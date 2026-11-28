// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): examples for the fun / story / camera batch.
// - Daeun's chat: a note photo with words (사진 속 글자) and a phone number.
// - Mina: birthday today (banner + balloons) and a video story to hold.
// - Leo: a view-once round video.
// - 새 친구 유나: no messages yet (hello card).
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../core/backend.dart';
import '../core/phone.dart';
import 'demo_backend.dart';

/// A paper note with a few lines; returns the picture and where each line is.
Future<(Uint8List, List<TextLine>)> _note(bool ko) async {
  const w = 720.0, h = 900.0;
  final lines = ko
      ? ['카페 와이파이', 'Burumy_Guest', '비밀번호: hello2027', '주문 번호 0412', '02-123-4567']
      : ['Cafe Wi-Fi', 'Burumy_Guest', 'Password: hello2027', 'Order no. 0412', '+1 415 555 0123'];
  final rec = ui.PictureRecorder();
  final c = ui.Canvas(rec);
  c.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), ui.Paint()..color = const ui.Color(0xFF8D6E63));
  final paper = ui.Rect.fromLTWH(70, 90, w - 140, h - 180);
  c.drawRRect(ui.RRect.fromRectAndRadius(paper.shift(const ui.Offset(6, 10)), const ui.Radius.circular(18)), ui.Paint()..color = const ui.Color(0x55000000));
  c.drawRRect(ui.RRect.fromRectAndRadius(paper, const ui.Radius.circular(18)), ui.Paint()..color = const ui.Color(0xFFFFFBEF));
  final out = <TextLine>[];
  var y = paper.top + 70;
  for (final (i, t) in lines.indexed) {
    final size = i == 0 ? 46.0 : 38.0;
    final pb = ui.ParagraphBuilder(ui.ParagraphStyle(fontFamily: 'Pretendard', fontSize: size, fontWeight: i == 0 ? ui.FontWeight.w600 : ui.FontWeight.w400))
      ..pushStyle(ui.TextStyle(color: const ui.Color(0xFF2B2B2B), fontFamily: 'Pretendard', fontSize: size))
      ..addText(t);
    final para = pb.build()..layout(ui.ParagraphConstraints(width: paper.width - 80));
    final x = paper.left + 40;
    c.drawParagraph(para, ui.Offset(x, y));
    final tw = para.longestLine;
    out.add(TextLine(t, ui.Rect.fromLTWH(x / w, y / h, tw / w, para.height / h)));
    y += para.height + (i == 0 ? 40 : 28);
  }
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final png = await img.toByteData(format: ui.ImageByteFormat.png);
  img.dispose();
  return (png!.buffer.asUint8List(), out);
}

String _md(DateTime d) => '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> addFunSample(FakeBackend b, bool ko, List<int> clip) async {
  final now = DateTime.now();
  // 317 + 453 in Daeun's chat (made by the photo sample).
  final (note, lines) = await _note(ko);
  b.files['note-photo'] = note;
  Phone.debugReadText = (photo) async => photo.length == note.length ? lines : const [];
  final daeun = b.rooms['!photos'];
  if (daeun != null) {
    daeun.addAll([
      Msg(id: 'note-photo', sender: '@daeun:test', body: 'wifi.png', time: now.subtract(const Duration(minutes: 1)), mine: false, kind: 'image'),
      Msg(
        id: 'note-phone',
        sender: '@daeun:test',
        body: ko
            ? '카페 사장님 번호는 010-2345-6789 예요. 사진 속 와이파이 비번은 글자 버튼으로 복사해요 ☕️'
            : "The owner's number is +1 415 555 0199. Copy the Wi-Fi password with the Text button ☕️",
        time: now,
        mine: false,
        kind: 'text',
      ),
    ]);
  }
  // 446: Mina's birthday is today (friends share only MM-DD).
  final old = b.cards['@mina:test'];
  b.cards['@mina:test'] = ProfileCard(photo: old?.photo, bio: old?.bio ?? b.bios['@mina:test'] ?? '', birthday: _md(now));
  // 403: a short video story from Mina to hold and slide through.
  b.files['st-video'] = clip;
  b.storyList.add(
    Story(
      id: 'st-video',
      roomId: '!r0',
      eventId: 'st-video',
      sender: '@mina:test',
      mine: false,
      time: now.subtract(const Duration(minutes: 30)),
      kind: 'video',
    ),
  );
  // 420: a view-once round video from Leo.
  b.files['once-round'] = clip;
  b.rooms['!r2']?.add(Msg(id: 'once-round', sender: '@leo:test', body: 'videonote.mp4', time: now, mine: false, kind: 'video', viewOnce: true));
  // 80: a new friend, nothing said yet.
  const id = '!newfriend';
  b.names[id] = ko ? '최유나' : 'Yuna Choi';
  b.peers[id] = '@yuna:test';
  // Second from the top, right under Daeun's chat.
  final rest = Map.of(b.rooms);
  final first = rest.keys.first;
  final top = rest.remove(first)!;
  b.rooms
    ..clear()
    ..[first] = top
    ..[id] = []
    ..addAll(rest);
}
