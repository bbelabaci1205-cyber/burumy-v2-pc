// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 문서 바로 보기 (Telegram tip 473, batch #10, 2026-11-27): files I open in
// a chat (PDF, plain text, photos sent as files) stay open as "tabs" when
// I tuck them away, so I can keep chatting and come back to them.
//
// Safety: the decrypted bytes live only in memory, never in a file, and
// every tab is dropped when the app locks, when I switch accounts or when
// I close it (rulebook: nothing decrypted left on the phone).
import 'package:flutter/foundation.dart';

import 'backend.dart';

/// What kind of file a name is (decides the viewer and the icon colour).
enum FileKind { pdf, text, image, video, audio, word, sheet, slides, archive, other }

String fileExt(String name) {
  final n = name.toLowerCase();
  final dot = n.lastIndexOf('.');
  return dot < 0 || dot == n.length - 1 ? '' : n.substring(dot + 1);
}

FileKind fileKindOf(String name) => switch (fileExt(name)) {
  'pdf' => FileKind.pdf,
  'txt' || 'md' || 'csv' || 'tsv' || 'json' || 'log' || 'xml' || 'yaml' || 'yml' || 'ini' || 'srt' || 'vtt' => FileKind.text,
  'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' || 'bmp' => FileKind.image,
  'mp4' || 'mov' || 'webm' || 'm4v' => FileKind.video,
  'mp3' || 'm4a' || 'wav' || 'aac' || 'ogg' || 'flac' => FileKind.audio,
  'doc' || 'docx' || 'hwp' || 'hwpx' || 'pages' || 'rtf' || 'odt' => FileKind.word,
  'xls' || 'xlsx' || 'numbers' || 'ods' => FileKind.sheet,
  'ppt' || 'pptx' || 'key' || 'odp' => FileKind.slides,
  'zip' || '7z' || 'rar' || 'tar' || 'gz' => FileKind.archive,
  _ => FileKind.other,
};

/// Burumy draws these itself (no other app, no website).
bool opensInApp(FileKind k) => k == FileKind.pdf || k == FileKind.text || k == FileKind.image;

/// Plain text bigger than this is cut (the rest: 다른 앱으로 열기).
const textViewMax = 2 * 1024 * 1024;

/// One open file.
class OpenDoc {
  OpenDoc({required this.roomId, required this.msg, required this.bytes, required this.chat, this.protected = false});
  final String roomId;
  final Msg msg;
  final Uint8List bytes;

  /// Chat name (shown on the tab card).
  final String chat;

  /// From a chat with 공유 비활성화: no saving, no other apps, no capture.
  final bool protected;

  /// PDF: the page I was on, and how many there are (0 = not known yet).
  int page = 1;
  int pages = 0;

  String get name => msg.body ?? 'file';
  String get id => msg.id;
  FileKind get kind => fileKindOf(name);
}

/// Up to [max] open files, newest first.
class OpenDocs extends ChangeNotifier {
  OpenDocs._();
  static final instance = OpenDocs._();

  /// Telegram keeps a handful; more would hold too much in memory.
  static const max = 5;

  final docs = <OpenDoc>[];

  OpenDoc? find(String eventId) => docs.where((d) => d.id == eventId).firstOrNull;

  /// Adds (or moves to the front). The oldest goes when there are too many.
  void add(OpenDoc d) {
    docs.removeWhere((x) => x.id == d.id);
    docs.insert(0, d);
    if (docs.length > max) docs.removeRange(max, docs.length);
    notifyListeners();
  }

  void close(String eventId) {
    docs.removeWhere((x) => x.id == eventId);
    notifyListeners();
  }

  /// App locked / account switched / 모두 닫기.
  void clear() {
    if (docs.isEmpty) return;
    docs.clear();
    notifyListeners();
  }
}
