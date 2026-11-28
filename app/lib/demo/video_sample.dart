// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Video example chat for the web demo (batch "영상 보기·내려받기",
// 2026-11-27): a 40-second test-pattern clip (made with ffmpeg, no camera
// footage) with "0:12" in its caption and a reply saying "0:30", so the
// time links, double-tap skip, hold-to-speed and speed panel can be tried.
import '../core/backend.dart';
import 'demo_backend.dart';

void addVideoSample(FakeBackend b, bool ko, List<int> clip) {
  final now = DateTime(2026, 11, 23, 20, 14);
  const id = '!video';
  b.names[id] = ko ? '송하린' : 'Harin Song';
  b.peers[id] = '@harin:test';
  b.files['vd1'] = clip;
  final msgs = [
    Msg(
      id: 'vd1',
      sender: '@harin:test',
      body: 'clip.mp4',
      caption: ko ? '제일 좋은 장면은 0:12부터예요 🎬' : 'The best part starts at 0:12 🎬',
      time: now.subtract(const Duration(minutes: 4)),
      mine: false,
      kind: 'video',
      size: clip.length,
    ),
    Msg(
      id: 'vd2',
      sender: '@me:test',
      body: ko ? '0:30 장면도 좋아요! 두 번 탭하면 10초씩 넘어가요' : 'Love 0:30 too! Double-tap skips 10 seconds',
      time: now.subtract(const Duration(minutes: 2)),
      mine: true,
      kind: 'text',
      replyTo: 'vd1',
    ),
  ];
  final rest = Map.of(b.rooms);
  b.rooms
    ..clear()
    ..[id] = msgs
    ..addAll(rest);
}
