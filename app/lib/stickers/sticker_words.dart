// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// What each sticker means, for the sticker search and the feeling row
// (Telegram: heart, thumbs up, ...). Search words, not screen text.
import 'package:flutter/cupertino.dart';

import '../core/emoji_words.dart';

/// Meaning (the last part of a sticker id) -> words people type.
const stickerWords = <String, List<String>>{
  'hello': ['안녕', '인사', '하이', 'hi', 'hello', '👋'],
  'thanks': ['고마워', '감사', 'thanks', 'thank', '🙏'],
  'love': ['사랑', '하트', '좋아해', 'love', 'heart', '❤️'],
  'good': ['좋아', '최고', '굿', 'good', 'like', '👍'],
  'lol': ['웃음', 'ㅋㅋ', 'ㅎㅎ', '웃겨', 'lol', 'haha', '😂'],
  'sorry': ['미안', '죄송', 'sorry', '🙇'],
  'night': ['잘자', '굿밤', '밤', 'night', 'sleep', '🌙'],
  'angry': ['화나', '화남', '짜증', 'angry', 'mad', '😠'],
  'wow': ['대박', '놀람', '헐', 'wow', '😮'],
  'sad': ['슬퍼', '눈물', '우울', 'sad', 'cry', '😢'],
  'congrats': ['축하', '생일', 'congrats', 'party', '🎉'],
  'fighting': ['화이팅', '파이팅', '힘내', 'fighting', '💪'],
  'hmm': ['음', '고민', '글쎄', 'hmm', 'think', '🤔'],
  'ok': ['오케이', '알았어', '응', 'ok', 'okay', '👌'],
  'secret': ['비밀', '쉿', 'secret', '🤫'],
  'dizzy': ['어지러', '멘붕', 'dizzy', '😵'],
  'brr': ['부르르', '진동', '연락해', '메시지', '추워', 'brr', 'buzz', '📳', '🥶'],
  'wink': ['윙크', '찡긋', 'wink', '😉'],
};

/// The feeling row beside '검색', in Telegram's order.
const stickerFeelings = <(String, IconData, List<String>)>[
  ('love', CupertinoIcons.heart, ['love']),
  ('like', CupertinoIcons.hand_thumbsup, ['good', 'ok', 'fighting']),
  ('dislike', CupertinoIcons.hand_thumbsdown, ['hmm', 'angry']),
  ('party', CupertinoIcons.sparkles, ['congrats', 'wow']),
  ('hello', CupertinoIcons.hand_raised, ['hello']),
  // 잘자 (Eric 2026-11-27): sleeping ones apart from waving ones.
  ('sleep', CupertinoIcons.moon_zzz, ['night']),
  ('smile', CupertinoIcons.smiley, ['lol', 'thanks']),
  ('sad', CupertinoIcons.drop, ['sad', 'sorry']),
  ('angry', CupertinoIcons.flame, ['angry', 'dizzy']),
];

/// The meaning part of 'buru_03_love' -> 'love'.
String stickerMeaning(String id) => id.split('_').skip(2).join('_');

/// Character (pack) -> words people type: '토끼 사랑', 'rabbit love'.
const stickerCharWords = <String, List<String>>{
  'buru': ['부루', '토끼', 'rabbit', 'bunny', 'buru'],
  'dugi': ['두기', '두더지', 'mole', 'dugi'],
  'rumi': ['루미', '말풍선', '젤리', 'rumi', 'bubble'],
  'mongi': ['몽지', '먼지', '구름', 'mongi', 'cloud'],
  'duru': ['두루', '두루미', '학', '새', 'crane', 'bird', 'duru'],
  'burumi': ['부루미', '비눗방울', '방울', 'burumi'],
  'hip': ['힙', '시티', '힙스터', 'hip', 'city'],
  'dandy': ['댄디', '신사', 'dandy'],
};

/// Extra words for a meaning (actions people type: '울고 있는 곰').
const _moreWords = <String, List<String>>{
  'sad': ['울어', '울고', '우는', '엉엉'],
  'lol': ['웃는', '웃고', '깔깔'],
  'love': ['사랑해', '좋아요', '뽀뽀'],
  'night': ['자는', '졸려', '잠'],
  'angry': ['화난', '삐짐'],
  'hello': ['반가워', '하이'],
  'thanks': ['고맙', '땡큐'],
  'congrats': ['축하해', '파티', '케이크'],
  'fighting': ['힘내', '응원'],
  'wow': ['놀란', '깜짝'],
  'moving': ['움직이는', '움짤', 'animated'],
};

