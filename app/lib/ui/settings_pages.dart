// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings sub-pages: appearance, power saving, language, notifications,
// chats, data, privacy & security, and the account tools (blocked people,
// devices, password, keys). Every row here really changes something.
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import '../brand/brand.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/error_log.dart';
import '../core/storage_usage.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'app_lock_page.dart';
import 'common.dart';
import 'app_icon.dart';
import 'links.dart';
import 'ios.dart';
import 'glass.dart';
import 'chat_row_actions.dart';
import 'settings_kit.dart';
import 'message_sheets.dart' show AccentButton, GlassSheet;
import 'settings_art.dart';
import 'sticker_panel.dart';
import 'wallpaper.dart';
import '../stickers/catalog.dart';
import 'settings_page.dart';
import 'ios_route.dart';
import 'wide.dart';

// ---------------------------------------------------------------- appearance

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static Future<void> pickPhoto(BuildContext context) async {
    final s = AppScope.of(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1170, imageQuality: 78);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    await s.setPref('chat_photo', base64Encode(bytes));
    await s.setPref('chat_theme', 'photo');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final size = double.tryParse(s.pref('text_size', '')) ?? 1.0;
    final corner = double.tryParse(s.pref('bubble_radius', '')) ?? Tokens.radius[2] + 2;
    final theme = s.pref('chat_theme', 'plain');
    final hasPhoto = chatPhoto(s) != null;
    final night = s.pref('night', 'system');
    final darkNow = p.dark;
    final themes = [...ChatTheme.all.map((t) => (t.id, t.label(l))), if (hasPhoto) ('photo', l.themePhoto)];

    Widget themeTile(String id, String label) {
      final picked = theme == id;
      return GestureDetector(
        key: Key('chat-theme-$id'),
        onTap: () => s.setPref('chat_theme', id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 68,
                height: 92,
                padding: const EdgeInsets.all(3),
                decoration: ShapeDecoration(
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: picked ? p.accent : const Color(0x00000000), width: 2.5),
                  ),
                ),
                child: ClipRSuperellipse(
                  borderRadius: BorderRadius.circular(15),
                  child: DecoratedBox(
                    // A hairline so the plain white one shows on a white card.
                    position: DecorationPosition.foreground,
                    decoration: ShapeDecoration(
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: p.separator),
                      ),
                    ),
                    child: ChatWallpaper(
                      theme: id,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(7, 14, 7, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              height: 12,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(6)),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 12,
                              margin: const EdgeInsets.only(left: 16),
                              decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(label, style: Tokens.caption.style.copyWith(color: picked ? p.accent : p.secondaryLabel)),
            ],
          ),
        ),
      );
    }

    return SettingsScaffold(
      title: l.settingsAppearance,
      children: [
        HeaderCard(color: Palette.tileCyan, icon: CupertinoIcons.paintbrush_fill, title: l.settingsAppearance, body: l.appearanceInfo),
        group(context, header: l.colorTheme, [
          // Preview: two bubbles on the chosen background.
          SizedBox(
            height: 150,
            child: ChatWallpaper(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PreviewBubble(text: l.bubbleSample, mine: false, radius: corner),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PreviewBubble(text: l.textSizePreviewReply, mine: true, radius: corner),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 136,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              children: [for (final (id, label) in themes) themeTile(id, label)],
            ),
          ),
          NavRow(
            key: const Key('photo-bg'),
            color: Palette.tileTeal,
            icon: CupertinoIcons.photo_fill,
            title: l.myPhotoBackground,
            onTap: () => pickPhoto(context),
          ),
          IosTile(
            key: const Key('my-color'),
            leading: iconTile(Palette.tileBlue, CupertinoIcons.paintbrush_fill),
            title: Text(l.myColor),
            additionalInfo: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            ),
            trailing: const IosChevron(),
            onTap: () => Navigator.of(context).push(
              IosPageRoute(
                builder: (_) => ChoicePage(
                  title: l.myColor,
                  options: [('green', l.themeGreen), ('blue', l.themeBlue)],
                  value: () => s.family.name,
                  onPick: (v) => s.setFamily(v == 'blue' ? BrandFamily.blue : BrandFamily.green),
                ),
              ),
            ),
          ),
        ]),
        group(context, header: l.glassEffect, footer: l.glassInfo, [
          Padding(
            padding: const EdgeInsets.all(10),
            child: IosSegmented<String>(
              key: const Key('glass-level'),
              groupValue: s.pref('glass', 'normal'),
              children: {'clear': Text(l.glassClear), 'normal': Text(l.glassNormal), 'solid': Text(l.glassSolid)},
              onValueChanged: (v) => s.setPref('glass', v == null || v == 'normal' ? '' : v),
            ),
          ),
        ]),
        group(context, footer: l.tiltInfo, [
          PrefSwitch('tilt', key: const Key('tilt-switch'), title: l.tiltMove, color: Palette.tileOrange, icon: CupertinoIcons.move),
        ]),
        group(context, [
          IosTile(
            leading: iconTile(Palette.tileIndigo, CupertinoIcons.moon_fill),
            title: Text(l.nightMode),
            trailing: IosSwitch(
              key: const Key('night-switch'),
              value: darkNow,
              activeTrackColor: p.accent,
              onChanged: (v) => s.setPref('night', v ? 'dark' : 'light'),
            ),
          ),
          NavRow(
            key: const Key('auto-night'),
            color: Palette.tilePurple,
            icon: CupertinoIcons.circle_lefthalf_fill,
            title: l.autoNight,
            value: night == 'system' ? l.autoNightSystem : l.autoNightOff,
            page: (c) => ChoicePage(
              title: l.autoNight,
              options: [('off', l.autoNightOff), ('system', l.autoNightSystem)],
              value: () => s.pref('night', 'system') == 'system' ? 'system' : 'off',
              onPick: (v) => s.setPref('night', v == 'system' ? 'system' : (paletteOf(c).dark ? 'dark' : 'light')),
            ),
          ),
        ]),
        group(context, [
          NavRow(
            key: const Key('text-size-row'),
            color: Palette.tileBlue,
            icon: CupertinoIcons.textformat_size,
            title: l.textSize,
            value: size == 1.0 ? l.textSizeDefault : '${(size * 100).round()}%',
            page: (_) => const TextSizePage(),
          ),
          NavRow(
            key: const Key('corner-row'),
            color: Palette.tileTeal,
            icon: CupertinoIcons.square_on_square,
            title: l.bubbleCorners,
            value: corner.toStringAsFixed(0),
            page: (_) => const CornerPage(),
          ),
          NavRow(
            color: Palette.tileOrange,
            icon: CupertinoIcons.battery_25,
            title: l.powerSaving,
            value: powerOptions(l).where((o) => o.$1 == s.pref('power_below', '15')).firstOrNull?.$2,
            page: (_) => const PowerSavingPage(),
          ),
          NavRow(color: Palette.tilePink, icon: CupertinoIcons.smiley_fill, title: l.stickersEmoji, page: (_) => const StickersEmojiPage()),
        ]),
        // Android only for now (iPhone needs the app in the App Store first).
        if (AppIconPicker.supported) group(context, header: l.appIcon, footer: l.appIconInfo, const [AppIconPicker()]),
      ],
    );
  }
}

