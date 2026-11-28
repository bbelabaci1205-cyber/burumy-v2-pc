// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Flutter (Dart) -> our Rust engine: sign-up, E2E 1:1 chat, recovery key on
// a new device. Needs a test server: BURUMY_TEST_SERVER (default
// http://127.0.0.1:6167) and BURUMY_TEST_INVITE.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/src/rust/api/device.dart';
import 'package:burumy/src/rust/frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> until(String what, List<BurumyDevice> devices, Future<bool> Function() check) async {
  for (var i = 0; i < 60; i++) {
    for (final d in devices) {
      await d.syncOnce();
    }
    if (await check()) return;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('timed out: $what');
}

Future<Uint8List> alice2Probe(BurumyDevice d, String ref) => d.downloadSecret(file: ref);

void main() {
  final server = Platform.environment['BURUMY_TEST_SERVER'] ?? 'http://127.0.0.1:6167';
  final invite = Platform.environment['BURUMY_TEST_INVITE'];

  setUpAll(() async {
    await RustLib.init(externalLibrary: ExternalLibrary.open('../target/debug/libburumy_bridge.so'));
  });

  test('Dart drives the Rust engine end to end', skip: invite == null ? 'needs a test server (BURUMY_TEST_INVITE)' : null, () async {
    final tmp = await Directory.systemTemp.createTemp('burumy-dart-');
    final run = DateTime.now().millisecondsSinceEpoch;
    const pw = 'Secret-pass-123';

    final alice = await BurumyDevice.open(homeserver: server, dataDir: '${tmp.path}/a1', storePassphrase: 'a1');
    final aliceId = await alice.register(username: 'dalice$run', password: pw, inviteCode: invite);
    final bob = await BurumyDevice.open(homeserver: server, dataDir: '${tmp.path}/b1', storePassphrase: 'b1');
    final bobId = await bob.register(username: 'dbob$run', password: pw, inviteCode: invite);
    expect(aliceId, startsWith('@dalice'));

    final key = await alice.enableRecovery();
    expect(key.split(' ').length, greaterThanOrEqualTo(12));

    final room = await alice.createDm(userId: bobId);
    await until('invite', [bob], () async => bob.invitedRooms().contains(room));
    await bob.join(roomId: room);
    await alice.syncOnce();
    await alice.sendText(roomId: room, text: '플러터에서 보낸 암호화 메시지');
    await until('bob reads', [bob, alice], () async {
      final m = await bob.messages(roomId: room, limit: 20);
      return m.any((x) => x.wasEncrypted && x.body == '플러터에서 보낸 암호화 메시지');
    });

    // A photo with words under it: bob sees the name and the caption.
    await alice.sendFileCaptioned(roomId: room, name: 'sea.png', mime: 'image/png', data: Uint8List.fromList([137, 80, 78, 71]), caption: '바다예요');
    await until('caption', [bob, alice], () async {
      final m = await bob.messages(roomId: room, limit: 30);
      return m.any((x) => x.kind == 'image' && x.body == 'sea.png' && x.caption == '바다예요');
    });

    // Checklist: bob may add but not tick; his tick is ignored on every phone.
    final list = await alice.createChecklist(roomId: room, title: '장보기', items: ['우유', '빵'], othersMark: false, othersAdd: true);
    await until('checklist', [bob, alice], () async => (await bob.messages(roomId: room, limit: 40)).any((x) => x.checklist != null));
    await bob.markChecklist(roomId: room, checklistId: list, item: 'i0', done: true);
    await bob.addChecklistItem(roomId: room, checklistId: list, text: '계란');
    await alice.markChecklist(roomId: room, checklistId: list, item: 'i1', done: true);
    await until('ticks', [bob, alice], () async {
      final c = (await alice.messages(roomId: room, limit: 40)).firstWhere((x) => x.eventId == list).checklist!;
      return c.items.length == 3 && c.items[1].doneBy == aliceId;
    });
    final seen = (await bob.messages(roomId: room, limit: 40)).firstWhere((x) => x.eventId == list).checklist!;
    expect(seen.items[0].doneBy, isNull, reason: 'bob was not allowed to tick');
    expect(seen.items[2].addedBy, bobId);

    // Plan: answers count per person; bob cannot cancel alice's plan.
    final plan = await alice.createMeetup(roomId: room, title: '저녁', startsAt: BigInt.from(DateTime(2030).millisecondsSinceEpoch), endsAt: BigInt.zero, place: '을지로');
    await until('plan', [bob, alice], () async => (await bob.messages(roomId: room, limit: 50)).any((x) => x.meetup != null));
    await bob.answerMeetup(roomId: room, meetupId: plan, answer: 'maybe');
    await bob.answerMeetup(roomId: room, meetupId: plan, answer: 'yes');
    await bob.cancelMeetup(roomId: room, meetupId: plan);
    await bob.sendContact(roomId: room, userId: aliceId, name: '앨리스');
    await bob.sendLocation(roomId: room, lat: 37.5665, lon: 126.978, accuracy: 12.4);
    await until('answers', [bob, alice], () async {
      final m = await alice.messages(roomId: room, limit: 60);
      return m.any((x) => x.kind == 'contact' && x.contact == aliceId) &&
          m.any((x) => x.kind == 'location') &&
          m.firstWhere((x) => x.eventId == plan).meetup!.yes.contains(bobId);
    });
    expect((await alice.messages(roomId: room, limit: 60)).firstWhere((x) => x.kind == 'location').body, 'geo:37.566500,126.978000;u=12');
    await expectLater(bob.sendLocation(roomId: room, lat: 120, lon: 0, accuracy: null), throwsA(anything), reason: 'not a place on Earth');
    final p = (await alice.messages(roomId: room, limit: 60)).firstWhere((x) => x.eventId == plan).meetup!;
    expect(p.maybe, isEmpty);
    expect(p.cancelled, isFalse, reason: 'only the maker cancels');
    expect(p.place, '을지로');

    // Group tools: rename, about, a switch, admin, remove (server checks rights).
    final g = await alice.createGroup(name: '팀', invite: [bobId], channel: false);
    await until('group invite', [bob], () async => bob.invitedRooms().contains(g));
    await bob.join(roomId: g);
    await alice.syncOnce();
    await alice.setRoomName(roomId: g, name: '여행 팀');
    await alice.setRoomAbout(roomId: g, text: '12월 제주');
    await alice.setRoomSwitch(roomId: g, key: 'hide_members', on_: true);
    await alice.setAdmin(roomId: g, userId: bobId, admin: true);
    await until(
      'bob sees tools',
      [bob, alice],
      () async => await bob.roomAbout(roomId: g) == '12월 제주' && await bob.roomSwitch(roomId: g, key: 'hide_members') && await bob.myRole(roomId: g) == 'admin',
    );
    expect(await alice.myRole(roomId: g), 'owner');
    // An admin cannot take the owner out.
    await expectLater(bob.removeMember(roomId: g, userId: aliceId), throwsA(anything));
    await alice.removeMember(roomId: g, userId: bobId);
    await until('bob removed', [alice], () async => !(await alice.members(roomId: g)).any((m) => m.userId == bobId));

    // 환영 인사 photo: encrypted on the phone, only the key travels (in a
    // hidden encrypted signal); another phone decrypts the same bytes.
    final pic = Uint8List.fromList(List.generate(70000, (i) => i % 251));
    final ref = await alice.uploadSecret(bytes: pic);
    expect(ref, contains('"key"'));
    expect(await alice2Probe(bob, ref), pic);

    // Let the room key reach the backup, then a new phone opens history.
    await Future<void>.delayed(const Duration(seconds: 2));
    final alice2 = await BurumyDevice.open(homeserver: server, dataDir: '${tmp.path}/a2', storePassphrase: 'a2');
    await alice2.login(username: 'dalice$run', password: pw, deviceName: 'phone 2');
    await alice2.syncOnce();
    final before = await alice2.messages(roomId: room, limit: 20);
    expect(before.where((m) => m.body != null), isEmpty);
    await alice2.recover(recoveryKey: key, roomId: room);
    final after = await alice2.messages(roomId: room, limit: 20);
    expect(after.where((m) => m.body == '플러터에서 보낸 암호화 메시지'), isNotEmpty);
    // ignore: avoid_print
    print('DART E2E OK: ${after.length} message(s) open on the new device');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
