// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 내 QR 코드 (Telegram tips 316 + 368):
//  - 테마: six looks for the card and the page behind it, picked from a
//    row of small cards (the first one is my app colour, green or blue)
//  - 5분짜리 QR: the code carries an end time and stops working after
//    5 minutes; my ID is not written under it, and there is no copy row.
import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/features.dart';
import '../core/qr.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'qr_watch.dart' show scanQr;
import 'settings_kit.dart';

/// The link a QR code carries for me. The web address waits for the domain.
/// With [until] (5분 QR) the app that reads it refuses it after that time.
String userLink(String id, {DateTime? until}) => until == null ? 'burumy://u/$id' : 'burumy://u/$id?until=${until.millisecondsSinceEpoch ~/ 1000}';

/// The ID inside one of our person codes, or null (not ours, or a 5분 QR
/// whose time is up).
String? readUserLink(String text, DateTime now) {
  final m = RegExp(r'^burumy://u/([^?\s]+)(?:\?until=(\d+))?$').firstMatch(text.trim());
  if (m == null) return null;
  final until = int.tryParse(m.group(2) ?? '');
  if (until != null && now.millisecondsSinceEpoch ~/ 1000 >= until) return null;
  return Uri.decodeComponent(m.group(1)!);
}

/// How long a 5분 QR works.
const shortQrLife = Duration(minutes: 5);

class QrTheme {
  const QrTheme(this.id, this.emoji, this.top, this.bottom, this.ink);
  final String id;
  final String emoji;

  /// Page gradient (top → bottom) and the colour of the code itself.
  final Color top, bottom, ink;

  /// iOS system colours only (Eric's tile rule); 'app' follows 내 색상.
  static List<QrTheme> all(Palette p) => [
    // Darker ink than the accent so phone cameras read it well on white.
    QrTheme('app', '🫧', p.accent.withValues(alpha: 0.30), p.accent.withValues(alpha: 0.08), Color.lerp(p.accent, const Color(0xFF000000), 0.35)!),
    const QrTheme('ocean', '🌊', Color(0xFF5AC8FA), Color(0xFF007AFF), Color(0xFF0A4FA8)),
    const QrTheme('sunset', '🌅', Color(0xFFFFCC00), Color(0xFFFF2D55), Color(0xFFC2185B)),
    const QrTheme('grape', '🍇', Color(0xFFAF52DE), Color(0xFF5856D6), Color(0xFF4A3AB0)),
    const QrTheme('mint', '🌿', Color(0xFF00C7BE), Color(0xFF34C759), Color(0xFF0B7A55)),
    const QrTheme('night', '🌙', Color(0xFF1C1C1E), Color(0xFF3A3A5C), Color(0xFF1C1C1E)),
  ];
}

/// Settings > QR button: my ID as a QR code (or someone else's, from
/// their profile, with no themes or 5분 choice).
class QrPage extends StatefulWidget {
  const QrPage({super.key, this.userId, this.title});
  final String? userId;
  final String? title;
  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  bool copied = false;
  DateTime? until;
  Timer? tick;

