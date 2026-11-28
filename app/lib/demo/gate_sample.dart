// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo of the join helper (가입 심사 도우미):
// - a public group someone shared ("음악 만드는 사람들", helper on, 2 quiz
//   questions + 1 written): open the link and try the quiz;
// - my group "망원동 친구들" (approval on): join questions written, three
//   people waiting with answers, helper off: switch it on and watch it
//   decide (one let in, one turned down for an empty answer, one for a
//   blocked word).
import '../core/backend.dart';
import 'demo_backend.dart';

void addGateSample(FakeBackend b, bool ko) {
  final now = b.now;
  // 1. Someone else's public group with the helper on.
  const music = '!music_makers';
  b.outside['music_makers'] = LinkPeek(
    roomId: music,
    name: ko ? '음악 만드는 사람들' : 'Music makers',
    about: ko ? '집에서 곡을 만드는 사람들이 작업물을 나누고 피드백해요.' : 'Home producers sharing tracks and feedback.',
    members: 412,
    approval: true,
  );
  b.roomConfigs[music] = {
    'gate': const GateSettings(on: true).toJson(),
    'join_questions': [
      GateQuestion(
        q: ko ? 'BPM은 무엇을 나타낼까요?' : 'What does BPM measure?',
        choices: ko ? ['곡의 빠르기', '곡의 길이', '음의 높이', '악기 수'] : ['How fast a song is', 'How long a song is', 'How high a note is', 'Number of instruments'],
        right: 0,
      ).toJson(),
      GateQuestion(q: ko ? '소리 파일이 아닌 것은?' : 'Which one is not a sound file?', choices: const ['WAV', 'MP3', 'PDF', 'FLAC'], right: 2).toJson(),
      GateQuestion(q: ko ? '요즘 어떤 음악을 만들고 있나요?' : 'What kind of music are you making?').toJson(),
    ],
  };
  // A friend shares the link in a chat that already has a shared link.
  final chat = b.rooms.entries.where((e) => e.value.any((m) => m.id == 'm41')).firstOrNull?.key;
  if (chat != null) {
    b.rooms[chat]!.insert(
      0,
      Msg(
        id: 'm41g',
        sender: '@sujin:test',
        body: ko ? '음악 모임 여기 좋아 https://burumy.app/c/music_makers' : 'Nice music group https://burumy.app/c/music_makers',
        time: now.subtract(const Duration(hours: 1)),
        mine: false,
        kind: 'text',
      ),
    );
  }

  // 2. My own group with approval on: questions set, helper off, people waiting.
  final mine = b.links.entries.where((e) => e.value.code == 'mangwon_friends').firstOrNull?.key;
  if (mine == null) return;
  b.roomConfigs[mine] = {
    ...?b.roomConfigs[mine],
    'gate': GateSettings(words: [ko ? '코인' : 'crypto']).toJson(),
    'join_questions': [
      GateQuestion(
        q: ko ? '우리 모임은 어느 동네 모임일까요?' : 'Which neighbourhood is this group for?',
        choices: ko ? ['망원동', '성수동', '연남동'] : ['Mangwon', 'Seongsu', 'Yeonnam'],
        right: 0,
      ).toJson(),
      GateQuestion(q: ko ? '망원동 어디쯤 사세요?' : 'Where in Mangwon do you live?').toJson(),
    ],
  };
  b.requests[mine] = [
    JoinRequest(userId: '@seoa:test', name: ko ? '윤서아' : 'Seoa Yoon', answers: ['0', ko ? '망원역 2번 출구 근처요' : 'Near Mangwon station exit 2']),
    JoinRequest(userId: '@hyunwoo:test', name: ko ? '김현우' : 'Hyunwoo Kim', answers: const ['0', '']),
    JoinRequest(userId: '@promo7:test', name: ko ? '코인 무료 지급' : 'Free crypto', answers: ['0', ko ? '링크 눌러 보세요' : 'Click my link']),
  ];
}
