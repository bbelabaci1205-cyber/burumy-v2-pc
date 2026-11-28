// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Ten more example chats for the web demo (Eric 2026-11-26 "각 상황들 다
//볼 수 있도록"): big unread counts, muted, ticks, photo / voice / sticker /
// file / missed call, groups with a sender, a channel, a timer chat and a
// long two-line preview. The list is then ordered by time like the engine.
import 'dart:convert';

import '../core/ai_styles.dart';
import '../core/backend.dart';
import '../core/room_texts.dart';
import '../design/tokens.dart';
import '../ui/common.dart' show Avatar;
import 'demo_backend.dart';

void addMoreChats(FakeBackend b, bool ko, List<int> photo) {
  final now = DateTime(2026, 11, 23, 20, 10);
  var n = 0;
  String room(String ko0, String en0, {bool group = false, bool channel = false, String? peer}) {
    final id = '!m${n++}';
    b.names[id] = ko ? ko0 : en0;
    if (group) b.groups.add(id);
    if (channel) b.channels.add(id);
    if (peer != null) b.peers[id] = peer;
    return id;
  }

  Msg text(String id, String who, String body, DateTime at, {bool mine = false}) => Msg(id: id, sender: who, body: body, time: at, mine: mine, kind: 'text');

  Avatar.tint.addAll({
    for (final x in ko ? ['동네 친구들', '축구 동호회', '회사 공지'] : ['Neighbours', 'Football club', 'Company news']) x: Palette.tileTeal,
  });

  // 1. Lots unread (99+).
  final a = room('이수진', 'Sujin Lee', peer: '@sujin:test');
  // A shared AI 말투 (569): the style travels inside the link.
  final pirate = AiStyles.link(
    ko
        ? const AiStyle(id: '', emoji: '🏴‍☠️', name: '해적', rules: "해적 선장처럼 써 줘. '으하하'와 '이 몸은' 같은 말을 넣어서, 바다와 보물 이야기를 살짝 섞어.")
        : const AiStyle(
            id: '',
            emoji: '🏴‍☠️',
            name: 'Pirate',
            rules: "Write like a pirate captain. Say 'arr' and 'matey', and mention the sea and treasure a little.",
          ),
  );
  b.rooms[a] = [
    text('m1s', '@sujin:test', ko ? '내가 만든 AI 말투야 ㅋㅋ 써 봐\n$pirate' : 'I made an AI style lol try it\n$pirate', now.subtract(const Duration(minutes: 5))),
    text('m1', '@sujin:test', ko ? 'ㅋㅋㅋㅋ 이거 봤어? 대박이야' : 'lol did you see this?', now.subtract(const Duration(minutes: 3))),
  ];
  b.unreadCounts[a] = 128;

  // 2. Channel, muted, with news waiting.
  final c = room('회사 공지', 'Company news', group: true, channel: true, peer: '@company:test');
  b.rooms[c] = [
    text(
      'm2',
      '@company:test',
      ko ? '12월 워크숍 일정이 확정됐어요. 장소와 시간은 첨부 파일을 확인해 주세요.' : 'December workshop is set. See the file for place and time.',
      now.subtract(const Duration(minutes: 25)),
    ),
  ];
  b.mutedChats.add(c);
  b.unreadCounts[c] = 5;

  // 3. Group: someone is typing, the preview shows who wrote.
  final g = room('동네 친구들', 'Neighbours', group: true);
  // A poll with the 562 extras: description + photo, a place, a sticker, a
  // photo answer and an answer a member added (open votes, so 투표 결과 works).
  b.rooms[g] = [
    Msg(
      id: 'pl2',
      sender: '@doyun:test',
      body: ko ? '토요일 모임, 어디서 할까요?' : 'Saturday meetup: where?',
      time: now.subtract(const Duration(hours: 1)),
      mine: false,
      kind: 'poll',
      poll: PollInfo(
        question: ko ? '토요일 모임, 어디서 할까요?' : 'Saturday meetup: where?',
        description: ko ? '오후 2시부터 2시간 정도예요. 가고 싶은 곳이 없으면 선택지를 추가해 주세요.' : 'From 2 pm, about two hours. Add a place if yours is missing.',
        hasPhoto: true,
        options: [
          PollOption('a0', ko ? '성수 카페거리' : 'Seongsu cafés', 0, const [], false, '', 'geo:37.54450,127.05570'),
          PollOption('a1', ko ? '한강 공원 피크닉' : 'Han River picnic', 0, const [], false, 'buru_04_good'),
          PollOption('a2', ko ? '보드게임 카페' : 'Board-game café', 0, const [], true),
          PollOption('x1', ko ? '을지로 맛집 투어' : 'Euljiro food tour', 0, const [], false, '', '', '@jiwoo:test'),
        ],
        anonymous: false,
        addOptions: true,
      ),
    ),
    text('m3', '@jiwoo:test', ko ? '오늘 저녁 치킨 콜?' : 'Chicken tonight?', now.subtract(const Duration(minutes: 41))),
  ];
  b.pollPhotos['pl2|'] = photo;
  b.pollPhotos['pl2|a2'] = photo;
  b.seedVotes(g, 'pl2', const {
    '@jiwoo:test': ['x1'],
    '@doyun:test': ['a1'],
    '@mina:test': ['a1'],
  });
  b.typing[g] = ['@doyun:test'];
  b.unreadCounts[g] = 7;

  // 4. My photo with a caption, read (two ticks).
  final m = room('엄마', 'Mum', peer: '@mum:test');
  // 전화 안 받으면 메시지 남기기: Mum doesn't pick up (after 6 seconds).
  b.unansweredCalls.add(m);
  b.rooms[m] = [
    Msg(
      id: 'm4',
      sender: '@me:test',
      body: 'photo.png',
      caption: ko ? '오늘 점심이에요' : 'Lunch today',
      time: now.subtract(const Duration(hours: 3)),
      mine: true,
      kind: 'image',
    ),
  ];
  b.files['m4'] = photo;

  // 5. My message just sent (one tick: not read yet).
  final s = room('정우진', 'Woojin Jung', peer: '@woojin:test');
  b.rooms[s] = [text('m5', '@me:test', ko ? '도착하면 연락해 줘' : 'Text me when you get there', now.subtract(const Duration(minutes: 1)), mine: true)];

  // 6. A file.
  final f = room('세무사 사무실', 'Tax office', peer: '@tax:test');
  b.rooms[f] = [
    Msg(
      id: 'm6',
      sender: '@tax:test',
      body: ko ? '2026_연말정산_안내.pdf' : '2026_tax_guide.pdf',
      time: now.subtract(const Duration(days: 1, hours: 2)),
      mine: false,
      kind: 'file',
    ),
  ];

  // 7. Voice message, unread.
  final v = room('한지민', 'Jimin Han', peer: '@jimin:test');
  b.rooms[v] = [
    Msg(
      id: 'm7',
      sender: '@jimin:test',
      body: 'voice',
      time: now.subtract(const Duration(hours: 5)),
      mine: false,
      kind: 'audio',
      voice: VoiceInfo(const Duration(seconds: 23), [for (var k = 0; k < 40; k++) 120 + (k * 311) % 880]),
    ),
  ];
  b.unreadCounts[v] = 2;

  // 8. Group sticker, muted.
  final k = room('축구 동호회', 'Football club', group: true);
  b.rooms[k] = [Msg(id: 'm8', sender: '@coach:test', body: 'buru_03_love', time: now.subtract(const Duration(days: 2)), mine: false, kind: 'sticker')];
  b.mutedChats.add(k);
  b.unreadCounts[k] = 12;

  // 9. Missed call.
  final call = room('박지훈', 'Jihoon Park', peer: '@jihoon:test');
  final at = now.subtract(const Duration(hours: 7));
  b.rooms[call] = [
    Msg(
      id: 'm9',
      sender: '@jihoon:test',
      body: '',
      time: at,
      mine: false,
      kind: 'call',
      call: CallInfo(id: 'k9', video: false, state: 'missed', started: at),
    ),
  ];

  // 10. Timer chat (messages vanish after an hour).
  final t = room('비밀 프로젝트', 'Secret project', peer: '@hana:test');
  b.rooms[t] = [text('m10', '@hana:test', ko ? '자료는 내일까지만 볼 수 있어요' : 'The files are only up until tomorrow', now.subtract(const Duration(days: 3)))];
  b.timers[t] = 3600;

  // 대화 정리하기 sample: a group nobody wrote in for 8 months.
  final old = room('2025 여름 캠프', 'Summer camp 2025', group: true);
  b.rooms[old] = [text('m10b', '@hana:test', ko ? '사진 다 올렸어요!' : 'All photos are up!', now.subtract(const Duration(days: 240)))];

  // 11. Long message: two lines in the list.
  final l = room('최유나', 'Yuna Choi', peer: '@yuna:test');
  b.rooms[l] = [
    text(
      'm11',
      '@yuna:test',
      ko
          ? '어제 말한 책 다 읽었는데 생각보다 훨씬 좋았어. 마지막 장은 꼭 천천히 읽어 봐. 다음 주에 만나면 이야기하자!'
          : 'Finished the book you told me about, it was so much better than I thought. Read the last chapter slowly. Let’s talk next week!',
      now.subtract(const Duration(days: 4)),
    ),
  ];

  // 12. Five stories and five bubbles in all (Eric 2026-11-26 "스토리 방울
  // 5개씩"): sample.dart has two of each, three more friends add one each.
  final storyNow = DateTime.now();
  for (final (i, (id, who)) in [(a, '@sujin:test'), (v, '@jimin:test'), (l, '@yuna:test')].indexed) {
    b.storyList.add(
      Story(
        id: 'ms$i',
        roomId: id,
        eventId: 'ms$i',
        sender: who,
        mine: false,
        time: storyNow.subtract(Duration(minutes: 20 + 30 * i)),
        kind: 'image',
      ),
    );
    if (photo.isNotEmpty) b.files['ms$i'] = photo;
  }
  for (final (ko0, en0, who, kind) in [
    ('서지아', 'Jia Seo', '@jia:test', 'text'),
    ('강민호', 'Minho Kang', '@minho:test', 'image'),
    ('윤하늘', 'Haneul Yoon', '@haneul:test', 'text'),
  ]) {
    final id = room(ko0, en0, peer: who);
    b.rooms[id] = [];
    b.receiveBubble(id, who, kind, kind == 'image' ? photo : utf8.encode(kind == 'text' && who == '@jia:test' ? '🎉' : '🌙'));
  }

  // 13. Invite links (Eric 2026-11-26 "응 만들어"): a private link, a public
  // group with approval and two people asking, my own channel with its web
  // page on, and a friend sharing someone else's public channel.
  b.links['!r1'] = const RoomLink(kind: 'private', code: 'h3k8mtq2va7xw9pc4rzn6sd5je');
  b.links[g] = const RoomLink(kind: 'public', code: 'mangwon_friends', approval: true);
  b.abouts[g] = ko ? '망원동 이웃끼리 맛집과 나눔 소식을 나눠요' : 'Neighbours sharing food spots and give-aways';
  b.requests[g] = [JoinRequest(userId: '@seoa:test', name: ko ? '윤서아' : 'Seoa Yoon'), JoinRequest(userId: '@hyunwoo:test', name: ko ? '김현우' : 'Hyunwoo Kim')];
  final diary = room('필름 사진 일기', 'Film photo diary', group: true, channel: true);
  Avatar.tint[ko ? '필름 사진 일기' : 'Film photo diary'] = Palette.tileOrange;
  b.rooms[diary] = [text('m40', '@me:test', ko ? '오늘은 성수동 골목에서 찍은 사진이에요' : 'Today: an alley in Seongsu', now.subtract(const Duration(days: 5)), mine: true)];
  b.roomMembers[diary] = [
    const Member(userId: '@me:test', name: 'me', role: 'owner'),
    const Member(userId: '@sujin:test', name: 'sujin', role: 'member'),
    const Member(userId: '@jimin:test', name: 'jimin', role: 'member'),
  ];
  b.links[diary] = const RoomLink(kind: 'public', code: 'film_diary', web: true);
  b.abouts[diary] = ko ? '필름 카메라로 찍은 서울 골목 사진을 올려요' : 'Seoul alleys on film';
  // 환영 인사 (Telegram tip 575): join Seoul Runners from Sujin's link and
  // the channel greets me with a photo, only I see it.
  final hello = jsonEncode({'url': 'demo://secret/welcome-runners', 'key': 'demo'});
  b.secrets[hello] = photo;
  final pack = RoomTexts(
    welcome: ko ? '**서울 러너스에 오신 걸 환영해요!** 🏃\n\n매주 토요일 아침 7시, 여의나루역 2번 출구에서 출발해요.\n처음이면 5km 코스부터 같이 달려요.\n\n> 고정 메시지에서 이번 주 코스를 확인해 주세요' : '**Welcome to Seoul Runners!** 🏃\n\nEvery Saturday 7 am from Yeouinaru station exit 2.\nNew? Start with our 5 km route.\n\n> See the pinned post for this week\'s route',
    rules: ko ? '1. 서로 존중해요\n2. 광고 금지' : '1. Be kind\n2. No ads',
    media: {'file': hello, 'mime': 'image/png', 'name': 'runners.png'},
    at: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
    salt: '5e0u1',
  ).toJson();
  b.welcomeOnJoin['!seoul_runners'] = (pack, '@seoulrunners:test', RoomTexts.fingerprint(pack));
  b.outside['seoul_runners'] = LinkPeek(
    roomId: '!seoul_runners',
    name: ko ? '서울 러너스' : 'Seoul Runners',
    about: ko ? '주말마다 한강을 같이 달려요. 처음 오셔도 괜찮아요.' : 'We run along the Han river every weekend. Beginners welcome.',
    members: 1284,
    channel: true,
  );
  b.rooms[a]!.insert(
    0,
    text(
      'm41',
      '@sujin:test',
      ko ? '이 채널 들어와 봐 https://burumy.app/c/seoul_runners' : 'Join this channel https://burumy.app/c/seoul_runners',
      now.subtract(const Duration(hours: 2)),
    ),
  );

  // Newest first, like the engine (pins stay on top in chats()).
  DateTime last(String id) => b.rooms[id]!.isEmpty ? DateTime(2000) : b.rooms[id]!.last.time;
  final order = b.rooms.keys.toList()..sort((x, y) => last(y).compareTo(last(x)));
  final sorted = {for (final id in order) id: b.rooms[id]!};
  b.rooms
    ..clear()
    ..addAll(sorted);
}
