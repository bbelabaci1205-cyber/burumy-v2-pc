// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'settings_kit.dart';

/// 이의 신청 (server rule 13, 대표 결정 2026-11-28): a paused account sees
/// why and until when, and sends one note to the operator. While it waits,
/// or after a "no", it says so instead of the box.
class AppealPage extends StatefulWidget {
  const AppealPage({super.key});

  @override
  State<AppealPage> createState() => _AppealPageState();
}

class _AppealPageState extends State<AppealPage> {
  final c = TextEditingController();
  Suspension? now;
  bool loaded = false, busy = false;

  @override
  void initState() {
    super.initState();
    c.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final s = await AppScope.read(context).backend.suspension();
    if (mounted) {
      setState(() {
        now = s;
        loaded = true;
      });
    }
  }

  bool get canSend => !busy && c.text.trim().isNotEmpty && now?.suspended == true && now?.appeal != 'waiting' && !tooSoon;
  bool get tooSoon => now?.againAt != null && now!.againAt!.isAfter(DateTime.now());

  Future<void> send() async {
    if (!canSend) return;
    setState(() => busy = true);
    try {
      await AppScope.read(context).backend.appeal(c.text.trim());
      if (!mounted) return;
      c.clear();
      await load();
    } catch (_) {
      await load();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = now;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    final status = s == null || !s.suspended
        ? l.notSuspended
        : [
            s.until == null ? l.suspendUntilLifted : l.suspendUntil(date.format(s.until!)),
            s.reason == 'other_edit' ? l.suspendReasonEdit : l.suspendReasonApp,
          ].join(' · ');
    final note = s?.appeal == 'waiting' ? l.appealWaiting : (s?.appeal == 'denied' && tooSoon ? l.appealDenied(date.format(s!.againAt!)) : null);
    final open = s?.suspended == true && note == null;
    return SettingsScaffold(
      title: l.appealButton,
      trailing: [if (open) GlassDone(key: const Key('appeal-send'), onTap: canSend ? send : null)],
      children: [
        if (loaded)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], Tokens.space[3]),
            child: Text(
              status,
              key: const Key('appeal-status'),
              style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
            ),
          ),
        if (note != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
            child: Text(
              note,
              key: const Key('appeal-note'),
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ),
        if (open)
          group(context, footer: l.appealInfo, [
            CupertinoTextField(
              key: const Key('appeal-field'),
              controller: c,
              autofocus: true,
              minLines: 4,
              maxLines: 8,
              maxLength: Suspension.appealMax,
              placeholder: l.appealHint,
              decoration: null,
              padding: EdgeInsets.all(Tokens.space[3]),
            ),
          ]),
      ],
    );
  }
}
