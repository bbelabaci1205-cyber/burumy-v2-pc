// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기, step 2: everything read from the export is
// encrypted on this phone and sent as one import card (engine/src/import.rs
// explains the shape). Photos and files go first (one encrypted upload
// each, with a small picture for photos), then the messages in parts.
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipEncoder;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

import 'backend.dart';
import 'chat_import.dart';

/// How far an import is (bytes, so the ring moves with big videos too).
class ImportProgress {
  const ImportProgress({required this.done, required this.total, required this.step, this.media = 0, this.mediaTotal = 0});
  final int done;
  final int total;

  /// media (photos and files), pack (messages), send (the card)
  final String step;
  final int media;
  final int mediaTotal;
  double get part => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);
}

class ImportCancelled implements Exception {
  const ImportCancelled();
}

/// What the person chose on the check screen.
class ImportChoice {
  const ImportChoice({required this.chat, required this.files, this.me, this.peer, this.peerId, this.media = true, this.title});
  final ParsedChat chat;
  final ImportFiles files;

  /// Which name in the export is me / the other person of this 1:1
  /// (null = keep only the name).
  final String? me;
  final String? peer;
  final String? peerId;
  final bool media;

  /// Name shown on the card (the other app's chat name by default).
  final String? title;
}

/// Biggest single photo / file sent along (the engine's upload limit).
const importMaxFile = 50 * 1024 * 1024;

/// Messages per encrypted part (40 parts at most, see the engine).
int importPartSize(int n) {
  final s = (n / 40).ceil();
  return s < 5000 ? 5000 : (s > 10000 ? 10000 : s);
}

class ImportSender {
  ImportSender(this.b);
  final Backend b;
  bool _stop = false;

  /// Stops before the next upload; nothing is posted in the chat.
  void cancel() => _stop = true;

  void _check() {
    if (_stop) throw const ImportCancelled();
  }

  /// Sends the import into [roomId]. Returns how many messages went in.
  Future<int> send(String roomId, ImportChoice c, {required String myId, void Function(ImportProgress p)? onProgress}) async {
    final chat = c.chat;
    final items = chat.items.take(importMaxItems).toList();
    final people = chat.people;
    final who = {for (final (i, n) in people.indexed) n: i};
    final withMedia = c.media
        ? [
            for (final x in items)
              if (x.media != null && c.files.has(x.media!) && c.files.sizeOf(x.media!) <= importMaxFile) x,
          ]
        : const <ImportItem>[];
    final mediaBytes = withMedia.fold<int>(0, (a, x) => a + c.files.sizeOf(x.media!));
    final packGuess = items.length * 60 + 1;
    final total = mediaBytes + packGuess;
    var done = 0;
    var mediaDone = 0;
    void tell(String step) => onProgress?.call(ImportProgress(done: done, total: total, step: step, media: mediaDone, mediaTotal: withMedia.length));
    tell('media');

    // 1. Photos, videos, voice and files: encrypted here, one by one.
    final refs = <ImportItem, (Object, Object?)>{};
    for (final x in withMedia) {
      _check();
      final bytes = c.files.read(x.media!);
      final size = c.files.sizeOf(x.media!);
      if (bytes != null && bytes.isNotEmpty) {
        try {
          final f = jsonDecode(await b.uploadEncrypted(bytes)) as Object;
          Object? th;
          if (x.kind == 'image' && bytes.length <= 20 * 1024 * 1024) {
            final small = await importThumb(bytes);
            if (small != null) th = jsonDecode(await b.uploadEncrypted(small));
          }
          refs[x] = (f, th);
        } catch (_) {
          // One file that won't go keeps its place as "not brought in".
        }
      }
      done += size;
      mediaDone++;
      tell('media');
    }

    // 2. The messages, in parts.
    final index = <ImportItem, int>{for (final (i, x) in items.indexed) x: i};
    Map<String, Object?> wire(ImportItem x) {
      final r = refs[x];
      final media = const ['image', 'video', 'audio', 'file'].contains(x.kind);
      final k = media && r == null ? 'missing' : x.kind;
      final out = <String, Object?>{'t': x.time.millisecondsSinceEpoch, 'k': k, 'b': x.body};
      if (x.from.isNotEmpty && x.kind != 'system') out['p'] = who[x.from];
      if (k == 'missing') out['mk'] = media ? x.kind : (x.missingKind.isEmpty ? 'file' : x.missingKind);
      if (r != null) {
        final name = x.media!.split('/').last;
        out['f'] = r.$1;
        if (r.$2 != null) out['th'] = r.$2;
        out['m'] = ChatImport.mimeOf(name);
        out['n'] = x.kind == 'file' ? name : '';
        out['s'] = c.files.sizeOf(x.media!);
      }
      if (k == 'missing' && x.kind == 'file' && x.body.isEmpty && x.media != null) out['b'] = x.media!.split('/').last;
      if (x.replyTo != null && x.replyTo! < chat.items.length) {
        final to = index[chat.items[x.replyTo!]];
        if (to != null) out['r'] = to;
      }
      if (x.forwarded) out['fw'] = true;
      if (x.edited) out['e'] = true;
      return out;
    }

    final size = importPartSize(items.length);
    final parts = <Map<String, Object?>>[];
    for (var i = 0; i < items.length; i += size) {
      _check();
      final slice = items.sublist(i, i + size > items.length ? items.length : i + size);
      final body = <String, Object?>{
        'v': 1,
        if (i == 0) 'people': people,
        'items': [for (final x in slice) wire(x)],
      };
      final raw = utf8.encode(jsonEncode(body));
      final gz = kIsWeb ? GZipEncoder().encodeBytes(raw) : await _gzipOff(raw);
      tell('pack');
      final f = jsonDecode(await b.uploadEncrypted(gz)) as Object;
      parts.add({'file': f, 'n': slice.length});
      done += packGuess * slice.length ~/ (items.isEmpty ? 1 : items.length);
      tell('pack');
    }

    // 3. One encrypted card in the chat.
    _check();
    final whoIds = <String, String>{
      if (c.me != null && who[c.me] != null) '${who[c.me]}': myId,
      if (c.peer != null && c.peerId != null && who[c.peer] != null && c.peer != c.me) '${who[c.peer]}': c.peerId!,
    };
    tell('send');
    await b.createCard(roomId, 'import', {
      'app': chat.app.name,
      'title': (c.title ?? chat.title).trim(),
      'from': items.first.time.millisecondsSinceEpoch,
      'to': items.last.time.millisecondsSinceEpoch,
      'media': refs.length,
      'parts': parts,
      'who': whoIds,
    });
    done = total;
    tell('send');
    return items.length;
  }
}

/// A small JPEG (longest side 480) of a photo for the chat, or null.
Future<Uint8List?> importThumb(Uint8List bytes) async => kIsWeb ? _thumb(bytes) : _thumbOff(bytes);

Future<Uint8List?> _thumbOff(Uint8List bytes) => Isolate.run(() => _thumb(bytes));

Uint8List? _thumb(Uint8List bytes) {
  try {
    final im = img.decodeImage(bytes);
    if (im == null) return null;
    final small = im.width >= im.height
        ? img.copyResize(im, width: im.width > 480 ? 480 : im.width)
        : img.copyResize(im, height: im.height > 480 ? 480 : im.height);
    return img.encodeJpg(small, quality: 72);
  } catch (_) {
    return null;
  }
}

/// On another thread with only the bytes (see [importThumb]).
Future<List<int>> _gzipOff(List<int> raw) => Isolate.run(() => GZipEncoder().encodeBytes(raw));
