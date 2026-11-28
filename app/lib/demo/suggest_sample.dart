// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 채널에 글 제안 (tip 531, no money):
// - 자연 사진 (my channel) and its admin chat with subscriber 유리, who
//   suggested a post (올리기 / 거절 buttons) after an earlier one was agreed;
// - 맛집 탐방 (someone else's channel): my admin chat there with the
//   "글 제안하기" button above the composer.
// The admin-chat rooms (채널 문의함, tip 526) come from the channel thread
// in the real app; here they are plain demo rooms with the same marker.
import '../core/backend.dart';
import 'demo_backend.dart';

/// [at] fixes "now" (screenshot tests); the preview uses the real time.
Future<void> addSuggestSample(FakeBackend b, bool ko, {List<int>? photo, DateTime? at}) async {
  final now = at ?? DateTime.now();
  const ch = '!nature';
  b.names[ch] = ko ? '자연 사진' : 'Nature Photos';
  b.groups.add(ch);
  b.channels.add(ch);
  b.roomMembers[ch] = [const Member(userId: '@me:test', name: 'me', role: 'owner'), Member(userId: '@yuri:test', name: ko ? '유리' : 'Yuri', role: 'member')];
  b.rooms[ch] = [
    Msg(
      id: 'nat1',
      sender: '@me:test',
      body: ko ? '오늘의 사진: 설악산 단풍 🍁' : 'Photo of the day: autumn leaves 🍁',
      time: now.subtract(const Duration(days: 1)),
      mine: true,
      kind: 'text',
    ),
    Msg(
      id: 'nat2',
      sender: '@me:test',
      body: ko ? '한라산 일출\n\n✍️ 유리님이 제안했어요' : 'Sunrise on Hallasan\n\n✍️ Suggested by Yuri',
      time: now.subtract(const Duration(hours: 5)),
      mine: true,
      kind: 'text',
    ),
  ];

  const dm = '!nature_dm_yuri';
  b.names[dm] = ko ? '자연 사진 · 유리' : 'Nature Photos · Yuri';
  b.groups.add(dm);
  b.roomMembers[dm] = [const Member(userId: '@me:test', name: 'me', role: 'owner'), Member(userId: '@yuri:test', name: ko ? '유리' : 'Yuri', role: 'member')];
  b.roomConfigs[dm] = {'channel_dm': ch, 'subscriber': '@yuri:test'};
  final file = photo == null ? null : await b.uploadEncrypted(photo);
  b.rooms[dm] = [
    Msg(
      id: 'sy1',
      sender: '@yuri:test',
      body: ko ? '안녕하세요! 사진 잘 보고 있어요.' : 'Hi! I love your photos.',
      time: now.subtract(const Duration(hours: 7)),
      mine: false,
      kind: 'text',
    ),
    Msg(
      id: 'sy2',
      sender: '@yuri:test',
      body: '✍️',
      time: now.subtract(const Duration(hours: 6)),
      mine: false,
      kind: 'card',
      card: CardInfo(kind: 'suggest', data: {'text': ko ? '한라산 일출' : 'Sunrise on Hallasan', 'at': 0, 'channel': ch}),
    ),
    Msg(
      id: 'sy3',
      sender: '@me:test',
      body: '🤝',
      time: now.subtract(const Duration(hours: 5)),
      mine: true,
      kind: 'card',
      card: CardInfo(kind: 'suggest_deal', data: {'to': 'sy2', 'act': 'accept', 'at': 0, 'credit': true, 'note': ''}),
    ),
    Msg(
      id: 'sy4',
      sender: '@yuri:test',
      body: ko ? '올려 주셔서 감사해요! 하나 더 제안할게요 🙏' : 'Thanks for posting it! One more 🙏',
      time: now.subtract(const Duration(minutes: 12)),
      mine: false,
      kind: 'text',
    ),
    Msg(
      id: 'sy5',
      sender: '@yuri:test',
      body: '✍️',
      time: now.subtract(const Duration(minutes: 10)),
      mine: false,
      kind: 'card',
      card: CardInfo(
        kind: 'suggest',
        data: {
          'text': ko ? '모레인 호수, 캐나다\n사진: 유리' : 'Moraine Lake, Canada\nPhoto: Yuri',
          'photo': ?file,
          if (file != null) 'mime': 'image/png',
          'at': DateTime(now.year, now.month, now.day + 1, 21, 30).millisecondsSinceEpoch,
          'channel': ch,
        },
      ),
    ),
  ];
  b.unreadCounts[dm] = 2;

  const food = '!food_ch';
  const myDm = '!food_dm_me';
  b.names[myDm] = ko ? '맛집 탐방 · 관리자에게' : 'Food Trips · Admins';
  b.groups.add(myDm);
  b.roomMembers[myDm] = [
    const Member(userId: '@me:test', name: 'me', role: 'member'),
    Member(userId: '@chef:test', name: ko ? '맛집 탐방' : 'Food Trips', role: 'owner'),
  ];
  b.roomConfigs[myDm] = {'channel_dm': food, 'subscriber': '@me:test'};
  b.rooms[myDm] = [
    Msg(
      id: 'fd1',
      sender: '@chef:test',
      body: ko ? '무엇이든 물어보세요. 올리고 싶은 맛집 후기가 있으면 글 제안하기를 눌러 주세요!' : 'Ask anything. Got a review to share? Tap Suggest a Post!',
      time: now.subtract(const Duration(hours: 2)),
      mine: false,
      kind: 'text',
    ),
  ];
}
