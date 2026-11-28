// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 코드 블록 색 (Telegram tip 411): splits a piece of code into coloured
// parts — keywords, words in quotes, notes (comments), numbers, type names
// and function names. Our own small reader that runs on the phone (no
// library, nothing sent anywhere). It only colours; it never changes the
// code, so copying gives back exactly what was sent.

enum CodePart { plain, keyword, string, comment, number, type, function }

class CodeSpan {
  const CodeSpan(this.text, this.part);
  final String text;
  final CodePart part;
  @override
  String toString() => '${part.name}:$text';
}

class _Lang {
  const _Lang(
    this.name,
    this.keywords, {
    this.line = const ['//'],
    this.block = const [('/*', '*/')],
    this.quotes = '"\'',
    this.triple = false,
    this.caseless = false,
  });
  final String name;
  final Set<String> keywords;
  final List<String> line;
  final List<(String, String)> block;
  final String quotes;
  final bool triple;
  final bool caseless;
}

// dart format off
const _c = {'if', 'else', 'for', 'while', 'do', 'return', 'break', 'continue', 'switch', 'case', 'default', 'true', 'false', 'null', 'new', 'this', 'class', 'static', 'const', 'void', 'try', 'catch', 'finally', 'throw', 'import', 'public', 'private', 'protected', 'final', 'enum', 'extends', 'implements', 'interface', 'abstract', 'super', 'in', 'is', 'as'};

final _langs = <_Lang>[
  _Lang('python', {
    'def', 'class', 'return', 'if', 'elif', 'else', 'for', 'while', 'in', 'not', 'and', 'or', 'is', 'None', 'True', 'False', 'import', 'from', 'as', 'with', 'try', 'except', 'finally', 'raise', 'lambda', 'yield', 'pass', 'break', 'continue', 'global', 'nonlocal', 'async', 'await', 'del', 'assert', 'self', 'print', 'len', 'range',
  }, line: const ['#'], block: const [], triple: true),
  _Lang('javascript', {..._c, 'function', 'let', 'var', 'const', 'async', 'await', 'yield', 'typeof', 'instanceof', 'undefined', 'of', 'export', 'from', 'delete', 'console'}, quotes: '"\'`'),
  _Lang('typescript', {..._c, 'function', 'let', 'var', 'async', 'await', 'type', 'interface', 'readonly', 'keyof', 'typeof', 'undefined', 'of', 'export', 'from', 'string', 'number', 'boolean', 'any', 'unknown', 'never'}, quotes: '"\'`'),
  _Lang('dart', {..._c, 'var', 'late', 'required', 'async', 'await', 'yield', 'dynamic', 'final', 'mixin', 'with', 'extension', 'on', 'factory', 'get', 'set', 'operator', 'typedef', 'show', 'hide', 'library', 'part', 'sealed', 'base'}),
  _Lang('java', {..._c, 'package', 'synchronized', 'volatile', 'native', 'instanceof', 'throws', 'int', 'long', 'double', 'float', 'boolean', 'char', 'byte', 'short', 'var', 'record'}),
  _Lang('kotlin', {..._c, 'fun', 'val', 'var', 'object', 'companion', 'when', 'data', 'sealed', 'override', 'open', 'internal', 'lateinit', 'suspend', 'package', 'it', 'typealias'}),
  _Lang('swift', {..._c, 'func', 'let', 'var', 'struct', 'protocol', 'extension', 'guard', 'nil', 'self', 'Self', 'init', 'deinit', 'inout', 'where', 'some', 'any', 'async', 'await', 'throws', 'override', 'mutating', 'weak', 'lazy', 'fileprivate', 'internal', 'open'}),
  _Lang('c', {..._c, 'int', 'long', 'short', 'char', 'float', 'double', 'unsigned', 'signed', 'struct', 'union', 'typedef', 'sizeof', 'extern', 'register', 'volatile', 'goto', 'auto', 'include', 'define', 'NULL'}),
  _Lang('cpp', {..._c, 'int', 'long', 'char', 'float', 'double', 'unsigned', 'struct', 'typedef', 'sizeof', 'namespace', 'using', 'template', 'typename', 'auto', 'nullptr', 'virtual', 'override', 'constexpr', 'std', 'include', 'define', 'delete', 'operator'}),
  _Lang('csharp', {..._c, 'using', 'namespace', 'var', 'int', 'string', 'bool', 'double', 'async', 'await', 'override', 'virtual', 'readonly', 'get', 'set', 'struct', 'record', 'out', 'ref'}),
  _Lang('go', {'func', 'package', 'import', 'var', 'const', 'type', 'struct', 'interface', 'map', 'chan', 'go', 'defer', 'select', 'if', 'else', 'for', 'range', 'return', 'break', 'continue', 'switch', 'case', 'default', 'fallthrough', 'nil', 'true', 'false', 'make', 'new', 'len', 'append', 'error', 'string', 'int', 'bool'}, quotes: '"\'`'),
  _Lang('rust', {'fn', 'let', 'mut', 'const', 'static', 'struct', 'enum', 'impl', 'trait', 'pub', 'use', 'mod', 'crate', 'self', 'Self', 'super', 'if', 'else', 'match', 'for', 'while', 'loop', 'in', 'return', 'break', 'continue', 'as', 'ref', 'move', 'async', 'await', 'where', 'dyn', 'unsafe', 'true', 'false', 'Some', 'None', 'Ok', 'Err'}, quotes: '"'),
  _Lang('php', {..._c, 'function', 'echo', 'foreach', 'as', 'array', 'namespace', 'use', 'require', 'include', 'fn', 'match'}, line: const ['//', '#']),
  _Lang('ruby', {'def', 'end', 'class', 'module', 'if', 'elsif', 'else', 'unless', 'while', 'until', 'for', 'in', 'do', 'return', 'yield', 'self', 'nil', 'true', 'false', 'and', 'or', 'not', 'require', 'puts', 'attr_accessor', 'begin', 'rescue', 'ensure'}, line: const ['#'], block: const []),
  _Lang('sql', {'select', 'from', 'where', 'and', 'or', 'not', 'insert', 'into', 'values', 'update', 'set', 'delete', 'create', 'table', 'drop', 'alter', 'join', 'left', 'right', 'inner', 'outer', 'on', 'group', 'by', 'order', 'having', 'limit', 'as', 'distinct', 'null', 'is', 'in', 'like', 'primary', 'key', 'index', 'count', 'sum', 'avg', 'max', 'min', 'desc', 'asc', 'union', 'case', 'when', 'then', 'end'}, line: const ['--'], caseless: true),
  _Lang('bash', {'if', 'then', 'else', 'elif', 'fi', 'for', 'while', 'do', 'done', 'case', 'esac', 'in', 'function', 'return', 'echo', 'export', 'local', 'cd', 'sudo', 'exit', 'set'}, line: const ['#'], block: const []),
  _Lang('json', {'true', 'false', 'null'}, line: const [], block: const [], quotes: '"'),
  _Lang('yaml', {'true', 'false', 'null', 'yes', 'no'}, line: const ['#'], block: const []),
  _Lang('html', {}, line: const [], block: const [('<!--', '-->')], quotes: '"\''),
  _Lang('css', {'important', 'px', 'em', 'rem', 'auto', 'none', 'inherit'}, line: const [], quotes: '"\''),
];

