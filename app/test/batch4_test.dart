// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 4 (2026-11-27): pins (bar steps, list, notify line),
// message links, pick-text copy, channel share arrow, saved tab, read time,
// invite-blocked links.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/read_times.dart';
import 'package:burumy/core/room_links.dart';
import 'package:burumy/core/saved_tags.dart';
import 'package:burumy/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  Future<void> pinVia(WidgetTester t, String text, {bool notify = true}) async {
    await t.longPress(find.text(text).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    if (!notify) {
      await t.tap(find.byKey(const Key('pin-notify')));
      await t.pumpAndSettle();
    }
    await t.tap(find.byKey(const Key('pin-for-0')));
    await t.pumpAndSettle();
  }

  testWidgets('group pins: notify line, bar steps back, list page', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('우리 팀', ['@mina:test']);
    await b.sendText(g, '첫 번째 공지');
    await b.sendText(g, '두 번째 공지');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await pinVia(t, '첫 번째 공지');
    await pinVia(t, '두 번째 공지', notify: false);
    expect(b.pinned(g), hasLength(2));
    // Two "메시지를 고정했어요" lines; only the first one rings.
    final lines = b.rooms[g]!.where((m) => m.card?.kind == 'pin').toList();
    expect(lines.map((m) => m.card!.data['notify']), [true, false]);
    expect(find.textContaining('메시지를 고정했어요'), findsNWidgets(2));
    // Newest pin first, then each tap steps to the one before.
    expect(find.text('고정 메시지 #2'), findsOneWidget);
    expect(find.byKey(const Key('pin-segments')), findsOneWidget);
    await t.tap(find.byKey(const Key('pinned-bar-tap')));
    await t.pumpAndSettle();
    expect(find.text('고정 메시지 #1'), findsOneWidget);
    await t.tap(find.byKey(const Key('pinned-list')));
    await t.pumpAndSettle();
    expect(find.text('고정 메시지 2개'), findsOneWidget);
    expect(find.byKey(const Key('unpin-all')), findsOneWidget);
    await t.tap(find.byKey(const Key('unpin-all')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('unpin-all-ok')));
    await t.pumpAndSettle();
    expect(b.pinned(g), isEmpty);
    expect(find.byKey(const Key('pinned-bar')), findsNothing);
    s.stopLive();
  });

  test('message links: only our own link with a chat and a message', () {
    final l = MessageLink('!room:x', r'$ev1');
    final back = MessageLink.parse('see ${l.url} here')!;
    expect((back.roomId, back.eventId), ('!room:x', r'$ev1'));
    expect(l.url, startsWith('https://${RoomLinks.host}/m#'));
    expect(MessageLink.parse('https://other.app/m#r=!a&e=b'), isNull);
    expect(MessageLink.parse('https://${RoomLinks.host}/m#r=nope&e=b'), isNull);
  });

  testWidgets('copy message link, then tapping it jumps (members only)', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('우리 팀', ['@mina:test']);
    await b.sendText(g, '목차로 쓸 글');
    for (var i = 0; i < 40; i++) {
      await b.sendText(g, '잡담 $i');
    }
    await s.refresh();
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String;
      return null;
    });
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.longPress(find.text('잡담 39').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-link')));
    await t.pumpAndSettle();
    expect(copied, contains('/m#r='));
    expect(find.text('링크를 복사했어요. 이 대화방 멤버만 열 수 있어요.'), findsOneWidget);
    final first = b.rooms[g]!.first.id;
    await b.sendText(g, MessageLink(g, first).url);
    await s.refresh();
    await t.pumpAndSettle();
    expect(find.text('목차로 쓸 글'), findsNothing);
    await t.tap(find.textContaining('/m#r=').last);
    await t.pumpAndSettle();
    expect(find.text('목차로 쓸 글'), findsOneWidget);
    s.stopLive();
  });

  testWidgets('pick part of a message to copy (not in 공유 비활성화 chats)', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '주소는 서울시 강남구 테헤란로 1 이에요');
    await s.refresh();
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String;
      return null;
    });
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.textContaining('테헤란로').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-select-text')), findsOneWidget);
    await t.longPress(find.descendant(of: find.byKey(const Key('menu-select-text')), matching: find.textContaining('테헤란로')));
    await t.pumpAndSettle();
    final btn = find.byType(CupertinoTextSelectionToolbarButton);
    expect(btn, findsWidgets);
    await t.tap(btn.first);
    await t.pumpAndSettle();
    expect(copied, isNotNull);
    expect(copied!.length, lessThan('주소는 서울시 강남구 테헤란로 1 이에요'.length));
    expect(find.text('글자를 복사했어요'), findsOneWidget);
    s.stopLive();
  });

  testWidgets('channel post share arrow: several chats + a word at once', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('부루미 소식', const [], channel: true);
    await b.sendText(ch, '새 기능이 나왔어요');
    final ann = await b.createDirectChat('ann');
    final bob = await b.createDirectChat('bob');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('부루미 소식'));
    await t.pumpAndSettle();
    final post = b.rooms[ch]!.last.id;
    await t.tap(find.byKey(Key('share-$post')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('share-to-$ann')));
    await t.tap(find.byKey(Key('share-to-$bob')));
    await t.pumpAndSettle();
    expect(find.text('보내기 2'), findsOneWidget);
    await t.enterText(find.byKey(const Key('share-word')), '이거 봐');
    await t.tap(find.byKey(const Key('share-send')));
    await t.pumpAndSettle();
    expect(find.text('2곳에 전달했어요'), findsOneWidget);
    for (final r in [ann, bob]) {
      expect(b.rooms[r]!.map((m) => m.body), containsAllInOrder(['이거 봐', '새 기능이 나왔어요']));
    }
    s.stopLive();
  });

  testWidgets('chat info 저장 tab lists what I saved from this chat', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '회의는 3시예요');
    await b.sendText(room, '그냥 인사');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('회의는 3시예요').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-save')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tag-💡')));
    await t.pumpAndSettle();
    expect(savedFrom(s).values, [room]);
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await t.scrollUntilVisible(find.byKey(const Key('info-tabs')), 200, scrollable: list);
    await t.pumpAndSettle();
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('saved-here')), findsOneWidget);
    expect(find.text('💡 회의는 3시예요'), findsOneWidget);
    expect(find.textContaining('그냥 인사'), findsNothing);
    s.stopLive();
  });

  test('read times: first receipt that covers the message, 7 days only', () {
    final t0 = DateTime(2026, 11, 27, 10);
    var raw = ReadTimes.add('', t0, t0.add(const Duration(minutes: 3)), t0)!;
    raw = ReadTimes.add(raw, t0.add(const Duration(hours: 1)), t0.add(const Duration(hours: 2)), t0)!;
    expect(ReadTimes.add(raw, t0, t0, t0), isNull);
    expect(ReadTimes.of(raw, t0.subtract(const Duration(minutes: 1)), t0), t0.add(const Duration(minutes: 3)));
    expect(ReadTimes.of(raw, t0.add(const Duration(minutes: 30)), t0), t0.add(const Duration(hours: 2)));
    expect(ReadTimes.of(raw, t0.add(const Duration(hours: 3)), t0), isNull);
    expect(ReadTimes.of(raw, t0, t0.add(const Duration(days: 8))), isNull);
  });

  testWidgets('1:1 my message menu shows when it was read; hidden when I hide ticks', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await b.sendText(room, '도착하면 연락해');
    b.readAt = b.now.add(const Duration(minutes: 1));
    b.readWhen = DateTime(b.now.year, b.now.month, b.now.day, 20, 38);
    b.now = b.now.add(const Duration(hours: 1));
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob'));
    await t.pumpAndSettle();
    await t.longPress(find.text('도착하면 연락해').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-header')), findsOneWidget);
    expect(find.text('읽음 · 오늘 오후 8:38'), findsOneWidget);
    await t.tapAt(const Offset(30, 120));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-header')), findsNothing);
    await s.setPref('send_read:$room', '0');
    await t.pumpAndSettle();
    await t.longPress(find.text('도착하면 연락해').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-reply')), findsOneWidget);
    expect(find.byKey(const Key('menu-header')), findsNothing);
    s.stopLive();
  });

  testWidgets('people who only take invitations from contacts get the link', (t) async {
    final (b, s) = await app(t);
    final g = await b.createGroup('우리 팀', ['@mina:test']);
    b.contactsOnly.add('@zed:test');
    await b.inviteUsers(g, ['@zed:test']);
    expect((await b.members(g)).any((m) => m.userId == '@zed:test'), isFalse);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await t.scrollUntilVisible(find.byKey(const Key('info-invites-blocked')), 200, scrollable: list);
    await t.pumpAndSettle();
    await Scrollable.ensureVisible(t.element(find.byKey(const Key('info-invites-blocked'))), alignment: 0.5);
    await t.pumpAndSettle();
    expect(find.text('초대를 막은 사람 1명'), findsOneWidget);
    await t.tap(find.byKey(const Key('info-invites-blocked')));
    await t.pumpAndSettle();
    expect(find.text('1명이 초대를 막았어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('send-invite-link')));
    await t.pumpAndSettle();
    final dm = b.rooms.entries.firstWhere((e) => e.key != g && e.value.isNotEmpty && (e.value.last.body ?? '').contains('/join#'));
    expect(dm.value.last.mine, isTrue);
    expect(find.byKey(const Key('info-invites-blocked')), findsNothing);
    await t.pump(const Duration(seconds: 5));
    s.stopLive();
  });
}
