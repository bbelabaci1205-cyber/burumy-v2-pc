// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Group and channel admin tools: auto-moderation rules (and ways people try
// to get around them), stats, levels, the admin log, and the screens.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/automod.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Msg msg(String id, String sender, String body, DateTime t, {bool mine = false, String kind = 'text'}) =>
    Msg(id: id, sender: sender, body: body, time: t, mine: mine, kind: kind);

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  final now = DateTime(2026, 11, 24, 12);

  test('auto-moderation: banned words (also spaced out), new-member links, flooding', () {
    final msgs = [
      msg('a', '@old:t', '오늘 광고 받아요', now),
      msg('b', '@old:t', '광.고 문의 주세요', now),
      msg('c', '@new:t', '여기 보세요 www.cheap-shop.xyz', now),
      msg('d', '@old:t', '링크 https://naver.com', now),
      msg('e', '@admin:t', '광고 금지예요', now),
      msg('f', '@me:t', '광고', now, mine: true),
      for (var i = 0; i < 7; i++) msg('s$i', '@spam:t', 'ㅋ', now.add(Duration(seconds: i))),
    ];
    final bad = violations(
      msgs,
      words: ['광고'],
      newLinks: true,
      flood: true,
      firstSeen: {'@old:t': 0, '@new:t': now.millisecondsSinceEpoch - 3600 * 1000, '@spam:t': 0},
      admins: {'@admin:t'},
      now: now,
    );
    final ids = {for (final (m, why) in bad) m.id: why};
    expect(ids['a'], ModWhy.word);
    expect(ids['b'], ModWhy.word, reason: 'dots between letters do not get around it');
    expect(ids['c'], ModWhy.link);
    expect(ids.containsKey('d'), isFalse, reason: 'old members may post links');
    expect(ids.containsKey('e'), isFalse, reason: 'admins are never removed');
    expect(ids.containsKey('f'), isFalse, reason: 'never my own');
    expect(ids['s5'], ModWhy.flood);
    expect(ids['s6'], ModWhy.flood);
    expect(ids.containsKey('s4'), isFalse, reason: 'five in ten seconds is fine');
  });

  test('switched-off rules remove nothing; an empty word never matches', () {
    final bad = violations(
      [msg('a', '@new:t', 'http://x.com', now), for (var i = 0; i < 9; i++) msg('s$i', '@s:t', 'a', now)],
      words: const [''],
      newLinks: false,
      flood: false,
      firstSeen: const {},
      admins: const {},
      now: now,
    );
    expect(bad, isEmpty);
  });

  test('levels: stage A steps, all three numbers needed', () {
    expect(levelOf(2, 5, 100), 0);
    expect(levelOf(3, 2, 0), 1);
    expect(levelOf(10, 3, 2), 1, reason: 'too young for level 2');
    expect(levelOf(10, 3, 3), 2);
    expect(levelOf(5000, 500, 400), 5);
  });

  test('stats: last 30 days only, busiest hour, people not counted twice', () {
    final st = RoomStats.of(
      [
        msg('a', '@x:t', 'hi', now.subtract(const Duration(hours: 1))),
        msg('b', '@x:t', 'hi', now.subtract(const Duration(hours: 1))),
        msg('c', '@y:t', 'hi', now.subtract(const Duration(days: 3))),
        msg('d', '@z:t', 'old', now.subtract(const Duration(days: 40))),
        msg('e', '@z:t', '', now, kind: 'call'),
      ],
      7,
      now,
    );
    expect(st.members, 7);
    expect(st.messages30, 3);
    expect(st.active30, 2);
    expect(st.busiest, 11);
    expect(st.days.last, 2);
  });

  test('admin log keeps the newest 200 and ignores broken entries', () {
    var prefs = <String, String>{'mod_log:!r': '[{"t":"x"},{"t":1,"k":"banned","n":"bob"}]'};
    expect(modLogOf(prefs, '!r').single.name, 'bob');
    for (var i = 0; i < 250; i++) {
      prefs = {'mod_log:!r': withLogEntry(prefs, '!r', ModEntry(now, 'removed', 'n$i', 'word'))};
    }
    final log = modLogOf(prefs, '!r');
    expect(log.length, 200);
    expect(log.first.name, 'n249');
    expect(modLogOf({'mod_log:!r': 'not json'}, '!r'), isEmpty);
  });

  testWidgets('auto-moderation on an admin phone removes and logs', (t) async {
    final (s, b) = await start(t);
    b.rooms['!r1']!.add(msg('bad', '@mina:test', '광고 받아요', DateTime.now()));
    await s.setPref('automod_words:!r1', '광고');
    await s.setOn('automod_on:!r1', true);
    expect(await s.autoModRoom('!r1'), 1);
    expect(b.rooms['!r1']!.any((m) => m.id == 'bad'), isFalse);
    expect(modLogOf(s.settings, '!r1').single.detail, 'word');
    // Not an admin (channel subscriber): nothing happens.
    await s.setOn('automod_on:!c', true);
    expect(await s.autoModRoom('!c'), 0);
  });

  testWidgets('admin tools: rules with agreement, welcome, reactions, bans, theme', (t) async {
    final (s, b) = await start(t);
    await t.tap(find.text('디자인 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await tapKey(t, 'info-tools');
    expect(find.text('운영 도구'), findsWidgets);

    await tapKey(t, 'tool-rules');
    await t.enterText(find.byKey(const Key('room-text')), '1. 서로 존중해요');
    await t.tap(find.byKey(const Key('rules-agree')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('room-text-save')));
    await t.pumpAndSettle();
    expect(b.roomConfigs['!r1']!['rules'], '1. 서로 존중해요');
    expect(b.roomConfigs['!r1']!['rules_agree'], true);

    await tapKey(t, 'tool-welcome');
    await t.enterText(find.byKey(const Key('room-text')), '반가워요!');
    await t.tap(find.byKey(const Key('room-text-save')));
    await t.pumpAndSettle();
    expect(b.roomConfigs['!r1']!['welcome'], '반가워요!');

    await tapKey(t, 'tool-reactions');
    await t.tap(find.byKey(const Key('pick-some')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('react-pick-🔥')));
    await t.pumpAndSettle();
    await tapKey(t, 'react-max-minus');
    expect(b.roomConfigs['!r1']!['reactions'], 'some');
    expect(b.roomConfigs['!r1']!['reactions_set'], contains('🔥'));
    expect(b.roomConfigs['!r1']!['reactions_max'], 10);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();

    await tapKey(t, 'tool-stats');
    expect(find.byKey(const Key('stats-members')), findsOneWidget);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await tapKey(t, 'tool-log');
    expect(find.textContaining('설정을 바꿈'), findsWidgets);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();

    // Ban mina from the member list, then unban.
    await t.scrollUntilVisible(find.byKey(const Key('member-@mina:test')), -150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    // Out from under the clear top bar.
    await t.drag(find.byType(Scrollable).last, const Offset(0, 120));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('member-@mina:test')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('member-ban')));
    await t.pumpAndSettle();
    expect(await b.banned('!r1'), ['@mina:test']);
    expect(modLogOf(s.settings, '!r1').first.kind, 'banned');

    // My own background for this chat only.
    await tapKey(t, 'info-theme');
    await t.tap(find.byKey(const Key('pick-nature')));
    await t.pumpAndSettle();
    expect(s.pref('chat_theme:!r1', ''), 'nature');
    expect(s.pref('chat_theme', 'plain'), 'plain');
  });

  testWidgets('members: rules gate before writing, welcome once, hidden counts, limited reactions', (t) async {
    final (s, b) = await start(t);
    b.roomMembers['!r1'] = [Member(userId: b.userId!, name: 'me', role: 'member'), const Member(userId: '@mina:test', name: 'mina', role: 'owner')];
    b.roomConfigs['!r1'] = {'rules': '광고 금지', 'rules_agree': true, 'welcome': '어서 와요', 'hide_counts': true, 'reactions': 'none'};
    b.rooms['!r1']!.add(
      Msg(id: 'rx', sender: '@mina:test', body: '좋죠', time: DateTime.now(), mine: false, kind: 'text', reactions: const [Reaction('👍', 4, null)]),
    );
    await t.tap(find.text('디자인 팀'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('rules-gate')), findsOneWidget);
    expect(find.byKey(const Key('composer')), findsNothing);
    expect(find.byKey(const Key('welcome-card')), findsOneWidget);
    expect(find.byKey(const Key('reaction-👍')), findsNothing, reason: 'room allows no reactions');

    await t.tap(find.byKey(const Key('rules-open')));
    await t.pumpAndSettle();
    expect(find.text('광고 금지'), findsOneWidget);
    await t.tap(find.byKey(const Key('rules-agree-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsOneWidget);
    expect(s.on('agreed:!r1'), isTrue);

    await t.tap(find.byKey(const Key('welcome-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('welcome-card')), findsNothing);

    // Reactions back on but counts hidden: emoji without numbers.
    b.roomConfigs['!r1'] = {...b.roomConfigs['!r1']!, 'reactions': 'all'};
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('디자인 팀').last);
    await t.pumpAndSettle();
    expect(find.text('👍'), findsOneWidget);
    expect(find.text('👍 4'), findsNothing);
  });
}
