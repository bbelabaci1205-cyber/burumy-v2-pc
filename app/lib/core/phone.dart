// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Our own bridge to the phone's built-in features (no outside plugin):
// where I am right now, and the newest photos and videos for the "+" sheet.
// The native halves are MainActivity/PhoneChannel.kt (Android) and
// AppDelegate.swift (iPhone); the web uses the browser's own location.
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ai_local.dart';
import 'phone_web_stub.dart' if (dart.library.js_interop) 'phone_web.dart' as web;

class GeoFix {
  const GeoFix(this.lat, this.lon, this.accuracy);
  final double lat, lon;

  /// Metres (null = unknown).
  final double? accuracy;
}

/// One photo or video on this phone (only a small picture until chosen).
class PhoneMedia {
  const PhoneMedia(this.id, this.thumb, {this.video = false, this.duration, this.live = false});
  final String id;
  final Uint8List thumb;
  final bool video;
  final Duration? duration;

  /// 움직이는 사진 (iPhone Live Photo / Android Motion Photo).
  final bool live;
}

/// One gallery album (Telegram tip 324): a fixed kind ("recents",
/// "favorites", "videos", "screenshots", "selfies", "live") or the phone's
/// own album ([name] set), and how many photos and videos it holds.
class PhoneAlbum {
  const PhoneAlbum(this.id, this.count, {this.name});
  final String id;
  final int count;
  final String? name;
  static const recentsId = 'recents';
}

/// A chosen photo/video. [clip] is the moving part of a Live Photo (MP4).
class PhoneFile {
  const PhoneFile(this.name, this.bytes, {this.clip});
  final String name;
  final Uint8List bytes;
  final Uint8List? clip;
}

/// "denied" (no permission), "off" (location turned off), "unavailable".
class PhoneError implements Exception {
  const PhoneError(this.code);
  final String code;
  @override
  String toString() => 'PhoneError($code)';
}

class Phone {
  static const _ch = MethodChannel('app.burumy/phone');

  /// Tests replace the phone.
  static Future<GeoFix> Function()? debugLocation;
  static Future<List<PhoneMedia>?> Function(int limit)? debugRecent;
  static Future<List<PhoneMedia>?> Function(int limit, String album)? debugAlbumRecent;
  static Future<List<PhoneAlbum>?> Function()? debugAlbums;

  /// The gallery's albums with counts (null: can't show them here).
  static Future<List<PhoneAlbum>?> albums() async {
    if (debugAlbums != null) return debugAlbums!();
    if (kIsWeb) return null;
    try {
      final list = await _ch.invokeListMethod<Object?>('albums');
      return [
        for (final x in (list ?? const []).cast<Map<Object?, Object?>>())
          PhoneAlbum(x['id'] as String, (x['count'] as num?)?.toInt() ?? 0, name: x['name'] as String?),
      ];
    } catch (_) {
      return null;
    }
  }

  static Future<(String, Uint8List)?> Function(String id)? debugLoad;

  /// Web: [top, bottom] edges the iPhone uses (status bar, home indicator);
  /// Flutter reports them itself in the phone apps.
  static (double, double) webSafeInsets() => kIsWeb ? web.safeInsets() : (0, 0);

  /// Web: the page colour behind the app, so Safari's top edge shows plain
  /// white (black in dark mode) instead of a grey haze.
  static void webPageColor(bool dark) {
    if (kIsWeb) web.pageColor(dark ? '#000000' : '#ffffff');
  }

