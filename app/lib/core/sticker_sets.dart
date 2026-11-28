// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스티커 묶음 (Telegram tips 538 + 441, Eric's card: "B. 묶음+공유만"):
// I put my own stickers (and any of the built-in ones) into a named set,
// sort them, give each an emoji, and share the set.
//
// How sharing stays private: the whole set is ONE file, encrypted on my
// phone and uploaded (Backend.uploadEncrypted). The file's place + key go
// either inside an end-to-end encrypted card in a chat, or after the '#'
// of a link (https://<host>/s#f=...), which browsers never send to a
// server. So the server only ever holds scrambled bytes: it can't see the
// pictures, the name, or who added the set. No use statistics are kept
// (Eric's card: stats left out, they would tell the server who sends what).
//
// The same file format works for emoji sets later (kind 'emoji', tip 430).
import 'dart:convert';
import 'dart:typed_data';

import '../brand/brand.dart';
import 'app_state.dart';
import 'doc.dart' show Doc;

/// One sticker in a set: a built-in sticker id, or my own PNG.
class SetItem {
  const SetItem({this.id = '', this.png, this.emoji = ''});
  final String id;
  final Uint8List? png;

  /// The emoji it stands for (finds it from the composer and the search).
  final String emoji;

  SetItem copy({String? emoji}) => SetItem(id: id, png: png, emoji: emoji ?? this.emoji);

  Map<String, Object?> toJson() => {if (id.isNotEmpty) 'id': id, if (png != null) 'png': base64Encode(png!), if (emoji.isNotEmpty) 'e': emoji};

  static SetItem? fromJson(Object? v) {
    if (v is! Map) return null;
    final id = v['id'] is String ? v['id'] as String : '';
    Uint8List? png;
    if (v['png'] is String) {
      try {
        png = base64Decode(v['png'] as String);
      } catch (_) {}
    }
    // A PNG must really be a PNG (and not too big); ids are plain words.
    if (png != null && (png.length > StickerSets.maxPng || png.length < 8 || png[0] != 0x89 || png[1] != 0x50)) png = null;
    if (id.isNotEmpty && !RegExp(r'^[a-z0-9_]{3,40}$').hasMatch(id)) return null;
    if (id.isEmpty && png == null) return null;
    final e = v['e'] is String ? (v['e'] as String) : '';
    return SetItem(id: id, png: png, emoji: e.length <= 16 ? e : '');
  }
}

/// A sticker set on this phone (made by me or added from someone).
class StickerSet {
  const StickerSet({required this.id, required this.name, required this.items, this.kind = 'sticker', this.mine = false, this.file = '', this.from = ''});

  /// Local id ('s' + time); the shared file's place when added.
  final String id;
  final String name;
  final List<SetItem> items;
  final String kind;

  /// I made it (I can edit it); others' sets are read-only.
  final bool mine;

  /// The shared file (place + key, JSON) once shared, else ''.
  final String file;

  /// Who shared it with me ('' = a link).
  final String from;

  StickerSet copy({String? name, List<SetItem>? items, String? file}) =>
      StickerSet(id: id, name: name ?? this.name, items: items ?? this.items, kind: kind, mine: mine, file: file ?? this.file, from: from);

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'mine': mine,
    'file': file,
    'from': from,
    'items': [for (final i in items) i.toJson()],
  };

  /// The shared file's contents (what others download).
  Map<String, Object?> payload() => {
    'v': 1,
    'kind': kind,
    'name': name,
    'items': [for (final i in items) i.toJson()],
  };

  static StickerSet? fromJson(Object? v) {
    if (v is! Map || v['id'] is! String) return null;
    return StickerSet(
      id: v['id'] as String,
      name: cleanName('${v['name'] ?? ''}'),
      kind: v['kind'] == 'emoji' ? 'emoji' : 'sticker',
      mine: v['mine'] == true,
      file: v['file'] is String ? v['file'] as String : '',
      from: v['from'] is String ? v['from'] as String : '',
      items: [for (final x in (v['items'] is List ? v['items'] as List : const [])) ?SetItem.fromJson(x)].take(StickerSets.maxItems).toList(),
    );
  }

  /// Reads a downloaded set file; null if it isn't one.
  static StickerSet? fromPayload(List<int> bytes, {required String file, String from = ''}) {
    try {
      final v = jsonDecode(utf8.decode(bytes));
      if (v is! Map || v['v'] != 1) return null;
      final s = StickerSet.fromJson({...v, 'id': 'x${file.hashCode.toUnsigned(32)}', 'mine': false, 'file': file, 'from': from});
      if (s == null || s.items.isEmpty || s.name.isEmpty) return null;
      return s;
    } catch (_) {
      return null;
    }
  }
}

