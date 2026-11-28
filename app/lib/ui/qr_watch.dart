// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// QR codes in the camera (Telegram tip 503): while the story camera (or
// the QR scanner) is open, a few frames a second are read on this phone.
// When a code shows up, yellow corner marks hug it (the iPhone camera's
// colour) and a glass capsule fades in above the shutter: what it is and
// "보기 ›". Our own codes (invite links, 대화 링크, people, message links,
// PC sign-in) open inside the app, never in a browser; any other site
// first shows its name and asks.
import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../core/app_state.dart';
import '../core/qr_read.dart';
import '../core/room_links.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_links.dart' show openChatLink;
import 'common.dart';
import 'glass.dart';
import 'invite_links.dart' show openJoinLink;
import 'ios.dart';
import 'link_pc.dart' show QrScanPage, confirmPcLink, lumaOf;
import 'story_camera.dart' show StoryCameraPage;
import 'links.dart' show openMessageLink, openWebLink;
import 'wide.dart';

/// Watches one camera for QR codes.
class QrWatcher extends ChangeNotifier {
  QrWatcher(this.camera);

  /// null in tests and the look-only demo ([fake]).
  final CameraController? camera;

  /// Tests / screenshots: pretend this was read (centre of the picture).
  @visibleForTesting
  static String? fake;

  QrHit? hit;
  QrTarget? target;

  /// Seen twice in a row: the capsule turns fully solid.
  bool sure = false;
  DateTime _seen = DateTime(2000), _last = DateTime(2000);
  bool _busy = false, _streaming = false, _paused = false, _gone = false;
  Timer? _timer;

  int get turns => kIsWeb || camera == null ? 0 : (camera!.description.sensorOrientation ~/ 90) % 4;
  bool get mirror => !kIsWeb && camera?.description.lensDirection == CameraLensDirection.front;

  Future<void> start() async {
    if (_gone) return;
    final f = fake;
    if (camera == null) {
      if (f != null) {
        _timer = Timer(const Duration(milliseconds: 600), () {
          _found(QrHit(f, const [(130, 330), (130, 170), (270, 170)], 400, 500));
          _timer = Timer(const Duration(milliseconds: 500), () => _found(QrHit(f, const [(130, 330), (130, 170), (270, 170)], 400, 500)));
        });
      }
      return;
    }
    if (kIsWeb) {
      // Browsers give no frame stream: take a quiet still now and then.
      _timer = Timer.periodic(const Duration(milliseconds: 900), (_) => _webTick());
      return;
    }
    try {
      await camera!.startImageStream(_frame);
      _streaming = true;
    } catch (_) {}
  }

