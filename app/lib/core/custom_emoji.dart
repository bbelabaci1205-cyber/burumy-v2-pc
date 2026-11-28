// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 직접 만든 움직이는 이모지 (Telegram tip 354, our way) and 그룹 이모지 묶음
// (tip 430).
//
// A made emoji is a small picture (PNG, made on this phone) plus how it
// moves ([CxMotion], drawn by our app, so no video or GIF is needed) and a
// plain emoji that stands in for it in lists, notifications and copies.
// In a message it travels as ":cx_<12 hex>:" inside the encrypted text; the
// id is a hash of picture + motion + stand-in, so nobody can pass off a
// different picture under someone else's id.
//
// The picture itself: the first time I use an emoji in a chat, my phone
// encrypts it, uploads the ciphertext (Backend.uploadSecret) and sends the
// key in a hidden encrypted note (kind [CustomEmojis.kind]). The server
// never sees the picture, which emoji I use, or with whom.
//
// Group emoji: an admin picks up to [CustomEmojis.packMax] emoji for the
// group. The pack goes out as a hidden note; the room settings keep only
// its fingerprint (only admins can change settings, the server checks), so
// a member cannot slip in a fake pack. An admin's phone sends the pack
// again when new people join (they cannot read older notes).
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'app_state.dart';
import 'backend.dart';
import 'room_rules.dart';

/// How a made emoji moves (none = still).
enum CxMotion { none, bounce, spin, wiggle, beat, float, jelly, sparkle }

class CxEmoji {
  const CxEmoji({required this.id, required this.png, required this.motion, required this.base});
  final String id;
  final Uint8List png;
  final CxMotion motion;

  /// Plain emoji standing in for it (lists, notifications, other apps).
  final String base;

  static String idOf(List<int> png, CxMotion motion, String base) =>
      'cx_${sha256.convert([...png, ...utf8.encode('|${motion.name}|$base')]).toString().substring(0, 12)}';

  static CxEmoji make(Uint8List png, CxMotion motion, String base) => CxEmoji(id: idOf(png, motion, base), png: png, motion: motion, base: base);

  Map<String, Object?> toJson() => {'id': id, 'png': base64Encode(png), 'm': motion.name, 'e': base};

  static CxEmoji? fromJson(Object? j) {
    if (j is! Map) return null;
    try {
      final png = base64Decode('${j['png']}');
      final m = CxMotion.values.firstWhere((x) => x.name == j['m'], orElse: () => CxMotion.none);
      final e = '${j['e'] ?? '🙂'}';
      final id = idOf(png, m, e);
      // A picture that does not match its id is dropped.
      return id == j['id'] ? CxEmoji(id: id, png: png, motion: m, base: e) : null;
    } catch (_) {
      return null;
    }
  }
}

class CustomEmojis {
  const CustomEmojis._();

  /// Hidden note with one emoji's picture key: {id, f, m, e}.
  static const kind = 'cx_emoji';

  /// Hidden note with a group's pack: {n: salt, items: [{id, f, m, e}]}.
  static const packKind = 'gx_pack';
  static const packCfg = 'gx';

  static const mineMax = 60, cacheMax = 300, packMax = 50;

  /// Biggest picture accepted (a 160 px PNG is far smaller).
  static const maxBytes = 96 * 1024;

  /// Emoji this phone knows (mine, received, group packs), by id.
  static final known = <String, CxEmoji>{};

  /// Ids I made or saved (newest first).
  static List<String> mine = [];

  static final _loaded = Expando<bool>();

  /// Reads what this account keeps (once per account per run).
  static void load(AppState s) {
    if (_loaded[s] == true) return;
    _loaded[s] = true;
    known.clear();
    for (final key in const ['cx_cache', 'my_emoji']) {
      try {
        for (final x in jsonDecode(s.pref(key, '[]')) as List) {
          final e = CxEmoji.fromJson(x);
          if (e != null) known[e.id] = e;
        }
      } catch (_) {}
    }
    try {
      mine = [for (final x in jsonDecode(s.pref('my_emoji', '[]')) as List) '${(x as Map)['id']}'].where(known.containsKey).toList();
    } catch (_) {
      mine = [];
    }
    changed.add(null);
  }

  /// Something new to draw (a picture arrived, a pack changed).
  static final changed = StreamController<void>.broadcast();

  static Future<void> _saveMine(AppState s) => s.setPref(
    'my_emoji',
    jsonEncode([
      for (final id in mine)
        if (known[id] != null) known[id]!.toJson(),
    ]),
  );

  static Future<void> _remember(AppState s, CxEmoji e) async {
    known[e.id] = e;
    final ids = <String>[];
    try {
      for (final x in jsonDecode(s.pref('cx_cache', '[]')) as List) {
        ids.add('${(x as Map)['id']}');
      }
    } catch (_) {}
    final keep = [e.id, ...ids.where((x) => x != e.id)].take(cacheMax);
    await s.setPref(
      'cx_cache',
      jsonEncode([
        for (final id in keep)
          if (known[id] != null) known[id]!.toJson(),
      ]),
    );
    changed.add(null);
  }

  /// Adds a made (or saved) emoji to 내 이모지.
  static Future<CxEmoji> addMine(AppState s, CxEmoji e) async {
    known[e.id] = e;
    mine = [e.id, ...mine.where((x) => x != e.id)].take(mineMax).toList();
    await _saveMine(s);
    changed.add(null);
    return e;
  }

  static Future<void> removeMine(AppState s, String id) async {
    mine = mine.where((x) => x != id).toList();
    await _saveMine(s);
    changed.add(null);
  }

