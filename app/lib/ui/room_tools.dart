// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Group and channel admin tools (운영 도구): rules, welcome message,
// reactions, auto-moderation, stats, admin log, moving board, bans, level
// and the discussion group. Room settings are saved in the room (checked by
// the engine); anything that needs reading messages runs on an admin's
// phone, because the server can't read them.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/custom_emoji.dart';
import '../core/features.dart';
import '../core/app_state.dart';
import '../core/automod.dart';
import '../core/keyword_replies.dart';
import '../core/guard.dart';
import '../core/group_tools.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'custom_emoji_ui.dart';
import 'formatting.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'welcome.dart';
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;
import '../core/topics.dart';
import 'topics.dart' show TopicsPage;
import 'room_rules_pages.dart';
import '../core/room_rules.dart';
import '../core/room_texts.dart';
import 'wide.dart';

/// Emoji admins can choose from for "some reactions".
const reactionPool = [
  '❤️', '👍', '👎', '😂', '😮', '😢', '🙏', '🔥', '🎉', '👏', '😍', '🤔', //
  '💯', '😡', '🥰', '😎', '🤝', '✅', '👀', '💚', '😭', '🤯', '🥳', '😴',
];

/// Reaction emoji allowed in a room for its config (null = all).
List<String>? allowedReactions(Map<String, dynamic> cfg) => switch (cfg['reactions']) {
  'none' => const [],
  'some' => [for (final e in (cfg['reactions_set'] as List? ?? const [])) e.toString()],
  _ => null,
};

int reactionsMax(Map<String, dynamic> cfg) => (cfg['reactions_max'] as num?)?.toInt() ?? 11;

String reactionsLabel(L l, Map<String, dynamic> cfg) => switch (cfg['reactions']) {
  'none' => l.reactionsNone,
  'some' => l.reactionsSome,
  _ => l.reactionsAll,
};

/// The admin tools list.
class ManageToolsPage extends StatefulWidget {
  const ManageToolsPage({super.key, required this.roomId, required this.isChannel, required this.role});
  final String roomId;
  final bool isChannel;
  final String role;

  @override
  State<ManageToolsPage> createState() => _ManageToolsPageState();
}

