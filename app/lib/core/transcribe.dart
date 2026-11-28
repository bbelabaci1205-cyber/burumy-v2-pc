// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 음성 메시지를 글로 보기 (WhatsApp 2025, WeChat): the phone's own speech
// recognition turns a voice message into words. On-device only: iPhone
// uses Apple's speech recognition with "on this device" forced, Android
// 13+ its on-device recognizer. A phone that can only do it on a server
// says "unsupported" and the button is hidden; the sound never leaves the
// phone. Translation of the words uses the phone AI (core/ai_local.dart).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Transcribe {
  const Transcribe._();
  static const _ch = MethodChannel('app.burumy/phone');

  /// Tests and the look-only web demo answer here instead of the phone.
  static Future<String?> Function(Uint8List bytes, String mime, String lang)? debug;

  /// Words heard in this sound (null = this phone can't, '' = no words).
  /// [lang]: the language to listen for ('ko', 'en', …).
  static Future<String?> run(Uint8List bytes, {required String mime, required String lang}) async {
    final d = debug;
    if (d != null) return d(bytes, mime, lang);
    if (kIsWeb) return null;
    try {
      return await _ch.invokeMethod<String>('transcribe', {'bytes': bytes, 'mime': mime, 'lang': lang});
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Whether to offer the button (the web has no on-device recognizer).
  static bool get offered => debug != null || !kIsWeb;
}
