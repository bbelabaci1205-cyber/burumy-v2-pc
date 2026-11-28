// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Burumy bubbles: a friend's photo, voice or emoji arrives as a closed soap
// bubble (only the friend's colour shows). Tap to pop: it opens once.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/screen_guard.dart';
import '../core/backend.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show ChatPageMime, voiceTime;
import 'common.dart';
import 'glass.dart';
import 'ios_route.dart';

/// Our own water drop (Eric 2026-11-26): filled with the app colour
/// (green, or blue with the blue 내 색상 — Eric picked '꽉 찬' over the
/// pastel glass so it reads even at 18 pt), a bright rim, a white shine
/// and a soft wobble like iPhone liquid glass. Nothing inside is ever drawn. Still when 절전 is on, when
/// the phone asks for less motion, and in tests.
class SoapBubble extends StatefulWidget {
  const SoapBubble({super.key, required this.color, this.size = 56, this.letter, this.phase = 0});
  final Color color;
  final double size;
  final String? letter;

  /// Where in the wobble this one starts, so bubbles side by side differ.
  final double phase;

  /// Tests run with the wobble frozen (it never settles).
  static bool get still => !testMotion && WidgetsBinding.instance.runtimeType.toString().contains('Test');

  /// A screenshot test can switch the wobble on.
  static bool testMotion = false;

  @override
  State<SoapBubble> createState() => _SoapBubbleState();
}

class _SoapBubbleState extends State<SoapBubble> with SingleTickerProviderStateMixin {
  late final wobble = AnimationController(vsync: this, duration: const Duration(milliseconds: 3600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
    final calm = (app?.calm ?? false) || (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || SoapBubble.still;
    if (calm) {
      wobble.stop();
    } else if (!wobble.isAnimating) {
      wobble.repeat();
    }
  }

  @override
  void dispose() {
    wobble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BubblePainter(widget.color, wobble, widget.phase),
        child: widget.letter == null
            ? null
            : Center(
                child: Text(
                  widget.letter!,
                  style: TextStyle(fontSize: size * 0.34, color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w500),
                ),
              ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color, this.t, this.phase) : super(repaint: t);
  final Color color;
  final Animation<double> t;
  final double phase;

  static const white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final a = (t.value + phase) * 2 * math.pi;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * 0.94;
    // The wobbling outline: a circle with two slow waves running round it.
    final path = Path();
    const n = 64;
    for (var i = 0; i <= n; i++) {
      final th = i / n * 2 * math.pi;
      final rr = r * (1 + 0.035 * math.sin(3 * th + a) + 0.025 * math.sin(2 * th - a * 2));
      final pt = c + Offset(math.cos(th) * rr, math.sin(th) * rr);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    final rect = Rect.fromCircle(center: c, radius: r);
    // Soft coloured glow under the drop.
    canvas.drawPath(
      path.shift(Offset(0, r * 0.08)),
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );
    // Body: the app colour all through, a little lighter where the light hits.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          radius: 1.05,
          colors: [Color.lerp(color, white, 0.4)!, color.withValues(alpha: 0.92), color, color],
          stops: const [0.0, 0.45, 0.8, 1.0],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipPath(path);
    // Light coming through the bottom (glass caustic).
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(r * 0.1, r * 0.62), width: r * 1.2, height: r * 0.5),
      Paint()
        ..color = white.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
    );
    canvas.restore();
    // Rim: bright at the top left, the colour at the bottom right.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, r * 0.06)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [white.withValues(alpha: 0.95), white.withValues(alpha: 0.15), color],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
    // Shine, drifting a little with the wobble.
    final drift = Offset(math.sin(a) * r * 0.03, math.cos(a) * r * 0.03);
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.36, -r * 0.44) + drift, width: r * 0.58, height: r * 0.3),
      Paint()
        ..color = white.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.03),
    );
    canvas.drawCircle(c + Offset(r * 0.44, r * 0.4) - drift, r * 0.06, Paint()..color = white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.color != color || old.phase != phase;
}

