// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Chat folders (Telegram-style): folder list with edit mode,
// suggested folders and tags; the folder editor; the chat picker.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../brand/brand.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_folders.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show GlassSheet;
import 'settings_art.dart';
import 'settings_kit.dart';
import 'wide.dart';

/// Icon, tile colour and name of a chat kind (include or exclude).
(IconData, Color, String) kindLook(BuildContext context, String k) {
  final l = L.of(context);
  final p = paletteOf(context);
  return switch (k) {
    'contacts' => (CupertinoIcons.person_crop_circle_fill, Palette.tileBlue, l.kindContacts),
    'noncontacts' => (CupertinoIcons.person_crop_circle_badge_xmark, Palette.tileTeal, l.kindNonContacts),
    'direct' => (CupertinoIcons.person_fill, Palette.tileBlue, l.filterPeople),
    'group' => (CupertinoIcons.person_3_fill, p.tileGreen, l.filterGroups),
    'channel' => (CupertinoIcons.speaker_2_fill, Palette.tileOrange, l.filterChannels),
    'bot' => (CupertinoIcons.cube_fill, Palette.tilePurple, l.filterBots),
    'unread' => (CupertinoIcons.envelope_badge_fill, Palette.tileRed, l.filterUnread),
    'muted' => (CupertinoIcons.bell_slash_fill, Palette.tileRed, l.kindMuted),
    'read' => (CupertinoIcons.checkmark_alt_circle_fill, Palette.tileTeal, l.kindRead),
    _ => (CupertinoIcons.archivebox_fill, Palette.tileOrange, l.kindArchived),
  };
}

/// Small coloured folder tag (chat list and the colour preview).
class FolderTag extends StatelessWidget {
  const FolderTag({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Tokens.radius[0])),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Tokens.caption.style.copyWith(color: color),
    ),
  );
}

/// Settings > Chat folders.
class FoldersPage extends StatefulWidget {
  const FoldersPage({super.key});
  @override
  State<FoldersPage> createState() => _FoldersPageState();
}

class _FoldersPageState extends State<FoldersPage> {
  bool editing = false;

  /// Folder waiting 5 seconds to be deleted (undo bar), and seconds left.
  String? pending;
  int left = 0;
  Timer? tick;

  @override
  void dispose() {
    tick?.cancel();
    if (pending != null) unawaited(_commit(AppScope.read(context), pending!));
    super.dispose();
  }

  Future<void> _commit(AppState s, String id) => saveFolders(s, foldersOf(s)..removeWhere((x) => x.id == id));

