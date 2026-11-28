// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screens for 메시지 효과 (tip 451), 큰 이모지 효과 (219 · 297 · 355) and
// 주사위 (218): the full-screen piece layer, the picker on the send menu,
// the small replay mark on a bubble, the moving big emoji and the dice.
// All drawn by our own code (no Lottie files, no outside art). Nothing
// moves when 화면 효과 is off, in power saving or with iPhone's 동작 줄이기.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/effects.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart' show charEmojiAsset;
import '../stickers/char_emoji.dart';
import 'bubbles.dart' show SoapBubble;
import 'common.dart' show paletteOf;

/// Effects may move here (setting on, no power saving, no 동작 줄이기).
bool fxAllowed(BuildContext context) {
  final s = context.getInheritedWidgetOfExactType<AppScope>()?.notifier;
  return !(s?.calm ?? false) && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);
}

/// Plays [kind] over the whole screen once, from [from] (screen point;
/// null = lower middle, where new messages are).
void playFx(BuildContext context, FxKind kind, {Offset? from}) {
  if (!fxAllowed(context)) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => FxLayer(kind: kind, from: from, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
  unawaited(HapticFeedback.lightImpact());
}

/// The play position of a widget's middle on the screen.
Offset? centerOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

class _Piece {
  _Piece(this.glyph, this.size, this.delay, this.a, this.b, this.c, this.d, this.spin, this.color, this.group);
  final String glyph;
  final double size, delay;

  /// Meaning depends on the motion (start point, speed, sway).
  final double a, b, c, d, spin;
  final Color color;
  final int group;
}

/// Full-screen layer of moving pieces; taps go through.
class FxLayer extends StatefulWidget {
  const FxLayer({super.key, required this.kind, this.from, this.onDone});
  final FxKind kind;
  final Offset? from;
  final VoidCallback? onDone;

  /// Confetti colours: iOS system colours (rulebook ch. 4), no dark green.
  static const confetti = [Palette.tileRed, Palette.tileOrange, Palette.tileYellow, Palette.tileBlue, Palette.tilePurple, Palette.tilePink, Palette.tileTeal];

  @override
  State<FxLayer> createState() => _FxLayerState();
}

class _FxLayerState extends State<FxLayer> with SingleTickerProviderStateMixin {
  late final AnimationController t = AnimationController(vsync: this, duration: Tokens.fxLength);
  List<_Piece> pieces = const [];
  List<Offset> centers = const [];

  @override
  void initState() {
    super.initState();
    t.forward().whenComplete(() => widget.onDone?.call());
  }

  @override
  void dispose() {
    t.dispose();
    super.dispose();
  }

  void make(Size s) {
    final r = math.Random(widget.kind.id.hashCode ^ DateTime.now().millisecond);
    final k = widget.kind;
    final n = k.count;
    centers = [for (var i = 0; i < 3; i++) Offset(s.width * (0.2 + 0.6 * r.nextDouble()), s.height * (0.18 + 0.3 * r.nextDouble()))];
    pieces = [
      for (var i = 0; i < n; i++)
        () {
          final g = k.glyphs[i % k.glyphs.length];
          final paper = g == '▬';
          final size = paper
              ? 9.0
              : (k.motion == FxMotion.sweep && i == 0 ? 72.0 : Tokens.fxPieceMin + r.nextDouble() * (Tokens.fxPieceMax - Tokens.fxPieceMin));
          final delay = switch (k.motion) {
            FxMotion.burst => r.nextDouble() * 0.12,
            FxMotion.fireworks => (i % 3) * 0.22 + r.nextDouble() * 0.05,
            FxMotion.sweep => i == 0 ? 0.0 : 0.05 + (i / n) * 0.45,
            _ => r.nextDouble() * 0.45,
          };
          return _Piece(
            g,
            size,
            delay,
            r.nextDouble(),
            r.nextDouble(),
            r.nextDouble(),
            r.nextDouble(),
            r.nextDouble() * 2 - 1,
            FxLayer.confetti[i % FxLayer.confetti.length],
            i % 3,
          );
        }(),
    ];
  }

  Widget glyph(_Piece p) {
    if (p.glyph == '▬') {
      return Container(
        width: p.size * 1.6,
        height: p.size,
        decoration: BoxDecoration(color: p.color, borderRadius: BorderRadius.circular(2)),
      );
    }
    if (p.glyph == '🫧') return SoapBubble(color: paletteOf(context).accent, size: p.size * 1.5, phase: p.a);
    final m = charEmojiCode.matchAsPrefix(p.glyph);
    if (m != null && (charEmojiAsset(m.group(1)!) != null || m.group(1)!.startsWith('cx_'))) return CharEmoji(m.group(1)!, size: p.size * 1.4);
    return Text(
      p.glyph,
      style: TextStyle(fontSize: p.size, height: 1, fontFamilyFallback: Tokens.emojiFallback),
    );
  }

  /// Where a piece is at overall time [v] (null = not on screen).
  (Offset, double, double, double)? place(_Piece p, double v, Size s, Offset o) {
    final k = ((v - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
    if (v < p.delay || k >= 1) return null;
    final fade = k > 0.75 ? (1 - k) / 0.25 : 1.0;
    final pop = Curves.easeOutBack.transform((k * 6).clamp(0.0, 1.0));
    switch (widget.kind.motion) {
      case FxMotion.rise:
        final x = p.a * s.width + math.sin(k * math.pi * (2 + p.b * 2) + p.c * 6) * Tokens.fxSway;
        final y = s.height + p.size - k * (s.height * (0.7 + p.b * 0.5) + p.size);
        return (Offset(x, y), fade, pop, p.spin * 0.3 * k);
      case FxMotion.fall:
        final x = p.a * s.width + math.sin(k * math.pi * 3 + p.c * 6) * Tokens.fxSway;
        final y = -p.size + k * (s.height * (0.8 + p.b * 0.4) + p.size);
        return (Offset(x, y), fade, pop, p.spin * math.pi * 2 * k);
      case FxMotion.burst:
      case FxMotion.fireworks:
        final fw = widget.kind.motion == FxMotion.fireworks;
        final c = fw ? centers[p.group] : o;
        final ang = fw ? p.a * math.pi * 2 : -math.pi / 2 + (p.a - 0.5) * math.pi * 1.5;
        final speed = (fw ? 260 : 520) * (0.45 + p.b * 0.75);
        final secs = k * Tokens.fxLength.inMilliseconds / 1000 * (1 - p.delay);
        final g = fw ? 160 : 900;
        final pos = c + Offset(math.cos(ang) * speed * secs, math.sin(ang) * speed * secs + 0.5 * g * secs * secs);
        return (pos, fade, pop, p.spin * math.pi * 3 * k);
      case FxMotion.sweep:
        // One big piece flies on a curve from lower left to upper right;
        // the others are its trail, left where it passed.
        Offset path(double q) => Offset(-80 + q * (s.width + 160), s.height * 0.78 - math.sin(q * math.pi * 0.9) * s.height * 0.5 - q * s.height * 0.2);
        if (p.delay == 0) return (path(Curves.easeInOut.transform(k)), 1.0, 1.0, -0.4);
        final at = path(Curves.easeInOut.transform(p.delay / 0.5 * 0.9)) + Offset((p.c - 0.5) * 40, (p.d - 0.5) * 40 + k * 30);
        return (at, fade * 0.9, pop * (1 - k * 0.4), p.spin * k);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          if (pieces.isEmpty) make(size);
          final o = widget.from ?? Offset(size.width / 2, size.height * 0.72);
          return AnimatedBuilder(
            animation: t,
            builder: (context, _) => Stack(
              key: Key('fx-layer-${widget.kind.id}'),
              clipBehavior: Clip.none,
              children: [
                for (final p in pieces)
                  if (place(p, t.value, size, o) case (final at, final alpha, final scale, final turn))
                    Positioned(
                      left: at.dx - p.size,
                      top: at.dy - p.size,
                      width: p.size * 2,
                      height: p.size * 2,
                      child: Opacity(
                        opacity: alpha.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: turn,
                          child: Transform.scale(
                            scale: scale,
                            child: Center(child: glyph(p)),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- picker

/// "효과 넣기" on the send menu (Telegram's row above the send options):
/// six quick effects, and the full list with search behind the arrow.
/// Tapping one shows it once and picks it; tapping again takes it off.
class FxPicker extends StatefulWidget {
  const FxPicker({super.key, required this.picked});
  final ValueNotifier<String?> picked;

  @override
  State<FxPicker> createState() => _FxPickerState();
}

class _FxPickerState extends State<FxPicker> {
  bool open = false;
  String query = '';

  void tap(FxKind k) {
    final on = widget.picked.value == k.id;
    widget.picked.value = on ? null : k.id;
    setState(() {});
    if (!on) playFx(context, k, from: centerOf(context));
  }

  Widget cell(FxKind k, Palette p) {
    final on = widget.picked.value == k.id;
    final m = charEmojiCode.matchAsPrefix(k.icon);
    return GestureDetector(
      key: Key('fx-${k.id}'),
      onTap: () => tap(k),
      child: Semantics(
        label: k.name(Localizations.localeOf(context).languageCode == 'ko'),
        selected: on,
        button: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: Tokens.fxCell,
          height: Tokens.fxCell,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? p.accent.withValues(alpha: 0.18) : null,
            border: on ? Border.all(color: p.accent, width: 2) : null,
          ),
          child: m != null
              ? CharEmoji(m.group(1)!, size: Tokens.fxIcon + 4)
              : k.icon == '🫧'
              ? SoapBubble(color: p.accent, size: Tokens.fxIcon + 2)
              : Text(
                  k.icon,
                  style: TextStyle(fontSize: Tokens.fxIcon, height: 1, color: const Color(0xFF000000), fontFamilyFallback: Tokens.emojiFallback),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final quick = [for (final id in MsgFx.quick) MsgFx.byId(id)!];
    final found = MsgFx.search(query, korean: ko);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l.fxAdd, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        SizedBox(height: Tokens.space[1]),
        if (!open)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final k in quick) cell(k, p),
              GestureDetector(
                key: const Key('fx-more'),
                onTap: () => setState(() => open = true),
                child: Container(
                  width: Tokens.fxCell,
                  height: Tokens.fxCell,
                  alignment: Alignment.center,
                  child: Icon(CupertinoIcons.chevron_down, size: Tokens.listIconSmall, color: p.secondaryLabel, semanticLabel: l.fxMore),
                ),
              ),
            ],
          )
        else ...[
          CupertinoSearchTextField(key: const Key('fx-search'), placeholder: l.fxSearch, onChanged: (v) => setState(() => query = v)),
          SizedBox(height: Tokens.space[1]),
          SizedBox(
            height: Tokens.fxCell * 4 + Tokens.space[1] * 3,
            child: found.isEmpty
                ? Center(
                    child: Text(l.fxNothing, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  )
                : GridView.count(
                    crossAxisCount: 6,
                    mainAxisSpacing: Tokens.space[1],
                    padding: EdgeInsets.zero,
                    children: [for (final k in found) Center(child: cell(k, p))],
                  ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------- mark

/// Small mark beside the time on a message sent with an effect; tap to
/// see the effect again.
class FxMark extends StatelessWidget {
  const FxMark({super.key, required this.kind, required this.fg});
  final FxKind kind;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final m = charEmojiCode.matchAsPrefix(kind.icon);
    return GestureDetector(
      key: const Key('fx-mark'),
      behavior: HitTestBehavior.opaque,
      onTap: () => playFx(context, kind, from: centerOf(context)),
      child: Semantics(
        button: true,
        label: L.of(context).fxReplay,
        child: Padding(
          padding: const EdgeInsets.only(right: 3),
          child: m != null
              ? CharEmoji(m.group(1)!, size: Tokens.fxMark + 2)
              : Text(
                  kind.icon == '🫧' ? '🫧' : kind.icon,
                  style: TextStyle(fontSize: Tokens.fxMark, height: 1, fontFamilyFallback: Tokens.emojiFallback),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- big emoji

/// A lone big emoji that moves (219): it plays a short motion when it
/// first shows and when tapped; a tap also plays its full-screen effect
/// (297 · 355), and in a 1:1 chat the friend sees it too.
class BigEmojiFx extends StatefulWidget {
  const BigEmojiFx({super.key, required this.text, required this.child, this.onTapped, this.fresh = false});
  final String text;
  final Widget child;

  /// Sent to the friend's phone (1:1 only).
  final VoidCallback? onTapped;

  /// Just arrived: move once on its own.
  final bool fresh;

  @override
  State<BigEmojiFx> createState() => _BigEmojiFxState();
}

class _BigEmojiFxState extends State<BigEmojiFx> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Tokens.fxEmojiMove);

  bool get heart => const ['❤️', '🩷', '💖', '💕', '😍', '🥰'].contains(widget.text.trim());

  @override
  void initState() {
    super.initState();
    if (widget.fresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && fxAllowed(context)) c.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void tap() {
    if (!fxAllowed(context)) return;
    c.forward(from: 0);
    playFx(context, MsgFx.forEmoji(widget.text), from: centerOf(context));
    widget.onTapped?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('big-emoji-fx'),
      onTap: tap,
      child: AnimatedBuilder(
        animation: c,
        child: widget.child,
        builder: (context, child) {
          final v = c.value;
          if (v == 0 || v == 1) return child!;
          // Heart: two beats. Others: a hop with a little wiggle.
          if (heart) {
            final beat = math.max(0.0, math.sin(v * math.pi * 4)) * (1 - v);
            return Transform.scale(scale: 1 + beat * 0.28, child: child);
          }
          final hop = math.sin(v * math.pi) * (1 - v * 0.4);
          return Transform.translate(
            offset: Offset(0, -hop * 18),
            child: Transform.rotate(
              angle: math.sin(v * math.pi * 6) * 0.18 * (1 - v),
              child: Transform.scale(scale: 1 + hop * 0.15, child: child),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- dice

/// 🎲 🎯 🏀 ⚽ 🎳 🎰 sent alone (218): rolls when it arrives, then shows
/// the result that came from the message's server-given id.
class DiceView extends StatefulWidget {
  const DiceView({super.key, required this.game, required this.value, this.roll = false, this.onTap});
  final String game;
  final int value;
  final bool roll;
  final VoidCallback? onTap;

  @override
  State<DiceView> createState() => _DiceViewState();
}

class _DiceViewState extends State<DiceView> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: Tokens.diceRoll, value: widget.roll ? 0 : 1);

  @override
  void initState() {
    super.initState();
    if (widget.roll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!fxAllowed(context)) {
          c.value = 1;
          return;
        }
        c.forward().whenComplete(() {
          if (mounted && Dice.win(widget.game, widget.value)) playFx(context, MsgFx.byId('party')!, from: centerOf(context));
        });
      });
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  String label(L l) => switch (widget.game) {
    // The die shows its number itself.
    '🎲' => '',
    '🎯' => widget.value == 6 ? l.diceBull : (widget.value == 1 ? l.diceMissed : l.diceScore(widget.value - 1)),
    '🏀' || '⚽' => widget.value >= 4 ? l.diceGoal : l.diceAlmost,
    '🎳' => widget.value == 6 ? l.diceStrike : l.dicePins(widget.value == 1 ? 0 : widget.value - 1 + (widget.value == 5 ? 1 : 0)),
    _ => Dice.win(widget.game, widget.value) ? l.diceJackpot : '',
  };

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return GestureDetector(
      key: Key('dice-${widget.game}'),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) {
          final v = c.value;
          final rolling = v < 1;
          // While rolling the face changes fast, then slows down.
          final shown = rolling ? 1 + ((v * v * 24).floor() * 7 + 3) % (Dice.kinds[widget.game] ?? 6) : widget.value;
          final settle = rolling ? 0.0 : 1.0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: Tokens.diceSize,
                height: Tokens.diceSize,
                child: Transform.rotate(
                  angle: rolling ? (1 - v) * math.pi * 4 : 0,
                  child: Transform.scale(scale: rolling ? 0.85 + 0.15 * math.sin(v * math.pi * 8).abs() : 1, child: face(shown, v, p)),
                ),
              ),
              if (label(l).isNotEmpty)
                AnimatedOpacity(
                  opacity: settle,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label(l),
                    key: const Key('dice-result'),
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: Tokens.semi),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget face(int v, double t, Palette p) => switch (widget.game) {
    '🎲' => CustomPaint(painter: _DieFace(v, p.dark)),
    '🎯' => CustomPaint(painter: _Target(v, t)),
    '🎰' => _Slot(reels: Dice.reels(v), p: p),
    _ => _Ball(game: widget.game, value: widget.value, t: t),
  };
}

class _DieFace extends CustomPainter {
  _DieFace(this.v, this.dark);
  final int v;
  final bool dark;

  static const spots = {
    1: [(0.5, 0.5)],
    2: [(0.27, 0.27), (0.73, 0.73)],
    3: [(0.27, 0.27), (0.5, 0.5), (0.73, 0.73)],
    4: [(0.27, 0.27), (0.73, 0.27), (0.27, 0.73), (0.73, 0.73)],
    5: [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)],
    6: [(0.27, 0.25), (0.73, 0.25), (0.27, 0.5), (0.73, 0.5), (0.27, 0.75), (0.73, 0.75)],
  };

  @override
  void paint(Canvas c, Size s) {
    final r = Rect.fromLTWH(s.width * 0.12, s.height * 0.12, s.width * 0.76, s.height * 0.76);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 4)), Radius.circular(s.width * 0.16)), Paint()..color = const Color(0x22000000));
    c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(s.width * 0.16)),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFE9E9EE)]).createShader(r),
    );
    if (dark) c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(s.width * 0.16)), Paint()..color = const Color(0x14000000));
    final pip = Paint()..color = v == 1 ? Palette.tileRed : const Color(0xFF1C1C1E);
    for (final (x, y) in spots[v] ?? const <(double, double)>[]) {
      c.drawCircle(Offset(r.left + r.width * x, r.top + r.height * y), r.width * (v == 1 ? 0.12 : 0.085), pip);
    }
  }

  @override
  bool shouldRepaint(_DieFace o) => o.v != v || o.dark != dark;
}

class _Target extends CustomPainter {
  _Target(this.v, this.t);
  final int v;
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final rad = s.width * 0.42;
    for (var i = 0; i < 5; i++) {
      c.drawCircle(o, rad * (1 - i * 0.2), Paint()..color = i.isEven ? Palette.tileRed : const Color(0xFFFFFFFF));
    }
    if (t < 1) return;
    // Where the dart landed: 6 = middle, 1 = off the board.
    final d = v == 1 ? rad * 1.12 : rad * (6 - v) * 0.2 + rad * 0.05;
    final at = o + Offset(math.cos(v * 1.7) * d, math.sin(v * 1.7) * d);
    c.drawLine(
      at,
      at + const Offset(14, -14),
      Paint()
        ..color = const Color(0xFF1C1C1E)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(at, 4, Paint()..color = Palette.tileBlue);
  }

  @override
  bool shouldRepaint(_Target o) => o.v != v || (o.t < 1) != (t < 1);
}

class _Slot extends StatelessWidget {
  const _Slot({required this.reels, required this.p});
  final List<String> reels;
  final Palette p;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(Tokens.radius[2]),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in reels)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(r, style: TextStyle(fontSize: 30, height: 1, fontFamilyFallback: Tokens.emojiFallback)),
              ),
          ],
        ),
      ),
    ),
  );
}

/// 🏀 ⚽ 🎳: the ball flies toward the goal / pins, in or not.
class _Ball extends StatelessWidget {
  const _Ball({required this.game, required this.value, required this.t});
  final String game;
  final int value;
  final double t;

  @override
  Widget build(BuildContext context) {
    final hit = game == '🎳' ? value >= 5 : value >= 4;
    final q = Curves.easeOut.transform(t);
    // Misses drift to the side at the end.
    final dx = hit ? 0.0 : (value.isEven ? 1 : -1) * 26 * q;
    final ball = game == '🎳' ? '🎳' : game;
    return Stack(
      alignment: Alignment.center,
      children: [
        if (game == '⚽')
          Positioned(
            top: 4,
            child: Text('🥅', style: TextStyle(fontSize: 40, height: 1, fontFamilyFallback: Tokens.emojiFallback)),
          ),
        if (game == '🏀') const Positioned(top: 2, width: 64, height: 44, child: CustomPaint(painter: _Hoop())),
        Positioned(
          bottom: 6 + q * (game == '🎳' ? 8 : 52),
          left: 0,
          right: 0,
          child: Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: game == '🎳' ? 1.4 : 1 - q * 0.35,
              child: Text(
                ball,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 38, height: 1, fontFamilyFallback: Tokens.emojiFallback),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Backboard and orange ring for 🏀 (there is no hoop emoji).
class _Hoop extends CustomPainter {
  const _Hoop();

  @override
  void paint(Canvas c, Size s) {
    final board = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height * 0.7), const Radius.circular(4));
    c.drawRRect(board, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRRect(
      board,
      Paint()
        ..color = const Color(0xFFD1D1D6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawRect(
      Rect.fromLTWH(s.width * 0.32, s.height * 0.2, s.width * 0.36, s.height * 0.32),
      Paint()
        ..color = Palette.tileRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    c.drawOval(
      Rect.fromLTWH(s.width * 0.22, s.height * 0.62, s.width * 0.56, s.height * 0.22),
      Paint()
        ..color = Palette.tileOrange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Hoop o) => false;
}
