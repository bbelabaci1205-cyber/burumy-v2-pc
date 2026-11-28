// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 데이터 사용량 (Telegram tip 379): how much the app sent and received, on
// Wi-Fi and on mobile data, by kind. Counted on this device only (never
// sent anywhere), from the moment this version runs or the last 초기화.
//
// - 사진 / 동영상 / 파일 / 음성 메시지: real sizes, counted where the app
//   sends or downloads them (RustBackend + Downloads).
// - 메시지: the words I send and the messages that arrive in my chat list,
//   by their length (a little more goes over the air for encryption).
// - 통화: estimated from the minutes talked (voice ≈ 0.3 MB, video ≈ 4 MB per
//   minute each way); shown with "약".
import 'dart:async';
import 'dart:convert';

import 'app_state.dart';

const usageKinds = ['photo', 'video', 'file', 'voice', 'messages', 'calls'];

/// One kind on one network: bytes and counts both ways.
class UsageRow {
  UsageRow([this.sent = 0, this.recv = 0, this.sentN = 0, this.recvN = 0]);
  int sent, recv, sentN, recvN;
  int get total => sent + recv;

  List<int> toJson() => [sent, recv, sentN, recvN];

  static UsageRow from(Object? j) {
    if (j is! List || j.length < 4) return UsageRow();
    int at(int i) => j[i] is int ? j[i] as int : 0;
    return UsageRow(at(0), at(1), at(2), at(3));
  }

  UsageRow operator +(UsageRow o) => UsageRow(sent + o.sent, recv + o.recv, sentN + o.sentN, recvN + o.recvN);
}

class DataUsage {
  const DataUsage._();

  static const _key = 'data_use';

  /// "wifi" or "cell" right now (AppState sets this when it starts).
  static String Function() network = () => 'wifi';

  /// Not yet written to the settings store: net -> kind -> row.
  static final _pending = <String, Map<String, UsageRow>>{};

  /// Called whenever something is noted (AppState saves right after).
  static void Function()? onNote;

  static void note(String kind, {required bool sent, required int bytes, int count = 1}) {
    if (bytes <= 0 && count <= 0) return;
    final net = network() == 'cell' ? 'cell' : 'wifi';
    final row = (_pending[net] ??= {})[kind] ??= UsageRow();
    if (sent) {
      row.sent += bytes;
      row.sentN += count;
    } else {
      row.recv += bytes;
      row.recvN += count;
    }
    onNote?.call();
  }

  /// Media kind of a file by its type ("image/…" → photo …).
  static String kindOfMime(String mime) => mime.startsWith('image/')
      ? 'photo'
      : mime.startsWith('video/')
      ? 'video'
      : mime.startsWith('audio/')
      ? 'voice'
      : 'file';

  /// A call that was live for [talked]: estimated both ways.
  static void noteCall(Duration talked, {required bool video}) {
    final minutes = talked.inSeconds / 60;
    if (minutes <= 0) return;
    final each = (minutes * (video ? 4 : 0.3) * 1024 * 1024).round();
    note('calls', sent: true, bytes: each);
    note('calls', sent: false, bytes: each);
  }

  static Map<String, Map<String, UsageRow>> _stored(AppState s) {
    final out = <String, Map<String, UsageRow>>{};
    try {
      final j = jsonDecode(s.pref(_key, '{}'));
      if (j is Map) {
        for (final net in const ['wifi', 'cell']) {
          final m = j[net];
          if (m is Map) out[net] = {for (final e in m.entries) '${e.key}': UsageRow.from(e.value)};
        }
      }
    } catch (_) {}
    return out;
  }

  /// net ("wifi" / "cell") -> kind -> row, saved and pending together.
  static Map<String, Map<String, UsageRow>> read(AppState s) {
    final out = _stored(s);
    for (final n in _pending.entries) {
      final m = out[n.key] ??= {};
      for (final k in n.value.entries) {
        m[k.key] = (m[k.key] ?? UsageRow()) + k.value;
      }
    }
    return out;
  }

  /// Counting since (first note or the last 초기화).
  static DateTime? since(AppState s) {
    final ms = int.tryParse(s.pref('data_use_since', ''));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Writes what was noted into the settings store.
  static Future<void> flush(AppState s) async {
    if (_pending.isEmpty) return;
    final all = read(s);
    _pending.clear();
    if (since(s) == null) await s.setPref('data_use_since', '${DateTime.now().millisecondsSinceEpoch}');
    await s.setPref(
      _key,
      jsonEncode({
        for (final n in all.entries) n.key: {for (final k in n.value.entries) k.key: k.value.toJson()},
      }),
    );
  }

  /// 통계 초기화.
  static Future<void> reset(AppState s) async {
    _pending.clear();
    await s.setPref(_key, '');
    await s.setPref('data_use_since', '${DateTime.now().millisecondsSinceEpoch}');
  }
}

bool _flushQueued = false;

/// AppState wiring: the current network, and a save right after news (one
/// save for everything noted in the same moment; no timer is left behind).
void startDataUsage(AppState s) {
  DataUsage.network = () => s.network == 'cellular' ? 'cell' : 'wifi';
  DataUsage.onNote = () {
    if (_flushQueued) return;
    _flushQueued = true;
    scheduleMicrotask(() {
      _flushQueued = false;
      unawaited(DataUsage.flush(s).catchError((_) {}));
    });
  };
}
