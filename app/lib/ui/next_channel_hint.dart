// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다음 안 읽은 채널 (Telegram tip 292): what shows under the last post while
// the list is pulled up. A round arrow fills as the pull grows; once full,
// letting go opens the next channel.
import 'package:flutter/cupertino.dart';

import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

class NextChannelHint extends StatelessWidget {
  const NextChannelHint({super.key, required this.next, required this.progress});
  final ChatPreview next;

  /// 0..1; 1 = letting go opens it.
  final double progress;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ready = progress >= 1;
    return Opacity(
      opacity: (progress * 1.6).clamp(0.0, 1.0),
      child: Column(
        key: const Key('next-channel'),
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: Tokens.nextFace + 8,
            height: Tokens.nextFace + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressRing(value: progress, color: p.accent, track: p.separator),
                ),
                AnimatedScale(
                  scale: ready ? 1.15 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: Icon(CupertinoIcons.arrow_up, size: 18, color: ready ? p.accent : p.secondaryLabel),
                ),
              ],
            ),
          ),
          SizedBox(height: Tokens.space[1]),
          LiquidGlass(
            radius: Tokens.capsule,
            child: Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[0], Tokens.space[0], Tokens.space[2], Tokens.space[0]),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Avatar(name: next.name, size: Tokens.authorFace, roomId: next.roomId, squircle: true, channel: true),
                  SizedBox(width: Tokens.space[1]),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          next.name,
                          key: const Key('next-channel-name'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                        ),
                        Text(ready ? l.nextChannelLetGo : l.nextChannelPull(next.unread), style: Tokens.bubbleMeta.style.copyWith(color: p.secondaryLabel)),
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

/// Thin ring that fills clockwise from the top.
class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({super.key, required this.value, required this.color, required this.track});
  final double value;
  final Color color, track;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _Ring(value, color, track));
}

class _Ring extends CustomPainter {
  _Ring(this.v, this.c, this.t);
  final double v;
  final Color c, t;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r.deflate(1), 0, 6.2832, false, pen..color = t);
    canvas.drawArc(r.deflate(1), -1.5708, 6.2832 * v, false, pen..color = c);
  }

  @override
  bool shouldRepaint(_Ring o) => o.v != v || o.c != c || o.t != t;
}
