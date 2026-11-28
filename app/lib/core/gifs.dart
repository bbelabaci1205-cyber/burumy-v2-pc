// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 GIF (Telegram tip 558, our way): GIFs I saved from chats, kept for me
// and sent again from the GIF tab, with words under them (설명), at a set
// time (예약) or changed first (글씨·그림·자르기).
//
// A saved GIF is encrypted on this phone and uploaded as ciphertext
// (Backend.uploadSecret); my settings keep only its key. The server never
// sees which GIFs I keep.
//
// Changing a GIF never makes a new one: the original goes as it is, the
// words and drawing go as one see-through picture (a "layer", encrypted,
// its key in a hidden note of kind [Gifs.layerKind]) and the cut as marks
// in the encrypted file name (see MediaTags). The app draws them over it.
// A layer counts only from the person who sent the GIF.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'app_state.dart';
import 'backend.dart';
import 'media_tags.dart';

class SavedGif {
  const SavedGif({required this.id, required this.f, required this.name, required this.mime, this.from = 0, this.to = -1, this.layer});

  /// First 12 hex of the GIF's sha256 (the same GIF is kept once).
  final String id;

  /// Key of the encrypted upload.
  final String f;
  final String name, mime;

  /// The part that plays, ms (to -1 = to the end).
  final int from, to;

  /// Key of an encrypted words/drawing layer kept with it.
  final String? layer;

  bool get isVideo => mime.startsWith('video/');

  Map<String, Object?> toJson() => {'id': id, 'f': f, 'n': name, 'm': mime, if (from > 0) 's': from, if (to >= 0) 'e': to, if (layer != null) 'o': layer};

  static SavedGif? fromJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'], f = j['f'];
    if (id is! String || f is! String) return null;
    return SavedGif(
      id: id,
      f: f,
      name: '${j['n'] ?? 'gif.gif'}',
      mime: '${j['m'] ?? 'image/gif'}',
      from: j['s'] is int ? j['s'] as int : 0,
      to: j['e'] is int ? j['e'] as int : -1,
      layer: j['o'] is String ? j['o'] as String : null,
    );
  }
}

class Gifs {
  const Gifs._();

  /// Hidden note with a layer's key: {id (12 hex), f}.
  static const layerKind = 'gif_layer';

  static const max = 200;

  /// Biggest GIF kept (Telegram keeps GIFs small too).
  static const maxBytes = 20 * 1024 * 1024;

  /// Biggest layer picture accepted.
  static const maxLayer = 2 * 1024 * 1024;

  /// Something changed (saved, removed, a layer arrived).
  static final changed = StreamController<void>.broadcast();

  static final _bytes = <String, Uint8List>{};
  static final _layers = <String, Uint8List>{};

