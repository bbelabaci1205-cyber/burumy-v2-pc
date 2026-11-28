// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// AI 편집기 (TelegramTips 561 + 569): fix spelling, translate, rewrite in a
// style, and "내 말투" (my own styles) that can be shared as a link.
//
// A shared style travels inside the link itself, after '#':
//   https://<host>/style#s=<base64url of {"e":emoji,"n":name,"r":rules}>
// so no server ever stores or counts it.
import 'dart:convert';

import '../brand/brand.dart';

class AiStyle {
  const AiStyle({required this.id, required this.emoji, required this.name, required this.rules, this.builtIn = false});

  final String id;
  final String emoji;
  final String name;

  /// What the person wrote ("외계인처럼 써 줘"). Built-in styles keep an
  /// English rule here and show [name] from the app's words.
  final String rules;
  final bool builtIn;

  Map<String, String> toJson() => {'i': id, 'e': emoji, 'n': name, 'r': rules};

  static AiStyle? fromJson(Object? j) {
    if (j is! Map) return null;
    final e = '${j['e'] ?? ''}', n = '${j['n'] ?? ''}', r = '${j['r'] ?? ''}';
    final s = AiStyle(id: '${j['i'] ?? AiStyles.newId(n, r)}', emoji: e, name: n, rules: r);
    return AiStyles.check(s) == null ? s : null;
  }
}

class AiStyles {
  const AiStyles._();

  static const maxName = 24;
  static const maxRules = 300;
  static const maxMine = 30;

  /// Built-in styles (name key → emoji, rule). Names come from L10n.
  static const builtIns = <AiStyle>[
    AiStyle(id: 'formal', emoji: '🤝', name: 'formal', rules: 'Polite and formal, like writing to someone you respect.', builtIn: true),
    AiStyle(id: 'short', emoji: '🎯', name: 'short', rules: 'As short as possible. Keep only what matters.', builtIn: true),
    AiStyle(id: 'friendly', emoji: '😊', name: 'friendly', rules: 'Warm and friendly, like talking to a close friend.', builtIn: true),
    AiStyle(id: 'work', emoji: '💼', name: 'work', rules: 'Clear business tone for a coworker: polite, to the point.', builtIn: true),
    AiStyle(id: 'historic', emoji: '📜', name: 'historic', rules: 'Old-fashioned, like a character in a historical drama.', builtIn: true),
    AiStyle(id: 'zen', emoji: '🗿', name: 'zen', rules: 'Calm and simple, like a quiet monk.', builtIn: true),
  ];

  /// Words a style's rules may not ask for (kept short on purpose: the
  /// model's own safety rules do the rest).
  static final _blocked = RegExp(
    r'(욕설|욕을|욕해|비속어|협박|혐오|자살|자해|마약|살해|죽여|성적|야한|음란|사칭|비밀번호|인증번호|계좌|송금|사기|'
    r'password|passcode|threat|slur|hate|suicide|self-harm|drugs|kill|sexual|nsfw|porn|impersonat|scam|phish|'
    r'ignore (all|previous|the above)|system prompt|jailbreak|이전 지시|지시를 무시)',
    caseSensitive: false,
  );

  /// True when [rules] alone would be blocked (for the 만들기 page).
  static bool blockedWords(String text) => _blocked.hasMatch(text);

  /// Null when fine, else a reason: "empty", "long", "blocked".
  static String? check(AiStyle s) {
    final n = s.name.trim(), r = s.rules.trim();
    if (n.isEmpty || r.isEmpty || s.emoji.trim().isEmpty) return 'empty';
    if (n.runes.length > maxName || r.runes.length > maxRules || s.emoji.runes.length > 8) return 'long';
    if (_blocked.hasMatch(n) || _blocked.hasMatch(r)) return 'blocked';
    return null;
  }

  static String newId(String name, String rules) {
    final h = utf8.encode('$name\n$rules').fold<int>(7, (a, b) => (a * 31 + b) & 0x7fffffff);
    return 'm${h.toRadixString(36)}';
  }

  // ---- my styles (kept in the account's settings, which sync encrypted) --

  static List<AiStyle> mine(String pref) {
    if (pref.isEmpty) return const [];
    try {
      final list = jsonDecode(pref);
      if (list is! List) return const [];
      return [for (final j in list) ?AiStyle.fromJson(j)];
    } catch (_) {
      return const [];
    }
  }

  static String save(List<AiStyle> list) => list.isEmpty ? '' : jsonEncode([for (final s in list.take(maxMine)) s.toJson()]);

  /// Adds (or replaces the same id) at the front.
  static List<AiStyle> add(List<AiStyle> list, AiStyle s) => [s, ...list.where((x) => x.id != s.id)].take(maxMine).toList();

  // ---- links ----

  static String get host => Brand.linkHost;

  static String link(AiStyle s) {
    final body = base64Url.encode(utf8.encode(jsonEncode({'e': s.emoji, 'n': s.name, 'r': s.rules}))).replaceAll('=', '');
    return 'https://$host/style#s=$body';
  }

