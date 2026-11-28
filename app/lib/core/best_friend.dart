// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 제일 친한 친구 ❤ (Snapchat's best-friend emoji, our way; 4대 메신저
// 보드 '우리식으로', Eric 2026-11-28). The friend I talk with most, BOTH
// ways, over the last two weeks gets a ❤ beside their name in my chat
// list. My phone counts the messages already on it; nothing is sent, the
// server never learns who my closest friend is, and the friend doesn't
// see it either (Snapchat shows its friend emojis to both and ranks on
// its server).
//
// "Both ways" means the smaller of the two counts: someone who sends me
// fifty messages I never answer is not a best friend.
import 'app_state.dart';
import 'backend.dart';

class BestFriend {
  const BestFriend._();

  /// Settings > 대화 > 제일 친한 친구 표시 (on by default).
  static const pref = 'best_friend_on';
  static const roomKey = 'best_friend_room';
  static const checkedKey = 'best_friend_checked';

  /// The last two weeks count.
  static const window = Duration(days: 14);

  /// Each side must have written at least this many messages.
  static const least = 5;

  /// Counted again at most this often.
  static const every = Duration(minutes: 30);

  static bool shown(AppState s) => s.on(pref, fallback: true);

  /// The 1:1 chat that has the ❤ now ('' = none).
  static String room(AppState s) => shown(s) ? s.pref(roomKey, '') : '';

  /// The chat whose two-way count is highest, or null. [msgs] per 1:1 chat.
  static String? pick(Map<String, List<Msg>> msgs, DateTime now) {
    final from = now.subtract(window);
    String? best;
    var bestScore = 0;
    DateTime? bestLast;
    for (final MapEntry(key: room, value: list) in msgs.entries) {
      var mine = 0, theirs = 0;
      DateTime? last;
      for (final m in list) {
        if (m.time.isBefore(from) || m.time.isAfter(now.add(const Duration(minutes: 5)))) continue;
        // Calls, lines and the like are not words to each other.
        if (const {'call', 'shot', 'welcome', 'opened', 'room_photo', 'verify'}.contains(m.kind)) continue;
        m.mine ? mine++ : theirs++;
        if (last == null || m.time.isAfter(last)) last = m.time;
      }
      final score = mine < theirs ? mine : theirs;
      if (score < least) continue;
      // A tie goes to whoever we talked with last.
      if (score > bestScore || (score == bestScore && bestLast != null && last != null && last.isAfter(bestLast))) {
        best = room;
        bestScore = score;
        bestLast = last;
      }
    }
    return best;
  }

  /// Counts again (at most every [every], or now with [force]).
  static Future<void> check(AppState s, {bool force = false}) async {
    if (!shown(s)) return;
    final now = s.backend.clock;
    final wall = DateTime.now().millisecondsSinceEpoch;
    final at = int.tryParse(s.pref(checkedKey, '')) ?? 0;
    if (!force && wall - at < every.inMilliseconds) return;
    final me = s.backend.userId ?? '';
    final msgs = <String, List<Msg>>{};
    for (final c in s.chats) {
      if (!c.isDirect || c.isBot || c.isChannel || c.roomId == s.savedRoomId || c.peer.isEmpty || c.peer == me) continue;
      if (s.isRequest(c.roomId)) continue;
      try {
        msgs[c.roomId] = await s.backend.cachedMessages(c.roomId);
      } catch (_) {}
    }
    final best = pick(msgs, now) ?? '';
    if (best != s.pref(roomKey, '')) await s.setPref(roomKey, best);
    await s.setPref(checkedKey, '$wall');
  }
}
