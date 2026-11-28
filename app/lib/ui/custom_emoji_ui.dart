// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screens for 직접 만든 움직이는 이모지 (tip 354) and 그룹 이모지 묶음 (tip 430):
// the maker (from a photo or from words), the 내 이모지 / 그룹 이모지 rows on
// top of the emoji panel, the sheet for saving someone's emoji, and the
// group's emoji page (admins choose; everyone can save them all).
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/custom_emoji.dart';
import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/char_emoji.dart' show charEmojiLetter;
import '../stickers/cx_emoji_view.dart';
import 'ai_age_ui.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'sticker_maker.dart' show renderSticker, StickerLook;
import 'wide.dart';

/// Motion names, in the order the maker shows them.
String cxMotionName(L l, CxMotion m) => switch (m) {
  CxMotion.none => l.cxStill,
  CxMotion.bounce => l.cxBounce,
  CxMotion.spin => l.cxSpin,
  CxMotion.wiggle => l.cxWiggle,
  CxMotion.beat => l.cxBeat,
  CxMotion.float => l.cxFloat,
  CxMotion.jelly => l.cxJelly,
  CxMotion.sparkle => l.cxSparkle,
};

/// Square PNG of [side] px from any picture (keeps see-through parts).
Future<Uint8List> cxSquare(Uint8List src, {int side = Tokens.cxPixels}) async {
  final codec = await ui.instantiateImageCodec(src);
  final img = (await codec.getNextFrame()).image;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final k = side / (img.width > img.height ? img.width : img.height);
  final w = img.width * k, h = img.height * k;
  c.drawImageRect(
    img,
    Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
    Rect.fromLTWH((side - w) / 2, (side - h) / 2, w, h),
    Paint()..filterQuality = FilterQuality.high,
  );
  final out = await rec.endRecording().toImage(side, side);
  return (await out.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

/// Words (1–4 letters or emoji) drawn as an emoji: thick white outline,
/// coloured letters, see-through around.
Future<Uint8List> cxFromWords(String words, Color color, {int side = Tokens.cxPixels}) async {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final t = words.trim();
  double fs = side * (t.characters.length <= 1 ? 0.78 : (t.characters.length == 2 ? 0.5 : 0.36));
  TextPainter paint(Paint? stroke, Color fill) => TextPainter(
    text: TextSpan(
      text: t,
      style: TextStyle(
        fontSize: fs,
        height: 1.05,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
        fontFamilyFallback: Tokens.emojiFallback,
        foreground: stroke,
        color: stroke == null ? fill : null,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(maxWidth: side * 0.94);
  var front = paint(null, color);
  while ((front.width > side * 0.92 || front.height > side * 0.92) && fs > 10) {
    fs *= 0.9;
    front = paint(null, color);
  }
  final back = paint(
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.07
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFFFFF),
    color,
  );
  final at = Offset((side - front.width) / 2, (side - front.height) / 2);
  back.paint(c, at);
  front.paint(c, at);
  final img = await rec.endRecording().toImage(side, side);
  return (await img.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
}

// ---------------------------------------------------------------- maker

/// 움직이는 이모지 만들기: a photo (cut out on the phone where it can) or a
/// few words; how it moves; which plain emoji stands in for it. Saved to
/// 내 이모지 on this phone; returns the new id.
class CxMakerPage extends StatefulWidget {
  const CxMakerPage({super.key, this.words = false});

  /// Start with words instead of asking for a photo.
  final bool words;

  /// Tests hand in a photo instead of the phone's picker.
  static Future<Uint8List?> Function()? debugPick;

  @override
  State<CxMakerPage> createState() => _CxMakerPageState();
}

class _CxMakerPageState extends State<CxMakerPage> {
  static const bases = ['🙂', '😍', '😂', '👍', '🎉', '😢', '🔥', '✨', '❤️', '🙏'];
  static const colors = [Palette.tileRed, Palette.tileOrange, Palette.tileYellow, Palette.tileBlue, Palette.tilePurple, Palette.tilePink, Palette.tileTeal];
  late bool fromWords = widget.words;
  Uint8List? png;
  bool working = false, saving = false;
  CxMotion motion = CxMotion.bounce;
  String base = bases.first;
  Color color = colors.first;
  final words = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => fromWords ? redrawWords() : pick());
  }

  @override
  void dispose() {
    words.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    Uint8List? bytes;
    if (CxMakerPage.debugPick != null) {
      bytes = await CxMakerPage.debugPick!();
    } else {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
      bytes = x == null ? null : await x.readAsBytes();
    }
    if (!mounted || bytes == null) return;
    setState(() {
      fromWords = false;
      working = true;
    });
    // Android's background removal is Google AI: 18+ only (ai_age.dart).
    final cut = await aiAgeOk(context) ? await Phone.cutout(bytes) : null;
    final drawn = await renderSticker(
      photo: bytes,
      cutout: cut,
      look: StickerLook(cut: cut != null, outline: true),
    );
    final small = await cxSquare(drawn);
    if (mounted) {
      setState(() {
        png = small;
        working = false;
      });
    }
  }

  Future<void> redrawWords() async {
    final t = words.text.trim();
    if (t.isEmpty) return setState(() => png = null);
    final got = await cxFromWords(t, color);
    if (mounted && words.text.trim() == t) setState(() => png = got);
  }

  Future<void> done() async {
    final s = AppScope.read(context);
    final p = png;
    if (p == null || saving) return;
    setState(() => saving = true);
    final e = await CustomEmojis.addMine(s, CxEmoji.make(p, motion, base));
    if (mounted) Navigator.pop(context, e.id);
  }

  Widget chip(Palette p, String label, bool on, VoidCallback tap, {Key? key}) => GestureDetector(
    key: key,
    onTap: tap,
    child: IntrinsicWidth(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(label, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final e = png == null ? null : CxEmoji.make(png!, motion, base);
    if (e != null) CustomEmojis.known[e.id] = e;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.cxMakeTitle),
        leading: GlassCircle(
          key: const Key('cx-close'),
          size: Tokens.closeButton,
          onTap: () => Navigator.pop(context),
          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
        ),
        trailing: GlassDone(key: const Key('cx-done'), onTap: png == null || saving ? null : done),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[3]),
          children: [
            // Big, and the way it looks between words.
            Container(
              key: const Key('cx-preview'),
              height: 220,
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
              child: working
                  ? const Center(child: CupertinoActivityIndicator())
                  : e == null
                  ? Center(
                      child: Text(
                        fromWords ? l.cxWordsHint : l.cxPhotoHint,
                        textAlign: TextAlign.center,
                        style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CxEmojiView(e.id, size: Tokens.cxBig, key: ValueKey('big-${e.id}')),
                        SizedBox(height: Tokens.space[2]),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                          decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(l.cxSample, style: Tokens.body.style.copyWith(color: p.onAccent)),
                              SizedBox(width: Tokens.space[0]),
                              CxEmojiView(e.id, size: 22, key: ValueKey('small-${e.id}')),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            SizedBox(height: Tokens.space[3]),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                chip(p, l.cxFromPhoto, !fromWords, pick, key: const Key('cx-photo')),
                SizedBox(width: Tokens.space[1]),
                chip(p, l.cxFromWords, fromWords, () {
                  setState(() {
                    fromWords = true;
                    png = null;
                  });
                  redrawWords();
                }, key: const Key('cx-words')),
              ],
            ),
            if (fromWords) ...[
              SizedBox(height: Tokens.space[2]),
              Container(
                height: 44,
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(22)),
                child: CupertinoTextField(
                  key: const Key('cx-text'),
                  controller: words,
                  decoration: null,
                  maxLength: 4,
                  placeholder: l.cxWordsPlaceholder,
                  placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                  style: Tokens.body.style.copyWith(color: p.label),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  onChanged: (_) => redrawWords(),
                ),
              ),
              SizedBox(height: Tokens.space[2]),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in colors)
                    GestureDetector(
                      onTap: () {
                        setState(() => color = c);
                        redrawWords();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: color == c ? Border.all(color: p.label, width: 2) : null,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            SizedBox(height: Tokens.space[3]),
            Text(l.cxMotionTitle, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            SizedBox(height: Tokens.space[1]),
            Wrap(
              spacing: Tokens.space[1],
              runSpacing: Tokens.space[1],
              children: [
                for (final m in CxMotion.values) chip(p, cxMotionName(l, m), motion == m, () => setState(() => motion = m), key: Key('cx-m-${m.name}')),
              ],
            ),
            SizedBox(height: Tokens.space[3]),
            Text(l.cxBaseTitle, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            SizedBox(height: Tokens.space[1]),
            Wrap(
              spacing: Tokens.space[0],
              children: [
                for (final b in bases)
                  GestureDetector(
                    key: Key('cx-base-$b'),
                    onTap: () => setState(() => base = b),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: base == b ? p.secondaryLabel.withValues(alpha: 0.18) : null, shape: BoxShape.circle),
                      child: Text(b, style: const TextStyle(fontSize: 26, height: 1, fontFamilyFallback: Tokens.emojiFallback)),
                    ),
                  ),
              ],
            ),
            SizedBox(height: Tokens.space[1]),
            Text(l.cxBaseInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- panel

/// Rows on top of the emoji panel: 내 이모지 (with the + tile) and the
/// group's emoji. [onEmoji] gets ":cx_…:".
List<Widget> cxPanelSlivers(
  BuildContext context, {
  required String roomId,
  required String roomName,
  bool group = false,
  required void Function(String code) onEmoji,
}) {
  final s = AppScope.of(context);
  CustomEmojis.load(s);
  final p = paletteOf(context);
  final l = L.of(context);
  final pack = group ? CustomEmojis.pack(s, roomId) : const <String>[];
  // Same look as the panel's own section titles (centred, caption grey).
  Widget head(String key, String title) => Padding(
    key: Key(key),
    padding: EdgeInsets.fromLTRB(0, Tokens.space[2], 0, Tokens.space[0]),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
    ),
  );
  Widget grid(List<Widget> cells) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
    sliver: SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8), delegate: SliverChildListDelegate(cells)),
  );
  Widget cell(String id) => GestureDetector(
    key: Key('cx-cell-$id'),
    onTap: () => onEmoji(':$id:'),
    onLongPress: () => showCxSave(context, id),
    child: Center(child: CxEmojiView(id, size: 34)),
  );
  return [
    if (pack.isNotEmpty) ...[
      SliverToBoxAdapter(
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => GroupEmojiPage(roomId: roomId, admin: false))),
          child: head('cx-group-head', l.cxGroupSection(roomName)),
        ),
      ),
      grid([for (final id in pack) cell(id)]),
    ],
    SliverToBoxAdapter(child: head('cx-mine-head', l.cxMineSection)),
    grid([
      GestureDetector(
        key: const Key('cx-make'),
        onTap: () async {
          final id = await openSheet<String>(context, (_) => const CxMakerPage());
          if (id != null) onEmoji(':$id:');
        },
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.16), shape: BoxShape.circle),
            child: Icon(CupertinoIcons.add, size: Tokens.listIconSmall, color: p.secondaryLabel, semanticLabel: l.cxMakeTitle),
          ),
        ),
      ),
      for (final id in CustomEmojis.mine) cell(id),
    ]),
  ];
}

