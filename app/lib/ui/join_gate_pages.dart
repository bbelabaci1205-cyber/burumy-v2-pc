// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가입 심사 도우미 (join helper) screens (Features.joinGate).
// - GatePage: admins switch the helper on, write join questions (written
//   or quiz), set the rules, see the log. iOS Settings layout.
// - GateQuestionPage: one question; quiz = 2-6 choices, tap one as right.
// - GateLogPage: who the helper let in, turned down or left for admins.
// - JoinQuizPage: the person asking answers the questions; quiz answers are
//   checked at once (right / try again), then the request goes out and
//   the helper answers within seconds.
// The helper has no encryption keys: it can't read the chat (shown on the
// page with the live key count).
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';

class GatePage extends StatefulWidget {
  const GatePage({super.key, required this.roomId});
  final String roomId;

  @override
  State<GatePage> createState() => _GatePageState();
}

class _GatePageState extends State<GatePage> {
  GateSettings gate = const GateSettings();
  List<GateQuestion> questions = const [];
  GateHelper helper = const GateHelper();
  int logCount = 0;
  bool loaded = false;
  bool busy = false;

  Backend get b => AppScope.read(context).backend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final cfg = await b.roomConfig(widget.roomId);
    final h = await b.gateHelper(widget.roomId).catchError((_) => const GateHelper());
    final log = await b.gateLog(widget.roomId).catchError((_) => const <GateEntry>[]);
    if (!mounted) return;
    setState(() {
      gate = GateSettings.from(cfg);
      questions = GateQuestion.listFrom(cfg);
      helper = h;
      logCount = log.length;
      loaded = true;
    });
  }

  Future<void> saveGate(GateSettings g) async {
    final before = gate;
    setState(() => gate = g);
    try {
      await b.setRoomConfig(widget.roomId, 'gate', g.toJson());
    } catch (_) {
      if (mounted) setState(() => gate = before);
    }
  }

  Future<void> saveQuestions(List<GateQuestion> qs) async {
    final before = questions;
    setState(() => questions = qs);
    try {
      await b.setRoomConfig(widget.roomId, 'join_questions', qs.isEmpty ? null : [for (final q in qs) q.toJson()]);
    } catch (_) {
      if (mounted) setState(() => questions = before);
    }
  }

  Future<void> setOn(bool on) async {
    setState(() => busy = true);
    try {
      // The helper reads the switch when it comes in, so write it first.
      if (on) await saveGate(gate.copyWith(on: true));
      await b.setGateHelper(widget.roomId, on);
      if (!on) await saveGate(gate.copyWith(on: false));
    } catch (_) {}
    await load();
    if (mounted) setState(() => busy = false);
  }

  Future<void> editQuestion(int? i) async {
    final r = await Navigator.of(context).push<Object>(IosPageRoute(builder: (_) => GateQuestionPage(initial: i == null ? null : questions[i])));
    if (r == null) return;
    final next = List.of(questions);
    if (r == GateQuestionPage.removed) {
      if (i != null) next.removeAt(i);
    } else if (r is GateQuestion) {
      i == null ? next.add(r) : next[i] = r;
    }
    await saveQuestions(next);
  }

  Future<void> editWords() async {
    final r = await Navigator.of(context).push<List<String>>(IosPageRoute(builder: (_) => GateWordsPage(initial: gate.words)));
    if (r != null) await saveGate(gate.copyWith(words: r));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    String kindOf(GateQuestion q) => q.quiz ? l.gateQuizKind(q.choices.length) : l.gateWrittenKind;
    return SettingsScaffold(
      title: l.gateTitle,
      children: [
        HeaderCard(color: p.tileGreen, icon: CupertinoIcons.person_crop_circle_badge_checkmark, title: l.gateTitle, body: l.gateHeader),
        if (!loaded)
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[5]),
            child: const Center(child: CupertinoActivityIndicator()),
          )
        else ...[
          group(context, footer: l.gateOnInfo, [
            IosTile(
              title: Text(l.gateOn),
              trailing: busy
                  ? const CupertinoActivityIndicator()
                  : IosSwitch(key: const Key('gate-on'), value: gate.on, activeTrackColor: p.accent, onChanged: setOn),
            ),
          ]),
          if (gate.on)
            group(context, header: l.gateSafety, footer: l.gateSafetyInfo, [
              IosTile(
                key: const Key('gate-keys'),
                leading: iconTile(helper.devices == 0 ? p.tileGreen : Palette.tileRed, CupertinoIcons.lock_shield_fill),
                title: Text(helper.devices == 0 ? l.gateCantRead : l.gateHasKeys),
                additionalInfo: Text(l.gateKeyCount(helper.devices)),
              ),
            ]),
          group(context, header: l.gateQuestions, footer: l.gateQuestionsInfo, [
            for (var i = 0; i < questions.length; i++)
              IosTile(
                key: Key('gate-q-$i'),
                title: Text(questions[i].q, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(kindOf(questions[i])),
                trailing: const IosChevron(),
                onTap: () => editQuestion(i),
              ),
            if (questions.length < GateQuestion.max)
              IosTile(
                key: const Key('gate-q-add'),
                leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 22),
                title: Text(l.gateAddQuestion, style: TextStyle(color: p.accent)),
                onTap: () => editQuestion(null),
              ),
          ]),
          group(context, header: l.gateRules, footer: l.gateRulesInfo, [
            IosTile(
              title: Text(l.gateNeedAnswers),
              trailing: IosSwitch(
                key: const Key('gate-need'),
                value: gate.needAnswers,
                activeTrackColor: p.accent,
                onChanged: (v) => saveGate(gate.copyWith(needAnswers: v)),
              ),
            ),
            NavRow(key: const Key('gate-words'), title: l.gateWords, value: '${gate.words.length}', onTap: editWords),
          ]),
          // AI check of written answers: only when cloud AI exists at all
          // (Features.cloudAi, off) and the room's owner turns it on.
          if (Features.cloudAi)
            group(context, footer: l.gateAiInfo, [
              IosTile(
                title: Text(l.gateAi),
                trailing: IosSwitch(
                  value: gate.ai,
                  activeTrackColor: p.accent,
                  onChanged: (v) => saveGate(gate.copyWith(ai: v)),
                ),
              ),
            ]),
          group(context, [
            NavRow(
              key: const Key('gate-log'),
              color: Palette.tileIndigo,
              icon: CupertinoIcons.list_bullet,
              title: l.gateLog,
              value: '$logCount',
              onTap: () async {
                await Navigator.of(context).push(IosPageRoute(builder: (_) => GateLogPage(roomId: widget.roomId)));
                await load();
              },
            ),
          ]),
        ],
      ],
    );
  }
}

