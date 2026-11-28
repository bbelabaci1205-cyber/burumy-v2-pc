// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 그룹·채널 사진 (v1): admins set it, every avatar of the room shows it, the
// chat says who changed it, and it can be taken off.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final png = File('assets/demo/photo.png').readAsBytesSync();

  testWidgets('room photo: set, shown, line in chat, removed (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    // No photo yet: the letter tile.
    expect(find.byType(Image), findsNothing);

    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-edit')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('room-photo-change')), findsOneWidget);
    await t.tap(find.byKey(const Key('room-photo')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('room-photo-new')), findsOneWidget);
    expect(find.byKey(const Key('room-photo-remove')), findsNothing);
    expect(find.textContaining('암호화'), findsOneWidget);
    await t.tap(find.text('취소'));
    await t.pumpAndSettle();

    // What the picker + cropper hand over.
    await t.runAsync(() => state.setRoomPhoto(team, png));
    await t.pumpAndSettle();
    expect(fake.roomPhotos[team], png);
    expect(find.byType(Image), findsWidgets);
    expect(fake.rooms[team]!.last.kind, 'room_photo');

    await t.tap(find.byKey(const Key('room-photo')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('room-photo-remove')));
    await t.pumpAndSettle();
    expect(fake.roomPhotos[team], isNull);
    expect(fake.rooms[team]!.last.body, 'removed');

    // Back in the chat: both lines.
    await t.tap(find.byKey(const Key('room-save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.text('그룹 사진을 바꿨어요'), findsOneWidget);
    expect(find.text('그룹 사진을 지웠어요'), findsOneWidget);
  });

  testWidgets('someone else\'s change says who (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    fake.roomPhotos[team] = png;
    fake.rooms[team]!.add(Msg(id: 'p1', sender: '@mina:test', body: 'set', time: DateTime.now(), mine: false, kind: 'room_photo'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    expect(find.byType(Image), findsWidgets);
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    expect(find.textContaining('사진을 바꿨어요'), findsOneWidget);
    expect(find.textContaining('님이 그룹 사진을'), findsOneWidget);
  });

  test('a public link peek carries the room photo', () async {
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    fake.outside['seoul_runners'] = const LinkPeek(roomId: '!sr', name: '서울 러너스', channel: true);
    expect((await fake.peekAddress('seoul_runners')).photo, isNull);
    fake.roomPhotos['!sr'] = png;
    expect((await fake.peekAddress('seoul_runners')).photo, png);
  });
}
