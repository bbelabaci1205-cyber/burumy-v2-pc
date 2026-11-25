// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Small shared pieces: palette lookup, avatar, time label.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'formatting.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';

Palette paletteOf(BuildContext c) => Palette.of(AppScope.of(c).family, CupertinoTheme.brightnessOf(c));

/// No-photo avatar: iOS colours only, no black/grey, top a little lighter,
/// no border (rulebook ch. 4-5).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 54, this.squircle = false, this.userId, this.roomId, this.owner});

  /// A channel: its owner's small photo at the bottom right (v1 rule).
  final String? owner;
  final String name;

  /// A chat: "저장한 메시지" shows the bookmark (Telegram and v1).
  final String? roomId;
  final double size;
  final bool squircle;

  /// A person: shows the photo I chose for them, if any (나에게만 보이는 사진).
  final String? userId;

  /// Same colour for the same name everywhere (avatar, group sender name).
  static Color colorFor(String name) => tint[name] ?? _colors[name.codeUnits.fold<int>(0, (a, b) => a + b) % _colors.length];

  /// Look-only demo: fixed colours for its example names (Eric 2026-11-25:
  /// groups and channels in calm blues so the list is not too colourful).
  static final tint = <String, Color>{};

  static const _colors = [Palette.tileRed, Palette.tileOrange, Palette.tileBlue, Palette.tileIndigo, Palette.tilePurple, Palette.tilePink, Palette.tileTeal];

  @override
  Widget build(BuildContext context) {
    final o = owner;
    if (o != null && o.isNotEmpty) {
      final b = (size * 0.4).roundToDouble();
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Avatar(name: name, size: size, squircle: squircle, roomId: roomId),
            Positioned(
              right: -b * 0.12,
              bottom: -b * 0.12,
              child: Avatar(key: const Key('owner-badge'), name: displayId(o), size: b, userId: o),
            ),
          ],
        ),
      );
    }
    final s = AppScope.of(context);
    if (roomId != null && roomId == s.savedRoomId) {
      final base = paletteOf(context).accent;
      return Container(
        key: const Key('saved-avatar'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(base, const Color(0xFFFFFFFF), 0.18)!, base]),
        ),
        child: Icon(CupertinoIcons.bookmark_fill, size: size * 0.46, color: const Color(0xFFFFFFFF)),
      );
    }
    // A photo I chose for them first, else the one they share with me.
    final mine = userId == null ? null : myPhotoFor(s, userId) ?? s.cardPhoto(userId!);
    if (mine != null) {
      return ClipOval(
        child: Image.memory(mine, width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
      );
    }
    final base = colorFor(name);
    final top = Color.lerp(base, const Color(0xFFFFFFFF), 0.18)!;
    // IDs start with @: the letter is the first one after it.
    final clean = name.trim().replaceFirst(RegExp('^@'), '');
    final letter = clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: squircle ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: squircle ? BorderRadius.circular(size * 0.3) : null,
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, base]),
      ),
      child: Text(
        letter,
        style: TextStyle(fontFamily: Tokens.font, fontSize: size * 0.42, fontWeight: FontWeight.w500, color: const Color(0xFFFFFFFF)),
      ),
    );
  }
}

/// Chat list time: today = hour, yesterday = word, older = date.
String shortTime(BuildContext c, DateTime t, {DateTime? now}) {
  // Telegram-style: today = time, the last 6 days = weekday only,
  // older = numbers only (11.23; another year 25.11.23).
  final lang = Localizations.localeOf(c).languageCode;
  final n = now ?? DateTime.now();
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(n.year, n.month, n.day);
  final ago = today.difference(day).inDays;
  if (ago <= 0) return DateFormat.jm(lang).format(t);
  if (ago < 7) return DateFormat.E(lang).format(t);
  final en = lang == 'en';
  if (t.year == n.year) return en ? '${t.month}/${t.day}' : '${t.month}.${t.day}';
  final yy = (t.year % 100).toString().padLeft(2, '0');
  return en ? '${t.month}/${t.day}/$yy' : '$yy.${t.month}.${t.day}';
}

/// Preview text for a message of any kind.
String previewText(BuildContext c, {required String kind, String? body, String? caption}) => previewTextL(L.of(c), kind: kind, body: body, caption: caption);

