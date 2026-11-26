// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat list (iOS large title, rows scroll under a clear bar).
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'bubbles.dart';
import 'chat_folders.dart';
import 'folders_page.dart' show FolderTag;
import 'chat_page.dart';
import 'wide.dart';
import 'chat_row_actions.dart';
import 'common.dart';
import 'glass.dart';
import 'home.dart';
import 'new_chat_page.dart';
import 'stories.dart';
import 'profile_page.dart' show SharedThumb;
import 'ios_route.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String query = '';

  /// 'all', 'unread', 'direct', 'group', 'channel', 'bot' or 'folder:<id>'.
  String filter = 'all';
  bool menu = false;

  /// 스토리 → 비눗방울 → 보관함 sit on top of the list as three tiers
  /// (Eric 2026-11-26). Scrolling up tucks them away one at a time, as far
  /// as the finger goes: the stories fly into the bar left of the title
  /// (Telegram), the bubbles to its right, the archive row just slides up.
  /// Let go inside a tier and it snaps open or shut at the halfway mark,
  /// so a small nudge no longer hides anything. Pulling down brings them
  /// back in the other order.
  final scroll = ScrollController();
  final listY = ValueNotifier<double>(0);
  final listKey = GlobalKey();
  final tierKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  /// Per tier: the list offset where it starts going under the bar, and its
  /// height (0 when the tier is not shown).
  List<(double, double)> tiers = const [];

  /// The current scroll started with a finger (a mouse wheel is not snapped).
  bool dragged = false;

  bool onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    listY.value = n.metrics.pixels;
    if (n is ScrollStartNotification) dragged = n.dragDetails != null;
    if (n is ScrollEndNotification && dragged) {
      dragged = false;
      Future.microtask(snap);
    }
    return false;
  }

  /// How far tier [i] is tucked away at list offset [at]: 0 open, 1 gone.
  double tucked(int i, double at) {
    if (i >= tiers.length) return 0;
    final (start, height) = tiers[i];
    if (height <= 0) return 0;
    return ((at - start) / height).clamp(0.0, 1.0).toDouble();
  }

  /// Reads where the tiers are (after each build; scrolling moves them all
  /// together, so these offsets stay put).
  void measure() {
    if (!mounted || !scroll.hasClients) return;
    final list = listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.attached || !list.hasSize) return;
    final bar = list.localToGlobal(Offset.zero).dy + MediaQuery.paddingOf(context).top + GlassTopBar.height;
    (double, double) tier(GlobalKey k) {
      final box = k.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return (0.0, 0.0);
      return (scroll.offset + box.localToGlobal(Offset.zero).dy - bar, box.size.height);
    }

    tiers = [for (final k in tierKeys) tier(k)];
  }

  /// Let go halfway into a tier: it finishes opening or closing.
  void snap() {
    if (!mounted || !scroll.hasClients) return;
    final at = scroll.offset;
    for (final (start, height) in tiers) {
      if (height <= 0) continue;
      // The first tier opens all the way to the top of the list.
      final open = start <= Tokens.space[2] ? 0.0 : start;
      final shut = start + height;
      if (at <= open + 1 || at >= shut - 1) continue;
      final to = at - open < (shut - open) / 2 ? open : shut;
      scroll.animateTo(to, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      return;
    }
  }

  /// Back to the top with every tier open (tapping the faces in the bar).
  void openTiers() {
    if (scroll.hasClients) scroll.animateTo(0, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  /// The bar title, with the tucked-away tiers next to it: story faces on
  /// the left, bubbles on the right. Both sides keep the same room so the
  /// title stays in the middle.
  Widget barTitle(BuildContext context, String text, bool stories, bool bubbles) {
    final p = paletteOf(context);
    final l = L.of(context);
    final app = AppScope.of(context);
    final label = Text(
      text,
      key: const Key('bar-title'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
    );
    if (!stories && !bubbles) return label;
    const mini = 22.0, step = 12.0, slot = mini + 2 * step;
    final faces = <Widget>[];
    if (stories) {
      final groups = storyGroups(app, app.stories);
      final seen = seenStories(app);
      final others = [
        for (final g in groups)
          if (!g.first.mine) g,
      ];
      for (final g in (others.isNotEmpty ? others : groups).take(3)) {
        faces.add(
          Container(
            width: mini,
            height: mini,
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.list,
              border: Border.all(color: g.any((x) => !seen.contains(x.id)) ? p.accent : p.separator, width: 1.5),
            ),
            child: Avatar(name: storyName(app, l, g.first), size: mini - 6, userId: g.first.sender),
          ),
        );
      }
    }
    final drops = <Widget>[
      if (bubbles)
        for (var i = 0; i < app.bubbles.length && i < 3; i++)
          SoapBubble(color: p.accent, size: mini, letter: bubbleName(app.chats, app.bubbles[i]).characters.first, phase: i * 0.37),
    ];
    // Overlapping faces; the first one sits next to the title.
    Widget pile(List<Widget> items, bool leftOfTitle) => SizedBox(
      width: slot,
      height: mini,
      child: Stack(
        children: [
          for (var i = items.length - 1; i >= 0; i--)
            Positioned(left: leftOfTitle ? null : i * step, right: leftOfTitle ? i * step : null, top: 0, child: items[i]),
        ],
      ),
    );
    // Rises from under the bar into place as its tier slides away.
    Widget fly(String key, int tier, double at, List<Widget> items, bool leftOfTitle) {
      final t = tucked(tier, at);
      if (t <= 0 || items.isEmpty) return const SizedBox(width: slot, height: mini);
      return GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: openTiers,
        child: Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((leftOfTitle ? -24 : 24) * (1 - t), 36 * (1 - t)),
            child: Transform.scale(scale: 1.8 - 0.8 * t, child: pile(items, leftOfTitle)),
          ),
        ),
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: listY,
      builder: (context, at, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          fly('stories-mini', 0, at, faces, true),
          SizedBox(width: Tokens.space[0]),
          Flexible(child: label),
          SizedBox(width: Tokens.space[0]),
          fly('bubbles-mini', 1, at, drops, false),
        ],
      ),
    );
  }

  /// A tier fades as it slides under the bar (its faces reappear up there).
  Widget tierFade(int i, Widget child) => ValueListenableBuilder<double>(
    valueListenable: listY,
    builder: (_, at, c) => Opacity(opacity: 1 - tucked(i, at), child: c),
    child: child,
  );

  /// v1 edit mode (⋯): circles to pick chats, handles to order pinned ones,
  /// and 모두 읽음 / 보관 / 삭제 at the bottom instead of the tab bar.
  bool editing = false;
  final picked = <String>{};

  void startEdit() {
    HomeTabs.hideBar.value = true;
    setState(() {
      editing = true;
      menu = false;
    });
  }

  void endEdit() {
    HomeTabs.hideBar.value = false;
    setState(() {
      editing = false;
      picked.clear();
    });
  }

  /// The left menu covers the whole height, so the tab bar steps aside
  /// (nothing in the menu hides under it).
  void setMenu(bool on) {
    if (!editing) HomeTabs.hideBar.value = on;
    setState(() => menu = on);
  }

  @override
  void dispose() {
    HomeTabs.hideBar.value = false;
    scroll.dispose();
    listY.dispose();
    super.dispose();
  }

  Future<void> editAction(String what, List<ChatPreview> shown) async {
    final app = AppScope.of(context);
    final b = app.backend;
    final ids = picked.toList();
    endEdit();
    switch (what) {
      case 'read':
        for (final c in ids.isEmpty ? app.chats.where((c) => c.unread > 0).map((c) => c.roomId) : ids) {
          await b.markRead(c);
        }
      case 'archive':
        for (final id in ids) {
          await b.setChatArchived(id, true);
        }
      case 'delete':
        PendingDelete.startMany(app, ids);
        return;
    }
    await app.refresh();
  }

  /// Pinned chats keep the order I drag them into.
  Future<void> reorderPinned(List<ChatPreview> shown, int from, int to) async {
    final app = AppScope.of(context);
    final pins = [
      for (final c in shown)
        if (c.pinned) c.roomId,
    ];
    final offset = shown.indexWhere((c) => c.pinned);
    if (offset < 0) return;
    final a = from - offset, z = (to > from ? to - 1 : to) - offset;
    if (a < 0 || a >= pins.length || z < 0 || z >= pins.length) return;
    pins.insert(z, pins.removeAt(a));
    for (final id in pins) {
      await app.backend.setChatPinned(id, false);
      await app.backend.setChatPinned(id, true);
    }
    await app.refresh();
  }

  Widget editBar(BuildContext context, List<ChatPreview> shown) {
    final l = L.of(context);
    final p = paletteOf(context);
    final any = picked.isNotEmpty;
    Widget button(String key, String label, VoidCallback? onTap, {Color? color}) => GestureDetector(
      key: Key(key),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: LiquidGlass(
        radius: Tokens.capsule,
        child: Container(
          // Telegram measured: 44 pt tall, 12 pt either side of the word.
          height: Tokens.closeButton,
          constraints: const BoxConstraints(minWidth: Tokens.closeButton),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Tokens.body.style.copyWith(color: (color ?? p.label).withValues(alpha: onTap == null ? 0.35 : 1)),
          ),
        ),
      ),
    );
    return Padding(
      key: const Key('list-edit-bar'),
      // Same place as the tab bar it replaces: 21 pt from the sides and bottom.
      padding: EdgeInsets.fromLTRB(FloatingTabBar.edge, 0, FloatingTabBar.edge, FloatingTabBar.bottomGap(context)),
      child: Row(
        children: [
          button('edit-read', any ? l.markRead : l.markAllRead, () => editAction('read', shown)),
          const Spacer(),
          button('edit-archive', l.archiveShort, any ? () => editAction('archive', shown) : null),
          const Spacer(),
          button('edit-delete', l.delete, any ? () => editAction('delete', shown) : null, color: Palette.tileRed),
        ],
      ),
    );
  }

  Future<void> newChat(BuildContext context) async {
    await openSheet<void>(context, (_) => const NewChatPage());
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final app = AppScope.of(context);
    final all = app.chats;
    final q = query.trim().toLowerCase();
    // 스토리 / 비눗방울 strips: pulled all the way left, they move into the
    // side menu (Eric 2026-11-25), like 보관함.
    Widget toMenu(String id, String pref, String title, Widget strip) => SwipeRow(
      key: Key('$id-swipe'),
      leftItems: const [],
      rightItems: [('$id-menu', l.archiveToMenu, CupertinoIcons.sidebar_left, p.tileGreen)],
      onAction: (_) {
        app.setOn(pref, true);
        showInfoBanner(context, title, l.archiveMovedBody);
      },
      child: strip,
      color: p.list,
    );
    final showStories = q.isEmpty && !editing && all.isNotEmpty && !app.on(storiesInMenuPref);
    final showBubbles = q.isEmpty && !editing && app.bubbles.isNotEmpty && !app.on(bubblesInMenuPref);
    WidgetsBinding.instance.addPostFrameCallback((_) => measure());
    // Searching looks through every chat, archived ones too.
    final chats = q.isEmpty
        ? [
            for (final c in all)
              if (!c.archived && !app.on(hiddenKey(c.roomId)) && takes(app, filter, c)) c,
          ]
        : [
            for (final c in all)
              if (c.name.toLowerCase().contains(q)) c,
          ];
    final archived = [
      for (final c in all)
        if (c.archived) c,
    ];
    final top = app.on('list_top');
    final folders = foldersOf(app);
    final width = MediaQuery.sizeOf(context).width * 2 / 3;
    final page = CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar(
        title: filterTitle(app, l, filter),
        middle: barTitle(context, filterTitle(app, l, filter), showStories, showBubbles),
        leading: editing
            ? [GlassPill(key: const Key('list-edit-done'), text: l.done, onTap: endEdit)]
            : [
                GlassCircle(key: const Key('chats-menu'), onTap: startEdit, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)),
                GlassCircle(key: const Key('side-menu-button'), onTap: () => setMenu(!menu), child: GlassCircle.icon(context, CupertinoIcons.sidebar_left)),
              ],
        trailing: editing
            ? const []
            : [
                // v1: camera (stories) next to "new chat".
                GlassCircle(
                  key: const Key('story-camera'),
                  onTap: () async {
                    await newStory(context);
                    await app.refresh();
                  },
                  child: GlassCircle.icon(context, CupertinoIcons.camera),
                ),
                GlassCircle(key: const Key('new-chat'), onTap: () => newChat(context), child: GlassCircle.icon(context, CupertinoIcons.square_pencil)),
              ],
      ),
      child: Stack(
        children: [
          KeyedSubtree(
            key: listKey,
            child: NotificationListener<ScrollNotification>(
              onNotification: onScroll,
              child: CustomScrollView(
                controller: scroll,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[1])),
                  if (all.isNotEmpty && top)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
                        child: CupertinoSearchTextField(
                          borderRadius: const BorderRadius.all(Radius.circular(18)),
                          key: const Key('chat-search'),
                          placeholder: l.searchChats,
                          onChanged: (v) => setState(() => query = v),
                        ),
                      ),
                    ),
                  if (top && all.isNotEmpty)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                          children: [
                            // Same choices as the left menu (Telegram folder tabs), then mine.
                            for (final (id, name) in [
                              for (final k in const ['all', 'unread', 'direct', 'group', 'channel', 'bot']) (k, filterName(l, k)),
                              for (final f in folders) ('folder:${f.id}', f.label),
                            ])
                              Padding(
                                padding: EdgeInsets.only(right: Tokens.space[1]),
                                child: GestureDetector(
                                  key: Key('chip-$id'),
                                  onTap: () => setState(() => filter = id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: filter == id ? p.card : const Color(0x00000000),
                                      borderRadius: BorderRadius.circular(Tokens.capsule),
                                      boxShadow: filter == id ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))] : null,
                                    ),
                                    child: Text(name, style: Tokens.preview.style.copyWith(color: filter == id ? p.accent : p.label)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  for (final who in AppScope.of(context).erasedBy)
                    SliverToBoxAdapter(
                      child: Padding(
                        key: Key('erased-$who'),
                        padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
                        child: Container(
                          padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], 0, Tokens.space[1]),
                          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.trash, size: Tokens.listIcon, color: p.secondaryLabel),
                              SizedBox(width: Tokens.space[1]),
                              Expanded(
                                child: Text(l.erasedByFriend(displayId(who)), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => AppScope.of(context).dismissErased(who),
                                child: Icon(CupertinoIcons.xmark, size: Tokens.listIcon - 4, color: p.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  for (final inv in AppScope.of(context).invites)
                    SliverToBoxAdapter(
                      child: InviteRow(key: Key('invite-${inv.roomId}'), invite: inv),
                    ),
                  // Tier 1 스토리, tier 2 비눗방울, tier 3 보관함: each slides up
                  // under the bar on its own (see [tiers]).
                  if (showStories)
                    SliverToBoxAdapter(
                      child: KeyedSubtree(
                        key: tierKeys[0],
                        child: tierFade(
                          0,
                          toMenu('stories', storiesInMenuPref, l.storiesMovedTitle, StoriesBar(stories: app.stories, onChanged: () => app.refresh())),
                        ),
                      ),
                    ),
                  if (showBubbles)
                    SliverToBoxAdapter(
                      child: KeyedSubtree(
                        key: tierKeys[1],
                        child: tierFade(1, toMenu('bubbles', bubblesInMenuPref, l.bubblesMovedTitle, BubbleStrip(bubbles: app.bubbles))),
                      ),
                    ),
                  if (q.isEmpty && !editing && archived.isNotEmpty && !app.on(archiveInMenuPref))
                    SliverToBoxAdapter(
                      child: Column(
                        key: tierKeys[2],
                        children: [
                          SwipeRow(
                            key: const Key('archive-swipe'),
                            leftItems: const [],
                            rightItems: [('archive-menu', l.archiveToMenu, CupertinoIcons.sidebar_left, p.tileGreen)],
                            onAction: (_) {
                              app.setOn(archiveInMenuPref, true);
                              showInfoBanner(context, l.archiveMovedTitle, l.archiveMovedBody);
                            },
                            child: ArchiveRow(chats: archived),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: Tokens.chatAvatar + Tokens.space[3] + Tokens.space[2]),
                            child: Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
                          ),
                        ],
                      ),
                    ),
                  if (all.isEmpty || chats.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          all.isEmpty ? l.chatsEmpty : (q.isEmpty ? '' : l.searchNone),
                          style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                    )
                  else if (editing)
                    EditRows(
                      chats: chats,
                      picked: picked,
                      onToggle: (id) => setState(() => picked.contains(id) ? picked.remove(id) : picked.add(id)),
                      onReorder: (a, z) => reorderPinned(chats, a, z),
                    )
                  else
                    ChatRows(chats: chats),
                  SliverToBoxAdapter(child: SizedBox(height: FloatingTabBar.room(context))),
                ],
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: FloatingTabBar.room(context) + Tokens.space[1], child: const DeleteUndoBar()),
          if (editing) Positioned(left: 0, right: 0, bottom: 0, child: editBar(context, chats)),
        ],
      ),
    );
    // Side menu: a card from the left that pushes the list aside.
    const d = Duration(milliseconds: 280);
    return Stack(
      children: [
        AnimatedPositioned(
          duration: d,
          curve: Curves.easeOutCubic,
          left: menu ? width : 0,
          right: menu ? -width : 0,
          top: 0,
          bottom: 0,
          child: Stack(
            children: [
              page,
              if (menu)
                Positioned.fill(
                  child: GestureDetector(
                    key: const Key('side-menu-close'),
                    onTap: () => setMenu(false),
                    // Swipe back to the left also closes it.
                    onHorizontalDragUpdate: (e) {
                      if (e.delta.dx < -4) setMenu(false);
                    },
                  ),
                ),
            ],
          ),
        ),
        // Drag from the left screen edge opens the side menu (Telegram-like).
        if (!menu)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: Tokens.space[4],
            child: GestureDetector(
              key: const Key('side-menu-edge'),
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (e) {
                if (e.delta.dx > 2) setMenu(true);
              },
            ),
          ),
        AnimatedPositioned(
          duration: d,
          curve: Curves.easeOutCubic,
          left: menu ? 0 : -width - 30,
          width: width,
          top: 0,
          bottom: 0,
          child: SideMenu(
            filter: filter,
            onPick: (f) {
              filter = f;
              setMenu(false);
            },
            onSearch: (v) => setState(() => query = v),
          ),
        ),
      ],
    );
  }
}

