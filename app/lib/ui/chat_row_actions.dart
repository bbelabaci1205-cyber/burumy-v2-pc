// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Things you do to one chat in the list: Telegram iOS swipe buttons, the
// iOS long-press preview with its menu, delete with 5 s undo, and hiding a
// chat from the list.
import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_state.dart';
import '../core/backend.dart';
import '../brand/brand.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_folders.dart';
import 'folders_page.dart';
import 'common.dart';
import 'glass.dart';
import 'wallpaper.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_menu.dart';
import 'message_sheets.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// One chat waiting to be deleted (5 s to undo), shared by the list and
/// the archive.
class PendingDelete {
  PendingDelete._();

  /// First chat waiting and the seconds left ([ids] has all of them).
  static final notifier = ValueNotifier<(String, int)?>(null);
  static List<String> ids = const [];
  static Timer? _timer;

  static bool has(String roomId) => notifier.value != null && ids.contains(roomId);

  static void start(AppState app, String roomId) => startMany(app, [roomId]);

  /// Several chats at once (list edit mode), one undo for all.
  static void startMany(AppState app, List<String> list) {
    if (list.isEmpty) return;
    _timer?.cancel();
    ids = List.of(list);
    notifier.value = (list.first, 5);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final v = notifier.value;
      if (v == null) return t.cancel();
      if (v.$2 > 1) {
        notifier.value = (v.$1, v.$2 - 1);
        return;
      }
      t.cancel();
      for (final id in ids) {
        try {
          await app.backend.leave(id);
        } catch (_) {}
      }
      notifier.value = null;
      ids = const [];
      await app.refresh();
    });
  }

  static void undo() {
    _timer?.cancel();
    notifier.value = null;
    ids = const [];
  }
}

/// Key of the per-chat "hide from the list" switch.
String hiddenKey(String roomId) => 'list_hidden:$roomId';

/// Runs one action on a chat ('read', 'pin', 'mute', 'archive', 'hide',
/// 'delete').
Future<void> runChatAction(BuildContext context, ChatPreview chat, String what) async {
  final app = AppScope.of(context);
  final b = app.backend;
  switch (what) {
    case 'read':
      await app.setOn('marked_unread:${chat.roomId}', false);
      await b.markRead(chat.roomId);
    case 'unread':
      await app.setOn('marked_unread:${chat.roomId}', true);
    case 'pin':
      await b.setChatPinned(chat.roomId, !chat.pinned);
    case 'mute':
      await b.setChatMuted(chat.roomId, !chat.muted);
    case 'archive':
      await b.setChatArchived(chat.roomId, !chat.archived);
    case 'hide':
      await app.setOn(hiddenKey(chat.roomId), true);
    case 'delete':
      PendingDelete.start(app, chat.roomId);
      return;
    default:
      return;
  }
  await app.refresh();
}

/// A row that slides sideways to show Telegram-style buttons: read and pin
/// on the left, mute, delete and archive on the right.
class SwipeRow extends StatefulWidget {
  const SwipeRow({super.key, this.chat, required this.child, this.leftItems, this.rightItems, this.onAction, this.color});
  final ChatPreview? chat;
  final Widget child;

  /// Other rows (보관함): their own buttons and what they do.
  final List<(String, String, IconData, Color)>? leftItems, rightItems;
  final ValueChanged<String>? onAction;

  /// Row colour at rest (list white unless it sits on a card).
  final Color? color;
  @override
  State<SwipeRow> createState() => _SwipeRowState();
}

class _SwipeRowState extends State<SwipeRow> with SingleTickerProviderStateMixin {
  /// Telegram iOS (measured from Eric's 2026-11-25 shots at 393 pt): 50 pt
  /// circles 60 pt apart, the outer circle centre 35 pt from the edge, so
  /// 10 pt from the screen edge and 10 pt from the slid row. Pulled further,
  /// each button keeps an equal share and sits in its middle (balanced).
  static const button = 60.0, pad = 5.0, dot = 50.0, full = 48.0;
  late final anim = AnimationController.unbounded(vsync: this);
  double get dx => anim.value;

