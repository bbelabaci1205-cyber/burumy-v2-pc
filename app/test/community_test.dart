// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 커뮤니티 (Eric 2026-11-27): make one from a group's info, the line in the
// chat, the mark on the chat row, the sheet with its three sections,
// "한 대화로 보기", joining / asking, hidden chats, who may add, leaving.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/community_sample.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t, {bool sample = false}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  if (sample) addCommunitySample(b, true);
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  await t.tap(find.text('대화').last);
  await t.pumpAndSettle();
  return (s, b);
}

Future<void> tapKey(WidgetTester t, String key) async {
  final f = find.byKey(Key(key));
  if (f.hitTestable().evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
  }
  await t.tap(f);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('make a community from the group info; line in the chat; mark on the row', (t) async {
    final (s, b) = await start(t);
    await t.tap(find.text('디자인 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await tapKey(t, 'info-community-add');
    expect(find.text('커뮤니티 만들기'), findsOneWidget);
    await tapKey(t, 'community-create');
    await t.enterText(find.byKey(const Key('community-name')), '동네 디자이너');
    await t.pumpAndSettle();
    await tapKey(t, 'community-new-done');

    expect(s.communities, hasLength(1));
    final c = s.communities.single;
    expect(c.name, '동네 디자이너');
    expect(c.role, 'owner');
    expect(c.chats.single.roomId, '!r1');
    // A group without a link got a private one with approval.
    final link = await b.roomLink('!r1');
    expect(link.kind, 'private');
    expect(link.approval, isTrue);
    // The info page now shows the community.
    expect(find.byKey(const Key('info-community')), findsOneWidget);

    // The line in the group.
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('community-card')), findsOneWidget);
    expect(find.text('이 그룹을 동네 디자이너 커뮤니티에 추가했어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    // Mark on the chat row opens the sheet.
    expect(find.byKey(Key('community-mark-${c.id}')), findsOneWidget);
    await t.tap(find.byKey(Key('community-mark-${c.id}')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('community-sheet')), findsOneWidget);
    expect(find.text('내가 들어간 대화'), findsOneWidget);
  });

  testWidgets('sheet sections, join and ask, show as one chat', (t) async {
    final (s, b) = await start(t, sample: true);
    const id = '!community_demo';
    await t.tap(find.byKey(const Key('community-mark-$id')).first);
    await t.pumpAndSettle();
    expect(find.text('내가 들어간 대화'), findsOneWidget);
    expect(find.text('볼 수 있는 대화'), findsOneWidget);
    await t.scrollUntilVisible(find.text('운영진 방'), 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    expect(find.text('가입 요청할 수 있는 대화'), findsOneWidget);
    // I am the owner: the hidden staff room shows, tagged.
    expect(find.text('운영진 방'), findsOneWidget);
    expect(find.textContaining('관리자만 보여요'), findsWidgets);

    // Ask to join: the button turns into "요청함".
    await tapKey(t, 'community-join-!cm_ask');
    expect(s.on('community_asked:!cm_ask'), isTrue);
    expect(find.text('요청함'), findsOneWidget);

    // Show as one chat: the community's chats fold into one row.
    await t.drag(find.byType(Scrollable).last, const Offset(0, 800));
    await t.pumpAndSettle();
    await tapKey(t, 'community-as-one');
    expect(s.communityAsOne(id), isTrue);
    await t.tap(find.byKey(const Key('community-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('community-row-$id')), findsOneWidget);
    expect(find.text('디자인 크루'), findsOneWidget);
    expect(find.text('디자인 팀'), findsNothing);

    // The row opens the page; join an open group from there.
    await t.tap(find.byKey(const Key('community-row-$id')));
    await t.pumpAndSettle();
    await tapKey(t, 'community-join-!cm_open');
    expect(b.rooms.containsKey('!cm_open'), isTrue);
    expect(find.text('주말 드로잉 모임'), findsWidgets); // the chat opened
  });

  testWidgets('members never see hidden chats; who may add; leave with undo', (t) async {
    final (s, b) = await start(t, sample: true);
    const id = '!community_demo';
    b.communityBook[id]!.role = 'member';
    await s.refresh();
    expect(s.communities.single.visible.any((x) => x.name == '운영진 방'), isFalse);
    // Members can't add while only admins may.
    expect(() => b.addToCommunity(id, '!r1'), throwsStateError);
    b.communityBook[id]!.addAll = true;
    await b.addToCommunity(id, '!r1');

    await t.tap(find.byKey(const Key('community-mark-$id')).first);
    await t.pumpAndSettle();
    expect(find.text('운영진 방'), findsNothing);
    await tapKey(t, 'community-settings');
    expect(find.text('커뮤니티 정보'), findsWidgets);
    await tapKey(t, 'community-leave');
    expect(find.byKey(const Key('community-undo')), findsOneWidget);
    await tapKey(t, 'community-undo');
    expect(s.communities, hasLength(1));
    await tapKey(t, 'community-leave');
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(s.communities, isEmpty);
  });

  testWidgets('admin: hide a chat, switch who may add, make an admin', (t) async {
    final (s, b) = await start(t, sample: true);
    const id = '!community_demo';
    await t.tap(find.byKey(const Key('community-mark-$id')).first);
    await t.pumpAndSettle();
    await tapKey(t, 'community-settings');
    await tapKey(t, 'community-add-all');
    expect(b.communityBook[id]!.addAll, isTrue);
    await tapKey(t, 'community-manage-!cm_open');
    await t.tap(find.byKey(const Key('community-chat-hide')));
    await t.pumpAndSettle();
    expect(s.communities.single.chats.firstWhere((x) => x.roomId == '!cm_open').hidden, isTrue);
    await tapKey(t, 'community-admins');
    await tapKey(t, 'community-admin-@leo:test');
    expect((await b.members(id)).firstWhere((m) => m.userId == '@leo:test').role, 'admin');
  });
}
