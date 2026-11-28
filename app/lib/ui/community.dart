// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 커뮤니티 (Eric 2026-11-27, after Telegram tip 574): several groups and
// channels linked together. Layout follows Telegram's flow (group settings >
// 커뮤니티에 추가 > 만들기; a sheet with "한 대화로 보기" and three sections;
// one row in the chat list when folded); look is iOS 27 + our tokens.
// The engine keeps the link list sealed, so the server never sees it.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_list_page.dart' show ChatRowTile, SearchCapsule, UnreadBadge;
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// Room id of the one-line row that stands for a folded community.
const communityRowPrefix = 'community:';

/// The community's picture: a rounded square in its colour with three
/// people (we have no room photos yet; never a border).
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({super.key, required this.name, this.size = 60});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final base = Avatar.colorFor(name);
    final top = Color.lerp(base, const Color(0xFFFFFFFF), Tokens.avatarTopLight)!;
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * 0.3)),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
      ),
      child: Icon(CupertinoIcons.person_3_fill, size: size * 0.55, color: const Color(0xFFFFFFFF)),
    );
  }
}

/// Small round mark on a chat's photo: this chat is in a community. Tap it
/// to see the community (Telegram puts a little chevron there too).
class CommunityMark extends StatelessWidget {
  const CommunityMark({super.key, required this.community});
  final Community community;
  static const size = 22.0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      key: Key('community-mark-${community.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openCommunitySheet(context, community.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: p.card,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Icon(CupertinoIcons.chevron_down, size: 12, color: p.secondaryLabel),
      ),
    );
  }
}

/// Last message shown on a folded community row: (chat name, message).
final _foldLast = <String, (String, Msg?)>{};

/// Chat list with "한 대화로 보기" communities folded into one row each,
/// placed where their newest chat was.
List<ChatPreview> foldCommunities(AppState s, List<ChatPreview> chats) {
  final folded = <String, Community>{};
  for (final c in s.communities) {
    if (s.communityAsOne(c.id)) folded[c.id] = c;
  }
  if (folded.isEmpty) return chats;
  final out = <ChatPreview>[];
  final placed = <String>{};
  for (final chat in chats) {
    final com = folded.values.where((c) => c.visible.any((x) => x.roomId == chat.roomId && x.state == 'in')).firstOrNull;
    if (com == null) {
      out.add(chat);
      continue;
    }
    if (!placed.add(com.id)) continue;
    final members = [
      for (final x in chats)
        if (com.visible.any((v) => v.roomId == x.roomId)) x,
    ];
    // The newest message among them.
    ChatPreview? newest;
    for (final x in members) {
      if (x.last != null && (newest?.last == null || x.last!.time.isAfter(newest!.last!.time))) newest = x;
    }
    _foldLast[com.id] = (newest?.name ?? '', newest?.last);
    out.add(
      ChatPreview(
        roomId: '$communityRowPrefix${com.id}',
        name: com.name,
        isDirect: false,
        encrypted: true,
        unread: members.where((x) => !x.muted).fold(0, (a, x) => a + x.unread),
        last: newest?.last,
      ),
    );
  }
  return out;
}

