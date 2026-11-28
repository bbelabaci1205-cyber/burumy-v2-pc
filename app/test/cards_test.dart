// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Channel/group cards: data checks (including tricks), giveaway, form,
// check-in, FAQ, guide, link buttons, formatted post and templates.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/cards.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend, String)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  final team = await b.createGroup('우리 팀', ['@mina:test']);
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('우리 팀'));
  await t.pumpAndSettle();
  return (s, b, team);
}

Future<void> tap(WidgetTester t, String key) async {
  // Long editors build lazily: scroll back up when the row is not built.
  if (find.byKey(Key(key)).evaluate().isEmpty) {
    final editor = find.byKey(const Key('card-editor-list')).evaluate().isNotEmpty;
    final list = editor ? editorList() : find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).last;
    await t.scrollUntilVisible(find.byKey(Key(key)), -200, scrollable: list);
    await t.pumpAndSettle();
  }
  final f = find.byKey(Key(key)).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

/// The editor page's own list (text fields have scrollables too).
Finder editorList() => find.descendant(of: find.byKey(const Key('card-editor-list')), matching: find.byType(Scrollable)).first;

/// Like [tap], but scrolls down first (rows further down a long editor).
Future<void> tapBelow(WidgetTester t, String key) async {
  if (find.byKey(Key(key)).evaluate().isEmpty) {
    await t.scrollUntilVisible(find.byKey(Key(key)), 200, scrollable: editorList());
    await t.pumpAndSettle();
  }
  await tap(t, key);
}

/// Types into a field that may be further down the editor.
Future<void> typeBelow(WidgetTester t, String key, String text) async {
  if (find.byKey(Key(key)).evaluate().isEmpty) {
    await t.scrollUntilVisible(find.byKey(Key(key)), 200, scrollable: editorList());
    await t.pumpAndSettle();
  }
  await t.enterText(find.byKey(Key(key)), text);
  await t.pump();
}

Future<void> tool(WidgetTester t, String id) async {
  await tap(t, 'attach');
  // The tab bar scrolls sideways and builds tabs lazily.
  final bar = find.descendant(of: find.byKey(const Key('attach-sheet')), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right)).last;
  await t.dragUntilVisible(find.byKey(Key('attach-tab-$id')), bar, const Offset(-120, 0));
  await t.pumpAndSettle();
  await t.tap(find.byKey(Key('attach-tab-$id')));
  await t.pumpAndSettle();
}

Msg card(String id, String kind, Map<String, Object?> data, {String sender = '@mina:test'}) => Msg(
  id: id,
  sender: sender,
  body: cardBody(kind, data),
  time: DateTime.now(),
  mine: false,
  kind: 'card',
  card: CardInfo(kind: kind, data: data),
);