/// One join question. Pops a GateQuestion, [removed], or null (back).
class GateQuestionPage extends StatefulWidget {
  const GateQuestionPage({super.key, this.initial});
  final GateQuestion? initial;

  static const removed = 'removed';

  @override
  State<GateQuestionPage> createState() => _GateQuestionPageState();
}

class _GateQuestionPageState extends State<GateQuestionPage> {
  late final q = TextEditingController(text: widget.initial?.q ?? '');
  late bool quiz = widget.initial?.quiz ?? true;
  late final choices = [
    for (final c in (widget.initial?.quiz == true ? widget.initial!.choices : const ['', ''])) TextEditingController(text: c),
  ];
  late int right = widget.initial?.quiz == true ? widget.initial!.right : 0;

  @override
  void dispose() {
    q.dispose();
    for (final c in choices) {
      c.dispose();
    }
    super.dispose();
  }

  bool get ok =>
      q.text.trim().isNotEmpty &&
      (!quiz || (choices.length >= GateQuestion.choicesMin && choices.every((c) => c.text.trim().isNotEmpty) && right < choices.length));

  void done() =>
      Navigator.of(context).pop(GateQuestion(q: q.text.trim(), choices: quiz ? [for (final c in choices) c.text.trim()] : const [], right: quiz ? right : -1));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key key, TextEditingController c, String hint, int max) => CupertinoTextField.borderless(
      key: key,
      controller: c,
      placeholder: hint,
      maxLength: max,
      style: Tokens.body.style.copyWith(color: p.label),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 2),
      onChanged: (_) => setState(() {}),
    );
    return SettingsScaffold(
      title: widget.initial == null ? l.gateAddQuestion : l.gateEditQuestion,
      trailing: [GlassDone(key: const Key('gate-q-done'), onTap: ok ? done : null)],
      children: [
        group(context, [field(const Key('gate-q-text'), q, l.gateQuestionHint, GateQuestion.qMax)]),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
          child: CupertinoSlidingSegmentedControl<bool>(
            key: const Key('gate-q-kind'),
            groupValue: quiz,
            children: {true: Text(l.gateQuizShort), false: Text(l.gateWrittenKind)},
            onValueChanged: (v) => setState(() => quiz = v ?? quiz),
          ),
        ),
        if (quiz)
          group(context, header: l.gateChoices, footer: l.gateChoicesInfo, [
            for (var i = 0; i < choices.length; i++)
              Row(
                children: [
                  CupertinoButton(
                    key: Key('gate-right-$i'),
                    padding: EdgeInsets.only(left: Tokens.space[3]),
                    minimumSize: const Size(44, 44),
                    onPressed: () => setState(() => right = i),
                    child: Icon(right == i ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: right == i ? p.accent : p.chevron, size: 24),
                  ),
                  Expanded(child: field(Key('gate-choice-$i'), choices[i], l.gateChoiceHint(i + 1), GateQuestion.choiceMax)),
                  if (choices.length > GateQuestion.choicesMin)
                    CupertinoButton(
                      key: Key('gate-choice-del-$i'),
                      padding: EdgeInsets.only(right: Tokens.space[3]),
                      minimumSize: const Size(44, 44),
                      onPressed: () => setState(() {
                        choices.removeAt(i).dispose();
                        if (right >= choices.length) right = choices.length - 1;
                        if (right > i) right--;
                      }),
                      child: const Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: 22),
                    ),
                ],
              ),
            if (choices.length < GateQuestion.choicesMax)
              IosTile(
                key: const Key('gate-choice-add'),
                leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 22),
                title: Text(l.gateAddChoice, style: TextStyle(color: p.accent)),
                onTap: () => setState(() => choices.add(TextEditingController())),
              ),
          ])
        else
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[4], vertical: Tokens.space[1]),
            child: Text(l.gateWrittenInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ),
        if (widget.initial != null)
          group(context, [
            IosTile(
              key: const Key('gate-q-remove'),
              title: Text(l.gateRemoveQuestion, style: const TextStyle(color: Palette.tileRed)),
              onTap: () => Navigator.of(context).pop(GateQuestionPage.removed),
            ),
          ]),
      ],
    );
  }
}

