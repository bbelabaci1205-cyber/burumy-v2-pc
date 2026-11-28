// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo of the AI 편집기: the web preview has no on-phone model,
// so this stands in with fixed example answers (spelling list, a few
// translated example sentences, simple style changes). The real app uses
// the phone's own model (core/ai_local.dart).
import '../core/ai_local.dart';
import '../core/ai_styles.dart' show detectLanguage;
import 'audio_reader_sample.dart' show demoPostSummary;

class DemoAi implements AiEngine {
  DemoAi({this.delay = const Duration(milliseconds: 900)});
  final Duration delay;

  @override
  Future<AiStatus> status() async => AiStatus.ready;

  static const _fixes = <String, String>{
    '됬': '됐',
    '몇일': '며칠',
    '않되': '안 되',
    '안되요': '안 돼요',
    '어떻해': '어떡해',
    '왠만하면': '웬만하면',
    '금새': '금세',
    '할께': '할게',
    '갈께': '갈게',
    '줄께': '줄게',
    '되요': '돼요',
    '오랫만': '오랜만',
    '설겆이': '설거지',
    '희안': '희한',
    '역활': '역할',
    'im ': "I'm ",
    'dont ': "don't ",
    'cant ': "can't ",
    'should of': 'should have',
    'wear do': 'where do',
    ' teh ': ' the ',
    'i ': 'I ',
  };

  static const _translations = <String, Map<String, String>>{
    '이번 주말에 시간 되면 같이 저녁 먹을래? 7시쯤 어때?': {
      'en': 'Want to have dinner together this weekend if you are free? How about around 7?',
      'ja': '今週末、時間があれば一緒に夕食どう？7時ごろはどう？',
    },
    'Want to grab dinner this weekend if you are free? How about 7?': {'ko': '이번 주말에 시간 되면 저녁 같이 먹을래? 7시 어때?'},
  };

  @override
  Future<String> run({required String rules, required String text}) async {
    await Future<void>.delayed(delay);
    // 긴 글 AI 요약 / 읽기 모드 요약 (tips 554 + 475).
    if (rules.startsWith('You summarize one long chat post')) return demoPostSummary(text, rules.contains('Korean'));
    if (rules.startsWith('You summarize a web article')) return demoPostSummary(text, rules.contains('Korean'));
    // AI 친구 (우리식): the web has no phone AI; fixed friendly answers.
    if (rules.startsWith('You are the Burumy AI friend')) return demoFriendReply(text, rules.contains('Korean'));
    if (rules.startsWith('You summarize unread chat messages')) {
      return rules.contains('Korean')
          ? '• 토요일 오후 2시 홍대입구역 9번 출구에서 만나요\n• 회비는 2만 원, 총무 지수에게 금요일까지 보내기\n• 지훈은 30분 늦어요\n• 비 오면 실내 볼링장으로 바꿔요'
          : '• Meet Saturday 2 pm at Hongik Univ. exit 9\n• Fee is ₩20,000, send to Jisoo by Friday\n• Jihun will be 30 min late\n• If it rains, bowling indoors instead';
    }
    if (rules.contains('Fix spelling')) {
      var out = text;
      _fixes.forEach((a, b) => out = out.replaceAll(a, b));
      return out;
    }
    final tr = RegExp(r'Translate the message into ([A-Za-z ]+)\.').firstMatch(rules);
    if (tr != null) {
      final code = switch (tr.group(1)!) {
        'Korean' => 'ko',
        'Japanese' => 'ja',
        _ => 'en',
      };
      return _translations[text.trim()]?[code] ??
          (code == 'ko' || detectLanguage(text) == 'ko'
              ? '(미리보기: 진짜 앱에서는 휴대폰 AI가 번역해요)\n$text'
              : '(Preview: the real app translates with the phone AI)\n$text');
    }
    final emoji = rules.contains('Add a few fitting emoji');
    final style = RegExp(r'Rewrite it in this style: (.*?)(?: Add a few| If the style)').firstMatch(rules)?.group(1) ?? '';
    var out = _restyle(text, style);
    if (emoji) out = _emojify(out);
    return out;
  }

