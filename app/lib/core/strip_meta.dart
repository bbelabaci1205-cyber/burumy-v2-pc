// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Removes hidden photo details (place, phone model, time, owner) before a
// photo leaves the phone (v1 4-2). Written from the public JPEG (ITU T.81 /
// JFIF), PNG (W3C) and WebP (RIFF) layouts. Pixels are never touched; a
// colour profile (ICC) is kept so colours look the same.
import 'dart:typed_data';

class StripMeta {
  const StripMeta._();

  /// The same picture without metadata. Unknown or broken files come back
  /// unchanged (never fail a send because of this).
  static List<int> photo(List<int> bytes, String mime) {
    try {
      final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
      if (_isJpeg(b)) return _jpeg(b);
      if (_isPng(b)) return _png(b);
      if (_isWebp(b)) return _webp(b);
    } catch (_) {}
    return bytes;
  }

  static bool _isJpeg(Uint8List b) => b.length > 4 && b[0] == 0xFF && b[1] == 0xD8;
  static bool _isPng(Uint8List b) => b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
  static bool _isWebp(Uint8List b) =>
      b.length > 12 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 && b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50;

  /// JPEG: drops APP1 (Exif, XMP), APP12-APP15 and comments; keeps APP0
  /// (JFIF), APP2 only when it is an ICC profile, and APP14 (Adobe colour).
  static List<int> _jpeg(Uint8List b) {
    final out = BytesBuilder(copy: false)..add([0xFF, 0xD8]);
    var i = 2;
    while (i + 4 <= b.length) {
      if (b[i] != 0xFF) return b; // broken: leave as is
      final m = b[i + 1];
      if (m == 0xDA) {
        // Start of scan: the rest is picture data, up to the end mark
        // (FF D9; it can't appear inside the data). Anything glued after
        // it is dropped: an Android Motion Photo hides its clip there, with
        // its own place and phone details (움직이는 사진, 2026-11-27).
        var end = b.length;
        for (var k = i + 2; k + 1 < b.length; k++) {
          if (b[k] == 0xFF && b[k + 1] == 0xD9) {
            end = k + 2;
            break;
          }
        }
        out.add(Uint8List.sublistView(b, i, end));
        return out.takeBytes();
      }
      if (m == 0xFF) {
        i++;
        continue;
      }
      if (m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
        out.add([0xFF, m]);
        i += 2;
        continue;
      }
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2 || i + 2 + len > b.length) return b;
      final seg = Uint8List.sublistView(b, i, i + 2 + len);
      if (_keepJpeg(m, seg)) out.add(seg);
      i += 2 + len;
    }
    return b;
  }

  static bool _keepJpeg(int m, Uint8List seg) {
    if (m == 0xFE) return false; // comment
    if (m == 0xE2) return _startsWith(seg, 4, 'ICC_PROFILE');
    if (m == 0xEE) return true; // Adobe colour transform
    if (m == 0xE0) return _startsWith(seg, 4, 'JFIF') || _startsWith(seg, 4, 'JFXX');
    if (m >= 0xE1 && m <= 0xEF) return false;
    return true;
  }

  static bool _startsWith(Uint8List b, int at, String s) {
    if (at + s.length > b.length) return false;
    for (var k = 0; k < s.length; k++) {
      if (b[at + k] != s.codeUnitAt(k)) return false;
    }
    return true;
  }

  /// PNG: drops text, time and Exif chunks.
  static List<int> _png(Uint8List b) {
    const drop = {'tEXt', 'zTXt', 'iTXt', 'tIME', 'eXIf'};
    final out = BytesBuilder(copy: false)..add(Uint8List.sublistView(b, 0, 8));
    var i = 8;
    while (i + 12 <= b.length) {
      final len = ByteData.sublistView(b, i, i + 4).getUint32(0);
      final type = String.fromCharCodes(b.sublist(i + 4, i + 8));
      final end = i + 12 + len;
      if (end > b.length) return b;
      if (!drop.contains(type)) out.add(Uint8List.sublistView(b, i, end));
      i = end;
      if (type == 'IEND') return out.takeBytes();
    }
    return b;
  }

  /// WebP: drops EXIF and XMP chunks and clears their flags in VP8X.
  static List<int> _webp(Uint8List b) {
    final body = BytesBuilder(copy: false);
    var i = 12;
    while (i + 8 <= b.length) {
      final type = String.fromCharCodes(b.sublist(i, i + 4));
      final len = ByteData.sublistView(b, i + 4, i + 8).getUint32(0, Endian.little);
      final end = i + 8 + len + (len.isOdd ? 1 : 0);
      if (end > b.length) return b;
      if (type == 'EXIF' || type == 'XMP ') {
        i = end;
        continue;
      }
      final chunk = Uint8List.fromList(b.sublist(i, end));
      if (type == 'VP8X' && chunk.length > 8) chunk[8] &= ~0x0C; // EXIF + XMP flags
      body.add(chunk);
      i = end;
    }
    final data = body.takeBytes();
    final head = ByteData(12)
      ..setUint8(0, 0x52)
      ..setUint8(1, 0x49)
      ..setUint8(2, 0x46)
      ..setUint8(3, 0x46)
      ..setUint32(4, data.length + 4, Endian.little)
      ..setUint8(8, 0x57)
      ..setUint8(9, 0x45)
      ..setUint8(10, 0x42)
      ..setUint8(11, 0x50);
    return (BytesBuilder(copy: false)
          ..add(head.buffer.asUint8List())
          ..add(data))
        .takeBytes();
  }
}