/// Little words that don't narrow a search ('커피 마시는 고양이' keeps 커피, 고양이).
const _skip = {'있는', '하는', '그', '이', '저', 'a', 'the', 'is', 'with', 'and'};

bool _wordHits(String id, String w, {String emoji = ''}) {
  final m = stickerMeaning(id);
  final pack = id.split('_').first;
  if (m.contains(w) || (emoji.isNotEmpty && w == emoji)) return true;
  bool any(List<String>? ws) => (ws ?? const []).any((x) {
    final y = x.toLowerCase();
    return y.contains(w) || (w.length >= 2 && w.contains(y) && y.length >= 2);
  });
  if (any(stickerWords[m]) || any(_moreWords[m]) || any(stickerCharWords[pack])) return true;
  return StickerPackLike.moving(id) && any(_moreWords['moving']);
}

/// Stickers whose meaning matches what was typed. Several words (tip 496,
/// '울고 있는 곰', 'rabbit love') must all fit: the character, the
/// feeling, moving or not. [emoji] = the emoji a sticker in my own set stands for.
bool stickerMatches(String id, String query, {String emoji = ''}) {
  final words = [
    for (final w in query.trim().toLowerCase().split(RegExp(r'\s+')))
      if (w.isNotEmpty && !_skip.contains(w)) w,
  ];
  if (words.isEmpty) return query.trim().isEmpty;
  return words.every((w) => _wordHits(id, w, emoji: emoji));
}

/// Whether a built-in sticker moves (same rule as StickerPack.moving).
class StickerPackLike {
  static bool moving(String item) => item.split('_').elementAtOrNull(1)?.startsWith('a') ?? false;
}

/// Built-in stickers for an emoji (tip 294: type 😂, get 😂 stickers).
List<String> stickersForEmoji(String emoji, Iterable<String> ids) {
  final e = emoji.trim();
  // The emoji itself, and its words (😭 -> 울어, 슬퍼, cry ...).
  final words = {e, ...(emojiWords[e] ?? '').split(' ').where((w) => w.isNotEmpty)};
  return [
    for (final id in ids)
      if ((stickerWords[stickerMeaning(id)] ?? const []).any(words.contains)) id,
  ];
}

