// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > Data and storage, batch "영상 보기·내려받기" (2026-11-27):
// per-network auto-download pages (tip 116), keep times per chat type
// (tip 101) and the download list (tip 109). iOS Settings look: grouped
// rows, switches, checkmark pages.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/downloads.dart';
import '../core/storage_usage.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'media_bubbles.dart';
import 'settings_kit.dart';

String kindName(L l, String kind) => switch (kind) {
  'photo' => l.photo,
  'video' => l.video,
  _ => l.file,
};

String chatTypeName(L l, String t) => switch (t) {
  'dm' => l.dlChatDm,
  'group' => l.group,
  _ => l.channel,
};

/// "사진, 동영상 10MB까지" (or "꺼짐").
String autoSummary(AppState s, L l, String net) {
  final parts = <String>[
    for (final k in autoKinds)
      if (s.autoChats(net, k).isNotEmpty) k == 'photo' ? kindName(l, k) : '${kindName(l, k)} ${l.dlUpToMb(s.autoMaxMb(net, k))}',
  ];
  return parts.isEmpty ? l.dlOff : parts.join(', ');
}

String keepName(L l, int days) => switch (days) {
  1 => l.keepDay,
  7 => l.keepWeek,
  30 => l.keepMonth,
  _ => l.keepNever,
};

/// The rows that go into the Data page's auto-download group.
List<Widget> autoDownloadRows(BuildContext context) {
  final l = L.of(context);
  final s = AppScope.of(context);
  final p = paletteOf(context);
  return [
    NavRow(
      key: const Key('auto-dl-cell'),
      color: p.tileGreen,
      icon: CupertinoIcons.antenna_radiowaves_left_right,
      title: l.autoDlCell,
      subtitle: s.on('auto_dl_cell', fallback: true) ? autoSummary(s, l, 'cell') : l.dlOff,
      page: (_) => const AutoDlNetPage(net: 'cell'),
    ),
    NavRow(
      key: const Key('auto-dl-wifi'),
      color: Palette.tileBlue,
      icon: CupertinoIcons.wifi,
      title: l.autoDlWifi,
      subtitle: s.on('auto_dl_wifi', fallback: true) ? autoSummary(s, l, 'wifi') : l.dlOff,
      page: (_) => const AutoDlNetPage(net: 'wifi'),
    ),
  ];
}

/// Mobile data / Wi-Fi: master switch, then photo / video / file.
class AutoDlNetPage extends StatelessWidget {
  const AutoDlNetPage({super.key, required this.net});
  final String net;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final on = s.on(net == 'cell' ? 'auto_dl_cell' : 'auto_dl_wifi', fallback: true);
    return SettingsScaffold(
      title: net == 'cell' ? l.autoDlCell : l.autoDlWifi,
      children: [
        group(context, footer: l.autoDownloadInfo, [PrefSwitch(net == 'cell' ? 'auto_dl_cell' : 'auto_dl_wifi', title: l.dlAutoSwitch, fallback: true)]),
        if (on)
          group(context, header: l.dlKinds, [
            for (final k in autoKinds)
              NavRow(
                key: Key('auto-dl-$net-$k'),
                title: kindName(l, k),
                value: s.autoChats(net, k).isEmpty
                    ? l.dlOff
                    : k == 'photo'
                    ? l.dlChatsCount(s.autoChats(net, k).length)
                    : l.dlUpToMb(s.autoMaxMb(net, k)),
                page: (_) => AutoDlKindPage(net: net, kind: k),
              ),
          ]),
      ],
    );
  }
}

