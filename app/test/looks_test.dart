// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 테마·배경·꾸미기 (tip batches #21 + #24): the background text, theme
// links, name / profile looks, room looks, accents and the both-phones note.
import 'dart:convert';
import 'dart:ui';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/looks.dart';
import 'package:burumy/core/room_theme.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/design/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Wall (background text)', () {
    test('our theme ids stay plain words (old settings still read)', () {
      expect(Wall.parse('secure').kind, 'theme');
      expect(Wall.parse('secure').id, 'secure');
      expect(Wall.parse('secure').encode(), 'secure');
      expect(Wall.parse('plain').isPlain, isTrue);
      expect(Wall.parse('').isPlain, isTrue);
    });

    test('colour, swirl, icons, strength, blur and motion round-trip', () {
      const c = Wall(kind: 'color', colors: [Color(0xFFFADCE2)], pattern: 'hearts', strength: 0.4, motion: true);
      expect(c.encode(), 'color:FADCE2~p=hearts~s=40~m=1');
      final back = Wall.parse(c.encode());
      expect(back.kind, 'color');
      expect(back.colors.single, const Color(0xFFFADCE2));
      expect(back.pattern, 'hearts');
      expect(back.strength, closeTo(0.4, 0.001));
      expect(back.motion, isTrue);

      final g = Wall.parse(Wall.gradSpec('mint', pattern: 'nature'));
      expect(g.kind, 'grad');
      expect(g.colors, hasLength(4));
      expect(g.pattern, 'nature');
      expect(Wall.parse(g.encode()).encode(), g.encode());

      final ph = Wall.parse('photo~b=1~m=1');
      expect(ph.kind, 'photo');
      expect(ph.blur, isTrue);
      expect(ph.motion, isTrue);
      expect(ph.encode(), 'photo~b=1~m=1');
    });

    test('unknown icons and bad colours are dropped, never crash', () {
      expect(Wall.parse('color:ZZZZZZ~p=evil').pattern, '');
      expect(Wall.parse('color:ZZZZZZ').colors.single, const Color(0xFFFFFFFF));
      expect(Wall.parse('grad:FFFFFF').isPlain, isTrue);
      expect(Wall.parse('color:FFFFFF~s=900').strength, 1.0);
    });

    test('a photo never goes to another phone; long texts are refused', () {
      expect(Wall.sendable('photo'), isFalse);
      expect(Wall.sendable('photo~b=1'), isFalse);
      expect(Wall.sendable(Wall.gradSpec('sky')), isTrue);
      expect(Wall.sendable('x' * 200), isFalse);
    });

    test('ready-made swirl sets are bright except the night one', () {
      for (final g in Wall.gradients.where((g) => g.$1 != 'night')) {
        for (final c in g.$2) {
          expect(c.computeLuminance(), greaterThan(0.45), reason: g.$1);
        }
      }
    });
  });

  group('MyTheme (made themes + links)', () {
    test('link carries the theme after # and reads back', () {
      final t = MyTheme(
        id: 'a',
        name: '라벤더 밤',
        accent: const Color(0xFFB14BE0),
        wall: Wall.gradSpec('lilac', pattern: 'stars'),
      );
      final link = t.link();
      expect(link, startsWith('https://${Brand.linkHost}/theme#t='));
      final back = MyTheme.parseLink('이거 써 봐 $link')!;
      expect(back.name, '라벤더 밤');
      expect(back.accent, const Color(0xFFB14BE0));
      expect(back.wall, t.wall);
      expect(MyTheme.withoutLink('이거 써 봐 $link'), '이거 써 봐');
    });

    test('a link with a photo, a missing name or junk is refused', () {
      String link(Map<String, Object?> j) => 'https://${Brand.linkHost}/theme#t=${base64Url.encode(utf8.encode(jsonEncode(j))).replaceAll('=', '')}';
      expect(MyTheme.parseLink(link({'n': 'x', 'a': 'FF2D55', 'w': 'photo'})), isNull);
      expect(MyTheme.parseLink(link({'n': '', 'a': 'FF2D55', 'w': 'plain'})), isNull);
      expect(MyTheme.parseLink(link({'n': 'x', 'a': 'nope', 'w': 'plain'})), isNull);
      expect(MyTheme.parseLink('https://${Brand.linkHost}/theme#t=!!!'), isNull);
    });

    test('a dark accent is lifted so it stays bright (no dark green)', () {
      final t = MyTheme.fromJson({'n': 'x', 'a': '0B3D1E', 'w': 'plain'})!;
      expect(t.accent.computeLuminance(), greaterThan(0.18));
    });

    test('list keeps order and survives bad JSON', () {
      final a = MyTheme(id: '1', name: 'A', accent: const Color(0xFFFF2D55), wall: 'plain');
      final b = MyTheme(id: '2', name: 'B', accent: const Color(0xFF0088FF), wall: Wall.gradSpec('sky'));
      expect(MyTheme.listFrom(MyTheme.listTo([a, b])).map((x) => x.name), ['A', 'B']);
      expect(MyTheme.listFrom('not json'), isEmpty);
    });
  });

  group('PersonLook (name + profile look)', () {
    test('old one-word name colour still reads', () {
      expect(PersonLook.parse('red').name, ['red']);
      expect(PersonLook.parse('red').encode(), 'red');
    });

    test('stripes, reply icons, cover and cover icons round-trip', () {
      final l = PersonLook.parse('orange+yellow|stars|purple+pink|hearts');
      expect(l.name, ['orange', 'yellow']);
      expect(l.reply, 'stars');
      expect(l.cover, ['purple', 'pink']);
      expect(l.coverIcons, 'hearts');
      expect(l.encode(), 'orange+yellow|stars|purple+pink|hearts');
      expect(const PersonLook(reply: 'music').encode(), '|music');
      expect(const PersonLook().encode(), '');
    });

    test('unknown colours / icons are dropped; long texts ignored', () {
      final l = PersonLook.parse('black+red|bombs|x|y');
      expect(l.name, ['red']);
      expect(l.reply, '');
      expect(l.cover, isEmpty);
      expect(PersonLook.parse('red|${'x' * 100}').isEmpty, isTrue);
    });
  });

  group('RoomLook (group / channel look)', () {
    test('reads from the room setting, drops photos and junk', () {
      final r = RoomLook.from({
        'look': {'c': 'green+teal', 'l': 'nature', 'e': '📚', 'w': Wall.gradSpec('mint'), 'n': 'blue'},
      });
      expect(r.cover, ['green', 'teal']);
      expect(r.logo, 'nature');
      expect(r.emoji, '📚');
      expect(r.wall, Wall.gradSpec('mint'));
      expect(r.name, 'blue');
      expect(RoomLook.from({'look': r.toJson()}).toJson(), r.toJson());
      expect(
        RoomLook.from({
          'look': {'w': 'photo', 'l': 'evil', 'c': 'black'},
        }).isEmpty,
        isTrue,
      );
      expect(const RoomLook().toJson(), isNull);
    });
  });

  group('accent colours (tip 229)', () {
    test('every pick is bright in light and dark', () {
      for (final f in Brand.picks) {
        for (final b in Brightness.values) {
          expect(Brand.accent(f, b).computeLuminance(), greaterThan(0.18), reason: '$f $b');
        }
      }
    });

    test('a non-green accent has no green tiles or story ring', () {
      for (final f in BrandFamily.values.where((f) => f != BrandFamily.green)) {
        final p = Palette.of(f, Brightness.light);
        expect(p.tileGreen, p.accent, reason: '$f');
      }
    });

    test('the made theme colour is used for custom', () {
      Brand.custom = const Color(0xFFFF2D55);
      expect(Palette.of(BrandFamily.custom, Brightness.light).accent, const Color(0xFFFF2D55));
      Brand.custom = const Color(0xFF03C46B);
    });
  });

  group('both phones (tips 387 + 410)', () {
    late FakeBackend b;
    late AppState s;
    setUp(() async {
      b = FakeBackend();
      s = AppState(b);
      await b.login(id: 'me', password: 'x');
      await s.refresh();
    });

    test('a colour mix goes to the other phone, with a card on mine', () async {
      final spec = Wall.gradSpec('peach', pattern: 'hearts');
      await RoomTheme.set(s, '!r0', spec, both: true);
      expect(b.sentSignals.last.$2, RoomTheme.kind);
      expect(b.sentSignals.last.$3['t'], spec);
      final note = jsonDecode(s.pref(RoomTheme.notePref('!r0'), '')) as Map;
      expect(note['by'], '');
      expect(note['t'], spec);
    });

    test('my photo never leaves; no card for it', () async {
      final before = b.sentSignals.length;
      await RoomTheme.set(s, '!r0', 'photo~b=1', both: true);
      expect(b.sentSignals.length, before);
      expect(s.pref(RoomTheme.notePref('!r0'), ''), '');
    });

    test('theirs: applied, card remembers what I had so I can go back', () async {
      await RoomTheme.set(s, '!r0', 'nature', both: false);
      final spec = Wall.gradSpec('sky');
      final at = DateTime.now().millisecondsSinceEpoch + 1000;
      await RoomTheme.onSignal(
        s,
        Signal(roomId: '!r0', id: 'x', sender: '@mina:test', kind: RoomTheme.kind, data: {'t': spec, 'at': at}, time: DateTime.now()),
      );
      expect(s.pref(RoomTheme.pref('!r0'), ''), spec);
      final note = jsonDecode(s.pref(RoomTheme.notePref('!r0'), '')) as Map;
      expect(note['by'], '@mina:test');
      expect(note['prev'], 'nature');
    });

    test('my look goes to 1:1 chats as an encrypted note, once per change', () async {
      b.names['!d'] = '민아';
      b.peers['!d'] = '@mina:test';
      b.rooms['!d'] = [Msg(id: 'd1', sender: '@mina:test', body: 'hi', time: DateTime.now(), mine: false, kind: 'text')];
      await s.refresh();
      await s.setPref('name_color', 'orange+yellow|stars');
      await s.applyNameColor();
      final sent = b.sentSignals.where((x) => x.$2 == PersonLook.signalKind).toList();
      expect(sent, isNotEmpty);
      expect(sent.every((x) => x.$3['v'] == 'orange+yellow|stars'), isTrue);
      final n = sent.length;
      await s.applyNameColor();
      expect(b.sentSignals.where((x) => x.$2 == PersonLook.signalKind).length, n);
    });

    test('a look note from a 1:1 chat is kept for their profile', () async {
      b.incomingSignals.add(
        Signal(roomId: '!r0', id: 'y', sender: '@mina:test', kind: PersonLook.signalKind, data: {'v': 'pink|hearts|pink|hearts'}, time: DateTime.now()),
      );
      await s.handleSignals();
      expect(s.pref(PersonLook.prefOf('@mina:test'), ''), 'pink|hearts|pink|hearts');
    });
  });
}
