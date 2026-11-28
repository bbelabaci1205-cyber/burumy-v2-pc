// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스티커 가게 (4대 메신저 보드 '우리식으로' 9번, Eric 2026-11-28; LINE/Viber
// sticker market, our way). Burumy's own packs are free and added with one
// tap; paid artist packs wait for payments (Plus, after launch), so that
// part only says it opens later. No brand ad packs: Burumy has no ads.
// Nothing is asked from a server: the packs ship with the app and the
// add/remove choice is a setting on this phone.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/sticker_sets.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'common.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'settings_pages.dart' show packName;
import 'sticker_sets_ui.dart' show AddPill, SetPreviewPage;

String _offKey(StickerPack k) => 'pack_off:${k.id}';

int _moving(StickerPack k) => k.items.where(StickerPack.moving).length;

class StickerShopPage extends StatelessWidget {
  const StickerShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final seen = StickerSets.seen(s).entries.where((e) => !StickerSets.has(s, e.key)).toList();
    final newest = stickerPacks.last;
    void open(StickerPack k) => Navigator.of(context).push(IosPageRoute(builder: (_) => ShopPackPage(pack: k)));

    Widget packRow(StickerPack k) {
      final on = !s.on(_offKey(k));
      return IosTile(
        key: Key('shop-pack-${k.id}'),
        leadingSize: 48,
        leading: Image.asset(k.asset(k.items.first), width: 48, height: 48),
        title: Text(packName(l, k.id)),
        subtitle: Text('${l.shopFreeTag} · ${l.stickerCount(k.items.length)}'),
        trailing: AddPill(on: on, onTap: () => s.setOn(_offKey(k), on)),
        onTap: () => open(k),
      );
    }

    return SettingsScaffold(
      title: l.shopTitle,
      children: [
        // 새로 나왔어요: the newest pack, its moving stickers large.
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
          child: GestureDetector(
            key: const Key('shop-new'),
            onTap: () => open(newest),
            child: Container(
              padding: EdgeInsets.all(Tokens.space[3]),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.shopNew,
                    style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  SizedBox(
                    height: 84,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final id in [...newest.items.where(StickerPack.moving), ...newest.items].take(4))
                          Image.asset(newest.asset(id), width: 76, height: 76),
                      ],
                    ),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              packName(l, newest.id),
                              style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${l.shopBy} · ${l.shopPackInfo(newest.items.length, _moving(newest))}',
                              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                            ),
                          ],
                        ),
                      ),
                      AddPill(on: !s.on(_offKey(newest)), onTap: () => s.setOn(_offKey(newest), !s.on(_offKey(newest)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        group(context, header: l.shopFree, footer: l.shopFreeInfo, [for (final k in stickerPacks.reversed) packRow(k)]),
        group(context, header: l.shopPaid, footer: l.shopPaidInfo, [
          IosTile(
            key: const Key('shop-paid'),
            leading: Icon(CupertinoIcons.bag_fill, color: p.secondaryLabel),
            title: Text(l.shopSoon, style: TextStyle(color: p.secondaryLabel)),
          ),
        ]),
        group(context, header: l.shopSeenTitle, footer: seen.isEmpty ? l.setsSeenNone : l.setsSeenInfo, [
          for (final e in seen)
            IosTile(
              key: Key('shop-seen-${e.key.hashCode}'),
              leading: Icon(CupertinoIcons.square_stack_3d_up_fill, color: p.accent),
              title: Text(e.value.$1),
              subtitle: Text(l.setSeenCount(e.value.$2, e.value.$3)),
              trailing: const IosChevron(),
              onTap: () => Navigator.of(context).push(
                IosPageRoute(
                  builder: (_) => SetPreviewPage(file: e.key, name: e.value.$1),
                ),
              ),
            ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin + Tokens.space[3], 0, IosSection.sideMargin + Tokens.space[3], Tokens.space[4]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.lock_fill, size: 13, color: p.secondaryLabel),
              SizedBox(width: Tokens.space[0]),
              Expanded(
                child: Text(l.shopPrivacy, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One pack: the add / remove button on top (Telegram), then every sticker.
class ShopPackPage extends StatelessWidget {
  const ShopPackPage({super.key, required this.pack});
  final StickerPack pack;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final on = !s.on(_offKey(pack));
    return SettingsScaffold(
      title: packName(l, pack.id),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
          child: Text(
            '${l.shopFreeTag} · ${l.shopBy} · ${l.shopPackInfo(pack.items.length, _moving(pack))}',
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
          child: GestureDetector(
            key: const Key('shop-pack-add'),
            onTap: () => s.setOn(_offKey(pack), on),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: on ? p.card : p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(
                on ? l.shopRemove : l.shopAdd,
                style: Tokens.body.style.copyWith(color: on ? CupertinoColors.systemRed : p.onAccent, fontWeight: Tokens.semi),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(IosSection.sideMargin),
          child: Container(
            padding: EdgeInsets.all(Tokens.space[2]),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Tokens.space[1],
              crossAxisSpacing: Tokens.space[1],
              children: [for (final id in pack.items) Image.asset(pack.asset(id))],
            ),
          ),
        ),
      ],
    );
  }
}
