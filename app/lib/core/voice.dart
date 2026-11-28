// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Voice recording and playback behind small interfaces, so screens can be
// tested without a microphone or speaker.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

class Recording {
  const Recording(this.bytes, this.mime, this.duration, this.waveform);
  final Uint8List bytes;
  final String mime;
  final Duration duration;

  /// Loudness bars, 0..1024.
  final List<int> waveform;
}

abstract class VoiceRecorder {
  Future<bool> start();

  /// Live loudness 0..1 while recording.
  Stream<double> get level;
  Future<Recording?> stop();
  Future<void> cancel();

  /// Locked recording (v1): pause and go on.
  Future<void> pause();
  Future<void> resume();
}

abstract class VoicePlayer {
  Future<void> play(Uint8List bytes, String key);
  Future<void> pause();

  /// 1, 1.5 or 2 (v1 voice speed).
  Future<void> setSpeed(double speed);

  /// Jump to [at] (이어 듣기, tip 199).
  Future<void> seek(Duration at);
  Stream<Duration> get position;
  Stream<bool> get playing;
  Future<void> dispose();
}

/// Where screens get their recorder and player (tests swap these).
class VoiceKit {
  static VoiceRecorder Function() recorder = () => _MicRecorder();
  static VoicePlayer Function() player = () => _SpeakerPlayer();

  /// Phones, computers and the web (the browser asks for the microphone).
  static bool get canRecord => true;
}

/// Squeezes many loudness samples into [bars] bars (0..1024).
List<int> squeeze(List<double> samples, {int bars = 40}) {
  if (samples.isEmpty) return const [];
  final out = <int>[];
  for (var i = 0; i < bars; i++) {
    final from = (i * samples.length / bars).floor();
    final to = ((i + 1) * samples.length / bars).ceil().clamp(from + 1, samples.length);
    final part = samples.sublist(from.clamp(0, samples.length - 1), to);
    final peak = part.reduce((a, b) => a > b ? a : b);
    out.add((peak.clamp(0.0, 1.0) * 1024).round());
  }
  return out;
}

class _MicRecorder implements VoiceRecorder {
  final _r = rec.AudioRecorder();
  final _levels = <double>[];
  final _level = StreamController<double>.broadcast();
  StreamSubscription<rec.Amplitude>? _sub;
  DateTime? _started;
  String? _path;
  String _mime = 'audio/mp4';

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<bool> start() async {
    if (!await _r.hasPermission()) return false;
    var encoder = rec.AudioEncoder.aacLc;
    if (kIsWeb) {
      // Browsers record AAC (plays everywhere) when they can, else Opus.
      if (!await _r.isEncoderSupported(encoder)) encoder = rec.AudioEncoder.opus;
      _mime = encoder == rec.AudioEncoder.opus ? 'audio/webm' : 'audio/mp4';
      _path = '';
    } else {
      final dir = await getTemporaryDirectory();
      _path = '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
    }
    await _r.start(rec.RecordConfig(encoder: encoder, bitRate: 48000, sampleRate: 44100, numChannels: 1), path: _path!);
    _started = DateTime.now();
    _sub = _r.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((a) {
      // dBFS (-60..0) to 0..1.
      final v = ((a.current + 60) / 60).clamp(0.0, 1.0);
      _levels.add(v);
      _level.add(v);
    });
    return true;
  }

  /// Time spent paused (left out of the length).
  Duration _paused = Duration.zero;
  DateTime? _pausedAt;

  @override
  Future<void> pause() async {
    if (_pausedAt != null) return;
    _pausedAt = DateTime.now();
    await _r.pause();
  }

  @override
  Future<void> resume() async {
    final at = _pausedAt;
    if (at == null) return;
    _paused += DateTime.now().difference(at);
    _pausedAt = null;
    await _r.resume();
  }

  @override
  Future<Recording?> stop() async {
    await _sub?.cancel();
    if (_pausedAt != null) await resume();
    final path = await _r.stop();
    final took = DateTime.now().difference(_started ?? DateTime.now()) - _paused;
    if (path == null) return null;
    final Uint8List bytes;
    if (kIsWeb) {
      // The browser hands back a short-lived blob address on this page.
      bytes = (await http.get(Uri.parse(path))).bodyBytes;
    } else {
      final f = File(path);
      bytes = await f.readAsBytes();
      await f.delete().catchError((_) => f);
    }
    await _r.dispose();
    return Recording(bytes, _mime, took, squeeze(_levels));
  }

  @override
  Future<void> cancel() async {
    await _sub?.cancel();
    await _r.cancel();
    await _r.dispose();
  }
}

class _SpeakerPlayer implements VoicePlayer {
  final _p = ja.AudioPlayer();
  String? _loaded;

  @override
  Future<void> play(Uint8List bytes, String key) async {
    if (_loaded != key && kIsWeb) {
      // Web: straight from memory (WebM starts with 1A 45 DF A3).
      final webm = bytes.length > 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3;
      await _p.setAudioSource(ja.AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: webm ? 'audio/webm' : 'audio/mp4')));
      _loaded = key;
    }
    if (_loaded != key) {
      final dir = await getTemporaryDirectory();
      // Decrypted only into the app's own temp folder, removed on dispose.
      final f = File('${dir.path}/play_${key.hashCode}.m4a');
      await f.writeAsBytes(bytes, flush: true);
      await _p.setFilePath(f.path);
      _loaded = key;
    }
    if (_p.processingState == ja.ProcessingState.completed) await _p.seek(Duration.zero);
    unawaited(_p.play());
  }

  @override
  Future<void> pause() => _p.pause();

  @override
  Future<void> setSpeed(double speed) => _p.setSpeed(speed);

  @override
  Future<void> seek(Duration at) => _p.seek(at);

  @override
  Stream<Duration> get position => _p.positionStream;

  @override
  Stream<bool> get playing => _p.playerStateStream.map((s) => s.playing && s.processingState != ja.ProcessingState.completed);

  @override
  Future<void> dispose() async {
    await _p.dispose();
    if (_loaded != null && !kIsWeb) {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/play_${_loaded.hashCode}.m4a');
      if (await f.exists()) await f.delete();
    }
  }
}
