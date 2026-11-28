// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat filters and folders, and the side menu that holds them (a full
// height card from the left that pushes the list aside).
import 'dart:math' as math;
import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/chat_marks.dart';
import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'chat_list_page.dart' show ArchivePage, SearchCapsule;
import 'chat_row_actions.dart' show archiveInMenuPref, showInfoBanner, storiesInMenuPref;
import 'stories.dart' show StoriesBar;
import 'folders_page.dart';
import 'glass.dart' show GlassCircle, LiquidGlass;
import 'look_pages.dart' show toggleNight;
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
    this.iconOnly = false,
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

  /// Telegram 502: the folder tab shows only its emoji (needs one).
  bool iconOnly;

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

  String get label => emoji.isEmpty ? name : (iconOnly ? emoji : '$emoji $name');

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'kinds': kinds.toList(),
    'include': include.toList(),
    'exclude': exclude.toList(),
    'skip': skip.toList(),
    'emoji': emoji,
    'color': color,
    if (iconOnly) 'icon_only': true,
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
    iconOnly: j['icon_only'] == true,
  );
}

/// [filter] is a folder ("folder:<id>") that has [roomId] added by hand
/// and doesn't leave archived chats out.
bool inFolderByHand(AppState s, String filter, String roomId) {
  if (!filter.startsWith('folder:')) return false;
  final id = filter.substring(7);
  for (final f in foldersOf(s)) {
    if (f.id == id) return f.include.contains(roomId) && !f.skip.contains('archived') && !f.exclude.contains(roomId);
  }
  return false;
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

/// Where "모든 대화" sits among my folder tabs (Telegram tip 342): the tab
/// in front is the one the app opens on.
const allPosPref = 'all_pos';

int allPos(AppState s, int folders) => (int.tryParse(s.pref(allPosPref, '0')) ?? 0).clamp(0, folders);

/// The filter the chat list opens on: "모두", or the folder put in front.
String startFilter(AppState s) {
  final f = foldersOf(s);
  return f.isNotEmpty && allPos(s, f.length) > 0 ? 'folder:${f.first.id}' : 'all';
}

Future<void> saveFolders(AppState s, List<ChatFolder> f) => s.setPref('folders', f.isEmpty ? '' : jsonEncode([for (final x in f) x.toJson()]));

/// Built-in filters: all, unread, mention, direct (people), group, channel, bot.
/// 'mention' = groups where someone @-called me or answered me and I
/// haven't looked yet (WhatsApp/Viber style; counts come from this phone).
bool filterTakes(String f, ChatPreview c) => switch (f) {
  'unread' => c.unread > 0,
  'mention' => (ChatMarks.counts.value[c.roomId]?.mentions ?? 0) > 0,
  'direct' => c.isDirect && !c.isBot,
  'group' => !c.isDirect && !c.isChannel,
  'channel' => c.isChannel,
  'bot' => c.isBot,
  _ => true,
};

String filterName(L l, String f) => switch (f) {
  'unread' => l.filterUnread,
  'mention' => l.filterMentions,
  'direct' => l.filterPeople,
  'group' => l.filterGroups,
  'channel' => l.filterChannels,
  'bot' => l.filterBots,
  _ => l.filterAll,
};

/// The built-in filter tabs, in order ('mention' only where marks are on).
List<String> get builtInFilters => ['all', 'unread', if (Features.tipsReply) 'mention', 'direct', 'group', 'channel', 'bot'];

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
  const SideMenu({super.key, this.controller, required this.filter, required this.onPick, required this.onSearch});
  final ScrollController? controller;
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
    // Unread chats in each folder, muted ones too (iOS Mail / Telegram).
    int unreadIn(bool Function(ChatPreview) f) => chats.where((c) => f(c) && c.unread > 0).length;
    Widget row(String id, String title, IconData icon, int count) {
      final on = filter == id;
      return GestureDetector(
        key: Key('filter-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onPick(id),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
          padding: EdgeInsets.symmetric(horizontal: Tokens.menuInset - Tokens.space[1], vertical: Tokens.space[1] + 2),
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24)],
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          controller: controller,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(top: Tokens.space[1], bottom: Tokens.space[4]),
          children: [
            // iOS sheet grabber.
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: EdgeInsets.only(bottom: Tokens.space[2]),
                decoration: BoxDecoration(color: p.chevron, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                children: [
                  Expanded(
                    child: SearchCapsule(key: const Key('side-search'), hint: l.searchChats, onChanged: onSearch),
                  ),
                  // 야간 모드 빠른 전환 (Telegram 180): moon by day, sun by night.
                  Padding(
                    padding: EdgeInsets.only(left: Tokens.space[2]),
                    child: GlassCircle(
                      key: const Key('menu-night'),
                      size: Tokens.closeButton,
                      onTap: () => toggleNight(s, p.dark),
                      child: Icon(p.dark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill, size: Tokens.listIcon, color: p.label),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            row('all', l.filterAll, CupertinoIcons.chat_bubble_2, unreadIn((_) => true)),
            row('unread', l.filterUnread, CupertinoIcons.envelope_badge, unreadIn((_) => true)),
            if (Features.tipsReply) row('mention', l.filterMentions, CupertinoIcons.at, ChatMarks.counts.value.values.where((m) => m.mentions > 0).length),
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
                  padding: EdgeInsets.fromLTRB(Tokens.menuInset - Tokens.space[1], Tokens.space[1] + 2, 0, Tokens.space[1] + 2),
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
            // 스토리 moved here from the chat list; the pin puts it back. 비눗방울
            // lives in each chat row now (Eric 2026-11-26), so it has no strip.
            for (final (id, pref, label, pinned, strip) in [
              if (s.on(storiesInMenuPref) && s.chats.isNotEmpty)
                ('stories', storiesInMenuPref, l.menuStories, l.storiesPinnedTitle, StoriesBar(stories: s.stories, onChanged: () => s.refresh())),
            ]) ...[
              Padding(
                key: Key('menu-$id'),
                padding: EdgeInsets.fromLTRB(Tokens.menuInset, Tokens.space[2], 0, 0),
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
              padding: EdgeInsets.fromLTRB(Tokens.menuInset, Tokens.space[3], Tokens.menuInset, Tokens.space[1]),
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
                padding: EdgeInsets.symmetric(horizontal: Tokens.menuInset, vertical: Tokens.space[1] + 2),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add, size: Tokens.listIcon, color: p.accent),
                    SizedBox(width: Tokens.space[2]),
                    Text(l.newFolder, style: Tokens.body.style.copyWith(color: p.accent)),
                  ],
                ),
              ),
            ),
            // Theme colour in one row (Eric 2026-11-26): the words on the left,
            // two small swatches at the right end like an iOS colour row.
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.menuInset, Tokens.space[3], Tokens.space[2], 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.myColor, style: Tokens.body.style.copyWith(color: p.label)),
                  ),
                  for (final (fam, label) in [(BrandFamily.green, l.themeGreen), (BrandFamily.blue, l.themeBlue)])
                    Semantics(
                      label: label,
                      selected: s.family == fam,
                      child: GestureDetector(
                        key: Key('menu-theme-${fam.name}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => s.setFamily(fam),
                        child: SizedBox.square(
                          dimension: Tokens.closeButton,
                          child: Center(
                            child: Container(
                              width: Tokens.miniFace,
                              height: Tokens.miniFace,
                              padding: const EdgeInsets.all(Tokens.miniRing + Tokens.miniGap),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: s.family == fam ? Brand.accent(fam, p.brightness) : const Color(0x00000000), width: Tokens.miniRing),
                              ),
                              child: Container(
                                decoration: BoxDecoration(color: Brand.accent(fam, p.brightness), shape: BoxShape.circle),
                              ),
                            ),
                          ),
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

/// Telegram folder tabs under the list search (Eric 2026-11-26 "이렇게"):
/// one glass capsule, 모두 + my folders, the chosen one on a soft grey pill,
/// unread chats as a small grey count. Few folders share the width; many
/// scroll sideways.
class FolderTabs extends StatelessWidget {
  const FolderTabs({super.key, required this.items, required this.selected, required this.onPick, this.onHold});

  /// (filter id, label, unread chats).
  final List<(String, String, int)> items;
  final String selected;
  final ValueChanged<String> onPick;

  /// Long press on a tab (Telegram: 폴더 편집 / 읽지 않은 대화 보기 / 탭 재정렬).
  final ValueChanged<String>? onHold;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    Widget tab(String id, String label, int count) {
      final on = selected == id;
      return GestureDetector(
        key: Key('tab-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onPick(id),
        onLongPress: onHold == null ? null : () => onHold!(id),
        // PC: right click opens the same menu (폴더 편집 ...), tip 61.
        onSecondaryTap: onHold == null ? null : () => onHold!(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? (p.dark ? const Color(0x33FFFFFF) : const Color(0x14000000)) : const Color(0x00000000),
            borderRadius: BorderRadius.circular(Tokens.capsule),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: on ? FontWeight.w500 : FontWeight.w400),
                ),
              ),
              if (count > 0) ...[
                SizedBox(width: Tokens.space[1] - 2),
                Container(
                  constraints: const BoxConstraints(minWidth: Tokens.folderCount),
                  height: Tokens.folderCount,
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] - 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.folderCount, borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Text(
                    count > 999 ? '999+' : '$count',
                    style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final few = items.length <= 3;
    // Same glass as the tab bar at the bottom (Eric 2026-11-28 "하단바와
    // 같이"): its blur, edge and shadow, and its pill for the chosen tab.
    // Height and width stay as they were.
    return SizedBox(
      height: Tokens.folderTabs,
      child: LiquidGlass(
        radius: Tokens.folderTabs / 2,
        child: Padding(
          padding: const EdgeInsets.all(Tokens.folderTabInset),
          // Every tab the same width when they all fit (Eric 2026-11-28
          // "버튼 비율은 모두 같게"); a name that would be cut at that
          // width (English "Local & hobby") turns the row into a
          // sliding list instead, so nothing is ever cut.
          child: LayoutBuilder(
            builder: (context, box) {
              final scale = MediaQuery.textScalerOf(context);
              double need(String label, int n, bool on) {
                final tp = TextPainter(
                  text: TextSpan(
                    text: label,
                    style: Tokens.body.style.copyWith(fontWeight: on ? FontWeight.w500 : FontWeight.w400),
                  ),
                  textDirection: TextDirection.ltr,
                  textScaler: scale,
                  maxLines: 1,
                )..layout();
                final badge = n <= 0 ? 0.0 : Tokens.space[1] - 2 + math.max(Tokens.folderCount, 2 * (Tokens.space[1] - 2) + 9.0 * (n > 999 ? 4 : '$n'.length));
                final w = tp.width;
                tp.dispose();
                return w + 2 * Tokens.space[3] + badge + 2;
              }

              final widest = items.isEmpty ? 0.0 : items.map((x) => need(x.$2, x.$3, true)).reduce(math.max);
              final equal = few && widest * items.length <= box.maxWidth;
              return equal
                  ? Row(children: [for (final (id, label, n) in items) Expanded(child: tab(id, label, n))])
                  : ScrollConfiguration(
                      // No scroll bar line under the tabs (the web drew one).
                      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                      child: ListView(scrollDirection: Axis.horizontal, children: [for (final (id, label, n) in items) tab(id, label, n)]),
                    );
            },
          ),
        ),
      ),
    );
  }
}

/// Keeps [FolderTabs] stuck under the bar while the list scrolls under it.
class FolderTabsHeader extends SliverPersistentHeaderDelegate {
  FolderTabsHeader(this.tabs);
  final Widget tabs;

  static const extent = Tokens.folderTabsAbove + Tokens.folderTabs + Tokens.folderTabsBelow;

  @override
  double get minExtent => extent;
  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Padding(padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.folderTabsAbove, Tokens.space[3], Tokens.folderTabsBelow), child: tabs);

  @override
  bool shouldRebuild(FolderTabsHeader old) => true;
}
