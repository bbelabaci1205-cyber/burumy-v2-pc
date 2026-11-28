// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story stickers from Telegram tip 467 (weather), with the place tag and
// the link sticker that sit next to it in the sticker sheet. Our way:
// - 날씨: our own drawn, moving skies (sun, clouds, rain, storm, snow, fog,
//   and the real moon phase at night) with a bubble burst when it appears;
//   the place is blurred to ~10 km and asked through our server, and the
//   story keeps only the temperature and the sky. Friends see °C or °F by
//   their own country and tap to switch.
// - 위치: a name, and only if the person wants, a spot (exact or ~1 km).
//   Friends tap it for a drawn map card; their own Maps app opens only on
//   a second tap (no map company is asked to draw anything).
// - 링크: the poster's phone makes the card (like chat link cards); friends
//   never contact the site just by watching. Tapping shows the real
//   address first, with a warning when the shown name looks like another
//   site.
// All of it travels inside the story, encrypted to the friends it is for.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image/image.dart' as img;
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/phone.dart';
import '../core/story_weather.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'links.dart';
import 'location.dart';
import 'story_more.dart';
import 'wide.dart';

const _white = Color(0xFFFFFFFF);
const _ink = Color(0xFF000000);
const _darkFill = Color(0xE61C1C1E);
// Soft lift, like an iOS widget on a photo (no hard band under it).
const _shadow = [BoxShadow(color: Color(0x24000000), blurRadius: 18, offset: Offset(0, 3))];
const _textShadow = [Shadow(color: Color(0x80000000), blurRadius: 8)];

/// Foreground / background of a sticker look (0 white, 1 dark, 2 clear, 3 our colour).
(Color, Color?, Color) _colours(int look, Palette p) => switch (look) {
  1 => (_white, _darkFill, _white),
  2 => (_white, null, _white),
  3 => (p.onAccent, p.accent, p.onAccent),
  _ => (_ink, _white, p.accent),
};

/// The sticker as it shows on a story (editor and viewer).
class StorySticker extends StatelessWidget {
  const StorySticker({super.key, required this.item, this.fahrenheit});
  final StoryLive item;

  /// Viewer's unit (null: by the phone's country / saved choice).
  final bool? fahrenheit;

  @override
  Widget build(BuildContext context) => switch (item.kind) {
    'weather' => WeatherSticker(item: item, fahrenheit: fahrenheit),
    'place' => _PlaceSticker(item: item),
    _ => _LinkSticker(item: item),
  };
}

// ------------------------------------------------------------------ weather

class WeatherSticker extends StatefulWidget {
  const WeatherSticker({super.key, required this.item, this.fahrenheit, this.burst = true});
  final StoryLive item;
  final bool? fahrenheit;

  /// The bubble burst when it first shows.
  final bool burst;

  /// Tests: draw one still frame (the loop never settles otherwise).
  static bool debugStill = false;

  @override
  State<WeatherSticker> createState() => _WeatherStickerState();
}

