// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Invite link text (manual 1-4, 6-7):
//   public   https://<host>/c/<address>
//   private  https://<host>/join#k=<code>&t=g|c&n=<name>
//   web page https://<host>/ch/<address>
// A private link keeps its code (and the name shown to the person who gets
// it) after '#', so the code never reaches a web server or its logs.
import 'dart:convert';

import 'package:flutter/widgets.dart' show StringCharacters;

import '../brand/brand.dart';

class LinkTarget {
  const LinkTarget({required this.kind, required this.code, this.name = '', this.channel = false});

  /// "public" or "private".
  final String kind;
  final String code;

  /// Private links only: the name the sender's phone put in the link.
  final String name;
  final bool channel;
}

class RoomLinks {
  const RoomLinks._();

  static String get host => Brand.linkHost;

  static String public(String address) => 'https://$host/c/$address';

  static String private(String code, {String name = '', bool channel = false}) {
    final n = name.trim().isEmpty ? '' : '&n=${shortName(name.trim())}';
    return 'https://$host/join#k=$code&t=${channel ? 'c' : 'g'}$n';
  }

  static String web(String address) => 'https://$host/ch/$address';

  /// Short text shown in the app (no https://).
  static String shown(String link) => link.replaceFirst(RegExp(r'^https?://'), '');

  /// Our link inside any text, or null. Takes with or without https://.
  static LinkTarget? parse(String text) {
    final t = text.trim();
    final h = RegExp.escape(host);
    final pub = RegExp('(?:https?://)?$h/c/([A-Za-z][A-Za-z0-9_]{4,31})\\b').firstMatch(t);
    if (pub != null) return LinkTarget(kind: 'public', code: pub.group(1)!.toLowerCase());
    final priv = RegExp('(?:https?://)?$h/join#(\\S+)').firstMatch(t);
    if (priv != null) {
      final q = Uri.splitQueryString(priv.group(1)!);
      final code = (q['k'] ?? '').toLowerCase();
      if (!RegExp(r'^[a-z2-9]{26}$').hasMatch(code)) return null;
      return LinkTarget(kind: 'private', code: code, name: (q['n'] ?? '').trim(), channel: q['t'] == 'c');
    }
    return null;
  }
}

/// The name, cut so the link still fits a QR code: at most 96 characters
/// once encoded (about 10 Korean letters or 90 English ones).
String shortName(String name) {
  var out = '';
  for (final r in name.runes) {
    final next = Uri.encodeComponent(String.fromCharCodes([...out.isEmpty ? <int>[] : Uri.decodeComponent(out).runes, r]));
    if (next.length > 96) break;
    out = next;
  }
  return out;
}

/// A link to one message (Telegram tip 302): https://<host>/m#r=<room>&e=<event>.
/// Everything after '#' stays on the phone (never reaches a web server),
/// and only members of the chat can open it: the app looks the chat up
/// among my own chats.
class MessageLink {
  const MessageLink(this.roomId, this.eventId);
  final String roomId;
  final String eventId;

  String get url => 'https://${RoomLinks.host}/m#r=${Uri.encodeComponent(roomId)}&e=${Uri.encodeComponent(eventId)}';

  static MessageLink? parse(String text) {
    final h = RegExp.escape(RoomLinks.host);
    final m = RegExp('(?:https?://)?$h/m#(\\S+)').firstMatch(text.trim());
    if (m == null) return null;
    final Map<String, String> q;
    try {
      q = Uri.splitQueryString(m.group(1)!);
    } catch (_) {
      return null;
    }
    final r = q['r'] ?? '', e = q['e'] ?? '';
    if (!r.startsWith('!') || e.isEmpty || r.length > 255 || e.length > 255) return null;
    return MessageLink(r, e);
  }
}

/// One extra invite link of a group or channel (Telegram tip 253). Each has
/// its own code; our server refuses it after [until] or once [max] people
/// came in, and counts every join ([uses], [joined]).
class InviteLink {
  const InviteLink({
    required this.code,
    this.name = '',
    this.until,
    this.max = 0,
    this.uses = 0,
    this.joined = const [],
    this.by = '',
    required this.made,
    this.revoked = false,
  });

  final String code;

  /// Only admins see it ("인스타 프로필", "친구용").
  final String name;

  /// Ends at; null = no end.
  final DateTime? until;

  /// People limit; 0 = no limit.
  final int max;
  final int uses;

  /// Who came in through it, newest last (the server keeps the last 100).
  final List<String> joined;
  final String by;
  final DateTime made;

  /// Cancelled (취소됨): it no longer opens.
  final bool revoked;

