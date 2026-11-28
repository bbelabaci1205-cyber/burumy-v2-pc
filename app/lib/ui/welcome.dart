// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 환영 인사 (Eric 2026-11-27, after Telegram tip 575): the bubble a new
// member sees right after joining (only them), and the admin's editor — a
// little chat screen with the preview bubble, formatting and one photo or
// video. Everything travels end-to-end encrypted (see core/room_texts.dart).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

import '../brand/mark.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/room_texts.dart';
import '../core/strip_meta.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show ChatPageMime;
import 'common.dart';
import 'formatting.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'media_bubbles.dart';
import 'stories.dart' show showStoryToast;
import 'wallpaper.dart';

/// "그룹에 들어왔어요" and the welcome bubble from the room, which only I
/// see. [preview]: the admin's editor (no join line, no time).
class WelcomeBubble extends StatelessWidget {
  const WelcomeBubble({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.texts,
    this.channel = false,
    this.preview = false,
    this.localMedia,
    this.onHold,
  });
  final String roomId;
  final String roomName;
  final RoomTexts texts;
  final bool channel;
  final bool preview;

  /// A photo/video picked in the editor and not uploaded yet.
  final (List<int>, String)? localMedia;
  final VoidCallback? onHold;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final media = localMedia != null || texts.media != null;
    final mime = localMedia?.$2 ?? texts.media?['mime'] as String? ?? '';
    final bubble = Container(
      key: Key(preview ? 'welcome-preview' : 'welcome-bubble'),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: Tokens.space[0]),
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1] - 2, Tokens.space[2], Tokens.space[1]),
      decoration: BoxDecoration(
        color: p.incoming,
        borderRadius: BorderRadius.circular(double.tryParse(AppScope.of(context).pref('bubble_radius', '')) ?? Tokens.radius[2] + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            roomName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.eye, size: 12, color: p.secondaryLabel),
              const SizedBox(width: 3),
              Text(
                l.welcomeOnlyYou,
                key: const Key('welcome-only-you'),
                style: Tokens.bubbleMeta.style.copyWith(color: p.secondaryLabel),
              ),
            ],
          ),
          if (media) ...[SizedBox(height: Tokens.space[1]), _WelcomeMedia(roomId: roomId, texts: texts, local: localMedia, video: mime.startsWith('video/'))],
          if (texts.welcome.isNotEmpty) ...[
            SizedBox(height: Tokens.space[0]),
            FormattedText(
              texts.welcome,
              style: Tokens.body.style.copyWith(color: p.label),
              linkColor: p.accent,
              quoteColor: p.accent,
            ),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!preview)
          Padding(
            padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
            child: Center(
              child: Container(
                key: const Key('joined-line'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(channel ? l.joinedChannelLine : l.joinedGroupLine, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The room speaks (its photo), like Telegram's welcome bubble.
            Padding(
              padding: EdgeInsets.only(left: Tokens.space[0], bottom: 2),
              child: Avatar(name: roomName, size: 30, squircle: true, channel: channel, roomId: roomId),
            ),
            Flexible(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(onLongPress: onHold, child: bubble),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WelcomeMedia extends StatefulWidget {
  const _WelcomeMedia({required this.roomId, required this.texts, required this.local, required this.video});
  final String roomId;
  final RoomTexts texts;
  final (List<int>, String)? local;
  final bool video;

  @override
  State<_WelcomeMedia> createState() => _WelcomeMediaState();
}

class _WelcomeMediaState extends State<_WelcomeMedia> {
  Future<List<int>>? photo;

  Future<List<int>> load() async {
    final local = widget.local;
    if (local != null) return local.$1;
    return RoomTexts.mediaBytes(AppScope.read(context).backend, widget.texts.media!);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.video) photo ??= load();
  }

  @override
  void didUpdateWidget(_WelcomeMedia old) {
    super.didUpdateWidget(old);
    if (old.local != widget.local || old.texts.media?['file'] != widget.texts.media?['file']) {
      photo = widget.video ? null : load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    if (widget.video) {
      final mime = widget.local?.$2 ?? widget.texts.media?['mime'] as String? ?? 'video/mp4';
      return VideoBubble(
        key: const Key('welcome-video'),
        name: widget.texts.media?['name'] as String? ?? '',
        meta: const SizedBox.shrink(),
        onOpen: () => Navigator.of(context, rootNavigator: true).push(
          IosPageRoute(
            fullscreenDialog: true,
            builder: (_) => VideoPlayerPage(mime: mime, load: load),
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(Tokens.radius[2]),
      child: FutureBuilder<List<int>>(
        future: photo,
        builder: (context, snap) {
          final b = snap.data;
          if (b == null) {
            return Container(
              width: 240,
              height: 160,
              color: p.secondaryLabel.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: snap.hasError ? Icon(CupertinoIcons.photo, color: p.secondaryLabel) : const CupertinoActivityIndicator(),
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
            child: Image.memory(Uint8List.fromList(b), key: const Key('welcome-photo'), fit: BoxFit.cover, gaplessPlayback: true),
          );
        },
      ),
    );
  }
}

/// 운영 도구 > 환영 인사: write it like a message and see what new members
/// will see (Telegram's editor, with our glass bar, formatting and one
/// photo or video). ✓ saves (encrypted), X leaves without saving.
class WelcomeEditorPage extends StatefulWidget {
  const WelcomeEditorPage({super.key, required this.roomId, required this.roomName, this.channel = false});
  final String roomId;
  final String roomName;
  final bool channel;

  @override
  State<WelcomeEditorPage> createState() => _WelcomeEditorPageState();
}

class _WelcomeEditorPageState extends State<WelcomeEditorPage> {
  final input = TextEditingController();
  final focus = FocusNode();

  /// What the preview shows (saved or just "sent" from the field).
  RoomTexts draft = const RoomTexts();

  /// A new photo/video (bytes, mime, name), uploaded on ✓.
  (List<int>, String, String)? newMedia;
  bool mediaRemoved = false;
  bool loaded = false;
  bool busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    loaded = true;
    final s = AppScope.read(context);
    s.backend.roomConfig(widget.roomId).then((cfg) {
      if (!mounted) return;
      final t = RoomTexts.of(s, widget.roomId, cfg);
      setState(() => draft = t);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    input.dispose();
    focus.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get shownMedia => mediaRemoved ? null : draft.media;
  bool get hasMedia => newMedia != null || shownMedia != null;
  RoomTexts get shown => RoomTexts(welcome: draft.welcome, rules: draft.rules, media: shownMedia, at: draft.at);
  bool get empty => draft.welcome.isEmpty && !hasMedia;

  /// "Send" from the field: the words go into the preview bubble.
  void put() {
    final t = input.text.trim();
    if (t.isEmpty) return;
    setState(() {
      draft = RoomTexts(welcome: t.length > 500 ? t.substring(0, 500) : t, rules: draft.rules, media: draft.media, at: draft.at);
      input.clear();
    });
  }

  Future<void> pick() async {
    final l = L.of(context);
    final x = await ImagePicker().pickMedia(imageQuality: 85, maxWidth: 1600);
    if (x == null || !mounted) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.length > RoomTexts.maxMedia) {
      showStoryToast(context, l.welcomeMediaTooBig);
      return;
    }
    var mime = x.mimeType ?? ChatPageMime.of(x.name);
    if (mime == 'application/octet-stream') mime = 'image/jpeg';
    // Photos lose their place and camera details before they leave the phone.
    final clean = mime.startsWith('image/') ? StripMeta.photo(bytes, mime) : bytes;
    setState(() {
      newMedia = (clean, mime, x.name);
      mediaRemoved = false;
    });
  }

  Future<void> hold() async {
    final l = L.of(context);
    final pickAction = await showCupertinoModalPopup<String>(
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (draft.welcome.isNotEmpty)
            CupertinoActionSheetAction(key: const Key('welcome-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.edit)),
          if (hasMedia)
            CupertinoActionSheetAction(key: const Key('welcome-media-off'), onPressed: () => Navigator.pop(c, 'media'), child: Text(l.welcomeRemoveMedia)),
          CupertinoActionSheetAction(
            key: const Key('welcome-delete'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(l.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pickAction == null) return;
    setState(() {
      switch (pickAction) {
        case 'edit':
          input.text = draft.welcome;
          input.selection = TextSelection.collapsed(offset: input.text.length);
          draft = RoomTexts(rules: draft.rules, media: draft.media, at: draft.at);
          focus.requestFocus();
        case 'media':
          newMedia = null;
          mediaRemoved = true;
        default:
          draft = RoomTexts(rules: draft.rules, at: draft.at);
          newMedia = null;
          mediaRemoved = true;
      }
    });
  }

  Future<void> save() async {
    if (busy) return;
    put();
    final s = AppScope.read(context);
    final l = L.of(context);
    setState(() => busy = true);
    try {
      Map<String, dynamic>? media;
      final nm = newMedia;
      if (nm != null) {
        media = await RoomTexts.uploadMedia(s.backend, nm.$1, nm.$2, nm.$3);
      } else if (mediaRemoved) {
        media = {};
      }
      await RoomTexts.save(s, widget.roomId, welcome: draft.welcome, media: media);
      await s.logMod(widget.roomId, 'setting', 'welcome');
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showStoryToast(context, l.saveFailed);
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final nm = newMedia;
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: LiquidGlass(
          radius: Tokens.capsule,
          child: Container(
            height: Tokens.closeButton,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            alignment: Alignment.center,
            child: Text(l.welcomeMessage, style: Tokens.navTitle.style),
          ),
        ),
        trailing: GlassDone(key: const Key('welcome-save'), onTap: busy ? null : save),
      ),
      child: ChatWallpaper(
        roomId: widget.roomId,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: empty && nm == null
                    ? Center(
                        key: const Key('welcome-empty'),
                        child: Padding(
                          padding: EdgeInsets.all(Tokens.space[4]),
                          child: LiquidGlass(
                            radius: Tokens.radius[3],
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[4], Tokens.space[4], Tokens.space[4]),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset('assets/brand/symbol_green.png', width: 96, color: p.accent, colorBlendMode: BlendMode.srcIn),
                                  SizedBox(height: Tokens.space[3]),
                                  Text(l.welcomeEmptyTitle, style: Tokens.cardTitle.style.copyWith(color: p.label)),
                                  SizedBox(height: Tokens.space[1]),
                                  Text(
                                    l.welcomeEmptyBody,
                                    textAlign: TextAlign.center,
                                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        reverse: true,
                        padding: EdgeInsets.all(Tokens.space[1]),
                        children: [
                          WelcomeBubble(
                            roomId: widget.roomId,
                            roomName: widget.roomName,
                            channel: widget.channel,
                            texts: shown,
                            preview: true,
                            localMedia: nm == null ? null : (nm.$1, nm.$2),
                            onHold: hold,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                            child: Center(
                              child: Container(
                                key: const Key('welcome-editor-hint'),
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                                decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                                child: Text(
                                  '${l.welcomeEditorHint}\n🔒 ${l.textsEncrypted}',
                                  textAlign: TextAlign.center,
                                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], Tokens.space[1]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GlassCircle(
                      key: const Key('welcome-attach'),
                      size: Tokens.closeButton,
                      onTap: pick,
                      child: Icon(CupertinoIcons.plus, color: p.label, size: 22),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Expanded(
                      child: CupertinoTextField(
                        key: const Key('welcome-input'),
                        controller: input,
                        focusNode: focus,
                        placeholder: l.welcomeAddHint,
                        minLines: 1,
                        maxLines: 6,
                        maxLength: 500,
                        contextMenuBuilder: (context, st) => formatMenu(context, st, input),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: (Tokens.closeButton - Tokens.body.lineHeight) / 2),
                        style: Tokens.body.style.copyWith(color: p.label),
                        decoration: BoxDecoration(
                          color: p.card.withValues(alpha: p.dark ? 0.55 : 0.75),
                          borderRadius: BorderRadius.circular(Tokens.closeButton / 2),
                        ),
                      ).glassEdge(radius: Tokens.closeButton / 2),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    GestureDetector(
                      key: const Key('welcome-put'),
                      onTap: put,
                      child: Container(
                        width: Tokens.closeButton,
                        height: Tokens.closeButton,
                        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: BurumyMark(color: p.onAccent, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A new member deletes the welcome (this phone only).
Future<void> deleteWelcome(BuildContext context, String roomId) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final ok = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (c) => IosActionSheet(
      actions: [
        CupertinoActionSheetAction(key: const Key('welcome-delete'), isDestructiveAction: true, onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (ok == true) await s.setOn('welcomed:$roomId', true);
}

/// Where the welcome goes in my timeline: right after I joined.
Msg welcomeMsg(DateTime at) => Msg(id: '_welcome', sender: '', body: '', time: at, mine: false, kind: 'welcome');

/// [shown] (oldest first) with the welcome placed at my join time.
List<Msg> withWelcome(List<Msg> shown, DateTime? joined) {
  if (joined == null) return [...shown, welcomeMsg(shown.isEmpty ? DateTime.now() : shown.last.time)];
  final i = shown.indexWhere((m) => m.time.isAfter(joined));
  final out = [...shown];
  out.insert(i < 0 ? out.length : i, welcomeMsg(joined));
  return out;
}
