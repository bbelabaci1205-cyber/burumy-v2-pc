// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 답장·멘션 묶음 (Telegram tips 455 · 399 · 249/320 · 276, 2026-11-27).
import 'dart:convert';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/chat_marks.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/my_pins.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/formatting.dart';
import 'package:burumy/ui/quote_block.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.tipsReply = true);
  tearDown(() => Features.tipsReply = false);

  final t0 = DateTime(2026, 11, 27, 9);
  Msg m(String id, {bool mine = false, String body = 'x', String? replyTo, int min = 0, List<Reaction> rx = const []}) =>
      Msg(id: id, sender: mine ? '@me:t' : '@a:t', body: body, time: t0.add(Duration(minutes: min)), mine: mine, kind: 'text', replyTo: replyTo, reactions: rx);

  group('455 quotes', () {
    test('splits plain words, quotes and folded quotes', () {
      final parts = splitQuotes('hi\n> a\n> b\n>> c\n>>\n>> d\nbye');
      expect(parts.map((p) => p.kind), ['text', 'quote', 'fold', 'text']);
      expect(parts[1].lines, ['a', 'b']);
      expect(parts[2].lines, ['c', '', 'd']);
      expect(splitQuotes('no quote').single.kind, 'text');
    });

    test('toggle puts whole lines in a quote and takes them out again', () {
      final (a, _) = toggleQuote('one\ntwo\nthree', 5, 6, fold: false);
      expect(a, 'one\n> two\nthree');
      final (b, end) = toggleQuote('one\ntwo\nthree', 0, 7, fold: true);
      expect(b, '>> one\n>> two\nthree');
      expect(end, '>> one\n>> two'.length);
      expect(toggleQuote(b, 0, 13, fold: true).$1, 'one\ntwo\nthree');
      // A folded quote picked for a plain one turns plain (not doubled).
      expect(toggleQuote('>> x', 0, 4, fold: false).$1, '> x');
    });

    test('copies and previews lose the marks', () {
      expect(plainText('>> folded\n> plain\nwords'), 'folded\nplain\nwords');
    });

    Widget host(Widget child) => CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [L.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: L.supportedLocales,
      home: Center(child: SizedBox(width: 280, child: child)),
    );

    testWidgets('a long folded quote shows 3 lines, a tap opens it', (t) async {
      final long = List.generate(8, (i) => '>> 줄 $i 아주 긴 문장이 이어져서 줄이 바뀌어요').join('\n');
      await t.pumpWidget(host(FormattedText('$long\n끝', style: const TextStyle(fontSize: 17, height: 22 / 17), linkColor: const Color(0xFF0000FF), quoteColor: const Color(0xFF00AA00))));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('quote-box')), findsOneWidget);
      expect(find.byKey(const Key('quote-chevron')), findsOneWidget);
      final shut = t.getSize(find.byKey(const Key('quote-box'))).height;
      await t.tap(find.byKey(const Key('quote-open')));
      await t.pumpAndSettle();
      expect(t.getSize(find.byKey(const Key('quote-box'))).height, greaterThan(shut * 2));
      await t.tap(find.byKey(const Key('quote-close')));
      await t.pumpAndSettle();
      expect(t.getSize(find.byKey(const Key('quote-box'))).height, shut);
    });

    testWidgets('a short folded quote has nothing to open; plain quotes never fold', (t) async {
      await t.pumpWidget(host(FormattedText('>> 짧아요\n> 보통 인용\n> 두 줄', style: const TextStyle(fontSize: 17), linkColor: const Color(0xFF0000FF), quoteColor: const Color(0xFF00AA00))));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('quote-box')), findsNWidgets(2));
      expect(find.byKey(const Key('quote-chevron')), findsNothing);
      expect(find.byKey(const Key('quote-sign')), findsNWidgets(2));
    });

    testWidgets('switch off: quotes stay the old ▎ lines', (t) async {
      Features.tipsReply = false;
      await t.pumpWidget(host(FormattedText('> 인용', style: const TextStyle(fontSize: 17), linkColor: const Color(0xFF0000FF), quoteColor: const Color(0xFF00AA00))));
      expect(find.byKey(const Key('quote-box')), findsNothing);
    });
  });

  group('249/320 marks', () {
    test('first look: unread mentions count, old reactions do not', () {
      final msgs = [
        m('mine', mine: true, rx: const [Reaction('❤️', 2, null)]),
        m('old', body: '@me 예전', min: 1),
        m('u1', body: '안녕', min: 2),
        m('u2', body: '@me 이거 봐요', min: 3),
        m('u3', replyTo: 'mine', min: 4),
        m('u4', body: '@모두 공지', min: 5),
      ];
      final st = ChatMarks.start(msgs, 4, t0.add(const Duration(hours: 1)));
      expect(ChatMarks.mentions(msgs, st, '@me:t', '').map((x) => x.id), ['u2', 'u3', 'u4']);
      expect(ChatMarks.reactions(msgs, st), isEmpty);
      // A new reaction from someone else counts; my own never does.
      final more = [
        msgs.first.copyWith(reactions: const [Reaction('❤️', 3, 'r-mine')]),
        ...msgs.skip(1),
      ];
      expect(ChatMarks.others(more.first), 2);
      expect(ChatMarks.reactions(more, st), isEmpty, reason: 'only my own reaction was added');
      final more2 = [more.first.copyWith(reactions: const [Reaction('❤️', 3, 'r-mine'), Reaction('👍', 1, null)]), ...msgs.skip(1)];
      expect(ChatMarks.reactions(more2, st).single.id, 'mine');
    });

    test('state survives encoding and stays small', () {
      final st = MarkState(since: t0, seen: {for (var i = 0; i < 260; i++) 's$i'}, rx: {'a': 2, 'b': 0});
      final back = MarkState.decode(st.encode())!;
      expect(back.since, t0);
      expect(back.seen, hasLength(MarkState.keepSeen));
      expect(back.seen, contains('s259'));
      expect(back.rx, {'a': 2});
      expect(MarkState.decode('nonsense'), isNull);
      expect(MarkState.decode(''), isNull);
    });

    test('1:1 chats: reactions yes, mentions no; channels neither', () {
      const dm = ChatPreview(roomId: 'd', name: 'd', isDirect: true, encrypted: true, unread: 0);
      const ch = ChatPreview(roomId: 'c', name: 'c', isDirect: false, encrypted: true, unread: 0, isChannel: true);
      expect(ChatMarks.mentionsCount(dm), isFalse);
      expect(ChatMarks.reactionsCount(dm), isTrue);
      expect(ChatMarks.reactionsCount(ch), isFalse);
    });
  });

  group('276 pin for me only', () {
    test('merge keeps message order; run-out pins drop', () {
      final msgs = [m('a'), m('b', min: 1), m('c', min: 2)];
      expect(MyPins.merge(['c'], ['a'], msgs), ['a', 'c']);
      expect(MyPins.merge(['c'], const [], msgs), ['c']);
      expect(MyPins.merge(['zz', 'c'], ['a'], msgs), ['zz', 'a', 'c'], reason: 'unknown keeps its place');
      expect(MyPins.live({'a': 0, 'b': t0.millisecondsSinceEpoch - 1, 'c': t0.millisecondsSinceEpoch + 1}, t0), ['a', 'c']);
    });
  });

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  testWidgets('399: pick words, reply with only them; the bubble shows the quote', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    b.rooms[room]!.add(Msg(id: 'q1', sender: '@bob:test', body: '토요일 아침 7시에 한강에서 만나요', time: DateTime.now(), mine: false, kind: 'text'));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    // Reply, then tap the reply line: 특정 부분 인용.
    await t.longPress(find.textContaining('한강에서').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-reply')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('mode-options')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('reply-other-chat')), findsOneWidget);
    await t.tap(find.byKey(const Key('reply-pick-part')));
    await t.pumpAndSettle();
    // Everything is picked at first; narrow it to "토요일 아침 7시".
    final field = t.widget<CupertinoTextField>(find.byKey(const Key('quote-pick-text')));
    field.controller!.selection = const TextSelection(baseOffset: 0, extentOffset: 9);
    await t.pumpAndSettle();
    expect(find.text('고른 글자 9자'), findsOneWidget);
    await t.tap(find.byKey(const Key('quote-pick-done')));
    await t.pumpAndSettle();
    expect(t.widget<Text>(find.byKey(const Key('mode-text'))).data, '토요일 아침 7시');
    await t.enterText(find.byType(CupertinoTextField).last, '좋아요!');
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pumpAndSettle();
    var sent = b.rooms[room]!.last;
    if (sent.body != '좋아요!') {
      await t.tap(find.byKey(const Key('send')));
      await t.pumpAndSettle();
      sent = b.rooms[room]!.last;
    }
    expect(sent.body, '좋아요!');
    expect(sent.replyTo, 'q1');
    expect(sent.quote, '토요일 아침 7시');
    expect(sent.quoteName, isNull);
    expect(find.byKey(const Key('quote-part')), findsOneWidget);
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('399: reply in another chat carries the words and the name, not a link', (t) async {
    final (b, s) = await app(t);
    final from = await b.createDirectChat('bob');
    final to = await b.createDirectChat('amy');
    b.rooms[from]!.add(Msg(id: 'q1', sender: '@bob:test', body: '다음 주 비 온대요', time: DateTime.now(), mine: false, kind: 'text'));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('다음 주 비 온대요').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-reply')));
    await t.pumpAndSettle();
    await t.enterText(find.byType(CupertinoTextField).last, '우산 챙겨요');
    await t.tap(find.byKey(const Key('mode-options')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('reply-other-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('forward-to-$from')), findsNothing, reason: 'the chat I am in is left out');
    await t.tap(find.byKey(Key('forward-to-$to')));
    await t.pumpAndSettle();
    // Now in amy's chat with the quote and my words.
    expect(find.text('bob · 다른 대화'), findsOneWidget);
    expect(find.text('우산 챙겨요'), findsOneWidget);
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    final sent = b.rooms[to]!.last;
    expect(sent.replyTo, isNull);
    expect(sent.quote, '다음 주 비 온대요');
    expect(sent.quoteName, 'bob');
    expect(find.byKey(const Key('quote-other-chat')), findsOneWidget);
    expect(b.rooms[from]!.last.id, 'q1', reason: 'nothing sent where it came from');
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('399: 공유 비활성화 chats keep words inside (no other-chat reply)', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    b.roomConfigs[room] = {'protect': true};
    b.rooms[room]!.add(Msg(id: 'q1', sender: '@bob:test', body: '비밀 이야기', time: DateTime.now(), mine: false, kind: 'text'));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('비밀 이야기').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-reply')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('mode-options')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('reply-other-chat')), findsNothing);
    expect(find.byKey(const Key('reply-cancel')), findsOneWidget);
    await t.tap(find.byKey(const Key('reply-cancel')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mode-bar')), findsNothing);
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('249/320: list marks, jump buttons, seen on screen', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('러닝', ['@jiwoo:test']);
    final now = DateTime.now();
    b.rooms[g]!.addAll([
      Msg(id: 'mine', sender: '@me:test', body: '토요일 7시 어때요?', time: now.subtract(const Duration(minutes: 50)), mine: true, kind: 'text', reactions: const [Reaction('❤️', 2, null)]),
      Msg(id: 'men', sender: '@jiwoo:test', body: '@me 지도 보내 줘요', time: now.subtract(const Duration(minutes: 40)), mine: false, kind: 'text'),
      for (var i = 0; i < 30; i++) Msg(id: 'f$i', sender: '@jiwoo:test', body: '잡담 $i', time: now.subtract(Duration(minutes: 30 - i)), mine: false, kind: 'text'),
    ]);
    b.unreadCounts[g] = 31;
    await s.refresh();
    await s.setPref(ChatMarks.key(g), jsonEncode({'since': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch, 'seen': [], 'rx': {}}));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await ChatMarks.scan(s);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('row-mark-mention')), findsOneWidget);
    expect(find.byKey(const Key('row-mark-reaction')), findsOneWidget);
    await t.tap(find.text('러닝'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('jump-mention')), findsOneWidget);
    expect(find.byKey(const Key('jump-reaction')), findsOneWidget);
    await t.tap(find.byKey(const Key('jump-mention')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('jump-mention')), findsNothing);
    expect(find.byKey(const Key('jump-down')), findsOneWidget, reason: 'scrolled up from the newest');
    // My invite is right above the mention: already on screen, so seen too.
    expect(find.byKey(const Key('jump-reaction')), findsNothing);
    await t.tap(find.byKey(const Key('jump-down')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('jump-down')), findsNothing);
    final st = MarkState.decode(s.pref(ChatMarks.key(g), ''))!;
    expect(st.seen, contains('men'));
    expect(st.rx['mine'], 2);
    expect(ChatMarks.counts.value[g], isNull, reason: 'list marks gone');
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('249/320: a bubble built just past the screen edge is not "seen"', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('러닝', ['@jiwoo:test']);
    final now = DateTime.now();
    b.rooms[g]!.addAll([
      Msg(id: 'mine', sender: '@me:test', body: '토요일 7시 어때요?', time: now.subtract(const Duration(minutes: 50)), mine: true, kind: 'text', reactions: const [Reaction('❤️', 2, null)]),
      for (var i = 0; i < 14; i++) Msg(id: 'f$i', sender: '@jiwoo:test', body: '잡담 $i', time: now.subtract(Duration(minutes: 30 - i)), mine: false, kind: 'text'),
    ]);
    await s.refresh();
    await s.setPref(ChatMarks.key(g), jsonEncode({'since': now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch, 'seen': [], 'rx': {}}));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('러닝'));
    await t.pumpAndSettle();
    final built = find.text('토요일 7시 어때요?', skipOffstage: false).evaluate().isNotEmpty;
    final shown = find.text('토요일 7시 어때요?').hitTestable().evaluate().isNotEmpty;
    expect(built && !shown, isTrue, reason: 'set-up: the bubble is built but off screen');
    expect(find.byKey(const Key('jump-reaction')), findsOneWidget, reason: 'still unseen');
    await t.tap(find.byKey(const Key('jump-reaction')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('jump-reaction')), findsNothing);
    expect(MarkState.decode(s.pref(ChatMarks.key(g), ''))!.rx['mine'], 2);
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('276: pin for me only stays on this phone', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '여권 번호 메모');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('여권 번호 메모').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    expect(find.text('bob님에게도 고정'), findsOneWidget);
    await t.tap(find.byKey(const Key('pin-both')));
    await t.pumpAndSettle();
    expect(find.text('이 휴대폰에서 나만 봐요. 상대방에게는 아무것도 가지 않아요.'), findsOneWidget);
    await t.tap(find.byKey(const Key('pin-for-0')));
    await t.pumpAndSettle();
    expect(b.pinned(room), isEmpty, reason: 'nothing sent');
    expect(find.text('고정된 메시지 · 나만'), findsOneWidget);
    // Unpin from the menu.
    await t.longPress(find.text('여권 번호 메모').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pinned-bar')), findsNothing);
    expect(MyPins.read(s, room), isEmpty);
    ChatMarks.stop();
    s.stopLive();
  });

  testWidgets('276: pin for both still goes to the chat', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '같이 보는 공지');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('같이 보는 공지').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pin-for-0')));
    await t.pumpAndSettle();
    expect(b.pinned(room), hasLength(1));
    expect(find.text('고정된 메시지'), findsOneWidget);
    ChatMarks.stop();
    s.stopLive();
  });
}
