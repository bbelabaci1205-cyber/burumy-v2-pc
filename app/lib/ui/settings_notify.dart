// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Notifications (Burumy v1 layout, iOS look): per kind of chat
// (show, preview, our own sound, exceptions), alerts while using the app,
// focus hours, and reset. Everything is decided on this phone.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/sounds.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'settings_page.dart' show NoticeTextSwitchTile, CallWaitingTile;
import 'wide.dart';

/// Keys every "reset all notifications" clears.
const _noticeKeys = [
  'notify_direct',
  'notify_group',
  'notify_channel',
  'preview_direct',
  'preview_group',
  'preview_channel',
  'sound_direct',
  'sound_group',
  'sound_channel',
  'in_app_style',
  'in_app_sound',
  'in_app_preview',
  'focus_on',
  'focus_from',
  'focus_to',
  'focus_days',
];

String soundLabel(L l, String name) => switch (name) {
  'nuri' => l.sound_nuri,
  'pop' => l.sound_pop,
  'drop' => l.sound_drop,
  'bell' => l.sound_bell,
  'chord' => l.sound_chord,
  'breeze' => l.sound_breeze,
  'knock' => l.sound_knock,
  'twinkle' => l.sound_twinkle,
  _ => l.soundNone,
};

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    String state(String kind) => s.on('notify_$kind', fallback: true) ? l.stateOn : l.stateOff;
    return SettingsScaffold(
      title: l.settingsNotifications,
      children: [
        HeaderCard(color: Palette.tileRed, icon: CupertinoIcons.bell_fill, title: l.settingsNotifications, body: l.notificationsInfo),
        group(context, header: l.messageNotices, [
          NavRow(
            key: const Key('notice-direct'),
            color: Palette.tileBlue,
            icon: CupertinoIcons.person_fill,
            title: l.notifyDirect,
            value: state('direct'),
            page: (_) => NoticeKindPage(kind: 'direct', title: l.notifyDirect),
          ),
          NavRow(
            key: const Key('notice-group'),
            color: p.tileGreen,
            icon: CupertinoIcons.person_3_fill,
            title: l.notifyGroup,
            value: state('group'),
            page: (_) => NoticeKindPage(kind: 'group', title: l.notifyGroup),
          ),
          NavRow(
            key: const Key('notice-channel'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.speaker_2_fill,
            title: l.notifyChannel,
            value: state('channel'),
            page: (_) => NoticeKindPage(kind: 'channel', title: l.notifyChannel),
          ),
        ]),
        group(context, [
          NavRow(
            key: const Key('in-app-row'),
            color: Palette.tileRed,
            icon: CupertinoIcons.app_badge_fill,
            title: l.inAppNotices,
            value: s.pref('in_app_style', 'banner') == 'banner' ? l.inAppBanner : l.inAppSilent,
            page: (_) => const InAppNoticePage(),
          ),
          NavRow(
            key: const Key('focus-row'),
            color: Palette.tileIndigo,
            icon: CupertinoIcons.moon_fill,
            title: l.focusSchedule,
            value: s.on('focus_on') ? l.stateOn : l.stateOff,
            page: (_) => const FocusPage(),
          ),
        ]),
        group(context, footer: l.noticeTextHiddenInfo, const [NoticeTextSwitchTile()]),
        group(context, header: l.tabCalls, footer: l.callWaitingInfo, const [CallWaitingTile()]),
        group(context, [
          CupertinoListTile(
            key: const Key('reset-notices'),
            title: Text(l.resetNotices, style: const TextStyle(color: Palette.tileRed)),
            onTap: () async {
              for (final k in _noticeKeys) {
                await s.setPref(k, '');
              }
              for (final k in s.settings.keys.where((k) => k.startsWith('notify_') && k.contains(':')).toList()) {
                await s.setPref(k, '');
              }
              await s.backend.setNoticeTextHidden(false);
              await s.backend.setCallWaiting('wait');
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ]),
      ],
    );
  }
}

/// One kind of chat: show alerts, preview, sound, exceptions per chat.
class NoticeKindPage extends StatelessWidget {
  const NoticeKindPage({super.key, required this.kind, required this.title});
  final String kind;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final sound = s.pref('sound_$kind', 'nuri');
    final prefix = 'notify_$kind:';
    final exceptions = [
      for (final e in s.settings.entries)
        if (e.key.startsWith(prefix) && e.value.isNotEmpty) (e.key.substring(prefix.length), e.value == '1'),
    ];
    String nameOf(String roomId) => s.chats.where((c) => c.roomId == roomId).firstOrNull?.name ?? roomId;
    return SettingsScaffold(
      title: title,
      children: [
        group(context, [PrefSwitch('notify_$kind', title: l.showNotices, fallback: true)]),
        group(context, footer: l.messagePreviewInfo, [
          PrefSwitch('preview_$kind', title: l.messagePreview, fallback: true),
          NavRow(
            key: const Key('sound-row'),
            title: l.sound,
            value: soundLabel(l, sound),
            page: (_) => SoundPage(prefKey: 'sound_$kind'),
          ),
        ]),
        group(context, header: l.noticeExceptions, footer: l.exceptionsInfo, [
          CupertinoListTile(
            key: const Key('add-exception'),
            leading: Icon(CupertinoIcons.add, color: p.accent, size: Tokens.listIcon),
            title: Text(l.addException, style: TextStyle(color: p.accent)),
            onTap: () async {
              final room = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => ChatPickPage(kind: kind)));
              if (room == null) return;
              // A new exception starts as the opposite of the kind's setting.
              await s.setPref('$prefix$room', s.on('notify_$kind', fallback: true) ? '0' : '1');
            },
          ),
          for (final (room, on) in exceptions)
            CupertinoListTile(
              key: Key('exception-$room'),
              title: Text(nameOf(room)),
              additionalInfo: Text(on ? l.noticeOnHere : l.noticeOffHere),
              trailing: IosSwitch(value: on, activeTrackColor: p.accent, onChanged: (v) => s.setPref('$prefix$room', v ? '1' : '0')),
              onTap: () => s.setPref('$prefix$room', ''),
            ),
        ]),
      ],
    );
  }
}

