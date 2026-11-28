// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// A new 1:1 chat with no messages yet (TelegramTips 80, our way): a card in
// the middle "아직 메시지가 없어요" with a big Burumy character waving hello
// over our soft scattering-dust; one tap sends that sticker as the first
// message. The character is picked from the chat, so it stays the same.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'common.dart';

/// Our characters' hello stickers.
List<String> get helloStickers => [
  for (final p in stickerPacks)
    for (final i in p.items)
      if (i.endsWith('_hello')) i,
];

/// The same hello for the same chat.
String helloFor(String roomId) {
  final all = helloStickers;
  var h = 0;
  for (final c in roomId.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return all[h % all.length];
}

class FirstHelloCard extends StatefulWidget {
  const FirstHelloCard({super.key, required this.roomId, required this.name, required this.onSend});
  final String roomId;
  final String name;
  final Future<void> Function(String stickerId) onSend;

  @override
  State<FirstHelloCard> createState() => _FirstHelloCardState();
}

class _FirstHelloCardState extends State<FirstHelloCard> with SingleTickerProviderStateMixin {
  late final AnimationController wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  bool sending = false;

  @override
  void initState() {
    super.initState();
    // Hops three times, then rests (reduce motion: it just sits still).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) wave.repeat(count: 3);
    });
  }

  @override
  void dispose() {
    wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final id = helloFor(widget.roomId);
    final asset = stickerAsset(id);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[5]),
        // Shrinks (never cut) when the keyboard leaves little room.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            key: const Key('first-hello'),
            width: 260,
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[4], Tokens.space[4], Tokens.space[3]),
            decoration: BoxDecoration(color: p.card.withValues(alpha: 0.86), borderRadius: BorderRadius.circular(Tokens.radius[3])),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.firstHelloTitle,
                  textAlign: TextAlign.center,
                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(
                  l.firstHelloSub,
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
                SizedBox(height: Tokens.space[2]),
                GestureDetector(
                  key: Key('first-hello-$id'),
                  behavior: HitTestBehavior.opaque,
                  onTap: sending
                      ? null
                      : () async {
                          setState(() => sending = true);
                          try {
                            await widget.onSend(id);
                          } finally {
                            if (mounted) setState(() => sending = false);
                          }
                        },
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: AnimatedBuilder(
                      animation: wave,
                      builder: (_, child) {
                        // A small hop and tilt, then a rest (hello!).
                        final t = wave.value;
                        final hop = t < .35 ? math.sin(t / .35 * math.pi) : 0.0;
                        final tilt = t < .35 ? math.sin(t / .35 * math.pi * 2) * .08 : 0.0;
                        return CustomPaint(
                          painter: _HelloDust(t, p.accent),
                          child: Transform.translate(
                            offset: Offset(0, -10 * hop),
                            child: Transform.rotate(angle: tilt, child: child),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(Tokens.space[2]),
                        child: asset == null ? const SizedBox() : Image.asset(asset, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Tokens.space[1]),
                Text(
                  l.firstHelloTap(widget.name),
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.accent),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Burumy's scattering dust: small brand-colour dots drifting out from
/// behind the character and fading (the launch logo's feel).
class _HelloDust extends CustomPainter {
  _HelloDust(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.Random(3);
    for (var i = 0; i < 22; i++) {
      final a = r.nextDouble() * math.pi * 2;
      final speed = .5 + r.nextDouble() * .5;
      final k = (t * speed + r.nextDouble()) % 1.0;
      final d = size.width * (.28 + .26 * k);
      final o = c + Offset(math.cos(a), math.sin(a)) * d;
      final dot = 1.5 + r.nextDouble() * 2.5;
      canvas.drawCircle(o, dot * (1 - k * .5), Paint()..color = color.withValues(alpha: .45 * (1 - k)));
    }
  }

  @override
  bool shouldRepaint(_HelloDust old) => old.t != t || old.color != color;
}
