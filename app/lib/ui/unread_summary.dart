// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 안 읽은 대화 AI 요약 (WhatsApp 2025, Viber 2026): when many messages came
// in while I was away, a bar at the top offers "요약 보기" and the phone AI
// turns them into a few lines. WhatsApp and Viber send the messages to a
// server for this; ours never leave the phone (core/ai_local.dart). Off in
// chats with 공유 비활성화 and on phones without on-device AI.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/ai_local.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ai_age_ui.dart';

class UnreadSummary {
  const UnreadSummary._();

  /// Fewer unread than this: just read them.
  static const from = 10;

  /// The last messages the model gets (on-phone models have small windows).
  static const maxChars = 3000;

  static String rules(String language) =>
      'You summarize unread chat messages for the person reading them. Reply in $language with 3 to 5 short lines, '
      "each starting with '• '. Keep names, times, places, numbers and decisions. Leave out greetings and small talk. "
      'Never add facts.';

  /// "name: words" lines of the unread texts, newest kept when too long.
  static String input(List<Msg> unread, String Function(String sender) name) {
    final lines = <String>[];
    var size = 0;
    for (final m in unread.reversed) {
      final t = (m.body ?? '').trim();
      if (m.kind != 'text' || t.isEmpty) continue;
      final line = '${m.mine ? 'me' : name(m.sender)}: $t';
      if (size + line.length > maxChars) break;
      lines.add(line);
      size += line.length + 1;
    }
    return lines.reversed.join('\n');
  }
}

class UnreadSummaryBar extends StatefulWidget {
  const UnreadSummaryBar({super.key, required this.roomId, required this.unread, required this.msgs, required this.blocked});
  final String roomId;

  /// How many were unread when the chat opened.
  final int unread;

  /// The chat's messages, oldest first.
  final List<Msg> msgs;

  /// 공유 비활성화: no summary.
  final bool blocked;

  @override
  State<UnreadSummaryBar> createState() => _UnreadSummaryBarState();
}

class _UnreadSummaryBarState extends State<UnreadSummaryBar> {
  bool closed = false, open = false, busy = false, failed = false;
  String? summary;

  @override
  void initState() {
    super.initState();
    // Ask the phone once whether it has AI (cached).
    if (LocalAi.known == null) unawaited(LocalAi.status().then((_) => mounted ? setState(() {}) : null));
  }

  Future<void> make() async {
    if (open) return setState(() => open = false);
    if (!await aiAgeOk(context) || !mounted) return;
    setState(() {
      open = true;
      failed = false;
    });
    if (summary != null) return;
    final s = AppScope.read(context);
    final unread = widget.msgs.where((m) => !m.mine).toList();
    final take = unread.length > widget.unread ? unread.sublist(unread.length - widget.unread) : unread;
    final text = UnreadSummary.input(take, displayId);
    if (text.isEmpty) return setState(() => failed = true);
    setState(() => busy = true);
    final lang = (s.locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'en' ? 'English' : 'Korean';
    try {
      summary = await LocalAi.run(rules: UnreadSummary.rules(lang), text: text);
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (closed || widget.blocked || widget.unread < UnreadSummary.from || !LocalAi.onPhone) return const SizedBox.shrink();
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], 0),
      child: Container(
        key: const Key('unread-summary'),
        decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.sparkles, size: 18, color: p.accent),
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: GestureDetector(
                    key: const Key('unread-summary-open'),
                    behavior: HitTestBehavior.opaque,
                    onTap: busy ? null : make,
                    child: Text(
                      open ? l.unreadSummaryTitle : l.unreadSummaryAsk(widget.unread),
                      style: Tokens.body.style.copyWith(color: p.accent, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                GestureDetector(
                  key: const Key('unread-summary-close'),
                  onTap: () => setState(() => closed = true),
                  child: Icon(CupertinoIcons.xmark, size: 16, color: p.secondaryLabel, semanticLabel: l.close),
                ),
              ],
            ),
            if (open) ...[
              SizedBox(height: Tokens.space[1]),
              if (busy)
                const Center(child: CupertinoActivityIndicator())
              else
                Text(
                  failed ? l.unreadSummaryFailed : summary ?? '',
                  key: const Key('unread-summary-text'),
                  style: Tokens.body.style.copyWith(color: p.label),
                ),
              SizedBox(height: Tokens.space[0]),
              Text(l.unreadSummaryOnPhone, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
