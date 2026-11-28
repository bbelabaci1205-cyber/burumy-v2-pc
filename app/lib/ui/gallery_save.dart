// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 갤러리에 저장 (v1 parity batch 3, 2026-11-27): a photo or video from a
// chat goes to the phone's photo library. Phone apps only. The decrypted
// copy lives in the app's temp folder just long enough to hand it over.
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/downloads.dart';
import '../core/media_tags.dart';

/// Tests swap this (no photo library there).
Future<void> Function(Uint8List bytes, String name, bool video) galleryWriter = _write;

Future<void> _write(Uint8List bytes, String name, bool video) async {
  if (!await Gal.hasPermission()) await Gal.requestPermission();
  if (!video) return Gal.putImageBytes(bytes, name: name);
  final dir = await getTemporaryDirectory();
  final ext = name.toLowerCase().endsWith('.mov') ? 'mov' : 'mp4';
  final f = File('${dir.path}/gallery-${DateTime.now().microsecondsSinceEpoch}.$ext');
  await f.writeAsBytes(bytes, flush: true);
  try {
    await Gal.putVideo(f.path);
  } finally {
    await f.delete().then((_) {}, onError: (_) {});
  }
}

/// 갤러리 자동 저장 (Telegram tip 352): a photo or video that just finished
/// downloading goes to Photos when Settings > Data says so for its chat
/// type. Skipped in 공유 비활성화 chats, for view-once, on the web, and
/// for media saved before (pref asaved, last 500).
Future<void> autoSaveToGallery(AppState s, String roomId, Msg m, List<int> bytes) async {
  if (kIsWeb || !s.autoSaves(roomId, m) || bytes.isEmpty) return;
  final done = s.pref('asaved', '').split(',');
  if (done.contains(m.id)) return;
  final cfg = await s.backend.roomConfig(roomId).catchError((_) => <String, dynamic>{});
  if (cfg['protect'] == true) return;
  final base = MediaTags.plain(m.body ?? 'burumy').split('.').first;
  await galleryWriter(Uint8List.fromList(bytes), base.isEmpty ? 'burumy' : base, m.kind == 'video');
  final keep = [...done.where((x) => x.isNotEmpty), m.id];
  await s.setPref('asaved', keep.skip(keep.length > 500 ? keep.length - 500 : 0).join(','));
}

Future<bool> saveToGallery(Backend b, String roomId, Msg m) async {
  if (m.viewOnce) return false;
  try {
    final bytes = Uint8List.fromList(await b.downloadFile(roomId, m.fileId));
    final base = MediaTags.plain(m.body ?? 'burumy').split('.').first;
    await galleryWriter(bytes, base.isEmpty ? 'burumy' : base, m.kind == 'video');
    return true;
  } catch (_) {
    return false;
  }
}
