// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 환영 인사 + 방 규칙, end-to-end encrypted (Eric 2026-11-27).
//
// The words (and the welcome photo or video) never sit in the room's plain
// settings. An admin's phone puts them in a "pack" and sends it as a hidden
// encrypted signal; the photo/video is encrypted on the phone and only its
// key travels inside the pack. The room's settings keep just the pack's
// fingerprint (SHA-256 of the pack, which carries a random salt) — only
// admins can change room settings (the server checks), so a phone accepts a
// pack only when it matches: a member can't slip in a fake welcome.
//
// New members can't read anything sent before they joined, so an admin's
// phone sends the pack again after someone new comes in (once per batch,
// skipped when another admin already did). Welcome shows only to people
// who joined after it was written, as a bubble only they see.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'app_state.dart';
import 'backend.dart';
import 'room_rules.dart';

class RoomTexts {
  const RoomTexts({this.welcome = '', this.rules = '', this.media, this.at = 0, this.salt = ''});

  /// Formatted text (marks as in messages).
  final String welcome;
  final String rules;

  /// Welcome photo or video: {file (key + address JSON), mime, name}.
  final Map<String, dynamic>? media;

  /// When the welcome was last written (ms); 0 = an old plain-text room.
  final int at;
  final String salt;

  static const kind = 'room_texts';
  static const cfgKey = 'texts';

  /// An admin's phone greets people who joined within this many days.
  static const newcomerDays = 7;

  /// Biggest welcome photo/video.
  static const maxMedia = 50 * 1024 * 1024;

  bool get hasWelcome => welcome.trim().isNotEmpty || media != null;
  bool get hasRules => rules.trim().isNotEmpty;
  bool get isVideo => (media?['mime'] as String? ?? '').startsWith('video/');

  Map<String, dynamic> toJson() => {'n': salt, 'welcome': welcome, 'rules': rules, if (media != null) 'media': media, 'at': at};

  static RoomTexts? fromJson(Object? v) {
    if (v is! Map) return null;
    final m = v['media'];
    final media = m is Map && m['file'] is String && m['mime'] is String ? Map<String, dynamic>.from(m) : null;
    return RoomTexts(
      welcome: _cap(v['welcome'] as String? ?? '', 600),
      rules: _cap(v['rules'] as String? ?? '', 2400),
      media: media,
      at: (v['at'] as num?)?.toInt() ?? 0,
      salt: v['n'] as String? ?? '',
    );
  }

  /// JSON with keys in a fixed order, so every phone gets the same bytes.
  static String canonical(Object? v) {
    if (v is Map) {
      final keys = v.keys.map((k) => '$k').toList()..sort();
      return '{${keys.map((k) => '${jsonEncode(k)}:${canonical(v[k])}').join(',')}}';
    }
    if (v is List) return '[${v.map(canonical).join(',')}]';
    return jsonEncode(v);
  }

  static String fingerprint(Map<String, dynamic> pack) => sha256.convert(utf8.encode(canonical(pack))).toString();

  /// The room's fingerprint (null: no encrypted texts here).
  static String? fingerprintIn(Map<String, dynamic> cfg) {
    final t = cfg[cfgKey];
    return t is Map ? t['h'] as String? : null;
  }

  /// What this phone shows for a room: the encrypted pack it accepted, else
  /// an old room's plain settings. Empty while the pack is on its way.
  static RoomTexts of(AppState s, String roomId, Map<String, dynamic> cfg) {
    final h = fingerprintIn(cfg);
    if (h != null) {
      final raw = s.pref('texts:$roomId', '');
      if (raw.isEmpty) return const RoomTexts();
      try {
        final pack = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (fingerprint(pack) == h) return fromJson(pack) ?? const RoomTexts();
      } catch (_) {}
      return const RoomTexts();
    }
    return RoomTexts(welcome: (cfg['welcome'] as String? ?? '').trim(), rules: (cfg['rules'] as String? ?? '').trim());
  }

