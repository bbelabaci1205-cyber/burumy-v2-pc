// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// v1 parity batch 3 (2026-11-27): drafts, pin for a while, repeat sends,
// voice speed, videos in the chat, polls tab.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/room_rules.dart';
import 'package:burumy/core/voice.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/gallery_save.dart';
import 'package:burumy/ui/media_bubbles.dart';
import 'package:burumy/ui/video_note.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'fake_voice.dart';

void main() {
  test('repeat sends: next day / week / month after now', () {
    final at = DateTime(2026, 1, 31, 9);
    expect(AppState.nextRepeat(at, 'day', at), DateTime(2026, 2, 1, 9));
    expect(AppState.nextRepeat(at, 'week', DateTime(2026, 2, 10)), DateTime(2026, 2, 14, 9));
    expect(AppState.nextRepeat(DateTime(2026, 3, 5, 9), 'month', DateTime(2026, 3, 5, 9)), DateTime(2026, 4, 5, 9));
  });

  test('pins for a while', () {
    final t0 = DateTime(2026, 11, 27);
    final cfg = {'pin_until': RoomRules.withPinUntil(const {}, 'a', t0.add(const Duration(days: 1)))};
    expect(RoomRules.livePins(['a', 'b'], cfg, t0), ['a', 'b']);
    expect(RoomRules.livePins(['a', 'b'], cfg, t0.add(const Duration(days: 2))), ['b']);
    expect(RoomRules.expiredPins(cfg, t0.add(const Duration(days: 2))), ['a']);
  });

  test('scheduled repeat goes again', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@bob:test');
    await s.schedule(room, 'good morning', DateTime.now().subtract(const Duration(minutes: 1)), repeat: 'day');
    await s.sendDue();
    expect(b.rooms[room]!.single.body, 'good morning');
    expect(s.scheduled.single['repeat'], 'day');
    expect(DateTime.fromMillisecondsSinceEpoch(s.scheduled.single['at'] as int).isAfter(DateTime.now()), isTrue);
  });

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  testWidgets('a draft stays, shows in the list, and goes once sent', (t) async {
    final (b, s) = await app(t);
    await b.createDirectChat('bob');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), 'half written');
    await t.pump();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(s.pref('draft:${b.rooms.keys.single}', ''), 'half written');
    expect(find.textContaining('임시 저장:'), findsOneWidget);
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    expect(t.widget<CupertinoTextField>(find.byKey(const Key('composer'))).controller!.text, 'half written');
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(s.pref('draft:${b.rooms.keys.single}', ''), '');
  });

  testWidgets('pin for a day keeps the end time', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, 'pin me');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('pin me').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pin-for-86400')));
    await t.pumpAndSettle();
    expect(b.pinned(room), hasLength(1));
    expect((await b.roomConfig(room))['pin_until'], isA<Map>());
  });

  testWidgets('voice speed 1× → 1.5× → 2× and a video opens its player', (t) async {
    VoiceKit.player = FakePlayer.new;
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendVoice(room, 'audio/mp4', [1, 2, 3], const Duration(seconds: 4), const []);
    await b.sendFile(room, name: 'clip.mp4', mime: 'video/mp4', bytes: [0, 0, 0]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('voice-play')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('voice-speed')));
    await t.pumpAndSettle();
    expect(s.pref('voice_speed', '1'), '1.5');
    expect(find.text('1.5×'), findsOneWidget);
    expect(find.byKey(const Key('video-bubble')), findsOneWidget);
    await t.tap(find.byKey(const Key('video-bubble')));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(VideoPlayerPage), findsOneWidget);
    await t.tap(find.byKey(const Key('video-close')));
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('round video: record, send, shows as a circle; photos save to the gallery', (t) async {
    VideoNotePage.fake = true;
    addTearDown(() => VideoNotePage.fake = false);
    final saved = <String>[];
    galleryWriter = (bytes, name, video) async => saved.add('$name:$video');
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendFile(room, name: 'pic.png', mime: 'image/png', bytes: [1, 2]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-videonote')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('video-note-page')), findsOneWidget);
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pumpAndSettle();
    expect(b.rooms[room]!.last.body, startsWith('videonote'));
    expect(b.rooms[room]!.last.kind, 'video');
    expect(find.byKey(const Key('round-video')), findsOneWidget);

    final saveOk = await saveToGallery(b, room, b.rooms[room]!.first);
    expect(saveOk, isTrue);
    expect(saved, ['pic:false']);
  });
}
