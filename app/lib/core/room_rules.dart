// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Group / channel rules from v1 (parity batch 2, 2026-11-27), kept in the
// room settings so every member's phone applies them the same way:
// - 관리자 권한: each admin gets their own rights (owner picks).
// - 멤버 권한: what plain members may send (text, photos, stickers...).
// - 슬로 모드: members wait between messages.
// - 기간 메시지 금지: the server stops them (level -1); the time is kept
//   here so an admin's phone lifts it when it runs out.
// - 멤버 태그: a short word next to a name.
// - 방장 넘기기: 1/3/7 days as joint owners, then the old owner finishes.
// - @멘션 and @모두 (33+ members: admins only).
import 'backend.dart';

class RoomRules {
  const RoomRules._();

  // ---- 관리자 권한 -----------------------------------------------------

  /// Rights an admin can have, in the order the owner sees them.
  static const rights = ['info', 'delete', 'ban', 'invite', 'pin', 'mute', 'add_admin'];

  /// A new admin gets everything but adding admins (like Telegram).
  static const defaultRights = ['info', 'delete', 'ban', 'invite', 'pin', 'mute'];

  static List<String> rightsOf(Map<String, dynamic> cfg, String userId) {
    final all = cfg['admin_rights'];
    if (all is Map && all[userId] is List) return [for (final r in all[userId] as List) '$r'];
    return defaultRights;
  }

  /// [role] is the person's role here (owner / admin / member / muted).
  static bool can(Map<String, dynamic> cfg, String role, String userId, String right) {
    if (role == 'owner') return true;
    if (role != 'admin') return false;
    return rightsOf(cfg, userId).contains(right);
  }

  static Map<String, dynamic> withRights(Map<String, dynamic> cfg, String userId, List<String>? list) {
    final all = <String, dynamic>{...(cfg['admin_rights'] as Map? ?? const {})};
    list == null
        ? all.remove(userId)
        : all[userId] = [
            for (final r in rights)
              if (list.contains(r)) r,
          ];
    return all;
  }

  // ---- 멤버 권한 -------------------------------------------------------

  /// What plain members may do (all on unless switched off).
  static const memberPerms = ['text', 'media', 'sticker', 'poll', 'link', 'invite', 'pin', 'info'];

  /// 380 (chat safety): "미디어 보내기" split by kind, like Telegram.
  static const mediaKinds = ['photo', 'video', 'file', 'music', 'voice', 'videonote', 'sticker', 'poll', 'link'];

  /// Kinds that the old single 'media' switch covered.
  static const oldMediaKinds = {'photo', 'video', 'file', 'music', 'voice', 'videonote'};

  /// The full list with media split (text, 9 media kinds, then the rest).
  static const memberPermsSplit = ['text', ...mediaKinds, 'invite', 'pin', 'info'];

  static bool memberMay(Map<String, dynamic> cfg, String perm, {String? userId}) {
    // 예외: one member set differently by an admin.
    final ex = cfg['perm_users'];
    if (userId != null && ex is Map && ex[userId] is Map) {
      final v = (ex[userId] as Map)[perm];
      if (v is bool) return v;
    }
    final p = cfg['member_perms'];
    if (p is! Map) return true;
    if (p[perm] == false) return false;
    if (oldMediaKinds.contains(perm) && p[perm] == null && p['media'] == false) return false;
    // 'media' asked as a whole (old screens): any kind still on counts.
    if (perm == 'media' && p['media'] == null) return oldMediaKinds.any((k) => p[k] != false);
    return true;
  }

  /// Admins and the owner are never limited.
  static bool may(Map<String, dynamic> cfg, String role, String perm, {String? userId}) =>
      role == 'owner' || role == 'admin' || memberMay(cfg, perm, userId: userId);

  /// The room's 'member_perms' value for the switches that are on (null =
  /// all on). Writes each kind; the old 'media' key goes away.
  static Map<String, dynamic>? permsValue(Iterable<String> on) {
    final off = {
      for (final k in memberPermsSplit)
        if (!on.contains(k)) k: false,
    };
    return off.isEmpty ? null : off;
  }

  /// 'perm_users' after setting one member's own switches (null = back to
  /// the room's). Only what differs from the room is kept.
  static Map<String, dynamic> withException(Map<String, dynamic> cfg, String userId, Set<String>? on) {
    final all = <String, dynamic>{...(cfg['perm_users'] as Map? ?? const {})};
    all.remove(userId);
    if (on != null) {
      final diff = <String, bool>{
        for (final k in memberPermsSplit)
          if (on.contains(k) != memberMay(cfg, k)) k: on.contains(k),
      };
      if (diff.isNotEmpty) all[userId] = diff;
    }
    return all;
  }

