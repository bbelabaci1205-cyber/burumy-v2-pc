// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat photo editor (Telegram tips 55, 70, 72, 118): turn and straighten,
// 자동 보정 + 13 adjustments, 10 filters, drawing with six pens (pen, arrow,
// highlighter, neon, eraser, blur) and words in three looks (outline,
// plain, box) on a rainbow colour bar. Everything happens on this phone;
// only the finished picture is encrypted and sent.
// #9 (tips 71, 201, 288, 370, 416): drag up on the rainbow bar for a
// thicker or thinner line, an exact colour from the colour well, two
// fingers zoom in for fine drawing (the brush gets smaller as you zoom),
// and a 스티커 tab: our stickers, emoji and a cut-out picture.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'color_pick.dart';
import 'ios_route.dart';
import 'photo_editor.dart';
import 'photo_stickers.dart';
import 'translate_ui.dart' show trNotice;

enum PenKind { pen, arrow, marker, neon, eraser, blur }

enum TextLook { outline, plain, box }

/// One finger line. Points and width are fractions of the picture's width
/// and height, so the line stays put at any size (screen or saved file).
class InkStroke {
  InkStroke(this.kind, this.color, this.width);
  final PenKind kind;
  final Color color;
  final double width;
  final points = <Offset>[];
}

/// Words on the picture. [at] = centre as a fraction of the picture.
class PhotoText {
  PhotoText(this.text, this.color, this.look);
  String text;
  Color color;
  TextLook look;
  Offset at = const Offset(.5, .45);
  double scale = 1, turn = 0;
}

/// The colours of the rainbow bar, left to right (white first, black last).
const rainbow = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFFF3B30),
  Color(0xFFFF9500),
  Color(0xFFFFCC00),
  Color(0xFF34C759),
  Color(0xFF32ADE6),
  Color(0xFF007AFF),
  Color(0xFFAF52DE),
  Color(0xFFFF2D55),
  Color(0xFF000000),
];

/// The colour at [t] (0..1) along the rainbow bar.
Color rainbowAt(double t) {
  final x = t.clamp(0.0, 1.0) * (rainbow.length - 1);
  final i = x.floor().clamp(0, rainbow.length - 2);
  return Color.lerp(rainbow[i], rainbow[i + 1], x - i)!;
}

/// Longest side of a finished picture (Telegram HD size).
const editedMaxSide = 2560;

/// Opens the editor; returns the finished PNG, or null when cancelled.
Future<Uint8List?> editChatPhoto(BuildContext context, Uint8List bytes) =>
    Navigator.of(context, rootNavigator: true).push<Uint8List>(IosPageRoute(fullscreenDialog: true, builder: (_) => MediaEditorPage(bytes: bytes)));

class MediaEditorPage extends StatefulWidget {
  const MediaEditorPage({super.key, required this.bytes});
  final Uint8List bytes;
  @override
  State<MediaEditorPage> createState() => MediaEditorPageState();
}

enum EditMode { crop, adjust, filter, draw, sticker, text }

class MediaEditorPageState extends State<MediaEditorPage> {
  final st = EditState();
  final shot = GlobalKey();
  EditMode mode = EditMode.adjust;

  /// null = 자동 보정 is the chosen dial; else one of the 13.
  Adjust? tool;
  ui.Image? img;
  bool saving = false;

  final strokes = <InkStroke>[];
  final texts = <PhotoText>[];
  final stickers = <PhotoSticker>[];

  /// The sticker whose menu is open (tap a sticker).
  PhotoSticker? chosen;

  /// Undo order: strokes and words, newest last.
  final history = <Object>[];
  PenKind pen = PenKind.pen;
  double penT = 0.0, textT = 0.0;

  /// Line thickness 0..1 (drag up on the rainbow bar); the dots are presets.
  double penSize = sizeOf(0.016);
  static const sizes = [0.008, 0.016, 0.03];
  static const minW = 0.004, maxW = 0.05;
  static double sizeOf(double w) => (w - minW) / (maxW - minW);
  double get penW => minW + penSize * (maxW - minW);

  /// An exact colour from the colour well (null = the rainbow bar's).
  Color? penPick, textPick;
  Color get penColor => penPick ?? rainbowAt(penT);
  Color get textColor => textPick ?? rainbowAt(textT);

  /// Two-finger zoom while drawing (tip 288): picture = (screen - pan) / zoom.
  double zoom = 1;
  Offset pan = Offset.zero;
  bool pinching = false;
  double pinchZoom = 1, pinchScale = 1;
  Offset pinchAt = Offset.zero, pinchPan = Offset.zero;

  PhotoText? editing;
  final words = TextEditingController();
  TextLook look = TextLook.outline;
  Object? moving; // the words or sticker being dragged
  bool overBin = false;
  Offset startAt = Offset.zero;
  double startScale = 1, startTurn = 0;

  static const _black = Color(0xFF000000);
  static const _white = Color(0xFFFFFFFF);
  static const _gold = Color(0xFFFFCC00); // iOS Photos yellow for "changed"