/// Words that get a request turned down, one per line.
class GateWordsPage extends StatefulWidget {
  const GateWordsPage({super.key, required this.initial});
  final List<String> initial;

  @override
  State<GateWordsPage> createState() => _GateWordsPageState();
}

class _GateWordsPageState extends State<GateWordsPage> {
  late final c = TextEditingController(text: widget.initial.join('\n'));

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.gateWords,
      trailing: [
        GlassDone(
          key: const Key('gate-words-done'),
          onTap: () => Navigator.of(context).pop([
            for (final w in c.text.split(RegExp(r'[\n,]')).map((w) => w.trim()).where((w) => w.isNotEmpty).toSet().take(GateSettings.wordsMax))
              w.length > 32 ? w.substring(0, 32) : w,
          ]),
        ),
      ],
      children: [
        group(context, footer: l.gateWordsInfo, [
          CupertinoTextField.borderless(
            key: const Key('gate-words-field'),
            controller: c,
            autofocus: true,
            minLines: 4,
            maxLines: 10,
            placeholder: l.gateWordsHint,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[3]),
          ),
        ]),
      ],
    );
  }
}

class GateLogPage extends StatefulWidget {
  const GateLogPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<GateLogPage> createState() => _GateLogPageState();
}

class _GateLogPageState extends State<GateLogPage> {
  List<GateEntry>? list;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final r = await AppScope.read(context).backend.gateLog(widget.roomId);
      if (mounted) setState(() => list = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    String why(String v) => switch (v) {
      'ok' => l.gateWhyOk,
      'ai' => l.gateWhyAi,
      'quiz' => l.gateWhyQuiz,
      'empty' => l.gateWhyEmpty,
      'words' => l.gateWhyWords,
      'fake' => l.gateWhyFake,
      'checking' => l.gateWhyChecking,
      _ => l.gateWhyHeld,
    };
    final now = list;
    return SettingsScaffold(
      title: l.gateLog,
      children: [
        if (now == null)
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[5]),
            child: const Center(child: CupertinoActivityIndicator()),
          )
        else if (now.isEmpty)
          Padding(
            padding: EdgeInsets.all(Tokens.space[5]),
            child: Text(
              l.gateLogNone,
              key: const Key('gate-log-empty'),
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.secondaryLabel),
            ),
          )
        else
          group(context, footer: l.gateLogInfo, [
            for (final e in now)
              IosTile(
                key: Key('gate-log-${e.userId}'),
                leadingSize: Tokens.memberAvatar,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                leading: Avatar(name: e.name, size: Tokens.memberAvatar, userId: e.userId),
                title: Text(e.name),
                subtitle: Text('${why(e.verdict)} · ${shortTime(context, e.at)}', style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                additionalInfo: Text(
                  switch (e.kind) {
                    'in' => l.gateIn,
                    'out' => l.gateOut,
                    _ => l.gateHeld,
                  },
                  style: TextStyle(
                    color: switch (e.kind) {
                      'in' => p.accent,
                      'out' => Palette.tileRed,
                      _ => Palette.tileOrange,
                    },
                  ),
                ),
              ),
          ]),
      ],
    );
  }
}

