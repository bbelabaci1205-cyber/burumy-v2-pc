// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 빠른 다듬기 D1 (2026-11-27): a chat with a booking
// code (코드 복사 button), and a channel post with my reaction that the
// channel's reaction rules now hide (faint chip).
import '../core/backend.dart';
import 'demo_backend.dart';

void addTipsD1Sample(FakeBackend b, bool ko, {List<int>? video}) {
  final now = DateTime.now();
  b.names['!code'] = ko ? '하늘 미용실' : 'Sky Hair Salon';
  b.peers['!code'] = '@sky_salon:test';
  b.rooms['!code'] = [
    Msg(
      id: 'code1',
      sender: '@sky_salon:test',
      body: ko ? '[하늘 미용실] 예약 확인 인증번호는 482913 이에요. 5분 안에 입력해 주세요.' : '[Sky Hair Salon] Your booking code is 482913. Enter it within 5 minutes.',
      time: now.subtract(const Duration(minutes: 1)),
      mine: false,
      kind: 'text',
    ),
  ];
  // 이어보기 (tip 509): a video I stopped part way (thin bar under it).
  if (video != null && b.rooms['!r0'] != null) {
    b.rooms['!r0']!.add(
      Msg(id: 'd1-video', sender: '@mina:test', body: 'trip.mp4', time: now.subtract(const Duration(seconds: 30)), mine: false, kind: 'video'),
    );
    b.files['d1-video'] = video;
    b.prefs['video_pos'] = '{"!r0|d1-video":[2000,5000,0]}';
  }
  // 부루미 소식: only 👍 ❤️ 🎉 allowed now; my old 😂 shows faint.
  final post = b.rooms['!c']?.lastOrNull;
  if (post != null) {
    final i = b.rooms['!c']!.length - 1;
    b.rooms['!c']![i] = post.copyWith(reactions: const [Reaction('👍', 12, null), Reaction('❤️', 5, null), Reaction('😂', 2, 'demo-mine')]);
    b.reactionOf['demo-mine'] = ('!c', post.id, '😂');
    b.roomConfigs['!c'] = {
      ...?b.roomConfigs['!c'],
      'reactions': 'some',
      'reactions_set': ['👍', '❤️', '🎉'],
    };
  }
}