void main() {
  final now = DateTime(2026, 11, 24, 12);

  test('checks: bad links, too many buttons, empty cards, odd colours', () {
    final d = demoCheckCard('links', {
      'buttons': [
        {'label': '사이트', 'url': 'https://burumy.app', 'color': 'blue'},
        {'label': '나쁜', 'url': 'javascript:alert(1)'},
        {'label': '공백', 'url': 'https://a b.com'},
        {'label': '', 'url': 'https://x.com'},
        {'label': '이상한 색', 'url': 'https://x.com', 'color': '#ff0000'},
        for (var i = 0; i < 30; i++) {'label': 'b$i', 'url': 'https://x.com', 'row': 1},
      ],
      'style': {'size': 'huge', 'shape': 'pill'},
    }, now);
    final b = d['buttons'] as List;
    expect(b.where((x) => x['row'] == 0).length, 2, reason: 'only safe buttons');
    expect(b.where((x) => x['row'] == 1).length, 3, reason: 'three per row');
    expect(b[1]['color'], '', reason: 'unknown colour follows the shared one');
    expect((d['style'] as Map)['size'], 'm');
    expect((d['style'] as Map)['shape'], 'pill');
    expect(() => demoCheckCard('links', {'buttons': []}, now), throwsArgumentError);
    expect(() => demoCheckCard('faq', {'items': []}, now), throwsArgumentError);
    expect(() => demoCheckCard('lottery', {'prize': '커피', 'winners': 0}, now), throwsArgumentError);
    expect(() => demoCheckCard('lottery', {'prize': '커피', 'ends_at': now.millisecondsSinceEpoch - 1}, now), throwsArgumentError);
    expect(() => demoCheckCard('nope', {}, now), throwsArgumentError);
    final f = demoCheckCard('form', {
      'title': '신청',
      'questions': [
        {'q': '이름'},
        {
          'q': '사이즈',
          'options': ['S', 'M'],
        },
        {
          'q': '하나뿐',
          'options': ['A'],
        },
      ],
    }, now);
    expect([for (final q in f['questions'] as List) q['type']], ['text', 'choice', 'text']);
  });

  test('web links: plain names become https, others refused', () {
    expect(webLink('example.com'), 'https://example.com');
    expect(webLink('http://a.kr/x'), 'http://a.kr/x');
    expect(webLink('javascript:alert(1)'), isNull);
    expect(webLink('not a link'), isNull);
    expect(webLink(''), isNull);
  });

  testWidgets('giveaway: make, others join, draw never picks me, private winners', (t) async {
    final (_, b, team) = await start(t);
    await tool(t, 'lottery');
    expect(find.byKey(const Key('card-send')), findsOneWidget);
    await t.enterText(find.byKey(const Key('lottery-prize')), '커피 쿠폰');
    await t.pump();
    await tap(t, 'lottery-plus');
    expect(find.text('2'), findsWidgets);
    await tap(t, 'card-send');
    final m = b.rooms[team]!.lastWhere((m) => m.kind == 'card');
    expect(m.card!.data['winners'], 2);
    expect(m.card!.data['announce'], false);
    expect(find.text('커피 쿠폰'), findsOneWidget);
    // I made it: I can't join, but I can draw.
    b.seedCardAnswers(team, m.id, {'@mina:test': 'in', '@bob:test': 'in', '@me:test': 'in'});
    await tap(t, 'lottery-draw');
    await tap(t, 'card-confirm');
    final c = b.rooms[team]!.firstWhere((x) => x.id == m.id).card!;
    expect(c.closed, isTrue);
    expect(c.winners, unorderedEquals(['@mina:test', '@bob:test']), reason: 'the maker never wins');
    expect(find.byKey(const Key('lottery-winners-list')), findsOneWidget);
  });

  testWidgets('member side: join and leave a giveaway, check in, open FAQ and guide', (t) async {
    final (_, b, team) = await start(t);
    b.rooms[team]!.addAll([
      card('g', 'lottery', {'prize': '책', 'winners': 1, 'ends_at': 0, 'note': '', 'announce': false}),
      card('c', 'checkin', {'text': '모두 괜찮아요?'}),
      card('f', 'faq', {
        'title': '자주 묻는 질문',
        'items': [
          {'q': '언제 열어요?', 'a': '매일 9시요'},
        ],
      }),
      card('m', 'guide', {
        'title': '도와드릴까요?',
        'sub': '',
        'items': [
          {'label': '가격', 'text': '만 원이에요'},
        ],
      }),
    ]);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();

    await tap(t, 'lottery-join');
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'g').card!.mine, 'in');
    expect(find.text('1명 참여'), findsOneWidget);
    await tap(t, 'lottery-join');
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'g').card!.mine, isNull, reason: 'tapping again leaves');

    await tap(t, 'checkin-help');
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'c').card!.counts['help'], 1);
    expect(find.byKey(const Key('card-answers')), findsNothing, reason: 'only the maker reads answers');

    expect(find.byKey(const Key('faq-answer-0')), findsNothing);
    await tap(t, 'faq-item-0');
    expect(find.text('매일 9시요'), findsOneWidget);

    await tap(t, 'guide-item-0');
    expect(find.byKey(const Key('guide-text')), findsOneWidget);
  });

  testWidgets('form: maker builds it, a member fills it, the maker reads it', (t) async {
    final (_, b, team) = await start(t);
    await tool(t, 'form');
    await t.enterText(find.byKey(const Key('form-title')), '송년 산행');
    await t.enterText(find.byKey(const Key('form-q-0')), '이름');
    await tap(t, 'form-add');
    await t.enterText(find.byKey(const Key('form-q-1')), '사이즈');
    await t.pump();
    final seg = find.byKey(const Key('form-type-1'));
    await t.ensureVisible(seg);
    await t.tapAt(t.getTopRight(seg) + const Offset(-20, 18));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('form-options-1')), 'S\nM\nL');
    await t.pump();
    await tap(t, 'card-send');
    final m = b.rooms[team]!.lastWhere((m) => m.kind == 'card');
    expect([for (final q in m.card!.listOf('questions')) q['type']], ['text', 'choice']);
    b.seedCardAnswers(team, m.id, {
      '@mina:test': ['미나', 'M'],
    });
    await t.pumpAndSettle();
    // Re-open so the bubble sees the new numbers.
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    expect(find.text('1명 보냄'), findsOneWidget);
    await tap(t, 'card-answers');
    expect(find.byKey(const Key('answer-@mina:test-1')), findsOneWidget);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('member fills a form with a choice', (t) async {
    final (_, b, team) = await start(t);
    b.rooms[team]!.add(
      card('f', 'form', {
        'title': '신청',
        'questions': [
          {'q': '이름', 'type': 'text', 'options': <String>[]},
          {
            'q': '사이즈',
            'type': 'choice',
            'options': ['S', 'M'],
          },
        ],
      }),
    );
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await tap(t, 'form-fill');
    await t.enterText(find.byKey(const Key('fill-0')), '나');
    await tap(t, 'fill-1-1');
    await tap(t, 'card-send');
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'f').card!.mine, ['나', 'M']);
    expect(find.text('보냈어요'), findsOneWidget);
  });

  testWidgets('link buttons: build rows, style, and opening shows the real address', (t) async {
    final (_, b, team) = await start(t);
    await tool(t, 'links');
    await tap(t, 'links-add');
    await t.enterText(find.byKey(const Key('links-label')), '홈페이지');
    await t.enterText(find.byKey(const Key('links-url')), 'burumy.app');
    await t.pump();
    await tap(t, 'links-own-blue');
    await tap(t, 'links-add-0');
    await t.enterText(find.byKey(const Key('links-label')), '가짜');
    await t.enterText(find.byKey(const Key('links-url')), 'https://paypa1.com/login');
    await t.pump();
    await tap(t, 'links-glass');
    await tap(t, 'card-send');
    final m = b.rooms[team]!.lastWhere((m) => m.kind == 'card');
    final btns = m.card!.listOf('buttons');
    expect(btns.map((x) => x['url']), ['https://burumy.app', 'https://paypa1.com/login']);
    expect(btns.first['color'], 'blue');
    expect((m.card!.data['style'] as Map)['glass'], false);
    await tap(t, 'link-btn-1');
    expect(find.text('https://paypa1.com/login'), findsOneWidget, reason: 'the real address, not the name');
    expect(find.text('주의: 의심스러운 링크예요'), findsOneWidget);
  });

  testWidgets('formatted post and templates', (t) async {
    final (s, b, team) = await start(t);
    // Long posts (2026-11-27) are for every chat, not only channels.
    await tap(t, 'attach');
    final bar = find
        .descendant(of: find.byKey(const Key('attach-sheet')), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right))
        .last;
    await t.dragUntilVisible(find.byKey(const Key('attach-tab-rich')), bar, const Offset(-120, 0));
    expect(find.byKey(const Key('attach-tab-rich')), findsOneWidget);
    await t.tapAt(const Offset(200, 100));
    await t.pumpAndSettle();

    await s.setPref('post_templates', '["매주 공지입니다"]');
    await tool(t, 'templates');
    await tap(t, 'template-0');
    expect(find.text('매주 공지입니다'), findsOneWidget, reason: 'goes into the message box');
    expect(b.rooms[team]!.any((m) => m.body == '매주 공지입니다'), isFalse, reason: 'not sent by itself');
  });

  testWidgets('old formatted posts still show', (t) async {
    final (s, b, team) = await start(t);
    b.rooms[team]!.add(card('old-rich', 'rich', {
      'title': '이번 주 소식',
      'blocks': [
        {'t': 'p', 'text': '안녕하세요'},
        {'t': 'li', 'text': '첫째'},
      ],
    }));
    await s.refresh();
    await t.pumpAndSettle();
    expect(find.text('이번 주 소식'), findsOneWidget);
    expect(find.text('첫째'), findsOneWidget);
  });

  // Choice flow (TelegramTips 576 without a bot).
  Map<String, Object?> movie({bool stats = true}) => {
    'title': '오늘 뭐 볼까?',
    'text': '',
    'start': '',
    'steps': [
      {
        'q': '기분은요?',
        'choices': [
          {'label': '신나게', 'to': 's1'},
          {'label': '차분하게', 'to': 'r1'},
        ],
      },
      {
        'q': '누구랑?',
        'choices': [
          {'label': '친구', 'to': 'r0'},
        ],
      },
    ],
    'results': [
      {
        'title': '액션',
        'text': '크게 봐요',
        'link': {'label': '예고편', 'url': 'https://burumy.app/t'},
      },
      {'title': '다큐', 'text': '', 'link': null},
    ],
    'stats': stats,
  };

  test('flow checks: bad targets, loops, blank results', () {
    final d = demoCheckCard('flow', {
      ...movie(),
      'steps': [
        {
          'q': '기분은요?',
          'choices': [
            {'label': '신나게', 'to': 's1'},
            {'label': '없는 곳', 'to': 's7'},
            {'label': '앞에 0', 'to': 'r01'},
            {'label': '', 'to': 'r0'},
          ],
        },
        {
          'q': '누구랑?',
          'choices': [
            {'label': '친구', 'to': 'r0'},
          ],
        },
      ],
    }, now);
    expect((d['steps'] as List).first['choices'], hasLength(1));
    expect(
      () => demoCheckCard('flow', {
        ...movie(),
        'steps': [
          {
            'q': 'a',
            'choices': [
              {'label': 'b', 'to': 's0'},
            ],
          },
        ],
      }, now),
      throwsArgumentError,
      reason: 'no way to any result',
    );
    expect(
      () => demoCheckCard('flow', {
        ...movie(),
        'results': [
          {'title': ' '},
        ],
      }, now),
      throwsArgumentError,
    );
    expect(
      flowReachesResult([
        ['s1'],
        ['r0'],
      ]),
      isTrue,
    );
    expect(
      flowReachesResult([
        ['s1'],
        ['s0'],
      ]),
      isFalse,
    );
  });

  testWidgets('flow: maker builds questions, choices, a result link and numbers', (t) async {
    final (_, b, team) = await start(t);
    await tool(t, 'flow');
    await typeBelow(t, 'flow-title', '오늘 뭐 볼까?');
    await typeBelow(t, 'flow-q-0', '기분은요?');
    await typeBelow(t, 'flow-choice-0-0', '신나게');
    await typeBelow(t, 'flow-choice-0-1', '차분하게');
    await t.pump();
    // Second question; the first one's choices still go to result 1.
    await tap(t, 'flow-add-q');
    await typeBelow(t, 'flow-q-1', '누구랑?');
    await typeBelow(t, 'flow-choice-1-0', '친구');
    await t.pump();
    await tap(t, 'flow-next-0-0');
    await tap(t, 'flow-to-s1');
    await tapBelow(t, 'flow-add-r');
    await typeBelow(t, 'flow-r-title-0', '액션');
    await typeBelow(t, 'flow-r-label-0', '예고편');
    await typeBelow(t, 'flow-r-url-0', 'burumy.app/t');
    await typeBelow(t, 'flow-r-title-1', '다큐');
    await t.pump();
    await tap(t, 'flow-next-0-1');
    await tap(t, 'flow-to-r1');
    await tap(t, 'card-send');
    final m = b.rooms[team]!.lastWhere((m) => m.kind == 'card');
    expect(m.card!.kind, 'flow');
    final steps = m.card!.listOf('steps');
    expect([for (final c in steps[0]['choices'] as List) c['to']], ['s1', 'r1']);
    expect([for (final c in steps[1]['choices'] as List) c['to']], ['r0'], reason: 'blank second choice is left out');
    expect(m.card!.listOf('results')[0]['link'], {'label': '예고편', 'url': 'https://burumy.app/t'});
    expect(m.card!.data['stats'], true);
    // Removing question 2 sends its pointers to the first result.
    expect(find.text('오늘 뭐 볼까?'), findsOneWidget);
    expect(find.byKey(const Key('flow-stats-open')), findsOneWidget, reason: 'the maker sees numbers');
    await expectLater(() => b.cardAnswers(team, m.id), throwsStateError, reason: 'no names to list');
  });

  testWidgets('flow editor: no path to a result keeps send off', (t) async {
    final (_, _, _) = await start(t);
    await tool(t, 'flow');
    await typeBelow(t, 'flow-title', 't');
    await typeBelow(t, 'flow-q-0', 'q');
    await typeBelow(t, 'flow-choice-0-0', 'a');
    await t.pump();
    await tap(t, 'flow-add-q');
    await typeBelow(t, 'flow-q-1', 'q2');
    await typeBelow(t, 'flow-choice-1-0', 'b');
    await typeBelow(t, 'flow-r-title-0', 'r');
    await t.pump();
    await tap(t, 'flow-next-0-0');
    await tap(t, 'flow-to-s1');
    await tap(t, 'flow-next-0-1');
    await tap(t, 'flow-to-s1');
    await tap(t, 'flow-next-1-0');
    await tap(t, 'flow-to-s0');
    await t.scrollUntilVisible(find.byKey(const Key('card-error')), -300, scrollable: editorList());
    expect(find.byKey(const Key('card-error'), skipOffstage: false), findsOneWidget);
    expect(find.text('어떤 선택으로도 결과에 닿지 않아요. 선택지가 어디로 가는지 확인해 주세요.', skipOffstage: false), findsOneWidget);
    // Removing question 2 points its choices at a result again.
    await tapBelow(t, 'flow-remove-q-1');
    await t.scrollUntilVisible(find.byKey(const Key('flow-title')), -300, scrollable: editorList());
    await t.drag(find.byKey(const Key('flow-title')), const Offset(0, 600));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('flow-title')), findsOneWidget);
    expect(find.byKey(const Key('card-error'), skipOffstage: false), findsNothing);
  });

  testWidgets('flow: member taps through, goes back, reaches a result, tries again, reverts', (t) async {
    final (_, b, team) = await start(t);
    b.rooms[team]!.add(card('w', 'flow', movie()));
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    expect(find.text('시작하기'), findsOneWidget);
    await tap(t, 'flow-start');
    expect(find.text('기분은요?'), findsOneWidget);
    expect(find.text('질문 1'), findsOneWidget);
    await tap(t, 'flow-choice-0');
    expect(find.text('누구랑?'), findsOneWidget);
    expect(find.text('질문 2'), findsOneWidget);
    await tap(t, 'flow-back');
    expect(find.text('기분은요?'), findsOneWidget);
    await tap(t, 'flow-choice-0');
    await tap(t, 'flow-choice-0');
    expect(find.byKey(const Key('flow-result')), findsOneWidget);
    expect(find.text('액션'), findsOneWidget);
    // Only the result number went to the maker, under a code, not my ID.
    final c = b.rooms[team]!.firstWhere((m) => m.id == 'w').card!;
    expect(c.mine, 'r0');
    expect(c.counts, {'r0': 1});
    expect(b.cardBooks['w']!.keys.single, isNot(contains('me')));
    expect(find.byKey(const Key('flow-stats-open')), findsNothing, reason: 'members see no stats page');
    await tap(t, 'flow-link-0');
    expect(find.text('https://burumy.app/t'), findsOneWidget, reason: 'the real address first');
    await t.tap(find.text('취소').last);
    await t.pumpAndSettle();
    await tap(t, 'flow-again');
    expect(find.text('기분은요?'), findsOneWidget);
    await tap(t, 'flow-choice-1');
    expect(find.text('다큐'), findsOneWidget);
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'w').card!.counts, {'r1': 1}, reason: 'one person counts once');
    // Long press: back to the start (Telegram's Revert).
    await t.longPress(find.text('다큐'));
    await t.pumpAndSettle();
    await tap(t, 'menu-flow-revert');
    expect(find.byKey(const Key('flow-start')), findsOneWidget);
    expect(find.text('1명이 결과를 받았어요'), findsOneWidget);
  });

  testWidgets('flow: numbers off sends nothing; maker stats page shows counts only', (t) async {
    final (_, b, team) = await start(t);
    b.rooms[team]!.add(card('q', 'flow', movie(stats: false)));
    b.rooms[team]!.add(
      Msg(
        id: 'mine',
        sender: '@me:test',
        body: '🧩 내 카드',
        time: DateTime.now(),
        mine: true,
        kind: 'card',
        card: CardInfo(kind: 'flow', data: {...movie(), 'title': '내 카드'}, counts: const {'r0': 3, 'r1': 1}),
      ),
    );
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await tap(t, 'flow-stats-open');
    expect(find.text('3 · 75%'), findsOneWidget);
    expect(find.text('1 · 25%'), findsOneWidget);
    expect(find.text('4명이 결과를 받았어요\n\n결과마다 몇 명인지만 보여요. 누가 어떤 결과를 받았는지는 아무도 몰라요.'), findsOneWidget);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await tap(t, 'flow-start');
    await tap(t, 'flow-choice-1');
    expect(b.rooms[team]!.firstWhere((m) => m.id == 'q').card!.mine, isNull, reason: 'numbers off: nothing leaves the phone');
  });
}
