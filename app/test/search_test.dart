// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 전체 검색 + 해시태그 (Telegram tips 500 · 189 · 248 · 533 · 444 · 454 ·
// 484 · 459, 2026-11-27).
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/search.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/search_sample.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/chat_list_page.dart';
import 'package:burumy/ui/hashtag_page.dart';
import 'package:burumy/ui/search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Msg _m(String id, String kind, String body, {String? caption, bool once = false, VoiceInfo? voice, DateTime? at}) =>
    Msg(id: id, sender: '@a:test', body: body, time: at ?? DateTime(2026, 11, 1), mine: false, kind: kind, caption: caption, viewOnce: once, voice: voice);

void main() {
  setUp(() => Features.search = true);
  tearDown(() => Features.search = false);

  test('hashtags: words in any language, #tag@address, not in links or C#', () {
    final h = findHashtags('가을 #여행 갔어요 #travel@Adventures, #2026 #부산_맛집! https://a.b/#frag C# &#39;');
    expect([for (final x in h) x.text], ['#여행', '#travel@adventures', '#부산_맛집']);
    expect(h[1].tag, 'travel');
    expect(h[1].address, 'adventures');
    expect(hasHashtag('Go #Future now', 'future'), isTrue);
    expect(hasHashtag('#futures', 'future'), isFalse, reason: 'whole tag only');
    expect(hasHashtag('#travel@trip_diary', 'travel'), isTrue);
    expect(parseHashtag('#여행@trip_diary'), ('여행', 'trip_diary'));
    expect(parseHashtag('여행'), ('여행', null));
  });

  test('kinds: same rules as the engine (photos, links, files, music, voice)', () {
    expect(searchHit(_m('1', 'text', 'see https://x.y'), 'link', ''), isTrue);
    expect(searchHit(_m('2', 'text', 'hello'), 'link', ''), isFalse);
    expect(searchHit(_m('3', 'file', 'plan.pdf'), 'file', 'plan'), isTrue);
    expect(searchHit(_m('4', 'file', 'song.MP3'), 'file', ''), isFalse);
    expect(searchHit(_m('4', 'file', 'song.MP3'), 'music', ''), isTrue);
    expect(searchHit(_m('5', 'audio', 'v.ogg', voice: const VoiceInfo(Duration(seconds: 3), [])), 'voice', ''), isTrue);
    expect(searchHit(_m('5', 'audio', 'v.ogg', voice: const VoiceInfo(Duration(seconds: 3), [])), 'music', ''), isFalse);
    expect(searchHit(_m('6', 'image', 'a.jpg', caption: '해운대'), 'text', '해운대'), isTrue, reason: 'captions are searched');
    expect(searchHit(_m('7', 'image', 'a.jpg', once: true), 'media', ''), isFalse, reason: 'view-once never shows');
    expect(searchHit(_m('8', 'text', 'hi'), 'text', ''), isFalse);
  });

  test('date chips: 10월, October, 2025년, 2025 10월', () {
    final now = DateTime(2026, 11, 27);
    final (oct, rest) = dateChips('10월 여행', now);
    expect([for (final c in oct) c.id], ['2026-10', '2025-10', '2024-10']);
    expect(rest, '여행');
    final (dec, _) = dateChips('december', now);
    expect(dec.first.id, '2025-12', reason: 'no future months');
    expect(dateChips('2025년', now).$1.single.id, '2025');
    expect(dateChips('2025년 10월', now).$1.single.id, '2025-10');
    expect(dateChips('oct 2024', now).$1.single.id, '2024-10');
    expect(dateChips('ma', now).$1, isEmpty);
    expect(dateChips('부산', now).$1, isEmpty);
    expect(oct.first.has(DateTime(2026, 10, 31, 23)), isTrue);
    expect(oct.first.has(DateTime(2026, 11, 1)), isFalse);
  });

  test('recent searches: newest first, no repeats, 20 at most', () {
    var s = '';
    for (var i = 0; i < 25; i++) {
      s = addRecentSearch(s, 'chat:$i');
    }
    s = addRecentSearch(s, 'chat:10');
    final r = recentSearches(s);
    expect(r.length, 20);
    expect(r.first, 'chat:10');
    expect(r.where((x) => x == 'chat:10').length, 1);
  });

  test('around the match: long text starts near the found word', () {
    final t = '${'아주 긴 앞부분 ' * 10}부산 바다';
    expect(aroundMatch(t, '부산').startsWith('…'), isTrue);
    expect(aroundMatch(t, '부산'), contains('부산'));
    expect(aroundMatch('짧은 글 부산', '부산'), '짧은 글 부산');
  });

  group('demo backend', () {
    late FakeBackend b;
    setUp(() async {
      b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
      addSearchSample(b, true, File('test/assets/sample_photo.png').readAsBytesSync());
      await b.login(id: 'me', password: 'x');
    });

    test('searches every chat, hidden chats never', () async {
      final hits = await b.searchEverywhere('부산');
      expect(hits.map((f) => f.roomId).toSet(), containsAll(['!trip', '!r0']));
      // The delete / hide passwords' hide list keeps a chat out.
      b.hideOn = true;
      b.role = 'normal';
      b.hideList.add('!trip');
      final after = await b.searchEverywhere('부산');
      expect(after.any((f) => f.roomId == '!trip'), isFalse);
    });

    test('kinds across chats', () async {
      expect((await b.searchEverywhere('', kind: 'music')).single.msg.id, 'sr4');
      expect((await b.searchEverywhere('', kind: 'voice')).map((f) => f.msg.id), contains('sr5'));
      expect((await b.searchEverywhere('', kind: 'link')).map((f) => f.msg.id), contains('sr2'));
      expect((await b.searchEverywhere('부산', kind: 'media')).map((f) => f.msg.id), containsAll(['tr2', 'sr6']));
    });

    test('public rooms and posts', () async {
      final rooms = await b.searchPublicRooms('부산');
      expect(rooms.first.address, 'travel_korea', reason: 'bigger first');
      expect((await b.searchPublicRooms('부산', channelsOnly: true)).any((r) => r.address == 'busan_walk'), isFalse);
      expect((await b.searchPublicPosts('부산 냉면')).isEmpty, isTrue);
      expect((await b.searchPublicPosts('#부산')).single.address, 'busan_food');
      expect(await b.searchPublicPosts('a'), isEmpty, reason: 'two letters at least');
    });
  });

  Widget wrap(AppState s, Widget child) => AppScope(
    state: s,
    child: CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );

  Future<AppState> app() async {
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    addSearchSample(b, true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await s.refresh();
    return s;
  }

  testWidgets('search screen: chats, global, messages with filter, tabs', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = await app();
    await t.pumpWidget(wrap(s, const SearchPage()));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-recent')), findsOneWidget);
    await t.enterText(find.byKey(const Key('search-input')), '부산');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-public-busan_food')), findsOneWidget);
    expect(find.byKey(const Key('search-msg-sr1')), findsOneWidget);
    expect(find.byKey(const Key('search-msg-tr3')), findsOneWidget);
    // 메시지 filter: channels only.
    await t.tap(find.byKey(const Key('search-scope')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('search-scope-channel')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-msg-sr1')), findsNothing);
    expect(find.byKey(const Key('search-msg-tr3')), findsOneWidget);
    // 채널 tab: my channel + public channels (not the group).
    await t.tap(find.byKey(const Key('tab-channels')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-channel-!trip')), findsNothing, reason: '"부산" is not in its name');
    expect(find.byKey(const Key('search-public-travel_korea')), findsOneWidget);
    expect(find.byKey(const Key('search-public-busan_walk')), findsNothing);
    // 글 tab: my channel's posts + public posts.
    await t.tap(find.byKey(const Key('tab-posts')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-msg-tr3')), findsOneWidget);
    expect(find.byKey(const Key('search-posts-note')), findsOneWidget);
    // 미디어 / 파일 / 음악.
    await t.ensureVisible(find.byKey(const Key('tab-media')));
    await t.tap(find.byKey(const Key('tab-media')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-media-sr6')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('tab-file')));
    await t.tap(find.byKey(const Key('tab-file')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-file-sr3')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('tab-music')));
    await t.tap(find.byKey(const Key('tab-music')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-music-sr4')), findsNothing, reason: 'its name has no 부산');
  });

  testWidgets('date chip narrows messages to that month', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = await app();
    await t.pumpWidget(wrap(s, const SearchPage()));
    await t.pumpAndSettle();
    final now = DateTime.now();
    final month = now.subtract(const Duration(days: 20));
    await t.enterText(find.byKey(const Key('search-input')), '${month.month}월 여행');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-date-chips')), findsOneWidget);
    await t.tap(find.byKey(Key('date-chip-${month.year}-${month.month}')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('search-msg-tr1')), findsOneWidget);
  });

  testWidgets('hashtag page: this chat / my messages / public, chat view, stories', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = await app();
    await t.pumpWidget(wrap(s, const HashtagPage(tag: '여행', roomId: '!trip')));
    await t.pumpAndSettle();
    // 이 대화: the channel's 4 posts with #여행 (tr2 has a caption).
    expect(find.byKey(const Key('tag-msg-tr1')), findsOneWidget);
    expect(find.byKey(const Key('tag-msg-sr1')), findsNothing);
    expect(find.byKey(const Key('tag-stories')), findsOneWidget, reason: "mina's story has #여행");
    await t.tap(find.byKey(const Key('tag-view')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tag-bubbles')), findsOneWidget);
    await t.tap(find.byKey(const Key('tag-scope-mine')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tag-bubble-sr1')), findsOneWidget);
    await t.tap(find.byKey(const Key('tag-scope-public')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tag-public')), findsOneWidget);
    expect(find.textContaining('겨울 부산 여행', findRichText: true), findsOneWidget);
  });

  testWidgets('#tag@address of a chat I am not in shows a join card', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = await app();
    await t.pumpWidget(wrap(s, const HashtagPage(tag: '부산', address: 'busan_food')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tag-join-card')), findsOneWidget);
    expect(find.byKey(const Key('tag-join')), findsOneWidget);
  });

  testWidgets('list search opens the search screen when the switch is on', (t) async {
    final s = await app();
    await t.pumpWidget(wrap(s, const SearchCapsule(hint: '검색', onChanged: _no, onOpen: _open)));
    await t.tap(find.byKey(const Key('list-search-open')));
    expect(opened, 1);
  });
}

int opened = 0;
void _no(String _) {}
void _open() => opened++;
