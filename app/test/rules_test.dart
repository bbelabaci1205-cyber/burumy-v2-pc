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
          path.endsWith('demo/sample.dart') ||
          path.endsWith('demo/more_sample.dart') ||
          path.endsWith('demo/live_sample.dart') ||
          path.endsWith('demo/video_sample.dart') ||
          path.endsWith('demo/photo_sample.dart') ||
          path.endsWith('demo/fun_sample.dart') ||
          path.endsWith('demo/rival_sample.dart') ||
          path.endsWith('demo/translate_sample.dart') ||
          path.endsWith('demo/share_sample.dart') ||
          // Date words the plan finder looks for, not screen text.
          path.endsWith('core/plan_pick.dart') ||
          // Sticker search words (what people type), not screen text.
          path.endsWith('stickers/sticker_words.dart') ||
          // Emoji search words (what people type), not screen text.
          path.endsWith('core/emoji_words.dart') ||
          // Look-alike rules (Korean letters, '공식' words) and demo names.
          path.endsWith('core/trust.dart') ||
          path.endsWith('demo/trust_sample.dart') ||
          path.endsWith('demo/guard_sample.dart') ||
          path.endsWith('demo/gate_sample.dart') ||
          path.endsWith('demo/tips_d1_sample.dart') ||
          path.endsWith('demo/reply_sample.dart') ||
          // Demo samples: made-up chats shown only in the web preview.
          (path.contains('/demo/') && path.endsWith('_sample.dart')) ||
          // 인증 코드 찾기: the Korean words that mark a code message.
          path.endsWith('core/codes.dart') ||
          // 강력 스팸 차단: the Korean spam words the filter looks for.
          path.endsWith('core/group_tools.dart') ||
          // 날짜로 찾기: the Korean month word ("3월") typed in search.
          path.endsWith('core/search.dart') ||
          // Story weather: the city table keeps each city's Korean and English name.
          path.endsWith('core/story_weather.dart') ||
          // Message effects (tip 451): each effect's Korean name and the
          // words that find it in the picker, beside the English ones.
          path.endsWith('core/effects.dart') ||
          // AI 편집기: words a style may not ask for, and the demo's fixed answers.
          path.endsWith('core/ai_styles.dart') ||
          path.endsWith('demo/demo_ai.dart') ||
          path.endsWith('demo/community_sample.dart') ||
          // 대화 가져오기: the words other apps write into their export files,
          // and the demo's sample export.
          path.endsWith('core/chat_import.dart') ||
          path.endsWith('demo/import_sample.dart'))
        continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        expect(hangul.hasMatch(code), isFalse, reason: '$path:${i + 1} has Korean text in code');
      }
    }
  });

  test('type scale never uses bold (700+) except the settings header title', () {
    // Eric 2026-11-25: 700 only where iOS 27 uses it (settings header card).
    for (final t in Tokens.all.where((t) => t != Tokens.headerTitle)) {
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
