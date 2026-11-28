// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PDF 형광펜 (4-app board): the list of what I marked in one PDF. Tap a
// mark to jump to its page; 지우기 waits 5 seconds (되돌리기); 대화에 보내기
// sends the marked words, with their pages, to the chat the PDF came from.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/open_docs.dart';
import '../core/pdf_marks.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;

/// The yellow of the marks (iOS highlighter).
const pdfMarkColor = Color(0xFFFFD60A);

/// The words as one message: "회비 정리.pdf에서 표시한 부분", then each
/// mark with its page.
String pdfMarksMessage(L l, String name, List<PdfMark> marks) => [
  l.pdfMarksQuote(name),
  for (final m in marks) '${l.pdfMarkPage(m.page)} · “${m.text.trim()}”',
].join('\n\n');

class PdfMarksPage extends StatefulWidget {
  const PdfMarksPage({super.key, required this.doc});
  final OpenDoc doc;

  @override
  State<PdfMarksPage> createState() => _PdfMarksPageState();
}

class _PdfMarksPageState extends State<PdfMarksPage> {
  /// Waiting out the 5 seconds: hidden here, still kept.
  final going = <String>{};
  bool sending = false;

  void letGo(PdfMark m) {
    final l = L.of(context);
    final s = AppScope.read(context);
    setState(() => going.add(m.id));
    showUndoCountdown(
      context,
      (n) => l.pdfMarkGoing(n),
      () async {
        await PdfMarks.remove(s, widget.doc.id, {m.id});
        if (mounted) setState(() => going.remove(m.id));
      },
      onUndo: () {
        if (mounted) setState(() => going.remove(m.id));
      },
    );
  }

  Future<void> send(List<PdfMark> marks) async {
    if (sending || marks.isEmpty) return;
    final l = L.of(context);
    final s = AppScope.read(context);
    setState(() => sending = true);
    await s.backend.sendText(widget.doc.roomId, pdfMarksMessage(l, widget.doc.name, marks));
    unawaited(s.refresh());
    if (!mounted) return;
    showStoryToast(context, l.pdfMarksSent);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final marks = [
      for (final m in PdfMarks.of(s, widget.doc.id))
        if (!going.contains(m.id)) m,
    ];
    return SettingsScaffold(
      title: l.pdfMarksTitle,
      children: [
        group(context, footer: l.pdfMarksInfo, [
          if (marks.isEmpty) IosTile(title: Text(l.pdfMarksHow, style: TextStyle(color: p.secondaryLabel))),
          for (final m in marks)
            IosTile(
              key: Key('pdf-mark-${m.id}'),
              leading: Container(
                width: 6,
                height: 30,
                decoration: BoxDecoration(color: pdfMarkColor, borderRadius: BorderRadius.circular(3)),
              ),
              title: Text(m.text.trim(), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(l.pdfMarkPage(m.page)),
              trailing: GestureDetector(
                key: Key('pdf-mark-del-${m.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => letGo(m),
                child: Padding(
                  padding: EdgeInsets.all(Tokens.space[1]),
                  child: Icon(CupertinoIcons.trash, size: 20, color: p.secondaryLabel),
                ),
              ),
              // Back to the PDF, on that page.
              onTap: () => Navigator.of(context).pop(m.page),
            ),
        ]),
        if (marks.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[3], Tokens.space[3] + Tokens.space[0], 0),
            child: AccentButton(key: const Key('pdf-marks-send'), text: l.pdfMarksSend, onTap: () => send(marks)),
          ),
      ],
    );
  }
}
