// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat list long press (v1 menu): a tap on the blurred background closes
// it; a 1:1 has 차단; 읽지 않음으로 표시 shows a badge until the chat opens.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('long press menu: closes on the background, has block, marks unread', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();

    Future<void> hold() async {
      await t.longPress(find.text('가족').last);
      await t.pumpAndSettle();
    }

    await hold();
    expect(find.byKey(const Key('chat-peek')), findsOneWidget);
    await t.tapAt(const Offset(20, 830));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-peek')), findsNothing);

    // 김민지 (a 1:1): 차단 is there.
    await t.longPress(find.text('김민지').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-block')), findsOneWidget);
    await t.tapAt(const Offset(20, 830));
    await t.pumpAndSettle();

    // Mark unread: a badge until opened.
    final before = s.chats.firstWhere((c) => c.roomId == '!r3').unread;
    expect(before, 0);
    await hold();
    await t.tap(find.byKey(const Key('menu-unread')));
    await t.pumpAndSettle();
    expect(s.chats.firstWhere((c) => c.roomId == '!r3').unread, 1);
  });
}
