// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 초대 링크 여러 개 (Telegram tip 253): next to a group's or channel's main
// link, admins make extra private links, each with a name only admins
// see, an end time (1시간 · 1일 · 1주 · 제한 없음 · 직접) and a people limit
// (1 · 10 · 100 · 제한 없음 · 직접). Our server keeps both limits, so they
// hold even while every admin's phone is off, and counts each join.
//
// - ExtraLinksSection: the "추가 링크" card on the invite link page, with a
//   ring icon per link that shrinks like a clock (green → orange → red).
// - InviteLinkEditPage: make or change one link.
// - InviteLinkDetailPage: copy / share / poster, who came in, edit, 취소
//   (5초 되돌리기, Burumy rule), and 지우기 for cancelled links.
// iOS Settings layout first; Telegram's "Invite links" pages for what is
// on them.
import 'dart:async';
import 'dart:math' as math;

import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../core/app_state.dart';
import '../core/backend.dart' hide LinkCard;
import '../core/room_links.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'invite_links.dart' show LinkCard;
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'poster.dart';
import 'settings_kit.dart';

/// The colour of a link's state (iOS system colours by meaning).
Color linkStateColor(BuildContext context, String state) => switch (state) {
  'live' => paletteOf(context).tileGreen,
  'soon' => Palette.tileOrange,
  'revoked' => Palette.tileGrey,
  _ => Palette.tileRed,
};

/// Round link icon with a ring that empties like a clock as the time or
/// the seats run out (Telegram's invite link icon, our colours).
class LinkRing extends StatelessWidget {
  const LinkRing({super.key, required this.color, required this.left, this.ring = true});
  final Color color;

  /// 1 = all left, 0 = none.
  final double left;

  /// Only links with a limit have a ring.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    const size = Tokens.linkRing;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(color, ring ? left : null, paletteOf(context).separator),
        child: Center(
          child: Container(
            width: size - Tokens.linkRingGap * 2,
            height: size - Tokens.linkRingGap * 2,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.link, size: Tokens.tileGlyph, color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.color, this.left, this.track);
  final Color color;
  final double? left;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final f = left;
    if (f == null) return;
    final r = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Tokens.linkRingStroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, math.pi * 2, false, pen..color = track);
    // From 12 o'clock, clockwise, what is still left.
    if (f > 0) canvas.drawArc(r, -math.pi / 2, math.pi * 2 * f, false, pen..color = color);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.color != color || old.left != left || old.track != track;
}

/// "3명 참여 · 7명 남음 · 1일 남음", or why it no longer opens.
String linkStatusLine(L l, InviteLink k, DateTime now) {
  final st = k.state(now);
  final parts = <String>[l.invJoined(k.uses)];
  switch (st) {
    case 'revoked':
      parts.add(l.invRevoked);
    case 'ended':
      parts.add(l.invEnded);
    case 'full':
      parts.add(l.invFull);
    default:
      if (k.max > 0) parts.add(l.invPeopleLeft(k.max - k.uses));
      final u = k.until;
      if (u != null) {
        final d = u.difference(now);
        parts.add(
          d.inDays >= 1
              ? l.invDaysLeft(d.inDays)
              : d.inHours >= 1
              ? l.invHoursLeft(d.inHours)
              : l.invMinutesLeft(math.max(1, d.inMinutes)),
        );
      }
  }
  return parts.join(' · ');
}

/// What a link is called in lists: its name, else the link itself.
String linkTitle(InviteLink k) => k.name.isNotEmpty ? k.name : RoomLinks.shown(k.link()).replaceFirst(RegExp(r'#.*'), '#…${k.code.substring(22)}');

/// The "추가 링크" card (and "취소된 링크" under it) on the invite link page.
class ExtraLinksSection extends StatefulWidget {
  const ExtraLinksSection({super.key, required this.roomId, required this.name, required this.isChannel, required this.approval});
  final String roomId;
  final String name;
  final bool isChannel;