/// One kind on one network: which chats, and the size limit.
class AutoDlKindPage extends StatelessWidget {
  const AutoDlKindPage({super.key, required this.net, required this.kind});
  final String net;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final chats = s.autoChats(net, kind);
    final mb = s.autoMaxMb(net, kind);
    final step = autoSizeSteps.indexWhere((x) => x >= mb);
    return SettingsScaffold(
      title: kindName(l, kind),
      children: [
        group(context, header: l.dlWhere, [
          for (final t in chatTypes)
            IosTile(
              title: Text(chatTypeName(l, t)),
              trailing: IosSwitch(
                key: Key('auto-dl-chat-$t'),
                value: chats.contains(t),
                activeTrackColor: p.accent,
                onChanged: (v) => s.setAutoChats(net, kind, {...chats.where((x) => x != t), if (v) t}),
              ),
            ),
        ]),
        if (kind != 'photo' && chats.isNotEmpty)
          group(context, header: l.dlMaxSize, footer: l.dlMaxInfo, [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[1]),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('1 MB', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      const Spacer(),
                      Text(
                        l.dlUpToMb(mb),
                        key: const Key('auto-dl-max'),
                        style: Tokens.body.style.copyWith(color: p.accent),
                      ),
                      const Spacer(),
                      Text('2 GB', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  CupertinoSlider(
                    key: const Key('auto-dl-slider'),
                    value: (step < 0 ? autoSizeSteps.length - 1 : step).toDouble(),
                    max: (autoSizeSteps.length - 1).toDouble(),
                    divisions: autoSizeSteps.length - 1,
                    activeColor: p.accent,
                    onChanged: (x) => s.setAutoMaxMb(net, kind, autoSizeSteps[x.round()]),
                  ),
                ],
              ),
            ),
          ]),
      ],
    );
  }
}

/// 352: 갤러리 자동 저장 rows on the Data page (one per chat type).
Widget autoSaveGroup(BuildContext context) {
  final l = L.of(context);
  final s = AppScope.of(context);
  final p = paletteOf(context);
  final icons = {'dm': (p.tileGreen, CupertinoIcons.person_fill), 'group': (Palette.tileBlue, CupertinoIcons.person_2_fill), 'channel': (Palette.tileOrange, CupertinoIcons.speaker_2_fill)};
  String value(String t) {
    final kinds = [if (s.autoSave(t, 'photo')) l.photo, if (s.autoSave(t, 'video')) l.video];
    return kinds.isEmpty ? l.dlOff : kinds.join(', ');
  }

  return KeyedSubtree(
    key: const Key('auto-save'),
    child: group(context, header: l.autoSaveTitle, footer: l.autoSaveInfo, [
      for (final t in chatTypes)
        NavRow(
          key: Key('auto-save-$t'),
          color: icons[t]!.$1,
          icon: icons[t]!.$2,
          title: chatTypeName(l, t),
          value: value(t),
          page: (_) => AutoSavePage(chatType: t),
        ),
    ]),
  );
}

/// One chat type: 사진 / 영상 switches and the biggest video to save.
class AutoSavePage extends StatelessWidget {
  const AutoSavePage({super.key, required this.chatType});
  final String chatType;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final mb = s.autoSaveMaxMb;
    final step = autoSizeSteps.indexWhere((x) => x >= mb);
    return SettingsScaffold(
      title: chatTypeName(l, chatType),
      children: [
        group(context, header: l.autoSaveTitle, footer: l.autoSaveInfo, [
          for (final k in const ['photo', 'video'])
            IosTile(
              title: Text(kindName(l, k)),
              trailing: IosSwitch(
                key: Key('auto-save-$chatType-$k'),
                value: s.autoSave(chatType, k),
                activeTrackColor: p.accent,
                onChanged: (v) => s.setAutoSave(chatType, k, v),
              ),
            ),
        ]),
        if (s.autoSave(chatType, 'video'))
          group(context, header: l.dlMaxSize, [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[1]),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('1 MB', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      const Spacer(),
                      Text(l.dlUpToMb(mb), key: const Key('auto-save-max'), style: Tokens.body.style.copyWith(color: p.accent)),
                      const Spacer(),
                      Text('2 GB', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                  CupertinoSlider(
                    key: const Key('auto-save-slider'),
                    value: (step < 0 ? autoSizeSteps.length - 1 : step).toDouble(),
                    max: (autoSizeSteps.length - 1).toDouble(),
                    divisions: autoSizeSteps.length - 1,
                    activeColor: p.accent,
                    onChanged: (x) => s.setAutoSaveMaxMb(autoSizeSteps[x.round()]),
                  ),
                ],
              ),
            ),
          ]),
      ],
    );
  }
}

