// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Example chats (Korean or English) for screenshots and the look-only demo.
import 'dart:convert';

import '../core/backend.dart';
import '../core/doc.dart';
import 'demo_backend.dart';
import '../design/tokens.dart';
import '../ui/common.dart' show Avatar;

/// Example chats for screenshots and the demo.
FakeBackend demoSample(bool ko, List<int> photo) {
  final b = FakeBackend();
  // Groups and channels in blue tones, people keep their own colours.
  Avatar.tint
    ..clear()
    ..addAll({
      for (final n in ko ? ['디자인 팀', '부루미 소식'] : ['Design Team', 'Burumy News']) n: Palette.tileBlue,
      for (final n in ko ? ['가족'] : ['Family']) n: Palette.tileIndigo,
    });
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
        Msg(id: 'vo', sender: '@mina:test', body: 'p.png', time: now.subtract(const Duration(minutes: 2)), mine: false, kind: 'image', viewOnce: true, expiresAt: now.add(const Duration(hours: 21))),
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
  // Two pins (the bar steps through them) and the "고정했어요" line.
  team.add(
    Msg(
      id: 'gp1',
      sender: '@mina:test',
      body: '📌 ${ko ? '오늘 회의 자료 공유할게요' : "I'll share today's meeting notes"}',
      time: now.subtract(const Duration(hours: 10, minutes: 25)),
      mine: false,
      kind: 'card',
      card: CardInfo(kind: 'pin', data: {'id': 'g1', 'text': ko ? '오늘 회의 자료 공유할게요' : "I'll share today's meeting notes", 'notify': true}),
    ),
  );
  team.sort((x, y) => x.time.compareTo(y.time));
  b.typing['!r1'] = ['@leo:test'];
  b.timers['!r0'] = 86400;
  b.pins['!r1'] = ['g1', 'g2'];
  b.streaks['!r0'] = (12, false);
  b.streaks['!r2'] = (5, true);
  // Chat list order: family pinned on top, team muted with news waiting,
  // one old chat in the archive.
  b.pinnedChats.add('!r3');
  b.mutedChats.add('!r1');
  b.unreadCounts['!r1'] = 3;
  b.unreadCounts['!r2'] = 1;
  b.names['!old'] = ko ? '중고 거래' : 'Marketplace';
  b.notContacts.addAll(['!r3', '!old']);
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
  final longPost = demoLongArticle(b, ko);
  b.rooms['!c'] = [
    // Long posts (2026-11-27): older than the rest, so the screens that
    // show the newest messages stay as they were.
    for (final (i, data) in [
      {'doc': demoStudyGuide(ko)},
      longPost,
    ].indexed)
      Msg(
        id: 'post$i',
        sender: '@burumy:test',
        body: articleBody(data),
        time: now.subtract(Duration(days: 3 - i)),
        mine: false,
        kind: 'card',
        card: CardInfo(kind: 'article', data: data),
      ),
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
      (
        'flow',
        {
          'title': ko ? '오늘 밤 뭐 볼까요? 🍿' : 'What should you watch tonight? 🍿',
          'text': ko ? '질문 3개에 답하면 딱 맞는 영화를 골라 드려요.' : "Answer three quick questions and we'll pick a movie.",
          'start': ko ? '내 영화 찾기' : 'Find my movie',
          'steps': [
            {
              'q': ko ? '오늘 기분은요?' : 'What are you in the mood for?',
              'choices': [
                {'label': ko ? '신나게' : 'Adventure', 'to': 's1'},
                {'label': ko ? '웃고 싶어요' : 'Comedy', 'to': 's1'},
                {'label': ko ? '두근두근' : 'Thriller', 'to': 's1'},
                {'label': ko ? '차분하게' : 'Documentary', 'to': 'r2'},
              ],
            },
            {
              'q': ko ? '시간은 얼마나 있어요?' : 'How much time do you have?',
              'choices': [
                {'label': ko ? '90분 이하' : 'Under 90 min', 'to': 's2'},
                {'label': ko ? '2시간쯤' : 'Around 2 hours', 'to': 's2'},
                {'label': ko ? '긴 영화도 좋아요' : 'Make it an epic', 'to': 'r0'},
              ],
            },
            {
              'q': ko ? '누구랑 봐요?' : 'Who are you watching with?',
              'choices': [
                {'label': ko ? '혼자' : 'Just me', 'to': 'r0'},
                {'label': ko ? '연인' : 'Date night', 'to': 'r1'},
                {'label': ko ? '친구들' : 'Friends', 'to': 'r1'},
              ],
            },
          ],
          'results': [
            {
              'title': ko ? '우주 대서사 액션 🚀' : 'Space epic 🚀',
              'text': ko ? '큰 화면으로 보면 더 멋진 영화예요.' : 'Best on the biggest screen you can find.',
              'link': {'label': ko ? '예고편 보기' : 'Watch trailer', 'url': 'https://burumy.app/movies/epic'},
            },
            {'title': ko ? '로맨틱 코미디 💕' : 'Rom-com 💕', 'text': ko ? '같이 웃기 좋은 영화예요.' : 'Great to laugh together.', 'link': null},
            {'title': ko ? '자연 다큐멘터리 🌿' : 'Nature documentary 🌿', 'text': ko ? '잔잔하게 쉬어 가요.' : 'Slow down and relax.', 'link': null},
          ],
          'stats': true,
        },
      ),
    ].indexed)
      Msg(
        id: 'card$i',
        sender: '@burumy:test',
        body: cardBody(kind, data),
        time: now.subtract(Duration(hours: 20 - i * 3)),
        mine: false,
        kind: 'card',
        card: CardInfo(
          kind: kind,
          data: data,
          counts: switch (kind) {
            'lottery' => const {'in': 37},
            'checkin' => const {'ok': 12, 'help': 1},
            'flow' => const {'r0': 58, 'r1': 41, 'r2': 23},
            _ => const {},
          },
        ),
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
  b.readWhen = now.subtract(const Duration(minutes: 3));
  // Someone who takes invitations from contacts only turned one down.
  b.contactsOnly.add('@sora:test');
  b.blockedInvites['!r1'] = ['@sora:test'];
  b.bios['@mina:test'] = ko ? '사진 찍는 걸 좋아해요 📷' : 'I love taking photos 📷';
  return b;
}

