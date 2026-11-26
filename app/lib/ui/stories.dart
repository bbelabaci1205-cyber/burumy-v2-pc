// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Stories, Instagram style: a row of rings over the chat list (mine first),
// a full-screen viewer (bars on top, tap left / right, hold to pause, pull
// down to close, reply at the bottom) and a simple composer. Stories go to
// 1:1 friends only, inside each chat's encryption, for 24 hours; nobody
// learns who watched (seen marks stay on this device).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'feed.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'story_camera.dart';
import 'story_editor.dart';
import 'story_more.dart';
import 'story_video.dart';
import 'wide.dart';

/// Story ids I have watched (this device only).
Set<String> seenStories(AppState s) {
  try {
    final v = jsonDecode(s.pref('story_seen', '[]'));
    return {for (final x in v as List) x as String};
  } catch (_) {
    return {};
  }
}

Future<void> markStorySeen(AppState s, String id) async {
  final seen = seenStories(s);
  if (!seen.add(id)) return;
  // Keep the list short: old ids are gone after 24 hours anyway.
  final list = seen.toList();
  await s.setPref('story_seen', jsonEncode(list.length > 300 ? list.sublist(list.length - 300) : list));
}

/// Stories by person: me first, then friends with something new, then the
/// ones I have seen (Instagram order).
List<List<Story>> storyGroups(AppState s, List<Story> all) {
  final by = <String, List<Story>>{};
  for (final x in all) {
    by.putIfAbsent(x.mine ? '' : x.sender, () => []).add(x);
  }
  final seen = seenStories(s);
  final others = by.entries.where((e) => e.key.isNotEmpty).map((e) => e.value).toList()
    ..sort((a, b) {
      final na = a.any((x) => !seen.contains(x.id)), nb = b.any((x) => !seen.contains(x.id));
      if (na != nb) return na ? -1 : 1;
      return b.last.time.compareTo(a.last.time);
    });
  return [?by[''], ...others];
}

/// Name shown for a story's person (my name for them, else the chat name).
String storyName(AppState s, L l, Story x) {
  if (x.mine) return l.storyMine;
  final a = aliasOf(s, x.sender);
  if (a.isNotEmpty) return a;
  final c = s.chats.where((c) => c.roomId == x.roomId).firstOrNull;
  return c != null && c.name.isNotEmpty ? c.name : displayId(x.sender).replaceFirst('@', '');
}

/// Ring around a photo: brand gradient while something is new, a thin grey
/// line once everything was seen (Instagram).
class StoryRing extends StatelessWidget {
  const StoryRing({super.key, required this.child, required this.size, this.fresh = true, this.show = true});
  final Widget child;
  final double size;
  final bool fresh;
  final bool show;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    if (!show)
      return SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      );
    final a = p.accent;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(fresh ? 2.5 : 1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: fresh ? SweepGradient(colors: [a, Color.lerp(a, Palette.tileTeal, 0.6)!, Color.lerp(a, Palette.tileYellow, 0.5)!, a]) : null,
        color: fresh ? null : p.separator,
      ),
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.list),
        child: ClipOval(child: child),
      ),
    );
  }
}

/// The row over the chat list: 내 스토리 (+ to add), then friends.
class StoriesBar extends StatelessWidget {
  const StoriesBar({super.key, required this.stories, required this.onChanged});
  final List<Story> stories;
  final VoidCallback onChanged;