  /// The kind a picked file is sent as, for the switches above.
  static String kindOfFile(String name, {bool asFile = false}) {
    final ext = name.split('.').last.toLowerCase();
    if (asFile) return 'file';
    if (name.startsWith('videonote')) return 'videonote';
    if (const ['jpg', 'jpeg', 'png', 'heic', 'gif', 'webp'].contains(ext)) return 'photo';
    if (const ['mp4', 'mov', 'm4v', 'webm'].contains(ext)) return 'video';
    if (const ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus'].contains(ext)) return 'music';
    return 'file';
  }

  // ---- 야간 모드 (v1) -------------------------------------------------

  /// Quiet hours for members, in the room's own clock (the admin's time
  /// zone when it was set). Admins can always write.
  static const nightChoices = ['off', '22-7', '23-7', '0-6', '1-8'];

  static String nightValue(Map<String, dynamic> cfg) {
    final n = cfg['night'];
    if (n is! Map || n['from'] is! int || n['to'] is! int) return 'off';
    return '${n['from']}-${n['to']}';
  }

  static Map<String, dynamic>? nightConfig(String value, Duration tz) {
    if (value == 'off') return null;
    final p = value.split('-').map(int.parse).toList();
    return {'from': p[0], 'to': p[1], 'tz': tz.inMinutes};
  }

  /// The hour members may write again, or null when it isn't quiet time.
  static int? nightUntil(Map<String, dynamic> cfg, String role, DateTime now) {
    if (role == 'owner' || role == 'admin') return null;
    final n = cfg['night'];
    if (n is! Map || n['from'] is! int || n['to'] is! int) return null;
    final from = n['from'] as int, to = n['to'] as int;
    final tz = n['tz'] is int ? n['tz'] as int : 0;
    final h = now.toUtc().add(Duration(minutes: tz)).hour;
    final quiet = from <= to ? (h >= from && h < to) : (h >= from || h < to);
    return quiet ? to : null;
  }

  // ---- 슬로 모드 -------------------------------------------------------

  static const slowChoices = [0, 10, 30, 60, 300, 900, 3600];

  static int slowSeconds(Map<String, dynamic> cfg) {
    final v = cfg['slow'];
    return v is int && v > 0 ? v : 0;
  }

  /// How long I still have to wait (null = I can send now).
  static Duration? slowWait(Map<String, dynamic> cfg, String role, DateTime? lastSent, DateTime now) {
    final s = slowSeconds(cfg);
    if (s == 0 || lastSent == null || role == 'owner' || role == 'admin') return null;
    final left = lastSent.add(Duration(seconds: s)).difference(now);
    return left > Duration.zero ? left : null;
  }

  // ---- 기간 메시지 금지 -----------------------------------------------

  /// 1 hour, 1 day, 7 days, and 0 = until lifted.
  static const muteChoices = [3600, 86400, 604800, 0];

  /// "그룹 안 1:1 막기": members of this group can't start 1:1 chats with each
  /// other (admins still can). The server enforces it on the invite.
  static bool noMemberDm(Map<String, dynamic> cfg) => cfg['no_member_dm'] == true;

  /// Words the server uses when it refuses such an invite.
  static bool isDmBlocked(Object error) => error.toString().contains('does not allow 1:1');

  /// My mute is over: the server lifts it on my next message, so I may write.
  static bool muteOver(Map<String, dynamic> cfg, String userId, DateTime now) {
    final until = muteUntil(cfg, userId);
    return until != null && !until.isAfter(now);
  }

  /// When their mute ends; null = not muted here. Forever = year 9999.
  static DateTime? muteUntil(Map<String, dynamic> cfg, String userId) {
    final m = cfg['mutes'];
    if (m is! Map || m[userId] is! int) return null;
    final at = m[userId] as int;
    return at == 0 ? DateTime(9999) : DateTime.fromMillisecondsSinceEpoch(at);
  }

  static Map<String, dynamic> withMute(Map<String, dynamic> cfg, String userId, DateTime? until, {bool forever = false}) {
    final all = <String, dynamic>{...(cfg['mutes'] as Map? ?? const {})};
    if (until == null && !forever) {
      all.remove(userId);
    } else {
      all[userId] = forever ? 0 : until!.millisecondsSinceEpoch;
    }
    return all;
  }

  /// Mutes whose time ran out (an admin's phone lifts them).
  static List<String> expiredMutes(Map<String, dynamic> cfg, DateTime now) {
    final m = cfg['mutes'];
    if (m is! Map) return const [];
    return [
      for (final e in m.entries)
        if (e.value is int && e.value != 0 && now.millisecondsSinceEpoch >= (e.value as int)) '${e.key}',
    ];
  }

  // ---- 멤버 태그 -------------------------------------------------------

  static const tagMax = 16;

  static String tagOf(Map<String, dynamic> cfg, String userId) {
    final t = cfg['tags'];
    return t is Map && t[userId] is String ? t[userId] as String : '';
  }

  static Map<String, dynamic> withTag(Map<String, dynamic> cfg, String userId, String tag) {
    final all = <String, dynamic>{...(cfg['tags'] as Map? ?? const {})};
    final t = tag.trim();
    t.isEmpty ? all.remove(userId) : all[userId] = t.characters16();
    return all;
  }

  // ---- 방장 넘기기 -----------------------------------------------------

  static const handoverDays = [1, 3, 7];

  /// (who gets it, when the old owner may finish) or null.
  static (String, DateTime)? handover(Map<String, dynamic> cfg) {
    final h = cfg['handover'];
    if (h is! Map || h['to'] is! String || h['until'] is! int) return null;
    return (h['to'] as String, DateTime.fromMillisecondsSinceEpoch(h['until'] as int));
  }

  // ---- 고정 기간 -----------------------------------------------------

  /// A day, a week, a month, or 0 = until unpinned.
  static const pinChoices = [86400, 604800, 2592000, 0];

  static Map<String, dynamic> withPinUntil(Map<String, dynamic> cfg, String msgId, DateTime? until) {
    final all = <String, dynamic>{...(cfg['pin_until'] as Map? ?? const {})};
    until == null ? all.remove(msgId) : all[msgId] = until.millisecondsSinceEpoch;
    return all;
  }

  /// Pins whose time ran out are not shown (and get unpinned by a phone
  /// that may do it).
  static List<String> livePins(List<String> pins, Map<String, dynamic> cfg, DateTime now) {
    final u = cfg['pin_until'];
    if (u is! Map) return pins;
    return [
      for (final p in pins)
        if (u[p] is! int || (u[p] as int) > now.millisecondsSinceEpoch) p,
    ];
  }

  static List<String> expiredPins(Map<String, dynamic> cfg, DateTime now) {
    final u = cfg['pin_until'];
    if (u is! Map) return const [];
    return [
      for (final e in u.entries)
        if (e.value is int && (e.value as int) <= now.millisecondsSinceEpoch) '${e.key}',
    ];
  }

  // ---- @멘션 -----------------------------------------------------------

  /// "@모두" / "@all" reaches everyone; 33+ members: admins only.
  static const everyone = ['@\uBAA8\uB450', '@all']; // @모두
  static const everyoneOpenUpTo = 32;

  static bool mayMentionAll(String role, int memberCount) => memberCount <= everyoneOpenUpTo || role == 'owner' || role == 'admin';

  static bool hasEveryone(String text) => everyone.any((e) => RegExp('${RegExp.escape(e)}(?![\\w\uAC00-\uD7A3])').hasMatch(text));

  /// Does this text mention me? By my name ("@민지"), my ID ("@minji") or
  /// "@모두".
  static bool mentionsMe(String text, String myId, String myName) {
    if (!text.contains('@')) return false;
    if (hasEveryone(text)) return true;
    final local = myId.startsWith('@') ? myId.substring(1).split(':').first : myId;
    final names = {local, if (myName.trim().isNotEmpty) myName.trim()};
    for (final n in names) {
      if (RegExp('@${RegExp.escape(n)}(?![\\w\uAC00-\uD7A3])', caseSensitive: false).hasMatch(text)) return true;
    }
    return false;
  }

  /// The word being typed after "@" at the cursor, or null.
  static String? mentionQuery(String text, int cursor) {
    if (cursor < 0 || cursor > text.length) return null;
    final before = text.substring(0, cursor);
    final m = RegExp(r'(^|\s)@([\w\uAC00-\uD7A3.]*)$').firstMatch(before);
    return m?.group(2);
  }

  /// Members matching what was typed after "@" (not me).
  static List<Member> mentionMatches(List<Member> members, String query, String me) {
    final q = query.toLowerCase();
    return [
      for (final m in members)
        if (m.userId != me && (m.name.toLowerCase().contains(q) || m.userId.toLowerCase().contains(q))) m,
    ];
  }
}

extension on String {
  /// At most [RoomRules.tagMax] characters (by code point).
  String characters16() => runes.length <= RoomRules.tagMax ? this : String.fromCharCodes(runes.take(RoomRules.tagMax));
}