/// A short formatted message (heading, table, formulas, list), like an
/// on-device AI answer or a teacher's note.
Map<String, Object?> demoStudyGuide(bool ko) => Doc(
  title: ko ? '기말고사 2026 정리' : 'Final Exams 2026',
  blocks: [
    DocBlock('p', text: ko ? '~~거의~~ 시험에 필요한 모든 것.' : '~~Almost~~ everything you need for the exam.'),
    DocBlock('h2', text: ko ? '시험 일정' : 'Exam schedule'),
    DocBlock(
      'table',
      rows: ko
          ? [
              ['과목', '월', '화', '수'],
              ['수학', '복습', '시험 1', '복습'],
              ['시간', '12:00', '10:00', '13:30'],
            ]
          : [
              ['Subject', 'Mon', 'Tue', 'Wed'],
              ['Math', 'Review', 'Exam 1', 'Review'],
              ['Time', '12:00', '10:00', '13:30'],
            ],
    ),
    DocBlock('h2', text: ko ? '공식' : 'Formulas'),
    DocBlock('p', text: ko ? '**피타고라스 정리:** 직각삼각형에서 \\(a^2 + b^2 = c^2\\)' : '**Pythagorean theorem:** in a right triangle \\(a^2 + b^2 = c^2\\)'),
    DocBlock('math', text: r'x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}'),
    DocBlock('h2', text: ko ? '정답' : 'Answer key'),
    DocBlock('ol', items: ['D', 'A', 'B', 'C']),
  ],
).toJson();

