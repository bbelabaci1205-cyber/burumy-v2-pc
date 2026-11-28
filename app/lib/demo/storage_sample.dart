// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for Telegram tip batches #22 (저장 공간·데이터) and #23
// (목록·알림 설정), 2026-11-27:
// - kept copies across chats and kinds (저장 공간 ring, 큰 파일, 대화별);
// - a month of data usage (데이터 사용량);
// - a draft typed "on my PC" in 박서준's chat (임시 글 이어쓰기);
// - a 3-second voice message from 엄마 in 가족 (알림음으로 저장) and one
//   saved sound already in 내 소리;
// - a folder "동네·취미" with link-able chats (폴더 공유하기) and a folder
//   link from 김민지 (폴더 추가하고 한 번에 들어가기).
// The second account's chats (다른 계정 미리보기) are made in demo_main.
import 'dart:convert';

import '../core/backend.dart';
import '../core/folder_link.dart';
import 'demo_backend.dart';

void addStorageSample(FakeBackend b, bool ko, {required List<int> tone, required List<int> savedTone}) {
  final now = DateTime.now();
  final day = now.millisecondsSinceEpoch;
  const mb = 1024 * 1024;
  String name(String k, String e) => ko ? k : e;

  // 1. Kept copies (on top of the 4-app sample's).
  final kept = <String, dynamic>{};
  try {
    kept.addAll(jsonDecode(b.prefs['media_kept'] ?? '{}') as Map<String, dynamic>);
  } catch (_) {}
  void keep(String id, String room, String type, int daysAgo, int bytes, String kind, String file) =>
      kept[id] = [room, type, day - 86400000 * daysAgo, bytes, kind, file];
  keep('st-v1', '!r3', 'group', 12, 612 * mb, 'video', name('제주도 가족 여행.mp4', 'jeju_trip.mp4'));
  keep('st-v2', '!r3', 'group', 4, 248 * mb, 'video', name('할머니 생신.mp4', 'grandma_birthday.mp4'));
  keep('st-p1', '!r3', 'group', 2, 38 * mb, 'photo', name('가족 사진 12장', '12 family photos'));
  keep('st-a1', '!r3', 'group', 1, 2 * mb, 'voice', name('음성 메시지', 'Voice message'));
  keep('st-f1', '!r1', 'group', 6, 186 * mb, 'file', name('디자인 시안 최종.zip', 'design_final.zip'));
  keep('st-f2', '!r1', 'group', 3, 24 * mb, 'file', name('발표 자료.pdf', 'slides.pdf'));
  keep('st-p2', '!r1', 'group', 3, 17 * mb, 'photo', name('화이트보드.jpg', 'whiteboard.jpg'));
  keep('st-v3', '!c', 'channel', 9, 420 * mb, 'video', name('부루미 소개 영상.mp4', 'burumy_intro.mp4'));
  keep('st-v4', '!c', 'channel', 20, 133 * mb, 'video', name('업데이트 안내.mp4', 'update_notes.mp4'));
  keep('st-p3', '!r0', 'dm', 5, 9 * mb, 'photo', name('전시회 사진.jpg', 'exhibition.jpg'));
  keep('st-a2', '!r0', 'dm', 1, 1 * mb, 'voice', name('음성 메시지', 'Voice message'));
  keep('st-f3', '!r2', 'dm', 8, 3 * mb, 'file', name('등산 코스.pdf', 'hiking_route.pdf'));
  b.prefs['media_kept'] = jsonEncode(kept);
  // One exception: 가족 keeps its copies.
  b.prefs['keep_room:!r3'] = '0';

  // 2. Data usage since November 1 (bytes, counts: sent / received).
  List<int> row(double sentMb, double recvMb, int sentN, int recvN) => [(sentMb * mb).round(), (recvMb * mb).round(), sentN, recvN];
  b.prefs['data_use'] = jsonEncode({
    'wifi': {
      'photo': row(84, 312, 61, 402),
      'video': row(150, 1630, 6, 48),
      'file': row(42, 260, 9, 31),
      'voice': row(3.2, 7.8, 40, 96),
      'messages': row(1.1, 3.4, 1820, 5230),
      'calls': row(96, 96, 0, 0),
    },
    'cell': {
      'photo': row(22, 118, 14, 190),
      'video': row(0, 210, 0, 9),
      'file': row(1.5, 12, 2, 6),
      'voice': row(0.8, 2.1, 12, 30),
      'messages': row(0.4, 1.2, 640, 1910),
      'calls': row(41, 41, 0, 0),
    },
  });
  b.prefs['data_use_since'] = '${DateTime(2026, 11, 1).millisecondsSinceEpoch}';

  // 3. A draft I typed on my PC in 박서준's chat.
  b.prefs['draft:!r2'] = name('토요일에 북한산 갈래? 아침 7시에 구파발역에서', 'Bukhansan on Saturday? 7 am at Gupabal station');
  b.prefs['draft_at:!r2'] = '${now.subtract(const Duration(minutes: 3)).millisecondsSinceEpoch}';
  b.prefs['draft_from:!r2'] = '1';

  // 4. 엄마's 3-second voice message (try 길게 누르기 > 알림음으로 저장), and
  // one sound already saved.
  b.files['st-tone'] = tone;
  b.rooms['!r3']?.add(
    Msg(
      id: 'st-tone',
      sender: '@mom:test',
      body: 'voice.wav',
      time: now.subtract(const Duration(minutes: 4)),
      mine: false,
      kind: 'audio',
      size: tone.length,
      voice: const VoiceInfo(Duration(seconds: 3), [120, 380, 700, 920, 640, 300, 520, 840, 610, 260, 180, 90]),
    ),
  );
  b.savedBlobs['tone_demo1'] = savedTone;
  b.prefs['my_sounds'] = jsonEncode([
    {'id': 'demo1', 'name': name('띵동 (내가 저장)', 'Ding (saved)'), 'ms': 1000, 'mime': 'audio/wav'},
  ]);

  // 5. A folder with groups and channels that have links (폴더 공유하기).
  String? roomOf(String code) => b.links.entries.where((e) => e.value.code == code).map((e) => e.key).firstOrNull;
  final hobby = [?roomOf('mangwon_friends'), ?roomOf('film_diary'), if (b.links.containsKey('!r1')) '!r1'];
  final folders = <dynamic>[];
  try {
    folders.addAll(jsonDecode(b.prefs['folders'] ?? '[]') as List);
  } catch (_) {}
  folders.add({
    'id': 'st-hobby',
    'name': name('동네·취미', 'Local & hobby'),
    'kinds': <String>[],
    'include': hobby,
    'exclude': <String>[],
    'skip': <String>[],
    'emoji': '🏡',
    'color': -1,
  });
  b.prefs['folders'] = jsonEncode(folders);

  // 6. A folder link from 김민지: three public chats to join in one go.
  b.outside['mangwon_bakery'] = LinkPeek(roomId: '!st-bakery', name: name('망원 빵지순례', 'Mangwon bakeries'), members: 412);
  b.outside['mangwon_market'] = LinkPeek(roomId: '!st-market', name: name('망원시장 소식', 'Mangwon market news'), members: 2318, channel: true);
  final link = FolderLink(
    name: name('망원동 생활', 'Mangwon life'),
    emoji: '🥐',
    items: const [
      FolderLinkItem(kind: 'public', code: 'mangwon_bakery'),
      FolderLinkItem(kind: 'public', code: 'mangwon_market', channel: true),
      FolderLinkItem(kind: 'public', code: 'seoul_runners', channel: true),
    ],
  ).url;
  b.rooms['!r0']?.add(
    Msg(
      id: 'st-folder',
      sender: '@mina:test',
      body: name('우리 동네 대화방 모아둔 폴더예요. 눌러서 한 번에 들어와요! $link', 'My neighbourhood folder, tap to join them all! $link'),
      time: now.subtract(const Duration(minutes: 3)),
      mine: false,
      kind: 'text',
    ),
  );
}

