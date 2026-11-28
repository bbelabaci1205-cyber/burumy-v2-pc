// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Translation on the phone only (Telegram's 번역 button and 대화 전체 번역,
// v1 parity; Eric 2026-11-27 "고를것없이 다해죠" -> on-device engine).
//
// iPhone: Apple's Translation framework (system, free, works offline once
// the language is downloaded in iOS Settings). Android: Google ML Kit
// on-device translation (the same ML Kit family the app already uses for
// the AI 편집기 and document scan; language packs ~30 MB each, downloaded
// once on Wi-Fi). Words never go to a translation server. If neither is
// there, the phone's own AI model (AI 편집기) is tried. The web has none.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ai_local.dart';
import 'ai_styles.dart' show detectLanguage, AiStyles;

/// Languages offered, Telegram's order of the most used ones (screen
/// names in the l10n files: trLang_xx).
const trLanguages = <String>['ko', 'en', 'ja', 'zh', 'es', 'fr', 'de', 'ru', 'pt', 'it', 'vi', 'th', 'id', 'tr', 'ar', 'hi', 'uk', 'pl', 'nl'];

/// English names, for the AI model fallback's instructions.
const trEnglishNames = <String, String>{
  'ko': 'Korean',
  'en': 'English',
  'ja': 'Japanese',
  'zh': 'Chinese',
  'es': 'Spanish',
  'fr': 'French',
  'de': 'German',
  'ru': 'Russian',
  'pt': 'Portuguese',
  'it': 'Italian',
  'vi': 'Vietnamese',
  'th': 'Thai',
  'id': 'Indonesian',
  'tr': 'Turkish',
  'ar': 'Arabic',
  'hi': 'Hindi',
  'uk': 'Ukrainian',
  'pl': 'Polish',
  'nl': 'Dutch',
};

enum TrStatus {
  /// Translates now, offline.
  ready,

  /// The phone can, after getting this language once (Wi-Fi download).
  download,

  /// This phone (or the web) can't.
  unsupported,
}

class TrError implements Exception {
  const TrError(this.code);

  /// "unsupported", "download" (language not on the phone yet), "failed".
  final String code;
  @override
  String toString() => 'TrError($code)';
}

/// Something that translates on this phone.
abstract class TranslateEngine {
  /// The language of [text] ('en', 'ja', ...), or null when unsure.
  Future<String?> detect(String text);

  Future<TrStatus> status(String from, String to);

  /// Throws [TrError] when it can't.
  Future<String> translate(String text, {required String from, required String to});
}

/// The phone's own engine over our channel (no outside Flutter plugin).
class PhoneTranslate implements TranslateEngine {
  static const _ch = MethodChannel('app.burumy/translate');

  @override
  Future<String?> detect(String text) async {
    if (!kIsWeb) {
      try {
        final got = await _ch.invokeMethod<String>('detect', {'text': text});
        if (got != null && got.isNotEmpty && got != 'und') return got.split('-').first;
      } catch (_) {}
    }
    final guess = detectLanguage(text);
    return guess.isEmpty ? null : guess;
  }

  @override
  Future<TrStatus> status(String from, String to) async {
    if (kIsWeb) return TrStatus.unsupported;
    try {
      final s = await _ch.invokeMethod<String>('status', {'from': from, 'to': to});
      final st = switch (s) {
        'ready' => TrStatus.ready,
        'download' => TrStatus.download,
        _ => TrStatus.unsupported,
      };
      if (st != TrStatus.unsupported) return st;
    } catch (_) {}
    return await LocalAi.available() ? TrStatus.ready : TrStatus.unsupported;
  }

  @override
  Future<String> translate(String text, {required String from, required String to}) async {
    if (kIsWeb) throw const TrError('unsupported');
    try {
      final out = await _ch.invokeMethod<String>('translate', {'text': text, 'from': from, 'to': to});
      if (out != null && out.trim().isNotEmpty) return out;
    } on PlatformException catch (e) {
      if (e.code == 'download') throw const TrError('download');
    } on MissingPluginException {
      // Older app build: fall through to the AI model.
    }
    // The phone's own AI model, when there is one.
    if (await LocalAi.available()) {
      try {
        return await LocalAi.run(rules: AiStyles.translateRules(trEnglishNames[to] ?? 'Korean'), text: text);
      } on AiError {
        throw const TrError('failed');
      }
    }
    throw const TrError('unsupported');
  }