  /// Welcome / rules switched on (tools page), even before the pack arrives.
  static bool welcomeOn(Map<String, dynamic> cfg) {
    final t = cfg[cfgKey];
    if (t is Map) return t['w'] == true;
    return (cfg['welcome'] as String? ?? '').trim().isNotEmpty;
  }

  static bool rulesOn(Map<String, dynamic> cfg) {
    final t = cfg[cfgKey];
    if (t is Map) return t['r'] == true;
    return (cfg['rules'] as String? ?? '').trim().isNotEmpty;
  }

  /// Show the welcome bubble to me? Only to people who joined after it was
  /// written (Telegram: new members), never to admins, until I delete it.
  bool welcomeFor(AppState s, String roomId, {required bool admin, DateTime? joined}) {
    if (!hasWelcome || admin || s.on('welcomed:$roomId')) return false;
    if (at == 0 || joined == null) return true;
    // A minute of slack for phone clocks.
    return joined.millisecondsSinceEpoch >= at - 60000;
  }

  /// When I joined [roomId]: the first time this phone saw it (a rename
  /// moves the server's membership time later, which must not make me
  /// "new" again).
  static DateTime? joinedAt(AppState s, String roomId, DateTime? since) {
    final kept = int.tryParse(s.pref('joined_at:$roomId', ''));
    if (kept != null) return DateTime.fromMillisecondsSinceEpoch(kept);
    if (since == null) return null;
    // Saved after this frame (screens call this while drawing).
    unawaited(Future(() => s.setPref('joined_at:$roomId', '${since.millisecondsSinceEpoch}')));
    return since;
  }

