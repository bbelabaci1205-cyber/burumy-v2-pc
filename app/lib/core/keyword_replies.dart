// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 키워드 자동 답장 (v1 parity batch 5, 2026-11-27): a group admin sets
// "word → answer" pairs; the admin's own phone answers when a member's
// message has the word (the server can't read messages). One answer per
// message, and the same word at most once a minute so it never floods.
import 'dart:convert';

import 'backend.dart';

typedef KeywordRule = ({String word, String answer});

String keywordKey(String roomId) => 'keyword_replies:$roomId';

List<KeywordRule> keywordRules(Map<String, String> prefs, String roomId) {
  try {
    final list = jsonDecode(prefs[keywordKey(roomId)] ?? '[]') as List;
    return [
      for (final x in list)
        if (x is Map && '${x['w'] ?? ''}'.trim().isNotEmpty && '${x['a'] ?? ''}'.trim().isNotEmpty) (word: '${x['w']}'.trim(), answer: '${x['a']}'.trim()),
    ];
  } catch (_) {
    return const [];
  }
}

String encodeKeywordRules(List<KeywordRule> rules) => jsonEncode([
  for (final r in rules) {'w': r.word, 'a': r.answer},
]);

/// The rule a message sets off, if any (first match, any case).
KeywordRule? keywordFor(String text, List<KeywordRule> rules) {
  final t = text.toLowerCase();
  for (final r in rules) {
    if (t.contains(r.word.toLowerCase())) return r;
  }
  return null;
}

/// Messages to answer now: newer than [since], not mine, plain text, and
/// not a word answered within the last minute ([lastByWord], ms).
List<(Msg, KeywordRule)> keywordAnswers(List<Msg> msgs, List<KeywordRule> rules, DateTime since, Map<String, int> lastByWord) {
  final out = <(Msg, KeywordRule)>[];
  final last = Map.of(lastByWord);
  for (final m in msgs) {
    if (m.mine || m.kind != 'text' || !m.time.isAfter(since)) continue;
    final r = keywordFor(m.body ?? '', rules);
    if (r == null) continue;
    final at = last[r.word];
    if (at != null && m.time.millisecondsSinceEpoch - at < 60000) continue;
    last[r.word] = m.time.millisecondsSinceEpoch;
    out.add((m, r));
  }
  return out;
}
