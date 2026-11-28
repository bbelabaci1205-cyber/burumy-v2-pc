// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 GIF (Telegram tip 558): marks in the file name, saving, sending with a
// layer and a cut, the layer only from the sender, and 예약.
import 'dart:convert';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/gifs.dart';
import 'package:burumy/core/media_tags.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('layer and cut marks go both ways', () {
    const t = MediaTags(gif: true, layer: 'a1b2c3d4e5f6', from: 1200, to: 3400);
    final name = t.apply('wave.mp4');
    expect(name, 'bm_g_oa1b2c3d4e5f6_t1200-3400__wave.mp4');
    final back = MediaTags.of(name);
    expect(back.gif, isTrue);
    expect(back.layer, 'a1b2c3d4e5f6');
    expect((back.from, back.to), (1200, 3400));
    expect(MediaTags.plain(name), 'wave.mp4');
    // To the end; a bad cut is dropped.
    expect(MediaTags.of(const MediaTags(from: 500).apply('x.mp4')).to, -1);
    expect(MediaTags.of('bm_t900-100__x.mp4').to, -1);
    expect(MediaTags.of('bm_oNOTHEX__x.gif').layer, isNull);
    expect(const MediaTags().any, isFalse);
  });

  test('save, send with layer + cut, layer only from the sender, 예약', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('bob');
    final gif = List<int>.generate(64, (i) => i);
    expect(await Gifs.save(s, gif, name: 'bm_g__wave.mp4', mime: 'video/mp4'), isTrue);
    // The same GIF is kept once.
    await Gifs.save(s, gif, name: 'wave.mp4', mime: 'video/mp4');
    final mine = Gifs.mine(s);
    expect(mine.length, 1);
    expect(mine.first.name, 'wave.mp4');
    // Only the key is in my settings, never the picture.
    expect(s.pref('my_gifs', '').contains(base64Encode(gif)), isFalse);

    final layer = Uint8List.fromList([9, 9, 9]);
    await Gifs.send(s, room, mine.first, caption: '좋은 하루!', layer: layer, from: 1000, to: 2000);
    final sent = b.rooms[room]!.last;
    final tags = MediaTags.of(sent.body);
    expect(tags.gif, isTrue);
    expect((tags.from, tags.to), (1000, 2000));
    expect(tags.layer, isNotNull);
    expect(sent.caption, '좋은 하루!');
    final note = b.sentSignals.last;
    expect(note.$2, Gifs.layerKind);
    expect(note.$3['id'], tags.layer);
    expect(await Gifs.layerOf(s, tags.layer!, '@me:test'), layer);

    // Someone else's note can't put words on bob's GIF ...
    final f = await b.uploadSecret([1, 2, 3]);
    await Gifs.onLayer(s, Signal(roomId: room, id: 'e1', sender: '@eve:test', kind: Gifs.layerKind, data: {'id': '0123456789ab', 'f': f}, time: DateTime.now()));
    expect(await Gifs.layerOf(s, '0123456789ab', '@bob:test'), isNull);
    // ... nor swap one that already arrived.
    await Gifs.onLayer(s, Signal(roomId: room, id: 'e2', sender: '@bob:test', kind: Gifs.layerKind, data: {'id': '0123456789ab', 'f': f}, time: DateTime.now()));
    expect(await Gifs.layerOf(s, '0123456789ab', '@bob:test'), isNull);

    // 예약: goes when due, with its words.
    await Gifs.schedule(s, room, mine.first, DateTime.now().subtract(const Duration(minutes: 1)), caption: '나중에');
    expect(s.scheduled.single['gif'], isA<Map>());
    final before = b.rooms[room]!.length;
    await s.sendDue();
    expect(s.scheduled, isEmpty);
    expect(b.rooms[room]!.length, before + 1);
    expect(b.rooms[room]!.last.caption, '나중에');
    expect(Gifs.isGifMsg(b.rooms[room]!.last), isTrue);

    await Gifs.remove(s, mine.first.id);
    expect(Gifs.mine(s), isEmpty);
  });
}
