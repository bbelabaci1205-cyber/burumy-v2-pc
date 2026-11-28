// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 예약 보내기 다듬기 (Telegram tip 217):
// - Hold send > 예약 보내기: an iOS wheel (day · hour · minute) and a big
//   button whose words follow the wheel live ("오늘 오후 5:41에 보내기").
// - 예약된 메시지 screen: the waiting messages drawn as my own bubbles under
//   day headers ("8월 5일에 보낼 메시지"); tap one for 지금 보내기 / 시간
//   바꾸기 / 복사 / 수정 / 삭제.
// Scheduled messages stay on this phone and go when the app is open at that
// time (or the next time it opens) — no server copy (the "send when the
// phone is off" server version is a separate, later item).
// Not built on purpose: Telegram's "접속하면 보내기" (send when online) —
// it needs the other person's online status, which Burumy hides.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'formatting.dart';
import 'glass.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'ios.dart';
import '../core/gifs.dart' show SavedGif;
import 'gif_tab.dart' show SavedGifView;
import 'ios_route.dart';
import 'wide.dart';

/// "오늘 오후 5:41에 보내기" / "내일 …" / "8월 5일 오후 …" / "2027년 1월 3일 …".
String scheduleButtonText(L l, DateTime at, DateTime now, String lang) {
  final time = DateFormat.jm(lang).format(at);
  final day = DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  final date = switch (day) {
    0 => l.today,
    1 => l.tomorrow,
    _ => at.year == now.year ? DateFormat.MMMd(lang).format(at) : DateFormat.yMMMd(lang).format(at),
  };
  return l.sendAtTime(date, time);
}

/// The wheel sheet; null = cancelled. [repeat]: '' once, day, week, month.
Future<(DateTime, String)?> pickSendTime(BuildContext context, {DateTime? initial, String repeat = ''}) => showCupertinoModalPopup<(DateTime, String)>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (c) => ScheduleSheet(initial: initial, repeat: repeat),
);

class ScheduleSheet extends StatefulWidget {
  const ScheduleSheet({super.key, this.initial, this.repeat = ''});
  final DateTime? initial;
  final String repeat;

