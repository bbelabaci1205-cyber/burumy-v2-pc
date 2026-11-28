// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 주제 (group topics, Telegram tips 527 · 362 · 262): the side rail, the top
// tab bar, the topic line in 모두, the topic list (목록 view) and the admin
// pages. Data + encryption: core/topics.dart.
//
// Telegram (iOS, 2025): the rail on the left (icon + name + unread count)
// can be folded into a tab bar on top; "All" shows every topic with a small
// topic line where the topic changes; the composer says "Message in
// General". Group Settings > Topics: Enable Topics + Display as Tabs/List.
// Ours: the same, plus topic names, icons and which topic each message is
// in are end-to-end encrypted (Telegram's server sees all of it).
import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/topics.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_list_page.dart' show UnreadBadge;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';

/// Telegram's six topic colours (+ orange), as iOS system colours. Green
/// follows the theme (no green in the blue theme).
Color topicColor(Palette p, int i) => switch (i) {
  1 => Palette.tileYellow,
  2 => Palette.tilePurple,
  3 => p.tileGreen,
  4 => Palette.tilePink,
  5 => Palette.tileRed,
  6 => Palette.tileOrange,
  _ => Palette.tileBlue,
};

/// Ready-made topic icons (one tap; any emoji can be typed into the name too).
const topicEmoji = ['📢', '💬', '📌', '❓', '💡', '📚', '🎮', '🎵', '🎨', '📷', '🍔', '☕', '⚽', '🏃', '✈️', '🏠', '💼', '💰', '🛒', '🎉', '❤️', '🔥', '⭐', '🐶'];

String topicName(L l, Topic t) => t.general && t.name.isEmpty ? l.topicGeneral : t.name;

/// A topic's icon: its emoji, or a speech bubble in its colour with the
/// first letter; 일반 = "#".
class TopicIcon extends StatelessWidget {
  const TopicIcon({super.key, required this.topic, this.size = Tokens.topicIcon});
  final Topic topic;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    Widget inner;
    if (topic.icon.isNotEmpty) {
      inner = Text(
        topic.icon,
        style: TextStyle(fontSize: size * .82, height: 1.1, fontFamilyFallback: Tokens.emojiFallback),
      );
    } else if (topic.general) {
      inner = Icon(CupertinoIcons.number, size: size * .86, color: p.secondaryLabel);
    } else {
      final name = topicName(l, topic);
      final letter = name.isEmpty ? '' : String.fromCharCode(name.runes.first).toUpperCase();
      inner = Stack(
        alignment: Alignment.center,
        children: [
          Icon(CupertinoIcons.chat_bubble_fill, size: size, color: topicColor(p, topic.color)),
          Padding(
            padding: EdgeInsets.only(bottom: size * .1),
            child: Text(
              letter,
              style: TextStyle(fontFamily: Tokens.font, fontSize: size * .44, height: 1, fontWeight: Tokens.semi, color: const Color(0xFFFFFFFF)),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: inner),
    );
  }
}

/// "모두" in the rail / bar.
class _AllIcon extends StatelessWidget {
  const _AllIcon({this.size = Tokens.topicIcon});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Icon(CupertinoIcons.chat_bubble_2_fill, size: size * .92, color: paletteOf(context).accent),
  );
}

/// Translucent strip (like the chat's top bar) behind the rail / bar.
class _Strip extends StatelessWidget {
  const _Strip({required this.child, this.vertical = true});
  final Widget child;
  final bool vertical;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.chatBackground.withValues(alpha: 0.78),
            border: vertical ? Border(right: BorderSide(color: p.separator, width: 0.5)) : Border(bottom: BorderSide(color: p.separator, width: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.n);
  final int n;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      constraints: const BoxConstraints(minWidth: Tokens.topicBadge),
      height: Tokens.topicBadge,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
      child: Text(n > 99 ? '99+' : '$n', style: Tokens.bubbleMeta.style.copyWith(color: p.onAccent)),
    );
  }
}

