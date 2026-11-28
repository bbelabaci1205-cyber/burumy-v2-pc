// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Draws a document (core/doc.dart): the one renderer for long posts, short
// formatted messages, on-device AI answers and bots. Only the known block
// types are drawn; everything else was dropped when the document was
// checked. Wide things (tables, code, formulas) scroll sideways instead of
// squeezing, like iOS Notes.
//
// Sizes (rulebook D + iOS 27 Notes, tokens only):
//   reading page  title 28/34 w600 (screenTitle), h1 22/28 (cardTitle) w600,
//                 h2 17/22 semi, body 17/22, 16 side margin, 12 between
//                 blocks, 24 before a heading.
//   in a bubble   title 22/28 (cardTitle), h1 17/22 semi, h2 15/20 semi,
//                 body 17/22, 8 between blocks, 12 before a heading.
//   quote         3pt side bar in the accent colour, 12 in.
//   pull quote    22/28 italic, accent colour, centred, hairlines above/below.
//   code / table  corner 10, fill = text colour at 6%, cell 8x12, hairline
//                 grid = text colour at 15%, header row semi on 4% fill.
//   photo         corner 10, caption 13/18 secondary.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../core/doc.dart';
import '../design/tokens.dart';
import 'code_block.dart';
import 'formatting.dart';

/// Loads (downloads + decrypts) one photo of a document.
typedef DocImageLoader = Future<List<int>> Function(Json file);

class DocView extends StatelessWidget {
  const DocView({
    super.key,
    required this.doc,
    required this.fg,
    required this.accent,
    this.compact = false,
    this.loadImage,
    this.maxBlocks,
    this.showTitle = true,
  });
  final Doc doc;

  /// Text colour (bubble ink, or the page label colour).
  final Color fg;
  final Color accent;

  /// Inside a chat bubble (smaller headings, tighter gaps).
  final bool compact;
  final DocImageLoader? loadImage;

  /// Draw only the first N blocks (bubble preview of a long post).
  final int? maxBlocks;
  final bool showTitle;

  double get gap => compact ? Tokens.space[1] : Tokens.space[2];
  double get headGap => compact ? Tokens.space[2] : Tokens.space[4];

  TextStyle get body => Tokens.body.style.copyWith(color: fg);

  TextStyle headStyle(String t) => switch (t) {
    'title' => (compact ? Tokens.cardTitle : Tokens.screenTitle).style.copyWith(color: fg, fontWeight: Tokens.semi),
    'h1' => (compact ? Tokens.body : Tokens.cardTitle).style.copyWith(color: fg, fontWeight: Tokens.semi),
    _ => (compact ? Tokens.preview : Tokens.body).style.copyWith(color: fg, fontWeight: Tokens.semi),
  };

  Widget text(String s, TextStyle st) => FormattedText(s, style: st, linkColor: accent, quoteColor: accent);

  @override
  Widget build(BuildContext context) {
    final blocks = maxBlocks == null ? doc.blocks : doc.blocks.take(maxBlocks!).toList();
    final kids = <Widget>[];
    if (showTitle && doc.title.trim().isNotEmpty) {
      kids.add(Text(doc.title.trim(), key: const Key('doc-title'), style: headStyle('title')));
    }
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final heading = b.t == 'h1' || b.t == 'h2';
      if (kids.isNotEmpty) kids.add(SizedBox(height: heading ? headGap : gap));
      kids.add(KeyedSubtree(key: Key('doc-block-$i'), child: block(context, b)));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: kids);
  }

  Widget block(BuildContext context, DocBlock b) {
    final line = fg.withValues(alpha: 0.15);
    switch (b.t) {
      case 'h1' || 'h2':
        return text(b.text, headStyle(b.t));
      case 'quote':
        return Container(
          padding: EdgeInsets.only(left: Tokens.space[2]),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          child: text(b.text, body.copyWith(color: fg.withValues(alpha: 0.85))),
        );
      case 'pull':
        return Container(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[2], horizontal: Tokens.space[3]),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: line, width: 1)),
          ),
          child: DefaultTextStyle.merge(
            textAlign: TextAlign.center,
            child: text(b.text, (compact ? Tokens.body : Tokens.cardTitle).style.copyWith(color: accent, fontStyle: FontStyle.italic)),
          ),
        );
      case 'code':
        // Same code box as chat messages (tip 411): language, colours, copy.
        return CodeBlockView(code: b.text, lang: b.lang, fg: fg, accent: accent);
      case 'math':
        return _Wide(
          center: true,
          child: Math.tex(
            b.text,
            mathStyle: MathStyle.display,
            textStyle: body.copyWith(fontSize: body.fontSize! * 1.1),
            onErrorFallback: (_) => Text(b.text, style: body.copyWith(fontFamily: 'monospace')),
          ),
        );
      case 'ul' || 'ol':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < b.items.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : Tokens.space[0]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: b.t == 'ol' ? 28 : 18,
                      child: Text(b.t == 'ol' ? '${b.start + i}.' : '•', style: body.copyWith(color: b.t == 'ul' ? accent : fg)),
                    ),
                    Expanded(child: text(b.items[i], body)),
                  ],
                ),
              ),
          ],
        );
      case 'table':
        return _Table(rows: b.rows, head: b.head, fg: fg, line: line, accent: accent, compact: compact);
      case 'img':
        return _Photo(block: b, fg: fg, loadImage: loadImage);
      case 'hr':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
          child: Container(height: 1, color: line),
        );
      default:
        return text(b.text, body);
    }
  }
}

