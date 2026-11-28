// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 1:1 read time (Telegram tip 421): "읽음 · 오늘 오후 10:38" on my message.
//
// The server only keeps the other person's newest read receipt, so this
// phone writes down each new one it sees (read up to, when) in a small
// local list (pref "readlog:<room>"). A message's read time is the first
// receipt that covers it. Only people who both share read ticks see any
// (the engine returns nothing otherwise), and like Telegram the time is
// kept for 7 days.
import 'dart:convert';

class ReadTimes {
  const ReadTimes._();

  static const keep = Duration(days: 7);
  static const maxEntries = 200;

  static List<(int, int)> parse(String raw) {
    try {
      final v = jsonDecode(raw);
      if (v is! List) return [];
      return [
        for (final e in v)
          if (e is List && e.length == 2 && e[0] is int && e[1] is int) (e[0] as int, e[1] as int),
      ];
    } catch (_) {
      return [];
    }
  }

  /// The list with a newly seen receipt, or null when nothing changed.
  static String? add(String raw, DateTime until, DateTime at, DateTime now) {
    final list = parse(raw);
    final u = until.millisecondsSinceEpoch, a = at.millisecondsSinceEpoch;
    if (list.isNotEmpty && list.last.$1 >= u) return null;
    final cut = now.subtract(keep).millisecondsSinceEpoch;
    final kept = [
      for (final e in list)
        if (e.$2 >= cut) e,
      (u, a),
    ];
    final out = kept.length > maxEntries ? kept.sublist(kept.length - maxEntries) : kept;
    return jsonEncode([
      for (final e in out) [e.$1, e.$2],
    ]);
  }

  /// When my message sent at [sent] was read, or null (not read, unknown or
  /// older than 7 days).
  static DateTime? of(String raw, DateTime sent, DateTime now) {
    final s = sent.millisecondsSinceEpoch;
    for (final e in parse(raw)) {
      if (e.$1 >= s) {
        final at = DateTime.fromMillisecondsSinceEpoch(e.$2);
        return now.difference(at) > keep ? null : at;
      }
    }
    return null;
  }
}