  /// Gets a language onto the phone (Android: ML Kit pack on Wi-Fi; iPhone:
  /// the system's download sheet). True when it is there now.
  static Future<bool> download(String from, String to) async {
    if (kIsWeb) return false;
    try {
      return await _ch.invokeMethod<bool>('download', {'from': from, 'to': to}) ?? false;
    } catch (_) {
      return false;
    }
  }
}

/// Shared entry point with a small in-memory cache (translations are never
/// written to disk: they are message words). Tests and the web demo swap
/// [engine].
class Translate {
  const Translate._();
  static TranslateEngine engine = PhoneTranslate();
  static final _cache = <String, String>{};
  static final _lang = <String, String?>{};
  static final _pending = <String, Future<String>>{};

  /// Already translated (no waiting), or null.
  static String? cached(String text, String to) => _cache['$to\u0000$text'];

  static Future<String?> detect(String text) async {
    if (_lang.containsKey(text)) return _lang[text];
    final got = await engine.detect(text);
    if (_lang.length > 2000) _lang.clear();
    return _lang[text] = got;
  }

  static Future<TrStatus> status(String from, String to) => engine.status(from, to);

  static Future<String> run(String text, {required String to, String? from}) {
    final k = '$to\u0000$text';
    final hit = _cache[k];
    if (hit != null) return SynchronousFuture(hit);
    return _pending[k] ??= () async {
      try {
        final src = from ?? await detect(text) ?? 'en';
        if (src == to) return text;
        final out = await engine.translate(text, from: src, to: to);
        if (_cache.length > 1000) _cache.clear();
        return _cache[k] = out;
      } finally {
        _pending.remove(k);
      }
    }();
  }

  /// Tests.
  static void reset() {
    _cache.clear();
    _lang.clear();
    _pending.clear();
  }

  /// The main language of a chat's recent incoming words (null when mixed
  /// or too little to tell). Telegram needs most messages in one language.
  static Future<String?> chatLanguage(List<String> texts) async {
    final counts = <String, int>{};
    var n = 0;
    for (final raw in texts) {
      // Web addresses are Latin letters in any language: leave them out.
      final t = raw.replaceAll(RegExp(r'https?://\S+'), ' ');
      if (t.trim().length < 2) continue;
      final g = await detect(t);
      n++;
      if (g != null) counts[g] = (counts[g] ?? 0) + 1;
    }
    if (n == 0) return null;
    final best = counts.entries.fold<MapEntry<String, int>?>(null, (a, b) => a == null || b.value > a.value ? b : a);
    if (best == null || best.value * 2 < n) return null;
    return best.key;
  }
}

/// Android translates with Google ML Kit, whose terms ask for the Google
/// Translate attribution next to every translation ("powered by Google
/// Translate", text style allowed; read 2026-11-27 from the ML Kit
/// translation terms + Cloud Translation attribution page). The iPhone uses
/// Apple's engine, so no credit there.
class TrCredit {
  const TrCredit._();

  /// Tests and screenshots: act as Android (true) or not (false).
  static bool? debugAndroid;
  static bool get google => debugAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
}

/// Settings keys (Settings > 언어, Telegram's "번역" group).
class TrPrefs {
  const TrPrefs._();

  /// "번역 버튼 보기": 번역 in the message menu (Telegram default off).
  static const button = 'translate_button';

  /// "대화 전체 번역": the bar on top of a chat in another language.
  static const chat = 'translate_chat';

  /// "번역하지 않을 언어": comma list; empty = only the app's language.
  static const skip = 'translate_skip';

  /// Per chat: translating into this language now.
  static String on(String room) => 'tr_on:$room';

  /// Per chat: the bar hidden (가리기).
  static String hidden(String room) => 'tr_hide:$room';

  /// Per chat: translate into this language instead of mine.
  static String to(String room) => 'tr_to:$room';
}
