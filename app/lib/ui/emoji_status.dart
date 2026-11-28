// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이모지 상태 (Telegram tip 359; free for everyone in Burumy): an emoji
// beside my name (🏖️ 휴가 중, 💼 일하는 중 …), for a while or until I
// change it. It goes end-to-end encrypted into each friend's 1:1 chat
// (Backend.setEmojiStatus), so the server never learns it, and people who
// only share a group with me don't get it. Shown after names in the chat
// list, the chat's title, the profile and my Settings card.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart' show EmojiStatus;
import '../design/tokens.dart';
import 'common.dart';
import '../l10n/app_localizations.dart';
import 'emoji_pick.dart';
import 'ios.dart';
import 'stories.dart' show showStoryToast;

/// Pref with my own status: "<emoji>|<until ms or 0>".
const myStatusKey = 'my_status';

EmojiStatus? myEmojiStatus(AppState s) {
  final parts = s.pref(myStatusKey, '').split('|');
  if (parts.length != 2 || parts.first.isEmpty) return null;
  final ms = int.tryParse(parts[1]) ?? 0;
  final st = EmojiStatus(parts.first, ms == 0 ? null : DateTime.fromMillisecondsSinceEpoch(ms));
  return st.liveAt(DateTime.now()) ? st : null;
}

/// Sets (or with '' clears) my status and sends it to my friends.
Future<int> setMyEmojiStatus(AppState s, String emoji, Duration? lasts) async {
  final until = lasts == null ? null : DateTime.now().add(lasts);
  await s.setPref(myStatusKey, emoji.isEmpty ? '' : '$emoji|${until?.millisecondsSinceEpoch ?? 0}');
  _cache.remove(s.backend.userId);
  return s.backend.setEmojiStatus(emoji, until);
}

/// Friends' statuses, asked once a minute at most.
final _cache = <String, (EmojiStatus?, DateTime)>{};
final _asking = <String, Future<void>>{};

/// Forgets friends' statuses (tests; a new account on this phone).
void forgetEmojiStatuses() => _cache.clear();

/// A small emoji after a name (nothing when there is no status).
class StatusMark extends StatefulWidget {
  const StatusMark({super.key, required this.user, this.size = 16, this.onTap});
  final String user;
  final double size;
  final VoidCallback? onTap;

  @override
  State<StatusMark> createState() => _StatusMarkState();
}

class _StatusMarkState extends State<StatusMark> {
  @override
  void initState() {
    super.initState();
    ask();
  }

  @override
  void didUpdateWidget(StatusMark old) {
    super.didUpdateWidget(old);
    if (old.user != widget.user) ask();
  }

  void ask() {
    final u = widget.user;
    if (u.isEmpty) return;
    final s = AppScope.read(context);
    if (u == s.backend.userId) return;
    final had = _cache[u];
    if (had != null && DateTime.now().difference(had.$2) < const Duration(minutes: 1)) return;
    final f = _asking[u] ??= s.backend
        .emojiStatusOf(u)
        .then((v) => _cache[u] = (v, DateTime.now()), onError: (_) => _cache[u] = (null, DateTime.now()))
        .whenComplete(() => _asking.remove(u));
    unawaited(f.then((_) => mounted ? setState(() {}) : null));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = widget.user;
    final st = u == s.backend.userId ? myEmojiStatus(s) : _cache[u]?.$1;
    if (st == null || !st.liveAt(DateTime.now())) {
      // Mine: an empty smile to tap (Telegram's "set status" spot), else nothing.
      if (widget.onTap != null) {
        return GestureDetector(
          key: const Key('status-empty'),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(CupertinoIcons.smiley, size: widget.size, color: paletteOf(context).secondaryLabel.withValues(alpha: 0.6)),
          ),
        );
      }
      return const SizedBox.shrink();
    }
    return GestureDetector(
      key: Key('status-${st.emoji}'),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(st.emoji, style: emojiStyle(widget.size)),
      ),
    );
  }
}

/// Quick picks first (Telegram shows a grid; ours leads with the common ones).
const statusQuick = ['🏖️', '💼', '📚', '✈️', '🏃', '😴', '🤒', '🎮', '🎧', '🍽️', '🚗', '❤️'];

/// The status sheet: pick an emoji, then how long.
Future<void> openEmojiStatus(BuildContext context, {String? emoji}) async {
  final s = AppScope.read(context);
  final l = L.of(context);
  var e = emoji;
  if (e == null) {
    final now = myEmojiStatus(s);
    e = await showCupertinoModalPopup<String>(
      context: context,
      builder: (c) {
        final p = paletteOf(c);
        return IosActionSheet(
          title: Text(l.statusTitle),
          message: Column(
            children: [
              Text(l.statusInfo),
              SizedBox(height: Tokens.space[2]),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  for (final q in statusQuick)
                    GestureDetector(
                      key: Key('status-quick-$q'),
                      onTap: () => Navigator.pop(c, q),
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: now?.emoji == q ? p.accent.withValues(alpha: 0.18) : null, shape: BoxShape.circle),
                        child: Text(q, style: emojiStyle(28)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(key: const Key('status-more'), onPressed: () => Navigator.pop(c, '+'), child: Text(l.statusOther)),
            if (now != null)
              CupertinoActionSheetAction(
                key: const Key('status-clear'),
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(c, ''),
                child: Text(l.statusClear),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        );
      },
    );
    if (e == '+' && context.mounted) e = await pickEmoji(context, title: l.statusTitle);
  }
  if (e == null || !context.mounted) return;
  if (e.isEmpty) {
    await setMyEmojiStatus(s, '', null);
    if (context.mounted) showStoryToast(context, l.statusCleared);
    return;
  }
  final picked = e;
  final lasts = await showCupertinoModalPopup<Duration?>(
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(picked, style: emojiStyle(44)),
      message: Text(l.statusHowLong),
      actions: [
        for (final (k, d, label) in [
          ('1h', const Duration(hours: 1), l.statusFor1h),
          ('2h', const Duration(hours: 2), l.statusFor2h),
          ('8h', const Duration(hours: 8), l.statusFor8h),
          ('2d', const Duration(days: 2), l.statusFor2d),
        ])
          CupertinoActionSheetAction(key: Key('status-for-$k'), onPressed: () => Navigator.pop(c, d), child: Text(label)),
        CupertinoActionSheetAction(key: const Key('status-for-ever'), onPressed: () => Navigator.pop(c, Duration.zero), child: Text(l.statusForEver)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (lasts == null || !context.mounted) return;
  await setMyEmojiStatus(s, picked, lasts == Duration.zero ? null : lasts);
  if (context.mounted) showStoryToast(context, l.statusSet(picked));
}
