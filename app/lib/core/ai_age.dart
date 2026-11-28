// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Android's on-phone AI (Google ML Kit GenAI: Gemini Nano for the AI 편집기,
// summaries and AI rewrites; subject segmentation for the sticker maker's
// background removal) may only be used by people 18 or older (ML Kit GenAI
// Additional Terms, read 2026-11-27). Eric 2026-11-27 (review card A + "18세
//이상 확인받기"): we have no signup age, so the app asks once, on the first
// AI tap: "만 18세 이상이에요" / "18세 미만이에요". Under 18 = those AI
// features stay off ("18세 이상만 쓸 수 있어요"). Translation (ML Kit
// translate, not GenAI) and everything on the iPhone (Apple's own AI) are
// not affected.
import 'package:flutter/foundation.dart';

import 'app_state.dart';

enum AiAgeAnswer { unknown, adult, minor }

class AiAge {
  const AiAge._();

  /// Settings key: 'adult' or 'minor' (missing = not asked yet).
  static const key = 'ai_age';

  /// Tests and screenshots: act as Android (true) or not (false).
  static bool? debugAndroid;

  /// The age check only exists on Android phones.
  static bool get applies => debugAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static AiAgeAnswer answer(AppState s) => switch (s.pref(key, '')) {
    'adult' => AiAgeAnswer.adult,
    'minor' => AiAgeAnswer.minor,
    _ => AiAgeAnswer.unknown,
  };

  /// The Google AI features may run now (no question needed).
  static bool allowed(AppState s) => !applies || answer(s) == AiAgeAnswer.adult;

  static Future<void> set(AppState s, bool adult) => s.setPref(key, adult ? 'adult' : 'minor');
}
