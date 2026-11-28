// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 전체 검색 + 해시태그 (2026-11-27): a travel channel I
// follow with #여행 / #부산 posts (one with #여행@trip_diary), a friend's
// photo, link, file, song and voice message, a story with #여행, public
// channels I'm not in, and public web-page posts for the 글 tab.
import '../core/backend.dart';
import 'demo_backend.dart';

void addSearchSample(FakeBackend b, bool ko, List<int> photo, {DateTime? at}) {
  final now = at ?? DateTime.now();
  Duration h(int n) => Duration(hours: n);

  // A channel I follow, with a public address.
  const trip = '!trip';
  b.names[trip] = ko ? '여행 일기' : 'Travel Diary';
  b.groups.add(trip);
  b.channels.add(trip);
  b.peers[trip] = '@tripdiary:test';
  b.links[trip] = const RoomLink(kind: 'public', code: 'trip_diary');
  Msg post(String id, String body, Duration ago, {String kind = 'text', String? caption}) =>
      Msg(id: id, sender: '@tripdiary:test', body: body, time: now.subtract(ago), mine: false, kind: kind, caption: caption);
  b.rooms[trip] = [
    post('tr1', ko ? '가을 단풍 명소 5곳을 모았어요 #여행 #가을' : 'Five places for autumn leaves #travel #autumn', const Duration(days: 20)),
    post('tr2', 'haeundae.jpg', const Duration(days: 6), kind: 'image', caption: ko ? '해운대 아침 바다 #부산 #여행' : 'Morning sea at Haeundae #busan #travel'),
    post('tr3', ko ? '부산 3일 코스 정리 #부산 #여행@trip_diary' : 'Busan in 3 days #busan #travel@trip_diary', const Duration(days: 2)),
    post('tr4', ko ? '다음 주는 제주 이야기예요 #여행' : 'Next week: Jeju #travel', h(5)),
  ];
  b.files['tr2'] = photo;

  // A friend's chat with things to find on the other tabs.
  final r0 = b.rooms['!r0'];
  if (r0 != null) {
    r0.insertAll(0, [
      Msg(
        id: 'sr1',
        sender: '@mina:test',
        body: ko ? '#여행 사진 정리했어! 부산 진짜 좋았다' : 'Sorted the #travel photos! Busan was great',
        time: now.subtract(const Duration(days: 3)),
        mine: false,
        kind: 'text',
      ),
      Msg(
        id: 'sr2',
        sender: '@mina:test',
        body: 'https://www.visitbusan.net/food',
        time: now.subtract(const Duration(days: 3, hours: 1)),
        mine: false,
        kind: 'text',
        preview: LinkCard(url: 'https://www.visitbusan.net/food', title: ko ? '부산 맛집 안내' : 'Busan food guide', site: 'visitbusan.net'),
      ),
      Msg(
        id: 'sr3',
        sender: '@me:test',
        body: ko ? '부산_여행_계획.pdf' : 'busan_trip_plan.pdf',
        time: now.subtract(const Duration(days: 4)),
        mine: true,
        kind: 'file',
        size: 482113,
      ),
      Msg(
        id: 'sr4',
        sender: '@mina:test',
        body: 'busan_night.mp3',
        time: now.subtract(const Duration(days: 4, hours: 2)),
        mine: false,
        kind: 'file',
        size: 4210000,
      ),
      Msg(
        id: 'sr5',
        sender: '@mina:test',
        body: 'voice.ogg',
        time: now.subtract(const Duration(days: 5)),
        mine: false,
        kind: 'audio',
        voice: const VoiceInfo(Duration(seconds: 14), [120, 400, 800, 300, 650, 900, 200, 500]),
      ),
      Msg(
        id: 'sr6',
        sender: '@mina:test',
        body: 'gwangalli.jpg',
        time: now.subtract(const Duration(days: 3, hours: 3)),
        mine: false,
        kind: 'image',
        caption: ko ? '광안리 야경 #부산' : 'Gwangalli at night #busan',
      ),
    ]);
    b.files['sr6'] = photo;
  }

  // A friend's story with a tag (tip 459).
  b.storyList.add(
    Story(
      id: 'st-tag',
      roomId: '!r0',
      eventId: 'st-tag',
      sender: '@mina:test',
      mine: false,
      time: now.subtract(h(4)),
      kind: 'image',
      caption: ko ? '부산 바다 #여행' : 'Busan sea #travel',
    ),
  );
  b.files['st-tag'] = photo;

  // Public chats I'm not in (전체 검색 / 채널 tabs).
  b.outside['busan_food'] = LinkPeek(
    roomId: '!busan_food',
    name: ko ? '부산 맛집 지도' : 'Busan Food Map',
    about: ko ? '부산 여행 맛집만 골라요' : 'Only the best food in Busan',
    members: 23410,
    channel: true,
  );
  b.outside['travel_korea'] = LinkPeek(
    roomId: '!travel_korea',
    name: ko ? '대한민국 여행' : 'Travel Korea',
    about: ko ? '부산, 제주, 강릉 여행 소식' : 'Busan, Jeju, Gangneung travel news',
    members: 58210,
    channel: true,
  );
  b.outside['busan_walk'] = LinkPeek(
    roomId: '!busan_walk',
    name: ko ? '부산 산책 모임' : 'Busan Walkers',
    about: ko ? '주말마다 바닷가를 걸어요' : 'Seaside walks every weekend',
    members: 320,
  );

  // Web-page posts of public channels (글 tab, 공개 글).
  b.publicPosts.addAll([
    PublicPost(
      address: 'busan_food',
      name: ko ? '부산 맛집 지도' : 'Busan Food Map',
      members: 23410,
      text: ko ? '돼지국밥 맛집 TOP 7 정리했어요 #부산 #여행' : 'Top 7 pork soup places #busan #travel',
      time: now.subtract(h(9)),
    ),
    PublicPost(
      address: 'travel_korea',
      name: ko ? '대한민국 여행' : 'Travel Korea',
      members: 58210,
      text: ko ? '겨울 부산 여행, 꼭 가 볼 곳 10곳 #여행' : 'Winter in Busan: 10 places to visit #travel',
      time: now.subtract(const Duration(days: 1)),
    ),
  ]);
}
