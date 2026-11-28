// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat backgrounds (Settings > Appearance > Colour theme): plain white like
// iPhone Messages by default, or a soft gradient with a drawn icon pattern,
// or my own photo. Everything is drawn here; nothing is downloaded.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/app_state.dart';
import '../core/looks.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class ChatTheme {
  const ChatTheme(this.id, this.light, this.dark, this.icons);
  final String id;
  final List<Color> light, dark;
  final List<IconData> icons;

  static const plain = ChatTheme('plain', [], [], []);
  static const all = [
    plain,
    ChatTheme('secure', [Color(0xFFE3F4E8), Color(0xFFCDEBD7)], [Color(0xFF0E2016), Color(0xFF07140D)], [
      CupertinoIcons.lock_fill,
      CupertinoIcons.shield_fill,
      CupertinoIcons.eye_slash_fill,
      CupertinoIcons.chat_bubble_fill,
    ]),
    ChatTheme('nature', [Color(0xFFEAF2E3), Color(0xFFD5E6CB)], [Color(0xFF15200F), Color(0xFF0C1509)], [
      CupertinoIcons.leaf_arrow_circlepath,
      CupertinoIcons.tree,
      CupertinoIcons.drop_fill,
      CupertinoIcons.sun_max_fill,
    ]),
    ChatTheme('daily', [Color(0xFFF6EEDF), Color(0xFFEBDDC4)], [Color(0xFF221B12), Color(0xFF16110A)], [
      CupertinoIcons.book_fill,
      CupertinoIcons.music_note,
      CupertinoIcons.camera_fill,
      CupertinoIcons.cart_fill,
    ]),
    // Our own hip-hop doodles (Burumy v1 art, 3 looks; colours from its README).
    ChatTheme('hiphop', [Color(0xFFFF5DA2), Color(0xFF7C4DFF), Color(0xFF00BFA6), Color(0xFF3D5AFE)], [], []),
    ChatTheme('hiphop_white', [Color(0xFFFBFAFD), Color(0xFFF3F2F8), Color(0xFFF1F6F5), Color(0xFFF2F4FA)], [], []),
    ChatTheme('hiphop_dark', [Color(0xFF17131F), Color(0xFF120F1C), Color(0xFF0F1716), Color(0xFF10131D)], [], []),
  ];

  static ChatTheme of(String id) => all.where((t) => t.id == id).firstOrNull ?? plain;

  String label(L l) => switch (id) {
    'secure' => l.themeSecure,
    'nature' => l.themeNature,
    'daily' => l.themeDaily,
    'hiphop' => l.themeHiphop,
    'hiphop_white' => l.themeHiphopWhite,
    'hiphop_dark' => l.themeHiphopDark,
    _ => l.themePlain,
  };
}

/// My own photo as the chat background (kept on this device only).
Uint8List? chatPhoto(AppState s) {
  final b = s.pref('chat_photo', '');
  if (b.isEmpty) return null;
  try {
    return base64Decode(b);
  } catch (_) {
    return null;
  }
}

/// The background text in use: [preview] if given, else this chat's own
/// pick, else the group's / channel's background for all members, else my
/// default (Settings > 모양).
String wallSpecOf(AppState s, {String? roomId, String? roomWall, String? preview}) {
  if (preview != null) return preview;
  final here = roomId == null ? '' : s.pref('chat_theme:$roomId', '');
  if (here.isNotEmpty) return here;
  if (roomWall != null && roomWall.isNotEmpty) return roomWall;
  return s.pref('chat_theme', 'plain');
}

/// 밤 밝기 (tip 387): how much a photo / colour background darkens when
/// night mode is on, 0..0.8 (Settings > 모양 > 배경 고르기).
double nightDim(AppState s) => (double.tryParse(s.pref('wall_dim', '')) ?? 0.3).clamp(0.0, 0.8);

/// Paints the chosen background behind [child].
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child, this.theme, this.roomId, this.roomWall, this.still = false});
  final Widget child;

  /// A chat with its own background (chat info > "이 대화방 배경").
  final String? roomId;

  /// The group's / channel's background for all members (tip 412 / 429).
  final String? roomWall;

  /// Preview a background that is not picked yet (any [Wall] text).
  final String? theme;

  /// Small previews: no swirl, no tilt.
  final bool still;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final wall = Wall.parse(wallSpecOf(s, roomId: roomId, roomWall: roomWall, preview: theme));
    final photo = wall.kind == 'photo' ? chatPhoto(s) : null;
    Widget art = WallArt(wall: wall, dark: p.dark, base: p.chatBackground, photo: photo, still: still || theme != null);
    // Night mode: photos and own colours step down so bubbles stay calm.
    if (p.dark && (wall.kind == 'photo' || wall.kind == 'color' || wall.kind == 'grad')) {
      final dim = nightDim(s);
      if (dim > 0) {
        art = Stack(
          fit: StackFit.expand,
          children: [
            art,
            ColoredBox(color: Color.fromRGBO(0, 0, 0, dim)),
          ],
        );
      }
    }
    return Stack(
      children: [
        Positioned.fill(
          child: TiltLayer(on: theme == null && !still && (s.tiltOn || wall.motion), child: art),
        ),
        child,
      ],
    );
  }
}

