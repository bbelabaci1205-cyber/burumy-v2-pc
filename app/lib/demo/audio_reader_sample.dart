// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview) for Telegram tip batches #25 + #26:
// - a friend sharing songs (play list player, speed, mini bar) and a long
//   radio episode (carries on where you stopped);
// - a channel with a long post (AI 요약) and an article link (읽기 모드).
// The songs are short tunes made right here (no music files are shipped);
// the article is a fixed example because the browser may not fetch other
// sites. Names and texts are made up.
import 'dart:math' as math;
import 'dart:typed_data';

import '../core/backend.dart';
import '../core/reader.dart';
import '../core/transcribe.dart';
import '../design/tokens.dart';
import '../ui/common.dart' show Avatar;
import 'demo_backend.dart';

/// A little tune as a WAV file: [notes] are semitones from A4 (null = rest).
Uint8List demoTune(List<int?> notes, {double beat = 0.32, int rate = 16000, double seconds = 0, double wobble = 0}) {
  final total = seconds > 0 ? (seconds * rate).round() : (notes.length * beat * rate).round();
  final data = ByteData(44 + total * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + total * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, total * 2, Endian.little);
  final step = (beat * rate).round();
  for (var i = 0; i < total; i++) {
    final n = notes[(i ~/ step) % notes.length];
    final t = (i % step) / rate;
    var v = 0.0;
    if (n != null) {
      final f = 440 * math.pow(2, n / 12) * (1 + wobble * math.sin(i / rate * 5));
      final env = math.min(1.0, t * 40) * math.exp(-t * 3.2);
      v = env * (0.6 * math.sin(2 * math.pi * f * i / rate) + 0.25 * math.sin(4 * math.pi * f * i / rate) + 0.1 * math.sin(6 * math.pi * f * i / rate));
    }
    data.setInt16(44 + i * 2, (v * 9000).round().clamp(-32768, 32767), Endian.little);
  }
  return data.buffer.asUint8List();
}

const _postKo =
    '📢 12월 도시 산책 행사 안내\n\n'
    '올해 마지막 도시 산책은 12월 14일 토요일 오전 10시에 시작해요. 모이는 곳은 서울숲 2번 출입구 앞 광장이고, '
    '성수동 골목과 뚝섬 한강공원을 지나 약 7km를 함께 걸어요. 중간에 성수동 카페 거리에서 30분 쉬는 시간이 있어요.\n\n'
    '참가비는 1인 5,000원이고, 따뜻한 차와 간식, 기념 손수건을 드려요. 신청은 12월 10일 수요일 밤 11시까지 채널 고정 글의 '
    '신청서로 받아요. 선착순 80명이고, 자리가 차면 대기 명단으로 받아요.\n\n'
    '날씨가 추울 수 있으니 장갑과 목도리를 꼭 챙겨 주세요. 비나 눈이 오면 행사는 12월 21일 토요일로 미뤄지고, 전날 저녁 7시에 '
    '이 채널로 알려 드려요. 반려견과 함께 오셔도 되지만 목줄은 꼭 해 주세요. 유모차도 다닐 수 있는 길이에요.\n\n'
    '행사가 끝나면 뚝섬 유원지역 근처에서 자유롭게 점심을 드시면 돼요. 사진 담당 봉사자 두 분도 모집 중이니 관심 있는 분은 '
    '댓글로 알려 주세요. 올해도 함께 걸어 주셔서 고마워요!';

const _postEn =
    '📢 December city walk\n\n'
    'Our last city walk of the year starts on Saturday 14 December at 10 am. We meet in the square in front of Seoul Forest gate 2 '
    'and walk about 7 km together through the Seongsu alleys and Ttukseom Hangang Park, with a 30-minute break on the Seongsu cafe street.\n\n'
    'It costs 5,000 won per person, and you get warm tea, snacks and a walk handkerchief. Sign up with the form in the pinned post '
    'by Wednesday 10 December, 11 pm. First 80 people; after that you go on a waiting list.\n\n'
    'It may be cold, so bring gloves and a scarf. If it rains or snows, the walk moves to Saturday 21 December and we will post it '
    'here the evening before at 7 pm. Dogs are welcome on a lead, and the path is fine for prams.\n\n'
    'After the walk, have lunch wherever you like near Ttukseom Resort station. We are also looking for two volunteer photographers: '
    'tell us in the comments. Thank you for walking with us this year!';

