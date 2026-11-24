// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Example chats (Korean or English) for screenshots and the look-only demo.
import '../core/backend.dart';
import 'demo_backend.dart';

/// Example chats for screenshots and the demo.
FakeBackend demoSample(bool ko, List<int> photo) {
  final b = FakeBackend();
  final names = ko ? ['김민지', '디자인 팀', '박서준', '가족'] : ['Mina Kim', 'Design Team', 'Leo Park', 'Family'];
  final texts = ko
      ? ['내일 3시에 볼까요?', '시안 올렸어요. 확인 부탁해요!', '사진', '저녁 뭐 먹을까?']
      : ['See you at 3 tomorrow?', 'Uploaded the drafts. Take a look!', 'Photo', 'What should we eat tonight?'];
  final now = DateTime(2026, 11, 23, 20, 10);
  for (var i = 0; i < names.length; i++) {
    final id = '!r$i';
    b.names[id] = names[i];
    b.rooms[id] = [
      if (i == 0) ...[
        Msg(id: 'a', sender: '@mina:test', body: ko ? '안녕하세요!' : 'Hi there!', time: now.subtract(const Duration(minutes: 9)), mine: false, kind: 'text'),
        Msg(
          id: 'b',
          sender: '@me:test',
          body: ko ? '안녕하세요, 반가워요' : 'Hello, nice to meet you',
          time: now.subtract(const Duration(minutes: 8)),
          mine: true,
          kind: 'text',
        ),
        Msg(id: 'img', sender: '@me:test', body: 'photo.png', time: now.subtract(const Duration(minutes: 7)), mine: true, kind: 'image'),
        Msg(
          id: 'fw',
          sender: '@mina:test',
          body: ko ? '사진전 일정: 12월 7일 토요일' : 'Photo show: Sat, Dec 7',
          time: now.subtract(const Duration(minutes: 6)),
          mine: false,
          kind: 'text',
          forwarded: true,
        ),
        Msg(
          id: 'd',
          sender: '@me:test',
          body: ko ? '주말 사진이에요' : 'Photos from the weekend',
          time: now.subtract(const Duration(minutes: 1)),
          mine: true,
          kind: 'text',
        ),
        Msg(id: 'vo', sender: '@mina:test', body: 'p.png', time: now.subtract(const Duration(minutes: 2)), mine: false, kind: 'image', viewOnce: true),
        Msg(
          id: 'vc',
          sender: '@me:test',
          body: 'voice',
          time: now.subtract(const Duration(seconds: 55)),
          mine: true,
          kind: 'audio',
          voice: VoiceInfo(const Duration(seconds: 12), [for (var k = 0; k < 40; k++) 150 + (k * 263) % 870]),
        ),
        Msg(
          id: 'cl',
          sender: '@mina:test',
          body: '',
          time: now.subtract(const Duration(minutes: 4)),
          mine: false,
          kind: 'call',
          call: CallInfo(
            id: 'k1',
            video: false,
            state: 'ended',
            started: now.subtract(const Duration(minutes: 4)),
            answered: now.subtract(const Duration(minutes: 4)),
            ended: now.subtract(const Duration(minutes: 4)).add(const Duration(minutes: 3, seconds: 25)),
          ),
        ),
        Msg(id: 'tm', sender: '@me:test', body: '86400', time: now.subtract(const Duration(seconds: 50)), mine: true, kind: 'timer'),
        Msg(
          id: 'st',
          sender: '@mina:test',
          body: 'buru_03_love',
          time: now.subtract(const Duration(seconds: 30)),
          mine: false,
          kind: 'sticker',
          expiresAt: now.add(const Duration(days: 1)),
        ),
      ],
      Msg(
        id: 'c$i',
        sender: '@x:test',
        body: texts[i],
        time: now.subtract(Duration(hours: i * 9)),
        mine: false,
        kind: i == 2 ? 'image' : 'text',
      ),
    ];
  }
  // A group with several people, a reply and an edited message.
  final team = b.rooms['!r1']!;
  b.groups.add('!r1');
  team.insertAll(0, [
    Msg(
      id: 'g1',
      sender: '@mina:test',
      body: ko ? '오늘 회의 자료 공유할게요' : "I'll share today's meeting notes",
      time: now.subtract(const Duration(hours: 10, minutes: 30)),
      mine: false,
      kind: 'text',
    ),
    Msg(
      id: 'g2',
      sender: '@leo:test',
      body: ko ? '좋아요, 3쪽 표 확인했어요' : 'Great, checked the table on page 3',
      time: now.subtract(const Duration(hours: 10, minutes: 20)),
      mine: false,
      kind: 'text',
      replyTo: 'g1',
      reactions: const [Reaction('👍', 3, 'x'), Reaction('❤️', 1, null)],
    ),
    Msg(
      id: 'g3',
      sender: '@me:test',
      body: ko ? '저도 볼게요. 내일까지 정리할게요' : "I'll look too and sum it up by tomorrow",
      time: now.subtract(const Duration(hours: 10, minutes: 10)),
      mine: true,
      kind: 'text',
      replyTo: 'g2',
      edited: true,
    ),
  ]);
  team.add(
    Msg(
      id: 'lk',
      sender: '@mina:test',
      body: ko ? '시안 정리했어요 https://burumy.app/notes/1' : 'Drafts are here https://burumy.app/notes/1',
      time: now.subtract(const Duration(hours: 10)),
      mine: false,
      kind: 'text',
      preview: LinkCard(
        url: 'https://burumy.app/notes/1',
        title: ko ? '디자인 시안 2차' : 'Design drafts, round 2',
        description: ko ? '메인 화면과 대화 목록 시안을 모았어요.' : 'Main screen and chat list drafts in one place.',
        site: 'burumy.app',
        hasImage: true,
      ),
    ),
  );
  team.add(
    Msg(
      id: 'pl',
      sender: '@mina:test',
      body: ko ? '회식 날짜 정해요' : 'Pick a date for team dinner',
      time: now.subtract(const Duration(hours: 9, minutes: 50)),
      mine: false,
      kind: 'poll',
      poll: PollInfo(
        question: ko ? '회식 날짜 정해요' : 'Pick a date for team dinner',
        options: [
          PollOption('a0', ko ? '금요일 저녁' : 'Friday night', 5),
          PollOption('a1', ko ? '토요일 점심' : 'Saturday lunch', 2),
          PollOption('a2', ko ? '다음 주에' : 'Next week', 1),
        ],
        anonymous: true,
        voters: 8,
        mine: const ['a0'],
      ),
    ),
  );
  team.sort((x, y) => x.time.compareTo(y.time));
  b.typing['!r1'] = ['@leo:test'];
  b.timers['!r0'] = 86400;
  b.pins['!r1'] = ['g1'];
  b.streaks['!r0'] = (12, false);
  b.streaks['!r2'] = (5, true);
  // Chat list order: family pinned on top, team muted with news waiting,
  // one old chat in the archive.
  b.pinnedChats.add('!r3');
  b.mutedChats.add('!r1');
  b.unreadCounts['!r1'] = 3;
  b.unreadCounts['!r2'] = 1;
  b.names['!old'] = ko ? '중고 거래' : 'Marketplace';
  b.rooms['!old'] = [
    Msg(
      id: 'o1',
      sender: '@seller:test',
      body: ko ? '거래 감사합니다' : 'Thanks for the trade',
      time: now.subtract(const Duration(days: 9)),
      mine: false,
      kind: 'text',
    ),
  ];
  // The other person of each 1:1 (block, profile).
  b.peers['!r0'] = '@mina:test';
  b.peers['!r2'] = '@leo:test';
  b.archivedChats.add('!old');
  // A channel seen as a subscriber.
  b.names['!c'] = ko ? '부루미 소식' : 'Burumy News';
  b.groups.add('!c');
  b.channels.add('!c');
  b.peers['!c'] = '@burumy:test';
  b.owner = false;
  b.rooms['!c'] = [
    Msg(
      id: 'n1',
      sender: '@burumy:test',
      body: ko ? '새 버전이 나왔어요. 그룹과 채널을 만들 수 있어요.' : 'A new version is out. You can now make groups and channels.',
      time: now.subtract(const Duration(days: 1)),
      mine: false,
      kind: 'text',
    ),
    // Channel tools (cards), as subscribers see them.
    for (final (i, (kind, data)) in <(String, Map<String, Object?>)>[
      (
        'rich',
        {
          'title': ko ? '이번 주 업데이트' : "This week's update",
          'blocks': [
            {'t': 'p', 'text': ko ? '많이 기다리셨죠. 세 가지가 달라졌어요.' : 'Three things changed.'},
            {'t': 'li', 'text': ko ? '채널 도구 9가지' : '9 channel tools'},
            {'t': 'li', 'text': ko ? '퀴즈와 마감 시간' : 'Quizzes and deadlines'},
            {'t': 'quote', 'text': ko ? '서버는 글 내용을 볼 수 없어요.' : 'The server never sees posts.'},
          ],
        },
      ),
      (
        'links',
        {
          'text': ko ? '부루미 소식을 더 보고 싶다면' : 'More Burumy news',
          'buttons': [
            {'label': ko ? '홈페이지' : 'Website', 'url': 'https://burumy.app', 'color': '', 'row': 0},
            {'label': ko ? '도움말' : 'Help', 'url': 'https://burumy.app/help', 'color': 'blue', 'row': 0},
            {'label': ko ? '의견 보내기' : 'Feedback', 'url': 'https://burumy.app/feedback', 'color': 'purple', 'row': 1},
          ],
          'style': {'color': 'green', 'glass': true, 'size': 'm', 'shape': 'round', 'ink': 'auto'},
        },
      ),
      (
        'faq',
        {
          'title': ko ? '자주 묻는 질문' : 'FAQ',
          'items': [
            {'q': ko ? '대화는 어디에 저장돼요?' : 'Where are chats kept?', 'a': ko ? '내 휴대폰에만 있어요. 서버에는 잠긴 글만 지나가요.' : 'Only on your phone.'},
            {'q': ko ? '전화번호가 필요해요?' : 'Do I need a phone number?', 'a': ko ? '아니요. 아이디만 있으면 돼요.' : 'No. An ID is enough.'},
          ],
        },
      ),
      ('lottery', {'prize': ko ? '커피 쿠폰 2장' : '2 coffee coupons', 'winners': 2, 'ends_at': 0, 'note': '', 'announce': false}),
      ('checkin', {'text': ko ? '지진 소식이 있어요. 모두 괜찮아요?' : 'There was an earthquake. Is everyone OK?'}),
    ].indexed)
      Msg(
        id: 'card$i',
        sender: '@burumy:test',
        body: cardBody(kind, data),
        time: now.subtract(Duration(hours: 20 - i * 3)),
        mine: false,
        kind: 'card',
        card: CardInfo(kind: kind, data: data, counts: kind == 'lottery' ? const {'in': 37} : (kind == 'checkin' ? const {'ok': 12, 'help': 1} : const {})),
      ),
  ];
  b.files['img'] = photo;
  // 저장한 메시지: saved from three chats plus my own notes, two tags
  // (kept on this device, like the real app).
  b.saved = 'saved';
  b.names['saved'] = '';
  b.rooms['saved'] = [
    Msg(
      id: 'sv1',
      sender: '@me:test',
      body: ko ? '사진전 일정: 12월 7일 토요일' : 'Photo show: Sat, Dec 7',
      time: now.subtract(const Duration(days: 3)),
      mine: true,
      kind: 'text',
      forwarded: true,
    ),
    Msg(
      id: 'sv2',
      sender: '@me:test',
      body: ko ? '시안 모음 https://burumy.app/design' : 'All drafts https://burumy.app/design',
      time: now.subtract(const Duration(days: 2)),
      mine: true,
      kind: 'text',
      forwarded: true,
    ),
    Msg(
      id: 'sv3',
      sender: '@me:test',
      body: ko ? '장보기: 우유, 계란, 사과' : 'Groceries: milk, eggs, apples',
      time: now.subtract(const Duration(days: 1)),
      mine: true,
      kind: 'text',
    ),
    Msg(id: 'sv4', sender: '@me:test', body: 'photo.png', time: now.subtract(const Duration(hours: 5)), mine: true, kind: 'image', forwarded: true),
    Msg(
      id: 'sv5',
      sender: '@me:test',
      body: ko ? '내일 아침 9시 회의 자료 챙기기' : 'Bring the notes to the 9 am meeting',
      time: now.subtract(const Duration(minutes: 40)),
      mine: true,
      kind: 'text',
    ),
  ];
  b.files['sv4'] = photo;
  // Friends' stories (24 h, encrypted to friends; no view records).
  // Stories count from the real time so they stay fresh in the demo and
  // read the same ("N시간") whenever they are looked at.
  final storyNow = DateTime.now();
  b.storyList.addAll([
    Story(
      id: 'st1',
      roomId: '!r0',
      eventId: 'st1',
      sender: '@mina:test',
      mine: false,
      time: storyNow.subtract(const Duration(hours: 3)),
      kind: 'image',
      caption: ko ? '주말 사진전 🎞️' : 'Weekend photo show 🎞️',
    ),
    Story(id: 'st2', roomId: '!r0', eventId: 'st2', sender: '@mina:test', mine: false, time: storyNow.subtract(const Duration(hours: 2)), kind: 'image'),
    Story(
      id: 'st3',
      roomId: '!r2',
      eventId: 'st3',
      sender: '@leo:test',
      mine: false,
      time: storyNow.subtract(const Duration(hours: 1)),
      kind: 'image',
      caption: ko ? '오늘 하늘' : 'Sky today',
    ),
  ]);
  // Friend feed samples (shown only while the feed switch is on).
  b.storyList.insertAll(0, [
    Story(
      id: 'fd1',
      roomId: '!r2',
      eventId: 'fd1',
      sender: '@leo:test',
      mine: false,
      time: storyNow.subtract(const Duration(days: 1)),
      kind: 'text',
      caption: ko ? '이번 주말 캠핑 갈 사람? 장소는 가평 쪽으로 생각 중이에요 ⛺️' : 'Camping this weekend, anyone? Thinking of the lake ⛺️',
      feed: true,
    ),
    Story(
      id: 'fd2',
      roomId: '!r0',
      eventId: 'fd2',
      sender: '@mina:test',
      mine: false,
      time: storyNow.subtract(const Duration(hours: 5)),
      kind: 'image',
      caption: ko ? '전시 마지막 날, 사람이 정말 많았어요' : 'Last day of the show, so many people',
      feed: true,
    ),
  ]);
  b.files['fd2'] = photo;
  b.files['st1'] = photo;
  b.files['st2'] = photo;
  b.files['st3'] = photo;
  b.prefs['saved_tags'] = '{"sv1":"✅","sv3":"❤️"}';
  b.prefs['saved_from'] = '{"sv1":"!r0","sv2":"!r1","sv4":"!r3"}';
  b.receiveBubble('!r0', '@mina:test', 'text', [0xF0, 0x9F, 0xA5, 0xB3]);
  b.receiveBubble('!r2', '@leo:test', 'image', b.files['img']!);
  b.previewImages['lk'] = b.files['img']!;
  b.readAt = now.subtract(const Duration(minutes: 5));
  b.bios['@mina:test'] = ko ? '사진 찍는 걸 좋아해요 📷' : 'I love taking photos 📷';
  return b;
}
