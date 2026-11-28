// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사진 보내기·편집 (Telegram tips 55, 70, 72, 76, 77, 111, 118, 324):
// marks in the file name, the album mosaic, auto fix, the chat photo editor
// (words, six pens, undo), the "+" sheet ⋯ menu (together / separately /
// 가리기 / original), 갤러리 ⌄ albums, video sound off = GIF, and editing a
// received photo. Screenshots at iPhone size (393 x 852) in test/shots.
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/media_tags.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/album.dart';
import 'package:burumy/ui/media_editor.dart';
import 'package:burumy/ui/photo_editor.dart';
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

Msg photo(String id, String name, {bool mine = false, String? caption, String kind = 'image'}) =>
    Msg(id: id, sender: mine ? '@me:test' : '@daeun:test', body: name, caption: caption, time: DateTime(2026, 11, 27, 9, 41), mine: mine, kind: kind);

void main() {
  test('marks in the file name', () {
    const t = MediaTags(album: 'k3x', index: 1, count: 3, spoiler: true, gif: true);
    final n = t.apply('IMG_1.mov');
    expect(n, 'bm_ak3x-1-3_s_g__IMG_1.mov');
    final back = MediaTags.of(n);
    expect((back.album, back.index, back.count, back.spoiler, back.gif), ('k3x', 1, 3, true, true));
    expect(MediaTags.plain(n), 'IMG_1.mov');
    expect(MediaTags.of('photo.png').any, isFalse);
    expect(MediaTags.plain('bm_no_end.png'), 'bm_no_end.png');
    expect(const MediaTags().apply('a.png'), 'a.png');
  });

  test('album rows and folding', () {
    expect(albumRows(2), [2]);
    expect(albumRows(3), [1, 2]);
    expect(albumRows(5), [2, 3]);
    expect(albumRows(7).fold<int>(0, (a, b) => a + b), 7);
    final list = [
      photo('a', 'bm_ax-0-3__1.png'),
      photo('t', 'hello', kind: 'text'),
      photo('b', 'bm_ax-1-3__2.png'),
      photo('c', 'bm_ax-2-3__3.png', caption: 'three'),
      // Same album id from someone else never folds in.
      photo('z', 'bm_ax-0-1__9.png', mine: true),
    ];
    final (rows, albums) = foldAlbums(list);
    expect(rows.map((m) => m.id), ['a', 't', 'z']);
    expect(albums['a']!.map((m) => m.id), ['a', 'b', 'c']);
  });

  test('auto fix stretches a dull photo and leaves 0 alone', () {
    // A grey, flat picture (60..140).
    final rgba = Uint8List(4 * 100);
    for (var i = 0; i < 100; i++) {
      final v = 60 + (i * 80 ~/ 100);
      rgba.setAll(i * 4, [v, v, v, 255]);
    }
    final s = AutoStats.of(rgba);
    expect(s.low, lessThan(70));
    expect(s.high, greaterThan(130));
    expect(autoMatrix(s, 0), Cm.identity);
    final m = autoMatrix(s, 1);
    expect(m[0], greaterThan(1.2)); // more contrast
    final st = EditState()..stats = s;
    expect(st.untouched, isTrue);
    st.auto = 0.5;
    expect(st.untouched, isFalse);
    st.reset();
    expect(st.auto, 0);
  });

  test('rainbow bar ends', () {
    expect(rainbowAt(0), const Color(0xFFFFFFFF));
    expect(rainbowAt(1), const Color(0xFF000000));
  });

  group('screens', () {
    setUpAll(() async {
      await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
      final home = Platform.environment['HOME'];
      await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    });

    Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_46_photo_$name.png'));

    Future<void> settle(WidgetTester t) async {
      // Real image decoding runs outside fake time; the editor's spinner
      // never settles while it waits, so pump in steps instead.
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    testWidgets('send, edit, album, gif, spoiler', (t) async {
      t.view.physicalSize = const Size(393 * 3, 852 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final pic = Uint8List.fromList(File('test/assets/sample_photo.png').readAsBytesSync());
      final pic2 = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      final clip = Uint8List.fromList(File('assets/demo/live.mp4').readAsBytesSync());
      final b = FakeBackend();
      final s = AppState(b, locale: const Locale('ko'));
      await b.login(id: 'me', password: 'x');
      final room = await b.createDirectChat('@daeun:test');
      b.files['r1'] = pic2;
      b.rooms[room]!.add(photo('r1', 'beach.jpg', caption: '오늘 바다'));
      Phone.debugRecent = (_) async => [
        PhoneMedia('p1', pic),
        PhoneMedia('v1', pic2, video: true, duration: const Duration(seconds: 3)),
        for (var i = 2; i < 9; i++) PhoneMedia('p$i', i.isEven ? pic2 : pic),
      ];
      Phone.debugAlbums = () async => const [
        PhoneAlbum(PhoneAlbum.recentsId, 9),
        PhoneAlbum('favorites', 2),
        PhoneAlbum('videos', 1),
        PhoneAlbum('screenshots', 3),
        PhoneAlbum('c:1', 4, name: '제주 여행'),
      ];
      Phone.debugAlbumRecent = (_, a) async => a == 'videos' ? [PhoneMedia('v1', pic2, video: true, duration: const Duration(seconds: 3))] : [PhoneMedia('p1', pic)];
      Phone.debugLoadFile = (id) async => id == 'v1' ? PhoneFile('clip.mp4', clip) : PhoneFile('IMG_$id.png', id == 'p1' ? pic : pic2);
      var stripped = 0;
      Phone.debugStripAudio = (v) async {
        stripped++;
        return v;
      };
      addTearDown(() {
        Phone.debugRecent = null;
        Phone.debugAlbums = null;
        Phone.debugAlbumRecent = null;
        Phone.debugLoadFile = null;
        Phone.debugStripAudio = null;
      });
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      await t.tap(find.textContaining('daeun').first);
      await settle(t);

      // 갤러리 ⌄: albums with counts; picking one shows only its photos.
      await t.tap(find.byKey(const Key('attach')));
      await settle(t);
      expect(find.text('최근 항목'), findsOneWidget);
      await t.tap(find.byKey(const Key('attach-album')));
      await settle(t);
      expect(find.text('제주 여행'), findsOneWidget);
      await shot(t, '1_albums');
      await t.tap(find.byKey(const Key('album-videos')));
      await settle(t);
      expect(find.byKey(const Key('attach-live-p1')), findsNothing);
      expect(find.byKey(const Key('attach-live-v1')), findsOneWidget);
      await t.tap(find.byKey(const Key('attach-album')));
      await settle(t);
      await t.tap(find.byKey(const Key('album-recents')));
      await settle(t);

      // Choose a photo and a video; video sound off = GIF.
      await t.tap(find.byKey(const Key('attach-live-p1')));
      await settle(t);
      await t.tap(find.byKey(const Key('attach-live-v1')));
      await settle(t);
      await t.tap(find.byKey(const Key('attach-mute-1')));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('소리를 껐어요. GIF로 보내요'), findsOneWidget);
      await shot(t, '2_chosen_gif');
      await t.pumpAndSettle(const Duration(seconds: 3));

      // ⋯ menu: together (ticked), separately, spoiler, as file.
      await t.tap(find.byKey(const Key('attach-more')));
      await settle(t);
      expect(find.text('묶어서 보내기'), findsOneWidget);
      await shot(t, '3_more_menu');
      await t.tap(find.byKey(const Key('attach-spoiler')));
      await settle(t);
      expect(find.byKey(const Key('attach-mode-pill')), findsOneWidget);

      // Tap the chosen photo: the editor.
      await t.tap(find.byKey(const Key('attach-live-p1')));
      await settle(t);
      expect(find.byKey(const Key('media-editor')), findsOneWidget);
      await t.tap(find.byKey(const Key('medit-auto')));
      await t.pump();
      await t.drag(find.byKey(const Key('medit-dial')), const Offset(-90, 0));
      await settle(t);
      expect(find.textContaining('자동  '), findsOneWidget);
      await shot(t, '4_editor_auto');
      // Draw with the neon pen and the blur pen, undo once.
      await t.tap(find.byKey(const Key('medit-mode-draw')));
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byKey(const Key('medit-pen-neon')));
      await t.tap(find.byKey(const Key('medit-rainbow')), warnIfMissed: false);
      final pad = t.getCenter(find.byKey(const Key('medit-draw-pad')));
      await t.dragFrom(pad - const Offset(100, 60), const Offset(200, 40));
      await t.tap(find.byKey(const Key('medit-pen-blur')));
      await t.dragFrom(pad + const Offset(-80, 60), const Offset(160, 0));
      await t.tap(find.byKey(const Key('medit-pen-arrow')));
      await t.dragFrom(pad + const Offset(-60, 120), const Offset(120, -30));
      await settle(t);
      await shot(t, '5_editor_draw');
      await t.tap(find.byKey(const Key('medit-undo')));
      await t.pump();
      // Words in the box look.
      await t.tap(find.byKey(const Key('medit-mode-text')));
      await settle(t);
      await t.enterText(find.byKey(const Key('medit-text-input')), '바다 최고');
      await t.tap(find.byKey(const Key('medit-text-look')));
      await t.tap(find.byKey(const Key('medit-text-look')));
      await t.pump(const Duration(milliseconds: 300));
      await shot(t, '6_editor_text');
      await t.tap(find.byKey(const Key('medit-text-done')));
      await settle(t);
      await shot(t, '7_editor_done');
      await t.tap(find.byKey(const Key('medit-done')));
      await settle(t);
      expect(find.byKey(const Key('media-editor')), findsNothing);

      await t.tap(find.byKey(const Key('attach-send')));
      await settle(t);
      final sent = b.rooms[room]!.where((m) => m.mine && (m.kind == 'image' || m.kind == 'video')).toList();
      expect(sent.length, 2, reason: '${sent.map((m) => m.body)}');
      final t0 = MediaTags.of(sent[0].body), t1 = MediaTags.of(sent[1].body);
      expect(t0.album, isNotNull);
      expect(t0.album, t1.album);
      expect((t0.index, t1.index, t0.count), (0, 1, 2));
      expect(t0.spoiler && t1.spoiler, isTrue);
      expect(t1.gif, isTrue);
      expect(MediaTags.plain(sent[0].body), 'IMG_p1.png');
      expect(stripped, 1);
      // One album bubble in the chat.
      expect(find.byKey(const Key('album-grid')), findsOneWidget);
      await shot(t, '8_chat_album');

      // A received photo: open big, edit and send as a new message.
      await t.tap(find.byKey(const Key('photo-r1')));
      await settle(t);
      expect(find.byKey(const Key('photo-view')), findsOneWidget);
      await shot(t, '9_viewer');
      await t.tap(find.byKey(const Key('photo-edit-send')));
      await settle(t);
      await t.tap(find.byKey(const Key('medit-mode-draw')));
      await t.pump(const Duration(milliseconds: 300));
      final pad2 = t.getCenter(find.byKey(const Key('medit-draw-pad')));
      await t.dragFrom(pad2, const Offset(80, 80));
      await t.tap(find.byKey(const Key('medit-done')));
      await settle(t);
      final last = b.rooms[room]!.last;
      expect(last.mine, isTrue);
      expect(last.body, startsWith('edited-'));
    });
  });
}
