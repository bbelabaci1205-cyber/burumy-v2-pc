// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// "오류 내용 보기": the last errors, kept in memory on this phone only.
// Only the error text and where it happened, never message content.

class ErrorLog {
  static final items = <(DateTime, String)>[];

  /// Only while the switch is on (Settings > Privacy and Security).
  static bool keep = false;

  static void add(Object error, [StackTrace? stack]) {
    if (!keep) return;
    final where = stack?.toString().split('\n').where((l) => l.contains('package:burumy')).take(3).join('\n') ?? '';
    var text = '$error';
    if (text.length > 600) text = '${text.substring(0, 600)}…';
    items.insert(0, (DateTime.now(), where.isEmpty ? text : '$text\n$where'));
    if (items.length > 50) items.removeLast();
  }
}
