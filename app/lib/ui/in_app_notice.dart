// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// In-app alerts (Settings > Notifications > While using the app): a glass
// banner at the top like an iPhone notification, and our own message sound.
// Never for the chat that is open, my own messages, muted, hidden or
// switched-off chats, or during focus hours.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/reminders.dart';
import '../core/rules.dart';
import '../core/sounds.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

/// Sound pref for a chat kind ("sound_direct", "sound_group", "sound_channel").
String soundKey(ChatPreview c) => c.isDirect ? 'sound_direct' : (c.isChannel ? 'sound_channel' : 'sound_group');

class InAppNotices extends StatefulWidget {
  const InAppNotices({super.key, required this.child, required this.onOpen});
  final Widget child;
  final void Function(String roomId, String name) onOpen;

  @override
  State<InAppNotices> createState() => _InAppNoticesState();
}

class _InAppNoticesState extends State<InAppNotices> {
  AppState? s;
  final seen = <String, String>{};
  bool primed = false;
  (ChatPreview, Msg)? showing;
  Timer? hide;

  /// Checks message reminders ("알림 받기") while the app is open.
  Timer? remindTick;

  @override
  void initState() {
    super.initState();
    remindTick = Timer.periodic(const Duration(seconds: 20), (_) => checkReminders());
  }

  Future<void> checkReminders() async {
    final st = s;
    if (st == null || !st.loggedIn || st.locked || !mounted) return;
    final due = await takeDueReminders(st, DateTime.now());
    if (due.isEmpty || !mounted) return;
    final r = due.last;
    final chat = st.chats.where((c) => c.roomId == r.roomId).firstOrNull;
    if (chat == null) return;
    final l = L.of(context);
    final m = Msg(id: 'remind:${r.msgId}', sender: '', body: '⏰ ${l.remindDue}', time: r.at, mine: false, kind: 'text');
    if (st.on('in_app_sound', fallback: true)) unawaited(Sounds.message(st.pref(soundKey(chat), 'nuri')));
    hide?.cancel();
    hide = Timer(const Duration(seconds: 6), () {
      if (mounted) setState(() => showing = null);
    });
    setState(() => showing = (chat, m));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final n = AppScope.read(context);
    if (n != s) {
      s?.removeListener(changed);
      s = n..addListener(changed);
      changed();
    }
  }

  @override
  void dispose() {
    s?.removeListener(changed);
    hide?.cancel();
    remindTick?.cancel();
    super.dispose();
  }

  void changed() {
    final st = s!;
    (ChatPreview, Msg)? fresh;
    for (final c in st.chats) {
      final m = c.last;
      if (m == null) continue;
      final before = seen[c.roomId];
      seen[c.roomId] = m.id;
      if (!primed || before == m.id || m.mine || c.roomId == st.openRoom || st.locked) continue;
      // Calls ring on their own screen.
      if (m.kind == 'call' || m.call != null) continue;
      final n = Notice(roomId: c.roomId, chat: c.name, sender: m.sender, kind: m.kind, body: m.body, time: m.time);
      if (!noticeAllowed(n, st.settings, c, DateTime.now())) continue;
      fresh = (c, m);
    }
    primed = true;
    if (fresh == null) return;
    if (st.on('in_app_sound', fallback: true)) unawaited(Sounds.message(st.pref(soundKey(fresh.$1), 'nuri')));
    if (st.on('in_app_vibrate', fallback: true)) unawaited(HapticFeedback.mediumImpact());
    if (st.pref('in_app_style', 'banner') != 'banner') return;
    hide?.cancel();
    hide = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => showing = null);
    });
    if (mounted) setState(() => showing = fresh);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final shown = showing;
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          left: Tokens.space[2],
          right: Tokens.space[2],
          top: shown == null ? -120 : top + Tokens.space[0],
          child: shown == null ? const SizedBox.shrink() : _Banner(chat: shown.$1, msg: shown.$2, onTap: () => tap(shown.$1), onClose: close),
        ),
      ],
    );
  }

  void close() {
    hide?.cancel();
    setState(() => showing = null);
  }

  void tap(ChatPreview c) {
    close();
    widget.onOpen(c.roomId, c.name);
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.chat, required this.msg, required this.onTap, required this.onClose});
  final ChatPreview chat;
  final Msg msg;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final preview = s.on('in_app_preview', fallback: true);
    final text = preview ? previewTextL(l, kind: msg.kind, body: msg.body, caption: msg.caption) : l.noticeNew;
    return GestureDetector(
      key: const Key('in-app-notice'),
      onTap: onTap,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < 0) onClose();
      },
      child: LiquidGlass(
        radius: Tokens.radius[3],
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[2]),
          child: Row(
            children: [
              Avatar(name: chat.name, size: 38, squircle: !chat.isDirect, userId: chat.isDirect ? chat.peer : null, roomId: chat.roomId),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chat.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: p.label),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
