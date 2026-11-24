// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PC auto-update: only a newer, well-formed build from the same https place.
import 'package:burumy/core/desktop_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final feed = Uri.parse('https://example.test/x/v2/update.json');
  final sum = 'a' * 64;
  test('newer build is taken, with the installer next to the feed', () {
    final n = newerBuild('{"build":12,"file":"burumy-v2-windows-setup.exe","sha256":"$sum"}', feed, 11);
    expect(n?.build, 12);
    expect(n?.file.toString(), 'https://example.test/x/v2/burumy-v2-windows-setup.exe');
  });
  test('same or older build, other host, bad fingerprint: nothing', () {
    expect(newerBuild('{"build":11,"file":"a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{"build":12,"file":"https://evil.test/a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{"build":12,"file":"../a.exe","sha256":"$sum"}', feed, 11), isNull);
    expect(newerBuild('{"build":12,"file":"a.exe","sha256":"xyz"}', feed, 11), isNull);
    expect(newerBuild('not json', feed, 11), isNull);
  });
}
