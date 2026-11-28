// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Photos sent together (Telegram tip 76): one bubble with a mosaic of up to
// 20 photos and videos; 가리기 (spoiler) covers a picture with moving dust
// until tapped; a video sent without sound (tip 77) plays as a GIF, on a
// loop, silent.
import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/backend.dart' show Msg;
import '../core/app_state.dart';
import '../core/media_tags.dart';
import '../design/tokens.dart';
import 'chat_page.dart' show ChatPageMime, EncryptedImage;
import 'gif_tab.dart' show GifLayerOver;
import 'media_sizes.dart';
import 'pinch_zoom.dart';

/// Rows of the mosaic for [n] pictures (Telegram-like: 2 side by side,
/// 3 = one big + two, then rows of 2 and 3).
List<int> albumRows(int n) {
  if (n <= 1) return [n];
  if (n == 2) return [2];
  if (n == 3) return [1, 2];
  if (n == 4) return [2, 2];
  final rows = <int>[];
  var left = n;
  while (left > 0) {
    final take = left == 4 ? 2 : (left >= 3 ? 3 : left);
    rows.add(take);
    left -= take;
  }
  // Two first reads better when it divides evenly (5 = 2 + 3).
  if (rows.length >= 2 && rows.first == 3 && rows.last == 2) {
    rows
      ..removeLast()
      ..insert(0, 2);
  }
  return rows;
}

/// The mosaic's layout for [count] squares, [width] wide: [cell] builds
/// square i at the given height. Shared by the chat bubble and the "+"
/// sheet's 미리보기 (so the preview looks exactly like what gets sent).
Widget albumMosaic({required int count, required double width, required Widget Function(int i, double height) cell, double gap = 2}) {
  final rows = albumRows(count);
  var at = 0;
  final children = <Widget>[];
  for (var r = 0; r < rows.length; r++) {
    final n = rows[r];
    final h = n == 1 ? width * 0.66 : (n == 2 ? width / 2 : width / 3) * 1.0;
    final cells = <Widget>[];
    for (var k = 0; k < n; k++) {
      cells.add(
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: k == 0 ? 0 : gap),
            child: cell(at + k, h),
          ),
        ),
      );
    }
    at += n;
    children.add(
      Padding(
        padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
        child: Row(children: cells),
      ),
    );
  }
  return SizedBox(
    width: width,
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// The mosaic: [items] in order; tap one to open it, spread two fingers
/// on one to look closer (tip 273).
class AlbumGrid extends StatelessWidget {
  const AlbumGrid({super.key, required this.roomId, required this.items, required this.onOpen, this.width = 260});
  final String roomId;
  final List<Msg> items;
  final void Function(int index) onOpen;
  final double width;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('album-grid'),
    child: albumMosaic(
      count: items.length,
      width: width,
      cell: (i, h) => GestureDetector(
        key: Key('album-cell-$i'),
        onTap: () => onOpen(i),
        child: SizedBox(
          height: h,
          child: AlbumCell(roomId: roomId, msg: items[i]),
        ),
      ),
    ),
  );
}

/// One square of the mosaic: the photo (covered when 가리기), or a dark
/// tile with a play mark for a video.
class AlbumCell extends StatelessWidget {
  const AlbumCell({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;
  @override
  Widget build(BuildContext context) {
    final tags = MediaTags.of(msg.body);
    Widget c = msg.kind == 'image'
        ? FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: EncryptedImage(roomId: roomId, eventId: msg.id),
          )
        : Container(
            color: const Color(0xFF1C1C1E),
            alignment: Alignment.center,
            child: const Icon(CupertinoIcons.play_circle_fill, color: Color(0xFFFFFFFF), size: 34),
          );
    c = ClipRect(child: c);
    // Covered pictures never lift (that would show them).
    return tags.spoiler
        ? ClipRect(
            child: SpoilerCover(key: Key('spoiler-${msg.id}'), child: c),
          )
        : PinchZoom(child: c);
  }
}

/// 가리기: the picture blurred under drifting dust; the first tap shows it
/// (only on this phone, only until the chat is closed). Opening plays like
/// Telegram (tip 369): the dust blows away from the finger while the blur
/// clears.
class SpoilerCover extends StatefulWidget {
  const SpoilerCover({super.key, required this.child});
  final Widget child;

