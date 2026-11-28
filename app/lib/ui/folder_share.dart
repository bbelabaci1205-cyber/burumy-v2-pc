// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 폴더 공유 (Telegram tip 211): 폴더 편집 > 폴더 공유하기 makes one link
// with the folder's groups and channels; whoever opens it sees the folder,
// ticks the chats they want, and adds the folder + joins them in one tap.
// Link format and limits: core/folder_link.dart.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart' hide LinkCard;
import '../core/folder_link.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_folders.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'glass.dart';
import 'invite_links.dart' show LinkCard;
import 'ios.dart';
import 'settings_kit.dart';
import 'wide.dart';

/// The folder's link-able chats: (chat, link item or null = no link).
Future<List<(ChatPreview, FolderLinkItem?)>> folderChats(AppState s, ChatFolder f) async {
  final out = <(ChatPreview, FolderLinkItem?)>[];
  for (final c in s.chats) {
    if (c.isDirect || !f.takes(c, s.friendIds)) continue;
    FolderLinkItem? item;
    try {
      final link = await s.backend.roomLink(c.roomId);
      if (link.public) item = FolderLinkItem(kind: 'public', code: link.code, channel: c.isChannel);
      if (link.private) item = FolderLinkItem(kind: 'private', code: link.code, name: c.name, channel: c.isChannel);
    } catch (_) {}
    out.add((c, item));
  }
  return out;
}

/// 폴더 공유하기: pick the chats, then copy or share the link.
class FolderSharePage extends StatefulWidget {
  const FolderSharePage({super.key, required this.folder});
  final ChatFolder folder;

  @override
  State<FolderSharePage> createState() => _FolderSharePageState();
}

class _FolderSharePageState extends State<FolderSharePage> {
  List<(ChatPreview, FolderLinkItem?)>? chats;

  /// Chats left out of the link (all with a link are in to start).
  final left = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final list = await folderChats(AppScope.read(context), widget.folder);
      if (mounted) setState(() => chats = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = chats;
    final items = [
      for (final (c, i) in list ?? const <(ChatPreview, FolderLinkItem?)>[])
        if (i != null && !left.contains(c.roomId)) i,
    ];
    final link = items.isEmpty ? '' : FolderLink(name: widget.folder.name, emoji: widget.folder.emoji, items: items).url;
    return SettingsScaffold(
      title: l.folderShare,
      children: [
        HeaderCard(
          color: Palette.tileBlue,
          icon: CupertinoIcons.folder_fill_badge_person_crop,
          title: l.folderShareTitle(widget.folder.name),
          body: l.folderShareInfo,
        ),
        if (list == null)
          const Padding(padding: EdgeInsets.all(24), child: CupertinoActivityIndicator())
        else ...[
          group(context, header: l.folderShareChats, footer: l.folderShareChatsInfo, [
            if (list.isEmpty)
              IosTile(
                key: const Key('folder-share-none'),
                title: Text(l.folderShareNone, style: TextStyle(color: p.secondaryLabel)),
              ),
            for (final (c, i) in list)
              IosTile(
                key: Key('folder-share-${c.roomId}'),
                leading: Avatar(name: c.name, size: 30, squircle: true, roomId: c.roomId, channel: c.isChannel),
                title: Text(
                  c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: i == null ? p.secondaryLabel : p.label),
                ),
                subtitle: i == null ? Text(l.folderShareNoLink) : null,
                trailing: i == null
                    ? null
                    : Icon(
                        left.contains(c.roomId) ? CupertinoIcons.circle : CupertinoIcons.checkmark_circle_fill,
                        color: left.contains(c.roomId) ? p.secondaryLabel : p.accent,
                      ),
                onTap: i == null ? null : () => setState(() => left.contains(c.roomId) ? left.remove(c.roomId) : left.add(c.roomId)),
              ),
          ]),
          if (link.isNotEmpty)
            KeyedSubtree(
              key: const Key('folder-share-link'),
              child: LinkCard(link: link),
            ),
        ],
      ],
    );
  }
}

/// Our folder link was opened: the folder card.
Future<void> openFolderLink(BuildContext context, FolderLink link) => openSheet<void>(context, (_) => FolderJoinPage(link: link));

class FolderJoinPage extends StatefulWidget {
  const FolderJoinPage({super.key, required this.link});
  final FolderLink link;

  @override
  State<FolderJoinPage> createState() => _FolderJoinPageState();
}

class _FolderJoinPageState extends State<FolderJoinPage> {
  /// Public chats: what the server shows before joining.
  final peeks = <String, LinkPeek?>{};

