// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 캘린더에 추가: a plan goes into the phone's own calendar app. Phones open
// their native "new event" screen already filled in (the person still taps
// 추가 there); the web downloads a standard .ics file that Calendar opens.
// Nothing is sent to any server.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'phone.dart';

class CalendarEvent {
  const CalendarEvent({required this.title, required this.start, this.end, this.place, this.id = ''});
  final String title;
  final DateTime start;
  final DateTime? end;
  final String? place;

  /// Stays the same for one plan, so adding it twice updates one event.
  final String id;

  /// The end the calendar gets: the set end, else two hours later.
  DateTime get until => end != null && end!.isAfter(start) ? end! : start.add(const Duration(hours: 2));

  /// RFC 5545 text (UTC times, folded lines, escaped text).
  String ics({DateTime? now}) {
    String t(DateTime d) {
      final u = d.toUtc();
      String two(int v) => v.toString().padLeft(2, '0');
      return '${u.year.toString().padLeft(4, '0')}${two(u.month)}${two(u.day)}T${two(u.hour)}${two(u.minute)}${two(u.second)}Z';
    }

    String esc(String s) => s.replaceAll(r'\', r'\\').replaceAll(';', r'\;').replaceAll(',', r'\,').replaceAll(RegExp(r'\r?\n'), r'\n');
    final uid = id.isEmpty ? '${start.millisecondsSinceEpoch}-${title.hashCode & 0x7fffffff}' : id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    final lines = [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Burumy//Plan//EN',
      'BEGIN:VEVENT',
      'UID:$uid@burumy',
      'DTSTAMP:${t(now ?? DateTime.now())}',
      'DTSTART:${t(start)}',
      'DTEND:${t(until)}',
      'SUMMARY:${esc(title)}',
      if (place != null && place!.isNotEmpty) 'LOCATION:${esc(place!)}',
      'BEGIN:VALARM',
      'TRIGGER:-PT1H',
      'ACTION:DISPLAY',
      'DESCRIPTION:${esc(title)}',
      'END:VALARM',
      'END:VEVENT',
      'END:VCALENDAR',
    ];
    return '${lines.map(_fold).join('\r\n')}\r\n';
  }

  /// Lines longer than 75 bytes continue on the next line after a space.
  static String _fold(String line) {
    final bytes = utf8.encode(line);
    if (bytes.length <= 75) return line;
    final out = StringBuffer();
    var count = 0;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final n = utf8.encode(ch).length;
      if (count + n > 74) {
        out.write('\r\n ');
        count = 1;
      }
      out.write(ch);
      count += n;
    }
    return out.toString();
  }

  static const _ch = MethodChannel('app.burumy/phone');

  /// Tests and the look-only web demo watch this.
  static Future<bool> Function(CalendarEvent e)? debugAdd;

  /// Opens the phone's "new event" screen (iPhone EventKit, Android
  /// Calendar app); the web downloads the .ics file. false = couldn't.
  Future<bool> add() async {
    if (debugAdd != null) return debugAdd!(this);
    if (kIsWeb) {
      final r = await Phone.share(bytes: Uint8List.fromList(utf8.encode(ics())), name: 'plan.ics', mime: 'text/calendar', saveOnly: true);
      return r != 'failed';
    }
    try {
      return await _ch.invokeMethod<bool>('addEvent', {
            'title': title,
            'start': start.millisecondsSinceEpoch,
            'end': until.millisecondsSinceEpoch,
            'place': place ?? '',
          }) ==
          true;
    } catch (_) {
      return false;
    }
  }
}