  static const ring = 68.0;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final groups = storyGroups(s, stories);
    final mine = groups.isNotEmpty && groups.first.first.mine ? groups.first : null;
    final others = mine == null ? groups : groups.sublist(1);
    final seen = seenStories(s);
    final me = s.backend.userId ?? '';
    Widget item({required Key key, required Widget face, required String label, required VoidCallback onTap, VoidCallback? onLong}) => GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLong,
      // No names under the rings (Eric 2026-11-26); screen readers still say them.
      child: Semantics(
        label: label,
        button: true,
        child: SizedBox(
          width: ring + Tokens.space[0],
          child: Center(child: face),
        ),
      ),
    );
    return SizedBox(
      key: const Key('stories-bar'),
      // Tight rows: the tiers sat too far apart (Eric 2026-11-26).
      height: ring + Tokens.space[1],
      child: ListView(
        scrollDirection: Axis.horizontal,
        // No bounce: past the end the whole strip slides (to the side menu).
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
        children: [
          item(
            key: const Key('story-mine'),
            face: Stack(
              clipBehavior: Clip.none,
              children: [
                StoryRing(
                  size: ring,
                  show: mine != null,
                  fresh: mine != null,
                  child: Avatar(name: displayId(me).replaceFirst('@', ''), size: ring - 10, userId: me),
                ),
                if (mine == null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.list, width: 2),
                      ),
                      child: Icon(CupertinoIcons.plus, size: 13, color: p.onAccent),
                    ),
                  ),
              ],
            ),
            label: l.storyMine,
            onTap: () async {
              if (mine != null) {
                await openStories(context, [mine], 0);
              } else {
                await newStory(context);
              }
              onChanged();
            },
            // Hold: a new story, or my archive (kept on this phone only).
            onLong: () async {
              final pick = await showCupertinoModalPopup<String>(
                useRootNavigator: !Wide.on,
                context: context,
                builder: (c) => CupertinoActionSheet(
                  actions: [
                    CupertinoActionSheetAction(key: const Key('mine-new'), onPressed: () => Navigator.pop(c, 'new'), child: Text(l.storyNew)),
                    CupertinoActionSheetAction(key: const Key('mine-archive'), onPressed: () => Navigator.pop(c, 'archive'), child: Text(l.storyArchive)),
                  ],
                  cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                ),
              );
              if (!context.mounted) return;
              if (pick == 'new') await newStory(context);
              if (pick == 'archive') await openStoryArchive(context);
              onChanged();
            },
          ),
          // Friend feed (hidden until Eric switches it on).
          if (Features.feed)
            item(
              key: const Key('feed-open'),
              face: Container(
                width: ring,
                height: ring,
                padding: const EdgeInsets.all(5),
                child: Container(
                  decoration: BoxDecoration(color: p.incoming, shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.square_grid_2x2, color: p.accent, size: 26),
                ),
              ),
              label: l.feedTitle,
              onTap: () async {
                await openFeed(context);
                onChanged();
              },
            ),
          for (var i = 0; i < others.length; i++)
            item(
              key: Key('story-${others[i].first.sender}'),
              face: StoryRing(
                size: ring,
                fresh: others[i].any((x) => !seen.contains(x.id)),
                child: Avatar(name: storyName(s, l, others[i].first), size: ring - 10, userId: others[i].first.sender),
              ),
              label: storyName(s, l, others[i].first),
              onTap: () async {
                await openStories(context, others, i);
                onChanged();
              },
            ),
        ],
      ),
    );
  }
}

Future<void> openStories(BuildContext context, List<List<Story>> groups, int start, {int at = 0}) => Navigator.of(context, rootNavigator: true).push(
  PageRouteBuilder(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (c, a, _) => FadeTransition(
      opacity: a,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        // Wide window: a 9:16 card in the middle, X at the window's corner.
        child: PhoneFrame(
          onClose: () => Navigator.of(c).maybePop(),
          child: StoryViewer(groups: groups, start: start, at: at),
        ),
      ),
    ),
  ),
);