/// The demo's fixed answers for the AI summary (core/ai_local.dart rules).
String demoPostSummary(String text, bool ko) {
  if (text.contains('골목길 서점') || text.contains('alley bookshops')) {
    return ko
        ? '• 성수동 골목에 작은 독립 서점 5곳이 1년 사이 새로 열렸어요\n• 서점마다 동네 작가 책, 밤 독서 모임 같은 저마다의 색이 있어요\n• 주말 오후 2~5시가 가장 붐비고, 평일 저녁이 한가해요'
        : '• Five small independent bookshops opened in Seongsu alleys within a year\n• Each has its own style: local writers, late-night reading clubs\n• Busiest on weekend afternoons 2–5 pm; quiet on weekday evenings';
  }
  return ko
      ? '• 12월 14일(토) 오전 10시, 서울숲 2번 출입구에서 출발해 약 7km 걸어요\n• 참가비 5,000원, 12월 10일(수) 밤 11시까지 신청 (선착순 80명)\n• 비·눈이 오면 12월 21일(토)로 미뤄지고 전날 저녁 7시에 알려요\n• 반려견은 목줄 필수, 사진 봉사자 2명 모집 중'
      : '• Sat 14 Dec, 10 am from Seoul Forest gate 2, about 7 km\n• 5,000 won; sign up by Wed 10 Dec, 11 pm (first 80)\n• Rain or snow: moves to Sat 21 Dec, announced 7 pm the day before\n• Dogs on a lead; two volunteer photographers wanted';
}

Article demoArticle(String url, bool ko) => Article(
  url: url,
  site: ko ? '도시 산책 매거진' : 'City Walk Magazine',
  title: ko ? '골목길 서점이 다시 늘어나는 이유' : 'Why alley bookshops are coming back',
  byline: ko ? '글 한소리 기자' : 'By Sori Han',
  blocks: ko
      ? const [
          ArticleBlock('p', '성수동 골목에 작은 독립 서점 5곳이 지난 1년 사이 새로 문을 열었어요. 큰 서점이 문을 닫는 동안, 동네 사람들이 오래 머무를 수 있는 작은 서점은 오히려 늘고 있어요.'),
          ArticleBlock('img', '성수동 골목의 한 독립 서점', src: 'asset:assets/demo/photo.png'),
          ArticleBlock('h', '서점마다 다른 색'),
          ArticleBlock('p', '어떤 곳은 동네 작가의 책만 모아 두고, 어떤 곳은 밤 9시부터 자정까지 조용히 책만 읽는 모임을 열어요. 주인이 직접 쓴 짧은 추천 글이 책마다 꽂혀 있는 곳도 있어요.'),
          ArticleBlock('quote', '“책을 사러 오기보다, 책 옆에 앉아 있으려고 오는 분이 많아요.”'),
          ArticleBlock('h', '언제 가면 좋을까'),
          ArticleBlock('li', '주말 오후 2시~5시: 가장 붐벼요'),
          ArticleBlock('li', '평일 저녁 7시 이후: 한가하고 조용해요'),
          ArticleBlock('li', '매달 마지막 금요일: 작가와의 대화가 열려요'),
          ArticleBlock('p', '서점 주인들은 “동네 사람들이 서로 얼굴을 아는 곳으로 남고 싶다”고 말해요. 다음 달에는 다섯 서점이 함께 만든 산책 지도도 나올 예정이에요.'),
        ]
      : const [
          ArticleBlock(
            'p',
            'Five small independent bookshops opened in the Seongsu alleys in the past year. While big stores close, small shops where neighbours can stay a while keep growing.',
          ),
          ArticleBlock('img', 'An independent bookshop in a Seongsu alley', src: 'asset:assets/demo/photo.png'),
          ArticleBlock('h', 'Each shop has its own style'),
          ArticleBlock(
            'p',
            'One stocks only books by local writers; another runs a silent reading club from 9 pm to midnight. In one shop, the owner tucks a short handwritten note into every book.',
          ),
          ArticleBlock('quote', '“Many people come to sit next to books rather than to buy them.”'),
          ArticleBlock('h', 'When to go'),
          ArticleBlock('li', 'Weekend afternoons 2–5 pm: busiest'),
          ArticleBlock('li', 'Weekday evenings after 7 pm: quiet'),
          ArticleBlock('li', 'Last Friday of each month: talks with writers'),
          ArticleBlock(
            'p',
            'The owners say they want to stay places where neighbours know each other’s faces. Next month the five shops will publish a walking map together.',
          ),
        ],
);

