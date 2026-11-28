// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Android-only screens of the 2026-11-27 credits + 18+ work at phone size
// (the web preview is iPhone, so these can't be seen there): the age
// question on the first ✨ tap, the under-18 notice, and the Google credit
// under a translation. Regenerate with --update-goldens.
import 'dart:io';

import 'package:burumy/core/ai_age.dart';
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/translate.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_editor_test.dart' show FakeAi, long;
import 'fake_backend.dart';
import 'screens_test.dart' show loadFont;

class _Tr implements TranslateEngine {
  @override
  Future<String?> detect(String text) async => RegExp('[가-힣]').hasMatch(text) ? 'ko' : 'en';
  @override
  Future<TrStatus> status(String from, String to) async => TrStatus.ready;
  @override
  Future<String> translate(String text, {required String from, required String to}) async => '곧 도착해요. 7시에 만나요?';
}

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('CupertinoSystemDisplay', ['assets/fonts/Pretendard-Regular.otf']);
  });

  Future<(FakeBackend, AppState, String)> chat(WidgetTester t, String who) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    LocalAi.engine = FakeAi();
    LocalAi.reset();
    await LocalAi.status();
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    LocalAi.blocked = () => !AiAge.allowed(s);
    addTearDown(() => LocalAi.blocked = () => false);
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat(who);
    return (b, s, room);
  }

  testWidgets('age question and under-18 notice (Android)', (t) async {
    AiAge.debugAndroid = true;
    addTearDown(() => AiAge.debugAndroid = false);
    final (_, s, _) = await chat(t, 'bob');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), long);
    await t.pump();
    await t.tap(find.byKey(const Key('ai-button')));
    await t.pumpAndSettle();
    await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/age_1_question.png'));
    await t.tap(find.byKey(const Key('ai-age-minor')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/age_2_under18.png'));
    await t.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('Google credit under a translation (Android)', (t) async {
    TrCredit.debugAndroid = true;
    addTearDown(() => TrCredit.debugAndroid = false);
    Translate.engine = _Tr();
    Translate.reset();
    final (b, s, room) = await chat(t, '@emma:test');
    b.rooms[room] = [Msg(id: 'e1', sender: '@emma:test', body: 'Just landed. Meet at 7?', time: b.clock, mine: false, kind: 'text')];
    await s.refresh();
    await s.setOn(TrPrefs.button, true);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('@emma:test'));
    await t.pumpAndSettle();
    await t.longPress(find.text('Just landed. Meet at 7?'));
    await t.pumpAndSettle();
    await t.tap(find.text('번역'));
    await t.pumpAndSettle();
    await expectLater(find.byType(BurumyApp), matchesGoldenFile('shots/tr_google_credit.png'));
  });
}
