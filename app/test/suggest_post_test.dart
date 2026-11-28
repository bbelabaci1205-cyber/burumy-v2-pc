// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널에 글 제안 (tip 531, no money): subscriber suggests, admin publishes
// (now / later) or declines; iPhone-size (393x852) screenshots.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/suggest_post.dart';
import 'package:burumy/demo/suggest_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/suggest_post.dart';
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
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });
  final png = File('assets/demo/photo.png').readAsBytesSync();

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    await t.runAsync(() => addSuggestSample(b, true, photo: png, at: DateTime(2026, 11, 27, 15)));
    final s = AppState(b, locale: const Locale('ko'));
    return (b, s);
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/$name.png'));
  }

  Future<void> open(WidgetTester t, AppState s, String chat) async {
    await s.afterLogin();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text(chat));
    await t.pumpAndSettle();
  }

  testWidgets('subscriber suggests a post with a photo', (t) async {
    final (b, s) = await app(t);
    SuggestPostPage.debugPhoto = () async => ('image/png', png);
    addTearDown(() => SuggestPostPage.debugPhoto = null);
    await open(t, s, '맛집 탐방 · 관리자에게');
    expect(find.byKey(const Key('suggest-bar')), findsOneWidget);
    await shot(t, 'ko_s1_suggest_bar');
    await t.tap(find.byKey(const Key('suggest-open')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('suggest-text')), '을지로 노포 국밥집 후기예요. 국물이 진해요!');
    await t.tap(find.byKey(const Key('suggest-photo')));
    await t.pumpAndSettle();
    await shot(t, 'ko_s2_suggest_editor');
    await t.tap(find.byKey(const Key('suggest-send')));
    await t.pumpAndSettle();
    final card = (await b.timeline('!food_dm_me')).last;
    expect(card.card?.kind, 'suggest');
    expect(card.card!.text('channel'), '!food_ch');
    expect(card.card!.text('photo'), isNotEmpty);
    expect(find.byKey(const Key('suggest-waiting')), findsOneWidget);
    await shot(t, 'ko_s3_suggest_sent');
  });

  testWidgets('admin publishes now, with the name', (t) async {
    final (b, s) = await app(t);
    await open(t, s, '자연 사진 · 유리');
    await shot(t, 'ko_s4_suggest_admin');
    await t.tap(find.byKey(const Key('suggest-accept')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('suggest-when-now')));
    await t.pumpAndSettle();
    await shot(t, 'ko_s5_suggest_accept');
    await t.tap(find.byKey(const Key('suggest-accept-go')));
    await t.pumpAndSettle();
    final post = (await b.timeline('!nature')).last;
    expect(post.kind, 'image');
    expect(post.caption, contains('유리님이 제안했어요'));
    expect(find.byKey(const Key('suggest-accept')), findsNothing);
    await t.drag(find.byType(ListView).first, const Offset(0, -400));
    await t.pumpAndSettle();
    await shot(t, 'ko_s6_suggest_agreed');
  });

  testWidgets('admin keeps their time: waits on the phone, then posts', (t) async {
    final (b, s) = await app(t);
    await open(t, s, '자연 사진 · 유리');
    await t.tap(find.byKey(const Key('suggest-accept')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('suggest-when-theirs')), findsOneWidget);
    await t.tap(find.byKey(const Key('suggest-credit')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('suggest-accept-go')));
    await t.pumpAndSettle();
    expect(SuggestPost.due(s).length, 1);
    final before = (await b.timeline('!nature')).length;
    await t.runAsync(() => SuggestPost.run(s));
    expect((await b.timeline('!nature')).length, before);
    b.now = DateTime.now().add(const Duration(days: 3));
    await t.runAsync(() => SuggestPost.run(s));
    expect((await b.timeline('!nature')).length, before + 1);
    expect((await b.timeline('!nature')).last.caption, isNot(contains('제안했어요')));
    expect(SuggestPost.due(s), isEmpty);
  });

  testWidgets('admin declines with a reason', (t) async {
    final (b, s) = await app(t);
    await open(t, s, '자연 사진 · 유리');
    await t.tap(find.byKey(const Key('suggest-decline')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('suggest-note')), '이번 주는 캐나다 사진이 많아요');
    await t.tap(find.byKey(const Key('suggest-decline-go')));
    await t.pumpAndSettle();
    final deal = (await b.timeline('!nature_dm_yuri')).last;
    expect(deal.card?.kind, 'suggest_deal');
    expect(deal.card!.data['act'], 'decline');
    expect(find.textContaining('이번 주는 캐나다'), findsOneWidget);
  });
}
