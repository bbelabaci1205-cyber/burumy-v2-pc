// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 해시태그 (Telegram tips 454 · 484 · 459). Tapping #여행 in a message or a
// story caption opens this page:
//
// - tabs 이 대화 / 내 메시지 / 공개 글 (454); the tag is marked yellow;
// - the bottom bar counts the messages and switches 목록으로 보기 ↔
//   대화로 보기, and photos-only results show as a grid (484);
// - #여행@adventures looks in that public chat only (484): the chat when
//   I'm in it, else a card to join it (the server never learns the tag);
// - friends' stories with the tag sit in a row on top (459, only stories
//   this phone can already see).
//
// Everything except 공개 글 is looked up on this phone (core/search.dart).
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/room_links.dart';
import '../core/search.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'glass.dart';
import 'invite_links.dart' show openJoinLink;
import 'ios_route.dart';
import 'profile_page.dart' show SharedThumb;
import 'search_page.dart';
import 'stories.dart' show openStories, storyGroups, storyName;
import 'wide.dart';

/// Opens the hashtag page. [roomId]: the chat it was tapped in (shows the
/// 이 대화 tab). [tag] may carry "@address".
Future<void> openHashtag(BuildContext context, String tag, {String? roomId}) {
  final (t, address) = parseHashtag(tag);
  final s = AppScope.read(context);
  final text = address == null ? '#$t' : '#$t@$address';
  unawaited(s.setPref(recentSearchPref, addRecentSearch(s.pref(recentSearchPref, ''), 'tag:$text')));
  return Navigator.of(context, rootNavigator: !Wide.on).push(
    IosPageRoute(
      builder: (_) => HashtagPage(tag: t, address: address, roomId: roomId),
    ),
  );
}

class HashtagPage extends StatefulWidget {
  const HashtagPage({super.key, required this.tag, this.address, this.roomId});

  /// Without '#'.
  final String tag;

  /// "#tag@address": that public chat only.
  final String? address;
  final String? roomId;

  @override
  State<HashtagPage> createState() => _HashtagPageState();
}

class _HashtagPageState extends State<HashtagPage> {
  /// 'chat' (이 대화), 'mine' (내 메시지) or 'public' (공개 글).
  late String scope = hasChat ? 'chat' : 'mine';

  /// 'list', 'chat' (bubbles) — photos-only results show as a grid.
  String view = 'list';
  List<Found>? mine;
  List<PublicPost>? posts;

  /// The public chat of "#tag@address" (to join it), once looked up.
  LinkPeek? peek;
  bool peekMissing = false;

  String get text => widget.address == null ? '#${widget.tag}' : '#${widget.tag}@${widget.address}';
  AppState get app => AppScope.read(context);

  /// The chat this page looks in for 이 대화.
  String? get chatId {
    if (widget.address == null) return widget.roomId;
    final p = peek;
    return p != null && app.chats.any((c) => c.roomId == p.roomId) ? p.roomId : null;
  }

