// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// The "+" sheet in a chat: a floating glass sheet with a picture grid, files,
// and tools on a sideways-scrolling tab bar (iOS 26 sheet, rulebook ch. 4-1).
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../brand/mark.dart';
import '../core/backend.dart' show Msg;
import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'wide.dart';

/// A picked photo, video or file, kept on this phone until sent.
class PickedFile {
  const PickedFile(this.name, this.bytes, {this.phoneId, this.asFile = false});
  final String name;
  final Uint8List bytes;

  /// Chosen in the 파일 tab: sent as a file (original quality), even photos.
  final bool asFile;

  /// Set when it was chosen from the live photo grid (to un-choose it).
  final String? phoneId;

  String get _ext => name.contains('.') ? name.split('.').last.toLowerCase() : '';
  bool get isImage => const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'heif', 'bmp'].contains(_ext);
  bool get isVideo => const ['mp4', 'mov', 'm4v', 'webm', '3gp', 'mkv'].contains(_ext);
}

/// What the sheet hands back: files to send, or a tool to open.
class AttachResult {
  const AttachResult.send(this.files, {this.caption = '', this.once = false}) : tool = null;
  const AttachResult.tool(this.tool) : files = const [], caption = '', once = false;
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
}) => showCupertinoModalPopup<AttachResult>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (_) => AttachSheet(caption: caption, isGroup: isGroup, isChannel: isChannel, sentFiles: sentFiles),
);

