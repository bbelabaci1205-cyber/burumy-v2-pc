// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 보관함 row (Eric 2026-11-25): a long swipe left moves it into the side
// menu with a black banner; the pin there brings it back. My last message
// in a 1:1 shows one tick (sent) or two (read).
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_row_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('archive row moves to the side menu and back', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('archive-row')), findsOneWidget);
    await t.drag(find.byKey(const Key('archive-row')), const Offset(-330, 0));
    await t.pumpAndSettle();
    expect(s.on(archiveInMenuPref), isTrue);
    expect(find.byKey(const Key('info-banner')), findsOneWidget);
    expect(find.text('보관함을 왼쪽 메뉴로 옮겼어요'), findsOneWidget);
    expect(find.byKey(const Key('archive-row')), findsNothing);
    await t.pump(const Duration(seconds: 4));
    // Drag from the left edge opens the menu.
    await t.dragFrom(const Offset(4, 500), const Offset(200, 0));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('side-menu-close')), findsOneWidget);
    expect(find.byKey(const Key('menu-archive')), findsOneWidget);
    await t.tap(find.byKey(const Key('menu-archive-pin')));
    await t.pumpAndSettle();
    expect(s.on(archiveInMenuPref), isFalse);
    expect(find.text('보관함을 대화 목록에 고정했어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    // Theme colour picks right in the side menu.
    await t.scrollUntilVisible(
      find.byKey(const Key('menu-theme-blue')),
      100,
      scrollable: find.descendant(of: find.byKey(const Key('side-menu')), matching: find.byType(Scrollable)).first,
    );
    await t.tap(find.byKey(const Key('menu-theme-blue')));
    await t.pumpAndSettle();
    expect(s.family, BrandFamily.blue);
    await t.tap(find.byKey(const Key('menu-theme-green')));
    await t.pumpAndSettle();
    expect(s.family, BrandFamily.green);
  });

  testWidgets('stories and bubbles strips move to the side menu and back', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    for (final (id, pref, moved) in [('stories', storiesInMenuPref, '스토리를 왼쪽 메뉴로 옮겼어요'), ('bubbles', bubblesInMenuPref, '비눗방울을 왼쪽 메뉴로 옮겼어요')]) {
      await t.drag(find.byKey(Key('$id-swipe')), const Offset(-340, 0));
      await t.pumpAndSettle();
      expect(s.on(pref), isTrue, reason: id);
      expect(find.text(moved), findsOneWidget);
      expect(find.byKey(Key('$id-swipe')), findsNothing);
      await t.pump(const Duration(seconds: 4));
    }
    await t.tap(find.byKey(const Key('side-menu-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-stories')), findsOneWidget);
    expect(find.byKey(const Key('stories-bar')), findsOneWidget);
    expect(find.byKey(const Key('menu-bubbles')), findsOneWidget);
    await t.tap(find.byKey(const Key('menu-stories-pin')));
    await t.pumpAndSettle();
    expect(s.on(storiesInMenuPref), isFalse);
    expect(find.text('스토리를 대화 목록에 고정했어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    await t.tap(find.byKey(const Key('menu-bubbles-pin')));
    await t.pumpAndSettle();
    expect(s.on(bubblesInMenuPref), isFalse);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('stories, bubbles, archive tuck away one at a time; a nudge snaps back', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('stories-bar')), findsOneWidget);
    expect(find.byKey(const Key('bubble-strip')), findsOneWidget);
    expect(find.text('내 스토리'), findsNothing);
    expect(find.text('비눗방울 2개'), findsNothing);
    expect(find.byKey(const Key('stories-mini')), findsNothing);
    final list = find.byType(CustomScrollView).first;
    Future<void> push(int steps) async {
      final g = await t.startGesture(t.getCenter(list) + const Offset(0, 200));
      for (var i = 0; i < steps; i++) {
        await g.moveBy(const Offset(0, -6));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pumpAndSettle();
    }

    // A small nudge is not enough any more: the stories snap back open.
    await push(6);
    expect(find.byKey(const Key('stories-mini')), findsNothing);
    // Past halfway the stories fold into the bar, left of the title; the
    // bubbles stay where they are (one tier at a time).
    await push(16);
    expect(find.byKey(const Key('stories-mini')), findsOneWidget);
    expect(t.getCenter(find.byKey(const Key('stories-mini'))).dx, lessThan(t.getCenter(find.byKey(const Key('bar-title'))).dx));
    expect(find.byKey(const Key('bubbles-mini')), findsNothing);
    // Pull down: everything opens again.
    await t.drag(list, const Offset(0, 300));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('stories-mini')), findsNothing);
  });

  testWidgets('my last message: one tick sent, two ticks read', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final dm = await b.createDirectChat('@bob:test');
    await b.sendText(dm, 'hi');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('list-tick-sent')), findsOneWidget);
    b.readAt = DateTime.now().add(const Duration(minutes: 1));
    await s.refresh();
    await t.pumpWidget(BurumyApp(key: UniqueKey(), state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('list-tick-read')), findsOneWidget);
  });
}
