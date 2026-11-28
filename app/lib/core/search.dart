// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 전체 검색 (Telegram tips 500 · 189 · 248 · 533 · 444) and 해시태그
// (454 · 484 · 459). What can be looked up where:
//
// - My chats and their messages, photos, links, files, music and voice
//   messages: on this phone only, over messages it already opened. The
//   words never leave the phone, and hidden chats / hidden messages are
//   never looked at (engine/src/search.rs).
// - Public groups and channels: the server's public list (only rooms their
//   admins made public). Nothing about my own chats goes with the words.
// - Public posts: only posts of public channels whose owner turned on the
//   channel web page (already readable by anyone on the web). The words go
//   in the request body, never in a link, and are not kept.
import 'backend.dart';

/// One hit of the search: which chat and which message.
class Found {
  const Found(this.roomId, this.msg);
  final String roomId;
  final Msg msg;
}

/// A post on a public channel's web page (공개 글).
class PublicPost {
  const PublicPost({required this.address, required this.name, required this.text, required this.time, this.members = 0, this.channel = true, this.photo});
  final String address;
  final String name;
  final String text;
  final DateTime time;
  final int members;
  final bool channel;

  /// Path of its photo on the link host (/ch-media/...), if any.
  final String? photo;
}

/// Kinds the engine can look for (tabs of the search screen).
const searchKinds = ['text', 'media', 'link', 'file', 'music', 'voice'];

const _musicExt = ['.mp3', '.m4a', '.aac', '.wav', '.ogg', '.flac', '.opus'];
final _anyLink = RegExp(r'https?://');

bool isMusic(Msg m) {
  final name = (m.body ?? '').toLowerCase();
  return switch (m.kind) {
    'audio' => m.voice == null,
    'file' => _musicExt.any(name.endsWith),
    _ => false,
  };
}

/// Same rule as the engine (engine/src/search.rs `search_hit`), used by the
/// look-only demo and tests.
bool searchHit(Msg m, String kind, String term) {
  final t = term.trim().toLowerCase();
  if (m.body == null || m.viewOnce || m.bubble) return false;
  bool has(String? s) => s != null && s.toLowerCase().contains(t);
  bool words() => t.isEmpty || has(m.body) || has(m.caption) || (m.preview != null && has(m.preview!.title));
  return switch (kind) {
    'text' => t.isNotEmpty && const ['text', 'file', 'image', 'video', 'audio'].contains(m.kind) && (has(m.body) || has(m.caption)),
    'media' => (m.kind == 'image' || m.kind == 'video') && words(),
    'link' => m.kind == 'text' && _anyLink.hasMatch(m.body ?? '') && words(),
    'file' => m.kind == 'file' && !isMusic(m) && words(),
    'music' => isMusic(m) && words(),
    'voice' => m.kind == 'audio' && m.voice != null && (t.isEmpty || has(m.caption)),
    _ => false,
  };
}

/// Words shown with a message in results (caption, else the body).
String searchText(Msg m) => (m.caption?.isNotEmpty ?? false) ? m.caption! : (m.body ?? '');

// ---- 메시지 필터 (tip 500): 모든 대화 / 1:1 / 그룹 / 채널 ----

const searchScopes = ['all', 'direct', 'group', 'channel'];

bool inScope(ChatPreview? c, String scope) => switch (scope) {
  'direct' => c != null && c.isDirect,
  'group' => c != null && !c.isDirect && !c.isChannel,
  'channel' => c != null && c.isChannel,
  _ => true,
};

// ---- 해시태그 (#여행, #travel@adventures) ----

/// A tag in a text: `#word`, or `#word@address` (that public chat only).
class Hashtag {
  const Hashtag(this.start, this.end, this.tag, this.address);
  final int start;
  final int end;

  /// Without '#', as written (case kept).
  final String tag;

  /// The public address after '@', lower case, or null.
  final String? address;

  /// The text as written: "#travel" or "#travel@adventures".
  String get text => address == null ? '#$tag' : '#$tag@$address';
}

// Letters (any language), digits and '_'; not right after a letter, digit,
// '/', '#' or '&' (so URLs, "C#" and "&#39;" are left alone); at least one
// letter, at most 64 long.
final _tag = RegExp(r'(?<![\p{L}\p{N}_/#&])#([\p{L}\p{N}_]{1,64})(?:@([A-Za-z][A-Za-z0-9_]{4,31}))?(?![\p{L}\p{N}_])', unicode: true);
final _hasLetter = RegExp(r'\p{L}', unicode: true);

List<Hashtag> findHashtags(String s) => [
  for (final m in _tag.allMatches(s))
    if (_hasLetter.hasMatch(m.group(1)!)) Hashtag(m.start, m.end, m.group(1)!, m.group(2)?.toLowerCase()),
];

/// Does [text] carry this tag (case does not matter; "#travel@adventures"
/// counts for #travel too)?
bool hasHashtag(String text, String tag) {
  final t = tag.toLowerCase();
  return findHashtags(text).any((h) => h.tag.toLowerCase() == t);
}

