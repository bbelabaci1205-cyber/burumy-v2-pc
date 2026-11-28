// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널에 글 제안 (Telegram tip 531, no money): the subscriber's button and
// editor, the suggestion card with 올리기 / 거절 for admins, the
// "합의됐어요!" card, and the admin's publish / decline pages.
// Logic: core/suggest_post.dart.
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/suggest_post.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'date_pick.dart' as dp;
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show AccentButton;
import 'settings_kit.dart';

String suggestWhen(BuildContext context, DateTime at) {
  final lang = Localizations.localeOf(context).languageCode;
  return DateFormat.MMMd(lang).add_jm().format(at);
}

/// Above the subscriber's composer in a channel's admin chat (Telegram:
/// "Tap here to suggest a post").
class SuggestBar extends StatelessWidget {
  const SuggestBar({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      key: const Key('suggest-bar'),
      padding: EdgeInsets.only(bottom: Tokens.space[1]),
      child: GestureDetector(
        key: const Key('suggest-open'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LiquidGlass(
          radius: 22,
          child: Container(
            height: Tokens.closeButton,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.square_pencil, size: Tokens.listIconSmall, color: p.accent),
                SizedBox(width: Tokens.space[1]),
                Text(l.suggestBarButton, style: Tokens.body.style.copyWith(color: p.accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The subscriber's editor: words, a photo, when.
class SuggestPostPage extends StatefulWidget {
  const SuggestPostPage({super.key, required this.dmRoom, required this.channel});
  final String dmRoom;
  final String channel;

  /// Tests: a photo instead of the gallery.
  static Future<(String, List<int>)?> Function()? debugPhoto;

  @override
  State<SuggestPostPage> createState() => _SuggestPostPageState();
}

class _SuggestPostPageState extends State<SuggestPostPage> {
  final text = TextEditingController();
  (String, List<int>)? photo;
  DateTime? at;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    if (SuggestPostPage.debugPhoto != null) {
      final got = await SuggestPostPage.debugPhoto!();
      if (got != null && mounted) setState(() => photo = got);
      return;
    }
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2048, maxHeight: 2048, imageQuality: 88);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    final name = x.name.toLowerCase();
    final mime = x.mimeType ?? (name.endsWith('.png') ? 'image/png' : 'image/jpeg');
    if (mounted) setState(() => photo = (mime, bytes));
  }

  Future<void> pickTime() async {
    final got = await dp.pickDateTime(context, initial: at, button: L.of(context).topicDone);
    if (got != null && mounted) setState(() => at = got);
  }

  bool get ok => !busy && (text.text.trim().isNotEmpty || photo != null);

  Future<void> send() async {
    final s = AppScope.read(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await SuggestPost.send(s.backend, widget.dmRoom, widget.channel, text.text, photo: photo, at: at);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.suggestPost,
      children: [
        SizedBox(height: Tokens.space[3]),
        group(context, header: l.suggestHint, [
          CupertinoTextField.borderless(
            key: const Key('suggest-text'),
            controller: text,
            autofocus: true,
            placeholder: l.suggestTextHint,
            maxLength: 4000,
            minLines: 4,
            maxLines: 10,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
            onChanged: (_) => setState(() {}),
          ),
          if (photo != null)
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radius[1]),
                child: Image.memory(
                  Uint8List.fromList(photo!.$2),
                  key: const Key('suggest-photo-preview'),
                  height: 180,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          IosTile(
            key: const Key('suggest-photo'),
            leading: iconTile(photo == null ? Palette.tileBlue : Palette.tileRed, photo == null ? CupertinoIcons.photo_fill : CupertinoIcons.trash_fill),
            title: Text(photo == null ? l.suggestPhoto : l.suggestPhotoRemove),
            onTap: () => photo == null ? pickPhoto() : setState(() => photo = null),
          ),
        ]),
        group(context, footer: l.suggestTimeInfo, [
          IosTile(
            key: const Key('suggest-time'),
            leading: iconTile(Palette.tileOrange, CupertinoIcons.clock_fill),
            title: Text(l.suggestTime),
            additionalInfo: Text(at == null ? l.suggestAnyTime : suggestWhen(context, at!)),
            trailing: at == null
                ? const IosChevron()
                : GestureDetector(
                    key: const Key('suggest-time-clear'),
                    onTap: () => setState(() => at = null),
                    child: Icon(CupertinoIcons.xmark_circle_fill, size: 20, color: p.secondaryLabel),
                  ),
            onTap: pickTime,
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          child: Opacity(
            opacity: ok ? 1 : 0.4,
            child: AccentButton(key: const Key('suggest-send'), text: l.suggestSend, onTap: ok ? send : () {}),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.cardToFooter, Tokens.space[4], 0),
          child: Text(error ?? l.suggestFree, style: Tokens.caption.style.copyWith(color: error != null ? Palette.tileRed : p.secondaryLabel)),
        ),
      ],
    );
  }
}

/// The suggestion in the admin chat: the post as it would look, the wished
/// time, and 거절 / 올리기 for admins (or "waiting" for the subscriber).
class SuggestCard extends StatelessWidget {
  const SuggestCard({super.key, required this.roomId, required this.msg, required this.deal, required this.admin, required this.name, required this.onChanged});
  final String roomId;
  final Msg msg;
  final Msg? deal;
  final bool admin;

  /// The suggester's name (for the credit line).
  final String name;
  final Future<void> Function() onChanged;

  Future<void> accept(BuildContext context) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final channel = msg.card!.text('channel');
    if (!await s.backend.canPost(channel).catchError((_) => false)) {
      if (context.mounted) showInfo(context, l.suggestNoRight);
      return;
    }
    if (!context.mounted) return;
    final got = await Navigator.of(context).push<(DateTime?, bool)>(IosPageRoute(builder: (_) => SuggestAcceptPage(wanted: SuggestPost.wantedAt(msg.card!))));
    if (got == null || !context.mounted) return;
    final credit = got.$2 ? l.suggestCreditLine(name) : null;
    await SuggestPost.accept(s, roomId, msg, at: got.$1, credit: credit, creditLine: credit ?? '');
    await onChanged();
  }

  Future<void> decline(BuildContext context) async {
    final note = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => const SuggestDeclinePage()));
    if (note == null || !context.mounted) return;
    await SuggestPost.decline(AppScope.read(context).backend, roomId, msg, note: note);
    await onChanged();
  }

  void showInfo(BuildContext context, String text) => ScaffoldMessengerLess.show(context, text);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final c = msg.card!;
    final wanted = SuggestPost.wantedAt(c);
    final width = MediaQuery.sizeOf(context).width * 0.8;
    Widget pill(String key, String text, {required bool main, required VoidCallback onTap}) => Expanded(
      child: GestureDetector(
        key: Key(key),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: Tokens.closeButton - 6,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: main ? p.accent : p.label.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(
            text,
            style: Tokens.preview.style.copyWith(color: main ? p.onAccent : p.label, fontWeight: Tokens.semi),
          ),
        ),
      ),
    );
    return Align(
      alignment: msg.mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: Key('suggest-card-${msg.id}'),
        width: width,
        margin: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[0]),
        padding: EdgeInsets.all(Tokens.space[2]),
        decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.square_pencil, size: 15, color: p.accent),
                SizedBox(width: Tokens.space[0]),
                Text(
                  l.suggestCardTitle,
                  style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                ),
              ],
            ),
            if (c.text('photo').isNotEmpty) ...[SizedBox(height: Tokens.space[1]), _SecretPhoto(file: c.text('photo'))],
            if (c.text('text').isNotEmpty) ...[SizedBox(height: Tokens.space[1]), Text(c.text('text'), style: Tokens.body.style.copyWith(color: p.label))],
            SizedBox(height: Tokens.space[1]),
            Text(
              wanted == null ? '${l.suggestTime}: ${l.suggestAnyTime}' : l.suggestWantsAt(suggestWhen(context, wanted)),
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
            if (deal == null) ...[
              SizedBox(height: Tokens.space[2]),
              if (admin)
                Row(
                  children: [
                    pill('suggest-decline', l.suggestDecline, main: false, onTap: () => decline(context)),
                    SizedBox(width: Tokens.space[1]),
                    pill('suggest-accept', l.suggestAccept, main: true, onTap: () => accept(context)),
                  ],
                )
              else
                Text(
                  l.suggestWaiting,
                  key: const Key('suggest-waiting'),
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiny in-place notice (this chat page has its own; cards use this).
class ScaffoldMessengerLess {
  static void show(BuildContext context, String text) {
    final o = Overlay.maybeOf(context);
    if (o == null) return;
    final p = paletteOf(context);
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => Positioned(
        left: Tokens.space[3],
        right: Tokens.space[3],
        bottom: MediaQuery.paddingOf(context).bottom + 96,
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
            decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Text(text, style: Tokens.preview.style.copyWith(color: p.label)),
          ),
        ),
      ),
    );
    o.insert(e);
    Timer(const Duration(seconds: 2), e.remove);
  }
}

class _SecretPhoto extends StatefulWidget {
  const _SecretPhoto({required this.file});
  final String file;
  @override
  State<_SecretPhoto> createState() => _SecretPhotoState();
}

class _SecretPhotoState extends State<_SecretPhoto> {
  static final _cache = <String, Uint8List>{};
  Uint8List? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bytes != null) return;
    final got = _cache[widget.file];
    if (got != null) {
      bytes = got;
      return;
    }
    unawaited(
      AppScope.read(context).backend.downloadEncrypted(widget.file).then((b) {
        final u = Uint8List.fromList(b);
        if (_cache.length > 20) _cache.remove(_cache.keys.first);
        _cache[widget.file] = u;
        if (mounted) setState(() => bytes = u);
      }, onError: (_) {}),
    );
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(Tokens.radius[1]),
    child: bytes == null
        ? Container(height: 160, color: paletteOf(context).label.withValues(alpha: 0.06))
        : Image.memory(bytes!, height: 180, width: double.infinity, fit: BoxFit.cover),
  );
}

