// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat list (iOS large title, rows scroll under a clear bar).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/group_tools.dart';
import 'music_player.dart' show AudioMiniBar;
import '../core/features.dart';
import '../ui/emoji_status.dart' show StatusMark;
import '../core/chat_marks.dart';
import '../core/app_state.dart';
import '../core/channel_dm.dart';
import '../core/backend.dart';
import '../core/login_safety.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'birthday.dart';
import 'bubbles.dart';
import 'chat_folders.dart';
import 'list_thumbs.dart';
import 'login_safety_ui.dart';
import 'look_pages.dart' show TimerMark;
import 'folders_page.dart' show FolderEditPage, FolderTag, FoldersPage;
import 'message_menu.dart' show MenuItem, showMessageMenu;
import 'channel_inbox.dart';
import 'chat_page.dart';
import 'search_page.dart' show openSearch;
import 'community.dart';
import 'wide.dart';
import 'archive_settings.dart';
import 'chat_row_actions.dart';
import '../core/ai_friend.dart';
import '../core/best_friend.dart';
import 'ai_friend_page.dart' show AiFriendRow;
import '../core/memories.dart';
import '../core/shot_alert.dart';
import 'common.dart';
import 'trust_ui.dart';
import 'downloads_ui.dart' show DownloadsButton;
import 'glass.dart';
import 'home.dart';
import 'new_chat_page.dart';
import 'qr_watch.dart' show EdgeSwipe;
import 'stories.dart';
import 'ios_route.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with TickerProviderStateMixin {
  String query = '';

  /// 'all', 'unread', 'mention', 'direct', 'group', 'channel', 'bot' or 'folder:<id>'.
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
  final tierTick = ValueNotifier<int>(0);
  final listKey = GlobalKey();
  final tierKeys = [GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey()];

  /// Per tier: the list offset where it starts going under the bar, and its
  /// height (0 when the tier is not shown).
  List<(double, double)> tiers = const [];

  /// Bottom edge of the top bar on screen, and the two spots beside the
  /// title where the tucked faces sit (stories left, bubbles right).
  double barBottom = 0;

  /// The search field (Eric 2026-11-26): under the stories and bubbles,
  /// above 보관함 and the chats; it slides up under the bar like them.
  bool searchShown = false;
  final miniSlots = [GlobalKey(), GlobalKey()];

  /// 스토리 / 비눗방울 once tucked away stay up beside the title; pulling
  /// the list down does not bring them back. Each comes down on its own
  /// when its small faces are tapped (Eric 2026-11-26 정정).
  final collapsed = [false, false];

  /// Opening from the title: 1 = still the small faces, 0 = back in place.
  late final grow = [for (var i = 0; i < 2; i++) AnimationController(vsync: this, duration: const Duration(milliseconds: 480), value: 0)];

  /// How far tier [i] has gone into the title: scrolled away, folded up
  /// there, or on its way back down.
  double into(int i, double at) => collapsed[i] ? 1 : math.max(tucked(i, at), grow[i].value);

  /// The current scroll started with a finger (a mouse wheel is not snapped).
  bool dragged = false;

  /// 보관함 starts hidden (Eric 2026-11-26, Telegram): pulling the list
  /// down past the top brings it out; once scrolled away under the bar it
  /// hides again.
  bool archiveOut = false;

  /// Pull needed past the top to bring 보관함 out: about one row of real
  /// finger travel, not a nudge (Eric 2026-11-26 "조금만 해도 나와").
  static const archivePull = Tokens.archivePull; // Telegram 60 pt (was 64)
  double overPull = 0;

  /// 당겨서 카메라 (우리식, Snapchat's camera-first idea without making the
  /// camera the first screen): pulled this far past the top in one swipe,
  /// letting go opens the story camera. A short pull still brings 보관함.
  static const cameraPull = 150.0;
  final camPull = ValueNotifier<double>(0);
  bool camArmed = false;

  bool get pullCameraOn => Features.ownWay && AppScope.read(context).on(pullCameraPref, fallback: true);

  void camTrack(double pulled) {
    if (!pullCameraOn) return;
    camPull.value = pulled;
    final armed = pulled >= cameraPull;
    if (armed != camArmed) {
      camArmed = armed;
      if (armed) HapticFeedback.mediumImpact();
    }
  }

  Future<void> camRelease() async {
    final go = camArmed;
    camArmed = false;
    camPull.value = 0;
    if (!go || !mounted) return;
    await newStory(context);
    if (mounted) await AppScope.read(context).refresh();
  }

  /// One tier per swipe (Eric 2026-11-26 "스토리만 올라가야 하는데 같이
  ///따라 올라감"): a swipe that starts among the tiers stops at the edge of
  /// the one it is in, up or down, even when flung. The next swipe takes
  /// the next tier.
  double stopUp = double.infinity, stopDown = double.negativeInfinity;

  /// Where the current swipe began: 보관함 only comes out on a swipe that
  /// starts at the very top (not on the one that just opened the search).
  double swipeFrom = 0;

  void setStops(double at) {
    measure();
    stopUp = double.infinity;
    stopDown = double.negativeInfinity;
    final open = [
      for (final t in tiers)
        if (t.$2 > 0) t,
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (start, height) in open) {
      final shut = start + height;
      if (shut > at + 1) {
        stopUp = shut;
        break;
      }
    }
    for (final (start, _) in open.reversed) {
      final top = start <= Tokens.space[2] ? 0.0 : start;
      if (top < at - 1) {
        // Going down: back to the top edge of the tier just above (the
        // very top is left to the normal bounce).
        if (top > 0) stopDown = top;
        break;
      }
    }
  }

  bool onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    listY.value = n.metrics.pixels;
    if (n is ScrollStartNotification) {
      dragged = n.dragDetails != null;
      overPull = 0;
      if (dragged) {
        swipeFrom = n.metrics.pixels;
        setStops(n.metrics.pixels);
      } else {
        measure();
      }
    }
    // 당겨서 카메라: how far past the top this swipe went (bounce or edge).
    if (swipeFrom <= 1 && n.metrics.pixels <= 0) {
      if (n is ScrollUpdateNotification && n.dragDetails != null) camTrack(math.max(-n.metrics.pixels, overPull));
      if (n is OverscrollNotification && n.dragDetails != null) camTrack(math.max(camPull.value, overPull - n.overscroll));
      // The finger came off: the list bounces back on its own.
      if (n is ScrollUpdateNotification && n.dragDetails == null && camPull.value > 0) unawaited(camRelease());
    }
    if (!archiveOut && swipeFrom <= 1 && n is ScrollUpdateNotification && n.dragDetails != null && n.metrics.pixels < -archivePull) {
      tick();
      setState(() => archiveOut = true);
    }
    if (!archiveOut && swipeFrom <= 1 && n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0 && n.metrics.pixels <= 0) {
      overPull -= n.overscroll;
      if (overPull > archivePull) {
        tick();
        setState(() => archiveOut = true);
      }
    }
    if (n is ScrollEndNotification && camPull.value > 0) unawaited(camRelease());
    if (n is ScrollEndNotification) {
      stopUp = double.infinity;
      stopDown = double.negativeInfinity;
      if (dragged) {
        dragged = false;
        Future.microtask(snap);
      }
      if (!jumping) {
        Future.microtask(tuckArchive);
        Future.microtask(foldTiers);
      }
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
    // Not in the middle of a layout (scroll notices can come from there).
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) return;
    final list = listKey.currentContext?.findRenderObject();
    if (list is! RenderBox || !list.attached || !list.hasSize) return;
    final bar = list.localToGlobal(Offset.zero).dy + MediaQuery.paddingOf(context).top + GlassTopBar.height;
    (double, double) tier(GlobalKey k) {
      final box = k.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) return (0.0, 0.0);
      return (scroll.offset + box.localToGlobal(Offset.zero).dy - bar, box.size.height);
    }

    final now = [for (final k in tierKeys) tier(k)];
    final changed =
        now.length != tiers.length ||
        [for (var i = 0; i < now.length; i++) (now[i].$1 - tiers[i].$1).abs() > 0.5 || (now[i].$2 - tiers[i].$2).abs() > 0.5].any((x) => x);
    tiers = now;
    // The moving copies and the small faces read [tiers]: redraw them.
    if (changed) tierTick.value++;
    barBottom = bar;
  }

  /// One light tap each time a tier folds or opens (Eric 2026-11-26: same
  /// strength as Telegram, which uses iOS's light impact).
  void tick() => HapticFeedback.lightImpact();

  /// Let go halfway into a tier: it finishes opening or closing.
  void snap() {
    if (!mounted || !scroll.hasClients) return;
    measure();
    final at = scroll.offset;
    for (final (start, height) in [...tiers]..sort((a, b) => a.$1.compareTo(b.$1))) {
      if (height <= 0) continue;
      // The first tier opens all the way to the top of the list.
      final open = start <= Tokens.space[2] ? 0.0 : start;
      final shut = start + height;
      if (at <= open + 1 || at >= shut - 1) continue;
      final to = at - open < (shut - open) / 2 ? open : shut;
      scroll.animateTo(to, duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
      tick();
      return;
    }
  }

  /// The archive row went fully under the bar: take it out of the list
  /// and keep the rows where they are.
  void tuckArchive() {
    if (!mounted || !archiveOut || !scroll.hasClients || tiers.length < 3) return;
    final (_, height) = tiers[2];
    if (height <= 0 || tucked(2, scroll.offset) < 0.99) return;
    final at = scroll.offset;
    setState(() => archiveOut = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) jump(math.max(0, at - height));
    });
  }

  /// Our own position fix after a tier leaves the list: its scroll-end
  /// notice must not fold or tuck anything else (one tier per swipe).
  bool jumping = false;
  void jump(double to) {
    jumping = true;
    scroll.jumpTo(to);
    jumping = false;
    // Read the tiers again once the list has been laid out at its new spot.
    SchedulerBinding.instance.addPostFrameCallback((_) => measure());
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Stories / bubbles that went fully under the bar fold into the title
  /// for good: out of the list, rows kept where they are.
  void foldTiers() {
    if (!mounted || !scroll.hasClients) return;
    measure();
    final at = scroll.offset;
    var gone = 0.0;
    final fold = <int>[];
    for (var i = 0; i < 2 && i < tiers.length; i++) {
      final (_, height) = tiers[i];
      if (collapsed[i] || height <= 0 || tucked(i, at) < 0.96) continue;
      fold.add(i);
      gone += height;
    }
    if (fold.isEmpty) return;
    tick();
    setState(() {
      for (final i in fold) {
        collapsed[i] = true;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) jump(math.max(0, at - gone));
    });
  }

  /// Tap on the small faces: that tier alone grows back down out of the
  /// title into its place at the top of the list.
  void openTier(int i) {
    if (!collapsed[i]) return;
    tick();
    setState(() => collapsed[i] = false);
    grow[i].value = 1;
    grow[i].animateTo(0, curve: Curves.linear).whenComplete(measure);
    if (scroll.hasClients && scroll.offset > 0) {
      scroll.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
    }
  }

  /// The bar title, with the tucked-away tiers next to it: story faces on
  /// the left, bubbles on the right. Both sides keep the same room so the
  /// title stays in the middle.
  Widget barTitle(BuildContext context, String text, bool stories) {
    final p = paletteOf(context);
    final l = L.of(context);
    final app = AppScope.of(context);
    final label = Text(
      text,
      key: const Key('bar-title'),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
    );
    if (!stories) return label;
    // Telegram iOS: the tucked faces are ~30 pt, overlapping by half.
    // Stories (left) and bubbles (right) use the same size and frame.
    const mini = Tokens.miniFace, step = mini / 2, slot = mini + 2 * step;
    const inner = mini - 2 * (Tokens.miniRing + Tokens.miniGap);
    // Same ring on both sides: gradient when new, grey when seen.
    Widget ringed(Widget child, bool fresh) => Container(
      width: mini,
      height: mini,
      padding: const EdgeInsets.all(Tokens.miniRing),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fresh ? null : p.separator,
        gradient: fresh ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.storyRing) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(Tokens.miniGap),
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.list),
        child: SizedBox.square(dimension: inner, child: child),
      ),
    );
    final faces = <Widget>[];
    if (stories) {
      final groups = storyGroups(app, app.stories);
      final seen = seenStories(app);
      final others = [
        for (final g in groups)
          if (!g.first.mine) g,
      ];
      for (final g in (others.isNotEmpty ? others : groups).take(3)) {
        faces.add(ringed(Avatar(name: storyName(app, l, g.first), size: inner, userId: g.first.sender, round: true), g.any((x) => !seen.contains(x.id))));
      }
    }
    // Overlapping faces; the first one sits next to the title.
    // Left of the title the faces keep the row's order (first friend on the
    // left), so the ones flying up land in the same order (2026-11-26).
    Widget pile(List<Widget> items, bool leftOfTitle) => SizedBox(
      width: slot,
      height: mini,
      child: Stack(
        children: leftOfTitle
            ? [for (var i = 0; i < items.length; i++) Positioned(right: (items.length - 1 - i) * step, top: 0, child: items[i])]
            : [for (var i = items.length - 1; i >= 0; i--) Positioned(left: i * step, top: 0, child: items[i])],
      ),
    );
    // Rises from under the bar into place as its tier slides away.
    Widget fly(String key, int tier, double at, List<Widget> items, bool leftOfTitle) {
      // Never two copies at once (Eric 2026-11-26 "이중으로 뜨면 안 되지"):
      // the row shrinks into this spot and is gone by 92% (see
      // [tierFade]); only then do the small faces show.
      // Fully there by 96%, so a scroll that stops just short never
      // leaves a half-faded pile (it looked pastel, 2026-11-26).
      final t = ((into(tier, at) - 0.92) / 0.04).clamp(0.0, 1.0).toDouble();
      if (t <= 0 || items.isEmpty) return const SizedBox(width: slot, height: mini);
      return GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: () => openTier(tier),
        child: Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: pile(items, leftOfTitle)),
        ),
      );
    }

    // The title comes first: a long one ("Chats", a folder name) gets the
    // room and the side slots shrink; the faces only show when they fit
    // (검수 2026-11-28: English "Chats" was cut to "Ch...").
    final tp = TextPainter(
      text: TextSpan(text: text, style: label.style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final textW = tp.width;
    tp.dispose();
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxWidth.isFinite ? ((box.maxWidth - textW) / 2 - Tokens.space[0]).clamp(0.0, slot).toDouble() : slot;
        final fits = room >= slot;
        return ListenableBuilder(
          listenable: Listenable.merge([listY, tierTick, ...grow]),
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KeyedSubtree(
                key: miniSlots[0],
                child: fits ? fly('stories-mini', 0, listY.value, faces, true) : SizedBox(width: room, height: mini),
              ),
              SizedBox(width: Tokens.space[0]),
              Flexible(child: label),
              SizedBox(width: Tokens.space[0]),
              // Same room on the right so the title stays in the middle.
              KeyedSubtree(
                key: miniSlots[1],
                child: SizedBox(width: room, height: mini),
              ),
            ],
          ),
        );
      },
    );
  }

  /// A tier shrinks into its small faces beside the title as it slides
  /// under the bar (stories to the left, bubbles to the right), and grows
  /// back out of them into its own place on the way down (Eric 2026-11-26
  /// "큰 방울이 작아져서 올라가고, 내려올 때는 작은 게 커지면서").
  /// The moving copy is drawn above the page (over the fixed search and
  /// the bar) so it can travel all the way to the title.
  final portals = [OverlayPortalController(), OverlayPortalController()];

  Widget tierFade(int i, int count, Widget child, Widget face) => ListenableBuilder(
    listenable: Listenable.merge([listY, tierTick, grow[i]]),
    child: child,
    builder: (context, c) {
      final at = listY.value;
      final t = into(i, at);
      Widget? moving;
      // Telegram feel (Eric 2026-11-26 "더 자연스럽게"): the names and the
      // faces past the third fade out early, so only the three faces that
      // become the small pile travel to the title; they hand over to the
      // pile right as they arrive (never two copies on screen).
      final fade = (1 - (t - 0.84) / 0.08).clamp(0.0, 1.0).toDouble();
      final rest = (1 - t / 0.25).clamp(0.0, 1.0).toDouble();
      final row = tierKeys[i].currentContext?.findRenderObject();
      final slot = miniSlots[i].currentContext?.findRenderObject();
      final ready = row is RenderBox && slot is RenderBox && row.hasSize && slot.hasSize && i < tiers.length;
      if (t > 0 && ready) {
        // Where the faces are now (the row's rings) ...
        const pad = 12.0, ring = StoriesBar.ring;
        // Same widths as the rows themselves (stories: ring + 8, StoriesBar).
        final itemW = ring + (i == 0 ? Tokens.space[2] : Tokens.space[0] * 2);
        // The pile beside the title shows friends (내 스토리 only when no
        // friend has one), so those same faces are the ones that travel.
        final app = AppScope.of(context);
        final friends = storyGroups(app, app.stories).where((g) => !g.first.mine).length;
        // 내 스토리, and 친구 피드 when it is on, stay; only friends travel.
        final skip = i == 0 && friends > 0 ? 1 + (Features.feed ? 1 : 0) : 0;
        final travelling = math.min(skip > 0 ? friends : count, 3);
        final contentW = math.min(row.size.width - 2 * pad - skip * itemW, travelling * itemW);
        final start = pad + skip * itemW;
        final ringY = (i == 0 ? 0.0 : Tokens.caption.lineHeight + Tokens.space[0]) + ring / 2;
        final from = Offset(start + contentW / 2, ringY);
        final rowTop = barBottom + tiers[i].$1 - (grow[i].value > 0 ? 0 : at);
        final rowLeft = row.localToGlobal(Offset.zero).dx;
        // ... and where they end up: the little pile beside the title.
        final box = slot.localToGlobal(Offset.zero) & slot.size;
        const mini = Tokens.miniFace, step = mini / 2;
        final e = Curves.easeInOut.transform(t);
        final scale = 1 - (1 - mini / ring) * e;
        if (fade > 0) {
          final top = ringY - ring / 2 - 3;
          Widget sized(Offset origin, Widget w) => Transform.scale(scale: scale, alignment: Alignment.topLeft, origin: origin, child: w);
          // The names and the other faces fade where they are, riding along
          // with the group's centre.
          final groupTo = Offset(box.right - (mini + (travelling - 1) * step) / 2, box.center.dy);
          final groupMove = (groupTo - Offset(rowLeft + from.dx, rowTop + from.dy)) * e;
          final faces = Rect.fromLTWH(start - 3, top, contentW + 6, ring + 6);
          moving = IgnorePointer(
            child: Stack(
              children: [
                if (rest > 0)
                  Positioned(
                    left: rowLeft + groupMove.dx,
                    top: rowTop + groupMove.dy,
                    width: row.size.width,
                    child: Opacity(
                      opacity: rest,
                      child: sized(from, ClipPath(clipper: _Outside(faces), child: face)),
                    ),
                  ),
                // Each travelling face flies to its own spot in the pile, so
                // they close up into the overlap as they shrink.
                for (var k = 0; k < travelling; k++)
                  () {
                    final at0 = Offset(start + k * itemW + itemW / 2, ringY);
                    final dest = Offset(box.right - mini / 2 - (travelling - 1 - k) * step, box.center.dy);
                    final mv = (dest - Offset(rowLeft + at0.dx, rowTop + at0.dy)) * e;
                    return Positioned(
                      left: rowLeft + mv.dx,
                      top: rowTop + mv.dy,
                      width: row.size.width,
                      child: Opacity(
                        opacity: fade,
                        child: sized(at0, ClipRect(clipper: _Inside(Rect.fromLTWH(start + k * itemW - 2, top, itemW + 1, ring + 6)), child: face)),
                      ),
                    );
                  }(),
              ],
            ),
          );
        }
      }
      if (!portals[i].isShowing) WidgetsBinding.instance.addPostFrameCallback((_) => portals[i].show());
      // Coming back down: the room it needs opens up as it grows.
      final g = Curves.easeInOut.transform(grow[i].value);
      Widget inList = Opacity(opacity: t > 0 ? 0 : 1, child: c);
      if (g > 0) inList = Align(alignment: Alignment.topCenter, heightFactor: 1 - g, child: inList);
      return OverlayPortal.targetsRootOverlay(controller: portals[i], overlayChildBuilder: (_) => moving ?? const SizedBox.shrink(), child: inList);
    },
  );

  /// v1 edit mode (⋯): circles to pick chats, handles to order pinned ones,
  /// and 모두 읽음 / 보관 / 삭제 at the bottom instead of the tab bar.
  bool editing = false;
  final picked = <String>{};

  /// Long press on a folder tab: the Telegram menu under the lifted tab.
  Future<void> holdTab(String id, List<ChatFolder> folders) async {
    final l = L.of(context);
    final p = paletteOf(context);
    HapticFeedback.mediumImpact();
    final folder = folders.where((f) => 'folder:${f.id}' == id).firstOrNull;
    final label = folder?.label ?? l.filterAll;
    final pick = await showMessageMenu(
      context,
      bubble: Container(
        height: Tokens.folderTabs,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          label,
          style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
        ),
      ),
      mine: false,
      reactions: const [],
      iconsFirst: true,
      items: [
        MenuItem('edit', l.tabEditFolder, CupertinoIcons.square_pencil),
        MenuItem('unread', l.tabShowUnread, CupertinoIcons.chat_bubble_text),
        MenuItem('order', l.tabReorder, CupertinoIcons.arrow_up_arrow_down),
      ],
    );
    if (!mounted || pick == null) return;
    final nav = paneNav(context);
    switch (pick) {
      case 'edit':
        nav.push(IosPageRoute(builder: (_) => folder == null ? const FoldersPage() : FolderEditPage(folder: folder)));
      case 'unread':
        setState(() => filter = 'unread');
      case 'order':
        nav.push(IosPageRoute(builder: (_) => const FoldersPage()));
    }
  }

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
    setState(() {
      menu = on;
      menuDrag = 0;
    });
  }

  /// iOS sheet drag: the card follows the finger 1:1 once the menu list is
  /// at its top; on release it closes only past a third of its height or
  /// on a fast flick, otherwise it springs back (UISheetPresentationController
  /// feel, 2026-11-26 Eric "too sensitive").
  double menuDrag = 0;
  bool menuDragging = false;
  final menuScroll = ScrollController();
  final menuKey = GlobalKey();
  final menuVelocity = <(Duration, double)>[];
  static const menuCloseFraction = 1 / 3;
  static const menuFlick = 800.0;

  void menuMove(PointerMoveEvent e) {
    final atTop = !menuScroll.hasClients || menuScroll.offset <= 0;
    if (menuDrag <= 0 && !(atTop && e.delta.dy > 0)) return;
    menuVelocity.add((e.timeStamp, e.position.dy));
    if (menuVelocity.length > 6) menuVelocity.removeAt(0);
    setState(() {
      menuDragging = true;
      menuDrag = math.max(0, menuDrag + e.delta.dy);
    });
    if (menuScroll.hasClients && menuScroll.offset != 0) menuScroll.jumpTo(0);
  }

  void menuUp(double height) {
    if (!menuDragging) return;
    var v = 0.0;
    if (menuVelocity.length > 1) {
      final (t0, y0) = menuVelocity.first;
      final (t1, y1) = menuVelocity.last;
      final ms = (t1 - t0).inMicroseconds / 1e6;
      if (ms > 0) v = (y1 - y0) / ms;
    }
    menuVelocity.clear();
    menuDragging = false;
    if (menuDrag > height * menuCloseFraction || v > menuFlick) {
      setMenu(false);
    } else {
      setState(() => menuDrag = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    ChatMarks.counts.addListener(marksChanged);
  }

  /// The @ filter follows the marks as they're worked out or seen.
  void marksChanged() {
    if (filter == 'mention' && mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatMarks.counts.removeListener(marksChanged);
    HomeTabs.hideBar.value = false;
    scroll.dispose();
    camPull.dispose();
    menuScroll.dispose();
    listY.dispose();
    tierTick.dispose();
    for (final g in grow) {
      g.dispose();
    }
    super.dispose();
  }

  Future<void> editAction(String what, List<ChatPreview> shown) async {
    final l = L.of(context);
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
      // Several at once (Telegram tip 184): all pinned already = unpin.
      case 'pin':
        final picks = app.chats.where((c) => ids.contains(c.roomId)).toList();
        final off = picks.every((c) => c.pinned);
        for (final c in picks) {
          if (c.pinned == off) await b.setChatPinned(c.roomId, !off);
        }
        if (mounted)
          showInfoBanner(
            context,
            off ? l.unpinnedMany(picks.length) : l.pinnedMany(picks.length),
            '',
            icon: off ? CupertinoIcons.pin_slash_fill : CupertinoIcons.pin_fill,
          );
      case 'mute':
        final picks = app.chats.where((c) => ids.contains(c.roomId)).toList();
        final off = picks.every((c) => c.muted);
        for (final c in picks) {
          off ? await app.unmuteChat(c.roomId) : await app.muteChat(c.roomId, null);
        }
        if (mounted)
          showInfoBanner(
            context,
            off ? l.unmutedMany(picks.length) : l.mutedMany(picks.length),
            '',
            icon: off ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill,
          );
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

  /// The folder put in front opens first (once, when the app starts).
  bool startPicked = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final app = AppScope.of(context);
    final all = app.chats;
    final q = query.trim().toLowerCase();
    // Unseen @ / ♥ marks follow the list (a light look, a few at most).
    ChatMarks.schedule(app);
    if (!startPicked && app.settings.isNotEmpty) {
      startPicked = true;
      filter = startFilter(app);
    }
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
    // 비눗방울 no longer has its own row (Eric 2026-11-26, plan B): each
    // waiting bubble sits as a small drop in its sender's chat row.
    final tiersOpen = showStories && !collapsed[0];
    WidgetsBinding.instance.addPostFrameCallback((_) => measure());
    // Searching looks through every chat, archived ones too.
    final chats = q.isEmpty
        ? [
            for (final c in all)
              // Tip 187: a chat added to a folder by hand shows in that
              // folder's tab even while archived.
              if ((!c.archived || inFolderByHand(app, filter, c.roomId)) && !app.on(hiddenKey(c.roomId)) && !app.isRequest(c.roomId) && takes(app, filter, c))
                c,
          ]
        : [
            for (final c in all)
              if (c.name.toLowerCase().contains(q)) c,
          ];
    // 커뮤니티 "한 대화로 보기": its chats fold into one row (not while editing).
    final folded = q.isEmpty && !editing ? foldCommunities(app, chats) : chats;
    // 문의함 (tip 526): a channel's subscriber messages as one row.
    final boxed = Features.channelTips && q.isEmpty && !editing ? ChannelDm.fold(app, folded) : folded;
    // AI 친구 (우리식): its own row right under 저장한 메시지 (all chats only).
    final listed = Features.ownWay && q.isEmpty && !editing && filter == 'all' && AiFriend.listed(app) ? withAiFriend(boxed, app.savedRoomId) : boxed;
    final archived = [
      for (final c in all)
        if (c.archived) c,
    ];
    final requests = app.requests;
    final top = app.on('list_top');
    searchShown = !top && !editing && all.isNotEmpty;
    final folders = foldersOf(app);
    // Telegram folder tabs under the search once I have my own folders
    // (Eric 2026-11-26); the old chip row (list_top) keeps its own.
    final tabs = searchShown && folders.isNotEmpty;
    final barText = tabs && (filter == 'all' || filter.startsWith('folder:')) ? filterTitle(app, l, 'all') : filterTitle(app, l, filter);
    final page = CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar(
        lift: Tokens.listBarLift,
        title: barText,
        middle: barTitle(context, barText, showStories),
        leading: editing
            ? [GlassPill(key: const Key('list-edit-done'), text: l.done, onTap: endEdit)]
            : [
                GlassCircle(key: const Key('chats-menu'), onTap: startEdit, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)),
                GlassCircle(key: const Key('side-menu-button'), onTap: () => setMenu(!menu), child: GlassCircle.icon(context, CupertinoIcons.sidebar_left)),
              ],
        trailing: editing
            ? [
                // Pin / mute every picked chat (Telegram tip 184).
                if (picked.isNotEmpty) ...[
                  GlassCircle(key: const Key('edit-pin'), onTap: () => editAction('pin', chats), child: GlassCircle.icon(context, CupertinoIcons.pin)),
                  GlassCircle(key: const Key('edit-mute'), onTap: () => editAction('mute', chats), child: GlassCircle.icon(context, CupertinoIcons.bell_slash)),
                ],
              ]
            : [
                // Tip 322: files still coming → the ⬇ ring (tap = list).
                const DownloadsButton(),
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
          // 당겨서 카메라: a glass circle grows under the bar while pulling.
          if (Features.ownWay)
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[2],
              child: IgnorePointer(
                child: PullCameraHint(pull: camPull, full: cameraPull, from: archivePull),
              ),
            ),
          KeyedSubtree(
            key: listKey,
            // The list starts under the bar, so the search can pin there;
            // the folding rows are drawn above the page while they move.
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
              child: NotificationListener<ScrollNotification>(
                onNotification: onScroll,
                child: CustomScrollView(
                  controller: scroll,
                  // Pull down works even when the list is short (brings 보관함 out).
                  physics: TierStopPhysics(stops: () => (stopUp, stopDown), parent: const AlwaysScrollableScrollPhysics()),
                  slivers: [
                    // Telegram: with 스토리/비눗방울 folded the search sits right under
                    // the bar (Eric 2026-11-26 "검색이 밑으로 쳐져 있음").
                    SliverToBoxAdapter(child: SizedBox(height: tiersOpen ? Tokens.space[1] : 0)),
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
                                for (final k in builtInFilters) (k, filterName(l, k)),
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
                    // 음악 미니 플레이어 (tips 108 + 199): stays while music plays.
                    if (Features.tipsAudio) const SliverToBoxAdapter(child: AudioMiniBar()),
                    // 새 로그인 경고 (tip 398): on top, until answered.
                    for (final d in AppScope.of(context).newLogins)
                      SliverToBoxAdapter(
                        child: NewLoginCard(key: Key('new-login-card-${d.id}'), device: d),
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
                    // Tier 1 스토리, tier 3 보관함: each slides up
                    // under the bar on its own (see [tiers]).
                    if (showStories && !collapsed[0])
                      SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: tierKeys[0],
                          child: tierFade(
                            0,
                            storyGroups(app, app.stories).length,
                            toMenu('stories', storiesInMenuPref, l.storiesMovedTitle, StoriesBar(stories: app.stories, onChanged: () => app.refresh())),
                            StoriesBar(stories: app.stories, onChanged: () {}),
                          ),
                        ),
                      ),
                    if (searchShown)
                      SliverToBoxAdapter(
                        child: Padding(
                          key: tierKeys[3],
                          padding: EdgeInsets.fromLTRB(Tokens.space[3], tiersOpen ? Tokens.space[1] : 0, Tokens.space[3], tabs ? 0 : Tokens.listSearchBelow),
                          child: SearchCapsule(
                            key: const Key('list-search'),
                            glass: true,
                            hint: l.searchChats,
                            onChanged: (v) => setState(() => query = v),
                            onOpen: Features.search ? () => openSearch(context) : null,
                          ),
                        ),
                      ),
                    if (tabs)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: FolderTabsHeader(
                          FolderTabs(
                            key: const Key('folder-tabs'),
                            selected: filter,
                            onPick: (id) => setState(() => filter = id),
                            onHold: (id) => holdTab(id, folders),
                            items: [for (final f in folders) ('folder:${f.id}', f.label, all.where((c) => f.takes(c, app.friendIds) && c.unread > 0).length)]
                              ..insert(allPos(app, folders.length), ('all', l.filterAll, 0)),
                          ),
                        ),
                      ),
                    // 메시지 요청 (v1): strangers' 1:1 chats wait in one row on top.
                    if (q.isEmpty && !editing && requests.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            ArchiveRow(chats: requests, requests: true),
                            Padding(
                              padding: EdgeInsets.only(left: Tokens.chatAvatar + Tokens.space[3] + Tokens.space[2]),
                              child: Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
                            ),
                          ],
                        ),
                      ),
                    // 생일 배너 under the search, like Telegram (TelegramTips 446).
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: tabs ? Tokens.space[1] : 0),
                        child: const BirthdayBanner(),
                      ),
                    ),
                    // 보관함 tucks up and drops down too, on its own (Eric 2026-11-26).
                    if (q.isEmpty && !editing && archived.isNotEmpty && !app.on(archiveInMenuPref))
                      SliverToBoxAdapter(
                        child: AnimatedSize(
                          key: tierKeys[2],
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.bottomCenter,
                          child: !archiveOut
                              ? const SizedBox(width: double.infinity)
                              : Column(
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
                      ),
                    if (all.isEmpty || chats.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            all.isEmpty ? l.chatsEmpty : (q.isNotEmpty ? l.searchNone : (filter == 'mention' ? l.mentionNone : '')),
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
                      ChatRows(chats: listed),
                    SliverToBoxAdapter(child: SizedBox(height: FloatingTabBar.room(context))),
                    // A short list can still push every tier under the bar.
                    SliverLayoutBuilder(
                      builder: (c, cons) {
                        // Room to scroll the lowest tier fully under the bar.
                        final need = tiers.fold<double>(0, (a, x) => x.$2 > 0 ? math.max(a, x.$1 + x.$2) : a);
                        final extra = math.max(0.0, cons.viewportMainAxisExtent + need - cons.precedingScrollExtent);
                        return SliverToBoxAdapter(child: SizedBox(height: extra));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: FloatingTabBar.room(context) + Tokens.space[1], child: const DeleteUndoBar()),
          if (editing) Positioned(left: 0, right: 0, bottom: 0, child: editBar(context, chats)),
          // Telegram tip 503: pull from the left edge to the right and the
          // camera opens (it reads QR codes too).
          if (Features.shareLinks && !editing)
            Positioned(
              left: 0,
              top: MediaQuery.paddingOf(context).top + GlassTopBar.height,
              bottom: 0,
              width: Tokens.space[3],
              child: EdgeSwipe(
                key: const Key('chats-edge-camera'),
                onSwipe: () async {
                  await newStory(context);
                  await app.refresh();
                },
              ),
            ),
        ],
      ),
    );
    // Side menu: a card that rises from the bottom over the list
    // (Eric 2026-11-26), the list dimmed behind; tap the dim or pull the
    // card down to close.
    const d = Duration(milliseconds: 320);
    final h = MediaQuery.sizeOf(context).height;
    final sheetTop = MediaQuery.paddingOf(context).top + Tokens.space[2];
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !menu,
            child: AnimatedOpacity(
              duration: d,
              opacity: menu ? 1 : 0,
              child: GestureDetector(
                key: const Key('side-menu-close'),
                onTap: () => setMenu(false),
                child: const ColoredBox(color: Color(0x33000000)),
              ),
            ),
          ),
        ),
        // As tall as what it holds (Eric 2026-11-26 "3번"), never taller than
        // the screen under the status bar; it slides up from below.
        AnimatedPositioned(
          duration: menuDragging ? Duration.zero : d,
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: menu ? -menuDrag : -h,
          child: Listener(
            onPointerMove: menuMove,
            onPointerUp: (_) => menuUp(menuKey.currentContext?.size?.height ?? h - sheetTop),
            onPointerCancel: (_) => menuUp(menuKey.currentContext?.size?.height ?? h - sheetTop),
            child: ConstrainedBox(
              key: menuKey,
              constraints: BoxConstraints(maxHeight: h - sheetTop),
              child: SideMenu(
                controller: menuScroll,
                filter: filter,
                onPick: (f) {
                  filter = f;
                  setMenu(false);
                },
                onSearch: (v) => setState(() => query = v),
              ),
            ),
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
          itemBuilder: (c, i) => shown[i].roomId == AiFriend.rowId
              ? const AiFriendRow()
              : shown[i].roomId.startsWith(communityRowPrefix)
              ? CommunityListRow(row: shown[i])
              : shown[i].roomId.startsWith(ChannelDm.rowPrefix)
              ? ChannelInboxRow(
                  row: shown[i],
                  open: (ctx, room, name, ch) => openChat(ctx, room, name, dmInbox: ch),
                )
              : SwipeRow(
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
  const ArchiveRow({super.key, required this.chats, this.requests = false});
  final List<ChatPreview> chats;

  /// The 메시지 요청 row (same look, its own icon and page).
  final bool requests;

  // Same size as a chat row and photo (Eric 2026-11-26 "아이콘 크기 맞춰").
  static const height = Tokens.chatRow, icon = Tokens.chatAvatar;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final unread = chats.where((c) => c.unread > 0 && !c.muted).length;
    return GestureDetector(
      key: Key(requests ? 'requests-row' : 'archive-row'),
      behavior: HitTestBehavior.opaque,
      onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => requests ? const RequestsPage() : const ArchivePage())),
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
                      colors: [
                        Color.lerp(requests ? Palette.tileBlue : p.tileGreen, const Color(0xFFFFFFFF), Tokens.avatarTopLight)!,
                        requests ? Palette.tileBlue : p.tileGreen,
                      ],
                    ),
                  ),
                  child: Icon(
                    requests ? CupertinoIcons.bubble_left_bubble_right_fill : CupertinoIcons.archivebox_fill,
                    color: const Color(0xFFFFFFFF),
                    size: 30,
                  ),
                ),
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(requests ? l.messageRequests : l.archive, style: Tokens.listName.style.copyWith(color: p.label)),
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
            if (unread > 0) UnreadBadge(count: unread, muted: !requests),
          ],
        ),
      ),
    );
  }
}

