// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스티커 만들기 (Eric 2026-11-26, Telegram's "Create sticker"): pick a photo,
// the phone cuts out the person or thing (no upload), add a white outline,
// a word and an emoji, then it is saved to 내 스티커 and sent. Where the
// phone can't cut out (web, older phones) the photo goes in a rounded
// square or a circle instead.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/backend.dart' show Msg;
import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ai_age_ui.dart';

/// Pref with my own stickers: a JSON list of PNGs (base64), newest first.
const myStickersKey = 'my_stickers';

/// At most this many are kept (they live on this phone).
const myStickersMax = 60;

/// A made sticker travels as a PNG file with this name, so every Burumy
/// shows it as a sticker (no bubble) instead of a photo.
const customStickerPrefix = 'burumy-sticker-';

bool isCustomSticker(Msg m) => m.kind == 'image' && (m.body ?? '').startsWith(customStickerPrefix);

List<Uint8List> myStickers(AppState s) {
  try {
    return [for (final x in jsonDecode(s.pref(myStickersKey, '[]')) as List) base64Decode('$x')];
  } catch (_) {
    return const [];
  }
}

Future<void> addMySticker(AppState s, Uint8List png) async {
  final all = [png, ...myStickers(s)].take(myStickersMax);
  await s.setPref(myStickersKey, jsonEncode([for (final x in all) base64Encode(x)]));
}

/// What the sticker looks like; the PNG is drawn from this.
class StickerLook {
  const StickerLook({this.cut = true, this.outline = true, this.text = '', this.emoji = '', this.circle = false});
  final bool cut;
  final bool outline;
  final String text;
  final String emoji;

  /// Without a cut-out: circle instead of a rounded square.
  final bool circle;

  StickerLook copy({bool? cut, bool? outline, String? text, String? emoji, bool? circle}) =>
      StickerLook(cut: cut ?? this.cut, outline: outline ?? this.outline, text: text ?? this.text, emoji: emoji ?? this.emoji, circle: circle ?? this.circle);
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

/// Draws the 512 x 512 sticker PNG (the size messengers use for stickers).
Future<Uint8List> renderSticker({required Uint8List photo, Uint8List? cutout, required StickerLook look}) async {
  const size = 512.0, margin = 28.0, edge = 11.0;
  var img = await _decode(look.cut && cutout != null ? cutout : photo);
  // No cut-out: the photo in a rounded square or a circle.
  if (!(look.cut && cutout != null)) {
    final side = math.min(img.width, img.height).toDouble();
    final src = Rect.fromCenter(center: Offset(img.width / 2, img.height / 2), width: side, height: side);
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    const dst = Rect.fromLTWH(0, 0, 512, 512);
    c.clipPath(Path()..addRRect(RRect.fromRectAndRadius(dst, Radius.circular(look.circle ? 256 : 96))));
    c.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.high);
    img = await r.endRecording().toImage(512, 512);
  }
  final box = Rect.fromLTWH(margin, margin, size - margin * 2, size - margin * 2);
  final fit = math.min(box.width / img.width, box.height / img.height);
  final dst = Rect.fromCenter(center: box.center, width: img.width * fit, height: img.height * fit);
  final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  if (look.outline) {
    // The white edge: the shape drawn in white, nudged all round.
    final white = Paint()..colorFilter = const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn);
    for (var a = 0; a < 24; a++) {
      final t = a * math.pi * 2 / 24;
      c.drawImageRect(img, src, dst.shift(Offset(math.cos(t) * edge, math.sin(t) * edge)), white);
    }
  }
  c.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.high);
  if (look.emoji.isNotEmpty) {
    final tp = TextPainter(
      text: TextSpan(
        text: look.emoji,
        style: const TextStyle(fontSize: 120, fontFamilyFallback: Tokens.emojiFallback),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(size - tp.width - 8, 8));
  }
  final words = look.text.trim();
  if (words.isNotEmpty) {
    TextPainter painter(Paint? stroke) => TextPainter(
      text: TextSpan(
        text: words,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 64,
          fontWeight: Tokens.semi,
          height: 1.1,
          foreground: stroke,
          color: stroke == null ? const Color(0xFFFFFFFF) : null,
        ),
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size - 32);
    final outline = painter(
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF16241B),
    );
    final fill = painter(null);
    final at = Offset((size - fill.width) / 2, size - fill.height - 18);
    outline.paint(c, at);
    fill.paint(c, at);
  }
  final out = await rec.endRecording().toImage(size.toInt(), size.toInt());
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// The maker. Pops with the finished PNG (already saved to 내 스티커).
class StickerMakerPage extends StatefulWidget {
  const StickerMakerPage({super.key});

  /// Tests hand in a photo instead of the phone's picker.
  static Future<Uint8List?> Function()? debugPick;

  @override
  State<StickerMakerPage> createState() => _StickerMakerPageState();
}