class AttachSheet extends StatefulWidget {
  const AttachSheet({super.key, required this.caption, required this.isGroup, required this.isChannel, this.sentFiles = const []});
  final String caption;

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
  final picked = <PickedFile>[];
  late final caption = TextEditingController(text: widget.caption);
  bool once = false;

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
    final got = await Phone.load(m.id);
    if (!mounted) return;
    setState(() {
      loading.remove(m.id);
      if (got != null && picked.length < 20) picked.add(PickedFile(got.$1, got.$2, phoneId: m.id));
      if (!canOnce) once = false;
    });
  }

  @override
  void dispose() {
    caption.dispose();
    super.dispose();
  }

  bool get canOnce => !widget.isChannel && picked.isNotEmpty && picked.every((f) => f.isImage || f.isVideo);

  Future<void> pick(String source, {bool asFile = false}) async {
    var got = await (AttachSheet.debugPicker ?? _phonePicker)(source);
    if (!mounted || got.isEmpty) return;
    if (asFile) got = [for (final f in got) PickedFile(f.name, f.bytes, asFile: true)];
    setState(() {
      picked.addAll(got.take(20 - picked.length));
      if (!canOnce) once = false;
    });
  }

  static Future<List<PickedFile>> _phonePicker(String source) async {
    Future<PickedFile> read(XFile x) async => PickedFile(x.name, await x.readAsBytes());
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

  void send() => Navigator.pop(context, AttachResult.send(List.of(picked), caption: once ? '' : caption.text, once: once && canOnce));

  /// v1 order (Eric 2026-11-24): channels get every tool; groups the same
  /// minus channel-only posts; 1:1 the personal ones.
  List<(String, IconData, String)> tabs(L l) {
    final room = widget.isGroup || widget.isChannel;
    return [
      ('gallery', CupertinoIcons.photo_fill_on_rectangle_fill, l.attachGallery),
      ('file', CupertinoIcons.doc_fill, l.attachFile),
      ('poll', CupertinoIcons.chart_bar_alt_fill, l.attachPoll),
      ('checklist', CupertinoIcons.checkmark_square_fill, l.checklist),
      if (room) ('lottery', CupertinoIcons.gift_fill, l.cardLottery),
      if (room) ('form', CupertinoIcons.doc_text_fill, l.cardForm),
      if (room) ('faq', CupertinoIcons.question_circle_fill, l.cardFaq),
      if (room) ('guide', CupertinoIcons.square_list_fill, l.cardGuide),
      ('links', CupertinoIcons.link_circle_fill, l.cardLinks),
      ('templates', CupertinoIcons.bookmark_fill, l.cardTemplates),
      ('audio', CupertinoIcons.headphones, l.cardAudio),
      if (widget.isChannel) ('rich', CupertinoIcons.textformat, l.cardRich),
      // Channel plans would show subscribers' ids in the answers: groups and 1:1 only for now.
      if (!widget.isChannel) ('meetup', CupertinoIcons.calendar, l.meetup),
      if (room) ('checkin', CupertinoIcons.heart_circle_fill, l.cardCheckin),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[1] + mq.viewPadding.bottom + mq.viewInsets.bottom),
      child: LiquidGlass(
        key: const Key('attach-sheet'),
        radius: 38,
        // Frosted enough that the chat behind never fights the grid.
        child: Container(
          color: p.background.withValues(alpha: 0.6),
          height: (mq.size.height * 0.56).clamp(360.0, 560.0),
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
              SizedBox(
                height: Tokens.sheetHeader - 11,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                  child: Row(
                    children: [
                      GlassCircle(
                        key: const Key('attach-close'),
                        size: Tokens.closeButton,
                        onTap: () => Navigator.pop(context),
                        child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                      ),
                      Expanded(
                        child: Text(
                          picked.isEmpty ? title : l.selectedCount(picked.length),
                          textAlign: TextAlign.center,
                          style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: Tokens.closeButton),
                    ],
                  ),
                ),
              ),
              Expanded(child: tab == 'gallery' ? galleryBody(l, p) : fileBody(l, p)),
              if (picked.isNotEmpty) captionBar(l, p) else tabBar(l, p),
            ],
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
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
      crossAxisCount: 3,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      children: [
        tile(const Key('attach-camera'), CupertinoIcons.camera_fill, l.attachCamera, () => pick('camera')),
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
    return GestureDetector(
      key: Key('attach-live-${m.id}'),
      onTap: () => toggle(m),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[1]),
            child: AnimatedScale(
              scale: at >= 0 ? 0.92 : 1,
              duration: const Duration(milliseconds: 180),
              child: Image.memory(
                m.thumb,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: p.card),
              ),
            ),
          ),
          if (d != null)
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
          Positioned(
            top: 6,
            right: 6,
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
        ],
      ),
    );
  }

  /// A picked picture with its order number; tap to take it out.
  Widget thumb(int i, Palette p) {
    final f = picked[i];
    return GestureDetector(
      key: Key('attach-sel-$i'),
      onTap: () => setState(() {
        picked.removeAt(i);
        if (!canOnce) once = false;
      }),
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
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Text('${i + 1}', style: Tokens.caption.style.copyWith(color: p.onAccent)),
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
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
                placeholder: once ? l.onceNoCaption : l.captionHint,
                minLines: 1,
                maxLines: 4,
                maxLength: 4096,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1] + 1),
                style: Tokens.body.style.copyWith(color: p.label),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
                suffix: canOnce
                    ? GestureDetector(
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

  /// Sideways-scrolling tools; the chosen one is lifted (iOS look).
  Widget tabBar(L l, Palette p) => SizedBox(
    height: Tokens.tabBar + Tokens.space[1],
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      children: [
        for (final (id, icon, label) in tabs(l))
          GestureDetector(
            key: Key('attach-tab-$id'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (id == 'gallery' || id == 'file' || id == 'audio') return setState(() => tab = id);
              Navigator.pop(context, AttachResult.tool(id));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 76,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                // iOS 27 tab bar: the chosen tab sits on a soft grey pill.
                color: tab == id ? Color(p.dark ? 0x24FFFFFF : 0x14000000) : null,
                borderRadius: BorderRadius.circular(Tokens.radius[2] + 4),
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
  );
}

/// "1.2 MB" style size.
String fileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