  /// "live", "soon" (ends within a day, or one more seat left / 10% left),
  /// "ended", "full" or "revoked".
  String state(DateTime now) {
    if (revoked) return 'revoked';
    final u = until;
    if (u != null && !now.isBefore(u)) return 'ended';
    if (max > 0 && uses >= max) return 'full';
    return left(now) <= .25 || (u != null && u.difference(now) < const Duration(days: 1)) ? 'soon' : 'live';
  }

  /// How much is left, 1 (all) to 0 (none): the smaller of time left and
  /// seats left. The ring around the link icon shrinks like a clock.
  double left(DateTime now) {
    var f = 1.0;
    final u = until;
    if (u != null) {
      final all = u.difference(made).inMilliseconds;
      f = all <= 0 ? 0 : (u.difference(now).inMilliseconds / all).clamp(0.0, 1.0);
    }
    if (max > 0) f = f < 1 - uses / max ? f : (1 - uses / max).clamp(0.0, 1.0);
    return f;
  }

  bool usable(DateTime now) => const {'live', 'soon'}.contains(state(now));

  String link({String roomName = '', bool channel = false}) => RoomLinks.private(code, name: roomName, channel: channel);

  InviteLink copyWith({String? name, DateTime? until, bool clearUntil = false, int? max, int? uses, List<String>? joined, bool? revoked}) => InviteLink(
    code: code,
    name: name ?? this.name,
    until: clearUntil ? null : (until ?? this.until),
    max: max ?? this.max,
    uses: uses ?? this.uses,
    joined: joined ?? this.joined,
    by: by,
    made: made,
    revoked: revoked ?? this.revoked,
  );
}

/// Why our server turned a link down: "ended", "full", "revoked" or null.
String? linkRefusal(Object error) {
  final t = error.toString();
  if (t.contains('link expired')) return 'ended';
  if (t.contains('link full')) return 'full';
  if (t.contains('link revoked')) return 'revoked';
  return null;
}

/// 대화 링크 (Telegram tip 438): a link that opens a 1:1 chat with me with
/// words already in the composer, e.g. https://<host>/dm#u=@eric:burumy.app&m=…
/// Everything sits after '#', so no web server ever sees who it is for or
/// what it says; the other person's phone reads it. It may also carry my
/// 아이디 키 (k) when I choose, so strangers can start the chat.
/// Nobody counts clicks: that would need a server to watch them.
class ChatLink {
  const ChatLink({required this.userId, this.text = '', this.key = ''});
  final String userId;
  final String text;
  final String key;

  /// Longest ready message (keeps the link short enough to paste anywhere).
  static const maxText = 500;

  String get url {
    final q = [
      'u=${Uri.encodeComponent(userId)}',
      if (text.trim().isNotEmpty) 'm=${Uri.encodeComponent(text.trim())}',
      if (key.isNotEmpty) 'k=${Uri.encodeComponent(key)}',
    ];
    return 'https://${RoomLinks.host}/dm#${q.join('&')}';
  }

  static ChatLink? parse(String raw) {
    final h = RegExp.escape(RoomLinks.host);
    final m = RegExp('(?:https?://)?$h/dm#(\\S+)').firstMatch(raw.trim());
    if (m == null) return null;
    final Map<String, String> q;
    try {
      q = Uri.splitQueryString(m.group(1)!);
    } catch (_) {
      return null;
    }
    final u = q['u'] ?? '';
    if (!RegExp(r'^@[a-z0-9._=\-/+]+:[A-Za-z0-9.\-:\[\]]+$').hasMatch(u) || u.length > 255) return null;
    final t = q['m'] ?? '';
    return ChatLink(userId: u, text: t.characters.take(maxText).toString(), key: (q['k'] ?? '').characters.take(20).toString());
  }
}

/// One of my saved 대화 링크 (kept on this phone only: setting `chat_links`).
class MyChatLink {
  const MyChatLink({required this.id, this.name = '', this.text = '', this.withKey = false});
  final String id;

  /// Only I see it ("가게 문의", "행사 신청").
  final String name;
  final String text;

  /// Put my 아이디 키 in the link.
  final bool withKey;

  Map<String, Object> toJson() => {'id': id, 'n': name, 't': text, 'k': withKey};

  static MyChatLink fromJson(Map<String, dynamic> j) =>
      MyChatLink(id: '${j['id'] ?? ''}', name: '${j['n'] ?? ''}', text: '${j['t'] ?? ''}', withKey: j['k'] == true);

  static List<MyChatLink> listFrom(String pref) {
    try {
      return [for (final j in jsonDecode(pref) as List) MyChatLink.fromJson((j as Map).cast<String, dynamic>())];
    } catch (_) {
      return const [];
    }
  }

  static String listTo(List<MyChatLink> l) => jsonEncode([for (final x in l) x.toJson()]);

  ChatLink link(String me, {String key = ''}) => ChatLink(userId: me, text: text, key: withKey ? key : '');
}