  static String _salt() {
    final r = Random.secure();
    return [for (var i = 0; i < 16; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  /// An admin saves: a new pack, its fingerprint in the room (old plain
  /// copies removed) and the pack to everyone here now. Null keeps a part.
  /// [media]: {} removes the photo/video.
  static Future<RoomTexts> save(AppState s, String roomId, {String? welcome, String? rules, Map<String, dynamic>? media}) async {
    final b = s.backend;
    final cfg = await b.roomConfig(roomId);
    final old = of(s, roomId, cfg);
    final w = (welcome ?? old.welcome).trim();
    final r = (rules ?? old.rules).trim();
    final m = media == null ? old.media : (media.isEmpty ? null : media);
    final welcomeChanged = w != old.welcome || canonical(m) != canonical(old.media);
    final now = b.clock.millisecondsSinceEpoch;
    final next = RoomTexts(welcome: w, rules: r, media: m, at: welcomeChanged || old.at == 0 ? now : old.at, salt: _salt());
    if (!next.hasWelcome && !next.hasRules) {
      await b.setRoomConfig(roomId, cfgKey, null);
      await s.setPref('texts:$roomId', '');
    } else {
      final pack = next.toJson();
      await s.setPref('texts:$roomId', jsonEncode(pack));
      await b.setRoomConfig(roomId, cfgKey, {'h': fingerprint(pack), 'w': next.hasWelcome, 'r': next.hasRules});
      await b.sendSignal(roomId, kind, pack);
      await s.setPref('texts_sent:$roomId', '$now');
    }
    // The old plain copies go (the server keeps only the fingerprint now).
    for (final k in const ['welcome', 'rules']) {
      if (cfg.containsKey(k)) await b.setRoomConfig(roomId, k, null);
    }
    return next;
  }

  /// Packs that came before the room's fingerprint did (checked again later).
  static final _waiting = Expando<Map<String, Map<String, dynamic>>>();

  /// A pack from another phone: kept only when it matches the room's
  /// fingerprint (which only admins can set).
  static Future<void> onSignal(AppState s, Signal sig) async {
    final cfg = await s.backend.roomConfig(sig.roomId);
    if (!await _accept(s, sig.roomId, cfg, sig.data)) {
      (_waiting[s] ??= {})[sig.roomId] = sig.data;
      return;
    }
    // Another admin already greeted everyone who joined before this.
    final seen = int.tryParse(s.pref('texts_seen:${sig.roomId}', '')) ?? 0;
    final t = sig.time.millisecondsSinceEpoch;
    if (t > seen) await s.setPref('texts_seen:${sig.roomId}', '$t');
  }

  static Future<bool> _accept(AppState s, String roomId, Map<String, dynamic> cfg, Map<String, dynamic> pack) async {
    final h = fingerprintIn(cfg);
    if (h == null || fingerprint(pack) != h) return false;
    if (s.pref('texts:$roomId', '') != jsonEncode(pack)) await s.setPref('texts:$roomId', jsonEncode(pack));
    return true;
  }

  static final _lastRun = Expando<DateTime>();

  /// Admin phones (on each refresh, at most every 20 s): send the pack again
  /// for people who joined since, and move old plain-text rooms over.
  static Future<void> run(AppState s) async {
    final b = s.backend;
    final now = b.clock;
    final last = _lastRun[s];
    if (last != null && now.difference(last).abs() < const Duration(seconds: 20)) return;
    _lastRun[s] = now;
    final me = b.userId ?? '';
    for (final c in s.chats.where((c) => !c.isDirect)) {
      try {
        final cfg = await b.roomConfig(c.roomId);
        final waiting = _waiting[s]?.remove(c.roomId);
        if (waiting != null && !await _accept(s, c.roomId, cfg, waiting)) {
          // Still no match: keep it a little longer (fingerprint may lag).
          (_waiting[s] ??= {})[c.roomId] = waiting;
        }
        final legacy = (cfg['welcome'] as String? ?? '').trim().isNotEmpty || (cfg['rules'] as String? ?? '').trim().isNotEmpty;
        final h = fingerprintIn(cfg);
        if (h == null && !legacy) continue;
        final role = await b.myRole(c.roomId);
        if (!RoomRules.can(cfg, role, me, 'info')) continue;
        if (h == null) {
          // An old room: its welcome/rules sat in plain settings. Encrypt them.
          await save(s, c.roomId);
          continue;
        }
        final mine = of(s, c.roomId, cfg);
        if (!mine.hasWelcome && !mine.hasRules) continue;
        final covered = max(int.tryParse(s.pref('texts_sent:${c.roomId}', '')) ?? 0, int.tryParse(s.pref('texts_seen:${c.roomId}', '')) ?? 0);
        final from = now.subtract(const Duration(days: newcomerDays)).millisecondsSinceEpoch;
        final members = await b.members(c.roomId);
        final fresh = members.any((m) {
          final t = m.since?.millisecondsSinceEpoch;
          return m.userId != me && t != null && t > covered && t > from;
        });
        if (!fresh) continue;
        await b.sendSignal(c.roomId, kind, mine.toJson());
        await s.setPref('texts_sent:${c.roomId}', '${now.millisecondsSinceEpoch}');
      } catch (_) {}
    }
  }

  /// Decrypted welcome photos/videos (by key JSON), kept while the app runs.
  static final _media = <String, List<int>>{};

  static Future<List<int>> mediaBytes(Backend b, Map<String, dynamic> media) async {
    final f = media['file'] as String;
    final got = _media[f];
    if (got != null) return got;
    final bytes = await b.downloadSecret(f);
    if (_media.length > 20) _media.remove(_media.keys.first);
    return _media[f] = bytes;
  }

  /// Encrypts a new welcome photo/video on this phone and uploads it.
  static Future<Map<String, dynamic>> uploadMedia(Backend b, List<int> bytes, String mime, String name) async {
    final f = await b.uploadSecret(bytes);
    _media[f] = bytes;
    return {'file': f, 'mime': mime, 'name': name};
  }
}

String _cap(String s, int n) => s.length > n ? s.substring(0, n) : s;
