// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 테마·배경·꾸미기 (Telegram tip batches #21 + #24, 2026-11-27).
//
// #21 테마·배경
// - AccentDots (229): the accent colour as a row of dots under the preview
//   in Settings > 모양; the whole app changes at once (cross-fade).
// - AllBackgroundsPage (305): every ready-made background in a 3-across
//   grid, 낮 / 밤 switch to see the night look.
// - WallpaperPage (181): 배경 고르기 — from my photos, one colour, mix my
//   own colours, or ours; 밤 밝기 slider. WallPreviewPage: swipe between
//   backgrounds, 흐림 / 움직임 / 무늬 + 강도, then 설정.
// - GradientMakerPage (281 + 284): four colours that turn a little each
//   time I send, with icons over them.
// - WallNoteCard (387 + 410): in a 1:1 chat, the card that says a new
//   background went to both phones (the other one can go back to theirs).
//
// #24 꾸미기 고급 (Plus 후보)
// - ThemeMakerPage + MyThemesRow (173 + 226): make a theme (name, accent,
//   background), keep it, share it as a link (the theme rides after '#',
//   inside the encrypted message), ThemeLinkCard / ThemeLinkPage open it.
// - PersonLookPage (402 + 409): name colour (one or two stripes), icons in
//   my reply quotes, profile cover colour + icons. CoverBackdrop draws it.
// - RoomLookPage (412 + 429): admins pick a group / channel cover, icons,
//   status emoji, background for all members and (channels) a name colour.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/automod.dart' show levelOf;
import '../core/looks.dart';
import '../core/room_theme.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'message_sheets.dart' show AccentButton;
import 'name_colors.dart';
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;
import 'wallpaper.dart';
import 'wide.dart' show openSheet;

// ------------------------------------------------------------- dots

/// A colour dot: one colour or two stripes, a ring when picked.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.colors, required this.picked, required this.onTap, this.size = Tokens.lookDot, this.child});
  final List<Color> colors;
  final bool picked;
  final VoidCallback onTap;
  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final ring = colors.isEmpty ? p.accent : colors.first;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        padding: EdgeInsets.all(picked ? Tokens.lookDotRing + Tokens.lookDotGap : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: picked ? ring : const Color(0x00000000), width: Tokens.lookDotRing),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.isEmpty ? p.searchFill : null,
            gradient: colors.length > 1
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors[0], colors[0], colors[1], colors[1]],
                    stops: const [0, .5, .5, 1],
                  )
                : null,
            border: colors.isNotEmpty && colors.first.computeLuminance() > 0.85 ? Border.all(color: p.separator) : null,
          ),
          child: colors.length == 1 ? ColoredBox(color: colors.first, child: child) : child,
        ),
      ),
    );
  }
}

/// 강조색 (tip 229): our green first, then iOS colours, then the made theme.
class AccentDots extends StatelessWidget {
  const AccentDots({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final made = s.family == BrandFamily.custom;
    return SizedBox(
      height: Tokens.lookDot + Tokens.space[3],
      child: ListView(
        key: const Key('accent-dots'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
        children: [
          for (final f in Brand.picks)
            Padding(
              padding: EdgeInsets.only(right: Tokens.space[2]),
              child: ColorDot(key: Key('accent-${f.name}'), colors: [Brand.accent(f, p.brightness)], picked: s.family == f, onTap: () => s.setFamily(f)),
            ),
          if (made)
            ColorDot(
              key: const Key('accent-custom'),
              colors: [Brand.custom],
              picked: true,
              onTap: () {},
              child: const Icon(CupertinoIcons.paintbrush_fill, size: 14, color: Color(0xFFFFFFFF)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- previews

/// A small chat: two bubbles on [spec] (any background text).
class MiniChat extends StatelessWidget {
  const MiniChat({super.key, required this.spec, this.accent, this.dark, this.big = false});
  final String spec;
  final Color? accent;
  final bool? dark;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final base = paletteOf(context);
    final p = dark == null ? base : Palette.of(base.family, dark! ? Brightness.dark : Brightness.light);
    final a = accent ?? p.accent;
    final pad = big ? Tokens.space[3] : 7.0;
    final h = big ? 30.0 : 12.0;
    Widget bar(bool mine, String text) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: big
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] - 1),
              decoration: BoxDecoration(color: mine ? a : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
              child: Text(text, style: Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label)),
            )
          : FractionallySizedBox(
              widthFactor: 0.7,
              child: Container(
                height: h,
                decoration: BoxDecoration(color: mine ? a : p.incoming, borderRadius: BorderRadius.circular(h / 2)),
              ),
            ),
    );
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(brightness: p.brightness),
      child: ChatWallpaper(
        theme: spec,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisAlignment: big ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!big) SizedBox(height: pad),
              bar(false, l.bubbleSample),
              SizedBox(height: big ? Tokens.space[1] : 6),
              bar(true, l.textSizePreviewReply),
            ],
          ),
        ),
      ),
    );
  }
}

/// A background tile in a grid (9:16, corner 12), ringed when picked.
class WallTile extends StatelessWidget {
  const WallTile({super.key, required this.spec, required this.picked, required this.onTap, this.label, this.dark, this.child});
  final String spec;
  final bool picked;
  final VoidCallback onTap;
  final String? label;
  final bool? dark;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: Tokens.wallTileAspect,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(Tokens.wallTileCorner + 3),
                  side: BorderSide(color: picked ? p.accent : const Color(0x00000000), width: Tokens.lookDotRing),
                ),
              ),
              child: ClipRSuperellipse(
                borderRadius: BorderRadius.circular(Tokens.wallTileCorner),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: ShapeDecoration(
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(Tokens.wallTileCorner),
                      side: BorderSide(color: p.separator, width: 0.5),
                    ),
                  ),
                  child: child ?? MiniChat(spec: spec, dark: dark),
                ),
              ),
            ),
          ),
          if (label != null) ...[
            SizedBox(height: Tokens.space[0]),
            Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.caption.style.copyWith(color: picked ? p.accent : p.secondaryLabel),
            ),
          ],
        ],
      ),
    );
  }
}

/// Every ready-made background: ours, then the swirling colour sets.
List<(String, String)> readyWalls(L l) => [
  for (final t in ChatTheme.all) (t.id, t.label(l)),
  for (final g in Wall.gradients) (Wall.gradSpec(g.$1), gradName(l, g.$1)),
];

String gradName(L l, String id) => switch (id) {
  'sky' => l.gradSky,
  'peach' => l.gradPeach,
  'mint' => l.gradMint,
  'lilac' => l.gradLilac,
  'sunset' => l.gradSunset,
  _ => l.gradNight,
};

