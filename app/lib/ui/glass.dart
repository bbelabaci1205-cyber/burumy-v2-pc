// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Glass pieces of the main screens (Eric's v1 look, 2026-11-24): round glass
// buttons, a top bar with a small centred title, and the floating tab bar.
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import 'common.dart';
import 'scroll_edge.dart';

/// Frosted fill used by the round buttons and the tab bar.
/// iOS 27: lighter glass in both modes (dark glass is lighter than in 26).
Color glassFill(Palette p) => switch (Glass.level) {
  'clear' => p.dark ? const Color(0x5C3A3A3C) : const Color(0x73FFFFFF),
  'solid' => p.dark ? const Color(0xFF2C2C2E) : const Color(0xFFFFFFFF),
  _ => p.dark ? const Color(0x993A3A3C) : const Color(0xB8FFFFFF),
};

/// Settings > Appearance > Glass: 'clear', 'normal' or 'solid' (power
/// saving also makes it solid). Set by the app on every rebuild.
class Glass {
  static String level = 'normal';
}

/// iOS 27 Liquid Glass surface (measured from iPhone screenshots,
/// 2026-11-24): the page shows through (blur + light tint), a clearly drawn
/// thin edge instead of a heavy shadow, a bright highlight along the top and
/// only a faint shadow underneath. Used by every glass control.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({super.key, required this.radius, required this.child, this.shadow = true});
  final double radius;
  final Widget child;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow ? [BoxShadow(color: Color(p.dark ? 0x2E000000 : 0x0D000000), blurRadius: 10, offset: const Offset(0, 2))] : null,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: CustomPaint(
            foregroundPainter: _Rim(radius, p.dark),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: glassFill(p),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(p.dark ? 0x14FFFFFF : 0x40FFFFFF), const Color(0x00FFFFFF)],
                  stops: const [0, 0.55],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The iOS 27 glass edge (hairline + top highlight) around any rounded box.
extension GlassEdge on Widget {
  Widget glassEdge({required double radius}) => Builder(
    builder: (c) => CustomPaint(foregroundPainter: _Rim(radius, paletteOf(c).dark), child: this),
  );
}

class _Rim extends CustomPainter {
  _Rim(this.radius, this.dark);
  final double radius;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // The defined edge (iOS 27): a hairline that separates glass from the page.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = dark ? const Color(0x33FFFFFF) : const Color(0x3D000000);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(0.3), Radius.circular(radius)), edge);
    // Bright highlight just inside, strongest at the top.
    final shine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dark ? const [Color(0x66FFFFFF), Color(0x0AFFFFFF), Color(0x1FFFFFFF)] : const [Color(0xFFFFFFFF), Color(0x40FFFFFF), Color(0x99FFFFFF)],
      ).createShader(rect);
    canvas.drawRRect(RRect.fromRectAndRadius(rect.deflate(1.1), Radius.circular((radius - 1).clamp(0, radius))), shine);
  }

  @override
  bool shouldRepaint(_Rim old) => old.dark != dark || old.radius != radius;
}

/// Round glass button (44 pt) for the top bars.
/// iOS 27 confirm button: filled accent circle with a white tick.
class AccentCircle extends StatelessWidget {
  const AccentCircle({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: Tokens.closeButton,
        height: Tokens.closeButton,
        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
        child: Icon(icon, size: Tokens.closeIcon, color: p.onAccent),
      ),
    );
  }
}

class GlassCircle extends StatelessWidget {
  const GlassCircle({super.key, required this.child, this.onTap, this.size = 44});
  final Widget child;
  final VoidCallback? onTap;
  final double size;

  /// The usual icon look inside a [GlassCircle].
  static Widget icon(BuildContext context, IconData i, {double size = 22}) => Icon(i, size: size, color: paletteOf(context).label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LiquidGlass(
        radius: size / 2,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Round glass back button for the left of a navigation bar (Telegram /
/// iOS 26 look); a cross on full-screen sheets.
class GlassBack extends StatelessWidget {
  const GlassBack({super.key, this.close = false});
  final bool close;

  @override
  Widget build(BuildContext context) => GlassCircle(
    key: const Key('back'),
    onTap: () => Navigator.of(context).maybePop(),
    child: GlassCircle.icon(context, close ? CupertinoIcons.xmark : CupertinoIcons.chevron_back),
  );
}

/// Confirm button of an iOS 26+ sheet: a filled accent circle with a white
/// check mark (dimmed while there is nothing to save).
class GlassDone extends StatelessWidget {
  const GlassDone({super.key, this.onTap, this.size = 44});
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: onTap == null ? p.accent.withValues(alpha: 0.35) : p.accent, shape: BoxShape.circle),
        child: const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFFFFFFFF), size: 22),
      ),
    );
  }
}

/// Glass capsule with a short word (for example "편집"), 44 pt tall.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.text, this.onTap});
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LiquidGlass(
        radius: 22,
        child: Container(
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          // Hug the word even where the parent offers the whole bar width.
          child: Center(
            widthFactor: 1,
            child: Text(text, maxLines: 1, style: Tokens.body.style.copyWith(color: p.label)),
          ),
        ),
      ),
    );
  }
}

/// Top bar (iOS 27): round glass buttons on both sides and a semibold
/// title in the middle. Clear while the page is at the top; once content
/// scrolls under it, it turns into frosted glass with a hairline (iOS 27's
/// default "hard" scroll edge, measured from iPhone screenshots).
class GlassTopBar extends StatefulWidget implements ObstructingPreferredSizeWidget {
  const GlassTopBar({
    super.key,
    this.title,
    this.middle,
    this.leading = const [],
    this.trailing = const [],
    this.back = false,
    this.tint,
    this.titleOnScroll = false,
    this.full,
  });

