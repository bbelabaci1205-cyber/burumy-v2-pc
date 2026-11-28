// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The alerts menu of one chat (Telegram tips 106 + 330): sound only off,
// off for 1 hour / 8 hours / 1 day / 7 days / a time I pick, or off until
// I turn them on. Everything stays on this phone.
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../core/app_state.dart';
import '../core/chat_mute.dart';
import '../core/my_sounds.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'in_app_notice.dart' show soundKey;
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show pickDateTime;
import 'settings_notify.dart' show SoundPage;
import 'wide.dart';

/// "1시간", "8시간", "1일", "7일".
String muteLength(L l, Duration d) => d.inHours < 24 ? l.muteHours(d.inHours) : l.muteDays(d.inDays);

/// Opens the menu for [roomId]; [muted] = alerts are off right now.
Future<void> openMuteSheet(BuildContext context, String roomId, {required bool muted}) async {
  final l = L.of(context);
  final app = AppScope.read(context);
  final quiet = app.on(quietKey(roomId));
  final end = muteEnd(app.settings, roomId);
  final pick = await showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (x) => IosActionSheet(
      title: muted && end != null ? Text(l.muteEndsAt(_when(x, end))) : null,
      actions: [
        if (muted)
          CupertinoActionSheetAction(key: const Key('mute-off'), onPressed: () => Navigator.pop(x, 'on'), child: Text(l.chatUnmute))
        else
          CupertinoActionSheetAction(
            key: const Key('mute-sound'),
            onPressed: () => Navigator.pop(x, 'sound'),
            child: Text(quiet ? l.muteSoundOn : l.muteSoundOff),
          ),
        for (final d in muteChoices)
          CupertinoActionSheetAction(
            key: Key('mute-${d.inHours}h'),
            onPressed: () => Navigator.pop(x, '${d.inMinutes}'),
            child: Text(l.muteFor(muteLength(l, d))),
          ),
        CupertinoActionSheetAction(key: const Key('mute-custom'), onPressed: () => Navigator.pop(x, 'custom'), child: Text(l.muteCustom)),
        // 알림음 바꾸기 (tip 329): this chat's own sound.
        CupertinoActionSheetAction(key: const Key('mute-tone'), onPressed: () => Navigator.pop(x, 'tone'), child: Text(l.toneForChat)),
        if (!muted)
          CupertinoActionSheetAction(
            key: const Key('mute-forever'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(x, 'forever'),
            child: Text(l.chatMute),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  switch (pick) {
    case 'on':
      await app.unmuteChat(roomId);
      if (context.mounted) showInfoBanner(context, l.unmutedToast, '', icon: CupertinoIcons.bell_fill);
    case 'sound':
      await app.setChatQuiet(roomId, !quiet);
      if (context.mounted)
        showInfoBanner(context, quiet ? l.soundOnToast : l.soundOffToast, '', icon: quiet ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill);
    case 'forever':
      await app.muteChat(roomId, null);
      if (context.mounted) showInfoBanner(context, l.mutedToast, '', icon: CupertinoIcons.bell_slash_fill);
    case 'tone':
      final chat = app.chats.where((c) => c.roomId == roomId).firstOrNull;
      final kindKey = chat == null ? 'sound_direct' : soundKey(chat);
      await Navigator.of(context).push(
        IosPageRoute<void>(
          builder: (_) => SoundPage(prefKey: MySounds.chatKey(roomId), chatDefault: app.pref(kindKey, 'nuri')),
        ),
      );
    case 'custom':
      final now = app.backend.clock;
      final at = await pickDateTime(context, now, title: l.muteUntilTitle);
      if (at == null || !context.mounted) return;
      await app.muteChat(roomId, at.difference(now));
      if (context.mounted) showInfoBanner(context, l.mutedUntilToast(_when(context, at)), '', icon: CupertinoIcons.bell_slash_fill);
    default:
      final d = Duration(minutes: int.parse(pick));
      await app.muteChat(roomId, d);
      if (context.mounted) showInfoBanner(context, l.mutedForToast(muteLength(l, d)), '', icon: CupertinoIcons.bell_slash_fill);
  }
}

/// "11월 28일 오후 3:00" in the app's language.
String _when(BuildContext context, DateTime t) => DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(t);
