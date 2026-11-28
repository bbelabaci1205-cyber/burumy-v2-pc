// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 저장 공간 (Telegram tips 206 · 367 · 371 · 243, 2026-11-27): Settings >
// 데이터·저장 공간 > 저장 공간.
//
// - A ring split by kind (사진 / 동영상 / 파일 / 음성 메시지 / 기타 임시 파일)
//   with the total in the middle. Unticking a kind takes its piece out and
//   the button counts only what is ticked; 비우기 lets those copies go
//   (5 seconds to take it back), then a check and "… 비웠어요".
// - 받아 둔 파일 자동으로 지우기 per chat type, with 예외 for single chats.
// - 최대 저장 용량: over it, the oldest copies go first.
// - 큰 파일: the biggest copies by kind, pick and let go.
// - 대화별 저장 공간 (367): which chats take room (chat_storage_page.dart).
// Only this device's copies go: messages stay, a tap downloads again.
// The PC app (243) uses the same page and keeps its own limits.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/app_state.dart';
import '../core/downloads.dart';
import '../core/storage_usage.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'chat_storage_page.dart';
import 'common.dart';
import 'downloads_ui.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';

/// Ring colours by kind (iOS system colours, neighbours never the same).
Color storeKindColor(String kind) => switch (kind) {
  'photo' => Palette.tileBlue,
  'video' => Palette.tilePurple,
  'file' => Palette.tileOrange,
  'voice' => Palette.tilePink,
  _ => Palette.tileGrey,
};

String storeKindName(L l, String kind) => switch (kind) {
  'photo' => l.photo,
  'video' => l.video,
  'file' => l.file,
  'voice' => l.voice,
  _ => l.storageOther,
};

/// "1 GB", "5 GB", …, "제한 없음".
String cacheMaxName(L l, int mb) => mb == 0 ? l.storageNoLimit : sizeText(mb * 1024 * 1024).replaceAll('.0 ', ' ');

/// The ring: pieces in [values] order (bytes); unpicked pieces shrink away.
/// Draws itself in from the top the first time (Telegram's spin-in).
class StorageRing extends StatefulWidget {
  const StorageRing({super.key, required this.values, required this.center, this.size = 200, this.stroke = 22});

  /// (colour, bytes, picked)
  final List<(Color, int, bool)> values;
  final Widget center;
  final double size;
  final double stroke;

  @override
  State<StorageRing> createState() => _StorageRingState();
}

class _StorageRingState extends State<StorageRing> with TickerProviderStateMixin {
  late final intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final move = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  List<double> from = const [], to = const [];

  List<double> targets() {
    final shown = [for (final (_, b, on) in widget.values) on ? b.toDouble() : 0.0];
    final sum = shown.fold<double>(0, (a, b) => a + b);
    return [for (final v in shown) sum == 0 ? 0 : v / sum];
  }

  @override
  void initState() {
    super.initState();
    from = to = targets();
  }

  @override
  void didUpdateWidget(StorageRing old) {
    super.didUpdateWidget(old);
    final next = targets();
    if (next.length != to.length || [for (var i = 0; i < next.length; i++) (next[i] - to[i]).abs() > 1e-6].any((x) => x)) {
      from = now;
      to = next;
      move.forward(from: 0);
    }
  }

  List<double> get now {
    final t = Curves.easeOutCubic.transform(move.value);
    return [for (var i = 0; i < to.length; i++) (i < from.length ? from[i] : 0) * (1 - t) + to[i] * t];
  }

  @override
  void dispose() {
    intro.dispose();
    move.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([intro, move]),
        builder: (_, _) => CustomPaint(
          painter: _RingPainter(
            parts: [for (var i = 0; i < widget.values.length; i++) (widget.values[i].$1, now[i])],
            reveal: Curves.easeOutCubic.transform(intro.value),
            stroke: widget.stroke,
            track: p.dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
          ),
          child: Center(child: widget.center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.parts, required this.reveal, required this.stroke, required this.track});
  final List<(Color, double)> parts;
  final double reveal;
  final double stroke;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final shown = parts.where((x) => x.$2 > 0.002).length;
    // A small gap between pieces (in radians), none with one piece.
    final gap = shown > 1 ? 0.035 : 0.0;
    var at = -math.pi / 2;
    final total = math.pi * 2 * reveal;
    for (final (c, f) in parts) {
      final sweep = f * total;
      if (sweep > gap) canvas.drawArc(rect, at + gap / 2, sweep - gap, false, paint..color = c);
      at += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}

/// The round tick in front of a kind (filled with the kind's colour).
class KindTick extends StatelessWidget {
  const KindTick({super.key, required this.color, required this.on});
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? color : const Color(0x00000000),
        border: on ? null : Border.all(color: p.chevron, width: 1.5),
      ),
      child: on ? const Icon(CupertinoIcons.checkmark_alt, size: 16, color: Color(0xFFFFFFFF)) : null,
    );
  }
}

