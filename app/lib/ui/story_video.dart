// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// A story video: plays from memory (a data link on the web, a temp file on
// phones), fills its box like a photo, and tells the viewer how long it is.
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

/// Mime type from a file name (the composer keeps names like story.mp4).
String storyMime(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.mp4') || n.endsWith('.m4v')) return 'video/mp4';
  if (n.endsWith('.mov')) return 'video/quicktime';
  if (n.endsWith('.webm')) return 'video/webm';
  return 'image/jpeg';
}

bool isStoryVideo(String name) => storyMime(name).startsWith('video/');

class StoryVideo extends StatefulWidget {
  const StoryVideo({super.key, required this.bytes, required this.mime, this.loop = false, this.onReady, this.speed = 1});

  /// Settings speed (round videos use the player's remembered speed).
  final double speed;
  final Uint8List bytes;
  final String mime;
  final bool loop;

  /// Called once the video can play, with its controller (to pause / resume).
  final void Function(VideoPlayerController c)? onReady;

  @override
  State<StoryVideo> createState() => _StoryVideoState();
}

class _StoryVideoState extends State<StoryVideo> {
  VideoPlayerController? c;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    open();
  }

  Future<void> open() async {
    try {
      final VideoPlayerController v;
      if (kIsWeb) {
        v = VideoPlayerController.networkUrl(Uri.dataFromBytes(widget.bytes, mimeType: widget.mime));
      } else {
        final dir = await getTemporaryDirectory();
        final ext = widget.mime.endsWith('quicktime') ? 'mov' : (widget.mime.endsWith('webm') ? 'webm' : 'mp4');
        final f = File('${dir.path}/story-${widget.bytes.length}-${identityHashCode(widget.bytes)}.$ext');
        await f.writeAsBytes(widget.bytes, flush: true);
        v = VideoPlayerController.file(f);
      }
      await v.initialize();
      await v.setLooping(widget.loop);
      if (widget.speed != 1) await v.setPlaybackSpeed(widget.speed);
      if (!mounted) {
        await v.dispose();
        return;
      }
      setState(() => c = v);
      widget.onReady?.call(v);
      await v.play();
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = c;
    if (v == null) {
      return Center(
        child: failed ? const Icon(CupertinoIcons.play_circle, color: Color(0xFFFFFFFF), size: 56) : const CupertinoActivityIndicator(color: Color(0xFFFFFFFF)),
      );
    }
    final size = v.value.size;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: size.width, height: size.height, child: VideoPlayer(v)),
    );
  }
}
