// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Long posts and formatted messages ("긴 글"): one document format shared by
// people's articles, short formatted messages, on-device AI answers and
// (later) bots. The phone engine checks every document again on arrival
// (engine/src/article.rs); this file mirrors those limits so the editor,
// the demo and the renderer agree with it.
//
// A document is {title, blocks: [...]}. Block types:
//   h1, h2            heading (text)
//   p                 paragraph (text with the usual inline marks)
//   quote, pull       quote with a side bar / big centred "pull quote"
//   code              code block (text, lang)
//   math              formula (tex, LaTeX)
//   ul, ol            bulleted / numbered list (items, ol: start)
//   table             table (rows of cells, head = first row is a header)
//   img               photo (file = encrypted file reference, mime, w, h, caption)
//   hr                divider
// Inside text the chat marks work (**bold**, __italic__, ++underline++,
// ~~strike~~, `code`, ||spoiler||, [text](url)) plus \( … \) for a formula
// inside a line.

const docKinds = ['h1', 'h2', 'p', 'quote', 'pull', 'code', 'math', 'ul', 'ol', 'table', 'img', 'hr'];

class DocLimits {
  static const chars = 100000;
  static const blocks = 2000;
  static const images = 50;
  static const tableCols = 12;
  static const tableRows = 200;

  /// JSON at most this big goes inside the message itself; bigger is sent
  /// as an encrypted file.
  static const inline = 16 * 1024;
}

typedef Json = Map<String, Object?>;

class DocBlock {
  DocBlock(
    this.t, {
    this.text = '',
    List<String>? items,
    List<List<String>>? rows,
    this.head = true,
    this.lang = '',
    this.start = 1,
    this.file,
    this.mime = 'image/jpeg',
    this.w = 0,
    this.h = 0,
    this.local,
  }) : items = items ?? [],
       rows = rows ?? [];

  /// Block type (see [docKinds]).
  String t;

  /// Text, code, or the formula (tex) for "math"; caption for "img".
  String text;
  List<String> items;
  List<List<String>> rows;
  bool head;
  String lang;
  int start;

  /// Photo: encrypted file reference (after upload) ...
  Json? file;
  String mime;
  int w, h;

  /// ... or the picked bytes before sending (editor only).
  List<int>? local;

  bool get isText => const ['h1', 'h2', 'p', 'quote', 'pull', 'code', 'math'].contains(t);
  bool get isList => t == 'ul' || t == 'ol';

  DocBlock copy() => DocBlock(
    t,
    text: text,
    items: [...items],
    rows: [
      for (final r in rows) [...r],
    ],
    head: head,
    lang: lang,
    start: start,
    file: file,
    mime: mime,
    w: w,
    h: h,
    local: local,
  );

  Json toJson() => switch (t) {
    'math' => {'t': t, 'tex': text},
    'code' => {'t': t, 'text': text, 'lang': lang},
    'ul' => {'t': t, 'items': items},
    'ol' => {'t': t, 'items': items, 'start': start},
    'table' => {'t': t, 'rows': rows, 'head': head},
    'img' => {'t': t, 'file': file, 'mime': mime, 'w': w, 'h': h, if (text.trim().isNotEmpty) 'caption': text},
    'hr' => {'t': t},
    _ => {'t': t, 'text': text},
  };
}

class Doc {
  Doc({this.title = '', List<DocBlock>? blocks}) : blocks = blocks ?? [];
  String title;
  final List<DocBlock> blocks;

  Json toJson() => {
    'title': title,
    'blocks': [for (final b in blocks) b.toJson()],
  };

  bool get isEmpty => title.trim().isEmpty && blocks.every((b) => b.t != 'hr' && b.t != 'img' && plainOf(b).trim().isEmpty);

  /// Characters a person reads.
  int get chars => title.length + blocks.fold(0, (n, b) => n + plainOf(b).length);

  /// Reading time in minutes (about 500 Korean characters a minute).
  int get minutes => (chars / 500).ceil().clamp(1, 999);

