// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Checks an SSH signature (ssh-keygen -Y sign, Ed25519) over the exact bytes
// of a file. Eric signs update.json on his own PC with Windows' built-in
// ssh-keygen; the app accepts it only if one of its pinned public keys made
// that signature for the "burumy-update" purpose. Format: OpenSSH PROTOCOL.sshsig.
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pinenacl/ed25519.dart' as nacl;

const updateSigNamespace = 'burumy-update';

/// True only when [armored] is a valid signature over [message] by one of
/// [allowedKeys] (`ssh-ed25519 <base64> [comment]` lines) for [namespace].
bool verifySshSignature({required List<int> message, required String armored, required List<String> allowedKeys, String namespace = updateSigNamespace}) {
  try {
    final blob = _dearmor(armored);
    final r = _Reader(blob);
    if (!_eq(r.raw(6), ascii.encode('SSHSIG'))) return false;
    if (r.u32() != 1) return false;
    final pubBlob = r.string();
    if (!_eq(r.string(), utf8.encode(namespace))) return false;
    r.string(); // reserved
    final hashAlg = utf8.decode(r.string());
    final sigBlob = r.string();
    if (!r.done) return false;

    // The key inside the signature must be one we pinned.
    final pinned = allowedKeys.map(_pubBlobOf).whereType<Uint8List>();
    if (!pinned.any((k) => _eq(k, pubBlob))) return false;
    final pr = _Reader(pubBlob);
    if (utf8.decode(pr.string()) != 'ssh-ed25519') return false;
    final pub = pr.string();
    if (pub.length != 32 || !pr.done) return false;

    final sr = _Reader(sigBlob);
    if (utf8.decode(sr.string()) != 'ssh-ed25519') return false;
    final sig = sr.string();
    if (sig.length != 64 || !sr.done) return false;

    final Digest h;
    if (hashAlg == 'sha512') {
      h = sha512.convert(message);
    } else if (hashAlg == 'sha256') {
      h = sha256.convert(message);
    } else {
      return false;
    }
    final signed = BytesBuilder()
      ..add(ascii.encode('SSHSIG'))
      ..add(_str(utf8.encode(namespace)))
      ..add(_str(const <int>[]))
      ..add(_str(utf8.encode(hashAlg)))
      ..add(_str(h.bytes));
    return nacl.VerifyKey(Uint8List.fromList(pub)).verify(signature: nacl.Signature(Uint8List.fromList(sig)), message: signed.toBytes());
  } catch (_) {
    return false;
  }
}

Uint8List? _pubBlobOf(String line) {
  final parts = line.trim().split(RegExp(r'\s+'));
  if (parts.length < 2 || parts[0] != 'ssh-ed25519') return null;
  try {
    return base64.decode(parts[1]);
  } catch (_) {
    return null;
  }
}

Uint8List _dearmor(String s) {
  const begin = '-----BEGIN SSH SIGNATURE-----', end = '-----END SSH SIGNATURE-----';
  final a = s.indexOf(begin), b = s.indexOf(end);
  if (a < 0 || b < a) throw const FormatException('not an SSH signature');
  return base64.decode(s.substring(a + begin.length, b).replaceAll(RegExp(r'\s'), ''));
}

Uint8List _str(List<int> b) =>
    (BytesBuilder()
          ..add([b.length >> 24 & 0xff, b.length >> 16 & 0xff, b.length >> 8 & 0xff, b.length & 0xff])
          ..add(b))
        .toBytes();

bool _eq(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _Reader {
  _Reader(this._b);
  final Uint8List _b;
  int _i = 0;
  bool get done => _i == _b.length;
  Uint8List raw(int n) {
    if (n < 0 || _i + n > _b.length) throw const FormatException('short');
    final out = Uint8List.sublistView(_b, _i, _i + n);
    _i += n;
    return out;
  }

  int u32() {
    final x = raw(4);
    return x[0] << 24 | x[1] << 16 | x[2] << 8 | x[3];
  }

  Uint8List string() => raw(u32());
}
