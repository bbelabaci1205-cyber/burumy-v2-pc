// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스토리 남기기 (Telegram tips 393, 392 / 468 / 534) and the story parts that
// play or answer with one tap (tips 395, 408, 414):
// - change a story after posting: words, stickers, who sees it, even the
//   picture. This phone keeps the picture before the words were drawn on
//   it (never sent anywhere), so the words can be changed later;
// - keep a story on my profile past its hours, in albums, up to 3 on top;
//   a video's cover is a frame I pick. Kept stories stay inside each 1:1
//   chat's encryption: only the friends it went to see it;
// - a reaction sticker (one tap = a private reaction to the poster), music
//   from my own phone, a round selfie video, a channel post card.
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/phone.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'story_more.dart';
import 'story_video.dart';
import 'wide.dart';

// ---------------------------------------------------------------- edit kit

/// What this phone keeps to change a story later (tip 393): the picture
/// before the words / drawing were put on it, and those layers. Kept only
/// here (the web keeps it until the page closes); never sent.
class StoryKit {
  StoryKit({required this.name, required this.bytes, this.layers = ''});
  final String name;
  final Uint8List bytes;

  /// [StoryDecorState.layersJson]: words, drawing and stickers.
  final String layers;

  static final _web = <String, StoryKit>{};
  static Directory? dirOverride;

  /// Tests: keep kits in memory, like the web does.
  static bool inMemory = false;
  static bool get _mem => inMemory || (kIsWeb && dirOverride == null);
  static const _keep = 60;

