// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Profile photo editor: crop dial, filters, adjustments, reset, output.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/photo_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show loadFont;

void main() {
  test('colour matrices', () {
    expect(Cm.mul(Cm.identity, Cm.identity), Cm.identity);
    // Saturation 0 turns pure red grey; offsets add up.
    final m = Cm.saturation(0);
    expect(m[0], closeTo(m[5], 1e-9));
    expect(Cm.all([Cm.offset(10), Cm.offset(5)])[4], 15);
    expect(filterIds.length, 10);
    expect(Adjust.values.length, 13);
    final st = EditState()
      ..filter = 'mono'
      ..angle = 12;
    st.adjust[Adjust.warmth] = 0.5;
    expect(st.untouched, isFalse);
    st.reset();
    expect(st.untouched, isTrue);
    expect(st.matrix(), Cm.identity);
  });

  for (final lang in ['ko', 'en']) {
    testWidgets('editor $lang', (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf']);
      await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
      await loadFont('.SF Pro Text', ['assets/fonts/Pretendard-Regular.otf']);
      final home = Platform.environment['HOME'];
      await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
      final bytes = File('test/assets/sample_photo.png').readAsBytesSync();
      Uint8List? out;
      await t.pumpWidget(
        CupertinoApp(
          locale: Locale(lang),
          supportedLocales: L.supportedLocales,
          localizationsDelegates: const [L.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
          home: Builder(
            builder: (c) => CupertinoButton(key: const Key('open'), onPressed: () async => out = await editProfilePhoto(c, bytes), child: const Text('open')),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('open')));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final e = t.element(find.byType(PhotoEditorPage));
        await precacheImage(MemoryImage(bytes), e);
        await precacheImage(ResizeImage(MemoryImage(bytes), width: 160), e);
      });
      await t.pump();

      // Straighten with the dial: drag left = turn right.
      await t.drag(find.byKey(const Key('editor-dial')), const Offset(-60, 0));
      await t.pump();
      final angle = (t.widget<Text>(find.byKey(const Key('editor-angle'))).data!);
      expect(int.parse(angle.replaceAll('°', '')), greaterThan(5));
      // Zoom in on the photo with two fingers.
      final c = t.getCenter(find.byKey(const Key('editor-photo')));
      final g1 = await t.startGesture(c - const Offset(20, 0));
      final g2 = await t.startGesture(c + const Offset(20, 0));
      await g1.moveBy(const Offset(-40, 0));
      await g2.moveBy(const Offset(40, 0));
      await g1.up();
      await g2.up();
      await t.pump();
      await expectLater(find.byType(PhotoEditorPage), matchesGoldenFile('shots/${lang}_20_editor_crop.png'));

      await t.tap(find.byKey(const Key('editor-mode-filter')));
      await t.pump();
      await t.tap(find.byKey(const Key('filter-warm')));
      await t.pump(const Duration(milliseconds: 300));
      await expectLater(find.byType(PhotoEditorPage), matchesGoldenFile('shots/${lang}_21_editor_filters.png'));

      await t.tap(find.byKey(const Key('editor-mode-adjust')));
      await t.pump();
      await t.tap(find.byKey(const Key('adjust-exposure')));
      await t.drag(find.byKey(const Key('adjust-dial')), const Offset(-45, 0));
      await t.pump();
      await t.dragUntilVisible(find.byKey(const Key('adjust-vignette')), find.byType(ListView).last, const Offset(-200, 0));
      await t.tap(find.byKey(const Key('adjust-vignette')));
      await t.drag(find.byKey(const Key('adjust-dial')), const Offset(-90, 0));
      await t.pump();
      await expectLater(find.byType(PhotoEditorPage), matchesGoldenFile('shots/${lang}_22_editor_adjust.png'));

      // One reset puts everything back.
      await t.tap(find.byKey(const Key('editor-reset')));
      await t.pump();
      await t.tap(find.byKey(const Key('editor-mode-crop')));
      await t.pump();
      expect(find.text('0°'), findsOneWidget);

      await t.tap(find.byKey(const Key('editor-mode-filter')));
      await t.pump();
      await t.tap(find.byKey(const Key('filter-mono')));
      await t.pump();
      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('editor-done')));
        for (var i = 0; i < 20 && out == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await t.pump();
        }
      });
      await t.pumpAndSettle();
      expect(out, isNotNull);
      // A PNG, 1024 x 1024.
      expect(out!.sublist(1, 4), [0x50, 0x4E, 0x47]);
      final w = ByteData.sublistView(out!).getUint32(16);
      expect(w, 1024);
    });
  }
}
