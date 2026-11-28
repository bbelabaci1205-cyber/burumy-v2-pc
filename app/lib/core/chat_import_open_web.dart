// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:file_selector/file_selector.dart' show XFile;

import 'chat_import.dart';

/// Web: the whole file in memory (browsers give no file path).
Future<ImportBundle> openExport(XFile f) async {
  final size = await f.length();
  if (size > 500 * 1024 * 1024) throw const ImportError('big');
  return ChatImport.readInBackground(f.name, await f.readAsBytes());
}