/// The one-line community row (Telegram: "Alpha Lounge / Max › Formula
/// Paddock / last words"). Tap opens the community page.
class CommunityListRow extends StatelessWidget {
  const CommunityListRow({super.key, required this.row});
  final ChatPreview row;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final id = row.roomId.substring(communityRowPrefix.length);
    final (chatName, last) = _foldLast[id] ?? ('', null);
    final who = last == null ? '' : (last.mine ? l.you : displayId(last.sender).replaceFirst('@', ''));
    return GestureDetector(
      key: Key('community-row-$id'),
      behavior: HitTestBehavior.opaque,
      onTap: () => paneNav(context).push(IosPageRoute(builder: (_) => CommunityPage(id: id))),
      child: Container(
        height: Tokens.chatRow,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            CommunityAvatar(name: row.name, size: Tokens.chatAvatar),
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
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.listName.style.copyWith(color: p.label),
                        ),
                      ),
                      if (last != null) Text(shortTime(context, last.time), style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: Tokens.preview.lineHeight * 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "지우 › 축구 동호회" in the label colour, then the words.
                              Text(
                                who.isEmpty ? chatName : l.communityLast(who, chatName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.preview.style.copyWith(color: p.label),
                              ),
                              if (last != null)
                                Text(
                                  previewText(context, kind: last.kind, body: last.body, caption: last.caption),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (row.unread > 0)
                        Container(
                          width: Tokens.badgeSlot,
                          margin: EdgeInsets.only(left: Tokens.space[1]),
                          alignment: Alignment.topRight,
                          child: UnreadBadge(count: row.unread),
                        ),
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

/// Telegram's community sheet over the chat list.
Future<void> openCommunitySheet(BuildContext context, String id) {
  final h = MediaQuery.sizeOf(context).height;
  final top = MediaQuery.paddingOf(context).top;
  return showCupertinoModalPopup<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final p = paletteOf(c);
      return Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[1]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(IosActionSheet.radius),
          child: Container(
            key: const Key('community-sheet'),
            height: (h - top) * 0.82,
            color: p.background,
            child: CommunityBody(id: id, sheet: true),
          ),
        ),
      );
    },
  );
}

/// Full page (from the folded row or the group info).
class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return WidePage(
      child: CupertinoPageScaffold(
        backgroundColor: p.background,
        child: SafeArea(bottom: false, child: CommunityBody(id: id, sheet: false)),
      ),
    );
  }
}

/// What the sheet and the page show: header, "한 대화로 보기", the three
/// sections and "커뮤니티에 대화 추가".
class CommunityBody extends StatefulWidget {
  const CommunityBody({super.key, required this.id, required this.sheet});
  final String id;
  final bool sheet;

  @override
  State<CommunityBody> createState() => _CommunityBodyState();
}

class _CommunityBodyState extends State<CommunityBody> {
  String query = '';
  bool searching = false;
  final busy = <String>{};