/// 메시지 요청: 1:1 chats from people who aren't my contacts. Open one to
/// read it; accept or delete it there.
class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final chats = AppScope.of(context).requests;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.messageRequests), border: null, backgroundColor: p.list.withValues(alpha: 0.0)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            if (chats.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  key: const Key('requests-empty'),
                  child: Text(l.messageRequestsEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ),
              )
            else ...[
              ChatRows(chats: chats),
              SliverToBoxAdapter(
                child: Padding(padding: EdgeInsets.all(Tokens.space[3]), child: sectionFooter(context, l.messageRequestsInfo)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  @override
  void initState() {
    super.initState();
    // Tip 187: "이게 보관함이에요" the first time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !AppScope.read(context).on(archiveIntroSeenKey)) showArchiveIntro(context);
    });
  }

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
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(l.archive),
        trailing: const ArchiveMenuButton(),
        border: null,
        backgroundColor: p.list.withValues(alpha: 0.0),
      ),
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

/// The round @ (unseen mention) or ♥ (unseen reaction) beside a chat's
/// count: the badge's 20 pt height, Telegram's order ♥ @ count. A muted
/// chat's ♥ turns grey like its count; @ keeps the accent (someone means me).
class MarkDot extends StatelessWidget {
  const MarkDot({super.key, required this.heart, this.muted = false});
  final bool heart;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    // Telegram: both in the accent colour (blue theme blue, green theme green).
    final bg = heart && muted ? p.secondaryLabel.withValues(alpha: 0.45) : p.accent;
    return Container(
      width: 20,
      height: 20,
      margin: EdgeInsets.only(left: Tokens.space[0]),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: heart
          ? Icon(CupertinoIcons.heart_fill, size: 11, color: p.onAccent)
          : Text(
              '@',
              style: Tokens.caption.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi, height: 1.1),
            ),
    );
  }
}

