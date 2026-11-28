// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱 대화 가져오기 (Telegram tips 244 + 254; Eric 2026-11-27 "같이 해
// 줘", "텔레그램 대화는 가져와지지?"): how to export from KakaoTalk,
// WhatsApp or Telegram, picking the file, checking who is who, the
// progress ring with a happy ending, and how imported messages look in the
// chat ("가져옴" by the time, a day line between days, the import line).
import 'dart:async';
import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../brand/mark.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/chat_import.dart';
import '../core/chat_import_open.dart';
import '../core/chat_import_send.dart';
import '../core/phone.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'media_bubbles.dart' show VideoPlayerPage;
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;
import 'translate_ui.dart' show CapsuleButton;
import 'wide.dart';

/// The look-only web demo hands in a sample export so the steps can be
/// tried without a real KakaoTalk file (lib/demo/import_sample.dart).
class ImportDemo {
  static (String, Uint8List) Function()? sample;
}

String importAppName(L l, String app) => switch (app) {
  'kakao' => l.importAppKakao,
  'whatsapp' => l.importAppWhatsapp,
  _ => l.importAppTelegram,
};

Color importAppColor(BuildContext context, String app) => switch (app) {
  'kakao' => Palette.tileYellow,
  'whatsapp' => paletteOf(context).tileGreen,
  _ => Palette.tileBlue,
};

/// Opens the guide. With [roomId] the messages go into that chat; without
/// it the person picks a chat after the file.
Future<void> openChatImport(BuildContext context, {String? roomId, String? title}) => Navigator.of(context).push(
  IosPageRoute(
    builder: (_) => ImportGuidePage(roomId: roomId, title: title),
  ),
);

// ---------------------------------------------------------------- guide

class ImportGuidePage extends StatefulWidget {
  const ImportGuidePage({super.key, this.roomId, this.title});
  final String? roomId;
  final String? title;
  @override
  State<ImportGuidePage> createState() => _ImportGuidePageState();
}

class _ImportGuidePageState extends State<ImportGuidePage> {
  String app = 'kakao';
  String device = 'iphone';
  bool reading = false;

  List<String> steps(L l) {
    final s = switch ((app, device)) {
      ('kakao', 'pc') => l.importStepsKakaoPc,
      ('kakao', _) => l.importStepsKakaoPhone,
      ('whatsapp', 'android') => l.importStepsWhatsappAndroid,
      ('whatsapp', _) => l.importStepsWhatsappIphone,
      _ => l.importStepsTelegram,
    };
    return s.split('\n');
  }

