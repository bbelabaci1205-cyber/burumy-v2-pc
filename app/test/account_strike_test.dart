// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 고친 앱 정지 (검수 2026-11-28): when the server has paused the account,
// sending says why and keeps the words in the box.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _Paused extends FakeBackend {
  String reason = 'M_FORBIDDEN burumy: account suspended for using a modified app';
  @override
  Future<void> sendText(String roomId, String text) async => throw StateError(reason);
}

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });
  for (final (reason, key) in [
    ('M_FORBIDDEN burumy: account suspended for using a modified app', 'account-suspended'),
    ('M_FORBIDDEN burumy: warning: this looks like a modified app; more tries will suspend this account', 'account-warned'),
    ("M_FORBIDDEN burumy: account suspended for editing someone else's message", 'account-suspended'),
  ]) {
    testWidgets('server refusal $key: explained, words kept', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final b = _Paused()..reason = reason;
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      final room = await b.createGroup('동네 러닝 크루', ['@sujin:test']);
      await s.refresh();
      await s.setOn('undo_send', false);
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('동네 러닝 크루').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(CupertinoTextField).last, '안녕하세요');
      await t.pump();
      await t.tap(find.byKey(const Key('send')));
      await t.pumpAndSettle();
      expect(find.byKey(Key(key)), findsOneWidget);
      await t.tap(find.text('확인'));
      await t.pumpAndSettle();
      expect(find.text('안녕하세요'), findsOneWidget, reason: 'the words stay in the box');
      expect(room, isNotEmpty);
      s.stopLive();
    });
  }

  testWidgets('edit of someone else\'s message: paused until lifted, appeal sent once, then waiting', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = _Paused()..reason = "M_FORBIDDEN burumy: account suspended for editing someone else's message";
    b.paused = const Suspension(suspended: true, reason: 'other_edit');
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await b.createGroup('동네 러닝 크루', ['@sujin:test']);
    await s.refresh();
    await s.setOn('undo_send', false);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 러닝 크루').first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(CupertinoTextField).last, '안녕하세요');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.textContaining('다른 사람의 메시지를 고치려는'), findsOneWidget);
    await t.tap(find.byKey(const Key('appeal-open')));
    await t.pumpAndSettle();
    expect(find.text('운영팀이 풀 때까지 정지 · 다른 사람의 메시지를 고치려는 시도'), findsOneWidget);
    await t.enterText(find.byKey(const Key('appeal-field')), '제 폰을 잃어버렸을 때 누가 쓴 것 같아요');
    await t.pump();
    await t.tap(find.byKey(const Key('appeal-send')));
    await t.pumpAndSettle();
    expect(b.appeals, ['제 폰을 잃어버렸을 때 누가 쓴 것 같아요']);
    expect(find.byKey(const Key('appeal-note')), findsOneWidget);
    expect(find.byKey(const Key('appeal-field')), findsNothing, reason: 'one waiting appeal at a time');
    await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/ko_strike_appeal_waiting.png'));
    s.stopLive();
  });
}
