// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 협박 공격 막기 (2026-11-26, 대표 승인): the phone's rules against
// "hide an illegal picture in an old message, report the app, blackmail the
// owner". The server refuses late edits and edits by others; the rules here
// are the app's side (menus, what is shown, the owner's alerts).
import 'automod.dart';
import 'backend.dart';

/// Groups and channels: a message can be edited this long after sending
/// (same as the server). 1:1 chats have no limit.
const editWindow = Duration(hours: 24);

/// An edit of a message older than this tells the owner and admins.
const lateEditAfter = Duration(hours: 1);

bool editWindowOpen({required bool group, required DateTime sent, required DateTime now}) => !group || now.difference(sent) <= editWindow;

/// Messages someone (not me, not an admin) changed long after sending, so
/// that nobody scrolling the chat would notice. Newest change first.
List<Msg> lateEdits(List<Msg> msgs, Set<String> admins) {
  final out = [
    for (final m in msgs)
      if (m.edited && m.editedAt != null && !m.mine && !admins.contains(m.sender) && m.editedAt!.difference(m.time) > lateEditAfter) m,
  ];
  out.sort((a, b) => b.editedAt!.compareTo(a.editedAt!));
  return out;
}

/// "새 멤버 사진·영상·링크 제한": days after joining (0 = off). Public rooms
/// get 7 days unless the owner changed it (the engine fills that in).
int newMediaDays(Map<String, dynamic> cfg) {
  final v = cfg['new_media_days'];
  return v is int && v > 0 && v <= 30 ? v : 0;
}

// Built-in stickers are ours and safe; "내 스티커" are any picture, so they
// travel as photos and count here.
const _mediaKinds = {'image', 'video', 'file', 'audio'};

/// Whether [m] is something the new-member limit covers: a photo, video,
/// file, or words with a link.
bool limitedKind(Msg m) => _mediaKinds.contains(m.kind) || (m.kind == 'text' && hasLinkText(m.body ?? '')) || hasLinkText(m.caption ?? '');

/// Someone who joined less than [days] before [at] (and isn't an admin).
/// Unknown join time counts as new (stricter is safer).
bool isNewMember(Member? who, int days, DateTime at) {
  if (days <= 0) return false;
  if (who == null) return true;
  if (who.role == 'owner' || who.role == 'admin') return false;
  final since = who.since;
  if (since == null) return true;
  return at.difference(since) < Duration(days: days);
}

/// Hidden from everyone but admins: a new member's photo / video / link
/// sent while the limit is on.
bool hideForNewMember(Msg m, Member? sender, int days, {DateTime? now}) {
  if (m.mine || days <= 0 || !limitedKind(m)) return false;
  // Someone no longer here (join time unknown): hidden while the message is
  // still inside the limit, so "join, post, leave" doesn't get around it.
  if (sender == null) return (now ?? DateTime.now()).difference(m.time) < Duration(days: days);
  return isNewMember(sender, days, m.time);
}

/// When I may send photos, videos and links here (null = now).
DateTime? myMediaFrom(Member? me, int days, {DateTime? now}) {
  if (days <= 0 || me == null || me.role != 'member' || me.since == null) return null;
  final t = me.since!.add(Duration(days: days));
  return t.isAfter(now ?? DateTime.now()) ? t : null;
}
