// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 날짜 고르기 (Telegram tip 559, iOS 27 inline calendar): a month grid with
// ‹ › to turn months, a "시간" row whose time opens a wheel under it, and a
// big accent button. Used by 서식 > 날짜 in the message field.
//
// Sizes (iOS 27 inline UIDatePicker): month title 17 semi + chevron, day
// cells 40 high with a 36 circle on the picked day (accent fill, white
// number) and today's number in accent, weekday letters 13 secondary.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/calendar_event.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'ios.dart';
import 'wide.dart';

/// Opens the sheet; null = cancelled.
Future<DateTime?> pickDateTime(BuildContext context, {DateTime? initial, String? button}) {
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (c) => DatePickSheet(initial: initial ?? nextWholeHour(DateTime.now()), button: button ?? L.of(context).dateMarkAdd),
  );
}

/// The next o'clock (14:20 → 15:00).
DateTime nextWholeHour(DateTime now) => DateTime(now.year, now.month, now.day, now.hour + 1);

class DatePickSheet extends StatefulWidget {
  const DatePickSheet({super.key, required this.initial, required this.button});
  final DateTime initial;
  final String button;

  @override
  State<DatePickSheet> createState() => _DatePickSheetState();
}

class _DatePickSheetState extends State<DatePickSheet> {
  late DateTime picked = widget.initial;
  late DateTime month = DateTime(widget.initial.year, widget.initial.month);
  bool wheel = false;

  static const cell = 40.0, dot = 36.0;

  void turn(int by) => setState(() => month = DateTime(month.year, month.month + by));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final symbols = DateFormat('', lang).dateSymbols;
    // Week starts as the language says (Korean / English: Sunday).
    final first = (symbols.FIRSTDAYOFWEEK + 1) % 7; // 0 = Sunday
    final lead = (DateTime(month.year, month.month).weekday % 7 - first + 7) % 7;
    final days = DateUtils.daysIn(month.year, month.month);
    final today = DateTime.now();
    final names = [for (var i = 0; i < 7; i++) symbols.NARROWWEEKDAYS[(first + i) % 7]];
    Widget day(int d) {
      final date = DateTime(month.year, month.month, d);
      final on = date.year == picked.year && date.month == picked.month && date.day == picked.day;
      final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
      return GestureDetector(
        key: Key('date-day-$d'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => picked = DateTime(month.year, month.month, d, picked.hour, picked.minute)),
        child: Center(
          child: Container(
            width: dot,
            height: dot,
            alignment: Alignment.center,
            decoration: on ? BoxDecoration(color: p.accent, shape: BoxShape.circle) : null,
            child: Text(
              '$d',
              style: Tokens.body.style.copyWith(color: on ? p.onAccent : (isToday ? p.accent : p.label), fontWeight: on || isToday ? Tokens.semi : null),
            ),
          ),
        ),
      );
    }

    final cells = <Widget>[for (var i = 0; i < lead; i++) const SizedBox.shrink(), for (var d = 1; d <= days; d++) day(d)];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }
    final time = DateFormat.jm(lang).format(picked);
    return Container(
      key: const Key('date-pick'),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[3])),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[3]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.yMMMM(lang).format(month),
                      key: const Key('date-month'),
                      style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                    ),
                  ),
                  CupertinoButton(
                    key: const Key('date-prev'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => turn(-1),
                    child: Icon(CupertinoIcons.chevron_left, color: p.accent, size: Tokens.listIcon),
                  ),
                  CupertinoButton(
                    key: const Key('date-next'),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => turn(1),
                    child: Icon(CupertinoIcons.chevron_right, color: p.accent, size: Tokens.listIcon),
                  ),
                ],
              ),
              SizedBox(height: Tokens.space[0]),
              Row(
                children: [
                  for (final n in names)
                    Expanded(
                      child: Text(
                        n,
                        textAlign: TextAlign.center,
                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: Tokens.semi),
                      ),
                    ),
                ],
              ),
              SizedBox(height: Tokens.space[0]),
              for (var r = 0; r < cells.length; r += 7)
                SizedBox(
                  height: cell,
                  child: Row(children: [for (final c in cells.sublist(r, r + 7)) Expanded(child: c)]),
                ),
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                color: p.separator,
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(l.dateMarkTime, style: Tokens.body.style.copyWith(color: p.label)),
                  ),
                  GestureDetector(
                    key: const Key('date-time'),
                    onTap: () => setState(() => wheel = !wheel),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                      decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[0] + 2)),
                      child: Text(time, style: Tokens.body.style.copyWith(color: wheel ? p.accent : p.label)),
                    ),
                  ),
                ],
              ),
              if (wheel)
                SizedBox(
                  height: Tokens.wheelHeight * 0.8,
                  child: CupertinoDatePicker(
                    key: const Key('date-wheel'),
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: picked,
                    onDateTimeChanged: (d) => setState(() => picked = DateTime(picked.year, picked.month, picked.day, d.hour, d.minute)),
                  ),
                ),
              SizedBox(height: Tokens.space[3]),
              SizedBox(
                height: 50,
                child: CupertinoButton(
                  key: const Key('date-ok'),
                  padding: EdgeInsets.zero,
                  color: p.accent,
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: () => Navigator.pop(context, picked),
                  child: Text(
                    widget.button,
                    style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DateUtils without Material.
class DateUtils {
  static int daysIn(int year, int month) => DateTime(year, month + 1, 0).day;
}

/// Tap on a date in a message (tip 559): the moment in MY time zone, with
/// 날짜 복사 / 캘린더에 추가 / 알림 설정 (reminder only for a time still ahead).
Future<void> openDateSheet(BuildContext context, DateTime at, String title, {ValueChanged<DateTime>? onRemind}) async {
  final l = L.of(context);
  final lang = Localizations.localeOf(context).toLanguageTag();
  final shown = dateMarkLabel(at, lang);
  final zone = at.timeZoneName;
  final pick = await showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(shown, key: const Key('date-shown')),
      message: zone.isEmpty ? null : Text(l.dateInMyZone(zone)),
      actions: [
        CupertinoActionSheetAction(key: const Key('date-copy'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.dateCopy)),
        CupertinoActionSheetAction(key: const Key('date-calendar'), onPressed: () => Navigator.pop(c, 'calendar'), child: Text(l.dateToCalendar)),
        if (onRemind != null && at.isAfter(DateTime.now()))
          CupertinoActionSheetAction(key: const Key('date-remind'), onPressed: () => Navigator.pop(c, 'remind'), child: Text(l.dateRemind)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  switch (pick) {
    case 'copy':
      await Clipboard.setData(ClipboardData(text: shown));
      if (context.mounted) showInfoBanner(context, l.dateCopied, '', icon: CupertinoIcons.doc_on_doc_fill);
    case 'calendar':
      final ok = await CalendarEvent(title: title, start: at, end: at.add(const Duration(hours: 1))).add();
      if (!ok && context.mounted) showInfoBanner(context, l.dateCalendarFailed, '', icon: CupertinoIcons.exclamationmark_circle_fill);
    case 'remind':
      onRemind!(at);
  }
}

/// The full moment in the reader's language, e.g. "Sat, Feb 28, 2026 10:00 AM".
String dateMarkLabel(DateTime at, String lang) => '${DateFormat.yMMMEd(lang).format(at)} ${DateFormat.jm(lang).format(at)}';