  @override
  State<ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<ScheduleSheet> {
  final opened = DateTime.now();
  late DateTime at = widget.initial ?? opened.add(const Duration(hours: 1));
  late String repeat = widget.repeat;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    // A time already passed (wheel left alone for a while) goes right away.
    final first = DateTime(opened.year, opened.month, opened.day, opened.hour, opened.minute);
    final start = at.isBefore(first) ? first : at;
    return Container(
      key: const Key('schedule-sheet'),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[3])),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: Tokens.sheetHeader,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    l.scheduleTitle,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: CupertinoButton(key: const Key('schedule-cancel'), onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
                  ),
                ],
              ),
            ),
            // v1 반복 보내기: once, every day, week or month.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: CupertinoSlidingSegmentedControl<String>(
                key: const Key('schedule-repeat'),
                groupValue: repeat,
                children: {'': Text(l.repeatNone), 'day': Text(l.repeatDay), 'week': Text(l.repeatWeek), 'month': Text(l.repeatMonth)},
                onValueChanged: (v) => setState(() => repeat = v ?? ''),
              ),
            ),
            SizedBox(
              height: Tokens.wheelHeight,
              child: CupertinoDatePicker(
                key: const Key('schedule-picker'),
                initialDateTime: start,
                minimumDate: first,
                maximumDate: opened.add(const Duration(days: 365)),
                use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                onDateTimeChanged: (v) => setState(() => at = v),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[3]),
              child: SizedBox(
                height: 50,
                child: CupertinoButton(
                  key: const Key('schedule-ok'),
                  padding: EdgeInsets.zero,
                  color: p.accent,
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: () => Navigator.pop(context, (at.isBefore(first) ? first : at, repeat)),
                  child: Text(
                    scheduleButtonText(l, at.isBefore(first) ? first : at, DateTime.now(), lang),
                    key: const Key('schedule-ok-text'),
                    style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 예약된 메시지 in one chat, drawn like the chat (tip 217).
class ScheduledChatPage extends StatefulWidget {
  const ScheduledChatPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<ScheduledChatPage> createState() => _ScheduledChatPageState();
}

class _ScheduledChatPageState extends State<ScheduledChatPage> {
  AppState get s => AppScope.read(context);

  /// Deleted, still inside the 5 seconds to take it back.
  final hidden = <String>{};

  List<Map<String, dynamic>> get mine =>
      s.scheduled.where((m) => m['room'] == widget.roomId && !hidden.contains(m['id'])).toList()..sort((a, b) => (a['at'] as int).compareTo(b['at'] as int));

  Future<void> change(String id, Map<String, dynamic>? to) async {
    await s.setScheduled([
      for (final x in s.scheduled)
        if (x['id'] != id) x else if (to != null) to,
    ]);
    if (mounted) setState(() {});
  }

  Future<void> actions(Map<String, dynamic> m) async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          CupertinoActionSheetAction(key: const Key('sched-now'), onPressed: () => Navigator.pop(c, 'now'), child: Text(l.sendNow)),
          CupertinoActionSheetAction(key: const Key('sched-time'), onPressed: () => Navigator.pop(c, 'time'), child: Text(l.reschedule)),
          CupertinoActionSheetAction(key: const Key('sched-copy'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.copy)),
          CupertinoActionSheetAction(key: const Key('sched-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.edit)),
          CupertinoActionSheetAction(
            key: const Key('sched-delete'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(l.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    final id = m['id'] as String;
    switch (pick) {
      case 'now':
        await change(id, {...m, 'at': 0});
        await s.sendDue();
        if (mounted) setState(() {});
      case 'time':
        final got = await pickSendTime(context, initial: DateTime.fromMillisecondsSinceEpoch(m['at'] as int), repeat: m['repeat'] as String? ?? '');
        if (got == null) return;
        await change(id, {...m, 'at': got.$1.millisecondsSinceEpoch, 'repeat': got.$2}..removeWhere((k, v) => k == 'repeat' && v == ''));
      case 'copy':
        await Clipboard.setData(ClipboardData(text: plainText(m['text'] as String)));
        if (mounted) showInfoBanner(context, l.copied, '', icon: CupertinoIcons.doc_on_doc_fill);
      case 'edit':
        final t = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => ScheduledEditPage(text: m['text'] as String)));
        if (t == null || t.trim().isEmpty) return;
        await change(id, {...m, 'text': t.trim()});
      case 'delete':
        // 5 seconds to take it back (rulebook: undo on delete).
        setState(() => hidden.add(id));
        final st = s;
        showUndoCountdown(
          context,
          l.scheduledDeleted,
          () async {
            await st.setScheduled(st.scheduled.where((x) => x['id'] != id).toList());
            hidden.remove(id);
            if (mounted) setState(() {});
          },
          onUndo: () {
            if (mounted) setState(() => hidden.remove(id));
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final list = mine;
    final rows = <Widget>[];
    String? lastDay;
    for (final m in list) {
      final at = DateTime.fromMillisecondsSinceEpoch(m['at'] as int);
      final day = DateFormat.yMMMMd(lang).format(at);
      if (day != lastDay) {
        lastDay = day;
        rows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(
                  l.scheduledFor(DateFormat.MMMMd(lang).format(at)),
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        );
      }
      final repeat = m['repeat'] as String? ?? '';
      rows.add(
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            key: Key('sched-${m['id']}'),
            onTap: () => actions(m),
            onLongPress: () => actions(m),
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
              margin: EdgeInsets.only(bottom: Tokens.space[1], left: Tokens.space[5]),
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[0] + 2),
              decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.rowBubble)),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: Tokens.space[1],
                children: [
                  // 내 GIF 예약 (tip 558): the GIF, then its words.
                  if (SavedGif.fromJson(m['gif']) case final g?)
                    Padding(
                      padding: EdgeInsets.only(top: Tokens.space[0]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Tokens.radius[1]),
                        child: SizedBox(
                          width: Tokens.gifPreview,
                          height: Tokens.gifPreview * 0.75,
                          child: SavedGifView(gif: g),
                        ),
                      ),
                    ),
                  if ((m['text'] as String).isNotEmpty || m['gif'] is! Map)
                    FormattedText(
                      m['text'] as String,
                      style: Tokens.body.style.copyWith(color: p.onAccent),
                      linkColor: p.onAccent,
                      quoteColor: p.onAccent,
                      codeInset: true,
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (repeat.isNotEmpty) Icon(CupertinoIcons.repeat, size: 11, color: p.onAccent.withValues(alpha: 0.8)),
                      if (repeat.isNotEmpty) const SizedBox(width: 2),
                      Icon(CupertinoIcons.clock, size: 11, color: p.onAccent.withValues(alpha: 0.8)),
                      const SizedBox(width: 2),
                      Text(DateFormat.jm(lang).format(at), style: Tokens.bubbleMeta.style.copyWith(color: p.onAccent.withValues(alpha: 0.8))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar(title: l.scheduledTitle, back: true, tint: p.chatBackground),
      child: ListView(
        key: const Key('scheduled-list'),
        padding: EdgeInsets.fromLTRB(
          Tokens.space[2],
          MediaQuery.paddingOf(context).top + GlassTopBar.height,
          Tokens.space[2],
          MediaQuery.paddingOf(context).bottom + Tokens.space[3],
        ),
        children: [
          ...rows,
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[5]),
              child: Center(
                child: Text(l.scheduledEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
            child: Text(
              l.scheduledInfo,
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen field to change a waiting message (no pop-up text boxes).
class ScheduledEditPage extends StatefulWidget {
  const ScheduledEditPage({super.key, required this.text});
  final String text;
  @override
  State<ScheduledEditPage> createState() => _ScheduledEditPageState();
}

class _ScheduledEditPageState extends State<ScheduledEditPage> {
  late final input = ComposeController(text: widget.text);

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.edit,
        back: true,
        tint: p.background,
        trailing: [GlassPill(key: const Key('sched-edit-done'), text: l.done, onTap: () => Navigator.pop(context, input.text))],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                child: CupertinoTextField(
                  key: const Key('sched-edit-field'),
                  controller: input,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 12,
                  decoration: null,
                  contextMenuBuilder: (c, st) => formatMenu(c, st, input),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
