// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story stickers (tip 467) at iPhone size (393 × 852), for checking the
// look. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/core/story_weather.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/sticker_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/story_more.dart';
import 'package:burumy/ui/story_stickers.dart';
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
    WeatherSticker.debugStill = true;
    // Noon in Seoul, night in London; same moon every run.
    stickerClock = () => DateTime.utc(2026, 11, 27, 3);
    Phone.debugLocation = () async => const GeoFix(37.5665, 126.9780, 30);
  });

  testWidgets('every sky, day and night', (t) async {
    t.view.physicalSize = const Size(393 * 2, 520 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    Widget cell(String sky, bool night, int look, double moon) => StorySticker(
      item: StoryLive(kind: 'weather', sky: sky, night: night, celsius: 19, moon: moon, look: look),
      fahrenheit: false,
    );
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
    await t.pumpWidget(
      AppScope(
        state: s,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Pretendard'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF5AC8FA), Color(0xFF6155F5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              ),
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final sky in weatherSkies) cell(sky, false, 0, 0),
                  cell('clear', true, 1, .12),
                  cell('clear', true, 1, .3),
                  cell('clear', true, 1, .5),
                  cell('clear', true, 2, .72),
                  cell('partly', true, 1, .5),
                  cell('rain', false, 2, 0),
                  cell('snow', false, 1, 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await expectLater(find.byType(Container).first, matchesGoldenFile('shots/stk_0_skies.png'));
  });

  testWidgets('sticker screens', (t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final photo = File('test/assets/sample_photo.png').readAsBytesSync();
    final b = demoSample(true, photo);
    b.rooms['!photos'] = [];
    b.names['!photos'] = '정다은';
    b.peers['!photos'] = '@daeun:test';
    addStickerSample(b, true, photo);
    final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await s.setPref('temp_unit', 'c');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    Future<void> shot(String name) async {
      await t.pump(const Duration(milliseconds: 400));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump(const Duration(milliseconds: 400));
      await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/stk_$name.png'));
    }

    Navigator.of(
      t.element(find.byKey(const Key('stories-bar'))),
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.png', photo))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await shot('1_sheet');
    await t.tap(find.byKey(const Key('story-live-weather')));
    await t.pumpAndSettle();
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700)));
    await t.pumpAndSettle();
    await shot('2_weather_page');
    await t.tap(find.byKey(const Key('weather-done')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-place')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('place-name')), '성수동 카페거리');
    await t.pump();
    await shot('3_place_page');
    await t.tap(find.byKey(const Key('place-done')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-link')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('link-url')), 'https://burumy.app');
    await t.pump(const Duration(milliseconds: 800));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await t.pumpAndSettle();
    await shot('4_link_page');
    await t.tap(find.byKey(const Key('link-done')));
    await t.pumpAndSettle();
    await shot('5_editor');
  });

  testWidgets('sticker viewer', (t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final photo = File('test/assets/sample_photo.png').readAsBytesSync();
    final b = demoSample(true, photo);
    b.rooms['!photos'] = [];
    b.names['!photos'] = '정다은';
    b.peers['!photos'] = '@daeun:test';
    addStickerSample(b, true, photo);
    final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await s.setPref('temp_unit', 'c');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    Future<void> shot(String name) async {
      await t.pump(const Duration(milliseconds: 400));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await t.pump(const Duration(milliseconds: 400));
      await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/stk_$name.png'));
    }

    // Leo's story as a friend sees it; then Daeun's night story; link sheet.
    final ctx = t.element(find.byKey(const Key('stories-bar')));
    final leo = b.storyList.firstWhere((x) => x.id == 'st-stickers');
    final moon = b.storyList.firstWhere((x) => x.id == 'st-moon');
    // ignore: unawaited_futures
    openStories(ctx, [
      [leo],
    ], 0);
    await shot('6_viewer');
    await t.tap(find.byKey(const Key('story-sticker-st-stickers-2')));
    await shot('7_link_sheet');
    await t.tapAt(const Offset(200, 60));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('story-sticker-st-stickers-1')));
    await shot('8_place_sheet');
    await t.tapAt(const Offset(200, 60));
    await t.pump(const Duration(milliseconds: 400));
    Navigator.of(t.element(find.byKey(const Key('story-sticker-st-stickers-0'))), rootNavigator: true).pop();
    await t.pump(const Duration(milliseconds: 400));
    // ignore: unawaited_futures
    openStories(ctx, [
      [moon],
    ], 0);
    await shot('9_night');
    StoryWeather.debugFetch = null;
  });
}
