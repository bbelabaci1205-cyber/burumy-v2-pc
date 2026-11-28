// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Batch "영상 보기·내려받기" (Telegram tips 109, 116, 101; 2026-11-27):
// - auto-download per network (Wi-Fi / mobile data) × kind (photo, video,
//   file) × chat type (1:1, group, channel), with a size limit for videos
//   and files (tip 116);
// - every download shows on the bubble with its size and an X that really
//   stops it, and in Settings > Data > 다운로드 목록 (tip 109);
// - downloaded copies stay in this device's ENCRYPTED store (never as a
//   plain file) and are removed after the keep time chosen per chat type
//   (tip 101). View-once media is never kept.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'app_state.dart';
import 'backend.dart';
import 'data_usage.dart';

/// Chat types used by the rules ("1:1", "그룹", "채널").
const chatTypes = ['dm', 'group', 'channel'];

/// Media types that can download on their own.
const autoKinds = ['photo', 'video', 'file'];

/// Size limit steps in MB for the slider (videos and files).
const autoSizeSteps = [1, 5, 10, 15, 25, 50, 100, 250, 500, 1000, 2000];

/// Keep times in days for the 101 picker (0 = 안 함 / keep).
const keepSteps = [1, 7, 30, 0];

/// Defaults (Telegram-like): photos everywhere; videos on Wi-Fi up to 50 MB
/// and on mobile data in 1:1 and groups up to 10 MB; files only 1:1 on
/// Wi-Fi up to 5 MB.
const _autoDefault = {
  'wifi_photo': 'dm,group,channel',
  'wifi_video': 'dm,group,channel',
  'wifi_file': 'dm',
  'cell_photo': 'dm,group,channel',
  'cell_video': 'dm,group',
  'cell_file': '',
};
const _maxDefault = {'wifi_video': 50, 'wifi_file': 5, 'cell_video': 10, 'cell_file': 1};

/// Telegram iOS defaults: 1:1 never, groups 1 month, channels 1 week.
const _keepDefault = {'dm': 0, 'group': 30, 'channel': 7};

/// Kinds shown in 저장 공간 (tip 206): voice messages on their own.
const storeKinds = ['photo', 'video', 'file', 'voice'];

/// The kind a kept copy is counted under.
String storeKindOf(Msg m) => m.kind == 'audio' ? 'voice' : autoKindOf(m);

/// 최대 저장 용량 (tip 371) in MB; 0 = 제한 없음.
const cacheMaxSteps = [1024, 5 * 1024, 20 * 1024, 50 * 1024, 0];

/// The message's media type for the rules.
String autoKindOf(Msg m) => m.kind == 'image' ? 'photo' : (m.kind == 'video' ? 'video' : 'file');

String chatTypeOf(AppState s, String roomId) {
  for (final c in s.chats) {
    if (c.roomId == roomId) return c.isChannel ? 'channel' : (c.isDirect ? 'dm' : 'group');
  }
  return 'dm';
}

extension AutoDownloadRules on AppState {
  /// "wifi" or "cell" for the network in use now.
  String get netKey => network == 'cellular' ? 'cell' : 'wifi';

  /// Which chat types download this kind on this network (empty = off).
  Set<String> autoChats(String net, String kind) => pref('adl_${net}_$kind', _autoDefault['${net}_$kind'] ?? '').split(',').where((x) => x.isNotEmpty).toSet();

  Future<void> setAutoChats(String net, String kind, Set<String> chats) => setPref(
    'adl_${net}_$kind',
    [
      for (final t in chatTypes)
        if (chats.contains(t)) t,
    ].join(','),
  );

  /// Size limit in MB (videos and files).
  int autoMaxMb(String net, String kind) => int.tryParse(pref('adl_${net}_${kind}_max', '${_maxDefault['${net}_$kind'] ?? 10}')) ?? 10;

  Future<void> setAutoMaxMb(String net, String kind, int mb) => setPref('adl_${net}_${kind}_max', '$mb');

