// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// New chat: new group, new channel, a contact, or anyone by ID.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'ios_route.dart';
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
      final room = await s.makeChat(() => s.backend.createDirectChat(userId));
      await s.refresh();
      if (mounted) openCreated(context, room, title);
    } catch (_) {
      if (mounted) setState(() => busy = false);
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
                CupertinoListTile(
                  key: const Key('new-group'),
                  leading: iconTile(Palette.tileBlue, CupertinoIcons.person_2_fill),
                  title: Text(l.newGroup),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => group(channel: false),
                ),
                CupertinoListTile(
                  key: const Key('new-channel'),
                  leading: iconTile(Palette.tileOrange, CupertinoIcons.speaker_2_fill),
                  title: Text(l.newChannel),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => group(channel: true),
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
              ],
            ),
            if (contacts.isNotEmpty)
              IosSection(
                header: sectionHeader(context, l.contactsSection),
                children: [
                  for (final c in contacts)
                    CupertinoListTile(
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
  const MembersPage({super.key, required this.contacts});
  final List<Person> contacts;
  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final picked = <String>{};

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
          onPressed: () => Navigator.of(context).push(IosPageRoute(builder: (_) => NameChatPage(channel: false, members: picked.toList()))),
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
                        CupertinoListTile(
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

  Future<void> create() async {
    final n = name.text.trim();
    if (n.isEmpty || busy) return;
    setState(() => busy = true);
    final s = AppScope.of(context);
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
              footer: sectionFooter(context, widget.channel ? l.channelInfo : l.groupInfo),
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