String bubbleName(List<ChatPreview> chats, BubbleRef b) => chats.where((c) => c.roomId == b.roomId).firstOrNull?.name ?? displayId(b.from);

Future<void> popBubble(BuildContext context, String roomId, String id, String name) async {
  final s = AppScope.of(context);
  await Navigator.of(context, rootNavigator: true).push(
    IosPageRoute(
      fullscreenDialog: true,
      builder: (_) => BubblePopPage(roomId: roomId, id: id, name: name),
    ),
  );
  await s.refresh();
}

/// Pops the bubble: opens once, then it is gone for good.
class BubblePopPage extends StatefulWidget {
  const BubblePopPage({super.key, required this.roomId, required this.id, required this.name});
  final String roomId;
  final String id;
  final String name;

  @override
  State<BubblePopPage> createState() => _BubblePopPageState();
}

class _BubblePopPageState extends State<BubblePopPage> {
  Future<(Msg?, List<int>)>? opened;
  VoicePlayer? player;
  bool playing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    opened ??= () async {
      final b = AppScope.of(context).backend;
      final msg = (await b.timeline(widget.roomId, limit: 200)).where((m) => m.id == widget.id).firstOrNull;
      final bytes = await b.openViewOnce(widget.roomId, widget.id);
      return (msg, bytes);
    }();
  }

  @override
  void dispose() {
    player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(widget.name),
        leading: CupertinoButton(
          key: const Key('bubble-close'),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(CupertinoIcons.xmark, color: p.label),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: CaptureBlock(
        what: 'bubble',
        child: SafeArea(
          child: FutureBuilder<(Msg?, List<int>)>(
            future: opened,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                  child: Text(l.bubbleGone, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                );
              }
              final got = snap.data;
              if (got == null) return const Center(child: CupertinoActivityIndicator());
              final (msg, bytes) = got;
              final kind = msg?.kind ?? 'text';
              final Widget inside = switch (kind) {
                'image' => ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.radius[2]),
                  child: Image.memory(Uint8List.fromList(bytes), key: const Key('bubble-photo'), fit: BoxFit.contain),
                ),
                'audio' => CupertinoButton(
                  key: const Key('bubble-voice'),
                  onPressed: () async {
                    final pl = player ??= VoiceKit.player();
                    await pl.play(Uint8List.fromList(bytes), widget.id);
                    setState(() => playing = true);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.play_circle_fill, size: 88, color: p.accent),
                      if (msg?.voice != null) Text(voiceTime(msg!.voice!.duration), style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                ),
                _ => Text(utf8.decode(bytes, allowMalformed: true), key: const Key('bubble-emoji'), style: const TextStyle(fontSize: 120)),
              };
              return Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(padding: EdgeInsets.all(Tokens.space[3]), child: inside),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(Tokens.space[3]),
                    child: Text(
                      l.bubbleOnce,
                      textAlign: TextAlign.center,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Make a bubble for a friend: an emoji, a photo or a short voice clip.
class SendBubblePage extends StatefulWidget {
  const SendBubblePage({super.key, required this.roomId, required this.name});
  final String roomId;
  final String name;

  @override
  State<SendBubblePage> createState() => _SendBubblePageState();
}

class _SendBubblePageState extends State<SendBubblePage> {
  static const emojis = ['🥳', '😘', '😂', '🥺', '😴', '🔥', '❤️', '👍', '🎉', '🌙', '☕', '🍀'];
  VoiceRecorder? recorder;
  DateTime? recStart;
  Timer? tick;
  bool busy = false;

  @override
  void dispose() {
    tick?.cancel();
    final r = recorder;
    if (r != null) unawaited(r.cancel());
    super.dispose();
  }

  Future<void> send(String kind, String mime, List<int> bytes) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend.sendBubble(widget.roomId, kind, mime, bytes);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> toggleRecord() async {
    final r = recorder;
    if (r == null) {
      final n = VoiceKit.recorder();
      if (!await n.start()) return;
      setState(() {
        recorder = n;
        recStart = DateTime.now();
      });
      tick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
      return;
    }
    tick?.cancel();
    setState(() {
      recorder = null;
      recStart = null;
    });
    final got = await r.stop();
    if (got != null) await send('voice', got.mime, got.bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final color = Avatar.colorFor(widget.name);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.bubbleSendTitle),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[3]),
          children: [
            Center(child: SoapBubble(color: color, size: 110)),
            SizedBox(height: Tokens.space[2]),
            Text(
              l.bubbleSendInfo(widget.name),
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
            SizedBox(height: Tokens.space[3]),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final e in emojis)
                  CupertinoButton(
                    key: Key('bubble-emoji-$e'),
                    padding: EdgeInsets.zero,
                    onPressed: busy ? null : () => send('emoji', 'text/plain', utf8.encode(e)),
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ),
              ],
            ),
            SizedBox(height: Tokens.space[3]),
            Row(
              children: [
                Expanded(
                  child: _BigButton(
                    key: const Key('bubble-photo-pick'),
                    icon: CupertinoIcons.photo,
                    label: l.attachPhoto,
                    onTap: busy
                        ? null
                        : () async {
                            final x = await ImagePicker().pickMedia();
                            if (x != null) await send('photo', ChatPageMime.of(x.name), await x.readAsBytes());
                          },
                  ),
                ),
                if (VoiceKit.canRecord) ...[
                  SizedBox(width: Tokens.space[2]),
                  Expanded(
                    child: _BigButton(
                      key: const Key('bubble-voice-rec'),
                      icon: recorder == null ? CupertinoIcons.mic_fill : CupertinoIcons.stop_fill,
                      label: recorder == null ? l.bubbleRecord : voiceTime(DateTime.now().difference(recStart ?? DateTime.now())),
                      onTap: busy ? null : toggleRecord,
                      active: recorder != null,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({super.key, required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: active ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          children: [
            Icon(icon, color: active ? p.onAccent : p.accent, size: 26),
            const SizedBox(height: 4),
            Text(label, style: Tokens.preview.style.copyWith(color: active ? p.onAccent : p.label)),
          ],
        ),
      ),
    );
  }
}

/// The bubble inside the chat: closed (tap to pop) or popped.
class BubbleMsg extends StatelessWidget {
  const BubbleMsg({super.key, required this.msg, required this.roomId, required this.name, required this.fg, required this.meta});
  final Msg msg;
  final String roomId;
  final String name;
  final Color fg;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final canPop = !msg.mine && !msg.opened;
    final label = msg.opened ? l.bubblePopped : (msg.mine ? l.bubbleSent : l.bubbleTapToPop);
    return GestureDetector(
      key: const Key('bubble-msg'),
      onTap: canPop ? () => popBubble(context, roomId, msg.id, name) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: msg.opened ? 0.35 : 1,
            child: SoapBubble(color: Avatar.colorFor(name), size: 40),
          ),
          SizedBox(width: Tokens.space[1]),
          Flexible(
            child: Text(label, style: Tokens.body.style.copyWith(color: fg)),
          ),
          SizedBox(width: Tokens.space[1]),
          meta,
        ],
      ),
    );
  }
}

/// Puts the waiting bubbles on the home-screen widget: only a colour and
/// the first letter of each friend's name. Never the photo, voice or emoji.
class HomeBubbles {
  static const appGroup = 'group.app.burumy.bubbles';

  static void publish(List<BubbleRef> bubbles, List<ChatPreview> chats) {
    if (kIsWeb) return;
    final list = [
      for (final b in bubbles.take(6))
        () {
          final name = bubbleName(chats, b);
          return {'c': Avatar.colorFor(name).toARGB32().toRadixString(16), 'l': name.characters.first};
        }(),
    ];
    unawaited(() async {
      try {
        await HomeWidget.setAppGroupId(appGroup);
        await HomeWidget.saveWidgetData<String>('bubbles', jsonEncode(list));
        await HomeWidget.saveWidgetData<int>('bubble_count', bubbles.length);
        await HomeWidget.updateWidget(androidName: 'BubbleWidgetProvider', iOSName: 'BubbleWidget');
      } catch (_) {
        // No widget support on this platform (desktop): nothing to do.
      }
    }());
  }
}
