// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 협박 공격 막기 (2026-11-26): edit window, late-edit alerts, the new-member
// media limit, messages hidden after reports, blackmail report, wiping one
// person's messages. The server side is tested in Rust (Conduit rules,
// trust service); these are the phone's rules and screens.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/guard.dart';
import 'package:burumy/core/trust.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/room_tools.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Msg msg(String id, String sender, String body, DateTime t, {bool mine = false, String kind = 'text', DateTime? editedAt, String? first, String? caption}) =>
    Msg(id: id, sender: sender, body: body, time: t, mine: mine, kind: kind, edited: editedAt != null, editedAt: editedAt, firstBody: first, caption: caption);

Future<(AppState, FakeBackend)> start(WidgetTester t, {void Function(FakeBackend b)? before}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  before?.call(b);
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> openTeam(WidgetTester t) async {
  await t.tap(find.text('디자인 팀').first);
  await t.pumpAndSettle();
}

void main() {
  final now = DateTime(2026, 11, 26, 12);

  test('edit window: 24 hours in groups and channels, no limit in 1:1', () {
    expect(editWindowOpen(group: true, sent: now.subtract(const Duration(hours: 23)), now: now), isTrue);
    expect(editWindowOpen(group: true, sent: now.subtract(const Duration(hours: 25)), now: now), isFalse);
    expect(editWindowOpen(group: false, sent: now.subtract(const Duration(days: 300)), now: now), isTrue);
  });

  test('late edits: only others, only non-admins, only more than an hour later, newest first', () {
    final list = lateEdits(
      [
        msg('ok', '@a:t', '고친 글', now.subtract(const Duration(days: 3)), editedAt: now.subtract(const Duration(days: 3, minutes: -5)), first: '글'),
        msg('late1', '@a:t', '나쁜 글', now.subtract(const Duration(days: 3)), editedAt: now.subtract(const Duration(hours: 2)), first: '안녕'),
        msg('late2', '@b:t', '나쁜 글', now.subtract(const Duration(days: 2)), editedAt: now.subtract(const Duration(hours: 1)), first: '반가워요'),
        msg('admin', '@boss:t', '공지 수정', now.subtract(const Duration(days: 3)), editedAt: now, first: '공지'),
        msg('mine', '@me:t', '내 글', now.subtract(const Duration(days: 3)), mine: true, editedAt: now, first: '내'),
        msg('plain', '@a:t', '그대로', now.subtract(const Duration(days: 3))),
      ],
      {'@boss:t'},
    );
    expect([for (final m in list) m.id], ['late2', 'late1']);
  });

  test('new-member limit: setting, who counts as new, what is covered', () {
    expect(newMediaDays(const {}), 0);
    expect(newMediaDays(const {'new_media_days': 7}), 7);
    expect(newMediaDays(const {'new_media_days': 99}), 0, reason: 'bad values from the server are ignored');
    final joined = now.subtract(const Duration(days: 2));
    final newbie = Member(userId: '@n:t', name: 'n', role: 'member', since: joined);
    final admin = Member(userId: '@a:t', name: 'a', role: 'admin', since: joined);
    expect(isNewMember(newbie, 7, now), isTrue);
    expect(isNewMember(newbie, 1, now), isFalse);
    expect(isNewMember(admin, 7, now), isFalse, reason: 'admins are never limited');
    expect(isNewMember(null, 7, now), isTrue, reason: 'unknown (already left) counts as new');
    expect(isNewMember(newbie, 0, now), isFalse, reason: 'off');
    expect(limitedKind(msg('p', '@n:t', 'a.png', now, kind: 'image')), isTrue);
    expect(limitedKind(msg('s', '@n:t', 'burumy-sticker-1.png', now, kind: 'image')), isTrue, reason: 'my own stickers are any picture');
    expect(limitedKind(msg('b', '@n:t', 'buru_01', now, kind: 'sticker')), isFalse, reason: 'built-in stickers are ours');
    expect(limitedKind(msg('l', '@n:t', '여기 www.cheap.xyz 보세요', now)), isTrue);
    expect(limitedKind(msg('t', '@n:t', '안녕하세요', now)), isFalse);
    expect(limitedKind(msg('f', '@n:t', 'a.pdf', now, kind: 'file', caption: '')), isTrue);
    expect(hideForNewMember(msg('p', '@n:t', 'a.png', now, kind: 'image'), newbie, 7), isTrue);
    expect(
      hideForNewMember(msg('p', '@n:t', 'a.png', now.add(const Duration(days: 6)), kind: 'image'), newbie, 7),
      isFalse,
      reason: 'sent after the limit ended',
    );
    expect(
      hideForNewMember(msg('p', '@gone:t', 'a.png', now, kind: 'image'), null, 7, now: now.add(const Duration(days: 1))),
      isTrue,
      reason: 'join, post, leave',
    );
    expect(
      hideForNewMember(msg('p', '@gone:t', 'a.png', now, kind: 'image'), null, 7, now: now.add(const Duration(days: 30))),
      isFalse,
      reason: 'old photos of people who left stay',
    );
    expect(myMediaFrom(newbie, 7), isNotNull);
    expect(myMediaFrom(admin, 7), isNull);
  });

  test('trust list: hidden messages are plain ids only', () {
    final t = TrustList.fromJson({
      'v': 2,
      'hidden': [r'$bad:t', '!room:t', 42, r'$ok'],
    });
    expect(t.hidden, {r'$bad:t', r'$ok'});
    expect(t.guard, '');
    expect(TrustList.fromJson({'guard': '@guard:t'}).guard, '@guard:t');
    expect(TrustList.fromJson({'guard': 'guard'}).guard, '');
  });

  testWidgets('a room with the public-room guard says so instead of "nobody can read it"', (t) async {
    await start(
      t,
      before: (b) {
        b.trust = TrustList(version: 9, guard: '@guard:test', hidden: const {r'$ad'});
        b.roomMembers['!r1'] = [
          Member(userId: b.userId!, name: '나', role: 'member'),
          const Member(userId: '@guard:test', name: '공개방 지킴이', role: 'member'),
        ];
        b.rooms['!r1']!.add(msg(r'$ad', '@coin:test', '무료 코인', b.now.subtract(const Duration(minutes: 5))));
      },
    );
    await openTeam(t);
    expect(find.text('무료 코인'), findsNothing);
    expect(find.byKey(const Key(r'report-hidden-$ad')), findsOneWidget);
    expect(find.byKey(const Key('title-locked')), findsNothing);
    expect(find.byKey(const Key('title-lock')), findsNothing);
    await t.scrollUntilVisible(find.byKey(const Key('guard-notice')), 400, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.up).first);
    expect(find.byKey(const Key('guard-notice')), findsOneWidget);
    expect(find.byKey(const Key('e2e-notice')), findsNothing);
  });

  testWidgets('without the guard the usual encryption line stays', (t) async {
    await start(t);
    await openTeam(t);
    await t.scrollUntilVisible(find.byKey(const Key('e2e-notice')), 400, scrollable: find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.up).first);
    expect(find.byKey(const Key('e2e-notice')), findsOneWidget);
  });

  testWidgets('admin sees the late-edit bar, the list, and can remove it; log keeps it', (t) async {
    final (s, b) = await start(
      t,
      before: (b) => b.rooms['!r1']!.add(
        msg('late', '@leo:test', '이 링크 보세요', b.now.subtract(const Duration(days: 4)), editedAt: b.now.subtract(const Duration(minutes: 5)), first: '좋은 아침이에요'),
      ),
    );
    await openTeam(t);
    expect(find.byKey(const Key('late-edit-bar')), findsOneWidget);
    expect(find.text('오래된 글 1개가 수정됐어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('late-edit-bar')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('late-late')), findsOneWidget);
    expect(find.textContaining('좋은 아침이에요'), findsOneWidget);
    await t.tap(find.byKey(const Key('late-remove-late')));
    await t.pumpAndSettle();
    expect(b.rooms['!r1']!.any((m) => m.id == 'late'), isFalse);
    expect(s.pref('mod_log:!r1', ''), contains('late_edit'));
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('late-edit-bar')), findsNothing, reason: 'seen ones stay quiet');
  });

  testWidgets('member: new member photo hidden, own photo and link blocked, old message not editable', (t) async {
    final (s, b) = await start(
      t,
      before: (b) {
        final me = b.userId!;
        b.roomMembers['!r1'] = [
          const Member(userId: '@boss:test', name: 'boss', role: 'owner'),
          Member(userId: me, name: '나', role: 'member', since: b.now.subtract(const Duration(days: 1))),
          Member(userId: '@new:test', name: 'new', role: 'member', since: b.now.subtract(const Duration(hours: 3))),
        ];
        b.roomConfigs['!r1'] = {'new_media_days': 7};
        b.rooms['!r1']!.addAll([
          msg('np', '@new:test', 'bad.png', b.now.subtract(const Duration(hours: 1)), kind: 'image'),
          msg('old', me, '어제 쓴 글', b.now.subtract(const Duration(hours: 30)), mine: true),
        ]);
      },
    );
    await openTeam(t);
    expect(find.byKey(const Key('new-hidden-np')), findsOneWidget);
    expect(find.text('새 멤버가 보낸 사진·영상·링크는 가려져요'), findsWidgets);
    // A link from me (joined yesterday) is stopped with a note.
    await t.enterText(find.byType(CupertinoTextField).last, 'www.my-shop.xyz 놀러 오세요');
    await t.pump();
    final before = b.rooms['!r1']!.length;
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    expect(b.rooms['!r1']!.length, before);
    expect(find.textContaining('7일이 지나야'), findsOneWidget);
    // My 30-hour-old message has no 수정 in its menu.
    await t.longPress(find.text('어제 쓴 글'));
    await t.pumpAndSettle();
    expect(find.text('수정'), findsNothing);
    expect(s, isNotNull);
  });

  testWidgets('three illegal reports hide the message for everyone', (t) async {
    final (s, b) = await start(t, before: (b) => b.rooms['!r1']!.add(msg('ill', '@x:test', '이상한 글', b.now)));
    // Two others already reported it.
    await b.reportContent('!r1', 'ill', '@x:test', 'illegal', '');
    await b.reportContent('!r1', 'ill', '@x:test', 'illegal', '');
    await openTeam(t);
    expect(find.byKey(const Key('report-hidden-ill')), findsNothing);
    await t.longPress(find.text('이상한 글').last);
    await t.pumpAndSettle();
    for (final k in ['menu-select', 'select-more', 'more-report']) {
      await t.tap(find.byKey(Key(k)));
      await t.pumpAndSettle();
    }
    await t.tap(find.text('불법 촬영물·성착취물 (합성 포함)'));
    await t.pumpAndSettle();
    expect(b.contentReports.last, ['!r1', 'ill', '@x:test', 'illegal', '이상한 글']);
    expect(s.trust.hidden, contains('ill'));
    expect(find.byKey(const Key('report-hidden-ill')), findsOneWidget);
    expect(find.text('신고나 자동 검사로 가려진 글이에요. 운영자가 확인하고 있어요.'), findsOneWidget);
    expect(find.text('이상한 글'), findsNothing);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('room tools: new-member switch, blackmail report, wipe one person', (t) async {
    final (s, b) = await start(t, before: (b) => b.rooms['!r1']!.add(msg('spam1', '@mina:test', '스팸', b.now)));
    await openTeam(t);
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    final tools = find.byKey(const Key('info-tools'));
    await t.scrollUntilVisible(tools, 150, scrollable: find.byType(Scrollable).last);
    await t.tap(tools);
    await t.pumpAndSettle();
    Future<void> tap(String key) async {
      final f = find.byKey(Key(key));
      await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
      await t.tap(f);
      await t.pumpAndSettle();
    }

    await tap('tool-new-media');
    await tap('new-media-3');
    expect(b.roomConfigs['!r1']!['new_media_days'], 3);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.text('3일'), findsOneWidget);

    await tap('tool-extortion');
    await t.enterText(find.byKey(const Key('extortion-who')), 'blackmailer');
    await t.enterText(find.byKey(const Key('extortion-words')), '돈 안 보내면 방 신고함');
    await t.tap(find.byKey(const Key('extortion-send')));
    await t.pumpAndSettle();
    expect(b.contentReports.last, ['!r1', '', '@blackmailer', 'extortion', '돈 안 보내면 방 신고함']);
    expect(find.byKey(const Key('extortion-done')), findsOneWidget);
    expect(s.pref('mod_log:!r1', ''), contains('extortion'));

    // Wipe: everything mina wrote goes, then she is banned.
    final n = b.rooms['!r1']!.where((m) => m.sender == '@mina:test').length;
    expect(n, greaterThan(1));
    final gone = await wipeAndCount(b);
    expect(gone, n);
    expect(b.rooms['!r1']!.any((m) => m.sender == '@mina:test'), isFalse);
    expect(b.bannedUsers['!r1'], contains('@mina:test'));
  });
}

// Same helper the member sheet uses.
Future<int> wipeAndCount(FakeBackend b) => wipeUser(b, '!r1', '@mina:test');
