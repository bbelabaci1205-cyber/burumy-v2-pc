// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 일정: the plans I made or said I'd go to, gathered from every chat,
// plus a reminder 1 hour before. Kept in this device's own settings only;
// the server never learns who is going where.
import 'dart:async';
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';
import 'reminders.dart';

class MyPlan {
  const MyPlan({required this.roomId, required this.id, required this.title, required this.start, this.end, this.place, this.answer = 'yes', this.guests = 0});
  final String roomId;
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? place;

  /// "yes", "maybe" or "mine" (I made it and haven't answered).
  final String answer;
  final int guests;

  /// Over once it has ended (or 2 hours after the start, with no end).
  bool pastAt(DateTime now) => (end ?? start.add(const Duration(hours: 2))).isBefore(now);

  Map<String, Object?> toJson() => {
    'room': roomId,
    'id': id,
    'title': title,
    'start': start.millisecondsSinceEpoch,
    if (end != null) 'end': end!.millisecondsSinceEpoch,
    if (place != null) 'place': place,
    'answer': answer,
    if (guests > 0) 'guests': guests,
  };

  static MyPlan? fromJson(Object? j) {
    if (j is! Map) return null;
    final room = j['room'], id = j['id'], title = j['title'], start = j['start'], end = j['end'];
    if (room is! String || id is! String || title is! String || start is! int) return null;
    return MyPlan(
      roomId: room,
      id: id,
      title: title,
      start: DateTime.fromMillisecondsSinceEpoch(start),
      end: end is int ? DateTime.fromMillisecondsSinceEpoch(end) : null,
      place: j['place'] is String ? j['place'] as String : null,
      answer: j['answer'] is String ? j['answer'] as String : 'yes',
      guests: j['guests'] is int ? j['guests'] as int : 0,
    );
  }
}

class MyPlans {
  static const key = 'my_plans', remindKey = 'plan_remind';

  /// At most this many kept (the oldest past ones go first).
  static const max = 200;

  static const remindBefore = Duration(hours: 1);

  /// 1시간 전에 알림 (on unless turned off).
  static bool reminds(AppState s) => s.on(remindKey, fallback: true);

  static List<MyPlan> all(AppState s) {
    try {
      final v = jsonDecode(s.pref(key, '[]'));
      if (v is! List) return [];
      return [for (final j in v) ?MyPlan.fromJson(j)]..sort((a, b) => a.start.compareTo(b.start));
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(AppState s, List<MyPlan> list) async {
    var keep = [...list]..sort((a, b) => a.start.compareTo(b.start));
    if (keep.length > max) keep = keep.sublist(keep.length - max);
    await s.setPref(key, keep.isEmpty ? '' : jsonEncode([for (final p in keep) p.toJson()]));
  }

  static MyPlan? find(AppState s, String id) => all(s).where((p) => p.id == id).firstOrNull;

  /// After I answer (or make) a plan: keep it and set the reminder, or drop
  /// both when I'm not going any more. [reminderTitle] is what the phone's
  /// notification says.
  static Future<void> update(
    AppState s, {
    required String roomId,
    required String id,
    required MeetupInfo plan,
    required String answer,
    int guests = 0,
    required String reminderTitle,
    DateTime? now,
  }) async {
    final going = !plan.cancelled && (answer == 'yes' || answer == 'maybe' || answer == 'mine');
    final rest = all(s).where((p) => p.id != id).toList();
    if (!going) {
      await _save(s, rest);
      await removeReminder(s, id);
      return;
    }
    final mine = MyPlan(roomId: roomId, id: id, title: plan.title, start: plan.startsAt, end: plan.endsAt, place: plan.place, answer: answer, guests: guests);
    await _save(s, [...rest, mine]);
    final at = plan.startsAt.subtract(remindBefore);
    if (reminds(s) && at.isAfter(now ?? DateTime.now())) {
      await addReminder(s, Reminder(roomId: roomId, msgId: id, chat: reminderTitle, at: at));
    } else {
      await removeReminder(s, id);
    }
  }

  /// The plan was cancelled by its maker: off my list, no reminder.
  static Future<void> drop(AppState s, String id) async {
    final list = all(s);
    if (list.any((p) => p.id == id)) await _save(s, list.where((p) => p.id != id).toList());
    await removeReminder(s, id);
  }

  /// The reminder switch: on puts back reminders for every coming plan.
  static Future<void> setReminds(AppState s, bool on, String Function(String title) reminderTitle, {DateTime? now}) async {
    await s.setOn(remindKey, on);
    final t = now ?? DateTime.now();
    for (final p in all(s)) {
      final at = p.start.subtract(remindBefore);
      if (on && at.isAfter(t)) {
        await addReminder(s, Reminder(roomId: p.roomId, msgId: p.id, chat: reminderTitle(p.title), at: at));
      } else {
        await removeReminder(s, p.id);
      }
    }
  }
}
