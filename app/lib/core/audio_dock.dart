// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// One player for music and long audio in chats (Telegram tips 199 + 108):
// tap a song and the chat's songs become a play list; a mini bar stays at
// the top while you scroll or change chats, with speed (1× → 1.5× → 2×,
// hold for 0.5×–2.5×) and a full player sheet (seek, previous / next,
// repeat). Where you stopped in a long track is kept on this phone, so it
// carries on from there next time.
//
// The file is decrypted only into the app's own temp folder (web: memory)
// and removed when the next track loads or the player closes.
import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:path_provider/path_provider.dart';

import 'backend.dart';

/// One song or audio file in the play list.
class Track {
  const Track({required this.roomId, required this.msgId, required this.name, this.size});
  final String roomId;
  final String msgId;

  /// File name as sent ("아이유 - 밤편지.mp3").
  final String name;
  final int? size;

  String get _bare => name.replaceFirst(RegExp(r'\.[A-Za-z0-9]{2,4}$'), '').replaceAll('_', ' ').trim();

  /// "Artist - Title" names split into the two; else the whole name.
  String get title {
    final i = _bare.indexOf(' - ');
    return i > 0 ? _bare.substring(i + 3).trim() : _bare;
  }

  String? get artist {
    final i = _bare.indexOf(' - ');
    return i > 0 ? _bare.substring(0, i).trim() : null;
  }

  static Track of(String roomId, Msg m) => Track(roomId: roomId, msgId: m.id, name: m.body ?? 'audio', size: m.size);
}

/// What actually makes the sound (tests swap in a fake).
abstract class AudioEngine {
  Future<Duration?> load(Uint8List bytes, String name);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration at);
  Future<void> setSpeed(double speed);
  Stream<Duration> get position;
  Stream<bool> get playing;

  /// Fires when a track plays to its end.
  Stream<void> get ended;
  Future<void> dispose();
}

/// Sound type from the file's first bytes, else its name.
String audioMime(Uint8List b, String name) {
  bool at(int i, List<int> sig) => b.length > i + sig.length && _eq(b, i, sig);
  if (at(0, const [0x52, 0x49, 0x46, 0x46])) return 'audio/wav';
  if (at(0, const [0x49, 0x44, 0x33]) || (b.length > 2 && b[0] == 0xFF && (b[1] & 0xE0) == 0xE0)) return 'audio/mpeg';
  if (at(0, const [0x4F, 0x67, 0x67, 0x53])) return 'audio/ogg';
  if (at(0, const [0x66, 0x4C, 0x61, 0x43])) return 'audio/flac';
  if (at(0, const [0x1A, 0x45, 0xDF, 0xA3])) return 'audio/webm';
  if (at(4, const [0x66, 0x74, 0x79, 0x70])) return 'audio/mp4';
  final ext = name.split('.').last.toLowerCase();
  return switch (ext) {
    'mp3' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'ogg' || 'opus' => 'audio/ogg',
    'flac' => 'audio/flac',
    'aac' => 'audio/aac',
    _ => 'audio/mp4',
  };
}

bool _eq(Uint8List b, int i, List<int> sig) {
  for (var k = 0; k < sig.length; k++) {
    if (b[i + k] != sig[k]) return false;
  }
  return true;
}

class JustAudioEngine implements AudioEngine {
  final _p = ja.AudioPlayer();
  File? _file;
  final _ended = StreamController<void>.broadcast();
  StreamSubscription<ja.PlayerState>? _sub;

  JustAudioEngine() {
    _sub = _p.playerStateStream.listen((s) {
      if (s.processingState == ja.ProcessingState.completed) _ended.add(null);
    });
  }

  @override
  Future<Duration?> load(Uint8List bytes, String name) async {
    await _drop();
    final mime = audioMime(bytes, name);
    if (kIsWeb) return _p.setAudioSource(ja.AudioSource.uri(Uri.dataFromBytes(bytes, mimeType: mime)));
    final dir = await getTemporaryDirectory();
    final ext = switch (mime) {
      'audio/wav' => 'wav',
      'audio/mpeg' => 'mp3',
      'audio/ogg' => 'ogg',
      'audio/flac' => 'flac',
      'audio/webm' => 'webm',
      'audio/aac' => 'aac',
      _ => 'm4a',
    };
    final f = File('${dir.path}/dock_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await f.writeAsBytes(bytes, flush: true);
    _file = f;
    return _p.setFilePath(f.path);
  }

  Future<void> _drop() async {
    final f = _file;
    _file = null;
    if (f != null && await f.exists()) await f.delete().catchError((_) => f);
  }

  @override
  Future<void> play() async => unawaited(_p.play());
  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> seek(Duration at) => _p.seek(at);
  @override
  Future<void> setSpeed(double speed) => _p.setSpeed(speed);
  @override
  Stream<Duration> get position => _p.positionStream;
  @override
  Stream<bool> get playing => _p.playerStateStream.map((s) => s.playing && s.processingState != ja.ProcessingState.completed);
  @override
  Stream<void> get ended => _ended.stream;

  @override
  Future<void> dispose() async {
    await _sub?.cancel();
    await _ended.close();
    await _p.dispose();
    await _drop();
  }
}

enum Repeat { off, all, one }

class AudioDock extends ChangeNotifier {
  AudioDock._();
  static final AudioDock instance = AudioDock._();

  /// Tests swap this for a fake.
  static AudioEngine Function() makeEngine = JustAudioEngine.new;

  /// Playback speeds offered when holding the speed button.
  static const speeds = [0.5, 1.0, 1.25, 1.5, 2.0, 2.5];

  /// Tracks at least this long remember where you stopped.
  static const rememberFrom = Duration(minutes: 1);

