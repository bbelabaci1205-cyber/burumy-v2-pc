// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PC auto-update: only a newer, well-formed build from the same https place,
// and only when update.json carries a valid signature by a pinned key.
// Fixtures: a throwaway test key (not Eric's) made with
//   ssh-keygen -t ed25519 -f k ; ssh-keygen -Y sign -f k -n burumy-update update.json
import 'dart:convert';

import 'package:burumy/core/desktop_update.dart';
import 'package:burumy/core/update_keys.dart';
import 'package:burumy/core/update_signature.dart';
import 'package:flutter_test/flutter_test.dart';

const testKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICMFD0PyUEiYbUCYhi0ktaLAZLaKuFlnr7MExSANRhva burumy-update";
const otherKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE+OrtABQTc2aIt6qwKp0RRg3RmTyjOqWRv/HgWI9ZNR other";
const body =
    "{\"app\":\"burumy-v2-windows\",\"build\":12,\"file\":\"burumy-v2-windows-setup.exe\",\"sha256\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}";
const goodSig =
    "-----BEGIN SSH SIGNATURE-----\nU1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgIwUPQ/JQSJhtQJiGLSS1osBkto\nq4WWevswTFIA1GG9oAAAANYnVydW15LXVwZGF0ZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtz\nc2gtZWQyNTUxOQAAAECaN5niZCOLqstz7CoxOUHKYl6R6q8m0B3NhznBgW9lYU9Tc55C+M\n+OnnPJas8q9IdK+N1tUTu23t9sLzFEPgcM\n-----END SSH SIGNATURE-----\n";
const sha256Sig =
    "-----BEGIN SSH SIGNATURE-----\nU1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgIwUPQ/JQSJhtQJiGLSS1osBkto\nq4WWevswTFIA1GG9oAAAANYnVydW15LXVwZGF0ZQAAAAAAAAAGc2hhMjU2AAAAUwAAAAtz\nc2gtZWQyNTUxOQAAAEDOcpjvcSBjKHmVmmMVGeZHxOfZQpT3NrA7y6wJ6VuKjVtvvObbUN\nDSAF6C2JahDpQYkXGU8yaXKAbx4395wKkE\n-----END SSH SIGNATURE-----\n";
const wrongPurposeSig =
    "-----BEGIN SSH SIGNATURE-----\nU1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgIwUPQ/JQSJhtQJiGLSS1osBkto\nq4WWevswTFIA1GG9oAAAANb3RoZXItcHVycG9zZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtz\nc2gtZWQyNTUxOQAAAEDwLGIPnNZJdinChVnC5HwUNM0M/TXj6yDNtv5m+Rj7znGvqU3OTb\nkYup+/BbBHN6uM+pSaqYGhDNa7ALAeH+0K\n-----END SSH SIGNATURE-----\n";
const otherKeySig =
    "-----BEGIN SSH SIGNATURE-----\nU1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgT46u0AFBNzZoi3qrAqnRFGDdGZ\nPKM6pZG/8eBYj1k1EAAAANYnVydW15LXVwZGF0ZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtz\nc2gtZWQyNTUxOQAAAEAaD+3Go3BtcePe5xUy/iI3g4NJs59kJ2Udr/zAN9B3E1pSgsBiQs\n2Y4E8h6HNQoEbhdv631FT36EjGfg97VZcB\n-----END SSH SIGNATURE-----\n";

void main() {
  final feed = Uri.parse('https://example.test/x/v2/update.json');
  final sum = 'a' * 64;
  const app = '"app":"burumy-v2-windows"';
  test('newer build is taken, with the installer next to the feed', () {
    final n = newerBuild('{$app,"build":12,"file":"burumy-v2-windows-setup.exe","sha256":"$sum"}', feed, 11);
    expect(n?.build, 12);
    expect(n?.file.toString(), 'https://example.test/x/v2/burumy-v2-windows-setup.exe');
  });
  test('same or older build, other host, bad fingerprint, other app: nothing', () {
    expect(newerBuild('{$app,"build":11,"file":"a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{$app,"build":12,"file":"https://evil.test/a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{$app,"build":12,"file":"../a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{$app,"build":12,"file":"a.exe","sha256":"xyz"}', feed, 11), isNull);
    expect(newerBuild('{"build":12,"file":"a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{"app":"burumy-windows","build":12,"file":"a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('not json', feed, 11), isNull);
  });

  group('signature', () {
    final bytes = utf8.encode(body);
    test('signed by a pinned key: update is taken (sha512 and sha256)', () {
      expect(verifiedNewerBuild(bytes, goodSig, feed, 11, keys: [testKey])?.build, 12);
      expect(verifiedNewerBuild(bytes, sha256Sig, feed, 11, keys: [otherKey, testKey])?.build, 12);
    });
    test('no keys pinned: never updates', () {
      expect(verifiedNewerBuild(bytes, goodSig, feed, 11, keys: const []), isNull);
    });
    test('one changed byte in update.json: refused', () {
      final changed = utf8.encode(body.replaceFirst('"build":12', '"build":13'));
      expect(verifiedNewerBuild(changed, goodSig, feed, 11, keys: [testKey]), isNull);
      final otherSum = utf8.encode(body.replaceFirst('aaaa', 'baaa'));
      expect(verifiedNewerBuild(otherSum, goodSig, feed, 11, keys: [testKey]), isNull);
    });
    test('other key, other purpose, broken or missing signature: refused', () {
      expect(verifiedNewerBuild(bytes, otherKeySig, feed, 11, keys: [testKey]), isNull);
      expect(verifiedNewerBuild(bytes, goodSig, feed, 11, keys: [otherKey]), isNull);
      expect(verifiedNewerBuild(bytes, wrongPurposeSig, feed, 11, keys: [testKey]), isNull);
      expect(verifiedNewerBuild(bytes, '', feed, 11, keys: [testKey]), isNull);
      expect(verifiedNewerBuild(bytes, 'Not found', feed, 11, keys: [testKey]), isNull);
      final flipped = goodSig.replaceFirst('M\n-----END', 'N\n-----END');
      expect(flipped, isNot(goodSig));
      expect(verifiedNewerBuild(bytes, flipped, feed, 11, keys: [testKey]), isNull);
    });
    test('Windows line endings in the .sig file still verify', () {
      expect(verifySshSignature(message: bytes, armored: goodSig.replaceAll('\n', '\r\n'), allowedKeys: [testKey]), isTrue);
    });
    test('signed but older build: refused', () {
      expect(verifiedNewerBuild(bytes, goodSig, feed, 12, keys: [testKey]), isNull);
    });
    test('only valid ssh-ed25519 lines are pinned in the app', () {
      for (final k in updatePublicKeys) {
        expect(k, matches(RegExp(r'^ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI[A-Za-z0-9+/]{43} ?')));
        expect(k, isNot(testKey));
      }
    });
  });
}
