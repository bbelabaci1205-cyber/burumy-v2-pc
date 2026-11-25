// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Opening web links: inside Burumy (the phone's own private browser view)
// or in the default browser, with sites that always go to the browser
// (Settings > Privacy > Open links, Telegram-style).
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'wide.dart';

/// Sites the person never wants opened inside the app.
List<String> neverInApp(AppState s) => s.pref('link_never', '').split(',').where((x) => x.isNotEmpty).toList();

/// Opens [url] the way Settings > Privacy > Open links says.
Future<bool> openWebLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final s = AppScope.read(context);
  final host = uri.host.toLowerCase();
  final never = neverInApp(s).any((h) => host == h || host.endsWith('.$h'));
  final inApp = !kIsWeb && s.pref('link_open', 'in_app') == 'in_app' && !never && (uri.scheme == 'https' || uri.scheme == 'http');
  if (inApp && await supportsLaunchMode(LaunchMode.inAppBrowserView)) {
    return launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Settings > Privacy > Open links.
class WebBrowserPage extends StatelessWidget {
  const WebBrowserPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final now = s.pref('link_open', 'in_app');
    final sites = neverInApp(s);
    Widget choice(String v, IconData icon, Color c, String title) => CupertinoListTile(
      key: Key('link-open-$v'),
      leading: iconTile(c, icon),
      title: Text(title),
      trailing: now == v ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
      onTap: () => s.setPref('link_open', v),
    );
    return SettingsScaffold(
      title: l.linkOpenTitle,
      children: [
        group(context, header: l.linkOpenHeader, footer: l.linkOpenInfo, [
          choice('in_app', CupertinoIcons.lock_shield_fill, p.tileGreen, l.linkOpenInApp),
          choice('browser', CupertinoIcons.compass_fill, Palette.tileBlue, l.linkOpenBrowser),
        ]),
        group(context, header: l.linkNeverHeader, footer: l.linkNeverInfo, [
          CupertinoListTile(
            key: const Key('link-never-add'),
            leading: Icon(CupertinoIcons.add, color: p.accent),
            title: Text(l.linkNeverAdd, style: TextStyle(color: p.accent)),
            onTap: () => paneNav(context).push(IosPageRoute<void>(builder: (_) => const _AddSitePage())),
          ),
          for (final h in sites)
            CupertinoListTile(
              key: Key('link-never-$h'),
              title: Text(h),
              trailing: GestureDetector(
                key: Key('link-never-drop-$h'),
                onTap: () => s.setPref('link_never', [...sites..remove(h)].join(',')),
                child: Icon(CupertinoIcons.minus_circle, color: p.secondaryLabel, size: 22),
              ),
            ),
        ]),
      ],
    );
  }
}

/// Type a site (full screen, no popup), saved as its bare host name.
class _AddSitePage extends StatefulWidget {
  const _AddSitePage();
  @override
  State<_AddSitePage> createState() => _AddSitePageState();
}

class _AddSitePageState extends State<_AddSitePage> {
  final c = TextEditingController();

  String? get host {
    var t = c.text.trim().toLowerCase();
    if (t.isEmpty) return null;
    if (!t.contains('://')) t = 'https://$t';
    final h = Uri.tryParse(t)?.host ?? '';
    final bare = h.startsWith('www.') ? h.substring(4) : h;
    return bare.contains('.') ? bare : null;
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final h = host;
    return SettingsScaffold(
      title: l.linkNeverAdd,
      trailing: [
        GlassDone(
          key: const Key('link-never-save'),
          onTap: h == null
              ? null
              : () {
                  final now = neverInApp(s);
                  if (!now.contains(h)) s.setPref('link_never', [...now, h].join(','));
                  Navigator.pop(context);
                },
        ),
      ],
      children: [
        group(context, footer: l.linkNeverInfo, [
          CupertinoTextField(
            key: const Key('link-never-field'),
            controller: c,
            autofocus: true,
            placeholder: 'example.com',
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: null,
            onChanged: (_) => setState(() {}),
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
          ),
        ]),
      ],
    );
  }
}
