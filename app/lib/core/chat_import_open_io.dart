// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart' show XFile;

import 'chat_import.dart';

/// Phones and computers: a zip stays on disk and each photo is read only
/// when it is sent, so a 1 GB export doesn't fill the phone's memory.
Future<ImportBundle> openExport(XFile f) async {
  final size = await f.length();
  if (size > importMaxBytes) throw const ImportError('big');
  final head = await f.openRead(0, 4).fold<List<int>>([], (a, b) => a..addAll(b));
  final zip = f.name.toLowerCase().endsWith('.zip') || (head.length == 4 && head[0] == 0x50 && head[1] == 0x4b && head[2] == 3 && head[3] == 4);
  if (zip && f.path.isNotEmpty && File(f.path).existsSync()) {
    final Archive a;
    try {
      a = ZipDecoder().decodeStream(InputFileStream(f.path));
    } catch (_) {
      throw const ImportError('broken');
    }
    return ChatImport.readInBackground(f.name, null, archive: a);
  }
  return ChatImport.readInBackground(f.name, await f.readAsBytes());
}