/// Short name of a background text for rows ("내 사진", "단색", …).
String wallName(L l, String spec) {
  final w = Wall.parse(spec);
  return switch (w.kind) {
    'photo' => l.themePhoto,
    'color' => l.wallSolid,
    'grad' =>
      Wall.gradients
              .where((g) => Wall.gradSpec(g.$1) == Wall(kind: 'grad', colors: w.colors, strength: 0.35).encode())
              .map((g) => gradName(l, g.$1))
              .firstOrNull ??
          l.wallMixed,
    _ => ChatTheme.of(w.id).label(l),
  };
}

// ------------------------------------------------- 305 all backgrounds

/// 배경 모두 보기 (tip 305): 3 across, 낮 / 밤 to see both looks.
class AllBackgroundsPage extends StatefulWidget {
  const AllBackgroundsPage({super.key});
  @override
  State<AllBackgroundsPage> createState() => _AllBackgroundsPageState();
}

class _AllBackgroundsPageState extends State<AllBackgroundsPage> {
  bool? night;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final dark = night ?? p.dark;
    final now = s.pref('chat_theme', 'plain');
    final walls = readyWalls(l);
    return SettingsScaffold(
      title: l.allBackgrounds,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2]),
          child: IosSegmented<bool>(
            key: const Key('all-bg-night'),
            groupValue: dark,
            children: {false: Text(l.dayLook), true: Text(l.nightLook)},
            onValueChanged: (v) => setState(() => night = v),
          ),
        ),
        GridView.count(
          key: const Key('all-bg-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          mainAxisSpacing: Tokens.space[2],
          crossAxisSpacing: Tokens.space[2],
          childAspectRatio: 0.48,
          children: [
            for (final (spec, label) in walls)
              WallTile(key: Key('all-bg-$label'), spec: spec, dark: dark, label: label, picked: now == spec, onTap: () => s.setPref('chat_theme', spec)),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
          child: Text(l.allBackgroundsInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

// ------------------------------------------------ 181 pick a background

/// Where a picked background goes: my default, or one chat (1:1: maybe
/// both phones).
class WallTarget {
  const WallTarget({this.roomId, this.direct = false});
  final String? roomId;
  final bool direct;

  String current(AppState s) => roomId == null ? s.pref('chat_theme', 'plain') : s.pref(RoomTheme.pref(roomId!), '');

  Future<void> apply(BuildContext context, String spec, {bool both = false}) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    if (roomId == null) {
      await s.setPref('chat_theme', spec);
      return;
    }
    await RoomTheme.set(s, roomId!, spec, both: both && direct && Wall.sendable(spec));
    if (both && direct && context.mounted) showStoryToast(context, Wall.sendable(spec) ? l.roomThemeSent : l.wallPhotoMineOnly);
  }
}

/// 배경 고르기 (tip 181).
class WallpaperPage extends StatelessWidget {
  const WallpaperPage({super.key, this.target = const WallTarget()});
  final WallTarget target;

  static Future<void> pickPhoto(BuildContext context, WallTarget target) async {
    final s = AppScope.read(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1170, imageQuality: 78);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await s.setPref('chat_photo', base64Encode(bytes));
    if (!context.mounted) return;
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => WallPreviewPage(specs: const ['photo'], target: target),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final now = target.current(s);
    final walls = readyWalls(l);
    final made = [for (final t in myThemes(s)) t.wall, ...s.pref('made_walls', '').split('\n').where((x) => x.isNotEmpty && Wall.sendable(x))].toSet().toList();
    final dim = nightDim(s);
    return SettingsScaffold(
      title: target.roomId == null ? l.pickBackground : l.chatThemeHere,
      children: [
        group(context, [
          NavRow(
            key: const Key('wall-from-photos'),
            color: Palette.tileTeal,
            icon: CupertinoIcons.photo_fill,
            title: l.wallFromPhotos,
            onTap: () => pickPhoto(context, target),
          ),
          NavRow(
            key: const Key('wall-solid'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.circle_fill,
            title: l.wallSolidColor,
            page: (_) => SolidColorsPage(target: target),
          ),
          NavRow(
            key: const Key('wall-mix'),
            color: Palette.tilePink,
            icon: CupertinoIcons.drop_fill,
            title: l.wallMakeColors,
            page: (_) => GradientMakerPage(target: target),
          ),
        ]),
        if (target.roomId != null)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
            child: CupertinoButton(
              key: const Key('wall-reset-room'),
              padding: EdgeInsets.zero,
              onPressed: now.isEmpty ? null : () => target.apply(context, ''),
              child: Text(l.roomThemeMine),
            ),
          ),
        if (made.isNotEmpty) ...[
          _head(context, l.wallMine),
          _grid(context, [for (final w in made) (w, '')], now, target),
        ],
        _head(context, l.wallReady),
        _grid(context, walls, now, target),
        group(context, header: l.nightBrightness, footer: l.nightBrightnessInfo, [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
            child: Row(
              children: [
                Icon(CupertinoIcons.moon_fill, size: Tokens.listIconSmall, color: p.secondaryLabel),
                Expanded(
                  child: CupertinoSlider(
                    key: const Key('night-dim'),
                    value: dim,
                    max: 0.8,
                    divisions: 8,
                    activeColor: p.accent,
                    onChanged: (v) => s.setPref('wall_dim', v.toStringAsFixed(2)),
                  ),
                ),
                Text('${(dim * 100).round()}%', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ],
            ),
          ),
        ]),
      ],
    );
  }

  // Section words over a grid (iOS grouped header, 16 + 16 in).
  Widget _head(BuildContext context, String text) => Padding(
    padding: EdgeInsets.fromLTRB(Tokens.space[3] * 2, Tokens.space[2], Tokens.space[3], Tokens.space[1]),
    child: Text(text, style: Tokens.caption.style.copyWith(color: paletteOf(context).secondaryLabel)),
  );

  Widget _grid(BuildContext context, List<(String, String)> walls, String now, WallTarget target) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 3,
    padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[4]),
    mainAxisSpacing: Tokens.space[2],
    crossAxisSpacing: Tokens.space[2],
    childAspectRatio: walls.any((w) => w.$2.isNotEmpty) ? 0.48 : Tokens.wallTileAspect,
    children: [
      for (final (i, (spec, label)) in walls.indexed)
        WallTile(
          key: Key('wall-tile-$spec'),
          spec: spec,
          label: label.isEmpty ? null : label,
          picked: now == spec,
          onTap: () => Navigator.of(context).push(
            IosPageRoute(
              builder: (_) => WallPreviewPage(specs: [for (final w in walls) w.$1], start: i, target: target),
            ),
          ),
        ),
    ],
  );
}

/// 단색 (tip 181): soft colours in a grid.
class SolidColorsPage extends StatelessWidget {
  const SolidColorsPage({super.key, required this.target});
  final WallTarget target;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final specs = [
      for (final c in Wall.solids) Wall(kind: 'color', colors: [c]).encode(),
    ];
    final now = target.current(AppScope.of(context));
    return SettingsScaffold(
      title: l.wallSolidColor,
      children: [
        GridView.count(
          key: const Key('solid-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          padding: EdgeInsets.all(Tokens.space[3]),
          mainAxisSpacing: Tokens.space[2],
          crossAxisSpacing: Tokens.space[2],
          childAspectRatio: Tokens.wallTileAspect,
          children: [
            for (final (i, spec) in specs.indexed)
              WallTile(
                key: Key('solid-$i'),
                spec: spec,
                picked: Wall.parse(now).kind == 'color' && Wall.parse(now).colors.first == Wall.solids[i],
                onTap: () async {
                  final set = await Navigator.of(context).push<bool>(
                    IosPageRoute(
                      builder: (_) => WallPreviewPage(specs: specs, start: i, target: target),
                    ),
                  );
                  if (set == true && context.mounted) Navigator.of(context).pop(true);
                },
              ),
          ],
        ),
      ],
    );
  }
}

/// The background big, swipe to the next one; 흐림 / 움직임 / 무늬 + 강도,
/// then 설정 (1:1: 이 대화에만 / 나와 상대 모두).
class WallPreviewPage extends StatefulWidget {
  const WallPreviewPage({super.key, required this.specs, this.start = 0, this.target = const WallTarget()});
  final List<String> specs;
  final int start;
  final WallTarget target;
  @override
  State<WallPreviewPage> createState() => _WallPreviewPageState();
}

class _WallPreviewPageState extends State<WallPreviewPage> {
  late final PageController pages = PageController(initialPage: widget.start);
  late final List<Wall> walls = [for (final x in widget.specs) Wall.parse(x)];
  late int at = widget.start;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Wall get w => walls[at];
  set w(Wall v) => setState(() => walls[at] = v);

  Future<void> done({bool both = false}) async {
    final spec = w.encode();
    final s = AppScope.read(context);
    // A colour mix I changed is kept under 내 배경 for next time.
    if (w.kind == 'grad' || w.kind == 'color') {
      final made = s.pref('made_walls', '').split('\n').where((x) => x.isNotEmpty).toList();
      if (!made.contains(spec) && !readyWalls(L.of(context)).any((r) => r.$1 == spec)) {
        await s.setPref('made_walls', [spec, ...made].take(12).join('\n'));
      }
    }
    if (!mounted) return;
    await widget.target.apply(context, spec, both: both);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final direct = widget.target.direct;
    Widget chip(Key key, String label, bool on, VoidCallback tap) => GestureDetector(
      key: key,
      onTap: tap,
      child: GlassChip(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, size: Tokens.listIconSmall, color: on ? p.accent : p.secondaryLabel),
            SizedBox(width: Tokens.space[0]),
            Text(label, style: Tokens.preview.style.copyWith(color: p.label)),
          ],
        ),
      ),
    );
    final canPattern = w.kind != 'photo';
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar(title: l.wallPreview, back: true, tint: p.chatBackground),
      child: Stack(
        children: [
          PageView.builder(
            key: const Key('wall-pages'),
            controller: pages,
            itemCount: walls.length,
            onPageChanged: (i) => setState(() => at = i),
            itemBuilder: (_, i) => ChatWallpaper(
              theme: walls[i].encode(),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], 236),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _bubble(context, l.bubbleSample, false),
                      SizedBox(height: Tokens.space[1]),
                      _bubble(context, l.wallPreviewReply, true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: Tokens.space[1],
                      alignment: WrapAlignment.center,
                      children: [
                        if (w.kind == 'photo') chip(const Key('wall-blur'), l.wallBlur, w.blur, () => w = w.copyWith(blur: !w.blur)),
                        chip(const Key('wall-motion'), l.wallMotion, w.motion, () => w = w.copyWith(motion: !w.motion)),
                      ],
                    ),
                    if (canPattern) ...[
                      SizedBox(height: Tokens.space[2]),
                      PatternPicker(
                        key: const Key('wall-pattern'),
                        picked: w.pattern,
                        onPick: (id) => w = w.copyWith(pattern: id),
                      ),
                      if (w.pattern.isNotEmpty || (w.kind == 'theme' && ChatTheme.of(w.id).icons.isNotEmpty))
                        GlassChip(
                          child: Row(
                            children: [
                              Text(l.patternStrength, style: Tokens.caption.style.copyWith(color: p.label)),
                              Expanded(
                                child: CupertinoSlider(
                                  key: const Key('wall-strength'),
                                  value: w.strength < 0 ? 0.5 : w.strength,
                                  activeColor: p.accent,
                                  onChanged: (v) => w = w.copyWith(strength: v),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    SizedBox(height: Tokens.space[2]),
                    if (direct) ...[
                      AccentButton(key: const Key('wall-set-both'), text: l.wallApplyBoth, onTap: () => done(both: true)),
                      SizedBox(height: Tokens.space[1]),
                      CupertinoButton(
                        key: const Key('wall-set-here'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, Tokens.settingsRow - 8),
                        onPressed: done,
                        child: Text(l.wallApplyHere),
                      ),
                    ] else
                      AccentButton(key: const Key('wall-set'), text: l.wallSet, onTap: done),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, String text, bool mine) {
    final p = paletteOf(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] - 1),
        decoration: BoxDecoration(color: mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
        child: Text(text, style: Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label)),
      ),
    );
  }
}

/// Icons to put over a background, a cover or reply quotes ('' = none).
class PatternPicker extends StatelessWidget {
  const PatternPicker({super.key, required this.picked, required this.onPick, this.onCard = false});
  final String picked;
  final ValueChanged<String> onPick;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    Widget cell(String id) {
      final on = picked == id;
      final icons = patternIcons(id);
      return GestureDetector(
        key: Key('pattern-$id'),
        onTap: () => onPick(id),
        child: Container(
          width: Tokens.lookDot + Tokens.space[1],
          height: Tokens.lookDot + Tokens.space[1],
          margin: EdgeInsets.only(right: Tokens.space[1]),
          decoration: BoxDecoration(
            color: onCard ? p.searchFill : p.card.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(color: on ? p.accent : const Color(0x00000000), width: Tokens.lookDotRing),
          ),
          child: icons.isEmpty
              ? Center(
                  child: Text(l.none, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                )
              : Icon(icons.first, size: Tokens.listIcon, color: on ? p.accent : p.label),
        ),
      );
    }

    return SizedBox(
      height: Tokens.lookDot + Tokens.space[2],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: onCard ? Tokens.space[3] : 0),
        children: [cell(''), for (final id in Patterns.ids) cell(id)],
      ),
    );
  }
}

// ------------------------------------------------- 281 + 284 colour mix

/// The colours offered when making a background or a theme: iOS hues in
/// three light steps (soft, middle, bright). No dark greens.
const pickHues = [0.0, 25.0, 45.0, 140.0, 175.0, 200.0, 215.0, 245.0, 275.0, 320.0];

List<Color> pickColors(double light) => [for (final h in pickHues) HSLColor.fromAHSL(1, h, h == 45 ? 0.95 : 0.85, light).toColor()];

/// A grid of colours to pick from (rows: soft, middle, bright).
class ColorGrid extends StatelessWidget {
  const ColorGrid({super.key, required this.picked, required this.onPick, this.rows = const [0.88, 0.76, 0.6]});
  final Color? picked;
  final ValueChanged<Color> onPick;
  final List<double> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
      child: Column(
        children: [
          for (final (r, light) in rows.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: Tokens.space[1]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final (i, c) in pickColors(light).indexed)
                    ColorDot(key: Key('grid-$r-$i'), size: 30, colors: [c], picked: picked?.toARGB32() == c.toARGB32(), onTap: () => onPick(c)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 내 색으로 움직이는 배경 만들기 (tips 281 + 284): four dots (tap one,
/// then a colour), icons + strength, preview that turns when tapped.
class GradientMakerPage extends StatefulWidget {
  const GradientMakerPage({super.key, this.target = const WallTarget(), this.start});
  final WallTarget target;
  final Wall? start;
  @override
  State<GradientMakerPage> createState() => _GradientMakerPageState();
}

class _GradientMakerPageState extends State<GradientMakerPage> {
  late Wall w = widget.start ?? Wall(kind: 'grad', colors: Wall.gradients.first.$2, strength: 0.35);
  int slot = 0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.wallMakeColors,
      children: [
        GestureDetector(
          key: const Key('grad-preview'),
          onTap: () => wallSpin.value++,
          child: Container(
            height: Tokens.lookPreview + 60,
            margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3]))),
            child: Stack(
              fit: StackFit.expand,
              children: [
                WallArt(wall: w, dark: p.dark, base: p.chatBackground),
                Padding(
                  padding: EdgeInsets.all(Tokens.space[3]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: _b(context, l.bubbleSample, false)),
                      SizedBox(height: Tokens.space[1]),
                      Align(alignment: Alignment.centerRight, child: _b(context, l.gradTapToTurn, true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: Tokens.space[3]),
        // The four colours; the ringed one changes.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, c) in w.colors.indexed)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                child: ColorDot(key: Key('grad-slot-$i'), size: 44, colors: [c], picked: slot == i, onTap: () => setState(() => slot = i)),
              ),
          ],
        ),
        group(context, header: l.gradPickColor, [
          ColorGrid(
            picked: w.colors[slot],
            onPick: (c) => setState(() {
              final cs = [...w.colors];
              cs[slot] = c;
              w = w.copyWith(colors: cs);
              slot = (slot + 1) % cs.length;
            }),
          ),
        ]),
        group(context, header: l.patternTitle, [
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
            child: PatternPicker(
              onCard: true,
              picked: w.pattern,
              onPick: (id) => setState(() => w = w.copyWith(pattern: id)),
            ),
          ),
          if (w.pattern.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                children: [
                  Text(l.patternStrength, style: Tokens.body.style.copyWith(color: p.label)),
                  Expanded(
                    child: CupertinoSlider(
                      key: const Key('grad-strength'),
                      value: w.strength,
                      activeColor: p.accent,
                      onChanged: (v) => setState(() => w = w.copyWith(strength: v)),
                    ),
                  ),
                ],
              ),
            ),
        ]),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: AccentButton(
            key: const Key('grad-next'),
            text: l.next,
            onTap: () async {
              final set = await Navigator.of(context).push<bool>(
                IosPageRoute(
                  builder: (_) => WallPreviewPage(specs: [w.encode()], target: widget.target),
                ),
              );
              if (set == true && context.mounted) Navigator.of(context).pop(true);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
          child: Text(l.gradInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }

  Widget _b(BuildContext context, String text, bool mine) {
    final p = paletteOf(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] - 1),
      decoration: BoxDecoration(color: mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Text(text, style: Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label)),
    );
  }
}

// --------------------------------------------- 387 + 410 both phones card

/// What the last both-phones background change was, for the card in the
/// chat: {by: '' (me) | user id, t: spec, prev: my old pick, at}.
String wallNotePref(String roomId) => 'chat_theme_note:$roomId';

Map<String, dynamic>? wallNote(AppState s, String roomId) {
  try {
    final j = jsonDecode(s.pref(wallNotePref(roomId), ''));
    return j is Map<String, dynamic> ? j : null;
  } catch (_) {
    return null;
  }
}

/// The card at the top of a 1:1 chat after a background went to both
/// phones: round thumbnail, who set it, and for the other person
/// "내 배경으로 되돌리기" (Telegram: 배경 보기 / 적용).
class WallNoteCard extends StatelessWidget {
  const WallNoteCard({super.key, required this.roomId, required this.peerName});
  final String roomId;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final n = wallNote(s, roomId);
    if (n == null) return const SizedBox.shrink();
    final mine = '${n['by'] ?? ''}'.isEmpty;
    final spec = '${n['t'] ?? ''}';
    Future<void> close() => s.setPref(wallNotePref(roomId), '');
    return Padding(
      key: const Key('wall-note'),
      padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
      child: GlassPanel(
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[2]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: WallArt(wall: Wall.parse(spec), dark: p.dark, base: p.chatBackground, still: true),
                    ),
                  ),
                  SizedBox(width: Tokens.space[2]),
                  Expanded(
                    child: Text(mine ? l.wallNoteMine(peerName) : l.wallNoteTheirs(peerName), style: Tokens.preview.style.copyWith(color: p.label)),
                  ),
                  GestureDetector(
                    key: const Key('wall-note-close'),
                    onTap: close,
                    child: Padding(
                      padding: EdgeInsets.all(Tokens.space[0]),
                      child: Icon(CupertinoIcons.xmark, size: Tokens.listIconSmall, color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
              if (!mine) ...[
                SizedBox(height: Tokens.space[1]),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        key: const Key('wall-note-keep'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        onPressed: close,
                        child: Text(l.wallNoteKeep, style: Tokens.preview.style.copyWith(color: p.accent)),
                      ),
                    ),
                    Expanded(
                      child: CupertinoButton(
                        key: const Key('wall-note-undo'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                        onPressed: () async {
                          await RoomTheme.set(s, roomId, '${n['prev'] ?? ''}', both: false);
                          await close();
                        },
                        child: Text(l.wallNoteUndo, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A glass capsule holding any row (chips and sliders over a background).
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LiquidGlass(
    radius: 20,
    child: Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + 2),
      alignment: Alignment.center,
      child: child,
    ),
  );
}

/// A frosted card (the chat's glass) for notes over the background.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      decoration: ShapeDecoration(
        color: p.card.withValues(alpha: 0.92),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[2])),
        shadows: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------- 173 + 226 themes

List<MyTheme> myThemes(AppState s) => MyTheme.listFrom(s.pref(MyTheme.pref, '[]'));

Future<void> saveMyThemes(AppState s, List<MyTheme> all) => s.setPref(MyTheme.pref, MyTheme.listTo(all));

/// Puts a theme on: its accent for the whole app, its background as my default.
Future<void> wearTheme(AppState s, MyTheme t) async {
  await s.setPref('accent_custom', hexOf(t.accent));
  await s.setPref('chat_theme', t.wall);
  await s.setPref('theme_on', t.id);
  Brand.custom = t.accent;
  s.setFamily(BrandFamily.custom);
}

/// 내 테마 (Settings > 모양): my made themes; tap to wear, hold for 편집 /
/// 보내기 / 링크 복사 / 삭제; the last card makes a new one.
class MyThemesRow extends StatelessWidget {
  const MyThemesRow({super.key});

  Future<void> menu(BuildContext context, MyTheme t) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final what = await showCupertinoModalPopup<String>(
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: Text(t.name),
        actions: [
          CupertinoActionSheetAction(key: const Key('theme-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.themeEdit)),
          CupertinoActionSheetAction(key: const Key('theme-copy-link'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.themeCopyLink)),
          CupertinoActionSheetAction(
            key: const Key('theme-delete'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(l.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!context.mounted) return;
    switch (what) {
      case 'edit':
        await Navigator.of(context).push(IosPageRoute(builder: (_) => ThemeMakerPage(edit: t)));
      case 'copy':
        await Clipboard.setData(ClipboardData(text: t.link()));
        if (context.mounted) showStoryToast(context, l.themeLinkCopied);
      case 'delete':
        final before = myThemes(s);
        await saveMyThemes(s, before.where((x) => x.id != t.id).toList());
        if (!context.mounted) return;
        showUndoCountdown(context, (n) => l.themeDeletedIn(n), () async {}, onUndo: () => saveMyThemes(s, before));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final list = myThemes(s);
    final on = s.family == BrandFamily.custom ? s.pref('theme_on', '') : '';
    Widget card(MyTheme t) => GestureDetector(
      key: Key('my-theme-${t.id}'),
      onTap: () => wearTheme(s, t),
      onLongPress: () => menu(context, t),
      child: Padding(
        padding: EdgeInsets.only(right: Tokens.space[2]),
        child: SizedBox(
          width: 64,
          child: WallTile(
            spec: t.wall,
            picked: on == t.id,
            label: t.name,
            onTap: () => wearTheme(s, t),
            child: MiniChat(spec: t.wall, accent: t.accent),
          ),
        ),
      ),
    );
    return SizedBox(
      height: 166,
      child: ListView(
        key: const Key('my-themes'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
        children: [
          for (final t in list) card(t),
          GestureDetector(
            key: const Key('theme-new'),
            onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const ThemeMakerPage())),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: Tokens.wallTileAspect,
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: ShapeDecoration(
                        color: p.searchFill,
                        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.wallTileCorner)),
                      ),
                      child: Icon(CupertinoIcons.add, color: p.accent, size: Tokens.listIcon),
                    ),
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(l.themeNew, style: Tokens.caption.style.copyWith(color: p.accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 테마 만들기 (tip 173): name, accent, background; the preview follows.
class ThemeMakerPage extends StatefulWidget {
  const ThemeMakerPage({super.key, this.edit, this.from});
  final MyTheme? edit;

  /// A theme from a link, to keep as mine.
  final MyTheme? from;
  @override
  State<ThemeMakerPage> createState() => _ThemeMakerPageState();
}

class _ThemeMakerPageState extends State<ThemeMakerPage> {
  late final TextEditingController name = TextEditingController(text: (widget.edit ?? widget.from)?.name ?? '');
  late Color accent = (widget.edit ?? widget.from)?.accent ?? Brand.accent(BrandFamily.purple, Brightness.light);
  late String wall = (widget.edit ?? widget.from)?.wall ?? Wall.gradSpec('lilac');
  String part = 'accent';

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final n = name.text.trim().isEmpty ? l.themeDefaultName : name.text.trim();
    final t = MyTheme(
      id: widget.edit?.id ?? 't${DateTime.now().microsecondsSinceEpoch}',
      name: n.length > 40 ? n.substring(0, 40) : n,
      accent: brightEnough(accent),
      wall: wall,
    );
    final all = myThemes(s).where((x) => x.id != t.id).toList();
    await saveMyThemes(s, [t, ...all]);
    await wearTheme(s, t);
    if (mounted) {
      showStoryToast(context, l.themeSaved);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final walls = readyWalls(l);
    return SettingsScaffold(
      title: widget.edit == null ? l.themeMake : l.themeEdit,
      trailing: [
        CupertinoButton(
          key: const Key('theme-save'),
          padding: EdgeInsets.zero,
          onPressed: save,
          child: Text(
            l.save,
            style: Tokens.body.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
        ),
      ],
      children: [
        Container(
          key: const Key('theme-preview'),
          height: Tokens.lookPreview,
          margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2]),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3]))),
          child: MiniChat(spec: wall, accent: brightEnough(accent), big: true),
        ),
        group(context, [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: CupertinoTextField(
              key: const Key('theme-name'),
              controller: name,
              placeholder: l.themeNameHint,
              maxLength: 40,
              decoration: null,
              padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
              style: Tokens.body.style.copyWith(color: p.label),
            ),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
          child: IosSegmented<String>(
            key: const Key('theme-part'),
            groupValue: part,
            children: {'accent': Text(l.themePartAccent), 'wall': Text(l.themePartWall)},
            onValueChanged: (v) => setState(() => part = v ?? 'accent'),
          ),
        ),
        if (part == 'accent')
          group(context, footer: l.themeAccentInfo, [
            ColorGrid(rows: const [0.7, 0.6, 0.5], picked: accent, onPick: (c) => setState(() => accent = c)),
          ])
        else ...[
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            mainAxisSpacing: Tokens.space[1],
            crossAxisSpacing: Tokens.space[1],
            childAspectRatio: 0.5,
            children: [
              for (final (spec, label) in walls)
                WallTile(
                  key: Key('theme-wall-$label'),
                  spec: spec,
                  label: label,
                  picked: wall == spec,
                  onTap: () => setState(() => wall = spec),
                  child: MiniChat(spec: spec, accent: brightEnough(accent)),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: CupertinoButton(
              key: const Key('theme-wall-mix'),
              padding: EdgeInsets.zero,
              onPressed: () async {
                final got = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const _MixForTheme()));
                if (got != null && mounted) setState(() => wall = got);
              },
              child: Text(l.wallMakeColors),
            ),
          ),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
          child: Text(l.themeMakeInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

/// The colour mixer, returning the made background to the theme maker.
class _MixForTheme extends StatefulWidget {
  const _MixForTheme();
  @override
  State<_MixForTheme> createState() => _MixForThemeState();
}

class _MixForThemeState extends State<_MixForTheme> {
  Wall w = Wall(kind: 'grad', colors: Wall.gradients[3].$2, strength: 0.35);
  int slot = 0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.wallMakeColors,
      trailing: [
        CupertinoButton(
          key: const Key('mix-done'),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(w.encode()),
          child: Text(
            l.done,
            style: Tokens.body.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
        ),
      ],
      children: [
        Container(
          height: Tokens.lookPreview,
          margin: EdgeInsets.all(Tokens.space[3]),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3]))),
          child: WallArt(wall: w, dark: p.dark, base: p.chatBackground),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, c) in w.colors.indexed)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                child: ColorDot(size: 44, colors: [c], picked: slot == i, onTap: () => setState(() => slot = i)),
              ),
          ],
        ),
        group(context, [
          ColorGrid(
            picked: w.colors[slot],
            onPick: (c) => setState(() {
              final cs = [...w.colors];
              cs[slot] = c;
              w = w.copyWith(colors: cs);
              slot = (slot + 1) % cs.length;
            }),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
            child: PatternPicker(
              onCard: true,
              picked: w.pattern,
              onPick: (id) => setState(() => w = w.copyWith(pattern: id)),
            ),
          ),
        ]),
      ],
    );
  }
}

/// The card under a message that carries a theme link (tip 226).
class ThemeLinkCard extends StatelessWidget {
  const ThemeLinkCard({super.key, required this.theme, required this.mine});
  final MyTheme theme;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final fg = mine ? p.onAccent : p.label;
    final bar = mine ? p.onAccent : p.accent;
    return GestureDetector(
      key: const Key('theme-card'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openSheet<void>(context, (_) => ThemeLinkPage(theme: theme)),
      child: Container(
        margin: EdgeInsets.only(top: Tokens.space[1]),
        width: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: bar.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[1])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 110,
              child: MiniChat(spec: theme.wall, accent: theme.accent),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], 2),
              child: Text(
                theme.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
              child: Text(
                l.themeCardOpen,
                style: Tokens.caption.style.copyWith(color: bar, fontWeight: Tokens.semi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A theme from a link: big preview, 적용하기 (and keep it in 내 테마).
class ThemeLinkPage extends StatelessWidget {
  const ThemeLinkPage({super.key, required this.theme});
  final MyTheme theme;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: theme.name, back: true, tint: p.background),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[3]),
          child: Column(
            children: [
              SizedBox(height: Tokens.space[5]),
              Expanded(
                child: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(Tokens.radius[3]),
                  child: MiniChat(key: const Key('theme-link-preview'), spec: theme.wall, accent: theme.accent, big: true),
                ),
              ),
              SizedBox(height: Tokens.space[3]),
              Text(
                l.themeLinkInfo,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
              SizedBox(height: Tokens.space[3]),
              AccentButton(
                key: const Key('theme-link-apply'),
                text: l.themeApply,
                onTap: () async {
                  final keep = MyTheme(id: theme.id, name: theme.name, accent: theme.accent, wall: theme.wall);
                  await saveMyThemes(s, [keep, ...myThemes(s).where((x) => x.id != keep.id)]);
                  await wearTheme(s, keep);
                  if (context.mounted) {
                    showStoryToast(context, l.themeApplied);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a theme link from anywhere (tapping it in text, a QR, …).
Future<void> openThemeLink(BuildContext context, MyTheme t) => openSheet<void>(context, (_) => ThemeLinkPage(theme: t));

// ------------------------------------------------- 402 + 409 my look

/// Group / channel looks of rooms opened on this phone (chat page fills it).
final roomLooks = <String, RoomLook>{};

/// Colours of NameColors keys.
List<Color> lookColors(List<String> keys) => [for (final k in keys) ?NameColors.colorOf(k)];

/// The look behind a profile header: colour(s) + icons, like an iOS
/// contact poster. Words on it turn white.
class CoverBackdrop extends StatelessWidget {
  const CoverBackdrop({super.key, required this.colors, required this.icons, this.radius = 0});
  final List<Color> colors;
  final String icons;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = colors.isEmpty ? [paletteOf(context).accent] : colors;
    final top = c.first, bottom = c.length > 1 ? c[1] : Color.lerp(c.first, const Color(0xFF000000), 0.18)!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]),
        ),
        child: icons.isEmpty ? const SizedBox.expand() : PatternLayer(id: icons, on: const Color(0xFF000000), strength: 0.35, step: Tokens.coverIconStep),
      ),
    );
  }
}

/// The header of a profile with a cover: photo, name (white) and a line.
class CoverHeader extends StatelessWidget {
  const CoverHeader({super.key, required this.colors, required this.icons, required this.child, this.extendTop = 0});
  final List<Color> colors;
  final String icons;
  final Widget child;

  /// How far the colour reaches up behind the bar (status bar + gap).
  final double extendTop;

  @override
  Widget build(BuildContext context) {
    if (colors.isEmpty && icons.isEmpty) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -extendTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: CoverBackdrop(colors: colors, icons: icons),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: Tokens.space[3]),
          child: child,
        ),
      ],
    );
  }
}

/// My look from settings (one text, see PersonLook).
PersonLook myLook(AppState s) => PersonLook.parse(s.pref('name_color', ''));

/// Someone's look as this phone knows it (group member event or 1:1 note).
PersonLook lookOfUser(AppState s, String userId) {
  if (userId == s.backend.userId) return myLook(s);
  final note = s.pref(PersonLook.prefOf(userId), '');
  return PersonLook.parse(note.isNotEmpty ? note : (NameColors.picked[userId] ?? ''));
}

/// 이름·프로필 꾸미기 (tips 402 + 409; replaces the v1 이름 색 page).
class PersonLookPage extends StatefulWidget {
  const PersonLookPage({super.key});
  @override
  State<PersonLookPage> createState() => _PersonLookPageState();
}

class _PersonLookPageState extends State<PersonLookPage> {
  String myName = '';

  @override
  void initState() {
    super.initState();
    unawaited(
      AppScope.read(context).backend.myName().then((n) {
        if (mounted) setState(() => myName = n);
      }, onError: (_) {}),
    );
  }

  Future<void> put(AppState s, PersonLook look) async {
    final v = look.encode();
    await s.setPref('name_color', v);
    final me = s.backend.userId ?? '';
    if (v.isEmpty) {
      NameColors.picked.remove(me);
    } else {
      NameColors.picked[me] = v;
    }
    if (mounted) setState(() {});
    // Every group I'm in, and as an encrypted note to each 1:1 chat.
    await s.applyNameColor();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final look = myLook(s);
    final me = s.backend.userId ?? '';
    final name = myName.isNotEmpty ? myName : (me.startsWith('@') ? me.substring(1).split(':').first : me);
    final nameColor = NameColors.colorOf(look.name.firstOrNull ?? '') ?? Avatar.colorFor(name);
    final stripe = look.name.length > 1 ? NameColors.colorOf(look.name[1]) : null;
    final cover = lookColors(look.cover);

    Widget dots(String prefix, List<String> now, ValueChanged<List<String>> pick, {bool combos = true}) => Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
      child: Wrap(
        spacing: Tokens.space[2],
        runSpacing: Tokens.space[2],
        children: [
          ColorDot(
            key: Key('$prefix-none'),
            colors: const [],
            picked: now.isEmpty,
            onTap: () => pick(const []),
            child: Icon(CupertinoIcons.nosign, size: Tokens.listIconSmall, color: p.secondaryLabel),
          ),
          for (final k in PersonLook.keys)
            ColorDot(key: Key('$prefix-$k'), colors: lookColors([k]), picked: now.length == 1 && now.first == k, onTap: () => pick([k])),
          if (combos)
            for (final c in PersonLook.combos)
              ColorDot(key: Key('$prefix-${c.join('+')}'), colors: lookColors(c), picked: now.join('+') == c.join('+'), onTap: () => pick(c)),
        ],
      ),
    );

    return SettingsScaffold(
      title: l.personLook,
      children: [
        // Preview: my cover, my name in a group, a reply to me, a link.
        Container(
          key: const Key('look-preview'),
          margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: p.card,
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3])),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (cover.isNotEmpty || look.coverIcons.isNotEmpty)
                      CoverBackdrop(colors: cover, icons: look.coverIcons)
                    else
                      ColoredBox(color: p.searchFill),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Avatar(name: name, size: 64, userId: me),
                        SizedBox(height: Tokens.space[1]),
                        Text(
                          name,
                          style: Tokens.body.style.copyWith(
                            color: cover.isNotEmpty || look.coverIcons.isNotEmpty ? const Color(0xFFFFFFFF) : p.label,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(Tokens.space[2]),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1] - 2, Tokens.space[2], Tokens.space[1] - 2),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NameText(name: name, color: nameColor, stripe: stripe),
                        LookQuote(color: nameColor, icons: look.reply, name: name, text: l.lookSampleQuote, ink: p.label),
                        Text(l.lookSampleText, style: Tokens.body.style.copyWith(color: p.label)),
                        LookQuote(color: nameColor, icons: look.reply, name: l.lookSampleLink, text: l.lookSampleLinkText, ink: p.label),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        group(context, header: l.nameColor, [dots('name', look.name, (v) => put(s, look.copyWith(name: v)))]),
        group(context, header: l.replyIcons, footer: l.replyIconsInfo, [
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
            child: PatternPicker(
              onCard: true,
              picked: look.reply,
              onPick: (id) => put(s, look.copyWith(reply: id)),
            ),
          ),
        ]),
        group(context, header: l.profileColor, [dots('cover', look.cover, (v) => put(s, look.copyWith(cover: v)))]),
        group(context, header: l.profileIcons, footer: l.personLookInfo, [
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
            child: PatternPicker(
              onCard: true,
              picked: look.coverIcons,
              onPick: (id) => put(s, look.copyWith(coverIcons: id)),
            ),
          ),
        ]),
      ],
    );
  }
}

/// A name in its colour; two-stripe colours run across the letters.
class NameText extends StatelessWidget {
  const NameText({super.key, required this.name, required this.color, this.stripe, this.style});
  final String name;
  final Color color;
  final Color? stripe;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final st = (style ?? Tokens.caption.style).copyWith(color: color);
    if (stripe == null) return Text(name, style: st);
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => LinearGradient(colors: [color, stripe!]).createShader(r),
      child: Text(name, style: st),
    );
  }
}

