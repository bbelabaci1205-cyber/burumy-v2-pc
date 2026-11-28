// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 안 읽은 대화 AI 요약: 10+ unread → a bar offers a summary made by the
// phone AI; none with 공유 비활성화, few unread, or no phone AI.
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_ai.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/unread_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _NoAi implements AiEngine {
  @override
  Future<AiStatus> status() async => AiStatus.unsupported;
  @override
  Future<String> run({required String rules, required String text}) async => throw const AiError('unsupported');
}

void main() {
  tearDown(() {
    LocalAi.engine = PhoneAi();
    LocalAi.reset();
  });

  Future<(FakeBackend, AppState, String)> open(WidgetTester t, int unread, {AiEngine? ai, bool protect = false}) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    LocalAi.engine = ai ?? DemoAi(delay: Duration.zero);
    LocalAi.reset();
    await LocalAi.status();
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final g = await fake.createGroup('토요일 모임', const ['@jisoo:test']);
    for (var i = 0; i < unread; i++) {
      fake.rooms[g]!.add(Msg(id: 'u$i', sender: '@jisoo:test', body: '메시지 $i', time: fake.now, mine: false, kind: 'text'));
    }
    fake.unreadCounts[g] = unread;
    if (protect) fake.roomConfigs[g] = {'protect': true};
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('토요일 모임'));
    await t.pumpAndSettle();
    return (fake, state, g);
  }

  testWidgets('many unread: the phone AI sums them up (ko)', (t) async {
    await open(t, 14);
    expect(find.text('안 읽은 메시지 14개 요약 보기'), findsOneWidget);
    await t.tap(find.byKey(const Key('unread-summary-open')));
    await t.pumpAndSettle();
    expect(find.textContaining('• 토요일 오후 2시'), findsOneWidget);
    expect(find.text('이 폰 AI로만 요약했어요. 대화는 폰 밖으로 나가지 않아요.'), findsOneWidget);
    await t.tap(find.byKey(const Key('unread-summary-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('unread-summary')), findsNothing);
  });

  testWidgets('few unread, 공유 비활성화, or no phone AI: no bar (ko)', (t) async {
    await open(t, 5);
    expect(find.byKey(const Key('unread-summary')), findsNothing);
  });
  testWidgets('공유 비활성화: no bar (ko)', (t) async {
    await open(t, 20, protect: true);
    expect(find.byKey(const Key('unread-summary')), findsNothing);
  });
  testWidgets('no phone AI: no bar (ko)', (t) async {
    await open(t, 20, ai: _NoAi());
    expect(find.byKey(const Key('unread-summary')), findsNothing);
  });

  test('input keeps names and the newest text, skips media', () {
    final now = DateTime(2026);
    final msgs = [
      for (var i = 0; i < 300; i++) Msg(id: '$i', sender: '@a:t', body: '긴 메시지 번호 $i 입니다', time: now, mine: false, kind: 'text'),
      Msg(id: 'p', sender: '@a:t', body: 'p.png', time: now, mine: false, kind: 'image'),
    ];
    final text = UnreadSummary.input(msgs, (s) => 'a');
    expect(text.length, lessThanOrEqualTo(UnreadSummary.maxChars));
    expect(text, endsWith('a: 긴 메시지 번호 299 입니다'));
    expect(text.contains('p.png'), isFalse);
  });
}
