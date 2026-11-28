// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Channel post quick share (Telegram tip 102): the round arrow beside a
// channel post opens this sheet. Pick several chats in a grid, add a word,
// send to all at once ("3곳에 전달했어요"), or copy the post's link.
// Forwarding keeps no source (v2 rule), and 공유 비활성화 chats never show
// the arrow.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/room_links.dart' show MessageLink;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

/// Shows the sheet; returns how many chats got the post (0 = none), or -1
/// when only the link was copied.
Future<int> showShareSheet(BuildContext context, {required String roomId, required Msg msg}) async {
  final n = await showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (_) => ShareSheet(roomId: roomId, msg: msg),
  );
  return n ?? 0;
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  /// Grid: 4 across, 60 pt photos (Telegram iOS share sheet).
  static const columns = 4, photo = 60.0;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final picked = <String>[];
  final word = TextEditingController();
  String query = '';
  bool sending = false;

  @override
  void dispose() {
    word.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (picked.isEmpty || sending) return;
    setState(() => sending = true);
    final b = AppScope.read(context).backend;
    var done = 0;
    final text = word.text.trim();
    for (final to in picked) {
      try {
        if (text.isNotEmpty) await b.sendText(to, text);
        await b.forward(widget.roomId, widget.msg.id, to);
        done++;
      } catch (_) {}
    }
    if (mounted) Navigator.pop(context, done);
  }

  Future<void> copyLink() async {
    await Clipboard.setData(ClipboardData(text: MessageLink(widget.roomId, widget.msg.id).url));
    if (mounted) Navigator.pop(context, -1);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final q = query.trim().toLowerCase();
    final chats = [
      for (final c in s.chats)
        if (c.roomId != widget.roomId && (q.isEmpty || c.name.toLowerCase().contains(q))) c,
    ];
    // Channel posts (text or photo) can go to my story (tip 414).
    final toStory = s.chats.any((c) => c.roomId == widget.roomId && c.isChannel) && (widget.msg.kind == 'text' || widget.msg.kind == 'image') && q.isEmpty;
    final media = MediaQuery.of(context);
    final bottom = media.viewInsets.bottom > 0 ? media.viewInsets.bottom : media.padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: SizedBox(
        height: media.size.height * 0.62,
        child: LiquidGlass(
          radius: IosActionSheet.radius,
          child: ColoredBox(
            color: p.card.withValues(alpha: p.dark ? 0.5 : 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: Tokens.sheetHeader,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('share-close'),
                          onTap: () => Navigator.pop(context, 0),
                          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                        ),
                      ),
                      Text(
                        l.shareTitle,
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      ),
                      Positioned(
                        right: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('share-copy-link'),
                          onTap: copyLink,
                          child: GlassCircle.icon(context, CupertinoIcons.link, size: Tokens.closeIcon),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
                  child: CupertinoSearchTextField(
                    key: const Key('share-search'),
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    placeholder: l.searchChats,
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: ShareSheet.columns, mainAxisExtent: ShareSheet.photo + 40),
                    itemCount: chats.length + (toStory ? 1 : 0),
                    itemBuilder: (c, i) {
                      // Tip 414: a channel post to my own story first.
                      if (toStory && i == 0) {
                        return GestureDetector(
                          key: const Key('share-to-story'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pop(context, -2),
                          child: Column(
                            children: [
                              Container(
                                width: ShareSheet.photo,
                                height: ShareSheet.photo,
                                padding: const EdgeInsets.all(Tokens.miniRing),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.storyRing),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: p.card),
                                  child: Icon(CupertinoIcons.plus, color: p.accent, size: Tokens.listIcon),
                                ),
                              ),
                              SizedBox(height: Tokens.space[0]),
                              Text(
                                l.skToStory,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: Tokens.caption.style.copyWith(color: p.label),
                              ),
                            ],
                          ),
                        );
                      }
                      final chat = chats[i - (toStory ? 1 : 0)];
                      final on = picked.contains(chat.roomId);
                      return GestureDetector(
                        key: Key('share-to-${chat.roomId}'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => on ? picked.remove(chat.roomId) : picked.add(chat.roomId)),
                        child: Column(
                          children: [
                            SizedBox(
                              width: ShareSheet.photo,
                              height: ShareSheet.photo,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AnimatedScale(
                                    // iOS lift: the picked photo shrinks a little inside an accent ring.
                                    scale: on ? 0.86 : 1,
                                    duration: const Duration(milliseconds: 160),
                                    child: Avatar(
                                      name: chat.name,
                                      size: ShareSheet.photo,
                                      squircle: !chat.isDirect,
                                      userId: chat.isDirect ? chat.peer : null,
                                      roomId: chat.roomId,
                                    ),
                                  ),
                                  if (on)
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        key: Key('share-check-${chat.roomId}'),
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: p.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: p.card, width: 2),
                                        ),
                                        child: Icon(CupertinoIcons.checkmark_alt, size: 14, color: p.onAccent),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: Tokens.space[0]),
                            Text(
                              chat.name,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.caption.style.copyWith(color: on ? p.accent : p.label),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (picked.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[2]),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoTextField(
                            key: const Key('share-word'),
                            controller: word,
                            placeholder: l.shareAddWord,
                            maxLines: 3,
                            minLines: 1,
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: 10),
                            decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.capsule)),
                          ),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        GestureDetector(
                          key: const Key('share-send'),
                          onTap: send,
                          child: Container(
                            height: 40,
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                            decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                l.shareSendN(picked.length),
                                style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The round arrow beside a channel post (30 pt, like Telegram).
class ShareArrow extends StatelessWidget {
  const ShareArrow({super.key, required this.onTap});
  final VoidCallback onTap;

  static const size = 30.0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: p.incoming, shape: BoxShape.circle),
        child: Icon(CupertinoIcons.arrowshape_turn_up_right_fill, size: 15, color: p.secondaryLabel),
      ),
    );
  }
}
