// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 일정 (설정 > 내 일정): every plan I made or said I'd go to, from all
// chats, soonest first; tap one to jump to it in its chat. Kept on this
// phone only.
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/my_plans.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'calls_page.dart' show EmptyState;
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'ios.dart';
import 'meetup.dart' show meetupTimeText;
import 'settings_kit.dart';

class MyPlansPage extends StatefulWidget {
  const MyPlansPage({super.key, this.now});

  /// Tests pin the clock.
  final DateTime? now;

  @override
  State<MyPlansPage> createState() => _MyPlansPageState();
}

class _MyPlansPageState extends State<MyPlansPage> {
  /// Past plans shown at most.
  static const pastShown = 20;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = widget.now ?? DateTime.now();
    final all = MyPlans.all(s);
    final soon = all.where((x) => !x.pastAt(now)).toList();
    final past = all.where((x) => x.pastAt(now)).toList().reversed.take(pastShown).toList();

    Widget row(MyPlan x, {bool old = false}) {
      final chat = s.chats.where((c) => c.roomId == x.roomId).firstOrNull;
      final answer = switch (x.answer) {
        'maybe' => l.meetupMaybe,
        'mine' => l.myPlansMade,
        _ => x.guests > 0 ? '${l.myPlansGoing} +${x.guests}' : l.myPlansGoing,
      };
      final line = [answer, meetupTimeText(lang, x.start, x.end), if (x.place != null) x.place!, if (chat != null) chat.name].join(' · ');
      return IosTile(
        key: Key('plan-${x.id}'),
        leadingSize: 40,
        leading: Opacity(
          opacity: old ? 0.5 : 1,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[1])),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: FittedBox(
              child: Column(
                children: [
                  Text(DateFormat.E(lang).format(x.start), style: Tokens.bubbleMeta.style.copyWith(color: Palette.tileRed)),
                  Text('${x.start.day}', style: Tokens.cardTitle.style.copyWith(color: p.label, height: 1.1)),
                ],
              ),
            ),
          ),
        ),
        title: Text(
          x.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: old ? p.secondaryLabel : p.label),
        ),
        subtitle: Text(line, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: chat == null ? null : const IosChevron(),
        onTap: chat == null ? null : () => openChat(context, x.roomId, chat.name, jump: x.id),
      );
    }

    return SettingsScaffold(
      title: l.myPlans,
      children: [
        if (all.isEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[5], Tokens.space[5], 0),
            child: EmptyState(text: l.myPlansEmpty),
          ),
        if (soon.isNotEmpty) group(context, [for (final x in soon) row(x)], header: l.myPlansSoon),
        if (past.isNotEmpty) group(context, [for (final x in past) row(x, old: true)], header: l.myPlansPast),
        group(context, [
          IosTile(
            title: Text(l.meetupRemind),
            trailing: IosSwitch(
              key: const Key('plans-remind'),
              value: MyPlans.reminds(s),
              onChanged: (v) => MyPlans.setReminds(s, v, l.meetupReminderTitle).then((_) => mounted ? setState(() {}) : null),
            ),
          ),
        ], footer: l.meetupRemindInfo),
      ],
    );
  }
}
