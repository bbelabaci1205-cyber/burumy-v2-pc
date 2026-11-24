// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat filters and folders, and the side menu that holds them (a full
// height card from the left that pushes the list aside).
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'settings_kit.dart';
import 'ios_route.dart';
import 'wide.dart';

/// A folder: a name, kinds of chats it takes, and chats added or left out
/// by hand. Kept in the on-device settings store.
class ChatFolder {
  ChatFolder({required this.id, required this.name, Set<String>? kinds, Set<String>? include, Set<String>? exclude})
    : kinds = kinds ?? {},
      include = include ?? {},
      exclude = exclude ?? {};
  final String id;
  String name;

  /// Any of: direct, group, channel, bot, unread.
  final Set<String> kinds;
  final Set<String> include;
  final Set<String> exclude;

  bool takes(ChatPreview c) {
    if (exclude.contains(c.roomId)) return false;
    if (include.contains(c.roomId)) return true;
    return kinds.any((k) => filterTakes(k, c));
  }

  Map<String, Object> toJson() => {'id': id, 'name': name, 'kinds': kinds.toList(), 'include': include.toList(), 'exclude': exclude.toList()};

  static ChatFolder fromJson(Map<String, dynamic> j) => ChatFolder(
    id: j['id'] as String,
    name: j['name'] as String,
    kinds: {...(j['kinds'] as List).cast<String>()},
    include: {...(j['include'] as List).cast<String>()},
    exclude: {...(j['exclude'] as List).cast<String>()},
  );
}

