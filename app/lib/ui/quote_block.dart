// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 인용문 (Telegram tips 455 + 399). "> " lines are a quote box; ">> "
// lines are a quote the sender folded (접는 인용): three lines show, the
// rest opens with a tap. The marks travel inside the encrypted message;
// whether a reader opened a folded quote stays on that screen only.
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

/// Lines that start a quote, folded or not.
const quoteMark = '> ', foldMark = '>> ';

/// How many lines a folded quote shows (Telegram: 3).
const foldLines = 3;

/// A run of lines of one kind: plain words, a quote, or a folded quote.
class TextPart {
  const TextPart(this.kind, this.lines);

  /// 'text', 'quote' or 'fold'.
  final String kind;
  final List<String> lines;
  String get text => lines.join('\n');
}

/// Splits a message into plain parts and quote boxes. A folded quote that
/// follows a plain one (or the other way round) starts a new box.
List<TextPart> splitQuotes(String text) {
  final out = <TextPart>[];
  for (final line in text.split('\n')) {
    final (kind, rest) = line.startsWith(foldMark)
        ? ('fold', line.substring(foldMark.length))
        : line.startsWith(quoteMark)
        ? ('quote', line.substring(quoteMark.length))
        // A lone ">" or ">>" keeps an empty line inside the quote.
        : line == '>>'
        ? ('fold', '')
        : line == '>'
        ? ('quote', '')
        : ('text', line);
    if (out.isNotEmpty && out.last.kind == kind) {
      out.last.lines.add(rest);
    } else {
      out.add(TextPart(kind, [rest]));
    }
  }
  return out;
}

/// Puts the chosen lines of [text] (the selection [from]..[to], widened to
/// whole lines) into a quote, or takes them out again when they already
/// are one of the same kind. Returns the new text and where the lines now
/// end.
(String, int) toggleQuote(String text, int from, int to, {required bool fold}) {
  final start = text.lastIndexOf('\n', from <= 0 ? 0 : from - 1) + 1;
  final cut = text.indexOf('\n', to > start ? to - 1 : to);
  final end = cut < 0 ? text.length : cut;
  final lines = text.substring(start, end).split('\n');
  final mark = fold ? foldMark : quoteMark;
  String bare(String l) => l.startsWith(foldMark)
      ? l.substring(foldMark.length)
      : l.startsWith(quoteMark)
      ? l.substring(quoteMark.length)
      : l;
  final already = lines.every((l) => l.startsWith(mark) && (fold || !l.startsWith(foldMark)));
  final next = lines.map((l) => already ? bare(l) : '$mark${bare(l)}').join('\n');
  return (text.substring(0, start) + next + text.substring(end), start + next.length);
}

/// One quote box: a light tint of the bubble's ink, a 3 pt bar on the
/// leading side and a small quote sign at the top right (Telegram / iOS
/// 27 Messages tint). Folded ones show three lines with a soft fade and
/// a chevron; a tap opens or closes them.
class QuoteBox extends StatefulWidget {
  const QuoteBox({super.key, required this.child, required this.color, required this.folded, required this.style});

  /// The quote's words (already formatted).
  final InlineSpan child;

  /// Bar, tint and signs (the bubble's link colour).
  final Color color;
  final bool folded;
  final TextStyle style;

  @override
  State<QuoteBox> createState() => _QuoteBoxState();
}

class _QuoteBoxState extends State<QuoteBox> {
  /// Opened by this reader (not saved anywhere).
  bool open = false;

  /// The words are longer than the folded height (so the chevron shows).
  bool longer = false;
  final words = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.folded) WidgetsBinding.instance.addPostFrameCallback((_) => measure());
  }

  @override
  void didUpdateWidget(QuoteBox old) {
    super.didUpdateWidget(old);
    if (widget.folded && !open) WidgetsBinding.instance.addPostFrameCallback((_) => measure());
  }

  /// After layout: did the three lines cut anything off?
  void measure() {
    if (!mounted || open) return;
    final r = words.currentContext?.findRenderObject();
    final more = r is RenderParagraph && r.didExceedMaxLines;
    if (more != longer) setState(() => longer = more);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final shut = widget.folded && !open;
    Widget text = Text.rich(
      widget.child,
      key: words,
      style: widget.style,
      maxLines: shut ? foldLines : null,
      overflow: shut ? TextOverflow.clip : TextOverflow.visible,
    );
    if (shut && longer) {
      // The last folded line fades out towards the chevron (Telegram).
      final lh = (widget.style.fontSize ?? 15) * (widget.style.height ?? 1.3);
      text = ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [((r.height - lh * 0.9) / r.height).clamp(0.0, 1.0), 1],
          colors: const [Color(0xFFFFFFFF), Color(0x26FFFFFF)],
        ).createShader(r),
        child: text,
      );
    }
    final box = Container(
      key: const Key('quote-box'),
      margin: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
      padding: EdgeInsets.fromLTRB(Tokens.space[1] + 3, Tokens.space[0] / 2, Tokens.space[3] + 2, Tokens.space[0] / 2 + (widget.folded && longer ? 2 : 0)),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[0])),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius[0]),
        border: Border(left: BorderSide(color: c, width: 3)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedSize(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic, alignment: Alignment.topCenter, child: text),
          Positioned(
            top: 0,
            right: -Tokens.space[3],
            child: Text(
              '”',
              key: const Key('quote-sign'),
              style: TextStyle(color: c, fontSize: 20, height: 1, fontWeight: FontWeight.w700),
            ),
          ),
          if (widget.folded && longer)
            Positioned(
              bottom: 0,
              right: -Tokens.space[3],
              child: Icon(open ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, key: const Key('quote-chevron'), size: 13, color: c),
            ),
        ],
      ),
    );
    if (!widget.folded) return box;
    return GestureDetector(
      key: Key(open ? 'quote-close' : 'quote-open'),
      behavior: HitTestBehavior.opaque,
      onTap: longer || open
          ? () {
              setState(() => open = !open);
              if (!open) WidgetsBinding.instance.addPostFrameCallback((_) => measure());
            }
          : null,
      child: box,
    );
  }
}

