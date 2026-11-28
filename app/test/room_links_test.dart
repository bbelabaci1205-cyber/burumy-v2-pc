// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:burumy/core/room_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public and private links round-trip', () {
    final p = RoomLinks.parse('봐 ${RoomLinks.public('seoul_runners')} 여기');
    expect(p?.kind, 'public');
    expect(p?.code, 'seoul_runners');
    const code = 'h3k8mtq2va7xw9pc4rzn6sd5je';
    final q = RoomLinks.parse(RoomLinks.private(code, name: '동네 친구들', channel: true))!;
    expect(q.kind, 'private');
    expect(q.code, code);
    expect(q.name, '동네 친구들');
    expect(q.channel, isTrue);
    expect(RoomLinks.parse('https://example.com/c/seoul_runners'), isNull);
    expect(RoomLinks.parse(RoomLinks.private('short')), isNull);
  });

  test('long names are cut to fit a QR code', () {
    final n = shortName('가' * 40);
    expect(n.length, lessThanOrEqualTo(96));
    expect(Uri.decodeComponent(n), '가' * 10);
  });
}
