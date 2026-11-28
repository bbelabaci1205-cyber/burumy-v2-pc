// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Profile photo editor: round crop (pinch and drag), straighten with an
// iPhone-style ruler dial, 10 filters, 13 adjustments, one reset. All on
// the phone; only the finished picture is sent.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'ios_route.dart';

/// 5x4 colour matrices (row-major, 20 numbers), combined right to left.
class Cm {
  static const identity = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];

  /// a after b (b is applied first).
  static List<double> mul(List<double> a, List<double> b) {
    final out = List<double>.filled(20, 0);
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 5; c++) {
        var v = c == 4 ? a[r * 5 + 4] : 0.0;
        for (var k = 0; k < 4; k++) {
          v += a[r * 5 + k] * b[k * 5 + c];
        }
        out[r * 5 + c] = v;
      }
    }
    return out;
  }

  static List<double> all(Iterable<List<double>> ms) => ms.fold(identity, (acc, m) => mul(m, acc));

  static List<double> scale(double s, [double off = 0]) => [s, 0, 0, 0, off, 0, s, 0, 0, off, 0, 0, s, 0, off, 0, 0, 0, 1, 0];
  static List<double> offset(double o) => scale(1, o);
  static List<double> rgb(double r, double g, double b) => [r, 0, 0, 0, 0, 0, g, 0, 0, 0, 0, 0, b, 0, 0, 0, 0, 0, 1, 0];

  static List<double> contrast(double c) => scale(c, 128 * (1 - c));

  static List<double> saturation(double s) {
    const lr = 0.2126, lg = 0.7152, lb = 0.0722;
    final i = 1 - s;
    return [lr * i + s, lg * i, lb * i, 0, 0, lr * i, lg * i + s, lb * i, 0, 0, lr * i, lg * i, lb * i + s, 0, 0, 0, 0, 0, 1, 0];
  }

  static List<double> warmth(double w) => [1 + w * 0.12, 0, 0, 0, w * 10, 0, 1, 0, 0, 0, 0, 0, 1 - w * 0.12, 0, -w * 10, 0, 0, 0, 1, 0];
  static List<double> tint(double t) => [1 + t * 0.06, 0, 0, 0, 0, 0, 1 - t * 0.1, 0, 0, 0, 0, 0, 1 + t * 0.06, 0, 0, 0, 0, 0, 1, 0];
}

/// The 13 adjustments, each -1..1 (0 = untouched).
enum Adjust { exposure, brilliance, highlights, shadows, contrast, brightness, blackPoint, saturation, vibrance, warmth, tint, fade, vignette }

List<double> adjustMatrix(Adjust a, double v) => switch (a) {
  Adjust.exposure => Cm.scale(math.pow(2, v * 1.2).toDouble()),
  Adjust.brilliance => Cm.all([Cm.contrast(1 - v * 0.15), Cm.offset(v * 18)]),
  // Highlights: pull the top down (or push up) while keeping black.
  Adjust.highlights => Cm.scale(1 + v * 0.25),
  // Shadows: lift the bottom while keeping white.
  Adjust.shadows => Cm.scale(1 - v * 0.25, v * 0.25 * 255),
  Adjust.contrast => Cm.contrast(1 + v * 0.6),
  Adjust.brightness => Cm.offset(v * 60),
  Adjust.blackPoint => Cm.scale(1 + v * 0.2, -v * 0.2 * 255),
  Adjust.saturation => Cm.saturation(1 + v),
  Adjust.vibrance => Cm.saturation(1 + v * 0.5),
  Adjust.warmth => Cm.warmth(v),
  Adjust.tint => Cm.tint(v),
  Adjust.fade => Cm.scale(1 - v.abs() * 0.3, v.abs() * 0.3 * 200),
  Adjust.vignette => Cm.identity, // drawn as a soft dark ring instead
};

/// The 10 filters (first = none).
const filterIds = ['none', 'vivid', 'warm', 'cool', 'dramatic', 'mono', 'silver', 'noir', 'fade', 'film'];