  Future<void> join(Community c, CommunityChat x) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    setState(() => busy.add(x.roomId));
    try {
      final (rid, asked) = await s.backend.joinCommunityChat(c.id, x.roomId);
      await s.setOn('community_asked:${x.roomId}', asked);
      await s.refresh();
      if (!mounted) return;
      if (asked) {
        showStoryToast(context, l.communityAsked);
      } else {
        if (widget.sheet) Navigator.pop(context);
        unawaited(openChat(context, rid, x.name));
      }
    } catch (_) {
      if (mounted) showStoryToast(context, l.saveFailed);
    } finally {
      if (mounted) setState(() => busy.remove(x.roomId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final c = s.communities.where((x) => x.id == widget.id).firstOrNull;
    if (c == null) {
      return Center(
        child: Text(l.communityEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
      );
    }
    final q = query.trim().toLowerCase();
    final shown = [
      for (final x in c.visible)
        if (q.isEmpty || x.name.toLowerCase().contains(q)) x,
    ];
    final mine = [
      for (final x in shown)
        if (x.state == 'in') x,
    ];
    final view = [
      for (final x in shown)
        if (x.state == 'view') x,
    ];
    final ask = [
      for (final x in shown)
        if (x.state == 'ask') x,
    ];
    final previews = {for (final x in s.chats) x.roomId: x};
    final canAdd = c.admin || c.addAll;
    Widget header() => SizedBox(
      height: Tokens.sheetHeader + Tokens.space[1],
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: Tokens.space[2],
            child: GlassCircle(
              key: const Key('community-close'),
              onTap: () => Navigator.pop(context),
              child: widget.sheet
                  ? GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon)
                  : GlassCircle.icon(context, CupertinoIcons.chevron_back, size: Tokens.backChevron),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.closeButton * 2 + Tokens.space[4]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CommunityAvatar(name: c.name, size: 22),
                SizedBox(width: Tokens.space[1]),
                Flexible(
                  child: Text(
                    c.name,
                    key: const Key('community-title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: Tokens.space[2],
            child: Row(
              children: [
                GlassCircle(
                  key: const Key('community-settings'),
                  onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => CommunitySettingsPage(id: c.id))),
                  child: GlassCircle.icon(context, CupertinoIcons.slider_horizontal_3),
                ),
                if (widget.sheet) ...[
                  SizedBox(width: Tokens.space[1]),
                  GlassCircle(
                    key: const Key('community-search'),
                    onTap: () => setState(() => searching = !searching),
                    child: GlassCircle.icon(context, CupertinoIcons.search),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    Widget joinButton(CommunityChat x) {
      final asked = s.on('community_asked:${x.roomId}');
      final label = x.state == 'view' ? l.communityJoin : (asked ? l.communityAskedBtn : l.communityAskBtn);
      return GestureDetector(
        key: Key('community-join-${x.roomId}'),
        behavior: HitTestBehavior.opaque,
        onTap: busy.contains(x.roomId) || (x.state == 'ask' && asked) ? null : () => join(c, x),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + Tokens.space[0], vertical: Tokens.space[1] - 2),
          decoration: BoxDecoration(
            color: x.state == 'ask' && asked ? p.secondaryLabel.withValues(alpha: 0.15) : p.accent,
            borderRadius: BorderRadius.circular(Tokens.capsule),
          ),
          child: busy.contains(x.roomId)
              ? const CupertinoActivityIndicator(radius: 7)
              : Text(
                  label,
                  style: Tokens.preview.style.copyWith(color: x.state == 'ask' && asked ? p.secondaryLabel : p.onAccent, fontWeight: Tokens.semi),
                ),
        ),
      );
    }

    Widget outsideRow(CommunityChat x) => Container(
      key: Key('community-chat-${x.roomId}'),
      height: Tokens.memberRow + Tokens.space[1],
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
      child: Row(
        children: [
          Avatar(name: x.name, size: Tokens.memberAvatar + 6, squircle: true, channel: x.channel, roomId: x.roomId),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  x.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.listName.style.copyWith(color: p.label),
                ),
                if (x.members > 0 || x.hidden)
                  Text(
                    [if (x.members > 0) l.communityMembers(x.members), if (x.hidden) l.communityHiddenTag].join(' · '),
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                  ),
              ],
            ),
          ),
          joinButton(x),
        ],
      ),
    );

    Widget section(String title, List<CommunityChat> list, Widget Function(CommunityChat) row) =>
        IosSection(header: sectionHeader(context, title), children: [for (final x in list) row(x)]);

    Widget inRow(CommunityChat x) {
      final pv = previews[x.roomId];
      if (pv == null) return outsideRow(x);
      return GestureDetector(
        key: Key('community-chat-${x.roomId}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (widget.sheet) Navigator.pop(context);
          unawaited(openChat(context, x.roomId, pv.name));
        },
        child: IgnorePointer(child: ChatRowTile(chat: pv, inCommunity: true)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.sheet)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(Tokens.capsule)),
              ),
            ),
          ),
        header(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(bottom: Tokens.settingsRow + Tokens.space[5] + MediaQuery.paddingOf(context).bottom),
            children: [
              if (!widget.sheet || searching)
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
                  child: SearchCapsule(key: const Key('community-query'), hint: l.searchChats, onChanged: (v) => setState(() => query = v)),
                ),
              IosSection(
                footer: sectionFooter(context, l.communityAsOneFooter),
                children: [
                  IosTile(
                    title: Text(l.communityAsOne),
                    trailing: IosSwitch(
                      key: const Key('community-as-one'),
                      value: s.communityAsOne(c.id),
                      activeTrackColor: p.accent,
                      onChanged: (v) => s.setOn('community_one:${c.id}', v),
                    ),
                  ),
                ],
              ),
              if (mine.isNotEmpty) section(l.communityIn, mine, inRow),
              if (view.isNotEmpty) section(l.communityView, view, outsideRow),
              if (ask.isNotEmpty) section(l.communityAsk, ask, outsideRow),
              if (shown.isEmpty)
                Padding(
                  padding: EdgeInsets.all(Tokens.space[5]),
                  child: Text(
                    l.communityEmpty,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                ),
            ],
          ),
        ),
        if (canAdd)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2] + MediaQuery.paddingOf(context).bottom),
            child: AccentButton(
              key: const Key('community-add-chat'),
              text: '＋  ${l.communityAddChat}',
              onTap: () => Navigator.of(context).push(IosPageRoute(fullscreenDialog: true, builder: (_) => CommunityPickPage(id: c.id))),
            ),
          ),
      ],
    );
  }
}

