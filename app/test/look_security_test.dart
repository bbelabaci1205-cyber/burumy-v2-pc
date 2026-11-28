// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 5 (2026-11-27): night by time + quick switch, timers
// up to a year and for many chats, battery slider, themed / 5-minute QR,
// chat background for both people.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/core/room_theme.dart';
import 'package:burumy/l10n/app_localizations_ko.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/look_pages.dart';
import 'package:burumy/ui/qr_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  test('night by time: crosses midnight, same time = never', () {
    final at = (int h, int m) => DateTime(2026, 11, 27, h, m);
    expect(Night.inWindow(22 * 60, 7 * 60, at(23, 0)), isTrue);
    expect(Night.inWindow(22 * 60, 7 * 60, at(6, 59)), isTrue);
    expect(Night.inWindow(22 * 60, 7 * 60, at(7, 0)), isFalse);
    expect(Night.inWindow(22 * 60, 7 * 60, at(12, 0)), isFalse);
    expect(Night.inWindow(9 * 60, 18 * 60, at(12, 0)), isTrue);
    expect(Night.inWindow(600, 600, at(10, 0)), isFalse);
    expect(Night.clock(22 * 60 + 5), '22:05');
  });

  test('timer words and marks up to a year', () {
    final l = LKo();
    expect(timerText(l, 0), l.timerOff);
    expect(timerText(l, 31536000), '1년');
    expect(timerText(l, 3 * 3600), '3시간');
    expect(timerText(l, 2 * 604800), '2주');
    expect(timerShort(604800), '1w');
    expect(timerShort(86400), '1d');
    expect(timerShort(31536000), '1y');
    expect(timerShort(2 * 2592000), '2mo');
  });

  test('5-minute QR: works until its time, then not', () {
    final now = DateTime(2026, 11, 27, 10);
    final link = userLink('@me:test', until: now.add(shortQrLife));
    expect(readUserLink(link, now), '@me:test');
    expect(readUserLink(link, now.add(const Duration(minutes: 4, seconds: 59))), '@me:test');
    expect(readUserLink(link, now.add(shortQrLife)), isNull);
    expect(readUserLink(userLink('@me:test'), now.add(const Duration(days: 999))), '@me:test');
    expect(readUserLink('https://example.com', now), isNull);
  });

  test('chat background for both: newest pick wins, photo never sent', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final s = AppState(b, locale: const Locale('ko'));
    final room = await b.createDirectChat('@bob:test');
    await RoomTheme.set(s, room, 'nature', both: true);
    expect(b.sentSignals.last.$2, RoomTheme.kind);
    expect(b.sentSignals.last.$3['t'], 'nature');
    final n = b.sentSignals.length;
    await RoomTheme.set(s, room, 'photo', both: true);
    expect(b.sentSignals.length, n, reason: 'my own photo stays on my phone');

    final mine = int.parse(s.pref(RoomTheme.atPref(room), ''));
    Signal sig(String t, int at) =>
        Signal(roomId: room, id: 'x$at', sender: '@bob:test', kind: RoomTheme.kind, data: {'t': t, 'at': at}, time: DateTime.fromMillisecondsSinceEpoch(at));
    await RoomTheme.onSignal(s, sig('daily', mine - 1000));
    expect(s.pref(RoomTheme.pref(room), ''), 'photo', reason: 'an older pick does not win');
    await RoomTheme.onSignal(s, sig('daily', mine + 1000));
    expect(s.pref(RoomTheme.pref(room), ''), 'daily');
    expect(s.pref(RoomTheme.byPref(room), ''), '@bob:test');
    await RoomTheme.onSignal(s, sig('photo', mine + 5000));
    expect(s.pref(RoomTheme.pref(room), ''), 'daily', reason: 'a photo name from outside is ignored');
  });

  // Scrolls to a row, out from under the clear top bar, and taps it.
  Future<void> go(WidgetTester t, String key) async {
    final f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    // Out from under the clear top bar / the tab bar.
    final y = t.getCenter(f).dy;
    final list = find.ancestor(of: f, matching: find.byType(Scrollable)).first;
    if (y < 150 || y > 690) {
      await t.drag(list, Offset(0, y < 150 ? 180 - y : 560 - y));
      await t.pumpAndSettle();
    }
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> settings(WidgetTester t) async {
    await t.tap(find.byKey(const Key('tab-settings')));
    await t.pumpAndSettle();
  }

  testWidgets('auto night by time: pick, change start time, back to phone', (t) async {
    final (_, s) = await app(t);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await settings(t);
    await go(t, 'look-row');
    await go(t, 'auto-night');
    await go(t, 'pick-schedule');
    expect(Night.mode(s), 'schedule');
    await go(t, 'night-from');
    expect(find.byKey(const Key('night-wheel-from')), findsOneWidget);
    await s.setPref(Night.fromKey, '${21 * 60 + 30}');
    await t.pumpAndSettle();
    expect(find.text('21:30'), findsWidgets);
    await go(t, 'pick-system');
    expect(Night.mode(s), 'system');
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('timer for many chats + "1w" mark, 1 year default', (t) async {
    final (b, s) = await app(t);
    final a = await b.createDirectChat('@ann:test');
    final c = await b.createDirectChat('@cid:test');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await settings(t);
    await go(t, 'privacy-row');
    await go(t, 'default-timer-row');
    await go(t, 'pick-31536000');
    expect(s.pref('default_timer', ''), '31536000');
    await go(t, 'timer-apply');
    await go(t, 'timer-apply-$a');
    await go(t, 'timer-apply-$c');
    await t.tap(find.byKey(const Key('timer-apply-go')));
    await t.pumpAndSettle();
    expect(await b.timer(a), 31536000);
    expect(await b.timer(c), 31536000);
    expect(s.timers[a], 31536000);
    await t.pump(const Duration(seconds: 3));
    for (final n in t.stateList<NavigatorState>(find.byType(Navigator))) {
      n.popUntil((r) => r.isFirst);
    }
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tab-chats')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('timer-mark-$a')), findsOneWidget);
    expect(find.text('1y'), findsWidgets);
  });

  testWidgets('battery slider: all the way right = always', (t) async {
    final (_, s) = await app(t);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await settings(t);
    await go(t, 'power-row');
    final slider = find.byKey(const Key('power-slider'));
    await t.ensureVisible(slider);
    await t.pumpAndSettle();
    final y = t.getCenter(slider).dy;
    if (y < 150 || y > 690) {
      await t.drag(find.byType(Scrollable).first, Offset(0, y < 150 ? 180 - y : 560 - y));
      await t.pumpAndSettle();
    }
    final r = t.getRect(slider);
    await t.dragFrom(Offset(r.left + r.width * 0.3, r.center.dy), Offset(r.width, 0));
    await t.pumpAndSettle();
    expect(s.powerBelow, 100);
    expect(s.lowBattery, isTrue);
  });

  testWidgets('QR: theme cards and the 5-minute code', (t) async {
    final (_, s) = await app(t);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await settings(t);
    await t.tap(find.byKey(const Key('my-qr')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('qr-bg-app')), findsOneWidget);
    await go(t, 'qr-theme-ocean');
    expect(s.pref('qr_theme', ''), 'ocean');
    expect(find.byKey(const Key('qr-bg-ocean')), findsOneWidget);
    await go(t, 'qr-short');
    expect(find.byKey(const Key('qr-countdown')), findsOneWidget);
    expect(find.textContaining(RegExp(r'^[45]:\d\d$')), findsOneWidget);
    expect(find.byKey(const Key('qr-copy')), findsNothing, reason: 'no ID to copy in 5-minute mode');
    await go(t, 'qr-short');
    expect(find.byKey(const Key('qr-copy')), findsOneWidget);
  });
}
