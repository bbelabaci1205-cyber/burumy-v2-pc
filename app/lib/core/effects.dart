// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 메시지 효과 (Telegram tip 451, plan B), 큰 이모지 효과 (219 · 297 · 355)
// and 주사위 (218), worked out on the phone.
//
// How an effect travels: right after a text goes out, a hidden end-to-end
// encrypted note (Backend.sendSignal, kind [MsgFx.kind]) tells the other
// phones "the message whose text hashes to h carries effect e". The server
// sees neither the text nor the effect; old apps simply show the text.
// The receiving phone ties the note to the message, plays the effect once
// when the chat is opened, and keeps a small mark on the bubble to replay.
//
// Big emoji: tapping a lone emoji plays its effect; in a 1:1 chat a hidden
// note (kind [MsgFx.tapKind]) lets the friend see it too if they have the
// chat open right then (Telegram's "watch together").
//
// Dice: the result is never chosen by a phone. It comes from the message's
// server-given id (sha256), which no one knows before sending, so every
// phone draws the same face and nobody can pick a six.
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'app_state.dart';
import 'backend.dart';

/// How the pieces move.
enum FxMotion {
  /// Up from the bottom with a sway (hearts, balloons, bubbles).
  rise,

  /// Out from the message in every direction, then falling.
  burst,

  /// Down from the top (snow, petals, confetti).
  fall,

  /// A few bursts at different places on the screen.
  fireworks,

  /// One big piece flying across, with a trail.
  sweep,
}

/// One effect: pieces drawn from [glyphs] ("🫧" = our soap bubble,
/// ":buru_e2_love:" = a Burumy character, "▬" = paper confetti).
class FxKind {
  const FxKind(this.id, this.icon, this.motion, this.glyphs, {this.ko = '', this.en = '', this.count = 34, this.free = true, this.words = const []});
  final String id;

  /// What the picker shows.
  final String icon;
  final FxMotion motion;
  final List<String> glyphs;
  final String ko, en;
  final int count;

  /// Always free now. The slot for Plus-only effects is kept (Features
  /// stays off), so later effects can be added without changing the data.
  final bool free;

  /// Extra words the search knows (Korean and English).
  final List<String> words;

  String name(bool korean) => korean ? ko : en;
}

class MsgFx {
  const MsgFx._();

  /// Hidden note: {h: text hash, e: effect id}.
  static const kind = 'msg_fx';

  /// Hidden note in a 1:1 chat: {e: emoji} tapped just now.
  static const tapKind = 'emoji_fx';

  /// The first row of the picker (Telegram's free six, our way).
  static const quick = ['heart', 'like', 'fire', 'party', 'laugh', 'bubbles'];

