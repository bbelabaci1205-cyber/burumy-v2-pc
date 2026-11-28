// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 인증 코드 복사 (Telegram tip 477, Eric 2026-11-27 option A): a received
// message that looks like a login / verification code gets a "코드 복사"
// button. Found on this phone only (the message is already decrypted
// here), nothing is sent anywhere. The copied code is cleared from the
// clipboard after a minute, like iOS's one-time codes.
import 'dart:async';

import 'package:flutter/services.dart';

/// Words that say "this is a code" (Korean + English).
final _codeWords = RegExp(r'(인증|확인|보안|로그인|일회용|승인)\s*(번호|코드)|코드|인증번호|verification|verify|code|otp|one[- ]time|passcode|pin\b', caseSensitive: false);

/// 4–8 digits, maybe split once ("123 456", "123-456"), or a short
/// letter+digit code ("G-482913", "AB12CD").
final _codeRe = RegExp(r'(?<![\w-])(\d{3,4}[ -]\d{3,4}|\d{4,8}|[A-Z]{1,3}-\d{4,8}|(?=[A-Z0-9]{6,8}\b)(?=[A-Z0-9]*\d)(?=[A-Z0-9]*[A-Z])[A-Z0-9]{6,8})(?![\w-])');

/// Things that look like codes but are not (money, years, times, phones).
final _notCode = RegExp(r'^(19|20)\d\d$');

/// The code in [text], or null. Only short messages (a long article with
/// a number is not a code message).
String? findCode(String text) {
  if (text.length > 400 || !_codeWords.hasMatch(text)) return null;
  for (final m in _codeRe.allMatches(text)) {
    final raw = m.group(1)!;
    final before = m.start > 0 ? text[m.start - 1] : '';
    final after = m.end < text.length ? text[m.end] : '';
    // 12,000원 / 3.5 / 10:30 / 50% are not codes.
    if (before.isNotEmpty && '.,:₩\$'.contains(before)) continue;
    if (after.isNotEmpty && ',:원%'.contains(after)) continue;
    if (after == '.' && m.end + 1 < text.length && RegExp(r'\d').hasMatch(text[m.end + 1])) continue;
    if (_notCode.hasMatch(raw)) continue;
    final clean = raw.contains(RegExp(r'[A-Z]')) ? raw : raw.replaceAll(RegExp(r'[ -]'), '');
    if (RegExp(r'^\d+$').hasMatch(clean) && (clean.length < 4 || clean.length > 8)) continue;
    return clean;
  }
  return null;
}

Timer? _clear;

/// Copies [code]; clears it from the clipboard after [keep] unless the
/// user copied something else meanwhile.
Future<void> copyCode(String code, {Duration keep = const Duration(minutes: 1)}) async {
  await Clipboard.setData(ClipboardData(text: code));
  _clear?.cancel();
  _clear = Timer(keep, () async {
    try {
      final now = await Clipboard.getData(Clipboard.kTextPlain);
      if (now?.text == code) await Clipboard.setData(const ClipboardData(text: ''));
    } catch (_) {}
  });
}
