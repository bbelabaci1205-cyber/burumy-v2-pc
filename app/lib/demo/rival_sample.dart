// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): examples for the 4-messenger batch (WhatsApp,
// WeChat, Viber, Snapchat features, 2026-11-27).
// - 한지민's voice messages: 글로 보기 (+ an English one to 번역).
// - 토요일 모임: 14 unread messages for 안 읽은 대화 AI 요약.
// - 동창 모임: I just joined; a member sent me the earlier messages.
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show Archive, ArchiveFile, ZipEncoder;

import '../core/backend.dart';
import '../core/my_plans.dart';
import '../core/phone.dart';
import '../core/transcribe.dart';
import 'demo_backend.dart';

void addRivalSample(FakeBackend b, bool ko, {List<int>? photo}) {
  // 글로 보기: the web has no on-phone recognizer; fixed words stand in.
  final jimin = b.peers.entries.where((e) => e.value == '@jimin:test').firstOrNull?.key;
  if (jimin != null) {
    final voice = b.rooms[jimin]!.where((m) => m.voice != null).firstOrNull;
    if (voice != null) b.files[voice.id] = List.filled(7, 1);
    final at = b.rooms[jimin]!.last.time.add(const Duration(minutes: 1));
    b.rooms[jimin]!.add(
      Msg(
        id: 'rv-en',
        sender: '@jimin:test',
        body: 'voice',
        time: at,
        mine: false,
        kind: 'audio',
        voice: VoiceInfo(const Duration(seconds: 9), [for (var k = 0; k < 40; k++) 140 + (k * 197) % 860]),
      ),
    );
    b.files['rv-en'] = List.filled(9, 1);
  }
  // 안 읽은 대화 AI 요약.
  const g = '!rv-meet';
  b.names[g] = ko ? '토요일 모임' : 'Saturday meetup';
  b.groups.add(g);
  final t0 = DateTime(2026, 11, 23, 19, 0);
  final talk = ko
      ? [
          ('jisoo', '토요일에 다들 시간 돼?'),
          ('jihun', '나 됨!'),
          ('mina', '오후면 좋아'),
          ('jisoo', '그럼 2시 어때'),
          ('jihun', 'ㅇㅋ'),
          ('mina', '장소는 홍대?'),
          ('jisoo', '홍대입구역 9번 출구에서 보자'),
          ('jisoo', '회비는 2만 원이야. 금요일까지 나한테 보내 줘'),
          ('jihun', '나 30분 정도 늦을 것 같아 ㅠ'),
          ('mina', '괜찮아 먼저 들어가 있을게'),
          ('mina', '근데 비 온대'),
          ('jisoo', '비 오면 실내 볼링장으로 바꾸자'),
          ('jihun', '좋아 좋아'),
          ('mina', '👍'),
        ]
      : [
          ('jisoo', 'Is everyone free on Saturday?'),
          ('jihun', "I'm in!"),
          ('mina', 'Afternoon is good'),
          ('jisoo', 'How about 2 pm'),
          ('jihun', 'ok'),
          ('mina', 'Hongdae?'),
          ('jisoo', "Let's meet at Hongik Univ. exit 9"),
          ('jisoo', 'Fee is ₩20,000. Send it to me by Friday'),
          ('jihun', "I'll be about 30 min late"),
          ('mina', "No problem, we'll go in first"),
          ('mina', 'It might rain though'),
          ('jisoo', "If it rains let's go bowling indoors"),
          ('jihun', 'Sounds good'),
          ('mina', '👍'),
        ];
  b.rooms[g] = [
    for (final (i, (who, words)) in talk.indexed)
      Msg(
        id: 'rv-m$i',
        sender: '@$who:test',
        body: words,
        time: t0.add(Duration(minutes: i * 3)),
        mine: false,
        kind: 'text',
      ),
  ];
  b.unreadCounts[g] = talk.length;
  // 그룹 스트릭: 3 of 5 wrote every day this week.
  b.streaks[g] = (4, true);

  // 들어오기 전 대화.
  const a = '!rv-alumni';
  b.names[a] = ko ? '동창 모임' : 'School friends';
  b.groups.add(a);
  final t1 = DateTime(2026, 11, 20, 21, 0);
  final before = ko
      ? [('jisoo', '연말 모임 12월 14일 토요일로 정했어!'), ('jun', '장소는 강남역 3번 출구 앞 고깃집'), ('jisoo', '회비 3만 원, 당일에 걷을게'), ('mina', '은지도 불러야지? 내가 초대할게')]
      : [
          ('jisoo', 'Year-end party is Sat, Dec 14!'),
          ('jun', 'Place: the BBQ house at Gangnam exit 3'),
          ('jisoo', '₩30,000 each, paid on the day'),
          ('mina', "Let's add Eunji too, I'll invite her"),
        ];
  b.earlier[a] = [
    for (final (i, (who, words)) in before.indexed)
      Msg(
        id: 'rv-e$i',
        sender: '@$who:test',
        body: words,
        time: t1.add(Duration(minutes: i * 7)),
        mine: false,
        kind: 'text',
      ),
  ];
  // A photo sent with the earlier chat (the place, from the last party).
  if (photo != null) {
    final i = before.length;
    b.earlier[a]!.add(
      Msg(
        id: 'rv-e$i',
        sender: '@jun:test',
        body: '',
        caption: ko ? '작년에 간 곳 여기야' : 'This is where we went last year',
        time: t1.add(Duration(minutes: i * 7)),
        mine: false,
        kind: 'image',
      ),
    );
    b.earlierFiles['$a|$i'] = photo;
  }
  // 모임 일정: end time, +guests, my answer kept in 내 일정.
  final me = b.userId ?? '@me:test';
  final n = DateTime.now();
  final sat = DateTime(n.year, n.month, n.day + (DateTime.saturday - n.weekday + 7) % 7 + 7, 19);
  final plan = MeetupInfo(
    title: ko ? '연말 모임' : 'Year-end party',
    startsAt: sat,
    endsAt: sat.add(const Duration(hours: 3)),
    place: ko ? '강남역 3번 출구 고깃집' : 'BBQ house, Gangnam exit 3',
    yes: ['@jisoo:test', '@mina:test', me],
    maybe: const ['@jun:test'],
    guests: {'@mina:test': 1, me: 1},
  );
  // 대화별 저장 공간: copies this phone has kept (sizes in bytes).
  final day = n.millisecondsSinceEpoch;
  const mb = 1024 * 1024;
  b.prefs['media_kept'] = jsonEncode({
    'rv-k1': [a, 'group', day - 86400000 * 3, 84 * mb, 'video', ko ? '작년 모임 영상.mp4' : 'last_party.mp4'],
    'rv-k2': [a, 'group', day - 86400000 * 2, 12 * mb, 'video', ko ? '노래방.mp4' : 'karaoke.mp4'],
    'rv-k3': [a, 'group', day - 86400000, 3 * mb, 'photo', ko ? '단체 사진.jpg' : 'group_photo.jpg'],
    'rv-k4': [a, 'group', day, 900 * 1024, 'file', ko ? '회비 정리.pdf' : 'fees.pdf'],
    'rv-k5': ['!rv-meet', 'group', day, 6 * mb, 'photo', ko ? '보드게임.jpg' : 'board_games.jpg'],
  });
  b.prefs['my_plans'] = jsonEncode([
    MyPlan(roomId: a, id: 'rv-plan', title: plan.title, start: plan.startsAt, end: plan.endsAt, place: plan.place, guests: 1).toJson(),
  ]);
  b.files['rv-zip'] = ZipEncoder().encodeBytes(
    Archive()
      ..add(ArchiveFile.bytes(ko ? '회비 정리.txt' : 'fees.txt', utf8.encode(ko ? '회비 3만 원\n지수 ✓ 민아 ✓ 준 ✓\n남은 돈 4만 원은 다음 모임에' : 'Fee 30,000 won\nJisoo ✓ Mina ✓ Jun ✓')))
      ..add(ArchiveFile.bytes(ko ? '문서/장소 안내.pdf' : 'docs/place.pdf', samplePdf.codeUnits))
      ..add(ArchiveFile.bytes(ko ? '사진/작년 단체사진.png' : 'photos/last_year.png', photo ?? const [0])),
  );
  b.rooms[a] = [
    Msg(id: 'rv-plan', sender: '@jisoo:test', body: plan.title, time: t1.add(const Duration(hours: 20)), mine: false, kind: 'meetup', meetup: plan),
    // ZIP 미리보기: a zip with a note, the scanned PDF and a photo.
    Msg(
      id: 'rv-zip',
      sender: '@jun:test',
      body: ko ? '연말 모임 자료.zip' : 'party_files.zip',
      time: t1.add(const Duration(hours: 21)),
      mine: false,
      kind: 'file',
      size: b.files['rv-zip']?.length,
    ),
    Msg(
      id: 'rv-a0',
      sender: '@mina:test',
      body: ko ? '은지 왔다! 위에 지난 대화 보내 놨어' : 'Eunji is here! I sent you the earlier chat',
      time: t1.add(const Duration(days: 1)),
      mine: false,
      kind: 'text',
    ),
  ];

  // 그룹 전용 스토리: 지수's own story for 동창 모임 only.
  if (photo != null) {
    b.files['rv-member-story'] = photo;
    b.storyList.add(
      Story(
        id: 'rv-member-story',
        roomId: a,
        eventId: 'rv-member-story',
        sender: '@jisoo:test',
        mine: false,
        time: n.subtract(const Duration(hours: 1)),
        kind: 'image',
        caption: ko ? '모임 장소 미리 와 봤어요 🍖' : 'Checked out the place 🍖',
        until: n.add(const Duration(hours: 23)),
        group: true,
        member: true,
      ),
    );
  }

  // 문서 스캔 stand-in: the web can't open the phone's document camera, so
  // the demo sends a small one-page PDF as if a page was just scanned.
  Phone.debugScan = () async => Uint8List.fromList(samplePdf.codeUnits);
  Transcribe.debug = (Uint8List bytes, String mime, String lang) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (bytes.length == 9) return "Hey! My flight lands at 6. Can you pick me up at gate 3? I'll bring the gifts.";
    return ko
        ? '민수야, 오늘 회의는 3시로 미뤄졌어. 자료는 내가 들고 갈 테니까 너는 노트북만 챙겨 와. 끝나고 저녁 같이 먹자.'
        : "Minsu, today's meeting moved to 3. I'll bring the papers, just bring your laptop. Let's have dinner after.";
  };
}

/// A one-page PDF with a short note on it (what a scan would send).
const samplePdf = '''%PDF-1.4
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 595 842]/Contents 4 0 R/Resources<</Font<</F1 5 0 R>>>>>>endobj
4 0 obj<</Length 58>>stream
BT /F1 24 Tf 72 760 Td (Scanned page - Burumy demo) Tj ET
endstream endobj
5 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>endobj
trailer<</Root 1 0 R>>
%%EOF
''';
