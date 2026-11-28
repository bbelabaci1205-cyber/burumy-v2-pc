// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 사진 (TelegramTips 563): screenshots at iPhone size (393 x 852):
// a Live Photo chosen in the "+" sheet (LIVE ⌄), the style menu, the note
// after picking, and the LIVE capsule on photos in the chat.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });

  Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_41_live_$name.png'));

  Future<void> settle(WidgetTester t) async {
    // Let the photos decode (real image decoding runs outside fake time).
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await t.pumpAndSettle();
    }
  }

  testWidgets('shots: choose a style, then the chat', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final still = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
    final clip = Uint8List.fromList(File('assets/demo/live.mp4').readAsBytesSync());
    final photo = Uint8List.fromList(File('test/assets/sample_photo.png').readAsBytesSync());
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@haneul:test');
    b.files['lv1'] = still;
    b.liveClips['lv1'] = clip;
    b.rooms[room]!.add(
      Msg(
        id: 'lv1',
        sender: '@haneul:test',
        body: 'sea.jpg',
        caption: '방금 바다 앞이에요 🌊',
        time: DateTime(2026, 11, 27, 9, 41),
        mine: false,
        kind: 'image',
        live: const LiveInfo('live', Duration(seconds: 3)),
      ),
    );
    Phone.debugRecent = (_) async => [
      PhoneMedia('p1', still, live: true),
      for (var i = 2; i < 10; i++) PhoneMedia('p$i', i.isEven ? photo : still, live: i == 5),
    ];
    Phone.debugLoadFile = (id) async => id == 'p1' ? PhoneFile('IMG_0001.jpg', still, clip: clip) : PhoneFile('IMG_000$id.png', photo);
    addTearDown(() {
      Phone.debugRecent = null;
      Phone.debugLoadFile = null;
    });
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('haneul').first);
    await settle(t);
    await shot(t, '4_chat');
    await t.tap(find.byKey(const Key('attach')));
    await settle(t);
    await t.tap(find.byKey(const Key('attach-live-p1')));
    await settle(t);
    await shot(t, '1_chosen');
    await t.tap(find.byKey(const Key('attach-live-style-0')));
    await settle(t);
    await shot(t, '2_menu');
    await t.tap(find.byKey(const Key('live-style-loop')));
    await t.pump(const Duration(milliseconds: 400));
    await shot(t, '3_toast');
    await t.pumpAndSettle(const Duration(seconds: 2));
    await t.tap(find.byKey(const Key('attach-send')));
    await settle(t);
    await shot(t, '5_sent');
    s.stopLive();
  });
}
