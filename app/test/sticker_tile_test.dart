// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sticker panel: '비눗방울 보내기' is the first tile in 1:1 chats and opens
// the bubble maker; groups don't get it (bubbles go to one friend).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';

import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/phone.dart';
import 'package:burumy/ui/bubbles.dart';
import 'package:burumy/ui/sticker_maker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

late FakeBackend fake;
late String roomId;

Future<void> open(WidgetTester t, {required bool group}) async {
  final b = fake = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  final room = group ? await b.createGroup('모임', ['@mina:test', '@leo:test']) : await b.createDirectChat('@mina:test');
  roomId = room;
  await b.sendText(room, '안녕');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('list-preview')).first);
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('sticker-button')));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('1:1: bubble tile first, opens the maker', (t) async {
    await open(t, group: false);
    expect(find.byKey(const Key('sticker-tile-bubble')), findsOneWidget);
    await t.tap(find.byKey(const Key('sticker-tile-bubble')));
    await t.pumpAndSettle();
    expect(find.byType(SendBubblePage), findsOneWidget);
  });

  testWidgets('group: no bubble tile', (t) async {
    await open(t, group: true);
    expect(find.byKey(const Key('sticker-panel')), findsOneWidget);
    expect(find.byKey(const Key('sticker-tile-bubble')), findsNothing);
  });

  testWidgets('✋ shows only waving stickers, 💤 only sleeping ones (Eric 2026-11-27)', (t) async {
    await open(t, group: false);
    Iterable<String> shown() => find
        .descendant(
          of: find.byKey(const Key('sticker-hits')),
          matching: find.byWidgetPredicate((w) => w is GestureDetector && '${w.key}'.contains('sticker-')),
        )
        .evaluate()
        .map((e) => '${e.widget.key}');
    await t.tap(find.byKey(const Key('sticker-feel-hello')));
    await t.pumpAndSettle();
    expect(shown(), isNotEmpty);
    for (final k in shown()) {
      expect(k, contains('_hello'));
    }
    await t.tap(find.byKey(const Key('sticker-feel-sleep')));
    await t.pumpAndSettle();
    expect(shown(), isNotEmpty);
    for (final k in shown()) {
      expect(k, contains('_night'));
    }
  });

  testWidgets('heart shows only love stickers; search finds by Korean word; emoji goes into the composer', (t) async {
    await open(t, group: false);
    await t.tap(find.byKey(const Key('sticker-feel-love')));
    await t.pumpAndSettle();
    final shown = find.descendant(
      of: find.byKey(const Key('sticker-hits')),
      matching: find.byWidgetPredicate((w) => w is GestureDetector && '${w.key}'.contains('sticker-')),
    );
    expect(shown, findsWidgets);
    for (final e in shown.evaluate()) {
      expect('${e.widget.key}', contains('_love'));
    }
    await t.tap(find.byKey(const Key('sticker-feel-love')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sticker-search-field')), '축하');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sticker-buru_11_congrats')), findsOneWidget);
    expect(find.byKey(const Key('sticker-buru_03_love')), findsNothing);
    await t.tap(find.byKey(const Key('seg-emoji')));
    await t.pumpAndSettle();
    await t.tap(find.text('😀').first);
    await t.pumpAndSettle();
    final field = t.widget<CupertinoTextField>(find.byKey(const Key('composer')));
    expect(field.controller!.text, contains('😀'));
  });

  for (final cut in [false, true]) {
    testWidgets('스티커 만들기 (${cut ? 'cut out' : 'no cut-out: shape'}): saved to 내 스티커 and sent as a sticker', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final photo = File('test/assets/sample_photo.png').readAsBytesSync();
      StickerMakerPage.debugPick = () async => photo;
      Phone.debugCutout = (b) async => cut ? Uint8List.fromList(photo) : null;
      addTearDown(() {
        StickerMakerPage.debugPick = null;
        Phone.debugCutout = null;
      });
      await open(t, group: true);
      await t.tap(find.byKey(const Key('sticker-tile-make')));
      await t.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 20 && find.byKey(const Key('maker-done')).evaluate().isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump(const Duration(milliseconds: 100));
      }
      for (var i = 0; i < 30 && find.descendant(of: find.byKey(const Key('maker-preview')), matching: find.byType(Image)).evaluate().isEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(Key(cut ? 'maker-cut' : 'maker-circle')), findsOneWidget);
      await t.enterText(find.byKey(const Key('maker-text')), '최고');
      await t.ensureVisible(find.byKey(const Key('maker-emoji-🎉')));
      await t.pump();
      await t.tap(find.byKey(const Key('maker-emoji-🎉')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const Key('maker-done')));
      for (var i = 0; i < 30 && find.byType(StickerMakerPage).evaluate().isNotEmpty; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pumpAndSettle();
      final sent = fake.rooms[roomId]!.last;
      expect(sent.kind, 'image');
      expect(sent.body, startsWith(customStickerPrefix));
      expect(find.byKey(const Key('sticker-msg')), findsWidgets);
      // It is in 내 스티커 now.
      expect(find.byKey(const Key('sticker-tab-mine')), findsOneWidget);
    });
  }
}
