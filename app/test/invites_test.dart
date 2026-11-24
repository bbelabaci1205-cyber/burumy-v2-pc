// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Invitations: a 1:1 chat someone started opens on its own; group
// invitations show in the chat list with join / decline.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  testWidgets('1:1 invitation opens itself; group invitation join and decline (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    fake.invites.addAll(const [
      Invite(roomId: '!dm', name: '', inviter: '@mina:test', direct: true),
      Invite(roomId: '!g1', name: '주말 모임', inviter: '@jun:test', direct: false),
      Invite(roomId: '!g2', name: '광고 방', inviter: '@spam:test', direct: false),
    ]);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // The 1:1 chat is already in the list; no row asks about it.
    expect(fake.rooms.containsKey('!dm'), isTrue);
    expect(find.byKey(const Key('invite-!dm')), findsNothing);
    expect(find.text('주말 모임'), findsOneWidget);
    expect(find.text('초대한 사람 · @jun'), findsOneWidget);

    await t.tap(find.byKey(const Key('decline-!g2')));
    await t.pumpAndSettle();
    expect(find.text('광고 방'), findsNothing);
    expect(fake.rooms.containsKey('!g2'), isFalse);

    await t.tap(find.byKey(const Key('accept-!g1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('invite-!g1')), findsNothing);
    expect(fake.rooms.containsKey('!g1'), isTrue);
    expect(find.text('주말 모임'), findsOneWidget); // now a chat row
  });
}
