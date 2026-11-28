// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The "+" sheet in a chat: a floating glass sheet with a picture grid, files,
// and tools on a sideways-scrolling tab bar (iOS 26 sheet, rulebook ch. 4-1).
import 'ios_route.dart';
import 'story_camera.dart' show StoryCameraPage;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../brand/mark.dart';
import '../core/backend.dart' show Msg;
import '../core/live_photo.dart';
import '../core/app_state.dart';
import '../core/features.dart';
import '../core/phone.dart';
import '../core/photo_size.dart';
import '../core/video_edit.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'formatting.dart' show formatMenu;
import 'album.dart' show SpoilerCover, albumMosaic;
import 'media_editor.dart';
import 'video_editor.dart';
import 'stories.dart' show showStoryToast;
import 'ios.dart';
import 'light_video.dart';
import 'glass.dart';
import 'live_photo.dart';
import 'message_sheets.dart' show SheetDrag;
import 'wide.dart';

/// A picked photo, video or file, kept on this phone until sent.
class PickedFile {
  const PickedFile(
    this.name,
    this.bytes, {
    this.phoneId,
    this.asFile = false,
    this.clip,
    this.style = LiveStyle.live,
    this.muted = false,
    this.isEdited = false,
    this.spoiler = false,
    this.video = VideoEdit.none,
    this.length,
  });

  /// A photo as chosen on the phone: an Android Motion Photo is split into
  /// its still and its clip here; an iPhone Live Photo brings [clip] along.
  factory PickedFile.fromPhone(String name, Uint8List bytes, {String? phoneId, Uint8List? clip, Duration? length}) {
    if (clip == null && const ['jpg', 'jpeg'].contains(name.split('.').last.toLowerCase())) {
      final parts = LivePhoto.splitMotion(bytes);
      if (parts != null) return PickedFile(name, parts.still, phoneId: phoneId, clip: parts.clip);
    }
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final mp4 = const ['mp4', 'mov', 'm4v'].contains(ext);
    return PickedFile(
      name,
      bytes,
      phoneId: phoneId,
      clip: clip != null && clip.length <= liveMaxBytes ? clip : null,
      length: length ?? (mp4 ? Mp4Meta.duration(bytes) : null),
    );
  }
  final String name;
  final Uint8List bytes;

  /// 움직이는 사진: the short clip (MP4) and how it plays; null = a plain photo.
  final Uint8List? clip;
  final LiveStyle style;
  bool get isLive => clip != null && isImage;

  /// A video's length (read from the file; null = unknown).
  final Duration? length;

  PickedFile _copy({
    String? name,
    Uint8List? bytes,
    bool? asFile,
    Uint8List? clip,
    bool dropClip = false,
    LiveStyle? style,
    bool? muted,
    bool? isEdited,
    bool? spoiler,
    VideoEdit? video,
  }) => PickedFile(
    name ?? this.name,
    bytes ?? this.bytes,
    phoneId: phoneId,
    asFile: asFile ?? this.asFile,
    clip: dropClip ? null : (clip ?? this.clip),
    style: style ?? this.style,
    muted: muted ?? this.muted,
    isEdited: isEdited ?? this.isEdited,
    spoiler: spoiler ?? this.spoiler,
    video: video ?? this.video,
    length: length,
  );

  PickedFile withStyle(LiveStyle s) => _copy(style: s);

  /// 소리 끄기 on a video (Telegram tip 77): sent as a GIF (silent loop).
  final bool muted;
  PickedFile withMuted(bool m) => _copy(muted: m);

  /// 가리기 for this one picture (Telegram tip 369): it arrives covered with
  /// moving dust until tapped.
  final bool spoiler;
  PickedFile withSpoiler(bool on) => _copy(spoiler: on);

  /// 자르기·회전 chosen for this video (tip 56); made when it is sent.
  final VideoEdit video;
  PickedFile withVideo(VideoEdit e) => _copy(video: e);

  /// After the photo editor: a new PNG (a 움직이는 사진 becomes a still).
  PickedFile edited(Uint8List png) => _copy(
    name: '${name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name}.png',
    bytes: png,
    dropClip: true,
    isEdited: true,
    style: LiveStyle.live,
  );

  /// Changed in the photo editor (the grid shows the new picture).
  final bool isEdited;

  /// 파일로 보내기 from the ⋯ menu: the original, as a file.
  PickedFile asOriginal() => PickedFile(name, bytes, phoneId: phoneId, asFile: true);

  /// Chosen in the 파일 tab: sent as a file (original quality), even photos.
  final bool asFile;

  /// Set when it was chosen from the live photo grid (to un-choose it).
  final String? phoneId;

  String get _ext => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isImage => const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'heif', 'bmp'].contains(_ext);
  bool get isVideo => const ['mp4', 'mov', 'm4v', 'webm', '3gp', 'mkv'].contains(_ext);

  /// A photo or video that goes into the chat as a picture (not a file).
  bool get isMedia => !asFile && (isImage || isVideo);
}

/// What the sheet hands back: files to send, or a tool to open.
class AttachResult {
  const AttachResult.send(this.files, {this.caption = '', this.once = false, this.together = true, this.hd = false, this.captionAbove = false, this.video})
    : tool = null,
      made = false;
  const AttachResult.tool(this.tool)
    : files = const [],
      caption = '',
      once = false,
      made = false,
      together = true,
      hd = false,
      captionAbove = false,
      video = null;

  /// A tool page shown inside the card already sent something.
  const AttachResult.made()
    : files = const [],
      caption = '',
      once = false,
      tool = null,
      made = true,
      together = true,
      hd = false,
      captionAbove = false,
      video = null;

  /// 설명 위로 (Telegram tip 452): the words show above the photo or video.
  final bool captionAbove;

  /// 묶어서 보내기 (one album bubble) or 따로 보내기 (Telegram tip 76).
  final bool together;

  /// HD (Telegram tip 529): photos go at up to 2560 px instead of the
  /// 표준 1280 px. 가리기 is per picture ([PickedFile.spoiler]).
  final bool hd;

  /// 영상 화질 (tip 114) + 가벼운 복사본 (479 · 480); null = the chat's default.
  final VideoSendPick? video;
  final bool made;
  final List<PickedFile> files;
  final String caption;
  final bool once;

