// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Hold the back button in a chat (Telegram tip 321, like Safari's back
// button on iPhone): a small menu of the chats I came through; one tap
// jumps straight back there. Two-pane PC: the chats opened just before.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

/// The chat pages open on top of each other (phone), oldest first.
class ChatTrail {
  ChatTrail._();
  static final stack = <(String, Route<void>)>[];

  /// Two panes: the chats shown before, newest first (at most 5).
  static final recent = <String>[];

  static void shown(String roomId) {
    recent
      ..remove(roomId)
      ..insert(0, roomId);
    if (recent.length > 6) recent.removeLast();
  }
}

/// iOS 27 pull-down menu sizes: 250 wide, 44 rows, 26 corners.
const _menuWidth = 250.0, _row = 44.0, _corner = 26.0;

/// The menu for the chat [roomId] that is on screen now.
Future<void> openBackTrail(BuildContext context, String roomId, {required bool wide, required void Function(String roomId, String name) open}) async {
  final app = AppScope.read(context);
  final nav = Navigator.of(context);
  final byId = {for (final c in app.chats) c.roomId: c};
  // Nearest first. Phone: the chat pages under this one; PC: the last ones shown.
  final ids = wide
      ? [
          for (final id in ChatTrail.recent)
            if (id != roomId && byId.containsKey(id)) id,
        ].take(5).toList()
      : [
          for (final e in ChatTrail.stack.reversed)
            if (e.$1 != roomId && byId.containsKey(e.$1)) e.$1,
        ];
  if (ids.isEmpty) return;
  HapticFeedback.mediumImpact();
  final box = context.findRenderObject() as RenderBox?;
  final at = box == null ? Offset.zero : box.localToGlobal(Offset(0, box.size.height + Tokens.space[1]));
  final pick = await nav.push<String>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (c, a, _) => _TrailMenu(anim: a, at: at, ids: ids),
    ),
  );
  if (pick == null) return;
  if (wide) {
    final c = byId[pick];
    if (c != null) open(pick, c.name);
    return;
  }
  final route = ChatTrail.stack.lastWhere((e) => e.$1 == pick).$2;
  nav.popUntil((r) => r == route || r.isFirst);
}

class _TrailMenu extends StatelessWidget {
  const _TrailMenu({required this.anim, required this.at, required this.ids});
  final Animation<double> anim;
  final Offset at;
  final List<String> ids;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final app = AppScope.of(context);
    final l = L.of(context);
    final byId = {for (final c in app.chats) c.roomId: c};
    final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('trail-close'),
            onTap: () => Navigator.pop(context),
            child: const ColoredBox(color: Color(0x00000000)),
          ),
        ),
        Positioned(
          left: at.dx,
          top: at.dy,
          child: FadeTransition(
            opacity: curve,
            // iOS menus grow out of the button they belong to.
            child: ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(curve),
              alignment: Alignment.topLeft,
              child: LiquidGlass(
                key: const Key('back-trail'),
                radius: _corner,
                child: SizedBox(
                  width: _menuWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < ids.length; i++) ...[
                        if (i > 0) Container(height: 1 / MediaQuery.devicePixelRatioOf(context), color: p.separator),
                        GestureDetector(
                          key: Key('trail-${ids[i]}'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.pop(context, ids[i]),
                          child: SizedBox(
                            height: _row,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                              child: Row(
                                children: [
                                  Avatar(
                                    name: byId[ids[i]]!.roomId == app.savedRoomId ? l.savedMessages : byId[ids[i]]!.name,
                                    size: 28,
                                    squircle: !byId[ids[i]]!.isDirect,
                                    userId: byId[ids[i]]!.isDirect ? byId[ids[i]]!.peer : null,
                                    roomId: ids[i],
                                  ),
                                  SizedBox(width: Tokens.space[2]),
                                  Expanded(
                                    child: Text(
                                      byId[ids[i]]!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Tokens.body.style.copyWith(color: p.label),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