class _PreviewBubble extends StatelessWidget {
  const _PreviewBubble({required this.text, required this.mine, required this.radius, this.scale = 1});
  final String text;
  final bool mine;
  final double radius, scale;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(radius)),
      child: Text(
        text,
        textScaler: TextScaler.linear(scale),
        style: Tokens.body.style.copyWith(color: mine ? p.onAccent : p.label),
      ),
    );
  }
}

/// Appearance > Text size: a chat preview and a slider.
class TextSizePage extends StatelessWidget {
  const TextSizePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final size = double.tryParse(s.pref('text_size', '')) ?? 1.0;
    final corner = double.tryParse(s.pref('bubble_radius', '')) ?? Tokens.radius[2] + 2;
    return SettingsScaffold(
      title: l.textSize,
      children: [
        group(context, [
          SizedBox(
            height: 190,
            child: ChatWallpaper(
              child: MediaQuery(
                // the app already scales text; show the raw preview here
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _PreviewBubble(text: l.textSizePreview, mine: false, radius: corner, scale: size),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _PreviewBubble(text: l.textSizePreviewReply, mine: true, radius: corner, scale: size),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: Row(
              children: [
                Text('A', style: TextStyle(fontSize: 13, color: p.label)),
                Expanded(
                  child: CupertinoSlider(
                    key: const Key('text-size'),
                    value: size.clamp(0.85, 1.3),
                    min: 0.85,
                    max: 1.3,
                    divisions: 9,
                    activeColor: p.accent,
                    onChanged: (v) => s.setPref('text_size', (v - 1.0).abs() < 0.01 ? '' : v.toStringAsFixed(2)),
                  ),
                ),
                Text('A', style: TextStyle(fontSize: 22, color: p.label)),
              ],
            ),
          ),
        ]),
      ],
    );
  }
}

/// Appearance > Message corners: a chat preview and a slider.
class CornerPage extends StatelessWidget {
  const CornerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final corner = double.tryParse(s.pref('bubble_radius', '')) ?? Tokens.radius[2] + 2;
    return SettingsScaffold(
      title: l.bubbleCorners,
      children: [
        group(context, [
          SizedBox(
            height: 160,
            child: ChatWallpaper(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _PreviewBubble(text: l.textSizePreview, mine: false, radius: corner),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PreviewBubble(text: l.textSizePreviewReply, mine: true, radius: corner),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: CupertinoSlider(
              key: const Key('bubble-radius'),
              value: corner.clamp(4, 22),
              min: 4,
              max: 22,
              divisions: 9,
              activeColor: p.accent,
              onChanged: (v) => s.setPref('bubble_radius', v.toStringAsFixed(0)),
            ),
          ),
        ]),
      ],
    );
  }
}

const quickReactions = ['❤️', '👍', '😂', '🔥', '😮', '😢', '🙏', '🎉'];

class StickersEmojiPage extends StatelessWidget {
  const StickersEmojiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    // Telegram's layout (sizes) with our items: reactions card, look card,
    // then my packs (drag to sort, switch to show in the panel).
    return SettingsScaffold(
      title: l.stickersEmoji,
      children: [
        HeaderCard(color: Palette.tilePink, icon: CupertinoIcons.smiley_fill, title: l.stickersEmoji, body: l.stickersHeaderInfo),
        group(context, footer: l.doubleTapInfo, [
          PrefChoice(
            'quick_reaction',
            title: l.quickReaction,
            fallback: '❤️',
            color: Palette.tileRed,
            icon: CupertinoIcons.heart_fill,
            options: [for (final e in quickReactions) (e, e)],
          ),
          PrefSwitch('double_tap_react', title: l.doubleTapReact, fallback: true, color: Palette.tileBlue, icon: CupertinoIcons.hand_point_right_fill),
        ]),
        group(context, footer: l.packDynamicInfo, [
          PrefSwitch('big_emoji', title: l.bigEmoji, fallback: true, color: Palette.tileOrange, icon: CupertinoIcons.smiley_fill),
          PrefSwitch('pack_dynamic', title: l.packDynamic, fallback: true, color: Palette.tilePurple, icon: CupertinoIcons.arrow_up_arrow_down),
        ]),
        const PackList(),
        group(context, [
          IosTile(
            key: const Key('clear-recent-stickers'),
            title: Text(l.clearRecentStickers, style: TextStyle(color: recentStickers(s).isEmpty ? paletteOf(context).secondaryLabel : Palette.tileRed)),
            onTap: recentStickers(s).isEmpty ? null : () => s.setPref(recentStickersKey, ''),
          ),
        ]),
      ],
    );
  }
}

