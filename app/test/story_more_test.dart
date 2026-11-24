// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story extras: who sees it (close friends), how long (6 h), a poll whose
// answer goes to the poster's 1:1 chat, and my archive on this phone.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/story_more.dart';
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

void main() {
  test('live parts survive the trip and bad ones are dropped', () {
    final x = encodeLive([
      StoryLive(kind: 'poll', q: '어때요?', options: ['좋아', '별로'], at: const Offset(.3, .6)),
    ]);
    final back = decodeLive(x);
    expect(back.single.q, '어때요?');
    expect(back.single.at.dx, closeTo(.3, .001));
    expect(decodeLive('{"items":[{"kind":"poll","q":"x","options":["only one"]},{"kind":"evil"}]}'), isEmpty);
    expect(decodeLive('nonsense'), isEmpty);
  });

  testWidgets('close friends, 6 hours, a poll, kept in my archive', (t) async {
    final (s, b) = await start(t);
    final dir = Directory.systemTemp.createTempSync('archive');
    StoryArchive.dirOverride = dir;
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    Navigator.of(
      t.element(find.byKey(const Key('stories-bar'))),
      rootNavigator: true,
    ).push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.png', png))));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('story-audience')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('aud-close')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('aud-friend-!r0')));
    await t.pump();
    await t.tap(find.byKey(const Key('aud-done')));
    await t.pumpAndSettle();
    expect(find.text('친한 친구'), findsOneWidget);
    expect(s.pref('story_close', ''), contains('!r0'));

    await t.tap(find.byKey(const Key('story-hours')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('hours-6')));
    await t.pumpAndSettle();
    expect(find.text('6시간'), findsOneWidget);

    await t.tap(find.byKey(const Key('story-tool-sticker')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-live-poll')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('live-q')), '주말에 뭐 할까?');
    await t.pump();
    await t.tap(find.byKey(const Key('live-done')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-live-item-0')), findsOneWidget);

    await t.tap(find.byKey(const Key('story-share')));
    for (var i = 0; i < 30 && !b.storyList.last.mine; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(b.lastStoryOnly, ['!r0']);
    expect(b.lastStoryHours, 6);
    expect(decodeLive(b.storyList.last.extra).single.q, '주말에 뭐 할까?');
    var kept = <(File, DateTime, String)>[];
    for (var i = 0; i < 30 && kept.isEmpty; i++) {
      kept = (await t.runAsync(StoryArchive.list))!;
      if (kept.isEmpty) await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    }
    expect(kept, hasLength(1));
    await t.pump(const Duration(seconds: 2));
    StoryArchive.dirOverride = null;
  });

  testWidgets("answering a friend's poll goes to our 1:1 chat", (t) async {
    final (_, b) = await start(t);
    b.storyList.add(
      Story(
        id: 'stp',
        roomId: '!r0',
        eventId: 'st1',
        sender: '@mina:test',
        mine: false,
        time: DateTime.now(),
        kind: 'image',
        extra: encodeLive([
          StoryLive(kind: 'poll', q: '짜장 짬뽕?', options: ['짜장', '짬뽕']),
        ]),
      ),
    );
    final s = AppScopeFinder.state(t);
    await s.refresh();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('story-@mina:test')));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    // Mina's third story (the poll).
    await t.tap(find.byKey(const Key('story-next')));
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byKey(const Key('story-next')));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byKey(const Key('live-option-1')));
    await t.pump(const Duration(milliseconds: 300));
    expect(b.rooms['!r0']!.last.body, contains('짬뽕'));
    await t.pump(const Duration(seconds: 2));
  });
}

class AppScopeFinder {
  static AppState state(WidgetTester t) => AppScope.read(t.element(find.byKey(const Key('stories-bar'))));
}
