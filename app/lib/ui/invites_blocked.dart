// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Invite-blocked people get the link instead (Telegram tip 385). Someone
// whose "그룹·채널 초대" setting takes only contacts turns my invitation
// down on their phone with a fixed mark; the group info then shows
// "초대를 막은 사람 N명", and this sheet sends them the invite link in a
// 1:1 chat so they can decide for themselves.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show SelectCircle;
import 'common.dart';
import 'invite_links.dart' show roomLinkText;
import 'message_sheets.dart' show GlassSheet;
import 'wide.dart';

/// People already sent the link (this phone), so the row stops asking.
List<String> linkSentTo(AppState s, String roomId) => s.pref('invlink_sent:$roomId', '').split(',').where((x) => x.isNotEmpty).toList();

/// Blocked people still waiting for a link from me.
Future<List<String>> blockedWaiting(AppState s, String roomId) async {
  final all = await s.backend.invitesBlocked(roomId).catchError((_) => const <String>[]);
  final sent = linkSentTo(s, roomId);
  return [
    for (final u in all)
      if (!sent.contains(u)) u,
  ];
}

/// Returns how many got the link (0 = none sent), or -1 when no link
/// could be made.
Future<int> showInvitesBlocked(
  BuildContext context, {
  required String roomId,
  required String name,
  required bool channel,
  required List<String> people,
}) async {
  final n = await showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (_) => InvitesBlockedSheet(roomId: roomId, name: name, channel: channel, people: people),
  );
  return n ?? 0;
}

class InvitesBlockedSheet extends StatefulWidget {
  const InvitesBlockedSheet({super.key, required this.roomId, required this.name, required this.channel, required this.people});
  final String roomId;
  final String name;
  final bool channel;
  final List<String> people;

  @override
  State<InvitesBlockedSheet> createState() => _InvitesBlockedSheetState();
}

class _InvitesBlockedSheetState extends State<InvitesBlockedSheet> {
  late final picked = {...widget.people};
  bool busy = false;

  Future<void> send() async {
    if (picked.isEmpty || busy) return;
    setState(() => busy = true);
    final s = AppScope.read(context);
    final b = s.backend;
    var link = await b.roomLink(widget.roomId).catchError((_) => const RoomLink());
    if (link.kind == 'none') {
      try {
        link = await b.newPrivateLink(widget.roomId);
      } catch (_) {
        if (mounted) Navigator.pop(context, -1);
        return;
      }
    }
    final text = roomLinkText(link, name: widget.name, channel: widget.channel);
    final done = <String>[];
    for (final u in picked) {
      try {
        final dm = await b.createDirectChat(u);
        await b.sendText(dm, text);
        done.add(u);
      } catch (_) {}
    }
    await s.setPref('invlink_sent:${widget.roomId}', {...linkSentTo(s, widget.roomId), ...done}.join(','));
    if (mounted) Navigator.pop(context, done.length);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GlassSheet(
      key: const Key('invites-blocked'),
      title: l.invitesBlockedTitle(widget.people.length),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[2]),
          child: Text(
            l.invitesBlockedInfo,
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final u in widget.people)
                GestureDetector(
                  key: Key('blocked-$u'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => picked.contains(u) ? picked.remove(u) : picked.add(u)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                    child: Row(
                      children: [
                        SelectCircle(on: picked.contains(u)),
                        SizedBox(width: Tokens.space[2]),
                        Avatar(name: displayId(u).substring(1), size: Tokens.memberAvatar, userId: u),
                        SizedBox(width: Tokens.space[2]),
                        Expanded(
                          child: Text(displayId(u), style: Tokens.body.style.copyWith(color: p.label)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[3]),
          child: GestureDetector(
            key: const Key('send-invite-link'),
            onTap: send,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: picked.isEmpty ? p.accent.withValues(alpha: 0.4) : p.accent,
                borderRadius: BorderRadius.circular(Tokens.capsule),
              ),
              child: Center(
                child: busy
                    ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                    : Text(
                        l.sendInviteLinkN(picked.length),
                        style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
