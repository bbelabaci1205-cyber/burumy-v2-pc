// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이모지 찾기 pieces (Telegram tips 366 + 378): the search capsule with the
// feeling chips (👍 ❤️ 😂 🎉 …), the emoji pick sheet used by 이모지 상태
// and sticker-set emoji, and the hold-to-zoom card (복사 / 보내기 / 상태로).
// Sizes follow the sticker panel's own search capsule (36 tall, 18 radius,
// 18 pt glyphs) and the rulebook (17/15/13 type, 8-pt spacing).
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/emoji_words.dart';
import '../design/tokens.dart';
import 'common.dart';
import '../l10n/app_localizations.dart';
import '../stickers/sticker_words.dart' show emojiGroups;
import 'glass.dart';

TextStyle emojiStyle(double size) => TextStyle(fontSize: size, fontFamilyFallback: Tokens.emojiFallback);

/// '이모지 검색' capsule; until typing starts, the feeling chips sit inside
/// it (Telegram). [feeling] = the chosen chip's emoji, or null.
class EmojiSearchBar extends StatefulWidget {
  const EmojiSearchBar({super.key, required this.onQuery, required this.onFeeling, this.feeling, this.autofocus = false});
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onFeeling;
  final String? feeling;
  final bool autofocus;

  @override
  State<EmojiSearchBar> createState() => _EmojiSearchBarState();
}