/// Groups and channels I may add: mine (owner / admin), not in any
/// community yet.
Future<List<ChatPreview>> addableChats(AppState s) async {
  final out = <ChatPreview>[];
  for (final c in s.chats) {
    if (c.isDirect || c.roomId == s.savedRoomId || c.roomId.startsWith(communityRowPrefix)) continue;
    if (s.communityOf(c.roomId) != null) continue;
    String role;
    try {
      role = await s.backend.myRole(c.roomId);
    } catch (_) {
      continue;
    }
    if (role == 'owner' || role == 'admin') out.add(c);
  }
  return out;
}

/// "추가할 대화": tick my groups and channels.
class CommunityPickPage extends StatefulWidget {
  const CommunityPickPage({super.key, required this.id});
  final String id;

  @override
  State<CommunityPickPage> createState() => _CommunityPickPageState();
}

class _CommunityPickPageState extends State<CommunityPickPage> {
  List<ChatPreview>? chats;
  final picked = <String>{};
  bool hidden = false;
  bool busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (chats != null) return;
    chats = const [];
    addableChats(AppScope.read(context)).then((x) {
      if (mounted) setState(() => chats = x);
    });
  }

  Future<void> save() async {
    final s = AppScope.read(context);
    final l = L.of(context);
    setState(() => busy = true);
    var failed = false;
    for (final r in picked) {
      try {
        await s.backend.addToCommunity(widget.id, r, hidden: hidden);
      } catch (_) {
        failed = true;
      }
    }
    await s.refresh();
    if (!mounted) return;
    setState(() => busy = false);
    showStoryToast(context, failed ? l.saveFailed : l.communityAddedToast);
    if (!failed) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final c = s.communities.where((x) => x.id == widget.id).firstOrNull;
    final list = chats ?? const <ChatPreview>[];
    return SettingsScaffold(
      title: l.communityPickTitle,
      trailing: [GlassDone(key: const Key('community-pick-done'), onTap: picked.isEmpty || busy ? null : save)],
      children: [
        if (list.isEmpty)
          Padding(
            padding: EdgeInsets.all(Tokens.space[4]),
            child: Text(
              l.communityPickEmpty,
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          )
        else
          group(context, footer: l.communityPickFooter, [
            for (final x in list)
              IosTile(
                key: Key('community-pick-${x.roomId}'),
                leading: Avatar(name: x.name, size: 32, squircle: true, channel: x.isChannel, roomId: x.roomId),
                leadingSize: 32,
                title: Text(x.name),
                trailing: picked.contains(x.roomId) ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                onTap: () => setState(() => picked.contains(x.roomId) ? picked.remove(x.roomId) : picked.add(x.roomId)),
              ),
          ]),
        if (c != null && c.admin && list.isNotEmpty)
          group(context, footer: l.communityChatsFooter, [
            IosTile(
              title: Text(l.communityPickHidden),
              trailing: IosSwitch(
                key: const Key('community-pick-hidden'),
                value: hidden,
                activeTrackColor: p.accent,
                onChanged: (v) => setState(() => hidden = v),
              ),
            ),
          ]),
      ],
    );
  }
}

/// "커뮤니티에 추가" from a group's info: the intro (Telegram: icon, one
/// line, "커뮤니티 만들기") and my communities to add this chat to.
class CommunityIntroPage extends StatelessWidget {
  const CommunityIntroPage({super.key, required this.roomId});
  final String roomId;

