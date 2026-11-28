// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// "통화 안 받으면 메시지 남기기": after a call nobody answered, the call
// screen offers 음성 남기기 / 영상 남기기 / 다시 걸기 (like the iPhone's
// FaceTime "Record Video" after no answer). The voice page records with a
// tap (no holding), then sends it as an ordinary encrypted voice message.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'glass.dart';

const _white = Color(0xFFFFFFFF);

/// Tap to record, tap again to send (2 minutes at most).
class VoiceNotePage extends StatefulWidget {
  const VoiceNotePage({super.key, required this.roomId, required this.title});
  final String roomId;
  final String title;
  static const maxLength = Duration(minutes: 2);

  @override
  State<VoiceNotePage> createState() => _VoiceNotePageState();
}

class _VoiceNotePageState extends State<VoiceNotePage> {
  VoiceRecorder? rec;
  bool sending = false, noMic = false;
  final watch = Stopwatch();
  final levels = <double>[];
  StreamSubscription<double>? sub;
  Timer? tick;

  @override
  void dispose() {
    tick?.cancel();
    unawaited(sub?.cancel());
    unawaited(rec?.cancel());
    super.dispose();
  }

  Future<void> start() async {
    final r = VoiceKit.recorder();
    final ok = await r.start().catchError((_) => false);
    if (!mounted) return;
    if (!ok) return setState(() => noMic = true);
    rec = r;
    levels.clear();
    sub = r.level.listen((v) {
      levels.add(v);
      if (levels.length > 40) levels.removeAt(0);
    });
    watch
      ..reset()
      ..start();
    tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (watch.elapsed >= VoiceNotePage.maxLength) unawaited(stop());
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  Future<void> stop() async {
    final r = rec;
    if (r == null) return;
    tick?.cancel();
    watch.stop();
    unawaited(sub?.cancel());
    setState(() {
      rec = null;
      sending = true;
    });
    final s = AppScope.read(context);
    try {
      final got = await r.stop();
      if (got == null || got.duration < const Duration(milliseconds: 700)) {
        if (mounted) setState(() => sending = false);
        return;
      }
      await s.backend.sendVoice(widget.roomId, got.mime, got.bytes, got.duration, got.waveform);
      unawaited(s.refresh());
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final recording = rec != null;
    final d = watch.elapsed;
    final time = '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return CupertinoPageScaffold(
      key: const Key('voice-note-page'),
      backgroundColor: const Color(0xF0000000),
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: GlassCircle(
                  key: const Key('voice-note-close'),
                  onTap: () => Navigator.of(context).pop(false),
                  child: const Icon(CupertinoIcons.xmark, color: _white, size: 20),
                ),
              ),
            ),
            const Spacer(),
            Text(
              l.callNoteTo(widget.title),
              textAlign: TextAlign.center,
              style: Tokens.screenTitle.style.copyWith(color: _white, fontWeight: FontWeight.w400),
            ),
            SizedBox(height: Tokens.space[3]),
            SizedBox(
              height: 48,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 40; i++)
                    Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                      height: 4 + 40 * (i < levels.length ? levels[i].clamp(0.0, 1.0) : 0.0),
                      decoration: BoxDecoration(
                        color: _white.withValues(alpha: recording ? 0.9 : 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            Text(
              noMic ? l.voiceNoMic : (recording ? time : l.callNoteVoiceHint),
              key: const Key('voice-note-time'),
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: _white.withValues(alpha: 0.8)),
            ),
            const Spacer(),
            GestureDetector(
              key: const Key('voice-note-record'),
              onTap: sending ? null : (recording ? stop : start),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _white, width: 4),
                ),
                alignment: Alignment.center,
                child: sending
                    ? const CupertinoActivityIndicator(color: _white)
                    : AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: recording ? 28 : 60,
                        height: recording ? 28 : 60,
                        decoration: BoxDecoration(color: const Color(0xFFFF3B30), borderRadius: BorderRadius.circular(recording ? 6 : 30)),
                      ),
              ),
            ),
            SizedBox(height: Tokens.space[5]),
          ],
        ),
      ),
    );
  }
}
