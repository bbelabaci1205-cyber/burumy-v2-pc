// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 밀어서 답장 (Telegram iOS feel, numbers in design/tokens.dart): the bubble
// follows the finger to the left, a small round reply mark grows in on the
// right, one firm tap when it is far enough, and letting go there starts a
// reply. Past the point the bubble is held back (rubber band). Only leftward
// drags start it, so a rightward swipe still goes back a page.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../design/tokens.dart';
import 'common.dart';

class SwipeReply extends StatefulWidget {
  const SwipeReply({super.key, required this.child, required this.mine, this.onReply});
  final Widget child;

  /// My bubble needs a longer pull (60 pt, others' 45 pt), as in Telegram.
  final bool mine;

  /// Null = swiping does nothing (switched off, or no right to reply).
  final VoidCallback? onReply;

  @override
  State<SwipeReply> createState() => _SwipeReplyState();
}

/// Only leftward drags.
class _LeftwardDrag extends HorizontalDragGestureRecognizer {
  _LeftwardDrag({super.debugOwner});
  double _dx = 0;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _dx = 0;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _dx += event.delta.dx;
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) =>
      _dx < -computeHitSlop(pointerDeviceKind, gestureSettings) && super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop);
}

class _SwipeReplyState extends State<SwipeReply> with SingleTickerProviderStateMixin {
  late final anim = AnimationController.unbounded(vsync: this);
  double raw = 0;
  bool ticked = false;

  double get point => widget.mine ? Tokens.replyOut : Tokens.replyIn;

  /// Telegram's rubber band: free up to [point], then 40 % and easing off.
  double band(double d) {
    if (d < point) return d;
    const range = 100.0, k = 0.4;
    return point + (1 - 1 / ((d - point) * k / range + 1)) * range;
  }

  void update(DragUpdateDetails d) {
    raw = math.min(0, raw + d.delta.dx);
    anim.value = -math.min(Tokens.replyMax, band(-raw));
    if (-anim.value >= point && !ticked) {
      ticked = true;
      HapticFeedback.heavyImpact();
    }
  }

  void end([DragEndDetails? _]) {
    if (-raw > point) widget.onReply?.call();
    raw = 0;
    ticked = false;
    // Back in about 0.3 s on a spring.
    const omega = 2 * math.pi / 0.3;
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: omega * omega, ratio: 1);
    anim.animateWith(SpringSimulation(spring, anim.value, 0, 0, tolerance: const Tolerance(distance: 0.3, velocity: 3))).whenComplete(() {
      if (mounted) anim.value = 0;
    });
  }

  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onReply == null) return widget.child;
    final p = paletteOf(context);
    return RawGestureDetector(
      gestures: {
        _LeftwardDrag: GestureRecognizerFactoryWithHandlers<_LeftwardDrag>(
          () => _LeftwardDrag(debugOwner: this),
          (r) => r
            ..onUpdate = update
            ..onEnd = end
            ..onCancel = end,
        ),
      },
      child: AnimatedBuilder(
        animation: anim,
        child: widget.child,
        builder: (context, c) {
          final x = anim.value;
          final t = (-x / point).clamp(0.0, 1.0);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Transform.translate(offset: Offset(x, 0), child: c),
              if (x < 0)
                Positioned(
                  // Telegram: the mark rides just past the bubble's side
                  // (10 pt after mine, 24 pt over the edge for others').
                  right: -x - Tokens.replyIcon - (widget.mine ? 10 : -24),
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Opacity(
                      opacity: t,
                      child: Transform.scale(
                        scale: 0.2 + 0.8 * t,
                        child: Container(
                          key: const Key('swipe-reply-mark'),
                          width: Tokens.replyIcon,
                          height: Tokens.replyIcon,
                          decoration: BoxDecoration(
                            color: p.label.withValues(alpha: t >= 1 ? 0.28 : 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(CupertinoIcons.arrowshape_turn_up_left_fill, size: 17, color: Color(0xFFFFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// What a message bubble reacts to, in one widget: tap, a 0.32 s hold for
/// the menu (Telegram; Flutter's own is 0.5 s) and swipe left to reply.
class BubbleGestures extends StatelessWidget {
  const BubbleGestures({super.key, required this.child, required this.mine, this.onTap, this.onLongPress, this.onReply});
  final Widget child;
  final bool mine;
  final VoidCallback? onTap, onLongPress, onReply;

  @override
  Widget build(BuildContext context) => SwipeReply(
    mine: mine,
    onReply: onReply,
    child: RawGestureDetector(
      gestures: {
        if (onLongPress != null)
          LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
            () => LongPressGestureRecognizer(duration: Tokens.holdTime, debugOwner: this),
            (r) => r.onLongPress = onLongPress,
          ),
        if (onTap != null)
          TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(debugOwner: this),
            (r) => r.onTap = onTap,
          ),
      },
      child: child,
    ),
  );
}
