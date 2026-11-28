// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 로그인·기기 안전 (Telegram tips 398, 311, 343, 356, 247, 308), behind
// [Features.loginSafety]. Everything here runs on my own phone: the server
// learns nothing new (no location, no list of who I talk to).
//
// - 새 로그인 경고: a device I haven't seen before shows a card on top of the
//   chat list ("본인인가요?"). "아니요" logs that device out (password check).
// - 모르는 사람 자동 보관: a first 1:1 message from someone who isn't my
//   friend goes to 보관함, muted.
// - 음성·영상 메시지 받을 사람: my rule travels to each 1:1 friend as a hidden
//   end-to-end encrypted note, so their app dims the mic button; my app also
//   hides voice/round-video messages that still come from people I don't allow.
// - 통화 기록 / 날짜로 지우기 "상대에게서도": a hidden encrypted note asks the
//   other phone to remove the same calls / days; each phone deletes what it
//   sent itself.
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';
import 'features.dart';
import 'rules.dart';

class LoginSafety {
  const LoginSafety._();

  // ---------------------------------------------------------------- 398
  /// Device ids I already know (this phone only).
  static const knownKey = 'known_devices';

  /// How often the device list is asked for while the app is open.
  static const every = Duration(minutes: 1);

  /// Compares my devices with the ones I know. The first look only learns
  /// them (no card for devices that were there before the update).
  static Future<List<DeviceRow>> newDevices(AppState s, List<DeviceRow> all) async {
    final known = s.pref(knownKey, '').split(',').where((x) => x.isNotEmpty).toSet();
    final now = {for (final d in all) d.id};
    if (known.isEmpty) {
      await s.setPref(knownKey, now.join(','));
      return const [];
    }
    final fresh = [
      for (final d in all)
        if (!d.thisDevice && !known.contains(d.id)) d,
    ];
    // Devices that are gone leave the list (they come back as new).
    final kept = known.intersection(now);
    if (kept.length != known.length) await s.setPref(knownKey, kept.join(','));
    return fresh;
  }

  /// "네, 저예요": that device is known from now on.
  static Future<void> confirm(AppState s, String deviceId) async {
    final known = s.pref(knownKey, '').split(',').where((x) => x.isNotEmpty).toSet()..add(deviceId);
    await s.setPref(knownKey, known.join(','));
  }

  // ---------------------------------------------------------------- 311
  /// 오래 안 쓴 기기 자동 로그아웃: days (0 = off). Our server reads it from my
  /// account settings and logs such devices out itself.
  static const idleDaysKey = 'device_idle_days';
  static const idleChoices = [7, 30, 90, 180, 365];

  /// Devices on this phone that don't ring for calls ("이 기기로 통화 받기"
  /// off). Kept in my account settings so any of my devices can change it.
  static const noCallsKey = 'no_call_devices';

  static bool callsOff(Map<String, dynamic> privacy, String deviceId) {
    final v = privacy[noCallsKey];
    return v is List && v.contains(deviceId);
  }

  /// Turns calls on or off for one of my devices (any of my devices may).
  static Future<Map<String, dynamic>> setCalls(AppState s, String deviceId, bool on) async {
    final now = await s.backend.accountPrivacy();
    final list = [
      for (final x in (now[noCallsKey] is List ? now[noCallsKey] as List : const []))
        if (x is String && x != deviceId) x,
    ];
    if (!on) list.add(deviceId);
    await s.backend.setAccountPrivacy(noCallsKey, list.isEmpty ? null : list);
    final next = {...now, noCallsKey: list.isEmpty ? null : list}..removeWhere((_, v) => v == null);
    s.accountPrivacy = next;
    return next;
  }

  /// 오래 안 쓴 기기 자동 로그아웃: 0 = off.
  static int idleDays(Map<String, dynamic> privacy) => (privacy[idleDaysKey] as num?)?.toInt() ?? 0;

  static Future<void> setIdleDays(AppState s, int days) async {
    await s.backend.setAccountPrivacy(idleDaysKey, days <= 0 ? null : days);
    s.accountPrivacy = {...s.accountPrivacy, idleDaysKey: days <= 0 ? null : days}..removeWhere((_, v) => v == null);
  }

  // ---------------------------------------------------------------- 343
  /// 모르는 사람 새 대화 자동 보관 (on by default in Telegram; off here
  /// until I switch it on, like Telegram's own default).
  static const strangerArchiveKey = 'stranger_archive';

