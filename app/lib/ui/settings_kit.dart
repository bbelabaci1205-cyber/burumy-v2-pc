// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Building blocks of the Settings screens (iOS Settings look, Telegram
// layout): page frame, header card, switch rows and choice rows that read
// and write the on-device settings kept in AppState.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'wide.dart';

/// A settings sub-page: grey grouped background, glass top bar with a back
/// button and a small title, rows scrolling underneath.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({super.key, required this.title, required this.children, this.trailing = const []});
  final String title;
  final List<Widget> children;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    // PC app: kept to a readable width in the right pane, wherever it was opened from.
    return WidePage(
      child: CupertinoPageScaffold(
        backgroundColor: p.background,
        // iOS 27: with a header card the small title only shows once the
        // card scrolls under the bar.
        navigationBar: GlassTopBar(
          title: title,
          back: true,
          trailing: trailing,
          tint: p.background,
          titleOnScroll: children.isNotEmpty && children.first is HeaderCard,
        ),
        child: ListView(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height, bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5]),
          children: children,
        ),
      ),
    );
  }
}

/// One card of rows (iOS inset grouped list).
Widget group(BuildContext context, List<Widget> rows, {String? header, String? footer, bool error = false}) => IosSection(
  header: header == null ? null : sectionHeader(context, header),
  footer: footer == null ? null : sectionFooter(context, footer, error: error),
  children: rows,
);

/// The card at the top of a settings page: big icon, title, one line.
class HeaderCard extends StatelessWidget {
  const HeaderCard({super.key, required this.color, required this.icon, required this.title, required this.body});
  final Color color;
  final IconData icon;
  final String title;
  final String body;

  /// v1 look (Eric 2026-11-25): big tile, title and words on the left.
  static const tile = 60.0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4] + Tokens.space[0], Tokens.space[3], 0),
      padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[3], Tokens.space[3] + Tokens.space[0], Tokens.space[3]),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: tile,
            height: tile,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Tokens.radius[2])),
            child: Icon(icon, size: 34, color: const Color(0xFFFFFFFF)),
          ),
          // iOS 27 Settings (일반, 손쉬운 사용): 22 semibold title, 17 words.
          SizedBox(height: Tokens.space[2] + Tokens.space[0]),
          Text(title, style: Tokens.headerTitle.style.copyWith(color: p.label)),
          SizedBox(height: Tokens.space[0]),
          Text(body, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
        ],
      ),
    );
  }
}

/// A row that opens another page.
class NavRow extends StatelessWidget {
  const NavRow({super.key, this.color, this.icon, required this.title, this.subtitle, this.value, this.page, this.onTap, this.danger = false});
  final Color? color;
  final IconData? icon;
  final String title;

  /// Small grey line under the title (Telegram: "11개 예외").
  final String? subtitle;
  final String? value;
  final WidgetBuilder? page;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return IosTile(
      leading: icon == null ? null : iconTile(color ?? Palette.tileGrey, icon!),
      title: Text(title, style: danger ? const TextStyle(color: Palette.tileRed) : null),
      subtitle: subtitle == null ? null : Text(subtitle!),
      additionalInfo: value == null ? null : Text(value!),
      trailing: page == null && onTap == null || danger ? null : const IosChevron(),
      onTap: onTap ?? (page == null ? null : () => Navigator.of(context).push(IosPageRoute(builder: page!))),
    );
  }
}

/// A switch kept in the on-device settings ("1" / "0").
class PrefSwitch extends StatelessWidget {
  const PrefSwitch(this.prefKey, {super.key, required this.title, this.subtitle, this.color, this.icon, this.fallback = false, this.onChanged});
  final String prefKey;
  final String title;
  final String? subtitle;
  final Color? color;
  final IconData? icon;
  final bool fallback;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return IosTile(
      leading: icon == null ? null : iconTile(color ?? Palette.tileGrey, icon!),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 2, style: Tokens.caption.style),
      trailing: IosSwitch(
        key: Key('pref-$prefKey'),
        value: s.on(prefKey, fallback: fallback),
        activeTrackColor: paletteOf(context).accent,
        onChanged: (v) {
          s.setOn(prefKey, v);
          onChanged?.call(v);
        },
      ),
    );
  }
}

/// A row with a value picked on its own page (checkmark list).
class PrefChoice extends StatelessWidget {
  const PrefChoice(this.prefKey, {super.key, required this.title, required this.options, required this.fallback, this.color, this.icon, this.footer});
  final String prefKey;
  final String title;
  final List<(String, String)> options;
  final String fallback;
  final Color? color;
  final IconData? icon;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = s.pref(prefKey, fallback);
    final label = options.where((o) => o.$1 == now).firstOrNull?.$2 ?? options.first.$2;
    return NavRow(
      key: Key('choice-$prefKey'),
      color: color,
      icon: icon,
      title: title,
      value: label,
      page: (c) => ChoicePage(title: title, options: options, value: () => s.pref(prefKey, fallback), footer: footer, onPick: (v) => s.setPref(prefKey, v)),
    );
  }
}

/// One choice out of a few, iOS checkmark list.
class ChoicePage extends StatelessWidget {
  const ChoicePage({super.key, required this.title, required this.options, required this.value, required this.onPick, this.header, this.footer, this.card});
  final String title;

  /// Optional explanation card on top (v1 look).
  final Widget? card;
  final List<(String, String)> options;
  final String Function() value;
  final ValueChanged<String> onPick;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // rebuild when settings change
    final now = value();
    return SettingsScaffold(
      title: title,
      children: [
        ?card,
        group(context, header: header, footer: footer, [
          for (final (v, label) in options)
            IosTile(
              key: Key('pick-$v'),
              title: Text(label),
              trailing: v == now ? Icon(CupertinoIcons.check_mark, color: paletteOf(context).accent, size: 20) : null,
              onTap: () => onPick(v),
            ),
        ]),
      ],
    );
  }
}
