// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Calls tab: every call this phone knows about (all / missed), built from
// the encrypted chats kept on this phone. Tap a line to call back.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../core/login_safety.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'call_page.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'login_safety_ui.dart';
import 'wide.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});
  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  bool missedOnly = false;
  List<CallLogItem>? log;

  /// 통화 기록 지우기 (tip 247): picking calls, and calls waiting 5 s.
  bool editing = false;
  final picked = <String>{};
  Set<String> waiting = const {};
  AppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (!identical(app, _app)) {
      _app?.removeListener(load);
      _app = app..addListener(load);
      load();
    }
  }

  @override
  void dispose() {
    _app?.removeListener(load);
    super.dispose();
  }

  Future<void> load() async {
    try {
      final l = await _app!.backend.callLog();
      if (mounted) setState(() => log = l);
    } catch (_) {
      if (mounted) setState(() => log = const []);
    }
  }

  static bool isMissed(CallLogItem c) => !c.mine && (c.call.state == 'missed' || c.call.state == 'busy');

  /// The ••• button: pick calls, or clear them all.
  Future<void> more() async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) => IosActionSheet(
        actions: [
          CupertinoActionSheetAction(key: const Key('calls-select'), onPressed: () => Navigator.pop(c, 'select'), child: Text(l.callsSelect)),
          CupertinoActionSheetAction(
            key: const Key('calls-clear'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'clear'),
            child: Text(l.callsClearAll),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    if (pick == 'select') setState(() => editing = true);
    if (pick == 'clear') await forget(shownNow());
  }

  List<CallLogItem> shownNow() {
    final hidden = LoginSafety.hiddenCalls(_app!);
    final all = [
      for (final c in log ?? const <CallLogItem>[])
        if (!hidden.contains(c.call.id) && !waiting.contains(c.call.id)) c,
    ];
    return missedOnly ? all.where(isMissed).toList() : all;
  }

  /// Asks "for me / for both" (both only when every call is from a 1:1
  /// chat), hides them at once, deletes after the 5-second undo.
  Future<void> forget(List<CallLogItem> calls) async {
    if (calls.isEmpty) return;
    final l = L.of(context);
    final app = _app!;
    final direct = calls.every((c) => app.chats.where((x) => x.roomId == c.roomId).firstOrNull?.isDirect ?? false);
    final one = {for (final c in calls) c.roomId}.length == 1;
    final name = one ? app.chats.where((x) => x.roomId == calls.first.roomId).firstOrNull?.name : null;
    final both = await askDeleteFor(context, title: l.callsDeleteAsk(calls.length), direct: direct, peerName: name);
    if (both == null || !mounted) return;
    final ids = {for (final c in calls) c.call.id};
    setState(() {
      waiting = {...waiting, ...ids};
      editing = false;
      picked.clear();
    });
    showUndoCountdown(
      context,
      (n) => l.callsDeleteIn(n),
      () async {
        await LoginSafety.forgetCalls(app, calls, both: both);
        if (mounted) setState(() => waiting = waiting.difference(ids));
        await load();
      },
      onUndo: () {
        if (mounted) setState(() => waiting = waiting.difference(ids));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final shown = shownNow();
    final edit = Features.loginSafety;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar(
        leading: [
          if (edit && editing)
            GlassCircle(
              key: const Key('calls-done'),
              onTap: () => setState(() {
                editing = false;
                picked.clear();
              }),
              child: GlassCircle.icon(context, CupertinoIcons.check_mark),
            )
          else
            GlassCircle(key: const Key('calls-more'), onTap: edit ? more : null, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)),
        ],
        middle: SizedBox(
          width: 180,
          child: IosSegmented<bool>(
            key: const Key('calls-filter'),
            groupValue: missedOnly,
            children: {false: Text(l.callsAll), true: Text(l.callsMissed)},
            onValueChanged: (v) => setState(() => missedOnly = v ?? false),
          ),
        ),
        trailing: [
          GlassCircle(
            key: const Key('calls-new'),
            onTap: () => openSheet<void>(context, (_) => const _PickToCall()),
            child: GlassCircle.icon(context, CupertinoIcons.phone_badge_plus),
          ),
        ],
      ),
      child: log == null
          ? const SizedBox()
          : shown.isEmpty
          ? EmptyState(text: missedOnly ? l.callsEmptyMissed : l.callsEmpty)
          : Stack(
              children: [
                ListView.separated(
                  padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[1], bottom: FloatingTabBar.room(context)),
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => Padding(
                    padding: EdgeInsets.only(left: 44 + Tokens.space[3] * 2),
                    child: Container(height: 1, color: p.separator),
                  ),
                  itemBuilder: (c, i) => _CallRow(
                    item: shown[i],
                    picking: editing,
                    picked: picked.contains(shown[i].call.id),
                    onPick: () => setState(() => picked.contains(shown[i].call.id) ? picked.remove(shown[i].call.id) : picked.add(shown[i].call.id)),
                  ),
                ),
                // Picked calls: one red button above the tab bar.
                if (editing)
                  Positioned(
                    left: Tokens.space[3],
                    right: Tokens.space[3],
                    bottom: FloatingTabBar.room(context) + Tokens.space[1],
                    child: GestureDetector(
                      key: const Key('calls-delete'),
                      onTap: picked.isEmpty
                          ? null
                          : () => forget([
                              for (final c in shown)
                                if (picked.contains(c.call.id)) c,
                            ]),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 160),
                        opacity: picked.isEmpty ? 0.4 : 1,
                        child: LiquidGlass(
                          radius: Tokens.capsule,
                          child: Container(
                            height: Tokens.closeButton,
                            alignment: Alignment.center,
                            child: Text(
                              l.callsDeleteN(picked.length),
                              style: Tokens.body.style.copyWith(color: Palette.tileRed, fontWeight: Tokens.semi),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.item, this.picking = false, this.picked = false, this.onPick});
  final CallLogItem item;
  final bool picking;
  final bool picked;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final app = AppScope.of(context);
    final c = item.call;
    final name = app.chats.where((x) => x.roomId == item.roomId).firstOrNull?.name ?? displayId(item.from);
    final missed = _CallsPageState.isMissed(item);
    final what = switch (c.state) {
      'missed' || 'busy' => item.mine ? l.callLineCancelled : l.callLineMissed,
      'declined' => l.callLineDeclined,
      _ => item.mine ? l.callLineOut : l.callLineIn,
    };
    final talked = c.answered != null && c.ended != null ? ' · ${callClock(c.ended!.difference(c.answered!))}' : '';
    return GestureDetector(
      key: Key('call-row-${c.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: picking ? onPick : () => startCall(context, item.roomId, name, video: c.video),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
        child: Row(
          children: [
            // iOS edit circle (Telegram calls "편집").
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: picking
                  ? Padding(
                      padding: EdgeInsets.only(right: Tokens.space[2]),
                      child: Icon(
                        picked ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                        key: Key('call-pick-${c.id}'),
                        size: 24,
                        color: picked ? p.accent : p.chevron,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Avatar(name: name, size: 44),
            SizedBox(width: Tokens.space[3]),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: missed ? Palette.tileRed : p.label),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(item.mine ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_left, size: 13, color: p.secondaryLabel),
                      const SizedBox(width: 3),
                      Icon(c.video ? CupertinoIcons.video_camera_solid : CupertinoIcons.phone_fill, size: 13, color: p.secondaryLabel),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text('$what$talked', maxLines: 1, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(shortTime(context, c.started), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          ],
        ),
      ),
    );
  }
}

/// New call: pick a 1:1 chat, then voice or video.
class _PickToCall extends StatelessWidget {
  const _PickToCall();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final dms = [
      for (final c in AppScope.of(context).chats)
        if (c.isDirect) c,
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar(title: l.callsNew, back: true),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          for (final c in dms)
            IosTile(
              leading: Avatar(name: c.name, size: 40),
              title: Text(c.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop();
                      startCall(context, c.roomId, c.name, video: false);
                    },
                    child: Icon(CupertinoIcons.phone, color: p.accent),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.of(context).pop();
                      startCall(context, c.roomId, c.name, video: true);
                    },
                    child: Icon(CupertinoIcons.video_camera, color: p.accent),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Centred Burumy mark with a line of text (empty lists).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/brand/symbol_green.png', width: 190, color: p.accent, colorBlendMode: BlendMode.srcIn),
          SizedBox(height: Tokens.space[4]),
          Text(
            text,
            key: const Key('empty-text'),
            style: Tokens.body.style.copyWith(color: p.secondaryLabel),
          ),
        ],
      ),
    );
  }
}
