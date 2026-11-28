// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story camera (Telegram layout): modes, live notice, video timer, collage
// boxes filled one by one, both-sides circle, then the composer.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/story_camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openCamera(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  StoryCameraPage.fake = true;
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  s.settings = await b.settings();
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('story-camera')));
  await t.pumpAndSettle();
  expect(find.byKey(const Key('story-camera')), findsWidgets);
}

/// Pictures are painted and decoded for real, so let real time pass.
Future<void> realWait(WidgetTester t, [int ms = 400]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('modes: live says it needs our server, video counts time', (t) async {
    await openCamera(t);
    expect(find.text('사진'), findsOneWidget);
    await t.tap(find.byKey(const Key('cam-mode-live')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-shutter')), findsNothing);
    await t.tap(find.byKey(const Key('cam-live-start')));
    await t.pump();
    expect(find.text('실시간 방송은 우리 서버가 준비되면 열려요'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('cam-mode-video')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('cam-shutter')));
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('cam-rec-time')), findsOneWidget);
    await t.tap(find.byKey(const Key('cam-shutter')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-rec-time')), findsNothing);
    await t.tap(find.byKey(const Key('cam-close')));
    await t.pumpAndSettle();
  });

  testWidgets('collage: pick a layout, fill both boxes, then the composer', (t) async {
    await openCamera(t);
    await t.tap(find.byKey(const Key('cam-grid')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-grid-picker')), findsOneWidget);
    // Back leaves the picker without choosing; the off button sits on the same line.
    expect(t.getTopLeft(find.byKey(const Key('cam-grid-off'))).dy, t.getTopLeft(find.byKey(const Key('cam-layout-0'))).dy);
    await t.tap(find.byKey(const Key('cam-grid-back')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-grid-picker')), findsNothing);
    await t.tap(find.byKey(const Key('cam-grid')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('cam-layout-0')));
    await t.pumpAndSettle();
    expect(find.text('탭하여 그리드 제거'), findsOneWidget);
    expect(find.byKey(const Key('cam-cell-1')), findsOneWidget);
    await t.tap(find.byKey(const Key('cam-shutter')));
    await realWait(t);
    expect(find.byKey(const Key('cam-grid-picker')), findsNothing);
    await t.tap(find.byKey(const Key('cam-shutter')));
    await realWait(t, 2000);
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('story-share')), findsOneWidget);
  });

  testWidgets('both sides: circle shows, one tap makes one picture', (t) async {
    await openCamera(t);
    await t.tap(find.byKey(const Key('cam-dual')));
    await t.pump();
    expect(find.byKey(const Key('cam-dual-circle')), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('cam-shutter')));
    await realWait(t, 2000);
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('story-share')), findsOneWidget);
  });

  testWidgets('404 front flash: hold ⚡ for warmth / brightness, the screen glows on the shot', (t) async {
    await openCamera(t);
    await t.tap(find.byKey(const Key('cam-flip')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('cam-flash')));
    await t.pumpAndSettle();
    await t.longPress(find.byKey(const Key('cam-flash')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-flash-panel')), findsOneWidget);
    expect(find.text('따뜻함'), findsOneWidget);
    final box = t.getRect(find.byKey(const Key('cam-flash-warm')));
    await t.tapAt(Offset(box.left + box.width * .8, box.center.dy));
    await t.pumpAndSettle();
    final s = t.state(find.byType(StoryCameraPage)).context;
    expect(AppScope.read(s).pref('front_flash_warm', ''), '0.80');
    expect(find.text('80%'), findsOneWidget);
    await t.tap(find.byKey(const Key('cam-flash-panel-close')), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-flash-panel')), findsNothing);
    await t.tap(find.byKey(const Key('cam-shutter')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('cam-screen-flash')), findsOneWidget);
    await realWait(t, 800);
    expect(find.byKey(const Key('cam-screen-flash')), findsNothing);
  });
}
