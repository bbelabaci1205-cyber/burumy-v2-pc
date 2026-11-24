// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Friend feed: hidden while the switch is off; when on, a words-only post,
// a friend's photo post liked and answered privately, and delete with undo.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
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
  tearDown(() => Features.feed = false);

  testWidgets('switched off: no way in', (t) async {
    Features.feed = false;
    await start(t);
    expect(find.byKey(const Key('feed-open')), findsNothing);
  });

  testWidgets('words-only post to my friends, kept out of the story row', (t) async {
    Features.feed = true;
    final (s, b) = await start(t);
    b.storyList.removeWhere((x) => x.feed);
    await s.refresh();
    await t.tap(find.byKey(const Key('feed-open')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('feed-empty')), findsOneWidget);

    await t.tap(find.byKey(const Key('feed-new')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('feed-input')), '오늘 날씨 좋다');
    await t.pump();
    await t.tap(find.byKey(const Key('feed-post')));
    await t.pumpAndSettle();
    final p = b.storyList.last;
    expect(p.feed, isTrue);
    expect(p.kind, 'text');
    expect(b.lastStoryHours, 0);
    expect(find.text('오늘 날씨 좋다'), findsOneWidget);
    // Only I see how many liked it.
    expect(find.byKey(Key('feed-likes-${p.id}')), findsOneWidget);
    expect(s.stories.where((x) => x.feed), isEmpty);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets("a friend's photo: like it, reply in our chat", (t) async {
    Features.feed = true;
    final (s, b) = await start(t);
    b.storyList.add(
      Story(id: 'fp1', roomId: '!r0', eventId: 'st1', sender: '@mina:test', mine: false, time: DateTime.now(), kind: 'image', caption: '바다', feed: true),
    );
    await s.refresh();
    await t.tap(find.byKey(const Key('feed-open')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('feed-post-fp1')), findsOneWidget);
    expect(find.byKey(const Key('feed-likes-fp1')), findsNothing);

    await t.tap(find.byKey(const Key('feed-like-fp1')));
    await t.pumpAndSettle();
    expect((await b.feedLikes()).single.postId, 'fp1');

    await t.tap(find.byKey(const Key('feed-reply-fp1')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('feed-reply-input')), '어디야?');
    await t.tap(find.byKey(const Key('feed-reply-send')));
    await t.pumpAndSettle();
    final last = b.rooms['!r0']!.last;
    expect(last.body, contains('바다'));
    expect(last.body, contains('어디야?'));
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('delete my post: 5 seconds to undo, then gone', (t) async {
    Features.feed = true;
    final (s, b) = await start(t);
    b.storyList.removeWhere((x) => x.feed);
    await b.postStory(mime: '', bytes: const [], caption: '지울 글', hours: 0);
    await s.refresh();
    final id = b.storyList.last.id;
    await t.tap(find.byKey(const Key('feed-open')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('feed-more-$id')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('feed-delete')));
    await t.pumpAndSettle();
    expect(find.text('지울 글'), findsNothing);
    await t.tap(find.byKey(const Key('feed-undo')));
    await t.pumpAndSettle();
    expect(find.text('지울 글'), findsOneWidget);

    await t.tap(find.byKey(Key('feed-more-$id')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('feed-delete')));
    await t.pump();
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await t.pumpAndSettle();
    expect(b.storyList.where((x) => x.id == id), isEmpty);
  });
}
