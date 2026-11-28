// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가입 심사 도우미: screenshots at iPhone size (393 x 852): the applicant's
// link page, quiz (try again, right, written), result, and the admin's
// requests with answers, helper page and log. Green light/dark + blue.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/room_links.dart';
import 'package:burumy/demo/gate_sample.dart';
import 'package:burumy/demo/more_sample.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/invite_links.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/join_gate_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    final pre = ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf'];
    await loadFont('Pretendard', pre);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    for (final f in ['CupertinoSystemText', 'CupertinoSystemDisplay', '.SF Pro Text']) {
      await loadFont(f, ['assets/fonts/Pretendard-Regular.otf']);
    }
  });

  for (final (f, dark) in [(BrandFamily.green, false), (BrandFamily.green, true), (BrandFamily.blue, false)]) {
    final tag = '${f.name}_${dark ? 'dark' : 'light'}';
    testWidgets('gate shots $tag', (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      t.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      Features.joinGate = true;
      addTearDown(() => Features.joinGate = false);
      final photo = File('test/assets/sample_photo.png').readAsBytesSync();
      final b = demoSample(true, photo);
      addMoreChats(b, true, photo);
      addGateSample(b, true);
      final s = AppState(b, family: f, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      Future<void> shot(String n) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_42_gate_${tag}_$n.png'));
      NavigatorState nav() => t.state<NavigatorState>(find.byType(Navigator).first);
      Future<void> push(Widget p) async {
        nav().push(IosPageRoute(builder: (_) => p));
        await t.pumpAndSettle();
      }

      Future<void> back() async {
        nav().pop();
        await t.pumpAndSettle();
      }

      // Applicant.
      openJoinLink(t.element(find.byType(Navigator).first), const LinkTarget(kind: 'public', code: 'music_makers'));
      await t.pumpAndSettle();
      await shot('1_link');
      await t.tap(find.byKey(const Key('join-go')));
      await t.pumpAndSettle();
      await shot('2_quiz');
      await t.tap(find.byKey(const Key('quiz-choice-1')));
      await t.pumpAndSettle();
      await shot('3_try_again');
      await t.tap(find.byKey(const Key('quiz-choice-0')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      await shot('4_right');
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('quiz-choice-2')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('quiz-written')), '집에서 로파이 비트를 만들어요');
      await t.pump();
      await shot('5_written');
      await t.tap(find.byKey(const Key('quiz-go')));
      await t.pumpAndSettle();
      await shot('6_in');
      while (nav().canPop()) {
        await back();
      }

      // Admin.
      final room = b.links.entries.firstWhere((e) => e.value.code == 'mangwon_friends').key;
      await push(JoinRequestsPage(roomId: room));
      await shot('7_requests');
      await back();
      await push(GatePage(roomId: room));
      await shot('8_admin_off');
      await t.tap(find.byKey(const Key('gate-on')));
      await t.pumpAndSettle();
      await shot('9_admin_on');
      await t.scrollUntilVisible(find.byKey(const Key('gate-log')), 150, scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gate-log')));
      await t.pumpAndSettle();
      await shot('10_log');
      await back();
      await t.scrollUntilVisible(find.byKey(const Key('gate-q-0')), -150, scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('gate-q-0')));
      await t.pumpAndSettle();
      await shot('11_question');
    });
  }
}
