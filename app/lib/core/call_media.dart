// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sound and picture of a call. Runs through our LiveKit server, encrypted
// end to end with the media key from the encrypted chat invite, so the
// server only passes along scrambled frames.
import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import 'backend.dart';

/// What the call screen needs from the media side (tests use a fake).
abstract class CallMedia extends ChangeNotifier {
  /// Set by tests to a fake.
  static CallMedia Function() make = LiveKitMedia.new;

  Future<void> join(CallTicket t);
  bool get connected;

  /// The other person is in the call (and whether their camera is on).
  bool get otherHere;
  bool get otherVideo;

  /// The other person was here and left.
  bool get otherLeft;

  Future<void> setMic(bool on);
  Future<void> setCamera(bool on);
  Future<void> setSpeaker(bool on);
  Future<void> flipCamera();

  Widget otherView();
  Widget myView();
  Future<void> leave();
}

class LiveKitMedia extends CallMedia {
  /// Settings > Data > "전화에 데이터 적게 쓰기": smaller, slower video.
  static bool lowData = false;
  lk.Room? _room;
  bool _wasHere = false;
  bool _front = true;

  @override
  Future<void> join(CallTicket t) async {
    final keys = await lk.BaseKeyProvider.create();
    await keys.setSharedKey(t.mediaKey);
    final room = lk.Room(
      roomOptions: lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        encryption: lk.E2EEOptions(keyProvider: keys),
        defaultCameraCaptureOptions: lowData ? const lk.CameraCaptureOptions(params: lk.VideoParametersPresets.h360_169) : const lk.CameraCaptureOptions(),
        defaultVideoPublishOptions: lowData
            ? const lk.VideoPublishOptions(videoEncoding: lk.VideoEncoding(maxBitrate: 250 * 1000, maxFramerate: 15))
            : const lk.VideoPublishOptions(),
      ),
    );
    _room = room;
    room.addListener(_changed);
    await room.connect(t.url, t.token);
    await room.localParticipant?.setMicrophoneEnabled(true);
    if (t.video) await room.localParticipant?.setCameraEnabled(true);
    _changed();
  }

  void _changed() {
    if (otherHere) _wasHere = true;
    notifyListeners();
  }

  lk.RemoteParticipant? get _other => _room?.remoteParticipants.values.firstOrNull;

  lk.VideoTrack? get _otherTrack {
    for (final p in _other?.videoTrackPublications ?? const <lk.RemoteTrackPublication>[]) {
      final t = p.track;
      if (t is lk.VideoTrack && !p.muted) return t as lk.VideoTrack;
    }
    return null;
  }

  lk.LocalVideoTrack? get _myTrack {
    for (final p in _room?.localParticipant?.videoTrackPublications ?? const <lk.LocalTrackPublication>[]) {
      final t = p.track;
      if (t != null && !p.muted) return t as lk.LocalVideoTrack;
    }
    return null;
  }

  @override
  bool get connected => _room?.connectionState == lk.ConnectionState.connected;
  @override
  bool get otherHere => _other != null;
  @override
  bool get otherVideo => _otherTrack != null;
  @override
  bool get otherLeft => _wasHere && _other == null;

  @override
  Future<void> setMic(bool on) async => _room?.localParticipant?.setMicrophoneEnabled(on);
  @override
  Future<void> setCamera(bool on) async => _room?.localParticipant?.setCameraEnabled(on);
  @override
  Future<void> setSpeaker(bool on) => lk.AudioManager.instance.setSpeakerOutputPreferred(on);
  @override
  Future<void> flipCamera() async {
    _front = !_front;
    await _myTrack?.setCameraPosition(_front ? lk.CameraPosition.front : lk.CameraPosition.back);
  }

  @override
  Widget otherView() {
    final t = _otherTrack;
    return t == null ? const SizedBox.shrink() : lk.VideoTrackRenderer(t, fit: lk.VideoViewFit.cover);
  }

  @override
  Widget myView() {
    final t = _myTrack;
    return t == null ? const SizedBox.shrink() : lk.VideoTrackRenderer(t, fit: lk.VideoViewFit.cover);
  }

  @override
  Future<void> leave() async {
    final r = _room;
    _room = null;
    r?.removeListener(_changed);
    await r?.disconnect();
    await r?.dispose();
  }
}
