// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다음 안 읽은 채널 (Telegram tip 292, channel batch #15): at the end of a
// channel, pulling further up opens the next channel with unread posts,
// without going back to the chat list. Order like Telegram: the chat list
// as it stands (pinned first), then the archive.
import 'backend.dart';

ChatPreview? nextUnreadChannel(List<ChatPreview> chats, String current, {Set<String> hidden = const {}}) {
  bool fits(ChatPreview c) => c.isChannel && c.unread > 0 && c.roomId != current && !hidden.contains(c.roomId);
  return chats.where((c) => !c.archived && fits(c)).firstOrNull ?? chats.where((c) => c.archived && fits(c)).firstOrNull;
}
