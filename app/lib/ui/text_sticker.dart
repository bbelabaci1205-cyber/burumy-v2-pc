// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 글자 스티커 (4-app board, WhatsApp 2026.1): type a few words, pick a
// shape and a colour, and they become a sticker. Drawn on this phone, saved
// to 내 스티커 like any made sticker, and sent as a PNG (so every Burumy shows
// it as a sticker, without a bubble).
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'sticker_maker.dart' show addMySticker;

/// The shapes: plain words with an outline, a speech bubble, a round
/// badge, a tag.
const textStickerShapes = ['plain', 'bubble', 'badge', 'tag'];

/// iOS system colours (Burumy icon-tile palette), white words on top.
const textStickerColors = <Color>[
  Color(0xFF34C759), // green
  Color(0xFF007AFF), // blue
  Color(0xFFFF9500), // orange
  Color(0xFFFF2D55), // pink
  Color(0xFFAF52DE), // purple
  Color(0xFFFFCC00), // yellow (dark words)
  Color(0xFF1C1C1E), // black
];

/// Most words a sticker takes (two short lines).
const textStickerMax = 24;

bool _darkWords(Color c) => c.computeLuminance() > 0.55;

/// Draws [words] as a 512×512 sticker PNG with a transparent background.
Future<Uint8List> renderTextSticker(String words, {required String shape, required Color color}) async {
  const size = 512.0;
  final text = words.trim();
  final ink = _darkWords(color) ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
  final plain = shape == 'plain';
  // Room for the words, leaving the white edge inside the 512px.
  final wide = switch (shape) {
    'badge' => 330.0,
    'plain' => 440.0,
    _ => 380.0,
  };
  // Biggest font that fits: one line first (Korean words would otherwise
  // break mid-word), then two lines for longer words.
  TextPainter lay(double fs, int lines) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Pretendard', fontSize: fs, fontWeight: FontWeight.w800, height: 1.08, color: plain ? color : ink),
    ),
    textAlign: TextAlign.center,
    maxLines: lines,
    ellipsis: '…',
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: wide);
  final maxH = shape == 'badge' ? 280.0 : 300.0;
  TextPainter? found;
  for (var fs = 150.0; fs >= 72 && found == null; fs -= 6) {
    final one = lay(fs, 1);
    if (!one.didExceedMaxLines) found = one;
  }
  if (found == null) {
    for (var fs = 120.0; fs >= 40; fs -= 6) {
      found = lay(fs, 2);
      if (!found.didExceedMaxLines && found.height <= maxH) break;
    }
  }
  final tp = found!;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final center = const Offset(size / 2, size / 2);
  final shadow = Paint()
    ..color = const Color(0x33000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final fill = Paint()..color = color;
  final white = Paint()..color = const Color(0xFFFFFFFF);
  switch (shape) {
    case 'bubble':
      final box = Rect.fromCenter(center: center.translate(0, -20), width: math.max(tp.width + 90, 260), height: tp.height + 80);
      final r = RRect.fromRectAndRadius(box, const Radius.circular(64));
      final tail = Path()
        ..moveTo(box.left + 70, box.bottom - 10)
        ..lineTo(box.left + 40, box.bottom + 56)
        ..lineTo(box.left + 130, box.bottom - 10)
        ..close();
      // One outline around box and tail together.
      final all = Path.combine(PathOperation.union, Path()..addRRect(r), tail);
      c.drawPath(all.shift(const Offset(0, 6)), shadow);
      // White edge, as on every Burumy sticker.
      c.drawPath(all, white..style = PaintingStyle.stroke..strokeWidth = 18..strokeJoin = StrokeJoin.round);
      c.drawPath(all, fill);
      tp.paint(c, box.center - Offset(tp.width / 2, tp.height / 2));
    case 'badge':
      final rad = math.min(236.0, math.max(tp.width, tp.height) / 2 + 70);
      c.drawCircle(center.translate(0, 6), rad, shadow);
      c.drawCircle(center, rad + 9, white..style = PaintingStyle.fill);
      c.drawCircle(center, rad, fill);
      tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
    case 'tag':
      final box = Rect.fromCenter(center: center, width: math.max(tp.width + 80, 220), height: tp.height + 56);
      final r = RRect.fromRectAndRadius(box, const Radius.circular(22));
      c.save();
      c.translate(center.dx, center.dy);
      c.rotate(-0.08);
      c.translate(-center.dx, -center.dy);
      c.drawRRect(r.shift(const Offset(0, 6)), shadow);
      c.drawRRect(r.inflate(9), white..style = PaintingStyle.fill);
      c.drawRRect(r, fill);
      tp.paint(c, box.center - Offset(tp.width / 2, tp.height / 2));
      c.restore();
    default:
      // Plain: coloured words with a thick white edge.
      final edge = TextPainter(
        text: TextSpan(
          text: text,
          style: (tp.text! as TextSpan).style!.copyWith(
            color: null,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 22
              ..strokeJoin = StrokeJoin.round
              ..color = const Color(0xFFFFFFFF),
          ),
        ),
        textAlign: TextAlign.center,
        maxLines: tp.maxLines,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: wide);
      final at = center - Offset(tp.width / 2, tp.height / 2);
      edge.paint(c, at);
      tp.paint(c, at);
  }
  final img = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// The maker. Pops with the finished PNG (already saved to 내 스티커).
class TextStickerPage extends StatefulWidget {
  const TextStickerPage({super.key});

  @override
  State<TextStickerPage> createState() => _TextStickerPageState();
}

class _TextStickerPageState extends State<TextStickerPage> {
  final words = TextEditingController();
  String shape = 'bubble';
  Color color = textStickerColors.first;
  Uint8List? preview;
  int _draw = 0;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    words.addListener(redraw);
  }

  @override
  void dispose() {
    words.dispose();
    super.dispose();
  }

  Future<void> redraw() async {
    final n = ++_draw;
    final t = words.text.trim();
    if (t.isEmpty) {
      if (mounted) setState(() => preview = null);
      return;
    }
    final png = await renderTextSticker(t, shape: shape, color: color);
    if (mounted && n == _draw) setState(() => preview = png);
  }

  Future<void> done() async {
    final png = preview;
    if (png == null || busy) return;
    setState(() => busy = true);
    await addMySticker(AppScope.read(context), png);
    if (mounted) Navigator.pop(context, png);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], 0),
              child: Row(
                children: [
                  GestureDetector(
                    key: const Key('tsticker-close'),
                    onTap: () => Navigator.pop(context),
                    child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                  ),
                  Expanded(
                    child: Text(l.textStickerTitle, textAlign: TextAlign.center, style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi)),
                  ),
                  CupertinoButton(
                    key: const Key('tsticker-done'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                    onPressed: preview == null || busy ? null : done,
                    child: Text(l.textStickerSave, style: TextStyle(fontWeight: Tokens.semi, color: preview == null ? p.secondaryLabel : p.accent)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: preview == null
                      ? Center(
                          child: Text(l.textStickerHint, textAlign: TextAlign.center, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                        )
                      : Image.memory(preview!, key: const Key('tsticker-preview'), gaplessPlayback: true),
                ),
              ),
            ),
            // Shapes.
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                children: [
                  for (final sh in textStickerShapes)
                    Padding(
                      padding: EdgeInsets.only(right: Tokens.space[1]),
                      child: GestureDetector(
                        key: Key('tsticker-shape-$sh'),
                        onTap: () {
                          setState(() => shape = sh);
                          redraw();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: shape == sh ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
                          child: Text(
                            switch (sh) {
                              'plain' => l.textStickerPlain,
                              'bubble' => l.textStickerBubble,
                              'badge' => l.textStickerBadge,
                              _ => l.textStickerTag,
                            },
                            style: Tokens.preview.style.copyWith(color: shape == sh ? p.onAccent : p.label),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            // Colours.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final (i, c) in textStickerColors.indexed)
                  GestureDetector(
                    key: Key('tsticker-color-$i'),
                    onTap: () {
                      setState(() => color = c);
                      redraw();
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: EdgeInsets.symmetric(horizontal: Tokens.space[0] + 2),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: color == c ? p.label : const Color(0x00000000), width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(Tokens.space[3]),
              child: CupertinoTextField(
                key: const Key('tsticker-text'),
                controller: words,
                autofocus: true,
                maxLength: textStickerMax,
                placeholder: l.textStickerPlaceholder,
                textAlign: TextAlign.center,
                padding: EdgeInsets.all(Tokens.space[2]),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                onSubmitted: (_) => done(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
