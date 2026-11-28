import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/phone_numbers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> found(String s) => [for (final (a, b) in findPhones(s)) s.substring(a, b)];

void main() {
  test('finds Korean and international numbers', () {
    expect(found('제 번호는 010-1234-5678 이에요'), ['010-1234-5678']);
    expect(found('01012345678로 연락'), ['01012345678']);
    expect(found('회사 02-123-4567, 고객센터 1588-1234'), ['02-123-4567', '1588-1234']);
    expect(found('call +82 10 1234 5678 now'), ['+82 10 1234 5678']);
    expect(found('+1 (415) 555-1234'), ['+1 (415) 555-1234']);
  });
  test('ignores dates, sums and codes', () {
    expect(found('2026-11-27 만나요'), isEmpty);
    expect(found('가격 1234567890원'), isEmpty);
    expect(found('인증번호 123456'), isEmpty);
    expect(found('https://x.com/0101234567890'), isNotEmpty); // links are cut out before this runs
  });
  test('dial digits', () => expect(dialDigits('+82 10-1234-5678'), '+821012345678'));

  testWidgets('a tap on a number opens call / text / copy / save, no Burumy lookup', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '연락 주세요 010-1234-5678');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.textContaining('010-1234-5678').first);
    await t.pumpAndSettle();
    await t.tapOnText(find.textRange.ofSubstring('010-1234-5678').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('phone-capsule')), findsOneWidget);
    for (final k in ['call', 'sms', 'copy', 'save']) {
      expect(find.byKey(Key('menu-phone-$k')), findsOneWidget);
    }
    expect(find.text('전화 걸기'), findsOneWidget);
    expect(find.textContaining('부루미에서 찾기'), findsNothing);
  });
}
