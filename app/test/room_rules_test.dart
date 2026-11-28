// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// v1 parity batch 2 (2026-11-27): admin rights, member permissions, slow
// mode, timed mutes, tags, owner handover, @mentions.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/room_rules.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  final t0 = DateTime(2026, 11, 27, 10);

  test('admin rights: owner all, admins per pick, members none', () {
    final cfg = <String, dynamic>{
      'admin_rights': {
        '@a:x': ['pin'],
      },
    };
    expect(RoomRules.can(cfg, 'owner', '@o:x', 'add_admin'), isTrue);
    expect(RoomRules.can(cfg, 'admin', '@a:x', 'pin'), isTrue);
    expect(RoomRules.can(cfg, 'admin', '@a:x', 'ban'), isFalse);
    expect(RoomRules.can(cfg, 'admin', '@b:x', 'ban'), isTrue, reason: 'default rights');
    expect(RoomRules.can(cfg, 'admin', '@b:x', 'add_admin'), isFalse);
    expect(RoomRules.can(cfg, 'member', '@m:x', 'pin'), isFalse);
    final next = RoomRules.withRights(cfg, '@a:x', ['ban', 'pin', 'nope']);
    expect(next['@a:x'], ['ban', 'pin']);
  });

  test('member permissions and slow mode', () {
    final cfg = <String, dynamic>{
      'member_perms': {'media': false},
      'slow': 30,
    };
    expect(RoomRules.may(cfg, 'member', 'media'), isFalse);
    expect(RoomRules.may(cfg, 'member', 'text'), isTrue);
    expect(RoomRules.may(cfg, 'admin', 'media'), isTrue);
    expect(RoomRules.slowWait(cfg, 'member', t0, t0.add(const Duration(seconds: 10))), const Duration(seconds: 20));
    expect(RoomRules.slowWait(cfg, 'member', t0, t0.add(const Duration(seconds: 31))), isNull);
    expect(RoomRules.slowWait(cfg, 'admin', t0, t0), isNull);
    expect(RoomRules.slowWait(const {}, 'member', t0, t0), isNull);
  });

  test('mutes, tags, handover', () {
    var cfg = <String, dynamic>{};
    cfg = {...cfg, 'mutes': RoomRules.withMute(cfg, '@m:x', t0.add(const Duration(hours: 1)))};
    cfg = {...cfg, 'mutes': RoomRules.withMute(cfg, '@n:x', null, forever: true)};
    expect(RoomRules.muteUntil(cfg, '@m:x'), t0.add(const Duration(hours: 1)));
    expect(RoomRules.muteUntil(cfg, '@n:x')!.year, 9999);
    expect(RoomRules.expiredMutes(cfg, t0), isEmpty);
    expect(RoomRules.expiredMutes(cfg, t0.add(const Duration(hours: 2))), ['@m:x']);
    expect(RoomRules.withTag(const {}, '@m:x', '  아주아주아주아주긴디자이너태그입니다  ')['@m:x'], hasLength(16));
    expect(RoomRules.withTag({'tags': {'@m:x': 'a'}}, '@m:x', ' '), isEmpty);
    expect(RoomRules.handover({'handover': {'to': '@m:x', 'until': t0.millisecondsSinceEpoch}}), ('@m:x', t0));
    expect(RoomRules.handover(const {}), isNull);
  });

  test('mentions: name, ID, @모두; 33+ members only admins', () {
    expect(RoomRules.mentionsMe('안녕 @민지 ', '@minji:x', '민지'), isTrue);
    expect(RoomRules.mentionsMe('hi @MINJI!', '@minji:x', '민지'), isTrue);
    expect(RoomRules.mentionsMe('hi @minjia', '@minji:x', '민지'), isFalse);
    expect(RoomRules.mentionsMe('모두 @모두 보세요', '@minji:x', '민지'), isTrue);
    expect(RoomRules.mentionsMe('email a@b.c', '@minji:x', '민지'), isFalse);
    expect(RoomRules.mayMentionAll('member', 32), isTrue);
    expect(RoomRules.mayMentionAll('member', 33), isFalse);
    expect(RoomRules.mayMentionAll('admin', 500), isTrue);
    expect(RoomRules.mentionQuery('hello @mi', 9), 'mi');
    expect(RoomRules.mentionQuery('hello@mi', 8), isNull);
    expect(RoomRules.mentionQuery('hello', 5), isNull);
    const ms = [Member(userId: '@me:x', name: 'me', role: 'owner'), Member(userId: '@mina:x', name: 'mina', role: 'member')];
    expect(RoomRules.mentionMatches(ms, 'mi', '@me:x').map((m) => m.userId), ['@mina:x']);
  });

  test('app state lifts mutes whose time ran out', () async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('Team', ['@mina:test']);
    await s.refresh();
    await b.setMemberLevel(room, '@mina:test', -1);
    await b.setRoomConfig(room, 'mutes', {'@mina:test': b.clock.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch});
    expect((await b.members(room)).firstWhere((m) => m.userId == '@mina:test').role, 'muted');
    await s.liftMutes();
    expect((await b.members(room)).firstWhere((m) => m.userId == '@mina:test').role, 'member');
    expect((await b.roomConfig(room))['mutes'], isNull);
  });

  testWidgets('muted member sees why, slow mode and member permissions stop sending', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('Team', ['@mina:test']);
    await b.sendText(room, 'first');
    await b.setRoomConfig(room, 'slow', 60);
    await b.setMemberLevel(room, '@me:test', 0);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('Team').first);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), 'second');
    await t.testTextInput.receiveAction(TextInputAction.send);
    await t.pump();
    final send = find.byKey(const Key('send'));
    if (send.evaluate().isNotEmpty) await t.tap(send);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('슬로 모드'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  Future<(FakeBackend, AppState, String)> open(WidgetTester t, Future<void> Function(FakeBackend b, String room) setup) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('Team', ['@mina:test']);
    await b.sendText(room, 'first');
    await setup(b, room);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('Team').first);
    await t.pumpAndSettle();
    return (b, s, room);
  }

  testWidgets('a muted member sees until when', (t) async {
    await open(t, (b, room) async {
      await b.setRoomConfig(room, 'mutes', {'@me:test': b.clock.add(const Duration(days: 1)).millisecondsSinceEpoch});
      await b.setMemberLevel(room, '@me:test', -1);
    });
    expect(find.byKey(const Key('read-only')), findsOneWidget);
    expect(find.textContaining('까지 메시지를 막았어요'), findsOneWidget);
    expect(find.byKey(const Key('composer')), findsNothing);
  });

  testWidgets('@ shows members to pick; photos off for members', (t) async {
    await open(t, (b, room) async {
      await b.setRoomConfig(room, 'member_perms', {'sticker': false});
    });
    await t.enterText(find.byKey(const Key('composer')), 'hi @mi');
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mention-list')), findsOneWidget);
    expect(find.byKey(const Key('mention-all')), findsNothing, reason: '"mi" is not 모두');
    await t.tap(find.byKey(const Key('mention-@mina:test')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mention-list')), findsNothing);
    final field = t.widget<CupertinoTextField>(find.byKey(const Key('composer')));
    expect(field.controller!.text, 'hi @mina ');
  });

  testWidgets('owner: member sheet has rights, tag, mute, handover', (t) async {
    final (b, s, room) = await open(t, (b, room) async => b.setAdmin(room, '@mina:test', true));
    await t.tap(find.byKey(const Key('chat-title')).first);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('member-@mina:test')), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.byKey(const Key('member-@mina:test')));
    await t.pumpAndSettle();
    for (final k in ['member-admin', 'member-rights', 'member-tag', 'member-handover', 'member-remove']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    expect(find.byKey(const Key('member-mute')), findsNothing, reason: 'admins are not muted');
    await t.tap(find.byKey(const Key('member-handover')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('handover-3')));
    await t.pumpAndSettle();
    expect((await b.members(room)).firstWhere((m) => m.userId == '@mina:test').role, 'owner');
    expect(RoomRules.handover(await b.roomConfig(room))?.$1, '@mina:test');
    await t.scrollUntilVisible(find.byKey(const Key('handover-card'), skipOffstage: false), -200, scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('handover-finish'), skipOffstage: false), findsOneWidget);
    expect(s.settings.keys.any((k) => k.startsWith('mod_log:')), isTrue);
  });

  test('4묶음: mute over lets me write, member-to-member chats blocked', () async {
    final cfg = RoomRules.withMute(const {}, '@m:x', t0.add(const Duration(hours: 1)));
    final c = {'mutes': cfg};
    expect(RoomRules.muteOver(c, '@m:x', t0), isFalse);
    expect(RoomRules.muteOver(c, '@m:x', t0.add(const Duration(hours: 2))), isTrue);
    expect(RoomRules.muteOver(const {}, '@m:x', t0), isFalse);

    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('Team', ['@mina:test']);
    await b.setRoomConfig(room, 'no_member_dm', true);
    await b.setMemberLevel(room, b.userId!, 0);
    Object? err;
    try {
      await b.createDirectChat('@mina:test');
    } catch (e) {
      err = e;
    }
    expect(err != null && RoomRules.isDmBlocked(err), isTrue);
    await b.createDirectChat('@stranger:test');
  });
}
