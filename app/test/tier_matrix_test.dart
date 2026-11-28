// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스토리 / 검색 / 보관함: one tier per swipe (비눗방울 sits in the chat rows), Android + iOS physics.

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'screens_test.dart' show sample;

void main() {
  for (final ios in [false, true]) {
    testWidgets('matrix ios=$ios', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      t.view.padding = const FakeViewPadding(top: 118, bottom: 68);
      addTearDown(t.view.reset);
      if (ios) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final b = sample(true);
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      s.settings = await b.settings();
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      final list = find.byType(CustomScrollView).first;
      String st() {
        bool vis(String k) {
          final f = find.byKey(Key(k));
          if (f.evaluate().isEmpty) return false;
          final r = t.getRect(f.first);
          return r.bottom > 118 / 3 + 60 + 2; // below the bar
        }

        return 'S${vis('stories-bar') ? 1 : 0} Q${vis('list-search') ? 1 : 0} A${vis('archive-row') ? 1 : 0}';
      }

      Future<void> slow(double d) async {
        final g = await t.startGesture(t.getCenter(list) + const Offset(0, 150));
        for (var i = 0; i < 30; i++) {
          await g.moveBy(Offset(0, -d / 30));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await t.pumpAndSettle();
      }

      Future<void> fling(double d) async {
        await t.fling(list, Offset(0, -d), 2500);
        await t.pumpAndSettle();
      }

      Future<void> pull() async {
        await t.fling(list, const Offset(0, 300), 2500);
        await t.pumpAndSettle();
      }

      final seen = <String>[st()];
      await fling(300);
      seen.add(st());
      await fling(300);
      seen.add(st());
      await fling(300);
      seen.add(st());
      await fling(300);
      seen.add(st());
      await pull();
      seen.add(st());
      await pull();
      seen.add(st());
      await t.drag(list, const Offset(0, 200));
      await t.pumpAndSettle();
      seen.add(st());
      await slow(400);
      seen.add(st());
      await slow(400);
      seen.add(st());
      await slow(400);
      seen.add(st());
      await pull();
      await pull();
      seen.add(st());
      await t.tap(find.byKey(const Key('stories-mini')));
      await t.pumpAndSettle();
      seen.add(st());
      for (var i = 0; i < 5; i++) {
        await fling(400);
        seen.add(st());
      }
      debugDefaultTargetPlatformOverride = null;
      // Exactly one tier changes per swipe, slow or flung (Eric 2026-11-26).
      expect(seen, [
        'S1 Q1 A0', 'S0 Q1 A0', 'S0 Q0 A0', 'S0 Q0 A0', 'S0 Q0 A0', //
        'S0 Q1 A0', 'S0 Q1 A1', 'S0 Q1 A1', 'S0 Q0 A1', 'S0 Q0 A0', 'S0 Q0 A0',
        'S0 Q1 A1', 'S1 Q1 A1', 'S0 Q1 A1', 'S0 Q0 A1', 'S0 Q0 A0', 'S0 Q0 A0', 'S0 Q0 A0',
      ]);
    });
  }
}
