// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// iOS 26/27 page motion: the same slide-in as iPhone, and a swipe back that
// starts anywhere on the page (not only at the left edge). Controls that
// drag sideways themselves (sliders, swipe-to-reply, list swipe buttons)
// sit deeper in the page and win their own drags first.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';

import '../design/tokens.dart';

class IosPageRoute<T> extends CupertinoPageRoute<T> {
  IosPageRoute({required super.builder, super.settings, super.fullscreenDialog, super.maintainState, super.title, this.enterUp = false});

  /// 다음 채널 (Telegram): this page comes up from below the first time it
  /// opens, while the one before it leaves upward ([exitUp]). After that it
  /// moves like any page (swipe back goes sideways).
  final bool enterUp;

  /// Set just before popping: this page leaves upward instead of sideways.
  bool exitUp = false;

  AnimationController get _ctrl => controller!;

  static const _upCurve = Curves.fastEaseInToSlowEaseOut;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    if (fullscreenDialog) return super.buildTransitions(context, animation, secondaryAnimation, child);
    // The same widgets every frame (only the numbers change), so the page
    // keeps its state when the up move ends.
    bool goingUp() => enterUp && animation.status == AnimationStatus.forward && !navigator!.userGestureInProgress;
    bool leavingUp() => exitUp && animation.status == AnimationStatus.reverse;
    final t = super.buildTransitions(context, goingUp() || leavingUp() ? kAlwaysCompleteAnimation : animation, secondaryAnimation, child);
    return AnimatedBuilder(
      animation: animation,
      child: _SwipeBack(route: this, child: t),
      builder: (context, c) {
        final h = MediaQuery.sizeOf(context).height;
        var dy = 0.0;
        if (goingUp()) dy = (1 - _upCurve.transform(animation.value)) * h;
        if (leavingUp()) dy = -_upCurve.transform(1 - animation.value) * h;
        return Transform.translate(offset: Offset(0, dy), child: c);
      },
    );
  }
}

/// Only rightward drags start a swipe back.
class _RightwardDrag extends HorizontalDragGestureRecognizer {
  _RightwardDrag({super.debugOwner});
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
      _dx > computeHitSlop(pointerDeviceKind, gestureSettings) && super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop);
}

class _SwipeBack extends StatefulWidget {
  const _SwipeBack({required this.route, required this.child});
  final IosPageRoute<dynamic> route;
  final Widget child;

  @override
  State<_SwipeBack> createState() => _SwipeBackState();
}

class _SwipeBackState extends State<_SwipeBack> {
  late final _RightwardDrag drag = _RightwardDrag(debugOwner: this)
    ..onStart = _start
    ..onUpdate = _update
    ..onEnd = _end
    ..onCancel = _cancel;
  bool active = false;

  bool get _allowed => widget.route.isCurrent && widget.route.popGestureEnabled && !widget.route.navigator!.userGestureInProgress;

  void _start(DragStartDetails d) {
    if (!_allowed) return;
    active = true;
    widget.route.navigator!.didStartUserGesture();
  }

  void _update(DragUpdateDetails d) {
    if (!active) return;
    final w = context.size?.width ?? 1;
    widget.route._ctrl.value -= (d.primaryDelta ?? 0) / w;
  }

  /// Telegram / iOS 26 rule: where the page would be [Tokens.backProject]
  /// seconds after letting go decides; it closes past [Tokens.backFinish] pt
  /// or half the width (whichever is less). Then a spring (damping 0.85,
  /// about 0.3 s) carries it on at the finger's speed, without overshoot.
  void _end(DragEndDetails d) {
    if (!active) return;
    active = false;
    final c = widget.route._ctrl;
    final nav = widget.route.navigator!;
    final w = context.size?.width ?? 1;
    final v = (d.primaryVelocity ?? 0) / w; // widths per second, + = closing
    final shown = 1 - c.value; // how far the page has been pulled aside
    final projected = shown + v * Tokens.backProject;
    final close = projected > (Tokens.backFinish / w).clamp(0.0, 0.5);
    final omega = 2 * 3.141592653589793 / Tokens.backResponse;
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: omega * omega, ratio: Tokens.backDamping);
    if (close) {
      nav.pop();
      c.animateBackWith(SpringSimulation(spring, c.value, 0, -v, tolerance: const Tolerance(distance: 0.001, velocity: 0.01)));
    } else {
      c.animateWith(SpringSimulation(spring, c.value, 1, -v, tolerance: const Tolerance(distance: 0.001, velocity: 0.01)));
    }
    if (c.isAnimating) {
      late AnimationStatusListener done;
      done = (st) {
        if (st == AnimationStatus.forward || st == AnimationStatus.reverse) return;
        nav.didStopUserGesture();
        c.removeStatusListener(done);
      };
      c.addStatusListener(done);
    } else {
      nav.didStopUserGesture();
    }
  }

  void _cancel() {
    if (!active) return;
    active = false;
    final c = widget.route._ctrl;
    c.animateTo(1, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    widget.route.navigator!.didStopUserGesture();
  }

  @override
  void dispose() {
    drag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) {
      if (_allowed) drag.addPointer(e);
    },
    child: widget.child,
  );
}
