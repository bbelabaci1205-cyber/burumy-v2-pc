// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch #16 (groups, 2026-11-27): the rules behind
// - 94  익명 관리자: an admin's messages show the group's name and photo.
// - 556 멤버 태그: members may put their own tag next to their name.
// - 365 강력 스팸 차단: admins' phones remove spam (the server can't read).
// - 384 누가 읽었는지: in groups of up to 100, who read my message and when.
// Everything here is plain logic so it can be tested without a server.
import 'dart:convert';

import 'automod.dart' show hasLinkText;
import 'backend.dart';

// ---- 94 익명 관리자 ---------------------------------------------------------

/// cfg 'anon': per admin, the times they were anonymous ([from, to] ms; to
/// 0 = still on). A message counts as anonymous when it was sent inside one
/// of those times, so turning it off later never unmasks old messages, and a
/// plain member can't fake it (only admins can change the room setting).
class AnonAdmins {
  const AnonAdmins._();

  /// Periods kept per person (oldest dropped first).
  static const maxPeriods = 20;

  static List<(int, int)> periods(Map<String, dynamic> cfg, String userId) {
    final all = cfg['anon'];
    if (all is! Map || all[userId] is! List) return const [];
    return [
      for (final p in all[userId] as List)
        if (p is List && p.length == 2 && p[0] is int && p[1] is int) (p[0] as int, p[1] as int),
    ];
  }

  /// Anonymous right now.
  static bool isOn(Map<String, dynamic> cfg, String userId) => periods(cfg, userId).any((p) => p.$2 == 0);

  /// People anonymous right now.
  static Set<String> current(Map<String, dynamic> cfg) {
    final all = cfg['anon'];
    if (all is! Map) return const {};
    return {
      for (final k in all.keys)
        if (isOn(cfg, '$k')) '$k',
    };
  }

  /// Was [userId] anonymous when [m] was sent?
  static bool sentAnon(Map<String, dynamic> cfg, Msg m) {
    final t = m.time.millisecondsSinceEpoch;
    return periods(cfg, m.sender).any((p) => t >= p.$1 && (p.$2 == 0 || t < p.$2));
  }

  /// The 'anon' value after switching [userId] on or off at [now].
  static Map<String, dynamic> withAnon(Map<String, dynamic> cfg, String userId, bool on, DateTime now) {
    final all = <String, dynamic>{...(cfg['anon'] as Map? ?? const {})};
    final list = [...periods(cfg, userId)];
    final ms = now.millisecondsSinceEpoch;
    final open = list.indexWhere((p) => p.$2 == 0);
    if (on && open < 0) list.add((ms, 0));
    // A period that never had time in it is dropped (on and off at once).
    if (!on && open >= 0) {
      if (list[open].$1 >= ms) {
        list.removeAt(open);
      } else {
        list[open] = (list[open].$1, ms);
      }
    }
    final kept = list.length > maxPeriods ? list.sublist(list.length - maxPeriods) : list;
    kept.isEmpty
        ? all.remove(userId)
        : all[userId] = [
            for (final p in kept) [p.$1, p.$2],
          ];
    return all;
  }

  /// Members as others see them: anonymous admins are left out (admins
  /// still see everyone, with an "익명" mark).
  static List<Member> visible(List<Member> members, Map<String, dynamic> cfg, {required bool viewerIsAdmin, required String me}) {
    if (viewerIsAdmin) return members;
    final hidden = current(cfg);
    return [
      for (final m in members)
        if (m.userId == me || !hidden.contains(m.userId)) m,
    ];
  }
}

// ---- 556 멤버 태그 -------------------------------------------------------

/// A tag next to someone's name, and whether an admin gave it (admins'
/// tags and tags an admin gave keep the old look; own tags are grey).
class ShownTag {
  const ShownTag(this.text, {required this.byAdmin});
  final String text;
  final bool byAdmin;
}

class MemberTags {
  const MemberTags._();

  /// Members may tag themselves (Telegram's "Edit Own Tags", off at first).
  static bool ownAllowed(Map<String, dynamic> cfg) => cfg['own_tags'] == true;

  /// The tag shown for [userId]: one an admin gave wins; else their own when
  /// the room allows it.
  static ShownTag? of(Map<String, dynamic> cfg, Map<String, String> own, String userId) {
    final t = cfg['tags'];
    if (t is Map && t[userId] is String && (t[userId] as String).trim().isNotEmpty) return ShownTag(t[userId] as String, byAdmin: true);
    final o = (own[userId] ?? '').trim();
    if (o.isNotEmpty && ownAllowed(cfg)) return ShownTag(o, byAdmin: false);
    return null;
  }

