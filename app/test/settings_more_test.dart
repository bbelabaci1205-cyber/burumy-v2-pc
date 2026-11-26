// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings that change what the app does: scam links, away reply, quick
// replies, auto-download, GIFs that stand still, storage, who may reach me.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/link_check.dart';
import 'package:burumy/core/storage_usage.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

FakeBackend sample() => demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());

Future<(AppState, FakeBackend)> start(WidgetTester t, {Future<void> Function(AppState s)? before}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = sample();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await before?.call(s);
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> openSettingsRow(WidgetTester t, String key) async {
  await t.tap(find.text('설정').last);
  await t.pumpAndSettle();
  final f = find.byKey(Key(key));
  await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  test('scam links: look-alikes, numbers, punycode, shorteners; real sites pass', () {
    expect(suspicious('https://naver.com/news'), isNull);
    expect(suspicious('https://m.naver.com'), isNull);
    expect(suspicious('www.coupang.com'), isNull);
    expect(suspicious('https://naver-login.help'), 'lookalike');
    expect(suspicious('https://nav3r.co/pay'), 'lookalike'); // 3 -> e
    expect(suspicious('http://kakao0bank.xyz'), 'lookalike');
    expect(suspicious('http://192.168.0.1/login'), 'ip');
    expect(suspicious('https://xn--80ak6aa92e.com'), 'punycode');
    expect(suspicious('https://bit.ly/abc'), 'short');
    expect(suspicious('https://user@toss.im.evil.com'), 'userinfo');
    expect(suspicious('https://toss.im.evil.com'), 'lookalike');
    expect(hasSuspiciousLink('택배 확인 https://cjlogistics-check.top/a 눌러 주세요'), isTrue);
    expect(hasSuspiciousLink('그냥 글이에요'), isFalse);
  });

  test('sizes read like people write them', () {
    expect(sizeText(512), '512 B');
    expect(sizeText(1536), '1.5 KB');
    expect(sizeText(250 * 1024 * 1024), '250 MB');
  });

  testWidgets('away reply: once per chat per 6 hours, only after switching on, never to my own', (t) async {
    final b = sample();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = b.rooms.keys.firstWhere((k) => b.names[k] == '김민지');
    await s.setPref('away_text', '자리에 없어요');
    await s.setPref('away_since', DateTime.now().toIso8601String());
    await s.setOn('away_on', true);
    await s.refresh(); // older messages: no reply
    expect(b.rooms[room]!.where((m) => m.body == '자리에 없어요'), isEmpty);
    b.rooms[room]!.add(Msg(id: 'n1', sender: '@mina:test', body: '있어요?', time: DateTime.now().add(const Duration(seconds: 1)), mine: false, kind: 'text'));
    await s.refresh();
    expect(b.rooms[room]!.where((m) => m.body == '자리에 없어요').length, 1);
    b.rooms[room]!.add(Msg(id: 'n2', sender: '@mina:test', body: '???', time: DateTime.now().add(const Duration(seconds: 2)), mine: false, kind: 'text'));
    await s.refresh();
    expect(b.rooms[room]!.where((m) => m.body == '자리에 없어요').length, 1);
    // Groups never get one.
    final group = b.rooms.keys.firstWhere((k) => b.names[k] == '디자인 팀');
    b.rooms[group]!.add(Msg(id: 'n3', sender: '@mina:test', body: '팀', time: DateTime.now().add(const Duration(seconds: 3)), mine: false, kind: 'text'));
    await s.refresh();
    expect(b.rooms[group]!.where((m) => m.body == '자리에 없어요'), isEmpty);
  });

  testWidgets('quick replies: saved in settings, picked from the sticker panel into the composer', (t) async {
    final (s, _) = await start(t);
    await openSettingsRow(t, 'chats-row');
    await t.scrollUntilVisible(find.byKey(const Key('quick-replies-row')), 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('quick-replies-row')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('quick-field')), '곧 갈게요');
    await t.tap(find.byKey(const Key('quick-add')));
    await t.pumpAndSettle();
    expect(find.text('곧 갈게요'), findsOneWidget);
    expect(s.pref('quick_replies', ''), '["곧 갈게요"]');
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.text('김민지').last);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-tab-phrases')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('phrase-0')));
    await t.pumpAndSettle();
    expect(find.widgetWithText(CupertinoTextField, '곧 갈게요'), findsOneWidget);
  });

  testWidgets('auto-download off: photos wait for a tap; GIFs stand still when switched off', (t) async {
    final (s, b) = await start(
      t,
      before: (s) async {
        await s.setOn('auto_dl_wifi', false);
        await s.setOn('auto_dl_cell', false);
      },
    );
    final room = b.rooms.keys.firstWhere((k) => b.names[k] == '김민지');
    b.files['gif1'] = File('test/assets/sample_photo.png').readAsBytesSync();
    await t.tap(find.text('김민지').last);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tap-to-download')), findsWidgets);
    await s.setOn('auto_dl_wifi', true);
    expect(s.autoDownload, isTrue);
    s.battery = 5;
    await s.setPref('power_below', '15');
    expect(s.calm, isTrue);
    expect(s.autoDownload, isFalse, reason: 'power saving waits for a tap');
    expect(s.gifsMove, isFalse);
    s.battery = 80;
    await s.setOn('autoplay_gif', false);
    expect(s.gifsMove, isFalse);
    expect(room, isNotEmpty);
  });

  testWidgets('storage: sizes shown and temporary files cleared', (t) async {
    var cleared = false;
    StorageUsage.read = () async => cleared ? const StorageUsage(5 << 20, 0) : const StorageUsage(5 << 20, 3 << 20);
    StorageUsage.clearCache = () async => cleared = true;
    await start(t);
    await openSettingsRow(t, 'data-row');
    expect(find.text('3.0 MB'), findsOneWidget);
    await t.tap(find.byKey(const Key('clear-cache')));
    await t.pumpAndSettle();
    expect(cleared, isTrue);
    expect(find.text('0 B'), findsOneWidget);
  });

  testWidgets('who may call me: choose, then always allow someone from contacts', (t) async {
    final (s, _) = await start(t);
    await openSettingsRow(t, 'privacy-row');
    final row = find.byKey(const Key('choice-who_calls'));
    await t.scrollUntilVisible(row, 150, scrollable: find.byType(Scrollable).last);
    await t.ensureVisible(row);
    await Scrollable.ensureVisible(t.element(row), alignment: 0.5);
    await t.pumpAndSettle();
    await t.tap(row);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pick-nobody')));
    await t.pumpAndSettle();
    expect(s.pref('who_calls', ''), 'nobody');
    await t.tap(find.byKey(const Key('who-allow')));
    await t.pumpAndSettle();
    await t.tap(find.byWidgetPredicate((w) => w is CupertinoListTile).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('people-done')));
    await t.pumpAndSettle();
    expect(s.pref('who_calls_allow', ''), isNotEmpty);
  });

  testWidgets('notifications: kind page, our sound, focus days, in-app style', (t) async {
    final (s, _) = await start(t);
    await openSettingsRow(t, 'notify-row');
    await t.tap(find.byKey(const Key('notice-group')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sound-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sound-drop')));
    await t.pumpAndSettle();
    expect(s.pref('sound_group', ''), 'drop');
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('add-exception')));
    await t.pumpAndSettle();
    await t.tap(find.text('디자인 팀').last);
    await t.pumpAndSettle();
    expect(s.settings.entries.where((e) => e.key.startsWith('notify_group:') && e.value == '0'), isNotEmpty);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('focus-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pref-focus_on')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('focus-day-7')));
    await t.pumpAndSettle();
    expect(s.pref('focus_days', ''), '123456');
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('in-app-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('in-app-silent')));
    await t.pumpAndSettle();
    expect(s.pref('in_app_style', ''), 'silent');
  });

  testWidgets('profile: first + last name, bio, remove photo, empty name cannot be saved', (t) async {
    final (s, b) = await start(t);
    b.photo = File('test/assets/sample_photo.png').readAsBytesSync();
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('settings-edit')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('profile-name')), '');
    await t.pump();
    await t.tap(find.byKey(const Key('profile-save')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('profile-name')), findsOneWidget, reason: 'no empty name');
    await t.enterText(find.byKey(const Key('profile-name')), '민지');
    await t.enterText(find.byKey(const Key('profile-last')), '김');
    await t.enterText(find.byKey(const Key('profile-bio')), '안녕하세요');
    await t.tap(find.byKey(const Key('change-photo')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('photo-remove')));
    await t.pumpAndSettle();
    expect(b.photo, isNull);
    await t.tap(find.byKey(const Key('profile-save')));
    await t.pumpAndSettle();
    expect(await b.myName(), '김민지');
    expect(s.pref('last_name', ''), '김');
    expect(await b.bioOf(b.userId!), '안녕하세요');
  });
}
