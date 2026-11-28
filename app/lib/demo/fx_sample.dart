// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only web demo for 효과 (#30) and 이모지 팩·GIF (#31): a birthday chat
// where a message arrives with the 축하 effect (plays when opened), my
// message carries 케이크, a big ❤️ that moves, and dice games.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, FontWeight, TextAlign, TextDirection;
import 'package:image/image.dart' as im;

import '../core/backend.dart';
import '../core/custom_emoji.dart';
import '../core/gifs.dart';
import '../ui/custom_emoji_ui.dart' show cxFromWords;
import 'demo_backend.dart';

void addFxSample(FakeBackend b, bool ko) {
  const r = '!fx-friend';
  const who = '@hayun:test';
  b.names[r] = ko ? '한하윤' : 'Hayun Han';
  b.peers[r] = who;
  b.unreadCounts[r] = 2;
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));
  Msg them(String id, String body, int min) => Msg(id: id, sender: who, body: body, time: ago(min), mine: false, kind: 'text');
  Msg me(String id, String body, int min) => Msg(id: id, sender: '@me:test', body: body, time: ago(min), mine: true, kind: 'text');
  Msg game(String id, String e, int min, {bool mine = false}) => Msg(
    id: id,
    sender: mine ? '@me:test' : who,
    body: e,
    time: ago(min),
    mine: mine,
    kind: 'card',
    card: CardInfo(kind: 'dice', data: {'e': e}),
  );
  b.rooms[r] = [
    them('fx1', ko ? '오늘 내 생일이야!' : "It's my birthday today!", 30),
    me('fx2', ko ? '생일 축하해! 🎂 오늘 하루 최고로 보내' : 'Happy birthday! 🎂 Have the best day', 29),
    them('fx3', '❤️', 28),
    them('fx4', ko ? '저녁에 주사위로 2차 정하자 ㅋㅋ' : "Let's roll for where we go after dinner", 20),
    game('fx5', '🎲', 19),
    game('fx6', '🎲', 18, mine: true),
    game('fx7', '🎯', 12),
    game('fx8', '🎰', 11, mine: true),
    game('fx9', '🏀', 10),
    them('fx10', ko ? '다들 와 줘서 너무 고마워!! 🎉' : 'Thank you all for coming!! 🎉', 1),
  ];
  // Effects on messages (normally tied by the hidden note; see effects.dart).
  b.prefs['msg_fx_ids'] = jsonEncode({'fx2': 'cake', 'fx10': 'party'});
  // Mine has played already; the friend's 축하 plays when the chat opens.
  b.prefs['msg_fx_played'] = 'fx2';
}

/// Made emoji (354) + group emoji (430): three of mine, one from 하윤 in her
/// chat, and the design team's group emoji. Pictures drawn from words here
/// (the demo has no photos to cut out).
Future<void> addCxSample(FakeBackend b, bool ko) async {
  Future<CxEmoji> make(String w, int color, CxMotion m, String base) async => CxEmoji.make(await cxFromWords(w, Color(color)), m, base);
  final mine = [
    await make(ko ? '굿' : 'OK', 0xFF0088FF, CxMotion.bounce, '👍'),
    await make('ㅋㅋ', 0xFFFF8D28, CxMotion.wiggle, '😂'),
    await make('♥', 0xFFFF2D55, CxMotion.beat, '❤️'),
  ];
  final hers = await make(ko ? '최고' : 'BEST', 0xFFCB30E0, CxMotion.jelly, '✨');
  final team = [
    await make(ko ? '확인' : 'SEEN', 0xFF00C3D0, CxMotion.bounce, '👀'),
    await make(ko ? '수고' : 'GG', 0xFF0088FF, CxMotion.float, '🙏'),
    await make('🔥', 0xFFFF383C, CxMotion.beat, '🔥'),
    await make(ko ? '회의' : 'SYNC', 0xFF6155F5, CxMotion.wiggle, '📅'),
  ];
  b.prefs['my_emoji'] = jsonEncode([for (final e in mine) e.toJson()]);
  b.prefs['cx_cache'] = jsonEncode([
    for (final e in [hers, ...team]) e.toJson(),
  ]);
  final now = DateTime.now();
  b.rooms['!fx-friend']?.addAll([
    Msg(
      id: 'cx1',
      sender: '@hayun:test',
      body: ko ? '선물 고마워 :${hers.id}: 진짜 마음에 들어' : 'Thanks for the gift :${hers.id}: love it',
      time: now.subtract(const Duration(seconds: 40)),
      mine: false,
      kind: 'text',
    ),
    Msg(id: 'cx2', sender: '@hayun:test', body: ':${hers.id}:', time: now.subtract(const Duration(seconds: 30)), mine: false, kind: 'text'),
  ]);
  // 디자인 팀: an admin picked the team's emoji (fingerprint in the room).
  const team0 = '!r1';
  final pack = {
    'n': 'demo',
    'items': [
      for (final e in team) {'id': e.id, 'f': await b.uploadSecret(e.png), 'm': e.motion.name, 'e': e.base},
    ],
  };
  b.prefs['gx:$team0'] = jsonEncode(pack);
  (b.roomConfigs[team0] ??= {})[CustomEmojis.packCfg] = {'h': CustomEmojis.fingerprint(pack), 'c': team.length};
}

