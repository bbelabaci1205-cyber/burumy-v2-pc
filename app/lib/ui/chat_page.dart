// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// One chat: bubbles + composer (iOS "+" on the left, brand send circle).
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/link_check.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'stories.dart' show showStoryToast;
import 'links.dart';
import 'wallpaper.dart';
import 'ios.dart';
import 'formatting.dart';
import 'glass.dart';
import 'message_menu.dart';
import 'message_sheets.dart';
import '../core/reminders.dart';
import '../core/saved_tags.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/screen_guard.dart';
import '../brand/mark.dart';
import 'attach_sheet.dart';
import 'bubbles.dart';
import 'cards.dart';
import 'checklist.dart';
import 'location.dart';
import 'meetup.dart';
import 'call_page.dart';
import 'poll.dart';
import 'profile_page.dart';
import 'room_tools.dart';
import 'saved_page.dart';
import 'sticker_panel.dart';
import 'verify_page.dart';
import '../stickers/catalog.dart';
import 'ios_route.dart';
import 'wide.dart';

/// Opens a chat over the whole screen (tab bar hidden, like Telegram).
Future<void> openChat(BuildContext context, String roomId, String title) async {
  final s = AppScope.read(context);
  if (s.on('marked_unread:$roomId')) unawaited(s.setOn('marked_unread:$roomId', false));
  if (Wide.on) {
    // Two panes: the chat shows on the right, in place of the last one.
    s.openRoom = roomId;
    await Wide.show(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: roomId, title: title),
      ),
      roomId: roomId,
    );
    if (Wide.selected.value == null && s.openRoom == roomId) s.openRoom = null;
    return;
  }
  final before = s.openRoom;
  s.openRoom = roomId;
  try {
    await paneNav(context).push(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: roomId, title: title),
      ),
    );
  } finally {
    s.openRoom = before;
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.roomId, required this.title});
  final String roomId;
  final String title;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Msg> msgs = const [];
  DateTime? readUntil;
  final input = TextEditingController();
  AppState? state;
  bool get veiled => state != null && veilOf(state!, widget.roomId).isNotEmpty;

  /// Composer modes: answering one message, or fixing my own.
  Msg? replying;
  Msg? editing;
  bool canPost = true;
  bool isGroup = false;
  bool isChannel = false;

  /// Channel posts show who wrote them (admin switch "서명 남기기").
  bool signed = false;
  List<String> typers = const [];
  bool stickersOpen = false;
  int timerSecs = 0;
  Timer? tick;
  List<String> pins = const [];

  /// Search inside this chat (done on the phone).
  bool searching = false;
  final searchInput = TextEditingController();
  List<Msg> hits = const [];
  int hitAt = 0;
  bool searched = false;
  String? focusId;
  int limit = 50;
  final listKey = GlobalKey();
  final scroll = ScrollController();
  final msgKeys = <String, GlobalKey>{};
  String? notice;
  Timer? noticeTimer;

  static const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  /// Group/channel settings from the admin tools, and my role there.
  Map<String, dynamic> cfg = const {};
  String role = 'member';
  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get hideCounts => hideCountsFor(cfg, role);

  /// Reactions the room allows (admins' choice), for the menu.
  List<String> get menuReactions => (allowedReactions(cfg) ?? quickReactions).take(6).toList();

  /// Shown reactions: only allowed ones, at most the room's maximum.
  List<Reaction> shownReactions(Msg m) {
    final ok = allowedReactions(cfg);
    final list = ok == null ? m.reactions : m.reactions.where((r) => ok.contains(r.key)).toList();
    return list.take(reactionsMax(cfg)).toList();
  }

  /// New members must agree to the rules before writing (when asked).
  bool get mustAgree => cfg['rules_agree'] == true && (cfg['rules'] as String? ?? '').trim().isNotEmpty && !isAdmin && !state!.on('agreed:${widget.roomId}');

  /// A delete waits 5 seconds so it can be undone.
  /// Messages waiting out the 5 s undo before they are deleted.
  List<String>? pendingDelete;
  int undoLeft = 0;
  Timer? undoTimer;

  /// Settings > Privacy > Undo send: the text waits here for 5 seconds.
  (String, Msg?)? pendingSend;
  int sendLeft = 0;
  Timer? sendTimer;
  Timer? typingIdle;
  DateTime typingSent = DateTime(2000);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s != state) {
      state?.removeListener(load);
      state = s..addListener(load);
      load();
      // Messages with a timer disappear on time even without news.
      tick ??= Timer.periodic(const Duration(seconds: 30), (_) => load());
    }
  }

  @override
  void dispose() {
    state?.removeListener(load);
    undoTimer?.cancel();
    typingIdle?.cancel();
    tick?.cancel();
    noticeTimer?.cancel();
    recTick?.cancel();
    recLevelSub?.cancel();
    final r = recorder;
    if (r != null) unawaited(r.cancel());
    searchInput.dispose();
    scroll.dispose();
    for (final d in pendingDelete ?? const <String>[]) {
      unawaited(state!.backend.deleteMessage(widget.roomId, d).catchError((_) {}));
    }
    sendTimer?.cancel();
    final ps = pendingSend;
    if (ps != null) unawaited(_deliver(state!.backend, ps.$1, ps.$2).catchError((_) {}));
    super.dispose();
  }

  /// Messages marked for the delete password; this chat is on the hide list.
  Set<String> marked = {};
  bool roomHidden = false;

  Future<void> load() async {
    final b = state!.backend;
    final m = await b.timeline(widget.roomId, limit: limit);
    final r = await b.readUntil(widget.roomId);
    final post = await b.canPost(widget.roomId);
    final channel = await b.isChannel(widget.roomId);
    final sign = channel && await b.roomSwitch(widget.roomId, 'sign').catchError((_) => false);
    final secs = await b.timer(widget.roomId);
    final row = state!.chats.where((c) => c.roomId == widget.roomId);
    final room = row.isNotEmpty && !row.first.isDirect;
    final c = room ? await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{}) : const <String, dynamic>{};
    final r0 = room ? await b.myRole(widget.roomId).catchError((_) => 'member') : 'member';
    final mk = kIsWeb ? const <String>[] : await b.markedMessages(widget.roomId).catchError((_) => const <String>[]);
    final ql = kIsWeb ? const <List<String>>[[], []] : await b.quietLists().catchError((_) => const <List<String>>[[], []]);
    if (mounted) {
      setState(() {
        final cut = clearedAt(state!, widget.roomId);
        final all = cut == null ? m : m.where((x) => x.time.isAfter(cut)).toList();
        // Thread replies live on the thread page, not in the chat.
        threads = {};
        for (final x in all) {
          if (x.threadRoot != null) threads.putIfAbsent(x.threadRoot!, () => []).add(x);
        }
        msgs = all.where((x) => x.threadRoot == null).toList();
        readUntil = r;
        canPost = post;
        isChannel = channel;
        signed = sign;
        isGroup = row.isNotEmpty && !row.first.isDirect;
        typers = b.typingUsers(widget.roomId);
        pins = b.pinned(widget.roomId);
        timerSecs = secs;
        cfg = c;
        role = r0;
        marked = mk.toSet();
        roomHidden = ql.first.contains(widget.roomId);
      });
    }
    if (m.isNotEmpty && !m.last.mine) unawaited(b.markRead(widget.roomId).catchError((_) {}));
  }

  static String mimeOf(String name) => ChatPageMime.of(name);

  /// Opens a view-once photo full screen; after closing it is gone.
  Future<void> openOnce(Msg m) async {
    final b = state!.backend;
    final bytes = await b.openViewOnce(widget.roomId, m.id);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(IosPageRoute(fullscreenDialog: true, builder: (_) => ViewOncePage(bytes: Uint8List.fromList(bytes))));
    await load();
  }

  Future<void> attach() async {
    FocusScope.of(context).unfocus();
    final r = await showAttachSheet(
      context,
      caption: input.text,
      isGroup: isGroup,
      isChannel: isChannel,
      sentFiles: [
        for (final m in msgs.reversed)
          if (m.mine && m.kind == 'file' && !m.viewOnce) m,
      ],
    );
    if (r == null || !mounted) return;
    final tool = r.tool;
    if (tool == null) {
      if (r.files.isEmpty) return;
      if (!r.once && r.caption.trim().isNotEmpty) input.clear();
      final b = state!.backend;
      for (var i = 0; i < r.files.length; i++) {
        final f = r.files[i];
        if (r.once) {
          await b.sendViewOnce(widget.roomId, name: f.name, mime: mimeOf(f.name), bytes: f.bytes);
        } else {
          // The words go under the last one, so they sit right above the composer.
          await b.sendFile(
            widget.roomId,
            name: f.name,
            mime: f.asFile ? 'application/octet-stream' : mimeOf(f.name),
            bytes: f.bytes,
            caption: i == r.files.length - 1 ? r.caption : '',
          );
        }
      }
      await load();
      unawaited(state!.refresh());
      return;
    }
    if (tool.startsWith('resend:')) {
      // "최근에 보낸 파일": the same file again, as a new message.
      final id = tool.substring(7);
      final m = msgs.where((x) => x.id == id).firstOrNull;
      if (m == null) return;
      final b = state!.backend;
      final bytes = await b.downloadFile(widget.roomId, id);
      await b.sendFile(widget.roomId, name: m.body ?? 'file', mime: 'application/octet-stream', bytes: Uint8List.fromList(bytes));
      await load();
      return;
    }
    final Widget? page = switch (tool) {
      'bubble' => SendBubblePage(roomId: widget.roomId, name: widget.title),
      'poll' => CreatePollPage(roomId: widget.roomId, isChannel: isChannel),
      'checklist' => CreateChecklistPage(roomId: widget.roomId, isGroup: isGroup || isChannel),
      'meetup' => CreateMeetupPage(roomId: widget.roomId),
      'contact' => PickContactPage(roomId: widget.roomId),
      'location' => SendLocationPage(roomId: widget.roomId),
      _ when cardKinds.contains(tool) => cardEditor(widget.roomId, tool),
      _ => null,
    };
    if (tool == 'templates') {
      final t = await openSheet<String>(context, (_) => const TemplatesPage());
      if (t != null && mounted) {
        input.text = t;
        input.selection = TextSelection.collapsed(offset: t.length);
        setState(() {});
      }
      return;
    }
    if (page == null) return;
    final made = await openSheet<bool>(context, (_) => page);
    if (made == true) {
      await load();
      unawaited(state!.refresh());
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    final b = state!.backend;
    final (rep, ed) = (replying, editing);
    input.clear();
    setState(() => replying = editing = null);
    typingIdle?.cancel();
    unawaited(b.setTyping(widget.roomId, false).catchError((_) {}));
    if (ed != null) {
      if (text != ed.body) await b.edit(widget.roomId, ed.id, text);
    } else if (state!.on('undo_send')) {
      if (pendingSend != null) await flushSend();
      setState(() {
        pendingSend = (text, rep);
        sendLeft = 5;
      });
      sendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        if (sendLeft <= 1) {
          unawaited(flushSend());
        } else {
          setState(() => sendLeft--);
        }
      });
      return;
    } else {
      await _deliver(b, text, rep);
    }
    await load();
    unawaited(state!.refresh());
  }

  Future<void> _deliver(Backend b, String text, Msg? rep) =>
      rep != null ? b.reply(widget.roomId, rep.id, text) : (channelSilent ? b.sendTextQuietly(widget.roomId, text) : b.sendText(widget.roomId, text));

  /// Channel owner's bell (v1): posts go out without sound for subscribers.
  bool get channelSilent => isChannel && state!.on('channel_silent:${widget.roomId}');

  Future<void> toggleChannelBell() async {
    final l = L.of(context);
    final now = !channelSilent;
    await state!.setOn('channel_silent:${widget.roomId}', now);
    if (mounted) showNotice(now ? l.channelSilentOn : l.channelLoudOn);
  }

  /// The 5 seconds are up (or another message follows): really send.
  Future<void> flushSend() async {
    sendTimer?.cancel();
    final ps = pendingSend;
    if (ps == null) return;
    setState(() => pendingSend = null);
    await _deliver(state!.backend, ps.$1, ps.$2);
    await load();
    unawaited(state!.refresh());
  }

  /// Take the waiting message back into the field.
  void cancelSend() {
    sendTimer?.cancel();
    final ps = pendingSend;
    if (ps == null) return;
    setState(() {
      pendingSend = null;
      replying = ps.$2;
    });
    input.text = ps.$1;
  }

  Widget sendUndoBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Container(
      key: const Key('send-undo-bar'),
      margin: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sendingIn(sendLeft), style: Tokens.caption.style.copyWith(color: p.accent)),
                Text(
                  pendingSend?.$1 ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: p.label),
                ),
              ],
            ),
          ),
          CupertinoButton(
            key: const Key('send-undo'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: cancelSend,
            child: Text(l.cancel, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
  }

  /// Hold the send button: send quietly, or set a time.
  Future<void> sendOptions() async {
    final l = L.of(context);
    final text = input.text.trim();
    if (text.isEmpty) return;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          CupertinoActionSheetAction(key: const Key('send-quiet'), onPressed: () => Navigator.pop(c, 'quiet'), child: Text(l.sendQuietly)),
          CupertinoActionSheetAction(key: const Key('send-later'), onPressed: () => Navigator.pop(c, 'later'), child: Text(l.sendLater)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    if (pick == 'quiet') {
      input.clear();
      await state!.backend.sendTextQuietly(widget.roomId, text);
      await load();
      unawaited(state!.refresh());
      return;
    }
    var at = DateTime.now().add(const Duration(hours: 1));
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => Container(
        height: 330,
        color: paletteOf(c).card,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                  CupertinoButton(key: const Key('schedule-ok'), onPressed: () => Navigator.pop(c, true), child: Text(l.scheduleSend)),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  key: const Key('schedule-picker'),
                  initialDateTime: at,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  use24hFormat: false,
                  onDateTimeChanged: (v) => at = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    input.clear();
    await state!.schedule(widget.roomId, text, at);
    if (mounted) showNotice(l.scheduledDone);
    setState(() {});
  }

  (String, DateTime, Offset)? lastUp;

  void doubleTapCheck(Msg m, PointerUpEvent e) {
    if (!state!.on('double_tap_react', fallback: true)) return;
    final now = DateTime.now();
    final prev = lastUp;
    lastUp = (m.id, now, e.position);
    if (prev != null && prev.$1 == m.id && now.difference(prev.$2) < const Duration(milliseconds: 300) && (prev.$3 - e.position).distance < 30) {
      lastUp = null;
      toggleReaction(m, state!.pref('quick_reaction', '❤️'));
    }
  }

  /// Tells the others I'm typing (at most every 4 seconds), and stops
  /// after 5 quiet seconds.
  void onTyped(String _) {
    final b = state!.backend;
    if (!state!.on('send_typing', fallback: true)) return;
    final now = DateTime.now();
    if (now.difference(typingSent) > const Duration(seconds: 4)) {
      typingSent = now;
      unawaited(b.setTyping(widget.roomId, true).catchError((_) {}));
    }
    typingIdle?.cancel();
    typingIdle = Timer(const Duration(seconds: 5), () {
      typingSent = DateTime(2000);
      unawaited(b.setTyping(widget.roomId, false).catchError((_) {}));
    });
  }

  Future<void> commitDelete() async {
    undoTimer?.cancel();
    final ids = pendingDelete;
    if (ids == null) return;
    for (final id in ids) {
      await state!.backend.deleteMessage(widget.roomId, id).catchError((_) {});
    }
    if (mounted) setState(() => pendingDelete = null);
    await load();
    unawaited(state!.refresh());
  }

  void startDelete(List<String> ids) {
    if (pendingDelete != null) unawaited(commitDelete());
    setState(() {
      pendingDelete = ids;
      undoLeft = 5;
    });
    undoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (undoLeft <= 1) {
        t.cancel();
        unawaited(commitDelete());
      } else {
        setState(() => undoLeft--);
      }
    });
  }

  void undoDelete() {
    undoTimer?.cancel();
    setState(() => pendingDelete = null);
  }

  Future<void> chooseTimer() async {
    final l = L.of(context);
    const options = [0, 86400, 604800, 2592000];
    final pick = await showCupertinoModalPopup<int>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.timer),
        message: Text(l.timerInfo),
        actions: [
          for (final o in options)
            CupertinoActionSheetAction(
              key: Key('timer-$o'),
              isDefaultAction: o == timerSecs,
              onPressed: () => Navigator.pop(c, o),
              child: Text(o == 0 ? l.timerOff : timerLabel(context, o)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || pick == timerSecs) return;
    await state!.backend.setTimer(widget.roomId, pick);
    await load();
  }

  VoiceRecorder? recorder;
  DateTime? recStart;
  bool recCancel = false;

  /// Finger's slide to the left while holding (the bar follows it, v1).
  double recDx = 0;

  /// Recent loudness, newest last (the locked bar's live wave).
  final recLevels = <double>[];

  /// Slid up: recording goes on after letting go (trash / pause / send).
  bool recLocked = false;
  bool recPaused = false;
  Duration recPausedFor = Duration.zero;
  DateTime? recPausedAt;
  Timer? recTick;
  double recLevel = 0;
  StreamSubscription<double>? recLevelSub;

  Future<void> startRecording() async {
    final r = VoiceKit.recorder();
    final ok = await r.start().catchError((_) => false);
    if (!mounted) return;
    if (!ok) {
      showNotice(L.of(context).voiceNoMic);
      return;
    }
    HapticFeedback.lightImpact();
    recorder = r;
    recLevels.clear();
    recLevelSub = r.level.listen((v) {
      if (!recPaused) {
        recLevels.add(v);
        if (recLevels.length > 60) recLevels.removeAt(0);
      }
      setState(() => recLevel = v);
    });
    recTick = Timer.periodic(const Duration(milliseconds: 200), (_) => setState(() {}));
    setState(() {
      recStart = DateTime.now();
      recCancel = false;
      recDx = 0;
      recLocked = false;
      recPaused = false;
      recPausedFor = Duration.zero;
      recPausedAt = null;
      stickersOpen = false;
    });
  }

  Future<void> finishRecording() async {
    final r = recorder;
    if (r == null) return;
    recTick?.cancel();
    unawaited(recLevelSub?.cancel());
    final cancel = recCancel;
    setState(() {
      recorder = null;
      recStart = null;
      recCancel = false;
      recLevel = 0;
      recDx = 0;
      recLocked = false;
      recPaused = false;
    });
    if (cancel) {
      await r.cancel();
      return;
    }
    final got = await r.stop();
    // Too short to be a message (a tap that turned into a hold).
    if (got == null || got.duration < const Duration(milliseconds: 700)) {
      if (mounted) showNotice(L.of(context).voiceHoldHint);
      return;
    }
    await state!.backend.sendVoice(widget.roomId, got.mime, got.bytes, got.duration, got.waveform);
    await load();
    unawaited(state!.refresh());
  }

  Duration get recTook {
    final now = DateTime.now();
    final paused = recPausedFor + (recPausedAt == null ? Duration.zero : now.difference(recPausedAt!));
    return now.difference(recStart ?? now) - paused;
  }

  Future<void> toggleRecPause() async {
    final r = recorder;
    if (r == null) return;
    if (recPaused) {
      await r.resume();
      setState(() {
        recPausedFor += DateTime.now().difference(recPausedAt ?? DateTime.now());
        recPausedAt = null;
        recPaused = false;
      });
    } else {
      await r.pause();
      setState(() {
        recPausedAt = DateTime.now();
        recPaused = true;
      });
    }
  }

  Future<void> cancelRecording() async {
    setState(() => recCancel = true);
    await finishRecording();
  }

  /// Locked recording (v1 layout): round glass trash, a glass capsule with
  /// the red dot, time, live level and pause, and the round send button.
  /// All 40 tall like the composer.
  Widget lockedRecordingBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      key: const Key('recording-locked'),
      padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], Tokens.space[1]),
      child: Row(
        children: [
          GlassCircle(
            key: const Key('rec-trash'),
            size: Tokens.closeButton,
            onTap: cancelRecording,
            child: Icon(CupertinoIcons.trash, color: Palette.tileRed, size: Tokens.listIcon),
          ),
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: LiquidGlass(
              radius: Tokens.capsule,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(width: Tokens.space[2]),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: recPaused ? p.secondaryLabel : Palette.tileRed, shape: BoxShape.circle),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Text(
                      voiceTime(recTook),
                      style: Tokens.body.style.copyWith(color: p.label, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    SizedBox(width: Tokens.space[2]),
                    Expanded(
                      child: _LevelDots(levels: recLevels, color: p.secondaryLabel),
                    ),
                    CupertinoButton(
                      key: const Key('rec-pause'),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                      minimumSize: const Size(40, 40),
                      onPressed: toggleRecPause,
                      child: Icon(
                        recPaused ? CupertinoIcons.mic_fill : CupertinoIcons.pause_fill,
                        semanticLabel: recPaused ? l.voiceResume : l.voicePause,
                        color: recPaused ? Palette.tileRed : p.label,
                        size: Tokens.listIcon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          GestureDetector(
            key: const Key('rec-send'),
            onTap: finishRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Icon(CupertinoIcons.arrow_up, color: p.onAccent, size: Tokens.listIcon),
            ),
          ),
        ],
      ),
    );
  }

  Widget recordingBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final took = recTook;
    return Container(
      key: const Key('recording'),
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Container(
            width: 8 + recLevel * 6,
            height: 8 + recLevel * 6,
            decoration: const BoxDecoration(color: Palette.tileRed, shape: BoxShape.circle),
          ),
          SizedBox(width: Tokens.space[1]),
          Text(
            voiceTime(took),
            style: Tokens.body.style.copyWith(color: p.label, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          // Follows the finger to the left (v1), fading as it goes.
          Transform.translate(
            offset: Offset(recDx.clamp(-120.0, 0.0), 0),
            child: Opacity(
              opacity: (1 + recDx / 160).clamp(0.3, 1.0),
              child: Text(
                recCancel ? l.voiceReleaseCancel : l.voiceSlideCancel,
                style: Tokens.preview.style.copyWith(color: recCancel ? Palette.tileRed : p.secondaryLabel),
              ),
            ),
          ),
          SizedBox(width: Tokens.space[2]),
          Icon(CupertinoIcons.lock, key: const Key('rec-lock-hint'), size: Tokens.listIconSmall, color: p.secondaryLabel, semanticLabel: l.voiceLockHint),
        ],
      ),
    );
  }

  void showNotice(String text) {
    noticeTimer?.cancel();
    setState(() => notice = text);
    noticeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => notice = null);
    });
  }

  Future<void> forwardMsg(Msg m) => forwardMany([m]);

  /// Forwards messages (oldest first) to one chat picked from the list.
  Future<void> forwardMany(List<Msg> list) async {
    final l = L.of(context);
    final to = await openSheet<String>(context, (_) => const ForwardPickPage());
    if (to == null || !mounted) return;
    try {
      for (final m in list) {
        await state!.backend.forward(widget.roomId, m.id, to);
      }
      // Forwarded into 저장한 메시지: remember where from (this device only).
      if (to == state!.savedRoomId && to != widget.roomId) {
        final after = await state!.backend.timeline(to, limit: 50);
        await setSavedFrom(state!, [for (final m in after.where((m) => m.mine).toList().reversed.take(list.length)) m.id], widget.roomId);
      }
      if (to == widget.roomId) await load();
      unawaited(state!.refresh());
      if (mounted) showNotice(l.forwardDone);
    } catch (_) {
      if (mounted) showNotice(l.forwardFailed);
    }
  }

  void openSearch() => setState(() {
    searching = true;
    stickersOpen = false;
  });

  void closeSearch() {
    searchInput.clear();
    setState(() {
      searching = false;
      searched = false;
      hits = const [];
      focusId = null;
    });
  }

  Future<void> runSearch(String term) async {
    // 저장한 메시지: an emoji tag searches by tag (Telegram).
    if (isSaved && savedTagChoices.contains(term.trim())) {
      setState(() => tagFilter = term.trim());
      return;
    }
    final found = await state!.backend.searchMessages(widget.roomId, term);
    if (!mounted) return;
    setState(() {
      hits = found;
      hitAt = 0;
      searched = term.trim().isNotEmpty;
    });
    if (found.isNotEmpty) await jumpTo(found.first.id);
  }

  Future<void> stepHit(int d) async {
    final i = hitAt + d;
    if (i < 0 || i >= hits.length) return;
    setState(() => hitAt = i);
    await jumpTo(hits[i].id);
  }

  /// Brings an older message into view: loads more history if needed,
  /// then scrolls until its bubble is built.
  Future<void> jumpTo(String id) async {
    setState(() => focusId = id);
    while (!msgs.any((m) => m.id == id) && limit < 2000) {
      limit *= 2;
      await load();
    }
    await WidgetsBinding.instance.endOfFrame;
    // Not built yet: start from the newest end and walk back in time.
    if (msgKeys[id]?.currentContext == null && scroll.hasClients) {
      scroll.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
    }
    for (var i = 0; i < 60 && mounted; i++) {
      final ctx = msgKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250));
        return;
      }
      if (!scroll.hasClients) return;
      final pos = scroll.position;
      final next = (pos.pixels + pos.viewportDimension * 0.8).clamp(0.0, pos.maxScrollExtent);
      if (next == pos.pixels) return;
      scroll.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Top bar while searching (v1 layout, iOS 27 glass): search capsule +
  /// round X. Capsule 44 tall, X 44, 8 between, 16 side margins.
  GlassTopBar searchTop(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GlassTopBar(
      tint: p.chatBackground.withValues(alpha: 0.7),
      full: Row(
        children: [
          Expanded(
            child: LiquidGlass(
              radius: Tokens.capsule,
              child: SizedBox(
                height: Tokens.closeButton,
                child: CupertinoSearchTextField(
                  key: const Key('msg-search'),
                  controller: searchInput,
                  autofocus: true,
                  placeholder: isSaved ? l.savedSearchHint : l.searchThisChat,
                  backgroundColor: const Color(0x00000000),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  style: Tokens.body.style.copyWith(color: p.label),
                  onSubmitted: runSearch,
                  onChanged: (v) {
                    if (v.trim().isEmpty) setState(() => hits = const []);
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          GlassCircle(key: const Key('search-cancel'), onTap: closeSearch, child: GlassCircle.icon(context, CupertinoIcons.xmark)),
        ],
      ),
    );
  }

  /// Bottom of the search (v1): left capsule = date jump + count, right =
  /// older / newer and "목록으로 보기". Capsules and circles 44 tall.
  Widget searchBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final has = hits.isNotEmpty;
    Widget capsule(String key, Widget child, VoidCallback onTap) => GestureDetector(
      key: Key(key),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LiquidGlass(
        radius: Tokens.capsule,
        child: Container(
          height: Tokens.closeButton,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
    Widget arrow(String key, IconData icon, bool on, VoidCallback go) => Opacity(
      opacity: on ? 1 : 0.35,
      child: GlassCircle(key: Key(key), onTap: on ? go : null, child: GlassCircle.icon(context, icon)),
    );
    final label = has ? l.searchCount(hitAt + 1, hits.length) : (searched ? l.searchNoHits : l.searchByDate);
    return Padding(
      key: const Key('search-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: capsule(
              'search-date',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.calendar, size: Tokens.listIcon, color: p.label),
                  SizedBox(width: Tokens.space[1]),
                  Flexible(
                    child: Text(
                      label,
                      key: const Key('search-count'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                  ),
                ],
              ),
              jumpToDate,
            ),
          ),
          if (has) ...[
            SizedBox(width: Tokens.space[1]),
            arrow('search-older', CupertinoIcons.chevron_up, hitAt < hits.length - 1, () => stepHit(1)),
            SizedBox(width: Tokens.space[1]),
            arrow('search-newer', CupertinoIcons.chevron_down, hitAt > 0, () => stepHit(-1)),
            SizedBox(width: Tokens.space[1]),
            capsule('search-list', Text(l.searchAsList, style: Tokens.body.style.copyWith(color: p.label)), openHitList),
          ],
        ],
      ),
    );
  }

  /// "날짜로 이동": the first message from the chosen day on.
  Future<void> jumpToDate() async {
    final l = L.of(context);
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    final got = await showCupertinoModalPopup<DateTime>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        title: l.searchByDate,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              key: const Key('date-wheel'),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: day,
              maximumDate: day,
              onDateTimeChanged: (d) => day = d,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: AccentButton(key: const Key('date-done'), text: l.done, onTap: () => Navigator.pop(c, day)),
          ),
        ],
      ),
    );
    if (got == null || !mounted) return;
    final from = DateTime(got.year, got.month, got.day);
    // Load older history until that day is covered (or nothing more).
    while (limit < 2000 && msgs.isNotEmpty && msgs.first.time.isAfter(from)) {
      final before = msgs.length;
      limit *= 2;
      await load();
      if (msgs.length == before) break;
    }
    final hit = msgs.where((m) => !m.time.isBefore(from)).firstOrNull;
    if (hit == null) {
      if (mounted) showNotice(l.searchNoneOnDate);
      return;
    }
    await jumpTo(hit.id);
  }

  Future<void> openHitList() async {
    final id = await Navigator.of(context).push<String>(
      IosPageRoute(
        builder: (_) => SearchHitsPage(hits: hits, title: widget.title),
      ),
    );
    if (id == null || !mounted) return;
    final i = hits.indexWhere((m) => m.id == id);
    if (i >= 0) setState(() => hitAt = i);
    await jumpTo(id);
  }

  Future<void> menu(Msg m) async {
    final l = L.of(context);
    final text = m.kind == 'text' && m.body != null;
    final forwardable = !m.viewOnce && m.body != null && const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind);
    final pinned = pins.contains(m.id);
    final saved = isSaved;
    // Notices in the middle (joins, calls) have no menu items of their own.
    final real = m.kind != 'notice';
    final isMarked = marked.contains(m.id);
    final choice = await showMessageMenu(
      context,
      mine: m.mine,
      reactions: menuReactions,
      bubble: Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.title),
      items: [
        if (canPost) MenuItem('reply', l.reply, CupertinoIcons.arrowshape_turn_up_left),
        if (text) MenuItem('copy', l.copy, CupertinoIcons.doc_on_doc),
        if (m.mine && text && canPost) MenuItem('edit', l.edit, CupertinoIcons.pencil),
        if (canPost) MenuItem('pin', pinned ? l.unpin : l.pin, pinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin),
        if (forwardable) MenuItem('forward', l.forward, CupertinoIcons.arrowshape_turn_up_right),
        if (forwardable && !saved) MenuItem('save', l.saveToSaved, CupertinoIcons.bookmark),
        if (saved) MenuItem('tag', l.tagMsg, CupertinoIcons.tag),
        if (real) MenuItem('remind', l.remindMe, CupertinoIcons.alarm),
        if (real) MenuItem('emergency', isMarked ? l.emergencyDeleteOff : l.emergencyDelete, CupertinoIcons.exclamationmark_shield),
        if (!saved) MenuItem('hide-room', roomHidden ? l.emergencyHideRoomOff : l.emergencyHideRoom, CupertinoIcons.eye_slash),
        if (m.poll != null && !m.poll!.closedAt(DateTime.now()) && !m.poll!.isQuiz && m.poll!.mine.isNotEmpty)
          MenuItem('retract', l.pollRetract, CupertinoIcons.arrow_uturn_left),
        if (m.poll != null && m.mine && !m.poll!.closed) MenuItem('close-poll', l.pollClose, CupertinoIcons.stop_circle),
        if (m.mine) MenuItem('delete', l.delete, CupertinoIcons.trash, danger: true),
        if (real) MenuItem('select', l.selectMsg, CupertinoIcons.checkmark_circle, group: true),
      ],
    );
    await doAction(m, choice);
  }

  /// Runs one message action (long-press menu or the select "더보기" sheet).
  Future<void> doAction(Msg m, String? choice) async {
    final l = L.of(context);
    final pinned = pins.contains(m.id);
    final isMarked = marked.contains(m.id);
    if (choice == 'pin' && pinned) choice = 'unpin';
    switch (choice) {
      case 'info':
        await showMessageInfo(m);
      case 'thread':
        await openThread(m);
      case 'report':
        await reportMsg(m);
      case 'reply':
        setState(() {
          replying = m;
          editing = null;
        });
      case 'edit':
        setState(() {
          replying = null;
          editing = m;
        });
        input.text = m.body ?? '';
      case 'copy':
        await Clipboard.setData(ClipboardData(text: plainText(m.body ?? '')));
      case 'forward':
        await forwardMsg(m);
      case 'save':
        await saveWithTag([m]);
      case 'tag':
        await tagSaved([m.id]);
      case 'retract':
        await state!.backend.vote(widget.roomId, m.id, const []);
        await load();
      case 'close-poll':
        await state!.backend.closePoll(widget.roomId, m.id);
        await load();
      case 'delete':
        startDelete([m.id]);
      case 'remind':
        await remind(m);
      case 'emergency':
        if (kIsWeb) {
          if (mounted) await showEmergencyWebNotice(context);
          return;
        }
        await state!.backend.markForDelete(widget.roomId, m.id, !isMarked);
        if (!mounted) return;
        setState(() => isMarked ? marked.remove(m.id) : marked.add(m.id));
        showNotice(isMarked ? l.emergencyUnmarked : l.emergencyMarked);
      case 'hide-room':
        if (kIsWeb) {
          if (mounted) await showEmergencyWebNotice(context);
          return;
        }
        final ql = await state!.backend.quietLists();
        final hide = [...ql.first.where((x) => x != widget.roomId), if (!roomHidden) widget.roomId];
        await state!.backend.setQuietLists(hide, ql.last);
        if (!mounted) return;
        setState(() => roomHidden = !roomHidden);
        showNotice(roomHidden ? l.emergencyHidden : l.emergencyUnhidden);
      case 'select':
        startSelect(m);
      case 'pin' || 'unpin':
        await state!.backend.pin(widget.roomId, m.id, choice == 'pin');
        await load();
      case final String r when r.startsWith('react:'):
        await toggleReaction(m, r.substring(6));
    }
  }

  /// Select mode "더보기" (v1): the less common actions for one message.
  Future<void> moreSheet(Msg m) async {
    final l = L.of(context);
    final text = m.kind == 'text' && m.body != null;
    final real = m.kind != 'notice';
    final pinned = pins.contains(m.id);
    final isMarked = marked.contains(m.id);
    CupertinoActionSheetAction row(BuildContext c, String id, String label, {bool danger = false}) =>
        CupertinoActionSheetAction(key: Key('more-$id'), isDestructiveAction: danger, onPressed: () => Navigator.pop(c, id), child: Text(label));
    final choice = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (canPost) row(c, 'reply', l.reply),
          if (text) row(c, 'copy', l.copy),
          if (m.mine && text && canPost) row(c, 'edit', l.edit),
          if (canPost && real && !isSaved) row(c, 'thread', l.threadReply),
          if (canPost) row(c, 'pin', pinned ? l.unpin : l.pin),
          if (real) row(c, 'emergency', isMarked ? l.emergencyDeleteOff : l.emergencyDelete),
          if (real) row(c, 'info', l.msgInfo),
          if (real && !m.mine) row(c, 'report', l.msgReport, danger: true),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (choice != null && mounted) await doAction(m, choice);
  }

  /// "메시지 정보": when it was sent, read, edited, and when it disappears.
  Future<void> showMessageInfo(Msg m) async {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(lang).add_jm();
    String? status;
    if (m.mine) {
      final read = !isGroup && !isChannel ? await state!.backend.readUntil(widget.roomId) : null;
      status = read != null && !read.isBefore(m.time) ? l.infoRead : l.infoSentOnly;
    }
    if (!mounted) return;
    await showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        key: const Key('info-sheet'),
        title: l.msgInfo,
        children: [
          SheetRow(label: l.infoSent, trailing: fmt.format(m.time), onTap: () {}),
          if (status != null) SheetRow(key: const Key('info-status'), label: l.infoStatus, trailing: status, onTap: () {}),
          if (m.edited) SheetRow(label: l.edited, trailing: '✓', onTap: () {}),
          if (m.forwarded) SheetRow(label: l.forwarded, trailing: '✓', onTap: () {}),
          if (m.expiresAt != null) SheetRow(label: l.infoExpires, trailing: fmt.format(m.expiresAt!), onTap: () {}),
          SizedBox(height: Tokens.space[1]),
        ],
      ),
    );
  }

  /// "메시지 신고": pick a reason; the sheet says the operator reads it.
  Future<void> reportMsg(Msg m) async {
    final l = L.of(context);
    final p = paletteOf(context);
    final reasons = [l.reportSpam, l.reportScam, l.reportViolence, l.reportSexual, l.reportChild, l.reportDrugs, l.reportPrivacy, l.reportOther];
    final why = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        key: const Key('report-sheet'),
        title: l.msgReport,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Text(l.reportNote, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          ),
          for (var i = 0; i < reasons.length; i++) SheetRow(key: Key('report-$i'), label: reasons[i], onTap: () => Navigator.pop(c, reasons[i])),
          SizedBox(height: Tokens.space[1]),
        ],
      ),
    );
    if (why == null || !mounted) return;
    final shown = m.kind == 'text' ? plainText(m.body ?? '') : previewTextL(l, kind: m.kind, body: m.body);
    try {
      await state!.backend.reportMessage(widget.roomId, m.id, why, shown);
      if (mounted) showNotice(l.reportDone);
    } catch (_) {
      if (mounted) showNotice(l.reportFailed);
    }
  }

  /// Replies per thread start (message id).
  Map<String, List<Msg>> threads = {};

  Future<void> openThread(Msg root) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ThreadPage(roomId: widget.roomId, root: root, chatTitle: widget.title),
      ),
    );
    if (mounted) await load();
  }

  /// Select mode ("선택"): ids of the chosen messages; null = off.
  Set<String>? selected;

  void startSelect(Msg m) => setState(() {
    selected = {m.id};
    replying = null;
    editing = null;
    stickersOpen = false;
  });

  void endSelect() => setState(() => selected = null);

  void toggleSelect(Msg m) => setState(() {
    final s = selected!;
    s.contains(m.id) ? s.remove(m.id) : s.add(m.id);
  });

  /// The chosen messages, oldest first.
  List<Msg> get chosen => [
    for (final m in msgs)
      if (selected?.contains(m.id) ?? false) m,
  ];

  static bool canForward(Msg m) => !m.viewOnce && m.body != null && const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind);

  Future<void> selectAction(String what) async {
    final l = L.of(context);
    final list = chosen;
    if (list.isEmpty) return;
    switch (what) {
      case 'delete':
        endSelect();
        startDelete([for (final m in list) m.id]);
      case 'tag':
        endSelect();
        if (isSaved) {
          await tagSaved([for (final m in list) m.id]);
        } else {
          await saveWithTag(list.where(canForward).toList());
        }
      case 'share':
        // v1 "공유" = send to my other chats here (not other apps).
        endSelect();
        await forwardMany(list.where(canForward).toList());
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: [
              for (final m in list)
                if (m.kind == 'text' && m.body != null) plainText(m.body!),
            ].join('\n'),
          ),
        );
        endSelect();
        showNotice(l.copied);
      case 'forward':
        endSelect();
        await forwardMany(list.where(canForward).toList());
      case 'more':
        final m = list.single;
        endSelect();
        await moreSheet(m);
    }
  }

  /// Top bar while selecting (v1 layout): "메시지 비우기" · "N개 선택됨" · "취소".
  GlassTopBar selectBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GlassTopBar.nav(
      leading: GlassPill(key: const Key('select-clear'), text: l.clearChat, onTap: clearAsk),
      middle: LiquidGlass(
        radius: Tokens.capsule,
        child: Container(
          height: Tokens.closeButton,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Center(
            widthFactor: 1,
            child: Text(
              l.selectedN(selected!.length),
              key: const Key('select-count'),
              style: Tokens.body.style.copyWith(color: p.label),
            ),
          ),
        ),
      ),
      trailing: GlassPill(key: const Key('select-cancel'), text: l.cancel, onTap: endSelect),
      backgroundColor: p.chatBackground.withValues(alpha: 0.7),
    );
  }

  /// "메시지 비우기": clears this chat on my screen only.
  Future<void> clearAsk() async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.clearChatInfo),
        actions: [
          CupertinoActionSheetAction(key: const Key('clear-ok'), isDestructiveAction: true, onPressed: () => Navigator.pop(c, true), child: Text(l.clearChat)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    await state!.setPref('cleared:${widget.roomId}', '${DateTime.now().millisecondsSinceEpoch}');
    endSelect();
    await load();
    if (mounted) showNotice(l.clearChatDone);
  }

  /// Bottom bar while selecting: five round glass buttons.
  Widget selectTools(BuildContext context) {
    final p = paletteOf(context);
    final list = chosen;
    final allMine = list.isNotEmpty && list.every((m) => m.mine);
    final fwd = list.isNotEmpty && list.every(canForward);
    Widget b(String id, IconData icon, bool on, {Color? color}) => Opacity(
      opacity: on ? 1 : 0.35,
      child: GlassCircle(
        key: Key('select-$id'),
        onTap: on ? () => selectAction(id) : null,
        child: Icon(icon, size: Tokens.listIcon, color: color ?? p.label),
      ),
    );
    return Padding(
      key: const Key('select-tools'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          b('delete', CupertinoIcons.trash, allMine, color: Palette.tileRed),
          b('tag', CupertinoIcons.tag, isSaved || fwd),
          b('share', CupertinoIcons.square_arrow_up, fwd),
          b('forward', CupertinoIcons.arrowshape_turn_up_right, fwd),
          b('more', CupertinoIcons.ellipsis, list.length == 1),
        ],
      ),
    );
  }

  Future<void> openInfo() async {
    if (isSaved) {
      await Navigator.of(context).push(IosPageRoute(builder: (_) => SavedInfoPage(roomId: widget.roomId)));
      return;
    }
    final r = await Navigator.of(context).push<String>(
      IosPageRoute(
        builder: (_) => ChatInfoPage(roomId: widget.roomId, title: widget.title, isGroup: isGroup, isChannel: isChannel),
      ),
    );
    if (r == 'search' && mounted) openSearch();
    if (mounted) {
      setState(() {});
      unawaited(load());
    }
  }

  /// The chat's photo in the top bar (44, like the round buttons).
  Widget headerPhoto(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.chats.where((x) => x.roomId == widget.roomId).firstOrNull;
    final direct = c?.isDirect ?? !(isGroup || isChannel);
    return Avatar(
      name: titleOf(s, widget.roomId, widget.title),
      size: Tokens.closeButton,
      squircle: !direct,
      userId: direct ? c?.peer : null,
      roomId: widget.roomId,
      owner: c != null && c.isChannel ? c.peer : null,
    );
  }

  bool get isSaved => widget.roomId == state?.savedRoomId || widget.title == L.of(context).savedMessages;

  /// Saved messages: '' = all, 'note' = my notes, else the source chat.
  String savedSource = '';

  Future<void> openSavedSideList() async {
    final pick = await openSavedSide(context, msgs: msgs, current: savedSource);
    if (pick == savedExit) {
      if (mounted) await Navigator.of(context).maybePop();
      return;
    }
    if (pick != null && mounted) {
      setState(() {
        savedSource = pick;
        tagFilter = '';
      });
    }
  }

  /// Saves copies in "저장한 메시지", then offers the 12 emoji tags (v1).
  Future<void> saveWithTag(List<Msg> list) async {
    final l = L.of(context);
    if (list.isEmpty) return;
    final List<String> copies;
    try {
      final b = state!.backend;
      final saved = await b.savedRoom(create: true);
      if (saved == null) throw StateError('no saved chat');
      for (final m in list) {
        await b.forward(widget.roomId, m.id, saved);
      }
      final after = await b.timeline(saved, limit: 50);
      copies = [for (final m in after.where((m) => m.mine).toList().reversed.take(list.length)) m.id];
      await setSavedFrom(state!, copies, widget.roomId);
    } catch (_) {
      if (mounted) showNotice(l.forwardFailed);
      return;
    }
    if (!mounted) return;
    final tag = await pickSavedTag(context, saved: true);
    if (tag != null) await setSavedTag(state!, copies, tag);
  }

  /// Inside "저장한 메시지": choose or remove the tag of messages.
  Future<void> tagSaved(List<String> ids) async {
    final tag = await pickSavedTag(context, saved: false, current: ids.length == 1 ? savedTags(state!)[ids.single] : null);
    if (tag == null || !mounted) return;
    await setSavedTag(state!, ids, tag.isEmpty ? null : tag);
    if (mounted) setState(() {});
  }

  /// Saved messages: the tag chosen in the filter row ('' = all).
  String tagFilter = '';

  static final _linkRe = RegExp(r'https?://\S+');
  bool hasLink(Msg m) => m.kind == 'text' && _linkRe.hasMatch(m.body ?? '');

  /// Saved messages: the tag on a bubble (Telegram shows it like a reaction).
  List<Reaction>? savedTagReaction(Msg m, Map<String, String> tagOf) {
    final t = tagOf[m.id];
    return t == null ? null : [Reaction(t, 1, 'tag')];
  }

  Widget tagRow(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final tags = savedTags(state!);
    final from = savedFrom(state!);
    // Counts follow the chat chosen in the side list (v1: 링크 1, ✅ 1, ❤ 1).
    final here = [
      for (final m in msgs)
        if (inSavedSource(m, savedSource, from)) m,
    ];
    final links = here.where(hasLink).length;
    final count = <String, int>{};
    for (final m in here) {
      final t = tags[m.id];
      if (t != null) count[t] = (count[t] ?? 0) + 1;
    }
    final used = [
      for (final t in savedTagChoices)
        if ((count[t] ?? 0) > 0) t,
    ];
    if (used.isEmpty && links == 0) return const SizedBox.shrink();
    Widget chip(String t, String label) {
      final on = tagFilter == t;
      return GestureDetector(
        key: Key('tag-filter-${t.isEmpty ? 'all' : t}'),
        onTap: () => setState(() => tagFilter = t),
        child: Container(
          height: 32,
          margin: EdgeInsets.only(right: Tokens.space[1]),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(label, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
        ),
      );
    }

    return SizedBox(
      key: const Key('tag-row'),
      height: 32 + Tokens.space[2],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[0]),
        children: [chip('', l.tagAll), if (links > 0) chip('link', '${l.savedLinkTag} $links'), for (final t in used) chip(t, '$t ${count[t]}')],
      ),
    );
  }

  Future<void> remind(Msg m) async {
    final l = L.of(context);
    final at = await pickReminderTime(context);
    if (at == null || !mounted) return;
    await addReminder(state!, Reminder(roomId: widget.roomId, msgId: m.id, chat: widget.title, at: at));
    if (!mounted) return;
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    showNotice(l.remindSet(fmt.format(at)));
  }

  /// Adds my emoji, or takes it back when I already chose it.
  Future<void> toggleReaction(Msg m, String key) async {
    final b = state!.backend;
    final mine = m.reactions.where((r) => r.key == key && r.mine != null).firstOrNull?.mine;
    if (mine == null) {
      // The room's reaction rules (admin tools).
      final ok = allowedReactions(cfg);
      if (ok != null && !ok.contains(key)) return;
      final shown = shownReactions(m);
      if (shown.length >= reactionsMax(cfg) && !shown.any((r) => r.key == key)) return;
    }
    if (mine != null) {
      await b.deleteMessage(widget.roomId, mine);
    } else {
      await b.react(widget.roomId, m.id, key);
    }
    await load();
  }

  String whoName(BuildContext context, String sender) => sender == state?.backend.userId ? L.of(context).you : displayId(sender);

  Widget undoBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Container(
      key: const Key('undo-bar'),
      margin: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Text('$undoLeft', style: Tokens.body.style.copyWith(color: p.accent)),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Text(l.deleted, style: Tokens.body.style.copyWith(color: p.label)),
          ),
          CupertinoButton(
            key: const Key('undo'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: undoDelete,
            child: Text(l.undo, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
  }

  /// Latest pinned message, under the title (like Telegram).
  Widget pinnedBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final m = msgs.where((x) => x.id == pins.last).firstOrNull;
    // iOS 27: a floating glass capsule under the bar, not a full-width strip.
    return Padding(
      key: const Key('pinned-bar'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: LiquidGlass(
        radius: 24,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
          child: Row(
            children: [
              Container(width: 2, height: 32, color: p.accent),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pinnedMessage, style: Tokens.caption.style.copyWith(color: p.accent)),
                    Text(
                      m == null ? '' : previewText(context, kind: m.kind, body: m.body),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: p.label),
                    ),
                  ],
                ),
              ),
              Icon(CupertinoIcons.pin, size: Tokens.listIconSmall, color: p.secondaryLabel),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown above the composer while answering or fixing a message.
  Widget modeBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final m = (editing ?? replying)!;
    return Container(
      key: const Key('mode-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], 0),
      child: Row(
        children: [
          Icon(editing != null ? CupertinoIcons.pencil : CupertinoIcons.reply, color: p.accent, size: Tokens.listIcon),
          SizedBox(width: Tokens.space[2]),
          Container(width: 2, height: 34, color: p.accent),
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(editing != null ? l.editing : whoName(context, m.sender), style: Tokens.caption.style.copyWith(color: p.accent)),
                Text(
                  previewText(context, kind: m.kind, body: m.body),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.caption.style.copyWith(color: p.label),
                ),
              ],
            ),
          ),
          CupertinoButton(
            key: const Key('mode-close'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: () {
              if (editing != null) input.clear();
              setState(() => replying = editing = null);
            },
            child: Icon(CupertinoIcons.xmark, color: p.secondaryLabel, size: Tokens.listIconSmall),
          ),
        ],
      ),
    );
  }

  /// The room's welcome message, until I close it (once per room).
  String? get welcomeText {
    final w = (cfg['welcome'] as String? ?? '').trim();
    if (w.isEmpty || isAdmin || state!.on('welcomed:${widget.roomId}')) return null;
    return w;
  }

  Widget welcomeCard(BuildContext context, String text) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      key: const Key('welcome-card'),
      padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      child: LiquidGlass(
        radius: Tokens.radius[3],
        child: Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[1], Tokens.space[2]),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('👋', style: TextStyle(fontSize: Tokens.cardTitle.size)),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.welcomeTitle,
                      style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      text,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: p.label),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                key: const Key('welcome-close'),
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 32),
                onPressed: () => state!.setOn('welcomed:${widget.roomId}', true),
                child: Icon(CupertinoIcons.xmark, size: 16, color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final tagOf = isSaved ? savedTags(state!) : const <String, String>{};
    final from = isSaved ? savedFrom(state!) : const <String, String>{};
    final shown = msgs
        .where(
          (m) =>
              !(pendingDelete?.contains(m.id) ?? false) &&
              (tagFilter.isEmpty || (tagFilter == 'link' ? hasLink(m) : tagOf[m.id] == tagFilter)) &&
              (!isSaved || inSavedSource(m, savedSource, from)),
        )
        .toList();
    final sourceChat = isSaved && savedSource.isNotEmpty && savedSource != 'note' ? savedSource : null;
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: selected != null
          ? selectBar(context)
          : searching
          ? searchTop(context)
          : GlassTopBar.nav(
              leading: const GlassBack(),
              // v1 layout, Telegram sizes: a glass capsule with the lock,
              // name and '끝까지 잠김' (or who is typing); photo on the right.
              middle: GestureDetector(
                key: const Key('chat-title'),
                onTap: openInfo,
                child: LiquidGlass(
                  radius: Tokens.capsule,
                  child: Container(
                    height: Tokens.closeButton,
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (sourceChat != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Avatar(name: savedSourceName(state!, sourceChat), size: 22, roomId: sourceChat),
                              SizedBox(width: Tokens.space[1]),
                              Flexible(child: Text(savedSourceName(state!, sourceChat), key: const Key('saved-source-title'))),
                            ],
                          )
                        else if (isSaved)
                          Text(savedSource == 'note' ? l.savedNotes : l.savedMessages)
                        else
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.lock, key: const Key('title-lock'), size: 14, color: p.label),
                              const SizedBox(width: 3),
                              Flexible(child: Text(titleOf(AppScope.of(context), widget.roomId, widget.title))),
                            ],
                          ),
                        if (isSaved && savedSource.isEmpty && savedSources(msgs, from).isNotEmpty)
                          Text(
                            l.savedChatsCount(savedSources(msgs, from).length),
                            key: const Key('saved-count'),
                            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                          ),
                        if (typers.isNotEmpty)
                          Text(
                            isGroup ? '${typers.map(displayId).join(', ')} · ${l.typing}' : l.typing,
                            key: const Key('typing'),
                            style: Tokens.caption.style.copyWith(color: p.accent),
                          )
                        else if (!isSaved)
                          Text(
                            l.chatLocked,
                            key: const Key('title-locked'),
                            style: Tokens.caption.style.copyWith(color: p.accent),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              backgroundColor: p.chatBackground.withValues(alpha: 0.7),
              border: null,
              trailing: isSaved
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassCircle(key: const Key('saved-search'), onTap: openSearch, child: GlassCircle.icon(context, CupertinoIcons.search)),
                        SizedBox(width: Tokens.space[1]),
                        GlassCircle(key: const Key('saved-side-open'), onTap: openSavedSideList, child: GlassCircle.icon(context, CupertinoIcons.sidebar_left)),
                      ],
                    )
                  : GestureDetector(key: const Key('title-photo'), onTap: openInfo, child: headerPhoto(context)),
            ),
      child: ChatWallpaper(
        roomId: widget.roomId,
        child: SafeArea(
          child: Column(
            children: [
              if (pins.isNotEmpty) pinnedBar(context),
              if (isSaved) tagRow(context),
              Expanded(
                child: ListView.builder(
                  key: listKey,
                  controller: scroll,
                  reverse: true,
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[1]),
                  itemCount: shown.length + 1,
                  itemBuilder: (c, i) {
                    if (i == shown.length) {
                      return Padding(
                        padding: EdgeInsets.all(Tokens.space[3]),
                        child: Text(
                          l.encryptedNotice,
                          textAlign: TextAlign.center,
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      );
                    }
                    final m = shown[shown.length - 1 - i];
                    if (m.kind == 'opened') {
                      return Padding(
                        key: const Key('opened-line'),
                        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                        child: Center(
                          child: Text(l.viewOnceOpenedLine, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                        ),
                      );
                    }
                    if (m.kind == 'call' && m.call != null) {
                      return CallLine(
                        key: Key('call-line-${m.id}'),
                        msg: m,
                        onCallBack: isGroup || isChannel ? null : (video) => startCall(context, widget.roomId, widget.title, video: video),
                      );
                    }
                    if (m.kind == 'verify') {
                      // A request to check each other's keys: a centred card
                      // (only the other person's request has a button).
                      return Padding(
                        key: Key('verify-line-${m.id}'),
                        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.lock_shield, size: Tokens.listIconSmall, color: p.accent),
                                SizedBox(width: Tokens.space[1]),
                                Text(l.verifyRequestLine, style: Tokens.caption.style.copyWith(color: p.label)),
                                SizedBox(width: Tokens.space[1]),
                                if (!m.mine)
                                  GestureDetector(
                                    key: Key('verify-open-${m.id}'),
                                    onTap: () => openSheet<void>(context, (_) => VerifyPage(userId: m.sender, name: displayId(m.sender), flowId: m.id)),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                                      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                      child: Text(l.verifyOpen, style: Tokens.caption.style.copyWith(color: p.onAccent)),
                                    ),
                                  )
                                else
                                  SizedBox(width: Tokens.space[1]),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (m.kind == 'timer') {
                      final secs = int.tryParse(m.body ?? '') ?? 0;
                      return Padding(
                        key: const Key('timer-line'),
                        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                            child: Text(
                              secs == 0 ? l.timerOffLine : l.timerLine(timerLabel(context, secs)),
                              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                            ),
                          ),
                        ),
                      );
                    }
                    final q = m.replyTo == null ? null : msgs.where((x) => x.id == m.replyTo).firstOrNull;
                    final focused = m.id == focusId;
                    return AnimatedContainer(
                      key: msgKeys.putIfAbsent(m.id, GlobalKey.new),
                      duration: const Duration(milliseconds: 200),
                      color: focused ? p.accent.withValues(alpha: 0.14) : p.accent.withValues(alpha: 0),
                      // Settings > Chats: double tap = my quick reaction (a
                      // plain pointer listener, so taps inside the bubble are
                      // not slowed down), swipe left = reply.
                      child: selected != null
                          ? GestureDetector(
                              key: Key('select-row-${m.id}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => toggleSelect(m),
                              child: Row(
                                children: [
                                  SelectCircle(on: selected!.contains(m.id)),
                                  Expanded(
                                    child: IgnorePointer(
                                      child: Bubble(
                                        msg: m,
                                        roomId: widget.roomId,
                                        read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                        senderName: (isGroup && !isChannel && !m.mine) || signed ? displayId(m.sender) : null,
                                        quote: q,
                                        quoteName: q == null ? null : whoName(context, q.sender),
                                        chatTitle: widget.title,
                                        reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                        hideCounts: hideCounts || isSaved,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Listener(
                              onPointerUp: (e) => doubleTapCheck(m, e),
                              child: GestureDetector(
                                // Veiled chats: holding shows the text, so a short
                                // tap opens the menu instead.
                                onTap: veiled ? () => menu(m) : null,
                                onLongPress: veiled ? null : () => menu(m),
                                onHorizontalDragEnd: state!.on('swipe_reply', fallback: true)
                                    ? (d) {
                                        if ((d.primaryVelocity ?? 0) < -250) setState(() => replying = m);
                                      }
                                    : null,
                                child: Bubble(
                                  msg: m,
                                  roomId: widget.roomId,
                                  read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                  senderName: (isGroup && !isChannel && !m.mine) || signed ? displayId(m.sender) : null,
                                  quote: q,
                                  quoteName: q == null ? null : whoName(context, q.sender),
                                  onReaction: isSaved ? (_) => tagSaved([m.id]) : (key) => toggleReaction(m, key),
                                  onOpenOnce: () => openOnce(m),
                                  onPollChanged: load,
                                  chatTitle: widget.title,
                                  reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                  hideCounts: hideCounts || isSaved,
                                  threadCount: threads[m.id]?.length ?? 0,
                                  onThread: () => openThread(m),
                                  onComments: isChannel && discussionName(state!, cfg) != null
                                      ? () => openChat(context, cfg['discussion'] as String, discussionName(state!, cfg)!)
                                      : null,
                                ),
                              ),
                            ),
                    );
                  },
                ),
              ),
              if (pendingDelete != null) undoBar(context),
              if (pendingSend != null) sendUndoBar(context),
              if (state!.scheduled.any((m) => m['room'] == widget.roomId))
                GestureDetector(
                  key: const Key('scheduled-chip'),
                  onTap: () async {
                    await Navigator.of(context).push(IosPageRoute(builder: (_) => ScheduledPage(roomId: widget.roomId)));
                    await load();
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: Tokens.space[1]),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.clock, size: 15, color: p.accent),
                        const SizedBox(width: 4),
                        Text(
                          L.of(context).scheduledCount(state!.scheduled.where((m) => m['room'] == widget.roomId).length),
                          style: Tokens.caption.style.copyWith(color: p.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              if (welcomeText case final w?) welcomeCard(context, w),
              if (notice != null)
                Padding(
                  key: const Key('notice'),
                  padding: EdgeInsets.only(bottom: Tokens.space[1]),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(notice!, style: Tokens.preview.style.copyWith(color: p.label)),
                  ),
                ),
              if (selected != null)
                selectTools(context)
              else if (searching)
                searchBar(context)
              else if (sourceChat != null)
                Padding(
                  key: const Key('saved-source-bar'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                  child: Row(
                    children: [
                      const SizedBox(width: Tokens.closeButton),
                      Expanded(
                        child: Center(
                          child: GlassPill(
                            key: const Key('saved-open-chat'),
                            text: l.savedOpenChat,
                            onTap: () => openChat(context, sourceChat, savedSourceName(state!, sourceChat)),
                          ),
                        ),
                      ),
                      GlassCircle(key: const Key('saved-source-search'), onTap: openSearch, child: GlassCircle.icon(context, CupertinoIcons.search)),
                    ],
                  ),
                )
              else if (canPost && mustAgree)
                Padding(
                  key: const Key('rules-gate'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                  child: Column(
                    children: [
                      Text(
                        l.rulesReadFirst,
                        textAlign: TextAlign.center,
                        style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                      ),
                      SizedBox(height: Tokens.space[1]),
                      GlassPill(
                        key: const Key('rules-open'),
                        text: l.readRules,
                        onTap: () => openSheet<void>(
                          context,
                          (_) => RulesSheet(rules: (cfg['rules'] as String? ?? '').trim(), onAgree: () => state!.setOn('agreed:${widget.roomId}', true)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (!canPost)
                Container(
                  key: const Key('read-only'),
                  width: double.infinity,
                  padding: EdgeInsets.all(Tokens.space[3]),
                  child: Text(
                    l.channelReadOnly,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                )
              else ...[
                if (replying != null || editing != null) modeBar(context),
                if (recLocked && recStart != null)
                  lockedRecordingBar(context)
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], Tokens.space[1]),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // iOS 27 Messages: "+" in its own glass circle.
                        GlassCircle(
                          key: const Key('attach'),
                          size: Tokens.closeButton,
                          onTap: attach,
                          child: Icon(CupertinoIcons.plus, color: p.label, size: 22),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        Expanded(
                          child: recStart != null
                              ? recordingBar(context)
                              : CupertinoTextField(
                                  key: const Key('composer'),
                                  controller: input,
                                  placeholder: isChannel ? (channelSilent ? l.channelPostSilent : l.channelPostLoud) : l.messageHint,
                                  // Channels: who posts (my picture) on the left, v1.
                                  prefix: isChannel
                                      ? Padding(
                                          padding: EdgeInsets.only(left: Tokens.space[1]),
                                          child: Avatar(name: displayId(state!.backend.userId ?? ''), size: 24),
                                        )
                                      : null,
                                  minLines: 1,
                                  maxLines: 6,
                                  onChanged: onTyped,
                                  textInputAction: state!.on('enter_send') ? TextInputAction.send : TextInputAction.newline,
                                  onSubmitted: state!.on('enter_send') ? (_) => send() : null,
                                  onTap: () => setState(() => stickersOpen = false),
                                  contextMenuBuilder: (context, st) {
                                    final items = [...st.contextMenuButtonItems];
                                    if (!st.textEditingValue.selection.isCollapsed) {
                                      void f(String mark) {
                                        wrapSelection(input, mark);
                                        st.hideToolbar();
                                      }

                                      items.addAll([
                                        ContextMenuButtonItem(label: l.fmtBold, onPressed: () => f('**')),
                                        ContextMenuButtonItem(label: l.fmtItalic, onPressed: () => f('__')),
                                        ContextMenuButtonItem(label: l.fmtUnderline, onPressed: () => f('++')),
                                        ContextMenuButtonItem(label: l.fmtStrike, onPressed: () => f('~~')),
                                        ContextMenuButtonItem(label: l.fmtCode, onPressed: () => f('`')),
                                        ContextMenuButtonItem(label: l.fmtSpoiler, onPressed: () => f('||')),
                                        ContextMenuButtonItem(
                                          label: l.fmtLink,
                                          onPressed: () async {
                                            st.hideToolbar();
                                            final sel = input.selection;
                                            final url = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const LinkEditPage()));
                                            if (url == null) return;
                                            input.selection = sel;
                                            wrapSelection(input, '', url: url);
                                          },
                                        ),
                                      ]);
                                    }
                                    return CupertinoAdaptiveTextSelectionToolbar.buttonItems(anchors: st.contextMenuAnchors, buttonItems: items);
                                  },
                                  suffix: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isChannel)
                                        CupertinoButton(
                                          key: const Key('channel-bell'),
                                          padding: EdgeInsets.only(right: Tokens.space[1]),
                                          minimumSize: const Size(32, 32),
                                          onPressed: toggleChannelBell,
                                          child: Icon(
                                            channelSilent ? CupertinoIcons.bell_slash : CupertinoIcons.bell,
                                            color: p.secondaryLabel,
                                            size: Tokens.listIcon + 2,
                                          ),
                                        ),
                                      // v1: the timer sits in the field, next to stickers.
                                      CupertinoButton(
                                        key: const Key('timer-button'),
                                        padding: EdgeInsets.only(right: Tokens.space[1]),
                                        minimumSize: const Size(32, 32),
                                        onPressed: chooseTimer,
                                        child: Icon(
                                          timerSecs > 0 ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
                                          color: timerSecs > 0 ? p.accent : p.secondaryLabel,
                                          size: Tokens.listIcon + 2,
                                        ),
                                      ),
                                      CupertinoButton(
                                        key: const Key('sticker-button'),
                                        padding: EdgeInsets.only(right: Tokens.space[1]),
                                        minimumSize: const Size(32, 32),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() => stickersOpen = !stickersOpen);
                                        },
                                        child: Icon(
                                          stickersOpen ? CupertinoIcons.keyboard : CupertinoIcons.smiley,
                                          color: p.secondaryLabel,
                                          size: Tokens.listIcon + 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Telegram iOS: 44 tall like the round buttons.
                                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: (Tokens.closeButton - Tokens.body.lineHeight) / 2),
                                  style: Tokens.body.style.copyWith(color: p.label),
                                  decoration: BoxDecoration(
                                    color: p.card.withValues(alpha: p.dark ? 0.55 : 0.75),
                                    borderRadius: BorderRadius.circular(Tokens.closeButton / 2),
                                  ),
                                ).glassEdge(radius: Tokens.closeButton / 2),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: input,
                          builder: (context, v, _) {
                            final mic = v.text.trim().isEmpty && editing == null && VoiceKit.canRecord;
                            if (!mic) {
                              return GestureDetector(
                                key: const Key('send'),
                                onTap: send,
                                onLongPress: editing == null && replying == null ? sendOptions : null,
                                child: Container(
                                  width: Tokens.closeButton,
                                  height: Tokens.closeButton,
                                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: BurumyMark(color: p.onAccent, size: 28),
                                ),
                              );
                            }
                            // Hold to record, let go to send, slide left to cancel.
                            return GestureDetector(
                              key: const Key('mic'),
                              onTap: () => showNotice(l.voiceHoldHint),
                              onLongPressStart: (_) => startRecording(),
                              onLongPressMoveUpdate: (d) {
                                if (recLocked || recStart == null) return;
                                final o = d.offsetFromOrigin;
                                // Slide up: lock (keeps recording after letting go).
                                if (o.dy < -60 && o.dx > -40) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    recLocked = true;
                                    recCancel = false;
                                    recDx = 0;
                                  });
                                  return;
                                }
                                setState(() {
                                  recDx = o.dx < 0 ? o.dx : 0;
                                  recCancel = o.dx < -80;
                                });
                              },
                              onLongPressEnd: (_) {
                                if (!recLocked) finishRecording();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: recStart != null ? 48 : Tokens.closeButton,
                                height: recStart != null ? 48 : Tokens.closeButton,
                                decoration: BoxDecoration(color: recStart != null ? p.accent : p.incoming, shape: BoxShape.circle),
                                child: Icon(CupertinoIcons.mic_fill, color: recStart != null ? p.onAccent : p.secondaryLabel, size: Tokens.listIcon + 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                if (stickersOpen)
                  StickerPanel(
                    phrases: quickReplies(state!),
                    onPhrase: (text) {
                      input.text = input.text.isEmpty ? text : "${input.text} $text";
                      input.selection = TextSelection.collapsed(offset: input.text.length);
                      setState(() => stickersOpen = false);
                    },
                    onPick: (id) async {
                      await state!.backend.sendSticker(widget.roomId, id);
                      await load();
                      unawaited(state!.refresh());
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Bubble extends StatelessWidget {
  const Bubble({
    super.key,
    required this.msg,
    required this.roomId,
    this.read = false,
    this.senderName,
    this.quote,
    this.quoteName,
    this.onReaction,
    this.onOpenOnce,
    this.onPollChanged,
    this.chatTitle = '',
    this.reactions,
    this.hideCounts = false,
    this.onComments,
    this.threadCount = 0,
    this.onThread,
  });

  /// Reactions to show (the room may limit them); null = all.
  final List<Reaction>? reactions;

  /// Members of rooms that hide numbers see no counts.
  final bool hideCounts;

  /// Channel post → its discussion group.
  final VoidCallback? onComments;

  /// Replies in this message's thread ("답글 N개" pill opens it).
  final int threadCount;
  final VoidCallback? onThread;
  final void Function(String key)? onReaction;
  final VoidCallback? onOpenOnce;
  final Future<void> Function()? onPollChanged;
  final String chatTitle;
  final Msg msg;
  final String roomId;
  final bool read;

  /// Shown on others' messages in groups.
  final String? senderName;

  /// The message this one answers (null if not loaded or none).
  final Msg? quote;
  final String? quoteName;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final mine = msg.mine;
    final fg = mine && msg.kind != 'sticker' ? p.onAccent : p.label;
    final time = DateFormat.jm(Localizations.localeOf(context).languageCode).format(msg.time);
    final l = L.of(context);
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (msg.edited)
          Text(
            '${l.edited} ',
            key: const Key('edited'),
            style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.6)),
          ),
        if (msg.expiresAt != null) ...[
          Icon(CupertinoIcons.timer, key: const Key('expires'), size: 11, color: fg.withValues(alpha: 0.6)),
          const SizedBox(width: 2),
        ],
        Text(time, style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.6))),
        if (mine) ...[
          const SizedBox(width: 2),
          Icon(
            read ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.checkmark_alt,
            key: Key(read ? 'tick-read' : 'tick-sent'),
            size: 13,
            color: fg.withValues(alpha: 0.75),
          ),
        ],
      ],
    );
    final Widget content;
    final big = msg.kind == 'text' && msg.preview == null && AppScope.of(context).on('big_emoji', fallback: true) && isBigEmoji(msg.body ?? '');
    if (msg.kind == 'sticker' || big) {
      final asset = big ? null : stickerAsset(msg.body ?? '');
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[0], horizontal: Tokens.space[0]),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (senderName != null) Text(senderName!, style: Tokens.caption.style.copyWith(color: Avatar.colorFor(senderName!))),
              SizedBox(
                key: Key(big ? 'big-emoji' : 'sticker-msg'),
                width: big ? null : 150,
                height: big ? null : 150,
                child: big
                    ? BigEmoji(msg.body!.trim())
                    : asset == null
                    ? Icon(CupertinoIcons.smiley, color: p.secondaryLabel, size: 48)
                    : Image.asset(asset, fit: BoxFit.contain),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: meta,
              ),
            ],
          ),
        ),
      );
    }
    if (msg.bubble) {
      content = BubbleMsg(msg: msg, roomId: roomId, name: chatTitle, fg: fg, meta: meta);
    } else if (msg.card != null) {
      content = CardBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {});
    } else if (msg.meetup != null) {
      content = MeetupBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, showWho: senderName != null);
    } else if (msg.contact != null) {
      content = ContactBubble(msg: msg, fg: fg, meta: meta);
    } else if (msg.kind == 'location') {
      content = LocationBubble(msg: msg, fg: fg, meta: meta);
    } else if (msg.checklist != null) {
      content = ChecklistBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, showWho: senderName != null);
    } else if (msg.poll != null) {
      content = PollBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, hideCounts: hideCounts);
    } else if (msg.voice != null) {
      content = VoiceBubble(roomId: roomId, msg: msg, fg: fg, meta: meta);
    } else if (msg.viewOnce) {
      final canOpen = !mine && !msg.opened;
      content = GestureDetector(
        key: const Key('view-once'),
        onTap: canOpen ? onOpenOnce : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: fg, width: 1.5),
              ),
              child: Text('1', style: Tokens.caption.style.copyWith(color: fg)),
            ),
            SizedBox(width: Tokens.space[1]),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.viewOncePhoto, style: Tokens.body.style.copyWith(color: fg)),
                  Text(
                    msg.opened ? l.viewOnceOpened : (canOpen ? l.viewOnceTap : ''),
                    key: msg.opened ? const Key('view-once-opened') : null,
                    style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[1]),
            meta,
          ],
        ),
      );
    } else if (msg.kind == 'image') {
      final cap = msg.caption;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[2]),
            child: EncryptedImage(roomId: roomId, eventId: msg.id),
          ),
          if (cap == null)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[0]),
              child: meta,
            )
          else
            Padding(
              key: const Key('caption'),
              padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], 2),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: Tokens.space[1],
                children: [
                  FormattedText(
                    cap,
                    style: Tokens.body.style.copyWith(color: fg),
                    linkColor: mine ? p.onAccent : p.accent,
                    quoteColor: mine ? p.onAccent : p.accent,
                  ),
                  meta,
                ],
              ),
            ),
        ],
      );
    } else if (msg.caption != null && msg.kind != 'text') {
      content = Column(
        key: const Key('caption'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(msg.kind == 'video' ? CupertinoIcons.videocam_fill : CupertinoIcons.doc, size: Tokens.listIcon, color: fg),
              SizedBox(width: Tokens.space[1]),
              Flexible(
                child: Text(
                  previewText(context, kind: msg.kind, body: msg.body),
                  style: Tokens.body.style.copyWith(color: fg),
                ),
              ),
            ],
          ),
          SizedBox(height: Tokens.space[0]),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Tokens.space[1],
            children: [
              FormattedText(
                msg.caption!,
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: mine ? p.onAccent : p.accent,
                quoteColor: mine ? p.onAccent : p.accent,
              ),
              meta,
            ],
          ),
        ],
      );
    } else {
      final text = previewText(context, kind: msg.kind, body: msg.body);
      final words = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Tokens.space[1],
        children: [
          if (msg.kind == 'file') Icon(CupertinoIcons.doc, size: Tokens.listIcon, color: fg),
          if (msg.kind == 'text')
            FormattedText(
              // The marks themselves (previewText takes them out).
              msg.body ?? '',
              style: Tokens.body.style.copyWith(color: fg),
              linkColor: mine ? p.onAccent : p.accent,
              quoteColor: mine ? p.onAccent : p.accent,
              onPlan: AppScope.of(context).on('plan_pick') ? (at) => planReminder(context, roomId, chatTitle, msg, at) : null,
            )
          else
            Text(text, style: Tokens.body.style.copyWith(color: msg.kind == 'locked' ? fg.withValues(alpha: 0.6) : fg)),
          if (msg.preview == null) meta,
        ],
      );
      final card = msg.preview;
      final scam = !mine && msg.kind == 'text' && AppScope.of(context).on('scam_warning', fallback: true) && hasSuspiciousLink(text);
      final warned = !scam
          ? words
          : Column(
              key: const Key('scam-warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Palette.tileRed, size: 15),
                    SizedBox(width: Tokens.space[0]),
                    Flexible(
                      child: Text(L.of(context).scamLink, style: Tokens.caption.style.copyWith(color: Palette.tileRed)),
                    ),
                  ],
                ),
                SizedBox(height: Tokens.space[0]),
                words,
              ],
            );
      content = card == null
          ? warned
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.centerLeft, child: warned),
                LinkCardView(card: card, roomId: roomId, eventId: msg.id, mine: mine),
                meta,
              ],
            );
    }
    final q = quote;
    final fwd = msg.forwarded
        ? Padding(
            key: const Key('forwarded'),
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_right_fill, size: 12, color: mine ? p.onAccent : p.accent),
                const SizedBox(width: 3),
                Text(l.forwarded, style: Tokens.caption.style.copyWith(color: mine ? p.onAccent : p.accent)),
              ],
            ),
          )
        : null;
    final Widget body = (senderName == null && q == null && fwd == null)
        ? content
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderName != null) Text(senderName!, style: Tokens.caption.style.copyWith(color: Avatar.colorFor(senderName!))),
              ?fwd,
              if (q != null)
                Container(
                  key: const Key('quote'),
                  margin: EdgeInsets.only(top: Tokens.space[0] - 2, bottom: Tokens.space[0]),
                  padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], 2),
                  decoration: BoxDecoration(
                    color: (mine ? p.onAccent : p.accent).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(Tokens.radius[0]),
                    border: Border(left: BorderSide(color: mine ? p.onAccent : p.accent, width: 3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quoteName ?? '', style: Tokens.caption.style.copyWith(color: mine ? p.onAccent : p.accent)),
                      Text(
                        previewText(context, kind: q.kind, body: q.body),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.caption.style.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              content,
            ],
          );
    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: EdgeInsets.symmetric(vertical: 2, horizontal: Tokens.space[0]),
        padding: msg.kind == 'image'
            ? EdgeInsets.all(Tokens.space[0] - 1)
            : EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1] - 2, Tokens.space[2], Tokens.space[1] - 2),
        decoration: BoxDecoration(
          color: mine ? p.accent : p.incoming,
          borderRadius: BorderRadius.circular(double.tryParse(AppScope.of(context).pref('bubble_radius', '')) ?? Tokens.radius[2] + 2),
        ),
        child: Veil(mode: veilOf(AppScope.of(context), roomId), ink: fg, child: body),
      ),
    );
    final shown = reactions ?? msg.reactions;
    Widget pill(Key key, IconData icon, String text, VoidCallback tap) => Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], Tokens.space[0]),
      child: GestureDetector(
        key: key,
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.accent),
              const SizedBox(width: 6),
              Text(text, style: Tokens.caption.style.copyWith(color: p.accent)),
            ],
          ),
        ),
      ),
    );
    final extra = [
      if (onComments != null) pill(Key('comments-${msg.id}'), CupertinoIcons.chat_bubble_2, l.comments, onComments!),
      if (onThread != null && threadCount > 0) pill(Key('thread-${msg.id}'), CupertinoIcons.text_bubble, l.threadReplies(threadCount), onThread!),
    ];
    final comments = extra.isEmpty
        ? null
        : (extra.length == 1 ? extra.single : Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: extra));
    if (shown.isEmpty && comments == null) return bubble;
    if (shown.isEmpty) {
      return Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [bubble, comments!]);
    }
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (comments != null) comments,
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[0]),
          child: Wrap(
            spacing: Tokens.space[0],
            children: [
              for (final r in shown)
                GestureDetector(
                  key: Key('reaction-${r.key}'),
                  onTap: () => onReaction?.call(r.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.mine != null ? p.accent.withValues(alpha: 0.18) : p.incoming,
                      borderRadius: BorderRadius.circular(Tokens.capsule),
                    ),
                    child: Text(hideCounts ? r.key : '${r.key} ${r.count}', style: Tokens.caption.style.copyWith(color: r.mine != null ? p.accent : p.label)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Downloads and decrypts a photo on this device, then shows it.
class EncryptedImage extends StatefulWidget {
  const EncryptedImage({super.key, required this.roomId, required this.eventId});
  final String roomId;
  final String eventId;
  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Settings > Data > Auto-download (and power saving): otherwise wait
    // for a tap.
    if (bytes == null && AppScope.of(context).autoDownload) bytes = fetch();
  }

  Future<List<int>> fetch() => AppScope.read(context).backend.downloadFile(widget.roomId, widget.eventId);

  void load() {
    final f = fetch();
    setState(() => bytes = f);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    Widget box(Widget child) => Container(width: 220, height: 160, color: p.secondaryLabel.withValues(alpha: 0.15), alignment: Alignment.center, child: child);
    if (bytes == null) {
      return GestureDetector(
        key: const Key('tap-to-download'),
        onTap: load,
        child: box(
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.arrow_down, color: Color(0xFFFFFFFF), size: 22),
          ),
        ),
      );
    }
    return FutureBuilder<List<int>>(
      future: bytes,
      builder: (c, snap) {
        final data = snap.data;
        if (data == null || data.isEmpty) return box(const CupertinoActivityIndicator());
        final raw = Uint8List.fromList(data);
        final gif = raw.length > 4 && raw[0] == 0x47 && raw[1] == 0x49 && raw[2] == 0x46;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 340),
          child: gif && !s.gifsMove
              ? StillImage(raw)
              : Image.memory(raw, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (_, _, _) => box(const SizedBox())),
        );
      },
    );
  }
}

