// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Several accounts on one phone (Telegram-style switch, Eric 2026-11-27):
// add / cancel / switch, the Settings-tab hold menu, the paid limit, and
// the fourth lock password that erases chosen accounts from this phone.
import 'package:burumy/core/accounts.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart' show AccountsHost;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<(Accounts, Map<int, FakeBackend>)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final lock = FakeLock();
  final made = <int, FakeBackend>{};
  final accounts = Accounts(
    store: MemoryBookStore(),
    openSlot: (slot) async => made[slot] ??= FakeBackend(lock: lock),
    eraseSlot: (slot) async => made.remove(slot),
    makeState: (b) => AppState(b, locale: const Locale('ko')),
  );
  final s = await accounts.load();
  await s.login('me', 'x');
  await made[0]!.createDirectChat('bob');
  await s.refresh();
  await t.pumpWidget(AccountsHost(accounts: accounts));
  await t.pumpAndSettle();
  return (accounts, made);
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> openSettings(WidgetTester t) => tap(t, find.byKey(const Key('tab-settings')));

Future<void> addVia(WidgetTester t, String id) async {
  await openSettings(t);
  await tap(t, find.byKey(const Key('account-add')));
  // An empty sign-in page, with a way back.
  expect(find.byKey(const Key('auth-cancel-add')), findsOneWidget);
  await tap(t, find.text('이미 계정이 있어요'));
  await t.enterText(find.byKey(const Key('auth-id')), id);
  await t.enterText(find.byKey(const Key('auth-pw')), 'pass1234');
  await tap(t, find.byKey(const Key('auth-submit')));
}

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
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
  });
  tearDown(() => Accounts.testOpen = true);

  testWidgets('shots: Settings with two accounts, the hold menu, app lock', (t) async {
    final (a, made) = await start(t);
    await addVia(t, 'mina');
    await a.switchTo(0);
    await t.pumpAndSettle();
    await made[a.list.last.slot]!.createDirectChat('zed');
    made[a.list.last.slot]!.unreadCounts.clear();
    await openSettings(t);
    await expectLater(find.byType(AccountsHost), matchesGoldenFile('shots/ko_24_accounts.png'));
    await t.longPress(find.byKey(const Key('tab-settings')));
    await t.pumpAndSettle();
    await expectLater(find.byType(AccountsHost), matchesGoldenFile('shots/ko_25_accounts_hold.png'));
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    made[0]!.lk.normalPw = 'normal123';
    await t.scrollUntilVisible(find.byKey(const Key('privacy-row')), 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('privacy-row')));
    await tap(t, find.byKey(const Key('app-lock')));
    await t.enterText(find.byKey(const Key('lock-gate')), 'normal123');
    await tap(t, find.byKey(const Key('lock-gate-ok')));
    await t.dragUntilVisible(find.byKey(const Key('lock-account-list')), find.byType(ListView).last, const Offset(0, -200));
    await t.pumpAndSettle();
    await expectLater(find.byType(AccountsHost), matchesGoldenFile('shots/ko_26_lock_accounts.png'));
    a.state.stopLive();
  });

  testWidgets('add an account, cancel, add again, switch back and forth', (t) async {
    final (a, made) = await start(t);
    expect(a.list, hasLength(1));
    await openSettings(t);
    await tap(t, find.byKey(const Key('account-add')));
    await tap(t, find.byKey(const Key('auth-cancel-add')));
    expect(a.active, 0);
    expect(a.list, hasLength(1));
    expect(a.state.loggedIn, isTrue);

    await addVia(t, 'mina');
    expect(a.list.map((e) => e.userId), ['@me:test', '@mina:test']);
    expect(a.state.backend.userId, '@mina:test');
    // Settings lists the other account; a tap switches to it.
    await openSettings(t);
    expect(find.byKey(const Key('account-0')), findsOneWidget);
    await tap(t, find.byKey(const Key('account-0')));
    expect(a.active, 0);
    expect(a.state.backend.userId, '@me:test');
    // Holding the Settings tab: every account, mine ticked, and 계정 추가.
    await t.longPress(find.byKey(const Key('tab-settings')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('switch-0')), findsOneWidget);
    expect(find.byKey(const Key('switch-add')), findsOneWidget);
    await tap(t, find.byKey(Key('switch-${a.list.last.slot}')));
    expect(a.state.backend.userId, '@mina:test');
    a.state.stopLive();
  });

  testWidgets('the same account can not come twice', (t) async {
    final (a, _) = await start(t);
    await addVia(t, 'me');
    expect(find.text('이미 이 휴대폰에 있는 계정이에요'), findsOneWidget);
    expect(a.list, hasLength(1));
    a.state.stopLive();
  });

  testWidgets('past the limit: a note on Plus and buying (no payment yet)', (t) async {
    final (a, _) = await start(t);
    Accounts.testOpen = false;
    expect(a.limit, 1);
    await openSettings(t);
    await tap(t, find.byKey(const Key('account-add')));
    expect(find.text('계정을 더 쓰려면'), findsOneWidget);
    await tap(t, find.byKey(const Key('accounts-limit-ok')));
    expect(a.adding, isFalse);
    a.plus = true;
    expect(a.limit, 2);
    a.bought = 1;
    expect(a.limit, 3);
    a.bought = 5;
    expect(a.limit, Accounts.most);
    a.state.stopLive();
  });

  testWidgets('account password: chosen accounts leave this phone, the rest opens', (t) async {
    final (a, made) = await start(t);
    await addVia(t, 'mina');
    final mina = a.active;
    final lock = made[0]!.lk;
    lock.normalPw = 'normal123';
    lock.accountPw = 'account99';
    // Never every account.
    await a.setToErase({0, mina});
    expect(a.toErase, hasLength(1));
    await a.setToErase({mina});
    expect(a.toErase, {mina});
    // Locked while mina is on screen; the account password opens "me".
    await a.state.checkLock();
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lock-password')), 'account99');
    await tap(t, find.byKey(const Key('lock-open')));
    expect(a.list.map((e) => e.userId), ['@me:test']);
    expect(a.active, 0);
    expect(a.state.backend.userId, '@me:test');
    expect(made.containsKey(mina), isFalse, reason: 'its store is erased');
    expect(find.text('bob'), findsWidgets);
    expect(find.byKey(const Key('lock-password')), findsNothing);
    a.state.stopLive();
  });

  testWidgets('hide password hides in every account; wrong-try wipe erases every account', (t) async {
    final (a, made) = await start(t);
    await addVia(t, 'mina');
    final mina = a.active;
    await made[mina]!.createDirectChat('zed');
    await a.switchTo(0);
    await t.pumpAndSettle();
    final lock = made[0]!.lk;
    lock.normalPw = 'normal123';
    lock.hidePw = 'hidden123';
    await a.state.checkLock();
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lock-password')), 'hidden123');
    await tap(t, find.byKey(const Key('lock-open')));
    expect(made[0]!.role, 'hide');
    expect(made[mina]!.role, 'hide');
    // Ten wrong tries: both accounts' chats go.
    await a.state.checkLock();
    await t.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      await t.enterText(find.byKey(const Key('lock-password')), 'wrong$i-xx');
      await tap(t, find.byKey(const Key('lock-open')));
    }
    expect(made[0]!.rooms, isEmpty);
    expect(made[mina]!.rooms, isEmpty);
    a.state.stopLive();
  });

  testWidgets('log out: the account leaves, the other one comes on screen', (t) async {
    final (a, made) = await start(t);
    await addVia(t, 'mina');
    final mina = a.active;
    await a.state.logout();
    await t.pumpAndSettle();
    expect(a.list.map((e) => e.userId), ['@me:test']);
    expect(a.active, 0);
    expect(made.containsKey(mina), isFalse);
    a.state.stopLive();
  });
}