  /// How long the dust takes to blow away.
  static const reveal = Duration(milliseconds: 520);

  @override
  State<SpoilerCover> createState() => _SpoilerCoverState();
}

class _SpoilerCoverState extends State<SpoilerCover> with TickerProviderStateMixin {
  bool open = false;
  late final Ticker ticker;
  late final AnimationController away = AnimationController(vsync: this, duration: SpoilerCover.reveal);
  double t = 0;
  Offset? tapAt;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((d) => setState(() => t = d.inMilliseconds / 1000))..start();
    away.addListener(() => setState(() {}));
    away.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => open = true);
        ticker.stop();
      }
    });
  }

  @override
  void dispose() {
    ticker.dispose();
    away.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (open) return widget.child;
    // Power saving / still GIFs: the dust stands still and opens at once.
    final moves = AppScope.of(context).gifsMove;
    if (!moves && ticker.isActive) ticker.stop();
    final p = Curves.easeOutCubic.transform(away.value);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: away.isAnimating
          ? null
          : (d) {
              if (!moves) {
                setState(() => open = true);
                ticker.stop();
                return;
              }
              tapAt = d.localPosition;
              away.forward();
            },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 22 * (1 - p) + 0.01, sigmaY: 22 * (1 - p) + 0.01, tileMode: TileMode.decal),
            child: widget.child,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _Dust(t, away: p, from: tapAt),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dust extends CustomPainter {
  _Dust(this.t, {this.away = 0, this.from});
  final double t;

  /// 0 = covering, 1 = blown away from [from].
  final double away;
  final Offset? from;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, 0.2 * (1 - away)));
    final r = math.Random(7);
    final n = (size.width * size.height / 140).clamp(60, 900).toInt();
    final dot = Paint();
    final o = from ?? size.center(Offset.zero);
    final reach = size.longestSide * 0.6;
    for (var i = 0; i < n; i++) {
      final speed = 6 + r.nextDouble() * 10;
      final dir = r.nextDouble() * math.pi * 2;
      var x = (r.nextDouble() * size.width + math.cos(dir) * speed * t) % size.width;
      var y = (r.nextDouble() * size.height + math.sin(dir) * speed * t) % size.height;
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;
      final dotSize = 0.7 + r.nextDouble() * 0.6;
      var a = 0.35 + 0.55 * (0.5 + 0.5 * math.sin(t * 2 + i));
      if (away > 0) {
        // Pushed out from the finger: near dots fly first and furthest.
        final d = Offset(x, y) - o;
        final len = d.distance;
        final push = (1 - (len / reach).clamp(0.0, 1.0)) * 0.6 + 0.4;
        final dirOut = len < 0.01 ? Offset(math.cos(dir), math.sin(dir)) : d / len;
        x += dirOut.dx * reach * away * push;
        y += dirOut.dy * reach * away * push;
        a *= (1 - away);
      }
      dot.color = Color.fromRGBO(255, 255, 255, a);
      canvas.drawCircle(Offset(x, y), dotSize, dot);
    }
  }

  @override
  bool shouldRepaint(_Dust o) => o.t != t || o.away != away;
}

/// A silent looping video (sent with 소리 끄기): plays by itself in the
/// chat like a GIF, with a GIF mark; tap opens it big.
class GifVideoBubble extends StatefulWidget {
  const GifVideoBubble({super.key, required this.roomId, required this.msg, required this.meta, required this.onOpen});
  final String roomId;
  final Msg msg;
  final Widget meta;
  final VoidCallback onOpen;
  @override
  State<GifVideoBubble> createState() => _GifVideoBubbleState();
}

