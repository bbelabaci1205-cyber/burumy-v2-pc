// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Videos inside a chat (v1 parity batch 3, 2026-11-27): a bubble that only
// downloads when tapped (saves data), and a full-screen player with
// play / pause, a scrub bar and speed 0.5× – 2× (v1). View-once videos use
// the same player with capture blocked.
// Batch "영상 보기" (2026-11-27): double tap left/right = 10 s back/forward
// (taps stack 10 → 20 → 30), hold = 2× while held (slide right for up to
// 3×), speed panel 0.2× – 2.5× remembered for every video, ±10 s buttons
// (iOS player), time bubble while scrubbing, and [startAt] for time links
// ("1:05" in a caption or a reply opens the video there).
import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_state.dart';
import '../core/screen_guard.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'float_video.dart';
import 'glass.dart';
import 'light_video.dart';
import 'video_touch.dart';

/// Video speeds (v1: 0.5, 1, 1.5, 2) shown as quick picks in the panel.
const videoSpeeds = [0.5, 1.0, 1.5, 2.0];

/// Free speed range (Telegram tip 383: 0.2× – 2.5×), in 0.1 steps.
const videoSpeedMin = 0.2, videoSpeedMax = 2.5;

/// Holding the video plays it at this speed (tip 272).
const videoHoldSpeed = 2.0;

/// One double tap jumps this far (iOS + Telegram: 10 s).
const videoSkip = Duration(seconds: 10);

/// Sliding right while holding: +0.1× every this many points, up to 3×
/// (Telegram tip 481).
const videoHoldStepPx = 24.0;
const videoHoldMax = 3.0;

/// The speed picked last time in the player (Settings memory).
double videoSpeedPref(BuildContext context) =>
    clampSpeed(double.tryParse(context.getInheritedWidgetOfExactType<AppScope>()?.notifier?.pref('video_speed', '1') ?? '1') ?? 1);

double clampSpeed(double s) => (((s.clamp(videoSpeedMin, videoSpeedMax)) * 10).round() / 10);

String speedText(double s) => '${s.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}×';

String clockText(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  final ss = s.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '${d.inMinutes}:$ss';
}

/// The bubble: a dark box with a play button (nothing is downloaded until
/// it is tapped, unless Settings > Data downloads it ahead). While it is
/// downloading, a ring with an X (tip 109); the size shows at the bottom.
class VideoBubble extends StatelessWidget {
  const VideoBubble({super.key, required this.name, required this.meta, required this.onOpen, this.size, this.downloading = false, this.onCancel, this.watched, this.inline});

  /// 자동 재생 (tip 204): the video playing silently in the bubble, with its
  /// own time / speaker pill (null = the dark box with ▶).
  final Widget? inline;
  final String name;
  final Widget meta;
  final VoidCallback onOpen;

  /// "12.3 MB" (null = unknown).
  final String? size;
  final bool downloading;
  final VoidCallback? onCancel;