  /// I may change my own tag: the room allows it and no admin set one.
  static bool canEditOwn(Map<String, dynamic> cfg, String role, String me) {
    final t = cfg['tags'];
    final fixed = t is Map && t[me] is String;
    return !fixed && (ownAllowed(cfg) || role == 'owner' || role == 'admin');
  }
}

// ---- 384 누가 읽었는지 -----------------------------------------------------

/// Read times in a group, kept on this phone (pref `readlog_g:ROOM`): the
/// server only keeps each person's newest receipt, so every new one is
/// written down as [read up to, when] and a message's time is the first
/// receipt that covers it. Kept for 7 days, like Telegram.
class GroupReads {
  const GroupReads._();

  static const maxMembers = 100;
  static const keep = Duration(days: 7);
  static const perPerson = 60;

  static Map<String, List<(int, int)>> parse(String raw) {
    try {
      final v = jsonDecode(raw);
      if (v is! Map) return {};
      return {
        for (final e in v.entries)
          if (e.value is List)
            '${e.key}': [
              for (final x in e.value as List)
                if (x is List && x.length == 2 && x[0] is int && x[1] is int) (x[0] as int, x[1] as int),
            ],
      };
    } catch (_) {
      return {};
    }
  }

  /// The log with the newest receipts added, or null when nothing changed.
  static String? add(String raw, Map<String, (DateTime, DateTime)> receipts, DateTime now) {
    final log = parse(raw);
    final cut = now.subtract(keep).millisecondsSinceEpoch;
    var changed = false;
    for (final e in receipts.entries) {
      final u = e.value.$1.millisecondsSinceEpoch, a = e.value.$2.millisecondsSinceEpoch;
      final list = log[e.key] ?? [];
      if (list.isNotEmpty && list.last.$1 >= u) continue;
      final kept = [
        for (final x in list)
          if (x.$2 >= cut) x,
        (u, a),
      ];
      log[e.key] = kept.length > perPerson ? kept.sublist(kept.length - perPerson) : kept;
      changed = true;
    }
    if (!changed) return null;
    return jsonEncode({
      for (final e in log.entries)
        if (e.value.isNotEmpty)
          e.key: [
            for (final x in e.value) [x.$1, x.$2],
          ],
    });
  }

  /// Who read my message sent at [sent] and when, newest first. [receipts]
  /// fills in people the log missed (their first receipt is the time).
  static List<(String, DateTime)> readers(String raw, Map<String, (DateTime, DateTime)> receipts, DateTime sent, DateTime now) {
    final log = parse(raw);
    final s = sent.millisecondsSinceEpoch;
    final out = <String, DateTime>{};
    for (final e in log.entries) {
      for (final x in e.value) {
        if (x.$1 >= s) {
          out[e.key] = DateTime.fromMillisecondsSinceEpoch(x.$2);
          break;
        }
      }
    }
    for (final e in receipts.entries) {
      if (out.containsKey(e.key) || e.value.$1.isBefore(sent)) continue;
      out[e.key] = e.value.$2;
    }
    final list = [
      for (final e in out.entries)
        if (now.difference(e.value) <= keep) (e.key, e.value.isBefore(sent) ? sent : e.value),
    ];
    list.sort((a, b) => b.$2.compareTo(a.$2));
    return list;
  }
}

// ---- 365 강력 스팸 차단 ----------------------------------------------------

/// Why a message looked like spam (several reasons can add up).
enum SpamWhy { words, link, contact, repeat, mentions, newcomer, shouting }

class AntiSpam {
  const AntiSpam._();

  static bool on(Map<String, dynamic> cfg) => cfg['antispam'] == true;

  /// People an admin said "스팸 아님" for: never checked again here.
  static Set<String> trusted(Map<String, dynamic> cfg) => {for (final x in cfg['spam_ok'] as List? ?? const []) '$x'};

  static List<String> withTrusted(Map<String, dynamic> cfg, String userId) => {...trusted(cfg), userId}.toList();