class _WeatherStickerState extends State<WeatherSticker> with TickerProviderStateMixin {
  late final loop = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  late final pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500), value: widget.burst ? 0 : 1);
  bool moving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.getInheritedWidgetOfExactType<AppScope>()?.notifier;
    final move = !WeatherSticker.debugStill && !MediaQuery.disableAnimationsOf(context) && (s?.gifsMove ?? true);
    if (!move) {
      // Still: no loop and no burst (Reduce Motion, autoplay off, battery saver).
      moving = false;
      loop.stop();
      pop.value = 1;
      return;
    }
    if (moving) return;
    moving = true;
    loop.repeat();
    if (pop.value < 1) unawaited(pop.forward());
  }

  @override
  void dispose() {
    loop.dispose();
    pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final p = paletteOf(context);
    final s = context.getInheritedWidgetOfExactType<AppScope>()?.notifier;
    final f = widget.fahrenheit ?? useFahrenheit(s?.pref('temp_unit', '') ?? '');
    final (fg, bg, _) = _colours(it.look, p);
    final temp = Text(
      tempLabel(it.celsius, f),
      key: const Key('weather-temp'),
      style: TextStyle(
        fontSize: 28,
        height: 1.1,
        fontWeight: Tokens.semi,
        color: fg,
        shadows: bg == null ? _textShadow : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return AnimatedBuilder(
      animation: Listenable.merge([loop, pop]),
      builder: (context, _) {
        final b = Curves.easeOut.transform(1 - pop.value);
        return Transform.scale(
          scale: 1 + .18 * math.sin(math.min(1, pop.value * 1.4) * math.pi) * (pop.value < 1 ? 1 : 0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 16, 8),
            decoration: bg == null
                ? null
                : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Tokens.radius[2]), boxShadow: it.look == 0 ? _shadow : null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 46,
                  height: 46,
                  child: CustomPaint(
                    painter: WeatherArt(sky: it.sky, night: it.night, moon: it.moon, t: loop.value, burst: b, dark: it.look != 0),
                  ),
                ),
                const SizedBox(width: 6),
                if (it.place.isEmpty)
                  temp
                else
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      temp,
                      Text(
                        it.place,
                        style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: .75), shadows: bg == null ? _textShadow : null),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Our own drawn weather: [t] runs 0..1 again and again, [burst] goes
/// 1 → 0 once when the sticker appears (bubbles fly out, the sky swells).
class WeatherArt extends CustomPainter {
  WeatherArt({required this.sky, required this.night, required this.moon, required this.t, this.burst = 0, this.dark = false});
  final String sky;
  final bool night, dark;
  final double moon, t, burst;

  static const sunCore = Color(0xFFFFD60A), sunEdge = Palette.tileOrange;
  static const moonLit = Color(0xFFF6F1D3);
  static const drop = Color(0xFF64D2FF);
  static const bolt = Palette.tileYellow;

  @override
  void paint(Canvas c, Size size) {
    final s = size.shortestSide;
    final o = size.center(Offset.zero);
    c.save();
    c.translate(o.dx, o.dy);
    c.scale(1 + .5 * burst);
    _bubbles(c, s);
    switch (sky) {
      case 'clear':
        night ? _moon(c, Offset.zero, s * .30, withStars: true) : _sun(c, Offset.zero, s * .24);
      case 'partly':
        night ? _moon(c, Offset(-s * .12, -s * .12), s * .22) : _sun(c, Offset(-s * .12, -s * .12), s * .19);
        _cloud(c, Offset(s * .07, s * .12), s * .62, _cloudFront, drift: true);
      case 'cloudy':
        _cloud(c, Offset(-s * .12, -s * .1), s * .5, _cloudBack, drift: true, back: true);
        _cloud(c, Offset(s * .06, s * .08), s * .66, _cloudFront, drift: true);
      case 'rain':
        _rain(c, s, flakes: false);
        _cloud(c, Offset(0, -s * .1), s * .72, _cloudFront);
      case 'storm':
        _rain(c, s, flakes: false, few: true);
        _bolt(c, s);
        _cloud(c, Offset(0, -s * .12), s * .74, _cloudDark);
      case 'snow':
        _rain(c, s, flakes: true);
        _cloud(c, Offset(0, -s * .1), s * .72, _cloudFront);
      default: // fog
        _cloud(c, Offset(0, -s * .12), s * .62, _cloudBack, drift: true);
        _fog(c, s);
    }
    c.restore();
  }

  // Clouds: lit from above (white top, cool grey underside) so they read
  // on a white sticker as well as on a dark one.
  List<Color> get _cloudFront => dark ? const [Color(0xFFFFFFFF), Color(0xFFD5DCE5)] : const [Color(0xFFF9FAFC), Color(0xFFB4BFCC)];
  List<Color> get _cloudBack => dark ? const [Color(0xFFC9D0DA), Color(0xFF9AA4B1)] : const [Color(0xFFDDE2E9), Color(0xFF9EA9B6)];
  List<Color> get _cloudDark => const [Color(0xFF9AA0AA), Color(0xFF5E646E)];

  /// Little soap bubbles (our logo's feel) flying out as the sticker appears.
  void _bubbles(Canvas c, double s) {
    if (burst <= 0.01) return;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var i = 0; i < 9; i++) {
      final a = i * 2 * math.pi / 9 + .4;
      final d = s * (.45 + 1.1 * (1 - burst)) * (1 + (i % 3) * .12);
      final r = s * (.05 + .03 * (i % 3));
      ring.color = (i.isEven ? _white : _accentFor()).withValues(alpha: (burst * .9).clamp(0, 1));
      c.drawCircle(Offset(math.cos(a) * d, math.sin(a) * d), r, ring);
    }
  }

  Color _accentFor() => switch (sky) {
    'clear' || 'partly' => night ? moonLit : sunCore,
    'rain' || 'snow' => drop,
    'storm' => bolt,
    _ => const Color(0xFFE5E5EA),
  };

  void _sun(Canvas c, Offset at, double r) {
    final rays = Paint()
      ..color = sunCore
      ..strokeWidth = r * .22
      ..strokeCap = StrokeCap.round;
    final spin = t * math.pi / 4;
    final reach = 1 + 1.2 * burst;
    for (var i = 0; i < 8; i++) {
      final a = spin + i * math.pi / 4;
      final pulse = 1 + .08 * math.sin((t + i / 8) * 2 * math.pi);
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(at + d * r * 1.35, at + d * r * (1.35 + .4 * pulse * reach), rays);
    }
    c.drawCircle(
      at,
      r,
      Paint()..shader = RadialGradient(colors: const [sunCore, sunEdge], stops: const [.55, 1]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
  }

  /// The moon as it really is tonight: [moon] 0 new, .5 full; lit on the
  /// right while it grows (as seen from the north, like the phone's own
  /// weather app).
  void _moon(Canvas c, Offset at, double r, {bool withStars = false}) {
    if (withStars) {
      final star = Paint()..color = moonLit;
      for (final (dx, dy, k) in const [(-1.55, -.9, 0.0), (1.4, -1.25, .33), (1.25, 1.1, .66)]) {
        final tw = .35 + .65 * (.5 + .5 * math.sin((t + k) * 2 * math.pi));
        star.color = moonLit.withValues(alpha: tw);
        _sparkle(c, at + Offset(dx * r, dy * r), r * .18 * (.7 + .3 * tw), star);
      }
    }
    c.drawCircle(at, r, Paint()..color = moonLit.withValues(alpha: .18));
    final lit = moonLit;
    final k = math.cos(2 * math.pi * moon); // 1 new, -1 full
    final waxing = moon < .5;
    if ((1 - k) / 2 < .03) {
      c.drawCircle(
        at,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = lit.withValues(alpha: .6),
      );
      return;
    }
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..arcTo(Rect.fromCircle(center: at, radius: r), -math.pi / 2, math.pi, false);
    final ex = r * k.abs();
    final ell = Rect.fromCenter(center: at, width: 2 * ex + .001, height: 2 * r);
    // Back from the bottom to the top along the shadow's edge.
    path.arcTo(ell, math.pi / 2, k > 0 ? -math.pi : math.pi, false);
    path.close();
    c.save();
    if (!waxing) {
      c.translate(at.dx * 2, 0);
      c.scale(-1, 1);
    }
    c.drawShadow(path, lit, 3, false);
    c.drawPath(path, Paint()..color = lit);
    c.restore();
  }

  void _sparkle(Canvas c, Offset at, double r, Paint p) {
    final path = Path()
      ..moveTo(at.dx, at.dy - r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx + r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy + r)
      ..quadraticBezierTo(at.dx, at.dy, at.dx - r, at.dy)
      ..quadraticBezierTo(at.dx, at.dy, at.dx, at.dy - r);
    c.drawPath(path, p);
  }

  void _cloud(Canvas c, Offset at, double w, List<Color> colours, {bool drift = false, bool back = false}) {
    final dx = drift ? math.sin((t + (back ? .5 : 0)) * 2 * math.pi) * w * .06 : 0.0;
    final o = at + Offset(dx, 0);
    final h = w * .3;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colours,
      ).createShader(Rect.fromLTRB(o.dx - w / 2, o.dy - w * .35, o.dx + w / 2, o.dy + h));
    final base = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - w / 2, o.dy, w, h), Radius.circular(h / 2));
    final path = Path()
      ..addRRect(base)
      ..addOval(Rect.fromCircle(center: o + Offset(-w * .2, h * .15), radius: w * .22))
      ..addOval(Rect.fromCircle(center: o + Offset(w * .08, -h * .05), radius: w * .3))
      ..addOval(Rect.fromCircle(center: o + Offset(w * .3, h * .3), radius: w * .17));
    if (!back) c.drawShadow(path, const Color(0x55000000), 2, true);
    c.drawPath(path, paint);
  }

  void _rain(Canvas c, double s, {required bool flakes, bool few = false}) {
    final n = few ? 3 : 4;
    final spread = 1 + .8 * burst;
    for (var i = 0; i < n; i++) {
      final x = (i - (n - 1) / 2) * s * .2 * spread;
      final run = (t * (flakes ? 1 : 2) + i * .29) % 1;
      final y = s * (.08 + .34 * run);
      final a = run < .8 ? 1.0 : (1 - run) * 5;
      if (flakes) {
        final p = Paint()
          ..color = _white.withValues(alpha: a)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;
        final at = Offset(x + math.sin((run + i) * 2 * math.pi) * s * .04, y);
        final r = s * .06;
        for (var k = 0; k < 3; k++) {
          final ang = k * math.pi / 3 + run * math.pi;
          final d = Offset(math.cos(ang), math.sin(ang)) * r;
          c.drawLine(at - d, at + d, p);
        }
      } else {
        final p = Paint()
          ..color = drop.withValues(alpha: a)
          ..strokeWidth = s * .055
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(x + s * .02, y), Offset(x - s * .02, y + s * .12), p);
      }
    }
  }

  void _bolt(Canvas c, double s) {
    final ph = t * 2 % 1;
    final on = burst > .3 || ph < .06 || (ph > .1 && ph < .15);
    if (!on) return;
    final path = Path()
      ..moveTo(s * .06, s * .02)
      ..lineTo(-s * .1, s * .26)
      ..lineTo(s * .02, s * .26)
      ..lineTo(-s * .06, s * .48)
      ..lineTo(s * .14, s * .2)
      ..lineTo(s * .02, s * .2)
      ..close();
    c.drawShadow(path, bolt, 4, false);
    c.drawPath(path, Paint()..color = bolt);
  }

  void _fog(Canvas c, double s) {
    final p = Paint()
      ..color = dark ? const Color(0xFFE5E5EA) : const Color(0xFFAEAEB2)
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final dx = math.sin((t + i * .33) * 2 * math.pi) * s * .07;
      final w = s * (.62 - i * .1);
      final y = s * (.2 + i * .13);
      c.drawLine(Offset(-w / 2 + dx, y), Offset(w / 2 + dx, y), p);
    }
  }

  @override
  bool shouldRepaint(WeatherArt o) => o.t != t || o.burst != burst || o.sky != sky || o.night != night || o.moon != moon || o.dark != dark;
}

