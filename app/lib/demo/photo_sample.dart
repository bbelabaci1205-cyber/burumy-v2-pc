// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only: a pretend phone gallery (drawn here, no real photos) so the
// web preview can show the "+" sheet's photo grid and 갤러리 ⌄ albums, and a
// chat with photos sent together, a covered (가리기) photo and a GIF video.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../core/backend.dart';
import '../core/phone.dart';
import 'demo_backend.dart';

/// A made-up photo: sky, sun and hills in [hue] (or a phone screenshot).
Future<Uint8List> _draw(int i, {bool shot = false}) async {
  const w = 600.0, h = 800.0;
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  final hue = (i * 47) % 360.0;
  if (shot) {
    c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..color = const ui.Color(0xFFF2F2F7));
    for (var r = 0; r < 9; r++) {
      c.drawRRect(
        ui.RRect.fromRectAndRadius(ui.Rect.fromLTWH(30, 90.0 + r * 76, w - 60, 60), const ui.Radius.circular(14)),
        ui.Paint()..color = const ui.Color(0xFFFFFFFF),
      );
      c.drawCircle(ui.Offset(70, 120.0 + r * 76), 18, ui.Paint()..color = HSV(hue + r * 30, .5, .9).color);
    }
  } else {
    final sky = ui.Gradient.linear(ui.Offset.zero, const ui.Offset(0, h), [HSV(hue, .45, .95).color, HSV(hue + 30, .25, 1).color]);
    c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..shader = sky);
    c.drawCircle(ui.Offset(150 + (i % 3) * 140.0, 230), 70, ui.Paint()..color = const ui.Color(0xFFFFF4C7));
    for (var k = 0; k < 3; k++) {
      final path = ui.Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 20) {
        path.lineTo(x, 470 + k * 90 + math.sin(x / (90 + k * 30) + i + k) * 40);
      }
      path
        ..lineTo(w, h)
        ..close();
      c.drawPath(path, ui.Paint()..color = HSV(hue + 120 + k * 15, .45 + k * .1, .75 - k * .15).color);
    }
  }
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return png!.buffer.asUint8List();
}

class HSV {
  HSV(this.h, this.s, this.v);
  final double h, s, v;
  ui.Color get color {
    final hh = (h % 360) / 60, c = v * s, x = c * (1 - ((hh % 2) - 1).abs()), m = v - c;
    final (r, g, b) = switch (hh.floor()) {
      0 => (c, x, 0.0),
      1 => (x, c, 0.0),
      2 => (0.0, c, x),
      3 => (0.0, x, c),
      4 => (x, 0.0, c),
      _ => (c, 0.0, x),
    };
    return ui.Color.from(alpha: 1, red: r + m, green: g + m, blue: b + m);
  }
}