  /// Before the camera takes a picture or films.
  Future<void> pause() async {
    _paused = true;
    // A still being read (web) must finish before the real picture.
    for (var i = 0; _busy && kIsWeb && i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (_streaming) {
      _streaming = false;
      try {
        await camera?.stopImageStream();
      } catch (_) {}
    }
  }

  Future<void> resume() async {
    _paused = false;
    if (!kIsWeb && camera != null && !_streaming && !_gone) await start();
  }

  void _frame(CameraImage frame) {
    final now = DateTime.now();
    if (_busy || _paused || now.difference(_last) < const Duration(milliseconds: 300)) return;
    _busy = true;
    _last = now;
    unawaited(
      compute(readQrHit, lumaOf(frame)).then((h) {
        _busy = false;
        _found(h);
      }),
    );
  }

  Future<void> _webTick() async {
    final c = camera;
    if (_busy || _paused || c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    _busy = true;
    try {
      final bytes = await (await c.takePicture()).readAsBytes();
      _found(readQrHit(greyOf(bytes)));
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void _found(QrHit? h) {
    if (_gone) return;
    final now = clock.now();
    if (h == null) {
      // Keep it a moment: one blurry frame shouldn't make it blink.
      if (hit != null && now.difference(_seen) > const Duration(milliseconds: 1500)) {
        hit = null;
        target = null;
        sure = false;
        notifyListeners();
      }
      return;
    }
    final same = hit?.text == h.text;
    if (!same) HapticFeedback.selectionClick();
    sure = same;
    hit = h;
    target = same ? target : QrTarget.of(h.text, now);
    _seen = now;
    notifyListeners();
  }

  @override
  void dispose() {
    _gone = true;
    _timer?.cancel();
    if (_streaming) {
      _streaming = false;
      unawaited(camera?.stopImageStream().catchError((_) {}));
    }
    super.dispose();
  }
}

/// A still picture (web) as grey levels, made smaller first.
(int, int, Uint8List) greyOf(Uint8List bytes) {
  var im = img.decodeImage(bytes);
  if (im == null) return (1, 1, Uint8List(1));
  if (im.width > 800) im = img.copyResize(im, width: 800);
  final out = Uint8List(im.width * im.height);
  var i = 0;
  for (final px in im) {
    out[i++] = ((px.r * 77 + px.g * 150 + px.b * 29).toInt() >> 8);
  }
  return (im.width, im.height, out);
}

/// Corner marks + capsule over a camera picture of [size].
class QrOverlay extends StatefulWidget {
  const QrOverlay({super.key, required this.watcher, required this.size, required this.bottom, required this.onClose});
  final QrWatcher watcher;
  final Size size;

  /// Capsule bottom edge, from the picture's bottom (above the shutter).
  final double bottom;

  /// Closes the camera before something opens in the app.
  final VoidCallback onClose;

  @override
  State<QrOverlay> createState() => _QrOverlayState();
}

class _QrOverlayState extends State<QrOverlay> {
  /// Public addresses: the name, once the server said it.
  final names = <String, String>{};

  @override
  void initState() {
    super.initState();
    widget.watcher.addListener(changed);
  }

  @override
  void dispose() {
    widget.watcher.removeListener(changed);
    super.dispose();
  }

  void changed() {
    if (!mounted) return;
    final t = widget.watcher.target;
    final r = t?.room;
    if (r != null && r.kind == 'public' && !names.containsKey(r.code)) {
      names[r.code] = '';
      unawaited(
        AppScope.read(context).backend.peekAddress(r.code).then((p) {
          if (mounted) setState(() => names[r.code] = p.name);
        }, onError: (_) {}),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.watcher;
    final h = w.hit, t = w.target;
    final box = h == null ? null : qrBox(h, turns: w.turns, mirror: w.mirror, boxW: widget.size.width, boxH: widget.size.height);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (box != null)
          AnimatedPositioned(
            key: const Key('qr-marks'),
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            left: box.$1 * widget.size.width,
            top: box.$2 * widget.size.height,
            width: (box.$3 - box.$1) * widget.size.width,
            height: (box.$4 - box.$2) * widget.size.height,
            child: IgnorePointer(child: CustomPaint(painter: _Marks())),
          ),
        Positioned(
          left: Tokens.space[4],
          right: Tokens.space[4],
          bottom: widget.bottom,
          // Sized to the capsule: the browser blurs the whole faded area
          // behind glass, so the fading box must be only the capsule.
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: t == null ? 0 : (w.sure ? 1 : .55),
              child: t == null
                  ? const SizedBox.shrink()
                  : _Capsule(target: t, name: names[t.room?.code ?? ''] ?? '', onTap: () => openQr(context, t, widget.onClose)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Four yellow corners (iPhone camera's QR marks).
class _Marks extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final pen = Paint()
      ..color = Palette.tileYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = Tokens.qrMarkStroke
      ..strokeCap = StrokeCap.round;
    final a = (s.shortestSide * .22).clamp(12.0, 40.0), r = Tokens.qrMarkCorner;
    void corner(Offset o, double dx, double dy) {
      final p = Path()
        ..moveTo(o.dx, o.dy + dy * a)
        ..lineTo(o.dx, o.dy + dy * r)
        ..quadraticBezierTo(o.dx, o.dy, o.dx + dx * r, o.dy)
        ..lineTo(o.dx + dx * a, o.dy);
      canvas.drawPath(p, pen);
    }

    corner(Offset.zero, 1, 1);
    corner(Offset(s.width, 0), -1, 1);
    corner(Offset(0, s.height), 1, -1);
    corner(Offset(s.width, s.height), -1, -1);
  }

  @override
  bool shouldRepaint(_Marks old) => false;
}

class _Capsule extends StatelessWidget {
  const _Capsule({required this.target, required this.name, required this.onTap});
  final QrTarget target;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    final t = target;
    final room = t.room;
    final (String title, String action, Widget icon) = switch (t.kind) {
      'room' => (
        room!.kind == 'public' ? (name.isNotEmpty ? name : '@${room.code}') : (room.name.isNotEmpty ? room.name : l.joinUnnamed),
        room.channel ? l.qrSeeChannel : l.qrSeeGroup,
        Avatar(name: room.kind == 'public' ? (name.isNotEmpty ? name : room.code) : room.name, size: Tokens.qrCapsuleIcon, squircle: true),
      ),
      'person' => (displayId(t.userId), l.qrChat, Avatar(name: displayId(t.userId).substring(1), userId: t.userId, size: Tokens.qrCapsuleIcon)),
      'chat' => (displayId(t.chat!.userId), l.qrChat, Avatar(name: displayId(t.chat!.userId).substring(1), userId: t.chat!.userId, size: Tokens.qrCapsuleIcon)),
      'message' => (l.qrMessage, l.qrSee, iconTile(Palette.tileBlue, CupertinoIcons.text_bubble_fill)),
      'pc' => (l.qrPc, l.qrConnect, iconTile(Palette.tileGrey, CupertinoIcons.device_laptop)),
      'expired' => (l.qrExpired, '', iconTile(Palette.tileRed, CupertinoIcons.clock_fill)),
      'web' => (t.host, l.qrOpenLink, iconTile(Palette.tileCyan, CupertinoIcons.globe)),
      _ => (t.raw.length > 40 ? '${t.raw.substring(0, 40)}…' : t.raw, l.qrCopyText, iconTile(Palette.tileGrey, CupertinoIcons.doc_text_fill)),
    };
    return GestureDetector(
      key: Key('qr-capsule-${t.kind}'),
      onTap: t.kind == 'expired' ? null : onTap,
      child: _Glass(
        child: Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[1] + 2, Tokens.space[1] + 2, Tokens.space[3], Tokens.space[1] + 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: Tokens.qrCapsuleIcon,
                height: Tokens.qrCapsuleIcon,
                child: FittedBox(child: icon),
              ),
              SizedBox(width: Tokens.space[2]),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: white, fontWeight: Tokens.semi),
                    ),
                    if (action.isNotEmpty)
                      Text(
                        '$action ›',
                        key: const Key('qr-capsule-action'),
                        style: Tokens.caption.style.copyWith(color: const Color(0xCCFFFFFF)),
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

/// What a tap on the capsule (or a scanned code) does.
Future<void> openQr(BuildContext context, QrTarget t, VoidCallback closeCamera) async {
  final l = L.of(context);
  final nav = Navigator.of(context, rootNavigator: !Wide.on);
  final host = nav.context;
  switch (t.kind) {
    case 'room':
      closeCamera();
      await openJoinLink(host, t.room!);
    case 'message':
      closeCamera();
      await openMessageLink(host, t.message!);
    case 'chat':
      closeCamera();
      await openChatLink(host, t.chat!);
    case 'person':
      closeCamera();
      await openChatLink(host, ChatLink(userId: t.userId));
    case 'pc':
      closeCamera();
      await confirmPcLink(host, t.raw);
    case 'web':
      // Another site: its name first, then the person decides.
      final go = await showCupertinoModalPopup<String>(
        context: context,
        useRootNavigator: !Wide.on,
        builder: (c) => IosActionSheet(
          key: const Key('qr-web-sheet'),
          title: Text(l.qrWebTitle(t.host)),
          message: Text(t.raw, maxLines: 4, overflow: TextOverflow.ellipsis),
          actions: [
            CupertinoActionSheetAction(
              key: const Key('qr-web-open'),
              isDefaultAction: true,
              onPressed: () => Navigator.pop(c, 'open'),
              child: Text(l.qrOpenLink),
            ),
            CupertinoActionSheetAction(key: const Key('qr-web-copy'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.copy)),
          ],
          cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        ),
      );
      if (go == 'copy') await Clipboard.setData(ClipboardData(text: t.raw));
      if (go == 'open') {
        closeCamera();
        if (host.mounted) await openWebLink(host, t.raw);
      }
    case 'text':
      await Clipboard.setData(ClipboardData(text: t.raw));
      if (context.mounted) showQrToast(context, l.copied);
  }
}

void showQrToast(BuildContext context, String text) {
  final o = Overlay.of(context, rootOverlay: true);
  final e = OverlayEntry(
    builder: (c) => Positioned(
      left: Tokens.space[4],
      right: Tokens.space[4],
      top: MediaQuery.paddingOf(c).top + Tokens.space[5] + Tokens.space[3],
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
          decoration: BoxDecoration(color: const Color(0xE6000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(
            text,
            style: Tokens.preview.style.copyWith(color: const Color(0xFFFFFFFF), decoration: TextDecoration.none),
          ),
        ),
      ),
    ),
  );
  o.insert(e);
  Timer(const Duration(milliseconds: 1600), () => e.mounted ? e.remove() : null);
}

/// 내 QR > QR 코드 읽기: the scanner on phones; in a browser (no frame
/// stream) the camera, which reads codes from stills.
Future<void> scanQr(BuildContext context) async {
  if (kIsWeb || StoryCameraPage.fake) {
    await openSheet<void>(context, (_) => const StoryCameraPage());
    return;
  }
  final text = await Navigator.of(
    context,
    rootNavigator: !Wide.on,
  ).push<String>(CupertinoPageRoute(fullscreenDialog: true, builder: (_) => const QrScanPage()));
  if (text == null || !context.mounted) return;
  await openQr(context, QrTarget.of(text, clock.now()), () {});
}

/// A thin strip along the screen edge: a quick pull to the right runs
/// [onSwipe] (the chat list's camera, tip 503).
class EdgeSwipe extends StatefulWidget {
  const EdgeSwipe({super.key, required this.onSwipe});
  final VoidCallback onSwipe;

  @override
  State<EdgeSwipe> createState() => _EdgeSwipeState();
}

class _EdgeSwipeState extends State<EdgeSwipe> {
  double dx = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onHorizontalDragStart: (_) => dx = 0,
    onHorizontalDragUpdate: (u) => dx += u.delta.dx,
    onHorizontalDragEnd: (e) {
      if (dx > Tokens.space[5] * 2 || (e.primaryVelocity ?? 0) > 400) {
        HapticFeedback.lightImpact();
        widget.onSwipe();
      }
      dx = 0;
    },
  );
}

/// The capsule's glass. In a browser the camera picture is a separate
/// video layer that a blur can't reach (it greys out a big box instead),
/// so there the capsule is a plain dark see-through fill.
class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => kIsWeb
      ? DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0x991C1C1E),
            borderRadius: BorderRadius.circular(Tokens.capsule),
            border: Border.all(color: const Color(0x33FFFFFF), width: .5),
          ),
          child: child,
        )
      : LiquidGlass(radius: Tokens.capsule, child: child);
}
