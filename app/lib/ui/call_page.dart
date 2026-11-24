// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Call screens: calling, ringing for me, talking (voice or video), ended.
// Layout follows the iPhone call screen: name and status on top, round
// buttons at the bottom, red to end, green to answer.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/call_session.dart';
import '../core/sounds.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios_route.dart';

const _white = Color(0xFFFFFFFF);
const _shade = Color(0x2EFFFFFF);

/// Starts a call from a chat and opens the call screen over everything.
Future<void> startCall(BuildContext context, String roomId, String title, {required bool video}) async {
  if (CallSession.active != null) return;
  final s = CallSession.outgoing(AppScope.of(context).backend, roomId, title, video: video);
  await Navigator.of(context, rootNavigator: true).push(IosPageRoute(fullscreenDialog: true, builder: (_) => CallPage(session: s)));
}

class CallPage extends StatefulWidget {
  const CallPage({super.key, required this.session});
  final CallSession session;
  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  CallSession get s => widget.session;
  Timer? closing;

  @override
  void initState() {
    super.initState();
    s.addListener(changed);
    CallSession.waiting.addListener(waitingChanged);
    tone();
  }

  /// Our own call tones: ringing for me, or waiting while I call.
  CallPhase? toneFor;
  void tone() {
    if (toneFor == s.phase) return;
    toneFor = s.phase;
    switch (s.phase) {
      case CallPhase.incoming:
        unawaited(Sounds.call('ring'));
      case CallPhase.calling:
        unawaited(Sounds.call('wait'));
      default:
        unawaited(Sounds.stop());
    }
  }

  void waitingChanged() {
    if (mounted) setState(() {});
  }

