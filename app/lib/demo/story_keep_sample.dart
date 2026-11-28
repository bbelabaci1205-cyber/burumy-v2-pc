// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 스토리 남기기·꾸미기 (Telegram tips 393, 392 / 468 /
// 534, 525, 395, 408, 414, 428): stories kept on 미나's profile in two
// albums, Leo's long video in two parts with a cover, a reaction sticker
// and his own music, a group's story with a round video, and one of mine
// kept in the 제주도 album.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Offset;

import '../core/backend.dart';
import '../ui/story_keep.dart' show storyPin;
import '../ui/story_more.dart';
import 'demo_backend.dart';

/// A short, soft tune (WAV) made here: no music files from anyone else.
Uint8List demoTune() {
  const rate = 8000;
  const notes = [523.25, 659.25, 783.99, 659.25, 587.33, 698.46, 880.0, 783.99];
  const each = 0.45;
  final n = (rate * each * notes.length).round();
  final pcm = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    final t = i / rate;
    final k = (t / each).floor().clamp(0, notes.length - 1);
    final local = t - k * each;
    final env = math.min(1.0, local * 20) * math.exp(-local * 3);
    final v = (math.sin(2 * math.pi * notes[k] * t) * 0.35 * env * 32767).round();
    pcm.setInt16(i * 2, v, Endian.little);
  }
  final h = ByteData(44);
  void s(int at, String x) {
    for (var i = 0; i < 4; i++) {
      h.setUint8(at + i, x.codeUnitAt(i));
    }
  }

  s(0, 'RIFF');
  h.setUint32(4, 36 + n * 2, Endian.little);
  s(8, 'WAVE');
  s(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little);
  h.setUint16(22, 1, Endian.little);
  h.setUint32(24, rate, Endian.little);
  h.setUint32(28, rate * 2, Endian.little);
  h.setUint16(32, 2, Endian.little);
  h.setUint16(34, 16, Endian.little);
  s(36, 'data');
  h.setUint32(40, n * 2, Endian.little);
  return Uint8List.fromList([...h.buffer.asUint8List(), ...pcm.buffer.asUint8List()]);
}

Future<void> addStoryKeepSample(FakeBackend b, bool ko, List<int> photo, {required Uint8List still, required Uint8List clip, required Uint8List round}) async {
  final now = DateTime.now();
  final over = now.subtract(const Duration(hours: 1));
  // 미나: four stories kept on her profile (two albums, one pinned on top).
  final mina = [
    ('kp-mina-1', ko ? '전시회' : 'Exhibitions', true, 9, photo),
    ('kp-mina-2', ko ? '전시회' : 'Exhibitions', false, 6, still),
    ('kp-mina-3', ko ? '여행' : 'Trips', false, 4, still),
    ('kp-mina-4', ko ? '여행' : 'Trips', false, 2, photo),
  ];
  for (final (id, album, top, days, pic) in mina) {
    b.files[id] = pic;
    b.storyList.add(
      Story(
        id: id,
        roomId: '!r0',
        eventId: id,
        sender: '@mina:test',
        mine: false,
        time: now.subtract(Duration(days: days)),
        kind: 'image',
        pin: storyPin(album: album, top: top),
        until: over,
      ),
    );
  }
  // 미나's story of today was changed after posting (tip 393): "수정됨".
  final i = b.storyList.indexWhere((x) => x.id == 'st1');
  if (i >= 0) b.storyList[i] = b.storyList[i].copyWith(edited: true);

  // Leo: one long video posted as two parts (tip 525), its cover picked
  // from a frame (tip 468), a ❤️ reaction sticker and his own music (395).
  final cover = await b.uploadEncrypted(still);
  final tune = await b.uploadEncrypted(demoTune());
  b.files['st-leo-long'] = clip;
  final react = StoryLive(kind: 'react', q: '❤️', at: const Offset(.78, .7));
  final music = StoryLive(
    kind: 'music',
    q: ko ? '산책' : 'A walk',
    site: ko ? '부루미 데모' : 'Burumy demo',
    file: tune,
    mime: 'audio/wav',
    at: const Offset(.5, .16),
  );
  for (final (n, from, to) in [(1, 0, 20), (2, 20, 40)]) {
    b.storyList.add(
      Story(
        id: 'st-leo-long-$n',
        roomId: '!r2',
        eventId: 'st-leo-long',
        sender: '@leo:test',
        mine: false,
        time: now.subtract(Duration(minutes: 30 - n)),
        kind: 'video',
        caption: ko ? '한강 자전거 ($n/2)' : 'Bike by the river ($n/2)',
        extra: withExtra(n == 1 ? encodeLive([react, music]) : encodeLive([music]), {
          'cover': cover,
          'clip': {'from': from, 'to': to},
        }),
        until: now.add(const Duration(hours: 23)),
      ),
    );
  }

  // A group's story (tip 428) by its admin, with a round video (408).
  if (b.rooms.containsKey('!r1')) {
    final rv = await b.uploadEncrypted(round);
    b.files['st-group'] = photo;
    b.storyList.add(
      Story(
        id: 'st-group',
        roomId: '!r1',
        eventId: 'st-group',
        sender: '@leo:test',
        mine: false,
        time: now.subtract(const Duration(minutes: 50)),
        kind: 'image',
        caption: ko ? '이번 주 모임 장소 정했어요!' : 'This week we meet here!',
        extra: encodeLive([StoryLive(kind: 'round', file: rv, mime: 'video/mp4', at: const Offset(.72, .3))]),
        group: true,
        until: now.add(const Duration(hours: 23)),
      ),
    );
  }

  // Mine, kept in the 제주도 album after its 24 hours.
  b.files['kp-mine-jeju'] = still;
  b.storyList.add(
    Story(
      id: 'kp-mine-jeju',
      roomId: '',
      eventId: 'kp-mine-jeju',
      sender: '@me:test',
      mine: true,
      time: now.subtract(const Duration(days: 3)),
      kind: 'image',
      pin: storyPin(album: ko ? '제주도' : 'Jeju'),
      until: now.subtract(const Duration(days: 2)),
    ),
  );
}
