// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기 (Telegram tips 244 + 254, Eric 2026-11-27 "같이 해
// 줘" + Telegram): reads a chat that KakaoTalk, WhatsApp or Telegram
// exported, on this phone only. Nothing here touches the network; the
// result goes to core/chat_import_send.dart, which encrypts it on the phone.
//
// Formats were written from what the apps' own export files look like
// (help pages + sample exports we made ourselves), not from anyone's code.
// The Korean words below are the words those apps write into their files
// (dates, "사진", "님이 들어왔습니다"), not screen text.
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:archive/archive.dart';

enum ImportApp { kakao, whatsapp, telegram }

/// One message read from an export file.
class ImportItem {
  ImportItem({
    required this.time,
    required this.from,
    required this.kind,
    this.body = '',
    this.media,
    this.replyTo,
    this.forwarded = false,
    this.edited = false,
  });

  DateTime time;

  /// The writer's name as the other app showed it ('' for app notices).
  final String from;

  /// text, image, video, audio, file, sticker, system, deleted, missing
  /// ("missing" = a photo or file the export left out; [body] says which).
  String kind;
  String body;

  /// Path of the photo / file inside the export (zip entry name).
  String? media;

  /// Telegram only: index (in the same chat) of the message this answers.
  int? replyTo;
  final bool forwarded;
  final bool edited;

  /// For "missing": image, video, audio, file or sticker.
  String missingKind = '';
}

/// A chat read from an export, before it is sent anywhere.
class ParsedChat {
  ParsedChat({required this.app, required this.title, required this.items});
  final ImportApp app;
  String title;
  final List<ImportItem> items;

  /// Writers, most messages first.
  List<String> get people {
    final n = <String, int>{};
    for (final x in items) {
      if (x.from.isNotEmpty && x.kind != 'system') n[x.from] = (n[x.from] ?? 0) + 1;
    }
    return n.keys.toList()..sort((a, b) => n[b]!.compareTo(n[a]!));
  }

  Map<String, int> get counts {
    final n = <String, int>{};
    for (final x in items) {
      if (x.from.isNotEmpty && x.kind != 'system') n[x.from] = (n[x.from] ?? 0) + 1;
    }
    return n;
  }

  int get mediaCount => items.where((x) => x.media != null).length;
  int get missingCount => items.where((x) => x.kind == 'missing').length;
  DateTime? get first => items.isEmpty ? null : items.first.time;
  DateTime? get last => items.isEmpty ? null : items.last.time;
}

/// Names (and sizes) of the files that came with the chat. Plain data, so
/// a chat can be read on another thread (isolate) with it.
class ImportNames {
  ImportNames(this.sizes);
  ImportNames.none() : sizes = const {};
  final Map<String, int> sizes;

  bool has(String name) => sizes.containsKey(name);
  Iterable<String> get names => sizes.keys;
  int sizeOf(String name) => sizes[name] ?? 0;

  /// Entry for a short name, matching the end of a path ("IMG-1.jpg" finds
  /// "chat/IMG-1.jpg"); exact paths first.
  String? find(String name) {
    if (sizes.containsKey(name)) return name;
    final n = name.replaceAll('\\', '/');
    if (sizes.containsKey(n)) return n;
    for (final k in sizes.keys) {
      if (k.endsWith('/$n')) return k;
    }
    return null;
  }
}

/// Files that came with the chat (zip entries), read only when needed.
class ImportFiles extends ImportNames {
  ImportFiles(this._entries) : super({for (final e in _entries.entries) e.key: e.value.size});
  ImportFiles.none() : _entries = const {}, super(const {});
  final Map<String, ArchiveFile> _entries;

  Uint8List? read(String name) {
    final f = _entries[name];
    if (f == null) return null;
    try {
      return f.readBytes();
    } catch (_) {
      return null;
    }
  }
}

/// Everything read from what the person picked.
class ImportBundle {
  ImportBundle({required this.chats, required this.files});

  /// Usually one; a whole-account Telegram export holds many.
  final List<ParsedChat> chats;
  final ImportFiles files;
}

/// Why a file could not be read.
class ImportError implements Exception {
  const ImportError(this.code);

  /// unknown (not a chat export), empty (no messages), big (too large),
  /// broken (damaged zip / json)
  final String code;
  @override
  String toString() => 'ImportError($code)';
}

/// Biggest export we read (bytes); a phone can't hold more in memory safely.
const importMaxBytes = 1024 * 1024 * 1024;

/// Most messages in one import (the engine keeps the same limit).
const importMaxItems = 300000;

class ChatImport {
  const ChatImport._();

  /// Reads a picked file. [name] is its file name (extension decides how).
  static ImportBundle read(String name, Uint8List bytes) {
    if (bytes.length > importMaxBytes) throw const ImportError('big');
    final lower = name.toLowerCase();
    if (_isZip(name, bytes)) {
      final Archive a;
      try {
        a = ZipDecoder().decodeBytes(bytes);
      } catch (_) {
        throw const ImportError('broken');
      }
      return fromArchive(a);
    }
    final text = decodeText(bytes);
    if (lower.endsWith('.json') || text.trimLeft().startsWith('{')) {
      return _checkMedia(ImportBundle(chats: telegramJson(text), files: ImportFiles.none()));
    }
    if (lower.endsWith('.html') || lower.endsWith('.htm') || text.contains('class="message')) {
      return _checkMedia(
        ImportBundle(
          chats: [
            telegramHtml([text]),
          ],
          files: ImportFiles.none(),
        ),
      );
    }
    return ImportBundle(
      chats: [textChat(text, fileName: name)],
      files: ImportFiles.none(),
    );
  }

