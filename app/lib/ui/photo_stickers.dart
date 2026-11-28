// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Things put on top of a photo in the chat photo editor and the story
// editor (Telegram tips 201 and 416): our stickers, emoji, and a picture
// from the gallery that can be cut out (배경 지우기, on this phone only:
// iPhone Vision / Android ML Kit, 18+ for Google's). Each one can be moved,
// pinched bigger, turned, flipped, copied or dragged to the bin.
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'ai_age_ui.dart';
import 'common.dart';
import 'sticker_panel.dart';

/// One thing on the photo. [at] = centre as a fraction of the picture.
class PhotoSticker {
  PhotoSticker.sticker(String this.id) : emoji = null, photo = null;
  PhotoSticker.emoji(String this.emoji) : id = null, photo = null;
  PhotoSticker.photo(Uint8List this.photo) : id = null, emoji = null;

  final String? id;
  final String? emoji;
  final Uint8List? photo;

  /// The cut-out picture (see-through background) once 오려내기 worked.
  Uint8List? cut;
  bool cutting = false;
  Offset at = const Offset(.5, .5);
  double scale = 1, turn = 0;
  bool flipped = false;

  PhotoSticker copy() {
    final c = id != null ? PhotoSticker.sticker(id!) : (emoji != null ? PhotoSticker.emoji(emoji!) : PhotoSticker.photo(photo!));
    return c
      ..cut = cut
      ..at = Offset((at.dx + .06).clamp(0, 1), (at.dy + .06).clamp(0, 1))
      ..scale = scale
      ..turn = turn
      ..flipped = flipped;
  }
}

/// The sticker drawn at [side] points (before its own scale and turn).
class PhotoStickerView extends StatelessWidget {
  const PhotoStickerView({super.key, required this.s, required this.side});
  final PhotoSticker s;
  final double side;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (s.emoji != null) {
      child = Text(s.emoji!, style: TextStyle(fontSize: side * .78, height: 1.1));
    } else if (s.id != null) {
      child = Image.asset(
        stickerAsset(s.id!) ?? '',
        width: side,
        height: side,
        errorBuilder: (_, _, _) => SizedBox(width: side, height: side),
      );
    } else if (s.cut != null) {
      child = Image.memory(s.cut!, width: side * 1.3, height: side * 1.3, fit: BoxFit.contain, gaplessPlayback: true);
    } else {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(side * .08),
        child: Image.memory(s.photo!, width: side * 1.3, height: side * 1.3, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    child = AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(s.cut != null), child: child),
    );
    if (s.flipped) child = Transform.flip(flipX: true, child: child);
    if (s.cutting) {
      child = Stack(
        alignment: Alignment.center,
        children: [
          Opacity(opacity: .55, child: child),
          const CupertinoActivityIndicator(color: Color(0xFFFFFFFF)),
        ],
      );
    }
    return child;
  }
}

/// A picture from the gallery for 사진 오려 붙이기 (tests swap [debugPick]).
Future<Uint8List?> Function()? debugPickStickerPhoto;
Future<Uint8List?> pickStickerPhoto() async {
  if (debugPickStickerPhoto != null) return debugPickStickerPhoto!();
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600);
  return x == null ? null : await x.readAsBytes();
}

/// Cuts the picture out on this phone. Returns false when this phone can't
/// (web, older phones, nothing found, under 18 on Android).
Future<bool> cutOutSticker(BuildContext context, PhotoSticker s, VoidCallback changed) async {
  if (s.photo == null || s.cut != null) return true;
  if (!await aiAgeOk(context)) return false;
  s.cutting = true;
  changed();
  final cut = await Phone.cutout(s.photo!);
  s
    ..cutting = false
    ..cut = cut;
  changed();
  return cut != null;
}

/// 스티커 tab sheet: '사진 오려 붙이기' on top, then our sticker panel with
/// its 이모지 side. Returns the new thing, or null.
Future<PhotoSticker?> pickPhotoSticker(BuildContext context) async {
  final got = await showCupertinoModalPopup<Object>(
    context: context,
    builder: (c) => Container(
      key: const Key('photo-sticker-sheet'),
      height: 440,
      decoration: BoxDecoration(
        color: paletteOf(c).card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[2])),
      ),
      padding: EdgeInsets.only(top: Tokens.space[2]),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: GestureDetector(
              key: const Key('photo-sticker-cut'),
              onTap: () => Navigator.pop(c, #photo),
              child: Container(
                height: Tokens.closeButton,
                decoration: BoxDecoration(color: paletteOf(c).background, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.scissors, size: Tokens.listIcon, color: paletteOf(c).accent),
                    SizedBox(width: Tokens.space[0]),
                    Text(L.of(c).stkPhotoCut, style: Tokens.preview.style.copyWith(color: paletteOf(c).label)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: Tokens.space[1]),
          Expanded(
            child: StickerPanel(onPick: (id) => Navigator.pop(c, PhotoSticker.sticker(id)), onEmoji: (e) => Navigator.pop(c, PhotoSticker.emoji(e))),
          ),
        ],
      ),
    ),
  );
  if (got is PhotoSticker) return got;
  if (got != #photo) return null;
  final bytes = await pickStickerPhoto();
  return bytes == null ? null : PhotoSticker.photo(bytes);
}

/// The small dark menu over a chosen sticker: 삭제 · 뒤집기 · 복제 (· 오려내기).
class StickerMenu extends StatelessWidget {
  const StickerMenu({super.key, required this.s, required this.onDelete, required this.onFlip, required this.onCopy, required this.onCut});
  final PhotoSticker s;
  final VoidCallback onDelete, onFlip, onCopy;
  final VoidCallback? onCut;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    Widget item(String k, String label, VoidCallback onTap, {bool red = false}) => GestureDetector(
      key: Key('stk-menu-$k'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
        child: Text(label, style: Tokens.preview.style.copyWith(color: red ? const Color(0xFFFF453A) : const Color(0xFFFFFFFF))),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE6202022),
        borderRadius: BorderRadius.circular(Tokens.radius[1]),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          item('delete', l.delete, onDelete, red: true),
          item('flip', l.stkFlip, onFlip),
          item('copy', l.stkCopy, onCopy),
          if (onCut != null) item('cut', l.stkCutout, onCut!),
        ],
      ),
    );
  }
}

/// A photo or video from the gallery to put into a sent message (사진
/// 바꾸기, tips 482 / 81 / 224). Returns (file name, bytes); tests swap
/// [debugPickSwap].
Future<(String, List<int>)?> Function()? debugPickSwap;
Future<(String, List<int>)?> pickSwapMedia() async {
  if (debugPickSwap != null) return debugPickSwap!();
  final x = await ImagePicker().pickMedia(maxWidth: 2560, maxHeight: 2560);
  if (x == null) return null;
  return (x.name, await x.readAsBytes());
}
