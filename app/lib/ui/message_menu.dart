// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Long press on a message (iOS / Telegram style): the page blurs, the
// message lifts in place, a glass reaction capsule sits above it and an
// iOS menu with icons below it.
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/sticker_words.dart' show emojiGroups;
import 'emoji_pick.dart';
import '../stickers/catalog.dart' show charReactions;
import '../stickers/char_emoji.dart';
import 'common.dart';
import 'glass.dart';
import 'wide.dart';

/// One menu row. [group] starts a new block (iOS thick separator above).
class MenuItem {
  const MenuItem(this.id, this.label, this.icon, {this.danger = false, this.group = false});
  final String id;
  final String label;
  final IconData icon;
  final bool danger;
  final bool group;
}

/// Tip 341: how many reactions one person may put on one message.
const myReactionsMax = 3;

/// Every emoji group, split once (the open reaction panel).
final _groupEmoji = [for (final (_, _, all) in emojiGroups) all.characters.toList()];

/// More emoji behind the ⌄ button of the reaction capsule.
const moreReactions = [
  '👍', '❤️', '😂', '😮', '😢', '🙏', '🔥', '🎉', //
  '👏', '😍', '🥰', '😆', '🤔', '😎', '😭', '😡',
  '👎', '💯', '✨', '🙌', '🤝', '💪', '👀', '🥲',
  '😴', '🤯', '🤩', '😇', '🫡', '🤗', '💔', '⭐',
];

/// Shows the menu; returns the picked item id, or 'react:<emoji>'.
/// [more] = the emoji behind ⌄ (empty hides the button).
Future<String?> showMessageMenu(
  BuildContext context, {
  required Widget bubble,
  required bool mine,
  required List<String> reactions,
  required List<MenuItem> items,
  List<String> more = moreReactions,
  bool iconsFirst = false,

  /// The lifted copy takes touches (a hidden chat's peek: hold to read).
  bool bubbleTouch = false,

  /// Tips 200/222: holding the lifted bubble again picks part of its words
  /// (iOS handles + 복사·전체 선택). Copying returns "copied-part".
  bool selectable = false,

  /// Tip 399: the picked words also get "인용" (returns "quote-part:<words>").
  bool quotable = false,

  /// Grey first row above the actions (tip 421: "오늘 10:38에 읽음").
  String? header,

  /// Tip 384: the header row can be tapped (returns this id), with small
  /// photos at its end ("✓✓ 3명 읽음 ○○○ ›").
  String? headerId,
  Widget? headerTrailing,

  /// Grey note under the actions (557: why copy / forward are missing).
  String? footer,

  /// The character reactions under ⌄ (rooms that limit reactions hide them).
  bool characters = false,
}) {
  return paneNav(context).push<String>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (c, a, _) => _MessageMenu(
        anim: a,
        bubble: bubble,
        mine: mine,
        reactions: reactions,
        more: more,
        items: items,
        iconsFirst: iconsFirst,
        bubbleTouch: bubbleTouch,
        selectable: selectable,
        quotable: quotable,
        header: header,
        headerId: headerId,
        headerTrailing: headerTrailing,
        footer: footer,
        characters: characters,
      ),
    ),
  );
}

/// Sizes (iOS 27 context menu, checked against the v1 screenshot at
/// 393 pt): 250 wide, 44 rows, 16 side inset, 22 line icons, 26 corners,
/// 8 pt block separator; reaction capsule 44 tall with 32 emoji.
class _MessageMenu extends StatefulWidget {
  const _MessageMenu({
    required this.anim,
    required this.bubble,
    required this.mine,
    required this.reactions,
    required this.more,
    required this.items,
    this.iconsFirst = false,
    this.bubbleTouch = false,
    this.selectable = false,
    this.quotable = false,
    this.header,
    this.headerId,
    this.headerTrailing,
    this.characters = false,
    this.footer,
  });
  final bool characters;
  final bool selectable;
  final bool quotable;
  final String? header;
  final String? headerId;
  final Widget? headerTrailing;
  final String? footer;

  /// Icon before the words (the chat list menu, v1 layout).
  final bool iconsFirst;
  final bool bubbleTouch;
  final Animation<double> anim;
  final Widget bubble;
  final bool mine;
  final List<String> reactions;
  final List<String> more;
  final List<MenuItem> items;

  static const width = 250.0, row = 44.0, emoji = 32.0;

  @override
  State<_MessageMenu> createState() => _MessageMenuState();
}

