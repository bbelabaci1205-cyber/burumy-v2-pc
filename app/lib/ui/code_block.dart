// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 코드 블록 (Telegram tip 411): a ``` block in a message is drawn as a box
// with the language name on top ("python"), coloured code (core/
// code_colors.dart, Xcode colours), and a copy button at the top right
// ("코드를 복사했어요"). Long lines scroll sideways instead of wrapping, so
// the code keeps its shape. Used in chat bubbles and in long posts (573).
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/code_colors.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart' show paletteOf;

class CodeBlockView extends StatelessWidget {
  const CodeBlockView({super.key, required this.code, this.lang = '', required this.fg, required this.accent, this.inset = false, this.onCopied});
  final String code;
  final String lang;

  /// Ink colour around the box (bubble text colour).
  final Color fg;
  final Color accent;

  /// On my own (accent-coloured) bubble: a card-coloured box so the code
  /// colours stay readable.
  final bool inset;

  /// Tells the screen to show "코드를 복사했어요" its own way; without it a
  /// small banner shows.
  final ValueChanged<String>? onCopied;

  Future<void> copy(BuildContext context) async {
    final l = L.of(context);
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    if (onCopied != null) {
      onCopied!(l.codeBlockCopied);
    } else {
      showInfoBanner(context, l.codeBlockCopied, '', icon: CupertinoIcons.doc_on_doc_fill);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final ink = inset ? p.label : fg;
    final head = inset ? p.accent : accent;
    final label = codeLangLabel(lang);
    final base = Tokens.codeText.style.copyWith(
      fontFamily: Tokens.codeFonts.first,
      fontFamilyFallback: [...Tokens.codeFonts.skip(1), ...Tokens.emojiFallback],
      color: ink,
    );
    Color colourOf(CodePart part) => switch (part) {
      CodePart.keyword => p.codeKeyword,
      CodePart.string => p.codeString,
      CodePart.comment => p.codeComment,
      CodePart.number => p.codeNumber,
      CodePart.type => p.codeType,
      CodePart.function => p.codeFunction,
      CodePart.plain => ink,
    };
    // On others' bubbles the theme colours are made for the plain page; on
    // the grey bubble they still read. Keywords also get the semi weight.
    final spans = [
      for (final s in colourCode(code, lang))
        TextSpan(
          text: s.text,
          style: TextStyle(
            color: colourOf(s.part),
            fontWeight: s.part == CodePart.keyword ? Tokens.semi : null,
            fontStyle: s.part == CodePart.comment ? FontStyle.italic : null,
          ),
        ),
    ];
    return Container(
      key: const Key('code-block'),
      margin: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
      decoration: BoxDecoration(
        color: inset ? p.codeInset : fg.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(Tokens.radius[1]),
        border: Border(left: BorderSide(color: head, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: Tokens.codeHeader + Tokens.space[0],
            child: Row(
              children: [
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Text(
                    label,
                    key: const Key('code-lang'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.caption.style.copyWith(color: head, fontWeight: Tokens.semi),
                  ),
                ),
                Semantics(
                  button: true,
                  label: L.of(context).codeBlockCopy,
                  child: CupertinoButton(
                    key: const Key('code-copy'),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                    minimumSize: const Size(44, 30),
                    onPressed: () => copy(context),
                    child: Icon(CupertinoIcons.doc_on_doc, size: Tokens.codeCopy, color: head),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            key: const Key('code-scroll'),
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
            child: Text.rich(
              TextSpan(style: base, children: spans),
              key: const Key('code-text'),
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }
}