  /// Download this message's media now without a tap?
  bool autoGet(String roomId, Msg m) {
    if (m.viewOnce || !autoDownload) return false;
    final net = netKey, kind = autoKindOf(m);
    if (!autoChats(net, kind).contains(chatTypeOf(this, roomId))) return false;
    if (kind == 'photo') return true;
    // Unknown size: wait for a tap (it could be 2 GB).
    final size = m.size;
    return size != null && size <= autoMaxMb(net, kind) * 1024 * 1024;
  }

  /// Days a downloaded copy stays for this chat type (0 = keep).
  int keepDays(String chatType) => int.tryParse(pref('keep_$chatType', '${_keepDefault[chatType] ?? 0}')) ?? 0;

  Future<void> setKeepDays(String chatType, int days) async {
    await setPref('keep_$chatType', '$days');
    await Downloads.instance.applyKeep(this);
  }

  // --- 352: 갤러리 자동 저장 (Telegram "Save to Photos") -----------------

  /// Save this kind ("photo" / "video") from this chat type into the
  /// phone's Photos as it arrives. Off by default (a secure messenger).
  bool autoSave(String chatType, String kind) => on('asave_${chatType}_$kind');

  Future<void> setAutoSave(String chatType, String kind, bool v) => setOn('asave_${chatType}_$kind', v);

  /// Videos bigger than this (MB) are not saved on their own.
  int get autoSaveMaxMb => int.tryParse(pref('asave_video_max', '25')) ?? 25;
  Future<void> setAutoSaveMaxMb(int mb) => setPref('asave_video_max', '$mb');

  bool autoSaveAny(String chatType) => autoSave(chatType, 'photo') || autoSave(chatType, 'video');

  /// Should [m] (just downloaded) go to Photos? Never view-once, never
  /// files, never 공유 비활성화 chats (the caller checks that one).
  bool autoSaves(String roomId, Msg m) {
    if (m.viewOnce || (m.kind != 'image' && m.kind != 'video')) return false;
    final kind = m.kind == 'image' ? 'photo' : 'video';
    if (!autoSave(chatTypeOf(this, roomId), kind)) return false;
    return kind == 'photo' || (m.size ?? 0) <= autoSaveMaxMb * 1024 * 1024;
  }

  /// 예외 (tip 101/206): one chat's own keep time, or null = its type's.
  int? keepDaysOf(String roomId) => int.tryParse(pref('keep_room:$roomId', ''));

  /// Days a copy from [roomId] stays (its exception, else its chat type).
  int keepDaysFor(String roomId, String chatType) => keepDaysOf(roomId) ?? keepDays(chatType);

  /// Chats with their own keep time.
  List<String> get keepExceptions => [
    for (final e in settings.entries)
      if (e.key.startsWith('keep_room:') && e.value.isNotEmpty) e.key.substring(10),
  ];

  Future<void> setKeepDaysOf(String roomId, int? days) async {
    await setPref('keep_room:$roomId', days == null ? '' : '$days');
    await Downloads.instance.applyKeep(this);
  }

  /// 최대 저장 용량 in MB (0 = no limit, the default).
  int get cacheMaxMb => int.tryParse(pref('cache_max', '0')) ?? 0;

  Future<void> setCacheMaxMb(int mb) async {
    await setPref('cache_max', '$mb');
    await Downloads.instance.applyKeep(this);
  }

  /// Back to the defaults for both networks.
  Future<void> resetAutoRules() async {
    for (final net in ['wifi', 'cell']) {
      for (final k in autoKinds) {
        await setPref('adl_${net}_$k', _autoDefault['${net}_$k'] ?? '');
        await setPref('adl_${net}_${k}_max', '${_maxDefault['${net}_$k'] ?? 10}');
      }
    }
  }

  bool get autoRulesChanged {
    for (final net in ['wifi', 'cell']) {
      for (final k in autoKinds) {
        if (pref('adl_${net}_$k', _autoDefault['${net}_$k'] ?? '') != (_autoDefault['${net}_$k'] ?? '')) return true;
        if (k != 'photo' && autoMaxMb(net, k) != (_maxDefault['${net}_$k'] ?? 10)) return true;
      }
    }
    return false;
  }
}

/// waiting = in line (at most [Downloads.maxRunning] run at once), paused =
/// stopped by me and kept in the list (tip 322).
enum DownloadState { waiting, running, paused, done, failed, cancelled }