  /// "poll", "checklist", "bubble", ...
  final String? tool;
}

typedef Picker = Future<List<PickedFile>> Function(String source);

/// Opens the sheet. [caption] starts with what was typed in the composer.
Future<AttachResult?> showAttachSheet(
  BuildContext context, {
  required String caption,
  required bool isGroup,
  required bool isChannel,
  List<Msg> sentFiles = const [],
  Widget? Function(String tool)? toolPage,
  int members = 0,
}) => showCupertinoModalPopup<AttachResult>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (_) => AttachSheet(caption: caption, isGroup: isGroup, isChannel: isChannel, sentFiles: sentFiles, toolPage: toolPage, members: members),
);

class AttachSheet extends StatefulWidget {
  const AttachSheet({
    super.key,
    required this.caption,
    required this.isGroup,
    required this.isChannel,
    this.sentFiles = const [],
    this.toolPage,
    this.members = 0,
  });

  /// People in the group / channel (light copies by default at 100+).
  final int members;
  final String caption;

  /// Tools that open right inside the card, like Telegram (Eric 2026-11-26
  /// "하단카드에서 다할수있게"): the page for a tool, or null to leave the
  /// sheet and let the chat handle it.
  final Widget? Function(String tool)? toolPage;

  /// Files I sent in this chat, newest first ("최근에 보낸 파일": tap sends again).
  final List<Msg> sentFiles;
  final bool isGroup;
  final bool isChannel;

  /// Tests replace the phone's picker ("camera", "library" or "file").
  static Picker? debugPicker;

  @override
  State<AttachSheet> createState() => _AttachSheetState();
}

class _AttachSheetState extends State<AttachSheet> {
  String tab = 'gallery';

  /// Room under the lists for the floating tab capsule.
  double get barRoom => picked.isEmpty ? FloatingTabBar.height + Tokens.space[2] : 0;

  /// The tool page shown in the card (its own X / title / action bar).
  Widget? toolBody;
  final picked = <PickedFile>[];
  late final caption = TextEditingController(text: widget.caption);
  bool once = false;
  bool together = true;

  /// 설명 위로 (tip 452), from the ⋯ menu.
  bool captionAbove = false;

  /// HD chosen in this sheet (null = the Settings default).
  bool? hdPick;

  /// 영상 화질 chosen in this sheet (null = 원본 + the chat's light rule).
  VideoSendPick? videoPick;

  /// A video that 화질 changes (not GIF / 소리 끄기, not 파일로, not once).
  PickedFile? get firstVideo => picked.where((f) => !f.asFile && f.isVideo && !f.muted).firstOrNull;

  /// Light copies only make sense where many people watch (card A).
  bool get lightAllowed => widget.isChannel || widget.isGroup;

  VideoSendPick defaultVideoPick() {
    final v = firstVideo;
    return VideoSendPick(
      light: v != null && lightAllowed && wantsLight(channel: widget.isChannel, members: widget.members, length: v.length),
    );
  }

  Future<void> pickVideoQuality() async {
    final v = firstVideo;
    if (v == null) return;
    final got = await showVideoQualitySheet(context, bytes: v.bytes, name: v.name, now: videoPick ?? defaultVideoPick(), lightAllowed: lightAllowed);
    if (got != null && mounted) setState(() => videoPick = got);
  }

  bool get hd => hdPick ?? AppScope.read(context).on('photo_hd');

  /// 미리보기 (tips 75 + 323): the pictures as the bubble will look, to
  /// drag into another order, cover or edit one by one.
  bool preview = false;

  /// Hovered square while dragging in the preview (index into [picked]).
  int? dropOn;

  /// First pictures of chosen videos (for the preview squares).
  final videoThumbs = <Uint8List, Uint8List?>{};

  /// Gallery album shown in the grid (null = 최근 항목).
  PhoneAlbum? album;
  List<PhoneAlbum>? albums;

  /// The phone's newest photos and videos (null: not allowed / web).
  List<PhoneMedia>? recent;
  final loading = <String>{};

  @override
  void initState() {
    super.initState();
    Phone.recent().then((r) {
      if (mounted) setState(() => recent = r);
    });
  }

  /// Tap on a live grid photo: choose it (loads the whole file) or un-choose.
  Future<void> toggle(PhoneMedia m) async {
    final at = picked.indexWhere((f) => f.phoneId == m.id);
    if (at >= 0) {
      return setState(() {
        picked.removeAt(at);
        if (!canOnce) once = false;
      });
    }
    if (picked.length >= 20 || loading.contains(m.id)) return;
    setState(() => loading.add(m.id));
    final got = await Phone.loadFile(m.id);
    if (!mounted) return;
    setState(() {
      loading.remove(m.id);
      if (got != null && picked.length < 20) picked.add(PickedFile.fromPhone(got.name, got.bytes, phoneId: m.id, clip: got.clip, length: m.duration));
      if (!canOnce) once = false;
    });
  }

  /// Speaker capsule on a chosen video: tap to send it without sound (GIF).
  Widget muteControl(int i) {
    final muted = picked[i].muted;
    return GestureDetector(
      key: Key('attach-mute-$i'),
      onTap: () => toggleMute(i),
      child: Container(
        height: Tokens.liveBadge,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(color: const Color(0x80000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(muted ? CupertinoIcons.speaker_slash_fill : CupertinoIcons.speaker_2_fill, size: 13, color: const Color(0xFFFFFFFF)),
            if (muted) ...[const SizedBox(width: 4), Text('GIF', style: Tokens.liveText.style.copyWith(color: const Color(0xFFFFFFFF)))],
          ],
        ),
      ),
    );
  }

  /// LIVE capsule on a chosen 움직이는 사진: pick 라이브 / 반복 / 바운스 / 끄기.
  Widget liveControl(int i) => Builder(
    builder: (c) => LiveBadge(
      key: Key('attach-live-style-$i'),
      style: picked[i].style,
      chevron: true,
      onTap: () async {
        final s = await showLiveStyleMenu(c, picked[i].style);
        if (s != null && mounted && i < picked.length) setState(() => picked[i] = picked[i].withStyle(s));
      },
    ),
  );

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  bool get canOnce => !widget.isChannel && picked.isNotEmpty && picked.every((f) => f.isImage || f.isVideo);

