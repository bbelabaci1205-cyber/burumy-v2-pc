import 'dart:async';

// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Notifications: text made on the phone, hidden when asked, muted chats
// silent, shown only while the app is in the background.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/push.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  final ko = lookupL(const Locale('ko'));
  final now = DateTime(2026, 11, 23, 22);

  test('notification text', () {
    expect(noticeText(ko, Notice(roomId: '!a', chat: '김민지', sender: '', kind: 'text', body: '7시 어때요?', time: now)), ('김민지', '7시 어때요?'));
    expect(noticeText(ko, Notice(roomId: '!g', chat: '디자인 팀', sender: '박서준', kind: 'image', time: now)), ('디자인 팀', '박서준: 사진'));
    expect(noticeText(ko, Notice(roomId: '!a', chat: '', sender: '', kind: 'text', time: now)), ('부루미', '새 메시지'));
    expect(noticeText(ko, Notice(roomId: '!a', chat: '김민지', sender: '', kind: 'bubble', time: now)).$2, isNot(contains('null')));
  });

  testWidgets('shown only in the background; muted chat silent; hide switch (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    final shown = <Notice>[];
    AppState.showNotices = (b) async => shown.addAll(await b.notifications());
    addTearDown(() => AppState.showNotices = null);
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('bob');
    final team = await fake.createDirectChat('team');
    fake.mutedChats.add(team);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();

    fake.rooms[bob]!.add(Msg(id: 'm1', sender: '@bob:test', body: '안녕', time: now, mine: false, kind: 'text'));
    await state.refresh();
    expect(shown, isEmpty); // app on screen: no notification

    state.inBackground = true;
    fake.rooms[team]!.add(Msg(id: 'm2', sender: '@x:test', body: '조용', time: now, mine: false, kind: 'text'));
    fake.rooms[bob]!.add(Msg(id: 'm3', sender: '@bob:test', body: '자요?', time: now, mine: false, kind: 'text'));
    await state.refresh();
    expect(shown.map((n) => n.body), ['안녕', '자요?']);

    // Settings switch hides chat name and text.
    state.inBackground = false;
    await t.tap(find.text('설정'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('notify-row')), 150, scrollable: find.byType(Scrollable).last);
    unawaited(Scrollable.ensureVisible(t.element(find.byKey(const Key('notify-row'))), alignment: 0.5));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('notify-row')));
    await t.pumpAndSettle();
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('notice-text-switch')), 150, scrollable: find.byType(Scrollable).last);
    unawaited(Scrollable.ensureVisible(t.element(find.byKey(const Key('notice-text-switch'))), alignment: 0.5));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('notice-text-switch')));
    await t.pumpAndSettle();
    expect(fake.hideNotice, isTrue);
    state.inBackground = true;
    fake.rooms[bob]!.add(Msg(id: 'm4', sender: '@bob:test', body: '비밀', time: now, mine: false, kind: 'text'));
    await state.refresh();
    expect(noticeText(ko, shown.last), ('부루미', '새 메시지'));
    state.stopLive();
  });
}
