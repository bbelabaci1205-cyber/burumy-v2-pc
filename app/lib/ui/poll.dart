// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Polls: the maker's screen and the poll bubble.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key, required this.roomId, required this.isChannel});
  final String roomId;
  final bool isChannel;

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final question = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];
  final explain = TextEditingController();
  bool anonymous = true;
  bool multiple = false;
  bool busy = false;

  /// Quiz mode and the right answer's row.
  bool quiz = false;
  int? correct;

  /// Deadline from now (null = none).
  Duration? closeIn;

  static const maxOptions = 10;

  bool get ready =>
      question.text.trim().isNotEmpty &&
      options.where((o) => o.text.trim().isNotEmpty).length >= 2 &&
      (!quiz || (correct != null && options[correct!].text.trim().isNotEmpty));

  /// The right answer's index among the options that will be sent.
  int? get correctSent {
    if (!quiz || correct == null) return null;
    var n = 0;
    for (var i = 0; i < correct!; i++) {
      if (options[i].text.trim().isNotEmpty) n++;
    }
    return n;
  }

  @override
  void dispose() {
    question.dispose();
    explain.dispose();
    for (final o in options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> create() async {
    if (!ready || busy) return;
    setState(() => busy = true);
    final s = AppScope.of(context);
    await s.backend.createPoll(
      widget.roomId,
      question.text.trim(),
      [for (final o in options) o.text],
      anonymous: anonymous || widget.isChannel,
      multiple: multiple && !quiz,
      quiz: correctSent,
      explain: quiz ? explain.text.trim() : '',
      closeAt: closeIn == null ? null : DateTime.now().add(closeIn!),
    );
    if (mounted) Navigator.pop(context, true);
  }

  static const deadlines = [null, Duration(hours: 1), Duration(days: 1), Duration(days: 3), Duration(days: 7)];

  static String deadlineLabel(L l, Duration? d) => switch (d?.inHours) {
    null => l.pollDeadlineNone,
    1 => l.pollIn1h,
    24 => l.pollIn1d,
    72 => l.pollIn3d,
    _ => l.pollIn1w,
  };

  Future<void> pickDeadline() async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<int>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.pollDeadline),
        actions: [
          for (var i = 0; i < deadlines.length; i++)
            CupertinoActionSheetAction(
              key: Key('deadline-$i'),
              isDefaultAction: deadlines[i] == closeIn,
              onPressed: () => Navigator.pop(c, i),
              child: Text(deadlineLabel(l, deadlines[i])),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick != null) setState(() => closeIn = deadlines[pick]);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final field = Tokens.body.style.copyWith(color: p.label);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.newPoll),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        trailing: CupertinoButton(
          key: const Key('poll-create'),
          padding: EdgeInsets.zero,
          onPressed: ready && !busy ? create : null,
          child: Text(l.pollCreate),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              header: sectionHeader(context, l.pollQuestion),
              children: [
                CupertinoTextField.borderless(
                  key: const Key('poll-question'),
                  controller: question,
                  placeholder: l.pollQuestion,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 255,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            IosSection(
              header: sectionHeader(context, l.pollOptions),
              children: [
                for (var i = 0; i < options.length; i++)
                  CupertinoTextField.borderless(
                    key: Key('poll-option-$i'),
                    controller: options[i],
                    placeholder: l.pollOption,
                    style: field,
                    padding: EdgeInsets.all(Tokens.space[2]),
                    prefix: quiz
                        ? GestureDetector(
                            key: Key('quiz-correct-$i'),
                            onTap: () => setState(() => correct = i),
                            child: Padding(
                              padding: EdgeInsets.only(left: Tokens.space[2]),
                              child: Icon(
                                correct == i ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                color: correct == i ? p.tileGreen : p.secondaryLabel,
                                size: 22,
                              ),
                            ),
                          )
                        : null,
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    suffix: options.length > 2
                        ? CupertinoButton(
                            padding: EdgeInsets.only(right: Tokens.space[1]),
                            minimumSize: const Size(32, 32),
                            onPressed: () => setState(() {
                              options.removeAt(i).dispose();
                              if (correct == i) {
                                correct = null;
                              } else if (correct != null && correct! > i) {
                                correct = correct! - 1;
                              }
                            }),
                            child: Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: Tokens.listIcon),
                          )
                        : null,
                  ),
                if (options.length < maxOptions)
                  IosTile(
                    key: const Key('poll-add'),
                    leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent),
                    title: Text(l.pollAddOption, style: Tokens.body.style.copyWith(color: p.accent)),
                    onTap: () => setState(() => options.add(TextEditingController())),
                  ),
              ],
            ),
            IosSection(
              footer: sectionFooter(context, widget.isChannel ? l.pollChannelInfo : (anonymous ? l.pollAnonInfo : l.pollOpenInfo)),
              children: [
                IosTile(
                  title: Text(l.pollAnonymous),
                  trailing: IosSwitch(
                    key: const Key('poll-anonymous'),
                    value: anonymous || widget.isChannel,
                    activeTrackColor: p.accent,
                    onChanged: widget.isChannel ? null : (v) => setState(() => anonymous = v),
                  ),
                ),
                IosTile(
                  title: Text(l.pollMultiple),
                  trailing: IosSwitch(
                    key: const Key('poll-multiple'),
                    value: multiple && !quiz,
                    activeTrackColor: p.accent,
                    onChanged: quiz ? null : (v) => setState(() => multiple = v),
                  ),
                ),
              ],
            ),
            IosSection(
              footer: sectionFooter(context, quiz && correct == null ? l.quizPickAnswer : l.quizModeInfo),
              children: [
                IosTile(
                  title: Text(l.quizMode),
                  trailing: IosSwitch(key: const Key('poll-quiz'), value: quiz, activeTrackColor: p.accent, onChanged: (v) => setState(() => quiz = v)),
                ),
                if (quiz)
                  CupertinoTextField.borderless(
                    key: const Key('quiz-explain'),
                    controller: explain,
                    placeholder: l.quizExplain,
                    style: field,
                    maxLength: 200,
                    minLines: 1,
                    maxLines: 4,
                    padding: EdgeInsets.all(Tokens.space[2]),
                  ),
              ],
            ),
            IosSection(
              footer: sectionFooter(context, l.pollDeadlineInfo),
              children: [
                IosTile(
                  key: const Key('poll-deadline'),
                  title: Text(l.pollDeadline),
                  additionalInfo: Text(deadlineLabel(l, closeIn)),
                  trailing: const IosChevron(),
                  onTap: pickDeadline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The poll inside a chat: tap to vote; after voting (or once closed) the
/// numbers show as bars, with a check on my choice.
class PollBubble extends StatefulWidget {
  const PollBubble({
    super.key,
    required this.roomId,
    required this.msg,
    required this.fg,
    required this.meta,
    required this.onChanged,
    this.hideCounts = false,
  });

  /// The room hides numbers from members (admin tools).
  final bool hideCounts;
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final Future<void> Function() onChanged;

  @override
  State<PollBubble> createState() => _PollBubbleState();
}

class _PollBubbleState extends State<PollBubble> {
  final picked = <String>{};
  bool busy = false;

  Future<void> send(List<String> choices) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend.vote(widget.roomId, widget.msg.id, choices);
      picked.clear();
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final poll = widget.msg.poll!;
    final fg = widget.fg;
    final accent = widget.msg.mine ? p.onAccent : p.accent;
    final closed = poll.closedAt(DateTime.now());
    // Hidden numbers: members see their own choice, never the results
    // (a quiz still shows right and wrong).
    final showResults = (poll.mine.isNotEmpty || closed) && (!widget.hideCounts || poll.isQuiz);
    final total = poll.options.fold<int>(0, (n, o) => n + o.votes);
    final kind = closed ? l.pollClosedKind : (poll.isQuiz ? l.pollQuizKind : (poll.anonymous ? l.pollAnonKind : l.pollOpenKind));
    final left = closed || poll.closeAt == null ? null : poll.closeAt!.difference(DateTime.now());
    final leftText = left == null
        ? null
        : (left.inDays >= 1 ? l.pollLeftDays(left.inDays) : (left.inHours >= 1 ? l.pollLeftHours(left.inHours) : l.pollLeftMin(left.inMinutes + 1)));
    return SizedBox(
      key: const Key('poll'),
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            poll.question,
            style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            [kind, if (poll.multiple && !closed) l.pollMultipleShort, ?leftText].join(' · '),
            style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.65)),
          ),
          SizedBox(height: Tokens.space[1]),
          for (final o in poll.options)
            GestureDetector(
              key: Key('poll-${o.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: showResults || busy || poll.mine.isNotEmpty || closed
                  ? null
                  : () {
                      if (!poll.multiple) {
                        send([o.id]);
                      } else {
                        setState(() => picked.contains(o.id) ? picked.remove(o.id) : picked.add(o.id));
                      }
                    },
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Tokens.space[0] + 1),
                child: showResults
                    ? _ResultRow(
                        option: o,
                        share: total == 0 ? 0 : o.votes / total,
                        chosen: poll.mine.contains(o.id),
                        fg: fg,
                        accent: accent,
                        hideNumber: widget.hideCounts,
                        right: poll.isQuiz ? o.id == poll.correct : null,
                      )
                    : Row(
                        children: [
                          Icon(
                            picked.contains(o.id) || poll.mine.contains(o.id)
                                ? CupertinoIcons.checkmark_circle_fill
                                : (poll.multiple ? CupertinoIcons.square : CupertinoIcons.circle),
                            size: 22,
                            color: picked.contains(o.id) || poll.mine.contains(o.id) ? accent : fg.withValues(alpha: 0.45),
                          ),
                          SizedBox(width: Tokens.space[1]),
                          Expanded(
                            child: Text(o.text, style: Tokens.body.style.copyWith(color: fg)),
                          ),
                        ],
                      ),
              ),
            ),
          if (poll.isQuiz && showResults && poll.mine.isNotEmpty)
            Padding(
              key: const Key('quiz-result'),
              padding: EdgeInsets.only(top: Tokens.space[0]),
              child: Text(
                [poll.mine.contains(poll.correct) ? l.quizRight : l.quizWrong, if (poll.explain.isNotEmpty) poll.explain].join('\n'),
                style: Tokens.caption.style.copyWith(color: fg),
              ),
            ),
          SizedBox(height: Tokens.space[0]),
          Row(
            children: [
              Expanded(
                child: poll.multiple && !showResults && picked.isNotEmpty
                    ? CupertinoButton(
                        key: const Key('poll-vote'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        alignment: Alignment.centerLeft,
                        onPressed: busy ? null : () => send(picked.toList()),
                        child: Text(l.pollVote, style: Tokens.preview.style.copyWith(color: accent)),
                      )
                    : Text(
                        widget.hideCounts ? (poll.mine.isNotEmpty ? l.pollVoted : '') : (poll.voters == 0 ? l.pollNoVotes : l.pollVoters(poll.voters)),
                        key: const Key('poll-voters'),
                        style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.65)),
                      ),
              ),
              widget.meta,
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.option,
    required this.share,
    required this.chosen,
    required this.fg,
    required this.accent,
    this.hideNumber = false,
    this.right,
  });
  final bool hideNumber;

  /// Quiz: true = the right answer, false = a wrong one, null = not a quiz.
  final bool? right;
  final PollOption option;
  final double share;
  final bool chosen;
  final Color fg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pct = (share * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                hideNumber ? '' : '$pct%',
                style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(option.text, style: Tokens.body.style.copyWith(color: fg)),
            ),
            if (right == true)
              Icon(CupertinoIcons.checkmark_alt_circle_fill, key: const Key('quiz-right'), size: 18, color: paletteOf(context).accent)
            else if (right == false && chosen)
              const Icon(CupertinoIcons.xmark_circle_fill, key: Key('quiz-wrong'), size: 18, color: Palette.tileRed)
            else if (chosen)
              Icon(CupertinoIcons.checkmark_alt_circle_fill, key: const Key('poll-mine'), size: 18, color: accent),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: LayoutBuilder(
            builder: (c, box) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  height: 4,
                  width: (box.maxWidth * share).clamp(4.0, box.maxWidth),
                  decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