  /// 승인 후 참여 is on: limits still end links, seats are the admins' call.
  final bool approval;

  @override
  State<ExtraLinksSection> createState() => _ExtraLinksSectionState();
}

class _ExtraLinksSectionState extends State<ExtraLinksSection> {
  List<InviteLink>? links;

  /// Hidden while its 5초 되돌리기 runs.
  final going = <String>{};
  Timer? tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
    // Rings and "N분 남음" move on their own.
    tick = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final r = await AppScope.read(context).backend.inviteLinks(widget.roomId).catchError((_) => <InviteLink>[]);
    if (mounted) setState(() => links = r);
  }

  Future<void> open(Widget page) async {
    await Navigator.of(context).push(IosPageRoute<void>(builder: (_) => page));
    await load();
  }

  void deleteAllRevoked(List<InviteLink> gone) {
    final l = L.of(context);
    final b = AppScope.read(context).backend;
    setState(() => going.addAll(gone.map((k) => k.code)));
    showUndoCountdown(context, (n) => l.invDeleteAllIn(n), () async {
      for (final k in gone) {
        await b.deleteInviteLink(widget.roomId, k.code).catchError((_) {});
      }
      if (mounted) {
        going.removeAll(gone.map((k) => k.code));
        await load();
      }
    }, onUndo: () => mounted ? setState(() => going.removeAll(gone.map((k) => k.code))) : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final now = clock.now();
    final all = (links ?? const <InviteLink>[]).where((k) => !going.contains(k.code)).toList();
    final open_ = all.where((k) => !k.revoked).toList(), gone = all.where((k) => k.revoked).toList();
    Widget row(InviteLink k) {
      final st = k.state(now);
      return IosTile(
        key: Key('inv-row-${k.code}'),
        leading: LinkRing(color: linkStateColor(context, st), left: k.left(now), ring: !k.revoked && (k.until != null || k.max > 0)),
        leadingSize: Tokens.linkRing,
        title: Text(linkTitle(k), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(linkStatusLine(l, k, now), style: TextStyle(color: st == 'live' || st == 'soon' ? null : linkStateColor(context, st))),
        trailing: const IosChevron(),
        onTap: () => open(InviteLinkDetailPage(roomId: widget.roomId, roomName: widget.name, isChannel: widget.isChannel, link: k)),
      );
    }

    return Column(
      children: [
        group(context, header: l.invMoreHeader, footer: l.invMoreInfo, [
          IosTile(
            key: const Key('inv-new'),
            leading: Icon(CupertinoIcons.add, color: p.accent),
            title: Text(l.invNew, style: TextStyle(color: p.accent)),
            onTap: () => open(InviteLinkEditPage(roomId: widget.roomId, approval: widget.approval)),
          ),
          if (links == null) const Padding(padding: EdgeInsets.all(12), child: CupertinoActivityIndicator()),
          for (final k in open_) row(k),
        ]),
        if (gone.isNotEmpty)
          group(context, header: l.invRevokedHeader, [
            for (final k in gone) row(k),
            IosTile(
              key: const Key('inv-delete-revoked'),
              title: Text(l.invDeleteAllRevoked, style: const TextStyle(color: Palette.tileRed)),
              onTap: () => deleteAllRevoked(gone),
            ),
          ]),
      ],
    );
  }
}

/// Make a new extra link, or change one ([link]).
class InviteLinkEditPage extends StatefulWidget {
  const InviteLinkEditPage({super.key, required this.roomId, this.link, this.approval = false});
  final String roomId;
  final InviteLink? link;
  final bool approval;

  /// Time choices (Telegram's stops), then 제한 없음 and 직접.
  static const times = [Duration(hours: 1), Duration(days: 1), Duration(days: 7)];
  static const people = [1, 10, 100];

  @override
  State<InviteLinkEditPage> createState() => _InviteLinkEditPageState();
}

class _InviteLinkEditPageState extends State<InviteLinkEditPage> {
  late final name = TextEditingController(text: widget.link?.name ?? '');
  late final count = TextEditingController();

  /// 0-2 = [InviteLinkEditPage.times], 3 = 제한 없음, 4 = 직접.
  int time = 3, seats = 3;
  DateTime? pickedEnd;
  bool busy = false;
  String? failed;

  bool get editing => widget.link != null;

  @override
  void initState() {
    super.initState();
    final k = widget.link;
    if (k != null) {
      if (k.until != null) {
        time = 4;
        pickedEnd = k.until;
      }
      final i = InviteLinkEditPage.people.indexOf(k.max);
      seats = k.max == 0 ? 3 : (i >= 0 ? i : 4);
      if (seats == 4) count.text = '${k.max}';
    }
  }

  @override
  void dispose() {
    name.dispose();
    count.dispose();
    super.dispose();
  }

  DateTime? endAt(DateTime now) => switch (time) {
    3 => null,
    4 => pickedEnd ?? now.add(const Duration(days: 1)),
    _ => now.add(InviteLinkEditPage.times[time]),
  };

  int get max => switch (seats) {
    3 => 0,
    4 => int.tryParse(count.text.trim()) ?? 0,
    _ => InviteLinkEditPage.people[seats],
  };

  bool get valid => !busy && (seats != 4 || max > 0) && (time != 4 || (pickedEnd ?? clock.now().add(const Duration(days: 1))).isAfter(clock.now()));

  Future<void> save() async {
    final b = AppScope.read(context).backend;
    final l = L.of(context);
    setState(() {
      busy = true;
      failed = null;
    });
    try {
      final until = endAt(clock.now());
      if (editing) {
        await b.editInviteLink(widget.roomId, widget.link!.code, name: name.text, until: until, max: max);
      } else {
        await b.makeInviteLink(widget.roomId, name: name.text, until: until, max: max);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = l.linkFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final now = clock.now();
    final end = endAt(now);
    Widget seg(Key key, int value, List<String> labels, ValueChanged<int> on) => Padding(
      padding: EdgeInsets.all(Tokens.space[2]),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<int>(
          key: key,
          groupValue: value,
          children: {
            for (var i = 0; i < labels.length; i++)
              i: Padding(
                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                child: Text(labels[i], maxLines: 1, style: Tokens.caption.style.copyWith(color: p.label)),
              ),
          },
          onValueChanged: (v) => v == null ? null : on(v),
        ),
      ),
    );
    return SettingsScaffold(
      title: editing ? l.invEditTitle : l.invNewTitle,
      trailing: [GlassPill(key: const Key('inv-save'), text: editing ? l.done : l.invMake, onTap: valid ? save : null)],
      children: [
        group(context, footer: l.invNameInfo, [
          CupertinoTextField.borderless(
            key: const Key('inv-name'),
            controller: name,
            placeholder: l.invNameHint,
            maxLength: 32,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + 2),
          ),
        ]),
        group(context, header: l.invTime, footer: end == null ? l.invTimeNone : l.invTimeEnds(DateFormat.MMMd(lang).add_jm().format(end)), [
          seg(const Key('inv-time'), time, [l.inv1h, l.inv1d, l.inv1w, l.invNoLimit, l.invPick], (v) => setState(() => time = v)),
          if (time == 4)
            SizedBox(
              height: Tokens.wheelHeight,
              child: CupertinoDatePicker(
                key: const Key('inv-time-wheel'),
                initialDateTime: pickedEnd ?? now.add(const Duration(days: 1)),
                minimumDate: now,
                maximumDate: now.add(const Duration(days: 366)),
                use24hFormat: false,
                onDateTimeChanged: (t) => setState(() => pickedEnd = t),
              ),
            ),
        ]),
        group(context, header: l.invPeople, footer: widget.approval ? l.invPeopleApproval : (max > 0 ? l.invPeopleN(max) : l.invPeopleNone), [
          seg(const Key('inv-seats'), seats, [
            l.invPeopleCount(1),
            l.invPeopleCount(10),
            l.invPeopleCount(100),
            l.invNoLimit,
            l.invPick,
          ], (v) => setState(() => seats = v)),
          if (seats == 4)
            CupertinoTextField.borderless(
              key: const Key('inv-count'),
              controller: count,
              placeholder: l.invPeopleHint,
              autofocus: !editing,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
              style: Tokens.body.style.copyWith(color: p.label),
              padding: EdgeInsets.all(Tokens.space[2] + 2),
              onChanged: (_) => setState(() {}),
            ),
        ]),
        if (failed != null)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
            child: sectionFooter(context, failed!, error: true),
          ),
      ],
    );
  }
}

