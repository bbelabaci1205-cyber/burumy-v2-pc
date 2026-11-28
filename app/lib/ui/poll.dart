// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Polls: the maker's screen, the poll bubble, adding an answer and the
// per-answer voter list (Telegram tip 562, made our own: everything stays
// inside the encrypted chat).
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'location.dart' show GeoPoint;
import 'sticker_panel.dart' show orderedPacks;
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
  final description = TextEditingController();
  final options = [TextEditingController(), TextEditingController()];

  /// One attachment per answer row (same order as [options]).
  final attachments = <PollAttachment?>[null, null];
  final explain = TextEditingController();

  /// Photo under the question.
  PollPhoto? photo;
  bool anonymous = true;
  bool multiple = false;
  bool addOptions = false;
  bool changeVote = true;
  bool shuffle = false;
  bool hideResults = false;
  bool busy = false;
  String? error;

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
    description.dispose();
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
    try {
      await s.backend.createPoll(
        widget.roomId,
        question.text.trim(),
        [for (final o in options) o.text],
        anonymous: anonymous || widget.isChannel,
        multiple: multiple && !quiz,
        quiz: correctSent,
        explain: quiz ? explain.text.trim() : '',
        closeAt: closeIn == null ? null : DateTime.now().add(closeIn!),
        extras: PollExtras(
          description: description.text.trim(),
          photo: photo,
          addOptions: addOptions && !widget.isChannel,
          changeVote: changeVote && !quiz,
          shuffle: shuffle,
          hideResults: hideResults,
          attachments: attachments,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
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

  static Future<PollPhoto?> pickPhoto() async {
    if (debugPollPhoto != null) return debugPollPhoto!();
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    final name = x.name.toLowerCase();
    final mime = x.mimeType ?? (name.endsWith('.png') ? 'image/png' : (name.endsWith('.webp') ? 'image/webp' : 'image/jpeg'));
    return PollPhoto(mime, bytes);
  }

  Future<void> attach(int i) async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.pollAttachTitle),
        actions: [
          CupertinoActionSheetAction(key: const Key('attach-photo'), onPressed: () => Navigator.pop(c, 'photo'), child: Text(l.pollAttachPhoto)),
          CupertinoActionSheetAction(key: const Key('attach-sticker'), onPressed: () => Navigator.pop(c, 'sticker'), child: Text(l.pollAttachSticker)),
          CupertinoActionSheetAction(key: const Key('attach-place'), onPressed: () => Navigator.pop(c, 'place'), child: Text(l.pollAttachPlace)),
          if (attachments[i] != null)
            CupertinoActionSheetAction(
              key: const Key('attach-remove'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'remove'),
              child: Text(l.pollAttachRemove),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    PollAttachment? got;
    switch (pick) {
      case 'remove':
        setState(() => attachments[i] = null);
        return;
      case 'photo':
        final ph = await pickPhoto();
        if (ph != null) got = PollAttachment.photo(ph);
      case 'sticker':
        final id = await pickSticker(context);
        if (id != null) got = PollAttachment.sticker(id);
      case 'place':
        try {
          final f = await Phone.location();
          got = PollAttachment.geo('geo:${f.lat.toStringAsFixed(5)},${f.lon.toStringAsFixed(5)}');
        } catch (_) {
          if (mounted) setState(() => error = L.of(context).locationUnavailable);
        }
    }
    if (got != null && mounted) setState(() => attachments[i] = got);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final field = Tokens.body.style.copyWith(color: p.label);
    final anon = anonymous || widget.isChannel;
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
              footer: error == null ? null : sectionFooter(context, error!, error: true),
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
                CupertinoTextField.borderless(
                  key: const Key('poll-description'),
                  controller: description,
                  placeholder: l.pollDescription,
                  style: Tokens.preview.style.copyWith(color: p.label),
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 1024,
                  minLines: 1,
                  maxLines: 5,
                ),
                if (photo == null)
                  IosTile(
                    key: const Key('poll-photo'),
                    leading: Icon(CupertinoIcons.photo, color: p.accent, size: Tokens.listIcon),
                    title: Text(l.pollAddPhoto, style: Tokens.body.style.copyWith(color: p.accent)),
                    onTap: () async {
                      final ph = await pickPhoto();
                      if (ph != null && mounted) setState(() => photo = ph);
                    },
                  )
                else
                  Padding(
                    padding: EdgeInsets.all(Tokens.space[2]),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(Tokens.radius[1]),
                          child: Image.memory(Uint8List.fromList(photo!.bytes), key: const Key('poll-photo-thumb'), width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const Spacer(),
                        CupertinoButton(
                          key: const Key('poll-photo-remove'),
                          padding: EdgeInsets.zero,
                          onPressed: () => setState(() => photo = null),
                          child: Text(l.pollRemovePhoto, style: Tokens.body.style.copyWith(color: Palette.tileRed)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            IosSection(
              header: sectionHeader(context, l.pollOptions),
              footer: sectionFooter(context, l.pollAttachInfo),
              children: [
                for (var i = 0; i < options.length; i++)
                  CupertinoTextField.borderless(
                    key: Key('poll-option-$i'),
                    controller: options[i],
                    placeholder: l.pollOption,
                    style: field,
                    padding: EdgeInsets.all(Tokens.space[2]),
                    prefix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quiz)
                          GestureDetector(
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
                          ),
                        if (attachments[i] != null)
                          Padding(
                            padding: EdgeInsets.only(left: Tokens.space[2]),
                            child: AttachmentThumb(key: Key('poll-att-$i'), att: attachments[i]!, size: 30),
                          ),
                      ],
                    ),
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    suffix: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          key: Key('poll-attach-$i'),
                          padding: EdgeInsets.only(right: Tokens.space[1]),
                          minimumSize: const Size(32, 32),
                          onPressed: () => attach(i),
                          child: Icon(CupertinoIcons.paperclip, color: attachments[i] == null ? p.secondaryLabel : p.accent, size: Tokens.listIcon),
                        ),
                        if (options.length > 2)
                          CupertinoButton(
                            padding: EdgeInsets.only(right: Tokens.space[1]),
                            minimumSize: const Size(32, 32),
                            onPressed: () => setState(() {
                              options.removeAt(i).dispose();
                              attachments.removeAt(i);
                              if (correct == i) {
                                correct = null;
                              } else if (correct != null && correct! > i) {
                                correct = correct! - 1;
                              }
                            }),
                            child: Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: Tokens.listIcon),
                          ),
                      ],
                    ),
                  ),
                if (options.length < maxOptions)
                  IosTile(
                    key: const Key('poll-add'),
                    leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent),
                    title: Text(l.pollAddOption, style: Tokens.body.style.copyWith(color: p.accent)),
                    onTap: () => setState(() {
                      options.add(TextEditingController());
                      attachments.add(null);
                    }),
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
                    value: anon,
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
              footer: sectionFooter(
                context,
                [l.pollMoreInfo, if (hideResults) anon ? l.pollHideAnonInfo : l.pollHideOpenInfo, if (!changeVote || quiz) l.pollNoChangeInfo].join('\n\n'),
              ),
              children: [
                if (!widget.isChannel)
                  IosTile(
                    title: Text(l.pollAllowAdd),
                    trailing: IosSwitch(
                      key: const Key('poll-allow-add'),
                      value: addOptions,
                      activeTrackColor: p.accent,
                      onChanged: (v) => setState(() => addOptions = v),
                    ),
                  ),
                IosTile(
                  title: Text(l.pollAllowChange),
                  trailing: IosSwitch(
                    key: const Key('poll-allow-change'),
                    value: changeVote && !quiz,
                    activeTrackColor: p.accent,
                    onChanged: quiz ? null : (v) => setState(() => changeVote = v),
                  ),
                ),
                IosTile(
                  title: Text(l.pollShuffle),
                  trailing: IosSwitch(
                    key: const Key('poll-shuffle'),
                    value: shuffle,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => shuffle = v),
                  ),
                ),
                IosTile(
                  title: Text(l.pollHideResults),
                  trailing: IosSwitch(
                    key: const Key('poll-hide'),
                    value: hideResults,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => hideResults = v),
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

/// Test hook: a picked photo without the phone's picker.
Future<PollPhoto?> Function()? debugPollPhoto;

/// Sticker grid for an answer (our own packs; nothing leaves the phone).
Future<String?> pickSticker(BuildContext context) {
  final l = L.of(context);
  final s = AppScope.read(context);
  final ids = [for (final pack in orderedPacks(s)) ...pack.items];
  return showCupertinoModalPopup<String>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) {
      final p = paletteOf(c);
      return Container(
        key: const Key('sticker-pick'),
        height: MediaQuery.sizeOf(c).height * 0.6,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[3])),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              SizedBox(
                height: Tokens.topBar,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(l.pollPickSticker, style: Tokens.navTitle.style.copyWith(color: p.label)),
                    Positioned(
                      right: Tokens.space[2],
                      child: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 5,
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  children: [
                    for (final id in ids)
                      GestureDetector(
                        key: Key('pick-$id'),
                        onTap: () => Navigator.pop(c, id),
                        child: Padding(padding: EdgeInsets.all(Tokens.space[0]), child: Image.asset(stickerAsset(id)!)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Small picture of an answer's attachment while writing the poll.
class AttachmentThumb extends StatelessWidget {
  const AttachmentThumb({super.key, required this.att, this.size = 30});
  final PollAttachment att;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    if (att.photo != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[0]),
        child: Image.memory(Uint8List.fromList(att.photo!.bytes), width: size, height: size, fit: BoxFit.cover),
      );
    }
    if (att.sticker != null && stickerAsset(att.sticker!) != null) return Image.asset(stickerAsset(att.sticker!)!, width: size, height: size);
    return SizedBox(
      width: size,
      height: size,
      child: Icon(CupertinoIcons.location_solid, color: p.accent, size: size * 0.7),
    );
  }
}

/// The poll inside a chat: tap to vote; after voting (or once closed) the
/// numbers show as bars, with a check on my choice. Hidden-result polls keep
/// the numbers covered until the end.
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

  Future<void> addAnswer() async {
    final added = await Navigator.of(context).push<bool>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddPollOptionPage(roomId: widget.roomId, pollId: widget.msg.id),
      ),
    );
    if (added == true) await widget.onChanged();
  }

  void openResults() => Navigator.of(context).push(
    CupertinoPageRoute(
      builder: (_) => PollResultsPage(roomId: widget.roomId, msg: widget.msg),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final poll = widget.msg.poll!;
    final fg = widget.fg;
    final accent = widget.msg.mine ? p.onAccent : p.accent;
    final now = DateTime.now();
    final closed = poll.closedAt(now);
    // Hidden numbers: members see their own choice, never the results
    // (a quiz still shows right and wrong). Hidden-until-end polls show
    // nothing before the end.
    final showResults = poll.resultsOpen(now) && (!widget.hideCounts || poll.isQuiz);
    final waiting = poll.hideResults && !closed;
    final total = poll.options.fold<int>(0, (n, o) => n + o.votes);
    final kind = closed ? l.pollClosedKind : (poll.isQuiz ? l.pollQuizKind : (poll.anonymous ? l.pollAnonKind : l.pollOpenKind));
    final left = closed || poll.closeAt == null ? null : poll.closeAt!.difference(now);
    final leftText = left == null
        ? null
        : (left.inDays >= 1 ? l.pollLeftDays(left.inDays) : (left.inHours >= 1 ? l.pollLeftHours(left.inHours) : l.pollLeftMin(left.inMinutes + 1)));
    final order = poll.orderFor(widget.msg.id, s.backend.userId ?? '');
    final canAdd = poll.addOptions && !closed && poll.options.length < 12;
    final canSeeWho = !poll.anonymous && showResults && !widget.hideCounts && poll.voters > 0;
    final sub = fg.withValues(alpha: 0.65);
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
          if (poll.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                poll.description,
                key: const Key('poll-desc'),
                style: Tokens.preview.style.copyWith(color: fg.withValues(alpha: 0.85)),
              ),
            ),
          if (poll.hasPhoto)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[1]),
              child: PollPhotoView(key: const Key('poll-desc-photo'), roomId: widget.roomId, pollId: widget.msg.id, slot: '', width: 260, height: 160),
            ),
          SizedBox(height: poll.hasPhoto ? Tokens.space[0] : 2),
          Text(
            [kind, if (poll.multiple && !closed) l.pollMultipleShort, if (!poll.changeVote && !poll.isQuiz && !closed) l.pollFinalShort, ?leftText].join(' · '),
            style: Tokens.caption.style.copyWith(color: sub),
          ),
          SizedBox(height: Tokens.space[1]),
          for (final o in order)
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
                        roomId: widget.roomId,
                        pollId: widget.msg.id,
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
                          if (_hasAttachment(o)) ...[
                            OptionAttachment(roomId: widget.roomId, pollId: widget.msg.id, option: o, fg: fg),
                            SizedBox(width: Tokens.space[1]),
                          ],
                          Expanded(
                            child: _OptionText(option: o, fg: fg),
                          ),
                        ],
                      ),
              ),
            ),
          if (canAdd)
            GestureDetector(
              key: const Key('poll-add-answer'),
              behavior: HitTestBehavior.opaque,
              onTap: addAnswer,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Tokens.space[0] + 1),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add_circled, size: 22, color: accent),
                    SizedBox(width: Tokens.space[1]),
                    Text(l.pollAddOption, style: Tokens.body.style.copyWith(color: accent)),
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
          if (canSeeWho)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[0]),
              child: GestureDetector(
                key: const Key('poll-view-votes'),
                onTap: openResults,
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: fg.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Text(l.pollViewVotes, style: Tokens.preview.style.copyWith(color: accent)),
                ),
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
                        waiting
                            ? l.pollHiddenUntilEnd
                            : widget.hideCounts
                            ? (poll.mine.isNotEmpty ? l.pollVoted : '')
                            : (poll.voters == 0 ? l.pollNoVotes : l.pollVoters(poll.voters)),
                        key: const Key('poll-voters'),
                        style: Tokens.caption.style.copyWith(color: sub),
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