/// Full-screen viewer: one page per person, bars for each story.
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.groups, required this.start, this.at = 0});
  final List<List<Story>> groups;
  final int start;

  /// Which story of the first person to start from.
  final int at;

  static const shown = Duration(seconds: 5);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer> with SingleTickerProviderStateMixin {
  late int person = widget.start;
  late int at = widget.at.clamp(0, widget.groups[widget.start].length - 1);
  late final AnimationController clock = AnimationController(vsync: this, duration: StoryViewer.shown)
    ..addStatusListener((st) {
      if (st == AnimationStatus.completed) next();
    });
  final reply = TextEditingController();
  final replyFocus = FocusNode();
  double drag = 0;
  final cache = <String, Future<List<int>>>{};
  VideoPlayerController? video;

  List<Story> get list => widget.groups[person];
  Story get story => list[at];

  @override
  void initState() {
    super.initState();
    replyFocus.addListener(() => replyFocus.hasFocus ? pause() : resume());
    WidgetsBinding.instance.addPostFrameCallback((_) => show());
  }

  @override
  void dispose() {
    clock.dispose();
    reply.dispose();
    replyFocus.dispose();
    super.dispose();
  }

  void show() {
    if (!mounted) return;
    video = null;
    unawaited(markStorySeen(AppScope.read(context), story.id));
    clock.duration = StoryViewer.shown;
    // A video waits for itself to load, then runs as long as it is.
    if (story.kind == 'video') {
      clock.value = 0;
    } else {
      clock.forward(from: 0);
    }
    setState(() {});
  }

  /// A video is ready: the bar follows its length (one minute at most).
  void playVideo(VideoPlayerController c) {
    if (!mounted) return;
    video = c;
    final d = c.value.duration;
    clock.duration = d > Duration.zero && d < const Duration(seconds: 60) ? d : const Duration(seconds: 60);
    clock.forward(from: 0);
  }

  void pause() {
    clock.stop();
    video?.pause();
  }

  void resume() {
    if (story.kind == 'video' && video == null) return;
    clock.forward();
    video?.play();
  }

  void next() {
    if (at < list.length - 1) {
      at++;
    } else if (person < widget.groups.length - 1) {
      person++;
      at = 0;
    } else {
      Navigator.of(context).maybePop();
      return;
    }
    show();
  }

  void back() {
    if (at > 0) {
      at--;
    } else if (person > 0) {
      person--;
      at = widget.groups[person].length - 1;
    }
    show();
  }

  Future<void> sendReply(String text) async {
    final t = text.trim();
    if (t.isEmpty || story.mine) return;
    final s = AppScope.read(context);
    final l = L.of(context);
    reply.clear();
    replyFocus.unfocus();
    try {
      await s.backend.sendText(story.roomId, '${l.storyReplyPrefix} $t');
      if (mounted) showStoryToast(context, l.storyReplied);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final x = story;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final bytes = cache.putIfAbsent(x.eventId, () => s.backend.downloadFile(x.roomId, x.eventId));
    const white = Color(0xFFFFFFFF);
    return GestureDetector(
      onVerticalDragUpdate: (d) => setState(() => drag = (drag + d.delta.dy).clamp(0, 400)),
      onVerticalDragEnd: (d) {
        if (drag > 120 || (d.primaryVelocity ?? 0) > 700) {
          Navigator.of(context).maybePop();
        } else {
          setState(() => drag = 0);
        }
      },
      child: Transform.translate(
        offset: Offset(0, drag),
        child: ColoredBox(
          key: const Key('story-viewer'),
          color: const Color(0xFF000000),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The picture, with rounded corners like Instagram.
              Padding(
                padding: EdgeInsets.only(top: top, bottom: bottom + 64),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.radius[2]),
                  child: FutureBuilder<List<int>>(
                    future: bytes,
                    builder: (_, b) => !b.hasData || b.data!.isEmpty
                        ? Center(child: Icon(x.kind == 'video' ? CupertinoIcons.play_circle : CupertinoIcons.photo, color: white, size: 56))
                        : x.kind == 'video'
                        ? StoryVideo(key: ValueKey(x.eventId), bytes: Uint8List.fromList(b.data!), mime: 'video/mp4', onReady: playVideo)
                        : Image.memory(Uint8List.fromList(b.data!), fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              ),
              // Tap left = back, right = next, hold = pause.
              Positioned.fill(
                top: top + 70,
                bottom: bottom + 64,
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        key: const Key('story-back'),
                        behavior: HitTestBehavior.opaque,
                        onTap: back,
                        onLongPressStart: (_) => pause(),
                        onLongPressEnd: (_) => resume(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        key: const Key('story-next'),
                        behavior: HitTestBehavior.opaque,
                        onTap: next,
                        onLongPressStart: (_) => pause(),
                        onLongPressEnd: (_) => resume(),
                      ),
                    ),
                  ],
                ),
              ),
              // Poll / question / plan: answers go to the poster's 1:1 chat.
              Positioned.fill(
                top: top,
                bottom: bottom + 64,
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      for (final (i, it) in decodeLive(x.extra).indexed)
                        Positioned(
                          left: it.at.dx * box.maxWidth,
                          top: it.at.dy * box.maxHeight,
                          child: FractionalTranslation(
                            translation: const Offset(-.5, -.5),
                            child: Transform.scale(
                              scale: it.scale,
                              child: Focus(
                                onFocusChange: (f) => f ? pause() : resume(),
                                child: StoryLiveCard(
                                  key: Key('story-live-${x.id}-$i'),
                                  item: it,
                                  chosen: s.pref('story_vote:${x.id}:$i', '').isEmpty ? null : s.pref('story_vote:${x.id}:$i', ''),
                                  onAnswer: x.mine
                                      ? null
                                      : (t) async {
                                          await s.setPref('story_vote:${x.id}:$i', t);
                                          try {
                                            await s.backend.sendText(x.roomId, t);
                                            if (context.mounted) showStoryToast(context, l.storyReplied);
                                          } catch (_) {}
                                        },
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if ((x.caption ?? '').isNotEmpty)
                Positioned(
                  left: Tokens.space[3],
                  right: Tokens.space[3],
                  bottom: bottom + 64 + Tokens.space[4],
                  child: Text(
                    x.caption!,
                    key: const Key('story-caption'),
                    textAlign: TextAlign.center,
                    style: Tokens.body.style.copyWith(
                      color: white,
                      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
                    ),
                  ),
                ),
              // Bars and who / when.
              Positioned(
                top: top + Tokens.space[1],
                left: Tokens.space[1],
                right: Tokens.space[1],
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < list.length; i++)
                          Expanded(
                            child: Container(
                              height: 2.5,
                              margin: const EdgeInsets.symmetric(horizontal: 1.5),
                              decoration: BoxDecoration(color: const Color(0x59FFFFFF), borderRadius: BorderRadius.circular(2)),
                              alignment: Alignment.centerLeft,
                              child: AnimatedBuilder(
                                animation: clock,
                                builder: (_, _) => FractionallySizedBox(
                                  widthFactor: i < at ? 1 : (i == at ? clock.value : 0),
                                  child: Container(
                                    decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(2)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: Tokens.space[2]),
                    Row(
                      children: [
                        SizedBox(width: Tokens.space[1]),
                        Avatar(name: storyName(s, l, x), size: 32, userId: x.sender),
                        SizedBox(width: Tokens.space[1]),
                        Flexible(
                          child: Text(
                            storyName(s, l, x),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Tokens.preview.style.copyWith(color: white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        Text(agoLabel(l, x.time), style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF))),
                        const Spacer(),
                        Builder(
                          builder: (c) => PhoneFrame.on(c)
                              ? const SizedBox.shrink()
                              : GestureDetector(
                                  key: const Key('story-close'),
                                  onTap: () => Navigator.of(context).maybePop(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(CupertinoIcons.xmark, color: white, size: 24),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Bottom: reply + heart (friends' stories), or a line for mine.
              Positioned(
                left: Tokens.space[2],
                right: Tokens.space[2],
                bottom: bottom + Tokens.space[1],
                child: x.mine
                    ? SizedBox(
                        height: Tokens.closeButton,
                        child: Center(
                          child: Text(l.storyPrivateNote, style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF))),
                        ),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: CupertinoTextField(
                              key: const Key('story-reply'),
                              controller: reply,
                              focusNode: replyFocus,
                              placeholder: l.storyReplyHint,
                              placeholderStyle: Tokens.body.style.copyWith(color: const Color(0xB3FFFFFF)),
                              style: Tokens.body.style.copyWith(color: white),
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: (Tokens.closeButton - Tokens.body.lineHeight) / 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0x80FFFFFF)),
                                borderRadius: BorderRadius.circular(Tokens.capsule),
                              ),
                              onSubmitted: sendReply,
                            ),
                          ),
                          SizedBox(width: Tokens.space[2]),
                          GestureDetector(
                            key: const Key('story-like'),
                            onTap: () => sendReply('❤️'),
                            child: const Icon(CupertinoIcons.heart, color: white, size: 28),
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

String agoLabel(L l, DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.storyNow;
  if (d.inHours < 1) return l.storyMinutes(d.inMinutes);
  return l.storyHours(d.inHours.clamp(1, 24));
}

void showStoryToast(BuildContext context, String text) {
  final o = Overlay.of(context, rootOverlay: true);
  final e = OverlayEntry(
    builder: (c) => Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.paddingOf(c).top + 80,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
          decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(text, style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF))),
        ),
      ),
    ),
  );
  o.insert(e);
  Timer(const Duration(milliseconds: 1600), e.remove);
}

/// 내 스토리 보관함; tapping one opens the composer to share it again.
Future<void> openStoryArchive(BuildContext context) {
  final nav = paneNav(context);
  return nav.push(
    IosPageRoute(
      builder: (c) => StoryArchivePage(
        onReuse: (file) => nav.push(IosPageRoute(fullscreenDialog: true, builder: (_) => StoryComposer(picked: (file.$1, Uint8List.fromList(file.$2))))),
      ),
    ),
  );
}

/// New story: take a photo (or choose one), add words, share with friends.
Future<void> newStory(BuildContext context) async {
  // PC app: in the right pane (Eric 2026-11-24); a phone: over everything.
  await openSheet<void>(context, (_) => const StoryCameraPage());
}

class StoryComposer extends StatefulWidget {
  const StoryComposer({super.key, this.picked});

  /// For tests and the demo: a picture already chosen.
  final (String, Uint8List)? picked;

  @override
  State<StoryComposer> createState() => _StoryComposerState();
}

class _StoryComposerState extends State<StoryComposer> {
  (String, Uint8List)? file;
  final caption = TextEditingController();
  bool busy = false;
  final decor = GlobalKey<StoryDecorState>();

  /// A decorating tool is open: the composer's own buttons step aside.
  bool tools = false;
  StoryAudience audience = const StoryAudience.all();
  int hours = 24;

  @override
  void initState() {
    super.initState();
    file = widget.picked;
  }

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  Future<void> pick(ImageSource src) async {
    try {
      final x = src == ImageSource.gallery
          ? await ImagePicker().pickMedia(maxWidth: 1440, imageQuality: 88)
          : await ImagePicker().pickImage(source: src, maxWidth: 1440, imageQuality: 88);
      if (x == null) return;
      final b = await x.readAsBytes();
      var name = x.name.isEmpty ? 'story.jpg' : x.name;
      if ((x.mimeType ?? '').startsWith('video/') && !isStoryVideo(name)) name = 'story.mp4';
      if (mounted) setState(() => file = (name, b));
    } catch (_) {}
  }

  Future<void> share() async {
    final f = file;
    if (f == null || busy) return;
    final l = L.of(context);
    final s = AppScope.read(context);
    final nav = Navigator.of(context);
    setState(() => busy = true);
    try {
      var out = f;
      final d = decor.currentState;
      if (d != null && d.edited) {
        final b = await d.flatten();
        if (b != null) out = ('story.png', b);
      }
      final n = await s.backend.postStory(
        mime: storyMime(out.$1),
        bytes: out.$2,
        caption: caption.text,
        only: audience.mode == 'all' ? const [] : audience.rooms,
        hours: hours,
        extra: d?.liveJson() ?? '',
      );
      // My own copy, on this phone only.
      await StoryArchive.keep(out.$1, out.$2, caption.text);
      if (!mounted) return;
      nav.pop(true);
      showStoryToast(context, l.storyShared(n));
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        showStoryToast(context, l.storyNoFriends);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final f = file;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return PhoneFrame(child: _composerPage(context, l, p, f, top, bottom));
  }

  Widget _composerPage(BuildContext context, L l, Palette p, (String, Uint8List)? f, double top, double bottom) {
    const white = Color(0xFFFFFFFF);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(top: top, bottom: bottom + 80),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              child: f == null
                  ? Container(
                      color: const Color(0xFF1C1C1E),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.camera, color: white, size: 56),
                          SizedBox(height: Tokens.space[2]),
                          Text(
                            l.storyHint,
                            textAlign: TextAlign.center,
                            style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF)),
                          ),
                        ],
                      ),
                    )
                  : isStoryVideo(f.$1)
                  ? StoryVideo(key: ValueKey(f.$2.length), bytes: f.$2, mime: storyMime(f.$1), loop: true)
                  : StoryDecor(key: decor, bytes: f.$2, onBusy: (b) => setState(() => tools = b)),
            ),
          ),
          if (f != null && !tools && isStoryVideo(f.$1))
            Positioned(
              left: Tokens.space[3],
              right: Tokens.space[3],
              bottom: bottom + 80 + Tokens.space[3],
              child: CupertinoTextField(
                key: const Key('story-caption-input'),
                controller: caption,
                placeholder: l.storyCaptionHint,
                textAlign: TextAlign.center,
                maxLength: 200,
                placeholderStyle: Tokens.body.style.copyWith(color: const Color(0xB3FFFFFF)),
                style: Tokens.body.style.copyWith(color: white),
                decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(Tokens.radius[1])),
                padding: EdgeInsets.all(Tokens.space[2]),
              ),
            ),
          if (!tools)
            Positioned(
              // Same row as the Aa / pen / sticker buttons.
              top: top + Tokens.space[2],
              left: Tokens.space[2],
              child: GlassCircle(
                key: const Key('story-composer-close'),
                onTap: () => Navigator.of(context).maybePop(),
                child: Icon(f == null ? CupertinoIcons.xmark : CupertinoIcons.chevron_back, color: white, size: 22),
              ),
            ),
          // Bottom: gallery, shutter, flip-free camera button / share.
          if (!tools)
            Positioned(
              left: Tokens.space[3],
              right: Tokens.space[3],
              bottom: bottom + Tokens.space[2],
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    // With a picture chosen only "share" stays (Instagram):
                    // the gallery is back on the camera.
                    if (f == null) ...[
                      GlassCircle(
                        key: const Key('story-gallery'),
                        onTap: () => pick(ImageSource.gallery),
                        child: const Icon(CupertinoIcons.photo_on_rectangle, color: white, size: 22),
                      ),
                      const Spacer(),
                    ] else ...[
                      // Who sees it, and for how long (Instagram has neither choice).
                      _Pill(
                        key: const Key('story-audience'),
                        icon: audience.mode == 'close' ? CupertinoIcons.star_fill : CupertinoIcons.person_2_fill,
                        text: audience.label(l),
                        onTap: () async {
                          final a = await pickAudience(context, audience);
                          if (a != null && mounted) setState(() => audience = a);
                        },
                      ),
                      SizedBox(width: Tokens.space[1]),
                      _Pill(
                        key: const Key('story-hours'),
                        icon: CupertinoIcons.clock,
                        text: l.storyHoursN(hours),
                        onTap: () async {
                          final h = await pickHours(context, hours);
                          if (h != null && mounted) setState(() => hours = h);
                        },
                      ),
                      const Spacer(),
                    ],
                    if (f == null)
                      GestureDetector(
                        key: const Key('story-shutter'),
                        onTap: () => pick(ImageSource.camera),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: white, width: 4),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            decoration: const BoxDecoration(color: white, shape: BoxShape.circle),
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        key: const Key('story-share'),
                        onTap: share,
                        // A round arrow (Instagram), so the two choices fit beside it.
                        child: Semantics(
                          label: l.storyShare,
                          button: true,
                          child: Container(
                            width: Tokens.closeButton,
                            height: Tokens.closeButton,
                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: busy ? const CupertinoActivityIndicator(color: white) : Icon(CupertinoIcons.arrow_right, color: p.onAccent, size: 22),
                          ),
                        ),
                      ),
                    if (f == null) ...[const Spacer(), const SizedBox(width: Tokens.closeButton)],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small glass capsule with an icon and words (composer choices).
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        radius: Tokens.closeButton / 2,
        child: SizedBox(
          height: Tokens.closeButton,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: white, size: 16),
                SizedBox(width: Tokens.space[0]),
                Text(text, style: Tokens.preview.style.copyWith(color: white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
