// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 큰 이모지 (Burumy v1): a lone emoji sent on its own moves, like
// Telegram's animated emoji. Pictures: Noto Animated Emoji by Google,
// CC BY 4.0 (see REFERENCES.md), 40 of the most used ones; any other emoji
// stays the still big one.
import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// File names (code points in hex, joined by '_') we have pictures for.
const movingEmojiNames = <String>{'1f389', '1f440', '1f44d', '1f44e', '1f44f', '1f480', '1f494', '1f4af', '1f525', '1f600', '1f601', '1f602', '1f605', '1f606', '1f609', '1f60a', '1f60d', '1f60e', '1f618', '1f621', '1f622', '1f62d', '1f62e', '1f631', '1f634', '1f642', '1f643', '1f644', '1f64f', '1f914', '1f923', '1f929', '1f92d', '1f92f', '1f970', '1f971', '1f973', '1f97a', '2728', '2764_fe0f'};

/// The picture's file name for [text] when it is exactly one emoji we have.
String? movingEmojiName(String text) {
  final t = text.trim();
  if (t.isEmpty || t.characters.length != 1) return null;
  final full = t.runes.map((r) => r.toRadixString(16)).join('_');
  if (movingEmojiNames.contains(full)) return full;
  // The same emoji written without the picture-style mark (U+FE0F), or with it.
  final bare = t.runes.where((r) => r != 0xFE0F).map((r) => r.toRadixString(16)).join('_');
  if (movingEmojiNames.contains(bare)) return bare;
  if (movingEmojiNames.contains('${bare}_fe0f')) return '${bare}_fe0f';
  return null;
}

/// A lone emoji that moves; null when we have no picture for it.
class MovingEmoji extends StatelessWidget {
  const MovingEmoji(this.name, {super.key, this.size = 112});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    // 동작 줄이기 (iPhone "Reduce Motion") or power saving: the first frame only.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return SizedBox.square(
      key: Key('moving-emoji-$name'),
      dimension: size,
      child: Lottie.asset(
        'assets/animated_emoji/$name.json',
        width: size,
        height: size,
        animate: !still && TickerMode.valuesOf(context).enabled,
        repeat: true,
        frameRate: FrameRate.max,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}