  /// Same as [read] for a whole picked file, with the slow part (reading
  /// a long chat) on another thread so the screen keeps moving. [archive]:
  /// an already opened zip (phones open big zips from disk, not memory).
  static Future<ImportBundle> readInBackground(String name, Uint8List? bytes, {Archive? archive}) async {
    if (archive == null && bytes != null && !_isZip(name, bytes)) {
      return _readOff(name, bytes);
    }
    final Archive a;
    try {
      a = archive ?? ZipDecoder().decodeBytes(bytes!);
    } catch (_) {
      throw const ImportError('broken');
    }
    // The zip stays here; only its chat text goes to the other thread.
    final entries = _entries(a);
    final files = ImportFiles(entries);
    final names = ImportNames(Map.of(files.sizes));
    final pick = _chatEntries(entries.keys.toList(), (k) => entries[k]!.size);
    if (pick == null) throw const ImportError('unknown');
    final texts = [for (final k in pick.$2) decodeText(entries[k]!.readBytes() ?? Uint8List(0))];
    final chats = await _parseOff(pick.$1, pick.$2, texts, names);
    return _checkMedia(ImportBundle(chats: chats, files: files));
  }

  // Own functions so the other thread gets only these values (a closure
  // would carry everything around it, open zips and screens included).
  static Future<ImportBundle> _readOff(String name, Uint8List bytes) async => kIsWeb ? read(name, bytes) : Isolate.run(() => read(name, bytes));
  static Future<List<ParsedChat>> _parseOff(String how, List<String> keys, List<String> texts, ImportNames names) =>
      kIsWeb ? Future.value(_parseEntries(how, keys, texts, names)) : Isolate.run(() => _parseEntries(how, keys, texts, names));

  static bool _isZip(String name, Uint8List bytes) =>
      name.toLowerCase().endsWith('.zip') || (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4b && bytes[2] == 3 && bytes[3] == 4);

  static Map<String, ArchiveFile> _entries(Archive a) => {
    for (final f in a.files)
      if (f.isFile && !f.name.startsWith('__MACOSX/') && !f.name.split('/').last.startsWith('._')) f.name.replaceAll('\\', '/'): f,
  };

  /// Which entries hold the chat: ("json" | "html" | "text", entry names).
  static (String, List<String>)? _chatEntries(List<String> keys, int Function(String) size) {
    final json = keys.where((k) => k.split('/').last == 'result.json').toList()..sort((a, b) => a.length.compareTo(b.length));
    if (json.isNotEmpty) return ('json', [json.first]);
    int n(String s) => int.tryParse(RegExp(r'messages(\d*)\.html$').firstMatch(s)!.group(1)!) ?? 1;
    final html = keys.where((k) => RegExp(r'(^|/)messages\d*\.html$').hasMatch(k)).toList()..sort((a, b) => n(a).compareTo(n(b)));
    if (html.isNotEmpty) return ('html', html);
    final texts = keys.where((k) => k.toLowerCase().endsWith('.txt') || k.toLowerCase().endsWith('.csv')).toList();
    if (texts.isEmpty) return null;
    // The chat file is the biggest text file.
    texts.sort((a, b) => size(b).compareTo(size(a)));
    return ('text', [texts.first]);
  }

  static List<ParsedChat> _parseEntries(String how, List<String> keys, List<String> texts, ImportNames names) {
    final first = keys.first;
    final base = first.contains('/') ? first.substring(0, first.lastIndexOf('/') + 1) : '';
    void place(List<ParsedChat> chats) {
      for (final c in chats) {
        for (final x in c.items) {
          if (x.media != null) x.media = names.find('$base${x.media}') ?? names.find(x.media!) ?? x.media;
        }
      }
    }

    switch (how) {
      case 'json':
        final chats = telegramJson(texts.first);
        place(chats);
        return chats;
      case 'html':
        final chats = [telegramHtml(texts)];
        place(chats);
        return chats;
      default:
        return [textChat(texts.first, fileName: first.split('/').last, files: names)];
    }
  }

  /// A zip: Telegram folder (result.json / messages.html), WhatsApp
  /// ("_chat.txt" + media) or KakaoTalk (Talk_*.txt + media).
  static ImportBundle fromArchive(Archive a) {
    final entries = _entries(a);
    final files = ImportFiles(entries);
    final pick = _chatEntries(entries.keys.toList(), (k) => entries[k]!.size);
    if (pick == null) throw const ImportError('unknown');
    final texts = [for (final k in pick.$2) decodeText(entries[k]!.readBytes() ?? Uint8List(0))];
    return _checkMedia(ImportBundle(chats: _parseEntries(pick.$1, pick.$2, texts, files), files: files));
  }

  /// Media the export points at but did not include become "missing".
  static ImportBundle _checkMedia(ImportBundle b) {
    for (final c in b.chats) {
      for (final x in c.items) {
        if (x.media != null && !b.files.has(x.media!)) {
          x.missingKind = x.kind;
          x.kind = 'missing';
          x.media = null;
        }
      }
    }
    return b;
  }