/// "합의됐어요!" / "제안이 거절됐어요" in the middle of the chat.
class SuggestDealLine extends StatelessWidget {
  const SuggestDealLine({super.key, required this.msg});
  final Msg msg;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final c = msg.card!;
    final ok = c.data['act'] == 'accept';
    final at = c.data['at'] is int && (c.data['at'] as int) > 0 ? DateTime.fromMillisecondsSinceEpoch(c.data['at'] as int) : null;
    Widget line(IconData icon, String text) => Padding(
      padding: EdgeInsets.only(top: Tokens.space[1]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: p.secondaryLabel),
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: Text(text, style: Tokens.caption.style.copyWith(color: p.label)),
          ),
        ],
      ),
    );
    return Center(
      child: Container(
        key: Key('suggest-deal-${msg.id}'),
        width: MediaQuery.sizeOf(context).width * 0.78,
        margin: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
        decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                ok ? '🤝 ${l.suggestDealAccepted}' : '🙅 ${l.suggestDealDeclined}',
                style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi, fontFamilyFallback: Tokens.emojiFallback),
              ),
            ),
            if (ok) ...[
              line(CupertinoIcons.calendar, at == null ? l.suggestDealNow : l.suggestDealAt(suggestWhen(context, at))),
              line(CupertinoIcons.gift, l.suggestDealFree),
              if (c.data['credit'] == true) line(CupertinoIcons.pencil, l.suggestDealCredit),
            ] else if (c.text('note').isNotEmpty)
              line(CupertinoIcons.text_bubble, l.suggestDealNote(c.text('note'))),
          ],
        ),
      ),
    );
  }
}

