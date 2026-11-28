// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스토리 남기기·꾸미기 (Telegram tips 393, 392 / 468 / 534, 525, 395, 408,
// 414, 428): change a posted story (the words come back editable), keep it
// on the profile in an album, a friend's kept stories in two albums, a
// reaction sticker that answers privately, a long video in parts, a group's
// story (admins only) and a channel post shared to my story.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/story_keep_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/profile_page.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/story_keep.dart';
import 'package:burumy/ui/story_more.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

final png = File('test/assets/sample_photo.png').readAsBytesSync();

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, png);
  await t.runAsync(() => addStoryKeepSample(b, true, png, still: png, clip: Uint8List.fromList([0, 0, 0, 1]), round: Uint8List.fromList([0, 0, 0, 1])));
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  s.settings = await b.settings();
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  StoryKit.inMemory = true;
  StoryArchive.dirOverride = Directory.systemTemp.createTempSync('archive');
  return (s, b);
}

NavigatorState rootNav(WidgetTester t) => Navigator.of(t.element(find.byKey(const Key('stories-bar'))), rootNavigator: true);

Future<String> postWithWords(WidgetTester t, FakeBackend b, String words) async {
  unawaited(rootNav(t).push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.png', png)))));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('story-tool-text')));
  await t.pumpAndSettle();
  await t.enterText(find.byKey(const Key('story-text-input')), words);
  await t.tap(find.byKey(const Key('story-text-done')));
  await t.pumpAndSettle();
  await t.runAsync(() async {
    await t.tap(find.byKey(const Key('story-share')));
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await t.pumpAndSettle();
  await t.runAsync(() => AppScope.read(t.element(find.byKey(const Key('stories-bar')))).refresh());
  await t.pumpAndSettle();
  return b.storyList.lastWhere((x) => x.mine).id;
}

Future<void> openMine(WidgetTester t) async {
  await t.tap(find.byKey(const Key('story-mine')));
  await t.pump(const Duration(milliseconds: 400));
  await t.pump(const Duration(milliseconds: 400));
}

void main() {
  test('pin, album, parts and one-tap parts read back safely', () {
    final x = Story(
      id: 'a',
      roomId: '',
      eventId: 'a',
      sender: '@me:test',
      mine: true,
      time: DateTime(2026),
      kind: 'image',
      pin: storyPin(album: '제주도', top: true),
      until: DateTime(2026),
    );
    expect((x.kept, x.album, x.top, x.inRow), (true, '제주도', true, false));
    expect(storyClip('{"clip":{"from":60,"to":120}}'), (60.0, 120.0));
    expect(storyClip('{"clip":{"from":60,"to":20}}'), isNull);
    expect(storyClip('{"clip":{"from":0,"to":900}}'), isNull);
    final good = '{"url":"mxc://x/1","key":{"k":"a"}}';
    final parts = decodeLive(
      encodeLive([
        StoryLive(kind: 'react', q: '🔥'),
        StoryLive(kind: 'music', q: '산책', site: '부루미', file: good, mime: 'audio/mpeg'),
        StoryLive(kind: 'round', file: good, mime: 'video/mp4'),
        StoryLive(kind: 'post', q: '부루미 소식', room: '!c', event: 'n1', url: 'https://burumy.app/c/news'),
      ]),
    );
    expect(parts.map((p) => p.kind), ['react', 'music', 'round', 'post']);
    // A friend's phone can't slip in a web address or a strange file.
    expect(decodeLive('{"items":[{"kind":"music","q":"x","file":"{\\"url\\":\\"https://evil\\"}","mime":"audio/mpeg"}]}'), isEmpty);
    expect(decodeLive('{"items":[{"kind":"round","file":"${good.replaceAll('"', r'\"')}","mime":"text/html"}]}'), isEmpty);
    expect(decodeLive('{"items":[{"kind":"react","q":"<b>"}]}').single.q, '❤️');
    expect(decodeLive('{"items":[{"kind":"post","q":"x","room":"evil","event":"e"}]}'), isEmpty);
    expect(withExtra('{"items":[]}', {'cover': 'c'}), '{"cover":"c"}');
    expect(withExtra('{"cover":"c"}', {'cover': null}), '');
    expect(demoTune().sublist(0, 4), 'RIFF'.codeUnits);
  });

  testWidgets('change a posted story: the words come back and can be changed (393)', (t) async {
    final (s, b) = await start(t);
    final id = await postWithWords(t, b, '오타 잇는 글');
    expect(await t.runAsync(() => StoryKit.load(id)), isNotNull);
    final first = b.storyList.firstWhere((x) => x.id == id);
    await openMine(t);
    await t.tap(find.byKey(const Key('story-more')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('my-story-edit')), findsOneWidget);
    await t.tap(find.byKey(const Key('my-story-edit')));
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    // The words I wrote are a layer again, not part of the picture.
    expect(find.text('오타 잇는 글'), findsOneWidget);
    await t.tap(find.byKey(const Key('story-item-0')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('story-text-input')), '고친 글');
    await t.tap(find.byKey(const Key('story-text-done')));
    await t.pumpAndSettle();
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('story-share')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    final now = b.storyList.firstWhere((x) => x.id == id);
    expect(now.edited, isTrue);
    expect(now.time, first.time, reason: 'keeps its place and time');
    expect(now.eventId, isNot(first.eventId), reason: 'the new picture went up');
    expect(find.text('고쳤어요'), findsOneWidget);
    s.stopLive();
  });

  testWidgets('keep on my profile, in an album, pinned on top (392 / 534)', (t) async {
    final (s, b) = await start(t);
    final id = await postWithWords(t, b, '바다');
    Future<void> menu(String key) async {
      await openMine(t);
      await t.tap(find.byKey(const Key('story-more')));
      await t.pumpAndSettle();
      await t.runAsync(() async {
        await t.tap(find.byKey(Key(key)));
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await t.pumpAndSettle();
    }

    await menu('my-story-keep');
    expect(b.storyList.firstWhere((x) => x.id == id).kept, isTrue);
    await menu('my-story-album');
    expect(find.byKey(const Key('album-제주도')), findsOneWidget, reason: 'albums I already use');
    await t.enterText(find.byKey(const Key('album-name')), '바다 여행');
    await t.pump();
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('album-done')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await t.pumpAndSettle();
    expect(b.storyList.firstWhere((x) => x.id == id).album, '바다 여행');
    await menu('my-story-top');
    expect(b.storyList.firstWhere((x) => x.id == id).top, isTrue);
    // 프로필 스토리: mine, with both albums; the pinned one first.
    unawaited(openMyKept(t.element(find.byKey(const Key('stories-bar')))));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('my-kept-page')), findsOneWidget);
    expect(find.byKey(Key('kept-$id')), findsOneWidget);
    expect(find.byKey(const Key('kept-top')), findsOneWidget);
    expect(find.byKey(const Key('kept-album-제주도')), findsOneWidget);
    await t.tap(find.byKey(const Key('kept-album-제주도')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('kept-$id')), findsNothing);
    expect(find.byKey(const Key('kept-kp-mine-jeju')), findsOneWidget);
    s.stopLive();
  });

  testWidgets("a friend's kept stories on their info page, by album (534)", (t) async {
    final (s, _) = await start(t);
    unawaited(
      rootNav(t).push(
        CupertinoPageRoute<void>(
          builder: (_) => const ChatInfoPage(roomId: '!r0', title: 'mina', isGroup: false, isChannel: false),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('kept-stories')), 300, scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('kept-kp-mina-1')), findsOneWidget);
    expect(find.text('프로필 스토리 4개'), findsOneWidget);
    await t.tap(find.byKey(const Key('kept-album-여행')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('kept-kp-mina-1')), findsNothing);
    expect(find.byKey(const Key('kept-kp-mina-3')), findsOneWidget);
    s.stopLive();
  });

  testWidgets('reaction sticker: one tap answers the poster privately (395)', (t) async {
    final (s, b) = await start(t);
    final leo = storyGroups(s, s.stories).firstWhere((g) => g.first.sender == '@leo:test' && !g.first.group);
    final at = leo.indexWhere((x) => x.id == 'st-leo-long-1');
    unawaited(openStories(t.element(find.byKey(const Key('stories-bar'))), [leo], 0, at: at));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('story-viewer')), findsOneWidget);
    expect(find.byKey(const Key('story-media-st-leo-long-1-0')), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('story-media-st-leo-long-1-0')));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pump(const Duration(milliseconds: 500));
    expect(b.rooms['!r2']!.last.body, contains('❤️'));
    expect(s.pref('story_vote:st-leo-long-1:0', ''), '❤️');
    // The two parts of one long video share one upload (525).
    final parts = leo.where((x) => x.id.startsWith('st-leo-long')).toList();
    expect(parts.map((x) => x.eventId).toSet().length, 1);
    expect(parts.map((x) => storyClip(x.extra)), [(0.0, 20.0), (20.0, 40.0)]);
    expect(storyCover(parts.first.extra), isNotEmpty);
    await t.pump(const Duration(seconds: 2));
    Navigator.of(t.element(find.byKey(const Key('story-viewer')))).pop();
    await t.pumpAndSettle();
    s.stopLive();
  });

  testWidgets("a group's story: admins post, everyone sees it under the group (428)", (t) async {
    final (s, b) = await start(t);
    expect(find.byKey(const Key('story-room-!r1')), findsOneWidget);
    unawaited(
      rootNav(t).push(
        CupertinoPageRoute<void>(
          builder: (_) => StoryComposer(picked: ('p.png', png), room: '!r1', roomName: '팀'),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('story-group')), findsOneWidget);
    expect(find.byKey(const Key('story-audience')), findsNothing, reason: 'the whole group sees it');
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('story-share')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    final g = b.storyList.last;
    expect((g.mine, g.group, g.roomId), (true, true, '!r1'));
    // A member (the channel !c, where I only read) can't.
    expect(() => b.postStories(mime: 'image/png', bytes: png, room: '!c'), throwsA(isA<StateError>()));
    s.stopLive();
  });

  testWidgets('channel post to my story: the card and a 글 보기 part (414)', (t) async {
    final (s, b) = await start(t);
    b.rooms['!c']!.add(Msg(id: 'n9', sender: '@burumy:test', body: '이번 주 새 기능', time: DateTime.now(), mine: false, kind: 'text'));
    await t.runAsync(s.refresh);
    await t.tap(find.text('부루미 소식'));
    await t.pumpAndSettle();
    const n1 = 'n9';
    await t.tap(find.byKey(Key('share-$n1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('share-to-story')), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('share-to-story')));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    expect(find.byKey(const Key('post-card')), findsOneWidget);
    expect(find.byKey(const Key('story-live-item-0')), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('story-share')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await t.pumpAndSettle();
    final x = b.storyList.last;
    expect(x.mine, isTrue);
    final post = decodeLive(x.extra).single;
    expect((post.kind, post.room, post.event), ('post', '!c', n1));
    s.stopLive();
  });
}
