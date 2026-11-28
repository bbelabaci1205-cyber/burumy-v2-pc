// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 친구 피드 댓글 — 아는 친구 댓글만 (core/feed_comments.dart): the short
// list under a post and the comments page. Our own layout in iOS 27
// sizes; WeChat Moments is only the idea.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/feed_comments.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'wide.dart';

/// The name I know [who] by.
String commenterName(AppState s, L l, String who) {
  if (who == s.backend.userId) return l.you;
  final c = s.chats.where((c) => c.isDirect && c.peer == who).firstOrNull;
  return c == null ? displayId(who).replaceFirst('@', '') : nameOf(s, c);
}

Future<void> openFeedComments(BuildContext context, Story post) => paneNav(context).push(IosPageRoute<void>(builder: (_) => FeedCommentsPage(post: post)));

/// Under a post: the newest two comments I may see and "댓글 N개 모두 보기".
class FeedCommentsPreview extends StatelessWidget {
  const FeedCommentsPreview({super.key, required this.post});
  final Story post;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final list = FeedComments.visible(s, post);
    if (list.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      key: Key('feed-comments-${post.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openFeedComments(context, post),
      child: Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (list.length > 2)
              Padding(
                padding: EdgeInsets.only(bottom: Tokens.space[0]),
                child: Text(l.feedCommentsMore(list.length), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              ),
            for (final c in list.skip(list.length > 2 ? list.length - 2 : 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${commenterName(s, l, c.who)} ',
                        style: TextStyle(color: p.label, fontWeight: FontWeight.w500),
                      ),
                      TextSpan(text: c.text),
                    ],
                  ),
                  key: Key('feed-comment-${c.id}'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.preview.style.copyWith(color: p.label),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FeedCommentsPage extends StatefulWidget {
  const FeedCommentsPage({super.key, required this.post});
  final Story post;

  @override
  State<FeedCommentsPage> createState() => _FeedCommentsPageState();
}

class _FeedCommentsPageState extends State<FeedCommentsPage> {
  final text = TextEditingController();
  bool busy = false;

  @override
  void initState() {
    super.initState();
    text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final t = text.text.trim();
    if (t.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await FeedComments.add(AppScope.read(context), widget.post, t);
      text.clear();
    } catch (_) {}
    if (mounted) setState(() => busy = false);
  }

  Future<void> hold(FeedComment c) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    if (!widget.post.mine && c.who != s.backend.userId) return;
    final go = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (x) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            key: const Key('feed-comment-delete'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(x, true),
            child: Text(l.feedCommentDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
      ),
    );
    if (go == true) await FeedComments.remove(s, widget.post, c);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final list = FeedComments.visible(s, widget.post);
    final top = MediaQuery.paddingOf(context).top + Tokens.sheetHeader;
    return CupertinoPageScaffold(
      key: const Key('feed-comments-page'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.feedCommentsTitle, leading: const [GlassBack()], tint: p.background),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, top + Tokens.space[1], 0, Tokens.space[3]),
              children: [
                // Who I see comments from, in one line, then why.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                  child: Row(
                    children: [
                      Icon(widget.post.mine ? CupertinoIcons.person_2_fill : CupertinoIcons.person_crop_circle_badge_checkmark, size: 16, color: p.accent),
                      SizedBox(width: Tokens.space[1]),
                      Expanded(
                        child: Text(
                          widget.post.mine ? l.feedCommentsMine : l.feedCommentsKnown,
                          key: const Key('feed-comments-rule'),
                          style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[0], Tokens.space[4], Tokens.space[3]),
                  child: Text(l.feedCommentsInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ),
                for (final c in list)
                  GestureDetector(
                    key: Key('feed-comment-row-${c.id}'),
                    behavior: HitTestBehavior.opaque,
                    onLongPress: () => hold(c),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], Tokens.space[1]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Avatar(name: commenterName(s, l, c.who), size: 32, userId: c.who),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        commenterName(s, l, c.who),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    SizedBox(width: Tokens.space[1]),
                                    Text(shortTime(context, c.at), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                  ],
                                ),
                                SizedBox(height: Tokens.nameToSub),
                                Text(c.text, style: Tokens.body.style.copyWith(color: p.label)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Write a comment (iOS 27 glass field and a round send button).
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], MediaQuery.paddingOf(context).bottom + Tokens.space[1]),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    key: const Key('feed-comment-input'),
                    controller: text,
                    placeholder: l.feedCommentHint,
                    maxLength: FeedComments.maxText,
                    minLines: 1,
                    maxLines: 4,
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                    style: Tokens.body.style.copyWith(color: p.label),
                    placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                    decoration: BoxDecoration(color: p.list, borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                SizedBox(width: Tokens.space[1]),
                TextFieldTapRegion(
                  child: GestureDetector(
                    key: const Key('feed-comment-send'),
                    onTap: text.text.trim().isEmpty ? null : send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: text.text.trim().isEmpty ? p.incoming : p.accent, shape: BoxShape.circle),
                      child: busy
                          ? const CupertinoActivityIndicator()
                          : Icon(CupertinoIcons.arrow_up, size: 20, color: text.text.trim().isEmpty ? p.secondaryLabel : p.onAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
