// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Wide screens (the PC app, a big browser window): two panes, as in v1's
// Windows app. The phone screens stay as they are on the left (tabs, chat
// list, settings), and what they open shows on the right: a chat, or a
// settings page (kept to a readable width). Full-screen things (camera,
// stories, calls, sheets) still cover the whole window.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show ChatPage;
import 'common.dart';
import 'glass.dart';
import 'home.dart';
import 'ios_route.dart';

class Wide {
  /// From this window width on, two panes.
  static const minWidth = 900.0;

  /// The left pane (a phone's width plus a little).
  static const listWidth = 400.0;

  /// Settings-like pages on the right are kept this wide, centred.
  static const pageWidth = 640.0;

  /// The right pane's navigator while two panes are shown.
  static final detail = GlobalKey<NavigatorState>();

  /// The chat open on the right (its row in the list is marked).
  static final selected = ValueNotifier<String?>(null);

  static bool get on => detail.currentState != null;

  /// Shows [route] on the right, in place of what was there.
  static Future<T?> show<T>(Route<T> route, {String? roomId}) {
    selected.value = roomId;
    return detail.currentState!.pushAndRemoveUntil(route, (r) => r.isFirst);
  }
}

bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= Wide.minWidth;

/// The navigator a popup, menu or page opened here should use: on wide
/// screens the pane it was opened from (right stays right, left stays left,
/// Eric 2026-11-24), on a phone the whole screen.
NavigatorState paneNav(BuildContext context) => Navigator.of(context, rootNavigator: !Wide.on);

/// A page that slides up over everything on a phone (new chat, forward,
/// templates, a form). On wide screens it opens in the right pane on top of
/// what is there, so the chat list stays on the left; closing it goes back.
Future<T?> openSheet<T>(BuildContext context, WidgetBuilder builder) {
  if (Wide.on) return Wide.detail.currentState!.push<T>(IosPageRoute<T>(builder: (c) => WidePage(child: builder(c))));
  return Navigator.of(context, rootNavigator: true).push<T>(IosPageRoute<T>(fullscreenDialog: true, builder: builder));
}

/// The two panes.
class WideHome extends StatelessWidget {
  const WideHome({super.key});

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final mq = MediaQuery.of(context);
    return ColoredBox(
      color: p.background,
      child: Row(
        children: [
          SizedBox(
            width: Wide.listWidth,
            child: MediaQuery(
              data: mq.copyWith(size: Size(Wide.listWidth, mq.size.height)),
              child: const HomeTabs(wide: true),
            ),
          ),
          Container(width: 1 / mq.devicePixelRatio, color: p.separator),
          Expanded(
            child: MediaQuery(
              data: mq.copyWith(size: Size(mq.size.width - Wide.listWidth - 1 / mq.devicePixelRatio, mq.size.height)),
              child: ClipRect(
                child: Navigator(
                  key: Wide.detail,
                  observers: [_Selected()],
                  onGenerateRoute: (_) => PageRouteBuilder<void>(pageBuilder: (_, _, _) => const _Nothing()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clears the mark in the list when the chat on the right is closed.
class _Selected extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.isFirst ?? false) Wide.selected.value = null;
  }
}

class _Nothing extends StatelessWidget {
  const _Nothing();

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return ColoredBox(
      key: const Key('wide-empty'),
      color: p.chatBackground,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(L.of(context).wideEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        ),
      ),
    );
  }
}

/// A tab's navigator in the left pane: pages it opens go to the right.
class PaneNavigator extends Navigator {
  const PaneNavigator({super.key, super.observers, super.onGenerateRoute});

  @override
  NavigatorState createState() => _PaneNavigatorState();
}

class _PaneNavigatorState extends NavigatorState {
  @override
  Future<T?> push<T extends Object?>(Route<T> route) {
    if (Wide.on && route is PageRoute<T> && !route.fullscreenDialog) {
      // Settings-like pages: the same page, kept to a readable width.
      final r = route is CupertinoPageRoute<T>
          ? IosPageRoute<T>(
              settings: route.settings,
              builder: (c) {
                final page = route.builder(c);
                return page is ChatPage ? page : WidePage(child: page);
              },
            )
          : route;
      return Wide.show(r);
    }
    return super.push(route);
  }
}

/// Keeps a settings-like page to [Wide.pageWidth] on wide screens.
class WidePage extends StatelessWidget {
  const WidePage({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (!Wide.on || w <= Wide.pageWidth) return child;
    final mq = MediaQuery.of(context);
    return ColoredBox(
      color: paletteOf(context).background,
      child: Center(
        child: SizedBox(
          width: Wide.pageWidth,
          child: MediaQuery(
            data: mq.copyWith(size: Size(Wide.pageWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Phone-shaped pages (camera, story viewer, story composer) on a wide or
/// landscape window: kept to a 9:16 card in the middle on black, as Telegram
/// Desktop shows stories. [onClose] adds an X at the top-right corner of the
/// window (the page's own X is then hidden, see [PhoneFrame.on]).
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child, this.onClose});
  final Widget child;
  final VoidCallback? onClose;

  /// True inside a frame that has its own corner X.
  static bool on(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_Framed>()?.closes ?? false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final w = box.maxWidth, h = box.maxHeight;
      if (!w.isFinite || !h.isFinite || w <= h * 0.75) return child;
      final mq = MediaQuery.of(c);
      final fw = math.min(w, h * 9 / 16);
      return ColoredBox(
        color: const Color(0xFF000000),
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: fw,
                height: h,
                child: MediaQuery(
                  data: mq.copyWith(size: Size(fw, h)),
                  child: _Framed(closes: onClose != null, child: child),
                ),
              ),
            ),
            if (onClose != null)
              Positioned(
                top: mq.padding.top + Tokens.space[2],
                right: Tokens.space[3],
                child: GlassCircle(
                  key: const Key('frame-close'),
                  onTap: onClose,
                  child: const Icon(CupertinoIcons.xmark, color: Color(0xFFFFFFFF), size: 22),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _Framed extends InheritedWidget {
  const _Framed({required this.closes, required super.child});
  final bool closes;

  @override
  bool updateShouldNotify(_Framed old) => old.closes != closes;
}