  Future<void> addTo(BuildContext context, String id) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    try {
      await s.backend.addToCommunity(id, roomId);
      await s.refresh();
      if (!context.mounted) return;
      showStoryToast(context, l.communityAddedToast);
      Navigator.pop(context);
    } catch (_) {
      if (context.mounted) showStoryToast(context, l.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = [
      for (final c in s.communities)
        if (c.admin || c.addAll) c,
    ];
    return SettingsScaffold(
      title: l.community,
      children: [
        SizedBox(height: Tokens.space[4]),
        const Center(child: CommunityAvatar(name: '', size: 84)),
        SizedBox(height: Tokens.space[2] + Tokens.space[0]),
        Text(
          l.community,
          textAlign: TextAlign.center,
          style: Tokens.headerTitle.style.copyWith(color: p.label),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[0], Tokens.space[5], Tokens.space[3]),
          child: Text(
            l.communityIntroBody,
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        group(context, footer: l.communityPrivacy, [
          IosTile(
            key: const Key('community-create'),
            leading: Icon(CupertinoIcons.person_3_fill, color: p.accent),
            title: Text(l.communityCreate, style: TextStyle(color: p.accent)),
            onTap: () async {
              final id = await Navigator.of(context).push<String>(IosPageRoute(fullscreenDialog: true, builder: (_) => const NewCommunityPage()));
              if (id != null && context.mounted) await addTo(context, id);
            },
          ),
        ]),
        if (mine.isNotEmpty)
          group(context, header: l.communityMine, [
            for (final c in mine)
              IosTile(
                key: Key('community-add-to-${c.id}'),
                leading: CommunityAvatar(name: c.name, size: 32),
                leadingSize: 32,
                title: Text(c.name),
                additionalInfo: Text(l.communityChatsCount(c.visible.length)),
                onTap: () => addTo(context, c.id),
              ),
          ]),
      ],
    );
  }
}

/// Full-screen "새 커뮤니티" (no pop-up text boxes, rulebook): name and an
/// optional about. Returns the new id.
class NewCommunityPage extends StatefulWidget {
  const NewCommunityPage({super.key});

  @override
  State<NewCommunityPage> createState() => _NewCommunityPageState();
}

class _NewCommunityPageState extends State<NewCommunityPage> {
  final name = TextEditingController();
  final about = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    about.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final s = AppScope.read(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final id = await s.backend.createCommunity(name.text, about: about.text);
      await s.refresh();
      if (mounted) Navigator.pop(context, id);
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.communityNew,
      trailing: [GlassDone(key: const Key('community-new-done'), onTap: busy || name.text.trim().isEmpty ? null : create)],
      children: [
        SizedBox(height: Tokens.space[4]),
        Center(
          child: ValueListenableBuilder(
            valueListenable: name,
            builder: (_, v, _) => CommunityAvatar(name: v.text.trim(), size: Tokens.infoAvatar),
          ),
        ),
        SizedBox(height: Tokens.space[3]),
        group(context, footer: error ?? l.communityPrivacy, error: error != null, [
          CupertinoTextField.borderless(
            key: const Key('community-name'),
            controller: name,
            autofocus: true,
            placeholder: l.communityName,
            maxLength: 64,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
            onChanged: (_) => setState(() {}),
          ),
          CupertinoTextField.borderless(
            key: const Key('community-about'),
            controller: about,
            placeholder: l.communityAbout,
            maxLength: 255,
            maxLines: 4,
            minLines: 1,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
          ),
        ]),
      ],
    );
  }
}

/// Community settings (Telegram's edit page): name, who may add chats,
/// admins, the chats (hide / remove), leave or delete.
class CommunitySettingsPage extends StatefulWidget {
  const CommunitySettingsPage({super.key, required this.id});
  final String id;