/// Emoji tab, Apple's group order (smileys first).
const emojiGroups = <(String, IconData, String)>[
  (
    'smileys',
    CupertinoIcons.smiley,
    '😀😃😄😁😆🥹😅😂🤣🥲☺️😊😇🙂🙃😉😌😍🥰😘😗😙😚😋😛😝😜🤪🤨🧐🤓😎🥸🤩🥳🙂‍↕️😏😒🙂‍↔️😞😔😟😕🙁☹️😣😖😫😩🥺😢😭😮‍💨😤😠😡🤬🤯😳🥵🥶😱😨😰😥😓🫣🤗🫡🤔🫢🤭🤫🤥😶😐😑😬🫨🙄😯😦😧😮😲🥱😴🤤😪😵😵‍💫🫥🤐🥴🤢🤮🤧😷🤒🤕🤑🤠😈👿👹👺🤡💩👻💀☠️👽👾🤖🎃😺😸😹😻😼😽🙀😿😾',
  ),
  (
    'people',
    CupertinoIcons.hand_raised,
    '👋🤚🖐️✋🖖👌🤌🤏✌️🤞🫰🤟🤘🤙👈👉👆🖕👇☝️🫵👍👎✊👊🤛🤜👏🙌🫶👐🤲🤝🙏✍️💅🤳💪🦾🦵🦶👂🦻👃🧠🫀🫁🦷🦴👀👁️👅👄🫦👶🧒👦👧🧑👱👨🧔👩🧓👴👵🙍🙎🙅🙆💁🙋🧏🙇🤦🤷👮🕵️💂🥷👷🫅🤴👸👳👲🧕🤵👰🤰🫄🤱👼🎅🤶🦸🦹🧙🧚🧛🧜🧝🧞🧟🧌💆💇🚶🧍🧎🏃💃🕺👯🧖🧗🤺🏇⛷️🏂🏌️🏄🚣🏊⛹️🏋️🚴🚵🤸🤼🤽🤾🤹🧘🛀🛌👭👫👬💏💑👪',
  ),
  (
    'animals',
    CupertinoIcons.paw,
    '🐶🐱🐭🐹🐰🦊🐻🐼🐻‍❄️🐨🐯🦁🐮🐷🐽🐸🐵🙈🙉🙊🐒🐔🐧🐦🐤🐣🐥🪿🦆🐦‍⬛🦅🦉🦇🐺🐗🐴🦄🫎🐝🪱🐛🦋🐌🐞🐜🪰🪲🪳🦟🦗🕷️🦂🐢🐍🦎🦖🦕🐙🦑🦐🦞🦀🪼🐡🐠🐟🐬🐳🐋🦈🦭🐊🐅🐆🦓🦍🦧🦣🐘🦛🦏🐪🐫🦒🦘🦬🐃🐂🐄🫏🐎🐖🐏🐑🦙🐐🦌🐕🐩🦮🐕‍🦺🐈🐈‍⬛🪶🪽🐓🦃🦤🦚🦜🦢🦩🕊️🐇🦝🦨🦡🦫🦦🦥🐁🐀🐿️🦔🌵🎄🌲🌳🌴🪵🌱🌿☘️🍀🎍🪴🎋🍃🍂🍁🍄🐚🪨🌾💐🌷🌹🥀🪻🪷🌺🌸🌼🌻🌞🌝🌛🌜🌚🌕🌙🌎🪐💫⭐️🌟✨⚡️☄️💥🔥🌪️🌈☀️🌤️⛅️🌥️☁️🌦️🌧️⛈️🌩️🌨️❄️☃️⛄️🌬️💨💧💦🫧☔️☂️🌊',
  ),
  (
    'food',
    CupertinoIcons.cart,
    '🍏🍎🍐🍊🍋🍋‍🟩🍌🍉🍇🍓🫐🍈🍒🍑🥭🍍🥥🥝🍅🍆🥑🥦🫛🥬🥒🌶️🫑🌽🥕🫒🧄🧅🥔🍠🫚🥐🥯🍞🥖🥨🧀🥚🍳🧈🥞🧇🥓🥩🍗🍖🦴🌭🍔🍟🍕🫓🥪🥙🧆🌮🌯🫔🥗🥘🫕🥫🍝🍜🍲🍛🍣🍱🥟🦪🍤🍙🍚🍘🍥🥠🥮🍢🍡🍧🍨🍦🥧🧁🍰🎂🍮🍭🍬🍫🍿🍩🍪🌰🥜🍯🥛🍼🫖☕️🍵🧃🥤🧋🍶🍺🍻🥂🍷🥃🍸🍹🧉🍾🧊🥄🍴🍽️🥣🥡🥢🧂',
  ),
  (
    'activity',
    CupertinoIcons.sportscourt,
    '⚽️🏀🏈⚾️🥎🎾🏐🏉🥏🎱🪀🏓🏸🏒🏑🥍🏏🪃🥅⛳️🪁🏹🎣🤿🥊🥋🎽🛹🛼🛷⛸️🥌🎿🏆🥇🥈🥉🏅🎖️🏵️🎗️🎫🎟️🎪🤹🎭🩰🎨🎬🎤🎧🎼🎹🥁🪘🪇🎷🎺🪗🎸🪕🎻🪈🎲♟️🎯🎳🎮🎰🧩',
  ),
  (
    'travel',
    CupertinoIcons.car,
    '🚗🚕🚙🚌🚎🏎️🚓🚑🚒🚐🛻🚚🚛🚜🦯🦽🦼🛴🚲🛵🏍️🛺🚨🚔🚍🚘🚖🚡🚠🚟🚃🚋🚞🚝🚄🚅🚈🚂🚆🚇🚊🚉✈️🛫🛬🛩️💺🛰️🚀🛸🚁🛶⛵️🚤🛥️🛳️⛴️🚢⚓️🛟🪝⛽️🚧🚦🚥🚏🗺️🗿🗽🗼🏰🏯🏟️🎡🎢🛝🎠⛲️⛱️🏖️🏝️🏜️🌋⛰️🏔️🗻🏕️⛺️🛖🏠🏡🏘️🏚️🏗️🏭🏢🏬🏣🏤🏥🏦🏨🏪🏫🏩💒🏛️⛪️🕌🕍🛕🕋⛩️🛤️🛣️🗾🎑🏞️🌅🌄🌠🎇🎆🌇🌆🏙️🌃🌌🌉🌁',
  ),
  (
    'objects',
    CupertinoIcons.lightbulb,
    '⌚️📱📲💻⌨️🖥️🖨️🖱️🖲️🕹️🗜️💽💾💿📀📼📷📸📹🎥📽️🎞️📞☎️📟📠📺📻🎙️🎚️🎛️🧭⏱️⏲️⏰🕰️⌛️⏳📡🔋🪫🔌💡🔦🕯️🪔🧯🛢️💸💵💴💶💷🪙💰💳💎⚖️🪜🧰🪛🔧🔨⚒️🛠️⛏️🪚🔩⚙️🪤🧱⛓️🧲🔫💣🧨🪓🔪🗡️⚔️🛡️🚬⚰️🪦⚱️🏺🔮📿🧿🪬💈⚗️🔭🔬🕳️🩹🩺🩻🩼💊💉🩸🧬🦠🧫🧪🌡️🧹🪠🧺🧻🚽🚰🚿🛁🛀🧼🪥🪒🪮🧽🪣🧴🛎️🔑🗝️🚪🪑🛋️🛏️🛌🧸🪆🖼️🪞🪟🛍️🛒🎁🎈🎏🎀🪄🪅🎊🎉🎎🪭🏮🎐🪩🧧✉️📩📨📧💌📥📤📦🏷️🪧📪📫📬📭📮📯📜📃📄📑🧾📊📈📉🗒️🗓️📆📅🗑️🪪📇🗃️🗳️🗄️📋📁📂🗂️🗞️📰📓📔📒📕📗📘📙📚📖🔖🧷🔗📎🖇️📐📏🧮📌📍✂️🖊️🖋️✒️🖌️🖍️📝✏️🔍🔎🔏🔐🔒🔓',
  ),
  (
    'symbols',
    CupertinoIcons.heart,
    '❤️🩷🧡💛💚💙🩵💜🖤🩶🤍🤎❤️‍🔥❤️‍🩹💔❣️💕💞💓💗💖💘💝💟☮️✝️☪️🕉️☸️🪯✡️🔯🕎☯️☦️🛐⛎♈️♉️♊️♋️♌️♍️♎️♏️♐️♑️♒️♓️🆔⚛️🉑☢️☣️📴📳🈶🈚️🈸🈺🈷️✴️🆚💮🉐㊙️㊗️🈴🈵🈹🈲🅰️🅱️🆎🆑🅾️🆘❌⭕️🛑⛔️📛🚫💯💢♨️🚷🚯🚳🚱🔞📵🚭❗️❕❓❔‼️⁉️🔅🔆〽️⚠️🚸🔱⚜️🔰♻️✅🈯️💹❇️✳️❎🌐💠Ⓜ️🌀💤🏧🚾♿️🅿️🛗🈳🈂️🛂🛃🛄🛅🚹🚺🚼⚧️🚻🚮🎦🛜📶🈁🔣ℹ️🔤🔡🔠🆖🆗🆙🆒🆕🆓0️⃣1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣9️⃣🔟🔢#️⃣*️⃣⏏️▶️⏸️⏯️⏹️⏺️⏭️⏮️⏩️⏪️⏫️⏬️◀️🔼🔽➡️⬅️⬆️⬇️↗️↘️↙️↖️↕️↔️↪️↩️⤴️⤵️🔀🔁🔂🔄🔃🎵🎶➕➖➗✖️🟰♾️💲💱™️©️®️〰️➰➿🔚🔙🔛🔝🔜✔️☑️🔘🔴🟠🟡🟢🔵🟣⚫️⚪️🟤🔺🔻🔸🔹🔶🔷🔳🔲▪️▫️◾️◽️◼️◻️🟥🟧🟨🟩🟦🟪⬛️⬜️🟫🔈🔇🔉🔊🔔🔕📣📢💬💭🗯️♠️♣️♥️♦️🃏🎴🀄️🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛',
  ),
];
