// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 예약 아이디 (Eric 2026-11-26): screenshots of the sign-up refusal with the
// owner's code field, and a channel title held for its owner.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });

  Future<void> phone(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  testWidgets('shots: reserved ID at sign-up, the owner code', (t) async {
    await phone(t);
    final s = AppState(FakeBackend(), locale: const Locale('ko'));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('auth-id')), 'samsung');
    await t.enterText(find.byKey(const Key('auth-pw')), 'abcd1234');
    await t.tap(find.byKey(const Key('auth-submit')));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_30_reserved_id.png'));
    await t.tap(find.byKey(const Key('auth-claim-open')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('auth-claim')), 'BRM-7K2Q-9MXA-4TPL');
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_31_reserved_code.png'));
  });

  testWidgets('shots: channel title held for its owner', (t) async {
    await phone(t);
    final fake = FakeBackend();
    final s = AppState(fake, locale: const Locale('ko'));
    await s.login('me', 'x');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-chat')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-channel')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('chat-name')), 'Samsung');
    await t.tap(find.byKey(const Key('create-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-name-error')), findsOneWidget);
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_32_reserved_channel.png'));
  });
}