  static bool isMine(String id) => mine.contains(id);

  /// Made-emoji ids in a message text.
  static final code = RegExp(r':(cx_[0-9a-f]{12}):');
  static Iterable<String> idsIn(String text) => code.allMatches(text).map((m) => m.group(1)!);

  /// After I sent [text]: give this chat the pictures it has not had yet.
  static Future<void> shareIn(AppState s, String roomId, String text) async {
    final ids = idsIn(text).toSet();
    if (ids.isEmpty) return;
    final sent = s.pref('cx_sent:$roomId', '').split(',').where((x) => x.isNotEmpty).toSet();
    for (final id in ids.where((x) => !sent.contains(x))) {
      final e = known[id];
      if (e == null) continue;
      final f = await s.backend.uploadSecret(e.png);
      await s.backend.sendSignal(roomId, kind, {'id': e.id, 'f': f, 'm': e.motion.name, 'e': e.base});
      sent.add(id);
    }
    await s.setPref('cx_sent:$roomId', sent.take(400).join(','));
  }

  static Future<CxEmoji?> _fetch(AppState s, Map<String, dynamic> d) async {
    final id = d['id'], f = d['f'];
    if (id is! String || f is! String || !RegExp(r'^cx_[0-9a-f]{12}$').hasMatch(id)) return null;
    final have = known[id];
    if (have != null) return have;
    final png = Uint8List.fromList(await s.backend.downloadSecret(f));
    if (png.length > maxBytes) return null;
    final e = CxEmoji.fromJson({'id': id, 'png': base64Encode(png), 'm': d['m'], 'e': d['e']});
    if (e != null) await _remember(s, e);
    return e;
  }

  static Future<void> onSignal(AppState s, Signal sig) async {
    load(s);
    await _fetch(s, sig.data);
  }

  // ------------------------------------------------------------ group pack

  static String _salt() {
    final r = Random.secure();
    return [for (var i = 0; i < 12; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  static String fingerprint(Map<String, dynamic> pack) => sha256.convert(utf8.encode(jsonEncode(pack))).toString();

  /// The group's emoji (ids), as this phone has them.
  static List<String> pack(AppState s, String roomId) {
    try {
      final p = jsonDecode(s.pref('gx:$roomId', '{}')) as Map;
      return [for (final x in (p['items'] as List? ?? const [])) '${(x as Map)['id']}'].where(known.containsKey).toList();
    } catch (_) {
      return const [];
    }
  }

  /// An admin saves the group's emoji: the pack to everyone here now, its
  /// fingerprint in the room. Empty = no group emoji.
  static Future<void> savePack(AppState s, String roomId, List<String> ids) async {
    final b = s.backend;
    if (ids.isEmpty) {
      await b.setRoomConfig(roomId, packCfg, null);
      await s.setPref('gx:$roomId', '');
      changed.add(null);
      return;
    }
    final items = <Map<String, dynamic>>[];
    for (final id in ids.take(packMax)) {
      final e = known[id];
      if (e == null) continue;
      items.add({'id': e.id, 'f': await b.uploadSecret(e.png), 'm': e.motion.name, 'e': e.base});
    }
    final pack = {'n': _salt(), 'items': items};
    await s.setPref('gx:$roomId', jsonEncode(pack));
    await b.setRoomConfig(roomId, packCfg, {'h': fingerprint(pack), 'c': items.length});
    await b.sendSignal(roomId, packKind, pack);
    await s.setPref('gx_sent:$roomId', '${b.clock.millisecondsSinceEpoch}');
    changed.add(null);
  }

  /// A pack from another phone: kept only when it matches the fingerprint
  /// an admin put in the room's settings.
  static Future<void> onPack(AppState s, Signal sig) async {
    load(s);
    final cfg = await s.backend.roomConfig(sig.roomId);
    final h = cfg[packCfg] is Map ? (cfg[packCfg] as Map)['h'] : null;
    if (h is! String || fingerprint(sig.data) != h) return;
    for (final x in (sig.data['items'] as List? ?? const [])) {
      if (x is Map) await _fetch(s, Map<String, dynamic>.from(x)).catchError((_) => null);
    }
    await s.setPref('gx:${sig.roomId}', jsonEncode(sig.data));
    await s.setPref('gx_seen:${sig.roomId}', '${sig.time.millisecondsSinceEpoch}');
    changed.add(null);
  }

  /// Admin phone, when the group is opened: send the pack again if someone
  /// joined since it was last sent (by me or another admin).
  static Future<void> resendForNewcomers(AppState s, String roomId) async {
    final b = s.backend;
    final raw = s.pref('gx:$roomId', '');
    if (raw.isEmpty) return;
    final cfg = await b.roomConfig(roomId);
    final me = b.userId ?? '';
    if (!RoomRules.can(cfg, await b.myRole(roomId), me, 'info')) return;
    final pack = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final h = cfg[packCfg] is Map ? (cfg[packCfg] as Map)['h'] : null;
    if (h != fingerprint(pack)) return;
    final covered = max(int.tryParse(s.pref('gx_sent:$roomId', '')) ?? 0, int.tryParse(s.pref('gx_seen:$roomId', '')) ?? 0);
    final members = await b.members(roomId);
    if (!members.any((m) => m.userId != me && (m.since?.millisecondsSinceEpoch ?? 0) > covered)) return;
    await b.sendSignal(roomId, packKind, pack);
    await s.setPref('gx_sent:$roomId', '${b.clock.millisecondsSinceEpoch}');
  }
}
