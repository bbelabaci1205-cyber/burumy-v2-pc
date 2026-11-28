// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 큰 이모지 (v1): one emoji on its own moves when we have its picture.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/moving_emoji.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('which texts move', () {
    expect(movingEmojiName('😂'), '1f602');
    expect(movingEmojiName(' 👍 '), '1f44d');
    expect(movingEmojiName('❤️'), '2764_fe0f');
    expect(movingEmojiName('❤'), '2764_fe0f');
    expect(movingEmojiName('😂😂'), isNull);
    expect(movingEmojiName('ㅋ'), isNull);
    expect(movingEmojiName('🦄'), isNull);
    expect(movingEmojiName(''), isNull);
    for (final n in movingEmojiNames) {
      expect(File('assets/animated_emoji/$n.json').existsSync(), isTrue, reason: n);
    }
  });

  testWidgets('a lone 😂 moves; two stay still big (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@mina:test');
    await fake.sendText(room, '😂');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('list-preview')).first);
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('moving-emoji-1f602')), findsOneWidget);
  });
}