  static String _restyle(String text, String style) {
    final s = text.trim();
    final sentences = s.split(RegExp(r'(?<=[.?!])\s+'));
    if (style.startsWith('As short')) return sentences.first;
    if (style.startsWith('Polite and formal')) {
      return s.replaceAll('먹을래?', '드시겠어요?').replaceAll('어때?', '어떠세요?').replaceAll('같이', '함께').replaceAll('시간 되면', '시간이 괜찮으시면');
    }
    if (style.startsWith('Warm and friendly')) return '$s 너무 보고 싶다~';
    if (style.startsWith('Clear business')) return '안녕하세요. ${s.replaceAll('먹을래?', '하실 수 있을까요?').replaceAll('어때?', '괜찮으실까요?')}';
    if (style.startsWith('Old-fashioned')) return s.replaceAll('먹을래?', '드시겠소?').replaceAll('어때?', '어떠하오?').replaceAll('시간 되면', '틈이 나거든');
    if (style.startsWith('Calm and simple')) return '서두르지 않아도 돼요. ${sentences.first}';
    if (style.contains('해적')) return '으하하! 이 몸은 ${s.replaceAll('먹을래?', '먹겠느냐, 선원?').replaceAll('어때?', '어떠냐, 보물처럼 귀한 시간이다!')}';
    if (style.toLowerCase().contains('pirate')) return 'Arr, matey! $s Arr!';
    return '$s ✨';
  }

  static String _emojify(String s) => s.replaceAllMapped(RegExp(r'([?.!~])(\s|$)'), (m) => '${m[1]} 😊${m[2]}').trimRight();
}

/// AI 친구 in the look-only demo: a few fixed answers by topic.
String demoFriendReply(String text, bool ko) {
  final t = text.toLowerCase();
  bool has(List<String> w) => w.any(t.contains);
  if (has(['저녁', '메뉴', '먹', 'dinner', 'eat'])) {
    return ko
        ? '오늘은 따뜻한 국물 어때요? 쌀쌀한 날엔 순두부찌개나 칼국수가 잘 어울려요. 가볍게 먹고 싶다면 연어 덮밥도 좋아요 🍜'
        : 'How about something warm tonight? A spicy tofu stew or noodle soup fits a chilly day. For something light, a salmon rice bowl 🍜';
  }
  if (has(['생일', 'birthday'])) {
    return ko
        ? '"생일 축하해! 올해는 네가 웃는 날이 더 많았으면 좋겠어. 늘 고마워, 오늘 하루 마음껏 행복하길 🎂" 이렇게 보내 보는 건 어때요?'
        : '"Happy birthday! Hope this year brings you even more reasons to smile. Thanks for always being there 🎂" How about that?';
  }
  if (has(['주말', 'weekend'])) {
    return ko
        ? '날씨가 괜찮으면 가까운 공원 산책이나 전시 구경 어때요? 집에 있고 싶다면 미뤄 둔 영화 한 편과 맛있는 간식도 좋아요.'
        : 'If the weather is nice, a walk in a park or an exhibition. Staying in? A movie you have been saving and a good snack.';
  }
  if (has(['영어', '번역', 'korean', 'translate'])) {
    return ko ? '"Thank you for today!" 라고 하면 돼요. 조금 더 친근하게는 "Thanks a lot for today 😊" 도 좋아요.' : '"오늘 고마웠어!" — or a bit more polite: "오늘 정말 고마웠어요 😊"';
  }
  return ko
      ? '좋은 질문이에요! 웹 미리보기에서는 연습용 답만 보여 드려요. 진짜 앱에서는 폰 안의 AI가 직접 답하고, 대화는 폰 밖으로 나가지 않아요.'
      : 'Good question! The web preview shows practice answers only. In the app, the AI on your phone answers and nothing leaves it.';
}
