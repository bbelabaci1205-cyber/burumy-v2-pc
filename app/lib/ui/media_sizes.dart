// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The size a photo or GIF took in the chat, remembered while the app runs.
// A row that scrolls away and back is built again and loads its picture
// again: with the size kept, the row keeps its height while it loads, so
// the list does not jump (Eric 2026-11-28, 한하윤 chat).
import 'dart:ui' show Size;

class MediaSizes {
  MediaSizes._();
  static final _sizes = <String, Size>{};

  static Size? of(String id) => _sizes[id];

  static void note(String id, Size? size) {
    if (size == null || size.isEmpty || _sizes[id] == size) return;
    _sizes.remove(id);
    _sizes[id] = size;
    if (_sizes.length > 600) _sizes.remove(_sizes.keys.first);
  }
}