  /// A 1:1 chat that just opened: archive and mute it when it's from a
  /// stranger and the switch is on. True when it was tucked away.
  static Future<bool> tuckStranger(AppState s, Invite i, Set<String> friends) async {
    if (!Features.loginSafety || !i.direct || !s.on(strangerArchiveKey)) return false;
    if (friends.contains(i.inviter)) return false;
    // 메시지 요청 already keeps it out of my list; archiving too would leave
    // an accepted chat hidden and muted.
    if (s.isRequest(i.roomId)) return false;
    await s.backend.setChatArchived(i.roomId, true);
    await s.backend.setChatMuted(i.roomId, true);
    await s.setPref('stranger_tucked:${i.roomId}', '1');
    return true;
  }

  // ---------------------------------------------------------------- 356
  /// Who may send me voice and round-video messages (1:1 chats).
  static const voiceKey = 'who_voice';
  static const voiceSignal = 'voice_rule';

  /// What I tell [peer] about my rule: may they send me voice?
  static bool voiceAllowedFor(AppState s, String peer, Set<String> friends) => allowedFrom(s.settings, voiceKey, peer, friends);

  /// Sends my answer to every 1:1 friend whose last answer differs.
  static Future<void> tellVoiceRule(AppState s, {bool force = false}) async {
    if (!Features.loginSafety) return;
    final friends = s.friendIds;
    for (final c in s.chats) {
      if (!c.isDirect || c.isBot || c.peer.isEmpty) continue;
      final ok = voiceAllowedFor(s, c.peer, friends);
      final told = s.pref('voice_told:${c.roomId}', '');
      if (!force && told == (ok ? '1' : '0')) continue;
      // Nothing was ever said and everyone may: no note needed.
      if (!force && told.isEmpty && ok) continue;
      try {
        await s.backend.sendSignal(c.roomId, voiceSignal, {'ok': ok});
        await s.setPref('voice_told:${c.roomId}', ok ? '1' : '0');
      } catch (_) {}
    }
  }

  /// Their rule for me arrived (newest wins).
  static Future<void> onVoiceSignal(AppState s, Signal sig) async {
    final ok = sig.data['ok'];
    if (ok is! bool) return;
    await s.setPref('voice_ok:${sig.roomId}', ok ? '1' : '0');
  }

  /// May I send voice / round video in this 1:1 chat?
  static bool canSendVoice(AppState s, ChatPreview? c) => !Features.loginSafety || c == null || !c.isDirect || s.pref('voice_ok:${c.roomId}', '1') == '1';

  /// A voice / round-video message from someone I don't allow: shown as a
  /// short line instead (a changed app could still send one).
  static bool hideVoice(AppState s, ChatPreview? c, Msg m) {
    if (!Features.loginSafety || c == null || !c.isDirect || m.mine) return false;
    final round = m.kind == 'video' && !m.viewOnce && (m.body ?? '').startsWith('videonote');
    if (m.kind != 'audio' && !round) return false;
    return !voiceAllowedFor(s, m.sender, s.friendIds);
  }

  // ---------------------------------------------------------------- 247
  /// Calls I removed from my list (this phone): call ids.
  static const callsHiddenKey = 'calls_hidden';
  static const callsSignal = 'calls_forget';

  static Set<String> hiddenCalls(AppState s) => s.pref(callsHiddenKey, '').split(',').where((x) => x.isNotEmpty).toSet();

  /// Removes calls from my list; with [both] the other phone removes them
  /// too. Each phone deletes the ring it sent itself (gone from the server).
  static Future<void> forgetCalls(AppState s, List<CallLogItem> calls, {required bool both}) async {
    final hidden = hiddenCalls(s)..addAll(calls.map((c) => c.call.id));
    // Keep the list short: the newest 2000 are plenty.
    final list = hidden.toList();
    await s.setPref(callsHiddenKey, list.skip(list.length > 2000 ? list.length - 2000 : 0).join(','));
    for (final c in calls) {
      if (c.mine) await _deleteRing(s, c.roomId, c.call.id);
    }
    if (!both) return;
    final byRoom = <String, List<String>>{};
    for (final c in calls) {
      byRoom.putIfAbsent(c.roomId, () => []).add(c.call.id);
    }
    for (final e in byRoom.entries) {
      final chat = s.chats.where((c) => c.roomId == e.key).firstOrNull;
      if (chat == null || !chat.isDirect) continue;
      try {
        await s.backend.sendSignal(e.key, callsSignal, {'ids': e.value.take(200).toList()});
      } catch (_) {}
    }
  }

  static Future<void> _deleteRing(AppState s, String roomId, String callId) async {
    try {
      final msgs = await s.backend.timeline(roomId, limit: 400);
      final m = msgs.where((m) => m.mine && m.call?.id == callId).firstOrNull;
      if (m != null) await s.backend.deleteMessage(roomId, m.id);
    } catch (_) {}
  }

