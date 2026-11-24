// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Plans ("일정") and contact cards: the maker's screens and the bubbles.
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'ios.dart';
import 'glass.dart';

class CreateMeetupPage extends StatefulWidget {
  const CreateMeetupPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<CreateMeetupPage> createState() => _CreateMeetupPageState();
}

class _CreateMeetupPageState extends State<CreateMeetupPage> {
  final title = TextEditingController();
  final place = TextEditingController();
  late DateTime when = () {
    final n = DateTime.now().add(const Duration(days: 1));
    return DateTime(n.year, n.month, n.day, 19);
  }();
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
    try {
      await AppScope.of(context).backend.createMeetup(widget.roomId, title.text.trim(), when, place.text.trim());
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final field = Tokens.body.style.copyWith(color: p.label);
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
            IosSection(
              hasLeading: false,
              header: sectionHeader(context, l.meetupWhen),
              footer: sectionFooter(context, l.meetupInfo),
              children: [
                SizedBox(
                  height: 200,
                  child: CupertinoDatePicker(
                    key: const Key('meetup-when'),
                    initialDateTime: when,
                    minimumDate: DateTime.now().subtract(const Duration(minutes: 1)),
                    minuteInterval: 5,
                    use24hFormat: false,
                    onDateTimeChanged: (d) => when = d,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A plan in the chat: a calendar tile, time and place, and three answers.
class MeetupBubble extends StatelessWidget {
  const MeetupBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta, required this.onChanged, this.showWho = false});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final Future<void> Function() onChanged;
  final bool showWho;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final m = msg.meetup!;
    final lang = Localizations.localeOf(context).languageCode;
    final past = m.startsAt.isBefore(DateTime.now());
    final closed = m.cancelled || past;
    final mineAnswer = m.answerOf(s.backend.userId);
    Future<void> answer(String a) async {
      await s.backend.answerMeetup(roomId, msg.id, mineAnswer == a ? '' : a);
      await onChanged();
    }

    Widget choice(String id, String label, int n) {
      final on = mineAnswer == id;
      return Expanded(
        child: GestureDetector(
          key: Key('meetup-$id'),
          onTap: closed ? null : () => answer(id),
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
              // iOS Calendar-style tile: small red month, big day.
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
                        fontWeight: FontWeight.w600,
                        decoration: m.cancelled ? TextDecoration.lineThrough : null,
                        decorationColor: fg,
                      ),
                    ),
                    Text(DateFormat.MMMEd(lang).add_jm().format(m.startsAt), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.8))),
                    if (m.place != null)
                      Text(
                        '📍 ${m.place}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.8)),
                      ),
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
            Row(children: [choice('yes', l.meetupYes, m.yes.length), choice('maybe', l.meetupMaybe, m.maybe.length), choice('no', l.meetupNo, m.no.length)]),
            if (showWho && m.yes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${l.meetupYes}: ${m.yes.map(displayId).join(', ')}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                ),
              ),
          ],
          Row(
            children: [
              if (msg.mine && !closed)
                GestureDetector(
                  key: const Key('meetup-cancel'),
                  onTap: () async {
                    await s.backend.cancelMeetup(roomId, msg.id);
                    await onChanged();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l.meetupCancel, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75))),
                  ),
                ),
              const Spacer(),
              meta,
            ],
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
                        CupertinoListTile(
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
                      style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w600),
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
