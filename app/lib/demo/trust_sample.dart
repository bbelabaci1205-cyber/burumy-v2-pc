// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사칭 막기 in the look-only demo: a singer with the official badge, the
// news channel's badge, someone new pretending to be the singer, and an
// account the operator marked '가짜'. Names are made up.
import '../core/backend.dart';
import '../core/trust.dart';
import 'demo_backend.dart';

void addTrustSample(FakeBackend b, bool ko, List<int> photo) {
  final star = ko ? '하늘별' : 'Haneul Star';
  b.trust = TrustList(
    version: 1,
    badges: [
      Badge(user: '@haneulbyeol:test', name: star),
      Badge(user: '@burumy:test', name: ko ? '부루미 소식' : 'Burumy News', kind: 'channel'),
    ],
    flags: const {'@prize_event:test': 'fake'},
  );
  final now = DateTime(2026, 11, 23, 20, 10);
  // Someone new with the singer's name and a look-alike ID.
  const imp = '!imp';
  b.names[imp] = star;
  b.peers[imp] = '@haneul_0fficial:test';
  b.strangerRooms.add(imp);
  b.unreadCounts[imp] = 3;
  b.trustAbouts['@haneul_0fficial:test'] = const TrustAbout(age: 'week', renamed: true, renamedDays: 2, photoDays: 1);
  b.rooms[imp] = [
    Msg(
      id: 'imp1',
      sender: '@haneul_0fficial:test',
      body: ko ? '안녕하세요, 하늘별이에요! 팬미팅 초대에 당첨되셨어요 🎉' : "Hi, it's Haneul Star! You won a fan-meeting invite 🎉",
      time: now.subtract(const Duration(minutes: 3)),
      mine: false,
      kind: 'text',
    ),
    Msg(id: 'imp2', sender: '@haneul_0fficial:test', body: 'ticket.png', time: now.subtract(const Duration(minutes: 2)), mine: false, kind: 'image'),
    Msg(
      id: 'imp3',
      sender: '@haneul_0fficial:test',
      body: ko ? '오늘 안에 참가비 5만 원을 보내 주셔야 자리가 확정돼요' : 'Send the 50,000 won fee today to keep your seat',
      time: now.subtract(const Duration(minutes: 1)),
      mine: false,
      kind: 'text',
    ),
  ];
  b.files['imp2'] = photo;
  final impMsgs = b.rooms.remove(imp)!;
  // An account the operator already marked '가짜'.
  const fake = '!fake';
  b.names[fake] = ko ? '이벤트 당첨 안내' : 'Prize notice';
  b.peers[fake] = '@prize_event:test';
  b.strangerRooms.add(fake);
  b.unreadCounts[fake] = 1;
  b.trustAbouts['@prize_event:test'] = const TrustAbout(age: 'month', photoDays: 12);
  final fakeMsgs = [
    Msg(
      id: 'fk1',
      sender: '@prize_event:test',
      body: ko ? '축하해요! 경품 수령을 위해 인증번호를 알려 주세요' : 'Congrats! Tell us the code we sent to claim your prize',
      time: now.subtract(const Duration(minutes: 40)),
      mine: false,
      kind: 'text',
    ),
  ];
  // 메시지 요청 (v1): someone new asking about a used camera.
  const req = '!req_camera';
  b.names[req] = ko ? '박준호' : 'Junho Park';
  b.peers[req] = '@junho_cam:test';
  b.strangerRooms.add(req);
  b.unreadCounts[req] = 1;
  b.prefs['dm_request:$req'] = '@junho_cam:test';
  final reqMsgs = [
    Msg(
      id: 'rq1',
      sender: '@junho_cam:test',
      body: ko ? '안녕하세요, 중고 카메라 글 보고 연락드려요. 아직 파시나요?' : 'Hi, I saw your used camera post. Is it still for sale?',
      time: now.subtract(const Duration(minutes: 20)),
      mine: false,
      kind: 'text',
    ),
  ];
  // Newest first in the demo list (the real engine sorts by time).
  final rest = Map.of(b.rooms);
  final keys = rest.keys.toList();
  b.rooms
    ..clear()
    ..[imp] = impMsgs;
  for (var i = 0; i < keys.length; i++) {
    if (i == 2) b.rooms[fake] = fakeMsgs;
    if (i == 3) b.rooms[req] = reqMsgs;
    b.rooms[keys[i]] = rest[keys[i]]!;
  }
}
