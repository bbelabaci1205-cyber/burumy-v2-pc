// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// iOS 27 scroll edge: a top bar is clear while the page is at the top, and
// turns into frosted glass with a hairline once something scrolls under it.
// One listener at the app root tells each page's top bar whether its own
// page has scrolled (pages are told apart by their CupertinoPageScaffold).
import 'package:flutter/cupertino.dart';

class ScrollEdge {
  static final _flags = Expando<ValueNotifier<bool>>('scrollEdge');

  static Element? _page(BuildContext context) {
    Element? found;
    if (context is Element && context.widget is CupertinoPageScaffold) return context;
    context.visitAncestorElements((e) {
      if (e.widget is CupertinoPageScaffold) {
        found = e;
        return false;
      }
      return true;
    });
    return found;
  }

  /// Whether the page that holds [context] has content under its top bar.
  static ValueNotifier<bool>? of(BuildContext context) {
    final page = _page(context);
    if (page == null) return null;
    return _flags[page] ??= ValueNotifier(false);
  }

  static bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final ctx = n.context;
    if (ctx == null) return false;
    final flag = of(ctx);
    if (flag == null) return false;
    // Lists that start at the bottom (chats) are "under the bar" whenever
    // they are not scrolled all the way back.
    final m = n.metrics;
    final under = m.axisDirection == AxisDirection.up ? m.extentAfter > 1 : m.pixels > m.minScrollExtent + 1;
    if (flag.value != under) flag.value = under;
    return false;
  }
}

/// Put once around the app: feeds [ScrollEdge].
class ScrollEdgeListener extends StatelessWidget {
  const ScrollEdgeListener({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollNotification>(onNotification: ScrollEdge._onScroll, child: child);
}