/// The person asking: questions first, then the request.
class JoinQuizPage extends StatefulWidget {
  const JoinQuizPage({super.key, required this.kind, required this.code, required this.name, required this.questions, this.channel = false});
  final String kind;
  final String code;
  final String name;
  final bool channel;
  final List<GateQuestion> questions;

  @override
  State<JoinQuizPage> createState() => _JoinQuizPageState();
}

class _JoinQuizPageState extends State<JoinQuizPage> {
  int step = 0;
  late final answers = List<String>.filled(widget.questions.length, '');
  final written = TextEditingController();

  /// Choice picked on this step and whether it was right (null = checking).
  int? picked;
  bool? right;

  /// '', 'sending', 'in', 'no', 'waiting', 'failed'.
  String result = '';
  String roomId = '';

  GateQuestion get q => widget.questions[step];

  @override
  void dispose() {
    written.dispose();
    super.dispose();
  }

  Future<void> pick(int i) async {
    if (right == true) return;
    setState(() {
      picked = i;
      right = null;
    });
    final a = List.of(answers)..[step] = '$i';
    bool? ok;
    try {
      ok = (await AppScope.read(context).backend.gateCheck(widget.kind, widget.code, a))[step];
    } catch (_) {
      ok = null;
    }
    if (!mounted || picked != i) return;
    setState(() => right = ok ?? false);
    if (ok == true) {
      answers[step] = '$i';
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) next();
    }
  }

  void next() {
    if (!q.quiz) answers[step] = written.text.trim();
    if (step + 1 < widget.questions.length) {
      setState(() {
        step++;
        picked = null;
        right = null;
        written.clear();
      });
    } else {
      send();
    }
  }

  Future<void> send() async {
    final s = AppScope.read(context);
    setState(() => result = 'sending');
    try {
      final (room, asked) = await s.backend.joinLinkWith(widget.kind, widget.code, answers);
      roomId = room;
      var state = asked ? 'waiting' : 'in';
      // The helper answers within seconds; wait a little for it.
      for (var i = 0; i < 12 && state == 'waiting'; i++) {
        await Future<void>.delayed(Duration(milliseconds: i == 0 ? 300 : 1200));
        state = await s.backend.knockState(room);
      }
      if (state == 'in') await s.refresh();
      if (mounted) setState(() => result = state == 'unknown' ? 'waiting' : state);
    } catch (_) {
      if (mounted) setState(() => result = 'failed');
    }
  }

  Future<void> open() async {
    final nav = Navigator.of(context);
    final title = widget.name;
    nav.pop();
    if (context.mounted) await openChat(context, roomId, title);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final n = widget.questions.length;
    Widget body;
    if (result.isNotEmpty) {
      final (icon, color, title, line) = switch (result) {
        'sending' => (null, p.accent, l.gateSending, ''),
        'in' => (CupertinoIcons.checkmark_circle_fill, p.accent, l.gateYoureIn, l.gateYoureInBody(widget.name)),
        'no' => (CupertinoIcons.xmark_circle_fill, Palette.tileRed, l.gateNotIn, l.gateNotInBody),
        'failed' => (CupertinoIcons.exclamationmark_circle_fill, Palette.tileRed, l.gateFailed, ''),
        _ => (CupertinoIcons.clock_fill, Palette.tileOrange, l.gateWaiting, l.gateWaitingBody),
      };
      body = Column(
        key: Key('quiz-result-$result'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon == null)
            const CupertinoActivityIndicator(radius: 16)
          else
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Icon(icon, size: 72, color: color),
            ),
          SizedBox(height: Tokens.space[3]),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Tokens.cardTitle.style.copyWith(color: p.label),
          ),
          if (line.isNotEmpty) ...[
            SizedBox(height: Tokens.nameToSub),
            Text(
              line,
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        ],
      );
    } else {
      body = ListView(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
        children: [
          SizedBox(height: Tokens.space[3]),
          Row(
            children: [
              Avatar(name: widget.name, size: Tokens.memberAvatar, squircle: true),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                    ),
                    Text(l.gateQuizIntro(n), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Tokens.space[4]),
          // Progress: one bar per question (iOS-style thin capsules).
          Row(
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(width: Tokens.space[0]),
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(color: i <= step ? p.accent : p.separator, borderRadius: BorderRadius.circular(Tokens.capsule)),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: Tokens.space[2]),
          Text(
            l.gateStep(step + 1, n),
            key: const Key('quiz-step'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
          SizedBox(height: Tokens.space[1]),
          Text(
            q.q,
            key: const Key('quiz-question'),
            style: Tokens.cardTitle.style.copyWith(color: p.label),
          ),
          SizedBox(height: Tokens.space[3]),
          if (q.quiz) ...[
            for (var i = 0; i < q.choices.length; i++) ...[
              _Choice(
                key: Key('quiz-choice-$i'),
                text: q.choices[i],
                state: picked != i ? '' : (right == null ? 'checking' : (right! ? 'right' : 'wrong')),
                onTap: () => pick(i),
              ),
              SizedBox(height: Tokens.space[1]),
            ],
            if (right == false)
              Padding(
                padding: EdgeInsets.only(top: Tokens.space[1]),
                child: Text(
                  l.gateTryAgain,
                  key: const Key('quiz-try-again'),
                  textAlign: TextAlign.center,
                  style: Tokens.preview.style.copyWith(color: Palette.tileRed),
                ),
              ),
          ] else
            Container(
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
              child: CupertinoTextField.borderless(
                key: const Key('quiz-written'),
                controller: written,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                maxLength: 300,
                placeholder: l.gateAnswerHint,
                style: Tokens.body.style.copyWith(color: p.label),
                padding: EdgeInsets.all(Tokens.space[3]),
                onChanged: (_) => setState(() {}),
              ),
            ),
          SizedBox(height: Tokens.space[3]),
          Text(l.gateAnswersSeenBy, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ],
      );
    }
    final button = switch (result) {
      'in' => (widget.channel ? l.gateGoToChannel : l.gateGoToGroup, open),
      'no' || 'waiting' || 'failed' => (l.close, () => Navigator.of(context).pop()),
      'sending' => null,
      _ when !q.quiz => (step + 1 < n ? l.next : l.gateSend, written.text.trim().isEmpty ? null : next),
      _ => null,
    };
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(child: body),
            if (button != null)
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                child: CupertinoButton.filled(
                  key: const Key('quiz-go'),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: button.$2,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      button.$1,
                      textAlign: TextAlign.center,
                      style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One quiz choice: a card row; right = accent check, wrong = red cross.
class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.text, required this.state, required this.onTap});
  final String text;

  /// '', 'checking', 'right', 'wrong'.
  final String state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final color = switch (state) {
      'right' => p.accent,
      'wrong' => Palette.tileRed,
      _ => null,
    };
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 50),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: color ?? p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: Tokens.body.style.copyWith(color: color == null ? p.label : p.onAccent)),
            ),
            switch (state) {
              'checking' => const CupertinoActivityIndicator(),
              'right' => Icon(CupertinoIcons.checkmark_alt, color: p.onAccent, size: 22),
              'wrong' => Icon(CupertinoIcons.xmark, color: p.onAccent, size: 20),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }
}
