// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// QR codes the camera reads (Telegram tip 503): what one holds, and where
// it sits in the picture. The picture never leaves the phone; zxing2
// (Apache-2.0, pure Dart) reads the grey levels on this phone.
import 'dart:typed_data';

import 'package:zxing2/qrcode.dart';
import 'package:zxing2/zxing2.dart';

import 'room_links.dart';

/// What a QR code holds, sorted for the camera's capsule.
/// kind: "room" (our invite link), "message", "chat" (대화 링크), "person"
/// (my-QR code), "expired" (a 5분 QR whose time is up), "pc" (PC sign-in),
/// "web" (another site) or "text".
class QrTarget {
  const QrTarget(this.kind, this.raw, {this.room, this.message, this.chat, this.userId = ''});
  final String kind;
  final String raw;
  final LinkTarget? room;
  final MessageLink? message;
  final ChatLink? chat;
  final String userId;

  /// Ours: opens inside the app, never in a browser.
  bool get inApp => const {'room', 'message', 'chat', 'person', 'pc'}.contains(kind);

  /// Web links: the site's name (shown before anything opens).
  String get host => Uri.tryParse(raw.trim())?.host ?? '';

  static final _person = RegExp(r'^burumy://u/([^?\s]+)(?:\?until=(\d+))?$');

  static QrTarget of(String text, DateTime now) {
    final t = text.trim();
    if (MessageLink.parse(t) case final m?) return QrTarget('message', t, message: m);
    if (ChatLink.parse(t) case final c?) return QrTarget('chat', t, chat: c);
    if (RoomLinks.parse(t) case final r?) return QrTarget('room', t, room: r);
    if (_person.firstMatch(t) case final m?) {
      final until = int.tryParse(m.group(2) ?? '');
      final id = Uri.decodeComponent(m.group(1)!);
      if (until != null && now.millisecondsSinceEpoch ~/ 1000 >= until) return QrTarget('expired', t, userId: id);
      return QrTarget('person', t, userId: id);
    }
    if (t.startsWith('burumy://pc-login?')) return QrTarget('pc', t);
    final u = Uri.tryParse(t);
    if (u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.contains('.')) return QrTarget('web', t);
    return QrTarget('text', t);
  }
}

/// One read: the words, and the code's finder points in the picture
/// (pixels of the grey frame as it came, before any turning).
class QrHit {
  const QrHit(this.text, this.points, this.width, this.height);
  final String text;
  final List<(double, double)> points;
  final int width, height;
}

/// Reads a QR code from grey levels (width, height, bytes); null when none.
QrHit? readQrHit((int, int, Uint8List) f) {
  final (w, h, luma) = f;
  try {
    final r = QRCodeReader().decode(BinaryBitmap(HybridBinarizer(GreyLuminance(luma, w, h))));
    return QrHit(r.text, [for (final p in r.resultPoints) (p.x, p.y)], w, h);
  } catch (_) {
    return null;
  }
}

/// The box around a code's finder points, in 0..1 of the preview, given
/// how the frame is turned ([turns] quarter turns clockwise), mirrored
/// (front camera), and fitted with BoxFit.cover into a [boxW] x [boxH]
/// preview. The finder points are the centres of the three big squares,
/// so the box grows a little to reach the code's real corners.
(double, double, double, double)? qrBox(QrHit hit, {required int turns, bool mirror = false, required double boxW, required double boxH}) {
  if (hit.points.length < 3 || boxW <= 0 || boxH <= 0) return null;
  final q = turns % 4;
  final w = hit.width.toDouble(), h = hit.height.toDouble();
  final tw = q.isOdd ? h : w, th = q.isOdd ? w : h;
  (double, double) turn((double, double) p) => switch (q) {
    1 => (h - p.$2, p.$1),
    2 => (w - p.$1, h - p.$2),
    3 => (p.$2, w - p.$1),
    _ => p,
  };
  final pts = [
    for (final p in hit.points)
      () {
        final t = turn(p);
        return mirror ? (tw - t.$1, t.$2) : t;
      }(),
  ];
  var x0 = pts.map((p) => p.$1).reduce((a, b) => a < b ? a : b), x1 = pts.map((p) => p.$1).reduce((a, b) => a > b ? a : b);
  var y0 = pts.map((p) => p.$2).reduce((a, b) => a < b ? a : b), y1 = pts.map((p) => p.$2).reduce((a, b) => a > b ? a : b);
  // Finder centres sit 3.5 modules in from the edges (of ~25-57): grow ~18 %.
  final gx = (x1 - x0) * .18, gy = (y1 - y0) * .18;
  x0 -= gx;
  x1 += gx;
  y0 -= gy;
  y1 += gy;
  final scale = (boxW / tw) > (boxH / th) ? boxW / tw : boxH / th;
  final ox = (boxW - tw * scale) / 2, oy = (boxH - th * scale) / 2;
  double nx(double x) => ((x * scale + ox) / boxW).clamp(0.0, 1.0);
  double ny(double y) => ((y * scale + oy) / boxH).clamp(0.0, 1.0);
  return (nx(x0), ny(y0), nx(x1), ny(y1));
}

/// Grey levels (one byte per pixel) for the QR reader.
class GreyLuminance extends LuminanceSource {
  GreyLuminance(this.data, int width, int height) : super(width, height);
  final Uint8List data;

  @override
  Int8List getRow(int y, Int8List? row) {
    final out = (row == null || row.length < width) ? Int8List(width) : row;
    for (var x = 0; x < width; x++) {
      out[x] = data[y * width + x].toSigned(8);
    }
    return out;
  }

  @override
  Int8List getMatrix() => Int8List.view(data.buffer, data.offsetInBytes, width * height);
}