class _ManageToolsPageState extends State<ManageToolsPage> {
  Map<String, dynamic> cfg = const {};
  int members = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (members == 0) unawaited(load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    final c = await b.roomConfig(widget.roomId);
    final m = await b.members(widget.roomId);
    if (mounted) {
      setState(() {
        cfg = c;
        members = m.length;
      });
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.of(context).push(IosPageRoute(builder: (_) => page));
    await load();
  }

  /// 습격 잠금 (v1): many strangers rushing in through a link. On = every
  /// new join through a link waits for an admin; off puts the link back the
  /// way it was.
  Future<void> setRaid(bool v) async {
    final s = AppScope.read(context);
    final b = s.backend;
    final id = widget.roomId;
    setState(() => cfg = {...cfg, 'raid': v});
    if (v) {
      final link = await b.roomLink(id).catchError((_) => const RoomLink());
      await s.setPref('raid_prev:$id', link.approval ? '1' : '0');
      if (!link.approval) await b.setLinkApproval(id, true).catchError((_) {});
    } else if (s.pref('raid_prev:$id', '1') == '0') {
      await b.setLinkApproval(id, false).catchError((_) {});
    }
    await b.setRoomConfig(id, 'raid', v ? true : null);
    await s.logMod(id, 'setting', 'raid');
  }

  Future<void> setFlag(String key, bool v) async {
    final s = AppScope.read(context);
    setState(() => cfg = {...cfg, key: v});
    await s.backend.setRoomConfig(widget.roomId, key, v);
    await s.logMod(widget.roomId, 'setting', key);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = widget.roomId;
    final rulesOn = RoomTexts.rulesOn(cfg);
    final welcomeOn = RoomTexts.welcomeOn(cfg);
    final old = (cfg['old_members'] as num?)?.toInt() ?? 0;
    return SettingsScaffold(
      title: l.manageTools,
      children: [
        HeaderCard(color: Palette.tileBlue, icon: CupertinoIcons.shield_lefthalf_fill, title: l.manageTools, body: l.manageToolsInfo),
        group(context, header: l.toolsJoin, footer: l.raidLockInfo, [
          NavRow(
            key: const Key('tool-rules'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.doc_text_fill,
            title: l.roomRules,
            value: rulesOn ? l.stateOn : l.stateOff,
            onTap: () => open(RoomTextPage(roomId: id, configKey: 'rules')),
          ),
          NavRow(
            key: const Key('tool-welcome'),
            color: p.tileGreen,
            icon: CupertinoIcons.hand_raised_fill,
            title: l.welcomeMessage,
            value: welcomeOn ? l.stateOn : l.stateOff,
            onTap: () => open(WelcomeEditorPage(roomId: id, roomName: titleOf(s, id, ''), channel: widget.isChannel)),
          ),
          NavRow(
            key: const Key('tool-level'),
            color: Palette.tilePurple,
            icon: CupertinoIcons.star_fill,
            title: l.roomLevel,
            onTap: () => open(LevelPage(roomId: id)),
          ),
          IosTile(
            leading: iconTile(Palette.tileRed, CupertinoIcons.lock_shield_fill),
            title: Text(l.raidLock),
            trailing: IosSwitch(key: const Key('tool-raid'), value: cfg['raid'] == true, activeTrackColor: p.accent, onChanged: setRaid),
          ),
        ]),
        if (!widget.isChannel)
          group(context, header: l.toolsMembers, footer: l.noMemberDmInfo, [
            NavRow(
              key: const Key('tool-member-perms'),
              color: p.tileGreen,
              icon: CupertinoIcons.person_2_fill,
              title: l.memberPerms,
              value: Features.chatSafety
                  ? '${RoomRules.memberPermsSplit.where((k) => RoomRules.memberMay(cfg, k)).length}/${RoomRules.memberPermsSplit.length}'
                  : '${RoomRules.memberPerms.where((k) => RoomRules.memberMay(cfg, k)).length}/${RoomRules.memberPerms.length}',
              onTap: () => open(memberPermsPage(s, id, cfg, l)),
            ),
            NavRow(
              key: const Key('tool-slow'),
              color: Palette.tileOrange,
              icon: CupertinoIcons.timer,
              title: l.slowMode,
              value: slowLabel(l, RoomRules.slowSeconds(cfg)),
              onTap: () => open(slowModePage(s, id, cfg, l)),
            ),
            NavRow(
              key: const Key('tool-night'),
              color: Palette.tileIndigo,
              icon: CupertinoIcons.moon_fill,
              title: l.roomNight,
              value: nightLabel(l, RoomRules.nightValue(cfg)),
              onTap: () => open(nightModePage(s, id, cfg, l)),
            ),
            // 그룹 이모지 묶음 (tip 430): picked emoji for everyone here.
            if (Features.funFx)
              NavRow(
                key: const Key('tool-group-emoji'),
                color: Palette.tileYellow,
                icon: CupertinoIcons.smiley_fill,
                title: l.cxGroupTitle,
                value: '${CustomEmojis.pack(s, id).length}',
                onTap: () => open(GroupEmojiPage(roomId: id, admin: true)),
              ),
            IosTile(
              leading: iconTile(Palette.tileRed, CupertinoIcons.chat_bubble_2_fill),
              title: Text(l.noMemberDm),
              trailing: IosSwitch(
                key: const Key('tool-no-member-dm'),
                value: RoomRules.noMemberDm(cfg),
                activeTrackColor: p.accent,
                onChanged: (v) => setFlag('no_member_dm', v),
              ),
            ),
          ]),
        group(context, header: l.toolsPosts, footer: widget.isChannel ? l.hideCountsInfo : l.hideCountsInfoGroup, [
          // 주제 (tip 527): groups only, the list itself is encrypted.
          if (!widget.isChannel)
            NavRow(
              key: const Key('tool-topics'),
              color: Palette.tileBlue,
              icon: CupertinoIcons.square_grid_2x2_fill,
              title: l.topics,
              value: Topics.fingerprintIn(cfg) != null && Topics.of(s, id, cfg).on ? l.stateOn : l.stateOff,
              onTap: () => open(TopicsPage(roomId: id)),
            ),
          NavRow(
            key: const Key('tool-reactions'),
            color: Palette.tilePink,
            icon: CupertinoIcons.heart_fill,
            title: l.reactionsSetting,
            value: reactionsLabel(l, cfg),
            onTap: () => open(ReactionsPage(roomId: id)),
          ),
          NavRow(
            key: const Key('tool-automod'),
            color: Palette.tileIndigo,
            icon: CupertinoIcons.wand_stars,
            title: l.autoMod,
            value: s.on('automod_on:$id') ? l.stateOn : l.stateOff,
            onTap: () => open(AutoModPage(roomId: id)),
          ),
          if (!widget.isChannel)
            NavRow(
              key: const Key('tool-keywords'),
              color: Palette.tileTeal,
              icon: CupertinoIcons.text_bubble_fill,
              title: l.keywordReplies,
              value: '${keywordRules(s.settings, id).length}',
              onTap: () => open(KeywordRepliesPage(roomId: id)),
            ),
          if (widget.isChannel)
            NavRow(
              key: const Key('tool-discussion'),
              color: Palette.tileCyan,
              icon: CupertinoIcons.chat_bubble_2_fill,
              title: l.discussion,
              value: discussionName(s, cfg) ?? l.discussionNone,
              onTap: () => open(DiscussionPage(roomId: id, now: cfg['discussion'] as String? ?? '')),
            ),
          IosTile(
            leading: iconTile(Palette.tileGrey, CupertinoIcons.number),
            title: Text(l.hideCounts),
            trailing: IosSwitch(
              key: const Key('tool-hide-counts'),
              value: cfg['hide_counts'] == true,
              activeTrackColor: p.accent,
              onChanged: (v) => setFlag('hide_counts', v),
            ),
          ),
        ]),
        // 94: the owner's own 익명으로 남기 (admins get it from the owner).
        if (!widget.isChannel && widget.role == 'owner')
          AnonSwitchGroup(
            key: ValueKey('anon-self-${AnonAdmins.isOn(cfg, s.backend.userId ?? '')}'),
            roomId: id,
            userId: s.backend.userId ?? '',
            initial: AnonAdmins.isOn(cfg, s.backend.userId ?? ''),
            self: true,
          ),
        group(context, header: l.toolsSafety, footer: l.toolsSafetyInfo, [
          // 365: 강력 스팸 차단 (groups).
          if (!widget.isChannel)
            NavRow(
              key: const Key('tool-antispam'),
              color: Palette.tileIndigo,
              icon: CupertinoIcons.shield_lefthalf_fill,
              title: l.antiSpam,
              value: AntiSpam.on(cfg) ? l.stateOn : l.stateOff,
              onTap: () => open(AntiSpamPage(roomId: id)),
            ),
          NavRow(
            key: const Key('tool-new-media'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.person_badge_minus_fill,
            title: l.newMediaTitle,
            value: newMediaDays(cfg) == 0 ? l.stateOff : l.newMediaDays(newMediaDays(cfg)),
            onTap: () => open(NewMediaPage(roomId: id, days: newMediaDays(cfg))),
          ),
          NavRow(
            key: const Key('tool-late-edits'),
            color: Palette.tileYellow,
            icon: CupertinoIcons.pencil_ellipsis_rectangle,
            title: l.lateEditTitle,
            onTap: () => open(LateEditsPage(roomId: id)),
          ),
          NavRow(
            key: const Key('tool-extortion'),
            color: Palette.tileRed,
            icon: CupertinoIcons.exclamationmark_bubble_fill,
            title: l.extortionRow,
            onTap: () => open(ExtortionReportPage(roomId: id)),
          ),
        ]),
        group(context, header: l.toolsStats, [
          NavRow(
            key: const Key('tool-stats'),
            color: Palette.tileTeal,
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: l.roomStats,
            onTap: () => open(RoomStatsPage(roomId: id)),
          ),
          NavRow(
            key: const Key('tool-log'),
            color: Palette.tileGrey,
            icon: CupertinoIcons.list_bullet,
            title: l.modLog,
            onTap: () => open(ModLogPage(roomId: id)),
          ),
          NavRow(
            key: const Key('tool-moving'),
            color: Palette.tileYellow,
            icon: CupertinoIcons.cube_box_fill,
            title: l.movingBoard,
            value: old > 0 ? '$members/$old' : null,
            onTap: () => open(MovingBoardPage(roomId: id)),
          ),
          NavRow(
            key: const Key('tool-banned'),
            color: Palette.tileRed,
            icon: CupertinoIcons.nosign,
            title: l.bannedUsers,
            onTap: () => open(BannedPage(roomId: id)),
          ),
        ]),
      ],
    );
  }
}

/// The linked discussion group's name, if this phone knows it.
String? discussionName(AppState s, Map<String, dynamic> cfg) {
  final d = cfg['discussion'] as String? ?? '';
  if (d.isEmpty) return null;
  return s.chats.where((c) => c.roomId == d).firstOrNull?.name;
}

/// Rules or welcome message: a full-screen text editor (no popups).
class RoomTextPage extends StatefulWidget {
  const RoomTextPage({super.key, required this.roomId, required this.configKey});
  final String roomId;

  /// "rules" or "welcome".
  final String configKey;

  @override
  State<RoomTextPage> createState() => _RoomTextPageState();
}

class _RoomTextPageState extends State<RoomTextPage> {
  final field = TextEditingController();
  bool agree = false;
  bool ready = false;
  bool busy = false;
  String? error;

  bool get rules => widget.configKey == 'rules';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    AppScope.read(context).backend.roomConfig(widget.roomId).then((c) {
      if (!mounted) return;
      final t = RoomTexts.of(AppScope.read(context), widget.roomId, c);
      setState(() {
        field.text = rules ? t.rules : t.welcome;
        agree = c['rules_agree'] == true;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (busy) return;
    final s = AppScope.read(context);
    final text = field.text.trim();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      // End-to-end encrypted (the room keeps only a fingerprint).
      await RoomTexts.save(s, widget.roomId, rules: rules ? text : null, welcome: rules ? null : text);
      if (rules) await s.backend.setRoomConfig(widget.roomId, 'rules_agree', text.isNotEmpty && agree);
      await s.logMod(widget.roomId, 'setting', widget.configKey);
      if (mounted) Navigator.pop(context);
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
      title: rules ? l.roomRules : l.welcomeMessage,
      trailing: [GlassDone(key: const Key('room-text-save'), onTap: busy ? null : save)],
      children: [
        group(context, footer: error ?? '${rules ? l.roomRulesInfo : l.welcomeInfo}\n🔒 ${l.textsEncrypted}', error: error != null, [
          CupertinoTextField.borderless(
            key: const Key('room-text'),
            controller: field,
            placeholder: rules ? l.roomRulesHint : l.welcomeHint,
            maxLength: rules ? 2000 : 500,
            minLines: rules ? 6 : 3,
            maxLines: 14,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2]),
          ),
        ]),
        if (rules)
          group(context, footer: l.rulesAgreeInfo, [
            IosTile(
              title: Text(l.rulesAgree),
              trailing: IosSwitch(key: const Key('rules-agree'), value: agree, activeTrackColor: p.accent, onChanged: (v) => setState(() => agree = v)),
            ),
          ]),
      ],
    );
  }
}

/// All / some / no reactions, which ones, and how many per message.
class ReactionsPage extends StatefulWidget {
  const ReactionsPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<ReactionsPage> createState() => _ReactionsPageState();
}

class _ReactionsPageState extends State<ReactionsPage> {
  String mode = 'all';
  List<String> chosen = const ['❤️', '👍', '😂', '😮', '😢', '🙏'];
  int max = 11;
  bool ready = false;
  Timer? saveMax;

  @override
  void dispose() {
    final t = saveMax;
    if (t != null && t.isActive) {
      t.cancel();
      unawaited(put('reactions_max', max));
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    AppScope.read(context).backend.roomConfig(widget.roomId).then((c) {
      if (!mounted) return;
      setState(() {
        mode = c['reactions'] as String? ?? 'all';
        final set = allowedReactions({...c, 'reactions': 'some'})!;
        if (set.isNotEmpty) chosen = set;
        max = reactionsMax(c);
      });
    }, onError: (_) {});
  }

  Future<void> put(String key, Object? v) async {
    final s = AppScope.read(context);
    await s.backend.setRoomConfig(widget.roomId, key, v);
    await s.logMod(widget.roomId, 'setting', key);
  }

  void pick(String v) {
    setState(() => mode = v);
    unawaited(put('reactions', v));
    if (v == 'some') unawaited(put('reactions_set', chosen));
  }

  void toggle(String e) {
    final next = chosen.contains(e) ? ([...chosen]..remove(e)) : [...chosen, e];
    if (next.isEmpty || next.length > 24) return;
    setState(() => chosen = next);
    unawaited(put('reactions_set', next));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.reactionsSetting,
      children: [
        group(context, footer: mode == 'none' ? l.reactionsNoneInfo : l.reactionsInfo, [
          for (final (v, label) in [('all', l.reactionsAll), ('some', l.reactionsSome), ('none', l.reactionsNone)])
            IosTile(
              key: Key('pick-$v'),
              title: Text(label),
              trailing: v == mode ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
              onTap: () => pick(v),
            ),
        ]),
        if (mode == 'some')
          group(context, header: l.reactionsPick, [
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: Wrap(
                spacing: Tokens.space[1],
                runSpacing: Tokens.space[1],
                alignment: WrapAlignment.center,
                children: [
                  for (final e in reactionPool)
                    GestureDetector(
                      key: Key('react-pick-$e'),
                      onTap: () => toggle(e),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: chosen.contains(e) ? p.accent.withValues(alpha: 0.18) : p.incoming.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(Tokens.radius[1]),
                        ),
                        child: Opacity(
                          opacity: chosen.contains(e) ? 1 : 0.4,
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        if (mode != 'none')
          group(context, footer: l.reactionsMaxInfo, [
            // Telegram 450 (Eric 2026-11-27): an iOS slider 1 … 11 with the
            // number above it, like 절전 모드.
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2]),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(l.reactionsMax, style: Tokens.body.style.copyWith(color: p.label)),
                      ),
                      Text(
                        '$max',
                        key: const Key('react-max'),
                        style: Tokens.body.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text('1', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      Expanded(
                        child: CupertinoSlider(
                          key: const Key('react-max-slider'),
                          value: max.toDouble(),
                          min: 1,
                          max: 11,
                          divisions: 10,
                          activeColor: p.accent,
                          onChanged: (v) {
                            final n = v.round();
                            if (n == max) return;
                            HapticFeedback.selectionClick();
                            setState(() => max = n);
                            // Saved once the finger rests (one room event, not ten).
                            saveMax?.cancel();
                            saveMax = Timer(const Duration(milliseconds: 400), () => unawaited(put('reactions_max', n)));
                          },
                        ),
                      ),
                      Text('11', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        if (mode != 'none' && Features.tipsD1)
          group(context, header: l.reactionsPreview, [ReactionsPreview(emoji: mode == 'some' ? chosen : reactionPool, max: max)]),
      ],
    );
  }
}

/// A sample channel post with as many reaction kinds as the limit lets
/// through, so admins see what members will see (Telegram 450 has none).
class ReactionsPreview extends StatelessWidget {
  const ReactionsPreview({super.key, required this.emoji, required this.max});
  final List<String> emoji;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final shown = emoji.take(max).toList();
    const counts = [128, 64, 41, 23, 17, 12, 9, 6, 4, 3, 2];
    return Padding(
      key: const Key('react-preview'),
      padding: EdgeInsets.all(Tokens.space[3]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
            child: Text(l.reactionsPreviewPost, style: Tokens.body.style.copyWith(color: p.label)),
          ),
          SizedBox(height: Tokens.space[0]),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: Tokens.space[0],
              runSpacing: Tokens.space[0],
              children: [
                for (var i = 0; i < shown.length; i++)
                  Container(
                    key: Key('react-preview-${shown[i]}'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: i == 0 ? p.accent.withValues(alpha: 0.18) : p.incoming,
                      borderRadius: BorderRadius.circular(Tokens.capsule),
                    ),
                    child: Text('${shown[i]} ${counts[i]}', style: Tokens.caption.style.copyWith(color: i == 0 ? p.accent : p.label)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-moderation: switch, banned words, and two rules.
class AutoModPage extends StatefulWidget {
  const AutoModPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<AutoModPage> createState() => _AutoModPageState();
}

class _AutoModPageState extends State<AutoModPage> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = widget.roomId;
    final words = bannedWordsOf(s.settings, id);
    Future<void> save(List<String> w) => s.setPref('automod_words:$id', w.join('\n'));
    void add() {
      final v = field.text.trim();
      if (v.isEmpty || words.length >= 200 || words.contains(v)) return;
      field.clear();
      unawaited(save([...words, v.length > 40 ? v.substring(0, 40) : v]));
    }

    return SettingsScaffold(
      title: l.autoMod,
      children: [
        group(context, footer: l.autoModInfo, [PrefSwitch('automod_on:$id', title: l.autoMod, icon: CupertinoIcons.wand_stars, color: Palette.tileIndigo)]),
        if (s.on('automod_on:$id')) ...[
          group(context, header: l.modRules, [
            PrefSwitch('automod_links:$id', title: l.modNewLinks, subtitle: l.modNewLinksInfo, fallback: true),
            PrefSwitch('automod_flood:$id', title: l.modFlood, subtitle: l.modFloodInfo, fallback: true),
          ]),
          group(context, header: l.bannedWords, footer: l.bannedWordsInfo, [
            for (var i = 0; i < words.length; i++)
              IosTile(
                key: Key('word-$i'),
                title: Text(words[i]),
                trailing: GestureDetector(
                  key: Key('word-remove-$i'),
                  onTap: () => save([...words]..removeAt(i)),
                  child: const Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: 22),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField.borderless(
                      key: const Key('word-field'),
                      controller: field,
                      placeholder: l.addBannedWord,
                      maxLength: 40,
                      style: Tokens.body.style.copyWith(color: p.label),
                      onSubmitted: (_) => add(),
                    ),
                  ),
                  GestureDetector(
                    key: const Key('word-add'),
                    onTap: add,
                    child: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 24),
                  ),
                ],
              ),
            ),
          ]),
        ],
      ],
    );
  }
}

/// 키워드 자동 답장: "word → answer" pairs this phone answers with.
class KeywordRepliesPage extends StatefulWidget {
  const KeywordRepliesPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<KeywordRepliesPage> createState() => _KeywordRepliesPageState();
}

class _KeywordRepliesPageState extends State<KeywordRepliesPage> {
  final word = TextEditingController(), answer = TextEditingController();

  @override
  void dispose() {
    word.dispose();
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = widget.roomId;
    final rules = keywordRules(s.settings, id);
    Future<void> save(List<KeywordRule> r) async {
      // Only messages from now on are answered.
      await s.setPref('keyword_seen:$id', '${DateTime.now().millisecondsSinceEpoch}');
      await s.setPref(keywordKey(id), r.isEmpty ? '' : encodeKeywordRules(r));
    }

    void add() {
      final w = word.text.trim(), a = answer.text.trim();
      if (w.isEmpty || a.isEmpty || rules.length >= 30 || rules.any((r) => r.word == w)) return;
      word.clear();
      answer.clear();
      unawaited(save([...rules, (word: w, answer: a)]));
    }

    Widget field(String key, TextEditingController c, String hint, int max) => CupertinoTextField.borderless(
      key: Key(key),
      controller: c,
      placeholder: hint,
      maxLength: max,
      style: Tokens.body.style.copyWith(color: p.label),
    );
    return SettingsScaffold(
      title: l.keywordReplies,
      children: [
        group(context, footer: l.keywordRepliesInfo, [
          for (var i = 0; i < rules.length; i++)
            IosTile(
              key: Key('keyword-$i'),
              title: Text(rules[i].word),
              subtitle: Text(rules[i].answer, maxLines: 2, style: Tokens.caption.style),
              trailing: GestureDetector(
                key: Key('keyword-remove-$i'),
                onTap: () => save([...rules]..removeAt(i)),
                child: const Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: 22),
              ),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      field('keyword-word', word, l.keywordWordHint, 30),
                      Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
                      field('keyword-answer', answer, l.keywordAnswerHint, 300),
                    ],
                  ),
                ),
                GestureDetector(
                  key: const Key('keyword-add'),
                  onTap: add,
                  child: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 24),
                ),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

/// Stats made on this phone from the chat on this phone.
class RoomStatsPage extends StatefulWidget {
  const RoomStatsPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<RoomStatsPage> createState() => _RoomStatsPageState();
}

class _RoomStatsPageState extends State<RoomStatsPage> {
  RoomStats? stats;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (stats != null) return;
    final b = AppScope.read(context).backend;
    () async {
      final m = await b.timeline(widget.roomId, limit: 1000);
      final mem = await b.members(widget.roomId);
      if (mounted) setState(() => stats = RoomStats.of(m, mem.length, DateTime.now()));
    }();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final st = stats;
    if (st == null) {
      return SettingsScaffold(
        title: l.roomStats,
        children: const [Padding(padding: EdgeInsets.all(40), child: CupertinoActivityIndicator())],
      );
    }
    final busy = st.busiest;
    return SettingsScaffold(
      title: l.roomStats,
      children: [
        group(context, [
          IosTile(
            title: Text(l.statsMembers),
            additionalInfo: Text('${st.members}', key: const Key('stats-members')),
          ),
          IosTile(
            title: Text(l.statsMessages30),
            additionalInfo: Text('${st.messages30}', key: const Key('stats-messages')),
          ),
          IosTile(title: Text(l.statsPerDay), additionalInfo: Text(st.perDay.toStringAsFixed(1))),
          IosTile(
            title: Text(l.statsActive),
            additionalInfo: Text('${st.active30}', key: const Key('stats-active')),
          ),
        ]),
        group(context, header: l.statsMessages30, [_Bars(values: st.days, color: p.accent, key: const Key('stats-days'))]),
        group(context, header: l.statsHours, footer: busy == null ? l.statsInfo : '${l.statsBusiest('$busy')}\n${l.statsInfo}', [
          _Bars(values: st.hours, color: Palette.tileTeal, labels: const {0: '0', 6: '6', 12: '12', 18: '18', 23: '23'}),
        ]),
      ],
    );
  }
}

/// Simple bar chart in a card row.
class _Bars extends StatelessWidget {
  const _Bars({super.key, required this.values, required this.color, this.labels = const {}});
  final List<int> values;
  final Color color;
  final Map<int, String> labels;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final top = values.fold<int>(0, (a, b) => b > a ? b : a);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[2]),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in values)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: Container(
                        height: top == 0 ? 2 : 2 + 94 * v / top,
                        decoration: BoxDecoration(
                          color: v == 0 ? p.separator : color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Text(
                      labels[i] ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      style: Tokens.bubbleMeta.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// This phone's admin log.
class ModLogPage extends StatelessWidget {
  const ModLogPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final log = modLogOf(s.settings, roomId);
    String why(String d) => switch (d) {
      'word' => l.whyWord,
      'link' => l.whyLink,
      'flood' => l.whyFlood,
      _ => d,
    };
    String line(ModEntry e) => switch (e.kind) {
      'removed' => l.logRemoved(e.name, why(e.detail)),
      'late_edit' => l.logLateEdit(e.name),
      'wiped' => l.logWiped(e.name, int.tryParse(e.detail) ?? 0),
      'extortion' => l.logExtortion(e.name),
      'banned' => l.logBanned(e.name),
      'unbanned' => l.logUnbanned(e.name),
      'muted' => l.logMuted(e.name),
      'unmuted' => l.logUnmuted(e.name),
      'handover' => l.logHandover(e.name),
      'spam' => l.logSpam(e.name),
      'spam_ok' => l.logSpamOk(e.name),
      _ => l.logSetting(settingName(l, e.name)),
    };
    return SettingsScaffold(
      title: l.modLog,
      children: [
        group(context, footer: l.modLogInfo, [
          if (log.isEmpty)
            IosTile(
              title: Text(l.modLogEmpty, style: TextStyle(color: p.secondaryLabel)),
            )
          else
            for (final e in log)
              IosTile(
                title: Text(line(e), maxLines: 2),
                subtitle: Text(
                  e.kind == 'spam' && AntiSpam.splitDetail(e.detail).$2.isNotEmpty
                      ? '${timeAgo(context, e.time)} · ${AntiSpam.splitDetail(e.detail).$2}'
                      : timeAgo(context, e.time),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style,
                ),
              ),
        ]),
      ],
    );
  }
}

String settingName(L l, String key) => switch (key) {
  'rules' || 'rules_agree' => l.roomRules,
  'welcome' => l.welcomeMessage,
  'reactions' || 'reactions_set' || 'reactions_max' => l.reactionsSetting,
  'hide_counts' => l.hideCounts,
  'discussion' => l.discussion,
  'old_members' => l.movingBoard,
  'new_media_days' => l.newMediaTitle,
  'member_perms' => l.memberPerms,
  'perm_users' => l.permExceptions,
  'slow' => l.slowMode,
  'night' => l.roomNight,
  'no_member_dm' => l.noMemberDm,
  'raid' => l.raidLock,
  'antispam' => l.antiSpam,
  'own_tags' => l.ownTags,
  'anon' => l.anonAdmin,
  _ => key,
};

/// Date and time for log rows, in the phone's language.
String timeAgo(BuildContext context, DateTime t) => DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(t);

/// How many people have moved over from the old group.
class MovingBoardPage extends StatefulWidget {
  const MovingBoardPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<MovingBoardPage> createState() => _MovingBoardPageState();
}

class _MovingBoardPageState extends State<MovingBoardPage> {
  final field = TextEditingController();
  int now = 0;
  int old = 0;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    final b = AppScope.read(context).backend;
    () async {
      final c = await b.roomConfig(widget.roomId);
      final m = await b.members(widget.roomId);
      if (!mounted) return;
      setState(() {
        old = (c['old_members'] as num?)?.toInt() ?? 0;
        now = m.length;
        if (old > 0) field.text = '$old';
      });
    }();
  }

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final v = int.tryParse(field.text.trim()) ?? 0;
    final s = AppScope.read(context);
    final clean = v.clamp(0, 10000000);
    await s.backend.setRoomConfig(widget.roomId, 'old_members', clean == 0 ? null : clean);
    await s.logMod(widget.roomId, 'setting', 'old_members');
    if (mounted) setState(() => old = clean);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final share = old == 0 ? 0.0 : (now / old).clamp(0.0, 1.0);
    return SettingsScaffold(
      title: l.movingBoard,
      children: [
        if (old > 0)
          Container(
            key: const Key('moving-card'),
            margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
            padding: EdgeInsets.all(Tokens.space[3]),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2] + 10)),
            child: Column(
              children: [
                Text('${(share * 100).round()}%', style: Tokens.largeTitle.style.copyWith(color: p.accent)),
                SizedBox(height: Tokens.space[1]),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: p.separator)),
                        FractionallySizedBox(
                          widthFactor: share,
                          child: ColoredBox(color: p.accent),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Tokens.space[1]),
                Text(l.movedCount('$now', '$old'), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              ],
            ),
          ),
        group(context, footer: l.movingInfo, [
          IosTile(
            title: Text(l.oldMembers),
            trailing: SizedBox(
              width: 120,
              child: CupertinoTextField.borderless(
                key: const Key('old-members'),
                controller: field,
                textAlign: TextAlign.end,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                placeholder: '0',
                style: Tokens.body.style.copyWith(color: p.label),
                onSubmitted: (_) => save(),
                onTapOutside: (_) {
                  FocusScope.of(context).unfocus();
                  unawaited(save());
                },
              ),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Banned people, tap to unban.
class BannedPage extends StatefulWidget {
  const BannedPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<BannedPage> createState() => _BannedPageState();
}

class _BannedPageState extends State<BannedPage> {
  List<String>? list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (list == null) unawaited(load());
  }

  Future<void> load() async {
    final x = await AppScope.read(context).backend.banned(widget.roomId);
    if (mounted) setState(() => list = x);
  }

  Future<void> unban(String id) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(displayId(id)),
        actions: [CupertinoActionSheetAction(key: const Key('unban-ok'), onPressed: () => Navigator.pop(c, true), child: Text(l.unban))],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok != true) return;
    await s.backend.setBanned(widget.roomId, id, false);
    await s.logMod(widget.roomId, 'unbanned', displayId(id));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final x = list ?? const [];
    return SettingsScaffold(
      title: l.bannedUsers,
      children: [
        group(context, [
          if (list != null && x.isEmpty)
            IosTile(
              title: Text(l.bannedEmpty, style: TextStyle(color: p.secondaryLabel)),
            ),
          for (final id in x)
            IosTile(
              key: Key('banned-$id'),
              leading: Avatar(name: displayId(id), size: 30),
              title: Text(displayId(id)),
              additionalInfo: Text(l.unban),
              onTap: () => unban(id),
            ),
        ]),
      ],
    );
  }
}

/// The room's level (stage A, worked out on this phone).
class LevelPage extends StatefulWidget {
  const LevelPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  (int, int, int)? got;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (got != null) return;
    final b = AppScope.read(context).backend;
    () async {
      final m = await b.timeline(widget.roomId, limit: 1000);
      final mem = await b.members(widget.roomId);
      final now = DateTime.now();
      final cut = now.subtract(const Duration(days: 28));
      final active = {
        for (final x in m)
          if (x.time.isAfter(cut) && x.kind != 'call') x.sender,
      }.length;
      // The room's age: its oldest message this phone has.
      final days = m.isEmpty ? 0 : now.difference(m.map((x) => x.time).reduce((a, b) => a.isBefore(b) ? a : b)).inDays;
      if (mounted) setState(() => got = (mem.length, active, days));
    }();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final g = got;
    if (g == null) {
      return SettingsScaffold(
        title: l.roomLevel,
        children: const [Padding(padding: EdgeInsets.all(40), child: CupertinoActivityIndicator())],
      );
    }
    final (members, active, days) = g;
    final lv = levelOf(members, active, days);
    final next = lv < levelSteps.length ? levelSteps[lv] : null;
    return SettingsScaffold(
      title: l.roomLevel,
      children: [
        HeaderCard(
          color: Palette.tilePurple,
          icon: CupertinoIcons.star_fill,
          title: l.levelN(lv),
          body: next == null
              ? l.levelMax
              : l.levelNext('${(next.$1 - members).clamp(0, next.$1)}', '${(next.$2 - active).clamp(0, next.$2)}', (next.$3 - days).clamp(0, next.$3)),
        ),
        group(context, footer: l.levelInfo, [
          IosTile(title: Text(l.statsMembers), additionalInfo: Text('$members')),
          IosTile(title: Text(l.statsActive), additionalInfo: Text('$active')),
          IosTile(
            title: Text(
              l.levelN(lv),
              key: const Key('level-now'),
              style: TextStyle(color: p.accent),
            ),
            additionalInfo: Text(next == null ? '' : '${next.$1}/${next.$2}/${next.$3}'),
          ),
        ]),
      ],
    );
  }
}

/// Channel → its discussion group (one of my groups where I'm in).
class DiscussionPage extends StatelessWidget {
  const DiscussionPage({super.key, required this.roomId, required this.now});
  final String roomId;
  final String now;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final groups = [
      for (final c in s.chats)
        if (!c.isDirect && !c.isChannel && c.roomId != roomId) c,
    ];
    return _DiscussionPicker(roomId: roomId, now: now, options: [('', l.discussionNone), for (final g in groups) (g.roomId, g.name)]);
  }
}

class _DiscussionPicker extends StatefulWidget {
  const _DiscussionPicker({required this.roomId, required this.now, required this.options});
  final String roomId;
  final String now;
  final List<(String, String)> options;

  @override
  State<_DiscussionPicker> createState() => _DiscussionPickerState();
}

class _DiscussionPickerState extends State<_DiscussionPicker> {
  late String now = widget.now;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ChoicePage(
      title: l.discussion,
      options: widget.options,
      value: () => now,
      footer: l.discussionInfo,
      onPick: (v) async {
        setState(() => now = v);
        final s = AppScope.read(context);
        await s.backend.setRoomConfig(widget.roomId, 'discussion', v);
        await s.logMod(widget.roomId, 'setting', 'discussion');
      },
    );
  }
}

/// Rules, read-only, with "I'll follow the rules" when the room asks.
class RulesSheet extends StatelessWidget {
  const RulesSheet({super.key, required this.rules, this.onAgree});
  final String rules;
  final VoidCallback? onAgree;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), middle: Text(l.roomRules), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  group(context, [
                    Padding(
                      padding: EdgeInsets.all(Tokens.space[3]),
                      child: Text(
                        rules,
                        key: const Key('rules-text'),
                        style: Tokens.body.style.copyWith(color: p.label),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            if (onAgree != null)
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                child: CupertinoButton.filled(
                  key: const Key('rules-agree-button'),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: () {
                    onAgree!();
                    Navigator.pop(context);
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(l.agreeRules, textAlign: TextAlign.center),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Members never see admin numbers when the room hides them.
bool hideCountsFor(Map<String, dynamic> cfg, String role) => cfg['hide_counts'] == true && role != 'owner' && role != 'admin';

/// Owner: delete the room — remove everyone, then leave.
Future<void> deleteRoom(Backend b, String roomId) async {
  final me = b.userId;
  for (final m in await b.members(roomId)) {
    if (m.userId == me) continue;
    try {
      await b.removeMember(roomId, m.userId);
    } catch (_) {}
  }
  await b.leave(roomId);
}

/// Admin: delete every message [userId] wrote here (as far back as the
/// phone can load), then ban them. Returns how many were deleted.
Future<int> wipeUser(Backend b, String roomId, String userId) async {
  final msgs = await b.timeline(roomId, limit: 2000);
  var n = 0;
  for (final m in msgs.where((m) => m.sender == userId && m.kind != 'deleted')) {
    try {
      await b.deleteMessage(roomId, m.id);
      n++;
    } catch (_) {}
  }
  await b.setBanned(roomId, userId, true);
  return n;
}

/// "새 멤버 사진·영상·링크 제한": off, or how many days after joining.
class NewMediaPage extends StatefulWidget {
  const NewMediaPage({super.key, required this.roomId, required this.days});
  final String roomId;
  final int days;

  @override
  State<NewMediaPage> createState() => _NewMediaPageState();
}

class _NewMediaPageState extends State<NewMediaPage> {
  late int days = widget.days;

  Future<void> pick(int d) async {
    final s = AppScope.read(context);
    setState(() => days = d);
    await s.backend.setRoomConfig(widget.roomId, 'new_media_days', d);
    await s.logMod(widget.roomId, 'setting', 'new_media_days');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.newMediaTitle,
      children: [
        HeaderCard(color: Palette.tileOrange, icon: CupertinoIcons.person_badge_minus_fill, title: l.newMediaTitle, body: l.newMediaInfo),
        group(context, footer: l.newMediaFooter, [
          for (final d in const [0, 1, 3, 7, 14, 30])
            IosTile(
              key: Key('new-media-$d'),
              title: Text(d == 0 ? l.stateOff : l.newMediaDays(d)),
              trailing: days == d ? Icon(CupertinoIcons.checkmark_alt, color: p.accent, size: Tokens.listIcon) : null,
              onTap: () => pick(d),
            ),
        ]),
      ],
    );
  }
}

/// "늦게 수정된 글": messages changed more than an hour after sending (how
/// pictures get hidden in old messages). Worked out on this phone.
class LateEditsPage extends StatefulWidget {
  const LateEditsPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<LateEditsPage> createState() => _LateEditsPageState();
}

class _LateEditsPageState extends State<LateEditsPage> {
  List<Msg>? list;
  Map<String, String> names = const {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (list == null) unawaited(load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    final msgs = await b.timeline(widget.roomId, limit: 1000);
    final mem = await b.members(widget.roomId);
    if (!mounted) return;
    setState(() {
      names = {for (final m in mem) m.userId: m.name};
      list = lateEdits(msgs, {
        for (final m in mem)
          if (m.role != 'member') m.userId,
      });
    });
  }

  Future<void> remove(Msg m) async {
    final s = AppScope.read(context);
    await s.backend.deleteMessage(widget.roomId, m.id);
    await s.logMod(widget.roomId, 'removed', names[m.sender] ?? m.sender, 'late_edit');
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final items = list ?? const <Msg>[];
    return SettingsScaffold(
      title: l.lateEditTitle,
      children: [
        HeaderCard(color: Palette.tileYellow, icon: CupertinoIcons.pencil_ellipsis_rectangle, title: l.lateEditTitle, body: l.lateEditInfo),
        group(context, [
          if (items.isEmpty)
            IosTile(
              title: Text(list == null ? '…' : l.lateEditEmpty, style: TextStyle(color: p.secondaryLabel)),
            )
          else
            for (final m in items)
              IosTile(
                key: Key('late-${m.id}'),
                padding: IosTile.plainPad.add(EdgeInsets.symmetric(vertical: Tokens.space[2])),
                title: Text(names[m.sender] ?? m.sender),
                subtitle: Text(
                  l.lateEditLine(plainText(m.firstBody ?? ''), plainText(m.body ?? ''), timeAgo(context, m.time), timeAgo(context, m.editedAt!)),
                  maxLines: 4,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
                trailing: CupertinoButton(
                  key: Key('late-remove-${m.id}'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: () => remove(m),
                  child: Icon(CupertinoIcons.trash, color: Palette.tileRed, size: Tokens.listIcon),
                ),
              ),
        ]),
      ],
    );
  }
}

/// "협박받았어요": a blackmail report to our operators, with what to do.
class ExtortionReportPage extends StatefulWidget {
  const ExtortionReportPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<ExtortionReportPage> createState() => _ExtortionReportPageState();
}

class _ExtortionReportPageState extends State<ExtortionReportPage> {
  final who = TextEditingController();
  final words = TextEditingController();
  bool sending = false;
  bool sent = false;
  bool failed = false;

  @override
  void dispose() {
    who.dispose();
    words.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final s = AppScope.read(context);
    final id = who.text.trim();
    if (id.isEmpty || words.text.trim().isEmpty) return;
    setState(() => sending = true);
    final user = id.startsWith('@') ? id : '@$id';
    try {
      await s.backend.reportContent(widget.roomId, '', user, 'extortion', words.text.trim());
      await s.logMod(widget.roomId, 'extortion', id);
      if (mounted) setState(() => sent = true);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.extortionTitle,
      children: [
        HeaderCard(color: Palette.tileRed, icon: CupertinoIcons.exclamationmark_bubble_fill, title: l.extortionTitle, body: l.extortionInfo),
        if (sent)
          group(context, [
            IosTile(
              key: const Key('extortion-done'),
              leading: Icon(CupertinoIcons.checkmark_seal_fill, color: p.accent),
              title: Text(l.extortionDone),
            ),
          ])
        else ...[
          group(context, header: l.extortionWho, [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
              child: CupertinoTextField.borderless(key: const Key('extortion-who'), controller: who, placeholder: l.extortionWhoHint),
            ),
          ]),
          group(context, header: l.extortionNote, [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
              child: CupertinoTextField.borderless(
                key: const Key('extortion-words'),
                controller: words,
                minLines: 4,
                maxLines: 10,
                placeholder: l.extortionNoteHint,
              ),
            ),
          ]),
          if (failed)
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
              child: Text(l.reportFailed, style: Tokens.caption.style.copyWith(color: Palette.tileRed)),
            ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: CupertinoButton.filled(key: const Key('extortion-send'), onPressed: sending ? null : send, child: Text(l.extortionSend)),
          ),
        ],
      ],
    );
  }
}

/// 강력 스팸 차단 (Telegram tip 365): one switch for the whole group. The
/// server can't read messages, so the phones of admins who may delete do
/// the work: spam words, links and contact handles from newcomers, the
/// same words posted again and again, mass mentions. Removed messages turn
/// to dust in everyone's chat; each one is listed here with "스팸 아님".
class AntiSpamPage extends StatefulWidget {
  const AntiSpamPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<AntiSpamPage> createState() => _AntiSpamPageState();
}

class _AntiSpamPageState extends State<AntiSpamPage> {
  Map<String, dynamic> cfg = const {};
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ready) {
      ready = true;
      unawaited(load());
    }
  }

  Future<void> load() async {
    final c = await AppScope.read(context).backend.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    if (mounted) setState(() => cfg = c);
  }

  Future<void> setOn(bool v) async {
    final s = AppScope.read(context);
    setState(() => cfg = {...cfg, 'antispam': v});
    try {
      await s.backend.setRoomConfig(widget.roomId, 'antispam', v ? true : null);
      await s.logMod(widget.roomId, 'setting', 'antispam');
      // Check right away what is already in the chat.
      if (v) unawaited(s.antiSpamRoom(widget.roomId).then((_) => mounted ? setState(() {}) : null).catchError((_) {}));
    } catch (_) {
      if (mounted) setState(() => cfg = {...cfg, 'antispam': !v});
    }
  }

  /// "스팸 아님": this person is never checked again here (and a mute the
  /// filter gave them is lifted).
  Future<void> notSpam(ModEntry e) async {
    final s = AppScope.read(context);
    final b = s.backend;
    final (user, _) = AntiSpam.splitDetail(e.detail);
    try {
      final fresh = await b.roomConfig(widget.roomId);
      await b.setRoomConfig(widget.roomId, 'spam_ok', AntiSpam.withTrusted(fresh, user));
      if (RoomRules.muteUntil(fresh, user) != null && s.pref('spam_muted:${widget.roomId}:$user', '') == '1') {
        await b.setMemberLevel(widget.roomId, user, 0);
        final m = RoomRules.withMute(fresh, user, null);
        await b.setRoomConfig(widget.roomId, 'mutes', m.isEmpty ? null : m);
        await s.setPref('spam_muted:${widget.roomId}:$user', '');
      }
      await s.logMod(widget.roomId, 'spam_ok', e.name, user);
      await load();
      if (mounted) showStoryToast(context, L.of(context).spamOkDone(e.name));
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final on = AntiSpam.on(cfg);
    final trusted = AntiSpam.trusted(cfg);
    final removed = modLogOf(s.settings, widget.roomId).where((e) => e.kind == 'spam').toList();
    return SettingsScaffold(
      title: l.antiSpam,
      children: [
        HeaderCard(color: Palette.tileIndigo, icon: CupertinoIcons.shield_lefthalf_fill, title: l.antiSpam, body: l.antiSpamIntro),
        group(context, footer: l.antiSpamInfo, [
          IosTile(
            title: Text(l.antiSpam),
            trailing: IosSwitch(key: const Key('antispam-switch'), value: on, activeTrackColor: p.accent, onChanged: setOn),
          ),
        ]),
        group(context, header: l.antiSpamChecks, [
          for (final (icon, color, text) in [
            (CupertinoIcons.textformat, Palette.tileRed, l.antiSpamCheckWords),
            (CupertinoIcons.link, Palette.tileOrange, l.antiSpamCheckLinks),
            (CupertinoIcons.doc_on_doc, Palette.tileTeal, l.antiSpamCheckRepeat),
            (CupertinoIcons.at, Palette.tilePurple, l.antiSpamCheckMentions),
            (CupertinoIcons.hand_raised_fill, Palette.tileGrey, l.antiSpamCheckStrikes),
          ])
            IosTile(leading: iconTile(color, icon), title: Text(text, maxLines: 3)),
        ]),
        group(context, header: l.antiSpamRemoved, footer: l.antiSpamRemovedInfo, [
          if (removed.isEmpty)
            IosTile(
              title: Text(l.antiSpamNone, style: TextStyle(color: p.secondaryLabel)),
            )
          else
            for (final (i, e) in removed.take(50).indexed)
              IosTile(
                key: Key('spam-row-$i'),
                title: Text(e.name),
                subtitle: Text(
                  '${timeAgo(context, e.time)} · ${AntiSpam.splitDetail(e.detail).$2}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
                trailing: trusted.contains(AntiSpam.splitDetail(e.detail).$1)
                    ? Text(l.spamOkMark, style: Tokens.caption.style.copyWith(color: p.secondaryLabel))
                    : GestureDetector(
                        key: Key('spam-ok-$i'),
                        onTap: () => notSpam(e),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                          decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
                          child: Text(l.spamOk, style: Tokens.caption.style.copyWith(color: p.accent)),
                        ),
                      ),
              ),
        ]),
      ],
    );
  }
}
