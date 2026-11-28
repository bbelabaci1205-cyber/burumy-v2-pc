// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Main screen: four tabs (contacts, calls, chats, settings) under a floating
// glass tab bar (Eric's v1 look, 2026-11-24). The bar hides while a page is
// open on top of a tab.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';

import '../core/app_state.dart';
import '../core/chat_badge.dart';
import '../core/features.dart';
import '../core/share_in.dart';
import '../l10n/app_localizations.dart';
import 'call_page.dart';
import 'calls_page.dart';
import 'chat_list_page.dart';
import 'chat_page.dart';
import 'contacts_page.dart';
import 'glass.dart';
import 'in_app_notice.dart';
import 'ios_route.dart';
import 'accounts_ui.dart';
import 'settings_page.dart';
import 'share_in.dart';
import 'wide.dart';

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key, this.wide = false});

  /// Left pane of the two-pane window: pages open on the right instead.
  final bool wide;

  /// A tab page that needs the bottom for its own bar (chat list edit mode).
  static final hideBar = ValueNotifier<bool>(false);

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> with WidgetsBindingObserver {
  int index = 2;

  @override
  void initState() {
    super.initState();
    // 다른 앱에서 보내기 (tips 350 + 182): picked up when the app opens or
    // comes back, and only once the app is unlocked (this screen is behind
    // the lock).
    WidgetsBinding.instance.addObserver(this);
    ShareInbox.waiting.addListener(shared);
    if (Features.shareLinks) unawaited(ShareInbox.check());
    WidgetsBinding.instance.addPostFrameCallback((_) => shared());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    if (st == AppLifecycleState.resumed && Features.shareLinks) unawaited(ShareInbox.check());
  }

  void shared() {
    final items = ShareInbox.waiting.value;
    if (items == null || !mounted) return;
    ShareInbox.waiting.value = null;
    if (!Features.shareLinks) {
      for (final i in items) {
        unawaited(i.drop());
      }
      return;
    }
    final c = keys[index].currentContext ?? context;
    unawaited(openShareIn(c, items));
  }

  final keys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  late final depth = List.generate(4, (_) => ValueNotifier<int>(0));

  // Made once: a new observer on every rebuild would restart its count.
  late final observers = [for (final d in depth) _Depth(d)];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ShareInbox.waiting.removeListener(shared);
    for (final d in depth) {
      d.dispose();
    }
    super.dispose();
  }

  void tap(int i) {
    if (i == index) {
      // Tapping the open tab again goes back to its first page.
      keys[i].currentState?.popUntil((r) => r.isFirst);
    } else {
      setState(() => index = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final tabs = [
      GlassTab(CupertinoIcons.person_crop_circle, CupertinoIcons.person_crop_circle_fill, l.tabContacts, key: const Key('tab-contacts')),
      GlassTab(CupertinoIcons.phone, CupertinoIcons.phone_fill, l.tabCalls, key: const Key('tab-calls')),
      GlassTab(
        CupertinoIcons.chat_bubble_2,
        CupertinoIcons.chat_bubble_2_fill,
        l.tabChats,
        key: const Key('tab-chats'),
        badge: badgeCount(AppScope.of(context).chats, AppScope.of(context).settings),
      ),
      GlassTab(CupertinoIcons.gear, CupertinoIcons.gear_solid, l.tabSettings, key: const Key('tab-settings')),
    ];
    const pages = [ContactsPage(), CallsPage(), ChatListPage(), SettingsPage()];
    return CallWatcher(
      child: InAppNotices(
        onOpen: (id, name) {
          final c = keys[index].currentContext;
          if (c != null) unawaited(openChat(c, id, name));
        },
        child: Stack(
          children: [
            IndexedStack(
              index: index,
              children: [
                for (var i = 0; i < 4; i++)
                  widget.wide
                      ? PaneNavigator(
                          key: keys[i],
                          observers: [observers[i]],
                          onGenerateRoute: (_) => IosPageRoute<void>(builder: (_) => pages[i]),
                        )
                      : CupertinoTabView(navigatorKey: keys[i], navigatorObservers: [observers[i]], builder: (_) => pages[i]),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ListenableBuilder(
                listenable: Listenable.merge([depth[index], HomeTabs.hideBar]),
                builder: (_, _) => IgnorePointer(
                  ignoring: depth[index].value > 1 || HomeTabs.hideBar.value,
                  child: AnimatedOpacity(
                    opacity: depth[index].value > 1 || HomeTabs.hideBar.value ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: FloatingTabBar(tabs: tabs, index: index, onTap: tap, onHold: (i) => i == 3 ? showAccountsMenu(context) : null),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Counts the pages open in one tab.
class _Depth extends NavigatorObserver {
  _Depth(this.n);
  final ValueNotifier<int> n;
  int _d = 0;

  // Navigator calls these while it rebuilds: tell the bar after the frame.
  void _set(int d) {
    _d = d;
    SchedulerBinding.instance.addPostFrameCallback((_) => n.value = _d);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_d + 1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_d - 1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_d - 1);
  }
}
