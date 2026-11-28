// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 사진 (TelegramTips 563, Eric approved 2026-11-27): an iPhone Live
// Photo or an Android Motion Photo is sent as its still photo plus the
// short clip (about 3 s). Written from public layouts only: JPEG (ITU T.81),
// Adobe XMP, ISO BMFF / MP4 (ISO/IEC 14496-12) and Google's published
// Motion Photo format (XMP "Container" items / older "MicroVideoOffset").
import 'dart:convert';
import 'dart:typed_data';

/// How the clip plays in the chat (chosen before sending).
enum LiveStyle {
  /// Plays once when the photo appears (and again on a tap), like Photos.
  live,

  /// Plays over and over.
  loop,

  /// Forward, then backward, over and over.
  bounce,

  /// Sent as a plain photo (the clip stays on this phone).
  off;

  static LiveStyle parse(String? s) => switch (s) {
    'loop' => loop,
    'bounce' => bounce,
    'off' => off,
    _ => live,
  };
}

/// A clip may be at most this long / big (a Live Photo is about 3 s).
const liveMaxBytes = 20 * 1024 * 1024;
const liveMaxMs = 10000;

class MotionParts {
  const MotionParts(this.still, this.clip);

  /// The JPEG without the clip at its end.
  final Uint8List still;

  /// The MP4 that was hidden at the end of the photo.
  final Uint8List clip;
}

class LivePhoto {
  const LivePhoto._();

  /// Android Motion Photo (Pixel "MVIMG", Samsung, ...): a JPEG with an MP4
  /// glued to its end, its length written in the XMP. null = not one.
  static MotionParts? splitMotion(List<int> bytes) {
    final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    if (b.length < 64 || b[0] != 0xFF || b[1] != 0xD8) return null;
    final xmp = _xmp(b);
    int? start;
    if (xmp != null) {
      // Motion Photo 1.0: the video item's Length (counted from the end).
      final item =
          RegExp(r'Item:Mime="video/[^"]*"[^>]*?Item:Length="(\d+)"|Item:Length="(\d+)"[^>]*?Item:Mime="video/', dotAll: true).firstMatch(xmp) ??
          RegExp(r'Item:Semantic="MotionPhoto"[^>]*?Item:Length="(\d+)"', dotAll: true).firstMatch(xmp);
      final len = item == null ? null : int.tryParse(item.group(1) ?? item.group(2) ?? '');
      // Older Pixel phones: GCamera:MicroVideoOffset (also from the end).
      final old = RegExp(r'MicroVideoOffset[=">\s]+"?(\d+)').firstMatch(xmp);
      final off = len ?? (old == null ? null : int.tryParse(old.group(1)!));
      if (off != null && off > 8 && off < b.length) start = b.length - off;
    }
    // No (usable) note: look for an MP4 right after the picture's end.
    if (start == null || !_isMp4At(b, start)) start = _mp4AfterJpeg(b);
    if (start == null || !_isMp4At(b, start)) return null;
    final clip = Uint8List.sublistView(b, start);
    if (clip.length > liveMaxBytes) return null;
    return MotionParts(Uint8List.sublistView(b, 0, start), clip);
  }

  /// True when the bytes look like a Motion Photo (for the LIVE mark).
  static bool isMotion(List<int> bytes) => splitMotion(bytes) != null;

  static String? _xmp(Uint8List b) {
    var i = 2;
    while (i + 4 <= b.length && b[i] == 0xFF) {
      final m = b[i + 1];
      if (m == 0xDA || m == 0xD9) break;
      final len = (b[i + 2] << 8) | b[i + 3];
      if (len < 2 || i + 2 + len > b.length) break;
      if (m == 0xE1) {
        final seg = latin1.decode(Uint8List.sublistView(b, i + 4, i + 2 + len), allowInvalid: true);
        if (seg.startsWith('http://ns.adobe.com/xap/1.0/')) return seg;
      }
      i += 2 + len;
    }
    return null;
  }

