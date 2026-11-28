// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 보관함 설정 (Telegram tip 187): the archive's ⋯ menu (보관함 설정 /
// 보관함은 이렇게 써요), the "이게 보관함이에요" sheet shown the first time
// the archive opens, and the settings page with its three switches. The
// rules themselves are in core/archive_rules.dart.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/archive_rules.dart';
import '../core/features.dart';
import '../core/login_safety.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show AccentButton, GlassSheet;
import 'settings_kit.dart';
import 'wide.dart';

/// Shown once, the first time the archive opens.
const archiveIntroSeenKey = 'archive_intro_seen';

/// The archive's ⋯ button (top right).
class ArchiveMenuButton extends StatelessWidget {
  const ArchiveMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCircle(key: const Key('archive-more'), onTap: () => openArchiveMenu(context), child: GlassCircle.icon(context, CupertinoIcons.ellipsis));
  }
}

Future<void> openArchiveMenu(BuildContext context) async {
  final l = L.of(context);
  final pick = await showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (x) => IosActionSheet(
      actions: [
        CupertinoActionSheetAction(key: const Key('archive-menu-settings'), onPressed: () => Navigator.pop(x, 'settings'), child: Text(l.archiveSettings)),
        CupertinoActionSheetAction(key: const Key('archive-menu-how'), onPressed: () => Navigator.pop(x, 'how'), child: Text(l.archiveHow)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  if (pick == 'settings') {
    await Navigator.of(context).push(IosPageRoute<void>(builder: (_) => const ArchiveSettingsPage()));
  } else {
    await showArchiveIntro(context);
  }
}

/// "이게 보관함이에요": what the archive does, in three lines.
Future<void> showArchiveIntro(BuildContext context) {
  final s = AppScope.read(context);
  if (!s.on(archiveIntroSeenKey)) s.setOn(archiveIntroSeenKey, true);
  return showCupertinoModalPopup<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) {
      final l = L.of(c);
      final p = paletteOf(c);
      Widget line(IconData icon, String title, String body) => Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[4], 0, Tokens.space[4], Tokens.space[3]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: p.accent),
            SizedBox(width: Tokens.space[2] + Tokens.space[0]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Text(body, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
          ],
        ),
      );
      return GlassSheet(
        key: const Key('archive-intro'),
        children: [
          SizedBox(height: Tokens.space[2]),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.archivebox_fill, size: 32, color: Color(0xFFFFFFFF)),
            ),
          ),
          SizedBox(height: Tokens.space[2]),
          Text(
            l.archiveIntroTitle,
            textAlign: TextAlign.center,
            style: Tokens.cardTitle.style.copyWith(color: p.label),
          ),
          SizedBox(height: Tokens.space[4]),
          line(CupertinoIcons.archivebox, l.archiveIntro1Title, l.archiveIntro1),
          line(CupertinoIcons.bell_slash, l.archiveIntro2Title, l.archiveIntro2),
          line(CupertinoIcons.hand_draw, l.archiveIntro3Title, l.archiveIntro3),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[3]),
            child: AccentButton(key: const Key('archive-intro-ok'), text: l.okButton, onTap: () => Navigator.of(c).pop()),
          ),
        ],
      );
    },
  );
}

class ArchiveSettingsPage extends StatelessWidget {
  const ArchiveSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SettingsScaffold(
      title: l.archiveSettings,
      children: [
        HeaderCard(color: Palette.tileGrey, icon: CupertinoIcons.archivebox_fill, title: l.archiveSettings, body: l.archiveSettingsInfo),
        group(context, header: l.archiveUnmutedHeader, footer: l.archiveUnmutedInfo, [
          PrefSwitch(archiveKeepUnmutedKey, key: const Key('archive-keep-unmuted'), title: l.archiveKeepUnmuted),
        ]),
        group(context, header: l.archiveFolderHeader, footer: l.archiveFolderInfo, [
          PrefSwitch(archiveKeepFolderKey, key: const Key('archive-keep-folder'), title: l.archiveKeepFolder),
        ]),
        // Tip 343 (already built): strangers' first chats go in, muted.
        if (Features.loginSafety)
          group(context, header: l.archiveStrangerHeader, footer: l.strangerArchiveSub, [
            PrefSwitch(LoginSafety.strangerArchiveKey, key: const Key('archive-strangers'), title: l.strangerArchive),
          ]),
      ],
    );
  }
}