List<double> filterMatrix(String id) => switch (id) {
  'vivid' => Cm.all([Cm.saturation(1.35), Cm.contrast(1.1)]),
  'warm' => Cm.all([Cm.warmth(0.6), Cm.saturation(1.15)]),
  'cool' => Cm.all([Cm.warmth(-0.6), Cm.saturation(1.05)]),
  'dramatic' => Cm.all([Cm.contrast(1.35), Cm.saturation(0.85), Cm.offset(-8)]),
  'mono' => Cm.saturation(0),
  'silver' => Cm.all([Cm.saturation(0), Cm.contrast(0.85), Cm.offset(14)]),
  'noir' => Cm.all([Cm.saturation(0), Cm.contrast(1.5), Cm.offset(-10)]),
  'fade' => Cm.all([Cm.scale(0.85, 30), Cm.saturation(0.8)]),
  'film' => Cm.all([Cm.rgb(1.05, 1.0, 0.92), Cm.contrast(1.08), Cm.scale(0.92, 14)]),
  _ => Cm.identity,
};

/// What the auto button needs to know about the photo: the darkest and
/// brightest 1% and the middle of its brightness (0..255), measured on a
/// small copy on this phone.
class AutoStats {
  const AutoStats(this.low, this.high, this.mean);
  final double low, high, mean;

  /// From RGBA bytes (any size).
  static AutoStats of(Uint8List rgba) {
    final hist = List<int>.filled(256, 0);
    var n = 0;
    var sum = 0.0;
    for (var i = 0; i + 3 < rgba.length; i += 4) {
      final y = (0.2126 * rgba[i] + 0.7152 * rgba[i + 1] + 0.0722 * rgba[i + 2]).round().clamp(0, 255);
      hist[y]++;
      sum += y;
      n++;
    }
    if (n == 0) return const AutoStats(0, 255, 128);
    double pct(double q) {
      var acc = 0;
      for (var v = 0; v < 256; v++) {
        acc += hist[v];
        if (acc >= n * q) return v.toDouble();
      }
      return 255;
    }

    return AutoStats(pct(0.01), pct(0.99), sum / n);
  }
}

/// 자동 보정 (Telegram tip 70): one dial that stretches the light range,
/// moves the middle towards normal and adds a little colour, all at once.
/// [v] 0..1.
List<double> autoMatrix(AutoStats s, double v) {
  if (v <= 0) return Cm.identity;
  final range = (s.high - s.low).clamp(40.0, 255.0);
  final stretch = 1 + ((255 / range).clamp(1.0, 1.8) - 1) * v;
  final low = s.low.clamp(0.0, 60.0) * v;
  final mid = (s.mean - low) * stretch;
  final lift = ((128 - mid) * 0.35 * v).clamp(-30.0, 30.0);
  return Cm.all([Cm.scale(stretch, -low * stretch + lift), Cm.saturation(1 + 0.18 * v), Cm.contrast(1 + 0.06 * v)]);
}

/// Everything chosen in the editor.
class EditState {
  String filter = 'none';
  final adjust = {for (final a in Adjust.values) a: 0.0};

  /// 자동 보정 0..1 (needs [stats]; chat photo editor only).
  double auto = 0;
  AutoStats? stats;

  /// Straighten (degrees, -45..45) and quarter turns.
  double angle = 0;
  int quarter = 0;
  bool flipped = false;

  bool get untouched => auto == 0 && filter == 'none' && adjust.values.every((v) => v == 0) && angle == 0 && quarter == 0 && !flipped;

  List<double> matrix() =>
      Cm.all([if (stats != null) autoMatrix(stats!, auto), filterMatrix(filter), for (final a in Adjust.values) adjustMatrix(a, adjust[a]!)]);

  void reset() {
    auto = 0;
    filter = 'none';
    for (final a in Adjust.values) {
      adjust[a] = 0;
    }
    angle = 0;
    quarter = 0;
    flipped = false;
  }
}

/// Opens the editor for a picked photo; returns the finished PNG, or null.
Future<Uint8List?> editProfilePhoto(BuildContext context, Uint8List bytes) =>
    Navigator.of(context, rootNavigator: true).push<Uint8List>(IosPageRoute(fullscreenDialog: true, builder: (_) => PhotoEditorPage(bytes: bytes)));

