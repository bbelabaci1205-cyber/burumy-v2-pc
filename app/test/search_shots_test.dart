// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 전체 검색 + 해시태그 screens at iPhone size (393 × 852) for checking
// against iOS 27 / Telegram. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/search_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:burumy/ui/hashtag_page.dart';
import 'package:burumy/ui/search_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  setUpAll(() async {
    Features.search = true;
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('CupertinoSystemDisplay', ['assets/fonts/Pretendard-Regular.otf']);
  });

  for (final dark in [false, true]) {
    testWidgets('search screens ${dark ? 'dark' : 'light'}', (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final photo = File('test/assets/sample_photo.png').readAsBytesSync();
      final b = demoSample(true, photo);
      addSearchSample(b, true, photo, at: DateTime(2026, 11, 27, 9, 41));
      final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
      await s.backend.login(id: 'me', password: 'x');
      await s.refresh();
      await s.setPref(Night.key, dark ? 'dark' : 'light');
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      final tag = dark ? 'dark' : 'light';
      Future<void> snap(String name) async {
        await t.pumpAndSettle();
        await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/search_${tag}_$name.png'));
      }

      Future<void> tab(String id) async {
        if (find.byKey(Key('tab-$id')).evaluate().isEmpty) {
          await t.drag(find.byKey(const Key('search-tabs')), const Offset(800, 0));
          await t.pumpAndSettle();
        }
        await t.ensureVisible(find.byKey(Key('tab-$id')));
        await t.tap(find.byKey(Key('tab-$id')));
        await t.pumpAndSettle();
      }

      nav.push(CupertinoPageRoute(builder: (_) => const SearchPage()));
      await t.pumpAndSettle();
      await snap('1_recent');
      await t.enterText(find.byKey(const Key('search-input')), '부산');
      await t.pump(const Duration(milliseconds: 300));
      await snap('2_chats');
      await tab('channels');
      await snap('3_channels');
      await tab('posts');
      await snap('4_posts');
      await tab('media');
      await snap('5_media');
      await t.enterText(find.byKey(const Key('search-input')), '');
      await t.pump(const Duration(milliseconds: 300));
      await tab('link');
      await snap('6_links');
      await tab('file');
      await snap('7_files');
      await tab('music');
      await snap('8_music');
      await tab('voice');
      await snap('9_voice');
      await tab('chats');
      await t.enterText(find.byKey(const Key('search-input')), '11월 여행');
      await t.pump(const Duration(milliseconds: 300));
      await snap('10_date_chips');
      nav.pop();
      await t.pumpAndSettle();
      nav.push(CupertinoPageRoute(builder: (_) => ChatPage(roomId: '!trip', title: b.names['!trip']!)));
      await snap('11_tags_in_chat');
      nav.pop();
      await t.pumpAndSettle();
      nav.push(CupertinoPageRoute(builder: (_) => const HashtagPage(tag: '여행', roomId: '!trip')));
      await snap('12_tag_list');
      await t.tap(find.byKey(const Key('tag-view')));
      await snap('13_tag_chat');
      await t.tap(find.byKey(const Key('tag-scope-mine')));
      await snap('14_tag_mine');
      await t.tap(find.byKey(const Key('tag-scope-public')));
      await snap('15_tag_public');
      nav.pop();
      await t.pumpAndSettle();
      nav.push(CupertinoPageRoute(builder: (_) => const HashtagPage(tag: '부산', address: 'busan_food')));
      await snap('16_tag_other_chat');
      nav.pop();
      await t.pumpAndSettle();
      nav.push(CupertinoPageRoute(builder: (_) => const HashtagPage(tag: '부산')));
      await snap('17_tag_grid');
    });
  }
}