/// "내 스티커": 40 pt pack picture, name, count, switch and a drag handle.
class PackList extends StatelessWidget {
  const PackList({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    // Base order (without the recent-first shuffle) is what the handle moves.
    final byId = {for (final k in stickerPacks) k.id: k};
    final order = <String>[
      for (final id in s.pref('pack_order', '').split(','))
        if (byId.containsKey(id)) id,
      for (final k in stickerPacks)
        if (!s.pref('pack_order', '').split(',').contains(k.id)) k.id,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[4], IosSection.sideMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, Tokens.groupTitleToCard + 2), child: sectionHeader(context, l.burumyStickers)),
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(IosSection.radius),
            child: ColoredBox(
              color: p.card,
              child: ReorderableList(
                key: const Key('pack-list'),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.length,
                onReorder: (from, to) {
                  final next = [...order];
                  final id = next.removeAt(from);
                  next.insert(to > from ? to - 1 : to, id);
                  s.setPref('pack_order', next.join(','));
                },
                itemBuilder: (c, i) {
                  final pack = byId[order[i]]!;
                  return ColoredBox(
                    key: Key('pack-${pack.id}'),
                    color: p.card,
                    child: Column(
                      children: [
                        if (i > 0) Container(height: 1, margin: const EdgeInsetsDirectional.only(start: 76, end: 20), color: p.separator),
                        SizedBox(
                          height: Tokens.memberRow,
                          child: Row(
                            children: [
                              SizedBox(width: Tokens.space[3]),
                              SizedBox(width: Tokens.memberAvatar, height: Tokens.memberAvatar, child: Image.asset(pack.asset(pack.items.first))),
                              SizedBox(width: Tokens.space[3] + Tokens.space[0]),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      packName(l, pack.id),
                                      style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                                    ),
                                    Text(l.stickerCount(pack.items.length), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                                  ],
                                ),
                              ),
                              IosSwitch(
                                key: Key('pack-switch-${pack.id}'),
                                value: !s.on('pack_off:${pack.id}'),
                                activeTrackColor: p.accent,
                                onChanged: (v) => s.setOn('pack_off:${pack.id}', !v),
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: Padding(
                                  key: Key('pack-drag-${pack.id}'),
                                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2]),
                                  child: Icon(CupertinoIcons.line_horizontal_3, size: Tokens.listIcon, color: p.secondaryLabel),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(padding: EdgeInsets.fromLTRB(20, Tokens.cardToFooter, 20, 0), child: sectionFooter(context, l.packOrderInfo)),
        ],
      ),
    );
  }
}

String packName(L l, String id) => switch (id) {
  'buru' => l.pack_buru,
  'dugi' => l.pack_dugi,
  'rumi' => l.pack_rumi,
  'mongi' => l.pack_mongi,
  'duru' => l.pack_duru,
  _ => l.pack_burumi,
};

// ---------------------------------------------------------------- power saving

/// Settings > Power saving choices: never, below 5..50 %, always.
List<(String, String)> powerOptions(L l) => [
  ('0', l.powerNever),
  for (final pct in const [5, 10, 15, 20, 25, 50]) ('$pct', l.powerBelowValue(pct)),
  ('100', l.powerAlways),
];

class PowerSavingPage extends StatelessWidget {
  const PowerSavingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final below = s.powerBelow;
    return SettingsScaffold(
      title: l.powerSaving,
      children: [
        HeaderCard(color: Palette.tileOrange, icon: CupertinoIcons.battery_25, title: l.powerSaving, body: l.powerSavingInfo),
        group(context, footer: l.powerModeInfo, [
          PrefChoice('power_below', title: l.powerMode, fallback: '15', color: Palette.tileOrange, icon: CupertinoIcons.battery_25, options: powerOptions(l)),
          if (s.battery != null)
            IosTile(
              key: const Key('battery-now'),
              title: Text('${s.battery}%'),
              additionalInfo: Text(s.calm ? l.stateOn : l.stateOff),
              leading: Icon(
                s.battery! < below ? CupertinoIcons.battery_25 : CupertinoIcons.battery_100,
                color: s.calm ? Palette.tileOrange : paletteOf(context).accent,
              ),
            ),
        ]),
        // Telegram: the heavy jobs one by one; all stop when the battery is low.
        group(context, header: l.powerJobs, footer: l.powerJobsInfo, [
          PrefSwitch('ui_effects', title: l.uiEffects, subtitle: l.uiEffectsInfo, fallback: true, color: Palette.tilePurple, icon: CupertinoIcons.sparkles),
          PrefSwitch(
            'ps_glass',
            title: l.psGlass,
            subtitle: l.psGlassSub,
            fallback: true,
            color: Palette.tileCyan,
            icon: CupertinoIcons.square_stack_3d_up_fill,
          ),
          PrefSwitch(
            'autoplay_gif',
            title: l.autoplayGif,
            subtitle: l.autoplayGifInfo,
            fallback: true,
            color: Palette.tileOrange,
            icon: CupertinoIcons.play_rectangle_fill,
          ),
          PrefSwitch(
            'ps_preload',
            title: l.psPreload,
            subtitle: l.psPreloadSub,
            fallback: true,
            color: Palette.tileBlue,
            icon: CupertinoIcons.arrow_down_circle_fill,
          ),
          PrefSwitch('tilt', title: l.tiltMove, subtitle: l.psTiltSub, color: Palette.tileRed, icon: CupertinoIcons.move),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- language

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    return ChoicePage(
      title: l.settingsLanguage,
      card: HeaderCard(color: Palette.tileBlue, icon: CupertinoIcons.globe, title: l.settingsLanguage, body: l.languageHeaderInfo),
      options: [('system', l.languageAuto), ('ko', l.languageKo), ('en', l.languageEn)],
      value: () => s.locale?.languageCode ?? 'system',
      onPick: (v) => s.setLocale(v == 'system' ? null : Locale(v)),
    );
  }
}

// ---------------------------------------------------------------- chats

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.settingsChatsPage,
      children: [
        HeaderCard(color: p.tileGreen, icon: CupertinoIcons.chat_bubble_fill, title: l.settingsChatsPage, body: l.chatsHeaderInfo),
        // v1 order: messages, chat list, AI, media and reactions.
        group(context, header: l.chatsMessages, [
          PrefSwitch(
            'formatting',
            key: const Key('formatting-switch'),
            title: l.formattingRow,
            subtitle: l.formattingSub,
            fallback: true,
            color: Palette.tileBlue,
            icon: CupertinoIcons.textformat,
          ),
          PrefSwitch('enter_send', title: l.enterSends, color: p.tileGreen, icon: CupertinoIcons.return_icon),
          PrefSwitch('swipe_reply', title: l.swipeReply, fallback: true, color: Palette.tileOrange, icon: CupertinoIcons.arrowshape_turn_up_left_fill),
        ]),
        group(context, header: l.chatsList, footer: l.listTopInfo, [
          PrefSwitch('list_top', title: l.listTop, color: Palette.tileTeal, icon: CupertinoIcons.search),
          PrefSwitch(
            'list_media',
            key: const Key('list-media-switch'),
            title: l.listMedia,
            subtitle: l.listMediaSub,
            color: Palette.tileOrange,
            icon: CupertinoIcons.photo_fill,
          ),
        ]),
        group(context, footer: l.streakInfo, const [StreakSwitchTile()]),
        group(context, header: l.aiFeatures, footer: l.aiOnPhoneInfo, [
          PrefSwitch(
            'scam_warning',
            title: l.scamWarning,
            subtitle: l.scamWarningSub,
            fallback: true,
            color: Palette.tileRed,
            icon: CupertinoIcons.exclamationmark_shield_fill,
          ),
          PrefSwitch(
            'plan_pick',
            key: const Key('plan-pick-switch'),
            title: l.planPick,
            subtitle: l.planPickSub,
            color: Palette.tileOrange,
            icon: CupertinoIcons.calendar,
          ),
        ]),
        group(context, header: l.chatsMediaReactions, [
          PrefSwitch('double_tap_react', title: l.doubleTapReact, fallback: true, color: Palette.tileRed, icon: CupertinoIcons.heart_fill),
          NavRow(
            key: const Key('quick-replies-row'),
            color: Palette.tileYellow,
            icon: CupertinoIcons.text_bubble_fill,
            title: l.quickReplies,
            value: '${quickReplies(AppScope.of(context)).length}',
            page: (_) => const QuickRepliesPage(),
          ),
          NavRow(
            key: const Key('away-row'),
            color: Palette.tileIndigo,
            icon: CupertinoIcons.moon_zzz_fill,
            title: l.awayReply,
            value: AppScope.of(context).on('away_on') ? l.stateOn : l.stateOff,
            page: (_) => const AwayReplyPage(),
          ),
        ]),
        group(context, [
          NavRow(
            key: const Key('hidden-chats-row'),
            color: Palette.tileGrey,
            icon: CupertinoIcons.eye_slash_fill,
            title: l.hiddenChats,
            value: '${AppScope.of(context).chats.where((c) => AppScope.of(context).on(hiddenKey(c.roomId))).length}',
            page: (_) => const HiddenChatsPage(),
          ),
        ]),
      ],
    );
  }
}

class QuickRepliesPage extends StatefulWidget {
  const QuickRepliesPage({super.key});

  @override
  State<QuickRepliesPage> createState() => _QuickRepliesPageState();
}

class _QuickRepliesPageState extends State<QuickRepliesPage> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> save(AppState s, List<String> list) => s.setPref('quick_replies', jsonEncode(list));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final list = quickReplies(s);
    void add() {
      final v = field.text.trim();
      if (v.isEmpty || list.length >= 20 || list.contains(v)) return;
      field.clear();
      save(s, [...list, v.length > 200 ? v.substring(0, 200) : v]);
    }

    return SettingsScaffold(
      title: l.quickReplies,
      children: [
        group(context, footer: l.quickRepliesInfo, [
          for (var i = 0; i < list.length; i++)
            IosTile(
              key: Key('quick-$i'),
              title: Text(list[i], maxLines: 2),
              trailing: GestureDetector(
                key: Key('quick-remove-$i'),
                onTap: () => save(s, [...list]..removeAt(i)),
                child: const Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: 22),
              ),
            ),
          if (list.length < 20)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField.borderless(
                      key: const Key('quick-field'),
                      controller: field,
                      placeholder: l.quickReplyHint,
                      maxLength: 200,
                      style: Tokens.body.style.copyWith(color: p.label),
                      onSubmitted: (_) => add(),
                    ),
                  ),
                  GestureDetector(
                    key: const Key('quick-add'),
                    onTap: add,
                    child: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 24),
                  ),
                ],
              ),
            ),
        ]),
      ],
    );
  }
}

