// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The ONE place for the app name, logo and brand colours (rulebook ch. 0:
// the logo and company name may change). Nothing else in the app may spell
// the name or a brand colour directly.
import 'dart:ui';

/// Which brand colour family the app is built in. Both are kept side by
/// side until the owner picks one (or keeps both as themes).
enum BrandFamily { green, blue }

class Brand {
  const Brand._();

  /// Shown names. Change here only.
  static const nameKo = '부루미';
  static const nameEn = 'Burumy';

  /// Logo assets (filled in when the new logo files arrive).
  static const logoMark = 'assets/brand/mark.svg';

  /// Brand accent per family and brightness. Bright colours only: dark green
  /// is not allowed anywhere (rulebook ch. 4).
  static Color accent(BrandFamily f, Brightness b) => switch ((f, b)) {
    (BrandFamily.green, _) => const Color(0xFF06C755),
    (BrandFamily.blue, Brightness.light) => const Color(0xFF007AFF),
    (BrandFamily.blue, Brightness.dark) => const Color(0xFF0A84FF),
  };
}
