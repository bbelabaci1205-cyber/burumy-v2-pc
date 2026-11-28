// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 긴 글 (2026-11-27): iPhone-size screenshots of a formatted message, a
// long post bubble, the reading page and the editor, for comparing with
// the Telegram 573 / 571 videos.
import 'dart:convert';
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/doc.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/article.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  final home = Platform.environment['HOME'];
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    // Code/formula fields use the phone's monospace font (tests have none).
    const mono = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf';
    if (File(mono).existsSync()) await loadFont('monospace', [mono]);
    final k = '$home/.pub-cache/hosted/pub.dev/flutter_math_fork-0.7.4/lib/katex_fonts/fonts';
    for (final (fam, files) in [
      ('KaTeX_Main', ['Regular', 'Italic', 'Bold', 'BoldItalic']),
      ('KaTeX_Math', ['Italic', 'BoldItalic']),
      ('KaTeX_AMS', ['Regular']),
      ('KaTeX_Size1', ['Regular']),
      ('KaTeX_Size2', ['Regular']),
      ('KaTeX_Size3', ['Regular']),
      ('KaTeX_Size4', ['Regular']),
    ]) {
      await loadFont('packages/flutter_math_fork/$fam', [for (final f in files) if (File('$k/$fam-$f.ttf').existsSync()) '$k/$fam-$f.ttf']);
    }
  });

  Future<(AppState, FakeBackend, String)> start(WidgetTester t, {bool dark = false}) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    if (dark) t.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
    final team = await b.createGroup('여행 모임', ['@mina:test']);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    return (s, b, team);
  }

  Msg post(String id, Map<String, Object?> data, {String sender = '@mina:test', bool mine = false}) =>
      Msg(id: id, sender: sender, body: articleBody(data), time: DateTime(2026, 11, 27, 9, 41), mine: mine, kind: 'card', card: CardInfo(kind: 'article', data: data));

  Future<void> openChat(WidgetTester t, AppState s, String name) async {
    await s.refresh();
    await t.pumpAndSettle();
    await t.tap(find.text(name).first);
    await t.pumpAndSettle();
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/$name.png'));
  }

  testWidgets('shots: formatted message (table, formulas, list)', (t) async {
    final (s, b, team) = await start(t);
    b.rooms[team]!.add(post('g1', {'doc': demoStudyGuide(true)}));
    await openChat(t, s, '여행 모임');
    await shot(t, 'ko_40_article_formatted');
  });

  testWidgets('shots: long post bubble + my short post', (t) async {
    final (s, b, team) = await start(t);
    b.rooms[team]!.add(post('l1', demoLongArticle(b, true)));
    await b.sendArticle(team, Doc(title: '모임 공지', blocks: [DocBlock('p', text: '토요일 **10시** 역 앞에서 만나요.'), DocBlock('ul', items: ['물', '모자', '선크림'])]).toJson());
    await openChat(t, s, '여행 모임');
    await shot(t, 'ko_41_article_bubbles');
    await t.tap(find.byKey(const Key('article-read')));
    await t.pumpAndSettle();
    await shot(t, 'ko_42_article_page');
  });

  testWidgets('shots: reading page with a photo (dark)', (t) async {
    final (s, b, team) = await start(t, dark: true);
    final photo = File('test/assets/article_photo.jpg').readAsBytesSync();
    final file = await b.uploadEncrypted(photo);
    final long = Doc.fromJson(demoLongArticle(b, true)['preview']);
    final d = Doc(title: '아랍에미리트 여행 가이드', blocks: [
      DocBlock('p', text: '미래 도시 같은 스카이라인부터 오래된 마을까지, 아랍에미리트는 새것과 옛것이 함께 있는 곳이에요.'),
      DocBlock('img', file: Doc.cleanFile(jsonDecode(file)), mime: 'image/jpeg', w: 1200, h: 800, text: '두바이 마리나의 저녁'),
      ...long.blocks.skip(1),
    ]);
    final id = await b.sendArticle(team, d.toJson());
    await openChat(t, s, '여행 모임');
    final m = b.rooms[team]!.firstWhere((m) => m.id == id);
    Navigator.of(t.element(find.byKey(const Key('composer')))).push(IosPageRoute(builder: (_) => ArticlePage(roomId: team, msg: m)));
    await t.pumpAndSettle();
    await shot(t, 'ko_43_article_page_dark');
  });

  testWidgets('shots: editor with table and formula, style menu', (t) async {
    final (s, _, team) = await start(t);
    await openChat(t, s, '여행 모임');
    Navigator.of(t.element(find.byKey(const Key('composer')))).push(IosPageRoute(fullscreenDialog: true, builder: (_) => ArticleEditor(roomId: team)));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('article-title')), '아랍에미리트 여행');
    await t.enterText(find.byKey(const Key('article-text-0')), '미래 도시 같은 스카이라인부터 오래된 마을까지 둘러봐요.');
    await t.pump();
    await t.tap(find.byKey(const Key('article-table')));
    await t.pumpAndSettle();
    for (final (r, c, v) in [(0, 0, '시기'), (0, 1, '날씨'), (0, 2, '추천'), (1, 0, '11월–3월'), (1, 1, '선선함'), (1, 2, '여행 최고'), (2, 0, '6월–9월'), (2, 1, '아주 더움'), (2, 2, '실내 위주')]) {
      await t.enterText(find.byKey(Key('article-cell-1-$r-$c')), v);
    }
    await t.tap(find.byKey(const Key('article-plus')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('insert-math')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('article-text-2')), r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}');
    await t.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await shot(t, 'ko_44_article_editor');
    await t.tap(find.byKey(const Key('article-style')));
    await t.pumpAndSettle();
    await shot(t, 'ko_45_article_style_menu');
  });
}
