// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 들어오기 전 대화: messages from before I joined a group, sent to my
// phones only by the member who added me (engine/src/history.rs). A bar at
// the top of the chat opens them; they stay on this phone.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/phone.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show Bubble;
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'media_bubbles.dart' show VideoPlayerPage;
import 'stories.dart' show showStoryToast;

class EarlierBar extends StatefulWidget {
  const EarlierBar({super.key, required this.roomId, required this.title});
  final String roomId;
  final String title;
  @override
  State<EarlierBar> createState() => _EarlierBarState();
}

class _EarlierBarState extends State<EarlierBar> {
  List<Msg> list = const [];
  bool closed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(
      AppScope.read(context).backend.earlierMessages(widget.roomId).then((x) {
        if (mounted) setState(() => list = x);
      }, onError: (_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty || closed) return const SizedBox.shrink();
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], 0),
      child: GestureDetector(
        key: const Key('earlier-bar'),
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).push(
          IosPageRoute(
            builder: (_) => EarlierPage(roomId: widget.roomId, title: widget.title, list: list),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[2])),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
          child: Row(
            children: [
              Icon(CupertinoIcons.clock, size: 18, color: p.accent),
              SizedBox(width: Tokens.space[1]),
              Expanded(
                child: Text(
                  l.earlierBar(list.length),
                  style: Tokens.body.style.copyWith(color: p.accent, fontWeight: FontWeight.w500),
                ),
              ),
              GestureDetector(
                key: const Key('earlier-close'),
                onTap: () => setState(() => closed = true),
                child: Icon(CupertinoIcons.xmark, size: 16, color: p.secondaryLabel, semanticLabel: l.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EarlierPage extends StatelessWidget {
  const EarlierPage({super.key, required this.roomId, required this.title, required this.list});
  final String roomId;
  final String title;
  final List<Msg> list;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      key: const Key('earlier-page'),
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.earlierTitle), backgroundColor: p.chatBackground, border: null),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[1]),
          children: [
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: Text(
                l.earlierInfo,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
            ),
            for (final (i, m) in list.indexed)
              Padding(
                padding: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
                child: m.kind == 'text'
                    ? Bubble(msg: m, roomId: roomId, chatTitle: title, senderName: m.mine ? null : displayId(m.sender))
                    : EarlierMedia(roomId: roomId, index: i, msg: m),
              ),
          ],
        ),
      ),
    );
  }
}

/// A photo, video, voice message or file from before I came: the small
/// picture first; tap opens it (downloaded and decrypted on this phone).
class EarlierMedia extends StatefulWidget {
  const EarlierMedia({super.key, required this.roomId, required this.index, required this.msg});
  final String roomId;
  final int index;
  final Msg msg;

  @override
  State<EarlierMedia> createState() => _EarlierMediaState();
}

class _EarlierMediaState extends State<EarlierMedia> {
  Future<List<int>>? thumb;
  bool busy = false;

  bool get visual => widget.msg.kind == 'image' || widget.msg.kind == 'video';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (visual) thumb ??= AppScope.read(context).backend.earlierFile(widget.roomId, widget.index, thumb: true);
  }

  Future<List<int>> full() => AppScope.read(context).backend.earlierFile(widget.roomId, widget.index);

  Future<void> open() async {
    if (busy) return;
    final m = widget.msg;
    final l = L.of(context);
    final nav = Navigator.of(context);
    if (m.kind == 'video') {
      await nav.push(IosPageRoute(builder: (_) => VideoPlayerPage(load: full)));
      return;
    }
    setState(() => busy = true);
    try {
      final bytes = Uint8List.fromList(await full());
      if (!mounted) return;
      if (m.kind == 'image') {
        await nav.push(IosPageRoute(builder: (_) => _EarlierPhoto(bytes: bytes)));
      } else if (m.kind == 'audio') {
        final player = VoiceKit.player();
        await player.play(bytes, 'earlier-${widget.roomId}-${widget.index}');
      } else {
        await Phone.share(bytes: bytes, name: m.body?.isNotEmpty == true ? m.body! : 'file', mime: 'application/octet-stream');
      }
    } catch (_) {
      if (mounted) showStoryToast(context, l.earlierFileFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final m = widget.msg;
    final fg = m.mine ? p.onAccent : p.label;
    final small = Tokens.caption.style.copyWith(color: p.secondaryLabel);
    final Widget body;
    if (visual) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        child: SizedBox(
          width: 240,
          height: 240,
          child: FutureBuilder<List<int>>(
            future: thumb,
            builder: (context, snap) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: p.searchFill),
                if (snap.hasData) Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, gaplessPlayback: true),
                if (snap.connectionState != ConnectionState.done || busy) const Center(child: CupertinoActivityIndicator()),
                if (snap.hasError) Center(child: Icon(CupertinoIcons.photo, color: p.secondaryLabel, size: 36)),
                if (m.kind == 'video')
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x80000000)),
                      child: const Icon(CupertinoIcons.play_fill, color: Color(0xFFFFFFFF), size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      final voice = m.kind == 'audio';
      body = Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: m.mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: m.mine ? p.onAccent : p.accent),
              child: busy
                  ? CupertinoActivityIndicator(color: m.mine ? p.accent : p.onAccent)
                  : Icon(voice ? CupertinoIcons.play_fill : CupertinoIcons.doc_fill, color: m.mine ? p.accent : p.onAccent, size: 20),
            ),
            SizedBox(width: Tokens.space[2]),
            Flexible(
              child: Text(
                voice ? l.earlierVoice : (m.body?.isNotEmpty == true ? m.body! : l.attachFile),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Tokens.body.style.copyWith(color: fg),
              ),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
        child: Column(
          crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!m.mine)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(displayId(m.sender), style: small),
              ),
            GestureDetector(key: Key('earlier-media-${widget.index}'), onTap: open, child: body),
            if (m.caption != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(m.caption!, style: Tokens.body.style.copyWith(color: p.label)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text(shortTime(context, m.time), style: small),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen photo with pinch to zoom.
class _EarlierPhoto extends StatelessWidget {
  const _EarlierPhoto({required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    key: const Key('earlier-photo'),
    backgroundColor: const Color(0xFF000000),
    navigationBar: GlassTopBar.nav(leading: const GlassBack(), backgroundColor: const Color(0x00000000), border: null),
    child: InteractiveViewer(maxScale: 5, child: Center(child: Image.memory(bytes))),
  );
}
