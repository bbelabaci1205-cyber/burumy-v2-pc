// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사진 제안 (Telegram tip 373): pick a profile photo for a friend (handy for
// parents who never set one); it goes end-to-end encrypted into our 1:1 chat
// as a card, and only their tap on "내 사진으로" changes their photo.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/error_log.dart';
import '../core/my_photos.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios_route.dart';
import 'my_profile_page.dart';
import 'stories.dart' show showStoryToast;

/// Picks + edits a photo and sends it to [userId]'s 1:1 chat. True if sent.
Future<bool> suggestPhoto(BuildContext context, String userId) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final chat = s.chats.where((c) => c.isDirect && c.peer == userId).firstOrNull;
  if (chat == null) {
    showStoryToast(context, l.photoSuggestNoChat);
    return false;
  }
  final picked = await pickProfilePhoto(context);
  if (picked == null || !context.mounted) return false;
  try {
    final small = MyPhotos.shrink(picked);
    final file = jsonDecode(await s.backend.uploadEncrypted(small));
    await s.backend.createCard(chat.roomId, 'photo', {'file': file, 'mime': MyPhotos.mimeOf(small)});
    await s.refresh();
    if (context.mounted) showStoryToast(context, l.photoSuggestSent);
    return true;
  } catch (e, st) {
    ErrorLog.add(e, st);
    if (context.mounted) showStoryToast(context, l.saveFailed);
    return false;
  }
}

/// The suggested photo's bytes, kept so the list does not flicker.
final _suggested = <String, Uint8List>{};

Future<Uint8List?> suggestedPhoto(Backend b, Msg m) async {
  final have = _suggested[m.id];
  if (have != null) return have;
  final f = m.card?.data['file'];
  if (f == null) return null;
  try {
    return _suggested[m.id] = Uint8List.fromList(await b.downloadEncrypted(jsonEncode(f)));
  } catch (_) {
    return null;
  }
}

/// In the chat: "○○님이 프로필 사진을 제안했어요" with the photo in a circle
/// and, for the one it was suggested to, "사진 보기" (centred, no bubble).
class PhotoSuggestBubble extends StatefulWidget {
  const PhotoSuggestBubble({super.key, required this.m, required this.name});
  final Msg m;

  /// Who sent it, as I know them.
  final String name;

  @override
  State<PhotoSuggestBubble> createState() => _PhotoSuggestBubbleState();
}

class _PhotoSuggestBubbleState extends State<PhotoSuggestBubble> {
  Uint8List? bytes;

  @override
  void initState() {
    super.initState();
    bytes = _suggested[widget.m.id];
    if (bytes == null) {
      suggestedPhoto(AppScope.read(context).backend, widget.m).then((b) {
        if (mounted && b != null) setState(() => bytes = b);
      });
    }
  }

  Future<void> view() async {
    final b = bytes;
    if (b == null) return;
    final l = L.of(context);
    await Navigator.of(context, rootNavigator: true).push<void>(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (c) => PhotoUsePage(
          bytes: b,
          title: l.photoSuggestTheirs(widget.name),
          button: l.photoSuggestUse,
          onUse: () async {
            final s = AppScope.read(c);
            await s.saveMyProfile(photo: b);
            if (!c.mounted) return;
            Navigator.pop(c);
            showStoryToast(c, l.photoMainDone);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final mine = widget.m.mine;
    return Center(
      child: Container(
        key: Key('photo-suggest-${widget.m.id}'),
        width: Tokens.suggestCard,
        margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        padding: EdgeInsets.all(Tokens.space[3]),
        decoration: BoxDecoration(
          color: p.label.withValues(alpha: p.dark ? 0.16 : 0.08),
          borderRadius: BorderRadius.circular(Tokens.radius[3]),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: mine ? null : view,
              child: ClipOval(
                child: SizedBox(
                  width: Tokens.suggestPhoto,
                  height: Tokens.suggestPhoto,
                  child: bytes == null
                      ? ColoredBox(color: p.label.withValues(alpha: 0.08), child: const CupertinoActivityIndicator())
                      : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true),
                ),
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            Text(
              mine ? l.photoSuggestMine : l.photoSuggestTheirs(widget.name),
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.label),
            ),
            if (!mine) ...[
              SizedBox(height: Tokens.space[2]),
              GestureDetector(
                key: Key('photo-suggest-view-${widget.m.id}'),
                behavior: HitTestBehavior.opaque,
                onTap: view,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                  decoration: BoxDecoration(color: p.label.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Text(
                    l.photoSuggestView,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