class StorageUsagePage extends StatefulWidget {
  const StorageUsagePage({super.key});

  @override
  State<StorageUsagePage> createState() => _StorageUsagePageState();
}

class _StorageUsagePageState extends State<StorageUsagePage> {
  /// Phones / PC: the app's own folders (web: the browser decides).
  StorageUsage? usage;
  bool read = false;

  /// Kinds left out of 비우기 (all ticked to start, like Telegram).
  final unpicked = <String>{};

  /// Kinds (or copies) waiting out the 5 seconds.
  final going = <String>{};
  final goingFiles = <String>{};

  /// 큰 파일 tab and the copies picked there.
  String bigTab = 'media';
  final bigPicked = <String>{};

  /// The green check in the ring right after 비우기.
  bool freed = false;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final u = await StorageUsage.read();
    if (mounted) {
      setState(() {
        usage = u;
        read = true;
      });
    }
  }

  /// Bytes per kind, "other" = the rest of the temporary folder.
  Map<String, int> sizes(AppState s) {
    final by = Downloads.instance.keptByKind(s);
    final out = {
      for (final k in storeKinds)
        if (!going.contains(k)) k: by[k]!.$1,
    };
    final u = usage;
    // Kept copies live in the encrypted store; the temporary folder holds
    // the rest (previews, files being opened).
    if (u != null && !going.contains('other')) out['other'] = u.cache;
    return out;
  }

  void clear(AppState s, Map<String, int> by) {
    final l = L.of(context);
    final kinds = {
      for (final e in by.entries)
        if (e.value > 0 && !unpicked.contains(e.key)) e.key,
    };
    final bytes = kinds.fold<int>(0, (a, k) => a + by[k]!);
    if (kinds.isEmpty) return;
    setState(() => going.addAll(kinds));
    showUndoCountdown(
      context,
      (n) => l.storageClearing(sizeText(bytes), n),
      () async {
        await Downloads.instance.forgetKinds(s, kinds.where((k) => k != 'other').toSet());
        if (kinds.contains('other')) await StorageUsage.clearCache();
        await load();
        if (!mounted) return;
        setState(() {
          going.removeAll(kinds);
          freed = true;
        });
        showInfoBanner(context, l.storageFreed(sizeText(bytes)), l.storageFreedInfo, icon: CupertinoIcons.checkmark_circle_fill);
        Timer(const Duration(milliseconds: 1600), () {
          if (mounted) setState(() => freed = false);
        });
      },
      onUndo: () {
        if (mounted) setState(() => going.removeAll(kinds));
      },
    );
  }

  void letGoBig(AppState s, Set<String> ids) {
    final l = L.of(context);
    setState(() {
      goingFiles.addAll(ids);
      bigPicked.clear();
    });
    showUndoCountdown(
      context,
      (n) => l.storageGoing(ids.length, n),
      () async {
        await Downloads.instance.forget(s, ids);
        if (mounted) setState(() => goingFiles.removeAll(ids));
      },
      onUndo: () {
        if (mounted) setState(() => goingFiles.removeAll(ids));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return ListenableBuilder(
      listenable: Downloads.instance,
      builder: (context, _) {
        final s = AppScope.of(context);
        final by = sizes(s);
        final total = by.values.fold<int>(0, (a, b) => a + b);
        final kinds = [...storeKinds, if (by.containsKey('other')) 'other'];
        final picked = kinds.where((k) => (by[k] ?? 0) > 0 && !unpicked.contains(k)).fold<int>(0, (a, k) => a + by[k]!);
        final empty = total == 0;
        return SettingsScaffold(
          title: l.storageTitle,
          children: [
            // The ring and the kinds.
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[4]),
              child: Center(
                child: StorageRing(
                  key: const Key('storage-ring'),
                  values: [for (final k in kinds) (storeKindColor(k), by[k] ?? 0, !unpicked.contains(k))],
                  center: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: freed
                        ? Icon(CupertinoIcons.checkmark_circle_fill, key: const Key('storage-freed'), size: 64, color: p.tileGreen)
                        : Column(
                            key: ValueKey(picked),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                sizeText(empty ? 0 : picked),
                                key: const Key('storage-total'),
                                style: Tokens.screenTitle.style.copyWith(color: p.label),
                              ),
                              SizedBox(height: Tokens.nameToSub),
                              Text(
                                empty ? l.storageNothing : (picked == total ? l.storageOnDevice : l.storageOfTotal(sizeText(total))),
                                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            group(context, footer: kIsWeb ? '${l.storageKeepsChats} ${l.storageWeb}' : l.storageKeepsChats, [
              for (final k in kinds)
                IosTile(
                  key: Key('store-kind-$k'),
                  leading: KindTick(color: storeKindColor(k), on: !unpicked.contains(k) && (by[k] ?? 0) > 0),
                  title: Text(storeKindName(l, k)),
                  subtitle: (by[k] ?? 0) > 0 && total > 0 ? Text(l.storagePercent(((by[k]! * 100) / total).clamp(1, 100).round())) : null,
                  additionalInfo: Text(sizeText(by[k] ?? 0)),
                  onTap: (by[k] ?? 0) == 0 ? null : () => setState(() => unpicked.contains(k) ? unpicked.remove(k) : unpicked.add(k)),
                ),
            ]),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0]),
              child: picked > 0
                  ? AccentButton(key: const Key('storage-clear'), text: l.storageClearButton(sizeText(picked)), onTap: () => clear(s, by))
                  : Container(
                      key: const Key('storage-clear-off'),
                      height: Tokens.settingsRow,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
                      child: Text(empty ? l.storageNothing : l.storagePickKind, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                    ),
            ),
            // 자동 삭제: per chat type, and single chats as exceptions.
            keepGroup(context),
            group(context, [
              NavRow(
                key: const Key('keep-exceptions'),
                color: Palette.tileIndigo,
                icon: CupertinoIcons.slider_horizontal_3,
                title: l.keepExceptions,
                value: '${s.keepExceptions.length}',
                page: (_) => const KeepExceptionsPage(),
              ),
            ]),
            // 최대 저장 용량.
            group(context, header: l.storageMaxTitle, footer: l.storageMaxInfo, [const CacheMaxSlider()]),
            // 대화별 저장 공간 (367).
            group(context, header: l.storageByChat, footer: l.storageByChatInfo, [
              ...chatStorageRows(context).take(5),
              NavRow(key: const Key('storage-by-chat'), title: l.storageAllChats, page: (_) => const AllChatStoragePage()),
            ]),
            // 큰 파일: biggest copies by kind.
            ...bigFiles(context, s),
          ],
        );
      },
    );
  }

  List<Widget> bigFiles(BuildContext context, AppState s) {
    final l = L.of(context);
    final p = paletteOf(context);
    bool takes(KeptFile f) => switch (bigTab) {
      'media' => f.kind == 'photo' || f.kind == 'video',
      'voice' => f.kind == 'voice',
      _ => f.kind != 'photo' && f.kind != 'video' && f.kind != 'voice',
    };
    final files = [
      for (final f in Downloads.instance.keptFiles(s))
        if (takes(f) && !goingFiles.contains(f.eventId)) f,
    ].take(20).toList();
    final chats = {for (final c in s.chats) c.roomId: c.name};
    return [
      Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[4], Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionHeader(context, l.storageBig),
            SizedBox(height: Tokens.groupTitleToCard),
            IosSegmented<String>(
              key: const Key('big-tabs'),
              groupValue: bigTab,
              onValueChanged: (v) => setState(() {
                bigTab = v ?? 'media';
                bigPicked.clear();
              }),
              children: {'media': Text(l.storageTabMedia), 'file': Text(l.file), 'voice': Text(l.voice)},
            ),
          ],
        ),
      ),
      group(context, [
        if (files.isEmpty)
          IosTile(
            key: const Key('big-none'),
            title: Text(l.storageChatEmpty, style: TextStyle(color: p.secondaryLabel)),
          ),
        for (final f in files)
          IosTile(
            key: Key('big-${f.eventId}'),
            leading: iconTile(storeKindColor(f.kind), switch (f.kind) {
              'photo' => CupertinoIcons.photo_fill,
              'video' => CupertinoIcons.videocam_fill,
              'voice' => CupertinoIcons.mic_fill,
              _ => CupertinoIcons.doc_fill,
            }),
            title: Text(f.name.isEmpty ? storeKindName(l, f.kind) : f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text([if (f.size > 0) sizeText(f.size), chats[f.roomId] ?? l.storageGoneChat].join(' · '), maxLines: 1),
            trailing: Icon(
              bigPicked.contains(f.eventId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: bigPicked.contains(f.eventId) ? p.accent : p.secondaryLabel,
            ),
            onTap: () => setState(() => bigPicked.contains(f.eventId) ? bigPicked.remove(f.eventId) : bigPicked.add(f.eventId)),
          ),
        if (bigPicked.isNotEmpty)
          IosTile(
            key: const Key('big-clear'),
            title: Text(l.storageClearPicked(bigPicked.length), style: const TextStyle(color: Palette.tileRed)),
            onTap: () => letGoBig(s, {...bigPicked}),
          ),
      ]),
    ];
  }
}