/// Still to come (shows a ring on the bubble).
bool isActive(DownloadState s) => s == DownloadState.waiting || s == DownloadState.running || s == DownloadState.paused;

class DownloadItem {
  DownloadItem({
    required this.roomId,
    required this.eventId,
    required this.name,
    required this.kind,
    required this.size,
    required this.chat,
    required this.at,
    this.state = DownloadState.running,
  });
  final String roomId;
  final String eventId;
  final String name;

  /// "photo", "video" or "file".
  final String kind;
  final int? size;

  /// Chat name at the time (shown in the list).
  final String chat;
  final DateTime at;
  DownloadState state;

  Map<String, Object?> toJson() => {'r': roomId, 'e': eventId, 'n': name, 'k': kind, 's': size, 'c': chat, 't': at.millisecondsSinceEpoch};

  static DownloadItem? fromJson(Object? j) {
    if (j is! Map) return null;
    final r = j['r'], e = j['e'], t = j['t'];
    if (r is! String || e is! String || t is! int) return null;
    return DownloadItem(
      roomId: r,
      eventId: e,
      name: '${j['n'] ?? ''}',
      kind: '${j['k'] ?? 'file'}',
      size: j['s'] is int ? j['s'] as int : null,
      chat: '${j['c'] ?? ''}',
      at: DateTime.fromMillisecondsSinceEpoch(t),
      state: DownloadState.done,
    );
  }
}

/// One running or waiting download.
class _Job {
  _Job(this.s, this.roomId, this.m);
  final AppState s;
  final String roomId;
  final Msg m;
  final done = Completer<List<int>>();

  /// Bumped on pause: a stopped transfer's late answer is ignored.
  int run = 0;
}

/// One place for every media download (bubbles, player, list).
/// Tip 322 (batch #11, 2026-11-27): downloads wait in line (3 at a time),
/// can be paused and started again, and "먼저 받기" moves one to the front.
/// A paused file starts again from the beginning when resumed: the
/// encrypted file comes as one piece from the server (no half-way resume).
class Downloads extends ChangeNotifier {
  Downloads._();
  static final instance = Downloads._();

  /// Newest first: running ones, then finished (kept up to [maxList]).
  final items = <DownloadItem>[];
  static const maxList = 100;

  /// After a download finishes (갤러리 자동 저장, set by the phone app).
  static Future<void> Function(AppState s, String roomId, Msg m, List<int> bytes)? afterDownload;

  /// At most this many transfers at once; the rest wait their turn.
  static int maxRunning = 3;
  final _jobs = <String, _Job>{};

  /// Waiting order (event ids): first in line first.
  final _line = <String>[];
  bool _loaded = false;

  /// Tests: start clean.
  @visibleForTesting
  void reset() {
    items.clear();
    _jobs.clear();
    _line.clear();
    _loaded = false;
    maxRunning = 3;
  }

  void _load(AppState s) {
    if (_loaded) return;
    _loaded = true;
    try {
      final list = jsonDecode(s.pref('dl_list', '[]'));
      if (list is List) {
        for (final j in list) {
          final it = DownloadItem.fromJson(j);
          if (it != null) items.add(it);
        }
      }
    } catch (_) {}
  }

  Future<void> _save(AppState s) =>
      s.setPref('dl_list', jsonEncode([for (final i in items.where((x) => x.state == DownloadState.done).take(maxList)) i.toJson()]));

  DownloadItem? find(String eventId) {
    for (final i in items) {
      if (i.eventId == eventId) return i;
    }
    return null;
  }

  /// Downloading, waiting or paused (the bubble shows a ring).
  bool isRunning(String eventId) {
    final st = find(eventId)?.state;
    return st == DownloadState.running || st == DownloadState.waiting;
  }

  bool isPaused(String eventId) => find(eventId)?.state == DownloadState.paused;

  /// Anything still to come (the ⬇ button on the chat list).
  int get activeCount => items.where((x) => isActive(x.state)).length;