  /// UTF-8 (with or without the mark at the start); UTF-16 when the file
  /// says so. Broken letters become "�" instead of stopping the import.
  static String decodeText(Uint8List b) {
    if (b.length >= 2 && b[0] == 0xff && b[1] == 0xfe) {
      return String.fromCharCodes(Uint16List.view(Uint8List.fromList(b.sublist(2 + (b.length % 2))).buffer));
    }
    var s = utf8.decode(b, allowMalformed: true);
    if (s.startsWith('\uFEFF')) s = s.substring(1);
    return s;
  }

  /// A plain text (or csv) chat: KakaoTalk or WhatsApp, whichever reads more lines.
  static ParsedChat textChat(String text, {String fileName = '', ImportNames? files}) {
    final k = kakao(text, files: files);
    final w = whatsapp(text, fileName: fileName, files: files);
    final best = k.items.length >= w.items.length ? k : w;
    if (best.items.isEmpty) throw ImportError(text.trim().isEmpty ? 'empty' : 'unknown');
    return best;
  }

  // ───────────────────────── shared bits ─────────────────────────

  static final _lrm = RegExp('[\u200e\u200f\u202a-\u202e\u2066-\u2069\uFEFF]');
  static String clean(String s) => s.replaceAll(_lrm, '').replaceAll('\r', '');

  /// Hour from "오후 3" / "3 PM" / "15".
  static int hour24(int h, String? ampm) {
    if (ampm == null || ampm.isEmpty) return h;
    final pm = ampm == '오후' || ampm.toUpperCase().startsWith('P') || ampm == '午後' || ampm == '下午';
    if (pm && h < 12) return h + 12;
    if (!pm && h == 12) return 0;
    return h;
  }

  static int year(String y) {
    final n = int.parse(y);
    return n < 100 ? 2000 + n : n;
  }

  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6, //
    'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };
  static int? month(String m) => _months[m.toLowerCase().substring(0, m.length < 3 ? m.length : 3)];

  static DateTime? at(int y, int mo, int d, int h, int mi, [int s = 0]) {
    if (mo < 1 || mo > 12 || d < 1 || d > 31 || h > 23 || mi > 59 || s > 59) return null;
    return DateTime(y, mo, d, h, mi, s);
  }

  static ImportItem? _last(List<ImportItem> l) => l.isEmpty ? null : l.last;

  // ───────────────────────── KakaoTalk ─────────────────────────

  // Phone: "2024. 1. 2. 오후 3:04, 홍길동 : 안녕" / "2024년 1월 2일 오후 3:04, …"
  static final _kPhone = RegExp(r'^(\d{4})[.년]\s*(\d{1,2})[.월]\s*(\d{1,2})[.일]?\s*(오전|오후)?\s*(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(오전|오후)?\s*[,:]\s?(.*)$');
  // Phone, English: "Jan 2, 2024 at 3:04 PM, John : hi" / "January 2, 2024, 3:04 PM, John : hi"
  static final _kPhoneEn = RegExp(r'^([A-Za-z]{3,9})\.? (\d{1,2}), (\d{4})(?:,| at) (\d{1,2}):(\d{2})(?::(\d{2}))? ?([AaPp][Mm])?,\s?(.*)$');
  // PC: "--------------- 2024년 1월 2일 화요일 ---------------"
  static final _kDay = RegExp(r'^-{3,}\s*(\d{4})년\s*(\d{1,2})월\s*(\d{1,2})일.*-{3,}\s*$');
  static final _kDayEn = RegExp(r'^-{3,}\s*(?:[A-Za-z]+, )?([A-Za-z]{3,9}) (\d{1,2}), (\d{4})\s*-{3,}\s*$');
  // PC: "[홍길동] [오후 3:04] 안녕" / "[John] [3:04 PM] hi"
  static final _kPc = RegExp(r'^\[(.+?)\] \[(오전|오후)?\s?(\d{1,2}):(\d{2})\s?([AaPp][Mm])?\] ?(.*)$');
  // CSV (Mac / newer phones): "2024-01-02 15:04:00,"홍길동","안녕""
  static final _kCsv = RegExp(r'^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}),');
  // A day line on phones ("2024년 1월 2일 화요일") — not a message.
  static final _kDayPhone = RegExp(r'^(\d{4})[.년]\s*(\d{1,2})[.월]\s*(\d{1,2})[.일]?\s*\S*요일\s*$');
  static final _kTitle = RegExp(r'^(.*?)\s*(?:님과 카카오톡 대화|카카오톡 대화)\s*$');
  static final _kTitleEn = RegExp(r'^(?:KakaoTalk Chats with|Talk with)\s+(.+)$');

  static const _kSystem = [
    '님이 들어왔습니다', '님이 나갔습니다', '님을 초대했습니다', '님을 초대하였습니다', '님을 내보냈습니다', //
    '채팅방 관리자가', '님이 방장', 'joined this chatroom', 'left this chatroom', 'invited',
  ];