  static Doc fromJson(Object? v) {
    final d = clean(v);
    return Doc(
      title: d['title'] as String? ?? '',
      blocks: [
        for (final b in (d['blocks'] as List).cast<Json>())
          DocBlock(
            b['t'] as String,
            text: (b['text'] ?? b['tex'] ?? b['caption'] ?? '') as String,
            items: (b['items'] as List?)?.cast<String>(),
            rows: [for (final r in (b['rows'] as List? ?? const [])) (r as List).cast<String>()],
            head: b['head'] as bool? ?? true,
            lang: b['lang'] as String? ?? '',
            start: b['start'] as int? ?? 1,
            file: b['file'] as Json?,
            mime: b['mime'] as String? ?? 'image/jpeg',
            w: b['w'] as int? ?? 0,
            h: b['h'] as int? ?? 0,
          ),
      ],
    );
  }

  /// Plain text for notifications, copying and old apps.
  String get plain {
    final out = <String>[if (title.trim().isNotEmpty) title.trim()];
    for (final b in blocks) {
      final s = plainOf(b);
      if (s.isNotEmpty) out.add(s);
    }
    return out.join('\n\n');
  }

  static String plainOf(DocBlock b) => switch (b.t) {
    'ul' => b.items.map((x) => '• $x').join('\n'),
    'ol' => [for (var i = 0; i < b.items.length; i++) '${b.start + i}. ${b.items[i]}'].join('\n'),
    'table' => b.rows.map((r) => r.join(' | ')).join('\n'),
    'hr' => '',
    _ => b.text.trim(),
  };

  /// Checks a document the same way the engine does (unknown blocks
  /// dropped, every text cut to its limit). Never throws.
  static Json clean(Object? v) {
    final d = v is Map ? v.cast<String, Object?>() : const <String, Object?>{};
    var left = DocLimits.chars;
    var images = 0;
    String? take(Object? x, int max) {
      if (x is! String || left <= 0) return null;
      var s = x.replaceAll(RegExp(r'[\x00-\x08\x0B-\x1F\x7F]'), '');
      if (s.length > max) s = s.substring(0, max);
      if (s.length > left) s = s.substring(0, left);
      s = s.trimRight();
      if (s.trim().isEmpty) return null;
      left -= s.length;
      return s;
    }

    List<Object?> list(Object? x) => x is List ? x : const [];
    final blocks = <Json>[];
    for (final raw in list(d['blocks']).take(DocLimits.blocks)) {
      if (raw is! Map) continue;
      final b = raw.cast<String, Object?>();
      final t = b['t'];
      if (t is! String || !docKinds.contains(t)) continue;
      Json? o;
      switch (t) {
        case 'h1' || 'h2':
          final s = take(b['text'], 300);
          if (s != null) o = {'t': t, 'text': s};
        case 'p' || 'quote' || 'pull':
          final s = take(b['text'], 20000);
          if (s != null) o = {'t': t, 'text': s};
        case 'code':
          final s = take(b['text'], 20000);
          final lang = (b['lang'] is String ? b['lang'] as String : '').replaceAll(RegExp(r'[^A-Za-z0-9+#\-_.]'), '');
          if (s != null) o = {'t': t, 'text': s, 'lang': lang.length > 20 ? lang.substring(0, 20) : lang};
        case 'math':
          final s = take(b['tex'], 2000);
          if (s != null) o = {'t': t, 'tex': s};
        case 'ul' || 'ol':
          final items = [for (final x in list(b['items']).take(500)) ?take(x, 4000)];
          if (items.isNotEmpty) {
            final st = b['start'];
            o = {'t': t, 'items': items, if (t == 'ol') 'start': st is int ? st.clamp(0, 100000) : 1};
          }
        case 'table':
          var rows = [
            for (final r in list(b['rows']).take(DocLimits.tableRows))
              if (list(r).isNotEmpty) [for (final c in list(r).take(DocLimits.tableCols)) take(c, 500) ?? ''],
          ];
          final cols = rows.fold(0, (n, r) => r.length > n ? r.length : n);
          if (cols > 0 && rows.any((r) => r.any((c) => c.isNotEmpty))) {
            rows = [
              for (final r in rows) [...r, for (var i = r.length; i < cols; i++) ''],
            ];
            o = {'t': t, 'rows': rows, 'head': b['head'] is bool ? b['head'] : true};
          }
        case 'img':
          final f = cleanFile(b['file']);
          if (f != null && images < DocLimits.images) {
            images++;
            final m = b['mime'];
            int dim(Object? x) => x is int ? x.clamp(0, 20000) : 0;
            final cap = take(b['caption'], 500);
            o = {
              't': t,
              'file': f,
              'mime': const ['image/jpeg', 'image/png', 'image/webp', 'image/gif'].contains(m) ? m : 'image/jpeg',
              'w': dim(b['w']),
              'h': dim(b['h']),
              'caption': ?cap,
            };
          }
        default:
          o = {'t': 'hr'};
      }
      if (o != null) blocks.add(o);
    }
    return {'title': take(d['title'], 200) ?? '', 'blocks': blocks};
  }

