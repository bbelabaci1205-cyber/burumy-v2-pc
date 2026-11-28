// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 앱 아이콘 (v1): four marks, six characters, five other logos; every
// picture is in the app, and Android has a launcher alias for each.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/app_icon.dart';
import 'package:burumy/ui/settings_pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every icon has its picture, launcher icons and alias', () {
    expect(AppIconPicker.ids.length, 15);
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final kotlin = File('android/app/src/main/kotlin/app/burumy/burumy/MainActivity.kt').readAsStringSync();
    for (final id in AppIconPicker.ids) {
      expect(File('assets/app_icons/$id.png').existsSync(), isTrue, reason: id);
      expect(kotlin, contains('"$id"'), reason: id);
      if (id == 'green') continue;
      expect(manifest, contains('@mipmap/ic_launcher_$id"'), reason: id);
      expect(manifest, contains('android:name=".Icon${id[0].toUpperCase()}${id.substring(1)}"'), reason: id);
      for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
        expect(File('android/app/src/main/res/mipmap-$d/ic_launcher_$id.png').existsSync(), isTrue, reason: '$id $d');
      }
    }
  });

  testWidgets('the picker shows three groups and keeps the pick (ko)', (t) async {
    AppIconPicker.preview = true;
    addTearDown(() => AppIconPicker.preview = false);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    t.state<NavigatorState>(find.byType(Navigator).first).push(CupertinoPageRoute(builder: (_) => const AppearancePage()));
    await t.pumpAndSettle();
    final picker = find.byType(AppIconPicker);
    await t.scrollUntilVisible(find.byKey(const Key('app-icon-logo_nest')), 300, scrollable: find.descendant(of: find.byType(AppearancePage), matching: find.byType(Scrollable)).first);
    expect(picker, findsOneWidget);
    expect(find.text('캐릭터'), findsOneWidget);
    expect(find.text('다른 로고'), findsOneWidget);
    expect(find.text('로고 F'), findsOneWidget);
    for (final id in AppIconPicker.ids) {
      expect(find.byKey(Key('app-icon-$id')), findsOneWidget, reason: id);
    }
    await t.ensureVisible(find.byKey(const Key('app-icon-dugi')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('app-icon-dugi')));
    await t.pumpAndSettle();
    expect(state.pref('app_icon', 'green'), 'dugi');
  });
}
