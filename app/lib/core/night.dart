// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 야간 모드 (Telegram tips 64 + 180): off / on / follow the phone / by time.
// "By time" turns dark between two times I pick (default 22:00–07:00);
// the times are kept on this phone only.
import 'package:flutter/widgets.dart' show Brightness;

import 'app_state.dart';

class Night {
  const Night._();

  /// 'system' (default), 'dark', 'light' or 'schedule'.
  static const key = 'night';
  static const fromKey = 'night_from';
  static const toKey = 'night_to';

  /// Minutes after midnight.
  static const defaultFrom = 22 * 60;
  static const defaultTo = 7 * 60;

  static String mode(AppState s) => s.pref(key, 'system');
  static int from(AppState s) => int.tryParse(s.pref(fromKey, '')) ?? defaultFrom;
  static int to(AppState s) => int.tryParse(s.pref(toKey, '')) ?? defaultTo;

  /// True when [now] falls between [from] and [to] (it may cross midnight).
  static bool inWindow(int from, int to, DateTime now) {
    if (from == to) return false;
    final m = now.hour * 60 + now.minute;
    return from < to ? (m >= from && m < to) : (m >= from || m < to);
  }

  static Brightness brightness(AppState s, Brightness system, DateTime now) => switch (mode(s)) {
    'dark' => Brightness.dark,
    'light' => Brightness.light,
    'schedule' => inWindow(from(s), to(s), now) ? Brightness.dark : Brightness.light,
    _ => system,
  };

  /// "22:00" style label for minutes after midnight.
  static String clock(int minutes) => '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';
}
