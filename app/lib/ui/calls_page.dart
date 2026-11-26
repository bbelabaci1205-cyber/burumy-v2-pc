// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Calls tab: every call this phone knows about (all / missed), built from
// the encrypted chats kept on this phone. Tap a line to call back.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'call_page.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'wide.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});
  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  bool missedOnly = false;
  List<CallLogItem>? log;
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

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final all = log ?? const <CallLogItem>[];
    final shown = missedOnly ? all.where(isMissed).toList() : all;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar(
        leading: [GlassCircle(child: GlassCircle.icon(context, CupertinoIcons.ellipsis))],
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
          : ListView.separated(
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[1], bottom: FloatingTabBar.room(context)),
              itemCount: shown.length,
              separatorBuilder: (_, _) => Padding(
                padding: EdgeInsets.only(left: 44 + Tokens.space[3] * 2),
                child: Container(height: 1, color: p.separator),
              ),
              itemBuilder: (c, i) => _CallRow(item: shown[i]),
            ),
    );
  }
}

class _CallRow extends StatelessWidget {
  const _CallRow({required this.item});
  final CallLogItem item;

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
      onTap: () => startCall(context, item.roomId, name, video: c.video),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
        child: Row(
          children: [
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