  static const all = <FxKind>[
    FxKind('heart', '❤️', FxMotion.rise, ['❤️', '🩷', '💕', '💖'], ko: '하트', en: 'Hearts', words: ['사랑', 'love']),
    FxKind('like', '👍', FxMotion.burst, ['👍'], ko: '좋아요', en: 'Like', count: 22, words: ['최고', 'good']),
    FxKind('fire', '🔥', FxMotion.rise, ['🔥'], ko: '불꽃', en: 'Fire', count: 30, words: ['열정', 'hot']),
    FxKind('party', '🎉', FxMotion.burst, ['▬', '▬', '▬', '🎉', '✨'], ko: '축하', en: 'Party', count: 60, words: ['생일', '폭죽', 'birthday', 'confetti']),
    FxKind('laugh', '😂', FxMotion.fall, ['😂', '🤣'], ko: '웃음', en: 'Laugh', count: 26, words: ['ㅋㅋ', 'lol']),
    FxKind('bubbles', '🫧', FxMotion.rise, ['🫧'], ko: '비눗방울', en: 'Bubbles', count: 24, words: ['부루미', 'burumy']),
    FxKind(
      'buru',
      ':buru_e2_love:',
      FxMotion.rise,
      [':buru_e2_love:', ':dugi_e1_smile:', ':rumi_e8_wink:', ':mongi_e2_love:'],
      ko: '부루미 친구들',
      en: 'Burumy friends',
      count: 16,
      words: ['캐릭터', 'character'],
    ),
    FxKind('balloons', '🎈', FxMotion.rise, ['🎈', '🎈', '🎀'], ko: '풍선', en: 'Balloons', count: 18, words: ['생일', 'birthday']),
    FxKind('fireworks', '🎆', FxMotion.fireworks, ['✨', '⭐', '▬'], ko: '불꽃놀이', en: 'Fireworks', count: 72, words: ['새해', 'new year']),
    FxKind('stars', '⭐', FxMotion.fall, ['⭐', '🌟', '✨'], ko: '별', en: 'Stars', count: 30, words: ['반짝', 'sparkle']),
    FxKind('snow', '❄️', FxMotion.fall, ['❄️', '❄️', '⛄'], ko: '눈', en: 'Snow', count: 36, words: ['겨울', '크리스마스', 'winter', 'christmas']),
    FxKind('petals', '🌸', FxMotion.fall, ['🌸', '🌷', '🌼'], ko: '꽃잎', en: 'Petals', count: 30, words: ['봄', '벚꽃', 'spring', 'flower']),
    FxKind('roses', '🌹', FxMotion.burst, ['🌹', '💐'], ko: '장미', en: 'Roses', count: 20, words: ['고백', '꽃', 'flower']),
    FxKind('kiss', '💋', FxMotion.burst, ['💋', '😘'], ko: '뽀뽀', en: 'Kiss', count: 18, words: ['키스', 'love']),
    FxKind('clap', '👏', FxMotion.burst, ['👏', '🙌'], ko: '박수', en: 'Clap', count: 22, words: ['수고', '대단', 'bravo']),
    FxKind('hundred', '💯', FxMotion.burst, ['💯'], ko: '100점', en: '100', count: 16, words: ['완벽', 'perfect']),
    FxKind('cake', '🎂', FxMotion.burst, ['🎂', '🍰', '🕯️', '▬'], ko: '케이크', en: 'Cake', count: 36, words: ['생일', 'birthday']),
    FxKind('rocket', '🚀', FxMotion.sweep, ['🚀', '✨', '⭐'], ko: '로켓', en: 'Rocket', count: 24, words: ['출발', '화이팅', 'launch']),
    FxKind('rainbow', '🌈', FxMotion.sweep, ['🌈', '☁️', '✨'], ko: '무지개', en: 'Rainbow', count: 18, words: ['행운', 'luck']),
    FxKind('thunder', '⚡', FxMotion.fall, ['⚡'], ko: '번개', en: 'Lightning', count: 14, words: ['깜짝', 'wow']),
    FxKind('leaves', '🍁', FxMotion.fall, ['🍁', '🍂'], ko: '낙엽', en: 'Leaves', count: 28, words: ['가을', 'autumn']),
    FxKind('music', '🎵', FxMotion.rise, ['🎵', '🎶'], ko: '음표', en: 'Music', count: 22, words: ['노래', 'song']),
    FxKind('money', '💸', FxMotion.fall, ['💸', '🪙'], ko: '용돈', en: 'Money', count: 24, words: ['돈', '부자', 'rich']),
    FxKind('ghost', '👻', FxMotion.sweep, ['👻', '💨'], ko: '유령', en: 'Ghost', count: 16, words: ['깜짝', '할로윈', 'halloween']),
    FxKind('sun', '☀️', FxMotion.burst, ['☀️', '✨'], ko: '햇살', en: 'Sunshine', count: 20, words: ['좋은 아침', 'morning']),
    FxKind('sad', '😢', FxMotion.fall, ['💧', '😢'], ko: '눈물', en: 'Tears', count: 26, words: ['슬퍼', 'cry']),
  ];

  static FxKind? byId(String? id) => all.where((k) => k.id == id).firstOrNull;

