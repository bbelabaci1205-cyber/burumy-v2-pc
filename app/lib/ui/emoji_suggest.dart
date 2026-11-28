// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 입력창 추천 줄 (Telegram tips 294, 221, 366): a glass strip right above
// the composer.
//  - ':웃음' (colon + word): matching emoji; a tap swaps the shortcut.
//  - only one emoji typed (😂): matching stickers (Burumy packs and my
//    sticker sets); a tap sends the sticker instead of the emoji.
//  - a word with an exact emoji (축하 -> 🎉 👏): a tap adds the emoji.
// All on the phone. Settings > 스티커와 이모지 can turn the last two off.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/emoji_words.dart';
import '../core/sticker_sets.dart';
import '../design/tokens.dart';
import '../stickers/catalog.dart';
import '../stickers/sticker_words.dart';
import 'emoji_pick.dart';
import 'glass.dart';
import 'sticker_panel.dart' show shownPacks;
import 'sticker_sets_ui.dart' show SetItemView;

/// What the strip offers for the composer's text right now.
sealed class Suggest {
  const Suggest();
}

/// Emoji that replace text[start, end) (shortcut) or go after it (word).
class EmojiSuggest extends Suggest {
  const EmojiSuggest(this.emoji, this.start, this.end, {this.replace = true});
  final List<String> emoji;
  final int start, end;
  final bool replace;
}

class StickerSuggest extends Suggest {
  const StickerSuggest(this.items);
  final List<SetItem> items;
}

/// Works out the strip for [text] with the cursor at [cursor].
Suggest? suggestFor(AppState s, String text, int cursor) {
  if (text.isEmpty) return null;
  final at = cursor < 0 ? text.length : cursor;
  final sc = colonShortcut(text, at);
  if (sc != null) {
    final hits = searchEmoji(sc.word, max: 24);
    return hits.isEmpty ? null : EmojiSuggest(hits, sc.start, at);
  }
  if (isSingleEmoji(text) && s.on('suggest_stickers', fallback: true)) {
    final e = text.trim();
    final built = stickersForEmoji(e, [for (final k in shownPacks(s)) ...k.items]);
    final mine = [
      for (final set in StickerSets.all(s))
        if (set.kind == 'sticker')
          for (final i in set.items)
            if (i.emoji == e) i,
    ];
    final items = [...mine, for (final id in built) SetItem(id: id)];
    return items.isEmpty ? null : StickerSuggest(items.take(30).toList());
  }
  if (s.on('suggest_emoji', fallback: true) && at == text.length) {
    final hits = emojiForLastWord(text);
    if (hits.isNotEmpty) return EmojiSuggest(hits, text.length, text.length, replace: false);
  }
  return null;
}

class SuggestStrip extends StatelessWidget {
  const SuggestStrip({super.key, required this.suggest, required this.onEmoji, required this.onSticker});
  final Suggest suggest;

  /// The emoji picked (the caller puts it in the composer).
  final ValueChanged<String> onEmoji;
  final ValueChanged<SetItem> onSticker;

  @override
  Widget build(BuildContext context) {
    final stickers = suggest is StickerSuggest;
    final h = stickers ? 76.0 : 48.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[1]),
      child: SizedBox(
        height: h,
        child: LiquidGlass(
          key: Key(stickers ? 'suggest-stickers' : 'suggest-emoji'),
          radius: stickers ? Tokens.radius[3] : Tokens.capsule,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
            children: switch (suggest) {
              EmojiSuggest(:final emoji) => [
                for (final e in emoji)
                  GestureDetector(
                    key: Key('suggest-e-$e'),
                    onTap: () => onEmoji(e),
                    child: SizedBox(
                      width: 44,
                      child: Center(child: Text(e, style: emojiStyle(28))),
                    ),
                  ),
              ],
              StickerSuggest(:final items) => [
                for (final (i, it) in items.indexed)
                  GestureDetector(
                    key: Key('suggest-s-$i'),
                    onTap: () => onSticker(it),
                    child: Padding(
                      padding: EdgeInsets.all(Tokens.space[0]),
                      child: it.png == null && it.id.isNotEmpty && StickerPack.moving(it.id)
                          ? Image.asset(stickerAsset(it.id)!, width: 64, height: 64)
                          : SetItemView(it, size: 64),
                    ),
                  ),
              ],
            },
          ),
        ),
      ),
    );
  }
}
