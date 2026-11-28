// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 로그인·기기 안전 screens at iPhone size (393 × 852), for checking against
// iOS / Telegram. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/login_safety.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/demo/login_safety_sample.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/link_pc.dart';
import 'package:burumy/ui/login_safety_ui.dart';
import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

/// Lets page pushes and fades finish (pumpAndSettle never ends: the QR page polls).
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

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
    testWidgets('login safety screens ${dark ? 'dark' : 'light'}', (t) async {
      Features.loginSafety = true;
      PcLinkCode.debugSecret = 'f' * 64;
      addTearDown(() {
        Features.loginSafety = false;
        PcLinkCode.debugSecret = null;
      });
      await withClock(Clock.fixed(DateTime(2026, 11, 23, 20, 5)), () async {
        t.view.physicalSize = const Size(393 * 2, 852 * 2);
        t.view.devicePixelRatio = 2;
        addTearDown(t.view.reset);
        final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
        addLoginSafetySample(b);
        final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
        await s.backend.login(id: 'me', password: 'x');
        // After login (a login starts with fresh settings): this phone knew
        // itself and the iPad; the Windows PC is new.
        await s.setPref(LoginSafety.knownKey, 'THIS,IPAD1');
        await s.refresh();
        await s.checkNewLogins(now: true);
        await s.setPref(Night.key, dark ? 'dark' : 'light');
        await t.pumpWidget(BurumyApp(state: s));
        await settle(t);
        final tag = dark ? 'dark' : 'light';
        await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/login_${tag}_1_card.png'));
        final nav = t.state<NavigatorState>(find.byType(Navigator).first);
        Future<void> shot(String name, Widget page, {Future<void> Function()? then}) async {
          nav.push(CupertinoPageRoute(builder: (_) => page));
          await settle(t);
          await then?.call();
          await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/login_${tag}_$name.png'));
          nav.pop();
          await settle(t);
        }

        await shot('2_link_pc', const LinkPcPage());
        b.pcReady = true;
        await shot('3_qr_login', const QrLoginPage());
        b.pcReady = false;
        await shot('4_qr_login_off', const QrLoginPage());
        // The 1:1 chat with messages on the most days (shows a range).
        var chat = s.chats.firstWhere((c) => c.isDirect && !c.isBot);
        var most = 0;
        for (final c in s.chats.where((c) => c.isDirect && !c.isBot)) {
          final days = {for (final m in await b.timeline(c.roomId, limit: 500)) DateTime(m.time.year, m.time.month, m.time.day)}.length;
          if (days > most) (most, chat) = (days, c);
        }
        await shot(
          '5_date_wipe',
          DeleteByDatePage(roomId: chat.roomId, title: chat.name, direct: true, peerName: chat.name),
          then: () async {
            final days = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('day-'));
            final keys = [
              for (final e in days.evaluate())
                if ((e.widget as dynamic).onTap != null) (e.widget.key as ValueKey<String>).value,
            ];
            // Pick the first and last day with messages (one day = one tap).
            if (keys.isNotEmpty) {
              await t.tap(find.byKey(ValueKey(keys.first)));
              if (keys.length > 1) await t.tap(find.byKey(ValueKey(keys.last)));
              await settle(t);
            }
          },
        );
      });
    });
  }
}
