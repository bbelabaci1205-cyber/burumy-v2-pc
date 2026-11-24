// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat backgrounds (Settings > Appearance > Colour theme): plain white like
// iPhone Messages by default, or a soft gradient with a drawn icon pattern,
// or my own photo. Everything is drawn here; nothing is downloaded.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/app_state.dart';
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

/// Paints the chosen background behind [child].
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child, this.theme, this.roomId});
  final Widget child;

  /// A chat with its own background (chat info > "이 대화방 배경").
  final String? roomId;

  /// Preview a theme that is not picked yet.
  final String? theme;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final here = roomId == null ? '' : s.pref('chat_theme:$roomId', '');
    final id = theme ?? (here.isNotEmpty ? here : s.pref('chat_theme', 'plain'));
    final photo = id == 'photo' ? chatPhoto(s) : null;
    return Stack(
      children: [
        Positioned.fill(
          child: photo != null
              ? Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true)
              : WallpaperArt(theme: ChatTheme.of(id), dark: p.dark, base: p.chatBackground),
        ),
        child,
      ],
    );
  }
}

class WallpaperArt extends StatelessWidget {
  const WallpaperArt({super.key, required this.theme, required this.dark, required this.base});
  final ChatTheme theme;
  final bool dark;
  final Color base;

  @override
  Widget build(BuildContext context) {
    if (theme.id.startsWith('hiphop')) return HiphopArt(look: dark ? 'hiphop_dark' : theme.id);
    if (theme.icons.isEmpty) return ColoredBox(color: base);
    final colors = dark ? theme.dark : theme.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
      ),
      child: CustomPaint(painter: _Pattern(theme.icons, Color(dark || theme.id == 'hiphop' ? 0x1FFFFFFF : 0x1A000000)), size: Size.infinite),
    );
  }
}

class _Pattern extends CustomPainter {
  _Pattern(this.icons, this.color);
  final List<IconData> icons;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 64.0;
    final rnd = math.Random(7);
    var n = 0;
    for (var y = -step / 2; y < size.height + step; y += step) {
      final shift = ((y / step).round().isOdd) ? step / 2 : 0.0;
      for (var x = -step / 2 + shift; x < size.width + step; x += step) {
        final icon = icons[n++ % icons.length];
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 22 + rnd.nextDouble() * 6, color: color),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(x + rnd.nextDouble() * 10, y + rnd.nextDouble() * 10);
        canvas.rotate((rnd.nextDouble() - .5) * .7);
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_Pattern o) => o.color != color || o.icons != icons;
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