/// "#travel@adventures" → ("travel", "adventures"); "#여행" → ("여행", null).
(String, String?) parseHashtag(String s) {
  final h = findHashtags(s.trim().startsWith('#') ? s.trim() : '#${s.trim()}');
  if (h.isEmpty) return (s.trim().replaceFirst('#', ''), null);
  return (h.first.tag, h.first.address);
}

// ---- 날짜 칩 (tip 189): "10월" → 2026년 10월 / 2025년 10월 ----

/// A date range offered under the search ("10월" → this year's and last
/// year's October; "2025" → that whole year).
class DateChip {
  const DateChip(this.from, this.to, this.month);
  final DateTime from;

  /// Exclusive end.
  final DateTime to;

  /// A month (else a whole year).
  final bool month;

  bool has(DateTime t) => !t.isBefore(from) && t.isBefore(to);

  String get id => month ? '${from.year}-${from.month}' : '${from.year}';
}

const _months = [
  ['january', 'jan'],
  ['february', 'feb'],
  ['march', 'mar'],
  ['april', 'apr'],
  ['may'],
  ['june', 'jun'],
  ['july', 'jul'],
  ['august', 'aug'],
  ['september', 'sep', 'sept'],
  ['october', 'oct'],
  ['november', 'nov'],
  ['december', 'dec'],
];

/// The date word in [query] (if any) as chips, newest first, and the rest
/// of the words (what is still searched for once a chip is picked).
(List<DateChip>, String) dateChips(String query, DateTime now) {
  final words = query.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  for (var i = 0; i < words.length; i++) {
    final w = words[i].toLowerCase();
    final rest = [...words]..removeAt(i);
    int? month;
    int? year;
    final ko = RegExp(r'^(\d{1,2})월$').firstMatch(w);
    if (ko != null) month = int.parse(ko.group(1)!);
    for (var m = 0; m < 12 && month == null; m++) {
      // At least 3 letters, so "ma" doesn't offer March and May.
      if (w.length >= 3 && _months[m].any((n) => n.startsWith(w) || w == n)) month = m + 1;
    }
    final y = RegExp(r'^(20\d\d|19\d\d)(년)?$').firstMatch(w);
    if (y != null) year = int.parse(y.group(1)!);
    if (month != null && (month < 1 || month > 12)) month = null;
    if (month == null && year == null) continue;
    // "10월 2025" / "2025년 10월": one exact chip.
    if (month != null && year == null && rest.isNotEmpty) {
      final y2 = RegExp(r'^(20\d\d|19\d\d)(년)?$').firstMatch(rest.first.toLowerCase());
      if (y2 != null) {
        year = int.parse(y2.group(1)!);
        rest.removeAt(0);
      }
    }
    if (year != null && month == null && i + 1 < words.length) {
      final m2 = RegExp(r'^(\d{1,2})월$').firstMatch(words[i + 1]);
      if (m2 != null && int.parse(m2.group(1)!) <= 12 && int.parse(m2.group(1)!) >= 1) {
        month = int.parse(m2.group(1)!);
        rest.remove(words[i + 1]);
      }
    }
    final left = rest.join(' ');
    if (month != null && year != null) return ([DateChip(DateTime(year, month), DateTime(year, month + 1), true)], left);
    if (year != null) return ([DateChip(DateTime(year), DateTime(year + 1), false)], left);
    // A month alone: the last 3 times it came round (not the future).
    final chips = <DateChip>[];
    var yy = month! > now.month ? now.year - 1 : now.year;
    for (var k = 0; k < 3; k++, yy--) {
      chips.add(DateChip(DateTime(yy, month), DateTime(yy, month + 1), true));
    }
    return (chips, left);
  }
  return (const [], query.trim());
}

// ---- 최근 검색 (kept on this phone) ----

const recentSearchPref = 'search_recent';

List<String> recentSearches(String saved) => saved.split('\n').where((s) => s.isNotEmpty).toList();

/// [item] first, at most 20 kept. Items: `chat:<roomId>` or `tag:<#tag>`.
String addRecentSearch(String saved, String item) => [item, ...recentSearches(saved).where((s) => s != item)].take(20).join('\n');

/// Where each match of [term] sits in [text] (for colouring), case not minded.
List<(int, int)> matchRanges(String text, String term) {
  final t = term.trim().toLowerCase();
  if (t.isEmpty) return const [];
  final low = text.toLowerCase();
  final out = <(int, int)>[];
  var at = low.indexOf(t);
  while (at >= 0 && out.length < 20) {
    out.add((at, at + t.length));
    at = low.indexOf(t, at + t.length);
  }
  return out;
}

/// The part of a long [text] around the first match, so the match shows in
/// a 2-line preview ("…the start of the match onwards").
String aroundMatch(String text, String term, {int before = 24}) {
  final flat = text.replaceAll('\n', ' ');
  final r = matchRanges(flat, term);
  if (r.isEmpty || r.first.$1 <= before) return flat;
  var from = r.first.$1 - before;
  final space = flat.indexOf(' ', from);
  if (space > 0 && space < r.first.$1) from = space + 1;
  return '…${flat.substring(from)}';
}
