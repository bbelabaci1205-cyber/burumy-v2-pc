// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가입 심사 도우미 (join helper): the rules (same as server/gate), the
// quiz an applicant answers (right / try again / let in), and the admin
// page (switch on: waiting requests are decided, the log shows why).
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/room_links.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/gate_sample.dart';
import 'package:burumy/demo/more_sample.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/invite_links.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/join_gate_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  Features.joinGate = true;
  addTearDown(() => Features.joinGate = false);
  final photo = File('test/assets/sample_photo.png').readAsBytesSync();
  final b = demoSample(true, photo);
  addMoreChats(b, true, photo);
  addGateSample(b, true);
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> push(WidgetTester t, Widget page) async {
  t.state<NavigatorState>(find.byType(Navigator).first).push(IosPageRoute(builder: (_) => page));
  await t.pumpAndSettle();
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  if (f.hitTestable().evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  const quiz = GateQuestion(q: 'BPM?', choices: ['빠르기', '길이'], right: 0);
  const written = GateQuestion(q: '어떤 음악을 만들어요?');

  test('rules: quiz, empty answers, blocked words, fake and checking accounts', () {
    const g = GateSettings(on: true, words: ['코인']);
    expect(gateScreen(const [quiz, written], g, ['0', '하우스 음악']), 'ok');
    expect(gateScreen(const [quiz, written], g, ['1', '하우스 음악']), 'quiz');
    expect(gateScreen(const [quiz, written], g, ['0', ' ']), 'empty');
    expect(gateScreen(const [quiz, written], g.copyWith(needAnswers: false), ['0', '']), 'ok');
    expect(gateScreen(const [quiz, written], g, ['0', '코인 드려요']), 'words');
    expect(gateScreen(const [quiz, written], g, ['0', '음악'], name: '무료 코인'), 'words');
    expect(gateScreen(const [quiz, written], g, ['0', '음악'], flag: 'fake'), 'fake');
    expect(gateScreen(const [quiz, written], g, ['0', '음악'], flag: 'checking'), 'checking');
    expect(gateRightWrong(const [quiz, written], ['0', 'x']), [true, null]);
  });

  test('settings and log round-trip through the room config', () {
    final cfg = <String, dynamic>{
      'gate': const GateSettings(on: true, words: ['코인'], about: '음악').toJson(),
      'join_questions': [quiz.toJson(), written.toJson()],
    };
    final g = GateSettings.from(cfg);
    expect(g.on && g.needAnswers, isTrue);
    expect(g.words, ['코인']);
    final qs = GateQuestion.listFrom(cfg);
    expect(qs.length, 2);
    expect(qs[0].quiz && qs[0].right == 0, isTrue);
    expect(qs[1].quiz, isFalse);
    expect(GateSettings.from(const {}).on, isFalse);
    final log = GateEntry.listFrom({
      'e': [
        {'u': '@a:t', 'n': '가', 'v': 'ok', 't': 1},
        {'u': '@b:t', 'n': '', 'v': 'quiz', 't': 2},
        {'u': '@c:t', 'n': '다', 'v': 'checking', 't': 3},
      ],
    });
    expect([for (final e in log) e.kind], ['held', 'out', 'in']); // newest first
    expect(log[1].name, '@b:t');
  });

  testWidgets('applicant: wrong pick says try again, right moves on, written answer, then in', (t) async {
    final (_, b) = await start(t);
    final qs = await b.gateQuestions('public', 'music_makers');
    expect(qs, isNotNull);
    expect(qs!.length, 3);
    expect(qs.every((q) => q.right == -1), isTrue, reason: 'right answers never reach the applicant');
    await push(t, JoinQuizPage(kind: 'public', code: 'music_makers', name: '음악 만드는 사람들', questions: qs));
    expect(find.text('질문 1/3'), findsOneWidget);
    await t.tap(find.byKey(const Key('quiz-choice-1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quiz-try-again')), findsOneWidget);
    await t.tap(find.byKey(const Key('quiz-choice-0')));
    await t.pump();
    await t.pump(const Duration(seconds: 1)); // right: a moment of ✓, then the next one
    await t.pumpAndSettle();
    expect(find.text('질문 2/3'), findsOneWidget);
    await t.tap(find.byKey(const Key('quiz-choice-2')));
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('질문 3/3'), findsOneWidget);
    await t.enterText(find.byKey(const Key('quiz-written')), '집에서 로파이 비트를 만들어요');
    await t.pump();
    await t.tap(find.byKey(const Key('quiz-go')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quiz-result-in')), findsOneWidget);
    expect(find.text('들어왔어요'), findsOneWidget);
    expect(b.rooms.containsKey('!music_makers'), isTrue);
  });

  testWidgets('applicant: link page asks the questions first', (t) async {
    await start(t);
    final ctx = t.element(find.byType(Navigator).first);
    openJoinLink(ctx, const LinkTarget(kind: 'public', code: 'music_makers'));
    await t.pumpAndSettle();
    expect(find.text('질문에 답하고 신청하기'), findsOneWidget);
    await t.tap(find.byKey(const Key('join-go')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quiz-step')), findsOneWidget);
  });

  testWidgets('admin: answers shown, helper switched on decides the waiting requests', (t) async {
    final (_, b) = await start(t);
    final room = b.links.entries.firstWhere((e) => e.value.code == 'mangwon_friends').key;
    await push(t, JoinRequestsPage(roomId: room));
    expect(find.textContaining('망원동 어디쯤 사세요?: 망원역 2번 출구 근처요'), findsOneWidget);
    expect(find.textContaining('우리 모임은 어느 동네 모임일까요?: 망원동'), findsWidgets);
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await t.pumpAndSettle();

    await push(t, GatePage(roomId: room));
    expect(find.text('질문 추가'), findsOneWidget);
    expect(find.byKey(const Key('gate-q-0')), findsOneWidget);
    await t.tap(find.byKey(const Key('gate-on')));
    await t.pumpAndSettle();
    expect(find.text('대화를 못 읽어요'), findsOneWidget);
    expect(find.text('암호 열쇠 0개'), findsOneWidget);
    expect(b.requests[room], isEmpty);
    expect(b.roomMembers[room]!.any((m) => m.userId == '@seoa:test'), isTrue);
    await tapKey(t, 'gate-log');
    expect(find.text('들어옴'), findsOneWidget);
    expect(find.text('거절'), findsNWidgets(2));
    expect(find.textContaining('글 답을 비웠어요'), findsOneWidget);
    expect(find.textContaining('금지어가 있어요'), findsOneWidget);
  });

  testWidgets('admin: a quiz question with choices and the right answer', (t) async {
    await start(t);
    GateQuestion? got;
    final ctx = t.element(find.byType(Navigator).first);
    Navigator.of(ctx).push<Object>(IosPageRoute(builder: (_) => const GateQuestionPage())).then((v) => got = v as GateQuestion?);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('gate-q-text')), '소리 파일이 아닌 것은?');
    await t.enterText(find.byKey(const Key('gate-choice-0')), 'WAV');
    await t.enterText(find.byKey(const Key('gate-choice-1')), 'PDF');
    await t.tap(find.byKey(const Key('gate-choice-add')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('gate-choice-2')), 'MP3');
    await t.tap(find.byKey(const Key('gate-right-1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('gate-q-done')));
    await t.pumpAndSettle();
    expect(got?.q, '소리 파일이 아닌 것은?');
    expect(got?.choices, ['WAV', 'PDF', 'MP3']);
    expect(got?.right, 1);
  });
}
