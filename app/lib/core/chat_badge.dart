// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The number on the 대화 tab and the app icon (Telegram tip 185). The
// phone counts it itself: the server never learns which chats are
// channels or muted.
import 'backend.dart';

/// Settings > 알림 > 배지 숫자: switches ("1"/"0").
const badgeChannelsPref = 'badge_channels', badgeMutedPref = 'badge_muted', badgeMessagesPref = 'badge_messages';

/// Unread messages (or chats with unread, when counting chats) in the
/// list. Archived and list-hidden chats never count.
int badgeCount(List<ChatPreview> chats, Map<String, String> prefs) {
  final channels = prefs[badgeChannelsPref] != '0';
  final muted = prefs[badgeMutedPref] == '1';
  final messages = prefs[badgeMessagesPref] != '0';
  var n = 0;
  for (final c in chats) {
    if (c.unread <= 0 || c.archived || prefs['list_hidden:${c.roomId}'] == '1') continue;
    if (c.isChannel && !channels) continue;
    if (c.muted && !muted) continue;
    n += messages ? c.unread : 1;
  }
  return n;
}
