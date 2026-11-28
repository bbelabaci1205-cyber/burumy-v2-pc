// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 4-app board (WhatsApp "저장 공간 관리"): which chats take room on this
// phone, and letting their downloaded copies go, one file or a whole chat.
// Only copies go: the messages stay and a tap downloads them again.
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/downloads.dart';
import '../core/storage_usage.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';
import 'storage_page.dart' show KindTick, StorageRing, storeKindColor, storeKindName;

/// One row per chat with kept copies, biggest first.
List<Widget> chatStorageRows(BuildContext context) {
  final s = AppScope.of(context);
  final l = L.of(context);
  final by = Downloads.instance.keptByChat(s);
  if (by.isEmpty) return const [];
  final names = {for (final c in s.chats) c.roomId: c};
  return [
    for (final (room, count, bytes) in by)
      IosTile(
        key: Key('storage-chat-$room'),
        leading: Avatar(name: names[room]?.name ?? '?', size: 30, squircle: !(names[room]?.isDirect ?? true)),
        title: Text(names[room]?.name ?? l.storageGoneChat, maxLines: 1, overflow: TextOverflow.ellipsis),
        additionalInfo: Text(bytes > 0 ? sizeText(bytes) : l.storageFiles(count)),
        trailing: const IosChevron(),
        onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => ChatStoragePage(roomId: room))),
      ),
  ];
}

/// Every chat with kept copies.
class AllChatStoragePage extends StatelessWidget {
  const AllChatStoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ListenableBuilder(
      listenable: Downloads.instance,
      builder: (context, _) => SettingsScaffold(
        title: l.storageByChat,
        children: [
          if (chatStorageRows(context) case final rows when rows.isNotEmpty)
            group(context, footer: l.storageByChatInfo, rows)
          else
            group(context, footer: l.storageByChatInfo, [IosTile(key: const Key('storage-none'), title: Text(l.storageChatEmpty))]),
        ],
      ),
    );
  }
}

/// One chat's kept copies, biggest first. Tap to pick; let the picked or
/// all of them go (5 seconds to take it back).
class ChatStoragePage extends StatefulWidget {
  const ChatStoragePage({super.key, required this.roomId});
  final String roomId;

  @override
  State<ChatStoragePage> createState() => _ChatStoragePageState();
}

class _ChatStoragePageState extends State<ChatStoragePage> {
  final picked = <String>{};

  /// Kinds left out of "선택한 것 비우기" (tip 367: all ticked to start).
  final unpicked = <String>{};

  /// Waiting out the 5 seconds: hidden here, still on the phone.
  final going = <String>{};

  void letGo(Set<String> ids) {
    final l = L.of(context);
    final s = AppScope.read(context);
    setState(() {
      going.addAll(ids);
      picked.clear();
    });
    showUndoCountdown(
      context,
      (n) => l.storageGoing(ids.length, n),
      () async {
        await Downloads.instance.forget(s, ids);
        if (mounted) setState(() => going.removeAll(ids));
      },
      onUndo: () {
        if (mounted) setState(() => going.removeAll(ids));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final chat = s.chats.where((c) => c.roomId == widget.roomId).firstOrNull;
    final files = [
      for (final f in Downloads.instance.keptFiles(s, roomId: widget.roomId))
        if (!going.contains(f.eventId)) f,
    ];
    final total = files.fold<int>(0, (a, f) => a + f.size);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag());
    // Tip 367: this chat's ring by kind, ticks, and one button.
    final by = {for (final k in storeKinds) k: 0};
    for (final f in files) {
      final k = storeKinds.contains(f.kind) ? f.kind : 'file';
      by[k] = by[k]! + f.size;
    }
    final kinds = [
      for (final k in storeKinds)
        if (by[k]! > 0) k,
    ];
    final tickedIds = {
      for (final f in files)
        if (!unpicked.contains(storeKinds.contains(f.kind) ? f.kind : 'file')) f.eventId,
    };
    final ticked = kinds.where((k) => !unpicked.contains(k)).fold<int>(0, (a, k) => a + by[k]!);
    return SettingsScaffold(
      title: chat?.name ?? l.storageGoneChat,
      children: [
        if (total > 0) ...[
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[4]),
            child: Center(
              child: StorageRing(
                key: const Key('storage-chat-ring'),
                size: 160,
                stroke: 18,
                values: [for (final k in kinds) (storeKindColor(k), by[k]!, !unpicked.contains(k))],
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(sizeText(ticked), style: Tokens.cardTitle.style.copyWith(color: p.label)),
                    Text(l.storageThisChat, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
              ),
            ),
          ),
          group(context, footer: l.storageChatInfo, [
            for (final k in kinds)
              IosTile(
                key: Key('chat-kind-$k'),
                leading: KindTick(color: storeKindColor(k), on: !unpicked.contains(k)),
                title: Text(storeKindName(l, k)),
                additionalInfo: Text(sizeText(by[k]!)),
                onTap: () => setState(() => unpicked.contains(k) ? unpicked.remove(k) : unpicked.add(k)),
              ),
          ]),
          if (ticked > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0]),
              child: AccentButton(key: const Key('storage-chat-kinds-clear'), text: l.storageClearButton(sizeText(ticked)), onTap: () => letGo(tickedIds)),
            ),
        ] else
          group(context, footer: l.storageChatInfo, [
            IosTile(
              key: const Key('storage-chat-total'),
              title: Text(l.storageChatTotal),
              additionalInfo: Text(total > 0 ? sizeText(total) : l.storageFiles(files.length)),
            ),
            if (files.isNotEmpty)
              IosTile(
                key: const Key('storage-chat-clear-all'),
                title: Text(l.storageClearChat, style: const TextStyle(color: Palette.tileRed)),
                onTap: () => letGo({for (final f in files) f.eventId}),
              ),
          ]),
        if (files.isEmpty)
          group(context, [
            IosTile(
              title: Text(l.storageChatEmpty, style: TextStyle(color: p.secondaryLabel)),
            ),
          ])
        else
          group(context, header: l.storageChatFiles, [
            if (picked.isNotEmpty)
              IosTile(
                key: const Key('storage-chat-clear'),
                title: Text(l.storageClearPicked(picked.length), style: const TextStyle(color: Palette.tileRed)),
                onTap: () => letGo({...picked}),
              ),
            for (final f in files)
              IosTile(
                key: Key('kept-${f.eventId}'),
                leading: Icon(
                  switch (f.kind) {
                    'photo' => CupertinoIcons.photo,
                    'video' => CupertinoIcons.videocam,
                    'voice' => CupertinoIcons.mic,
                    _ => CupertinoIcons.doc,
                  },
                  size: Tokens.listIcon,
                  color: p.secondaryLabel,
                ),
                title: Text(f.name.isEmpty ? l.storageNoName : f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text([if (f.size > 0) sizeText(f.size), date.format(f.at)].join(' · ')),
                trailing: Icon(
                  picked.contains(f.eventId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  color: picked.contains(f.eventId) ? p.accent : p.secondaryLabel,
                ),
                onTap: () => setState(() => picked.contains(f.eventId) ? picked.remove(f.eventId) : picked.add(f.eventId)),
              ),
          ]),
      ],
    );
  }
}