class ChatRowTile extends StatelessWidget {
  const ChatRowTile({super.key, required this.chat, this.inCommunity = false});
  final ChatPreview chat;

  /// Eric 2026-11-26: the words never touch the count. A fixed slot wide
  /// enough for "999+" keeps an 8 pt gap whatever the number.
  Widget badgeSlot(ChatPreview chat) => Container(
    key: const Key('row-badge-slot'),
    width: Tokens.badgeSlot,
    margin: EdgeInsets.only(left: Tokens.space[1]),
    alignment: Alignment.topRight,
    child: chat.unread > 0
        ? UnreadBadge(count: chat.unread, muted: chat.muted)
        // The red 📌 emoji (Eric 2026-11-26, from the plan B mock-up).
        : Text(
            '📌',
            key: const Key('pinned'),
            style: TextStyle(fontSize: Tokens.rowEmoji, height: 1.2, fontFamilyFallback: Tokens.emojiFallback),
          ),
  );

  /// Shown inside its community's sheet (no community mark then).
  final bool inCommunity;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final cut = clearedAt(s, chat.roomId);
    var last = cut != null && chat.last != null && !chat.last!.time.isAfter(cut) ? null : chat.last;
    // 날짜로 지우기 (tip 308): a wiped last message isn't previewed.
    if (last != null && LoginSafety.hiddenByDate(s, chat.roomId, last)) last = null;
    final name = nameOf(s, chat);
    return ValueListenableBuilder<String?>(valueListenable: Wide.selected, builder: (context, _, _) => row(context, p, s, name, last));
  }

  /// The grey line under the name, like Telegram: who is typing (accent),
  /// a missed call, or the last message with its sender in groups.
  TextSpan previewLine(BuildContext context, Palette p, AppState s, Msg? last) {
    final l = L.of(context);
    String short(String id) => displayId(id).replaceFirst('@', '');
    // 익명 관리자 (94): never named in the list.
    final anon = s.anonCfgs[chat.roomId] ?? const <String, dynamic>{};
    final hidden = AnonAdmins.current(anon);
    final typers = s.backend.typingUsers(chat.roomId).where((u) => !hidden.contains(u)).toList();
    if (typers.isNotEmpty) {
      final who = chat.isDirect ? '' : '${typers.map(short).join(', ')} ';
      return TextSpan(
        text: '$who${l.typing}',
        style: TextStyle(color: p.accent),
      );
    }
    // 쓰다 만 글 (Telegram / v1): "임시 저장: …" in red.
    final draft = s.pref('draft:${chat.roomId}', '');
    if (draft.isNotEmpty) {
      return TextSpan(
        children: [
          TextSpan(
            text: '${l.draftLabel} ',
            style: const TextStyle(color: Palette.tileRed),
          ),
          TextSpan(text: draft.replaceAll('\n', ' ')),
        ],
      );
    }
    if (Features.ownWay) {
      // 1년 전 오늘: the saved chat says so until I open it today.
      if (chat.roomId == s.savedRoomId && Memories.waiting(s)) {
        return TextSpan(
          text: l.memoriesPreview(s.memories.first.years, Memories.count(s.memories)),
          style: TextStyle(color: p.accent),
        );
      }
      // 캡처 알림: newer than the last message.
      final shot = ShotAlert.newest(s, chat.roomId, last);
      if (shot != null) {
        final mine = shot.who == s.backend.userId;
        return TextSpan(text: mine ? l.shotPreviewMine : l.shotPreview(chat.isDirect ? nameOf(s, chat) : short(shot.who)));
      }
    }
    if (last == null) return const TextSpan(text: '');
    final missed = last.kind == 'call' && last.call?.state == 'missed' && !last.mine;
    final body = last.bubble
        ? l.attachBubble
        : (missed ? l.callLineMissed : previewText(context, kind: last.kind, body: last.body, caption: last.caption, live: last.live != null));
    // Groups (not channels): "지우: …" with the name in the label colour.
    if (!chat.isDirect && !chat.isChannel && chat.roomId != s.savedRoomId && last.kind != 'call' && !AnonAdmins.sentAnon(anon, last)) {
      return TextSpan(
        children: [
          TextSpan(
            text: '${last.mine ? l.you : short(last.sender)}: ',
            style: TextStyle(color: p.label),
          ),
          TextSpan(text: body),
        ],
      );
    }
    // A bubble still waiting to be popped reads in the app colour.
    if (last.bubble && s.bubbles.any((b) => b.roomId == chat.roomId))
      return TextSpan(
        text: body,
        style: TextStyle(color: p.accent),
      );
    return TextSpan(text: body);
  }

  Widget row(BuildContext context, Palette p, AppState s, String name, Msg? last) {
    final tags = tagsOf(s, chat);
    final waiting = s.bubbles.where((b) => b.roomId == chat.roomId).firstOrNull;
    final thumb = last != null && !last.viewOnce && (last.kind == 'image' || last.kind == 'video') && s.on('list_media') && s.autoDownload;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openChat(context, chat.roomId, name),
      // 대화 목록 가리기: a finger anywhere on the row shows the last message.
      child: VeilHold(
        child: Container(
          height: Tokens.chatRow,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          // Two panes: the chat open on the right is marked (iPad style).
          decoration: Wide.on && Wide.selected.value == chat.roomId ? BoxDecoration(color: p.incoming) : null,
          child: Row(
            children: [
              // 커뮤니티: a small round mark at the photo's lower left opens it.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Avatar(
                    name: name,
                    size: Tokens.chatAvatar,
                    squircle: !chat.isDirect,
                    channel: chat.isChannel,
                    userId: chat.isDirect ? chat.peer : null,
                    roomId: chat.roomId,
                    owner: chat.isChannel ? chat.peer : null,
                  ),
                  if (!inCommunity && !chat.isDirect)
                    if (s.communityOf(chat.roomId) case final com?) Positioned(left: -3, bottom: -3, child: CommunityMark(community: com)),
                  // 자동 삭제 is on here (Telegram 364: "1w" on the photo).
                  if ((s.timers[chat.roomId] ?? 0) > 0)
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: TimerMark(key: Key('timer-mark-${chat.roomId}'), seconds: s.timers[chat.roomId]!),
                    ),
                ],
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
                                  style: Tokens.listName.style.copyWith(color: p.label),
                                ),
                              ),
                              // 사칭 막기: official badge or '확인 중' / '가짜' (1:1 and channels).
                              if (chat.isDirect || chat.isChannel) TrustMark(user: chat.peer, name: chat.name, size: 15),
                              // 이모지 상태 (tip 359): a friend's emoji after their name.
                              if (Features.emojiStickers && chat.isDirect) StatusMark(user: chat.peer, size: 15),
                              // 제일 친한 친구 ❤ (우리식): counted on this phone, only I see it.
                              if (Features.ownWay && chat.isDirect && BestFriend.room(s) == chat.roomId) const BestFriendMark(),
                              if (chat.muted)
                                Padding(
                                  padding: const EdgeInsets.only(left: 3),
                                  child: Icon(CupertinoIcons.bell_slash_fill, key: const Key('muted'), size: 13, color: p.secondaryLabel),
                                ),
                            ],
                          ),
                        ),
                        // Eric 2026-11-26 (plan B): a waiting bubble shows as a small
                        // drop before the streak; tap it to pop.
                        if (waiting != null) RowBubble(bubble: waiting, name: name, gapAfter: chat.streak == 0),
                        if (chat.streak > 0) StreakBadge(days: chat.streak, atRisk: chat.streakAtRisk, afterBubble: waiting != null),
                        // Telegram: my last message gets one tick (sent) or two (read),
                        // 1:1 only, and only when read receipts go both ways.
                        if (last != null && last.mine && chat.isDirect && !chat.isChannel) ListTick(roomId: chat.roomId, at: last.time),
                        if (last != null) Text(shortTime(context, last.time), style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
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
                                // 설정 > 개인정보 및 보안 > 대화 목록 가리기 (Eric 2026-11-26): the
                                // last message shows only while a finger rests on the row.
                                Veil(
                                  mode: s.on('veil_list') ? 'dots' : '',
                                  ink: p.secondaryLabel,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Settings > Chats > Photo and video previews (v1).
                                      if (thumb)
                                        Padding(
                                          padding: EdgeInsets.only(right: Tokens.space[0], top: 1),
                                          child: ListThumbs(roomId: chat.roomId, last: last),
                                        ),
                                      Expanded(
                                        child: Text.rich(
                                          previewLine(context, p, s, last),
                                          key: const Key('list-preview'),
                                          maxLines: tags.isEmpty ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                        ),
                                      ),
                                    ],
                                  ),
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
                        // Eric 2026-11-26: the words never touch the count. A fixed slot
                        // wide enough for "999+" keeps an 8 pt gap whatever the number.
                        if (Features.tipsReply)
                          // 안 본 반응 ♥ · 멘션 @ (tips 320 / 249) before the count, like Telegram.
                          ValueListenableBuilder<Map<String, MarkCounts>>(
                            valueListenable: ChatMarks.counts,
                            builder: (c, all, _) {
                              final mk = all[chat.roomId];
                              return Padding(
                                padding: EdgeInsets.only(left: mk == null ? 0 : Tokens.space[0]),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((mk?.reactions ?? 0) > 0) MarkDot(key: const Key('row-mark-reaction'), heart: true, muted: chat.muted),
                                    if ((mk?.mentions ?? 0) > 0) const MarkDot(key: Key('row-mark-mention'), heart: false),
                                    if (chat.unread > 0 || chat.pinned) badgeSlot(chat),
                                  ],
                                ),
                              );
                            },
                          )
                        else if (chat.unread > 0 || chat.pinned)
                          badgeSlot(chat),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [chats] with the AI 친구 row after 저장한 메시지 (or first).