/// The rows themselves (main list and archive share them).
class ChatRows extends StatelessWidget {
  const ChatRows({super.key, required this.chats});
  final List<ChatPreview> chats;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return ValueListenableBuilder<(String, int)?>(
      valueListenable: PendingDelete.notifier,
      builder: (context, pending, _) {
        final shown = [
          for (final c in chats)
            if (pending == null || !PendingDelete.ids.contains(c.roomId)) c,
        ];
        return SliverList.separated(
          itemCount: shown.length,
          separatorBuilder: (_, _) => Padding(
            padding: EdgeInsets.only(left: Tokens.chatAvatar + Tokens.space[3] + Tokens.space[2]),
            child: Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
          ),
          itemBuilder: (c, i) => SwipeRow(
            key: ValueKey('swipe-${shown[i].roomId}'),
            chat: shown[i],
            child: ChatPressMenu(
              chat: shown[i],
              child: ChatRowTile(chat: shown[i]),
            ),
          ),
        );
      },
    );
  }
}

/// Edit mode rows: a circle on the left, the row, and on pinned chats a
/// handle to drag them into order (v1, iOS Mail).
class EditRows extends StatelessWidget {
  const EditRows({super.key, required this.chats, required this.picked, required this.onToggle, required this.onReorder});
  final List<ChatPreview> chats;
  final Set<String> picked;
  final void Function(String roomId) onToggle;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return SliverReorderableList(
      itemCount: chats.length,
      onReorder: onReorder,
      itemBuilder: (c, i) {
        final chat = chats[i];
        return Column(
          key: ValueKey('edit-${chat.roomId}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i > 0)
              Padding(
                padding: EdgeInsets.only(left: Tokens.space[2] + 32 + Tokens.space[3] + Tokens.chatAvatar + Tokens.space[2]),
                child: Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
              ),
            GestureDetector(
              key: Key('edit-row-${chat.roomId}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(chat.roomId),
              child: ColoredBox(
                color: p.list,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: Tokens.space[2]),
                      child: SelectCircle(on: picked.contains(chat.roomId)),
                    ),
                    Expanded(
                      child: IgnorePointer(child: ChatRowTile(chat: chat)),
                    ),
                    if (chat.pinned)
                      ReorderableDragStartListener(
                        index: i,
                        child: Padding(
                          key: Key('edit-drag-${chat.roomId}'),
                          padding: EdgeInsets.only(right: Tokens.space[3]),
                          child: Icon(CupertinoIcons.line_horizontal_3, color: p.secondaryLabel, size: Tokens.listIcon),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// "Archived Chats" row on top of the list (iOS folder style).
class ArchiveRow extends StatelessWidget {
  const ArchiveRow({super.key, required this.chats});
  final List<ChatPreview> chats;

  static const height = 62.0, icon = 48.0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final unread = chats.where((c) => c.unread > 0 && !c.muted).length;
    return GestureDetector(
      key: const Key('archive-row'),
      behavior: HitTestBehavior.opaque,
      onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => const ArchivePage())),
      child: Container(
        // Lower than a chat row, one line of names: the gap down to the
        // first chat (저장한 메시지) was too wide (Eric 2026-11-26).
        height: ArchiveRow.height,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            // Same width as a chat photo, so the names line up with the chats.
            SizedBox(
              width: Tokens.chatAvatar,
              child: Center(
                child: Container(
                  width: ArchiveRow.icon,
                  height: ArchiveRow.icon,
                  // Telegram: the pinned archive wears the theme colour (green / blue).
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(p.tileGreen, const Color(0xFFFFFFFF), 0.18)!, p.tileGreen],
                    ),
                  ),
                  child: const Icon(CupertinoIcons.archivebox_fill, color: Color(0xFFFFFFFF), size: 24),
                ),
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.archive,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Text(
                    chats.map((c) => c.name).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            if (unread > 0) UnreadBadge(count: unread, muted: true),
          ],
        ),
      ),
    );
  }
}

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final chats = [
      for (final c in AppScope.of(context).chats)
        if (c.archived) c,
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.archive), border: null, backgroundColor: p.list.withValues(alpha: 0.0)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (chats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(l.archiveEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ),
              )
            else ...[
              ChatRows(chats: chats),
              SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(Tokens.space[3]), child: sectionFooter(context, l.archiveFooter)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.muted = false});
  final int count;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[0] + 2, vertical: 1),
      // Muted chats keep a grey count, like iOS Messages / Telegram.
      decoration: BoxDecoration(color: muted ? p.secondaryLabel.withValues(alpha: 0.45) : p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: Tokens.caption.style.copyWith(color: p.onAccent),
      ),
    );
  }
}

