// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 4-messenger batch 2: 전화 무시, 모르는 사람 전화 정보, 영상 통화 화면 잠금,
// (일부만 골라 답장 is the tips-reply thread's 인용, tip 399.)
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/call_media.dart';
import 'package:burumy/core/call_session.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'call_test.dart' show tick;
import 'fake_backend.dart';
import 'fake_call_media.dart';

void main() {
  setUp(() {
    CallMedia.make = FakeCallMedia.new;
    CallSession.active = null;
    CallSession.waiting.value = null;
  });

  Future<(FakeBackend, AppState)> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    return (fake, state);
  }

  Future<void> ring(WidgetTester t, AppState state) async {
    await state.refresh();
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
  }

  testWidgets('무시: the ringing stops on my side, nothing is sent; a stranger shows as unknown (ko)', (t) async {
    final (fake, state) = await boot(t);
    final mina = await fake.createDirectChat('@mina:test');
    fake.strangerRooms.add(mina);
    await fake.createGroup('동네 모임', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    final id = fake.receiveCall(mina, '@mina:test');
    await ring(t, state);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('caller-unknown')), findsOneWidget);
    expect(find.text('연락처에 없는 사람이에요'), findsOneWidget);
    expect(find.textContaining('같은 그룹 1개'), findsOneWidget);
    expect(find.text('무시'), findsOneWidget);
    await t.tap(find.byKey(const Key('call-ignore')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-accept')), findsNothing);
    expect(fake.hangups[id], isNull, reason: 'the caller keeps hearing it ring');
    state.stopLive();
  });

  testWidgets('a friend in my contacts: no unknown card (ko)', (t) async {
    final (fake, state) = await boot(t);
    final bob = await fake.createDirectChat('@bob:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    fake.receiveCall(bob, '@bob:test');
    await ring(t, state);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('call-accept')), findsOneWidget);
    expect(find.byKey(const Key('caller-unknown')), findsNothing);
    await t.tap(find.byKey(const Key('call-decline')));
    await tick(t, 2);
    await t.pumpAndSettle();
    state.stopLive();
  });

  testWidgets('video call: 화면 잠금 hides the buttons until a long hold (ko)', (t) async {
    final (fake, state) = await boot(t);
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    fake.receiveCall(bob, '@bob:test', video: true);
    await ring(t, state);
    await t.tap(find.byKey(const Key('call-accept')));
    await t.pump();
    FakeCallMedia.last!.otherJoins();
    await tick(t);
    await t.tap(find.byKey(const Key('call-lock')));
    await t.pump();
    expect(find.byKey(const Key('call-end')), findsNothing);
    expect(find.text('화면 잠김 · 길게 눌러 풀기'), findsOneWidget);
    await t.tap(find.byKey(const Key('call-locked')));
    await t.pump();
    expect(find.byKey(const Key('call-end')), findsNothing, reason: 'a tap does nothing');
    await t.longPress(find.byKey(const Key('call-locked')));
    await t.pump();
    expect(find.byKey(const Key('call-end')), findsOneWidget);
    await t.tap(find.byKey(const Key('call-end')));
    await tick(t, 2);
    await t.pumpAndSettle();
    state.stopLive();
  });
}