const _aliases = {
  'py': 'python', 'python3': 'python', 'js': 'javascript', 'jsx': 'javascript', 'node': 'javascript', 'ts': 'typescript', 'tsx': 'typescript', 'kt': 'kotlin', 'c++': 'cpp', 'cc': 'cpp', 'h': 'c',
  'cs': 'csharp', 'c#': 'csharp', 'golang': 'go', 'rs': 'rust', 'rb': 'ruby', 'sh': 'bash', 'shell': 'bash', 'zsh': 'bash', 'console': 'bash', 'yml': 'yaml', 'xml': 'html', 'svg': 'html', 'scss': 'css',
};

// dart format on

/// The language name to show above the block ("python"), or '' when the
/// sender wrote none. Unknown names are shown as written (lower case).
String codeLangLabel(String lang) {
  final s = lang.trim().toLowerCase();
  if (s.isEmpty) return '';
  return s.length > 20 ? s.substring(0, 20) : s;
}

_Lang? _find(String lang) {
  final s = lang.trim().toLowerCase();
  final n = _aliases[s] ?? s;
  for (final l in _langs) {
    if (l.name == n) return l;
  }
  return null;
}

/// Unknown or no language: quotes, numbers and the common note marks only.
const _plainLang = _Lang('', {}, line: ['//', '#'], quotes: '"\'');

