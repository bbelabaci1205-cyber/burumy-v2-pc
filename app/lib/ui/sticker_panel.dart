// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sticker panel under the composer, Telegram style (Eric 2026-11-26): see-
// through glass, a row of pack icons, '검색' with a feeling row (heart, thumbs
// up, ...), one scrolling list of sections in 5 columns, and a floating
// 스티커 | 이모지 switch. Tap sends.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/emoji_words.dart';
import '../core/features.dart';
import '../core/sticker_sets.dart';
import '../design/tokens.dart';
import '../stickers/catalog.dart';
import '../stickers/char_emoji.dart';
import '../stickers/sticker_words.dart';
import 'bubbles.dart' show SoapBubble;
import 'glass.dart';
import 'settings_pages.dart' show packName;
import 'sticker_maker.dart' show myStickers;
import 'emoji_pick.dart';
import 'emoji_status.dart' show openEmojiStatus;
import 'ios_route.dart';
import 'sticker_sets_ui.dart' show MySetsPage, setCover, SetItemView;
import 'wide.dart' show paneNav;
import '../l10n/app_localizations.dart';
import 'common.dart';

/// Pref holding recently sent stickers (newest first, at most 16).
const recentStickersKey = 'recent_stickers';

/// Saved phrases for the composer (Settings > Chats > Quick replies).
List<String> quickReplies(AppState s) {
  try {
    return [for (final x in jsonDecode(s.pref('quick_replies', '[]')) as List) '$x'];
  } catch (_) {
    return const [];
  }
}

/// All packs in my order (Settings > Stickers and emoji, drag to sort);
/// with "묶음 정렬 유연하게" on, packs used lately come first.
List<StickerPack> orderedPacks(AppState s) {
  final byId = {for (final p in stickerPacks) p.id: p};
  final order = <String>[
    for (final id in s.pref('pack_order', '').split(','))
      if (byId.containsKey(id)) id,
  ];
  for (final p in stickerPacks) {
    if (!order.contains(p.id)) order.add(p.id);
  }
  if (s.on('pack_dynamic', fallback: true)) {
    final packOf = {
      for (final p in stickerPacks)
        for (final i in p.items) i: p.id,
    };
    final used = <String>[];
    for (final id in recentStickers(s)) {
      final k = packOf[id];
      if (k != null && !used.contains(k)) used.add(k);
    }
    order.sort((a, b) => (used.contains(a) ? used.indexOf(a) : 99 + order.indexOf(a)).compareTo(used.contains(b) ? used.indexOf(b) : 99 + order.indexOf(b)));
  }
  return [for (final id in order) byId[id]!];
}

/// Sticker packs switched on in settings, in my order.
List<StickerPack> shownPacks(AppState s) => [
  for (final p in orderedPacks(s))
    if (!s.on('pack_off:${p.id}')) p,
];

List<String> recentStickers(AppState s) => [
  for (final id in s.pref(recentStickersKey, '').split(','))
    if (id.isNotEmpty && stickerAsset(id) != null) id,
];

/// A sticker of my set fits a feeling chip ([want] = meanings) or the
/// search words (its emoji's words, the set's name, a built-in's meaning).
bool setItemMatches(StickerSet set, SetItem it, List<String>? want, String query) {
  if (want != null) return it.id.isNotEmpty && want.contains(stickerMeaning(it.id));
  if (it.id.isNotEmpty && stickerMatches(it.id, query, emoji: it.emoji)) return true;
  final words = query.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return false;
  final mine = '${set.name.toLowerCase()} ${it.emoji} ${emojiWords[it.emoji] ?? ''}';
  return words.every(mine.contains);
}

class StickerPanel extends StatefulWidget {
  const StickerPanel({
    super.key,
    required this.onPick,
    this.phrases = const [],
    this.onPhrase,
    this.onBubble,
    this.onEmoji,
    this.onMake,
    this.onMakeText,
    this.onMine,
    this.onSendEmoji,
    this.emojiTop,
    this.gifTab,
  });

  /// Hold an emoji > 보내기 (tip 378): sends it at once.
  final void Function(String emoji)? onSendEmoji;
  final void Function(String id) onPick;