/// A reply quote box tinted with the quoted person's colour, their icons
/// faint inside (tip 402).
class LookQuote extends StatelessWidget {
  const LookQuote({super.key, required this.color, required this.icons, required this.name, required this.text, required this.ink});
  final Color color;
  final String icons;
  final String name;
  final String text;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: Tokens.space[0] - 2, bottom: Tokens.space[0]),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radius[0]),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Stack(
        children: [
          if (icons.isNotEmpty)
            Positioned.fill(
              child: QuoteIcons(id: icons, color: color),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Tokens.caption.style.copyWith(color: color)),
                Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three small icons along the right of a quote box.
class QuoteIcons extends StatelessWidget {
  const QuoteIcons({super.key, required this.id, required this.color});
  final String id;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icons = patternIcons(id);
    if (icons.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.only(right: Tokens.space[1]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, ic) in [icons[0], icons[1 % icons.length], icons[0]].indexed)
              Padding(
                padding: EdgeInsets.only(left: 3, top: i.isOdd ? 10 : 0, bottom: i.isOdd ? 0 : 10),
                child: Icon(ic, size: 11, color: color.withValues(alpha: 0.35)),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------- 412 + 429 group / channel

/// 모양 (group / channel edit, admins): cover colour + icons, status emoji,
/// background for all members, a channel's name colour; 적용 saves it to
/// the room (the server lets only admins change it).
class RoomLookPage extends StatefulWidget {
  const RoomLookPage({super.key, required this.roomId, required this.title, required this.channel, required this.start});
  final String roomId;
  final String title;
  final bool channel;
  final RoomLook start;
  @override
  State<RoomLookPage> createState() => _RoomLookPageState();
}

class _RoomLookPageState extends State<RoomLookPage> {
  late RoomLook look = widget.start;
  bool busy = false;

  /// The room's level (stage A, worked out on this phone like 레벨 page);
  /// parts open as it grows.
  int level = 0;

  bool open(int need) => !RoomLookLevels.on || level >= need;

  @override
  void initState() {
    super.initState();
    final b = AppScope.read(context).backend;
    () async {
      try {
        final m = await b.timeline(widget.roomId, limit: 1000);
        final mem = await b.members(widget.roomId);
        final now = DateTime.now();
        final cut = now.subtract(const Duration(days: 28));
        final active = {
          for (final x in m)
            if (x.time.isAfter(cut) && x.kind != 'call') x.sender,
        }.length;
        final days = m.isEmpty ? 0 : now.difference(m.map((x) => x.time).reduce((a, b) => a.isBefore(b) ? a : b)).inDays;
        if (mounted) setState(() => level = levelOf(mem.length, active, days));
      } catch (_) {}
    }();
  }

  Future<void> apply() async {
    if (busy) return;
    final l = L.of(context);
    setState(() => busy = true);
    try {
      await AppScope.read(context).backend.setRoomConfig(widget.roomId, RoomLook.cfgKey, look.toJson());
      if (!mounted) return;
      showStoryToast(context, l.roomLookSaved);
      Navigator.of(context).pop(look);
    } catch (_) {
      if (mounted) showStoryToast(context, l.roomLookFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final cover = lookColors(look.cover);
    Widget locked(int need, Widget child) => open(need)
        ? child
        : Stack(
            children: [
              IgnorePointer(child: Opacity(opacity: 0.35, child: child)),
              Positioned.fill(
                child: Center(
                  child: GlassChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.lock_fill, size: 14, color: p.secondaryLabel),
                        SizedBox(width: Tokens.space[0]),
                        Text(l.lookFromLevel(need), style: Tokens.caption.style.copyWith(color: p.label)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
    Widget dots() => Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
      child: Wrap(
        spacing: Tokens.space[2],
        runSpacing: Tokens.space[2],
        children: [
          ColorDot(
            key: const Key('room-cover-none'),
            colors: const [],
            picked: look.cover.isEmpty,
            onTap: () => setState(() => look = look.copyWith(cover: const [])),
            child: Icon(CupertinoIcons.nosign, size: Tokens.listIconSmall, color: p.secondaryLabel),
          ),
          for (final k in PersonLook.keys)
            ColorDot(
              key: Key('room-cover-$k'),
              colors: lookColors([k]),
              picked: look.cover.join('+') == k,
              onTap: () => setState(() => look = look.copyWith(cover: [k])),
            ),
          for (final c in PersonLook.combos)
            ColorDot(
              key: Key('room-cover-${c.join('+')}'),
              colors: lookColors(c),
              picked: look.cover.join('+') == c.join('+'),
              onTap: () => setState(() => look = look.copyWith(cover: c)),
            ),
        ],
      ),
    );
    final walls = readyWalls(l);
    return SettingsScaffold(
      title: l.roomLook,
      children: [
        // Live preview of the info header.
        Container(
          key: const Key('room-look-preview'),
          height: 170,
          margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: p.card,
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3])),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cover.isNotEmpty || look.logo.isNotEmpty) CoverBackdrop(colors: cover, icons: look.logo),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Avatar(name: widget.title, size: 72, squircle: !widget.channel, channel: widget.channel, roomId: widget.roomId),
                  SizedBox(height: Tokens.space[1]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.body.style.copyWith(
                            color: cover.isNotEmpty || look.logo.isNotEmpty ? const Color(0xFFFFFFFF) : p.label,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (look.emoji.isNotEmpty) ...[SizedBox(width: Tokens.space[0]), RoomStatusEmoji(key: ValueKey(look.emoji), emoji: look.emoji)],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        group(context, header: l.roomCoverColor, [locked(RoomLook.coverLevel, dots())]),
        group(context, header: l.roomLogoIcons, [
          locked(
            RoomLook.logoLevel,
            Padding(
              padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
              child: PatternPicker(
                onCard: true,
                picked: look.logo,
                onPick: (id) => setState(() => look = look.copyWith(logo: id)),
              ),
            ),
          ),
        ]),
        group(context, header: l.roomStatusEmoji, [
          locked(
            RoomLook.emojiLevel,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              child: Wrap(
                spacing: Tokens.space[1],
                runSpacing: Tokens.space[1],
                children: [
                  for (final e in ['', ...RoomLook.emojis])
                    GestureDetector(
                      key: Key('room-emoji-$e'),
                      onTap: () => setState(() => look = look.copyWith(emoji: e)),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.searchFill,
                          border: Border.all(color: look.emoji == e ? p.accent : const Color(0x00000000), width: Tokens.lookDotRing),
                        ),
                        child: e.isEmpty
                            ? Icon(CupertinoIcons.nosign, size: Tokens.listIconSmall, color: p.secondaryLabel)
                            : Text(e, style: const TextStyle(fontSize: 20, fontFamilyFallback: Tokens.emojiFallback)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
        group(context, header: l.roomWallAll, footer: l.roomWallAllInfo, [
          locked(
            RoomLook.wallLevel,
            SizedBox(
              height: 166,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                children: [
                  for (final (spec, label) in [('', l.none), ...walls])
                    Padding(
                      padding: EdgeInsets.only(right: Tokens.space[2]),
                      child: SizedBox(
                        width: 64,
                        child: WallTile(
                          key: Key('room-wall-$label'),
                          spec: spec.isEmpty ? 'plain' : spec,
                          label: label,
                          picked: look.wall == spec,
                          onTap: () => setState(() => look = look.copyWith(wall: spec)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ]),
        if (widget.channel)
          group(context, header: l.channelNameColor, footer: l.channelNameColorInfo, [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              child: Wrap(
                spacing: Tokens.space[2],
                runSpacing: Tokens.space[2],
                children: [
                  ColorDot(
                    key: const Key('ch-name-none'),
                    colors: const [],
                    picked: look.name.isEmpty,
                    onTap: () => setState(() => look = look.copyWith(name: '')),
                    child: Icon(CupertinoIcons.nosign, size: Tokens.listIconSmall, color: p.secondaryLabel),
                  ),
                  for (final k in PersonLook.keys)
                    ColorDot(
                      key: Key('ch-name-$k'),
                      colors: lookColors([k]),
                      picked: look.name == k,
                      onTap: () => setState(() => look = look.copyWith(name: k)),
                    ),
                ],
              ),
            ),
          ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], 0),
          child: AccentButton(key: const Key('room-look-apply'), text: l.applyChanges, onTap: apply),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], 0),
          child: Text(l.roomLookInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

/// RoomLookPage parts open by community level (the look-only demo turns
/// this off so every part can be tried).
class RoomLookLevels {
  const RoomLookLevels._();
  static bool on = true;
}

/// The room's status emoji: it drops into place with a small bounce
/// (Telegram: the emoji flies into the slot).
class RoomStatusEmoji extends StatefulWidget {
  const RoomStatusEmoji({super.key, required this.emoji, this.size = 20});
  final String emoji;
  final double size;
  @override
  State<RoomStatusEmoji> createState() => _RoomStatusEmojiState();
}

class _RoomStatusEmojiState extends State<RoomStatusEmoji> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 480))..forward();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: CurvedAnimation(parent: c, curve: Curves.elasticOut),
    child: Text(
      widget.emoji,
      style: TextStyle(fontSize: widget.size, fontFamilyFallback: Tokens.emojiFallback),
    ),
  );
}
