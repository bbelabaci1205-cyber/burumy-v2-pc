// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Wrong-password wipe, delete for both, friend's delete notice, capture
// block on view-once content.
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:burumy/core/screen_guard.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('5 wrong passwords erase every chat; warning first (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('bob');
    fake.normalPw = 'normal123';
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // Settings > App Lock: choose 5 tries.
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('privacy-row')), 150, scrollable: find.byType(Scrollable).last);
    unawaited(Scrollable.ensureVisible(t.element(find.byKey(const Key('privacy-row'))), alignment: 0.5));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('privacy-row')));
    await t.pumpAndSettle();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('app-lock')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lock-gate')), 'normal123');
    await t.tap(find.byKey(const Key('lock-gate-ok')));
    await t.pumpAndSettle();
    await t.dragUntilVisible(find.text('5번'), find.byType(ListView).last, const Offset(0, -200));
    await t.pumpAndSettle();
    await t.tap(find.text('5번'));
    await t.pumpAndSettle();
    expect(fake.wipeN, 5);

    // Locked: wrong, wrong (warning: 3 left), wrong, wrong, wrong = erased.
    await state.checkLock();
    await t.pumpAndSettle();
    for (var i = 1; i <= 5; i++) {
      await t.enterText(find.byKey(const Key('lock-password')), 'guess$i-xx');
      await t.tap(find.byKey(const Key('lock-open')));
      await t.pumpAndSettle();
      if (i == 2) expect(find.text('3번 더 틀리면 모든 대화가 지워져요'), findsOneWidget);
    }
    expect(fake.wiped, 1);
    expect(fake.rooms, isEmpty);
    expect(fake.fails, 0);
    await t.enterText(find.byKey(const Key('lock-password')), 'normal123');
    await t.tap(find.byKey(const Key('lock-open')));
    await t.pumpAndSettle();
    expect(find.text('아직 대화가 없어요'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('delete a 1:1 chat for both (5 s undo); friend deleted notice (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('delete-both')), 200, scrollable: find.byType(Scrollable).last);
    unawaited(Scrollable.ensureVisible(t.element(find.byKey(const Key('delete-both'))), alignment: 0.5));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('delete-both')));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('4초 뒤 삭제돼요'), findsOneWidget);
    await t.tap(find.byKey(const Key('delete-undo')));
    await t.pump(const Duration(seconds: 6));
    expect(fake.deletedForBoth, isEmpty);
    await t.tap(find.byKey(const Key('delete-both')));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(fake.deletedForBoth, [bob]);
    expect(find.text('bob'), findsNothing);

    // A friend deleted ours for both: told once on the chat list.
    fake.eraseNotices.add('@carol:test');
    await state.refresh();
    await t.pumpAndSettle();
    expect(find.text('상대가 양쪽에서 대화를 지웠어요 · @carol'), findsOneWidget);
    await state.refresh();
    await t.pumpAndSettle();
    expect(find.textContaining('@carol'), findsOneWidget);
    await t.tap(find.descendant(of: find.byKey(const Key('erased-@carol:test')), matching: find.byType(CupertinoButton)));
    await t.pumpAndSettle();
    expect(find.textContaining('@carol'), findsNothing);
    state.stopLive();
  });

  testWidgets('view-once photo blocks capture while open', (t) async {
    final calls = <(String, Object?)>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('app.burumy/screen'), (c) async {
      calls.add((c.method, c.arguments));
      return c.method == 'captured' ? false : null;
    });
    await t.pumpWidget(
      CupertinoApp(
        localizationsDelegates: const [DefaultCupertinoLocalizations.delegate, DefaultWidgetsLocalizations.delegate],
        home: Builder(
          builder: (c) => CupertinoButton(
            key: const Key('go'),
            onPressed: () => Navigator.of(c).push(
              CupertinoPageRoute(
                builder: (_) => const CaptureBlock(child: SizedBox(key: Key('secret'))),
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('go')));
    await t.pumpAndSettle();
    expect(calls.where((c) => c.$1 == 'secure').map((c) => c.$2), [true]);
    // Screen recording starts (iPhone): the photo is covered.
    ScreenGuard.captured.value = true;
    await t.pump();
    expect(find.byKey(const Key('capture-cover')), findsOneWidget);
    ScreenGuard.captured.value = false;
    Navigator.of(t.element(find.byType(CaptureBlock))).pop();
    await t.pumpAndSettle();
    expect(calls.where((c) => c.$1 == 'secure').map((c) => c.$2), [true, false]);
    expect(ViewOncePage, isNotNull);
  });
}
