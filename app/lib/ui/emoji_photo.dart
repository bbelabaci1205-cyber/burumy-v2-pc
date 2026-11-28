// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이모지 사진 (Telegram tips 376 + 351): a profile photo made from an emoji
// or a Burumy character on an iPhone-colour ground with a soft top shine.
// Made on this phone as a 1024 px PNG; used for me, groups and channels and
// the 공개 사진.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import '../stickers/sticker_words.dart' show emojiGroups;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';

Future<Uint8List?> makeEmojiPhoto(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push<Uint8List>(IosPageRoute(fullscreenDialog: true, builder: (_) => const EmojiPhotoPage()));

/// Burumy tab: character emoji, then the still stickers.
final emojiPhotoCharacters = [
  for (final ids in charEmojiGroups.values) ...ids.map((i) => charEmojiAsset(i)!),
  for (final p in stickerPacks)
    for (final i in p.items)
      if (!StickerPack.moving(i)) p.asset(i),
];

/// Top of the ground: the colour a little lighter (iPhone shine).
List<Color> emojiPhotoGround(Color c) => [Color.lerp(c, const Color(0xFFFFFFFF), Tokens.emojiPhotoShine)!, c];

class EmojiPhotoPage extends StatefulWidget {
  const EmojiPhotoPage({super.key});
  @override
  State<EmojiPhotoPage> createState() => _EmojiPhotoPageState();
}

class _EmojiPhotoPageState extends State<EmojiPhotoPage> {
  final shot = GlobalKey();
  bool characters = false;

  /// An emoji (text) or a Burumy asset path.
  String item = '😊';
  Color ground = Tokens.emojiPhotoGrounds[6];

  /// Own colour (hue 0..360) when "직접 고르기" is on.
  double? hue;
  double scale = 0.62;
  bool saving = false;

  Color get colour => hue == null ? ground : HSVColor.fromAHSV(1, hue!, 0.72, 0.92).toColor();

  Future<void> done() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final box = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final im = await box.toImage(pixelRatio: Tokens.emojiPhotoOut / Tokens.emojiPhotoPreview);
      final data = await im.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted || data == null) return;
      Navigator.pop(context, data.buffer.asUint8List());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final size = Tokens.emojiPhotoPreview;
    Widget dot(Color c, {bool on = false, Gradient? g, required Key key, required VoidCallback onTap}) => GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: Tokens.emojiPhotoDot,
        height: Tokens.emojiPhotoDot,
        margin: EdgeInsets.symmetric(horizontal: Tokens.space[0]),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: on ? p.label : const Color(0x00000000), width: 2),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: g ?? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: emojiPhotoGround(c)),
          ),
        ),
      ),
    );
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.emojiPhotoTitle,
        tint: p.background,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('emoji-photo-done'), onTap: saving ? null : done)],
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[3]),
          RepaintBoundary(
            key: shot,
            child: ClipOval(
              child: Container(
                key: const Key('emoji-photo-preview'),
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: emojiPhotoGround(colour)),
                ),
                child: item.startsWith('assets/')
                    ? Image.asset(item, width: size * scale, height: size * scale, fit: BoxFit.contain)
                    : Text(
                        item,
                        style: TextStyle(fontSize: size * scale * 0.82, height: 1.15, fontFamilyFallback: Tokens.emojiFallback),
                      ),
              ),
            ),
          ),
          SizedBox(height: Tokens.space[3]),
          // Ground colours (iPhone system colours) + 직접 고르기.
          SizedBox(
            height: Tokens.emojiPhotoDot,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              children: [
                for (var i = 0; i < Tokens.emojiPhotoGrounds.length; i++)
                  dot(
                    Tokens.emojiPhotoGrounds[i],
                    key: Key('emoji-ground-$i'),
                    on: hue == null && ground == Tokens.emojiPhotoGrounds[i],
                    onTap: () => setState(() {
                      ground = Tokens.emojiPhotoGrounds[i];
                      hue = null;
                    }),
                  ),
                dot(
                  ground,
                  key: const Key('emoji-ground-custom'),
                  on: hue != null,
                  g: const SweepGradient(
                    colors: [
                      Color(0xFFFF383C),
                      Color(0xFFFFCC00),
                      Color(0xFF34C759),
                      Color(0xFF00C0E8),
                      Color(0xFF0088FF),
                      Color(0xFFCB30E0),
                      Color(0xFFFF383C),
                    ],
                  ),
                  onTap: () => setState(() => hue ??= HSVColor.fromColor(ground).hue),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
            child: Column(
              children: [
                if (hue != null)
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(l.emojiPhotoColor, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      ),
                      Expanded(
                        child: CupertinoSlider(
                          key: const Key('emoji-hue'),
                          value: hue!,
                          max: 360,
                          activeColor: colour,
                          onChanged: (v) => setState(() => hue = v),
                        ),
                      ),
                    ],
                  ),
                Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: Text(l.emojiPhotoSize, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ),
                    Expanded(
                      child: CupertinoSlider(key: const Key('emoji-size'), value: scale, min: 0.35, max: 0.85, onChanged: (v) => setState(() => scale = v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
            child: IosSegmented<bool>(
              key: const Key('emoji-photo-tabs'),
              groupValue: characters,
              children: {false: Text(l.emojiPhotoEmoji), true: Text(l.emojiPhotoSticker)},
              onValueChanged: (v) => setState(() => characters = v ?? characters),
            ),
          ),
          Expanded(
            child: characters
                ? GridView.count(
                    key: const Key('emoji-photo-characters'),
                    crossAxisCount: 5,
                    padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], MediaQuery.paddingOf(context).bottom + Tokens.space[2]),
                    children: [
                      for (final a in emojiPhotoCharacters)
                        GestureDetector(
                          onTap: () => setState(() => item = a),
                          child: Container(
                            margin: EdgeInsets.all(Tokens.space[0]),
                            decoration: a == item
                                ? BoxDecoration(color: p.accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Tokens.radius[1]))
                                : null,
                            padding: EdgeInsets.all(Tokens.space[0]),
                            child: Image.asset(a, fit: BoxFit.contain),
                          ),
                        ),
                    ],
                  )
                : CustomScrollView(
                    key: const Key('emoji-photo-emoji'),
                    slivers: [
                      for (final (_, _, all) in emojiGroups)
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                            delegate: SliverChildListDelegate([
                              for (final e in all.characters)
                                GestureDetector(
                                  onTap: () => setState(() => item = e),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: e == item
                                        ? BoxDecoration(color: p.accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(Tokens.radius[1]))
                                        : null,
                                    child: Text(e, style: const TextStyle(fontSize: 30, fontFamilyFallback: Tokens.emojiFallback)),
                                  ),
                                ),
                            ]),
                          ),
                        ),
                      SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + Tokens.space[2])),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
