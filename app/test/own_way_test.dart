// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 우리식 기능 묶음: 캡처 알림, 제일 친한 친구 ❤, 1년 전 오늘, 친구 피드
// '아는 친구 댓글만'.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/best_friend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/feed_comments.dart';
import 'package:burumy/core/memories.dart';
import 'package:burumy/core/screen_guard.dart';
import 'package:burumy/core/shot_alert.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Msg msg(String id, bool mine, DateTime t, {String kind = 'text', bool once = false}) =>
    Msg(id: id, sender: mine ? '@me:test' : '@x:test', body: 'hi', time: t, mine: mine, kind: kind, viewOnce: once);

void main() {
  setUp(() {
    Features.ownWay = true;
    Features.feed = true;
  });
  tearDown(() {
    Features.ownWay = false;
    Features.feed = false;
    ScreenGuard.onShot = null;
  });

  final now = DateTime(2026, 11, 28, 12);

  group('제일 친한 친구', () {
    List<Msg> talk(int mine, int theirs, {int daysAgo = 1}) => [
      for (var i = 0; i < mine; i++) msg('m$i', true, now.subtract(Duration(days: daysAgo, minutes: i))),
      for (var i = 0; i < theirs; i++) msg('t$i', false, now.subtract(Duration(days: daysAgo, minutes: i))),
    ];

    test('both ways count: the smaller side decides', () {
      // A: 50 from them, 2 from me (not a best friend). B: 8 and 9.
      expect(BestFriend.pick({'A': talk(2, 50), 'B': talk(8, 9)}, now), 'B');
    });

    test('nobody below 5 each, and old messages do not count', () {
      expect(BestFriend.pick({'A': talk(4, 30)}, now), isNull);
      expect(BestFriend.pick({'A': talk(9, 9, daysAgo: 20)}, now), isNull);
    });

    test('calls and capture lines are not words to each other', () {
      final calls = [for (var i = 0; i < 10; i++) msg('c$i', i.isEven, now.subtract(Duration(hours: i)), kind: 'call')];
      expect(BestFriend.pick({'A': calls}, now), isNull);
    });
  });

  group('1년 전 오늘', () {
    test('pictures saved on this day in earlier years, newest year first', () {
      final saved = [
        msg('a', true, DateTime(2025, 11, 28, 9), kind: 'image'),
        msg('b', true, DateTime(2024, 11, 28, 9), kind: 'video'),
        msg('c', true, DateTime(2025, 11, 27, 9), kind: 'image'),
        msg('d', true, DateTime(2025, 11, 28, 9)),
        msg('e', true, DateTime(2025, 11, 28, 9), kind: 'image', once: true),
        msg('f', true, DateTime(2026, 11, 28, 9), kind: 'image'),
      ];
      final days = Memories.pick(saved, now);
      expect([for (final d in days) d.years], [1, 2]);
      expect([for (final m in days.first.msgs) m.id], ['a']);
      expect(Memories.count(days), 2);
    });

    test('29 February shows on 28 February in other years', () {
      expect(Memories.sameDay(DateTime(2024, 2, 29), DateTime(2027, 2, 28)), isTrue);
      expect(Memories.sameDay(DateTime(2024, 2, 29), DateTime(2028, 2, 28)), isFalse);
    });
  });

  group('캡처 알림', () {
    test('a screenshot over protected content tells the chat, once per burst', () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      final room = await fake.createDirectChat('@mina:test');
      await s.refresh();
      s.openRoom = room;
      // Nothing protected on screen: nothing is sent.
      ScreenGuard.debugShot();
      await Future<void>.delayed(Duration.zero);
      expect(fake.sentSignals.where((x) => x.$2 == ShotAlert.kind), isEmpty);
      await ScreenGuard.hold('photo');
      ScreenGuard.debugShot();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      ScreenGuard.debugShot();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await ScreenGuard.release('photo');
      final sent = fake.sentSignals.where((x) => x.$2 == ShotAlert.kind).toList();
      expect(sent, hasLength(1));
      expect(sent.single.$1, room);
      expect(sent.single.$3['w'], 'photo');
      expect(ShotAlert.lines(s, room).single.what, 'photo');
    });

    test("someone else's notice becomes a line between the messages", () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      final t = DateTime(2026, 11, 28, 10);
      await ShotAlert.onSignal(s, Signal(roomId: '!a', id: 'e1', sender: '@mina:test', kind: ShotAlert.kind, data: {'w': 'video'}, time: t));
      final shots = ShotAlert.asMsgs(s, '!a');
      expect(shots.single.kind, 'shot');
      final mixed = ShotAlert.mix([msg('1', true, t.subtract(const Duration(minutes: 1))), msg('2', false, t.add(const Duration(minutes: 1)))], shots);
      expect([for (final m in mixed) m.id], ['1', shots.single.id, '2']);
      // An unknown kind of content reads as the chat.
      expect(ShotAlert.whatOf('evil'), 'chat');
    });
  });

  group('피드 댓글 (아는 친구 댓글만)', () {
    Story post({required bool mine, String id = 'p1', String room = '!r', String sender = '@mina:test'}) =>
        Story(id: id, roomId: room, eventId: id, sender: mine ? '@me:test' : sender, mine: mine, time: now, kind: 'text', feed: true);

    test("on a friend's post I see only people I know, me and the poster", () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      s.friendIds = {'@leo:test', '@mina:test'};
      final p = post(mine: false);
      s.feed = [p];
      await s.setPref(
        'feed_c:p1',
        '[{"i":"1","w":"@leo:test","t":"hi","a":1},{"i":"2","w":"@stranger:test","t":"yo","a":2},{"i":"3","w":"@mina:test","t":"thx","a":3}]',
      );
      expect([for (final c in FeedComments.visible(s, p)) c.id], ['1', '3']);
      // My own comment goes to the poster only.
      await FeedComments.add(s, p, '멋지다');
      final sent = fake.sentSignals.where((x) => x.$2 == FeedComments.sendKind).single;
      expect(sent.$1, '!r');
      expect(sent.$3['p'], 'p1');
      expect(FeedComments.visible(s, p).last.text, '멋지다');
    });

    test('a list from someone who is not the poster is ignored', () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      s.feed = [post(mine: false)];
      await FeedComments.onList(s, Signal(roomId: '!r', id: 'e', sender: '@evil:test', kind: FeedComments.listKind, data: {'p': 'p1', 'c': []}, time: now));
      await FeedComments.onList(
        s,
        Signal(
          roomId: '!r',
          id: 'e2',
          sender: '@mina:test',
          kind: FeedComments.listKind,
          data: {
            'p': 'p1',
            'c': [
              {'i': 'x', 'w': '@leo:test', 't': 'hey', 'a': 5},
            ],
          },
          time: now,
        ),
      );
      expect(FeedComments.all(s, 'p1').single.id, 'x');
    });

    test("on my post a friend's comment is handed to the post's friends only", () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      final p = post(mine: true);
      s.feed = [p];
      await s.setPref(FeedComments.audienceKey('p1'), '!a,!b');
      await FeedComments.onComment(
        s,
        Signal(roomId: '!a', id: 'e', sender: '@stranger:test', kind: FeedComments.sendKind, data: {'p': 'p1', 'i': 'c1', 't': 'hello', 'a': 1}, time: now),
      );
      expect(FeedComments.visible(s, p).single.who, '@stranger:test', reason: 'the poster sees everyone');
      final out = fake.sentSignals.where((x) => x.$2 == FeedComments.listKind).toList();
      expect([for (final x in out) x.$1], ['!a', '!b']);
    });

    test('a post whose audience is not known here hands the comments to nobody (보안검수)', () async {
      final fake = FakeBackend();
      await fake.login(id: 'me', password: 'x');
      final s = AppState(fake, locale: const Locale('ko'));
      final p = post(mine: true);
      s.feed = [p];
      await FeedComments.onComment(
        s,
        Signal(roomId: '!a', id: 'e', sender: '@mina:test', kind: FeedComments.sendKind, data: {'p': 'p1', 'i': 'c1', 't': 'hello', 'a': 1}, time: now),
      );
      expect(FeedComments.all(s, 'p1').single.id, 'c1', reason: 'kept on my phone');
      expect(fake.sentSignals.where((x) => x.$2 == FeedComments.listKind), isEmpty);
    });
  });

  testWidgets('chat list: ❤ beside the best friend, capture line as the preview', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@mina:test');
    fake.peers[room] = '@mina:test';
    final base = fake.clock.subtract(const Duration(hours: 3));
    fake.rooms[room]!.addAll([
      for (var i = 0; i < 12; i++)
        Msg(
          id: 'w$i',
          sender: i.isEven ? '@me:test' : '@mina:test',
          body: 'hi $i',
          time: base.add(Duration(minutes: i)),
          mine: i.isEven,
          kind: 'text',
        ),
    ]);
    final s = AppState(fake, locale: const Locale('ko'));
    await s.refresh();
    await ShotAlert.onSignal(s, Signal(roomId: room, id: 'e', sender: '@mina:test', kind: ShotAlert.kind, data: {'w': 'photo'}, time: fake.clock));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('best-friend')), findsOneWidget);
    expect(find.textContaining('캡처했어요'), findsOneWidget);
    // Switched off in Settings: no ❤.
    await s.setOn(BestFriend.pref, false);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('best-friend')), findsNothing);
  });
}
