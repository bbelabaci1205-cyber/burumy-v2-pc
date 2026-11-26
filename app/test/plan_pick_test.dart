// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/plan_pick.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';

import 'fake_backend.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 25, 10, 0); // Wednesday
  DateTime? one(String s) {
    final h = findPlans(s, now);
    return h.isEmpty ? null : h.single.at;
  }

  test('finds dates and times', () {
    expect(one('내일 3시에 볼까요?'), DateTime(2026, 11, 26, 15));
    expect(one('12월 7일 오후 7시 모임'), DateTime(2026, 12, 7, 19));
    expect(one('토요일 저녁 6시 반'), DateTime(2026, 11, 28, 18, 30));
    expect(one('다음 주 월요일 오전 10시'), DateTime(2026, 12, 7, 10));
    expect(one('오늘 오후 2시 30분'), DateTime(2026, 11, 25, 14, 30));
    expect(one('3시에 봐'), DateTime(2026, 11, 25, 15));
    expect(one('모레'), DateTime(2026, 11, 27, 9));
  });

  test('ignores vague or past ones', () {
    expect(one('3시간 걸렸어'), isNull);
    expect(one('그냥 얘기'), isNull);
    expect(one('오늘 오전 8시'), isNull);
    expect(findPlans('내일 3시에 봐', now).single.start, 0);
  });

  testWidgets('formatted messages switch and dotted plans (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    await fake.sendText(bob, '**굵게** 내일 3시에 봐');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@bob:test').first);
    await t.pumpAndSettle();
    bool raw() => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('**굵게**')).evaluate().isNotEmpty;
    expect(raw(), isFalse);
    await state.setOn('formatting', false);
    await t.pumpAndSettle();
    expect(raw(), isTrue);
    await state.setOn('formatting', true);
    await state.setOn('plan_pick', true);
    await t.pumpAndSettle();
    final dotted = find.byWidgetPredicate((w) {
      if (w is! RichText) return false;
      var hit = false;
      w.text.visitChildren((s) {
        if (s is TextSpan && s.style?.decorationStyle == TextDecorationStyle.dotted && s.text == '내일 3시') hit = true;
        return !hit;
      });
      return hit;
    });
    expect(dotted, findsOneWidget);
    state.stopLive();
  });
}
