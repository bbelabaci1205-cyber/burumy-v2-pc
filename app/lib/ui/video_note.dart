// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 동그라미 영상 메시지 (v1 parity batch 3, 2026-11-27): a short round video
// from the front camera, up to 60 seconds. The camera is on only while this
// screen is open and frames stay on the phone until I send (encrypted like
// any file). In the chat it shows as a circle that plays in place.
// Tip 466 (batch #11, 2026-11-27, card B): ⚡ 화면 플래시 lights the screen
// around the circle in the warm colour of the story camera's front flash,
// so faces show in the dark; 꾹 누르기 records while held (let go = send),
// slide up to lock (hands free, tap ■ to send), slide left to throw it away.
import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_state.dart';
import '../core/screen_guard.dart';
import 'media_bubbles.dart' show videoSpeedPref;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'story_video.dart';

/// Round videos are sent as files named like this.
const videoNotePrefix = 'videonote';

bool isVideoNote(String? name) => (name ?? '').startsWith(videoNotePrefix);

class VideoNotePage extends StatefulWidget {
  const VideoNotePage({super.key, required this.roomId, this.onRecorded});
  final String roomId;

  /// Story mode (tip 408): the clip comes back here instead of being sent.
  final Future<void> Function(Uint8List bytes, String mime)? onRecorded;

  /// Tests: no camera; recording gives a few fake bytes.
  static bool fake = false;
  static const maxLength = Duration(seconds: 60);

  @override
  State<VideoNotePage> createState() => _VideoNotePageState();
}

class _VideoNotePageState extends State<VideoNotePage> {
  CameraController? ctl;
  bool unavailable = false, recording = false, sending = false;

  /// The "1" button: the person can watch it once, then it is gone
  /// (TelegramTips 420).
  bool once = false;

  /// ⚡ 화면 플래시 (remembered), and the hold-to-record state (tip 466).
  bool flash = false, holding = false, locked = false;
  Offset holdMove = Offset.zero;
  final watch = Stopwatch();
  Timer? tick;

  /// Slide this far up to lock, this far left to throw away.
  static const lockAt = 80.0, cancelAt = 110.0;

  @override
  void initState() {
    super.initState();
    if (!VideoNotePage.fake) unawaited(open());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    flash = AppScope.of(context).on('vn_flash');
  }

  double get flashWarm => double.tryParse(AppScope.read(context).pref('front_flash_warm', '0.4')) ?? .4;
  double get flashBright => double.tryParse(AppScope.read(context).pref('front_flash_bright', '1')) ?? 1;

  /// White warmed towards amber (the story camera's front-flash colour).
  Color flashColor() => Color.lerp(const Color(0xFFFFFFFF), Palette.flashWarm, flashWarm)!.withValues(alpha: 0.55 + 0.45 * flashBright);

  void holdStart(LongPressStartDetails d) {
    if (recording || sending) return;
    HapticFeedback.mediumImpact();
    setState(() {
      holding = true;
      locked = false;
      holdMove = Offset.zero;
    });
    unawaited(start());
  }

  void holdUpdate(LongPressMoveUpdateDetails d) {
    if (!holding) return;
    final o = d.offsetFromOrigin;
    setState(() => holdMove = o);
    if (!locked && o.dy < -lockAt) {
      HapticFeedback.mediumImpact();
      setState(() => locked = true);
    } else if (!locked && o.dx < -cancelAt) {
      HapticFeedback.heavyImpact();
      unawaited(discard());
    }
  }

  void holdEnd() {
    if (!holding) return;
    setState(() => holding = false);
    // Locked: keeps recording; ■ sends. Else letting go sends.
    if (!locked && recording) unawaited(stop());
  }

  /// Slid left: stops and keeps nothing.
  Future<void> discard() async {
    tick?.cancel();
    watch.stop();
    setState(() {
      holding = false;
      locked = false;
      recording = false;
    });
    if (!VideoNotePage.fake) {
      try {
        await ctl?.stopVideoRecording();
      } catch (_) {}
    }
  }

