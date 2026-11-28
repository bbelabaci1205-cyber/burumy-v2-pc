// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채팅 안에서 바로 핀치 확대 (Telegram tip 273): spread two fingers on a
// photo or video in the chat and it lifts above everything and grows under
// the fingers; let go and it springs back into its bubble (iPhone Photos
// feel). One finger still scrolls the chat, taps and holds still work.
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';

import '../core/features.dart';

/// Only wins when a second finger joins (one finger = the chat scrolls).
class TwoFingerScaleRecognizer extends ScaleGestureRecognizer {
  TwoFingerScaleRecognizer({super.debugOwner});
  int _down = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    _down++;
    _fingers++;
    // Two fingers on the picture: take the gesture right away, before the
    // chat list starts scrolling with the first one.
    if (_down >= 2) super.resolve(GestureDisposition.accepted);
  }

  @override
  void resolve(GestureDisposition disposition) {
    // One finger moving is a scroll, never a zoom.
    if (disposition == GestureDisposition.accepted && _down < 2) return;
    super.resolve(disposition);
  }

  /// Fingers still on the screen (for telling "one left" from "all up").
  int get fingers => _fingers;
  int _fingers = 0;

  @override
  void handleEvent(PointerEvent event) {
    final up = event is PointerUpEvent || event is PointerCancelEvent;
    if (up) _fingers = (_fingers - 1).clamp(0, 99);
    super.handleEvent(event);
    // The last finger left without a scale end (it had stopped moving).
    if (up && _fingers == 0) onAllUp?.call();
  }

  /// Every finger is off the screen.
  VoidCallback? onAllUp;

  @override
  void didStopTrackingLastPointer(int pointer) {
    _down = 0;
    _fingers = 0;
    super.didStopTrackingLastPointer(pointer);
  }
}

class PinchZoom extends StatefulWidget {
  const PinchZoom({super.key, required this.child, this.enabled = true, this.radius = 0});
  final Widget child;
  final bool enabled;

  /// Corner rounding of the lifted copy (the bubble's).
  final double radius;

  /// Biggest growth.
  static const maxScale = 4.0;

  @override
  State<PinchZoom> createState() => _PinchZoomState();
}

class _PinchZoomState extends State<PinchZoom> with SingleTickerProviderStateMixin {
  final shot = GlobalKey();
  TwoFingerScaleRecognizer? recognizer;
  OverlayEntry? entry;
  ui.Image? picture;
  Rect from = Rect.zero;
  Offset startFocal = Offset.zero, segFocal = Offset.zero, shift = Offset.zero, baseShift = Offset.zero;
  double scale = 1, baseScale = 1;
  bool lifted = false;
  late final back = AnimationController.unbounded(vsync: this);
  double backFrom = 1;
  Offset backShift = Offset.zero;

  @override
  void dispose() {
    back.dispose();
    entry?.remove();
    entry = null;
    picture?.dispose();
    super.dispose();
  }

  void start(ScaleStartDetails d) {
    if (back.isAnimating) return;
    if (lifted) {
      // A finger joined or left: carry on from where the picture is.
      baseScale = scale;
      baseShift = shift;
      segFocal = d.focalPoint;
      return;
    }
    final box = shot.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (box == null || !box.hasSize) return;
    final view = View.of(context);
    // Sharp when grown: drawn at a higher resolution than the screen.
    final ratio = (view.devicePixelRatio * 2.5).clamp(1.0, 2600 / box.size.longestSide.clamp(1, 9999));
    try {
      picture = box.toImageSync(pixelRatio: ratio);
    } catch (_) {
      return;
    }
    from = box.localToGlobal(Offset.zero) & box.size;
    startFocal = d.focalPoint;
    segFocal = d.focalPoint;
    scale = baseScale = 1;
    shift = baseShift = Offset.zero;
    setState(() => lifted = true);
    entry = OverlayEntry(builder: (_) => lift());
    Overlay.of(context, rootOverlay: true).insert(entry!);
  }

  void update(ScaleUpdateDetails d) {
    if (!lifted || back.isAnimating) return;
    scale = (baseScale * d.scale).clamp(0.8, PinchZoom.maxScale);
    shift = baseShift + (d.focalPoint - segFocal);
    entry?.markNeedsBuild();
  }

  void end(ScaleEndDetails d) {
    if (!lifted || back.isAnimating) return;
    // Fingers still down: only one of them left (start() follows).
    if ((recognizer?.fingers ?? 0) > 0) return;
    release(d.scaleVelocity);
  }

  /// "Release to close": spring back into the bubble.
  void release([double velocity = 0]) {
    if (!lifted || back.isAnimating) return;
    backFrom = scale;
    backShift = shift;
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 520, ratio: 0.82);
    back.value = 1;
    back.addListener(_relayout);
    back.animateWith(SpringSimulation(spring, 1, 0, -velocity.clamp(-4.0, 4.0))).whenCompleteOrCancel(drop);
  }

  void _relayout() => entry?.markNeedsBuild();

  void drop() {
    back.removeListener(_relayout);
    entry?.remove();
    entry = null;
    picture?.dispose();
    picture = null;
    if (mounted) setState(() => lifted = false);
  }

  /// The lifted copy over the whole app, with the chat dimmed behind.
  Widget lift() {
    final img = picture;
    if (img == null) return const SizedBox.shrink();
    // While springing back: k goes 1 → 0 (with a little overshoot).
    final k = back.isAnimating ? back.value : 1.0;
    final s = back.isAnimating ? 1 + (backFrom - 1) * k : scale;
    final move = back.isAnimating ? backShift * k : shift;
    // Grow around the point between the fingers.
    final anchor = startFocal - from.topLeft;
    final topLeft = from.topLeft + move + anchor - anchor * s;
    final dim = ((s - 1) / 1.5).clamp(0.0, 1.0) * 0.55;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: Color.fromRGBO(0, 0, 0, dim))),
          Positioned(
            left: topLeft.dx,
            top: topLeft.dy,
            width: from.width * s,
            height: from.height * s,
            child: ClipRRect(
              key: const Key('pinch-lifted'),
              borderRadius: BorderRadius.circular(widget.radius * s.clamp(1.0, 1.6)),
              child: RawImage(image: img, fit: BoxFit.fill, filterQuality: FilterQuality.medium),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = RepaintBoundary(
      key: shot,
      // The copy flies; the bubble keeps its place, empty.
      child: Opacity(opacity: lifted ? 0 : 1, child: widget.child),
    );
    if (!widget.enabled || !Features.photoSend) return body;
    return RawGestureDetector(
      gestures: {
        TwoFingerScaleRecognizer: GestureRecognizerFactoryWithHandlers<TwoFingerScaleRecognizer>(
          () => recognizer = TwoFingerScaleRecognizer(debugOwner: this),
          (r) => r
            ..onStart = start
            ..onUpdate = update
            ..onEnd = end
            ..onAllUp = release,
        ),
      },
      child: body,
    );
  }
}
