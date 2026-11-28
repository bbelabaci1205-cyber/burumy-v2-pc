// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이모지 찾기 (Telegram tips 366, 378, 221; Eric 2026-11-27 "다 해 줘"):
// words people type -> emoji, in Korean and English. Our own word list
// (written for Burumy, not copied from any keyword set). Everything runs
// on the phone: nothing typed here leaves it.
import 'package:flutter/widgets.dart' show StringCharacters;

/// Emoji -> the words that find it (space separated, Korean first).
const emojiWords = <String, String>{
  // 웃음·기쁨
  '😀': '웃음 웃는 미소 기쁨 행복 smile happy grin',
  '😃': '웃음 신남 기쁨 smile happy',
  '😄': '웃음 활짝 기쁨 smile laugh',
  '😁': '헤헤 웃음 이빨 grin',
  '😆': '깔깔 웃음 ㅋㅋ laugh lol',
  '😅': '머쓱 식은땀 헤헤 sweat awkward',
  '😂': '웃겨 ㅋㅋ ㅋㅋㅋ 빵터짐 눈물 웃음 lol laugh joy funny',
  '🤣': '데굴데굴 ㅋㅋ 웃겨 빵터짐 rofl lol',
  '🥲': '웃픈 눈물 미소 bittersweet',
  '😊': '미소 수줍 좋아 smile blush',
  '😇': '천사 착한 순수 angel innocent',
  '🙂': '미소 괜찮 smile',
  '🙃': '거꾸로 장난 silly',
  '😉': '윙크 장난 wink',
  '😌': '편안 안심 relieved calm',
  '😍': '반함 하트눈 사랑 좋아 love heart eyes',
  '🥰': '사랑 행복 하트 좋아 love',
  '😘': '뽀뽀 키스 사랑 kiss',
  '😋': '맛있 냠냠 yummy tasty',
  '😛': '메롱 혀 tongue',
  '😜': '장난 메롱 윙크 crazy',
  '🤪': '미친 정신없 장난 crazy',
  '🤨': '의심 흠 수상 suspicious',
  '🧐': '관찰 탐정 자세히 monocle',
  '🤓': '공부 범생 nerd',
  '😎': '멋짐 쿨 선글라스 cool',
  '🤩': '감동 반짝 스타 wow star',
  '🥳': '파티 축하 생일 party celebrate',
  // 슬픔·걱정
  '😏': '능글 흐흐 smirk',
  '😒': '시큰둥 별로 unamused',
  '😞': '실망 우울 disappointed',
  '😔': '시무룩 우울 sad',
  '😟': '걱정 근심 worried',
  '😕': '혼란 애매 confused',
  '🙁': '슬픔 시무룩 sad',
  '😣': '참는 괴로 persevere',
  '😖': '괴로 짜증 confounded',
  '😫': '지침 피곤 tired',
  '😩': '지침 힘듦 weary',
  '🥺': '부탁 제발 글썽 please puppy',
  '😢': '슬퍼 슬픔 눈물 울어 sad cry tear',
  '😭': '엉엉 오열 울어 눈물 슬퍼 sob cry',
  '😤': '씩씩 뿌듯 화남 huff',
  '😠': '화나 화남 짜증 angry mad',
  '😡': '분노 화남 빡침 angry rage',
  '🤬': '욕 분노 curse',
  '🤯': '멘붕 충격 머리터짐 mind blown',
  '😳': '당황 부끄 놀람 flushed',
  '🥵': '더워 더움 hot',
  '🥶': '추워 추움 cold',
  '😱': '비명 공포 충격 scream shock',
  '😨': '무서 공포 fear',
  '😰': '불안 식은땀 anxious',
  '😥': '휴 안도 실망 relieved sad',
  '😓': '땀 진땀 sweat',
  '🫣': '부끄 엿보기 peek',
  '🤗': '안아 포옹 허그 hug',
  '🫡': '경례 알겠 충성 salute',
  '🤔': '고민 생각 음 글쎄 think hmm',
  '🤭': '쿡쿡 입가림 giggle',
  '🤫': '쉿 비밀 조용 secret shh',
  '🤥': '거짓말 lie',
  '😶': '할말없 무표정 speechless',
  '😐': '무표정 그냥 neutral',
  '😑': '무표정 실망 expressionless',
  '😬': '어색 이크 grimace awkward',
  '🙄': '눈굴림 어이없 eye roll',
  '😯': '헉 놀람 hushed',
  '😮': '놀람 와 헐 대박 wow surprised',
  '😲': '깜짝 놀람 astonished',
  '🥱': '하품 졸려 지루 yawn bored',
  '😴': '잠 졸려 잘자 쿨쿨 sleep tired',
  '🤤': '침 먹고싶 drool',
  '😪': '졸림 잠 sleepy',
  '😵': '어지러 멘붕 dizzy',
  '😵‍💫': '어지러 빙글 dizzy',
  '🤐': '입다물 비밀 zip',
  '🥴': '취함 어질 woozy drunk',
  '🤢': '토할 역겨 nausea',
  '🤮': '토 구역질 vomit',
  '🤧': '재채기 감기 sneeze cold',
  '😷': '마스크 아픔 감기 sick mask',
  '🤒': '열 아픔 감기 sick fever',
  '🤕': '다침 부상 hurt',
  '🤑': '돈 부자 money rich',
  '🤠': '카우보이 cowboy',
  '😈': '악마 장난 devil',
  '👻': '유령 귀신 ghost',
  '💀': '해골 죽겠 skull dead',
  '👽': '외계인 alien',
  '🤖': '로봇 robot',
  '💩': '똥 poop',
  '🤡': '광대 clown',
  // 손·사람
  '👋': '안녕 인사 하이 바이 손흔들 hi hello bye wave',
  '🤚': '손 멈춰 hand',
  '✋': '손 멈춰 하이파이브 stop hand',
  '🖐️': '손 다섯 hand',
  '👌': '오케이 좋아 ok okay',
  '🤌': '이탈리아 손 pinch',
  '✌️': '브이 평화 승리 peace victory',
  '🤞': '행운 기도 luck fingers crossed',
  '🫰': '손하트 하트 finger heart',
  '🤟': '사랑해 love you',
  '🤘': '락 rock',
  '🤙': '전화 연락 call me',
  '👈': '왼쪽 left',
  '👉': '오른쪽 right',
  '👆': '위 up',
  '👇': '아래 down',
  '☝️': '하나 잠깐 one',
  '🫵': '너 you',
  '👍': '좋아 최고 굿 따봉 좋아요 like good yes thumbs up',
  '👎': '별로 싫어 나빠 dislike bad thumbs down',
  '✊': '주먹 화이팅 fist',
  '👊': '주먹 펀치 punch',
  '👏': '박수 짝짝 축하 잘했 clap congrats',
  '🙌': '만세 야호 축하 hooray',
  '🫶': '하트손 사랑 heart hands love',
  '🤝': '악수 협력 약속 deal handshake',
  '🙏': '감사 고마워 부탁 기도 제발 thanks please pray',
  '✍️': '쓰기 메모 write',
  '💪': '화이팅 힘 근육 힘내 파이팅 strong fighting',
  '👀': '눈 보기 구경 주목 eyes look',
  '🧠': '뇌 생각 brain',
  '👶': '아기 baby',
  '🙇': '죄송 사과 꾸벅 미안 sorry bow',
  '🤦': '아이고 한심 facepalm',
  '🤷': '몰라 글쎄 shrug',
  '🙋': '저요 손들 질문 raise hand',
  '🙆': '좋아 오케이 ok',
  '🙅': '안돼 금지 no',
  '💃': '춤 댄스 dance',
  '🕺': '춤 댄스 dance',
  '🏃': '달리기 뛰기 서둘러 run',
  '🚶': '걷기 산책 walk',
  '🧘': '요가 명상 yoga',
  // 하트·기호
  '❤️': '하트 사랑 좋아 빨강 love heart',
  '🧡': '하트 주황 heart',
  '💛': '하트 노랑 heart',
  '💚': '하트 초록 heart',
  '💙': '하트 파랑 heart',
  '💜': '하트 보라 heart',
  '🖤': '하트 검정 heart',
  '🤍': '하트 하양 heart',
  '💔': '실연 상처 깨진 이별 broken heart',
  '❤️‍🔥': '불타는 사랑 열정 heart fire',
  '💕': '하트 사랑 hearts love',
  '💖': '반짝 하트 sparkle heart',
  '💯': '백점 완벽 100 perfect',
  '💢': '화남 짜증 anger',
  '💥': '쾅 충돌 boom',
  '💫': '어지러 별 dizzy',
  '💦': '땀 물 sweat',
  '💨': '휙 바람 dash',
  '💤': '잠 쿨쿨 졸려 zzz sleep',
  '💬': '말 대화 채팅 speech chat',
  '💭': '생각 thought',
  '✅': '완료 체크 확인 done check',
  '❌': '안돼 틀림 취소 no wrong',
  '❗️': '느낌표 중요 important',
  '❓': '물음표 질문 question',
  '⚠️': '주의 경고 warning',
  '🔥': '불 대박 핫 최고 fire hot lit',
  '✨': '반짝 새것 sparkle new',
  '⭐️': '별 즐겨찾기 star',
  '🌟': '별 반짝 star',
  '🎉': '축하 파티 생일 빵빠레 congrats party',
  '🎊': '축하 파티 confetti',
  '🎂': '생일 케이크 birthday cake',
  '🎁': '선물 생일 gift present',
  '🎈': '풍선 생일 balloon',
  '🏆': '우승 트로피 1등 winner trophy',
  '🥇': '1등 금메달 first gold',
  // 동물·자연
  '🐶': '강아지 개 멍멍 puppy dog',
  '🐱': '고양이 냥 야옹 cat',
  '🐭': '쥐 mouse',
  '🐰': '토끼 rabbit bunny',
  '🦊': '여우 fox',
  '🐻': '곰 bear',
  '🐼': '판다 panda',
  '🐨': '코알라 koala',
  '🐯': '호랑이 tiger',
  '🦁': '사자 lion',
  '🐷': '돼지 pig',
  '🐸': '개구리 frog',
  '🐵': '원숭이 monkey',
  '🙈': '못봄 부끄 원숭이 see no evil',
  '🐔': '닭 chicken',
  '🐧': '펭귄 penguin',
  '🐥': '병아리 chick',
  '🦄': '유니콘 unicorn',
  '🐝': '벌 bee',
  '🦋': '나비 butterfly',
  '🐢': '거북이 느림 turtle slow',
  '🐳': '고래 whale',
  '🐬': '돌고래 dolphin',
  '🐙': '문어 octopus',
  '🌸': '벚꽃 꽃 봄 blossom flower spring',
  '🌹': '장미 꽃 rose',
  '🌻': '해바라기 꽃 sunflower',
  '🌷': '튤립 꽃 tulip',
  '💐': '꽃다발 축하 bouquet',
  '🍀': '행운 클로버 luck clover',
  '🌈': '무지개 rainbow',
  '☀️': '해 맑음 날씨 sun sunny',
  '🌙': '달 밤 잘자 moon night',
  '☁️': '구름 흐림 cloud',
  '🌧️': '비 rain',
  '☔️': '우산 비 umbrella rain',
  '❄️': '눈 겨울 추워 snow winter',
  '⛄️': '눈사람 겨울 snowman',
  '🌊': '파도 바다 wave sea',
  '⚡️': '번개 전기 빠름 lightning',
  // 음식
  '🍎': '사과 apple',
  '🍓': '딸기 strawberry',
  '🍉': '수박 여름 watermelon',
  '🍑': '복숭아 peach',
  '🍌': '바나나 banana',
  '🍕': '피자 pizza',
  '🍔': '햄버거 버거 hamburger burger',
  '🍟': '감자튀김 fries',
  '🌭': '핫도그 hotdog',
  '🍗': '치킨 닭다리 chicken',
  '🍜': '라면 국수 noodle ramen',
  '🍚': '밥 rice',
  '🍙': '주먹밥 rice ball',
  '🍣': '초밥 스시 sushi',
  '🍱': '도시락 bento',
  '🍰': '케이크 디저트 cake',
  '🍩': '도넛 donut',
  '🍪': '쿠키 cookie',
  '🍫': '초콜릿 chocolate',
  '🍦': '아이스크림 ice cream',
  '☕️': '커피 카페 coffee',
  '🍵': '차 녹차 tea',
  '🧋': '버블티 밀크티 bubble tea',
  '🍺': '맥주 술 beer',
  '🍻': '건배 맥주 술 cheers',
  '🥂': '건배 축하 cheers',
  '🍷': '와인 술 wine',
  '🍶': '소주 술 sake soju',
  // 활동·물건·여행
  '⚽️': '축구 공 soccer football',
  '🏀': '농구 basketball',
  '⚾️': '야구 baseball',
  '🎮': '게임 game',
  '🎵': '음악 노래 music',
  '🎶': '음악 노래 music',
  '🎤': '노래 마이크 노래방 karaoke mic',
  '🎧': '음악 헤드폰 music',
  '🎬': '영화 movie',
  '📷': '사진 카메라 photo camera',
  '📱': '휴대폰 폰 phone',
  '💻': '노트북 컴퓨터 일 laptop work',
  '💡': '아이디어 전구 idea',
  '💰': '돈 money',
  '💸': '돈 지출 money',
  '💳': '카드 결제 card',
  '📚': '책 공부 books study',
  '✏️': '연필 쓰기 pencil',
  '📌': '고정 핀 pin',
  '📅': '달력 일정 calendar',
  '⏰': '알람 시간 alarm',
  '⌛️': '시간 기다림 hourglass',
  '🔑': '열쇠 key',
  '🔒': '잠금 비밀 보안 lock',
  '🏠': '집 home house',
  '🏢': '회사 사무실 office',
  '🏥': '병원 hospital',
  '🏫': '학교 school',
  '🚗': '차 자동차 car',
  '🚌': '버스 bus',
  '🚇': '지하철 subway',
  '✈️': '비행기 여행 plane travel',
  '🚀': '로켓 빠름 출시 rocket launch',
  '🏖️': '바다 휴가 해변 beach vacation',
  '⛺️': '캠핑 camping',
  '🎄': '크리스마스 트리 christmas',
  '🎃': '할로윈 호박 halloween',
  '🧧': '세뱃돈 설날 new year',
};

