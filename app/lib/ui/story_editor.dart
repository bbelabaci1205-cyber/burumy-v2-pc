// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Instagram-style story decorating on top of the picture: words (with a
// colour and an optional box), drawing with a finger, and our stickers.
// Everything can be moved, pinched bigger or smaller and turned; drag it
// onto the bin at the bottom to remove it. On share it all becomes part of
// one picture, made on the phone.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'common.dart';
import 'glass.dart';
import 'photo_stickers.dart';
import 'sticker_panel.dart';
import 'story_keep.dart';
import 'story_more.dart';
import 'translate_ui.dart' show trNotice;
import 'video_note.dart';
import 'wide.dart';

/// Colours to pick from: white, black, then iOS colours and our green.
List<Color> storyColors(Palette p) => [
  const Color(0xFFFFFFFF),
  const Color(0xFF000000),
  Palette.tileRed,
  Palette.tileOrange,
  Palette.tileYellow,
  p.accent,
  Palette.tileBlue,
  Palette.tilePurple,
  Palette.tilePink,
];

class StoryItem {
  StoryItem.text(this.text, this.color, this.boxed) : sticker = null, pic = null;
  StoryItem.sticker(this.sticker) : text = null, color = const Color(0xFFFFFFFF), boxed = false, pic = null;

  /// 사진 오려 붙이기 (tip 416): a picture from the gallery, cut out on tap.
  StoryItem.pic(PhotoSticker this.pic) : text = null, sticker = null, color = const Color(0xFFFFFFFF), boxed = false;
  String? text;
  Color color;
  bool boxed;
  final String? sticker;
  final PhotoSticker? pic;
  Offset at = Offset.zero; // from the centre
  double scale = 1, turn = 0;
}

class StoryStroke {
  StoryStroke(this.color, this.width);
  final Color color;
  final double width;
  final points = <Offset>[];
}

/// The picture with its decorations, and the tools at the top right.
class StoryDecor extends StatefulWidget {
  const StoryDecor({super.key, this.bytes, this.background, this.liveOnly = false, this.layers = '', this.live = const [], this.onBusy, this.plainStickers = false});

  /// Only our stickers in the sticker sheet (a GIF's layer, tip 558: no
  /// polls, music or other live parts).
  final bool plainStickers;

  /// The photo; or [background] (a playing video, a channel post card).
  final Uint8List? bytes;
  final Widget? background;

  /// A video: only live parts (stickers that are not baked into a picture).
  final bool liveOnly;

  /// Words / drawing / stickers to start from (changing a story, tip 393).
  final String layers;
  final List<StoryLive> live;

  /// True while a tool is open (the composer hides its own buttons).
  final ValueChanged<bool>? onBusy;

  @override
  State<StoryDecor> createState() => StoryDecorState();
}

enum _Tool { none, text, draw }

class StoryDecorState extends State<StoryDecor> {
  final paper = GlobalKey();
  final items = <StoryItem>[];

  /// Live parts: drawn by the viewer, not baked into the picture.
  final live = <StoryLive>[];
  StoryLive? movingLive;
  double liveStartScale = 1;
  final strokes = <StoryStroke>[];
  _Tool tool = _Tool.none;
  StoryItem? editing;
  final words = TextEditingController();
  Color pen = const Color(0xFFFFFFFF);
  bool boxed = false;
  double width = 6;
  StoryItem? moving;

  /// The picture whose menu is open (삭제 · 뒤집기 · 복제 · 오려내기).
  StoryItem? chosen;
  bool overBin = false;
  Offset startAt = Offset.zero;
  double startScale = 1, startTurn = 0;

  bool get edited => items.isNotEmpty || strokes.isNotEmpty;

  /// The box size the layers were placed in (positions scale with it).
  Size box = Size.zero;
  Size? _loadedFrom;
  Map<String, dynamic>? _pending;

