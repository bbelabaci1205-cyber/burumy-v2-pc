// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 사진 (TelegramTips 563, Eric approved 2026-11-27): the LIVE
// capsule, the play-style menu (라이브 / 반복 / 바운스 / 라이브 끄기) and the
// chat photo that moves. Look = iOS Photos LIVE capsule + iOS 27 context
// menu; the mark is drawn here (a dot, a ring and a dotted ring).
import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_state.dart';
import '../core/live_photo.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'stories.dart' show showStoryToast;

/// The Live mark: a dot, a ring around it, and a dotted outer ring
/// (crossed out when the clip is off).
class LiveMark extends StatelessWidget {
  const LiveMark({super.key, this.size = Tokens.liveMark, required this.color, this.off = false});
  final double size;
  final Color color;
  final bool off;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter(color, off));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.off);
  final Color color;
  final bool off;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final fill = Paint()..color = color;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14;
    canvas.drawCircle(c, r * 0.22, fill);
    canvas.drawCircle(c, r * 0.52, line);
    // Dotted outer ring (18 dots).
    for (var i = 0; i < 18; i++) {
      final a = i * math.pi * 2 / 18;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * 0.88), r * 0.08, fill);
    }
    if (off) {
      canvas.drawLine(c + Offset(-r, -r) * 0.9, c + Offset(r, r) * 0.9, line..strokeWidth = r * 0.16);
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color || old.off != off;
}

IconData liveStyleIcon(LiveStyle s) => switch (s) {
  LiveStyle.loop => CupertinoIcons.repeat,
  LiveStyle.bounce => CupertinoIcons.arrow_right_arrow_left,
  _ => CupertinoIcons.circle, // replaced by LiveMark in the menu
};

String liveStyleName(L l, LiveStyle s) => switch (s) {
  LiveStyle.live => l.liveStyleLive,
  LiveStyle.loop => l.liveStyleLoop,
  LiveStyle.bounce => l.liveStyleBounce,
  LiveStyle.off => l.liveStyleOff,
};

/// The see-through capsule in a photo's top-left corner: mark + "LIVE"
/// (+ ⌄ when it opens the style menu before sending).
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key, required this.style, this.onTap, this.chevron = false});
  final LiveStyle style;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    final off = style == LiveStyle.off;
    final text = Tokens.liveText.style.copyWith(color: white, letterSpacing: 0.4);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: Tokens.liveBadge,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] - 1),
        decoration: BoxDecoration(color: const Color(0x59000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (style == LiveStyle.loop || style == LiveStyle.bounce)
              Icon(liveStyleIcon(style), size: Tokens.liveMark - 1, color: white)
            else
              LiveMark(color: white, off: off),
            SizedBox(width: Tokens.space[0]),
            Text(off ? l.liveLabelOff : l.liveLabel, style: text),
            if (chevron) ...[SizedBox(width: 2), Icon(CupertinoIcons.chevron_down, size: 10, color: white)],
          ],
        ),
      ),
    );
  }
}

/// iOS 27 context menu under the capsule: 라이브 / 반복 / 바운스 / 라이브 끄기,
/// a tick on the chosen one. Shows the "turned on" note after a change.
Future<LiveStyle?> showLiveStyleMenu(BuildContext context, LiveStyle now) async {
  final box = context.findRenderObject() as RenderBox?;
  final at = box == null ? Offset.zero : box.localToGlobal(Offset(0, box.size.height + Tokens.space[0]));
  final picked = await Navigator.of(context, rootNavigator: true).push<LiveStyle>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (c, a, _) => _LiveMenu(anim: a, at: at, now: now),
    ),
  );
  if (picked == null || picked == now || !context.mounted) return picked;
  final l = L.of(context);
  showStoryToast(context, switch (picked) {
    LiveStyle.live => l.liveOnToast,
    LiveStyle.loop => l.liveLoopToast,
    LiveStyle.bounce => l.liveBounceToast,
    LiveStyle.off => l.liveOffToast,
  });
  return picked;
}