/// Picks one chat of a kind ("direct", "group" or "channel").
class ChatPickPage extends StatelessWidget {
  const ChatPickPage({super.key, required this.kind});
  final String kind;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final list = s.chats.where(
      (c) => switch (kind) {
        'direct' => c.isDirect,
        'channel' => c.isChannel,
        _ => !c.isDirect && !c.isChannel,
      },
    );
    return SettingsScaffold(
      title: l.pickChat,
      children: [
        group(context, [
          for (final c in list)
            CupertinoListTile(
              key: Key('pick-chat-${c.roomId}'),
              leading: Avatar(name: c.name, size: 30, squircle: !c.isDirect),
              title: Text(c.name),
              onTap: () => Navigator.of(context).pop(c.roomId),
            ),
          if (list.isEmpty) CupertinoListTile(title: Text(l.nothingShared)),
        ]),
      ],
    );
  }
}

/// Our own message sounds; tapping one plays it.
class SoundPage extends StatelessWidget {
  const SoundPage({super.key, required this.prefKey});
  final String prefKey;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final now = s.pref(prefKey, 'nuri');
    return SettingsScaffold(
      title: l.sound,
      children: [
        group(context, footer: l.soundInfo, [
          for (final name in ['none', ...messageSounds])
            CupertinoListTile(
              key: Key('sound-$name'),
              title: Text(soundLabel(l, name)),
              trailing: name == now ? Icon(CupertinoIcons.check_mark, color: paletteOf(context).accent, size: 20) : null,
              onTap: () {
                s.setPref(prefKey, name);
                unawaited(Sounds.message(name));
              },
            ),
        ]),
      ],
    );
  }
}