/// The second account's backend in the demo (회사 계정).
FakeBackend demoWorkAccount(bool ko) {
  final w = FakeBackend();
  final now = DateTime.now();
  String name(String k, String e) => ko ? k : e;
  void chat(String id, String title, String who, String text, int minsAgo, {bool group = false, int unread = 0}) {
    w.names[id] = title;
    if (group) w.groups.add(id);
    w.rooms[id] = [
      Msg(
        id: '$id-1',
        sender: who,
        body: text,
        time: now.subtract(Duration(minutes: minsAgo)),
        mine: false,
        kind: 'text',
      ),
    ];
    if (unread > 0) w.unreadCounts[id] = unread;
  }

  chat('!w1', name('마케팅 팀', 'Marketing'), '@hana:work', name('내일 회의 자료 올렸어요', 'Uploaded the slides for tomorrow'), 5, group: true, unread: 4);
  chat('!w2', name('이하나 팀장', 'Hana Lee'), '@hana:work', name('보고서 확인했어요. 수고했어요!', 'Read the report, great work!'), 32, unread: 1);
  chat('!w3', name('거래처 · 하늘상사', 'Client · Sky Co.'), '@sky:work', name('견적서 다시 보내 주실 수 있을까요?', 'Could you resend the quote?'), 75, group: true, unread: 2);
  chat('!w4', name('김도윤', 'Doyun Kim'), '@doyun:work', name('점심 같이 해요', 'Lunch together?'), 180);
  chat('!w5', name('회사 공지', 'Company news'), '@hr:work', name('12월 연차 신청은 금요일까지예요', 'Book December leave by Friday'), 400, group: true);
  // Hidden on that account: never in the preview.
  chat('!w6', name('이직 준비', 'Job hunt'), '@me:work', name('면접 일정', 'Interview dates'), 20);
  w.prefs['list_hidden:!w6'] = '1';
  return w;
}