/// Same, without a screen (used for phone notifications).
String previewTextL(L l, {required String kind, String? body, String? caption}) {
  final cap = caption == null ? '' : plainText(caption).trim();
  if (cap.isNotEmpty && const ['image', 'video', 'file'].contains(kind)) {
    return '${kind == 'file' ? (body ?? l.file) : (kind == 'image' ? l.photo : l.video)} · $cap';
  }
  return switch (kind) {
    'image' => l.photo,
    'video' => l.video,
    'audio' => l.voice,
    'file' => body ?? l.file,
    'locked' => l.messageLocked,
    'sticker' => l.sticker,
    'timer' => l.timer,
    'poll' => '${l.poll}: ${body ?? ''}',
    'checklist' => '${l.checklist}: ${body ?? ''}',
    'meetup' => '${l.meetup}: ${body ?? ''}',
    'card' => plainText(body ?? ''),
    'verify' => l.verifyRequestLine,
    'contact' => '${l.contactCard}: ${body ?? ''}',
    'location' => l.location,
    'call' => l.callPreview,
    'bubble' => l.attachBubble,
    _ => plainText(body ?? ''),
  };
}

/// IDs are shown without the server part ("@mina", not "@mina:server"):
/// screens never show internal server names (rulebook ch. 6).
String displayId(String userId) {
  final i = userId.indexOf(':');
  return i > 0 ? userId.substring(0, i) : userId;
}

/// iOS Settings-style coloured icon tile (white glyph, near-flat).
/// iOS 27: 28 pt, a little lighter at the top, with a thin light rim
/// (measured from iPhone Settings, 2026-11-24).
Widget iconTile(Color c, IconData i) => Container(
  width: 28,
  height: 28,
  decoration: ShapeDecoration(
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(7.5),
      side: BorderSide(color: Color.lerp(c, const Color(0xFFFFFFFF), 0.35)!, width: 0.6),
    ),
    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(c, const Color(0xFFFFFFFF), 0.08)!, c]),
  ),
  child: Icon(i, size: Tokens.listIconSmall, color: const Color(0xFFFFFFFF)),
);

/// iOS grouped-list section title: small, grey, regular weight.
Widget sectionHeader(BuildContext context, String text) => Text(text, style: Tokens.caption.style.copyWith(color: paletteOf(context).secondaryLabel));

/// iOS grouped-list note under a section: small, grey (red for errors).
Widget sectionFooter(BuildContext context, String text, {bool error = false}) =>
    Text(text, style: Tokens.caption.style.copyWith(color: error ? const Color(0xFFFF3B30) : paletteOf(context).secondaryLabel));

/// Name I gave a person in my contacts (kept only on this phone).
/// My own name for a person from 이름 + 성: Korean puts 성 first with no
/// space (김 + 민수 = 김민수), other languages "first last".
String joinName(String first, String last, String lang) {
  final f = first.trim(), g = last.trim();
  if (f.isEmpty || g.isEmpty) return f.isEmpty ? g : f;
  return lang == 'ko' ? '$g$f' : '$f $g';
}

final _photoCache = <String, Uint8List>{};

/// The photo I set for a person; stays in this phone's locked store.
Uint8List? myPhotoFor(AppState s, String? userId) {
  if (userId == null) return null;
  final raw = s.pref('cphoto:$userId', '');
  if (raw.isEmpty) return null;
  return _photoCache['$userId:${raw.hashCode}:${raw.length}'] ??= base64Decode(raw);
}

/// Largest photo kept for a person (the picker makes ~20 KB; a browser
/// may ignore the size hint, so anything bigger is refused).
const myPhotoMaxBytes = 300 * 1024;

/// Saves (or with null removes) the photo; false when it is too big.
Future<bool> setMyPhotoFor(AppState s, String userId, List<int>? bytes) async {
  if (bytes != null && bytes.length > myPhotoMaxBytes) return false;
  _photoCache.removeWhere((k, _) => k.startsWith('$userId:'));
  await s.setPref('cphoto:$userId', bytes == null || bytes.isEmpty ? '' : base64Encode(bytes));
  return true;
}

String aliasOf(AppState s, String? userId) => userId == null ? '' : s.pref('alias:$userId', '').trim();

/// Chat name as I see it: my own name for the person in 1:1 chats.
String nameOf(AppState s, ChatPreview c) {
  final a = c.isDirect ? aliasOf(s, c.peer) : '';
  return a.isNotEmpty ? a : c.name;
}

/// Same, by room, for pages opened with a title.
String titleOf(AppState s, String roomId, String fallback) {
  final c = s.chats.where((x) => x.roomId == roomId).firstOrNull;
  if (c != null && !c.isDirect && c.name.isNotEmpty) return c.name; // renamed groups follow
  final a = c != null && c.isDirect ? aliasOf(s, c.peer) : '';
  return a.isNotEmpty ? a : fallback;
}

/// Messages I cleared on my side ("메시지 비우기") end at this moment.
DateTime? clearedAt(AppState s, String roomId) {
  final v = int.tryParse(s.pref('cleared:$roomId', ''));
  return v == null ? null : DateTime.fromMillisecondsSinceEpoch(v);
}
