// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// One call from ring to hang-up. Ringing, answering and hanging up are
// small encrypted chat events; the sound and picture go through
// [CallMedia], encrypted end to end with the key from the invite.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

import 'backend.dart';
import 'data_usage.dart';
import 'call_media.dart';

enum CallPhase { incoming, calling, connecting, live, ended }

/// Why a call ended (for the line on the call screen).
enum CallEnd { normal, noAnswer, declined, busy, failed, cancelled, ignored }

class CallSession extends ChangeNotifier {
  CallSession._(this.backend, this.roomId, this.title, this.video, this.phase, {this.callId = ''}) : camera = video, speaker = video;

  /// I am calling. Rings until the other side answers (45 s at most).
  static CallSession outgoing(Backend b, String roomId, String title, {required bool video}) =>
      CallSession._(b, roomId, title, video, CallPhase.calling)..unawaitedStart();

  /// A call ringing for me.
  static CallSession incoming(Backend b, RingingCall r, String title) =>
      CallSession._(b, r.roomId, title, r.video, CallPhase.incoming, callId: r.callId).._watch();

  /// The single call going on right now.
  static CallSession? active;

  /// A second call ringing while I talk (call waiting, like a phone). The
  /// caller just hears it ring; unanswered it becomes a missed call.
  static final waiting = ValueNotifier<CallSession?>(null);

  static const ringFor = Duration(seconds: 45);

  final Backend backend;
  final String roomId;
  final String title;
  final bool video;
  String callId;
  CallPhase phase;
  CallEnd? endedBy;
  DateTime? liveSince;
  bool mic = true;
  bool camera;
  bool speaker;
  CallMedia? media;
  Timer? _tick;
  DateTime _began = clock.now();

  void unawaitedStart() => unawaited(_start());

  Future<void> _start() async {
    active = this;
    try {
      callId = await backend.startCall(roomId, video: video);
      await _join();
      _watch();
    } catch (_) {
      await _finish(CallEnd.failed, send: false);
    }
  }

  Future<void> _join() async {
    final t = await backend.callTicket(roomId, callId);
    final m = CallMedia.make();
    media = m;
    m.addListener(_mediaChanged);
    await m.join(t);
    await m.setSpeaker(speaker);
  }

  void _watch() {
    _began = clock.now();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _check());
  }

  void _mediaChanged() {
    final m = media;
    if (m == null) return;
    if (m.otherHere && (phase == CallPhase.calling || phase == CallPhase.connecting)) {
      phase = CallPhase.live;
      liveSince = clock.now();
    }
    if (m.otherLeft && phase == CallPhase.live) {
      unawaited(_finish(CallEnd.normal));
      return;
    }
    notifyListeners();
  }

  Future<void> _check() async {
    if (phase == CallPhase.ended || callId.isEmpty) return;
    final String state;
    try {
      state = await backend.callState(roomId, callId);
    } catch (_) {
      return;
    }
    if (phase == CallPhase.ended) return;
    switch (state) {
      case 'declined':
        await _finish(phase == CallPhase.incoming ? CallEnd.cancelled : CallEnd.declined, send: false);
      case 'busy':
        await _finish(phase == CallPhase.incoming ? CallEnd.cancelled : CallEnd.busy, send: false);
      case 'missed':
        await _finish(phase == CallPhase.incoming ? CallEnd.cancelled : CallEnd.noAnswer, send: false);
      case 'ended':
        await _finish(CallEnd.normal, send: false);
      default:
        if (phase == CallPhase.calling && clock.now().difference(_began) >= ringFor) {
          await _finish(CallEnd.noAnswer);
        } else if (phase == CallPhase.incoming && clock.now().difference(_began) >= ringFor) {
          await _finish(CallEnd.cancelled, send: false);
        } else {
          notifyListeners(); // the live clock
        }
    }
  }

  Future<void> accept() async {
    if (phase != CallPhase.incoming) return;
    active = this;
    phase = CallPhase.connecting;
    notifyListeners();
    try {
      await backend.answerCall(roomId, callId);
      await _join();
      _mediaChanged();
    } catch (_) {
      await _finish(CallEnd.failed);
    }
  }

  /// Call waiting: end the call I am in and answer the waiting one.
  static Future<CallSession?> endAndAnswer() async {
    final w = waiting.value;
    if (w == null) return null;
    waiting.value = null;
    await active?.hangUp();
    await w.accept();
    return w;
  }

  /// Call waiting: say no to the waiting call, keep talking.
  static Future<void> declineWaiting() async {
    final w = waiting.value;
    waiting.value = null;
    await w?.decline();
  }

  Future<void> decline() async {
    if (phase != CallPhase.incoming) return;
    phase = CallPhase.ended;
    endedBy = CallEnd.declined;
    _tick?.cancel();
    notifyListeners();
    await backend.hangupCall(roomId, callId, 'decline');
  }

  /// 무시 (WhatsApp 2025): stop the ringing on my side only. Nothing is
  /// sent, so the caller just hears it ring out (and can leave a message);
  /// for me it becomes a missed call.
  void ignore() {
    if (phase != CallPhase.incoming) return;
    phase = CallPhase.ended;
    endedBy = CallEnd.ignored;
    _tick?.cancel();
    if (identical(waiting.value, this)) waiting.value = null;
    notifyListeners();
  }

  Future<void> hangUp() => _finish(phase == CallPhase.calling ? CallEnd.cancelled : CallEnd.normal);

  Future<void> _finish(CallEnd why, {bool send = true}) async {
    if (phase == CallPhase.ended) return;
    // 데이터 사용량 (tip 379): estimated from the minutes talked.
    final since = liveSince;
    if (since != null) DataUsage.noteCall(clock.now().difference(since), video: video);
    phase = CallPhase.ended;
    endedBy = why;
    _tick?.cancel();
    if (identical(active, this)) active = null;
    if (identical(waiting.value, this)) waiting.value = null;
    notifyListeners();
    final m = media;
    media = null;
    m?.removeListener(_mediaChanged);
    try {
      if (send && callId.isNotEmpty) await backend.hangupCall(roomId, callId, 'end');
    } catch (_) {}
    try {
      await m?.leave();
    } catch (_) {}
  }

  Future<void> toggleMic() async {
    mic = !mic;
    notifyListeners();
    await media?.setMic(mic);
  }

  Future<void> toggleCamera() async {
    camera = !camera;
    notifyListeners();
    await media?.setCamera(camera);
  }

  Future<void> toggleSpeaker() async {
    speaker = !speaker;
    notifyListeners();
    await media?.setSpeaker(speaker);
  }

  Future<void> flip() async => media?.flipCamera();

  bool _gone = false;

  @override
  void notifyListeners() {
    if (!_gone) super.notifyListeners();
  }

  @override
  void dispose() {
    _gone = true;
    _tick?.cancel();
    if (phase != CallPhase.ended) unawaited(_finish(CallEnd.normal));
    super.dispose();
  }
}
