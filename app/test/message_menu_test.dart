// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Message long-press menu in v1 order, "알림 받기", "비상 시 삭제",
// "이 대화방 비상 시 숨김" and select mode.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/reminders.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:burumy/core/saved_tags.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend, String)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  final room = await b.createDirectChat('@mina:test');
  await b.sendText(room, '첫 글');
  await b.sendText(room, '둘째 글');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('둘째 글').first);
  await t.pumpAndSettle();
  return (s, b, room);
}

Future<void> hold(WidgetTester t, String text) async {
  await t.longPress(find.text(text).last);
  await t.pumpAndSettle();
}

Future<void> tap(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)).last);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('menu rows follow the v1 order, select comes last after a gap', (t) async {
    final (_, b, room) = await start(t);
    await hold(t, '첫 글');
    const order = ['reply', 'copy', 'edit', 'pin', 'forward', 'save', 'remind', 'emergency', 'hide-room', 'delete', 'select'];
    final ys = [for (final id in order) t.getTopLeft(find.byKey(Key('menu-$id'))).dy];
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], greaterThan(ys[i - 1]), reason: order[i]);
    }
    // Rows 44 tall; the block gap (8) before "선택".
    expect(ys[1] - ys[0], 44);
    expect(ys.last - ys[ys.length - 2], 52);
    expect(t.getSize(find.byKey(const Key('menu-reply'))).width, 250);
    // ⌄ opens more emoji.
    await tap(t, 'react-more');
    expect(find.byKey(const Key('react-panel')), findsOneWidget);
    expect(find.byKey(const Key('menu-reply')), findsNothing);
    await tap(t, 'react-🔥');
    final first = (await b.timeline(room)).firstWhere((m) => m.body == '첫 글');
    expect(first.reactions.map((r) => r.key), contains('🔥'));
  });

  testWidgets('remind me: four quick times + own time, kept on the phone only', (t) async {
    final (s, _, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-remind');
    expect(find.byKey(const Key('remind-sheet')), findsOneWidget);
    expect(find.text('이 휴대폰에 알림이 와요. 서버로는 아무것도 보내지 않아요.'), findsOneWidget);
    for (final x in ['20분 뒤', '1시간 뒤', '3시간 뒤', '내일 오전 9시', '날짜와 시간 고르기']) {
      expect(find.text(x), findsOneWidget);
    }
    final before = DateTime.now();
    await tap(t, 'remind-1');
    final list = reminders(s);
    expect(list, hasLength(1));
    expect(list.single.roomId, room);
    expect(list.single.at.difference(before).inMinutes, inInclusiveRange(59, 60));
    expect(find.textContaining('알림 시간:'), findsOneWidget);
    // Same message again replaces the old reminder.
    await t.pump(const Duration(seconds: 3));
    await hold(t, '첫 글');
    await tap(t, 'menu-remind');
    await tap(t, 'remind-0');
    expect(reminders(s), hasLength(1));
    // Due: taken off the list and shown as a banner.
    final due = await takeDueReminders(s, DateTime.now().add(const Duration(hours: 2)));
    expect(due, hasLength(1));
    expect(reminders(s), isEmpty);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('choices: tomorrow 9 AM is tomorrow, even late at night', (t) async {
    final c = reminderChoices(DateTime(2026, 12, 31, 23, 50));
    expect(c[0], DateTime(2027, 1, 1, 0, 10));
    expect(c[3], DateTime(2027, 1, 1, 9));
  });

  testWidgets('emergency delete: the delete password erases marked messages', (t) async {
    final (_, b, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-emergency');
    expect(await b.markedMessages(room), hasLength(1));
    expect(find.text('삭제 비밀번호로 열면 이 메시지가 지워져요'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    // The row now offers to take the mark off.
    await hold(t, '첫 글');
    expect(find.text('비상 시 삭제 취소'), findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    await b.startSession('delete');
    final left = await b.timeline(room);
    expect(left.map((m) => m.body), ['둘째 글']);
  });

  testWidgets('hide this chat in emergency: on the hide list, then off again', (t) async {
    final (_, b, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-hide-room');
    expect((await b.quietLists()).first, [room]);
    await t.pump(const Duration(seconds: 3));
    await hold(t, '첫 글');
    await tap(t, 'menu-hide-room');
    expect((await b.quietLists()).first, isEmpty);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('select mode: count, copy, forward-ready, delete with undo', (t) async {
    final (_, b, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    expect(find.text('1개 선택됨'), findsOneWidget);
    expect(find.byKey(const Key('select-tools')), findsOneWidget);
    expect(find.byKey(const Key('send')), findsNothing, reason: 'composer is replaced');
    await t.tap(find.text('둘째 글'), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(find.text('2개 선택됨'), findsOneWidget);
    // v1 bottom row: delete, tag, share, forward, more.
    final xs = [
      for (final k in ['delete', 'tag', 'share', 'forward', 'more']) t.getCenter(find.byKey(Key('select-$k'))).dx,
    ];
    for (var i = 1; i < xs.length; i++) {
      expect(xs[i], greaterThan(xs[i - 1]));
    }
    // "공유" sends to my chats here (v1), not to other apps.
    await tap(t, 'select-share');
    expect(find.text('전달할 대화'), findsOneWidget);
    await t.tap(find.text('취소').last);
    await t.pumpAndSettle();
    // Delete two of mine: 5 s undo bar, then gone.
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await t.tap(find.text('둘째 글'), warnIfMissed: false);
    await t.pumpAndSettle();
    await tap(t, 'select-delete');
    expect(find.byKey(const Key('undo-bar')), findsOneWidget);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect((await b.timeline(room)).where((m) => m.kind == 'text'), isEmpty);
  });

  testWidgets('select mode: cancel and clear messages', (t) async {
    final (s, _, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await tap(t, 'select-cancel');
    expect(find.byKey(const Key('select-tools')), findsNothing);
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await tap(t, 'select-clear');
    await tap(t, 'clear-ok');
    expect(s.pref('cleared:$room', ''), isNotEmpty);
    expect(find.text('첫 글'), findsNothing);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('search: glass field + X, date capsule, list of results', (t) async {
    final (_, b, room) = await start(t);
    await b.sendText(room, '셋째 글');
    final state = (await b.timeline(room)).length;
    expect(state, 3);
    // Open search from the 1:1 info page.
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-search')).last);
    await t.pumpAndSettle();
    expect(find.text('이 대화방에서 검색'), findsOneWidget);
    expect(find.text('날짜로 이동'), findsOneWidget);
    expect(t.getSize(find.byKey(const Key('search-cancel'))).height, 44);
    await t.enterText(find.byKey(const Key('msg-search')), '글');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    await tap(t, 'search-list');
    expect(find.byKey(const Key('hit-2')), findsOneWidget);
    await tap(t, 'hit-2');
    expect(find.text('3/3'), findsOneWidget);
    // Date jump: the sample messages are from yesterday, so today has none.
    await tap(t, 'search-date');
    await tap(t, 'date-done');
    expect(find.text('그날 이후 메시지가 없어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await tap(t, 'search-cancel');
    expect(find.byKey(const Key('search-bar')), findsNothing);
  });

  testWidgets('tag: save two messages, tag them, filter the saved chat', (t) async {
    final (s, b, _) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await t.tap(find.text('둘째 글'), warnIfMissed: false);
    await t.pumpAndSettle();
    await tap(t, 'select-tag');
    expect(find.text('저장한 메시지에 저장했어요'), findsOneWidget);
    expect(find.byKey(const Key('tag-💡')), findsOneWidget);
    await tap(t, 'tag-💡');
    final saved = (await b.savedRoom())!;
    final copies = (await b.timeline(saved)).where((m) => m.kind == 'text').toList();
    expect(copies.map((m) => m.body), ['첫 글', '둘째 글']);
    expect(savedTags(s), {for (final m in copies) m.id: '💡'});
    // Untagged third copy through the menu (sheet closed without a tag).
    await hold(t, '첫 글');
    await tap(t, 'menu-save');
    await t.tapAt(const Offset(200, 100));
    await t.pumpAndSettle();
    expect(savedTags(s), hasLength(2));
  });

  testWidgets('channel composer: my picture, bell switches silent posts (v1)', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await b.createGroup('소식', [], channel: true);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('소식').first);
    await t.pumpAndSettle();
    expect(find.text('알리기'), findsOneWidget);
    await tap(t, 'channel-bell');
    expect(find.text('구독자가 소리 없이 알림을 받아요'), findsOneWidget);
    expect(find.text('조용히 알리기'), findsOneWidget);
    await t.enterText(find.byKey(const Key('composer')), '조용한 글');
    await t.pump();
    await tap(t, 'send');
    expect(b.quietSent, ['조용한 글']);
    await tap(t, 'channel-bell');
    await t.enterText(find.byKey(const Key('composer')), '알리는 글');
    await t.pump();
    await tap(t, 'send');
    expect(b.quietSent, ['조용한 글']);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('select more (v1): message info and report', (t) async {
    final (s, b, room) = await start(t);
    b.rooms[room]!.add(Msg(id: r'$bad', sender: '@mina:test', body: '나쁜 글', time: DateTime.now(), mine: false, kind: 'text'));
    await s.refresh();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('나쁜 글').first);
    await t.pumpAndSettle();
    // Info for my own message: sent time and status.
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await tap(t, 'select-more');
    expect(find.byKey(const Key('more-report')), findsNothing, reason: 'my own message');
    await tap(t, 'more-info');
    expect(find.byKey(const Key('info-sheet')), findsOneWidget);
    expect(find.text('보낸 시간'), findsOneWidget);
    expect(find.byKey(const Key('info-status')), findsOneWidget);
    await tap(t, 'sheet-close');
    // Report mina's message: the sheet says the operator reads it.
    await hold(t, '나쁜 글');
    await tap(t, 'menu-select');
    await tap(t, 'select-more');
    await tap(t, 'more-report');
    expect(find.textContaining('운영자가 이 글을 봐요'), findsOneWidget);
    await tap(t, 'report-0');
    expect(b.reports, [(r'$bad', '스팸', '나쁜 글')]);
    expect(find.text('신고했어요. 운영자가 확인할게요.'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('reply in thread: own page, pill under the first message', (t) async {
    final (_, b, room) = await start(t);
    await hold(t, '첫 글');
    await tap(t, 'menu-select');
    await tap(t, 'select-more');
    await tap(t, 'more-thread');
    expect(find.text('아직 답글이 없어요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('thread-input')), '스레드 답');
    await tap(t, 'thread-send');
    expect(find.text('스레드 답'), findsOneWidget);
    expect(find.text('답글 1개'), findsOneWidget);
    final first = (await b.timeline(room)).firstWhere((m) => m.body == '첫 글');
    expect((await b.timeline(room)).last.threadRoot, first.id);
    await tap(t, 'back');
    // The reply stays out of the chat; the first message shows "답글 1개".
    expect(find.text('스레드 답'), findsNothing);
    expect(find.byKey(Key('thread-${first.id}')), findsOneWidget);
    await tap(t, 'thread-${first.id}');
    expect(find.text('스레드 답'), findsOneWidget);
    await tap(t, 'back');
  });
}
