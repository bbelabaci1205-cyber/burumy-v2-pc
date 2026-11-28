// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Plans ("일정") and contact cards: the maker's screens and the bubbles.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/calendar_event.dart';
import '../core/my_plans.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'stories.dart' show showStoryToast;

class CreateMeetupPage extends StatefulWidget {
  const CreateMeetupPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<CreateMeetupPage> createState() => _CreateMeetupPageState();
}

/// "When" like the iPhone Calendar's new event: 시작 and 종료 rows that
/// open a wheel right under them (one at a time).
class _CreateMeetupPageState extends State<CreateMeetupPage> {
  final title = TextEditingController();
  final place = TextEditingController();
  late DateTime when = () {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day, 19);
  }();
  DateTime? until;
  bool hasEnd = false;

  /// Which wheel is open: "start", "end" or null.
  String? open = 'start';
  bool busy = false;

  bool get ready => title.text.trim().isNotEmpty && !busy;

  @override
  void dispose() {
    title.dispose();
    place.dispose();
    super.dispose();
  }

  Future<void> create() async {
    if (!ready) return;
    setState(() => busy = true);
    final s = AppScope.of(context);
    final l = L.of(context);
    try {
      final end = hasEnd ? until : null;
      final id = await s.backend.createMeetup(widget.roomId, title.text.trim(), when, place.text.trim(), endsAt: end);
      // My own plan goes into 내 일정 right away (with its reminder).
      final plan = MeetupInfo(title: title.text.trim(), startsAt: when, endsAt: end, place: place.text.trim().isEmpty ? null : place.text.trim());
      await MyPlans.update(s, roomId: widget.roomId, id: id, plan: plan, answer: 'mine', reminderTitle: l.meetupReminderTitle(plan.title));
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void setStart(DateTime d) => setState(() {
    final length = (until ?? when.add(const Duration(hours: 2))).difference(when);
    when = d;
    // Like Calendar: moving the start keeps the same length.
    if (until != null) until = d.add(length.isNegative ? const Duration(hours: 1) : length);
  });

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final field = Tokens.body.style.copyWith(color: p.label);
    final end = until ?? when.add(const Duration(hours: 2));
    // iOS Calendar: the label, then a date pill and a time pill.
    Widget dateRow(String id, String label, DateTime d, {bool bad = false}) {
      final on = open == id;
      Widget pill(String text) => Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[1])),
        child: Text(
          text,
          maxLines: 1,
          style: Tokens.body.style.copyWith(
            color: on ? p.accent : (bad ? Palette.tileRed : p.label),
            decoration: bad ? TextDecoration.lineThrough : null,
            decorationColor: Palette.tileRed,
          ),
        ),
      );
      return GestureDetector(
        key: Key('meetup-$id-row'),
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => open = on ? null : id),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 20, end: 12),
          child: Row(
            children: [
              Text(label, maxLines: 1, style: Tokens.body.style.copyWith(color: p.label)),
              SizedBox(width: Tokens.space[2]),
              // Long dates (English, big text) shrink instead of spilling.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [pill(DateFormat.MMMEd(lang).format(d)), pill(DateFormat.jm(lang).format(d))]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget wheel(String id, DateTime d, ValueChanged<DateTime> changed, DateTime min) => AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: open != id
          ? const SizedBox(width: double.infinity)
          : SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                key: Key('meetup-$id-wheel'),
                initialDateTime: d.isBefore(min) ? min : d,
                minimumDate: min,
                minuteInterval: 5,
                use24hFormat: false,
                onDateTimeChanged: changed,
              ),
            ),
    );

    final rows = <Widget>[
      dateRow('start', l.meetupStarts, when),
      if (open == 'start') wheel('start', when, setStart, _roundDown(DateTime.now())),
      IosTile(
        title: Text(l.meetupEndToggle),
        trailing: IosSwitch(
          key: const Key('meetup-end-switch'),
          value: hasEnd,
          onChanged: (v) => setState(() {
            hasEnd = v;
            until ??= when.add(const Duration(hours: 2));
            open = v ? 'end' : (open == 'end' ? null : open);
          }),
        ),
      ),
      if (hasEnd) dateRow('end', l.meetupEnds, end, bad: !end.isAfter(when)),
      if (hasEnd && open == 'end') wheel('end', end, (d) => setState(() => until = d), when.add(const Duration(minutes: 5))),
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.newMeetup),
        trailing: Opacity(
          opacity: ready ? 1 : 0.4,
          child: GlassPill(key: const Key('meetup-create'), text: l.send, onTap: ready ? create : null),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              hasLeading: false,
              children: [
                CupertinoTextField.borderless(
                  key: const Key('meetup-title'),
                  controller: title,
                  placeholder: l.meetupTitleHint,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 200,
                  onChanged: (_) => setState(() {}),
                ),
                CupertinoTextField.borderless(
                  key: const Key('meetup-place'),
                  controller: place,
                  placeholder: l.meetupPlaceHint,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 200,
                  prefix: Padding(
                    padding: EdgeInsets.only(left: Tokens.space[2]),
                    child: Icon(CupertinoIcons.location_solid, size: Tokens.listIconSmall, color: p.secondaryLabel),
                  ),
                ),
              ],
            ),
            IosSection(hasLeading: false, header: sectionHeader(context, l.meetupWhen), children: rows),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, '${l.meetupRemindInfo}\n${l.meetupInfo}'),
              children: [
                IosTile(
                  title: Text(l.meetupRemind),
                  trailing: IosSwitch(
                    key: const Key('meetup-remind'),
                    value: MyPlans.reminds(s),
                    onChanged: (v) => MyPlans.setReminds(s, v, l.meetupReminderTitle).then((_) => mounted ? setState(() {}) : null),
                  ),
                ),
              ],
            ),
            SizedBox(height: Tokens.space[5]),
          ],
        ),
      ),
    );
  }

  static DateTime _roundDown(DateTime d) => DateTime(d.year, d.month, d.day, d.hour, d.minute - d.minute % 5);
}