class PhotoEditorPage extends StatefulWidget {
  const PhotoEditorPage({super.key, required this.bytes, this.outputSize = 1024});
  final Uint8List bytes;
  final int outputSize;
  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

enum _Mode { crop, filter, adjust }

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  final st = EditState();
  final view = TransformationController();
  final shot = GlobalKey();
  _Mode mode = _Mode.crop;
  Adjust tool = Adjust.exposure;
  bool saving = false;

  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _gold = Color(0xFFFFCC00); // iOS Photos yellow for "changed"

  void resetAll() {
    setState(() {
      st.reset();
      view.value = Matrix4.identity();
    });
  }

  Future<void> done() async {
    setState(() => saving = true);
    await WidgetsBinding.instance.endOfFrame;
    final box = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ratio = widget.outputSize / box.size.width;
    final img = await box.toImage(pixelRatio: ratio);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.pop(context, data!.buffer.asUint8List());
  }

  /// The photo with filter, adjustments, turn and flip.
  Widget photo() {
    Widget p = Image.memory(widget.bytes, fit: BoxFit.cover, gaplessPlayback: true);
    p = ColorFiltered(colorFilter: ColorFilter.matrix(st.matrix()), child: p);
    // Straightening zooms in just enough that no corner shows (iPhone).
    final t = st.angle * math.pi / 180;
    final fill = math.cos(t).abs() + math.sin(t).abs();
    p = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ((st.quarter * 90 + st.angle) * math.pi / 180)
        ..scaleByDouble(fill * (st.flipped ? -1.0 : 1.0), fill, 1.0, 1.0),
      child: p,
    );
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      backgroundColor: _black,
      child: SafeArea(
        child: Column(
          children: [
            // Top: cancel · reset · done
            SizedBox(
              height: Tokens.topBar,
              child: Row(
                children: [
                  CupertinoButton(
                    key: const Key('editor-cancel'),
                    // Text-only bar button: no tall default padding (it cut the words off).
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel, style: Tokens.body.style.copyWith(color: _white)),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('editor-reset'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: st.untouched ? null : resetAll,
                    child: Text(l.editorReset, style: Tokens.body.style.copyWith(color: st.untouched ? _white.withValues(alpha: 0.35) : _gold)),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('editor-done'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: saving ? null : done,
                    child: saving
                        ? const CupertinoActivityIndicator(color: _white)
                        : Text(
                            l.done,
                            style: Tokens.body.style.copyWith(color: _gold, fontWeight: FontWeight.w500),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(child: LayoutBuilder(builder: (c, box) => cropArea(box))),
            SizedBox(height: Tokens.space[2]),
            SizedBox(height: 118, child: tools(l)),
            modeBar(l),
          ],
        ),
      ),
    );
  }

  Widget cropArea(BoxConstraints box) {
    final d = math.min(box.maxWidth, box.maxHeight) - Tokens.space[4] * 2;
    return Stack(
      alignment: Alignment.center,
      children: [
        // What gets saved: the square around the circle (shown round).
        SizedBox(
          width: d,
          height: d,
          child: RepaintBoundary(
            key: shot,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InteractiveViewer(
                    key: const Key('editor-photo'),
                    transformationController: view,
                    minScale: 1,
                    maxScale: 6,
                    clipBehavior: Clip.none,
                    child: SizedBox(width: d, height: d, child: photo()),
                  ),
                  if (st.adjust[Adjust.vignette]! != 0)
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              const Color(0x00000000),
                              (st.adjust[Adjust.vignette]! > 0 ? _black : _white).withValues(alpha: st.adjust[Adjust.vignette]!.abs() * 0.6),
                            ],
                            stops: const [0.55, 1],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Dim outside the shapes, thin lines on their edges (iOS contact photo).
        IgnorePointer(
          child: CustomPaint(size: Size(box.maxWidth, box.maxHeight), painter: _CircleMask(d / 2)),
        ),
      ],
    );
  }

  Widget tools(L l) {
    switch (mode) {
      case _Mode.crop:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundIcon(key: const Key('editor-rotate'), icon: CupertinoIcons.rotate_left, onTap: () => setState(() => st.quarter = (st.quarter + 3) % 4)),
                SizedBox(width: Tokens.space[4]),
                Text(
                  '${st.angle.round()}°',
                  key: const Key('editor-angle'),
                  style: Tokens.caption.style.copyWith(color: st.angle == 0 ? _white : _gold),
                ),
                SizedBox(width: Tokens.space[4]),
                _RoundIcon(key: const Key('editor-flip'), icon: CupertinoIcons.arrow_left_right, onTap: () => setState(() => st.flipped = !st.flipped)),
              ],
            ),
            SizedBox(height: Tokens.space[1]),
            RulerDial(key: const Key('editor-dial'), value: st.angle / 45, onChanged: (v) => setState(() => st.angle = v * 45)),
          ],
        );
      case _Mode.filter:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          itemCount: filterIds.length,
          separatorBuilder: (_, _) => SizedBox(width: Tokens.space[1]),
          itemBuilder: (_, i) {
            final id = filterIds[i];
            final on = st.filter == id;
            return GestureDetector(
              key: Key('filter-$id'),
              onTap: () => setState(() => st.filter = id),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(filterName(l, id), style: Tokens.bubbleMeta.style.copyWith(color: on ? _white : _white.withValues(alpha: 0.6))),
                  SizedBox(height: Tokens.space[0] + 2),
                  // iOS lift for the chosen one: slightly larger, soft shadow.
                  AnimatedScale(
                    scale: on ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Tokens.radius[0]),
                        boxShadow: on ? const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))] : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(filterMatrix(id)),
                        child: Image.memory(widget.bytes, fit: BoxFit.cover, cacheWidth: 160),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case _Mode.adjust:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${adjustName(l, tool)}  ${(st.adjust[tool]! * 100).round()}',
              key: const Key('adjust-label'),
              style: Tokens.caption.style.copyWith(color: _white),
            ),
            SizedBox(height: Tokens.space[1]),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                itemCount: Adjust.values.length,
                separatorBuilder: (_, _) => SizedBox(width: Tokens.space[1]),
                itemBuilder: (_, i) {
                  final a = Adjust.values[i];
                  final v = st.adjust[a]!;
                  final on = a == tool;
                  return GestureDetector(
                    key: Key('adjust-${a.name}'),
                    onTap: () => setState(() => tool = a),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: on ? _white.withValues(alpha: 0.18) : null,
                        border: Border.all(color: v != 0 ? _gold : _white.withValues(alpha: on ? 0.9 : 0.35), width: 1.4),
                      ),
                      child: Icon(adjustIcon(a), size: 20, color: v != 0 ? _gold : _white),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            RulerDial(key: const Key('adjust-dial'), value: st.adjust[tool]!, onChanged: (v) => setState(() => st.adjust[tool] = v)),
          ],
        );
    }
  }

  Widget modeBar(L l) {
    Widget tab(_Mode m, IconData i, String label) {
      final on = mode == m;
      return Expanded(
        child: CupertinoButton(
          key: Key('editor-mode-${m.name}'),
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          onPressed: () => setState(() => mode = m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: Tokens.listIcon, color: on ? _gold : _white.withValues(alpha: 0.6)),
              const SizedBox(height: 2),
              Text(label, style: Tokens.bubbleMeta.style.copyWith(color: on ? _gold : _white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(_Mode.crop, CupertinoIcons.crop_rotate, l.editorCrop),
        tab(_Mode.filter, CupertinoIcons.circle_grid_hex, l.editorFilters),
        tab(_Mode.adjust, CupertinoIcons.slider_horizontal_3, l.editorAdjust),
      ],
    );
  }
}

String filterName(L l, String id) => switch (id) {
  'vivid' => l.filterVivid,
  'warm' => l.filterWarm,
  'cool' => l.filterCool,
  'dramatic' => l.filterDramatic,
  'mono' => l.filterMono,
  'silver' => l.filterSilver,
  'noir' => l.filterNoir,
  'fade' => l.filterFade,
  'film' => l.filterFilm,
  _ => l.filterNone,
};

String adjustName(L l, Adjust a) => switch (a) {
  Adjust.exposure => l.adjExposure,
  Adjust.brilliance => l.adjBrilliance,
  Adjust.highlights => l.adjHighlights,
  Adjust.shadows => l.adjShadows,
  Adjust.contrast => l.adjContrast,
  Adjust.brightness => l.adjBrightness,
  Adjust.blackPoint => l.adjBlackPoint,
  Adjust.saturation => l.adjSaturation,
  Adjust.vibrance => l.adjVibrance,
  Adjust.warmth => l.adjWarmth,
  Adjust.tint => l.adjTint,
  Adjust.fade => l.adjFade,
  Adjust.vignette => l.adjVignette,
};

IconData adjustIcon(Adjust a) => switch (a) {
  Adjust.exposure => CupertinoIcons.plusminus_circle,
  Adjust.brilliance => CupertinoIcons.sparkles,
  Adjust.highlights => CupertinoIcons.circle_lefthalf_fill,
  Adjust.shadows => CupertinoIcons.circle_righthalf_fill,
  Adjust.contrast => CupertinoIcons.square_split_1x2,
  Adjust.brightness => CupertinoIcons.sun_max,
  Adjust.blackPoint => CupertinoIcons.circle_fill,
  Adjust.saturation => CupertinoIcons.drop,
  Adjust.vibrance => CupertinoIcons.drop_triangle,
  Adjust.warmth => CupertinoIcons.thermometer,
  Adjust.tint => CupertinoIcons.eyedropper,
  Adjust.fade => CupertinoIcons.cloud_fog,
  Adjust.vignette => CupertinoIcons.smallcircle_circle,
};

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: onTap,
    child: Icon(icon, color: const Color(0xFFFFFFFF), size: Tokens.listIcon + 2),
  );
}

