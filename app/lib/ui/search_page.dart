// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 전체 검색 (Telegram tips 500 · 189 · 248 · 533 · 444): one search screen
// with tabs 대화 · 채널 · 글 · 미디어 · 링크 · 파일 · 음악 · 음성.
//
// Layout follows Telegram's search (tabs under the field, sections 대화 /
// 전체 검색 / 메시지, media grid), sizes and glass follow iOS 27 and our
// tokens. What runs where is written in core/search.dart: my own messages
// are looked up on this phone only.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/ai_friend.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../core/room_links.dart';
import '../core/search.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_folders.dart' show FolderTabs;
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'glass.dart';
import 'hashtag_page.dart';
import 'invite_links.dart' show openJoinLink;
import 'ios.dart';
import 'profile_page.dart' show SharedThumb;
import 'ai_friend_page.dart' show AiFriendFace, openAiFriend;
import 'ios_route.dart';
import 'search_features.dart';
import 'settings_pages.dart' show packName;
import 'sticker_shop.dart' show ShopPackPage;
import 'wide.dart';

/// Opens the search over the list (fades in, like iOS search).
Future<void> openSearch(BuildContext context, {String query = ''}) => Navigator.of(context, rootNavigator: !Wide.on).push(
  PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, a, _) => FadeTransition(
      opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
      child: SearchPage(query: query),
    ),
  ),
);

/// Tabs, in Telegram's order (글 = tip 533's Posts).
const searchTabs = ['chats', 'channels', 'posts', 'media', 'link', 'file', 'music', 'voice'];

String searchTabName(L l, String id) => switch (id) {
  'channels' => l.searchTabChannels,
  'posts' => l.searchTabPosts,
  'media' => l.searchTabMedia,
  'link' => l.searchTabLinks,
  'file' => l.searchTabFiles,
  'music' => l.searchTabMusic,
  'voice' => l.searchTabVoice,
  _ => l.searchTabChats,
};