/// First frame only (a GIF that should not move).
class StillImage extends StatefulWidget {
  const StillImage(this.bytes, {super.key});
  final Uint8List bytes;
  @override
  State<StillImage> createState() => _StillImageState();
}

class _StillImageState extends State<StillImage> {
  ui.Image? frame;

  @override
  void initState() {
    super.initState();
    unawaited(() async {
      try {
        final codec = await ui.instantiateImageCodec(widget.bytes);
        final f = await codec.getNextFrame();
        codec.dispose();
        if (mounted) {
          setState(() => frame = f.image);
        } else {
          f.image.dispose();
        }
      } catch (_) {}
    }());
  }

  @override
  void dispose() {
    frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => frame == null
      ? const SizedBox(width: 220, height: 160)
      : RawImage(key: const Key('still-gif'), image: frame, fit: BoxFit.cover, width: frame!.width.toDouble(), height: frame!.height.toDouble());
}

/// "1일", "1주", "1달" (or hours / minutes for other values).
String timerLabel(BuildContext context, int secs) {
  final l = L.of(context);
  return switch (secs) {
    86400 => l.timer1d,
    604800 => l.timer1w,
    2592000 => l.timer1m,
    _ => secs >= 3600 ? '${secs ~/ 3600}h' : '${(secs / 60).ceil()}m',
  };
}

/// Full-screen view of a view-once photo. Closing it ends the viewing.
class ViewOncePage extends StatelessWidget {
  const ViewOncePage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      key: const Key('view-once-page'),
      backgroundColor: const Color(0xFF000000),
      navigationBar: GlassTopBar.nav(
        backgroundColor: const Color(0x00000000),
        border: null,
        leading: CupertinoButton(
          key: const Key('view-once-close'),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark, color: Color(0xFFFFFFFF)),
        ),
        middle: Text(l.viewOnceInfo, style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF))),
      ),
      child: CaptureBlock(
        child: Center(
          child: Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
        ),
      ),
    );
  }
}