List<ChatPreview> withAiFriend(List<ChatPreview> chats, String? saved) {
  final row = ChatPreview(roomId: AiFriend.rowId, name: '', isDirect: false, encrypted: true, unread: 0);
  final at = chats.isNotEmpty && chats.first.roomId == saved ? 1 : 0;
  return [...chats.take(at), row, ...chats.skip(at)];
}

/// Settings > 대화 > 아래로 당겨 카메라 열기 (on by default).
const pullCameraPref = 'pull_camera';

/// The circle under the bar while the list is pulled down: grows from the
/// 보관함 pull to [full], then says "놓으면 카메라가 열려요".
class PullCameraHint extends StatelessWidget {
  const PullCameraHint({super.key, required this.pull, required this.full, required this.from});
  final ValueNotifier<double> pull;
  final double full, from;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return ValueListenableBuilder<double>(
      valueListenable: pull,
      builder: (context, v, _) {
        if (v <= from) return const SizedBox.shrink();
        final t = ((v - from) / (full - from)).clamp(0.0, 1.0);
        final ready = t >= 1;
        return Opacity(
          key: const Key('pull-camera-hint'),
          opacity: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.6 + 0.4 * t,
                child: Container(
                  width: Tokens.closeButton,
                  height: Tokens.closeButton,
                  decoration: BoxDecoration(
                    color: ready ? p.accent : p.card,
                    shape: BoxShape.circle,
                    boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 2))],
                  ),
                  child: Icon(CupertinoIcons.camera_fill, size: 22, color: ready ? p.onAccent : p.label),
                ),
              ),
              SizedBox(height: Tokens.space[0]),
              Text(ready ? l.pullCameraLetGo : l.pullCameraMore, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ],
          ),
        );
      },
    );
  }
}

