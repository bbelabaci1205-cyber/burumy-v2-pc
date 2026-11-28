// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// IP review 2026-11-27 (Eric card A): Android's Google AI only for 18+
// (asked once on the first ✨ tap), and 설정 > 오픈소스·출처 with the
// credits (MET Norway, Google ML Kit, Pretendard, PDQ) and Rust notices.
import 'package:burumy/core/ai_age.dart';
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/licenses.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/settings_more.dart' show LicensesPage;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ai_editor_test.dart' show FakeAi, long;
import 'fake_backend.dart';

void main() {
  late FakeAi ai;
  Future<AppState> chat(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    ai = FakeAi();
    LocalAi.engine = ai;
    LocalAi.reset();
    await LocalAi.status();
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    LocalAi.blocked = () => !AiAge.allowed(s);
    addTearDown(() => LocalAi.blocked = () => false);
    await b.login(id: 'me', password: 'x');
    await b.createDirectChat('bob');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), long);
    await t.pump();
    return s;
  }

  group('Android AI age check', () {
    setUp(() => AiAge.debugAndroid = true);
    tearDown(() => AiAge.debugAndroid = false);

    testWidgets('first ✨ tap asks; under 18 = no AI, "18세 이상만 쓸 수 있어요"', (t) async {
      final s = await chat(t);
      await expectLater(LocalAi.run(rules: 'r', text: 'x'), throwsA(isA<AiError>().having((e) => e.code, 'code', 'age')));
      await t.tap(find.byKey(const Key('ai-button')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('ai-age-sheet')), findsOneWidget);
      expect(find.text('만 18세 이상이에요'), findsOneWidget);
      await t.tap(find.byKey(const Key('ai-age-minor')));
      await t.pump();
      expect(find.text('18세 이상만 쓸 수 있어요'), findsOneWidget);
      await t.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byKey(const Key('ai-editor')), findsNothing);
      expect(s.pref(AiAge.key, ''), 'minor');
      expect(await LocalAi.available(), isFalse);
      // Asked only once: next tap shows the notice, no question.
      await t.tap(find.byKey(const Key('ai-button')));
      await t.pump();
      expect(find.byKey(const Key('ai-age-sheet')), findsNothing);
      expect(find.text('18세 이상만 쓸 수 있어요'), findsOneWidget);
      await t.pumpAndSettle(const Duration(seconds: 3));
      expect(ai.asked, isEmpty);
    });

    testWidgets('18 or older: the AI 편집기 opens and works', (t) async {
      final s = await chat(t);
      await t.tap(find.byKey(const Key('ai-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('ai-age-adult')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('ai-editor')), findsOneWidget);
      expect(s.pref(AiAge.key, ''), 'adult');
      expect(LocalAi.blocked(), isFalse);
    });
  });

  testWidgets('iPhone: no age question, the AI 편집기 opens right away', (t) async {
    AiAge.debugAndroid = false;
    
    await chat(t);
    await t.tap(find.byKey(const Key('ai-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('ai-age-sheet')), findsNothing);
    expect(find.byKey(const Key('ai-editor')), findsOneWidget);
  });

  test('Rust notices: one entry per licence text, crate names without versions', () {
    final got = parseRustNotices(
      '@@@ MIT License\nfoo 1.0.0|bar 0.2.1|foo 1.1.0\nPermission is hereby granted\n@@@ Apache License 2.0\nbaz 3.0.0\nApache text\n',
    );
    expect(got.length, 2);
    expect(got.first.packages, ['foo', 'bar']);
    expect(got.last.paragraphs.map((p) => p.text).join(), 'Apache text');
  });

  testWidgets('오픈소스·출처: credits first, then every part (Dart, Rust, font)', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pump(const Duration(seconds: 1));
    t.state<NavigatorState>(find.byType(Navigator).first).push(IosPageRoute<void>(builder: (_) => const LicensesPage()));
    // The licence list loads from real files (Flutter's list, rust.txt).
    await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('오픈소스·출처'), findsWidgets);
    for (final k in ['credit-weather', 'credit-google', 'credit-font', 'credit-pdq']) {
      expect(find.byKey(Key(k)), findsOneWidget);
    }
    expect(find.text('MET Norway · CC BY 4.0'), findsOneWidget);
    await t.tap(find.byKey(const Key('credit-google')));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.textContaining('POWERED BY GOOGLE'), findsOneWidget);
  });
}
