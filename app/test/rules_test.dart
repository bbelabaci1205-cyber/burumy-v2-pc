// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Rulebook checks that run with every test: both languages complete, no
// screen text written in code, no bold, no dark green.
import 'dart:convert';
import 'dart:io';

import 'package:burumy/design/tokens.dart';
import 'package:flutter/widgets.dart';
import 'package:burumy/core/features.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> arb(String lang) =>
    (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>)..removeWhere((k, _) => k.startsWith('@'));

void main() {
  test('cloud AI stays on the phone unless switched on, chosen per chat, and not blocked by the owner', () {
    expect(Features.cloudAi, isFalse);
    expect(aiPlaceFor(chatAllowsCloud: true), AiPlace.onDevice);
    expect(aiPlaceFor(chatAllowsCloud: true, ownerBlocksCloud: true), AiPlace.onDevice);
    expect(Features.business, isFalse);
  });

  test('Korean and English have exactly the same texts', () {
    final ko = arb('ko').keys.toSet(), en = arb('en').keys.toSet();
    expect(ko.difference(en), isEmpty, reason: 'missing in English');
    expect(en.difference(ko), isEmpty, reason: 'missing in Korean');
    for (final e in arb('en').entries) {
      expect((e.value as String).trim(), isNotEmpty, reason: 'empty English text ${e.key}');
    }
  });

  test('Korean texts use 해요체, not 합니다체', () {
    for (final e in arb('ko').entries) {
      expect(e.value as String, isNot(matches(RegExp(r'(습니다|십시오|입니다)'))), reason: e.key);
      expect(e.value as String, isNot(contains('유저')), reason: '${e.key}: 사용자');
    }
  });

  test('no screen text written directly in code', () {
    final hangul = RegExp(r'[가-힣]');
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final path = f.path.replaceAll('\\', '/');
      if (!path.endsWith('.dart') ||
          path.contains('/l10n/') ||
          path.contains('/src/rust/') ||
          path.endsWith('brand/brand.dart') ||
          path.endsWith('demo/sample.dart'))
        continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        expect(hangul.hasMatch(code), isFalse, reason: '$path:${i + 1} has Korean text in code');
      }
    }
  });

  test('type scale never uses bold (700+)', () {
    for (final t in Tokens.all) {
      expect(t.weight.value, lessThan(700));
    }
  });

  test('brand accents are bright (no dark green) in every family and mode', () {
    for (final p in Palette.all) {
      expect(p.accent.computeLuminance(), greaterThan(0.18), reason: '${p.family} ${p.brightness}');
    }
  });

  test('every palette pairs light text on dark and dark text on light', () {
    for (final p in Palette.all) {
      final bg = p.background.computeLuminance(), fg = p.label.computeLuminance();
      final contrast = (fg > bg ? (fg + 0.05) / (bg + 0.05) : (bg + 0.05) / (fg + 0.05));
      expect(contrast, greaterThan(7), reason: '${p.family} ${p.brightness}');
      expect(p.brightness == Brightness.dark, p.dark);
    }
  });
}