/// File name -> media type (shared by the chat and profile screens).
class ChatPageMime {
  const ChatPageMime._();
  static String of(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}

/// Pick the chat to pass a message on to.
class ForwardPickPage extends StatefulWidget {
  const ForwardPickPage({super.key});

  @override
  State<ForwardPickPage> createState() => _ForwardPickPageState();
}

class _ForwardPickPageState extends State<ForwardPickPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final q = query.trim().toLowerCase();
    final chats = [
      for (final c in AppScope.of(context).chats)
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.forwardTo),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        backgroundColor: p.list,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
              child: CupertinoSearchTextField(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                key: const Key('forward-search'),
                placeholder: l.searchChats,
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, _) => Padding(
                  padding: EdgeInsets.only(left: 40 + Tokens.space[3] * 2),
                  child: Container(height: 1, color: p.separator),
                ),
                itemBuilder: (c, i) {
                  final chat = chats[i];
                  return GestureDetector(
                    key: Key('forward-to-${chat.roomId}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, chat.roomId),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                      child: Row(
                        children: [
                          Avatar(
                            name: chat.name,
                            size: 40,
                            squircle: !chat.isDirect,
                            userId: chat.isDirect ? chat.peer : null,
                            roomId: chat.roomId,
                            owner: chat.isChannel ? chat.peer : null,
                          ),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Text(
                              chat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.body.style.copyWith(color: p.label),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link card under a text (Telegram-style bar on the left). The picture was
/// encrypted by the sender's phone; this phone never visits the site until
/// the card is tapped.
class LinkCardView extends StatefulWidget {
  const LinkCardView({super.key, required this.card, required this.roomId, required this.eventId, required this.mine});
  final LinkCard card;
  final String roomId;
  final String eventId;
  final bool mine;

  @override
  State<LinkCardView> createState() => _LinkCardViewState();
}

class _LinkCardViewState extends State<LinkCardView> {
  Future<List<int>>? image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.card.hasImage) image ??= AppScope.of(context).backend.previewImage(widget.roomId, widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final c = widget.card;
    final line = widget.mine ? p.onAccent : p.accent;
    final fg = widget.mine ? p.onAccent : p.label;
    return GestureDetector(
      key: const Key('link-card'),
      onTap: () => openWebLink(context, c.url),
      child: Container(
        margin: EdgeInsets.only(top: Tokens.space[0], bottom: 2),
        padding: EdgeInsets.fromLTRB(Tokens.space[1], 3, Tokens.space[1], Tokens.space[0]),
        decoration: BoxDecoration(
          color: line.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radius[0]),
          border: Border(left: BorderSide(color: line, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.site != null)
              Text(
                c.site!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.caption.style.copyWith(color: line),
              ),
            Text(
              c.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
            ),
            if (c.description != null)
              Text(
                c.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Tokens.preview.style.copyWith(color: fg),
              ),
            if (image != null)
              FutureBuilder<List<int>>(
                future: image,
                builder: (context, snap) {
                  final bytes = snap.data;
                  if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: EdgeInsets.only(top: Tokens.space[0]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.radius[0]),
                      child: Image.memory(Uint8List.fromList(bytes), key: const Key('link-card-image'), fit: BoxFit.cover, width: double.infinity, height: 150),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

String voiceTime(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Play button, loudness bars (filled as it plays) and length.
class VoiceBubble extends StatefulWidget {
  const VoiceBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  VoicePlayer? player;
  bool playing = false;
  Duration at = Duration.zero;
  final subs = <StreamSubscription<Object>>[];

  @override
  void dispose() {
    for (final s in subs) {
      s.cancel();
    }
    player?.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (playing) {
      await player?.pause();
      return;
    }
    final b = AppScope.of(context).backend;
    if (player == null) {
      final pl = VoiceKit.player();
      player = pl;
      subs.add(pl.position.listen((d) => mounted ? setState(() => at = d) : null));
      subs.add(pl.playing.listen((v) => mounted ? setState(() => playing = v) : null));
    }
    final bytes = await b.downloadFile(widget.roomId, widget.msg.id);
    await player!.play(Uint8List.fromList(bytes), widget.msg.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final v = widget.msg.voice!;
    final mine = widget.msg.mine;
    final total = v.duration.inMilliseconds == 0 ? 1 : v.duration.inMilliseconds;
    final done = (at.inMilliseconds / total).clamp(0.0, 1.0);
    final bars = v.waveform.isEmpty ? List.filled(30, 200) : v.waveform;
    return Row(
      key: const Key('voice'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: const Key('voice-play'),
          onTap: toggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: mine ? p.onAccent : p.accent, shape: BoxShape.circle),
            child: Icon(playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: mine ? p.accent : p.onAccent, size: 20),
          ),
        ),
        SizedBox(width: Tokens.space[1]),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < bars.length; i++)
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.only(right: 1.5),
                      height: 3 + 21 * (bars[i] / 1024),
                      decoration: BoxDecoration(
                        color: i / bars.length <= done && (playing || at > Duration.zero) ? widget.fg : widget.fg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  voiceTime(playing || at > Duration.zero ? at : v.duration),
                  style: Tokens.bubbleMeta.style.copyWith(color: widget.fg.withValues(alpha: 0.7)),
                ),
                SizedBox(width: Tokens.space[2]),
                widget.meta,
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// How a chat hides its messages from people nearby: '' (not hidden),
/// 'dots' (대화방 가리기) or 'blur' (민감한 대화). Both are set per chat in
/// the chat's info page.
String veilOf(AppState s, String roomId) => s.on('veil_all') || s.on('veil_dots:$roomId', fallback: false)
    ? 'dots'
    : s.on('veil_blur:$roomId', fallback: false)
    ? 'blur'
    : '';

/// Hides a bubble's content until a finger rests on it.
class Veil extends StatefulWidget {
  const Veil({super.key, required this.mode, required this.ink, required this.child});
  final String mode;

  /// Colour of the dots (the bubble's text colour).
  final Color ink;
  final Widget child;
  @override
  State<Veil> createState() => _VeilState();
}

class _VeilState extends State<Veil> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    if (widget.mode.isEmpty) return widget.child;
    final hidden = widget.mode == 'dots'
        ? Stack(
            children: [
              Opacity(opacity: 0, child: widget.child),
              Positioned.fill(child: CustomPaint(painter: _Dots(widget.ink.withValues(alpha: 0.55)))),
            ],
          )
        : ClipRect(
            child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: widget.child),
          );
    return Listener(
      key: const Key('veil'),
      onPointerDown: (_) => setState(() => open = true),
      onPointerUp: (_) => setState(() => open = false),
      onPointerCancel: (_) => setState(() => open = false),
      child: open ? widget.child : hidden,
    );
  }
}

class _Dots extends CustomPainter {
  _Dots(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    var seed = 7;
    double next() => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) % 1000) / 1000;
    final n = (size.width * size.height / 40).clamp(8, 600).toInt();
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(Offset(next() * size.width, next() * size.height), 0.6 + next() * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(_Dots old) => old.color != color;
}

/// Messages set to go later in one chat: send now or delete.
class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = s.scheduled.where((m) => m['room'] == roomId).toList()..sort((a, b) => (a['at'] as int).compareTo(b['at'] as int));
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).languageCode).add_jm();
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.sendLater, back: true, tint: p.background),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            footer: sectionFooter(context, l.scheduledInfo),
            children: [
              for (final m in mine)
                CupertinoListTile(
                  key: Key('sched-${m['id']}'),
                  title: Text(m['text'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(fmt.format(DateTime.fromMillisecondsSinceEpoch(m['at'] as int)), style: Tokens.caption.style),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        key: Key('sched-now-${m['id']}'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () async {
                          final left = s.scheduled.where((x) => x['id'] != m['id']).toList();
                          await s.setScheduled([
                            ...left,
                            {...m, 'at': 0},
                          ]);
                          await s.sendDue();
                        },
                        child: Icon(CupertinoIcons.paperplane_fill, color: p.accent),
                      ),
                      CupertinoButton(
                        key: Key('sched-del-${m['id']}'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () => s.setScheduled(s.scheduled.where((x) => x['id'] != m['id']).toList()),
                        child: const Icon(CupertinoIcons.trash, color: Palette.tileRed),
                      ),
                    ],
                  ),
                ),
              if (mine.isEmpty) CupertinoListTile(title: Text(l.nothingShared)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen field for a link address (no pop-up text boxes).
class LinkEditPage extends StatefulWidget {
  const LinkEditPage({super.key});
  @override
  State<LinkEditPage> createState() => _LinkEditPageState();
}

class _LinkEditPageState extends State<LinkEditPage> {
  final url = TextEditingController(text: 'https://');

  void done() {
    final u = url.text.trim();
    final ok = Uri.tryParse(u)?.hasAuthority == true && (u.startsWith('https://') || u.startsWith('http://'));
    if (ok) Navigator.pop(context, u);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.fmtLink,
        back: true,
        tint: p.background,
        trailing: [GlassPill(key: const Key('link-done'), text: l.done, onTap: done)],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                child: CupertinoTextField(
                  key: const Key('link-url'),
                  controller: url,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: null,
                  onSubmitted: (_) => done(),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One to three emoji alone in a message are shown big, without a bubble
/// (Settings > Stickers and emoji > Big emoji).
bool isBigEmoji(String text) {
  final s = text.trim();
  if (s.isEmpty || s.characters.length > 3) return false;
  return RegExp(
    r'^(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]|\s)+$',
    unicode: true,
  ).hasMatch(s);
}

class BigEmoji extends StatelessWidget {
  const BigEmoji(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: 48, height: 1.15, fontFamilyFallback: Tokens.emojiFallback));
}

/// Round choice mark on the left of a message in select mode (24 pt,
/// iOS edit-mode circle): thin grey ring, or accent fill with a white check.
class SelectCircle extends StatelessWidget {
  const SelectCircle({super.key, required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? p.accent : const Color(0x00000000),
          border: on ? null : Border.all(color: p.secondaryLabel, width: 1.5),
        ),
        child: on ? Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIconSmall - 2, color: p.onAccent) : null,
      ),
    );
  }
}

/// "목록으로 보기": the search results as a list, newest first.
class SearchHitsPage extends StatelessWidget {
  const SearchHitsPage({super.key, required this.hits, required this.title});
  final List<Msg> hits;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(back: true, title: l.searchFound),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(top: Tokens.space[2]),
          children: [
            IosSection(
              hasLeading: false,
              children: [
                for (final (i, m) in hits.indexed)
                  GestureDetector(
                    key: Key('hit-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, m.id),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
                      child: Row(
                        children: [
                          Avatar(name: m.mine ? l.you : displayId(m.sender), size: 40, userId: m.mine ? null : m.sender),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.mine ? l.you : displayId(m.sender),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Text(shortTime(context, m.time), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                  ],
                                ),
                                SizedBox(height: Tokens.nameToSub),
                                Text(
                                  previewText(context, kind: m.kind, body: m.body, caption: m.caption),
                                  maxLines: 2,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live loudness as a row of dots (locked voice recording).
class _LevelDots extends StatelessWidget {
  const _LevelDots({required this.levels, required this.color});
  final List<double> levels;
  final Color color;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final n = (box.maxWidth / 6).floor().clamp(0, 60);
      final shown = levels.length > n ? levels.sublist(levels.length - n) : levels;
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: 3,
              height: 3 + (i >= n - shown.length ? shown[i - (n - shown.length)] * 16 : 0),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      );
    },
  );
}

/// "스레드로 답장": the first message, its replies, and a box to answer.
class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.roomId, required this.root, required this.chatTitle});
  final String roomId;
  final Msg root;
  final String chatTitle;
  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final input = TextEditingController();
  List<Msg> replies = const [];
  Timer? poll;
  bool group = false;

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(seconds: 3), (_) => load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final row = AppScope.of(context).chats.where((c) => c.roomId == widget.roomId);
    group = row.isNotEmpty && !row.first.isDirect;
    load();
  }

  @override
  void dispose() {
    poll?.cancel();
    input.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final all = await AppScope.of(context).backend.timeline(widget.roomId, limit: 500);
    if (!mounted) return;
    setState(() => replies = all.where((x) => x.threadRoot == widget.root.id).toList());
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await AppScope.of(context).backend.replyInThread(widget.roomId, widget.root.id, text);
    await load();
  }

  Widget bubble(Msg m) => Padding(
    padding: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
    child: Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.chatTitle, senderName: group && !m.mine ? displayId(m.sender) : null),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.threadTitle), backgroundColor: p.chatBackground),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('thread-list'),
                // Same side gap as the chat itself.
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                children: [
                  bubble(widget.root),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                    child: Center(
                      child: Text(
                        replies.isEmpty ? l.threadEmpty : l.threadReplies(replies.length),
                        key: const Key('thread-count'),
                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                      ),
                    ),
                  ),
                  for (final m in replies) bubble(m),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: LiquidGlass(
                      radius: Tokens.closeButton / 2,
                      child: CupertinoTextField.borderless(
                        key: const Key('thread-input'),
                        controller: input,
                        placeholder: l.threadPlaceholder,
                        placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                        style: Tokens.body.style.copyWith(color: p.label),
                        minLines: 1,
                        maxLines: 5,
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] - 1),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  AccentCircle(key: const Key('thread-send'), icon: CupertinoIcons.arrow_up, onTap: send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings > Chats > Find plans: a tapped date or time in a message offers
/// a reminder (an hour before, or at the time). Kept on this phone only.
Future<void> planReminder(BuildContext context, String roomId, String chat, Msg m, DateTime at) async {
  final l = L.of(context);
  final fmt = DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag()).add_jm();
  final early = at.subtract(const Duration(hours: 1));
  final pick = await showCupertinoModalPopup<DateTime>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.planFound(fmt.format(at))),
      actions: [
        if (early.isAfter(DateTime.now()))
          CupertinoActionSheetAction(key: const Key('plan-early'), onPressed: () => Navigator.pop(c, early), child: Text(l.planHourBefore)),
        CupertinoActionSheetAction(key: const Key('plan-at'), onPressed: () => Navigator.pop(c, at), child: Text(l.planAtTime)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  await addReminder(AppScope.read(context), Reminder(roomId: roomId, msgId: m.id, chat: chat, at: pick));
  if (context.mounted) showStoryToast(context, l.remindSet(fmt.format(pick)));
}
