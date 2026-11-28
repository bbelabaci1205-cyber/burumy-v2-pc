// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가입 심사 도우미 (join helper) and join questions: what the room keeps
// (room config keys `gate` and `join_questions`) and the helper's log.
// The helper itself runs on our server (server/gate). It has no encryption
// keys, so it gets no room keys and can't read the chat; it only sees a
// join request (name + answers) and lets people in or says no.

/// One join question. No choices = a written answer; 2-6 choices = quiz
/// (pick one; `right` is known to admins and the helper only).
class GateQuestion {
  const GateQuestion({required this.q, this.choices = const [], this.right = -1});
  final String q;
  final List<String> choices;
  final int right;

  bool get quiz => choices.isNotEmpty;

  static const max = 5;
  static const qMax = 200;
  static const choiceMax = 80;
  static const choicesMin = 2;
  static const choicesMax = 6;

  Object toJson() => quiz ? {'q': q, 'choices': choices, 'right': right} : q;

  static GateQuestion? fromJson(Object? v) {
    if (v is String && v.trim().isNotEmpty) return GateQuestion(q: v);
    if (v is Map) {
      final q = v['q'];
      if (q is! String || q.trim().isEmpty) return null;
      final choices = [
        for (final c in (v['choices'] as List? ?? const []))
          if (c is String) c,
      ];
      final right = (v['right'] as num?)?.toInt() ?? -1;
      if (choices.isNotEmpty && (choices.length < choicesMin || choices.length > choicesMax)) return null;
      return GateQuestion(q: q, choices: choices, right: right);
    }
    return null;
  }

  static List<GateQuestion> listFrom(Map<String, dynamic> cfg) => [for (final v in (cfg['join_questions'] as List? ?? const []).take(max)) ?fromJson(v)];
}

/// The helper's switches for one room.
class GateSettings {
  const GateSettings({this.on = false, this.needAnswers = true, this.words = const [], this.ai = false, this.about = ''});
  final bool on;
  final bool needAnswers;
  final List<String> words;
  final bool ai;
  final String about;

  static const wordsMax = 30;
  static const aboutMax = 300;

  factory GateSettings.from(Map<String, dynamic> cfg) {
    final g = cfg['gate'];
    if (g is! Map) return const GateSettings();
    return GateSettings(
      on: g['on'] == true,
      needAnswers: g['need_answers'] != false,
      words: [
        for (final w in (g['words'] as List? ?? const []))
          if (w is String && w.trim().isNotEmpty) w,
      ],
      ai: g['ai'] == true,
      about: (g['about'] as String?) ?? '',
    );
  }

  GateSettings copyWith({bool? on, bool? needAnswers, List<String>? words, bool? ai, String? about}) =>
      GateSettings(on: on ?? this.on, needAnswers: needAnswers ?? this.needAnswers, words: words ?? this.words, ai: ai ?? this.ai, about: about ?? this.about);

  Map<String, Object> toJson() => {
    'on': on,
    'need_answers': needAnswers,
    if (words.isNotEmpty) 'words': words,
    if (ai) 'ai': true,
    if (about.trim().isNotEmpty) 'about': about.trim(),
  };
}

/// Whether the helper is in the room and how many encryption devices it
/// has (0 = it can't get any room key).
class GateHelper {
  const GateHelper({this.joined = false, this.devices = 0});
  final bool joined;
  final int devices;
}

/// One decision in the helper's log. `verdict`: ok / ai (let in), quiz /
/// empty / words / fake (turned down), checking / ai_hold (left for the
/// admins).
class GateEntry {
  const GateEntry({required this.userId, required this.name, required this.verdict, required this.at});
  final String userId;
  final String name;
  final String verdict;
  final DateTime at;

  /// let in / turned down / left for the admins.
  String get kind => switch (verdict) {
    'ok' || 'ai' => 'in',
    'quiz' || 'empty' || 'words' || 'fake' => 'out',
    _ => 'held',
  };

  static List<GateEntry> listFrom(Object? json) {
    final e = json is Map ? json['e'] : null;
    return [
      for (final x in (e is List ? e : const []))
        if (x is Map && x['u'] is String)
          GateEntry(
            userId: x['u'] as String,
            name: (x['n'] as String?)?.isNotEmpty == true ? x['n'] as String : (x['u'] as String),
            verdict: (x['v'] as String?) ?? '',
            at: DateTime.fromMillisecondsSinceEpoch((x['t'] as num?)?.toInt() ?? 0),
          ),
    ].reversed.toList();
  }
}

/// The same free rules the helper uses (server/gate/src/lib.rs `screen`),
/// for the look-only demo and for tests. Returns ok / quiz / empty / words
/// / fake / checking.
String gateScreen(List<GateQuestion> qs, GateSettings g, List<String> answers, {String name = '', String flag = ''}) {
  if (flag == 'fake') return 'fake';
  final text = '${name.toLowerCase()} ${answers.join(' ').toLowerCase()}';
  if (g.words.any((w) => w.trim().isNotEmpty && text.contains(w.trim().toLowerCase()))) return 'words';
  if (gateRightWrong(qs, answers).any((r) => r == false)) return 'quiz';
  for (var i = 0; i < qs.length; i++) {
    if (!qs[i].quiz && g.needAnswers && (i >= answers.length || answers[i].trim().characters < 2)) return 'empty';
  }
  if (flag == 'checking') return 'checking';
  return 'ok';
}

/// Right / wrong per quiz question (null for written ones).
List<bool?> gateRightWrong(List<GateQuestion> qs, List<String> answers) => [
  for (var i = 0; i < qs.length; i++) qs[i].quiz ? (i < answers.length && int.tryParse(answers[i].trim()) == qs[i].right) : null,
];

extension on String {
  int get characters => runes.length;
}
