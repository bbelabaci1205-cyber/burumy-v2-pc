// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screen capture guard for view-once photos and bubbles. Android: the
// screen is black in screenshots and recordings. iPhone: screenshots can't
// be blocked by apps, but while the screen is recorded or mirrored the
// content is covered.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class ScreenGuard {
  static const _ch = MethodChannel('app.burumy/screen');
  static int _holds = 0;
  static final captured = ValueNotifier<bool>(false);
  static bool _listening = false;

  static Future<void> hold() async {
    _holds++;
    _listen();
    if (_holds == 1) await _call('secure', true);
    try {
      captured.value = await _ch.invokeMethod<bool>('captured') ?? false;
    } catch (_) {}
  }

  static Future<void> release() async {
    if (_holds == 0) return;
    _holds--;
    if (_holds == 0) await _call('secure', false);
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _ch.setMethodCallHandler((c) async {
      if (c.method == 'capturedChanged') captured.value = c.arguments == true;
    });
  }

  static Future<void> _call(String m, Object? a) async {
    try {
      await _ch.invokeMethod(m, a);
    } catch (_) {
      // No native side (tests, web): nothing to block.
    }
  }
}

/// Wraps secret content: blocks capture while shown, and covers it while
/// the screen is being recorded.
class CaptureBlock extends StatefulWidget {
  const CaptureBlock({super.key, required this.child});
  final Widget child;
  @override
  State<CaptureBlock> createState() => _CaptureBlockState();
}

class _CaptureBlockState extends State<CaptureBlock> {
  @override
  void initState() {
    super.initState();
    ScreenGuard.hold();
  }

  @override
  void dispose() {
    ScreenGuard.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: ScreenGuard.captured,
    builder: (_, cap, child) => cap ? const ColoredBox(key: Key('capture-cover'), color: Color(0xFF000000)) : child!,
    child: widget.child,
  );
}
