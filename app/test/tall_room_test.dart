// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Whole channel / DM info and admin pages in tall pictures (for checking
// against the v1 screenshots). Regenerate with --update-goldens.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_page.dart' show ChatPage;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'screens_test.dart' show loadFont;

import 'dart:io';

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
  });

  testWidgets('tall room pages', (t) async {
    t.view.physicalSize = const Size(393 * 2, 2600 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final ch = await fake.createGroup('골프채널', [], channel: true);
    final dm = await fake.createDirectChat('@bob:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    Future<void> shot(String n) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/room_$n.png'));
    Future<void> back() async {
      await t.tap(find.byKey(const Key('back')).last);
      await t.pumpAndSettle();
    }

    for (final (id, name) in [(ch, '골프채널'), (dm, '@bob:test')]) {
      await t.tap(find.text(name).first);
      await t.pumpAndSettle();
      expect(find.byType(ChatPage), findsOneWidget);
      await t.tap(find.byKey(const Key('chat-title')));
      await t.pumpAndSettle();
      await shot(id == ch ? 'channel_info' : 'dm_info');
      if (id == ch) {
        await t.tap(find.byKey(const Key('info-tools')));
        await t.pumpAndSettle();
        await shot('channel_tools');
        await back();
        await t.tap(find.byKey(const Key('info-edit')));
        await t.pumpAndSettle();
        await shot('channel_edit');
        await back();
      }
      await back();
      await back();
    }
    state.stopLive();
  });
}
