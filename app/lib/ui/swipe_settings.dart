// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > 대화 > 대화 목록 밀기 (Telegram tip 260): which action sits at
// the outer end of each swipe side. A sample row on top slides by itself to
// show the button that was just chosen.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart';
import 'common.dart';
import 'ios.dart';
import 'settings_kit.dart';

/// The label of a swipe choice ('' = the usual buttons).
String swipeChoiceLabel(L l, String id) => switch (id) {
  'read' => l.markRead,
  'pin' => l.swipePin,
  'mute' => l.swipeMute,
  'archive' => l.swipeArchive,
  'delete' => l.delete,
  _ => l.swipeDefault,
};

class SwipeActionsPage extends StatefulWidget {
  const SwipeActionsPage({super.key});
  @override
  State<SwipeActionsPage> createState() => _SwipeActionsPageState();
}

class _SwipeActionsPageState extends State<SwipeActionsPage> with SingleTickerProviderStateMixin {
  /// -1 = pulled left (buttons on the right), 1 = pulled right, 0 = rest.
  late final slide = AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => show(1));
  }

  @override
  void dispose() {
    slide.dispose();
    super.dispose();
  }

  /// Slides the sample open to [side], holds, and lets it go back.
  Future<void> show(double side) async {
    if (!mounted) return;
    if (AppScope.read(context).calm) {
      slide.value = side;
      return;
    }
    await slide.animateTo(0, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
    if (!mounted) return;
    await slide.animateTo(side, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  Future<void> pick(String pref, String id, double side) async {
    final s = AppScope.read(context);
    await s.setPref(pref, id);
    // The other side can't keep the same action.
    final other = pref == swipeRightPref ? swipeLeftPref : swipeRightPref;
    if (id.isNotEmpty && s.pref(other, '') == id) await s.setPref(other, '');
    await show(side);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    Widget choices(String pref, double side) => group(context, header: side > 0 ? l.swipeToRight : l.swipeToLeft, [
      for (final id in ['', ...swipeActions])
        IosTile(
          key: Key('swipe-pick-${side > 0 ? 'r' : 'l'}-${id.isEmpty ? 'default' : id}'),
          title: Text(swipeChoiceLabel(l, id)),
          trailing: s.pref(pref, '') == id ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
          onTap: () => pick(pref, id, side),
        ),
    ]);
    return SettingsScaffold(
      title: l.swipeSettings,
      children: [
        group(context, footer: l.swipeSettingsInfo, [SwipeSample(slide: slide)]),
        choices(swipeRightPref, 1),
        choices(swipeLeftPref, -1),
      ],
    );
  }
}

/// A made-up chat row opened to one side, with the real buttons.
class SwipeSample extends StatelessWidget {
  const SwipeSample({super.key, required this.slide});
  final AnimationController slide;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final sample = ChatPreview(
      roomId: '!swipe-sample',
      name: l.swipeSampleName,
      isDirect: true,
      encrypted: true,
      unread: 1,
      last: Msg(id: 's', sender: '', body: l.swipeSampleText, time: DateTime(2026), mine: false, kind: 'text'),
    );
    final (lead, trail) = swipeSides(context, sample);
    const button = 60.0, dot = 44.0;
    Widget circles(List<(String, String, IconData, Color)> items) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final it in items)
          SizedBox(
            width: button,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(color: it.$4, shape: BoxShape.circle),
                  child: Icon(it.$3, color: const Color(0xFFFFFFFF), size: 22),
                ),
                SizedBox(height: Tokens.space[0]),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(it.$2, maxLines: 1, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ),
              ],
            ),
          ),
      ],
    );
    return SizedBox(
      key: const Key('swipe-sample'),
      height: Tokens.chatRow,
      child: AnimatedBuilder(
        animation: slide,
        builder: (_, _) {
          final v = slide.value;
          final open = (v > 0 ? lead.length : trail.length) * button;
          return ClipRect(
            child: Stack(
              children: [
                if (v > 0) Positioned(left: 0, top: 0, bottom: 0, child: circles(lead)),
                if (v < 0) Positioned(right: 0, top: 0, bottom: 0, child: circles(trail)),
                Transform.translate(
                  offset: Offset(v * open, 0),
                  child: ColoredBox(
                    color: v == 0 ? p.card : Color.alphaBlend(p.incoming, p.card),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      child: Row(
                        children: [
                          Avatar(name: sample.name, size: Tokens.chatAvatar),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sample.name,
                                  maxLines: 1,
                                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  sample.last!.body ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