class _GifVideoBubbleState extends State<GifVideoBubble> {
  VideoPlayerController? c;
  File? temp;
  bool started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started && AppScope.of(context).autoDownload) unawaited(start());
  }

  Future<void> start() async {
    if (started) return;
    started = true;
    try {
      final s = AppScope.read(context);
      final bytes = Uint8List.fromList(await s.backend.downloadFile(widget.roomId, widget.msg.fileId));
      final mime = ChatPageMime.of(MediaTags.plain(widget.msg.body));
      final VideoPlayerController v;
      if (kIsWeb) {
        v = VideoPlayerController.networkUrl(Uri.dataFromBytes(bytes, mimeType: mime == 'application/octet-stream' ? 'video/mp4' : mime));
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/gif-${DateTime.now().microsecondsSinceEpoch}.${mime.endsWith('quicktime') ? 'mov' : 'mp4'}');
        await f.writeAsBytes(bytes, flush: true);
        temp = f;
        v = VideoPlayerController.file(f, videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));
      }
      await v.initialize();
      await v.setVolume(0);
      await v.setLooping(true);
      if (!mounted) {
        await v.dispose();
        return;
      }
      // 자르기 (tip 558): only the chosen part plays; nothing was re-made.
      final tags = MediaTags.of(widget.msg.body);
      if (tags.trims) {
        v.addListener(() {
          final at = v.value.position.inMilliseconds;
          if ((tags.to >= 0 && at >= tags.to) || at < tags.from - 150) unawaited(v.seekTo(Duration(milliseconds: tags.from)));
        });
        await v.seekTo(Duration(milliseconds: tags.from));
      }
      setState(() => c = v);
      if (s.gifsMove) await v.play();
    } catch (_) {
      started = false;
    }
  }

  @override
  void dispose() {
    c?.dispose();
    final f = temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = c;
    const w = 240.0;
    // Before the clip starts: the shape it had before, so the row keeps its height.
    final had = MediaSizes.of(widget.msg.id);
    final ratio = v == null || !v.value.isInitialized ? (had == null ? 1.5 : w / had.height) : v.value.aspectRatio.clamp(0.6, 2.2);
    if (v != null && v.value.isInitialized) MediaSizes.note(widget.msg.id, Size(w, w / ratio));
    Widget body = v == null
        ? Container(
            color: const Color(0xFF1C1C1E),
            alignment: Alignment.center,
            child: started
                ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                : const Icon(CupertinoIcons.arrow_down_circle_fill, color: Color(0xCCFFFFFF), size: 40),
          )
        : GifLayerOver(msg: widget.msg, child: VideoPlayer(v));
    body = MediaTags.of(widget.msg.body).spoiler ? SpoilerCover(child: body) : PinchZoom(radius: Tokens.radius[2], child: body);
    return GestureDetector(
      key: const Key('gif-video'),
      onTap: v == null ? start : widget.onOpen,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        child: SizedBox(
          width: w,
          height: w / ratio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              body,
              Positioned(left: Tokens.space[1], top: Tokens.space[1], child: const GifMark()),
              Positioned(right: Tokens.space[1], bottom: Tokens.space[1], child: widget.meta),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "GIF" capsule on a looping video.
class GifMark extends StatelessWidget {
  const GifMark({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: const Color(0x80000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
    child: Text('GIF', style: Tokens.liveText.style.copyWith(color: const Color(0xFFFFFFFF))),
  );
}

/// Folds album members into their first one: (rows to show, first id →
/// every member in order). Members only fold with the same sender.
(List<Msg>, Map<String, List<Msg>>) foldAlbums(List<Msg> list) {
  final groups = <String, List<Msg>>{};
  for (final m in list) {
    if (m.viewOnce || m.imported != null || (m.kind != 'image' && m.kind != 'video')) continue;
    final a = MediaTags.of(m.body).album;
    if (a != null) groups.putIfAbsent('${m.sender}|$a', () => []).add(m);
  }
  groups.removeWhere((_, v) => v.length < 2);
  if (groups.isEmpty) return (list, const {});
  final byFirst = <String, List<Msg>>{};
  final drop = <String>{};
  for (final g in groups.values) {
    g.sort((x, y) => MediaTags.of(x.body).index.compareTo(MediaTags.of(y.body).index));
    // The bubble sits where the first-sent member is.
    final first = list.firstWhere((m) => g.contains(m));
    byFirst[first.id] = g;
    drop.addAll(g.where((m) => m != first).map((m) => m.id));
  }
  return (
    [
      for (final m in list)
        if (!drop.contains(m.id)) m,
    ],
    byFirst,
  );
}
