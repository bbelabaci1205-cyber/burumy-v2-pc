// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Calls: call out, answer, decline, call waiting / missed / busy, no answer;
// call lines in the chat.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/call_media.dart';
import 'package:burumy/core/call_session.dart';
import 'package:burumy/core/voice.dart';
import 'package:burumy/ui/video_note.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';
import 'fake_call_media.dart';
import 'fake_voice.dart';

Future<void> tick(WidgetTester t, [int seconds = 1]) async {
  for (var i = 0; i < seconds; i++) {
    await t.pump(const Duration(seconds: 1));
  }
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() {
    CallMedia.make = FakeCallMedia.new;
    CallSession.active = null;
    CallSession.waiting.value = null;
  });

  Future<(FakeBackend, AppState, String)> open(WidgetTester t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    return (fake, state, bob);
  }

  testWidgets('call out, talk, mute, hang up; call line in chat (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-voice-call')));
    await tick(t);
    expect(find.text('거는 중…'), findsOneWidget);
    expect(find.text('끝에서 끝까지 암호화돼요'), findsOneWidget);
    final media = FakeCallMedia.last!;
    expect(media.ticket!.mediaKey, startsWith('key-'));

    // Bob answers and joins: the clock runs.
    final callId = fake.rooms[bob]!.last.call!.id;
    await fake.answerCall(bob, callId);
    media.otherJoins();
    await tick(t, 3);
    expect(find.text('00:03'), findsOneWidget);
    await t.tap(find.byKey(const Key('call-mute')));
    await t.pump();
    expect(media.mic, isFalse);
    await t.tap(find.byKey(const Key('call-speaker')));
    await t.pump();
    expect(media.speaker, isTrue);

    fake.now = fake.now.add(const Duration(minutes: 1, seconds: 2));
    await t.tap(find.byKey(const Key('call-end')));
    await t.pump();
    expect(find.text('통화 종료'), findsOneWidget);
    expect(fake.hangups[callId], 'end');
    expect(media.left, isTrue);
    await tick(t, 2);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-status')), findsNothing);
    // Back in the chat (the call started from its info page): the call
    // line with how long we talked.
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await state.refresh();
    await t.pumpAndSettle();
    expect(find.text('건 통화'), findsOneWidget);
    expect(find.textContaining('01:02'), findsOneWidget);
    expect(CallSession.active, isNull);
    state.stopLive();
  });

  Future<String> talkWithBob(WidgetTester t, FakeBackend fake, AppState state, String bob, {bool video = false}) async {
    final id = fake.receiveCall(bob, '@bob:test', video: video);
    await state.refresh();
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.byKey(const Key('call-accept')));
    await t.pump();
    FakeCallMedia.last!.otherJoins();
    await tick(t);
    return id;
  }

  testWidgets('incoming video call: answer; second call waits, end and answer (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    final carol = await fake.createDirectChat('carol');
    final id = fake.receiveCall(bob, '@bob:test', video: true);
    await state.refresh();
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('영상 통화'), findsOneWidget);
    expect(find.byKey(const Key('call-accept')), findsOneWidget);
    await t.tap(find.byKey(const Key('call-accept')));
    await t.pump();
    expect((await fake.callState(bob, id)), 'ongoing');
    FakeCallMedia.last!.otherJoins();
    await tick(t);
    expect(find.byKey(const Key('fake-other-video')), findsOneWidget);
    expect(find.byKey(const Key('fake-my-video')), findsOneWidget);
    await t.tap(find.byKey(const Key('call-flip')));
    await t.pump();
    expect(FakeCallMedia.last!.flips, 1);

    // Carol calls while I'm talking: no "busy"; it waits (she hears ringing).
    final id2 = fake.receiveCall(carol, '@carol:test');
    await state.refresh();
    await tick(t);
    expect(fake.hangups[id2], isNull);
    expect(find.byKey(const Key('call-waiting')), findsOneWidget);
    expect(find.text('대기 중인 전화'), findsOneWidget);

    // End and answer: Bob's call ends, Carol's starts.
    await t.tap(find.byKey(const Key('waiting-answer')));
    await tick(t);
    await t.pumpAndSettle();
    expect(fake.hangups[id], 'end');
    expect(await fake.callState(carol, id2), 'ongoing');
    expect(find.text('carol'), findsWidgets);
    FakeCallMedia.last!.otherJoins();
    await tick(t);
    FakeCallMedia.last!.otherLeaves();
    await tick(t, 2);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-status')), findsNothing);
    state.stopLive();
  });

  testWidgets('waiting call: decline keeps talking; unanswered rings out to missed (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    final carol = await fake.createDirectChat('carol');
    final dan = await fake.createDirectChat('dan');
    await talkWithBob(t, fake, state, bob);
    final id2 = fake.receiveCall(carol, '@carol:test');
    await state.refresh();
    await tick(t);
    await t.tap(find.byKey(const Key('waiting-decline')));
    await tick(t);
    expect(fake.hangups[id2], 'decline');
    expect(find.byKey(const Key('call-waiting')), findsNothing);
    expect(find.byKey(const Key('call-end')), findsOneWidget);

    // Dan calls and gives up: it becomes a missed call; my call goes on.
    final id3 = fake.receiveCall(dan, '@dan:test');
    await state.refresh();
    await tick(t);
    expect(find.byKey(const Key('call-waiting')), findsOneWidget);
    await fake.hangupCall(dan, id3, 'end'); // Dan stops ringing
    await tick(t, 2);
    expect(find.byKey(const Key('call-waiting')), findsNothing);
    expect(await fake.callState(dan, id3), 'missed');
    expect(find.byKey(const Key('call-end')), findsOneWidget);
    state.stopLive();
  });

  testWidgets('my call ends while one waits: it rings normally (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    final carol = await fake.createDirectChat('carol');
    await talkWithBob(t, fake, state, bob);
    fake.receiveCall(carol, '@carol:test');
    await state.refresh();
    await tick(t);
    FakeCallMedia.last!.otherLeaves();
    await tick(t, 2);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-accept')), findsOneWidget);
    expect(find.text('carol'), findsWidgets);
    await t.tap(find.byKey(const Key('call-decline')));
    await tick(t, 2);
    await t.pumpAndSettle();
    state.stopLive();
  });

  testWidgets('settings: missed (nothing shows) and busy (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    final carol = await fake.createDirectChat('carol');
    fake.waitMode = 'missed';
    await talkWithBob(t, fake, state, bob);
    final id2 = fake.receiveCall(carol, '@carol:test');
    await state.refresh();
    await tick(t);
    expect(find.byKey(const Key('call-waiting')), findsNothing);
    expect(fake.hangups[id2], isNull); // she keeps hearing it ring

    fake.waitMode = 'busy';
    final carol2 = await fake.createDirectChat('erin');
    final id3 = fake.receiveCall(carol2, '@erin:test');
    await state.refresh();
    await tick(t);
    expect(fake.hangups[id3], 'busy');
    state.stopLive();
  });

  testWidgets('decline, and no answer after 45 s (ko)', (t) async {
    final (fake, state, bob) = await open(t);
    final id = fake.receiveCall(bob, '@bob:test');
    await state.refresh();
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('음성 통화'), findsOneWidget);
    await t.tap(find.byKey(const Key('call-decline')));
    await tick(t, 2);
    await t.pumpAndSettle();
    expect(fake.hangups[id], 'decline');

    // My call that nobody picks up stops by itself.
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-voice-call')));
    await tick(t, 46);
    expect(find.text('받지 않았어요'), findsOneWidget);
    // It stays open with 남기기 / 다시 걸기 until I close it.
    await tick(t, 2);
    expect(find.byKey(const Key('call-note-voice')), findsOneWidget);
    await t.tap(find.byKey(const Key('call-note-close')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await state.refresh();
    await t.pumpAndSettle();
    expect(find.text('취소한 통화'), findsOneWidget);
    expect(find.text('거절한 통화'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('no answer: leave a voice message, a video note, or call again (ko)', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final (fake, state, bob) = await open(t);
    VoiceKit.recorder = FakeRecorder.new;
    VideoNotePage.fake = true;
    Future<void> callBob() async {
      await t.tap(find.byKey(const Key('info-voice-call')));
      await tick(t, 46);
      expect(find.text('받지 않았어요. 메시지를 남길까요?'), findsOneWidget);
    }

    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await callBob();

    // 음성 남기기: tap to record, tap to send; the call screen closes.
    await t.tap(find.byKey(const Key('call-note-voice')));
    await t.pumpAndSettle();
    expect(find.text('bob님에게 남길 말'), findsOneWidget);
    await t.tap(find.byKey(const Key('voice-note-record')));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('voice-note-record')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-status')), findsNothing);
    expect(fake.rooms[bob]!.where((m) => m.voice != null), hasLength(1));

    // 영상 남기기: a round video note in the chat.
    await callBob();
    await t.tap(find.byKey(const Key('call-note-video')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.byKey(const Key('video-note-record')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('call-status')), findsNothing);
    expect(fake.rooms[bob]!.where((m) => m.kind == 'video' && (m.body ?? '').startsWith('videonote')), hasLength(1));

    // 다시 걸기: a new call rings at once.
    await callBob();
    final calls = fake.rooms[bob]!.where((m) => m.call != null).length;
    await t.tap(find.byKey(const Key('call-again')));
    await tick(t);
    expect(find.text('거는 중…'), findsOneWidget);
    expect(fake.rooms[bob]!.where((m) => m.call != null).length, calls + 1);
    await CallSession.active!.hangUp();
    await tick(t, 2);
    await t.pumpAndSettle();
    state.stopLive();
  });

  test('demo: calls to an unanswered chat end as missed, others keep ringing', () async {
    final b = FakeBackend()..unansweredAfter = Duration.zero;
    await b.login(id: 'me', password: 'demo');
    b.rooms['!mum'] = [];
    b.rooms['!friend'] = [];
    b.unansweredCalls.add('!mum');
    final mum = await b.startCall('!mum', video: false);
    final friend = await b.startCall('!friend', video: false);
    expect(await b.callState('!mum', mum), 'missed');
    expect(await b.callState('!friend', friend), 'ringing');
  });
}
