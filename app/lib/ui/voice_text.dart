// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The 글로 보기 button on a voice message, and the words under it with a
// 번역 link (phone AI). The words are kept on this phone only (on-device
// settings), so the button shows them at once the next time.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../core/ai_local.dart';
import '../core/ai_styles.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/transcribe.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'ai_age_ui.dart';

class VoiceTextArea extends StatefulWidget {
  const VoiceTextArea({super.key, required this.roomId, required this.msg, required this.fg, required this.child, this.mime});
  final String roomId;
  final Msg msg;
  final Color fg;

  /// 동그란 영상 메시지 (tip 361): "video/mp4"; null = a voice message.
  final String? mime;

  /// The voice message itself (play button and wave).
  final Widget child;

  @override
  State<VoiceTextArea> createState() => _VoiceTextAreaState();
}

class _VoiceTextAreaState extends State<VoiceTextArea> {
  bool open = false, busy = false, failed = false, translating = false, showTranslation = false;
  String? words, translated;

  String get key => 'stt:${widget.msg.id}';
  String get trKey => 'stt_tr:${widget.msg.id}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    words ??= s.settings[key];
    translated ??= s.settings[trKey];
  }

  String lang(AppState s) => (s.locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode;

  Future<void> toggle() async {
    if (open) return setState(() => open = false);
    setState(() {
      open = true;
      failed = false;
    });
    if (words != null) return;
    final s = AppScope.read(context);
    setState(() => busy = true);
    try {
      final bytes = Uint8List.fromList(await s.backend.downloadFile(widget.roomId, widget.msg.id));
      final got = await Transcribe.run(
        bytes,
        mime: widget.mime ?? ((widget.msg.body ?? '').toLowerCase().endsWith('.webm') ? 'audio/webm' : 'audio/mp4'),
        lang: lang(s),
      );
      if (!mounted) return;
      if (got == null) {
        setState(() => failed = true);
      } else {
        words = got.trim();
        unawaited(s.setPref(key, words!.isEmpty ? ' ' : words!));
      }
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> translate() async {
    if (translated != null) return setState(() => showTranslation = !showTranslation);
    if (!await aiAgeOk(context) || !mounted) return;
    final s = AppScope.read(context);
    final to = lang(s);
    setState(() => translating = true);
    try {
      final out = await LocalAi.run(rules: AiStyles.translateRules(aiLanguages[to] ?? 'Korean'), text: words!);
      translated = out;
      showTranslation = true;
      unawaited(s.setPref(trKey, out));
    } catch (_) {}
    if (mounted) setState(() => translating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final fg = widget.fg;
    final soft = fg.withValues(alpha: 0.7);
    final text = (words ?? '').trim();
    final s = AppScope.of(context);
    // Translate only words that aren't already in my language.
    final foreign = text.isNotEmpty && detectLanguage(text) != '' && detectLanguage(text) != lang(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A narrow bubble shrinks the wave a little to make room.
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: widget.child),
            ),
            if (Transcribe.offered) ...[
              SizedBox(width: Tokens.space[1]),
              GestureDetector(
                key: const Key('voice-text'),
                onTap: busy ? null : toggle,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: fg.withValues(alpha: open ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(Tokens.radius[0]),
                  ),
                  alignment: Alignment.center,
                  child: busy
                      ? CupertinoActivityIndicator(radius: 7, color: fg)
                      : Icon(open ? CupertinoIcons.chevron_up : CupertinoIcons.textformat, size: 15, color: fg, semanticLabel: l.voiceToText),
                ),
              ),
            ],
          ],
        ),
        if (open && !busy)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Padding(
              padding: EdgeInsets.only(top: Tokens.space[1]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failed ? l.voiceToTextFailed : (text.isEmpty ? l.voiceToTextEmpty : text),
                    key: const Key('voice-words'),
                    style: Tokens.body.style.copyWith(color: failed || text.isEmpty ? soft : fg),
                  ),
                  if (showTranslation && translated != null) ...[
                    SizedBox(height: Tokens.space[0]),
                    Text(
                      translated!,
                      key: const Key('voice-translated'),
                      style: Tokens.body.style.copyWith(color: fg),
                    ),
                  ],
                  if (foreign && LocalAi.known != AiStatus.unsupported)
                    GestureDetector(
                      key: const Key('voice-translate'),
                      onTap: translating ? null : translate,
                      child: Padding(
                        padding: EdgeInsets.only(top: Tokens.space[0]),
                        child: Text(
                          translating ? l.voiceTranslating : (showTranslation ? l.voiceShowOriginal : l.voiceTranslate),
                          style: Tokens.caption.style.copyWith(color: soft, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(top: Tokens.space[0]),
                    child: Text(l.voiceToTextOnPhone, style: Tokens.caption.style.copyWith(color: soft)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
