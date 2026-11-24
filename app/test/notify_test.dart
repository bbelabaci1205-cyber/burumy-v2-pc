// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Notifications and "who can reach me": rules on the phone, the in-app
// banner, and the settings pages that drive them.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/rules.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flutter_test_config.dart' show played;

ChatPreview chat({bool direct = true, bool channel = false, bool muted = false, String id = '!r'}) =>
    ChatPreview(roomId: id, name: 'x', isDirect: direct, isChannel: channel, peer: '', encrypted: true, unread: 0, muted: muted);

Notice notice([String room = '!r']) => Notice(roomId: room, chat: 'x', sender: 'a', kind: 'text', body: 'hi', time: DateTime(2026));

void main() {
  test('who may reach me: everyone, contacts, nobody, with exceptions first', () {
    const friends = {'@a:t'};
    expect(allowedFrom({}, 'who_calls', '@z:t', friends), isTrue);
    expect(allowedFrom({'who_calls': 'contacts'}, 'who_calls', '@z:t', friends), isFalse);
    expect(allowedFrom({'who_calls': 'contacts'}, 'who_calls', '@a:t', friends), isTrue);
    expect(allowedFrom({'who_calls': 'nobody'}, 'who_calls', '@a:t', friends), isFalse);
    expect(allowedFrom({'who_calls': 'nobody', 'who_calls_allow': '@a:t'}, 'who_calls', '@a:t', friends), isTrue);
    expect(allowedFrom({'who_calls_deny': '@a:t,@b:t'}, 'who_calls', '@a:t', friends), isFalse);
    // A deny wins over an allow for the same person.
    expect(allowedFrom({'who_calls_allow': '@a:t', 'who_calls_deny': '@a:t'}, 'who_calls', '@a:t', friends), isFalse);
  });

  test('focus hours, also across midnight and only on chosen days', () {
    final p = {'focus_on': '1', 'focus_from': '22:00', 'focus_to': '07:00', 'focus_days': '1'}; // Monday night
    expect(inFocus(p, DateTime(2026, 11, 23, 23)), isTrue); // Mon 23:00
    expect(inFocus(p, DateTime(2026, 11, 24, 6, 59)), isTrue); // Tue 06:59 belongs to Monday
    expect(inFocus(p, DateTime(2026, 11, 24, 7)), isFalse);
    expect(inFocus(p, DateTime(2026, 11, 24, 23)), isFalse); // Tuesday not chosen
    expect(inFocus({...p, 'focus_on': '0'}, DateTime(2026, 11, 23, 23)), isFalse);
    expect(inFocus({'focus_on': '1', 'focus_from': '09:00', 'focus_to': '18:00'}, DateTime(2026, 11, 24, 12)), isTrue);
    expect(inFocus({'focus_on': '1', 'focus_from': 'bad', 'focus_to': '99:99'}, DateTime(2026, 11, 24, 23)), isTrue); // falls back to 22-07
  });

  test('notices: muted, hidden, kind off, per-chat exception', () {
    final now = DateTime(2026, 11, 24, 12);
    expect(noticeAllowed(notice(), {}, chat(), now), isTrue);
    expect(noticeAllowed(notice(), {}, chat(muted: true), now), isFalse);
    expect(noticeAllowed(notice(), {'list_hidden:!r': '1'}, chat(), now), isFalse);
    expect(noticeAllowed(notice(), {'notify_direct': '0'}, chat(), now), isFalse);
    expect(noticeAllowed(notice(), {'notify_group': '0'}, chat(direct: false), now), isFalse);
    expect(noticeAllowed(notice(), {'notify_channel': '0'}, chat(direct: false, channel: true), now), isFalse);
    expect(noticeAllowed(notice(), {'notify_direct:!r': '0'}, chat(), now), isFalse);
  });

  testWidgets('in-app banner for a new message in another chat, not the open one; sound plays', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final state = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    final room = b.rooms.keys.firstWhere((k) => b.names[k] == '김민지');
    played.clear();
    b.rooms[room]!.add(Msg(id: 'new1', sender: '@mina:test', body: '새 소식', time: DateTime.now(), mine: false, kind: 'text'));
    await state.refresh();
    await t.pump();
    expect(find.byKey(const Key('in-app-notice')), findsOneWidget);
    expect(played.single, 'assets/sounds/burumy_nuri.wav');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('in-app-notice')));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('composer')), findsOneWidget);
    expect(state.openRoom, room);
    // While that chat is open, its news doesn't pop up.
    b.rooms[room]!.add(Msg(id: 'new2', sender: '@mina:test', body: '또', time: DateTime.now(), mine: false, kind: 'text'));
    await state.refresh();
    await t.pump();
    expect(find.byKey(const Key('in-app-notice')), findsNothing);
    // Silent style: nothing shows.
    await state.setPref('in_app_style', 'silent');
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(state.openRoom, isNull);
    b.rooms[room]!.add(Msg(id: 'new3', sender: '@mina:test', body: '셋', time: DateTime.now(), mine: false, kind: 'text'));
    await state.refresh();
    await t.pump();
    expect(find.byKey(const Key('in-app-notice')), findsNothing);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('privacy: invites and 1:1 starts from strangers are turned down when set to contacts', (t) async {
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final state = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await state.setPref('who_invites', 'contacts');
    b.invites.add(const Invite(roomId: '!spam', name: '광고방', inviter: '@stranger:test', direct: false));
    await state.refresh();
    expect(state.invites.where((i) => i.roomId == '!spam'), isEmpty);
    expect(b.invites.where((i) => i.roomId == '!spam'), isEmpty);
    await state.setPref('who_invites', 'everyone');
    b.invites.add(const Invite(roomId: '!ok', name: '모임', inviter: '@stranger:test', direct: false));
    await state.refresh();
    expect(state.invites.where((i) => i.roomId == '!ok'), isNotEmpty);
  });
}
