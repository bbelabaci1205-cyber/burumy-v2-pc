// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Small sheets from the message menu (layout from Burumy v1, sizes iOS 27):
// "알림 받기" (remind me about this message) and the web notice for the
// emergency delete / hide items.
//
// Sizes: sheet floats 10 pt from the edges with 30 pt corners (same as
// IosActionSheet), grabber 36x5, header 56 with the 44 round X on the left
// and a 17 semibold title, note 15 grey with 16 side inset, rows 52 tall
// (17 label, 13 grey time on the right).
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../core/reminders.dart';
import '../core/saved_tags.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

/// Floating glass sheet with a grabber and an optional X + title header.
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, this.title, required this.children});
  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: LiquidGlass(
        radius: IosActionSheet.radius,
        child: ColoredBox(
          color: p.card.withValues(alpha: p.dark ? 0.5 : 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  ),
                ),
              ),
              if (title != null)
                SizedBox(
                  height: Tokens.sheetHeader,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('sheet-close'),
                          onTap: () => Navigator.pop(context),
                          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                        ),
                      ),
                      Text(
                        title!,
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// One 52 pt row of a [GlassSheet].
class SheetRow extends StatefulWidget {
  const SheetRow({super.key, required this.label, this.trailing, required this.onTap});
  final String label;
  final String? trailing;
  final VoidCallback onTap;
  @override
  State<SheetRow> createState() => _SheetRowState();
}

class _SheetRowState extends State<SheetRow> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: Container(
        height: Tokens.settingsRow,
        color: down ? p.label.withValues(alpha: 0.06) : const Color(0x00000000),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0]),
        child: Row(
          children: [
            Expanded(
              child: Text(widget.label, style: Tokens.body.style.copyWith(color: p.label)),
            ),
            if (widget.trailing != null) Text(widget.trailing!, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

/// "알림 받기": returns the chosen time, or null.
Future<DateTime?> pickReminderTime(BuildContext context, {DateTime? now}) {
  return showCupertinoModalPopup<DateTime>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      final p = paletteOf(c);
      final t = now ?? DateTime.now();
      final at = reminderChoices(t);
      final fmt = DateFormat.jm(Localizations.localeOf(c).toLanguageTag());
      final labels = [l.remindIn20, l.remindIn1h, l.remindIn3h, l.remindTomorrow];
      return GlassSheet(
        key: const Key('remind-sheet'),
        title: l.remindMe,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Text(kIsWeb ? l.remindNoteWeb : l.remindNote, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          ),
          for (var i = 0; i < at.length; i++)
            SheetRow(key: Key('remind-$i'), label: labels[i], trailing: fmt.format(at[i]), onTap: () => Navigator.pop(c, at[i])),
          SheetRow(
            key: const Key('remind-pick'),
            label: l.remindPick,
            onTap: () async {
              final got = await pickDateTime(c, t);
              if (got != null && c.mounted) Navigator.pop(c, got);
            },
          ),
          SizedBox(height: Tokens.space[1]),
        ],
      );
    },
  );
}

/// iOS wheel for a date and time within the next year.
Future<DateTime?> pickDateTime(BuildContext context, DateTime now) {
  var chosen = now.add(const Duration(hours: 1));
  return showCupertinoModalPopup<DateTime>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      return GlassSheet(
        title: l.remindPick,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              key: const Key('remind-wheel'),
              initialDateTime: chosen,
              minimumDate: now,
              maximumDate: now.add(const Duration(days: 365)),
              use24hFormat: false,
              onDateTimeChanged: (d) => chosen = d,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: AccentButton(key: const Key('remind-done'), text: l.done, onTap: () => Navigator.pop(c, chosen)),
          ),
        ],
      );
    },
  );
}

/// Full-width accent capsule (52 tall), like the v1 "확인".
class AccentButton extends StatelessWidget {
  const AccentButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: Tokens.settingsRow,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          text,
          style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Web: app lock and emergency delete / hide live only in the phone app.
Future<void> showEmergencyWebNotice(BuildContext context) {
  return showCupertinoModalPopup<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      final p = paletteOf(c);
      return GlassSheet(
        key: const Key('emergency-web'),
        title: '',
        children: [
          Icon(CupertinoIcons.exclamationmark_shield, size: 44, color: p.accent),
          SizedBox(height: Tokens.space[2]),
          Text(
            l.emergencyDelete,
            textAlign: TextAlign.center,
            style: Tokens.cardTitle.style.copyWith(color: p.label),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], Tokens.space[4]),
            child: Text(
              l.emergencyWebInfo,
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[3]),
            child: AccentButton(key: const Key('emergency-ok'), text: l.okButton, onTap: () => Navigator.pop(c)),
          ),
        ],
      );
    },
  );
}

/// After saving (v1 toast sheet) or inside saved messages: the 12 emoji
/// tags as 44 pt round buttons, 8 apart. Returns the tag, '' to remove the
/// tag, or null.
Future<String?> pickSavedTag(BuildContext context, {required bool saved, String? current}) {
  return showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      final p = paletteOf(c);
      return GlassSheet(
        key: const Key('tag-sheet'),
        children: [
          SizedBox(height: Tokens.space[2]),
          Text(
            saved ? l.savedToast : l.tagMsg,
            textAlign: TextAlign.center,
            style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: Tokens.nameToSub),
          Text(
            l.savedTagHint,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: Tokens.space[1],
              runSpacing: Tokens.space[1],
              children: [
                for (final t in savedTagChoices)
                  GestureDetector(
                    key: Key('tag-$t'),
                    onTap: () => Navigator.pop(c, t),
                    child: Container(
                      width: Tokens.closeButton,
                      height: Tokens.closeButton,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: t == current ? p.accent.withValues(alpha: 0.2) : p.label.withValues(alpha: 0.06),
                      ),
                      child: Text(t, style: TextStyle(fontSize: 22, height: 1, fontFamilyFallback: Tokens.emojiFallback)),
                    ),
                  ),
              ],
            ),
          ),
          if (current != null) SheetRow(key: const Key('tag-remove'), label: l.tagRemove, onTap: () => Navigator.pop(c, '')),
        ],
      );
    },
  );
}
