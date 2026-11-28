// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// v1 sticker art in v2 (2026-11-27): moving stickers, Hip/Dandy Friends,
// character emoji between words and character reactions.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:burumy/stickers/catalog.dart';
import 'package:burumy/stickers/char_emoji.dart';
import 'package:burumy/ui/chat_page.dart' show isBigEmoji;
import 'package:burumy/ui/formatting.dart' show plainText;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  test('catalog: 372 stickers, 162 character emoji, 48 reactions, every file there', () {
    final all = [for (final p in stickerPacks) ...p.items];
    expect(all, hasLength(6 * 24 + 60 + 168));
    expect(all.toSet(), hasLength(all.length), reason: 'ids are unique');
    expect(all.where(StickerPack.moving), hasLength(48 + 30 + 84));
    for (final id in all) {
      expect(File(stickerAsset(id)!).existsSync(), isTrue, reason: id);
    }
    final emoji = [for (final g in charEmojiGroups.values) ...g];
    expect(emoji, hasLength(162));
    for (final id in emoji) {
      expect(File(charEmojiAsset(id)!).existsSync(), isTrue, reason: id);
    }
    expect(charReactions, hasLength(48));
    for (final id in charReactions) {
      expect(File(charReactionAsset(id)!).existsSync(), isTrue, reason: id);
    }
    // Old ids keep working (messages already sent).
    expect(stickerAsset('buru_01_hello'), 'assets/stickers/buru/buru_01_hello.webp');
    expect(stickerAsset('remy_a03_lol'), 'assets/stickers/hip/remy_a03_lol.webp');
    expect(charReactionAsset('❤️'), isNull);
  });

  test('short codes: composer letters out and back, plain emoji for lists', () {
    const sent = '좋아 :buru_e2_love: 고마워 :remy_e1_hello:';
    final typed = charEmojiIn(sent);
    expect(typed.length, '좋아 X 고마워 X'.length, reason: 'each is one letter');
    expect(charEmojiOut(typed), sent);
    expect(charEmojiPlain(sent), '좋아 😍 고마워 👋');
    expect(plainText('**hi** :buru_e8_wink:'), 'hi 😉');
    expect(charEmojiIn(':nobody_e1_x:'), ':nobody_e1_x:', reason: 'unknown codes stay as typed');
    expect(isBigEmoji(':buru_e3_lol:'), isTrue);
    expect(isBigEmoji(':buru_e3_lol: :dugi_e3_lol: :rumi_e3_lol:'), isTrue);
    expect(isBigEmoji(':buru_e3_lol: ok'), isFalse);
    expect(reactionText('buru_r2_love'), '😍');
    expect(reactionText('🔥'), '🔥');
  });

  test('composer: a pasted short code becomes one letter, cursor right after it', () {
    final c = EmojiTextController();
    c.value = const TextEditingValue(text: 'a:buru_e1_smile:b', selection: TextSelection.collapsed(offset: 16));
    expect(c.text.length, 3);
    expect(c.selection.baseOffset, 2);
    expect(c.outText, 'a:buru_e1_smile:b');
    c.text = '';
    expect(c.outText, '');
  });

  testWidgets('emoji side: tap a character emoji, send, it shows as a picture', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@ann:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('seg-emoji')));
    await t.pumpAndSettle();
    final tab = find.byKey(const Key('emoji-tab-c-buru'));
    await t.ensureVisible(tab);
    await t.pumpAndSettle();
    await t.tap(tab);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('emoji-c-buru_e2_love')));
    await t.pumpAndSettle();
    final field = t.widget<EditableText>(find.descendant(of: find.byKey(const Key('composer')), matching: find.byType(EditableText)));
    expect(field.controller.text, charEmojiLetter('buru_e2_love'));
    await t.enterText(find.byKey(const Key('composer')), '${charEmojiLetter('buru_e2_love')} 좋아');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(fake.rooms[room]!.last.body, ':buru_e2_love: 좋아');
    expect(find.byKey(const Key('char-emoji-buru_e2_love')), findsWidgets);
    expect(state.chats.first.last!.body, ':buru_e2_love: 좋아');
  });

  testWidgets('reactions: ⌄ shows the character reactions; one is sent as its id', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@ann:test');
    await fake.sendText(room, 'hello');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    await t.longPress(find.text('hello').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('react-more')));
    await t.pumpAndSettle();
    expect(find.text('캐릭터 반응'), findsOneWidget);
    final pick = find.byKey(const Key('react-dugi_r6_fire'));
    await t.scrollUntilVisible(
      pick,
      60,
      scrollable: find.descendant(of: find.byKey(const Key('react-scroll')), matching: find.byType(Scrollable)),
    );
    await t.tap(pick);
    await t.pumpAndSettle();
    expect(fake.rooms[room]!.last.reactions.single.key, 'dugi_r6_fire');
    expect(find.byKey(const Key('reaction-dugi_r6_fire')), findsOneWidget);
  });
}
