// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Group / channel rules screens (v1 parity batch 2, 2026-11-27): 멤버 권한,
// 슬로 모드, 관리자 권한, 멤버 태그, 기간 메시지 금지, 방장 넘기기, @멘션.
// Layout from v1 (Telegram-like lists), look per iOS Settings.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../core/group_tools.dart';
import '../core/room_rules.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'appeal_page.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'wide.dart';

String slowLabel(L l, int s) => switch (s) {
  0 => l.stateOff,
  < 60 => l.ruleSecs(s),
  < 3600 => l.ruleMins(s ~/ 60),
  _ => l.ruleHours(s ~/ 3600),
};

String permLabel(L l, String k) => switch (k) {
  'text' => l.permText,
  'media' => l.permMedia,
  'photo' => l.permPhoto,
  'video' => l.permVideo,
  'file' => l.permFile,
  'music' => l.permMusic,
  'voice' => l.permVoice,
  'videonote' => l.permVideoNote,
  'sticker' => l.permSticker,
  'poll' => l.permPoll,
  'link' => l.permLink,
  'invite' => l.permInvite,
  'pin' => l.permPin,
  _ => l.permInfo,
};

String rightLabel(L l, String k) => switch (k) {
  'info' => l.rightInfo,
  'delete' => l.rightDelete,
  'ban' => l.rightBan,
  'invite' => l.rightInvite,
  'pin' => l.rightPin,
  'mute' => l.rightMute,
  _ => l.rightAddAdmin,
};

/// A list of switches saved straight into the room settings.
class _SwitchListPage extends StatefulWidget {
  const _SwitchListPage({
    required this.title,
    required this.header,
    required this.footer,
    required this.keys,
    required this.label,
    required this.initial,
    required this.save,
    this.prefix = 'perm',
    this.after,
  });
  final String title, header, footer, prefix;

  /// More settings under the switches.
  final Widget? after;
  final List<String> keys;
  final String Function(L l, String k) label;
  final Set<String> initial;
  final Future<void> Function(Set<String> on) save;

  @override
  State<_SwitchListPage> createState() => _SwitchListPageState();
}

class _SwitchListPageState extends State<_SwitchListPage> {
  late Set<String> on = {...widget.initial};

  Future<void> flip(String k, bool v) async {
    final before = {...on};
    setState(() => v ? on.add(k) : on.remove(k));
    try {
      await widget.save(on);
    } catch (_) {
      if (mounted) setState(() => on = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: widget.title,
      children: [
        group(context, header: widget.header, footer: widget.footer, [
          for (final k in widget.keys)
            IosTile(
              title: Text(widget.label(l, k)),
              trailing: IosSwitch(key: Key('${widget.prefix}-$k'), value: on.contains(k), activeTrackColor: p.accent, onChanged: (v) => flip(k, v)),
            ),
        ]),
        ?widget.after,
      ],
    );
  }
}

/// 멤버 권한: what plain members may send here. With chat safety (380):
/// media split by kind under one folding row, plus 예외 per member.
Widget memberPermsPage(AppState s, String roomId, Map<String, dynamic> cfg, L l) => Features.chatSafety
    ? MemberPermsPage(roomId: roomId, cfg: cfg)
    : _SwitchListPage(
        title: l.memberPerms,
        header: l.memberPermsHeader,
        footer: l.memberPermsInfo,
        keys: RoomRules.memberPerms,
        label: permLabel,
        initial: {
          for (final k in RoomRules.memberPerms)
            if (RoomRules.memberMay(cfg, k)) k,
        },
        save: (on) async {
          final off = {
            for (final k in RoomRules.memberPerms)
              if (!on.contains(k)) k: false,
          };
          await s.backend.setRoomConfig(roomId, 'member_perms', off.isEmpty ? null : off);
          await s.logMod(roomId, 'setting', 'member_perms');
        },
      );

/// 관리자 권한: the owner picks what this admin may do, and (tip 94)
/// whether they stay anonymous.
Widget adminRightsPage(AppState s, String roomId, Member m, Map<String, dynamic> cfg, L l) => _SwitchListPage(
  title: l.adminRights,
  header: m.name,
  footer: l.adminRightsInfo,
  prefix: 'right',
  keys: RoomRules.rights,
  label: rightLabel,
  initial: RoomRules.rightsOf(cfg, m.userId).toSet(),
  save: (on) async {
    final fresh = await s.backend.roomConfig(roomId);
    await s.backend.setRoomConfig(roomId, 'admin_rights', RoomRules.withRights(fresh, m.userId, on.toList()));
  },
  after: AnonSwitchGroup(roomId: roomId, userId: m.userId, initial: AnonAdmins.isOn(cfg, m.userId)),
);

/// 익명으로 남기 (tip 94): this admin's messages show the group's name and
/// photo, and members don't see them in the member list.
class AnonSwitchGroup extends StatefulWidget {
  const AnonSwitchGroup({super.key, required this.roomId, required this.userId, required this.initial, this.self = false});
  final String roomId, userId;
  final bool initial;