  static ParsedChat kakao(String text, {ImportNames? files}) {
    final lines = const LineSplitter().convert(clean(text));
    var title = '';
    final items = <ImportItem>[];
    var start = 0;
    for (var i = 0; i < lines.length && i < 4; i++) {
      final t = _kTitle.firstMatch(lines[i].trim()) ?? _kTitleEn.firstMatch(lines[i].trim());
      if (t != null) {
        title = t.group(1)!.trim();
        start = i + 1;
        break;
      }
    }
    // Group titles end with the member count ("친구들 5").
    title = title.replaceFirst(RegExp(r'\s+\d+$'), '');
    if (lines.isNotEmpty && lines.first.startsWith('Date,User,Message')) return _kakaoCsv(text, title);
    DateTime? day;
    for (var i = start; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('저장한 날짜') || line.startsWith('Date Saved')) continue;
      final d = _kDay.firstMatch(line);
      if (d != null) {
        day = DateTime(int.parse(d.group(1)!), int.parse(d.group(2)!), int.parse(d.group(3)!));
        continue;
      }
      final de = _kDayEn.firstMatch(line);
      if (de != null && month(de.group(1)!) != null) {
        day = DateTime(int.parse(de.group(3)!), month(de.group(1)!)!, int.parse(de.group(2)!));
        continue;
      }
      if (_kDayPhone.hasMatch(line.trim())) continue;
      final pc = _kPc.firstMatch(line);
      if (pc != null && day != null) {
        final t = at(day.year, day.month, day.day, hour24(int.parse(pc.group(3)!), pc.group(2) ?? pc.group(5)), int.parse(pc.group(4)!));
        if (t != null) {
          items.add(_kakaoItem(t, pc.group(1)!.trim(), pc.group(6)!));
          continue;
        }
      }
      final m = _kPhone.firstMatch(line);
      if (m != null) {
        final t = at(
          int.parse(m.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
          hour24(int.parse(m.group(5)!), m.group(4) ?? m.group(8)),
          int.parse(m.group(6)!),
          int.tryParse(m.group(7) ?? '') ?? 0,
        );
        if (t != null) {
          _kakaoRest(items, t, m.group(9)!);
          continue;
        }
      }
      final e = _kPhoneEn.firstMatch(line);
      if (e != null && month(e.group(1)!) != null) {
        final t = at(
          int.parse(e.group(3)!),
          month(e.group(1)!)!,
          int.parse(e.group(2)!),
          hour24(int.parse(e.group(4)!), e.group(7)),
          int.parse(e.group(5)!),
          int.tryParse(e.group(6) ?? '') ?? 0,
        );
        if (t != null) {
          _kakaoRest(items, t, e.group(8)!);
          continue;
        }
      }
      // A line of a longer message.
      final prev = _last(items);
      if (prev != null && prev.kind == 'text') prev.body = '${prev.body}\n$line';
    }
    for (final x in items) {
      x.body = x.body.trimRight();
    }
    items.removeWhere((x) => x.kind == 'text' && x.body.isEmpty);
    if (files != null) _kakaoMedia(items, files);
    return ParsedChat(app: ImportApp.kakao, title: title, items: items);
  }

  /// "홍길동 : 안녕" after the time, or a notice ("홍길동님이 들어왔습니다.").
  static void _kakaoRest(List<ImportItem> items, DateTime t, String rest) {
    final i = rest.indexOf(' : ');
    if (i > 0) {
      items.add(_kakaoItem(t, rest.substring(0, i).trim(), rest.substring(i + 3)));
    } else if (rest.trim().isNotEmpty) {
      items.add(ImportItem(time: t, from: '', kind: 'system', body: rest.trim()));
    }
  }

  static ImportItem _kakaoItem(DateTime t, String from, String body) {
    final b = body.trim();
    String? missing;
    var name = '';
    if (RegExp(r'^(사진|Photo)( \d+장| \d+ photos?)?$').hasMatch(b)) missing = 'image';
    if (b == '동영상' || b == 'Video') missing = 'video';
    if (b == '음성메시지' || b == 'Voice Note' || b == 'Voice Message') missing = 'audio';
    if (b == '이모티콘' || b == 'Emoticons' || b == '(이모티콘)') missing = 'sticker';
    final f = RegExp(r'^(?:파일|File): (.+)$').firstMatch(b);
    if (f != null) {
      missing = 'file';
      name = f.group(1)!.trim();
    }
    if (b == '삭제된 메시지입니다.' || b == 'This message has been deleted.' || b == 'Message deleted.') {
      return ImportItem(time: t, from: from, kind: 'deleted');
    }
    if (from.isEmpty || (_kSystem.any(b.contains) && !b.contains('\n') && b.length < 80 && from == '')) {
      return ImportItem(time: t, from: '', kind: 'system', body: b);
    }
    if (missing != null) {
      return ImportItem(time: t, from: from, kind: 'missing', body: name)..missingKind = missing;
    }
    return ImportItem(time: t, from: from, kind: 'text', body: body);
  }

