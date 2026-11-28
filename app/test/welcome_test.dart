// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 환영 인사 + 규칙, end-to-end encrypted (Telegram tip 575, Eric 2026-11-27):
// only admins' packs are taken, new members (only) get the bubble, admin
// phones greet people who join later, old plain rooms are moved over.
import 'dart:convert';
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/room_texts.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> boot() async {
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  return (s, b);
}

Future<void> openGroup(WidgetTester t, AppState s) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  await t.tap(find.text('디자인 팀'));
  await t.pumpAndSettle();
}

/// The owner's phone wrote a pack: what the room and the hidden note hold.
Map<String, dynamic> ownerPack(FakeBackend b, {String welcome = '어서 와요 👋', String rules = '광고 금지', int? at, Map<String, dynamic>? media}) {
  final pack = RoomTexts(welcome: welcome, rules: rules, at: at ?? b.clock.millisecondsSinceEpoch, salt: 'ab12', media: media).toJson();
  b.roomConfigs['!r1'] = {
    ...?b.roomConfigs['!r1'],
    'texts': {'h': RoomTexts.fingerprint(pack), 'w': welcome.isNotEmpty || media != null, 'r': rules.isNotEmpty},
  };
  return pack;
}

Signal note(Map<String, dynamic> data, {String from = '@mina:test', DateTime? at}) =>
    Signal(roomId: '!r1', id: '\$${data.hashCode}', sender: from, kind: RoomTexts.kind, data: data, time: at ?? DateTime(2026, 11, 23, 20));