/// One extra link: the link (copy / share / promo image), how it stands,
/// who came in, edit, cancel (5초 되돌리기) or, once cancelled, delete.
class InviteLinkDetailPage extends StatefulWidget {
  const InviteLinkDetailPage({super.key, required this.roomId, required this.roomName, required this.isChannel, required this.link});
  final String roomId;
  final String roomName;
  final bool isChannel;
  final InviteLink link;

  @override
  State<InviteLinkDetailPage> createState() => _InviteLinkDetailPageState();
}

class _InviteLinkDetailPageState extends State<InviteLinkDetailPage> {
  late InviteLink k = widget.link;
  Map<String, String> names = const {};

  Backend get b => AppScope.read(context).backend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final list = await b.inviteLinks(widget.roomId).catchError((_) => <InviteLink>[]);
    final ms = await b.members(widget.roomId).catchError((_) => <Member>[]);
    if (!mounted) return;
    setState(() {
      k = list.where((x) => x.code == k.code).firstOrNull ?? k;
      names = {for (final m in ms) m.userId: m.name};
    });
  }

  void cancel() {
    final l = L.of(context);
    final nav = Navigator.of(context);
    final room = widget.roomId, code = k.code, backend = b;
    final deleting = k.revoked;
    nav.pop();
    showUndoCountdown(
      context,
      (n) => deleting ? l.invDeleteIn(n) : l.invRevokeIn(n),
      () => (deleting ? backend.deleteInviteLink(room, code) : backend.revokeInviteLink(room, code)).catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final now = clock.now();
    final st = k.state(now);
    final text = k.link(roomName: widget.roomName, channel: widget.isChannel);
    final who = k.joined.reversed.toList();
    return SettingsScaffold(
      title: k.name.isNotEmpty ? k.name : l.linkTitle,
      children: [
        if (k.usable(now))
          group(context, [LinkCard(key: Key('inv-card-${k.code}'), link: text)])
        else
          group(context, footer: st == 'revoked' ? l.invRevokedInfo : (st == 'full' ? l.invFullInfo : l.invEndedInfo), [
            IosTile(
              leading: LinkRing(color: linkStateColor(context, st), left: 0, ring: false),
              leadingSize: Tokens.linkRing,
              title: Text(linkTitle(k)),
              subtitle: Text(linkStatusLine(l, k, now)),
            ),
          ]),
        if (k.usable(now))
          group(context, [
            IosTile(
              key: const Key('inv-status'),
              leading: LinkRing(color: linkStateColor(context, st), left: k.left(now), ring: k.until != null || k.max > 0),
              leadingSize: Tokens.linkRing,
              title: Text(linkStatusLine(l, k, now)),
              subtitle: Text(
                k.until == null ? l.invTimeNone : l.invTimeEnds(DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(k.until!)),
              ),
            ),
            NavRow(
              key: const Key('inv-poster'),
              color: Palette.tilePurple,
              icon: CupertinoIcons.qrcode,
              title: l.posterMake,
              onTap: () => Navigator.of(context).push(
                IosPageRoute(
                  builder: (_) => PosterPage(roomId: widget.roomId, name: widget.roomName, link: text, isChannel: widget.isChannel),
                ),
              ),
            ),
            NavRow(
              key: const Key('inv-edit'),
              color: Palette.tileBlue,
              icon: CupertinoIcons.pencil,
              title: l.invEditTitle,
              onTap: () async {
                await Navigator.of(context).push(
                  IosPageRoute<void>(
                    builder: (_) => InviteLinkEditPage(roomId: widget.roomId, link: k),
                  ),
                );
                await load();
              },
            ),
          ]),
        group(context, header: l.invJoinedHeader(k.uses), footer: k.uses > who.length ? l.invJoinedMore : null, [
          if (who.isEmpty)
            IosTile(
              title: Text(l.invNobody, style: Tokens.body.style.copyWith(color: paletteOf(context).secondaryLabel)),
            )
          else
            for (final u in who)
              IosTile(
                key: Key('inv-who-$u'),
                leading: Avatar(name: names[u] ?? displayId(u), userId: u, size: Tokens.memberAvatar),
                leadingSize: Tokens.memberAvatar,
                title: Text(names[u] ?? displayId(u)),
                subtitle: names.containsKey(u) ? null : Text(l.invLeftRoom),
              ),
        ]),
        group(context, [
          IosTile(
            key: const Key('inv-cancel'),
            title: Text(k.revoked ? l.invDelete : l.invRevoke, style: const TextStyle(color: Palette.tileRed)),
            onTap: cancel,
          ),
        ]),
      ],
    );
  }
}

