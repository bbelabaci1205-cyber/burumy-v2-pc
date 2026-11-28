// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 동영상 이어보기 (Telegram tip 509, Eric 2026-11-27 "내 폰에만 저장"): where
// I stopped in each long video, kept in this phone's encrypted settings
// store only (never sent, not even to my other devices). Rules:
// - only videos longer than a minute,
// - stopping in the last 5 seconds counts as "watched" and forgets it,
// - view-once videos are never remembered,
// - at most [cap] videos; the oldest is dropped.
import 'dart:convert';

import 'app_state.dart';

class VideoResume {
  const VideoResume._();

  static const pref = 'video_pos';
  static const minLength = Duration(minutes: 1);
  static const endSlack = Duration(seconds: 5);
  static const cap = 200;

  /// The key for a chat video.
  static String keyFor(String roomId, String eventId) => '$roomId|$eventId';

  static Map<String, List<int>> _all(AppState s) {
    try {
      final m = jsonDecode(s.pref(pref, '{}')) as Map<String, dynamic>;
      return {
        for (final e in m.entries) e.key: [for (final x in e.value as List) (x as num).toInt()],
      };
    } catch (_) {
      return {};
    }
  }

  /// Where to start, or null (start from the beginning).
  static Duration? at(AppState s, String key) {
    final v = _all(s)[key];
    return v == null ? null : Duration(milliseconds: v[0]);
  }

  /// How much was watched, 0..1, for the thin bar under the bubble; null
  /// when nothing is remembered.
  static double? watched(AppState s, String key) {
    final v = _all(s)[key];
    if (v == null || v[1] <= 0) return null;
    return (v[0] / v[1]).clamp(0.0, 1.0);
  }

  /// Saves (or forgets) the place for [key] when the player closes.
  static Future<void> save(AppState s, String key, Duration pos, Duration total) async {
    final all = _all(s);
    final keep = total >= minLength && pos > const Duration(seconds: 2) && pos < total - endSlack;
    if (!keep) {
      if (all.remove(key) == null) return;
    } else {
      all.remove(key);
      all[key] = [pos.inMilliseconds, total.inMilliseconds, DateTime.now().millisecondsSinceEpoch];
      while (all.length > cap) {
        all.remove(all.keys.first);
      }
    }
    await s.setPref(pref, all.isEmpty ? '' : jsonEncode(all));
  }
}