  /// Downloads [m] (once; a second call joins the first, and a paused one
  /// starts again). Kept in the encrypted store unless view-once.
  Future<List<int>> get(AppState s, String roomId, Msg m) {
    _load(s);
    final old = _jobs[m.fileId];
    if (old != null) {
      if (isPaused(m.fileId)) resume(s, m.fileId);
      return old.done.future;
    }
    final chat = s.chats.where((c) => c.roomId == roomId).map((c) => c.name).firstOrNull ?? '';
    final item = DownloadItem(roomId: roomId, eventId: m.fileId, name: m.body ?? '', kind: autoKindOf(m), size: m.size, chat: chat, at: DateTime.now(), state: DownloadState.waiting);
    items.removeWhere((x) => x.eventId == m.fileId);
    items.insert(0, item);
    if (items.length > maxList) items.removeRange(maxList, items.length);
    final job = _Job(s, roomId, m);
    _jobs[m.fileId] = job;
    _line.add(m.fileId);
    _pump();
    // May be called while a bubble builds: tell the listeners right after.
    scheduleMicrotask(notifyListeners);
    return job.done.future;
  }

  void _pump() {
    var running = items.where((x) => x.state == DownloadState.running).length;
    while (running < maxRunning && _line.isNotEmpty) {
      _start(_line.removeAt(0));
      running++;
    }
  }

  void _start(String id) {
    final job = _jobs[id];
    final item = find(id);
    if (job == null || item == null) return;
    item.state = DownloadState.running;
    final run = ++job.run;
    final keep = !job.m.viewOnce;
    final s = job.s;
    // Already kept here: it comes from this device, not the network.
    final local = _kept(s).containsKey(id);
    scheduleMicrotask(notifyListeners);
    unawaited(
      s.backend
          .downloadFileCached(job.roomId, id, cache: keep)
          .then(
            (bytes) async {
              if (run != job.run) return;
              // Stopped with X: nothing comes back (empty), nothing is kept.
              if (item.state == DownloadState.cancelled) return _finish(id, const <int>[]);
              item.state = DownloadState.done;
              // 데이터 사용량 (tip 379).
              if (!local) DataUsage.note(storeKindOf(job.m), sent: false, bytes: bytes.length);
              if (keep) await _touch(s, job.roomId, id, chatTypeOf(s, job.roomId), size: job.m.size ?? bytes.length, kind: storeKindOf(job.m), name: item.name);
              await _save(s);
              _finish(id, bytes);
              final after = afterDownload;
              if (after != null) unawaited(after(s, job.roomId, job.m, bytes).then((_) {}, onError: (_) {}));
            },
            onError: (Object e) {
              if (run != job.run) return;
              if (item.state == DownloadState.cancelled) return _finish(id, const <int>[]);
              item.state = DownloadState.failed;
              _jobs.remove(id);
              job.done.completeError(e);
              notifyListeners();
              _pump();
            },
          ),
    );
  }

  void _finish(String id, List<int> bytes) {
    final job = _jobs.remove(id);
    if (job != null && !job.done.isCompleted) job.done.complete(bytes);
    notifyListeners();
    _pump();
  }

  /// X: really stops the transfer; the bubble goes back to "tap to download".
  Future<void> cancel(AppState s, String eventId) async {
    final it = find(eventId);
    if (it == null || !isActive(it.state)) return;
    final wasRunning = it.state == DownloadState.running;
    it.state = DownloadState.cancelled;
    _line.remove(eventId);
    final job = _jobs[eventId];
    if (job != null) job.run++;
    _finish(eventId, const <int>[]);
    if (wasRunning) await s.backend.cancelDownload(eventId);
  }

  /// 멈추기: stops now, stays in the list; [resume] starts it again.
  Future<void> pause(AppState s, String eventId) async {
    final it = find(eventId);
    if (it == null || (it.state != DownloadState.running && it.state != DownloadState.waiting)) return;
    final wasRunning = it.state == DownloadState.running;
    it.state = DownloadState.paused;
    _line.remove(eventId);
    _jobs[eventId]?.run++;
    notifyListeners();
    _pump();
    if (wasRunning) await s.backend.cancelDownload(eventId);
  }

