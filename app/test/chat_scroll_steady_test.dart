// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/demo/fx_sample.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('한하윤 chat: scrolling toward newer never jumps back (photo rows keep their height)', (t) async {
    Features.funFx = true;
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    addFxSample(b, true);
    await t.runAsync(() async {
      await addCxSample(b, true);
      await addGifSample(b, true);
    });
    final s = AppState(b, locale: const Locale('ko'));
    await s.refresh();
    await t.pumpWidget(
      AppScope(
        state: s,
        child: CupertinoApp(
          locale: const Locale('ko'),
          localizationsDelegates: const [
            L.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L.supportedLocales,
          home: const ChatPage(roomId: '!fx-friend', title: '한하윤'),
        ),
      ),
    );
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    final list = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.up);
    final sc = t.state<ScrollableState>(list.first).position;
    await t.drag(list.first, const Offset(0, 3000));
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    for (var k = 0; k < 8; k++) {
      final before = sc.pixels;
      await t.drag(list.first, const Offset(0, -150));
      await t.pump();
      final after = sc.pixels;
      for (var i = 0; i < 30; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      if (before > 0) expect(after, lessThan(before), reason: 'drag $k went back');
    }
  });
}
