// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Data > Storage used: sizes of the app's own folders on this
// phone, and clearing the temporary one.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class StorageUsage {
  const StorageUsage(this.app, this.cache);
  final int app;
  final int cache;

  /// Tests swap this.
  static Future<StorageUsage?> Function() read = _read;
  static Future<void> Function() clearCache = _clear;

  static Future<int> _size(Directory d) async {
    var n = 0;
    if (!await d.exists()) return 0;
    await for (final e in d.list(recursive: true, followLinks: false)) {
      if (e is File) {
        try {
          n += await e.length();
        } catch (_) {}
      }
    }
    return n;
  }

  static Future<StorageUsage?> _read() async {
    if (kIsWeb) return null;
    try {
      final app = await _size(await getApplicationSupportDirectory());
      final docs = await _size(await getApplicationDocumentsDirectory());
      final cache = await _size(await getTemporaryDirectory());
      return StorageUsage(app + docs, cache);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _clear() async {
    if (kIsWeb) return;
    final d = await getTemporaryDirectory();
    await for (final e in d.list(followLinks: false)) {
      try {
        await e.delete(recursive: true);
      } catch (_) {}
    }
  }
}

/// "12.3 MB" style size.
String sizeText(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '$bytes B' : '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}
