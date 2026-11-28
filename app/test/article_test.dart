// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Long posts / formatted messages: document checks, typed marks, the
// editor (blocks, table, photo, undo, AI tidy), sending short (inside the
// message) and long (encrypted file), the bubble and the reading page.
import 'dart:convert';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/doc.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/article.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

// 1x1 PNG.
final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');

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
  final f = find.byKey(Key(key)).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

Future<void> openEditor(WidgetTester t) async {
  await tap(t, 'attach');
  final bar = find.descendant(of: find.byKey(const Key('attach-sheet')), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right)).last;
  await t.dragUntilVisible(find.byKey(const Key('attach-tab-rich')), bar, const Offset(-120, 0));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('attach-tab-rich')));
  await t.pumpAndSettle();
  expect(find.byKey(const Key('article-editor')), findsOneWidget);
}

void main() {
  test('documents are checked like the engine does', () {
    final d = Doc.clean({
      'title': 'T',
      'blocks': [
        {'t': 'script', 'text': '<script>'},
        {'t': 'p', 'text': 'hello\u0007 world'},
        {'t': 'h1', 'text': '   '},
        {
          't': 'img',
          'file': {'url': 'https://evil/x'},
        },
        {
          't': 'table',
          'rows': [
            ['a', 'b', 'c'],
            ['only one'],
          ],
        },
        {
          't': 'ol',
          'items': ['x', 5, ''],
          'start': -3,
        },
      ],
    });
    final b = (d['blocks'] as List).cast<Map>();
    expect(b.map((x) => x['t']), ['p', 'table', 'ol']);
    expect(b[0]['text'], 'hello world');
    expect((b[1]['rows'] as List)[1], ['only one', '', ''], reason: 'rows squared');
    expect(b[2]['items'], ['x']);
    expect(b[2]['start'], 0);
    // Total length is capped.
    final big = Doc.clean({
      'blocks': [
        for (var i = 0; i < 10; i++) {'t': 'p', 'text': '가' * 20000},
      ],
    });
    expect(Doc.fromJson(big).chars, lessThanOrEqualTo(DocLimits.chars));
    expect(
      Doc.cleanFile({
        'url': 'mxc://x/y',
        'key': {'alg': 'A256CTR', 'k': 'a b'},
        'iv': 'x',
        'hashes': {'sha256': 'y'},
      }),
      isNull,
    );
  });

  test('photo size is read from the header', () {
    expect(imageSize(png), (1, 1));
    expect(imageSize([1, 2, 3]), (0, 0));
  });

  test('typed marks become blocks and back', () {
    const text = '# 큰 제목\n## 작은 제목\n본문 한 줄\n둘째 줄\n\n- 사과\n- 배\n1. 하나\n2. 둘\n> 인용\n>> 큰 인용\n| 이름 | 나이 |\n|---|---|\n| 미나 | 20 |\n\$\$a^2+b^2=c^2\$\$\n```dart\nvoid main() {}\n```\n---';
    final b = blocksFromText(text);
    expect(b.map((x) => x.t), ['h1', 'h2', 'p', 'ul', 'ol', 'quote', 'pull', 'table', 'math', 'code', 'hr']);
    expect(b[2].text, '본문 한 줄\n둘째 줄');
    expect(b[3].items, ['사과', '배']);
    expect(b[7].rows, [
      ['이름', '나이'],
      ['미나', '20'],
    ]);
    expect(b[7].head, isTrue);
    expect(b[8].text, 'a^2+b^2=c^2');
    expect(b[9].lang, 'dart');
    final again = blocksFromText(textFromBlocks(Doc(blocks: b)));
    expect(again.map((x) => x.t), b.map((x) => x.t), reason: 'round trip');
  });

  test('short documents go inside the message, long ones as an encrypted file', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('g', []);
    final short = await b.sendArticle(
      room,
      Doc(
        title: '짧은 글',
        blocks: [DocBlock('p', text: '안녕')],
      ).toJson(),
    );
    final s = b.rooms[room]!.firstWhere((m) => m.id == short);
    expect(s.card!.kind, 'article');
    expect(s.card!.data['doc'], isNotNull);
    expect(s.body, '📰 짧은 글');
    final longDoc = Doc(
      title: '긴 글',
      blocks: [for (var i = 0; i < 40; i++) DocBlock('p', text: '문단 $i ${'내용' * 200}')],
    );
    final long = await b.sendArticle(room, longDoc.toJson());
    final l = b.rooms[room]!.firstWhere((m) => m.id == long);
    expect(l.card!.data['doc'], isNull, reason: 'not inside the message');
    expect(l.card!.data['file'], isNotNull);
    expect(((l.card!.data['preview'] as Map)['blocks'] as List).length, lessThanOrEqualTo(6));
    final opened = Doc.fromJson(await b.openArticle(room, long));
    expect(opened.blocks.length, 40);
    expect(opened.blocks.last.text, startsWith('문단 39'));
  });

  testWidgets('write a post with a heading, a table and a formula', (t) async {
    final (_, b, team) = await start(t);
    await openEditor(t);
    await t.enterText(find.byKey(const Key('article-title')), '여행 계획');
    await t.enterText(find.byKey(const Key('article-text-0')), '이번 주말에 가요.');
    await t.pump();
    // Style menu: a new block becomes a heading.
    await tap(t, 'article-table');
    await t.enterText(find.byKey(const Key('article-cell-1-0-0')), '날짜');
    await t.enterText(find.byKey(const Key('article-cell-1-0-1')), '장소');
    await t.enterText(find.byKey(const Key('article-cell-1-1-0')), '토요일');
    await t.enterText(find.byKey(const Key('article-cell-1-1-1')), '부산');
    await tap(t, 'table-add-col');
    await tap(t, 'article-plus');
    await tap(t, 'insert-math');
    await t.enterText(find.byKey(const Key('article-text-2')), r'\frac{1}{2}');
    await t.pump();
    // Undo / redo of a structure change.
    await tap(t, 'article-plus');
    await tap(t, 'insert-hr');
    expect(find.byKey(const Key('article-text-3')), findsNothing);
    await tap(t, 'article-undo');
    await tap(t, 'article-redo');
    await tap(t, 'article-undo');
    await tap(t, 'article-send');
    final m = b.rooms[team]!.lastWhere((m) => m.kind == 'card');
    final doc = Doc.fromJson(m.card!.data['doc']);
    expect(doc.title, '여행 계획');
    expect(doc.blocks.map((x) => x.t), ['p', 'table', 'math'], reason: 'empty last paragraph dropped, divider undone');
    expect(doc.blocks[1].rows.first, ['날짜', '장소', '', ''], reason: '3 columns + 1 added');
    expect(doc.blocks[2].text, r'\frac{1}{2}');
    // The bubble draws the whole short post.
    expect(find.text('여행 계획'), findsWidgets);
    expect(find.byKey(const Key('doc-table-scroll')), findsWidgets);
    expect(find.byKey(const Key('article-read')), findsNothing, reason: 'short: no read-all button');
  });

  testWidgets('style menu, list typing and AI tidy', (t) async {
    final (_, b, team) = await start(t);
    await openEditor(t);
    await t.enterText(find.byKey(const Key('article-text-0')), '소제목');
    await tap(t, 'article-style');
    await tap(t, 'style-h2');
    expect(find.byKey(const Key('article-text-0')), findsOneWidget);
    await tap(t, 'article-plus');
    await tap(t, 'insert-ol');
    await t.enterText(find.byKey(const Key('article-item-1-0')), '하나\n둘');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('article-item-1-1')), findsOneWidget, reason: 'a line break starts the next item');
    // Typed marks in a paragraph → AI 도우미 > 자동 정리.
    await tap(t, 'article-plus');
    await tap(t, 'insert-quote');
    await tap(t, 'article-style');
    await tap(t, 'style-p');
    await t.enterText(find.byKey(const Key('article-text-2')), '# 큰 제목\n- 사과\n- 배');
    await t.pump();
    await tap(t, 'article-ai');
    await tap(t, 'ai-tidy');
    // AI writing without the on-device module: says so, changes nothing.
    ArticleAi.rewrite = null;
    LocalAi.engine = _NoAi();
    LocalAi.reset();
    addTearDown(() => LocalAi.engine = PhoneAi());
    await tap(t, 'article-ai');
    await tap(t, 'ai-polish');
    expect(find.byKey(const Key('article-note')), findsOneWidget);
    await tap(t, 'article-send');
    final doc = Doc.fromJson(b.rooms[team]!.lastWhere((m) => m.kind == 'card').card!.data['doc']);
    expect(doc.blocks.map((x) => x.t), ['h2', 'ol', 'h1', 'ul']);
    expect(doc.blocks[1].items, ['하나', '둘']);
    expect(doc.blocks[3].items, ['사과', '배']);
  });

  testWidgets('AI rewrite uses the on-device module when there is one', (t) async {
    final (_, b, team) = await start(t);
    ArticleAi.rewrite = (text, style) async => style == 'shorter' ? '짧게: $text' : null;
    addTearDown(() => ArticleAi.rewrite = null);
    await openEditor(t);
    await t.enterText(find.byKey(const Key('article-text-0')), '긴 문장');
    await t.pump();
    await tap(t, 'article-ai');
    await tap(t, 'ai-shorter');
    await tap(t, 'article-send');
    final doc = Doc.fromJson(b.rooms[team]!.lastWhere((m) => m.kind == 'card').card!.data['doc']);
    expect(doc.blocks.single.text, '짧게: 긴 문장');
  });

  testWidgets('photos are uploaded encrypted, with a caption', (t) async {
    final (_, b, team) = await start(t);
    ArticleEditorTest.picker = () async => [('image/png', png)];
    addTearDown(() => ArticleEditorTest.picker = null);
    await openEditor(t);
    await t.enterText(find.byKey(const Key('article-text-0')), '사진 한 장');
    await tap(t, 'article-photo');
    await t.enterText(find.byKey(const Key('article-caption-1')), '바다');
    await t.pump();
    await tap(t, 'article-send');
    final doc = Doc.fromJson(b.rooms[team]!.lastWhere((m) => m.kind == 'card').card!.data['doc']);
    final img = doc.blocks.firstWhere((x) => x.t == 'img');
    expect(img.file?['url'], startsWith('mxc://'));
    expect(img.text, '바다');
    expect(img.w, 1);
    expect(b.blobs.values.any((v) => v.length == png.length), isTrue, reason: 'uploaded (encrypted on a real phone)');
  });

  testWidgets('long post: preview in the bubble, read all on its own page', (t) async {
    final (s, b, team) = await start(t);
    await b.sendArticle(
      team,
      Doc(
        title: '아주 긴 글',
        blocks: [for (var i = 0; i < 40; i++) DocBlock('p', text: '문단 $i ${'내용' * 200}')],
      ).toJson(),
    );
    await s.refresh();
    await t.pump(const Duration(seconds: 31));
    await t.pumpAndSettle();
    expect(find.text('아주 긴 글'), findsWidgets);
    expect(find.byKey(const Key('article-read')), findsOneWidget);
    await tap(t, 'article-read');
    expect(find.byKey(const Key('article-page')), findsOneWidget);
    final page = find.descendant(of: find.byKey(const Key('article-page')), matching: find.byType(Scrollable)).first;
    await t.scrollUntilVisible(find.textContaining('문단 39'), 600, scrollable: page);
    await t.scrollUntilVisible(find.textContaining('끝까지 암호화된 글이에요'), 300, scrollable: page);
    expect(find.textContaining('끝까지 암호화된 글이에요'), findsOneWidget);
  });

  testWidgets('long text in the chat box opens in the editor', (t) async {
    final (_, b, team) = await start(t);
    expect(find.byKey(const Key('composer-expand')), findsNothing);
    await t.enterText(find.byKey(const Key('composer')), '# 공지\n- 회의 3시\n- 장소 2층');
    await t.pump();
    await tap(t, 'composer-expand');
    expect(find.byKey(const Key('article-editor')), findsOneWidget);
    await tap(t, 'article-send');
    final doc = Doc.fromJson(b.rooms[team]!.lastWhere((m) => m.kind == 'card').card!.data['doc']);
    expect(doc.blocks.map((x) => x.t), ['h1', 'ul']);
    final box = t.widget<CupertinoTextField>(find.byKey(const Key('composer')));
    expect(box.controller!.text, isEmpty, reason: 'sent, so the chat box is cleared');
  });

  testWidgets('closing with words asks to keep a draft', (t) async {
    final (s, _, team) = await start(t);
    await openEditor(t);
    await t.enterText(find.byKey(const Key('article-text-0')), '나중에 이어 쓸 글');
    await t.pump();
    await tap(t, 'article-close');
    await tap(t, 'article-keep');
    expect(s.settings[ArticleEditor.draftKey(team)], contains('나중에 이어 쓸 글'));
    await openEditor(t);
    expect(find.text('나중에 이어 쓸 글'), findsOneWidget);
  });
}

/// A phone without the built-in model.
class _NoAi implements AiEngine {
  @override
  Future<AiStatus> status() async => AiStatus.unsupported;

  @override
  Future<String> run({required String rules, required String text}) => throw const AiError('unsupported');
}
