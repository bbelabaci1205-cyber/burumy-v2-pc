// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sticker pack order: my order from settings; with "묶음 정렬 유연하게" the
// packs used lately come first; switched-off packs leave the panel.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/stickers/catalog.dart';
import 'package:burumy/ui/sticker_panel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('my order, recent first, off packs hidden', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final ids = [for (final p in stickerPacks) p.id];
    expect([for (final p in orderedPacks(s)) p.id], ids);
    // Last pack moved to the front by hand.
    await s.setPref('pack_order', [ids.last, ...ids.take(ids.length - 1)].join(','));
    expect(orderedPacks(s).first.id, ids.last);
    // A sticker from the second pack sent lately: that pack leads.
    await s.setPref(recentStickersKey, stickerPacks[1].items.first);
    expect(orderedPacks(s).first.id, ids[1]);
    expect(orderedPacks(s)[1].id, ids.last);
    // Dynamic order off: my order again.
    await s.setOn('pack_dynamic', false);
    expect(orderedPacks(s).first.id, ids.last);
    await s.setOn('pack_off:${ids.last}', true);
    expect(shownPacks(s).map((p) => p.id), isNot(contains(ids.last)));
  });
}
