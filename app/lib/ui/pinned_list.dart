// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 고정 메시지 (Telegram tips 208 + 63): the split bar beside the pinned
// capsule, the "OO님이 메시지를 고정했어요" line, and the page with every pin.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/my_pins.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show Bubble;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

/// Left bar of the pinned capsule: one piece per pin, the shown one in
/// accent (Telegram shows at most 4 pieces and slides the window).
class PinSegments extends StatelessWidget {
  const PinSegments({super.key, required this.count, required this.at, required this.color});
  final int count;
  final int at;
  final Color color;

  static const height = 32.0, width = 2.0, gap = 2.0, visible = 4;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return Container(width: width, height: height, color: color);
    final n = count.clamp(1, visible);
    // The window of pieces that holds [at].
    final first = (at - (n - 1)).clamp(0, count - n);
    final piece = (height - gap * (n - 1)) / n;
    return SizedBox(
      key: const Key('pin-segments'),
      width: width,
      height: height,
      child: Column(
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0) const SizedBox(height: gap),
            Container(
              width: width,
              height: piece,
              decoration: BoxDecoration(color: first + i == at ? color : color.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(width / 2)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centred grey capsule in the chat: "OO님이 메시지를 고정했어요 · 미리보기".
class PinLine extends StatelessWidget {
  const PinLine({super.key, required this.who, required this.text, required this.onTap});

  /// null = I pinned it.
  final String? who;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final line = who == null ? l.pinLineMine : l.pinLine(who!);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Text(
              text.isEmpty ? line : '$line · $text',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ),
        ),
      ),
    );
  }
}

/// "고정 메시지 N개": the pins as bubbles, oldest at the top like the chat.
/// Tapping one returns its id (the chat jumps there). Admins get
/// "모두 고정 해제" at the bottom (Telegram's "Unpin All Messages").
class PinnedListPage extends StatefulWidget {
  const PinnedListPage({super.key, required this.roomId, required this.title, required this.pins, required this.msgs, required this.canUnpin});
  final String roomId;
  final String title;
  final List<String> pins;
  final Map<String, Msg> msgs;
  final bool canUnpin;

  @override
  State<PinnedListPage> createState() => _PinnedListPageState();
}

class _PinnedListPageState extends State<PinnedListPage> {
  late List<String> pins = [...widget.pins];

  Future<void> unpinAll() async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.unpinAllAsk(pins.length)),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('unpin-all-ok'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.unpinAll),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    final st = AppScope.of(context);
    final b = st.backend;
    // 나만 고정 (tip 276): mine are only on this phone.
    final mine = MyPins.read(st, widget.roomId);
    for (final id in [...pins]) {
      if (mine.containsKey(id)) {
        await MyPins.unpin(st, widget.roomId, id);
      } else {
        await b.pin(widget.roomId, id, false).catchError((_) {});
      }
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final shown = [for (final id in pins) ?widget.msgs[id]];
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar(back: true, title: l.pinnedListTitle(pins.length)),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                key: const Key('pinned-list-page'),
                reverse: true,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                itemCount: shown.length,
                itemBuilder: (c, i) {
                  final m = shown[shown.length - 1 - i];
                  return GestureDetector(
                    key: Key('pinned-item-${m.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, m.id),
                    child: IgnorePointer(
                      child: Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.title, senderName: m.mine ? null : displayId(m.sender)),
                    ),
                  );
                },
              ),
            ),
            if (widget.canUnpin && pins.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                child: GestureDetector(
                  key: const Key('unpin-all'),
                  onTap: unpinAll,
                  child: LiquidGlass(
                    radius: 25,
                    child: SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: Center(
                        child: Text(l.unpinAll, style: Tokens.body.style.copyWith(color: Palette.tileRed)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
