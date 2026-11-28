// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기: guide → sample file → check → progress ring →
// done, then the chat shows the import line and "가져옴" bubbles in the
// original order with day lines. Also the send/receive round trip.
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/chat_import.dart';
import 'package:burumy/core/chat_import_send.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/demo/import_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_import_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

const _png = [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, //
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1f, 0x15, 0xc4, 0x89, 0x00, 0x00, 0x00, 0x0d, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9c, 0x63, 0xf8, 0xcf, 0xc0, 0xf0,
  0x1f, 0x00, 0x05, 0x00, 0x01, 0xff, 0x89, 0x99, 0x3d, 0x1d, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
];

void main() {
  setUp(() => Features.chatImport = true);
  tearDown(() {
    Features.chatImport = false;
    ImportDemo.sample = null;
  });

  test('sent import comes back checked, in order, with me and the 1:1 partner linked', () async {
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@mina:test');
    final (name, bytes) = demoImportFile(true, _png);
    final b = ChatImport.read(name, bytes);
    final chat = b.chats.single;
    final steps = <String>[];
    final n = await ImportSender(fake).send(
      room,
      ImportChoice(chat: chat, files: b.files, me: '나', peer: '김민지', peerId: '@mina:test'),
      myId: '@me:test',
      onProgress: (p) => steps.add(p.step),
    );
    expect(n, chat.items.length);
    expect(steps, containsAllInOrder(['media', 'pack', 'send']));
    final card = (await fake.timeline(room)).last;
    expect(card.card?.kind, 'import');
    expect(card.card!.data['count'], n);
    expect(card.card!.data['media'], 1, reason: 'the one photo in the zip');
    final got = await fake.importedMessages(room, card.id);
    final msgs = got.toMsgs(card.id, '@me:test');
    expect(msgs.length, n);
    expect(msgs.first.body, '메리 크리스마스! 🎄');
    expect(msgs.first.sender, '@mina:test');
    expect(msgs[1].mine, isTrue);
    expect(msgs.where((m) => m.kind == 'image').single.imported!.file, isNotNull);
    expect(msgs.where((m) => m.kind == 'missing').single.imported!.missing, 'video');
    for (var i = 1; i < msgs.length; i++) {
      expect(msgs[i].time.isBefore(msgs[i - 1].time), isFalse);
    }
  });

  test('importing the same chat twice is noticed before it goes in', () async {
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@mina:test');
    final (name, bytes) = demoImportFile(true, _png);
    final chat = ChatImport.read(name, bytes).chats.single;
    expect(await importedBefore(fake, room, chat), isFalse);
    await ImportSender(fake).send(
      room,
      ImportChoice(chat: chat, files: ChatImport.read(name, bytes).files, me: '나'),
      myId: '@me:test',
    );
    expect(await importedBefore(fake, room, chat), isTrue);
  });

  test('in a group nobody else can be linked to an account', () async {
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final group = await fake.createGroup('가족', ['@mina:test']);
    final (name, bytes) = demoImportFile(true, _png);
    final b = ChatImport.read(name, bytes);
    await ImportSender(fake).send(
      group,
      ImportChoice(chat: b.chats.single, files: b.files, me: '나', peer: '김민지', peerId: '@mina:test'),
      myId: '@me:test',
    );
    final card = (await fake.timeline(group)).last;
    final got = await fake.importedMessages(group, card.id);
    expect(got.people.firstWhere((p) => p.name == '김민지').id, '', reason: 'only the 1:1 partner may be linked');
    expect(got.people.firstWhere((p) => p.name == '나').id, '@me:test');
  });

  testWidgets('guide → sample → check → ring → done → bubbles in the chat (ko)', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@mina:test');
    fake.names[room] = '김민지';
    ImportDemo.sample = () => demoImportFile(true, _png);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(
      nav.push(
        CupertinoPageRoute<void>(
          builder: (_) => ImportGuidePage(roomId: room, title: '김민지'),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('카카오톡에서 내보내는 방법'), findsOneWidget);
    await t.tap(find.byKey(const Key('import-app-telegram')));
    await t.pumpAndSettle();
    expect(find.text('텔레그램에서 내보내는 방법'), findsOneWidget);
    expect(find.byKey(const Key('import-device')), findsNothing, reason: 'Telegram exports only on a computer');
    await t.tap(find.byKey(const Key('import-app-kakao')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('import-sample')), 200, scrollable: find.byType(Scrollable).last);
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('import-sample')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await t.pumpAndSettle();
    expect(find.byKey(const Key('import-check')), findsOneWidget);
    expect(find.text('메시지 10개'), findsWidgets);
    // "나" is guessed as me; 김민지 becomes the chat partner's bubbles.
    expect(find.byKey(const Key('import-peer-info')), findsOneWidget);
    await t.scrollUntilVisible(find.byKey(const Key('import-go')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const Key('import-go')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('import-confirm')));
    // Uploads and packing run on other threads: let real time pass.
    for (var i = 0; i < 40 && find.byKey(const Key('import-done-check')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('import-done-check')), findsOneWidget);
    expect(find.text('메시지 10개를 가져왔어요!'), findsOneWidget);
    await t.tap(find.byKey(const Key('import-see')));
    await t.pumpAndSettle();
    final card = (await fake.timeline(room)).last;
    expect(card.card?.kind, 'import');

    // The chat: the import line, then the old messages by their own dates.
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.pumpAndSettle();
    expect(find.byKey(Key('import-line-${card.id}')), findsOneWidget);
    expect(find.text('카카오톡에서 대화를 가져왔어요 · 메시지 10개'), findsOneWidget);
    expect(find.text('좋아, 카톡 대화 내보내서 가져올게'), findsOneWidget);
    expect(find.byKey(const Key('imported-mark')), findsWidgets);
    expect(find.text('2025년 3월 2일 (일)'), findsOneWidget, reason: 'day line above the first message of that day');
    // Holding an imported message: only reply (as a quote) and copy.
    await t.longPress(find.text('좋아, 카톡 대화 내보내서 가져올게'));
    await t.pumpAndSettle();
    expect(find.text('답장'), findsWidgets);
    expect(find.text('고정'), findsNothing);
    await t.tap(find.text('답장').last);
    await t.pumpAndSettle();
    // The info sheet from the line.
    await t.tap(find.byKey(Key('import-line-${card.id}')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('import-info')), findsOneWidget);
    expect(find.byKey(const Key('import-delete')), findsOneWidget);
  });
}
