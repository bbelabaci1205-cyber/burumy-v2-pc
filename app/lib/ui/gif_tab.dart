// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 GIF (Telegram tip 558): the GIF side of the sticker panel. Tap a GIF
// to send it; hold it for 설명 붙여 보내기, 편집해서 보내기 (글씨·그림·스티커
// and 자르기), 예약 보내기 and 내 GIF에서 빼기. GIF search (tip 353) comes in
// a later version (Eric 2026-11-17).
//
// Editing never makes a new GIF (see core/gifs.dart): the words and drawing
// become one see-through picture laid over it, and the cut is a mark.
import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../brand/mark.dart';
import '../core/app_state.dart';
import '../core/backend.dart' show Msg;
import '../core/gifs.dart';
import '../core/media_tags.dart';
import '../core/video_edit.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'schedule_send.dart' show pickSendTime;
import 'stories.dart' show showStoryToast;
import 'story_editor.dart';
import 'video_editor.dart';
import 'wide.dart';

/// Plays a GIF: a .gif picture, or a silent looping video that plays only
/// [from]..[to] ms. [layer] (words/drawing) is drawn over it.
class GifPlayer extends StatefulWidget {
  const GifPlayer({super.key, required this.bytes, required this.video, this.from = 0, this.to = -1, this.layer, this.fit = BoxFit.cover, this.onRatio});
  final Uint8List bytes;
  final bool video;
  final int from, to;
  final Uint8List? layer;
  final BoxFit fit;

  /// Width / height, once known.
  final ValueChanged<double>? onRatio;

  @override
  State<GifPlayer> createState() => _GifPlayerState();
}

class _GifPlayerState extends State<GifPlayer> {
  VideoPlayerController? c;
  File? temp;

  /// Width / height of the GIF, once known.
  double? ratio;

  @override
  void initState() {
    super.initState();
    if (widget.video) {
      unawaited(open());
    } else {
      unawaited(
        ui.instantiateImageCodec(widget.bytes).then((codec) async {
          final f = await codec.getNextFrame();
          if (mounted && f.image.height > 0) {
            setState(() => ratio = f.image.width / f.image.height);
            widget.onRatio?.call(ratio!);
          }
          f.image.dispose();
          codec.dispose();
        }, onError: (_) {}),
      );
    }
  }

  @override
  void didUpdateWidget(GifPlayer old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from && c != null) unawaited(c!.seekTo(Duration(milliseconds: widget.from)));
  }

  Future<void> open() async {
    try {
      final VideoPlayerController v;
      if (kIsWeb) {
        v = VideoPlayerController.networkUrl(Uri.dataFromBytes(widget.bytes, mimeType: 'video/mp4'));
      } else {
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/mygif-${DateTime.now().microsecondsSinceEpoch}.mp4');
        await f.writeAsBytes(widget.bytes, flush: true);
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
      v.addListener(() => keepInside(v));
      setState(() {
        c = v;
        ratio = v.value.aspectRatio;
      });
      widget.onRatio?.call(v.value.aspectRatio);
      if (widget.from > 0) await v.seekTo(Duration(milliseconds: widget.from));
      if (!mounted) return;
      final s = AppScope.read(context);
      if (s.gifsMove && !s.calm) await v.play();
    } catch (_) {}
  }

  /// The cut: back to [from] past [to] (or before [from] after a loop).
  void keepInside(VideoPlayerController v) {
    final at = v.value.position.inMilliseconds;
    final to = widget.to;
    if ((to >= 0 && at >= to) || at < widget.from - 150) unawaited(v.seekTo(Duration(milliseconds: widget.from)));
  }

  @override
  void dispose() {
    c?.dispose();
    final f = temp;
    if (f != null) unawaited(f.delete().then((_) {}, onError: (_) {}));
    super.dispose();
  }

  /// The GIF filling its box exactly (under a layer).
  Widget _plain() {
    final v = c;
    if (widget.video) return v == null ? const SizedBox.shrink() : VideoPlayer(v);
    return Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true);
  }

  @override
  Widget build(BuildContext context) {
    final v = c;
    final Widget base = widget.video
        ? (v == null
              ? const ColoredBox(
                  color: Color(0xFF1C1C1E),
                  child: Center(child: CupertinoActivityIndicator(color: Color(0xFFFFFFFF))),
                )
              : FittedBox(
                  fit: widget.fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(width: v.value.size.width, height: v.value.size.height, child: VideoPlayer(v)),
                ))
        : Image.memory(widget.bytes, fit: widget.fit, gaplessPlayback: true);
    final layer = widget.layer, r = ratio;
    if (layer == null) return base;
    // The layer was drawn over the whole GIF: crop or fit both as one.
    final both = Stack(
      fit: StackFit.expand,
      children: [
        if (r == null) base else _plain(),
        Image.memory(layer, fit: BoxFit.fill, gaplessPlayback: true),
      ],
    );
    if (r == null || widget.fit == BoxFit.fill) return both;
    return FittedBox(
      fit: widget.fit,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: 300 * r, height: 300, child: both),
    );
  }
}

