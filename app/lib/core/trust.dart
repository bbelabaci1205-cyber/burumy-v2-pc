// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Impersonation guard (사칭 막기), the phone's side.
//
// The trust service publishes one small public list: official badges and
// '확인 중' / '가짜' labels. Every phone downloads the whole list and checks
// people against it here, so nobody learns whose profile someone opened.
// The look-alike rules are the same as server/trust/src/names.rs (the
// shared cases in test/trust_test.dart keep them in step).

import 'package:crypto/crypto.dart' show sha256;

/// 514: a short fingerprint of my profile photo for the trust service, so
/// it can tell "사진 바뀜 N일 전" without ever getting the photo.
String photoPrint(List<int>? bytes) => bytes == null || bytes.isEmpty ? 'none' : sha256.convert(bytes).toString().substring(0, 16);

/// Words only our own accounts may use in an ID or name.
const ourWords = ['admin', 'official', 'burumy', 'support', '공식', '부루미', '운영자', '관리자', '고객센터'];

/// Words people add around a famous name ("haneul_official", "진짜하늘").
const _affixes = ['official', 'real', 'the', 'kr', 'korea', 'tv', 'fan', '공식', '진짜', '본인', '계정'];

const _l = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
const _v = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ';
const _t = 'ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ';
const _gone = '.,_-·•\'"`~^*+=:;/\\()[]{}<>';

const _fold = {
  '0': 'o', 'ο': 'o', 'о': 'o', 'ө': 'o', //
  '1': 'l', 'i': 'l', '|': 'l', '!': 'l', 'ı': 'l', 'ℓ': 'l', 'ι': 'l', 'і': 'l', 'ӏ': 'l',
  '3': 'e', 'е': 'e', 'ё': 'e',
  '4': 'a', '@': 'a', 'а': 'a', 'α': 'a',
  '5': 's', r'$': 's', 'ѕ': 's',
  '7': 't', 'τ': 't',
  '8': 'b',
  'р': 'p', 'ρ': 'p',
  'с': 'c', 'ϲ': 'c',
  'у': 'y',
  'х': 'x', 'χ': 'x',
  'ј': 'j',
  'ԁ': 'd',
  'к': 'k', 'κ': 'k',
  'ν': 'v',
  'м': 'm',
};

bool _invisible(int c) =>
    c == 0x20 ||
    c == 0x09 ||
    c == 0x0A ||
    c == 0xA0 ||
    c == 0x3000 ||
    (c >= 0x2000 && c <= 0x200F) ||
    (c >= 0x0300 && c <= 0x036F) ||
    c == 0x2060 ||
    c == 0xFEFF ||
    c == 0xAD ||
    c == 0x3164 ||
    c == 0x115F ||
    c == 0x1160 ||
    _gone.contains(String.fromCharCode(c));

/// The look-alike skeleton of a name or ID: same skeleton = looks the same.
String skeleton(String s) {
  final out = StringBuffer();
  for (var c in s.toLowerCase().runes) {
    // Full-width letters (ａｂｃ) count as plain ones.
    if (c >= 0xFF01 && c <= 0xFF5E) c = String.fromCharCode(c - 0xFEE0).toLowerCase().runes.first;
    if (_invisible(c)) continue;
    if (c >= 0xAC00 && c <= 0xD7A3) {
      final n = c - 0xAC00;
      out
        ..write(_l[n ~/ 588])
        ..write(_v[(n % 588) ~/ 28]);
      if (n % 28 > 0) out.write(_t[n % 28 - 1]);
      continue;
    }
    final ch = String.fromCharCode(c);
    out.write(_fold[ch] ?? ch);
  }
  return out.toString().replaceAll('rn', 'm').replaceAll('vv', 'w');
}

/// The famous part: skeleton without numbers at the end and without words
/// like "official" / "공식" at either end.
String nameCore(String s) {
  var k = skeleton(s.replaceFirst(RegExp(r'[0-9]+$'), ''));
  final affixes = [for (final a in _affixes) skeleton(a)];
  while (true) {
    final before = k.length;
    for (final a in affixes) {
      if (k.length > a.length && k.endsWith(a)) k = k.substring(0, k.length - a.length);
      if (k.length > a.length && k.startsWith(a)) k = k.substring(a.length);
    }
    if (k.length == before) return k;
  }
}

/// Check marks people paste into names to look official.
bool hasBadgeMark(String s) => RegExp('[✓✔☑✅🔵🛡🎖🏅\u{1F5F8}]', unicode: true).hasMatch(s);

