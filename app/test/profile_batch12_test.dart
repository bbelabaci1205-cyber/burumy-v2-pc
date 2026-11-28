// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 프로필 묶음 #12 (Telegram tips 195 큰 사진 머리, 445 남에게 보이는 내 프로필,
// 58 예전 사진, 374 공개 사진, 373 사진 제안, 376 + 351 이모지 사진).
// Screenshots at iPhone size (393 x 852) in test/shots/p12_*.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/my_photos.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/emoji_photo.dart';
import 'package:burumy/ui/my_profile_page.dart';
import 'package:burumy/ui/profile_header.dart';
import 'package:burumy/ui/profile_page.dart';
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

Uint8List square(int r, int g, int b, {int size = 300}) {
  final im = img.Image(width: size, height: size);
  img.fill(im, color: img.ColorRgb8(r, g, b));
  img.fillCircle(im, x: size ~/ 2, y: size ~/ 2, radius: size ~/ 4, color: img.ColorRgb8(255, 255, 255));
  return Uint8List.fromList(img.encodePng(im));
}

Future<(FakeBackend, AppState)> app(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  return (b, s);
}

void main() {
  setUp(() => Features.profile = true);
  tearDown(() => Features.profile = false);

  testWidgets('58 earlier photos: kept on change, newest first, max 6, back as 대표 사진, delete main', (t) async {
    final (b, s) = await app(t);
    final photos = [for (var i = 0; i < 8; i++) square(20 * i, 100, 200)];
    for (final (i, p) in photos.indexed) {
      await t.runAsync(() => s.saveMyProfile(photo: p, now: DateTime(2026, 11, 1 + i)));
    }
    final ids = MyPhotos.ids(s);
    expect(ids.length, MyPhotos.max, reason: 'only six kept');
    // Newest earlier photo first; small JPEG copies.
    expect(img.decodeImage(MyPhotos.bytes(s, ids.first)!)!.getPixel(0, 0).r, 20 * 6);
    expect(MyPhotos.since(ids.first), DateTime(2026, 11, 8));
    expect(s.myOwnPhoto, photos.last);
    // Older keys are gone from the settings.
    expect(b.prefs.keys.where((k) => k.startsWith('me_photo_old:')).length, MyPhotos.max);

    // An earlier one becomes 대표 사진; the current one moves into the list.
    await t.runAsync(() => MyPhotos.makeMain(s, ids[2]));
    expect(img.decodeImage(s.myOwnPhoto!)!.getPixel(0, 0).r, 20 * 4);
    expect(MyPhotos.ids(s).length, MyPhotos.max);
    expect(img.decodeImage(MyPhotos.bytes(s, MyPhotos.ids(s).first)!)!.getPixel(0, 0).r, 20 * 7);
    // Shared as my photo too.
    expect(b.photo, s.myOwnPhoto);

    // 사진 지우기 on the 대표 사진: the newest earlier one takes its place, the
    // removed one is not kept.
    final next = MyPhotos.bytes(s, MyPhotos.ids(s).first);
    await t.runAsync(() => MyPhotos.dropMain(s));
    expect(s.myOwnPhoto, next);
    expect(MyPhotos.ids(s).length, MyPhotos.max - 1);

    // Off: nothing kept.
    Features.profile = false;
    final before = MyPhotos.ids(s).length;
    await t.runAsync(() => s.saveMyProfile(photo: photos.first));
    expect(MyPhotos.ids(s).length, before);
  });

  testWidgets('374 public photo: contacts get the real one, the server the public one; nobody = public for all', (t) async {
    final (b, s) = await app(t);
    final real = square(250, 120, 30), pub = square(30, 120, 250);
    await t.runAsync(() => s.saveMyProfile(photo: real));
    expect(b.photo, isNotNull, reason: "'everyone' by default");

    await s.setPref('who_photo', 'contacts');
    await t.runAsync(() => MyPhotos.setPublic(s, pub));
    expect(b.shared['photo'], 'contacts');
    expect(b.photo, MyPhotos.publicPhoto(s), reason: 'the public profile shows the 공개 사진');
    expect(MyPhotos.seenBy(s, contact: true).$1, real);
    expect(MyPhotos.seenBy(s, contact: true).$2, isFalse);
    expect(MyPhotos.seenBy(s, contact: false).$2, isTrue);

    await s.setPref('who_photo', 'nobody');
    await t.runAsync(s.publishProfile);
    expect(b.shared['photo'], 'everyone', reason: 'friends get the 공개 사진 too');
    expect(b.photo, MyPhotos.publicPhoto(s));
    expect(MyPhotos.seenBy(s, contact: true).$2, isTrue);

    await s.setPref('who_photo', 'everyone');
    await t.runAsync(s.publishProfile);
    expect(b.photo, real, reason: 'public photo unused when everyone sees the real one');

    await s.setPref('who_photo', 'contacts');
    await t.runAsync(() => MyPhotos.setPublic(s, null));
    expect(b.photo, isNull);
    expect(MyPhotos.seenBy(s, contact: false).$1, isNull);
  });

  test('373 photo card: only the encrypted file place + key', () {
    final file = {
      'url': 'mxc://burumy.app/x',
      'key': {
        'kty': 'oct',
        'key_ops': ['encrypt', 'decrypt'],
        'alg': 'A256CTR',
        'k': 'abc',
        'ext': true,
      },
      'iv': 'aXY=',
      'hashes': {'sha256': 'c2hh'},
      'v': 'v2',
    };
    final d = demoCheckCard('photo', {'file': file, 'mime': 'image/gif', 'name': 'x'}, DateTime(2026));
    expect(d['mime'], 'image/jpeg');
    expect(d.containsKey('name'), isFalse);
    expect(
      () => demoCheckCard('photo', {
        'file': {'url': 'https://x'},
      }, DateTime(2026)),
      throwsArgumentError,
    );
    expect(cardBody('photo', d), '🖼️');
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

    Future<void> shot(WidgetTester t, String name) => expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/p12_$name.png'));

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 6; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.pump(const Duration(milliseconds: 600));
    }

    late Uint8List sunset, hills;
    setUp(() {
      sunset = Uint8List.fromList(File('assets/demo/live_still.jpg').readAsBytesSync());
      hills = Uint8List.fromList(File('assets/demo/photo.png').readAsBytesSync());
    });

    NavigatorState navOf(WidgetTester t) => Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);

    testWidgets('195 their info: circle → big photo, bars, labels, tap through, scroll back', (t) async {
      final (b, s) = await app(t);
      final room = await b.createDirectChat('@mina:test');
      await b.sendText(room, '안녕');
      b.cards['@mina:test'] = ProfileCard(photo: sunset, bio: '사진 찍는 미나', private: true);
      await s.setPref('cphoto:@mina:test', base64Encode(hills));
      await s.refresh();
      s.cardOf('@mina:test', fresh: true);
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      unawaited(
        navOf(t).push(
          CupertinoPageRoute<void>(
            builder: (_) => ChatInfoPage(roomId: room, title: 'mina', isGroup: false, isChannel: false),
          ),
        ),
      );
      await settle(t);
      expect(find.byKey(const Key('info-name')), findsOneWidget);
      await shot(t, '1_info_small');

      // Tap the circle (no story): the photo fills the top.
      await t.tap(find.byKey(const Key('profile-avatar')));
      await settle(t);
      expect(find.byKey(const Key('profile-photo-bars')), findsOneWidget);
      expect(find.text('내가 정한 사진'), findsOneWidget);
      expect(find.byKey(const Key('info-name-photo')), findsOneWidget);
      expect(find.byKey(const Key('info-voice-call-photo')), findsOneWidget);
      await shot(t, '2_info_big');

      // Right half: their own photo.
      await t.tap(find.byKey(const Key('profile-photo-next')));
      await settle(t);
      expect(find.text('올린 사진'), findsOneWidget);
      await shot(t, '3_info_big_theirs');

      // Scroll up: back to the circle.
      await t.drag(find.byType(ListView).first, const Offset(0, -120));
      await settle(t);
      expect(find.byKey(const Key('profile-photo-bars')), findsNothing);
      expect(find.byKey(const Key('profile-avatar')), findsOneWidget);
    });

    testWidgets('445 my profile as others see it, 374 public photo label, 58 earlier photos viewer', (t) async {
      final (b, s) = await app(t);
      await t.runAsync(() => s.saveMyProfile(photo: hills, bio: '부루미 만드는 사람', birthday: '03-14'));
      await t.runAsync(() => s.saveMyProfile(photo: sunset));
      await s.setPref('who_photo', 'contacts');
      await s.setPref('who_birthday', 'contacts');
      await t.runAsync(() => MyPhotos.setPublic(s, square(0, 136, 255)));
      await b.setMyName('에릭');
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('설정').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('my-profile')));
      await settle(t);
      expect(find.byType(MyProfileViewPage), findsOneWidget);
      expect(find.byKey(const Key('my-profile-bio')), findsOneWidget);
      expect(find.byKey(const Key('my-profile-birthday')), findsOneWidget);
      await shot(t, '4_my_profile_contacts');

      // 모든 사람: the 공개 사진 with its label, the birthday hidden.
      await t.tap(find.text('모든 사람'));
      await settle(t);
      expect(find.text('공개 사진'), findsWidgets);
      expect(find.byKey(const Key('my-profile-birthday')), findsNothing);
      expect(find.textContaining('안 보이는 것: 프로필 사진, 생일'), findsOneWidget);
      await shot(t, '5_my_profile_everyone');

      // 예전 사진: 1/2, 대표 사진으로.
      await t.scrollUntilVisible(find.byKey(const Key('my-profile-photos')), 200, scrollable: find.byType(Scrollable).first);
      await t.tap(find.byKey(const Key('my-profile-photos')));
      await settle(t);
      expect(find.text('1/2'), findsOneWidget);
      expect(find.text('대표 사진'), findsOneWidget);
      await t.tap(find.byKey(const Key('photos-thumb-1')));
      await settle(t);
      expect(find.text('2/2'), findsOneWidget);
      await shot(t, '6_old_photos');
      await t.tap(find.byKey(const Key('photos-menu')));
      await settle(t);
      await t.tap(find.byKey(const Key('photos-main')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(t);
      expect(find.text('이제 대표 사진이에요'), findsOneWidget);
      expect(s.myOwnPhoto, hills);
      expect(find.text('1/2'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('376 emoji photo: ground, size, a Burumy character, done gives a 1024 px PNG', (t) async {
      final (_, s) = await app(t);
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      Uint8List? out;
      final ctx = t.element(find.byType(CupertinoPageScaffold).first);
      unawaited(makeEmojiPhoto(ctx).then((v) => out = v));
      await settle(t);
      await t.tap(find.byKey(const Key('emoji-ground-3')));
      await t.tap(find.text('부루미'));
      await settle(t);
      await t.tap(find.byType(Image).at(1));
      await settle(t);
      await shot(t, '7_emoji_photo');
      await t.tap(find.byKey(const Key('emoji-photo-done')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await settle(t);
      expect(out, isNotNull);
      final im = img.decodePng(out!)!;
      expect((im.width, im.height), (1024, 1024));
      expect(emojiPhotoCharacters.every((a) => a.startsWith('assets/stickers/')), isTrue);
    });

    testWidgets('373 suggest a photo: card in the chat, 사진 보기, 내 사진으로', (t) async {
      final (b, s) = await app(t);
      final room = await b.createDirectChat('@mina:test');
      await b.sendText(room, '엄마 사진 하나 골라 봤어');
      final file = jsonDecode(await b.uploadEncrypted(sunset));
      b.rooms[room]!.add(
        Msg(
          id: 'ps',
          sender: '@mina:test',
          body: '🖼️',
          time: DateTime.now(),
          mine: false,
          kind: 'card',
          card: CardInfo(kind: 'photo', data: {'file': file, 'mime': 'image/jpeg'}),
        ),
      );
      await s.refresh();
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      await t.tap(find.text('대화').last);
      await t.pumpAndSettle();
      expect(find.text('🖼️ 사진 제안'), findsOneWidget, reason: 'chat list preview');
      await t.tap(find.text('🖼️ 사진 제안'));
      await settle(t);
      expect(find.byKey(const Key('photo-suggest-ps')), findsOneWidget);
      expect(find.textContaining('님이 프로필 사진을 제안했어요'), findsOneWidget);
      await shot(t, '8_suggest_card');
      await t.tap(find.byKey(const Key('photo-suggest-view-ps')));
      await settle(t);
      await shot(t, '9_suggest_view');
      await t.tap(find.byKey(const Key('photo-use')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await settle(t);
      expect(s.myOwnPhoto, sunset);
      expect(find.text('이제 대표 사진이에요'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('header widget alone: pull down opens, no photos = stays a circle', (t) async {
      final (_, s) = await app(t);
      await t.pumpWidget(BurumyApp(state: s));
      await t.pumpAndSettle();
      final key = GlobalKey<ProfileTopState>();
      unawaited(
        navOf(t).push(
          CupertinoPageRoute<void>(
            builder: (_) => CupertinoPageScaffold(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  ProfileTop(
                    key: key,
                    photos: [HeaderPhoto(hills)],
                    avatar: const SizedBox(width: 100, height: 100),
                    avatarSize: 100,
                    name: (_) => const Text('이름'),
                    sub: (_) => const Text('@id'),
                    actions: null,
                  ),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        ),
      );
      await settle(t);
      expect(key.currentState!.open, isFalse);
      final g = await t.startGesture(t.getCenter(find.byType(ListView)));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(0, 30));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await settle(t);
      expect(key.currentState!.open, isTrue);
    });
  });
}
