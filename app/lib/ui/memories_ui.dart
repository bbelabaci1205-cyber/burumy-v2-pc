// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 1년 전 오늘 (core/memories.dart): the glass bar on top of 저장한 메시지
// and the full-screen look back. Layout is ours (Snapchat's flashback card
// is only the idea); sizes follow the pinned bar and iOS 27 photo viewer.
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/memories.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show ForwardPickPage;
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'story_video.dart';
import 'wide.dart';

/// Pictures already opened here (event id → bytes), while the app runs.
final _bytes = <String, Future<List<int>>>{};

Future<List<int>> _load(AppState s, String room, Msg m) => _bytes.putIfAbsent(m.fileId, () => s.backend.downloadFileCached(room, m.fileId));

/// Under the saved chat's title while there are memories today (until I
/// close it for today).
class MemoriesBar extends StatelessWidget {
  const MemoriesBar({super.key, required this.roomId, this.onJump});
  final String roomId;

  /// "저장한 메시지에서 보기": scroll the saved chat to that message.
  final void Function(String id)? onJump;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final days = s.memories;
    if (days.isEmpty || s.pref(_closedKey, '') == Memories.dayKey(s.backend.clock)) return const SizedBox.shrink();
    final first = days.first;
    final pics = [for (final d in days) ...d.msgs];
    return Padding(
      key: const Key('memories-bar'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: GestureDetector(
        key: const Key('memories-open'),
        onTap: () => openMemories(context, roomId, onJump: onJump),
        child: LiquidGlass(
          radius: 24,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[1], Tokens.space[0], Tokens.space[1]),
            child: Row(
              children: [
                // Up to three small pictures, a little stacked.
                SizedBox(
                  width: 36.0 + 10 * (pics.take(3).length - 1),
                  height: 36,
                  child: Stack(
                    children: [
                      for (final (i, m) in pics.take(3).indexed.toList().reversed)
                        Positioned(
                          left: 10.0 * i,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Tokens.radius[1]),
                              border: Border.all(color: p.card, width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Tokens.radius[1] - 1),
                              child: _Thumb(roomId: roomId, msg: m),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.memoriesTitle(first.years),
                        style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                      ),
                      Text(
                        '${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(first.msgs.first.time)} · ${l.memoriesCount(Memories.count(days))}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                Text(l.memoriesOpen, style: Tokens.preview.style.copyWith(color: p.accent)),
                CupertinoButton(
                  key: const Key('memories-close'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(36, 36),
                  onPressed: () async {
                    await s.setPref(_closedKey, Memories.dayKey(s.backend.clock));
                    await Memories.markSeen(s);
                  },
                  child: Icon(CupertinoIcons.xmark, size: Tokens.listIconSmall, color: p.secondaryLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _closedKey = 'memories_closed';
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    if (msg.kind == 'video') {
      return ColoredBox(
        color: p.incoming,
        child: Icon(CupertinoIcons.play_fill, size: 16, color: p.secondaryLabel),
      );
    }
    return FutureBuilder<List<int>>(
      future: _load(AppScope.of(context), roomId, msg),
      builder: (_, snap) => snap.data == null
          ? ColoredBox(color: p.incoming)
          : Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, cacheWidth: 120, gaplessPlayback: true),
    );
  }
}

/// The look back: one picture at a time, newest year first.
Future<void> openMemories(BuildContext context, String roomId, {void Function(String id)? onJump}) async {
  final s = AppScope.read(context);
  await Memories.markSeen(s);
  if (!context.mounted) return;
  final jump = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<String>(IosPageRoute(fullscreenDialog: true, builder: (_) => MemoriesPage(roomId: roomId)));
  if (jump != null) onJump?.call(jump);
}

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  final pager = PageController();
  int at = 0;

  @override
  void dispose() {
    pager.dispose();
    super.dispose();
  }

  Future<void> send(Msg m) async {
    final s = AppScope.read(context);
    final l = L.of(context);
    final to = await openSheet<String>(context, (_) => const ForwardPickPage());
    if (to == null || !mounted) return;
    try {
      await s.backend.forward(widget.roomId, m.id, to);
      if (mounted) showNotice(l.forwarded);
    } catch (_) {}
  }

  void showNotice(String text) {
    final p = paletteOf(context);
    final o = Overlay.of(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (c) => Positioned(
        left: Tokens.space[4],
        right: Tokens.space[4],
        bottom: MediaQuery.paddingOf(c).bottom + 96,
        child: IgnorePointer(
          child: LiquidGlass(
            radius: Tokens.capsule,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: p.label),
              ),
            ),
          ),
        ),
      ),
    );
    o.insert(e);
    Future<void>.delayed(const Duration(seconds: 2), e.remove);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    final items = [
      for (final d in s.memories)
        for (final m in d.msgs) (d.years, m),
    ];
    if (items.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
      return const CupertinoPageScaffold(backgroundColor: Color(0xFF000000), child: SizedBox.shrink());
    }
    final i = at.clamp(0, items.length - 1);
    final (years, m) = items[i];
    final lang = Localizations.localeOf(context).languageCode;
    final pad = MediaQuery.paddingOf(context);
    return CupertinoPageScaffold(
      key: const Key('memories-page'),
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              key: const Key('memories-pager'),
              controller: pager,
              itemCount: items.length,
              onPageChanged: (n) => setState(() => at = n),
              itemBuilder: (_, n) => _Picture(roomId: widget.roomId, msg: items[n].$2),
            ),
          ),
          // Top: close, the title, the day; one short bar per picture.
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], pad.top + Tokens.space[1], Tokens.space[3], Tokens.space[3]),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x99000000), Color(0x00000000)]),
              ),
              child: Column(
                children: [
                  if (items.length > 1)
                    Padding(
                      padding: EdgeInsets.only(bottom: Tokens.space[2]),
                      child: Row(
                        children: [
                          for (var k = 0; k < items.length; k++)
                            Expanded(
                              child: Container(
                                height: 3,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: white.withValues(alpha: k == i ? 0.95 : 0.35),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.memoriesTitle(years),
                              key: const Key('memories-title'),
                              style: Tokens.body.style.copyWith(color: white, fontWeight: Tokens.semi),
                            ),
                            Text(DateFormat.yMMMEd(lang).format(m.time), style: Tokens.caption.style.copyWith(color: white.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      GlassCircle(
                        key: const Key('memories-x'),
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(CupertinoIcons.xmark, color: white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom: the caption, where it was saved, and two actions.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], pad.bottom + Tokens.space[2]),
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xAA000000), Color(0x00000000)]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if ((m.caption ?? '').trim().isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: Tokens.space[2]),
                      child: Text(
                        m.caption!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Tokens.preview.style.copyWith(color: white),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _Action(
                          key: const Key('memories-send'),
                          icon: CupertinoIcons.arrowshape_turn_up_right_fill,
                          text: l.memoriesSend,
                          onTap: () => send(m),
                        ),
                      ),
                      SizedBox(width: Tokens.space[2]),
                      Expanded(
                        child: _Action(
                          key: const Key('memories-goto'),
                          icon: CupertinoIcons.bookmark_fill,
                          text: l.memoriesGoTo,
                          onTap: () => Navigator.of(context).pop(m.id),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Tokens.space[2]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CupertinoIcons.lock_fill, size: 12, color: white.withValues(alpha: 0.7)),
                      SizedBox(width: Tokens.space[0]),
                      Text(l.memoriesOnPhone, style: Tokens.caption.style.copyWith(color: white.withValues(alpha: 0.7))),
                    ],
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

class _Picture extends StatelessWidget {
  const _Picture({required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<int>>(
    future: _load(AppScope.of(context), roomId, msg),
    builder: (_, snap) {
      final b = snap.data;
      if (b == null) return const Center(child: CupertinoActivityIndicator(color: Color(0xFFFFFFFF)));
      final bytes = Uint8List.fromList(b);
      if (msg.kind == 'video')
        return Center(
          child: StoryVideo(bytes: bytes, mime: 'video/mp4', loop: true),
        );
      return Center(child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true));
    },
  );
}

class _Action extends StatelessWidget {
  const _Action({super.key, required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    return GestureDetector(
      onTap: onTap,
      child: LiquidGlass(
        radius: Tokens.capsule,
        child: SizedBox(
          height: Tokens.closeButton,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: white),
              SizedBox(width: Tokens.space[1]),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.preview.style.copyWith(color: white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