  bool get untouched => st.untouched && strokes.isEmpty && texts.isEmpty && stickers.isEmpty;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    words.dispose();
    img?.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodecWithSize(
        await ui.ImmutableBuffer.fromUint8List(widget.bytes),
        getTargetSize: (w, h) {
          final big = math.max(w, h);
          if (big <= editedMaxSide) return ui.TargetImageSize(width: w, height: h);
          final k = editedMaxSide / big;
          return ui.TargetImageSize(width: (w * k).round(), height: (h * k).round());
        },
      );
      final full = (await codec.getNextFrame()).image;
      final small = await (await ui.instantiateImageCodec(widget.bytes, targetWidth: 64)).getNextFrame();
      final rgba = await small.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      small.image.dispose();
      if (!mounted) return full.dispose();
      setState(() {
        img = full;
        if (rgba != null) st.stats = AutoStats.of(rgba.buffer.asUint8List());
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  void resetAll() => setState(() {
    st.reset();
    strokes.clear();
    texts.clear();
    stickers.clear();
    history.clear();
    chosen = null;
    zoom = 1;
    pan = Offset.zero;
  });

  Future<void> done() async {
    if (untouched) return Navigator.pop(context);
    setState(() {
      saving = true;
      editing = null;
      chosen = null;
      zoom = 1;
      pan = Offset.zero;
    });
    await WidgetsBinding.instance.endOfFrame;
    final box = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final i = img!;
    final long = math.max(i.width, i.height).toDouble();
    final ratio = long / math.max(box.size.width, box.size.height);
    final out = await box.toImage(pixelRatio: ratio);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    if (!mounted) return;
    Navigator.pop(context, data!.buffer.asUint8List());
  }

  void undo() => setState(() {
    if (history.isEmpty) return;
    final last = history.removeLast();
    strokes.remove(last);
    texts.remove(last);
    stickers.remove(last);
    if (last == chosen) chosen = null;
  });

  void clearAll() => setState(() {
    strokes.clear();
    texts.clear();
    stickers.clear();
    history.clear();
    chosen = null;
  });

  Future<void> addSticker() async {
    final s = await pickPhotoSticker(context);
    if (s == null || !mounted) return;
    setState(() {
      stickers.add(s);
      history.add(s);
      chosen = s.photo != null ? s : null;
    });
  }

  Future<void> cutOut(PhotoSticker s) async {
    final ok = await cutOutSticker(context, s, () {
      if (mounted) setState(() {});
    });
    if (!ok && mounted) trNotice(context, L.of(context).cutoutFail);
  }

  /// Screen point on the picture box -> fraction of the picture.
  Offset toPic(Offset p, double w, double h) {
    final q = (p - pan) / zoom;
    return Offset(q.dx / w, q.dy / h);
  }

  Offset clampPan(Offset o, double w, double h) => Offset(o.dx.clamp(w - w * zoom, 0.0), o.dy.clamp(h - h * zoom, 0.0));

  void startPinch(ScaleUpdateDetails d, double w, double h) {
    // A line started by the first finger a moment ago was not meant.
    if (strokes.isNotEmpty && history.isNotEmpty && history.last == strokes.last && strokes.last.points.length < 6) {
      history.removeLast();
      strokes.removeLast();
    }
    pinching = true;
    pinchZoom = zoom;
    pinchScale = d.scale;
    pinchPan = pan;
    pinchAt = d.localFocalPoint;
  }

  void openText([PhotoText? t]) {
    final it = t ?? PhotoText('', textColor, look);
    words.text = it.text;
    look = it.look;
    setState(() => editing = it);
  }

  void closeText() {
    final it = editing;
    if (it == null) return;
    final w = words.text.trim();
    setState(() {
      if (w.isEmpty) {
        texts.remove(it);
        history.remove(it);
      } else {
        it
          ..text = w
          ..look = look
          ..color = textColor;
        if (!texts.contains(it)) {
          texts.add(it);
          history.add(it);
        }
      }
      editing = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      key: const Key('media-editor'),
      backgroundColor: _black,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: Tokens.topBar,
                  child: Row(
                    children: [
                      CupertinoButton(
                        key: const Key('medit-cancel'),
                        // Text-only bar button: no tall default padding (it cut the words off).
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.cancel, style: Tokens.body.style.copyWith(color: _white)),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        key: const Key('medit-reset'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                        onPressed: untouched ? null : resetAll,
                        child: Text(l.editorReset, style: Tokens.body.style.copyWith(color: untouched ? _white.withValues(alpha: 0.35) : _gold)),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        key: const Key('medit-done'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                        onPressed: saving || img == null ? null : done,
                        child: saving
                            ? const CupertinoActivityIndicator(color: _white)
                            : Text(
                                l.done,
                                style: Tokens.body.style.copyWith(color: _gold, fontWeight: Tokens.semi),
                              ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: img == null ? const Center(child: CupertinoActivityIndicator(color: _white)) : LayoutBuilder(builder: (c, box) => picture(box)),
                ),
                SizedBox(height: Tokens.space[2]),
                SizedBox(height: 136, child: tools(l)),
                modeBar(l),
              ],
            ),
            if (editing != null) Positioned.fill(child: textOverlay(l)),
          ],
        ),
      ),
    );
  }

  /// The picture at the largest size that fits, turned the chosen way.
  Widget picture(BoxConstraints box) {
    final i = img!;
    final side = st.quarter.isOdd;
    final iw = (side ? i.height : i.width).toDouble(), ih = (side ? i.width : i.height).toDouble();
    final room = Size(box.maxWidth - Tokens.space[3] * 2, box.maxHeight);
    final k = math.min(room.width / iw, room.height / ih);
    final w = iw * k, h = ih * k;
    final drawing = mode == EditMode.draw && editing == null;
    final bin = Offset(w / 2, h - 40);
    final view = Matrix4.identity()
      ..translateByDouble(pan.dx, pan.dy, 0, 1)
      ..scaleByDouble(zoom, zoom, 1, 1);
    return Center(
      child: SizedBox(
        width: w,
        height: h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRect(
              child: Transform(
                transform: view,
                child: RepaintBoundary(
                  key: shot,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(child: CustomPaint(painter: PhotoPainter(i, st, strokes.where((s) => s.kind == PenKind.blur).toList()))),
                        Positioned.fill(child: CustomPaint(painter: InkPainter(strokes.where((s) => s.kind != PenKind.blur).toList()))),
                        for (final s in stickers) stickerItem(s, Size(w, h), bin),
                        for (final t in texts)
                          if (t != editing) textItem(t, Size(w, h), bin),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (drawing)
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('medit-draw-pad'),
                  onScaleStart: (d) => setState(() {
                    if (d.pointerCount > 1) return;
                    pinching = false;
                    final thick = pen == PenKind.marker || pen == PenKind.blur || pen == PenKind.eraser ? 2.2 : 1;
                    // Zoomed in = a finer brush on the picture (tip 288).
                    final s = InkStroke(pen, penColor, penW * thick / zoom);
                    s.points.add(toPic(d.localFocalPoint, w, h));
                    strokes.add(s);
                    history.add(s);
                  }),
                  onScaleUpdate: (d) => setState(() {
                    if (d.pointerCount > 1) {
                      if (!pinching) startPinch(d, w, h);
                      final picAt = (pinchAt - pinchPan) / pinchZoom;
                      zoom = (pinchZoom * d.scale / pinchScale).clamp(1.0, 6.0);
                      pan = clampPan(d.localFocalPoint - picAt * zoom, w, h);
                      return;
                    }
                    if (pinching || strokes.isEmpty) return;
                    strokes.last.points.add(toPic(d.localFocalPoint, w, h));
                  }),
                  onScaleEnd: (d) => setState(() {
                    if (d.pointerCount == 0) pinching = false;
                    if (zoom < 1.05) {
                      zoom = 1;
                      pan = Offset.zero;
                    }
                  }),
                ),
              ),
            if (chosen != null && moving == null && !saving && stickers.contains(chosen)) stickerMenu(Size(w, h)),
            if (zoom > 1)
              Positioned(
                left: Tokens.space[1],
                top: Tokens.space[1],
                child: GestureDetector(
                  key: const Key('medit-zoom-reset'),
                  onTap: () => setState(() {
                    zoom = 1;
                    pan = Offset.zero;
                  }),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                    decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(
                      '${zoom.toStringAsFixed(1)}×',
                      style: Tokens.caption.style.copyWith(color: _white, fontFeatures: const [ui.FontFeature.tabularFigures()]),
                    ),
                  ),
                ),
              ),
            if (moving != null)
              Positioned(
                left: bin.dx - 24,
                top: bin.dy - 24,
                child: AnimatedContainer(
                  key: const Key('medit-bin'),
                  duration: const Duration(milliseconds: 150),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: overBin ? Palette.tileRed : const Color(0x66000000)),
                  child: const Icon(CupertinoIcons.trash, color: _white, size: Tokens.closeIcon),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget textItem(PhotoText t, Size box, Offset bin) => Positioned(
    left: t.at.dx * box.width,
    top: t.at.dy * box.height,
    child: FractionalTranslation(
      translation: const Offset(-.5, -.5),
      child: GestureDetector(
        key: Key('medit-text-${texts.indexOf(t)}'),
        onTap: mode == EditMode.text || mode == EditMode.draw ? () => openText(t) : null,
        onScaleStart: (_) => setState(() {
          moving = t;
          startScale = t.scale;
          startTurn = t.turn;
        }),
        onScaleUpdate: (d) => setState(() {
          t.at = Offset((t.at.dx + d.focalPointDelta.dx / box.width).clamp(0, 1), (t.at.dy + d.focalPointDelta.dy / box.height).clamp(0, 1));
          t.scale = (startScale * d.scale).clamp(.3, 5);
          t.turn = startTurn + d.rotation;
          overBin = (Offset(t.at.dx * box.width, t.at.dy * box.height) - bin).distance < 48;
        }),
        onScaleEnd: (_) => setState(() {
          if (overBin) {
            texts.remove(t);
            history.remove(t);
          }
          moving = null;
          overBin = false;
        }),
        child: Transform.rotate(
          angle: t.turn,
          child: Transform.scale(
            scale: overBin && moving == t ? t.scale * .5 : t.scale,
            child: TextLookView(text: t.text, color: t.color, look: t.look, size: box.width * 0.075),
          ),
        ),
      ),
    ),
  );

  /// A sticker on the picture: drag, pinch, turn; tap for its menu; drag to
  /// the bin to throw it away.
  Widget stickerItem(PhotoSticker s, Size box, Offset bin) {
    final side = box.width * 0.3;
    final free = mode == EditMode.sticker || mode == EditMode.text || mode == EditMode.draw;
    return Positioned(
      left: s.at.dx * box.width,
      top: s.at.dy * box.height,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: GestureDetector(
          key: Key('medit-sticker-${stickers.indexOf(s)}'),
          onTap: free ? () => setState(() => chosen = chosen == s ? null : s) : null,
          onScaleStart: free
              ? (_) => setState(() {
                  moving = s;
                  chosen = null;
                  startScale = s.scale;
                  startTurn = s.turn;
                })
              : null,
          onScaleUpdate: free
              ? (d) => setState(() {
                  s.at = Offset(
                    (s.at.dx + d.focalPointDelta.dx / box.width / zoom).clamp(0, 1),
                    (s.at.dy + d.focalPointDelta.dy / box.height / zoom).clamp(0, 1),
                  );
                  s.scale = (startScale * d.scale).clamp(.3, 5);
                  s.turn = startTurn + d.rotation;
                  overBin = (Offset(s.at.dx * box.width, s.at.dy * box.height) - bin).distance < 48;
                })
              : null,
          onScaleEnd: free
              ? (_) => setState(() {
                  if (overBin) {
                    stickers.remove(s);
                    history.remove(s);
                  }
                  moving = null;
                  overBin = false;
                })
              : null,
          child: Transform.rotate(
            angle: s.turn,
            child: Transform.scale(
              scale: overBin && moving == s ? s.scale * .5 : s.scale,
              child: PhotoStickerView(s: s, side: side),
            ),
          ),
        ),
      ),
    );
  }

  /// The menu over the chosen sticker (outside the saved picture).
  Widget stickerMenu(Size box) {
    final s = chosen!;
    final side = box.width * 0.3 * (s.photo != null ? 1.3 : 1) * s.scale * zoom;
    final x = pan.dx + s.at.dx * box.width * zoom, y = pan.dy + s.at.dy * box.height * zoom;
    return Positioned(
      left: 0,
      right: 0,
      top: (y - side / 2 - 48).clamp(0.0, box.height - 40),
      child: Align(
        alignment: Alignment((x / box.width * 2 - 1).clamp(-1.0, 1.0), 0),
        child: StickerMenu(
          key: const Key('medit-sticker-menu'),
          s: s,
          onDelete: () => setState(() {
            stickers.remove(s);
            history.remove(s);
            chosen = null;
          }),
          onFlip: () => setState(() => s.flipped = !s.flipped),
          onCopy: () => setState(() {
            final c = s.copy();
            stickers.add(c);
            history.add(c);
            chosen = c;
          }),
          onCut: s.photo != null && s.cut == null && !s.cutting ? () => cutOut(s) : null,
        ),
      ),
    );
  }

  /// The colour well next to the rainbow bar: the exact-colour picker.
  Widget colorWell(Key key, Color c, ValueChanged<Color> onPick) => GestureDetector(
    key: key,
    onTap: () async {
      final got = await pickExactColor(context, c);
      if (got != null) onPick(got);
    },
    child: Container(
      width: 28,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(colors: [Color(0xFFFF3B30), Color(0xFFFFCC00), Color(0xFF34C759), Color(0xFF32ADE6), Color(0xFFAF52DE), Color(0xFFFF3B30)]),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c,
          border: Border.all(color: _black, width: 2),
        ),
      ),
    ),
  );

  Widget tools(L l) {
    switch (mode) {
      case EditMode.crop:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Plain(key: const Key('medit-rotate'), icon: CupertinoIcons.rotate_left, onTap: () => setState(() => st.quarter = (st.quarter + 3) % 4)),
                SizedBox(width: Tokens.space[4]),
                Text('${st.angle.round()}°', style: Tokens.caption.style.copyWith(color: st.angle == 0 ? _white : _gold)),
                SizedBox(width: Tokens.space[4]),
                _Plain(key: const Key('medit-flip'), icon: CupertinoIcons.arrow_left_right, onTap: () => setState(() => st.flipped = !st.flipped)),
              ],
            ),
            SizedBox(height: Tokens.space[1]),
            RulerDial(key: const Key('medit-angle'), value: st.angle / 45, onChanged: (v) => setState(() => st.angle = v * 45)),
          ],
        );
      case EditMode.filter:
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          itemCount: filterIds.length,
          separatorBuilder: (_, _) => SizedBox(width: Tokens.space[1]),
          itemBuilder: (_, i) {
            final id = filterIds[i];
            final on = st.filter == id;
            return GestureDetector(
              key: Key('medit-filter-$id'),
              onTap: () => setState(() => st.filter = id),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(filterName(l, id), style: Tokens.bubbleMeta.style.copyWith(color: on ? _white : _white.withValues(alpha: 0.6))),
                  SizedBox(height: Tokens.space[0] + 2),
                  AnimatedScale(
                    scale: on ? 1.08 : 1,
                    duration: const Duration(milliseconds: 160),
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Tokens.radius[0]),
                        boxShadow: on ? const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(0, 3))] : null,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.matrix(filterMatrix(id)),
                        child: Image.memory(widget.bytes, fit: BoxFit.cover, cacheWidth: 160),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case EditMode.adjust:
        final value = tool == null ? st.auto : st.adjust[tool]!;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${tool == null ? l.editorAuto : adjustName(l, tool!)}  ${(value * 100).round()}',
              key: const Key('medit-adjust-label'),
              style: Tokens.caption.style.copyWith(color: value == 0 ? _white : _gold),
            ),
            SizedBox(height: Tokens.space[1]),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                children: [
                  // 자동 first, like iPhone Photos' magic wand.
                  dialChip(const Key('medit-auto'), CupertinoIcons.wand_stars, null, st.auto),
                  for (final a in Adjust.values) dialChip(Key('medit-adjust-${a.name}'), adjustIcon(a), a, st.adjust[a]!),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            RulerDial(
              key: const Key('medit-dial'),
              value: value,
              onChanged: (v) => setState(() => tool == null ? st.auto = v.clamp(0.0, 1.0) : st.adjust[tool!] = v),
            ),
          ],
        );
      case EditMode.draw:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              child: Row(
                children: [
                  _Plain(key: const Key('medit-undo'), icon: CupertinoIcons.arrow_uturn_left, onTap: history.isEmpty ? null : undo),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('medit-clear'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                    onPressed: history.isEmpty ? null : clearAll,
                    child: Text(l.editorClearAll, style: Tokens.preview.style.copyWith(color: history.isEmpty ? _white.withValues(alpha: 0.35) : _white)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 52,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final k in PenKind.values)
                    GestureDetector(
                      key: Key('medit-pen-${k.name}'),
                      onTap: () => setState(() => pen = k),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                        child: AnimatedSlide(
                          // iOS Markup: the chosen pen stands up a little.
                          offset: Offset(0, pen == k ? -0.12 : 0.08),
                          duration: const Duration(milliseconds: 160),
                          child: Semantics(
                            label: penName(l, k),
                            child: CustomPaint(size: const Size(26, 52), painter: PenTipPainter(k, penColor)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                children: [
                  Expanded(
                    child: RainbowBar(
                      key: const Key('medit-rainbow'),
                      t: penT,
                      color: penColor,
                      onChanged: (v) => setState(() {
                        penT = v;
                        penPick = null;
                      }),
                      width: penSize,
                      onWidth: (v) => setState(() => penSize = v),
                    ),
                  ),
                  SizedBox(width: Tokens.space[2]),
                  colorWell(const Key('medit-color-well'), penColor, (c) => setState(() => penPick = c)),
                  SizedBox(width: Tokens.space[1]),
                  for (var i = 0; i < sizes.length; i++)
                    GestureDetector(
                      key: Key('medit-size-$i'),
                      onTap: () => setState(() => penSize = sizeOf(sizes[i])),
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: Center(
                          child: Container(
                            width: 6.0 + i * 5,
                            height: 6.0 + i * 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (penSize - sizeOf(sizes[i])).abs() < .01 ? _white : _white.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      case EditMode.sticker:
        Widget pill(Key k, IconData icon, String label, VoidCallback onTap) => CupertinoButton(
          key: k,
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            height: Tokens.closeButton,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            decoration: BoxDecoration(color: _white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: Tokens.listIcon, color: _white),
                SizedBox(width: Tokens.space[1]),
                Text(label, style: Tokens.body.style.copyWith(color: _white)),
              ],
            ),
          ),
        );
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            pill(const Key('medit-add-sticker'), CupertinoIcons.smiley, l.editorAddSticker, addSticker),
            SizedBox(height: Tokens.space[1]),
            Text(
              l.editorStickerHint,
              textAlign: TextAlign.center,
              style: Tokens.bubbleMeta.style.copyWith(color: _white.withValues(alpha: 0.6)),
            ),
          ],
        );
      case EditMode.text:
        return Center(
          child: CupertinoButton(
            key: const Key('medit-add-text'),
            onPressed: () => openText(),
            child: Container(
              height: Tokens.closeButton,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              decoration: BoxDecoration(color: _white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Aa',
                    style: Tokens.body.style.copyWith(color: _white, fontWeight: Tokens.semi),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  Text(l.editorAddText, style: Tokens.body.style.copyWith(color: _white)),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget dialChip(Key key, IconData icon, Adjust? a, double v) {
    final on = tool == a;
    return GestureDetector(
      key: key,
      onTap: () => setState(() => tool = a),
      child: Container(
        width: 44,
        height: 44,
        margin: EdgeInsets.only(right: Tokens.space[1]),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? _white.withValues(alpha: 0.18) : null,
          border: Border.all(color: v != 0 ? _gold : _white.withValues(alpha: on ? 0.9 : 0.35), width: 1.4),
        ),
        child: Icon(icon, size: 20, color: v != 0 ? _gold : _white),
      ),
    );
  }

  Widget modeBar(L l) {
    Widget tab(EditMode m, IconData i, String label) {
      final on = mode == m;
      return Expanded(
        child: CupertinoButton(
          key: Key('medit-mode-${m.name}'),
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          onPressed: () {
            setState(() {
              mode = m;
              chosen = null;
              if (m != EditMode.draw) {
                zoom = 1;
                pan = Offset.zero;
              }
            });
            if (m == EditMode.text && texts.isEmpty) openText();
            if (m == EditMode.sticker && stickers.isEmpty) addSticker();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: Tokens.listIcon, color: on ? _gold : _white.withValues(alpha: 0.6)),
              const SizedBox(height: 2),
              Text(label, style: Tokens.bubbleMeta.style.copyWith(color: on ? _gold : _white.withValues(alpha: 0.6))),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tab(EditMode.crop, CupertinoIcons.crop_rotate, l.editorCrop),
        tab(EditMode.adjust, CupertinoIcons.slider_horizontal_3, l.editorAdjust),
        tab(EditMode.filter, CupertinoIcons.circle_grid_hex, l.editorFilters),
        tab(EditMode.draw, CupertinoIcons.pencil_outline, l.editorDraw),
        tab(EditMode.sticker, CupertinoIcons.smiley, l.editorSticker),
        tab(EditMode.text, CupertinoIcons.textformat, l.editorText),
      ],
    );
  }

  /// Typing words: dimmed picture, the words in the middle, look switch
  /// and 완료 on top, the rainbow bar underneath (above the keyboard).
  Widget textOverlay(L l) {
    final c = textColor;
    return ColoredBox(
      color: const Color(0x99000000),
      child: Column(
        children: [
          // Solid bars so the editor's own buttons don't show through.
          Container(
            color: _black,
            height: Tokens.topBar,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              child: Row(
                children: [
                  CupertinoButton(
                    key: const Key('medit-text-look'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                    onPressed: () => setState(() => look = TextLook.values[(look.index + 1) % TextLook.values.length]),
                    child: TextLookIcon(look),
                  ),
                  const Spacer(),
                  CupertinoButton(
                    key: const Key('medit-text-done'),
                    padding: EdgeInsets.zero,
                    onPressed: closeText,
                    child: Text(
                      l.done,
                      style: Tokens.body.style.copyWith(color: _gold, fontWeight: Tokens.semi),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // What it will look like; the real field sits on top, see-through.
                    ValueListenableBuilder(
                      valueListenable: words,
                      builder: (_, v, _) => TextLookView(text: v.text.isEmpty ? ' ' : v.text, color: c, look: look, size: 28),
                    ),
                    IntrinsicWidth(
                      child: CupertinoTextField(
                        key: const Key('medit-text-input'),
                        controller: words,
                        autofocus: true,
                        maxLines: null,
                        maxLength: 200,
                        textAlign: TextAlign.center,
                        cursorColor: _white,
                        decoration: null,
                        padding: TextLookView.padFor(look, 28),
                        style: TextLookView.styleFor(c, look, 28).copyWith(color: const Color(0x00000000)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: _black,
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[4]),
            child: Row(
              children: [
                Expanded(
                  child: RainbowBar(
                    key: const Key('medit-text-rainbow'),
                    t: textT,
                    color: c,
                    onChanged: (v) => setState(() {
                      textT = v;
                      textPick = null;
                    }),
                  ),
                ),
                SizedBox(width: Tokens.space[2]),
                colorWell(const Key('medit-text-color-well'), c, (x) => setState(() => textPick = x)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String penName(L l, PenKind k) => switch (k) {
  PenKind.pen => l.penPen,
  PenKind.arrow => l.penArrow,
  PenKind.marker => l.penMarker,
  PenKind.neon => l.penNeon,
  PenKind.eraser => l.penEraser,
  PenKind.blur => l.penBlur,
};

class _Plain extends StatelessWidget {
  const _Plain({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
    onPressed: onTap,
    child: Icon(icon, color: Color(onTap == null ? 0x59FFFFFF : 0xFFFFFFFF), size: Tokens.listIcon + 2),
  );
}

/// Words in one of the three looks: 테두리 (dark outline), 기본 (soft
/// shadow) or 상자 (coloured box, the words in black or white).
class TextLookView extends StatelessWidget {
  const TextLookView({super.key, required this.text, required this.color, required this.look, required this.size});
  final String text;
  final Color color;
  final TextLook look;
  final double size;

  static Color inkOn(Color c) => c.computeLuminance() > .5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  static TextStyle styleFor(Color c, TextLook look, double size) => TextStyle(
    fontFamily: Tokens.font,
    fontSize: size,
    height: 1.2,
    fontWeight: Tokens.semi,
    color: look == TextLook.box ? inkOn(c) : c,
    shadows: look == TextLook.plain ? const [Shadow(color: Color(0x66000000), blurRadius: 6)] : null,
  );

  static EdgeInsets padFor(TextLook look, double size) =>
      look == TextLook.box ? EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.14) : EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final style = styleFor(color, look, size);
    Widget t = Text(text, textAlign: TextAlign.center, style: style);
    if (look == TextLook.outline) {
      t = Stack(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.16
                ..strokeJoin = StrokeJoin.round
                ..color = inkOn(color),
              color: null,
            ),
          ),
          t,
        ],
      );
    }
    return Container(
      constraints: BoxConstraints(maxWidth: size * 11),
      padding: padFor(look, size),
      decoration: look == TextLook.box ? BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.3)) : null,
      child: t,
    );
  }
}

/// The look switch: an "A" drawn the way the words will look.
class TextLookIcon extends StatelessWidget {
  const TextLookIcon(this.look, {super.key});
  final TextLook look;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 30,
    height: 30,
    child: Center(
      child: TextLookView(text: 'A', color: const Color(0xFFFFFFFF), look: look, size: 18),
    ),
  );
}

/// Rainbow colour bar: drag or tap along it; a ring shows the colour.
/// With [onWidth], dragging the finger up makes the line thicker (down =
/// thinner) and a circle above the ring shows the size (tip 71).
class RainbowBar extends StatefulWidget {
  const RainbowBar({super.key, required this.t, required this.onChanged, this.color, this.width, this.onWidth});
  final double t;
  final ValueChanged<double> onChanged;

  /// The ring's colour when it is not the bar's own (exact colour picked).
  final Color? color;
  final double? width;
  final ValueChanged<double>? onWidth;

  @override
  State<RainbowBar> createState() => _RainbowBarState();
}

class _RainbowBarState extends State<RainbowBar> {
  double? startY, startW;
  bool sizing = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      void at(Offset p) => widget.onChanged((p.dx / box.maxWidth).clamp(0.0, 1.0));
      final ring = widget.color ?? rainbowAt(widget.t);
      final left = (widget.t * box.maxWidth - 13).clamp(0.0, box.maxWidth - 26);
      final dot = 6.0 + (widget.width ?? 0) * 30;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => at(d.localPosition),
        onPanStart: (d) {
          startY = d.localPosition.dy;
          startW = widget.width;
        },
        onPanUpdate: (d) {
          final up = (startY ?? d.localPosition.dy) - d.localPosition.dy;
          if (widget.onWidth != null && startW != null && (sizing || up.abs() > 12)) {
            if (!sizing) setState(() => sizing = true);
            widget.onWidth!((startW! + up / 140).clamp(0.0, 1.0));
          } else {
            at(d.localPosition);
          }
        },
        onPanEnd: (_) => setState(() {
          sizing = false;
          startY = null;
        }),
        child: SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  gradient: const LinearGradient(colors: rainbow),
                  border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
                ),
              ),
              Positioned(
                left: left,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ring,
                    border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
                    boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 1))],
                  ),
                ),
              ),
              if (sizing)
                Positioned(
                  key: const Key('rainbow-size-preview'),
                  left: left + 13 - dot / 2,
                  bottom: 34,
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ring,
                      border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// The photo with turn, flip, straighten, colour and the 흐림 pen.
class PhotoPainter extends CustomPainter {
  PhotoPainter(this.img, this.st, this.blurs) : m = st.matrix(), q = st.quarter, a = st.angle, f = st.flipped, vig = st.adjust[Adjust.vignette]!;
  final ui.Image img;
  final EditState st;
  final List<InkStroke> blurs;
  final List<double> m;
  final int q;
  final double a, vig;
  final bool f;

  void _photo(Canvas canvas, Size size, Paint paint) {
    final side = q.isOdd;
    final dw = side ? size.height : size.width, dh = side ? size.width : size.height;
    final t = a * math.pi / 180;
    final fill = math.cos(t).abs() + math.sin(t).abs();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate((q * 90 + a) * math.pi / 180);
    canvas.scale(fill * (f ? -1 : 1), fill);
    canvas.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromCenter(center: Offset.zero, width: dw, height: dh),
      paint,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = ColorFilter.matrix(m);
    _photo(canvas, size, paint);
    if (blurs.isNotEmpty) {
      // Blurred copy of the photo, shown only where the 흐림 pen went.
      canvas.saveLayer(rect, Paint());
      for (final s in blurs) {
        canvas.drawPath(strokePath(s, size), strokePaint(size.width * s.width, const Color(0xFFFFFFFF)));
      }
      canvas.saveLayer(rect, Paint()..blendMode = BlendMode.srcIn);
      canvas.saveLayer(rect, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: size.width * 0.035, sigmaY: size.width * 0.035, tileMode: TileMode.clamp));
      _photo(canvas, size, paint);
      canvas.restore();
      canvas.restore();
      canvas.restore();
    }
    if (vig != 0) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0x00000000),
              Color(vig > 0 ? 0xFF000000 : 0xFFFFFFFF).withValues(alpha: vig.abs() * 0.6),
            ],
            stops: const [0.55, 1],
          ).createShader(rect),
      );
    }
  }

  @override
  bool shouldRepaint(PhotoPainter o) => true;
}

Path strokePath(InkStroke s, Size size) {
  final pts = [for (final p in s.points) Offset(p.dx * size.width, p.dy * size.height)];
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  if (pts.length == 1) return path..lineTo(pts.first.dx + 0.1, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    // Smooth: through the middle points (quadratic), like a real pen.
    final mid = (pts[i - 1] + pts[i]) / 2;
    path.quadraticBezierTo(pts[i - 1].dx, pts[i - 1].dy, mid.dx, mid.dy);
  }
  return path..lineTo(pts.last.dx, pts.last.dy);
}

Paint strokePaint(double w, Color c) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..color = c;

/// Pen, arrow, highlighter, neon and eraser lines (eraser takes ink away,
/// never the photo).
class InkPainter extends CustomPainter {
  InkPainter(this.strokes);
  final List<InkStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;
    canvas.saveLayer(Offset.zero & size, Paint());
    for (final s in strokes) {
      final w = size.width * s.width;
      final path = strokePath(s, size);
      switch (s.kind) {
        case PenKind.pen:
          canvas.drawPath(path, strokePaint(w, s.color));
        case PenKind.arrow:
          canvas.drawPath(path, strokePaint(w, s.color));
          final pts = [for (final p in s.points) Offset(p.dx * size.width, p.dy * size.height)];
          if (pts.length > 1) {
            final end = pts.last;
            // Direction from a point a little way back, so a shaky end doesn't twist it.
            var from = pts.first;
            for (final p in pts.reversed) {
              if ((p - end).distance > w * 4) {
                from = p;
                break;
              }
            }
            final dir = (end - from).direction;
            final head = w * 3.2 + 8;
            final hp = Path()
              ..moveTo(end.dx + math.cos(dir + 2.6) * head, end.dy + math.sin(dir + 2.6) * head)
              ..lineTo(end.dx, end.dy)
              ..lineTo(end.dx + math.cos(dir - 2.6) * head, end.dy + math.sin(dir - 2.6) * head);
            canvas.drawPath(hp, strokePaint(w, s.color));
          }
        case PenKind.marker:
          canvas.drawPath(path, strokePaint(w, s.color.withValues(alpha: 0.45))..strokeCap = StrokeCap.square);
        case PenKind.neon:
          canvas.drawPath(path, strokePaint(w * 1.8, s.color)..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.9));
          canvas.drawPath(path, strokePaint(w * 0.55, const Color(0xFFFFFFFF)));
        case PenKind.eraser:
          canvas.drawPath(path, strokePaint(w, const Color(0xFF000000))..blendMode = BlendMode.clear);
        case PenKind.blur:
          break;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InkPainter o) => true;
}

/// The pen picture in the tool row (iOS Markup look): a white body with
/// its tip in the chosen colour; eraser and blur have their own tips.
class PenTipPainter extends CustomPainter {
  PenTipPainter(this.kind, this.color);
  final PenKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * .15, s.height * .34, w * .7, s.height * .66),
      topLeft: const Radius.circular(3),
      topRight: const Radius.circular(3),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2F2F7));
    final tipColor = switch (kind) {
      PenKind.eraser => const Color(0xFFFFB3C1),
      PenKind.blur => const Color(0xFF8E8E93),
      _ => color,
    };
    final top = s.height * .34;
    final tip = Path();
    switch (kind) {
      case PenKind.marker:
        tip
          ..moveTo(w * .15, top)
          ..lineTo(w * .3, s.height * .1)
          ..lineTo(w * .7, s.height * .04)
          ..lineTo(w * .85, top);
      case PenKind.eraser:
        tip.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .15, s.height * .12, w * .7, top - s.height * .12 + 2), const Radius.circular(4)));
      case PenKind.blur:
        tip
          ..moveTo(w * .15, top)
          ..quadraticBezierTo(w * .5, -s.height * .06, w * .85, top);
      default:
        tip
          ..moveTo(w * .15, top)
          ..lineTo(w * .5, s.height * .04)
          ..lineTo(w * .85, top);
    }
    tip.close();
    final paint = Paint()..color = tipColor;
    if (kind == PenKind.neon)
      canvas.drawPath(
        tip,
        Paint()
          ..color = color.withValues(alpha: .8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    canvas.drawPath(tip, paint);
    // A band on the body in the colour (pen kinds only), and a small arrow mark.
    if (kind != PenKind.eraser && kind != PenKind.blur) {
      canvas.drawRect(Rect.fromLTWH(w * .15, top + 4, w * .7, 4), Paint()..color = tipColor);
    }
    if (kind == PenKind.arrow) {
      final y = top + 18;
      final p = strokePaint(1.6, const Color(0xFF3C3C43));
      canvas.drawLine(Offset(w * .32, y + 8), Offset(w * .68, y - 2), p);
      canvas.drawLine(Offset(w * .68, y - 2), Offset(w * .5, y - 3), p);
      canvas.drawLine(Offset(w * .68, y - 2), Offset(w * .62, y + 5), p);
    }
  }

  @override
  bool shouldRepaint(PenTipPainter o) => o.kind != kind || o.color != color;
}