class _LiveMenu extends StatelessWidget {
  const _LiveMenu({required this.anim, required this.at, required this.now});
  final Animation<double> anim;
  final Offset at;
  final LiveStyle now;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final size = MediaQuery.sizeOf(context);
    final left = at.dx.clamp(Tokens.space[3], size.width - Tokens.liveMenuWidth - Tokens.space[3]).toDouble();
    final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    Widget row(LiveStyle s) => GestureDetector(
      key: Key('live-style-${s.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context, s),
      child: SizedBox(
        height: Tokens.liveMenuRow,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Row(
            children: [
              SizedBox(width: 22, child: Icon(CupertinoIcons.checkmark_alt, size: 18, color: s == now ? p.label : const Color(0x00000000))),
              SizedBox(width: Tokens.space[1]),
              Expanded(
                child: Text(liveStyleName(L.of(context), s), style: Tokens.body.style.copyWith(color: p.label)),
              ),
              if (s == LiveStyle.live || s == LiveStyle.off)
                LiveMark(size: 20, color: p.label, off: s == LiveStyle.off)
              else
                Icon(liveStyleIcon(s), size: 20, color: p.label),
            ],
          ),
        ),
      ),
    );
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(context)),
        ),
        Positioned(
          left: left,
          top: at.dy,
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(curve),
              alignment: Alignment.topLeft,
              child: SizedBox(
                key: const Key('live-menu'),
                width: Tokens.liveMenuWidth,
                child: LiquidGlass(
                  radius: Tokens.radius[3],
                  child: Container(
                    color: p.background.withValues(alpha: 0.55),
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[0]),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [for (final s in LiveStyle.values) row(s)]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plays a 움직이는 사진's clip over its still, in its style:
/// 라이브 = once when it shows up (and on a tap of LIVE), 반복 = over and
/// over, 바운스 = forward then backward. Silent. Stays still when GIF
/// autoplay is off or the battery saver is on (tap LIVE to play once).
class LiveLayer extends StatefulWidget {
  const LiveLayer({super.key, required this.style, required this.loadClip, required this.child, this.mime = 'video/mp4'});
  final LiveStyle style;
  final Future<List<int>> Function() loadClip;
  final String mime;

  /// The still photo.
  final Widget child;

  @override
  State<LiveLayer> createState() => LiveLayerState();
}

class LiveLayerState extends State<LiveLayer> {
  VideoPlayerController? c;
  File? temp;
  bool showing = false;
  bool backward = false;
  Timer? back;
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    final s = AppScope.of(context);
    if (s.autoDownload && s.gifsMove) {
      started = true;
      unawaited(play());
    }
  }

  Future<VideoPlayerController?> open() async {
    if (c != null) return c;
    try {
      final bytes = Uint8List.fromList(await widget.loadClip());
      if (bytes.isEmpty) return null;
      final VideoPlayerController v;
      if (kIsWeb) {
        v = VideoPlayerController.networkUrl(Uri.dataFromBytes(bytes, mimeType: widget.mime));
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/live-${DateTime.now().microsecondsSinceEpoch}.${widget.mime.endsWith('quicktime') ? 'mov' : 'mp4'}');
        await f.writeAsBytes(bytes, flush: true);
        temp = f;
        v = VideoPlayerController.file(f, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      }
      await v.initialize();
      await v.setVolume(0);
      if (!mounted) {
        await v.dispose();
        return null;
      }
      v.addListener(tick);
      setState(() => c = v);
      return v;
    } catch (_) {
      return null;
    }
  }

  /// Starts the clip (again) from the beginning.
  Future<void> play() async {
    if (widget.style == LiveStyle.off) return;
    final v = await open();
    if (v == null || !mounted) return;
    back?.cancel();
    backward = false;
    await v.setLooping(widget.style == LiveStyle.loop);
    await v.seekTo(Duration.zero);
    setState(() => showing = true);
    await v.play();
  }

  void tick() {
    final v = c;
    if (v == null || !mounted) return;
    final val = v.value;
    final atEnd = val.duration > Duration.zero && !val.isPlaying && val.position >= val.duration - const Duration(milliseconds: 60);
    if (!atEnd || backward) return;
    switch (widget.style) {
      case LiveStyle.bounce:
        // Backward: small steps toward the start, then forward again
        // (players can't run backward on their own).
        if (!AppScope.read(context).gifsMove) return setState(() => showing = false);
        backward = true;
        var pos = val.position;
        back = Timer.periodic(Tokens.liveBackStep, (t) {
          pos -= Tokens.liveBackStep;
          if (pos <= Duration.zero || !mounted) {
            t.cancel();
            backward = false;
            if (mounted) unawaited(v.play());
            return;
          }
          unawaited(v.seekTo(pos));
        });
      case LiveStyle.live:
        // Once, then back to the still photo.
        setState(() => showing = false);
      default:
        break;
    }
  }

  @override
  void dispose() {
    back?.cancel();
    c?.removeListener(tick);
    c?.dispose();
    final f = temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = c;
    return Stack(
      children: [
        widget.child,
        if (v != null && v.value.isInitialized)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showing ? 1 : 0,
                duration: Tokens.liveFade,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v)),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: Tokens.liveInset,
          top: Tokens.liveInset,
          child: LiveBadge(key: const Key('live-badge'), style: widget.style, onTap: play),
        ),
      ],
    );
  }
}
