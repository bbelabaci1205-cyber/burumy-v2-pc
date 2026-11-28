// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 테마·배경·꾸미기 (Telegram tip batches #21 + #24, 2026-11-27): the data
// behind chat backgrounds, made themes, name / profile looks and group or
// channel looks. Only words and colour numbers live here; drawing is in
// ui/wallpaper.dart and ui/look_studio.dart.
//
// What travels where:
// - A chat background ("배경") is one short text, e.g. `secure`,
//   `color:F2D7E1~s=40~p=hearts` or `grad:FFB3C7-C7A6FF-9FD8FF-B8F2D8~p=stars`.
//   It is kept on this phone; in a 1:1 chat it may go to the other phone
//   as a hidden end-to-end encrypted note (tip 295 / 387 / 410). My own
//   photo never leaves this phone.
// - A theme I made (tip 173 / 226) travels inside its link after '#', so
//   no web server sees it; the link itself goes in an encrypted message.
// - My name colour + reply icons + profile colour + profile icons (tip 402
//   / 409) are one short text: on my member event in groups (like the old
//   name colour, the server sees it like any name) and as an encrypted note
//   in 1:1 chats.
// - A group / channel look (tip 412 / 429) is the room setting `look`,
//   which only admins can change (the server checks).
import 'dart:convert';
import 'dart:ui';

import '../brand/brand.dart';

/// `RRGGBB` → colour; [or] when it is not a colour.
Color hexColor(String hex, [Color or = const Color(0x00000000)]) {
  final h = hex.trim().replaceFirst('#', '');
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(h)) return or;
  return Color(0xFF000000 | int.parse(h, radix: 16));
}