  bool get hasChat => widget.roomId != null || widget.address != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final b = app.backend;
    if (widget.address != null) {
      try {
        final p = await b.peekAddress(widget.address!);
        if (mounted) setState(() => peek = p);
      } catch (_) {
        if (mounted) setState(() => peekMissing = true);
      }
    }
    final all = await b.searchEverywhere('#${widget.tag}', limit: 1000).catchError((_) => <Found>[]);
    if (!mounted) return;
    setState(
      () => mine = [
        for (final f in all)
          if (hasHashtag(searchText(f.msg), widget.tag)) f,
      ],
    );
  }

  Future<void> loadPosts() async {
    if (posts != null) return;
    final r = await app.backend.searchPublicPosts('#${widget.tag}').catchError((_) => <PublicPost>[]);
    if (!mounted) return;
    setState(
      () => posts = [
        for (final x in r)
          if (hasHashtag(x.text, widget.tag) && (widget.address == null || x.address == widget.address)) x,
      ],
    );
  }

  List<Found>? get hits {
    final m = mine;
    if (m == null) return null;
    if (scope == 'chat') {
      final id = chatId;
      return id == null
          ? const []
          : [
              for (final f in m)
                if (f.roomId == id) f,
            ];
    }
    // #tag@address under 내 메시지: still only that chat's tag.
    return m;
  }

  /// Friends' stories (and mine) with the tag in the caption (tip 459).
  List<Story> get stories => [
    for (final x in app.stories)
      if (!x.feed && hasHashtag(x.caption ?? '', widget.tag)) x,
  ];

  ChatPreview? chatOf(String roomId) => app.chats.where((c) => c.roomId == roomId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    AppScope.of(context);
    final h = hits;
    final pub = scope == 'public';
    final count = pub ? (posts?.length ?? 0) : (h?.length ?? 0);
    final media = !pub && h != null && h.isNotEmpty && h.every((f) => f.msg.kind == 'image' || f.msg.kind == 'video');
    final st = stories;
    return CupertinoPageScaffold(
      backgroundColor: view == 'chat' && !pub ? p.chatBackground : p.list,
      navigationBar: GlassTopBar(back: true, title: text),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  key: const Key('tag-scope'),
                  groupValue: scope,
                  onValueChanged: (v) {
                    if (v == null) return;
                    setState(() => scope = v);
                    if (v == 'public') unawaited(loadPosts());
                  },
                  children: {
                    if (hasChat) 'chat': Text(l.tagThisChat, key: const Key('tag-scope-chat')),
                    'mine': Text(l.tagMyMessages, key: const Key('tag-scope-mine')),
                    'public': Text(l.tagPublicPosts, key: const Key('tag-scope-public')),
                  },
                ),
              ),
            ),
            if (st.isNotEmpty && !pub) storyRow(p, l, st),
            if (scope == 'chat' && widget.address != null && chatId == null) joinCard(p, l),
            Expanded(
              child: pub
                  ? publicList(p, l)
                  : h == null
                  ? const Center(child: CupertinoActivityIndicator())
                  : h.isEmpty
                  ? ListView(children: [EmptyMark(text: l.searchNoResults)])
                  : media
                  ? grid(h)
                  : view == 'chat'
                  ? bubbles(p, l, h)
                  : list(p, l, h),
            ),
            bottomBar(p, l, count, canToggle: !pub && !media && (h?.isNotEmpty ?? false)),
          ],
        ),
      ),
    );
  }

  /// "스토리 N개 · 스토리 보기 · #여행": faces of the people, opens them.
  Widget storyRow(Palette p, L l, List<Story> st) {
    final groups = storyGroups(app, st);
    return PressRow(
      key: const Key('tag-stories'),
      onTap: () => openStories(context, groups, 0),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
        child: Row(
          children: [
            SizedBox(
              width: Tokens.memberAvatar + Tokens.space[3] * (groups.take(3).length - 1),
              height: Tokens.memberAvatar,
              child: Stack(
                children: [
                  for (var i = groups.take(3).length - 1; i >= 0; i--)
                    Positioned(
                      left: Tokens.space[3] * i,
                      child: Container(
                        padding: const EdgeInsets.all(Tokens.miniRing),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: p.storyRing, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          shape: BoxShape.circle,
                        ),
                        child: Avatar(
                          name: storyName(app, l, groups[i].first),
                          size: Tokens.memberAvatar - Tokens.miniRing * 2,
                          userId: groups[i].first.sender,
                          round: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.tagStories(st.length), style: Tokens.listName.style.copyWith(color: p.label)),
                  Text(l.tagStoriesSub('#${widget.tag}'), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, size: Tokens.listIconSmall, color: p.chevron),
          ],
        ),
      ),
    );
  }

  /// #tag@address of a chat I'm not in: what it is + 참여.
  Widget joinCard(Palette p, L l) {
    final pk = peek;
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
      child: Container(
        key: const Key('tag-join-card'),
        padding: EdgeInsets.all(Tokens.space[2]),
        decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          children: [
            Avatar(name: pk?.name ?? widget.address!, size: Tokens.memberAvatar, squircle: true, channel: pk?.channel ?? true),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pk?.name ?? l.tagInChat('@${widget.address}'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.listName.style.copyWith(color: p.label),
                  ),
                  Text(peekMissing ? l.searchNoResults : l.tagJoinToSee, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
            if (pk != null)
              GlassPill(
                key: const Key('tag-join'),
                text: l.tagOpenChat,
                onTap: () async {
                  await openJoinLink(context, LinkTarget(kind: 'public', code: widget.address!, name: pk.name, channel: pk.channel));
                  await app.refresh();
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }

  String chatName(String roomId) {
    final c = chatOf(roomId);
    return c == null ? '' : nameOf(app, c);
  }

  Widget list(Palette p, L l, List<Found> h) => ListView.builder(
    key: const Key('tag-list'),
    itemCount: h.length,
    itemBuilder: (_, i) {
      final f = h[i];
      final c = chatOf(f.roomId);
      return MessageResult(
        key: Key('tag-msg-${f.msg.id}'),
        chat: c,
        name: chatName(f.roomId),
        sender: c == null || c.isDirect || c.isChannel ? '' : (f.msg.mine ? l.you : displayId(f.msg.sender).replaceFirst('@', '')),
        text: searchText(f.msg),
        term: '#${widget.tag}',
        markBack: true,
        time: shortTime(context, f.msg.time, now: app.backend.clock),
        onTap: () => openChat(context, f.roomId, chatName(f.roomId), jump: f.msg.id),
      );
    },
  );

  /// 대화로 보기: the posts as bubbles, oldest at the top, each under its
  /// chat's name (Telegram's "Show as Chat").
  Widget bubbles(Palette p, L l, List<Found> h) {
    final shown = h.reversed.toList();
    return ListView.builder(
      key: const Key('tag-bubbles'),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2]),
      itemCount: shown.length,
      itemBuilder: (_, i) {
        final f = shown[i];
        final mine = f.msg.mine;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            key: Key('tag-bubble-${f.msg.id}'),
            onTap: () => openChat(context, f.roomId, chatName(f.roomId), jump: f.msg.id),
            child: Container(
              margin: EdgeInsets.only(bottom: Tokens.space[1]),
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
              decoration: BoxDecoration(color: mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName(f.roomId),
                    style: Tokens.caption.style.copyWith(color: mine ? p.onAccent : p.accent, fontWeight: Tokens.semi),
                  ),
                  Text.rich(
                    markedText(
                      searchText(f.msg),
                      '#${widget.tag}',
                      Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label),
                      p.accent,
                      background: true,
                      markBack: p.searchMark,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      shortTime(context, f.msg.time, now: app.backend.clock),
                      style: Tokens.bubbleMeta.style.copyWith(color: mine ? p.onAccent.withValues(alpha: 0.7) : p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget grid(List<Found> h) => GridView.builder(
    key: const Key('tag-grid'),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1, crossAxisSpacing: 1),
    itemCount: h.length,
    itemBuilder: (_, i) => GestureDetector(
      onTap: () => openChat(context, h[i].roomId, chatName(h[i].roomId), jump: h[i].msg.id),
      child: SharedThumb(roomId: h[i].roomId, msg: h[i].msg),
    ),
  );

  Widget publicList(Palette p, L l) {
    final x = posts;
    if (x == null) return const Center(child: CupertinoActivityIndicator());
    return ListView(
      key: const Key('tag-public'),
      children: [
        if (x.isEmpty) EmptyMark(text: l.searchNoResults),
        for (final post in x)
          MessageResult(
            key: Key('tag-public-${post.address}-${post.time.millisecondsSinceEpoch}'),
            name: post.name,
            channel: post.channel,
            sender: '',
            text: post.text,
            term: '#${widget.tag}',
            markBack: true,
            time: shortTime(context, post.time, now: app.backend.clock),
            onTap: () => openJoinLink(context, LinkTarget(kind: 'public', code: post.address, name: post.name, channel: post.channel)),
          ),
        Padding(
          padding: EdgeInsets.all(Tokens.space[3]),
          child: Text(l.searchPublicPostsNote, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }

  /// Glass bar: "메시지 N개" and the view switch (Telegram 454 / 484).
  Widget bottomBar(Palette p, L l, int count, {required bool canToggle}) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], bottom + Tokens.space[1]),
      child: LiquidGlass(
        radius: Tokens.capsule,
        child: SizedBox(
          height: Tokens.closeButton,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Row(
              children: [
                Icon(CupertinoIcons.number, size: Tokens.listIconSmall, color: p.secondaryLabel),
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: Text(
                    l.tagCount(count),
                    key: const Key('tag-count'),
                    style: Tokens.preview.style.copyWith(color: p.label),
                  ),
                ),
                if (canToggle)
                  GestureDetector(
                    key: const Key('tag-view'),
                    onTap: () => setState(() => view = view == 'list' ? 'chat' : 'list'),
                    child: Text(view == 'list' ? l.tagShowChat : l.tagShowList, style: Tokens.preview.style.copyWith(color: p.accent)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
