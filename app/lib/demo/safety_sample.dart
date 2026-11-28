// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 안전 묶음 in the look-only demo: Leo turned off sharing in our 1:1
// (only he can turn it back on) and sent a 한 번만 듣기 voice message;
// the design team's group has voice / round videos off for members, with
// one exception. Names are made up.
import '../core/backend.dart';
import 'demo_backend.dart';

void addSafetySample(FakeBackend b, {bool ko = true}) {
  const leo = '@leo:test';
  b.roomConfigs['!r2'] = {...?b.roomConfigs['!r2'], 'protect': true, 'protect_by': leo};
  final now = DateTime(2026, 11, 23, 20, 12);
  b.files['once-voice'] = const <int>[];
  b.rooms['!r2']?.add(Msg(id: 'once-voice', sender: leo, body: 'voiceonce-12000.m4a', time: now, mine: false, kind: 'audio', viewOnce: true));
  // 514: the look-alike account sits in one of my groups, so the
  // first-message card shows "같이 있는 그룹" with its picture.
  const hike = '!hike';
  b.groups.add(hike);
  b.names[hike] = ko ? '주말 등산 모임' : 'Weekend hikers';
  b.rooms[hike] = [
    Msg(
      id: 'hk1',
      sender: '@mina:test',
      body: ko ? '이번 주는 북한산 어때요?' : 'Bukhansan this week?',
      time: now.subtract(const Duration(days: 2)),
      mine: false,
      kind: 'text',
    ),
  ];
  b.roomMembers[hike] = const [
    Member(userId: '@me:test', name: 'me', role: 'member'),
    Member(userId: '@mina:test', name: 'mina', role: 'owner'),
    Member(userId: '@haneul_0fficial:test', name: 'haneul', role: 'member'),
  ];
  b.roomConfigs['!r1'] = {
    ...?b.roomConfigs['!r1'],
    'member_perms': {'voice': false, 'videonote': false},
    'perm_users': {
      '@mina:test': {'voice': true},
    },
  };
}