  Future<void> open() async {
    try {
      final cams = await availableCameras();
      final desc = cams.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull ?? cams.firstOrNull;
      if (desc == null) throw StateError('no camera');
      final c = CameraController(desc, ResolutionPreset.medium, enableAudio: true);
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => ctl = c);
    } catch (_) {
      if (mounted) setState(() => unavailable = true);
    }
  }

  @override
  void dispose() {
    tick?.cancel();
    ctl?.dispose();
    super.dispose();
  }

  Future<void> start() async {
    if (!VideoNotePage.fake) {
      final c = ctl;
      if (c == null) return;
      try {
        await c.startVideoRecording();
      } catch (_) {
        return;
      }
    }
    watch
      ..reset()
      ..start();
    setState(() => recording = true);
    tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (watch.elapsed >= VideoNotePage.maxLength) unawaited(stop());
      if (mounted) setState(() {});
    });
  }

  Future<void> stop() async {
    if (!recording) return;
    tick?.cancel();
    watch.stop();
    setState(() {
      recording = false;
      sending = true;
    });
    final s = AppScope.read(context);
    try {
      Uint8List bytes;
      var mime = kIsWeb ? 'video/webm' : 'video/mp4';
      if (VideoNotePage.fake) {
        bytes = Uint8List.fromList([0, 0, 0, 1]);
      } else {
        final x = await ctl!.stopVideoRecording();
        bytes = await x.readAsBytes();
        mime = x.mimeType ?? mime;
      }
      final ext = mime.contains('webm') ? 'webm' : (mime.contains('quicktime') ? 'mov' : 'mp4');
      if (widget.onRecorded != null) {
        await widget.onRecorded!(bytes, mime);
      } else if (once) {
        await s.backend.sendViewOnce(widget.roomId, name: '$videoNotePrefix.$ext', mime: mime, bytes: bytes);
      } else {
        await s.backend.sendFile(widget.roomId, name: '$videoNotePrefix.$ext', mime: mime, bytes: bytes);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    final size = MediaQuery.sizeOf(context).width * 0.72;
    final left = VideoNotePage.maxLength - watch.elapsed;
    final c = ctl;
    return CupertinoPageScaffold(
      key: const Key('video-note-page'),
      // ⚡: the whole screen glows (front camera has no real flash).
      backgroundColor: flash ? flashColor() : const Color(0xF0000000),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: GlassCircle(
                  key: const Key('video-note-close'),
                  onTap: () => Navigator.of(context).pop(false),
                  child: Icon(CupertinoIcons.xmark, color: flash ? const Color(0xFF000000) : white, size: 20),
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: size + 8,
              height: size + 8,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: recording ? const Color(0xFFFF3B30) : const Color(0x33FFFFFF), width: 3),
              ),
              child: ClipOval(
                child: c != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(width: c.value.previewSize?.height ?? size, height: c.value.previewSize?.width ?? size, child: CameraPreview(c)),
                      )
                    : Container(
                        color: const Color(0xFF1C1C1E),
                        alignment: Alignment.center,
                        child: unavailable
                            ? Padding(
                                padding: EdgeInsets.all(Tokens.space[4]),
                                child: Text(
                                  l.cameraUnavailable,
                                  textAlign: TextAlign.center,
                                  style: Tokens.caption.style.copyWith(color: white),
                                ),
                              )
                            : (VideoNotePage.fake ? const SizedBox() : const CupertinoActivityIndicator(color: white)),
                      ),
              ),
            ),
            SizedBox(height: Tokens.space[3]),
            Text(
              recording ? clockOf(left) : (once ? l.videoNoteOnceHint : l.videoNoteHoldHint),
              key: const Key('video-note-time'),
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: flash ? const Color(0xFF000000) : white),
            ),
            if (recording && (holding || locked))
              Padding(
                padding: EdgeInsets.only(top: Tokens.space[1]),
                child: Text(
                  locked ? l.videoNoteLocked : l.videoNoteSlideHint,
                  key: const Key('video-note-hold-hint'),
                  style: Tokens.caption.style.copyWith(color: flash ? const Color(0x99000000) : const Color(0xB3FFFFFF)),
                ),
              ),
            const Spacer(),
            // Slide up to lock: the lock rises over the button while held.
            SizedBox(
              height: 56,
              child: AnimatedOpacity(
                opacity: holding && !locked ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Transform.translate(
                  offset: Offset(0, (holdMove.dy.clamp(-lockAt, 0)) / 3),
                  child: LiquidGlass(
                    key: const Key('video-note-lock'),
                    radius: Tokens.capsule,
                    flat: kIsWeb,
                    child: const SizedBox(
                      width: 36,
                      height: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.lock_fill, color: white, size: 16),
                          Icon(CupertinoIcons.chevron_up, color: white, size: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                flashButton(),
                SizedBox(width: Tokens.space[5]),
                record(),
                SizedBox(width: Tokens.space[5]),
                if (widget.onRecorded == null) onceButton() else const SizedBox(width: 44),
              ],
            ),
            SizedBox(height: Tokens.space[5]),
          ],
        ),
      ),
    );
  }

  /// ⚡ 화면 플래시 (remembered on this phone).
  Widget flashButton() {
    const white = Color(0xFFFFFFFF);
    return GlassCircle(
      key: const Key('video-note-flash'),
      onTap: () async {
        final s = AppScope.read(context);
        setState(() => flash = !flash);
        await s.setOn('vn_flash', flash);
      },
      child: Icon(flash ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt_slash_fill, color: flash ? Palette.tileYellow : white, size: 20),
    );
  }

  /// "1" in a circle, like the attach sheet's view-once switch: white
  /// filled when on.
  Widget onceButton() {
    const white = Color(0xFFFFFFFF);
    return GlassCircle(
      key: const Key('video-note-once'),
      onTap: recording || sending ? null : () => setState(() => once = !once),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: once ? white : const Color(0x00FFFFFF),
          border: Border.all(color: white, width: 1.5),
        ),
        child: Text('1', style: Tokens.caption.style.copyWith(color: once ? const Color(0xFF000000) : white, height: 1)),
      ),
    );
  }

  Widget record() {
    const white = Color(0xFFFFFFFF);
    return GestureDetector(
      key: const Key('video-note-record'),
      onTap: sending || holding ? null : (recording ? stop : start),
      onLongPressStart: holdStart,
      onLongPressMoveUpdate: holdUpdate,
      onLongPressEnd: (_) => holdEnd(),
      onLongPressCancel: holdEnd,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: flash ? const Color(0x99000000) : white, width: 4),
        ),
        alignment: Alignment.center,
        child: sending
            ? const CupertinoActivityIndicator(color: white)
            : AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: recording ? 28 : 60,
                height: recording ? 28 : 60,
                decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(recording ? 6 : 30)),
              ),
      ),
    );
  }
}