bool _hasAttachment(PollOption o) => o.hasPhoto || o.sticker.isNotEmpty || o.geo.isNotEmpty;

/// An answer's words, with "추가: name" under answers members added.
class _OptionText extends StatelessWidget {
  const _OptionText({required this.option, required this.fg});
  final PollOption option;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(option.text, style: Tokens.body.style.copyWith(color: fg)),
        if (option.addedBy.isNotEmpty)
          Text(
            l.pollAddedBy(displayId(option.addedBy)),
            key: Key('added-by-${option.id}'),
            style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.55)),
          ),
      ],
    );
  }
}

/// An answer's photo, sticker or place inside the bubble. Photo: tap to see
/// it big; place: tap to open the phone's own Maps app.
class OptionAttachment extends StatelessWidget {
  const OptionAttachment({super.key, required this.roomId, required this.pollId, required this.option, required this.fg, this.size = 32});
  final String roomId;
  final String pollId;
  final PollOption option;
  final Color fg;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (option.hasPhoto) {
      return PollPhotoView(key: Key('opt-photo-${option.id}'), roomId: roomId, pollId: pollId, slot: option.id, width: size, height: size, small: true);
    }
    if (option.sticker.isNotEmpty && stickerAsset(option.sticker) != null) {
      return Image.asset(stickerAsset(option.sticker)!, key: Key('opt-sticker-${option.id}'), width: size, height: size);
    }
    final g = GeoPoint.parse(option.geo);
    if (g == null) return SizedBox(width: size, height: size);
    return GestureDetector(
      key: Key('opt-place-${option.id}'),
      onTap: () => launchUrl(g.mapsUri, mode: LaunchMode.externalApplication),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[0])),
        child: Icon(CupertinoIcons.location_solid, size: size * 0.6, color: fg),
      ),
    );
  }
}