/// A saved GIF, loaded from its encrypted copy.
class SavedGifView extends StatelessWidget {
  const SavedGifView({super.key, required this.gif, this.fit = BoxFit.cover});
  final SavedGif gif;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.read(context);
    return FutureBuilder<(Uint8List, Uint8List?)>(
      future: () async {
        final b = await Gifs.bytesOf(s, gif);
        Uint8List? l;
        try {
          l = await Gifs.savedLayer(s, gif);
        } catch (_) {}
        return (b, l);
      }(),
      builder: (context, snap) {
        final d = snap.data;
        if (d == null) return const ColoredBox(color: Color(0x14000000));
        return GifPlayer(bytes: d.$1, video: gif.isVideo, from: gif.from, to: gif.to, layer: d.$2, fit: fit);
      },
    );
  }
}

/// The GIF side of the sticker panel.
class GifTab extends StatefulWidget {
  const GifTab({super.key, required this.roomId, required this.onSent});
  final String roomId;
  final VoidCallback onSent;

  @override
  State<GifTab> createState() => _GifTabState();
}

class _GifTabState extends State<GifTab> {
  StreamSubscription<void>? sub;

  /// Taken out, still inside the 5 seconds to take it back.
  final leaving = <String>{};

  @override
  void initState() {
    super.initState();
    sub = Gifs.changed.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    super.dispose();
  }

