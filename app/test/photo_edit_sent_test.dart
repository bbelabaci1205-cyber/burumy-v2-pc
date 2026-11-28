// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// #9 보낸 사진 고치기 (Telegram tips 452 B, 482, 81, 224): 설명 위로 when
// sending, editing a sent photo's words and their place, swapping the
// photo in a 1:1 chat ("사진 바뀜", the old one in 메시지 정보), adding a
// photo to a sent text, and no swaps in a public group. Screenshots at
// iPhone size (393 x 852) in test/shots.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/photo_stickers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'photo_send_test.dart' show loadFont;

Msg mine(String id, String kind, String body, {String? caption}) =>
    Msg(id: id, sender: '@me:test', body: body, caption: caption, time: DateTime(2026, 11, 27, 9, 41), mine: true, kind: kind);

void main() {
  test('fake backend: caption, swap, and no swaps in public rooms', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@daeun:test');
    b.files['m1'] = [1, 2, 3];
    b.rooms[room]!.add(mine('m1', 'image', 'a.png', caption: '처음'));
    await b.editMedia(room, 'm1', caption: '고침', captionAbove: true);
    var m = b.rooms[room]!.last;
    expect((m.caption, m.captionAbove, m.mediaChanged, m.firstBody, m.fileId), ('고침', true, false, '처음', 'm1'));
    await b.editMedia(room, 'm1', caption: '새 사진', name: 'b.jpg', mime: 'image/jpeg', bytes: [9, 9]);
    m = b.rooms[room]!.last;
    expect(m.mediaChanged, isTrue);
    expect(m.fileId, isNot('m1'));
    expect(await b.downloadFile(room, m.fileId), [9, 9]);
    expect(await b.downloadFile(room, m.id), [1, 2, 3]); // the old one stays
    // A text gets a photo.
    b.rooms[room]!.add(mine('t1', 'text', '사진 보낼게'));
    await b.editMedia(room, 't1', caption: '사진 보낼게', name: 'c.png', mime: 'image/png', bytes: [7]);
    m = b.rooms[room]!.last;
    expect((m.kind, m.caption, m.firstBody), ('image', '사진 보낼게', '사진 보낼게'));
    // Public group: words yes, swaps no.
    final g = await b.createGroup('공개', const []);
    await b.setPublicLink(g, 'opengroup');
    b.rooms[g]!.add(mine('p1', 'image', 'p.png', caption: 'x'));
    await b.editMedia(g, 'p1', caption: 'y');
    expect(b.rooms[g]!.last.caption, 'y');
    expect(() => b.editMedia(g, 'p1', caption: 'y', name: 'q.png', mime: 'image/png', bytes: [1]), throwsStateError);
  });

  group('screens', () {
    setUpAll(() async {
      await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
      final home = Platform.environment['HOME'];
      await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    });

    Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_48_edit_sent_$name.png'));

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    testWidgets('caption above, edit words, swap the photo, add a photo to a text', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pic = Uint8List.fromList(File('test/assets/sample_photo.png').readAsBytesSync());
      final pic2 = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      final room = await b.createDirectChat('@daeun:test');
      b.files['m1'] = pic;
      b.rooms[room]!.add(mine('m1', 'image', 'sea.png', caption: '오늘 바다'));
      b.rooms[room]!.add(mine('t1', 'text', '사진은 이따 보낼게'));
      debugPickSwap = () async => ('beach.jpg', pic2);
      addTearDown(() => debugPickSwap = null);
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('daeun').first);
      await settle(t);

      // 1. Edit the photo's words and move them above (452 B).
      await t.longPress(find.text('오늘 바다'));
      await settle(t);
      await t.tap(find.byKey(const Key('menu-edit')));
      await settle(t);
      expect(find.text('사진 수정'), findsOneWidget);
      expect(find.byKey(const Key('edit-media-thumb')), findsOneWidget);
      await t.enterText(find.byKey(const Key('composer')), '오늘 바다 최고');
      await t.tap(find.byKey(const Key('mode-options')));
      await settle(t);
      expect(find.byKey(const Key('edit-media-sheet')), findsOneWidget);
      await shot(t, '1_options');
      await t.tap(find.byKey(const Key('edit-media-above')));
      await settle(t);
      await t.tap(find.byKey(const Key('send')));
      await settle(t);
      var m = b.rooms[room]!.firstWhere((x) => x.id == 'm1');
      expect((m.caption, m.captionAbove, m.mediaChanged), ('오늘 바다 최고', true, false));
      expect(find.byKey(const Key('caption-above')), findsOneWidget);
      await shot(t, '2_caption_above');

      // 2. Swap the photo (1:1 chat): "사진 바뀜", the old one in 메시지 정보.
      await t.longPress(find.text('오늘 바다 최고'));
      await settle(t);
      await t.tap(find.byKey(const Key('menu-edit')));
      await settle(t);
      await t.tap(find.byKey(const Key('mode-options')));
      await settle(t);
      await t.tap(find.byKey(const Key('edit-media-swap')));
      await settle(t);
      expect(find.text('새 사진으로 바뀌어요'), findsOneWidget);
      await shot(t, '3_swap_picked');
      await t.tap(find.byKey(const Key('send')));
      await settle(t);
      m = b.rooms[room]!.firstWhere((x) => x.id == 'm1');
      expect(m.mediaChanged, isTrue);
      expect(await b.downloadFile(room, m.fileId), pic2);
      expect(find.text('사진 바뀜 '), findsOneWidget);
      await shot(t, '4_swapped');

      // 3. A sent text gets a photo (482).
      await t.longPress(find.text('사진은 이따 보낼게'));
      await settle(t);
      await t.tap(find.byKey(const Key('menu-edit')));
      await settle(t);
      await t.tap(find.byKey(const Key('mode-options')));
      await settle(t);
      await t.tap(find.byKey(const Key('edit-media-add')));
      await settle(t);
      await t.tap(find.byKey(const Key('send')));
      await settle(t);
      final t1 = b.rooms[room]!.firstWhere((x) => x.id == 't1');
      expect((t1.kind, t1.caption), ('image', '사진은 이따 보낼게'));
      await shot(t, '5_text_got_photo');
    });

    testWidgets('public group: only the words can change', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pic = Uint8List.fromList(File('test/assets/sample_photo.png').readAsBytesSync());
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      final g = await b.createGroup('동네 모임', const ['@daeun:test', '@minji:test']);
      await b.setPublicLink(g, 'townmeet');
      b.files['p1'] = pic;
      b.rooms[g]!.add(mine('p1', 'image', 'p.png', caption: '모임 사진'));
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      await t.tap(find.text('동네 모임').first);
      await settle(t);
      await t.longPress(find.text('모임 사진'));
      await settle(t);
      await t.tap(find.byKey(const Key('menu-edit')));
      await settle(t);
      await t.tap(find.byKey(const Key('mode-options')));
      await settle(t);
      expect(find.text('공개 그룹·채널에서는 보낸 사진을 바꿀 수 없어요. 설명만 고칠 수 있어요.'), findsOneWidget);
      expect(find.byKey(const Key('edit-media-swap')), findsNothing);
      expect(find.byKey(const Key('edit-media-draw')), findsNothing);
      expect(find.byKey(const Key('edit-media-above')), findsOneWidget);
      await shot(t, '6_public_words_only');
    });
  });
}
