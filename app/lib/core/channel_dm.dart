// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널 관리자에게 메시지 / 문의함 (Telegram tip 526, v1 parity; channel
// batch #15). A subscriber taps 💬 under a channel whose admins turned on
// 구독자 메시지 받기 (room config subscriber_dm). Each subscriber gets one
// ordinary end-to-end encrypted room with the channel's owner and admins;
// its room config says which channel it belongs to (channel_dm) and who
// the subscriber is (subscriber). Admins see all of a channel's rooms as
// one "메시지" row in their chat list (channel_inbox.dart).
// The server learns only that this person and the admins share a room
// (like any chat); the words stay encrypted. No paid messages (Plus later).
//
// Shape other features build on (batch #17 글 제안): in a chat page,
// ChannelDm.channelOf(cfg) != null means "this is a channel message room";
// the admin side is myRole owner/admin, the subscriber side is my user id
// == ChannelDm.subscriberOf(cfg).
import 'dart:async';

import 'app_state.dart';
import 'backend.dart';

class ChannelDm {
  const ChannelDm._();

  /// Chat list row standing for one channel's message rooms.
  static const rowPrefix = 'dminbox:';

  static String? channelOf(Map<String, dynamic> cfg) => cfg['channel_dm'] is String ? cfg['channel_dm'] as String : null;
  static String? subscriberOf(Map<String, dynamic> cfg) => cfg['subscriber'] is String ? cfg['subscriber'] as String : null;

  /// The channel lets subscribers write to its admins.
  static bool isOn(Map<String, dynamic> channelCfg) => channelCfg['subscriber_dm'] == true;

  /// Message rooms I know of: room -> (channel, subscriber). Filled from
  /// each room's settings on this phone (no server round trip).
  static final known = <String, (String, String)>{};
  static final _notDm = <String>{};

  /// Forget what was read (tests; another account).
  static void reset() {
    known.clear();
    _notDm.clear();
  }

  /// Room I opened for each channel as a subscriber (this phone).
  static String _myRoomKey(String channel) => 'channel_dm:$channel';

  /// Reads the settings of group rooms not looked at yet.
  static Future<void> scan(AppState s) async {
    for (final c in s.chats) {
      if (c.isDirect || c.isChannel || known.containsKey(c.roomId) || _notDm.contains(c.roomId)) continue;
      final cfg = await s.backend.roomConfig(c.roomId).catchError((_) => <String, dynamic>{});
      final ch = channelOf(cfg), sub = subscriberOf(cfg);
      if (ch != null && sub != null) {
        known[c.roomId] = (ch, sub);
      } else {
        _notDm.add(c.roomId);
      }
    }
  }

  /// Admin side: message rooms per channel (newest first), the ones where
  /// I'm not the subscriber and still run the channel.
  static Map<String, List<ChatPreview>> inboxes(AppState s) {
    final me = s.backend.userId;
    final out = <String, List<ChatPreview>>{};
    for (final c in s.chats) {
      final k = known[c.roomId];
      if (k == null || k.$2 == me) continue;
      out.putIfAbsent(k.$1, () => []).add(c);
    }
    for (final l in out.values) {
      l.sort((a, b) => (b.last?.time ?? DateTime(2000)).compareTo(a.last?.time ?? DateTime(2000)));
    }
    return out;
  }

  /// The chat list with each channel's message rooms folded into one row.
  static List<ChatPreview> fold(AppState s, List<ChatPreview> chats) {
    final boxes = inboxes(s);
    if (boxes.isEmpty) return chats;
    final inBox = {
      for (final l in boxes.values)
        for (final c in l) c.roomId,
    };
    final out = <ChatPreview>[];
    final placed = <String>{};
    for (final c in chats) {
      if (!inBox.contains(c.roomId)) {
        out.add(c);
        continue;
      }
      final ch = known[c.roomId]!.$1;
      if (!placed.add(ch)) continue;
      final rooms = boxes[ch]!;
      final channel = s.chats.where((x) => x.roomId == ch).firstOrNull;
      out.add(
        ChatPreview(
          roomId: '$rowPrefix$ch',
          name: channel?.name ?? rooms.first.name,
          isDirect: false,
          encrypted: true,
          unread: rooms.fold(0, (a, x) => a + x.unread),
          last: rooms.first.last,
          isChannel: true,
        ),
      );
    }
    return out;
  }

  /// Subscriber side: my message room for this channel, made the first
  /// time (with the channel's owner and admins in it).
  static Future<String> open(AppState s, String channel, String channelName) async {
    final b = s.backend;
    final saved = s.pref(_myRoomKey(channel), '');
    if (saved.isNotEmpty && s.chats.any((c) => c.roomId == saved)) return saved;
    final me = b.userId ?? '';
    // An earlier room (other phone of mine) is found by its settings.
    await scan(s);
    for (final e in known.entries) {
      if (e.value.$1 == channel && e.value.$2 == me) {
        await s.setPref(_myRoomKey(channel), e.key);
        return e.key;
      }
    }
    final admins = [
      for (final m in await b.members(channel).catchError((_) => const <Member>[]))
        if ((m.role == 'owner' || m.role == 'admin') && m.userId != me) m.userId,
    ];
    final owner = s.chats.where((c) => c.roomId == channel).firstOrNull?.peer ?? '';
    if (owner.isNotEmpty && !admins.contains(owner) && owner != me) admins.insert(0, owner);
    if (admins.isEmpty) throw StateError('no admins');
    final room = await b.createGroup(channelName, admins);
    await b.setRoomConfig(room, 'channel_dm', channel);
    await b.setRoomConfig(room, 'subscriber', me);
    for (final a in admins) {
      unawaited(b.setAdmin(room, a, true).catchError((_) {}));
    }
    known[room] = (channel, me);
    await s.setPref(_myRoomKey(channel), room);
    return room;
  }

  /// Admin side, for each group invitation: if it is named like a channel I
  /// run, join it and keep it only when its settings say it is a message
  /// room of that channel from the person who invited me (and the channel
  /// still takes messages); otherwise leave at once. Returns true when the
  /// invitation was dealt with here.
  static Future<bool> takeInvite(AppState s, Invite i) async {
    if (i.direct) return false;
    final b = s.backend;
    final mine = [
      for (final c in s.chats)
        if (c.isChannel && c.name == i.name) c,
    ];
    if (mine.isEmpty) return false;
    String? channel;
    for (final c in mine) {
      final role = await b.myRole(c.roomId).catchError((_) => 'member');
      if (role == 'owner' || role == 'admin') channel = c.roomId;
    }
    if (channel == null) return false;
    await b.join(i.roomId);
    final cfg = await b.roomConfig(i.roomId).catchError((_) => <String, dynamic>{});
    final chCfg = await b.roomConfig(channel).catchError((_) => <String, dynamic>{});
    final ok = channelOf(cfg) == channel && subscriberOf(cfg) == i.inviter && isOn(chCfg);
    if (!ok) {
      await b.leave(i.roomId).catchError((_) {});
      return true;
    }
    known[i.roomId] = (channel, i.inviter);
    return true;
  }
}
