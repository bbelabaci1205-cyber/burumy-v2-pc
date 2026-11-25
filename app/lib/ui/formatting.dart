// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Message formatting: **bold**, __italic__, ++underline++, ~~strike~~,
// `code`, ||spoiler||, [text](https://link) and "> " quote lines. The
// marks travel inside the encrypted message and are drawn on the phone.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import '../core/app_state.dart';
import '../core/plan_pick.dart';
import '../l10n/app_localizations.dart';
import 'ios.dart';
import 'links.dart';
import 'wide.dart';

/// Marks in the order they are looked for.
const formatMarks = ['**', '__', '++', '~~', '||', '`'];

final _link = RegExp(r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)');
final _bare = RegExp(r'''https?://[^\s<>()]+[^\s<>().,!?'"]''');

/// The text with all marks taken out (list previews, notifications, copy).
String plainText(String text) {
  var t = text.replaceAllMapped(_link, (m) => m.group(1)!);
  for (final k in formatMarks) {
    final e = RegExp.escape(k);
    t = t.replaceAllMapped(RegExp('$e(.+?)$e', dotAll: true), (m) => m.group(1)!);
  }
  return t.split('\n').map((l) => l.startsWith('> ') ? l.substring(2) : l).join('\n');
}

/// Wraps the selected part of [c] in [mark] (or adds a link).
void wrapSelection(TextEditingController c, String mark, {String? url}) {
  final sel = c.selection;
  if (!sel.isValid || sel.isCollapsed) return;
  final inner = sel.textInside(c.text);
  final repl = url != null ? '[$inner]($url)' : '$mark$inner$mark';
  c.value = TextEditingValue(
    text: sel.textBefore(c.text) + repl + sel.textAfter(c.text),
    selection: TextSelection.collapsed(offset: sel.start + repl.length),
  );
}

/// Formatted message text; spoilers open with a tap.
class FormattedText extends StatefulWidget {
  const FormattedText(this.text, {super.key, required this.style, required this.linkColor, required this.quoteColor, this.onPlan});
  final String text;

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
      if (m.start > at) out.addAll(plans(s.substring(at, m.start), st));
      final url = m.group(0)!;
      out.add(TextSpan(text: url, style: st.merge(linkStyle), recognizer: tap(() => open(url))));
      at = m.end;
    }
    if (at < s.length) out.addAll(plans(s.substring(at), st));
    return out;
  }

  /// Plain words, with found dates and times dotted-underlined.
  List<InlineSpan> plans(String s, TextStyle st) {
    final f = widget.onPlan;
    if (f == null) return [TextSpan(text: s, style: st)];
    final out = <InlineSpan>[];
    var at = 0;
    for (final h in findPlans(s, DateTime.now())) {
      if (h.start > at) out.add(TextSpan(text: s.substring(at, h.start), style: st));
      out.add(
        TextSpan(
          text: s.substring(h.start, h.end),
          style: st.merge(TextStyle(decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted, decorationColor: widget.linkColor)),
          recognizer: tap(() => f(h.at)),
        ),
      );
      at = h.end;
    }
    if (at < s.length) out.add(TextSpan(text: s.substring(at), style: st));
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
          out.addAll(inline(inner, st.copyWith(fontWeight: FontWeight.w600)));
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
    final spans = <InlineSpan>[];
    final lines = widget.text.split('\n');
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
