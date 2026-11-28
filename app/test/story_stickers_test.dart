// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story stickers (Telegram tip 467): weather, place and link.
// - what travels inside the story, and that odd input from a friend's phone
//   is cut short or dropped;
// - the sky maths done on the phone (sun height, moon phase, °C/°F);
// - adding all three in the editor and sharing;
// - a friend's view: °C ⇄ °F tap, the place card, the link's real address
//   and the look-alike warning.
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/core/story_weather.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/story_more.dart';
import 'package:burumy/ui/story_stickers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  s.settings = await b.settings();
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  return (s, b);
}

void main() {
  setUp(() {
    WeatherSticker.debugStill = true;
    StoryWeather.clearCache();
    StoryWeather.debugFetch = (lat, lon) async => const WeatherNow(18.6, 'rain');
    Phone.debugLocation = () async => const GeoFix(37.5665, 126.9780, 30);
  });
  tearDown(() {
    StoryWeather.debugFetch = null;
    Phone.debugLocation = null;
  });

  test('stickers survive the trip; bad ones are cut or dropped', () {
    final x = encodeLive([
      StoryLive(kind: 'weather', celsius: 18.64, sky: 'storm', night: true, moon: .5, look: 1, place: '서울', at: const Offset(.4, .2)),
      StoryLive(kind: 'place', q: '성수동', lat: 37.54, lon: 127.06, look: 3),
      StoryLive(kind: 'link', url: 'https://burumy.app/a', q: '우리 앱', title: '부루미', site: 'Burumy', card: true, img: 'AAAA'),
    ]);
    final back = decodeLive(x);
    expect(back.map((e) => e.kind), ['weather', 'place', 'link']);
    expect(back[0].celsius, 18.6);
    expect(back[0].sky, 'storm');
    expect(back[0].night, isTrue);
    expect(back[0].moon, .5);
    expect(back[0].look, 1);
    expect(back[0].place, '서울');
    expect(back[1].lat, 37.54);
    expect(back[1].look, 3);
    expect(back[2].card, isTrue);
    expect(back[2].img, 'AAAA');
    // A friend's phone could send anything.
    final bad = decodeLive(
      '{"items":['
      '{"kind":"weather","t":"hot"},'
      '{"kind":"weather","t":999,"sky":"lava","look":9,"moon":7},'
      '{"kind":"place","q":"   "},'
      '{"kind":"place","q":"집","lat":500,"lon":1},'
      '{"kind":"link","url":"javascript:alert(1)"},'
      '{"kind":"link","url":"https://x.co","img":"<svg onload=x>"}'
      ']}',
    );
    expect(bad.map((e) => e.kind), ['weather', 'place', 'link']);
    expect(bad[0].celsius, 60);
    expect(bad[0].sky, 'cloudy');
    expect(bad[0].look, 2);
    expect(bad[0].moon, 1);
    expect(bad[1].lat, isNull);
    expect(bad[2].img, isEmpty);
  });

  test('sky maths on the phone', () {
    // Full moon 2024-01-25 17:54 UTC, new moon 2024-01-11 11:57 UTC.
    expect(moonPhase(DateTime.utc(2024, 1, 25, 17, 54)), closeTo(.5, .02));
    final n = moonPhase(DateTime.utc(2024, 1, 11, 11, 57));
    expect(n < .02 || n > .98, isTrue);
    expect(moonLit(.5), closeTo(1, .001));
    // Seoul: noon in June high sun, midnight dark.
    expect(sunHeight(DateTime.utc(2026, 6, 21, 3, 30), 37.57, 126.98), greaterThan(70));
    expect(isNight(DateTime.utc(2026, 6, 21, 15), 37.57, 126.98), isTrue);
    expect(isNight(DateTime.utc(2026, 11, 27, 3), 37.57, 126.98), isFalse);
    // Units by country, or the reader's own choice.
    expect(useFahrenheit('', const Locale('en', 'US')), isTrue);
    expect(useFahrenheit('', const Locale('ko', 'KR')), isFalse);
    expect(useFahrenheit('c', const Locale('en', 'US')), isFalse);
    expect(useFahrenheit('f', const Locale('ko', 'KR')), isTrue);
    expect(tempLabel(18.6, false), '19°C');
    expect(tempLabel(0, true), '32°F');
    expect(tempLabel(-3.4, false), '-3°C');
    // Blurred to 0.1° before it leaves the phone.
    expect(StoryWeather.blur(37.5665, 126.978), (37.6, 127.0));
    expect(nearestCity(37.55, 127.0)?.ko, '서울');
    expect(nearestCity(0, -140), isNull);
  });

  test('look-alike link names and the small card picture', () {
    expect(linkLooksElsewhere('naver.com', 'https://n4ver-login.xyz/a'), isTrue);
    expect(linkLooksElsewhere('naver.com', 'https://m.naver.com/x'), isFalse);
    expect(linkLooksElsewhere('www.Naver.com 로그인', 'https://naver.com'), isFalse);
    expect(linkLooksElsewhere('우리 가게 메뉴', 'https://x.com'), isFalse);
    final thumb = storyLinkThumb(File('test/assets/sample_photo.png').readAsBytesSync());
    expect(thumb, isNotEmpty);
    expect(thumb.length, lessThanOrEqualTo(15000));
    expect(storyLinkThumb(const [1, 2, 3]), isEmpty);
  });

  testWidgets('add weather, a place and a link, then share', (t) async {
    final (s, b) = await start(t);
    await s.setPref('temp_unit', 'c');
    b.storyLinks['https://burumy.app'] = StoryLinkInfo(title: '부루미', site: 'Burumy', image: File('test/assets/sample_photo.png').readAsBytesSync());
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    Navigator.of(
      t.element(find.byKey(const Key('stories-bar'))),
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.png', png))));
    await t.pumpAndSettle();

    // Weather: found for "where I am" (blurred), shown in °C here.
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-weather')));
    await t.pumpAndSettle();
    expect(find.text('19°C'), findsOneWidget);
    // MET Norway's data is CC BY 4.0: the credit sits under the sticker.
    expect(find.text('날씨 정보: MET Norway 자료 기반 (CC BY 4.0)'), findsOneWidget);
    await t.tap(find.byKey(const Key('weather-show-city')));
    await t.pump();
    expect(find.descendant(of: find.byType(WeatherSticker), matching: find.text('서울')), findsOneWidget);
    await t.tap(find.byKey(const Key('sticker-look-1')));
    await t.pump();
    await t.tap(find.byKey(const Key('weather-done')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-live-item-0')), findsOneWidget);

    // A city instead of my place: no location used at all.
    await t.tap(find.byKey(const Key('story-live-item-0')));
    await t.pumpAndSettle();
    StoryWeather.debugFetch = (lat, lon) async => WeatherNow(lat > 40 ? -3 : 25, lat > 40 ? 'snow' : 'clear');
    await t.enterText(find.byKey(const Key('weather-search')), '삿포로');
    await t.pump();
    await t.tap(find.byKey(const Key('weather-city-Sapporo')));
    await t.pumpAndSettle();
    expect(find.text('-3°C'), findsOneWidget);
    await t.tap(find.byKey(const Key('weather-done')));
    await t.pumpAndSettle();

    // Place: a name only.
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-place')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('place-done')), findsOneWidget);
    await t.enterText(find.byKey(const Key('place-name')), '성수동 카페거리');
    await t.pump();
    await t.tap(find.byKey(const Key('place-done')));
    await t.pumpAndSettle();

    // Link: my phone makes the card.
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-link')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('link-url')), 'burumy.app');
    await t.pump(const Duration(milliseconds: 800));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    expect(find.text('부루미'), findsWidgets);
    await t.tap(find.byKey(const Key('link-done')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-live-item-2')), findsOneWidget);

    await t.tap(find.byKey(const Key('story-share')));
    for (var i = 0; i < 30 && !b.storyList.last.mine; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 50));
    }
    final sent = decodeLive(b.storyList.last.extra);
    expect(sent.map((e) => e.kind), ['weather', 'place', 'link']);
    expect(sent[0].celsius, -3);
    expect(sent[0].sky, 'snow');
    expect(sent[0].place, '삿포로');
    expect(sent[0].look, 1);
    expect(sent[1].q, '성수동 카페거리');
    expect(sent[1].lat, isNull);
    expect(sent[2].url, 'https://burumy.app');
    expect(sent[2].title, '부루미');
    expect(sent[2].card, isTrue);
    expect(sent[2].img, isNotEmpty);
    // No place, coordinates or address of mine in the story.
    expect(b.storyList.last.extra, isNot(contains('37.5')));
  });

  testWidgets("a friend's stickers: °C/°F tap, place card, link address", (t) async {
    final (s, b) = await start(t);
    b.files['st-x'] = File('test/assets/sample_photo.png').readAsBytesSync();
    final story = Story(
      id: 'st-x',
      roomId: '!r2',
      eventId: 'st-x',
      sender: '@leo:test',
      mine: false,
      time: DateTime.now(),
      kind: 'image',
      extra: encodeLive([
        StoryLive(kind: 'weather', celsius: 20, sky: 'clear', at: const Offset(.5, .2)),
        StoryLive(kind: 'place', q: '한강 공원', lat: 37.52, lon: 126.93, at: const Offset(.5, .45)),
        StoryLive(kind: 'link', url: 'https://n4ver-login.xyz/a', q: 'naver.com', at: const Offset(.5, .7)),
      ]),
    );
    await s.setPref('temp_unit', 'c');
    final ctx = t.element(find.byKey(const Key('stories-bar')));
    // ignore: unawaited_futures
    openStories(ctx, [
      [story],
    ], 0);
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('20°C'), findsOneWidget);
    await t.tap(find.byKey(const Key('story-sticker-st-x-0')));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text('68°F'), findsOneWidget);
    expect(s.pref('temp_unit', ''), 'f');

    await t.tap(find.byKey(const Key('story-sticker-st-x-1')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('story-place-card')), findsOneWidget);
    expect(find.byKey(const Key('story-place-maps')), findsOneWidget);
    await t.tapAt(const Offset(200, 60));
    await t.pump(const Duration(milliseconds: 400));

    await t.tap(find.byKey(const Key('story-sticker-st-x-2')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('story-link-card')), findsOneWidget);
    expect(find.byKey(const Key('story-link-warning')), findsOneWidget);
    expect(find.textContaining('n4ver-login.xyz', findRichText: true), findsWidgets);
  });
}
