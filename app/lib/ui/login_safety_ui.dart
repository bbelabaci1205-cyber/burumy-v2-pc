// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 로그인·기기 안전 screens (see core/login_safety.dart), behind
// Features.loginSafety: the new-login card on top of the chat list, the
// device sheet, the "for both" delete sheet with its 5-second undo, and
// 날짜로 지우기 (a month calendar, one day or a range).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:intl/intl.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/login_safety.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_pages.dart' show PasswordCheckPage, ChangePasswordPage, deviceIcon;
import 'wide.dart';

// ------------------------------------------------------------------ 398

/// "누군가 새 기기로 로그인했어요" on top of the chat list (Telegram tip
/// 398). Yes = known from now on; no = that device is logged out at once
/// (my password), then a nudge to change the password.
/// When a new login happened, as people say it: 방금 / 5분 전 / 오후 3:12 /
/// the usual date for older ones.
String loginWhen(BuildContext context, DateTime? at, DateTime now) {
  final l = L.of(context);
  if (at == null) return l.newLoginJustNow;
  final ago = now.difference(at);
  if (ago < const Duration(minutes: 2)) return l.newLoginJustNow;
  if (ago < const Duration(hours: 1)) return l.newLoginMinutesAgo(ago.inMinutes);
  if (at.year == now.year && at.month == now.month && at.day == now.day) {
    return DateFormat.jm(Localizations.localeOf(context).toString()).format(at);
  }
  return shortTime(context, at);
}

class NewLoginCard extends StatefulWidget {
  const NewLoginCard({super.key, required this.device});
  final DeviceRow device;

  @override
  State<NewLoginCard> createState() => _NewLoginCardState();
}

