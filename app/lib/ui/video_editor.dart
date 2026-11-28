// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 동영상 자르기·회전 (Telegram tip 56), iPhone Photos style: the video on
// black, a strip of pictures from along it with a handle at each end to
// keep only a part, and 회전 (a quarter turn to the left) / 뒤집기 (mirror)
// / 소리 at the bottom. Nothing is cut here: the editor hands back what was
// chosen and the phone makes the new video when it is sent (before it is
// encrypted, so the cut-off parts never leave the phone).
import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/phone.dart';
import '../core/video_edit.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'ios_route.dart';

/// What the editor gives back: the cut / turn, and whether the sound is off.
typedef VideoEditResult = ({VideoEdit edit, bool muted});

/// Opens the editor full screen; null = 취소.
Future<VideoEditResult?> editChatVideo(
  BuildContext context, {
  required Uint8List bytes,
  required String name,
  VideoEdit start = VideoEdit.none,
  bool muted = false,
  bool trimOnly = false,
}) => Navigator.of(context, rootNavigator: true).push<VideoEditResult>(
  IosPageRoute(
    fullscreenDialog: true,
    builder: (_) => VideoEditorPage(bytes: bytes, name: name, start: start, muted: muted, trimOnly: trimOnly),
  ),
);

/// "0:07" / "1:02:05".
String clockText(Duration d) {
  final s = d.inSeconds;
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, r = s % 60;
  final two = r.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$two' : '$m:$two';
}

class VideoEditorPage extends StatefulWidget {
  const VideoEditorPage({super.key, required this.bytes, required this.name, this.start = VideoEdit.none, this.muted = false, this.trimOnly = false});
  final Uint8List bytes;
  final String name;
  final VideoEdit start;
  final bool muted;

  /// Only the cut (a GIF, tip 558): no turn, mirror or sound.
  final bool trimOnly;

  /// Tests: a fixed length instead of a real player.
  static Duration? debugLength;

  @override
  State<VideoEditorPage> createState() => VideoEditorPageState();
}

