// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Web only: the browser's <video> element sits on top of the app and takes
// taps for itself, so a video in a bubble or the small window couldn't be
// tapped or dragged. This lets taps pass through to Burumy's own gestures.
export 'video_touch_stub.dart' if (dart.library.js_interop) 'video_touch_web.dart';
