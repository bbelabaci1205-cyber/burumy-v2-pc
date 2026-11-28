// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 링크·서식·보내기 묶음 #4 (Telegram tips 411, 559, 217, 289, 400+401).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/code_colors.dart';
import 'package:burumy/core/date_mark.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/calendar_event.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/date_pick.dart';
import 'package:burumy/ui/formatting.dart';
import 'package:burumy/ui/schedule_send.dart';
import 'package:burumy/ui/compose_options.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/ui/send_fly.dart';
import 'package:burumy/main.dart' show BurumyApp;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.tipsLink = true);

  group('411 code blocks', () {
    test('splits words and ``` blocks; keeps the code exactly', () {
      final p = splitCode('봐 주세요:\n```python\ndef f(x):\n    return x * 2  # 두 배\n```\n고마워요');
      expect(p.length, 3);
      expect(p[0].code, isFalse);
      expect(p[0].text, '봐 주세요:');
      expect(p[1].code, isTrue);
      expect(p[1].lang, 'python');
      expect(p[1].text, 'def f(x):\n    return x * 2  # 두 배');
      expect(p[2].text, '고마워요');
      // Left open: runs to the end. No language: first line is code.
      final open = splitCode('```\nSELECT 1;\nSELECT 2;');
      expect(open.single.code, isTrue);
      expect(open.single.text, 'SELECT 1;\nSELECT 2;');
      expect(splitCode('```a = 1```').single.text, 'a = 1');
      expect(splitCode('그냥 글이에요').single.code, isFalse);
      expect(splitCode('```js\nlet a\n```').single.lang, 'js');
    });

    test('colours keywords, quotes, notes, numbers; joining gives the code back', () {
      const code = 'def find(items):\n    """첫 줄"""\n    for i in range(10):  # 열 번\n        print("hi", i)\n    return None';
      final spans = colourCode(code, 'py');
      expect(spans.map((s) => s.text).join(), code);
      String partOf(String w) => spans.firstWhere((s) => s.text.contains(w)).part.name;
      expect(partOf('def'), 'keyword');
      expect(partOf('"""첫 줄"""'), 'string');
      expect(partOf('# 열 번'), 'comment');
      expect(partOf('10'), 'number');
      expect(partOf('find'), 'function');
      final js = colourCode('const user = new User("a"); // note', 'javascript');
      expect(js.map((s) => s.text).join(), 'const user = new User("a"); // note');
      expect(js.firstWhere((s) => s.text == 'User').part, CodePart.function);
      expect(js.last.part, CodePart.comment);
      expect(colourCode('SELECT * FROM t WHERE id = 3', 'sql').first.part, CodePart.keyword);
      expect(codeLangLabel(' Python '), 'python');
      expect(codeLangLabel(''), '');
    });

    test('menu 코드 on several lines makes a fenced block; previews drop fences', () {
      final c = TextEditingController(text: '보세요 a = 1\nb = 2');
      c.selection = TextSelection(baseOffset: 4, extentOffset: c.text.length);
      wrapSelection(c, '`');
      expect(c.text, '보세요 \n```\na = 1\nb = 2\n```');
      expect(plainText('보기:\n```python\nx = 1\n```'), '보기:\nx = 1\n');
      final one = TextEditingController(text: '값 x 입니다')..selection = const TextSelection(baseOffset: 2, extentOffset: 3);
      wrapSelection(one, '`');
      expect(one.text, '값 `x` 입니다');
    });
  });

  group('559 dates', () {
    test('mark keeps world time; reader sees own zone; plain text = words', () {
      final at = DateTime.utc(2026, 2, 28, 1, 0);
      final m = dateMarkText('내일 10시', at);
      expect(m, '[내일 10시](t:${at.millisecondsSinceEpoch ~/ 1000})');
      final hit = dateMark.firstMatch('스쿼시 $m 어때요')!;
      expect(dateMarkAt(hit).toUtc(), at);
      expect(dateMarkAt(hit).isUtc, isFalse, reason: 'shown in this phone time zone');
      expect(plainText('스쿼시 $m 어때요'), '스쿼시 내일 10시 어때요');
      expect(eventTitle('스쿼시 내일 10시 어때요\n둘째 줄'), '스쿼시 내일 10시 어때요');
    });

    test('the field shows the words only; the mark stays in the text', () {
      final c = ComposeController(text: '안녕 ${dateMarkText('내일', DateTime.utc(2026, 3, 1))} 봐요');
      expect(c.text, contains('](t:'));
    });
  });

  Widget wrap(AppState s, Widget child) => AppScope(
    state: s,
    child: CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );

  Future<AppState> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    return AppState(b, locale: const Locale('ko'));
  }

  testWidgets('411: a code message shows language, colours and copies', (t) async {
    final s = await app(t);
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
      return null;
    });
    await t.pumpWidget(
      wrap(
        s,
        const CupertinoPageScaffold(
          child: Center(
            child: FormattedText(
              '이거요\n```python\nprint("hi")\n```',
              style: TextStyle(color: Color(0xFF000000)),
              linkColor: Color(0xFF0000FF),
              quoteColor: Color(0xFF00AA00),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('code-block')), findsOneWidget);
    expect(find.text('python'), findsOneWidget);
    await t.tap(find.byKey(const Key('code-copy')));
    await t.pump();
    expect(copied, 'print("hi")');
    expect(find.text('코드를 복사했어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await t.pumpAndSettle();
  });

  testWidgets('559: tap a date → my time, copy, calendar, reminder', (t) async {
    final s = await app(t);
    final at = DateTime.now().add(const Duration(days: 3));
    final when = DateTime(at.year, at.month, at.day, 10);
    (String, DateTime)? added;
    CalendarEvent.debugAdd = (e) async {
      added = (e.title, e.start);
      return true;
    };
    addTearDown(() => CalendarEvent.debugAdd = null);
    DateTime? reminded;
    await t.pumpWidget(
      wrap(
        s,
        CupertinoPageScaffold(
          child: Center(
            child: FormattedText(
              '스쿼시 ${dateMarkText('그날 10시', when)} 어때요',
              style: const TextStyle(color: Color(0xFF000000)),
              linkColor: const Color(0xFF0000FF),
              quoteColor: const Color(0xFF00AA00),
              onDateRemind: (d) => reminded = d,
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('t:'), findsNothing);
    await t.tapOnText(find.textRange.ofSubstring('그날 10시'));
    await t.pumpAndSettle();
    expect(find.text(dateMarkLabel(when, 'ko')), findsOneWidget);
    await t.tap(find.byKey(const Key('date-calendar')));
    await t.pumpAndSettle();
    expect(added?.$1, '스쿼시 그날 10시 어때요');
    expect(added?.$2, when);
    await t.tapOnText(find.textRange.ofSubstring('그날 10시'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('date-remind')));
    await t.pumpAndSettle();
    expect(reminded, when);
  });

  testWidgets('559: 날짜 sheet picks a day and time', (t) async {
    final s = await app(t);
    DateTime? got;
    await t.pumpWidget(
      wrap(
        s,
        CupertinoPageScaffold(
          child: Builder(
            builder: (c) => Center(
              child: CupertinoButton(
                key: const Key('open'),
                onPressed: () async => got = await pickDateTime(c, initial: DateTime(2026, 2, 27, 10)),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('open')));
    await t.pumpAndSettle();
    expect(find.text('2026년 2월'), findsOneWidget);
    await t.tap(find.byKey(const Key('date-day-28')));
    await t.pump();
    await t.tap(find.byKey(const Key('date-ok')));
    await t.pumpAndSettle();
    expect(got, DateTime(2026, 2, 28, 10));
  });

  test('217: the button words follow the wheel', () async {
    await initializeDateFormatting('ko');
    final l = lookupL(const Locale('ko'));
    final now = DateTime(2026, 8, 2, 17, 0);
    expect(scheduleButtonText(l, DateTime(2026, 8, 2, 17, 41), now, 'ko'), '오늘 오후 5:41에 보내기');
    expect(scheduleButtonText(l, DateTime(2026, 8, 3, 9, 5), now, 'ko'), '내일 오전 9:05에 보내기');
    expect(scheduleButtonText(l, DateTime(2026, 8, 5, 0, 0), now, 'ko'), '8월 5일 오전 12:00에 보내기');
    expect(scheduleButtonText(l, DateTime(2027, 1, 3, 12, 0), now, 'ko'), startsWith('2027년 1월 3일'));
  });

  testWidgets('217: scheduled screen: now, reschedule, edit, delete with undo', (t) async {
    final s = await app(t);
    final room = await s.backend.createDirectChat('@you:x');
    final at = DateTime.now().add(const Duration(days: 2));
    await s.schedule(room, '생일 축하해 🎂', at);
    await s.schedule(room, '두 번째', at.add(const Duration(days: 1)));
    await t.pumpWidget(wrap(s, ScheduledChatPage(roomId: room)));
    await t.pumpAndSettle();
    expect(find.textContaining('에 보낼 메시지'), findsNWidgets(2));
    final first = s.scheduled.firstWhere((m) => m['text'] == '생일 축하해 🎂')['id'];
    // 수정
    await t.tap(find.byKey(Key('sched-$first')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sched-edit')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('sched-edit-field')), '생일 정말 축하해');
    await t.tap(find.byKey(const Key('sched-edit-done')));
    await t.pumpAndSettle();
    expect(s.scheduled.firstWhere((m) => m['id'] == first)['text'], '생일 정말 축하해');
    // 시간 바꾸기: the sheet opens on the old time and keeps it
    await t.tap(find.byKey(Key('sched-$first')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sched-time')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('schedule-sheet')), findsOneWidget);
    await t.tap(find.byKey(const Key('schedule-repeat')).first);
    await t.tap(find.text('매주'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('schedule-ok')));
    await t.pumpAndSettle();
    expect(s.scheduled.firstWhere((m) => m['id'] == first)['repeat'], 'week');
    // 지금 보내기
    await t.tap(find.byKey(Key('sched-$first')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sched-now')));
    await t.pumpAndSettle();
    final sent = await s.backend.timeline(room);
    expect(sent.any((m) => m.body == '생일 정말 축하해'), isTrue);
    // weekly: it comes back a week later
    expect(s.scheduled.where((m) => m['id'] == first), hasLength(1));
    // 삭제 + 되돌리기
    final second = s.scheduled.firstWhere((m) => m['text'] == '두 번째')['id'];
    await t.tap(find.byKey(Key('sched-$second')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sched-delete')));
    await t.pump();
    expect(find.byKey(Key('sched-$second')), findsNothing);
    await t.tap(find.byKey(const Key('undo-countdown-undo')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('sched-$second')), findsOneWidget);
    await t.tap(find.byKey(Key('sched-$second')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sched-delete')));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(s.scheduled.where((m) => m['id'] == second), isEmpty);
  });

  testWidgets('289 + 217 in the chat: a sent bubble rises from the field; 예약 wheel', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '안녕!');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 30));
    }
    final flying = find.byWidgetPredicate((w) => w is SendFly && w.fly);
    expect(flying, findsOneWidget);
    // Partway: still below its place.
    final moving = t.widgetList<Transform>(find.descendant(of: flying, matching: find.byType(Transform))).first;
    expect(moving.transform.getTranslation().y, greaterThan(0));
    await t.pumpAndSettle();
    expect(find.text('안녕!'), findsOneWidget);
    // 예약: the button says when.
    await t.enterText(find.byKey(const Key('composer')), '내일 봐요');
    await t.pump();
    await t.longPress(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send-later')));
    await t.pumpAndSettle();
    expect(find.textContaining('에 보내기'), findsOneWidget);
    await t.tap(find.byKey(const Key('schedule-ok')));
    await t.pumpAndSettle();
    expect(state.scheduled.single['text'], '내일 봐요');
    await t.tap(find.byKey(const Key('scheduled-chip')));
    await t.pumpAndSettle();
    expect(find.byType(ScheduledChatPage), findsOneWidget);
    expect(fake.rooms[bob], isNotNull);
    state.stopLive();
  });

  test('400: links in the field, in order, once (like the engine)', () {
    expect(linksIn('목록 https://a.com/x 그리고 [커피](https://b.org/c). 또 https://a.com/x'), ['https://a.com/x', 'https://b.org/c']);
    expect(linksIn('https://e'), isEmpty);
    expect(linksIn('날짜 [내일](t:1772272800)'), isEmpty);
  });

  const png = <int>[
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
    16,
    73,
    68,
    65,
    84,
    120,
    156,
    99,
    48,
    57,
    30,
    9,
    68,
    12,
    16,
    10,
    0,
    36,
    170,
    5,
    81,
    31,
    180,
    194,
    127,
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
  ];

  Future<(FakeBackend, AppState, String)> openChat(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    fake.rooms[bob]!.add(Msg(id: 'q1', sender: '@bob:test', body: '어디 갈까?', time: fake.now, mine: false, kind: 'text'));
    fake.storyLinks['https://laura.travel/queens'] = const StoryLinkInfo(title: '퀸즈 맛집 2026', site: 'Laura Travels', description: '아스토리아에서 플러싱까지', image: png);
    fake.storyLinks['https://coffee.example/best'] = const StoryLinkInfo(title: '최고의 커피', site: 'Coffee', image: png);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    return (fake, state, bob);
  }

  testWidgets('400: link line → move up, small photo, pick the 2nd link, send', (t) async {
    final (fake, state, bob) = await openChat(t);
    await t.enterText(find.byKey(const Key('composer')), '목록: https://laura.travel/queens 그리고 커피는 https://coffee.example/best');
    await t.pump(const Duration(milliseconds: 800));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-bar')), findsOneWidget);
    expect(find.text('퀸즈 맛집 2026'), findsOneWidget);
    await t.tap(find.byKey(const Key('link-options')));
    await t.pumpAndSettle();
    expect(find.text('링크 미리보기 설정'), findsOneWidget);
    expect(find.byKey(const Key('compose-tab-reply')), findsNothing, reason: 'no reply = no tabs');
    await t.tap(find.byKey(const Key('opt-link-up')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('opt-link-small')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-card-small')), findsOneWidget);
    await t.tap(find.byKey(const Key('pick-link-https://coffee.example/best')));
    await t.pumpAndSettle();
    expect(find.text('최고의 커피'), findsOneWidget);
    await t.tap(find.byKey(const Key('opt-link-apply')));
    await t.pumpAndSettle();
    expect(find.text('최고의 커피'), findsOneWidget, reason: 'the line shows the picked link');
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    final sent = fake.rooms[bob]!.last;
    expect(sent.preview?.url, 'https://coffee.example/best');
    expect(sent.preview?.above, isTrue);
    expect(sent.preview?.small, isTrue);
    expect(find.byKey(const Key('link-card-small')), findsOneWidget);
    // The card is drawn above the words.
    final card = t.getTopLeft(find.byKey(const Key('link-card'))).dy;
    final words = t.getTopLeft(find.textContaining('목록:')).dy;
    expect(card, lessThan(words));
    state.stopLive();
  });

  testWidgets('400: ✕ or 미리보기 안 함 sends without a card', (t) async {
    final (fake, state, bob) = await openChat(t);
    await t.enterText(find.byKey(const Key('composer')), 'https://laura.travel/queens');
    await t.pump(const Duration(milliseconds: 800));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('link-options')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('opt-link-off')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-bar')), findsNothing);
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.last.preview, isNull);
    // Next message: the card is back by default.
    await t.enterText(find.byKey(const Key('composer')), 'https://laura.travel/queens');
    await t.pump(const Duration(milliseconds: 800));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-bar')), findsOneWidget);
    await t.tap(find.byKey(const Key('link-bar-close')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.last.preview, isNull);
    state.stopLive();
  });

  testWidgets('401: reply + link → 답장 | 링크 tabs; 답장 안 함 from the reply tab', (t) async {
    final (fake, state, bob) = await openChat(t);
    await t.fling(find.text('어디 갈까?'), const Offset(-300, 0), 1000);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '여기 https://laura.travel/queens');
    await t.pump(const Duration(milliseconds: 800));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-bar')), findsOneWidget);
    await t.tap(find.byKey(const Key('link-options')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('compose-tab-reply')), findsOneWidget);
    await t.tap(find.byKey(const Key('compose-tab-reply')));
    await t.pumpAndSettle();
    expect(find.text('답장 설정'), findsOneWidget);
    expect(find.byKey(const Key('compose-reply-bubble')), findsOneWidget);
    expect(find.byKey(const Key('opt-reply-pick-part')), findsOneWidget);
    await t.tap(find.byKey(const Key('opt-reply-apply')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    final sent = fake.rooms[bob]!.last;
    expect(sent.replyTo, isNotNull);
    expect(sent.preview?.title, '퀸즈 맛집 2026');
    state.stopLive();
  });
}
