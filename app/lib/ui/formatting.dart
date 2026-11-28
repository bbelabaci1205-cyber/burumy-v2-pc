// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Message formatting: **bold**, __italic__, ++underline++, ~~strike~~,
// `code`, ||spoiler||, [text](https://link), \( formula \) and "> " quote
// lines. The
// marks travel inside the encrypted message and are drawn on the phone.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../core/app_state.dart';
import '../core/code_colors.dart';
import '../core/date_mark.dart';
import '../core/features.dart';
import '../core/search.dart' show findHashtags;
import '../design/tokens.dart';
import '../core/plan_pick.dart';
import '../l10n/app_localizations.dart';
import '../stickers/char_emoji.dart';
import 'chat_page.dart' show LinkEditPage;
import 'code_block.dart';
import 'date_pick.dart';
import 'common.dart' show paletteOf;
import 'hashtag_page.dart' show openHashtag;
import 'ios.dart';
import 'ios_route.dart';
import 'links.dart';
import 'phone_numbers.dart';
import 'quote_block.dart';
import 'wide.dart';

/// Marks in the order they are looked for.
const formatMarks = ['**', '__', '++', '~~', '||', '`'];

final _link = RegExp(r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)');

/// A formula inside a line: \( a^2 + b^2 = c^2 \).
final _math = RegExp(r'\\\((.+?)\\\)');
final _bare = RegExp(r'''https?://[^\s<>()]+[^\s<>().,!?'"]''');

/// Video time links (Telegram tips 84 + 198): "1:05" or "1:02:30".
final _timecode = RegExp(r'(?<![\d:])(?:(\d{1,2}):)?([0-5]?\d):([0-5]\d)(?![\d:])');

/// The times written in [s] (start, end, time).
List<(int, int, Duration)> findTimecodes(String s) => [
  for (final m in _timecode.allMatches(s))
    (m.start, m.end, Duration(hours: int.tryParse(m.group(1) ?? '') ?? 0, minutes: int.parse(m.group(2)!), seconds: int.parse(m.group(3)!))),
];

/// The text with all marks taken out (list previews, notifications, copy).
String plainText(String text) {
  // ``` fence lines (and their language name) are not shown in previews.
  var t = text.contains('```') ? text.replaceAll(RegExp(r'^[ \t]*```[A-Za-z0-9_+#.-]*[ \t]*\n?', multiLine: true), '').replaceAll('```', '') : text;
  t = t.replaceAllMapped(dateMark, (m) => m.group(1)!).replaceAllMapped(_link, (m) => m.group(1)!).replaceAllMapped(_math, (m) => m.group(1)!);
  for (final k in formatMarks) {
    final e = RegExp.escape(k);
    t = t.replaceAllMapped(RegExp('$e(.+?)$e', dotAll: true), (m) => m.group(1)!);
  }
  return charEmojiPlain(
    t
        .split('\n')
        .map(
          (l) => l.startsWith(foldMark)
              ? l.substring(foldMark.length)
              : l.startsWith('> ')
              ? l.substring(2)
              : l,
        )
        .join('\n'),
  );
}

/// Wraps the selected part of [c] in [mark] (or adds a link).
void wrapSelection(TextEditingController c, String mark, {String? url}) {
  final sel = c.selection;
  if (!sel.isValid || sel.isCollapsed) return;
  final inner = sel.textInside(c.text);
  // Code over several lines becomes a ``` block (tip 411) on its own lines.
  final block = url == null && mark == '`' && inner.contains('\n');
  final before = sel.textBefore(c.text), after = sel.textAfter(c.text);
  final repl = url != null
      ? '[$inner]($url)'
      : block
      ? '${before.isEmpty || before.endsWith('\n') ? '' : '\n'}```\n$inner\n```${after.isEmpty || after.startsWith('\n') ? '' : '\n'}'
      : '$mark$inner$mark';
  c.value = TextEditingValue(
    text: sel.textBefore(c.text) + repl + sel.textAfter(c.text),
    selection: TextSelection.collapsed(offset: sel.start + repl.length),
  );
}

/// The message field: a date mark shows only its words, dotted-underlined
/// like in the sent message, instead of "[내일 10시](t:1772272800)"; the
/// marks stay in the text (drawn tiny and clear) so sending is unchanged.
class ComposeController extends EmojiTextController {
  ComposeController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!text.contains('](t:') || (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final hidden = (style ?? const TextStyle()).copyWith(fontSize: 0.01, color: const Color(0x00000000), letterSpacing: 0);
    final line = CupertinoTheme.of(context).primaryColor;
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in dateMark.allMatches(text)) {
      if (m.start > at) out.add(TextSpan(text: text.substring(at, m.start)));
      out.add(TextSpan(text: '[', style: hidden));
      out.add(
        TextSpan(
          text: m.group(1),
          style: TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted, decorationColor: line, decorationThickness: 1.6),
        ),
      );
      out.add(TextSpan(text: text.substring(m.start + 1 + m.group(1)!.length, m.end), style: hidden));
      at = m.end;
    }
    if (at < text.length) out.add(TextSpan(text: text.substring(at)));
    return TextSpan(style: style, children: out);
  }
}

