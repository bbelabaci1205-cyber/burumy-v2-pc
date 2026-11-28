// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 작은 화면으로 보기 (Telegram tips 334 + 103, batch #10, 2026-11-27): the
// player's ⧉ button shrinks the video into a small rounded window that
// floats over every screen of the app, so I can chat while it plays.
// - drag it anywhere; let go and it moves to the nearest corner;
// - two fingers make it bigger or smaller;
// - throw it off the side of the screen to close it;
// - tap it for play / pause, ✕ and ⤢ (back to full screen).
// It closes with the app lock and account switch (AppState.onStop), and
// is never offered for 한 번만 보기 videos.
// Outside the app (iPhone's own picture-in-picture over other apps) needs
// the phone's video layer: noted for the real-device build.
import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import 'glass.dart';

/// What the full-screen player hands to the window (and gets back).
class FloatHandoff {
  FloatHandoff({required this.controller, this.temp, required this.reopen, this.onClose});
  final VideoPlayerController controller;

  /// The decrypted temp file on phones (removed when the window closes).
  final File? temp;

  /// Builds the full-screen player again around [controller].
  final Widget Function(FloatHandoff h) reopen;

  /// Where it stopped, for 이어보기.
  final void Function(Duration at, Duration total)? onClose;
}

class FloatVideo {
  const FloatVideo._();
  static OverlayEntry? _entry;
  static FloatHandoff? _now;
  static bool _hooked = false;

  /// Window width at scale 1, and the scale range for two fingers.
  static const baseWidth = 200.0, minScale = 0.7, maxScale = 1.7;

  static bool get showing => _entry != null;

  static void show(BuildContext context, FloatHandoff h) {
    close();
    if (!_hooked) {
      _hooked = true;
      AppState.onStop.add(close);
    }
    _now = h;
    final was = h.controller.value.isPlaying;
    final overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(builder: (_) => _FloatWindow(h: h));
    overlay.insert(_entry!);
    // Web: the browser pauses a video when it moves on the page; keep going.
    if (was) _keepPlaying(h, () => _now == h);
  }

  static void _keepPlaying(FloatHandoff h, bool Function() still) {
    for (final ms in const [150, 600]) {
      Future.delayed(Duration(milliseconds: ms), () {
        try {
          if (still() && h.controller.value.isInitialized && !h.controller.value.isPlaying) unawaited(h.controller.play().catchError((_) {}));
        } catch (_) {} // closed meanwhile
      });
    }
  }

  /// ✕, thrown away, app locked: stops and frees the video.
  static void close() {
    final h = _now;
    _entry?.remove();
    _entry = null;
    _now = null;
    if (h == null) return;
    final v = h.controller.value;
    if (v.isInitialized) h.onClose?.call(v.position, v.duration);
    unawaited(h.controller.dispose());
    final f = h.temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
  }

  /// ⤢: the same video (same spot, still playing) full screen again.
  static Future<void> expand(BuildContext context) async {
    final h = _now;
    if (h == null) return;
    final was = h.controller.value.isPlaying;
    _entry?.remove();
    _entry = null;
    _now = null;
    if (was) _keepPlaying(h, () => _now == null);
    await Navigator.of(context, rootNavigator: true).push(PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (c, a, _) => FadeTransition(opacity: a, child: h.reopen(h)),
    ));
  }
}

class _FloatWindow extends StatefulWidget {
  const _FloatWindow({required this.h});
  final FloatHandoff h;

  @override
  State<_FloatWindow> createState() => _FloatWindowState();
}

class _FloatWindowState extends State<_FloatWindow> with SingleTickerProviderStateMixin {
  Offset? at;
  double scale = 1, startScale = 1;
  Offset dragFrom = Offset.zero;
  bool controls = false, dragging = false;
  Timer? hide;
  late final AnimationController snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  Animation<Offset>? move;

  VideoPlayerController get c => widget.h.controller;

  @override
  void initState() {
    super.initState();
    c.addListener(tick);
    snap.addListener(() {
      if (move != null) setState(() => at = move!.value);
    });
  }