/// A poll photo, decrypted on this phone. Tap = full screen.
class PollPhotoView extends StatefulWidget {
  const PollPhotoView({
    super.key,
    required this.roomId,
    required this.pollId,
    required this.slot,
    required this.width,
    required this.height,
    this.small = false,
  });
  final String roomId;
  final String pollId;
  final String slot;
  final double width;
  final double height;
  final bool small;

  @override
  State<PollPhotoView> createState() => _PollPhotoViewState();
}

class _PollPhotoViewState extends State<PollPhotoView> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bytes ??= AppScope.read(context).backend.pollPhoto(widget.roomId, widget.pollId, widget.slot);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final r = BorderRadius.circular(widget.small ? Tokens.radius[0] : Tokens.radius[2]);
    return FutureBuilder<List<int>>(
      future: bytes,
      builder: (c, snap) {
        final data = snap.data;
        if (data == null || data.isEmpty) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.15), borderRadius: r),
            alignment: Alignment.center,
            child: snap.connectionState == ConnectionState.done ? null : const CupertinoActivityIndicator(radius: 8),
          );
        }
        final raw = Uint8List.fromList(data);
        return GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            PageRouteBuilder(
              opaque: false,
              barrierColor: const Color(0xF0000000),
              pageBuilder: (_, _, _) => _PhotoFull(raw),
              transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
            ),
          ),
          child: ClipRRect(
            borderRadius: r,
            child: Image.memory(raw, width: widget.width, height: widget.height, fit: BoxFit.cover, gaplessPlayback: true),
          ),
        );
      },
    );
  }
}

