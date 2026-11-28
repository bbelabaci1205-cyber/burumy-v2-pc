// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 가벼운 영상 복사본 (Telegram tips 479 · 480 · 114, batch #11, Eric
// 2026-11-27 card "A: 가벼운 복사본 1개").
//
// Telegram's server makes smaller copies of channel videos. Our server
// can't (it only sees encrypted bytes), so the SENDER's phone makes them:
// - 114 화질 슬라이더: before sending, five steps from 작은 용량 to 원본
//   with the size it will be ("1280×720 · 0:40 · 12 MB").
// - 479 · 480: long videos (30 s+) in channels and big groups (100+) also
//   get one light copy (480p), encrypted with its own key and sent as a
//   hidden second file. The viewer's ⚙ menu picks 자동 / 원본 / 가벼운 화질;
//   자동 = light copy on mobile data, original on Wi-Fi.
// The server sees one more encrypted file, nothing else.
// Making the copy uses the phone's own video encoder (Phone.editVideo with
// a height: Android Media3, iPhone AVFoundation). The web can't make
// copies (it sends the original) but plays them.
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/live_photo.dart' show Mp4Meta;
import '../core/media_tags.dart';
import '../core/phone.dart';
import '../core/storage_usage.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

/// Heights of the slider's first four steps; the fifth is 원본.
const lightSteps = [360, 480, 720, 1080];

/// Video bit rate per step (kbit/s), plus 128 for sound. Phone encoders
/// land near these with H.264.
const _kbps = {360: 600, 480: 1000, 720: 2200, 1080: 4500};

/// The light copy everyone can pick (Telegram "Medium 480").
const lightHeight = 480;

/// Card A: copies for videos this long in channels / groups this big.
const lightMinLength = Duration(seconds: 30);
const lightMinMembers = 100;

/// Rough size of [len] at [height] (bytes).
int estimateBytes(Duration len, int height) => ((_kbps[height] ?? 2200) + 128) * 1000 ~/ 8 * len.inSeconds;

