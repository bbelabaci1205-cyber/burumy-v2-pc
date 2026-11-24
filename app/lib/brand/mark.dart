// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The small Burumy mark for places under 48 px (send button, tabs, loading
// dots): five round drops scattering up in one big wave (rulebook D-6).
// The 76-dot original is for big places; both may change with the logo.
import 'package:flutter/widgets.dart';

class BurumyMark extends StatelessWidget {
  const BurumyMark({super.key, required this.color, this.size = 24});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _Mark(color)),
  );
}

class _Mark extends CustomPainter {
  _Mark(this.color);
  final Color color;

  /// Centre x, centre y, radius, as parts of the box.
  static const drops = [(0.27, 0.73, 0.19), (0.55, 0.57, 0.135), (0.73, 0.38, 0.10), (0.81, 0.20, 0.07), (0.70, 0.07, 0.045)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    for (final (x, y, r) in drops) {
      canvas.drawCircle(Offset(x * size.width, y * size.height), r * size.width, paint);
    }
  }

  @override
  bool shouldRepaint(_Mark old) => old.color != color;
}