/// 제일 친한 친구 ❤ beside the name (only I see it). Tap = what it means.
class BestFriendMark extends StatelessWidget {
  const BestFriendMark({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return GestureDetector(
      key: const Key('best-friend'),
      behavior: HitTestBehavior.opaque,
      onTap: () => showInfoBanner(context, l.bestFriendTip, l.bestFriendTipBody, icon: CupertinoIcons.heart_fill),
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Semantics(
          label: l.bestFriendTip,
          child: Text(
            '❤️',
            style: TextStyle(fontSize: Tokens.rowEmoji - 1, height: 1.2, fontFamilyFallback: Tokens.emojiFallback),
          ),
        ),
      ),
    );
  }
}

/// A waiting 비눗방울 in its sender's row (Eric 2026-11-26, plan B): a
/// small drop before the streak, the same size as the flame. Tap to pop.
class RowBubble extends StatelessWidget {
  const RowBubble({super.key, required this.bubble, required this.name, this.gapAfter = true});
  final BubbleRef bubble;
  final String name;

  /// Room before the time when no flame follows.
  final bool gapAfter;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      key: Key('row-bubble-${bubble.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => popBubble(context, bubble.roomId, bubble.id, name),
      child: Padding(
        padding: EdgeInsets.only(left: Tokens.space[1], right: gapAfter ? Tokens.space[1] : 0),
        child: SoapBubble(color: p.accent, size: Tokens.rowBubble),
      ),
    );
  }
}

