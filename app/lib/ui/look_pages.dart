// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 꾸미기·보안 설정 묶음 (Telegram tips 64/180, 251/364, 382):
//  - 자동 야간 모드 with a time schedule
//  - 메시지 자동 삭제: any time up to 1 year (wheel), and one time for
//    many chats at once
//  - 절전 모드: battery % slider
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/night.dart';
import '../core/looks.dart';
import '../core/room_theme.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'stories.dart' show showStoryToast;
import 'settings_kit.dart';
import 'theme_fade.dart';
import 'wallpaper.dart';
import 'look_studio.dart';

// ---------------------------------------------------------------- night

/// Flips day/night now (Settings switch, chat-list menu moon), with the fade.
Future<void> toggleNight(AppState s, bool darkNow) => ThemeFade.run(() => s.setPref(Night.key, darkNow ? 'light' : 'dark'));

String autoNightValue(L l, AppState s) => switch (Night.mode(s)) {
  'system' => l.autoNightSystem,
  'schedule' => l.autoNightRange(Night.clock(Night.from(s)), Night.clock(Night.to(s))),
  _ => l.autoNightOff,
};

/// Settings > 모양 > 자동 야간 모드: off / follow the phone / by time.
class AutoNightPage extends StatefulWidget {
  const AutoNightPage({super.key});
  @override
  State<AutoNightPage> createState() => _AutoNightPageState();
}

