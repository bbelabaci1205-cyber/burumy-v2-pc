// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가루처럼 사라지기 (Telegram tip 365, 2026-11-27): a removed message breaks
// into fine dust that drifts up and away, left to right, then its row
// closes. Used when someone deletes a message, or the anti-spam filter
// removes spam, while the chat is open. Our own drawing: the bubble is
// copied to a picture once, then its tiny squares are drawn moving
// (Canvas.drawAtlas). With "동작 줄이기" it just fades.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class DustOut extends StatefulWidget {
  const DustOut({super.key, required this.child, this.onDone});
  final Widget child;
  final VoidCallback? onDone;

  /// Whole effect; the row closes in the last part.
  static const duration = Duration(milliseconds: 1100);

  /// Size of one grain, in logical pixels.
  static const grain = 2.5;

  @override
  State<DustOut> createState() => _DustOutState();
}

class _DustOutState extends State<DustOut> with SingleTickerProviderStateMixin {
  final shot = GlobalKey();
  late final AnimationController t = AnimationController(vsync: this, duration: DustOut.duration);
  ui.Image? image;
  double ratio = 1;
  bool still = false;

  @override
  void initState() {
    super.initState();
    t.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => capture());
  }

  Future<void> capture() async {
    if (!mounted) return;
    still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final b = shot.currentContext?.findRenderObject();
    if (!still && b is RenderRepaintBoundary && b.hasSize && !b.size.isEmpty) {
      try {
        ratio = math.min(MediaQuery.devicePixelRatioOf(context), 2.0);
        final img = await b.toImage(pixelRatio: ratio);
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() => image = img);
      } catch (_) {
        // No picture (old renderer): fade instead.
      }
    }
    if (mounted) t.forward();
  }

  @override
  void dispose() {
    t.dispose();
    image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = image;
    return AnimatedBuilder(
      animation: t,
      builder: (context, child) {
        // The row closes over the last 30%.
        final close = Curves.easeInOut.transform(((t.value - 0.7) / 0.3).clamp(0.0, 1.0));
        final Widget body = img == null
            ? Opacity(opacity: (1 - t.value * 1.6).clamp(0.0, 1.0), child: child)
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(opacity: 0, child: child),
                  Positioned.fill(child: CustomPaint(painter: _DustPainter(img, ratio, t.value))),
                ],
              );
        return ClipRect(
          clipBehavior: img == null ? Clip.hardEdge : Clip.none,
          child: Align(alignment: Alignment.topCenter, heightFactor: 1 - close, child: body),
        );
      },
      child: RepaintBoundary(key: shot, child: widget.child),
    );
  }
}

class _DustPainter extends CustomPainter {
  _DustPainter(this.image, this.ratio, this.t);
  final ui.Image image;
  final double ratio;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final g = DustOut.grain * ratio;
    final cols = (image.width / g).ceil(), rows = (image.height / g).ceil();
    final transforms = <RSTransform>[];
    final rects = <Rect>[];
    final colors = <Color>[];
    // Same random numbers every frame (seeded by the grain's place).
    double rnd(int i, int salt) {
      final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
      return x - x.floorToDouble();
    }

    final inv = 1 / ratio;
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final i = y * cols + x;
        // Left to right sweep with a little scatter.
        final start = (x / cols) * 0.45 + rnd(i, 1) * 0.12;
        final life = 0.35 + rnd(i, 2) * 0.25;
        final k = ((t - start) / life).clamp(0.0, 1.0);
        if (k >= 1) continue;
        final ease = Curves.easeOut.transform(k);
        final dx = ease * (14 + rnd(i, 3) * 26) + math.sin(k * 6 + i) * 2 * k;
        final dy = -ease * (10 + rnd(i, 4) * 34);
        final scale = inv * (1 - 0.4 * k);
        final px = x * g * inv + dx, py = y * g * inv + dy;
        transforms.add(RSTransform(scale, 0, px, py));
        rects.add(Rect.fromLTWH(x * g, y * g, g, g));
        colors.add(Color.fromRGBO(255, 255, 255, 1 - k * k));
      }
    }
    if (rects.isEmpty) return;
    canvas.drawAtlas(image, transforms, rects, colors, BlendMode.modulate, null, Paint()..filterQuality = FilterQuality.low);
  }

  @override
  bool shouldRepaint(_DustPainter old) => old.t != t || old.image != image;
}