  /// "Date,User,Message" files; a message may span lines inside quotes.
  static ParsedChat _kakaoCsv(String text, String title) {
    final items = <ImportItem>[];
    final rows = _csv(clean(text));
    for (final r in rows.skip(1)) {
      if (r.length < 3) continue;
      final m = _kCsv.firstMatch('${r[0]},');
      if (m == null) continue;
      final t = at(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
      if (t == null) continue;
      final from = r[1].trim();
      final body = r.sublist(2).join(',');
      items.add(from.isEmpty ? ImportItem(time: t, from: '', kind: 'system', body: body.trim()) : _kakaoItem(t, from, body));
    }
    return ParsedChat(app: ImportApp.kakao, title: title, items: items);
  }

  static List<List<String>> _csv(String s) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (quoted) {
        if (c == '"') {
          if (i + 1 < s.length && s[i + 1] == '"') {
            cell.write('"');
            i++;
          } else {
            quoted = false;
          }
        } else {
          cell.write(c);
        }
      } else if (c == '"') {
        quoted = true;
      } else if (c == ',') {
        row.add(cell.toString());
        cell.clear();
      } else if (c == '\n') {
        row.add(cell.toString());
        cell.clear();
        rows.add(row);
        row = <String>[];
      } else {
        cell.write(c);
      }
    }
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }

  /// KakaoTalk's "save everything" export puts photos next to the text,
  /// named by the time they were sent (…_20240102_150412…). A "사진" line
  /// takes the unused file whose time is within its minute.
  static void _kakaoMedia(List<ImportItem> items, ImportNames files) {
    final stamp = RegExp(r'(\d{4})-?(\d{2})-?(\d{2})[_\- ](\d{2})-?(\d{2})-?(\d{2})');
    final pool = <(DateTime, String, String)>[];
    for (final n in files.names) {
      final base = n.split('/').last;
      final kind = mediaKind(base);
      if (kind == null) continue;
      final m = stamp.firstMatch(base);
      if (m == null) continue;
      final t = at(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
        int.parse(m.group(4)!),
        int.parse(m.group(5)!),
        int.parse(m.group(6)!),
      );
      if (t != null) pool.add((t, n, kind));
    }
    if (pool.isEmpty) return;
    pool.sort((a, b) => a.$1.compareTo(b.$1) != 0 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    final used = <String>{};
    for (final x in items) {
      if (x.kind != 'missing' || x.missingKind == 'sticker') continue;
      final want = x.missingKind;
      final n = RegExp(r'(\d+)').firstMatch(x.body)?.group(1);
      final count = want == 'image' && n == null ? (int.tryParse(RegExp(r'(\d+)장').firstMatch(x.body)?.group(1) ?? '') ?? 1) : 1;
      var took = 0;
      final extra = <ImportItem>[];
      for (final p in pool) {
        if (took >= count) break;
        if (used.contains(p.$2)) continue;
        final dt = p.$1.difference(x.time).inSeconds;
        if (dt < 0 || dt >= 120) continue;
        if (want == 'file' ? p.$2.split('/').last != x.body && !p.$2.endsWith(x.body) : p.$3 != want) continue;
        used.add(p.$2);
        if (took == 0) {
          x.kind = want == 'file' ? 'file' : p.$3;
          x.media = p.$2;
          x.body = '';
        } else {
          extra.add(ImportItem(time: x.time, from: x.from, kind: p.$3, media: p.$2));
        }
        took++;
      }
      if (extra.isNotEmpty) items.insertAll(items.indexOf(x) + 1, extra);
    }
  }

  /// image / video / audio / file by a file name's ending; null = not media.
  static String? mediaKind(String name) {
    final e = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'].contains(e)) return 'image';
    if (const ['mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv', 'avi'].contains(e)) return 'video';
    if (const ['opus', 'ogg', 'oga', 'm4a', 'mp3', 'aac', 'wav', 'amr', 'flac'].contains(e)) return 'audio';
    if (e.isEmpty || e == 'txt' || e == 'json' || e == 'html' || e == 'csv' || e == 'css' || e == 'js') return null;
    return 'file';
  }

  static String mimeOf(String name) {
    final e = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return const {
          'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'gif': 'image/gif', 'webp': 'image/webp', //
          'heic': 'image/heic', 'heif': 'image/heif', 'bmp': 'image/bmp',
          'mp4': 'video/mp4', 'mov': 'video/quicktime', 'm4v': 'video/mp4', '3gp': 'video/3gpp', 'webm': 'video/webm', 'mkv': 'video/x-matroska',
          'opus': 'audio/ogg', 'ogg': 'audio/ogg', 'oga': 'audio/ogg', 'm4a': 'audio/mp4', 'mp3': 'audio/mpeg', 'aac': 'audio/aac',
          'wav': 'audio/wav', 'amr': 'audio/amr', 'flac': 'audio/flac',
          'pdf': 'application/pdf', 'vcf': 'text/vcard', 'zip': 'application/zip',
        }[e] ??
        'application/octet-stream';
  }

  // ───────────────────────── WhatsApp ─────────────────────────

  // iPhone: "[1/2/24, 2:30:15 PM] John: hi" / "[2024. 1. 2. 오후 2:30:15] 홍길동: 안녕"
  static final _wIos = RegExp(r'^\[([^\]]{6,40}?)\] (.*)$');
  // Android: "1/2/24, 14:30 - John: hi" / "2024. 1. 2. 오후 2:30 - 홍길동: 안녕"
  static final _wAnd = RegExp(
    r'^(\d{1,4}[./\-]\s?\d{1,2}[./\-]\s?\d{1,4}\.?,?\s+(?:오전|오후|午前|午後|上午|下午)?\s?\d{1,2}[:.]\d{2}(?:[:.]\d{2})?\s?(?:[AaPp]\.?\s?[Mm]\.?)?) - (.*)$',
  );
  static final _wStamp = RegExp(
    r'^(\d{1,4})[./\-]\s?(\d{1,2})[./\-]\s?(\d{1,4})\.?,?\s+(오전|오후|午前|午後|上午|下午)?\s?(\d{1,2})[:.](\d{2})(?:[:.](\d{2}))?\s?([AaPp])?\.?\s?(?:[Mm]\.?)?$',
  );
  static final _wFile = RegExp(
    r'([\w\-. ()]+\.(?:jpe?g|png|webp|gif|heic|mp4|mov|3gp|opus|ogg|m4a|mp3|aac|amr|wav|pdf|docx?|xlsx?|pptx?|zip|txt|vcf|apk|hwp|csv))\b',
    caseSensitive: false,
  );
  static final _wOmitted = RegExp(
    r'^<?(?:Media omitted|미디어 (?:파일 )?(?:없음|생략됨|제외됨)|image omitted|video omitted|audio omitted|sticker omitted|document omitted|GIF omitted|사진 생략됨|동영상 생략됨|오디오 생략됨|스티커 생략됨|문서 생략됨)>?$',
    caseSensitive: false,
  );
  static final _wTitle = RegExp(r'(?:WhatsApp Chat (?:with|-) |WhatsApp 채팅 ?- ?|WhatsApp 채팅방 ?- ?)(.+?)(?:\.txt)?$', caseSensitive: false);

  static ParsedChat whatsapp(String text, {String fileName = '', ImportNames? files}) {
    final lines = const LineSplitter().convert(clean(text));
    final raw = <(String, String)>[];
    for (final line in lines) {
      final ios = _wIos.firstMatch(line);
      if (ios != null && _wStamp.hasMatch(ios.group(1)!.trim())) {
        raw.add((ios.group(1)!.trim(), ios.group(2)!));
        continue;
      }
      final a = _wAnd.firstMatch(line);
      if (a != null) {
        raw.add((a.group(1)!.trim(), a.group(2)!));
        continue;
      }
      if (raw.isNotEmpty) raw[raw.length - 1] = (raw.last.$1, '${raw.last.$2}\n$line');
    }
    // Day and month order: whichever spot goes past 12 is the day.
    var dayFirst = false, yearFirst = false;
    var seen = false;
    for (final r in raw) {
      final m = _wStamp.firstMatch(r.$1);
      if (m == null) continue;
      final a = int.parse(m.group(1)!), b = int.parse(m.group(2)!);
      if (m.group(1)!.length == 4) {
        yearFirst = true;
        seen = true;
        break;
      }
      if (a > 12) {
        dayFirst = true;
        seen = true;
        break;
      }
      if (b > 12) {
        dayFirst = false;
        seen = true;
        break;
      }
    }
    if (!seen && raw.isNotEmpty) {
      // No hint: 12-hour clocks are mostly US (month first), else day first.
      dayFirst = !RegExp(r'[AaPp]\.?\s?[Mm]').hasMatch(raw.first.$1);
    }
    final items = <ImportItem>[];
    for (final r in raw) {
      final m = _wStamp.firstMatch(r.$1);
      if (m == null) continue;
      final n1 = int.parse(m.group(1)!), n2 = int.parse(m.group(2)!), n3 = int.parse(m.group(3)!);
      final (y, mo, d) = yearFirst ? (n1, n2, n3) : (dayFirst ? (year('$n3'), n2, n1) : (year('$n3'), n1, n2));
      final ap = m.group(4) ?? (m.group(8) == null ? null : '${m.group(8)}M');
      final t = at(y, mo, d, hour24(int.parse(m.group(5)!), ap), int.parse(m.group(6)!), int.tryParse(m.group(7) ?? '') ?? 0);
      if (t == null) continue;
      final rest = r.$2;
      final i = rest.indexOf(': ');
      if (i <= 0 || rest.substring(0, i).contains('\n')) {
        items.add(ImportItem(time: t, from: '', kind: 'system', body: rest.trim()));
        continue;
      }
      items.add(_waItem(t, rest.substring(0, i).trim(), rest.substring(i + 2), files));
    }
    // The first notice ("Messages and calls are end-to-end encrypted…") is WhatsApp's own.
    if (items.isNotEmpty && items.first.kind == 'system' && items.length > 1) items.removeAt(0);
    final title = _wTitle.firstMatch(fileName)?.group(1)?.trim() ?? '';
    return ParsedChat(app: ImportApp.whatsapp, title: title, items: items);
  }

  static ImportItem _waItem(DateTime t, String from, String body, ImportNames? files) {
    final b = body.trim();
    if (b == 'This message was deleted' || b == 'You deleted this message' || b == '삭제된 메시지입니다' || b == '메시지를 삭제했습니다') {
      return ImportItem(time: t, from: from, kind: 'deleted');
    }
    if (_wOmitted.hasMatch(b)) {
      final low = b.toLowerCase();
      final k = low.contains('image') || b.contains('사진')
          ? 'image'
          : low.contains('video') || low.contains('gif') || b.contains('동영상')
          ? 'video'
          : low.contains('audio') || b.contains('오디오')
          ? 'audio'
          : low.contains('sticker') || b.contains('스티커')
          ? 'sticker'
          : low.contains('document') || b.contains('문서')
          ? 'file'
          : 'image';
      return ImportItem(time: t, from: from, kind: 'missing')..missingKind = k;
    }
    // "<attached: 00000012-PHOTO-….jpg>" / "IMG-….jpg (file attached)" / "…jpg (파일 첨부됨)"
    final lines = b.split('\n');
    for (var li = 0; li < lines.length; li++) {
      final line = lines[li];
      final looksAttached = line.contains('attached') || line.contains('첨부') || line.startsWith('<') || line.contains('(file') || line.contains('(파일');
      if (!looksAttached && lines.length > 1) continue;
      for (final f in _wFile.allMatches(line)) {
        final name = f.group(1)!.trim().replaceFirst(RegExp(r'^(?:attached|첨부)[: ]\s*', caseSensitive: false), '');
        final hit = files?.find(name);
        if (hit == null && !looksAttached) continue;
        final kind = mediaKind(name) ?? 'file';
        final caption = [...lines.sublist(0, li), ...lines.sublist(li + 1)].join('\n').trim();
        if (hit == null) {
          return ImportItem(time: t, from: from, kind: 'missing', body: kind == 'file' ? name : '')..missingKind = kind;
        }
        return ImportItem(time: t, from: from, kind: kind, media: hit, body: caption);
      }
    }
    return ImportItem(time: t, from: from, kind: 'text', body: body.trimRight());
  }

  // ───────────────────────── Telegram ─────────────────────────

  /// result.json: one chat, or a whole-account export with chats.list.
  static List<ParsedChat> telegramJson(String text) {
    final Object? v;
    try {
      v = jsonDecode(text);
    } catch (_) {
      throw const ImportError('broken');
    }
    if (v is! Map) throw const ImportError('unknown');
    final list = <Map>[];
    if (v['messages'] is List) list.add(v);
    final chats = v['chats'];
    if (chats is Map && chats['list'] is List) {
      for (final c in chats['list'] as List) {
        if (c is Map && c['messages'] is List && (c['messages'] as List).isNotEmpty) list.add(c);
      }
    }
    if (list.isEmpty) throw const ImportError('unknown');
    final out = [for (final c in list) _tgChat(c)]..removeWhere((c) => c.items.isEmpty);
    if (out.isEmpty) throw const ImportError('empty');
    return out;
  }

  static ParsedChat _tgChat(Map c) {
    final items = <ImportItem>[];
    final byId = <Object?, int>{};
    final replies = <int, Object?>{};
    for (final m in c['messages'] as List) {
      if (m is! Map) continue;
      final ts = int.tryParse('${m['date_unixtime'] ?? ''}');
      final t = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts * 1000) : DateTime.tryParse('${m['date'] ?? ''}');
      if (t == null) continue;
      final from = '${m['from'] ?? m['actor'] ?? ''}'.trim();
      final text = _tgText(m['text']);
      if (m['type'] == 'service') {
        final action = '${m['action'] ?? ''}';
        final who = from.isEmpty ? '' : from;
        items.add(ImportItem(time: t, from: '', kind: 'system', body: _tgAction(action, who, m)));
        byId[m['id']] = items.length - 1;
        continue;
      }
      if (m['type'] != 'message') continue;
      String kind = 'text';
      String? media;
      var body = text;
      final photo = m['photo'], file = m['file'];
      final mt = '${m['media_type'] ?? ''}';
      if (photo is String) {
        kind = 'image';
        media = photo;
      } else if (file is String) {
        media = file;
        kind = switch (mt) {
          'voice_message' || 'audio_file' => 'audio',
          'video_file' || 'video_message' || 'animation' => 'video',
          'sticker' => (file.toLowerCase().endsWith('.webp') || file.toLowerCase().endsWith('.png')) ? 'image' : 'sticker',
          _ => mediaKind(file) ?? 'file',
        };
      }
      final notIncluded = media != null && (media.startsWith('(File') || media.contains('not included') || media.contains('exceeds maximum size'));
      ImportItem it;
      if (notIncluded || kind == 'sticker') {
        final k = kind == 'sticker' ? 'sticker' : kind;
        it = ImportItem(
          time: t,
          from: from,
          kind: 'missing',
          body: k == 'file' ? '${m['file_name'] ?? ''}' : body,
          forwarded: m['forwarded_from'] != null,
          edited: m['edited'] != null,
        )..missingKind = k;
        if (k == 'sticker' && body.isEmpty) it.body = '${m['sticker_emoji'] ?? ''}';
      } else {
        if (media == null && body.trim().isEmpty) {
          // Contact, place, poll…: keep what can be said in words.
          final p = m['poll'];
          if (p is Map) body = '${p['question'] ?? ''}';
          final loc = m['location_information'];
          if (loc is Map) body = '${loc['latitude']}, ${loc['longitude']}';
          final ct = m['contact_information'];
          if (ct is Map) body = '${ct['first_name'] ?? ''} ${ct['last_name'] ?? ''} ${ct['phone_number'] ?? ''}'.trim();
          if (body.trim().isEmpty) continue;
        }
        it = ImportItem(
          time: t,
          from: from,
          kind: kind,
          body: kind == 'file' && body.isEmpty ? '' : body,
          media: media,
          forwarded: m['forwarded_from'] != null,
          edited: m['edited'] != null,
        );
      }
      items.add(it);
      byId[m['id']] = items.length - 1;
      if (m['reply_to_message_id'] != null) replies[items.length - 1] = m['reply_to_message_id'];
    }
    for (final e in replies.entries) {
      final to = byId[e.value];
      if (to != null && to < e.key) items[e.key].replyTo = to;
    }
    return ParsedChat(app: ImportApp.telegram, title: '${c['name'] ?? ''}'.trim(), items: items);
  }

  static String _tgText(Object? t) {
    if (t is String) return t;
    if (t is List) {
      return t.map((x) => x is String ? x : (x is Map ? '${x['text'] ?? ''}' : '')).join();
    }
    return '';
  }

  /// Telegram notices as short codes the screen turns into words
  /// ("sys:join|홍길동"); unknown ones keep Telegram's own action word.
  static String _tgAction(String action, String who, Map m) => switch (action) {
    'create_group' || 'create_channel' || 'migrate_from_group' => 'sys:create|$who',
    'invite_members' || 'join_group_by_link' || 'join_group_by_request' => 'sys:join|$who',
    'remove_members' => 'sys:left|$who',
    'pin_message' => 'sys:pin|$who',
    'phone_call' || 'group_call' => 'sys:call|$who',
    'edit_group_title' => 'sys:title|$who|${m['title'] ?? ''}',
    'edit_group_photo' => 'sys:photo|$who',
    _ => 'sys:other|$who',
  };

  /// messages.html (and messages2.html …): Telegram Desktop's page export.
  static ParsedChat telegramHtml(List<String> pages) {
    final items = <ImportItem>[];
    var title = '';
    var lastFrom = '';
    final byId = <String, int>{};
    final replies = <int, String>{};
    final dateRe = RegExp(r'class="pull_right date details" title="(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})(?: UTC([+-]\d{2}):?(\d{2}))?"');
    for (final page in pages) {
      if (title.isEmpty) {
        final h = RegExp(r'<div class="text bold">\s*([\s\S]*?)\s*</div>').firstMatch(page);
        if (h != null) title = _unhtml(h.group(1)!).trim();
      }
      final blocks = page.split(RegExp(r'<div class="message '));
      for (final blk in blocks.skip(1)) {
        final id = RegExp(r'id="message(-?\d+)"').firstMatch(blk)?.group(1) ?? '';
        if (blk.startsWith('service')) {
          continue; // day lines and notices: dates come from each message
        }
        final d = dateRe.firstMatch(blk);
        if (d == null) continue;
        var t = DateTime.utc(
          int.parse(d.group(3)!),
          int.parse(d.group(2)!),
          int.parse(d.group(1)!),
          int.parse(d.group(4)!),
          int.parse(d.group(5)!),
          int.parse(d.group(6)!),
        );
        if (d.group(7) != null) {
          final off = Duration(hours: int.parse(d.group(7)!), minutes: int.parse(d.group(8)!) * (d.group(7)!.startsWith('-') ? -1 : 1));
          t = t.subtract(off).toLocal();
        } else {
          t = DateTime(t.year, t.month, t.day, t.hour, t.minute, t.second);
        }
        // "joined" blocks continue the previous writer.
        final fwd = blk.contains('class="forwarded body"');
        final main = fwd ? blk.split('class="forwarded body"').first : blk;
        final fromM = RegExp(r'<div class="from_name">\s*([\s\S]*?)\s*</div>').firstMatch(main);
        final from = fromM != null ? _unhtml(fromM.group(1)!.replaceAll(RegExp(r'<span[\s\S]*?</span>'), '')).trim() : lastFrom;
        lastFrom = from;
        final textM = RegExp(r'<div class="text">\s*([\s\S]*?)\s*</div>').firstMatch(blk);
        final text = textM == null ? '' : _unhtml(textM.group(1)!).trim();
        final href = RegExp(r'href="((?:photos|video_files|voice_messages|round_video_messages|files|stickers|audio_files|music)/[^"]+)"')
            .firstMatch(blk)
            ?.group(1);
        String kind = 'text';
        if (href != null) {
          kind = href.startsWith('photos/')
              ? 'image'
              : href.startsWith('voice_messages/') || href.startsWith('audio_files/') || href.startsWith('music/')
              ? 'audio'
              : href.startsWith('video_files/') || href.startsWith('round_video_messages/')
              ? 'video'
              : href.startsWith('stickers/')
              ? (href.endsWith('.webp') ? 'image' : 'sticker')
              : 'file';
        }
        if (href == null && text.isEmpty) continue;
        final it = kind == 'sticker'
            ? (ImportItem(time: t, from: from, kind: 'missing', body: text, forwarded: fwd)..missingKind = 'sticker')
            : ImportItem(time: t, from: from, kind: kind, body: text, media: href == null ? null : Uri.decodeFull(href), forwarded: fwd);
        items.add(it);
        if (id.isNotEmpty) byId[id] = items.length - 1;
        final r = RegExp(r'go_to_message(-?\d+)').firstMatch(blk)?.group(1);
        if (r != null) replies[items.length - 1] = r;
      }
    }
    for (final e in replies.entries) {
      final to = byId[e.value];
      if (to != null && to < e.key) items[e.key].replyTo = to;
    }
    if (items.isEmpty) throw const ImportError('unknown');
    return ParsedChat(app: ImportApp.telegram, title: title, items: items);
  }

  static String _unhtml(String s) => s
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ')
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m.group(1)!)))
      .replaceAll('&amp;', '&');
}

/// Names other apps give the exporting person ("나" in KakaoTalk, "You" in
/// WhatsApp, …): the check screen guesses that one is me.
const importSelfWords = {'나', 'me', 'you', '당신', 'ich', 'yo', 'moi', '我', '自分'};
