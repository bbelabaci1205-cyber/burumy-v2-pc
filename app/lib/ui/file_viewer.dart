// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 문서 바로 보기 (Telegram tip 473, batch #10, Eric 2026-11-27 "전부 만들기").
//
// Tap a file in a chat: Burumy decrypts it on the phone and shows it here.
// - PDF: drawn on the phone (PDFium inside the app, no website, no viewer
//   service), pages scroll, two fingers zoom, 찾기 highlights every match,
//   the page I was on is remembered.
// - Plain text (txt, csv, json, srt …) and photos sent as files: shown here.
// - Word / Excel / PowerPoint / 한글 / zip: a card says what it is and offers
//   다른 앱으로 열기 with a warning that the file leaves Burumy's encryption.
//   (iPhone's own Quick Look can draw Office files inside the app: needs a
//   real iPhone build, noted for the device test.)
// - ⌄ tucks the file away: a glass bar above the message box keeps up to 5
//   open files ("회비 정리.pdf 외 1개"); tap it for the stacked cards.
// - Chats with 공유 비활성화: no other apps, no saving, no text selection,
//   screen capture blocked.
// Decrypted bytes stay in memory only (core/open_docs.dart).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdfrx/pdfrx.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/downloads.dart';
import '../core/open_docs.dart';
import '../core/pdf_marks.dart';
import '../core/screen_guard.dart';
import '../core/phone.dart';
import '../core/storage_usage.dart';
import '../core/zip_peek.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChatVideo;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'saved_page.dart' show showPullDown;
import 'zip_view.dart';
import 'pdf_marks_page.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// The coloured square with the file's extension (Telegram / iOS Files).
/// Colours are iOS system colours by meaning: PDF red, documents blue,
/// sheets green, slides orange, text grey, archives indigo.
class FileTile extends StatelessWidget {
  const FileTile({super.key, required this.name, this.size = 44, this.child});
  final String name;
  final double size;

  /// Drawn over the tile (the download ring).
  final Widget? child;

  static Color colorOf(BuildContext context, FileKind k) => switch (k) {
    FileKind.pdf => Palette.tileRed,
    FileKind.word => Palette.tileBlue,
    FileKind.sheet => paletteOf(context).tileGreen,
    FileKind.slides => Palette.tileOrange,
    FileKind.archive => Palette.tileIndigo,
    FileKind.image || FileKind.video => Palette.tilePurple,
    FileKind.audio => Palette.tilePink,
    FileKind.text => Palette.tileGrey,
    FileKind.other => Palette.tileTeal,
  };

  @override
  Widget build(BuildContext context) {
    final ext = fileExt(name).toUpperCase();
    final label = ext.isEmpty ? '?' : (ext.length > 4 ? ext.substring(0, 4) : ext);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: colorOf(context, fileKindOf(name)),
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(size * 0.26)),
            ),
            child: Text(
              label,
              key: const Key('file-tile-ext'),
              style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: Tokens.semi, fontSize: size * (label.length > 3 ? 0.24 : 0.28)),
            ),
          ),
          ?child,
        ],
      ),
    );
  }
}