bool _wordChar(int c) => (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || c == 95 || c == 36;
bool _digit(int c) => c >= 48 && c <= 57;

/// Splits [code] into coloured parts. Joining every part's text gives back
/// [code] exactly.
List<CodeSpan> colourCode(String code, String lang) {
  final l = _find(lang) ?? _plainLang;
  final out = <CodeSpan>[];
  final s = code;
  var i = 0, plainFrom = 0;
  void add(int from, int to, CodePart p) {
    if (plainFrom < from) _push(out, s.substring(plainFrom, from), CodePart.plain);
    _push(out, s.substring(from, to), p);
    plainFrom = to;
  }

  while (i < s.length) {
    // Notes (comments).
    String? lineMark;
    for (final m in l.line) {
      if (s.startsWith(m, i)) lineMark = m;
    }
    // "#" in an unknown language counts as a note only at the start of a line.
    if (lineMark == '#' && l.name.isEmpty && !_lineStart(s, i)) lineMark = null;
    if (lineMark != null) {
      final e = s.indexOf('\n', i);
      final end = e < 0 ? s.length : e;
      add(i, end, CodePart.comment);
      i = end;
      continue;
    }
    (String, String)? blk;
    for (final b in l.block) {
      if (s.startsWith(b.$1, i)) blk = b;
    }
    if (blk != null) {
      final e = s.indexOf(blk.$2, i + blk.$1.length);
      final end = e < 0 ? s.length : e + blk.$2.length;
      add(i, end, CodePart.comment);
      i = end;
      continue;
    }
    final c = s.codeUnitAt(i);
    // Words in quotes (Python's """ … """ too).
    if (l.quotes.contains(s[i])) {
      final q = s[i];
      if (l.triple && s.startsWith(q * 3, i)) {
        final e = s.indexOf(q * 3, i + 3);
        final end = e < 0 ? s.length : e + 3;
        add(i, end, CodePart.string);
        i = end;
        continue;
      }
      var j = i + 1;
      while (j < s.length && s[j] != q && (q == '`' || s[j] != '\n')) {
        if (s[j] == '\\') j++;
        j++;
      }
      final end = j < s.length && s[j] == q ? j + 1 : j.clamp(0, s.length);
      add(i, end, CodePart.string);
      i = end;
      continue;
    }
    if (_digit(c) && (i == 0 || !_wordChar(s.codeUnitAt(i - 1)))) {
      var j = i + 1;
      while (j < s.length && (_wordChar(s.codeUnitAt(j)) || s[j] == '.') && !(s[j] == '.' && j + 1 < s.length && s[j + 1] == '.')) {
        j++;
      }
      add(i, j, CodePart.number);
      i = j;
      continue;
    }
    if (_wordChar(c)) {
      var j = i + 1;
      while (j < s.length && _wordChar(s.codeUnitAt(j))) {
        j++;
      }
      final w = s.substring(i, j);
      if (l.keywords.contains(l.caseless ? w.toLowerCase() : w)) {
        add(i, j, CodePart.keyword);
      } else if (l.name != 'json' && l.name != 'sql' && j < s.length && s[j] == '(') {
        add(i, j, CodePart.function);
      } else if (l.name.isNotEmpty && l.name != 'sql' && l.name != 'json' && w.length > 1 && _upper(w.codeUnitAt(0)) && w.contains(RegExp('[a-z]'))) {
        add(i, j, CodePart.type);
      }
      i = j;
      continue;
    }
    i++;
  }
  if (plainFrom < s.length) _push(out, s.substring(plainFrom), CodePart.plain);
  return out;
}

bool _upper(int c) => c >= 65 && c <= 90;

bool _lineStart(String s, int i) {
  var j = i - 1;
  while (j >= 0 && (s[j] == ' ' || s[j] == '\t')) {
    j--;
  }
  return j < 0 || s[j] == '\n';
}

void _push(List<CodeSpan> out, String text, CodePart p) {
  if (text.isEmpty) return;
  if (out.isNotEmpty && out.last.part == p) {
    out[out.length - 1] = CodeSpan(out.last.text + text, p);
  } else {
    out.add(CodeSpan(text, p));
  }
}

/// One piece of a message: words, or a ``` code block ```.
class TextPiece {
  const TextPiece.words(this.text) : code = false, lang = '';
  const TextPiece.code(this.text, this.lang) : code = true;
  final String text;
  final bool code;
  final String lang;
}

final _fence = RegExp(r'^[ \t]*```');

/// Splits a message into words and ``` blocks (a block runs from a line
/// starting with ``` to the next such line; a block left open runs to the
/// end, as people often forget the closing marks).
List<TextPiece> splitCode(String text) {
  if (!text.contains('```')) return [TextPiece.words(text)];
  final lines = text.split('\n');
  final out = <TextPiece>[];
  final words = <String>[];
  void flush() {
    if (words.isEmpty) return;
    out.add(TextPiece.words(words.join('\n')));
    words.clear();
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (!_fence.hasMatch(line)) {
      words.add(line);
      i++;
      continue;
    }
    final after = line.trimLeft().substring(3);
    // ```one line``` on a single line.
    final close = after.indexOf('```');
    if (close >= 0) {
      flush();
      out.add(TextPiece.code(after.substring(0, close), ''));
      final rest = after.substring(close + 3).trim();
      if (rest.isNotEmpty) words.add(rest);
      i++;
      continue;
    }
    // A language name is one word; anything else on the line is code.
    final lang = RegExp(r'^[A-Za-z0-9_+#.-]{1,20}$').hasMatch(after.trim()) ? after.trim() : '';
    final code = <String>[if (lang.isEmpty && after.trim().isNotEmpty) after];
    flush();
    i++;
    while (i < lines.length && !_fence.hasMatch(lines[i])) {
      code.add(lines[i]);
      i++;
    }
    var tail = '';
    if (i < lines.length) {
      final t = lines[i].trimLeft().substring(3);
      tail = t.trim();
      i++;
    }
    out.add(TextPiece.code(code.join('\n'), lang));
    if (tail.isNotEmpty) words.add(tail);
  }
  flush();
  // Empty word pieces between blocks are dropped.
  return out.where((p) => p.code || p.text.trim().isNotEmpty).toList();
}
