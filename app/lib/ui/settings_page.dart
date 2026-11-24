// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings tab (iPhone Settings look, Telegram layout): big profile at the
// top, then cards that open the sub-pages in settings_pages.dart.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'profile_page.dart';
import 'recovery_page.dart';
import 'settings_kit.dart';
import 'settings_more.dart';
import 'settings_notify.dart';
import 'settings_pages.dart';
import 'ios_route.dart';
import 'wide.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static Future<void> showKey(BuildContext context) async {
    final l = L.of(context);
    final key = await AppScope.of(context).backend.makeRecoveryKey();
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(l.recoveryKeyTitle),
        content: Column(
          children: [
            SizedBox(height: Tokens.space[1]),
            Text(l.recoveryKeyBody),
            SizedBox(height: Tokens.space[2]),
            Text(key, key: const Key('recovery-key-text'), style: Tokens.body.style),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Clipboard.setData(ClipboardData(text: key)),
            child: Text(l.copied),
          ),
          CupertinoDialogAction(onPressed: () => Navigator.pop(c), child: Text(l.done)),
        ],
      ),
    );
  }

  static Future<void> enterKey(BuildContext context) => Navigator.of(context).push(IosPageRoute(fullscreenDialog: true, builder: (_) => const RecoveryPage()));

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? name;
  List<int>? photo;
  bool? backupOn;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (name == null) load();
  }

  Future<void> load() async {
    final b = AppScope.of(context).backend;
    final n = await b.myName().catchError((_) => '');
    final ph = await b.myPhoto().catchError((_) => null);
    final bk = await b.hasRecovery().catchError((_) => false);
    if (mounted) {
      setState(() {
        name = n;
        photo = ph;
        backupOn = bk;
      });
    }
  }

  Future<void> editProfile() async {
    await Navigator.of(context).push(IosPageRoute(builder: (_) => const ProfilePage()));
    await load();
  }

  Future<void> openSaved() async {
    final s = AppScope.of(context);
    final l = L.of(context);
    final id = await s.openSaved();
    if (!mounted) return;
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: id, title: l.savedMessages),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final lang = s.locale?.languageCode;
    void go(Widget page) => Navigator.of(context).push(IosPageRoute(builder: (_) => page));
    NavRow row(String key, Color c, IconData icon, String title, {String? value, WidgetBuilder? page, VoidCallback? onTap}) =>
        NavRow(key: Key(key), color: c, icon: icon, title: title, value: value, page: page, onTap: onTap);
    // Layout = Burumy (big photo on top, cards in Burumy's order);
    // the details (glass bar, 26pt cards, 52pt rows, tiles) = iOS 27.
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        tint: p.background,
        title: l.tabSettings,
        leading: [GlassCircle(key: const Key('my-qr'), onTap: () => go(const MyQrPage()), child: GlassCircle.icon(context, CupertinoIcons.qrcode))],
        trailing: [GlassPill(key: const Key('settings-edit'), text: l.editShort, onTap: editProfile)],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height, bottom: FloatingTabBar.room(context)),
        children: [
          GestureDetector(
            key: const Key('my-profile'),
            onTap: editProfile,
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                PhotoAvatar(name: name ?? '', bytes: photo, size: 94),
                const SizedBox(height: 10),
                Text(
                  name ?? '',
                  key: const Key('my-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.screenTitle.style.copyWith(color: p.label),
                ),
                const SizedBox(height: 2),
                Text(displayId(s.backend.userId ?? ''), style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
              ],
            ),
          ),
          SizedBox(height: Tokens.space[2]),
          const SecurityCheckCard(),
          group(context, [row('saved-row', p.tileGreen, CupertinoIcons.bookmark_fill, l.savedMessages, onTap: openSaved)]),
          group(context, [
            row(
              'backup-row',
              p.tileGreen,
              CupertinoIcons.cloud_upload_fill,
              l.chatBackup,
              value: backupOn == null ? null : (backupOn! ? l.stateOn : l.stateOff),
              onTap: () => showBackupSheet(context),
            ),
          ]),
          group(context, [row('account-row', Palette.tileGrey, CupertinoIcons.person_crop_circle_fill, l.accountManage, page: (_) => const AccountPage())]),
          // Rulebook D-5 / 10-1: colours by meaning, never the same colour on
          // neighbouring rows of one card.
          group(context, [
            row('look-row', Palette.tileCyan, CupertinoIcons.paintbrush_fill, l.settingsAppearance, page: (_) => const AppearancePage()),
            row(
              'power-row',
              Palette.tileOrange,
              CupertinoIcons.battery_25,
              l.powerSaving,
              value: powerOptions(l).where((o) => o.$1 == s.pref('power_below', '15')).firstOrNull?.$2,
              page: (_) => const PowerSavingPage(),
            ),
            row(
              'language-row',
              Palette.tileGrey,
              CupertinoIcons.globe,
              l.settingsLanguage,
              value: switch (lang) {
                'ko' => l.languageKo,
                'en' => l.languageEn,
                _ => l.languageAuto,
              },
              onTap: () => go(const LanguagePage()),
            ),
            row('notify-row', Palette.tileRed, CupertinoIcons.bell_fill, l.settingsNotifications, page: (_) => const NotificationsPage()),
            row('devices-row', p.tileBlack, CupertinoIcons.device_laptop, l.devices, page: (_) => const DevicesPage()),
            row('chats-row', p.tileGreen, CupertinoIcons.chat_bubble_fill, l.settingsChatsPage, page: (_) => const ChatSettingsPage()),
            row('data-row', Palette.tileTeal, CupertinoIcons.chart_pie_fill, l.dataStorage, page: (_) => const DataPage()),
            row('privacy-row', Palette.tileBlue, CupertinoIcons.checkmark_shield_fill, l.settingsPrivacy, page: (_) => const PrivacyPage()),
          ]),
          group(context, [
            row('faq-row', Palette.tileTeal, CupertinoIcons.question_circle_fill, l.faq, page: (_) => const FaqPage()),
            row('tour-row', Palette.tileYellow, CupertinoIcons.lightbulb_fill, l.featureTour, page: (_) => const FeatureTourPage()),
            row('about-row', Palette.tileGrey, CupertinoIcons.info_circle_fill, l.aboutApp, page: (_) => const AboutPage()),
          ]),
          group(context, [
            CupertinoListTile(
              key: const Key('logout'),
              leading: iconTile(Palette.tileRed, CupertinoIcons.square_arrow_right),
              title: Text(l.logOut, style: const TextStyle(color: Palette.tileRed)),
              onTap: s.logout,
            ),
          ]),
          SizedBox(height: Tokens.space[2]),
          Center(
            child: Text('${Brand.nameEn} v2', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ),
        ],
      ),
    );
  }
}

