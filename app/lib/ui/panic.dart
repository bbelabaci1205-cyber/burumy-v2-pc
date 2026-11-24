// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Two-finger double tap anywhere = panic (Settings > Privacy). Watches raw
// touches only; never blocks them.
import 'package:flutter/widgets.dart';

class PanicListener extends StatefulWidget {
  const PanicListener({super.key, required this.onPanic, required this.child});
  final VoidCallback onPanic;
  final Widget child;

  @override
  State<PanicListener> createState() => _PanicListenerState();
}

class _PanicListenerState extends State<PanicListener> {
  final _down = <int, Offset>{};
  DateTime? _twoAt;
  bool _moved = false;
  DateTime? _lastTap;

  void _onDown(PointerDownEvent e) {
    _down[e.pointer] = e.position;
    if (_down.length == 2) {
      _twoAt = DateTime.now();
      _moved = false;
    } else if (_down.length > 2) {
      _twoAt = null;
    }
  }

  void _onMove(PointerMoveEvent e) {
    final start = _down[e.pointer];
    if (start != null && (e.position - start).distance > 18) _moved = true;
  }

  void _onUp(PointerEvent e) {
    _down.remove(e.pointer);
    if (_down.isNotEmpty) return;
    final at = _twoAt;
    _twoAt = null;
    if (at == null || _moved) return;
    final now = DateTime.now();
    if (now.difference(at) > const Duration(milliseconds: 300)) return;
    final last = _lastTap;
    if (last != null && now.difference(last) < const Duration(milliseconds: 500)) {
      _lastTap = null;
      widget.onPanic();
    } else {
      _lastTap = now;
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: _onDown,
    onPointerMove: _onMove,
    onPointerUp: _onUp,
    onPointerCancel: _onUp,
    child: widget.child,
  );
}