  void remove(AppState s, ChatFolder f) {
    tick?.cancel();
    if (pending != null) unawaited(_commit(s, pending!));
    setState(() {
      pending = f.id;
      left = 5;
    });
    tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (left <= 1) {
        t.cancel();
        final id = pending;
        setState(() => pending = null);
        if (id != null) unawaited(_commit(s, id));
      } else {
        setState(() => left--);
      }
    });
  }

  void undo() {
    tick?.cancel();
    setState(() => pending = null);
  }

  Future<void> edit(ChatFolder? f) async {
    await paneNav(context).push(IosPageRoute<void>(builder: (_) => FolderEditPage(folder: f)));
    if (mounted) setState(() {});
  }

  Future<void> suggest(AppState s, ChatFolder f) async {
    await saveFolders(s, [...foldersOf(s), f]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final all = foldersOf(s);
    final folders = [
      for (final f in all)
        if (f.id != pending) f,
    ];
    int count(ChatFolder f) => s.chats.where((c) => f.takes(c, s.friendIds)).length;

    Widget folderRow(int i, ChatFolder f) {
      final c = f.color >= 0 && f.color < folderColors.length ? folderColors[f.color] : Palette.tileGrey;
      return Column(
        key: ValueKey(f.id),
        mainAxisSize: MainAxisSize.min,
        children: [
          if (i > 0)
            Container(
              height: 1,
              margin: const EdgeInsetsDirectional.only(start: 60, end: 20),
              color: p.dark ? const Color(0xFF38383A) : const Color(0xFFE6E6E8),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: IosSection.rowHeight),
            child: CupertinoListTile(
              key: Key('folder-row-${f.id}'),
              backgroundColor: p.card,
              leading: editing
                  ? GestureDetector(
                      key: Key('folder-minus-${f.id}'),
                      onTap: () => remove(s, f),
                      child: const Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: 24),
                    )
                  : f.emoji.isEmpty
                  ? iconTile(c, CupertinoIcons.folder_fill)
                  : SizedBox(
                      width: 28,
                      child: Center(child: Text(f.emoji, style: const TextStyle(fontSize: 22))),
                    ),
              title: Text(f.name),
              additionalInfo: editing ? null : Text(l.folderChatsCount(count(f))),
              trailing: editing
                  ? ReorderableDragStartListener(
                      index: i,
                      child: Icon(CupertinoIcons.line_horizontal_3, key: Key('folder-drag-${f.id}'), color: p.secondaryLabel),
                    )
                  : const CupertinoListTileChevron(),
              onTap: editing ? null : () => edit(f),
            ),
          ),
        ],
      );
    }

    final names = {for (final f in all) f.name};
    final suggestions = [
      if (!names.contains(l.folderUnreadName))
        (
          'unread',
          ChatFolder(
            id: 'unread${DateTime.now().millisecondsSinceEpoch}',
            name: l.folderUnreadName,
            kinds: {'contacts', 'noncontacts', 'group', 'channel', 'bot'},
            skip: {'read'},
          ),
          l.folderUnreadInfo,
        ),
      if (!names.contains(l.folderPersonalName))
        (
          'personal',
          ChatFolder(id: 'personal${DateTime.now().millisecondsSinceEpoch}', name: l.folderPersonalName, kinds: {'contacts', 'noncontacts'}),
          l.folderPersonalInfo,
        ),
    ];

    return WidePage(
      child: CupertinoPageScaffold(
        backgroundColor: p.background,
        navigationBar: GlassTopBar(
          title: l.chatFolders,
          back: true,
          tint: p.background,
          trailing: [
            if (folders.isNotEmpty)
              editing
                  ? GlassDone(key: const Key('folders-done'), onTap: () => setState(() => editing = false))
                  : GlassPill(key: const Key('folders-edit'), text: l.editList, onTap: () => setState(() => editing = true)),
          ],
        ),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + GlassTopBar.height,
                bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5] * 2,
              ),
              children: [
                ArtHeader(art: const FolderArt(), text: l.foldersArtInfo),
                group(context, header: l.myFolders, footer: folders.isEmpty ? null : l.foldersEditInfo, [
                  CupertinoListTile(
                    key: const Key('folders-new'),
                    leading: Icon(CupertinoIcons.add, color: p.accent),
                    title: Text(l.createFolder, style: TextStyle(color: p.accent)),
                    onTap: () => edit(null),
                  ),
                  CupertinoListTile(
                    key: const Key('folders-all'),
                    leading: iconTile(p.tileGreen, CupertinoIcons.chat_bubble_2_fill),
                    title: Text(l.allChatsFolder),
                  ),
                  if (folders.isNotEmpty)
                    ReorderableList(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: folders.length,
                      itemBuilder: (_, i) => folderRow(i, folders[i]),
                      // iOS lift: slight scale + soft shadow while dragging.
                      proxyDecorator: (child, _, a) => AnimatedBuilder(
                        animation: a,
                        builder: (_, _) => Transform.scale(
                          scale: 1 + 0.03 * a.value,
                          child: DecoratedBox(
                            decoration: BoxDecoration(boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.12 * a.value), blurRadius: 16)]),
                            child: child,
                          ),
                        ),
                      ),
                      onReorderItem: (a, b) async {
                        final list = [...folders];
                        final f = list.removeAt(a);
                        list.insert(b, f);
                        final gone = all.where((x) => x.id == pending);
                        await saveFolders(s, [...list, ...gone]);
                        if (mounted) setState(() {});
                      },
                    ),
                ]),
                if (suggestions.isNotEmpty && !editing)
                  group(context, header: l.recommendedFolders, [
                    for (final (key, f, info) in suggestions)
                      CupertinoListTile(
                        key: Key('suggest-$key'),
                        title: Text(f.name),
                        subtitle: Text(info),
                        trailing: GestureDetector(
                          key: Key('suggest-add-$key'),
                          onTap: () => suggest(s, f),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 5),
                            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                            child: Text(l.add, style: Tokens.preview.style.copyWith(color: p.onAccent)),
                          ),
                        ),
                      ),
                  ]),
                group(context, footer: l.folderTagsInfo, [PrefSwitch('folder_tags', key: const Key('folder-tags'), title: l.folderTags, fallback: true)]),
              ],
            ),
            if (pending != null)
              Positioned(
                left: Tokens.space[3],
                right: Tokens.space[3],
                bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[3],
                child: Container(
                  key: const Key('folders-undo-bar'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                  decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l.deletingIn(left), style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF))),
                      ),
                      CupertinoButton(
                        key: const Key('folders-undo'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                        minimumSize: const Size(0, 36),
                        onPressed: undo,
                        child: Text(l.undo, style: Tokens.body.style.copyWith(color: Brand.accent(p.family, Brightness.dark))),
                      ),
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

/// Make or change a folder: name + icon, chats in, chats out, tag colour.
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
  bool tried = false;

  bool get empty => f.kinds.isEmpty && f.include.isEmpty;

  Future<void> save() async {
    final s = AppScope.of(context);
    f.name = name.text.trim();
    if (f.name.isEmpty || empty) {
      setState(() => tried = true);
      return;
    }
    final all = foldersOf(s);
    final at = all.indexWhere((x) => x.id == f.id);
    if (at >= 0) {
      all[at] = f;
    } else {
      all.add(f);
    }
    await saveFolders(s, all);
    if (mounted) Navigator.pop(context);
  }

  Future<void> remove() async {
    final s = AppScope.of(context);
    await saveFolders(s, foldersOf(s)..removeWhere((x) => x.id == f.id));
    if (mounted) Navigator.pop(context);
  }

  Future<void> pick(bool out) async {
    await paneNav(context).push(
      IosPageRoute<void>(
        builder: (_) => ChatPickPage(folder: f, exclude: out),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> pickEmoji() async {
    const emojis = [
      '💬',
      '👥',
      '📢',
      '🤖',
      '⭐️',
      '❤️',
      '💼',
      '🏠',
      '🎓',
      '🎮',
      '🎵',
      '✈️',
      '🛒',
      '💰',
      '📚',
      '🍀',
      '🔥',
      '🎉',
      '🐶',
      '⚽️',
      '💡',
      '📌',
      '🔒',
      '👪',
    ];
    final l = L.of(context);
    final p = paletteOf(context);
    final got = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (x) => GlassSheet(
        title: l.folderIcon,
        children: [
          Padding(
            padding: EdgeInsets.all(Tokens.space[2]),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: Tokens.space[1],
              runSpacing: Tokens.space[1],
              children: [
                for (final e in emojis)
                  GestureDetector(
                    key: Key('folder-emoji-$e'),
                    onTap: () => Navigator.pop(x, e),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 28))),
                    ),
                  ),
              ],
            ),
          ),
          CupertinoButton(
            key: const Key('folder-emoji-none'),
            onPressed: () => Navigator.pop(x, ''),
            child: Text(l.folderIconNone, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
    if (got != null) setState(() => f.emoji = got);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final byId = {for (final c in s.chats) c.roomId: c};

    Widget drop(Key key, VoidCallback onTap) => GestureDetector(
      key: key,
      onTap: () => setState(onTap),
      child: Icon(CupertinoIcons.minus_circle, color: p.secondaryLabel, size: 22),
    );
    Widget kindRow(String k, Set<String> from) {
      final (icon, color, title) = kindLook(context, k);
      return CupertinoListTile(
        key: Key('folder-kind-$k'),
        leading: iconTile(color, icon),
        title: Text(title),
        trailing: drop(Key('folder-drop-$k'), () => from.remove(k)),
      );
    }

    Widget chatRow(String id, Set<String> from) {
      final c = byId[id];
      final n = c == null ? id : nameOf(s, c);
      return CupertinoListTile(
        key: Key('folder-has-$id'),
        leading: Avatar(name: n, size: 28, squircle: c != null && !c.isDirect, userId: c?.isDirect == true ? c!.peer : null, roomId: id),
        title: Text(n),
        trailing: drop(Key('folder-drop-$id'), () => from.remove(id)),
      );
    }

    Widget addRow(Key key, bool out) => CupertinoListTile(
      key: key,
      leading: Icon(CupertinoIcons.add, color: p.accent),
      title: Text(l.folderAddChats, style: TextStyle(color: p.accent)),
      onTap: () => pick(out),
    );

    final color = f.color >= 0 && f.color < folderColors.length ? folderColors[f.color] : null;
    final tagName = name.text.trim().isEmpty ? l.folderName : name.text.trim();
    return WidePage(
      child: CupertinoPageScaffold(
        backgroundColor: p.background,
        navigationBar: GlassTopBar(
          title: widget.folder == null ? l.newFolderTitle : f.label,
          leading: const [GlassBack(close: true)],
          trailing: [GlassDone(key: const Key('folder-save'), onTap: save)],
          tint: p.background,
        ),
        child: ListView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height, bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5]),
          children: [
            group(context, header: l.folderName, footer: tried && name.text.trim().isEmpty ? l.folderNeedName : null, error: true, [
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      key: const Key('folder-name'),
                      controller: name,
                      placeholder: l.folderName,
                      maxLength: 24,
                      decoration: null,
                      onChanged: (_) => setState(() {}),
                      style: Tokens.body.style.copyWith(color: p.label),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                    ),
                  ),
                  GestureDetector(
                    key: const Key('folder-emoji'),
                    onTap: pickEmoji,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      child: f.emoji.isEmpty ? Icon(CupertinoIcons.folder, color: p.accent, size: 24) : Text(f.emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),
            ]),
            group(context, header: l.folderInclude, footer: tried && empty ? l.folderNeedChats : l.folderIncludeInfo, error: tried && empty, [
              addRow(const Key('folder-add-include'), false),
              for (final k in f.kinds) kindRow(k, f.kinds),
              for (final id in f.include) chatRow(id, f.include),
            ]),
            group(context, header: l.folderExclude, footer: l.folderExcludeInfo, [
              addRow(const Key('folder-add-exclude'), true),
              for (final k in f.skip) kindRow(k, f.skip),
              for (final id in f.exclude) chatRow(id, f.exclude),
            ]),
            IosSection(
              header: Row(
                children: [
                  Expanded(child: sectionHeader(context, l.folderColor)),
                  color == null
                      ? Text(
                          l.folderNoTag,
                          key: const Key('folder-tag-preview'),
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        )
                      : FolderTag(key: const Key('folder-tag-preview'), text: tagName, color: color),
                ],
              ),
              footer: sectionFooter(context, l.folderColorInfo),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = -1; i < folderColors.length; i++)
                        GestureDetector(
                          key: Key('folder-color-$i'),
                          onTap: () => setState(() => f.color = i),
                          child: Container(
                            width: 34,
                            height: 34,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: f.color == i ? (i < 0 ? p.secondaryLabel : folderColors[i]) : const Color(0x00000000), width: 2),
                            ),
                            child: Container(
                              decoration: BoxDecoration(shape: BoxShape.circle, color: i < 0 ? p.background : folderColors[i]),
                              child: i < 0 ? Icon(CupertinoIcons.nosign, size: 16, color: p.secondaryLabel) : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.folder != null) group(context, [NavRow(key: const Key('folder-delete'), title: l.deleteFolder, danger: true, onTap: remove)]),
          ],
        ),
      ),
    );
  }
}

