// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Long posts ("긴 글"): the bubble in the chat, the full reading page and the
// full-screen editor. The document format and its limits are in
// core/doc.dart; drawing is ui/doc_view.dart (shared with short formatted
// messages, AI answers and bots).
//
// Editor layout (Telegram 2026 article editor for placement, iOS 27 for
// detail; Eric approved 2026-11-27):
//   top     round glass close (left), undo / redo glass circles (right)
//   body    title 28/34, then blocks; 16 side margin, 12 between blocks
//   bottom  glass tool bar 44 tall above the keyboard:
//           AI · + · Aa · list · table · link · photo ............ send circle
// Encryption: photos are encrypted on the phone before upload; the
// document goes inside the encrypted card or, when long, as an encrypted
// file whose key travels only inside the encrypted card.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../brand/mark.dart';
import '../core/ai_local.dart';
import '../core/ai_styles.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/doc.dart';
import '../core/strip_meta.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show LinkEditPage;
import 'common.dart';
import 'doc_view.dart';
import 'formatting.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'wide.dart';
import 'ai_age_ui.dart';

/// On-device AI writing. Returns null when the phone can't do it. [style]
/// is "polish" or "shorter".
typedef ArticleAiRewrite = Future<String?> Function(String text, String style);

/// Tests swap the photo picker.
class ArticleEditorTest {
  static Future<List<(String, List<int>)>> Function()? picker;
}

class ArticleAi {
  /// Tests swap this; null = the phone's built-in model (core/ai_local.dart:
  /// Apple's model on iPhone, Gemini Nano on Android; never leaves the phone).
  static ArticleAiRewrite? rewrite;

  static const rules = {
    'polish':
        'Rewrite so it reads naturally and clearly. Keep the meaning, the language and any marks like **bold** or [text](link). Reply with the text only.',
    'shorter': 'As short as possible. Keep only what matters, in the same language. Keep marks like **bold**. Reply with the text only.',
  };

  /// The phone's model takes about [AiStyles.maxText] characters at a time,
  /// so longer text goes paragraph by paragraph.
  static Future<String?> onPhone(String text, String style) async {
    if (!await LocalAi.available()) return null;
    final parts = <String>[];
    var cur = '';
    for (final para in text.split('\n\n')) {
      if (cur.isNotEmpty && cur.length + para.length + 2 > AiStyles.maxText) {
        parts.add(cur);
        cur = '';
      }
      cur = cur.isEmpty ? para : '$cur\n\n$para';
    }
    if (cur.isNotEmpty) parts.add(cur);
    try {
      final out = <String>[];
      for (final p in parts) {
        out.add(p.length > AiStyles.maxText ? p : await LocalAi.run(rules: rules[style] ?? rules['polish']!, text: p));
      }
      return out.join('\n\n');
    } on AiError {
      return null;
    }
  }
}

Future<List<int>> Function(Json) docImageLoader(Backend b) =>
    (file) => b.downloadEncrypted(jsonEncode(file));

// ---------------------------------------------------------------------------
// Bubble

/// A long post / formatted message inside a chat bubble.
class ArticleBubble extends StatelessWidget {
  const ArticleBubble({super.key, required this.roomId, required this.msg, required this.data, required this.fg});
  final String roomId;
  final Msg msg;
  final Map<String, Object?> data;
  final Color fg;

