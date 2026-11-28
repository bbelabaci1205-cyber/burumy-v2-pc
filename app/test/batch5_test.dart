// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// v1 parity batch 5 (2026-11-27): remove from contacts, tidy up quiet
// chats, don't let people find me by ID.
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/keyword_replies.dart';
import 'package:burumy/core/room_rules.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/core/rules.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/location.dart';
import 'package:burumy/ui/my_look.dart';
import 'package:burumy/ui/name_colors.dart';
import 'package:burumy/ui/room_tools.dart';
import 'package:burumy/ui/tidy_chats.dart';
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

  Future<void> tap(WidgetTester t, Finder f) async {
    if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  testWidgets('remove from contacts: the chat stays, opening it brings them back', (t) async {
    final (b, s) = await app(t);
    await b.createDirectChat('bob');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('tab-contacts')));
    expect(find.text('bob'), findsOneWidget);
    await t.longPress(find.text('bob'));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('contact-remove')));
    expect(find.text('bob'), findsNothing);
    expect(s.removedContacts, {'@bob:test'});
    expect(b.rooms, hasLength(1), reason: 'the chat itself stays');
    await s.removeContact('@bob:test', removed: false);
    expect(s.removedContacts, isEmpty);
  });

  test('quiet chats: groups and channels silent for 6 months', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final now = b.clock;
    Msg at(Duration ago) => Msg(id: 'x', sender: '@a:test', body: 'hi', time: now.subtract(ago), mine: false, kind: 'text');
    ChatPreview c(String id, {bool direct = false, Msg? last}) => ChatPreview(roomId: id, name: id, isDirect: direct, encrypted: true, unread: 0, last: last);
    final list = quietChats([
      c('old', last: at(const Duration(days: 200))),
      c('new', last: at(const Duration(days: 3))),
      c('dm', direct: true, last: at(const Duration(days: 300))),
      c('empty'),
    ], now);
    expect(list.map((x) => x.roomId), ['old']);
  });

  testWidgets('tidy up: picks quiet groups, leaves them after the undo time', (t) async {
    final (b, s) = await app(t);
    final old = await b.createGroup('Camp', ['@mina:test']);
    b.rooms[old] = [Msg(id: 'o1', sender: '@mina:test', body: 'bye', time: b.clock.subtract(const Duration(days: 240)), mine: false, kind: 'text')];
    final fresh = await b.createGroup('Team', ['@mina:test']);
    await b.sendText(fresh, 'hi');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('tab-settings')));
    await tap(t, find.byKey(const Key('chats-row')));
    await tap(t, find.byKey(const Key('tidy-row')));
    expect(find.byKey(Key('tidy-$old')), findsOneWidget);
    expect(find.byKey(Key('tidy-$fresh')), findsNothing);
    await tap(t, find.byKey(const Key('tidy-leave')));
    expect(find.byKey(const Key('list-undo-bar')), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await t.pumpAndSettle();
    expect(s.chats.any((c) => c.roomId == old), isFalse);
    expect(s.chats.any((c) => c.roomId == fresh), isTrue);
    expect(find.byKey(const Key('tidy-empty')), findsOneWidget);
  });

  testWidgets("don't let people find me by ID: tells the server", (t) async {
    final (b, s) = await app(t);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('tab-settings')));
    await tap(t, find.byKey(const Key('privacy-row')));
    await tap(t, find.byKey(const Key('pref-no_id_search')));
    expect(b.idSearchHidden, isTrue);
    expect(s.on('no_id_search'), isTrue);
  });

  test('keyword replies: one answer per message, a word once a minute', () {
    final rules = [(word: '회비', answer: '매달 1만 원이에요')];
    final t0 = DateTime(2026, 11, 27, 10);
    Msg m(String id, String body, int sec, {bool mine = false}) => Msg(
      id: id,
      sender: '@a:test',
      body: body,
      time: t0.add(Duration(seconds: sec)),
      mine: mine,
      kind: 'text',
    );
    final out = keywordAnswers(
      [m('1', '회비 얼마예요?', 1), m('2', '회비 언제 내요', 20), m('3', '저도 회비', 90), m('4', '회비', 100, mine: true), m('5', '안녕', 110)],
      rules,
      t0,
      const {},
    );
    expect(out.map((x) => x.$1.id), ['1', '3']);
    expect(keywordFor('HELLO', [(word: 'hello', answer: 'hi')])?.answer, 'hi');
  });

  test('keyword replies: the admin phone answers in the group', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('Club', ['@mina:test']);
    await s.refresh();
    await s.setPref(keywordKey(room), encodeKeywordRules([(word: '회비', answer: '매달 1만 원이에요')]));
    await s.setPref('keyword_seen:$room', '${b.clock.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch}');
    b.rooms[room]!.add(Msg(id: 'q1', sender: '@mina:test', body: '회비 얼마예요?', time: b.clock, mine: false, kind: 'text'));
    await s.refresh();
    expect(b.rooms[room]!.last.body, '매달 1만 원이에요');
    expect(b.rooms[room]!.last.replyTo, 'q1');
    final n = b.rooms[room]!.length;
    await s.refresh();
    expect(b.rooms[room]!.length, n, reason: 'answered once');
  });

  testWidgets('search filter: photos only', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, 'hello');
    await b.sendFile(
      room,
      name: 'pic.png',
      mime: 'image/png',
      bytes: const [
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        2,
        8,
        2,
        0,
        0,
        0,
        253,
        212,
        154,
        115,
        0,
        0,
        0,
        22,
        73,
        68,
        65,
        84,
        120,
        156,
        99,
        100,
        56,
        17,
        192,
        192,
        192,
        192,
        196,
        192,
        192,
        192,
        192,
        192,
        0,
        0,
        12,
        250,
        1,
        28,
        130,
        57,
        77,
        12,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ],
    );
    await b.sendFile(room, name: 'doc.pdf', mime: 'application/pdf', bytes: [1]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.text('bob'));
    await tap(t, find.byKey(const Key('chat-title')));
    await tap(t, find.byKey(const Key('info-search')).last);
    await tap(t, find.byKey(const Key('search-kind')));
    await tap(t, find.byKey(const Key('search-kind-photo')));
    expect(find.text('1/1'), findsOneWidget);
    await tap(t, find.byKey(const Key('search-cancel')));
    await tap(t, find.byKey(const Key('chat-title')));
    await tap(t, find.byKey(const Key('info-search')).last);
    await tap(t, find.byKey(const Key('search-kind')));
    await tap(t, find.byKey(const Key('search-kind-file')));
    expect(find.text('1/1'), findsOneWidget);
  });

  test('night mode: members quiet between the hours, admins never', () {
    final cfg = {'night': RoomRules.nightConfig('23-7', const Duration(hours: 9))};
    expect(RoomRules.nightValue(cfg), '23-7');
    // 01:00 KST = 16:00 UTC the day before.
    final kst1am = DateTime.utc(2026, 11, 26, 16);
    expect(RoomRules.nightUntil(cfg, 'member', kst1am), 7);
    expect(RoomRules.nightUntil(cfg, 'admin', kst1am), isNull);
    // 12:00 KST.
    expect(RoomRules.nightUntil(cfg, 'member', DateTime.utc(2026, 11, 26, 3)), isNull);
    final day = {'night': RoomRules.nightConfig('0-6', Duration.zero)};
    expect(RoomRules.nightUntil(day, 'member', DateTime.utc(2026, 1, 1, 5)), 6);
    expect(RoomRules.nightUntil(day, 'member', DateTime.utc(2026, 1, 1, 6)), isNull);
    expect(RoomRules.nightConfig('off', Duration.zero), isNull);
  });

  testWidgets('one post to several channels at once', (t) async {
    final (b, s) = await app(t);
    final a = await b.createGroup('News A', const [], channel: true);
    final c = await b.createGroup('News B', const [], channel: true);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.text('News A'));
    await t.enterText(find.byKey(const Key('composer')), '공지예요');
    await t.pump();
    await t.longPress(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send-many')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('send-many-$c')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send-many-go')));
    await t.pumpAndSettle();
    expect(b.rooms[a]!.last.body, '공지예요');
    expect(b.rooms[c]!.last.body, '공지예요');
  });

  testWidgets('raid lock: link joins wait for an admin, off restores the link', (t) async {
    final (b, s) = await app(t);
    final room = await b.createGroup('Open club', ['@mina:test']);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    unawaited(
      t
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(
            IosPageRoute(
              builder: (_) => ManageToolsPage(roomId: room, isChannel: false, role: 'owner'),
            ),
          ),
    );
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('tool-raid')));
    expect((await b.roomLink(room)).approval, isTrue);
    expect((await b.roomConfig(room))['raid'], isTrue);
    await tap(t, find.byKey(const Key('tool-raid')));
    expect((await b.roomLink(room)).approval, isFalse);
    expect((await b.roomConfig(room))['raid'], isNull);
  });

  testWidgets("message requests: a stranger's chat waits apart, accept or delete", (t) async {
    final (b, s) = await app(t);
    b.invites.add(const Invite(roomId: '!s1', name: 'kim', inviter: '@kim:test', direct: true));
    b.invites.add(const Invite(roomId: '!s2', name: 'spam', inviter: '@spam:test', direct: true));
    await s.refresh();
    expect(s.requests.map((c) => c.roomId).toSet(), {'!s1', '!s2'});
    expect(
      noticeAllowed(Notice(roomId: '!s1', chat: 'kim', sender: 'kim', kind: 'text', body: 'hi', time: b.clock), s.settings, s.requests.first, b.clock),
      isFalse,
    );
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('requests-row')), findsOneWidget);
    await tap(t, find.byKey(const Key('requests-row')));
    await tap(t, find.text('@kim:test').first);
    expect(find.byKey(const Key('request-bar')), findsOneWidget);
    await tap(t, find.byKey(const Key('request-accept')));
    expect(find.byKey(const Key('request-bar')), findsNothing);
    expect(s.isRequest('!s1'), isFalse);
    expect(s.friendIds, contains('@kim:test'));
    await s.declineRequest('!s2', block: true);
    expect(s.requests, isEmpty);
    expect(b.blockedIds, contains('@spam:test'));
  });

  testWidgets('name colour for all my groups, and my own name in one group', (t) async {
    final (b, s) = await app(t);
    final g1 = await b.createGroup('Club', ['@mina:test']);
    final g2 = await b.createGroup('Team', ['@mina:test']);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    unawaited(t.state<NavigatorState>(find.byType(Navigator).first).push(IosPageRoute(builder: (_) => const NameColorPage())));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('name-color-blue')));
    expect(await b.nameColors(g1), {'@me:test': 'blue'});
    expect(await b.nameColors(g2), {'@me:test': 'blue'});
    expect(NameColors.colorFor('@me:test', 'me'), NameColors.colorOf('blue'));
    await b.setMyRoomLook(g1, name: '총무 민지');
    expect((await b.members(g1)).firstWhere((m) => m.userId == '@me:test').name, '총무 민지');
    expect((await b.members(g2)).firstWhere((m) => m.userId == '@me:test').name, isNot('총무 민지'));
  });

  testWidgets('live location: moves each minute, ends by itself or when stopped', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await s.refresh();
    var lat = 37.5;
    s.whereAmI = () async => GeoFix(lat, 127.0, 10);
    await s.startLiveLocation(room, const Duration(minutes: 15));
    final id = s.liveShares[room]!.$1;
    expect(GeoPoint.liveUntil(b.rooms[room]!.last.body), isNotNull);
    lat = 37.6;
    await s.moveLiveLocations();
    expect(b.rooms[room]!.last.body, startsWith('geo:37.600000,127.000000'));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await tap(t, find.text('bob'));
    expect(find.byKey(const Key('live-on')), findsOneWidget);
    expect(find.byKey(const Key('edited')), findsNothing);
    await tap(t, find.byKey(const Key('live-stop')));
    expect(s.liveShares, isEmpty);
    expect(b.rooms[room]!.firstWhere((m) => m.id == id).body, isNot(contains('37.5')));
    expect(GeoPoint.liveUntil(b.rooms[room]!.firstWhere((m) => m.id == id).body)!.isAfter(b.clock), isFalse);
  });
}
