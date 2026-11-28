// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): examples for the profile batch #12.
// - Me: a photo (sunset) + two earlier photos (예전 사진); 프로필 사진 shown to
//   내 연락처 only, with a Burumy-character 공개 사진 for everyone else.
// - Mina: her own photo plus one I set for her (two bars in the big header),
//   and a 사진 제안 card she sent me.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;

import '../core/backend.dart';
import '../core/my_photos.dart';
import 'demo_backend.dart';

/// A Burumy character on an iPhone-colour ground (what 이모지 사진 makes).
Future<Uint8List> _charPhoto(String asset, ui.Color top, ui.Color bottom) async {
  const s = 512.0;
  final codec = await ui.instantiateImageCodec((await rootBundle.load(asset)).buffer.asUint8List());
  final art = (await codec.getNextFrame()).image;
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawRect(const ui.Rect.fromLTWH(0, 0, s, s), ui.Paint()..shader = ui.Gradient.linear(const ui.Offset(0, 0), const ui.Offset(0, s), [top, bottom]));
  const inner = s * 0.62;
  c.drawImageRect(
    art,
    ui.Rect.fromLTWH(0, 0, art.width.toDouble(), art.height.toDouble()),
    const ui.Rect.fromLTWH((s - inner) / 2, (s - inner) / 2, inner, inner),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final im = await rec.endRecording().toImage(s.toInt(), s.toInt());
  final png = await im.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

Future<void> addProfileSample(FakeBackend b, Uint8List photo, Uint8List still) async {
  final now = b.now;
  final pub = await _charPhoto('assets/stickers/emoji/buru_e1_smile.webp', const ui.Color(0xFF5CC8FF), const ui.Color(0xFF0088FF));
  final old = await _charPhoto('assets/stickers/emoji/rumi_e2_love.webp', const ui.Color(0xFFFF8FA3), const ui.Color(0xFFFF2D55));
  // My photo, two earlier ones and the 공개 사진 (all kept on this phone).
  b.prefs['me_photo'] = base64Encode(still);
  b.prefs['me_loaded'] = '1';
  b.prefs['who_photo'] = 'contacts';
  b.prefs[MyPhotos.publicKey] = base64Encode(pub);
  final t1 = now.subtract(const Duration(days: 12)).millisecondsSinceEpoch, t2 = now.subtract(const Duration(days: 80)).millisecondsSinceEpoch;
  b.prefs[MyPhotos.photoKey('$t1')] = base64Encode(photo);
  b.prefs[MyPhotos.photoKey('$t2')] = base64Encode(old);
  b.prefs[MyPhotos.listKey] = '$t1,$t2';
  // What the public profile shows: the 공개 사진.
  b.photo = pub;
  // Mina: her photo + the one I chose for her (나에게만 보이는 사진).
  final card = b.cards['@mina:test'];
  b.cards['@mina:test'] = ProfileCard(photo: still, bio: card?.bio ?? b.bios['@mina:test'] ?? '', birthday: card?.birthday ?? '', private: true);
  b.prefs['cphoto:@mina:test'] = base64Encode(photo);
}

/// A 사진 제안 from Mina (she picked a photo for me). Added after the other
/// samples so it is the newest message in her chat.
Future<void> addProfileSuggestCard(FakeBackend b) async {
  final now = b.now;
  final old = await _charPhoto('assets/stickers/emoji/rumi_e2_love.webp', const ui.Color(0xFFFF8FA3), const ui.Color(0xFFFF2D55));
  final file = jsonDecode(await b.uploadEncrypted(old));
  b.rooms['!r0']!.add(
    Msg(
      id: 'photo-suggest',
      sender: '@mina:test',
      body: '🖼️',
      time: now.subtract(const Duration(seconds: 5)),
      mine: false,
      kind: 'card',
      card: CardInfo(kind: 'photo', data: {'file': file, 'mime': 'image/png'}),
    ),
  );
}