/// Streak mark next to a 1:1 name: flame + days; an hourglass when it
/// ends tonight unless both write.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, required this.atRisk, this.afterBubble = false});
  final int days;
  final bool atRisk;

  /// Right after a waiting bubble: a small gap, so drop and flame read as one group.
  final bool afterBubble;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    const flame = Palette.tileOrange;
    return Padding(
      key: const Key('streak'),
      padding: EdgeInsets.only(left: afterBubble ? Tokens.space[0] : Tokens.space[1], right: Tokens.space[1]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The 🔥 emoji (Eric 2026-11-26), faded when it ends tonight.
          Opacity(
            opacity: atRisk ? 0.55 : 1,
            child: Text(
              '🔥',
              style: TextStyle(fontSize: Tokens.rowEmoji, height: 1.2, fontFamilyFallback: Tokens.emojiFallback),
            ),
          ),
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

/// Telegram-style search capsule: 44 pt, the magnifier and the word sit in
/// the middle until you type; then they move to the left like iOS.
class SearchCapsule extends StatefulWidget {
  const SearchCapsule({super.key, required this.hint, required this.onChanged, this.glass = false, this.onOpen});
  final bool glass;

  /// 전체 검색: a tap opens the search screen instead of typing here.
  final VoidCallback? onOpen;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SearchCapsule> createState() => _SearchCapsuleState();
}

class _SearchCapsuleState extends State<SearchCapsule> {
  final text = TextEditingController();
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final idle = !focus.hasFocus && text.text.isEmpty;
    final icon = Icon(CupertinoIcons.search, size: 20, color: p.secondaryLabel);
    final body = Stack(
      alignment: Alignment.center,
      children: [
        if (idle)
          IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                SizedBox(width: Tokens.space[0] + 2),
                Text(widget.hint, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
              ],
            ),
          ),
        CupertinoTextField(
          controller: text,
          focusNode: focus,
          decoration: null,
          style: Tokens.body.style.copyWith(color: p.label),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
          prefix: idle
              ? null
              : Padding(
                  padding: EdgeInsets.only(left: Tokens.space[2]),
                  child: icon,
                ),
          suffix: text.text.isEmpty
              ? null
              : CupertinoButton(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                  minimumSize: Size.zero,
                  onPressed: () {
                    text.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: p.secondaryLabel),
                ),
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {});
          },
        ),
      ],
    );
    final open = widget.onOpen;
    if (open != null) {
      return GestureDetector(
        key: const Key('list-search-open'),
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: AbsorbPointer(child: frame(p, body)),
      );
    }
    return frame(p, body);
  }

  Widget frame(Palette p, Widget body) {
    // Eric 2026-11-26: the list search wears the same glass as the tab bar.
    if (widget.glass)
      return SizedBox(
        height: Tokens.searchField,
        child: LiquidGlass(
          radius: Tokens.searchField / 2,
          shadow: false,
          // No edge line, like the iOS search field (Eric 2026-11-26 "테두리 선 없애").
          rim: false,
          // A little more frosted than the bars (Eric 2026-11-26 "약간 탁하게").
          child: ColoredBox(color: p.searchFill.withValues(alpha: 0.6), child: body),
        ),
      );
    return Container(
      height: Tokens.searchField,
      decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.searchField / 2)),
      child: body,
    );
  }
}

/// Holds a swipe at the tier edges set for it (see stopUp / stopDown).
class TierStopPhysics extends ScrollPhysics {
  const TierStopPhysics({required this.stops, super.parent});
  final (double, double) Function() stops;

  @override
  TierStopPhysics applyTo(ScrollPhysics? ancestor) => TierStopPhysics(stops: stops, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final (up, down) = stops();
    if (value > up && position.pixels <= up) return value - up;
    if (position.pixels >= up && value > position.pixels && position.pixels - up < 1) return value - position.pixels;
    if (value < down && position.pixels >= down) return value - down;
    return super.applyBoundaryConditions(position, value);
  }
}

/// Keeps only [rect] of a widget (the travelling story faces).
class _Inside extends CustomClipper<Rect> {
  const _Inside(this.rect);
  final Rect rect;
  @override
  Rect getClip(Size size) => rect;
  @override
  bool shouldReclip(_Inside old) => old.rect != rect;
}

/// Everything except [rect] (names and the faces that only fade).
class _Outside extends CustomClipper<Path> {
  const _Outside(this.rect);
  final Rect rect;
  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addRect(rect);
  @override
  bool shouldReclip(_Outside old) => old.rect != rect;
}