/// Both shapes a viewer may pick (Eric 2026-11-26, 설정 > 모양 > 프로필
/// 모양): dark outside the rounded square, lightly dimmed corners that only
/// the circle cuts off, and a thin line on each edge.
class _CircleMask extends CustomPainter {
  _CircleMask(this.r);
  final double r;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final box = Rect.fromCircle(center: c, radius: r);
    final rounded = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(2 * r * Tokens.roomKakaoCorner)).getOuterPath(box);
    final circle = Path()..addOval(box);
    canvas.drawPath(Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), rounded), Paint()..color = const Color(0x99000000));
    canvas.drawPath(Path.combine(PathOperation.difference, rounded, circle), Paint()..color = const Color(0x40000000));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(rounded, line..color = const Color(0x4DFFFFFF));
    canvas.drawCircle(c, r, line..color = const Color(0x80FFFFFF));
  }

  @override
  bool shouldRepaint(_CircleMask old) => old.r != r;
}

/// iPhone-style ruler dial: drag sideways, ticks move under a fixed centre
/// line, light tick at every step, snaps to 0 near the middle. -1..1.
class RulerDial extends StatelessWidget {
  const RulerDial({super.key, required this.value, required this.onChanged});
  final double value;
  final ValueChanged<double> onChanged;

  /// Pixels for the whole -1..1 range.
  static const span = 300.0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onHorizontalDragUpdate: (d) {
      var v = (value - d.delta.dx / (span / 2)).clamp(-1.0, 1.0);
      if (v.abs() < 0.02) v = 0;
      onChanged(v);
    },
    onDoubleTap: () => onChanged(0),
    child: SizedBox(
      height: 36,
      width: double.infinity,
      child: CustomPaint(painter: _Ruler(value)),
    ),
  );
}

