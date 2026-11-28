// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사진 보내기 묶음 #8 (Telegram tips 75 + 323 미리보기·순서 바꾸기, 529
// 표준/HD, 273 대화 안 핀치 확대, 369 한 장씩 가리기, 56 동영상 자르기·
// 회전). Screenshots at iPhone size (393 x 852) in test/shots/p8_*.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/media_tags.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/core/photo_size.dart';
import 'package:burumy/core/video_edit.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/attach_sheet.dart';
import 'package:burumy/ui/settings_pages.dart' show DataPage;
import 'package:burumy/ui/video_editor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  test('표준 / HD sizes', () {
    expect(PhotoQuality.standard.longSide, 1280);
    expect(PhotoQuality.hd.longSide, 2560);
    expect(PhotoSize.fitSize(4032, 3024, 1280), (1280, 960));
    expect(PhotoSize.fitSize(3024, 4032, 2560), (1920, 2560));
    // Never made bigger.
    expect(PhotoSize.fitSize(800, 600, 1280), (800, 600));
    expect(PhotoSize.jpgName('IMG_1.HEIC'), 'IMG_1.jpg');
    expect(PhotoSize.jpgName('noext'), 'noext.jpg');
    expect(PhotoSize.canShrink('a.png'), isTrue);
    expect(PhotoSize.canShrink('a.heic'), isTrue);
    // Moving pictures stay as they are.
    expect(PhotoSize.canShrink('a.gif'), isFalse);
    expect(PhotoSize.canShrink('a.webp'), isFalse);
    expect(PhotoSize.hasSeeThrough(Uint8List.fromList([1, 2, 3, 255, 4, 5, 6, 255])), isFalse);
    expect(PhotoSize.hasSeeThrough(Uint8List.fromList([1, 2, 3, 255, 4, 5, 6, 0])), isTrue);
  });

  testWidgets('a big photo goes out at 1280 px (standard) or 2560 px (HD) as JPEG', (t) async {
    final big = img.Image(width: 3200, height: 2400);
    img.fill(big, color: img.ColorRgb8(120, 180, 220));
    img.fillCircle(big, x: 1600, y: 1200, radius: 600, color: img.ColorRgb8(250, 220, 90));
    final png = Uint8List.fromList(img.encodePng(big, level: 1));
    final std = (await t.runAsync(() => PhotoSize.fit('IMG_9.png', png, PhotoQuality.standard)))!;
    expect(std.name, 'IMG_9.jpg');
    final a = img.decodeJpg(std.bytes)!;
    expect((a.width, a.height), (1280, 960));
    final hd = (await t.runAsync(() => PhotoSize.fit('IMG_9.png', png, PhotoQuality.hd)))!;
    final b = img.decodeJpg(hd.bytes)!;
    expect((b.width, b.height), (2560, 1920));
    // A small JPEG is kept untouched (no second blur).
    final small = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
    final same = (await t.runAsync(() => PhotoSize.fit('s.jpg', small, PhotoQuality.standard)))!;
    expect(identical(same.bytes, small), isTrue);
    // A GIF passes as is.
    final gif = Uint8List.fromList([0x47, 0x49, 0x46, 0x38]);
    expect((await PhotoSize.fit('a.gif', gif, PhotoQuality.standard)).bytes, gif);
  });

  test('video edit: length, turns, what the phone gets', () {
    expect(VideoEdit.none.isNone, isTrue);
    const e = VideoEdit(start: Duration(seconds: 3), end: Duration(seconds: 12), turns: 5, flip: true);
    expect(e.trims, isTrue);
    expect(e.turnsOrFlips, isTrue);
    expect(e.sideways, isTrue);
    expect(e.degrees, 90);
    expect(e.lengthOf(const Duration(seconds: 40)), const Duration(seconds: 9));
    expect(e.lengthOf(const Duration(seconds: 8)), const Duration(seconds: 5));
    expect(e.toChannel(), {'startMs': 3000, 'endMs': 12000, 'turns': 1, 'flip': true});
    expect(const VideoEdit(turns: 4).isNone, isTrue);
    expect(const VideoEdit(start: Duration(seconds: 2)).toChannel()['endMs'], -1);
    expect(clockText(const Duration(seconds: 65)), '1:05');
    expect(clockText(const Duration(hours: 1, seconds: 5)), '1:00:05');
  });

  test('a picked file keeps its cover and cut through other changes', () {
    final f = PickedFile('a.mp4', Uint8List(4)).withSpoiler(true).withVideo(const VideoEdit(turns: 1)).withMuted(true);
    expect((f.spoiler, f.video.turns, f.muted), (true, 1, true));
    final p = PickedFile('b.jpg', Uint8List(4)).withSpoiler(true).edited(Uint8List(2));
    expect((p.name, p.spoiler, p.isEdited), ('b.png', true, true));
    expect(p.asOriginal().spoiler, isFalse);
    expect(PickedFile('c.pdf', Uint8List(1)).isMedia, isFalse);
  });

  group('screens', () {
    setUpAll(() async {
      await loadFont('Pretendard', [
        'assets/fonts/Pretendard-Regular.otf',
        'assets/fonts/Pretendard-Medium.otf',
        'assets/fonts/Pretendard-SemiBold.otf',
        'assets/fonts/Pretendard-Bold.otf',
      ]);
      final home = Platform.environment['HOME'];
      await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    });

    Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/p8_$name.png'));

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    late Uint8List pic, pic2, clip;
    late List<Uint8List> strip;
    final edits = <Map<String, Object>>[];
    final fits = <(String, PhotoQuality)>[];

    setUp(() {
      Features.photoSend = true;
      pic = Uint8List.fromList(File('test/assets/sample_photo.png').readAsBytesSync());
      pic2 = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      clip = Uint8List.fromList(File('assets/demo/live.mp4').readAsBytesSync());
      strip = [for (var i = 0; i < 10; i++) i.isEven ? pic : pic2];
      edits.clear();
      fits.clear();
      Phone.debugRecent = (_) async => [
        PhoneMedia('p1', pic),
        PhoneMedia('v1', pic2, video: true, duration: const Duration(seconds: 40)),
        PhoneMedia('p2', pic2),
        for (var i = 3; i < 9; i++) PhoneMedia('p$i', i.isEven ? pic2 : pic),
      ];
      Phone.debugLoadFile = (id) async => id == 'v1' ? PhoneFile('walk.mp4', clip) : PhoneFile('IMG_$id.png', id == 'p1' ? pic : pic2);
      Phone.debugVideoFrames = (_, n) async => strip.take(n).toList();
      Phone.debugEditVideo = (v, e) async {
        edits.add(e);
        return v;
      };
      PhotoSize.debugFit = (name, bytes, q) async {
        fits.add((name, q));
        return (name: PhotoSize.jpgName(name), bytes: bytes);
      };
      VideoEditorPage.debugLength = const Duration(seconds: 40);
    });

    tearDown(() {
      Features.photoSend = false;
      Phone.debugRecent = null;
      Phone.debugLoadFile = null;
      Phone.debugVideoFrames = null;
      Phone.debugEditVideo = null;
      PhotoSize.debugFit = null;
      VideoEditorPage.debugLength = null;
    });

    Future<(FakeBackend, String)> openChat(WidgetTester t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      final room = await b.createDirectChat('@daeun:test');
      b.files['r1'] = pic2;
      b.rooms[room]!.add(
        Msg(id: 'r1', sender: '@daeun:test', body: 'beach.jpg', caption: '오늘 바다', time: DateTime(2026, 11, 27, 9, 41), mine: false, kind: 'image'),
      );
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('daeun').first);
      await settle(t);
      return (b, room);
    }

    testWidgets('preview, order, cover one, HD, trim and turn a video, send', (t) async {
      final (b, room) = await openChat(t);
      await t.tap(find.byKey(const Key('attach')));
      await settle(t);
      for (final id in ['p1', 'v1', 'p2']) {
        await t.tap(find.byKey(Key('attach-live-$id')));
        await settle(t);
      }
      // HD chip (off = 표준) next to the caption.
      expect(find.byKey(const Key('attach-hd')), findsOneWidget);
      await t.tap(find.byKey(const Key('attach-hd')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('HD 화질로 보내요'), findsOneWidget);
      await shot(t, '1_hd_on');
      await t.pumpAndSettle(const Duration(seconds: 3));

      // Tap the chosen video: the editor.
      await t.tap(find.byKey(const Key('attach-live-v1')));
      await settle(t);
      expect(find.byKey(const Key('video-editor')), findsOneWidget);
      await t.drag(find.byKey(const Key('vedit-handle-start')), const Offset(40, 0));
      await t.drag(find.byKey(const Key('vedit-handle-end')), const Offset(-120, 0));
      await t.tap(find.byKey(const Key('vedit-rotate')));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.byKey(const Key('vedit-flip')));
      await t.pump(const Duration(milliseconds: 100));
      final len = t.widget<Text>(find.byKey(const Key('vedit-length'))).data!;
      expect(len, isNot('0:40'));
      await shot(t, '2_video_editor');
      await t.tap(find.byKey(const Key('vedit-done')));
      await settle(t);
      expect(find.byKey(const Key('video-editor')), findsNothing);

      // 3개 선택 ›: the preview, like the bubble.
      await t.tap(find.byKey(const Key('attach-preview')));
      await settle(t);
      expect(find.byKey(const Key('attach-preview-album')), findsOneWidget);
      // Hold the first photo and drop it on the last one: new order.
      final first = t.getCenter(find.byKey(const Key('attach-square-0')));
      final last = t.getCenter(find.byKey(const Key('attach-square-2')));
      final g = await t.startGesture(first);
      await t.pump(const Duration(milliseconds: 400));
      await g.moveTo(Offset.lerp(first, last, 0.5)!);
      await t.pump(const Duration(milliseconds: 50));
      await g.moveTo(last);
      await t.pump(const Duration(milliseconds: 50));
      await shot(t, '3_preview_drag');
      await g.up();
      await settle(t);
      // Tap a square: cover only that one.
      await t.tap(find.byKey(const Key('attach-square-1')));
      await settle(t);
      expect(find.byKey(const Key('square-spoiler')), findsOneWidget);
      await shot(t, '4_square_menu');
      await t.tap(find.byKey(const Key('square-spoiler')));
      await settle(t);
      expect(find.text('1개 가림'), findsOneWidget);
      await shot(t, '5_preview_covered');

      await t.tap(find.byKey(const Key('attach-send')));
      await settle(t);
      final sent = b.rooms[room]!.where((m) => m.mine && (m.kind == 'image' || m.kind == 'video')).toList();
      expect(sent.map((m) => MediaTags.plain(m.body)), ['walk.mp4', 'IMG_p2.jpg', 'IMG_p1.jpg'], reason: '${sent.map((m) => m.body)}');
      final tags = sent.map((m) => MediaTags.of(m.body)).toList();
      expect(tags.map((x) => x.index), [0, 1, 2]);
      expect(tags.map((x) => x.spoiler), [false, true, false]);
      expect(fits.map((x) => x.$2).toSet(), {PhotoQuality.hd});
      expect(edits.single['turns'], 1);
      expect(edits.single['flip'], true);
      expect(edits.single['startMs'] as int, greaterThan(0));
      expect(edits.single['endMs'] as int, lessThan(40000));
      expect(find.byKey(const Key('album-grid')), findsOneWidget);
      await shot(t, '6_chat_album');
      // Let the toasts go (the dust keeps moving, so no settle).
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('a failed video cut sends nothing of that video', (t) async {
      final (b, room) = await openChat(t);
      Phone.debugEditVideo = (v, e) async => null;
      await t.tap(find.byKey(const Key('attach')));
      await settle(t);
      await t.tap(find.byKey(const Key('attach-live-v1')));
      await settle(t);
      await t.tap(find.byKey(const Key('attach-live-v1')));
      await settle(t);
      await t.tap(find.byKey(const Key('vedit-rotate')));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.byKey(const Key('vedit-done')));
      await settle(t);
      await t.tap(find.byKey(const Key('attach-send')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('영상을 편집하지 못해서 보내지 않았어요'), findsOneWidget);
      await t.pumpAndSettle(const Duration(seconds: 3));
      expect(b.rooms[room]!.where((m) => m.mine && m.kind == 'video'), isEmpty);
    });

    testWidgets('two fingers lift a chat photo; letting go puts it back', (t) async {
      await openChat(t);
      final photo = find.byKey(const Key('pinch-r1'));
      expect(photo, findsOneWidget);
      final c = t.getCenter(photo);
      final a = await t.startGesture(c - const Offset(20, 0), pointer: 1);
      final z = await t.startGesture(c + const Offset(20, 0), pointer: 2);
      await t.pump();
      await a.moveTo(c - const Offset(90, 20));
      await z.moveTo(c + const Offset(90, 20));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byKey(const Key('pinch-lifted')), findsOneWidget);
      final big = t.getSize(find.byKey(const Key('pinch-lifted')));
      expect(big.width, greaterThan(t.getSize(photo).width * 2));
      await shot(t, '7_pinch');
      await a.up();
      await z.up();
      await t.pumpAndSettle();
      expect(find.byKey(const Key('pinch-lifted')), findsNothing);
      // One finger still scrolls / taps (opens the photo screen).
      await t.tap(photo);
      await settle(t);
      expect(find.byKey(const Key('photo-view')), findsOneWidget);
    });

    testWidgets('Settings > 데이터: HD by default', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      Navigator.of(t.element(find.text('대화').last)).push(CupertinoPageRoute<void>(builder: (_) => const DataPage()));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.byKey(const Key('pref-photo_hd')),
        200,
        scrollable: find.descendant(of: find.byType(DataPage), matching: find.byType(Scrollable)).first,
      );
      await t.pumpAndSettle();
      await shot(t, '8_settings_hd');
      await t.tap(find.byKey(const Key('pref-photo_hd')));
      await t.pumpAndSettle();
      expect(s.on('photo_hd'), isTrue);
    });
  });
}
