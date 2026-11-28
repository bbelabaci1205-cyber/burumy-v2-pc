// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// AI 친구 (core/ai_friend.dart): its row in the chat list and its chat.
// Layout follows our chat screen (glass title capsule, Telegram-size
// bubbles and composer); the lock line says the talk stays on the phone.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../brand/mark.dart';
import '../core/ai_friend.dart';
import '../core/ai_local.dart';
import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show ForwardPickPage;
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'wide.dart';

Future<void> openAiFriend(BuildContext context, {String ask = ''}) => paneNav(context).push(IosPageRoute<void>(builder: (_) => AiFriendPage(ask: ask)));

/// The round face: our mark on a soft accent gradient.
class AiFriendFace extends StatelessWidget {
  const AiFriendFace({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accent.withValues(alpha: 0.75), Palette.tileIndigo]),
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BurumyMark(size: size * 0.5, color: const Color(0xFFFFFFFF)),
          Positioned(
            right: size * 0.16,
            top: size * 0.14,
            child: Icon(CupertinoIcons.sparkles, size: size * 0.24, color: const Color(0xFFFFFFFF)),
          ),
        ],
      ),
    );
  }
}

/// The chat list row (under 저장한 메시지). Hold: 대화 지우기 / 목록에서 빼기.
class AiFriendRow extends StatelessWidget {
  const AiFriendRow({super.key});

