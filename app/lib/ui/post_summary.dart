// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 긴 글 AI 요약 (Telegram tip 554): a long post in a channel or group gets a
// small "요약" button at its top. Tapping it makes a few lines with the
// phone's own AI (core/ai_local.dart) and shows them in place of the post,
// with "원문 보기" to go back. Telegram sends the post to its own servers for
// this; here the words never leave the phone, and the summary is kept on
// this phone only. Hidden in chats with 공유 비활성화, on phones without
// on-device AI, and for people the 18+ check keeps out (Android).
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/ai_local.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'ai_age_ui.dart';

class PostSummary {
  const PostSummary._();

  /// Shorter posts are quick to read: no button.
  static const minChars = 500;

  /// On-phone models have small windows: the start of a very long post.
  static const maxChars = 4000;

  /// Settings key that turns the button off (Settings > 대화 > AI 기능).
  static const pref = 'ai_post_summary';

  static String rules(String language) =>
      'You summarize one long chat post for the person reading it. Reply in $language with 2 to 4 short lines, '
      "each starting with '• '. Keep names, dates, times, places, prices and numbers exactly. "
      'Leave out greetings and filler. Never add facts that are not in the post.';

  /// The phone keeps each summary under this key (never sent anywhere).
  static String key(String msgId) => 'sum:$msgId';

  /// Whether this message gets the button at all (the AI check comes later).
  static bool fits(Msg m, {required bool room}) => room && m.kind == 'text' && !m.viewOnce && (m.body ?? '').trim().length >= minChars;

  /// The post's words for the model (marks are left in: they're short).
  static String input(String body) {
    final t = body.trim();
    return t.length <= maxChars ? t : t.substring(0, maxChars);
  }
}

/// 링크 3줄 요약 (4-app board, Viber 2025): an article from a link, made
/// short by the phone's own AI (the page is fetched by the phone itself, as
/// 읽기 모드 does).
class LinkSummary {
  const LinkSummary._();

  static String rules(String language) =>
      'You summarize a web article for the person reading it. Reply in $language with exactly 3 short lines, '
      "each starting with '• '. Keep names, dates, times, places, prices and numbers exactly. "
      'Never add facts that are not in the article.';
}

/// Wraps a long post's words: the 요약 button above, the summary in place.
class SummaryArea extends StatefulWidget {
  const SummaryArea({super.key, required this.msg, required this.fg, required this.child});
  final Msg msg;
  final Color fg;

  /// The post's own words (shown until a summary is open).
  final Widget child;

  @override
  State<SummaryArea> createState() => _SummaryAreaState();
}

class _SummaryAreaState extends State<SummaryArea> with SingleTickerProviderStateMixin {
  bool open = false, busy = false, failed = false;
  String? summary;
  late final AnimationController shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void initState() {
    super.initState();
    // Ask the phone once whether it has AI (cached for the whole app).
    if (LocalAi.known == null) unawaited(LocalAi.status().then((_) => mounted ? setState(() {}) : null));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final kept = AppScope.of(context).settings[PostSummary.key(widget.msg.id)];
    if (summary == null && kept != null && kept.trim().isNotEmpty) summary = kept;
  }

  @override
  void dispose() {
    shine.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (open) return setState(() => open = false);
    if (!await aiAgeOk(context) || !mounted) return;
    if (summary != null) return setState(() => open = true);
    final s = AppScope.read(context);
    setState(() {
      busy = true;
      failed = false;
    });
    unawaited(shine.repeat());
    final lang = (s.locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'en' ? 'English' : 'Korean';
    try {
      final out = await LocalAi.run(rules: PostSummary.rules(lang), text: PostSummary.input(widget.msg.body ?? ''));
      summary = out.trim();
      unawaited(s.setPref(PostSummary.key(widget.msg.id), summary!));
      open = true;
    } catch (_) {
      failed = true;
    }
    shine.stop();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final offered = LocalAi.onPhone && s.on(PostSummary.pref, fallback: true);
    if (!offered) return widget.child;
    final l = L.of(context);
    final fg = widget.fg;
    final soft = fg.withValues(alpha: 0.7);
    final button = GestureDetector(
      key: Key('post-summary-${widget.msg.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : toggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 3),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[3])),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(open ? CupertinoIcons.doc_text : CupertinoIcons.sparkles, size: 13, color: fg),
            const SizedBox(width: 3),
            Text(
              busy ? l.postSummaryBusy : (open ? l.postSummaryOriginal : l.postSummaryButton),
              style: Tokens.caption.style.copyWith(color: fg, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
    final Widget body;
    if (open && summary != null) {
      body = Column(
        key: const Key('post-summary-box'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(Tokens.space[1]),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Tokens.radius[1]),
              border: Border(left: BorderSide(color: fg.withValues(alpha: 0.5), width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.postSummaryTitle,
                  style: Tokens.caption.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(
                  summary!,
                  key: const Key('post-summary-text'),
                  style: Tokens.body.style.copyWith(color: fg),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[0]),
            child: Text(l.postSummaryOnPhone, style: Tokens.caption.style.copyWith(color: soft)),
          ),
        ],
      );
    } else if (busy) {
      // A light sweeping over the words while the phone thinks.
      body = AnimatedBuilder(
        animation: shine,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (r) {
            final x = shine.value * 3 - 1;
            return LinearGradient(
              begin: Alignment(x - 1, -0.3),
              end: Alignment(x + 1, 0.3),
              colors: [fg.withValues(alpha: 0), fg.withValues(alpha: 0.45), fg.withValues(alpha: 0)],
            ).createShader(r);
          },
          child: child,
        ),
        child: widget.child,
      );
    } else {
      body = widget.child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: Tokens.space[0]),
          child: button,
        ),
        if (failed)
          Padding(
            padding: EdgeInsets.only(bottom: Tokens.space[0]),
            child: Text(
              l.postSummaryFailed,
              key: const Key('post-summary-failed'),
              style: Tokens.caption.style.copyWith(color: soft),
            ),
          ),
        body,
      ],
    );
  }
}