class _EmojiSearchBarState extends State<EmojiSearchBar> {
  final c = TextEditingController();
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    c.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final typing = focus.hasFocus || c.text.isNotEmpty;
    return Container(
      key: const Key('emoji-search'),
      height: 36,
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
                    key: const Key('emoji-search-field'),
                    controller: c,
                    focusNode: focus,
                    autofocus: widget.autofocus,
                    decoration: null,
                    placeholder: typing ? l.emojiSearchHint : l.searchChats,
                    placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                    style: Tokens.body.style.copyWith(color: p.label),
                    padding: EdgeInsets.only(left: Tokens.space[0] + 2),
                    onChanged: (v) {
                      setState(() {});
                      widget.onFeeling(null);
                      widget.onQuery(v);
                    },
                    suffix: typing
                        ? CupertinoButton(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                            minimumSize: Size.zero,
                            onPressed: () {
                              c.clear();
                              focus.unfocus();
                              widget.onQuery('');
                              setState(() {});
                            },
                            child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: p.secondaryLabel),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (!typing)
            Positioned(
              left: 96,
              right: Tokens.space[1],
              top: 0,
              bottom: 0,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final (e, _) in emojiFeelings)
                    GestureDetector(
                      key: Key('emoji-feel-$e'),
                      onTap: () => widget.onFeeling(widget.feeling == e ? null : e),
                      child: SizedBox(
                        width: 36,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: widget.feeling == e ? p.secondaryLabel.withValues(alpha: 0.2) : null, shape: BoxShape.circle),
                            // Not chosen: a little faded, like Telegram's grey glyphs.
                            child: Opacity(
                              opacity: widget.feeling == e ? 1 : 0.55,
                              child: Text(e, style: emojiStyle(18)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The emoji a search or a feeling chip finds.
List<String> emojiHits(String query, String? feeling) {
  if (feeling != null)
    return [
      for (final (e, all) in emojiFeelings)
        if (e == feeling) ...all.characters,
    ];
  return searchEmoji(query);
}

/// Hold an emoji (tip 378): it grows in a glass card with 복사, 보내기 and
/// (when [onStatus] is given) 상태로 설정. Returns nothing; the buttons act.
Future<void> showEmojiZoom(BuildContext context, String emoji, {VoidCallback? onSend, VoidCallback? onStatus}) {
  return showCupertinoModalPopup<void>(
    context: context,
    barrierColor: const Color(0x33000000),
    builder: (c) {
      final p = paletteOf(c);
      final l = L.of(c);
      Widget button(String key, IconData icon, String label, VoidCallback onTap) => GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.pop(c);
          onTap();
        },
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Container(
                width: Tokens.closeButton,
                height: Tokens.closeButton,
                decoration: BoxDecoration(color: p.label.withValues(alpha: 0.08), shape: BoxShape.circle),
                child: Icon(icon, size: Tokens.listIcon, color: p.label),
              ),
              SizedBox(height: Tokens.space[0]),
              Text(label, style: Tokens.caption.style.copyWith(color: p.label)),
            ],
          ),
        ),
      );
      final words = (emojiWords[emoji] ?? '').split(' ').where((w) => RegExp(r'[\uAC00-\uD7A3]').hasMatch(w)).take(3).join(' · ');
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: SizedBox(
            width: 300,
            child: LiquidGlass(
              key: const Key('emoji-zoom'),
              radius: 30,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], Tokens.space[3]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: emojiStyle(120)),
                    if (words.isNotEmpty) ...[SizedBox(height: Tokens.space[1]), Text(words, style: Tokens.preview.style.copyWith(color: p.secondaryLabel))],
                    SizedBox(height: Tokens.space[3]),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        button('emoji-zoom-copy', CupertinoIcons.doc_on_doc, l.copy, () => Clipboard.setData(ClipboardData(text: emoji))),
                        if (onSend != null) button('emoji-zoom-send', CupertinoIcons.arrow_up, l.send, onSend),
                        if (onStatus != null) button('emoji-zoom-status', CupertinoIcons.person_crop_circle_badge_checkmark, l.emojiSetStatus, onStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// A sheet to pick one emoji (search, feelings, every group). Returns it.
Future<String?> pickEmoji(BuildContext context, {String? title}) => showCupertinoModalPopup<String>(
  context: context,
  builder: (c) => _EmojiPickSheet(title: title),
);

class _EmojiPickSheet extends StatefulWidget {
  const _EmojiPickSheet({this.title});
  final String? title;
  @override
  State<_EmojiPickSheet> createState() => _EmojiPickSheetState();
}

class _EmojiPickSheetState extends State<_EmojiPickSheet> {
  String query = '';
  String? feeling;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final h = MediaQuery.sizeOf(context).height * 0.62;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final hits = query.trim().isEmpty && feeling == null ? null : emojiHits(query, feeling);
    Widget cell(String e) => GestureDetector(
      key: Key('pick-emoji-$e'),
      onTap: () => Navigator.pop(context, e),
      child: Center(child: Text(e, style: emojiStyle(30))),
    );
    const grid = SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8);
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: SizedBox(
        height: h,
        child: LiquidGlass(
          key: const Key('emoji-pick-sheet'),
          radius: 30,
          child: ColoredBox(
            color: p.card.withValues(alpha: p.dark ? 0.6 : 0.7),
            child: Column(
              children: [
                SizedBox(
                  height: Tokens.sheetHeader,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('emoji-pick-close'),
                          onTap: () => Navigator.pop(context),
                          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                        ),
                      ),
                      Text(
                        widget.title ?? l.emojiPickTitle,
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                  child: EmojiSearchBar(feeling: feeling, onQuery: (v) => setState(() => query = v), onFeeling: (f) => setState(() => feeling = f)),
                ),
                Expanded(
                  child: hits != null
                      ? (hits.isEmpty
                            ? Center(
                                child: Text(l.emojiNone, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                              )
                            : GridView(
                                key: const Key('emoji-pick-hits'),
                                padding: EdgeInsets.all(Tokens.space[1]),
                                gridDelegate: grid,
                                children: [for (final e in hits) cell(e)],
                              ))
                      : CustomScrollView(
                          slivers: [
                            for (final (_, _, all) in emojiGroups)
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[0]),
                                sliver: SliverGrid(gridDelegate: grid, delegate: SliverChildListDelegate([for (final e in all.characters) cell(e)])),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