  /// The other phone removed calls for both of us.
  static Future<void> onCallsSignal(AppState s, Signal sig) async {
    final ids = sig.data['ids'];
    if (ids is! List) return;
    final chat = s.chats.where((c) => c.roomId == sig.roomId).firstOrNull;
    if (chat == null || !chat.isDirect) return;
    final mine = <CallLogItem>[];
    try {
      for (final c in await s.backend.callLog(max: 1000)) {
        if (c.roomId == sig.roomId && ids.contains(c.call.id)) mine.add(c);
      }
    } catch (_) {}
    final hidden = hiddenCalls(s)
      ..addAll([
        for (final x in ids.take(200))
          if (x is String && x.length < 200) x,
      ]);
    await s.setPref(callsHiddenKey, hidden.join(','));
    for (final c in mine) {
      if (c.mine) await _deleteRing(s, c.roomId, c.call.id);
    }
  }

  // ---------------------------------------------------------------- 308
  static const daysSignal = 'days_forget';

  /// Messages sent from [from] (inclusive) until [to] (exclusive).
  static bool inRange(Msg m, DateTime from, DateTime to) => !m.time.isBefore(from) && m.time.isBefore(to);

  /// The messages of a chat between two days (both days included).
  static (DateTime, DateTime) span(DateTime a, DateTime b) {
    final first = a.isBefore(b) ? a : b, last = a.isBefore(b) ? b : a;
    return (DateTime(first.year, first.month, first.day), DateTime(last.year, last.month, last.day + 1));
  }

  /// Wipes my messages in the range from the server, hides everyone else's
  /// here; with [both] (1:1 only) the other phone does the same.
  static Future<int> forgetDays(AppState s, String roomId, DateTime from, DateTime to, {required bool both}) async {
    final n = await _forgetRange(s, roomId, from, to);
    if (both) {
      try {
        await s.backend.sendSignal(roomId, daysSignal, {'from': from.millisecondsSinceEpoch, 'to': to.millisecondsSinceEpoch});
      } catch (_) {}
    }
    return n;
  }

  /// Hidden-by-date ranges of a chat on this phone: [[from, to], ...] (ms).
  static List<(int, int)> hiddenRanges(AppState s, String roomId) {
    final raw = s.pref('days_hidden:$roomId', '');
    if (raw.isEmpty) return const [];
    try {
      final v = jsonDecode(raw) as List;
      return [
        for (final r in v)
          if (r is List && r.length == 2) ((r[0] as num).toInt(), (r[1] as num).toInt()),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Is this message inside a range I wiped by date?
  static bool hiddenByDate(AppState s, String roomId, Msg m) => inRanges(hiddenRanges(s, roomId), m);

  static bool inRanges(List<(int, int)> ranges, Msg m) {
    final t = m.time.millisecondsSinceEpoch;
    return ranges.any((r) => t >= r.$1 && t < r.$2);
  }

  static Future<int> _forgetRange(AppState s, String roomId, DateTime from, DateTime to) async {
    final ranges = [...hiddenRanges(s, roomId), (from.millisecondsSinceEpoch, to.millisecondsSinceEpoch)];
    await s.setPref(
      'days_hidden:$roomId',
      jsonEncode([
        for (final r in ranges.length > 50 ? ranges.sublist(ranges.length - 50) : ranges) [r.$1, r.$2],
      ]),
    );
    var n = 0;
    try {
      final msgs = await s.backend.timeline(roomId, limit: 5000);
      for (final m in msgs) {
        if (!inRange(m, from, to)) continue;
        n++;
        if (m.mine) {
          try {
            await s.backend.deleteMessage(roomId, m.id);
          } catch (_) {}
        }
      }
    } catch (_) {}
    return n;
  }

  /// The other phone wiped days of our 1:1 chat for both of us.
  static Future<void> onDaysSignal(AppState s, Signal sig) async {
    final from = (sig.data['from'] as num?)?.toInt(), to = (sig.data['to'] as num?)?.toInt();
    if (from == null || to == null || to <= from) return;
    // A year at most per request.
    if (to - from > 366 * 24 * 3600 * 1000) return;
    final chat = s.chats.where((c) => c.roomId == sig.roomId).firstOrNull;
    if (chat == null || !chat.isDirect) return;
    await _forgetRange(s, sig.roomId, DateTime.fromMillisecondsSinceEpoch(from), DateTime.fromMillisecondsSinceEpoch(to));
  }

  /// Hidden-note handlers for [AppState.signalHandlers].
  static Map<String, Future<void> Function(Signal)> handlers(AppState s) => {
    voiceSignal: (x) => onVoiceSignal(s, x),
    callsSignal: (x) => onCallsSignal(s, x),
    daysSignal: (x) => onDaysSignal(s, x),
  };
}