/// 날짜 표시 (tip 559): the selected words carry [at].
void markDate(TextEditingController c, DateTime at) {
  final sel = c.selection;
  if (!sel.isValid || sel.isCollapsed) return;
  final repl = dateMarkText(sel.textInside(c.text), at);
  c.value = TextEditingValue(
    text: sel.textBefore(c.text) + repl + sel.textAfter(c.text),
    selection: TextSelection.collapsed(offset: sel.start + repl.length),
  );
}

/// The text field's menu: with words selected, the format buttons too
/// (bold … spoiler, link), like the chat composer.
Widget formatMenu(BuildContext context, EditableTextState st, TextEditingController input) {
  final l = L.of(context);
  final items = [...st.contextMenuButtonItems];
  if (!st.textEditingValue.selection.isCollapsed) {
    void f(String mark) {
      wrapSelection(input, mark);
      st.hideToolbar();
    }

    items.addAll([
      ContextMenuButtonItem(label: l.fmtBold, onPressed: () => f('**')),
      ContextMenuButtonItem(label: l.fmtItalic, onPressed: () => f('__')),
      ContextMenuButtonItem(label: l.fmtUnderline, onPressed: () => f('++')),
      ContextMenuButtonItem(label: l.fmtStrike, onPressed: () => f('~~')),
      ContextMenuButtonItem(label: l.fmtCode, onPressed: () => f('`')),
      ContextMenuButtonItem(label: l.fmtSpoiler, onPressed: () => f('||')),
      // 인용 / 접는 인용 (tip 455): whole lines; again = take it out.
      if (Features.tipsReply)
        for (final fold in const [false, true])
          ContextMenuButtonItem(
            label: fold ? l.fmtFoldQuote : l.fmtQuote,
            onPressed: () {
              final sel = input.selection;
              final (t, at) = toggleQuote(input.text, sel.start, sel.end, fold: fold);
              input.value = TextEditingValue(
                text: t,
                selection: TextSelection.collapsed(offset: at),
              );
              st.hideToolbar();
            },
          ),
      ContextMenuButtonItem(
        label: l.fmtLink,
        onPressed: () async {
          st.hideToolbar();
          final sel = input.selection;
          final url = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const LinkEditPage()));
          if (url == null) return;
          input.selection = sel;
          wrapSelection(input, '', url: url);
        },
      ),
      // 날짜 (tip 559): the words get an exact moment each reader sees in
      // their own time zone. Written dates ("내일 3시") fill the calendar in.
      if (Features.tipsLink)
        ContextMenuButtonItem(
          label: l.fmtDate,
          onPressed: () async {
            st.hideToolbar();
            final sel = input.selection;
            final words = sel.textInside(input.text);
            final found = findPlans(words, DateTime.now());
            final at = await pickDateTime(context, initial: found.isEmpty ? null : found.first.at);
            if (at == null) return;
            input.selection = sel;
            markDate(input, at);
          },
        ),
    ]);
  }
  return CupertinoAdaptiveTextSelectionToolbar.buttonItems(anchors: st.contextMenuAnchors, buttonItems: items);
}

/// Formatted message text; spoilers open with a tap.
class FormattedText extends StatefulWidget {
  const FormattedText(
    this.text, {
    super.key,
    required this.style,
    required this.linkColor,
    required this.quoteColor,
    this.onPlan,
    this.onTime,
    this.codeInset = false,
    this.onCodeCopied,
    this.onDateRemind,
    this.tagRoom,
  });

  /// 날짜 표시 > 알림 설정: a reminder for this message at that time.
  final ValueChanged<DateTime>? onDateRemind;
  final String text;

  /// ``` code blocks on my own (accent) bubble get a card-coloured box.
  final bool codeInset;

  /// "코드를 복사했어요" shown by the chat screen.
  final ValueChanged<String>? onCodeCopied;

  /// 해시태그 (tips 454 · 484): #words open the hashtag page; the chat
  /// they were tapped in gets the 이 대화 tab. Only with [Features.search].
  final String? tagRoom;

  /// Caption of a video, or a reply to one: "1:05" plays it from there.
  final ValueChanged<Duration>? onTime;

  /// Settings > Chats > Find plans: dates and times become tappable.
  final ValueChanged<DateTime>? onPlan;
  final TextStyle style;
  final Color linkColor;
  final Color quoteColor;
  @override
  State<FormattedText> createState() => _FormattedTextState();
}

