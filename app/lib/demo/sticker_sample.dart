// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): story stickers from tip 467.
// - Leo's new story: weather (Seoul), a place tag and a link card.
// - Daeun's story from London at night: the moon as it is tonight.
// - The weather "helper" answers with fixed examples per city, so every
//   sky can be tried by picking cities (서울 partly, 제주 rain, 삿포로 snow,
//   방콕 storm, 런던 fog, 도쿄 cloudy, 두바이 clear …).
import 'dart:typed_data';
import 'dart:ui' show Offset;

import '../core/backend.dart';
import '../core/story_weather.dart';
import '../ui/story_more.dart';
import '../ui/story_stickers.dart';
import 'demo_backend.dart';

const _examples = {
  'Seoul': (9.4, 'partly'),
  'Busan': (13.2, 'clear'),
  'Jeju': (14.1, 'rain'),
  'Seogwipo': (15.0, 'rain'),
  'Gangneung': (6.8, 'cloudy'),
  'Tokyo': (12.6, 'cloudy'),
  'Sapporo': (-3.2, 'snow'),
  'Bangkok': (31.4, 'storm'),
  'Singapore': (29.8, 'storm'),
  'London': (8.1, 'fog'),
  'Paris': (10.3, 'rain'),
  'Dubai': (28.7, 'clear'),
  'New York': (1.2, 'snow'),
  'Los Angeles': (19.5, 'clear'),
  'Sydney': (24.3, 'clear'),
};

/// Fixed weather for the look-only demo (no server): the nearest example
/// city, else a mild cloudy day.
Future<WeatherNow> demoWeather(double lat, double lon) async {
  await Future<void>.delayed(const Duration(milliseconds: 500));
  final c = nearestCity(lat, lon, withinKm: 60);
  final e = c == null ? null : _examples[c.en];
  if (e != null) return WeatherNow(e.$1, e.$2);
  final warm = lat.abs() < 23;
  return WeatherNow(warm ? 27 : 11, warm ? 'clear' : 'cloudy');
}

void addStickerSample(FakeBackend b, bool ko, Uint8List photo) {
  StoryWeather.debugFetch = demoWeather;
  final thumb = storyLinkThumb(photo);
  b.storyLinks['https://burumy.app'] = StoryLinkInfo(
    title: ko ? '부루미 — 친구끼리만 보는 메신저' : 'Burumy — the messenger for friends only',
    site: 'Burumy',
    image: photo,
  );
  final now = DateTime.now();
  final sky = stickerClock();
  final seoul = cities.first;
  final leo = encodeLive([
    StoryLive(
      kind: 'weather',
      at: const Offset(.5, .2),
      celsius: 9.4,
      sky: 'partly',
      night: isNight(sky, seoul.lat, seoul.lon),
      moon: moonPhase(sky),
      place: ko ? '서울' : 'Seoul',
    ),
    StoryLive(kind: 'place', q: ko ? '성수동 카페거리' : 'Seongsu café street', at: const Offset(.5, .62), lat: 37.54, lon: 127.06),
    StoryLive(
      kind: 'link',
      url: 'https://burumy.app',
      title: ko ? '부루미 — 친구끼리만 보는 메신저' : 'Burumy — the messenger for friends only',
      site: 'Burumy',
      img: thumb,
      card: true,
      at: const Offset(.5, .8),
    ),
  ]);
  b.files['st-stickers'] = photo;
  b.storyList.add(
    Story(
      id: 'st-stickers',
      roomId: '!r2',
      eventId: 'st-stickers',
      sender: '@leo:test',
      mine: false,
      time: now.subtract(const Duration(minutes: 8)),
      kind: 'image',
      extra: leo,
    ),
  );
  final daeun = encodeLive([
    StoryLive(kind: 'weather', at: const Offset(.5, .3), celsius: 8.1, sky: 'clear', night: true, moon: moonPhase(sky), look: 1, place: ko ? '런던' : 'London'),
  ]);
  const room = '!photos';
  if (!b.rooms.containsKey(room)) return;
  b.files['st-moon'] = photo;
  b.storyList.add(
    Story(
      id: 'st-moon',
      roomId: room,
      eventId: 'st-moon',
      sender: '@daeun:test',
      mine: false,
      time: now.subtract(const Duration(minutes: 3)),
      kind: 'image',
      extra: daeun,
    ),
  );
}
