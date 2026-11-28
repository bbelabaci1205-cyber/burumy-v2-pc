// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 우리식 기능 2차: AI 친구, 스티커 가게, 통합 검색 (당겨서 카메라 is in the
// chat list test below).
import 'dart:io';

import 'package:burumy/core/ai_friend.dart';
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/demo/demo_ai.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/search_sample.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/ai_friend_page.dart';
import 'package:burumy/ui/chat_list_page.dart' show pullCameraPref;
import 'package:burumy/ui/search_page.dart';
import 'package:burumy/ui/story_camera.dart' show StoryCameraPage;
import 'package:burumy/ui/sticker_sets_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() async {
    Features.ownWay = true;
    LocalAi.engine = DemoAi();
    LocalAi.reset();
    await LocalAi.status();
  });
  tearDown(() {
    Features.ownWay = false;
    LocalAi.engine = PhoneAi();
    LocalAi.reset();
  });

  Widget wrap(AppState s, Widget child) => AppScope(
    state: s,
    child: CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  group('AI 친구', () {
    test('the model sees only the last turns of this talk', () {
      final lines = [for (var i = 0; i < 12; i++) AiLine(mine: i.isEven, text: 'line $i', at: DateTime(2026))];
      final r = AiFriend.rules(lines, korean: true);
      expect(r, contains('line 11'));
      expect(r, isNot(contains('line 3')), reason: 'only ${AiFriend.context} turns');
      expect(r, contains('Korean'));
    });

    test('a question and its answer stay on this phone, and can be wiped', () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      final out = await AiFriend.ask(s, '주말에 뭐 하지?', korean: true);
      expect(out, isNotEmpty);
      expect([for (final x in AiFriend.log(s)) x.mine], [true, false]);
      expect(fake.sentSignals, isEmpty, reason: 'nothing is sent anywhere');
      await AiFriend.clear(s);
      expect(AiFriend.log(s), isEmpty);
    });

    test('listed only where the phone has its own AI and the switch is on', () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      expect(AiFriend.listed(s), isTrue);
      await s.setOn(AiFriend.pref, false);
      expect(AiFriend.listed(s), isFalse);
    });

    testWidgets('chat page: send, the AI answers', (t) async {
      phone(t);
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      await t.pumpWidget(wrap(s, const AiFriendPage()));
      await t.pumpAndSettle();
      await t.enterText(find.byType(CupertinoTextField).last, '안녕');
      await t.pump();
      await t.tap(find.byKey(const Key('ai-friend-send')));
      await t.pumpAndSettle(const Duration(seconds: 2));
      expect(AiFriend.log(s).length, 2);
    });
  });

  testWidgets('스티커 가게: free packs add and remove, paid ones wait', (t) async {
    phone(t);
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final s = AppState(fake, locale: const Locale('ko'));
    await t.pumpWidget(wrap(s, const BrowseSetsPage()));
    await t.pumpAndSettle();
    expect(find.text('스티커 가게'), findsWidgets);
    expect(find.byKey(const Key('shop-new')), findsOneWidget);
    expect(find.text('곧 열려요'), findsOneWidget);
    await t.tap(find.byKey(const Key('shop-new')));
    await t.pumpAndSettle();
    final before = s.on('pack_off:dandy');
    await t.tap(find.byKey(const Key('shop-pack-add')));
    await t.pumpAndSettle();
    expect(s.on('pack_off:dandy'), !before);
  });

  group('통합 검색', () {
    Future<AppState> app() async {
      final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
      addSearchSample(b, true, File('test/assets/sample_photo.png').readAsBytesSync());
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      return s;
    }

    Future<void> type(WidgetTester t, String w) async {
      await t.enterText(find.byKey(const Key('search-input')), w);
      await t.pump(const Duration(milliseconds: 300));
      await t.pumpAndSettle();
    }

    testWidgets('features, the AI friend, and followed channel posts', (t) async {
      phone(t);
      final s = await app();
      await t.pumpWidget(wrap(s, const SearchPage()));
      await t.pumpAndSettle();
      await type(t, '잠금');
      expect(find.byKey(const Key('search-feature-lock')), findsOneWidget);
      await type(t, '부산');
      expect(find.byKey(const Key('search-ask-ai')), findsOneWidget);
      expect(find.byKey(const Key('search-all-posts')), findsOneWidget);
      await t.tap(find.byKey(const Key('search-all-posts')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('search-posts-note')), findsOneWidget);
      await t.tap(find.byKey(const Key('tab-chats')));
      await t.pumpAndSettle();
      await type(t, '스티커');
      expect(find.byKey(const Key('search-feature-shop')), findsOneWidget);
    });
  });

  testWidgets('당겨서 카메라: a long pull at the top opens the camera; the AI friend is in the list', (t) async {
    phone(t);
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@mina:test');
    final s = AppState(fake, locale: const Locale('ko'));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ai-friend-row')), findsOneWidget);
    Future<TestGesture> pull() async {
      final g = await t.startGesture(t.getCenter(find.byKey(const Key('ai-friend-row'))));
      for (var i = 0; i < 30; i++) {
        await g.moveBy(const Offset(0, 20));
        await t.pump(const Duration(milliseconds: 16));
      }
      return g;
    }

    // Switched off in Settings: no camera on the pull.
    await s.setOn(pullCameraPref, false);
    await t.pumpAndSettle();
    var g = await pull();
    expect(find.byKey(const Key('pull-camera-hint')), findsNothing);
    await g.up();
    await t.pumpAndSettle();
    await s.setOn(pullCameraPref, true);
    await t.pumpAndSettle();
    g = await pull();
    expect(find.byKey(const Key('pull-camera-hint')), findsOneWidget);
    expect(find.text('놓으면 카메라가 열려요'), findsOneWidget);
    await g.up();
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(StoryCameraPage), findsOneWidget);
  });
}
