// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 채널 묶음 #15 (Telegram tips 521 · 292 · 472 · 310 ·
// 526):
// - 여행 기록: my super channel (signed posts with authors' photos, one
//   post sent as the channel), a public address so I can write in groups
//   as it, and three subscribers' messages folded into one 메시지 row.
// - 동네 빵집 소식: a channel I only read, with 💬 (messages to its admins)
//   and unread posts, so pulling up at the end of another channel goes on.
// - 한강 러닝 크루: 도윤 writes as his public channel (checked), 은우 claims
//   one he doesn't run (shows his own name).
import '../core/backend.dart';
import 'demo_backend.dart';

void addChannelTipsSample(FakeBackend b, bool ko) {
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));
  Msg t(String id, String who, int min, String body, {PostAs? as}) =>
      Msg(id: id, sender: who, body: body, time: ago(min), mine: who == '@me:test', kind: 'text', postAs: as);

  // 472 + 526: my super channel.
  const trip = '!ct_trip';
  b.names[trip] = ko ? '여행 기록' : 'Travel notes';
  b.groups.add(trip);
  b.channels.add(trip);
  b.switches['$trip/sign'] = true;
  b.roomConfigs[trip] = {'authors': true, 'subscriber_dm': true};
  b.links[trip] = const RoomLink(kind: 'public', code: 'travelnotes');
  b.roomMembers[trip] = [
    const Member(userId: '@me:test', name: 'me', role: 'owner'),
    Member(userId: '@sora:test', name: ko ? '소라' : 'Sora', role: 'admin'),
    Member(userId: '@jun:test', name: ko ? '준' : 'Jun', role: 'admin'),
  ];
  b.rooms[trip] = [
    t(
      'ct1',
      '@sora:test',
      300,
      ko ? '제주 동쪽 해안 도로 따라 달려 봤어요. 성산까지 40분, 바람이 정말 시원해요 🌊' : 'Drove the east coast road on Jeju. 40 min to Seongsan, lovely breeze 🌊',
    ),
    t('ct2', '@jun:test', 200, ko ? '부산 국밥 지도 3편 올렸어요. 서면 쪽 두 곳이 새로 들어갔어요 🍲' : 'Busan soup map part 3 is up. Two new places near Seomyeon 🍲'),
    t('ct3', '@sora:test', 120, ko ? '📢 이번 주말 정기 모임은 쉬어요. 다음 주에 만나요!' : '📢 No meetup this weekend. See you next week!', as: const PostAs.channel()),
    t('ct4', '@me:test', 60, ko ? '구독자 1만 명 고마워요! 여행 사진 공모전을 열어요 📸' : 'Thanks for 10k subscribers! Photo contest coming 📸'),
  ];

  // 526: three subscribers wrote to the admins.
  var i = 0;
  for (final (who, name, words) in [
    (
      '@mina:test',
      ko ? '민아' : 'Mina',
      ko ? ['안녕하세요! 광고 문의 드려요', '숙소 홍보를 한 번 부탁드릴 수 있을까요?'] : ['Hi! An ad question', 'Could you post about our guesthouse once?'],
    ),
    ('@haeun:test', ko ? '하은' : 'Haeun', ko ? ['제주 사진 공모전 마감이 언제예요?'] : ['When does the photo contest close?']),
    ('@taeho:test', ko ? '태호' : 'Taeho', ko ? ['부산 국밥 지도에 저희 가게도 넣어 주실 수 있나요? 🙏'] : ['Could our shop go on the soup map? 🙏']),
  ]) {
    final id = '!ct_dm$i';
    b.names[id] = b.names[trip]!;
    b.groups.add(id);
    b.roomConfigs[id] = {'channel_dm': trip, 'subscriber': who};
    b.roomMembers[id] = [Member(userId: who, name: name, role: 'owner'), const Member(userId: '@me:test', name: 'me', role: 'admin')];
    b.rooms[id] = [for (var k = 0; k < words.length; k++) t('ctd$i$k', who, 30 + i * 25 - k * 2, words[k])];
    b.unreadCounts[id] = words.length;
    i++;
  }

  // 526 + 292: a channel I only read.
  const bakery = '!ct_bakery';
  b.names[bakery] = ko ? '동네 빵집 소식' : 'Corner bakery news';
  b.groups.add(bakery);
  b.channels.add(bakery);
  b.roomConfigs[bakery] = {'subscriber_dm': true};
  b.peers[bakery] = '@baker:test';
  b.roomMembers[bakery] = [
    const Member(userId: '@me:test', name: 'me', role: 'member'),
    Member(userId: '@baker:test', name: ko ? '빵집 사장님' : 'Baker', role: 'owner'),
  ];
  b.rooms[bakery] = [
    t('cb1', '@baker:test', 180, ko ? '오늘 아침 소금빵 200개 구웠어요 🥐' : 'Baked 200 salt rolls this morning 🥐'),
    t('cb2', '@baker:test', 90, ko ? '크리스마스 케이크 예약 받아요. 💬 버튼으로 편하게 물어봐 주세요!' : 'Christmas cake orders open. Ask with the 💬 button!'),
    t('cb3', '@baker:test', 20, ko ? '마감 30분 전 모든 빵 20% 할인 🔔' : '20% off everything 30 minutes before closing 🔔'),
  ];
  b.unreadCounts[bakery] = 3;

  // 310: someone writes in the running group as his public channel.
  const doyunCh = '!ct_doyun';
  b.outside['doyunrun'] = LinkPeek(roomId: doyunCh, name: ko ? '도윤의 러닝 일지' : "Doyun's running log", channel: true, members: 842);
  b.channelAdmins[doyunCh] = {'@doyun:test'};
  final run = b.rooms['!run'];
  if (run != null) {
    run.addAll([
      t(
        'ctr1',
        '@doyun:test',
        15,
        ko ? '제 채널에 반포 코스 지도 올려 뒀어요. 참고하세요 🗺️' : 'Put the Banpo route map on my channel 🗺️',
        as: const PostAs.of(doyunCh, 'doyunrun'),
      ),
      t('ctr2', '@eunwoo:test', 12, ko ? '저도 도윤의 러닝 일지예요 (아님)' : "I'm Doyun's running log too (not really)", as: const PostAs.of(doyunCh, 'doyunrun')),
    ]);
  }
}