void main() {
  test('fingerprint: same pack same bytes, any change differs', () {
    final a = {'welcome': '안녕', 'rules': '', 'n': 'x', 'at': 1};
    final b = {'at': 1, 'n': 'x', 'rules': '', 'welcome': '안녕'};
    expect(RoomTexts.fingerprint(a), RoomTexts.fingerprint(b));
    expect(RoomTexts.fingerprint({...a, 'welcome': '안녕!'}), isNot(RoomTexts.fingerprint(a)));
    expect(RoomTexts.fingerprint({...a, 'n': 'y'}), isNot(RoomTexts.fingerprint(a)), reason: 'salt: no guessing short texts');
  });

  test('a pack is taken only when it matches the room (admins set it); a member cannot fake one', () async {
    final (s, b) = await boot();
    final pack = ownerPack(b);
    final fake = {...pack, 'welcome': '가짜 공지: 이 링크로 들어오세요 http://evil'};
    b.incomingSignals.add(note(fake, from: '@troll:test'));
    await s.handleSignals();
    expect(RoomTexts.of(s, '!r1', b.roomConfigs['!r1']!).welcome, isEmpty);
    b.incomingSignals.add(note(pack));
    await s.handleSignals();
    final got = RoomTexts.of(s, '!r1', b.roomConfigs['!r1']!);
    expect(got.welcome, '어서 와요 👋');
    expect(got.rules, '광고 금지');
    // The owner changes it: the old pack no longer counts.
    ownerPack(b, welcome: '새 인사');
    expect(RoomTexts.of(s, '!r1', b.roomConfigs['!r1']!).welcome, isEmpty);
  });

  test('a pack that comes before the room fingerprint is kept and checked again', () async {
    final (s, b) = await boot();
    final pack = RoomTexts(welcome: '먼저 왔어요', at: 1, salt: 'cd').toJson();
    b.roomMembers['!r1'] = [Member(userId: b.userId!, name: 'me', role: 'member'), const Member(userId: '@mina:test', name: 'mina', role: 'owner')];
    b.incomingSignals.add(note(pack));
    await s.handleSignals();
    expect(s.pref('texts:!r1', ''), isEmpty);
    b.roomConfigs['!r1'] = {
      'texts': {'h': RoomTexts.fingerprint(pack), 'w': true},
    };
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(RoomTexts.of(s, '!r1', b.roomConfigs['!r1']!).welcome, '먼저 왔어요');
  });

  test('save: words never in plain settings; old plain copies removed; empty removes all', () async {
    final (s, b) = await boot();
    b.roomConfigs['!r1'] = {'welcome': '옛 인사', 'rules': '옛 규칙'};
    await RoomTexts.save(s, '!r1', welcome: '새 인사');
    final cfg = b.roomConfigs['!r1']!;
    expect(cfg.containsKey('welcome'), isFalse);
    expect(cfg.containsKey('rules'), isFalse);
    expect(jsonEncode(cfg), isNot(contains('인사')));
    expect(jsonEncode(cfg), isNot(contains('규칙')));
    final sent = b.sentSignals.last;
    expect(sent.$2, RoomTexts.kind);
    expect(sent.$3['welcome'], '새 인사');
    expect(sent.$3['rules'], '옛 규칙', reason: 'old rules moved over too');
    expect(RoomTexts.fingerprint(sent.$3), (cfg['texts'] as Map)['h']);

    await RoomTexts.save(s, '!r1', welcome: '', rules: '');
    expect(b.roomConfigs['!r1']!.containsKey('texts'), isFalse);
  });

  test('admin phone: old plain room moved over; newcomers greeted once; another admin counts', () async {
    final (s, b) = await boot();
    final me = b.userId!;
    b.roomConfigs['!r1'] = {'welcome': '어서 와요'};
    b.roomMembers['!r1'] = [Member(userId: me, name: 'me', role: 'owner', since: DateTime(2026, 11, 1))];
    // (Runs at most every 20 s; the start-up refresh just ran.)
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(b.roomConfigs['!r1']!.containsKey('welcome'), isFalse);
    expect(b.roomConfigs['!r1']!['texts'], isA<Map>());
    final n = b.sentSignals.length;

    // Nobody new: nothing sent.
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(b.sentSignals.length, n);

    // Someone joins: the pack goes again (they can't read older notes).
    b.roomMembers['!r1'] = [...b.roomMembers['!r1']!, Member(userId: '@new:test', name: 'new', role: 'member', since: b.now.add(const Duration(seconds: 5)))];
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(b.sentSignals.length, n + 1);
    expect(b.sentSignals.last.$3['welcome'], '어서 와요');

    // Another admin already greeted the next one: skipped here.
    b.roomMembers['!r1'] = [...b.roomMembers['!r1']!, Member(userId: '@new2:test', name: 'new2', role: 'member', since: b.now.add(const Duration(seconds: 5)))];
    b.incomingSignals.add(note(b.sentSignals.last.$3, from: '@admin2:test', at: b.now.add(const Duration(seconds: 30))));
    await s.handleSignals();
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(b.sentSignals.length, n + 1);
  });

  test('plain members never send packs (only admins with the info right)', () async {
    final (s, b) = await boot();
    final me = b.userId!;
    b.roomConfigs['!r1'] = {'welcome': '어서 와요'};
    b.roomMembers['!r1'] = [
      Member(userId: me, name: 'me', role: 'member', since: DateTime(2026, 11, 1)),
      Member(userId: '@new:test', name: 'new', role: 'member', since: b.now),
    ];
    final n = b.sentSignals.length;
    b.now = b.now.add(const Duration(minutes: 1));
    await RoomTexts.run(s);
    expect(b.sentSignals.length, n);
    expect(b.roomConfigs['!r1']!['welcome'], '어서 와요');
  });

  testWidgets('new member: joined line + bubble only for me, with the photo; hold to delete', (t) async {
    final (s, b) = await boot();
    final photo = File('test/assets/sample_photo.png').readAsBytesSync();
    final media = await RoomTexts.uploadMedia(b, photo, 'image/png', 'hi.png');
    final pack = ownerPack(b, welcome: '**어서 와요!** 공지부터 봐 주세요', at: b.now.subtract(const Duration(days: 1)).millisecondsSinceEpoch, media: media);
    b.roomMembers['!r1'] = [Member(userId: b.userId!, name: 'me', role: 'member', since: b.now), const Member(userId: '@mina:test', name: 'mina', role: 'owner')];
    b.incomingSignals.add(note(pack));
    await s.handleSignals();
    await openGroup(t, s);
    expect(find.byKey(const Key('joined-line')), findsOneWidget);
    expect(find.byKey(const Key('welcome-bubble')), findsOneWidget);
    expect(find.text('나만 보여요'), findsOneWidget);
    expect(find.byKey(const Key('welcome-photo')), findsOneWidget);
    expect(find.textContaining('어서 와요!'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing, reason: 'marks drawn, not shown');
    await t.longPress(find.byKey(const Key('welcome-bubble')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('welcome-delete')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('welcome-bubble')), findsNothing);
    expect(s.on('welcomed:!r1'), isTrue);
  });

  test('join time: the first one seen stays (a rename must not make me new)', () async {
    final (s, _) = await boot();
    final first = DateTime(2026, 11, 1);
    expect(RoomTexts.joinedAt(s, '!r1', first), first);
    await Future<void>.delayed(Duration.zero);
    expect(RoomTexts.joinedAt(s, '!r1', DateTime(2026, 11, 20)), first);
  });

  testWidgets('people who were here before the welcome was written do not get it', (t) async {
    final (s, b) = await boot();
    final pack = ownerPack(b, at: b.now.millisecondsSinceEpoch);
    b.roomMembers['!r1'] = [
      Member(userId: b.userId!, name: 'me', role: 'member', since: b.now.subtract(const Duration(days: 30))),
      const Member(userId: '@mina:test', name: 'mina', role: 'owner'),
    ];
    b.incomingSignals.add(note(pack));
    await s.handleSignals();
    await openGroup(t, s);
    expect(find.byKey(const Key('welcome-bubble')), findsNothing);
    // Rules still apply to everyone.
    expect(RoomTexts.of(s, '!r1', b.roomConfigs['!r1']!).rules, '광고 금지');
  });

  testWidgets('editor: write, see the preview, edit by holding, delete everything', (t) async {
    final (s, b) = await boot();
    await openGroup(t, s);
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    final tools = find.byKey(const Key('info-tools'));
    await t.scrollUntilVisible(tools, 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    // Keep it clear of the top bar.
    await Scrollable.ensureVisible(tools.evaluate().single, alignment: 0.5);
    await t.pumpAndSettle();
    await t.tap(tools);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tool-welcome')));
    await t.pumpAndSettle();
    expect(find.text('환영 인사 만들기'), findsOneWidget);
    await t.enterText(find.byKey(const Key('welcome-input')), '반가워요');
    await t.tap(find.byKey(const Key('welcome-put')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('welcome-editor-hint')), findsOneWidget);
    // Hold → 수정: the words go back into the field.
    await t.longPress(find.byKey(const Key('welcome-preview')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('welcome-edit')));
    await t.pumpAndSettle();
    expect(find.text('반가워요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('welcome-input')), '반가워요! 2');
    // ✓ takes what is in the field too.
    await t.tap(find.byKey(const Key('welcome-save')));
    await t.pumpAndSettle();
    expect(b.sentSignals.last.$3['welcome'], '반가워요! 2');
    expect(find.text('켜짐'), findsWidgets);

    await t.tap(find.byKey(const Key('tool-welcome')));
    await t.pumpAndSettle();
    await t.longPress(find.byKey(const Key('welcome-preview')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('welcome-delete')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('welcome-empty')), findsOneWidget);
    await t.tap(find.byKey(const Key('welcome-save')));
    await t.pumpAndSettle();
    expect(b.roomConfigs['!r1']!.containsKey('texts'), isFalse);
  });
}
