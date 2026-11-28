// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Our own sounds (made for Burumy v1, see REFERENCES.md): eight message
// sounds and two call tones, played from the app's own files.
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';

import 'app_state.dart';
import 'my_sounds.dart';

/// Message sounds people can pick (file names under assets/sounds/).
const messageSounds = ['nuri', 'pop', 'drop', 'bell', 'chord', 'breeze', 'knock', 'twinkle'];

class Sounds {
  const Sounds._();

  /// Tests swap this so nothing touches the speaker.
  static Future<void> Function(String asset, {bool loop}) player = _play;

  static ja.AudioPlayer? _p;

  static Future<void> _play(String asset, {bool loop = false}) async {
    final p = _p ??= ja.AudioPlayer();
    await p.stop();
    await p.setAsset(asset);
    await p.setLoopMode(loop ? ja.LoopMode.one : ja.LoopMode.off);
    await p.play();
  }

  /// A message sound by name ("none" plays nothing).
  static Future<void> message(String name) async {
    if (name == 'none' || !messageSounds.contains(name)) return;
    try {
      await player('assets/sounds/burumy_$name.wav');
    } catch (_) {}
  }

  /// Tests swap this (a saved sound's bytes and type).
  static Future<void> Function(List<int> bytes, String mime) bytesPlayer = _playBytes;

  static Future<void> _playBytes(List<int> bytes, String mime) async {
    final p = _p ??= ja.AudioPlayer();
    await p.stop();
    if (kIsWeb) {
      await p.setAudioSource(ja.AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mime)));
    } else {
      // Only into the app's own temp folder, for as long as it plays.
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/tone_play.${mime.contains('webm') ? 'webm' : (mime.contains('ogg') ? 'ogg' : 'm4a')}');
      await f.writeAsBytes(bytes, flush: true);
      await p.setFilePath(f.path);
      unawaited(p.playerStateStream.firstWhere((x) => x.processingState == ja.ProcessingState.completed).then((_) => f.delete()).catchError((_) => f));
    }
    await p.setLoopMode(ja.LoopMode.off);
    await p.play();
  }

  /// Any sound name: ours, "none" or a saved one ("my:<id>", tip 329).
  static Future<void> play(AppState s, String name) async {
    final mine = MySounds.find(s, name);
    if (mine == null) return message(name);
    try {
      final b = await MySounds.bytes(s, mine.id);
      if (b != null) await bytesPlayer(b, mine.mime);
    } catch (_) {}
  }

  /// Call tones: "ring" (someone calls me) or "wait" (I'm calling).
  static Future<void> call(String which) async {
    try {
      await player('assets/sounds/burumy_call_$which.wav', loop: true);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _p?.stop();
    } catch (_) {}
  }
}
