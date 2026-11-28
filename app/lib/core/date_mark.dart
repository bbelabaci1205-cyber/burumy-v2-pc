// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 날짜 표시 (Telegram tip 559): words in a message can carry an exact
// moment, written as [내일 10시](t:1772272800) — the seconds since 1970 in
// world time (UTC). The mark travels inside the encrypted message like
// every other format mark, so the server never sees it. Each reader's
// phone shows the moment in that reader's own time zone, and a tap offers
// 날짜 복사 / 캘린더에 추가 / 알림 설정.

/// [words](t:seconds)
final dateMark = RegExp(r'\[([^\]\n]+)\]\(t:(\d{1,12})\)');

/// The mark for [words] at [at].
String dateMarkText(String words, DateTime at) => '[${words.replaceAll(']', ')')}](t:${at.toUtc().millisecondsSinceEpoch ~/ 1000})';

/// The moment of a matched mark, in this phone's time zone.
DateTime dateMarkAt(Match m) => DateTime.fromMillisecondsSinceEpoch(int.parse(m.group(2)!) * 1000);

/// A short event title from a message: its first line, without marks.
String eventTitle(String plain) {
  final first = plain.trim().split('\n').first.trim();
  return first.length > 60 ? '${first.substring(0, 59)}…' : first;
}