  Future<void> hold(BuildContext context) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    unawaited(HapticFeedback.mediumImpact());
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => CupertinoActionSheet(
        title: Text(l.aiFriendName),
        actions: [
          CupertinoActionSheetAction(key: const Key('ai-friend-clear'), onPressed: () => Navigator.pop(c, 'clear'), child: Text(l.aiFriendClear)),
          CupertinoActionSheetAction(
            key: const Key('ai-friend-hide'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'hide'),
            child: Text(l.aiFriendHide),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == 'clear') {
      await AiFriend.clear(s);
    } else if (pick == 'hide') {
      await s.setOn(AiFriend.pref, false);
      if (context.mounted) showInfoBanner(context, l.aiFriendName, l.aiFriendHidden, icon: CupertinoIcons.sparkles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final last = AiFriend.log(s).lastOrNull;
    return GestureDetector(
      key: const Key('ai-friend-row'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openAiFriend(context),
      onLongPress: () => hold(context),
      child: Container(
        height: Tokens.chatRow,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            AiFriendFace(size: Tokens.chatAvatar),
            SizedBox(width: Tokens.space[2]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(l.aiFriendName, maxLines: 1, style: Tokens.listName.style.copyWith(color: p.label)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(CupertinoIcons.lock_fill, size: 13, color: p.secondaryLabel),
                      ),
                      const Spacer(),
                      if (last != null) Text(shortTime(context, last.at), style: Tokens.listDate.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  SizedBox(
                    height: Tokens.preview.lineHeight * 2,
                    child: Text(
                      last == null ? l.aiFriendPreview : last.text.replaceAll('\n', ' '),
                      key: const Key('ai-friend-preview'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiFriendPage extends StatefulWidget {
  const AiFriendPage({super.key, this.ask = ''});

  /// Words to put in the box (통합 검색's "AI 친구에게 묻기").
  final String ask;

  @override
  State<AiFriendPage> createState() => _AiFriendPageState();
}

class _AiFriendPageState extends State<AiFriendPage> {
  late final input = TextEditingController(text: widget.ask);
  final scroll = ScrollController();
  bool thinking = false;
  bool failed = false;
  bool? ok;

  @override
  void initState() {
    super.initState();
    input.addListener(() => setState(() {}));
    unawaited(LocalAi.available().then((v) => mounted ? setState(() => ok = v) : null));
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send([String? words]) async {
    final t = (words ?? input.text).trim();
    if (t.isEmpty || thinking) return;
    final s = AppScope.read(context);
    final ko = Localizations.localeOf(context).languageCode != 'en';
    input.clear();
    setState(() {
      thinking = true;
      failed = false;
    });
    try {
      await AiFriend.ask(s, t, korean: ko);
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => thinking = false);
  }

  Future<void> holdLine(AiLine line) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(key: const Key('ai-line-copy'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.aiFriendCopy)),
          CupertinoActionSheetAction(key: const Key('ai-line-send'), onPressed: () => Navigator.pop(c, 'send'), child: Text(l.aiFriendShare)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted) return;
    if (pick == 'copy') {
      await Clipboard.setData(ClipboardData(text: line.text));
      if (mounted) showInfoBanner(context, l.aiFriendCopied, '', icon: CupertinoIcons.doc_on_doc_fill);
    } else if (pick == 'send') {
      // Only the words I pick go to a chat, like any message I write.
      final to = await openSheet<String>(context, (_) => const ForwardPickPage());
      if (to == null) return;
      try {
        await s.backend.sendText(to, line.text);
        if (mounted) showInfoBanner(context, l.forwarded, '', icon: CupertinoIcons.arrowshape_turn_up_right_fill);
      } catch (_) {}
    }
  }

  Future<void> more() async {
    final s = AppScope.read(context);
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            key: const Key('ai-friend-clear'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'clear'),
            child: Text(l.aiFriendClear),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == 'clear') {
      await AiFriend.clear(s);
      if (mounted) showInfoBanner(context, l.aiFriendName, l.aiFriendCleared, icon: CupertinoIcons.sparkles);
    }
  }

  Widget bubble(Palette p, AiLine line, {Key? key}) => Align(
    key: key,
    alignment: line.mine ? Alignment.centerRight : Alignment.centerLeft,
    child: GestureDetector(
      onLongPress: line.mine ? null : () => holdLine(line),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: EdgeInsets.symmetric(vertical: Tokens.space[0]),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + 2, vertical: Tokens.space[1] + 1),
        decoration: BoxDecoration(color: line.mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(18)),
        child: Text(line.text, style: Tokens.body.style.copyWith(color: line.mine ? p.onAccent : p.label)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final lines = AiFriend.log(s);
    final hello = AiLine(mine: false, text: l.aiFriendHello, at: DateTime.now());
    final shown = [hello, ...lines];
    final pad = MediaQuery.paddingOf(context);
    final ideas = [l.aiFriendIdea1, l.aiFriendIdea2, l.aiFriendIdea3, l.aiFriendIdea4];
    return CupertinoPageScaffold(
      key: const Key('ai-friend-page'),
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: LiquidGlass(
          radius: Tokens.capsule,
          child: Container(
            height: Tokens.closeButton,
            constraints: const BoxConstraints(minWidth: Tokens.titlePillMin),
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.aiFriendName, style: Tokens.navTitle.style.copyWith(color: p.label)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.lock_fill, size: 10, color: p.secondaryLabel),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        l.aiFriendLock,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.bubbleMeta.style.copyWith(color: p.secondaryLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        trailing: GlassCircle(key: const Key('ai-friend-more'), onTap: more, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('ai-friend-list'),
              controller: scroll,
              reverse: true,
              padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[2], Tokens.space[2], pad.top + GlassTopBar.height + Tokens.space[2]),
              children: [
                if (ok == false)
                  Padding(
                    key: const Key('ai-friend-no-ai'),
                    padding: EdgeInsets.all(Tokens.space[3]),
                    child: Text(
                      l.aiFriendNoAi,
                      textAlign: TextAlign.center,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                if (failed)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                    child: Text(
                      l.aiFriendFailed,
                      key: const Key('ai-friend-failed'),
                      textAlign: TextAlign.center,
                      style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                    ),
                  ),
                if (thinking)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      key: const Key('ai-friend-thinking'),
                      margin: EdgeInsets.symmetric(vertical: Tokens.space[0]),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 1),
                      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(18)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CupertinoActivityIndicator(radius: 7),
                          SizedBox(width: Tokens.space[1]),
                          Text(l.aiFriendThinking, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                        ],
                      ),
                    ),
                  ),
                // Ideas to start with, while nothing was said yet.
                if (lines.isEmpty && ok != false)
                  Padding(
                    padding: EdgeInsets.only(top: Tokens.space[2]),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: Tokens.space[1],
                      runSpacing: Tokens.space[1],
                      children: [
                        for (final (i, idea) in ideas.indexed)
                          GestureDetector(
                            key: Key('ai-idea-$i'),
                            onTap: () => send(idea),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                              decoration: BoxDecoration(
                                color: p.card,
                                borderRadius: BorderRadius.circular(Tokens.capsule),
                                border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                              ),
                              child: Text(idea, style: Tokens.preview.style.copyWith(color: p.accent)),
                            ),
                          ),
                      ],
                    ),
                  ),
                for (final (i, line) in shown.indexed.toList().reversed) bubble(p, line, key: Key('ai-line-$i')),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                  child: Column(
                    children: [
                      AiFriendFace(size: 64),
                      SizedBox(height: Tokens.space[1]),
                      Text(l.aiFriendWrong, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Composer: Telegram size, round send button.
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], pad.bottom + Tokens.space[1]),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: LiquidGlass(
                    radius: 20,
                    child: CupertinoTextField(
                      key: const Key('ai-friend-input'),
                      controller: input,
                      enabled: ok != false,
                      placeholder: l.aiFriendHint,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: AiFriend.maxText,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] - 2),
                      style: Tokens.body.style.copyWith(color: p.label),
                      placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                      decoration: const BoxDecoration(),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                ),
                SizedBox(width: Tokens.space[1]),
                TextFieldTapRegion(
                  child: GestureDetector(
                    key: const Key('ai-friend-send'),
                    onTap: input.text.trim().isEmpty || thinking ? null : send,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: input.text.trim().isEmpty ? p.incoming : p.accent, shape: BoxShape.circle),
                      child: Icon(CupertinoIcons.arrow_up, size: 20, color: input.text.trim().isEmpty ? p.secondaryLabel : p.onAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