class _FormattedTextState extends State<FormattedText> {
  bool revealed = false;
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _taps) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer tap(VoidCallback f) {
    final r = TapGestureRecognizer()..onTap = f;
    _taps.add(r);
    return r;
  }

  List<InlineSpan> links(String s, TextStyle st) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final m in _bare.allMatches(s)) {
      if (m.start > at) out.addAll(times(s.substring(at, m.start), st));
      final url = m.group(0)!;
      out.add(TextSpan(text: url, style: st.merge(linkStyle), recognizer: tap(() => open(url))));
      at = m.end;
    }
    if (at < s.length) out.addAll(times(s.substring(at), st));
    return out;
  }

  /// Video times become links (before plan times, so "1:05" is not 1 AM).
  List<InlineSpan> times(String s, TextStyle st) {
    final f = widget.onTime;
    if (f == null) return phones(s, st);
    final out = <InlineSpan>[];
    var at = 0;
    for (final (from, to, d) in findTimecodes(s)) {
      if (from > at) out.addAll(phones(s.substring(at, from), st));
      out.add(
        TextSpan(
          text: s.substring(from, to),
          style: st.merge(TextStyle(color: widget.linkColor, decoration: TextDecoration.underline, decorationColor: widget.linkColor)),
          recognizer: tap(() => f(d)),
        ),
      );
      at = to;
    }
    if (at < s.length) out.addAll(phones(s.substring(at), st));
    return out;
  }

  /// Phone numbers in the words open the call / text / copy menu.
  List<InlineSpan> phones(String s, TextStyle st) {
    final out = <InlineSpan>[];
    var at = 0;
    for (final (a, b) in findPhones(s)) {
      if (a > at) out.addAll(tags(s.substring(at, a), st));
      final n = s.substring(a, b);
      out.add(TextSpan(text: n, style: st.merge(linkStyle), recognizer: tap(() => openPhoneMenu(context, n))));
      at = b;
    }
    if (at < s.length) out.addAll(tags(s.substring(at), st));
    return out;
  }

  /// #해시태그 in link colour (no underline, like Telegram); a tap opens
  /// the hashtag page.
  List<InlineSpan> tags(String s, TextStyle st) {
    if (!Features.search || !s.contains('#')) return plans(s, st);
    final out = <InlineSpan>[];
    var at = 0;
    for (final h in findHashtags(s)) {
      if (h.start > at) out.addAll(plans(s.substring(at, h.start), st));
      out.add(
        TextSpan(
          text: s.substring(h.start, h.end),
          style: st.merge(TextStyle(color: widget.linkColor)),
          recognizer: tap(() => openHashtag(context, h.text, roomId: widget.tagRoom)),
        ),
      );
      at = h.end;
    }
    if (at < s.length) out.addAll(plans(s.substring(at), st));
    return out;
  }

  /// Plain words, with found dates and times dotted-underlined.
  List<InlineSpan> plans(String s, TextStyle st) {
    final f = widget.onPlan;
    if (f == null) return charEmojiSpans(s, st);
    final out = <InlineSpan>[];
    var at = 0;
    for (final h in findPlans(s, DateTime.now())) {
      if (h.start > at) out.addAll(charEmojiSpans(s.substring(at, h.start), st));
      out.add(
        TextSpan(
          text: s.substring(h.start, h.end),
          style: st.merge(TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted, decorationColor: widget.linkColor)),
          recognizer: tap(() => f(h.at)),
        ),
      );
      at = h.end;
    }
    if (at < s.length) out.addAll(charEmojiSpans(s.substring(at), st));
    return out;
  }

  TextStyle get linkStyle => TextStyle(color: widget.linkColor, decoration: TextDecoration.underline, decorationColor: widget.linkColor);

  void open(String url) => openWebLink(context, url);

  /// A link under other words ("[here](https://...)") could pretend to go
  /// somewhere else: show the real address first, like Telegram.
  Future<void> openHidden(String shown, String url) async {
    if (shown.trim() == url) return open(url);
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.openLinkAsk),
        message: Text(url, key: const Key('link-real')),
        actions: [CupertinoActionSheetAction(key: const Key('link-open'), onPressed: () => Navigator.pop(c, true), child: Text(l.openLink))],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok == true) open(url);
  }

  /// Inline marks, nested.
  List<InlineSpan> inline(String s, TextStyle st) {
    final out = <InlineSpan>[];
    var i = 0, plainFrom = 0;
    void flush(int to) {
      if (to > plainFrom) out.addAll(links(s.substring(plainFrom, to), st));
    }

    while (i < s.length) {
      final mm = _math.matchAsPrefix(s, i);
      if (mm != null) {
        flush(i);
        out.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Math.tex(
              mm.group(1)!,
              mathStyle: MathStyle.text,
              textStyle: st,
              onErrorFallback: (_) => Text(mm.group(0)!, style: st),
            ),
          ),
        );
        i = plainFrom = mm.end;
        continue;
      }
      final dm = dateMark.matchAsPrefix(s, i);
      if (dm != null) {
        flush(i);
        final at = dateMarkAt(dm);
        out.add(
          TextSpan(
            text: dm.group(1),
            style: st.merge(
              TextStyle(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
                decorationColor: widget.linkColor,
                decorationThickness: 1.6,
              ),
            ),
            recognizer: tap(() => openDateSheet(context, at, eventTitle(plainText(widget.text)), onRemind: widget.onDateRemind)),
          ),
        );
        i = plainFrom = dm.end;
        continue;
      }
      final lm = _link.matchAsPrefix(s, i);
      if (lm != null) {
        flush(i);
        final url = lm.group(2)!;
        final shown = lm.group(1)!;
        out.add(TextSpan(text: shown, style: st.merge(linkStyle), recognizer: tap(() => openHidden(shown, url))));
        i = plainFrom = lm.end;
        continue;
      }
      String? hit;
      int end = -1;
      for (final k in formatMarks) {
        if (s.startsWith(k, i)) {
          final e = s.indexOf(k, i + k.length);
          if (e > i + k.length) {
            hit = k;
            end = e;
            break;
          }
        }
      }
      if (hit == null) {
        i++;
        continue;
      }
      flush(i);
      final inner = s.substring(i + hit.length, end);
      switch (hit) {
        case '**':
          out.addAll(inline(inner, st.copyWith(fontWeight: Tokens.semi)));
        case '__':
          out.addAll(inline(inner, st.copyWith(fontStyle: FontStyle.italic)));
        case '++':
          out.addAll(inline(inner, st.copyWith(decoration: TextDecoration.underline, decorationColor: st.color)));
        case '~~':
          out.addAll(inline(inner, st.copyWith(decoration: TextDecoration.lineThrough, decorationColor: st.color)));
        case '`':
          out.add(
            TextSpan(
              text: inner,
              style: st.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['Menlo', 'Courier']),
            ),
          );
        case '||':
          out.add(
            TextSpan(
              text: inner,
              recognizer: revealed ? null : tap(() => setState(() => revealed = true)),
              style: revealed
                  ? st
                  : st.copyWith(color: const Color(0x00000000), backgroundColor: (st.color ?? const Color(0xFF888888)).withValues(alpha: 0.28)),
            ),
          );
      }
      i = plainFrom = end + hit.length;
    }
    flush(s.length);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _taps) {
      r.dispose();
    }
    _taps.clear();
    // Settings > Chats > Formatted messages off: the marks show as typed.
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    if (scope != null && !scope.notifier!.on('formatting', fallback: true)) {
      return Text.rich(TextSpan(style: widget.style, children: links(widget.text, widget.style)));
    }
    final pieces = Features.tipsLink ? splitCode(widget.text) : [TextPiece.words(widget.text)];
    if (pieces.length == 1 && !pieces.first.code) return words(widget.text);
    // Words and ``` code blocks (tip 411), one under the other.
    return Column(
      key: const Key('formatted-pieces'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final piece in pieces)
          piece.code
              ? CodeBlockView(
                  code: piece.text,
                  lang: piece.lang,
                  fg: widget.style.color ?? paletteOf(context).label,
                  accent: widget.quoteColor,
                  inset: widget.codeInset,
                  onCopied: widget.onCodeCopied,
                )
              : words(piece.text),
      ],
    );
  }

  Widget words(String text) {
    // 인용문 상자 (tip 455): quotes become boxes, folded ones open on tap.
    if (Features.tipsReply && text.split('\n').any((x) => x.startsWith('> ') || x.startsWith(foldMark) || x == '>' || x == '>>')) {
      // Telegram: quote words a step smaller than the message (15/20).
      final qs = widget.style.copyWith(fontSize: Tokens.preview.style.fontSize, height: Tokens.preview.style.height);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final part in splitQuotes(text))
            if (part.kind == 'text')
              Text.rich(TextSpan(style: widget.style, children: inline(part.text, widget.style)))
            else
              QuoteBox(
                color: widget.quoteColor,
                folded: part.kind == 'fold',
                style: qs,
                child: TextSpan(style: qs, children: inline(part.text, qs)),
              ),
        ],
      );
    }
    final spans = <InlineSpan>[];
    final lines = text.split('\n');
    for (var n = 0; n < lines.length; n++) {
      final line = lines[n];
      if (line.startsWith('> ')) {
        spans.add(
          TextSpan(
            text: '▎',
            style: widget.style.copyWith(color: widget.quoteColor),
          ),
        );
        spans.addAll(inline(line.substring(2), widget.style.copyWith(fontStyle: FontStyle.italic)));
      } else {
        spans.addAll(inline(line, widget.style));
      }
      if (n < lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