/// Draws one [Wall]: our themes, a photo (sharp or blurred), one colour or
/// swirling colours, with icons over it.
class WallArt extends StatelessWidget {
  const WallArt({super.key, required this.wall, required this.dark, required this.base, this.photo, this.still = false});
  final Wall wall;
  final bool dark;
  final Color base;
  final Uint8List? photo;
  final bool still;

  @override
  Widget build(BuildContext context) {
    switch (wall.kind) {
      case 'photo':
        final b = photo;
        if (b == null) return ColoredBox(color: base);
        final img = Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true);
        if (!wall.blur) return img;
        return ClipRect(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14, tileMode: TileMode.mirror),
            child: Transform.scale(scale: 1.08, child: img),
          ),
        );
      case 'color':
        final c = wall.colors.first;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c),
            if (wall.pattern.isNotEmpty) PatternLayer(id: wall.pattern, on: c, strength: wall.strength),
          ],
        );
      case 'grad':
        final avg = wall.colors.reduce((a, b) => Color.lerp(a, b, .5)!);
        return Stack(
          fit: StackFit.expand,
          children: [
            SwirlArt(colors: wall.colors, still: still),
            if (wall.pattern.isNotEmpty) PatternLayer(id: wall.pattern, on: avg, strength: wall.strength),
          ],
        );
      default:
        final t = ChatTheme.of(wall.id);
        final art = WallpaperArt(theme: t, dark: dark, base: base, strength: wall.strength);
        if (wall.pattern.isEmpty) return art;
        return Stack(
          fit: StackFit.expand,
          children: [
            art,
            PatternLayer(id: wall.pattern, on: dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF), strength: wall.strength < 0 ? 0.5 : wall.strength),
          ],
        );
    }
  }
}

/// The icons of a pattern id (see core/looks.dart Patterns).
List<IconData> patternIcons(String id) => switch (id) {
  'hearts' => const [CupertinoIcons.heart_fill, CupertinoIcons.heart, CupertinoIcons.suit_heart_fill],
  'stars' => const [CupertinoIcons.star_fill, CupertinoIcons.sparkles, CupertinoIcons.moon_stars_fill],
  'music' => const [CupertinoIcons.music_note, CupertinoIcons.music_note_2, CupertinoIcons.headphones],
  'paws' => const [CupertinoIcons.paw_solid, CupertinoIcons.paw, CupertinoIcons.hare_fill],
  'weather' => const [CupertinoIcons.sun_max_fill, CupertinoIcons.cloud_fill, CupertinoIcons.snow, CupertinoIcons.drop_fill],
  'travel' => const [CupertinoIcons.airplane, CupertinoIcons.globe, CupertinoIcons.car_fill, CupertinoIcons.camera_fill],
  'games' => const [CupertinoIcons.gamecontroller_fill, CupertinoIcons.sportscourt_fill, CupertinoIcons.flag_fill, CupertinoIcons.rocket_fill],
  'nature' => const [CupertinoIcons.tree, CupertinoIcons.leaf_arrow_circlepath, CupertinoIcons.ant_fill, CupertinoIcons.tortoise_fill],
  _ => const <IconData>[],
};

/// Icons scattered over a background; ink follows the colour under it.
class PatternLayer extends StatelessWidget {
  const PatternLayer({super.key, required this.id, required this.on, this.strength = 0.5, this.step = 64});
  final String id;
  final Color on;
  final double strength;
  final double step;

  @override
  Widget build(BuildContext context) {
    final icons = patternIcons(id);
    if (icons.isEmpty || strength <= 0) return const SizedBox.shrink();
    final darkUnder = on.computeLuminance() < 0.4;
    final ink = darkUnder ? Color.fromRGBO(255, 255, 255, 0.06 + strength * 0.3) : Color.fromRGBO(0, 0, 0, 0.04 + strength * 0.22);
    return CustomPaint(
      painter: _Pattern(icons, ink, step: step),
      size: Size.infinite,
    );
  }
}

