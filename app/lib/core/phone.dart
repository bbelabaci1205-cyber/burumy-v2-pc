// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Our own bridge to the phone's built-in features (no outside plugin):
// where I am right now, and the newest photos and videos for the "+" sheet.
// The native halves are MainActivity/PhoneChannel.kt (Android) and
// AppDelegate.swift (iPhone); the web uses the browser's own location.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'phone_web_stub.dart' if (dart.library.js_interop) 'phone_web.dart' as web;

class GeoFix {
  const GeoFix(this.lat, this.lon, this.accuracy);
  final double lat, lon;

  /// Metres (null = unknown).
  final double? accuracy;
}

/// One photo or video on this phone (only a small picture until chosen).
class PhoneMedia {
  const PhoneMedia(this.id, this.thumb, {this.video = false, this.duration});
  final String id;
  final Uint8List thumb;
  final bool video;
  final Duration? duration;
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
  static Future<(String, Uint8List)?> Function(String id)? debugLoad;

  /// Web: [top, bottom] edges the iPhone uses (status bar, home indicator);
  /// Flutter reports them itself in the phone apps.
  static (double, double) webSafeInsets() => kIsWeb ? web.safeInsets() : (0, 0);

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
  static Future<List<PhoneMedia>?> recent({int limit = 60}) async {
    if (debugRecent != null) return debugRecent!(limit);
    if (kIsWeb) return null;
    try {
      final list = await _ch.invokeListMethod<Object?>('recent', {'limit': limit});
      if (list == null) return null;
      return [
        for (final x in list.cast<Map<Object?, Object?>>())
          PhoneMedia(
            x['id'] as String,
            x['thumb'] as Uint8List,
            video: x['video'] == true,
            duration: x['ms'] == null ? null : Duration(milliseconds: (x['ms'] as num).toInt()),
          ),
      ];
    } catch (_) {
      return null;
    }
  }

  /// The whole file for one chosen item: (name, bytes).
  static Future<(String, Uint8List)?> load(String id) async {
    if (debugLoad != null) return debugLoad!(id);
    try {
      final m = await _ch.invokeMapMethod<String, Object?>('load', {'id': id});
      if (m == null) return null;
      return (m['name'] as String, m['bytes'] as Uint8List);
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

  /// This app's page in the phone's Settings (to allow location / photos).
  static Future<void> openSettings() async {
    try {
      await _ch.invokeMethod('settings');
    } catch (_) {}
  }
}
