// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 표준 / HD photos (Telegram tip 529). A chat photo is made smaller on this
// phone before it is encrypted: 표준 = at most 1280 px on the long side,
// HD = at most 2560 px (4 times the pixels). The friend downloads a few
// hundred KB instead of a 5–10 MB original, and the server stores less.
// 파일로 보내기 still sends the untouched original.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// How big a photo goes out.
enum PhotoQuality {
  standard(1280),
  hd(2560);

  const PhotoQuality(this.longSide);

  /// Longest side in pixels.
  final int longSide;
}

/// A photo ready to send: its (new) name and bytes.
typedef SizedPhoto = ({String name, Uint8List bytes});

class PhotoSize {
  /// JPEG quality: camera photos / pictures without see-through parts.
  static const jpegQuality = 87;

  /// Screenshots and drawings (PNG) keep sharper letters.
  static const pngJpegQuality = 92;

  /// Tests replace the work (no image decoder in plain unit tests).
  static Future<SizedPhoto> Function(String name, Uint8List bytes, PhotoQuality q)? debugFit;

  /// Kinds that may move (GIF, WebP) or are not photos stay as they are.
  static bool canShrink(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return const ['jpg', 'jpeg', 'png', 'heic', 'heif', 'bmp'].contains(ext);
  }

  /// New width / height so the long side is at most [max] (never larger).
  static (int, int) fitSize(int w, int h, int max) {
    if (w <= 0 || h <= 0) return (w, h);
    final long = w > h ? w : h;
    if (long <= max) return (w, h);
    final k = max / long;
    return ((w * k).round().clamp(1, max), (h * k).round().clamp(1, max));
  }

  /// [name] with a .jpg ending (same name otherwise).
  static String jpgName(String name) {
    final dot = name.lastIndexOf('.');
    return '${dot > 0 ? name.substring(0, dot) : name}.jpg';
  }

  /// The photo at [q]. Anything that can't be read goes out unchanged
  /// (the chat still removes place and camera data before sending).
  static Future<SizedPhoto> fit(String name, Uint8List bytes, PhotoQuality q) async {
    final debug = debugFit;
    if (debug != null) return debug(name, bytes, q);
    if (!canShrink(name)) return (name: name, bytes: bytes);
    try {
      final (sw, sh) = await _sizeOf(bytes);
      final (w, h) = fitSize(sw, sh, q.longSide);
      final ext = name.split('.').last.toLowerCase();
      final jpeg = ext == 'jpg' || ext == 'jpeg';
      // Already small enough and already a JPEG: keep it, no second blur.
      if (jpeg && w == sw && h == sh) return (name: name, bytes: bytes);
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: w, targetHeight: h);
      final frame = await codec.getNextFrame();
      codec.dispose();
      final image = frame.image;
      final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final iw = image.width, ih = image.height;
      image.dispose();
      if (rgba == null) return (name: name, bytes: bytes);
      final out = await compute(_encode, (rgba.buffer.asUint8List(), iw, ih, jpeg ? jpegQuality : pngJpegQuality));
      if (out.png) {
        final dot = name.lastIndexOf('.');
        return (name: '${dot > 0 ? name.substring(0, dot) : name}.png', bytes: out.bytes);
      }
      return (name: jpgName(name), bytes: out.bytes);
    } catch (_) {
      return (name: name, bytes: bytes);
    }
  }

  /// Width and height as shown (turned upright). Phones read only the
  /// file's header; the web has no header reader, so it decodes once.
  static Future<(int, int)> _sizeOf(Uint8List bytes) async {
    if (!kIsWeb) {
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final size = (desc.width, desc.height);
      desc.dispose();
      buffer.dispose();
      return size;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final f = await codec.getNextFrame();
    final size = (f.image.width, f.image.height);
    f.image.dispose();
    codec.dispose();
    return size;
  }

  /// Any pixel not fully solid (a cut-out sticker, a drawing on clear).
  static bool hasSeeThrough(Uint8List rgba) {
    for (var i = 3; i < rgba.length; i += 4) {
      if (rgba[i] != 255) return true;
    }
    return false;
  }
}

/// Runs off the main thread on phones: JPEG, or PNG when the picture has
/// see-through parts (a sticker-like drawing stays clear around it).
({Uint8List bytes, bool png}) _encode((Uint8List, int, int, int) a) {
  final (rgba, w, h, quality) = a;
  final pic = img.Image.fromBytes(width: w, height: h, bytes: rgba.buffer, numChannels: 4, order: img.ChannelOrder.rgba);
  if (PhotoSize.hasSeeThrough(rgba)) return (bytes: img.encodePng(pic, level: 6), png: true);
  return (bytes: img.encodeJpg(pic, quality: quality), png: false);
}
