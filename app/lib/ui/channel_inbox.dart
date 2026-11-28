// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널 문의함 (Telegram tip 526, channel batch #15): what admins see.
// - Chat list: one row per channel ("메시지" tag) instead of a row per
//   subscriber.
// - Inside: the newest subscriber's chat, with every subscriber as a tab
//   on top; the button at the left of the tabs moves them to a bar down
//   the left side (Telegram's second look; wide screens start there).
// - Subscriber side: the 💬 button under the channel and the empty card.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/channel_dm.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'name_colors.dart';
import 'wide.dart';

/// Pref: tabs down the left side instead of on top.
const inboxSidePref = 'dm_inbox_side';

String subscriberName(AppState s, String roomId) {
  final sub = ChannelDm.known[roomId]?.$2 ?? '';
  return sub.isEmpty ? '' : displayId(sub).replaceFirst('@', '');
}

/// The chat list row for one channel's messages.
class ChannelInboxRow extends StatelessWidget {
  const ChannelInboxRow({super.key, required this.row, required this.open});
  final ChatPreview row;

  /// Opens a message room (the chat page lives in chat_page.dart).
  final void Function(BuildContext context, String roomId, String title, String channel) open;

  String get channel => row.roomId.substring(ChannelDm.rowPrefix.length);

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final s = AppScope.of(context);
    final rooms = ChannelDm.inboxes(s)[channel] ?? const <ChatPreview>[];
    final names = [for (final r in rooms.take(3)) subscriberName(s, r.roomId)].join(', ');
    final last = row.last;
    return GestureDetector(
      key: Key('dm-inbox-$channel'),
      behavior: HitTestBehavior.opaque,
      onTap: rooms.isEmpty ? null : () => open(context, rooms.first.roomId, subscriberName(s, rooms.first.roomId), channel),
      child: Container(
        height: Tokens.chatRow,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            Avatar(name: row.name, size: Tokens.chatAvatar, roomId: channel, squircle: true, channel: true),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                row.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.listName.style.copyWith(color: p.label),
                              ),
                            ),
                            SizedBox(width: Tokens.space[1]),
                            Container(
                              key: const Key('dm-inbox-tag'),
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] - 2, vertical: 1),
                              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(Tokens.capsule)),
                              child: Text(
                                l.dmInboxTag,
                                style: Tokens.bubbleMeta.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      if (last != null) Text(shortTime(context, last.time), style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              names,
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
                      if (row.unread > 0) UnreadBadge(count: row.unread),
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

/// Small unread number in the accent colour.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
      child: Text(
        '$count',
        style: Tokens.caption.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
      ),
    );
  }
}

/// The subscribers of one channel, on top (tabs) or down the left side.
class InboxTabs extends StatelessWidget {
  const InboxTabs({super.key, required this.channel, required this.current, required this.onPick, required this.side, required this.onToggle, this.onAll});
  final String channel, current;
  final void Function(String roomId, String name) onPick;

