// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 아이디 키 (WhatsApp "username key", 2026): a stranger can start a 1:1
// chat with me only when they also know the short key I chose. Friends and
// people I already talk with are not asked.
//
// The key itself never leaves the phones. The first invitation carries a
// proof (a hash of the key, both IDs and a fixed label) and only my phone
// compares it. An invitation without the right proof waits unseen (no
// notice, no "declined" sign to the sender), the same way a 'contacts
// only' invitation does.
import 'dart:convert';

import 'package:crypto/crypto.dart';

class IdKey {
  const IdKey._();

  /// The on-device setting holding my key ('' = off).
  static const pref = 'id_key';

  /// Marks the proof in the invitation's reason.
  static const prefix = 'bk1:';

  static const minLength = 4, maxLength = 20;

  /// Keys compare without case or spaces ("Blue 7" = "blue7").
  static String normal(String key) => key.toLowerCase().replaceAll(RegExp(r'\s'), '');

  /// Letters and digits only, 4–20 of them.
  static bool valid(String key) {
    final k = normal(key);
    return k.length >= minLength && k.length <= maxLength && RegExp(r'^[a-z0-9\uAC00-\uD7A3]+$').hasMatch(k);
  }

  /// What the sender's phone puts in the invitation.
  static String proof(String key, {required String from, required String to}) {
    final d = sha256.convert(utf8.encode('burumy-id-key|${normal(key)}|$from|$to'));
    return prefix + base64Url.encode(d.bytes.sublist(0, 16)).replaceAll('=', '');
  }

  /// My phone: may this first 1:1 invitation come in?
  /// [myKey] '' = no key set (everyone the other privacy rules allow).
  static bool lets({required String myKey, required String reason, required String from, required String me, required bool friend}) {
    if (myKey.isEmpty || friend) return true;
    return reason == proof(myKey, from: from, to: me);
  }
}