class StreakSwitchTile extends StatefulWidget {
  const StreakSwitchTile({super.key});
  @override
  State<StreakSwitchTile> createState() => _StreakSwitchTileState();
}

class _StreakSwitchTileState extends State<StreakSwitchTile> {
  bool? on;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (on == null) {
      AppScope.of(context).backend.streaksEnabled().then((v) {
        if (mounted) setState(() => on = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    return CupertinoListTile(
      leading: iconTile(Palette.tileOrange, CupertinoIcons.flame_fill),
      title: Text(l.streaks),
      trailing: IosSwitch(
        key: const Key('streak-switch'),
        value: on ?? true,
        activeTrackColor: paletteOf(context).accent,
        onChanged: (v) async {
          setState(() => on = v);
          await s.backend.setStreaksEnabled(v);
          await s.refresh();
        },
      ),
    );
  }
}

class LinkPreviewSwitchTile extends StatefulWidget {
  const LinkPreviewSwitchTile({super.key});
  @override
  State<LinkPreviewSwitchTile> createState() => _LinkPreviewSwitchTileState();
}

class _LinkPreviewSwitchTileState extends State<LinkPreviewSwitchTile> {
  bool? on;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (on == null) {
      AppScope.of(context).backend.linkPreviewsEnabled().then((v) {
        if (mounted) setState(() => on = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    return CupertinoListTile(
      leading: iconTile(Palette.tileBlue, CupertinoIcons.link),
      title: Text(l.linkPreviews),
      trailing: IosSwitch(
        key: const Key('link-preview-switch'),
        value: on ?? true,
        activeTrackColor: paletteOf(context).accent,
        onChanged: (v) async {
          setState(() => on = v);
          await s.backend.setLinkPreviewsEnabled(v);
        },
      ),
    );
  }
}

/// Notifications say only "new message" (no chat name, no text).
class NoticeTextSwitchTile extends StatefulWidget {
  const NoticeTextSwitchTile({super.key});
  @override
  State<NoticeTextSwitchTile> createState() => _NoticeTextSwitchTileState();
}

class _NoticeTextSwitchTileState extends State<NoticeTextSwitchTile> {
  bool? on;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (on == null) {
      AppScope.of(context).backend.noticeTextHidden().then((v) {
        if (mounted) setState(() => on = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    return CupertinoListTile(
      leading: iconTile(Palette.tileRed, CupertinoIcons.bell_slash),
      title: Text(l.noticeTextHidden),
      trailing: IosSwitch(
        key: const Key('notice-text-switch'),
        value: on ?? false,
        activeTrackColor: paletteOf(context).accent,
        onChanged: (v) async {
          setState(() => on = v);
          await s.backend.setNoticeTextHidden(v);
        },
      ),
    );
  }
}

/// A call coming in while I talk: call waiting (default), missed, or busy.
class CallWaitingTile extends StatefulWidget {
  const CallWaitingTile({super.key});
  @override
  State<CallWaitingTile> createState() => _CallWaitingTileState();
}

class _CallWaitingTileState extends State<CallWaitingTile> {
  String? mode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mode == null) {
      AppScope.of(context).backend.callWaiting().then((v) {
        if (mounted) setState(() => mode = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    String label(String m) => switch (m) {
      'missed' => l.callWaitingMissed,
      'busy' => l.callWaitingBusy,
      _ => l.callWaitingWait,
    };
    return CupertinoListTile(
      key: const Key('call-waiting-tile'),
      leading: iconTile(paletteOf(context).tileGreen, CupertinoIcons.phone_fill),
      title: Text(l.callWaitingTitle),
      additionalInfo: Text(label(mode ?? 'wait')),
      trailing: const CupertinoListTileChevron(),
      onTap: () => showCupertinoModalPopup<void>(
        useRootNavigator: !Wide.on,
        context: context,
        builder: (c) => IosActionSheet(
          title: Text(l.callWaitingTitle),
          actions: [
            for (final m in const ['wait', 'missed', 'busy'])
              CupertinoActionSheetAction(
                key: Key('call-waiting-$m'),
                onPressed: () async {
                  Navigator.pop(c);
                  setState(() => mode = m);
                  await s.backend.setCallWaiting(m);
                },
                child: Text(label(m)),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        ),
      ),
    );
  }
}