  bool get mine => widget.userId == null;

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  void startShort() {
    tick?.cancel();
    setState(() => until = clock.now().add(shortQrLife));
    tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (clock.now().isAfter(until!)) t.cancel();
      setState(() {});
    });
  }

  void stopShort() {
    tick?.cancel();
    setState(() => until = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final id = displayId(widget.userId ?? s.backend.userId ?? '');
    final themes = QrTheme.all(p);
    final theme = mine ? themes.where((t) => t.id == s.pref('qr_theme', 'app')).firstOrNull ?? themes.first : themes.first;
    final left = until?.difference(clock.now());
    final expired = left != null && left.isNegative;
    final code = QrCode.encode(userLink(id, until: until));
    String mmss(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

    final card = Container(
      key: const Key('my-qr-code'),
      width: 260,
      padding: const EdgeInsets.fromLTRB(22, 44, 22, 18),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFFFF),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(30)),
        shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, 6))],
      ),
      child: Column(
        children: [
          if (code != null)
            AnimatedOpacity(
              duration: Tokens.liveFade,
              opacity: expired ? 0.12 : 1,
              child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: QrPainter(code, theme.ink))),
            ),
          const SizedBox(height: 14),
          if (until == null)
            Text(
              id,
              style: Tokens.body.style.copyWith(color: const Color(0xFF16241B), fontWeight: Tokens.semi),
            )
          else
            Text(
              expired ? l.qrShortOver : mmss(left!),
              key: const Key('qr-countdown'),
              style: (expired ? Tokens.body : Tokens.qrCountdown).style.copyWith(
                color: expired ? const Color(0xFF8E8E93) : theme.ink,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
    );

    return SettingsScaffold(
      title: widget.title ?? l.myQr,
      children: [
        // The theme colours fill the area behind the card (Telegram 316).
        Container(
          key: Key('qr-bg-${theme.id}'),
          margin: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          padding: EdgeInsets.symmetric(vertical: Tokens.space[5]),
          decoration: ShapeDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.top, theme.bottom]),
            shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3])),
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Padding(padding: const EdgeInsets.only(top: 36), child: card),
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFFFFF)),
                  padding: const EdgeInsets.all(3),
                  child: Avatar(name: id.replaceFirst('@', ''), size: 66, userId: widget.userId ?? s.backend.userId),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[3], Tokens.space[5], 0),
          child: Text(
            until != null ? l.qrShortInfo : l.myQrInfo,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        if (mine) ...[
          group(context, header: l.qrTheme, [
            SizedBox(
              height: Tokens.qrThemeH + Tokens.space[3] * 2,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.all(Tokens.space[3]),
                children: [
                  for (final t in themes)
                    Padding(
                      padding: EdgeInsets.only(right: Tokens.space[2]),
                      child: GestureDetector(
                        key: Key('qr-theme-${t.id}'),
                        onTap: () => s.setPref('qr_theme', t.id == 'app' ? '' : t.id),
                        child: Container(
                          width: Tokens.qrThemeW,
                          height: Tokens.qrThemeH,
                          alignment: Alignment.center,
                          decoration: ShapeDecoration(
                            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [t.top, t.bottom]),
                            shape: RoundedSuperellipseBorder(
                              borderRadius: BorderRadius.circular(Tokens.qrThemeCorner),
                              side: BorderSide(color: t.id == theme.id ? p.accent : const Color(0x00000000), width: 2.5),
                            ),
                          ),
                          child: Text(t.emoji, style: const TextStyle(fontSize: Tokens.qrThemeEmoji)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
          group(context, footer: l.qrShortFooter, [
            IosTile(
              key: const Key('qr-short-row'),
              leading: iconTile(Palette.tileOrange, CupertinoIcons.timer),
              title: Text(l.qrShort),
              trailing: IosSwitch(
                key: const Key('qr-short'),
                value: until != null,
                activeTrackColor: p.accent,
                onChanged: (v) => v ? startShort() : stopShort(),
              ),
            ),
            if (expired)
              IosTile(
                key: const Key('qr-short-again'),
                leading: iconTile(p.accent, CupertinoIcons.arrow_clockwise),
                title: Text(l.qrShortAgain),
                onTap: startShort,
              ),
          ]),
        ],
        if (until == null || (mine && Features.shareLinks))
          group(context, [
            if (until == null)
              IosTile(
                key: const Key('qr-copy'),
                leading: iconTile(Palette.tileBlue, CupertinoIcons.doc_on_doc_fill),
                title: Text(copied ? l.copied : l.copy),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: id));
                  setState(() => copied = true);
                },
              ),
            // Someone else's code: read it with the camera (tip 503).
            if (mine && Features.shareLinks)
              IosTile(
                key: const Key('qr-scan'),
                leading: iconTile(Palette.tileIndigo, CupertinoIcons.qrcode_viewfinder),
                title: Text(l.qrScan),
                onTap: () => scanQr(context),
              ),
          ]),
      ],
    );
  }
}

class QrPainter extends CustomPainter {
  QrPainter(this.code, this.color);
  final QrCode code;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / code.size;
    final paint = Paint()..color = color;
    bool finder(int x, int y) => (x < 7 && y < 7) || (x >= code.size - 7 && y < 7) || (x < 7 && y >= code.size - 7);
    for (var y = 0; y < code.size; y++) {
      for (var x = 0; x < code.size; x++) {
        if (finder(x, y) || !code.dark(x, y)) continue;
        // Soft round dots (still read fine: centres stay dark).
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x * cell + cell * .06, y * cell + cell * .06, cell * .88, cell * .88), Radius.circular(cell * .3)),
          paint,
        );
      }
    }
    // The three corner eyes, rounded.
    for (final (fx, fy) in [(0, 0), (code.size - 7, 0), (0, code.size - 7)]) {
      final o = Rect.fromLTWH(fx * cell, fy * cell, cell * 7, cell * 7);
      canvas.drawDRRect(RRect.fromRectAndRadius(o, Radius.circular(cell * 2.2)), RRect.fromRectAndRadius(o.deflate(cell), Radius.circular(cell * 1.5)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(o.deflate(cell * 2), Radius.circular(cell * 1.1)), paint);
    }
  }

  @override
  bool shouldRepaint(QrPainter o) => o.code != code || o.color != color;
}
