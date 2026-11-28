// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// One made emoji (tip 354) drawn at any size, moving the way its maker
// chose. Still when GIFs are set not to move, in power saving or with
// iPhone's 동작 줄이기. Until its picture arrives it shows its stand-in emoji.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../core/app_state.dart';
import '../core/custom_emoji.dart';
import '../design/tokens.dart';

class CxEmojiView extends StatefulWidget {
  const CxEmojiView(this.id, {super.key, required this.size, this.still = false});
  final String id;
  final double size;

  /// Never moves (pickers that show many at once can still ask for motion).
  final bool still;

  /// Tap on a made emoji in a message (set by the chat screen: save it).
  static void Function(BuildContext context, String id)? onTap;

  @override
  State<CxEmojiView> createState() => _CxEmojiViewState();
}

class _CxEmojiViewState extends State<CxEmojiView> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Tokens.cxLoop);
  StreamSubscription<void>? sub;

  @override
  void initState() {
    super.initState();
    sub = CustomEmojis.changed.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
    final moves = !widget.still && (s?.gifsMove ?? true) && !(s?.calm ?? false) && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    if (moves && !c.isAnimating) {
      c.repeat();
    } else if (!moves) {
      c.stop();
    }
  }

  @override
  void dispose() {
    unawaited(sub?.cancel());
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = CustomEmojis.known[widget.id];
    final size = widget.size;
    final Widget pic = e == null
        ? Text(
            '🙂',
            style: TextStyle(fontSize: size * 0.8, height: 1, fontFamilyFallback: Tokens.emojiFallback),
          )
        : Image.memory(e.png, width: size, height: size, gaplessPlayback: true, cacheWidth: (size * 3).round(), semanticLabel: e.base);
    final body = SizedBox(
      key: Key('cx-${widget.id}'),
      width: size,
      height: size,
      child: Center(
        child: e == null || e.motion == CxMotion.none
            ? pic
            : AnimatedBuilder(animation: c, child: pic, builder: (context, child) => cxMove(e.motion, c.value, child!)),
      ),
    );
    final tap = CxEmojiView.onTap;
    if (tap == null || e == null) return body;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => tap(context, widget.id), child: body);
  }
}

/// The motion at loop point [t] (0..1): small, friendly moves.
Widget cxMove(CxMotion m, double t, Widget child) {
  final w = t * 2 * math.pi;
  switch (m) {
    case CxMotion.none:
      return child;
    case CxMotion.bounce:
      final h = math.sin(t * math.pi).abs();
      return FractionalTranslation(
        translation: Offset(0, -0.18 * h),
        child: Transform.scale(scaleY: 1 - 0.06 * (1 - h), child: child),
      );
    case CxMotion.spin:
      return Transform.rotate(angle: w, child: child);
    case CxMotion.wiggle:
      return Transform.rotate(angle: math.sin(w * 2) * 0.22, child: child);
    case CxMotion.beat:
      final b = math.max(0.0, math.sin(w * 2)) * (t < 0.5 ? 1 : 0.6);
      return Transform.scale(scale: 1 + 0.16 * b, child: child);
    case CxMotion.float:
      return FractionalTranslation(translation: Offset(math.sin(w) * 0.06, math.cos(w) * 0.1), child: child);
    case CxMotion.jelly:
      return Transform.scale(scaleX: 1 + 0.1 * math.sin(w * 2), scaleY: 1 - 0.1 * math.sin(w * 2), child: child);
    case CxMotion.sparkle:
      return Opacity(
        opacity: 0.7 + 0.3 * (0.5 + 0.5 * math.cos(w * 2)),
        child: Transform.scale(scale: 1 + 0.05 * math.sin(w * 2), child: child),
      );
  }
}
