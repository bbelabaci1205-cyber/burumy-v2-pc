// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Friend feed: photos and words for 1:1 friends only. No ads, no public
// page, no follower counts. Each post goes inside each 1:1 chat's own
// encryption (the same path as stories, without the 24-hour timer). A like
// is a small encrypted note to the poster alone, so only the poster sees
// how many; a reply goes into our 1:1 chat.
//
// Built but hidden (Features.feed off): Eric 2026-11-24 "만들고 빼고 시기를 보자".
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'stories.dart';
import 'story_more.dart';
import 'story_video.dart';
import 'wide.dart';

Future<void> openFeed(BuildContext context) => Navigator.of(context).push(IosPageRoute<void>(builder: (_) => const FeedPage()));

/// Pictures already fetched (event id -> bytes), kept while the app runs.
final _pictures = <String, Future<List<int>>>{};

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  /// A post waiting to be deleted (5 s to undo).
  String? pending;
  int left = 0;
  Timer? timer;

  /// Likes changed here before the next refresh (post id -> on).
  final liked = <String, bool>{};

  @override
  void dispose() {
    timer?.cancel();
    final id = pending;
    if (id != null) unawaited(AppScope.read(context).backend.deleteStory(id).catchError((_) {}));
    super.dispose();
  }

  void delete(Story x) {
    final s = AppScope.read(context);
    final before = pending;
    if (before != null) unawaited(s.backend.deleteStory(before).catchError((_) {}));
    timer?.cancel();
    setState(() {
      pending = x.id;
      left = 5;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (left > 1) {
        setState(() => left--);
        return;
      }
      t.cancel();
      final id = pending;
      setState(() => pending = null);
      if (id != null) {
        try {
          await s.backend.deleteStory(id);
        } catch (_) {}
        await s.refresh();
      }
    });
  }

  void undo() {
    timer?.cancel();
    setState(() => pending = null);
  }

  Future<void> like(Story x, bool on) async {
    final s = AppScope.read(context);
    setState(() => liked[x.id] = on);
    try {
      await s.backend.feedLike(x.roomId, x.id, on: on);
    } catch (_) {
      if (mounted) setState(() => liked.remove(x.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final posts = [
      for (final x in s.feed)
        if (x.id != pending) x,
    ];
    final top = MediaQuery.paddingOf(context).top + Tokens.sheetHeader;
    return CupertinoPageScaffold(
      key: const Key('feed-page'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.feedTitle,
        leading: const [GlassBack()],
        trailing: [
          GlassCircle(
            key: const Key('feed-new'),
            onTap: () async {
              await paneNav(context).push(IosPageRoute<void>(fullscreenDialog: true, builder: (_) => const FeedComposer()));
              await s.refresh();
            },
            child: GlassCircle.icon(context, CupertinoIcons.plus),
          ),
        ],
        tint: p.background,
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(padding: EdgeInsets.only(top: top)),
              CupertinoSliverRefreshControl(onRefresh: s.refresh),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[4], 0, Tokens.space[4], Tokens.space[2]),
                  child: Text(
                    l.feedInfo,
                    key: const Key('feed-info'),
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                  ),
                ),
              ),
              if (posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      l.feedEmpty,
                      key: const Key('feed-empty'),
                      style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => SizedBox(height: Tokens.space[2]),
                  itemBuilder: (_, i) {
                    final x = posts[i];
                    final me = s.backend.userId ?? '';
                    final likers = s.feedLikes.where((k) => k.postId == x.id && !k.mine).length;
                    final iLike = liked[x.id] ?? s.feedLikes.any((k) => k.postId == x.id && k.sender == me);
                    return FeedCard(
                      key: Key('feed-post-${x.id}'),
                      post: x,
                      likes: likers,
                      liked: iLike,
                      onLike: () => like(x, !iLike),
                      onDelete: () => delete(x),
                    );
                  },
                ),
              SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5])),
            ],
          ),
          if (pending != null)
            Positioned(
              left: Tokens.space[3],
              right: Tokens.space[3],
              bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[3],
              child: LiquidGlass(
                key: const Key('feed-undo-bar'),
                radius: Tokens.closeButton / 2,
                child: SizedBox(
                  height: Tokens.closeButton,
                  child: Row(
                    children: [
                      SizedBox(width: Tokens.space[4]),
                      Expanded(
                        child: Text(l.feedDeleted, style: Tokens.preview.style.copyWith(color: p.label)),
                      ),
                      CupertinoButton(
                        key: const Key('feed-undo'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                        onPressed: undo,
                        child: Text('${l.undo} $left', style: Tokens.preview.style.copyWith(color: p.accent)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One post: who and when, the picture (or words), like and reply.
class FeedCard extends StatelessWidget {
  const FeedCard({super.key, required this.post, required this.likes, required this.liked, required this.onLike, required this.onDelete});
  final Story post;

  /// How many friends liked it (shown only on my own posts).
  final int likes;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final x = post;
    final name = storyName(s, l, x);
    final words = (x.caption ?? '').trim();
    final pad = EdgeInsets.symmetric(horizontal: Tokens.space[4]);
    return ColoredBox(
      color: p.list,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[3]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: pad,
              child: Row(
                children: [
                  Avatar(name: name, size: 40, userId: x.mine ? s.backend.userId : x.sender),
                  SizedBox(width: Tokens.space[2]),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                        ),
                        Text(shortTime(context, x.time), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      ],
                    ),
                  ),
                  if (x.mine)
                    CupertinoButton(
                      key: Key('feed-more-${x.id}'),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                      onPressed: () async {
                        final go = await showCupertinoModalPopup<bool>(
                          useRootNavigator: !Wide.on,
                          context: context,
                          builder: (c) => CupertinoActionSheet(
                            actions: [
                              CupertinoActionSheetAction(
                                key: const Key('feed-delete'),
                                isDestructiveAction: true,
                                onPressed: () => Navigator.pop(c, true),
                                child: Text(l.delete),
                              ),
                            ],
                            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                          ),
                        );
                        if (go == true) onDelete();
                      },
                      child: Icon(CupertinoIcons.ellipsis, color: p.secondaryLabel, size: 22),
                    ),
                ],
              ),
            ),
            if (x.kind == 'text') ...[
              SizedBox(height: Tokens.space[2]),
              Padding(
                padding: pad,
                child: Text(words, style: Tokens.body.style.copyWith(color: p.label)),
              ),
            ] else ...[
              SizedBox(height: Tokens.space[2]),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: _Picture(post: x),
              ),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[4], 0),
              child: Row(
                children: [
                  if (!x.mine) ...[
                    CupertinoButton(
                      key: Key('feed-like-${x.id}'),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                      onPressed: onLike,
                      child: Semantics(
                        label: l.feedLike,
                        selected: liked,
                        child: Icon(liked ? CupertinoIcons.heart_fill : CupertinoIcons.heart, color: liked ? Palette.tileRed : p.label, size: 26),
                      ),
                    ),
                    CupertinoButton(
                      key: Key('feed-reply-${x.id}'),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                      onPressed: () => paneNav(context).push(IosPageRoute<void>(fullscreenDialog: true, builder: (_) => _FeedReply(post: x))),
                      child: Semantics(
                        label: l.feedReply,
                        child: Icon(CupertinoIcons.chat_bubble, color: p.label, size: 25),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: EdgeInsets.only(left: Tokens.space[2]),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.heart_fill, color: Palette.tileRed, size: 18),
                          SizedBox(width: Tokens.space[0]),
                          Text(
                            l.feedLikesN(likes),
                            key: Key('feed-likes-${x.id}'),
                            style: Tokens.preview.style.copyWith(color: p.label),
                          ),
                          SizedBox(width: Tokens.space[1]),
                          Text('· ${l.feedOnlyMe}', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (x.kind != 'text' && words.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
                child: Text(words, style: Tokens.body.style.copyWith(color: p.label)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.post});
  final Story post;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final f = _pictures.putIfAbsent(post.eventId, () => s.backend.downloadFile(post.roomId, post.eventId));
    return ColoredBox(
      color: p.incoming,
      child: FutureBuilder<List<int>>(
        future: f,
        builder: (_, snap) {
          final b = snap.data;
          if (b == null) {
            return snap.hasError ? Icon(CupertinoIcons.photo, color: p.secondaryLabel) : const Center(child: CupertinoActivityIndicator());
          }
          final bytes = b is Uint8List ? b : Uint8List.fromList(b);
          if (post.kind == 'video') return StoryVideo(bytes: bytes, mime: 'video/mp4', loop: true);
          return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity, cacheWidth: 1080, gaplessPlayback: true);
        },
      ),
    );
  }
}

/// Reply to a friend's post: goes into our 1:1 chat only.
class _FeedReply extends StatefulWidget {
  const _FeedReply({required this.post});
  final Story post;

  @override
  State<_FeedReply> createState() => _FeedReplyState();
}

class _FeedReplyState extends State<_FeedReply> {
  final text = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final t = text.text.trim();
    if (t.isEmpty || busy) return;
    final s = AppScope.read(context);
    final l = L.of(context);
    final words = (widget.post.caption ?? '').trim();
    final about = words.isEmpty ? l.feedAddPhoto : (words.length > 30 ? '${words.substring(0, 30)}…' : words);
    setState(() => busy = true);
    try {
      await s.backend.sendText(widget.post.roomId, '${l.feedReplyPrefix} 「$about」\n$t');
      if (!mounted) return;
      Navigator.of(context).pop();
      showStoryToast(context, l.storyReplied);
    } catch (_) {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.feedReply,
        leading: const [GlassBack(close: true)],
        trailing: [_Capsule(key: const Key('feed-reply-send'), text: l.send, busy: busy, onTap: send)],
        tint: p.background,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[4], MediaQuery.paddingOf(context).top + Tokens.sheetHeader + Tokens.space[2], Tokens.space[4], 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.feedReplyHint, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            SizedBox(height: Tokens.space[2]),
            CupertinoTextField(
              key: const Key('feed-reply-input'),
              controller: text,
              autofocus: true,
              maxLines: 6,
              minLines: 3,
              maxLength: 1000,
              padding: EdgeInsets.all(Tokens.space[3]),
              style: Tokens.body.style.copyWith(color: p.label),
              decoration: BoxDecoration(color: p.list, borderRadius: BorderRadius.circular(Tokens.radius[2])),
            ),
          ],
        ),
      ),
    );
  }
}

/// New post: words, an optional photo or video, and who sees it.
class FeedComposer extends StatefulWidget {
  const FeedComposer({super.key, this.picked});

  /// For tests: a picture already chosen (name, bytes).
  final (String, List<int>)? picked;

  @override
  State<FeedComposer> createState() => _FeedComposerState();
}

class _FeedComposerState extends State<FeedComposer> {
  final text = TextEditingController();
  (String, List<int>)? photo;
  StoryAudience audience = const StoryAudience.all();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    photo = widget.picked;
    text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    try {
      final x = await ImagePicker().pickMedia(imageQuality: 85, maxWidth: 2160);
      if (x == null) return;
      final b = await x.readAsBytes();
      if (mounted) setState(() => photo = (x.name, b));
    } catch (_) {}
  }

  bool get ready => !busy && (photo != null || text.text.trim().isNotEmpty);

  Future<void> post() async {
    if (!ready) return;
    final s = AppScope.read(context);
    final l = L.of(context);
    final nav = Navigator.of(context);
    setState(() => busy = true);
    try {
      final f = photo;
      final n = await s.backend.postStory(
        mime: f == null ? '' : storyMime(f.$1),
        bytes: f?.$2 ?? const [],
        caption: text.text,
        only: audience.mode == 'all' ? const [] : audience.rooms,
        hours: 0,
      );
      if (!mounted) return;
      nav.pop();
      showStoryToast(context, l.feedPosted(n));
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
    final f = photo;
    return CupertinoPageScaffold(
      key: const Key('feed-composer'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.feedNew,
        leading: const [GlassBack(close: true)],
        trailing: [_Capsule(key: const Key('feed-post'), text: l.feedPost, busy: busy, onTap: ready ? post : null)],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          Tokens.space[4],
          MediaQuery.paddingOf(context).top + Tokens.sheetHeader + Tokens.space[2],
          Tokens.space[4],
          Tokens.space[5],
        ),
        children: [
          CupertinoTextField(
            key: const Key('feed-input'),
            controller: text,
            placeholder: l.feedHint,
            maxLines: 8,
            minLines: 4,
            maxLength: 2000,
            padding: EdgeInsets.all(Tokens.space[3]),
            style: Tokens.body.style.copyWith(color: p.label),
            placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
            decoration: BoxDecoration(color: p.list, borderRadius: BorderRadius.circular(Tokens.radius[2])),
          ),
          SizedBox(height: Tokens.space[3]),
          if (f != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    isStoryVideo(f.$1)
                        ? StoryVideo(bytes: Uint8List.fromList(f.$2), mime: storyMime(f.$1), loop: true)
                        : Image.memory(Uint8List.fromList(f.$2), fit: BoxFit.cover, cacheWidth: 1080),
                    Positioned(
                      top: Tokens.space[2],
                      right: Tokens.space[2],
                      child: GlassCircle(
                        key: const Key('feed-photo-remove'),
                        size: 32,
                        onTap: () => setState(() => photo = null),
                        child: Semantics(
                          label: l.feedRemovePhoto,
                          child: const Icon(CupertinoIcons.xmark, color: Color(0xFFFFFFFF), size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: Tokens.space[3]),
          Row(
            children: [
              if (f == null) ...[
                _Choice(key: const Key('feed-photo'), icon: CupertinoIcons.photo, text: l.feedAddPhoto, onTap: pick),
                SizedBox(width: Tokens.space[2]),
              ],
              _Choice(
                key: const Key('feed-audience'),
                icon: audience.mode == 'close' ? CupertinoIcons.star_fill : CupertinoIcons.person_2_fill,
                text: audience.label(l),
                onTap: () async {
                  final a = await pickAudience(context, audience);
                  if (a != null && mounted) setState(() => audience = a);
                },
              ),
            ],
          ),
          SizedBox(height: Tokens.space[3]),
          Text(l.feedInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ],
      ),
    );
  }
}

/// Filled accent capsule in the top bar (올리기 / 보내기).
class _Capsule extends StatelessWidget {
  const _Capsule({super.key, required this.text, required this.onTap, this.busy = false});
  final String text;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Tokens.closeButton,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
        decoration: BoxDecoration(color: on ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
        alignment: Alignment.center,
        child: busy
            ? const CupertinoActivityIndicator()
            : Text(
                text,
                style: Tokens.body.style.copyWith(color: on ? p.onAccent : p.secondaryLabel, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}

/// Light capsule choice under the text (사진 / 모든 친구).
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Tokens.closeButton,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        decoration: BoxDecoration(color: p.list, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: p.accent, size: 18),
            SizedBox(width: Tokens.space[1]),
            Text(text, style: Tokens.preview.style.copyWith(color: p.label)),
          ],
        ),
      ),
    );
  }
}
