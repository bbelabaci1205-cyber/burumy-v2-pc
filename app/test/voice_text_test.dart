// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 음성 메시지를 글로 보기 + 번역: the phone's own recognizer turns a voice
// message into words (kept on this phone), foreign words get a 번역 link
// (phone AI); a phone that can't shows why.
import 'dart:typed_data';

import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/transcribe.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _Ai implements AiEngine {
  String? asked;
  @override
  Future<AiStatus> status() async => AiStatus.ready;
  @override
  Future<String> run({required String rules, required String text}) async {
    asked = rules;
    return '오늘 저녁 7시에 만나요';
  }
}

void main() {
  tearDown(() {
    Transcribe.debug = null;
    LocalAi.engine = PhoneAi();
    LocalAi.reset();
  });

  Future<(FakeBackend, AppState, String)> open(WidgetTester t, String said) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('mina');
    await fake.sendVoice(room, 'audio/mp4', Uint8List(10), const Duration(seconds: 6), const [100, 300, 900]);
    var calls = 0;
    Transcribe.debug = (b, mime, lang) async {
      calls++;
      expect(lang, 'ko');
      return calls > 1 ? 'TWICE' : said;
    };
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('mina'));
    await t.pumpAndSettle();
    return (fake, state, room);
  }

  testWidgets('words show under the voice message and stay on this phone (ko)', (t) async {
    final (_, state, _) = await open(t, '내일 회의는 10시로 바뀌었어요');
    await t.tap(find.byKey(const Key('voice-text')));
    await t.pumpAndSettle();
    expect(find.text('내일 회의는 10시로 바뀌었어요'), findsOneWidget);
    expect(find.text('이 폰 안에서만 바꿨어요'), findsOneWidget);
    expect(find.byKey(const Key('voice-translate')), findsNothing); // already Korean
    // Closing and opening again doesn't listen again.
    await t.tap(find.byKey(const Key('voice-text')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('voice-text')));
    await t.pumpAndSettle();
    expect(find.text('내일 회의는 10시로 바뀌었어요'), findsOneWidget);
    expect(state.settings.keys.where((k) => k.startsWith('stt:')), hasLength(1));
  });

  testWidgets('foreign words: 번역 with the phone AI (ko)', (t) async {
    final ai = _Ai();
    LocalAi.engine = ai;
    await LocalAi.status(refresh: true);
    await open(t, "Let's meet at 7 tonight");
    await t.tap(find.byKey(const Key('voice-text')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('voice-translate')));
    await t.pumpAndSettle();
    expect(find.text('오늘 저녁 7시에 만나요'), findsOneWidget);
    expect(ai.asked, contains('Korean'));
    expect(find.text('번역 숨기기'), findsOneWidget);
  });

  testWidgets("a phone that can't says so (ko)", (t) async {
    await open(t, '');
    Transcribe.debug = (b, m, l) async => null;
    await t.tap(find.byKey(const Key('voice-text')));
    await t.pumpAndSettle();
    expect(find.textContaining('이 폰에서는 글로 바꿀 수 없어요'), findsOneWidget);
  });
}
