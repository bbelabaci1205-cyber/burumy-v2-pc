// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/more_sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Chat list second line, like Telegram: who is typing, a missed call, and
// the sender's name in groups (not in channels or 1:1).
void main() {
  testWidgets('list preview: typing, missed call, group sender', (t) async {
    t.view.physicalSize = const Size(393, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    addMoreChats(b, true, const []);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.textContaining('doyun 입력 중…', findRichText: true), findsOneWidget);
    expect(find.textContaining('부재중 통화', findRichText: true), findsOneWidget);
    expect(find.textContaining('coach: ', findRichText: true), findsOneWidget);
    // Channel and 1:1 lines carry no sender name.
    expect(find.textContaining('company: ', findRichText: true), findsNothing);
    expect(find.textContaining('sujin: ', findRichText: true), findsNothing);
    // 저장한 메시지 is all mine: no '나:' in front.
    expect(find.textContaining('나: ', findRichText: true), findsNothing);
  });
}