  @override
  void initState() {
    super.initState();
    live.addAll(widget.live);
    try {
      final j = widget.layers.isEmpty ? null : jsonDecode(widget.layers);
      if (j is Map<String, dynamic>) _pending = j;
    } catch (_) {}
  }

  /// Words, drawing and stickers as JSON, kept only on this phone so the
  /// story can be changed later (tip 393).
  String layersJson() => jsonEncode({
    'w': box.width,
    'h': box.height,
    'items': [
      for (final it in items)
        {
          if (it.text != null) 't': it.text,
          if (it.sticker != null) 's': it.sticker,
          'c': it.color.toARGB32(),
          'b': it.boxed,
          'x': it.at.dx,
          'y': it.at.dy,
          'k': it.scale,
          'r': it.turn,
        },
    ],
    'strokes': [
      for (final st in strokes)
        {
          'c': st.color.toARGB32(),
          'w': st.width,
          'p': [
            for (final o in st.points) ...[o.dx, o.dy],
          ],
        },
    ],
  });

  void _restore(Size now) {
    final j = _pending;
    if (j == null || now.isEmpty) return;
    _pending = null;
    _loadedFrom = now;
    final w = j['w'], h = j['h'];
    final f = w is num && w > 0 ? now.width / w : 1.0;
    final fy = h is num && h > 0 ? now.height / h : f;
    double n(Object? v) => v is num && v.isFinite ? v.toDouble() : 0;
    for (final x in (j['items'] as List? ?? const [])) {
      if (x is! Map) continue;
      final t = x['t'], st = x['s'];
      final it = t is String ? StoryItem.text(t, Color(n(x['c']).toInt()), x['b'] == true) : (st is String ? StoryItem.sticker(st) : null);
      if (it == null) continue;
      it
        ..at = Offset(n(x['x']) * f, n(x['y']) * fy)
        ..scale = n(x['k']) == 0 ? 1 : n(x['k'])
        ..turn = n(x['r']);
      items.add(it);
    }
    for (final x in (j['strokes'] as List? ?? const [])) {
      if (x is! Map) continue;
      final st = StoryStroke(Color(n(x['c']).toInt()), n(x['w']) == 0 ? 6 : n(x['w']));
      final pts = x['p'] as List? ?? const [];
      for (var i = 0; i + 1 < pts.length; i += 2) {
        st.points.add(Offset(n(pts[i]) * f, n(pts[i + 1]) * fy));
      }
      strokes.add(st);
    }
  }

  @override
  void dispose() {
    words.dispose();
    super.dispose();
  }

  void setTool(_Tool t) {
    setState(() => tool = t);
    widget.onBusy?.call(t != _Tool.none);
  }