class _Ruler extends CustomPainter {
  _Ruler(this.v);
  final double v;
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final step = RulerDial.span / 2 / 20; // 20 ticks per half
    final shift = -v * RulerDial.span / 2;
    final tick = Paint()..strokeWidth = 1;
    for (var i = -20; i <= 20; i++) {
      final x = mid + i * step + shift;
      if (x < 0 || x > size.width) continue;
      final big = i % 5 == 0;
      final fadeOut = 1 - ((x - mid).abs() / mid).clamp(0.0, 1.0);
      tick.color = Color.fromRGBO(255, 255, 255, (big ? 0.85 : 0.45) * fadeOut);
      final h = big ? 14.0 : 8.0;
      canvas.drawLine(Offset(x, size.height / 2 - h / 2), Offset(x, size.height / 2 + h / 2), tick);
    }
    // Zero dot, and the fixed centre line.
    final zx = mid + shift;
    if (zx >= 0 && zx <= size.width) canvas.drawCircle(Offset(zx, 3), 2, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawLine(
      Offset(mid, 4),
      Offset(mid, size.height - 4),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = v == 0 ? const Color(0xFFFFFFFF) : const Color(0xFFFFCC00),
    );
  }

  @override
  bool shouldRepaint(_Ruler old) => old.v != v;
}
