// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 데이터 사용량 (Telegram tip 379): Settings > 데이터·저장 공간 > 데이터
// 사용량. 전체 / 모바일 데이터 / Wi-Fi, a ring by kind with the total in the
// middle, rows that open to 보냄 / 받음, the auto-download rules one tap
// away, and 통계 초기화 (5 seconds to take it back). Counted on this device
// only (core/data_usage.dart).
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../core/app_state.dart';
import '../core/data_usage.dart';
import '../core/storage_usage.dart' show sizeText;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'downloads_ui.dart' show AutoDlNetPage;
import 'ios.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'settings_kit.dart';
import 'storage_page.dart' show StorageRing;

Color usageColor(String kind) => switch (kind) {
  'photo' => Palette.tileBlue,
  'video' => Palette.tilePurple,
  'file' => Palette.tileOrange,
  'voice' => Palette.tilePink,
  'messages' => Palette.tileTeal,
  _ => Palette.tileYellow,
};

String usageName(L l, String kind) => switch (kind) {
  'photo' => l.photo,
  'video' => l.video,
  'file' => l.file,
  'voice' => l.voice,
  'messages' => l.usageMessages,
  _ => l.usageCalls,
};

IconData usageIcon(String kind) => switch (kind) {
  'photo' => CupertinoIcons.photo_fill,
  'video' => CupertinoIcons.videocam_fill,
  'file' => CupertinoIcons.doc_fill,
  'voice' => CupertinoIcons.mic_fill,
  'messages' => CupertinoIcons.chat_bubble_fill,
  _ => CupertinoIcons.phone_fill,
};

class DataUsagePage extends StatefulWidget {
  const DataUsagePage({super.key});

  @override
  State<DataUsagePage> createState() => _DataUsagePageState();
}

class _DataUsagePageState extends State<DataUsagePage> {
  /// 'all', 'cell' or 'wifi'.
  String net = 'all';

  /// Rows opened to show 보냄 / 받음.
  final open = <String>{};

  /// 통계 초기화 waiting out its 5 seconds: shows as zero.
  bool resetting = false;

  Map<String, UsageRow> rows(AppState s) {
    if (resetting) return {for (final k in usageKinds) k: UsageRow()};
    final all = DataUsage.read(s);
    final out = {for (final k in usageKinds) k: UsageRow()};
    for (final n in const ['wifi', 'cell']) {
      if (net != 'all' && net != n) continue;
      for (final e in (all[n] ?? const <String, UsageRow>{}).entries) {
        if (out.containsKey(e.key)) out[e.key] = out[e.key]! + e.value;
      }
    }
    return out;
  }

  void reset(AppState s) {
    final l = L.of(context);
    setState(() => resetting = true);
    showUndoCountdown(
      context,
      (n) => l.usageResetting(n),
      () async {
        await DataUsage.reset(s);
        if (mounted) setState(() => resetting = false);
      },
      onUndo: () {
        if (mounted) setState(() => resetting = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final by = rows(s);
    final total = by.values.fold<int>(0, (a, r) => a + r.total);
    final since = DataUsage.since(s);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    return SettingsScaffold(
      title: l.dataUsageTitle,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[3], Tokens.space[3] + Tokens.space[0], 0),
          child: IosSegmented<String>(
            key: const Key('usage-net'),
            groupValue: net,
            onValueChanged: (v) => setState(() => net = v ?? 'all'),
            children: {'all': Text(l.usageAll), 'cell': Text(l.usageCell), 'wifi': Text(l.usageWifi)},
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: Tokens.space[4]),
          child: Center(
            child: StorageRing(
              key: const Key('usage-ring'),
              values: [for (final k in usageKinds) (usageColor(k), by[k]!.total, true)],
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sizeText(total),
                    key: const Key('usage-total'),
                    style: Tokens.screenTitle.style.copyWith(color: p.label),
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Text(switch (net) {
                    'cell' => l.usageCell,
                    'wifi' => l.usageWifi,
                    _ => l.usageUsed,
                  }, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
          ),
        ),
        group(context, footer: l.usageInfo, [
          for (final k in usageKinds) ...[
            IosTile(
              key: Key('usage-$k'),
              leading: iconTile(usageColor(k), usageIcon(k)),
              title: Text(usageName(l, k)),
              additionalInfo: Text(k == 'calls' && by[k]!.total > 0 ? l.usageAbout(sizeText(by[k]!.total)) : sizeText(by[k]!.total)),
              trailing: Icon(open.contains(k) ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, size: 14, color: p.chevron),
              onTap: () => setState(() => open.contains(k) ? open.remove(k) : open.add(k)),
            ),
            if (open.contains(k)) ...[
              IosTile(
                key: Key('usage-$k-sent'),
                leading: const SizedBox(width: 30),
                title: Text(k == 'calls' ? l.usageSent : l.usageSentN(by[k]!.sentN), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                additionalInfo: Text(sizeText(by[k]!.sent)),
              ),
              IosTile(
                key: Key('usage-$k-recv'),
                leading: const SizedBox(width: 30),
                title: Text(k == 'calls' ? l.usageRecv : l.usageRecvN(by[k]!.recvN), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                additionalInfo: Text(sizeText(by[k]!.recv)),
              ),
            ],
          ],
        ]),
        // Telegram: the auto-download rules sit right here.
        group(context, header: l.autoDownload, [
          if (net != 'wifi')
            NavRow(
              key: const Key('usage-auto-cell'),
              color: p.tileGreen,
              icon: CupertinoIcons.antenna_radiowaves_left_right,
              title: l.autoDlCell,
              page: (_) => const AutoDlNetPage(net: 'cell'),
            ),
          if (net != 'cell')
            NavRow(
              key: const Key('usage-auto-wifi'),
              color: Palette.tileBlue,
              icon: CupertinoIcons.wifi,
              title: l.autoDlWifi,
              page: (_) => const AutoDlNetPage(net: 'wifi'),
            ),
        ]),
        group(context, footer: since == null ? null : l.usageSince(date.format(since)), [
          IosTile(
            key: const Key('usage-reset'),
            title: Text(l.usageReset, style: TextStyle(color: total == 0 ? p.secondaryLabel : Palette.tileRed)),
            onTap: total == 0 ? null : () => reset(s),
          ),
        ]),
      ],
    );
  }
}
