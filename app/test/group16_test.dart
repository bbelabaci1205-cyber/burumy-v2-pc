// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch #16 (groups, 2026-11-27): 94 익명 관리자, 556 멤버
// 태그 (스스로 달기), 365 강력 스팸 차단 + 가루 효과, 384 누가 읽었는지.
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/automod.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/group_tools.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/dust_out.dart';
import 'package:burumy/ui/room_tools.dart';
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

  Msg msg(String id, String from, String text, DateTime at) => Msg(id: id, sender: from, body: text, time: at, mine: from == '@me:test', kind: 'text');

  // ---- 94 익명 관리자 --------------------------------------------------

  test('anonymous admins: periods, old messages stay as sent, plain members hidden', () {
    final t0 = DateTime(2026, 11, 27, 10);
    var cfg = <String, dynamic>{};
    cfg = {'anon': AnonAdmins.withAnon(cfg, '@sujin:test', true, t0)};
    expect(AnonAdmins.isOn(cfg, '@sujin:test'), isTrue);
    expect(AnonAdmins.current(cfg), {'@sujin:test'});
    final during = msg('a', '@sujin:test', '공지', t0.add(const Duration(minutes: 5)));
    final before = msg('b', '@sujin:test', '예전 글', t0.subtract(const Duration(minutes: 5)));
    expect(AnonAdmins.sentAnon(cfg, during), isTrue);
    expect(AnonAdmins.sentAnon(cfg, before), isFalse);
    // Off later: what was sent while anonymous stays anonymous.
    cfg = {'anon': AnonAdmins.withAnon(cfg, '@sujin:test', false, t0.add(const Duration(hours: 1)))};
    expect(AnonAdmins.isOn(cfg, '@sujin:test'), isFalse);
    expect(AnonAdmins.sentAnon(cfg, during), isTrue);
    expect(AnonAdmins.sentAnon(cfg, msg('c', '@sujin:test', '이후', t0.add(const Duration(hours: 2)))), isFalse);
    // Someone else can't borrow it.
    expect(AnonAdmins.sentAnon(cfg, msg('d', '@mina:test', '공지', t0.add(const Duration(minutes: 5)))), isFalse);
    // On and off at the same moment leaves nothing behind.
    final quick = AnonAdmins.withAnon({'anon': AnonAdmins.withAnon({}, '@x:test', true, t0)}, '@x:test', false, t0);
    expect(quick, isEmpty);
    // Member list.
    final on = {'anon': AnonAdmins.withAnon({}, '@sujin:test', true, t0)};
    const people = [Member(userId: '@me:test', name: 'me', role: 'member'), Member(userId: '@sujin:test', name: '수진', role: 'admin')];
    expect(AnonAdmins.visible(people, on, viewerIsAdmin: false, me: '@me:test').map((m) => m.name), ['me']);
    expect(AnonAdmins.visible(people, on, viewerIsAdmin: true, me: '@me:test'), hasLength(2));
  });

  Future<String> anonGroup(FakeBackend b, {String myRole = 'member'}) async {
    final g = await b.createGroup('동네 러닝 크루', ['@sujin:test', '@mina:test']);
    final t0 = b.now.subtract(const Duration(hours: 2));
    b.roomMembers[g] = [
      Member(userId: '@me:test', name: 'me', role: myRole),
      const Member(userId: '@sujin:test', name: '수진', role: 'admin'),
      const Member(userId: '@mina:test', name: '민아', role: 'member'),
    ];
    b.roomConfigs[g] = {'anon': AnonAdmins.withAnon({}, '@sujin:test', true, t0)};
    b.rooms[g] = [
      msg('n1', '@sujin:test', '이번 주 토요일 7시 한강에서 모여요', t0.add(const Duration(minutes: 10))),
      msg('n2', '@mina:test', '좋아요!', t0.add(const Duration(minutes: 12))),
    ];
    return g;
  }

  testWidgets('anonymous admin: the message shows the group, not the admin', (t) async {
    final (b, s) = await app(t);
    final g = await anonGroup(b);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 러닝 크루').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sender-anon')), findsOneWidget);
    expect(find.text('익명 관리자'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('sender-anon')), matching: find.text('동네 러닝 크루')), findsOneWidget);
    expect(find.textContaining('sujin'), findsNothing);
    expect(find.textContaining('수진'), findsNothing);
    expect(find.textContaining('민아'), findsWidgets, reason: 'other members keep their names (shown by name, not @id)');
    expect(g, isNotEmpty);
    s.stopLive();
  });

  // ---- 556 멤버 태그 ---------------------------------------------------

  test('member tags: admin-given tag wins, own tags only when allowed', () {
    const own = {'@mina:test': '러닝 3년차', '@me:test': '새내기'};
    expect(MemberTags.of({}, own, '@mina:test'), isNull, reason: 'off by default');
    final cfg = {
      'own_tags': true,
      'tags': {'@sujin:test': '총무'},
    };
    expect(MemberTags.of(cfg, own, '@mina:test')!.text, '러닝 3년차');
    expect(MemberTags.of(cfg, own, '@mina:test')!.byAdmin, isFalse);
    expect(MemberTags.of(cfg, {...own, '@sujin:test': '아무거나'}, '@sujin:test')!.text, '총무');
    expect(MemberTags.of(cfg, own, '@sujin:test')!.byAdmin, isTrue);
    expect(MemberTags.canEditOwn(cfg, 'member', '@me:test'), isTrue);
    expect(MemberTags.canEditOwn(cfg, 'member', '@sujin:test'), isFalse, reason: 'an admin set it');
    expect(MemberTags.canEditOwn({}, 'member', '@me:test'), isFalse);
  });

  testWidgets('member tags: own tag next to the name in chat; my tag from group info', (t) async {
    final (b, s) = await app(t);
    final g = await anonGroup(b);
    b.roomConfigs[g] = {'own_tags': true};
    b.ownTags[g] = {'@mina:test': '러닝 3년차'};
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 러닝 크루').first);
    await t.pumpAndSettle();
    expect(find.text('러닝 3년차'), findsOneWidget);
    s.stopLive();
    await b.setMyRoomTag(g, '  새내기 ');
    expect((await b.memberTags(g))['@me:test'], '새내기');
    await b.setMyRoomTag(g, '');
    expect((await b.memberTags(g)).containsKey('@me:test'), isFalse);
  });

  // ---- 384 누가 읽었는지 ------------------------------------------------

  test('group reads: first receipt that covers the message, newest first, 7 days', () {
    final t0 = DateTime(2026, 11, 27, 15);
    final r1 = {'@a:test': (t0.add(const Duration(minutes: 1)), t0.add(const Duration(minutes: 2)))};
    var raw = GroupReads.add('', r1, t0)!;
    final r2 = {
      '@a:test': (t0.add(const Duration(hours: 1)), t0.add(const Duration(hours: 1, minutes: 1))),
      '@b:test': (t0.add(const Duration(hours: 1)), t0.add(const Duration(hours: 1, minutes: 5))),
    };
    raw = GroupReads.add(raw, r2, t0)!;
    expect(GroupReads.add(raw, r2, t0), isNull, reason: 'nothing new');
    final who = GroupReads.readers(raw, r2, t0, t0.add(const Duration(hours: 2)));
    expect(who.map((x) => x.$1), ['@b:test', '@a:test']);
    expect(who.last.$2, t0.add(const Duration(minutes: 2)), reason: 'a read it at the first receipt');
    // A later message: only the receipts that cover it.
    final later = GroupReads.readers(raw, r2, t0.add(const Duration(minutes: 30)), t0.add(const Duration(hours: 2)));
    expect(later.firstWhere((x) => x.$1 == '@a:test').$2, t0.add(const Duration(hours: 1, minutes: 1)));
    expect(GroupReads.readers(raw, r2, t0.add(const Duration(hours: 3)), t0), isEmpty);
    expect(GroupReads.readers(raw, r2, t0, t0.add(const Duration(days: 8))), isEmpty);
  });

  testWidgets('who read: hold my group message, tap "N명 읽음", see names and times', (t) async {
    final (b, s) = await app(t);
    final g = await anonGroup(b, myRole: 'owner');
    b.roomConfigs[g] = {};
    await b.sendText(g, '내일 비 오면 취소예요');
    final sent = b.now;
    b.groupReads[g] = {
      '@mina:test': (sent.add(const Duration(minutes: 1)), sent.add(const Duration(minutes: 3))),
      '@sujin:test': (sent.add(const Duration(minutes: 1)), sent.add(const Duration(minutes: 9))),
    };
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 러닝 크루').first);
    await t.pumpAndSettle();
    await t.longPress(find.text('내일 비 오면 취소예요').last);
    await t.pumpAndSettle();
    expect(find.text('2명 읽음'), findsOneWidget);
    expect(find.byKey(const Key('reader-faces')), findsOneWidget);
    await t.tap(find.byKey(const Key('menu-header')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('readers-sheet')), findsOneWidget);
    expect(find.byKey(const Key('reader-@sujin:test')), findsOneWidget);
    expect(find.byKey(const Key('reader-@mina:test')), findsOneWidget);
    // Newest first: 수진 (9 min) above 민아 (3 min).
    expect(t.getTopLeft(find.byKey(const Key('reader-@sujin:test'))).dy, lessThan(t.getTopLeft(find.byKey(const Key('reader-@mina:test'))).dy));
    s.stopLive();
  });

  testWidgets('who read: nothing when I hide my read ticks', (t) async {
    final (b, s) = await app(t);
    final g = await anonGroup(b, myRole: 'owner');
    b.roomConfigs[g] = {};
    await b.sendText(g, '확인했어요');
    b.groupReads[g] = {'@mina:test': (b.now.add(const Duration(minutes: 1)), b.now.add(const Duration(minutes: 2)))};
    await s.setPref('send_read', '0');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 러닝 크루').first);
    await t.pumpAndSettle();
    await t.longPress(find.text('확인했어요').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-header')), findsNothing);
    s.stopLive();
  });

  // ---- 365 강력 스팸 차단 -----------------------------------------------

  test('anti-spam: catches gambling ads and repeats, leaves normal talk alone', () {
    final now = DateTime(2026, 11, 27, 12);
    final old = now.subtract(const Duration(days: 30));
    final msgs = [
      msg('1', '@mina:test', '오늘 7시 한강 러닝 갈 사람?', now),
      msg('2', '@spam:test', '🎰 카지노 첫충 100% 지급!! 문의 텔레 @casino_vip 바로가기 http://bit.ly/x', now),
      msg('3', '@mina:test', '링크 공유해요 https://running.example.com/map', now),
      for (var i = 0; i < 4; i++) msg('r$i', '@bot:test', '무료 코인 받으세요 지금 바로 신청', now),
      msg('4', '@sujin:test', '카지노 광고 조심하세요', now),
    ];
    final found = AntiSpam.find(msgs, admins: {'@sujin:test'}, trusted: const {}, joined: {'@mina:test': old, '@spam:test': now, '@bot:test': now}, now: now);
    final ids = found.map((x) => x.$1.id).toSet();
    expect(ids, containsAll(['2', 'r0', 'r1', 'r2', 'r3']));
    expect(ids, isNot(contains('1')));
    expect(ids, isNot(contains('3')), reason: 'a known member sharing a link is fine');
    expect(ids, isNot(contains('4')), reason: 'admins are never checked');
    final trusted = AntiSpam.find(msgs, admins: const {}, trusted: {'@spam:test', '@bot:test', '@sujin:test'}, joined: const {}, now: now);
    expect(trusted, isEmpty);
    final d = AntiSpam.detail(msgs[1]);
    expect(AntiSpam.splitDetail(d).$1, '@spam:test');
  });

  test('anti-spam on an admin phone: removes, logs, mutes after 3 strikes', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final g = await b.createGroup('큰 동호회', ['@spam:test']);
    b.roomMembers[g] = [
      const Member(userId: '@me:test', name: 'me', role: 'owner'),
      Member(userId: '@spam:test', name: '광고봇', role: 'member', since: b.now),
      Member(userId: '@mina:test', name: '민아', role: 'member', since: b.now.subtract(const Duration(days: 90))),
    ];
    b.rooms[g] = [
      msg('ok', '@mina:test', '다들 주말 잘 보내요', b.now),
      for (var i = 0; i < 3; i++) msg('s$i', '@spam:test', '[$i] 토토 먹튀 없는 곳 카톡문의 open.kakao.com/o/abc$i', b.now),
    ];
    expect(await s.antiSpamRoom(g), 0, reason: 'off until switched on');
    b.roomConfigs[g] = {'antispam': true};
    expect(await s.antiSpamRoom(g), 3);
    expect(b.rooms[g]!.map((m) => m.id), ['ok']);
    final log = modLogOf(s.settings, g);
    expect(log.where((e) => e.kind == 'spam'), hasLength(3));
    expect(log.any((e) => e.kind == 'muted' && e.name == '광고봇'), isTrue);
    expect(b.roomConfigs[g]!['mutes'], contains('@spam:test'));
  });

  testWidgets('anti-spam page: switch on, "스팸 아님" trusts the person and lifts the mute', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('큰 동호회', ['@spam:test']);
    b.roomMembers[g] = [const Member(userId: '@me:test', name: 'me', role: 'owner'), Member(userId: '@new:test', name: '새 멤버', role: 'member', since: b.now)];
    b.rooms[g] = [for (var i = 0; i < 3; i++) msg('s$i', '@new:test', '재택부업 고수익 보장 텔레문의 @job_kr_$i', b.now)];
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first));
    unawaited(nav.push(CupertinoPageRoute<void>(builder: (_) => AntiSpamPage(roomId: g))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('antispam-switch')));
    await t.pumpAndSettle();
    expect(b.roomConfigs[g]!['antispam'], isTrue);
    await t.runAsync(() => s.antiSpamRoom(g));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('spam-row-0')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('spam-ok-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('spam-ok-0')));
    await t.pumpAndSettle();
    expect(b.roomConfigs[g]!['spam_ok'], ['@new:test']);
    expect(b.roomConfigs[g]!['mutes'], isNull, reason: 'the spam mute is lifted');
    expect(find.byKey(const Key('spam-ok-0')), findsNothing, reason: 'the row now says it was marked');
    await t.pumpAndSettle(const Duration(seconds: 5));
    s.stopLive();
  });

  testWidgets('dust: a deleted message breaks into dust, then its row closes', (t) async {
    var done = false;
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: DustOut(
            onDone: () => done = true,
            child: Container(width: 200, height: 40, color: const Color(0xFF34C759)),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(done, isFalse);
    await t.pump(DustOut.duration);
    await t.pump();
    expect(done, isTrue);
  });
}
