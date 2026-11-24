// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// A person's profile (Telegram + Instagram): story ring on the photo,
// today's stories as round pictures, ID with QR, Telegram's 그룹 tab.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('person profile: ring, stories, QR, groups tab', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.text('김민지').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('info-story-ring')), findsOneWidget);
    expect(find.byKey(const Key('info-stories')), findsOneWidget);
    expect(find.text('스토리 2개'), findsOneWidget);
    // Telegram order of the round buttons: call, video, mute, search, more.
    final xs = [
      for (final k in ['info-voice-call', 'info-video-call', 'info-mute', 'info-search', 'info-more']) t.getCenter(find.byKey(Key(k))).dx,
    ];
    expect([...xs]..sort(), xs);
    await t.tap(find.byKey(const Key('info-qr')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('my-qr-code')), findsOneWidget);
    expect(find.text('QR 코드'), findsWidgets);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    for (var i = 0; i < 6 && find.byKey(const Key('info-tabs')).hitTestable().evaluate().isEmpty; i++) {
      await t.drag(
        find.byKey(const Key('info-encryption')).hitTestable().evaluate().isEmpty
            ? find.byKey(const Key('info-tabs'))
            : find.byKey(const Key('info-encryption')),
        const Offset(0, -300),
      );
      await t.pumpAndSettle();
    }
    await t.tap(find.text('그룹').last);
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('common-empty')).evaluate().length +
          find.byWidgetPredicate((w) => w.key is ValueKey && '${(w.key as ValueKey).value}'.startsWith('common-!')).evaluate().length,
      greaterThan(0),
    );
  });
}