  static bool _isMp4At(Uint8List b, int at) =>
      at >= 0 && at + 12 <= b.length && b[at + 4] == 0x66 && b[at + 5] == 0x74 && b[at + 6] == 0x79 && b[at + 7] == 0x70; // "ftyp"

  /// First "ftyp" box that starts right after a JPEG end mark (FF D9).
  static int? _mp4AfterJpeg(Uint8List b) {
    for (var i = 2; i + 12 <= b.length; i++) {
      if (b[i] == 0xFF && b[i + 1] == 0xD9 && _isMp4At(b, i + 2)) return i + 2;
    }
    return null;
  }
}

/// Removes hidden details (place, phone model, owner, edit notes) from an
/// MP4/MOV clip before it leaves the phone. Boxes are blanked in place
/// (renamed to "free" and zeroed), so every offset in the file stays right
/// and the clip plays the same.
class Mp4Meta {
  const Mp4Meta._();

  static const _containers = {'moov', 'trak', 'mdia', 'minf', 'stbl', 'edts', 'dinf'};
  static const _drop = {'udta', 'meta', 'uuid', 'XMP_'};

  static Uint8List strip(List<int> bytes) {
    final b = Uint8List.fromList(bytes);
    try {
      _walk(b, 0, b.length, top: true);
    } catch (_) {}
    return b;
  }

  static void _walk(Uint8List b, int from, int to, {bool top = false}) {
    var i = from;
    while (i + 8 <= to) {
      var size = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
      final type = latin1.decode(Uint8List.sublistView(b, i + 4, i + 8), allowInvalid: true);
      var head = 8;
      if (size == 1) {
        if (i + 16 > to) return;
        size = 0;
        for (var k = 8; k < 16; k++) {
          size = size * 256 + b[i + k];
        }
        head = 16;
      } else if (size == 0) {
        size = to - i;
      }
      if (size < head || i + size > to) return;
      if (_drop.contains(type)) {
        _blank(b, i, size, head);
      } else if (_containers.contains(type)) {
        _walk(b, i + head, i + size);
      }
      i += size;
    }
  }

  static void _blank(Uint8List b, int at, int size, int head) {
    b.setRange(at + 4, at + 8, const [0x66, 0x72, 0x65, 0x65]); // "free"
    b.fillRange(at + head, at + size, 0);
  }

  /// True when no box that can hold a place or owner is left.
  static bool clean(List<int> bytes) {
    final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    var found = false;
    void walk(int from, int to) {
      var i = from;
      while (i + 8 <= to) {
        final size = (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
        final type = latin1.decode(Uint8List.sublistView(b, i + 4, i + 8), allowInvalid: true);
        if (size < 8 || i + size > to) return;
        if (_drop.contains(type)) found = true;
        if (_containers.contains(type)) walk(i + 8, i + size);
        i += size;
      }
    }

    walk(0, b.length);
    return !found;
  }

  /// Clip length from the movie header (mvhd), or null.
  static Duration? duration(List<int> bytes) {
    final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    int u32(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
    Duration? found;
    void walk(int from, int to) {
      var i = from;
      while (i + 8 <= to && found == null) {
        final size = u32(i);
        final type = latin1.decode(Uint8List.sublistView(b, i + 4, i + 8), allowInvalid: true);
        if (size < 8 || i + size > to) return;
        if (type == 'moov') walk(i + 8, i + size);
        if (type == 'mvhd' && i + 32 <= to) {
          final v1 = b[i + 8] == 1;
          final scale = v1 ? u32(i + 28) : u32(i + 20);
          final dur = v1 ? u32(i + 32) * 4294967296 + u32(i + 36) : u32(i + 24);
          if (scale > 0) found = Duration(milliseconds: dur * 1000 ~/ scale);
        }
        i += size;
      }
    }

    try {
      walk(0, b.length);
    } catch (_) {}
    return found;
  }
}
