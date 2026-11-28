// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 답장·멘션 (2026-11-27, tips 455 · 399 · 249/320 ·
// 276): a running club group with a folded quote, a partial-quote reply
// to me, an @mention further up, a quote copied from another chat and new
// reactions on my message; in the 1:1 with 민지, a pin only I see.
import 'dart:convert';

import '../core/backend.dart';
import 'demo_backend.dart';

void addReplySample(FakeBackend b, bool ko) {
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));
  const g = '!run';
  b.names[g] = ko ? '한강 러닝 크루' : 'River Running Club';
  b.groups.add(g);
  b.roomMembers[g] = [
    Member(userId: '@me:test', name: 'me', role: 'owner', since: ago(60 * 24 * 30)),
    Member(userId: '@jiwoo:test', name: ko ? '지우' : 'Jiwoo', role: 'member', since: ago(60 * 24 * 20)),
    Member(userId: '@harin:test', name: ko ? '하린' : 'Harin', role: 'member', since: ago(60 * 24 * 20)),
    Member(userId: '@doyun:test', name: ko ? '도윤' : 'Doyun', role: 'member', since: ago(60 * 24 * 10)),
  ];
  Msg t(String id, String who, int min, String body, {String? replyTo, String? quote, String? quoteName, List<Reaction> reactions = const []}) => Msg(
    id: id,
    sender: who,
    body: body,
    time: ago(min),
    mine: who == '@me:test',
    kind: 'text',
    replyTo: replyTo,
    quote: quote,
    quoteName: quoteName,
    reactions: reactions,
  );
  b.rooms[g] = [
    t(
      'run1',
      '@me:test',
      95,
      ko ? '이번 주 토요일 아침 7시, 반포 한강공원에서 10km 어때요? 끝나고 근처에서 브런치도 먹어요 🏃' : 'Saturday 7 AM, 10 km at the river park? Brunch nearby after 🏃',
      reactions: const [Reaction('❤️', 3, null), Reaction('👍', 2, null)],
    ),
    t('run2', '@doyun:test', 90, ko ? '@me 코스 지도 한 번만 보내 줄 수 있어요? 처음이라 길을 잘 몰라서요' : '@me could you send the route map? First time here'),
    t('run3', '@harin:test', 80, ko ? '좋아요! 참고로 지난번 기사 내용이에요' : 'Nice! Here is the article from last time'),
    t(
      'run4',
      '@harin:test',
      79,
      ko
          ? '>> 겨울 아침 달리기는 몸이 데워지기 전까지 10분 정도 천천히 걷거나 가볍게 뛰는 게 좋아요.\n>> 얇은 옷을 여러 겹 입고, 땀이 나면 한 겹씩 벗어요.\n>> 손과 귀가 가장 먼저 차가워지니 장갑과 귀마개를 챙겨요.\n>> 물은 차갑지 않게, 달리기 전후로 한 컵씩 마셔요.\n>> 끝나면 바로 따뜻한 곳으로 들어가 몸을 천천히 식혀요.\n장갑 꼭 챙겨요 🧤'
          : '>> On winter mornings, walk or jog slowly for ten minutes until your body warms up.\n>> Wear thin layers and take one off when you start to sweat.\n>> Hands and ears get cold first, so bring gloves and ear warmers.\n>> Drink a cup of not-too-cold water before and after.\n>> Go somewhere warm right after and cool down slowly.\nDon\'t forget gloves 🧤',
    ),
    t(
      'run5',
      '@harin:test',
      60,
      ko ? '민지가 그러는데 토요일에 비 소식이 있대요 ☔️' : 'Mina says rain is coming on Saturday ☔️',
      quote: ko ? '토요일 오전에 비 온대요. 우산 챙겨요!' : 'Rain on Saturday morning. Bring an umbrella!',
      quoteName: ko ? '김민지' : 'Mina Kim',
    ),
    t('run6', '@doyun:test', 40, ko ? '비 오면 실내 트랙도 괜찮아요' : 'Indoor track is fine if it rains'),
    t('run7', '@harin:test', 30, ko ? '실내 트랙 어디 있어요?' : 'Where is the indoor track?'),
    t('run8', '@doyun:test', 25, ko ? '잠실 쪽에 하나 있어요' : 'There is one near Jamsil'),
    t(
      'run9',
      '@jiwoo:test',
      3,
      ko ? '7시 좋아요! 저는 물 넉넉히 챙길게요 💧' : '7 works! I\'ll bring plenty of water 💧',
      replyTo: 'run1',
      quote: ko ? '토요일 아침 7시' : 'Saturday 7 AM',
    ),
  ];
  // Newest chat, so it sits at the top of the list (the demo keeps the order rooms were added).
  final rest = Map.of(b.rooms)..remove(g);
  final mine = b.rooms[g]!;
  b.rooms
    ..clear()
    ..[g] = mine
    ..addAll(rest);
  b.unreadCounts[g] = 7;
  // The reactions on my invite came after I last looked.
  b.prefs['marks:$g'] = jsonEncode({'since': ago(200).millisecondsSinceEpoch, 'seen': [], 'rx': {}});
  // 1:1 with 민지: the photo show date pinned for me only.
  if (b.rooms['!r0']?.any((m) => m.id == 'fw') ?? false) b.prefs['mypins:!r0'] = jsonEncode({'fw': 0});
}