  /// Words typical of spam in Korean groups (gambling, loans, "reading
  /// rooms", adult ads, moving people to other apps) and in English ones.
  static const words = [
    '카지노', '바카라', '토토', '슬롯', '먹튀', '도박', '홀덤', '대출', '급전', '무담보', '신용불량', //
    '리딩방', '코인리딩', '수익보장', '원금보장', '고수익', '수익인증', '재택부업', '부업모집', '고액알바', '일당지급',
    '텔레문의', '텔레그램문의', '카톡문의', '오픈채팅', '라인문의', '조건만남', '출장안마', '성인방', '19금',
    '팔로워구매', '무료코인', '에어드랍', '투자상담', '선착순지급', '무료나눔이벤트',
    'casino', 'betting', 'cryptosignal', 'guaranteedprofit', 'investmentopportunity', 'airdrop', 'freecrypto',
    'dmme', 'contactmeon', 'workfromhome', 'onlyfans', 'adultcontent', 'loanoffer',
  ];

  /// Points from which a message is removed.
  static const limit = 3;

  /// Members newer than this get one more point when they post links.
  static const newFor = Duration(days: 3);

  static String _squeeze(String t) => t.toLowerCase().replaceAll(RegExp(r'[\s.\-_*·,!~/|]+'), '');

  static final _phone = RegExp(r'(\+?\d[\d\s\-]{8,}\d)');
  static final _handle = RegExp(r'(@[a-zA-Z][\w]{4,}|t\.me/|wa\.me/|open\.kakao\.com|line\.me/|discord\.gg/)');

  /// Reasons this message looks like spam; empty = fine. [repeats] = how
  /// many messages in the recent chat have exactly the same words.
  static List<SpamWhy> reasons(Msg m, {required bool newcomer, required int repeats}) {
    final text = '${m.body ?? ''} ${m.caption ?? ''}';
    if (text.trim().isEmpty || m.kind == 'sticker') return const [];
    final out = <SpamWhy>[];
    final sq = _squeeze(text);
    final hits = words.where((w) => sq.contains(w)).length;
    if (hits > 0) out.addAll(hits > 1 ? const [SpamWhy.words, SpamWhy.words] : const [SpamWhy.words]);
    final link = hasLinkText(text);
    if (link) out.add(SpamWhy.link);
    if (_handle.hasMatch(text) || _phone.hasMatch(text)) out.add(SpamWhy.contact);
    if (repeats >= 3) out.addAll(const [SpamWhy.repeat, SpamWhy.repeat]);
    if ('@'.allMatches(text).length >= 6) out.addAll(const [SpamWhy.mentions, SpamWhy.mentions]);
    if (newcomer && (link || out.contains(SpamWhy.contact) || hits > 0)) out.add(SpamWhy.newcomer);
    final letters = text.replaceAll(RegExp(r'[^A-Za-z]'), '');
    final emoji = RegExp(r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]', unicode: true).allMatches(text).length;
    if ((letters.length >= 20 && letters == letters.toUpperCase()) || emoji >= 10) out.add(SpamWhy.shouting);
    return out;
  }

  static bool isSpam(List<SpamWhy> r) => r.length >= limit;

  /// The messages to remove, oldest first: never mine, an admin's, or from
  /// someone marked "스팸 아님".
  static List<(Msg, List<SpamWhy>)> find(
    List<Msg> msgs, {
    required Set<String> admins,
    required Set<String> trusted,
    required Map<String, DateTime?> joined,
    required DateTime now,
  }) {
    final same = <String, int>{};
    for (final m in msgs) {
      final t = _squeeze('${m.body ?? ''}${m.caption ?? ''}');
      if (t.length >= 8) same[t] = (same[t] ?? 0) + 1;
    }
    final out = <(Msg, List<SpamWhy>)>[];
    for (final m in msgs) {
      if (m.mine || admins.contains(m.sender) || trusted.contains(m.sender) || m.body == null) continue;
      if (!const ['text', 'image', 'video', 'file', 'audio'].contains(m.kind)) continue;
      final j = joined[m.sender];
      final newcomer = j == null || now.difference(j) < newFor;
      final r = reasons(m, newcomer: newcomer, repeats: same[_squeeze('${m.body ?? ''}${m.caption ?? ''}')] ?? 0);
      if (isSpam(r)) out.add((m, r));
    }
    return out;
  }

  /// Someone whose spam was removed this many times in a day can't write
  /// for a day (기간 메시지 금지).
  static const strikes = 3;

  /// Mod-log detail for a removed spam message: who, then a short piece of
  /// what it said (kept on this admin's phone only).
  static String detail(Msg m) {
    final t = '${m.body ?? ''} ${m.caption ?? ''}'.trim().replaceAll('\n', ' ');
    return '${m.sender}\n${t.length > 80 ? '${t.substring(0, 80)}…' : t}';
  }

  static (String, String) splitDetail(String d) {
    final i = d.indexOf('\n');
    return i < 0 ? (d, '') : (d.substring(0, i), d.substring(i + 1));
  }
}
