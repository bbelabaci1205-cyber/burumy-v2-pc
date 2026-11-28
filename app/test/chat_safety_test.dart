// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 안전 묶음 (2026-11-27, tips 557, 478, 514, 418, 380).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/report_reasons.dart';
import 'package:burumy/core/room_rules.dart';
import 'package:burumy/core/trust.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/chat_safety.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.chatSafety = true);
  tearDown(() => Features.chatSafety = false);

  test('478 reasons: stable codes, urgent first, text for the operator', () {
    expect(ReportReasons.all.first.code, ReportReasons.dislike);
    expect(ReportReasons.find('goods.weapons')?.group, 'goods');
    expect(ReportReasons.urgent('child.sexual'), isTrue);
    expect(ReportReasons.urgent('violence.self_harm'), isTrue);
    expect(ReportReasons.urgent('scam.spam'), isFalse);
    expect(ReportReasons.illegalPicture('sexual_crime.deepfake'), isTrue);
    expect(ReportReasons.illegalPicture('adult.porn'), isFalse);
    final t = ReportReasons.reportText(code: 'terror.recruiting', label: '테러 > 모으기', note: '  여러 방에 올려요 ');
    expect(t.split('\n'), ['burumy-report/1 code=terror.recruiting urgent=1', '테러 > 모으기', 'note: 여러 방에 올려요']);
    expect(ReportReasons.reportText(code: 'other', label: '기타'), 'burumy-report/1 code=other\n기타');
    final codes = [
      for (final r in ReportReasons.all) ...[r.code, for (final s in r.subs) s.code],
    ];
    expect(codes.toSet().length, codes.length, reason: 'codes are unique');
  });

  test('380 media kinds: old media switch still counts, exceptions win', () {
    final old = <String, dynamic>{
      'member_perms': {'media': false},
    };
    expect(RoomRules.memberMay(old, 'photo'), isFalse);
    expect(RoomRules.memberMay(old, 'voice'), isFalse);
    expect(RoomRules.memberMay(old, 'sticker'), isTrue);
    final cfg = <String, dynamic>{'member_perms': RoomRules.permsValue(RoomRules.memberPermsSplit.where((k) => k != 'voice'))};
    expect(cfg['member_perms'], {'voice': false});
    expect(RoomRules.memberMay(cfg, 'voice'), isFalse);
    expect(RoomRules.memberMay(cfg, 'media'), isTrue, reason: 'other kinds still on');
    final ex = RoomRules.withException(cfg, '@m:x', {...RoomRules.memberPermsSplit});
    expect(ex, {
      '@m:x': {'voice': true},
    });
    final withEx = {...cfg, 'perm_users': ex};
    expect(RoomRules.memberMay(withEx, 'voice', userId: '@m:x'), isTrue);
    expect(RoomRules.memberMay(withEx, 'voice', userId: '@n:x'), isFalse);
    expect(RoomRules.may(withEx, 'admin', 'voice'), isTrue);
    expect(RoomRules.withException(withEx, '@m:x', null), isEmpty);
    expect(RoomRules.kindOfFile('a.HEIC'), 'photo');
    expect(RoomRules.kindOfFile('a.mov'), 'video');
    expect(RoomRules.kindOfFile('song.mp3'), 'music');
    expect(RoomRules.kindOfFile('a.png', asFile: true), 'file');
  });

  test('557 only the one who turned it on (1:1) may turn it off', () {
    final cfg = {'protect': true, 'protect_by': '@leo:x'};
    expect(mayTurnProtectOff(cfg, direct: true, me: '@me:x'), isFalse);
    expect(mayTurnProtectOff(cfg, direct: true, me: '@leo:x'), isTrue);
    expect(mayTurnProtectOff(cfg, direct: false, me: '@me:x'), isTrue, reason: 'groups: admins');
    expect(mayTurnProtectOff({'protect': true}, direct: true, me: '@me:x'), isTrue, reason: 'old rooms');
  });

  test('418 voice once: the length rides in the encrypted name', () {
    final n = onceVoiceName(const Duration(milliseconds: 12340), 'audio/mp4');
    expect(n, 'voiceonce-12340.m4a');
    expect(onceVoiceLength(n), const Duration(milliseconds: 12340));
    expect(onceVoiceLength('photo.png'), isNull);
    expect(photoPrint(null), 'none');
    expect(photoPrint([1, 2, 3]).length, 16);
  });

  Future<(FakeBackend, AppState, String)> openDm(WidgetTester t, {Map<String, dynamic>? cfg, List<Msg> extra = const []}) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '비밀 글');
    b.rooms[room]!.addAll(extra);
    if (cfg != null) b.roomConfigs[room] = cfg;
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    // The list row shows the newest message (or a voice / photo word).
    final last = extra.isEmpty ? '비밀 글' : (extra.last.kind == 'text' ? extra.last.body! : null);
    await t.tap(
      last == null
          ? find.text('비밀 글').evaluate().isEmpty
                ? find.textContaining('음성').first
                : find.text('비밀 글').first
          : find.text(last).first,
    );
    await t.pumpAndSettle();
    return (b, s, room);
  }

  testWidgets('557 notice pill, menu footer, other side cannot turn it off', (t) async {
    await openDm(t, cfg: {'protect': true, 'protect_by': '@mina:test'});
    expect(find.byKey(const Key('protect-notice')), findsOneWidget);
    expect(find.textContaining('이 대화의 공유를 막았어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('protect-notice')));
    await t.pump();
    expect(find.text('상대가 켠 공유 비활성화는 상대만 끌 수 있어요'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 4));
    await t.longPress(find.text('비밀 글').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-footer')), findsOneWidget);
    expect(find.byKey(const Key('menu-copy')), findsNothing);
  });

  testWidgets('478 report: reason, narrower reason, note goes with a code', (t) async {
    final now = DateTime.now();
    final (b, _, _) = await openDm(
      t,
      extra: [Msg(id: 'bad', sender: '@mina:test', body: '총 팔아요', time: now, mine: false, kind: 'text')],
    );
    await t.longPress(find.text('총 팔아요').last);
    await t.pumpAndSettle();
    for (final k in ['menu-select', 'select-more', 'more-report']) {
      await t.tap(find.byKey(Key(k)));
      await t.pumpAndSettle();
    }
    expect(find.byKey(const Key('report-sheet')), findsOneWidget);
    await t.tap(find.byKey(const Key('report-goods')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('report-goods.weapons')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('report-note')), '여러 번 올렸어요');
    await t.tap(find.byKey(const Key('report-send')));
    await t.pumpAndSettle();
    expect(b.reports.single.$2, contains('code=goods.weapons'));
    expect(b.reports.single.$2, contains('note: 여러 번 올렸어요'));
    expect(b.reports.single.$3, '총 팔아요');
    await t.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('478 그냥 싫어요 hides on this phone, nothing to the operator', (t) async {
    final now = DateTime.now();
    final (b, _, _) = await openDm(
      t,
      extra: [Msg(id: 'meh', sender: '@mina:test', body: '별로인 글', time: now, mine: false, kind: 'text')],
    );
    await t.longPress(find.text('별로인 글').last);
    await t.pumpAndSettle();
    for (final k in ['menu-select', 'select-more', 'more-report']) {
      await t.tap(find.byKey(Key(k)));
      await t.pumpAndSettle();
    }
    await t.tap(find.byKey(const Key('report-dislike')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('report-dislike-hide')));
    await t.pumpAndSettle();
    expect(b.reports, isEmpty);
    expect(find.byKey(const Key('disliked-meh')), findsOneWidget);
    expect(find.text('별로인 글'), findsNothing);
    await t.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('418 one-time voice: bubble, opens once, then expired', (t) async {
    final now = DateTime.now();
    final (b, _, room) = await openDm(
      t,
      extra: [Msg(id: 'ov', sender: '@mina:test', body: 'voiceonce-9000.m4a', time: now, mine: false, kind: 'audio', viewOnce: true)],
    );
    b.files['ov'] = const [1, 2, 3];
    expect(find.byKey(const Key('once-voice')), findsOneWidget);
    expect(find.textContaining('0:09'), findsOneWidget);
    await t.tap(find.byKey(const Key('once-voice')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('once-voice-page')), findsOneWidget);
    await t.tap(find.byKey(const Key('once-voice-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('once-voice-expired')), findsOneWidget);
    expect(b.rooms[room]!.firstWhere((m) => m.id == 'ov').opened, isTrue);
  });

  testWidgets('514 card: photo / name change days and groups in common', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    const room = '!new';
    b.names[room] = '하늘';
    b.peers[room] = '@sky:test';
    b.strangerRooms.add(room);
    b.rooms[room] = [Msg(id: 'h', sender: '@sky:test', body: '처음 인사', time: DateTime.now(), mine: false, kind: 'text')];
    b.trustAbouts['@sky:test'] = const TrustAbout(age: 'quarter', renamedDays: 2, photoDays: 0);
    final g = await b.createGroup('등산 모임', ['@sky:test']);
    b.roomMembers[g] = const [Member(userId: '@me:test', name: 'me', role: 'owner'), Member(userId: '@sky:test', name: '하늘', role: 'member')];
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('처음 인사').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('first-contact-card')), findsOneWidget);
    expect(find.text('1~3개월 전'), findsOneWidget);
    expect(find.text('2일 전'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    await t.tap(find.byKey(const Key('first-common')));
    await t.pumpAndSettle();
    expect(find.text('등산 모임'), findsWidgets);
  });

  testWidgets('380 text off for members: locked composer, voice says why', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final g = await b.createGroup('공지방', ['@mina:test']);
    b.roomMembers[g] = const [Member(userId: '@me:test', name: 'me', role: 'member'), Member(userId: '@mina:test', name: 'mina', role: 'owner')];
    b.roomConfigs[g] = {
      'member_perms': {'text': false, 'voice': false},
    };
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('공지방').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('text-locked')), findsOneWidget);
    expect(find.text('이 방에서는 글을 보낼 수 없어요'), findsOneWidget);
  });

  testWidgets('478 report sits in the long-press menu for others\' messages', (t) async {
    final now = DateTime.now();
    await openDm(
      t,
      extra: [Msg(id: 'x', sender: '@mina:test', body: '남의 글', time: now, mine: false, kind: 'text')],
    );
    await t.longPress(find.text('남의 글').last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-report')), findsOneWidget);
    await t.tap(find.byKey(const Key('menu-report')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('report-sheet')), findsOneWidget);
  });
}