  /// Picker search: name, icon or extra words.
  static List<FxKind> search(String q, {bool korean = true}) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return all;
    return [
      for (final k in all)
        if (k.ko.contains(s) || k.en.toLowerCase().contains(s) || k.icon == s || k.words.any((w) => w.toLowerCase().contains(s))) k,
    ];
  }

  /// Effect a lone big emoji plays when tapped (none: the emoji bursts).
  static FxKind forEmoji(String emoji) {
    final e = emoji.trim();
    for (final k in all) {
      if (k.icon == e) return k;
    }
    const near = {
      '💖': 'heart',
      '💕': 'heart',
      '🥰': 'heart',
      '😍': 'heart',
      '🎊': 'party',
      '🥳': 'party',
      '🤣': 'laugh',
      '😭': 'sad',
      '🌷': 'petals',
      '💐': 'roses',
      '😘': 'kiss',
      '🙌': 'clap',
      '⛄': 'snow',
    };
    final n = byId(near[e]);
    if (n != null) return n;
    return FxKind('emoji', e, FxMotion.burst, [e], ko: e, en: e, count: 18);
  }

  /// Short hash of a message text (what the hidden note carries).
  static String hashOf(String text) => sha256.convert(utf8.encode(text.trim())).toString().substring(0, 16);

  static const _idsKey = 'msg_fx_ids', _waitKey = 'msg_fx_wait', _playedKey = 'msg_fx_played';

  static Map<String, String> _map(AppState s, String key) {
    try {
      return {for (final e in (jsonDecode(s.pref(key, '{}')) as Map).entries) '${e.key}': '${e.value}'};
    } catch (_) {
      return {};
    }
  }

  static List<Map<String, dynamic>> _waiting(AppState s) {
    try {
      return [for (final x in jsonDecode(s.pref(_waitKey, '[]')) as List) Map<String, dynamic>.from(x as Map)];
    } catch (_) {
      return [];
    }
  }

  /// The effect on a message (null = none).
  static String? of(AppState s, String msgId) => _map(s, _idsKey)[msgId];

  static Future<void> _tie(AppState s, String msgId, String fx) async {
    final m = _map(s, _idsKey)..[msgId] = fx;
    // Kept on this phone only, newest 500.
    final keep = m.entries.toList().reversed.take(500).toList().reversed;
    await s.setPref(_idsKey, jsonEncode({for (final e in keep) e.key: e.value}));
  }

  /// I sent [text] with effect [fx]: tell the other phones, tie it to my
  /// own message (newest of mine with that text) and return its id.
  static Future<String?> sent(AppState s, String roomId, String text, String fx, List<Msg> timeline) async {
    if (byId(fx) == null) return null;
    final h = hashOf(text);
    await s.backend.sendSignal(roomId, kind, {'h': h, 'e': fx});
    final mine = timeline.reversed.where((m) => m.mine && m.kind == 'text' && hashOf(m.body ?? '') == h).firstOrNull;
    if (mine == null) return null;
    await _tie(s, mine.id, fx);
    await markPlayed(s, mine.id);
    return mine.id;
  }

  /// A hidden note arrived: keep it until its message shows up.
  static Future<void> onSignal(AppState s, Signal sig) async {
    final h = sig.data['h'], e = sig.data['e'];
    if (h is! String || e is! String || h.length != 16 || byId(e) == null) return;
    final w = _waiting(s)..add({'r': sig.roomId, 's': sig.sender, 'h': h, 'e': e, 't': sig.time.millisecondsSinceEpoch});
    await s.setPref(_waitKey, jsonEncode(w.length > 50 ? w.sublist(w.length - 50) : w));
  }

  /// Ties waiting notes to messages in [timeline]; returns the ids of
  /// messages with an effect that has not played yet (newest last).
  static Future<List<String>> match(AppState s, String roomId, List<Msg> timeline) async {
    final w = _waiting(s);
    if (w.isNotEmpty) {
      final left = <Map<String, dynamic>>[];
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final x in w) {
        if (x['r'] != roomId) {
          // Notes for chats never opened go after two days.
          if (now - ((x['t'] as num?) ?? 0) < 2 * 86400000) left.add(x);
          continue;
        }
        final m = timeline.reversed.where((m) => !m.mine && m.sender == x['s'] && m.kind == 'text' && hashOf(m.body ?? '') == x['h']).firstOrNull;
        if (m == null) {
          left.add(x);
        } else {
          await _tie(s, m.id, '${x['e']}');
        }
      }
      if (left.length != w.length) await s.setPref(_waitKey, jsonEncode(left));
    }
    final ids = _map(s, _idsKey);
    final played = _played(s);
    return [
      for (final m in timeline)
        if (!m.mine && ids.containsKey(m.id) && !played.contains(m.id)) m.id,
    ];
  }

  static Set<String> _played(AppState s) => s.pref(_playedKey, '').split(',').where((x) => x.isNotEmpty).toSet();

  static Future<void> markPlayed(AppState s, String msgId) async {
    final p = _played(s).toList()..add(msgId);
    await s.setPref(_playedKey, (p.length > 500 ? p.sublist(p.length - 500) : p).join(','));
  }

  // ---------------------------------------------------------------- live

  /// Effects to play now in an open chat: (room, effect, emoji).
  static final live = StreamController<(String, FxKind)>.broadcast();

  static DateTime _lastTap = DateTime(2000);

  /// I tapped a big emoji in a 1:1 chat: the friend sees it too if they
  /// have the chat open (at most once a second).
  static Future<void> tapped(AppState s, String roomId, String emoji) async {
    final now = DateTime.now();
    if (now.difference(_lastTap) < const Duration(seconds: 1)) return;
    _lastTap = now;
    try {
      await s.backend.sendSignal(roomId, tapKind, {'e': emoji});
    } catch (_) {}
  }

  static Future<void> onTapSignal(AppState s, Signal sig) async {
    final e = sig.data['e'];
    // Only a short lone emoji, and only fresh taps (not old ones arriving late).
    if (e is! String || e.isEmpty || e.length > 16) return;
    if (DateTime.now().difference(sig.time).inSeconds.abs() > 30) return;
    live.add((sig.roomId, forEmoji(e)));
  }
}

