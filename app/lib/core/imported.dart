// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기: what an import card holds once a phone opened it
// (engine/src/import.rs checks it), and how its messages show in the chat.
import 'dart:convert';

import 'backend.dart';

/// One writer of an imported chat: their name in the other app, and the
/// Burumy account behind it ("" = only the name is known).
class ImportPerson {
  const ImportPerson(this.name, this.id);
  final String name;
  final String id;
}

/// Marks a message as brought in from another app (shown "가져옴 7:30").
class ImportMark {
  const ImportMark({
    required this.app,
    required this.cardId,
    required this.name,
    this.file,
    this.thumb,
    this.mime = '',
    this.fileName = '',
    this.size = 0,
    this.missing = '',
  });

  /// kakao, whatsapp, telegram
  final String app;
  final String cardId;

  /// The writer's name in the other app.
  final String name;

  /// Encrypted file reference (JSON) of a photo, video, voice or file.
  final String? file;
  final String? thumb;
  final String mime;
  final String fileName;
  final int size;

  /// For kind "missing": what the other app left out (image, video, …).
  final String missing;
}

class ImportedChat {
  const ImportedChat({required this.app, required this.title, required this.by, required this.people, required this.items});

  factory ImportedChat.fromJson(Map<String, Object?> j) => ImportedChat(
    app: '${j['app'] ?? ''}',
    title: '${j['title'] ?? ''}',
    by: '${j['by'] ?? ''}',
    people: [
      for (final p in (j['people'] is List ? j['people'] as List : const []))
        if (p is Map) ImportPerson('${p['name'] ?? ''}', '${p['id'] ?? ''}'),
    ],
    items: [
      for (final x in (j['items'] is List ? j['items'] as List : const []))
        if (x is Map) x.cast<String, Object?>(),
    ],
  );

  final String app;
  final String title;

  /// Who brought it in.
  final String by;
  final List<ImportPerson> people;

  /// Checked wire items (t, p, k, b, f, th, m, n, s, r, fw, e, mk).
  final List<Map<String, Object?>> items;

  static String msgId(String cardId, int i) => 'imp:$cardId:$i';
  static bool isImported(String id) => id.startsWith('imp:');

  /// The messages as chat bubbles, oldest first. [me]: my user id.
  List<Msg> toMsgs(String cardId, String? me) {
    final out = <Msg>[];
    for (final (i, x) in items.indexed) {
      final p = x['p'] is int ? x['p'] as int : -1;
      final person = p >= 0 && p < people.length ? people[p] : null;
      final id = person?.id ?? '';
      final kind = '${x['k']}';
      final r = x['r'];
      String? ref(Object? v) => v is Map ? jsonEncode(v) : null;
      out.add(
        Msg(
          id: msgId(cardId, i),
          sender: id.isNotEmpty ? id : 'imp:$cardId:p$p',
          body: '${x['b'] ?? ''}',
          time: DateTime.fromMillisecondsSinceEpoch(x['t'] is int ? x['t'] as int : 0),
          mine: id.isNotEmpty && id == me,
          kind: kind,
          replyTo: r is int ? msgId(cardId, r) : null,
          edited: x['e'] == true,
          forwarded: x['fw'] == true,
          imported: ImportMark(
            app: app,
            cardId: cardId,
            name: person?.name ?? '',
            file: ref(x['f']),
            thumb: ref(x['th']),
            mime: '${x['m'] ?? ''}',
            fileName: '${x['n'] ?? ''}',
            size: x['s'] is int ? x['s'] as int : 0,
            missing: '${x['mk'] ?? ''}',
          ),
        ),
      );
    }
    return out;
  }
}

/// Puts imported messages among the chat's own ones, by time. [loaded]:
/// the chat's messages (oldest first); [complete]: the chat's whole
/// history is loaded, so imported messages older than all of it show too
/// (the newest [olderLimit] of them, more as the person scrolls up).
List<Msg> mergeImported(List<Msg> loaded, List<Msg> imported, {required bool complete, int olderLimit = 300}) {
  if (imported.isEmpty) return loaded;
  final oldest = loaded.isEmpty ? null : loaded.first.time;
  final inside = <Msg>[];
  final older = <Msg>[];
  for (final m in imported) {
    if (oldest != null && !m.time.isBefore(oldest)) {
      inside.add(m);
    } else {
      older.add(m);
    }
  }
  final shownOlder = complete ? older.sublist(older.length > olderLimit ? older.length - olderLimit : 0) : const <Msg>[];
  final all = [...shownOlder, ...loaded, ...inside];
  // Stable by time: same-second messages keep their order.
  final idx = {for (final (i, m) in all.indexed) m.id: i};
  all.sort((a, b) {
    final c = a.time.compareTo(b.time);
    return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
  });
  return all;
}

/// The look-only demo and tests check parts the way the engine does
/// (engine/src/import.rs is the real check on phones).
Map<String, Object?> demoAssembleImport(List<Map<String, Object?>> parts, int sent, Map<int, String> who) {
  final people = [
    for (final n in (parts.isNotEmpty && parts.first['people'] is List ? parts.first['people'] as List : const []).take(5000))
      '$n'.replaceAll('\n', ' ').characters64,
  ];
  const kinds = ['text', 'image', 'video', 'audio', 'file', 'system', 'deleted', 'missing'];
  const media = ['image', 'video', 'audio', 'file'];
  final keep = <(int, Map<String, Object?>)>[];
  var i = 0;
  for (final part in parts) {
    for (final v in (part['items'] is List ? part['items'] as List : const []).take(10000)) {
      final at = i++;
      if (v is! Map) continue;
      final t = v['t'];
      final k = '${v['k'] ?? 'text'}';
      final p = v['p'];
      if (t is! int || t < 946684800000 || t > sent + 86400000 || !kinds.contains(k)) continue;
      final pOk = p is int && p >= 0 && p < people.length;
      if (k != 'system' && !pOk) continue;
      final b = '${v['b'] ?? ''}';
      final out = <String, Object?>{'t': t, 'k': k, 'b': b.length > 10000 ? b.substring(0, 10000) : b};
      if (pOk) out['p'] = p;
      if (media.contains(k)) {
        final f = v['f'];
        if (f is Map && '${f['url']}'.startsWith('mxc://')) {
          out['f'] = f;
          if (v['th'] is Map) out['th'] = v['th'];
          out['m'] = '${v['m'] ?? ''}';
          out['n'] = '${v['n'] ?? ''}';
          out['s'] = v['s'] is int ? v['s'] : 0;
        } else {
          out['k'] = 'missing';
          out['mk'] = k;
        }
      }
      if (out['k'] == 'missing') out['mk'] ??= v['mk'] ?? 'file';
      final r = v['r'];
      if (r is int && r < at) out['r'] = r;
      if (v['fw'] == true) out['fw'] = true;
      if (v['e'] == true) out['e'] = true;
      keep.add((at, out));
    }
  }
  keep.sort((a, b) {
    final c = (a.$2['t'] as int).compareTo(b.$2['t'] as int);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  final moved = {for (final (n, e) in keep.indexed) e.$1: n};
  final items = [
    for (final e in keep) {...e.$2, if (e.$2['r'] is int) 'r': moved[e.$2['r']]}..removeWhere((k, v) => k == 'r' && v == null),
  ];
  return {
    'people': [
      for (final (n, name) in people.indexed) {'name': name, 'id': who[n] ?? ''},
    ],
    'items': items,
  };
}

extension on String {
  String get characters64 => length > 64 ? substring(0, 64) : this;
}
