// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 링크 3줄 요약 (4-app board, Viber 2025): under a received article link,
// 3줄 요약 fetches the page on this phone and its own AI writes three lines
// only I see. Phones without their own AI get no button.
import 'package:burumy/core/ai_local.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/reader.dart';
import 'package:burumy/demo/audio_reader_sample.dart';
import 'package:burumy/demo/demo_ai.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/post_summary.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

class _NoAi implements AiEngine {
  @override
  Future<AiStatus> status() async => AiStatus.unsupported;
  @override
  Future<String> run({required String rules, required String text}) async => throw const AiError('unsupported');
}

Future<AppState> app(WidgetTester t, AiEngine ai) async {
  t.view.physicalSize = const Size(1179, 2556);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  Features.tipsAiRead = true;
  LocalAi.engine = ai;
  LocalAi.reset();
  await LocalAi.status();
  final fake = FakeBackend();
  final state = AppState(fake, locale: const Locale('ko'));
  await fake.login(id: 'me', password: 'x');
  addAudioReaderSample(fake, true);
  Reader.debug = (u) async => demoArticle(u, true);
  addTearDown(() {
    Reader.debug = null;
    Features.tipsAiRead = false;
    LocalAi.engine = PhoneAi();
    LocalAi.reset();
  });
  await state.refresh();
  await t.pumpWidget(BurumyApp(state: state));
  await t.pumpAndSettle();
  await t.tap(find.text('도시 산책 매거진'));
  await t.pumpAndSettle();
  return state;
}

void main() {
  testWidgets('3줄 요약 under the link: three lines, kept, folds away', (t) async {
    final s = await app(t, DemoAi(delay: Duration.zero));
    final button = find.byKey(const Key('link-summary-cw2'));
    expect(button, findsOneWidget);
    expect(find.byKey(const Key('reader-open-cw2')), findsOneWidget);
    await t.ensureVisible(button);
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-summary-box')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('link-summary-box')), matching: find.textContaining('독립 서점 5곳')), findsOneWidget);
    expect(s.settings[PostSummary.key('link:cw2')], contains('독립 서점 5곳'));
    await t.ensureVisible(button);
    await t.pumpAndSettle();
    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-summary-box')), findsNothing);
  });

  testWidgets('no own AI on this phone: no 3줄 요약 (읽기 모드 stays)', (t) async {
    await app(t, _NoAi());
    expect(find.byKey(const Key('link-summary-cw2')), findsNothing);
    expect(find.byKey(const Key('reader-open-cw2')), findsOneWidget);
  });
}