/// Under the main link: up to three overlapping faces and "N명 참여"
/// (Telegram's invite link page); tap for the list.
class JoinedFaces extends StatelessWidget {
  const JoinedFaces({super.key, required this.count, required this.who, this.roomId});
  final int count;

  /// Newest last.
  final List<String> who;
  final String? roomId;

  static const face = Tokens.joinedFace;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final recent = who.reversed.take(3).toList();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        IosPageRoute<void>(
          builder: (_) => JoinedListPage(who: who, count: count, roomId: roomId),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: Tokens.space[3]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: face + (recent.length - 1).clamp(0, 2) * face * .62,
              height: face,
              child: Stack(
                children: [
                  for (var i = recent.length - 1; i >= 0; i--)
                    Positioned(
                      left: i * face * .62,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: p.card, width: 1.5),
                        ),
                        child: Avatar(name: displayId(recent[i]).replaceFirst('@', ''), userId: recent[i], size: face - 3, round: true),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            Text(l.invJoined(count), style: Tokens.preview.style.copyWith(color: p.accent)),
          ],
        ),
      ),
    );
  }
}

/// Everyone the server counted for a link (newest first).
class JoinedListPage extends StatefulWidget {
  const JoinedListPage({super.key, required this.who, required this.count, this.roomId});
  final List<String> who;
  final int count;
  final String? roomId;

  @override
  State<JoinedListPage> createState() => _JoinedListPageState();
}

class _JoinedListPageState extends State<JoinedListPage> {
  Map<String, String> names = const {};

  @override
  void initState() {
    super.initState();
    final r = widget.roomId;
    if (r != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final ms = await AppScope.read(context).backend.members(r).catchError((_) => <Member>[]);
        if (mounted) setState(() => names = {for (final m in ms) m.userId: m.name});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return SettingsScaffold(
      title: l.invJoined(widget.count),
      children: [
        group(context, footer: widget.count > widget.who.length ? l.invJoinedMore : null, [
          for (final u in widget.who.reversed)
            IosTile(
              leading: Avatar(name: names[u] ?? displayId(u), userId: u, size: Tokens.memberAvatar),
              leadingSize: Tokens.memberAvatar,
              title: Text(names[u] ?? displayId(u)),
              subtitle: widget.roomId != null && names.isNotEmpty && !names.containsKey(u) ? Text(l.invLeftRoom) : null,
            ),
        ]),
      ],
    );
  }
}
