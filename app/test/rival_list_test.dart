// 4-app board: the "멘션" chat list filter (WhatsApp/Viber style): only the
// groups where someone called me with @ (or answered me) and I haven't
// looked yet.
import 'dart:async';
import 'dart:convert';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/chat_marks.dart';
import 'package:burumy/core/downloads.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart' show onceLeft;
import 'package:burumy/l10n/app_localizations_ko.dart';
import 'package:burumy/ui/storage_page.dart';
import 'package:burumy/ui/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.tipsReply = true);
  tearDown(() => Features.tipsReply = false);

  testWidgets('멘션 tab shows only chats that called me; empty text when none', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final now = DateTime.now();
    final run = await b.createGroup('러닝', ['@jiwoo:test']);
    final book = await b.createGroup('독서', ['@jiwoo:test']);
    b.rooms[run]!.add(Msg(id: 'men', sender: '@jiwoo:test', body: '@me 지도 보내 줘요', time: now.subtract(const Duration(minutes: 5)), mine: false, kind: 'text'));
    b.rooms[book]!.add(Msg(id: 'chat', sender: '@jiwoo:test', body: '다음 책 뭐 읽어요?', time: now.subtract(const Duration(minutes: 4)), mine: false, kind: 'text'));
    b.unreadCounts[run] = 1;
    b.unreadCounts[book] = 1;
    await s.refresh();
    final since = jsonEncode({'since': now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch, 'seen': [], 'rx': {}});
    await s.setPref(ChatMarks.key(run), since);
    await s.setPref(ChatMarks.key(book), since);
    await s.setOn('list_top', true);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await ChatMarks.scan(s);
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('chip-mention')));
    await t.pumpAndSettle();
    expect(find.text('러닝'), findsOneWidget);
    expect(find.text('독서'), findsNothing);

    // Once it has been seen it leaves the tab right away.
    ChatMarks.counts.value = const {};
    await t.pumpAndSettle();
    expect(find.text('러닝'), findsNothing);
    expect(find.text('나를 부른 대화가 없어요'), findsOneWidget);

    // Off switch: no 멘션 tab at all.
    Features.tipsReply = false;
    await t.tap(find.byKey(const Key('chip-all')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chip-mention')), findsNothing);
    ChatMarks.stop();
    s.stopLive();
  });

  newGroupFromMembers();
  reportFromProfile();
  storagePerChat();
  viewOnceExpiry();
}

/// 4-app board: "이 멤버로 새 그룹 만들기" from a group's ⋯ menu.
class _Made extends FakeBackend {
  final made = <String, List<String>>{};
  @override
  Future<String> createGroup(String name, List<String> members, {bool channel = false}) {
    made[name] = members;
    return super.createGroup(name, members, channel: channel);
  }
}

void newGroupFromMembers() {
  testWidgets('new group starts with everyone here ticked; untick one, name it, made', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = _Made();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final g = await b.createGroup('동창', ['@mina:test', '@jun:test', '@jisoo:test']);
    b.roomMembers[g] = [
      const Member(userId: '@me:test', name: 'me', role: 'owner'),
      for (final n in ['mina', 'jun', 'jisoo']) Member(userId: '@$n:test', name: n, role: 'member'),
    ];
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => ChatInfoPage(roomId: g, title: '동창', isGroup: true, isChannel: false),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('more-new-group')));
    await t.pumpAndSettle();
    for (final id in ['@mina:test', '@jun:test', '@jisoo:test']) {
      expect(find.descendant(of: find.byKey(Key('pick-$id')), matching: find.byIcon(CupertinoIcons.checkmark_circle_fill)), findsOneWidget);
    }
    expect(find.byKey(const Key('pick-@me:test')), findsNothing, reason: 'not me');
    await t.tap(find.byKey(const Key('pick-@jun:test')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('members-next')));
    await t.pumpAndSettle();
    await t.enterText(find.byType(CupertinoTextField).first, '여행 모임');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(b.made['여행 모임']?.toSet(), {'@mina:test', '@jisoo:test'});
    expect(find.text('여행 모임'), findsWidgets, reason: 'the new chat opened');
    ChatMarks.stop();
    s.stopLive();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}

