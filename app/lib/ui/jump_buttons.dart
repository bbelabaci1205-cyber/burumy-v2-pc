// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The round buttons at the lower right of a chat (Telegram tips 249 + 320):
// ♥ = reactions to my messages I haven't seen, @ = mentions / answers to
// me I haven't seen, ↓ = back to the newest. Each tap goes to the next
// one; holding ♥ or @ marks them all as seen.
import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import 'common.dart';
import 'glass.dart';

class JumpButtons extends StatelessWidget {
  const JumpButtons({
    super.key,
    required this.reactions,
    required this.mentions,
    required this.down,
    this.onReaction,
    this.onMention,
    this.onDown,
    this.onClearReactions,
    this.onClearMentions,
  });
  final int reactions;
  final int mentions;
  final bool down;
  final VoidCallback? onReaction, onMention, onDown, onClearReactions, onClearMentions;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    Widget button(Key key, Widget icon, int count, VoidCallback? tap, VoidCallback? hold) => Padding(
      padding: EdgeInsets.only(top: Tokens.jumpGap),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          GlassCircle(key: key, size: Tokens.jumpSize, onTap: tap, onLongPress: hold, child: icon),
          // Telegram: the count sits on top of the circle.
          if (count > 0)
            Positioned(
              top: -Tokens.space[1],
              child: IgnorePointer(
                child: Container(
                  key: Key('${(key as ValueKey).value}-count'),
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[0] + 2, vertical: 1),
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(color: p.onAccent),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    final items = <Widget>[
      if (reactions > 0) button(const Key('jump-reaction'), GlassCircle.icon(context, CupertinoIcons.heart), reactions, onReaction, onClearReactions),
      if (mentions > 0)
        button(
          const Key('jump-mention'),
          Text(
            '@',
            style: TextStyle(fontSize: 22, height: 1, color: p.label, fontWeight: FontWeight.w500),
          ),
          mentions,
          onMention,
          onClearMentions,
        ),
      if (down) button(const Key('jump-down'), GlassCircle.icon(context, CupertinoIcons.chevron_down), 0, onDown, null),
    ];
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      alignment: Alignment.bottomCenter,
      child: Column(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}

/// Fills the space like [Expanded] and floats [jumps] over its lower right.
class JumpsArea extends StatelessWidget {
  const JumpsArea({super.key, required this.child, this.jumps});
  final Widget child;
  final Widget? jumps;

  @override
  Widget build(BuildContext context) => Expanded(
    child: jumps == null
        ? child
        : Stack(
            children: [
              child,
              Positioned(right: Tokens.space[2], bottom: Tokens.jumpAbove, child: jumps!),
            ],
          ),
  );
}
