// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 4-app board (WhatsApp 2026): look inside a ZIP without unpacking it.
// The list comes from the file's own table of contents; one file is
// unpacked only when it is tapped, in memory, never onto the phone's disk
// and never to a server. Guards against "zip bombs": a cap on entries, on
// the size of one unpacked file and on how much it may grow.
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'open_docs.dart' show fileExt;

/// One entry inside the archive.
class ZipEntry {
  const ZipEntry({required this.path, required this.size, required this.packed});

  /// Full path inside the archive ("사진/바다.jpg").
  final String path;

  /// Size once unpacked, as the archive says (bytes).
  final int size;

  /// Size inside the archive (bytes; = size when stored as is).
  final int packed;

  String get name => path.split('/').where((x) => x.isNotEmpty).lastOrNull ?? path;

  /// The folder it sits in ('' = top).
  String get folder {
    final i = path.lastIndexOf('/');
    return i <= 0 ? '' : path.substring(0, i);
  }
}

/// Why an archive can't be shown.
enum ZipProblem { password, broken, tooMany, unsupported }

class ZipPeekResult {
  const ZipPeekResult(this.entries, {this.problem, this.total = 0});
  final List<ZipEntry> entries;
  final ZipProblem? problem;

  /// All entries counted, even past [ZipPeek.maxEntries].
  final int total;
}

class ZipPeek {
  const ZipPeek._();

  /// More than this and only the first ones are listed.
  static const maxEntries = 2000;

  /// One file bigger than this once unpacked: 다른 앱으로 열기 instead.
  static const maxUnpacked = 50 * 1024 * 1024;

  /// A file that claims to grow more than this many times is refused
  /// (normal files shrink 2–10×; bombs claim thousands).
  static const maxRatio = 200;

  /// Archives Burumy can look inside (tar.gz counts as gz).
  static bool canPeek(String name) => const {'zip', 'tar', 'gz', 'tgz'}.contains(fileExt(name));

  static Archive _open(String name, Uint8List bytes) {
    final ext = fileExt(name);
    if (ext == 'zip') {
      // Every zip starts with "PK"; anything else is not one.
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b) throw const FormatException('not a zip');
      return ZipDecoder().decodeBytes(bytes);
    }
    if (ext == 'tar') return TarDecoder().decodeBytes(bytes);
    // .gz / .tgz: a tar inside when it is one, else the single file.
    final raw = GZipDecoder().decodeBytes(bytes);
    if (raw.length > maxUnpacked) throw const FormatException('too big');
    final inner = name.toLowerCase().replaceAll(RegExp(r'\.t?gz$'), '');
    if (ext == 'tgz' || inner.endsWith('.tar')) return TarDecoder().decodeBytes(raw);
    return Archive()..add(ArchiveFile.bytes(inner.isEmpty ? 'file' : inner.split('/').last, raw));
  }

  /// The files inside, folders first by path order as stored (no folders
  /// themselves, no hidden macOS extras).
  static ZipPeekResult list(String name, Uint8List bytes) {
    if (!canPeek(name)) return const ZipPeekResult([], problem: ZipProblem.unsupported);
    try {
      final a = _open(name, bytes);
      final out = <ZipEntry>[];
      var total = 0;
      for (final f in a.files) {
        if (!f.isFile || _junk(f.name)) continue;
        total++;
        if (out.length < maxEntries) {
          out.add(ZipEntry(path: f.name, size: f.size, packed: f.rawContent?.length ?? f.size));
        }
      }
      out.sort((x, y) => x.path.toLowerCase().compareTo(y.path.toLowerCase()));
      return ZipPeekResult(out, total: total, problem: total > maxEntries ? ZipProblem.tooMany : null);
    } on ArchivePasswordException {
      return const ZipPeekResult([], problem: ZipProblem.password);
    } catch (_) {
      return const ZipPeekResult([], problem: ZipProblem.broken);
    }
  }

  /// Unpacks one file in memory. Null when it is too big, looks like a
  /// bomb, needs a password or is broken.
  static Uint8List? read(String name, Uint8List bytes, ZipEntry e) {
    if (e.size > maxUnpacked) return null;
    if (e.packed > 0 && e.size > e.packed * maxRatio && e.size > 1024 * 1024) return null;
    try {
      final a = _open(name, bytes);
      final f = a.files.where((x) => x.isFile && x.name == e.path).firstOrNull;
      final out = f?.readBytes();
      if (out == null || out.length > maxUnpacked) return null;
      return out;
    } catch (_) {
      return null;
    }
  }

  /// macOS / Windows extras nobody means to send.
  static bool _junk(String path) =>
      path.startsWith('__MACOSX/') || path.endsWith('.DS_Store') || path.endsWith('Thumbs.db') || path.split('/').any((p) => p.startsWith('._'));

  /// Total unpacked size of the listed files.
  static int sizeOf(List<ZipEntry> l) => l.fold(0, (a, e) => a + e.size);
}
