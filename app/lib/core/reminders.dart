// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Message reminders ("알림 받기"): kept in this device's own settings and
// shown by the phone at the time. Nothing goes to the server.
import 'dart:async';
import 'dart:convert';

import 'app_state.dart';

class Reminder {
  const Reminder({required this.roomId, required this.msgId, required this.chat, required this.at});
  final String roomId;
  final String msgId;
  final String chat;
  final DateTime at;

  /// Id of the phone notification.
  int get id => Object.hash(msgId, at.millisecondsSinceEpoch) & 0x7fffffff;

  Map<String, Object> toJson() => {'room': roomId, 'msg': msgId, 'chat': chat, 'at': at.millisecondsSinceEpoch};

  static Reminder? fromJson(Object? j) {
    if (j is! Map) return null;
    final at = j['at'];
    if (j['room'] is! String || j['msg'] is! String || at is! int) return null;
    return Reminder(roomId: j['room'] as String, msgId: j['msg'] as String, chat: '${j['chat'] ?? ''}', at: DateTime.fromMillisecondsSinceEpoch(at));
  }
}

/// At most this many waiting at once.
const maxReminders = 64;

/// The four quick choices of the sheet, counted from [now].
List<DateTime> reminderChoices(DateTime now) {
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
  return [now.add(const Duration(minutes: 20)), now.add(const Duration(hours: 1)), now.add(const Duration(hours: 3)), tomorrow];
}

List<Reminder> reminders(AppState s) {
  try {
    final v = jsonDecode(s.pref('reminders', '[]'));
    if (v is! List) return [];
    return [for (final j in v) ?Reminder.fromJson(j)];
  } catch (_) {
    return [];
  }
}

Future<void> _save(AppState s, List<Reminder> list) => s.setPref('reminders', list.isEmpty ? '' : jsonEncode([for (final r in list) r.toJson()]));

/// Set by the app (phone builds): the phone shows it at the time.
Future<void> Function(Reminder r)? scheduleReminder;
Future<void> Function(Reminder r)? cancelReminder;

Future<void> addReminder(AppState s, Reminder r) async {
  final list = [...reminders(s).where((x) => x.msgId != r.msgId), r]..sort((a, b) => a.at.compareTo(b.at));
  for (final old in reminders(s).where((x) => x.msgId == r.msgId)) {
    unawaited(cancelReminder?.call(old));
  }
  await _save(s, list.length > maxReminders ? list.sublist(list.length - maxReminders) : list);
  try {
    await scheduleReminder?.call(r);
  } catch (_) {}
}

/// Reminders whose time has come; they are taken off the list.
Future<List<Reminder>> takeDueReminders(AppState s, DateTime now) async {
  final all = reminders(s);
  final due = [
    for (final r in all)
      if (!r.at.isAfter(now)) r,
  ];
  if (due.isNotEmpty)
    await _save(s, [
      for (final r in all)
        if (r.at.isAfter(now)) r,
    ]);
  return due;
}

/// Takes the reminder for this message (or plan) off, if there is one.
Future<void> removeReminder(AppState s, String msgId) async {
  final all = reminders(s);
  final gone = all.where((x) => x.msgId == msgId).toList();
  if (gone.isEmpty) return;
  for (final r in gone) {
    unawaited(cancelReminder?.call(r));
  }
  await _save(s, all.where((x) => x.msgId != msgId).toList());
}
