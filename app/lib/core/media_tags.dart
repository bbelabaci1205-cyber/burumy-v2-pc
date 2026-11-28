// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Small marks carried in a photo or video's (encrypted) file name, the
// same way round video notes and my stickers are told apart: which album
// it belongs to (묶어서 보내기), 가리기 (spoiler) and GIF (a video sent
// without sound that plays on a loop). The server never sees the name; an
// app that doesn't know the marks just shows a normal photo.
//
// Form: bm_<mark>_<mark>__<real name>, marks: a<id>-<index>-<count>, s, g,
// p<id> (a video that has a light copy) and l<id>-<height> (that light
// copy, tips 479 · 480: not shown as its own message), o<12 hex> (a GIF's
// 글씨·그림 layer, tip 558) and t<from ms>-<to ms> (the part of a GIF that
// plays; -1 = to the end). The GIF itself is never re-made: words, drawing
// and the cut are drawn over it by the app.
class MediaTags {
  const MediaTags({
    this.album,
    this.index = 0,
    this.count = 1,
    this.spoiler = false,
    this.gif = false,
    this.pair,
    this.lightOf,
    this.lightHeight = 0,
    this.layer,
    this.from = 0,
    this.to = -1,
  });
  final String? album;
  final int index, count;
  final bool spoiler, gif;

  /// This video's light copy is the one marked l<pair>.
  final String? pair;

  /// This video IS the light copy of the video marked p<lightOf>.
  final String? lightOf;
  final int lightHeight;

  /// Id of the words/drawing layer sent in a hidden note (see gifs.dart).
  final String? layer;

  /// Plays only [from]..[to] ms (to -1 = to the end).
  final int from, to;

  bool get trims => from > 0 || to >= 0;

  static const prefix = 'bm_';

  bool get any => album != null || spoiler || gif || pair != null || lightOf != null || layer != null || trims;

  /// [name] with these marks in front.
  String apply(String name) {
    final marks = [
      if (album != null) 'a$album-$index-$count',
      if (spoiler) 's',
      if (gif) 'g',
      if (pair != null) 'p$pair',
      if (lightOf != null) 'l$lightOf-$lightHeight',
      if (layer != null) 'o$layer',
      if (trims) 't$from-$to',
    ];
    return marks.isEmpty ? name : '$prefix${marks.join('_')}__$name';
  }

  static MediaTags of(String? name) {
    final n = name ?? '';
    if (!n.startsWith(prefix)) return const MediaTags();
    final end = n.indexOf('__', prefix.length);
    if (end < 0) return const MediaTags();
    String? album;
    var index = 0, count = 1;
    var spoiler = false, gif = false;
    String? pair, lightOf, layer;
    var lightHeight = 0;
    var from = 0, to = -1;
    for (final m in n.substring(prefix.length, end).split('_')) {
      if (m == 's') spoiler = true;
      if (m == 'g') gif = true;
      if (m.length > 1 && m.startsWith('p')) pair = m.substring(1);
      if (m.length > 1 && m.startsWith('l')) {
        final p = m.substring(1).split('-');
        if (p[0].isNotEmpty) {
          lightOf = p[0];
          lightHeight = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
        }
      }
      if (RegExp(r'^o[0-9a-f]{12}$').hasMatch(m)) layer = m.substring(1);
      final t = RegExp(r'^t(\d{1,8})-(-1|\d{1,8})$').firstMatch(m);
      if (t != null) {
        from = int.parse(t.group(1)!);
        to = int.parse(t.group(2)!);
        if (to >= 0 && to <= from) to = -1;
      }
      if (m.startsWith('a')) {
        final p = m.substring(1).split('-');
        if (p.length == 3 && p[0].isNotEmpty) {
          album = p[0];
          index = int.tryParse(p[1]) ?? 0;
          count = (int.tryParse(p[2]) ?? 1).clamp(1, 20);
        }
      }
    }
    return MediaTags(
      album: album,
      index: index,
      count: count,
      spoiler: spoiler,
      gif: gif,
      pair: pair,
      lightOf: lightOf,
      lightHeight: lightHeight,
      layer: layer,
      from: from,
      to: to,
    );
  }

  /// The real file name, without marks.
  static String plain(String? name) {
    final n = name ?? '';
    if (!n.startsWith(prefix)) return n;
    final end = n.indexOf('__', prefix.length);
    return end < 0 ? n : n.substring(end + 2);
  }
}
