// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Every sticker, character emoji and reaction carries the meaning its art
// was drawn for (v1 lists: stickers/emoji_map.json for the six Burumy
// characters, pack_map_hip_friends.json / pack_map_dandy_friends.json for
// the two friend packs). 2026-11-27: 31 were wrong (a04, e8, friends' e4).
import 'package:burumy/stickers/catalog.dart';
import 'package:burumy/stickers/sticker_words.dart';
import 'package:flutter_test/flutter_test.dart';

/// The v1 lists, by number, in our meaning words.
const _main = {
  's01': 'hello', 's02': 'thanks', 's03': 'love', 's04': 'good', 's05': 'lol', 's06': 'sorry', 's07': 'night', 's08': 'angry',
  's09': 'wow', 's10': 'sad', 's11': 'congrats', 's12': 'fighting', 's13': 'hmm', 's14': 'ok', 's15': 'secret', 's16': 'dizzy',
  'a01': 'hello', 'a02': 'lol', 'a03': 'love', 'a04': 'brr', 'a05': 'night', 'a06': 'wow', 'a07': 'congrats', 'a08': 'angry',
  'e1': 'smile', 'e2': 'love', 'e3': 'lol', 'e4': 'sad', 'e5': 'angry', 'e6': 'wow', 'e7': 'night', 'e8': 'wink',
  'r1': 'good', 'r2': 'love', 'r3': 'lol', 'r4': 'wow', 'r5': 'sad', 'r6': 'fire', 'r7': 'thanks', 'r8': 'congrats',
};
const _friend = {'1': 'hello', '2': 'good', '3': 'lol', '4': 'thanks', '5': 'wow', '6': 'sad'};
const _mainChars = {'buru', 'dugi', 'rumi', 'mongi', 'duru', 'burumi'};

String _want(String id) {
  final p = id.split('_');
  if (_mainChars.contains(p[0])) {
    final n = RegExp(r'^\d+$').hasMatch(p[1]) ? 's${p[1]}' : p[1];
    return _main[n]!;
  }
  return _friend[p[1].substring(p[1].length - 1)]!;
}

void main() {
  test('every picture has the meaning it was drawn for', () {
    final all = [
      for (final p in stickerPacks) ...p.items,
      for (final g in charEmojiGroups.values) ...g,
      ...charReactions,
    ];
    expect(all.length, 582);
    for (final id in all) {
      expect(stickerMeaning(id), _want(id), reason: id);
    }
  });
}
