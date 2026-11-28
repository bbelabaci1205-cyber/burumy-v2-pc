// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 프로필 묶음 (Telegram tips 58 · 374 · 373): my earlier profile photos and
// the 공개 사진 for people who may not see the real one. Both stay on this
// phone (inside the app's encrypted settings); only the photo I pick as
// 대표 사진 is shared, by my 공개 범위 choices.
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'app_state.dart';
import 'features.dart';

class MyPhotos {
  const MyPhotos._();

  /// Earlier photos kept (newest first). Telegram keeps all; six is enough
  /// to go back and keeps the phone's settings small.
  static const max = 6;

  static const listKey = 'me_photos_old';
  static String photoKey(String id) => 'me_photo_old:$id';
  static const publicKey = 'me_public_photo';

  /// Long side of a kept photo (the editor makes 1024 px squares).
  static const keptSize = 720;

  /// Earlier photos, newest first.
  static List<String> ids(AppState s) => s.pref(listKey, '').split(',').where((x) => x.isNotEmpty && s.pref(photoKey(x), '').isNotEmpty).toList();

  static Uint8List? bytes(AppState s, String id) {
    final raw = s.pref(photoKey(id), '');
    return raw.isEmpty ? null : base64Decode(raw);
  }

  /// When an earlier photo was my 대표 사진 until (its id is the time).
  static DateTime? since(String id) {
    final ms = int.tryParse(id.split('-').first);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Puts [photo] (the one being replaced) at the top of the list.
  static Future<void> keep(AppState s, Uint8List photo, {DateTime? now}) async {
    if (!Features.profile || photo.isEmpty) return;
    final small = shrink(photo);
    final list = ids(s);
    // The same photo again (made 대표 and back): no second copy.
    for (final id in list) {
      final b = bytes(s, id);
      if (b != null && _same(b, small)) return;
    }
    final t = (now ?? DateTime.now()).millisecondsSinceEpoch;
    var id = '$t';
    for (var i = 1; list.contains(id); i++) {
      id = '$t-$i';
    }
    await s.setPref(photoKey(id), base64Encode(small));
    final next = [id, ...list];
    for (final old in next.skip(max)) {
      await s.setPref(photoKey(old), '');
    }
    await s.setPref(listKey, next.take(max).join(','));
  }

  /// Takes an earlier photo off this phone.
  static Future<void> forget(AppState s, String id) async {
    await s.setPref(photoKey(id), '');
    await s.setPref(listKey, ids(s).where((x) => x != id).join(','));
  }

  /// "대표 사진으로": the earlier photo becomes my photo again; the one it
  /// replaces moves into the list (saveMyProfile keeps it).
  static Future<void> makeMain(AppState s, String id) async {
    final b = bytes(s, id);
    if (b == null) return;
    await forget(s, id);
    await s.saveMyProfile(photo: b);
  }

  /// "사진 지우기" on my 대표 사진: the newest earlier photo takes its place
  /// (as in Telegram); the removed one is not kept.
  static Future<void> dropMain(AppState s) async {
    final next = ids(s).firstOrNull;
    final b = next == null ? null : bytes(s, next);
    if (next != null) await forget(s, next);
    await s.setPref('me_photo', b == null ? '' : base64Encode(b));
    await s.publishProfile();
  }

  /// 공개 사진 (tip 374): shown to people my 프로필 사진 setting hides it from.
  static Uint8List? publicPhoto(AppState s) {
    final raw = s.pref(publicKey, '');
    return raw.isEmpty ? null : base64Decode(raw);
  }

  static Future<void> setPublic(AppState s, Uint8List? photo) async {
    await s.setPref(publicKey, photo == null || photo.isEmpty ? '' : base64Encode(shrink(photo)));
    await s.publishProfile();
  }

  /// What a person sees as my photo, by my 프로필 사진 setting. [contact]:
  /// someone I talk to 1:1 (gets my card inside our encrypted chat).
  /// Returns the photo and whether it is the 공개 사진.
  static (Uint8List?, bool) seenBy(AppState s, {required bool contact}) {
    final real = s.myOwnPhoto;
    final pub = Features.profile ? publicPhoto(s) : null;
    final who = s.pref('who_photo', 'everyone');
    final sees = who == 'everyone' || (who == 'contacts' && contact);
    if (sees && real != null) return (real, false);
    if (pub != null) return (pub, true);
    return (null, false);
  }

  /// A smaller JPEG for keeping (PNG stays PNG when it has see-through parts).
  static Uint8List shrink(Uint8List b) {
    try {
      final im = img.decodeImage(b);
      if (im == null) return b;
      final big = im.width > keptSize || im.height > keptSize;
      final out = big ? img.copyResize(im, width: im.width >= im.height ? keptSize : null, height: im.height > im.width ? keptSize : null) : im;
      if (out.hasAlpha && _seeThrough(out)) return Uint8List.fromList(img.encodePng(out));
      final jpg = Uint8List.fromList(img.encodeJpg(out, quality: 88));
      return !big && jpg.length >= b.length ? b : jpg;
    } catch (_) {
      return b;
    }
  }

  static bool _seeThrough(img.Image im) {
    final step = (im.width ~/ 16).clamp(1, 64);
    for (var y = 0; y < im.height; y += step) {
      for (var x = 0; x < im.width; x += step) {
        if (im.getPixel(x, y).a < 250) return true;
      }
    }
    return false;
  }

  static String mimeOf(List<int> b) => b.length > 3 && b[0] == 0x89 && b[1] == 0x50 ? 'image/png' : 'image/jpeg';

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