/// A file in a chat: tile, name, "1.2 MB · PDF", time. Tap opens it; while
/// it downloads the tile shows a ring with an X (tap = stop).
class FileBubble extends StatelessWidget {
  const FileBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta, this.protected = false});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final bool protected;

  @override
  Widget build(BuildContext context) {
    final name = msg.body ?? L.of(context).file;
    final size = msg.size == null || msg.size! <= 0 ? null : sizeText(msg.size!);
    final ext = fileExt(name).toUpperCase();
    return ListenableBuilder(
      listenable: Downloads.instance,
      builder: (context, _) {
        final running = Downloads.instance.isRunning(msg.fileId);
        return GestureDetector(
          key: Key('file-bubble-${msg.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: running ? () => Downloads.instance.cancel(AppScope.read(context), msg.fileId) : () => openFileMsg(context, roomId, msg, protected: protected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FileTile(
                  name: name,
                  child: running
                      ? Container(
                          key: const Key('file-downloading'),
                          width: 44,
                          height: 44,
                          decoration: ShapeDecoration(
                            color: const Color(0x66000000),
                            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(44 * 0.26)),
                          ),
                          child: const Stack(
                            alignment: Alignment.center,
                            children: [
                              CupertinoActivityIndicator(color: Color(0xFFFFFFFF), radius: 14),
                              Icon(CupertinoIcons.xmark, color: Color(0xFFFFFFFF), size: 12),
                            ],
                          ),
                        )
                      : null,
                ),
                SizedBox(width: Tokens.space[2]),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              [?size, if (ext.isNotEmpty) ext].join(' · '),
                              key: const Key('file-size'),
                              style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                            ),
                          ),
                          SizedBox(width: Tokens.space[2]),
                          meta,
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String mimeOfName(String name) => switch (fileExt(name)) {
  'pdf' => 'application/pdf',
  'txt' || 'log' || 'srt' || 'vtt' || 'ini' => 'text/plain',
  'md' => 'text/markdown',
  'csv' => 'text/csv',
  'json' => 'application/json',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  'gif' => 'image/gif',
  'webp' => 'image/webp',
  'doc' => 'application/msword',
  'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls' => 'application/vnd.ms-excel',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt' => 'application/vnd.ms-powerpoint',
  'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'hwp' => 'application/x-hwp',
  'zip' => 'application/zip',
  _ => 'application/octet-stream',
};

/// Opens a file message: from the open tabs if it is there, else it is
/// downloaded (encrypted copy kept by the Settings > Data rules) and shown.
Future<void> openFileMsg(BuildContext context, String roomId, Msg msg, {bool protected = false}) async {
  final name = msg.body ?? 'file';
  final kind = fileKindOf(name);
  if (kind == FileKind.video) return openChatVideo(context, roomId, msg);
  final open = OpenDocs.instance.find(msg.id);
  final nav = Navigator.of(context, rootNavigator: true);
  if (open != null) {
    OpenDocs.instance.add(open);
    await nav.push(IosPageRoute(fullscreenDialog: true, builder: (_) => FileViewerPage(doc: open)));
    return;
  }
  final s = AppScope.read(context);
  final l = L.of(context);
  try {
    final bytes = Uint8List.fromList(await Downloads.instance.get(s, roomId, msg));
    // Stopped with X: nothing to show.
    if (bytes.isEmpty || !context.mounted) return;
    final chat = s.chats.where((c) => c.roomId == roomId).map((c) => c.name).firstOrNull ?? '';
    final doc = OpenDoc(roomId: roomId, msg: msg, bytes: bytes, chat: chat, protected: protected);
    doc.page = DocPages.of(s, msg.id);
    // Only files Burumy draws itself become tabs.
    if (opensInApp(kind)) OpenDocs.instance.add(doc);
    await nav.push(IosPageRoute(fullscreenDialog: true, builder: (_) => FileViewerPage(doc: doc)));
  } catch (_) {
    if (context.mounted) showStoryToast(context, l.docFailed);
  }
}

/// The page I was on in each PDF (this phone only, last 100 files).
class DocPages {
  const DocPages._();
  static const keep = 100;

  static Map<String, dynamic> _all(AppState s) {
    try {
      final m = jsonDecode(s.pref('doc_pages', '{}'));
      return m is Map<String, dynamic> ? m : {};
    } catch (_) {
      return {};
    }
  }

  static int of(AppState s, String eventId) {
    final v = _all(s)[eventId];
    return v is int && v > 0 ? v : 1;
  }

  static Future<void> save(AppState s, String eventId, int page) async {
    final m = _all(s)..remove(eventId);
    if (page > 1) m[eventId] = page;
    final keys = m.keys.toList();
    if (keys.length > keep) {
      for (final k in keys.take(keys.length - keep)) {
        m.remove(k);
      }
    }
    await s.setPref('doc_pages', jsonEncode(m));
  }
}

class FileViewerPage extends StatefulWidget {
  const FileViewerPage({super.key, required this.doc});
  final OpenDoc doc;

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  final pdf = PdfViewerController();
  PdfTextSearcher? searcher;
  bool searching = false;
  final query = TextEditingController();
  final selectFocus = FocusNode();
  bool pdfFailed = false;
  double pull = 0;

  /// PDF 형광펜 (4-app board): my marks in this file, by page.
  List<PdfMark> marks = const [];
  Map<int, List<PdfMark>> marksByPage = const {};

  OpenDoc get doc => widget.doc;

  @override
  void initState() {
    super.initState();
    if (doc.kind == FileKind.pdf) {
      searcher = PdfTextSearcher(pdf)..addListener(onSearch);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (doc.kind == FileKind.pdf) loadMarks();
  }

  void loadMarks() {
    marks = PdfMarks.of(AppScope.read(context), doc.id);
    final by = <int, List<PdfMark>>{};
    for (final m in marks) {
      (by[m.page] ??= []).add(m);
    }
    marksByPage = by;
  }

  /// The words picked now become a mark (one box per line).
  Future<void> markSelection(PdfTextSelectionDelegate sel) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final ranges = await sel.getSelectedTextRanges();
    final now = DateTime.now();
    final made = <PdfMark>[];
    for (final (i, r) in ranges.indexed) {
      final chars = r.pageText.charRects;
      final end = r.end > chars.length ? chars.length : r.end;
      if (r.start >= end) continue;
      final rects = PdfMarks.lines([for (final c in chars.sublist(r.start, end)) (c.left, c.top, c.right, c.bottom)]);
      if (rects.isEmpty) continue;
      made.add(PdfMark(page: r.pageNumber, rects: rects, text: r.text, at: now.add(Duration(microseconds: i))));
    }
    await sel.clearTextSelection();
    if (made.isEmpty || !mounted) return;
    await PdfMarks.add(s, doc.id, made);
    if (!mounted) return;
    setState(loadMarks);
    showStoryToast(context, l.pdfMarkDone);
  }

  /// Draws the marks under the words (multiply, like a real highlighter).
  void paintMarks(ui.Canvas canvas, Rect pageRect, PdfPage page) {
    final on = marksByPage[page.pageNumber];
    if (on == null) return;
    final paint = Paint()
      ..color = pdfMarkColor.withValues(alpha: .55)
      ..blendMode = BlendMode.multiply;
    for (final m in on) {
      for (final (l, t, r, b) in m.rects) {
        final rect = PdfRect(l, t, r, b).toRect(page: page, scaledPageSize: pageRect.size).translate(pageRect.left, pageRect.top);
        canvas.drawRRect(RRect.fromRectAndRadius(rect.inflate(1), const Radius.circular(2)), paint);
      }
    }
  }

  Future<void> openMarks() async {
    final page = await Navigator.of(context).push<int>(IosPageRoute(builder: (_) => PdfMarksPage(doc: doc)));
    if (!mounted) return;
    setState(loadMarks);
    if (page != null) await pdf.goToPage(pageNumber: page);
  }

  void onSearch() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    searcher?.removeListener(onSearch);
    searcher?.dispose();
    query.dispose();
    selectFocus.dispose();
    super.dispose();
  }

  /// ⌄ : back to the chat, the file stays in the bar.
  void tuckAway() => Navigator.of(context).pop();

  void close() {
    OpenDocs.instance.close(doc.id);
    Navigator.of(context).pop();
  }

  Future<void> openOther() async {
    final l = L.of(context);
    if (doc.protected) {
      showStoryToast(context, l.docProtectedNoShare);
      return;
    }
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) => IosActionSheet(
        title: Text(l.docOpenOther),
        message: Text(l.docOpenOtherWarn),
        actions: [CupertinoActionSheetAction(key: const Key('doc-open-other-go'), onPressed: () => Navigator.pop(c, true), child: Text(l.docOpenOtherGo))],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    await Phone.share(bytes: doc.bytes, name: doc.name, mime: mimeOfName(doc.name), saveOnly: kIsWeb);
  }

  Future<void> more() async {
    final l = L.of(context);
    final pick = await showPullDown(context, [
      if (doc.kind == FileKind.pdf) ('find', l.docSearch, CupertinoIcons.search, false),
      if (doc.kind == FileKind.pdf && !doc.protected) ('marks', marks.isEmpty ? l.pdfMarksTitle : l.pdfMarks(marks.length), CupertinoIcons.pencil_outline, false),
      if (!doc.protected) ('other', l.docOpenOther, CupertinoIcons.square_arrow_up, false),
      ('close', l.close, CupertinoIcons.xmark, false),
    ]);
    if (!mounted) return;
    switch (pick) {
      case 'find':
        setState(() => searching = true);
      case 'marks':
        await openMarks();
      case 'other':
        await openOther();
      case 'close':
        close();
    }
  }

  void onPage(int? n) {
    if (n == null || n == doc.page) return;
    doc.page = n;
    final s = AppScope.read(context);
    unawaited(DocPages.save(s, doc.id, n));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final size = doc.msg.size ?? doc.bytes.length;
    final sub = [sizeText(size), if (doc.kind == FileKind.pdf && doc.pages > 0) l.docPage(doc.page, doc.pages)].join(' · ');
    final s = searcher;
    final bar = GlassTopBar(
      key: const Key('doc-top-bar'),
      tint: p.background,
      full: searching && s != null ? searchBar(context, s) : null,
      leading: [
        GlassCircle(
          key: const Key('doc-tuck'),
          onTap: opensInApp(doc.kind) ? tuckAway : close,
          child: GlassCircle.icon(context, opensInApp(doc.kind) ? CupertinoIcons.chevron_down : CupertinoIcons.xmark),
        ),
      ],
      trailing: [
        if (doc.kind == FileKind.pdf)
          GlassCircle(key: const Key('doc-find'), onTap: () => setState(() => searching = true), child: GlassCircle.icon(context, CupertinoIcons.search)),
        GlassCircle(key: const Key('doc-more'), onTap: more, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)),
      ],
      // Glass capsule like the chat title: name, then size · page.
      middle: LiquidGlass(
        radius: Tokens.capsule,
        flat: kIsWeb,
        child: Container(
          height: Tokens.closeButton,
          constraints: const BoxConstraints(minWidth: Tokens.titlePillMin),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                doc.name,
                key: const Key('doc-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.navTitle.style.copyWith(color: p.label),
              ),
              Text(
                sub,
                key: const Key('doc-sub'),
                maxLines: 1,
                style: Tokens.navSubtitle.style.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
    final page = CupertinoPageScaffold(
      key: const Key('doc-page'),
      backgroundColor: p.background,
      navigationBar: bar,
      child: GestureDetector(
        // Pull down from the very top (like Telegram) tucks the file away.
        onVerticalDragUpdate: doc.kind == FileKind.pdf ? null : (d) => pull += d.delta.dy,
        onVerticalDragEnd: doc.kind == FileKind.pdf
            ? null
            : (d) {
                if (pull > 120 || (d.primaryVelocity ?? 0) > 900) opensInApp(doc.kind) ? tuckAway() : close();
                pull = 0;
              },
        child: body(context),
      ),
    );
    return doc.protected ? CaptureBlock(what: 'file', child: page) : page;
  }

  Widget searchBar(BuildContext context, PdfTextSearcher s) {
    final p = paletteOf(context);
    final l = L.of(context);
    final total = s.matches.length;
    final at = s.currentIndex;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
      child: Row(
        children: [
          Expanded(
            child: CupertinoSearchTextField(
              key: const Key('doc-search-field'),
              controller: query,
              autofocus: true,
              placeholder: l.docSearch,
              onChanged: (t) => t.trim().isEmpty ? s.resetTextSearch() : s.startTextSearch(t.trim(), caseInsensitive: true),
              onSubmitted: (_) => s.goToNextMatch(),
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          Text(
            query.text.trim().isEmpty ? '' : (total == 0 ? (s.isSearching ? '…' : l.docSearchNone) : '${(at ?? 0) + 1}/$total'),
            key: const Key('doc-search-count'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
          CupertinoButton(
            key: const Key('doc-search-up'),
            padding: EdgeInsets.all(Tokens.space[1]),
            minimumSize: Size.zero,
            onPressed: total == 0 ? null : s.goToPrevMatch,
            child: const Icon(CupertinoIcons.chevron_up, size: 20),
          ),
          CupertinoButton(
            key: const Key('doc-search-down'),
            padding: EdgeInsets.all(Tokens.space[1]),
            minimumSize: Size.zero,
            onPressed: total == 0 ? null : s.goToNextMatch,
            child: const Icon(CupertinoIcons.chevron_down, size: 20),
          ),
          CupertinoButton(
            key: const Key('doc-search-cancel'),
            padding: EdgeInsets.only(left: Tokens.space[1]),
            minimumSize: Size.zero,
            onPressed: () {
              s.resetTextSearch();
              query.clear();
              setState(() => searching = false);
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  Widget body(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    switch (doc.kind) {
      case FileKind.pdf:
        if (pdfFailed) return notInApp(context, failed: true);
        final top = MediaQuery.paddingOf(context).top + GlassTopBar.height;
        return Stack(
          children: [
            Padding(
              // Pages start under the bar (they still scroll the whole way).
              padding: EdgeInsets.only(top: top),
              child: PdfViewer.data(
                doc.bytes,
                key: const Key('doc-pdf'),
                sourceName: 'burumy-${doc.id}',
                controller: pdf,
                initialPageNumber: doc.page,
                params: PdfViewerParams(
                  backgroundColor: p.background,
                  pageDropShadow: const BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2)),
                  textSelectionParams: PdfTextSelectionParams(enabled: !doc.protected),
                  pagePaintCallbacks: [paintMarks, ?searcher?.pageTextMatchPaintCallback],
                  // 형광펜 next to 복사 when words are picked.
                  customizeContextMenuItems: doc.protected
                      ? null
                      : (params, items) {
                          // 복사 · 전체 선택 in our words (not the English fallback).
                          final l = L.of(context);
                          for (var i = 0; i < items.length; i++) {
                            final label = switch (items[i].type) {
                              ContextMenuButtonType.copy => l.copy,
                              ContextMenuButtonType.selectAll => l.liveTextAll,
                              _ => null,
                            };
                            if (label != null && items[i].label == null) items[i] = items[i].copyWith(label: label);
                          }
                          if (!params.textSelectionDelegate.hasSelectedText) return;
                          items.insert(
                            0,
                            ContextMenuButtonItem(
                              label: l.pdfMarkAdd,
                              onPressed: () {
                                params.dismissContextMenu();
                                unawaited(markSelection(params.textSelectionDelegate));
                              },
                            ),
                          );
                        },
                  onPageChanged: onPage,
                  onViewerReady: (d, c) {
                    if (mounted) setState(() => doc.pages = d.pages.length);
                  },
                  errorBannerBuilder: (c, e, st, ref) => notInApp(c, failed: true),
                  loadingBannerBuilder: (c, got, total) => const Center(child: CupertinoActivityIndicator()),
                ),
              ),
            ),
            if (doc.pages > 0)
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[3],
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: LiquidGlass(
                      key: const Key('doc-page-pill'),
                      radius: Tokens.capsule,
                      flat: kIsWeb,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                        child: Text(
                          l.docPage(doc.page, doc.pages),
                          style: Tokens.caption.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case FileKind.text:
        final cut = doc.bytes.length > textViewMax;
        final text = utf8.decode(cut ? doc.bytes.sublist(0, textViewMax) : doc.bytes, allowMalformed: true);
        final mono = const ['csv', 'tsv', 'json', 'log', 'xml', 'yaml', 'yml', 'ini'].contains(fileExt(doc.name));
        final style = (mono ? Tokens.codeText : Tokens.body).style.copyWith(color: p.label);
        final list = ListView(
          key: const Key('doc-text'),
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[5]),
          children: [
            if (cut)
              Padding(
                padding: EdgeInsets.only(bottom: Tokens.space[2]),
                child: Text(l.docTextCut, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ),
            mono
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(text, style: style),
                  )
                : Text(text, style: style),
          ],
        );
        return SafeArea(
          // Words can be picked and copied, except in 공유 비활성화 chats.
          child: doc.protected
              ? list
              : SelectableRegion(
                  focusNode: selectFocus,
                  selectionControls: cupertinoTextSelectionHandleControls,
                  contextMenuBuilder: (c, st) =>
                      CupertinoAdaptiveTextSelectionToolbar.buttonItems(anchors: st.contextMenuAnchors, buttonItems: st.contextMenuButtonItems),
                  child: list,
                ),
        );
      case FileKind.image:
        return InteractiveViewer(
          key: const Key('doc-image'),
          maxScale: 6,
          child: Center(
            child: Image.memory(doc.bytes, fit: BoxFit.contain, errorBuilder: (c, e, st) => notInApp(c, failed: true)),
          ),
        );
      // ZIP 미리보기 (4-app board): what's inside, one file at a time.
      case FileKind.archive when ZipPeek.canPeek(doc.name):
        return ZipView(doc: doc, fallback: (c) => notInApp(c));
      default:
        return notInApp(context);
    }
  }

  /// Word / Excel / 한글 / zip …: what it is and 다른 앱으로 열기.
  Widget notInApp(BuildContext context, {bool failed = false}) {
    final p = paletteOf(context);
    final l = L.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[4]),
          child: Column(
            key: const Key('doc-not-in-app'),
            mainAxisSize: MainAxisSize.min,
            children: [
              FileTile(name: doc.name, size: 72),
              SizedBox(height: Tokens.space[3]),
              Text(
                doc.name,
                textAlign: TextAlign.center,
                style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: Tokens.space[0]),
              Text(sizeText(doc.msg.size ?? doc.bytes.length), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              SizedBox(height: Tokens.space[4]),
              Text(
                failed ? l.docFailed : l.docNoInApp,
                textAlign: TextAlign.center,
                style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
              ),
              SizedBox(height: Tokens.space[1]),
              Text(
                doc.protected ? l.docProtectedNoShare : l.docNoInAppHint,
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
              ),
              if (!doc.protected) ...[
                SizedBox(height: Tokens.space[4]),
                CupertinoButton.filled(
                  key: const Key('doc-open-other'),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: openOther,
                  child: Text(l.docOpenOther),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The glass bar above the message box while files are tucked away:
/// "회비 정리.pdf 외 1개". Tap = one file opens / several = stacked cards.
class DocTabsBar extends StatelessWidget {
  const DocTabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OpenDocs.instance,
      builder: (context, _) {
        final docs = OpenDocs.instance.docs;
        if (docs.isEmpty) return const SizedBox.shrink();
        final p = paletteOf(context);
        final l = L.of(context);
        final first = docs.first;
        return Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
          child: GestureDetector(
            key: const Key('doc-tabs-bar'),
            onTap: () => docs.length == 1 ? reopen(context, first) : showDocTabs(context),
            child: LiquidGlass(
              radius: Tokens.capsule,
              flat: kIsWeb,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                child: Row(
                  children: [
                    FileTile(name: first.name, size: 28),
                    SizedBox(width: Tokens.space[2]),
                    Expanded(
                      child: Text(
                        docs.length == 1 ? first.name : l.docTabsMore(first.name, docs.length - 1),
                        key: const Key('doc-tabs-label'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (first.kind == FileKind.pdf && first.pages > 0)
                      Padding(
                        padding: EdgeInsets.only(left: Tokens.space[1]),
                        child: Text(l.docPage(first.page, first.pages), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      ),
                    GestureDetector(
                      key: const Key('doc-tabs-close'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => docs.length == 1 ? OpenDocs.instance.close(first.id) : OpenDocs.instance.clear(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                        child: Icon(CupertinoIcons.xmark, size: 16, color: p.secondaryLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<void> reopen(BuildContext context, OpenDoc d) {
  OpenDocs.instance.add(d);
  return Navigator.of(context, rootNavigator: true).push(IosPageRoute(fullscreenDialog: true, builder: (_) => FileViewerPage(doc: d)));
}

/// The open files as stacked cards (newest in front, like Telegram's tabs).
Future<void> showDocTabs(BuildContext context) async {
  final pick = await showCupertinoModalPopup<OpenDoc>(context: context, useRootNavigator: !Wide.on, builder: (c) => const _DocTabsSheet());
  if (pick != null && context.mounted) await reopen(context, pick);
}

class _DocTabsSheet extends StatelessWidget {
  const _DocTabsSheet();

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ListenableBuilder(
      listenable: OpenDocs.instance,
      builder: (context, _) {
        final docs = OpenDocs.instance.docs;
        if (docs.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
        }
        return Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
          child: ClipRSuperellipse(
            borderRadius: BorderRadius.circular(IosActionSheet.radius),
            child: ColoredBox(
              color: p.background,
              child: Column(
                key: const Key('doc-tabs-sheet'),
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[1], Tokens.space[1]),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.docTabsTitle,
                            style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                          ),
                        ),
                        CupertinoButton(
                          key: const Key('doc-tabs-close-all'),
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                          onPressed: OpenDocs.instance.clear,
                          child: Text(l.docTabsCloseAll, style: Tokens.preview.style.copyWith(color: p.accent)),
                        ),
                      ],
                    ),
                  ),
                  // Stacked: each card overlaps the one behind it a little.
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[3]),
                    child: Column(
                      children: [
                        for (final (i, d) in docs.indexed)
                          Transform.translate(
                            offset: Offset(0, -i * 6.0),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: i * 4.0),
                              child: _DocCard(doc: d, onTap: () => Navigator.pop(context, d)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({required this.doc, required this.onTap});
  final OpenDoc doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final where = [
      if (doc.chat.isNotEmpty) doc.chat,
      if (doc.kind == FileKind.pdf && doc.pages > 0) l.docPage(doc.page, doc.pages) else sizeText(doc.msg.size ?? doc.bytes.length),
    ].join(' · ');
    return Dismissible(
      key: Key('doc-card-${doc.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => OpenDocs.instance.close(doc.id),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: Tokens.space[1]),
          padding: EdgeInsets.all(Tokens.space[2]),
          decoration: ShapeDecoration(
            color: p.card,
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[2])),
            shadows: const [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              FileTile(name: doc.name),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.listName.style.copyWith(color: p.label),
                    ),
                    Text(
                      where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                key: Key('doc-card-close-${doc.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => OpenDocs.instance.close(doc.id),
                child: Padding(
                  padding: EdgeInsets.all(Tokens.space[1]),
                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 22, color: p.chevron),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