  /// Opens [next] in place of this screen.
  void openInstead(CallSession next) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(IosPageRoute(fullscreenDialog: true, builder: (_) => CallPage(session: next)));
  }

  Future<void> endAndAnswer() async {
    closing?.cancel();
    closing = const _Never();
    final next = await CallSession.endAndAnswer();
    if (next != null) openInstead(next);
  }

  void changed() {
    if (!mounted) return;
    tone();
    setState(() {});
    if (s.phase == CallPhase.ended && closing == null) {
      closing = Timer(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        // My call ended while another was waiting: it now rings normally.
        final w = CallSession.waiting.value;
        if (w != null && w.phase == CallPhase.incoming) {
          CallSession.waiting.value = null;
          openInstead(w);
        } else {
          Navigator.of(context).maybePop();
        }
      });
    }
  }

  @override
  void dispose() {
    closing?.cancel();
    CallSession.waiting.removeListener(waitingChanged);
    s.removeListener(changed);
    unawaited(Sounds.stop());
    s.dispose();
    super.dispose();
  }

  String status(L l) {
    switch (s.phase) {
      case CallPhase.incoming:
        return s.video ? l.callVideo : l.callVoice;
      case CallPhase.calling:
        return l.callCalling;
      case CallPhase.connecting:
        return l.callConnecting;
      case CallPhase.live:
        final d = clock.now().difference(s.liveSince ?? clock.now());
        return callClock(d);
      case CallPhase.ended:
        return switch (s.endedBy) {
          CallEnd.noAnswer => l.callNoAnswer,
          CallEnd.declined => l.callDeclined,
          CallEnd.busy => l.callBusy,
          CallEnd.failed => l.callFailed,
          _ => l.callEnded,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final base = Avatar.colorFor(s.title);
    final m = s.media;
    final showVideo = s.video && s.phase == CallPhase.live && m != null;
    final w = CallSession.waiting.value;
    final waitingShown = w != null && !identical(w, s) && s.phase != CallPhase.incoming;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: the friend's colour fading to night (iPhone style).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.lerp(base, const Color(0xFF000000), 0.25)!, Color.lerp(base, const Color(0xFF000000), 0.82)!],
              ),
            ),
          ),
          if (showVideo && m.otherVideo) Positioned.fill(child: m.otherView()),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: Tokens.space[4] + (waitingShown ? 84 : 0)),
                if (!(showVideo && m.otherVideo)) ...[Avatar(name: s.title, size: 110), SizedBox(height: Tokens.space[2])],
                Text(
                  s.title,
                  key: const Key('call-name'),
                  style: Tokens.screenTitle.style.copyWith(color: _white, fontWeight: FontWeight.w400),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(
                  status(l),
                  key: const Key('call-status'),
                  style: Tokens.body.style.copyWith(color: _white.withValues(alpha: 0.75)),
                ),
                SizedBox(height: Tokens.space[1]),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.lock_fill, size: 12, color: _white.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(l.callE2ee, style: Tokens.caption.style.copyWith(color: _white.withValues(alpha: 0.6))),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[4]),
                  child: s.phase == CallPhase.incoming ? answerRow(l) : controls(l),
                ),
              ],
            ),
          ),
          if (showVideo && s.camera)
            Positioned(
              top: MediaQuery.paddingOf(context).top + Tokens.space[2],
              right: Tokens.space[2],
              width: 104,
              height: 150,
              child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius[2]), child: m.myView()),
            ),
          if (CallSession.waiting.value case final w? when !identical(w, s) && s.phase != CallPhase.incoming)
            Positioned(
              top: MediaQuery.paddingOf(context).top + Tokens.space[1],
              left: Tokens.space[2],
              right: Tokens.space[2],
              child: WaitingBanner(call: w, onDecline: CallSession.declineWaiting, onAnswer: endAndAnswer),
            ),
        ],
      ),
    );
  }

  Widget answerRow(L l) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      RoundCallButton(key: const Key('call-decline'), icon: CupertinoIcons.phone_down_fill, label: l.callDecline, color: Palette.tileRed, onTap: s.decline),
      RoundCallButton(
        key: const Key('call-accept'),
        icon: s.video ? CupertinoIcons.video_camera_solid : CupertinoIcons.phone_fill,
        label: l.callAccept,
        color: paletteOf(context).tileGreen,
        onTap: s.accept,
      ),
    ],
  );

  Widget controls(L l) {
    final ended = s.phase == CallPhase.ended;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RoundCallButton(
              key: const Key('call-speaker'),
              icon: CupertinoIcons.speaker_3_fill,
              label: l.callSpeaker,
              on: s.speaker,
              onTap: ended ? null : s.toggleSpeaker,
            ),
            RoundCallButton(
              key: const Key('call-camera'),
              icon: s.camera ? CupertinoIcons.video_camera_solid : CupertinoIcons.video_camera,
              label: l.callCamera,
              on: s.camera,
              onTap: ended || !s.video ? null : s.toggleCamera,
            ),
            RoundCallButton(
              key: const Key('call-mute'),
              icon: s.mic ? CupertinoIcons.mic_fill : CupertinoIcons.mic_slash_fill,
              label: l.callMute,
              on: !s.mic,
              onTap: ended ? null : s.toggleMic,
            ),
            if (s.video)
              RoundCallButton(
                key: const Key('call-flip'),
                icon: CupertinoIcons.camera_rotate_fill,
                label: l.callFlip,
                onTap: ended || !s.camera ? null : s.flip,
              ),
          ],
        ),
        SizedBox(height: Tokens.space[4]),
        RoundCallButton(
          key: const Key('call-end'),
          icon: CupertinoIcons.phone_down_fill,
          label: l.callEnd,
          color: Palette.tileRed,
          onTap: ended ? null : s.hangUp,
        ),
      ],
    );
  }
}

/// mm:ss (or h:mm:ss) for the call clock and call lines.
String callClock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours, m = d.inMinutes % 60, sec = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}

/// Round button of the call screen. [color] = filled (answer/end); else
/// frosted, and white when switched on.
class RoundCallButton extends StatelessWidget {
  const RoundCallButton({super.key, required this.icon, required this.label, this.onTap, this.on = false, this.color});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool on;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? (on ? _white : _shade);
    final glyph = color != null ? _white : (on ? const Color(0xFF1C1C1E) : _white);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
              child: Icon(icon, color: glyph, size: 30),
            ),
            SizedBox(height: Tokens.space[0] + 2),
            Text(label, style: Tokens.caption.style.copyWith(color: _white)),
          ],
        ),
      ),
    );
  }
}