/// Above a reply that quotes only part of a message (tip 399): who wrote
/// it, the picked words (up to three lines) and the quote sign. From
/// another chat: a small two-bubble sign before the name and no jump
/// (that message is not in this chat).
class ReplyQuoteHeader extends StatelessWidget {
  const ReplyQuoteHeader({super.key, required this.name, required this.text, required this.color, required this.ink, this.otherChat = false, this.onTap});
  final String name;
  final String text;
  final Color color;
  final Color ink;
  final bool otherChat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cap = Tokens.caption.style;
    return GestureDetector(
      key: Key(otherChat ? 'quote-other-chat' : 'quote-part'),
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: Tokens.space[0] - 2, bottom: Tokens.space[0]),
        padding: EdgeInsets.fromLTRB(Tokens.space[1] + 3, 2, Tokens.space[3] + 2, 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[0])),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.radius[0]),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (name.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (otherChat) ...[Icon(CupertinoIcons.bubble_left_bubble_right_fill, size: 12, color: color), const SizedBox(width: 4)],
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cap.copyWith(color: color),
                        ),
                      ),
                    ],
                  ),
                Text(
                  text,
                  maxLines: foldLines,
                  overflow: TextOverflow.ellipsis,
                  style: cap.copyWith(color: ink),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: -Tokens.space[3],
              child: Text(
                '”',
                style: TextStyle(color: color, fontSize: 18, height: 1, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "특정 부분 인용" (tip 399): the message's words with iOS handles; the
/// picked part (all of it at first, like Telegram) becomes the quote.
/// Returns the words, or null when cancelled.
class QuotePickPage extends StatefulWidget {
  const QuotePickPage({super.key, required this.words, required this.name, this.start});
  final String words;
  final String name;

  /// The part picked before (opened again from the reply line).
  final String? start;

  @override
  State<QuotePickPage> createState() => _QuotePickPageState();
}

class _QuotePickPageState extends State<QuotePickPage> {
  late final text = TextEditingController(text: widget.words);
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final at = widget.start == null ? -1 : widget.words.indexOf(widget.start!);
    text.selection = at < 0
        ? TextSelection(baseOffset: 0, extentOffset: widget.words.length)
        : TextSelection(baseOffset: at, extentOffset: at + widget.start!.length);
    text.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.requestFocus();
    });
  }

  @override
  void dispose() {
    text.dispose();
    focus.dispose();
    super.dispose();
  }

  String get picked {
    final s = text.selection;
    return s.isValid && !s.isCollapsed ? s.textInside(text.text).trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ok = picked.isNotEmpty;
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        middle: Text(l.quotePickTitle),
        trailing: CupertinoButton(
          key: const Key('quote-pick-done'),
          padding: EdgeInsets.zero,
          onPressed: ok ? () => Navigator.pop(context, picked.characters.take(1024).toString()) : null,
          child: Text(
            l.fmtQuote,
            style: TextStyle(fontWeight: Tokens.semi, color: ok ? p.accent : p.secondaryLabel),
          ),
        ),
        backgroundColor: p.chatBackground.withValues(alpha: 0.7),
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[3]),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.85),
                padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
                decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.name, style: Tokens.caption.style.copyWith(color: p.accent)),
                    CupertinoTextField.borderless(
                      key: const Key('quote-pick-text'),
                      controller: text,
                      focusNode: focus,
                      readOnly: true,
                      showCursor: false,
                      maxLines: null,
                      padding: EdgeInsets.zero,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Tokens.space[3]),
            Text(
              ok ? l.quotePickCount(picked.characters.length) : l.quotePickHint,
              key: const Key('quote-pick-hint'),
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}
