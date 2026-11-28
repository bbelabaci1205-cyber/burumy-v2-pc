// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이름 색 (v1): the colour of my name above my messages in groups, one of 8
// iOS colours. Kept on my member event in each group, so everyone sees it.
//
// 계정 색 (Telegram tip 402, 2026-11-27): the same text may now also carry a
// second stripe colour, icons for my reply quotes and my profile cover
// colour + icons (core/looks.dart PersonLook). The old one-word value
// (`red`) still reads.
import 'package:flutter/widgets.dart';

import '../core/looks.dart';
import '../design/tokens.dart';
import 'common.dart';

class NameColors {
  /// The 8 colours, in picker order.
  static const keys = PersonLook.keys;

  static Color? colorOf(String key) {
    final k = key.contains('|') || key.contains('+') ? (PersonLook.parse(key).name.firstOrNull ?? '') : key;
    return switch (k) {
      'red' => Palette.tileRed,
      'orange' => Palette.tileOrange,
      'yellow' => const Color(0xFFE5A800), // iOS yellow reads poorly as text; its darker step.
      'green' => const Color(0xFF34C759),
      'teal' => Palette.tileTeal,
      'blue' => Palette.tileBlue,
      'purple' => Palette.tilePurple,
      'pink' => Palette.tilePink,
      _ => null,
    };
  }

  /// Colours people picked (their whole look text), by user ID (filled
  /// when a group opens, and from 1:1 notes).
  static final picked = <String, String>{};

  /// The look [userId] chose, as far as this phone knows.
  static PersonLook lookOf(String userId) => PersonLook.parse(picked[userId] ?? '');

  /// The name colour for [userId]: their pick, else one made from [name].
  static Color colorFor(String userId, String name) => colorOf(picked[userId] ?? '') ?? Avatar.colorFor(name);

  /// Their second stripe colour (two-colour names), or null.
  static Color? stripeFor(String userId) {
    final n = lookOf(userId).name;
    return n.length > 1 ? colorOf(n[1]) : null;
  }
}
