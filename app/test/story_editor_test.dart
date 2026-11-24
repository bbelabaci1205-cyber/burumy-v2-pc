// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story decorating (Instagram style): words with a colour and a box,
// drawing with undo, a sticker, then one flattened picture is shared.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('words, drawing, sticker, then share one picture', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    final b = demoSample(true, png);
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    Navigator.of(
      t.element(find.byKey(const Key('stories-bar'))),
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.png', png))));
    await t.pumpAndSettle();

    // Words.
    await t.tap(find.byKey(const Key('story-tool-text')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-share')), findsNothing);
    await t.enterText(find.byKey(const Key('story-text-input')), '안녕 친구들');
    await t.tap(find.byKey(const Key('story-color-ffff3b30')));
    await t.tap(find.byKey(const Key('story-text-box')));
    await t.pump();
    await t.tap(find.byKey(const Key('story-text-done')));
    await t.pumpAndSettle();
    expect(find.text('안녕 친구들'), findsOneWidget);
    expect(find.byKey(const Key('story-item-0')), findsOneWidget);

    // Drawing, with undo.
    await t.tap(find.byKey(const Key('story-tool-draw')));
    await t.pumpAndSettle();
    await t.drag(find.byKey(const Key('story-draw-pad')), const Offset(80, 120));
    await t.drag(find.byKey(const Key('story-draw-pad')), const Offset(-60, 40));
    await t.tap(find.byKey(const Key('story-draw-undo')));
    await t.tap(find.byKey(const Key('story-draw-done')));
    await t.pumpAndSettle();

    // A sticker from our packs.
    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-sticker-sheet')), findsOneWidget);
    final first = find
        .byWidgetPredicate(
          (w) =>
              w is GestureDetector &&
              w.key is ValueKey &&
              '${(w.key as ValueKey).value}'.startsWith('sticker-') &&
              !'${(w.key as ValueKey).value}'.startsWith('sticker-tab'),
        )
        .first;
    await t.tap(first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-item-1')), findsOneWidget);

    // Moving something shows the bin.
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('story-item-0'))));
    await g.moveBy(const Offset(0, 30));
    await t.pump();
    expect(find.byKey(const Key('story-bin')), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('story-share')));
    for (var i = 0; i < 30 && !b.storyList.last.mine; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(b.storyList.last.mine, isTrue);
    expect(b.storyList.last.kind, 'image');
    final shared = b.files[b.storyList.last.eventId]!;
    expect(shared.length, isNot(png.length)); // flattened, not the plain photo
    await t.pump(const Duration(seconds: 2));
  });
}
