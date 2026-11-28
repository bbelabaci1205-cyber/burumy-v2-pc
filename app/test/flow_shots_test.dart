// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 선택형 카드 (Eric 2026-11-27, TelegramTips 576): screenshots of the card
// in a channel (start, question, result, long-press revert), the editor and
// the maker's numbers page.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/cards.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

Map<String, Object?> movie() => {
  'title': '오늘 밤 뭐 볼까요? 🍿',
  'text': '질문 3개에 답하면 딱 맞는 영화를 골라 드려요.',
  'start': '내 영화 찾기',
  'steps': [
    {
      'q': '오늘 기분은요?',
      'choices': [
        {'label': '신나게', 'to': 's1'},
        {'label': '웃고 싶어요', 'to': 's1'},
        {'label': '두근두근', 'to': 's1'},
        {'label': '차분하게', 'to': 'r1'},
      ],
    },
    {
      'q': '누구랑 봐요?',
      'choices': [
        {'label': '혼자', 'to': 'r0'},
        {'label': '친구들', 'to': 'r0'},
        {'label': '연인', 'to': 'r1'},
      ],
    },
  ],
  'results': [
    {
      'title': '우주 대서사 액션 🚀',
      'text': '큰 화면으로 보면 더 멋진 영화예요.',
      'link': {'label': '예고편 보기', 'url': 'https://burumy.app/movies/epic'},
    },
    {'title': '자연 다큐멘터리 🌿', 'text': '잔잔하게 쉬어 가요.', 'link': null},
  ],
  'stats': true,
};

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });

  Future<(FakeBackend, String)> open(WidgetTester t, {bool maker = false}) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    FlowProgress.reset('flow1');
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('영화 모임', ['@mina:test']);
    b.rooms[room]!.add(
      Msg(
        id: 'flow1',
        sender: maker ? '@me:test' : '@mina:test',
        body: '🧩 오늘 밤 뭐 볼까요?',
        // Fixed time so the pictures stay the same.
        time: DateTime(2026, 11, 27, 21, 41),
        mine: maker,
        kind: 'card',
        card: CardInfo(kind: 'flow', data: movie(), counts: const {'r0': 58, 'r1': 23}),
      ),
    );
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('영화 모임'));
    await t.pumpAndSettle();
    return (b, room);
  }

  Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_40_flow_$name.png'));

  testWidgets('shots: member taps through the card', (t) async {
    await open(t);
    await shot(t, '1_start');
    await t.tap(find.byKey(const Key('flow-start')));
    await t.pumpAndSettle();
    await shot(t, '2_question');
    await t.tap(find.byKey(const Key('flow-choice-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('flow-choice-1')));
    await t.pumpAndSettle();
    await shot(t, '3_result');
    await t.longPress(find.byKey(const Key('flow-result')));
    await t.pumpAndSettle();
    await shot(t, '4_revert_menu');
  });

  testWidgets('shots: maker numbers page', (t) async {
    await open(t, maker: true);
    await shot(t, '5_maker_card');
    await t.tap(find.byKey(const Key('flow-stats-open')));
    await t.pumpAndSettle();
    await shot(t, '6_stats');
  });

  testWidgets('shots: editor', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    final bar = find
        .descendant(of: find.byKey(const Key('attach-sheet')), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right))
        .last;
    await t.dragUntilVisible(find.byKey(const Key('attach-tab-flow')), bar, const Offset(-120, 0));
    await t.pumpAndSettle();
    await shot(t, '7_attach_tab');
    await t.tap(find.byKey(const Key('attach-tab-flow')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('flow-title')), '오늘 밤 뭐 볼까요? 🍿');
    await t.enterText(find.byKey(const Key('flow-q-0')), '오늘 기분은요?');
    await t.enterText(find.byKey(const Key('flow-choice-0-0')), '신나게');
    await t.enterText(find.byKey(const Key('flow-choice-0-1')), '차분하게');
    await t.pumpAndSettle();
    await shot(t, '8_editor');
    await t.tap(find.byKey(const Key('flow-next-0-1')));
    await t.pumpAndSettle();
    await shot(t, '9_pick_next');
    await t.tap(find.byKey(const Key('flow-to-r0')));
    await t.pumpAndSettle();
    final list = find.descendant(of: find.byKey(const Key('card-editor-list')), matching: find.byType(Scrollable)).first;
    await t.scrollUntilVisible(find.byKey(const Key('flow-stats')), 300, scrollable: list);
    await t.pumpAndSettle();
    await shot(t, '10_editor_results');
  });
}
