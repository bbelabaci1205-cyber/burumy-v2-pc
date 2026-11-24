// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Size, type, spacing and colour rules from the v2 rulebook ch. 3-4
// (owner's choice "A": Telegram-size type, iOS-first look). Screens use these
// names only, never raw numbers.
import 'package:flutter/widgets.dart';

import '../brand/brand.dart';

class TypeStyle {
  const TypeStyle(this.size, this.lineHeight, this.weight);
  final double size;
  final double lineHeight;
  final FontWeight weight;

  TextStyle get style =>
      TextStyle(fontFamily: Tokens.font, fontFamilyFallback: Tokens.emojiFallback, fontSize: size, height: lineHeight / size, fontWeight: weight);
}

class Tokens {
  const Tokens._();

  static const font = 'Pretendard';

  /// The phone's own colour emoji (iOS, Android).
  static const emojiFallback = ['Apple Color Emoji', 'Noto Color Emoji'];

  // Type scale. Weight 700 (bold) is never used.
  static const largeTitle = TypeStyle(34, 41, FontWeight.w600);
  static const screenTitle = TypeStyle(28, 34, FontWeight.w600);
  static const cardTitle = TypeStyle(22, 28, FontWeight.w500);
  static const body = TypeStyle(17, 22, FontWeight.w400);
  static const preview = TypeStyle(15, 20, FontWeight.w400);
  static const caption = TypeStyle(13, 18, FontWeight.w400);
  static const bubbleMeta = TypeStyle(11, 13, FontWeight.w400);
  static const tabLabel = TypeStyle(10, 12, FontWeight.w500);
  static const all = [largeTitle, screenTitle, cardTitle, body, preview, caption, bubbleMeta, tabLabel];

  // Spacing and corners.
  static const space = [4.0, 8.0, 12.0, 16.0, 24.0, 32.0];
  static const radius = [6.0, 10.0, 16.0, 26.0];
  static const capsule = 999.0;

  // Gaps between texts.
  static const nameToSub = 2.0, groupTitleToCard = 6.0, cardToFooter = 8.0;

  // Bars and sheets.
  static const tabBar = 62.0, tabIcon = 26.0;
  static const sheetHeader = 56.0, closeButton = 44.0, closeIcon = 22.0;
  static const topBar = 44.0, listIcon = 22.0, listIconSmall = 18.0, settingsRow = 52.0;
  static const loadingMark = 168.0;

  // Chat info header (Telegram 1:1 info, measured 2026-11-24): 100 photo,
  // 28 name, 57-tall action tiles.
  static const infoAvatar = 100.0, infoTile = 57.0, memberAvatar = 40.0, memberRow = 60.0;

  // Chat list row (Telegram iOS, measured 2026-11-24 on Eric's iPhone):
  // 76 pitch, 60 photo, 16 left, text 12 after the photo.
  static const chatRow = 76.0, chatAvatar = 60.0;
}

/// Neutral backgrounds + one brand accent (rulebook ch. 4).
class Palette {
  const Palette._(this.family, this.brightness);
  final BrandFamily family;
  final Brightness brightness;

  static const all = [
    Palette._(BrandFamily.green, Brightness.light),
    Palette._(BrandFamily.green, Brightness.dark),
    Palette._(BrandFamily.blue, Brightness.light),
    Palette._(BrandFamily.blue, Brightness.dark),
  ];

  factory Palette.of(BrandFamily f, Brightness b) => all.firstWhere((p) => p.family == f && p.brightness == b);

  bool get dark => brightness == Brightness.dark;
  Color get accent => Brand.accent(family, brightness);
  Color get onAccent => const Color(0xFFFFFFFF);
  Color get background => dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  Color get card => dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);

  /// Plain lists (chat list): white in light mode, black in dark (iOS).
  /// Chat room background: plain white / black like iPhone Messages.
  Color get chatBackground => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  /// Others' message bubbles on that background (iPhone Messages grey).
  Color get incoming => dark ? const Color(0xFF262629) : const Color(0xFFE9E9EB);
  Color get list => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color get label => dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get secondaryLabel => dark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);
  Color get separator => dark ? const Color(0xFF38383A) : const Color(0xFFE6E6E8);

  /// iOS system colours for icon tiles (chosen by meaning, rulebook ch. 4).
  static const tileRed = Color(0xFFFF3B30),
      tileOrange = Color(0xFFFF9500),
      tileYellow = Color(0xFFFFCC00),
      tileBlue = Color(0xFF007AFF),
      tileIndigo = Color(0xFF5856D6),
      tilePurple = Color(0xFFAF52DE),
      tilePink = Color(0xFFFF2D55),
      tileTeal = Color(0xFF30B0C7),
      tileGrey = Color(0xFF8E8E93),
      tileCyan = Color(0xFF32ADE6);
  // Eric 2026-11-24: brand-colour tiles follow the theme (blue theme = blue,
  // green theme = base green).
  Color get tileGreen => Brand.accent(family, brightness);

  /// "Black" tile (devices): lifted to dark grey on dark cards so it still reads.
  Color get tileBlack => dark ? const Color(0xFF48484A) : const Color(0xFF1C1C1E);
}
