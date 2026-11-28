// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Quiz polls (one right answer, final answers, explanation) and deadlines.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/poll.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deadline closes a poll; a past deadline is closed', () {
    final now = DateTime(2026, 11, 24, 12);
    final p = PollInfo(question: 'q', options: const [], closeAt: now.add(const Duration(minutes: 1)));
    expect(p.closedAt(now), isFalse);
    expect(p.closedAt(now.add(const Duration(minutes: 1))), isTrue);
    expect(const PollInfo(question: 'q', options: []).closedAt(now), isFalse);
  });

  testWidgets('quiz: pick the right answer, answer once, see right/wrong and why (ko)', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-poll')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('poll-question')), '2+2는?');
    await t.enterText(find.byKey(const Key('poll-option-0')), '3');
    await t.enterText(find.byKey(const Key('poll-option-1')), '4');
    await t.scrollUntilVisible(find.byKey(const Key('poll-quiz')), 120, scrollable: find.descendant(of: find.byType(CreatePollPage), matching: find.byType(Scrollable)).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-quiz')));
    await t.pumpAndSettle();
    expect(find.text('새 투표'), findsOneWidget, reason: 'before create');
    // No right answer chosen yet: can't make it.
    await t.tap(find.byKey(const Key('poll-create')), warnIfMissed: false);
    await t.pumpAndSettle();
    expect(fake.rooms[team]!.where((m) => m.kind == 'poll'), isEmpty);
    expect(find.byType(CreatePollPage), findsOneWidget, reason: 'still writing');
    await t.scrollUntilVisible(find.byKey(const Key('quiz-correct-1')), -120, scrollable: find.descendant(of: find.byType(CreatePollPage), matching: find.byType(Scrollable)).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('quiz-correct-1')));
    await t.scrollUntilVisible(find.byKey(const Key('quiz-explain')), 120, scrollable: find.descendant(of: find.byType(CreatePollPage), matching: find.byType(Scrollable)).first);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('quiz-explain')), '2 더하기 2는 4');
    await t.scrollUntilVisible(find.byKey(const Key('poll-deadline')), 120, scrollable: find.descendant(of: find.byType(CreatePollPage), matching: find.byType(Scrollable)).first);
    await t.tap(find.byKey(const Key('poll-deadline')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('deadline-2')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-create')));
    await t.pumpAndSettle();

    final m = fake.rooms[team]!.last;
    expect(m.poll!.correct, 'a1');
    expect(m.poll!.explain, '2 더하기 2는 4');
    expect(m.poll!.multiple, isFalse);
    expect(m.poll!.closeAt, isNotNull);
    expect(find.textContaining('퀴즈'), findsWidgets);
    expect(find.textContaining('남음'), findsOneWidget);

    await t.tap(find.byKey(const Key('poll-a0')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quiz-wrong')), findsOneWidget);
    expect(find.byKey(const Key('quiz-right')), findsOneWidget);
    expect(find.textContaining('아쉬워요'), findsOneWidget);
    expect(find.textContaining('2 더하기 2는 4'), findsOneWidget);
    // Answer is final: no take-back in the menu, and the engine refuses.
    await t.longPress(find.text('2+2는?'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-retract')), findsNothing);
    await expectLater(fake.vote(team, m.id, ['a1']), throwsStateError);
    state.stopLive();
  });
}