/// '' = fine, else "mark", "reserved" or "lookalike".
String checkName(String name, {String? who, List<String> reserved = const [], List<Badge> badges = const [], bool displayName = false}) {
  if (hasBadgeMark(name)) return 'mark';
  if (badges.any((b) => b.user == who && skeleton(b.name) == skeleton(name))) return '';
  final skel = skeleton(name);
  if (ourWords.any((w) => skel.contains(skeleton(w)))) return 'reserved';
  // Two people may share a display name; the one without the badge gets
  // "공식 계정이 아니에요" on the other side instead.
  if (displayName) return '';
  final c = nameCore(name);
  if (c.runes.length < 2) return '';
  for (final b in badges) {
    if (b.user == who) continue;
    final local = b.user.replaceFirst('@', '').split(':').first;
    if (nameCore(b.name) == c || nameCore(local) == c) return 'lookalike';
  }
  if (reserved.any((r) => nameCore(r) == c)) return 'reserved';
  return '';
}

class Badge {
  const Badge({required this.user, required this.name, this.kind = 'person'});
  final String user;

  /// The name that was checked; a different name hides the badge.
  final String name;

  /// person / brand / channel
  final String kind;
}

/// The public list (badges and labels).
class TrustList {
  const TrustList({this.version = 0, this.badges = const [], this.flags = const {}, this.hidden = const {}, this.guard = ''});
  final int version;
  final List<Badge> badges;

  /// user -> "checking" | "fake"
  final Map<String, String> flags;

  /// Messages hidden in every app after several reports as illegal (or by
  /// the operator). Only message ids: no room, no sender, no words.
  final Set<String> hidden;

  /// The operator's public-room guard account (empty when there is none).
  /// A room it is in is a public room it checks for illegal pictures and spam.
  final String guard;

  static const empty = TrustList();

  factory TrustList.fromJson(Map<String, dynamic> j) => TrustList(
    version: (j['v'] as num?)?.toInt() ?? 0,
    badges: [
      for (final b in (j['badges'] as List? ?? const []))
        if (b is Map && b['user'] is String && b['name'] is String)
          Badge(user: b['user'] as String, name: b['name'] as String, kind: (b['kind'] as String?) ?? 'person'),
    ],
    flags: {
      for (final f in (j['flags'] as List? ?? const []))
        if (f is Map && f['user'] is String && (f['state'] == 'checking' || f['state'] == 'fake')) f['user'] as String: f['state'] as String,
    },
    hidden: {
      for (final h in (j['hidden'] as List? ?? const []))
        if (h is String && h.startsWith(r'$') && h.length < 256) h,
    },
    guard: switch (j['guard']) {
      final String g when g.startsWith('@') && g.length < 256 => g,
      _ => '',
    },
  );

  Badge? badgeOf(String user) {
    for (final b in badges) {
      if (b.user == user) return b;
    }
    return null;
  }

  /// What to show next to someone whose name is [name] right now.
  Trust of(String user, String name) {
    final flag = flags[user] ?? '';
    final b = badgeOf(user);
    // A badge is for one name: renamed accounts lose it until checked again.
    if (b != null && skeleton(b.name) == skeleton(name)) return Trust(badge: b, flag: flag);
    // Someone else with a badge-holder's name (or a look-alike of it).
    Badge? copies;
    final c = nameCore(name), lc = nameCore(user.replaceFirst('@', '').split(':').first);
    for (final o in badges) {
      if (o.user == user) continue;
      final oc = nameCore(o.name);
      if (oc.runes.length >= 2 && (oc == c || oc == lc)) {
        copies = o;
        break;
      }
    }
    return Trust(flag: flag, looksLike: copies);
  }
}

class Trust {
  const Trust({this.badge, this.flag = '', this.looksLike});
  final Badge? badge;

  /// '', "checking" (reports came in) or "fake" (the operator confirmed).
  final String flag;

  /// The badge holder this account looks like (and isn't).
  final Badge? looksLike;

  bool get official => badge != null && flag != 'fake';
  bool get fake => flag == 'fake';
  bool get checking => flag == 'checking';
  bool get warn => fake || checking || looksLike != null;
}

/// Rough age and recent rename of an account, for the first-chat card.
class TrustAbout {
  const TrustAbout({this.age = 'unknown', this.renamed = false, this.renamedDays = -1, this.photoDays = -1});

  /// "week" (under 7 days), "month", "quarter" (1-3 months), "year",
  /// "older" or "unknown". Never a date (privacy).
  final String age;
  final bool renamed;

  /// 514: days since the name / profile photo changed; -1 = not within 30
  /// days (or unknown).
  final int renamedDays, photoDays;
}

/// Show the first-chat card? A 1:1 with someone who isn't my friend, that I
/// haven't answered and haven't accepted yet.
bool needsFirstContactCard({
  required bool isDirect,
  required String peer,
  required Set<String> friends,
  required bool accepted,
  required bool iWrote,
  bool bot = false,
}) => isDirect && peer.isNotEmpty && !bot && !friends.contains(peer) && !accepted && !iWrote;
