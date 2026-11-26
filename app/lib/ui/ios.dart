// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// iOS 27 list cards and switches, measured from real iPhone screenshots
// (Settings, Apple Account, Phone, Messages; 2026-11-24, iPhone at 3x):
//  - cards: 16 pt from the screen edges, 26 pt smooth (superellipse) corners
//  - rows: 52 pt tall; separators start where the text starts and stop
//    20 pt before the card's right edge; light grey, 1 pt
//  - 35 pt between cards
//  - switch: 63 x 28 pt track with a wide 37 x 24 pt capsule knob
import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import 'common.dart';
import 'settings_kit.dart';

/// One iOS 27 inset grouped card of rows, with an optional title above and
/// note below. Same shape of arguments as CupertinoListSection.insetGrouped.
/// iOS 27 Settings row: tile 18pt in from the card edge, text 14pt after
/// the tile (so it starts where the separator starts, 60pt in), chevron
/// 17pt from the right (measured from Eric's iPhone, 2026-11-25).
/// Rows without an icon keep their text 20pt in.
class IosTile extends CupertinoListTile {
  IosTile({
    super.key,
    required Widget title,
    super.subtitle,
    super.additionalInfo,
    super.leading,
    super.trailing,
    super.onTap,
    super.backgroundColor,
    super.backgroundColorActivated,
    EdgeInsetsGeometry? padding,
    super.leadingSize,
    super.leadingToTitle = gap,
  }) : super(
         // iOS row titles are a little heavier than Pretendard Regular:
         // measured ink sits between 400 and 500, nearer 500.
         title: DefaultTextStyle.merge(
           style: const TextStyle(fontWeight: FontWeight.w500),
           child: title,
         ),
         padding: padding ?? (leading == null ? plainPad : iconedPad),
       );

  static const gap = 14.0;
  static const plainPad = EdgeInsetsDirectional.only(start: 20, end: 17);
  static const iconedPad = EdgeInsetsDirectional.only(start: 18, end: 17);
}

/// Row chevron in the iOS 27 Settings grey.
class IosChevron extends StatelessWidget {
  const IosChevron({super.key});

  @override
  Widget build(BuildContext context) => Icon(CupertinoIcons.right_chevron, size: Tokens.body.size, color: paletteOf(context).chevron);
}

class IosSection extends StatelessWidget {
  const IosSection({super.key, required this.children, this.header, this.footer, this.hasLeading = true, this.margin, this.backgroundColor});
  final List<Widget> children;
  final Widget? header;
  final Widget? footer;

  /// Rows start with an icon: separators then start at the text (60 pt).
  final bool hasLeading;
  final EdgeInsetsGeometry? margin;

  /// Card colour (default: the palette's card colour).
  final Color? backgroundColor;

  static const sideMargin = 16.0, radius = 26.0, rowHeight = 52.0, gap = 35.0;

  /// Does this row start with an icon? (The separator above it then starts
  /// at the text, else 20 pt in.)
  bool _iconed(Widget row) => switch (row) {
    CupertinoListTile t => t.leading != null,
    NavRow r => r.icon != null,
    PrefSwitch r => r.icon != null,
    _ => hasLeading,
  };

  /// Rows with a bigger photo (member lists, 40 pt) push the text right.
  double _wider(Widget row) => row is CupertinoListTile && row.leadingSize > 28 ? row.leadingSize - 28 : 0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final line = p.dark ? const Color(0xFF38383A) : const Color(0xFFE6E6E8);
    final shape = RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius));
    final transparent = backgroundColor != null && backgroundColor!.a == 0;
    final card = transparent ? null : (backgroundColor ?? p.card);
    final rows = <Widget>[
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0)
          Container(
            height: 1,
            margin: EdgeInsetsDirectional.only(start: _iconed(children[i]) ? 60 + _wider(children[i]) : 20, end: 20),
            color: line,
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: rowHeight),
          child: children[i],
        ),
      ],
    ];
    return Padding(
      padding: margin ?? EdgeInsets.fromLTRB(sideMargin, header == null ? gap : Tokens.space[4], sideMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, Tokens.groupTitleToCard + 2), child: header),
          if (children.isNotEmpty)
            ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: DecoratedBox(
                decoration: ShapeDecoration(shape: shape, color: card),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: rows),
              ),
            ),
          if (footer != null) Padding(padding: EdgeInsets.fromLTRB(20, Tokens.cardToFooter, 20, 0), child: footer),
        ],
      ),
    );
  }
}

/// iOS 27 switch: wide track and a capsule knob that slides across.
class IosSwitch extends StatelessWidget {
  const IosSwitch({super.key, required this.value, required this.onChanged, this.activeTrackColor});
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeTrackColor;

