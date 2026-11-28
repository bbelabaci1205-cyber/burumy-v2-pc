// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Example community for the web demo (Eric 2026-11-27): two of my chats,
// one open group, one that needs approval and one hidden admins' room.
import '../core/backend.dart';
import 'demo_backend.dart';

void addCommunitySample(FakeBackend b, bool ko) {
  const id = '!community_demo';
  final c = FakeCommunity(name: ko ? '디자인 크루' : 'Design Crew', about: ko ? '디자이너들이 모이는 곳이에요' : 'Where designers meet', role: 'owner', members: 214);
  b.communityBook[id] = c;
  b.roomMembers[id] = [
    const Member(userId: '@me:test', name: 'me', role: 'owner'),
    const Member(userId: '@mina:test', name: 'mina', role: 'admin'),
    const Member(userId: '@leo:test', name: 'leo', role: 'member'),
    const Member(userId: '@jun:test', name: 'jun', role: 'member'),
  ];
  // My own chats that are in it.
  for (final r in ['!r1', '!c']) {
    if (b.rooms.containsKey(r)) c.chats[r] = false;
  }
  // Chats of others: open, approval and hidden (admins only).
  final others = [
    CommunityChat(roomId: '!cm_open', name: ko ? '주말 드로잉 모임' : 'Weekend sketching', state: 'view', by: '@mina:test', members: 128),
    CommunityChat(roomId: '!cm_news', name: ko ? '디자인 크루 공지' : 'Design Crew news', channel: true, state: 'view', by: '@mina:test', members: 1284),
    CommunityChat(roomId: '!cm_ask', name: ko ? '포트폴리오 리뷰방' : 'Portfolio review', state: 'ask', by: '@leo:test', members: 54),
    CommunityChat(roomId: '!cm_staff', name: ko ? '운영진 방' : 'Staff room', state: 'ask', by: '@mina:test', members: 6, hidden: true),
  ];
  for (final o in others) {
    b.outsideChats[o.roomId] = o;
    c.chats[o.roomId] = o.hidden;
  }
}