/// Bumped each time I send in a chat: swirling backgrounds turn a little
/// (tip 281: "colours move as you send messages").
final wallSpin = ValueNotifier<int>(0);

/// Four soft colour spots that sit around the middle and turn an eighth of
/// a circle (smoothly) each time I send.
class SwirlArt extends StatefulWidget {
  const SwirlArt({super.key, required this.colors, this.still = false});
  final List<Color> colors;
  final bool still;
  @override
  State<SwirlArt> createState() => _SwirlArtState();
}

class _SwirlArtState extends State<SwirlArt> with SingleTickerProviderStateMixin {
  late final AnimationController turn = AnimationController(vsync: this, duration: Tokens.swirlTurn);
  double from = 0, to = 0;

  @override
  void initState() {
    super.initState();
    from = to = widget.still ? 0 : wallSpin.value.toDouble();
    wallSpin.addListener(_spin);
  }

  void _spin() {
    if (widget.still || !mounted) return;
    from = _now;
    to = wallSpin.value.toDouble();
    turn.forward(from: 0);
  }

  double get _now => from + (to - from) * Curves.easeInOutCubic.transform(turn.value);

  @override
  void dispose() {
    wallSpin.removeListener(_spin);
    turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: turn,
    builder: (_, _) => CustomPaint(painter: SwirlPainter(widget.colors, _now), size: Size.infinite),
  );
}

class SwirlPainter extends CustomPainter {
  SwirlPainter(this.colors, this.phase);
  final List<Color> colors;

  /// In eighths of a turn.
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final c = colors.length >= 4 ? colors : [...colors, ...colors].take(4).toList();
    final avg = Color.lerp(Color.lerp(c[0], c[1], .5), Color.lerp(c[2], c[3], .5), .5)!;
    canvas.drawRect(r, Paint()..color = avg);
    final mid = r.center;
    final reach = Offset(size.width * .42, size.height * .38);
    final radius = r.longestSide * .62;
    for (var i = 0; i < 4; i++) {
      final a = (i * 90 + 45 + phase * 45) * math.pi / 180;
      final at = mid + Offset(math.cos(a) * reach.dx, -math.sin(a) * reach.dy);
      canvas.drawRect(r, Paint()..shader = ui.Gradient.radial(at, radius, [c[i], c[i].withValues(alpha: 0)]));
    }
  }

  @override
  bool shouldRepaint(SwirlPainter o) => o.phase != phase || o.colors != colors;
}

class WallpaperArt extends StatelessWidget {
  const WallpaperArt({super.key, required this.theme, required this.dark, required this.base, this.strength = -1});
  final ChatTheme theme;
  final bool dark;
  final Color base;

  /// 무늬 강도 0..1; below 0 = the theme's own.
  final double strength;

