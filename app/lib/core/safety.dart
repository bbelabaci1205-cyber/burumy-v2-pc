// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Emergency wipes that don't need my password (v1 parity, 2026-11-27):
// - 원격 비상 삭제: 1-3 trusted friends can wipe this phone by sending the
//   delete code I picked, as a hidden encrypted note in our 1:1 chat.
//   Optional: two of them must ask within 24 hours.
// - 미접속 자동 삭제: if the app isn't opened (unlocked) for N days, the next
//   start wipes before anything is shown. A plain reminder comes a day
//   before.
// The code itself is never stored: only a salted hash on this phone.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'backend.dart';

/// Small values that must be readable before the app is unlocked (the
/// lock screen never loads an account). Phones: the system keychain.
abstract class VaultStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

class KeychainVault implements VaultStore {
  static const _s = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _s.read(key: 'burumy.$key');
  @override
  Future<void> write(String key, String? value) => value == null ? _s.delete(key: 'burumy.$key') : _s.write(key: 'burumy.$key', value: value);
}

class MemoryVault implements VaultStore {
  final data = <String, String>{};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String? value) async => value == null ? data.remove(key) : data[key] = value;
}

class Safety {
  const Safety._();

  static VaultStore vault = KeychainVault();

  /// Clock for tests.
  static DateTime Function() now = DateTime.now;

  // ---- 원격 비상 삭제 --------------------------------------------------

  /// Settings keys (encrypted app settings).
  static const friendsKey = 'wipe_friends', codeKey = 'wipe_code', twoKey = 'wipe_two', lastMsgKey = 'wipe_msg', votesKey = 'wipe_votes';

  /// Signal kind a trusted friend sends.
  static const wipeKind = 'wipe';

  static const maxFriends = 3;

  /// "salt$hash" for a new code.
  static String sealCode(String code, {String? salt}) {
    salt ??= base64UrlEncode(List<int>.generate(12, (_) => Random.secure().nextInt(256)));
    return '$salt\$${_hash(code, salt)}';
  }

  static String _hash(String code, String salt) => sha256.convert(utf8.encode('burumy-wipe:$salt:${code.trim()}')).toString();

  static bool codeMatches(String sealed, String code) {
    final i = sealed.indexOf(r'$');
    if (i <= 0 || code.trim().isEmpty) return false;
    final want = sealed.substring(i + 1), got = _hash(code, sealed.substring(0, i));
    // Same time for every wrong code.
    var diff = want.length ^ got.length;
    for (var k = 0; k < min(want.length, got.length); k++) {
      diff |= want.codeUnitAt(k) ^ got.codeUnitAt(k);
    }
    return diff == 0;
  }

  static List<String> friends(Map<String, String> settings) => (settings[friendsKey] ?? '').split(',').where((x) => x.isNotEmpty).toList();

  /// Looks at one hidden note. Returns what to do: null (ignore), 'wait'
  /// (first of two needed votes) or 'wipe'. [votes] is updated in place.
  static String? judge(Map<String, String> settings, Signal s, Map<String, int> votes) {
    if (s.kind != wipeKind) return null;
    final sealed = settings[codeKey] ?? '';
    if (sealed.isEmpty || !friends(settings).contains(s.sender)) return null;
    // Old notes (a new phone syncing history) never count.
    if (now().difference(s.time).abs() > const Duration(hours: 24)) return null;
    if (!codeMatches(sealed, '${s.data['code'] ?? ''}')) return null;
    if (settings[twoKey] != '1') return 'wipe';
    final t = now().millisecondsSinceEpoch;
    votes.removeWhere((_, at) => t - at > const Duration(hours: 24).inMilliseconds);
    votes[s.sender] = t;
    return votes.length >= 2 ? 'wipe' : 'wait';
  }

  // ---- 미접속 자동 삭제 ------------------------------------------------

  static const idleChoices = [0, 3, 7, 14, 30];

  static Future<int> idleDays() async => int.tryParse(await vault.read('idle_days') ?? '') ?? 0;

  static Future<void> setIdleDays(int days) async {
    await vault.write('idle_days', days == 0 ? null : '$days');
    await touch();
  }

  /// The app was opened (unlocked): start counting again.
  static Future<void> touch() => vault.write('idle_last', '${now().millisecondsSinceEpoch}');

  /// On start, before the lock screen: true when the days ran out.
  static Future<bool> idleExpired() async {
    final days = await idleDays();
    if (days == 0) return false;
    final last = int.tryParse(await vault.read('idle_last') ?? '');
    if (last == null) return false;
    return now().millisecondsSinceEpoch - last > Duration(days: days).inMilliseconds;
  }

  /// When the plain reminder should come (a day before), or null.
  static Future<DateTime?> idleReminderAt() async {
    final days = await idleDays();
    if (days == 0) return null;
    return now().add(Duration(days: days - 1));
  }
}
