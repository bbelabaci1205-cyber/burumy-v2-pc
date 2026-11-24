// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// iOS 26/27 page motion: the same slide-in as iPhone, and a swipe back that
// starts anywhere on the page (not only at the left edge). Controls that
// drag sideways themselves (sliders, swipe-to-reply, list swipe buttons)
// sit deeper in the page and win their own drags first.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

class IosPageRoute<T> extends CupertinoPageRoute<T> {
  IosPageRoute({required super.builder, super.settings, super.fullscreenDialog, super.maintainState, super.title});

  AnimationController get _ctrl => controller!;

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final t = super.buildTransitions(context, animation, secondaryAnimation, child);
    if (fullscreenDialog) return t;
    return _SwipeBack(route: this, child: t);
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

  void _end(DragEndDetails d) {
    if (!active) return;
    active = false;
    final c = widget.route._ctrl;
    final nav = widget.route.navigator!;
    final w = context.size?.width ?? 1;
    final v = (d.primaryVelocity ?? 0) / w; // screen widths per second
    final stay = v.abs() >= 1 ? v <= 0 : c.value > 0.5;
    const curve = Curves.fastEaseInToSlowEaseOut;
    const time = Duration(milliseconds: 350);
    if (stay) {
      c.animateTo(1, duration: time, curve: curve);
    } else {
      nav.pop();
      if (c.isAnimating) c.animateBack(0, duration: time, curve: curve);
    }
    if (c.isAnimating) {
      late AnimationStatusListener done;
      done = (_) {
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
