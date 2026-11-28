// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 나만 고정 (Telegram tip 276): in a 1:1 chat a message can be pinned for
// me only. It is kept on this phone (pref "mypins:<room>": id -> until
// in ms, 0 = until unpinned) and never sent anywhere; the other person
// sees nothing.
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';

class MyPins {
  MyPins._();

  static String key(String roomId) => 'mypins:$roomId';

  static Map<String, int> read(AppState s, String roomId) {
    try {
      final j = jsonDecode(s.pref(key(roomId), '{}')) as Map<String, dynamic>;
      return {for (final e in j.entries) e.key: (e.value as num).toInt()};
    } catch (_) {
      return {};
    }
  }

  /// Still pinned now, in the order they were pinned.
  static List<String> live(Map<String, int> pins, DateTime now) => [
    for (final e in pins.entries)
      if (e.value == 0 || e.value > now.millisecondsSinceEpoch) e.key,
  ];

  static Future<void> pin(AppState s, String roomId, String id, {DateTime? until}) {
    final all = read(s, roomId)
      ..remove(id)
      ..[id] = until?.millisecondsSinceEpoch ?? 0;
    // Run out ones are dropped while writing.
    final now = s.backend.clock.millisecondsSinceEpoch;
    all.removeWhere((_, v) => v != 0 && v <= now);
    return s.setPref(key(roomId), jsonEncode(all));
  }

  static Future<void> unpin(AppState s, String roomId, String id) {
    final all = read(s, roomId)..remove(id);
    return s.setPref(key(roomId), all.isEmpty ? '' : jsonEncode(all));
  }

  /// Shared pins and mine together, oldest message first (Telegram order:
  /// the bar starts at the newest). Unknown messages keep their place.
  static List<String> merge(List<String> shared, List<String> mine, List<Msg> msgs) {
    if (mine.isEmpty) return shared;
    final at = {for (final m in msgs) m.id: m.time};
    final all = [...shared, ...mine.where((x) => !shared.contains(x))];
    final known = all.where(at.containsKey).toList()..sort((a, b) => at[a]!.compareTo(at[b]!));
    var k = 0;
    return [for (final id in all) at.containsKey(id) ? known[k++] : id];
  }
}