  static List<SavedGif> mine(AppState s) {
    try {
      return [for (final x in jsonDecode(s.pref('my_gifs', '[]')) as List) ?SavedGif.fromJson(x)];
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _setMine(AppState s, List<SavedGif> v) async {
    await s.setPref('my_gifs', jsonEncode([for (final g in v.take(max)) g.toJson()]));
    changed.add(null);
  }

  static String idOf(List<int> bytes) => sha256.convert(bytes).toString().substring(0, 12);

  static bool isSaved(AppState s, String id) => mine(s).any((g) => g.id == id);

  /// A GIF message: a looping silent video, or a .gif picture.
  static bool isGifMsg(Msg m) {
    if (m.viewOnce || m.body == null) return false;
    if (m.kind == 'video') return MediaTags.of(m.body).gif;
    return m.kind == 'image' && MediaTags.plain(m.body).toLowerCase().endsWith('.gif');
  }

  /// Keeps [bytes] in 내 GIF (newest first). False when too big.
  static Future<bool> save(AppState s, List<int> bytes, {required String name, required String mime, int from = 0, int to = -1, String? layer}) async {
    if (bytes.length > maxBytes) return false;
    final id = idOf(bytes);
    final have = mine(s);
    final old = have.where((g) => g.id == id).firstOrNull;
    final f = old?.f ?? await s.backend.uploadSecret(bytes);
    _bytes[id] = Uint8List.fromList(bytes);
    final g = SavedGif(id: id, f: f, name: MediaTags.plain(name), mime: mime, from: from, to: to, layer: layer ?? old?.layer);
    await _setMine(s, [g, ...have.where((x) => x.id != id)]);
    return true;
  }

  /// Saves the GIF of a chat message (with its cut and layer).
  static Future<bool> saveMsg(AppState s, String roomId, Msg m) async {
    final bytes = await s.backend.downloadFile(roomId, m.id);
    final tags = MediaTags.of(m.body);
    final name = MediaTags.plain(m.body);
    final layerId = tags.layer;
    final layer = layerId == null ? null : _layerRefs(s)[layerId];
    return save(
      s,
      bytes,
      name: name,
      mime: m.kind == 'video' ? 'video/mp4' : 'image/gif',
      from: tags.from,
      to: tags.to,
      layer: layer != null && layer['from'] == m.sender ? layer['f'] as String? : null,
    );
  }

  static Future<void> remove(AppState s, String id) => _setMine(s, mine(s).where((g) => g.id != id).toList());

  /// Moves [id] to the front (just sent).
  static Future<void> bump(AppState s, String id) async {
    final all = mine(s);
    final g = all.where((x) => x.id == id).firstOrNull;
    if (g == null || all.first.id == id) return;
    await _setMine(s, [g, ...all.where((x) => x.id != id)]);
  }

  static Future<Uint8List> bytesOf(AppState s, SavedGif g) async {
    final have = _bytes[g.id];
    if (have != null) return have;
    final b = Uint8List.fromList(await s.backend.downloadSecret(g.f));
    _bytes[g.id] = b;
    return b;
  }

  static Future<Uint8List?> savedLayer(AppState s, SavedGif g) async {
    final f = g.layer;
    if (f == null) return null;
    final have = _layers['f:$f'];
    if (have != null) return have;
    final b = Uint8List.fromList(await s.backend.downloadSecret(f));
    if (b.length > maxLayer) return null;
    return _layers['f:$f'] = b;
  }

  // ------------------------------------------------------------ sending

  static String _newId() {
    final r = Random.secure();
    return [for (var i = 0; i < 6; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  /// Sends a saved GIF. [layer] = a new words/drawing picture (null keeps
  /// the one saved with it); [from]/[to] = the part that plays.
  static Future<void> send(AppState s, String roomId, SavedGif g, {String caption = '', Uint8List? layer, int? from, int? to}) async {
    final b = s.backend;
    final bytes = await bytesOf(s, g);
    String? layerId;
    String? layerF = layer == null ? g.layer : null;
    if (layer != null && layer.length <= maxLayer) layerF = await b.uploadSecret(layer);
    if (layerF != null) {
      layerId = _newId();
      if (layer != null) _layers[layerId] = layer;
      await b.sendSignal(roomId, layerKind, {'id': layerId, 'f': layerF});
      await _keepRef(s, layerId, layerF, b.userId ?? '');
    }
    final tags = MediaTags(gif: g.isVideo, layer: layerId, from: g.isVideo ? (from ?? g.from) : 0, to: g.isVideo ? (to ?? g.to) : -1);
    await b.sendFile(roomId, name: tags.apply(g.name), mime: g.mime, bytes: bytes, caption: caption);
    await bump(s, g.id);
  }

  /// A scheduled GIF ({gif: SavedGif json, l: layer key, s, e}).
  static Future<void> sendScheduled(AppState s, String roomId, Map<String, dynamic> m) async {
    final g = SavedGif.fromJson(m['gif']);
    if (g == null) return;
    final l = m['l'];
    final withLayer = l is String ? SavedGif(id: g.id, f: g.f, name: g.name, mime: g.mime, from: g.from, to: g.to, layer: l) : g;
    await send(s, roomId, withLayer, caption: '${m['text'] ?? ''}', from: m['s'] as int?, to: m['e'] as int?);
  }

  /// Puts a GIF in the 예약 list (the layer is uploaded now).
  static Future<void> schedule(
    AppState s,
    String roomId,
    SavedGif g,
    DateTime at, {
    String repeat = '',
    String caption = '',
    Uint8List? layer,
    int? from,
    int? to,
  }) async {
    final l = layer == null ? g.layer : await s.backend.uploadSecret(layer);
    await s.setScheduled([
      ...s.scheduled,
      {
        'id': '${DateTime.now().microsecondsSinceEpoch}',
        'room': roomId,
        'text': caption,
        'at': at.millisecondsSinceEpoch,
        'quiet': false,
        if (repeat.isNotEmpty) 'repeat': repeat,
        'gif': g.toJson(),
        'l': ?l,
        's': ?from,
        'e': ?to,
      },
    ]);
  }

  // ------------------------------------------------------------ layers

  static Map<String, dynamic> _layerRefs(AppState s) {
    try {
      return Map<String, dynamic>.from(jsonDecode(s.pref('gif_layers', '{}')) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _keepRef(AppState s, String id, String f, String from) async {
    final all = _layerRefs(s)..remove(id);
    final keep = <String, dynamic>{
      id: {'f': f, 'from': from},
      ...all,
    };
    await s.setPref('gif_layers', jsonEncode(Map.fromEntries(keep.entries.take(400))));
  }

  static Future<void> onLayer(AppState s, Signal sig) async {
    final id = sig.data['id'], f = sig.data['f'];
    if (id is! String || f is! String || !RegExp(r'^[0-9a-f]{12}$').hasMatch(id)) return;
    // The first note for an id wins (a later one cannot swap the picture).
    if (_layerRefs(s).containsKey(id)) return;
    await _keepRef(s, id, f, sig.sender);
    changed.add(null);
  }

  /// The layer [id] of a GIF sent by [sender] (null: none, not yet, or
  /// sent by someone else).
  static Future<Uint8List?> layerOf(AppState s, String id, String sender) async {
    final ref = _layerRefs(s)[id];
    if (ref is! Map || ref['from'] != sender) return null;
    final have = _layers[id];
    if (have != null) return have;
    final b = Uint8List.fromList(await s.backend.downloadSecret('${ref['f']}'));
    if (b.length > maxLayer) return null;
    return _layers[id] = b;
  }
}
