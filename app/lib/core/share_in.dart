// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱에서 부루미로 보내기 (Telegram tips 350 + 182): photos, videos,
// files or words shared from another app's share sheet. The phone hands
// them over (Android: the share intent; iPhone: our share extension leaves
// them in the app's own shared folder); this app picks them up when it
// opens or comes back to the front, and asks where to send them. Nothing
// is sent anywhere before the person picks chats and presses 보내기.
import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'room_rules.dart';

/// One thing to send: a file (bytes) or words.
class SharedItem {
  const SharedItem({required this.name, required this.mime, this.bytes, this.path = '', this.text = ''});
  final String name, mime;

  /// In memory (web demo, tests); phones give [path] and it is read on send.
  final Uint8List? bytes;
  final String path;

  /// Shared words or a link (no file).
  final String text;

  bool get isText => bytes == null && path.isEmpty;

  /// The room rule this needs ('text', 'link', 'photo', 'video', ...).
  String get kind => isText ? (RegExp(r'https?://').hasMatch(text) ? 'link' : 'text') : RoomRules.kindOfFile(name);

  bool get isPhoto => kind == 'photo';
  bool get isVideo => kind == 'video';

  Future<Uint8List> read() async => bytes ?? (path.isEmpty ? Uint8List(0) : await File(path).readAsBytes());

  /// Removes the phone's temporary copy once it is sent (or given up).
  Future<void> drop() async {
    if (path.isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  static SharedItem? fromMap(Object? o) {
    if (o is! Map) return null;
    final text = (o['text'] as String?)?.trim() ?? '';
    final path = o['path'] as String? ?? '';
    if (text.isEmpty && path.isEmpty) return null;
    return SharedItem(name: o['name'] as String? ?? 'file', mime: o['mime'] as String? ?? 'application/octet-stream', path: path, text: text);
  }
}

/// Waiting shares, from the phone.
class ShareInbox {
  static const channel = MethodChannel('app.burumy/share');

  /// Look-only demo: what Settings > 다른 앱에서 보내기 체험 pretends was shared.
  static List<SharedItem>? demo;

  /// Something arrived: the app shows the "where to send" screen.
  static final waiting = ValueNotifier<List<SharedItem>?>(null);

  /// Asks the phone for anything shared to us (call at start and whenever
  /// the app comes back to the front).
  static Future<void> check() async {
    if (kIsWeb) return;
    try {
      final got = await channel.invokeMethod<List<Object?>>('take');
      final items = [for (final o in got ?? const []) ?SharedItem.fromMap(o)];
      if (items.isNotEmpty) waiting.value = items;
    } on MissingPluginException {
      // Desktop builds: no share sheet to come from.
    } catch (_) {}
  }

  /// Total bytes, for the progress bar (words count as one byte each).
  static Future<int> sizeOf(List<SharedItem> items) async {
    var n = 0;
    for (final i in items) {
      if (i.bytes != null) {
        n += i.bytes!.length;
      } else if (i.path.isNotEmpty) {
        try {
          n += await File(i.path).length();
        } catch (_) {}
      } else {
        n += i.text.length;
      }
    }
    return n;
  }
}
