// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 저장한 메시지 (v1 layout, Telegram details): on top of the chat list with
// the bookmark, 'N개 대화' + tag chips with counts, the side list by source
// chat, the source view with '대화 열기', the info page with its ⋯ menu,
// and saving from a chat remembers where it came from (on this device).
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/saved_tags.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  s.settings = await b.settings();
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('saved messages: in the list by time, chips, side list, source view, info', (t) async {
    final (s, _) = await start(t);
    expect(s.chats.any((c) => c.roomId == s.savedRoomId), isTrue);
    expect(find.byKey(const Key('saved-avatar')), findsWidgets);
    await tap(t, find.text('저장한 메시지').first);
    // 3 source chats; chips 링크 1, ✅ 1, ❤️ 1.
    expect(find.byKey(const Key('saved-count')), findsOneWidget);
    expect(find.text('3개 대화'), findsOneWidget);
    expect(find.text('링크 1'), findsOneWidget);
    expect(find.text('✅ 1'), findsOneWidget);
    // Link chip shows only the message with a link.
    await tap(t, find.byKey(const Key('tag-filter-link')));
    expect(find.textContaining('burumy.app/design'), findsOneWidget);
    expect(find.textContaining('장보기'), findsNothing);
    await tap(t, find.byKey(const Key('tag-filter-all')));
    // Side list: 모든 메시지, 내 노트, then the chats.
    await tap(t, find.byKey(const Key('saved-side-open')));
    expect(find.byKey(const Key('saved-src-all')), findsOneWidget);
    expect(find.byKey(const Key('saved-src-note')), findsOneWidget);
    expect(find.byKey(const Key('saved-src-!r0')), findsOneWidget);
    expect(find.byKey(const Key('saved-src-!r1')), findsOneWidget);
    // My notes only: no forwarded copies, composer stays.
    await tap(t, find.byKey(const Key('saved-src-note')));
    expect(find.textContaining('장보기'), findsOneWidget);
    expect(find.textContaining('사진전'), findsNothing);
    // One source chat: its messages, '대화 열기' instead of the composer.
    await tap(t, find.byKey(const Key('saved-side-open')));
    await tap(t, find.byKey(const Key('saved-src-!r0')));
    expect(find.byKey(const Key('saved-source-title')), findsOneWidget);
    expect(find.textContaining('사진전'), findsOneWidget);
    expect(find.textContaining('장보기'), findsNothing);
    expect(find.byKey(const Key('saved-open-chat')), findsOneWidget);
    await tap(t, find.byKey(const Key('saved-open-chat')));
    expect(find.text('김민지'), findsWidgets);
    await tap(t, find.byKey(const Key('back')).last);
    // Info page: tabs and the ⋯ menu (zoom, photos switch).
    await tap(t, find.byKey(const Key('chat-title')));
    expect(find.byKey(const Key('saved-info-tabs')), findsOneWidget);
    expect(find.byKey(const Key('saved-media-3')), findsOneWidget);
    await tap(t, find.byKey(const Key('saved-info-more')));
    await tap(t, find.byKey(const Key('pulldown-zoom-out')));
    expect(find.byKey(const Key('saved-media-4')), findsOneWidget);
    await tap(t, find.byKey(const Key('saved-info-more')));
    await tap(t, find.byKey(const Key('pulldown-photos')));
    expect(find.byKey(const Key('saved-media-empty')), findsOneWidget);
    // Videos can't be switched off too: one kind always stays.
    await tap(t, find.byKey(const Key('saved-info-more')));
    await tap(t, find.byKey(const Key('pulldown-videos')));
    expect(find.byKey(const Key('saved-media-empty')), findsOneWidget);
    await tap(t, find.byKey(const Key('saved-info-more')));
    await tap(t, find.byKey(const Key('pulldown-calendar')));
    expect(find.byKey(const Key('media-calendar')), findsOneWidget);
  });

  testWidgets('forwarding into saved messages remembers the source chat', (t) async {
    final (s, b) = await start(t);
    await tap(t, find.text('김민지').last);
    await t.longPress(find.text('안녕하세요!'));
    await t.pumpAndSettle();
    await tap(t, find.byKey(const Key('menu-forward')));
    await tap(t, find.text('저장한 메시지').last);
    final copy = b.rooms['saved']!.last;
    expect(copy.body, '안녕하세요!');
    expect(savedFrom(s)[copy.id], '!r0');
  });

  testWidgets('chat list ⋯ = v1 edit mode: pick, read all, archive, delete with undo', (t) async {
    final (s, b) = await start(t);
    await tap(t, find.byKey(const Key('chats-menu')));
    expect(find.byKey(const Key('list-edit-bar')), findsOneWidget);
    expect(find.byKey(const Key('list-edit-done')), findsOneWidget);
    // Nothing picked: 모두 읽음 works, 보관 / 삭제 wait for a pick.
    expect(find.text('모두 읽음'), findsOneWidget);
    await tap(t, find.byKey(const Key('edit-archive')));
    expect(find.byKey(const Key('list-edit-bar')), findsOneWidget);
    await tap(t, find.byKey(const Key('edit-row-!r0')));
    expect(find.text('읽음'), findsOneWidget);
    await tap(t, find.byKey(const Key('edit-archive')));
    expect(find.byKey(const Key('list-edit-bar')), findsNothing);
    expect(s.chats.firstWhere((c) => c.roomId == '!r0').archived, isTrue);
    // Delete two at once: one undo for both.
    await tap(t, find.byKey(const Key('chats-menu')));
    await tap(t, find.byKey(const Key('edit-row-!r1')));
    await tap(t, find.byKey(const Key('edit-row-!r2')));
    await tap(t, find.byKey(const Key('edit-delete')));
    expect(find.byKey(const Key('list-undo-bar')), findsOneWidget);
    expect(find.text('디자인 팀'), findsNothing);
    await tap(t, find.byKey(const Key('list-undo')));
    expect(find.text('디자인 팀'), findsOneWidget);
    // Read all.
    await tap(t, find.byKey(const Key('chats-menu')));
    await tap(t, find.byKey(const Key('edit-read')));
    expect(s.chats.where((c) => c.unread > 0 && c.roomId != s.savedRoomId), isEmpty);
  });
}