String clockOf(Duration d) {
  final s = d.inSeconds.clamp(0, 3600);
  return '0:${(s % 60).toString().padLeft(2, '0')}';
}

/// The circle in the chat: tap plays it in place (downloads then).
class RoundVideoBubble extends StatefulWidget {
  const RoundVideoBubble({super.key, required this.load, required this.mime, required this.meta});
  final Future<List<int>> Function() load;
  final String mime;
  final Widget meta;

  @override
  State<RoundVideoBubble> createState() => _RoundVideoBubbleState();
}

class _RoundVideoBubbleState extends State<RoundVideoBubble> {
  Uint8List? bytes;
  bool loading = false;

  Future<void> play() async {
    if (bytes != null) return setState(() => bytes = null);
    setState(() => loading = true);
    try {
      final b = Uint8List.fromList(await widget.load());
      if (mounted) setState(() => bytes = b);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const d = 200.0;
    return GestureDetector(
      key: const Key('round-video'),
      onTap: play,
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          children: [
            ClipOval(
              child: Container(
                width: d,
                height: d,
                color: const Color(0xFF1C1C1E),
                child: bytes != null
                    ? StoryVideo(bytes: bytes!, mime: widget.mime, speed: videoSpeedPref(context))
                    : Center(
                        child: loading
                            ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                            : const Icon(CupertinoIcons.play_fill, color: Color(0xFFFFFFFF), size: 34),
                      ),
              ),
            ),
            Positioned(right: 8, bottom: 8, child: widget.meta),
          ],
        ),
      ),
    );
  }
}

/// A view-once round video in the chat: a dark circle with the "1" mark
/// (no picture shown before it is opened).
class OnceRoundBubble extends StatelessWidget {
  const OnceRoundBubble({super.key, required this.opened, required this.canOpen, required this.onOpen, required this.meta});
  final bool opened, canOpen;
  final VoidCallback? onOpen;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    const d = 200.0;
    return GestureDetector(
      key: const Key('once-round'),
      onTap: canOpen ? onOpen : null,
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          children: [
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1E),
                border: opened ? Border.all(color: const Color(0x55FFFFFF), width: 2) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: opened ? const Color(0x88FFFFFF) : white, width: 2),
                    ),
                    child: Text('1', style: Tokens.body.style.copyWith(color: opened ? const Color(0x88FFFFFF) : white, height: 1)),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  Text(
                    opened ? l.onceRoundExpired : (canOpen ? l.viewOnceTap : l.onceRoundSent),
                    key: opened ? const Key('once-round-expired') : null,
                    style: Tokens.caption.style.copyWith(color: opened ? const Color(0x88FFFFFF) : white),
                  ),
                ],
              ),
            ),
            Positioned(right: 8, bottom: 8, child: meta),
          ],
        ),
      ),
    );
  }
}

