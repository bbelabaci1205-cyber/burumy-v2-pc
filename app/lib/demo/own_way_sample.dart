// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): examples for the 우리식 batch (4대 메신저 보드
// '우리식으로', 2026-11-28).
// - 캡처 알림: 한지민 took a screenshot of a view-once photo (line in the
//   chat + chat list), and I took one in 박서준's chat.
// - 제일 친한 친구 ❤: 김민지 and I wrote to each other most this fortnight.
// - 1년 전 오늘: 저장한 메시지 has photos saved on this day 1 and 2 years ago.
// - 친구 피드 댓글: 김민지's post has comments from friends and from someone I
//   don't know (hidden); my own post shows every comment.
import 'dart:convert';

import '../core/backend.dart';
import '../core/feed_comments.dart';
import '../core/shot_alert.dart';
import 'demo_backend.dart';

void addOwnWaySample(FakeBackend b, bool ko, {required List<int> photo, required List<int> still}) {
  final now = b.clock;
  // 캡처 알림.
  final jimin = b.peers.entries.where((e) => e.value == '@jimin:test').firstOrNull?.key;
  if (jimin != null && (b.rooms[jimin]?.isNotEmpty ?? false)) {
    final last = b.rooms[jimin]!.map((m) => m.time).reduce((a, x) => x.isAfter(a) ? x : a);
    b.prefs['shots:$jimin'] = jsonEncode([ShotLine(who: '@jimin:test', at: last.add(const Duration(minutes: 2)), what: 'photo').toJson()]);
  }
  final leo = b.rooms['!r2'];
  if (leo != null && leo.isNotEmpty) {
    b.prefs['shots:!r2'] = jsonEncode([ShotLine(who: '@me:test', at: leo.first.time.subtract(const Duration(minutes: 1)), what: 'chat').toJson()]);
  }

  // 제일 친한 친구 ❤: a real back-and-forth with 김민지 two days ago.
  final mina = b.rooms['!r0'];
  if (mina != null) {
    final day = DateTime(now.year, now.month, now.day - 2, 21);
    final talk = ko
        ? [
            ('mina', '오늘 퇴근하고 뭐 해?'),
            ('me', '집에서 영화 볼까 해'),
            ('mina', '뭐 볼 건데?'),
            ('me', '아직 못 골랐어 ㅋㅋ'),
            ('mina', '그럼 내가 추천해 줄게'),
            ('me', '좋아 알려 줘'),
            ('mina', '"리틀 포레스트" 어때'),
            ('me', '오 그거 보고 싶었어'),
            ('mina', '보고 어땠는지 말해 줘'),
            ('me', '응 내일 얘기해!'),
            ('mina', '잘 자 🌙'),
            ('me', '너도 잘 자'),
          ]
        : [
            ('mina', 'What are you up to after work?'),
            ('me', 'Thinking of a movie at home'),
            ('mina', 'Which one?'),
            ('me', "Haven't picked yet lol"),
            ('mina', "I'll suggest one"),
            ('me', 'Go on'),
            ('mina', 'How about "Little Forest"'),
            ('me', "Oh I've wanted to see that"),
            ('mina', 'Tell me how it was'),
            ('me', "Sure, let's talk tomorrow!"),
            ('mina', 'Good night 🌙'),
            ('me', 'You too'),
          ];
    mina.insertAll(0, [
      for (final (i, (who, words)) in talk.indexed)
        Msg(
          id: 'bf$i',
          sender: who == 'me' ? '@me:test' : '@mina:test',
          body: words,
          time: day.add(Duration(minutes: i * 3)),
          mine: who == 'me',
          kind: 'text',
        ),
    ]);
  }

  // 1년 전 오늘: photos saved on this day in 2025 and 2024.
  final saved = b.rooms[b.saved];
  if (saved != null) {
    final y1 = DateTime(now.year - 1, now.month, now.day, 14, 20);
    final y2 = DateTime(now.year - 2, now.month, now.day, 11, 5);
    saved.insertAll(0, [
      Msg(id: 'mem2', sender: '@me:test', body: 'photo.jpg', caption: ko ? '첫눈 온 날' : 'First snow', time: y2, mine: true, kind: 'image'),
      Msg(id: 'mem1', sender: '@me:test', body: 'photo.png', caption: ko ? '제주도 바다 🌊' : 'Jeju sea 🌊', time: y1, mine: true, kind: 'image'),
      Msg(id: 'mem1b', sender: '@me:test', body: 'photo.jpg', time: y1.add(const Duration(minutes: 3)), mine: true, kind: 'image'),
    ]);
    b.files['mem1'] = photo;
    b.files['mem1b'] = still;
    b.files['mem2'] = still;
  }

  // 친구 피드 댓글 (아는 친구 댓글만).
  Map<String, Object> c(String id, String who, String text, Duration ago) => FeedComment(id: id, who: who, text: text, at: now.subtract(ago)).toJson();
  b.prefs['feed_c:fd2'] = jsonEncode([
    c('c1', '@leo:test', ko ? '와 사람 진짜 많다! 나도 가고 싶었는데' : 'Wow, packed! I wanted to go too', const Duration(hours: 4)),
    c('c2', '@yejin_client:test', ko ? '저도 다녀왔어요 :)' : 'I went too :)', const Duration(hours: 3)),
    c('c3', '@mina:test', ko ? '@박서준 다음 전시 같이 가자' : '@Leo next show together', const Duration(hours: 2)),
    c('c4', '@jimin:test', ko ? '사진 너무 예쁘다 📸' : 'Lovely photo 📸', const Duration(hours: 1)),
  ]);
  b.storyList.insert(
    0,
    Story(
      id: 'fd0',
      roomId: '',
      eventId: 'fd0',
      sender: '@me:test',
      mine: true,
      time: now.subtract(const Duration(hours: 8)),
      kind: 'text',
      caption: ko ? '이번 주 목표: 매일 30분 걷기 🚶 같이 할 사람?' : 'Goal this week: 30 min walk every day 🚶 who is in?',
      feed: true,
    ),
  );
  b.prefs['feed_c:fd0'] = jsonEncode([
    c('d1', '@mina:test', ko ? '나 할래! 저녁에 같이 걷자' : "I'm in! Let's walk tonight", const Duration(hours: 7)),
    c('d2', '@sora_gym:test', ko ? '좋은 목표네요 💪' : 'Great goal 💪', const Duration(hours: 6)),
    c('d3', '@leo:test', ko ? '주말엔 한강 어때' : 'Han river on the weekend?', const Duration(hours: 5)),
  ]);
}