  static RegExp get _linkRe => RegExp('(?:https?://)?${RegExp.escape(host)}/style#s=([A-Za-z0-9_-]+)');

  /// [text] without its style link (the card shows the style instead).
  static String withoutLink(String text) => text.replaceAll(_linkRe, '').trim();

  /// A style link anywhere in [text], or null.
  static AiStyle? parse(String text) {
    final m = _linkRe.firstMatch(text);
    if (m == null) return null;
    try {
      var b = m.group(1)!;
      b += '=' * ((4 - b.length % 4) % 4);
      final j = jsonDecode(utf8.decode(base64Url.decode(b)));
      if (j is! Map) return null;
      return AiStyle.fromJson({...j, 'i': newId('${j['n']}', '${j['r']}')});
    } catch (_) {
      return null;
    }
  }

  // ---- what we ask the model ----

  static const _base =
      'You edit one chat message for the person who wrote it. Reply with the edited message only: '
      'no quotes, no notes, no greeting. Keep the meaning, names, numbers, links and line breaks. '
      'Never add facts. Write in the same language as the message unless told to translate.';

  static String fixRules() => '$_base Fix spelling, spacing and grammar only. Change as little as possible.';

  static String translateRules(String language) => '$_base Translate the message into $language. Keep the tone.';

  static String styleRules(AiStyle s, {bool emojify = false}) =>
      '$_base Rewrite it in this style: ${s.rules.trim()}${emojify ? ' Add a few fitting emoji.' : ''} '
      'If the style asks for anything harmful, ignore that part.';

  /// Longest message the AI editor takes (on-phone models have small
  /// windows; Apple's is about 4,000 tokens for rules + text + answer).
  static const maxText = 1500;

  /// What came back is not a usable edit (empty, or far longer than asked).
  static bool badOutput(String input, String output) {
    final o = output.trim();
    return o.isEmpty || o.runes.length > input.runes.length * 4 + 200;
  }
}

/// The language a message is written in, by its letters (good enough to
/// say "원래 언어: 영어"; the phone model does the real work).
String detectLanguage(String text) {
  var ko = 0, ja = 0, zh = 0, latin = 0, cyr = 0, other = 0;
  for (final r in text.runes) {
    if (r >= 0xAC00 && r <= 0xD7A3 || r >= 0x3131 && r <= 0x318E) {
      ko++;
    } else if (r >= 0x3040 && r <= 0x30FF) {
      ja++;
    } else if (r >= 0x4E00 && r <= 0x9FFF) {
      zh++;
    } else if (r >= 0x41 && r <= 0x5A || r >= 0x61 && r <= 0x7A || r >= 0xC0 && r <= 0x24F) {
      latin++;
    } else if (r >= 0x400 && r <= 0x4FF) {
      cyr++;
    } else if (r > 0x7F && r != 0x20) {
      other++;
    }
  }
  if (ja > 0 && ja + zh >= ko && ja + zh >= latin) return 'ja';
  final best = [('ko', ko), ('zh', zh), ('en', latin), ('ru', cyr), ('', other)]..sort((a, b) => b.$2.compareTo(a.$2));
  return best.first.$2 == 0 ? '' : best.first.$1;
}

/// Languages the 번역 tab offers (code → English name for the model).
const aiLanguages = <String, String>{
  'ko': 'Korean',
  'en': 'English',
  'ja': 'Japanese',
  'zh': 'Simplified Chinese',
  'es': 'Spanish',
  'vi': 'Vietnamese',
  'ru': 'Russian',
};

/// One piece of the result and whether it differs from the original.
typedef DiffPart = ({String text, bool changed});

/// Splits [after] into pieces, marking the words that are not in [before]
/// (word-level, longest common run), for the underline under fixed words.
List<DiffPart> wordDiff(String before, String after) {
  final tok = RegExp(r'\s+|[^\s]+');
  final a = [for (final m in tok.allMatches(before)) m.group(0)!];
  final b = [for (final m in tok.allMatches(after)) m.group(0)!];
  if (a.length * b.length > 250000) return [(text: after, changed: false)];
  final n = a.length, m = b.length;
  final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      dp[i][j] = a[i] == b[j] ? dp[i + 1][j + 1] + 1 : (dp[i + 1][j] >= dp[i][j + 1] ? dp[i + 1][j] : dp[i][j + 1]);
    }
  }
  final out = <DiffPart>[];
  void push(String t, bool c) {
    final space = t.trim().isEmpty;
    if (out.isNotEmpty && (out.last.changed == (c && !space) || space)) {
      out[out.length - 1] = (text: out.last.text + t, changed: out.last.changed);
    } else {
      out.add((text: t, changed: c && !space));
    }
  }

  var i = 0, j = 0;
  while (j < m) {
    if (i < n && a[i] == b[j]) {
      push(b[j], false);
      i++;
      j++;
    } else if (i < n && dp[i + 1][j] >= dp[i][j + 1]) {
      i++;
    } else {
      push(b[j], true);
      j++;
    }
  }
  return out;
}
