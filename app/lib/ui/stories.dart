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
import 'media_bubbles.dart' show videoSpeedPref;
import '../core/backend.dart';
import '../core/features.dart';
import '../core/search.dart' show Hashtag, findHashtags;
import 'hashtag_page.dart' show openHashtag;
import '../core/room_links.dart' show MessageLink, RoomLinks;
import 'links.dart' show openMessageLink, openWebLink;
import 'chat_page.dart' show openChat;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'feed.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'story_camera.dart';
import 'story_editor.dart';
import 'story_keep.dart';
import 'story_more.dart';
import 'story_stickers.dart';
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
    // A group's story (tip 428) sits under the group, mine or not.
    // A member's group-only story sits under that person, like any other.
    by.putIfAbsent(x.group && !x.member ? 'room:${x.roomId}' : (x.mine ? '' : x.sender), () => []).add(x);
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
  if (x.group && !x.member) {
    final g = s.chats.where((c) => c.roomId == x.roomId).firstOrNull;
    return g != null && g.name.isNotEmpty ? g.name : l.skGroupStory;
  }
  if (x.mine) return l.storyMine;
  final a = aliasOf(s, x.sender);
  if (a.isNotEmpty) return a;
  if (x.member) {
    // Their 1:1 chat's name if we have one, else their ID.
    final dm = s.chats.where((c) => c.isDirect && c.peer == x.sender).firstOrNull;
    return dm != null && dm.name.isNotEmpty ? dm.name : displayId(x.sender).replaceFirst('@', '');
  }
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
        gradient: !fresh
            ? null
            // Same top-to-bottom ring as the small faces by the title
            // (Eric 2026-11-26); Tokens.storyRingLinear = false brings back
            // the earlier sweep look.
            : Tokens.storyRingLinear
            ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.storyRing)
            : SweepGradient(colors: [a, Color.lerp(a, Palette.tileTeal, 0.6)!, Color.lerp(a, Palette.tileYellow, 0.5)!, a]),
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

  /// Telegram iOS (Eric's shot 2026-11-26): ring 62, photo 52.
  static const ring = 62.0;

  /// Room for the name under a ring (gap + one caption line + a little).
  static double get nameLine => Tokens.space[0] + Tokens.caption.lineHeight + Tokens.space[1];

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
      // Name under each ring (Eric 2026-11-26 put them back).
      child: SizedBox(
        // 12 between circles like Telegram iOS (Eric 2026-11-27: too tight at 4).
        width: ring + Tokens.space[2],
        child: Column(
          children: [
            face,
            SizedBox(height: Tokens.space[0]),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.label),
            ),
          ],
        ),
      ),
    );
    return SizedBox(
      key: const Key('stories-bar'),
      // Tight rows: the tiers sat too far apart (Eric 2026-11-26).
      height: ring + StoriesBar.nameLine,
      child: ListView(
        scrollDirection: Axis.horizontal,
        // No bounce: past the end the whole strip slides (to the side menu).
        physics: const ClampingScrollPhysics(),
        // First circle lines up with the chat photos below (16 from the edge).
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] - Tokens.space[2] / 2),
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
                  // No ring yet: the photo fills the whole ring size so it lines
                  // up with the friends' rings (Eric 2026-11-26).
                  child: Avatar(name: displayId(me).replaceFirst('@', ''), size: mine == null ? ring : ring - 10, userId: me, round: true),
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
                    CupertinoActionSheetAction(key: const Key('mine-kept'), onPressed: () => Navigator.pop(c, 'kept'), child: Text(l.skKeptMine)),
                  ],
                  cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                ),
              );
              if (!context.mounted) return;
              if (pick == 'new') await newStory(context);
              if (pick == 'archive') await openStoryArchive(context);
              if (pick == 'kept') await openMyKept(context);
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
                padding: const EdgeInsets.all(2), // same outer size as the friends' rings (검수 11-28)
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
              key: Key(others[i].first.group ? 'story-room-${others[i].first.roomId}' : 'story-${others[i].first.sender}'),
              face: StoryRing(
                size: ring,
                fresh: others[i].any((x) => !seen.contains(x.id)),
                child: others[i].first.group
                    ? Avatar(name: storyName(s, l, others[i].first), size: ring - 10, squircle: true, roomId: others[i].first.roomId)
                    : Avatar(name: storyName(s, l, others[i].first), size: ring - 10, userId: others[i].first.sender, round: true),
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

  /// Music on this story (tip 395); [muted] = sound off (music and round
  /// videos), toggled by tapping either.
  final music = StoryMusic();
  bool muted = false;

  /// The part of a long video this story shows (tip 525), or null.
  (double, double)? get clip => story.kind == 'video' ? storyClip(story.extra) : null;

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
    unawaited(music.dispose());
    super.dispose();
  }

  StoryLive? get musicPart => decodeLive(story.extra).where((x) => x.kind == 'music').firstOrNull;

  void show() {
    if (!mounted) return;
    video = null;
    unawaited(music.pause());
    final m = musicPart;
    if (m != null) unawaited(music.play(AppScope.read(context), m, muted: muted));
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
    // Same speed as chat videos (Settings memory, tip 481); the bar keeps up.
    final sp = videoSpeedPref(context);
    if (sp != 1) c.setPlaybackSpeed(sp);
    if (musicPart != null || muted) c.setVolume(muted ? 0 : (musicPart != null ? .25 : 1));
    // One part of a long video (tip 525): start at its beginning, run its length.
    final cl = clip;
    if (cl != null) {
      unawaited(c.seekTo(Duration(milliseconds: (cl.$1 * 1000).round())));
      clock.duration = Duration(milliseconds: ((cl.$2 - cl.$1) * 1000 / sp).round());
      clock.forward(from: 0);
      return;
    }
    final d = c.value.duration * (1 / sp);
    clock.duration = d > Duration.zero && d < const Duration(seconds: 60) ? d : const Duration(seconds: 60);
    clock.forward(from: 0);
  }

  /// Where in the video a point of the bar is (a part's own stretch).
  Duration videoAt(VideoPlayerController c, double v) {
    final cl = clip;
    if (cl == null) return c.value.duration * v;
    return Duration(milliseconds: ((cl.$1 + (cl.$2 - cl.$1) * v) * 1000).round());
  }

  void pause() {
    clock.stop();
    video?.pause();
    unawaited(music.pause());
  }

  /// Holding a video story (TelegramTips 403): it stops, and sliding the
  /// finger left / right moves through it; the top bar follows.
  bool holding = false;
  double holdFrom = 0;
  DateTime lastSeek = DateTime(0);

  void holdStart(LongPressStartDetails _) {
    pause();
    holdFrom = clock.value;
    setState(() => holding = true);
  }

  void holdMove(LongPressMoveUpdateDetails d) {
    if (story.kind != 'video') return;
    final w = MediaQuery.sizeOf(context).width;
    final v = (holdFrom + d.offsetFromOrigin.dx / w).clamp(0.0, 0.999);
    clock.value = v;
    final c = video;
    final now = DateTime.now();
    if (c != null && now.difference(lastSeek).inMilliseconds > 80) {
      lastSeek = now;
      unawaited(c.seekTo(videoAt(c, v)));
    }
  }

  void holdEnd(LongPressEndDetails _) {
    final c = video;
    if (c != null && story.kind == 'video') unawaited(c.seekTo(videoAt(c, clock.value)));
    setState(() => holding = false);
    resume();
  }

  void resume() {
    if (story.kind == 'video' && video == null) return;
    clock.forward();
    video?.play();
    final m = musicPart;
    if (m != null && !muted) unawaited(music.play(AppScope.read(context), m, muted: false));
  }

  void toggleSound() {
    setState(() => muted = !muted);
    final m = musicPart;
    if (m != null) {
      if (muted) {
        unawaited(music.pause());
      } else {
        unawaited(music.play(AppScope.read(context), m, muted: false));
      }
    }
    video?.setVolume(muted ? 0 : (m != null ? .25 : 1));
  }

  /// One tap on a reaction sticker (tip 395): a private reaction to the
  /// poster, in our 1:1 chat. Once per story, kept on this phone.
  Future<void> react(StoryLive it, int i) async {
    final x = story;
    if (x.mine || x.group) return;
    final s = AppScope.read(context);
    final l = L.of(context);
    final key = 'story_vote:${x.id}:$i';
    if (s.pref(key, '').isNotEmpty) return;
    await s.setPref(key, it.q);
    if (mounted) setState(() {});
    try {
      await s.backend.sendText(x.roomId, '${l.storyReplyPrefix} ${it.q}');
      if (mounted) showStoryToast(context, l.skReactSent);
    } catch (_) {}
  }

  /// A channel post on a story (tip 414): members open the post; others
  /// get the channel's public link when it has one.
  Future<void> openPost(StoryLive it) async {
    final s = AppScope.read(context);
    final nav = Navigator.of(context);
    final member = s.chats.any((c) => c.roomId == it.room);
    if (member || it.url.isEmpty) {
      await nav.maybePop();
      if (nav.context.mounted) await openMessageLink(nav.context, MessageLink(it.room, it.event));
      return;
    }
    await nav.maybePop();
    if (nav.context.mounted) await openWebLink(nav.context, it.url);
  }

  /// ⋯ on my own story: change it, keep it on my profile, albums, cover,
  /// delete (tips 393 / 392 / 534 / 468).
  Future<void> more() async {
    pause();
    final x = story;
    final nav = Navigator.of(context);
    final changed = await myStoryMenu(context, x, edit: () => editMyStory(nav.context, x));
    if (!mounted) return;
    if (changed) {
      await nav.maybePop();
    } else {
      resume();
    }
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
                        // The cover (tip 468) shows until the video plays.
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (storyCover(x.extra).isNotEmpty) StoryThumb(story: x, width: 900),
                              StoryVideo(key: ValueKey(x.eventId), bytes: Uint8List.fromList(b.data!), mime: 'video/mp4', onReady: playVideo),
                            ],
                          )
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
                        onLongPressStart: holdStart,
                        onLongPressMoveUpdate: holdMove,
                        onLongPressEnd: holdEnd,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        key: const Key('story-next'),
                        behavior: HitTestBehavior.opaque,
                        onTap: next,
                        onLongPressStart: holdStart,
                        onLongPressMoveUpdate: holdMove,
                        onLongPressEnd: holdEnd,
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
                              child: it.isMedia
                                  ? StoryMediaPart(
                                      key: Key('story-media-${x.id}-$i'),
                                      item: it,
                                      muted: muted,
                                      chosen: s.pref('story_vote:${x.id}:$i', '').isNotEmpty,
                                      load: (f) => cache.putIfAbsent('part:$f', () => s.backend.downloadEncrypted(f)),
                                      onTap: switch (it.kind) {
                                        'react' => x.mine || x.group ? null : () => react(it, i),
                                        'post' => () => openPost(it),
                                        _ => toggleSound,
                                      },
                                    )
                                  : it.isSticker
                                  ? GestureDetector(
                                      key: Key('story-sticker-${x.id}-$i'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () async {
                                        pause();
                                        await openStorySticker(context, it);
                                        if (!mounted) return;
                                        setState(() {});
                                        resume();
                                      },
                                      child: StorySticker(item: it),
                                    )
                                  : Focus(
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
              if (holding && x.kind == 'video')
                Positioned(
                  top: top + 64,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: LiquidGlass(
                        key: const Key('story-scrub-hint'),
                        radius: Tokens.capsule,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                          child: Text(l.storyScrubHint, style: Tokens.caption.style.copyWith(color: white)),
                        ),
                      ),
                    ),
                  ),
                ),
              if ((x.caption ?? '').isNotEmpty)
                Positioned(
                  left: Tokens.space[3],
                  right: Tokens.space[3],
                  bottom: bottom + 64 + Tokens.space[4],
                  child: storyCaption(
                    context,
                    x.caption!,
                    Tokens.body.style.copyWith(
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      storyName(s, l, x),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Tokens.preview.style.copyWith(color: white, fontWeight: Tokens.semi),
                                    ),
                                  ),
                                  SizedBox(width: Tokens.space[1]),
                                  Text(
                                    x.inRow ? agoLabel(l, x.time) : '${x.time.month}/${x.time.day}',
                                    style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF)),
                                  ),
                                  if (x.edited)
                                    Text(
                                      ' · ${l.skEdited}',
                                      key: const Key('story-edited'),
                                      style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF)),
                                    ),
                                ],
                              ),
                              // 그룹 전용 스토리: which group it was shared with (its own line).
                              if (x.member)
                                Text(
                                  l.storyGroupOnlyLabel(s.chats.where((c) => c.roomId == x.roomId).firstOrNull?.name ?? l.skGroupStory),
                                  key: const Key('story-member-tag'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF)),
                                ),
                            ],
                          ),
                        ),
                        if (x.mine)
                          GestureDetector(
                            key: const Key('story-more'),
                            onTap: more,
                            child: Semantics(
                              label: l.skMore,
                              button: true,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(CupertinoIcons.ellipsis, color: white, size: 24),
                              ),
                            ),
                          ),
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
                child: x.group
                    ? Center(
                        child: GestureDetector(
                          key: const Key('story-group-open'),
                          onTap: () async {
                            final nav = Navigator.of(context);
                            await nav.maybePop();
                            if (nav.context.mounted) await openChat(nav.context, x.roomId, storyName(s, l, x));
                          },
                          child: LiquidGlass(
                            radius: Tokens.capsule,
                            child: SizedBox(
                              height: Tokens.closeButton,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.chat_bubble_2_fill, color: white, size: Tokens.listIconSmall),
                                    SizedBox(width: Tokens.space[1]),
                                    Text(
                                      l.skGroupOpen,
                                      style: Tokens.preview.style.copyWith(color: white, fontWeight: Tokens.semi),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : x.mine
                    ? SizedBox(
                        height: Tokens.closeButton,
                        child: Center(
                          child: Text(
                            x.kept ? [l.skKeptDone, if (x.album.isNotEmpty) x.album].join(' · ') : l.storyPrivateNote,
                            key: const Key('story-mine-note'),
                            style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF)),
                          ),
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

/// A channel post to my story (tip 414): the post drawn as the picture,
/// and a "글 보기" part that opens it (members) or the channel's public link.
Future<void> postToStory(BuildContext context, {required String roomId, required Msg msg}) async {
  final s = AppScope.read(context);
  final nav = paneNav(context);
  final chat = s.chats.where((c) => c.roomId == roomId).firstOrNull;
  final name = chat?.name ?? '';
  Uint8List? photo;
  if (msg.kind == 'image') {
    try {
      photo = Uint8List.fromList(await s.backend.downloadFile(roomId, msg.id));
    } catch (_) {}
  }
  var url = '';
  try {
    final link = await s.backend.roomLink(roomId);
    if (link.public) url = RoomLinks.public(link.code);
  } catch (_) {}
  final text = msg.kind == 'text' || msg.kind == 'image' ? (msg.body ?? '') : '';
  if (!context.mounted) return;
  await nav.push(
    IosPageRoute(
      fullscreenDialog: true,
      builder: (_) => StoryComposer(
        postCard: ChannelPostCard(roomId: roomId, name: name, text: msg.kind == 'image' && text == 'image' ? '' : text, photo: photo),
        post: StoryLive(
          kind: 'post',
          q: name,
          title: text.length > 120 ? text.substring(0, 120) : text,
          room: roomId,
          event: msg.id,
          url: url,
          at: const Offset(.5, .86),
        ),
      ),
    ),
  );
}

/// 프로필 스토리 (tips 392 / 534): the ones I kept on my profile.
Future<void> openMyKept(BuildContext context) => paneNav(context).push(
  IosPageRoute(
    builder: (_) => MyKeptStoriesPage(open: (c, list, i) => openStories(c, [list], 0, at: i)),
  ),
);

/// New story: take a photo (or choose one), add words, share with friends.
Future<void> newStory(BuildContext context) async {
  // PC app: in the right pane (Eric 2026-11-24); a phone: over everything.
  await openSheet<void>(context, (_) => const StoryCameraPage());
}

/// Changes one of my stories (tip 393): opens the composer with the picture
/// as it was before the words went on (kept on this phone), its stickers
/// and who sees it. Without that kit, new things go on the shared picture.
Future<void> editMyStory(BuildContext context, Story x) async {
  final s = AppScope.read(context);
  final nav = paneNav(context);
  final kit = x.kind == 'image' ? await StoryKit.load(x.id) : null;
  List<int> bytes = kit?.bytes ?? const [];
  if (kit == null) {
    try {
      bytes = await s.backend.downloadFile(x.roomId, x.eventId);
    } catch (_) {}
  }
  if (bytes.isEmpty || !context.mounted) return;
  final name = kit?.name ?? (x.kind == 'video' ? 'story.mp4' : 'story.jpg');
  await nav.push(
    IosPageRoute(
      fullscreenDialog: true,
      builder: (_) => StoryComposer(picked: (name, Uint8List.fromList(bytes)), editing: x, kit: kit),
    ),
  );
}

class StoryComposer extends StatefulWidget {
  const StoryComposer({super.key, this.picked, this.editing, this.kit, this.room = '', this.roomName = '', this.post, this.postCard});

  /// For tests and the demo: a picture already chosen.
  final (String, Uint8List)? picked;

  /// Changing this story of mine (tip 393); [kit] = its picture before
  /// the words went on, kept on this phone.
  final Story? editing;
  final StoryKit? kit;

  /// A group's or channel's story (tip 428): that room ('' = mine).
  final String room, roomName;

  /// A channel post shared to my story (tip 414): its tap part, and the
  /// card drawn as the picture.
  final StoryLive? post;
  final Widget? postCard;

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

  /// A video's length (known once it plays) and the parts left out (tip 525).
  Duration? length;
  final skipped = <int>{};

  /// A video's chosen cover (tip 468).
  Uint8List? cover;

  Story? get editing => widget.editing;
  bool get group => widget.room.isNotEmpty || (editing?.group ?? false);

  /// Parts of [partLength] when the video is longer (up to 10).
  static const partLength = Duration(seconds: 60);
  int get parts {
    final d = length;
    if (d == null || editing != null || d <= partLength + const Duration(seconds: 1)) return 1;
    return (d.inMilliseconds / partLength.inMilliseconds).ceil().clamp(1, 10);
  }

  @override
  void initState() {
    super.initState();
    file = widget.picked ?? (widget.postCard != null ? ('story.png', Uint8List(0)) : null);
    final e = editing;
    if (e != null) {
      caption.text = e.kind == 'video' ? (e.caption ?? '') : '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => audience = storyAudienceOf(AppScope.read(context), e.id));
      });
    }
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
      final d = decor.currentState;
      final video = isStoryVideo(f.$1);
      var out = f;
      var changedPicture = false;
      if (d != null && !video && (d.edited || widget.postCard != null)) {
        final b = await d.flatten();
        if (b != null) {
          out = ('story.png', b);
          changedPicture = true;
        }
      }
      if (out.$2.isEmpty) throw StateError('no picture');
      // Music and round videos go up (sealed) only now.
      final live = d?.live ?? <StoryLive>[];
      await uploadStoryParts(s.backend, live);
      var extra = encodeLive(live);
      final e = editing;
      if (e != null) {
        // Keep the cover a video already had.
        final old = storyCover(e.extra);
        if (old.isNotEmpty) extra = withExtra(extra, {'cover': old});
      }
      if (cover != null) extra = withExtra(extra, {'cover': await s.backend.uploadEncrypted(cover!)});
      final only = audience.mode == 'all' || audience.mode == 'group' ? const <String>[] : audience.rooms;
      // 그룹 전용 스토리: my own story, only for that group's members.
      final memberRoom = group ? '' : audience.groupRoom;
      final words = video ? caption.text : '';
      if (e != null) {
        // Tip 393: same story, new words / stickers / audience / picture.
        final keepPicture = video || (!changedPicture && widget.kit == null);
        await s.backend.editStory(
          e.id,
          mime: keepPicture ? '' : storyMime(out.$1),
          bytes: keepPicture ? const [] : out.$2,
          caption: words,
          extra: extra,
          only: e.group ? const [] : only,
          pin: e.pin,
        );
        if (!video && d != null) await StoryKit.save(e.id, StoryKit(name: widget.kit?.name ?? f.$1, bytes: widget.kit?.bytes ?? f.$2, layers: d.layersJson()));
        if (!e.group) await keepStoryAudience(s, e.id, audience);
        await s.refresh();
        if (!mounted) return;
        nav.pop(true);
        showStoryToast(context, l.skSaved);
        return;
      }
      // Tip 525: a long video goes up once, as several stories.
      final n = parts;
      final extras = n == 1
          ? [extra]
          : [
              for (var i = 0; i < n; i++)
                if (!skipped.contains(i))
                  withExtra(extra, {
                    'clip': {'from': i * partLength.inSeconds, 'to': ((i + 1) * partLength.inSeconds).clamp(0, (length!.inMilliseconds / 1000).ceil())},
                  }),
            ];
      if (extras.isEmpty) {
        setState(() => busy = false);
        return;
      }
      final posted = await s.backend.postStories(
        mime: storyMime(out.$1),
        bytes: out.$2,
        caption: words,
        only: group ? const [] : only,
        hours: hours,
        extras: extras,
        room: memberRoom.isNotEmpty ? '$memberStoryPrefix$memberRoom' : widget.room,
      );
      for (final id in posted.ids) {
        if (!video && d != null) await StoryKit.save(id, StoryKit(name: f.$1, bytes: f.$2, layers: d.layersJson()));
        if (!group) await keepStoryAudience(s, id, audience);
      }
      // My own copy, on this phone only.
      await StoryArchive.keep(out.$1, out.$2, caption.text);
      if (!mounted) return;
      nav.pop(true);
      showStoryToast(context, group ? l.skGroupShared : (memberRoom.isNotEmpty ? l.storyGroupOnlyShared(audience.name) : l.storyShared(posted.sent)));
    } catch (_) {
      if (mounted) {
        setState(() => busy = false);
        showStoryToast(context, editing != null ? l.skFailed : l.storyNoFriends);
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

  String clock(int sec) => '${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}';

  Widget _composerPage(BuildContext context, L l, Palette p, (String, Uint8List)? f, double top, double bottom) {
    const white = Color(0xFFFFFFFF);
    final e = editing;
    final startLive = e != null ? decodeLive(e.extra) : [?widget.post];
    final video = f != null && isStoryVideo(f.$1);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: EdgeInsets.only(top: top, bottom: bottom + 80),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              child: widget.postCard != null
                  ? StoryDecor(key: decor, background: widget.postCard, live: startLive, onBusy: (b) => setState(() => tools = b))
                  : f == null
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
                  : video
                  // A video: live parts only (reaction, music, round video, polls…).
                  ? StoryDecor(
                      key: decor,
                      liveOnly: true,
                      live: startLive,
                      onBusy: (b) => setState(() => tools = b),
                      background: StoryVideo(
                        key: ValueKey(f.$2.length),
                        bytes: f.$2,
                        mime: storyMime(f.$1),
                        loop: true,
                        onReady: (c) {
                          if (mounted) setState(() => length = c.value.duration);
                        },
                      ),
                    )
                  : StoryDecor(key: decor, bytes: f.$2, layers: widget.kit?.layers ?? '', live: startLive, onBusy: (b) => setState(() => tools = b)),
            ),
          ),
          // Tip 525: the parts a long video becomes; tap one to leave it out.
          if (video && !tools && parts > 1)
            Positioned(
              left: Tokens.space[3],
              right: Tokens.space[3],
              bottom: bottom + 80 + Tokens.space[3] + Tokens.closeButton + Tokens.space[2],
              child: Column(
                key: const Key('story-split'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.skSplit(parts - skipped.length),
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(
                      color: white,
                      fontWeight: Tokens.semi,
                      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
                    ),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  Row(
                    children: [
                      for (var i = 0; i < parts; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          child: GestureDetector(
                            key: Key('story-part-$i'),
                            onTap: () => setState(() => skipped.contains(i) ? skipped.remove(i) : skipped.add(i)),
                            child: Container(
                              height: Tokens.storyAlbumChip,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: skipped.contains(i) ? const Color(0x33FFFFFF) : const Color(0xCCFFFFFF),
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(i == 0 ? Tokens.radius[0] : 0),
                                  right: Radius.circular(i == parts - 1 ? Tokens.radius[0] : 0),
                                ),
                              ),
                              child: Text(
                                clock(i * partLength.inSeconds),
                                style: Tokens.caption.style.copyWith(color: skipped.contains(i) ? white : const Color(0xFF000000)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(
                    l.skSplitInfo,
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(
                      color: const Color(0xB3FFFFFF),
                      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          if (video && !tools)
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
                child: Icon(f == null || e != null ? CupertinoIcons.xmark : CupertinoIcons.chevron_back, color: white, size: 22),
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
                    if (f == null && widget.postCard == null) ...[
                      GlassCircle(
                        key: const Key('story-gallery'),
                        onTap: () => pick(ImageSource.gallery),
                        child: const Icon(CupertinoIcons.photo_on_rectangle, color: white, size: 22),
                      ),
                      const Spacer(),
                    ] else ...[
                      // A group's story: its name (everyone in it sees it).
                      if (group)
                        _Pill(
                          key: const Key('story-group'),
                          icon: CupertinoIcons.person_3_fill,
                          text: widget.roomName.isEmpty ? l.skGroupStory : widget.roomName,
                          onTap: () {},
                        )
                      else
                        // Who sees it, and for how long (Instagram has neither choice).
                        // A long group name shrinks with … instead of pushing out.
                        Flexible(
                          child: _Pill(
                            key: const Key('story-audience'),
                            icon: switch (audience.mode) {
                              'close' => CupertinoIcons.star_fill,
                              'group' => CupertinoIcons.person_3_fill,
                              _ => CupertinoIcons.person_2_fill,
                            },
                            text: audience.label(l),
                            onTap: () async {
                              final a = await pickAudience(context, audience);
                              if (a != null && mounted) setState(() => audience = a);
                            },
                          ),
                        ),
                      SizedBox(width: Tokens.space[1]),
                      if (e == null)
                        _Pill(
                          key: const Key('story-hours'),
                          icon: CupertinoIcons.clock,
                          text: l.storyHoursN(hours),
                          onTap: () async {
                            final h = await pickHours(context, hours);
                            if (h != null && mounted) setState(() => hours = h);
                          },
                        ),
                      // Tip 468: a video's cover, picked from its frames.
                      if (video && e == null) ...[
                        SizedBox(width: Tokens.space[1]),
                        _Pill(
                          key: const Key('story-cover'),
                          icon: cover == null ? CupertinoIcons.photo : CupertinoIcons.checkmark_alt,
                          text: l.skCoverPill,
                          onTap: () async {
                            final c = await pickStoryCover(context, f.$2, name: f.$1);
                            if (c != null && mounted) setState(() => cover = c);
                          },
                        ),
                      ],
                      const Spacer(),
                    ],
                    if (f == null && widget.postCard == null)
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
                          label: e != null ? l.done : l.storyShare,
                          button: true,
                          child: Container(
                            width: Tokens.closeButton,
                            height: Tokens.closeButton,
                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: busy
                                ? const CupertinoActivityIndicator(color: white)
                                : Icon(e != null ? CupertinoIcons.checkmark_alt : CupertinoIcons.arrow_right, color: p.onAccent, size: 22),
                          ),
                        ),
                      ),
                    if (f == null && widget.postCard == null) ...[const Spacer(), const SizedBox(width: Tokens.closeButton)],
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
                Flexible(
                  child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Tokens.preview.style.copyWith(color: white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A story's caption; with 전체 검색 on, #해시태그 are bold and open the
/// hashtag page (tip 459: stories with the tag that I can see).
Widget storyCaption(BuildContext context, String caption, TextStyle style) {
  final tags = Features.search ? findHashtags(caption) : const <Hashtag>[];
  if (tags.isEmpty) return Text(caption, key: const Key('story-caption'), textAlign: TextAlign.center, style: style);
  final spans = <InlineSpan>[];
  var at = 0;
  for (final h in tags) {
    if (h.start > at) spans.add(TextSpan(text: caption.substring(at, h.start)));
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          key: Key('story-tag-${h.tag}'),
          onTap: () {
            final nav = Navigator.of(context, rootNavigator: true);
            nav.maybePop();
            openHashtag(nav.context, h.text);
          },
          child: Text(
            h.text,
            style: style.copyWith(fontWeight: Tokens.semi, decoration: TextDecoration.underline, decorationColor: style.color),
          ),
        ),
      ),
    );
    at = h.end;
  }
  if (at < caption.length) spans.add(TextSpan(text: caption.substring(at)));
  return Text.rich(
    TextSpan(style: style, children: spans),
    key: const Key('story-caption'),
    textAlign: TextAlign.center,
  );
}