  @override
  State<CommunitySettingsPage> createState() => _CommunitySettingsPageState();
}

class _CommunitySettingsPageState extends State<CommunitySettingsPage> {
  final name = TextEditingController();
  final about = TextEditingController();
  bool loaded = false;
  int? countdown;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    name.dispose();
    about.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function(Backend b) f) async {
    final s = AppScope.read(context);
    try {
      await f(s.backend);
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
    await s.refresh();
  }

  /// Leave / delete with 5 s to take it back (rulebook).
  void start(bool delete) {
    final s = AppScope.read(context);
    final nav = paneNav(context);
    setState(() => countdown = 5);
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (countdown! > 1) return setState(() => countdown = countdown! - 1);
      t.cancel();
      try {
        delete ? await s.backend.deleteCommunity(widget.id) : await s.backend.leaveCommunity(widget.id);
      } catch (_) {}
      await s.refresh();
      nav.popUntil((r) => r.isFirst);
    });
  }

  Future<void> chatMenu(Community c, CommunityChat x) async {
    final l = L.of(context);
    final mine = x.by == AppScope.read(context).backend.userId;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (ctx) => IosActionSheet(
        title: Text(x.name),
        actions: [
          if (c.admin)
            CupertinoActionSheetAction(
              key: const Key('community-chat-hide'),
              onPressed: () => Navigator.pop(ctx, 'hide'),
              child: Text(x.hidden ? l.communityShow : l.communityHide),
            ),
          if (c.admin || mine)
            CupertinoActionSheetAction(
              key: const Key('community-chat-remove'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, 'remove'),
              child: Text(l.communityRemoveChat),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
      ),
    );
    if (pick == 'hide') await run((b) => b.setCommunityChatHidden(c.id, x.roomId, !x.hidden));
    if (pick == 'remove') await run((b) => b.removeFromCommunity(c.id, x.roomId));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final c = s.communities.where((x) => x.id == widget.id).firstOrNull;
    if (c == null) return SettingsScaffold(title: l.communityInfo, children: const []);
    if (!loaded) {
      loaded = true;
      name.text = c.name;
      about.text = c.about;
    }
    final changed = name.text.trim() != c.name || about.text.trim() != c.about;
    Widget pick(bool all, String title, String info) => IosTile(
      key: Key('community-add-${all ? 'all' : 'admins'}'),
      title: Text(title),
      subtitle: Text(info, maxLines: 2, style: Tokens.caption.style),
      trailing: c.addAll == all ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
      onTap: c.admin && c.addAll != all ? () => run((b) => b.setCommunityAddAll(c.id, all)) : null,
    );
    return SettingsScaffold(
      title: l.communityInfo,
      trailing: [
        if (c.admin && changed)
          GlassDone(
            key: const Key('community-info-save'),
            onTap: name.text.trim().isEmpty ? null : () => run((b) => b.setCommunityInfo(c.id, name.text, about.text)),
          ),
      ],
      children: [
        SizedBox(height: Tokens.space[4]),
        Center(
          child: CommunityAvatar(name: c.name, size: Tokens.infoAvatar),
        ),
        SizedBox(height: Tokens.space[1]),
        Text(
          l.communityMembers(c.members),
          textAlign: TextAlign.center,
          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
        ),
        SizedBox(height: Tokens.space[2]),
        if (c.admin)
          group(context, [
            CupertinoTextField.borderless(
              key: const Key('community-edit-name'),
              controller: name,
              placeholder: l.communityName,
              maxLength: 64,
              style: Tokens.body.style.copyWith(color: p.label),
              padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
              onChanged: (_) => setState(() {}),
            ),
            CupertinoTextField.borderless(
              key: const Key('community-edit-about'),
              controller: about,
              placeholder: l.communityAbout,
              maxLength: 255,
              maxLines: 4,
              minLines: 1,
              style: Tokens.body.style.copyWith(color: p.label),
              padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
              onChanged: (_) => setState(() {}),
            ),
          ])
        else if (c.about.isNotEmpty)
          group(context, [
            Padding(
              padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
              child: Text(c.about, style: Tokens.body.style.copyWith(color: p.label)),
            ),
          ]),
        group(context, header: l.communityWhoAdds, [
          pick(true, l.communityAddAll, l.communityAddAllInfo),
          pick(false, l.communityAddAdmins, l.communityAddAdminsInfo),
        ]),
        if (c.admin)
          group(context, [
            NavRow(
              key: const Key('community-admins'),
              color: p.tileGreen,
              icon: CupertinoIcons.checkmark_shield_fill,
              title: l.communityAdmins,
              page: (_) => CommunityAdminsPage(id: c.id),
            ),
          ]),
        if (c.visible.isNotEmpty)
          group(context, header: l.communityChats, footer: c.admin ? l.communityChatsFooter : null, [
            for (final x in c.visible)
              IosTile(
                key: Key('community-manage-${x.roomId}'),
                leading: Avatar(name: x.name, size: 32, squircle: true, channel: x.channel, roomId: x.roomId),
                leadingSize: 32,
                title: Text(x.name),
                additionalInfo: x.hidden ? Text(l.communityHiddenTag) : null,
                trailing: c.admin || x.by == s.backend.userId ? const IosChevron() : null,
                onTap: c.admin || x.by == s.backend.userId ? () => chatMenu(c, x) : null,
              ),
          ]),
        group(context, footer: c.role == 'owner' ? l.communityDeleteInfo : l.communityLeaveInfo, [
          if (countdown != null)
            IosTile(
              key: const Key('community-undo'),
              title: Text(c.role == 'owner' ? l.communityRemovingIn(countdown!) : l.leavingIn(countdown!), style: const TextStyle(color: Palette.tileRed)),
              trailing: Text(l.undo, style: TextStyle(color: p.accent)),
              onTap: () {
                timer?.cancel();
                setState(() => countdown = null);
              },
            )
          else
            IosTile(
              key: Key(c.role == 'owner' ? 'community-delete' : 'community-leave'),
              title: Text(c.role == 'owner' ? l.communityDelete : l.communityLeave, style: const TextStyle(color: Palette.tileRed)),
              onTap: () => start(c.role == 'owner'),
            ),
        ]),
      ],
    );
  }
}

