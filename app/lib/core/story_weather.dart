// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 날씨 스티커 (Telegram tip 467), the parts without screens:
// - asking OUR weather helper (server/weather) for "now" at a place blurred
//   to a 0.1° square (about 10 km). The weather company never sees the
//   person's phone or exact place; the story keeps only the temperature and
//   the sky (and a city name only when the person turns it on);
// - day or night and the moon's phase, worked out on the phone (no network);
// - °C or °F by the reader's country (tap the sticker to switch);
// - a small built-in city list, so the weather works without sharing any
//   location at all, and the nearest city's name can be shown.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:http/http.dart' as http;

/// Our weather helper (Caddy: /_weather/* → server/weather). Empty = none:
/// the sticker then offers no live weather.
const weatherServer = String.fromEnvironment('BURUMY_WEATHER');

/// The clock the stickers read (day or night, the moon). Tests pin it.
DateTime Function() stickerClock = DateTime.now;

/// The kinds of sky we draw.
const weatherSkies = ['clear', 'partly', 'cloudy', 'rain', 'storm', 'snow', 'fog'];

class WeatherNow {
  const WeatherNow(this.celsius, this.sky);
  final double celsius;
  final String sky;
}

/// Why weather couldn't be found.
class WeatherError implements Exception {
  const WeatherError(this.code);

  /// off (no helper in this build), network, location.
  final String code;
  @override
  String toString() => 'WeatherError($code)';
}

class StoryWeather {
  /// Tests and the look-only demo answer here instead of the helper.
  static Future<WeatherNow> Function(double lat, double lon)? debugFetch;

  /// Answers for 15 minutes per square, so moving between screens or adding
  /// a second sticker asks nobody.
  static final _cache = <String, (DateTime, WeatherNow)>{};

  static bool get available => debugFetch != null || weatherServer.isNotEmpty;

  /// The 0.1° square (≈10 km) a point is blurred to before it leaves the phone.
  static (double, double) blur(double lat, double lon) => ((lat * 10).round() / 10, (lon * 10).round() / 10);

  static Future<WeatherNow> now(double lat, double lon) async {
    final (a, b) = blur(lat, lon);
    final key = '$a,$b';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < const Duration(minutes: 15)) return hit.$2;
    final WeatherNow w;
    if (debugFetch != null) {
      w = await debugFetch!(a, b);
    } else {
      if (weatherServer.isEmpty) throw const WeatherError('off');
      try {
        final r = await http.get(Uri.parse('$weatherServer/_weather/v1/now?lat=$a&lon=$b')).timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) throw const WeatherError('network');
        final j = jsonDecode(r.body);
        final t = j is Map ? j['t'] : null;
        final sky = j is Map ? j['sky'] : null;
        if (t is! num || sky is! String || !weatherSkies.contains(sky)) throw const WeatherError('network');
        w = WeatherNow(t.toDouble().clamp(-90, 60).toDouble(), sky);
      } on WeatherError {
        rethrow;
      } catch (_) {
        throw const WeatherError('network');
      }
    }
    _cache[key] = (DateTime.now(), w);
    return w;
  }

  static void clearCache() => _cache.clear();
}

double _julian(DateTime t) => t.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;
double _rad(double d) => d * math.pi / 180;
double _deg(double r) => r * 180 / math.pi;

/// The sun's height above the horizon in degrees (good to ~1°).
double sunHeight(DateTime t, double lat, double lon) {
  final d = _julian(t) - 2451545.0;
  final g = _rad((357.529 + 0.98560028 * d) % 360);
  final q = (280.459 + 0.98564736 * d) % 360;
  final l = _rad(q + 1.915 * math.sin(g) + 0.020 * math.sin(2 * g));
  final e = _rad(23.439 - 0.00000036 * d);
  final ra = math.atan2(math.cos(e) * math.sin(l), math.cos(l));
  final dec = math.asin(math.sin(e) * math.sin(l));
  final gmst = (18.697374558 + 24.06570982441908 * d) % 24;
  final ha = _rad(gmst * 15 + lon) - ra;
  final h = math.asin(math.sin(_rad(lat)) * math.sin(dec) + math.cos(_rad(lat)) * math.cos(dec) * math.cos(ha));
  return _deg(h);
}

/// Night = the sun has set (its top edge below the horizon).
bool isNight(DateTime t, double lat, double lon) => sunHeight(t, lat, lon) < -0.833;

/// The moon's age as part of a month: 0 new, .25 first quarter, .5 full,
/// .75 last quarter.
double moonPhase(DateTime t) {
  const newMoon = 2451550.1; // 2000-01-06
  const month = 29.530588853;
  final p = ((_julian(t) - newMoon) / month) % 1;
  return p < 0 ? p + 1 : p;
}

/// How much of the moon is lit (0..1).
double moonLit(double phase) => (1 - math.cos(2 * math.pi * phase)) / 2;

/// Countries that say temperatures in °F.
const _fahrenheit = {'US', 'LR', 'MM', 'BS', 'BZ', 'KY', 'PW', 'FM', 'MH'};

/// °F for readers in those countries (by the phone's own region), unless
/// they picked one (pref "temp_unit": c / f).
bool useFahrenheit(String pref, [Locale? device]) {
  if (pref == 'f') return true;
  if (pref == 'c') return false;
  final cc = (device ?? PlatformDispatcher.instance.locale).countryCode?.toUpperCase();
  return cc != null && _fahrenheit.contains(cc);
}

/// "19°" in the reader's unit, no decimals (like the phone's weather app).
String tempLabel(double celsius, bool fahrenheit) => '${(fahrenheit ? celsius * 9 / 5 + 32 : celsius).round()}°${fahrenheit ? 'F' : 'C'}';

