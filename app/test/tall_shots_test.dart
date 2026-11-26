// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Whole settings pages in one tall picture (for checking against v1 and
// Telegram screenshots). Regenerate with --update-goldens.
import 'dart:async';
import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  setUpAll(() async {
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

  testWidgets('tall settings pages', (t) async {
    t.view.physicalSize = const Size(393 * 2, 2600 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final state = AppState(demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync()), family: BrandFamily.green, locale: const Locale('ko'));
    await state.backend.login(id: 'me', password: 'x');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/tall_settings.png'));
    for (final row in ['privacy-row', 'look-row', 'notify-row', 'chats-row', 'data-row', 'power-row', 'devices-row', 'folders-row', 'security-check']) {
      final f = find.byKey(Key(row));
      if (f.evaluate().isEmpty) continue;
      unawaited(Scrollable.ensureVisible(t.element(f), alignment: 0.5));
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
      if (row == 'folders-row') {
        // One suggested folder with a tag colour, then the editor.
        await t.tap(find.byKey(const Key('suggest-add-personal')));
        await t.pumpAndSettle();
        await t.tap(find.text('개인').last);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('folder-color-1')));
        await t.pumpAndSettle();
        await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/tall_folder_edit.png'));
        await t.tap(find.byKey(const Key('folder-save')));
        await t.pumpAndSettle();
      }
      await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/tall_$row.png'));
      await t.tap(find.byKey(const Key('back')).last);
      await t.pumpAndSettle();
    }
  });
}
