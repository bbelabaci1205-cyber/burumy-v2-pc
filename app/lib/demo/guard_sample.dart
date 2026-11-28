// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 협박 공격 막기 in the look-only demo (2026-11-26): a group I run, where
// someone quietly changed an old message (the owner sees "늦게 수정된 글")
// and a message several people reported is hidden for everyone; and a
// public group I'm a member of, where a brand-new member's photo stays
// hidden. Names are made up.
import '../core/backend.dart';
import '../core/trust.dart';
import 'demo_backend.dart';

void addGuardSample(FakeBackend b, bool ko, List<int> photo) {
  final now = b.now;
  final me = '@me:test';
  // 1. My group: a late edit and a reported message.
  const mine = '!guard_own';
  // 이름 색 (v1): Sora picked purple.
  b.demoColors[mine] = {'@sora:test': 'purple'};
  b.groups.add(mine);
  b.names[mine] = ko ? '동네 사진 모임' : 'Neighbourhood photos';
  b.roomMembers[mine] = [
    Member(userId: me, name: ko ? '나' : 'Me', role: 'owner', since: now.subtract(const Duration(days: 200))),
    Member(userId: '@sora:test', name: ko ? '소라' : 'Sora', role: 'member', since: now.subtract(const Duration(days: 120))),
    Member(userId: '@quiet99:test', name: 'quiet99', role: 'member', since: now.subtract(const Duration(days: 40))),
  ];
  b.roomConfigs[mine] = {'new_media_days': 7};
  final ownMsgs = [
    Msg(
      id: 'gd1',
      sender: '@quiet99:test',
      body: ko ? '이 링크에서 예전 사진 더 보세요 www.free-pics.xyz' : 'More old photos at www.free-pics.xyz',
      time: now.subtract(const Duration(days: 12)),
      mine: false,
      kind: 'text',
      edited: true,
      editedAt: now.subtract(const Duration(minutes: 20)),
      firstBody: ko ? '오늘 노을 정말 예뻤어요' : 'The sunset was lovely today',
    ),
    Msg(
      id: 'gd2',
      sender: '@sora:test',
      body: ko ? '토요일 출사 갈 사람?' : 'Photo walk on Saturday?',
      time: now.subtract(const Duration(hours: 3)),
      mine: false,
      kind: 'text',
    ),
    Msg(id: r'$gd_reported', sender: '@quiet99:test', body: 'x.png', time: now.subtract(const Duration(hours: 1)), mine: false, kind: 'image'),
    Msg(
      id: 'gd4',
      sender: me,
      body: ko ? '저요! 10시에 공원 입구에서 봐요' : "Me! See you at the park gate at 10",
      time: now.subtract(const Duration(minutes: 30)),
      mine: true,
      kind: 'text',
    ),
  ];
  const guard = '@guard:test';
  b.trust = TrustList(
    version: b.trust.version + 1,
    badges: b.trust.badges,
    flags: b.trust.flags,
    hidden: {...b.trust.hidden, r'$gd_reported', r'$gp_spam'},
    guard: guard,
  );

  // 2. A public group where I'm a member: a new member's photo is hidden.
  const open = '!guard_public';
  b.groups.add(open);
  b.names[open] = ko ? '여행 정보 공개방' : 'Open travel tips';
  b.roomMembers[open] = [
    const Member(userId: '@host:test', name: 'host', role: 'owner'),
    Member(userId: me, name: ko ? '나' : 'Me', role: 'member', since: now.subtract(const Duration(days: 30))),
    Member(userId: '@newbie_77:test', name: 'newbie_77', role: 'member', since: now.subtract(const Duration(hours: 2))),
    Member(userId: guard, name: ko ? '공개방 지킴이' : 'Public room guard', role: 'member', since: now.subtract(const Duration(days: 60))),
  ];
  b.roomConfigs[open] = {'new_media_days': 7};
  b.files[r'$gp_new'] = photo;
  final openMsgs = [
    Msg(
      id: 'gp1',
      sender: '@host:test',
      body: ko ? '제주 3박 4일 일정 공유해요' : 'Sharing a 4-day Jeju plan',
      time: now.subtract(const Duration(hours: 5)),
      mine: false,
      kind: 'text',
    ),
    Msg(id: r'$gp_new', sender: '@newbie_77:test', body: 'photo.png', time: now.subtract(const Duration(hours: 1)), mine: false, kind: 'image'),
    // The same ad in many public rooms: the guard hid it everywhere.
    Msg(
      id: r'$gp_spam',
      sender: '@coin_king:test',
      body: ko ? '오늘만 무료 코인 이벤트' : 'Free coins today only',
      time: now.subtract(const Duration(minutes: 55)),
      mine: false,
      kind: 'text',
    ),
    Msg(
      id: 'gp3',
      sender: '@newbie_77:test',
      body: ko ? '싸게 가는 법 www.cheap-trip.xyz' : 'Cheap trips www.cheap-trip.xyz',
      time: now.subtract(const Duration(minutes: 50)),
      mine: false,
      kind: 'text',
    ),
  ];
  // Newest first in the demo list.
  final rest = Map.of(b.rooms);
  b.rooms
    ..clear()
    ..[mine] = ownMsgs
    ..[open] = openMsgs
    ..addAll(rest);
}
