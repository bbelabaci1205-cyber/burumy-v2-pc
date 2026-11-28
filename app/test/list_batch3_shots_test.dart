// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 3: iPhone-size screenshots of the swipe settings,
// edit mode with pin / mute, the back-button trail and the folders list
// with "모든 대화" movable.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:burumy/ui/chat_page.dart' show openChat;
import 'package:burumy/ui/folders_page.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/swipe_settings.dart';
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

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final s = AppState(fake, locale: const Locale('ko'));
    await s.login('me', 'x');
    for (final n in ['민지', '서준', '가족']) {
      final id = await fake.createDirectChat(n);
      await fake.sendText(id, '안녕');
    }
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    return (fake, s);
  }

  testWidgets('shots: swipe settings', (t) async {
    final (_, s) = await app(t);
    await s.setPref('swipe_left', 'pin');
    final nav = t.state<NavigatorState>(find.byType(Navigator).last);
    nav.push(IosPageRoute<void>(builder: (_) => const SwipeActionsPage()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('swipe-pick-l-pin')));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_40_swipe_settings.png'));
  });

  testWidgets('shots: edit mode pin + mute', (t) async {
    final (_, s) = await app(t);
    await t.tap(find.byKey(const Key('chats-menu')));
    await t.pumpAndSettle();
    for (final c in s.chats.where((c) => c.name != '가족')) {
      await t.tap(find.byKey(Key('edit-row-${c.roomId}')));
    }
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_41_edit_pin_mute.png'));
    await t.tap(find.byKey(const Key('edit-mute')));
    await t.pump(const Duration(milliseconds: 500));
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_42_edit_muted.png'));
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('shots: back trail', (t) async {
    final (_, s) = await app(t);
    final ctx = t.element(find.text('민지'));
    final a = s.chats.firstWhere((c) => c.name == '민지'), b = s.chats.firstWhere((c) => c.name == '서준');
    openChat(ctx, a.roomId, a.name);
    await t.pumpAndSettle();
    openChat(t.element(find.byKey(const Key('back')).last), b.roomId, b.name);
    await t.pumpAndSettle();
    await t.longPress(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('back-trail')), findsOneWidget);
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_43_back_trail.png'));
    await t.tap(find.byKey(Key('trail-${a.roomId}')));
    await t.pumpAndSettle();
    expect(s.openRoom, a.roomId);
  });

  testWidgets('shots: folders with 모든 대화 movable', (t) async {
    final (_, s) = await app(t);
    await saveFolders(s, [ChatFolder(id: 'w', name: '일', emoji: '💼', kinds: {'group'})]);
    final nav = t.state<NavigatorState>(find.byType(Navigator).last);
    nav.push(IosPageRoute<void>(builder: (_) => const FoldersPage()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('folders-edit')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-drag-all')), findsOneWidget);
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_44_folders_default.png'));
  });
}