  static const width = 63.0, height = 28.0, knobWidth = 37.0, knobHeight = 24.0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final on = activeTrackColor ?? p.accent;
    final off = p.dark ? const Color(0xFF39393D) : const Color(0xFFC5C5C7);
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        onHorizontalDragEnd: enabled
            ? (d) {
                final v = d.primaryVelocity ?? 0;
                if (v > 0 && !value) onChanged!(true);
                if (v < 0 && value) onChanged!(false);
              }
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: value ? on : off, borderRadius: BorderRadius.circular(height / 2)),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knobWidth,
                height: knobHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(knobHeight / 2),
                  boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 1.5))],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS 26/27 segmented control: a soft capsule track and a white capsule
/// that slides to the chosen part. Same arguments as
/// CupertinoSlidingSegmentedControl.
class IosSegmented<T extends Object> extends StatelessWidget {
  const IosSegmented({super.key, required this.children, required this.groupValue, required this.onValueChanged});
  final Map<T, Widget> children;
  final T? groupValue;
  final ValueChanged<T?> onValueChanged;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final keys = children.keys.toList();
    final at = groupValue == null ? -1 : keys.indexOf(groupValue as T);
    return LayoutBuilder(
      builder: (context, outer) => Container(
        width: outer.hasBoundedWidth ? null : 110.0 * keys.length,
        height: 36,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: p.dark ? const Color(0x3D767680) : const Color(0x1F767680), borderRadius: BorderRadius.circular(18)),
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth / keys.length;
            return Stack(
              children: [
                if (at >= 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: w * at,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: p.dark ? const Color(0xFF636366) : const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < keys.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onValueChanged(keys[i]),
                          child: Center(
                            child: DefaultTextStyle(
                              style: Tokens.preview.style.copyWith(color: p.label, fontWeight: i == at ? FontWeight.w600 : FontWeight.w400),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: children[keys[i]]!,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// iOS 26/27 action sheet: one floating rounded card of choices and a
/// separate "cancel" card, both with the soft glass edge. Same arguments as
/// CupertinoActionSheet (the actions are CupertinoActionSheetAction).
class IosActionSheet extends StatelessWidget {
  const IosActionSheet({super.key, this.title, this.message, this.actions = const [], this.cancelButton});
  final Widget? title;
  final Widget? message;
  final List<Widget> actions;
  final Widget? cancelButton;

  static const radius = 30.0;

  /// Draws a CupertinoActionSheetAction as our own row (that widget only
  /// reacts to taps inside Flutter's own sheet).
  Widget _row(BuildContext context, Widget w, {bool cancel = false}) {
    if (w is! CupertinoActionSheetAction) return w;
    final accent = CupertinoTheme.of(context).primaryColor;
    return _SheetRow(
      key: w.key,
      onTap: w.onPressed,
      child: DefaultTextStyle(
        style: Tokens.body.style.copyWith(
          fontSize: 18,
          color: w.isDestructiveAction ? const Color(0xFFFF3B30) : accent,
          fontWeight: w.isDefaultAction || cancel ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
        child: w.child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Works without the app's palette too (dialogs from small widgets).
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final grey = CupertinoColors.secondaryLabel.resolveFrom(context);
    final fill = dark ? const Color(0xF22C2C2E) : const Color(0xF7FFFFFF);
    final line = dark ? const Color(0xFF38383A) : const Color(0xFFE6E6E8);
    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: dark ? const Color(0x33FFFFFF) : const Color(0x1F000000), width: 0.5),
    );
    Widget card(List<Widget> rows) => DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        color: fill,
        shadows: const [BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, 8))],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
      ),
    );
    final head = <Widget>[
      if (title != null || message != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            children: [
              if (title != null)
                DefaultTextStyle(
                  style: Tokens.caption.style.copyWith(color: grey, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  child: title!,
                ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: DefaultTextStyle(
                    style: Tokens.caption.style.copyWith(color: grey),
                    textAlign: TextAlign.center,
                    child: message!,
                  ),
                ),
            ],
          ),
        ),
    ];
    final rows = <Widget>[
      ...head,
      for (var i = 0; i < actions.length; i++) ...[if (i > 0 || head.isNotEmpty) Container(height: 0.5, color: line), _row(context, actions[i])],
    ];
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(child: SingleChildScrollView(child: card(rows))),
            if (cancelButton != null) ...[
              const SizedBox(height: 8),
              card([_row(context, cancelButton!, cancel: true)]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatefulWidget {
  const _SheetRow({super.key, required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_SheetRow> createState() => _SheetRowState();
}

class _SheetRowState extends State<_SheetRow> {
  bool down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => down = true),
    onTapCancel: () => setState(() => down = false),
    onTapUp: (_) => setState(() => down = false),
    onTap: widget.onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      constraints: const BoxConstraints(minHeight: 57),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: down ? const Color(0x14000000) : const Color(0x00000000),
      child: widget.child,
    ),
  );
}
