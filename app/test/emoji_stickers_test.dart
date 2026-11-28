// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이모지 찾기·반응 + 스티커 묶음 (Telegram tip batches #19 + #20).
import 'dart:convert';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/emoji_words.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/sticker_sets.dart';
import 'package:burumy/main.dart';
import 'package:burumy/stickers/sticker_words.dart';
import 'package:burumy/ui/emoji_status.dart' show forgetEmojiStatuses;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<(FakeBackend, AppState, String)> open(WidgetTester t, {String? say, void Function(FakeBackend)? before}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final fake = FakeBackend();
  final state = AppState(fake, locale: const Locale('ko'));
  await fake.login(id: 'me', password: 'x');
  final room = await fake.createDirectChat('@ann:test');
  if (say != null) await fake.sendText(room, say);
  before?.call(fake);
  await state.refresh();
  await t.pumpWidget(BurumyApp(state: state));
  await t.pumpAndSettle();
  await t.tap(find.text('@ann:test'));
  await t.pumpAndSettle();
  return (fake, state, room);
}

void main() {
  setUp(() {
    Features.emojiStickers = true;
    forgetEmojiStatuses();
  });
  tearDown(() => Features.emojiStickers = false);

  test('emoji words: Korean and English, shortcut, last word, one emoji', () {
    expect(searchEmoji('하트'), contains('❤️'));
    expect(searchEmoji('하트').first, '❤️');
    expect(searchEmoji('heart'), contains('❤️'));
    expect(searchEmoji('웃'), containsAll(['😀', '😂']));
    expect(searchEmoji('👋').first, '👋');
    expect(searchEmoji(''), isEmpty);
    expect(colonShortcut('안녕 :웃', 5), (start: 3, word: '웃'));
    expect(colonShortcut(':buru_e1_smile:', 15), isNull, reason: 'a closed character code is not a shortcut');
    expect(colonShortcut('시간 3:30', 7), isNull);
    expect(emojiForLastWord('생일 축하해'), contains('🎉'));
    expect(emojiForLastWord('오늘 고마워요'), contains('🙏'));
    expect(emojiForLastWord('그냥 말'), isEmpty);
    expect(isSingleEmoji(' 😂 '), isTrue);
    expect(isSingleEmoji('👨‍💻'), isTrue);
    expect(isSingleEmoji('😂😂'), isFalse);
    expect(isSingleEmoji('ㅋ'), isFalse);
  });

  test('sticker search: several words must all fit (tip 496)', () {
    expect(stickerMatches('buru_10_sad', '울고 있는 토끼'), isTrue);
    expect(stickerMatches('dugi_10_sad', '울고 있는 토끼'), isFalse);
    expect(stickerMatches('buru_03_love', 'rabbit love'), isTrue);
    expect(stickerMatches('buru_a03_love', '움직이는 사랑'), isTrue);
    expect(stickerMatches('buru_03_love', '움직이는 사랑'), isFalse);
    expect(stickersForEmoji('😭', ['buru_10_sad', 'buru_03_love']), ['buru_10_sad']);
  });

  test('set files and links: only real encrypted-file links, only PNGs', () {
    final file = jsonEncode({
      'url': 'mxc://s/abc',
      'key': {
        'kty': 'oct',
        'key_ops': ['encrypt', 'decrypt'],
        'alg': 'A256CTR',
        'k': 'a2V5',
        'ext': true,
      },
      'iv': 'aXY',
      'hashes': {'sha256': 'c2hh'},
      'v': 'v2',
    });
    final link = StickerSetLink(file, '우리 강아지');
    expect(link.url, startsWith('https://burumy.app/s#f='));
    final back = StickerSetLink.parse('보세요 ${link.url} !')!;
    expect(jsonDecode(back.file)['url'], 'mxc://s/abc');
    expect(back.name, '우리 강아지');
    expect(StickerSetLink.parse('https://burumy.app/s#f=${base64Url.encode(utf8.encode('{"url":"https://evil"}'))}'), isNull);

    final png = [0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0, 1, 2];
    final payload = utf8.encode(
      jsonEncode({
        'v': 1,
        'kind': 'sticker',
        'name': '  묶음  ',
        'items': [
          {'id': 'buru_03_love', 'e': '❤️'},
          {'png': base64Encode(png)},
          {'png': base64Encode(utf8.encode('<svg>not a png</svg>'))},
          {'id': '../../etc/passwd'},
        ],
      }),
    );
    final set = StickerSet.fromPayload(payload, file: file)!;
    expect(set.name, '묶음');
    expect(set.items, hasLength(2));
    expect(set.items.first.emoji, '❤️');
    expect(set.mine, isFalse);
    expect(StickerSet.fromPayload(utf8.encode('{"v":2}'), file: file), isNull);
  });

  testWidgets('composer: :웃음 swaps for the emoji; one emoji alone suggests stickers', (t) async {
    final (fake, _, room) = await open(t);
    await t.enterText(find.byKey(const Key('composer')), '좋아 :하트');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('suggest-emoji')), findsOneWidget);
    await t.tap(find.byKey(const Key('suggest-e-❤️')));
    await t.pumpAndSettle();
    final field = t.widget<EditableText>(find.descendant(of: find.byKey(const Key('composer')), matching: find.byType(EditableText)));
    expect(field.controller.text, '좋아 ❤️');
    await t.enterText(find.byKey(const Key('composer')), '😂');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('suggest-stickers')), findsOneWidget);
    await t.tap(find.byKey(const Key('suggest-s-0')));
    await t.pumpAndSettle();
    expect(fake.rooms[room]!.last.kind, 'sticker');
    expect(fake.rooms[room]!.last.body, endsWith('_lol'));
    expect(field.controller.text, isEmpty);
    // A word with an exact emoji: the emoji goes after it.
    await t.enterText(find.byKey(const Key('composer')), '생일 축하');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('suggest-e-🎉')));
    await t.pumpAndSettle();
    expect(field.controller.text, '생일 축하 🎉');
  });

  testWidgets('emoji panel: search, feeling chip, hold to zoom', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('seg-emoji')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('emoji-feel-🎉')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emoji-hit-🥳')), findsOneWidget);
    await t.enterText(find.byKey(const Key('emoji-search-field')), '고양이');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emoji-hit-🐱')), findsOneWidget);
    await t.longPress(find.byKey(const Key('emoji-hit-🐱')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('emoji-zoom')), findsOneWidget);
    expect(find.byKey(const Key('emoji-zoom-status')), findsOneWidget);
  });

  testWidgets('reactions: search every emoji; 3 of mine at most (a 4th takes a place)', (t) async {
    final (fake, _, room) = await open(t, say: 'hello');
    Future<void> react(String e, {bool search = false}) async {
      await t.longPress(find.text('hello').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('react-more')));
      await t.pumpAndSettle();
      if (search) {
        await t.enterText(find.byKey(const Key('emoji-search-field')), '유니콘');
        await t.pumpAndSettle();
      }
      await t.tap(find.byKey(Key('react-$e')).first);
      await t.pumpAndSettle();
    }

    await react('🦄', search: true);
    await react('🔥');
    await react('👏');
    expect(fake.rooms[room]!.last.reactions.where((r) => r.mine != null), hasLength(3));
    await react('🎉');
    final mine = [
      for (final r in fake.rooms[room]!.last.reactions)
        if (r.mine != null) r.key,
    ];
    expect(mine, hasLength(3));
    expect(mine, contains('🎉'));
  });

  testWidgets('sticker set: make, share to a chat, the card opens, someone adds it', (t) async {
    final (fake, state, room) = await open(t);
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    final manage = find.byKey(const Key('sticker-tab-sets'));
    await t.ensureVisible(manage);
    await t.tap(manage);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('set-new')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('set-name')), '우리 강아지');
    await t.tap(find.byKey(const Key('set-add')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pick-buru_03_love')));
    await t.tap(find.byKey(const Key('pick-buru_05_lol')));
    await t.pump();
    expect(find.text('2개 골랐어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('pick-done')));
    await t.pumpAndSettle();
    // Second sticker to the front.
    await t.tap(find.byKey(const Key('set-item-1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('set-item-first')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('set-share')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('set-share')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('set-share-chat')));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test').last);
    await t.pumpAndSettle();
    final sets = StickerSets.all(state);
    expect(sets.single.name, '우리 강아지');
    expect(sets.single.items.map((i) => i.id), ['buru_05_lol', 'buru_03_love']);
    expect(sets.single.items.first.emoji, '😂', reason: 'built-ins bring their emoji');
    final card = fake.rooms[room]!.last;
    expect(card.card!.kind, 'stickers');
    expect(card.card!.data['n'], 2);
    expect(card.card!.data.containsKey('items'), isFalse, reason: 'pictures only inside the encrypted file');
    // What travels is the encrypted file; it reads back as the same set.
    final back = StickerSet.fromPayload(await fake.downloadEncrypted(sets.single.file), file: sets.single.file)!;
    expect(back.items.map((i) => i.id), ['buru_05_lol', 'buru_03_love']);

    // Someone else gets the card (a fresh phone): 보기 > 추가.
    await t.tap(find.byKey(const Key('set-save')));
    await t.pumpAndSettle();
    await StickerSets.save(state, const []);
    for (var i = 0; i < 2; i++) {
      await t.tap(find.byKey(const Key('back')).last);
      await t.pumpAndSettle();
    }
    fake.rooms[room]!.add(Msg(id: 'from-ann', sender: '@ann:test', body: card.body, time: DateTime.now(), mine: false, kind: 'card', card: card.card));
    await state.refresh();
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test').first);
    await t.pumpAndSettle();
    expect(StickerSets.seen(state).values.single.$1, '우리 강아지');
    expect(find.byKey(const Key('set-card-from-ann')), findsOneWidget);
    await t.tap(find.byKey(const Key('set-card-from-ann')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('set-preview')), findsOneWidget);
    await t.tap(find.byKey(const Key('set-add-to-mine')));
    await t.pumpAndSettle();
    expect(StickerSets.all(state).single.mine, isFalse);
    expect(StickerSets.all(state).single.from, '@ann:test');
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('emoji status: a friend\'s shows after the name; I set mine for 1 hour', (t) async {
    final (fake, state, _) = await open(t, before: (f) => f.statuses['@ann:test'] = const EmojiStatus('🏖️'));
    expect(find.byKey(const Key('title-status')), findsOneWidget);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('status-🏖️')), findsOneWidget);
    await t.tap(find.byKey(const Key('tab-settings')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('my-status')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('status-quick-💼')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('status-for-1h')));
    await t.pumpAndSettle();
    expect(fake.statuses[fake.userId]!.emoji, '💼');
    expect(fake.statuses[fake.userId]!.until!.difference(DateTime.now()).inMinutes, inInclusiveRange(58, 60));
    expect(find.byKey(const Key('status-💼')), findsOneWidget);
    expect(state.pref('my_status', ''), startsWith('💼|'));
    await t.pump(const Duration(seconds: 2));
  });
}
