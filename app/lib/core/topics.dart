// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 주제 (group topics, Telegram tips 527 · 362 · 262), end-to-end encrypted.
//
// What the server can't learn:
// - which topic a message is in: the topic id rides INSIDE the encrypted
//   message content (engine topic.rs, field app.burumy.topic), never in the
//   readable relation part;
// - the topic list (names, icons, colours, closed) or even that the group
//   uses topics: an admin's phone sends the list as a hidden encrypted
//   "pack"; the room's settings keep only the pack's fingerprint (SHA-256
//   of the pack, which carries a random salt). Only admins can change room
//   settings (the server checks), so a phone accepts a pack only when it
//   matches: a member can't slip in a fake topic list.
//
// New members can't read anything sent before they joined, so an admin's
// phone sends the pack again after someone new comes in (as with the
// welcome, core/room_texts.dart). Unread counts per topic are counted on
// the phone.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters;

import 'app_state.dart';
import 'backend.dart';
import 'room_rules.dart';
import 'room_texts.dart' show RoomTexts;

class Topic {
  const Topic({required this.id, this.name = '', this.icon = '', this.color = 0, this.closed = false});

  /// Short id (letters/digits); "g" = 일반 (General).
  final String id;

  /// Up to [maxName] characters; 일반 may be '' (shown in my language).
  final String name;

  /// One emoji, or '' for the coloured bubble with the first letter.
  final String icon;

  /// Index into [Topics.colors].
  final int color;

  /// Closed: only admins can write in it (members still read).
  final bool closed;

  bool get general => id == Topics.general;

  Topic copyWith({String? name, String? icon, int? color, bool? closed}) =>
      Topic(id: id, name: name ?? this.name, icon: icon ?? this.icon, color: color ?? this.color, closed: closed ?? this.closed);

  Map<String, dynamic> toJson() => {'i': id, 'n': name, if (icon.isNotEmpty) 'e': icon, 'c': color, if (closed) 'x': true};

  static Topic? fromJson(Object? v) {
    if (v is! Map) return null;
    final id = v['i'];
    if (id is! String || !Topics.validId(id)) return null;
    final e = v['e'] as String? ?? '';
    return Topic(
      id: id,
      name: Topics.cap(v['n'] as String? ?? '', Topics.maxName),
      // One emoji at most (a few code units for flags / skin tones).
      icon: e.runes.length <= 8 ? e : '',
      color: ((v['c'] as num?)?.toInt() ?? 0).clamp(0, Topics.colorCount - 1),
      closed: v['x'] == true,
    );
  }
}

class Topics {
  const Topics({this.on = false, this.view = tabs, this.list = const [], this.generalHidden = false, this.at = 0, this.salt = ''});

  /// Topics switched on for this group.
  final bool on;

  /// "tabs" (side rail / top bar inside the chat) or "list" (a list of
  /// topics first, like a folder of chats). Same for everyone.
  final String view;

  /// 일반 first, then the topics in the order the admins made them.
  final List<Topic> list;

  /// 일반 hidden from the tabs (its messages stay in 모두).
  final bool generalHidden;
  final int at;
  final String salt;

  static const kind = 'room_topics';
  static const cfgKey = 'topics';
  static const tabs = 'tabs', listView = 'list';
  static const general = 'g', all = 'all';
  static const maxName = 32, maxTopics = 100;

  /// Telegram's topic colours, as iOS system colours (Palette tiles).
  static const colorCount = 7;

