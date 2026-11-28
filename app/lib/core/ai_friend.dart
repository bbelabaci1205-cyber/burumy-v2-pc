// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// AI 친구 (Snapchat My AI, our way; 4대 메신저 보드 '우리식으로', Eric
// 2026-11-28). A chat in the list with the AI built into the phone (Apple
// Intelligence / Gemini Nano, core/ai_local.dart). Snapchat sends every
// word to its servers; here nothing leaves the phone: the talk is kept in
// the app's own encrypted settings on this phone and the answers come from
// the phone's model. Cloud AI stays the later '잠긴 방 AI' plan
// (Features.cloudAi, off).
import 'dart:convert';

import 'ai_local.dart';
import 'app_state.dart';

class AiLine {
  const AiLine({required this.mine, required this.text, required this.at});
  final bool mine;
  final String text;
  final DateTime at;

  List<Object> toJson() => [mine ? 1 : 0, text, at.millisecondsSinceEpoch];

  static AiLine? fromJson(Object? v) {
    if (v is! List || v.length != 3 || v[1] is! String || v[2] is! int) return null;
    return AiLine(mine: v[0] == 1, text: v[1] as String, at: DateTime.fromMillisecondsSinceEpoch(v[2] as int));
  }
}

class AiFriend {
  const AiFriend._();

  /// The chat list row's id (never a real room).
  static const rowId = 'aifriend:';

  /// Settings > 대화 > AI 기능 > 대화 목록에 AI 친구 보이기 (on by default).
  static const pref = 'ai_friend_row';
  static const logKey = 'ai_friend_log';

  /// Kept on this phone (oldest go first).
  static const keep = 200;

  /// Turns the model sees (it has a small window).
  static const context = 8;

  static const maxText = 1000;

  /// In the list: switched on, and this phone has its own AI.
  static bool listed(AppState s) => s.on(pref, fallback: true) && LocalAi.onPhone && !LocalAi.blocked();

  static List<AiLine> log(AppState s) {
    final raw = s.pref(logKey, '');
    if (raw.isEmpty) return const [];
    try {
      return [for (final v in jsonDecode(raw) as List) ?AiLine.fromJson(v)];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(AppState s, List<AiLine> all) {
    final cut = all.length > keep ? all.sublist(all.length - keep) : all;
    return s.setPref(logKey, cut.isEmpty ? '' : jsonEncode([for (final l in cut) l.toJson()]));
  }

  static Future<void> clear(AppState s) => s.setPref(logKey, '');

  /// What the model is told: who it is, how to answer, and the last turns.
  static String rules(List<AiLine> before, {required bool korean}) {
    final b = StringBuffer(
      'You are the Burumy AI friend, a warm and helpful friend inside a private messenger. '
      'Answer in ${korean ? 'Korean, polite and friendly (해요체)' : 'English, friendly'}. '
      'Keep it short: at most five sentences, no lists unless asked. '
      'Never claim to see the user\'s chats, contacts or files; you only see this conversation. '
      'If asked for medical, legal or money decisions, give general information and suggest asking an expert.',
    );
    final last = before.length > context ? before.sublist(before.length - context) : before;
    if (last.isNotEmpty) {
      b.write('\nConversation so far:');
      for (final l in last) {
        b.write('\n${l.mine ? 'User' : 'AI friend'}: ${l.text}');
      }
    }
    return b.toString();
  }

  /// Adds my words, asks the phone's AI, adds its answer. Throws [AiError].
  static Future<String> ask(AppState s, String text, {required bool korean}) async {
    final t = text.trim();
    if (t.isEmpty) return '';
    final words = t.length > maxText ? t.substring(0, maxText) : t;
    final before = log(s);
    await _save(s, [...before, AiLine(mine: true, text: words, at: DateTime.now())]);
    final out = await LocalAi.run(
      rules: rules(before, korean: korean),
      text: words,
    );
    await _save(s, [...log(s), AiLine(mine: false, text: out, at: DateTime.now())]);
    return out;
  }
}