class AwayReplyPage extends StatefulWidget {
  const AwayReplyPage({super.key});

  @override
  State<AwayReplyPage> createState() => _AwayReplyPageState();
}

class _AwayReplyPageState extends State<AwayReplyPage> {
  TextEditingController? field;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    field ??= TextEditingController(text: s.pref('away_text', L.of(context).awayReplyDefault));
  }

  @override
  void dispose() {
    field?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.awayReply,
      children: [
        group(context, footer: l.awayReplyInfo, [
          IosTile(
            title: Text(l.awayReply),
            trailing: IosSwitch(
              key: const Key('away-switch'),
              value: s.on('away_on'),
              activeTrackColor: p.accent,
              onChanged: (v) async {
                final text = field!.text.trim().isEmpty ? l.awayReplyDefault : field!.text.trim();
                await s.setPref('away_text', text);
                await s.setPref('away_since', v ? DateTime.now().toIso8601String() : '');
                await s.setOn('away_on', v);
              },
            ),
          ),
        ]),
        group(context, header: l.awayReplyText, [
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: CupertinoTextField.borderless(
              key: const Key('away-text'),
              controller: field,
              maxLines: 4,
              minLines: 2,
              maxLength: 300,
              style: Tokens.body.style.copyWith(color: p.label),
              onChanged: (v) => s.setPref('away_text', v.trim()),
            ),
          ),
        ]),
      ],
    );
  }
}