/// Width × height of the first video track in an MP4 / MOV (tkhd box).
Size? mp4VideoSize(List<int> bytes) {
  final b = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  int u32(int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
  Size? found;
  void walk(int from, int to) {
    var at = from;
    while (found == null && at + 8 <= to) {
      var size = u32(at);
      final type = String.fromCharCodes(b.sublist(at + 4, at + 8));
      var head = 8;
      if (size == 1 && at + 16 <= to) {
        size = (u32(at + 8) << 32) | u32(at + 12);
        head = 16;
      } else if (size == 0) {
        size = to - at;
      }
      if (size < head || at + size > to) return;
      if (type == 'moov' || type == 'trak') {
        walk(at + head, at + size);
      } else if (type == 'tkhd') {
        final v = b[at + head];
        // Width / height are the last 8 bytes (16.16 fixed point).
        final end = at + size;
        if (size - head >= (v == 1 ? 96 : 84)) {
          final w = u32(end - 8) >> 16, h = u32(end - 4) >> 16;
          if (w > 0 && h > 0) found = Size(w.toDouble(), h.toDouble());
        }
      }
      at += size;
    }
  }

  try {
    walk(0, b.length);
  } catch (_) {}
  return found;
}

/// What the sender picked for one video (114) and whether a light copy
/// goes along (479 · 480).
class VideoSendPick {
  const VideoSendPick({this.height, this.light = false});

  /// null = 원본 (unchanged).
  final int? height;
  final bool light;
}

/// Should this video get a light copy by default (card A)?
bool wantsLight({required bool channel, required int members, required Duration? length}) =>
    (channel || members >= lightMinMembers) && (length ?? Duration.zero) >= lightMinLength;

/// Can this phone make smaller videos? (Not the web.)
bool get canShrinkVideo => Phone.canEditVideo;

/// Makes [bytes] [height] lines tall on the phone (null = can't here).
Future<Uint8List?> shrinkVideo(Uint8List bytes, String name, int height) =>
    Phone.editVideo(bytes, name, {'startMs': 0, 'endMs': -1, 'turns': 0, 'flip': false, 'mute': false, 'height': height});

// ---- viewer side ------------------------------------------------------

/// The light copy of one video, found among the chat's messages.
class LightCopy {
  const LightCopy({required this.msg, required this.height, required this.load});
  final Msg msg;
  final int height;
  final Future<List<int>> Function() load;
  int? get size => msg.size;
}

/// Light copies seen in open chats, by the original's pair id.
class LightIndex {
  const LightIndex._();
  static final _byPair = <String, Msg>{};

  /// A light copy: hidden from the chat, used by its original's ⚙ menu.
  static bool isLight(Msg m) => m.kind == 'video' && MediaTags.of(m.body).lightOf != null;

  static void note(Iterable<Msg> msgs) {
    for (final m in msgs) {
      final t = MediaTags.of(m.body);
      if (m.kind == 'video' && t.lightOf != null) _byPair[t.lightOf!] = m;
    }
  }

  static Msg? of(Msg original) {
    final pair = MediaTags.of(original.body).pair;
    return pair == null ? null : _byPair[pair];
  }
}

/// "자동", "원본", "가벼운 화질" (pref video_quality).
enum VideoQuality { auto, original, light }

VideoQuality videoQualityPref(AppState? s) => switch (s?.pref('video_quality', 'auto')) {
  'original' => VideoQuality.original,
  'light' => VideoQuality.light,
  _ => VideoQuality.auto,
};

/// 자동: the light copy on mobile data, the original on Wi-Fi.
bool autoPicksLight(AppState? s) => s != null && s.network == 'cellular';

/// The ⚙ panel in the player: 자동 (which one now) / 원본 / 가벼운 화질.
class QualityMenu extends StatelessWidget {
  const QualityMenu({super.key, required this.light, required this.originalSize, required this.now, required this.playingLight, required this.onPick});
  final LightCopy light;
  final int? originalSize;
  final VideoQuality now;
  final bool playingLight;
  final ValueChanged<VideoQuality> onPick;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final l = L.of(context);
    final caption = Tokens.caption.style.copyWith(color: white);
    Widget row(VideoQuality q, String title, String? sub) => GestureDetector(
      key: Key('video-quality-${q.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => onPick(q),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        child: Row(
          children: [
            SizedBox(width: 22, child: q == now ? const Icon(CupertinoIcons.checkmark_alt, color: white, size: 16) : null),
            Expanded(child: Text(title, style: Tokens.preview.style.copyWith(color: white))),
            if (sub != null) Text(sub, style: caption.copyWith(color: const Color(0xB3FFFFFF))),
          ],
        ),
      ),
    );
    return LiquidGlass(
      key: const Key('video-quality-panel'),
      radius: Tokens.radius[2],
      flat: kIsWeb,
      child: SizedBox(
        width: 250,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[2], Tokens.space[2], Tokens.space[1]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.videoQualityTitle, style: caption),
              SizedBox(height: Tokens.space[0]),
              row(VideoQuality.auto, l.videoQualityAuto, playingLight ? l.videoQualityLightShort : l.videoQualityOriginal),
              row(VideoQuality.original, l.videoQualityOriginal, originalSize == null ? null : sizeText(originalSize!)),
              row(VideoQuality.light, l.videoQualityLight(light.height), light.size == null ? null : sizeText(light.size!)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- sender side (114) ------------------------------------------------

/// The 화질 sheet: five steps, the size in big numbers, and the light-copy
/// switch. Returns null when closed without 완료.
Future<VideoSendPick?> showVideoQualitySheet(
  BuildContext context, {
  required Uint8List bytes,
  required String name,
  required VideoSendPick now,
  required bool lightAllowed,
}) => showCupertinoModalPopup<VideoSendPick>(
  context: context,
  builder: (_) => _QualitySheet(bytes: bytes, name: name, now: now, lightAllowed: lightAllowed),
);

class _QualitySheet extends StatefulWidget {
  const _QualitySheet({required this.bytes, required this.name, required this.now, required this.lightAllowed});
  final Uint8List bytes;
  final String name;
  final VideoSendPick now;
  final bool lightAllowed;

  @override
  State<_QualitySheet> createState() => _QualitySheetState();
}

class _QualitySheetState extends State<_QualitySheet> {
  late final Size? size = mp4VideoSize(widget.bytes);
  late final Duration len = Mp4Length.of(widget.bytes);

  /// Steps that make the video smaller than it is, then 원본.
  late final List<int?> steps = [
    for (final h in lightSteps)
      if (size == null || h < size!.shortestSide) h,
    null,
  ];
  late int step = () {
    final i = steps.indexOf(widget.now.height);
    return i < 0 ? steps.length - 1 : i;
  }();
  late bool light = widget.now.light;

  int? get height => steps[step];

  int get bytes => height == null ? widget.bytes.length : estimateBytes(len, height!).clamp(0, widget.bytes.length);

  String get dims {
    final s = size;
    if (s == null) return height == null ? '' : '${height}p';
    if (height == null) return '${s.width.round()}×${s.height.round()}';
    final k = height! / s.shortestSide;
    int even(double x) => (x / 2).round() * 2;
    return '${even(s.width * k)}×${even(s.height * k)}';
  }

  String clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: ClipRSuperellipse(
        borderRadius: BorderRadius.circular(30),
        child: ColoredBox(
          color: p.background,
          child: Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[3]),
            child: Column(
              key: const Key('video-quality-sheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.videoSendQuality, textAlign: TextAlign.center, style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi)),
                SizedBox(height: Tokens.space[3]),
                Text(
                  sizeText(bytes),
                  key: const Key('video-quality-mb'),
                  textAlign: TextAlign.center,
                  style: Tokens.largeTitle.style.copyWith(color: p.label),
                ),
                Text(
                  [dims, if (len > Duration.zero) clock(len), height == null ? l.videoQualityOriginal : l.videoQualityAbout].where((x) => x.isNotEmpty).join(' · '),
                  key: const Key('video-quality-dims'),
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
                SizedBox(height: Tokens.space[3]),
                Row(
                  children: [
                    Text(l.videoQualitySmall, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    Expanded(
                      child: CupertinoSlider(
                        key: const Key('video-quality-slider'),
                        value: step.toDouble(),
                        max: (steps.length - 1).toDouble(),
                        divisions: steps.length > 1 ? steps.length - 1 : null,
                        activeColor: p.accent,
                        onChanged: steps.length > 1 ? (x) => setState(() => step = x.round()) : null,
                      ),
                    ),
                    Text(l.videoQualityHigh, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
                if (widget.lightAllowed) ...[
                  SizedBox(height: Tokens.space[2]),
                  Container(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
                    decoration: ShapeDecoration(color: p.card, shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[2]))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.videoLightCopy, style: Tokens.body.style.copyWith(color: p.label)),
                              Text(l.videoLightCopySub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                            ],
                          ),
                        ),
                        CupertinoSwitch(key: const Key('video-light-switch'), value: light, activeTrackColor: p.accent, onChanged: (v) => setState(() => light = v)),
                      ],
                    ),
                  ),
                ],
                if (!canShrinkVideo) ...[
                  SizedBox(height: Tokens.space[2]),
                  Text(l.videoQualityWebNote, key: const Key('video-quality-web'), textAlign: TextAlign.center, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ],
                SizedBox(height: Tokens.space[3]),
                CupertinoButton.filled(
                  key: const Key('video-quality-done'),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: () => Navigator.pop(context, VideoSendPick(height: height, light: light && widget.lightAllowed)),
                  child: Text(l.done),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clip length from the MP4 header (0 when unknown).
class Mp4Length {
  const Mp4Length._();
  static Duration of(List<int> bytes) {
    try {
      return Mp4Meta.duration(bytes) ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }
}