  Future<void> pick(String source, {bool asFile = false}) async {
    var got = await (AttachSheet.debugPicker ?? _phonePicker)(source);
    if (!mounted || got.isEmpty) return;
    // 파일 tab: original file as it is (no clip split, no LIVE).
    if (asFile) got = [for (final f in got) PickedFile(f.name, f.bytes, asFile: true)];
    setState(() {
      picked.addAll(got.take(20 - picked.length));
      if (!canOnce) once = false;
    });
  }

  /// The in-app camera (story camera, 영상 first, 60 s at most); what it
  /// takes joins the picked files, under the caption box as usual.
  Future<void> shoot() async {
    final got = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<(String, Uint8List)>(IosPageRoute(fullscreenDialog: true, builder: (_) => const StoryCameraPage(capture: true, video: true)));
    if (!mounted || got == null || picked.length >= 20) return;
    setState(() {
      picked.add(PickedFile.fromPhone(got.$1, got.$2));
      if (!canOnce) once = false;
    });
  }

  static Future<List<PickedFile>> _phonePicker(String source) async {
    Future<PickedFile> read(XFile x) async => PickedFile.fromPhone(x.name, await x.readAsBytes());
    switch (source) {
      case 'camera':
        final x = await ImagePicker().pickImage(source: ImageSource.camera);
        return x == null ? const [] : [await read(x)];
      case 'library':
        final xs = await ImagePicker().pickMultipleMedia(limit: 20);
        return [for (final x in xs) await read(x)];
      case 'audio':
        final xs = await openFiles(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'audio',
              extensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'opus', 'flac'],
              mimeTypes: ['audio/*'],
              uniformTypeIdentifiers: ['public.audio'],
            ),
          ],
        );
        return [for (final x in xs) await read(x)];
      default:
        final xs = await openFiles();
        return [for (final x in xs) await read(x)];
    }
  }

  void send() => Navigator.pop(
    context,
    AttachResult.send(
      [for (final f in picked) once ? f.withSpoiler(false) : f],
      caption: once ? '' : caption.text,
      once: once && canOnce,
      together: together,
      hd: hd,
      video: once || firstVideo == null ? null : (videoPick ?? defaultVideoPick()),
      captionAbove: captionAbove && !once,
    ),
  );

  int get mediaCount => picked.where((f) => !f.asFile && (f.isImage || f.isVideo)).length;

  /// Tap on a chosen photo: the photo editor (draw, words, auto, filters).
  Future<void> edit(int i) async {
    final f = picked[i];
    if (!f.isImage || f.asFile) return;
    final png = await editChatPhoto(context, f.bytes);
    if (png != null && mounted && i < picked.length) setState(() => picked[i] = f.edited(png));
  }

  /// Speaker on a chosen video: off = it goes as a GIF.
  void toggleMute(int i) {
    final l = L.of(context);
    final m = !picked[i].muted;
    setState(() => picked[i] = picked[i].withMuted(m));
    showStoryToast(context, m ? l.videoMutedToast : l.videoSoundToast);
  }

  /// ⋯ (top right, Telegram): together / separately, 가리기, 파일로 보내기.
  Future<void> moreMenu() async {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget tick(bool on, String text) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text),
        if (on) ...[SizedBox(width: Tokens.space[1]), Icon(CupertinoIcons.checkmark_alt, size: 18, color: p.accent)],
      ],
    );
    final media = mediaCount;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (media > 1) ...[
            CupertinoActionSheetAction(key: const Key('attach-together'), onPressed: () => Navigator.pop(c, 'together'), child: tick(together, l.sendTogether)),
            CupertinoActionSheetAction(
              key: const Key('attach-separately'),
              onPressed: () => Navigator.pop(c, 'apart'),
              child: tick(!together, l.sendSeparately),
            ),
          ],
          if (media > 0 && !once)
            CupertinoActionSheetAction(key: const Key('attach-spoiler'), onPressed: () => Navigator.pop(c, 'spoiler'), child: tick(allCovered, l.sendSpoiler)),
          if (media > 0 && !once)
            CupertinoActionSheetAction(
              key: const Key('attach-caption-above'),
              onPressed: () => Navigator.pop(c, 'above'),
              child: tick(captionAbove, l.captionAboveMenu),
            ),
          if (hasPhotos) CupertinoActionSheetAction(key: const Key('attach-hd-menu'), onPressed: () => Navigator.pop(c, 'hd'), child: tick(hd, l.sendHd)),
          if (firstVideo != null && !once)
            CupertinoActionSheetAction(key: const Key('attach-video-quality'), onPressed: () => Navigator.pop(c, 'vq'), child: Text(l.videoSendQuality)),
          if (picked.any((f) => !f.asFile))
            CupertinoActionSheetAction(key: const Key('attach-as-file'), onPressed: () => Navigator.pop(c, 'file'), child: Text(l.sendAsFileOriginal)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    setState(() {
      switch (pick) {
        case 'together':
          together = true;
        case 'apart':
          together = false;
        case 'spoiler':
          final on = !allCovered;
          for (var i = 0; i < picked.length; i++) {
            if (picked[i].isMedia) picked[i] = picked[i].withSpoiler(on);
          }
        case 'above':
          captionAbove = !captionAbove;
        case 'hd':
          toggleHd();
        case 'vq':
          WidgetsBinding.instance.addPostFrameCallback((_) => pickVideoQuality());
        case 'file':
          for (var i = 0; i < picked.length; i++) {
            picked[i] = picked[i].asOriginal();
          }
          once = false;
          preview = false;
      }
    });
  }

  /// Every picture covered (the ⋯ 가리고 보내기 tick).
  bool get allCovered => mediaCount > 0 && picked.where((f) => f.isMedia).every((f) => f.spoiler);
  int get coveredCount => picked.where((f) => f.isMedia && f.spoiler).length;

  /// A photo that 표준 / HD changes (not GIF, not 파일로).
  bool get hasPhotos => Features.photoSend && picked.any((f) => !f.asFile && f.isImage && PhotoSize.canShrink(f.name));

  void toggleHd() {
    final l = L.of(context);
    setState(() => hdPick = !hd);
    showStoryToast(context, hd ? l.photoHdOn : l.photoHdOff);
  }

  /// Tap on a chosen video: 자르기·회전 (tip 56).
  Future<void> editVideo(int i) async {
    final f = picked[i];
    if (!f.isVideo || f.asFile || !canTrim) return;
    final r = await editChatVideo(context, bytes: f.bytes, name: f.name, start: f.video, muted: f.muted);
    if (r != null && mounted && i < picked.length && identical(picked[i].bytes, f.bytes)) {
      setState(() => picked[i] = picked[i].withVideo(r.edit).withMuted(r.muted));
    }
  }

  /// 자르기·회전 here (phones; the batch flag).
  bool get canTrim => Features.photoSend && Phone.canEditVideo;

  /// Photo → editor; video → 자르기·회전; others: nothing.
  Future<void> open(int i) => picked[i].isImage ? edit(i) : editVideo(i);

  /// Moves the picture at [from] to where [to] is (the others make room).
  void move(int from, int to) {
    if (from == to || from < 0 || to < 0 || from >= picked.length || to >= picked.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      picked.insert(to, picked.removeAt(from));
      dropOn = null;
    });
  }

  /// Square menu in 미리보기: edit / trim, cover or show, take out.
  Future<void> squareMenu(int i) async {
    final l = L.of(context);
    final f = picked[i];
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (f.isImage) CupertinoActionSheetAction(key: const Key('square-edit'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.pickEdit)),
          if (f.isVideo && canTrim)
            CupertinoActionSheetAction(key: const Key('square-trim'), onPressed: () => Navigator.pop(c, 'edit'), child: Text(l.pickTrim)),
          if (!once)
            CupertinoActionSheetAction(
              key: const Key('square-spoiler'),
              onPressed: () => Navigator.pop(c, 'spoiler'),
              child: Text(f.spoiler ? l.pickSpoilerOff : l.pickSpoilerOn),
            ),
          CupertinoActionSheetAction(
            key: const Key('square-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(l.pickRemove),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted || i >= picked.length) return;
    switch (pick) {
      case 'edit':
        await open(i);
      case 'spoiler':
        setState(() => picked[i] = picked[i].withSpoiler(!picked[i].spoiler));
      case 'remove':
        setState(() {
          picked.removeAt(i);
          if (!canOnce) once = false;
          if (mediaCount == 0) preview = false;
        });
    }
  }

  /// The first picture of a chosen video (once, then kept).
  Uint8List? videoThumb(PickedFile f) {
    final id = f.phoneId;
    if (id != null) {
      final m = recent?.where((x) => x.id == id).firstOrNull;
      if (m != null) return m.thumb;
    }
    if (videoThumbs.containsKey(f.bytes)) return videoThumbs[f.bytes];
    videoThumbs[f.bytes] = null;
    unawaited(
      Phone.videoFrames(f.bytes, f.name, count: 1, height: 360).then((list) {
        if (mounted && list.isNotEmpty) setState(() => videoThumbs[f.bytes] = list.first);
      }),
    );
    return null;
  }

  /// 갤러리 ⌄ (Telegram tip 324): 최근 항목, 즐겨찾기, 동영상, 스크린샷, … and
  /// my own albums, with counts.
  Future<void> albumMenu() async {
    final l = L.of(context);
    final list = albums ??= await Phone.albums();
    if (!mounted || list == null || list.isEmpty) return;
    final chosen = await showAlbumMenu(context, list, album?.id, l);
    if (chosen == null || !mounted) return;
    final r = await Phone.recent(album: chosen.id == PhoneAlbum.recentsId ? null : chosen.id);
    if (!mounted) return;
    setState(() {
      album = chosen.id == PhoneAlbum.recentsId ? null : chosen;
      recent = r ?? const [];
    });
  }

  /// v1 order (Eric 2026-11-24): channels get every tool; groups the same
  /// minus channel-only posts; 1:1 the personal ones.
  List<(String, IconData, String)> tabs(L l) {
    final room = widget.isGroup || widget.isChannel;
    return [
      ('gallery', CupertinoIcons.photo_fill_on_rectangle_fill, l.attachGallery),
      ('file', CupertinoIcons.doc_fill, l.attachFile),
      // 문서 스캔: paper → flattened PDF, made on the phone.
      if (Phone.canScan) ('scan', CupertinoIcons.doc_text_viewfinder, l.attachScan),
      ('videonote', CupertinoIcons.videocam_circle_fill, l.videoNote),
      ('poll', CupertinoIcons.chart_bar_alt_fill, l.attachPoll),
      ('checklist', CupertinoIcons.checkmark_square_fill, l.checklist),
      if (room) ('lottery', CupertinoIcons.gift_fill, l.cardLottery),
      if (room) ('form', CupertinoIcons.doc_text_fill, l.cardForm),
      if (room) ('faq', CupertinoIcons.question_circle_fill, l.cardFaq),
      if (room) ('guide', CupertinoIcons.square_list_fill, l.cardGuide),
      ('links', CupertinoIcons.link_circle_fill, l.cardLinks),
      ('templates', CupertinoIcons.bookmark_fill, l.cardTemplates),
      ('audio', CupertinoIcons.headphones, l.cardAudio),
      // Long post (headings, tables, formulas, photos) for every chat.
      ('rich', CupertinoIcons.textformat, l.articleWrite),
      // Channel plans would show subscribers' ids in the answers: groups and 1:1 only for now.
      if (!widget.isChannel) ('meetup', CupertinoIcons.calendar, l.meetup),
      if (room) ('checkin', CupertinoIcons.heart_circle_fill, l.cardCheckin),
      if (room) ('flow', CupertinoIcons.square_stack_3d_up_fill, l.cardFlow),
      if (!widget.isChannel) ('location', CupertinoIcons.location_solid, l.location),
      if (!widget.isChannel) ('contact', CupertinoIcons.person_crop_circle_fill, l.contactCard),
      if (!room) ('bubble', CupertinoIcons.circle_grid_hex_fill, l.attachBubble),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final mq = MediaQuery.of(context);
    final title = tabs(l).firstWhere((t) => t.$1 == tab).$3;
    // Telegram: drag the sheet down to close it (not while a tool is open).
    return SheetDrag(
      enabled: toolBody == null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[1] + mq.viewPadding.bottom + mq.viewInsets.bottom),
        child: LiquidGlass(
          key: const Key('attach-sheet'),
          radius: 38,
          // Frosted enough that the chat behind never fights the grid.
          child: Container(
            color: p.background.withValues(alpha: 0.6),
            // A tool page and the album preview get the tall card, like Telegram.
            height: toolBody != null || (preview && mediaCount > 0)
                ? mq.size.height - mq.viewPadding.top - Tokens.space[3] - mq.viewInsets.bottom
                : (mq.size.height * 0.56).clamp(360.0, 560.0),
            child: Column(
              children: [
                // iOS sheet grabber (36 x 5).
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  ),
                ),
                if (toolBody == null) ...[
                  SizedBox(
                    height: Tokens.sheetHeader - 11,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                      child: Row(
                        children: [
                          if (preview)
                            GlassCircle(
                              key: const Key('attach-preview-back'),
                              size: Tokens.closeButton,
                              onTap: () => setState(() => preview = false),
                              child: GlassCircle.icon(context, CupertinoIcons.chevron_left, size: Tokens.closeIcon),
                            )
                          else
                            GlassCircle(
                              key: const Key('attach-close'),
                              size: Tokens.closeButton,
                              onTap: () => Navigator.pop(context),
                              child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                            ),
                          Expanded(
                            child: picked.isEmpty && tab == 'gallery' && recent != null
                                ? GestureDetector(
                                    key: const Key('attach-album'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: albumMenu,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            album == null ? l.albumRecents : albumName(l, album!),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                                          ),
                                        ),
                                        SizedBox(width: Tokens.space[0]),
                                        Icon(CupertinoIcons.chevron_down, size: 14, color: p.secondaryLabel),
                                      ],
                                    ),
                                  )
                                : Features.photoSend && picked.isNotEmpty && mediaCount > 0 && tab == 'gallery'
                                // "3개 선택 ›": the bubble as it will look (tips 75 + 323).
                                ? GestureDetector(
                                    key: const Key('attach-preview'),
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => setState(() => preview = !preview),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          preview ? l.albumPreview : l.selectedCount(picked.length),
                                          style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                                        ),
                                        if (!preview) ...[
                                          SizedBox(width: Tokens.space[0]),
                                          Icon(CupertinoIcons.chevron_right, size: 14, color: p.secondaryLabel),
                                        ],
                                      ],
                                    ),
                                  )
                                : Text(
                                    picked.isEmpty ? title : l.selectedCount(picked.length),
                                    textAlign: TextAlign.center,
                                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                                  ),
                          ),
                          if (picked.isNotEmpty)
                            GlassCircle(
                              key: const Key('attach-more'),
                              size: Tokens.closeButton,
                              onTap: moreMenu,
                              child: GlassCircle.icon(context, CupertinoIcons.ellipsis, size: Tokens.closeIcon),
                            )
                          else
                            SizedBox(width: Tokens.closeButton),
                        ],
                      ),
                    ),
                  ),
                  // Room between the X and the tiles (Eric 2026-11-26: too tight).
                  SizedBox(height: Tokens.space[2]),
                ],
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: MediaQuery(
                          // Pages scroll under the floating tab capsule.
                          data: mq.removeViewInsets(removeBottom: true).copyWith(padding: mq.padding.copyWith(top: 0, bottom: barRoom)),
                          child: toolBody != null
                              ? toolHost()
                              : (tab == 'gallery' ? (preview && mediaCount > 0 ? previewBody(l, p) : galleryBody(l, p)) : fileBody(l, p)),
                        ),
                      ),
                      if (picked.isEmpty) Positioned(left: Tokens.space[1], right: Tokens.space[1], bottom: Tokens.space[1], child: tabBar(l, p)),
                    ],
                  ),
                ),
                if (picked.isNotEmpty) captionBar(l, p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget galleryBody(L l, Palette p) {
    Widget tile(Key key, IconData icon, String label, VoidCallback onTap) => GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: p.card.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(Tokens.radius[1])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: p.accent),
            SizedBox(height: Tokens.space[0]),
            Text(label, style: Tokens.caption.style.copyWith(color: p.label)),
          ],
        ),
      ),
    );
    final live = recent;
    final media = [
      for (var i = 0; i < picked.length; i++)
        if ((picked[i].isImage || picked[i].isVideo) && (live == null || picked[i].phoneId == null)) i,
    ];
    return GridView.count(
      padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], barRoom),
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: [
        // 채널 짧은 영상 (4-app board): in a channel the camera is ours and
        // opens on 영상, so a short clip goes straight into the post.
        tile(const Key('attach-camera'), CupertinoIcons.camera_fill, l.attachCamera, () => widget.isChannel ? shoot() : pick('camera')),
        tile(const Key('attach-library'), CupertinoIcons.photo_on_rectangle, live == null ? l.attachLibrary : l.attachAllPhotos, () => pick('library')),
        for (final i in media) thumb(i, p),
        if (live != null)
          for (final m in live) liveThumb(m, p),
      ],
    );
  }

  /// A photo from the phone's live grid: empty ring until chosen, then its
  /// order number (Telegram / iOS Photos picker look).
  Widget liveThumb(PhoneMedia m, Palette p) {
    final at = picked.indexWhere((f) => f.phoneId == m.id);
    final d = m.duration;
    final chosen = at >= 0 ? picked[at] : null;
    return GestureDetector(
      key: Key('attach-live-${m.id}'),
      // Chosen photo: tap = editor; the round mark un-chooses (Telegram).
      onTap: chosen != null && (chosen.isImage || (chosen.isVideo && canTrim)) ? () => open(at) : () => toggle(m),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: AnimatedScale(
              scale: at >= 0 ? 0.92 : 1,
              duration: const Duration(milliseconds: 180),
              child: Image.memory(
                chosen != null && chosen.isEdited ? chosen.bytes : m.thumb,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: p.card),
              ),
            ),
          ),
          // Chosen video: the sound capsule takes the corner instead.
          if (d != null && chosen == null)
            Positioned(
              left: 6,
              bottom: 5,
              child: Text(
                '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
                style: Tokens.caption.style.copyWith(
                  color: const Color(0xFFFFFFFF),
                  shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
                ),
              ),
            ),
          if (loading.contains(m.id)) const Center(child: CupertinoActivityIndicator(color: Color(0xFFFFFFFF))),
          // 움직이는 사진: chosen = LIVE ⌄ (style menu); not yet = the mark only.
          if (at >= 0 && picked[at].isLive)
            Positioned(left: Tokens.liveInset, top: Tokens.liveInset, child: liveControl(at))
          else if (m.live && !(chosen?.isEdited ?? false))
            Positioned(
              left: Tokens.liveInset,
              top: Tokens.liveInset,
              child: LiveMark(color: const Color(0xFFFFFFFF), size: Tokens.liveMark + 2),
            ),
          if (chosen != null && chosen.isVideo) Positioned(left: Tokens.liveInset, bottom: Tokens.liveInset, child: muteControl(at)),
          if (chosen != null && chosen.isEdited) const Positioned(left: 6, top: 6, child: EditedMark()),
          if (chosen != null && !chosen.video.isNone) const Positioned(left: 6, top: 6, child: EditedMark(icon: CupertinoIcons.scissors)),
          if (chosen != null && chosen.spoiler)
            Positioned(
              left: 6,
              bottom: chosen.isVideo ? Tokens.liveBadge + 10 : 6,
              child: const EditedMark(icon: CupertinoIcons.eye_slash_fill),
            ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              key: Key('attach-live-check-${m.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => toggle(m),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: at >= 0 ? p.accent : const Color(0x33000000),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                  ),
                  child: at >= 0 ? Text('${at + 1}', style: Tokens.caption.style.copyWith(color: p.onAccent)) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A picked picture with its order number; tap to take it out.
  Widget thumb(int i, Palette p) {
    final f = picked[i];
    void drop() => setState(() {
      picked.removeAt(i);
      if (!canOnce) once = false;
    });
    return GestureDetector(
      key: Key('attach-sel-$i'),
      // Photo: tap = editor; the number takes it out. Others: tap takes it out.
      onTap: f.isImage || (f.isVideo && canTrim) ? () => open(i) : drop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: f.isImage
                ? Image.memory(
                    f.bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => ColoredBox(color: p.card),
                  )
                : ColoredBox(
                    color: const Color(0xFF1C1C1E),
                    child: Icon(CupertinoIcons.play_circle_fill, color: const Color(0xFFFFFFFF), size: 34),
                  ),
          ),
          if (f.isLive) Positioned(left: Tokens.liveInset, top: Tokens.liveInset, child: liveControl(i)),
          if (f.isEdited) const Positioned(left: 6, top: 6, child: EditedMark()),
          if (!f.video.isNone) const Positioned(left: 6, top: 6, child: EditedMark(icon: CupertinoIcons.scissors)),
          if (f.spoiler)
            Positioned(
              left: 6,
              bottom: f.isVideo ? Tokens.liveBadge + 10 : 6,
              child: const EditedMark(icon: CupertinoIcons.eye_slash_fill),
            ),
          if (f.isVideo) Positioned(left: Tokens.liveInset, bottom: Tokens.liveInset, child: muteControl(i)),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              key: Key('attach-sel-check-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: drop,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: Tokens.caption.style.copyWith(color: p.onAccent)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 미리보기 (tips 75 + 323): the pictures exactly as the bubble will
  /// look (one mosaic, or one bubble each for 따로 보내기). Hold a square
  /// and drag it onto another to change the order; tap one for 편집 /
  /// 자르기·회전, 가리기 or 빼기.
  Widget previewBody(L l, Palette p) {
    final media = [
      for (var i = 0; i < picked.length; i++)
        if (picked[i].isMedia) i,
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth - Tokens.space[3] * 2, 300.0);
        Widget bubble(Widget child) => Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(bottom: Tokens.space[1]),
            child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius[2]), child: child),
          ),
        );
        return ListView(
          key: const Key('attach-preview-list'),
          padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: Tokens.space[2]),
              child: Text(
                l.albumPreviewHint,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
            ),
            if (together && media.length > 1 && !once)
              bubble(
                SizedBox(
                  key: const Key('attach-preview-album'),
                  width: width,
                  child: albumMosaic(count: media.length, width: width, cell: (k, h) => square(media[k], h, p)),
                ),
              )
            else
              for (final i in media) bubble(SizedBox(width: width, child: square(i, width * 0.66, p))),
          ],
        );
      },
    );
  }

  /// One square of the preview: drag it onto another to swap places.
  Widget square(int i, double h, Palette p) {
    final f = picked[i];
    final d = f.video.isNone ? f.length : (f.length == null ? null : f.video.lengthOf(f.length!));
    Widget face(double w) {
      final pic = f.isImage ? f.bytes : videoThumb(f);
      Widget c;
      if (pic == null) {
        c = const ColoredBox(
          color: Color(0xFF1C1C1E),
          child: Center(child: Icon(CupertinoIcons.play_circle_fill, color: Color(0xFFFFFFFF), size: 34)),
        );
      } else if (f.isVideo && f.video.turnsOrFlips) {
        // As it will be sent: turned and mirrored.
        Widget im = Image.memory(pic, gaplessPlayback: true);
        if (f.video.flip) im = Transform.flip(flipX: true, child: im);
        c = FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: RotatedBox(quarterTurns: (4 - f.video.turns % 4) % 4, child: im),
        );
      } else {
        c = Image.memory(
          pic,
          fit: BoxFit.cover,
          width: w,
          height: h,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => ColoredBox(color: p.card),
        );
      }
      if (f.spoiler) c = IgnorePointer(child: SpoilerCover(child: c));
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(child: c),
            if (f.isVideo)
              Positioned(
                left: Tokens.liveInset,
                bottom: Tokens.liveInset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: const Color(0x80000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f.muted) ...[const Icon(CupertinoIcons.speaker_slash_fill, size: 11, color: Color(0xFFFFFFFF)), const SizedBox(width: 3)],
                      Text(d == null ? '' : clockText(d), style: Tokens.liveText.style.copyWith(color: const Color(0xFFFFFFFF))),
                    ],
                  ),
                ),
              ),
            if (f.isEdited) const Positioned(right: 6, top: 6, child: EditedMark()),
            if (!f.video.isNone) const Positioned(right: 6, top: 6, child: EditedMark(icon: CupertinoIcons.scissors)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return DragTarget<int>(
          onWillAcceptWithDetails: (d) {
            if (d.data == i) return false;
            if (dropOn != i) setState(() => dropOn = i);
            return true;
          },
          onLeave: (_) {
            if (dropOn == i) setState(() => dropOn = null);
          },
          onAcceptWithDetails: (d) => move(d.data, i),
          builder: (context, _, _) => LongPressDraggable<int>(
            key: Key('attach-square-$i'),
            data: i,
            delay: const Duration(milliseconds: 260),
            hapticFeedbackOnStart: true,
            onDragEnd: (_) {
              if (dropOn != null && mounted) setState(() => dropOn = null);
            },
            feedback: Transform.scale(
              // Lifted a little; a wide square shrinks so the drop spot stays visible.
              scale: math.min(1.06, 200 / math.max(w, 1)),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.radius[1]),
                  boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 8))],
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius[1]), child: face(w)),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: face(w)),
            child: GestureDetector(
              onTap: () => squareMenu(i),
              child: AnimatedScale(scale: dropOn == i ? 0.92 : 1, duration: const Duration(milliseconds: 160), child: face(w)),
            ),
          ),
        );
      },
    );
  }

  Widget fileBody(L l, Palette p) {
    final audio = tab == 'audio';
    // Telegram 파일 tab: white card with accent rows, then my recent files.
    Widget action(Key key, IconData icon, String text, VoidCallback tap) => IosTile(
      key: key,
      leading: Icon(icon, color: p.accent, size: Tokens.listIcon + 2),
      title: Text(text, style: TextStyle(color: p.accent)),
      onTap: tap,
    );
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], barRoom),
      children: [
        IosSection(
          margin: EdgeInsets.zero,
          footer: sectionFooter(context, audio ? l.attachAudioInfo : l.attachFileInfo),
          children: [
            if (audio)
              action(const Key('attach-pick-audio'), CupertinoIcons.music_note_2, l.attachPickAudio, () => pick('audio'))
            else ...[
              action(const Key('attach-file-gallery'), CupertinoIcons.photo, l.attachFromGallery, () => pick('library', asFile: true)),
              action(const Key('attach-pick-file'), CupertinoIcons.cloud, l.attachFromFiles, () => pick('file')),
            ],
            for (var i = 0; i < picked.length; i++)
              IosTile(
                key: Key('attach-file-$i'),
                leading: iconTile(Palette.tileGrey, picked[i].isImage ? CupertinoIcons.photo : CupertinoIcons.doc_fill),
                title: Text(picked[i].name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(fileSize(picked[i].bytes.length), style: Tokens.caption.style),
                trailing: Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: Tokens.listIcon),
                onTap: () => setState(() => picked.removeAt(i)),
              ),
          ],
        ),
        if (!audio && picked.isEmpty && widget.sentFiles.isNotEmpty)
          IosSection(
            margin: EdgeInsets.only(top: Tokens.space[4]),
            header: sectionHeader(context, l.recentSentFiles),
            children: [
              for (final m in widget.sentFiles.take(10))
                IosTile(
                  key: Key('attach-recent-${m.id}'),
                  leading: iconTile(Palette.tileBlue, CupertinoIcons.doc_fill),
                  title: Text(m.body ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(fmt.format(m.time), style: Tokens.caption.style),
                  onTap: () => Navigator.pop(context, AttachResult.tool('resend:${m.id}')),
                ),
            ],
          ),
      ],
    );
  }

  /// Words under the pictures, the "1" (view once) switch and send.
  Widget captionBar(L l, Palette p) => Padding(
    padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[2]),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!once && (coveredCount > 0 || (mediaCount > 1 && !together)))
          Padding(
            padding: EdgeInsets.only(bottom: Tokens.space[1]),
            child: Container(
              key: const Key('attach-mode-pill'),
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
              decoration: BoxDecoration(color: p.label.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(
                [
                  if (mediaCount > 1 && !together) l.sendSeparately,
                  if (coveredCount > 0) allCovered ? l.sendSpoiler : l.spoilerCount(coveredCount),
                ].join(' · '),
                style: Tokens.caption.style.copyWith(color: p.background),
              ),
            ),
          ),
        if (once)
          Padding(
            padding: EdgeInsets.only(bottom: Tokens.space[1]),
            child: Container(
              key: const Key('attach-once-pill'),
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
              decoration: BoxDecoration(color: p.label.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(l.onceOnInfo, style: Tokens.caption.style.copyWith(color: p.background)),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                key: const Key('attach-caption'),
                controller: caption,
                enabled: !once,
                // Bold, italic, links … like the chat composer (tip 111).
                contextMenuBuilder: (c, st) => formatMenu(c, st, caption),
                placeholder: once ? l.onceNoCaption : l.captionHint,
                minLines: 1,
                maxLines: 4,
                maxLength: 4096,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] + 1),
                style: Tokens.body.style.copyWith(color: p.label),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
                suffix: canOnce || hasPhotos || (firstVideo != null && !once)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 영상 화질 (tip 114): "원본" / "720p"; tap = the slider.
                          if (firstVideo != null && !once)
                            GestureDetector(
                              key: const Key('attach-vq'),
                              onTap: pickVideoQuality,
                              child: Container(
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                margin: EdgeInsets.only(right: Tokens.space[1]),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: videoPick?.height != null ? p.accent : p.secondaryLabel, width: 1.5),
                                ),
                                child: Text(
                                  videoPick?.height == null ? l.videoQualityOriginal : '${videoPick!.height}p',
                                  style: Tokens.caption.style.copyWith(color: videoPick?.height != null ? p.accent : p.secondaryLabel, fontWeight: Tokens.semi),
                                ),
                              ),
                            ),
                          // 표준 / HD (tip 529): lit = HD.
                          if (hasPhotos)
                            GestureDetector(
                              key: const Key('attach-hd'),
                              onTap: toggleHd,
                              child: Container(
                                height: 26,
                                padding: const EdgeInsets.symmetric(horizontal: 5),
                                margin: EdgeInsets.only(right: Tokens.space[1]),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: hd ? p.accent : null,
                                  border: Border.all(color: hd ? p.accent : p.secondaryLabel, width: 1.5),
                                ),
                                child: Text(
                                  'HD',
                                  style: Tokens.caption.style.copyWith(color: hd ? p.onAccent : p.secondaryLabel, fontWeight: Tokens.semi),
                                ),
                              ),
                            ),
                          if (canOnce)
                            GestureDetector(
                              key: const Key('attach-once'),
                              onTap: () => setState(() => once = !once),
                              child: Container(
                                width: 26,
                                height: 26,
                                margin: EdgeInsets.only(right: Tokens.space[1]),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: once ? p.accent : null,
                                  border: Border.all(color: once ? p.accent : p.secondaryLabel, width: 1.5),
                                ),
                                child: Text('1', style: Tokens.caption.style.copyWith(color: once ? p.onAccent : p.secondaryLabel)),
                              ),
                            ),
                        ],
                      )
                    : null,
              ),
            ),
            SizedBox(width: Tokens.space[1]),
            GestureDetector(
              key: const Key('attach-send'),
              onTap: send,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: BurumyMark(color: p.onAccent, size: 26),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  /// A tool page in the card: closing it closes the sheet; once it has
  /// sent something (pops with true) the chat reloads.
  Widget toolHost() => Navigator(
    key: ValueKey('tool-$tab'),
    onGenerateRoute: (_) {
      final r = PageRouteBuilder<bool>(pageBuilder: (_, _, _) => toolBody!, transitionDuration: Duration.zero);
      r.popped.then((made) {
        if (mounted) Navigator.of(context).pop(made == true ? const AttachResult.made() : null);
      });
      return r;
    },
  );

  /// Sideways-scrolling tools on a floating glass capsule, like the main
  /// tab bar and Telegram's attach menu; the chosen one sits on a pill.
  Widget tabBar(L l, Palette p) => SizedBox(
    key: const Key('attach-tabbar'),
    height: FloatingTabBar.height,
    child: LiquidGlass(
      radius: FloatingTabBar.height / 2,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        children: [
          for (final (id, icon, label) in tabs(l))
            GestureDetector(
              key: Key('attach-tab-$id'),
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (id == 'gallery' || id == 'file' || id == 'audio') {
                  return setState(() {
                    tab = id;
                    toolBody = null;
                  });
                }
                final page = widget.toolPage?.call(id);
                if (page != null) {
                  return setState(() {
                    tab = id;
                    toolBody = page;
                  });
                }
                Navigator.pop(context, AttachResult.tool(id));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 76,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  // iOS 27 tab bar: the chosen tab sits on a soft grey pill.
                  color: tab == id ? Color(p.dark ? 0x33FFFFFF : 0x14000000) : null,
                  borderRadius: BorderRadius.circular((FloatingTabBar.height - 8) / 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: Tokens.tabIcon, color: tab == id ? p.accent : p.label),
                    const SizedBox(height: 3),
                    Text(label, maxLines: 1, style: Tokens.tabLabel.style.copyWith(color: tab == id ? p.accent : p.label)),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// "1.2 MB" style size.
String fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Small pencil mark on a photo changed in the editor.
class EditedMark extends StatelessWidget {
  const EditedMark({super.key, this.icon = CupertinoIcons.pencil});

  /// Pencil (photo edited), scissors (video cut / turned), eye (가리기).
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: Tokens.liveBadge,
    height: Tokens.liveBadge,
    decoration: const BoxDecoration(color: Color(0x80000000), shape: BoxShape.circle),
    child: Icon(icon, size: 13, color: const Color(0xFFFFFFFF)),
  );
}

String albumName(L l, PhoneAlbum a) => switch (a.id) {
  PhoneAlbum.recentsId => l.albumRecents,
  'favorites' => l.albumFavorites,
  'videos' => l.albumVideos,
  'screenshots' => l.albumScreenshots,
  'selfies' => l.albumSelfies,
  'live' => l.albumLive,
  _ => a.name ?? '',
};

IconData albumIcon(PhoneAlbum a) => switch (a.id) {
  PhoneAlbum.recentsId => CupertinoIcons.clock,
  'favorites' => CupertinoIcons.heart,
  'videos' => CupertinoIcons.videocam,
  'screenshots' => CupertinoIcons.device_phone_portrait,
  'selfies' => CupertinoIcons.person_crop_square,
  'live' => CupertinoIcons.smallcircle_circle,
  _ => CupertinoIcons.rectangle_stack,
};

/// iOS 27 pull-down under the 갤러리 title: kinds first, then my albums,
/// each with its count; a tick on the one shown.
Future<PhoneAlbum?> showAlbumMenu(BuildContext context, List<PhoneAlbum> albums, String? now, L l) {
  final box = context.findRenderObject() as RenderBox?;
  final top = box == null ? 120.0 : box.localToGlobal(Offset.zero).dy + Tokens.sheetHeader;
  return Navigator.of(context, rootNavigator: true).push<PhoneAlbum>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (c, anim, _) {
        final p = paletteOf(c);
        final size = MediaQuery.sizeOf(c);
        final w = math.min(300.0, size.width - Tokens.space[3] * 2);
        final current = now ?? PhoneAlbum.recentsId;
        final mine = albums.indexWhere((a) => a.name != null);
        Widget row(PhoneAlbum a) => GestureDetector(
          key: Key('album-${a.id}'),
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(c, a),
          child: SizedBox(
            height: Tokens.liveMenuRow,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                children: [
                  SizedBox(width: 22, child: Icon(CupertinoIcons.checkmark_alt, size: 18, color: a.id == current ? p.label : const Color(0x00000000))),
                  SizedBox(width: Tokens.space[1]),
                  Expanded(
                    child: Text(
                      albumName(l, a),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                  ),
                  Text('${a.count}', style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  SizedBox(width: Tokens.space[1]),
                  Icon(albumIcon(a), size: 20, color: p.label),
                ],
              ),
            ),
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(c)),
            ),
            Positioned(
              left: (size.width - w) / 2,
              top: top,
              child: FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn)),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const Key('album-menu'),
                    width: w,
                    child: LiquidGlass(
                      radius: Tokens.radius[3],
                      child: Container(
                        color: p.background.withValues(alpha: 0.55),
                        constraints: BoxConstraints(maxHeight: size.height * 0.55),
                        padding: EdgeInsets.symmetric(vertical: Tokens.space[0]),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < albums.length; i++) ...[
                                // A thicker gap between the kinds and my albums (iOS menu section).
                                if (i == mine && i > 0) Container(height: 8, color: p.separator.withValues(alpha: 0.5)),
                                row(albums[i]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
