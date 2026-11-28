// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 알림음 (Telegram tip 329): a short voice or audio message can become a
// notification sound ("알림음으로 저장"), and each chat can have its own
// sound (chat alerts menu > 알림음 바꾸기).
//
// - The sound itself stays in the encrypted store on this device
//   (Backend.saveBlob), never as a plain file and never sent anywhere.
// - Telegram's limits: 5 seconds and 300 KB at most.
// - Sound names: our own sounds ("nuri", "pop", ...), "none", or
//   "my:<id>" for a saved one.
import 'dart:convert';
import 'dart:math';

import 'app_state.dart';

class MySound {
  const MySound(this.id, this.name, this.ms, this.mime);
  final String id;
  final String name;

  /// Length in milliseconds.
  final int ms;
  final String mime;

  String get key => 'my:$id';

  Map<String, Object> toJson() => {'id': id, 'name': name, 'ms': ms, 'mime': mime};

  static MySound? fromJson(Object? j) {
    if (j is! Map || j['id'] is! String) return null;
    return MySound(j['id'] as String, '${j['name'] ?? ''}', j['ms'] is int ? j['ms'] as int : 0, '${j['mime'] ?? 'audio/mp4'}');
  }
}

/// Why a sound can't be saved.
enum ToneRefusal { tooLong, tooBig, full }

class MySounds {
  const MySounds._();

  static const maxLength = Duration(seconds: 5);
  static const maxBytes = 300 * 1024;

  /// At most this many saved sounds (Telegram keeps a short list too).
  static const most = 20;

  static const _listKey = 'my_sounds';

  /// Per-chat sound (empty = the sound for its kind of chat).
  static String chatKey(String roomId) => 'sound:$roomId';

  static List<MySound> list(AppState s) {
    try {
      final j = jsonDecode(s.pref(_listKey, '[]'));
      return [
        for (final x in j as List)
          if (MySound.fromJson(x) case final m?) m,
      ];
    } catch (_) {
      return const [];
    }
  }

  static MySound? find(AppState s, String key) {
    if (!key.startsWith('my:')) return null;
    final id = key.substring(3);
    for (final m in list(s)) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Can [bytes] lasting [length] become a sound? null = yes.
  static ToneRefusal? check(AppState s, int bytes, Duration length) {
    if (length > maxLength + const Duration(milliseconds: 400)) return ToneRefusal.tooLong;
    if (bytes > maxBytes) return ToneRefusal.tooBig;
    if (list(s).length >= most) return ToneRefusal.full;
    return null;
  }

  /// Saves a sound and returns it ([name] is shown in the lists).
  static Future<MySound> add(AppState s, String name, List<int> bytes, Duration length, String mime) async {
    final id = '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';
    await s.backend.saveBlob('tone_$id', bytes);
    final m = MySound(id, name, length.inMilliseconds, mime);
    await s.setPref(_listKey, jsonEncode([...list(s).map((x) => x.toJson()), m.toJson()]));
    _cache[id] = bytes;
    return m;
  }

  /// Removes a sound; chats and kinds that used it go back to "nuri".
  static Future<void> remove(AppState s, String id) async {
    await s.setPref(
      _listKey,
      jsonEncode([
        for (final x in list(s))
          if (x.id != id) x.toJson(),
      ]),
    );
    for (final e in s.settings.entries.toList()) {
      if (e.value == 'my:$id' && (e.key.startsWith('sound:') || e.key.startsWith('sound_'))) await s.setPref(e.key, e.key.startsWith('sound:') ? '' : 'nuri');
    }
    _cache.remove(id);
    try {
      await s.backend.dropBlob('tone_$id');
    } catch (_) {}
  }

  static Future<void> rename(AppState s, String id, String name) async {
    final n = name.trim();
    if (n.isEmpty) return;
    await s.setPref(_listKey, jsonEncode([for (final x in list(s)) (x.id == id ? MySound(x.id, n, x.ms, x.mime) : x).toJson()]));
  }

  static final _cache = <String, List<int>>{};

  /// The sound's bytes (from the encrypted store), or null.
  static Future<List<int>?> bytes(AppState s, String id) async {
    final hit = _cache[id];
    if (hit != null) return hit;
    try {
      final b = await s.backend.blob('tone_$id');
      if (b != null) _cache[id] = b;
      return b;
    } catch (_) {
      return null;
    }
  }

  /// The sound a chat plays: its own, else its kind's ("sound_direct"…).
  static String forChat(AppState s, String roomId, String kindKey) {
    final own = s.pref(chatKey(roomId), '');
    if (own.isNotEmpty && (own == 'none' || !own.startsWith('my:') || find(s, own) != null)) return own;
    return s.pref(kindKey, 'nuri');
  }
}
