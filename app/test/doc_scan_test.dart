// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 문서 스캔: attach sheet → 문서 스캔 → the phone's scan comes back as a PDF
// and is sent as a file named with the date.
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('문서 스캔 sends the scanned PDF as a file (ko)', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    Phone.debugScan = () async => Uint8List.fromList('%PDF-1.4 test'.codeUnits);
    addTearDown(() => Phone.debugScan = null);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createGroup('서류방', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('서류방'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    expect(find.text('문서 스캔'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-tab-scan')));
    await t.pumpAndSettle();
    final sent = fake.rooms[room]!.last;
    expect(sent.kind, 'file');
    expect(sent.body, matches(RegExp(r'^스캔 \d{4}-\d\d-\d\d \d\d\.\d\d\.pdf$')));
    expect(fake.files.values.last, '%PDF-1.4 test'.codeUnits);
  });
}
