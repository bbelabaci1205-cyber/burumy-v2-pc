// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PDF 형광펜 (4-app board, WhatsApp 2025): words picked in a PDF opened in
// a chat get a highlighter mark. Marks are kept on this phone only (with the
// other settings, encrypted on the phone); nobody else sees them unless I
// send them to the chat as a quote.
import 'dart:convert';

import 'app_state.dart';

/// One highlighted run of words.
class PdfMark {
  const PdfMark({required this.page, required this.rects, required this.text, required this.at});

  /// 1-based page number.
  final int page;

  /// One box per line, in PDF page units (left, top, right, bottom; top is
  /// the bigger number, as PDFs count from the bottom).
  final List<(double, double, double, double)> rects;

  /// The words themselves (for the list and for sending).
  final String text;
  final DateTime at;

  String get id => '${at.microsecondsSinceEpoch}';

  Map<String, Object> toJson() => {
    'p': page,
    'r': [
      for (final r in rects) [r.$1, r.$2, r.$3, r.$4],
    ],
    't': text,
    'a': at.microsecondsSinceEpoch,
  };

  static PdfMark? fromJson(Object? j) {
    if (j is! Map) return null;
    final p = j['p'], t = j['t'], a = j['a'], r = j['r'];
    if (p is! int || t is! String || a is! int || r is! List) return null;
    final rects = <(double, double, double, double)>[];
    for (final x in r) {
      if (x is List && x.length == 4 && x.every((v) => v is num)) {
        rects.add(((x[0] as num).toDouble(), (x[1] as num).toDouble(), (x[2] as num).toDouble(), (x[3] as num).toDouble()));
      }
    }
    return PdfMark(page: p, rects: rects, text: t, at: DateTime.fromMicrosecondsSinceEpoch(a));
  }
}

class PdfMarks {
  const PdfMarks._();

  static const prefKey = 'pdf_marks';

  /// Files with marks kept (oldest dropped), and marks per file.
  static const maxDocs = 60, maxPerDoc = 300;

  /// Longest text kept for one mark.
  static const maxText = 1000;

  static Map<String, dynamic> _all(AppState s) {
    try {
      final v = jsonDecode(s.pref(prefKey, '{}'));
      return v is Map<String, dynamic> ? v : {};
    } catch (_) {
      return {};
    }
  }

  /// This file's marks, in page order then top to bottom.
  static List<PdfMark> of(AppState s, String docId) {
    final raw = _all(s)[docId];
    if (raw is! List) return const [];
    final out = [for (final x in raw) ?PdfMark.fromJson(x)];
    out.sort((a, b) {
      if (a.page != b.page) return a.page.compareTo(b.page);
      final ay = a.rects.isEmpty ? 0.0 : a.rects.first.$2, by = b.rects.isEmpty ? 0.0 : b.rects.first.$2;
      return by.compareTo(ay);
    });
    return out;
  }

  static Future<void> _save(AppState s, String docId, List<PdfMark> marks) async {
    final all = _all(s)..remove(docId);
    if (marks.isNotEmpty) all[docId] = [for (final m in marks.take(maxPerDoc)) m.toJson()];
    // Newest last: drop the oldest files past the cap.
    while (all.length > maxDocs) {
      all.remove(all.keys.first);
    }
    await s.setPref(prefKey, jsonEncode(all));
  }

  static Future<void> add(AppState s, String docId, List<PdfMark> marks) async {
    if (marks.isEmpty) return;
    final cut = [
      for (final m in marks)
        if (m.rects.isNotEmpty)
          PdfMark(page: m.page, rects: m.rects, text: m.text.length > maxText ? '${m.text.substring(0, maxText)}…' : m.text, at: m.at),
    ];
    await _save(s, docId, [...of(s, docId), ...cut]);
  }

  static Future<void> remove(AppState s, String docId, Set<String> ids) => _save(s, docId, [
    for (final m in of(s, docId))
      if (!ids.contains(m.id)) m,
  ]);

  /// One box per line from the boxes of single letters (as PDFs give
  /// them). Letters on the same line overlap in height; a new line starts
  /// when one doesn't, or when the words jump back to the left.
  static List<(double, double, double, double)> lines(Iterable<(double, double, double, double)> chars) {
    final out = <(double, double, double, double)>[];
    (double, double, double, double)? cur;
    for (final c in chars) {
      final (l, t, r, b) = c;
      if (r - l <= 0 || t - b <= 0) continue;
      if (cur != null) {
        final (cl, ct, cr, cb) = cur;
        final mid = (t + b) / 2;
        final sameLine = mid <= ct && mid >= cb && l >= cl - (ct - cb);
        if (sameLine) {
          cur = (cl < l ? cl : l, ct > t ? ct : t, cr > r ? cr : r, cb < b ? cb : b);
          continue;
        }
        out.add(cur);
      }
      cur = c;
    }
    if (cur != null) out.add(cur);
    return out;
  }
}