  /// Chats not ticked (all ticked to start, Telegram).
  final left = <String>{};
  bool loading = true;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    for (final i in widget.link.items) {
      if (i.kind != 'public') continue;
      try {
        peeks[i.code] = await b.peekAddress(i.code);
      } catch (_) {
        peeks[i.code] = null;
      }
    }
    if (mounted) setState(() => loading = false);
  }

  String nameOf(FolderLinkItem i) {
    final n = i.kind == 'public' ? peeks[i.code]?.name ?? i.code : i.name;
    return n.isEmpty ? L.of(context).joinUnnamed : n;
  }

  bool joined(FolderLinkItem i) => i.kind == 'public' && (peeks[i.code]?.joined ?? false);

  bool gone(FolderLinkItem i) => i.kind == 'public' && peeks.containsKey(i.code) && peeks[i.code] == null;

  Future<void> go() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final nav = Navigator.of(context);
    setState(() => busy = true);
    final rooms = <String>{};
    var asked = 0, failed = 0;
    for (final i in widget.link.items) {
      if (left.contains(i.code) || gone(i)) continue;
      if (joined(i)) {
        rooms.add(peeks[i.code]!.roomId);
        continue;
      }
      try {
        final (room, onlyAsked) = await s.backend.joinLink(i.kind, i.code);
        if (onlyAsked) {
          asked++;
        } else {
          rooms.add(room);
        }
      } catch (_) {
        failed++;
      }
    }
    await s.refresh();
    // The folder takes the chats I'm in now (asked ones join it later by hand).
    final all = foldersOf(s);
    final name = widget.link.name;
    final f = ChatFolder(id: DateTime.now().microsecondsSinceEpoch.toRadixString(36), name: name, emoji: widget.link.emoji, include: rooms);
    if (rooms.isNotEmpty) await saveFolders(s, [...all, f]);
    if (!mounted) return;
    nav.pop();
    final extra = [if (asked > 0) l.folderJoinAsked(asked), if (failed > 0) l.folderJoinFailed(failed)].join(' ');
    showInfoBanner(context, rooms.isEmpty ? l.folderJoinNone : l.folderJoined(name, rooms.length), extra, icon: CupertinoIcons.folder_fill);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final items = widget.link.items;
    final picked = items.where((i) => !left.contains(i.code) && !gone(i)).length;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: loading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        SizedBox(height: Tokens.space[3]),
                        Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(color: Palette.tileBlue, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                            alignment: Alignment.center,
                            child: widget.link.emoji.isEmpty
                                ? const Icon(CupertinoIcons.folder_fill, size: 38, color: Color(0xFFFFFFFF))
                                : Text(widget.link.emoji, style: const TextStyle(fontSize: 36)),
                          ),
                        ),
                        SizedBox(height: Tokens.space[3]),
                        Text(
                          l.folderJoinTitle(widget.link.name),
                          key: const Key('folder-join-name'),
                          textAlign: TextAlign.center,
                          style: Tokens.cardTitle.style.copyWith(color: p.label),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.nameToSub, Tokens.space[4], 0),
                          child: Text(
                            l.folderJoinInfo,
                            textAlign: TextAlign.center,
                            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                          ),
                        ),
                        group(context, header: l.folderJoinChats(items.length), [
                          for (final i in items)
                            IosTile(
                              key: Key('folder-join-${i.code}'),
                              leading: Avatar(
                                name: nameOf(i),
                                size: 30,
                                squircle: true,
                                channel: i.channel || (peeks[i.code]?.channel ?? false),
                                photo: peeks[i.code]?.photo,
                              ),
                              title: Text(nameOf(i), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                gone(i)
                                    ? l.joinNotFound
                                    : joined(i)
                                    ? l.folderJoinIn
                                    : (i.channel || (peeks[i.code]?.channel ?? false))
                                    ? l.channel
                                    : l.group,
                              ),
                              trailing: gone(i)
                                  ? null
                                  : Icon(
                                      left.contains(i.code) ? CupertinoIcons.circle : CupertinoIcons.checkmark_circle_fill,
                                      color: left.contains(i.code) ? p.secondaryLabel : p.accent,
                                    ),
                              onTap: gone(i) ? null : () => setState(() => left.contains(i.code) ? left.remove(i.code) : left.add(i.code)),
                            ),
                        ]),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                    child: CupertinoButton.filled(
                      key: const Key('folder-join-go'),
                      borderRadius: BorderRadius.circular(Tokens.capsule),
                      onPressed: busy || picked == 0 ? null : go,
                      child: SizedBox(
                        width: double.infinity,
                        child: busy
                            ? CupertinoActivityIndicator(color: p.onAccent)
                            : Text(
                                l.folderJoinGo(picked),
                                textAlign: TextAlign.center,
                                style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Opens a folder link if [url] is one (true = handled).
Future<bool> maybeOpenFolderLink(BuildContext context, String url) async {
  final f = FolderLink.parse(url);
  if (f == null) return false;
  unawaited(openFolderLink(context, f));
  return true;
}
