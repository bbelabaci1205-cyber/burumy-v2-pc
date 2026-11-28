// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// On-phone AI (AI 편집기, 573 article editor, later the AI secretary).
// iPhone: Apple's built-in model (Apple Intelligence phones, iOS 26+).
// Android: Google's built-in model (Gemini Nano phones).
// Text never leaves the phone. Web, older phones and tests: [available]
// says no, and callers hide their AI buttons.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AiStatus {
  /// Ready to use now.
  ready,

  /// The phone can do it but is still getting the model (Android).
  preparing,

  /// This phone (or the web) has no built-in AI.
  unsupported,
}

/// Something that turns text into text on this phone.
abstract class AiEngine {
  Future<AiStatus> status();

  /// [rules] tell the model what to do; [text] is the person's words.
  /// Throws [AiError] when it can't.
  Future<String> run({required String rules, required String text});
}

class AiError implements Exception {
  const AiError(this.code);

  /// "unsupported", "busy", "refused", "failed" or "age" (Android, under
  /// 18 or not asked yet).
  final String code;
  @override
  String toString() => 'AiError($code)';
}

/// The real phone engine, over our own channel (no outside plugin).
class PhoneAi implements AiEngine {
  static const _ch = MethodChannel('app.burumy/ai');

  @override
  Future<AiStatus> status() async {
    if (kIsWeb) return AiStatus.unsupported;
    try {
      final s = await _ch.invokeMethod<String>('status');
      return switch (s) {
        'ready' => AiStatus.ready,
        'preparing' => AiStatus.preparing,
        _ => AiStatus.unsupported,
      };
    } catch (_) {
      return AiStatus.unsupported;
    }
  }

  @override
  Future<String> run({required String rules, required String text}) async {
    if (kIsWeb) throw const AiError('unsupported');
    try {
      final out = await _ch.invokeMethod<String>('run', {'rules': rules, 'text': text});
      if (out == null || out.trim().isEmpty) throw const AiError('failed');
      return out.trim();
    } on PlatformException catch (e) {
      throw AiError(switch (e.code) {
        'unsupported' || 'busy' || 'refused' => e.code,
        _ => 'failed',
      });
    } on MissingPluginException {
      throw const AiError('unsupported');
    }
  }
}

/// Shared entry point. Tests and the web demo swap [engine].
class LocalAi {
  const LocalAi._();
  static AiEngine engine = PhoneAi();
  static AiStatus? _known;

  /// True while the person may not use the phone's AI (Android under 18,
  /// or not asked yet: core/ai_age.dart). Set by main.dart; the screens ask
  /// first, this is the last stop.
  static bool Function() blocked = () => false;

  /// Cached after the first ask; [refresh] asks the phone again.
  static Future<AiStatus> status({bool refresh = false}) async {
    if (!refresh && _known != null) return _known!;
    return _known = await engine.status();
  }

  static Future<bool> available() async => !blocked() && await status() == AiStatus.ready;

  /// What the last [status] said, without asking again (null = not asked
  /// yet). The composer's AI button and Settings use this.
  static AiStatus? get known => _known;

  /// The phone can do it (now, or once its model is ready).
  static bool get onPhone => _known == AiStatus.ready || _known == AiStatus.preparing;

  /// Clears the cache (tests, or after the model finished downloading).
  static void reset() => _known = null;

  static Future<String> run({required String rules, required String text}) async {
    if (blocked()) throw const AiError('age');
    return engine.run(rules: rules, text: text);
  }
}
