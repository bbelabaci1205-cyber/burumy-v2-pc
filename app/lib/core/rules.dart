// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Small rules the phone applies itself: who may reach me, and which
// notifications to show. Settings live in my own account settings; nothing
// here is sent anywhere.
import 'backend.dart';

/// Who may do something to me ("everyone", "contacts" or "nobody"), with
/// per-person exceptions kept as comma lists in `<key>_allow` / `<key>_deny`.
bool allowedFrom(Map<String, String> prefs, String key, String userId, Set<String> contacts, {String fallback = 'everyone'}) {
  List<String> list(String k) => (prefs[k] ?? '').split(',').where((s) => s.isNotEmpty).toList();
  if (list('${key}_deny').contains(userId)) return false;
  if (list('${key}_allow').contains(userId)) return true;
  return switch (prefs[key] ?? fallback) {
    'nobody' => false,
    'contacts' => contacts.contains(userId),
    _ => true,
  };
}

/// Minutes since midnight from "HH:MM".
int minutesOf(String hhmm, int fallback) {
  final p = hhmm.split(':');
  if (p.length != 2) return fallback;
  final h = int.tryParse(p[0]), m = int.tryParse(p[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) return fallback;
  return h * 60 + m;
}

/// Focus hours: on, between `focus_from` and `focus_to` (may cross
/// midnight), on the weekdays in `focus_days` ("1".."7", Monday = 1).
bool inFocus(Map<String, String> prefs, DateTime now) {
  if (prefs['focus_on'] != '1') return false;
  final days = prefs['focus_days'] ?? '1234567';
  final from = minutesOf(prefs['focus_from'] ?? '', 22 * 60);
  final to = minutesOf(prefs['focus_to'] ?? '', 7 * 60);
  final t = now.hour * 60 + now.minute;
  if (from == to) return days.contains('${now.weekday}');
  if (from < to) return days.contains('${now.weekday}') && t >= from && t < to;
  // Crosses midnight: the early part belongs to the day before.
  if (t >= from) return days.contains('${now.weekday}');
  if (t < to) return days.contains('${now.subtract(const Duration(days: 1)).weekday}');
  return false;
}

/// Whether a phone notification for [n] should be shown.
bool noticeAllowed(Notice n, Map<String, String> prefs, ChatPreview? chat, DateTime now) {
  if (chat != null) {
    if (chat.muted) return false;
    if (prefs['list_hidden:${chat.roomId}'] == '1') return false;
    final kind = chat.isDirect ? 'notify_direct' : (chat.isChannel ? 'notify_channel' : 'notify_group');
    if (prefs[kind] == '0') return false;
    if (prefs['$kind:${chat.roomId}'] == '0') return false;
  }
  if (inFocus(prefs, now)) return false;
  return true;
}