  /// The owner's own switch (group tools page).
  final bool self;

  @override
  State<AnonSwitchGroup> createState() => _AnonSwitchGroupState();
}

class _AnonSwitchGroupState extends State<AnonSwitchGroup> {
  late bool on = widget.initial;

  Future<void> flip(bool v) async {
    final s = AppScope.read(context);
    setState(() => on = v);
    try {
      final fresh = await s.backend.roomConfig(widget.roomId);
      final next = AnonAdmins.withAnon(fresh, widget.userId, v, s.backend.clock);
      await s.backend.setRoomConfig(widget.roomId, 'anon', next.isEmpty ? null : next);
      await s.logMod(widget.roomId, 'setting', 'anon');
    } catch (_) {
      if (mounted) setState(() => on = !v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return group(context, footer: widget.self ? l.anonSelfInfo : l.anonAdminInfo, [
      IosTile(
        leading: iconTile(Palette.tileGrey, CupertinoIcons.eye_slash_fill),
        title: Text(l.anonAdmin),
        trailing: IosSwitch(key: const Key('right-anon'), value: on, activeTrackColor: p.accent, onChanged: flip),
      ),
    ]);
  }
}

/// One pick out of a few, saved by [onPick] (room settings, not my prefs).
class RoomChoicePage extends StatefulWidget {
  const RoomChoicePage({super.key, required this.title, required this.options, required this.initial, required this.onPick, this.footer, this.card});
  final String title;
  final List<(String, String)> options;
  final String initial;
  final Future<void> Function(String v) onPick;
  final String? footer;
  final Widget? card;

  @override
  State<RoomChoicePage> createState() => _RoomChoicePageState();
}

class _RoomChoicePageState extends State<RoomChoicePage> {
  late String now = widget.initial;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return SettingsScaffold(
      title: widget.title,
      children: [
        ?widget.card,
        group(context, footer: widget.footer, [
          for (final (v, label) in widget.options)
            IosTile(
              key: Key('pick-$v'),
              title: Text(label),
              trailing: v == now ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
              onTap: () async {
                final before = now;
                setState(() => now = v);
                try {
                  await widget.onPick(v);
                } catch (_) {
                  if (mounted) setState(() => now = before);
                }
              },
            ),
        ]),
      ],
    );
  }
}

/// 다음 동안 메시지 금지: the server stops them (level -1); the end time
/// is kept so an admin's phone lifts it later.
Future<void> muteMember(AppState s, String roomId, Member m, int secs) async {
  final b = s.backend;
  await b.setMemberLevel(roomId, m.userId, -1);
  final fresh = await b.roomConfig(roomId);
  await b.setRoomConfig(roomId, 'mutes', RoomRules.withMute(fresh, m.userId, secs == 0 ? null : b.clock.add(Duration(seconds: secs)), forever: secs == 0));
  await s.logMod(roomId, 'muted', m.name);
}

Future<void> unmuteMember(AppState s, String roomId, String userId, String name) async {
  final b = s.backend;
  await b.setMemberLevel(roomId, userId, 0);
  final fresh = await b.roomConfig(roomId);
  final left = RoomRules.withMute(fresh, userId, null);
  await b.setRoomConfig(roomId, 'mutes', left.isEmpty ? null : left);
  await s.logMod(roomId, 'unmuted', name);
}

/// 슬로 모드.
Widget slowModePage(AppState s, String roomId, Map<String, dynamic> cfg, L l) => RoomChoicePage(
  title: l.slowMode,
  footer: l.slowModeInfo,
  options: [for (final v in RoomRules.slowChoices) ('$v', slowLabel(l, v))],
  initial: '${RoomRules.slowSeconds(cfg)}',
  onPick: (v) async {
    final n = int.parse(v);
    await s.backend.setRoomConfig(roomId, 'slow', n == 0 ? null : n);
    await s.logMod(roomId, 'setting', 'slow');
  },
);

String nightLabel(L l, String v) {
  if (v == 'off') return l.stateOff;
  final p = v.split('-');
  return l.nightRange(int.parse(p[0]), int.parse(p[1]));
}

Widget nightModePage(AppState s, String roomId, Map<String, dynamic> cfg, L l) => RoomChoicePage(
  title: l.roomNight,
  footer: l.roomNightInfo,
  options: [for (final v in RoomRules.nightChoices) (v, nightLabel(l, v))],
  initial: RoomRules.nightValue(cfg),
  onPick: (v) async {
    await s.backend.setRoomConfig(roomId, 'night', RoomRules.nightConfig(v, DateTime.now().timeZoneOffset));
    await s.logMod(roomId, 'setting', 'night');
  },
);

/// 멤버 태그: a full-screen editor (no popup text fields).
class TagEditPage extends StatefulWidget {
  const TagEditPage({super.key, required this.roomId, required this.member, required this.initial, this.own = false});
  final String roomId;
  final Member member;
  final String initial;