class _PhotoFull extends StatelessWidget {
  const _PhotoFull(this.raw);
  final Uint8List raw;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: const Key('poll-photo-full'),
    onTap: () => Navigator.pop(context),
    child: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(child: Center(child: Image.memory(raw))),
          ),
          Positioned(top: Tokens.space[1], left: Tokens.space[2], child: const GlassBack(close: true)),
        ],
      ),
    ),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.roomId,
    required this.pollId,
    required this.option,
    required this.share,
    required this.chosen,
    required this.fg,
    required this.accent,
    this.hideNumber = false,
    this.right,
  });
  final String roomId;
  final String pollId;
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
            if (_hasAttachment(option)) ...[
              OptionAttachment(roomId: roomId, pollId: pollId, option: option, fg: fg, size: 28),
              SizedBox(width: Tokens.space[1]),
            ],
            Expanded(
              child: _OptionText(option: option, fg: fg),
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

/// Full-screen "add an answer" (no popup text boxes, project rule).
class AddPollOptionPage extends StatefulWidget {
  const AddPollOptionPage({super.key, required this.roomId, required this.pollId});
  final String roomId;
  final String pollId;

  @override
  State<AddPollOptionPage> createState() => _AddPollOptionPageState();
}

class _AddPollOptionPageState extends State<AddPollOptionPage> {
  final text = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> add() async {
    final t = text.text.trim();
    if (t.isEmpty || busy) return;
    final l = L.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.of(context).backend.addPollOption(widget.roomId, widget.pollId, t);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final m = '$e';
      if (mounted) {
        setState(() => error = m.contains('full') ? l.pollFull : (m.contains('repeat') || m.contains('already') ? l.pollRepeat : l.pollClosedKind));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.pollAddTitle),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        trailing: CupertinoButton(
          key: const Key('poll-add-done'),
          padding: EdgeInsets.zero,
          onPressed: text.text.trim().isEmpty || busy ? null : add,
          child: Text(l.pollAddDone),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              footer: sectionFooter(context, error ?? l.pollAddInfo, error: error != null),
              children: [
                CupertinoTextField.borderless(
                  key: const Key('poll-add-text'),
                  controller: text,
                  autofocus: true,
                  placeholder: l.pollOption,
                  style: Tokens.body.style.copyWith(color: p.label),
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => add(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "투표 결과": every answer with the people who chose it (open polls only;
/// in anonymous polls nobody, not even the maker, gets names).
class PollResultsPage extends StatefulWidget {
  const PollResultsPage({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  State<PollResultsPage> createState() => _PollResultsPageState();
}

class _PollResultsPageState extends State<PollResultsPage> {
  Map<String, String> names = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await AppScope.read(context).backend.members(widget.roomId);
      if (mounted) setState(() => names = {for (final m in list) m.userId: m.name});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final poll = widget.msg.poll!;
    final total = poll.options.fold<int>(0, (n, o) => n + o.votes);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.pollResults), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          key: const Key('poll-results'),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
              child: Text(poll.question, style: Tokens.cardTitle.style.copyWith(color: p.label)),
            ),
            if (poll.anonymous)
              Padding(
                padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[1], IosSection.sideMargin, 0),
                child: Text(l.pollAnonResultsInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ),
            for (final o in poll.options)
              IosSection(
                header: Row(
                  children: [
                    if (_hasAttachment(o)) ...[
                      OptionAttachment(roomId: widget.roomId, pollId: widget.msg.id, option: o, fg: p.label, size: 22),
                      SizedBox(width: Tokens.space[1]),
                    ],
                    Expanded(child: sectionHeader(context, o.text)),
                    sectionHeader(context, '${l.pollVotesN(o.votes)} · ${total == 0 ? 0 : (o.votes * 100 / total).round()}%'),
                  ],
                ),
                children: [
                  if (o.who.isEmpty)
                    IosTile(
                      title: Text(poll.anonymous ? l.pollAnonKind : l.pollNobodyYet, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                    )
                  else
                    for (final u in o.who)
                      IosTile(
                        key: Key('voter-${o.id}-$u'),
                        leading: Avatar(name: names[u] ?? displayId(u), userId: u, size: 32),
                        title: Text(names[u] ?? displayId(u)),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
