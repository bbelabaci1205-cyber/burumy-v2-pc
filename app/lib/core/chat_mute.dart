// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat alerts off for a while, or only the sound off (all on this phone).
// "Muted" itself lives in the engine; the end time and the sound-only
// switch are on-device settings, so nothing about them reaches the server.

/// When a timed mute ends (ms since epoch). Missing = forever.
String muteUntilKey(String roomId) => 'mute_until:$roomId';

/// Alerts still come, without a sound ("소리 끄기").
String quietKey(String roomId) => 'quiet:$roomId';

/// The choices in the mute menu, shortest first (Telegram iOS order).
const muteChoices = [Duration(hours: 1), Duration(hours: 8), Duration(days: 1), Duration(days: 7)];

/// The end of a timed mute, or null (no end set).
DateTime? muteEnd(Map<String, String> prefs, String roomId) {
  final v = int.tryParse(prefs[muteUntilKey(roomId)] ?? '');
  return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
}

/// Chats whose mute time is over by [now].
List<String> expiredMutes(Map<String, String> prefs, DateTime now) => [
  for (final e in prefs.entries)
    if (e.key.startsWith('mute_until:') && (int.tryParse(e.value) ?? 0) <= now.millisecondsSinceEpoch) e.key.substring('mute_until:'.length),
];
