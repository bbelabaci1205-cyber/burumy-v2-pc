// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screen flow in both languages and both brand colours: sign up -> chat
// list -> new chat -> send -> settings.
import 'dart:async';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/main.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:burumy/ui/chat_page.dart';

import 'package:burumy/core/voice.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/ui/attach_sheet.dart';
import 'package:burumy/ui/location.dart';
import 'package:burumy/ui/bubbles.dart';
import 'package:burumy/ui/common.dart' show Avatar, setMyPhotoFor, joinName;
import 'package:burumy/ui/chat_list_page.dart' show ChatRowTile;
import 'package:burumy/ui/chat_page.dart' show ChatPage;

import 'fake_backend.dart';
import 'fake_voice.dart';

void main() {
  test('contact name: Korean 성+이름, others first last', () {
    expect(joinName('민수', '김', 'ko'), '김민수');
    expect(joinName('Minsu', 'Kim', 'en'), 'Minsu Kim');
    expect(joinName(' 민수 ', '', 'ko'), '민수');
    expect(joinName('', '김', 'en'), '김');
  });

  for (final lang in ['ko', 'en']) {
    for (final f in BrandFamily.values) {
      testWidgets('flow $lang / ${f.name}', (t) async {
        final ko = lang == 'ko';
        final state = AppState(FakeBackend(), family: f, locale: Locale(lang));
        await t.pumpWidget(BurumyApp(state: state));
        await t.pumpAndSettle();
        expect(find.text(ko ? '아이디로 시작해요' : 'Start with an ID'), findsOneWidget);

        // Weak password is refused with the rule text.
        await t.enterText(find.byKey(const Key('auth-id')), 'eric');
        await t.enterText(find.byKey(const Key('auth-pw')), 'short');
        await t.tap(find.byKey(const Key('auth-submit')));
        await t.pump();
        expect(find.textContaining(ko ? '8자 이상' : '8 or more'), findsOneWidget);

        await t.enterText(find.byKey(const Key('auth-pw')), 'Secret123');
        await t.tap(find.byKey(const Key('auth-submit')));
        await t.pumpAndSettle();
        expect(find.text(ko ? '아직 대화가 없어요' : 'No chats yet'), findsOneWidget);

        await t.tap(find.byKey(const Key('new-chat')));
        await t.pumpAndSettle();
        expect(find.text(ko ? '새 대화' : 'New Chat'), findsOneWidget);
        await t.enterText(find.byType(CupertinoTextField).last, '@bob:test');
        await t.tap(find.text(ko ? '시작' : 'Start'));
        await t.pumpAndSettle();
        expect(find.textContaining(ko ? '종단간 암호화' : 'end-to-end encrypted'), findsOneWidget);

        await t.enterText(find.byKey(const Key('composer')), ko ? '안녕' : 'Hi');
        await t.pump();
        await t.tap(find.byKey(const Key('send')));
        await t.pump(const Duration(milliseconds: 300));
        expect(find.text(ko ? '안녕' : 'Hi'), findsOneWidget);
        state.stopLive();
      });
    }
  }

  testWidgets('contacts, photo, read tick, recovery key (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('bob');
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // Contacts tab lists the 1:1 partner and finds new people by ID.
    await t.tap(find.text('연락처').last);
    await t.pumpAndSettle();
    expect(find.text('bob'), findsOneWidget);
    await t.enterText(find.byKey(const Key('people-search')), 'carol');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    expect(find.text('@carol'), findsOneWidget);

    // Open the chat from contacts, send text + photo, then the other side reads.
    await t.enterText(find.byKey(const Key('people-search')), '');
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '사진 보낼게요');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tick-sent')), findsOneWidget);
    await t.runAsync(() async {
      await fake.sendFile(room, name: 'photo.png', mime: 'image/png', bytes: File('test/assets/sample_photo.png').readAsBytesSync());
    });
    fake.readAt = DateTime(2030);
    state.notifyListeners();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('tick-read')), findsNWidgets(2));
    expect(find.byType(Image), findsOneWidget);

    // Settings -> enter recovery key on a full screen.
    Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
    await t.pumpAndSettle();
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('backup-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('backup-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('enter-key')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('recovery-key')), 'one two three');
    await t.tap(find.byKey(const Key('recovery-submit')));
    await t.pumpAndSettle();
    expect(find.text('예전 대화를 열었어요'), findsOneWidget);
    expect(fake.recovery, isTrue);
    state.stopLive();
  });

  testWidgets('group, channel, reply, edit, delete with undo (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@bob:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // New group: tick bob, name it, land in the chat.
    await t.tap(find.byKey(const Key('new-chat')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-group')));
    await t.pumpAndSettle();
    expect(find.text('멤버 추가'), findsOneWidget);
    await t.tap(find.text('@bob:test'));
    await t.pump();
    await t.tap(find.byKey(const Key('members-next')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('chat-name')), '우리 팀');
    await t.tap(find.byKey(const Key('create-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsOneWidget);
    expect(fake.groups.length, 1);

    // Send, reply to it, edit the reply, delete then undo, delete for real.
    await t.enterText(find.byKey(const Key('composer')), '첫 글');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    await t.longPress(find.text('첫 글'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-reply')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mode-bar')), findsOneWidget);
    await t.enterText(find.byKey(const Key('composer')), '답장');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quote')), findsOneWidget);

    await t.longPress(find.text('답장'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-edit')));
    await t.pumpAndSettle();
    expect(find.text('메시지 수정'), findsOneWidget);
    await t.enterText(find.byKey(const Key('composer')), '고친 답장');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.text('고친 답장'), findsOneWidget);
    expect(find.byKey(const Key('edited')), findsOneWidget);

    await t.longPress(find.text('고친 답장'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-delete')));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('고친 답장'), findsNothing);
    expect(find.byKey(const Key('undo-bar')), findsOneWidget);
    await t.tap(find.byKey(const Key('undo')));
    await t.pump();
    expect(find.text('고친 답장'), findsOneWidget);

    await t.longPress(find.text('고친 답장'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-delete')));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('undo-bar')), findsNothing);
    expect(fake.rooms.values.expand((m) => m).where((m) => m.body == '고친 답장'), isEmpty);

    // Someone typing shows under the title.
    final g = fake.groups.first;
    fake.typing[g] = ['@bob:test'];
    state.notifyListeners();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('typing')), findsOneWidget);

    // Channel: owner can write; as a subscriber the composer is gone.
    Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-chat')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-channel')));
    await t.pumpAndSettle();
    expect(find.textContaining('나만 글을 쓸 수 있어요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('chat-name')), '부루미 소식');
    await t.tap(find.byKey(const Key('create-chat')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsOneWidget);
    fake.owner = false;
    state.notifyListeners();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsNothing);
    expect(find.byKey(const Key('read-only')), findsOneWidget);
    state.stopLive();
  });

  testWidgets('app lock: three passwords, hide and delete (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@hid:test');
    await fake.createDirectChat('@del:test');
    await fake.createDirectChat('@keep:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // Settings > App Lock > first password (rule enforced, twice).
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('privacy-row')));
    await t.tap(find.byKey(const Key('privacy-row')));
    await t.pumpAndSettle();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('app-lock')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lock-set-first')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('password-new')), 'short');
    await t.enterText(find.byKey(const Key('password-again')), 'short');
    await t.tap(find.byKey(const Key('password-save')));
    await t.pump();
    expect(find.textContaining('8자 이상'), findsOneWidget);
    await t.enterText(find.byKey(const Key('password-new')), 'normal123');
    await t.enterText(find.byKey(const Key('password-again')), 'normal123');
    await t.tap(find.byKey(const Key('password-save')));
    await t.pumpAndSettle();
    expect(fake.normalPw, 'normal123');

    // Managed view: hide + delete passwords and lists.
    await t.tap(find.byKey(const Key('lock-hide')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('password-new')), 'normal123');
    await t.enterText(find.byKey(const Key('password-again')), 'normal123');
    await t.tap(find.byKey(const Key('password-save')));
    await t.pump();
    expect(find.text('다른 비밀번호와 같아요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('password-new')), 'hide12345');
    await t.enterText(find.byKey(const Key('password-again')), 'hide12345');
    await t.tap(find.byKey(const Key('password-save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lock-delete')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('password-new')), 'delete123');
    await t.enterText(find.byKey(const Key('password-again')), 'delete123');
    await t.tap(find.byKey(const Key('password-save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('lock-list-0')));
    await t.pumpAndSettle();
    await t.tap(find.text('@hid:test'));
    await t.pump();
    await t.tap(find.byKey(const Key('quiet-save')));
    await t.pumpAndSettle();
    expect(find.text('1개 골랐어요'), findsOneWidget);
    fake.deleteList = ['@del:test'];

    // Lock. Wrong password says so; the hide password opens normally.
    await state.checkLock();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lock-password')), findsOneWidget);
    await t.enterText(find.byKey(const Key('lock-password')), 'nope12345');
    await t.tap(find.byKey(const Key('lock-open')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('lock-wrong')), findsOneWidget);
    await t.enterText(find.byKey(const Key('lock-password')), 'hide12345');
    await t.tap(find.byKey(const Key('lock-open')));
    await t.pumpAndSettle();
    expect(state.locked, isFalse);
    expect(fake.hideOn, isTrue);
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.text('@hid:test'), findsOneWidget); // visible inside a hide session

    // Next normal session: hidden. Delete session: erased too.
    await state.checkLock();
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lock-password')), 'normal123');
    await t.tap(find.byKey(const Key('lock-open')));
    await t.pumpAndSettle();
    expect(find.text('@hid:test'), findsNothing);
    expect(find.text('@keep:test'), findsOneWidget);
    await state.checkLock();
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('lock-password')), 'delete123');
    await t.tap(find.byKey(const Key('lock-open')));
    await t.pumpAndSettle();
    expect(find.text('@del:test'), findsNothing);
    expect(find.text('@keep:test'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('streaks show in the list and can be switched off (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final a = await fake.createDirectChat('@ann:test');
    final b = await fake.createDirectChat('@ben:test');
    fake.streaks[a] = (7, false);
    fake.streaks[b] = (4, true);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('streak')), findsNWidgets(2));
    expect(find.text('7'), findsOneWidget);
    expect(find.byKey(const Key('streak-risk')), findsOneWidget);
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('chats-row')));
    await t.tap(find.byKey(const Key('chats-row')));
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('streak-switch')));
    await t.tap(find.byKey(const Key('streak-switch')));
    await t.pumpAndSettle();
    expect(fake.streaksOn, isFalse);
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('streak')), findsNothing);
    state.stopLive();
  });

  testWidgets('sticker panel sends a built-in sticker (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@ann:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sticker-panel')), findsOneWidget);
    await t.tap(find.byKey(const Key('sticker-tab-dugi')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('sticker-dugi_01_hello')));
    await t.pumpAndSettle();
    expect(fake.rooms[room]!.last.kind, 'sticker');
    expect(fake.rooms[room]!.last.body, 'dugi_01_hello');
    expect(find.byKey(const Key('sticker-msg')), findsOneWidget);
    // Recently sent comes first; a pack switched off disappears.
    expect(state.pref('recent_stickers', ''), 'dugi_01_hello');
    await state.setPref('pack_off:dugi', '1');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sticker-tab-recent')), findsOneWidget);
    expect(find.byKey(const Key('sticker-tab-dugi')), findsNothing);
    // Emoji alone are shown big, without a bubble.
    await t.tap(find.byKey(const Key('sticker-button')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '😂👍');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('big-emoji')), findsOneWidget);
    state.stopLive();
  });

  testWidgets('reactions and pinned message (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@ann:test');
    await fake.sendText(room, '좋은 소식이에요');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    await t.longPress(find.text('좋은 소식이에요').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('react-❤️')));
    await t.pumpAndSettle();
    expect(find.text('❤️ 1'), findsOneWidget);
    await t.tap(find.byKey(const Key('reaction-❤️')));
    await t.pumpAndSettle();
    expect(find.text('❤️ 1'), findsNothing);
    await t.longPress(find.text('좋은 소식이에요').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('pinned-bar')), findsOneWidget);
    expect(find.text('고정된 메시지'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('disappearing messages timer (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@ann:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('timer-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('timer-86400')));
    await t.pumpAndSettle();
    expect(find.text('사라지는 메시지: 1일'), findsOneWidget);
    await t.enterText(find.byKey(const Key('composer')), '곧 사라져요');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('expires')), findsOneWidget);
    await t.tap(find.byKey(const Key('timer-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('timer-0')));
    await t.pumpAndSettle();
    expect(find.text('사라지는 메시지를 껐어요'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('view once photo opens one time only (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final room = await fake.createDirectChat('@ann:test');
    fake.files['once'] = File('test/assets/sample_photo.png').readAsBytesSync();
    fake.rooms[room]!.add(Msg(id: 'once', sender: '@ann:test', body: 'p.png', time: fake.now, mine: false, kind: 'image', viewOnce: true));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('@ann:test'));
    await t.pumpAndSettle();
    expect(find.text('눌러서 열기'), findsOneWidget);
    await t.tap(find.byKey(const Key('view-once')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('view-once-page')), findsOneWidget);
    await t.tap(find.byKey(const Key('view-once-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('view-once-opened')), findsOneWidget);
    await t.tap(find.byKey(const Key('view-once')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('view-once-page')), findsNothing);
    state.stopLive();
  });

  testWidgets('profile name and chat info with leave + undo (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final g = await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('my-profile')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('profile-name')), '에릭');
    await t.enterText(find.byKey(const Key('profile-bio')), '부루미 만드는 사람');
    await t.tap(find.byKey(const Key('profile-save')));
    await t.pumpAndSettle();
    expect(find.text('에릭'), findsOneWidget);
    expect(fake.bios.values, ['부루미 만드는 사람']);

    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    expect(find.text('멤버 2명'), findsOneWidget);
    expect(find.text('방장'), findsOneWidget);
    await revealInfo(t, find.byKey(const Key('leave')), 200);
    await t.ensureVisible(find.byKey(const Key('leave')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('leave')));
    await t.pump(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('leave-undo')));
    await t.pump(const Duration(seconds: 6));
    expect(fake.rooms.containsKey(g), isTrue);
    await t.tap(find.byKey(const Key('leave')));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(fake.rooms.containsKey(g), isFalse);
    expect(find.text('우리 팀'), findsNothing);
    state.stopLive();
  });

  testWidgets('1:1 info: ID, block, hide chat, read ticks, shared links (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    fake.bios['@bob:test'] = '밥이에요';
    fake.rooms[bob]!.add(Msg(id: 'l1', sender: '@bob:test', body: '여기 봐요 https://burumy.com/a', time: DateTime(2026, 11, 24), mine: false, kind: 'text'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('bob').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('veil')), findsNothing);
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('info-id')), findsOneWidget);
    expect(find.text('밥이에요'), findsOneWidget);
    await t.tap(find.byKey(const Key('info-block')));
    await t.pumpAndSettle();
    expect(fake.blockedIds, ['@bob:test']);
    expect(find.text('차단 풀기'), findsOneWidget);
    await revealInfo(t, find.byKey(Key('pref-veil_dots:$bob')), 150);
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('pref-veil_dots:$bob')));
    await t.pumpAndSettle();
    await revealInfo(t, find.byKey(Key('pref-send_read:$bob')), 150);
    await t.tap(find.byKey(Key('pref-send_read:$bob')));
    await t.pumpAndSettle();
    expect(await fake.readUntil(bob), isNull);
    await revealInfo(t, find.byKey(const Key('info-tabs')), 200);
    await t.tap(find.text('링크'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('shared-l1')), findsOneWidget);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('veil')), findsWidgets);
    state.stopLive();
  });

  testWidgets('1:1 more menu: my name and note, timer, clear my side (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    fake.rooms[bob]!.add(Msg(id: 'o1', sender: '@bob:test', body: '옛날 이야기', time: DateTime(2026, 11, 20), mine: false, kind: 'text'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('bob').first);
    await t.pumpAndSettle();
    expect(find.text('옛날 이야기'), findsOneWidget);
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-edit')));
    await t.pumpAndSettle();
    expect(find.textContaining('님의 사진 설정'), findsOneWidget);
    await t.enterText(find.byKey(const Key('contact-first')), '선배');
    await t.enterText(find.byKey(const Key('contact-last')), '밥');
    await t.enterText(find.byKey(const Key('contact-memo')), '커피는 라떼');
    await t.tap(find.byKey(const Key('contact-save')));
    await t.pumpAndSettle();
    // 성 + 이름 (Korean order, no space).
    expect(state.pref('alias:@bob:test', ''), '밥선배');
    expect(find.text('밥선배'), findsWidgets);
    // A photo only I see replaces the letter avatar.
    await setMyPhotoFor(state, '@bob:test', base64Decode(_png1x1));
    await t.pumpAndSettle();
    expect(find.descendant(of: find.byType(Avatar).first, matching: find.byType(Image)), findsOneWidget);
    await setMyPhotoFor(state, '@bob:test', null);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('info-memo')), findsOneWidget);
    await t.tap(find.byKey(const Key('info-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('more-timer')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('timer-86400')));
    await t.pumpAndSettle();
    expect(await fake.timer(bob), 86400);
    await t.tap(find.byKey(const Key('info-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('more-clear')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('clear-ok')));
    await t.pumpAndSettle();
    expect(state.pref('cleared:$bob', ''), isNotEmpty);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('info-more')), findsNothing);
    expect(find.text('옛날 이야기'), findsNothing);
    expect(fake.rooms[bob]!.any((m) => m.id == 'o1'), isTrue);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byType(ChatPage), findsNothing);
    expect(find.descendant(of: find.byType(ChatRowTile), matching: find.text('밥선배')), findsOneWidget);
    state.stopLive();
  });

  testWidgets('chat list: swipe buttons, delete with undo, hide from list (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    final g = await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // Swipe left: mute, delete, archive.
    await t.drag(find.text('우리 팀'), const Offset(-200, 0));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('swipe-mute')));
    await t.pumpAndSettle();
    expect(fake.mutedChats, contains(g));
    // Swipe right: pin.
    await t.drag(find.text('bob'), const Offset(100, 0));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('swipe-pin')));
    await t.pumpAndSettle();
    expect(state.chats.firstWhere((c) => c.roomId == bob).pinned, isTrue);
    // While a row is open, tapping it only closes it (does not open the chat).
    await t.drag(find.text('bob'), const Offset(100, 0));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('swipe-pin')), findsOneWidget);
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('swipe-pin')), findsNothing);
    expect(find.byType(ChatPage), findsNothing);

    // Delete: gone at once, 5 s to undo.
    await t.drag(find.text('우리 팀'), const Offset(-200, 0));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('swipe-delete')));
    await t.pump();
    expect(find.text('우리 팀'), findsNothing);
    expect(find.byKey(const Key('list-undo-bar')), findsOneWidget);
    await t.tap(find.byKey(const Key('list-undo')));
    await t.pump(const Duration(seconds: 6));
    expect(fake.rooms.containsKey(g), isTrue);
    expect(find.text('우리 팀'), findsOneWidget);
    await t.drag(find.text('우리 팀'), const Offset(-200, 0));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('swipe-delete')));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(fake.rooms.containsKey(g), isFalse);

    // Hide from the list (long-press menu), show again from settings.
    final gesture = await t.startGesture(t.getCenter(find.text('bob')));
    await t.pump(const Duration(milliseconds: 900));
    await t.pumpAndSettle();
    await gesture.up();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-peek')), findsWidgets);
    await t.tap(find.byKey(const Key('menu-hide')));
    await t.pumpAndSettle();
    expect(find.text('bob'), findsNothing);
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('chats-row')));
    await t.tap(find.byKey(const Key('chats-row')));
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('hidden-chats-row')));
    await t.tap(find.byKey(const Key('hidden-chats-row')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('unhide-$bob')));
    await t.pumpAndSettle();
    expect(state.on('list_hidden:$bob'), isFalse);
    state.stopLive();
  });

  testWidgets('chat list: long swipe runs the edge action (Telegram)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    final g = await fake.createGroup('우리 팀', ['@mina:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    // Far left: one long grey bar, letting go archives.
    final g1 = await t.startGesture(t.getCenter(find.text('우리 팀')));
    for (var i = 0; i < 10; i++) {
      await g1.moveBy(const Offset(-30, 0));
      await t.pump();
    }
    expect(find.byKey(const Key('swipe-full')), findsOneWidget);
    await g1.up();
    await t.pumpAndSettle();
    expect(fake.archivedChats, contains(g));
    // Far right: long bar, letting go pins.
    final g2 = await t.startGesture(t.getCenter(find.text('bob')));
    for (var i = 0; i < 10; i++) {
      await g2.moveBy(const Offset(30, 0));
      await t.pump();
    }
    expect(find.byKey(const Key('swipe-full')), findsOneWidget);
    await g2.up();
    await t.pumpAndSettle();
    expect(state.chats.firstWhere((c) => c.roomId == bob).pinned, isTrue);
  });

  testWidgets('side menu: filters, search, new folder, folder chips (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('@bob:test');
    await fake.createDirectChat('@helpbot:test');
    final g = await fake.createGroup('우리 팀', ['@mina:test']);
    final ch = await fake.createGroup('공지', [], channel: true);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-search')), findsNothing); // hidden by default

    Future<void> pick(String f) async {
      await t.tap(find.byKey(const Key('side-menu-button')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('filter-$f')));
      await t.pumpAndSettle();
    }

    await pick('channel');
    expect(find.text('공지'), findsWidgets);
    expect(find.text('우리 팀'), findsNothing);
    await pick('bot');
    expect(find.text('@helpbot:test'), findsOneWidget);
    expect(find.text('@bob:test'), findsNothing);
    await pick('group');
    expect(find.text('우리 팀'), findsOneWidget);
    expect(find.text('@bob:test'), findsNothing);
    await pick('all');

    // A folder with groups + bob by hand.
    await t.tap(find.byKey(const Key('side-menu-button')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('new-folder')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('folder-name')), '일');
    await t.tap(find.byKey(const Key('folder-add-include')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pick-kind-group')));
    await t.pumpAndSettle();
    await revealInfo(t, find.byKey(Key('folder-chat-$ch')), 150);
    unawaited(Scrollable.ensureVisible(t.element(find.byKey(Key('folder-chat-$ch'))), alignment: 0.5));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('folder-chat-$ch')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pick-done')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('folder-kind-group')), findsOneWidget);
    expect(find.byKey(Key('folder-has-$ch')), findsOneWidget);
    await t.tap(find.byKey(const Key('folder-save')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('side-menu')), findsOneWidget);
    await t.tap(find.text('일'));
    await t.pumpAndSettle();
    expect(find.text('우리 팀'), findsOneWidget);
    expect(find.text('@bob:test'), findsNothing);
    expect(find.text('공지'), findsWidgets);
    expect(g, isNotEmpty);

    // Chips on top when switched on.
    await state.setOn('list_top', true);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-search')), findsOneWidget);
    await t.tap(find.byKey(const Key('chip-all')));
    await t.pumpAndSettle();
    expect(find.text('@bob:test'), findsOneWidget);
    // Switched off again: search and chips leave the list.
    await state.setOn('list_top', false);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('chat-search')), findsNothing);
    expect(find.byKey(const Key('chip-all')), findsNothing);
    state.stopLive();
  });

  testWidgets('hold send: quietly, schedule, send now (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();

    await t.enterText(find.byKey(const Key('composer')), '쉿');
    await t.pump();
    await t.longPress(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send-quiet')));
    await t.pumpAndSettle();
    expect(fake.quietSent, ['쉿']);

    await t.enterText(find.byKey(const Key('composer')), '내일 봐요');
    await t.pump();
    await t.longPress(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send-later')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('schedule-ok')));
    await t.pumpAndSettle();
    expect(state.scheduled.single['text'], '내일 봐요');
    expect(fake.rooms[bob]!.where((m) => m.body == '내일 봐요'), isEmpty);
    await t.tap(find.byKey(const Key('scheduled-chip')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('sched-now-${state.scheduled.single['id']}')));
    await t.pumpAndSettle();
    expect(state.scheduled, isEmpty);
    expect(fake.rooms[bob]!.where((m) => m.body == '내일 봐요'), hasLength(1));
    state.stopLive();
  });

  testWidgets('chat list: pin, mute, archive, search (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('bob');
    final g = await fake.createGroup('우리 팀', ['@mina:test']);
    await fake.sendText(g, '안녕');
    await state.setOn('list_top', true);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    Future<void> act(String name, String key) async {
      // iOS long-press preview: hold, it lifts, then the menu stays.
      final g = await t.startGesture(t.getCenter(find.text(name)));
      await t.pump(const Duration(milliseconds: 900));
      await t.pumpAndSettle();
      await g.up();
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key(key)));
      await t.pumpAndSettle();
    }

    await act('bob', 'menu-pin');
    expect(state.chats.first.roomId, isNot(g));
    expect(find.byKey(const Key('pinned')), findsOneWidget);
    await act('우리 팀', 'menu-mute');
    expect(fake.mutedChats, contains(g));
    expect(find.byKey(const Key('muted')), findsOneWidget);

    // Search finds by name.
    await t.enterText(find.byKey(const Key('chat-search')), '팀');
    await t.pumpAndSettle();
    expect(find.text('bob'), findsNothing);
    expect(find.text('우리 팀'), findsOneWidget);
    await t.enterText(find.byKey(const Key('chat-search')), '');
    await t.pumpAndSettle();

    await act('우리 팀', 'menu-archive');
    // Gone from the list; only named in the archive row.
    expect(find.descendant(of: find.byKey(const Key('archive-row')), matching: find.text('우리 팀')), findsOneWidget);
    expect(find.text('우리 팀'), findsOneWidget);
    await t.tap(find.byKey(const Key('archive-row')));
    await t.pumpAndSettle();
    expect(find.text('우리 팀'), findsOneWidget);
    await act('우리 팀', 'menu-archive');
    expect(fake.archivedChats, isEmpty);
    state.stopLive();
  });

  testWidgets('forward a message and search inside a chat (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    await fake.sendText(bob, '회의는 4시예요');
    for (var i = 0; i < 40; i++) {
      await fake.sendText(bob, '잡담 $i');
    }
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();

    // Search from chat info: the old message is found and shown.
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('info-search')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('msg-search')), '4시');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('회의는 4시예요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('msg-search')), '잡담 1');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.text('1/11'), findsOneWidget);
    await t.tap(find.byKey(const Key('search-older')));
    await t.pumpAndSettle();
    expect(find.text('2/11'), findsOneWidget);
    expect(find.text('잡담 18'), findsOneWidget);
    await t.tap(find.byKey(const Key('search-cancel')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsOneWidget);

    // Forward the found message to the team (the chat stays where search left it).
    await t.longPress(find.text('잡담 18'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-forward')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('forward-to-$team')));
    await t.pumpAndSettle();
    expect(find.text('전달했어요'), findsOneWidget);
    expect(fake.rooms[team]!.last.body, '잡담 18');
    expect(fake.rooms[team]!.last.forwarded, isTrue);
    await t.pump(const Duration(seconds: 3));
    state.stopLive();
  });

  testWidgets('link card from my phone, switch in settings (ko)', (t) async {
    final fake = FakeBackend();
    fake.pages['https://news.test/a'] = const LinkCard(url: 'https://news.test/a', title: '오늘의 소식', site: 'news.test');
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '봐요 https://news.test/a');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('link-card')), findsOneWidget);
    expect(find.text('오늘의 소식'), findsOneWidget);
    Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
    await t.pumpAndSettle();

    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('data-row')));
    await t.tap(find.byKey(const Key('data-row')));
    await t.pumpAndSettle();
    await reveal(t, find.byKey(const Key('link-preview-switch')));
    await t.tap(find.byKey(const Key('link-preview-switch')));
    await t.pumpAndSettle();
    expect(fake.previewsOn, isFalse);
    await fake.sendText(bob, '다시 https://news.test/a');
    expect(fake.rooms[bob]!.last.preview, isNull);
    state.stopLive();
  });

  testWidgets('settings: security check, account, faq, tour, about, power value (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('security-check')), findsOneWidget);
    expect(find.textContaining('보안 점검'), findsWidgets);
    for (final (row, expectText) in const [('account-row', '내 아이디'), ('faq-row', '대화가 정말 안전한가요?'), ('tour-row', '끝에서 끝까지 암호화'), ('about-row', '버전 1.0.0')]) {
      await reveal(t, find.byKey(Key(row)));
      await t.tap(find.byKey(Key(row)));
      await t.pumpAndSettle();
      expect(find.text(expectText), findsWidgets, reason: row);
      if (row == 'faq-row') {
        await t.tap(find.byKey(const Key('faq-0')));
        await t.pumpAndSettle();
        expect(find.byKey(const Key('faq-a-0')), findsOneWidget);
      }
      await t.tap(find.byKey(const Key('back')).last);
      await t.pumpAndSettle();
    }
    await reveal(t, find.byKey(const Key('power-row')));
    expect(find.text('15% 미만일 때'), findsOneWidget);
    // Low battery pauses the moving effects.
    expect(state.calm, isFalse);
    state.battery = 10;
    expect(state.calm, isTrue);
    await state.setPref('power_below', '0');
    expect(state.calm, isFalse);
    state.stopLive();
  });

  testWidgets('privacy: undo send, hide all chats, panic gesture (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await state.setOn('undo_send', true);
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    // Undo send: waits, can be taken back into the field.
    await t.enterText(find.byKey(const Key('composer')), '앗 잘못 보냄');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pump();
    expect(find.byKey(const Key('send-undo-bar')), findsOneWidget);
    expect(fake.rooms[bob]!.where((m) => m.body == '앗 잘못 보냄'), isEmpty);
    await t.tap(find.byKey(const Key('send-undo')));
    await t.pump();
    expect(find.text('앗 잘못 보냄'), findsOneWidget); // back in the field
    await t.pump(const Duration(seconds: 6));
    expect(fake.rooms[bob]!.where((m) => m.body == '앗 잘못 보냄'), isEmpty);
    // ...or goes after 5 seconds.
    await t.tap(find.byKey(const Key('send')));
    await t.pump();
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.body == '앗 잘못 보냄').length, 1);
    // Hide all chats covers every chat.
    expect(veilOf(state, bob), '');
    await state.setOn('veil_all', true);
    expect(veilOf(state, bob), 'dots');
    // Panic: two-finger double tap locks (switch + app lock on).
    await fake.setNormalPassword('abcd1234');
    await state.setOn('panic', true);
    Future<void> twoFingerTap() async {
      final a = await t.startGesture(const Offset(150, 400), pointer: 7);
      final b = await t.startGesture(const Offset(240, 400), pointer: 8);
      await t.pump(const Duration(milliseconds: 60));
      await a.up();
      await b.up();
      await t.pump(const Duration(milliseconds: 120));
    }

    await twoFingerTap();
    expect(state.locked, isFalse);
    await twoFingerTap();
    await t.pump();
    expect(state.locked, isTrue);
    state.stopLive();
  });

  testWidgets('voice message: hold to record, slide to cancel, play (ko)', (t) async {
    VoiceKit.recorder = FakeRecorder.new;
    VoiceKit.player = FakePlayer.new;
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();

    // Empty composer shows the mic; a tap only explains.
    await t.tap(find.byKey(const Key('mic')));
    await t.pump();
    expect(find.text('길게 눌러 음성 메시지를 녹음해요'), findsOneWidget);

    // Hold, slide left: cancelled, nothing sent.
    final mic = t.getCenter(find.byKey(const Key('mic')));
    var g = await t.startGesture(mic);
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('recording')), findsOneWidget);
    await g.moveBy(const Offset(-120, 0));
    await t.pump();
    expect(find.text('놓으면 취소돼요'), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    expect(fake.rooms[bob], isEmpty);

    // Hold and let go: sent with its length.
    g = await t.startGesture(t.getCenter(find.byKey(const Key('mic'))));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('recording')), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.single.voice!.duration, const Duration(seconds: 4));
    expect(find.byKey(const Key('voice')), findsOneWidget);
    expect(find.text('0:04'), findsOneWidget);
    await t.tap(find.byKey(const Key('voice-play')));
    await t.pumpAndSettle();
    expect(FakePlayer.plays, 1);
    expect(find.text('0:01'), findsOneWidget);

    // Slide up: locked. Letting go keeps recording; trash throws it away.
    g = await t.startGesture(t.getCenter(find.byKey(const Key('mic'))));
    await t.pump(const Duration(milliseconds: 600));
    await g.moveBy(const Offset(0, -80));
    await t.pump();
    await g.up();
    await t.pump();
    expect(find.byKey(const Key('recording-locked')), findsOneWidget);
    await t.tap(find.byKey(const Key('rec-pause')));
    await t.pump();
    await t.tap(find.byKey(const Key('rec-trash')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.voice != null), hasLength(1));
    // Locked again, then sent with the round send button.
    g = await t.startGesture(t.getCenter(find.byKey(const Key('mic'))));
    await t.pump(const Duration(milliseconds: 600));
    await g.moveBy(const Offset(0, -80));
    await t.pump();
    await g.up();
    await t.pump();
    await t.tap(find.byKey(const Key('rec-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.voice != null), hasLength(2));
    await t.pump(const Duration(seconds: 3));
    state.stopLive();
  });

  testWidgets('attach sheet: two photos with a caption, view once, files (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    await state.refresh();
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    AttachSheet.debugPicker = (source) async => source == 'file'
        ? [
            PickedFile('report.pdf', Uint8List.fromList([1, 2, 3])),
          ]
        : [PickedFile('a.png', png), PickedFile('b.png', png)];
    addTearDown(() => AttachSheet.debugPicker = null);
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('bob').first);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '바다 사진이에요');
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('attach-sheet')), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-library')));
    await t.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);
    expect(find.byKey(const Key('attach-sel-0')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('attach-caption')), matching: find.text('바다 사진이에요')), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    final sent = fake.rooms[bob]!.where((m) => m.kind == 'image').toList();
    expect(sent.length, 2);
    expect(sent.first.caption, isNull);
    expect(sent.last.caption, '바다 사진이에요');
    expect(find.byKey(const Key('caption')), findsOneWidget);

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-library')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-sel-0')));
    await t.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-once')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('attach-once-pill')), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.viewOnce).length, 1);

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-file')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-pick-file')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('attach-once')), findsNothing, reason: 'files cannot be view-once');
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.kind == 'file').single.body, 'report.pdf');

    // 파일 tab: a photo from the gallery goes as a file (original), and
    // "최근에 보낸 파일" sends a file again.
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-file')));
    await t.pumpAndSettle();
    final again = fake.rooms[bob]!.where((m) => m.kind == 'file').single;
    expect(find.byKey(Key('attach-recent-${again.id}')), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-file-gallery')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.kind == 'file').length, greaterThan(1), reason: 'photo sent as a file');
    final before = fake.rooms[bob]!.where((m) => m.kind == 'file').length;
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-file')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(Key('attach-recent-${again.id}')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('attach-recent-${again.id}')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.kind == 'file').length, before + 1);
    expect(fake.rooms[bob]!.last.body, 'report.pdf');
    state.stopLive();
  });

  testWidgets('checklist: make, tick, add; others only when allowed (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    fake.rooms[team]!.add(
      Msg(
        id: 'theirs',
        sender: '@mina:test',
        body: '미나 목록',
        time: DateTime(2026, 11, 23, 9),
        mine: false,
        kind: 'checklist',
        checklist: const ChecklistInfo(title: '미나 목록', items: [ChecklistItem('i0', '미나 일')]),
      ),
    );
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('check-i0')).first);
    await t.pumpAndSettle();
    expect(fake.rooms[team]!.firstWhere((m) => m.id == 'theirs').checklist!.done, 0, reason: 'mina did not allow others to tick');
    expect(find.byKey(const Key('checklist-add-item')), findsNothing);

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-checklist')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('checklist-title')), '여행 준비');
    await t.enterText(find.byKey(const Key('checklist-item-0')), '여권');
    await t.tap(find.byKey(const Key('checklist-add')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('checklist-item-1')), '충전기');
    await t.tap(find.byKey(const Key('checklist-create')));
    await t.pumpAndSettle();
    final mine = fake.rooms[team]!.lastWhere((m) => m.kind == 'checklist');
    expect(mine.checklist!.items.map((i) => i.text), ['여권', '충전기']);
    expect(find.text('0/2 완료'), findsOneWidget);
    await t.tap(find.text('여권'));
    await t.pumpAndSettle();
    expect(find.text('1/2 완료'), findsOneWidget);
    await t.tap(find.byKey(const Key('checklist-add-item')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('checklist-new-item')), '우산');
    await t.tap(find.byKey(const Key('checklist-new-ok')));
    await t.pumpAndSettle();
    expect(find.text('1/3 완료'), findsOneWidget);
    expect(find.text('우산'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('event: make, answer, take back, cancel; contact card opens a chat (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    await fake.createDirectChat('@bob:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();

    Future<void> tool(String id) async {
      await t.tap(find.byKey(const Key('attach')));
      await t.pumpAndSettle();
      await showTab(t, 'attach-tab-$id');
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('attach-tab-$id')));
      await t.pumpAndSettle();
    }

    await tool('meetup');
    await t.enterText(find.byKey(const Key('meetup-title')), '송년회');
    await t.enterText(find.byKey(const Key('meetup-place')), '을지로');
    await t.tap(find.byKey(const Key('meetup-create')));
    await t.pumpAndSettle();
    final id = fake.rooms[team]!.lastWhere((m) => m.kind == 'meetup').id;
    expect(find.text('송년회'), findsOneWidget);
    await t.tap(find.byKey(const Key('meetup-yes')));
    await t.pumpAndSettle();
    expect(fake.rooms[team]!.firstWhere((m) => m.id == id).meetup!.yes, ['@me:test']);
    expect(find.text('갈게요 1'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byKey(const Key('meetup-yes')));
    await t.pumpAndSettle();
    expect(fake.rooms[team]!.firstWhere((m) => m.id == id).meetup!.yes, isEmpty, reason: 'tapping again takes it back');
    await t.tap(find.byKey(const Key('meetup-cancel')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('meetup-cancelled')), findsOneWidget);

    await tool('contact');
    await t.tap(find.byKey(const Key('pick-contact-@bob:test')));
    await t.pumpAndSettle();
    expect(fake.rooms[team]!.last.contact, '@bob:test');
    await t.tap(find.byKey(const Key('contact-message')));
    await t.pumpAndSettle();
    expect(find.byType(ChatPage), findsWidgets);
    expect(find.text('@bob'), findsWidgets);
    state.stopLive();
  });

  testWidgets('group tools: rename, about, add, admin, remove; channel hides subscribers (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test']);
    await fake.createDirectChat('@bob:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('info-edit')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('room-name')), '여행 팀');
    await t.enterText(find.byKey(const Key('room-about')), '12월 제주');
    await t.tap(find.byKey(const Key('room-switch')));
    await t.tap(find.byKey(const Key('room-save')));
    await t.pumpAndSettle();
    expect(fake.names[team], '여행 팀');
    expect(await fake.roomSwitch(team, 'hide_members'), isTrue);
    expect(find.byKey(const Key('info-about')), findsOneWidget);
    expect(find.text('여행 팀'), findsWidgets);

    await reveal(t, find.byKey(const Key('info-add-member')));
    await t.tap(find.byKey(const Key('info-add-member')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('add-@bob:test')));
    await t.pump();
    await t.tap(find.byKey(const Key('add-members-ok')));
    await t.pumpAndSettle();
    expect((await fake.members(team)).map((m) => m.userId), contains('@bob:test'));

    await revealInfo(t, find.byKey(const Key('member-@bob:test')), 150);
    await t.tap(find.byKey(const Key('member-@bob:test')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('member-admin')));
    await t.pumpAndSettle();
    expect((await fake.members(team)).firstWhere((m) => m.userId == '@bob:test').role, 'admin');
    await revealInfo(t, find.byKey(const Key('member-@mina:test')), 150);
    await t.tap(find.byKey(const Key('member-@mina:test')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('member-remove')));
    await t.pumpAndSettle();
    expect((await fake.members(team)).map((m) => m.userId), isNot(contains('@mina:test')));
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();

    // A subscriber sees the count, never who else follows.
    final ch = await fake.createGroup('소식', ['@mina:test'], channel: true);
    fake.owner = false;
    await state.refresh();
    await t.pumpAndSettle();
    await t.tap(find.text('소식'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('member-@mina:test')), findsNothing);
    expect(find.byKey(const Key('info-edit')), findsNothing);
    expect(find.textContaining('구독자 2명'), findsWidgets);
    expect(ch, isNotEmpty);
    state.stopLive();
  });

  testWidgets('polls: make, vote, results, retract, close (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('우리 팀', ['@mina:test', '@leo:test']);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-poll')));
    await t.pumpAndSettle();
    expect(find.text('새 투표'), findsOneWidget);
    await t.enterText(find.byKey(const Key('poll-question')), '점심 뭐 먹을까요?');
    await t.enterText(find.byKey(const Key('poll-option-0')), '국수');
    await t.enterText(find.byKey(const Key('poll-option-1')), '비빔밥');
    await t.tap(find.byKey(const Key('poll-add')));
    await t.pump();
    await t.enterText(find.byKey(const Key('poll-option-2')), '김밥');
    // Anonymous is on by default; switch it off for a public poll.
    await t.tap(find.byKey(const Key('poll-anonymous')));
    await t.pump();
    expect(find.textContaining('멤버 모두에게 보여요'), findsOneWidget);
    await t.tap(find.byKey(const Key('poll-create')));
    await t.pumpAndSettle();
    final poll = fake.rooms[team]!.last;
    expect(poll.poll!.anonymous, isFalse);
    expect(find.byKey(const Key('poll')), findsOneWidget);
    expect(find.text('공개 투표'), findsOneWidget);

    fake.seedVotes(team, poll.id, {
      '@mina:test': ['a1'],
      '@leo:test': ['a1'],
    });
    await state.refresh();
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-a0')));
    await t.pumpAndSettle();
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(find.byKey(const Key('poll-mine')), findsOneWidget);
    expect(find.text('3명 투표'), findsOneWidget);

    await t.longPress(find.text('점심 뭐 먹을까요?'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-retract')));
    await t.pumpAndSettle();
    expect(find.text('2명 투표'), findsOneWidget);
    expect(find.byKey(const Key('poll-mine')), findsNothing);

    await t.longPress(find.text('점심 뭐 먹을까요?'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-close-poll')));
    await t.pumpAndSettle();
    expect(find.text('마감된 투표'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    state.stopLive();
  });

  testWidgets('bubbles: send one, pop one once (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    fake.receiveBubble(bob, '@bob:test', 'text', utf8.encode('🥳'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    // The waiting bubble shows who, not what.
    expect(find.byKey(const Key('bubble-strip')), findsOneWidget);
    expect(find.text('🥳'), findsNothing);
    await t.tap(find.byType(SoapBubble).first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('bubble-emoji')), findsOneWidget);
    await t.tap(find.byKey(const Key('bubble-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('bubble-strip')), findsNothing);
    expect(await fake.pendingBubbles(), isEmpty);

    // Send one back.
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    expect(find.text('터뜨렸어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await showTab(t, 'attach-tab-bubble');
    await t.tap(find.byKey(const Key('attach-tab-bubble')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('bubble-emoji-😘')));
    await t.pumpAndSettle();
    expect(find.text('비눗방울을 보냈어요'), findsOneWidget);
    expect(fake.rooms[bob]!.last.bubble, isTrue);
    state.stopLive();
  });

  testWidgets('live photo grid and location (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    await state.refresh();
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    Phone.debugRecent = (_) async => [PhoneMedia('p1', png), PhoneMedia('p2', png, video: true, duration: const Duration(seconds: 75))];
    Phone.debugLoad = (id) async => (id == 'p1' ? 'sea.png' : 'clip.mp4', png);
    Phone.debugLocation = () async => const GeoFix(37.5665, 126.978, 12);
    addTearDown(() {
      Phone.debugRecent = null;
      Phone.debugLoad = null;
      Phone.debugLocation = null;
    });
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('bob').first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('attach-live-p1')), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-live-p1')));
    await t.pumpAndSettle();
    await t.dragUntilVisible(find.byKey(const Key('attach-live-p2')), find.byType(GridView), const Offset(0, -150));
    await t.pumpAndSettle();
    expect(find.text('1:15'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-live-p2')));
    await t.pumpAndSettle();
    expect(find.text('2개 선택'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-live-p2')));
    await t.pumpAndSettle();
    expect(find.text('1개 선택'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.where((m) => m.kind == 'image').length, 1);

    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await showTab(t, 'attach-tab-location');
    await t.tap(find.byKey(const Key('attach-tab-location')));
    await t.pumpAndSettle();
    expect(find.text('정확도 약 12m'), findsOneWidget);
    await t.tap(find.byKey(const Key('location-send')));
    await t.pumpAndSettle();
    final loc = fake.rooms[bob]!.last;
    expect(loc.kind, 'location');
    expect(find.byKey(Key('location-${loc.id}')), findsOneWidget);
    expect(GeoPoint.parse(loc.body)!.lat, closeTo(37.5665, 1e-6));

    // No permission: says so and offers Settings, nothing is sent.
    Phone.debugLocation = () async => throw const PhoneError('denied');
    final before = fake.rooms[bob]!.length;
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await showTab(t, 'attach-tab-location');
    await t.tap(find.byKey(const Key('attach-tab-location')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('location-settings')), findsOneWidget);
    expect(find.byKey(const Key('location-send')), findsNothing);
    expect(fake.rooms[bob]!.length, before);
    state.stopLive();
  });
}

/// Scrolls a row into the middle of the screen (clear of the glass bars).
Future<void> reveal(WidgetTester t, Finder f) async {
  await revealInfo(t, f, 150);
  unawaited(Scrollable.ensureVisible(t.element(f), alignment: 0.5));
  await t.pumpAndSettle();
}

/// The attach tab bar scrolls sideways and builds tabs lazily.
Future<void> showTab(WidgetTester t, String key) async {
  final bar = find
      .descendant(of: find.byKey(const Key('attach-sheet')), matching: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.right))
      .last;
  await t.dragUntilVisible(find.byKey(Key(key)), bar, const Offset(-120, 0));
  await t.pumpAndSettle();
}

/// Scrolls an info page until [f] shows, then out from under the clear top
/// bar (content scrolls behind it, as on iPhone).
Future<void> revealInfo(WidgetTester t, Finder f, double step) async {
  final list = find.byType(Scrollable).last;
  await t.scrollUntilVisible(f, step, scrollable: list);
  await t.pumpAndSettle();
  if (t.getRect(f).top < 90) {
    await t.drag(list, const Offset(0, 120));
    await t.pumpAndSettle();
  }
}

const _png1x1 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
