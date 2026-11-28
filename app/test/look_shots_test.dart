// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 5 screens at iPhone size (393 × 852), for checking
// against iOS / Telegram. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:clock/clock.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/look_pages.dart';
import 'package:burumy/ui/qr_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('CupertinoSystemDisplay', ['assets/fonts/Pretendard-Regular.otf']);
  });

  for (final dark in [false, true]) {
    testWidgets('batch 5 screens ${dark ? 'dark' : 'light'}', (t) async {
      // Fixed time (noon): the 5-minute QR and night-by-time look the same on every run.
      await withClock(Clock.fixed(DateTime(2026, 11, 27, 12)), () async {
        t.view.physicalSize = const Size(393 * 2, 852 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final s = AppState(demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync()), family: BrandFamily.green, locale: const Locale('ko'));
        await s.backend.login(id: 'me', password: 'x');
        await s.refresh();
        await s.setPref(Night.key, dark ? 'dark' : 'light');
        await t.pumpWidget(BurumyApp(state: s));
        await t.pumpAndSettle();
        final nav = t.state<NavigatorState>(find.byType(Navigator).first);
        final tag = dark ? 'dark' : 'light';
        Future<void> shot(String name, Widget page, {Future<void> Function()? then}) async {
          nav.push(CupertinoPageRoute(builder: (_) => page));
          await t.pumpAndSettle();
          await then?.call();
          await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/look_${tag}_$name.png'));
          nav.pop();
          await t.pumpAndSettle();
        }

        await s.setPref(Night.key, 'schedule');
        await s.setPref(Night.key, dark ? 'dark' : 'light');
        await shot(
          '1_auto_night',
          const AutoNightPage(),
          then: () async {
            await s.setPref(Night.key, 'schedule');
            await t.pumpAndSettle();
            await t.tap(find.byKey(const Key('night-from')));
            await t.pumpAndSettle();
          },
        );
        await s.setPref(Night.key, dark ? 'dark' : 'light');
        await t.pumpAndSettle();
        await shot('2_default_timer', const DefaultTimerPage());
        await shot(
          '3_timer_apply',
          const TimerApplyPage(seconds: 604800),
          then: () async {
            await t.tap(find.byKey(const Key('timer-apply-all')));
            await t.pumpAndSettle();
          },
        );
        await s.setPref('qr_theme', 'ocean');
        await shot('4_qr', const QrPage());
        await s.setPref('qr_theme', '');
        await shot(
          '5_qr_short',
          const QrPage(),
          then: () async {
            await t.tap(find.byKey(const Key('qr-short')));
            await t.pump(const Duration(seconds: 1));
            await t.pumpAndSettle();
          },
        );
        final room = s.chats.firstWhere((c) => c.isDirect).roomId;
        await shot(
          '6_room_theme',
          RoomThemePage(roomId: room, direct: true),
          then: () async {
            await t.tap(find.byKey(const Key('room-theme-nature')));
            await t.pumpAndSettle();
          },
        );
        // The wheel for "다른 시간".
        nav.push(CupertinoPageRoute(builder: (_) => const DefaultTimerPage()));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('pick-other')));
        await t.pumpAndSettle();
        await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/look_${tag}_7_wheel.png'));
        await t.tap(find.byKey(const Key('timer-wheel-done')));
        await t.pumpAndSettle();
      });
    });
  }
}