// ------------------------------------------------------------------ place

class _PlaceSticker extends StatelessWidget {
  const _PlaceSticker({required this.item});
  final StoryLive item;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final (fg, bg, icon) = _colours(item.look, p);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: bg == null
          ? null
          : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Tokens.radius[2]), boxShadow: item.look == 0 ? _shadow : null),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.location_solid, size: 22, color: icon, shadows: bg == null ? _textShadow : null),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              item.q,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, height: 1.2, fontWeight: Tokens.semi, color: fg, shadows: bg == null ? _textShadow : null),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ link

String linkHost(String url) => (Uri.tryParse(url)?.host ?? '').replaceFirst(RegExp(r'^www\.'), '');

/// Does the shown name look like a web address other than where the link
/// really goes? ("naver.com" on a link to n4ver-login.xyz)
bool linkLooksElsewhere(String shown, String url) {
  final m = RegExp(r'([a-z0-9-]+\.)+[a-z]{2,}', caseSensitive: false).firstMatch(shown.trim());
  if (m == null) return false;
  final named = m[0]!.toLowerCase().replaceFirst(RegExp(r'^www\.'), '');
  final real = linkHost(url).toLowerCase();
  return !(real == named || real.endsWith('.$named'));
}

class _LinkSticker extends StatelessWidget {
  const _LinkSticker({required this.item});
  final StoryLive item;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final (fg, bg, icon) = _colours(item.look, p);
    final label = item.q.isNotEmpty ? item.q : (item.title.isNotEmpty && !item.card ? item.title : linkHost(item.url));
    final deco = bg == null
        ? BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
            border: Border.all(color: const Color(0x99FFFFFF), width: 1),
          )
        : BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Tokens.radius[2]), boxShadow: item.look == 0 ? _shadow : null);
    if (!item.card) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: deco,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.link, size: 20, color: icon),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 19, height: 1.2, fontWeight: Tokens.semi, color: fg),
              ),
            ),
          ],
        ),
      );
    }
    Uint8List? pic;
    if (item.img.isNotEmpty) {
      try {
        pic = base64Decode(item.img);
      } catch (_) {}
    }
    return Container(
      width: 264,
      padding: const EdgeInsets.all(10),
      decoration: deco,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: SizedBox(
              width: 56,
              height: 56,
              child: pic != null ? Image.memory(pic, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => _letter(p, fg)) : _letter(p, fg),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.q.isNotEmpty ? item.q : (item.title.isNotEmpty ? item.title : linkHost(item.url)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.preview.style.copyWith(color: fg, fontWeight: Tokens.semi, height: 1.25),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(CupertinoIcons.link, size: 12, color: fg.withValues(alpha: .6)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        linkHost(item.url),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: .6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _letter(Palette p, Color fg) {
    final h = linkHost(item.url);
    return ColoredBox(
      color: p.accent.withValues(alpha: .15),
      child: Center(
        child: Text(
          h.isEmpty ? '🔗' : h[0].toUpperCase(),
          style: Tokens.cardTitle.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}

/// Shrinks a page picture to a small JPEG (≤ ~11 KB) for the story card.
String storyLinkThumb(List<int> bytes) {
  if (bytes.isEmpty || bytes.length > 4 * 1024 * 1024) return '';
  try {
    final src = img.decodeImage(Uint8List.fromList(bytes));
    if (src == null) return '';
    final side = math.min(src.width, src.height);
    final sq = img.copyCrop(src, x: (src.width - side) ~/ 2, y: (src.height - side) ~/ 2, width: side, height: side);
    for (final (px, q) in const [(168, 72), (144, 60), (112, 55)]) {
      final out = img.encodeJpg(
        img.copyResize(sq, width: px, height: px, interpolation: img.Interpolation.average),
        quality: q,
      );
      final b64 = base64Encode(out);
      if (b64.length <= 15000) return b64;
    }
  } catch (_) {}
  return '';
}

// ------------------------------------------------------------------ viewer taps

/// What a tap on a sticker does in a friend's story. Returns when done (the
/// story pauses meanwhile).
Future<void> openStorySticker(BuildContext context, StoryLive it) async {
  switch (it.kind) {
    case 'weather':
      // °C ⇄ °F, remembered on this phone.
      final s = AppScope.read(context);
      final f = useFahrenheit(s.pref('temp_unit', ''));
      await s.setPref('temp_unit', f ? 'c' : 'f');
    case 'place':
      await _sheet(context, _PlaceCard(item: it));
    case 'link':
      await _sheet(context, _LinkCard(item: it));
  }
}

Future<void> _sheet(BuildContext context, Widget child) => showCupertinoModalPopup<void>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (c) => SafeArea(
    top: false,
    child: Container(
      margin: EdgeInsets.all(Tokens.space[2]),
      decoration: BoxDecoration(color: paletteOf(c).card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  ),
);

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.item});
  final StoryLive item;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final point = item.lat != null && item.lon != null ? GeoPoint(item.lat!, item.lon!, null) : null;
    return Column(
      key: const Key('story-place-card'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (point != null) SizedBox(height: 160, child: MapArt(pin: true, seed: item.q.hashCode)),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
          child: Row(
            children: [
              Icon(CupertinoIcons.location_solid, color: p.accent, size: Tokens.listIcon),
              SizedBox(width: Tokens.space[1]),
              Expanded(
                child: Text(
                  item.q,
                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                ),
              ),
            ],
          ),
        ),
        if (point == null)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[0], Tokens.space[3], 0),
            child: Text(l.stkPlaceOnlyName, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ),
        Padding(
          padding: EdgeInsets.all(Tokens.space[3]),
          child: _WideButton(
            key: const Key('story-place-maps'),
            text: l.stkMapOpen,
            onTap: () {
              Navigator.of(context).pop();
              final uri = point?.mapsUri ?? Uri.parse('https://maps.apple.com/?q=${Uri.encodeQueryComponent(item.q)}');
              unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
            },
          ),
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.item});
  final StoryLive item;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final shown = item.q.isNotEmpty ? item.q : item.title;
    final elsewhere = linkLooksElsewhere(shown, item.url);
    return Padding(
      key: const Key('story-link-card'),
      padding: EdgeInsets.all(Tokens.space[3]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (shown.isNotEmpty)
            Text(
              shown,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
            ),
          SizedBox(height: Tokens.space[1]),
          Text(l.stkLinkGoesTo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          SizedBox(height: Tokens.nameToSub),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: linkHost(item.url),
                  style: TextStyle(fontWeight: Tokens.semi, color: p.label),
                ),
                TextSpan(text: '  ${item.url}'),
              ],
            ),
            key: const Key('story-link-real'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
          if (elsewhere) ...[
            SizedBox(height: Tokens.space[2]),
            Row(
              key: const Key('story-link-warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.exclamationmark_triangle_fill, size: 18, color: Palette.tileOrange),
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: Text(l.stkLinkLookalike, style: Tokens.caption.style.copyWith(color: Palette.tileOrange)),
                ),
              ],
            ),
          ],
          SizedBox(height: Tokens.space[3]),
          _WideButton(
            key: const Key('story-link-open'),
            text: l.stkLinkOpen,
            onTap: () {
              Navigator.of(context).pop();
              unawaited(openWebLink(context, item.url));
            },
          ),
        ],
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          text,
          style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ editor pages

/// Full-screen pages to add or change a weather / place / link sticker.
Future<StoryLive?> editSticker(BuildContext context, String kind, [StoryLive? old]) => paneNav(context).push<StoryLive>(
  IosPageRoute(
    fullscreenDialog: true,
    builder: (_) => switch (kind) {
      'weather' => _WeatherPage(old: old),
      'place' => _PlacePage(old: old),
      _ => _LinkPage(old: old),
    },
  ),
);

/// Row of round colour choices (white, dark, clear, our colour).
class _LookRow extends StatelessWidget {
  const _LookRow({required this.look, required this.count, required this.onPick});
  final int look, count;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final names = [l.stkLookWhite, l.stkLookDark, l.stkLookClear, l.stkLookColor];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < count; i++)
            GestureDetector(
              key: Key('sticker-look-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(i),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: switch (i) {
                        0 => _white,
                        1 => const Color(0xFF1C1C1E),
                        2 => const Color(0x00000000),
                        _ => p.accent,
                      },
                      border: Border.all(color: look == i ? p.accent : p.separator, width: look == i ? 3 : 1),
                    ),
                    child: i == 2 ? Icon(CupertinoIcons.circle_lefthalf_fill, size: 18, color: p.secondaryLabel) : null,
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(names[i], style: Tokens.caption.style.copyWith(color: look == i ? p.accent : p.secondaryLabel)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The sticker shown big on a photo-like ground at the top of each page.
class _Preview extends StatelessWidget {
  const _Preview({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
    child: ClipRSuperellipse(
      borderRadius: BorderRadius.circular(IosSection.radius),
      child: Container(
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5AC8FA), Color(0xFF0088FF), Color(0xFF6155F5)]),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    ),
  );
}

class _WeatherPage extends StatefulWidget {
  const _WeatherPage({this.old});
  final StoryLive? old;

  @override
  State<_WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<_WeatherPage> {
  late int look = widget.old?.look ?? 0;
  bool here = true;
  City? city;
  City? near;
  bool showCity = false;
  WeatherNow? now;
  double? lat, lon;
  String? error;
  bool busy = false;
  final search = TextEditingController();
  int ask = 0;

  @override
  void initState() {
    super.initState();
    final old = widget.old;
    if (old != null) {
      // Changing a sticker I already placed: keep its weather.
      now = WeatherNow(old.celsius, old.sky);
      showCity = old.place.isNotEmpty;
      here = false;
      city = cities.where((c) => c.ko == old.place || c.en == old.place).firstOrNull;
    } else {
      unawaited(findHere());
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> findHere() async {
    final n = ++ask;
    setState(() {
      here = true;
      city = null;
      busy = true;
      error = null;
    });
    try {
      final f = await Phone.location();
      final (a, b) = StoryWeather.blur(f.lat, f.lon);
      final w = await StoryWeather.now(a, b);
      if (!mounted || n != ask) return;
      setState(() {
        lat = a;
        lon = b;
        near = nearestCity(a, b);
        now = w;
        busy = false;
      });
    } catch (e) {
      if (!mounted || n != ask) return;
      setState(() {
        busy = false;
        now = null;
        error = e is WeatherError ? e.code : 'location';
        if (error == 'location') here = false;
      });
    }
  }

  Future<void> pickCity(City c) async {
    final n = ++ask;
    setState(() {
      here = false;
      city = c;
      busy = true;
      error = null;
    });
    try {
      final w = await StoryWeather.now(c.lat, c.lon);
      if (!mounted || n != ask) return;
      setState(() {
        lat = c.lat;
        lon = c.lon;
        now = w;
        busy = false;
      });
    } catch (e) {
      if (!mounted || n != ask) return;
      setState(() {
        busy = false;
        now = null;
        error = e is WeatherError ? e.code : 'network';
      });
    }
  }

  String? get cityName {
    final ko = L.of(context).localeName.startsWith('ko');
    if (!showCity) return null;
    if (city != null) return city!.name(ko);
    if (here && near != null) return near!.name(ko);
    final old = widget.old;
    return old != null && old.place.isNotEmpty ? old.place : null;
  }

  StoryLive? get made {
    final w = now;
    if (w == null) return null;
    final at = stickerClock();
    final old = widget.old;
    // Day or night and the moon, worked out on this phone from the time and
    // the blurred point (a sticker I am changing keeps its own).
    final night = old != null && lat == null ? old.night : (lat != null ? isNight(at, lat!, lon!) : false);
    return StoryLive(
      kind: 'weather',
      at: old?.at ?? const Offset(.5, .3),
      scale: old?.scale ?? 1,
      look: look,
      sky: w.sky,
      celsius: w.celsius,
      night: night,
      moon: old != null && lat == null ? old.moon : moonPhase(at),
      place: cityName ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ko = l.localeName.startsWith('ko');
    final m = made;
    final q = search.text.trim().toLowerCase();
    final list = q.isEmpty ? cities : cities.where((c) => c.ko.contains(q) || c.en.toLowerCase().contains(q)).toList();
    final msg = switch (error) {
      'off' => l.stkWeatherOff,
      'location' => l.stkWeatherNoLocation,
      null => null,
      _ => l.stkWeatherNetwork,
    };
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.stkWeatherTitle,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('weather-done'), onTap: m == null || busy ? null : () => Navigator.of(context).pop(m))],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader, bottom: Tokens.space[5]),
        children: [
          _Preview(
            child: m != null
                ? WeatherSticker(key: ValueKey('${m.sky}${m.night}$look'), item: m)
                : busy
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(color: _white),
                      SizedBox(height: Tokens.space[1]),
                      Text(l.stkWeatherFinding, style: Tokens.preview.style.copyWith(color: _white)),
                    ],
                  )
                : Padding(
                    padding: EdgeInsets.all(Tokens.space[3]),
                    child: Text(
                      msg ?? '',
                      key: const Key('weather-error'),
                      textAlign: TextAlign.center,
                      style: Tokens.preview.style.copyWith(color: _white),
                    ),
                  ),
          ),
          // MET Norway's data is CC BY 4.0: say where it comes from (and that
          // we turn it into our own picture) right under the sticker.
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
            child: Text(
              l.stkWeatherCredit,
              key: const Key('weather-credit'),
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ),
          IosSection(
            header: sectionHeader(context, l.stkLook),
            hasLeading: false,
            children: [_LookRow(look: look, count: 3, onPick: (i) => setState(() => look = i))],
          ),
          IosSection(
            footer: sectionFooter(context, l.stkWeatherInfo),
            children: [
              IosTile(
                key: const Key('weather-here'),
                leading: iconTile(Palette.tileBlue, CupertinoIcons.location_fill),
                title: Text(l.stkWeatherHere),
                subtitle: Text(l.stkWeatherHereSub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                trailing: here ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                onTap: findHere,
              ),
              IosTile(
                key: const Key('weather-show-city'),
                leading: iconTile(Palette.tileOrange, CupertinoIcons.textformat),
                title: Text(l.stkWeatherShowCity),
                trailing: IosSwitch(value: showCity, onChanged: (v) => setState(() => showCity = v)),
                onTap: () => setState(() => showCity = !showCity),
              ),
            ],
          ),
          IosSection(
            header: sectionHeader(context, l.stkWeatherCity),
            hasLeading: false,
            children: [
              CupertinoTextField(
                key: const Key('weather-search'),
                controller: search,
                placeholder: l.stkSearchCity,
                prefix: Padding(
                  padding: EdgeInsets.only(left: Tokens.space[3]),
                  child: Icon(CupertinoIcons.search, size: Tokens.listIconSmall, color: p.secondaryLabel),
                ),
                onChanged: (_) => setState(() {}),
                decoration: null,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2] + 3),
                style: Tokens.body.style.copyWith(color: p.label),
              ),
              for (final c in list.take(q.isEmpty ? 20 : 40))
                IosTile(
                  key: Key('weather-city-${c.en}'),
                  title: Text(c.name(ko)),
                  additionalInfo: Text(ko ? c.en : '', style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  trailing: !here && city == c ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                  onTap: () => pickCity(c),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlacePage extends StatefulWidget {
  const _PlacePage({this.old});
  final StoryLive? old;

  @override
  State<_PlacePage> createState() => _PlacePageState();
}

class _PlacePageState extends State<_PlacePage> {
  late final name = TextEditingController(text: widget.old?.q ?? '');
  late int look = widget.old?.look ?? 0;
  late bool map = widget.old?.lat != null;
  bool exact = false;
  bool busy = false;
  String? error;
  double? lat, lon;
  City? near;

  @override
  void initState() {
    super.initState();
    lat = widget.old?.lat;
    lon = widget.old?.lon;
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> setMap(bool on) async {
    setState(() {
      map = on;
      error = null;
    });
    if (on) await locate();
  }

  Future<void> locate() async {
    setState(() => busy = true);
    try {
      final f = await Phone.location();
      if (!mounted) return;
      setState(() {
        // Exact: 5 decimals (~1 m); rough: 2 decimals (~1 km).
        final k = exact ? 100000 : 100;
        lat = (f.lat * k).round() / k;
        lon = (f.lon * k).round() / k;
        near = nearestCity(f.lat, f.lon);
        busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        busy = false;
        map = false;
        lat = lon = null;
        error = L.of(context).stkPlaceNoLocation;
      });
    }
  }

  bool get ok => name.text.trim().isNotEmpty && !busy && (!map || lat != null);

  StoryLive get made => StoryLive(
    kind: 'place',
    q: name.text.trim(),
    at: widget.old?.at ?? const Offset(.5, .64),
    scale: widget.old?.scale ?? 1,
    look: look,
    lat: map ? lat : null,
    lon: map ? lon : null,
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ko = l.localeName.startsWith('ko');
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.stkPlaceTitle,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('place-done'), onTap: ok ? () => Navigator.of(context).pop(made) : null)],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader, bottom: Tokens.space[5]),
        children: [
          _Preview(
            child: name.text.trim().isEmpty ? Icon(CupertinoIcons.location_solid, size: 40, color: _white.withValues(alpha: .8)) : _PlaceSticker(item: made),
          ),
          IosSection(
            hasLeading: false,
            children: [
              CupertinoTextField(
                key: const Key('place-name'),
                controller: name,
                autofocus: widget.old == null,
                placeholder: l.stkPlaceName,
                maxLength: 60,
                onChanged: (_) => setState(() {}),
                decoration: null,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
                style: Tokens.body.style.copyWith(color: p.label),
              ),
            ],
          ),
          if (near != null && name.text.trim().isEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(IosSection.sideMargin + 4, Tokens.space[2], 0, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  key: const Key('place-near'),
                  onTap: () => setState(() => name.text = near!.name(ko)),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text('${l.stkNearby}: ${near!.name(ko)}', style: Tokens.preview.style.copyWith(color: p.accent)),
                  ),
                ),
              ),
            ),
          IosSection(
            header: sectionHeader(context, l.stkLook),
            hasLeading: false,
            children: [_LookRow(look: look, count: 4, onPick: (i) => setState(() => look = i))],
          ),
          IosSection(
            footer: sectionFooter(context, error ?? l.stkPlaceInfo, error: error != null),
            children: [
              IosTile(
                key: const Key('place-map'),
                leading: iconTile(p.tileGreen, CupertinoIcons.map_fill),
                title: Text(l.stkPlaceMap),
                trailing: busy ? const CupertinoActivityIndicator() : IosSwitch(value: map, onChanged: setMap),
              ),
              if (map) ...[
                IosTile(
                  key: const Key('place-rough'),
                  title: Text(l.stkPlaceRough),
                  trailing: !exact ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                  onTap: () {
                    setState(() => exact = false);
                    unawaited(locate());
                  },
                ),
                IosTile(
                  key: const Key('place-exact'),
                  title: Text(l.stkPlaceExact),
                  trailing: exact ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                  onTap: () {
                    setState(() => exact = true);
                    unawaited(locate());
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LinkPage extends StatefulWidget {
  const _LinkPage({this.old});
  final StoryLive? old;

  @override
  State<_LinkPage> createState() => _LinkPageState();
}

class _LinkPageState extends State<_LinkPage> {
  late final url = TextEditingController(text: widget.old?.url ?? '');
  late final name = TextEditingController(text: widget.old?.q ?? '');
  late int look = widget.old?.look ?? 0;
  late bool card = widget.old?.card ?? true;
  late String title = widget.old?.title ?? '', site = widget.old?.site ?? '', thumb = widget.old?.img ?? '';
  late String readFor = widget.old?.url ?? '';
  bool reading = false;
  bool previewsOff = false;
  Timer? wait;

  @override
  void dispose() {
    wait?.cancel();
    url.dispose();
    name.dispose();
    super.dispose();
  }

  /// "naver.com" → "https://naver.com".
  String get address {
    final t = url.text.trim();
    if (t.isEmpty) return '';
    return t.startsWith('http://') || t.startsWith('https://') ? t : 'https://$t';
  }

  bool get valid {
    final u = Uri.tryParse(address);
    return u != null && u.host.contains('.') && !u.host.startsWith('.') && !u.host.endsWith('.') && address.length <= 500;
  }

  void changed() {
    setState(() {});
    wait?.cancel();
    if (!valid || address == readFor) return;
    wait = Timer(const Duration(milliseconds: 700), read);
  }

  Future<void> read() async {
    final a = address;
    final s = AppScope.read(context);
    setState(() => reading = true);
    final on = await s.backend.linkPreviewsEnabled();
    final info = on ? await s.backend.storyLinkCard(a) : null;
    final small = info == null ? '' : storyLinkThumb(info.image);
    if (!mounted || a != address) return;
    setState(() {
      reading = false;
      previewsOff = !on;
      readFor = a;
      title = info?.title ?? '';
      site = info?.site ?? '';
      thumb = small;
    });
  }

  StoryLive get made => StoryLive(
    kind: 'link',
    url: address,
    q: name.text.trim(),
    title: title.length > 120 ? title.substring(0, 120) : title,
    site: site.length > 60 ? site.substring(0, 60) : site,
    img: card ? thumb : '',
    card: card && !previewsOff,
    look: look,
    at: widget.old?.at ?? const Offset(.5, .82),
    scale: widget.old?.scale ?? 1,
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key key, TextEditingController c, String hint, int max, {bool auto = false, TextInputType? type}) => CupertinoTextField(
      key: key,
      controller: c,
      autofocus: auto,
      placeholder: hint,
      maxLength: max,
      keyboardType: type,
      autocorrect: false,
      onChanged: (_) => changed(),
      decoration: null,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
      style: Tokens.body.style.copyWith(color: p.label),
    );
    final note = !valid && url.text.trim().isNotEmpty
        ? l.stkLinkBad
        : previewsOff
        ? l.stkLinkPreviewOff
        : l.stkLinkInfo;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.stkLinkTitle,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('link-done'), onTap: valid && !reading ? () => Navigator.of(context).pop(made) : null)],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader, bottom: Tokens.space[5]),
        children: [
          _Preview(
            child: reading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CupertinoActivityIndicator(color: _white),
                      SizedBox(height: Tokens.space[1]),
                      Text(l.stkLinkReading, style: Tokens.preview.style.copyWith(color: _white)),
                    ],
                  )
                : valid
                ? _LinkSticker(item: made)
                : Icon(CupertinoIcons.link, size: 40, color: _white.withValues(alpha: .8)),
          ),
          IosSection(
            hasLeading: false,
            footer: sectionFooter(context, note, error: note == l.stkLinkBad),
            children: [
              field(const Key('link-url'), url, l.stkLinkUrl, 500, auto: widget.old == null, type: TextInputType.url),
              field(const Key('link-name'), name, l.stkLinkName, 40),
            ],
          ),
          if (!previewsOff)
            Padding(
              padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[4], IosSection.sideMargin, 0),
              child: CupertinoSlidingSegmentedControl<bool>(
                key: const Key('link-shape'),
                groupValue: card,
                children: {false: Text(l.stkLinkSmall), true: Text(l.stkLinkCard)},
                onValueChanged: (v) => setState(() => card = v ?? card),
              ),
            ),
          IosSection(
            header: sectionHeader(context, l.stkLook),
            hasLeading: false,
            children: [_LookRow(look: look, count: 4, onPick: (i) => setState(() => look = i))],
          ),
        ],
      ),
    );
  }
}
