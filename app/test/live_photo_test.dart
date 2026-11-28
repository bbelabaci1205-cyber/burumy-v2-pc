// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 움직이는 사진 (TelegramTips 563): Motion Photo split, place details removed
// from both parts, the LIVE style menu before sending, and the LIVE mark in
// the chat.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/live_photo.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/core/strip_meta.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

List<int> box(String type, List<int> body) {
  final n = body.length + 8;
  return [(n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255, ...latin1.encode(type), ...body];
}

/// A tiny MP4: ftyp, moov (mvhd 3 s, udta with a place, trak with its own
/// udta, meta with a phone name), mdat.
Uint8List mp4() {
  final mvhd = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x03, 0xE8, 0, 0, 0x0B, 0xB8, ...List.filled(80, 0)];
  return Uint8List.fromList([
    ...box('ftyp', ascii.encode('isom\x00\x00\x02\x00isomiso2mp41')),
    ...box('moov', [
      ...box('mvhd', mvhd),
      ...box('udta', box('\xA9xyz', ascii.encode('+37.5665+126.9780/'))),
      ...box('trak', [...box('tkhd', List.filled(20, 1)), ...box('udta', ascii.encode('Galaxy S27'))]),
      ...box('meta', ascii.encode('com.apple.quicktime.location.ISO6709 +37.5+126.9')),
    ]),
    ...box('mdat', List.filled(64, 7)),
  ]);
}

/// A JPEG with an Exif place, an XMP note and (optionally) a clip at its end.
Uint8List jpeg({String? xmp, List<int> tail = const []}) {
  List<int> seg(int m, List<int> body) => [0xFF, m, ((body.length + 2) >> 8) & 255, (body.length + 2) & 255, ...body];
  return Uint8List.fromList([
    0xFF, 0xD8, //
    ...seg(0xE0, ascii.encode('JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00')),
    ...seg(0xE1, ascii.encode('Exif\x00\x00GPS 37.5665 126.9780')),
    if (xmp != null) ...seg(0xE1, latin1.encode('http://ns.adobe.com/xap/1.0/\x00$xmp')),
    ...seg(0xDA, [1, 1, 0, 0, 63, 0]),
    1, 2, 3, 0xFF, 0x00, 4, 5, //
    0xFF, 0xD9,
    ...tail,
  ]);
}

void main() {
  final clip = mp4();

  test('Motion Photo 1.0: the clip is split off by its XMP length', () {
    final xmp =
        '<x:xmpmeta><Container:Directory><rdf:Seq>'
        '<rdf:li><Container:Item Item:Mime="image/jpeg" Item:Semantic="Primary" Item:Length="0"/></rdf:li>'
        '<rdf:li><Container:Item Item:Mime="video/mp4" Item:Semantic="MotionPhoto" Item:Length="${clip.length}"/></rdf:li>'
        '</rdf:Seq></Container:Directory></x:xmpmeta>';
    final whole = jpeg(xmp: xmp, tail: clip);
    final parts = LivePhoto.splitMotion(whole)!;
    expect(parts.clip, clip);
    expect(parts.still.length, whole.length - clip.length);
    expect(parts.still.sublist(parts.still.length - 2), [0xFF, 0xD9]);
  });

  test('older Pixel MicroVideoOffset and no note at all still split', () {
    final old = jpeg(xmp: '<rdf:Description GCamera:MicroVideo="1" GCamera:MicroVideoOffset="${clip.length}"/>', tail: clip);
    expect(LivePhoto.splitMotion(old)!.clip, clip);
    final bare = jpeg(tail: clip);
    expect(LivePhoto.splitMotion(bare)!.clip, clip);
    // A plain photo is not a Motion Photo.
    expect(LivePhoto.splitMotion(jpeg()), isNull);
    expect(LivePhoto.splitMotion(jpeg(tail: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])), isNull);
  });

  test('a Motion Photo sent as a normal photo leaves its clip behind', () {
    final out = StripMeta.photo(jpeg(tail: clip), 'image/jpeg');
    final s = latin1.decode(out);
    expect(s.contains('GPS'), isFalse);
    expect(s.contains('ftyp'), isFalse);
    expect(out.sublist(out.length - 2), [0xFF, 0xD9]);
  });

  test('clip: place, phone and owner boxes are blanked, length kept', () {
    expect(Mp4Meta.clean(clip), isFalse);
    final out = Mp4Meta.strip(clip);
    final s = latin1.decode(out);
    expect(out.length, clip.length);
    expect(s.contains('37.5'), isFalse);
    expect(s.contains('Galaxy'), isFalse);
    expect(s.contains('udta'), isFalse);
    expect(Mp4Meta.clean(out), isTrue);
    expect(Mp4Meta.duration(out), const Duration(seconds: 3));
    // Picture data untouched.
    expect(out.sublist(out.length - 64), List.filled(64, 7));
  });

  test('play styles', () {
    expect(LiveStyle.parse('loop'), LiveStyle.loop);
    expect(LiveStyle.parse('bounce'), LiveStyle.bounce);
    expect(LiveStyle.parse('anything'), LiveStyle.live);
  });

  testWidgets('choose 바운스 before sending; the chat shows LIVE (ko)', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final bob = await fake.createDirectChat('@bob:test');
    await state.refresh();
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    Phone.debugRecent = (_) async => [PhoneMedia('p1', png, live: true), PhoneMedia('p2', png)];
    Phone.debugLoadFile = (id) async => id == 'p1' ? PhoneFile('IMG_0001.jpg', png, clip: clip) : PhoneFile('IMG_0002.jpg', png);
    addTearDown(() {
      Phone.debugRecent = null;
      Phone.debugLoadFile = null;
    });
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('bob').first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    // Not chosen yet: only the Live mark; chosen: the LIVE ⌄ capsule.
    expect(find.byKey(const Key('attach-live-style-0')), findsNothing);
    await t.tap(find.byKey(const Key('attach-live-p1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('attach-live-style-0')), findsOneWidget);
    expect(find.text('LIVE'), findsWidgets);
    await t.tap(find.byKey(const Key('attach-live-style-0')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('live-menu')), findsOneWidget);
    for (final w in ['라이브', '반복', '바운스', '라이브 끄기']) {
      expect(find.text(w), findsOneWidget);
    }
    await t.tap(find.byKey(const Key('live-style-bounce')));
    await t.pump();
    expect(find.text('바운스로 바꿨어요'), findsOneWidget);
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byKey(const Key('live-menu')), findsNothing);
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    final sent = fake.rooms[bob]!.last;
    expect(sent.kind, 'image');
    expect(sent.live?.style, 'bounce');
    expect(sent.live?.duration, const Duration(seconds: 3));
    expect(await fake.liveVideo(bob, sent.id), clip);
    expect(find.byKey(Key('live-${sent.id}')), findsOneWidget);
    expect(find.byKey(const Key('live-badge')), findsOneWidget);

    // 라이브 끄기: sent as a plain photo, the clip stays on the phone.
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-live-p1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-live-style-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('live-style-off')));
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('LIVE 끔'), findsOneWidget);
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.last.live, isNull);
    expect(fake.rooms[bob]!.last.kind, 'image');

    // View once: the photo stays still.
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-live-p1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-once')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-send')));
    await t.pumpAndSettle();
    expect(fake.rooms[bob]!.last.viewOnce, isTrue);
    expect(fake.rooms[bob]!.last.live, isNull);
    state.stopLive();
  });
}