  List<(String, String, IconData, Color)> left(L l, Palette p) =>
      widget.leftItems ??
      [
        if (widget.chat!.unread > 0) ('read', l.markRead, CupertinoIcons.chat_bubble_fill, Palette.tileBlue),
        ('pin', widget.chat!.pinned ? l.swipeUnpin : l.swipePin, widget.chat!.pinned ? CupertinoIcons.pin_slash_fill : CupertinoIcons.pin_fill, p.tileGreen),
      ];

  List<(String, String, IconData, Color)> right(L l) =>
      widget.rightItems ??
      [
        (
          'mute',
          widget.chat!.muted ? l.swipeUnmute : l.swipeMute,
          widget.chat!.muted ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill,
          Palette.tileOrange,
        ),
        ('delete', l.delete, CupertinoIcons.trash_fill, Palette.tileRed),
        ('archive', widget.chat!.archived ? l.swipeUnarchive : l.swipeArchive, CupertinoIcons.archivebox_fill, Palette.tileGrey),
      ];

  void run(String id) => widget.onAction != null ? widget.onAction!(id) : runChatAction(context, widget.chat!, id);

  void settle(double to) => anim.animateTo(to, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);

  @override
  void dispose() {
    anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ls = left(l, p);
    final rs = right(l);
    final maxL = ls.length * button + pad * 2, maxR = rs.length * button + pad * 2;
    // Pulled past the buttons: one long capsule, and letting go runs the
    // outer action (Telegram: archive on the right, the first on the left).
    // Read live (build() does not rerun while the row moves).
    bool fullL() => dx > maxL + full;
    bool fullR() => -dx > maxR + full;
    Widget circle((String, String, IconData, Color) it) => GestureDetector(
      key: Key('swipe-${it.$1}'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        settle(0);
        run(it.$1);
      },
      // Telegram iOS: a small coloured circle, the word under it.
      child: SizedBox(
        width: button,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(color: it.$4, shape: BoxShape.circle),
              child: Icon(it.$3, color: const Color(0xFFFFFFFF), size: 24),
            ),
            SizedBox(height: Tokens.space[0]),
            // Never cut: a long word shrinks a little to fit its button.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(it.$2, maxLines: 1, softWrap: false, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
          ],
        ),
      ),
    );
    Widget buttons(List<(String, String, IconData, Color)> items, {required bool start}) {
      final long = start ? fullL() : fullR();
      final edge = start ? items.first : items.last;
      if (long) {
        // Telegram: one capsule as tall as the circles and at their height
        // (an empty word line under it keeps them level), 10 pt from the
        // screen edge and from the row, icon on the row side.
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: pad * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                key: const Key('swipe-full'),
                duration: const Duration(milliseconds: 120),
                height: dot,
                decoration: BoxDecoration(color: edge.$4, borderRadius: BorderRadius.circular(dot / 2)),
                alignment: start ? Alignment.centerRight : Alignment.centerLeft,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                child: Icon(edge.$3, color: const Color(0xFFFFFFFF), size: 26),
              ),
              SizedBox(height: Tokens.space[0]),
              Text(' ', style: Tokens.caption.style),
            ],
          ),
        );
      }
      final ep = math.min(pad, dx.abs() / 2);
      final slot = (dx.abs() - ep * 2) / items.length;
      return Row(
        mainAxisAlignment: start ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          SizedBox(width: ep),
          for (final it in items)
            SizedBox(
              width: slot,
              child: OverflowBox(minWidth: button, maxWidth: button, child: circle(it)),
            ),
          SizedBox(width: ep),
        ],
      );
    }

    void end(double v) {
      if (fullL() || fullR()) {
        final it = fullL() ? ls.first : rs.last;
        settle(0);
        run(it.$1);
        return;
      }
      if (dx > 0) settle(dx > maxL / 2 || v > 400 ? maxL : 0);
      if (dx < 0) settle(dx < -maxR / 2 || v < -400 ? -maxR : 0);
    }

    double reach() => math.max((context.size?.width ?? 0) - Tokens.sideStrip, full * 3);
    void move(double by) => anim.value = (dx + by).clamp(rs.isEmpty ? 0.0 : -math.max(reach(), maxR + full), ls.isEmpty ? 0.0 : math.max(reach(), maxL + full));

    final r = Radius.circular(Tokens.radius[3]);
    // A strip that scrolls sideways (스토리, 비눗방울): pulled past its end,
    // the row itself moves.
    final inner = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis != Axis.horizontal) return false;
        if (n is OverscrollNotification && n.dragDetails != null) move(-n.overscroll);
        if (n is ScrollEndNotification && dx != 0) end(0);
        return false;
      },
      child: widget.child,
    );
    return GestureDetector(
      // Telegram (Eric 2026-11-25 "여기까지 당겨 줘"): the row can be pulled
      // almost all the way, leaving a side strip, and the capsule fills it.
      onHorizontalDragUpdate: (d) => move(d.delta.dx),
      onHorizontalDragEnd: (d) => end(d.primaryVelocity ?? 0),
      child: AnimatedBuilder(
        animation: anim,
        builder: (_, child) => ClipRect(
          child: Stack(
            children: [
              if (dx != 0)
                Positioned.fill(
                  // Only the opened strip, so things line up with the row edge.
                  child: Align(
                    alignment: dx > 0 ? Alignment.centerLeft : Alignment.centerRight,
                    child: SizedBox(
                      width: dx.abs(),
                      child: buttons(dx > 0 ? ls : rs, start: dx > 0),
                    ),
                  ),
                ),
              Transform.translate(
                offset: Offset(dx, 0),
                // The moving edge of the row is rounded while it is open.
                child: ClipRRect(
                  borderRadius: dx == 0 ? BorderRadius.zero : (dx > 0 ? BorderRadius.horizontal(left: r) : BorderRadius.horizontal(right: r)),
                  // Built here (not once outside) so it follows the live
                  // offset: while open, a tap closes the row instead of
                  // opening the chat.
                  // Telegram: the pulled row turns light grey.
                  child: ColoredBox(
                    color: dx == 0 ? (widget.color ?? p.list) : Color.alphaBlend(p.incoming, p.list),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: dx == 0 ? null : () => settle(0),
                      child: AbsorbPointer(absorbing: dx != 0, child: child),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        child: inner,
      ),
    );
  }
}

/// Telegram-style black banner above the tab bar: an (i), a title and one
/// line under it; goes away by itself.
void showInfoBanner(BuildContext context, String title, String body) {
  final o = Overlay.of(context, rootOverlay: true);
  final e = OverlayEntry(
    builder: (c) => Positioned(
      left: Tokens.space[3],
      right: Tokens.space[3],
      bottom: FloatingTabBar.room(c) + Tokens.space[2],
      child: Container(
        key: const Key('info-banner'),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: const Color(0xE6333333), borderRadius: BorderRadius.circular(Tokens.radius[3])),
        child: Row(
          children: [
            const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFFFFFFFF), size: 28),
            SizedBox(width: Tokens.space[3]),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w500, decoration: TextDecoration.none),
                  ),
                  Text(
                    body,
                    style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF), decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  o.insert(e);
  Timer(const Duration(milliseconds: 3000), () {
    if (e.mounted) e.remove();
  });
}

/// 보관함 row: in the chat list, or moved to the side menu (Eric 2026-11-25:
/// Telegram's swipe on the archive row, but it goes to the left menu).
const archiveInMenuPref = 'archive_in_menu';
const storiesInMenuPref = 'stories_in_menu';
const bubblesInMenuPref = 'bubbles_in_menu';

/// Bar above the tab bar while a chat waits to be deleted.
class DeleteUndoBar extends StatelessWidget {
  const DeleteUndoBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ValueListenableBuilder<(String, int)?>(
      valueListenable: PendingDelete.notifier,
      builder: (_, v, _) {
        if (v == null) return const SizedBox.shrink();
        return Container(
          key: const Key('list-undo-bar'),
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
          decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Row(
            children: [
              Expanded(
                child: Text(l.deletingIn(v.$2), style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF))),
              ),
              CupertinoButton(
                key: const Key('list-undo'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                minimumSize: const Size(0, 36),
                onPressed: PendingDelete.undo,
                // Light accent on the black toast; blue theme never shows green.
                child: Text(l.undo, style: Tokens.body.style.copyWith(color: Brand.accent(paletteOf(context).family, Brightness.dark))),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Long press on a chat: a preview of its last messages on the chat's own
/// background (nothing is marked read) and the v1 menu under it, icons on
/// the left (Eric 2026-11-24).
class ChatPressMenu extends StatelessWidget {
  const ChatPressMenu({super.key, required this.chat, required this.child});
  final ChatPreview chat;
  final Widget child;

  Future<void> open(BuildContext context) async {
    final l = L.of(context);
    final app = AppScope.read(context);
    final b = app.backend;
    final c = chat;
    final saved = c.roomId == app.savedRoomId;
    final blocked = c.isDirect && c.peer.isNotEmpty ? (await b.blocked().catchError((_) => const <String>[])).contains(c.peer) : false;
    final ql = kIsWeb ? const <List<String>>[[], []] : await b.quietLists().catchError((_) => const <List<String>>[[], []]);
    final hidden = ql.first.contains(c.roomId), toDelete = ql.last.contains(c.roomId);
    final folders = foldersOf(app);
    if (!context.mounted) return;
    // The preview gives way so the whole menu fits on the screen.
    final mq = MediaQuery.of(context);
    final rows = 11;
    final room = mq.size.height - mq.padding.vertical - rows * 44 - Tokens.space[1] * 4 - Tokens.space[3] * 2;
    final peek = room.clamp(120.0, mq.size.height * 0.4);
    final pick = await showMessageMenu(
      context,
      bubble: ChatPeek(chat: c, height: peek),
      mine: true,
      reactions: const [],
      iconsFirst: true,
      items: [
        c.unread > 0 ? MenuItem('read', l.markRead, CupertinoIcons.envelope_open) : MenuItem('unread', l.markUnread, CupertinoIcons.envelope),
        MenuItem('pin', c.pinned ? l.chatUnpin : l.chatPin, c.pinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin),
        MenuItem('mute', c.muted ? l.chatUnmute : l.chatMute, c.muted ? CupertinoIcons.bell : CupertinoIcons.bell_slash),
        MenuItem('archive', c.archived ? l.chatUnarchive : l.chatArchive, CupertinoIcons.archivebox),
        if (!saved) MenuItem('folder', l.addToFolder, CupertinoIcons.folder_badge_plus),
        if (!saved) MenuItem('hide-room', hidden ? l.emergencyHideRoomOff : l.emergencyHideRoom, CupertinoIcons.lock, group: true),
        if (!saved) MenuItem('delete-room', toDelete ? l.emergencyDeleteOff : l.emergencyDeleteRoom, CupertinoIcons.shield),
        MenuItem('hide', l.hideFromList, CupertinoIcons.eye_slash),
        if (c.isDirect && !saved && c.peer.isNotEmpty) MenuItem('block', blocked ? l.unblock : l.blockShort, CupertinoIcons.nosign),
        MenuItem('clear', l.clearChat, CupertinoIcons.paintbrush),
        MenuItem('delete', l.delete, CupertinoIcons.trash, danger: true),
      ],
    );
    if (pick == null || !context.mounted) return;
    switch (pick) {
      case 'hide-room' || 'delete-room':
        if (kIsWeb) return showEmergencyWebNotice(context);
        final hide = [...ql.first.where((x) => x != c.roomId), if (pick == 'hide-room' && !hidden) c.roomId];
        final del = [...ql.last.where((x) => x != c.roomId), if (pick == 'delete-room' && !toDelete) c.roomId];
        await b.setQuietLists(pick == 'hide-room' ? hide : ql.first, pick == 'delete-room' ? del : ql.last);
        if (!context.mounted) return;
        final on = pick == 'hide-room' ? !hidden : !toDelete;
        showStoryToast(context, pick == 'hide-room' ? (on ? l.emergencyHidden : l.emergencyUnhidden) : (on ? l.emergencyRoomMarked : l.emergencyUnmarked));
      case 'block':
        await b.block(c.peer, !blocked);
      case 'folder':
        await pickFolder(context, folders);
      case 'clear':
        final ok = await showCupertinoModalPopup<bool>(
          useRootNavigator: !Wide.on,
          context: context,
          builder: (x) => IosActionSheet(
            message: Text(l.clearChatInfo),
            actions: [
              CupertinoActionSheetAction(
                key: const Key('clear-ok'),
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(x, true),
                child: Text(l.clearChat),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
          ),
        );
        if (ok == true) await app.setPref('cleared:${c.roomId}', '${DateTime.now().millisecondsSinceEpoch}');
        await app.refresh();
      default:
        if (context.mounted) await runChatAction(context, c, pick);
    }
  }

  /// "폴더에 추가": the folders, each toggles this chat in or out.
  Future<void> pickFolder(BuildContext context, List<ChatFolder> folders) async {
    final l = L.of(context);
    final app = AppScope.read(context);
    final id = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (x) => IosActionSheet(
        title: Text(folders.isEmpty ? l.noFoldersYet : l.addToFolder),
        actions: [
          for (final f in folders)
            CupertinoActionSheetAction(
              key: Key('folder-pick-${f.id}'),
              onPressed: () => Navigator.pop(x, f.id),
              child: Text(f.takes(chat, app.friendIds) ? l.removeFromFolder(f.name) : f.label),
            ),
          CupertinoActionSheetAction(key: const Key('folder-pick-new'), onPressed: () => Navigator.pop(x, ''), child: Text(l.newFolder)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
      ),
    );
    if (id == null || !context.mounted) return;
    if (id.isEmpty) {
      await paneNav(context).push(IosPageRoute<void>(builder: (_) => const FolderEditPage()));
      return;
    }
    final f = folders.firstWhere((x) => x.id == id);
    if (f.takes(chat, app.friendIds)) {
      f.include.remove(chat.roomId);
      if (f.takes(chat, app.friendIds)) f.exclude.add(chat.roomId);
    } else {
      f.exclude.remove(chat.roomId);
      f.include.add(chat.roomId);
      if (context.mounted) showStoryToast(context, l.folderAddedTo);
    }
    await saveFolders(app, folders);
    await app.refresh();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPress: () {
      HapticFeedback.mediumImpact();
      open(context);
    },
    child: child,
  );
}

/// The preview card: the last few messages of a chat.
class ChatPeek extends StatefulWidget {
  const ChatPeek({super.key, required this.chat, this.height});
  final ChatPreview chat;
  final double? height;
  @override
  State<ChatPeek> createState() => _ChatPeekState();
}

class _ChatPeekState extends State<ChatPeek> {
  List<Msg> msgs = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).backend.timeline(widget.chat.roomId, limit: 12).then((m) {
      if (mounted) setState(() => msgs = m);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final size = MediaQuery.sizeOf(context);
    final c = widget.chat;
    return Container(
      key: const Key('chat-peek'),
      width: size.width - Tokens.space[2] * 2,
      height: widget.height ?? size.height * 0.4,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Tokens.radius[3])),
      clipBehavior: Clip.antiAlias,
      // The chat as it looks inside: its background, the name capsule on
      // top, the last messages at the bottom (v1).
      child: ChatWallpaper(
        roomId: c.roomId,
        child: Stack(
          children: [
            // Messages stay under the name capsule, never behind it.
            Positioned.fill(
              top: Tokens.closeButton + Tokens.space[2],
              child: ListView(
                reverse: true,
                padding: EdgeInsets.all(Tokens.space[2]),
                children: [
                  for (final m in msgs.reversed)
                    Align(
                      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] - 2),
                        constraints: BoxConstraints(maxWidth: size.width * 0.6),
                        decoration: BoxDecoration(color: m.mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
                        child: Text(
                          m.viewOnce ? L.of(context).viewOncePhoto : previewText(context, kind: m.kind, body: m.body),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.preview.style.copyWith(color: m.mine ? p.onAccent : p.label),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              top: Tokens.space[2],
              left: 0,
              right: 0,
              child: Center(
                child: LiquidGlass(
                  radius: Tokens.capsule,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[0], Tokens.space[0], Tokens.space[3], Tokens.space[0]),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Avatar(name: c.name, size: 32, squircle: !c.isDirect, userId: c.isDirect ? c.peer : null, roomId: c.roomId),
                        SizedBox(width: Tokens.space[1]),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: size.width * 0.5),
                          child: Text(
                            c.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
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
