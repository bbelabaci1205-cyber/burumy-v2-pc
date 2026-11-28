// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 정리하기 (v1 parity batch 5, 2026-11-27): groups and channels with
// no new message for 6 months, picked in one list and left together. The
// usual 5-second undo bar comes up before anything is left.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart';
import 'common.dart';
import 'ios.dart';
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';

/// How long a room must be quiet to show up here.
const tidyQuietFor = Duration(days: 182);

/// Groups and channels whose last message is older than [tidyQuietFor].
List<ChatPreview> quietChats(List<ChatPreview> chats, DateTime now) => [
  for (final c in chats)
    if (!c.isDirect && c.last != null && now.difference(c.last!.time) >= tidyQuietFor && !PendingDelete.has(c.roomId)) c,
];

class TidyChatsPage extends StatefulWidget {
  const TidyChatsPage({super.key});
  @override
  State<TidyChatsPage> createState() => _TidyChatsPageState();
}

class _TidyChatsPageState extends State<TidyChatsPage> {
  /// Picked to leave. All of them are picked at first.
  Set<String>? picked;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final app = AppScope.of(context);
    return ValueListenableBuilder<(String, int)?>(
      valueListenable: PendingDelete.notifier,
      builder: (context, _, _) {
        final list = quietChats(app.chats, app.backend.clock);
        final on = picked ??= {for (final c in list) c.roomId};
        final chosen = [
          for (final c in list)
            if (on.contains(c.roomId)) c.roomId,
        ];
        return Stack(
          children: [
            SettingsScaffold(
              title: l.tidyChats,
              children: [
                group(context, footer: l.tidyChatsInfo, [
                  for (final c in list)
                    IosTile(
                      key: Key('tidy-${c.roomId}'),
                      leading: Avatar(name: c.name, size: 30, squircle: true, roomId: c.roomId),
                      title: Text(c.name),
                      subtitle: Text(l.tidyLast(DateFormatLite.ymd(c.last!.time))),
                      trailing: Icon(
                        on.contains(c.roomId) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                        color: on.contains(c.roomId) ? p.accent : p.secondaryLabel,
                      ),
                      onTap: () => setState(() => on.contains(c.roomId) ? on.remove(c.roomId) : on.add(c.roomId)),
                    ),
                  if (list.isEmpty) IosTile(key: const Key('tidy-empty'), title: Text(l.tidyNone)),
                ]),
                if (chosen.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(Tokens.space[3]),
                    child: AccentButton(key: const Key('tidy-leave'), text: l.tidyLeave(chosen.length), onTap: () => PendingDelete.startMany(app, chosen)),
                  ),
              ],
            ),
            Positioned(left: 0, right: 0, bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[2], child: const DeleteUndoBar()),
          ],
        );
      },
    );
  }
}

/// "2026. 5. 3." without pulling locale data in.
class DateFormatLite {
  static String ymd(DateTime t) => '${t.year}. ${t.month}. ${t.day}.';
}