/// Opening a view-once round video (TelegramTips 420): the circle opens big
/// in the middle of a darkened screen, a ring around it fills as it plays,
/// it can't be paused, and "닫고 삭제" ends it early. When it ends the circle
/// fades away into dust and the chat shows "만료된 영상 메시지".
class OnceRoundPlayerPage extends StatefulWidget {
  const OnceRoundPlayerPage({super.key, required this.bytes, required this.mime});
  final Uint8List bytes;
  final String mime;

  /// Tests: the clip "plays" for this long without a real player.
  static Duration? fakeLength;

  @override
  State<OnceRoundPlayerPage> createState() => _OnceRoundPlayerPageState();
}

class _OnceRoundPlayerPageState extends State<OnceRoundPlayerPage> with SingleTickerProviderStateMixin {
  late final AnimationController gone = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  double progress = 0;
  Timer? fake;
  bool closing = false;

  @override
  void initState() {
    super.initState();
    final f = OnceRoundPlayerPage.fakeLength;
    if (f != null) {
      fake = Timer.periodic(const Duration(milliseconds: 50), (tm) {
        final p = tm.tick * 50 / f.inMilliseconds;
        if (p >= 1) return unawaited(close());
        if (mounted) setState(() => progress = p);
      });
    }
  }

  void ready(dynamic c) {
    void on() {
      final v = c.value;
      final len = v.duration.inMilliseconds;
      if (len <= 0) return;
      if (mounted) setState(() => progress = (v.position.inMilliseconds / len).clamp(0.0, 1.0));
      if (v.isCompleted || v.position >= v.duration) {
        c.removeListener(on);
        unawaited(close());
      }
    }

    c.addListener(on);
  }

  Future<void> close() async {
    if (closing) return;
    closing = true;
    fake?.cancel();
    await gone.forward();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    fake?.cancel();
    gone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    const white = Color(0xFFFFFFFF);
    final d = MediaQuery.sizeOf(context).width * 0.84;
    return CupertinoPageScaffold(
      key: const Key('once-round-page'),
      backgroundColor: const Color(0xE6000000),
      child: CaptureBlock(
        what: 'round',
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: gone,
                builder: (_, child) => Opacity(
                  opacity: 1 - gone.value,
                  child: Transform.scale(scale: 1 + 0.12 * gone.value, child: child),
                ),
                child: SizedBox(
                  width: d + 12,
                  height: d + 12,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipOval(
                        child: SizedBox(
                          width: d,
                          height: d,
                          child: OnceRoundPlayerPage.fakeLength != null
                              ? const ColoredBox(color: Color(0xFF1C1C1E))
                              : StoryVideo(bytes: widget.bytes, mime: widget.mime, onReady: ready),
                        ),
                      ),
                      // No tap to pause: watched once, straight through.
                      IgnorePointer(
                        child: CustomPaint(key: const Key('once-round-ring'), size: Size(d + 12, d + 12), painter: _Ring(progress, p.accent)),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: Tokens.space[3]),
              Text(l.viewOnceInfo, style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF))),
              const Spacer(),
              GestureDetector(
                key: const Key('once-round-close'),
                onTap: close,
                child: LiquidGlass(
                  radius: Tokens.capsule,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[4], vertical: Tokens.space[2]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.trash, color: white, size: 18),
                        SizedBox(width: Tokens.space[1]),
                        Text(l.onceRoundClose, style: Tokens.body.style.copyWith(color: white)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: Tokens.space[5]),
            ],
          ),
        ),
      ),
    );
  }
}

/// The thin ring around the open circle that fills as the video plays.
class _Ring extends CustomPainter {
  _Ring(this.value, this.color);
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x33FFFFFF);
    canvas.drawArc(r.deflate(2), 0, 6.283185, false, track);
    final fill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(r.deflate(2), -1.570796, 6.283185 * value, false, fill);
  }

  @override
  bool shouldRepaint(_Ring old) => old.value != value || old.color != color;
}