/// 최대 저장 용량: 1 GB … 50 GB, 제한 없음.
class CacheMaxSlider extends StatelessWidget {
  const CacheMaxSlider({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final now = s.cacheMaxMb;
    var i = cacheMaxSteps.indexOf(now);
    if (i < 0) i = cacheMaxSteps.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2]),
      child: Column(
        children: [
          Text(
            cacheMaxName(l, now),
            key: const Key('cache-max-value'),
            style: Tokens.body.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              key: const Key('cache-max-slider'),
              value: i.toDouble(),
              min: 0,
              max: (cacheMaxSteps.length - 1).toDouble(),
              divisions: cacheMaxSteps.length - 1,
              activeColor: p.accent,
              onChanged: (v) => s.setCacheMaxMb(cacheMaxSteps[v.round()]),
            ),
          ),
          // Each name sits under its stop (the thumb runs 14 pt in from
          // each end); the end names keep inside the card.
          LayoutBuilder(
            builder: (context, box) {
              const inset = 14.0, each = 64.0;
              final step = (box.maxWidth - inset * 2) / (cacheMaxSteps.length - 1);
              return SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    for (final (n, mb) in cacheMaxSteps.indexed)
                      Positioned(
                        left: (inset + step * n - each / 2).clamp(0, box.maxWidth - each),
                        width: each,
                        top: 0,
                        child: Text(
                          cacheMaxName(l, mb),
                          maxLines: 1,
                          textAlign: n == 0 ? TextAlign.left : (n == cacheMaxSteps.length - 1 ? TextAlign.right : TextAlign.center),
                          style: Tokens.caption.style.copyWith(color: n == i ? p.label : p.secondaryLabel),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 예외: single chats that keep their copies longer or shorter.
class KeepExceptionsPage extends StatelessWidget {
  const KeepExceptionsPage({super.key});

  Future<void> pickDays(BuildContext context, AppState s, String roomId, String name) async {
    final l = L.of(context);
    await Navigator.of(context).push(
      IosPageRoute<void>(
        builder: (_) => ChoicePage(
          title: name,
          header: l.keepTitle,
          footer: l.keepExceptionInfo,
          options: [for (final d in keepSteps) ('$d', keepName(l, d))],
          value: () => '${s.keepDaysOf(roomId) ?? ''}',
          onPick: (v) => s.setKeepDaysOf(roomId, int.parse(v)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final names = {for (final c in s.chats) c.roomId: c};
    return SettingsScaffold(
      title: l.keepExceptions,
      children: [
        group(context, footer: l.keepExceptionInfo, [
          IosTile(
            key: const Key('keep-exception-add'),
            leading: Icon(CupertinoIcons.add, color: p.accent, size: Tokens.listIcon),
            title: Text(l.addException, style: TextStyle(color: p.accent)),
            onTap: () async {
              final room = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const _AnyChatPickPage()));
              if (room == null || !context.mounted) return;
              // Starts as "안 지워요", then the time can be picked.
              await s.setKeepDaysOf(room, 0);
              if (context.mounted) await pickDays(context, s, room, names[room]?.name ?? '');
            },
          ),
          for (final r in s.keepExceptions)
            IosTile(
              key: Key('keep-exception-$r'),
              leading: Avatar(name: names[r]?.name ?? '?', size: 30, squircle: !(names[r]?.isDirect ?? true), roomId: r),
              title: Text(names[r]?.name ?? l.storageGoneChat, maxLines: 1, overflow: TextOverflow.ellipsis),
              additionalInfo: Text(keepName(l, s.keepDaysOf(r) ?? 0)),
              trailing: GestureDetector(
                key: Key('keep-exception-drop-$r'),
                onTap: () => s.setKeepDaysOf(r, null),
                child: Icon(CupertinoIcons.minus_circle, color: p.secondaryLabel, size: 22),
              ),
              onTap: () => pickDays(context, s, r, names[r]?.name ?? ''),
            ),
        ]),
      ],
    );
  }
}

/// Any chat of mine (for an exception).
class _AnyChatPickPage extends StatelessWidget {
  const _AnyChatPickPage();

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final have = s.keepExceptions.toSet();
    return SettingsScaffold(
      title: l.addException,
      children: [
        group(context, [
          for (final c in s.chats)
            if (!have.contains(c.roomId))
              IosTile(
                key: Key('pick-chat-${c.roomId}'),
                leading: Avatar(name: c.name, size: 30, squircle: !c.isDirect, roomId: c.roomId),
                title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.of(context).pop(c.roomId),
              ),
        ]),
      ],
    );
  }
}