class _MessageMenuState extends State<_MessageMenu> {
  bool open = false;

  /// Tip 358: search and feeling chips in the open reaction panel.
  String query = '';
  String? feeling;
  final selectFocus = FocusNode();

  /// The words picked on the lifted bubble right now.
  String picked = '';

  @override
  void dispose() {
    selectFocus.dispose();
    super.dispose();
  }

  /// The lifted bubble with word picking: iOS handles and toolbar; "복사"
  /// copies just the picked words and closes the menu.
  Widget selectableBubble(Widget child) => SelectableRegion(
    key: const Key('menu-select-text'),
    focusNode: selectFocus,
    selectionControls: cupertinoTextSelectionHandleControls,
    onSelectionChanged: (c) => picked = c?.plainText ?? '',
    contextMenuBuilder: (c, st) => CupertinoAdaptiveTextSelectionToolbar.buttonItems(
      anchors: st.contextMenuAnchors,
      buttonItems: [
        for (final b in st.contextMenuButtonItems) ...[
          b.type == ContextMenuButtonType.copy
              ? b.copyWith(
                  onPressed: () {
                    b.onPressed?.call();
                    if (mounted) Navigator.pop(context, 'copied-part');
                  },
                )
              : b,
          // Telegram: 복사, then 인용 (tip 399).
          if (b.type == ContextMenuButtonType.copy && widget.quotable)
            ContextMenuButtonItem(
              label: L.of(context).fmtQuote,
              onPressed: () {
                final words = picked.trim();
                if (words.isNotEmpty && mounted) Navigator.pop(context, 'quote-part:$words');
              },
            ),
        ],
      ],
    ),
    child: child,
  );

  Widget emoji(String e, {double size = 26}) => GestureDetector(
    key: Key('react-$e'),
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.pop(context, 'react:$e'),
    child: SizedBox(
      width: _MessageMenu.emoji + 8,
      height: _MessageMenu.emoji + 8,
      child: Center(child: ReactionGlyph(e, size: size)),
    ),
  );

