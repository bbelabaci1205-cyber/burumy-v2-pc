// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 그룹 묶음 #16 (2026-11-27, Telegram tips 94 · 556 ·
// 365 · 384): a badminton club group where I'm the owner.
// - 수진 is an anonymous admin: her notice shows the group's name and photo.
// - 지훈 has the admin-given tag "총무" (green); 민아 and 도윤 tagged
//   themselves (grey), since the group lets members do that.
// - 강력 스팸 차단 is on: a few seconds after the chat opens, a gambling ad
//   arrives and turns to dust (my phone removes it); 모임 관리 > 강력 스팸
//   차단 lists it with "스팸 아님".
// - My notice was read by 7 of 11: hold it, tap "7명 읽음".
import 'dart:async';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/group_tools.dart';
import 'demo_backend.dart';

const group16Room = '!badminton';

void addGroup16Sample(FakeBackend b, bool ko) {
  final now = DateTime.now();
  DateTime ago(int min) => now.subtract(Duration(minutes: min));
  const g = group16Room;
  b.names[g] = ko ? '동네 배드민턴 모임' : 'Neighbourhood Badminton';
  b.groups.add(g);
  Member m(String id, String ko1, String en, String role, int days) => Member(userId: '@$id:test', name: ko ? ko1 : en, role: role, since: ago(60 * 24 * days));
  b.roomMembers[g] = [
    m('me', 'me', 'me', 'owner', 120),
    m('sujin', '수진', 'Sujin', 'admin', 100),
    m('jihoon', '지훈', 'Jihoon', 'admin', 90),
    m('mina', '민아', 'Mina', 'member', 60),
    m('doyun', '도윤', 'Doyun', 'member', 40),
    m('harin', '하린', 'Harin', 'member', 30),
    m('seojun', '서준', 'Seojun', 'member', 30),
    m('yerin', '예린', 'Yerin', 'member', 20),
    m('taeo', '태오', 'Taeo', 'member', 14),
    m('jiwoo', '지우', 'Jiwoo', 'member', 10),
    m('nari', '나리', 'Nari', 'member', 7),
    m('junho', '준호', 'Junho', 'member', 5),
  ];
  b.roomConfigs[g] = {
    'own_tags': true,
    'antispam': true,
    'tags': {'@jihoon:test': ko ? '총무' : 'Treasurer'},
    'anon': AnonAdmins.withAnon(const {}, '@sujin:test', true, ago(60 * 24)),
  };
  b.ownTags[g] = {'@mina:test': ko ? '복식 좋아해요' : 'Doubles fan', '@doyun:test': ko ? '초보 환영' : 'Beginner'};
  Msg t(String id, String who, int min, String body) => Msg(id: id, sender: who, body: body, time: ago(min), mine: who == '@me:test', kind: 'text');
  b.rooms[g] = [
    t(
      'bd1',
      '@sujin:test',
      180,
      ko ? '📢 이번 주 토요일 오전 9시, 구민체육관 2층 코트예요. 셔틀콕은 모임에서 준비해요. 회비는 5,000원이에요.' : '📢 Saturday 9 AM, community gym court 2. Shuttles are on us. Fee 5,000 won.',
    ),
    t('bd2', '@mina:test', 170, ko ? '저 참석이요! 복식 하실 분 찾아요 🏸' : "I'm in! Looking for a doubles partner 🏸"),
    t('bd3', '@doyun:test', 160, ko ? '처음인데 라켓 빌릴 수 있나요?' : "First time here, can I borrow a racket?"),
    t('bd4', '@jihoon:test', 150, ko ? '네, 여분 라켓 2개 가져갈게요. 회비는 현장에서 받아요.' : "Yes, I'll bring 2 spare rackets. Fees on the day."),
    t('bd5', '@me:test', 60, ko ? '비 와도 실내라 그대로 해요. 확인하신 분은 이 글 꼭 읽어 주세요 🙏' : "Indoor, so rain doesn't matter. Please read this one 🙏"),
    t('bd6', '@harin:test', 20, ko ? '확인했어요! 토요일에 봬요' : 'Got it! See you Saturday'),
  ];
  final sent = ago(60);
  (DateTime, DateTime) read(int afterMin) => (sent.add(const Duration(minutes: 1)), sent.add(Duration(minutes: afterMin)));
  b.groupReads[g] = {
    '@sujin:test': read(2),
    '@jihoon:test': read(5),
    '@mina:test': read(7),
    '@doyun:test': read(12),
    '@harin:test': read(38),
    '@seojun:test': read(41),
    '@yerin:test': read(55),
  };
}

/// 강력 스팸 차단, live: each time the group is opened (at most every 40
/// seconds) a spam ad arrives, shows for a moment, and my phone removes it.
void wireGroup16Spam(FakeBackend b, AppState s, bool ko) {
  var n = 0;
  void arm() {
    b.onRead[group16Room] = () {
      Timer(const Duration(milliseconds: 2200), () async {
        n++;
        b.roomMembers[group16Room] = [
          ...?b.roomMembers[group16Room]?.where((m) => m.userId != '@promo_vip:test'),
          Member(userId: '@promo_vip:test', name: ko ? '수익보장' : 'Promo', role: 'member', since: DateTime.now()),
        ];
        b.rooms[group16Room]!.add(
          Msg(
            id: 'spam$n',
            sender: '@promo_vip:test',
            body: ko
                ? '🎰 토토·카지노 첫충 100% 지급!! 먹튀 없는 곳 ✅ 텔레문의 @vip_casino777 👉 open.kakao.com/o/vip$n'
                : '🎰 Casino first deposit 100% bonus!! contact me on telegram @vip_casino777 👉 bit.ly/vip$n',
            time: DateTime.now(),
            mine: false,
            kind: 'text',
          ),
        );
        // The chat shows it…
        await s.setPref('demo_spam_tick', '$n');
        // …and a moment later my phone (an admin) removes it as dust.
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        await s.antiSpamRoom(group16Room);
        Timer(const Duration(seconds: 40), arm);
      });
    };
  }

  arm();
}
