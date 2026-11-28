// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Things you do to one chat in the list: Telegram iOS swipe buttons, the
// iOS long-press preview with its menu, delete with 5 s undo, and hiding a
// chat from the list.
import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show LongPressGestureRecognizer, TapGestureRecognizer, kTouchSlop;
import 'package:flutter/physics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_state.dart';
import '../core/backend.dart';
import '../brand/brand.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_folders.dart';
import 'chat_mute_sheet.dart';
import 'chat_page.dart' show Veil, veilOf;
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
      // Swipe: straight off (or back on); the long-press menu offers times.
      chat.muted ? await app.unmuteChat(chat.roomId) : await app.muteChat(chat.roomId, null);
      return;
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

/// Settings > 대화 > 대화 목록 밀기 (Telegram tip 260): the action at the
/// outer end of each side, run by pulling the row all the way. Empty = the
/// usual (Telegram iOS) buttons.
const swipeRightPref = 'swipe_right', swipeLeftPref = 'swipe_left';

/// What a swipe can do, in the settings order.
const swipeActions = ['read', 'pin', 'mute', 'archive', 'delete'];

/// One swipe button: id, word, icon, colour.
(String, String, IconData, Color) swipeButton(BuildContext context, ChatPreview c, String id) {
  final l = L.of(context);
  final p = paletteOf(context);
  return switch (id) {
    'read' =>
      c.unread > 0
          ? ('read', l.markRead, CupertinoIcons.chat_bubble_fill, Palette.tileBlue)
          : ('unread', l.swipeUnread, CupertinoIcons.chat_bubble_fill, Palette.tileBlue),
    'pin' => ('pin', c.pinned ? l.swipeUnpin : l.swipePin, c.pinned ? CupertinoIcons.pin_slash_fill : CupertinoIcons.pin_fill, p.tileGreen),
    'mute' => ('mute', c.muted ? l.swipeUnmute : l.swipeMute, c.muted ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill, Palette.tileOrange),
    'archive' => ('archive', c.archived ? l.swipeUnarchive : l.swipeArchive, CupertinoIcons.archivebox_fill, Palette.tileGrey),
    _ => ('delete', l.delete, CupertinoIcons.trash_fill, Palette.tileRed),
  };
}

/// Buttons for pulling right (read, pin) and left (mute, delete, archive);
/// a chosen action goes to the outer end of its side and leaves the other.
(List<(String, String, IconData, Color)>, List<(String, String, IconData, Color)>) swipeSides(BuildContext context, ChatPreview c) {
  final s = AppScope.of(context);
  final lead = s.pref(swipeRightPref, ''), trail = s.pref(swipeLeftPref, '');
  final l = [
    if (lead.isNotEmpty) lead,
    for (final x in [if (c.unread > 0 || lead == 'read') 'read', 'pin'])
      if (x != lead && x != trail) x,
  ];
  final r = [
    for (final x in const ['mute', 'delete', 'archive'])
      if (x != lead && x != trail) x,
    if (trail.isNotEmpty) trail,
  ];
  return ([for (final x in l) swipeButton(context, c, x)], [for (final x in r) swipeButton(context, c, x)]);
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

  List<(String, String, IconData, Color)> left(L l, Palette p) => widget.leftItems ?? swipeSides(context, widget.chat!).$1;

  List<(String, String, IconData, Color)> right(L l) => widget.rightItems ?? swipeSides(context, widget.chat!).$2;

  void run(String id) => widget.onAction != null ? widget.onAction!(id) : runChatAction(context, widget.chat!, id);

  /// Telegram: a critically damped spring (about 0.5 s), carried on at the
  /// finger's speed.
  void settle(double to, [double velocity = 0]) {
    const omega = 2 * math.pi / Tokens.rowResponse;
    final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: omega * omega, ratio: 1);
    anim.animateWith(SpringSimulation(spring, dx, to, velocity, tolerance: const Tolerance(distance: 0.5, velocity: 5))).whenComplete(() {
      if (mounted) anim.value = to; // land exactly (closed = 0)
    });
  }

  /// Whether a long pull is armed (for the one tick when that changes).
  bool armed = false;

  /// The row's width, from the last layout.
  double rowWidth = 393;

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
    // Telegram: past the buttons + 20 pt or 52.5 % of the row, whichever is
    // more; a delete at the edge needs nearly the whole row (width − 29).
    double longAt(double open, String edgeId) {
      final w = rowWidth;
      if (edgeId == 'delete') return math.max(open, w - Tokens.rowDeleteGap);
      return math.min(w, math.max(open + Tokens.rowFullExtra, w * Tokens.rowFullShare));
    }

    bool fullL() => ls.isNotEmpty && dx > longAt(maxL, ls.first.$1);
    bool fullR() => rs.isNotEmpty && -dx > longAt(maxR, rs.last.$1);
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
      armed = false;
      if (fullL() || fullR()) {
        final it = fullL() ? ls.first : rs.last;
        settle(0, v);
        run(it.$1);
        return;
      }
      // Telegram: a flick faster than 50 pt/s decides by its direction,
      // otherwise past half the buttons opens.
      if (dx > 0) settle((v.abs() > Tokens.rowFlick ? v > 0 : dx > maxL / 2) ? maxL : 0, v);
      if (dx < 0) settle((v.abs() > Tokens.rowFlick ? v < 0 : dx < -maxR / 2) ? -maxR : 0, v);
    }

    double reach() => math.max((context.size?.width ?? 0) - Tokens.sideStrip, full * 3);
    void move(double by) {
      anim.value = (dx + by).clamp(rs.isEmpty ? 0.0 : -math.max(reach(), maxR + full), ls.isEmpty ? 0.0 : math.max(reach(), maxL + full));
      // Telegram: one light tick when the long pull arms or lets go.
      final now = fullL() || fullR();
      if (now != armed) {
        armed = now;
        HapticFeedback.selectionClick();
      }
    }

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
    return LayoutBuilder(
      builder: (context, box) {
        if (box.maxWidth.isFinite) rowWidth = box.maxWidth;
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
      },
    );
  }
}

