// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Microphone and speaker stand-ins for screen tests.
import 'dart:async';
import 'dart:typed_data';

import 'package:burumy/core/voice.dart';

class FakeRecorder implements VoiceRecorder {
  FakeRecorder({this.allowed = true});
  final bool allowed;
  final _level = StreamController<double>.broadcast();
  bool cancelled = false;

  @override
  Stream<double> get level => _level.stream;
  @override
  Future<bool> start() async => allowed;
  @override
  Future<Recording?> stop() async =>
      Recording(Uint8List.fromList(List.filled(100, 7)), 'audio/mp4', const Duration(seconds: 4), [for (var i = 0; i < 40; i++) (i * 97) % 1024]);
  @override
  Future<void> cancel() async => cancelled = true;
  bool paused = false;
  @override
  Future<void> pause() async => paused = true;
  @override
  Future<void> resume() async => paused = false;
}

class FakePlayer implements VoicePlayer {
  static int plays = 0;
  final _pos = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  @override
  Future<void> play(Uint8List bytes, String key) async {
    plays++;
    _playing.add(true);
    _pos.add(const Duration(seconds: 1));
  }

  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Future<void> dispose() async {}
}
