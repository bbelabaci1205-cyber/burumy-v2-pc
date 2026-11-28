// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// v1 parity batch 1 (2026-11-27): remote wipe by trusted friends, idle
// wipe, 공유 비활성화, photo metadata removal.
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/safety.dart';
import 'package:burumy/core/strip_meta.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Signal wipe(String from, String code, DateTime at) =>
    Signal(roomId: '!r', id: '\$${at.millisecondsSinceEpoch}$from', sender: from, kind: 'wipe', data: {'code': code}, time: at);

void main() {
  final t0 = DateTime(2026, 11, 27, 10);

  test('delete code: only a salted check is kept', () {
    final sealed = Safety.sealCode('blue-river-7');
    expect(sealed.contains('blue-river-7'), isFalse);
    expect(Safety.codeMatches(sealed, 'blue-river-7'), isTrue);
    expect(Safety.codeMatches(sealed, ' blue-river-7 '), isTrue);
    expect(Safety.codeMatches(sealed, 'blue-river-8'), isFalse);
    expect(Safety.codeMatches(sealed, ''), isFalse);
    expect(Safety.sealCode('a'), isNot(Safety.sealCode('a')));
  });

  test('wipe requests: trusted friend + right code, fresh, two votes when asked', () {
    Safety.now = () => t0;
    final settings = {Safety.friendsKey: '@a:x,@b:x', Safety.codeKey: Safety.sealCode('secret1')};
    final votes = <String, int>{};
    expect(Safety.judge(settings, wipe('@a:x', 'secret1', t0), votes), 'wipe');
    expect(Safety.judge(settings, wipe('@c:x', 'secret1', t0), votes), isNull, reason: 'not trusted');
    expect(Safety.judge(settings, wipe('@a:x', 'nope', t0), votes), isNull, reason: 'wrong code');
    expect(Safety.judge(settings, wipe('@a:x', 'secret1', t0.subtract(const Duration(days: 2))), votes), isNull, reason: 'old note');
    expect(Safety.judge({...settings, Safety.codeKey: ''}, wipe('@a:x', 'secret1', t0), votes), isNull, reason: 'no code set');

    final two = {...settings, Safety.twoKey: '1'};
    expect(Safety.judge(two, wipe('@a:x', 'secret1', t0), votes), 'wait');
    expect(Safety.judge(two, wipe('@a:x', 'secret1', t0), votes), 'wait', reason: 'same friend twice');
    expect(Safety.judge(two, wipe('@b:x', 'secret1', t0), votes), 'wipe');
    Safety.now = DateTime.now;
  });

  test('idle wipe: counts days since the app was opened', () async {
    Safety.vault = MemoryVault();
    var now = t0;
    Safety.now = () => now;
    expect(await Safety.idleExpired(), isFalse);
    await Safety.setIdleDays(7);
    expect(await Safety.idleDays(), 7);
    now = t0.add(const Duration(days: 6));
    expect(await Safety.idleExpired(), isFalse);
    expect(await Safety.idleReminderAt(), t0.add(const Duration(days: 12)));
    now = t0.add(const Duration(days: 8));
    expect(await Safety.idleExpired(), isTrue);
    await Safety.touch();
    expect(await Safety.idleExpired(), isFalse);
    await Safety.setIdleDays(0);
    now = t0.add(const Duration(days: 100));
    expect(await Safety.idleExpired(), isFalse);
    Safety.now = DateTime.now;
  });

  test('app state: a trusted request runs the plan, then erases', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@a:test');
    await s.refresh();
    await s.setPref(Safety.friendsKey, '@a:test');
    await s.setPref(Safety.codeKey, Safety.sealCode('secret1'));
    await s.setPref(Safety.lastMsgKey, '폰을 잃어버렸어요');
    b.incomingSignals.add(wipe('@b:test', 'secret1', DateTime.now()));
    await s.handleSignals();
    expect(b.erasedAll, isFalse);
    b.incomingSignals.add(wipe('@a:test', 'secret1', DateTime.now()));
    await s.handleSignals();
    expect(b.erasedAll, isTrue);
    expect(b.rooms.containsKey(room), isFalse);
  });

  test('photo details are removed, the picture stays', () {
    // SOI, APP0 JFIF, APP1 Exif (with fake GPS), APP2 ICC, COM, DQT, SOS + data, EOI
    List<int> seg(int m, List<int> body) => [0xFF, m, (body.length + 2) >> 8, (body.length + 2) & 255, ...body];
    final jfif = seg(0xE0, [...'JFIF'.codeUnits, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0]);
    final exif = seg(0xE1, [...'Exif'.codeUnits, 0, 0, ...'GPS 37.5665N 126.9780E'.codeUnits]);
    final icc = seg(0xE2, [...'ICC_PROFILE'.codeUnits, 0, 1, 1, 9, 9]);
    final com = seg(0xFE, 'made by phone X'.codeUnits);
    final dqt = seg(0xDB, List.filled(65, 1));
    final scan = [0xFF, 0xDA, 0, 8, 1, 1, 0, 0, 63, 0, 0x12, 0x34, 0xFF, 0xD9];
    final jpeg = Uint8List.fromList([0xFF, 0xD8, ...jfif, ...exif, ...icc, ...com, ...dqt, ...scan]);
    final out = StripMeta.photo(jpeg, 'image/jpeg');
    final text = String.fromCharCodes(out);
    expect(text.contains('GPS'), isFalse);
    expect(text.contains('phone X'), isFalse);
    expect(text.contains('ICC_PROFILE'), isTrue);
    expect(text.contains('JFIF'), isTrue);
    expect(out.sublist(out.length - scan.length), scan);
    expect(out.length, jpeg.length - exif.length - com.length);

    // PNG with a text chunk.
    List<int> chunk(String type, List<int> data) => [0, 0, 0, data.length, ...type.codeUnits, ...data, 0, 0, 0, 0];
    final png = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      ...chunk('IHDR', List.filled(13, 0)),
      ...chunk('tEXt', 'Author\u0000Kim'.codeUnits),
      ...chunk('IDAT', [1, 2, 3]),
      ...chunk('IEND', []),
    ]);
    final p = StripMeta.photo(png, 'image/png');
    expect(String.fromCharCodes(p).contains('Author'), isFalse);
    expect(String.fromCharCodes(p).contains('IDAT'), isTrue);

    // Broken files are sent unchanged.
    final junk = [0xFF, 0xD8, 0x00, 0x01];
    expect(StripMeta.photo(junk, 'image/jpeg'), junk);
  });

  testWidgets('공유 비활성화: no copy, forward or save in the menu', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '비밀 글');
    b.roomConfigs[room] = {'protect': true};
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('비밀 글').first);
    await t.pumpAndSettle();
    await t.longPress(find.text('비밀 글').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-reply')), findsOneWidget);
    expect(find.byKey(const Key('menu-copy')), findsNothing);
    expect(find.byKey(const Key('menu-forward')), findsNothing);
    expect(find.byKey(const Key('menu-save')), findsNothing);
  });
}
