// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Phone numbers inside messages (TelegramTips 453, our way): a tap on a
// number lifts it as a small green capsule over the blurred chat with the
// iOS menu under it: call, text, copy, save to the phone's contacts.
// Burumy never looks people up by phone number (no "find on Burumy" row):
// the number stays between the chat and the phone's own apps.
import 'dart:convert' show utf8;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'glass.dart';
import 'message_menu.dart';

/// A run of digits that looks like a phone number: starts with +, 0 or a
/// bracket (Korean and international numbers), or a Korean 4-digit company
/// line (1588-1234). Dates (2026-11-27) and plain sums don't match.
final _candidate = RegExp(r'(?<![\w+])(\+|\()?\d[\d\s().-]{5,18}\d(?![\w])');
final _company = RegExp(r'^1[5-9]\d{2}-?\d{4}$');

/// The digits to dial (+ kept).
String dialDigits(String shown) => shown.replaceAll(RegExp(r'[^\d+]'), '');

bool _isPhone(String s) {
  final d = dialDigits(s);
  final digits = d.replaceAll('+', '');
  if (_company.hasMatch(s.trim())) return true;
  if (digits.length < 9 || digits.length > 15) return false;
  if (s.contains('\n')) return false;
  // A date or time written with dashes / dots is not a number to call.
  if (RegExp(r'^(19|20)\d{2}[.-]\d{1,2}[.-]\d{1,2}').hasMatch(s)) return false;
  return s.startsWith('+') || s.startsWith('0') || s.startsWith('(');
}

/// Phone numbers found in [text]: (start, end) pairs.
List<(int, int)> findPhones(String text) => [
  for (final m in _candidate.allMatches(text))
    if (_isPhone(m.group(0)!.trim())) (m.start, m.start + m.group(0)!.trimRight().length),
];

/// The menu for one number.
Future<void> openPhoneMenu(BuildContext context, String shown) async {
  final l = L.of(context);
  final p = paletteOf(context);
  final digits = dialDigits(shown);
  final got = await showMessageMenu(
    context,
    mine: false,
    reactions: const [],
    bubble: LiquidGlass(
      key: const Key('phone-capsule'),
      radius: Tokens.capsule,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
        child: Text(shown.trim(), style: Tokens.body.style.copyWith(color: p.accent)),
      ),
    ),
    items: [
      MenuItem('phone-call', l.phoneCall, CupertinoIcons.phone),
      MenuItem('phone-sms', l.phoneText, CupertinoIcons.chat_bubble),
      MenuItem('phone-copy', l.phoneCopy, CupertinoIcons.doc_on_doc),
      MenuItem('phone-save', l.phoneSave, CupertinoIcons.person_crop_circle_badge_plus, group: true),
    ],
  );
  if (!context.mounted) return;
  switch (got) {
    case 'phone-call':
      await launchUrl(Uri(scheme: 'tel', path: digits));
    case 'phone-sms':
      await launchUrl(Uri(scheme: 'sms', path: digits));
    case 'phone-copy':
      await Clipboard.setData(ClipboardData(text: digits));
      if (context.mounted) showInfoBanner(context, l.phoneCopied, shown.trim());
    case 'phone-save':
      // A one-person contact card handed to the phone's share sheet:
      // iPhone shows "Create New Contact / Add to Existing Contact".
      final card = 'BEGIN:VCARD\r\nVERSION:3.0\r\nTEL;TYPE=CELL:$digits\r\nEND:VCARD\r\n';
      await Phone.share(bytes: Uint8List.fromList(utf8.encode(card)), name: 'contact.vcf', mime: 'text/vcard');
  }
}
