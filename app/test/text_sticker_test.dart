// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 글자 스티커 (4-app board): words in a shape become a sticker, saved to
// 내 스티커 and sent as a PNG.
import 'dart:ui' as ui;

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/sticker_maker.dart';
import 'package:burumy/ui/text_sticker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle(WidgetTester t, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('every shape and colour draws a 512px sticker', (t) async {
    await t.runAsync(() async {
      for (final sh in textStickerShapes) {
        for (final c in [textStickerColors.first, textStickerColors[5]]) {
          final png = await renderTextSticker('오늘도 화이팅 아주 길게 써 본 말', shape: sh, color: c);
          final img = (await (await ui.instantiateImageCodec(png)).getNextFrame()).image;
          expect((img.width, img.height), (512, 512), reason: sh);
        }
      }
    });
  });

  testWidgets('글자 tile: type, pick a shape and colour, send; it is in 내 스티커', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '안녕');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('list-preview')).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-tile-text')));
    await settle(t, () => find.byType(TextStickerPage).evaluate().isNotEmpty);
    await t.pump(const Duration(milliseconds: 800));
    expect(find.byType(TextStickerPage), findsOneWidget);
    // Nothing to send before there are words.
    expect(t.widget<CupertinoButton>(find.byKey(const Key('tsticker-done'))).onPressed, isNull);
    await t.enterText(find.byKey(const Key('tsticker-text')), '고마워요');
    await t.tap(find.byKey(const Key('tsticker-shape-badge')));
    await t.tap(find.byKey(const Key('tsticker-color-3')));
    await settle(t, () => find.byKey(const Key('tsticker-preview')).evaluate().isNotEmpty);
    expect(find.byKey(const Key('tsticker-preview')), findsOneWidget);
    await t.tap(find.byKey(const Key('tsticker-done')));
    await settle(t, () => find.byType(TextStickerPage).evaluate().isEmpty);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pumpAndSettle();
    final sent = b.rooms[room]!.last;
    expect(sent.kind, 'image');
    expect(sent.body, startsWith(customStickerPrefix));
    expect(myStickers(s), hasLength(1));
  });
}
