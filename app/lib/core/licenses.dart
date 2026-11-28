// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Licence notices that Flutter does not collect by itself, for 설정 >
// 오픈소스·출처 (IP review 2026-11-27, L4): the Pretendard font (SIL OFL
// 1.1: its licence must travel with the font), the Rust crates inside the
// engine (assets/licenses/rust.txt, made by scripts/make_rust_notices.sh
// with cargo-about), Google ML Kit on Android, MET Norway weather data and
// Meta's PDQ picture fingerprint (our safety server), PDFium (PDF view),
// Noto Animated Emoji (CC BY 4.0, 움직이는 큰 이모지).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google's own disclaimer for shown translations (Cloud Translation
/// attribution page, which the ML Kit translation terms point to). Kept in
/// Google's words, so not translated.
const googleTranslateDisclaimer =
    'THIS SERVICE MAY CONTAIN TRANSLATIONS POWERED BY GOOGLE. GOOGLE DISCLAIMS ALL WARRANTIES RELATED TO THE TRANSLATIONS, '
    'EXPRESS OR IMPLIED, INCLUDING ANY WARRANTIES OF ACCURACY, RELIABILITY, AND ANY IMPLIED WARRANTIES OF MERCHANTABILITY, '
    'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.';

const metNorwayNotice =
    'Weather data from The Norwegian Meteorological Institute (MET Norway), licensed under the Creative Commons '
    'Attribution 4.0 International licence (CC BY 4.0): https://creativecommons.org/licenses/by/4.0/\n\n'
    'Changes: our weather server rounds the place to about 10 km and the app turns the forecast into its own '
    'temperature and sky picture. Burumy is not made by or connected with MET Norway or Yr.\n\n'
    'Source: https://api.met.no';

const mlKitNotice =
    'Android only: translation, language detection, document scanning, background removal (subject segmentation) '
    'and the on-device AI model (ML Kit GenAI) are provided by Google ML Kit and run on the phone.\n\n'
    'Terms: https://developers.google.com/ml-kit/terms\n'
    'Translation terms: https://developers.google.com/ml-kit/language/translation/translation-terms\n'
    'GenAI terms: https://developers.google.com/ml-kit/genai-terms\n\n'
    'Translations on Android are powered by Google Translate.\n\n$googleTranslateDisclaimer';

const pdqNotice =
    'PDQ picture fingerprint, published by Meta Platforms (ThreatExchange), used by our safety server through the '
    'pdqhash crate (Apache-2.0) to recognise known illegal pictures. No picture in a private chat is checked.\n\n'
    'https://github.com/facebook/ThreatExchange/tree/main/pdq';

/// The PDF engine inside 문서 바로 보기 (tip 473): pdfrx (MIT, listed by
/// Flutter) loads PDFium, which is not a Dart package.
const pdfiumNotice =
    'PDFium, the PDF engine made by Google and the PDFium authors, used to show PDF files inside Burumy. '
    'Licensed under the BSD 3-Clause licence and the Apache License 2.0; it includes FreeType (FreeType licence), '
    'libjpeg-turbo, libpng, zlib, OpenJPEG and LittleCMS under their own permissive licences.\n\n'
    'https://pdfium.googlesource.com/pdfium/+/main/LICENSE';

/// 움직이는 큰 이모지: Google's Noto Animated Emoji, used unchanged.
const notoAnimatedNotice =
    'Animated emoji: Noto Animated Emoji by Google, licensed under the Creative Commons Attribution 4.0 '
    'International licence (CC BY 4.0): https://creativecommons.org/licenses/by/4.0/\n\n'
    'Used unchanged (40 of them, played when an emoji is sent on its own). Burumy is not made by or connected '
    'with Google.\n\n'
    'Source: https://googlefonts.github.io/noto-emoji-animation/';

bool _done = false;

/// Adds the notices above to Flutter's licence list (once).
void registerExtraLicenses() {
  if (_done) return;
  _done = true;
  LicenseRegistry.addLicense(_extra);
}

Stream<LicenseEntry> _extra() async* {
  yield const LicenseEntryWithLineBreaks(['MET Norway (weather data)'], metNorwayNotice);
  yield const LicenseEntryWithLineBreaks(['Google ML Kit (Android)'], mlKitNotice);
  yield const LicenseEntryWithLineBreaks(['PDQ (Meta)'], pdqNotice);
  yield const LicenseEntryWithLineBreaks(['PDFium'], pdfiumNotice);
  yield const LicenseEntryWithLineBreaks(['Noto Animated Emoji (Google)'], notoAnimatedNotice);
  try {
    yield LicenseEntryWithLineBreaks(['Pretendard'], await rootBundle.loadString('assets/fonts/Pretendard-OFL.txt'));
  } catch (_) {}
  try {
    for (final e in parseRustNotices(await rootBundle.loadString('assets/licenses/rust.txt'))) {
      yield e;
    }
  } catch (_) {}
}

/// `assets/licenses/rust.txt`: blocks of `@@@ licence name`, then a line of
/// `crate version|crate version`, then the licence text.
@visibleForTesting
List<LicenseEntry> parseRustNotices(String data) {
  final out = <LicenseEntry>[];
  for (final part in data.split('@@@ ').skip(1)) {
    final a = part.indexOf('\n');
    final b = a < 0 ? -1 : part.indexOf('\n', a + 1);
    if (b < 0) continue;
    final crates = part.substring(a + 1, b).split('|').where((c) => c.isNotEmpty).map((c) => c.split(' ').first).toSet().toList();
    if (crates.isEmpty) continue;
    out.add(LicenseEntryWithLineBreaks(crates, part.substring(b + 1).trim()));
  }
  return out;
}