  /// '비눗방울 보내기' tile first in the grid (1:1 chats; Eric 2026-11-26).
  final VoidCallback? onBubble;

  /// Quick replies (Settings > Chats); tapping one puts it in the composer.
  final List<String> phrases;
  final void Function(String text)? onPhrase;

  /// '스티커 만들기' tile, and a tap on one of 내 스티커 (sends the PNG).
  final VoidCallback? onMake;

  /// 글자 스티커 (4-app board): words in a shape, made here.
  final VoidCallback? onMakeText;
  final void Function(Uint8List png)? onMine;

  /// The 이모지 side: a tapped emoji goes into the composer.
  final void Function(String emoji)? onEmoji;

  /// Rows on top of the emoji side: 내 이모지 · 그룹 이모지 (tips 354 · 430).
  final List<Widget> Function(BuildContext context)? emojiTop;

  /// The GIF side (내 GIF, tip 558); null = no GIF segment.
  final Widget Function(BuildContext context)? gifTab;

  /// Telegram's panel height (keyboard height on a 6.1" iPhone).
  static const height = 336.0;
  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> {
  String tab = '';
  bool emoji = false;

  /// The GIF side is showing (tip 558).
  bool gif = false;
  String query = '';
  String? feeling;

  /// The emoji side's search (tip 366) and feeling chip (tip 378).
  String emojiQuery = '';
  String? emojiFeeling;
  final search = TextEditingController();
  final focus = FocusNode();
  final scroll = ScrollController();
  final heads = <String, GlobalKey>{};

  GlobalKey head(String id) => heads.putIfAbsent(id, () => GlobalKey());

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    scroll.dispose();
    super.dispose();
  }

  void pick(AppState s, String id) {
    final recent = [id, ...recentStickers(s).where((x) => x != id)].take(16).join(',');
    s.setPref(recentStickersKey, recent);
    widget.onPick(id);
  }