  @override
  Widget build(BuildContext context) {
    if (theme.id.startsWith('hiphop')) return HiphopArt(look: dark ? 'hiphop_dark' : theme.id);
    if (theme.icons.isEmpty) return ColoredBox(color: base);
    final colors = dark ? theme.dark : theme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: CustomPaint(
        painter: _Pattern(
          theme.icons,
          strength < 0
              ? Color(dark || theme.id == 'hiphop' ? 0x1FFFFFFF : 0x1A000000)
              : (dark ? Color.fromRGBO(255, 255, 255, 0.04 + strength * 0.24) : Color.fromRGBO(0, 0, 0, 0.03 + strength * 0.2)),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _Pattern extends CustomPainter {
  _Pattern(this.icons, this.color, {this.step = 64});
  final List<IconData> icons;
  final Color color;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = step / 64;
    final rnd = math.Random(7);
    var n = 0;
    for (var y = -step / 2; y < size.height + step; y += step) {
      final shift = ((y / step).round().isOdd) ? step / 2 : 0.0;
      for (var x = -step / 2 + shift; x < size.width + step; x += step) {
        final icon = icons[n++ % icons.length];
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: (22 + rnd.nextDouble() * 6) * scale, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x + rnd.nextDouble() * 10 * scale, y + rnd.nextDouble() * 10 * scale);
        canvas.rotate((rnd.nextDouble() - .5) * .7);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_Pattern o) => o.color != color || o.icons != icons || o.step != step;
}

/// The hip-hop wallpaper: four soft colour spots (top right, top left,
/// bottom left, bottom right) and our doodle tile (2560 px drawn at 432 pt,
/// lines in its alpha only) tinted per look. A dark phone always shows the
/// dark look.
const _bright = [Color(0xFFFF5DA2), Color(0xFF7C4DFF), Color(0xFF00BFA6), Color(0xFF3D5AFE)];

class HiphopArt extends StatefulWidget {
  const HiphopArt({super.key, required this.look});
  final String look;

  static ui.Image? _tile;
  static Future<ui.Image>? _loading;

  static Future<ui.Image> tile() => _loading ??= () async {
    final data = await rootBundle.load('assets/wallpaper/hiphop_tile.webp');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final f = await codec.getNextFrame();
    return _tile = f.image;
  }();

  @override
  State<HiphopArt> createState() => _HiphopArtState();
}

class _HiphopArtState extends State<HiphopArt> {
  ui.Image? tile = HiphopArt._tile;

  @override
  void initState() {
    super.initState();
    if (tile == null) {
      HiphopArt.tile().then((t) {
        if (mounted) setState(() => tile = t);
      }, onError: (_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final look = ChatTheme.of(widget.look);
    final (lines, opacity) = switch (widget.look) {
      'hiphop' => (const [Color(0xFF000000), Color(0xFF000000), Color(0xFF000000), Color(0xFF000000)], 0.24),
      'hiphop_white' => (_bright, 0.5),
      _ => (_bright, 0.4),
    };
    return CustomPaint(painter: _HiphopPainter(look.light, lines, opacity, tile), size: Size.infinite);
  }
}

class _HiphopPainter extends CustomPainter {
  _HiphopPainter(this.back, this.lines, this.opacity, this.tile);
  final List<Color> back;
  final List<Color> lines;
  final double opacity;
  final ui.Image? tile;

  /// Four colour spots from the corners (TR, TL, BL, BR), fading inwards.
  static void spots(Canvas canvas, Rect r, List<Color> c, {Paint? base}) {
    final avg = Color.lerp(Color.lerp(c[0], c[1], .5), Color.lerp(c[2], c[3], .5), .5)!;
    canvas.drawRect(r, base ?? (Paint()..color = avg));
    final corners = [r.topRight, r.topLeft, r.bottomLeft, r.bottomRight];
    final radius = r.longestSide * 0.85;
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        r,
        Paint()
          ..blendMode = base == null ? BlendMode.srcOver : BlendMode.srcATop
          ..shader = ui.Gradient.radial(corners[i], radius, [c[i], c[i].withValues(alpha: 0)]),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    spots(canvas, r, back);
    final t = tile;
    if (t == null) return;
    const pt = 432.0;
    final scale = pt / t.width;
    canvas.saveLayer(r, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    canvas.drawRect(
      r,
      Paint()
        ..shader = ImageShader(t, TileMode.repeated, TileMode.repeated, Matrix4.diagonal3Values(scale, scale, 1).storage, filterQuality: FilterQuality.medium),
    );
    // Colour the lines: keep only where the tile has ink.
    canvas.saveLayer(r, Paint()..blendMode = BlendMode.srcIn);
    spots(canvas, r, lines);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HiphopPainter o) => o.tile != tile || o.back != back || o.lines != lines || o.opacity != opacity;
}

/// Tokens used by the wallpaper previews.
const wallpaperPreviewRadius = 16.0;
double get wallpaperTileWidth => 72 + Tokens.space[0];

/// Settings > Appearance > Move when tilted: the background drifts a few
/// points against the phone's tilt (a little zoomed so no edge shows).
/// Phones only; the sensor stops as soon as the chat closes.
class TiltLayer extends StatefulWidget {
  const TiltLayer({super.key, required this.on, required this.child});
  final bool on;
  final Widget child;
  @override
  State<TiltLayer> createState() => _TiltLayerState();
}

class _TiltLayerState extends State<TiltLayer> {
  static const reach = 14.0;
  StreamSubscription<AccelerometerEvent>? sub;
  Offset at = Offset.zero;

  bool get phone => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(TiltLayer old) {
    super.didUpdateWidget(old);
    if (old.on != widget.on) _listen();
  }

  void _listen() {
    unawaited(sub?.cancel());
    sub = null;
    if (!widget.on || !phone) return;
    sub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((e) {
      // Gravity split over x / y: about -9.8..9.8 each. Smoothed.
      final want = Offset((e.x / 9.8).clamp(-1.0, 1.0) * reach, (-(e.y - 6) / 9.8).clamp(-1.0, 1.0) * reach);
      final next = Offset.lerp(at, want, 0.15)!;
      if ((next - at).distance > 0.2 && mounted) setState(() => at = next);
    });
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.on || !phone) return widget.child;
    return ClipRect(
      child: Transform.translate(
        offset: at,
        child: Transform.scale(scale: 1.1, child: widget.child),
      ),
    );
  }
}
