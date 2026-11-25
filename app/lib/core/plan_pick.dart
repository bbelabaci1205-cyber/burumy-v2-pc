// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Chats > Find plans (일정 뽑기): finds dates and times written in
// a message ("내일 3시", "12월 7일 오후 7시", "토요일 저녁 6시 반") so a tap
// can set a reminder. Runs on this phone only; nothing is sent anywhere.

class PlanHit {
  const PlanHit(this.start, this.end, this.at);
  final int start;
  final int end;
  final DateTime at;
}

final _plan = RegExp(
  r'(?:(?<md>(?<mon>\d{1,2})\s*월\s*(?<day>\d{1,2})\s*일)|(?<rel>오늘|내일|모레)|(?<next>다음\s*주\s*)?(?<wd>[월화수목금토일])요일)?'
  r'\s*(?:(?<ap>오전|오후|아침|낮|저녁|밤|새벽)\s*)?(?:(?<h>\d{1,2})\s*시(?:\s*(?<min>\d{1,2})\s*분|\s*(?<half>반))?)?',
);

const _weekdays = '월화수목금토일';

/// Plans in [text], counted from [now]. Only future times are kept.
List<PlanHit> findPlans(String text, DateTime now) {
  final out = <PlanHit>[];
  for (final m in _plan.allMatches(text)) {
    if (m.end == m.start) continue;
    final hasDay = m.namedGroup('md') != null || m.namedGroup('rel') != null || m.namedGroup('wd') != null;
    final h = int.tryParse(m.namedGroup('h') ?? '');
    if (!hasDay && h == null) continue;
    // A bare "3시" with nothing around it is too vague unless am/pm is said.
    if (!hasDay && m.namedGroup('ap') == null && m.namedGroup('min') == null && m.namedGroup('half') == null) {
      final after = text.substring(m.end).trimLeft();
      if (!after.startsWith('에')) continue;
    }
    var day = DateTime(now.year, now.month, now.day);
    if (m.namedGroup('md') != null) {
      final mon = int.parse(m.namedGroup('mon')!), d = int.parse(m.namedGroup('day')!);
      if (mon < 1 || mon > 12 || d < 1 || d > 31) continue;
      day = DateTime(now.year, mon, d);
      if (day.isBefore(DateTime(now.year, now.month, now.day))) day = DateTime(now.year + 1, mon, d);
    } else if (m.namedGroup('rel') != null) {
      day = day.add(Duration(days: const {'오늘': 0, '내일': 1, '모레': 2}[m.namedGroup('rel')]!));
    } else if (m.namedGroup('wd') != null) {
      final want = _weekdays.indexOf(m.namedGroup('wd')!) + 1;
      var add = (want - now.weekday) % 7;
      if (m.namedGroup('next') != null) add += 7;
      day = day.add(Duration(days: add));
    }
    var hour = h ?? 9, minute = 0;
    if (h != null) {
      if (h > 24) continue;
      minute = m.namedGroup('half') != null ? 30 : int.tryParse(m.namedGroup('min') ?? '') ?? 0;
      if (minute > 59) continue;
      final ap = m.namedGroup('ap');
      final pm = ap == '오후' || ap == '저녁' || ap == '밤' || (ap == '낮' && h < 6);
      if (pm && h < 12) hour = h + 12;
      // No am/pm: 1-7 o'clock usually means the afternoon.
      if (ap == null && h >= 1 && h <= 7) hour = h + 12;
      if (hour == 24) hour = 0;
    }
    var at = DateTime(day.year, day.month, day.day, hour, minute);
    if (!hasDay && !at.isAfter(now)) at = at.add(const Duration(days: 1));
    if (!at.isAfter(now)) continue;
    var start = m.start, end = m.end;
    while (start < end && text[start] == ' ') {
      start++;
    }
    while (end > start && text[end - 1] == ' ') {
      end--;
    }
    out.add(PlanHit(start, end, at));
  }
  return out;
}
