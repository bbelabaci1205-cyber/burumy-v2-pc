// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Appearance > App icon (Burumy v1): four looks of the bubble
// mark, the six characters and five other Burumy logos (v1 art, re-coloured
// to the bright brand green). Android swaps the launcher alias; the choice
// is kept on the phone.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class AppIconPicker extends StatelessWidget {
  const AppIconPicker({super.key});

  static bool get supported => preview || (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  /// Look-only demo: shows the picker on the web too (picking does nothing).
  static bool preview = false;
  static const _channel = MethodChannel('app.burumy/icon');
  static const marks = ['green', 'dark', 'light', 'mint'];
  static const characters = ['buru', 'dugi', 'rumi', 'mongi', 'duru', 'burumi'];
  static const logos = ['logo_burrow', 'logo_buzz', 'logo_closedeye', 'logo_lineb', 'logo_nest'];
  static const ids = [...marks, ...characters, ...logos];

  static String label(L l, String id) => switch (id) {
    'dark' => l.appIconDark,
    'light' => l.appIconLight,
    'mint' => l.appIconMint,
    'buru' => l.pack_buru,
    'dugi' => l.pack_dugi,
    'rumi' => l.pack_rumi,
    'mongi' => l.pack_mongi,
    'duru' => l.pack_duru,
    'burumi' => l.pack_burumi,
    _ when id.startsWith('logo_') => l.appIconLogo(const ['A', 'B', 'C', 'E', 'F'][logos.indexOf(id)]),
    _ => l.appIconGreen,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final now = s.pref('app_icon', 'green');
    Widget tile(String id) => GestureDetector(
      key: Key('app-icon-$id'),
      onTap: () async {
        if (id == now) return;
        await s.setPref('app_icon', id == 'green' ? '' : id);
        try {
          await _channel.invokeMethod('set', id);
        } on PlatformException catch (_) {
        } on MissingPluginException catch (_) {}
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: id == now ? p.accent : const Color(0x00000000), width: 2.5),
              ),
            ),
            child: ClipRSuperellipse(
              borderRadius: BorderRadius.circular(14),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: p.separator),
                  ),
                ),
                child: Image.asset('assets/app_icons/$id.png', width: 60, height: 60),
              ),
            ),
          ),
          SizedBox(height: Tokens.space[1]),
          Text(label(l, id), style: Tokens.caption.style.copyWith(color: id == now ? p.accent : p.secondaryLabel)),
        ],
      ),
    );
    Widget group(String title, List<String> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: Tokens.space[1], bottom: Tokens.space[2]),
          child: Text(title, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
        // Four to a row, like the first row.
        LayoutBuilder(
          builder: (context, box) => Wrap(
            runSpacing: Tokens.space[3],
            children: [
              for (final id in list)
                SizedBox(
                  width: box.maxWidth / 4,
                  child: Center(child: tile(id)),
                ),
            ],
          ),
        ),
      ],
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[3]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          group(l.appIconMarks, marks),
          SizedBox(height: Tokens.space[4]),
          group(l.appIconCharacters, characters),
          SizedBox(height: Tokens.space[4]),
          group(l.appIconLogos, logos),
        ],
      ),
    );
  }
}