  void tick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    c.removeListener(tick);
    hide?.cancel();
    snap.dispose();
    super.dispose();
  }

  Size sizeFor(double sc) {
    final ratio = c.value.isInitialized && c.value.aspectRatio > 0 ? c.value.aspectRatio : 16 / 9;
    final w = FloatVideo.baseWidth * sc;
    return Size(w, w / ratio.clamp(0.5, 2.4));
  }

  /// Corners inside the safe area (above the tab bar / message box).
  List<Offset> corners(Size screen, EdgeInsets pad, Size box) {
    final m = Tokens.space[2];
    final left = pad.left + m, right = screen.width - pad.right - m - box.width;
    final top = pad.top + 64, bottom = screen.height - pad.bottom - 96 - box.height;
    return [Offset(left, top), Offset(right, top), Offset(left, bottom), Offset(right, bottom)];
  }

  void showControls() {
    setState(() => controls = !controls);
    hide?.cancel();
    if (controls) {
      hide = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => controls = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screen = mq.size;
    final box = sizeFor(scale);
    final spots = corners(screen, mq.padding, box);
    final pos = at ?? spots[3];
    const white = Color(0xFFFFFFFF);
    final v = c.value;
    final progress = v.duration.inMilliseconds == 0 ? 0.0 : (v.position.inMilliseconds / v.duration.inMilliseconds).clamp(0.0, 1.0);
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        key: const Key('float-video'),
        onTap: showControls,
        onScaleStart: (d) {
          snap.stop();
          dragging = true;
          startScale = scale;
          dragFrom = d.focalPoint - pos;
        },
        onScaleUpdate: (d) => setState(() {
          if (d.pointerCount > 1) scale = (startScale * d.scale).clamp(FloatVideo.minScale, FloatVideo.maxScale);
          at = d.focalPoint - dragFrom;
        }),
        onScaleEnd: (d) {
          dragging = false;
          final p = at ?? pos;
          final vx = d.velocity.pixelsPerSecond.dx;
          // Thrown (or pushed half-way) off a side: close.
          final offLeft = p.dx + box.width / 2 < 0 || (vx < -1400 && p.dx < screen.width / 2);
          final offRight = p.dx + box.width / 2 > screen.width || (vx > 1400 && p.dx + box.width > screen.width / 2);
          if (offLeft || offRight) {
            FloatVideo.close();
            return;
          }
          // Nearest corner, a little ahead in the throw direction.
          final aim = p + d.velocity.pixelsPerSecond * 0.12;
          final c2 = corners(screen, mq.padding, sizeFor(scale));
          final best = c2.reduce((a, b) => (a - aim).distance < (b - aim).distance ? a : b);
          move = Tween(begin: p, end: best).animate(CurvedAnimation(parent: snap, curve: Curves.easeOutBack));
          snap.forward(from: 0);
        },
        child: AnimatedContainer(
          duration: dragging ? Duration.zero : const Duration(milliseconds: 160),
          width: box.width,
          height: box.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFF000000)),
                if (v.isInitialized) IgnorePointer(child: VideoPlayer(c)),
                // Thin progress line at the bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: progress, child: const ColoredBox(color: Color(0xE6FFFFFF))),
                  ),
                ),
                AnimatedOpacity(
                  opacity: controls ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: IgnorePointer(
                    ignoring: !controls,
                    child: ColoredBox(
                      color: const Color(0x55000000),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 6,
                            top: 6,
                            child: _Small(
                              key: const Key('float-close'),
                              icon: CupertinoIcons.xmark,
                              onTap: FloatVideo.close,
                            ),
                          ),
                          Positioned(
                            right: 6,
                            top: 6,
                            child: _Small(
                              key: const Key('float-expand'),
                              icon: CupertinoIcons.arrow_up_left_arrow_down_right,
                              onTap: () => FloatVideo.expand(context),
                            ),
                          ),
                          Center(
                            child: GestureDetector(
                              key: const Key('float-play'),
                              onTap: () {
                                v.isPlaying ? c.pause() : c.play();
                                showControls();
                                showControls();
                              },
                              child: Icon(v.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: white, size: math.min(36, box.height * 0.3)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Small extends StatelessWidget {
  const _Small({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: LiquidGlass(
      radius: Tokens.capsule,
      flat: kIsWeb,
      shadow: false,
      child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 14, color: const Color(0xFFFFFFFF))),
    ),
  );
}