  static Future<Directory> _dir() async {
    final base = dirOverride ?? await getApplicationSupportDirectory();
    final d = Directory('${base.path}/story_kits');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static bool _safe(String id) => RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(id);

  static Future<void> save(String id, StoryKit k) async {
    if (!_safe(id)) return;
    if (_mem) {
      _web[id] = k;
      return;
    }
    try {
      final d = await _dir();
      await File('${d.path}/$id.bin').writeAsBytes(k.bytes, flush: true);
      await File('${d.path}/$id.json').writeAsString(jsonEncode({'name': k.name, 'layers': k.layers}), flush: true);
      // Only the newest ones.
      final all = [
        for (final f in d.listSync())
          if (f is File && f.path.endsWith('.json')) f,
      ]..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      for (final f in all.skip(_keep)) {
        await forget(f.uri.pathSegments.last.replaceAll('.json', ''));
      }
    } catch (_) {}
  }

  static Future<StoryKit?> load(String id) async {
    if (!_safe(id)) return null;
    if (_mem) return _web[id];
    try {
      final d = await _dir();
      final j = File('${d.path}/$id.json'), b = File('${d.path}/$id.bin');
      if (!await j.exists() || !await b.exists()) return null;
      final m = jsonDecode(await j.readAsString()) as Map;
      return StoryKit(name: m['name'] as String? ?? 'story.jpg', bytes: await b.readAsBytes(), layers: m['layers'] as String? ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<void> forget(String id) async {
    _web.remove(id);
    if (!_safe(id) || _mem) return;
    try {
      final d = await _dir();
      for (final x in ['bin', 'json']) {
        final f = File('${d.path}/$id.$x');
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
  }
}

/// Who a story of mine went to, kept on this phone (never in the story:
/// friends must not learn who else got it).
StoryAudience storyAudienceOf(AppState s, String id) {
  try {
    final j = jsonDecode(s.pref('story_aud:$id', ''));
    if (j is Map && j['mode'] is String) {
      return StoryAudience(j['mode'] as String, [for (final r in (j['rooms'] as List? ?? const [])) r as String]);
    }
  } catch (_) {}
  return const StoryAudience.all();
}

Future<void> keepStoryAudience(AppState s, String id, StoryAudience a) =>
    s.setPref('story_aud:$id', a.mode == 'all' ? '' : jsonEncode({'mode': a.mode, 'rooms': a.rooms}));

/// The pin JSON a kept story carries: album name and top pin.
String storyPin({String album = '', bool top = false}) => jsonEncode({if (album.isNotEmpty) 'album': album, if (top) 'top': true});

/// Albums used in [kept], in the order they first appear.
List<String> storyAlbums(Iterable<Story> kept) {
  final out = <String>[];
  for (final x in kept) {
    if (x.album.isNotEmpty && !out.contains(x.album)) out.add(x.album);
  }
  return out;
}

/// Kept stories for a profile: top pins first, then newest first.
List<Story> profileOrder(Iterable<Story> kept) => [...kept]
  ..sort((a, b) {
    if (a.top != b.top) return a.top ? -1 : 1;
    return b.time.compareTo(a.time);
  });

// ---------------------------------------------------------------- my menu

/// The ⋯ menu on my own story (viewer). Returns true when the story
/// changed or went away (the viewer then closes and the list reloads).
Future<bool> myStoryMenu(BuildContext context, Story x, {required Future<void> Function() edit}) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final pick = await showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => CupertinoActionSheet(
      actions: [
        if (x.inRow || x.kept) CupertinoActionSheetAction(key: const Key('my-story-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.skEdit)),
        if (!x.group)
          CupertinoActionSheetAction(
            key: const Key('my-story-keep'),
            onPressed: () => Navigator.pop(c, x.kept ? 'unkeep' : 'keep'),
            child: Text(x.kept ? l.skUnkeep : l.skKeep),
          ),
        if (x.kept) ...[
          CupertinoActionSheetAction(key: const Key('my-story-album'), onPressed: () => Navigator.pop(c, 'album'), child: Text(l.skAlbumPut)),
          CupertinoActionSheetAction(key: const Key('my-story-top'), onPressed: () => Navigator.pop(c, 'top'), child: Text(x.top ? l.skUntop : l.skTop)),
        ],
        if (x.kind == 'video') CupertinoActionSheetAction(key: const Key('my-story-cover'), onPressed: () => Navigator.pop(c, 'cover'), child: Text(l.skCover)),
        CupertinoActionSheetAction(
          key: const Key('my-story-delete'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(c, 'delete'),
          child: Text(l.skDelete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return false;
  final b = s.backend;
  final aud = storyAudienceOf(s, x.id);
  final only = aud.mode == 'all' ? const <String>[] : aud.rooms;
  Future<bool> change({String? pin, bool unpin = false, String? extra}) async {
    try {
      await b.editStory(x.id, caption: x.caption ?? '', extra: extra ?? x.extra ?? '', only: only, pin: unpin ? null : (pin ?? x.pin));
      await s.refresh();
      return true;
    } catch (_) {
      if (context.mounted) showSkToast(context, l.skFailed);
      return false;
    }
  }

  switch (pick) {
    case 'edit':
      await edit();
      return true;
    case 'keep':
      final ok = await change(pin: storyPin());
      if (ok && context.mounted) showSkToast(context, l.skKeptDone);
      return ok;
    case 'unkeep':
      if (x.inRow) {
        final ok = await change(unpin: true);
        if (ok && context.mounted) showSkToast(context, l.skUnkeptDone);
        return ok;
      }
      // Its hours are over: taking it off the profile deletes it (5 s to undo).
      showUndoCountdown(context, (n) => l.skDeleteIn(n), () async {
        await b.deleteStory(x.id);
        await StoryKit.forget(x.id);
        await s.refresh();
      });
      return true;
    case 'album':
      final a = await pickStoryAlbum(context, x.album, storyAlbums(s.keptStories.where((k) => k.mine)));
      if (a == null || !context.mounted) return false;
      return change(
        pin: storyPin(album: a, top: x.top),
      );
    case 'top':
      if (!x.top && s.keptStories.where((k) => k.mine && k.top && k.id != x.id).length >= 3) {
        showSkToast(context, l.skTopFull);
        return false;
      }
      return change(
        pin: storyPin(album: x.album, top: !x.top),
      );
    case 'cover':
      final video = await b.downloadFile(x.roomId, x.eventId);
      if (!context.mounted || video.isEmpty) return false;
      final cover = await pickStoryCover(context, Uint8List.fromList(video));
      if (cover == null || !context.mounted) return false;
      try {
        final ref = await b.uploadEncrypted(cover);
        return await change(extra: withExtra(x.extra, {'cover': ref}));
      } catch (_) {
        if (context.mounted) showSkToast(context, l.skFailed);
        return false;
      }
    case 'delete':
      showUndoCountdown(context, (n) => l.skDeleteIn(n), () async {
        await b.deleteStory(x.id);
        await StoryKit.forget(x.id);
        await s.refresh();
      });
      return true;
  }
  return false;
}

/// Short dark capsule near the top (same look as the story toasts).
void showSkToast(BuildContext context, String text) {
  final o = Overlay.of(context, rootOverlay: true);
  final e = OverlayEntry(
    builder: (c) => Positioned(
      left: 0,
      right: 0,
      top: MediaQuery.paddingOf(c).top + 80,
      child: Center(
        child: Container(
          key: const Key('sk-toast'),
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

// ---------------------------------------------------------------- albums

/// Which album (tip 534): none, one of mine, or a new name. Full page,
/// no popup text box. Null = cancelled.
Future<String?> pickStoryAlbum(BuildContext context, String now, List<String> albums) => paneNav(context).push<String>(
  IosPageRoute(
    fullscreenDialog: true,
    builder: (_) => _AlbumPage(now: now, albums: albums),
  ),
);

class _AlbumPage extends StatefulWidget {
  const _AlbumPage({required this.now, required this.albums});
  final String now;
  final List<String> albums;

  @override
  State<_AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<_AlbumPage> {
  late String chosen = widget.now;
  final name = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final typed = name.text.trim();
    Widget row(String a, String label) => IosTile(
      key: Key('album-${a.isEmpty ? 'none' : a}'),
      title: Text(label),
      trailing: chosen == a && typed.isEmpty ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
      onTap: () => setState(() {
        chosen = a;
        name.clear();
      }),
    );
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.skAlbums,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('album-done'), onTap: () => Navigator.of(context).pop(typed.isNotEmpty ? typed : chosen))],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader),
        children: [
          IosSection(hasLeading: false, children: [row('', l.skAlbumNone), for (final a in widget.albums) row(a, a)]),
          IosSection(
            hasLeading: false,
            header: sectionHeader(context, l.skAlbumNew),
            footer: sectionFooter(context, l.skAlbumInfo),
            children: [
              CupertinoTextField(
                key: const Key('album-name'),
                controller: name,
                placeholder: l.skAlbumName,
                maxLength: 40,
                onChanged: (_) => setState(() {}),
                decoration: null,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
                style: Tokens.body.style.copyWith(color: p.label),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- cover

/// Picks a video's cover from frames along it (tip 468). Returns a PNG /
/// JPEG, or null.
Future<Uint8List?> pickStoryCover(BuildContext context, Uint8List video, {String name = 'story.mp4'}) => paneNav(context).push<Uint8List>(
  IosPageRoute(
    fullscreenDialog: true,
    builder: (_) => _CoverPage(video: video, name: name),
  ),
);

class _CoverPage extends StatefulWidget {
  const _CoverPage({required this.video, required this.name});
  final Uint8List video;
  final String name;

  @override
  State<_CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<_CoverPage> {
  List<Uint8List>? frames;
  int at = 0;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final f = await Phone.videoFrames(widget.video, widget.name, count: 8, height: 480);
    if (mounted) setState(() => frames = f);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final f = frames;
    const white = Color(0xFFFFFFFF);
    return CupertinoPageScaffold(
      key: const Key('cover-page'),
      backgroundColor: const Color(0xFF000000),
      navigationBar: GlassTopBar(
        title: l.skCoverTitle,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('cover-done'), onTap: f == null || f.isEmpty ? null : () => Navigator.of(context).pop(f[at]))],
        tint: const Color(0xFF000000),
      ),
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(height: Tokens.sheetHeader),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: f == null
                    ? const Center(child: CupertinoActivityIndicator(color: white))
                    : f.isEmpty
                    ? Center(
                        child: Text(
                          l.skCoverNone,
                          textAlign: TextAlign.center,
                          style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF)),
                        ),
                      )
                    : AspectRatio(
                        aspectRatio: 9 / 16,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Tokens.radius[2]),
                          child: Image.memory(f[at], key: const Key('cover-big'), fit: BoxFit.cover, gaplessPlayback: true),
                        ),
                      ),
              ),
            ),
            if (f != null && f.isNotEmpty)
              SizedBox(
                height: Tokens.coverStrip * Tokens.coverLift,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < f.length; i++)
                        GestureDetector(
                          key: Key('cover-frame-$i'),
                          onTap: () => setState(() => at = i),
                          // iOS: the chosen frame lifts a little, no glow.
                          child: AnimatedScale(
                            scale: i == at ? Tokens.coverLift : 1,
                            duration: const Duration(milliseconds: 160),
                            child: Container(
                              width: Tokens.coverStrip * 9 / 16,
                              height: Tokens.coverStrip,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(i == at ? Tokens.radius[0] : 0)),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(f[i], fit: BoxFit.cover),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(Tokens.space[3]),
              child: Text(
                l.skCoverInfo,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- thumbs

/// A story's small picture: the photo, or a video's chosen cover (tip
/// 468); a play mark when a video has none.
class StoryThumb extends StatefulWidget {
  const StoryThumb({super.key, required this.story, this.width = 300});
  final Story story;
  final int width;

  @override
  State<StoryThumb> createState() => _StoryThumbState();
}

class _StoryThumbState extends State<StoryThumb> {
  Future<List<int>>? bytes;
  String? from;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final x = widget.story;
    final key = '${x.eventId}|${x.extra}';
    if (from == key) return;
    from = key;
    final b = AppScope.of(context).backend;
    final cover = storyCover(x.extra);
    bytes = x.kind == 'image' ? b.downloadFile(x.roomId, x.eventId) : (cover.isNotEmpty ? b.downloadEncrypted(cover) : null);
  }

  @override
  void didUpdateWidget(StoryThumb old) {
    super.didUpdateWidget(old);
    if (old.story.eventId != widget.story.eventId || old.story.extra != widget.story.extra) {
      from = null;
      didChangeDependencies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final video = widget.story.kind == 'video';
    final fallback = ColoredBox(
      color: p.incoming,
      child: Icon(video ? CupertinoIcons.play_fill : CupertinoIcons.photo, color: p.secondaryLabel, size: Tokens.listIcon),
    );
    final b = bytes;
    if (b == null) return fallback;
    return FutureBuilder<List<int>>(
      future: b,
      builder: (_, s) => s.hasData && s.data!.isNotEmpty
          ? Image.memory(Uint8List.fromList(s.data!), fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: widget.width)
          : fallback,
    );
  }
}

// ---------------------------------------------------------------- profile grid

/// Stories kept on a profile (tips 392 / 534 / 468): album capsules, then a
/// 3-across grid (top pins first). Tap = watch from that one.
class KeptStories extends StatefulWidget {
  const KeptStories({super.key, required this.stories, required this.onOpen, this.title});
  final List<Story> stories;
  final void Function(List<Story> list, int at) onOpen;
  final String? title;

  @override
  State<KeptStories> createState() => _KeptStoriesState();
}

class _KeptStoriesState extends State<KeptStories> {
  String album = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final albums = storyAlbums(widget.stories);
    if (!albums.contains(album)) album = '';
    final list = profileOrder(widget.stories.where((x) => album.isEmpty || x.album == album));
    Widget chip(String a, String label) {
      final on = album == a;
      return GestureDetector(
        key: Key('kept-album-${a.isEmpty ? 'all' : a}'),
        onTap: () => setState(() => album = a),
        child: Container(
          height: Tokens.storyAlbumChip,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(label, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
        ),
      );
    }

    return Column(
      key: const Key('kept-stories'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[4], Tokens.space[3], Tokens.space[1]),
          child: sectionHeader(context, widget.title ?? l.skKeptCount(widget.stories.length)),
        ),
        if (albums.isNotEmpty)
          SizedBox(
            height: Tokens.storyAlbumChip + Tokens.space[2],
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[0]),
              children: [
                chip('', l.skAll),
                for (final a in albums) ...[SizedBox(width: Tokens.space[1]), chip(a, a)],
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              crossAxisCount: 3,
              mainAxisSpacing: Tokens.storyGridGap,
              crossAxisSpacing: Tokens.storyGridGap,
              childAspectRatio: 9 / 16,
              children: [
                for (var i = 0; i < list.length; i++)
                  GestureDetector(
                    key: Key('kept-${list[i].id}'),
                    onTap: () => widget.onOpen(list, i),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        StoryThumb(story: list[i]),
                        Positioned(
                          left: Tokens.space[1],
                          bottom: Tokens.space[1],
                          child: Text(
                            '${list[i].time.month}/${list[i].time.day}',
                            style: Tokens.caption.style.copyWith(
                              color: const Color(0xFFFFFFFF),
                              shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
                            ),
                          ),
                        ),
                        if (list[i].top)
                          Positioned(
                            right: Tokens.space[1],
                            top: Tokens.space[1],
                            child: const Icon(
                              CupertinoIcons.pin_fill,
                              key: Key('kept-top'),
                              size: Tokens.listIconSmall,
                              color: Color(0xFFFFFFFF),
                              shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
                            ),
                          ),
                        if (list[i].kind == 'video')
                          const Positioned(
                            right: 6,
                            bottom: 6,
                            child: Icon(
                              CupertinoIcons.play_fill,
                              size: 14,
                              color: Color(0xFFFFFFFF),
                              shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- one-tap parts

/// Reaction sticker, music, round video or channel post on a story (tips
/// 395 / 408 / 414). In the editor it only shows; in the viewer [onTap]
/// reacts, mutes or opens.
class StoryMediaPart extends StatefulWidget {
  const StoryMediaPart({super.key, required this.item, this.chosen = false, this.muted = false, this.load, this.onTap});
  final StoryLive item;

  /// Reaction already sent (kept on this phone).
  final bool chosen;

  /// Sound off (music / round video).
  final bool muted;

  /// Gets the part's file (viewer); null = use [StoryLive.bytes].
  final Future<List<int>> Function(String file)? load;
  final VoidCallback? onTap;

  @override
  State<StoryMediaPart> createState() => _StoryMediaPartState();
}

class _StoryMediaPartState extends State<StoryMediaPart> with SingleTickerProviderStateMixin {
  late final AnimationController pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Future<List<int>>? video;
  VideoPlayerController? round;

  @override
  void initState() {
    super.initState();
    final it = widget.item;
    if (it.kind == 'round') {
      video = it.bytes != null ? Future.value(it.bytes!) : (widget.load != null && it.file.isNotEmpty ? widget.load!(it.file) : null);
    }
  }

  @override
  void didUpdateWidget(StoryMediaPart old) {
    super.didUpdateWidget(old);
    if (widget.chosen && !old.chosen) pop.forward(from: 0);
    round?.setVolume(widget.muted ? 0 : 1);
  }

  @override
  void dispose() {
    pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    Widget child;
    switch (it.kind) {
      case 'react':
        child = AnimatedBuilder(
          animation: pop,
          builder: (_, _) {
            // A quick bounce when I react (iOS spring feel).
            final t = pop.value;
            final s = 1 + (t < .5 ? t * .5 : (1 - t) * .5);
            return Transform.scale(
              scale: s,
              child: Container(
                width: Tokens.storyReact,
                height: Tokens.storyReact,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.chosen ? const Color(0xFFFFFFFF) : const Color(0xE6FFFFFF),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: Text(
                  it.q,
                  style: const TextStyle(fontSize: Tokens.storyReactEmoji, height: 1.1, fontFamilyFallback: Tokens.emojiFallback),
                ),
              ),
            );
          },
        );
      case 'music':
        child = LiquidGlass(
          radius: Tokens.capsule,
          child: SizedBox(
            height: Tokens.storyMusic,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.muted ? CupertinoIcons.speaker_slash_fill : CupertinoIcons.music_note_2, color: white, size: Tokens.listIconSmall),
                  SizedBox(width: Tokens.space[1]),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      [it.q, it.site].where((x) => x.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: white, fontWeight: Tokens.semi),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case 'round':
        child = Container(
          width: Tokens.storyRound,
          height: Tokens.storyRound,
          padding: const EdgeInsets.all(Tokens.storyRoundRim),
          decoration: const BoxDecoration(
            color: white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: const Color(0xFF1C1C1E),
              child: FutureBuilder<List<int>>(
                future: video,
                builder: (_, s) => s.hasData && s.data!.isNotEmpty
                    ? StoryVideo(
                        key: ValueKey(it.file.isEmpty ? it.bytes.hashCode : it.file.hashCode),
                        bytes: Uint8List.fromList(s.data!),
                        mime: it.mime.isEmpty ? 'video/mp4' : it.mime,
                        loop: true,
                        onReady: (c) {
                          round = c;
                          c.setVolume(widget.muted ? 0 : 1);
                        },
                      )
                    : const Center(child: Icon(CupertinoIcons.person_crop_circle, color: Color(0x99FFFFFF), size: 40)),
              ),
            ),
          ),
        );
      default: // post
        child = LiquidGlass(
          radius: Tokens.capsule,
          child: SizedBox(
            height: Tokens.closeButton,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(CupertinoIcons.news_solid, color: white, size: Tokens.listIconSmall),
                  SizedBox(width: Tokens.space[1]),
                  Text(
                    l.skPostOpen,
                    style: Tokens.preview.style.copyWith(color: white, fontWeight: Tokens.semi),
                  ),
                  SizedBox(width: Tokens.space[0]),
                  const Icon(CupertinoIcons.chevron_right, color: white, size: 14),
                ],
              ),
            ),
          ),
        );
    }
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: child);
  }
}

/// Plays a story's music while it shows (tip 395).
class StoryMusic {
  StoryMusic();
  VoicePlayer? _p;
  String? _key;

  Future<void> play(AppState s, StoryLive it, {required bool muted}) async {
    if (it.file.isEmpty && it.bytes == null) return;
    final key = it.file.isEmpty ? 'local${it.bytes.hashCode}' : it.file;
    try {
      _p ??= VoiceKit.player();
      if (_key != key) {
        final bytes = it.bytes ?? Uint8List.fromList(await s.backend.downloadEncrypted(it.file));
        _key = key;
        if (muted) return;
        await _p!.play(bytes, key);
      } else if (!muted) {
        await _p!.play(Uint8List(0), key);
      }
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _p?.pause();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _p?.dispose();
    } catch (_) {}
    _p = null;
    _key = null;
  }
}

/// Music from my own phone (tip 395): no shared music library, so no
/// licences; the file goes sealed with the story to the same friends.
Future<StoryLive?> pickStoryMusic(BuildContext context) async {
  final l = L.of(context);
  try {
    final f = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'audio', extensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus'], mimeTypes: ['audio/*'], uniformTypeIdentifiers: ['public.audio']),
      ],
    );
    if (f == null) return null;
    final bytes = await f.readAsBytes();
    if (bytes.length > storyMusicMax) {
      if (context.mounted) showSkToast(context, l.skMusicTooBig);
      return null;
    }
    final name = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
    final ext = f.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      'ogg' || 'opus' => 'audio/ogg',
      'aac' => 'audio/aac',
      _ => 'audio/mp4',
    };
    // "가수 - 제목" file names become title and artist.
    final parts = name.split(' - ');
    return StoryLive(
      kind: 'music',
      q: (parts.length > 1 ? parts.sublist(1).join(' - ') : name).trim(),
      site: parts.length > 1 ? parts.first.trim() : '',
      mime: mime,
      bytes: bytes,
      at: const Offset(.5, .2),
    );
  } catch (_) {
    return null;
  }
}

const storyMusicMax = 10 * 1024 * 1024;

/// Reaction faces to pick from (tip 395).
Future<String?> pickStoryReaction(BuildContext context) => showCupertinoModalPopup<String>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (c) => CupertinoActionSheet(
    title: Text(L.of(c).skReactPick),
    message: Text(L.of(c).skReactInfo),
    actions: [
      CupertinoActionSheetAction(
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final e in StoryLive.reactions)
              GestureDetector(
                key: Key('react-pick-$e'),
                onTap: () => Navigator.pop(c, e),
                child: Text(e, style: const TextStyle(fontSize: 34, fontFamilyFallback: Tokens.emojiFallback)),
              ),
          ],
        ),
      ),
    ],
    cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(L.of(c).cancel)),
  ),
);

/// Puts each part's own file (music, round video) up, sealed, just before
/// sharing: nothing is uploaded for a story that is never posted.
Future<void> uploadStoryParts(Backend b, List<StoryLive> live) async {
  for (final it in live) {
    final bytes = it.bytes;
    if (bytes != null && it.file.isEmpty) {
      it.file = await b.uploadEncrypted(bytes);
    }
  }
}

// ---------------------------------------------------------------- my profile stories

/// 프로필 스토리: the stories I kept on my profile (tips 392 / 534 / 468),
/// with their albums; tap one to watch it (⋯ there changes it).
class MyKeptStoriesPage extends StatelessWidget {
  const MyKeptStoriesPage({super.key, required this.open});
  final Future<void> Function(BuildContext context, List<Story> list, int at) open;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = s.keptStories.where((x) => x.mine && !x.group).toList();
    return CupertinoPageScaffold(
      key: const Key('my-kept-page'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.skKeptMine, leading: const [GlassBack()], tint: p.background),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader, bottom: Tokens.space[5]),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[1], Tokens.space[5], 0),
            child: Text(l.skKeptInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ),
          if (mine.isEmpty)
            Padding(
              padding: EdgeInsets.all(Tokens.space[5]),
              child: Text(
                l.skKeptEmpty,
                key: const Key('my-kept-empty'),
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
              ),
            )
          else
            KeptStories(stories: mine, title: l.skKeptCount(mine.length), onOpen: (list, i) => open(context, list, i)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- channel post -> story

/// A channel post drawn as a story picture (tip 414): the channel's photo
/// and name over a soft brand gradient, the post's words (and photo).
class ChannelPostCard extends StatelessWidget {
  const ChannelPostCard({super.key, required this.roomId, required this.name, required this.text, this.photo});
  final String roomId, name, text;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    const ink = Color(0xFF000000);
    return DecoratedBox(
      key: const Key('post-card-bg'),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: p.storyRing),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[4]),
          child: Container(
            key: const Key('post-card'),
            constraints: const BoxConstraints(maxWidth: 320),
            padding: EdgeInsets.all(Tokens.space[3]),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Avatar(name: name, size: Tokens.memberAvatar, squircle: true, channel: true, roomId: roomId),
                    SizedBox(width: Tokens.space[2]),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.listName.style.copyWith(color: ink),
                      ),
                    ),
                  ],
                ),
                if (photo != null) ...[
                  SizedBox(height: Tokens.space[2]),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Tokens.radius[1]),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: Image.memory(photo!, fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                ],
                if (text.trim().isNotEmpty) ...[
                  SizedBox(height: Tokens.space[2]),
                  Text(
                    text.trim(),
                    maxLines: photo != null ? 5 : 12,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: ink),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
