// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 보낼 때 말풍선이 날아드는 움직임 (Telegram tip 289, iPhone Messages): a
// message I just sent rises out of the message field into its place and
// settles, instead of just appearing. Stickers and big emoji grow from the
// field. Off with Settings > Power saving > moving effects (AppState.calm).
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class SendFly extends StatefulWidget {
  const SendFly({super.key, required this.child, required this.fly, this.big = false, this.onDone});
  final Widget child;

  /// Play once now (a message that has just been sent).
  final bool fly;

  /// Sticker / big emoji: grows from half size.
  final bool big;
  final VoidCallback? onDone;

  @override
  State<SendFly> createState() => _SendFlyState();
}

class _SendFlyState extends State<SendFly> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Tokens.sendFly, value: widget.fly ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.fly) c.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fly && c.isCompleted) return widget.child;
    final from = widget.big ? Tokens.sendFlyFromBig : Tokens.sendFlyFrom;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      builder: (context, child) {
        final t = c.value;
        final rise = Curves.easeOutCubic.transform(t);
        final grow = Curves.easeOutBack.transform(t);
        return Opacity(
          opacity: Curves.easeOut.transform((t * 3).clamp(0, 1)),
          child: Transform.translate(
            offset: Offset(0, (1 - rise) * Tokens.sendFlyRise),
            child: Transform.scale(scale: from + (1 - from) * grow, alignment: Alignment.bottomRight, child: child),
          ),
        );
      },
    );
  }
}