/// Feeling chips over the emoji grid (tip 378), Telegram's order.
const emojiFeelings = <(String, String)>[
  ('👍', '👍👌✌️🙌👏💪🤝🫡✅💯🔥⭐️🏆🥇'),
  ('❤️', '❤️🧡💛💚💙💜🖤🤍💕💖❤️‍🔥😍🥰😘🫶🫰🤟🌹'),
  ('😂', '😂🤣😆😄😁😀😃😅🤭😹🙃😜🤪'),
  ('🎉', '🎉🎊🥳🎂🎁🎈🍾🥂🍻👏🙌✨🏆'),
  ('😢', '😢😭🥲🥺😞😔😟🙁😿💔😥😓'),
  ('😡', '😡😠🤬😤💢👿🙄😒😑'),
  ('😮', '😮😲😯😳😱🤯😵‍💫😵🫣👀'),
  ('💤', '💤😴🥱😪🛌🌙🛏️'),
  ('👋', '👋🙋🤗🫡🙏🙇✋🤚'),
  ('🍔', '🍔🍕🍟🍗🍜🍚🍣🍰🍩☕️🧋🍺'),
];

String _norm(String s) => s.trim().toLowerCase();

/// Emoji whose words start with (or equal) [query]; exact word first.
/// Also finds by emoji itself (👋 -> 👋 and its cousins sharing a word).
List<String> searchEmoji(String query, {int max = 64}) {
  final q = _norm(query);
  if (q.isEmpty) return const [];
  // (where the word sits in its list, emoji): 하트 is ❤️'s first word, 😍's second.
  final exact = <(int, String)>[], start = <(int, String)>[], inside = <String>[];
  // Typing an emoji: emoji that share its first word.
  if (emojiWords.containsKey(q)) {
    final first = emojiWords[q]!.split(' ').first;
    return [q, ...emojiWords.entries.where((e) => e.key != q && e.value.split(' ').contains(first)).map((e) => e.key)].take(max).toList();
  }
  for (final MapEntry(key: e, value: w) in emojiWords.entries) {
    final words = w.split(' ');
    final at = words.indexOf(q);
    if (at >= 0) {
      exact.add((at, e));
    } else if (words.any((x) => x.startsWith(q))) {
      start.add((words.indexWhere((x) => x.startsWith(q)), e));
    } else if (q.characters.length >= 2 && words.any((x) => x.contains(q))) {
      inside.add(e);
    }
  }
  // Stable sort: same place keeps the list's order.
  List<String> ranked(List<(int, String)> l) => [
    for (final x in ([...l.indexed]..sort((a, b) => a.$2.$1 != b.$2.$1 ? a.$2.$1.compareTo(b.$2.$1) : a.$1.compareTo(b.$1)))) x.$2.$2,
  ];
  return [...ranked(exact), ...ranked(start), ...inside].take(max).toList();
}