Future<void> addPhotoSample(FakeBackend b, bool ko, List<int> clip, {List<int>? longClip}) async {
  final photos = [for (var i = 0; i < 14; i++) await _draw(i, shot: i == 3 || i == 9)];
  final shots = {3, 9};
  final favs = {0, 5, 7};
  final media = <PhoneMedia>[for (var i = 0; i < photos.length; i++) PhoneMedia('p$i', photos[i])];
  // One "video" in the grid (the live clip), second place.
  media.insert(1, PhoneMedia('v0', photos[2], video: true, duration: const Duration(seconds: 3)));
  // A longer one to try 자르기·회전 on (tip 56).
  if (longClip != null) media.insert(3, PhoneMedia('v1', photos[10], video: true, duration: const Duration(seconds: 40)));
  List<PhoneMedia> only(bool Function(PhoneMedia m) keep) => media.where(keep).toList();
  Phone.debugRecent = (_) async => media;
  Phone.debugAlbumRecent = (_, album) async => switch (album) {
    'favorites' => only((m) => favs.contains(int.tryParse(m.id.substring(1)) ?? -1) && !m.video),
    'videos' => only((m) => m.video),
    'screenshots' => only((m) => !m.video && shots.contains(int.parse(m.id.substring(1)))),
    'c:trip' => only((m) => !m.video && !shots.contains(int.parse(m.id.substring(1))) && int.parse(m.id.substring(1)) < 8),
    _ => media,
  };
  Phone.debugAlbums = () async => [
    PhoneAlbum(PhoneAlbum.recentsId, media.length),
    PhoneAlbum('favorites', favs.length),
    const PhoneAlbum('videos', 1),
    PhoneAlbum('screenshots', shots.length),
    PhoneAlbum('c:trip', 6, name: ko ? '제주 여행' : 'Jeju trip'),
  ];
  // The web can't cut a person out of a photo; the demo cuts a soft oval
  // from the middle so 오려내기 can be tried (phones cut the real shape).
  Phone.debugCutout ??= demoCutout;
  Phone.debugLoadFile = (id) async => switch (id) {
    'v0' => PhoneFile('clip.mp4', Uint8List.fromList(clip)),
    'v1' => PhoneFile('walk.mp4', Uint8List.fromList(longClip ?? clip)),
    _ => PhoneFile('photo$id.png', photos[int.parse(id.substring(1))]),
  };
  // Look-only demo: the editor works, but a browser can't cut a video, so
  // the demo sends the clip as it is (phones make the real cut one).
  Phone.debugEditVideo = (v, _) async => v;

  // A chat that shows what arrives: an album, a covered photo, a GIF.
  final now = DateTime(2026, 11, 23, 20, 14);
  const id = '!photos';
  b.names[id] = ko ? '정다은' : 'Daeun Jung';
  b.peers[id] = '@daeun:test';
  for (var i = 0; i < 3; i++) {
    b.files['al$i'] = photos[i + 4];
  }
  b.files['sp0'] = photos[6];
  b.files['gif0'] = clip;
  b.rooms
    ..remove(id)
    ..[id] = [
      for (var i = 0; i < 3; i++)
        Msg(
          id: 'al$i',
          sender: '@daeun:test',
          body: 'bm_ademo-$i-3__trip$i.png',
          caption: i == 2 ? (ko ? '여행 사진 세 장 묶어서 보내요 ⛰️' : 'Three trip photos, sent together ⛰️') : null,
          time: now.subtract(Duration(minutes: 6, seconds: 3 - i)),
          mine: false,
          kind: 'image',
        ),
      Msg(id: 'sp0', sender: '@daeun:test', body: 'bm_s__surprise.png', time: now.subtract(const Duration(minutes: 4)), mine: false, kind: 'image'),
      Msg(
        id: 'note',
        sender: '@daeun:test',
        body: ko ? '위에 사진은 눌러야 보여요 🙈' : 'Tap the photo above to see it 🙈',
        time: now.subtract(const Duration(minutes: 4)),
        mine: false,
        kind: 'text',
      ),
      Msg(id: 'gif0', sender: '@daeun:test', body: 'bm_g__wave.mp4', time: now.subtract(const Duration(minutes: 2)), mine: false, kind: 'video'),
    ];
  // Newest first: this chat on top.
  final rest = Map.of(b.rooms)..remove(id);
  final mine = b.rooms[id]!;
  b.rooms
    ..clear()
    ..[id] = mine
    ..addAll(rest);
}

/// Demo 오려내기: the middle of the photo in an oval, the rest see-through.
Future<Uint8List?> demoCutout(Uint8List photo) async {
  final img = (await (await ui.instantiateImageCodec(photo, targetWidth: 800)).getNextFrame()).image;
  final w = img.width.toDouble(), h = img.height.toDouble();
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  final oval = ui.Rect.fromCenter(center: ui.Offset(w / 2, h * .52), width: w * .62, height: h * .72);
  c.clipPath(ui.Path()..addOval(oval));
  c.drawImage(img, ui.Offset.zero, ui.Paint());
  final out = await rec.endRecording().toImage(img.width, img.height);
  img.dispose();
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  out.dispose();
  return data?.buffer.asUint8List();
}