  /// Tap on a pack icon: scroll its section to the top.
  void jump(String id) {
    setState(() {
      tab = id;
      query = '';
      feeling = null;
      search.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = heads[id]?.currentContext;
      if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final l = L.of(context);
    final recent = recentStickers(s);
    final packs = shownPacks(s);
    final mine = myStickers(s);
    final phrases = widget.phrases.isNotEmpty && widget.onPhrase != null;
    final glyph = p.secondaryLabel;
    // Sections: quick replies, recent (when there is any), then the packs.
    final sections = <(String, String, List<String>, Widget)>[
      if (phrases) ('phrases', l.stickerPhrases, widget.phrases, Icon(CupertinoIcons.text_bubble, size: Tokens.listIcon, color: glyph)),
      if (recent.isNotEmpty) ('recent', l.stickerRecent, recent, Icon(CupertinoIcons.clock, size: Tokens.listIcon, color: glyph)),
      if (mine.isNotEmpty && widget.onMine != null)
        (
          'mine',
          l.stickerMine,
          [for (var i = 0; i < mine.length; i++) 'mine:$i'],
          Icon(CupertinoIcons.person_crop_circle, size: Tokens.listIcon, color: glyph),
        ),
      // 스티커 묶음 (tips 538 + 441): my sets and the ones I added.
      if (Features.emojiStickers)
        for (final set in StickerSets.all(s))
          if (set.kind == 'sticker' && set.items.isNotEmpty)
            ('set:${set.id}', set.name, [for (var i = 0; i < set.items.length; i++) 'set:${set.id}:$i'], setCover(set, size: 28)),
      for (final k in packs) (k.id, packName(l, k.id), k.items, Image.asset(k.asset(k.items.first))),
    ];
    final at = sections.any((x) => x.$1 == tab) ? tab : (sections.isEmpty ? '' : sections.first.$1);
    return SizedBox(
      key: const Key('sticker-panel'),
      height: StickerPanel.height,
      child: LiquidGlass(
        radius: 38,
        shadow: false,
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: Tokens.space[1]),
                if (gif && widget.gifTab != null) Expanded(child: widget.gifTab!(context)),
                if (!gif || widget.gifTab == null) ...[
                  SizedBox(height: 44, child: emoji ? emojiTabs(p) : packTabs(p, sections, at)),
                  if (!emoji) searchRow(p, l),
                  if (emoji && Features.emojiStickers)
                    Padding(
                      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[0], Tokens.space[2], Tokens.space[0]),
                      child: EmojiSearchBar(
                        feeling: emojiFeeling,
                        onQuery: (v) => setState(() => emojiQuery = v),
                        onFeeling: (f) => setState(() => emojiFeeling = f),
                      ),
                    ),
                  Expanded(child: emoji ? emojiGrid(p, l) : stickerList(p, l, s, sections)),
                ],
              ],
            ),
            if (widget.onEmoji != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: Tokens.space[2],
                child: Center(child: switcher(p, l)),
              ),
          ],
        ),
      ),
    );
  }

  Widget packTabs(Palette p, List<(String, String, List<String>, Widget)> sections, String at) => ListView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
    children: [
      for (final x in sections)
        GestureDetector(
          key: Key('sticker-tab-${x.$1}'),
          onTap: () => jump(x.$1),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.all(Tokens.space[0] + 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: x.$1 == at ? p.secondaryLabel.withValues(alpha: 0.16) : null, shape: BoxShape.circle),
            child: x.$4,
          ),
        ),
      // 내 스티커 묶음 (make, share, 둘러보기).
      if (Features.emojiStickers)
        GestureDetector(
          key: const Key('sticker-tab-sets'),
          onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => const MySetsPage())),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            child: Icon(CupertinoIcons.square_stack_3d_up, size: 21, color: p.secondaryLabel),
          ),
        ),
    ],
  );

  /// '검색' and the feeling row in one see-through capsule (Telegram).
  Widget searchRow(Palette p, L l) {
    final typing = focus.hasFocus || query.isNotEmpty;
    return Container(
      key: const Key('sticker-search'),
      height: 36,
      margin: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[0], Tokens.space[2], Tokens.space[0]),
      decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(18)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: Tokens.space[2]),
                Icon(CupertinoIcons.search, size: 18, color: p.secondaryLabel),
                Expanded(
                  child: CupertinoTextField(
                    key: const Key('sticker-search-field'),
                    controller: search,
                    focusNode: focus,
                    decoration: null,
                    placeholder: l.searchChats,
                    placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                    style: Tokens.body.style.copyWith(color: p.label),
                    padding: EdgeInsets.only(left: Tokens.space[0] + 2),
                    onChanged: (v) => setState(() {
                      query = v;
                      feeling = null;
                    }),
                    suffix: typing
                        ? CupertinoButton(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                            minimumSize: Size.zero,
                            onPressed: () {
                              search.clear();
                              focus.unfocus();
                              setState(() => query = '');
                            },
                            child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: p.secondaryLabel),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          // The feelings sit over the rest of the capsule until typing starts.
          if (!typing)
            Positioned(
              left: 96,
              right: Tokens.space[1],
              top: 0,
              bottom: 0,
              // Soft fade at the right edge so a half-cut icon reads as "more" (보안검수 UI 2026-11-28).
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (r) =>
                    const LinearGradient(colors: [Color(0xFF000000), Color(0xFF000000), Color(0x00000000)], stops: [0, 0.88, 1]).createShader(r),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final (id, icon, _) in stickerFeelings)
                      GestureDetector(
                        key: Key('sticker-feel-$id'),
                        onTap: () => setState(() => feeling = feeling == id ? null : id),
                        // Telegram: a small soft circle behind the chosen one (Eric: not the full height).
                        child: SizedBox(
                          width: 36,
                          child: Center(
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: feeling == id ? p.secondaryLabel.withValues(alpha: 0.16) : null, shape: BoxShape.circle),
                              child: Icon(icon, size: 20, color: feeling == id ? p.label : p.secondaryLabel),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget sectionHead(Palette p, String id, String title) => Padding(
    key: head(id),
    padding: EdgeInsets.fromLTRB(0, Tokens.space[2], 0, Tokens.space[0]),
    child: Text(
      title,
      textAlign: TextAlign.center,
      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
    ),
  );

  SliverGrid grid(List<Widget> cells) =>
      SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), delegate: SliverChildListDelegate(cells));

  Widget cell(AppState s, String id) => id.startsWith('set:')
      ? setCell(s, id)
      : GestureDetector(
          key: Key('sticker-$id'),
          onTap: () => pick(s, id),
          child: Padding(
            padding: EdgeInsets.all(Tokens.space[0]),
            child: StickerPack.moving(id)
                ? MovingWhenSeen(asset: stickerAsset(id)!)
                : Image.asset(stickerAsset(id)!, cacheWidth: (80 * MediaQuery.devicePixelRatioOf(context)).round()),
          ),
        );

  /// One sticker of a set ('set:<set id>:<index>'): built-in ones go as
  /// stickers, PNGs as 내 스티커 do.
  Widget setCell(AppState s, String key) {
    final parts = key.split(':');
    final set = StickerSets.all(s).where((x) => x.id == parts[1]).firstOrNull;
    final i = int.tryParse(parts.last) ?? -1;
    if (set == null || i < 0 || i >= set.items.length) return const SizedBox.shrink();
    final it = set.items[i];
    return GestureDetector(
      key: Key('sticker-$key'),
      onTap: () => it.png != null ? widget.onMine?.call(it.png!) : pick(s, it.id),
      child: Padding(padding: EdgeInsets.all(Tokens.space[0]), child: SetItemView(it, size: 80)),
    );
  }

  Widget stickerList(Palette p, L l, AppState s, List<(String, String, List<String>, Widget)> sections) {
    final bottom = widget.onEmoji != null ? 56.0 : Tokens.space[2];
    final pad = EdgeInsets.symmetric(horizontal: Tokens.space[1]);
    // Searching or a feeling: one grid of every matching sticker.
    if (query.trim().isNotEmpty || feeling != null) {
      final want = feeling == null ? null : stickerFeelings.firstWhere((f) => f.$1 == feeling).$3;
      final hits = <String>{
        // My sets first: their emoji and name count too (tip 496).
        if (Features.emojiStickers)
          for (final set in StickerSets.all(s))
            if (set.kind == 'sticker')
              for (final (i, it) in set.items.indexed)
                if (setItemMatches(set, it, want, query)) 'set:${set.id}:$i',
        for (final k in shownPacks(s))
          for (final id in k.items)
            if (want != null ? want.contains(stickerMeaning(id)) : stickerMatches(id, query)) id,
      }.toList();
      if (hits.isEmpty) {
        return Center(
          child: Text(l.stickerNone, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        );
      }
      return CustomScrollView(
        key: const Key('sticker-hits'),
        slivers: [
          SliverPadding(
            padding: pad.copyWith(top: Tokens.space[1], bottom: bottom),
            sliver: grid([for (final id in hits) cell(s, id)]),
          ),
        ],
      );
    }
    final first = sections.indexWhere((x) => x.$1 != 'phrases');
    final mine = myStickers(s);
    return CustomScrollView(
      controller: scroll,
      // Every section built, so a pack icon can scroll to its header.
      cacheExtent: 4000,
      slivers: [
        for (var i = 0; i < sections.length; i++) ...[
          SliverToBoxAdapter(child: sectionHead(p, sections[i].$1, sections[i].$2)),
          if (sections[i].$1 == 'phrases')
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  for (var k = 0; k < sections[i].$3.length; k++)
                    GestureDetector(
                      key: Key('phrase-$k'),
                      onTap: () => widget.onPhrase!(sections[i].$3[k]),
                      child: Container(
                        margin: EdgeInsets.only(bottom: Tokens.space[1]),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                        decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                        child: Text(sections[i].$3[k], style: Tokens.preview.style.copyWith(color: p.label)),
                      ),
                    ),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: pad,
              sliver: grid([
                // Telegram puts '스티커 만들기' first; ours starts with '비눗방울 보내기'.
                if (i == first && widget.onBubble != null)
                  BubbleTile(key: const Key('sticker-tile-bubble'), label: l.stickerTileBubble, onTap: widget.onBubble!),
                if (i == first && widget.onMake != null)
                  MakeTile(key: const Key('sticker-tile-make'), icon: CupertinoIcons.add, label: l.stickerTileMake, onTap: widget.onMake!),
                if (i == first && widget.onMakeText != null)
                  MakeTile(key: const Key('sticker-tile-text'), icon: CupertinoIcons.textformat, label: l.textStickerTile, onTap: widget.onMakeText!),
                for (final id in sections[i].$3)
                  if (id.startsWith('mine:'))
                    GestureDetector(
                      key: Key('sticker-$id'),
                      onTap: () => widget.onMine!(mine[int.parse(id.substring(5))]),
                      child: Padding(padding: EdgeInsets.all(Tokens.space[0]), child: Image.memory(mine[int.parse(id.substring(5))])),
                    )
                  else
                    cell(s, id),
              ]),
            ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );
  }

  Widget emojiTabs(Palette p) => ListView(
    scrollDirection: Axis.horizontal,
    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
    children: [
      for (final (id, icon, _) in emojiGroups)
        GestureDetector(
          key: Key('emoji-tab-$id'),
          onTap: () => jump('emoji-$id'),
          child: Container(
            width: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tab == 'emoji-$id' ? p.secondaryLabel.withValues(alpha: 0.16) : null, shape: BoxShape.circle),
            child: Icon(icon, size: 21, color: p.secondaryLabel),
          ),
        ),
      // Our character emoji after Apple's groups (Telegram: added packs follow).
      for (final g in charEmojiGroups.keys)
        GestureDetector(
          key: Key('emoji-tab-c-$g'),
          onTap: () => jump('emoji-c-$g'),
          child: Container(
            width: 40,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: EdgeInsets.all(Tokens.space[0] + 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tab == 'emoji-c-$g' ? p.secondaryLabel.withValues(alpha: 0.16) : null, shape: BoxShape.circle),
            child: CharEmoji(charEmojiGroups[g]!.first, size: 28),
          ),
        ),
    ],
  );

  String emojiTitle(L l, String id) => switch (id) {
    'smileys' => l.emoji_smileys,
    'people' => l.emoji_people,
    'animals' => l.emoji_animals,
    'food' => l.emoji_food,
    'activity' => l.emoji_activity,
    'travel' => l.emoji_travel,
    'objects' => l.emoji_objects,
    _ => l.emoji_symbols,
  };

  /// Hold an emoji: it grows, with 복사 / 보내기 / 상태로 (tip 378).
  void zoom(String e) => showEmojiZoom(
    context,
    e,
    onSend: widget.onSendEmoji == null ? null : () => widget.onSendEmoji!(e),
    onStatus: Features.emojiStickers ? () => openEmojiStatus(context, emoji: e) : null,
  );

  Widget emojiGrid(Palette p, L l) {
    final hits = Features.emojiStickers && (emojiQuery.trim().isNotEmpty || emojiFeeling != null) ? emojiHits(emojiQuery, emojiFeeling) : null;
    if (hits != null) {
      if (hits.isEmpty)
        return Center(
          child: Text(l.emojiNone, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        );
      return GridView(
        key: const Key('emoji-hits'),
        padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[1], Tokens.space[1], 56),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        children: [
          for (final e in hits)
            GestureDetector(
              key: Key('emoji-hit-$e'),
              onTap: () => widget.onEmoji!(e),
              onLongPress: () => zoom(e),
              child: Center(
                child: Text(e, style: const TextStyle(fontSize: 30, fontFamilyFallback: Tokens.emojiFallback)),
              ),
            ),
        ],
      );
    }
    return emojiAll(p, l);
  }

  Widget emojiAll(Palette p, L l) => CustomScrollView(
    key: const Key('emoji-grid'),
    controller: scroll,
    cacheExtent: 20000,
    slivers: [
      ...?widget.emojiTop?.call(context),
      for (final (id, _, all) in emojiGroups) ...[
        SliverToBoxAdapter(child: sectionHead(p, 'emoji-$id', emojiTitle(l, id))),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            delegate: SliverChildListDelegate([
              for (final e in all.characters)
                GestureDetector(
                  key: Key('emoji-$e'),
                  onTap: () => widget.onEmoji!(e),
                  onLongPress: Features.emojiStickers ? () => zoom(e) : null,
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 30, fontFamilyFallback: Tokens.emojiFallback)),
                  ),
                ),
            ]),
          ),
        ),
      ],
      for (final MapEntry(key: g, value: ids) in charEmojiGroups.entries) ...[
        SliverToBoxAdapter(child: sectionHead(p, 'emoji-c-$g', l.charEmojiTitle(packName(l, g)))),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
            delegate: SliverChildListDelegate([
              for (final id in ids)
                GestureDetector(
                  key: Key('emoji-c-$id'),
                  onTap: () => widget.onEmoji!(':$id:'),
                  child: Center(child: CharEmoji(id, size: 34)),
                ),
            ]),
          ),
        ),
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 56)),
    ],
  );

  /// Telegram's floating GIF | 스티커 | 이모지 capsule (GIF = 내 GIF, tip 558;
  /// GIF search is next version).
  Widget switcher(Palette p, L l) => SizedBox(
    height: 40,
    child: LiquidGlass(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (side, label, key) in [
              if (widget.gifTab != null) ('gif', 'GIF', 'seg-gif'),
              ('stickers', l.segStickers, 'seg-stickers'),
              ('emoji', l.segEmoji, 'seg-emoji'),
            ])
              GestureDetector(
                key: Key(key),
                onTap: () => setState(() {
                  gif = side == 'gif';
                  emoji = side == 'emoji';
                  tab = '';
                  focus.unfocus();
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (side == 'gif' ? gif : !gif && emoji == (side == 'emoji')) ? Color(p.dark ? 0x33FFFFFF : 0x14000000) : null,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Text(label, style: Tokens.preview.style.copyWith(color: p.label)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// '비눗방울 보내기' as a sticker of its own (Eric 2026-11-26): a soap bubble
/// filling the cell with the words inside, so it reads even without them.
class BubbleTile extends StatelessWidget {
  const BubbleTile({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = math.min(box.maxWidth, box.maxHeight) - Tokens.space[0];
          return Stack(
            alignment: Alignment.center,
            children: [
              SoapBubble(color: p.accent, size: size),
              Padding(
                padding: EdgeInsets.all(size * 0.16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    // White on the green bubble (green on green could not be
                    // read; 검수 2026-11-28).
                    style: Tokens.caption.style.copyWith(
                      color: p.onAccent,
                      fontWeight: Tokens.semi,
                      height: 1.15,
                      shadows: const [Shadow(color: Color(0x40000000), blurRadius: 2, offset: Offset(0, 0.5))],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Telegram's '스티커 만들기' look: a rounded grey square, a thin "+" and a
/// two-line grey label, the size of one sticker cell.
class MakeTile extends StatelessWidget {
  const MakeTile({super.key, required this.icon, required this.label, required this.onTap, this.art});
  final IconData icon;

  /// A picture in place of the "+" (the bubble tile shows a bubble).
  final Widget? art;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(Tokens.space[0]),
        child: Container(
          decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[2])),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(2),
          // Short cells on small phones: shrink rather than overflow.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                art ?? Icon(icon, size: 28, color: p.secondaryLabel),
                SizedBox(height: Tokens.space[0]),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A moving sticker in the panel: loaded once it first scrolls into view,
/// and moving only while it is on screen (Telegram plays the visible ones).
/// The panel builds every section ahead (for the pack icons), so without
/// this a few hundred moving pictures would load and play at once.
class MovingWhenSeen extends StatefulWidget {
  const MovingWhenSeen({super.key, required this.asset});
  final String asset;
  @override
  State<MovingWhenSeen> createState() => _MovingWhenSeenState();
}

class _MovingWhenSeenState extends State<MovingWhenSeen> {
  bool seen = false, onScreen = false;
  ScrollPosition? position;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = Scrollable.maybeOf(context)?.position;
    if (now != position) {
      position?.removeListener(check);
      position = now?..addListener(check);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => check());
  }

  @override
  void dispose() {
    position?.removeListener(check);
    super.dispose();
  }

  void check() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final view = Scrollable.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (box == null || view == null || !box.attached || !view.attached) return;
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    final now = top + box.size.height > -40 && top < view.size.height + 40;
    if (now != onScreen || (now && !seen)) {
      setState(() {
        onScreen = now;
        seen = seen || now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!seen) return const SizedBox.expand();
    return TickerMode(
      enabled: onScreen,
      child: Image.asset(widget.asset, cacheWidth: (80 * MediaQuery.devicePixelRatioOf(context)).round()),
    );
  }
}