class _StickerMakerPageState extends State<StickerMakerPage> {
  static const emojis = ['', '❤️', '😂', '👍', '🎉', '😢', '🔥', '✨', '💯'];
  Uint8List? photo, cutout, preview;
  bool cutting = false, saving = false;
  StickerLook look = const StickerLook();
  final words = TextEditingController();
  int drawn = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => pick());
  }

  @override
  void dispose() {
    words.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    Uint8List? bytes;
    if (StickerMakerPage.debugPick != null) {
      bytes = await StickerMakerPage.debugPick!();
    } else {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048);
      bytes = x == null ? null : await x.readAsBytes();
    }
    if (!mounted) return;
    if (bytes == null) {
      if (photo == null) Navigator.pop(context);
      return;
    }
    setState(() {
      photo = bytes;
      cutout = null;
      cutting = true;
    });
    // Android's background removal is Google AI: 18+ only (ai_age.dart).
    final cut = await aiAgeOk(context) ? await Phone.cutout(bytes) : null;
    if (!mounted) return;
    setState(() {
      cutout = cut;
      cutting = false;
      look = look.copy(cut: cut != null);
    });
    await redraw();
  }

  Future<void> redraw() async {
    final p = photo;
    if (p == null) return;
    final n = ++drawn;
    final png = await renderSticker(photo: p, cutout: cutout, look: look);
    if (mounted && n == drawn) setState(() => preview = png);
  }

  void change(StickerLook next) {
    setState(() => look = next);
    redraw();
  }

  Future<void> done() async {
    final s = AppScope.of(context);
    final p = photo;
    if (p == null || saving) return;
    setState(() => saving = true);
    final png = await renderSticker(photo: p, cutout: cutout, look: look);
    await addMySticker(s, png);
    if (mounted) Navigator.pop(context, png);
  }

  Widget chip(Palette p, String label, bool on, VoidCallback tap, {Key? key}) => GestureDetector(
    key: key,
    onTap: tap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      // Sized by its words (an alignment would stretch it across the page).
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: on ? p.accent : p.secondaryLabel.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
      child: Text(label, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final canCut = cutout != null;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.stickerMakeTitle),
        leading: GlassCircle(
          key: const Key('maker-close'),
          size: Tokens.closeButton,
          onTap: () => Navigator.pop(context),
          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
        ),
        trailing: GlassDone(key: const Key('maker-done'), onTap: preview == null || saving ? null : done),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[3]),
          children: [
            // Preview on the see-through checkerboard.
            Center(
              child: GestureDetector(
                onTap: pick,
                child: Container(
                  key: const Key('maker-preview'),
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tokens.radius[2]), color: p.card),
                  clipBehavior: Clip.antiAlias,
                  child: CustomPaint(
                    painter: _Checker(p.dark),
                    child: cutting || preview == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CupertinoActivityIndicator(),
                                SizedBox(height: Tokens.space[1]),
                                Text(l.stickerMakeWorking, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                              ],
                            ),
                          )
                        : Image.memory(preview!, fit: BoxFit.contain, gaplessPlayback: true),
                  ),
                ),
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            Text(
              l.stickerMakeInfo,
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
            if (photo != null && !cutting && !canCut) ...[
              SizedBox(height: Tokens.space[1]),
              Text(
                l.stickerMakeNoCut,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
            ],
            SizedBox(height: Tokens.space[3]),
            Wrap(
              spacing: Tokens.space[1],
              runSpacing: Tokens.space[1],
              alignment: WrapAlignment.center,
              children: [
                if (canCut) chip(p, l.stickerMakeCut, look.cut, () => change(look.copy(cut: !look.cut)), key: const Key('maker-cut')),
                if (!canCut || !look.cut) ...[
                  chip(p, l.stickerMakeRound, !look.circle, () => change(look.copy(circle: false)), key: const Key('maker-round')),
                  chip(p, l.stickerMakeCircle, look.circle, () => change(look.copy(circle: true)), key: const Key('maker-circle')),
                ],
                chip(p, l.stickerMakeOutline, look.outline, () => change(look.copy(outline: !look.outline)), key: const Key('maker-outline')),
              ],
            ),
            SizedBox(height: Tokens.space[3]),
            Container(
              height: 44,
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22)),
              child: CupertinoTextField(
                key: const Key('maker-text'),
                controller: words,
                decoration: null,
                maxLength: 24,
                placeholder: l.stickerMakeText,
                placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                style: Tokens.body.style.copyWith(color: p.label),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                onChanged: (v) => change(look.copy(text: v)),
              ),
            ),
            SizedBox(height: Tokens.space[3]),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in emojis)
                    GestureDetector(
                      key: Key('maker-emoji-${e.isEmpty ? 'none' : e}'),
                      onTap: () => change(look.copy(emoji: e)),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.only(right: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: look.emoji == e ? p.secondaryLabel.withValues(alpha: 0.18) : null, shape: BoxShape.circle),
                        child: e.isEmpty
                            ? Icon(CupertinoIcons.nosign, size: 22, color: p.secondaryLabel)
                            : Text(e, style: const TextStyle(fontSize: 26, fontFamilyFallback: Tokens.emojiFallback)),
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

/// The grey-and-white squares that mean "see-through".
class _Checker extends CustomPainter {
  _Checker(this.dark);
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 12.0;
    final a = Paint()..color = dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF);
    final b = Paint()..color = dark ? const Color(0xFF3A3A3C) : const Color(0xFFEDEDEF);
    canvas.drawRect(Offset.zero & size, a);
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        if ((x + y).isOdd) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), b);
      }
    }
  }

  @override
  bool shouldRepaint(_Checker old) => old.dark != dark;
}

/// A made sticker in the chat: the PNG on its own, no bubble.
class CustomStickerView extends StatefulWidget {
  const CustomStickerView({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  State<CustomStickerView> createState() => _CustomStickerViewState();
}

class _CustomStickerViewState extends State<CustomStickerView> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bytes ??= AppScope.of(context).backend.downloadFile(widget.roomId, widget.msg.fileId);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: bytes,
    builder: (_, b) => b.hasData ? Image.memory(Uint8List.fromList(b.data!), fit: BoxFit.contain) : const SizedBox.expand(),
  );
}
