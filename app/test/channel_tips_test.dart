// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널 묶음 #15 (Telegram tips 521, 292, 472, 310, 526).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/channel_dm.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() {
    Features.channelTips = true;
    ChannelDm.reset();
  });
  tearDown(() => Features.channelTips = false);

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  testWidgets('521 hold the share arrow, slide onto a chat, 5 s undo then it goes', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('부루미 소식', const [], channel: true);
    await b.sendText(ch, '새 기능이 나왔어요');
    final ann = await b.createDirectChat('ann');
    await b.sendText(ann, '안녕');
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('부루미 소식'));
    await t.pumpAndSettle();
    final post = b.rooms[ch]!.last.id;
    final arrow = t.getCenter(find.byKey(Key('share-$post')));
    final g = await t.startGesture(arrow);
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quick-forward')), findsOneWidget);
    final face = t.getCenter(find.byKey(Key('quick-to-$ann')));
    await g.moveTo(face);
    await t.pump();
    expect(find.byKey(const Key('quick-name')), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quick-forward')), findsNothing);
    expect(find.byKey(const Key('quick-undo-bar')), findsOneWidget);
    // Undo: nothing goes.
    await t.tap(find.byKey(const Key('quick-undo')));
    await t.pumpAndSettle();
    expect(b.rooms[ann]!.map((m) => m.body), isNot(contains('새 기능이 나왔어요')));
    // Again, and let the 5 seconds run out.
    final g2 = await t.startGesture(arrow);
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    await g2.moveTo(t.getCenter(find.byKey(Key('quick-to-$ann'))));
    await t.pump();
    await g2.up();
    await t.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await t.pumpAndSettle();
    expect(b.rooms[ann]!.map((m) => m.body), contains('새 기능이 나왔어요'));
    expect(find.byKey(const Key('quick-undo-bar')), findsNothing);
    s.stopLive();
  });

  testWidgets('292 pull up past the last post opens the next unread channel', (t) async {
    final (b, s) = await app(t);
    final a = await b.createGroup('부루미 소식', const [], channel: true);
    await b.sendText(a, '첫 글');
    final c = await b.createGroup('여행 채널', const [], channel: true);
    await b.sendText(c, '제주 사진');
    b.unreadCounts[c] = 3;
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('부루미 소식'));
    await t.pumpAndSettle();
    final list = find.byType(ListView).first;
    final g = await t.startGesture(t.getCenter(list));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, -40));
      await t.pump();
    }
    expect(find.byKey(const Key('next-channel')), findsOneWidget);
    expect(find.text('여행 채널'), findsWidgets);
    expect(find.text('놓으면 다음 채널로 가요'), findsOneWidget);
    await g.up();
    await t.pumpAndSettle();
    expect(find.text('제주 사진'), findsOneWidget);
    expect(find.text('첫 글'), findsNothing);
    s.stopLive();
  });

  testWidgets('472 super channel: author photos, an admin may post as the channel', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('여행 기록', const [], channel: true);
    await b.setRoomSwitch(ch, 'sign', true);
    await b.setRoomConfig(ch, 'authors', true);
    b.rooms[ch]!.addAll([
      Msg(id: 'p1', sender: '@sora:test', body: '오늘은 제주', time: b.now, mine: false, kind: 'text'),
      Msg(id: 'p2', sender: '@jun:test', body: '공지: 휴방', time: b.now, mine: false, kind: 'text', postAs: const PostAs.channel()),
    ]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('여행 기록'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('author-p1')), findsOneWidget);
    expect(find.text('@sora'), findsOneWidget);
    expect(find.byKey(const Key('author-p2')), findsNothing);
    expect(find.text('@jun'), findsNothing);
    // I pick 채널 이름으로 from the photo by the field.
    await t.tap(find.byKey(const Key('send-as')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('send-as-sheet')), findsOneWidget);
    await t.tap(find.byKey(const Key('send-as-channel')));
    await t.pumpAndSettle();
    expect(s.pref('send_as:$ch', ''), '{"ch":true}');
    await t.enterText(find.byKey(const Key('composer')), '채널 이름으로 올려요');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle(const Duration(seconds: 6));
    expect(b.rooms[ch]!.last.postAs?.channel, isTrue);
    s.stopLive();
  });

  testWidgets('310 write in a group as my public channel; a false claim shows the real name', (t) async {
    final (b, s) = await app(t);
    final mine = await b.createGroup('내 가게', const [], channel: true);
    await b.setPublicLink(mine, 'mystore');
    final bobs = '!bobs';
    b.outside['bobnews'] = LinkPeek(roomId: bobs, name: '밥의 뉴스', channel: true);
    b.channelAdmins[bobs] = {'@bob:test'};
    final g = await b.createGroup('동네 모임', const []);
    b.rooms[g]!.addAll([
      Msg(id: 'm1', sender: '@bob:test', body: '새 소식 있어요', time: b.now, mine: false, kind: 'text', postAs: PostAs.of(bobs, 'bobnews')),
      Msg(id: 'm2', sender: '@eve:test', body: '저도 밥의 뉴스예요', time: b.now, mine: false, kind: 'text', postAs: PostAs.of(bobs, 'bobnews')),
    ]);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 모임'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('as-channel-m1')), findsOneWidget);
    expect(find.text('밥의 뉴스'), findsOneWidget);
    expect(find.byKey(const Key('as-channel-m2')), findsNothing);
    expect(find.text('@eve'), findsOneWidget);
    await t.tap(find.byKey(const Key('send-as')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(Key('send-as-$mine')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('composer')), '가게 이름으로 인사해요');
    await t.pump();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle(const Duration(seconds: 6));
    final last = b.rooms[g]!.last;
    expect(last.postAs?.room, mine);
    expect(last.postAs?.address, 'mystore');
    s.stopLive();
  });

  testWidgets('526 subscriber: 💬 opens a private room with the admins', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('동네 빵집', const [], channel: true);
    b.owner = false;
    b.roomMembers[ch] = [Member(userId: b.userId!, name: 'me', role: 'member'), const Member(userId: '@baker:test', name: '빵집 사장', role: 'owner')];
    b.roomConfigs[ch] = {'subscriber_dm': true};
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('동네 빵집'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('channel-dm')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dm-empty')), findsOneWidget);
    final room = s.pref('channel_dm:$ch', '');
    expect(room, isNotEmpty);
    expect(b.roomConfigs[room]?['channel_dm'], ch);
    expect(b.roomConfigs[room]?['subscriber'], b.userId);
    s.stopLive();
  });

  testWidgets('526 admin: one 메시지 row per channel, tabs per subscriber, side bar', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('동네 빵집', const [], channel: true);
    b.roomConfigs[ch] = {'subscriber_dm': true};
    final r1 = await b.createGroup('동네 빵집', const []);
    final r2 = await b.createGroup('동네 빵집', const []);
    b.roomConfigs[r1] = {'channel_dm': ch, 'subscriber': '@mina:test'};
    b.roomConfigs[r2] = {'channel_dm': ch, 'subscriber': '@jun:test'};
    b.rooms[r1]!.add(Msg(id: 'a1', sender: '@mina:test', body: '케이크 예약돼요?', time: b.now, mine: false, kind: 'text'));
    b.rooms[r2]!.add(Msg(id: 'b1', sender: '@jun:test', body: '광고 문의예요', time: b.now.add(const Duration(minutes: 1)), mine: false, kind: 'text'));
    b.unreadCounts[r1] = 1;
    b.unreadCounts[r2] = 1;
    // A fake invitation named like my channel is joined, checked and left.
    b.invites.add(const Invite(roomId: '!fake', name: '동네 빵집', inviter: '@eve:test', direct: false));
    await s.refresh();
    expect(b.rooms.containsKey('!fake'), isFalse);
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    expect(find.byKey(Key('dm-inbox-$ch')), findsOneWidget);
    expect(find.byKey(const Key('dm-inbox-tag')), findsOneWidget);
    await t.tap(find.byKey(Key('dm-inbox-$ch')));
    await t.pumpAndSettle();
    expect(find.text('광고 문의예요'), findsOneWidget);
    expect(find.byKey(const Key('dm-inbox-tabs')), findsOneWidget);
    await t.tap(find.byKey(Key('dm-tab-$r1')));
    await t.pumpAndSettle();
    expect(find.text('케이크 예약돼요?'), findsOneWidget);
    await t.tap(find.byKey(const Key('dm-inbox-toggle')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dm-inbox-side')), findsOneWidget);
    // 전체: both people's messages together; a tap opens that chat.
    await t.tap(find.byKey(const Key('dm-tab-all')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dm-all-page')), findsOneWidget);
    expect(find.byKey(const Key('dm-all-a1')), findsOneWidget);
    expect(find.byKey(const Key('dm-all-b1')), findsOneWidget);
    await t.tap(find.byKey(const Key('dm-all-b1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dm-all-page')), findsNothing);
    expect(find.text('광고 문의예요'), findsOneWidget);
    s.stopLive();
  });
}
