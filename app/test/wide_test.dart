// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Two panes on a wide window (the PC app): chats and settings pages open on
// the right, the list stays on the left with the open chat marked.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:burumy/ui/wide.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wide window: two panes', (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('wide-empty')), findsOneWidget);
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.text('김민지').last);
    await t.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);
    expect(Wide.selected.value, isNotNull);
    // The list is still there on the left.
    expect(find.byKey(const Key('stories-bar')), findsOneWidget);
    expect(t.getTopLeft(find.byType(ChatPage)).dx, greaterThanOrEqualTo(Wide.listWidth));

    // Opened from the right, it stays on the right: the chat's info page and
    // its "더 보기" sheet (Eric 2026-11-24).
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-more')));
    await t.pumpAndSettle();
    expect(t.getTopLeft(find.byKey(const Key('more-clear'))).dx, greaterThanOrEqualTo(Wide.listWidth));
    await t.tapAt(const Offset(800, 100));
    await t.pumpAndSettle();

    // New chat opens on the right too, the list stays.
    await t.tap(find.byKey(const Key('new-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('stories-bar')), findsOneWidget);
    expect(t.getTopLeft(find.text('새 대화').last).dx, greaterThanOrEqualTo(Wide.listWidth));

    // Settings: the page opens on the right.
    await t.tap(find.byKey(const Key('tab-settings')));
    await t.pumpAndSettle();
    await t.tap(find.text('모양'));
    await t.pumpAndSettle();
    expect(find.byType(ChatPage), findsNothing);
    expect(find.text('설정'), findsWidgets);
    expect(find.byType(WidePage), findsWidgets);
    expect(t.getTopLeft(find.byType(WidePage).first).dx, greaterThanOrEqualTo(Wide.listWidth));
  });
}