/// "11월 29일 (토) 오후 2:00 – 4:00" (the end's date only when it differs).
String meetupTimeText(String lang, DateTime start, DateTime? end) {
  final full = DateFormat.MMMEd(lang).add_jm();
  if (end == null) return full.format(start);
  final sameDay = end.year == start.year && end.month == start.month && end.day == start.day;
  return '${full.format(start)} – ${sameDay ? DateFormat.jm(lang).format(end) : full.format(end)}';
}

/// A plan in the chat: a calendar tile, time and place, three answers,
/// how many I bring, and 캘린더에 추가.
class MeetupBubble extends StatefulWidget {
  const MeetupBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta, required this.onChanged, this.showWho = false});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final Future<void> Function() onChanged;
  final bool showWho;

  @override
  State<MeetupBubble> createState() => _MeetupBubbleState();
}

class _MeetupBubbleState extends State<MeetupBubble> {
  bool sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The maker cancelled it: off 내 일정, no reminder.
    final m = widget.msg.meetup!;
    final s = AppScope.of(context);
    if (m.cancelled && MyPlans.find(s, widget.msg.id) != null) unawaited(MyPlans.drop(s, widget.msg.id));
  }

  Future<void> send(String answer, int guests) async {
    if (sending) return;
    final s = AppScope.of(context);
    final l = L.of(context);
    final m = widget.msg.meetup!;
    setState(() => sending = true);
    try {
      await s.backend.answerMeetup(widget.roomId, widget.msg.id, MeetupInfo.answerWith(answer, guests));
      await MyPlans.update(
        s,
        roomId: widget.roomId,
        id: widget.msg.id,
        plan: m,
        answer: answer.isEmpty && widget.msg.mine ? 'mine' : answer,
        guests: guests,
        reminderTitle: l.meetupReminderTitle(m.title),
      );
      await widget.onChanged();
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> toCalendar() async {
    final m = widget.msg.meetup!;
    final l = L.of(context);
    final ok = await CalendarEvent(title: m.title, start: m.startsAt, end: m.endsAt, place: m.place, id: widget.msg.id).add();
    if (ok && kIsWeb && mounted) showStoryToast(context, l.meetupCalendarFile);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final msg = widget.msg;
    final fg = widget.fg;
    final m = msg.meetup!;
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final past = (m.endsAt ?? m.startsAt).isBefore(now);
    final closed = m.cancelled || past;
    final me = s.backend.userId;
    final mineAnswer = m.answerOf(me);
    final bring = m.guestsOf(me);

    Widget choice(String id, String label, int n) {
      final on = mineAnswer == id;
      return Expanded(
        child: GestureDetector(
          key: Key('meetup-$id'),
          onTap: closed ? null : () => send(on ? '' : id, 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 34,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? fg : fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Text(
              n > 0 ? '$label $n' : label,
              maxLines: 1,
              style: Tokens.caption.style.copyWith(color: on ? (msg.mine ? p.accent : p.card) : fg.withValues(alpha: closed ? 0.5 : 1)),
            ),
          ),
        ),
      );
    }

    Widget round(String key, IconData icon, VoidCallback? tap) => GestureDetector(
      key: Key(key),
      onTap: tap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fg.withValues(alpha: tap == null ? 0.06 : 0.14),
        ),
        child: Icon(icon, size: 16, color: fg.withValues(alpha: tap == null ? 0.35 : 1)),
      ),
    );

    final small = Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.8));
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: Column(
        key: Key('meetup-${msg.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // iOS Calendar-style tile: small red weekday, big day.
              Container(
                width: 46,
                height: 50,
                decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(Tokens.radius[1])),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat.E(lang).format(m.startsAt), style: Tokens.bubbleMeta.style.copyWith(color: Palette.tileRed)),
                    Text('${m.startsAt.day}', style: Tokens.cardTitle.style.copyWith(color: const Color(0xFF000000), height: 1.1)),
                  ],
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.title,
                      style: Tokens.body.style.copyWith(
                        color: fg,
                        fontWeight: Tokens.semi,
                        decoration: m.cancelled ? TextDecoration.lineThrough : null,
                        decorationColor: fg,
                      ),
                    ),
                    Text(meetupTimeText(lang, m.startsAt, m.endsAt), key: const Key('meetup-time'), style: small),
                    if (m.place != null) Text('📍 ${m.place}', maxLines: 2, overflow: TextOverflow.ellipsis, style: small),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Tokens.space[1]),
          if (m.cancelled)
            Text(
              l.meetupCancelled,
              key: const Key('meetup-cancelled'),
              style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
            )
          else ...[
            if (past) Text(l.meetupPast, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7))),
            Row(children: [choice('yes', l.meetupYes, m.coming), choice('maybe', l.meetupMaybe, m.maybe.length), choice('no', l.meetupNo, m.no.length)]),
            // 같이 오는 사람: only once I said I'm going.
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: mineAnswer != 'yes' || closed
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4, right: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(l.meetupBring, style: small)),
                          round('meetup-guest-minus', CupertinoIcons.minus, bring > 0 && !sending ? () => send('yes', bring - 1) : null),
                          SizedBox(
                            width: 34,
                            child: Text(
                              '+$bring',
                              key: const Key('meetup-guests'),
                              textAlign: TextAlign.center,
                              style: Tokens.body.style.copyWith(color: fg, fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ),
                          round('meetup-guest-plus', CupertinoIcons.plus, bring < MeetupInfo.maxGuests && !sending ? () => send('yes', bring + 1) : null),
                        ],
                      ),
                    ),
            ),
            if (widget.showWho && m.yes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l.meetupYes}: ${m.yes.map((u) => (m.guests[u] ?? 0) > 0 ? l.meetupWithGuests(displayId(u), m.guests[u]!) : displayId(u)).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                if (!closed)
                  GestureDetector(
                    key: const Key('meetup-calendar'),
                    onTap: toCalendar,
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar_badge_plus, size: 15, color: fg.withValues(alpha: 0.85)),
                        const SizedBox(width: 3),
                        Text(l.meetupAddCalendar, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                if (msg.mine && !closed) ...[
                  SizedBox(width: Tokens.space[3]),
                  GestureDetector(
                    key: const Key('meetup-cancel'),
                    onTap: () async {
                      await s.backend.cancelMeetup(widget.roomId, msg.id);
                      await MyPlans.drop(s, msg.id);
                      await widget.onChanged();
                    },
                    child: Text(l.meetupCancel, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75))),
                  ),
                ],
                const Spacer(),
                widget.meta,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick one of my contacts to share in this chat.