class _NewLoginCardState extends State<NewLoginCard> with SingleTickerProviderStateMixin {
  // The shield nods twice when the card arrives (no glow: iOS rule).
  late final shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    shake.dispose();
    super.dispose();
  }

  Future<void> no() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final d = widget.device;
    final ok = await Navigator.of(context).push<bool>(
      IosPageRoute(
        builder: (_) => PasswordCheckPage(title: l.newLoginOut, run: (pw) => s.backend.logOutDevices([d.id], pw)),
      ),
    );
    if (ok != true || !mounted) return;
    await s.answerNewLogin(d.id, mine: false);
    if (!mounted) return;
    // Next: a new password, so whoever it was can't sign in again.
    final change = await showCupertinoModalPopup<bool>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) => IosActionSheet(
        title: Text(l.newLoginOutDone(deviceName(l, d))),
        message: Text(l.newLoginChangePw),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('new-login-change-pw'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.changePassword),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c, false), child: Text(l.later)),
      ),
    );
    if (change == true && mounted) {
      await Navigator.of(context).push(IosPageRoute(builder: (_) => const ChangePasswordPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final d = widget.device;
    final when = loginWhen(context, d.lastSeen, s.backend.clock);
    Widget button(String key, String text, Color color, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        key: Key(key),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: Tokens.closeButton,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: p.dark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(Tokens.capsule),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tokens.preview.style.copyWith(color: color, fontWeight: Tokens.semi),
          ),
        ),
      ),
    );
    return Padding(
      key: Key('new-login-${d.id}'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Container(
        padding: EdgeInsets.all(Tokens.space[3]),
        decoration: ShapeDecoration(
          color: p.searchFill,
          shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3])),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: shake,
                  builder: (_, child) {
                    // Two small nods, then still.
                    final t = shake.value;
                    final a = 0.16 * math.sin(t * 4 * math.pi) * (1 - t);
                    return Transform.rotate(angle: a, child: child);
                  },
                  child: iconTile(Palette.tileRed, CupertinoIcons.exclamationmark_shield_fill),
                ),
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.newLoginTitle,
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      ),
                      const SizedBox(height: Tokens.subtitleGap),
                      Text(
                        l.newLoginBody(deviceName(l, d), when),
                        key: const Key('new-login-body'),
                        style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Tokens.space[2] + Tokens.space[0]),
            Row(
              children: [
                button('new-login-yes', l.newLoginYes, p.accent, () async {
                  await s.answerNewLogin(d.id, mine: true);
                }),
                SizedBox(width: Tokens.space[1]),
                button('new-login-no', l.newLoginNo, Palette.tileRed, no),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A device's name, or a plain word for the kind of device.
String deviceName(L l, DeviceRow d) => d.name.trim().isEmpty ? l.deviceUnnamed : d.name.trim();

// ------------------------------------------------------------- 247 / 308

/// "나에게서만 / 나와 상대 모두에게서" (1:1) or just "지우기". Null = cancel,
/// false = only me, true = both.
Future<bool?> askDeleteFor(BuildContext context, {required String title, required bool direct, String? peerName}) {
  final l = L.of(context);
  return showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      title: Text(title),
      actions: [
        if (direct)
          CupertinoActionSheetAction(
            key: const Key('delete-both'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(peerName == null ? l.deleteForBothShort : l.deleteForMeAnd(peerName)),
          ),
        CupertinoActionSheetAction(
          key: const Key('delete-me'),
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(c, false),
          child: Text(direct ? l.deleteForMeOnly : l.delete),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// The black "5초 뒤 지워요 · 되돌리기" capsule above the tab bar (Burumy rule:
/// every delete can be taken back for 5 seconds). [run] when time is up.
void showUndoCountdown(BuildContext context, String Function(int left) text, Future<void> Function() run, {VoidCallback? onUndo}) {
  final o = Overlay.of(context, rootOverlay: true);
  final left = ValueNotifier<int>(5);
  late OverlayEntry e;
  Timer? t;
  var done = false;
  void close() {
    t?.cancel();
    if (e.mounted) e.remove();
  }

  final family = paletteOf(context).family;
  e = OverlayEntry(
    builder: (c) => Positioned(
      left: Tokens.space[3],
      right: Tokens.space[3],
      bottom: FloatingTabBar.room(c) + Tokens.space[1],
      child: ValueListenableBuilder<int>(
        valueListenable: left,
        builder: (_, n, _) => Container(
          key: const Key('undo-countdown'),
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
          decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text(n),
                  style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF), decoration: TextDecoration.none),
                ),
              ),
              CupertinoButton(
                key: const Key('undo-countdown-undo'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                minimumSize: const Size(0, 36),
                onPressed: () {
                  done = true;
                  close();
                  onUndo?.call();
                },
                child: Text(L.of(c).undo, style: Tokens.body.style.copyWith(color: Brand.accent(family, Brightness.dark))),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  o.insert(e);
  t = Timer.periodic(const Duration(seconds: 1), (x) async {
    if (left.value > 1) {
      left.value--;
      return;
    }
    x.cancel();
    close();
    if (!done) {
      done = true;
      await run();
    }
  });
}

/// 날짜로 지우기 (Telegram tip 308): a month calendar of this chat; tap one
/// day, or two days for everything between, then the red button at the
/// bottom. My messages are deleted from the server; others' disappear
/// from this phone; in a 1:1 chat I may ask the other phone to do the same.
class DeleteByDatePage extends StatefulWidget {
  const DeleteByDatePage({super.key, required this.roomId, required this.title, required this.direct, this.peerName});
  final String roomId;
  final String title;
  final bool direct;
  final String? peerName;

  @override
  State<DeleteByDatePage> createState() => _DeleteByDatePageState();
}

/// "11월 23일", "11월 23일–27일", "11월 30일–12월 2일" (en: Nov 23–27).
String dayRange(L l, String lang, DateTime x, DateTime y) {
  final (a, b) = x.isBefore(y) ? (x, y) : (y, x);
  final fmt = DateFormat.MMMd(lang);
  if (a.year == b.year && a.month == b.month && a.day == b.day) return fmt.format(a);
  if (a.year == b.year && a.month == b.month) return l.dayRangeSameMonth(fmt.format(a), b.day);
  return '${fmt.format(a)}–${fmt.format(b)}';
}

class _DeleteByDatePageState extends State<DeleteByDatePage> {
  List<Msg>? msgs;
  DateTime? first, last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (msgs == null) load();
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    final all = await s.backend.timeline(widget.roomId, limit: 5000).catchError((_) => <Msg>[]);
    if (!mounted) return;
    setState(
      () => msgs = [
        for (final m in all)
          if (!LoginSafety.hiddenByDate(s, widget.roomId, m)) m,
      ],
    );
  }

  static DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  void tap(DateTime d) {
    HapticFeedback.selectionClick();
    setState(() {
      if (first == null || last != null) {
        first = d;
        last = null;
      } else if (d == first) {
        first = null;
      } else {
        last = d;
      }
    });
  }

  bool picked(DateTime d) {
    if (first == null) return false;
    if (last == null) return d == first;
    final (a, b) = LoginSafety.span(first!, last!);
    return !d.isBefore(a) && d.isBefore(b);
  }

  Future<void> wipe(int n) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final (from, to) = LoginSafety.span(first!, last ?? first!);
    final both = await askDeleteFor(context, title: l.dateWipeAsk(n), direct: widget.direct, peerName: widget.peerName);
    if (both == null || !mounted) return;
    final nav = Navigator.of(context);
    showUndoCountdown(context, (left) => l.dateWipeIn(left), () async {
      await LoginSafety.forgetDays(s, widget.roomId, from, to, both: both);
      await s.refresh();
    });
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).languageCode;
    final all = msgs ?? const <Msg>[];
    final count = <DateTime, int>{};
    for (final m in all) {
      final d = dayOf(m.time);
      count[d] = (count[d] ?? 0) + 1;
    }
    final now = AppScope.of(context).backend.clock;
    final months = {for (final d in count.keys) DateTime(d.year, d.month), DateTime(now.year, now.month)}.toList()..sort((a, b) => b.compareTo(a));
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.E(lang).format(DateTime(2026, 11, 22 + i))];
    final n = first == null
        ? 0
        : () {
            final (a, b) = LoginSafety.span(first!, last ?? first!);
            return all.where((m) => LoginSafety.inRange(m, a, b)).length;
          }();
    final range = first == null ? '' : dayRange(l, lang, first!, last ?? first!);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.dateWipeTitle), backgroundColor: p.background),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('date-wipe-calendar'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: Tokens.space[2]),
                    child: Text(l.dateWipeHint, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ),
                  Row(
                    children: [
                      for (final w in weekdays)
                        Expanded(
                          child: Center(
                            child: Text(w, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                          ),
                        ),
                    ],
                  ),
                  for (final mo in months) ...[
                    Padding(
                      padding: EdgeInsets.only(top: Tokens.space[3], bottom: Tokens.space[1]),
                      child: Text(
                        DateFormat.yMMMM(lang).format(mo),
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 0,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < mo.weekday % 7; i++) const SizedBox.shrink(),
                        for (var d = 1; d <= DateTime(mo.year, mo.month + 1, 0).day; d++)
                          _day(context, DateTime(mo.year, mo.month, d), count[DateTime(mo.year, mo.month, d)] ?? 0),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // The red button (Telegram: "이 날짜 기록 지우기").
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: n > 0 ? 1 : 0.4,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                child: GestureDetector(
                  key: const Key('date-wipe-go'),
                  onTap: n > 0 ? () => wipe(n) : null,
                  child: Container(
                    height: Tokens.settingsRow,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: Palette.tileRed, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(
                      first == null ? l.dateWipePick : l.dateWipeButton(range, n),
                      style: Tokens.body.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: Tokens.semi),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _day(BuildContext context, DateTime d, int n) {
    final p = paletteOf(context);
    final has = n > 0;
    // Where d sits in the picked range: a band with round ends (iOS / Telegram).
    final (DateTime? a, DateTime? b) = first == null
        ? (null, null)
        : () {
            final (x, y) = LoginSafety.span(first!, last ?? first!);
            return (x, y.subtract(const Duration(days: 1)));
          }();
    final on = picked(d);
    final isStart = on && a != null && dayOf(a) == d;
    final isEnd = on && b != null && dayOf(b) == d;
    final end = isStart || isEnd;
    final today = d == dayOf(AppScope.of(context).backend.clock);
    final band = Palette.tileRed.withValues(alpha: 0.16);
    const size = 40.0;
    return GestureDetector(
      key: Key('day-${d.year}-${d.month}-${d.day}'),
      behavior: HitTestBehavior.opaque,
      onTap: has ? () => tap(d) : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (on && !(isStart && isEnd))
            Row(
              children: [
                Expanded(
                  child: Container(height: size, color: isStart ? null : band),
                ),
                Expanded(
                  child: Container(height: size, color: isEnd ? null : band),
                ),
              ],
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: end ? Palette.tileRed : (on ? band : null), shape: BoxShape.circle),
            child: Text(
              '${d.day}',
              style: Tokens.preview.style.copyWith(
                color: end
                    ? const Color(0xFFFFFFFF)
                    : on
                    ? Palette.tileRed
                    : today
                    ? p.accent
                    : (has ? p.label : p.secondaryLabel.withValues(alpha: 0.45)),
                fontWeight: end || has || today ? Tokens.semi : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A voice or round video from someone my rule doesn't allow (a changed
/// app could still send one): one grey line instead of the player.
class VoiceBlockedLine extends StatelessWidget {
  const VoiceBlockedLine({super.key, required this.fg});
  final Color fg;
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Row(
      key: const Key('voice-blocked'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.mic_slash, size: Tokens.listIconSmall, color: fg.withValues(alpha: 0.7)),
        SizedBox(width: Tokens.space[1]),
        Flexible(
          child: Text(l.voiceBlockedLine, style: Tokens.preview.style.copyWith(color: fg.withValues(alpha: 0.7))),
        ),
      ],
    );
  }
}

/// Shown when I tap the dimmed mic: they don't take voice messages from me.
void showVoiceClosed(BuildContext context, String name) {
  final l = L.of(context);
  showCupertinoModalPopup<void>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      title: Text(l.voiceClosedTitle),
      message: Text(l.voiceClosedBody(name)),
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.ok)),
    ),
  );
}

/// Device icon for a device sheet / card.
IconData iconOfDevice(DeviceRow d) => deviceIcon(d.name);

// ------------------------------------------------------------------ 311

/// What kind of device, in words.
String deviceKind(L l, DeviceRow d) {
  final i = deviceIcon(d.name);
  if (i == CupertinoIcons.device_laptop) return l.deviceKindPc;
  if (i == CupertinoIcons.globe) return l.deviceKindWeb;
  return l.deviceKindPhone;
}

/// One device, from 설정 > 기기 (Telegram tip 311): what it is, when it was
/// last used, "이 기기로 통화 받기", and the red "이 기기 로그아웃".
/// Returns true when the device was logged out.
Future<bool?> showDeviceSheet(BuildContext context, DeviceRow d) {
  return showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => _DeviceSheet(device: d),
  );
}

class _DeviceSheet extends StatefulWidget {
  const _DeviceSheet({required this.device});
  final DeviceRow device;
  @override
  State<_DeviceSheet> createState() => _DeviceSheetState();
}

class _DeviceSheetState extends State<_DeviceSheet> {
  bool? calls;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calls == null) load();
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    final p = await s.backend.accountPrivacy().catchError((_) => <String, dynamic>{});
    if (mounted) setState(() => calls = !LoginSafety.callsOff(p, widget.device.id));
  }

  Future<void> logOut() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final d = widget.device;
    final ok = await Navigator.of(context).push<bool>(
      IosPageRoute(
        builder: (_) => PasswordCheckPage(title: l.deviceSheetOut, run: (pw) => s.backend.logOutDevices([d.id], pw)),
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final d = widget.device;
    final s = AppScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    // Plain rows like Telegram's session sheet / iOS 정보 (no icons).
    Widget info(String title, String value) => IosTile(title: Text(title), additionalInfo: Text(value));
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(IosActionSheet.radius),
        child: ColoredBox(
          color: p.background,
          child: Column(
            key: const Key('device-sheet'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: Tokens.space[4]),
              Center(
                child: Container(
                  width: HeaderTile.size,
                  height: HeaderTile.size,
                  decoration: ShapeDecoration(
                    color: d.thisDevice ? Palette.tileBlue : (d.verified ? p.tileGreen : Palette.tileGrey),
                    shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[2])),
                  ),
                  child: Icon(iconOfDevice(d), size: 34, color: const Color(0xFFFFFFFF)),
                ),
              ),
              SizedBox(height: Tokens.space[2]),
              Text(
                deviceName(l, d),
                textAlign: TextAlign.center,
                style: Tokens.cardTitle.style.copyWith(color: p.label, fontWeight: Tokens.semi),
              ),
              const SizedBox(height: Tokens.subtitleGap),
              Text(
                d.verified ? l.deviceVerified : l.deviceNotVerified,
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
              ),
              SizedBox(height: Tokens.space[2]),
              IosSection(
                children: [
                  info(l.deviceSheetKind, deviceKind(l, d)),
                  info(l.deviceSheetLastSeen, d.thisDevice ? l.onlineNow : (d.lastSeen == null ? '—' : shortTime(context, d.lastSeen!))),
                ],
              ),
              IosSection(
                footer: Text(l.deviceSheetCallsSub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                children: [
                  IosTile(
                    title: Text(l.deviceSheetCalls),
                    trailing: IosSwitch(
                      key: const Key('device-calls'),
                      value: calls ?? true,
                      activeTrackColor: p.accent,
                      onChanged: calls == null
                          ? null
                          : (v) async {
                              setState(() => calls = v);
                              try {
                                await LoginSafety.setCalls(s, d.id, v);
                              } catch (_) {
                                if (mounted) setState(() => calls = !v);
                              }
                            },
                    ),
                  ),
                ],
              ),
              if (!d.thisDevice)
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[3]),
                  child: GestureDetector(
                    key: const Key('device-logout'),
                    onTap: logOut,
                    child: Container(
                      height: Tokens.settingsRow,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
                      child: Text(
                        l.deviceSheetOut,
                        style: Tokens.body.style.copyWith(color: Palette.tileRed, fontWeight: Tokens.semi),
                      ),
                    ),
                  ),
                ),
              if (d.thisDevice) SizedBox(height: Tokens.space[2]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Header tile size in the device sheet (iOS 27 settings header: 60).
class HeaderTile {
  const HeaderTile._();
  static const size = 60.0;
}

/// "오래 안 쓴 기기 자동 로그아웃" row for 설정 > 기기 (our server does it).
class IdleLogoutRow extends StatefulWidget {
  const IdleLogoutRow({super.key});
  @override
  State<IdleLogoutRow> createState() => _IdleLogoutRowState();
}

class _IdleLogoutRowState extends State<IdleLogoutRow> {
  int? days;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (days == null) load();
  }

  Future<void> load() async {
    final p = await AppScope.read(context).backend.accountPrivacy().catchError((_) => <String, dynamic>{});
    if (mounted) setState(() => days = LoginSafety.idleDays(p));
  }

  static String label(L l, int d) => switch (d) {
    7 => l.idleDays7,
    30 => l.idleDays30,
    90 => l.idleDays90,
    180 => l.idleDays180,
    365 => l.idleDays365,
    _ => l.deviceIdleOff,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final now = days ?? 0;
    return IosTile(
      key: const Key('device-idle-row'),
      title: Text(l.deviceIdleTitle),
      additionalInfo: Text(label(l, now)),
      trailing: const IosChevron(),
      onTap: () async {
        final picked = await Navigator.of(context).push<int>(IosPageRoute(builder: (c) => _IdlePage(now: now)));
        if (picked == null || picked == now) return;
        setState(() => days = picked);
        try {
          await LoginSafety.setIdleDays(s, picked);
        } catch (_) {
          if (mounted) setState(() => days = now);
        }
      },
    );
  }
}

class _IdlePage extends StatelessWidget {
  const _IdlePage({required this.now});
  final int now;
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.deviceIdlePage, back: true, tint: p.background),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            header: Text(l.deviceIdleHeader),
            footer: Text(l.deviceIdleInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            children: [
              for (final d in [0, ...LoginSafety.idleChoices])
                IosTile(
                  key: Key('idle-$d'),
                  title: Text(_IdleLogoutRowState.label(l, d)),
                  trailing: d == now ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
                  onTap: () => Navigator.of(context).pop(d),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
