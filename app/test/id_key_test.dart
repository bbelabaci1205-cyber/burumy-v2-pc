// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 아이디 키: a stranger's first 1:1 chat comes in only with the right key;
// friends are not asked; the key page saves and turns off; the new-chat
// screen sends a proof (never the key).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/id_key.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/id_key_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  test('proof: same key in any case/spaces, tied to both IDs, never the key', () {
    final p = IdKey.proof('Blue 7', from: '@a:t', to: '@b:t');
    expect(p, IdKey.proof('blue7', from: '@a:t', to: '@b:t'));
    expect(p, startsWith('bk1:'));
    expect(p.contains('blue7'), isFalse);
    expect(p == IdKey.proof('blue7', from: '@c:t', to: '@b:t'), isFalse);
    expect(IdKey.valid('abc'), isFalse);
    expect(IdKey.valid('blue7'), isTrue);
    expect(IdKey.valid('파란별7'), isTrue);
    expect(IdKey.valid('no-dash!'), isFalse);
  });

  test('only the right proof lets a stranger in', () async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await state.setPref(IdKey.pref, 'blue7');
    final me = fake.userId!;
    fake.invites.addAll([
      const Invite(roomId: '!nokey', name: '', inviter: '@spam:test', direct: true),
      const Invite(roomId: '!wrong', name: 'bk1:wrong', inviter: '@spam2:test', direct: true),
      Invite(
        roomId: '!ok',
        name: IdKey.proof('blue7', from: '@jisoo:test', to: me),
        inviter: '@jisoo:test',
        direct: true,
      ),
    ]);
    await state.refresh();
    expect(fake.rooms.containsKey('!ok'), isTrue);
    expect(fake.rooms.containsKey('!nokey'), isFalse);
    expect(fake.rooms.containsKey('!wrong'), isFalse);
    // Waiting unseen, not declined (the sender isn't told).
    expect(fake.invites.map((i) => i.roomId), containsAll(['!nokey', '!wrong']));

    // Turning the key off lets the waiting first chats in.
    await state.setPref(IdKey.pref, '');
    await state.refresh();
    expect(fake.rooms.containsKey('!nokey'), isTrue);
  });

  test('people I already talk with are not asked', () async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@mina:test');
    await state.setPref(IdKey.pref, 'blue7');
    fake.invites.add(const Invite(roomId: '!g', name: '', inviter: '@mina:test', direct: true));
    await state.refresh();
    expect(fake.rooms.containsKey('!g'), isTrue);
  });

  testWidgets('key page saves, rejects a bad key, turns off; new chat sends the proof (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(CupertinoPageRoute(builder: (_) => const IdKeyPage()));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('id-key-field')), 'ab');
    await t.tap(find.byKey(const Key('id-key-save')));
    await t.pumpAndSettle();
    expect(find.text('글자나 숫자로 4~20자를 써 주세요.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('id-key-field')), 'Blue7');
    await t.tap(find.byKey(const Key('id-key-save')));
    await t.pumpAndSettle();
    expect(state.pref(IdKey.pref, ''), 'blue7');

    nav.push(CupertinoPageRoute(builder: (_) => const IdKeyPage()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('id-key-off')));
    await t.pumpAndSettle();
    expect(state.pref(IdKey.pref, ''), '');

    // My side: a chat with someone's key carries only the proof.
    await fake.createDirectChat('@jisoo:test', idKey: 'Sun 42');
    expect(fake.dmProofs['@jisoo:test'], IdKey.proof('sun42', from: fake.userId!, to: '@jisoo:test'));
  });
}