class _AutoNightPageState extends State<AutoNightPage> {
  /// Which time row has its wheel open: 'from', 'to' or null.
  String? open;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final mode = Night.mode(s);
    final now = mode == 'system' || mode == 'schedule' ? mode : 'off';
    Future<void> pick(String v) => ThemeFade.run(() => s.setPref(Night.key, v == 'off' ? (p.dark ? 'dark' : 'light') : v));
    Widget timeRow(String which, String title, int minutes) => Column(
      children: [
        IosTile(
          key: Key('night-$which'),
          title: Text(title),
          additionalInfo: Text(Night.clock(minutes), style: TextStyle(color: open == which ? p.accent : null)),
          onTap: () => setState(() => open = open == which ? null : which),
        ),
        if (open == which)
          SizedBox(
            height: Tokens.wheelHeight,
            child: CupertinoDatePicker(
              key: Key('night-wheel-$which'),
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: DateTime(2000, 1, 1, minutes ~/ 60, minutes % 60),
              onDateTimeChanged: (d) => s.setPref(which == 'from' ? Night.fromKey : Night.toKey, '${d.hour * 60 + d.minute}'),
            ),
          ),
      ],
    );
    return SettingsScaffold(
      title: l.autoNight,
      children: [
        group(context, footer: l.autoNightInfo, [
          for (final (v, label) in [('off', l.autoNightOff), ('system', l.autoNightSystem), ('schedule', l.autoNightSchedule)])
            IosTile(
              key: Key('pick-$v'),
              title: Text(label),
              trailing: v == now ? Icon(CupertinoIcons.check_mark, color: p.accent, size: Tokens.listIconSmall) : null,
              onTap: () => pick(v),
            ),
        ]),
        if (now == 'schedule')
          group(context, header: l.autoNightTimes, footer: l.autoNightScheduleInfo, [
            timeRow('from', l.autoNightFrom, Night.from(s)),
            timeRow('to', l.autoNightTo, Night.to(s)),
          ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- timer

/// 메시지 자동 삭제 times: the quick ones, then "다른 시간" (wheel).
const quickTimers = [0, 86400, 604800, 2592000, 31536000];

/// The longest a message can wait (1 year, Telegram 251).
const maxTimer = 31536000;

/// Units in the "다른 시간" wheel (seconds each) and how many of each.
const timerUnits = [(3600, 23), (86400, 6), (604800, 3), (2592000, 11), (31536000, 1)];

/// "1일", "3시간", "2주", "1년"…
String timerText(L l, int secs) {
  if (secs <= 0) return l.timerOff;
  // The usual words for the usual times (same as before 251).
  if (secs == 86400) return l.timer1d;
  if (secs == 604800) return l.timer1w;
  if (secs == 2592000) return l.timer1m;
  if (secs % 31536000 == 0) return l.timerYears(secs ~/ 31536000);
  if (secs % 2592000 == 0) return l.timerMonths(secs ~/ 2592000);
  if (secs % 604800 == 0) return l.timerWeeks(secs ~/ 604800);
  if (secs % 86400 == 0) return l.timerDays(secs ~/ 86400);
  if (secs % 3600 == 0) return l.timerHours(secs ~/ 3600);
  return l.timerMinutes((secs / 60).ceil());
}

/// Short mark for the chat-list photo: "1d", "1w", "3h"… (Telegram 364).
String timerShort(int secs) {
  for (final (unit, mark) in const [(31536000, 'y'), (2592000, 'mo'), (604800, 'w'), (86400, 'd'), (3600, 'h')]) {
    if (secs >= unit && secs % unit == 0) return '${secs ~/ unit}$mark';
  }
  return secs >= 3600 ? '${secs ~/ 3600}h' : '${(secs / 60).ceil()}m';
}

/// The action sheet used everywhere a chat timer is chosen: off, 1 day,
/// 1 week, 1 month, 1 year, "다른 시간…". Returns seconds or null.
Future<int?> pickTimer(BuildContext context, {required int now, String? message}) async {
  final l = L.of(context);
  final pick = await showCupertinoModalPopup<int>(
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.timer),
      message: Text(message ?? l.timerInfo),
      actions: [
        for (final o in quickTimers)
          CupertinoActionSheetAction(key: Key('timer-$o'), isDefaultAction: o == now, onPressed: () => Navigator.pop(c, o), child: Text(timerText(l, o))),
        CupertinoActionSheetAction(
          key: const Key('timer-other'),
          isDefaultAction: now > 0 && !quickTimers.contains(now),
          onPressed: () => Navigator.pop(c, -1),
          child: Text(now > 0 && !quickTimers.contains(now) ? '${l.timerOther} (${timerText(l, now)})' : l.timerOther),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick != -1 || !context.mounted) return pick;
  return pickTimerWheel(context, now);
}

/// "다른 시간": a two-wheel picker (number + unit, 1 hour … 1 year).
Future<int?> pickTimerWheel(BuildContext context, int now) {
  final l = L.of(context);
  var unit = 1; // days, unless a time is already set
  var count = 1;
  for (var i = timerUnits.length - 1; i >= 0; i--) {
    final (u, max) = timerUnits[i];
    if (now >= u && now % u == 0 && now ~/ u <= max) {
      unit = i;
      count = now ~/ u;
      break;
    }
  }
  String unitName(int i, int n) => switch (i) {
    0 => l.timerUnitHours(n),
    1 => l.timerUnitDays(n),
    2 => l.timerUnitWeeks(n),
    3 => l.timerUnitMonths(n),
    _ => l.timerUnitYears(n),
  };
  return showCupertinoModalPopup<int>(
    context: context,
    builder: (c) {
      final p = paletteOf(c);
      return StatefulBuilder(
        builder: (c, set) {
          final (u, max) = timerUnits[unit];
          if (count > max) count = max;
          return Container(
            key: const Key('timer-wheel'),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[3])),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: Tokens.sheetHeader,
                    child: Row(
                      children: [
                        CupertinoButton(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
                        Expanded(
                          child: Text(
                            l.timerOther,
                            textAlign: TextAlign.center,
                            style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                          ),
                        ),
                        CupertinoButton(
                          key: const Key('timer-wheel-done'),
                          onPressed: () => Navigator.pop(c, u * count),
                          child: Text(l.done, style: TextStyle(fontWeight: Tokens.semi)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Tokens.wheelHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            key: ValueKey('count-$unit'),
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(initialItem: count - 1),
                            onSelectedItemChanged: (i) => set(() => count = i + 1),
                            children: [for (var n = 1; n <= max; n++) Center(child: Text('$n'))],
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            key: const Key('timer-unit'),
                            itemExtent: 32,
                            scrollController: FixedExtentScrollController(initialItem: unit),
                            onSelectedItemChanged: (i) => set(() => unit = i),
                            children: [for (var i = 0; i < timerUnits.length; i++) Center(child: Text(unitName(i, count)))],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Settings > 개인정보 > 메시지 자동 삭제 (Telegram 364): the time for new
/// chats, and "기존 대화에 적용" to put one time on many chats at once.
class DefaultTimerPage extends StatelessWidget {
  const DefaultTimerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final secs = int.tryParse(s.pref('default_timer', '0')) ?? 0;
    final custom = secs > 0 && !quickTimers.contains(secs);
    return SettingsScaffold(
      title: l.defaultTimer,
      children: [
        HeaderCard(color: Palette.tileOrange, icon: CupertinoIcons.timer, title: l.defaultTimer, body: l.defaultTimerHeader),
        group(context, header: l.defaultTimerNew, footer: l.defaultTimerInfo, [
          for (final o in quickTimers)
            IosTile(
              key: Key('pick-$o'),
              title: Text(timerText(l, o)),
              trailing: o == secs ? Icon(CupertinoIcons.check_mark, color: p.accent, size: Tokens.listIconSmall) : null,
              onTap: () => s.setPref('default_timer', '$o'),
            ),
          IosTile(
            key: const Key('pick-other'),
            title: Text(l.timerOther),
            additionalInfo: custom ? Text(timerText(l, secs)) : null,
            trailing: custom ? Icon(CupertinoIcons.check_mark, color: p.accent, size: Tokens.listIconSmall) : const IosChevron(),
            onTap: () async {
              final v = await pickTimerWheel(context, secs);
              if (v != null) await s.setPref('default_timer', '$v');
            },
          ),
        ]),
        group(context, footer: l.timerApplyInfo, [
          IosTile(
            key: const Key('timer-apply'),
            leading: iconTile(p.accent, CupertinoIcons.checkmark_circle_fill),
            title: Text(l.timerApply),
            trailing: const IosChevron(),
            onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => TimerApplyPage(seconds: secs))),
          ),
        ]),
      ],
    );
  }
}

/// "기존 대화에 적용": tick chats, then one time goes on all of them.
class TimerApplyPage extends StatefulWidget {
  const TimerApplyPage({super.key, required this.seconds});
  final int seconds;
  @override
  State<TimerApplyPage> createState() => _TimerApplyPageState();
}

class _TimerApplyPageState extends State<TimerApplyPage> {
  final picked = <String>{};
  late int secs = widget.seconds;
  bool busy = false;

  Future<void> apply() async {
    final s = AppScope.read(context);
    final l = L.of(context);
    setState(() => busy = true);
    var done = 0;
    for (final id in picked) {
      try {
        await s.setChatTimer(id, secs);
        done++;
      } catch (_) {}
    }
    if (!mounted) return;
    unawaited(s.refresh());
    Navigator.of(context).pop();
    showStoryToast(context, secs == 0 ? l.timerAppliedOff(done) : l.timerApplied(done, timerText(l, secs)));
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    // Chats I can set a timer in: 1:1 and groups (not channels, not saved).
    final chats = [
      for (final c in s.chats)
        if (!c.isChannel && c.roomId != s.savedRoomId) c,
    ];
    return SettingsScaffold(
      title: l.timerApply,
      trailing: [
        GlassPill(
          key: const Key('timer-apply-go'),
          text: picked.isEmpty ? l.timerApplyGo : l.timerApplyGoN(picked.length),
          onTap: picked.isEmpty || busy ? null : apply,
        ),
      ],
      children: [
        group(context, header: l.timerApplyTime, [
          IosTile(
            key: const Key('timer-apply-time'),
            title: Text(l.timer),
            additionalInfo: Text(timerText(l, secs)),
            trailing: const IosChevron(),
            onTap: () async {
              final v = await pickTimer(context, now: secs, message: l.timerApplyInfo);
              if (v != null) setState(() => secs = v);
            },
          ),
        ]),
        group(context, header: l.timerApplyPick, [
          IosTile(
            key: const Key('timer-apply-all'),
            title: Text(picked.length == chats.length ? l.timerDeselectAll : l.timerSelectAll, style: TextStyle(color: p.accent)),
            onTap: () => setState(() {
              if (picked.length == chats.length) {
                picked.clear();
              } else {
                picked.addAll(chats.map((c) => c.roomId));
              }
            }),
          ),
          for (final c in chats)
            IosTile(
              key: Key('timer-apply-${c.roomId}'),
              leading: Avatar(name: c.name, size: 30, squircle: !c.isDirect, userId: c.isDirect ? c.peer : null, roomId: c.roomId),
              title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              additionalInfo: (s.timers[c.roomId] ?? 0) > 0 ? Text(timerText(l, s.timers[c.roomId]!)) : null,
              trailing: Icon(
                picked.contains(c.roomId) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                color: picked.contains(c.roomId) ? p.accent : p.secondaryLabel,
              ),
              onTap: () => setState(() => picked.contains(c.roomId) ? picked.remove(c.roomId) : picked.add(c.roomId)),
            ),
        ]),
      ],
    );
  }
}

/// The small "1w" capsule on a chat photo when its messages disappear.
class TimerMark extends StatelessWidget {
  const TimerMark({super.key, required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      height: Tokens.timerMark,
      constraints: const BoxConstraints(minWidth: Tokens.timerMark),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(Tokens.timerMark / 2),
        border: Border.all(color: p.background, width: 2),
      ),
      child: Text(timerShort(seconds), style: Tokens.timerMarkText.style.copyWith(color: p.onAccent, height: 1)),
    );
  }
}

// ---------------------------------------------------------------- power

String powerLabel(L l, int below) => below <= 0 ? l.powerNever : (below >= 100 ? l.powerAlways : l.powerBelowValue(below));

/// 절전 모드 battery slider (Telegram 382): 꺼짐 … 50% … 항상, in steps.
const powerSteps = [0, 5, 10, 15, 20, 25, 30, 40, 50, 75, 100];

class PowerSlider extends StatelessWidget {
  const PowerSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final below = s.powerBelow;
    var i = powerSteps.indexWhere((v) => v >= below);
    if (i < 0) i = powerSteps.length - 1;
    final label = powerLabel(l, below);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2]),
      child: Column(
        children: [
          Text(
            label,
            key: const Key('power-value'),
            style: Tokens.body.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
          Row(
            children: [
              Text(l.powerNever, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              Expanded(
                child: CupertinoSlider(
                  key: const Key('power-slider'),
                  value: i.toDouble(),
                  min: 0,
                  max: (powerSteps.length - 1).toDouble(),
                  divisions: powerSteps.length - 1,
                  activeColor: p.accent,
                  onChanged: (v) => s.setPref('power_below', '${powerSteps[v.round()]}'),
                ),
              ),
              Text(l.powerAlways, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- room theme

/// Chat info > 이 대화방 배경 (Telegram 295): a big preview, a row of theme
/// cards, and in 1:1 chats "상대방 화면에도 적용" (encrypted note).
class RoomThemePage extends StatefulWidget {
  const RoomThemePage({super.key, required this.roomId, required this.direct});
  final String roomId;
  final bool direct;
  @override
  State<RoomThemePage> createState() => _RoomThemePageState();
}

class _RoomThemePageState extends State<RoomThemePage> {
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final here = s.pref(RoomTheme.pref(widget.roomId), '');
    final both = widget.direct && s.on('chat_theme_both', fallback: true);
    final by = s.pref(RoomTheme.byPref(widget.roomId), '');
    final shown = here.isEmpty ? s.pref('chat_theme', 'plain') : here;
    Future<void> pick(String id) async {
      if (busy) return;
      setState(() => busy = true);
      try {
        await RoomTheme.set(s, widget.roomId, id, both: both);
        if (mounted && both) showStoryToast(context, l.roomThemeSent);
      } catch (_) {
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }

    Widget card(String id, String label) {
      final on = here == id;
      return GestureDetector(
        key: Key('room-theme-$id'),
        onTap: () => pick(id),
        child: Padding(
          padding: EdgeInsets.only(right: Tokens.space[2]),
          child: Column(
            children: [
              Container(
                width: Tokens.qrThemeW,
                height: Tokens.qrThemeH,
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(Tokens.qrThemeCorner),
                    side: BorderSide(color: on ? p.accent : p.separator, width: on ? 2.5 : 0.5),
                  ),
                ),
                child: id.isEmpty
                    ? Center(
                        child: Icon(CupertinoIcons.arrow_uturn_left, color: p.secondaryLabel, size: Tokens.listIcon),
                      )
                    : WallArt(wall: Wall.parse(id), dark: p.dark, base: p.chatBackground, photo: chatPhoto(s), still: true),
              ),
              SizedBox(height: Tokens.space[1]),
              SizedBox(
                width: Tokens.qrThemeW,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: on ? p.accent : p.secondaryLabel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SettingsScaffold(
      title: l.chatThemeHere,
      children: [
        // The chat as it will look (the same art the chat screen draws).
        Container(
          key: const Key('room-theme-preview'),
          height: 180,
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3]))),
          child: Stack(
            children: [
              Positioned.fill(
                child: WallArt(wall: Wall.parse(shown), dark: p.dark, base: p.chatBackground, photo: chatPhoto(s)),
              ),
              Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _Bubble(text: l.roomThemeSample1, mine: false),
                    SizedBox(height: Tokens.space[1]),
                    _Bubble(text: l.roomThemeSample2, mine: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Tokens.space[2]),
        SizedBox(
          height: Tokens.qrThemeH + 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            children: [card('', l.roomThemeMine), for (final (spec, label) in readyWalls(l)) card(spec, label)],
          ),
        ),
        // 배경 고르기 for this chat (tip 181 / 387): photo, colour, own mix.
        group(context, [
          NavRow(
            key: const Key('room-theme-more'),
            color: Palette.tileTeal,
            icon: CupertinoIcons.photo_fill,
            title: l.wallMoreChoices,
            value: here.isEmpty ? null : wallName(l, here),
            page: (_) => WallpaperPage(
              target: WallTarget(roomId: widget.roomId, direct: widget.direct),
            ),
          ),
        ]),
        if (widget.direct)
          group(context, footer: by.isNotEmpty ? l.roomThemeByOther : l.roomThemeBothInfo, [
            PrefSwitch('chat_theme_both', key: const Key('room-theme-both'), title: l.roomThemeBoth, fallback: true),
          ])
        else
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[2], Tokens.space[5], 0),
            child: Text(l.chatThemeHereInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine});
  final String text;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
        child: Text(text, style: Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label)),
      ),
    );
  }
}