  /// Bigger than this shows the start and a "전체 읽기" button.
  static const bubbleBlocks = 12, bubbleChars = 1500;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final inline = data['doc'] != null;
    final doc = Doc.fromJson(inline ? data['doc'] : data['preview']);
    final long = !inline || doc.blocks.length > bubbleBlocks || doc.chars > bubbleChars;
    final chars = inline ? doc.chars : (data['chars'] as int? ?? doc.chars);
    final accent = msg.mine ? fg : p.accent;
    final b = AppScope.read(context).backend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          // Fade out the end of a cut preview.
          shaderCallback: (r) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: long ? [const Color(0xFFFFFFFF), const Color(0xFFFFFFFF), const Color(0x00FFFFFF)] : [const Color(0xFFFFFFFF), const Color(0xFFFFFFFF)],
            stops: long ? const [0, 0.8, 1] : const [0, 1],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: DocView(
            key: const Key('article-bubble-doc'),
            doc: doc,
            fg: fg,
            accent: accent,
            compact: true,
            maxBlocks: long ? 8 : null,
            loadImage: docImageLoader(b),
          ),
        ),
        if (long) ...[
          SizedBox(height: Tokens.space[2]),
          GestureDetector(
            key: const Key('article-read'),
            onTap: () => paneNav(context).push(
              IosPageRoute(
                builder: (_) => ArticlePage(roomId: roomId, msg: msg),
              ),
            ),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(
                '${l.articleReadAll} · ${l.articleMinutes((chars / 500).ceil().clamp(1, 999))}',
                style: Tokens.preview.style.copyWith(color: fg, fontWeight: Tokens.semi),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Reading page

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  Doc? doc;
  bool failed = false, copied = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await AppScope.read(context).backend.openArticle(widget.roomId, widget.msg.id);
      if (mounted) setState(() => doc = Doc.fromJson(d));
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  Future<void> copy() async {
    final d = doc;
    if (d == null) return;
    await Clipboard.setData(ClipboardData(text: plainText(d.plain)));
    if (!mounted) return;
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final d = doc;
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        trailing: GlassCircle(
          key: const Key('article-copy'),
          onTap: copy,
          child: GlassCircle.icon(context, copied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_doc),
        ),
        backgroundColor: p.chatBackground,
        border: null,
      ),
      child: SafeArea(
        bottom: false,
        child: d == null
            ? Center(
                child: failed
                    ? Padding(
                        padding: EdgeInsets.all(Tokens.space[5]),
                        child: Text(
                          l.articleOpenFailed,
                          key: const Key('article-failed'),
                          textAlign: TextAlign.center,
                          style: Tokens.body.style.copyWith(color: p.secondaryLabel),
                        ),
                      )
                    : const CupertinoActivityIndicator(),
              )
            : ListView(
                key: const Key('article-page'),
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[5] + MediaQuery.paddingOf(context).bottom),
                children: [
                  DocView(doc: d, fg: p.label, accent: p.accent, loadImage: docImageLoader(AppScope.read(context).backend)),
                  SizedBox(height: Tokens.space[5]),
                  Row(
                    children: [
                      Icon(CupertinoIcons.lock_fill, size: 13, color: p.secondaryLabel),
                      SizedBox(width: Tokens.space[0]),
                      Expanded(
                        child: Text(
                          '${l.articleChars(d.chars)} · ${l.articleMinutes(d.minutes)} · ${l.articleEncrypted}',
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor

/// One block being edited, with its text fields.
class _Ed {
  _Ed(this.b) {
    text.text = b.text;
    lang.text = b.lang;
    for (final x in b.items.isEmpty && b.isList ? [''] : b.items) {
      items.add(TextEditingController(text: x));
      itemFocus.add(FocusNode());
    }
    for (final r in b.rows) {
      cells.add([for (final c in r) TextEditingController(text: c)]);
    }
  }
  final DocBlock b;
  final text = TextEditingController();
  final lang = TextEditingController();
  final focus = FocusNode();
  final items = <TextEditingController>[];
  final itemFocus = <FocusNode>[];
  final cells = <List<TextEditingController>>[];

  DocBlock read() => b.copy()
    ..text = text.text
    ..lang = lang.text.trim()
    ..items = [for (final c in items) c.text]
    ..rows = [
      for (final r in cells) [for (final c in r) c.text],
    ];

  void dispose() {
    text.dispose();
    lang.dispose();
    focus.dispose();
    for (final c in items) {
      c.dispose();
    }
    for (final f in itemFocus) {
      f.dispose();
    }
    for (final r in cells) {
      for (final c in r) {
        c.dispose();
      }
    }
  }
}

class ArticleEditor extends StatefulWidget {
  const ArticleEditor({super.key, required this.roomId, this.initialText = ''});
  final String roomId;

  /// Words already typed in the chat composer ("크게 쓰기").
  final String initialText;

  /// Draft key in settings.
  static String draftKey(String roomId) => 'article_draft:$roomId';

  @override
  State<ArticleEditor> createState() => _ArticleEditorState();
}

class _ArticleEditorState extends State<ArticleEditor> {
  final title = TextEditingController();
  final titleFocus = FocusNode();
  final eds = <_Ed>[];
  int cur = 0;
  bool busy = false;
  String? note;

  /// Undo / redo: snapshots of the whole document.
  final undo = <(String, List<DocBlock>)>[];
  final redo = <(String, List<DocBlock>)>[];
  (String, List<DocBlock>)? last;
  DateTime lastTyped = DateTime(0);

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    var start = Doc();
    final draft = s.settings[ArticleEditor.draftKey(widget.roomId)];
    if (widget.initialText.trim().isNotEmpty) {
      start = Doc(blocks: blocksFromText(widget.initialText));
    } else if (draft is String && draft.isNotEmpty) {
      try {
        start = Doc.fromJson(jsonDecode(draft));
      } catch (_) {}
    }
    title.text = start.title;
    if (start.blocks.isEmpty) start.blocks.add(DocBlock('p'));
    for (final b in start.blocks) {
      eds.add(_Ed(b));
    }
    last = snap();
  }

  @override
  void dispose() {
    noteTimer?.cancel();
    title.dispose();
    titleFocus.dispose();
    for (final e in eds) {
      e.dispose();
    }
    super.dispose();
  }

  Doc read() => Doc(title: title.text.trim(), blocks: [for (final e in eds) e.read()]);

  (String, List<DocBlock>) snap() => (title.text, [for (final e in eds) e.read()]);

  /// Remembers the state before a change (typing is grouped per pause).
  void remember({bool typing = false}) {
    final now = DateTime.now();
    if (typing && now.difference(lastTyped) < const Duration(milliseconds: 900)) {
      lastTyped = now;
      return;
    }
    lastTyped = typing ? now : DateTime(0);
    if (last != null) undo.add(last!);
    if (undo.length > 100) undo.removeAt(0);
    redo.clear();
  }

  void changed({bool typing = false}) {
    remember(typing: typing);
    last = snap();
    setState(() {});
  }

  void restore((String, List<DocBlock>) s) {
    for (final e in eds) {
      e.dispose();
    }
    eds.clear();
    title.text = s.$1;
    for (final b in s.$2) {
      eds.add(_Ed(b.copy()));
    }
    if (eds.isEmpty) eds.add(_Ed(DocBlock('p')));
    cur = cur.clamp(0, eds.length - 1);
    last = snap();
    setState(() {});
  }

  void doUndo() {
    if (undo.isEmpty) return;
    redo.add(snap());
    restore(undo.removeLast());
  }

  void doRedo() {
    if (redo.isEmpty) return;
    undo.add(snap());
    restore(redo.removeLast());
  }

  void setStructure(void Function() f) {
    remember();
    f();
    last = snap();
    setState(() {});
  }

  _Ed get current => eds[cur.clamp(0, eds.length - 1)];

  /// Turns the current block into another kind, keeping its words.
  void turnInto(String t) {
    final e = current;
    final b = e.read();
    if (b.t == t) return;
    final words = b.isList ? b.items.where((x) => x.trim().isNotEmpty).join('\n') : (b.t == 'table' ? Doc.plainOf(b) : b.text);
    final nb = DocBlock(
      t,
      text: (t == 'ul' || t == 'ol') ? '' : words,
      items: (t == 'ul' || t == 'ol') ? words.split('\n').where((x) => x.trim().isNotEmpty).toList() : null,
    );
    setStructure(() {
      final i = eds.indexOf(e);
      eds[i] = _Ed(nb);
      e.dispose();
    });
    focusBlock(cur);
  }

  /// Adds a block after the current one (or replaces an empty paragraph).
  void insert(DocBlock b) {
    setStructure(() {
      final e = current;
      final empty = e.b.t == 'p' && e.text.text.trim().isEmpty;
      final at = eds.indexOf(e) + 1;
      if (empty) {
        eds[at - 1] = _Ed(b);
        e.dispose();
        cur = at - 1;
      } else {
        eds.insert(at, _Ed(b));
        cur = at;
      }
      // Always somewhere to keep writing after a table, photo or divider.
      if (!b.isText && !b.isList && (cur == eds.length - 1)) eds.add(_Ed(DocBlock('p')));
    });
    focusBlock(cur);
  }

  void focusBlock(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || i >= eds.length) return;
      final e = eds[i];
      if (e.b.isList && e.itemFocus.isNotEmpty) {
        e.itemFocus.last.requestFocus();
      } else if (e.b.t != 'table' && e.b.t != 'hr') {
        e.focus.requestFocus();
      }
    });
  }

  void remove(_Ed e) => setStructure(() {
    eds.remove(e);
    e.dispose();
    if (eds.isEmpty) eds.add(_Ed(DocBlock('p')));
    cur = cur.clamp(0, eds.length - 1);
  });

  void move(_Ed e, int by) => setStructure(() {
    final i = eds.indexOf(e);
    final j = (i + by).clamp(0, eds.length - 1);
    eds
      ..removeAt(i)
      ..insert(j, e);
    cur = j;
  });

  // -- tools ---------------------------------------------------------------

  Future<void> styleMenu() async {
    final l = L.of(context);
    final kinds = [
      ('h1', l.blockH1),
      ('h2', l.blockH2),
      ('p', l.blockP),
      ('quote', l.blockQuote),
      ('pull', l.blockPull),
      ('code', l.blockCode),
      ('math', l.blockMath),
    ];
    final icons = {
      'h1': CupertinoIcons.textformat_size,
      'h2': CupertinoIcons.textformat,
      'p': CupertinoIcons.text_alignleft,
      'quote': CupertinoIcons.text_quote,
      'pull': CupertinoIcons.quote_bubble,
      'code': CupertinoIcons.chevron_left_slash_chevron_right,
      'math': CupertinoIcons.function,
    };
    final t = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.articleStyle),
        actions: [
          for (final (k, name) in kinds)
            CupertinoActionSheetAction(
              key: Key('style-$k'),
              onPressed: () => Navigator.pop(c, k),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[k], size: 20),
                  SizedBox(width: Tokens.space[1]),
                  Text(name),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (t != null) turnInto(t);
  }

  Future<void> plusMenu() async {
    final l = L.of(context);
    final t = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.articleInsert),
        actions: [
          for (final (k, name) in [
            ('img', l.blockImg),
            ('table', l.blockTable),
            ('ol', l.blockOl),
            ('quote', l.blockQuote),
            ('code', l.blockCode),
            ('math', l.blockMath),
            ('hr', l.blockHr),
          ])
            CupertinoActionSheetAction(key: Key('insert-$k'), onPressed: () => Navigator.pop(c, k), child: Text(name)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    switch (t) {
      case 'img':
        await addPhoto();
      case 'table':
        addTable();
      case null:
        break;
      default:
        insert(DocBlock(t, items: t == 'ol' ? [''] : null));
    }
  }

  void addTable() => insert(
    DocBlock(
      'table',
      rows: [
        ['', '', ''],
        ['', '', ''],
        ['', '', ''],
      ],
    ),
  );

  void listButton() {
    final t = current.b.t;
    // Text → list → numbered list → text, like Notes.
    turnInto(switch (t) {
      'ul' => 'ol',
      'ol' => 'p',
      _ => 'ul',
    });
  }

  /// The field the person is typing in (for links and AI).
  TextEditingController? get activeField {
    final e = current;
    if (e.b.isList) {
      for (var i = 0; i < e.items.length; i++) {
        if (e.itemFocus[i].hasFocus) return e.items[i];
      }
      return e.items.isEmpty ? null : e.items.last;
    }
    return e.b.isText && e.b.t != 'code' && e.b.t != 'math' ? e.text : null;
  }

  Future<void> addLink([TextEditingController? field]) async {
    final c = field ?? activeField;
    if (c == null) return;
    final sel = c.selection;
    final url = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const LinkEditPage()));
    if (url == null || !mounted) return;
    remember();
    if (sel.isValid && !sel.isCollapsed) {
      c.selection = sel;
      wrapSelection(c, '', url: url);
    } else {
      final at = sel.isValid ? sel.start : c.text.length;
      final link = '[$url]($url)';
      c.value = TextEditingValue(
        text: c.text.replaceRange(at, at, link),
        selection: TextSelection.collapsed(offset: at + link.length),
      );
    }
    last = snap();
    setState(() {});
  }

  /// Picks photos, strips hidden details (place, phone) and adds them.
  Future<void> addPhoto() async {
    final got =
        await (ArticleEditorTest.picker ??
            () async {
              final xs = await ImagePicker().pickMultiImage(imageQuality: 85, maxWidth: 2160, limit: 10);
              return [for (final x in xs) (x.mimeType ?? (x.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg'), await x.readAsBytes())];
            })();
    if (got.isEmpty || !mounted) return;
    final have = eds.where((e) => e.b.t == 'img').length;
    for (final (mime, raw) in got.take(DocLimits.images - have)) {
      final m = const ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].contains(mime) ? mime : 'image/jpeg';
      final bytes = StripMeta.photo(raw, m);
      final (w, h) = imageSize(bytes);
      if (!mounted) return;
      insert(DocBlock('img', local: bytes, mime: m, w: w, h: h));
    }
  }

  Future<void> aiMenu() async {
    final l = L.of(context);
    final p = paletteOf(context);
    final t = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.articleAi),
        message: Text(l.articleAiInfo),
        actions: [
          for (final (k, name, sub) in [('tidy', l.aiTidy, l.aiTidySub), ('polish', l.aiPolish, l.aiPolishSub), ('shorter', l.aiShorter, l.aiShorterSub)])
            CupertinoActionSheetAction(
              key: Key('ai-$k'),
              onPressed: () => Navigator.pop(c, k),
              child: Column(
                children: [
                  Text(name),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (t == null || !mounted) return;
    if (t == 'tidy') return tidy();
    if (!await aiAgeOk(context) || !mounted) return;
    final f = ArticleAi.rewrite ?? ArticleAi.onPhone;
    final field = activeField;
    if (field == null) return show(l.aiUnavailable);
    final sel = field.selection;
    final whole = !sel.isValid || sel.isCollapsed;
    final src = whole ? field.text : sel.textInside(field.text);
    if (src.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final out = await f(src, t);
      if (!mounted) return;
      if (out == null || out.trim().isEmpty) return show(l.aiUnavailable);
      remember();
      field.text = whole ? out.trim() : sel.textBefore(field.text) + out.trim() + sel.textAfter(field.text);
      last = snap();
      show(l.aiDone);
    } catch (_) {
      if (mounted) show(l.aiUnavailable);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Turns typed marks (# - | $$ ```) into real blocks. On the phone only.
  void tidy() {
    final out = <DocBlock>[];
    var changedAny = false;
    for (final e in eds) {
      final b = e.read();
      if (b.t == 'p') {
        final got = blocksFromText(b.text);
        if (got.length != 1 || got.first.t != 'p') changedAny = true;
        out.addAll(got);
      } else {
        out.add(b);
      }
    }
    if (!changedAny) return show(L.of(context).aiDone);
    remember();
    restore((title.text, out));
    show(L.of(context).aiDone);
  }

  Timer? noteTimer;

  void show(String s) {
    setState(() => note = s);
    noteTimer?.cancel();
    noteTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => note = null);
    });
  }

  Future<void> send() async {
    if (busy) return;
    final l = L.of(context);
    final d = read();
    if (d.isEmpty) return show(l.articleEmpty);
    if (d.chars > DocLimits.chars) return show(l.articleTooLong);
    setState(() => busy = true);
    try {
      final s = AppScope.read(context);
      final b = s.backend;
      // Photos: encrypted on this phone, then uploaded.
      for (final x in d.blocks.where((x) => x.t == 'img' && x.file == null && x.local != null)) {
        x.file = (jsonDecode(await b.uploadEncrypted(x.local!)) as Map).cast<String, Object?>();
      }
      d.blocks.removeWhere((x) => x.t == 'img' && x.file == null);
      await b.sendArticle(widget.roomId, d.toJson());
      await s.setPref(ArticleEditor.draftKey(widget.roomId), '');
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) show(l.saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> close() async {
    final l = L.of(context);
    final d = read();
    final s = AppScope.read(context);
    if (d.isEmpty) {
      await s.setPref(ArticleEditor.draftKey(widget.roomId), '');
      if (mounted) Navigator.pop(context);
      return;
    }
    final hasPhotos = d.blocks.any((b) => b.t == 'img');
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.articleDiscardAsk),
        message: hasPhotos ? Text(l.articleDraftNote) : null,
        actions: [
          CupertinoActionSheetAction(key: const Key('article-keep'), onPressed: () => Navigator.pop(c, 'keep'), child: Text(l.articleKeepDraft)),
          CupertinoActionSheetAction(
            key: const Key('article-discard'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'drop'),
            child: Text(l.articleDiscard),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    final draft = Doc(title: d.title, blocks: d.blocks.where((b) => b.t != 'img').toList());
    await s.setPref(ArticleEditor.draftKey(widget.roomId), pick == 'keep' ? jsonEncode(draft.toJson()) : '');
    if (mounted) Navigator.pop(context);
  }

  // -- drawing -------------------------------------------------------------

  Widget field(
    _Ed e,
    TextEditingController c, {
    FocusNode? focus,
    required TextStyle style,
    String? hint,
    Key? key,
    bool mono = false,
    TextAlign align = TextAlign.start,
    ValueChanged<String>? onChanged,
  }) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoTextField(
      key: key,
      controller: c,
      focusNode: focus,
      maxLines: null,
      textAlign: align,
      placeholder: hint,
      placeholderStyle: style.copyWith(color: p.secondaryLabel.withValues(alpha: 0.5)),
      padding: EdgeInsets.zero,
      decoration: null,
      style: mono ? style.copyWith(fontFamily: 'monospace', fontFamilyFallback: const ['Menlo', 'Courier']) : style,
      cursorColor: p.accent,
      onTap: () => cur = eds.indexOf(e),
      onChanged: onChanged ?? (_) => changed(typing: true),
      contextMenuBuilder: (context, st) {
        final items = [...st.contextMenuButtonItems];
        if (!st.textEditingValue.selection.isCollapsed && !mono) {
          void f(String mark) {
            remember();
            wrapSelection(c, mark);
            last = snap();
            st.hideToolbar();
            setState(() {});
          }

          items.addAll([
            ContextMenuButtonItem(
              label: l.articleStyle,
              onPressed: () {
                st.hideToolbar();
                cur = eds.indexOf(e);
                styleMenu();
              },
            ),
            ContextMenuButtonItem(label: l.fmtBold, onPressed: () => f('**')),
            ContextMenuButtonItem(label: l.fmtItalic, onPressed: () => f('__')),
            ContextMenuButtonItem(label: l.fmtUnderline, onPressed: () => f('++')),
            ContextMenuButtonItem(label: l.fmtStrike, onPressed: () => f('~~')),
            ContextMenuButtonItem(label: l.fmtCode, onPressed: () => f('`')),
            ContextMenuButtonItem(label: l.fmtSpoiler, onPressed: () => f('||')),
            ContextMenuButtonItem(
              label: l.fmtLink,
              onPressed: () {
                st.hideToolbar();
                addLink(c);
              },
            ),
          ]);
        }
        return CupertinoAdaptiveTextSelectionToolbar.buttonItems(anchors: st.contextMenuAnchors, buttonItems: items);
      },
    );
  }

  /// Long-press handle on a block: move / remove.
  Future<void> blockMenu(_Ed e) async {
    final l = L.of(context);
    final i = eds.indexOf(e);
    final t = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (i > 0) CupertinoActionSheetAction(key: const Key('block-up'), onPressed: () => Navigator.pop(c, 'up'), child: Text(l.blockUp)),
          if (i < eds.length - 1) CupertinoActionSheetAction(key: const Key('block-down'), onPressed: () => Navigator.pop(c, 'down'), child: Text(l.blockDown)),
          CupertinoActionSheetAction(
            key: const Key('block-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(l.blockRemove),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    switch (t) {
      case 'up':
        move(e, -1);
      case 'down':
        move(e, 1);
      case 'remove':
        remove(e);
    }
  }

  Widget blockEditor(_Ed e, int i) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ink = p.label;
    final body = Tokens.body.style.copyWith(color: ink);
    final faint = ink.withValues(alpha: 0.06);
    final line = ink.withValues(alpha: 0.15);
    Widget box(Widget child, {Color? fill}) => Container(
      padding: EdgeInsets.all(Tokens.space[2]),
      decoration: BoxDecoration(color: fill ?? faint, borderRadius: BorderRadius.circular(Tokens.radius[1])),
      child: child,
    );
    switch (e.b.t) {
      case 'h1' || 'h2':
        return field(
          e,
          e.text,
          key: Key('article-text-$i'),
          focus: e.focus,
          hint: e.b.t == 'h1' ? l.blockH1 : l.blockH2,
          style: (e.b.t == 'h1' ? Tokens.cardTitle : Tokens.body).style.copyWith(color: ink, fontWeight: Tokens.semi),
        );
      case 'quote':
        return Container(
          padding: EdgeInsets.only(left: Tokens.space[2]),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: p.accent, width: 3)),
          ),
          child: field(
            e,
            e.text,
            key: Key('article-text-$i'),
            focus: e.focus,
            hint: l.blockQuote,
            style: body.copyWith(color: ink.withValues(alpha: 0.85)),
          ),
        );
      case 'pull':
        return Container(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: line)),
          ),
          child: field(
            e,
            e.text,
            key: Key('article-text-$i'),
            focus: e.focus,
            hint: l.blockPull,
            align: TextAlign.center,
            style: Tokens.cardTitle.style.copyWith(color: p.accent, fontStyle: FontStyle.italic),
          ),
        );
      case 'code':
        return box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 140,
                child: field(
                  e,
                  e.lang,
                  key: Key('article-lang-$i'),
                  hint: l.articleLangHint,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
              ),
              SizedBox(height: Tokens.space[1]),
              field(
                e,
                e.text,
                key: Key('article-text-$i'),
                focus: e.focus,
                hint: l.articleCodeHint,
                mono: true,
                style: Tokens.preview.style.copyWith(color: ink, height: 1.4),
              ),
            ],
          ),
        );
      case 'math':
        return box(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(
                e,
                e.text,
                key: Key('article-text-$i'),
                focus: e.focus,
                hint: l.articleMathHint,
                mono: true,
                style: Tokens.preview.style.copyWith(color: ink),
              ),
              if (e.text.text.trim().isNotEmpty) ...[
                SizedBox(height: Tokens.space[1]),
                DocView(
                  doc: Doc(blocks: [DocBlock('math', text: e.text.text)]),
                  fg: ink,
                  accent: p.accent,
                ),
              ],
            ],
          ),
        );
      case 'ul' || 'ol':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var k = 0; k < e.items.length; k++)
              Padding(
                padding: EdgeInsets.only(top: k == 0 ? 0 : Tokens.space[0]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: e.b.t == 'ol' ? 28 : 18,
                      child: Text(e.b.t == 'ol' ? '${e.b.start + k}.' : '•', style: body.copyWith(color: e.b.t == 'ul' ? p.accent : ink)),
                    ),
                    Expanded(
                      child: field(
                        e,
                        e.items[k],
                        key: Key('article-item-$i-$k'),
                        focus: e.itemFocus[k],
                        hint: l.articleItemHint,
                        style: body,
                        onChanged: (s) => listTyped(e, k, s),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case 'table':
        return tableEditor(e, i);
      case 'img':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DocView(
              doc: Doc(blocks: [e.b.copy()..text = '']),
              fg: ink,
              accent: p.accent,
              loadImage: docImageLoader(AppScope.read(context).backend),
            ),
            SizedBox(height: Tokens.space[0]),
            field(
              e,
              e.text,
              key: Key('article-caption-$i'),
              focus: e.focus,
              hint: l.articleCaptionHint,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        );
      case 'hr':
        return Padding(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
          child: Container(height: 1, color: line),
        );
      default:
        return field(e, e.text, key: Key('article-text-$i'), focus: e.focus, hint: i == 0 ? l.articleBodyHint : null, style: body);
    }
  }

  /// A line break in a list item starts the next item; an empty item +
  /// line break ends the list and goes on with normal text.
  void listTyped(_Ed e, int k, String s) {
    if (!s.contains('\n')) return changed(typing: true);
    final parts = s.split('\n');
    final i = eds.indexOf(e);
    if (parts.first.trim().isEmpty && parts.length == 2 && parts[1].isEmpty && k == e.items.length - 1 && e.items.length > 1) {
      setStructure(() {
        e.items.removeLast().dispose();
        e.itemFocus.removeLast().dispose();
        eds.insert(i + 1, _Ed(DocBlock('p')));
        cur = i + 1;
      });
      focusBlock(i + 1);
      return;
    }
    setStructure(() {
      e.items[k].text = parts.first;
      for (var j = 1; j < parts.length; j++) {
        e.items.insert(k + j, TextEditingController(text: parts[j]));
        e.itemFocus.insert(k + j, FocusNode());
      }
      cur = i;
    });
    final next = k + parts.length - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && next < e.itemFocus.length) e.itemFocus[next].requestFocus();
    });
  }

  Widget tableEditor(_Ed e, int i) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ink = p.label;
    final line = ink.withValues(alpha: 0.15);
    final cols = e.cells.isEmpty ? 0 : e.cells.first.length;
    final st = Tokens.preview.style.copyWith(color: ink);
    Widget act(String key, String label, VoidCallback f) => GestureDetector(
      key: Key(key),
      onTap: f,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
        decoration: BoxDecoration(color: ink.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(label, style: Tokens.caption.style.copyWith(color: ink)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius[1]),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(Tokens.radius[1]),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(120),
                border: TableBorder(
                  horizontalInside: BorderSide(color: line),
                  verticalInside: BorderSide(color: line),
                ),
                children: [
                  for (var r = 0; r < e.cells.length; r++)
                    TableRow(
                      decoration: r == 0 && e.b.head ? BoxDecoration(color: ink.withValues(alpha: 0.04)) : null,
                      children: [
                        for (var c = 0; c < cols; c++)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: Tokens.space[1], horizontal: Tokens.space[1]),
                            child: field(
                              e,
                              e.cells[r][c],
                              key: Key('article-cell-$i-$r-$c'),
                              style: r == 0 && e.b.head ? st.copyWith(fontWeight: Tokens.semi) : st,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: Tokens.space[1]),
        Wrap(
          spacing: Tokens.space[1],
          runSpacing: Tokens.space[1],
          children: [
            act('table-add-row', l.tableAddRow, () {
              if (e.cells.length >= DocLimits.tableRows) return;
              setStructure(() => e.cells.add([for (var c = 0; c < cols; c++) TextEditingController()]));
            }),
            act('table-add-col', l.tableAddCol, () {
              if (cols >= DocLimits.tableCols) return;
              setStructure(() {
                for (final r in e.cells) {
                  r.add(TextEditingController());
                }
              });
            }),
            if (e.cells.length > 1) act('table-del-row', l.tableDelRow, () => setStructure(() => e.cells.removeLast().forEach((c) => c.dispose()))),
            if (cols > 1)
              act(
                'table-del-col',
                l.tableDelCol,
                () => setStructure(() {
                  for (final r in e.cells) {
                    r.removeLast().dispose();
                  }
                }),
              ),
            act('table-head', '${e.b.head ? '✓ ' : ''}${l.tableHeader}', () => setStructure(() => e.b.head = !e.b.head)),
          ],
        ),
      ],
    );
  }

  Widget tool(String key, IconData icon, VoidCallback? onTap, {Widget? child}) {
    final p = paletteOf(context);
    return GestureDetector(
      key: Key(key),
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: 40,
        height: Tokens.closeButton,
        child: Center(child: child ?? Icon(icon, size: 22, color: p.label)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final d = read();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, _) {
        if (!did) close();
      },
      child: CupertinoPageScaffold(
        backgroundColor: p.chatBackground,
        resizeToAvoidBottomInset: true,
        navigationBar: GlassTopBar.nav(
          leading: GlassCircle(key: const Key('article-close'), onTap: close, child: GlassCircle.icon(context, CupertinoIcons.xmark)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: undo.isEmpty ? 0.35 : 1,
                child: GlassCircle(key: const Key('article-undo'), onTap: doUndo, child: GlassCircle.icon(context, CupertinoIcons.arrow_uturn_left)),
              ),
              SizedBox(width: Tokens.space[1]),
              Opacity(
                opacity: redo.isEmpty ? 0.35 : 1,
                child: GlassCircle(key: const Key('article-redo'), onTap: doRedo, child: GlassCircle.icon(context, CupertinoIcons.arrow_uturn_right)),
              ),
            ],
          ),
          backgroundColor: p.chatBackground,
          border: null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('article-editor'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[5]),
                  children: [
                    CupertinoTextField(
                      key: const Key('article-title'),
                      controller: title,
                      focusNode: titleFocus,
                      maxLines: null,
                      placeholder: l.articleTitleHint,
                      placeholderStyle: Tokens.screenTitle.style.copyWith(color: p.secondaryLabel.withValues(alpha: 0.5), fontWeight: Tokens.semi),
                      padding: EdgeInsets.zero,
                      decoration: null,
                      cursorColor: p.accent,
                      style: Tokens.screenTitle.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      onChanged: (_) => changed(typing: true),
                    ),
                    for (var i = 0; i < eds.length; i++) ...[
                      SizedBox(height: eds[i].b.t == 'h1' || eds[i].b.t == 'h2' ? Tokens.space[4] : Tokens.space[2]),
                      GestureDetector(
                        key: ValueKey(eds[i]),
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => cur = i,
                        onLongPress: () => blockMenu(eds[i]),
                        child: blockEditor(eds[i], i),
                      ),
                    ],
                  ],
                ),
              ),
              if (note != null || busy)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                  child: Row(
                    children: [
                      if (busy) ...[const CupertinoActivityIndicator(), SizedBox(width: Tokens.space[1])],
                      Expanded(
                        child: Text(
                          note ?? l.articleSending,
                          key: const Key('article-note'),
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              // Tool bar above the keyboard (Telegram order, iOS glass).
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[1]),
                child: Row(
                  children: [
                    Expanded(
                      child: LiquidGlass(
                        radius: Tokens.closeButton / 2,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                          child: Row(
                            children: [
                              tool('article-ai', CupertinoIcons.sparkles, aiMenu),
                              tool('article-plus', CupertinoIcons.plus, plusMenu),
                              tool('article-style', CupertinoIcons.textformat, styleMenu),
                              tool('article-list', CupertinoIcons.list_bullet, listButton),
                              tool('article-table', CupertinoIcons.table, addTable),
                              tool('article-link', CupertinoIcons.link, addLink),
                              tool('article-photo', CupertinoIcons.photo, addPhoto),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Text(
                      l.articleChars(d.chars),
                      key: const Key('article-count'),
                      style: Tokens.caption.style.copyWith(color: d.chars > DocLimits.chars ? Palette.tileRed : p.secondaryLabel),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    GestureDetector(
                      key: const Key('article-send'),
                      onTap: send,
                      child: Opacity(
                        opacity: busy || d.isEmpty ? 0.4 : 1,
                        child: Container(
                          width: Tokens.closeButton,
                          height: Tokens.closeButton,
                          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: BurumyMark(color: p.onAccent, size: 28),
                        ),
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
  }
}

/// Width and height from a PNG, GIF or JPEG header (0, 0 if unknown), read
/// without decoding the picture.
(int, int) imageSize(List<int> b) {
  int be16(int i) => (b[i] << 8) | b[i + 1];
  int be32(int i) => (b[i] << 24) | (b[i + 1] << 16) | (b[i + 2] << 8) | b[i + 3];
  try {
    if (b.length > 24 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return (be32(16), be32(20));
    if (b.length > 10 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return (b[6] | (b[7] << 8), b[8] | (b[9] << 8));
    if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
      var i = 2;
      while (i + 9 < b.length) {
        if (b[i] != 0xFF) return (0, 0);
        final marker = b[i + 1];
        final len = be16(i + 2);
        // Start-of-frame markers carry the size (not DHT/JPG/DAC).
        if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) return (be16(i + 7), be16(i + 5));
        i += 2 + len;
      }
    }
  } catch (_) {}
  return (0, 0);
}
