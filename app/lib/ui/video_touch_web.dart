// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
import 'dart:js_interop';

@JS('document')
external _Doc get _doc;

extension type _Doc(JSObject _) implements JSObject {
  external _El createElement(String tag);
  external _El get head;
}

extension type _El(JSObject _) implements JSObject {
  external set textContent(String v);
  external void appendChild(_El c);
}

bool _done = false;

/// video_player_web adds <video id="videoElement-N"> elements (often after
/// this runs); one page-wide rule lets taps fall through all of them
/// (Burumy draws its own controls).
void videoLetTapsThrough() {
  if (_done) return;
  _done = true;
  final s = _doc.createElement('style')..textContent = 'video[id^="videoElement-"]{pointer-events:none!important}';
  _doc.head.appendChild(s);
}