/// Telegram's side rail: 모두, 일반 and each topic, top to bottom; the
/// button on top folds it into the tab bar.
class TopicRail extends StatelessWidget {
  const TopicRail({
    super.key,
    required this.topics,
    required this.current,
    required this.unread,
    required this.onPick,
    required this.onSwitch,
    this.onAdd,
    this.onHold,
  });
  final Topics topics;
  final String current;
  final Map<String, int> unread;
  final ValueChanged<String> onPick;
  final VoidCallback onSwitch;
  final VoidCallback? onAdd;
  final ValueChanged<Topic>? onHold;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget item(String id, Widget icon, String name, int n, {Topic? t}) {
      final on = current == id;
      return GestureDetector(
        key: Key('topic-rail-$id'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onPick(id),
        onLongPress: t == null || onHold == null ? null : () => onHold!(t),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[0], vertical: 2),
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1] - 2),
          decoration: BoxDecoration(color: on ? p.accent.withValues(alpha: 0.14) : null, borderRadius: BorderRadius.circular(Tokens.radius[1])),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  icon,
                  if (n > 0) Positioned(right: -Tokens.space[1], top: -Tokens.space[0], child: _Count(n)),
                  if (t?.closed == true)
                    Positioned(
                      right: -Tokens.space[0],
                      bottom: -2,
                      child: Icon(CupertinoIcons.lock_fill, size: 11, color: p.secondaryLabel),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Tokens.tabLabel.style.copyWith(color: on ? p.accent : p.secondaryLabel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final total = unread.values.fold<int>(0, (a, b) => a + b);
    return SizedBox(
      key: const Key('topic-rail'),
      width: Tokens.topicRail,
      child: _Strip(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          children: [
            GestureDetector(
              key: const Key('topic-switch-bar'),
              behavior: HitTestBehavior.opaque,
              onTap: onSwitch,
              child: Semantics(
                label: l.topicSwitchBar,
                button: true,
                child: SizedBox(
                  height: Tokens.closeButton,
                  child: Icon(CupertinoIcons.sidebar_left, size: Tokens.listIcon, color: p.label),
                ),
              ),
            ),
            item(Topics.all, const _AllIcon(), l.topicAll, total),
            for (final t in topics.shown) item(t.id, TopicIcon(topic: t), topicName(l, t), unread[t.id] ?? 0, t: t),
            if (onAdd != null)
              GestureDetector(
                key: const Key('topic-rail-add'),
                behavior: HitTestBehavior.opaque,
                onTap: onAdd,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                  child: Column(
                    children: [
                      Icon(CupertinoIcons.plus_circle_fill, size: Tokens.topicIcon, color: p.accent),
                      const SizedBox(height: 2),
                      Text(
                        l.topicNew,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.tabLabel.style.copyWith(color: p.accent),
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
}

/// The rail folded into a tab bar on top (Telegram); the button on the
/// left opens the rail again.
class TopicBar extends StatelessWidget {
  const TopicBar({
    super.key,
    required this.topics,
    required this.current,
    required this.unread,
    required this.onPick,
    required this.onSwitch,
    this.onAdd,
    this.onHold,
  });
  final Topics topics;
  final String current;
  final Map<String, int> unread;
  final ValueChanged<String> onPick;
  final VoidCallback onSwitch;
  final VoidCallback? onAdd;
  final ValueChanged<Topic>? onHold;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget chip(String id, Widget icon, String name, int n, {Topic? t}) {
      final on = current == id;
      return GestureDetector(
        key: Key('topic-tab-$id'),
        onTap: () => onPick(id),
        onLongPress: t == null || onHold == null ? null : () => onHold!(t),
        child: Container(
          height: 32,
          margin: EdgeInsets.only(right: Tokens.space[1]),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          decoration: BoxDecoration(color: on ? p.accent.withValues(alpha: 0.14) : null, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              SizedBox(width: Tokens.space[0]),
              Text(name, style: Tokens.preview.style.copyWith(color: on ? p.accent : p.label)),
              if (t?.closed == true) ...[const SizedBox(width: 3), Icon(CupertinoIcons.lock_fill, size: 11, color: p.secondaryLabel)],
              if (n > 0) ...[SizedBox(width: Tokens.space[0]), _Count(n)],
            ],
          ),
        ),
      );
    }

    final total = unread.values.fold<int>(0, (a, b) => a + b);
    return SizedBox(
      key: const Key('topic-bar'),
      height: Tokens.folderTabs,
      child: _Strip(
        vertical: false,
        child: Row(
          children: [
            GestureDetector(
              key: const Key('topic-switch-rail'),
              behavior: HitTestBehavior.opaque,
              onTap: onSwitch,
              child: Semantics(
                label: l.topicSwitchBar,
                button: true,
                child: SizedBox(
                  width: Tokens.closeButton,
                  height: Tokens.folderTabs,
                  child: Icon(CupertinoIcons.sidebar_left, size: Tokens.listIcon, color: p.label),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: Tokens.space[2], top: 4, bottom: 4),
                children: [
                  chip(Topics.all, const _AllIcon(size: Tokens.topicIconSmall), l.topicAll, total),
                  for (final t in topics.shown)
                    chip(
                      t.id,
                      TopicIcon(topic: t, size: Tokens.topicIconSmall),
                      topicName(l, t),
                      unread[t.id] ?? 0,
                      t: t,
                    ),
                  if (onAdd != null)
                    GestureDetector(
                      key: const Key('topic-tab-add'),
                      onTap: onAdd,
                      child: SizedBox(width: 32, child: Icon(CupertinoIcons.plus_circle_fill, size: 22, color: p.accent)),
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

/// In 모두: a small centred line where the topic changes ("› 공지");
/// tapping it opens that topic.
class TopicLine extends StatelessWidget {
  const TopicLine({super.key, required this.topic, required this.onTap});
  final Topic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return Padding(
      padding: EdgeInsets.only(top: Tokens.space[1], bottom: Tokens.space[0]),
      child: Center(
        child: GestureDetector(
          key: Key('topic-line-${topic.id}'),
          onTap: onTap,
          child: Container(
            height: Tokens.topicLine,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
            decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TopicIcon(topic: topic, size: 14),
                SizedBox(width: Tokens.space[0]),
                Text(topicName(l, topic), style: Tokens.caption.style.copyWith(color: p.label)),
                const SizedBox(width: 2),
                Icon(CupertinoIcons.chevron_right, size: 11, color: p.secondaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 목록 view: the group opens on its topics, like a small chat list.
class TopicListBody extends StatelessWidget {
  const TopicListBody({
    super.key,
    required this.topics,
    required this.msgs,
    required this.unread,
    required this.nameOf,
    required this.onOpen,
    this.onAdd,
    this.onHold,
  });
  final Topics topics;
  final List<Msg> msgs;
  final Map<String, int> unread;
  final String Function(String userId) nameOf;
  final ValueChanged<Topic> onOpen;
  final VoidCallback? onAdd;
  final ValueChanged<Topic>? onHold;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lastOf = <String, Msg>{};
    for (final m in msgs) {
      lastOf[topics.topicOf(m)] = m;
    }
    // Newest first, like the chat list (topics without messages last).
    final order = [...topics.shown]
      ..sort((a, b) {
        final x = lastOf[a.id]?.time, y = lastOf[b.id]?.time;
        if (x == null && y == null) return 0;
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      });
    String preview(Msg m) {
      final body = (m.kind == 'text' ? m.body : (m.caption?.isNotEmpty == true ? m.caption : m.body)) ?? '';
      return '${m.mine ? l.you : nameOf(m.sender)}: ${body.replaceAll('\n', ' ')}';
    }

    return ListView(
      key: const Key('topic-list'),
      padding: EdgeInsets.only(top: Tokens.space[1], bottom: Tokens.space[4]),
      children: [
        for (final t in order)
          _TopicRow(
            topic: t,
            name: topicName(l, t),
            last: lastOf[t.id] == null ? l.topicNoMessages : preview(lastOf[t.id]!),
            time: lastOf[t.id] == null ? '' : shortTime(context, lastOf[t.id]!.time),
            unread: unread[t.id] ?? 0,
            onTap: () => onOpen(t),
            onHold: onHold == null ? null : () => onHold!(t),
          ),
        if (onAdd != null)
          CupertinoButton(
            key: const Key('topic-list-add'),
            onPressed: onAdd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.plus_circle_fill, size: Tokens.listIcon, color: p.accent),
                SizedBox(width: Tokens.space[1]),
                Text(l.topicNew, style: Tokens.body.style.copyWith(color: p.accent)),
              ],
            ),
          ),
      ],
    );
  }
}

class _TopicRow extends StatefulWidget {
  const _TopicRow({required this.topic, required this.name, required this.last, required this.time, required this.unread, required this.onTap, this.onHold});
  final Topic topic;
  final String name, last, time;
  final int unread;
  final VoidCallback onTap;
  final VoidCallback? onHold;
  @override
  State<_TopicRow> createState() => _TopicRowState();
}

class _TopicRowState extends State<_TopicRow> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      key: Key('topic-row-${widget.topic.id}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      onLongPress: widget.onHold,
      child: Container(
        color: down ? p.rowPressed : null,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TopicIcon(topic: widget.topic, size: 36),
            ),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // name (+ lock) takes the room, the time sits at the right edge like the chat list.
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.listName.style.copyWith(color: p.label),
                              ),
                            ),
                            if (widget.topic.closed) ...[const SizedBox(width: 4), Icon(CupertinoIcons.lock_fill, size: 13, color: p.secondaryLabel)],
                          ],
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      Text(widget.time, style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  const SizedBox(height: Tokens.nameToSub),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                      if (widget.unread > 0) ...[SizedBox(width: Tokens.space[1]), UnreadBadge(count: widget.unread)],
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

/// Group > 운영 도구 > 주제: on/off, tabs or list, the topics.
class TopicsPage extends StatefulWidget {
  const TopicsPage({super.key, required this.roomId});
  final String roomId;
  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  Topics t = const Topics();
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    final cfg = await s.backend.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    if (mounted) setState(() => t = Topics.of(s, widget.roomId, cfg));
  }

  Future<void> save(Topics next) async {
    final s = AppScope.read(context);
    final before = t;
    setState(() {
      t = next;
      busy = true;
      error = null;
    });
    try {
      t = await Topics.save(s, widget.roomId, next);
      await s.logMod(widget.roomId, 'setting', 'topics');
    } catch (_) {
      if (mounted) {
        setState(() {
          t = before;
          error = L.of(context).saveFailed;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> edit(Topic? topic) async {
    final got = await editTopic(context, topic);
    if (got == null || !mounted) return;
    final list = [
      ...(t.list.isEmpty ? const [Topic(id: Topics.general)] : t.list),
    ];
    final at = list.indexWhere((x) => x.id == got.id);
    at >= 0 ? list[at] = got : list.add(got);
    await save(t.copyWith(list: list));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = t.list.isEmpty ? const [Topic(id: Topics.general)] : t.list;
    return SettingsScaffold(
      title: l.topics,
      children: [
        HeaderCard(color: Palette.tileBlue, icon: CupertinoIcons.square_grid_2x2_fill, title: l.topics, body: l.topicsInfo),
        group(context, footer: error ?? l.topicOffInfo, error: error != null, [
          IosTile(
            title: Text(l.topicsOn),
            trailing: IosSwitch(
              key: const Key('topics-on'),
              value: t.on,
              activeTrackColor: p.accent,
              onChanged: busy ? null : (v) => save(t.copyWith(on: v, list: list)),
            ),
          ),
        ]),
        if (t.on) ...[
          group(context, header: l.topicsView, footer: l.topicsViewInfo, [
            Padding(
              padding: EdgeInsets.symmetric(vertical: Tokens.space[3]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ViewChoice(
                    key: const Key('topics-view-tabs'),
                    list: false,
                    label: l.topicsViewTabs,
                    on: t.view == Topics.tabs,
                    onTap: () => save(t.copyWith(view: Topics.tabs)),
                  ),
                  _ViewChoice(
                    key: const Key('topics-view-list'),
                    list: true,
                    label: l.topicsViewList,
                    on: t.view == Topics.listView,
                    onTap: () => save(t.copyWith(view: Topics.listView)),
                  ),
                ],
              ),
            ),
          ]),
          group(context, header: l.topicsList, footer: l.topicsListInfo, [
            for (final x in list)
              IosTile(
                key: Key('topics-row-${x.id}'),
                leading: TopicIcon(topic: x),
                title: Text(topicName(l, x)),
                additionalInfo: x.closed ? Icon(CupertinoIcons.lock_fill, size: 15, color: p.secondaryLabel) : null,
                trailing: const IosChevron(),
                onTap: () => edit(x),
              ),
            IosTile(
              key: const Key('topics-new'),
              leading: Icon(CupertinoIcons.plus_circle_fill, size: Tokens.topicIcon, color: p.accent),
              title: Text(l.topicNew, style: TextStyle(color: p.accent)),
              onTap: () => edit(null),
            ),
          ]),
          group(context, [
            IosTile(
              title: Text(l.topicHideGeneral),
              trailing: IosSwitch(
                key: const Key('topics-hide-general'),
                value: t.generalHidden,
                activeTrackColor: p.accent,
                onChanged: busy ? null : (v) => save(t.copyWith(generalHidden: v)),
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

/// Telegram's two little phone pictures: tabs on the side, or a list.
class _ViewChoice extends StatelessWidget {
  const _ViewChoice({super.key, required this.list, required this.label, required this.on, required this.onTap});
  final bool list;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final ink = on ? p.accent : p.secondaryLabel.withValues(alpha: 0.5);
    Widget bar(double w, {double h = 5}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: ink, borderRadius: BorderRadius.circular(h)),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 104,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: p.background,
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              border: Border.all(color: ink, width: 2),
            ),
            child: list
                ? Column(
                    children: [
                      bar(26),
                      const SizedBox(height: 8),
                      for (var i = 0; i < 5; i++) ...[
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Expanded(child: bar(1, h: 4)),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      bar(26),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [bar(30, h: 10), const SizedBox(height: 5), bar(22, h: 10), const SizedBox(height: 5), bar(28, h: 10)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: Tokens.space[1]),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 2),
            decoration: BoxDecoration(color: on ? p.accent : null, borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Text(label, style: Tokens.caption.style.copyWith(color: on ? p.onAccent : p.label)),
          ),
        ],
      ),
    );
  }
}

/// Make or change a topic (admins). Returns the topic, or null.
Future<Topic?> editTopic(BuildContext context, Topic? topic) => Navigator.of(context).push<Topic>(IosPageRoute(builder: (_) => TopicEditPage(topic: topic)));

class TopicEditPage extends StatefulWidget {
  const TopicEditPage({super.key, this.topic});
  final Topic? topic;
  @override
  State<TopicEditPage> createState() => _TopicEditPageState();
}

class _TopicEditPageState extends State<TopicEditPage> {
  late final name = TextEditingController(text: widget.topic?.name ?? '');
  late String icon = widget.topic?.icon ?? '';
  late int color = widget.topic?.color ?? 0;
  late bool closed = widget.topic?.closed ?? false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  bool get general => widget.topic?.general ?? false;
  bool get ok => general || name.text.trim().isNotEmpty;

  Topic get draft => Topic(id: widget.topic?.id ?? Topics.newId(), name: Topics.cap(name.text, Topics.maxName), icon: icon, color: color, closed: closed);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: widget.topic == null ? l.topicNew : l.topicEdit,
      trailing: [GlassDone(key: const Key('topic-done'), onTap: ok ? () => Navigator.pop(context, draft) : null)],
      children: [
        SizedBox(height: Tokens.space[4]),
        Center(
          child: ValueListenableBuilder(
            valueListenable: name,
            builder: (_, _, _) => TopicIcon(key: const Key('topic-preview'), topic: draft, size: 72),
          ),
        ),
        SizedBox(height: Tokens.space[3]),
        group(context, [
          CupertinoTextField.borderless(
            key: const Key('topic-name'),
            controller: name,
            autofocus: widget.topic == null,
            placeholder: general ? l.topicGeneral : l.topicNameHint,
            maxLength: Topics.maxName,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
            onChanged: (_) => setState(() {}),
          ),
        ], header: l.topicName),
        if (!general) ...[
          group(context, header: l.topicColor, [
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < Topics.colorCount; i++)
                    GestureDetector(
                      key: Key('topic-color-$i'),
                      onTap: () => setState(() => color = i),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: topicColor(p, i), shape: BoxShape.circle),
                        child: color == i && icon.isEmpty ? const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Color(0xFFFFFFFF)) : null,
                      ),
                    ),
                ],
              ),
            ),
          ]),
          group(context, header: l.topicIcon, [
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: Tokens.space[1],
                runSpacing: Tokens.space[1],
                children: [
                  _IconPick(
                    key: const Key('topic-icon-letter'),
                    on: icon.isEmpty,
                    onTap: () => setState(() => icon = ''),
                    child: TopicIcon(topic: draft.copyWith(icon: ''), size: 26),
                  ),
                  for (final e in topicEmoji)
                    _IconPick(
                      key: Key('topic-icon-$e'),
                      on: icon == e,
                      onTap: () => setState(() => icon = e),
                      child: Text(e, style: const TextStyle(fontSize: 24, height: 1.1, fontFamilyFallback: Tokens.emojiFallback)),
                    ),
                ],
              ),
            ),
          ]),
          if (widget.topic != null)
            group(context, [
              IosTile(
                key: const Key('topic-close'),
                leading: iconTile(closed ? p.tileGreen : Palette.tileOrange, closed ? CupertinoIcons.lock_open_fill : CupertinoIcons.lock_fill),
                title: Text(closed ? l.topicReopen : l.topicClose),
                onTap: () => setState(() => closed = !closed),
              ),
            ], footer: closed ? l.topicClosedBar : null),
        ],
      ],
    );
  }
}

class _IconPick extends StatelessWidget {
  const _IconPick({super.key, required this.on, required this.onTap, required this.child});
  final bool on;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? p.accent.withValues(alpha: 0.18) : null, borderRadius: BorderRadius.circular(Tokens.radius[1])),
        child: child,
      ),
    );
  }
}
