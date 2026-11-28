// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 모임 일정 업그레이드: end time, people I bring (+N), 1시간 전 알림,
// 내 일정 (설정), 캘린더에 추가 (.ics).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/calendar_event.dart';
import 'package:burumy/core/my_plans.dart';
import 'package:burumy/core/reminders.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show showTab, reveal;
import 'package:burumy/ui/glass.dart' show GlassBack;

import 'fake_backend.dart';

void main() {
  test('.ics has UTC times, an alarm 1 hour before, escaped text, folded lines', () {
    final e = CalendarEvent(
      title: '연말 모임, 2차; 노래방',
      start: DateTime.utc(2030, 12, 14, 10),
      end: DateTime.utc(2030, 12, 14, 13),
      place: '강남역 3번 출구 고깃집 강남역 3번 출구 고깃집 강남역 3번 출구 고깃집',
      id: r'$abc:x',
    );
    final ics = e.ics(now: DateTime.utc(2030));
    expect(ics, contains('DTSTART:20301214T100000Z\r\n'));
    expect(ics, contains('DTEND:20301214T130000Z\r\n'));
    expect(ics, contains(r'SUMMARY:연말 모임\, 2차\; 노래방'));
    expect(ics, contains('TRIGGER:-PT1H'));
    expect(ics, contains('UID:abcx@burumy'));
    for (final line in ics.split('\r\n')) {
      expect(line.length <= 75, isTrue, reason: line);
    }
    // No end: two hours.
    expect(CalendarEvent(title: 'x', start: DateTime.utc(2030)).until, DateTime.utc(2030, 1, 1, 2));
  });

  testWidgets('make with an end time, go with +2, reminder, 내 일정, calendar, cancel (ko)', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    CalendarEvent? added;
    CalendarEvent.debugAdd = (e) async {
      added = e;
      return true;
    };
    addTearDown(() => CalendarEvent.debugAdd = null);
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
    await showTab(t, 'attach-tab-meetup');
    await t.tap(find.byKey(const Key('attach-tab-meetup')));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('meetup-title')), '송년회');
    await t.enterText(find.byKey(const Key('meetup-place')), '을지로');
    expect(find.byKey(const Key('meetup-start-wheel')), findsOneWidget);
    await t.tap(find.byKey(const Key('meetup-end-switch')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('meetup-start-wheel')), findsNothing, reason: 'one wheel at a time');
    expect(find.byKey(const Key('meetup-end-wheel')), findsOneWidget);
    expect(find.text('1시간 전에 알림'), findsOneWidget);
    await t.tap(find.byKey(const Key('meetup-create')));
    await t.pumpAndSettle();

    final msg = fake.rooms[team]!.lastWhere((m) => m.kind == 'meetup');
    final plan = msg.meetup!;
    expect(plan.endsAt, plan.startsAt.add(const Duration(hours: 2)));
    expect(find.textContaining('–'), findsWidgets, reason: 'time shows start – end');
    // Made by me: already in 내 일정, with a reminder 1 hour before.
    expect(MyPlans.find(state, msg.id)!.answer, 'mine');
    expect(reminders(state).single.at, plan.startsAt.subtract(const Duration(hours: 1)));
    expect(reminders(state).single.chat, '1시간 뒤: 송년회');

    // 갈게요, then bring two people.
    await t.tap(find.byKey(const Key('meetup-yes')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('meetup-guests')), findsOneWidget);
    await t.tap(find.byKey(const Key('meetup-guest-plus')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('meetup-guest-plus')));
    await t.pumpAndSettle();
    var now = fake.rooms[team]!.firstWhere((m) => m.id == msg.id).meetup!;
    expect(now.guests['@me:test'], 2);
    expect(now.coming, 3);
    expect(find.text('갈게요 3'), findsOneWidget);
    expect(MyPlans.find(state, msg.id)!.guests, 2);
    await t.tap(find.byKey(const Key('meetup-guest-minus')));
    await t.pumpAndSettle();
    now = fake.rooms[team]!.firstWhere((m) => m.id == msg.id).meetup!;
    expect(now.guests['@me:test'], 1);

    // 캘린더에 추가.
    await t.tap(find.byKey(const Key('meetup-calendar')));
    await t.pumpAndSettle();
    expect(added!.title, '송년회');
    expect(added!.end, plan.endsAt);
    expect(added!.place, '을지로');

    // 못 가요: off 내 일정, no reminder.
    await t.tap(find.byKey(const Key('meetup-no')));
    await t.pumpAndSettle();
    expect(MyPlans.find(state, msg.id), isNull);
    expect(reminders(state), isEmpty);
    await t.tap(find.byKey(const Key('meetup-yes')));
    await t.pumpAndSettle();
    expect(MyPlans.find(state, msg.id)!.answer, 'yes');

    // 설정 > 내 일정.
    await t.tap(find.byType(GlassBack).first);
    await t.pumpAndSettle();
    await t.tap(find.text('설정'));
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('plans-row')));
    await t.tap(find.byKey(const Key('plans-row')));
    await t.pumpAndSettle();
    expect(find.text('다가오는 일정'), findsOneWidget);
    expect(find.byKey(Key('plan-${msg.id}')), findsOneWidget);
    expect(find.textContaining('갈게요'), findsWidgets);
    // Reminder switch off takes the reminder away; on puts it back.
    await t.tap(find.byKey(const Key('plans-remind')));
    await t.pumpAndSettle();
    expect(reminders(state), isEmpty);
    await t.tap(find.byKey(const Key('plans-remind')));
    await t.pumpAndSettle();
    expect(reminders(state), hasLength(1));
    // Tap: back in the chat at the plan.
    await t.tap(find.byKey(Key('plan-${msg.id}')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('meetup-${msg.id}')), findsOneWidget);
    // The maker cancels it: off the list.
    await t.tap(find.byKey(const Key('meetup-cancel')));
    await t.pumpAndSettle();
    expect(MyPlans.find(state, msg.id), isNull);
    expect(reminders(state), isEmpty);
    state.stopLive();
  });

  test('answers with guests', () {
    final p = MeetupInfo(title: 'x', startsAt: _t, cancelled: true);
    expect(p.copyWith(cancelled: false).cancelled, isFalse);
    expect(MeetupInfo.answerWith('yes', 3), 'yes+3');
    expect(MeetupInfo.answerWith('yes', 0), 'yes');
    expect(MeetupInfo.answerWith('maybe', 2), 'maybe');
    expect(MeetupInfo.answerWith('yes', 40), 'yes+9');
  });
}

final _t = DateTime(2030);
