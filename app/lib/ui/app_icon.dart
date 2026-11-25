// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Appearance > App icon (Burumy v1): four looks of the bubble
// mark. Android swaps the launcher alias; the choice is kept on the phone.
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class AppIconPicker extends StatelessWidget {
  const AppIconPicker({super.key});

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static const _channel = MethodChannel('app.burumy/icon');
  static const ids = ['green', 'dark', 'light', 'mint'];

  static String label(L l, String id) => switch (id) {
    'dark' => l.appIconDark,
    'light' => l.appIconLight,
    'mint' => l.appIconMint,
    _ => l.appIconGreen,
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final now = s.pref('app_icon', 'green');
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[3]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final id in ids)
            GestureDetector(
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
            ),
        ],
      ),
    );
  }
}
