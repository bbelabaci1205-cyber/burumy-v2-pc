// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Long press on a message (iOS / Telegram style): the page blurs, the
// message lifts in place, a glass reaction capsule sits above it and an
// iOS menu with icons below it.
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
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
}) {
  return paneNav(context).push<String>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (c, a, _) => _MessageMenu(anim: a, bubble: bubble, mine: mine, reactions: reactions, more: more, items: items, iconsFirst: iconsFirst),
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
  });

  /// Icon before the words (the chat list menu, v1 layout).
  final bool iconsFirst;
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

  Widget emoji(String e, {double size = 26}) => GestureDetector(
    key: Key('react-$e'),
    behavior: HitTestBehavior.opaque,
    onTap: () => Navigator.pop(context, 'react:$e'),
    child: SizedBox(
      width: _MessageMenu.emoji + 8,
      height: _MessageMenu.emoji + 8,
      child: Center(
        child: Text(
          e,
          style: TextStyle(fontSize: size, height: 1, fontFamilyFallback: Tokens.emojiFallback),
        ),
      ),
    ),
  );

  Widget capsule(Palette p) {
    final more = widget.more.where((e) => !widget.reactions.contains(e)).toList();
    if (open) {
      return LiquidGlass(
        key: const Key('react-panel'),
        radius: Tokens.radius[3],
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[1]),
          child: SizedBox(
            width: (_MessageMenu.emoji + 8) * 8,
            child: Wrap(
              children: [
                for (final e in [...widget.reactions, ...more]) emoji(e),
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
            if (more.isNotEmpty)
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
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0 && items[i].group) Container(height: Tokens.space[1], color: p.label.withValues(alpha: 0.06)),
                _Row(item: items[i], iconFirst: widget.iconsFirst),
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
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width - Tokens.space[2] * 2),
              child: widget.bubble,
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