/// Community admins: everyone in the community, admins ticked.
class CommunityAdminsPage extends StatefulWidget {
  const CommunityAdminsPage({super.key, required this.id});
  final String id;

  @override
  State<CommunityAdminsPage> createState() => _CommunityAdminsPageState();
}

class _CommunityAdminsPageState extends State<CommunityAdminsPage> {
  List<Member> people = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    load();
  }

  Future<void> load() async {
    try {
      final x = await AppScope.read(context).backend.members(widget.id);
      if (mounted) setState(() => people = x);
    } catch (_) {}
  }

  Future<void> toggle(Member m) async {
    final s = AppScope.read(context);
    try {
      await s.backend.setCommunityAdmin(widget.id, m.userId, m.role == 'member');
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final me = AppScope.of(context).backend.userId;
    return SettingsScaffold(
      title: l.communityAdmins,
      children: [
        group(context, footer: l.communityAdminsFooter, [
          for (final m in people)
            IosTile(
              key: Key('community-admin-${m.userId}'),
              leading: Avatar(name: m.name, size: 32, userId: m.userId),
              leadingSize: 32,
              title: Text(m.name),
              additionalInfo: Text(switch (m.role) {
                'owner' => l.communityRoleOwner,
                'admin' => l.communityRoleAdmin,
                _ => '',
              }),
              trailing: m.role == 'owner' || m.userId == me
                  ? null
                  : Icon(m.role == 'admin' ? CupertinoIcons.checkmark_alt : CupertinoIcons.add, color: p.accent),
              onTap: m.role == 'owner' || m.userId == me ? null : () => toggle(m),
            ),
        ]),
      ],
    );
  }
}

/// The line in a chat: "이 그룹을 ○○ 커뮤니티에 추가했어요 · 보기".
class CommunityCardBubble extends StatelessWidget {
  const CommunityCardBubble({super.key, required this.card});
  final CardInfo card;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = card.text('community');
    final name = card.text('name');
    final channel = card.text('kind') == 'channel';
    final known = s.communities.any((c) => c.id == id);
    return Center(
      child: Container(
        key: const Key('community-card'),
        width: 220,
        margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        padding: EdgeInsets.all(Tokens.space[3]),
        decoration: BoxDecoration(
          color: p.label.withValues(alpha: p.dark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(Tokens.radius[3]),
        ),
        child: Column(
          children: [
            CommunityAvatar(name: name, size: 64),
            SizedBox(height: Tokens.space[2]),
            Text(
              channel ? l.communityCardChannel(name) : l.communityCardGroup(name),
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.label),
            ),
            SizedBox(height: Tokens.space[2]),
            GestureDetector(
              key: const Key('community-card-open'),
              behavior: HitTestBehavior.opaque,
              onTap: () => known ? paneNav(context).push(IosPageRoute(builder: (_) => CommunityPage(id: id))) : showStoryToast(context, l.communityNotYet),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                decoration: BoxDecoration(color: p.label.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(
                  l.communityOpen,
                  textAlign: TextAlign.center,
                  style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