String scopeName(L l, String s) => switch (s) {
  'direct' => l.searchScopeDirect,
  'group' => l.searchScopeGroup,
  'channel' => l.searchScopeChannel,
  _ => l.searchScopeAll,
};

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.query = ''});
  final String query;
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final input = TextEditingController(text: widget.query);
  final focus = FocusNode();
  String tab = 'chats';

  /// What is searched (after the typing settles).
  String query = '';
  Timer? settle;

  /// 메시지 filter (tip 500) and the picked date chip (tip 189).
  String scope = 'all';
  DateChip? chip;

  /// Results per "kind|words" (my phone), and the server's public lists.
  final found = <String, List<Found>>{};
  final publicRooms = <String, List<LinkPeek>>{};
  final publicPosts = <String, List<PublicPost>>{};
  final loading = <String>{};
  bool moreGlobal = false;

  @override
  void initState() {
    super.initState();
    query = widget.query.trim();
    if (query.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  @override
  void dispose() {
    settle?.cancel();
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  void typed(String v) {
    settle?.cancel();
    settle = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        query = v.trim();
        chip = null;
        moreGlobal = false;
      });
    });
    if (v.trim().isEmpty) {
      settle?.cancel();
      setState(() {
        query = '';
        chip = null;
      });
    }
  }

  AppState get app => AppScope.read(context);

  /// The words left once a date chip is picked ("10월 여행" → "여행").
  (List<DateChip>, String) get dates => dateChips(query, app.backend.clock);

  /// With a date word ("11월 여행") the rest is searched, in those months
  /// (all offered ones until a chip is picked).
  String get words => dates.$1.isEmpty ? query : dates.$2;
  bool inDates(DateTime t) => chip != null ? chip!.has(t) : (dates.$1.isEmpty || dates.$1.any((d) => d.has(t)));

  List<Found>? results(String kind) {
    final w = words;
    if (kind == 'text' && w.isEmpty) return const [];
    final key = '$kind|$w';
    if (found[key] case final f?) return f;
    if (!loading.contains(key)) {
      loading.add(key);
      app.backend
          .searchEverywhere(w, kind: kind, limit: 500)
          .then((r) {
            if (mounted) setState(() => found[key] = r);
          })
          .catchError((_) {
            if (mounted) setState(() => found[key] = const []);
          })
          .whenComplete(() => loading.remove(key));
    }
    return null;
  }

  List<LinkPeek>? publicList(bool channels) {
    final w = words;
    if (w.length < 2) return const [];
    final key = '$channels|$w';
    if (publicRooms[key] case final f?) return f;
    if (!loading.contains('pub$key')) {
      loading.add('pub$key');
      app.backend
          .searchPublicRooms(w, channelsOnly: channels)
          .then((r) {
            if (mounted) setState(() => publicRooms[key] = r);
          })
          .catchError((_) {
            if (mounted) setState(() => publicRooms[key] = const []);
          });
    }
    return null;
  }

  List<PublicPost>? postsList() {
    final w = words;
    if (w.length < 2) return const [];
    if (publicPosts[w] case final f?) return f;
    if (!loading.contains('posts$w')) {
      loading.add('posts$w');
      app.backend
          .searchPublicPosts(w)
          .then((r) {
            if (mounted) setState(() => publicPosts[w] = r);
          })
          .catchError((_) {
            if (mounted) setState(() => publicPosts[w] = const []);
          });
    }
    return null;
  }

  ChatPreview? chatOf(String roomId) => app.chats.where((c) => c.roomId == roomId).firstOrNull;

  /// Hits with the 메시지 filter and the date chip applied.
  /// The 메시지 filter belongs to the 대화 tab's messages ([scoped]).
  List<Found> shown(List<Found> all, {bool scoped = false}) => [
    for (final f in all)
      if ((!scoped || inScope(chatOf(f.roomId), scope)) && inDates(f.msg.time)) f,
  ];

  Future<void> remember(String item) => app.setPref(recentSearchPref, addRecentSearch(app.pref(recentSearchPref, ''), item));

  Future<void> openFound(Found f) async {
    final c = chatOf(f.roomId);
    unawaited(remember('chat:${f.roomId}'));
    await openChat(context, f.roomId, c == null ? '' : nameOf(app, c), jump: f.msg.id);
  }

  Future<void> openRoom(ChatPreview c) async {
    unawaited(remember('chat:${c.roomId}'));
    await openChat(context, c.roomId, nameOf(app, c));
  }

  Future<void> openPublic(LinkPeek p) async {
    final c = p.joined ? chatOf(p.roomId) : null;
    if (c != null) return openRoom(c);
    await openJoinLink(context, LinkTarget(kind: 'public', code: p.address, name: p.name, channel: p.channel));
  }

  Future<void> pickScope() async {
    final l = L.of(context);
    final s = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.searchScopeTitle),
        actions: [
          for (final k in searchScopes)
            CupertinoActionSheetAction(
              key: Key('search-scope-$k'),
              isDefaultAction: k == scope,
              onPressed: () => Navigator.pop(c, k),
              child: Text(scopeName(l, k)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (s != null && mounted) setState(() => scope = s);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      child: Column(
        children: [
          SizedBox(height: top + Tokens.space[1]),
          // The field and a round X (iOS 27 search: glass field, glass close).
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Row(
              children: [
                Expanded(
                  child: LiquidGlass(
                    radius: Tokens.capsule,
                    shadow: false,
                    rim: false,
                    child: ColoredBox(
                      color: p.searchFill.withValues(alpha: 0.6),
                      child: SizedBox(
                        height: Tokens.searchField,
                        child: CupertinoSearchTextField(
                          key: const Key('search-input'),
                          controller: input,
                          focusNode: focus,
                          placeholder: l.searchChats,
                          backgroundColor: const Color(0x00000000),
                          borderRadius: BorderRadius.circular(Tokens.capsule),
                          style: Tokens.body.style.copyWith(color: p.label),
                          onChanged: typed,
                          onSubmitted: (v) {
                            settle?.cancel();
                            setState(() => query = v.trim());
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Tokens.space[1]),
                GlassCircle(
                  key: const Key('search-close'),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: GlassCircle.icon(context, CupertinoIcons.xmark),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.folderTabsAbove, Tokens.space[3], Tokens.folderTabsBelow),
            child: FolderTabs(
              key: const Key('search-tabs'),
              selected: tab,
              onPick: (id) => setState(() => tab = id),
              items: [for (final t in searchTabs) (t, searchTabName(l, t), 0)],
            ),
          ),
          if (query.isNotEmpty && dates.$1.isNotEmpty) chips(p),
          Expanded(
            child: GestureDetector(
              // Dragging the results puts the keyboard away (iOS).
              onPanDown: (_) => focus.unfocus(),
              behavior: HitTestBehavior.translucent,
              child: MediaQuery.removePadding(context: context, removeTop: true, child: body(context, p, l)),
            ),
          ),
        ],
      ),
    );
  }

  /// Date chips (tip 189): "10월" → this year's and earlier Octobers.
  Widget chips(Palette p) {
    final lang = Localizations.localeOf(context).languageCode;
    return SizedBox(
      height: Tokens.folderTabs,
      child: ListView(
        key: const Key('search-date-chips'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[0]),
        children: [
          for (final d in dates.$1)
            Padding(
              padding: EdgeInsets.only(right: Tokens.space[1]),
              child: GestureDetector(
                key: Key('date-chip-${d.id}'),
                onTap: () => setState(() => chip = chip?.id == d.id ? null : d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: chip?.id == d.id ? p.accent : p.searchFill, borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.calendar, size: Tokens.listIconSmall, color: chip?.id == d.id ? p.onAccent : p.secondaryLabel),
                      SizedBox(width: Tokens.space[0]),
                      Text(
                        d.month ? DateFormat.yMMMM(lang).format(d.from) : DateFormat.y(lang).format(d.from),
                        style: Tokens.preview.style.copyWith(color: chip?.id == d.id ? p.onAccent : p.label),
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

  Widget body(BuildContext context, Palette p, L l) => switch (tab) {
    'chats' => query.isEmpty ? recentView(p, l) : chatsView(p, l),
    'channels' => channelsView(p, l),
    'posts' => postsView(p, l),
    'media' => mediaView(p, l),
    _ => listView(p, l, tab),
  };

  Widget wait() => const Padding(
    padding: EdgeInsets.only(top: 48),
    child: Center(child: CupertinoActivityIndicator()),
  );

  Widget empty(L l, {String? text}) => ListView(
    key: const Key('search-empty'),
    padding: EdgeInsets.only(top: Tokens.space[4], bottom: Tokens.space[5]),
    children: [EmptyMark(text: text ?? l.searchNoResults)],
  );

  // ---- 대화 tab, nothing typed: people + recent ----

  Widget recentView(Palette p, L l) {
    final people = [
      for (final c in app.chats)
        if (c.isDirect && !c.isBot && c.peer.isNotEmpty && c.peer != app.backend.userId) c,
    ].take(12).toList();
    final recent = [
      for (final r in recentSearches(app.pref(recentSearchPref, '')))
        if (r.startsWith('chat:') && chatOf(r.substring(5)) != null) r else if (r.startsWith('tag:')) r,
    ];
    return ListView(
      key: const Key('search-recent'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      children: [
        if (people.isNotEmpty)
          SizedBox(
            height: Tokens.chatAvatar + Tokens.space[1] + Tokens.caption.lineHeight + Tokens.space[3],
            child: ListView(
              key: const Key('search-people'),
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
              children: [
                for (final c in people)
                  GestureDetector(
                    key: Key('search-person-${c.roomId}'),
                    onTap: () => openRoom(c),
                    child: SizedBox(
                      width: Tokens.chatAvatar + Tokens.space[2],
                      child: Column(
                        children: [
                          Avatar(name: nameOf(app, c), size: Tokens.chatAvatar, userId: c.peer, roomId: c.roomId),
                          SizedBox(height: Tokens.space[0]),
                          Text(
                            nameOf(app, c),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Tokens.caption.style.copyWith(color: p.label),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (recent.isNotEmpty) ...[
          SectionHead(
            title: l.searchRecent,
            action: l.searchClear,
            actionKey: const Key('search-recent-clear'),
            onAction: () => app.setPref(recentSearchPref, ''),
          ),
          for (final r in recent)
            if (r.startsWith('tag:'))
              ResultRow(
                key: Key('recent-$r'),
                leading: TagTile(size: Tokens.memberAvatar),
                title: r.substring(4),
                onTap: () => openHashtag(context, r.substring(4)),
              )
            else
              chatRow(p, l, chatOf(r.substring(5))!, keyPrefix: 'recent'),
        ],
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
          child: Text(
            l.searchOnPhoneNote,
            key: const Key('search-phone-note'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
      ],
    );
  }

  String chatSub(L l, ChatPreview c) {
    if (c.isDirect) return displayId(c.peer);
    return c.isChannel ? l.searchScopeChannel : l.searchScopeGroup;
  }

  Widget chatRow(Palette p, L l, ChatPreview c, {String keyPrefix = 'search-chat'}) => ResultRow(
    key: Key('$keyPrefix-${c.roomId}'),
    leading: Avatar(
      name: nameOf(app, c),
      size: Tokens.memberAvatar,
      squircle: !c.isDirect,
      channel: c.isChannel,
      userId: c.isDirect ? c.peer : null,
      roomId: c.roomId,
      owner: c.isChannel ? c.peer : null,
    ),
    title: nameOf(app, c),
    term: words,
    sub: chatSub(l, c),
    onTap: () => openRoom(c),
  );

  Widget publicRow(Palette p, L l, LinkPeek r) => ResultRow(
    key: Key('search-public-${r.address}'),
    leading: Avatar(name: r.name, size: Tokens.memberAvatar, squircle: true, channel: r.channel),
    title: r.name,
    term: words,
    sub: '@${r.address} · ${r.channel ? l.searchSubscribers(r.members) : l.searchMembers(r.members)}',
    onTap: () => openPublic(r),
  );

  // ---- 대화 tab with words: 대화 / 전체 검색 / 메시지 ----

  Widget chatsView(Palette p, L l) {
    final w = words.toLowerCase();
    final chats = w.isEmpty
        ? const <ChatPreview>[]
        : [
            for (final c in app.chats)
              if (nameOf(app, c).toLowerCase().contains(w) || (c.isDirect && displayId(c.peer).toLowerCase().contains(w.replaceFirst('@', '')))) c,
          ];
    final mineIds = {for (final c in app.chats) c.roomId};
    final pub = [
      for (final r in publicList(false) ?? const <LinkPeek>[])
        if (!mineIds.contains(r.roomId)) r,
    ];
    final msgs = results('text');
    final hits = msgs == null ? null : shown(msgs, scoped: true);
    final own = Features.ownWay ? ownWaySections(p, l, msgs) : const <Widget>[];
    if (own.isEmpty && chats.isEmpty && pub.isEmpty && hits != null && hits.isEmpty && publicList(false) != null) return empty(l);
    return ListView(
      key: const Key('search-chats'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      children: [
        if (chats.isNotEmpty) ...[SectionHead(title: l.searchSectionChats), for (final c in chats.take(20)) chatRow(p, l, c)],
        ...own,
        if (pub.isNotEmpty) ...[
          SectionHead(
            title: l.searchSectionGlobal,
            action: pub.length > 3 ? (moreGlobal ? l.searchLess : l.searchMore) : null,
            actionKey: const Key('search-global-more'),
            onAction: () => setState(() => moreGlobal = !moreGlobal),
          ),
          for (final r in pub.take(moreGlobal ? 20 : 3)) publicRow(p, l, r),
        ],
        SectionHead(
          title: l.searchSectionMessages,
          trailing: GestureDetector(
            key: const Key('search-scope'),
            onTap: pickScope,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scopeName(l, scope),
                  style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                ),
                SizedBox(width: Tokens.space[0] / 2),
                Icon(CupertinoIcons.chevron_down, size: Tokens.caption.size, color: p.accent),
              ],
            ),
          ),
        ),
        if (hits == null)
          wait()
        else if (hits.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: Text(
              l.searchNoResults,
              key: const Key('search-no-messages'),
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          )
        else
          for (final f in hits.take(200)) messageRow(p, l, f),
      ],
    );
  }

  // ---- 통합 검색 (우리식 2): ask the AI friend, features and settings,
  // sticker packs, and the newest posts of channels I follow. All on this
  // phone; nothing new is asked from a server. ----

  List<Widget> ownWaySections(Palette p, L l, List<Found>? msgs) {
    final w = words.trim();
    final feats = findFeatures(app, l, p, w);
    final packs = findPacks(l, w);
    final posts = [
      for (final f in msgs ?? const <Found>[])
        if (chatOf(f.roomId)?.isChannel ?? false) f,
    ];
    return [
      if (feats.isNotEmpty) ...[
        SectionHead(title: l.searchFeatures),
        for (final f in feats.take(5))
          ResultRow(key: Key('search-feature-${f.id}'), leading: featureLeading(f), title: f.title, term: w, sub: f.where, onTap: () => f.open(context)),
      ],
      if (w.length >= 2 && AiFriend.listed(app))
        ResultRow(
          key: const Key('search-ask-ai'),
          leading: AiFriendFace(size: Tokens.memberAvatar),
          title: l.aiFriendAsk(w),
          sub: l.aiFriendLock,
          onTap: () => openAiFriend(context, ask: w),
        ),
      if (packs.isNotEmpty) ...[
        SectionHead(title: l.searchStickers),
        for (final k in packs)
          ResultRow(
            key: Key('search-pack-${k.id}'),
            leading: Image.asset(k.asset(k.items.first), width: Tokens.memberAvatar, height: Tokens.memberAvatar),
            title: packName(l, k.id),
            term: w,
            sub: '${l.shopFreeTag} · ${l.stickerCount(k.items.length)}',
            onTap: () => Navigator.of(context).push(IosPageRoute<void>(builder: (_) => ShopPackPage(pack: k))),
          ),
      ],
      if (posts.isNotEmpty) ...[
        SectionHead(
          title: l.searchChannelPosts,
          action: l.searchAllPosts,
          actionKey: const Key('search-all-posts'),
          onAction: () => setState(() => tab = 'posts'),
        ),
        for (final f in posts.take(3)) messageRow(p, l, f),
      ],
    ];
  }

  Widget messageRow(Palette p, L l, Found f) {
    final c = chatOf(f.roomId);
    final name = c == null ? '' : nameOf(app, c);
    final m = f.msg;
    final who = c == null || c.isDirect || c.isChannel ? '' : (m.mine ? l.you : displayId(m.sender).replaceFirst('@', ''));
    final text = m.kind == 'text' ? searchText(m) : previewText(context, kind: m.kind, body: m.body, caption: m.caption);
    return MessageResult(
      key: Key('search-msg-${m.id}'),
      chat: c,
      name: name,
      sender: who,
      text: text,
      term: words,
      time: shortTime(context, m.time, now: app.backend.clock),
      onTap: () => openFound(f),
    );
  }

  // ---- 채널 tab (tip 444 + 248) ----

  Widget channelsView(Palette p, L l) {
    final w = words.toLowerCase();
    final mine = [
      for (final c in app.chats)
        if (c.isChannel && (w.isEmpty || nameOf(app, c).toLowerCase().contains(w))) c,
    ];
    final mineIds = {for (final c in app.chats) c.roomId};
    final pubAll = publicList(true);
    final pub = [
      for (final r in pubAll ?? const <LinkPeek>[])
        if (!mineIds.contains(r.roomId)) r,
    ];
    if (mine.isEmpty && w.length >= 2 && pubAll != null && pub.isEmpty) return empty(l);
    return ListView(
      key: const Key('search-channels'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      children: [
        if (mine.isNotEmpty) ...[SectionHead(title: l.searchMyChannels), for (final c in mine) chatRow(p, l, c, keyPrefix: 'search-channel')],
        if (w.length >= 2) ...[
          SectionHead(title: l.searchPublicChannels),
          if (pubAll == null)
            wait()
          else if (pub.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              child: Text(l.searchNoResults, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            )
          else
            for (final r in pub) publicRow(p, l, r),
        ] else if (mine.isEmpty)
          EmptyMark(text: l.searchChannelsHint),
      ],
    );
  }

  // ---- 글 tab (tip 533): my channels' posts (phone) + public posts ----

  Widget postsView(Palette p, L l) {
    if (words.length < 2) return empty(l, text: l.searchPostsHint);
    final all = results('text');
    final mineIds = {for (final c in app.chats) c.roomId};
    final mine = all == null
        ? null
        : [
            for (final f in all)
              if (chatOf(f.roomId)?.isChannel ?? false)
                if (inDates(f.msg.time)) f,
          ];
    final pubAll = postsList();
    final pub = [
      for (final x in pubAll ?? const <PublicPost>[])
        // Posts of channels I'm in already show above (from my phone).
        if (!app.chats.any((c) => c.isChannel && mineIds.contains(c.roomId) && nameOf(app, c) == x.name))
          if (inDates(x.time)) x,
    ];
    if (mine != null && mine.isEmpty && pubAll != null && pub.isEmpty) return empty(l);
    return ListView(
      key: const Key('search-posts'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      children: [
        if (mine == null) wait() else if (mine.isNotEmpty) ...[SectionHead(title: l.searchFollowedPosts), for (final f in mine.take(100)) messageRow(p, l, f)],
        SectionHead(title: l.searchPublicPosts),
        if (pubAll == null)
          wait()
        else if (pub.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: Text(l.searchNoResults, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          )
        else
          for (final x in pub)
            MessageResult(
              key: Key('search-public-post-${x.address}-${x.time.millisecondsSinceEpoch}'),
              name: x.name,
              channel: true,
              sender: '',
              text: x.text,
              term: words,
              time: shortTime(context, x.time, now: app.backend.clock),
              onTap: () => openJoinLink(context, LinkTarget(kind: 'public', code: x.address, name: x.name, channel: x.channel)),
            ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          child: Text(
            l.searchPublicPostsNote,
            key: const Key('search-posts-note'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
      ],
    );
  }

  // ---- 미디어 tab (tip 189): 3-column grid ----

  Widget mediaView(Palette p, L l) {
    final all = results('media');
    if (all == null) return wait();
    final hits = shown(all);
    if (hits.isEmpty) return empty(l);
    return GridView.builder(
      key: const Key('search-media'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 1, crossAxisSpacing: 1),
      itemCount: hits.length,
      itemBuilder: (_, i) => GestureDetector(
        key: Key('search-media-${hits[i].msg.id}'),
        onTap: () => openFound(hits[i]),
        child: SharedThumb(roomId: hits[i].roomId, msg: hits[i].msg),
      ),
    );
  }

  // ---- 링크 · 파일 · 음악 · 음성 ----

  Widget listView(Palette p, L l, String kind) {
    final all = results(kind);
    if (all == null) return wait();
    final hits = shown(all);
    if (hits.isEmpty) return empty(l);
    return ListView.builder(
      key: Key('search-$kind'),
      padding: EdgeInsets.only(bottom: Tokens.space[5]),
      itemCount: hits.length,
      itemBuilder: (_, i) => kindRow(p, l, kind, hits[i]),
    );
  }

  Widget kindRow(Palette p, L l, String kind, Found f) {
    final m = f.msg;
    final c = chatOf(f.roomId);
    final chat = c == null ? '' : nameOf(app, c);
    final when = shortTime(context, m.time, now: app.backend.clock);
    switch (kind) {
      case 'link':
        final url = RegExp(r'https?://\S+').firstMatch(m.body ?? '')?.group(0) ?? '';
        final host = Uri.tryParse(url)?.host ?? url;
        return ResultRow(
          key: Key('search-link-${m.id}'),
          leading: KindTile(text: host.isEmpty ? '#' : host.replaceFirst('www.', '').characters.first.toUpperCase(), color: Palette.tileBlue),
          title: m.preview?.title.isNotEmpty ?? false ? m.preview!.title : host,
          term: words,
          sub: url,
          subColor: p.accent,
          foot: chat,
          time: when,
          onTap: () => openFound(f),
        );
      case 'file':
        final name = m.body ?? '';
        final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
        return ResultRow(
          key: Key('search-file-${m.id}'),
          leading: KindTile(text: ext.isEmpty ? '?' : (ext.length > 4 ? ext.substring(0, 4) : ext), color: fileColor(ext)),
          title: name,
          term: words,
          sub: [if (m.size != null) fileSize(m.size!), chat].join(' · '),
          time: when,
          onTap: () => openFound(f),
        );
      case 'music':
        return ResultRow(
          key: Key('search-music-${m.id}'),
          leading: PlayTile(color: p.accent),
          title: (m.body ?? '').replaceFirst(RegExp(r'\.[A-Za-z0-9]{2,4}$'), ''),
          term: words,
          sub: chat,
          time: when,
          onTap: () => openFound(f),
        );
      default:
        final who = m.mine ? l.you : displayId(m.sender).replaceFirst('@', '');
        final len = m.voice?.duration;
        return ResultRow(
          key: Key('search-voice-${m.id}'),
          leading: PlayTile(color: p.accent),
          title: c == null || c.isDirect ? who : '$who → $chat',
          sub: len == null ? '' : '${len.inMinutes}:${(len.inSeconds % 60).toString().padLeft(2, '0')}',
          time: when,
          onTap: () => openFound(f),
        );
    }
  }
}

String fileSize(int b) {
  if (b < 1024) return '$b B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
  return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// iOS system colours by meaning: documents red / blue, archives orange,
/// sheets green-ish teal, slides orange-red, the rest grey.
Color fileColor(String ext) => switch (ext) {
  'pdf' => Palette.tileRed,
  'doc' || 'docx' || 'hwp' || 'txt' || 'pages' => Palette.tileBlue,
  'zip' || 'rar' || '7z' || 'tar' || 'gz' => Palette.tileOrange,
  'xls' || 'xlsx' || 'csv' || 'numbers' => Palette.tileTeal,
  'ppt' || 'pptx' || 'key' => Palette.tileIndigo,
  'jpg' || 'jpeg' || 'png' || 'heic' || 'gif' || 'webp' => Palette.tileCyan,
  _ => Palette.tileGrey,
};

// ---- building blocks (also used by the hashtag page) ----

/// Grey section title with an optional action on the right (Telegram's
/// "RECENT · Clear"; iOS grouped header sizes).
class SectionHead extends StatelessWidget {
  const SectionHead({super.key, required this.title, this.action, this.actionKey, this.onAction, this.trailing});
  final String title;
  final String? action;
  final Key? actionKey;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      color: p.background,
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1] - 2, Tokens.space[3], Tokens.space[1] - 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: Tokens.semi),
            ),
          ),
          ?trailing,
          if (action != null)
            GestureDetector(
              key: actionKey,
              onTap: onAction,
              behavior: HitTestBehavior.opaque,
              child: Text(action!, style: Tokens.caption.style.copyWith(color: p.accent)),
            ),
        ],
      ),
    );
  }
}

/// Words with the found part coloured (accent), like Telegram's results.
TextSpan markedText(String text, String term, TextStyle style, Color mark, {bool background = false, Color? markBack}) {
  final ranges = matchRanges(text, term);
  if (ranges.isEmpty) return TextSpan(text: text, style: style);
  final out = <TextSpan>[];
  var at = 0;
  for (final (a, b) in ranges) {
    if (a > at) out.add(TextSpan(text: text.substring(at, a)));
    out.add(
      TextSpan(
        text: text.substring(a, b),
        style: background ? TextStyle(backgroundColor: markBack) : TextStyle(color: mark),
      ),
    );
    at = b;
  }
  if (at < text.length) out.add(TextSpan(text: text.substring(at)));
  return TextSpan(style: style, children: out);
}

/// One result line: picture, title (found words coloured), a line under
/// it, time on the right; iOS member-row height.
class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.leading,
    required this.title,
    this.term = '',
    this.sub = '',
    this.subColor,
    this.foot = '',
    this.time = '',
    this.onTap,
  });
  final Widget leading;
  final String title;
  final String term;
  final String sub;
  final Color? subColor;
  final String foot;
  final String time;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return PressRow(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: Tokens.memberRow),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
        child: Row(
          children: [
            leading,
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          markedText(title, term, Tokens.listName.style.copyWith(color: p.label), p.accent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time.isNotEmpty) ...[SizedBox(width: Tokens.space[1]), Text(time, style: Tokens.caption.style.copyWith(color: p.secondaryLabel))],
                    ],
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: Tokens.nameToSub),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: subColor ?? p.secondaryLabel),
                    ),
                  ],
                  if (foot.isNotEmpty)
                    Text(
                      foot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
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

/// A found message: chat picture, chat name + time, then who wrote it and
/// the words around the match (2 lines), like a chat-list row.
class MessageResult extends StatelessWidget {
  const MessageResult({
    super.key,
    this.chat,
    required this.name,
    required this.sender,
    required this.text,
    required this.term,
    required this.time,
    this.channel = false,
    this.onTap,
    this.markBack = false,
  });
  final ChatPreview? chat;
  final String name;
  final String sender;
  final String text;
  final String term;
  final String time;
  final bool channel;
  final VoidCallback? onTap;

  /// Hashtag results: yellow behind the tag (Telegram 454) instead of colour.
  final bool markBack;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final c = chat;
    final shownText = aroundMatch(text, term);
    final style = Tokens.preview.style.copyWith(color: p.secondaryLabel);
    return PressRow(
      onTap: onTap,
      child: Container(
        height: Tokens.chatRow,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            Avatar(
              name: name,
              size: Tokens.chatAvatar,
              squircle: c == null ? true : !c.isDirect,
              channel: c == null ? channel : c.isChannel,
              userId: c != null && c.isDirect ? c.peer : null,
              roomId: c?.roomId,
              owner: c != null && c.isChannel ? c.peer : null,
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.listName.style.copyWith(color: p.label),
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      Text(time, style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  const SizedBox(height: Tokens.nameToSub),
                  Text.rich(
                    TextSpan(
                      style: style,
                      children: [
                        if (sender.isNotEmpty)
                          TextSpan(
                            text: '$sender: ',
                            style: TextStyle(color: p.label),
                          ),
                        markedText(shownText, term, style, p.accent, background: markBack, markBack: p.searchMark),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

/// Row that turns light grey while a finger rests on it (iOS cell).
class PressRow extends StatefulWidget {
  const PressRow({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  State<PressRow> createState() => _PressRowState();
}

class _PressRowState extends State<PressRow> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: ColoredBox(color: down ? p.rowPressed : const Color(0x00000000), child: widget.child),
    );
  }
}

/// Rounded tile with a short word (file kind, link site letter).
class KindTile extends StatelessWidget {
  const KindTile({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: Tokens.memberAvatar,
    height: Tokens.memberAvatar,
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: color,
      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[1])),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: Tokens.semi),
    ),
  );
}

/// Round play button (music, voice).
class PlayTile extends StatelessWidget {
  const PlayTile({super.key, required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: Tokens.memberAvatar,
    height: Tokens.memberAvatar,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(CupertinoIcons.play_fill, size: Tokens.listIconSmall, color: const Color(0xFFFFFFFF)),
  );
}

/// '#' in a round tile (recent hashtag searches).
class TagTile extends StatelessWidget {
  const TagTile({super.key, required this.size});
  final double size;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.searchFill, shape: BoxShape.circle),
      child: Text('#', style: Tokens.cardTitle.style.copyWith(color: p.secondaryLabel)),
    );
  }
}

/// Small Burumy mark with a line (empty results; keyboard stays visible).
class EmptyMark extends StatelessWidget {
  const EmptyMark({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[4], vertical: Tokens.space[4]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/brand/symbol_green.png', width: Tokens.infoAvatar, color: p.accent.withValues(alpha: 0.35), colorBlendMode: BlendMode.srcIn),
          SizedBox(height: Tokens.space[3]),
          Text(
            text,
            key: const Key('empty-text'),
            textAlign: TextAlign.center,
            style: Tokens.body.style.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}
