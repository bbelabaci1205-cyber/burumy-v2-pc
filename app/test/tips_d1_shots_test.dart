// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 빠른 다듬기 D1 screens at iPhone size (393 × 852) for checking against
// iOS 27 / Telegram. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/night.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/tips_d1_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:burumy/ui/feedback_page.dart';
import 'package:burumy/ui/folders_page.dart';
import 'package:burumy/ui/room_tools.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  setUpAll(() async {
    Features.tipsD1 = true;
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('CupertinoSystemDisplay', ['assets/fonts/Pretendard-Regular.otf']);
  });

  for (final dark in [false, true]) {
    testWidgets('D1 screens ${dark ? 'dark' : 'light'}', (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
      addTipsD1Sample(b, true, video: const [0]);
      // Fixed times so the pictures don't change every minute.
      final fixed = DateTime(2026, 11, 27, 9, 41);
      for (final r in ['!code', '!r0']) {
        final list = b.rooms[r]!;
        final i = list.indexWhere((m) => m.id == (r == '!code' ? 'code1' : 'd1-video'));
        final m = list[i];
        list[i] = Msg(id: m.id, sender: m.sender, body: m.body, time: fixed, mine: m.mine, kind: m.kind);
      }
      final s = AppState(b, family: BrandFamily.green, locale: const Locale('ko'));
      await s.backend.login(id: 'me', password: 'x');
      await s.refresh();
      await s.setPref('video_pos', b.prefs['video_pos']!);
      await s.setPref(Night.key, dark ? 'dark' : 'light');
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      final tag = dark ? 'dark' : 'light';
      Future<void> shot(String name, Widget page, {Future<void> Function()? then, bool pop = true}) async {
        nav.push(CupertinoPageRoute(builder: (_) => page));
        await t.pumpAndSettle();
        await then?.call();
        await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/d1_${tag}_$name.png'));
        if (pop) nav.pop();
        await t.pumpAndSettle();
      }

      final ch = await b.createGroup('러닝 크루 소식', const [], channel: true);
      b.roomConfigs[ch] = {'reactions': 'some', 'reactions_set': ['❤️', '👍', '🔥', '🎉', '😂'], 'reactions_max': 3};
      await shot('1_reaction_limit', ReactionsPage(roomId: ch));
      await shot('2_code_copy', const ChatPage(roomId: '!code', title: '하늘 미용실'));
      await shot('3_hidden_reaction', ChatPage(roomId: '!c', title: b.names['!c']!));
      await shot('7_video_resume_bar', ChatPage(roomId: '!r0', title: b.names['!r0']!));
      await shot('4_feedback', const FeedbackPage());
      final f = ChatFolder(id: 'w', name: '회사', emoji: '💼', iconOnly: true, kinds: {'group'});
      await shot('5_folder_edit', FolderEditPage(folder: f));
      await shot(
        '6_folder_emoji',
        FolderEditPage(folder: f),
        then: () async {
          await t.tap(find.byKey(const Key('folder-emoji')));
          await t.pumpAndSettle();
        },
        pop: false,
      );
    });
  }
}