/// 101: the group of keep-time rows on the Data page.
Widget keepGroup(BuildContext context) {
  final l = L.of(context);
  final s = AppScope.of(context);
  final p = paletteOf(context);
  final icons = {
    'dm': (p.tileGreen, CupertinoIcons.person_fill),
    'group': (Palette.tileBlue, CupertinoIcons.person_2_fill),
    'channel': (Palette.tileOrange, CupertinoIcons.speaker_2_fill),
  };
  return KeyedSubtree(
    key: const Key('keep-media'),
    child: group(context, header: l.keepTitle, footer: l.keepInfo, [
      for (final t in chatTypes)
        NavRow(
          key: Key('keep-$t'),
          color: icons[t]!.$1,
          icon: icons[t]!.$2,
          title: chatTypeName(l, t),
          value: keepName(l, s.keepDays(t)),
          page: (_) => ChoicePage(
            title: chatTypeName(l, t),
            header: l.keepTitle,
            footer: l.keepInfo,
            options: [for (final d in keepSteps) ('$d', keepName(l, d))],
            value: () => '${s.keepDays(t)}',
            onPick: (v) => s.setKeepDays(t, int.parse(v)),
          ),
        ),
    ]),
  );
}

/// 109: everything downloaded lately, running ones on top with an X.
class DownloadListPage extends StatelessWidget {
  const DownloadListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    return ListenableBuilder(
      listenable: Downloads.instance,
      builder: (context, _) {
        final d = Downloads.instance;
        final running = d.items.where((x) => isActive(x.state)).toList();
        final done = d.items.where((x) => !isActive(x.state)).toList();
        Widget row(DownloadItem it) {
          final icon = switch (it.kind) {
            'photo' => CupertinoIcons.photo_fill,
            'video' => CupertinoIcons.videocam_fill,
            _ => CupertinoIcons.doc_fill,
          };
          final status = switch (it.state) {
            DownloadState.running => l.dlRunning,
            DownloadState.waiting => l.dlWaiting,
            DownloadState.paused => l.dlPaused,
            DownloadState.cancelled => l.dlCancelled,
            DownloadState.failed => l.dlFailed,
            DownloadState.done => it.chat,
          };
          final size = it.size == null ? '' : sizeText(it.size!);
          final tile = IosTile(
            key: Key('dl-row-${it.eventId}'),
            leading: iconTile(it.kind == 'video' ? Palette.tileBlue : (it.kind == 'photo' ? p.tileGreen : Palette.tileGrey), icon),
            title: Text(it.name.isEmpty ? kindName(l, it.kind) : it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text([status, size].where((x) => x.isNotEmpty).join(' · '), maxLines: 1),
            // Tip 322: 멈추기 / 이어 받기, then X (그만 받기).
            trailing: isActive(it.state)
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        key: Key('dl-pause-${it.eventId}'),
                        onTap: () => it.state == DownloadState.paused ? d.resume(s, it.eventId) : d.pause(s, it.eventId),
                        child: Padding(
                          padding: EdgeInsets.all(Tokens.space[0]),
                          child: Icon(
                            it.state == DownloadState.paused ? CupertinoIcons.play_circle_fill : CupertinoIcons.pause_circle_fill,
                            size: 28,
                            color: p.accent,
                          ),
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      GestureDetector(
                        key: Key('dl-cancel-${it.eventId}'),
                        onTap: () => d.cancel(s, it.eventId),
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (it.state == DownloadState.running) const CupertinoActivityIndicator(radius: 14),
                              Icon(it.state == DownloadState.running ? CupertinoIcons.xmark : CupertinoIcons.xmark_circle_fill, size: it.state == DownloadState.running ? 12 : 24, color: it.state == DownloadState.running ? p.label : p.chevron),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
            onTap: it.state == DownloadState.done && it.kind == 'video'
                ? () => Navigator.of(context, rootNavigator: true).push(
                    IosPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => VideoPlayerPage(
                        mime: it.name.toLowerCase().endsWith('.mov')
                            ? 'video/quicktime'
                            : (it.name.toLowerCase().endsWith('.webm') ? 'video/webm' : 'video/mp4'),
                        load: () => s.backend.downloadFileCached(it.roomId, it.eventId),
                      ),
                    ),
                  )
                : null,
          );
          if (!isActive(it.state)) return tile;
          // Hold: 먼저 받기 / 멈추기 / 그만 받기 (Telegram "우선순위 올리기").
          return GestureDetector(key: Key('dl-hold-${it.eventId}'), onLongPress: () => downloadMenu(context, it), child: tile);
        }

        return SettingsScaffold(
          title: l.dlList,
          children: [
            if (d.items.isEmpty)
              group(context, [
                IosTile(
                  key: const Key('dl-empty'),
                  title: Text(l.dlListEmpty, style: TextStyle(color: p.secondaryLabel)),
                ),
              ]),
            if (running.isNotEmpty) group(context, header: l.dlRunning, [for (final it in running) row(it)]),
            if (done.isNotEmpty)
              group(context, header: l.dlRecent, footer: l.dlListInfo, [
                for (final it in done) row(it),
                IosTile(
                  key: const Key('dl-clear'),
                  title: Text(l.dlClear, style: const TextStyle(color: Palette.tileRed)),
                  onTap: () => d.clearList(s),
                ),
              ]),
          ],
        );
      },
    );
  }
}

/// The hold menu of a download in the list (tip 322).
Future<void> downloadMenu(BuildContext context, DownloadItem it) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final d = Downloads.instance;
  final pick = await showCupertinoModalPopup<String>(
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(it.name.isEmpty ? kindName(l, it.kind) : it.name),
      actions: [
        if (it.state != DownloadState.running) CupertinoActionSheetAction(key: const Key('dl-first'), onPressed: () => Navigator.pop(c, 'first'), child: Text(l.dlFirst)),
        if (it.state == DownloadState.paused)
          CupertinoActionSheetAction(key: const Key('dl-resume'), onPressed: () => Navigator.pop(c, 'resume'), child: Text(l.dlResume))
        else
          CupertinoActionSheetAction(key: const Key('dl-pause'), onPressed: () => Navigator.pop(c, 'pause'), child: Text(l.dlPause)),
        CupertinoActionSheetAction(key: const Key('dl-stop'), isDestructiveAction: true, onPressed: () => Navigator.pop(c, 'stop'), child: Text(l.dlStop)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  switch (pick) {
    case 'first':
      await d.first(s, it.eventId);
    case 'resume':
      d.resume(s, it.eventId);
    case 'pause':
      await d.pause(s, it.eventId);
    case 'stop':
      await d.cancel(s, it.eventId);
  }
}

/// The ⬇ button on the chat list while files are coming (tip 322): a ring
/// around an arrow; tap = the download list.
class DownloadsButton extends StatelessWidget {
  const DownloadsButton({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Downloads.instance,
    builder: (context, _) {
      final n = Downloads.instance.activeCount;
      if (n == 0) return const SizedBox.shrink();
      final p = paletteOf(context);
      // A still icon (no spinner on the list: it would run all the time).
      return Padding(
        padding: EdgeInsets.only(right: Tokens.space[1]),
        child: GlassCircle(
          key: const Key('downloads-button'),
          onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const DownloadListPage())),
          child: Icon(CupertinoIcons.arrow_down_circle, size: 24, color: p.accent),
        ),
      );
    },
  );
}

/// Size under a video or file ("12.3 MB"), or nothing when unknown.
String? sizeOf(Msg m) => m.size == null || m.size! <= 0 ? null : sizeText(m.size!);
