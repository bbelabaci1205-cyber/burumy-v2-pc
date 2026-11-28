// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Web: the browser's own location (it asks the person first).
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'phone.dart';

@JS('navigator.geolocation')
external _Geo? get _geo;

extension type _Geo._(JSObject _) implements JSObject {
  external void getCurrentPosition(JSFunction ok, JSFunction err, JSObject options);
}

extension type _Pos._(JSObject _) implements JSObject {
  external _Coords get coords;
}

extension type _Coords._(JSObject _) implements JSObject {
  external double get latitude;
  external double get longitude;
  external double get accuracy;
}

extension type _Err._(JSObject _) implements JSObject {
  external int get code;
}

Future<GeoFix> location() {
  final g = _geo;
  if (g == null) return Future.error(const PhoneError('unavailable'));
  final done = Completer<GeoFix>();
  g.getCurrentPosition(
    ((_Pos p) {
      if (!done.isCompleted) done.complete(GeoFix(p.coords.latitude, p.coords.longitude, p.coords.accuracy));
    }).toJS,
    ((_Err e) {
      if (!done.isCompleted) done.completeError(PhoneError(e.code == 1 ? 'denied' : 'unavailable'));
    }).toJS,
    {'enableHighAccuracy': true, 'timeout': 15000, 'maximumAge': 60000}.jsify()! as JSObject,
  );
  return done.future;
}

@JS('burumyInsets')
external JSArray<JSNumber>? _insets();

/// [top, bottom] of the screen the phone itself uses (status bar, home
/// indicator), from the page's safe-area insets.
(double, double) safeInsets() {
  try {
    final v = _insets()?.toDart;
    if (v == null || v.length < 2) return (0, 0);
    return (v[0].toDartDouble, v[1].toDartDouble);
  } catch (_) {
    return (0, 0);
  }
}

@JS('burumyPageColor')
external void _pageColor(JSString css);

/// Paint the page behind the app (and Safari's status bar) in one plain
/// colour: white, or black in dark mode (Eric 2026-11-26).
void pageColor(String css) {
  try {
    _pageColor(css.toJS);
  } catch (_) {}
}

@JS('burumyShare')
external JSPromise<JSString> _share(JSString? text, JSUint8Array? bytes, JSString name, JSString mime, JSBoolean saveOnly);

/// The browser's share sheet (with the picture where it can), else a
/// download of the picture / the text copied. "shared", "saved", "copied"
/// or "failed".
Future<String> share(String? text, Uint8List? bytes, String name, String mime, {bool saveOnly = false}) async {
  try {
    final r = await _share(text?.toJS, bytes?.toJS, name.toJS, mime.toJS, saveOnly.toJS).toDart;
    return r.toDart;
  } catch (_) {
    return 'failed';
  }
}

@JS('burumyVideoFrames')
external JSPromise<JSArray<JSUint8Array>> _videoFrames(JSUint8Array bytes, JSString mime, JSNumber count, JSNumber height);

/// Small pictures from along a video (video editor strip); empty = failed.
Future<List<Uint8List>> videoFrames(Uint8List video, String mime, int count, int height) async {
  try {
    final r = await _videoFrames(video.toJS, mime.toJS, count.toJS, height.toJS).toDart;
    return [for (final f in r.toDart) f.toDart];
  } catch (_) {
    return const [];
  }
}
