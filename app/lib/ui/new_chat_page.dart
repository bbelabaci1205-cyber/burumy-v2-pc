// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// New chat: new group, new channel, a contact, or anyone by ID.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'trust_ui.dart';
import 'chat_page.dart';
import 'common.dart';
import 'invite_links.dart';
import 'ios.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'room_rules_pages.dart';
import 'wide.dart';

/// Closes the new-chat screens and opens the chat in their place.
void openCreated(BuildContext context, String roomId, String title) {
  if (Wide.on) {
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    Wide.show(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: roomId, title: title),
      ),
      roomId: roomId,
    );
    return;
  }
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    IosPageRoute(
      builder: (_) => ChatPage(roomId: roomId, title: title),
    ),
    (r) => r.isFirst,
  );
}

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});
  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  final id = TextEditingController();

  /// 아이디 키 the other person gave me (only for their first chat).
  final key = TextEditingController();
  List<Person> contacts = const [];
  bool busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).backend.contacts().then((c) {
      if (mounted) setState(() => contacts = c);
    });
  }

  Future<void> direct(String userId, String title) async {
    if (userId.isEmpty || busy) return;
    setState(() => busy = true);
    final s = AppScope.of(context);
    try {
      final k = key.text.trim();
      final room = await s.makeChat(() => s.backend.createDirectChat(userId, idKey: k));
      await s.refresh();
      if (mounted) openCreated(context, room, title);
    } catch (e) {
      if (mounted) setState(() => busy = false);
      if (mounted) await explainDmBlocked(context, e);
    }
  }

  Future<void> group({required bool channel}) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => channel ? const NameChatPage(channel: true, members: []) : MembersPage(contacts: contacts),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.newChat),
        backgroundColor: p.background,
        border: null,
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        trailing: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => direct(id.text.trim(), id.text.trim()), child: Text(l.start)),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              children: [
                IosTile(
                  key: const Key('new-group'),
                  leading: iconTile(Palette.tileBlue, CupertinoIcons.person_2_fill),
                  title: Text(l.newGroup),
                  trailing: const IosChevron(),
                  onTap: () => group(channel: false),
                ),
                IosTile(
                  key: const Key('new-channel'),
                  leading: iconTile(Palette.tileOrange, CupertinoIcons.speaker_2_fill),
                  title: Text(l.newChannel),
                  trailing: const IosChevron(),
                  onTap: () => group(channel: true),
                ),
                IosTile(
                  key: const Key('new-by-link'),
                  leading: iconTile(Palette.tileIndigo, CupertinoIcons.link),
                  title: Text(l.joinByLink),
                  trailing: const IosChevron(),
                  onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const JoinByLinkPage())),
                ),
              ],
            ),
            IosSection(
              header: sectionHeader(context, l.orById),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  child: CupertinoTextField(
                    key: const Key('new-chat-id'),
                    controller: id,
                    placeholder: l.newChatHint,
                    autocorrect: false,
                    decoration: null,
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                    onSubmitted: (v) => direct(v.trim(), v.trim()),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  child: CupertinoTextField(
                    key: const Key('new-chat-key'),
                    controller: key,
                    placeholder: l.idKeyEnterHint,
                    autocorrect: false,
                    decoration: null,
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                    onSubmitted: (_) => direct(id.text.trim(), id.text.trim()),
                  ),
                ),
              ],
              footer: sectionFooter(context, l.idKeyEnterInfo),
            ),
            if (contacts.isNotEmpty)
              IosSection(
                header: sectionHeader(context, l.contactsSection),
                children: [
                  for (final c in contacts)
                    IosTile(
                      leading: Avatar(name: c.name, size: 30),
                      title: Text(c.name),
                      subtitle: Text(displayId(c.userId), style: Tokens.caption.style),
                      onTap: () => direct(c.userId, c.name),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Step 1 of a new group: tick the people to add (none is fine).
class MembersPage extends StatefulWidget {
  const MembersPage({super.key, required this.contacts, this.picked = const {}});
  final List<Person> contacts;

  /// Ticked when the page opens ("이 멤버로 새 그룹" starts with everyone).
  final Set<String> picked;
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  late final picked = {...widget.picked};

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(l.addMembers),
        backgroundColor: p.background,
        border: null,
        trailing: CupertinoButton(
          key: const Key('members-next'),
          padding: EdgeInsets.zero,
          onPressed: picked.isEmpty && widget.picked.isNotEmpty
              ? null
              : () => Navigator.of(context).push(IosPageRoute(builder: (_) => NameChatPage(channel: false, members: picked.toList()))),
          child: Text(l.next),
        ),
      ),
      child: SafeArea(
        child: widget.contacts.isEmpty
            ? Center(
                child: Text(l.contactsEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              )
            : ListView(
                children: [
                  IosSection(
                    children: [
                      for (final c in widget.contacts)
                        IosTile(
                          key: Key('pick-${c.userId}'),
                          leading: Avatar(name: c.name, size: 30),
                          title: Text(c.name),
                          subtitle: Text(displayId(c.userId), style: Tokens.caption.style),
                          trailing: Icon(
                            picked.contains(c.userId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: picked.contains(c.userId) ? p.accent : p.secondaryLabel,
                          ),
                          onTap: () => setState(() => picked.contains(c.userId) ? picked.remove(c.userId) : picked.add(c.userId)),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Last step: the name, then create.
class NameChatPage extends StatefulWidget {
  const NameChatPage({super.key, required this.channel, required this.members});
  final bool channel;
  final List<String> members;
  @override
  State<NameChatPage> createState() => _NameChatPageState();
}

class _NameChatPageState extends State<NameChatPage> {
  final name = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> create() async {
    final n = name.text.trim();
    if (n.isEmpty || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    final s = AppScope.of(context);
    // Channel titles can't take a name held for its real owner (the server
    // checks again; private groups among friends are free).
    if (widget.channel) {
      var why = '';
      try {
        why = await s.backend.nameCheck(n, room: true);
      } catch (_) {}
      if (!mounted) return;
      if (why.isNotEmpty) {
        return setState(() {
          busy = false;
          error = nameRefusal(L.of(context), why);
        });
      }
    }
    try {
      final room = await s.makeChat(() => s.backend.createGroup(n, widget.members, channel: widget.channel));
      await s.refresh();
      if (mounted) openCreated(context, room, n);
    } catch (_) {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(widget.channel ? l.newChannel : l.newGroup),
        backgroundColor: p.background,
        border: null,
        trailing: busy
            ? const CupertinoActivityIndicator()
            : CupertinoButton(key: const Key('create-chat'), padding: EdgeInsets.zero, onPressed: create, child: Text(l.create)),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              footer: error != null
                  ? Text(
                      error!,
                      key: const Key('chat-name-error'),
                      style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                    )
                  : sectionFooter(context, widget.channel ? l.channelInfo : l.groupInfo),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  child: CupertinoTextField(
                    key: const Key('chat-name'),
                    controller: name,
                    autofocus: true,
                    placeholder: widget.channel ? l.channelName : l.groupName,
                    decoration: null,
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                    onSubmitted: (_) => create(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