String cleanName(String s) {
  final t = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  return t.length > StickerSets.maxName ? t.substring(0, StickerSets.maxName) : t;
}

/// The sets kept on this phone (pref 'sticker_sets'), in my order.
class StickerSets {
  const StickerSets._();
  static const key = 'sticker_sets';

  /// Telegram allows 120 per set; ours travel as one file, so 50.
  static const maxItems = 50;
  static const maxName = 32;
  static const maxSets = 30;
  static const maxPng = 512 * 1024;

  static List<StickerSet> all(AppState s) {
    try {
      return [for (final x in jsonDecode(s.pref(key, '[]')) as List) ?StickerSet.fromJson(x)];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(AppState s, List<StickerSet> sets) => s.setPref(key, jsonEncode([for (final x in sets.take(maxSets)) x.toJson()]));

  /// Adds or replaces (same id, or the same shared file).
  static Future<void> put(AppState s, StickerSet set) async {
    final list = all(s);
    final i = list.indexWhere((x) => x.id == set.id || (set.file.isNotEmpty && x.file == set.file));
    if (i >= 0) {
      list[i] = set;
    } else {
      list.insert(0, set);
    }
    await save(s, list);
  }

  static Future<void> remove(AppState s, String id) => save(s, [
    for (final x in all(s))
      if (x.id != id) x,
  ]);

  static bool has(AppState s, String file) => file.isNotEmpty && all(s).any((x) => x.file == file);

  /// Sets seen in my chats but not added (tip 79 "둘러보기"): file -> (name,
  /// count, times seen). Kept on the phone only.
  static const seenKey = 'sticker_sets_seen';

  static Map<String, (String, int, int)> seen(AppState s) {
    try {
      final m = jsonDecode(s.pref(seenKey, '{}')) as Map;
      return {
        for (final e in m.entries)
          if (e.value is List && (e.value as List).length == 3)
            '${e.key}': ('${(e.value as List)[0]}', ((e.value as List)[1] as num).toInt(), ((e.value as List)[2] as num).toInt()),
      };
    } catch (_) {
      return const {};
    }
  }

  static final _counted = <String>{};

  /// A set card went by in a chat (counted once per message).
  static Future<void> noteSeen(AppState s, String messageId, String file, String name, int count) async {
    if (file.isEmpty || !_counted.add(messageId)) return;
    final m = {...seen(s)};
    final old = m[file];
    m[file] = (name, count, (old?.$3 ?? 0) + 1);
    final keep = m.entries.toList()..sort((a, b) => b.value.$3.compareTo(a.value.$3));
    await s.setPref(
      seenKey,
      jsonEncode({
        for (final e in keep.take(40)) e.key: [e.value.$1, e.value.$2, e.value.$3],
      }),
    );
  }
}

/// Link to a shared set: `https://host/s#f=file/// Link to a shared set: https://<host>/s#f=<file, base64url>&n=<name>.n=name` (file in base64url).
/// Everything after '#' stays on the phone.
class StickerSetLink {
  const StickerSetLink(this.file, this.name);
  final String file;
  final String name;

  String get url => 'https://${Brand.linkHost}/s#f=${base64Url.encode(utf8.encode(file)).replaceAll('=', '')}&n=${Uri.encodeComponent(name)}';

  static StickerSetLink? parse(String text) {
    final h = RegExp.escape(Brand.linkHost);
    final m = RegExp('(?:https?://)?$h/s#(\\S+)').firstMatch(text.trim());
    if (m == null) return null;
    try {
      final q = Uri.splitQueryString(m.group(1)!);
      var f = q['f'] ?? '';
      f = f.padRight((f.length + 3) ~/ 4 * 4, '=');
      final file = utf8.decode(base64Url.decode(f));
      // Only a real encrypted-file reference (mxc place + AES key) goes on.
      final clean = Doc.cleanFile(jsonDecode(file));
      if (clean == null) return null;
      return StickerSetLink(jsonEncode(clean), cleanName(q['n'] ?? ''));
    } catch (_) {
      return null;
    }
  }
}