class ChatRowTile extends StatelessWidget {
  const ChatRowTile({super.key, required this.chat});
  final ChatPreview chat;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final cut = clearedAt(s, chat.roomId);
    final last = cut != null && chat.last != null && !chat.last!.time.isAfter(cut) ? null : chat.last;
    final name = nameOf(s, chat);
    return ValueListenableBuilder<String?>(valueListenable: Wide.selected, builder: (context, _, _) => row(context, p, s, name, last));
  }

  Widget row(BuildContext context, Palette p, AppState s, String name, Msg? last) {
    final tags = tagsOf(s, chat);
    final thumb = last != null && !last.viewOnce && (last.kind == 'image' || last.kind == 'video') && s.on('list_media') && s.autoDownload;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openChat(context, chat.roomId, name),
      child: Container(
        height: Tokens.chatRow,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        // Two panes: the chat open on the right is marked (iPad style).
        decoration: Wide.on && Wide.selected.value == chat.roomId ? BoxDecoration(color: p.incoming) : null,
        child: Row(
          children: [
            Avatar(
              name: name,
              size: Tokens.chatAvatar,
              squircle: !chat.isDirect,
              userId: chat.isDirect ? chat.peer : null,
              roomId: chat.roomId,
              owner: chat.isChannel ? chat.peer : null,
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // text centred in the 76pt row, like Telegram
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (chat.muted)
                              Padding(
                                padding: const EdgeInsets.only(left: 3),
                                child: Icon(CupertinoIcons.bell_slash_fill, key: const Key('muted'), size: 13, color: p.secondaryLabel),
                              ),
                          ],
                        ),
                      ),
                      if (chat.streak > 0) StreakBadge(days: chat.streak, atRisk: chat.streakAtRisk),
                      // Telegram: my last message gets one tick (sent) or two (read),
                      // 1:1 only, and only when read receipts go both ways.
                      if (last != null && last.mine && chat.isDirect && !chat.isChannel) ListTick(roomId: chat.roomId, at: last.time),
                      if (last != null) Text(shortTime(context, last.time), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Always room for two lines, like iPhone Messages and
                      // Telegram, so every row is the same height.
                      Expanded(
                        child: SizedBox(
                          height: Tokens.preview.lineHeight * 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Settings > Chats > Photo and video previews (v1).
                                  if (thumb)
                                    Padding(
                                      padding: EdgeInsets.only(right: Tokens.space[0], top: 1),
                                      child: SizedBox(
                                        key: const Key('list-thumb'),
                                        width: 20,
                                        height: 20,
                                        child: SharedThumb(roomId: chat.roomId, msg: last),
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      last == null
                                          ? ''
                                          : (last.bubble
                                                ? L.of(context).attachBubble
                                                : previewText(context, kind: last.kind, body: last.body, caption: last.caption)),
                                      maxLines: tags.isEmpty ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                    ),
                                  ),
                                ],
                              ),
                              // Folder tags (Telegram): one line under the preview.
                              if (tags.isNotEmpty)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      key: const Key('folder-tags-row'),
                                      children: [
                                        for (final f in tags.take(3))
                                          Flexible(
                                            child: Padding(
                                              padding: const EdgeInsets.only(right: 4),
                                              child: FolderTag(text: f.label, color: folderColors[f.color]),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (chat.unread > 0)
                        UnreadBadge(count: chat.unread, muted: chat.muted)
                      else if (chat.pinned)
                        Icon(CupertinoIcons.pin_fill, key: const Key('pinned'), size: 15, color: p.secondaryLabel),
                    ],
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

/// Streak mark next to a 1:1 name: flame + days; an hourglass when it
/// ends tonight unless both write.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, required this.atRisk});
  final int days;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    const flame = Palette.tileOrange;
    return Padding(
      key: const Key('streak'),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.flame_fill, size: 15, color: atRisk ? flame.withValues(alpha: 0.55) : flame),
          const SizedBox(width: 2),
          Text('$days', style: Tokens.caption.style.copyWith(color: atRisk ? p.secondaryLabel : flame)),
          if (atRisk) ...[const SizedBox(width: 2), Icon(CupertinoIcons.hourglass, key: const Key('streak-risk'), size: 13, color: p.secondaryLabel)],
        ],
      ),
    );
  }
}

