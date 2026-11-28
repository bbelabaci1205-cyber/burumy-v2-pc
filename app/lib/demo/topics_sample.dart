// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 주제 (group topics, tip 527): a club group with topics
// switched on (side rail), some unread in 천문 and 맛집, 화학 closed.
// I'm the owner, so 운영 도구 > 주제 can switch tabs/list and add topics.
import 'dart:convert';

import '../core/backend.dart';
import '../core/topics.dart';
import 'demo_backend.dart';

/// [at]: the time the sample is built around (tests pin it).
void addTopicsSample(FakeBackend b, bool ko, {DateTime? at}) {
  const id = '!science';
  final now = at ?? DateTime.now();
  b.names[id] = ko ? '과학 동아리' : 'Science Club';
  b.groups.add(id);
  b.roomMembers[id] = [
    const Member(userId: '@me:test', name: 'me', role: 'owner'),
    Member(userId: '@mina:test', name: ko ? '미나' : 'Mina', role: 'admin'),
    Member(userId: '@leo:test', name: ko ? '레오' : 'Leo', role: 'member'),
    Member(userId: '@jun:test', name: ko ? '준' : 'Jun', role: 'member'),
    Member(userId: '@sora:test', name: ko ? '소라' : 'Sora', role: 'member'),
  ];
  final t = Topics(
    on: true,
    list: [
      const Topic(id: Topics.general),
      Topic(id: 'tnews', name: ko ? '공지' : 'News', icon: '📢'),
      Topic(id: 'tastro', name: ko ? '천문' : 'Astronomy', color: 2),
      Topic(id: 'tchem', name: ko ? '화학' : 'Chemistry', color: 3, closed: true),
      Topic(id: 'tfood', name: ko ? '맛집' : 'Food', icon: '🍔'),
    ],
    salt: '5c1e7a0b2d9f4e63a8b1c0d2e3f40516',
  );
  final pack = t.toJson();
  b.prefs['topics:$id'] = jsonEncode(pack);
  b.roomConfigs[id] = {
    ...?b.roomConfigs[id],
    Topics.cfgKey: {'h': Topics.fingerprint(pack)},
  };
  var n = 0;
  Msg m(String who, String text, int minAgo, [String? topic]) => Msg(
    id: 'sci${n++}',
    sender: who,
    body: text,
    time: now.subtract(Duration(minutes: minAgo)),
    mine: who == '@me:test',
    kind: 'text',
    topic: topic,
  );
  b.rooms[id] = [
    m('@sora:test', ko ? '안녕하세요! 이번에 새로 들어왔어요 🙌' : 'Hi! I just joined 🙌', 300),
    m('@mina:test', ko ? '이번 주 토요일 오후 2시, 과학관 앞에서 모여요.' : 'Saturday 2 PM, in front of the science museum.', 240, 'tnews'),
    m('@mina:test', ko ? '준비물: 쌍안경, 공책, 따뜻한 옷' : 'Bring binoculars, a notebook and warm clothes.', 238, 'tnews'),
    m('@me:test', ko ? '확인했어요!' : 'Got it!', 200, 'tnews'),
    m('@jun:test', ko ? '소금물 전기분해 결과 정리해서 올렸어요.' : 'I posted the salt-water electrolysis notes.', 180, 'tchem'),
    m('@mina:test', ko ? '화학 주제는 실험이 끝나서 닫아 둘게요.' : 'Closing Chemistry now that the experiment is done.', 170, 'tchem'),
    m('@leo:test', ko ? '어제 개기월식 보신 분? 달이 정말 빨갰어요 🌕' : 'Anyone see the lunar eclipse last night? So red 🌕', 50, 'tastro'),
    m('@sora:test', ko ? '저 봤어요! 사진도 찍었는데 흔들렸어요 😅' : 'Me! My photo came out blurry 😅', 45, 'tastro'),
    m('@leo:test', ko ? '다음엔 삼각대 가져가요. 토성 고리도 보일 거예요.' : 'Bring a tripod next time. Saturn\'s rings should show too.', 40, 'tastro'),
    m('@jun:test', ko ? '모임 끝나고 근처 국밥집 어때요?' : 'Soup place nearby after the meetup?', 20, 'tfood'),
    m('@sora:test', ko ? '좋아요! 과학관 옆 골목에 맛집 있어요.' : 'Yes! There\'s a good one in the alley next to the museum.', 12, 'tfood'),
    m('@leo:test', ko ? '다들 토요일에 봬요!' : 'See you all Saturday!', 5),
  ];
  // Read up to 3 hours ago in 천문/맛집 (unread counts), the rest seen.
  final seen = now.millisecondsSinceEpoch;
  b.prefs['topic_seen:$id'] = jsonEncode({
    'g': seen,
    'tnews': seen,
    'tchem': seen,
    'tastro': now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
    'tfood': now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
  });
  b.unreadCounts[id] = 5;
}
