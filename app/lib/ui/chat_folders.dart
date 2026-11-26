// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat filters and folders, and the side menu that holds them (a full
// height card from the left that pushes the list aside).
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'chat_list_page.dart' show ArchivePage;
import 'bubbles.dart' show BubbleStrip;
import 'chat_row_actions.dart' show archiveInMenuPref, bubblesInMenuPref, showInfoBanner, storiesInMenuPref;
import 'stories.dart' show StoriesBar;
import 'folders_page.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'wide.dart';

/// A folder: a name, kinds of chats it takes, and chats added or left out
/// by hand. Kept in the on-device settings store.
class ChatFolder {
  ChatFolder({
    required this.id,
    required this.name,
    Set<String>? kinds,
    Set<String>? include,
    Set<String>? exclude,
    Set<String>? skip,
    this.emoji = '',
    this.color = -1,
  }) : kinds = kinds ?? {},
       include = include ?? {},
       exclude = exclude ?? {},
       skip = skip ?? {};
  final String id;
  String name;

  /// Emoji in front of the name (may be empty).
  String emoji;

  /// Tag colour: index into [folderColors], -1 = no tag.
  int color;

  /// Kinds it takes: contacts, noncontacts, group, channel, bot (and the
  /// older direct / unread).
  final Set<String> kinds;

  /// Kinds it leaves out: muted, read, archived.
  final Set<String> skip;
  final Set<String> include;
  final Set<String> exclude;

  bool takes(ChatPreview c, [Set<String> friends = const {}]) {
    if (exclude.contains(c.roomId)) return false;
    if (include.contains(c.roomId)) return true;
    if (skip.contains('muted') && c.muted) return false;
    if (skip.contains('read') && c.unread == 0) return false;
    if (skip.contains('archived') && c.archived) return false;
    return kinds.any(
      (k) => switch (k) {
        'contacts' => c.isDirect && !c.isBot && friends.contains(c.peer),
        'noncontacts' => c.isDirect && !c.isBot && !friends.contains(c.peer),
        _ => filterTakes(k, c),
      },
    );
  }

  String get label => emoji.isEmpty ? name : '$emoji $name';

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'kinds': kinds.toList(),
    'include': include.toList(),
    'exclude': exclude.toList(),
    'skip': skip.toList(),
    'emoji': emoji,
    'color': color,
  };

  static ChatFolder fromJson(Map<String, dynamic> j) => ChatFolder(
    id: j['id'] as String,
    name: j['name'] as String,
    kinds: {...(j['kinds'] as List).cast<String>()},
    include: {...(j['include'] as List).cast<String>()},
    exclude: {...(j['exclude'] as List).cast<String>()},
    skip: {...((j['skip'] as List?) ?? const []).cast<String>()},
    emoji: (j['emoji'] as String?) ?? '',
    color: (j['color'] as int?) ?? -1,
  );
}

/// Folder tag colours (iOS system colours).
const folderColors = [Palette.tileBlue, Color(0xFF34C759), Palette.tileOrange, Palette.tileRed, Palette.tilePurple, Palette.tileTeal, Palette.tilePink];

