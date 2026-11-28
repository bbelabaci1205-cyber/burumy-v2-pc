// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// A chat photo full screen: pinch to zoom, swipe sideways through an
// album, tap to hide the bars. Bottom row: 편집해서 보내기 (Telegram tip
// 118: draw or write on someone's photo and send it as a new message) and
// 저장. Other screens add their own buttons to [PhotoViewPage.extraButtons].
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../core/backend.dart' show Msg;
import '../core/app_state.dart';
import '../core/media_tags.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'gallery_save.dart';
import 'live_text.dart' show liveTextButton;
import 'media_editor.dart';
import 'stories.dart' show showStoryToast;

/// A button for the bottom row: (key, icon, label, what it does with the
/// photo's bytes).
typedef PhotoButton = ({Key key, IconData icon, String Function(L l) label, Future<void> Function(BuildContext c, Uint8List bytes) onTap});

class PhotoViewPage extends StatefulWidget {
  const PhotoViewPage({super.key, required this.roomId, required this.photos, this.start = 0, this.canShare = true, this.canPost = true, this.who = ''});
  final String roomId;

  /// The photo, or every photo of its album in order.
  final List<Msg> photos;
  final int start;

  /// False in chats with 공유 비활성화 (no edit-and-send, no save).
  final bool canShare;
  final bool canPost;
  final String who;

  /// More buttons other features put in the bottom row.
  /// A button whose label is empty is not shown (e.g. 글자 on phones that
  /// can't read text).
  static final extraButtons = <PhotoButton>[liveTextButton];

  @override
  State<PhotoViewPage> createState() => _PhotoViewPageState();
}

class _PhotoViewPageState extends State<PhotoViewPage> {
  late final pages = PageController(initialPage: widget.start);
  late int at = widget.start;
  final cache = <String, Future<List<int>>>{};
  bool bars = true;
  bool busy = false;

  static const _white = Color(0xFFFFFFFF);

  Future<List<int>> bytesOf(Msg m) => cache.putIfAbsent(m.fileId, () => AppScope.read(context).backend.downloadFile(widget.roomId, m.fileId));

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  /// Draw or write on it; the chat sends the result as a new photo.
  Future<void> editAndSend() async {
    final m = widget.photos[at];
    setState(() => busy = true);
    final raw = Uint8List.fromList(await bytesOf(m));
    if (!mounted) return;
    setState(() => busy = false);
    final png = await editChatPhoto(context, raw);
    if (png != null && mounted) Navigator.pop(context, png);
  }

  Future<void> save() async {
    final l = L.of(context);
    final ok = await saveToGallery(AppScope.read(context).backend, widget.roomId, widget.photos[at]);
    if (mounted) showStoryToast(context, ok ? l.savedToGallery : l.saveFailed);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final mq = MediaQuery.of(context);
    final many = widget.photos.length > 1;
    final buttons = <(Key, IconData, String, VoidCallback?)>[
      if (widget.canShare && widget.canPost) (const Key('photo-edit-send'), CupertinoIcons.pencil_outline, l.editAndSend, busy ? null : editAndSend),
      if (widget.canShare && !kIsWeb) (const Key('photo-save'), CupertinoIcons.arrow_down_to_line, l.saveToGallery, save),
      if (widget.canShare)
        for (final b in PhotoViewPage.extraButtons.where((b) => b.label(l).isNotEmpty))
          (
            b.key,
            b.icon,
            b.label(l),
            () async {
              final raw = Uint8List.fromList(await bytesOf(widget.photos[at]));
              if (context.mounted) await b.onTap(context, raw);
            },
          ),
    ];
    return CupertinoPageScaffold(
      key: const Key('photo-view'),
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => bars = !bars),
              child: PageView.builder(
                controller: pages,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => at = i),
                itemBuilder: (_, i) => FutureBuilder<List<int>>(
                  future: bytesOf(widget.photos[i]),
                  builder: (_, snap) {
                    final d = snap.data;
                    if (d == null || d.isEmpty) return const Center(child: CupertinoActivityIndicator(color: _white));
                    return InteractiveViewer(
                      key: Key('photo-zoom-$i'),
                      maxScale: 6,
                      child: Center(child: Image.memory(Uint8List.fromList(d), fit: BoxFit.contain, gaplessPlayback: true)),
                    );
                  },
                ),
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: bars ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !bars,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(top: mq.viewPadding.top),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Color(0x00000000)]),
                    ),
                    child: SizedBox(
                      height: Tokens.topBar + Tokens.space[2],
                      child: Row(
                        children: [
                          CupertinoButton(
                            key: const Key('photo-close'),
                            onPressed: () => Navigator.pop(context),
                            child: const Icon(CupertinoIcons.xmark, color: _white, size: Tokens.closeIcon),
                          ),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.who.isNotEmpty)
                                  Text(
                                    widget.who,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Tokens.navTitle.style.copyWith(color: _white),
                                  ),
                                Text(
                                  many ? l.photoOf(at + 1, widget.photos.length) : shortTime(context, widget.photos[at].time),
                                  style: Tokens.navSubtitle.style.copyWith(color: _white.withValues(alpha: 0.7)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Tokens.closeButton + 16),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (buttons.isNotEmpty)
                    Container(
                      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[2] + mq.viewPadding.bottom),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0x99000000), Color(0x00000000)]),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final (k, icon, label, tap) in buttons)
                            CupertinoButton(
                              key: k,
                              padding: EdgeInsets.zero,
                              onPressed: tap,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: tap == null ? _white.withValues(alpha: 0.35) : _white, size: Tokens.tabIcon),
                                  const SizedBox(height: 3),
                                  Text(label, style: Tokens.tabLabel.style.copyWith(color: _white)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real name of a chat photo or video (without the album / spoiler marks).
String mediaName(Msg m) => MediaTags.plain(m.body);