/// Chats hidden from the list; tap one to show it again.
class HiddenChatsPage extends StatelessWidget {
  const HiddenChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final app = AppScope.of(context);
    final hidden = [
      for (final c in app.chats)
        if (app.on(hiddenKey(c.roomId))) c,
    ];
    return SettingsScaffold(
      title: l.hiddenChats,
      children: [
        group(context, footer: l.hiddenChatsInfo, [
          for (final c in hidden)
            IosTile(
              key: Key('unhide-${c.roomId}'),
              leading: Avatar(name: c.name, size: 30, squircle: !c.isDirect),
              title: Text(c.name),
              trailing: Text(l.showInList, style: TextStyle(color: paletteOf(context).accent)),
              onTap: () => app.setOn(hiddenKey(c.roomId), false),
            ),
          if (hidden.isEmpty) IosTile(title: Text(l.nothingShared)),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- data

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  StorageUsage? usage;
  bool read = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final u = await StorageUsage.read();
    if (mounted) {
      setState(() {
        usage = u;
        read = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final u = usage;
    return SettingsScaffold(
      title: l.dataStorage,
      children: [
        HeaderCard(color: Palette.tileTeal, icon: CupertinoIcons.chart_pie_fill, title: l.dataStorage, body: l.dataInfo),
        group(context, header: l.storageUsage, footer: u == null && read ? l.storageWeb : l.storageInfo, [
          if (!read)
            IosTile(title: CupertinoActivityIndicator())
          else if (u != null) ...[
            IosTile(key: const Key('storage-app'), title: Text(l.storageApp), additionalInfo: Text(sizeText(u.app))),
            IosTile(key: const Key('storage-cache'), title: Text(l.storageCache), additionalInfo: Text(sizeText(u.cache))),
            IosTile(
              key: const Key('clear-cache'),
              title: Text(l.clearCache, style: TextStyle(color: u.cache == 0 ? p.secondaryLabel : Palette.tileRed)),
              onTap: u.cache == 0
                  ? null
                  : () async {
                      await StorageUsage.clearCache();
                      await load();
                    },
            ),
          ] else
            IosTile(title: Text(l.storageUsage), additionalInfo: const Text('—')),
        ]),
        group(context, header: l.autoDownload, footer: l.autoDownloadInfo, [
          PrefSwitch(
            'auto_dl_cell',
            title: l.autoDlCell,
            subtitle: l.autoDlPhotosSub,
            fallback: true,
            color: p.tileGreen,
            icon: CupertinoIcons.antenna_radiowaves_left_right,
          ),
          PrefSwitch('auto_dl_wifi', title: l.autoDlWifi, subtitle: l.autoDlPhotosSub, fallback: true, color: Palette.tileBlue, icon: CupertinoIcons.wifi),
          Builder(
            builder: (context) {
              final s = AppScope.of(context);
              final changed = !s.on('auto_dl_cell', fallback: true) || !s.on('auto_dl_wifi', fallback: true);
              return IosTile(
                key: const Key('auto-dl-reset'),
                leading: Icon(CupertinoIcons.arrow_counterclockwise, color: p.secondaryLabel),
                title: Text(l.autoDlReset, style: TextStyle(color: changed ? p.accent : p.secondaryLabel)),
                onTap: changed
                    ? () async {
                        await s.setOn('auto_dl_cell', true);
                        await s.setOn('auto_dl_wifi', true);
                      }
                    : null,
              );
            },
          ),
        ]),
        group(context, header: l.mediaAndLinks, footer: l.linkPreviewInfo, [
          PrefSwitch(
            'autoplay_gif',
            title: l.autoplayGif,
            subtitle: l.autoplayGifSub,
            fallback: true,
            color: Palette.tileOrange,
            icon: CupertinoIcons.play_rectangle_fill,
          ),
          const LinkPreviewSwitchTile(),
        ]),
        group(context, header: l.callsHeader, [
          PrefSwitch('low_data_calls', title: l.lowDataCalls, subtitle: l.lowDataCallsSub, color: p.tileGreen, icon: CupertinoIcons.phone_fill),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- privacy

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  int? blockedCount;
  bool? lockSet;
  bool? verified;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (blockedCount == null) load();
  }

  Future<void> load() async {
    final b = AppScope.of(context).backend;
    final n = (await b.blocked().catchError((_) => <String>[])).length;
    final lock = await b.lockIsSet().catchError((_) => false);
    final v = await b.thisDeviceVerified().catchError((_) => false);
    if (mounted) {
      setState(() {
        blockedCount = n;
        lockSet = lock;
        verified = v;
      });
    }
  }

  Future<void> open(Widget page) async {
    await Navigator.of(context).push(IosPageRoute(builder: (_) => page));
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final who = [('everyone', l.whoEveryone), ('contacts', l.whoContacts)];
    final card = [...who, ('nobody', l.whoNobody)];
    // Built in from the start (v1 rows): one fixed choice and why.
    Widget fixedRow(String key, String title, String info) => NavRow(
      key: Key('fixed-$key'),
      title: title,
      value: l.whoAlwaysNobody,
      page: (_) => ChoicePage(title: title, footer: info, options: [('nobody', l.whoAlwaysNobody)], value: () => 'nobody', onPick: (_) {}),
    );
    return SettingsScaffold(
      title: l.settingsPrivacy,
      children: [
        HeaderCard(color: Palette.tileBlue, icon: CupertinoIcons.lock_shield_fill, title: l.settingsPrivacy, body: l.privacyInfo),
        // 1. Security: locks, keys and devices together.
        group(context, header: l.settingsSecurity, [
          NavRow(
            key: const Key('blocked-row'),
            color: Palette.tileRed,
            icon: CupertinoIcons.hand_raised_fill,
            title: l.blockedUsers,
            value: blockedCount == null || blockedCount == 0 ? null : '$blockedCount',
            onTap: () => open(const BlockedPage()),
          ),
          NavRow(
            key: const Key('app-lock'),
            color: Palette.tilePurple,
            icon: CupertinoIcons.lock_fill,
            title: l.appLock,
            value: lockSet == true ? l.appLockOn : l.appLockOff,
            onTap: () => open(const AppLockPage()),
          ),
          NavRow(
            key: const Key('hide-delete-row'),
            color: Palette.tileBlue,
            icon: CupertinoIcons.eye_slash_fill,
            title: l.hideDeleteRow,
            onTap: () => open(const AppLockPage()),
          ),
          NavRow(
            key: const Key('verify-row'),
            color: paletteOf(context).tileGreen,
            icon: CupertinoIcons.checkmark_shield_fill,
            title: l.verifyThisDevice,
            value: verified == null ? null : (verified! ? l.verifiedDone : l.verifyNeeded),
            onTap: () => open(const KeysPage()),
          ),
          NavRow(color: Palette.tileTeal, icon: CupertinoIcons.arrow_clockwise_circle_fill, title: l.recoveryKeyTitle, onTap: () => showBackupSheet(context)),
          NavRow(
            key: const Key('password-row'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.textformat_abc,
            title: l.changePassword,
            onTap: () => open(const ChangePasswordPage()),
          ),
          NavRow(color: paletteOf(context).tileBlack, icon: CupertinoIcons.device_laptop, title: l.devices, onTap: () => open(const DevicesPage())),
          NavRow(color: Palette.tileIndigo, icon: CupertinoIcons.lock_shield, title: l.encryptionKeys, onTap: () => open(const KeysPage())),
        ]),
        // 2. Messages I send.
        group(context, header: l.privMessages, footer: l.defaultTimerInfo, [
          PrefChoice(
            'default_timer',
            title: l.defaultTimer,
            fallback: '0',
            options: [('0', l.timerOff), ('86400', l.timer1d), ('604800', l.timer1w), ('2592000', l.timer1m)],
          ),
          PrefSwitch('undo_send', title: l.undoSend, subtitle: l.undoSendSub),
          PrefSwitch('send_read', title: l.sendRead, subtitle: l.sendReadSub, fallback: true),
          PrefSwitch('send_typing', title: l.sendTyping, subtitle: l.sendTypingSub, fallback: true),
          NavRow(
            key: const Key('edit-history-row'),
            title: l.editHistory,
            value: l.editHistoryAlways,
            page: (_) => ChoicePage(title: l.editHistory, footer: l.editHistoryInfo, options: [('on', l.editHistoryAlways)], value: () => 'on', onPick: (_) {}),
          ),
        ]),
        // 3. Who sees my info.
        group(context, header: l.privWhoSees, footer: l.whoCardInfo, [
          fixedRow('last-seen', l.whoLastSeen, l.lastSeenInfo),
          for (final (k, title, fallback) in [
            ('who_photo', l.whoPhoto, 'everyone'),
            ('who_bio', l.whoBio, 'everyone'),
            ('who_birthday', l.whoBirthday, 'contacts'),
          ])
            NavRow(
              key: Key('choice-$k'),
              title: title,
              value: card.where((o) => o.$1 == s.pref(k, fallback)).firstOrNull?.$2,
              page: (_) => ChoicePage(
                title: title,
                footer: l.whoCardInfo,
                options: card,
                value: () => AppScope.of(context).pref(k, fallback),
                onPick: (v) async {
                  final st = AppScope.read(context);
                  await st.setPref(k, v);
                  try {
                    await st.publishProfile();
                  } catch (e, t) {
                    ErrorLog.add(e, t);
                  }
                },
              ),
            ),
          fixedRow('forwards', l.whoForwards, l.forwardsInfo),
        ]),
        group(context, [PrefSwitch('birthday_alert', title: l.birthdayAlert, subtitle: l.birthdayAlertSub)]),
        // 4. Who can reach me.
        group(context, header: l.privWhoReach, footer: l.whoInfo, [
          for (final (k, title, opts) in [
            ('who_calls', l.whoCalls, [...who, ('nobody', l.whoNobody)]),
            ('who_messages', l.whoMessages, who),
            ('who_invites', l.whoInvites, who),
          ])
            NavRow(
              key: Key('choice-$k'),
              title: title,
              value: opts.where((o) => o.$1 == s.pref(k, 'everyone')).firstOrNull?.$2 ?? opts.first.$2,
              page: (_) => WhoPage(prefKey: k, title: title, options: opts),
            ),
        ]),
        // 5. When someone looks at my screen.
        group(context, header: l.privScreen, [
          PrefSwitch('veil_all', title: l.veilAll, subtitle: l.veilAllSub),
          PrefSwitch('panic', title: l.panic, subtitle: l.panicSub),
        ]),
        // 6. My account.
        group(context, header: l.privAccount, [
          PrefChoice(
            'auto_delete_months',
            title: l.autoDeleteRow,
            fallback: '12',
            footer: l.autoDeleteInfo,
            options: [('1', l.months1), ('3', l.months3), ('6', l.months6), ('12', l.months12), ('18', l.months18)],
          ),
          NavRow(
            key: const Key('link-open-row'),
            title: l.linkOpenTitle,
            value: s.pref('link_open', 'in_app') == 'in_app' ? l.linkOpenInAppShort : l.linkOpenBrowserShort,
            page: (_) => const WebBrowserPage(),
          ),
          PrefSwitch('show_errors', title: l.showErrors, subtitle: l.showErrorsSub),
          if (s.on('show_errors'))
            NavRow(key: const Key('error-log-row'), title: l.errorLog, value: '${ErrorLog.items.length}', page: (_) => const ErrorLogPage()),
        ]),
      ],
    );
  }
}

/// Who may call, message or add me, with people always allowed or never
/// allowed (kept as comma lists next to the choice).
class WhoPage extends StatelessWidget {
  const WhoPage({super.key, required this.prefKey, required this.title, required this.options});
  final String prefKey;
  final String title;
  final List<(String, String)> options;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final now = s.pref(prefKey, 'everyone');
    List<String> list(String k) => s.pref(k, '').split(',').where((x) => x.isNotEmpty).toList();
    Widget exceptionRow(String suffix, String label) {
      final k = '${prefKey}_$suffix';
      final n = list(k).length;
      return NavRow(
        key: Key('who-$suffix'),
        title: label,
        value: n == 0 ? l.addUsers : l.peopleCount(n),
        page: (_) => PeoplePickPage(title: label, picked: list(k), onDone: (ids) => s.setPref(k, ids.join(','))),
      );
    }

    return SettingsScaffold(
      title: title,
      children: [
        group(context, [
          for (final (v, label) in options)
            IosTile(
              key: Key('pick-$v'),
              title: Text(label),
              trailing: v == now ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
              onTap: () => s.setPref(prefKey, v),
            ),
        ]),
        group(context, header: l.noticeExceptions, footer: l.whoExceptionsInfo, [exceptionRow('allow', l.alwaysAllow), exceptionRow('deny', l.alwaysDeny)]),
      ],
    );
  }
}

/// Picks people from my contacts (checkmarks), saved with Done.
class PeoplePickPage extends StatefulWidget {
  const PeoplePickPage({super.key, required this.title, required this.picked, required this.onDone});
  final String title;
  final List<String> picked;
  final ValueChanged<List<String>> onDone;

  @override
  State<PeoplePickPage> createState() => _PeoplePickPageState();
}

class _PeoplePickPageState extends State<PeoplePickPage> {
  late final picked = {...widget.picked};
  List<Person>? people;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (people == null) {
      AppScope.of(context).backend.contacts().then(
        (v) {
          if (mounted) setState(() => people = v);
        },
        onError: (_) {
          if (mounted) setState(() => people = const []);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final known = {for (final x in people ?? const <Person>[]) x.userId: x.name};
    // People picked earlier who are no longer contacts stay listed.
    final ids = [...known.keys, ...picked.where((id) => !known.containsKey(id))];
    return SettingsScaffold(
      title: widget.title,
      trailing: [
        GlassPill(
          key: const Key('people-done'),
          text: l.done,
          onTap: () {
            widget.onDone(picked.toList());
            Navigator.of(context).pop();
          },
        ),
      ],
      children: [
        if (people == null)
          const Center(child: CupertinoActivityIndicator())
        else
          group(context, [
            for (final id in ids)
              IosTile(
                key: Key('person-$id'),
                leading: Avatar(name: known[id] ?? id, size: 30),
                title: Text(known[id] ?? displayId(id)),
                trailing: picked.contains(id) ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
                onTap: () => setState(() => picked.contains(id) ? picked.remove(id) : picked.add(id)),
              ),
            if (ids.isEmpty) IosTile(title: Text(l.contactsEmpty)),
          ]),
      ],
    );
  }
}

/// Make or enter the chat recovery key.
void showBackupSheet(BuildContext context) {
  final l = L.of(context);
  showCupertinoModalPopup<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.recoveryKeyTitle),
      message: Text(l.recoveryKeyBody),
      actions: [
        CupertinoActionSheetAction(
          key: const Key('make-key'),
          onPressed: () {
            Navigator.pop(c);
            SettingsPage.showKey(context);
          },
          child: Text(l.makeRecoveryKey),
        ),
        CupertinoActionSheetAction(
          key: const Key('enter-key'),
          onPressed: () {
            Navigator.pop(c);
            SettingsPage.enterKey(context);
          },
          child: Text(l.enterRecoveryKey),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

// ---------------------------------------------------------------- blocked

class BlockedPage extends StatefulWidget {
  const BlockedPage({super.key});
  @override
  State<BlockedPage> createState() => _BlockedPageState();
}

class _BlockedPageState extends State<BlockedPage> {
  List<String>? ids;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ids == null) load();
  }

  Future<void> load() async {
    final v = await AppScope.of(context).backend.blocked().catchError((_) => <String>[]);
    if (mounted) setState(() => ids = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final b = AppScope.of(context).backend;
    return SettingsScaffold(
      title: l.blockedUsers,
      children: [
        group(context, footer: l.blockedInfo, [
          IosTile(
            key: const Key('block-add'),
            leading: Icon(CupertinoIcons.person_badge_minus, color: p.accent),
            title: Text(l.blockSomeone, style: TextStyle(color: p.accent)),
            onTap: () async {
              await Navigator.of(context).push(IosPageRoute(builder: (_) => const BlockByIdPage()));
              await load();
            },
          ),
        ]),
        if (ids != null && ids!.isNotEmpty)
          group(context, [
            for (final id in ids!)
              IosTile(
                key: Key('blocked-$id'),
                leading: Avatar(name: displayId(id), size: 36),
                title: Text(displayId(id)),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () async {
                    await b.block(id, false);
                    await load();
                  },
                  child: Text(l.unblock, style: TextStyle(color: p.accent)),
                ),
              ),
          ]),
      ],
    );
  }
}

/// Full-screen field for an id (no pop-up text boxes).
class BlockByIdPage extends StatefulWidget {
  const BlockByIdPage({super.key});
  @override
  State<BlockByIdPage> createState() => _BlockByIdPageState();
}

class _BlockByIdPageState extends State<BlockByIdPage> {
  final field = TextEditingController();
  String? error;

  Future<void> save() async {
    final s = AppScope.of(context);
    var id = field.text.trim();
    if (id.isEmpty) return;
    if (!id.startsWith('@')) id = '@$id';
    if (!id.contains(':')) {
      final me = s.backend.userId ?? '';
      final i = me.indexOf(':');
      if (i > 0) id = '$id${me.substring(i)}';
    }
    try {
      await s.backend.block(id, true);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).blockFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.blockSomeone,
      trailing: [
        CupertinoButton(
          key: const Key('block-save'),
          padding: EdgeInsets.zero,
          onPressed: save,
          child: Text(l.done, style: TextStyle(color: p.accent)),
        ),
      ],
      children: [
        group(context, footer: error, [
          CupertinoTextField(
            key: const Key('block-id'),
            controller: field,
            autofocus: true,
            placeholder: l.userIdHint,
            decoration: null,
            padding: EdgeInsets.all(Tokens.space[3]),
            onSubmitted: (_) => save(),
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- devices

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  List<DeviceRow>? list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (list == null) load();
  }

  Future<void> load() async {
    final v = await AppScope.of(context).backend.devices().catchError((_) => <DeviceRow>[]);
    if (mounted) setState(() => list = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final all = list ?? const <DeviceRow>[];
    final mine = all.where((d) => d.thisDevice).toList();
    final others = all.where((d) => !d.thisDevice).toList();
    Widget row(DeviceRow d) => IosTile(
      key: Key('device-${d.id}'),
      leadingSize: Tokens.listIcon + Tokens.space[3],
      leading: iconTile(d.thisDevice ? Palette.tileBlue : (d.verified ? p.tileGreen : Palette.tileGrey), deviceIcon(d.name)),
      title: Text(d.name.isEmpty ? d.id : d.name, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        [
          d.verified ? l.deviceVerified : l.deviceNotVerified,
          if (d.thisDevice) l.onlineNow else if (d.lastSeen != null) shortTime(context, d.lastSeen!),
        ].join(' · '),
        style: Tokens.caption.style,
      ),
    );
    return SettingsScaffold(
      title: l.devices,
      children: [
        // Telegram-style top: picture, one line, one big button.
        ArtHeader(art: const LaptopArt(), text: l.devicesArtInfo),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
          child: AccentButton(key: const Key('add-device'), text: l.addDevice, onTap: () => showAddDevice(context)),
        ),
        if (mine.isNotEmpty) group(context, header: l.thisDevice, footer: l.devicesPlatforms, [for (final d in mine) row(d)]),
        if (others.isNotEmpty) ...[
          group(context, header: l.otherDevices, [for (final d in others) row(d)]),
          group(context, footer: l.devicesHeaderInfo, [
            IosTile(
              key: const Key('logout-others'),
              title: Text(l.logOutOthers, style: const TextStyle(color: Palette.tileRed)),
              onTap: () async {
                final ids = [for (final d in others) d.id];
                final ok = await Navigator.of(context).push<bool>(
                  IosPageRoute(
                    builder: (_) => PasswordCheckPage(title: l.logOutOthers, run: (pw) => AppScope.of(context).backend.logOutDevices(ids, pw)),
                  ),
                );
                if (ok == true) await load();
              },
            ),
          ]),
        ],
      ],
    );
  }
}

/// Phone, computer or tablet, from the device's name.
IconData deviceIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('windows') || n.contains('pc') || n.contains('mac') || n.contains('linux') || n.contains('desktop')) return CupertinoIcons.device_laptop;
  if (n.contains('web') || n.contains('browser')) return CupertinoIcons.globe;
  return CupertinoIcons.device_phone_portrait;
}

/// "기기 추가": how to sign in on another device (three steps).
Future<void> showAddDevice(BuildContext context) {
  final l = L.of(context);
  final p = paletteOf(context);
  Widget step(int n, String text) => Padding(
    padding: EdgeInsets.only(bottom: Tokens.space[3]),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
          child: Text(
            '$n',
            style: Tokens.preview.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: Tokens.space[2]),
        Expanded(
          child: Text(text, style: Tokens.body.style.copyWith(color: p.label)),
        ),
      ],
    ),
  );
  return showCupertinoModalPopup<void>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => GlassSheet(
      key: const Key('add-device-sheet'),
      title: l.addDeviceTitle,
      children: [
        const LaptopArt(),
        SizedBox(height: Tokens.space[4]),
        step(1, l.addDeviceStep1),
        step(2, l.addDeviceStep2),
        step(3, l.addDeviceStep3),
        SizedBox(height: Tokens.space[2]),
        AccentButton(text: l.done, onTap: () => Navigator.pop(c)),
      ],
    ),
  );
}

/// Asks for my account password once, then runs [run] with it.
class PasswordCheckPage extends StatefulWidget {
  const PasswordCheckPage({super.key, required this.title, required this.run});
  final String title;
  final Future<void> Function(String password) run;
  @override
  State<PasswordCheckPage> createState() => _PasswordCheckPageState();
}

class _PasswordCheckPageState extends State<PasswordCheckPage> {
  final field = TextEditingController();
  String? error;
  bool busy = false;

  Future<void> go() async {
    if (busy || field.text.isEmpty) return;
    setState(() => busy = true);
    try {
      await widget.run(field.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).lockWrong);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: widget.title,
      trailing: [
        CupertinoButton(
          key: const Key('pw-go'),
          padding: EdgeInsets.zero,
          onPressed: go,
          child: Text(l.done, style: TextStyle(color: p.accent)),
        ),
      ],
      children: [
        group(context, footer: error ?? l.passwordAgainInfo, error: error != null, [
          CupertinoTextField(
            key: const Key('pw-field'),
            controller: field,
            obscureText: true,
            autofocus: true,
            placeholder: l.currentPassword,
            decoration: null,
            padding: EdgeInsets.all(Tokens.space[3]),
            onSubmitted: (_) => go(),
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- password

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final old = TextEditingController(), next = TextEditingController(), again = TextEditingController();
  String? error;
  bool busy = false;

  static bool good(String v) => v.length >= 8 && RegExp('[A-Za-z]').hasMatch(v) && RegExp('[0-9]').hasMatch(v);

  Future<void> save() async {
    final l = L.of(context);
    if (busy) return;
    if (!good(next.text)) return setState(() => error = l.passwordRule);
    if (next.text != again.text) return setState(() => error = l.passwordMismatch);
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend.changePassword(old.text, next.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => error = l.lockWrong);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key k, TextEditingController c, String hint) =>
        CupertinoTextField(key: k, controller: c, obscureText: true, placeholder: hint, decoration: null, padding: EdgeInsets.all(Tokens.space[3]));
    return SettingsScaffold(
      title: l.changePassword,
      trailing: [
        CupertinoButton(
          key: const Key('pw-save'),
          padding: EdgeInsets.zero,
          onPressed: save,
          child: Text(l.save, style: TextStyle(color: p.accent)),
        ),
      ],
      children: [
        group(context, [field(const Key('pw-old'), old, l.currentPassword)]),
        group(context, footer: error ?? l.passwordRule, error: error != null, [
          field(const Key('pw-new'), next, l.newPassword),
          field(const Key('pw-again'), again, l.confirmPassword),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------- keys

class KeysPage extends StatefulWidget {
  const KeysPage({super.key});
  @override
  State<KeysPage> createState() => _KeysPageState();
}

class _KeysPageState extends State<KeysPage> {
  List<String>? keys;
  bool verified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (keys == null) load();
  }

  Future<void> load() async {
    final b = AppScope.of(context).backend;
    final k = await b.myKeys().catchError((_) => <String>['', '']);
    final v = await b.thisDeviceVerified().catchError((_) => false);
    if (mounted) {
      setState(() {
        keys = k;
        verified = v;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget keyRow(String title, String value) => IosTile(
      title: Text(title),
      subtitle: Text(
        _spaced(value),
        maxLines: 3,
        style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontFamily: 'monospace'),
      ),
      trailing: Icon(CupertinoIcons.doc_on_doc, color: p.accent, size: 20),
      onTap: () => Clipboard.setData(ClipboardData(text: value)),
    );
    final k = keys ?? const ['', ''];
    return SettingsScaffold(
      title: l.encryptionKeys,
      children: [
        group(context, [
          IosTile(
            leading: iconTile(
              verified ? p.tileGreen : Palette.tileOrange,
              verified ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_shield_fill,
            ),
            title: Text(verified ? l.deviceVerified : l.deviceNotVerified),
          ),
        ]),
        group(context, footer: l.keysInfo, [keyRow(l.myIdentityKey, k.isNotEmpty ? k[0] : ''), keyRow(l.thisDeviceKey, k.length > 1 ? k[1] : '')]),
      ],
    );
  }

  static String _spaced(String v) => [for (var i = 0; i < v.length; i += 4) v.substring(i, (i + 4).clamp(0, v.length))].join(' ');
}

/// "오류 내용 보기": the errors kept on this phone, newest first, to copy.
class ErrorLogPage extends StatefulWidget {
  const ErrorLogPage({super.key});
  @override
  State<ErrorLogPage> createState() => _ErrorLogPageState();
}

class _ErrorLogPageState extends State<ErrorLogPage> {
  bool copied = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final all = ErrorLog.items;
    return SettingsScaffold(
      title: l.errorLog,
      children: [
        group(context, [
          if (all.isEmpty)
            IosTile(
              title: Text(l.errorLogEmpty, style: TextStyle(color: p.secondaryLabel)),
            ),
          for (final (t, text) in all)
            IosTile(
              title: Text(
                text,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: Tokens.caption.style.copyWith(color: p.label),
              ),
              subtitle: Text(shortTime(context, t)),
            ),
        ]),
        if (all.isNotEmpty)
          group(context, [
            IosTile(
              key: const Key('error-copy'),
              title: Text(copied ? l.copied : l.errorLogCopy, style: TextStyle(color: p.accent)),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: [for (final (t, x) in all) '${t.toIso8601String()} $x'].join('\n\n')));
                if (mounted) setState(() => copied = true);
              },
            ),
          ]),
      ],
    );
  }
}
