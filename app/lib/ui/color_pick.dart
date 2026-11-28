// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Exact colour for the pens and words (Telegram tip 370), shaped like the
// iOS colour picker: 격자 (a grid of shades), 스펙트럼 (hue across, light
// to dark down) and 슬라이더 (red, green, blue). Opened from the colour
// well next to the rainbow bar.
import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';

/// The 12 x 10 grid: a grey row on top, then 12 hues from light to deep.
List<List<Color>> colorGrid() {
  final rows = <List<Color>>[];
  rows.add([for (var i = 0; i < 12; i++) HSLColor.fromAHSL(1, 0, 0, 1 - i / 11).toColor()]);
  for (var r = 0; r < 9; r++) {
    // Light (0.88) at the top, deep (0.22) at the bottom, iOS-like saturation.
    final light = 0.88 - r * (0.66 / 8);
    rows.add([for (var h = 0; h < 12; h++) HSLColor.fromAHSL(1, h * 30.0, 0.92, light).toColor()]);
  }
  return rows;
}

/// The colour at (x, y) of the spectrum box: hue across, light (top) to dark (bottom).
Color spectrumAt(double x, double y) {
  final h = x.clamp(0.0, 1.0) * 360;
  final l = 0.95 - y.clamp(0.0, 1.0) * 0.85;
  return HSLColor.fromAHSL(1, h % 360, 1, l).toColor();
}

/// Opens the picker; returns the chosen colour or null.
Future<Color?> pickExactColor(BuildContext context, Color start) => showCupertinoModalPopup<Color>(
  context: context,
  builder: (_) => ColorPickSheet(start: start),
);

class ColorPickSheet extends StatefulWidget {
  const ColorPickSheet({super.key, required this.start});
  final Color start;
  @override
  State<ColorPickSheet> createState() => _ColorPickSheetState();
}

class _ColorPickSheetState extends State<ColorPickSheet> {
  late Color color = widget.start;
  int tab = 0;
  Offset? spot; // where the finger last was on the spectrum (0..1)

  static const _bg = Color(0xFF1C1C1E);
  static const _white = Color(0xFFFFFFFF);

  int _ch(double v) => (v * 255).round().clamp(0, 255);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Container(
      key: const Key('color-pick'),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[2])),
      ),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[4] + MediaQuery.paddingOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: Tokens.closeButton),
                Expanded(
                  child: Text(
                    l.colorTitle,
                    textAlign: TextAlign.center,
                    style: Tokens.body.style.copyWith(color: _white, fontWeight: Tokens.semi),
                  ),
                ),
                CupertinoButton(
                  key: const Key('color-pick-done'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
                  onPressed: () => Navigator.pop(context, color),
                  child: Text(
                    l.done,
                    style: Tokens.body.style.copyWith(color: const Color(0xFFFFCC00), fontWeight: Tokens.semi),
                  ),
                ),
              ],
            ),
            SizedBox(height: Tokens.space[1]),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                key: const Key('color-pick-tabs'),
                groupValue: tab,
                thumbColor: const Color(0xFF636366),
                backgroundColor: const Color(0xFF2C2C2E),
                children: {
                  0: Text(l.colorGrid, style: Tokens.preview.style.copyWith(color: _white)),
                  1: Text(l.colorSpectrum, style: Tokens.preview.style.copyWith(color: _white)),
                  2: Text(l.colorSliders, style: Tokens.preview.style.copyWith(color: _white)),
                },
                onValueChanged: (v) => setState(() => tab = v ?? 0),
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            SizedBox(height: 236, child: [grid, spectrum, sliders][tab]()),
            SizedBox(height: Tokens.space[2]),
            Row(
              children: [
                Container(
                  key: const Key('color-pick-swatch'),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(Tokens.radius[0]),
                    border: Border.all(color: const Color(0x33FFFFFF), width: 0.5),
                  ),
                ),
                SizedBox(width: Tokens.space[2]),
                Text(
                  '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}',
                  style: Tokens.body.style.copyWith(color: _white, fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget grid() {
    final rows = colorGrid();
    return LayoutBuilder(
      builder: (_, box) {
        final cw = box.maxWidth / 12, chh = box.maxHeight / rows.length;
        void at(Offset p) {
          final c = (p.dx / cw).floor().clamp(0, 11), r = (p.dy / chh).floor().clamp(0, rows.length - 1);
          setState(() => color = rows[r][c]);
        }

        return GestureDetector(
          key: const Key('color-pick-grid'),
          onTapDown: (d) => at(d.localPosition),
          onPanUpdate: (d) => at(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[0]),
            child: Column(
              children: [
                for (final row in rows)
                  Expanded(
                    child: Row(
                      children: [
                        for (final c in row)
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: c,
                                border: c == color ? Border.all(color: _white, width: 2.5) : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget spectrum() => LayoutBuilder(
    builder: (_, box) {
      void at(Offset p) {
        final x = (p.dx / box.maxWidth).clamp(0.0, 1.0), y = (p.dy / box.maxHeight).clamp(0.0, 1.0);
        setState(() {
          spot = Offset(x, y);
          color = spectrumAt(x, y);
        });
      }

      return GestureDetector(
        key: const Key('color-pick-spectrum'),
        onTapDown: (d) => at(d.localPosition),
        onPanUpdate: (d) => at(d.localPosition),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Tokens.radius[0]),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _SpectrumPainter())),
              if (spot != null)
                Positioned(
                  left: spot!.dx * box.maxWidth - 14,
                  top: spot!.dy * box.maxHeight - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: _white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 4)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Widget sliders() {
    final l = L.of(context);
    Widget one(String name, String k, double v, Color tint, Color Function(int) make) => Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(name, style: Tokens.preview.style.copyWith(color: _white)),
        ),
        Expanded(
          child: CupertinoSlider(key: Key('color-pick-$k'), value: v, activeColor: tint, onChanged: (x) => setState(() => color = make(_ch(x)))),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${_ch(v)}',
            textAlign: TextAlign.end,
            style: Tokens.preview.style.copyWith(color: _white, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        one(l.colorRed, 'r', color.r, const Color(0xFFFF3B30), (x) => color.withRed(x)),
        one(l.colorGreen, 'g', color.g, const Color(0xFF34C759), (x) => color.withGreen(x)),
        one(l.colorBlue, 'b', color.b, const Color(0xFF007AFF), (x) => color.withBlue(x)),
      ],
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: [for (var i = 0; i <= 12; i++) HSLColor.fromAHSL(1, (i * 30) % 360, 1, .5).toColor()]).createShader(rect),
    );
    // White at the top fading to clear, then clear to black at the bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF2FFFFFF), Color(0x00FFFFFF), Color(0x00000000), Color(0xE6000000)],
          stops: [0, .47, .53, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SpectrumPainter o) => false;
}