  Future<void> send(SavedGif g) async {
    final s = AppScope.read(context);
    try {
      await Gifs.send(s, widget.roomId, g);
      widget.onSent();
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
  }

  Future<void> hold(SavedGif g) async {
    unawaited(HapticFeedback.mediumImpact());
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: SizedBox(
          height: Tokens.gifPreview,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
            child: SavedGifView(gif: g, fit: BoxFit.contain),
          ),
        ),
        actions: [
          CupertinoActionSheetAction(key: const Key('gif-send'), onPressed: () => Navigator.pop(c, 'send'), child: Text(l.send)),
          CupertinoActionSheetAction(key: const Key('gif-caption'), onPressed: () => Navigator.pop(c, 'caption'), child: Text(l.gifWithCaption)),
          CupertinoActionSheetAction(key: const Key('gif-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.gifEdit)),
          CupertinoActionSheetAction(key: const Key('gif-later'), onPressed: () => Navigator.pop(c, 'later'), child: Text(l.sendLater)),
          CupertinoActionSheetAction(
            key: const Key('gif-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(l.gifRemove),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    final s = AppScope.read(context);
    switch (pick) {
      case 'send':
        await send(g);
      case 'caption' || 'edit':
        final sent = await Navigator.of(context, rootNavigator: true).push<bool>(
          IosPageRoute(
            fullscreenDialog: true,
            builder: (_) => GifComposePage(roomId: widget.roomId, gif: g, edit: pick == 'edit'),
          ),
        );
        if (sent == true) widget.onSent();
      case 'later':
        final got = await pickSendTime(context);
        if (got == null || !mounted) return;
        await Gifs.schedule(s, widget.roomId, g, got.$1, repeat: got.$2);
        if (mounted) showStoryToast(context, l.scheduledDone);
        widget.onSent();
      case 'remove':
        setState(() => leaving.add(g.id));
        showUndoCountdown(
          context,
          (n) => l.gifRemoveIn(n),
          () async {
            await Gifs.remove(s, g.id);
            leaving.remove(g.id);
          },
          onUndo: () {
            if (mounted) setState(() => leaving.remove(g.id));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final s = AppScope.of(context);
    final all = Gifs.mine(s).where((g) => !leaving.contains(g.id)).toList();
    return CustomScrollView(
      key: const Key('gif-tab'),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
            child: Text(
              l.gifMine,
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: Tokens.semi),
            ),
          ),
        ),
        if (all.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              key: const Key('gif-empty'),
              padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[4], Tokens.space[5], 0),
              child: Column(
                children: [
                  Icon(CupertinoIcons.photo_on_rectangle, size: 40, color: p.secondaryLabel),
                  SizedBox(height: Tokens.space[2]),
                  Text(
                    l.gifEmpty,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 3, crossAxisSpacing: 3),
              delegate: SliverChildBuilderDelegate(
                (context, i) => GestureDetector(
                  key: Key('gif-${all[i].id}'),
                  onTap: () => send(all[i]),
                  onLongPress: () => hold(all[i]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Tokens.radius[1]),
                    child: SavedGifView(key: ValueKey(all[i].id), gif: all[i]),
                  ),
                ),
                childCount: all.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 56)),
      ],
    );
  }
}

/// 설명 붙여 보내기 / 편집해서 보내기: the GIF on black with Aa · pen ·
/// sticker at the top right (the story tools), 자르기 for a video GIF, and
/// the words field with the send button at the bottom. Hold send for 예약.
/// Pops true once sent or scheduled.
class GifComposePage extends StatefulWidget {
  const GifComposePage({super.key, required this.roomId, required this.gif, this.edit = false});
  final String roomId;
  final SavedGif gif;

  /// Opened for 편집 (else for 설명: the words field is focused).
  final bool edit;

  @override
  State<GifComposePage> createState() => _GifComposePageState();
}

class _GifComposePageState extends State<GifComposePage> {
  static const _white = Color(0xFFFFFFFF);
  final decor = GlobalKey<StoryDecorState>();
  final words = TextEditingController();
  Uint8List? bytes, oldLayer;
  double ratio = 1;
  late int from = widget.gif.from, to = widget.gif.to;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    try {
      final b = await Gifs.bytesOf(s, widget.gif);
      Uint8List? l;
      try {
        l = await Gifs.savedLayer(s, widget.gif);
      } catch (_) {}
      if (mounted) {
        setState(() {
          bytes = b;
          oldLayer = l;
        });
      }
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
  }

  @override
  void dispose() {
    words.dispose();
    super.dispose();
  }

  Future<void> trim() async {
    final b = bytes;
    if (b == null) return;
    final got = await editChatVideo(
      context,
      bytes: b,
      name: widget.gif.name,
      muted: true,
      trimOnly: true,
      start: VideoEdit(
        start: Duration(milliseconds: from),
        end: to < 0 ? null : Duration(milliseconds: to),
      ),
    );
    if (got == null || !mounted) return;
    setState(() {
      from = got.edit.start.inMilliseconds;
      to = got.edit.end?.inMilliseconds ?? -1;
    });
  }

  /// The new layer: null when nothing was added (the saved one stays).
  Future<Uint8List?> layer() async {
    final d = decor.currentState;
    if (d == null || !d.edited) return null;
    return d.flatten(width: Tokens.gifLayerWidth);
  }

  Future<void> go({bool later = false}) async {
    if (busy || bytes == null) return;
    final s = AppScope.read(context);
    final l = L.of(context);
    (DateTime, String)? when;
    if (later) {
      when = await pickSendTime(context);
      if (when == null || !mounted) return;
    }
    setState(() => busy = true);
    try {
      final drawn = await layer();
      if (when != null) {
        await Gifs.schedule(s, widget.roomId, widget.gif, when.$1, repeat: when.$2, caption: words.text.trim(), layer: drawn, from: from, to: to);
      } else {
        await Gifs.send(s, widget.roomId, widget.gif, caption: words.text.trim(), layer: drawn, from: from, to: to);
      }
      if (!mounted) return;
      if (when != null) showStoryToast(context, l.scheduledDone);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        showStoryToast(context, l.saveFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final b = bytes;
    final cut = from > 0 || to >= 0;
    return CupertinoPageScaffold(
      key: const Key('gif-compose'),
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: Tokens.topBar,
              child: Row(
                children: [
                  CupertinoButton(
                    key: const Key('gif-compose-cancel'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    onPressed: () => Navigator.pop(context),
                    child: Text(l.cancel, style: Tokens.body.style.copyWith(color: _white)),
                  ),
                  Expanded(
                    child: Text(
                      widget.edit ? l.gifEdit : l.gifWithCaption,
                      textAlign: TextAlign.center,
                      style: Tokens.navTitle.style.copyWith(color: _white),
                    ),
                  ),
                  SizedBox(width: Tokens.space[3] * 2 + Tokens.closeButton),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[2]),
                child: b == null
                    ? const Center(child: CupertinoActivityIndicator(color: _white))
                    : Center(
                        child: AspectRatio(
                          aspectRatio: ratio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Tokens.radius[2]),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                GifPlayer(
                                  bytes: b,
                                  video: widget.gif.isVideo,
                                  from: from,
                                  to: to,
                                  fit: BoxFit.fill,
                                  onRatio: (r) {
                                    if (mounted && r > 0 && (r - ratio).abs() > 0.01) setState(() => ratio = r.clamp(0.5, 2.4));
                                  },
                                ),
                                // The old layer sits inside the decor so a
                                // new one is drawn on top of it as one.
                                StoryDecor(
                                  key: decor,
                                  plainStickers: true,
                                  background: oldLayer == null ? null : Image.memory(oldLayer!, fit: BoxFit.fill),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (widget.gif.isVideo)
              CupertinoButton(
                key: const Key('gif-trim'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                minimumSize: const Size(0, 36),
                onPressed: b == null ? null : trim,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.scissors, size: Tokens.listIcon, color: cut ? Palette.tileYellow : _white),
                    SizedBox(width: Tokens.space[0]),
                    Text(l.gifTrim, style: Tokens.preview.style.copyWith(color: cut ? Palette.tileYellow : _white)),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[2]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      key: const Key('gif-caption-field'),
                      controller: words,
                      autofocus: !widget.edit,
                      minLines: 1,
                      maxLines: 4,
                      placeholder: l.gifCaptionHint,
                      placeholderStyle: Tokens.body.style.copyWith(color: _white.withValues(alpha: 0.5)),
                      style: Tokens.body.style.copyWith(color: _white),
                      cursorColor: p.accent,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(Tokens.closeButton / 2)),
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  GestureDetector(
                    key: const Key('gif-compose-send'),
                    onTap: () => go(),
                    onLongPress: () => go(later: true),
                    child: Container(
                      width: Tokens.closeButton,
                      height: Tokens.closeButton,
                      decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: busy ? CupertinoActivityIndicator(color: p.onAccent) : BurumyMark(color: p.onAccent, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Words and drawing over a GIF in a chat (tip 558): from the hidden note
/// of the person who sent it. Nothing until it arrives.
class GifLayerOver extends StatefulWidget {
  const GifLayerOver({super.key, required this.msg, required this.child});
  final Msg msg;
  final Widget child;

  @override
  State<GifLayerOver> createState() => _GifLayerOverState();
}

class _GifLayerOverState extends State<GifLayerOver> {
  Uint8List? layer;
  StreamSubscription<void>? sub;

  @override
  void initState() {
    super.initState();
    if (MediaTags.of(widget.msg.body).layer == null) return;
    sub = Gifs.changed.stream.listen((_) => unawaited(fetch()));
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(fetch()));
  }

  Future<void> fetch() async {
    final id = MediaTags.of(widget.msg.body).layer;
    if (id == null || layer != null || !mounted) return;
    try {
      final got = await Gifs.layerOf(AppScope.read(context), id, widget.msg.sender);
      if (got != null && mounted) setState(() => layer = got);
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = layer;
    if (l == null) return widget.child;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: Image.memory(l, key: const Key('gif-layer'), fit: BoxFit.fill, gaplessPlayback: true),
          ),
        ),
      ],
    );
  }
}