/// A group or channel invitation: join or decline.
class InviteRow extends StatefulWidget {
  const InviteRow({super.key, required this.invite});
  final Invite invite;

  @override
  State<InviteRow> createState() => _InviteRowState();
}

class _InviteRowState extends State<InviteRow> {
  bool busy = false;

  Future<void> run(Future<void> Function() f) async {
    setState(() => busy = true);
    try {
      await f();
    } catch (_) {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final app = AppScope.of(context);
    final inv = widget.invite;
    final name = inv.name.isEmpty ? displayId(inv.inviter) : inv.name;
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
      child: Container(
        padding: EdgeInsets.all(Tokens.space[2]),
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          children: [
            Avatar(name: name, size: 44, squircle: true),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: p.label),
                  ),
                  Text(
                    l.inviteFrom(displayId(inv.inviter)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            if (busy)
              const CupertinoActivityIndicator()
            else ...[
              CupertinoButton(
                key: Key('decline-${inv.roomId}'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                minimumSize: const Size(0, 32),
                onPressed: () => run(() => app.declineInvite(inv.roomId)),
                child: Text(l.inviteDecline, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
              ),
              CupertinoButton(
                key: Key('accept-${inv.roomId}'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                minimumSize: const Size(0, 32),
                color: p.accent,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => run(() => app.acceptInvite(inv.roomId)),
                child: Text(l.inviteAccept, style: Tokens.body.style.copyWith(color: const Color(0xFFFFFFFF))),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One green tick (sent) or two (read) in front of the time in a chat row.
class ListTick extends StatefulWidget {
  const ListTick({super.key, required this.roomId, required this.at});
  final String roomId;
  final DateTime at;

  @override
  State<ListTick> createState() => _ListTickState();
}

class _ListTickState extends State<ListTick> {
  bool read = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    load();
  }

  @override
  void didUpdateWidget(ListTick old) {
    super.didUpdateWidget(old);
    if (old.at != widget.at || old.roomId != widget.roomId) load();
  }

  Future<void> load() async {
    final until = await AppScope.read(context).backend.readUntil(widget.roomId).catchError((_) => null);
    final r = until != null && !widget.at.isAfter(until);
    if (mounted && r != read) setState(() => read = r);
  }

  @override
  Widget build(BuildContext context) {
    final c = paletteOf(context).accent;
    final tick = Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIconSmall, color: c);
    return Padding(
      padding: EdgeInsets.only(right: Tokens.space[0]),
      child: read
          ? SizedBox(
              key: const Key('list-tick-read'),
              width: Tokens.listIconSmall + Tokens.space[1] - 2,
              height: Tokens.listIconSmall,
              child: Stack(
                children: [
                  tick,
                  Positioned(left: Tokens.space[1] - 2, child: tick),
                ],
              ),
            )
          : KeyedSubtree(key: const Key('list-tick-sent'), child: tick),
    );
  }
}