class VideoEditorPageState extends State<VideoEditorPage> with SingleTickerProviderStateMixin {
  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);
  static const _gold = Color(0xFFFFCC00); // iOS Photos yellow for "changed"

  VideoPlayerController? c;
  File? temp;
  bool failed = false;
  List<Uint8List> frames = const [];

  /// The whole video's length (known once the player is ready).
  Duration full = Duration.zero;

  /// Kept part, 0..1 of [full].
  double from = 0, to = 1;

  /// Where the white play line is, 0..1.
  double at = 0;
  late int turns = widget.start.turns;
  late bool flip = widget.start.flip;
  late bool muted = widget.muted;
  bool playing = false;

  /// A quarter turn plays as a short spin (iPhone Photos).
  late final spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  @override
  void initState() {
    super.initState();
    unawaited(open());
    unawaited(
      Phone.videoFrames(widget.bytes, widget.name).then((f) {
        if (mounted) setState(() => frames = f);
      }),
    );
  }

  Future<void> open() async {
    final fixed = VideoEditorPage.debugLength;
    if (fixed != null) {
      setState(() => setFull(fixed));
      return;
    }
    try {
      final VideoPlayerController v;
      final mov = widget.name.toLowerCase().endsWith('.mov');
      if (kIsWeb) {
        v = VideoPlayerController.networkUrl(Uri.dataFromBytes(widget.bytes, mimeType: mov ? 'video/quicktime' : 'video/mp4'));
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/vedit-${DateTime.now().microsecondsSinceEpoch}.${mov ? 'mov' : 'mp4'}');
        await f.writeAsBytes(widget.bytes, flush: true);
        temp = f;
        v = VideoPlayerController.file(f, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      }
      await v.initialize();
      if (!mounted) {
        await v.dispose();
        return;
      }
      await v.setVolume(muted ? 0 : 1);
      v.addListener(tick);
      setState(() {
        c = v;
        setFull(v.value.duration);
      });
      await seekTo(from);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  void setFull(Duration d) {
    full = d;
    final ms = d.inMilliseconds;
    if (ms <= 0) return;
    from = (widget.start.start.inMilliseconds / ms).clamp(0.0, 1.0);
    to = widget.start.end == null ? 1 : (widget.start.end!.inMilliseconds / ms).clamp(from, 1.0);
    at = from;
  }

  /// Keeps playing inside the kept part, round and round.
  void tick() {
    final v = c;
    if (v == null || full == Duration.zero || !mounted) return;
    final f = v.value.position.inMilliseconds / full.inMilliseconds;
    if (v.value.isPlaying && f >= to - 0.002) {
      unawaited(seekTo(from));
      return;
    }
    if (v.value.isPlaying != playing || (f - at).abs() > 0.001) {
      setState(() {
        playing = v.value.isPlaying;
        if (playing) at = f.clamp(from, to);
      });
    }
  }

  Future<void> seekTo(double f) async {
    final v = c;
    if (v == null) return;
    await v.seekTo(Duration(milliseconds: (full.inMilliseconds * f).round()));
  }

  Future<void> togglePlay() async {
    final v = c;
    if (v == null) return;
    if (v.value.isPlaying) {
      await v.pause();
    } else {
      if (at >= to - 0.01 || at < from) await seekTo(from);
      await v.play();
    }
  }

  @override
  void dispose() {
    spin.dispose();
    c?.removeListener(tick);
    c?.dispose();
    final f = temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    super.dispose();
  }

  /// Shortest part allowed, as 0..1.
  double get minPart => full.inMilliseconds <= 0 ? 0.05 : (VideoEdit.minLength.inMilliseconds / full.inMilliseconds).clamp(0.0, 1.0);

  VideoEdit get edit {
    final ms = full.inMilliseconds;
    final start = from <= 0.001 ? Duration.zero : Duration(milliseconds: (ms * from).round());
    final end = to >= 0.999 ? null : Duration(milliseconds: (ms * to).round());
    return VideoEdit(start: start, end: end, turns: turns, flip: flip);
  }

  bool get untouched => edit.isNone && muted == widget.muted;

  void rotate() {
    HapticFeedback.selectionClick();
    setState(() => turns = (turns + 1) % 4);
    spin.forward(from: 0);
  }

  void mirror() {
    HapticFeedback.selectionClick();
    setState(() => flip = !flip);
  }

  Future<void> toggleSound() async {
    setState(() => muted = !muted);
    await c?.setVolume(muted ? 0 : 1);
  }

  void reset() {
    setState(() {
      from = 0;
      to = 1;
      at = 0;
      turns = 0;
      flip = false;
      muted = widget.muted;
    });
    unawaited(c?.setVolume(muted ? 0 : 1));
    unawaited(seekTo(0));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final changed = !untouched;
    return CupertinoPageScaffold(
      key: const Key('video-editor'),
      backgroundColor: _black,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: Tokens.topBar,
              child: Row(
                children: [
                  CupertinoButton(
                    key: const Key('vedit-cancel'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel, style: Tokens.body.style.copyWith(color: _white)),
                  ),
                  Expanded(
                    child: Text(
                      l.videoEditTitle,
                      textAlign: TextAlign.center,
                      style: Tokens.navTitle.style.copyWith(color: _white),
                    ),
                  ),
                  CupertinoButton(
                    key: const Key('vedit-done'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: full == Duration.zero ? null : () => Navigator.pop<VideoEditResult>(context, (edit: edit, muted: muted)),
                    child: Text(
                      l.done,
                      style: Tokens.body.style.copyWith(color: _gold, fontWeight: Tokens.semi),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: GestureDetector(
                  key: const Key('vedit-play-area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: togglePlay,
                  child: Center(child: picture()),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: strip(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], 0),
              child: Row(
                children: [
                  Text(
                    clockText(edit.start),
                    key: const Key('vedit-from'),
                    style: Tokens.caption.style.copyWith(color: _white.withValues(alpha: 0.7)),
                  ),
                  const Spacer(),
                  Text(
                    clockText(edit.lengthOf(full)),
                    key: const Key('vedit-length'),
                    style: Tokens.caption.style.copyWith(color: edit.trims ? _gold : _white, fontWeight: Tokens.semi),
                  ),
                  const Spacer(),
                  Text(
                    clockText(edit.end ?? full),
                    key: const Key('vedit-to'),
                    style: Tokens.caption.style.copyWith(color: _white.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[3]),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!widget.trimOnly) ...[
                    tool(const Key('vedit-rotate'), CupertinoIcons.rotate_left, l.videoRotate, turns != 0, rotate),
                    tool(const Key('vedit-flip'), CupertinoIcons.arrow_right_arrow_left, l.videoFlip, flip, mirror),
                    tool(const Key('vedit-sound'), muted ? CupertinoIcons.speaker_slash_fill : CupertinoIcons.speaker_2_fill, l.videoSound, muted, toggleSound),
                  ],
                  tool(const Key('vedit-reset'), CupertinoIcons.arrow_counterclockwise, l.editorReset, false, changed ? reset : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tool(Key key, IconData icon, String label, bool on, VoidCallback? tap) {
    final color = tap == null ? _white.withValues(alpha: 0.35) : (on ? _gold : _white);
    return CupertinoButton(
      key: key,
      padding: EdgeInsets.zero,
      minimumSize: const Size(64, 52),
      onPressed: tap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: Tokens.tabIcon),
          const SizedBox(height: 3),
          Text(label, style: Tokens.tabLabel.style.copyWith(color: color)),
        ],
      ),
    );
  }

  /// The video, turned and mirrored as it will be sent.
  Widget picture() {
    final v = c;
    if (failed) return const Icon(CupertinoIcons.play_circle, color: _white, size: 56);
    final size = v == null ? const Size(16, 9) : v.value.size;
    Widget body = v == null
        ? (frames.isNotEmpty
              ? Image.memory(frames[(frames.length * at).floor().clamp(0, frames.length - 1)], fit: BoxFit.cover, gaplessPlayback: true)
              : const ColoredBox(color: Color(0xFF1C1C1E)))
        : VideoPlayer(v);
    body = SizedBox(width: size.width, height: size.height, child: body);
    if (flip) body = Transform.flip(flipX: true, child: body);
    body = RotatedBox(key: const Key('vedit-turned'), quarterTurns: (4 - turns % 4) % 4, child: body);
    body = AnimatedBuilder(
      animation: spin,
      builder: (_, child) {
        // From a quarter back to where it now sits, slowing at the end.
        final t = Curves.easeOutCubic.transform(spin.value);
        return Transform.rotate(angle: spin.isAnimating ? (1 - t) * math.pi / 2 : 0, child: child);
      },
      child: FittedBox(fit: BoxFit.contain, child: body),
    );
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        body,
        if (v != null && !playing)
          Center(
            child: Container(
              key: const Key('vedit-play'),
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.play_fill, color: _white, size: 30),
            ),
          ),
      ],
    );
  }

  static const _handle = 16.0;
  static const _stripHeight = 52.0;

  /// Pictures from along the video; a handle at each end keeps a part.
  Widget strip() => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth - _handle * 2;
      final trimmed = from > 0.001 || to < 0.999;
      final frame = trimmed ? _gold : _white;
      final left = _handle + w * from, right = _handle + w * to;
      void dragEdge(bool start, double dx) {
        setState(() {
          if (start) {
            from = (from + dx / w).clamp(0.0, to - minPart);
            at = from;
          } else {
            to = (to + dx / w).clamp(from + minPart, 1.0);
            at = to;
          }
        });
        unawaited(c?.pause());
        unawaited(seekTo(at));
      }

      void scrub(double x) {
        final f = ((x - _handle) / w).clamp(from, to);
        setState(() => at = f);
        unawaited(c?.pause());
        unawaited(seekTo(f));
      }

      return SizedBox(
        key: const Key('vedit-strip'),
        height: _stripHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The pictures (dimmed outside the kept part).
            Positioned(
              left: _handle,
              right: _handle,
              top: 2,
              bottom: 2,
              child: GestureDetector(
                key: const Key('vedit-scrub'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => scrub(d.localPosition.dx + _handle),
                onHorizontalDragUpdate: (d) => scrub(d.localPosition.dx + _handle),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.radius[0]),
                  child: Row(
                    children: [
                      for (var i = 0; i < math.max(frames.length, 1); i++)
                        Expanded(
                          child: frames.isEmpty
                              ? const ColoredBox(color: Color(0xFF2C2C2E), child: SizedBox.expand())
                              : Image.memory(frames[i], fit: BoxFit.cover, height: _stripHeight, gaplessPlayback: true),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: _handle,
              width: math.max(0, left - _handle),
              top: 2,
              bottom: 2,
              child: const IgnorePointer(child: ColoredBox(color: Color(0xA6000000))),
            ),
            Positioned(
              left: right,
              right: _handle,
              top: 2,
              bottom: 2,
              child: const IgnorePointer(child: ColoredBox(color: Color(0xA6000000))),
            ),
            // The frame around the kept part, with a handle each side.
            Positioned(
              left: left - _handle,
              width: right - left + _handle * 2,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(horizontal: BorderSide(color: frame, width: 2)),
                    borderRadius: BorderRadius.circular(Tokens.radius[0] + 2),
                  ),
                ),
              ),
            ),
            for (final start in [true, false])
              Positioned(
                left: start ? left - _handle : right,
                width: _handle,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  key: Key(start ? 'vedit-handle-start' : 'vedit-handle-end'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) => HapticFeedback.selectionClick(),
                  onHorizontalDragUpdate: (d) => dragEdge(start, d.delta.dx),
                  child: Container(
                    decoration: BoxDecoration(
                      color: frame,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(start ? Tokens.radius[0] + 2 : 0),
                        right: Radius.circular(start ? 0 : Tokens.radius[0] + 2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(start ? CupertinoIcons.chevron_left : CupertinoIcons.chevron_right, size: 13, color: _black),
                  ),
                ),
              ),
            // Where the video is now.
            Positioned(
              left: _handle + w * at - 1.5,
              width: 3,
              top: -3,
              bottom: -3,
              child: IgnorePointer(
                child: Container(
                  key: const Key('vedit-playhead'),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3)],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
