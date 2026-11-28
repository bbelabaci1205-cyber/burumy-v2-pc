// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 사진 example chat for the web demo (TelegramTips 563): a friend's
// Live Photo that plays once, and my own one sent as 바운스. The clip is a
// small drawn 3-second sea scene (made for the demo, no camera photo).
import '../core/backend.dart';
import 'demo_backend.dart';

void addLiveSample(FakeBackend b, bool ko, List<int> still, List<int> clip) {
  final now = DateTime(2026, 11, 23, 20, 12);
  const id = '!live';
  b.names[id] = ko ? '이하늘' : 'Haneul Lee';
  b.peers[id] = '@haneul:test';
  b.files['lv1'] = still;
  b.files['lv2'] = still;
  b.liveClips['lv1'] = clip;
  b.liveClips['lv2'] = clip;
  final msgs = [
    Msg(
      id: 'lv1',
      sender: '@haneul:test',
      body: 'sea.jpg',
      caption: ko ? '방금 바다 앞이에요 🌊' : 'Right by the sea 🌊',
      time: now.subtract(const Duration(minutes: 3)),
      mine: false,
      kind: 'image',
      live: const LiveInfo('live', Duration(seconds: 3)),
    ),
    Msg(
      id: 'lv2',
      sender: '@me:test',
      body: 'sea.jpg',
      caption: ko ? '바운스로 보내 봤어요' : 'Sent as Bounce',
      time: now.subtract(const Duration(minutes: 1)),
      mine: true,
      kind: 'image',
      live: const LiveInfo('bounce', Duration(seconds: 3)),
    ),
  ];
  // Newest first, like the engine: this chat goes on top.
  final rest = Map.of(b.rooms);
  b.rooms
    ..clear()
    ..[id] = msgs
    ..addAll(rest);
}