  /// A well-formed encrypted file reference, or null.
  static Json? cleanFile(Object? v) {
    if (v is! Map) return null;
    final url = v['url'], key = v['key'], iv = v['iv'], hashes = v['hashes'];
    bool small(Object? s) => s is String && s.length <= 100 && RegExp(r'^[A-Za-z0-9+/=\-_]*$').hasMatch(s);
    if (url is! String || !url.startsWith('mxc://') || url.length > 300 || url.contains(RegExp(r'\s'))) return null;
    if (key is! Map || key['alg'] != 'A256CTR' || !small(key['k']) || !small(iv) || hashes is! Map || !small(hashes['sha256'])) return null;
    return {
      'url': url,
      'key': {
        'kty': 'oct',
        'key_ops': ['encrypt', 'decrypt'],
        'alg': 'A256CTR',
        'k': key['k'],
        'ext': true,
      },
      'iv': iv,
      'hashes': {'sha256': hashes['sha256']},
      'v': 'v2',
    };
  }
}

/// Turns typed text into blocks, so people (and AI answers) can write with
/// simple marks and get a formatted post: "# " heading, "## " small
/// heading, "> " quote, ">> " pull quote, "- "/"• " list, "1. " numbered
/// list, "|a|b|" table rows, "$$ … $$" formula, ``` code ```, "---" divider.
/// Runs on the phone; no text leaves it.
List<DocBlock> blocksFromText(String text) {
  final out = <DocBlock>[];
  final lines = text.replaceAll('\r\n', '\n').split('\n');
  final para = <String>[];
  void flush() {
    final s = para.join('\n').trim();
    if (s.isNotEmpty) out.add(DocBlock('p', text: s));
    para.clear();
  }

  final ol = RegExp(r'^(\d{1,5})[.)]\s+(.*)$');
  final ul = RegExp(r'^[-*•]\s+(.*)$');
  var i = 0;
  while (i < lines.length) {
    final raw = lines[i];
    final line = raw.trim();
    if (line.startsWith('```')) {
      flush();
      final lang = line.substring(3).trim();
      final code = <String>[];
      i++;
      while (i < lines.length && !lines[i].trim().startsWith('```')) {
        code.add(lines[i]);
        i++;
      }
      out.add(DocBlock('code', text: code.join('\n'), lang: lang));
      i++;
      continue;
    }
    if (line.startsWith(r'$$')) {
      flush();
      var body = line.substring(2);
      if (body.endsWith(r'$$') && body.length >= 2) {
        out.add(DocBlock('math', text: body.substring(0, body.length - 2).trim()));
        i++;
        continue;
      }
      final tex = <String>[body];
      i++;
      while (i < lines.length && !lines[i].trim().endsWith(r'$$')) {
        tex.add(lines[i]);
        i++;
      }
      if (i < lines.length) {
        final last = lines[i].trim();
        tex.add(last.substring(0, last.length - 2));
      }
      out.add(DocBlock('math', text: tex.join('\n').trim()));
      i++;
      continue;
    }
    if (line.startsWith('|') && line.length > 1) {
      flush();
      final rows = <List<String>>[];
      var head = false;
      while (i < lines.length && lines[i].trim().startsWith('|')) {
        final l = lines[i].trim();
        final cells = l.substring(1, l.endsWith('|') && l.length > 1 ? l.length - 1 : l.length).split('|').map((c) => c.trim()).toList();
        if (cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c))) {
          head = rows.length == 1;
        } else {
          rows.add(cells);
        }
        i++;
      }
      if (rows.isNotEmpty) out.add(DocBlock('table', rows: rows, head: head || rows.length > 1));
      continue;
    }
    if (ol.hasMatch(line) || ul.hasMatch(line)) {
      flush();
      final numbered = ol.hasMatch(line);
      final items = <String>[];
      final start = numbered ? int.parse(ol.firstMatch(line)!.group(1)!) : 1;
      while (i < lines.length) {
        final l = lines[i].trim();
        final m = numbered ? ol.firstMatch(l) : ul.firstMatch(l);
        if (m == null) break;
        items.add(m.group(numbered ? 2 : 1)!.trim());
        i++;
      }
      out.add(DocBlock(numbered ? 'ol' : 'ul', items: items, start: start));
      continue;
    }
    if (RegExp(r'^(-{3,}|_{3,}|\*{3,})$').hasMatch(line)) {
      flush();
      out.add(DocBlock('hr'));
    } else if (line.startsWith('## ')) {
      flush();
      out.add(DocBlock('h2', text: line.substring(3).trim()));
    } else if (line.startsWith('# ')) {
      flush();
      out.add(DocBlock('h1', text: line.substring(2).trim()));
    } else if (line.startsWith('>> ')) {
      flush();
      out.add(DocBlock('pull', text: line.substring(3).trim()));
    } else if (line.startsWith('> ')) {
      flush();
      final q = <String>[];
      while (i < lines.length && lines[i].trim().startsWith('> ')) {
        q.add(lines[i].trim().substring(2));
        i++;
      }
      out.add(DocBlock('quote', text: q.join('\n')));
      continue;
    } else if (line.isEmpty) {
      flush();
    } else {
      para.add(raw);
    }
    i++;
  }
  flush();
  return out;
}

