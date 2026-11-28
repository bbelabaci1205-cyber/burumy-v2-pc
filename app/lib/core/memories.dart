// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 1년 전 오늘 (Snapchat Memories' flashback, our way; 4대 메신저 보드
// '우리식으로', Eric 2026-11-28). On the day a photo or video was saved to
// 저장한 메시지 one or more years ago, my phone picks it out and the
// 저장한 메시지 row says so. Snapchat keeps Memories on its servers and
// picks there; here the pictures stay where they already are (my own
// encrypted saved chat) and the picking happens on this phone. Nothing new
// is uploaded or kept anywhere.
import 'app_state.dart';
import 'backend.dart';

/// One day's memories: the pictures saved on this day [years] ago.
class MemoryDay {
  const MemoryDay(this.years, this.msgs);
  final int years;

  /// Oldest first.
  final List<Msg> msgs;
}

class Memories {
  const Memories._();

  /// Settings > 대화 > 1년 전 오늘 (on by default).
  static const pref = 'memories_on';

  /// The day ('YYYY-MM-DD') whose memories I already opened.
  static const seenKey = 'memories_seen';

  static bool shown(AppState s) => s.on(pref, fallback: true);

  static bool isPicture(Msg m) => (m.kind == 'image' || m.kind == 'video') && !m.viewOnce;

  /// Same day of the year: 29 February counts on 28 February in other years.
  static bool sameDay(DateTime a, DateTime today) {
    if (a.month == today.month && a.day == today.day) return true;
    final leap = DateTime(today.year, 2, 29).month == 2;
    return !leap && a.month == 2 && a.day == 29 && today.month == 2 && today.day == 28;
  }

  /// Pictures from this day in earlier years, newest year first.
  static List<MemoryDay> pick(List<Msg> saved, DateTime today) {
    final byYear = <int, List<Msg>>{};
    for (final m in saved) {
      if (!isPicture(m) || m.time.year >= today.year || !sameDay(m.time, today)) continue;
      byYear.putIfAbsent(today.year - m.time.year, () => []).add(m);
    }
    final years = byYear.keys.toList()..sort();
    return [for (final y in years) MemoryDay(y, byYear[y]!..sort((a, b) => a.time.compareTo(b.time)))];
  }

  static String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Today's memories (kept in [AppState.memories] by [check]).
  static Future<void> check(AppState s) async {
    final room = s.savedRoomId;
    if (!shown(s) || room == null) {
      s.memories = const [];
      return;
    }
    try {
      s.memories = pick(await s.backend.cachedMessages(room), s.backend.clock);
    } catch (_) {
      s.memories = const [];
    }
  }

  /// There are memories today that I haven't opened yet.
  static bool waiting(AppState s) => shown(s) && s.memories.isNotEmpty && s.pref(seenKey, '') != dayKey(s.backend.clock);

  static Future<void> markSeen(AppState s) => s.setPref(seenKey, dayKey(s.backend.clock));

  static int count(List<MemoryDay> days) => days.fold(0, (a, d) => a + d.msgs.length);
}
