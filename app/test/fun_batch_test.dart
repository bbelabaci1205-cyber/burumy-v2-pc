// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 6 (fun / stories / camera), 2026-11-27.
import 'dart:async';
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/birthday.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/ui/first_hello.dart';
import 'package:burumy/ui/photo_viewer.dart';
import 'package:burumy/ui/profile_page.dart';
import 'package:burumy/ui/stories.dart';
import 'package:burumy/ui/video_note.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<(FakeBackend, AppState)> app(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  return (b, s);
}

void main() {
  testWidgets('420 view-once round video: send with "1", opens big, ring, close, then expired', (t) async {
    VideoNotePage.fake = true;
    OnceRoundPlayerPage.fakeLength = const Duration(seconds: 1);
    addTearDown(() {
      VideoNotePage.fake = false;
      OnceRoundPlayerPage.fakeLength = null;
    });
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '안녕');
    b.files['in'] = [0, 0, 0, 1];
    b.rooms[room]!.add(Msg(id: 'in', sender: 'bob', body: 'videonote.mp4', time: DateTime.now(), mine: false, kind: 'video', viewOnce: true));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('once-round')), findsOneWidget);

    // Open the one I got: big circle + ring, plays to the end, then gone.
    await t.tap(find.text('눌러서 열기'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    expect(find.byKey(const Key('once-round-page')), findsOneWidget);
    expect(find.byKey(const Key('once-round-ring')), findsOneWidget);
    expect(find.text('닫고 삭제'), findsOneWidget);
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 60));
    }
    await t.pumpAndSettle();
    expect(find.byKey(const Key('once-round-page')), findsNothing);
    expect(find.byKey(const Key('once-round-expired')), findsOneWidget);
    expect(find.text('만료된 영상 메시지'), findsOneWidget);
    // Record one with the "1" on.
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-videonote')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('video-note-once')));
    await t.pump();
    expect(find.text('한 번만 보기: 받는 사람이 한 번 본 뒤 사라져요'), findsOneWidget);
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pumpAndSettle();
    final sent = b.rooms[room]!.last;
    expect(sent.viewOnce, isTrue);
    expect(sent.kind, 'video');
    expect(sent.body, startsWith('videonote'));
    expect(find.byKey(const Key('once-round')), findsNWidgets(2));
  });

  testWidgets('403 hold a video story: it stops and shows "slide left or right"', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    final st = Story(id: 'v1', roomId: room, eventId: 'v1', sender: 'bob', mine: false, time: DateTime.now(), kind: 'video');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => StoryViewer(
            groups: [
              [st],
            ],
            start: 0,
          ),
        ),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('story-viewer')), findsOneWidget);
    final g = await t.startGesture(t.getCenter(find.byKey(const Key('story-next'))));
    await t.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('story-scrub-hint')), findsOneWidget);
    await g.moveBy(const Offset(120, 0));
    await t.pump(const Duration(milliseconds: 100));
    await g.up();
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('story-scrub-hint')), findsNothing);
    expect(find.byKey(const Key('story-viewer')), findsOneWidget, reason: 'sliding does not close or skip');
    nav.pop();
    await t.pump(const Duration(seconds: 1));
  });

  test('446 birthday days, 29 Feb on 28 Feb in other years', () {
    expect(isBirthdayOn('03-14', DateTime(2027, 3, 14)), isTrue);
    expect(isBirthdayOn('03-14', DateTime(2027, 3, 15)), isFalse);
    expect(isBirthdayOn('02-29', DateTime(2027, 2, 28)), isTrue);
    expect(isBirthdayOn('02-29', DateTime(2028, 2, 28)), isFalse);
    expect(isBirthdayOn('', DateTime(2027, 2, 28)), isFalse);
  });

  testWidgets('446 birthday banner on the chat list, balloons on their info, × hides till tomorrow', (t) async {
    final (b, s) = await app(t);
    final now = DateTime.now();
    final md = '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '안녕');
    b.cards['@mina:test'] = ProfileCard(birthday: md);
    await s.refresh();
    s.cardOf('@mina:test', fresh: true);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('birthday-banner')), findsOneWidget);
    expect(find.textContaining('오늘 생일이에요!'), findsOneWidget);
    await t.tap(find.byKey(const Key('birthday-banner-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('birthday-banner')), findsNothing);
    expect(s.pref('birthday_banner_closed', ''), todayKey(now));

    // Their info page: "오늘 생일 🎂" and balloons, once today.
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => ChatInfoPage(roomId: room, title: 'mina', isGroup: false, isChannel: false),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('birthday-party')), findsOneWidget);
    expect(find.textContaining('오늘 생일 🎂'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
    expect(find.byKey(const Key('birthday-party')), findsNothing);
    nav.pop();
    await t.pumpAndSettle();
    expect(s.pref('birthday_party:@mina:test', ''), todayKey(now));
  });

  testWidgets('80 empty 1:1 chat: hello card with a character, one tap sends it', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, 'x');
    b.rooms[room]!.clear();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('@mina:test').first);
    await t.pump(const Duration(milliseconds: 500));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('first-hello')), findsOneWidget);
    expect(find.text('아직 메시지가 없어요'), findsOneWidget);
    expect(find.byKey(const Key('e2e-notice')), findsOneWidget);
    final id = helloFor(room);
    expect(id, endsWith('_hello'));
    await t.tap(find.byKey(Key('first-hello-$id')));
    await t.pump(const Duration(milliseconds: 500));
    expect(b.rooms[room]!.single.kind, 'sticker');
    expect(b.rooms[room]!.single.body, id);
    expect(find.byKey(const Key('first-hello')), findsNothing);
  });

  testWidgets('317 text in a photo: 글자 button, words light up, pick lines, copy', (t) async {
    final (b, s) = await app(t);
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String?;
      return null;
    });
    Phone.debugReadText = (_) async => const [
      TextLine('Burumy_Guest', Rect.fromLTWH(.1, .2, .5, .06)),
      TextLine('비밀번호: hello2027', Rect.fromLTWH(.1, .3, .6, .06)),
    ];
    addTearDown(() => Phone.debugReadText = null);
    final room = await b.createDirectChat('bob');
    b.files['p'] = File('test/assets/sample_photo.png').readAsBytesSync();
    final m = Msg(id: 'p', sender: 'bob', body: 'p.png', time: DateTime.now(), mine: false, kind: 'image');
    b.rooms[room]!.add(m);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => PhotoViewPage(roomId: room, photos: [m]),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('photo-text')), findsOneWidget);
    expect(find.text('글자'), findsOneWidget);
    await t.tap(find.byKey(const Key('photo-text')));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('live-text')), findsOneWidget);
    expect(find.byKey(const Key('live-line-0')), findsOneWidget);
    await t.tap(find.byKey(const Key('live-line-1')));
    await t.pump();
    expect(find.text('1줄 골랐어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('live-text-copy')));
    await t.pumpAndSettle();
    expect(copied, '비밀번호: hello2027');
    expect(find.byKey(const Key('live-text')), findsNothing);
    expect(find.byKey(const Key('info-banner')), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('317 hidden where the phone cannot read text', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    b.files['p'] = File('test/assets/sample_photo.png').readAsBytesSync();
    final m = Msg(id: 'p', sender: 'bob', body: 'p.png', time: DateTime.now(), mine: false, kind: 'image');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => PhotoViewPage(roomId: room, photos: [m]),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('photo-text')), findsNothing);
  });
}