  /// The decorated picture as one PNG, about [width] wide.
  Future<Uint8List?> flatten({double width = 1080}) async {
    if (chosen != null) {
      setState(() => chosen = null);
      await WidgetsBinding.instance.endOfFrame;
    }
    final b = paper.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (b == null) return null;
    final img = await b.toImage(pixelRatio: width / b.size.width);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  void openText([StoryItem? it]) {
    editing = it;
    words.text = it?.text ?? '';
    if (it != null) {
      pen = it.color;
      boxed = it.boxed;
    }
    setTool(_Tool.text);
  }

  void closeText() {
    final t = words.text.trim();
    final it = editing;
    setState(() {
      if (it != null) {
        if (t.isEmpty) {
          items.remove(it);
        } else {
          it
            ..text = t
            ..color = pen
            ..boxed = boxed;
        }
      } else if (t.isNotEmpty) {
        items.add(StoryItem.text(t, pen, boxed));
      }
      editing = null;
    });
    setTool(_Tool.none);
  }

  Future<void> addSticker() async {
    final id = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => Container(
        key: const Key('story-sticker-sheet'),
        height: 464,
        decoration: BoxDecoration(
          color: paletteOf(c).card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[2])),
        ),
        padding: EdgeInsets.only(top: Tokens.space[2]),
        child: Column(
          children: [
            // Our live parts first (answers come back in 1:1 chats), then
            // weather, a place tag and a link (tip 467).
            for (final row in [
              if (!widget.plainStickers) [
                ('poll', L.of(c).storyPoll, CupertinoIcons.chart_bar_alt_fill),
                ('question', L.of(c).storyQuestion, CupertinoIcons.question_circle_fill),
                ('plan', L.of(c).storyPlan, CupertinoIcons.calendar),
              ],
              if (!widget.plainStickers) [
                ('weather', L.of(c).stkWeather, CupertinoIcons.cloud_sun_fill),
                ('place', L.of(c).stkPlace, CupertinoIcons.location_solid),
                ('link', L.of(c).stkLink, CupertinoIcons.link),
              ],
              // Tips 395 / 408: a reaction, my own music, a round video.
              if (!widget.plainStickers) [
                ('react', L.of(c).skReact, CupertinoIcons.heart_fill),
                ('music', L.of(c).skMusic, CupertinoIcons.music_note_2),
                ('round', L.of(c).skRoundShort, CupertinoIcons.videocam_circle_fill),
              ],
            ]) ...[
              if (row.first.$1 != 'poll') SizedBox(height: Tokens.space[1]),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                child: Row(
                  children: [
                    for (final (k, label, icon) in row) ...[
                      if (k != row.first.$1) SizedBox(width: Tokens.space[1]),
                      Expanded(
                        child: GestureDetector(
                          key: Key('story-live-$k'),
                          onTap: () => Navigator.pop(c, 'live:$k'),
                          child: Container(
                            height: Tokens.closeButton,
                            decoration: BoxDecoration(color: paletteOf(c).background, borderRadius: BorderRadius.circular(Tokens.capsule)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, size: Tokens.listIcon, color: paletteOf(c).accent),
                                SizedBox(width: Tokens.space[0]),
                                Flexible(
                                  child: Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Tokens.preview.style.copyWith(color: paletteOf(c).label),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: Tokens.space[1]),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: GestureDetector(
                key: const Key('story-photo-cut'),
                onTap: () => Navigator.pop(c, 'photo'),
                child: Container(
                  height: Tokens.closeButton,
                  decoration: BoxDecoration(color: paletteOf(c).background, borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.scissors, size: Tokens.listIcon, color: paletteOf(c).accent),
                      SizedBox(width: Tokens.space[0]),
                      Text(L.of(c).stkPhotoCut, style: Tokens.preview.style.copyWith(color: paletteOf(c).label)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            Expanded(child: StickerPanel(onPick: (id) => Navigator.pop(c, id))),
          ],
        ),
      ),
    );
    if (id == null) return;
    if (id == 'photo') {
      final bytes = await pickStickerPhoto();
      if (bytes == null || !mounted) return;
      final it = StoryItem.pic(PhotoSticker.photo(bytes));
      setState(() {
        items.add(it);
        chosen = it;
      });
      return;
    }
    if (id.startsWith('live:')) {
      if (!mounted) return;
      final kind = id.substring(5);
      final it = switch (kind) {
        'react' => await _react(),
        'music' => await pickStoryMusic(context),
        'round' => await _round(),
        _ => await editLive(context, kind),
      };
      if (it != null && mounted) setState(() => live.add(it));
      return;
    }
    if (stickerAsset(id) == null) return;
    setState(() => items.add(StoryItem.sticker(id)));
  }

  Future<void> cutOut(PhotoSticker p) async {
    final ok = await cutOutSticker(context, p, () {
      if (mounted) setState(() {});
    });
    if (!ok && mounted) trNotice(context, L.of(context).cutoutFail);
  }

  Future<StoryLive?> _react() async {
    final e = await pickStoryReaction(context);
    return e == null ? null : StoryLive(kind: 'react', q: e, at: const Offset(.5, .62));
  }

  /// A round selfie video on top (tip 408), recorded like a chat one.
  Future<StoryLive?> _round() async {
    StoryLive? out;
    await openSheet<bool>(
      context,
      (_) => VideoNotePage(
        roomId: '',
        onRecorded: (bytes, mime) async => out = StoryLive(kind: 'round', mime: mime, bytes: bytes, at: const Offset(.72, .3)),
      ),
    );
    return out;
  }

  /// Live parts as JSON for the story (empty = none).
  String liveJson() => encodeLive(live);

  Widget itemView(StoryItem it) {
    if (it.sticker != null) return Image.asset(stickerAsset(it.sticker!)!, width: 140, height: 140);
    if (it.pic != null) return PhotoStickerView(s: it.pic!, side: 140);
    final dark = it.color.computeLuminance() > .5;
    final style = TextStyle(
      fontSize: 28,
      height: 1.25,
      fontWeight: Tokens.semi,
      color: it.boxed ? (dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF)) : it.color,
    );
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: it.boxed ? EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]) : EdgeInsets.zero,
      decoration: it.boxed ? BoxDecoration(color: it.color, borderRadius: BorderRadius.circular(Tokens.radius[1])) : null,
      child: Text(
        it.text ?? '',
        textAlign: TextAlign.center,
        style: it.boxed ? style : style.copyWith(shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    const white = Color(0xFFFFFFFF);
    return LayoutBuilder(
      builder: (context, box) {
        this.box = box.biggest;
        if (_pending != null && _loadedFrom == null) _restore(box.biggest);
        final centre = box.biggest.center(Offset.zero);
        final bin = Offset(centre.dx, box.maxHeight - 56);
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: paper,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.bytes != null) Image.memory(widget.bytes!, fit: BoxFit.cover, gaplessPlayback: true) else ?widget.background,
                  CustomPaint(painter: _Ink(strokes)),
                  for (final it in items)
                    Positioned(
                      left: centre.dx + it.at.dx,
                      top: centre.dy + it.at.dy,
                      child: FractionalTranslation(
                        translation: const Offset(-.5, -.5),
                        child: GestureDetector(
                          key: Key('story-item-${items.indexOf(it)}'),
                          onTap: it.text != null ? () => openText(it) : (it.pic != null ? () => setState(() => chosen = chosen == it ? null : it) : null),
                          onScaleStart: (d) {
                            moving = it;
                            chosen = null;
                            startAt = it.at;
                            startScale = it.scale;
                            startTurn = it.turn;
                            setState(() {});
                          },
                          onScaleUpdate: (d) => setState(() {
                            it.at += d.focalPointDelta;
                            it.scale = (startScale * d.scale).clamp(.3, 5);
                            it.turn = startTurn + d.rotation;
                            overBin = (centre + it.at - bin).distance < 56;
                          }),
                          onScaleEnd: (_) => setState(() {
                            if (overBin) items.remove(it);
                            moving = null;
                            overBin = false;
                          }),
                          child: Transform.rotate(
                            angle: it.turn,
                            child: Transform.scale(scale: overBin && moving == it ? it.scale * .5 : it.scale, child: itemView(it)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (chosen != null && moving == null && items.contains(chosen))
              Positioned(
                left: 0,
                right: 0,
                top: (centre.dy + chosen!.at.dy - 140 * 1.3 * chosen!.scale / 2 - 48).clamp(0.0, box.maxHeight - 40),
                child: Align(
                  alignment: Alignment(((centre.dx + chosen!.at.dx) / box.maxWidth * 2 - 1).clamp(-1.0, 1.0), 0),
                  child: StickerMenu(
                    key: const Key('story-pic-menu'),
                    s: chosen!.pic!,
                    onDelete: () => setState(() {
                      items.remove(chosen);
                      chosen = null;
                    }),
                    onFlip: () => setState(() => chosen!.pic!.flipped = !chosen!.pic!.flipped),
                    onCopy: () => setState(() {
                      final it = chosen!;
                      final c = StoryItem.pic(it.pic!.copy())
                        ..at = it.at + const Offset(24, 24)
                        ..scale = it.scale
                        ..turn = it.turn;
                      items.add(c);
                      chosen = c;
                    }),
                    onCut: chosen!.pic!.cut == null && !chosen!.pic!.cutting ? () => cutOut(chosen!.pic!) : null,
                  ),
                ),
              ),
            for (final it in live)
              Positioned(
                left: it.at.dx * box.maxWidth,
                top: it.at.dy * box.maxHeight,
                child: FractionalTranslation(
                  translation: const Offset(-.5, -.5),
                  child: GestureDetector(
                    key: Key('story-live-item-${live.indexOf(it)}'),
                    onTap: () async {
                      if (it.kind == 'react') {
                        final e = await pickStoryReaction(context);
                        if (e != null) setState(() => it.q = e);
                        return;
                      }
                      if (it.isMedia) return;
                      final x = await editLive(context, it.kind, it);
                      if (x != null) setState(() => live[live.indexOf(it)] = x);
                    },
                    onScaleStart: (_) => setState(() {
                      movingLive = it;
                      liveStartScale = it.scale;
                    }),
                    onScaleUpdate: (d) => setState(() {
                      it.at = Offset(
                        (it.at.dx + d.focalPointDelta.dx / box.maxWidth).clamp(0, 1),
                        (it.at.dy + d.focalPointDelta.dy / box.maxHeight).clamp(0, 1),
                      );
                      it.scale = (liveStartScale * d.scale).clamp(.4, 3);
                      overBin = (Offset(it.at.dx * box.maxWidth, it.at.dy * box.maxHeight) - bin).distance < 56;
                    }),
                    onScaleEnd: (_) => setState(() {
                      if (overBin) live.remove(it);
                      movingLive = null;
                      overBin = false;
                    }),
                    child: Transform.scale(
                      scale: overBin && movingLive == it ? it.scale * .5 : it.scale,
                      child: AbsorbPointer(
                        child: it.isMedia ? StoryMediaPart(item: it, muted: true) : StoryLiveCard(item: it),
                      ),
                    ),
                  ),
                ),
              ),
            if (tool == _Tool.draw)
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('story-draw-pad'),
                  onPanStart: (d) => setState(() => strokes.add(StoryStroke(pen, width)..points.add(d.localPosition))),
                  onPanUpdate: (d) => setState(() => strokes.last.points.add(d.localPosition)),
                ),
              ),
            if (moving != null || movingLive != null)
              Positioned(
                left: bin.dx - 24,
                top: bin.dy - 24,
                child: AnimatedContainer(
                  key: const Key('story-bin'),
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: overBin ? Palette.tileRed : const Color(0x66000000)),
                  child: const Icon(CupertinoIcons.trash, color: white, size: Tokens.closeIcon),
                ),
              ),
            // Tools at the top right (Instagram): Aa, pen, sticker.
            if (tool == _Tool.none && moving == null && movingLive == null)
              Positioned(
                top: Tokens.space[2],
                right: Tokens.space[2],
                child: Row(
                  children: [
                    if (!widget.liveOnly) ...[
                      GlassCircle(
                        key: const Key('story-tool-text'),
                        onTap: openText,
                        child: Text(
                          'Aa',
                          style: Tokens.body.style.copyWith(color: white, fontWeight: Tokens.semi),
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      GlassCircle(
                        key: const Key('story-tool-draw'),
                        onTap: () => setTool(_Tool.draw),
                        child: const Icon(CupertinoIcons.scribble, color: white, size: Tokens.closeIcon),
                      ),
                      SizedBox(width: Tokens.space[1]),
                    ],
                    GlassCircle(
                      key: const Key('story-tool-sticker'),
                      onTap: addSticker,
                      child: const Icon(CupertinoIcons.smiley, color: white, size: Tokens.closeIcon),
                    ),
                  ],
                ),
              ),
            if (tool == _Tool.draw) ...[
              Positioned(
                top: Tokens.space[2],
                left: Tokens.space[2],
                right: Tokens.space[2],
                child: Row(
                  children: [
                    GlassCircle(
                      key: const Key('story-draw-undo'),
                      onTap: strokes.isEmpty ? null : () => setState(strokes.removeLast),
                      child: const Icon(CupertinoIcons.arrow_uturn_left, color: white, size: Tokens.closeIcon),
                    ),
                    const Spacer(),
                    for (final w in const [3.0, 6.0, 12.0])
                      GestureDetector(
                        key: Key('story-pen-$w'),
                        onTap: () => setState(() => width = w),
                        child: SizedBox(
                          width: Tokens.closeButton,
                          height: Tokens.closeButton,
                          child: Center(
                            child: Container(
                              width: w + 6,
                              height: w + 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: white,
                                border: width == w ? Border.all(color: p.accent, width: 2) : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    _DoneButton(key: const Key('story-draw-done'), text: l.done, onTap: () => setTool(_Tool.none)),
                  ],
                ),
              ),
              Positioned(left: 0, right: 0, bottom: Tokens.space[3], child: colorRow(p)),
            ],
            if (tool == _Tool.text)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x99000000),
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                          child: IntrinsicWidth(
                            child: Container(
                              padding: boxed ? EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]) : EdgeInsets.zero,
                              decoration: boxed ? BoxDecoration(color: pen, borderRadius: BorderRadius.circular(Tokens.radius[1])) : null,
                              child: CupertinoTextField(
                                key: const Key('story-text-input'),
                                controller: words,
                                autofocus: true,
                                maxLines: null,
                                maxLength: 200,
                                textAlign: TextAlign.center,
                                cursorColor: p.accent,
                                decoration: null,
                                style: TextStyle(
                                  fontSize: 28,
                                  height: 1.25,
                                  fontWeight: Tokens.semi,
                                  color: boxed ? (pen.computeLuminance() > .5 ? const Color(0xFF000000) : white) : pen,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: Tokens.space[2],
                        left: Tokens.space[2],
                        right: Tokens.space[2],
                        child: Row(
                          children: [
                            GlassCircle(
                              key: const Key('story-text-box'),
                              onTap: () => setState(() => boxed = !boxed),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[0]),
                                decoration: boxed ? BoxDecoration(color: white, borderRadius: BorderRadius.circular(Tokens.radius[0])) : null,
                                child: Text(
                                  'A',
                                  style: Tokens.body.style.copyWith(color: boxed ? const Color(0xFF000000) : white, fontWeight: Tokens.semi),
                                ),
                              ),
                            ),
                            const Spacer(),
                            _DoneButton(key: const Key('story-text-done'), text: l.done, onTap: closeText),
                          ],
                        ),
                      ),
                      Positioned(left: 0, right: 0, bottom: Tokens.space[3], child: colorRow(p)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget colorRow(Palette p) {
    return SizedBox(
      height: Tokens.closeButton,
      child: ListView(
        key: const Key('story-colors'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        children: [
          for (final c in storyColors(p))
            GestureDetector(
              key: Key('story-color-${c.toARGB32().toRadixString(16)}'),
              onTap: () => setState(() => pen = c),
              child: SizedBox(
                width: Tokens.closeButton,
                child: Center(
                  child: Container(
                    width: pen == c ? 30 : 26,
                    height: pen == c ? 30 : 26,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFFFFF), width: pen == c ? 3 : 2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Tokens.closeButton,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          text,
          style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}

class _Ink extends CustomPainter {
  _Ink(this.strokes);
  final List<StoryStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
        continue;
      }
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (final pt in s.points.skip(1)) {
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Ink o) => true;
}