  /// 이어 받기: back in line (from the start, see the class note).
  void resume(AppState s, String eventId) {
    final it = find(eventId);
    if (it == null || it.state != DownloadState.paused || !_jobs.containsKey(eventId)) return;
    it.state = DownloadState.waiting;
    _line.add(eventId);
    notifyListeners();
    _pump();
  }

  /// 먼저 받기: to the front of the line; when every slot is busy, the
  /// newest running one waits so this one starts now.
  Future<void> first(AppState s, String eventId) async {
    final it = find(eventId);
    if (it == null) return;
    if (it.state == DownloadState.paused) {
      it.state = DownloadState.waiting;
    } else if (it.state != DownloadState.waiting) {
      return;
    }
    _line
      ..remove(eventId)
      ..insert(0, eventId);
    final running = items.where((x) => x.state == DownloadState.running).toList();
    if (running.length >= maxRunning) {
      // items is newest first: the first running one is the newest.
      final bump = running.first;
      bump.state = DownloadState.waiting;
      _jobs[bump.eventId]?.run++;
      _line.insert(1, bump.eventId);
      unawaited(s.backend.cancelDownload(bump.eventId).then((_) {}, onError: (_) {}));
    }
    notifyListeners();
    _pump();
  }

  /// Clears the finished rows (files stay until their keep time).
  Future<void> clearList(AppState s) async {
    items.removeWhere((x) => x.state != DownloadState.running);
    await _save(s);
    notifyListeners();
  }

  // --- 101: kept copies -----------------------------------------------

  Map<String, dynamic> _kept(AppState s) {
    try {
      final m = jsonDecode(s.pref('media_kept', '{}'));
      return m is Map<String, dynamic> ? m : {};
    } catch (_) {
      return {};
    }
  }

  /// Last opened time per kept file (the keep time counts from there),
  /// with its size, kind and name for 대화별 저장 공간.
  Future<void> _touch(AppState s, String roomId, String eventId, String type, {int size = 0, String kind = '', String name = ''}) async {
    final k = _kept(s);
    k.remove(eventId);
    k[eventId] = [roomId, type, DateTime.now().millisecondsSinceEpoch, size, kind, name];
    if (k.length > 3000) k.remove(k.keys.first);
    await s.setPref('media_kept', jsonEncode(k));
  }

  /// Removes copies older than their chat type's keep time, and tells the
  /// store the longest time so it also cleans up by itself. Runs at start
  /// and whenever a keep time changes.
  Future<int> applyKeep(AppState s, {DateTime? now}) async {
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final k = _kept(s);
    var removed = 0;
    for (final e in k.entries.toList()) {
      final v = e.value;
      if (v is! List || v.length < 3) continue;
      final days = s.keepDaysFor('${v[0]}', '${v[1]}');
      if (days == 0) continue;
      if (t - (v[2] as int) > Duration(days: days).inMilliseconds) {
        try {
          await s.backend.forgetFile('${v[0]}', e.key);
        } catch (_) {}
        k.remove(e.key);
        removed++;
      }
    }
    // 최대 저장 용량: over the limit, the oldest copies go first.
    final max = s.cacheMaxMb * 1024 * 1024;
    if (max > 0) {
      var total = 0;
      for (final v in k.values) {
        if (v is List && v.length > 3 && v[3] is int) total += v[3] as int;
      }
      final oldest = k.entries.where((e) => e.value is List && (e.value as List).length > 2).toList()
        ..sort((a, b) => ((a.value as List)[2] as int).compareTo((b.value as List)[2] as int));
      for (final e in oldest) {
        if (total <= max) break;
        final v = e.value as List;
        try {
          await s.backend.forgetFile('${v[0]}', e.key);
        } catch (_) {}
        k.remove(e.key);
        total -= v.length > 3 && v[3] is int ? v[3] as int : 0;
        removed++;
      }
    }
    if (removed > 0) {
      await s.setPref('media_kept', jsonEncode(k));
      notifyListeners();
    }
    final all = [for (final c in chatTypes) s.keepDays(c), for (final r in s.keepExceptions) s.keepDaysOf(r) ?? 0];
    final longest = all.contains(0) ? null : Duration(days: all.reduce((a, b) => a > b ? a : b));
    try {
      await s.backend.setMediaKeep(maxFile: 2000 * 1024 * 1024, keep: longest);
    } catch (_) {}
    return removed;
  }