/// Alerts while I use the app: banner or nothing, sound, preview.
class InAppNoticePage extends StatelessWidget {
  const InAppNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final style = s.pref('in_app_style', 'banner');
    Widget phone(String v, String label) {
      final on = style == v;
      return GestureDetector(
        key: Key('in-app-$v'),
        onTap: () => s.setPref('in_app_style', v),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tokens.radius[1] + 4),
                border: Border.all(color: on ? p.accent : p.separator, width: 2),
              ),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.all(Tokens.space[0]),
              child: v == 'banner'
                  ? Container(
                      height: 12,
                      decoration: BoxDecoration(color: on ? p.accent : p.separator, borderRadius: BorderRadius.circular(Tokens.radius[0])),
                    )
                  : null,
            ),
            SizedBox(height: Tokens.space[1]),
            Text(label, style: Tokens.caption.style.copyWith(color: on ? p.accent : p.secondaryLabel)),
          ],
        ),
      );
    }

    return SettingsScaffold(
      title: l.inAppNotices,
      children: [
        group(context, header: l.inAppStyle, footer: l.inAppStyleInfo, [
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[3]),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [phone('silent', l.inAppSilent), phone('banner', l.inAppBanner)]),
          ),
        ]),
        group(context, [
          PrefSwitch('in_app_sound', title: l.inAppSound, fallback: true, color: Palette.tileRed, icon: CupertinoIcons.speaker_2_fill),
          PrefSwitch('in_app_preview', title: l.inAppPreview, fallback: true, color: Palette.tileBlue, icon: CupertinoIcons.text_bubble_fill),
        ]),
      ],
    );
  }
}

/// Focus hours: no alerts between two times on chosen days.
class FocusPage extends StatelessWidget {
  const FocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final on = s.on('focus_on');
    final days = s.pref('focus_days', '1234567');
    final locale = Localizations.localeOf(context).languageCode;
    // Monday 2026-11-23 .. Sunday 2026-11-29 give the weekday names.
    String dayName(int d) => DateFormat.E(locale).format(DateTime(2026, 11, 22 + d)).substring(0, locale == 'ko' ? 1 : 2);
    String shown(String key, String fallback) {
      final hhmm = s.pref(key, fallback).split(':');
      final t = DateTime(2026, 1, 1, int.tryParse(hhmm[0]) ?? 0, int.tryParse(hhmm.last) ?? 0);
      return DateFormat.jm(locale).format(t);
    }

    Future<void> pick(String key, String fallback) async {
      final hhmm = s.pref(key, fallback).split(':');
      var t = DateTime(2026, 1, 1, int.tryParse(hhmm[0]) ?? 0, int.tryParse(hhmm.last) ?? 0);
      await showCupertinoModalPopup<void>(
        useRootNavigator: !Wide.on,
        context: context,
        builder: (c) => Container(
          height: 260,
          color: p.card,
          child: SafeArea(
            top: false,
            child: CupertinoDatePicker(key: Key('time-$key'), mode: CupertinoDatePickerMode.time, initialDateTime: t, onDateTimeChanged: (v) => t = v),
          ),
        ),
      );
      await s.setPref(key, '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
    }

    return SettingsScaffold(
      title: l.focusSchedule,
      children: [
        group(context, footer: l.focusInfo, [PrefSwitch('focus_on', title: l.focusSchedule)]),
        if (on) ...[
          group(context, [
            NavRow(key: const Key('focus-from'), title: l.focusFrom, value: shown('focus_from', '22:00'), onTap: () => pick('focus_from', '22:00')),
            NavRow(key: const Key('focus-to'), title: l.focusTo, value: shown('focus_to', '07:00'), onTap: () => pick('focus_to', '07:00')),
          ]),
          group(context, header: l.focusDays, [
            Padding(
              padding: EdgeInsets.symmetric(vertical: Tokens.space[2], horizontal: Tokens.space[2]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var d = 1; d <= 7; d++)
                    GestureDetector(
                      key: Key('focus-day-$d'),
                      onTap: () {
                        final set = days.split('').toSet();
                        set.contains('$d') ? set.remove('$d') : set.add('$d');
                        s.setPref('focus_days', (set.toList()..sort()).join());
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: days.contains('$d') ? p.accent : p.incoming),
                        child: Text(dayName(d), style: Tokens.caption.style.copyWith(color: days.contains('$d') ? const Color(0xFFFFFFFF) : p.label)),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ],
      ],
    );
  }
}