/// Composer letter for a made emoji (one character, drawn as its picture).
String cxLetter(String id) => charEmojiLetter(id);

// ---------------------------------------------------------------- save

/// Tap on a made emoji: see it big; save it to 내 이모지 (or take it out).
Future<void> showCxSave(BuildContext context, String id) async {
  final s = AppScope.read(context);
  final l = L.of(context);
  final e = CustomEmojis.known[id];
  if (e == null) return;
  final mine = CustomEmojis.isMine(id);
  final go = await showCupertinoModalPopup<bool>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: CxEmojiView(id, size: Tokens.cxBig),
      message: Text(mine ? l.cxIsMine : l.cxSaveInfo),
      actions: [
        CupertinoActionSheetAction(
          key: const Key('cx-save'),
          isDefaultAction: !mine,
          isDestructiveAction: mine,
          onPressed: () => Navigator.pop(c, true),
          child: Text(mine ? l.cxRemove : l.cxSave),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (go != true) return;
  if (mine) {
    await CustomEmojis.removeMine(s, id);
  } else {
    await CustomEmojis.addMine(s, e);
  }
}

// ---------------------------------------------------------------- group

/// 그룹 이모지: admins pick up to 50 from 내 이모지 for everyone in the
/// group; members see them first in the emoji panel and can save them all.
class GroupEmojiPage extends StatefulWidget {
  const GroupEmojiPage({super.key, required this.roomId, required this.admin});
  final String roomId;
  final bool admin;

  @override
  State<GroupEmojiPage> createState() => _GroupEmojiPageState();
}

class _GroupEmojiPageState extends State<GroupEmojiPage> {
  late List<String> picked = CustomEmojis.pack(AppScope.read(context), widget.roomId);
  bool saving = false, dirty = false;
  StreamSubscription<void>? sub;

  @override
  void initState() {
    super.initState();
    sub = CustomEmojis.changed.stream.listen((_) {
      if (mounted && !dirty) setState(() => picked = CustomEmojis.pack(AppScope.read(context), widget.roomId));
    });
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    super.dispose();
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await CustomEmojis.savePack(AppScope.read(context), widget.roomId, picked);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveAll() async {
    final s = AppScope.read(context);
    for (final id in picked.reversed) {
      final e = CustomEmojis.known[id];
      if (e != null && !CustomEmojis.isMine(id)) await CustomEmojis.addMine(s, e);
    }
    if (mounted) setState(() {});
  }

  Widget tile(Palette p, String id, {bool on = false, VoidCallback? tap}) => GestureDetector(
    key: Key('gx-$id'),
    onTap: tap,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CxEmojiView(id, size: 44),
        if (widget.admin)
          Positioned(
            right: 2,
            bottom: 2,
            child: Icon(on ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, size: Tokens.listIconSmall, color: on ? p.accent : p.secondaryLabel),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final s = AppScope.of(context);
    CustomEmojis.load(s);
    final choices = widget.admin ? {...picked, ...CustomEmojis.mine}.toList() : picked;
    final allSaved = picked.every(CustomEmojis.isMine);
    return SettingsScaffold(
      title: l.cxGroupTitle,
      trailing: [if (widget.admin && dirty) GlassDone(key: const Key('gx-done'), onTap: saving ? null : save)],
      children: [
        HeaderCard(color: Palette.tileYellow, icon: CupertinoIcons.smiley_fill, title: l.cxGroupTitle, body: widget.admin ? l.cxGroupAdminInfo : l.cxGroupInfo),
        if (choices.isEmpty)
          Padding(
            padding: EdgeInsets.all(Tokens.space[4]),
            child: Text(
              widget.admin ? l.cxGroupEmptyAdmin : l.cxGroupEmpty,
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: Container(
              padding: EdgeInsets.all(Tokens.space[2]),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
              child: Wrap(
                spacing: Tokens.space[1],
                runSpacing: Tokens.space[1],
                children: [
                  for (final id in choices)
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: tile(
                        p,
                        id,
                        on: picked.contains(id),
                        tap: widget.admin
                            ? () => setState(() {
                                dirty = true;
                                if (picked.contains(id)) {
                                  picked = picked.where((x) => x != id).toList();
                                } else if (picked.length < CustomEmojis.packMax) {
                                  picked = [...picked, id];
                                }
                              })
                            : () => showCxSave(context, id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (widget.admin)
          group(context, footer: l.cxGroupCount(picked.length, CustomEmojis.packMax), [
            NavRow(
              key: const Key('gx-make'),
              color: Palette.tileOrange,
              icon: CupertinoIcons.add,
              title: l.cxMakeTitle,
              onTap: () async {
                final id = await openSheet<String>(context, (_) => const CxMakerPage());
                if (id != null && mounted) {
                  setState(() {
                    dirty = true;
                    if (!picked.contains(id) && picked.length < CustomEmojis.packMax) picked = [...picked, id];
                  });
                }
              },
            ),
          ])
        else if (picked.isNotEmpty)
          group(context, [
            NavRow(
              key: const Key('gx-save-all'),
              color: p.tileGreen,
              icon: allSaved ? CupertinoIcons.checkmark : CupertinoIcons.tray_arrow_down_fill,
              title: allSaved ? l.cxAllSaved : l.cxSaveAll,
              onTap: allSaved ? null : saveAll,
            ),
          ]),
      ],
    );
  }
}
