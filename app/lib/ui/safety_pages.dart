// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 원격 비상 삭제 (trusted friends + delete code), 미접속 자동 삭제 (N days
// without opening the app), and the friend's side: asking for a wipe.
// v1 parity, 2026-11-27. Phone apps only (the web can't keep secrets).
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/app_state.dart';
import '../core/safety.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'settings_kit.dart';
import 'settings_pages.dart' show PeoplePickPage;
import 'stories.dart' show showStoryToast;

/// Settings > 개인정보 및 보안 > 원격 비상 삭제.
class RemoteWipePage extends StatefulWidget {
  const RemoteWipePage({super.key});
  @override
  State<RemoteWipePage> createState() => _RemoteWipePageState();
}

class _RemoteWipePageState extends State<RemoteWipePage> {
  final code = TextEditingController(), again = TextEditingController(), last = TextEditingController();
  String? error;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    last.text = AppScope.of(context).pref(Safety.lastMsgKey, '');
  }

  @override
  void dispose() {
    code.dispose();
    again.dispose();
    last.dispose();
    super.dispose();
  }

  Future<void> saveCode() async {
    final l = L.of(context);
    final s = AppScope.of(context);
    final c = code.text.trim();
    if (c.length < 6) return setState(() => error = l.wipeCodeRule);
    if (c != again.text.trim()) return setState(() => error = l.passwordMismatch);
    await s.setPref(Safety.codeKey, Safety.sealCode(c));
    code.clear();
    again.clear();
    if (!mounted) return;
    setState(() => error = null);
    showStoryToast(context, l.wipeCodeSaved);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final friends = Safety.friends(s.settings);
    final hasCode = s.pref(Safety.codeKey, '').isNotEmpty;
    final names = {for (final c in s.chats.where((c) => c.isDirect)) c.peer: c.name};
    Widget field(Key k, TextEditingController c, String hint, {bool secret = true, int lines = 1}) => CupertinoTextField(
      key: k,
      controller: c,
      obscureText: secret,
      placeholder: hint,
      minLines: lines,
      maxLines: secret ? 1 : 4,
      decoration: null,
      padding: EdgeInsets.all(Tokens.space[3]),
    );
    return SettingsScaffold(
      title: l.remoteWipe,
      children: [
        HeaderCard(color: Palette.tileRed, icon: CupertinoIcons.antenna_radiowaves_left_right, title: l.remoteWipe, body: l.remoteWipeInfo),
        group(context, header: l.wipeFriends, footer: l.wipeFriendsInfo, [
          NavRow(
            key: const Key('wipe-friends'),
            title: l.wipeFriendsPick,
            value: friends.isEmpty ? l.notSet : friends.map((f) => names[f] ?? displayId(f)).join(', '),
            page: (_) => PeoplePickPage(
              title: l.wipeFriends,
              picked: friends,
              max: Safety.maxFriends,
              onDone: (ids) => s.setPref(Safety.friendsKey, ids.take(Safety.maxFriends).join(',')),
            ),
          ),
        ]),
        group(context, header: hasCode ? l.wipeCodeChange : l.wipeCode, footer: error ?? l.wipeCodeInfo, error: error != null, [
          field(const Key('wipe-code'), code, l.wipeCode),
          field(const Key('wipe-code-again'), again, l.confirmPassword),
          IosTile(
            key: const Key('wipe-code-save'),
            title: Text(l.save, style: TextStyle(color: p.accent)),
            onTap: saveCode,
          ),
        ]),
        group(context, footer: l.wipeTwoInfo, [PrefSwitch(Safety.twoKey, key: const Key('wipe-two'), title: l.wipeTwo)]),
        group(context, header: l.wipeLastMsg, footer: l.wipeLastMsgInfo, [
          field(const Key('wipe-last'), last, l.wipeLastMsgHint, secret: false, lines: 2),
          IosTile(
            key: const Key('wipe-last-save'),
            title: Text(l.save, style: TextStyle(color: p.accent)),
            onTap: () async {
              await s.setPref(Safety.lastMsgKey, last.text.trim());
              if (context.mounted) showStoryToast(context, l.savedShort);
            },
          ),
        ]),
        group(context, footer: l.decoyTip, const []),
      ],
    );
  }
}

/// Settings row: 미접속 자동 삭제 (kept in the keychain so it works while
/// the app is locked).
class IdleWipeRow extends StatefulWidget {
  const IdleWipeRow({super.key});
  @override
  State<IdleWipeRow> createState() => _IdleWipeRowState();
}

class _IdleWipeRowState extends State<IdleWipeRow> {
  int? days;

  @override
  void initState() {
    super.initState();
    Safety.idleDays().then((d) {
      if (mounted) setState(() => days = d);
    }, onError: (_) {});
  }

  String label(L l, int d) => d == 0 ? l.timerOff : l.daysN(d);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = days ?? 0;
    return NavRow(
      key: const Key('idle-wipe'),
      color: Palette.tileOrange,
      icon: CupertinoIcons.hourglass,
      title: l.idleWipe,
      value: now == 0 ? l.stateOff : label(l, now),
      page: (_) => ChoicePage(
        title: l.idleWipe,
        footer: l.idleWipeInfo,
        options: [for (final d in Safety.idleChoices) ('$d', label(l, d))],
        value: () => '${days ?? 0}',
        onPick: (v) async {
          final d = int.parse(v);
          await Safety.setIdleDays(d);
          if (mounted) setState(() => days = d);
        },
      ),
    );
  }
}

/// A trusted friend's side (1:1 정보 > 더 보기 > 비상 삭제 요청): send the
/// delete code they gave me. Their phone checks it; I learn nothing back.
class WipeRequestPage extends StatefulWidget {
  const WipeRequestPage({super.key, required this.roomId, required this.name});
  final String roomId;
  final String name;
  @override
  State<WipeRequestPage> createState() => _WipeRequestPageState();
}

class _WipeRequestPageState extends State<WipeRequestPage> {
  final code = TextEditingController();
  bool busy = false;

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final l = L.of(context);
    if (busy || code.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend.sendSignal(widget.roomId, Safety.wipeKind, {'code': code.text.trim()});
      if (!mounted) return;
      showStoryToast(context, l.wipeRequestSent);
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) showStoryToast(context, l.saveFailed);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SettingsScaffold(
      title: l.wipeRequest,
      children: [
        HeaderCard(color: Palette.tileRed, icon: CupertinoIcons.exclamationmark_shield_fill, title: l.wipeRequest, body: l.wipeRequestInfo(widget.name)),
        group(context, footer: l.wipeRequestNote, [
          CupertinoTextField(
            key: const Key('wipe-request-code'),
            controller: code,
            obscureText: true,
            placeholder: l.wipeCode,
            decoration: null,
            padding: EdgeInsets.all(Tokens.space[3]),
          ),
          IosTile(
            key: const Key('wipe-request-send'),
            title: Text(l.wipeRequestSend, style: TextStyle(color: Palette.tileRed)),
            onTap: send,
          ),
        ]),
        if (kIsWeb) group(context, footer: l.emergencyWebInfo, const []),
      ],
    );
  }
}
