// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 빠른 전달 (Telegram tip 521, channel batch #15): hold the round share
// arrow beside a channel post, a glass capsule with five faces pops up
// (저장한 메시지 + the 4 chats I wrote in last), slide the finger onto one
// and let go. A tap still opens the full share sheet (tip 102).
// The post is passed on by the phone (re-encrypted for the new chat, where
// it came from is never kept), and the chat shows a 5 second 되돌리기 bar
// before it really goes.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter/gestures.dart' show LongPressGestureRecognizer;

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'share_sheet.dart';

/// The five places a held arrow offers: 저장한 메시지 first, then the
/// chats with the newest messages (no channels I only read, not this
/// chat, nothing archived).
List<ChatPreview> quickTargets(AppState s, String fromRoom) {
  final saved = s.savedRoomId;
  final out = <ChatPreview>[];
  for (final c in s.chats) {
    if (c.roomId == saved && saved != fromRoom) out.insert(0, c);
  }
  final rest = [
    for (final c in s.chats)
      if (c.roomId != fromRoom && c.roomId != saved && !c.archived && !c.isChannel && !s.isRequest(c.roomId)) c,
  ]..sort((a, b) => (b.last?.time ?? DateTime(2000)).compareTo(a.last?.time ?? DateTime(2000)));
  out.addAll(rest.take(5 - out.length));
  return out;
}

/// Share arrow that also forwards with a hold-and-slide.
class QuickForwardArrow extends StatefulWidget {
  const QuickForwardArrow({super.key, required this.roomId, required this.msgId, required this.onTap, required this.onPick});
  final String roomId, msgId;
  final VoidCallback onTap;

  /// Finger let go on a face: forward there.
  final void Function(ChatPreview to) onPick;

  @override
  State<QuickForwardArrow> createState() => _QuickForwardArrowState();
}

class _QuickForwardArrowState extends State<QuickForwardArrow> {
  OverlayEntry? entry;
  List<ChatPreview> targets = const [];
  final hover = ValueNotifier<int>(-1);

  /// Top-left of the capsule on screen.
  Offset origin = Offset.zero;

  static double get capsuleH => Tokens.quickFace + 2 * Tokens.quickPad;
  double get capsuleW => targets.length * Tokens.quickFace + (targets.length - 1) * Tokens.quickGap + 2 * Tokens.quickPad;

  void open() {
    final s = AppScope.read(context);
    targets = quickTargets(s, widget.roomId);
    if (targets.isEmpty) return;
    final box = context.findRenderObject()! as RenderBox;
    final at = box.localToGlobal(Offset.zero);
    final screen = MediaQuery.sizeOf(context).width;
    // Right edge lines up with the arrow, just above it; kept on screen.
    var left = at.dx + box.size.width - capsuleW;
    if (left < Tokens.space[2]) left = Tokens.space[2];
    if (left + capsuleW > screen - Tokens.space[2]) left = screen - Tokens.space[2] - capsuleW;
    origin = Offset(left, at.dy - capsuleH - Tokens.quickAbove);
    HapticFeedback.mediumImpact();
    entry = OverlayEntry(
      builder: (_) => _Capsule(origin: origin, targets: targets, hover: hover),
    );
    Overlay.of(context, rootOverlay: true).insert(entry!);
  }

  /// Which face is under the finger (screen point), or -1.
  int faceAt(Offset g) {
    final dy = g.dy - origin.dy;
    // A little slack above and below so the finger need not be exact.
    if (dy < -Tokens.space[4] || dy > capsuleH + Tokens.space[3]) return -1;
    final dx = g.dx - origin.dx - Tokens.quickPad + Tokens.quickGap / 2;
    final i = (dx / (Tokens.quickFace + Tokens.quickGap)).floor();
    return i >= 0 && i < targets.length ? i : -1;
  }

  void move(Offset g) {
    final i = faceAt(g);
    if (i != hover.value) {
      if (i >= 0) HapticFeedback.selectionClick();
      hover.value = i;
    }
  }

  void close() {
    final i = hover.value;
    entry?.remove();
    entry = null;
    hover.value = -1;
    if (i >= 0 && i < targets.length) widget.onPick(targets[i]);
  }

  @override
  void dispose() {
    entry?.remove();
    hover.dispose();
    super.dispose();
  }

  @override
  // Same 0.32 s hold as the bubble around it (Telegram), so this one wins.
  Widget build(BuildContext context) => RawGestureDetector(
    gestures: {
      LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(duration: Tokens.holdTime, debugOwner: this),
        (r) => r
          ..onLongPressStart = ((_) => open())
          ..onLongPressMoveUpdate = ((d) => move(d.globalPosition))
          ..onLongPressEnd = ((_) => close())
          ..onLongPressCancel = () {
            entry?.remove();
            entry = null;
            hover.value = -1;
          },
      ),
    },
    child: ShareArrow(key: Key('share-${widget.msgId}'), onTap: widget.onTap),
  );
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.origin, required this.targets, required this.hover});
  final Offset origin;
  final List<ChatPreview> targets;
  final ValueNotifier<int> hover;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    return Positioned(
      left: origin.dx,
      top: origin.dy,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, alignment: Alignment.bottomRight, child: child),
          child: ValueListenableBuilder<int>(
            valueListenable: hover,
            builder: (context, h, _) => Stack(
              key: const Key('quick-forward'),
              clipBehavior: Clip.none,
              children: [
                LiquidGlass(
                  radius: Tokens.capsule,
                  child: Padding(
                    padding: EdgeInsets.all(Tokens.quickPad),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < targets.length; i++) ...[
                          if (i > 0) SizedBox(width: Tokens.quickGap),
                          AnimatedScale(
                            key: Key('quick-to-${targets[i].roomId}'),
                            scale: h == i ? Tokens.quickGrow : 1,
                            duration: const Duration(milliseconds: 120),
                            child: Avatar(
                              name: targets[i].name,
                              size: Tokens.quickFace,
                              roomId: targets[i].roomId,
                              squircle: !targets[i].isDirect,
                              userId: targets[i].isDirect ? targets[i].peer : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (h >= 0)
                  Positioned(
                    left: Tokens.quickPad + h * (Tokens.quickFace + Tokens.quickGap) + Tokens.quickFace / 2 - 60,
                    width: 120,
                    bottom: Tokens.quickFace + 2 * Tokens.quickPad + Tokens.space[0],
                    child: Center(
                      child: Container(
                        key: const Key('quick-name'),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
                        decoration: BoxDecoration(color: p.label.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(Tokens.capsule)),
                        child: Text(
                          targets[h].roomId == s.savedRoomId ? L.of(context).savedMessages : targets[h].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.background, fontWeight: Tokens.semi),
                        ),
                      ),
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