/// ':웃음' shortcut (tip 366/221): the word being typed right before the
/// cursor after a colon, else null. ':buru_e1:' codes (our character
/// emoji, already closed) are not shortcuts.
({int start, String word})? colonShortcut(String text, int cursor) {
  if (cursor < 0 || cursor > text.length) return null;
  final before = text.substring(0, cursor);
  final m = RegExp(r'(^|\s):([^\s:]{1,20})$').firstMatch(before);
  if (m == null) return null;
  return (start: m.start + m.group(1)!.length, word: m.group(2)!);
}

/// The last whole word of the message (tip 221 "type a word, get emoji"):
/// only exact word matches, so normal typing is not interrupted.
List<String> emojiForLastWord(String text, {int max = 8}) {
  final m = RegExp(r'([^\s]{1,20})$').firstMatch(text.trimRight());
  if (m == null || text.trim().isEmpty) return const [];
  final w = _norm(m.group(1)!);
  if (w.startsWith(':') || w.startsWith('@') || w.startsWith('http')) return const [];
  // Korean endings: '축하해' / '고마워요' still find 축하 / 고마워.
  final stems = {w, w.replaceAll(RegExp(r'(해요|해|요|합니다|했어|해줘)$'), '')}..removeWhere((x) => x.characters.length < 2 && !RegExp(r'^[a-z]+$').hasMatch(x));
  final out = <String>[];
  for (final MapEntry(key: e, value: ws) in emojiWords.entries) {
    if (ws.split(' ').any(stems.contains)) out.add(e);
  }
  return out.take(max).toList();
}

/// The text is exactly one emoji (tip 294: then stickers are suggested).
bool isSingleEmoji(String text) {
  final t = text.trim();
  if (t.isEmpty || t.characters.length != 1) return false;
  return RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]', unicode: true).hasMatch(t);
}