  Future<void> pick() async {
    final l = L.of(context);
    final XFile? f;
    try {
      f = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'chat',
            extensions: ['zip', 'txt', 'json', 'html', 'csv'],
            mimeTypes: ['application/zip', 'text/plain', 'application/json', 'text/html', 'text/csv'],
            uniformTypeIdentifiers: ['public.zip-archive', 'public.plain-text', 'public.json', 'public.html', 'public.comma-separated-values-text'],
          ),
        ],
      );
    } catch (_) {
      if (mounted) showStoryToast(context, l.importPickFailed);
      return;
    }
    if (f == null || !mounted) return;
    await _read(() => openExport(f!));
  }

  Future<void> trySample() async {
    final s = ImportDemo.sample?.call();
    if (s == null) return;
    await _read(() => ChatImport.readInBackground(s.$1, s.$2));
  }

  Future<void> _read(Future<ImportBundle> Function() open) async {
    final l = L.of(context);
    setState(() => reading = true);
    ImportBundle? b;
    String? err;
    try {
      b = await open();
    } on ImportError catch (e) {
      err = e.code;
    } catch (_) {
      err = 'unknown';
    }
    if (!mounted) return;
    setState(() => reading = false);
    if (b == null) {
      showStoryToast(context, switch (err) {
        'big' => l.importErrBig,
        'empty' => l.importErrEmpty,
        'broken' => l.importErrBroken,
        _ => l.importErrUnknown,
      });
      return;
    }
    var chat = b.chats.first;
    if (b.chats.length > 1) {
      final picked = await openSheet<ParsedChat>(context, (_) => _PickExportChat(chats: b!.chats));
      if (picked == null || !mounted) return;
      chat = picked;
    }
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ImportCheckPage(chat: chat, files: b!.files, roomId: widget.roomId, title: widget.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final devices = app == 'telegram'
        ? const ['pc']
        : app == 'kakao'
        ? const ['iphone', 'android', 'pc']
        : const ['iphone', 'android'];
    final dev = devices.contains(device) ? device : devices.first;
    if (dev != device) device = dev;
    return SettingsScaffold(
      key: const Key('import-guide'),
      title: l.importTitle,
      children: [
        HeaderCard(color: Palette.tileTeal, icon: CupertinoIcons.tray_arrow_down_fill, title: l.importTitle, body: l.importHeader),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
          child: Row(
            children: [
              for (final a in const ['kakao', 'whatsapp', 'telegram']) ...[
                if (a != 'kakao') SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: _AppChoice(app: a, on: app == a, onTap: () => setState(() => app = a)),
                ),
              ],
            ],
          ),
        ),
        if (devices.length > 1)
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
            child: CupertinoSlidingSegmentedControl<String>(
              key: const Key('import-device'),
              groupValue: dev,
              children: {
                for (final d in devices)
                  d: Padding(
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                    child: Text(switch (d) {
                      'iphone' => l.importDeviceIphone,
                      'android' => l.importDeviceAndroid,
                      _ => l.importDevicePc,
                    }, key: Key('import-device-$d')),
                  ),
              },
              onValueChanged: (v) => setState(() => device = v ?? device),
            ),
          ),
        group(
          context,
          header: l.importHowTo(importAppName(l, app)),
          footer: app == 'telegram' ? l.importTelegramPhoneNote : (app == 'kakao' ? l.importKakaoMediaNote : l.importWhatsappMediaNote),
          [
            for (final (i, s) in steps(l).indexed)
              Padding(
                key: Key('import-step-$i'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      child: Text(
                        '${i + 1}',
                        style: Tokens.caption.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                      ),
                    ),
                    SizedBox(width: Tokens.space[2]),
                    Expanded(
                      child: Text(s, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  ],
                ),
              ),
          ],
        ),
        group(context, [
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CupertinoIcons.lock_shield_fill, color: p.accent, size: 22),
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Text(l.importPrivacy, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                ),
              ],
            ),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
          child: reading
              ? Column(
                  children: [
                    const CupertinoActivityIndicator(),
                    SizedBox(height: Tokens.space[1]),
                    Text(
                      l.importReading,
                      key: const Key('import-reading'),
                      style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                    ),
                  ],
                )
              : Column(
                  children: [
                    CapsuleButton(key: const Key('import-pick'), label: l.importPick, onTap: pick),
                    if (ImportDemo.sample != null) ...[
                      SizedBox(height: Tokens.space[2]),
                      CapsuleButton(key: const Key('import-sample'), label: l.importSample, filled: false, onTap: trySample),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _AppChoice extends StatelessWidget {
  const _AppChoice({required this.app, required this.on, required this.onTap});
  final String app;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GestureDetector(
      key: Key('import-app-$app'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: on ? p.accent.withValues(alpha: 0.12) : p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
        child: Column(
          children: [
            iconTile(importAppColor(context, app), CupertinoIcons.chat_bubble_2_fill),
            SizedBox(height: Tokens.space[1]),
            Text(
              importAppName(l, app),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.preview.style.copyWith(color: on ? p.accent : p.label, fontWeight: on ? Tokens.semi : FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

/// A whole-account Telegram export: which chat to bring in.
class _PickExportChat extends StatelessWidget {
  const _PickExportChat({required this.chats});
  final List<ParsedChat> chats;
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.importPickChat), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              children: [
                for (final (i, c) in chats.indexed)
                  IosTile(
                    key: Key('import-chat-$i'),
                    title: Text(c.title.isEmpty ? l.importNoTitle : c.title),
                    subtitle: Text(l.importCount(c.items.length)),
                    trailing: const IosChevron(),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- check

/// What was found, who is me, where it goes, with or without photos.
class ImportCheckPage extends StatefulWidget {
  const ImportCheckPage({super.key, required this.chat, required this.files, this.roomId, this.title});
  final ParsedChat chat;
  final ImportFiles files;
  final String? roomId;
  final String? title;
  @override
  State<ImportCheckPage> createState() => _ImportCheckPageState();
}

class _ImportCheckPageState extends State<ImportCheckPage> {
  String? me;
  bool media = true;
  String? roomId;
  String? roomTitle;

  @override
  void initState() {
    super.initState();
    roomId = widget.roomId;
    roomTitle = widget.title;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (me != null) return;
    final people = widget.chat.people;
    me = people.where((n) => importSelfWords.contains(n.toLowerCase())).firstOrNull;
    unawaited(
      AppScope.read(context).backend.myName().then((n) {
        if (!mounted || me != null) return;
        final hit = people.where((x) => x.trim() == n.trim()).firstOrNull;
        if (hit != null) setState(() => me = hit);
      }, onError: (_) {}),
    );
  }

  ChatPreview? get room => roomId == null ? null : AppScope.read(context).chats.where((c) => c.roomId == roomId).firstOrNull;

  /// In a 1:1 with two writers, the one who isn't me is the other person.
  String? get peerName {
    final r = room;
    final people = widget.chat.people;
    if (r == null || !r.isDirect || r.peer.isEmpty || me == null || people.length != 2) return null;
    return people.firstWhere((x) => x != me);
  }

  int get mediaBytes => [
    for (final x in widget.chat.items)
      if (x.media != null) widget.files.sizeOf(x.media!),
  ].fold(0, (a, b) => a + b);

  Future<void> pickRoom() async {
    final r = await openSheet<ChatPreview>(context, (_) => const _PickRoom());
    if (r != null && mounted) {
      setState(() {
        roomId = r.roomId;
        roomTitle = r.name;
      });
    }
  }

  Future<void> start() async {
    final l = L.of(context);
    if (roomId == null) {
      await pickRoom();
      if (roomId == null || !mounted) return;
    }
    final c = widget.chat;
    final again = await importedBefore(AppScope.read(context).backend, roomId!, c);
    if (!mounted) return;
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (s) => IosActionSheet(
        title: Text(l.importConfirmTitle(roomTitle ?? '', c.items.length)),
        message: Text(again ? l.importAlready : l.importConfirmInfo),
        actions: [CupertinoActionSheetAction(key: const Key('import-confirm'), onPressed: () => Navigator.pop(s, true), child: Text(l.importStart))],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(s, false), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    final peer = peerName;
    final choice = ImportChoice(chat: c, files: widget.files, me: me, peer: peer, peerId: peer == null ? null : room?.peer, media: media && c.mediaCount > 0);
    await Navigator.of(context).pushReplacement(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImportProgressPage(roomId: roomId!, roomTitle: roomTitle ?? '', choice: choice),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final c = widget.chat;
    final lang = Localizations.localeOf(context).toLanguageTag();
    final day = DateFormat.yMMMd(lang);
    final counts = c.counts;
    final people = c.people;
    final peer = peerName;
    return SettingsScaffold(
      key: const Key('import-check'),
      title: l.importCheckTitle,
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
          padding: EdgeInsets.all(Tokens.space[3]),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
          child: Row(
            children: [
              SizedBox(
                width: HeaderCard.tile,
                height: HeaderCard.tile,
                child: Container(
                  decoration: BoxDecoration(color: importAppColor(context, c.app.name), borderRadius: BorderRadius.circular(Tokens.radius[2])),
                  child: const Icon(CupertinoIcons.chat_bubble_2_fill, color: Color(0xFFFFFFFF), size: 32),
                ),
              ),
              SizedBox(width: Tokens.space[3]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(importAppName(l, c.app.name), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    Text(
                      c.title.isEmpty ? l.importNoTitle : c.title,
                      key: const Key('import-found-title'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.cardTitle.style.copyWith(color: p.label),
                    ),
                    SizedBox(height: Tokens.space[0]),
                    Text(
                      l.importCount(c.items.length),
                      key: const Key('import-found-count'),
                      style: Tokens.preview.style.copyWith(color: p.label),
                    ),
                    if (c.first != null)
                      Text('${day.format(c.first!)} – ${day.format(c.last!)}', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
              ),
            ],
          ),
        ),
        group(context, header: l.importWhoIsMe, footer: l.importWhoIsMeInfo, [
          for (final n in people.take(30))
            IosTile(
              key: Key('import-me-$n'),
              title: Text(n),
              additionalInfo: Text(l.importCount(counts[n] ?? 0)),
              trailing: me == n ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
              onTap: () => setState(() => me = me == n ? null : n),
            ),
        ]),
        if (peer != null)
          group(context, [
            Padding(
              padding: EdgeInsets.all(Tokens.space[3]),
              child: Text(
                l.importPeerInfo(peer, room?.name ?? ''),
                key: const Key('import-peer-info'),
                style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
              ),
            ),
          ]),
        group(context, header: l.importWhere, [
          NavRow(
            key: const Key('import-room'),
            color: Palette.tileBlue,
            icon: CupertinoIcons.chat_bubble_fill,
            title: roomTitle == null || roomId == null ? l.importPickRoom : roomTitle!,
            onTap: widget.roomId == null ? pickRoom : null,
          ),
        ]),
        if (c.mediaCount > 0 || c.missingCount > 0)
          group(context, footer: c.missingCount > 0 ? l.importMissingInfo(c.missingCount) : null, [
            if (c.mediaCount > 0)
              IosTile(
                key: const Key('import-media'),
                leading: iconTile(Palette.tileOrange, CupertinoIcons.photo_fill),
                title: Text(l.importMedia),
                subtitle: Text(l.importMediaSize(c.mediaCount, sizeLabel(mediaBytes))),
                trailing: CupertinoSwitch(value: media, onChanged: (v) => setState(() => media = v)),
              ),
            if (c.mediaCount == 0) IosTile(leading: iconTile(Palette.tileGrey, CupertinoIcons.photo), title: Text(l.importNoMedia)),
          ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
          child: CapsuleButton(key: const Key('import-go'), label: l.importStart, onTap: start),
        ),
      ],
    );
  }
}

String sizeLabel(int b) {
  if (b >= 1024 * 1024 * 1024) return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  if (b >= 1024 * 1024) return '${(b / (1024 * 1024)).toStringAsFixed(b >= 100 * 1024 * 1024 ? 0 : 1)} MB';
  if (b >= 1024) return '${(b / 1024).round()} KB';
  return '$b B';
}

/// The chats the messages can go into (ones I may write in).
class _PickRoom extends StatelessWidget {
  const _PickRoom();
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final chats = AppScope.of(context).chats.where((c) => !c.archived).toList();
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.importPickRoom), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: EdgeInsets.all(Tokens.space[3]),
              child: Text(l.importPickRoomInfo, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            ),
            IosSection(
              hasLeading: false,
              children: [
                for (final c in chats)
                  IosTile(
                    key: Key('import-room-${c.roomId}'),
                    title: Text(c.name),
                    subtitle: Text(c.isChannel ? l.importKindChannel : (c.isDirect ? l.importKindDirect : l.importKindGroup)),
                    trailing: const IosChevron(),
                    onTap: () => Navigator.pop(context, c),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- progress

/// The ring (34 % · 86 MB / 256 MB) with the brand mark breathing in the
/// middle, then a check and confetti.
class ImportProgressPage extends StatefulWidget {
  const ImportProgressPage({super.key, required this.roomId, required this.roomTitle, required this.choice});
  final String roomId;
  final String roomTitle;
  final ImportChoice choice;
  @override
  State<ImportProgressPage> createState() => _ImportProgressPageState();
}

class _ImportProgressPageState extends State<ImportProgressPage> with TickerProviderStateMixin {
  late final AnimationController breathe = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  late final AnimationController party = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  ImportProgress prog = const ImportProgress(done: 0, total: 1, step: 'media');
  ImportSender? sender;
  int? sentCount;
  bool failed = false;
  bool cancelled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (sender == null) unawaited(run());
  }

  Future<void> run() async {
    final s = AppScope.read(context);
    final me = s.backend.userId ?? '';
    setState(() {
      failed = false;
      sender = ImportSender(s.backend);
    });
    try {
      final n = await sender!.send(
        widget.roomId,
        widget.choice,
        myId: me,
        onProgress: (p) {
          if (mounted) setState(() => prog = p);
        },
      );
      if (!mounted) return;
      setState(() => sentCount = n);
      unawaited(HapticFeedback.mediumImpact());
      if (!s.calm) unawaited(party.forward(from: 0));
      unawaited(s.refresh());
    } on ImportCancelled {
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    sender?.cancel();
    breathe.dispose();
    party.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final done = sentCount != null;
    final pct = (prog.part * 100).floor();
    final stepText = failed
        ? l.importFailed
        : done
        ? l.importDone(sentCount!)
        : switch (prog.step) {
            'media' when prog.mediaTotal > 0 => l.importStepMedia(prog.media, prog.mediaTotal),
            'send' => l.importStepSend,
            _ => l.importStepPack,
          };
    return CupertinoPageScaffold(
      key: const Key('import-progress'),
      backgroundColor: p.background,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(Tokens.space[4]),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: CustomPaint(
                        painter: _Ring(part: done ? 1 : prog.part, track: p.label.withValues(alpha: 0.08), color: failed ? Palette.tileRed : p.accent),
                        child: Center(
                          child: done
                              ? TweenAnimationBuilder<double>(
                                  key: const Key('import-done-check'),
                                  tween: Tween(begin: 0.4, end: 1),
                                  duration: const Duration(milliseconds: 420),
                                  curve: Curves.easeOutBack,
                                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                                  child: Icon(CupertinoIcons.checkmark_alt, size: 88, color: p.accent),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ScaleTransition(
                                      scale: Tween(begin: 0.92, end: 1.06).animate(CurvedAnimation(parent: breathe, curve: Curves.easeInOut)),
                                      child: BurumyMark(size: 64, color: p.accent),
                                    ),
                                    SizedBox(height: Tokens.space[1]),
                                    Text(
                                      '$pct%',
                                      key: const Key('import-pct'),
                                      style: Tokens.screenTitle.style.copyWith(color: p.label),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: Tokens.space[4]),
                    Text(
                      stepText,
                      key: const Key('import-step'),
                      textAlign: TextAlign.center,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                    if (!done && !failed && prog.total > 1024 * 1024)
                      Padding(
                        padding: EdgeInsets.only(top: Tokens.space[0]),
                        child: Text('${sizeLabel(prog.done)} / ${sizeLabel(prog.total)}', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      ),
                    if (!done && !failed)
                      Padding(
                        padding: EdgeInsets.only(top: Tokens.space[2]),
                        child: Text(
                          l.importKeepOpen,
                          textAlign: TextAlign.center,
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                    SizedBox(height: Tokens.space[5]),
                    if (done)
                      CapsuleButton(
                        key: const Key('import-see'),
                        label: l.importSeeChat,
                        onTap: () {
                          // Back to the start, then the chat with its new old messages.
                          final nav = Navigator.of(context);
                          nav.popUntil((r) => r.isFirst);
                          unawaited(openChat(nav.context, widget.roomId, widget.roomTitle));
                        },
                      )
                    else if (failed) ...[
                      CapsuleButton(key: const Key('import-retry'), label: l.importRetry, onTap: run),
                      SizedBox(height: Tokens.space[2]),
                      CapsuleButton(label: l.close, filled: false, onTap: () => Navigator.pop(context)),
                    ] else
                      CapsuleButton(
                        key: const Key('import-cancel'),
                        label: l.importStop,
                        filled: false,
                        onTap: cancelled
                            ? null
                            : () {
                                setState(() => cancelled = true);
                                sender?.cancel();
                              },
                      ),
                  ],
                ),
              ),
            ),
            if (done)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _Confetti(party, colors: [p.accent, Palette.tileYellow, Palette.tileBlue, Palette.tilePink, Palette.tileOrange])),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring({required this.part, required this.track, required this.color});
  final double part;
  final Color track;
  final Color color;
  @override
  void paint(Canvas c, Size s) {
    const w = 12.0;
    final r = Rect.fromLTWH(w / 2, w / 2, s.width - w, s.height - w);
    c.drawArc(
      r,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = w,
    );
    if (part > 0) {
      c.drawArc(
        r,
        -math.pi / 2,
        math.pi * 2 * part,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Ring o) => o.part != part || o.color != color || o.track != track;
}

/// Little paper pieces falling from the top once (skipped when 효과 줄이기).
class _Confetti extends CustomPainter {
  _Confetti(this.t, {required this.colors}) : super(repaint: t);
  final Animation<double> t;
  final List<Color> colors;
  static final _bits = List.generate(70, (i) {
    final r = math.Random(i * 7919);
    return (r.nextDouble(), r.nextDouble() * 0.35, 0.6 + r.nextDouble() * 0.8, r.nextDouble() * math.pi * 2, r.nextDouble() * 6 - 3);
  });
  @override
  void paint(Canvas c, Size s) {
    final v = t.value;
    if (v <= 0 || v >= 1) return;
    for (final (i, b) in _bits.indexed) {
      final (x, delay, speed, angle, spin) = b;
      final k = ((v - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final y = -20 + k * speed * s.height * 1.1;
      final dx = math.sin(k * 6 + angle) * 18;
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: (1 - k).clamp(0.0, 1.0));
      c.save();
      c.translate(x * s.width + dx, y);
      c.rotate(angle + k * spin);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2.5, 8, 5), const Radius.circular(1.5)), paint);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => true;
}

// ---------------------------------------------------------------- in the chat

/// "카카오톡에서 가져온 대화 · 메시지 1,234개" in the middle of the chat.
class ImportCardLine extends StatelessWidget {
  const ImportCardLine({super.key, required this.msg, required this.who, this.onDelete});
  final Msg msg;

  /// Who brought it in ("" = me).
  final String who;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final d = msg.card!.data;
    final app = '${d['app']}';
    final n = d['count'] is int ? d['count'] as int : 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: Center(
        child: GestureDetector(
          key: Key('import-line-${msg.id}'),
          onTap: () => openSheet<void>(context, (_) => ImportInfoPage(msg: msg, who: who, onDelete: onDelete)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.tray_arrow_down_fill, size: Tokens.listIconSmall, color: importAppColor(context, app)),
                SizedBox(width: Tokens.space[1]),
                Flexible(
                  child: Text(
                    msg.mine ? l.importLineMine(importAppName(l, app), n) : l.importLine(who, importAppName(l, app), n),
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(color: p.label),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the import line opens: from where, how many, the dates, and for
/// the one who brought it in, taking it out again.
class ImportInfoPage extends StatelessWidget {
  const ImportInfoPage({super.key, required this.msg, required this.who, this.onDelete});
  final Msg msg;
  final String who;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final d = msg.card!.data;
    final app = '${d['app']}';
    final lang = Localizations.localeOf(context).toLanguageTag();
    final day = DateFormat.yMMMd(lang);
    int n(String k) => d[k] is int ? d[k] as int : 0;
    return CupertinoPageScaffold(
      key: const Key('import-info'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.importInfoTitle), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              children: [
                IosTile(
                  leading: iconTile(importAppColor(context, app), CupertinoIcons.chat_bubble_2_fill),
                  title: Text(importAppName(l, app)),
                  subtitle: Text('${d['title'] ?? ''}'),
                ),
                IosTile(
                  leading: iconTile(Palette.tileBlue, CupertinoIcons.text_bubble_fill),
                  title: Text(l.importInfoCount),
                  additionalInfo: Text(l.importCount(n('count'))),
                ),
                if (n('media') > 0)
                  IosTile(leading: iconTile(Palette.tileOrange, CupertinoIcons.photo_fill), title: Text(l.importMedia), additionalInfo: Text('${n('media')}')),
                if (n('from') > 0)
                  IosTile(
                    leading: iconTile(Palette.tileRed, CupertinoIcons.calendar),
                    title: Text(l.importInfoDates),
                    subtitle: Text(
                      '${day.format(DateTime.fromMillisecondsSinceEpoch(n('from')))} – ${day.format(DateTime.fromMillisecondsSinceEpoch(n('to')))}',
                    ),
                  ),
                IosTile(
                  leading: iconTile(Palette.tilePurple, CupertinoIcons.person_fill),
                  title: Text(l.importInfoBy),
                  additionalInfo: Text(msg.mine ? l.importInfoByMe : who),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[4], vertical: Tokens.space[2]),
              child: Text(l.importInfoNote, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
            ),
            if (msg.mine && onDelete != null)
              IosSection(
                children: [
                  IosTile(
                    key: const Key('import-delete'),
                    title: Text(l.importDelete, style: const TextStyle(color: Palette.tileRed)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete!();
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A day line above the first imported message of each day.
class ImportDayLine extends StatelessWidget {
  const ImportDayLine({super.key, required this.day});
  final DateTime day;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(DateFormat.yMMMEd(lang).format(day), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ),
    );
  }
}

/// Telegram notice codes ("sys:join|홍길동") and other apps' notice lines.
String importNotice(L l, String body) {
  if (!body.startsWith('sys:')) return body;
  final parts = body.substring(4).split('|');
  final who = parts.length > 1 ? parts[1] : '';
  return switch (parts.first) {
    'create' => l.importSysCreate(who),
    'join' => l.importSysJoin(who),
    'left' => l.importSysLeft(who),
    'pin' => l.importSysPin(who),
    'call' => l.importSysCall(who),
    'title' => l.importSysTitle(who, parts.length > 2 ? parts[2] : ''),
    'photo' => l.importSysPhoto(who),
    _ => l.importSysOther(who),
  };
}

/// An imported photo, video, voice message or file (downloaded and
/// decrypted on this phone when tapped), or one the export left out.
class ImportedMedia extends StatefulWidget {
  const ImportedMedia({super.key, required this.msg, this.senderName});
  final Msg msg;
  final String? senderName;
  @override
  State<ImportedMedia> createState() => _ImportedMediaState();
}

class _ImportedMediaState extends State<ImportedMedia> {
  Future<List<int>>? thumb;
  bool busy = false;

  ImportMark get mark => widget.msg.imported!;
  bool get visual => widget.msg.kind == 'image' || widget.msg.kind == 'video';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final f = mark.thumb ?? (widget.msg.kind == 'image' && mark.size < 4 * 1024 * 1024 ? mark.file : null);
    if (visual && f != null) thumb ??= AppScope.read(context).backend.downloadEncrypted(f);
  }

  Future<List<int>> full() => AppScope.read(context).backend.downloadEncrypted(mark.file!);

  Future<void> open() async {
    if (busy || mark.file == null) return;
    final m = widget.msg;
    final l = L.of(context);
    final nav = Navigator.of(context);
    if (m.kind == 'video') {
      await nav.push(IosPageRoute(builder: (_) => VideoPlayerPage(load: full)));
      return;
    }
    setState(() => busy = true);
    try {
      final bytes = Uint8List.fromList(await full());
      if (!mounted) return;
      if (m.kind == 'image') {
        await nav.push(IosPageRoute(builder: (_) => _Photo(bytes: bytes)));
      } else if (m.kind == 'audio') {
        await VoiceKit.player().play(bytes, m.id);
      } else {
        await Phone.share(
          bytes: bytes,
          name: mark.fileName.isNotEmpty ? mark.fileName : 'file',
          mime: mark.mime.isNotEmpty ? mark.mime : 'application/octet-stream',
        );
      }
    } catch (_) {
      if (mounted) showStoryToast(context, l.earlierFileFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final m = widget.msg;
    final fg = m.mine ? p.onAccent : p.label;
    final meta = Tokens.bubbleMeta.style.copyWith(color: p.secondaryLabel);
    final time = DateFormat.jm(Localizations.localeOf(context).languageCode).format(m.time);
    final Widget body;
    if (m.kind == 'missing' || mark.file == null) {
      final k = m.kind == 'missing' ? mark.missing : m.kind;
      final (icon, word) = switch (k) {
        'image' => (CupertinoIcons.photo, l.kindPhoto),
        'video' => (CupertinoIcons.videocam, l.kindVideo),
        'audio' => (CupertinoIcons.mic, l.kindVoice),
        'sticker' => (CupertinoIcons.smiley, l.importSticker),
        _ => (CupertinoIcons.doc, l.kindFile),
      };
      body = Container(
        key: Key('imported-missing-${m.id}'),
        constraints: const BoxConstraints(maxWidth: 260),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] + 2),
        decoration: BoxDecoration(color: m.mine ? p.accent.withValues(alpha: 0.55) : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg.withValues(alpha: 0.75)),
            SizedBox(width: Tokens.space[1]),
            Flexible(
              child: Text(
                (m.body ?? '').isNotEmpty && k != 'sticker'
                    ? '$word · ${m.body}'
                    : (k == 'sticker' && (m.body ?? '').isNotEmpty ? '${m.body} $word' : l.importNotIncluded(word)),
                style: Tokens.preview.style.copyWith(color: fg.withValues(alpha: 0.85)),
              ),
            ),
          ],
        ),
      );
    } else if (visual) {
      body = ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        child: SizedBox(
          width: 220,
          height: 220,
          child: FutureBuilder<List<int>>(
            future: thumb,
            builder: (context, snap) => Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: p.searchFill),
                if (snap.hasData) Image.memory(Uint8List.fromList(snap.data!), fit: BoxFit.cover, gaplessPlayback: true),
                if ((thumb != null && snap.connectionState != ConnectionState.done) || busy) const Center(child: CupertinoActivityIndicator()),
                if (thumb == null || snap.hasError)
                  Center(child: Icon(m.kind == 'video' ? CupertinoIcons.videocam : CupertinoIcons.photo, color: p.secondaryLabel, size: 36)),
                if (m.kind == 'video')
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x80000000)),
                      child: const Icon(CupertinoIcons.play_fill, color: Color(0xFFFFFFFF), size: 24),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      final voice = m.kind == 'audio';
      body = Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: m.mine ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: m.mine ? p.onAccent : p.accent),
              child: busy
                  ? CupertinoActivityIndicator(color: m.mine ? p.accent : p.onAccent)
                  : Icon(voice ? CupertinoIcons.play_fill : CupertinoIcons.doc_fill, color: m.mine ? p.accent : p.onAccent, size: 20),
            ),
            SizedBox(width: Tokens.space[2]),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voice ? l.earlierVoice : (mark.fileName.isNotEmpty ? mark.fileName : l.attachFile),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: fg),
                  ),
                  if (mark.size > 0) Text(sizeLabel(mark.size), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7))),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Align(
      alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
        child: Column(
          crossAxisAlignment: m.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (widget.senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(widget.senderName!, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ),
            GestureDetector(key: Key('imported-media-${m.id}'), onTap: open, child: body),
            if ((m.body ?? '').isNotEmpty && m.kind != 'missing')
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(m.body!, style: Tokens.body.style.copyWith(color: p.label)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
              child: Text('${l.importedMark} $time', key: const Key('imported-mark'), style: meta),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.bytes});
  final Uint8List bytes;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    key: const Key('imported-photo'),
    backgroundColor: const Color(0xFF000000),
    navigationBar: GlassTopBar.nav(leading: const GlassBack(), backgroundColor: const Color(0x00000000), border: null),
    child: InteractiveViewer(maxScale: 5, child: Center(child: Image.memory(bytes))),
  );
}

/// The same chat (same app, first and last message time and count) was
/// already brought into [roomId]: importing it again would show every
/// message twice, so the confirm sheet says so first.
Future<bool> importedBefore(Backend b, String roomId, ParsedChat c) async {
  if (c.items.isEmpty) return false;
  final n = c.items.length > importMaxItems ? importMaxItems : c.items.length;
  final last = c.items[n - 1].time.millisecondsSinceEpoch;
  try {
    final msgs = await b.timeline(roomId, limit: 500);
    return msgs.any((m) {
      final d = m.card?.kind == 'import' ? m.card!.data : null;
      return d != null && d['app'] == c.app.name && d['from'] == c.items.first.time.millisecondsSinceEpoch && d['to'] == last && d['count'] == n;
    });
  } catch (_) {
    return false;
  }
}