/// A long post sent as an encrypted file: only a preview is in the message.
Map<String, Object?> demoLongArticle(FakeBackend b, bool ko) {
  final doc = Doc(
    title: ko ? '아랍에미리트 여행 가이드' : 'Exploring the UAE',
    blocks: [
      DocBlock(
        'p',
        text: ko
            ? '미래 도시 같은 스카이라인부터 오래된 마을까지, 아랍에미리트는 새것과 옛것이 함께 있는 곳이에요.'
            : 'From futuristic skylines to ancient settlements, the UAE mixes modern luxury and rich culture.',
      ),
      DocBlock('h1', text: ko ? '두바이: 미래의 도시' : 'Dubai: City of the Future'),
      DocBlock('p', text: ko ? '두바이는 높은 빌딩, 큰 쇼핑몰, 바다 앞 산책로로 유명해요.' : 'Dubai is famous for towering skyscrapers, huge malls and waterfront walks.'),
      DocBlock('h2', text: ko ? '꼭 해 볼 것' : 'Things to do'),
      DocBlock(
        'ul',
        items: ko
            ? ['**부르즈 할리파** 전망대 올라가기', '**두바이 몰** 구경하기', '사막 사파리 (낙타 타기)', '**마리나 비치**에서 쉬기']
            : ['Visit the **Burj Khalifa**', 'Explore the **Dubai Mall**', 'Desert safari with camel rides', 'Relax on **Marina Beach**'],
      ),
      DocBlock(
        'pull',
        text: ko ? '셰이크 자이드 그랜드 모스크는 세계에서 가장 아름다운 건물 중 하나예요.' : 'The Sheikh Zayed Grand Mosque is one of the most beautiful buildings in the world.',
      ),
      DocBlock('h1', text: ko ? '아부다비: 문화의 도시' : 'Abu Dhabi: Culture and Grandeur'),
      DocBlock('p', text: ko ? '수도 아부다비에는 박물관과 모스크, 테마파크가 모여 있어요.' : 'The capital brings together museums, mosques and theme parks.'),
      DocBlock('h2', text: ko ? '가기 좋은 때' : 'Best times to visit'),
      DocBlock(
        'table',
        rows: ko
            ? [
                ['시기', '날씨', '추천'],
                ['11월–3월', '선선하고 맑음', '여행하기 가장 좋아요'],
                ['4월–5월', '따뜻함', '관광하기 좋아요'],
                ['6월–9월', '아주 더움', '실내 위주로'],
                ['10월', '조금씩 선선', '사람이 적어요'],
              ]
            : [
                ['Season', 'Weather', 'Tip'],
                ['Nov–Mar', 'Pleasant and mild', 'Best time to travel'],
                ['Apr–May', 'Warm', 'Good for sightseeing'],
                ['Jun–Sep', 'Very hot', 'Indoor attractions'],
                ['Oct', 'Cooling down', 'Fewer crowds'],
              ],
      ),
      DocBlock('quote', text: ko ? '여름엔 한낮을 피해서 아침이나 저녁에 움직이세요.' : 'In summer, go out in the morning or evening.'),
      DocBlock('code', lang: 'text', text: ko ? '공항 → 시내: 메트로 레드 라인 (약 30분)' : 'Airport → city: Metro Red Line (~30 min)'),
      DocBlock('hr'),
      DocBlock('h2', text: ko ? '마무리' : 'Final thoughts'),
      DocBlock(
        'p',
        text:
            (ko
                ? '두바이의 **화려함**이든 아부다비의 **문화**든, 아랍에미리트는 잊지 못할 여행이 될 거예요. '
                : 'Whether you seek **luxury** in Dubai or **culture** in Abu Dhabi, the UAE offers an unforgettable trip. ') *
            6,
      ),
    ],
  );
  final raw = utf8.encode(jsonEncode(doc.toJson()));
  const url = 'mxc://burumy.demo/long-post';
  b.blobs[url] = raw;
  return {
    'file': {
      'url': url,
      'key': {
        'kty': 'oct',
        'key_ops': ['encrypt', 'decrypt'],
        'alg': 'A256CTR',
        'k': 'demo',
        'ext': true,
      },
      'iv': 'demo',
      'hashes': {'sha256': 'demo'},
      'v': 'v2',
    },
    'preview': articlePreview(doc.toJson()),
    'size': raw.length,
    'chars': doc.chars,
    'images': 0,
  };
}
