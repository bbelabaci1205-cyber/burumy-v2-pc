// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 통합 검색 (4대 메신저 보드 '우리식으로' 2번, Eric 2026-11-28; WeChat
// 搜一搜, our way). One search box finds my chats, my messages, the posts of
// channels I follow, and the app's own features and settings. Everything
// here is looked up on this phone: the feature list ships with the app,
// sticker packs too, and the channel posts come from my own phone's search.
// No new public search (the public parts stay as tip 533 left them).
import 'package:flutter/cupertino.dart';

import '../core/ai_friend.dart';
import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'ai_friend_page.dart';
import 'app_lock_page.dart';
import 'common.dart';
import 'folders_page.dart';
import 'ios_route.dart';
import 'my_plans_page.dart';
import 'settings_more.dart' show FaqPage;
import 'settings_notify.dart' show NotificationsPage;
import 'settings_pages.dart';
import 'sticker_shop.dart';

class FeatureHit {
  const FeatureHit({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.where = '',
    this.words = const [],
    required this.open,
  });
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  /// Where it lives ("설정 › 대화"), empty for a page of its own.
  final String where;

  /// Other words people type for it.
  final List<String> words;
  final void Function(BuildContext context) open;

  bool matches(String w) => title.toLowerCase().contains(w) || words.any((x) => x.contains(w) || (w.length >= 2 && w.contains(x)));
}

void _push(BuildContext c, Widget page) => Navigator.of(c).push(IosPageRoute<void>(builder: (_) => page));

/// The app's features and settings pages, in the words the app uses.
List<FeatureHit> featureIndex(AppState app, L l, Palette p) {
  final chats = '${l.tabSettings} › ${l.settingsChatsPage}';
  return [
    FeatureHit(
      id: 'ai',
      title: l.searchFeatAiFriend,
      icon: CupertinoIcons.sparkles,
      color: Palette.tilePurple,
      words: const ['ai', '인공지능', '챗봇', '질문'],
      open: (c) => openAiFriend(c),
    ),
    FeatureHit(
      id: 'shop',
      title: l.shopTitle,
      icon: CupertinoIcons.bag_fill,
      color: Palette.tileOrange,
      words: const ['sticker', '이모티콘', '스티커'],
      open: (c) => _push(c, const StickerShopPage()),
    ),
    FeatureHit(
      id: 'memories',
      title: l.searchFeatMemories,
      icon: CupertinoIcons.photo_on_rectangle,
      color: p.tileGreen,
      where: chats,
      words: const ['추억', '메모리', 'memories'],
      open: (c) => _push(c, const ChatSettingsPage()),
    ),
    FeatureHit(
      id: 'best',
      title: l.searchFeatBestFriend,
      icon: CupertinoIcons.heart_fill,
      color: Palette.tileRed,
      where: chats,
      words: const ['하트', '베프', '친한'],
      open: (c) => _push(c, const ChatSettingsPage()),
    ),
    FeatureHit(
      id: 'camera',
      title: l.searchFeatPullCamera,
      icon: CupertinoIcons.camera_fill,
      color: Palette.tileGrey,
      where: chats,
      words: const ['카메라', 'camera', '스토리'],
      open: (c) => _push(c, const ChatSettingsPage()),
    ),
    FeatureHit(
      id: 'lock',
      title: l.searchFeatLock,
      icon: CupertinoIcons.lock_fill,
      color: Palette.tileBlue,
      where: '${l.tabSettings} › ${l.settingsPrivacy}',
      words: const ['잠금', '비밀번호', 'lock', 'password', '암호'],
      open: (c) => _push(c, const AppLockPage()),
    ),
    FeatureHit(
      id: 'look',
      title: l.settingsAppearance,
      icon: CupertinoIcons.paintbrush_fill,
      color: Palette.tileCyan,
      words: const ['테마', '다크', '배경', '글자', 'theme', 'dark'],
      open: (c) => _push(c, const AppearancePage()),
    ),
    FeatureHit(
      id: 'notify',
      title: l.settingsNotifications,
      icon: CupertinoIcons.bell_fill,
      color: Palette.tileRed,
      words: const ['알림', '소리', 'notification'],
      open: (c) => _push(c, const NotificationsPage()),
    ),
    FeatureHit(
      id: 'chats',
      title: l.settingsChatsPage,
      icon: CupertinoIcons.chat_bubble_fill,
      color: p.tileGreen,
      words: const ['대화', 'chat'],
      open: (c) => _push(c, const ChatSettingsPage()),
    ),
    FeatureHit(
      id: 'folders',
      title: l.chatFolders,
      icon: CupertinoIcons.folder_fill,
      color: Palette.tileOrange,
      words: const ['폴더', 'folder'],
      open: (c) => _push(c, const FoldersPage()),
    ),
    FeatureHit(
      id: 'data',
      title: l.dataStorage,
      icon: CupertinoIcons.chart_pie_fill,
      color: Palette.tileTeal,
      words: const ['저장', '용량', '데이터', 'storage'],
      open: (c) => _push(c, const DataPage()),
    ),
    FeatureHit(
      id: 'privacy',
      title: l.settingsPrivacy,
      icon: CupertinoIcons.checkmark_shield_fill,
      color: Palette.tileBlue,
      words: const ['개인정보', '보안', '차단', 'privacy'],
      open: (c) => _push(c, const PrivacyPage()),
    ),
    FeatureHit(
      id: 'devices',
      title: l.devices,
      icon: CupertinoIcons.device_laptop,
      color: p.tileBlack,
      words: const ['기기', 'pc', '컴퓨터', 'device'],
      open: (c) => _push(c, const DevicesPage()),
    ),
    FeatureHit(
      id: 'plans',
      title: l.myPlans,
      icon: CupertinoIcons.calendar,
      color: Palette.tileRed,
      words: const ['일정', '약속', 'plan'],
      open: (c) => _push(c, const MyPlansPage()),
    ),
    FeatureHit(
      id: 'faq',
      title: l.faq,
      icon: CupertinoIcons.question_circle_fill,
      color: Palette.tileTeal,
      words: const ['도움', '질문', 'help'],
      open: (c) => _push(c, const FaqPage()),
    ),
  ];
}

List<FeatureHit> findFeatures(AppState app, L l, Palette p, String words) {
  final w = words.trim().toLowerCase();
  if (w.isEmpty) return const [];
  return [
    for (final f in featureIndex(app, l, p))
      // The AI friend only where the phone has its own AI.
      if (f.id != 'ai' || AiFriend.listed(app))
        if (f.matches(w)) f,
  ];
}

/// Sticker packs whose name has the words.
List<StickerPack> findPacks(L l, String words) {
  final w = words.trim().toLowerCase();
  if (w.length < 2) return const [];
  return [
    for (final k in stickerPacks)
      if (packName(l, k.id).toLowerCase().contains(w)) k,
  ];
}

/// The setting's tile, in the avatars' space so the rows line up.
Widget featureLeading(FeatureHit f) => SizedBox.square(
  dimension: Tokens.memberAvatar,
  child: Center(child: iconTile(f.color, f.icon)),
);