/// Colour → `RRGGBB`.
String hexOf(Color c) => (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

/// A colour made light enough to carry white words and our "bright only"
/// rule (no dark accents): mixed toward white until bright enough.
Color brightEnough(Color c, {double min = 0.19}) {
  var x = c;
  for (var i = 0; i < 12 && x.computeLuminance() < min; i++) {
    x = Color.lerp(x, const Color(0xFFFFFFFF), 0.12)!;
  }
  return x;
}

// ------------------------------------------------------------ backgrounds

/// One chat background.
class Wall {
  const Wall({this.kind = 'theme', this.id = 'plain', this.colors = const [], this.pattern = '', this.strength = 0.5, this.blur = false, this.motion = false});

  /// 'theme' (one of ours, see ChatTheme), 'photo' (my own picture),
  /// 'color' (one colour) or 'grad' (3–4 colours that swirl).
  final String kind;

  /// Our theme's id (kind 'theme').
  final String id;
  final List<Color> colors;

  /// Icons drawn over it ('' = none); see [Patterns].
  final String pattern;

  /// How strong the icons show, 0..1 (무늬 강도).
  final double strength;

  /// My photo, softly blurred (흐림).
  final bool blur;

  /// Drifts with the phone's tilt (움직임).
  final bool motion;

  static const plain = Wall();

  bool get isPlain => kind == 'theme' && id == 'plain' && pattern.isEmpty;

  /// The longest background text we take from another phone or a link.
  static const maxLength = 120;

  static Wall parse(String spec) {
    final parts = spec.trim().split('~');
    final head = parts.first;
    final opts = <String, String>{};
    for (final o in parts.skip(1)) {
      final i = o.indexOf('=');
      if (i > 0) opts[o.substring(0, i)] = o.substring(i + 1);
    }
    final pattern = Patterns.sets.containsKey(opts['p']) ? opts['p']! : '';
    final strength = ((int.tryParse(opts['s'] ?? '') ?? 50).clamp(0, 100)) / 100;
    final blur = opts['b'] == '1', motion = opts['m'] == '1';
    if (head.startsWith('color:')) {
      final c = hexColor(head.substring(6), const Color(0xFFFFFFFF));
      return Wall(kind: 'color', colors: [c], pattern: pattern, strength: strength, motion: motion);
    }
    if (head.startsWith('grad:')) {
      final cs = [for (final h in head.substring(5).split('-').take(4)) hexColor(h, const Color(0xFFFFFFFF))];
      if (cs.length < 2) return plain;
      return Wall(kind: 'grad', colors: cs, pattern: pattern, strength: strength, motion: motion);
    }
    if (head == 'photo') return Wall(kind: 'photo', id: 'photo', blur: blur, motion: motion);
    if (head.isEmpty) return plain;
    return Wall(id: head, pattern: pattern, strength: opts.containsKey('s') ? strength : -1, motion: motion);
  }

  String encode() {
    final head = switch (kind) {
      'color' => 'color:${hexOf(colors.first)}',
      'grad' => 'grad:${colors.map(hexOf).join('-')}',
      'photo' => 'photo',
      _ => id,
    };
    return [
      head,
      if (pattern.isNotEmpty) 'p=$pattern',
      if (strength >= 0 && (kind == 'color' || kind == 'grad' || strength != 0.5) && kind != 'photo') 's=${(strength * 100).round()}',
      if (blur && kind == 'photo') 'b=1',
      if (motion) 'm=1',
    ].join('~');
  }

  Wall copyWith({List<Color>? colors, String? pattern, double? strength, bool? blur, bool? motion}) => Wall(
    kind: kind,
    id: id,
    colors: colors ?? this.colors,
    pattern: pattern ?? this.pattern,
    strength: strength ?? this.strength,
    blur: blur ?? this.blur,
    motion: motion ?? this.motion,
  );

  /// Ours to show from another phone: short, known kinds, never a photo.
  static bool sendable(String spec) => spec.length <= maxLength && !spec.startsWith('photo');

  // -------------------------------------------------- ready-made colours

  /// 단색 (tip 181): soft iOS-like colours that keep bubbles readable.
  static const solids = [
    Color(0xFFFFFFFF),
    Color(0xFFF2F2F7),
    Color(0xFFDCEBFF),
    Color(0xFFD9F2F5),
    Color(0xFFDDF3E4),
    Color(0xFFF4F1D6),
    Color(0xFFFCE7D2),
    Color(0xFFFADCE2),
    Color(0xFFEBDDF6),
    Color(0xFFE2E0FB),
    Color(0xFF1C1C1E),
    Color(0xFF0F1B2D),
  ];

  /// 움직이는 색 배경 (tips 281 + 284): four colours that turn a little each
  /// time I send. Our own soft sets (bright; no dark green).
  static const gradients = [
    ('sky', [Color(0xFFBFE3FF), Color(0xFFD9D2FF), Color(0xFFC6F1F0), Color(0xFFE7F4FF)]),
    ('peach', [Color(0xFFFFD3B8), Color(0xFFFFC2D4), Color(0xFFFFE8B8), Color(0xFFFFDCC8)]),
    ('mint', [Color(0xFFC6F2DD), Color(0xFFD8F5C4), Color(0xFFBFE9F2), Color(0xFFE6F8E9)]),
    ('lilac', [Color(0xFFE3D1FF), Color(0xFFFFD1EC), Color(0xFFCFD8FF), Color(0xFFF2E3FF)]),
    ('sunset', [Color(0xFFFFB8A8), Color(0xFFFFD39A), Color(0xFFF7A8C8), Color(0xFFFFC9B0)]),
    ('night', [Color(0xFF1E2A4A), Color(0xFF2B1F45), Color(0xFF123A44), Color(0xFF1C2238)]),
  ];

  static String gradSpec(String id, {String pattern = ''}) {
    final g = gradients.where((x) => x.$1 == id).firstOrNull ?? gradients.first;
    return Wall(kind: 'grad', colors: g.$2, pattern: pattern, strength: 0.35).encode();
  }
}

/// Icon sets drawn over a background, on a profile cover or inside reply
/// quotes (iOS-style icons from the app, so nothing is downloaded).
class Patterns {
  const Patterns._();

  /// The icon set ids (drawn by ui/look_studio.dart `patternIcons`).
  static const sets = {'hearts': 0, 'stars': 1, 'music': 2, 'paws': 3, 'weather': 4, 'travel': 5, 'games': 6, 'nature': 7};

  /// In picker order.
  static const ids = ['hearts', 'stars', 'music', 'paws', 'weather', 'travel', 'games', 'nature'];
}

// --------------------------------------------------------- made themes

/// A theme I made or got by link (tip 173 / 226): a name, the accent and a
/// chat background. The night look comes by itself (dark bars, the same
/// background dimmed).
class MyTheme {
  const MyTheme({required this.id, required this.name, required this.accent, required this.wall});
  final String id;
  final String name;
  final Color accent;

  /// A [Wall] text (never a photo: themes can be shared).
  final String wall;

  Map<String, dynamic> toJson() => {'i': id, 'n': name, 'a': hexOf(accent), 'w': wall};

  static MyTheme? fromJson(Object? j) {
    if (j is! Map) return null;
    final n = '${j['n'] ?? ''}'.trim();
    final w = '${j['w'] ?? ''}';
    final a = hexColor('${j['a'] ?? ''}', const Color(0x00000000));
    if (n.isEmpty || n.length > 40 || a.a == 0 || !Wall.sendable(w)) return null;
    final id = '${j['i'] ?? ''}';
    return MyTheme(id: id.isEmpty ? 't${DateTime.now().microsecondsSinceEpoch}' : id, name: n, accent: brightEnough(a), wall: w);
  }

  static const pref = 'my_themes';

  static List<MyTheme> listFrom(String json) {
    try {
      final j = jsonDecode(json);
      if (j is! List) return const [];
      return [for (final x in j) ?MyTheme.fromJson(x)];
    } catch (_) {
      return const [];
    }
  }

  static String listTo(List<MyTheme> all) => jsonEncode([for (final t in all) t.toJson()]);

  // ---- links: https://<host>/theme#t=<base64url of {n, a, w}> ----

  static String get host => Brand.linkHost;

  String link() {
    final body = base64Url.encode(utf8.encode(jsonEncode({'n': name, 'a': hexOf(accent), 'w': wall}))).replaceAll('=', '');
    return 'https://$host/theme#t=$body';
  }

  static RegExp get _linkRe => RegExp('(?:https?://)?${RegExp.escape(host)}/theme#t=([A-Za-z0-9_-]+)');

  /// [text] without its theme link (the card shows the theme instead).
  static String withoutLink(String text) => text.replaceAll(_linkRe, '').trim();

  /// A theme link anywhere in [text], or null.
  static MyTheme? parseLink(String text) {
    final m = _linkRe.firstMatch(text);
    if (m == null) return null;
    try {
      var b = m.group(1)!;
      if (b.length > 600) return null;
      b += '=' * ((4 - b.length % 4) % 4);
      final j = jsonDecode(utf8.decode(base64Url.decode(b)));
      if (j is! Map) return null;
      return MyTheme.fromJson({...j, 'i': 'l${b.hashCode.toUnsigned(32)}'});
    } catch (_) {
      return null;
    }
  }
}

// ------------------------------------------------- name + profile look

/// My look as others see it (tip 402 + 409): name colour (one or two
/// stripes), icons in my reply quotes, profile cover colour (one or two)
/// and icons on my profile cover. Colours are NameColors keys.
class PersonLook {
  const PersonLook({this.name = const [], this.reply = '', this.cover = const [], this.coverIcons = ''});
  final List<String> name;
  final String reply;
  final List<String> cover;
  final String coverIcons;

  static const keys = ['red', 'orange', 'yellow', 'green', 'teal', 'blue', 'purple', 'pink'];

  /// Two-stripe name colours offered after the single ones.
  static const combos = [
    ['red', 'orange'],
    ['orange', 'yellow'],
    ['green', 'teal'],
    ['teal', 'blue'],
    ['blue', 'purple'],
    ['purple', 'pink'],
    ['pink', 'orange'],
  ];

  bool get isEmpty => name.isEmpty && reply.isEmpty && cover.isEmpty && coverIcons.isEmpty;

  /// `red+orange|hearts|purple+pink|stars`; the old one-word name colour
  /// (`red`) still reads.
  static PersonLook parse(String s) {
    if (s.length > 80) return const PersonLook();
    final p = s.split('|');
    List<String> cols(String x) => [
      for (final k in x.split('+').take(2))
        if (keys.contains(k)) k,
    ];
    String icons(String x) => Patterns.sets.containsKey(x) ? x : '';
    return PersonLook(
      name: cols(p[0]),
      reply: p.length > 1 ? icons(p[1]) : '',
      cover: p.length > 2 ? cols(p[2]) : const [],
      coverIcons: p.length > 3 ? icons(p[3]) : '',
    );
  }

  String encode() {
    if (isEmpty) return '';
    final out = [name.join('+'), reply, cover.join('+'), coverIcons];
    while (out.length > 1 && out.last.isEmpty) {
      out.removeLast();
    }
    return out.join('|');
  }

  PersonLook copyWith({List<String>? name, String? reply, List<String>? cover, String? coverIcons}) =>
      PersonLook(name: name ?? this.name, reply: reply ?? this.reply, cover: cover ?? this.cover, coverIcons: coverIcons ?? this.coverIcons);

  /// The hidden note kind that carries my look to 1:1 chats.
  static const signalKind = 'my_look';

  /// Where a person's look from a 1:1 note is kept on this phone.
  static String prefOf(String userId) => 'look_of:$userId';
}

// ------------------------------------------------ group / channel look

/// 채널·그룹 꾸미기 (tip 412 + 429): admins pick it, every member sees it.
/// Kept as the room setting [cfgKey].
class RoomLook {
  const RoomLook({this.cover = const [], this.logo = '', this.emoji = '', this.wall = '', this.name = ''});

  /// Cover colour(s) behind the photo on the info page (NameColors keys).
  final List<String> cover;

  /// Icons on the cover ([Patterns] id).
  final String logo;

  /// 상태 이모지 next to the room's name.
  final String emoji;

  /// Background for every member (a [Wall] text; never a photo).
  final String wall;

  /// A channel's name / reply colour (NameColors key).
  final String name;

  static const cfgKey = 'look';

  /// Emoji offered as the room's status.
  static const emojis = ['📚', '☕️', '🏃', '🎮', '🎵', '🌿', '⭐️', '🔥', '💼', '🍰', '⚽️', '✈️'];

  bool get isEmpty => cover.isEmpty && logo.isEmpty && emoji.isEmpty && wall.isEmpty && name.isEmpty;

  static RoomLook from(Map<String, dynamic> cfg) {
    final j = cfg[cfgKey];
    if (j is! Map) return const RoomLook();
    final cover = [
      for (final k in '${j['c'] ?? ''}'.split('+').take(2))
        if (PersonLook.keys.contains(k)) k,
    ];
    final logo = Patterns.sets.containsKey(j['l']) ? '${j['l']}' : '';
    final e = '${j['e'] ?? ''}';
    final w = '${j['w'] ?? ''}';
    final n = '${j['n'] ?? ''}';
    return RoomLook(cover: cover, logo: logo, emoji: e.runes.length <= 8 ? e : '', wall: Wall.sendable(w) ? w : '', name: PersonLook.keys.contains(n) ? n : '');
  }

  Map<String, dynamic>? toJson() => isEmpty
      ? null
      : {
          if (cover.isNotEmpty) 'c': cover.join('+'),
          if (logo.isNotEmpty) 'l': logo,
          if (emoji.isNotEmpty) 'e': emoji,
          if (wall.isNotEmpty) 'w': wall,
          if (name.isNotEmpty) 'n': name,
        };

  RoomLook copyWith({List<String>? cover, String? logo, String? emoji, String? wall, String? name}) =>
      RoomLook(cover: cover ?? this.cover, logo: logo ?? this.logo, emoji: emoji ?? this.emoji, wall: wall ?? this.wall, name: name ?? this.name);

  /// Community level that opens each part (stage A levels, room_tools):
  /// cover colour at 1, icons + status at 2, background for all at 3.
  static const coverLevel = 1, logoLevel = 2, emojiLevel = 2, wallLevel = 3;
}