  static Future<GeoFix> location() async {
    if (debugLocation != null) return debugLocation!();
    if (kIsWeb) return web.location();
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('location');
      if (m == null) throw const PhoneError('unavailable');
      return GeoFix((m['lat'] as num).toDouble(), (m['lon'] as num).toDouble(), (m['accuracy'] as num?)?.toDouble());
    } on PlatformException catch (e) {
      throw PhoneError(e.code);
    } on MissingPluginException {
      throw const PhoneError('unavailable');
    }
  }

  /// The newest photos and videos, newest first. null = can't show them
  /// here (web, no permission): the sheet falls back to the phone's picker.
  /// [album]: only that album (null = 최근 항목).
  static Future<List<PhoneMedia>?> recent({int limit = 60, String? album}) async {
    if (album != null && debugAlbumRecent != null) return debugAlbumRecent!(limit, album);
    if (debugRecent != null) return debugRecent!(limit);
    if (kIsWeb) return null;
    try {
      final list = await _ch.invokeListMethod<Object?>('recent', {'limit': limit, 'album': ?album});
      if (list == null) return null;
      return [
        for (final x in list.cast<Map<Object?, Object?>>())
          PhoneMedia(
            x['id'] as String,
            x['thumb'] as Uint8List,
            video: x['video'] == true,
            duration: x['ms'] == null ? null : Duration(milliseconds: (x['ms'] as num).toInt()),
            live: x['live'] == true,
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  /// The whole file for one chosen item: (name, bytes).
  static Future<(String, Uint8List)?> load(String id) async {
    final f = await loadFile(id);
    return f == null ? null : (f.name, f.bytes);
  }

  /// Same, with the clip of a Live Photo (iPhone: the paired video, made
  /// into an MP4 on the phone; Android Motion Photos carry it inside the
  /// JPEG and are split in Dart).
  static Future<PhoneFile?> Function(String id)? debugLoadFile;
  static Future<PhoneFile?> loadFile(String id) async {
    if (debugLoadFile != null) return debugLoadFile!(id);
    if (debugLoad != null) {
      final r = await debugLoad!(id);
      return r == null ? null : PhoneFile(r.$1, r.$2);
    }
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('load', {'id': id});
      if (m == null) return null;
      return PhoneFile(m['name'] as String, m['bytes'] as Uint8List, clip: m['clip'] as Uint8List?);
    } catch (_) {
      return null;
    }
  }

  /// 사진 속 글자 (TelegramTips 317): lines of text found in a photo, read
  /// on this phone (iPhone: Apple Vision Live Text). null = this phone
  /// can't (Android, web): the button is then not shown.
  static Future<List<TextLine>?> Function(Uint8List photo)? debugReadText;
  static bool get canReadText => debugReadText != null || (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);
  static Future<List<TextLine>?> readText(Uint8List photo) async {
    if (debugReadText != null) return debugReadText!(photo);
    if (!canReadText) return null;
    try {
      final r = await _ch.invokeListMethod<Map<Object?, Object?>>('readText', {'bytes': photo});
      if (r == null) return null;
      return [
        for (final m in r)
          TextLine(
            m['text'] as String? ?? '',
            Rect.fromLTWH((m['x'] as num).toDouble(), (m['y'] as num).toDouble(), (m['w'] as num).toDouble(), (m['h'] as num).toDouble()),
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  /// 소리 끄기 (Telegram tip 77): the same video without its sound track,
  /// copied on this phone without re-encoding (Android MediaMuxer, iPhone
  /// AVAssetExportSession passthrough). null = can't here (web): the video
  /// is then sent as is and every Burumy app plays it silent.
  static Future<Uint8List?> Function(Uint8List video)? debugStripAudio;
  static Future<Uint8List?> stripAudio(Uint8List video, String name) async {
    if (debugStripAudio != null) return debugStripAudio!(video);
    if (kIsWeb) return null;
    try {
      return await _ch.invokeMethod<Uint8List>('stripAudio', {'bytes': video, 'mov': name.toLowerCase().endsWith('.mov')});
    } catch (_) {
      return null;
    }
  }

  /// 동영상 자르기·회전 (Telegram tip 56): small pictures from along the
  /// video for the editor's strip ([count] of them, evenly spread, each
  /// about [height] px tall). Android MediaMetadataRetriever, iPhone
  /// AVAssetImageGenerator, the web a hidden <video> drawn on a canvas.
  /// Empty = can't here.
  static Future<List<Uint8List>> Function(Uint8List video, int count)? debugVideoFrames;
  static Future<List<Uint8List>> videoFrames(Uint8List video, String name, {int count = 10, int height = 96}) async {
    if (debugVideoFrames != null) return debugVideoFrames!(video, count);
    try {
      if (kIsWeb) return await web.videoFrames(video, name.toLowerCase().endsWith('.mov') ? 'video/quicktime' : 'video/mp4', count, height);
      final list = await _ch.invokeListMethod<Uint8List>('videoFrames', {
        'bytes': video,
        'count': count,
        'height': height,
        'mov': name.toLowerCase().endsWith('.mov'),
      });
      return list ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// Can this device make the cut / turned video? (phones; tests and the
  /// look-only web demo set [debugEditVideo]).
  static bool get canEditVideo =>
      debugEditVideo != null || (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android));

  /// The new video: only [start, end) kept, turned [turns] quarter turns to
  /// the left and mirrored when [flip] (Android Media3 Transformer, iPhone
  /// AVAssetExportSession), H.264 MP4. Made on this phone before it is
  /// encrypted, so the parts cut off never leave it. null = it failed (the
  /// chat then sends nothing rather than the uncut video).
  static Future<Uint8List?> Function(Uint8List video, Map<String, Object> edit)? debugEditVideo;
  static Future<Uint8List?> editVideo(Uint8List video, String name, Map<String, Object> edit) async {
    if (debugEditVideo != null) return debugEditVideo!(video, edit);
    if (!canEditVideo) return null;
    try {
      return await _ch.invokeMethod<Uint8List>('editVideo', {'bytes': video, 'mov': name.toLowerCase().endsWith('.mov'), ...edit});
    } catch (_) {
      return null;
    }
  }

  /// 문서 스캔: the phone's own document camera (iPhone VisionKit, Android
  /// Google document scanner) finds the page edges, flattens every page and
  /// gives one PDF back. Runs on the phone; null = cancelled or can't here.
  static Future<Uint8List?> Function()? debugScan;
  static bool get canScan => debugScan != null || (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android));
  static Future<Uint8List?> scanDocument() async {
    if (debugScan != null) return debugScan!();
    if (!canScan) return null;
    try {
      return await _ch.invokeMethod<Uint8List>('scanDocument');
    } catch (_) {
      return null;
    }
  }

  /// Battery left in % (null = can't tell, e.g. on the web).
  static Future<int?> Function()? debugBattery;
  static Future<int?> battery() async {
    if (debugBattery != null) return debugBattery!();
    if (kIsWeb) return null;
    try {
      return await _ch.invokeMethod<int>('battery');
    } catch (_) {
      return null;
    }
  }

  /// "wifi", "cellular", "none" or "unknown" (web, older phones).
  static Future<String> Function()? debugNetwork;
  static Future<String> network() async {
    if (debugNetwork != null) return debugNetwork!();
    if (kIsWeb) return 'unknown';
    try {
      return await _ch.invokeMethod<String>('network') ?? 'unknown';
    } catch (_) {
      return 'unknown';
    }
  }

  /// 스티커 만들기: the person or thing in a photo, cut out on this phone
  /// (iPhone: Vision, iOS 17+; Android: ML Kit subject segmentation). A PNG
  /// with a see-through background, or null where the phone can't (web,
  /// older phones, nothing found). The photo never leaves the phone.
  static Future<Uint8List?> Function(Uint8List photo)? debugCutout;
  static Future<Uint8List?> cutout(Uint8List photo) async {
    if (debugCutout != null) return debugCutout!(photo);
    if (kIsWeb) return null;
    // Android's cut-out is Google ML Kit (18+ only, core/ai_age.dart).
    if (LocalAi.blocked()) return null;
    try {
      return await _ch.invokeMethod<Uint8List>('cutout', {'bytes': photo});
    } catch (_) {
      return null;
    }
  }

  /// The phone's share sheet with a picture and/or words (iPhone/Android
  /// share sheet, the browser's on the web). "shared", "saved", "copied" or
  /// "failed".
  static Future<String> Function(String? text, Uint8List? bytes)? debugShare;
  static Future<String> share({String? text, Uint8List? bytes, String name = 'image.png', String mime = 'image/png', bool saveOnly = false}) async {
    if (debugShare != null) return debugShare!(text, bytes);
    if (kIsWeb) return web.share(text, bytes, name, mime, saveOnly: saveOnly);
    try {
      final ok = await _ch.invokeMethod<bool>('share', {'text': text, 'bytes': bytes, 'name': name, 'mime': mime});
      return ok == true ? 'shared' : 'failed';
    } catch (_) {
      return 'failed';
    }
  }

  /// Puts a picture into the phone's Photos (web: downloads it).
  static Future<bool> Function(Uint8List bytes)? debugSaveImage;
  static Future<bool> saveImage(Uint8List bytes, {String name = 'image.png'}) async {
    if (debugSaveImage != null) return debugSaveImage!(bytes);
    if (kIsWeb) return await web.share(null, bytes, name, 'image/png', saveOnly: true) != 'failed';
    try {
      return await _ch.invokeMethod<bool>('saveImage', {'bytes': bytes, 'name': name}) == true;
    } catch (_) {
      return false;
    }
  }

  /// This app's page in the phone's Settings (to allow location / photos).
  static Future<void> openSettings() async {
    try {
      await _ch.invokeMethod('settings');
    } catch (_) {}
  }
}

/// One line of text in a photo; [box] is in parts of the picture (0-1).
class TextLine {
  const TextLine(this.text, this.box);
  final String text;
  final Rect box;
}
