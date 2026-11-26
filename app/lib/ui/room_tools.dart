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

import '../core/app_state.dart';
import '../core/automod.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
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
    final rules = (cfg['rules'] as String? ?? '').trim();
    final welcome = (cfg['welcome'] as String? ?? '').trim();
    final old = (cfg['old_members'] as num?)?.toInt() ?? 0;
    return SettingsScaffold(
      title: l.manageTools,
      children: [
        HeaderCard(color: Palette.tileBlue, icon: CupertinoIcons.shield_lefthalf_fill, title: l.manageTools, body: l.manageToolsInfo),
        group(context, header: l.toolsJoin, [
          NavRow(
            key: const Key('tool-rules'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.doc_text_fill,
            title: l.roomRules,
            value: rules.isEmpty ? l.stateOff : l.stateOn,
            onTap: () => open(RoomTextPage(roomId: id, configKey: 'rules')),
          ),
          NavRow(
            key: const Key('tool-welcome'),
            color: p.tileGreen,
            icon: CupertinoIcons.hand_raised_fill,
            title: l.welcomeMessage,
            value: welcome.isEmpty ? l.stateOff : l.stateOn,
            onTap: () => open(RoomTextPage(roomId: id, configKey: 'welcome')),
          ),
          NavRow(
            key: const Key('tool-level'),
            color: Palette.tilePurple,
            icon: CupertinoIcons.star_fill,
            title: l.roomLevel,
            onTap: () => open(LevelPage(roomId: id)),
          ),
        ]),
        group(context, header: l.toolsPosts, footer: widget.isChannel ? l.hideCountsInfo : l.hideCountsInfoGroup, [
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
      setState(() {
        field.text = c[widget.configKey] as String? ?? '';
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
      await s.backend.setRoomConfig(widget.roomId, widget.configKey, text.isEmpty ? null : text);
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
        group(context, footer: error ?? (rules ? l.roomRulesInfo : l.welcomeInfo), error: error != null, [
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

  void step(int d) {
    final v = (max + d).clamp(1, 11);
    if (v == max) return;
    setState(() => max = v);
    unawaited(put('reactions_max', v));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.reactionsSetting,
      children: [
        group(context, footer: l.reactionsInfo, [
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
            IosTile(
              title: Text(l.reactionsMax),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepButton(key: const Key('react-max-minus'), icon: CupertinoIcons.minus, onTap: max > 1 ? () => step(-1) : null),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '$max',
                      key: const Key('react-max'),
                      textAlign: TextAlign.center,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                  ),
                  _StepButton(key: const Key('react-max-plus'), icon: CupertinoIcons.plus, onTap: max < 11 ? () => step(1) : null),
                ],
              ),
            ),
          ]),
      ],
    );
  }
}

/// iOS stepper half (−/+), grey capsule.
class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 32,
        decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: onTap == null ? p.secondaryLabel : p.label),
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
      'banned' => l.logBanned(e.name),
      'unbanned' => l.logUnbanned(e.name),
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
                subtitle: Text(timeAgo(context, e.time), style: Tokens.caption.style),
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