/// 내 GIF (tip 558): four saved GIFs (three drawn here, plus 다은's wave
/// clip) and, in 하윤's chat, a GIF with words drawn over it.
Future<void> addGifSample(FakeBackend b, bool ko) async {
  final saved = <Map<String, Object?>>[];
  Future<void> keep(List<int> bytes, String name, String mime) async {
    saved.add({'id': Gifs.idOf(bytes), 'f': await b.uploadSecret(bytes), 'n': name, 'm': mime});
  }

  await keep(_drawnGif('HI!', 0xFF0088FF, 'hop'), 'hi.gif', 'image/gif');
  await keep(_drawnGif('LOL', 0xFFFF8D28, 'shake'), 'lol.gif', 'image/gif');
  await keep(_drawnGif('', 0xFF34C759, 'ball'), 'ball.gif', 'image/gif');
  final clip = b.files['gif0'];
  if (clip != null && clip.isNotEmpty) await keep(clip, 'wave.mp4', 'video/mp4');
  b.prefs['my_gifs'] = jsonEncode(saved);

  // 하윤 sends a party GIF with "생일 축하해!" drawn over it.
  final party = _drawnGif('YAY', 0xFFFF2D55, 'party');
  b.files['gf1'] = party;
  const layer = 'a1b2c3d4e5f6';
  final png = await _wordsLayer(ko ? '생일 축하해! 🎉' : 'Happy birthday! 🎉');
  b.prefs['gif_layers'] = jsonEncode({
    layer: {'f': await b.uploadSecret(png), 'from': '@hayun:test'},
  });
  b.rooms['!fx-friend']?.add(
    Msg(
      id: 'gf1',
      sender: '@hayun:test',
      body: 'bm_o${layer}__party.gif',
      time: DateTime.now().subtract(const Duration(seconds: 20)),
      mine: false,
      kind: 'image',
    ),
  );
}

/// A small looping GIF drawn with the image package.
Uint8List _drawnGif(String words, int argb, String move) {
  const w = 200, h = 150, n = 12;
  final c = Color(argb);
  int ch(double v) => (v * 255).round().clamp(0, 255);
  im.Image? first;
  for (var i = 0; i < n; i++) {
    final t = i / n;
    final f = im.Image(width: w, height: h);
    final light = 0.82 + 0.1 * math.sin(t * 2 * math.pi);
    im.fill(f, color: im.ColorRgb8(ch(c.r * 0.25 + light * 0.75), ch(c.g * 0.25 + light * 0.75), ch(c.b * 0.25 + light * 0.75)));
    final col = im.ColorRgb8(ch(c.r), ch(c.g), ch(c.b));
    switch (move) {
      case 'ball':
        final y = (h - 34) - (math.sin(t * math.pi).abs() * 80).round();
        im.fillCircle(f, x: w ~/ 2 + 26, y: h - 14, radius: 12 - (math.sin(t * math.pi) * 5).round(), color: im.ColorRgb8(150, 150, 150));
        im.fillCircle(f, x: w ~/ 2 + 26, y: y, radius: 22, color: col);
      case 'party':
        final r = math.Random(7);
        for (var k = 0; k < 26; k++) {
          final x = r.nextInt(w), y0 = r.nextInt(h);
          final y = ((y0 + t * h) % h).round();
          final pc = [im.ColorRgb8(255, 45, 85), im.ColorRgb8(255, 204, 0), im.ColorRgb8(0, 136, 255), im.ColorRgb8(52, 199, 89)][k % 4];
          im.fillRect(f, x1: x, y1: y, x2: x + 6, y2: y + 10, color: pc);
        }
      default:
        break;
    }
    if (words.isNotEmpty) {
      final dx = move == 'shake' ? (math.sin(t * 6 * math.pi) * 10).round() : 0;
      final dy = move == 'hop' ? -(math.sin(t * math.pi).abs() * 22).round() : 0;
      final x = (w - words.length * 26) ~/ 2 + dx;
      final y = (h - 48) ~/ 2 + dy + (move == 'party' ? 0 : 6);
      im.drawString(f, words, font: im.arial48, x: x + 2, y: y + 2, color: im.ColorRgb8(255, 255, 255));
      im.drawString(f, words, font: im.arial48, x: x, y: y, color: col);
    }
    f.frameDuration = 90;
    if (first == null) {
      first = f;
    } else {
      first.addFrame(f);
    }
  }
  return im.encodeGif(first!);
}

/// Words drawn on a see-through picture, like the GIF editor makes.
Future<Uint8List> _wordsLayer(String words) async {
  const w = 720.0, h = 540.0;
  final rec = ui.PictureRecorder();
  final canvas = ui.Canvas(rec);
  TextPainter p(ui.Paint? stroke) => TextPainter(
    text: TextSpan(
      text: words,
      style: TextStyle(
        fontSize: 76,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
        foreground: stroke,
        color: stroke == null ? const Color(0xFFFFFFFF) : null,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w - 40);
  final back = p(
    ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = const Color(0xFF000000),
  );
  final front = p(null);
  final at = ui.Offset((w - front.width) / 2, h - front.height - 36);
  back.paint(canvas, at);
  front.paint(canvas, at);
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
