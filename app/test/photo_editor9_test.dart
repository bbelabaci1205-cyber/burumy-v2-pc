// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// #9 사진 편집기 (Telegram tips 71, 201, 288, 370, 416): drag up on the
// rainbow bar for thickness, the exact-colour picker, two-finger zoom with
// a finer brush, the 스티커 tab with a cut-out picture (menu: 삭제 · 뒤집기 ·
// 복제 · 오려내기). Screenshots at iPhone size (393 x 852) in test/shots.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/photo_sample.dart' show demoCutout;
import 'package:burumy/main.dart';
import 'package:burumy/ui/color_pick.dart';
import 'package:burumy/ui/media_editor.dart';
import 'package:burumy/ui/photo_stickers.dart';
import 'package:burumy/ui/story_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'photo_send_test.dart' show loadFont;

void main() {
  test('colour grid and spectrum', () {
    final g = colorGrid();
    expect(g.length, 10);
    expect(g.every((r) => r.length == 12), isTrue);
    expect(g.first.first, const Color(0xFFFFFFFF));
    expect(g.first.last, const Color(0xFF000000));
    expect(spectrumAt(0, 0).computeLuminance(), greaterThan(.8));
    expect(spectrumAt(.5, 1).computeLuminance(), lessThan(.05));
  });

  test('sticker copy keeps the look and moves a little', () {
    final s = PhotoSticker.emoji('🎉')
      ..scale = 2
      ..turn = .5
      ..flipped = true;
    final c = s.copy();
    expect((c.emoji, c.scale, c.turn, c.flipped), ('🎉', 2.0, .5, true));
    expect(c.at, isNot(s.at));
  });

  group('screens', () {
    setUpAll(() async {
      await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
      final home = Platform.environment['HOME'];
      await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    });

    Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_47_editor_$name.png'));

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    testWidgets('thickness, colour, zoom, stickers, cut out', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pic = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      debugPickStickerPhoto = () async => pic;
      Phone.debugCutout = demoCutout;
      addTearDown(() {
        debugPickStickerPhoto = null;
        Phone.debugCutout = null;
      });
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      Uint8List? out;
      final done = Completer<void>();
      unawaited(
        editChatPhoto(t.element(find.text('대화').last), pic).then((v) {
          out = v;
          done.complete();
        }),
      );
      await settle(t);
      final ed = t.state<MediaEditorPageState>(find.byType(MediaEditorPage));

      // 71: drag up on the rainbow bar = thicker line, a circle shows the size.
      await t.tap(find.byKey(const Key('medit-mode-draw')));
      await t.pump(const Duration(milliseconds: 300));
      final before = ed.penSize;
      final bar = t.getCenter(find.byKey(const Key('medit-rainbow')));
      final g = await t.startGesture(bar);
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, -15));
        await t.pump();
      }
      expect(find.byKey(const Key('rainbow-size-preview')), findsOneWidget);
      await shot(t, '1_thickness');
      await g.up();
      await t.pump();
      expect(ed.penSize, greaterThan(before + .3));

      // 370: exact colour from the colour well.
      await t.tap(find.byKey(const Key('medit-color-well')));
      await settle(t);
      expect(find.byKey(const Key('color-pick')), findsOneWidget);
      await shot(t, '2_color_grid');
      await t.tap(find.text('스펙트럼'));
      await t.pump(const Duration(milliseconds: 300));
      final sp = t.getRect(find.byKey(const Key('color-pick-spectrum')));
      await t.tapAt(sp.topLeft + Offset(sp.width * .62, sp.height * .4));
      await t.pump(const Duration(milliseconds: 300));
      await shot(t, '3_color_spectrum');
      await t.tap(find.byKey(const Key('color-pick-done')));
      await settle(t);
      expect(ed.penPick, isNotNull);
      expect(ed.penColor, ed.penPick);

      // 288: two fingers zoom in; a line drawn then is finer on the picture.
      final pad = t.getCenter(find.byKey(const Key('medit-draw-pad')));
      final a = await t.startGesture(pad - const Offset(30, 0), pointer: 7);
      final c = await t.startGesture(pad + const Offset(30, 0), pointer: 8);
      for (var i = 0; i < 8; i++) {
        await a.moveBy(const Offset(-12, 0));
        await c.moveBy(const Offset(12, 0));
        await t.pump();
      }
      await a.up();
      await c.up();
      await t.pump();
      expect(ed.zoom, greaterThan(2));
      expect(find.byKey(const Key('medit-zoom-reset')), findsOneWidget);
      final zoomAt = ed.zoom;
      await t.dragFrom(pad - const Offset(60, 20), const Offset(120, 30));
      await t.pump();
      expect(ed.strokes.last.width, closeTo(ed.penW / zoomAt, 1e-9));
      await shot(t, '4_zoomed_draw');
      await t.tap(find.byKey(const Key('medit-zoom-reset')));
      await t.pump();
      expect(ed.zoom, 1);

      // 201 + 416: 스티커 tab opens the sheet; a gallery picture goes on top
      // with its menu; 오려내기 cuts it out, then flip and copy.
      await t.tap(find.byKey(const Key('medit-mode-sticker')));
      await settle(t);
      expect(find.byKey(const Key('photo-sticker-sheet')), findsOneWidget);
      await shot(t, '5_sticker_sheet');
      await t.tap(find.byKey(const Key('photo-sticker-cut')));
      await settle(t);
      expect(ed.stickers.length, 1);
      expect(find.byKey(const Key('medit-sticker-menu')), findsOneWidget);
      await shot(t, '6_picture_menu');
      await t.tap(find.byKey(const Key('stk-menu-cut')));
      await settle(t);
      expect(ed.stickers.single.cut, isNotNull);
      await t.tap(find.byKey(const Key('stk-menu-flip')));
      await t.pump();
      expect(ed.stickers.single.flipped, isTrue);
      await t.tap(find.byKey(const Key('stk-menu-copy')));
      await settle(t);
      expect(ed.stickers.length, 2);
      await shot(t, '7_cut_out');
      // Tap elsewhere-free: tap the chosen one again closes the menu.
      await t.tap(find.byKey(const Key('medit-sticker-1')));
      await t.pump();
      expect(find.byKey(const Key('medit-sticker-menu')), findsNothing);
      // Undo takes the copy away.
      await t.tap(find.byKey(const Key('medit-mode-draw')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const Key('medit-undo')));
      await t.pump();
      expect(ed.stickers.length, 1);

      await t.tap(find.byKey(const Key('medit-done')));
      await settle(t);
      await t.runAsync(() => done.future.timeout(const Duration(seconds: 5)));
      expect(out, isNotNull);
      expect(out!.sublist(1, 4), 'PNG'.codeUnits);
    });

    testWidgets('story: cut-out picture sticker', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pic = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      debugPickStickerPhoto = () async => pic;
      Phone.debugCutout = demoCutout;
      addTearDown(() {
        debugPickStickerPhoto = null;
        Phone.debugCutout = null;
      });
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      final key = GlobalKey<StoryDecorState>();
      unawaited(
        Navigator.of(t.element(find.text('대화').last)).push(
          CupertinoPageRoute<void>(
            builder: (_) => CupertinoPageScaffold(backgroundColor: const Color(0xFF000000), child: StoryDecor(key: key, bytes: pic)),
          ),
        ),
      );
      await settle(t);
      await t.tap(find.byKey(const Key('story-tool-sticker')));
      await settle(t);
      expect(find.byKey(const Key('story-photo-cut')), findsOneWidget);
      await t.tap(find.byKey(const Key('story-photo-cut')));
      await settle(t);
      expect(find.byKey(const Key('story-pic-menu')), findsOneWidget);
      await t.tap(find.byKey(const Key('stk-menu-cut')));
      await settle(t);
      expect(key.currentState!.items.single.pic!.cut, isNotNull);
      await t.tap(find.byKey(const Key('stk-menu-copy')));
      await settle(t);
      expect(key.currentState!.items.length, 2);
      await shot(t, '8_story_cut');
      final f = key.currentState!.flatten();
      await t.pump();
      await t.pump();
      final png = await t.runAsync(() => f.timeout(const Duration(seconds: 10)));
      await t.pump();
      expect(png, isNotNull);
      expect(find.byKey(const Key('story-pic-menu')), findsNothing);
    });
  });
}