class City {
  const City(this.ko, this.en, this.lat, this.lon);
  final String ko, en;
  final double lat, lon;
  String name(bool korean) => korean ? ko : en;
}

/// Places people pick most (Korea first, then the world). On the phone, so
/// picking one tells nobody anything.
const cities = [
  City('서울', 'Seoul', 37.57, 126.98),
  City('부산', 'Busan', 35.18, 129.08),
  City('인천', 'Incheon', 37.46, 126.71),
  City('대구', 'Daegu', 35.87, 128.60),
  City('대전', 'Daejeon', 36.35, 127.38),
  City('광주', 'Gwangju', 35.16, 126.85),
  City('울산', 'Ulsan', 35.54, 129.31),
  City('수원', 'Suwon', 37.26, 127.03),
  City('세종', 'Sejong', 36.48, 127.29),
  City('춘천', 'Chuncheon', 37.88, 127.73),
  City('강릉', 'Gangneung', 37.75, 128.88),
  City('속초', 'Sokcho', 38.21, 128.59),
  City('청주', 'Cheongju', 36.64, 127.49),
  City('전주', 'Jeonju', 35.82, 127.15),
  City('여수', 'Yeosu', 34.76, 127.66),
  City('포항', 'Pohang', 36.02, 129.34),
  City('경주', 'Gyeongju', 35.86, 129.22),
  City('창원', 'Changwon', 35.23, 128.68),
  City('제주', 'Jeju', 33.50, 126.53),
  City('서귀포', 'Seogwipo', 33.25, 126.56),
  City('도쿄', 'Tokyo', 35.68, 139.69),
  City('오사카', 'Osaka', 34.69, 135.50),
  City('후쿠오카', 'Fukuoka', 33.59, 130.40),
  City('삿포로', 'Sapporo', 43.06, 141.35),
  City('오키나와', 'Okinawa', 26.21, 127.68),
  City('베이징', 'Beijing', 39.90, 116.41),
  City('상하이', 'Shanghai', 31.23, 121.47),
  City('홍콩', 'Hong Kong', 22.32, 114.17),
  City('타이베이', 'Taipei', 25.03, 121.57),
  City('방콕', 'Bangkok', 13.76, 100.50),
  City('다낭', 'Da Nang', 16.05, 108.20),
  City('하노이', 'Hanoi', 21.03, 105.85),
  City('호치민', 'Ho Chi Minh City', 10.82, 106.63),
  City('싱가포르', 'Singapore', 1.35, 103.82),
  City('쿠알라룸푸르', 'Kuala Lumpur', 3.14, 101.69),
  City('세부', 'Cebu', 10.32, 123.89),
  City('마닐라', 'Manila', 14.60, 120.98),
  City('발리', 'Bali', -8.65, 115.22),
  City('자카르타', 'Jakarta', -6.21, 106.85),
  City('뉴델리', 'New Delhi', 28.61, 77.21),
  City('두바이', 'Dubai', 25.20, 55.27),
  City('이스탄불', 'Istanbul', 41.01, 28.98),
  City('런던', 'London', 51.51, -0.13),
  City('파리', 'Paris', 48.86, 2.35),
  City('베를린', 'Berlin', 52.52, 13.40),
  City('로마', 'Rome', 41.90, 12.50),
  City('바르셀로나', 'Barcelona', 41.39, 2.17),
  City('마드리드', 'Madrid', 40.42, -3.70),
  City('암스테르담', 'Amsterdam', 52.37, 4.90),
  City('프라하', 'Prague', 50.08, 14.44),
  City('빈', 'Vienna', 48.21, 16.37),
  City('취리히', 'Zurich', 47.38, 8.54),
  City('오슬로', 'Oslo', 59.91, 10.75),
  City('헬싱키', 'Helsinki', 60.17, 24.94),
  City('모스크바', 'Moscow', 55.76, 37.62),
  City('카이로', 'Cairo', 30.04, 31.24),
  City('케이프타운', 'Cape Town', -33.92, 18.42),
  City('뉴욕', 'New York', 40.71, -74.01),
  City('로스앤젤레스', 'Los Angeles', 34.05, -118.24),
  City('샌프란시스코', 'San Francisco', 37.77, -122.42),
  City('시애틀', 'Seattle', 47.61, -122.33),
  City('라스베이거스', 'Las Vegas', 36.17, -115.14),
  City('시카고', 'Chicago', 41.88, -87.63),
  City('하와이 호놀룰루', 'Honolulu', 21.31, -157.86),
  City('괌', 'Guam', 13.44, 144.79),
  City('사이판', 'Saipan', 15.18, 145.75),
  City('밴쿠버', 'Vancouver', 49.28, -123.12),
  City('토론토', 'Toronto', 43.65, -79.38),
  City('멕시코시티', 'Mexico City', 19.43, -99.13),
  City('상파울루', 'São Paulo', -23.55, -46.63),
  City('시드니', 'Sydney', -33.87, 151.21),
  City('멜버른', 'Melbourne', -37.81, 144.96),
  City('오클랜드', 'Auckland', -36.85, 174.76),
];

/// Distance in km (good enough for "which city is nearest").
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1), dLon = _rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 6371 * 2 * math.asin(math.min(1, math.sqrt(a)));
}

/// The nearest city on our list within [withinKm], worked out on the phone.
City? nearestCity(double lat, double lon, {double withinKm = 40}) {
  City? best;
  var bestKm = withinKm;
  for (final c in cities) {
    final km = distanceKm(lat, lon, c.lat, c.lon);
    if (km <= bestKm) {
      best = c;
      bestKm = km;
    }
  }
  return best;
}