// ------------------------------------------------------------------ dice

/// Games that roll when sent alone, like Telegram: (emoji, faces).
class Dice {
  const Dice._();

  static const kinds = {'🎲': 6, '🎯': 6, '🏀': 5, '⚽': 5, '🎳': 6, '🎰': 64};

  /// A text that is only one of the game emoji.
  static String? gameOf(String text) {
    final t = text.trim().replaceAll('\u{FE0F}', '');
    return kinds.containsKey(t) ? t : null;
  }

  /// Result 1..faces from the message id (the server gives the id; nobody
  /// chooses it), the same on every phone.
  static int valueOf(String game, String msgId) {
    final faces = kinds[game] ?? 6;
    final d = sha256.convert(utf8.encode('burumy-dice:$game:$msgId')).bytes;
    final n = (d[0] << 24 | d[1] << 16 | d[2] << 8 | d[3]) & 0x7fffffff;
    return n % faces + 1;
  }

  /// Slot machine reels for a 1..64 result: three of 🍒 🍋 🔔 7️⃣.
  static const reelFaces = ['🍒', '🍋', '🔔', '7️⃣'];
  static List<String> reels(int v) {
    final i = v - 1;
    return [reelFaces[i % 4], reelFaces[i ~/ 4 % 4], reelFaces[i ~/ 16 % 4]];
  }

  /// A "win" worth celebrating (top score / three of a kind / in the hoop).
  static bool win(String game, int v) => switch (game) {
    '🎰' => reels(v).toSet().length == 1,
    '🏀' || '⚽' => v >= 4,
    _ => v == 6,
  };
}
