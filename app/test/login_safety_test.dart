// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 로그인·기기 안전 (Telegram tips 398, 78+311, 247, 308, 343, 356).
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/login_safety.dart';
import 'package:burumy/core/qr.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/link_pc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.loginSafety = true);
  tearDown(() => Features.loginSafety = false);

  Future<(FakeBackend, AppState)> made() async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'demo');
    final s = AppState(b, locale: const Locale('ko'));
    return (b, s);
  }

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    return made();
  }

  DeviceRow pc(String id) => DeviceRow(id: id, name: 'Burumy Windows PC', lastSeen: DateTime(2026, 11, 27, 9), thisDevice: false, verified: false);

  test('new login: first look learns, a later new device shows, yes remembers', () async {
    final (b, s) = await made();
    b.otherDevices.add(pc('OLD'));
    await s.checkNewLogins(now: true);
    expect(s.newLogins, isEmpty, reason: 'devices from before the update are known');
    b.otherDevices.add(pc('NEW'));
    await s.checkNewLogins(now: true);
    expect(s.newLogins.map((d) => d.id), ['NEW']);
    expect(s.thisDeviceId, 'THIS');
    await s.answerNewLogin('NEW', mine: true);
    await s.checkNewLogins(now: true);
    expect(s.newLogins, isEmpty);
    // Logged out and back in = new again.
    b.otherDevices.removeWhere((d) => d.id == 'NEW');
    await s.checkNewLogins(now: true);
    b.otherDevices.add(pc('NEW'));
    await s.checkNewLogins(now: true);
    expect(s.newLogins.map((d) => d.id), ['NEW']);
  });

  testWidgets('new login card: "not me" logs that device out and offers a new password', (t) async {
    final (b, s) = await app(t);
    await s.checkNewLogins(now: true);
    b.otherDevices.add(pc('EVIL'));
    await s.refresh();
    await s.checkNewLogins(now: true);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('new-login-EVIL')), findsOneWidget);
    expect(find.textContaining('Burumy Windows PC'), findsOneWidget);
    await t.tap(find.byKey(const Key('new-login-no')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('pw-field')), 'demo');
    await t.tap(find.byKey(const Key('pw-go')));
    await t.pumpAndSettle();
    expect(b.otherDevices.where((d) => d.id == 'EVIL'), isEmpty, reason: 'logged out');
    expect(find.byKey(const Key('new-login-change-pw')), findsOneWidget);
    expect(s.newLogins, isEmpty);
  });

  test('strangers: first 1:1 message from a non-friend goes to 보관함, muted', () async {
    final (b, s) = await made();
    await s.setOn(LoginSafety.strangerArchiveKey, true);
    // 메시지 요청 on (the default): the request row handles it, never also
    // archived (an accepted chat would stay hidden and muted).
    b.invites.add(const Invite(roomId: '!r', name: '', inviter: '@asks:test', direct: true));
    await s.refresh();
    expect(s.isRequest('!r'), isTrue);
    expect(b.archivedChats, isNot(contains('!r')));
    expect(s.tuckedNow.value, 0);
    // Requests off: the archive switch takes over.
    await s.setOn('message_requests', false);
    b.invites.add(const Invite(roomId: '!x', name: '', inviter: '@spam:test', direct: true));
    await s.refresh();
    expect(b.archivedChats, contains('!x'));
    expect(b.mutedChats, contains('!x'));
    expect(s.tuckedNow.value, 1);
    // Switch off: nothing is tucked.
    await s.setOn(LoginSafety.strangerArchiveKey, false);
    b.invites.add(const Invite(roomId: '!y', name: '', inviter: '@new:test', direct: true));
    await s.refresh();
    expect(b.archivedChats, isNot(contains('!y')));
  });

  test('voice rule: told to friends as a hidden note, their rule dims my mic', () async {
    final (b, s) = await made();
    final room = await b.createDirectChat('@bob:test');
    await s.refresh();
    expect(b.sentSignals.where((x) => x.$2 == LoginSafety.voiceSignal), isEmpty, reason: 'everyone may: nothing to say');
    await s.setPref(LoginSafety.voiceKey, 'nobody');
    await LoginSafety.tellVoiceRule(s);
    final sent = b.sentSignals.lastWhere((x) => x.$2 == LoginSafety.voiceSignal);
    expect(sent.$1, room);
    expect(sent.$3['ok'], false);
    // Their note says no: my mic is closed in that chat.
    final chat = s.chats.firstWhere((c) => c.roomId == room);
    expect(LoginSafety.canSendVoice(s, chat), isTrue);
    await LoginSafety.onVoiceSignal(s, Signal(roomId: room, id: 'v1', sender: '@bob:test', kind: LoginSafety.voiceSignal, data: {'ok': false}, time: DateTime(2026)));
    expect(LoginSafety.canSendVoice(s, chat), isFalse);
    // A voice from someone I don't allow is shown as one line.
    final m = Msg(id: 'a', sender: '@bob:test', body: 'voice', time: DateTime(2026), mine: false, kind: 'audio');
    expect(LoginSafety.hideVoice(s, chat, m), isTrue);
    await s.setPref('${LoginSafety.voiceKey}_allow', '@bob:test');
    expect(LoginSafety.hideVoice(s, chat, m), isFalse);
  });

  testWidgets('voice closed: dimmed mic explains why', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('bob');
    await s.refresh();
    await s.setPref('voice_ok:$room', '0');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('bob').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('mic-closed')), findsOneWidget);
    expect(find.byKey(const Key('mic')), findsNothing);
    await t.tap(find.byKey(const Key('mic-closed')));
    await t.pumpAndSettle();
    expect(find.text('음성 메시지를 보낼 수 없어요'), findsOneWidget);
  });

  test('calls: for me hides, for both tells the other phone and deletes my ring', () async {
    final (b, s) = await made();
    final room = await b.createDirectChat('@bob:test');
    await s.refresh();
    final mine = await b.startCall(room, video: false);
    final theirs = b.receiveCall(room, '@bob:test');
    final log = await b.callLog();
    await LoginSafety.forgetCalls(s, log, both: true);
    expect(LoginSafety.hiddenCalls(s), containsAll([mine, theirs]));
    expect(b.rooms[room]!.where((m) => m.call?.id == mine), isEmpty, reason: 'my own ring is gone from the server');
    final note = b.sentSignals.lastWhere((x) => x.$2 == LoginSafety.callsSignal);
    expect(note.$3['ids'], containsAll([mine, theirs]));
    // The other phone gets it.
    final (b2, s2) = await made();
    final r2 = await b2.createDirectChat('@me:test');
    await s2.refresh();
    final again = b2.receiveCall(r2, '@me:test');
    await LoginSafety.onCallsSignal(s2, Signal(roomId: r2, id: 'c', sender: '@me:test', kind: LoginSafety.callsSignal, data: {'ids': [again]}, time: DateTime(2026)));
    expect(LoginSafety.hiddenCalls(s2), contains(again));
  });

  testWidgets('calls tab: select two, delete for me with 5-second undo', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('@bob:test');
    await s.refresh();
    final a = b.receiveCall(room, '@bob:test');
    final c = b.receiveCall(room, '@bob:test');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('tab-calls')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('calls-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('calls-select')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('call-row-$a')));
    await t.tap(find.byKey(Key('call-row-$c')));
    await t.pump();
    await t.tap(find.byKey(const Key('calls-delete')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('delete-both')), findsOneWidget);
    await t.tap(find.byKey(const Key('delete-me')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('undo-countdown')), findsOneWidget);
    expect(find.byKey(Key('call-row-$a')), findsNothing, reason: 'hidden while waiting');
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(LoginSafety.hiddenCalls(s), containsAll([a, c]));
    expect(b.sentSignals.where((x) => x.$2 == LoginSafety.callsSignal), isEmpty, reason: 'for me only');
  });

  test('days: span covers whole days, mine deleted, others hidden, other phone asked', () async {
    final (b, s) = await made();
    final room = await b.createDirectChat('@bob:test');
    await s.refresh();
    Msg m(String id, DateTime t, bool mine) => Msg(id: id, sender: mine ? '@me:test' : '@bob:test', body: id, time: t, mine: mine, kind: 'text');
    b.rooms[room]!.addAll([
      m('keep', DateTime(2026, 11, 20, 23, 59), true),
      m('a', DateTime(2026, 11, 21, 0, 0), true),
      m('b', DateTime(2026, 11, 22, 12), false),
      m('c', DateTime(2026, 11, 22, 23, 59), true),
      m('keep2', DateTime(2026, 11, 23), false),
    ]);
    final (from, to) = LoginSafety.span(DateTime(2026, 11, 22), DateTime(2026, 11, 21));
    expect(from, DateTime(2026, 11, 21));
    expect(to, DateTime(2026, 11, 23));
    final n = await LoginSafety.forgetDays(s, room, from, to, both: true);
    expect(n, 3);
    final left = b.rooms[room]!.map((x) => x.id).toList();
    expect(left, containsAll(['keep', 'b', 'keep2']));
    expect(left, isNot(contains('a')));
    expect(left, isNot(contains('c')));
    final hidden = b.rooms[room]!.where((x) => LoginSafety.hiddenByDate(s, room, x)).map((x) => x.id);
    expect(hidden, ['b']);
    final note = b.sentSignals.lastWhere((x) => x.$2 == LoginSafety.daysSignal);
    expect(note.$3['from'], from.millisecondsSinceEpoch);
    // A request for more than a year is ignored.
    await LoginSafety.onDaysSignal(s, Signal(roomId: room, id: 'd', sender: '@bob:test', kind: LoginSafety.daysSignal, data: {'from': 0, 'to': DateTime(2026).millisecondsSinceEpoch}, time: DateTime(2026)));
    expect(b.rooms[room]!.map((x) => x.id), contains('keep'));
  });

  test('device calls switch and idle logout go to my account settings', () async {
    final (b, s) = await made();
    await s.checkNewLogins(now: true);
    expect(s.callsOffHere, isFalse);
    await LoginSafety.setCalls(s, 'THIS', false);
    expect(b.privacy[LoginSafety.noCallsKey], ['THIS']);
    expect(s.callsOffHere, isTrue);
    await LoginSafety.setCalls(s, 'THIS', true);
    expect(b.privacy.containsKey(LoginSafety.noCallsKey), isFalse);
    await LoginSafety.setIdleDays(s, 90);
    expect(b.privacy[LoginSafety.idleDaysKey], 90);
    await LoginSafety.setIdleDays(s, 0);
    expect(b.privacy.containsKey(LoginSafety.idleDaysKey), isFalse);
  });

  test('calls off here: ringing stays quiet on this device only', () async {
    final (b, s) = await made();
    final room = await b.createDirectChat('@bob:test');
    await s.checkNewLogins(now: true);
    await LoginSafety.setCalls(s, 'THIS', false);
    b.receiveCall(room, '@bob:test');
    await s.refresh();
    expect(s.ringing, isEmpty);
    expect(b.hangups, isEmpty, reason: 'not turned down: my other devices still ring');
  });

  test('PC QR: code holds only the hash; phone vouches, PC signs in once', () async {
    final (secret, rid) = PcLinkCode.fresh();
    expect(PcLinkCode.read(PcLinkCode.of(rid)), rid);
    expect(PcLinkCode.of(rid), isNot(contains(secret)));
    expect(PcLinkCode.read('https://evil.example/?r=$rid'), isNull);
    expect(PcLinkCode.read('burumy://pc-login?r=zz'), isNull);
    final (_, phone) = await made();
    final pcB = FakeBackend();
    final pcS = AppState(pcB, locale: const Locale('ko'));
    expect(await pcS.loginWithPcCode(secret), isFalse, reason: 'not vouched yet');
    await phone.backend.approvePcLogin(rid);
    expect(await pcS.loginWithPcCode(rid), isFalse, reason: 'the QR alone is not enough');
    expect(await pcS.loginWithPcCode(secret), isTrue);
    expect(pcB.loggedIn, isTrue);
    expect(await FakeBackend().takePcLogin(secret), isFalse, reason: 'only once');
  });

  test('QR reader: reads our own QR from grey pixels', () {
    final rid = PcLinkCode.fresh().$2;
    final text = PcLinkCode.of(rid);
    final q = QrCode.encode(text)!;
    const scale = 6, quiet = 4;
    final w = (q.size + quiet * 2) * scale;
    final px = Uint8List(w * w)..fillRange(0, w * w, 255);
    for (var y = 0; y < q.size; y++) {
      for (var x = 0; x < q.size; x++) {
        if (!q.dark(x, y)) continue;
        for (var dy = 0; dy < scale; dy++) {
          for (var dx = 0; dx < scale; dx++) {
            px[((y + quiet) * scale + dy) * w + (x + quiet) * scale + dx] = 0;
          }
        }
      }
    }
    expect(readQr((w, w, px)), text);
    expect(readQr((w, w, Uint8List(w * w)..fillRange(0, w * w, 255))), isNull);
  });
}