/// A call line in the chat: which way, how it went, how long; tap to call back.
class CallLine extends StatelessWidget {
  const CallLine({super.key, required this.msg, required this.onCallBack});
  final Msg msg;
  final void Function(bool video)? onCallBack;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final c = msg.call!;
    final missed = !msg.mine && (c.state == 'missed' || c.state == 'busy');
    final label = switch (c.state) {
      'ongoing' || 'ringing' => l.callLineNow,
      'declined' => l.callLineDeclined,
      'missed' || 'busy' => msg.mine ? l.callLineCancelled : l.callLineMissed,
      _ => msg.mine ? l.callLineOut : l.callLineIn,
    };
    final talked = c.talked;
    final when = shortTime(context, msg.time);
    final sub = talked == null ? when : '$when · ${callClock(talked)}';
    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onCallBack == null ? null : () => onCallBack!(c.video),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 2, horizontal: Tokens.space[1]),
          padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
          decoration: BoxDecoration(color: msg.mine ? p.accent.withValues(alpha: 0.16) : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[3])),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Tokens.body.style.copyWith(color: p.label)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        msg.mine ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left,
                        size: 13,
                        color: missed || c.state == 'declined' ? Palette.tileRed : p.accent,
                      ),
                      const SizedBox(width: 3),
                      Text(sub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                ],
              ),
              SizedBox(width: Tokens.space[3]),
              Icon(c.video ? CupertinoIcons.video_camera : CupertinoIcons.phone, color: p.accent, size: 26),
            ],
          ),
        ),
      ),
    );
  }
}

/// Watches for calls ringing for me and opens the ringing screen. A second
/// call while I am in one waits (banner on the call screen), like a phone.
class CallWatcher extends StatefulWidget {
  const CallWatcher({super.key, required this.child});
  final Widget child;
  @override
  State<CallWatcher> createState() => _CallWatcherState();
}

class _CallWatcherState extends State<CallWatcher> {
  final handled = <String>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    for (final r in s.ringing) {
      if (!handled.add(r.callId)) continue;
      final title = s.chats.where((c) => c.roomId == r.roomId).firstOrNull?.name ?? displayId(r.from);
      if (CallSession.active != null) {
        // My choice in Settings: call waiting (default; the caller hears it
        // ring), let it ring out to a missed call, or tell "busy". A third
        // call just rings out and becomes a missed call.
        unawaited(() async {
          final mode = await s.backend.callWaiting().catchError((_) => 'wait');
          if (CallSession.active == null) return;
          if (mode == 'busy') {
            await s.backend.hangupCall(r.roomId, r.callId, 'busy').catchError((_) {});
          } else if (mode == 'wait' && CallSession.waiting.value == null) {
            CallSession.waiting.value = CallSession.incoming(s.backend, r, title);
          }
        }());
        continue;
      }
      final session = CallSession.incoming(s.backend, r, title);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).push(IosPageRoute(fullscreenDialog: true, builder: (_) => CallPage(session: session)));
      });
      break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A Timer that never fires (marks "already leaving").
class _Never implements Timer {
  const _Never();
  @override
  void cancel() {}
  @override
  bool get isActive => false;
  @override
  int get tick => 0;
}

/// Call waiting banner on top of the call screen (iPhone style card).
class WaitingBanner extends StatelessWidget {
  const WaitingBanner({super.key, required this.call, required this.onDecline, required this.onAnswer});
  final CallSession call;
  final VoidCallback onDecline;
  final VoidCallback onAnswer;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    Widget circle(Key key, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: _white, size: 22),
      ),
    );
    return Container(
      key: const Key('call-waiting'),
      padding: EdgeInsets.all(Tokens.space[2]),
      decoration: BoxDecoration(color: const Color(0xE62C2C2E), borderRadius: BorderRadius.circular(Tokens.radius[3])),
      child: Row(
        children: [
          Avatar(name: call.title, size: 46),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: _white),
                ),
                Text(call.video ? l.callWaitingVideo : l.callWaiting, style: Tokens.caption.style.copyWith(color: _white.withValues(alpha: 0.7))),
              ],
            ),
          ),
          circle(const Key('waiting-decline'), CupertinoIcons.phone_down_fill, Palette.tileRed, onDecline),
          SizedBox(width: Tokens.space[2]),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [circle(const Key('waiting-answer'), CupertinoIcons.phone_fill, paletteOf(context).tileGreen, onAnswer)],
          ),
        ],
      ),
    );
  }
}
