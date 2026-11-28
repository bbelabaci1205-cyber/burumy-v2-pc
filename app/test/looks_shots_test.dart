// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 테마·배경·꾸미기 screens (tip batches #21 + #24) at iPhone size (393 × 852),
// for checking against iOS / Telegram. The demo chats carry times from "now",
// so these are pictures to look at, not a check: run with LOOK_SHOTS=1 and
// --update-goldens to make them again.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/looks.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/demo/look_sample.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:burumy/ui/look_studio.dart';
import 'package:burumy/ui/profile_page.dart';
import 'package:burumy/ui/settings_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  setUpAll(() async {
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
    RoomLookLevels.on = false;
  });

  for (final dark in [false, true]) {
    testWidgets('looks screens ${dark ? 'dark' : 'light'}', skip: !Platform.environment.containsKey('LOOK_SHOTS'), (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
      addLookSample(b, true);
      final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      // The demo's saved settings (the app loads them when logging in).
      for (final e in Map.of(b.prefs).entries) {
        await s.setPref(e.key, e.value);
      }
      await s.setPref(Night.key, dark ? 'dark' : 'light');
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      final tag = dark ? 'dark' : 'light';
      Future<void> shot(String name, Widget page, {Future<void> Function()? then, bool settle = true}) async {
        nav.push(CupertinoPageRoute(builder: (_) => page));
        if (settle) {
          await t.pumpAndSettle();
        } else {
          for (var i = 0; i < 15; i++) {
            await t.pump(const Duration(milliseconds: 200));
          }
        }
        await then?.call();
        await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/looks_${tag}_$name.png'));
        nav.pop();
        if (settle) {
          await t.pumpAndSettle();
        } else {
          for (var i = 0; i < 10; i++) {
            await t.pump(const Duration(milliseconds: 200));
          }
        }
      }

      await shot('01_appearance', const AppearancePage());
      await shot(
        '02_accent_purple',
        const AppearancePage(),
        then: () async {
          await t.tap(find.byKey(const Key('accent-purple')));
          await t.pumpAndSettle();
        },
      );
      s.setFamily(BrandFamily.green);
      await shot('03_all_backgrounds', const AllBackgroundsPage());
      await shot('04_pick_background', const WallpaperPage());
      await shot(
        '05_preview',
        WallPreviewPage(
          specs: [
            Wall.gradSpec('peach', pattern: 'hearts'),
            'secure',
          ],
        ),
      );
      await shot('06_mix', const GradientMakerPage());
      await shot('07_theme_maker', const ThemeMakerPage());
      await shot('08_chat_jisu', const ChatPage(roomId: '!look_jisu', title: '지수'), settle: false);
      await shot('09_theme_link', ThemeLinkPage(theme: MyTheme.parseLink(b.rooms['!look_jisu']![1].body!)!));
      await s.setPref('name_color', 'orange+yellow|stars|blue+purple|music');
      await shot('10_person_look', const PersonLookPage());
      await shot('11_info_jisu', const ChatInfoPage(roomId: '!look_jisu', title: '지수', isGroup: false, isChannel: false), settle: false);
      await shot('12_chat_book', const ChatPage(roomId: '!look_book', title: '독서 모임'), settle: false);
      await shot('13_info_book', const ChatInfoPage(roomId: '!look_book', title: '독서 모임', isGroup: true, isChannel: false), settle: false);
      await shot(
        '14_room_look',
        RoomLookPage(roomId: '!look_book', title: '독서 모임', channel: false, start: RoomLook.from(b.roomConfigs['!look_book']!)),
        settle: false,
      );
      await shot('15_solid', const SolidColorsPage(target: WallTarget()));
    });
  }
}