  Widget capsule(Palette p) {
    final more = widget.more.where((e) => !widget.reactions.contains(e)).toList();
    if (open) {
      final cell = _MessageMenu.emoji + 8;
      // Every emoji is offered only where the room allows any reaction.
      final all = Features.emojiStickers && widget.characters;
      final hits = all && (query.trim().isNotEmpty || feeling != null) ? emojiHits(query, feeling) : null;
      Widget title(String t) => Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[1], 0, Tokens.space[0]),
        child: Text(t, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
      );
      const grid = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8);
      return LiquidGlass(
        key: const Key('react-panel'),
        radius: Tokens.radius[3],
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[1]),
          child: SizedBox(
            width: cell * 8,
            height: cell * (all ? 7.5 : 6.5),
            child: Column(
              children: [
                if (all)
                  Padding(
                    padding: EdgeInsets.only(bottom: Tokens.space[1]),
                    child: EmojiSearchBar(feeling: feeling, onQuery: (v) => setState(() => query = v), onFeeling: (f) => setState(() => feeling = f)),
                  ),
                Expanded(
                  // Telegram: the open panel scrolls; character reactions, then every emoji.
                  child: CustomScrollView(
                    key: const Key('react-scroll'),
                    slivers: hits != null
                        ? [
                            if (hits.isEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.all(Tokens.space[3]),
                                  child: Text(
                                    L.of(context).emojiNone,
                                    textAlign: TextAlign.center,
                                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                  ),
                                ),
                              ),
                            SliverGrid(gridDelegate: grid, delegate: SliverChildListDelegate([for (final e in hits) emoji(e)])),
                          ]
                        : [
                            SliverToBoxAdapter(
                              child: Wrap(
                                children: [
                                  for (final e in [...widget.reactions, ...more]) emoji(e),
                                ],
                              ),
                            ),
                            if (widget.characters) ...[
                              SliverToBoxAdapter(child: title(L.of(context).charReactionsTitle)),
                              SliverToBoxAdapter(child: Wrap(children: [for (final e in charReactions) emoji(e)])),
                            ],
                            if (all) ...[
                              SliverToBoxAdapter(child: title(L.of(context).reactAllEmoji)),
                              for (final list in _groupEmoji)
                                SliverGrid(
                                  gridDelegate: grid,
                                  delegate: SliverChildBuilderDelegate((_, i) => emoji(list[i]), childCount: list.length),
                                ),
                            ],
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return LiquidGlass(
      radius: Tokens.capsule,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[0], vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in widget.reactions.take(5)) emoji(e, size: 28),
            if (more.isNotEmpty || widget.characters)
              GestureDetector(
                key: const Key('react-more'),
                onTap: () => setState(() => open = true),
                child: Container(
                  width: _MessageMenu.emoji,
                  height: _MessageMenu.emoji,
                  margin: EdgeInsets.symmetric(horizontal: Tokens.space[0]),
                  decoration: BoxDecoration(color: p.label.withValues(alpha: 0.08), shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.chevron_down, size: Tokens.listIconSmall, color: p.secondaryLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget menu(Palette p) {
    final items = widget.items;
    return SizedBox(
      width: _MessageMenu.width,
      child: LiquidGlass(
        radius: Tokens.radius[3],
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.header != null) ...[
                GestureDetector(
                  key: const Key('menu-header'),
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.headerId == null ? null : () => Navigator.of(context).pop(widget.headerId),
                  child: SizedBox(
                    height: _MessageMenu.row,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.checkmark_alt_circle, size: 18, color: widget.headerId == null ? p.secondaryLabel : p.label),
                          SizedBox(width: Tokens.space[1]),
                          Expanded(
                            child: Text(
                              widget.header!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.preview.style.copyWith(color: widget.headerId == null ? p.secondaryLabel : p.label),
                            ),
                          ),
                          if (widget.headerTrailing != null) ...[SizedBox(width: Tokens.space[1]), widget.headerTrailing!],
                          if (widget.headerId != null) ...[
                            SizedBox(width: Tokens.space[0]),
                            Icon(CupertinoIcons.chevron_right, size: 14, color: p.secondaryLabel),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Container(height: Tokens.space[1], color: p.label.withValues(alpha: 0.06)),
              ],
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0 && items[i].group) Container(height: Tokens.space[1], color: p.label.withValues(alpha: 0.06)),
                _Row(item: items[i], iconFirst: widget.iconsFirst),
              ],
              if (widget.footer != null) ...[
                Container(height: Tokens.space[1], color: p.label.withValues(alpha: 0.06)),
                Padding(
                  key: const Key('menu-footer'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1] + 2, Tokens.space[3], Tokens.space[0]),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(CupertinoIcons.hand_raised_fill, size: 14, color: p.label.withValues(alpha: 0.7)),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      Expanded(
                        child: Text(widget.footer!, style: Tokens.caption.style.copyWith(color: p.label.withValues(alpha: 0.7))),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final anim = widget.anim;
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    final side = widget.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('menu-dismiss'),
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * anim.value, sigmaY: 14 * anim.value),
                child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.18 * anim.value)),
              ),
            ),
          ),
          // A tap anywhere outside the menu rows closes it (the scroll view
          // below would otherwise swallow taps on the blurred background).
          GestureDetector(
            key: const Key('menu-outside'),
            behavior: HitTestBehavior.translucent,
            onTap: () => Navigator.pop(context),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[3]),
                  child: Opacity(
                    opacity: anim.value.clamp(0, 1),
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * curved.value,
                      alignment: widget.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: side,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.reactions.isNotEmpty) capsule(p),
          SizedBox(height: Tokens.space[1]),
          IgnorePointer(
            ignoring: !widget.bubbleTouch && !widget.selectable,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width - Tokens.space[2] * 2),
              child: widget.selectable ? selectableBubble(widget.bubble) : widget.bubble,
            ),
          ),
          if (!open) ...[SizedBox(height: Tokens.space[1]), menu(p)],
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({required this.item, this.iconFirst = false});
  final MenuItem item;
  final bool iconFirst;
  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final it = widget.item;
    final c = it.danger ? Palette.tileRed : p.label;
    return GestureDetector(
      key: Key('menu-${it.id}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: () => Navigator.pop(context, it.id),
      child: Container(
        height: _MessageMenu.row,
        color: down ? p.label.withValues(alpha: 0.08) : const Color(0x00000000),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            if (widget.iconFirst) ...[Icon(it.icon, size: Tokens.listIcon, color: c), SizedBox(width: Tokens.space[3])],
            Expanded(
              child: Text(
                it.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.body.style.copyWith(color: c),
              ),
            ),
            if (!widget.iconFirst) ...[SizedBox(width: Tokens.space[2]), Icon(it.icon, size: Tokens.listIcon, color: c)],
          ],
        ),
      ),
    );
  }
}
