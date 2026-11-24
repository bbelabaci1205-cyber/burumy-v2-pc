// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Stories (Instagram style): the ring row over the chat list, the viewer
// (next, back, seen marks kept on this device only, reply goes to the 1:1
// chat), and sharing a new one with every 1:1 friend.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/story_camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
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
  return (s, b);
}

void unawaitedPush(WidgetTester t, Widget page) {
  Navigator.of(t.element(find.byKey(const Key('stories-bar'))), rootNavigator: true).push(CupertinoPageRoute<void>(builder: (_) => page));
}

void main() {
  testWidgets('ring row, viewer, seen on this device, reply into the 1:1 chat', (t) async {
    final (s, b) = await start(t);
    expect(find.byKey(const Key('stories-bar')), findsOneWidget);
    expect(find.byKey(const Key('story-mine')), findsOneWidget);
    expect(find.byKey(const Key('story-@mina:test')), findsOneWidget);
    await t.tap(find.byKey(const Key('story-@mina:test')));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('story-viewer')), findsOneWidget);
    expect(find.byKey(const Key('story-caption')), findsOneWidget);
    expect(seenStories(s), contains('st1'));
    // Tap right: Mina's second story.
    await t.tap(find.byKey(const Key('story-next')));
    await t.pump(const Duration(milliseconds: 100));
    expect(seenStories(s), contains('st2'));
    await t.enterText(find.byKey(const Key('story-reply')), '멋져요');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pump(const Duration(milliseconds: 300));
    expect(b.rooms['!r0']!.last.body, contains('멋져요'));
    // Nothing about watching ever goes to the server: only local prefs.
    expect(b.prefs['story_seen'], contains('st2'));
    await t.tap(find.byKey(const Key('story-close')));
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 500));
  });

  testWidgets('share a new story with every 1:1 friend', (t) async {
    final (s, b) = await start(t);
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    // The camera button opens the story camera; here with a picture chosen.
    StoryCameraPage.fake = true;
    await t.tap(find.byKey(const Key('story-camera')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cam-shutter')), findsOneWidget);
    await t.tap(find.byKey(const Key('cam-close')));
    await t.pumpAndSettle();
    // A video keeps the words line (photos get words with the Aa tool).
    unawaitedPush(t, StoryComposer(picked: ('p.mp4', png)));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 100));
    await t.pump(const Duration(milliseconds: 600));
    await t.enterText(find.byKey(const Key('story-caption-input')), '안녕');
    await t.tap(find.byKey(const Key('story-share')));
    await t.pump(const Duration(milliseconds: 300));
    expect(b.storyList.last.mine, isTrue);
    expect(b.storyList.last.caption, '안녕');
    await t.pump(const Duration(seconds: 2));
  });
}
