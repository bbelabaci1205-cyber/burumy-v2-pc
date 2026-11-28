// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 1:1 info > 암호화: member status, 7-emoji check, device keys, and the
// in-chat request card.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(FakeBackend, String)> start(WidgetTester t, {void Function(FakeBackend b, String room)? before}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  final room = await b.createDirectChat('@mina:test');
  await b.sendText(room, '안녕');
  before?.call(b, room);
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('list-preview')).first);
  await t.pumpAndSettle();
  return (b, room);
}

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key)).last;
  await t.ensureVisible(f);
  await t.pumpAndSettle();
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('암호화 row → check with 7 emoji → verified', (t) async {
    final (b, _) = await start(t);
    await tap(t, 'chat-title');
    expect(find.text('확인 안 됨'), findsOneWidget);
    await tap(t, 'info-encryption');
    expect(find.text('이 대화는 종단간 암호화되어 있어요'), findsOneWidget);
    // Device keys (advanced), read in groups of four.
    await tap(t, 'enc-keys');
    expect(find.textContaining('mX3k Q9vT'), findsOneWidget);
    await t.tap(find.byKey(const Key('enc-start')));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('상대 휴대폰에서 수락하기를 기다리고 있어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 2));
    await t.pump();
    expect(find.byKey(const Key('verify-emoji')), findsOneWidget);
    expect(find.text('🐶'), findsOneWidget);
    await tap(t, 'verify-match');
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.byKey(const Key('verify-done')), findsOneWidget);
    expect(b.verifiedUsers, contains('@mina:test'));
    await tap(t, 'verify-close');
    expect(find.text('확인됨'), findsWidgets);
  });

  testWidgets('their request in the chat: accept, then "they don\'t match" cancels', (t) async {
    final (b, _) = await start(
      t,
      before: (b, room) {
        b.rooms[room]!.add(Msg(id: 'req1', sender: '@mina:test', body: 'verify', time: DateTime(2026, 11, 23, 20, 1), mine: false, kind: 'verify'));
        b.checks['req1'] = ['@mina:test', 'incoming', 0];
      },
    );
    expect(find.byKey(const Key('verify-open-req1')), findsOneWidget);
    await tap(t, 'verify-open-req1');
    expect(find.textContaining('보안 코드를 확인하자고'), findsOneWidget);
    await t.tap(find.byKey(const Key('verify-accept')));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    await tap(t, 'verify-nomatch');
    expect(find.text('확인이 취소됐어요'), findsOneWidget);
    expect(b.verifiedUsers, isEmpty);
    await tap(t, 'verify-close');
  });
}