List<ChatFolder> foldersOf(AppState s) {
  try {
    return [for (final j in jsonDecode(s.pref('folders', '[]')) as List) ChatFolder.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

Future<void> saveFolders(AppState s, List<ChatFolder> f) => s.setPref('folders', f.isEmpty ? '' : jsonEncode([for (final x in f) x.toJson()]));

/// Built-in filters: all, unread, direct (people), group, channel, bot.
bool filterTakes(String f, ChatPreview c) => switch (f) {
  'unread' => c.unread > 0,
  'direct' => c.isDirect && !c.isBot,
  'group' => !c.isDirect && !c.isChannel,
  'channel' => c.isChannel,
  'bot' => c.isBot,
  _ => true,
};

String filterName(L l, String f) => switch (f) {
  'unread' => l.filterUnread,
  'direct' => l.filterPeople,
  'group' => l.filterGroups,
  'channel' => l.filterChannels,
  'bot' => l.filterBots,
  _ => l.filterAll,
};

/// Applies a filter id ('all', 'unread', ..., or 'folder:<id>').
bool takes(AppState s, String filter, ChatPreview c) {
  if (filter.startsWith('folder:')) {
    final f = foldersOf(s).where((x) => 'folder:${x.id}' == filter).firstOrNull;
    return f == null || f.takes(c);
  }
  return filterTakes(filter, c);
}

/// Title for the list when a filter is on.
String filterTitle(AppState s, L l, String filter) {
  if (filter.startsWith('folder:')) {
    return foldersOf(s).where((x) => 'folder:${x.id}' == filter).firstOrNull?.name ?? l.tabChats;
  }
  return filter == 'all' ? l.tabChats : filterName(l, filter);
}

/// The side menu: search, filters, my folders, new folder.
class SideMenu extends StatelessWidget {
  const SideMenu({super.key, required this.filter, required this.onPick, required this.onSearch});
  final String filter;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final chats = [
      for (final c in s.chats)
        if (!c.archived) c,
    ];
    int unreadIn(bool Function(ChatPreview) f) => chats.where((c) => f(c) && c.unread > 0 && !c.muted).length;
    Widget row(String id, String title, IconData icon, int count) {
      final on = filter == id;
      return GestureDetector(
        key: Key('filter-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onPick(id),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] + 2),
          decoration: BoxDecoration(
            color: on ? p.accent.withValues(alpha: 0.12) : const Color(0x00000000),
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
          ),
          child: Row(
            children: [
              Icon(icon, size: Tokens.listIcon, color: on ? p.accent : p.label),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: on ? p.accent : p.label),
                ),
              ),
              if (count > 0) Text('$count', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ],
          ),
        ),
      );
    }

    final folders = foldersOf(s);
    return Container(
      key: const Key('side-menu'),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(40)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24)],
      ),
      child: SafeArea(
        right: false,
        child: ListView(
          padding: EdgeInsets.only(top: Tokens.space[2], bottom: FloatingTabBar.room(context)),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              child: CupertinoSearchTextField(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                key: const Key('side-search'),
                placeholder: l.searchChats,
                onChanged: onSearch,
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            row('all', l.filterAll, CupertinoIcons.chat_bubble_2, unreadIn((_) => true)),
            row('unread', l.filterUnread, CupertinoIcons.envelope_badge, unreadIn((_) => true)),
            row('direct', l.filterPeople, CupertinoIcons.person, unreadIn((c) => filterTakes('direct', c))),
            row('group', l.filterGroups, CupertinoIcons.person_3, unreadIn((c) => filterTakes('group', c))),
            row('channel', l.filterChannels, CupertinoIcons.speaker_2, unreadIn((c) => filterTakes('channel', c))),
            row('bot', l.filterBots, CupertinoIcons.cube, unreadIn((c) => filterTakes('bot', c))),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[1]),
              child: Text(l.myFolders, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
            for (final f in folders)
              GestureDetector(
                onLongPress: () => paneNav(context).push(IosPageRoute(builder: (_) => FolderEditPage(folder: f))),
                child: row('folder:${f.id}', f.name, CupertinoIcons.folder, unreadIn(f.takes)),
              ),
            GestureDetector(
              key: const Key('new-folder'),
              behavior: HitTestBehavior.opaque,
              onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => const FolderEditPage())),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add, size: Tokens.listIcon, color: p.accent),
                    SizedBox(width: Tokens.space[2]),
                    Text(l.newFolder, style: Tokens.body.style.copyWith(color: p.accent)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Make or change a folder: name, kinds of chats, chats by hand.
class FolderEditPage extends StatefulWidget {
  const FolderEditPage({super.key, this.folder});
  final ChatFolder? folder;
  @override
  State<FolderEditPage> createState() => _FolderEditPageState();
}

class _FolderEditPageState extends State<FolderEditPage> {
  late final ChatFolder f = widget.folder == null
      ? ChatFolder(id: DateTime.now().microsecondsSinceEpoch.toRadixString(36), name: '')
      : ChatFolder.fromJson(widget.folder!.toJson() as Map<String, dynamic>);
  late final name = TextEditingController(text: f.name);

  Future<void> save() async {
    final s = AppScope.of(context);
    f.name = name.text.trim();
    if (f.name.isEmpty) return;
    final all = foldersOf(s)..removeWhere((x) => x.id == f.id);
    await saveFolders(s, [...all, f]);
    if (mounted) Navigator.pop(context);
  }

  Future<void> remove() async {
    final s = AppScope.of(context);
    await saveFolders(s, foldersOf(s)..removeWhere((x) => x.id == f.id));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    Widget kind(String k, IconData icon, Color c) => CupertinoListTile(
      leading: iconTile(c, icon),
      title: Text(filterName(l, k)),
      trailing: IosSwitch(
        key: Key('kind-$k'),
        value: f.kinds.contains(k),
        activeTrackColor: p.accent,
        onChanged: (v) => setState(() => v ? f.kinds.add(k) : f.kinds.remove(k)),
      ),
    );
    return SettingsScaffold(
      title: widget.folder == null ? l.newFolder : f.name,
      trailing: [GlassPill(key: const Key('folder-save'), text: l.save, onTap: save)],
      children: [
        group(context, [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
            child: CupertinoTextField(
              key: const Key('folder-name'),
              controller: name,
              placeholder: l.folderName,
              maxLength: 24,
              decoration: null,
              style: Tokens.body.style.copyWith(color: p.label),
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
            ),
          ),
        ]),
        group(context, header: l.folderKinds, footer: l.folderInfo, [
          kind('direct', CupertinoIcons.person_fill, Palette.tileBlue),
          kind('group', CupertinoIcons.person_3_fill, p.tileGreen),
          kind('channel', CupertinoIcons.speaker_2_fill, Palette.tileOrange),
          kind('bot', CupertinoIcons.cube_fill, Palette.tilePurple),
          kind('unread', CupertinoIcons.envelope_badge_fill, Palette.tileRed),
        ]),
        group(context, header: l.folderChats, [
          for (final c in s.chats)
            CupertinoListTile(
              key: Key('folder-chat-${c.roomId}'),
              leading: Avatar(name: c.name, size: 30, squircle: !c.isDirect),
              title: Text(c.name),
              trailing: Icon(f.takes(c) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: f.takes(c) ? p.accent : p.secondaryLabel),
              onTap: () => setState(() {
                if (f.takes(c)) {
                  f.include.remove(c.roomId);
                  if (f.takes(c)) f.exclude.add(c.roomId);
                } else {
                  f.exclude.remove(c.roomId);
                  if (!f.takes(c)) f.include.add(c.roomId);
                }
              }),
            ),
        ]),
        if (widget.folder != null) group(context, [NavRow(key: const Key('folder-delete'), title: l.deleteFolder, danger: true, onTap: remove)]),
      ],
    );
  }
}
