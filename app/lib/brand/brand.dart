// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The ONE place for the app name, logo and brand colours (rulebook ch. 0:
// the logo and company name may change). Nothing else in the app may spell
// the name or a brand colour directly.
import 'dart:ui';

/// Which brand colour family the app is built in. Both are kept side by
/// side until the owner picks one (or keeps both as themes).
///
/// 강조색 고르기 (Telegram tip 229, 2026-11-27): besides our green (the
/// default) and blue, a few more iOS system colours can be picked in
/// Settings > 모양, and [custom] is the colour of a theme the person made
/// (tip 173). Whatever is picked, it is the only accent on screen: no green
/// shows in another colour (chat backgrounds excepted).
enum BrandFamily { green, blue, teal, indigo, purple, pink, orange, custom }

class Brand {
  const Brand._();

  /// Shown names. Change here only.
  static const nameKo = '부루미';
  static const nameEn = 'Burumy';

  /// Where invite links and channel web pages live (the domain is picked
  /// before launch; set at build time with BURUMY_LINKS=host).
  static const linkHost = String.fromEnvironment('BURUMY_LINKS', defaultValue: 'burumy.app');

  /// Official support account (버그·제안 보내기 goes here; the name is
  /// reserved so nobody else can take it).
  static const supportLocalpart = 'burumy_support';

  /// Logo assets (filled in when the new logo files arrive).
  static const logoMark = 'assets/brand/mark.svg';

  /// Brand accent per family and brightness. Bright colours only: dark green
  /// is not allowed anywhere (rulebook ch. 4).
  static Color accent(BrandFamily f, Brightness b) => switch ((f, b)) {
    // Our own green (Eric 2026-11-26): moved a little toward mint so it is
    // not the same number as another messenger's brand green (#06C755).
    (BrandFamily.green, _) => const Color(0xFF03C46B),
    // iOS 26/27 system blue (sRGB), same as the blue tiles.
    (BrandFamily.blue, Brightness.light) => const Color(0xFF0088FF),
    (BrandFamily.blue, Brightness.dark) => const Color(0xFF0091FF),
    // iOS 26/27 system colours (sRGB), the same as the icon tiles. Teal is
    // the iOS cyan step so white words on it stay readable.
    (BrandFamily.teal, _) => const Color(0xFF00B4CC),
    (BrandFamily.indigo, _) => const Color(0xFF786EF7),
    (BrandFamily.purple, _) => const Color(0xFFB14BE0),
    (BrandFamily.pink, _) => const Color(0xFFFF2D55),
    (BrandFamily.orange, _) => const Color(0xFFFF8D28),
    (BrandFamily.custom, _) => custom,
  };

  /// The accent of the theme the person made (Settings > 모양 > 테마 만들기);
  /// set by the app before each frame from the saved setting.
  static Color custom = const Color(0xFF03C46B);

  /// The colours offered as dots, in order (green first: our default).
  static const picks = [BrandFamily.green, BrandFamily.teal, BrandFamily.blue, BrandFamily.indigo, BrandFamily.purple, BrandFamily.pink, BrandFamily.orange];
}