/// Sideways-scrolling box for formulas (code: [CodeBlockView]).
class _Wide extends StatelessWidget {
  const _Wide({required this.child, this.center = false});
  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final box = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: child,
    );
    return LayoutBuilder(
      builder: (context, c) => Container(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: c.maxWidth),
          child: box,
        ),
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.rows, required this.head, required this.fg, required this.line, required this.accent, required this.compact});
  final List<List<String>> rows;
  final bool head, compact;
  final Color fg, line, accent;

  @override
  Widget build(BuildContext context) {
    final st = (compact ? Tokens.preview : Tokens.body).style.copyWith(color: fg);
    final cols = rows.isEmpty ? 0 : rows.first.length;
    // The frame hugs the table (no empty strip when it is narrower than
    // the bubble) and the table scrolls sideways when it is wider.
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        key: const Key('doc-table-scroll'),
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius[1]),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: line, borderRadius: BorderRadius.circular(Tokens.radius[1])),
            children: [
              for (var r = 0; r < rows.length; r++)
                TableRow(
                  decoration: r == 0 && head ? BoxDecoration(color: fg.withValues(alpha: 0.04)) : null,
                  children: [
                    for (var c = 0; c < cols; c++)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 64, maxWidth: 240),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: Tokens.space[1], horizontal: Tokens.space[2]),
                          child: FormattedText(
                            c < rows[r].length ? rows[r][c] : '',
                            style: r == 0 && head ? st.copyWith(fontWeight: Tokens.semi) : st,
                            linkColor: accent,
                            quoteColor: accent,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatefulWidget {
  const _Photo({required this.block, required this.fg, this.loadImage});
  final DocBlock block;
  final Color fg;
  final DocImageLoader? loadImage;

  @override
  State<_Photo> createState() => _PhotoState();
}

/// Decrypted photos kept while the app runs (never written to disk).
final _photoCache = <String, Uint8List>{};

class _PhotoState extends State<_Photo> {
  Uint8List? bytes;
  bool failed = false;

  String? get key => widget.block.file?['url'] as String?;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final b = widget.block;
    if (b.local != null) {
      bytes = Uint8List.fromList(b.local!);
      return;
    }
    final k = key;
    if (k == null || widget.loadImage == null) return;
    if (_photoCache[k] != null) {
      bytes = _photoCache[k];
      return;
    }
    try {
      final got = Uint8List.fromList(await widget.loadImage!(b.file!));
      if (_photoCache.length > 60) _photoCache.remove(_photoCache.keys.first);
      _photoCache[k] = got;
      if (mounted) setState(() => bytes = got);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    final ratio = b.w > 0 && b.h > 0 ? (b.w / b.h).clamp(0.5, 2.5) : 4 / 3;
    final fill = widget.fg.withValues(alpha: 0.06);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius[1]),
          child: AspectRatio(
            aspectRatio: ratio.toDouble(),
            child: bytes != null
                ? Image.memory(
                    bytes!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => ColoredBox(color: fill),
                  )
                : ColoredBox(
                    color: fill,
                    child: Center(child: failed ? Icon(CupertinoIcons.photo, color: widget.fg.withValues(alpha: 0.4)) : const CupertinoActivityIndicator()),
                  ),
          ),
        ),
        if (b.text.trim().isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[1]),
            child: Text(b.text, style: Tokens.caption.style.copyWith(color: widget.fg.withValues(alpha: 0.6))),
          ),
      ],
    );
  }
}
