// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 공유·링크 (tips 253 · 438 · 503 · 350 · 182): my team
// group has its main link (12 people came in through it) and four extra
// links — one going well, one nearly used up, one whose time is over and a
// cancelled one — so every ring colour shows.
import 'dart:typed_data';

import '../core/backend.dart';
import '../core/share_in.dart';
import '../core/room_links.dart';
import 'demo_backend.dart';

void addShareSample(FakeBackend b, bool ko, {DateTime? at, Uint8List? photo}) {
  final now = at ?? DateTime.now();

  // 다른 앱에서 보내기 (350 + 182): a photo and a link "shared from the
  // Photos app" (Settings > 다른 앱에서 보내기 체험; phones get the real share sheet).
  ShareInbox.demo = [
    if (photo != null) SharedItem(name: 'IMG_2041.png', mime: 'image/png', bytes: photo),
    const SharedItem(name: 'link', mime: 'text/plain', text: 'https://www.instagram.com/p/burumy-cake'),
  ];

  // 대화 링크 (438): Mina sends a bakery's link; tapping it opens a chat with
  // the bakery with "케이크 주문하고 싶어요" waiting in the composer.
  const bakery = '@sweetbake:test';
  b.directory[bakery] = ko ? '달콤 베이커리' : 'Sweet Bakery';
  final cake = ChatLink(userId: bakery, text: ko ? '안녕하세요! 생일 케이크 주문하고 싶어요 🎂' : "Hi! I'd like to order a birthday cake 🎂");
  b.rooms['!r0']?.insert(
    0,
    Msg(
      id: 'cl1',
      sender: '@mina:test',
      body: ko ? '케이크는 여기서 주문해! 링크 누르면 바로 대화창 열려\n${cake.url}' : 'Order the cake here, the link opens their chat\n${cake.url}',
      // Just before the sample chat's first message (it starts at 20:01).
      time: DateTime(2026, 11, 23, 19, 40),
      mine: false,
      kind: 'text',
    ),
  );
  const team = '!r1';
  const people = ['@mina:test', '@leo:test', '@sora:test', '@jia:test', '@minho:test', '@haneul:test'];
  b.mainUses[team] = (12, people.sublist(0, 4));
  b.inviteLinkMap[team] = [
    InviteLink(
      code: 'insta2profile7link8q4m9w2x',
      name: ko ? '인스타 프로필' : 'Instagram profile',
      until: now.add(const Duration(days: 4)),
      max: 100,
      uses: 23,
      joined: people,
      by: '@me:test',
      made: now.subtract(const Duration(days: 3)),
    ),
    InviteLink(
      code: 'friends4only5link6k2m8p3v7',
      name: ko ? '친구용' : 'For friends',
      until: now.add(const Duration(hours: 3)),
      max: 10,
      uses: 8,
      joined: people.sublist(1, 5),
      by: '@me:test',
      made: now.subtract(const Duration(hours: 20)),
    ),
    InviteLink(
      code: 'meetup3over2link9h4k7m2q5',
      until: now.subtract(const Duration(days: 1)),
      uses: 15,
      joined: people.sublist(2),
      by: '@me:test',
      made: now.subtract(const Duration(days: 8)),
    ),
    InviteLink(
      code: 'blog7gone3link4w8m2k5q9v6',
      name: ko ? '블로그' : 'Blog',
      uses: 2,
      joined: people.sublist(0, 2),
      by: '@me:test',
      made: now.subtract(const Duration(days: 12)),
      revoked: true,
    ),
  ];
}
