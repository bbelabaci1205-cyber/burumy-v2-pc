// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화방 테마 양쪽 적용 (Telegram tip 295): in a 1:1 chat the background I
// pick can go to the other phone too, as a hidden end-to-end encrypted
// note (the server never learns which theme). The newest pick wins on both
// phones. My own photo background never leaves this phone.
//
// 양쪽 같은 배경 (tips 387 + 410, 2026-11-27): any background text (one
// colour, swirling colours, icons + strength) can go, and both phones show
// a card in the chat ("새 배경을 설정했어요"); the other person can go
// back to their own background from that card.
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';
import 'looks.dart';

class RoomTheme {
  const RoomTheme._();

  static const kind = 'chat_theme';

  static String pref(String roomId) => 'chat_theme:$roomId';
  static String atPref(String roomId) => 'chat_theme_at:$roomId';
  static String byPref(String roomId) => 'chat_theme_by:$roomId';

  /// Picks a background here; with [both] it goes to the other phone too.
  /// '' = use my default.
  static Future<void> set(AppState s, String roomId, String theme, {required bool both}) async {
    final now = s.backend.clock.millisecondsSinceEpoch;
    await s.setPref(pref(roomId), theme);
    await s.setPref(atPref(roomId), '$now');
    await s.setPref(byPref(roomId), '');
    if (both && Wall.sendable(theme)) {
      await s.backend.sendSignal(roomId, kind, {'t': theme, 'at': now});
      await s.setPref(notePref(roomId), jsonEncode({'by': '', 't': theme, 'at': now}));
    }
  }

  /// The card in the chat about the last both-phones change.
  static String notePref(String roomId) => 'chat_theme_note:$roomId';

  /// A theme from the other phone: taken when it is newer than mine.
  static Future<void> onSignal(AppState s, Signal sig) async {
    final t = sig.data['t'];
    if (t is! String || !Wall.sendable(t)) return;
    final at = (sig.data['at'] as num?)?.toInt() ?? sig.time.millisecondsSinceEpoch;
    final mine = int.tryParse(s.pref(atPref(sig.roomId), '')) ?? 0;
    if (at <= mine) return;
    final prev = s.pref(byPref(sig.roomId), '').isEmpty ? s.pref(pref(sig.roomId), '') : '';
    await s.setPref(notePref(sig.roomId), jsonEncode({'by': sig.sender, 't': t, 'at': at, 'prev': prev}));
    await s.setPref(pref(sig.roomId), t);
    await s.setPref(atPref(sig.roomId), '$at');
    await s.setPref(byPref(sig.roomId), sig.sender);
  }
}
