// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sticker panel under the composer: recently sent first, then one tab per
// Burumy character that is switched on (Settings > Stickers and emoji), a
// grid of that character's stickers. Tap sends.
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../stickers/catalog.dart';
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

class StickerPanel extends StatefulWidget {
  const StickerPanel({super.key, required this.onPick, this.phrases = const [], this.onPhrase});
  final void Function(String id) onPick;

  /// Quick replies (Settings > Chats); tapping one puts it in the composer.
  final List<String> phrases;
  final void Function(String text)? onPhrase;
  @override
  State<StickerPanel> createState() => _StickerPanelState();
}

class _StickerPanelState extends State<StickerPanel> {
  int tab = 0;

  void pick(AppState s, String id) {
    final recent = [id, ...recentStickers(s).where((x) => x != id)].take(16).join(',');
    s.setPref(recentStickersKey, recent);
    widget.onPick(id);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final recent = recentStickers(s);
    final packs = shownPacks(s);
    // Tabs: recent (when there is any), then the packs.
    final tabs = <(String, List<String>, Widget)>[
      if (widget.phrases.isNotEmpty && widget.onPhrase != null)
        ('phrases', widget.phrases, Icon(CupertinoIcons.text_bubble, size: Tokens.listIcon, color: p.secondaryLabel)),
      if (recent.isNotEmpty) ('recent', recent, Icon(CupertinoIcons.clock, size: Tokens.listIcon, color: p.secondaryLabel)),
      for (final k in packs) (k.id, k.items, Image.asset(k.asset(k.items.first))),
    ];
    if (tabs.isEmpty) return Container(key: const Key('sticker-panel'), height: 300, color: p.card);
    final at = tab.clamp(0, tabs.length - 1);
    final items = tabs[at].$2;
    return Container(
      key: const Key('sticker-panel'),
      height: 300,
      color: p.card,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
              children: [
                for (var i = 0; i < tabs.length; i++)
                  GestureDetector(
                    key: Key('sticker-tab-${tabs[i].$1}'),
                    onTap: () => setState(() => tab = i),
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: EdgeInsets.all(Tokens.space[0]),
                      padding: EdgeInsets.all(Tokens.space[0]),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == at ? p.secondaryLabel.withValues(alpha: 0.18) : null,
                        borderRadius: BorderRadius.circular(Tokens.radius[1]),
                      ),
                      child: tabs[i].$3,
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: p.separator),
          Expanded(
            child: tabs[at].$1 == 'phrases'
                ? ListView(
                    padding: EdgeInsets.all(Tokens.space[1]),
                    children: [
                      for (var i = 0; i < items.length; i++)
                        GestureDetector(
                          key: Key('phrase-$i'),
                          onTap: () => widget.onPhrase!(items[i]),
                          child: Container(
                            margin: EdgeInsets.only(bottom: Tokens.space[1]),
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                            child: Text(items[i], style: Tokens.preview.style.copyWith(color: p.label)),
                          ),
                        ),
                    ],
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(Tokens.space[1]),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: Tokens.space[0],
                      crossAxisSpacing: Tokens.space[0],
                    ),
                    itemCount: items.length,
                    itemBuilder: (c, i) => GestureDetector(
                      key: Key('sticker-${items[i]}'),
                      onTap: () => pick(s, items[i]),
                      child: Padding(padding: EdgeInsets.all(Tokens.space[0]), child: Image.asset(stickerAsset(items[i])!)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
