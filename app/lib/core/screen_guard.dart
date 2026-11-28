// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screen capture guard for view-once photos and bubbles. Android: the
// screen is black in screenshots and recordings. iPhone: screenshots can't
// be blocked by apps, but while the screen is recorded or mirrored the
// content is covered. With Features.chatSafety (557) the iPhone also draws
// the app inside a secure text layer while held, so screenshots come out
// blank (the trick Telegram uses; needs checking on a real iPhone build).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'features.dart';

class ScreenGuard {
  static const _ch = MethodChannel('app.burumy/screen');
  static int _holds = 0;

  /// What protected things are on screen now (newest last): chat, photo,
  /// video, voice, round, file or bubble.
  static final _what = <String>[];

  /// 캡처 알림 (core/shot_alert.dart): the phone took a screenshot while
  /// something protected was showing (iPhone; Android blocks it instead).
  /// Set by the app; gets what was on screen.
  static void Function(String what)? onShot;

  /// Tests: as if the phone just said a screenshot was taken.
  static void debugShot() => _shot();

  static void _shot() {
    if (_holds == 0 || _what.isEmpty) return;
    onShot?.call(_what.last);
  }

  static final captured = ValueNotifier<bool>(false);
  static bool _listening = false;

  static Future<void> hold([String what = 'chat']) async {
    _holds++;
    _what.add(what);
    _listen();
    if (_holds == 1) {
      await _call('secure', true);
      if (Features.chatSafety) await _call('shield', true);
    }
    try {
      captured.value = await _ch.invokeMethod<bool>('captured') ?? false;
    } catch (_) {}
  }

  static Future<void> release([String what = 'chat']) async {
    if (_holds == 0) return;
    _holds--;
    final i = _what.lastIndexOf(what);
    if (i >= 0) _what.removeAt(i);
    if (_holds == 0) {
      await _call('secure', false);
      if (Features.chatSafety) await _call('shield', false);
    }
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _ch.setMethodCallHandler((c) async {
      if (c.method == 'capturedChanged') captured.value = c.arguments == true;
      if (c.method == 'screenshot') _shot();
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
  const CaptureBlock({super.key, required this.child, this.what = 'photo'});
  final Widget child;

  /// What it is, for 캡처 알림: photo, video, voice, round, file or bubble.
  final String what;
  @override
  State<CaptureBlock> createState() => _CaptureBlockState();
}

class _CaptureBlockState extends State<CaptureBlock> {
  @override
  void initState() {
    super.initState();
    ScreenGuard.hold(widget.what);
  }

  @override
  void dispose() {
    ScreenGuard.release(widget.what);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: ScreenGuard.captured,
    builder: (_, cap, child) => cap ? const ColoredBox(key: Key('capture-cover'), color: Color(0xFF000000)) : child!,
    child: widget.child,
  );
}

/// 공유 비활성화 (v1 parity): while [on], the whole chat blocks capture and
/// is covered during screen recording. Always in the tree so switching it
/// keeps the chat's state.
class CaptureGuard extends StatefulWidget {
  const CaptureGuard({super.key, required this.on, required this.child});
  final bool on;
  final Widget child;
  @override
  State<CaptureGuard> createState() => _CaptureGuardState();
}

class _CaptureGuardState extends State<CaptureGuard> {
  bool held = false;

  void sync() {
    if (widget.on && !held) {
      held = true;
      ScreenGuard.hold();
    } else if (!widget.on && held) {
      held = false;
      ScreenGuard.release();
    }
  }

  @override
  void initState() {
    super.initState();
    sync();
  }

  @override
  void didUpdateWidget(CaptureGuard old) {
    super.didUpdateWidget(old);
    sync();
  }

  @override
  void dispose() {
    if (held) ScreenGuard.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: ScreenGuard.captured,
    builder: (_, cap, child) => Stack(
      children: [
        child!,
        if (cap && widget.on)
          const Positioned.fill(
            child: ColoredBox(key: Key('protect-cover'), color: Color(0xFF000000)),
          ),
      ],
    ),
    child: widget.child,
  );
}