class PickContactPage extends StatefulWidget {
  const PickContactPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<PickContactPage> createState() => _PickContactPageState();
}

class _PickContactPageState extends State<PickContactPage> {
  List<Person>? people;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (people == null) {
      AppScope.of(context).backend.contacts().then((x) {
        if (mounted) setState(() => people = x);
      }, onError: (_) => mounted ? setState(() => people = const []) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final list = people;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), middle: Text(l.pickContact), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: list == null
            ? const Center(child: CupertinoActivityIndicator())
            : list.isEmpty
            ? Center(
                child: Text(l.noContacts, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              )
            : ListView(
                children: [
                  IosSection(
                    children: [
                      for (final c in list)
                        IosTile(
                          key: Key('pick-contact-${c.userId}'),
                          leading: Avatar(name: aliasOf(s, c.userId).isEmpty ? c.name : aliasOf(s, c.userId), size: 32),
                          title: Text(aliasOf(s, c.userId).isEmpty ? c.name : aliasOf(s, c.userId)),
                          subtitle: Text(displayId(c.userId), style: Tokens.caption.style),
                          onTap: () async {
                            final name = aliasOf(s, c.userId).isEmpty ? c.name : aliasOf(s, c.userId);
                            await s.backend.sendContact(widget.roomId, c.userId, name);
                            if (context.mounted) Navigator.pop(context, true);
                          },
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// A shared contact: avatar, name, ID and "message".
class ContactBubble extends StatelessWidget {
  const ContactBubble({super.key, required this.msg, required this.fg, required this.meta});
  final Msg msg;
  final Color fg;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final uid = msg.contact!;
    final name = msg.body ?? displayId(uid);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: Column(
        key: Key('contact-${msg.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Avatar(name: name, size: 44),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: fg, fontWeight: Tokens.semi),
                    ),
                    Text(displayId(uid), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Tokens.space[1]),
          if (uid != s.backend.userId)
            GestureDetector(
              key: const Key('contact-message'),
              onTap: () async {
                final room = await s.makeChat(() => s.backend.createDirectChat(uid));
                await s.refresh();
                // Never the name written on the card: anyone can type any name there.
                if (context.mounted) await openChat(context, room, displayId(uid));
              },
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(l.contactMessage, style: Tokens.caption.style.copyWith(color: fg)),
              ),
            ),
          Align(alignment: Alignment.centerRight, child: meta),
        ],
      ),
    );
  }
}