  AudioEngine? _engine;
  final _subs = <StreamSubscription<Object?>>[];

  List<Track> queue = const [];
  int index = 0;
  bool playing = false, loading = false;
  Duration position = Duration.zero;
  Duration? duration;
  double speed = 1;
  Repeat repeat = Repeat.off;

  /// Name of the chat the list came from (shown in the player).
  String chatName = '';

  /// How the dock reads files and keeps settings (set on [start]).
  Future<List<int>> Function(String roomId, String msgId)? _download;
  String Function(String key)? _read;
  Future<void> Function(String key, String value)? _write;
  DateTime _savedAt = DateTime.fromMillisecondsSinceEpoch(0);

  Track? get current => queue.isEmpty ? null : queue[index];
  bool get active => queue.isNotEmpty;
  bool isCurrent(String msgId) => current?.msgId == msgId;

  static String posKey(String msgId) => 'audio_at:$msgId';

  /// Plays [list] from [at]: the chat's songs become the play list.
  Future<void> start({
    required List<Track> list,
    required int at,
    required String chatName,
    required Future<List<int>> Function(String roomId, String msgId) download,
    required String Function(String key) read,
    required Future<void> Function(String key, String value) write,
    double speed = 1,
  }) async {
    _download = download;
    _read = read;
    _write = write;
    this.chatName = chatName;
    this.speed = speed;
    queue = List.unmodifiable(list);
    index = at.clamp(0, list.length - 1);
    await _load(play: true);
  }

  AudioEngine _make() {
    final e = _engine;
    if (e != null) return e;
    final n = _engine = makeEngine();
    _subs.add(
      n.position.listen((d) {
        position = d;
        if (playing && DateTime.now().difference(_savedAt) > const Duration(seconds: 10)) unawaited(_savePos());
        notifyListeners();
      }),
    );
    _subs.add(
      n.playing.listen((v) {
        if (playing && !v) unawaited(_savePos());
        playing = v;
        notifyListeners();
      }),
    );
    _subs.add(n.ended.listen((_) => unawaited(_ended())));
    return n;
  }

  Future<void> _load({required bool play}) async {
    final t = current;
    final dl = _download;
    if (t == null || dl == null) return;
    final e = _make();
    loading = true;
    position = Duration.zero;
    duration = null;
    notifyListeners();
    try {
      final bytes = Uint8List.fromList(await dl(t.roomId, t.msgId));
      if (current?.msgId != t.msgId) return; // skipped while loading
      duration = await e.load(bytes, t.name);
      await e.setSpeed(speed);
      // Carry on where I stopped (not in the last few seconds).
      final saved = int.tryParse(_read?.call(posKey(t.msgId)) ?? '') ?? 0;
      final len = duration ?? Duration.zero;
      if (saved > 5000 && len >= rememberFrom && saved < len.inMilliseconds - 5000) {
        position = Duration(milliseconds: saved);
        await e.seek(position);
      }
    } catch (_) {
      loading = false;
      notifyListeners();
      return;
    }
    loading = false;
    notifyListeners();
    if (play) await e.play();
  }

  Future<void> _savePos() async {
    final t = current;
    final w = _write;
    final len = duration;
    if (t == null || w == null || len == null || len < rememberFrom) return;
    _savedAt = DateTime.now();
    // Finished (or almost): start from the top next time.
    final ms = position.inMilliseconds > len.inMilliseconds - 5000 ? 0 : position.inMilliseconds;
    await w(posKey(t.msgId), ms == 0 ? '' : '$ms');
  }

  Future<void> _ended() async {
    final t = current;
    if (t != null && _write != null) await _write!(posKey(t.msgId), '');
    if (repeat == Repeat.one) {
      await _engine?.seek(Duration.zero);
      await _engine?.play();
    } else if (index < queue.length - 1) {
      index++;
      await _load(play: true);
    } else if (repeat == Repeat.all && queue.isNotEmpty) {
      index = 0;
      await _load(play: true);
    } else {
      await _engine?.pause();
      await _engine?.seek(Duration.zero);
      position = Duration.zero;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    final e = _engine;
    if (e == null) return;
    playing ? await e.pause() : await e.play();
  }

  /// Plays track [i] of the list.
  Future<void> jump(int i) async {
    if (i < 0 || i >= queue.length) return;
    await _savePos();
    index = i;
    await _load(play: true);
  }

  /// Back to the start of this track, or the one before when near the start.
  Future<void> previous() async {
    if (position > const Duration(seconds: 3) || index == 0) return seek(Duration.zero);
    return jump(index - 1);
  }

  Future<void> next() async {
    if (index < queue.length - 1) return jump(index + 1);
    if (repeat == Repeat.all) return jump(0);
  }

  Future<void> seek(Duration at) async {
    position = at;
    notifyListeners();
    await _engine?.seek(at);
  }

  Future<void> setSpeed(double v) async {
    speed = v;
    notifyListeners();
    await _engine?.setSpeed(v);
  }

  /// 1× → 1.5× → 2× → 1× (other speeds go back to 1×).
  double get nextSpeed => speed == 1 ? 1.5 : (speed == 1.5 ? 2 : 1);

  void cycleRepeat() {
    repeat = Repeat.values[(repeat.index + 1) % Repeat.values.length];
    notifyListeners();
  }

  /// Stops and hides the mini bar (keeps where I stopped).
  Future<void> close() async {
    await _savePos();
    final e = _engine;
    _engine = null;
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    queue = const [];
    index = 0;
    playing = loading = false;
    position = Duration.zero;
    duration = null;
    notifyListeners();
    await e?.dispose();
  }

  /// Tests: back to a clean state.
  @visibleForTesting
  Future<void> reset() async {
    await close();
    speed = 1;
    repeat = Repeat.off;
  }
}
