// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 야간 모드 빠른 전환 (Telegram tip 180): iPhone does not use Telegram's
// spreading circle, so the old screen is kept as a picture and fades away
// over the new colours (a soft cross-fade, like iOS Display switching).
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../design/tokens.dart';

class ThemeFade extends StatefulWidget {
  const ThemeFade({super.key, required this.child});
  final Widget child;

  static _ThemeFadeState? _live;

  /// Runs [change] (which flips day/night) with the fade. Without the
  /// widget, or with reduced motion, it only runs [change].
  static Future<void> run(Future<void> Function() change) async {
    final s = _live;
    if (s == null || !s.mounted) return change();
    return s._run(change);
  }

  @override
  State<ThemeFade> createState() => _ThemeFadeState();
}

class _ThemeFadeState extends State<ThemeFade> with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final _fade = AnimationController(vsync: this, duration: Tokens.themeFade);
  ui.Image? _shot;

  @override
  void initState() {
    super.initState();
    ThemeFade._live = this;
  }

  @override
  void dispose() {
    if (ThemeFade._live == this) ThemeFade._live = null;
    _fade.dispose();
    _shot?.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() change) async {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return change();
    ui.Image? img;
    try {
      final r = _boundary.currentContext?.findRenderObject();
      if (r is RenderRepaintBoundary) img = await r.toImage(pixelRatio: MediaQuery.devicePixelRatioOf(context));
    } catch (_) {}
    await change();
    if (img == null || !mounted) return img?.dispose();
    _shot?.dispose();
    setState(() => _shot = img);
    unawaited(
      _fade.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        final old = _shot;
        setState(() => _shot = null);
        old?.dispose();
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(
    textDirection: TextDirection.ltr,
    children: [
      RepaintBoundary(key: _boundary, child: widget.child),
      if (_shot case final shot?)
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: ReverseAnimation(CurvedAnimation(parent: _fade, curve: Curves.easeInOut)),
              child: RawImage(key: const Key('theme-fade'), image: shot, fit: BoxFit.fill),
            ),
          ),
        ),
    ],
  );
}
