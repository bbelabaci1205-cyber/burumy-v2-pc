// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 안 본 멘션·반응 (Telegram tips 249 + 320). In groups, a message that
// mentions me or answers one of mine is a mention until it has been on my
// screen; in groups and 1:1 chats, new reactions to my messages count the
// same way. The chat list shows a green @ / ♥ circle, the chat shows jump
// buttons. Everything is worked out and kept on this phone only (pref
// "marks:<room>"); the server learns nothing new.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'backend.dart';
import 'features.dart';
import 'room_rules.dart';

/// What I have already seen in one chat.
class MarkState {
  MarkState({required this.since, Set<String>? seen, Map<String, int>? rx}) : seen = seen ?? {}, rx = rx ?? {};

  /// Mentions older than this never count (the feature's start in this chat).
  final DateTime since;

  /// Mentions that were on my screen.
  final Set<String> seen;

  /// My message id -> how many reactions from others I have seen on it.
  final Map<String, int> rx;

  /// Kept small: the newest seen ids and reaction counts only.
  static const keepSeen = 200, keepRx = 300;

  String encode() {
    final s = seen.toList();
    final r = rx.entries.where((e) => e.value > 0).toList();
    return jsonEncode({
      'since': since.millisecondsSinceEpoch,
      'seen': s.sublist(s.length > keepSeen ? s.length - keepSeen : 0),
      'rx': Map.fromEntries(r.sublist(r.length > keepRx ? r.length - keepRx : 0)),
    });
  }

  static MarkState? decode(String raw) {
    if (raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return MarkState(
        since: DateTime.fromMillisecondsSinceEpoch((j['since'] as num).toInt()),
        seen: {for (final x in (j['seen'] as List? ?? const [])) '$x'},
        rx: {for (final e in (j['rx'] as Map? ?? const {}).entries) '${e.key}': (e.value as num).toInt()},
      );
    } catch (_) {
      return null;
    }
  }
}

/// Numbers for one chat row: unseen mentions and unseen reactions.
typedef MarkCounts = ({int mentions, int reactions});

class ChatMarks {
  ChatMarks._();

  static String key(String roomId) => 'marks:$roomId';

  /// Reactions from other people (my own one taken out).
  static int others(Msg m) => m.reactions.fold<int>(0, (n, r) => n + r.count - (r.mine != null ? 1 : 0));

  /// Mentions me ("@이름", "@모두") or answers one of my messages.
  static bool isMention(Msg m, Set<String> mine, String me, String myName) =>
      !m.mine && m.body != null && (RoomRules.mentionsMe(m.body!, me, myName) || (m.replyTo != null && mine.contains(m.replyTo)));

  /// The first look at a chat: mentions among the unread messages count;
  /// every reaction already there is taken as seen (no old flood).
  static MarkState start(List<Msg> msgs, int unread, DateTime now) {
    final others = msgs.where((m) => !m.mine).toList();
    final firstUnread = unread > 0 && others.isNotEmpty ? others[(others.length - unread).clamp(0, others.length - 1)].time : null;
    return MarkState(
      since: firstUnread?.subtract(const Duration(milliseconds: 1)) ?? now,
      rx: {
        for (final m in msgs)
          if (m.mine && ChatMarks.others(m) > 0) m.id: ChatMarks.others(m),
      },
    );
  }

  /// Unseen mentions, oldest first (groups only).
  static List<Msg> mentions(List<Msg> msgs, MarkState st, String me, String myName) {
    final mine = {
      for (final m in msgs)
        if (m.mine) m.id,
    };
    return [
      for (final m in msgs)
        if (m.time.isAfter(st.since) && !st.seen.contains(m.id) && isMention(m, mine, me, myName)) m,
    ];
  }

  /// My messages with reactions I haven't seen, oldest first.
  static List<Msg> reactions(List<Msg> msgs, MarkState st) => [
    for (final m in msgs)
      if (m.mine && others(m) > (st.rx[m.id] ?? 0)) m,
  ];

  /// Mentions count in groups; reactions in groups and 1:1 chats.
  static bool mentionsCount(ChatPreview c) => !c.isDirect && !c.isChannel;
  static bool reactionsCount(ChatPreview c) => !c.isChannel;

  // --- chat list -----------------------------------------------------------

  /// Room -> counts, for the chat list (rebuilds listen to this).
  static final counts = ValueNotifier<Map<String, MarkCounts>>(const {});
  static Timer? _wait;
  static bool _busy = false;
  static DateTime _last = DateTime(2000);
  static String _myName = '';

  /// Looks again soon (many changes in a row make one look).
  static void schedule(AppState s) {
    if (!Features.tipsReply) return;
    _wait?.cancel();
    // At most one look every 2 seconds, however often the list redraws.
    final gap = const Duration(seconds: 2) - DateTime.now().difference(_last);
    _wait = Timer(gap > const Duration(milliseconds: 600) ? gap : const Duration(milliseconds: 600), () => unawaited(scan(s)));
  }

  /// Stops a waiting look (log out, tests).
  static void stop() {
    _wait?.cancel();
    _wait = null;
  }

  /// Works out every chat's numbers from the messages on this phone.
  static Future<void> scan(AppState s) async {
    if (_busy) return schedule(s);
    _busy = true;
    _last = DateTime.now();
    try {
      final b = s.backend;
      final me = b.userId ?? '';
      if (_myName.isEmpty) _myName = await b.myName().catchError((_) => '');
      final out = <String, MarkCounts>{};
      final starts = <String, String>{};
      for (final c in s.chats.take(80)) {
        if (c.archived || c.roomId == s.savedRoomId || !(mentionsCount(c) || reactionsCount(c))) continue;
        final msgs = await b.cachedMessages(c.roomId).catchError((_) => const <Msg>[]);
        if (msgs.isEmpty) continue;
        var st = MarkState.decode(s.pref(key(c.roomId), ''));
        if (st == null) {
          st = start(msgs, c.unread, b.clock);
          starts[key(c.roomId)] = st.encode();
        }
        final n = (mentions: mentionsCount(c) ? mentions(msgs, st, me, _myName).length : 0, reactions: reactions(msgs, st).length);
        if (n.mentions > 0 || n.reactions > 0) out[c.roomId] = n;
      }
      for (final e in starts.entries) {
        await s.setPref(e.key, e.value);
      }
      if (!mapEquals(out, counts.value)) counts.value = out;
    } finally {
      _busy = false;
    }
  }

  /// These were on my screen: they stop counting here and in the list.
  static Future<void> seen(AppState s, String roomId, List<Msg> msgs, {Iterable<String> mentionIds = const [], Iterable<String> reactionIds = const []}) async {
    final st = MarkState.decode(s.pref(key(roomId), '')) ?? MarkState(since: s.backend.clock);
    st.seen.addAll(mentionIds);
    final ids = reactionIds.toSet();
    for (final m in msgs) {
      if (ids.contains(m.id)) st.rx[m.id] = others(m);
    }
    await s.setPref(key(roomId), st.encode());
    final now = counts.value[roomId];
    if (now != null) {
      final left = (mentions: (now.mentions - mentionIds.length).clamp(0, 1 << 20), reactions: (now.reactions - ids.length).clamp(0, 1 << 20));
      counts.value = {...counts.value}..[roomId] = left;
      if (left.mentions == 0 && left.reactions == 0) counts.value = {...counts.value}..remove(roomId);
    }
  }
}