  /// 이어보기 (tip 509): how much I watched, 0..1 (null = nothing saved).
  final double? watched;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    return GestureDetector(
      key: const Key('video-bubble'),
      onTap: downloading ? onCancel : onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        child: Container(
          width: 240,
          height: 160,
          color: const Color(0xFF1C1C1E),
          child: Stack(
            children: [
              Center(
                child: Container(
                  key: Key(downloading ? 'video-downloading' : 'video-play-mark'),
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
                  child: downloading
                      ? const Stack(
                          alignment: Alignment.center,
                          children: [
                            CupertinoActivityIndicator(color: white, radius: 20),
                            Icon(CupertinoIcons.xmark, color: white, size: 16),
                          ],
                        )
                      : const Icon(CupertinoIcons.play_fill, color: white, size: 26),
                ),
              ),
              Positioned(
                left: Tokens.space[2],
                top: Tokens.space[2],
                right: Tokens.space[2],
                child: Text(
                  name.isEmpty ? l.videoLabel : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: const Color(0xCCFFFFFF)),
                ),
              ),
              if (size != null)
                Positioned(
                  left: Tokens.space[1],
                  bottom: Tokens.space[1],
                  child: Container(
                    key: const Key('video-size'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 1),
                    decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(size!, style: Tokens.bubbleMeta.style.copyWith(color: white)),
                  ),
                ),
              // Playing by itself: covers the ▶ box once the picture is there.
              if (inline != null) Positioned.fill(child: inline!),
              Positioned(right: Tokens.space[1], bottom: Tokens.space[1], child: meta),
              if (watched != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 3,
                  child: Container(
                    key: const Key('video-watched'),
                    color: const Color(0x33FFFFFF),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: watched,
                      child: Container(color: paletteOf(context).accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A player for decrypted bytes: on the web from memory, on phones from a
/// temp file the caller deletes. Muted loops mix with other sound.
Future<(VideoPlayerController, File?)> videoFromBytes(Uint8List bytes, String mime, {bool mix = false}) async {
  final m = mime == 'application/octet-stream' ? 'video/mp4' : mime;
  if (kIsWeb)
    return (
      VideoPlayerController.networkUrl(
        Uri.dataFromBytes(bytes, mimeType: m),
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: mix),
      ),
      null,
    );
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/inline-${DateTime.now().microsecondsSinceEpoch}.${m.endsWith('quicktime') ? 'mov' : (m.endsWith('webm') ? 'webm' : 'mp4')}');
  await f.writeAsBytes(bytes, flush: true);
  return (VideoPlayerController.file(f, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: mix)), f);
}

/// 자동 재생 (tip 204): a downloaded video plays without sound inside its
/// bubble, the time left and a speaker at the top left (tap = sound on).
class InlineVideo extends StatefulWidget {
  const InlineVideo({super.key, required this.load, required this.mime});
  final Future<List<int>> Function() load;
  final String mime;

  @override
  State<InlineVideo> createState() => InlineVideoState();
}

class InlineVideoState extends State<InlineVideo> {
  VideoPlayerController? c;
  File? temp;
  bool sound = false;

  @override
  void initState() {
    super.initState();
    unawaited(start());
  }

  Future<void> start() async {
    try {
      final (v, f) = await videoFromBytes(Uint8List.fromList(await widget.load()), widget.mime, mix: true);
      temp = f;
      await v.initialize();
      await v.setVolume(0);
      await v.setLooping(true);
      videoLetTapsThrough();
      if (!mounted) {
        await v.dispose();
        return;
      }
      v.addListener(tick);
      setState(() => c = v);
      await v.play();
    } catch (_) {}
  }

  void tick() {
    if (mounted) setState(() {});
  }

  /// The full player opens: this one rests.
  void pause() => c?.pause();
  void resume() => c?.play();

  @override
  void dispose() {
    c?.removeListener(tick);
    c?.dispose();
    final f = temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = c;
    if (v == null || !v.value.isInitialized) return const SizedBox.shrink();
    const white = Color(0xFFFFFFFF);
    final left = v.value.duration - v.value.position;
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: IgnorePointer(child: VideoPlayer(v))),
        ),
        Positioned(
          left: Tokens.space[1],
          top: Tokens.space[1],
          child: GestureDetector(
            key: const Key('inline-sound'),
            onTap: () {
              setState(() => sound = !sound);
              v.setVolume(sound ? 1 : 0);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
              decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    clockText(left.isNegative ? Duration.zero : left),
                    key: const Key('inline-left'),
                    style: Tokens.bubbleMeta.style.copyWith(color: white),
                  ),
                  const SizedBox(width: 4),
                  Icon(sound ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill, size: 12, color: white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen player. [load] fetches the (decrypted) bytes.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({
    super.key,
    required this.load,
    this.mime = 'video/mp4',
    this.once = false,
    this.startAt,
    this.resumed = false,
    this.onClose,
    this.from,
    this.light,
    this.originalSize,
  });
  final Future<List<int>> Function() load;
  final String mime;

  /// 한 번만 보기: capture blocked, no speed memory.
  final bool once;

  /// Opened from a time link ("1:05"): start here.
  final Duration? startAt;

  /// [startAt] is where I stopped last time (tip 509): a pill offers
  /// 처음부터 for a few seconds.
  final bool resumed;

  /// Called on close with where it stopped and how long it is.
  final void Function(Duration at, Duration total)? onClose;

  /// Back from the small window (tip 334): the same video, still playing.
  final FloatHandoff? from;

  /// The sender's light copy (tips 479 · 480): the ⚙ menu picks 자동 /
  /// 원본 / 가벼운 화질. Null = only the original.
  final LightCopy? light;

  /// The original's size (shown in the ⚙ panel).
  final int? originalSize;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? c;
  File? temp;
  bool failed = false;
  double speed = 1;

  /// Holding: the speed shown in the top capsule (null = not holding).
  double? holdSpeed;
  double holdFromX = 0;

  /// Double tap: which side (-1 back, 1 forward), how far so far, and where.
  int skipSide = 0;
  int skipSeconds = 0;
  Timer? skipTimer;
  Offset? tapAt;

  /// Dragging the bar: the time under the finger.
  Duration? scrubAt;
  bool speedPanel = false;

  /// "이어서 봐요 · 처음부터" pill (tip 509).
  bool resumePill = false;
  Timer? resumeTimer;

  AppState? get app => context.getInheritedWidgetOfExactType<AppScope>()?.notifier;

  @override
  void initState() {
    super.initState();
    unawaited(open());
  }

  /// Given to the small window: this page must not free the video.
  bool handedOff = false;

  Future<void> open() async {
    final from = widget.from;
    if (from != null) {
      from.controller.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        c = from.controller;
        temp = from.temp;
        speed = from.controller.value.playbackSpeed;
      });
      return;
    }
    // One video at a time: a new one closes the small window.
    if (FloatVideo.showing) FloatVideo.close();
    try {
      // 화질 (tips 479 · 480): 자동 picks the light copy on mobile data.
      quality = videoQualityPref(app);
      playingLight = lightFor(quality);
      final v = await make(Uint8List.fromList(await (playingLight ? widget.light!.load : widget.load)()));
      if (!mounted) {
        await v.dispose();
        return;
      }
      // Settings memory: the speed picked last time (not for view-once).
      final saved = widget.once ? 1.0 : clampSpeed(double.tryParse(app?.pref('video_speed', '1') ?? '1') ?? 1);
      setState(() {
        c = v;
        speed = saved;
      });
      final start = widget.startAt;
      if (start != null && start > Duration.zero) {
        await v.seekTo(start < v.value.duration ? start : Duration.zero);
        if (widget.resumed && start < v.value.duration && mounted) {
          setState(() => resumePill = true);
          resumeTimer = Timer(const Duration(seconds: 5), () {
            if (mounted) setState(() => resumePill = false);
          });
        }
      }
      if (saved != 1) await v.setPlaybackSpeed(saved);
      await v.play();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    skipTimer?.cancel();
    resumeTimer?.cancel();
    if (!handedOff) {
      final last = c?.value;
      if (last != null && last.isInitialized && !widget.once) widget.onClose?.call(last.position, last.duration);
      c?.dispose();
      final f = temp;
      if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    }
    super.dispose();
  }

  /// A player for decrypted [bytes] (phones: a temp file removed on close).
  Future<VideoPlayerController> make(Uint8List bytes) async {
    final VideoPlayerController v;
    if (kIsWeb) {
      v = VideoPlayerController.networkUrl(Uri.dataFromBytes(bytes, mimeType: widget.mime));
    } else {
      // Decrypted only into the app's own temp folder, removed on close.
      final dir = await getTemporaryDirectory();
      final ext = widget.mime.endsWith('quicktime') ? 'mov' : (widget.mime.endsWith('webm') ? 'webm' : 'mp4');
      final f = File('${dir.path}/play-${DateTime.now().microsecondsSinceEpoch}.$ext');
      await f.writeAsBytes(bytes, flush: true);
      temp = f;
      v = VideoPlayerController.file(f);
    }
    await v.initialize();
    videoLetTapsThrough();
    v.addListener(() {
      if (mounted) setState(() {});
    });
    return v;
  }

  // --- 화질 (tips 479 · 480) ---------------------------------------------

  VideoQuality quality = VideoQuality.auto;
  bool playingLight = false;
  bool qualityPanel = false;

  bool lightFor(VideoQuality q) => widget.light != null && (q == VideoQuality.light || (q == VideoQuality.auto && autoPicksLight(app)));

  /// Picked in the ⚙ panel: the other copy plays from the same second.
  Future<void> setQuality(VideoQuality q) async {
    setState(() {
      quality = q;
      qualityPanel = false;
    });
    if (!widget.once) await app?.setPref('video_quality', q.name);
    final light = lightFor(q);
    final old = c;
    if (light == playingLight || old == null) return;
    final at = old.value.position;
    final playing = old.value.isPlaying;
    final oldTemp = temp;
    setState(() {
      c = null;
      playingLight = light;
    });
    await old.dispose();
    if (oldTemp != null) unawaited(oldTemp.delete().then((_) {}, onError: (_) {}));
    try {
      final v = await make(Uint8List.fromList(await (light ? widget.light!.load : widget.load)()));
      if (!mounted) {
        await v.dispose();
        return;
      }
      await v.seekTo(at < v.value.duration ? at : Duration.zero);
      await v.setPlaybackSpeed(speed);
      setState(() => c = v);
      if (playing) await v.play();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  /// Shrinks into the small window and goes back to where I was.
  void toFloat() {
    final v = c;
    if (v == null) return;
    handedOff = true;
    FloatVideo.show(
      context,
      FloatHandoff(
        controller: v,
        temp: temp,
        onClose: widget.onClose,
        reopen: (h) =>
            VideoPlayerPage(load: widget.load, mime: widget.mime, onClose: widget.onClose, light: widget.light, originalSize: widget.originalSize, from: h),
      ),
    );
    Navigator.pop(context);
  }

  Future<void> setSpeed(double s, {bool remember = true}) async {
    final v = clampSpeed(s);
    await c?.setPlaybackSpeed(v);
    if (!mounted) return;
    setState(() => speed = v);
    if (remember && !widget.once) await app?.setPref('video_speed', '$v');
  }

  void togglePlay() {
    final v = c;
    if (v == null) return;
    v.value.isPlaying ? v.pause() : v.play();
  }

  Future<void> jump(Duration by) async {
    final v = c;
    if (v == null) return;
    final total = v.value.duration;
    var to = v.value.position + by;
    if (to < Duration.zero) to = Duration.zero;
    if (to > total) to = total;
    await v.seekTo(to);
  }

  /// Double tap: left third back, right third forward, middle = play/pause.
  /// Taps on the same side within a second add up (10 → 20 → 30 s).
  void doubleTap(double width) {
    final x = tapAt?.dx ?? width / 2;
    final side = x < width / 3 ? -1 : (x > width * 2 / 3 ? 1 : 0);
    if (side == 0) return togglePlay();
    HapticFeedback.selectionClick();
    setState(() {
      skipSeconds = side == skipSide ? skipSeconds + videoSkip.inSeconds : videoSkip.inSeconds;
      skipSide = side;
    });
    unawaited(jump(videoSkip * side));
    skipTimer?.cancel();
    skipTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => skipSide = 0);
    });
  }

  void holdStart(LongPressStartDetails d) {
    if (c == null) return;
    HapticFeedback.mediumImpact();
    holdFromX = d.globalPosition.dx;
    setState(() => holdSpeed = videoHoldSpeed);
    unawaited(c!.setPlaybackSpeed(videoHoldSpeed));
    if (!c!.value.isPlaying) unawaited(c!.play());
  }

  void holdMove(LongPressMoveUpdateDetails d) {
    final h = holdSpeed;
    if (h == null) return;
    final steps = ((d.globalPosition.dx - holdFromX) / videoHoldStepPx).floor();
    final next = ((videoHoldSpeed + steps * 0.1).clamp(videoHoldSpeed, videoHoldMax) * 10).round() / 10;
    if (next != h) {
      HapticFeedback.selectionClick();
      setState(() => holdSpeed = next);
      unawaited(c?.setPlaybackSpeed(next));
    }
  }

  void holdEnd() {
    if (holdSpeed == null) return;
    setState(() => holdSpeed = null);
    unawaited(c?.setPlaybackSpeed(speed));
  }

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final l = L.of(context);
    final v = c;
    final value = v?.value;
    final total = value?.duration ?? Duration.zero;
    final at = scrubAt ?? value?.position ?? Duration.zero;
    final caption = Tokens.caption.style.copyWith(color: white);
    final video = v == null
        ? Center(
            child: failed ? const Icon(CupertinoIcons.exclamationmark_circle, color: white, size: 48) : const CupertinoActivityIndicator(color: white),
          )
        : Center(
            child: AspectRatio(aspectRatio: value!.aspectRatio == 0 ? 16 / 9 : value.aspectRatio, child: IgnorePointer(child: VideoPlayer(v))),
          );
    final page = CupertinoPageScaffold(
      key: const Key('video-page'),
      backgroundColor: const Color(0xFF000000),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            children: [
              Positioned.fill(child: video),
              // The whole screen takes the gestures (not only the picture).
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('video-surface'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => speedPanel || qualityPanel ? setState(() => speedPanel = qualityPanel = false) : togglePlay(),
                  onDoubleTapDown: (d) => tapAt = d.localPosition,
                  onDoubleTap: () => doubleTap(box.maxWidth),
                  onLongPressStart: holdStart,
                  onLongPressMoveUpdate: holdMove,
                  onLongPressEnd: (_) => holdEnd(),
                  onLongPressCancel: holdEnd,
                ),
              ),
              if (skipSide != 0) skipRipple(box, l),
              if (holdSpeed != null)
                Positioned(
                  top: Tokens.space[2],
                  left: 0,
                  right: 0,
                  child: Center(
                    child: LiquidGlass(
                      key: const Key('video-hold'),
                      radius: Tokens.capsule,
                      flat: kIsWeb,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              speedText(holdSpeed!),
                              style: Tokens.caption.style.copyWith(color: white, fontWeight: Tokens.semi),
                            ),
                            SizedBox(width: Tokens.space[0]),
                            const Icon(CupertinoIcons.forward_fill, color: white, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (resumePill && holdSpeed == null && v != null)
                Positioned(
                  top: Tokens.space[1] + 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: LiquidGlass(
                      key: const Key('video-resume'),
                      radius: Tokens.capsule,
                      flat: kIsWeb,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.videoResumed(clockText(widget.startAt!)), style: caption),
                            SizedBox(width: Tokens.space[2]),
                            GestureDetector(
                              key: const Key('video-from-start'),
                              onTap: () {
                                resumeTimer?.cancel();
                                setState(() => resumePill = false);
                                unawaited(v.seekTo(Duration.zero));
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                                decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(Tokens.capsule)),
                                child: Text(l.videoFromStart, style: caption.copyWith(fontWeight: Tokens.semi)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (holdSpeed == null)
                Positioned(
                  left: Tokens.space[3],
                  top: Tokens.space[1],
                  child: GlassCircle(
                    key: const Key('video-close'),
                    onTap: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark, color: white, size: 20),
                  ),
                ),
              // ⧉ 작은 화면 (tip 334): keeps playing over the chats.
              if (holdSpeed == null && v != null && !widget.once)
                Positioned(
                  right: Tokens.space[3],
                  top: Tokens.space[1],
                  child: GlassCircle(
                    key: const Key('video-float'),
                    onTap: toFloat,
                    child: const Icon(CupertinoIcons.rectangle_on_rectangle, color: white, size: 20),
                  ),
                ),
              if (v != null && holdSpeed == null)
                Positioned(
                  left: Tokens.space[3],
                  right: Tokens.space[3],
                  bottom: Tokens.space[3],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(clockText(at), style: caption),
                          Expanded(
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: CupertinoSlider(
                                    key: const Key('video-seek'),
                                    value: total.inMilliseconds == 0 ? 0 : (at.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0),
                                    activeColor: white,
                                    thumbColor: white,
                                    onChangeStart: (x) => setState(() => scrubAt = Duration(milliseconds: (x * total.inMilliseconds).round())),
                                    onChanged: (x) {
                                      final to = Duration(milliseconds: (x * total.inMilliseconds).round());
                                      setState(() => scrubAt = to);
                                      v.seekTo(to);
                                    },
                                    onChangeEnd: (_) => setState(() => scrubAt = null),
                                  ),
                                ),
                                // The time follows the finger while dragging.
                                if (scrubAt != null && total.inMilliseconds > 0)
                                  Positioned(
                                    bottom: 40,
                                    left: 0,
                                    right: 0,
                                    child: Align(
                                      alignment: Alignment(((scrubAt!.inMilliseconds / total.inMilliseconds) * 2 - 1).clamp(-1.0, 1.0), 0),
                                      child: LiquidGlass(
                                        key: const Key('video-scrub-time'),
                                        radius: Tokens.capsule,
                                        flat: kIsWeb,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                                          child: Text(clockText(scrubAt!), style: caption),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(clockText(total), style: caption),
                        ],
                      ),
                      SizedBox(height: Tokens.space[1]),
                      Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Align(alignment: Alignment.centerLeft, child: speedPill(caption)),
                          ),
                          const Spacer(),
                          GlassCircle(
                            key: const Key('video-back10'),
                            onTap: () => jump(-videoSkip),
                            child: const Icon(CupertinoIcons.gobackward_10, color: white, size: 22),
                          ),
                          SizedBox(width: Tokens.space[4]),
                          GlassCircle(
                            key: const Key('video-play'),
                            size: 56,
                            onTap: togglePlay,
                            child: Icon(value!.isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: white, size: 26),
                          ),
                          SizedBox(width: Tokens.space[4]),
                          GlassCircle(
                            key: const Key('video-fwd10'),
                            onTap: () => jump(videoSkip),
                            child: const Icon(CupertinoIcons.goforward_10, color: white, size: 22),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 64,
                            child: Align(alignment: Alignment.centerRight, child: widget.light == null ? null : qualityPill(caption)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (speedPanel && holdSpeed == null)
                Positioned(left: Tokens.space[3], bottom: Tokens.space[3] + 56 + Tokens.space[2] + 40, child: speedMenu(l, caption)),
              if (qualityPanel && holdSpeed == null && widget.light != null)
                Positioned(
                  right: Tokens.space[3],
                  bottom: Tokens.space[3] + 56 + Tokens.space[2] + 40,
                  child: QualityMenu(light: widget.light!, originalSize: widget.originalSize, now: quality, playingLight: playingLight, onPick: setQuality),
                ),
            ],
          ),
        ),
      ),
    );
    return widget.once ? CaptureBlock(what: 'video', child: page) : page;
  }

  /// ⚙ + "480p" while the light copy plays: tap = the 화질 panel.
  Widget qualityPill(TextStyle caption) => GestureDetector(
    key: const Key('video-quality'),
    onTap: () => setState(() {
      qualityPanel = !qualityPanel;
      speedPanel = false;
    }),
    child: LiquidGlass(
      radius: Tokens.capsule,
      flat: kIsWeb,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.gear_alt_fill, color: Color(0xFFFFFFFF), size: 14),
            if (playingLight) ...[const SizedBox(width: 3), Text('${widget.light!.height}p', style: caption)],
          ],
        ),
      ),
    ),
  );

  /// Tap = the speed panel; the pill shows the speed now.
  Widget speedPill(TextStyle caption) => GestureDetector(
    key: const Key('video-speed'),
    onTap: () => setState(() => speedPanel = !speedPanel),
    child: LiquidGlass(
      radius: Tokens.capsule,
      flat: kIsWeb,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
        child: Text(speedText(speed), style: caption),
      ),
    ),
  );

  /// Telegram tip 383 + iOS menu look: a slider 0.2× – 2.5× over quick picks.
  Widget speedMenu(L l, TextStyle caption) {
    const white = Color(0xFFFFFFFF);
    return LiquidGlass(
      key: const Key('video-speed-panel'),
      radius: Tokens.radius[2],
      flat: kIsWeb,
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[2]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(l.videoSpeedTitle, style: caption),
                  const Spacer(),
                  Text(
                    speedText(speed),
                    key: const Key('video-speed-now'),
                    style: caption.copyWith(fontWeight: Tokens.semi),
                  ),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: CupertinoSlider(
                  key: const Key('video-speed-slider'),
                  value: speed,
                  min: videoSpeedMin,
                  max: videoSpeedMax,
                  divisions: ((videoSpeedMax - videoSpeedMin) * 10).round(),
                  activeColor: white,
                  thumbColor: white,
                  onChanged: (x) => setSpeed(x, remember: false),
                  onChangeEnd: (x) => setSpeed(x),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final s in videoSpeeds)
                    GestureDetector(
                      key: Key('video-speed-$s'),
                      onTap: () async {
                        await setSpeed(s);
                        if (mounted) setState(() => speedPanel = false);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                        decoration: BoxDecoration(
                          color: s == speed ? const Color(0x40FFFFFF) : const Color(0x00FFFFFF),
                          borderRadius: BorderRadius.circular(Tokens.capsule),
                        ),
                        child: Text(s == 1 ? l.videoSpeedNormal : speedText(s), style: caption),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The soft half-circle on the tapped side with "◀◀ 10초" / "10초 ▶▶".
  Widget skipRipple(BoxConstraints box, L l) {
    const white = Color(0xFFFFFFFF);
    final back = skipSide < 0;
    final w = box.maxWidth * 0.38;
    return Positioned(
      key: Key(back ? 'video-skip-back' : 'video-skip-fwd'),
      top: 0,
      bottom: 0,
      left: back ? 0 : null,
      right: back ? null : 0,
      width: w,
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: BorderRadius.horizontal(
            left: back ? Radius.zero : Radius.elliptical(w, box.maxHeight / 2),
            right: back ? Radius.elliptical(w, box.maxHeight / 2) : Radius.zero,
          ),
          child: Container(
            color: const Color(0x26FFFFFF),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(back ? CupertinoIcons.backward_fill : CupertinoIcons.forward_fill, color: white, size: 26),
                SizedBox(height: Tokens.space[0]),
                Text(
                  l.videoSkipSeconds(skipSeconds),
                  style: Tokens.caption.style.copyWith(color: white, fontWeight: Tokens.semi),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
