// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Small drawn pictures on top of settings pages (our own art, theme colours).
import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import 'common.dart';

/// A laptop showing a Burumy chat (list on the left, bubbles on the right).
class LaptopArt extends StatelessWidget {
  const LaptopArt({super.key});
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return SizedBox(width: 200, height: 130, child: CustomPaint(painter: _Laptop(p)));
  }
}

class _Laptop extends CustomPainter {
  _Laptop(this.p);
  final Palette p;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final frame = Paint()..color = p.dark ? const Color(0xFF8E8E93) : const Color(0xFF3A3A3C);
    final screen = RRect.fromLTRBR(w * 0.12, 0, w * 0.88, s.height * 0.78, const Radius.circular(9));
    c.drawRRect(screen, frame);
    final inner = RRect.fromLTRBR(w * 0.12 + 5, 5, w * 0.88 - 5, s.height * 0.78 - 4, const Radius.circular(5));
    c.drawRRect(inner, Paint()..color = p.card);
    // Chat list column.
    final split = inner.left + inner.width * 0.36;
    c.drawRect(Rect.fromLTRB(split, inner.top, split + 0.8, inner.bottom), Paint()..color = p.separator);
    const dots = [Palette.tileRed, Palette.tileOrange, Palette.tileBlue, Palette.tilePurple, Palette.tileTeal];
    for (var i = 0; i < dots.length; i++) {
      final y = inner.top + 10 + i * 17.0;
      c.drawCircle(Offset(inner.left + 9, y), 4.5, Paint()..color = dots[i]);
      c.drawRRect(RRect.fromLTRBR(inner.left + 17, y - 2, split - 6, y + 2, const Radius.circular(2)), Paint()..color = p.separator);
    }
    // Chat side: soft accent wash with bubbles.
    final chat = Rect.fromLTRB(split + 1, inner.top, inner.right, inner.bottom);
    c.drawRect(chat, Paint()..color = p.accent.withValues(alpha: 0.10));
    void bubble(double y, double width, bool mine) {
      final r = mine
          ? RRect.fromLTRBR(chat.right - 6 - width, y, chat.right - 6, y + 10, const Radius.circular(5))
          : RRect.fromLTRBR(chat.left + 6, y, chat.left + 6 + width, y + 10, const Radius.circular(5));
      c.drawRRect(r, Paint()..color = mine ? p.accent : p.incoming);
    }

    bubble(inner.top + 10, 46, false);
    bubble(inner.top + 25, 34, false);
    bubble(inner.top + 44, 52, true);
    bubble(inner.top + 59, 30, true);
    bubble(inner.top + 78, 40, false);
    // Base.
    final base = Path()
      ..moveTo(0, s.height * 0.80)
      ..lineTo(w, s.height * 0.80)
      ..lineTo(w * 0.96, s.height)
      ..lineTo(w * 0.04, s.height)
      ..close();
    c.drawPath(base, Paint()..color = p.dark ? const Color(0xFF636366) : const Color(0xFFC7C7CC));
    c.drawRRect(
      RRect.fromLTRBR(w * 0.42, s.height * 0.80, w * 0.58, s.height * 0.86, const Radius.circular(3)),
      Paint()..color = p.dark ? const Color(0xFF48484A) : const Color(0xFFAEAEB2),
    );
  }

  @override
  bool shouldRepaint(_Laptop o) => o.p != p;
}

/// Art + one line of text, centred (Telegram-style page top).
class ArtHeader extends StatelessWidget {
  const ArtHeader({super.key, required this.art, required this.text});
  final Widget art;
  final String text;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[3], Tokens.space[5], Tokens.space[3]),
      child: Column(
        children: [
          art,
          SizedBox(height: Tokens.space[3]),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}

/// A folder with coloured tabs sticking out (Settings > Chat folders).
class FolderArt extends StatelessWidget {
  const FolderArt({super.key});
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return SizedBox(width: 150, height: 112, child: CustomPaint(painter: _Folder(p)));
  }
}

class _Folder extends CustomPainter {
  _Folder(this.p);
  final Palette p;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // Back of the folder with its tab.
    final back = Path()
      ..addRRect(RRect.fromLTRBR(w * 0.06, h * 0.10, w * 0.40, h * 0.30, const Radius.circular(8)))
      ..addRRect(RRect.fromLTRBR(w * 0.06, h * 0.20, w * 0.94, h * 0.96, const Radius.circular(12)));
    c.drawPath(back, Paint()..color = Color.lerp(p.accent, const Color(0xFF000000), 0.18)!);
    // Coloured sheets peeking out.
    const sheets = [Palette.tileBlue, Palette.tileOrange, Palette.tilePurple];
    for (var i = 0; i < sheets.length; i++) {
      final x = w * (0.16 + i * 0.24);
      c.save();
      c.translate(x + w * 0.11, h * 0.40);
      c.rotate((i - 1) * 0.12);
      c.drawRRect(RRect.fromLTRBR(-w * 0.11, -h * 0.26, w * 0.11, h * 0.20, const Radius.circular(7)), Paint()..color = sheets[i]);
      for (var k = 0; k < 2; k++) {
        c.drawRRect(
          RRect.fromLTRBR(-w * 0.07, -h * (0.18 - k * 0.08), w * (0.07 - k * 0.03), -h * (0.15 - k * 0.08), const Radius.circular(2)),
          Paint()..color = const Color(0xB3FFFFFF),
        );
      }
      c.restore();
    }
    // Front of the folder, a little lighter on top (iOS tile glow).
    final front = RRect.fromLTRBR(w * 0.03, h * 0.42, w * 0.97, h, const Radius.circular(12));
    c.drawRRect(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(p.accent, const Color(0xFFFFFFFF), 0.12)!, p.accent],
        ).createShader(front.outerRect),
    );
  }

  @override
  bool shouldRepaint(_Folder o) => o.p != p;
}
