// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Admin tools that run on an admin's phone (the server can't read messages):
// auto-moderation, the local admin log, room stats and the room level.
import 'dart:convert';

import 'backend.dart';
import 'link_check.dart';

/// Why auto-moderation removes a message.
enum ModWhy { word, link, flood }

/// Words from the local banned-word list (comma list kept on this phone).
List<String> bannedWordsOf(Map<String, String> prefs, String roomId) =>
    (prefs['automod_words:$roomId'] ?? '').split('\n').map((w) => w.trim()).where((w) => w.isNotEmpty).toList();

/// The messages auto-moderation would remove, oldest first. Never my own,
/// never an admin's, never anything already gone.
List<(Msg, ModWhy)> violations(
  List<Msg> msgs, {
  required List<String> words,
  required bool newLinks,
  required bool flood,
  required Map<String, int> firstSeen,
  required Set<String> admins,
  required DateTime now,
}) {
  final out = <(Msg, ModWhy)>[];
  final lowered = [for (final w in words) w.toLowerCase()];
  final recent = <String, List<DateTime>>{};
  for (final m in msgs) {
    if (m.mine || admins.contains(m.sender) || m.body == null) continue;
    if (!const ['text', 'image', 'video', 'file', 'audio', 'sticker'].contains(m.kind)) continue;
    final text = '${m.body} ${m.caption ?? ''}'.toLowerCase();
    if (m.kind == 'text' || (m.caption ?? '').isNotEmpty) {
      if (lowered.any((w) => _hasWord(text, w))) {
        out.add((m, ModWhy.word));
        continue;
      }
      final seen = firstSeen[m.sender];
      final isNew = seen == null || now.millisecondsSinceEpoch - seen < const Duration(hours: 24).inMilliseconds;
      if (newLinks && isNew && _hasLink(text)) {
        out.add((m, ModWhy.link));
        continue;
      }
    }
    if (flood) {
      final times = recent.putIfAbsent(m.sender, () => [])..add(m.time);
      times.removeWhere((t) => m.time.difference(t) > const Duration(seconds: 10));
      if (times.length > 5) out.add((m, ModWhy.flood));
    }
  }
  return out;
}

bool _hasWord(String text, String w) {
  if (w.isEmpty) return false;
  if (text.contains(w)) return true;
  // People hide words with spaces or dots in between ("광.고", "a d s").
  final squeezed = text.replaceAll(RegExp(r'[\s.\-_*·,]+'), '');
  return squeezed.contains(w.replaceAll(RegExp(r'[\s.\-_*·,]+'), ''));
}

/// A web address (or a disguised one) in the text.
bool hasLinkText(String text) => _hasLink(text.toLowerCase());

bool _hasLink(String text) =>
    RegExp(r'(https?://|www\.|[a-z0-9-]+\.(com|net|org|io|me|kr|co|ly|gg|link|xyz|app|site|shop)\b)').hasMatch(text) || hasSuspiciousLink(text);

/// One admin action done on this phone.
class ModEntry {
  const ModEntry(this.time, this.kind, this.name, [this.detail = '']);
  final DateTime time;

  /// removed, banned, unbanned, setting
  final String kind;
  final String name;
  final String detail;

  Map<String, Object> toJson() => {'t': time.millisecondsSinceEpoch, 'k': kind, 'n': name, 'd': detail};
  static ModEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final t = j['t'], k = j['k'], n = j['n'], d = j['d'];
    if (t is! int || k is! String || n is! String) return null;
    return ModEntry(DateTime.fromMillisecondsSinceEpoch(t), k, n, d is String ? d : '');
  }
}

/// The local admin log, newest first.
List<ModEntry> modLogOf(Map<String, String> prefs, String roomId) {
  try {
    final list = jsonDecode(prefs['mod_log:$roomId'] ?? '[]');
    if (list is! List) return const [];
    return list.map(ModEntry.fromJson).whereType<ModEntry>().toList();
  } catch (_) {
    return const [];
  }
}

/// Adds one entry and keeps the newest 200.
String withLogEntry(Map<String, String> prefs, String roomId, ModEntry e) {
  final list = [e, ...modLogOf(prefs, roomId)].take(200).toList();
  return jsonEncode([for (final x in list) x.toJson()]);
}

/// Numbers for the stats page, all worked out from the chat on this phone.
class RoomStats {
  const RoomStats({required this.members, required this.messages30, required this.active30, required this.hours, required this.days});
  final int members;
  final int messages30;
  final int active30;

  /// Messages by hour of day (24).
  final List<int> hours;

  /// Messages per day for the last 30 days, oldest first.
  final List<int> days;

  double get perDay => messages30 / 30;
  int? get busiest {
    var best = -1, at = -1;
    for (var h = 0; h < 24; h++) {
      if (hours[h] > best) (best, at) = (hours[h], h);
    }
    return best <= 0 ? null : at;
  }

  static RoomStats of(List<Msg> msgs, int members, DateTime now) {
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    final hours = List.filled(24, 0), days = List.filled(30, 0);
    final people = <String>{};
    var n = 0;
    for (final m in msgs) {
      if (const ['call', 'opened', 'locked', 'deleted'].contains(m.kind)) continue;
      final t = m.time.toLocal();
      if (t.isBefore(start) || t.isAfter(now.add(const Duration(minutes: 5)))) continue;
      n++;
      people.add(m.sender);
      hours[t.hour]++;
      final d = DateTime(t.year, t.month, t.day).difference(start).inDays;
      if (d >= 0 && d < 30) days[d]++;
    }
    return RoomStats(members: members, messages30: n, active30: people.length, hours: hours, days: days);
  }
}

/// Community levels, stage A (members, people who wrote in 4 weeks, days).
const levelSteps = [(3, 2, 0), (10, 3, 3), (30, 8, 7), (100, 20, 14), (300, 50, 30)];

int levelOf(int members, int active, int days) {
  var lv = 0;
  for (final (m, a, d) in levelSteps) {
    if (members >= m && active >= a && days >= d) {
      lv++;
    } else {
      break;
    }
  }
  return lv;
}
