// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 번역 (2026-11-27, v1 parity): the bar on a chat in another language, the
// whole chat translated in place, the 번역 sheet, Settings > 언어.
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/translate.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/translate_ui.dart' show TranslateSheet;
import 'package:burumy/ui/settings_pages.dart' show LanguagePage;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _Engine implements TranslateEngine {
  TrStatus st = TrStatus.ready;
  final asked = <String>[];
  @override
  Future<String?> detect(String text) async => RegExp('[가-힣]').hasMatch(text) ? 'ko' : 'en';
  @override
  Future<TrStatus> status(String from, String to) async => st;
  @override
  Future<String> translate(String text, {required String from, required String to}) async {
    asked.add('$from>$to');
    return '[$to] $text';
  }
}

void main() {
  late _Engine engine;
  setUp(() {
    engine = _Engine();
    Translate.engine = engine;
    Translate.reset();
  });

  Future<(FakeBackend, AppState, String)> chat(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@emma:test');
    final at = b.clock;
    b.rooms[room] = [
      for (final (i, w) in ['Hi! I just landed', 'Are we meeting at 7?', 'Let me know'].indexed)
        Msg(
          id: 'e$i',
          sender: '@emma:test',
          body: w,
          time: at.add(Duration(minutes: i)),
          mine: false,
          kind: 'text',
        ),
    ];
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('@emma:test'));
    await t.pumpAndSettle();
    return (b, s, room);
  }

  testWidgets('a chat in English: bar -> whole chat in Korean -> 원문 보기', (t) async {
    final (_, s, room) = await chat(t);
    expect(find.byKey(const Key('translate-bar')), findsOneWidget);
    expect(find.text('한국어로 번역하기'), findsOneWidget);
    await t.tap(find.byKey(const Key('translate-bar-tap')));
    await t.pumpAndSettle();
    expect(s.pref(TrPrefs.on(room), ''), 'ko');
    expect(find.text('[ko] Are we meeting at 7?'), findsOneWidget);
    expect(find.text('원문 보기'), findsOneWidget);
    await t.tap(find.byKey(const Key('translate-bar-tap')));
    await t.pumpAndSettle();
    expect(find.text('Are we meeting at 7?'), findsOneWidget);
    expect(engine.asked.toSet(), {'en>ko'});
  });

  testWidgets('⋯ menu: don\'t translate English hides the bar; other language; hide here', (t) async {
    final (_, s, room) = await chat(t);
    await t.tap(find.byKey(const Key('translate-bar-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-bar-other')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-lang-ja')));
    await t.pumpAndSettle();
    expect(s.pref(TrPrefs.on(room), ''), 'ja');
    expect(find.text('[ja] Let me know'), findsOneWidget);
    await t.tap(find.byKey(const Key('translate-bar-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-bar-skip')));
    await t.pumpAndSettle();
    expect(s.pref(TrPrefs.skip, ''), 'en');
    expect(find.byKey(const Key('translate-bar')), findsNothing);
    await s.setPref(TrPrefs.skip, '');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('translate-bar-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-bar-hide')));
    await t.pump();
    expect(find.byKey(const Key('translate-bar')), findsNothing);
    expect(s.on(TrPrefs.hidden(room)), isTrue);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('no bar when switched off, or the phone can\'t translate', (t) async {
    engine.st = TrStatus.unsupported;
    await chat(t);
    expect(find.byKey(const Key('translate-bar')), findsNothing);
  });

  testWidgets('Android: "Powered by Google Translate" next to translations; iPhone: none', (t) async {
    TrCredit.debugAndroid = true;
    addTearDown(() => TrCredit.debugAndroid = false);
    final (_, s, _) = await chat(t);
    expect(find.byKey(const Key('tr-google-credit')), findsNothing);
    await t.tap(find.byKey(const Key('translate-bar-tap')));
    await t.pumpAndSettle();
    expect(find.text('Powered by Google Translate'), findsOneWidget);
    await s.setOn(TrPrefs.button, true);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('translate-bar-tap')));
    await t.pumpAndSettle();
    await t.longPress(find.text('Let me know'));
    await t.pumpAndSettle();
    await t.tap(find.text('번역'));
    await t.pumpAndSettle();
    expect(find.descendant(of: find.byType(TranslateSheet), matching: find.byKey(const Key('tr-google-credit'))), findsOneWidget);
    TrCredit.debugAndroid = false;
    await t.tap(find.byKey(const Key('tr-to')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-lang-ja')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tr-google-credit')), findsNothing);
  });

  testWidgets('번역 button: hold a message -> sheet with the translation, then whole chat on', (t) async {
    final (_, s, room) = await chat(t);
    await s.setOn(TrPrefs.button, true);
    await t.pumpAndSettle();
    await t.longPress(find.text('Let me know'));
    await t.pumpAndSettle();
    await t.tap(find.text('번역'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tr-original')), findsOneWidget);
    expect(find.text('영어'), findsOneWidget);
    expect(find.text('[ko] Let me know'), findsOneWidget);
    await t.tap(find.byKey(const Key('tr-whole-chat')));
    await t.pumpAndSettle();
    expect(s.pref(TrPrefs.on(room), ''), 'ko');
  });

  testWidgets('Settings > 언어: 번역 group and 번역하지 않을 언어', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    unawaited(Navigator.of(t.element(find.byType(CupertinoPageScaffold).first)).push(IosPageRoute(builder: (_) => const LanguagePage())));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pref-translate_button')), findsOneWidget);
    expect(find.byKey(const Key('pref-translate_chat')), findsOneWidget);
    expect(find.byKey(const Key('pick-ko')), findsOneWidget);
    await t.tap(find.byKey(const Key('tr-skip-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-lang-en')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-lang-ja')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tr-lang-en')));
    await t.pumpAndSettle();
    expect(s.pref(TrPrefs.skip, ''), 'ja');
  });

  test('chat language needs most messages in one language', () async {
    expect(await Translate.chatLanguage(['hello there', 'how are you', '안녕']), 'en');
    expect(await Translate.chatLanguage(['hello', '안녕']), 'en', reason: 'a tie keeps the first');
    expect(await Translate.chatLanguage(['hello', '안녕', '반가워']), 'ko');
    // A link's address doesn't make a Korean post English.
    expect(await Translate.chatLanguage(['이번 주 이야기 https://citywalk.example/stories/alley-bookshops', '안녕하세요 여러분']), 'ko');
    expect(await Translate.chatLanguage([]), isNull);
  });
}
