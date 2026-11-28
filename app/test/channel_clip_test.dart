// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널 짧은 영상 (4-app board, WhatsApp 2025): in a channel, 카메라 opens
// our own camera on 영상; the clip joins the post and is sent as a video.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/story_camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> tap(WidgetTester t, String key) async {
  final f = find.byKey(Key(key)).last;
  await t.ensureVisible(f);
  await t.pump(const Duration(milliseconds: 500));
  await t.tap(f);
  await t.pump(const Duration(milliseconds: 800));
}

void main() {
  testWidgets('channel: 카메라 → 영상 → record → it is in the post → sent', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    StoryCameraPage.fake = true;
    addTearDown(() => StoryCameraPage.fake = false);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final ch = await b.createGroup('부루미 소식', const [], channel: true);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('부루미 소식'));
    await t.pumpAndSettle();
    await tap(t, 'attach');
    await tap(t, 'attach-camera');
    expect(find.byType(StoryCameraPage), findsOneWidget);
    // Opens on 영상, and there is no 라이브 here.
    expect(find.byKey(const Key('cam-mode-live')), findsNothing);
    await tap(t, 'cam-shutter');
    expect(find.byKey(const Key('cam-rec-time')), findsOneWidget);
    await tap(t, 'cam-shutter');
    await t.pump(const Duration(milliseconds: 800));
    expect(find.byType(StoryCameraPage), findsNothing);
    await tap(t, 'attach-send');
    await t.pumpAndSettle();
    final sent = b.rooms[ch]!.last;
    expect(sent.kind, 'video');
  });
}
