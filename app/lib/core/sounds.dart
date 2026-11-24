// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Our own sounds (made for Burumy v1, see REFERENCES.md): eight message
// sounds and two call tones, played from the app's own files.
import 'package:just_audio/just_audio.dart' as ja;

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