  /// Fills the whole bar instead of the left / middle / right layout (for
  /// example the in-chat search field with its round X).
  final Widget? full;

  /// Same arguments as CupertinoNavigationBar, so every page uses this bar.
  factory GlassTopBar.nav({Key? key, Widget? leading, Widget? middle, Widget? trailing, Color? backgroundColor, Border? border}) => GlassTopBar(
    key: key,
    middle: middle == null
        ? null
        : Builder(
            builder: (c) => DefaultTextStyle(
              style: Tokens.body.style.copyWith(color: paletteOf(c).label, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: middle,
            ),
          ),
    leading: [?leading],
    trailing: [?trailing],
    tint: backgroundColor,
  );

  /// Page colour behind the bar.
  final Color? tint;
  final String? title;

  /// Anything other than a plain title (for example a segmented control).
  final Widget? middle;
  final List<Widget> leading;
  final List<Widget> trailing;

  /// Show the round back button first on the left.
  final bool back;

  /// The page shows its own big title: the bar's small one appears only
  /// once the page scrolls (iOS large-title pages).
  final bool titleOnScroll;

  static const height = 60.0;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  bool shouldFullyObstruct(BuildContext context) => false;

  @override
  State<GlassTopBar> createState() => _GlassTopBarState();
}

class _GlassTopBarState extends State<GlassTopBar> {
  ValueNotifier<bool>? under;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    under = ScrollEdge.of(context);
  }

  Widget title(Palette p) => Text(
    widget.title ?? '',
    key: const Key('bar-title'),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final w = widget;
    final top = MediaQuery.paddingOf(context).top;
    final left = [
      if (w.back)
        GlassCircle(key: const Key('back'), onTap: () => Navigator.of(context).maybePop(), child: GlassCircle.icon(context, CupertinoIcons.chevron_back)),
      ...w.leading,
    ];
    Widget side(List<Widget> items) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[if (i > 0) SizedBox(width: Tokens.space[1]), items[i]],
      ],
    );
    final bar = Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], top, Tokens.space[3], 0),
      child: SizedBox(
        height: GlassTopBar.height,
        child: w.full != null
            ? Center(child: w.full)
            : Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 96),
                    child: Center(
                      child:
                          w.middle ??
                          (w.titleOnScroll && under != null
                              ? ValueListenableBuilder<bool>(
                                  valueListenable: under!,
                                  builder: (_, on, t) => AnimatedOpacity(opacity: on ? 1 : 0, duration: const Duration(milliseconds: 180), child: t),
                                  child: title(p),
                                )
                              : title(p)),
                    ),
                  ),
                  Align(alignment: Alignment.centerLeft, child: side(left)),
                  Align(alignment: Alignment.centerRight, child: side(w.trailing)),
                ],
              ),
      ),
    );
    final flag = under;
    Widget frost(bool on) => IgnorePointer(
      child: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Glass.level == 'solid'
                    ? (p.dark ? const Color(0xFF1C1C1E) : const Color(0xFFFCFCFE))
                    : Glass.level == 'clear'
                    ? (p.dark ? const Color(0xA61C1C1E) : const Color(0xB3FCFCFE))
                    : (p.dark ? const Color(0xD91C1C1E) : const Color(0xE6FCFCFE)),
                border: Border(bottom: BorderSide(color: p.dark ? const Color(0x33FFFFFF) : const Color(0x24000000), width: 0.5)),
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      height: top + GlassTopBar.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (flag != null) ValueListenableBuilder<bool>(valueListenable: flag, builder: (_, on, _) => frost(on)),
          bar,
        ],
      ),
    );
  }
}

class GlassTab {
  const GlassTab(this.icon, this.activeIcon, this.label, {this.key});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Key? key;
}

/// Floating capsule tab bar; the chosen tab sits on a lifted pill.
class FloatingTabBar extends StatelessWidget {
  const FloatingTabBar({super.key, required this.tabs, required this.index, required this.onTap});
  final List<GlassTab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  /// iOS 27 tab bar: 63 pt capsule, selected tab on a soft grey pill.
  static const height = 63.0;

  /// iOS 27 / Telegram: the capsule sits 21 pt from the side edges and,
  /// on phones with a home bar, 21 pt from the bottom edge (over the home
  /// indicator's safe area, not above it). No home bar: a small gap.
  static const edge = 21.0;
  static double bottomGap(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return safe > 0 ? edge : Tokens.space[2];
  }

  /// Room the pages keep free at the bottom for the bar.
  static double room(BuildContext context) => height + bottomGap(context);

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final pill = p.dark ? const Color(0x33FFFFFF) : const Color(0x14000000);
    return Padding(
      padding: EdgeInsets.fromLTRB(edge, 0, edge, bottomGap(context)),
      child: SizedBox(
        height: height,
        child: LiquidGlass(
          radius: height / 2,
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: GestureDetector(
                      key: tabs[i].key,
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(color: i == index ? pill : const Color(0x00FFFFFF), borderRadius: BorderRadius.circular((height - 8) / 2)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(i == index ? tabs[i].activeIcon : tabs[i].icon, size: Tokens.tabIcon, color: i == index ? p.accent : p.label),
                            const SizedBox(height: 2),
                            Text(tabs[i].label, style: Tokens.tabLabel.style.copyWith(fontSize: 11, color: i == index ? p.accent : p.label)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
