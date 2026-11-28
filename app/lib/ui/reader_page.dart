// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 읽기 모드 screen (tip 475): the article picked out by core/reader.dart,
// in our own reading layout (doc_view.dart reading-page sizes: title 28/34
// w600, headings 22/28, body 17/22 by default, 16 side margins), with a
// text size choice (Aa), the AI summary on top (tip 554, phone AI only) and
// "브라우저로 열기" for the original page.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/ai_local.dart';
import '../core/app_state.dart';
import '../core/reader.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart' show paletteOf;
import 'ai_age_ui.dart';
import 'glass.dart';
import 'links.dart';
import 'post_summary.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// Opens [url] in 읽기 모드.
Future<void> openReader(BuildContext context, String url) => openSheet<void>(context, (_) => ReaderPage(url: url));

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.url});
  final String url;

  /// Body text sizes for the Aa choice (17 = iOS body, the default).
  static const sizes = [15.0, 17.0, 19.0, 22.0, 26.0];
  static const sizePref = 'reader_size';

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final Future<Article?> article = Reader.open(widget.url);
  bool summaryBusy = false, summaryOpen = false, summaryFailed = false;
  String? summary;

  int sizeIndex(AppState s) => (int.tryParse(s.pref(ReaderPage.sizePref, '1')) ?? 1).clamp(0, ReaderPage.sizes.length - 1);

  @override
  void initState() {
    super.initState();
    if (LocalAi.known == null) unawaited(LocalAi.status().then((_) => mounted ? setState(() {}) : null));
  }

  Future<void> summarize(Article a) async {
    if (summary != null) return setState(() => summaryOpen = !summaryOpen);
    if (!await aiAgeOk(context) || !mounted) return;
    final s = AppScope.read(context);
    setState(() {
      summaryBusy = true;
      summaryFailed = false;
    });
    final lang = (s.locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'en' ? 'English' : 'Korean';
    try {
      summary = (await LocalAi.run(rules: PostSummary.rules(lang), text: PostSummary.input('${a.title}\n${a.text}'))).trim();
      summaryOpen = true;
    } catch (_) {
      summaryFailed = true;
    }
    if (mounted) setState(() => summaryBusy = false);
  }

  Future<void> pickSize() async {
    final s = AppScope.read(context);
    await showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) {
          final p = paletteOf(c);
          final l = L.of(c);
          final i = sizeIndex(s);
          return SafeArea(
            top: false,
            child: Container(
              key: const Key('reader-size-sheet'),
              margin: EdgeInsets.all(Tokens.space[1]),
              padding: EdgeInsets.all(Tokens.space[3]),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.readerTextSize,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                  SizedBox(height: Tokens.space[2]),
                  Row(
                    children: [
                      Text('A', style: TextStyle(fontSize: 14, color: p.secondaryLabel)),
                      Expanded(
                        child: CupertinoSlider(
                          key: const Key('reader-size'),
                          value: i.toDouble(),
                          max: (ReaderPage.sizes.length - 1).toDouble(),
                          divisions: ReaderPage.sizes.length - 1,
                          activeColor: p.accent,
                          onChanged: (v) {
                            unawaited(s.setPref(ReaderPage.sizePref, '${v.round()}'));
                            set(() {});
                            setState(() {});
                          },
                        ),
                      ),
                      Text('A', style: TextStyle(fontSize: 24, color: p.secondaryLabel)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final host = Uri.tryParse(widget.url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
    return CupertinoPageScaffold(
      key: const Key('reader-page'),
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar(
        title: host,
        tint: p.chatBackground,
        leading: const [GlassBack(key: Key('reader-close'), close: true)],
        trailing: [
          GlassCircle(key: const Key('reader-aa'), onTap: pickSize, child: GlassCircle.icon(context, CupertinoIcons.textformat_size)),
          GlassCircle(
            key: const Key('reader-browser'),
            onTap: () => openWebLink(context, widget.url),
            child: GlassCircle.icon(context, CupertinoIcons.compass),
          ),
        ],
      ),
      child: FutureBuilder<Article?>(
        future: article,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CupertinoActivityIndicator(),
                  SizedBox(height: Tokens.space[2]),
                  Text(l.readerLoading, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            );
          }
          final a = snap.data;
          if (a == null) return failed(context);
          return body(context, a, ReaderPage.sizes[sizeIndex(s)]);
        },
      ),
    );
  }

  Widget failed(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Tokens.space[4]),
        child: Column(
          key: const Key('reader-failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/brand/symbol_green.png', width: 64, color: p.accent.withValues(alpha: 0.35), colorBlendMode: BlendMode.srcIn),
            SizedBox(height: Tokens.space[3]),
            Text(
              l.readerFailed,
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.secondaryLabel),
            ),
            SizedBox(height: Tokens.space[3]),
            CupertinoButton.filled(
              key: const Key('reader-failed-browser'),
              onPressed: () {
                Navigator.pop(context);
                unawaited(openWebLink(context, widget.url));
              },
              child: Text(l.readerOpenBrowser),
            ),
          ],
        ),
      ),
    );
  }

  Widget body(BuildContext context, Article a, double size) {
    final l = L.of(context);
    final p = paletteOf(context);
    final scale = size / 17;
    final text = TextStyle(fontSize: size, height: 1.5, color: p.label);
    final firstPicture = a.blocks.where((b) => b.kind == 'img').firstOrNull?.src;
    Widget picture(String src, String caption) => Padding(
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: src.startsWith('asset:')
                ? Image.asset(src.substring(6), fit: BoxFit.cover, width: double.infinity)
                : Image.network(src, fit: BoxFit.cover, width: double.infinity, errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
          if (caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[0]),
              child: Text(caption, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
        ],
      ),
    );
    final children = <Widget>[
      Text(
        '${a.site} · ${l.readerMinutes(a.minutes)}',
        key: const Key('reader-meta'),
        style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
      ),
      SizedBox(height: Tokens.space[1]),
      Text(
        a.title,
        key: const Key('reader-title'),
        style: Tokens.screenTitle.style.copyWith(color: p.label, fontSize: 28 * scale.clamp(0.9, 1.3), height: 34 / 28),
      ),
      if (a.byline != null) ...[SizedBox(height: Tokens.space[1]), Text(a.byline!, style: Tokens.preview.style.copyWith(color: p.secondaryLabel))],
      if (a.image != null && a.image != firstPicture) picture(a.image!, ''),
      if (LocalAi.onPhone && s(context).on(PostSummary.pref, fallback: true)) summaryBox(context, a),
      SizedBox(height: Tokens.space[2]),
    ];
    String? lastHeading;
    var prev = '';
    for (final b in a.blocks) {
      // A little air after a list.
      if (prev == 'li' && b.kind != 'li') children.add(SizedBox(height: Tokens.space[1]));
      prev = b.kind;
      switch (b.kind) {
        case 'h':
          if (b.text == lastHeading) continue;
          lastHeading = b.text;
          children.add(
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[4], bottom: Tokens.space[1]),
              child: Text(
                b.text,
                style: Tokens.cardTitle.style.copyWith(color: p.label, fontWeight: FontWeight.w600, fontSize: 22 * scale.clamp(0.9, 1.3)),
              ),
            ),
          );
        case 'quote':
          children.add(
            Container(
              margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
              padding: EdgeInsets.only(left: Tokens.space[2]),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: p.accent, width: 3)),
              ),
              child: Text(b.text, style: text.copyWith(color: p.secondaryLabel)),
            ),
          );
        case 'li':
          children.add(
            Padding(
              padding: EdgeInsets.only(bottom: Tokens.space[0], left: Tokens.space[1]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: text.copyWith(color: p.accent)),
                  Expanded(child: Text(b.text, style: text)),
                ],
              ),
            ),
          );
        case 'code':
          children.add(
            Container(
              margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
              padding: EdgeInsets.all(Tokens.space[2]),
              decoration: BoxDecoration(color: p.label.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Tokens.radius[1])),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  b.text,
                  style: Tokens.codeText.style.copyWith(color: p.label, fontFamily: 'monospace'),
                ),
              ),
            ),
          );
        case 'img':
          children.add(picture(b.src!, b.text));
        default:
          children.add(
            Padding(
              padding: EdgeInsets.only(bottom: Tokens.space[2]),
              child: Text(b.text, style: text),
            ),
          );
      }
    }
    children.addAll([
      SizedBox(height: Tokens.space[3]),
      Container(height: 0.5, color: p.separator),
      SizedBox(height: Tokens.space[2]),
      Text(
        l.readerFootnote,
        key: const Key('reader-footnote'),
        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
      ),
      CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        onPressed: () => openWebLink(context, widget.url),
        child: Text(
          l.readerOpenBrowser,
          style: Tokens.preview.style.copyWith(color: p.accent, fontWeight: FontWeight.w500),
        ),
      ),
      GestureDetector(
        onLongPress: () {
          unawaited(Clipboard.setData(ClipboardData(text: widget.url)));
          showStoryToast(context, l.readerLinkCopied);
        },
        child: Text(
          widget.url,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
        ),
      ),
    ]);
    return SafeArea(
      child: ListView(
        key: const Key('reader-list'),
        padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[5]),
        children: children,
      ),
    );
  }

  AppState s(BuildContext context) => AppScope.of(context);

  Widget summaryBox(BuildContext context, Article a) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.only(top: Tokens.space[2]),
      child: Container(
        key: const Key('reader-summary'),
        width: double.infinity,
        padding: EdgeInsets.all(Tokens.space[2]),
        decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              key: const Key('reader-summary-open'),
              behavior: HitTestBehavior.opaque,
              onTap: summaryBusy ? null : () => summarize(a),
              child: Row(
                children: [
                  Icon(CupertinoIcons.sparkles, size: 18, color: p.accent),
                  SizedBox(width: Tokens.space[1]),
                  Expanded(
                    child: Text(
                      summaryBusy ? l.postSummaryBusy : (summaryOpen ? l.postSummaryTitle : l.readerSummaryAsk),
                      style: Tokens.body.style.copyWith(color: p.accent, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (summaryBusy) const CupertinoActivityIndicator(radius: 8),
                  if (!summaryBusy && summary != null)
                    Icon(summaryOpen ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 16, color: p.secondaryLabel),
                ],
              ),
            ),
            if (summaryFailed) ...[SizedBox(height: Tokens.space[1]), Text(l.postSummaryFailed, style: Tokens.preview.style.copyWith(color: p.secondaryLabel))],
            if (summaryOpen && summary != null) ...[
              SizedBox(height: Tokens.space[1]),
              Text(
                summary!,
                key: const Key('reader-summary-text'),
                style: Tokens.body.style.copyWith(color: p.label),
              ),
              SizedBox(height: Tokens.space[0]),
              Text(l.postSummaryOnPhone, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ],
          ],
        ),
      ),
    );
  }
}