List<ChatFolder> foldersOf(AppState s) {
  try {
    return [for (final j in jsonDecode(s.pref('folders', '[]')) as List) ChatFolder.fromJson(j as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

String? _tagRaw;
List<ChatFolder> _tagged = const [];

/// Folders with a tag colour that take this chat (chat list tags; off by
/// Settings > Chat folders > Show folder tags).
List<ChatFolder> tagsOf(AppState s, ChatPreview c) {
  if (!s.on('folder_tags', fallback: true)) return const [];
  final raw = s.pref('folders', '[]');
  if (raw != _tagRaw) {
    _tagRaw = raw;
    _tagged = [
      for (final f in foldersOf(s))
        if (f.color >= 0 && f.color < folderColors.length) f,
    ];
  }
  return [
    for (final f in _tagged)
      if (f.takes(c, s.friendIds)) f,
  ];
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
    return f == null || f.takes(c, s.friendIds);
  }
  return filterTakes(filter, c);
}

/// Title for the list when a filter is on.
String filterTitle(AppState s, L l, String filter) {
  if (filter.startsWith('folder:')) {
    return foldersOf(s).where((x) => 'folder:${x.id}' == filter).firstOrNull?.label ?? l.tabChats;
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
            if (s.on(archiveInMenuPref) && s.chats.any((c) => c.archived))
              GestureDetector(
                key: const Key('menu-archive'),
                behavior: HitTestBehavior.opaque,
                onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => const ArchivePage())),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1] + 2, 0, Tokens.space[1] + 2),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.archivebox, size: Tokens.listIcon, color: p.label),
                      SizedBox(width: Tokens.space[2]),
                      Expanded(
                        child: Text(l.archive, style: Tokens.body.style.copyWith(color: p.label)),
                      ),
                      // Back into the chat list (Telegram's pin arrow).
                      CupertinoButton(
                        key: const Key('menu-archive-pin'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                        minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                        onPressed: () {
                          s.setOn(archiveInMenuPref, false);
                          showInfoBanner(context, l.archivePinnedTitle, l.archivePinnedBody);
                        },
                        child: Icon(CupertinoIcons.pin, size: Tokens.listIconSmall, color: p.accent),
                      ),
                    ],
                  ),
                ),
              ),
            // 스토리 / 비눗방울 moved here from the chat list; the pin puts them back.
            for (final (id, pref, label, pinned, strip) in [
              if (s.on(storiesInMenuPref) && s.chats.isNotEmpty)
                ('stories', storiesInMenuPref, l.menuStories, l.storiesPinnedTitle, StoriesBar(stories: s.stories, onChanged: () => s.refresh())),
              if (s.on(bubblesInMenuPref) && s.bubbles.isNotEmpty)
                ('bubbles', bubblesInMenuPref, l.bubblesWaiting(s.bubbles.length), l.bubblesPinnedTitle, BubbleStrip(bubbles: s.bubbles, caption: false)),
            ]) ...[
              Padding(
                key: Key('menu-$id'),
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ),
                    CupertinoButton(
                      key: Key('menu-$id-pin'),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                      onPressed: () {
                        s.setOn(pref, false);
                        showInfoBanner(context, pinned, l.archivePinnedBody);
                      },
                      child: Icon(CupertinoIcons.pin, size: Tokens.listIconSmall, color: p.accent),
                    ),
                  ],
                ),
              ),
              strip,
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[1]),
              child: Text(l.myFolders, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
            for (final f in folders)
              GestureDetector(
                onLongPress: () => paneNav(context).push(IosPageRoute(builder: (_) => FolderEditPage(folder: f))),
                child: row('folder:${f.id}', f.label, CupertinoIcons.folder, unreadIn((c) => f.takes(c, s.friendIds))),
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
            // Theme colour right in the side menu (Eric 2026-11-25): tap a dot.
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[1]),
              child: Text(l.myColor, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              child: Row(
                children: [
                  for (final (fam, label) in [(BrandFamily.green, l.themeGreen), (BrandFamily.blue, l.themeBlue)])
                    GestureDetector(
                      key: Key('menu-theme-${fam.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => s.setFamily(fam),
                      child: Padding(
                        padding: EdgeInsets.all(Tokens.space[1]),
                        child: Column(
                          children: [
                            Container(
                              width: Tokens.closeButton,
                              height: Tokens.closeButton,
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: s.family == fam ? Brand.accent(fam, p.brightness) : const Color(0x00000000), width: 2),
                              ),
                              child: Container(
                                decoration: BoxDecoration(color: Brand.accent(fam, p.brightness), shape: BoxShape.circle),
                                child: s.family == fam ? const Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIconSmall, color: Color(0xFFFFFFFF)) : null,
                              ),
                            ),
                            SizedBox(height: Tokens.space[0]),
                            Text(label, style: Tokens.caption.style.copyWith(color: s.family == fam ? p.label : p.secondaryLabel)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
