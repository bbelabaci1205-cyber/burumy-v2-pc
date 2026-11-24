// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/formatting.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plain text drops the marks', () {
    expect(plainText('**굵게** __기울임__ ++밑줄++ ~~줄~~ `코드` ||비밀|| [링크](https://a.b)'), '굵게 기울임 밑줄 줄 코드 비밀 링크');
    expect(plainText('> 인용\n보통'), '인용\n보통');
    expect(plainText('2**3 = 8'), '2**3 = 8');
  });

  test('wrap selection', () {
    final c = TextEditingController(text: '안녕 친구');
    c.selection = const TextSelection(baseOffset: 3, extentOffset: 5);
    wrapSelection(c, '**');
    expect(c.text, '안녕 **친구**');
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    wrapSelection(c, '', url: 'https://burumy.com');
    expect(c.text, '[안녕](https://burumy.com) **친구**');
  });

  testWidgets('spoiler opens on tap; marks never shown', (t) async {
    await t.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: FormattedText(
            'a **b** ||secret|| `c`',
            style: TextStyle(color: Color(0xFF000000)),
            linkColor: Color(0xFF0000FF),
            quoteColor: Color(0xFF00FF00),
          ),
        ),
      ),
    );
    final rich = t.widget<RichText>(find.byType(RichText).first);
    final txt = rich.text.toPlainText();
    expect(txt, 'a b secret c');
    TextStyle? spoilerStyle() {
      TextStyle? found;
      rich.text.visitChildren((s) {
        if (s is TextSpan && s.text == 'secret') found = s.style;
        return true;
      });
      return found;
    }

    expect(spoilerStyle()?.color, const Color(0x00000000));
  });

  testWidgets('a link hiding a different address asks first and shows the real one', (t) async {
    await t.pumpWidget(
      const CupertinoApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        home: Center(
          child: FormattedText(
            '[https://bank.com](https://evil.example/login)',
            style: TextStyle(color: Color(0xFF000000)),
            linkColor: Color(0xFF0000FF),
            quoteColor: Color(0xFF00FF00),
          ),
        ),
      ),
    );
    await t.tapOnText(find.textRange.ofSubstring('bank'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-real')), findsOneWidget);
    expect(find.text('https://evil.example/login'), findsOneWidget);
  });
}