/// Admin: when to post it, and with the suggester's name or not.
class SuggestAcceptPage extends StatefulWidget {
  const SuggestAcceptPage({super.key, this.wanted});
  final DateTime? wanted;
  @override
  State<SuggestAcceptPage> createState() => _SuggestAcceptPageState();
}

class _SuggestAcceptPageState extends State<SuggestAcceptPage> {
  /// 'now', 'theirs' or 'other'.
  late String when = widget.wanted != null && widget.wanted!.isAfter(DateTime.now()) ? 'theirs' : 'now';
  DateTime? other;
  bool credit = true;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget choice(String key, String title, {String? info}) => IosTile(
      key: Key('suggest-when-$key'),
      title: Text(title),
      additionalInfo: info == null ? null : Text(info),
      trailing: when == key ? Icon(CupertinoIcons.checkmark_alt, size: 22, color: p.accent) : null,
      onTap: () async {
        if (key == 'other') {
          final got = await dp.pickDateTime(context, initial: other, button: l.topicDone);
          if (got == null) return;
          other = got;
        }
        if (mounted) setState(() => when = key);
      },
    );
    final wanted = widget.wanted;
    return SettingsScaffold(
      title: l.suggestAcceptTitle,
      children: [
        SizedBox(height: Tokens.space[3]),
        group(context, header: l.suggestTime, footer: when == 'now' ? null : l.suggestPhoneOn, [
          choice('now', l.suggestNow),
          if (wanted != null && wanted.isAfter(DateTime.now())) choice('theirs', l.suggestTheirTime(suggestWhen(context, wanted))),
          choice('other', l.suggestOtherTime, info: when == 'other' && other != null ? suggestWhen(context, other!) : null),
        ]),
        group(context, [
          IosTile(
            title: Text(l.suggestCredit),
            trailing: IosSwitch(key: const Key('suggest-credit'), value: credit, activeTrackColor: p.accent, onChanged: (v) => setState(() => credit = v)),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          child: AccentButton(
            key: const Key('suggest-accept-go'),
            text: l.suggestAccept,
            onTap: () => Navigator.pop(context, (
              switch (when) {
                'theirs' => wanted,
                'other' => other,
                _ => null,
              },
              credit,
            )),
          ),
        ),
      ],
    );
  }
}

/// Admin: decline, with an optional reason.
class SuggestDeclinePage extends StatefulWidget {
  const SuggestDeclinePage({super.key});
  @override
  State<SuggestDeclinePage> createState() => _SuggestDeclinePageState();
}

class _SuggestDeclinePageState extends State<SuggestDeclinePage> {
  final note = TextEditingController();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.suggestDecline,
      children: [
        SizedBox(height: Tokens.space[3]),
        group(context, [
          CupertinoTextField.borderless(
            key: const Key('suggest-note'),
            controller: note,
            placeholder: l.suggestNote,
            maxLength: 200,
            maxLines: 3,
            minLines: 1,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + Tokens.space[0]),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], 0),
          child: AccentButton(key: const Key('suggest-decline-go'), text: l.suggestDeclineSend, onTap: () => Navigator.pop(context, note.text)),
        ),
      ],
    );
  }
}