void addAudioReaderSample(FakeBackend b, bool ko, {List<int>? round}) {
  final now = DateTime(2026, 11, 27, 19, 30);

  // 1. A friend sharing songs and a long radio episode.
  const m = '!music-friend';
  final who = '@chaewon:test';
  b.names[m] = ko ? '채원' : 'Chaewon';
  b.peers[m] = who;
  b.unreadCounts[m] = 4;
  Msg song(String id, String name, int min, int size) => Msg(
    id: id,
    sender: who,
    body: name,
    time: now.subtract(Duration(minutes: min)),
    mine: false,
    kind: 'file',
    size: size,
  );
  b.rooms[m] = [
    Msg(
      id: 'mu0',
      sender: who,
      body: ko ? '요즘 듣는 곡들 보내 줄게 🎧 차례대로 들어 봐' : 'Sending the songs I listen to these days 🎧 play them in order',
      time: now.subtract(const Duration(minutes: 12)),
      mine: false,
      kind: 'text',
    ),
    song('mu1', 'Lumen - Morning Walk.mp3', 11, 3920000),
    song('mu2', 'Lumen - City Lights.mp3', 11, 4410000),
    song('mu3', 'Paper Boats - Han River.mp3', 10, 3650000),
    Msg(
      id: 'mu4',
      sender: who,
      body: ko ? '이건 라디오 다시 듣기야. 길어서 끊어 들어도 들은 데부터 이어져!' : 'And a radio replay. It is long, but it carries on where you stopped!',
      time: now.subtract(const Duration(minutes: 9)),
      mine: false,
      kind: 'text',
    ),
    song('mu5', ko ? '부루미 라디오 - 12화 겨울 산책.mp3' : 'Burumy Radio - Ep 12 Winter walk.mp3', 9, 18700000),
  ];
  // 동그란 영상 메시지 with 글로 보기 (tip 361).
  if (round != null) {
    b.rooms[m]!.add(Msg(id: 'mu6', sender: who, body: 'videonote.mp4', time: now.subtract(const Duration(minutes: 8)), mine: false, kind: 'video'));
    b.files['mu6'] = round;
    final before = Transcribe.debug;
    Transcribe.debug = (bytes, mime, lang) async {
      if (!mime.startsWith('video/')) return before == null ? null : before(bytes, mime, lang);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      return ko
          ? '지금 한강 걷는 중이야! 라디오 듣다가 생각나서 찍었어. 다음에 같이 걷자 😊'
          : "Walking by the Han River now! Thought of you while listening to the radio. Let's walk together next time 😊";
    };
  }
  // C major-ish little tunes (semitones from A4).
  b.files['mu1'] = demoTune([3, 7, 10, 7, 12, 10, 7, 3, 5, 8, 12, 8, 10, 7, 3, null], seconds: 24);
  b.files['mu2'] = demoTune([-2, 2, 5, 9, 7, 5, 2, null, 0, 3, 7, 10, 9, 7, 3, null], beat: 0.26, seconds: 22);
  b.files['mu3'] = demoTune([0, 4, 7, 4, 9, 7, 4, 0, -1, 2, 7, 2, 5, 4, 0, null], beat: 0.4, seconds: 26);
  b.files['mu5'] = demoTune([0, null, 7, null, 5, 4, 2, null, 0, null, 4, null, 2, 0, -3, null], beat: 0.45, seconds: 75, rate: 8000);

  // 2. A channel with a long post (요약) and an article link (읽기 모드).
  const c = '!walk-channel';
  b.names[c] = ko ? '도시 산책 매거진' : 'City Walk Magazine';
  b.groups.add(c);
  b.channels.add(c);
  b.peers[c] = '@citywalk:test';
  b.unreadCounts[c] = 2;
  Avatar.tint[b.names[c]!] = Palette.tileTeal;
  const url = 'https://citywalk.example/stories/alley-bookshops';
  b.rooms[c] = [
    Msg(id: 'cw1', sender: '@citywalk:test', body: ko ? _postKo : _postEn, time: now.subtract(const Duration(hours: 3)), mine: false, kind: 'text'),
    Msg(
      id: 'cw2',
      sender: '@citywalk:test',
      body: ko ? '이번 주 이야기: 골목길 서점이 다시 늘어나는 이유 📚\n$url' : 'This week: why alley bookshops are coming back 📚\n$url',
      time: now.subtract(const Duration(hours: 1)),
      mine: false,
      kind: 'text',
      preview: LinkCard(
        url: url,
        title: ko ? '골목길 서점이 다시 늘어나는 이유' : 'Why alley bookshops are coming back',
        description: ko ? '성수동 골목에 작은 독립 서점 5곳이 새로 문을 열었어요.' : 'Five small bookshops opened in the Seongsu alleys.',
        site: ko ? '도시 산책 매거진' : 'City Walk Magazine',
      ),
    ),
  ];

  // The browser can't fetch other sites: the example article stands in.
  Reader.debug = (u) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return demoArticle(u, ko);
  };
}