/// 4-app board: "신고하기" right on a person's info page, with their last
/// 5 messages (and only theirs).
void reportFromProfile() {
  setUp(() => Features.chatSafety = true);
  tearDown(() => Features.chatSafety = false);
  testWidgets('report from a profile carries their last 5 messages, not mine', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@scam:test');
    final now = DateTime.now();
    b.rooms[room]!.addAll([
      for (var i = 0; i < 7; i++)
        Msg(
          id: 's$i',
          sender: '@scam:test',
          body: '투자 $i',
          time: now.subtract(Duration(minutes: 20 - i)),
          mine: false,
          kind: 'text',
        ),
      Msg(id: 'me1', sender: '@me:test', body: '관심 없어요', time: now, mine: true, kind: 'text'),
    ]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => ChatInfoPage(roomId: room, title: 'scam', isGroup: false, isChannel: false),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('이 사람이 보낸 최근 메시지 5개까지 운영팀에 함께 보내요'), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('info-report')));
    await t.tap(find.byKey(const Key('info-report')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('report-scam')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('report-scam.money')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('report-send')));
    await t.pumpAndSettle();
    final (id, reason, shown) = b.reports.single;
    expect(id, 's6', reason: 'pinned to their newest message');
    expect(reason, contains('scam.money'));
    for (var i = 2; i < 7; i++) {
      expect(shown, contains('투자 $i'));
    }
    expect(shown, isNot(contains('투자 1')));
    expect(shown, isNot(contains('관심 없어요')), reason: 'never my own words');
    s.stopLive();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}

/// 4-app board: 대화별 저장 공간 on 데이터 및 저장 공간.
void storagePerChat() {
  testWidgets("chats by size; one chat's files biggest first; clear picked, 5s to take back", (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    Downloads.instance.reset();
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final trip = await b.createGroup('여행', ['@mina:test']);
    final work = await b.createGroup('회사', ['@jun:test']);
    final now = DateTime.now();
    Msg f(String id, String kind, int size, String name) => Msg(id: id, sender: '@mina:test', body: name, time: now, mine: false, kind: kind, size: size);
    final big = f('v1', 'video', 80 << 20, '바다.mp4'), small = f('p1', 'image', 2 << 20, '노을.jpg'), doc = f('d1', 'file', 1 << 20, '보고서.pdf');
    b.rooms[trip]!.addAll([big, small]);
    b.rooms[work]!.add(doc);
    await s.refresh();
    for (final (r, m) in [(trip, big), (trip, small), (work, doc)]) {
      await Downloads.instance.get(s, r, m);
    }
    expect(Downloads.instance.keptByChat(s).map((x) => x.$1), [trip, work], reason: 'biggest chat first');

    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(nav.push(CupertinoPageRoute<void>(builder: (_) => const StorageUsagePage())));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('storage-by-chat')), 200, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('storage-by-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('storage-chat-$work')), findsOneWidget);
    expect(find.text('82.0 MB'), findsOneWidget);
    await t.tap(find.byKey(Key('storage-chat-$trip')));
    await t.pumpAndSettle();
    final names = find.textContaining(RegExp(r'바다|노을'));
    expect(t.widget<Text>(names.first).data, '바다.mp4', reason: 'biggest first');
    await t.tap(find.byKey(const Key('kept-v1')));
    await t.pumpAndSettle();
    expect(find.text('고른 파일 1개 지우기'), findsOneWidget);
    await t.tap(find.byKey(const Key('storage-chat-clear')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('kept-v1')), findsNothing, reason: 'hidden while the 5 seconds run');
    expect(b.kept, contains('v1'), reason: 'not gone yet');
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(b.kept.contains('v1'), isFalse);
    expect(b.kept, containsAll(['p1', 'd1']));
    expect(Downloads.instance.keptFiles(s, roomId: trip).single.eventId, 'p1');
    s.stopLive();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}

/// 4-app board: a view-once photo nobody opens is gone after a day.
void viewOnceExpiry() {
  test('view-once line: time left to open, or until it goes', () {
    final l = LKo();
    final now = DateTime(2026, 11, 27, 9);
    Msg m({bool opened = false, Duration? left}) =>
        Msg(id: 'x', sender: '@a:t', body: 'p.png', time: now, mine: false, kind: 'image', viewOnce: true, opened: opened, expiresAt: left == null ? null : now.add(left));
    expect(onceLeft(l, m(left: const Duration(hours: 23, minutes: 40)), false, now: now), '눌러서 열기 · 23시간 남음');
    expect(onceLeft(l, m(left: const Duration(minutes: 12)), false, now: now), '눌러서 열기 · 12분 남음');
    expect(onceLeft(l, m(left: const Duration(hours: 5)), true, now: now), '안 열면 5시간 뒤 사라져요');
    expect(onceLeft(l, m(left: const Duration(hours: 5), opened: true), false, now: now), isNull);
    expect(onceLeft(l, m(), false, now: now), isNull, reason: 'no end time: old message');
  });

  test('sent view-once carries the 1-day life', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final r = await b.createDirectChat('@mina:test');
    await b.sendViewOnce(r, name: 'p.png', mime: 'image/png', bytes: const [1, 2, 3]);
    final m = b.rooms[r]!.last;
    expect(m.viewOnce, isTrue);
    expect(m.expiresAt!.difference(m.time), viewOnceLife);
  });
}
