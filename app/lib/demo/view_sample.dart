// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for batches #10 보기·파일 and #11 영상 가볍게 (2026-11-27):
// the 독서 모임 group has a 3-page PDF (opens inside Burumy, 찾기 works),
// a text file, and Word / Excel files (다른 앱으로 열기 card), plus a
// 40-second reading video with a light copy (⚙ 자동 / 원본 / 가벼운 화질),
// which plays silently in its bubble (자동 재생) and can float (⧉).
import 'dart:convert';

import '../core/backend.dart';
import '../core/media_tags.dart';
import 'demo_backend.dart';

void addViewSample(FakeBackend b, bool ko, {required List<int> pdf, required List<int> clip, required List<int> light}) {
  const g = '!book-club';
  b.names[g] = ko ? '책 읽는 저녁' : 'Evening Book Club';
  b.groups.add(g);
  final t0 = DateTime.now().subtract(const Duration(minutes: 40));
  final list = utf8.encode(
    ko
        ? '12월에 읽을 책\n\n1. 작별하지 않는다 - 한강\n2. 불편한 편의점 - 김호연\n3. 아몬드 - 손원평\n\n다음 달 후보\n- 소년이 온다\n- 달러구트 꿈 백화점\n- 파친코\n\n기억에 남는 문장 하나씩 골라 오기!'
        : 'Books for December\n\n1. We Do Not Part - Han Kang\n2. The Second Chance Convenience Store - Kim Ho-yeon\n3. Almond - Sohn Won-pyung\n\nNext month ideas\n- Human Acts\n- The Dallergut Dream Department Store\n- Pachinko\n\nBring one sentence you loved!',
  );
  // Office files: Burumy doesn't draw these itself (other-app card).
  final fakeDocx = [0x50, 0x4B, 0x03, 0x04, ...List.filled(180 * 1024, 0)];
  final fakeXlsx = [0x50, 0x4B, 0x03, 0x04, ...List.filled(42 * 1024, 0)];
  b.files['bk-pdf'] = pdf;
  b.files['bk-txt'] = list;
  b.files['bk-docx'] = fakeDocx;
  b.files['bk-xlsx'] = fakeXlsx;
  // The sender's phone made a light copy (the demo's is 144 lines: the
  // sample clip itself is small).
  const pair = 'demo1';
  final vname = ko ? '낭독 영상.mp4' : 'reading.mp4';
  b.files['bk-vid-l'] = light;
  b.files['bk-vid'] = clip;
  b.rooms[g] = [
    Msg(id: 'bk-0', sender: '@seoyeon:test', body: ko ? '12월 모임 자료 올려요 📚 눌러 보면 부루미 안에서 바로 열려요' : 'December club notes 📚 Tap to open them right in Burumy', time: t0, mine: false, kind: 'text'),
    Msg(id: 'bk-pdf', sender: '@seoyeon:test', body: ko ? '12월 독서 모임 안내.pdf' : 'December book club.pdf', time: t0.add(const Duration(minutes: 1)), mine: false, kind: 'file', size: pdf.length),
    Msg(id: 'bk-txt', sender: '@minjun:test', body: ko ? '읽을 책 목록.txt' : 'reading_list.txt', time: t0.add(const Duration(minutes: 3)), mine: false, kind: 'file', size: list.length),
    Msg(id: 'bk-docx', sender: '@minjun:test', body: ko ? '발표 순서.docx' : 'talk_order.docx', time: t0.add(const Duration(minutes: 4)), mine: false, kind: 'file', size: fakeDocx.length),
    Msg(id: 'bk-xlsx', sender: '@seoyeon:test', body: ko ? '회비 정리.xlsx' : 'club_fees.xlsx', time: t0.add(const Duration(minutes: 5)), mine: false, kind: 'file', size: fakeXlsx.length),
    Msg(
      id: 'bk-vid-l',
      sender: '@haeun:test',
      body: const MediaTags(lightOf: pair, lightHeight: 144).apply(vname),
      time: t0.add(const Duration(minutes: 6)),
      mine: false,
      kind: 'video',
      size: light.length,
    ),
    Msg(
      id: 'bk-vid',
      sender: '@haeun:test',
      body: const MediaTags(pair: pair).apply(vname),
      caption: ko ? '지난 모임 낭독이에요. 톱니바퀴로 가벼운 화질을 고를 수 있어요' : 'Reading from last time. Pick the light version with the gear',
      time: t0.add(const Duration(minutes: 6, seconds: 5)),
      mine: false,
      kind: 'video',
      size: clip.length,
    ),
    Msg(
      id: 'bk-1',
      sender: '@haeun:test',
      body: ko ? 'PDF 보다가 아래로 내려 두면 대화하면서 다시 열 수 있어요!' : 'Tuck the PDF away and reopen it while you chat!',
      time: t0.add(const Duration(minutes: 7)),
      mine: false,
      kind: 'text',
    ),
  ];
  b.unreadCounts[g] = 6;
  // Near the top of the list (second, under the first chat).
  final rest = Map.of(b.rooms);
  final first = rest.keys.first;
  final top = rest.remove(first)!;
  final mine = rest.remove(g)!;
  b.rooms
    ..clear()
    ..[first] = top
    ..[g] = mine
    ..addAll(rest);
}
