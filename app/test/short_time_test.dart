// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Chat-list dates, Telegram style: today = time, this week = weekday, older = numbers.
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('today / this week / older', (t) async {
    late BuildContext ctx;
    await t.pumpWidget(
      CupertinoApp(
        locale: const Locale('ko'),
        localizationsDelegates: const [L.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
        supportedLocales: L.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final now = DateTime(2026, 11, 25, 8, 30); // Wednesday
    expect(shortTime(ctx, DateTime(2026, 11, 25, 7, 5), now: now), contains('7:05'));
    expect(shortTime(ctx, DateTime(2026, 11, 24, 21), now: now), '화');
    expect(shortTime(ctx, DateTime(2026, 11, 19, 9), now: now), '목');
    expect(shortTime(ctx, DateTime(2026, 11, 18, 9), now: now), '11.18');
    expect(shortTime(ctx, DateTime(2025, 3, 2, 9), now: now), '25.3.2');
  });
}