  /// "임시 파일 지우기": every kept copy goes now.
  Future<void> forgetAll(AppState s) async {
    final k = _kept(s);
    for (final e in k.entries) {
      final v = e.value;
      if (v is List && v.isNotEmpty) {
        try {
          await s.backend.forgetFile('${v[0]}', e.key);
        } catch (_) {}
      }
    }
    await s.setPref('media_kept', '{}');
  }

  /// Copies kept now (for the storage screen).
  int keptCount(AppState s) => _kept(s).length;

  // --- 4-app board: storage per chat (WhatsApp "저장 공간 관리") ------------

  /// Every copy kept on this phone, biggest first.
  List<KeptFile> keptFiles(AppState s, {String? roomId}) {
    final out = <KeptFile>[];
    for (final e in _kept(s).entries) {
      final v = e.value;
      if (v is! List || v.length < 3 || (roomId != null && v[0] != roomId)) continue;
      out.add(
        KeptFile(
          roomId: '${v[0]}',
          eventId: e.key,
          at: DateTime.fromMillisecondsSinceEpoch(v[2] is int ? v[2] as int : 0),
          size: v.length > 3 && v[3] is int ? v[3] as int : 0,
          kind: v.length > 4 ? '${v[4]}' : '',
          name: v.length > 5 ? '${v[5]}' : '',
        ),
      );
    }
    out.sort((a, b) => b.size.compareTo(a.size));
    return out;
  }

  /// Chat -> (copies, bytes), biggest chat first.
  List<(String roomId, int count, int bytes)> keptByChat(AppState s) {
    final m = <String, (int, int)>{};
    for (final f in keptFiles(s)) {
      final x = m[f.roomId] ?? (0, 0);
      m[f.roomId] = (x.$1 + 1, x.$2 + f.size);
    }
    final out = [for (final e in m.entries) (e.key, e.value.$1, e.value.$2)];
    out.sort((a, b) => b.$3 != a.$3 ? b.$3.compareTo(a.$3) : b.$2.compareTo(a.$2));
    return out;
  }

  /// Bytes and copies kept per kind (photo, video, file, voice).
  Map<String, (int bytes, int count)> keptByKind(AppState s, {String? roomId}) {
    final out = {for (final k in storeKinds) k: (0, 0)};
    for (final f in keptFiles(s, roomId: roomId)) {
      final k = storeKinds.contains(f.kind) ? f.kind : 'file';
      final x = out[k]!;
      out[k] = (x.$1 + f.size, x.$2 + 1);
    }
    return out;
  }

  /// Lets every copy of these kinds go (in one chat, or everywhere).
  /// Returns the bytes freed.
  Future<int> forgetKinds(AppState s, Set<String> kinds, {String? roomId}) async {
    final files = [
      for (final f in keptFiles(s, roomId: roomId))
        if (kinds.contains(storeKinds.contains(f.kind) ? f.kind : 'file')) f,
    ];
    await forget(s, [for (final f in files) f.eventId]);
    return files.fold<int>(0, (a, f) => a + f.size);
  }

  /// Lets these copies go (the messages stay; a tap downloads again).
  Future<void> forget(AppState s, Iterable<String> eventIds) async {
    final k = _kept(s);
    for (final id in eventIds) {
      final v = k.remove(id);
      if (v is List && v.isNotEmpty) {
        try {
          await s.backend.forgetFile('${v[0]}', id);
        } catch (_) {}
      }
    }
    await s.setPref('media_kept', jsonEncode(k));
    notifyListeners();
  }
}

/// One downloaded copy kept on this phone.
class KeptFile {
  const KeptFile({required this.roomId, required this.eventId, required this.at, required this.size, required this.kind, required this.name});
  final String roomId;
  final String eventId;
  final DateTime at;

  /// Bytes (0 = kept before sizes were noted).
  final int size;

  /// photo, video, file, voice ('' = not noted).
  final String kind;
  final String name;
}
