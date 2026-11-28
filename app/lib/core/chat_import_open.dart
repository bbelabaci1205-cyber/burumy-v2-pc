// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Opens a picked export file: phones and computers read a big zip from
// disk piece by piece; the web reads it into memory.
export 'chat_import_open_web.dart' if (dart.library.io) 'chat_import_open_io.dart';