  static bool validId(String id) => id.isNotEmpty && id.length <= 24 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);

  static String cap(String s, int n) {
    final t = s.trim();
    return t.characters.length <= n ? t : t.characters.take(n).toString();
  }

  Topic? byId(String? id) => list.where((t) => t.id == (id ?? general)).firstOrNull;

  /// Topics shown as tabs (일반 can be hidden).
  List<Topic> get shown => [
    for (final t in list)
      if (!(t.general && generalHidden)) t,
  ];

  Topics copyWith({bool? on, String? view, List<Topic>? list, bool? generalHidden}) =>
      Topics(on: on ?? this.on, view: view ?? this.view, list: list ?? this.list, generalHidden: generalHidden ?? this.generalHidden, at: at, salt: salt);

  Map<String, dynamic> toJson() => {
    'n': salt,
    'on': on,
    'v': view,
    't': [for (final t in list) t.toJson()],
    if (generalHidden) 'gh': true,
    'at': at,
  };

  static Topics? fromJson(Object? v) {
    if (v is! Map) return null;
    final raw = v['t'];
    final seen = <String>{};
    final items = <Topic>[
      if (raw is List)
        for (final x in raw.take(maxTopics + 1))
          if (Topic.fromJson(x) case final t? when seen.add(t.id)) t,
    ];
    // 일반 is always there, first.
    final g = items.where((t) => t.general).firstOrNull ?? const Topic(id: general);
    return Topics(
      on: v['on'] == true,
      view: v['v'] == listView ? listView : tabs,
      list: [g, ...items.where((t) => !t.general)],
      generalHidden: v['gh'] == true,
      at: (v['at'] as num?)?.toInt() ?? 0,
      salt: v['n'] as String? ?? '',
    );
  }

  static String fingerprint(Map<String, dynamic> pack) => RoomTexts.fingerprint(pack);

  static String? fingerprintIn(Map<String, dynamic> cfg) {
    final t = cfg[cfgKey];
    return t is Map ? t['h'] as String? : null;
  }

  /// What this phone shows for a room (off until the pack arrived).
  static Topics of(AppState s, String roomId, Map<String, dynamic> cfg) {
    final h = fingerprintIn(cfg);
    if (h == null) return const Topics();
    final raw = s.pref('topics:$roomId', '');
    if (raw.isEmpty) return const Topics();
    try {
      final pack = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      if (fingerprint(pack) == h) return fromJson(pack) ?? const Topics();
    } catch (_) {}
    return const Topics();
  }

  static String _salt() {
    final r = Random.secure();
    return [for (var i = 0; i < 16; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  /// A fresh id for a new topic (random, so two admins never clash).
  static String newId() {
    final r = Random.secure();
    const abc = 'abcdefghijkmnpqrstuvwxyz23456789';
    return 't${[for (var i = 0; i < 7; i++) abc[r.nextInt(abc.length)]].join()}';
  }

  /// Can I add, rename or close topics here? (Admins with the 정보 변경 right.)
  static bool canManage(Map<String, dynamic> cfg, String role, String me) => (role == 'owner' || role == 'admin') && RoomRules.can(cfg, role, me, 'info');

  /// An admin saves: a new pack, its fingerprint in the room and the pack
  /// to everyone here now.
  static Future<Topics> save(AppState s, String roomId, Topics t) async {
    final b = s.backend;
    final now = b.clock.millisecondsSinceEpoch;
    final list = t.list.isEmpty ? const [Topic(id: general)] : t.list;
    final next = Topics(on: t.on, view: t.view, list: list, generalHidden: t.generalHidden, at: now, salt: _salt());
    final pack = next.toJson();
    await s.setPref('topics:$roomId', jsonEncode(pack));
    await b.setRoomConfig(roomId, cfgKey, {'h': fingerprint(pack)});
    await b.sendSignal(roomId, kind, pack);
    await s.setPref('topics_sent:$roomId', '$now');
    return next;
  }

  static final _waiting = Expando<Map<String, Map<String, dynamic>>>();

  /// A pack from another phone: kept only when it matches the room's
  /// fingerprint (which only admins can set).
  static Future<void> onSignal(AppState s, Signal sig) async {
    final cfg = await s.backend.roomConfig(sig.roomId);
    if (!await _accept(s, sig.roomId, cfg, sig.data)) {
      (_waiting[s] ??= {})[sig.roomId] = sig.data;
      return;
    }
    final seen = int.tryParse(s.pref('topics_seen:${sig.roomId}', '')) ?? 0;
    final t = sig.time.millisecondsSinceEpoch;
    if (t > seen) await s.setPref('topics_seen:${sig.roomId}', '$t');
  }

  static Future<bool> _accept(AppState s, String roomId, Map<String, dynamic> cfg, Map<String, dynamic> pack) async {
    final h = fingerprintIn(cfg);
    if (h == null || fingerprint(pack) != h) return false;
    if (s.pref('topics:$roomId', '') != jsonEncode(pack)) await s.setPref('topics:$roomId', jsonEncode(pack));
    return true;
  }

  static final _lastRun = Expando<DateTime>();

  /// Admin phones (on each refresh, at most every 20 s): send the pack
  /// again for people who joined since, and accept packs that came early.
  static Future<void> run(AppState s) async {
    final b = s.backend;
    final now = b.clock;
    final last = _lastRun[s];
    if (last != null && now.difference(last).abs() < const Duration(seconds: 20)) return;
    _lastRun[s] = now;
    final me = b.userId ?? '';
    for (final c in s.chats.where((c) => !c.isDirect && !c.isChannel)) {
      try {
        final cfg = await b.roomConfig(c.roomId);
        final waiting = _waiting[s]?.remove(c.roomId);
        if (waiting != null && !await _accept(s, c.roomId, cfg, waiting)) (_waiting[s] ??= {})[c.roomId] = waiting;
        if (fingerprintIn(cfg) == null) continue;
        final role = await b.myRole(c.roomId);
        if (!canManage(cfg, role, me)) continue;
        final mine = s.pref('topics:${c.roomId}', '');
        if (mine.isEmpty || of(s, c.roomId, cfg).list.isEmpty) continue;
        final covered = max(int.tryParse(s.pref('topics_sent:${c.roomId}', '')) ?? 0, int.tryParse(s.pref('topics_seen:${c.roomId}', '')) ?? 0);
        final members = await b.members(c.roomId);
        final fresh = members.any((m) {
          final t = m.since?.millisecondsSinceEpoch;
          return m.userId != me && t != null && t > covered;
        });
        if (!fresh) continue;
        await b.sendSignal(c.roomId, kind, Map<String, dynamic>.from(jsonDecode(mine) as Map));
        await s.setPref('topics_sent:${c.roomId}', '${now.millisecondsSinceEpoch}');
      } catch (_) {}
    }
  }

  /// The topic a message is in ('g' when it has none, or an unknown one).
  String topicOf(Msg m) {
    final t = m.topic;
    if (t == null || byId(t) == null) return general;
    return t;
  }

  // ---- Unread per topic (this phone only) ----

  /// When I last looked at each topic (ms).
  static Map<String, int> seen(AppState s, String roomId) {
    try {
      return Map<String, int>.from(jsonDecode(s.pref('topic_seen:$roomId', '{}')) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> markSeen(AppState s, String roomId, Iterable<String> ids, DateTime upTo) async {
    final m = seen(s, roomId);
    var changed = false;
    for (final id in ids) {
      if ((m[id] ?? 0) < upTo.millisecondsSinceEpoch) {
        m[id] = upTo.millisecondsSinceEpoch;
        changed = true;
      }
    }
    if (changed) await s.setPref('topic_seen:$roomId', jsonEncode(m));
  }

  /// Unread messages per topic id. [base]: the room's read mark when no
  /// topic was looked at yet.
  Map<String, int> unread(List<Msg> msgs, Map<String, int> seenAt, DateTime? base) {
    final out = <String, int>{};
    for (final m in msgs) {
      if (m.mine) continue;
      final t = topicOf(m);
      final from = seenAt[t] ?? base?.millisecondsSinceEpoch;
      if (from == null || m.time.millisecondsSinceEpoch <= from) continue;
      out[t] = (out[t] ?? 0) + 1;
    }
    return out;
  }
}
