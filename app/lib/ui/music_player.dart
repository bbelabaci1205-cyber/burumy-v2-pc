// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Music and long audio (Telegram tips 108 + 199), drawn for core/audio_dock.dart:
// - MusicBubble: a song in a chat (round play button, title, artist, size).
// - AudioMiniBar: the thin glass bar at the top of chats while it plays
//   (play/pause, title, speed, close). Tap = the player sheet.
// - MusicPlayerSheet: cover, title, seek bar, previous / play / next,
//   repeat, speed, and the chat's songs as the play list.
// - pickSpeed: hold the speed button for 0.5×–2.5×.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/audio_dock.dart';
import '../core/backend.dart';
import '../core/search.dart' show isMusic;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart' show paletteOf;
import 'chat_page.dart' show voiceTime;
import 'glass.dart';
import 'ios.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// "1.5×" (no ".0").
String audioSpeedText(double v) => '${v == v.roundToDouble() ? v.toInt() : v}×';

/// iOS colours by the song's name (same song, same cover).
List<Color> coverColors(String name) {
  const all = [
    Palette.tileIndigo,
    Palette.tilePurple,
    Palette.tilePink,
    Palette.tileOrange,
    Palette.tileBlue,
    Palette.tileTeal,
    Palette.tileRed,
    Palette.tileCyan,
  ];
  final h = name.codeUnits.fold<int>(7, (a, c) => (a * 31 + c) & 0x7fffffff);
  return [all[h % all.length], all[(h ~/ 8 + 3) % all.length]];
}

/// The song's square cover (no album art travels with the file).
class MusicCover extends StatelessWidget {
  const MusicCover({super.key, required this.name, required this.size});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = coverColors(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: c),
      ),
      alignment: Alignment.center,
      child: Icon(CupertinoIcons.music_note_2, size: size * 0.42, color: const Color(0xFFFFFFFF)),
    );
  }
}

/// Starts the chat's songs from [m].
Future<void> playChatMusic(BuildContext context, String roomId, Msg m, String chatName) async {
  final s = AppScope.read(context);
  final dock = AudioDock.instance;
  if (dock.isCurrent(m.id)) return dock.toggle();
  final all = await s.backend.timeline(roomId, limit: 500);
  final songs = all.where((x) => isMusic(x) && !x.viewOnce && x.body != null).toList();
  if (!songs.any((x) => x.id == m.id)) songs.add(m);
  await dock.start(
    list: [for (final x in songs) Track.of(roomId, x)],
    at: songs.indexWhere((x) => x.id == m.id),
    chatName: chatName,
    download: s.backend.downloadFile,
    read: (k) => s.pref(k, ''),
    write: s.setPref,
    speed: double.tryParse(s.pref('music_speed', '1')) ?? 1,
  );
}

/// Sets the dock's speed and keeps it for next time.
Future<void> setDockSpeed(BuildContext context, double v) async {
  final s = AppScope.read(context);
  final l = L.of(context);
  await AudioDock.instance.setSpeed(v);
  unawaited(s.setPref('music_speed', '$v'));
  if (context.mounted) showStoryToast(context, v == 1 ? l.audioSpeedNormal : l.audioSpeedSet(audioSpeedText(v).replaceAll('×', '')));
}