  /// '전체' (Telegram's All at the top of the list): every subscriber's
  /// messages together. [current] is empty while it is open.
  final VoidCallback? onAll;
  final bool side;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final rooms = ChannelDm.inboxes(s)[channel] ?? const <ChatPreview>[];
    final toggle = GlassCircle(
      key: const Key('dm-inbox-toggle'),
      size: 36,
      onTap: onToggle,
      child: Icon(side ? CupertinoIcons.rectangle_split_3x1 : CupertinoIcons.sidebar_left, size: 18, color: p.label),
    );
    Widget face(ChatPreview r, double size) {
      final sub = ChannelDm.known[r.roomId]?.$2 ?? '';
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Avatar(name: subscriberName(s, r.roomId), size: size, userId: sub),
          if (r.unread > 0) Positioned(right: -6, top: -4, child: UnreadBadge(count: r.unread)),
        ],
      );
    }

    final l = L.of(context);
    final allOn = current.isEmpty;
    final allSide = onAll == null
        ? null
        : GestureDetector(
            key: const Key('dm-tab-all'),
            behavior: HitTestBehavior.opaque,
            onTap: allOn ? null : onAll,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: Tokens.space[0], vertical: 2),
              padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
              decoration: BoxDecoration(color: allOn ? p.accent.withValues(alpha: 0.14) : null, borderRadius: BorderRadius.circular(Tokens.radius[1])),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: allOn ? p.accent : p.label.withValues(alpha: 0.08), shape: BoxShape.circle),
                    child: Icon(CupertinoIcons.bubble_left_bubble_right_fill, size: 20, color: allOn ? p.onAccent : p.secondaryLabel),
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(l.dmInboxAll, maxLines: 1, style: Tokens.tabLabel.style.copyWith(color: allOn ? p.accent : p.secondaryLabel)),
                ],
              ),
            ),
          );
    if (side) {
      return Container(
        key: const Key('dm-inbox-side'),
        width: Tokens.inboxSide,
        color: p.background.withValues(alpha: 0.6),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          children: [
            Center(child: toggle),
            SizedBox(height: Tokens.space[1]),
            ?allSide,
            for (final r in rooms)
              GestureDetector(
                key: Key('dm-tab-${r.roomId}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(r.roomId, subscriberName(s, r.roomId)),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: Tokens.space[0], vertical: 2),
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                  decoration: BoxDecoration(
                    color: r.roomId == current ? p.accent.withValues(alpha: 0.14) : null,
                    borderRadius: BorderRadius.circular(Tokens.radius[1]),
                  ),
                  child: Column(
                    children: [
                      face(r, 40),
                      SizedBox(height: Tokens.space[0]),
                      Text(
                        subscriberName(s, r.roomId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.tabLabel.style.copyWith(color: r.roomId == current ? p.accent : p.secondaryLabel),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      key: const Key('dm-inbox-tabs'),
      height: Tokens.folderTabs + Tokens.space[1],
      child: Row(
        children: [
          SizedBox(width: Tokens.space[2]),
          toggle,
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(right: Tokens.space[2]),
              children: [
                if (onAll != null)
                  Padding(
                    padding: EdgeInsets.only(right: Tokens.space[1]),
                    child: Center(
                      child: GestureDetector(
                        key: const Key('dm-tab-all'),
                        onTap: allOn ? null : onAll,
                        child: LiquidGlass(
                          radius: Tokens.capsule,
                          child: Container(
                            height: 36,
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                            alignment: Alignment.center,
                            color: allOn ? p.accent.withValues(alpha: 0.16) : null,
                            child: Text(
                              l.dmInboxAll,
                              style: Tokens.caption.style.copyWith(color: allOn ? p.accent : p.label, fontWeight: allOn ? Tokens.semi : null),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                for (final r in rooms)
                  Padding(
                    padding: EdgeInsets.only(right: Tokens.space[1]),
                    child: Center(
                      child: GestureDetector(
                        key: Key('dm-tab-${r.roomId}'),
                        onTap: () => onPick(r.roomId, subscriberName(s, r.roomId)),
                        child: LiquidGlass(
                          radius: Tokens.capsule,
                          child: Container(
                            height: 36,
                            padding: EdgeInsets.fromLTRB(4, 0, Tokens.space[2], 0),
                            color: r.roomId == current ? p.accent.withValues(alpha: 0.16) : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Avatar(name: subscriberName(s, r.roomId), size: 28, userId: ChannelDm.known[r.roomId]?.$2),
                                SizedBox(width: Tokens.space[1]),
                                Text(
                                  subscriberName(s, r.roomId),
                                  style: Tokens.caption.style.copyWith(
                                    color: r.roomId == current ? p.accent : p.label,
                                    fontWeight: r.roomId == current ? Tokens.semi : null,
                                  ),
                                ),
                                if (r.unread > 0) ...[SizedBox(width: Tokens.space[0]), UnreadBadge(count: r.unread)],
                              ],
                            ),
                          ),
                        ),
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

/// Subscriber side, empty room: what this chat is for.
class ChannelDmEmpty extends StatelessWidget {
  const ChannelDmEmpty({super.key, required this.channelName});
  final String channelName;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Center(
      child: Container(
        key: const Key('dm-empty'),
        width: 240,
        padding: EdgeInsets.all(Tokens.space[3]),
        decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.chat_bubble_2_fill, size: 32, color: Color(0xFFFFFFFF)),
            ),
            SizedBox(height: Tokens.space[2]),
            Text(
              l.dmEmptyTitle,
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
            ),
            SizedBox(height: Tokens.space[0]),
            Text(
              l.dmEmptyBody(channelName),
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide screens start with the side bar (Telegram desktop look).
bool inboxSide(AppState s) => s.on(inboxSidePref, fallback: Wide.on);

/// Lets a long widget tree be wrapped without moving every line of it.
extension WrapWith on Widget {
  Widget wrapWith(Widget Function(Widget) f) => f(this);
}

/// 전체: every subscriber's messages to this channel in one list, newest at
/// the bottom, each with who sent it. A tap opens that person's chat.
class ChannelInboxAllPage extends StatefulWidget {
  const ChannelInboxAllPage({super.key, required this.channel, required this.title, required this.openRoom});
  final String channel, title;

  /// Opens one subscriber's chat in place of this page.
  final void Function(BuildContext context, String roomId, String name) openRoom;

  @override
  State<ChannelInboxAllPage> createState() => _ChannelInboxAllPageState();
}

class _ChannelInboxAllPageState extends State<ChannelInboxAllPage> {
  List<(String, Msg)>? all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (all == null) load();
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    final rooms = ChannelDm.inboxes(s)[widget.channel] ?? const <ChatPreview>[];
    final got = <(String, Msg)>[];
    for (final r in rooms) {
      try {
        final ms = await s.backend.cachedMessages(r.roomId);
        for (final m in ms.length > 100 ? ms.sublist(ms.length - 100) : ms) {
          if (m.kind == 'welcome' || m.kind == 'verify') continue;
          got.add((r.roomId, m));
        }
      } catch (_) {}
    }
    got.sort((a, b) => b.$2.time.compareTo(a.$2.time));
    if (mounted) setState(() => all = got);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final l = L.of(context);
    final pad = MediaQuery.paddingOf(context);
    final side = s.on(inboxSidePref);
    final tabs = InboxTabs(
      channel: widget.channel,
      current: '',
      side: side,
      onToggle: () => s.setOn(inboxSidePref, !side),
      onAll: () {},
      onPick: (room, name) => widget.openRoom(context, room, name),
    );
    final list = all;
    Widget row((String, Msg) x) {
      final (room, m) = x;
      final who = m.mine ? l.you : subscriberName(s, room);
      final text = m.kind == 'text' ? (m.body ?? '') : previewText(context, kind: m.kind, body: m.body, caption: m.caption);
      return GestureDetector(
        key: Key('dm-all-${m.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.openRoom(context, room, subscriberName(s, room)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: m.mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!m.mine) ...[Avatar(name: subscriberName(s, room), size: 28, userId: ChannelDm.known[room]?.$2), SizedBox(width: Tokens.space[1])],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                  decoration: BoxDecoration(color: m.mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[3] - 8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        who,
                        style: Tokens.caption.style.copyWith(color: m.mine ? p.onAccent : NameColors.colorFor(room, who), fontWeight: Tokens.semi),
                      ),
                      Text(text, style: Tokens.body.style.copyWith(color: m.mine ? p.onAccent : p.label)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          shortTime(context, m.time, now: s.backend.clock),
                          style: Tokens.bubbleMeta.style.copyWith(color: (m.mine ? p.onAccent : p.secondaryLabel).withValues(alpha: 0.8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final body = list == null
        ? const Center(child: CupertinoActivityIndicator())
        : ListView(
            key: const Key('dm-all-list'),
            reverse: true,
            padding: EdgeInsets.only(top: Tokens.space[2], bottom: pad.bottom + Tokens.space[3]),
            children: [
              for (final x in list) row(x),
              Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: Text(
                  l.dmInboxAllInfo,
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
              ),
            ],
          );
    return CupertinoPageScaffold(
      key: const Key('dm-all-page'),
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: LiquidGlass(
          radius: Tokens.capsule,
          child: Container(
            height: Tokens.closeButton,
            constraints: const BoxConstraints(minWidth: Tokens.titlePillMin),
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.navTitle.style.copyWith(color: p.label),
                ),
                Text(l.dmInboxAll, style: Tokens.navSubtitle.style.copyWith(color: p.accent)),
              ],
            ),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: pad.top + GlassTopBar.height),
        child: side
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  tabs,
                  Expanded(child: body),
                ],
              )
            : Column(
                children: [
                  tabs,
                  Expanded(child: body),
                ],
              ),
      ),
    );
  }
}