/// Pick chats and chat types for a folder (in or out).
class ChatPickPage extends StatefulWidget {
  const ChatPickPage({super.key, required this.folder, required this.exclude});
  final ChatFolder folder;
  final bool exclude;
  @override
  State<ChatPickPage> createState() => _ChatPickPageState();
}

class _ChatPickPageState extends State<ChatPickPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final f = widget.folder;
    final kinds = widget.exclude ? f.skip : f.kinds;
    final chats = widget.exclude ? f.exclude : f.include;
    final other = widget.exclude ? f.include : f.exclude;
    final types = widget.exclude ? const ['muted', 'read', 'archived'] : const ['contacts', 'noncontacts', 'group', 'channel', 'bot'];
    Widget mark(bool on) => Icon(on ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: on ? p.accent : p.secondaryLabel);
    final q = query.trim().toLowerCase();
    final list = <ChatPreview>[
      for (final c in s.chats)
        if (q.isEmpty || nameOf(s, c).toLowerCase().contains(q)) c,
    ];
    return SettingsScaffold(
      title: widget.exclude ? l.folderExclude : l.folderInclude,
      trailing: [GlassDone(key: const Key('pick-done'), onTap: () => Navigator.pop(context))],
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[2], IosSection.sideMargin, 0),
          child: CupertinoSearchTextField(
            key: const Key('pick-search'),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            placeholder: l.searchChats,
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        if (q.isEmpty)
          group(context, header: l.chatTypes, [
            for (final k in types)
              Builder(
                builder: (context) {
                  final (icon, color, title) = kindLook(context, k);
                  return CupertinoListTile(
                    key: Key('pick-kind-$k'),
                    leading: iconTile(color, icon),
                    title: Text(title),
                    trailing: mark(kinds.contains(k)),
                    onTap: () => setState(() => kinds.contains(k) ? kinds.remove(k) : kinds.add(k)),
                  );
                },
              ),
          ]),
        group(context, header: l.chatsHeader, [
          for (final c in list)
            CupertinoListTile(
              key: Key('folder-chat-${c.roomId}'),
              leading: Avatar(name: nameOf(s, c), size: 28, squircle: !c.isDirect, userId: c.isDirect ? c.peer : null, roomId: c.roomId),
              title: Text(nameOf(s, c)),
              trailing: mark(chats.contains(c.roomId)),
              onTap: () => setState(() {
                if (!chats.remove(c.roomId)) {
                  chats.add(c.roomId);
                  other.remove(c.roomId);
                }
              }),
            ),
        ]),
      ],
    );
  }
}
