// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 캡처 알림 (Snapchat's screenshot notice, our way; 4대 메신저 보드
// '우리식으로', Eric 2026-11-28). Burumy blocks capture where it can: on
// Android the protected screens come out black, so nothing is ever caught
// and nothing needs telling. An iPhone can't refuse a screenshot, so when
// one is taken while protected content is on screen (a view-once photo,
// video, voice or round video, a protected file, a chat with sharing off),
// the people in that chat are told: "민지님이 캡처했어요".
//
// The notice is a hidden end-to-end encrypted note (Backend.sendSignal):
// the server sees only scrambled bytes, never that a capture happened.
// Each phone keeps the lines for its own chats (at most [keep] per chat)
// and shows them in the chat and on its chat list row.
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';
import 'features.dart';

/// One capture line in a chat.
class ShotLine {
  const ShotLine({required this.who, required this.at, required this.what});

  /// Who took it (my own ID for mine).
  final String who;
  final DateTime at;

  /// What was on screen: chat, photo, video, voice, round, file or bubble.
  final String what;

  List<Object> toJson() => [who, at.millisecondsSinceEpoch, what];

  static ShotLine? fromJson(Object? v) {
    if (v is! List || v.length != 3 || v[0] is! String || v[1] is! int || v[2] is! String) return null;
    return ShotLine(who: v[0] as String, at: DateTime.fromMillisecondsSinceEpoch(v[1] as int), what: ShotAlert.whatOf(v[2]));
  }
}

class ShotAlert {
  const ShotAlert._();

  /// Signal kind (a-z, 0-9, _).
  static const kind = 'shot';

  /// Lines kept per chat on this phone.
  static const keep = 30;

  /// Same person, same chat: one line per this long (holding the buttons
  /// makes several screenshots in a row).
  static const quiet = Duration(seconds: 20);

  static const whats = {'chat', 'photo', 'video', 'voice', 'round', 'file', 'bubble'};

  static String whatOf(Object? v) => v is String && whats.contains(v) ? v : 'chat';

  static String _key(String room) => 'shots:$room';

  /// Synthetic message ids for the chat's centre lines.
  static const idPrefix = 'shot-';

  static List<ShotLine> lines(AppState s, String room) {
    final raw = s.pref(_key(room), '');
    if (raw.isEmpty) return const [];
    try {
      return [for (final v in jsonDecode(raw) as List) ?ShotLine.fromJson(v)];
    } catch (_) {
      return const [];
    }
  }

  static Future<bool> _add(AppState s, String room, ShotLine line) async {
    final now = lines(s, room);
    if (now.any((x) => x.who == line.who && x.what == line.what && line.at.difference(x.at).abs() < quiet)) return false;
    final next = [...now, line]..sort((a, b) => a.at.compareTo(b.at));
    final cut = next.length > keep ? next.sublist(next.length - keep) : next;
    await s.setPref(_key(room), jsonEncode([for (final l in cut) l.toJson()]));
    return true;
  }

  /// The phone said a screenshot was just taken while [what] was on screen
  /// in [room]: tell the others in that chat, and note it for me.
  static Future<void> taken(AppState s, String room, String what) async {
    if (!Features.ownWay || room.isEmpty || room == s.savedRoomId) return;
    final me = s.backend.userId ?? '';
    final w = whatOf(what);
    final at = DateTime.now();
    if (!await _add(s, room, ShotLine(who: me, at: at, what: w))) return;
    try {
      await s.backend.sendSignal(room, kind, {'w': w, 'at': at.millisecondsSinceEpoch});
    } catch (_) {}
  }

  /// Someone else's phone told us.
  static Future<void> onSignal(AppState s, Signal g) async {
    if (!Features.ownWay || g.sender == s.backend.userId) return;
    final at = g.data['at'];
    // Their clock may be off: never later than when it arrived.
    final when = at is int && at > 0 ? DateTime.fromMillisecondsSinceEpoch(at) : g.time;
    await _add(s, g.roomId, ShotLine(who: g.sender, at: when.isAfter(g.time) ? g.time : when, what: whatOf(g.data['w'])));
  }

  /// The lines as messages, to sit between the chat's messages by time.
  static List<Msg> asMsgs(AppState s, String room) => [
    for (final (i, l) in lines(s, room).indexed) Msg(id: '$idPrefix$i', sender: l.who, body: l.what, time: l.at, mine: l.who == s.backend.userId, kind: 'shot'),
  ];

  /// [shown] (oldest first) with the capture lines put in by time.
  static List<Msg> mix(List<Msg> shown, List<Msg> shots) {
    if (shots.isEmpty) return shown;
    final out = <Msg>[];
    var j = 0;
    for (final m in shown) {
      while (j < shots.length && !shots[j].time.isAfter(m.time)) {
        out.add(shots[j++]);
      }
      out.add(m);
    }
    out.addAll(shots.skip(j));
    return out;
  }

  /// The newest line, when it is newer than the chat's last message (the
  /// chat list shows it instead of the message).
  static ShotLine? newest(AppState s, String room, Msg? last) {
    final all = lines(s, room);
    if (all.isEmpty) return null;
    final l = all.last;
    return last == null || l.at.isAfter(last.time) ? l : null;
  }
}