  /// 556: my own tag (kept on my member event, not the room settings).
  final bool own;
  @override
  State<TagEditPage> createState() => _TagEditPageState();
}

class _TagEditPageState extends State<TagEditPage> {
  late final c = TextEditingController(text: widget.initial);
  bool busy = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final s = AppScope.read(context);
    setState(() => busy = true);
    try {
      if (widget.own) {
        await s.backend.setMyRoomTag(widget.roomId, c.text.trim());
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
      final fresh = await s.backend.roomConfig(widget.roomId);
      final tags = RoomRules.withTag(fresh, widget.member.userId, c.text);
      await s.backend.setRoomConfig(widget.roomId, 'tags', tags.isEmpty ? null : tags);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SettingsScaffold(
      title: widget.own ? l.myTag : l.memberTag,
      trailing: [GlassDone(key: const Key('tag-save'), onTap: busy ? null : save)],
      children: [
        group(context, header: widget.member.name, footer: widget.own ? l.myTagInfo : l.memberTagInfo, [
          CupertinoTextField(
            key: const Key('tag-field'),
            controller: c,
            autofocus: true,
            maxLength: RoomRules.tagMax,
            placeholder: l.memberTagHint,
            decoration: null,
            padding: EdgeInsets.all(Tokens.space[3]),
          ),
        ]),
      ],
    );
  }
}

/// 다음 동안 메시지 금지: returns seconds (0 = until lifted) or null.
Future<int?> pickMuteTime(BuildContext context) {
  final l = L.of(context);
  String label(int s) => switch (s) {
    3600 => l.muteFor1h,
    86400 => l.muteFor1d,
    604800 => l.muteFor7d,
    _ => l.muteForever,
  };
  return showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.muteMember),
      actions: [
        for (final v in RoomRules.muteChoices) CupertinoActionSheetAction(key: Key('mute-$v'), onPressed: () => Navigator.pop(c, v), child: Text(label(v))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// 고정 기간: seconds (0 = until unpinned) or null.
Future<int?> pickPinTime(BuildContext context) {
  final l = L.of(context);
  String label(int s) => switch (s) {
    86400 => l.pinFor1d,
    604800 => l.pinFor1w,
    2592000 => l.pinFor1m,
    _ => l.pinForever,
  };
  return showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.pinHowLong),
      actions: [
        for (final v in RoomRules.pinChoices) CupertinoActionSheetAction(key: Key('pin-for-$v'), onPressed: () => Navigator.pop(c, v), child: Text(label(v))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// 고정 in a 1:1 (tip 276): how long, plus "{name}님에게도 고정" (on = both
/// see it, as before; off = only on my phone). Returns (seconds, both).
Future<(int, bool)?> pickPinFor(BuildContext context, String name) {
  final l = L.of(context);
  var both = true;
  String label(int s) => switch (s) {
    86400 => l.pinFor1d,
    604800 => l.pinFor1w,
    2592000 => l.pinFor1m,
    _ => l.pinForever,
  };
  return showCupertinoModalPopup<(int, bool)>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.pinHowLong),
      message: StatefulBuilder(
        builder: (c2, set) {
          final p = paletteOf(c2);
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pinAlsoFor(name), style: Tokens.body.style.copyWith(color: p.label)),
                    SizedBox(height: Tokens.space[0]),
                    Text(
                      both ? l.pinAlsoForOn : l.pinOnlyMeInfo,
                      key: const Key('pin-both-info'),
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ],
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              IosSwitch(key: const Key('pin-both'), value: both, onChanged: (v) => set(() => both = v)),
            ],
          );
        },
      ),
      actions: [
        for (final v in RoomRules.pinChoices)
          CupertinoActionSheetAction(key: Key('pin-for-$v'), onPressed: () => Navigator.pop(c, (v, both)), child: Text(label(v))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// 고정 (groups/channels): how long, plus "모두에게 알림" (Telegram: on by
/// default). Returns (seconds, notify) or null when cancelled.
Future<(int, bool)?> pickPin(BuildContext context) {
  final l = L.of(context);
  var notify = true;
  String label(int s) => switch (s) {
    86400 => l.pinFor1d,
    604800 => l.pinFor1w,
    2592000 => l.pinFor1m,
    _ => l.pinForever,
  };
  return showCupertinoModalPopup<(int, bool)>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.pinHowLong),
      message: StatefulBuilder(
        builder: (c2, set) {
          final p = paletteOf(c2);
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pinNotifyAll, style: Tokens.body.style.copyWith(color: p.label)),
                    SizedBox(height: Tokens.space[0]),
                    Text(l.pinNotifyInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              IosSwitch(key: const Key('pin-notify'), value: notify, onChanged: (v) => set(() => notify = v)),
            ],
          );
        },
      ),
      actions: [
        for (final v in RoomRules.pinChoices)
          CupertinoActionSheetAction(key: Key('pin-for-$v'), onPressed: () => Navigator.pop(c, (v, notify)), child: Text(label(v))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// 방장 넘기기: 1/3/7 days as joint owners.
Future<int?> pickHandoverDays(BuildContext context, String name) {
  final l = L.of(context);
  return showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.handoverTitle(name)),
      message: Text(l.handoverInfo),
      actions: [
        for (final d in RoomRules.handoverDays)
          CupertinoActionSheetAction(key: Key('handover-$d'), onPressed: () => Navigator.pop(c, d), child: Text(l.daysN(d))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// Members to pick after "@" in the composer (above the input, like
/// Telegram).
class MentionList extends StatelessWidget {
  const MentionList({super.key, required this.members, required this.onPick, this.everyone});
  final List<Member> members;
  final ValueChanged<String> onPick;

  /// "@모두" row when I may use it.
  final String? everyone;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final rows = <Widget>[
      if (everyone != null)
        IosTile(
          key: const Key('mention-all'),
          leadingSize: 32,
          leading: Icon(CupertinoIcons.person_3_fill, color: p.accent, size: 22),
          title: Text(everyone!),
          subtitle: Text(l.mentionAllInfo),
          onTap: () => onPick(everyone!),
        ),
      for (final m in members.take(6))
        IosTile(
          key: Key('mention-${m.userId}'),
          leadingSize: 32,
          leading: Avatar(name: m.name, size: 32, userId: m.userId),
          title: Text(m.name),
          subtitle: Text(displayId(m.userId)),
          onTap: () => onPick(m.name.contains(' ') ? displayId(m.userId).replaceFirst('@', '') : m.name),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      key: const Key('mention-list'),
      margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// The server refused a 1:1 chat because a group we share blocks
/// member-to-member chats (v1 "그룹 안 1:1 막기"). Says so; true if it was that.
Future<bool> explainDmBlocked(BuildContext context, Object error) async {
  if (await explainStrike(context, error)) return true;
  if (!context.mounted || !RoomRules.isDmBlocked(error)) return false;
  await showCupertinoDialog<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => CupertinoAlertDialog(
      key: const Key('dm-blocked'),
      content: Text(L.of(c).memberDmBlocked),
      actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(c), child: Text(L.of(c).okButton))],
    ),
  );
  return true;
}

/// The server paused this account, or warned it, for refusals our own app
/// never causes (a changed app or a script; 검수 2026-11-28). Says so;
/// true if it was that.
Future<bool> explainStrike(BuildContext context, Object error) async {
  final t = error.toString();
  final suspended = t.contains('account suspended');
  if (!suspended && !t.contains('looks like a modified app')) return false;
  final edit = t.contains("someone else's message");
  var appeal = false;
  await showCupertinoDialog<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => CupertinoAlertDialog(
      key: Key(suspended ? 'account-suspended' : 'account-warned'),
      content: Text(edit ? L.of(c).accountSuspendedEdit : (suspended ? L.of(c).accountSuspended : L.of(c).accountWarned)),
      actions: [
        if (suspended)
          CupertinoDialogAction(
            key: const Key('appeal-open'),
            onPressed: () {
              appeal = true;
              Navigator.pop(c);
            },
            child: Text(L.of(c).appealButton),
          ),
        CupertinoDialogAction(isDefaultAction: true, onPressed: () => Navigator.pop(c), child: Text(L.of(c).okButton)),
      ],
    ),
  );
  if (appeal && context.mounted) await Navigator.of(context).push(IosPageRoute(builder: (_) => const AppealPage()));
  return true;
}

/// 380 멤버 권한: 글 보내기, "미디어 보내기 9/9" that folds open into the
/// kinds (check circles), the rest, and 예외 (members set differently).
/// With [userId] it edits that one member's exception instead.
class MemberPermsPage extends StatefulWidget {
  const MemberPermsPage({super.key, required this.roomId, required this.cfg, this.userId, this.name});
  final String roomId;
  final Map<String, dynamic> cfg;
  final String? userId, name;

  @override
  State<MemberPermsPage> createState() => _MemberPermsPageState();
}

class _MemberPermsPageState extends State<MemberPermsPage> {
  late Map<String, dynamic> cfg = widget.cfg;
  late Set<String> on = {
    for (final k in RoomRules.memberPermsSplit)
      if (RoomRules.memberMay(cfg, k, userId: widget.userId)) k,
  };
  bool mediaOpen = false;
  List<Member> members = const [];

  @override
  void initState() {
    super.initState();
    if (widget.userId == null) _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final m = await AppScope.read(context).backend.members(widget.roomId);
      if (mounted) setState(() => members = m);
    } catch (_) {}
  }

  Future<void> save(Set<String> next) async {
    final before = on;
    setState(() => on = next);
    final s = AppScope.read(context);
    try {
      final fresh = await s.backend.roomConfig(widget.roomId);
      if (widget.userId == null) {
        await s.backend.setRoomConfig(widget.roomId, 'member_perms', RoomRules.permsValue(next));
        await s.logMod(widget.roomId, 'setting', 'member_perms');
      } else {
        final ex = RoomRules.withException(fresh, widget.userId!, next);
        await s.backend.setRoomConfig(widget.roomId, 'perm_users', ex.isEmpty ? null : ex);
        await s.logMod(widget.roomId, 'setting', 'perm_users');
      }
      cfg = await s.backend.roomConfig(widget.roomId);
    } catch (_) {
      if (mounted) setState(() => on = before);
    }
  }

  void flip(String k, bool v) => save(v ? {...on, k} : ({...on}..remove(k)));

  Map<String, dynamic> get exceptions => (cfg['perm_users'] as Map?)?.cast<String, dynamic>() ?? const {};

  Future<void> editException(String userId, String name) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => MemberPermsPage(roomId: widget.roomId, cfg: cfg, userId: userId, name: name),
      ),
    );
    final s = AppScope.read(context);
    final fresh = await s.backend.roomConfig(widget.roomId).catchError((_) => cfg);
    if (mounted) setState(() => cfg = fresh);
  }

  Future<void> addException() async {
    final l = L.of(context);
    final me = AppScope.read(context).backend.userId;
    final pick = await showCupertinoModalPopup<Member>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.permPickMember),
        actions: [
          for (final m in members.where((m) => m.userId != me && m.role != 'owner' && m.role != 'admin' && !exceptions.containsKey(m.userId)))
            CupertinoActionSheetAction(key: Key('perm-pick-${m.userId}'), onPressed: () => Navigator.pop(c, m), child: Text(m.name)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick != null && mounted) await editException(pick.userId, pick.name);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final media = RoomRules.mediaKinds;
    final mediaOn = media.where(on.contains).length;
    Widget sw(String k) => IosTile(
      title: Text(permLabel(l, k)),
      trailing: IosSwitch(key: Key('perm-$k'), value: on.contains(k), activeTrackColor: p.accent, onChanged: (v) => flip(k, v)),
    );
    final rows = <Widget>[
      sw('text'),
      IosTile(
        key: const Key('perm-media-row'),
        title: Row(
          children: [
            Text(l.permMediaAll),
            SizedBox(width: Tokens.space[1]),
            Text('$mediaOn/${media.length}', style: TextStyle(color: p.secondaryLabel)),
            SizedBox(width: Tokens.space[0]),
            Icon(mediaOpen ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 14, color: p.secondaryLabel),
          ],
        ),
        onTap: () => setState(() => mediaOpen = !mediaOpen),
        trailing: IosSwitch(
          key: const Key('perm-media'),
          value: mediaOn > 0,
          activeTrackColor: p.accent,
          onChanged: (v) => save(v ? {...on, ...media} : on.difference(media.toSet())),
        ),
      ),
      if (mediaOpen)
        for (final k in media)
          IosTile(
            key: Key('perm-kind-$k'),
            padding: const EdgeInsetsDirectional.only(start: 44, end: 17),
            title: Text(permLabel(l, k)),
            trailing: Icon(
              on.contains(k) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: on.contains(k) ? p.accent : p.secondaryLabel,
              size: 22,
            ),
            onTap: () => flip(k, !on.contains(k)),
          ),
      for (final k in const ['invite', 'pin', 'info']) sw(k),
    ];
    final names = {for (final m in members) m.userId: m.name};
    return SettingsScaffold(
      title: widget.userId == null ? l.memberPerms : (widget.name ?? ''),
      children: [
        group(
          context,
          header: widget.userId == null ? l.memberPermsHeader : l.permExceptions,
          footer: widget.userId == null ? l.memberPermsInfo : l.permExceptionInfo,
          rows,
        ),
        // 556: members may put a tag next to their own name.
        if (widget.userId == null)
          group(context, header: l.memberTag, footer: l.ownTagsInfo, [
            IosTile(
              title: Text(l.ownTags),
              trailing: IosSwitch(
                key: const Key('perm-own-tags'),
                value: MemberTags.ownAllowed(cfg),
                activeTrackColor: p.accent,
                onChanged: (v) async {
                  final s = AppScope.read(context);
                  setState(() => cfg = {...cfg, 'own_tags': v});
                  try {
                    await s.backend.setRoomConfig(widget.roomId, 'own_tags', v ? true : null);
                    await s.logMod(widget.roomId, 'setting', 'own_tags');
                  } catch (_) {
                    if (mounted) setState(() => cfg = {...cfg, 'own_tags': !v});
                  }
                },
              ),
            ),
          ]),
        if (widget.userId != null)
          group(context, [
            IosTile(
              key: const Key('perm-exception-remove'),
              title: Text(l.permExceptionRemove, style: const TextStyle(color: Palette.tileRed)),
              onTap: () async {
                final s = AppScope.read(context);
                final fresh = await s.backend.roomConfig(widget.roomId);
                final ex = RoomRules.withException(fresh, widget.userId!, null);
                await s.backend.setRoomConfig(widget.roomId, 'perm_users', ex.isEmpty ? null : ex);
                if (context.mounted) Navigator.of(context).maybePop();
              },
            ),
          ])
        else
          group(context, header: l.permExceptions, footer: l.permExceptionInfo, [
            IosTile(
              key: const Key('perm-exception-add'),
              leading: Icon(CupertinoIcons.person_badge_plus, color: p.accent),
              title: Text(l.permExceptionAdd, style: TextStyle(color: p.accent)),
              onTap: addException,
            ),
            for (final e in exceptions.entries)
              IosTile(
                key: Key('perm-exception-${e.key}'),
                leading: Avatar(name: names[e.key] ?? e.key, userId: e.key, size: 30),
                title: Text(names[e.key] ?? e.key),
                additionalInfo: Text(l.permExceptionCount(e.value is Map ? (e.value as Map).length : 0)),
                trailing: const IosChevron(),
                onTap: () => editException(e.key, names[e.key] ?? e.key),
              ),
          ]),
      ],
    );
  }
}