/// Hold the speed button: every speed to pick from.
Future<double?> pickSpeed(BuildContext context, double now) {
  final l = L.of(context);
  return showCupertinoModalPopup<double>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.audioSpeedTitle),
      actions: [
        for (final v in AudioDock.speeds)
          CupertinoActionSheetAction(
            key: Key('speed-$v'),
            isDefaultAction: v == now,
            onPressed: () => Navigator.pop(c, v),
            child: Text(v == 1 ? '${audioSpeedText(v)} · ${l.audioSpeedPlain}' : audioSpeedText(v)),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

/// A song in a chat.
class MusicBubble extends StatelessWidget {
  const MusicBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta, required this.chatTitle});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final String chatTitle;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final t = Track.of(roomId, msg);
    final mine = msg.mine;
    return ListenableBuilder(
      listenable: AudioDock.instance,
      builder: (context, _) {
        final dock = AudioDock.instance;
        final here = dock.isCurrent(msg.id);
        final busy = here && dock.loading;
        final len = here ? dock.duration : null;
        final done = len == null || len.inMilliseconds == 0 ? 0.0 : (dock.position.inMilliseconds / len.inMilliseconds).clamp(0.0, 1.0);
        final sub = [
          if (t.artist != null) t.artist!,
          if (here && len != null) '${voiceTime(dock.position)} / ${voiceTime(len)}' else if (msg.size != null) _size(msg.size!),
        ].join(' · ');
        return Row(
          key: Key('music-${msg.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: Key('music-play-${msg.id}'),
              onTap: () => playChatMusic(context, roomId, msg, chatTitle),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: mine ? p.onAccent : p.accent, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: busy
                    ? CupertinoActivityIndicator(radius: 9, color: mine ? p.accent : p.onAccent)
                    : Icon(
                        here && dock.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                        size: 20,
                        color: mine ? p.accent : p.onAccent,
                        semanticLabel: here && dock.playing ? l.audioPause : l.audioPlay,
                      ),
              ),
            ),
            SizedBox(width: Tokens.space[1]),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                    ),
                    if (here)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: Stack(
                              children: [
                                Container(color: fg.withValues(alpha: 0.2)),
                                FractionallySizedBox(
                                  widthFactor: done,
                                  child: Container(color: fg),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                          ),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        meta,
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _size(int b) => b < 1024 * 1024 ? '${(b / 1024).toStringAsFixed(0)} KB' : '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Thin glass bar at the top of chats while music plays.
class AudioMiniBar extends StatelessWidget {
  const AudioMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AudioDock.instance,
      builder: (context, _) {
        final dock = AudioDock.instance;
        final t = dock.current;
        if (t == null) return const SizedBox.shrink();
        final p = paletteOf(context);
        final l = L.of(context);
        final len = dock.duration;
        final done = len == null || len.inMilliseconds == 0 ? 0.0 : (dock.position.inMilliseconds / len.inMilliseconds).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], 0),
          child: GestureDetector(
            key: const Key('audio-mini'),
            behavior: HitTestBehavior.opaque,
            onTap: () => openMusicPlayer(context),
            onVerticalDragEnd: (d) {
              if ((d.primaryVelocity ?? 0) > 200) openMusicPlayer(context);
            },
            child: LiquidGlass(
              radius: Tokens.radius[2],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        CupertinoButton(
                          key: const Key('audio-mini-play'),
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                          minimumSize: const Size(44, 44),
                          onPressed: dock.toggle,
                          child: dock.loading
                              ? const CupertinoActivityIndicator(radius: 9)
                              : Icon(
                                  dock.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                  color: p.accent,
                                  semanticLabel: dock.playing ? l.audioPause : l.audioPlay,
                                ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                key: const Key('audio-mini-title'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.preview.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                t.artist ?? dock.chatName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                        SpeedButton(compact: true),
                        CupertinoButton(
                          key: const Key('audio-mini-close'),
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                          minimumSize: const Size(44, 44),
                          onPressed: dock.close,
                          child: Icon(CupertinoIcons.xmark, size: 18, color: p.secondaryLabel, semanticLabel: l.close),
                        ),
                      ],
                    ),
                  ),
                  // How far along, as a hairline under the bar.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: done,
                      child: Container(height: 2, color: p.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// "1×" button: tap = 1× → 1.5× → 2×, hold = every speed.
class SpeedButton extends StatelessWidget {
  const SpeedButton({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final dock = AudioDock.instance;
    final on = dock.speed != 1;
    return GestureDetector(
      key: const Key('audio-speed'),
      behavior: HitTestBehavior.opaque,
      onTap: () => setDockSpeed(context, dock.nextSpeed),
      onLongPress: () async {
        final v = await pickSpeed(context, dock.speed);
        if (v != null && context.mounted) await setDockSpeed(context, v);
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: on ? p.accent : null,
            border: Border.all(color: on ? p.accent : p.secondaryLabel, width: 1.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            audioSpeedText(dock.speed),
            style: (compact ? Tokens.caption : Tokens.preview).style.copyWith(color: on ? p.onAccent : p.secondaryLabel, fontWeight: Tokens.semi),
          ),
        ),
      ),
    );
  }
}

Future<void> openMusicPlayer(BuildContext context) =>
    showCupertinoModalPopup<void>(useRootNavigator: !Wide.on, context: context, builder: (_) => const MusicPlayerSheet());

class MusicPlayerSheet extends StatefulWidget {
  const MusicPlayerSheet({super.key});

  @override
  State<MusicPlayerSheet> createState() => _MusicPlayerSheetState();
}

class _MusicPlayerSheetState extends State<MusicPlayerSheet> {
  /// While dragging the seek bar (the sound jumps on release).
  double? dragging;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    final h = MediaQuery.sizeOf(context).height;
    return ListenableBuilder(
      listenable: AudioDock.instance,
      builder: (context, _) {
        final dock = AudioDock.instance;
        final t = dock.current;
        if (t == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }
        final len = dock.duration ?? Duration.zero;
        final total = len.inMilliseconds == 0 ? 1 : len.inMilliseconds;
        final at = dragging ?? (dock.position.inMilliseconds / total).clamp(0.0, 1.0);
        final shownAt = Duration(milliseconds: (at * total).round());
        return Container(
          key: const Key('music-player'),
          constraints: BoxConstraints(maxHeight: h * 0.9),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Tokens.radius[3])),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: Tokens.space[1]),
                Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(3)),
                ),
                SizedBox(height: Tokens.space[3]),
                MusicCover(name: t.name, size: 180),
                SizedBox(height: Tokens.space[3]),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                  child: Column(
                    children: [
                      Text(
                        t.title,
                        key: const Key('music-player-title'),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: Tokens.cardTitle.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: Tokens.space[0]),
                      Text(
                        t.artist ?? dock.chatName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.body.style.copyWith(color: p.secondaryLabel),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Tokens.space[2]),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoSlider(
                          key: const Key('music-seek'),
                          value: at,
                          activeColor: p.accent,
                          onChanged: len == Duration.zero ? null : (v) => setState(() => dragging = v),
                          onChangeEnd: (v) {
                            setState(() => dragging = null);
                            unawaited(dock.seek(Duration(milliseconds: (v * total).round())));
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Text(voiceTime(shownAt), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                          const Spacer(),
                          Text('-${voiceTime(len - shownAt)}', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        key: const Key('music-repeat'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: () {
                          dock.cycleRepeat();
                          showStoryToast(context, switch (dock.repeat) {
                            Repeat.off => l.audioRepeatOff,
                            Repeat.all => l.audioRepeatAll,
                            Repeat.one => l.audioRepeatOne,
                          });
                        },
                        child: Icon(
                          dock.repeat == Repeat.one ? CupertinoIcons.repeat_1 : CupertinoIcons.repeat,
                          color: dock.repeat == Repeat.off ? p.secondaryLabel : p.accent,
                          semanticLabel: l.audioRepeat,
                        ),
                      ),
                      CupertinoButton(
                        key: const Key('music-prev'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(56, 56),
                        onPressed: dock.previous,
                        child: Icon(CupertinoIcons.backward_fill, size: 30, color: p.label, semanticLabel: l.audioPrevious),
                      ),
                      CupertinoButton(
                        key: const Key('music-toggle'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(72, 72),
                        onPressed: dock.toggle,
                        child: dock.loading
                            ? const CupertinoActivityIndicator(radius: 14)
                            : Icon(
                                dock.playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                                size: 44,
                                color: p.label,
                                semanticLabel: dock.playing ? l.audioPause : l.audioPlay,
                              ),
                      ),
                      CupertinoButton(
                        key: const Key('music-next'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(56, 56),
                        onPressed: dock.index < dock.queue.length - 1 || dock.repeat == Repeat.all ? dock.next : null,
                        child: Icon(
                          CupertinoIcons.forward_fill,
                          size: 30,
                          color: dock.index < dock.queue.length - 1 || dock.repeat == Repeat.all ? p.label : p.secondaryLabel,
                          semanticLabel: l.audioNext,
                        ),
                      ),
                      const SpeedButton(),
                    ],
                  ),
                ),
                if (dock.queue.length > 1) ...[
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[1]),
                    child: Row(
                      children: [
                        Text(
                          l.audioPlaylist(dock.queue.length),
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontWeight: Tokens.semi),
                        ),
                        const Spacer(),
                        Text(
                          dock.chatName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      key: const Key('music-list'),
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: Tokens.space[2]),
                      itemCount: dock.queue.length,
                      itemBuilder: (context, i) {
                        final x = dock.queue[i];
                        final now = i == dock.index;
                        return GestureDetector(
                          key: Key('music-row-$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => now ? dock.toggle() : dock.jump(i),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                            child: Row(
                              children: [
                                MusicCover(name: x.name, size: 40),
                                SizedBox(width: Tokens.space[2]),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        x.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.body.style.copyWith(color: now ? p.accent : p.label, fontWeight: now ? FontWeight.w500 : FontWeight.w400),
                                      ),
                                      if (x.artist != null)
                                        Text(
                                          x.artist!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                        ),
                                    ],
                                  ),
                                ),
                                if (now) Icon(dock.playing ? CupertinoIcons.speaker_2_fill : CupertinoIcons.pause, size: 18, color: p.accent),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  SizedBox(height: Tokens.space[3]),
              ],
            ),
          ),
        );
      },
    );
  }
}
