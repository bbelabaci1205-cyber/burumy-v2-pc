// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Demo only (web preview): a friend writing in another language for 번역
// (the bar, the whole chat, the sheet), plus character emoji between words,
// a lone character emoji shown big and a character reaction. The web has
// no translation engine, so fixed translations stand in. Names made up.
import '../core/ai_styles.dart' show detectLanguage;
import '../core/backend.dart';
import '../core/translate.dart';
import 'demo_backend.dart';

const _enKo = <String, String>{
  'Hi! I just landed in Seoul 😊': '안녕! 방금 서울에 도착했어 😊',
  'Thanks! Are we still meeting tomorrow at 7?': '고마워! 우리 내일 7시에 만나는 거 맞지?',
  'I found a great Korean BBQ place near Hongdae.': '홍대 근처에 정말 좋은 고깃집을 찾았어.',
  'Let me know if that works for you!': '괜찮은지 알려 줘!',
};

const _koEn = <String, String>{
  '안녕! 방금 서울역에 도착했어 😊': 'Hi! I just arrived at Seoul Station 😊',
  '고마워! 우리 내일 7시에 만나는 거 맞지?': 'Thanks! We are meeting tomorrow at 7, right?',
  '홍대 근처에 정말 맛있는 고깃집을 찾았어.': 'I found a really good BBQ place near Hongdae.',
  '괜찮은지 알려 줘!': 'Let me know if that works!',
};

/// Look-only engine: the sentences above, a mark on anything else.
class DemoTranslate implements TranslateEngine {
  @override
  Future<String?> detect(String text) async {
    final g = detectLanguage(text);
    return g.isEmpty ? null : g;
  }

  @override
  Future<TrStatus> status(String from, String to) async => TrStatus.ready;

  @override
  Future<String> translate(String text, {required String from, required String to}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final hit = (to == 'ko' ? _enKo : _koEn)[text.trim()];
    return hit ?? '($to) $text';
  }
}

void addTranslateSample(FakeBackend b, bool ko) {
  const r = '!tr-friend';
  final who = ko ? '@emma:test' : '@sua:test';
  b.names[r] = ko ? 'Emma' : '이수아';
  b.peers[r] = who;
  b.unreadCounts[r] = 3;
  final t = DateTime(2026, 11, 26, 21, 0);
  final lines = (ko ? _enKo : _koEn).keys.toList();
  Msg them(String id, String body, int min) => Msg(
    id: id,
    sender: who,
    body: body,
    time: t.add(Duration(minutes: min)),
    mine: false,
    kind: 'text',
  );
  b.rooms[r] = [
    them('tr1', lines[0], 0),
    Msg(
      id: 'tr2',
      sender: '@me:test',
      body: ko ? '와 환영해요! :buru_e2_love: 오는 길 괜찮았어요? :rumi_e3_lol:' : 'Welcome! :buru_e2_love: How was the trip? :rumi_e3_lol:',
      time: t.add(const Duration(minutes: 1)),
      mine: true,
      kind: 'text',
      reactions: const [Reaction('buru_r2_love', 1, null)],
    ),
    them('tr3', lines[1], 2),
    them('tr4', lines[2], 3),
    them('tr5', lines[3], 3),
    them('tr6', ':mongi_e2_love:', 4),
  ];
}