/// Telegram-style black banner above the tab bar: an (i), a title and one
/// line under it; goes away by itself.
void showInfoBanner(BuildContext context, String title, String body, {IconData icon = CupertinoIcons.info_circle_fill}) {
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
            Icon(icon, color: const Color(0xFFFFFFFF), size: 28),
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
                  if (body.isNotEmpty)
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
      bubbleTouch: AppScope.of(context).on('veil_list') || veilOf(AppScope.of(context), c.roomId).isNotEmpty,
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
      case 'mute':
        await openMuteSheet(context, c.roomId, muted: c.muted);
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
  Widget build(BuildContext context) => PressLift(onLongPress: () => open(context), child: child);
}

/// iOS context-menu press (Eric 2026-11-26): the row turns light grey the
/// moment a finger rests on it and slowly sinks while held; when the long
/// press lands it springs back a little past full size and the menu opens.
/// A scroll or an early lift just lets it go.
class PressLift extends StatefulWidget {
  const PressLift({super.key, required this.onLongPress, required this.child});
  final Future<void> Function() onLongPress;
  final Widget child;

  /// How far the row sinks while held (4%; it pops back to 101%).
  static const sink = 0.04;

  @override
  State<PressLift> createState() => _PressLiftState();
}

class _PressLiftState extends State<PressLift> with SingleTickerProviderStateMixin {
  late final press = AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0);
  bool down = false, fired = false;
  Offset start = Offset.zero;

  @override
  void dispose() {
    press.dispose();
    super.dispose();
  }

  void letGo() {
    if (!down || fired) return;
    setState(() => down = false);
    press.animateTo(0, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
  }

  Future<void> lift() async {
    fired = true;
    HapticFeedback.mediumImpact();
    // Back up a little past full size, then settle (iOS context-menu pop).
    await press.animateTo(-0.25, duration: const Duration(milliseconds: 130), curve: Curves.easeOut);
    if (!mounted) return;
    await press.animateTo(0, duration: const Duration(milliseconds: 150), curve: Curves.easeInOut);
    if (!mounted) return;
    await widget.onLongPress();
    if (!mounted) return;
    setState(() {
      down = false;
      fired = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Listener(
      onPointerDown: (e) {
        start = e.position;
        fired = false;
        setState(() => down = true);
        // Telegram: still for 0.12 s, then sinks over 0.2 s and the menu
        // opens (0.32 s in all).
        press.animateTo(
          1,
          duration: Tokens.holdTime,
          curve: Interval(Tokens.holdWait.inMilliseconds / Tokens.holdTime.inMilliseconds, 1, curve: Curves.easeOut),
        );
      },
      onPointerMove: (e) {
        if ((e.position - start).distance > kTouchSlop) letGo();
      },
      onPointerUp: (_) => letGo(),
      onPointerCancel: (_) => letGo(),
      child: QuickHold(
        onLongPress: lift,
        child: AnimatedBuilder(
          animation: press,
          child: widget.child,
          builder: (context, c) => Transform.scale(
            scale: 1 - PressLift.sink * press.value,
            child: AnimatedContainer(duration: const Duration(milliseconds: 120), color: down ? p.rowPressed : p.rowPressed.withValues(alpha: 0), child: c),
          ),
        ),
      ),
    );
  }
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
    final s = AppScope.of(context);
    final veiled = s.on('veil_list') ? 'dots' : veilOf(s, c.roomId);
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
                        // 가리기 on: the peek stays covered too (Telegram keeps
                        // spoilers hidden in previews); hold a bubble to read it.
                        child: Veil(
                          mode: veiled,
                          ink: m.mine ? p.onAccent : p.label,
                          child: Text(
                            m.viewOnce
                                ? (m.kind == 'audio' ? L.of(context).onceVoice : L.of(context).viewOncePhoto)
                                : previewText(context, kind: m.kind, body: m.body),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Tokens.preview.style.copyWith(color: m.mine ? p.onAccent : p.label),
                          ),
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

/// A long press that lands after [Tokens.holdTime] (Telegram 0.32 s) instead
/// of Flutter's 0.5 s. Taps and sideways drags around it still work.
class QuickHold extends StatelessWidget {
  const QuickHold({super.key, required this.child, this.onLongPress, this.onTap});
  final Widget child;
  final VoidCallback? onLongPress, onTap;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      if (onLongPress != null)
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(duration: Tokens.holdTime, debugOwner: this),
          (r) => r.onLongPress = onLongPress,
        ),
      if (onTap != null)
        TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(() => TapGestureRecognizer(debugOwner: this), (r) => r.onTap = onTap),
    },
    child: child,
  );
}