/// The other way round: a document as typed text with the same marks
/// (used when a post goes back into the plain composer, and for AI input).
String textFromBlocks(Doc d) {
  final out = <String>[if (d.title.trim().isNotEmpty) '# ${d.title.trim()}'];
  for (final b in d.blocks) {
    out.add(switch (b.t) {
      'h1' => '# ${b.text}',
      'h2' => '## ${b.text}',
      'quote' => b.text.split('\n').map((l) => '> $l').join('\n'),
      'pull' => '>> ${b.text}',
      'code' => '```${b.lang}\n${b.text}\n```',
      'math' => '\$\$${b.text}\$\$',
      'ul' => b.items.map((x) => '- $x').join('\n'),
      'ol' => [for (var i = 0; i < b.items.length; i++) '${b.start + i}. ${b.items[i]}'].join('\n'),
      'table' => [
        for (var r = 0; r < b.rows.length; r++) ...[
          '| ${b.rows[r].join(' | ')} |',
          if (r == 0 && b.head) '|${List.filled(b.rows[r].length, '---').join('|')}|',
        ],
      ].join('\n'),
      'hr' => '---',
      'img' => b.text.isEmpty ? '' : '(${b.text})',
      _ => b.text,
    });
  }
  return out.where((s) => s.isNotEmpty).join('\n\n');
}
