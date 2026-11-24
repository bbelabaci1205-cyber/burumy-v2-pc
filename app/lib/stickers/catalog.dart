// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Built-in Burumy sticker packs (our own art, generated list; do not edit by hand).

class StickerPack {
  const StickerPack(this.id, this.items);
  final String id;
  final List<String> items;

  String asset(String item) => 'assets/stickers/$id/$item.webp';
}

const stickerPacks = [
  StickerPack('buru', [
    'buru_01_hello',
    'buru_02_thanks',
    'buru_03_love',
    'buru_04_good',
    'buru_05_lol',
    'buru_06_sorry',
    'buru_07_night',
    'buru_08_angry',
    'buru_09_wow',
    'buru_10_sad',
    'buru_11_congrats',
    'buru_12_fighting',
    'buru_13_hmm',
    'buru_14_ok',
    'buru_15_secret',
    'buru_16_dizzy',
  ]),
  StickerPack('dugi', [
    'dugi_01_hello',
    'dugi_02_thanks',
    'dugi_03_love',
    'dugi_04_good',
    'dugi_05_lol',
    'dugi_06_sorry',
    'dugi_07_night',
    'dugi_08_angry',
    'dugi_09_wow',
    'dugi_10_sad',
    'dugi_11_congrats',
    'dugi_12_fighting',
    'dugi_13_hmm',
    'dugi_14_ok',
    'dugi_15_secret',
    'dugi_16_dizzy',
  ]),
  StickerPack('rumi', [
    'rumi_01_hello',
    'rumi_02_thanks',
    'rumi_03_love',
    'rumi_04_good',
    'rumi_05_lol',
    'rumi_06_sorry',
    'rumi_07_night',
    'rumi_08_angry',
    'rumi_09_wow',
    'rumi_10_sad',
    'rumi_11_congrats',
    'rumi_12_fighting',
    'rumi_13_hmm',
    'rumi_14_ok',
    'rumi_15_secret',
    'rumi_16_dizzy',
  ]),
  StickerPack('mongi', [
    'mongi_01_hello',
    'mongi_02_thanks',
    'mongi_03_love',
    'mongi_04_good',
    'mongi_05_lol',
    'mongi_06_sorry',
    'mongi_07_night',
    'mongi_08_angry',
    'mongi_09_wow',
    'mongi_10_sad',
    'mongi_11_congrats',
    'mongi_12_fighting',
    'mongi_13_hmm',
    'mongi_14_ok',
    'mongi_15_secret',
    'mongi_16_dizzy',
  ]),
  StickerPack('duru', [
    'duru_01_hello',
    'duru_02_thanks',
    'duru_03_love',
    'duru_04_good',
    'duru_05_lol',
    'duru_06_sorry',
    'duru_07_night',
    'duru_08_angry',
    'duru_09_wow',
    'duru_10_sad',
    'duru_11_congrats',
    'duru_12_fighting',
    'duru_13_hmm',
    'duru_14_ok',
    'duru_15_secret',
    'duru_16_dizzy',
  ]),
  StickerPack('burumi', [
    'burumi_01_hello',
    'burumi_02_thanks',
    'burumi_03_love',
    'burumi_04_good',
    'burumi_05_lol',
    'burumi_06_sorry',
    'burumi_07_night',
    'burumi_08_angry',
    'burumi_09_wow',
    'burumi_10_sad',
    'burumi_11_congrats',
    'burumi_12_fighting',
    'burumi_13_hmm',
    'burumi_14_ok',
    'burumi_15_secret',
    'burumi_16_dizzy',
  ]),
];

/// Asset path for a sticker id like 'buru_01_hello' (null if unknown).
String? stickerAsset(String id) {
  for (final p in stickerPacks) {
    if (p.items.contains(id)) return p.asset(id);
  }
  return null;
}
