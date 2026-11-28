// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Story camera, laid out like Telegram's iOS story camera: a full-screen
// live picture with round corners, grid / both-sides / flash / close at the
// top right, the white shutter, and at the bottom the gallery, the
// 라이브 · 영상 · 사진 switch and the flip button.
//
// - 사진: one tap. 영상: tap to start and stop (60 s at most).
// - 그리드 (collage): pick a layout, then fill the boxes one by one.
// - 앞뒤 동시: the back camera, then the front one right after; the front
//   photo goes in a circle you can move. (Phones can't run both cameras at
//   once through Flutter's camera, so the two are taken back to back.)
// - 라이브 needs our own broadcast server, so it only says when it opens.
//
// The camera runs only while this screen is open and in front; pictures
// stay on the phone until you share them.
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'glass.dart';
import 'ios_route.dart';
import 'qr_watch.dart';
import 'stories.dart';
import 'wide.dart';

enum CamMode { live, video, photo }

/// Collage layouts (parts of the screen, 0..1), Telegram's order.
const storyLayouts = <List<Rect>>[
  [Rect.fromLTWH(0, 0, 1, .5), Rect.fromLTWH(0, .5, 1, .5)],
  [Rect.fromLTWH(0, 0, .5, 1), Rect.fromLTWH(.5, 0, .5, 1)],
  [Rect.fromLTWH(0, 0, .5, .5), Rect.fromLTWH(.5, 0, .5, .5), Rect.fromLTWH(0, .5, .5, .5), Rect.fromLTWH(.5, .5, .5, .5)],
  [Rect.fromLTWH(0, 0, 1, .5), Rect.fromLTWH(0, .5, .5, .5), Rect.fromLTWH(.5, .5, .5, .5)],
  [Rect.fromLTWH(0, 0, 1, 1 / 3), Rect.fromLTWH(0, 1 / 3, 1, 1 / 3), Rect.fromLTWH(0, 2 / 3, 1, 1 / 3)],
  [
    Rect.fromLTWH(0, 0, .5, 1 / 3),
    Rect.fromLTWH(.5, 0, .5, 1 / 3),
    Rect.fromLTWH(0, 1 / 3, .5, 1 / 3),
    Rect.fromLTWH(.5, 1 / 3, .5, 1 / 3),
    Rect.fromLTWH(0, 2 / 3, .5, 1 / 3),
    Rect.fromLTWH(.5, 2 / 3, .5, 1 / 3),
  ],
];

/// Sizes measured on Telegram's story camera (iPhone, points).
class CamSize {
  static const bar =
          48.0, // gallery / mode switch / flip row
      barGap =
          16.0, // between the picture and that row
      shutter = 72.0,
      shutterLift =
          17.0, // shutter bottom above the picture bottom
      segment = 66.0,
      dual = 160.0,
      liveButton = 52.0,
      maxVideo = Duration(seconds: 60);
}

class StoryCameraPage extends StatefulWidget {
  const StoryCameraPage({super.key, this.room = '', this.roomName = '', this.capture = false, this.video = false});

  /// A group's or channel's story (tip 428): that room; '' = my own.
  final String room, roomName;

  /// 채널 짧은 영상 (4-app board, WhatsApp 2025): the camera only takes the
  /// picture or clip and pops with it as (name, bytes), for the attach
  /// sheet. No story editor, no 라이브.
  final bool capture;

  /// Opens on 영상 instead of 사진.
  final bool video;

  /// Tests and screenshots without a camera: a painted scene stands in.
  static bool fake = false;

  @override
  State<StoryCameraPage> createState() => _StoryCameraPageState();
}

class _StoryCameraPageState extends State<StoryCameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cams = const [];
  CameraController? ctl;
  CameraLensDirection lens = CameraLensDirection.back;
  bool starting = true, unavailable = false, busy = false;
  CamMode mode = CamMode.photo;
  FlashMode flash = FlashMode.off;

  /// Front camera "flash" = the screen lights up (TelegramTips 404).
  /// Hold the ⚡ button to set its warmth and brightness (kept on this
  /// phone only).
  bool flashPanel = false, screenFlash = false;
  double get flashWarm => double.tryParse(AppScope.read(context).pref('front_flash_warm', '0.4')) ?? .4;
  double get flashBright => double.tryParse(AppScope.read(context).pref('front_flash_bright', '1')) ?? 1;
  bool get frontFlashOn => lens == CameraLensDirection.front && flash != FlashMode.off;
  bool dual = false, pickingGrid = false;
  int? layout;
  List<Uint8List?> cells = const [];
  Uint8List? frontShot;
  Offset dualAt = const Offset(.25, .72); // circle centre, part of the picture
  bool recording = false;
  final watch = Stopwatch();
  Timer? tick;
  double zoom = 1, zoomStart = 1, minZoom = 1, maxZoom = 1;
  Offset swipe = Offset.zero;
  int pointers = 0;
  int fakeShots = 0;

  /// QR codes in the picture (tip 503): on in plain photo mode only.
  QrWatcher? qr;

  bool get qrWanted =>
      Features.shareLinks && mode == CamMode.photo && layout == null && !dual && !recording && (StoryCameraPage.fake || (ctl?.value.isInitialized ?? false));

  /// Starts or stops the QR watcher to match the camera and mode.
  void syncQr() {
    if (!mounted) return;
    final want = qrWanted;
    if (want && qr != null && qr!.camera == (StoryCameraPage.fake ? null : ctl)) return;
    if (!want && qr == null) return;
    dropQr();
    if (want) {
      qr = QrWatcher(StoryCameraPage.fake ? null : ctl);
      unawaited(qr!.start());
    }
    setState(() {});
  }

  void dropQr() {
    qr?.dispose();
    qr = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.video) mode = CamMode.video;
    start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tick?.cancel();
    dropQr();
    ctl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    // The camera is on only while this screen is in front.
    if (StoryCameraPage.fake || unavailable) return;
    if (st == AppLifecycleState.inactive || st == AppLifecycleState.paused) {
      final c = ctl;
      ctl = null;
      dropQr();
      c?.dispose();
      if (mounted) setState(() {});
    } else if (st == AppLifecycleState.resumed && ctl == null) {
      open(lens);
    }
  }

  Future<void> start() async {
    if (StoryCameraPage.fake) {
      setState(() => starting = false);
      return;
    }
    try {
      cams = await availableCameras();
    } catch (_) {
      cams = const [];
    }
    if (!mounted) return;
    if (cams.isEmpty) {
      setState(() {
        unavailable = true;
        starting = false;
      });
      return;
    }
    await open(CameraLensDirection.back);
  }

  CameraDescription? camFor(CameraLensDirection d) => cams.where((c) => c.lensDirection == d).firstOrNull;

  Future<void> open(CameraLensDirection d) async {
    final desc = camFor(d) ?? cams.firstOrNull;
    if (desc == null) return;
    final old = ctl;
    dropQr();
    setState(() {
      ctl = null;
      starting = true;
    });
    await old?.dispose();
    final c = CameraController(desc, ResolutionPreset.high, enableAudio: mode == CamMode.video);
    try {
      await c.initialize();
      try {
        minZoom = await c.getMinZoomLevel();
        maxZoom = await c.getMaxZoomLevel();
      } catch (_) {
        minZoom = maxZoom = 1;
      }
      zoom = minZoom;
      try {
        await c.setFlashMode(flash);
      } catch (_) {}
    } catch (_) {
      await c.dispose();
      if (mounted) {
        setState(() {
          unavailable = true;
          starting = false;
        });
      }
      return;
    }
    if (!mounted) {
      await c.dispose();
      return;
    }
    setState(() {
      ctl = c;
      lens = desc.lensDirection;
      starting = false;
    });
  }

  bool get canFlip => StoryCameraPage.fake || (camFor(CameraLensDirection.front) != null && camFor(CameraLensDirection.back) != null);

  Future<void> flip() async {
    if (recording || busy) return;
    final to = lens == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
    if (StoryCameraPage.fake) {
      setState(() => lens = to);
      return;
    }
    if (!canFlip) return;
    await open(to);
  }

  Future<void> setMode(CamMode m) async {
    if (recording || m == mode) return;
    final audioChange = (m == CamMode.video) != (mode == CamMode.video);
    setState(() {
      mode = m;
      if (m != CamMode.photo) {
        layout = null;
        pickingGrid = false;
        dual = false;
      }
    });
    if (audioChange && !StoryCameraPage.fake && !unavailable) await open(lens);
  }

  Future<void> cycleFlash() async {
    final next = switch (flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.always,
      _ => FlashMode.off,
    };
    setState(() => flash = next);
    try {
      await ctl?.setFlashMode(next);
    } catch (_) {}
  }

  void toggleDual() {
    final l = L.of(context);
    setState(() {
      dual = !dual;
      if (dual) {
        layout = null;
        pickingGrid = false;
      }
    });
    if (dual) showStoryToast(context, l.camDualHint);
  }

  void chooseLayout(int? i) {
    setState(() {
      if (i == null || i == layout) {
        layout = null;
        cells = const [];
        pickingGrid = i == null ? false : pickingGrid;
      } else {
        layout = i;
        cells = List.filled(storyLayouts[i].length, null);
        dual = false;
      }
    });
  }

  int get nextCell => cells.indexWhere((c) => c == null);

  // ---- taking pictures ----

  Future<Uint8List?> snap() async {
    if (StoryCameraPage.fake) return fakePhoto(fakeShots++, front: lens == CameraLensDirection.front);
    final c = ctl;
    if (c == null || !c.value.isInitialized) return null;
    await qr?.pause();
    try {
      final x = await c.takePicture();
      return await x.readAsBytes();
    } finally {
      unawaited(qr?.resume());
    }
  }

  Future<Uint8List?> snapFront() async {
    if (StoryCameraPage.fake) return fakePhoto(fakeShots++, front: true);
    if (camFor(CameraLensDirection.front) == null) return null;
    final back = lens;
    await open(CameraLensDirection.front);
    // Give the front camera a moment to set its light.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final b = await snap();
    await open(back);
    return b;
  }

  Future<void> shoot() async {
    final l = L.of(context);
    if (busy) return;
    if (mode == CamMode.live) {
      showStoryToast(context, l.camLiveLater);
      return;
    }
    if (unavailable && !StoryCameraPage.fake) {
      await pickFrom(ImageSource.camera);
      return;
    }
    if (mode == CamMode.video) {
      await (recording ? stopVideo() : startVideo());
      return;
    }
    setState(() {
      busy = true;
      pickingGrid = false;
    });
    try {
      final b = await flashed(snap);
      if (b == null) return;
      if (layout != null) {
        final next = [...cells];
        next[nextCell] = b;
        setState(() => cells = next);
        if (nextCell < 0) {
          final out = await composeStory(cells: [for (final c in cells) c!], layout: storyLayouts[layout!]);
          await compose(('story.png', out));
        }
        return;
      }
      if (dual) {
        final f = await snapFront();
        if (f != null) {
          if (mounted) setState(() => frontShot = f);
          final out = await composeStory(cells: [b], layout: const [Rect.fromLTWH(0, 0, 1, 1)], front: f, frontAt: dualAt, frontPart: CamSize.dual / 393);
          await compose(('story.png', out));
          return;
        }
      }
      await compose(('story.jpg', b));
    } catch (_) {
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  /// Front camera + flash: the screen glows in the chosen colour while the
  /// picture is taken (iPhone front cameras have no lamp).
  Future<T> flashed<T>(Future<T> Function() take) async {
    if (!frontFlashOn) return take();
    setState(() => screenFlash = true);
    await Future<void>.delayed(const Duration(milliseconds: 260));
    try {
      return await take();
    } finally {
      if (mounted) setState(() => screenFlash = false);
    }
  }

  /// The glow colour: white warmed towards amber.
  Color flashColor() => Color.lerp(const Color(0xFFFFFFFF), Palette.flashWarm, flashWarm)!;

  Widget flashSlider({required Key key, required String label, required double value, required ValueChanged<double> onChanged}) {
    return LayoutBuilder(
      builder: (context, box) {
        void at(Offset o) => onChanged((o.dx / box.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          key: key,
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => at(d.localPosition),
          onTapDown: (d) => at(d.localPosition),
          child: LiquidGlass(
            radius: Tokens.capsule,
            child: SizedBox(
              height: 44,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: const ColoredBox(color: Color(0xFFFFFFFF), child: SizedBox.expand()),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      child: Row(
                        children: [
                          Text(label, style: Tokens.body.style.copyWith(color: value > .3 ? const Color(0xFF000000) : const Color(0xFFFFFFFF))),
                          const Spacer(),
                          Text(
                            '${(value * 100).round()}%',
                            style: Tokens.body.style.copyWith(color: value > .9 ? const Color(0xFF000000) : const Color(0xFFFFFFFF)),
                          ),
                        ],
                      ),
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

  /// Held ⚡: two sliders (warmth, brightness) over a preview of the glow.
  List<Widget> flashLayers(double top) {
    final s = AppScope.read(context);
    final l = L.of(context);
    return [
      if (flashPanel)
        Positioned.fill(
          child: GestureDetector(
            key: const Key('cam-flash-panel-close'),
            onTap: () => setState(() => flashPanel = false),
            child: ColoredBox(color: flashColor().withValues(alpha: .35 * flashBright)),
          ),
        ),
      if (flashPanel)
        Positioned(
          key: const Key('cam-flash-panel'),
          top: top + Tokens.closeButton + Tokens.space[3],
          left: Tokens.space[5],
          right: Tokens.space[5],
          child: Column(
            children: [
              flashSlider(
                key: const Key('cam-flash-warm'),
                label: l.camFlashWarm,
                value: flashWarm,
                onChanged: (v) => s.setPref('front_flash_warm', v.toStringAsFixed(2)).then((_) => mounted ? setState(() {}) : null),
              ),
              SizedBox(height: Tokens.space[2]),
              flashSlider(
                key: const Key('cam-flash-bright'),
                label: l.camFlashBright,
                value: flashBright,
                onChanged: (v) => s.setPref('front_flash_bright', v.clamp(.2, 1.0).toStringAsFixed(2)).then((_) => mounted ? setState(() {}) : null),
              ),
              SizedBox(height: Tokens.space[2]),
              Text(
                l.camFlashFront,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),
      if (screenFlash || (recording && frontFlashOn))
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              key: const Key('cam-screen-flash'),
              color: flashColor().withValues(alpha: .4 + .6 * flashBright),
            ),
          ),
        ),
    ];
  }

  Future<void> startVideo() async {
    final c = ctl;
    if (StoryCameraPage.fake) {
      setState(() => recording = true);
      watch
        ..reset()
        ..start();
      tick = Timer.periodic(const Duration(milliseconds: 250), (_) => setState(() {}));
      return;
    }
    if (c == null) return;
    dropQr();
    try {
      await c.startVideoRecording();
    } catch (_) {
      return;
    }
    watch
      ..reset()
      ..start();
    setState(() => recording = true);
    tick = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (watch.elapsed >= CamSize.maxVideo) stopVideo();
      if (mounted) setState(() {});
    });
  }

  Future<void> stopVideo() async {
    tick?.cancel();
    watch.stop();
    setState(() => recording = false);
    if (StoryCameraPage.fake) {
      // Tests: a stand-in clip, so the capture path can be followed.
      if (widget.capture) await compose(('clip.mp4', Uint8List.fromList(List.filled(64, 7))));
      return;
    }
    final c = ctl;
    if (c == null) return;
    try {
      final x = await c.stopVideoRecording();
      final b = await x.readAsBytes();
      final mime = x.mimeType ?? (kIsWeb ? 'video/webm' : 'video/mp4');
      final ext = mime.contains('webm') ? 'webm' : (mime.contains('quicktime') ? 'mov' : 'mp4');
      await compose(('story.$ext', b));
    } catch (_) {}
  }

  Future<void> pickFrom(ImageSource src) async {
    try {
      final x = src == ImageSource.gallery
          ? await ImagePicker().pickMedia(maxWidth: 1440, imageQuality: 88)
          // No camera here, on 영상: the phone's own camera records a clip.
          : mode == CamMode.video
          ? await ImagePicker().pickVideo(source: src, maxDuration: CamSize.maxVideo)
          : await ImagePicker().pickImage(source: src, maxWidth: 1440, imageQuality: 88);
      if (x == null) return;
      final b = await x.readAsBytes();
      var name = x.name.isEmpty ? 'story.jpg' : x.name;
      if ((x.mimeType ?? '').startsWith('video/') && !name.contains('.')) name = 'story.mp4';
      await compose((name, b));
    } catch (_) {}
  }

  /// To the editor; the camera rests while it is open.
  Future<void> compose((String, Uint8List) file) async {
    if (!mounted) return;
    final nav = Navigator.of(context);
    final c = ctl;
    ctl = null;
    await c?.dispose();
    if (widget.capture) {
      nav.pop(file);
      return;
    }
    final shared = await nav.push<bool>(
      IosPageRoute(
        builder: (_) => StoryComposer(picked: file, room: widget.room, roomName: widget.roomName),
      ),
    );
    if (!mounted) return;
    if (shared == true) {
      nav.pop(true);
      return;
    }
    setState(() {
      if (layout != null) cells = List.filled(storyLayouts[layout!].length, null);
    });
    if (!StoryCameraPage.fake && !unavailable) await open(lens);
  }

  // ---- gestures on the picture ----

  void scaleStart(ScaleStartDetails d) {
    zoomStart = zoom;
    swipe = Offset.zero;
    pointers = d.pointerCount;
  }

  void scaleUpdate(ScaleUpdateDetails d) {
    pointers = d.pointerCount > pointers ? d.pointerCount : pointers;
    if (d.pointerCount >= 2) {
      final z = (zoomStart * d.scale).clamp(minZoom, maxZoom);
      if (z != zoom) {
        zoom = z;
        ctl?.setZoomLevel(z).catchError((_) {});
      }
    } else {
      swipe += d.focalPointDelta;
    }
  }

  void scaleEnd(ScaleEndDetails d) {
    if (pointers >= 2 || swipe.dx.abs() < 60 || swipe.dx.abs() < swipe.dy.abs()) return;
    final i = CamMode.values.indexOf(mode) + (swipe.dx < 0 ? 1 : -1);
    if (i >= 0 && i < CamMode.values.length) setMode(CamMode.values[i]);
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    if (qrWanted != (qr != null) || (qr != null && !StoryCameraPage.fake && qr!.camera != ctl)) WidgetsBinding.instance.addPostFrameCallback((_) => syncQr());
    return CupertinoTheme(
      data: CupertinoTheme.of(context).copyWith(brightness: Brightness.dark),
      child: PhoneFrame(child: Builder(builder: page)),
    );
  }

  Widget page(BuildContext context) {
    final l = L.of(context);
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    const white = Color(0xFFFFFFFF);
    final barBottom = bottom > 0 ? bottom : Tokens.space[2];
    return CupertinoPageScaffold(
      key: const Key('story-camera'),
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned(
            top: top + Tokens.space[0],
            left: 0,
            right: 0,
            bottom: barBottom + CamSize.bar + CamSize.barGap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[3]),
              child: LayoutBuilder(builder: (context, box) => picture(context, box.biggest)),
            ),
          ),
          Positioned(
            left: Tokens.space[3],
            right: Tokens.space[3],
            bottom: barBottom,
            height: CamSize.bar,
            child: Row(
              children: [
                GlassCircle(
                  key: Key(mode == CamMode.live ? 'cam-live-settings' : 'cam-gallery'),
                  size: CamSize.bar,
                  onTap: mode == CamMode.live ? () => showStoryToast(context, l.camLiveLater) : () => pickFrom(ImageSource.gallery),
                  child: Icon(mode == CamMode.live ? CupertinoIcons.gear_alt : CupertinoIcons.photo_on_rectangle, color: white, size: Tokens.closeIcon),
                ),
                const Spacer(),
                modeSwitch(l),
                const Spacer(),
                GlassCircle(
                  key: const Key('cam-flip'),
                  size: CamSize.bar,
                  onTap: flip,
                  child: const Icon(CupertinoIcons.arrow_2_circlepath, color: white, size: Tokens.closeIcon),
                ),
              ],
            ),
          ),
          ...flashLayers(top),
        ],
      ),
    );
  }

  Widget live() {
    const white = Color(0xFFFFFFFF);
    final c = ctl;
    if (StoryCameraPage.fake) return _FakeScene(front: lens == CameraLensDirection.front);
    if (c != null && c.value.isInitialized) {
      // The browser's video already fills its box (object-fit: cover), and
      // its size can come portrait or landscape: resizing it here again made
      // the first picture look zoomed in on iPhone Safari.
      if (kIsWeb) return SizedBox.expand(child: c.buildPreview());
      final ar = c.value.aspectRatio; // wide side / short side
      return FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(width: 300, height: 300 * ar, child: CameraPreview(c)),
      );
    }
    if (unavailable) {
      return ColoredBox(
        key: const Key('cam-unavailable'),
        color: Palette.of(AppScope.of(context).family, Brightness.dark).card,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.camera, color: white, size: 48),
              SizedBox(height: Tokens.space[2]),
              Text(
                L.of(context).camUnavailable,
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: const Color(0xB3FFFFFF)),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CupertinoActivityIndicator(color: white));
  }

  Widget picture(BuildContext context, Size size) {
    final l = L.of(context);
    const white = Color(0xFFFFFFFF);
    final lay = layout;
    final children = <Widget>[];
    // The live picture keeps one place in the tree whether or not a grid is
    // on, and only moves into the cell being shot. Rebuilding it inside a
    // cell made a new camera view that stayed black on iPhone (Eric
    // 2026-11-28 "그리드에서 화면이 안 보임").
    Rect cellRect(Rect r) => Rect.fromLTWH(r.left * size.width, r.top * size.height, r.width * size.width, r.height * size.height);
    final liveAt = lay == null || nextCell < 0 ? Offset.zero & size : cellRect(storyLayouts[lay][nextCell]);
    children.add(
      Positioned.fromRect(
        key: const ValueKey('cam-live'),
        rect: liveAt,
        child: ClipRect(child: live()),
      ),
    );
    if (lay != null) {
      final rects = storyLayouts[lay];
      final next = nextCell;
      for (var i = 0; i < rects.length; i++) {
        final r = cellRect(rects[i]);
        final b = i < cells.length ? cells[i] : null;
        // The cell being shot shows the live picture underneath.
        if (b == null && i == next) continue;
        children.add(
          Positioned.fromRect(
            key: Key('cam-cell-$i'),
            rect: r,
            child: b != null
                ? Image.memory(b, fit: BoxFit.cover, gaplessPlayback: true)
                : ColoredBox(color: Palette.of(AppScope.of(context).family, Brightness.dark).card),
          ),
        );
      }
      children.add(
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _GridLines(rects))),
        ),
      );
    }
    Widget? dualCircle;
    if (dual) {
      final d = CamSize.dual;
      final cx = (dualAt.dx * size.width).clamp(d / 2, size.width - d / 2);
      final cy = (dualAt.dy * size.height).clamp(d / 2, size.height - d / 2);
      final f = frontShot;
      dualCircle = (Positioned(
        left: cx - d / 2,
        top: cy - d / 2,
        width: d,
        height: d,
        child: GestureDetector(
          key: const Key('cam-dual-circle'),
          onPanUpdate: (u) => setState(() {
            dualAt = Offset(
              ((dualAt.dx * size.width + u.delta.dx) / size.width).clamp(0, 1),
              ((dualAt.dy * size.height + u.delta.dy) / size.height).clamp(0, 1),
            );
          }),
          child: ClipOval(
            child: f != null
                ? Image.memory(f, fit: BoxFit.cover, gaplessPlayback: true)
                : StoryCameraPage.fake
                ? const _FakeScene(front: true)
                : LiquidGlass(
                    radius: d / 2,
                    child: const Center(child: Icon(CupertinoIcons.person_fill, color: white, size: 56)),
                  ),
          ),
        ),
      ));
    }
    // Swipe to change mode, pinch to zoom, double tap to flip.
    final gestures = Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onScaleStart: scaleStart,
        onScaleUpdate: scaleUpdate,
        onScaleEnd: scaleEnd,
        onDoubleTap: flip,
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        ...children,
        gestures,
        ?dualCircle,
        if (qr case final q?)
          Positioned.fill(
            child: QrOverlay(
              watcher: q,
              size: size,
              bottom: CamSize.shutterLift + CamSize.shutter + Tokens.space[3],
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        Positioned(top: Tokens.space[1], left: 0, right: Tokens.space[0], child: topRow(l)),
        if (recording)
          Positioned(
            top: Tokens.space[1] + Tokens.closeButton + Tokens.space[1],
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                key: const Key('cam-rec-time'),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                decoration: BoxDecoration(color: Palette.tileRed, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(
                  clockText(watch.elapsed),
                  style: Tokens.preview.style.copyWith(color: white, fontFeatures: const [ui.FontFeature.tabularFigures()]),
                ),
              ),
            ),
          ),
        if (mode == CamMode.live)
          Positioned(
            left: Tokens.space[5] + Tokens.space[3],
            right: Tokens.space[5] + Tokens.space[3],
            bottom: CamSize.shutterLift + (CamSize.shutter - CamSize.liveButton) / 2,
            height: CamSize.liveButton,
            child: GestureDetector(
              key: const Key('cam-live-start'),
              onTap: shoot,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Palette.tilePink, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(l.camLiveStart, style: Tokens.body.style.copyWith(color: white)),
              ),
            ),
          )
        else
          Positioned(
            left: 0,
            right: 0,
            bottom: CamSize.shutterLift,
            child: Center(child: shutter(l)),
          ),
      ],
    );
  }

  Widget shutter(L l) {
    const white = Color(0xFFFFFFFF);
    final video = mode == CamMode.video;
    final inner = CamSize.shutter - 8;
    final left = layout == null ? 0 : cells.where((c) => c == null).length;
    return Semantics(
      button: true,
      label: left > 0 ? l.camGridLeft(left) : null,
      child: GestureDetector(
        key: const Key('cam-shutter'),
        onTap: shoot,
        child: Container(
          width: CamSize.shutter,
          height: CamSize.shutter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x66000000), width: 4),
          ),
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: recording ? inner * .45 : inner,
            height: recording ? inner * .45 : inner,
            decoration: BoxDecoration(color: video ? Palette.tileRed : white, borderRadius: BorderRadius.circular(recording ? Tokens.radius[0] : inner / 2)),
            child: busy ? const CupertinoActivityIndicator() : null,
          ),
        ),
      ),
    );
  }

  Widget topIcon({required Key key, required Widget icon, required VoidCallback onTap, bool on = false, VoidCallback? onLongPress}) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        width: Tokens.closeButton,
        height: Tokens.closeButton,
        child: Center(
          child: Container(
            width: Tokens.closeButton - Tokens.space[0],
            height: Tokens.closeButton - Tokens.space[0],
            decoration: on ? const BoxDecoration(color: Color(0xFFFFFFFF), shape: BoxShape.circle) : null,
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(color: on ? const Color(0xFF000000) : const Color(0xFFFFFFFF), size: Tokens.closeIcon),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }

  Widget topRow(L l) {
    final gap = SizedBox(width: Tokens.space[0] + 2);
    if (pickingGrid) {
      return SizedBox(
        height: Tokens.closeButton + Tokens.space[5] + Tokens.space[2],
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back to the usual buttons without choosing.
            topIcon(key: const Key('cam-grid-back'), icon: const Icon(CupertinoIcons.chevron_back), onTap: () => setState(() => pickingGrid = false)),
            Expanded(
              child: ListView(
                key: const Key('cam-grid-picker'),
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: EdgeInsets.only(left: Tokens.space[2]),
                children: [
                  // Top-aligned like the layout icons (a list stretches its children to full height).
                  Align(
                    alignment: Alignment.topCenter,
                    child: topIcon(key: const Key('cam-grid-off'), icon: const _GridIcon(null), onTap: () => chooseLayout(null)),
                  ),
                  for (var i = storyLayouts.length - 1; i >= 0; i--) ...[
                    gap,
                    // The tip hangs under its button without taking room in
                    // the row (it pushed the other buttons off the left edge).
                    Align(
                      alignment: Alignment.topCenter,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          topIcon(key: Key('cam-layout-$i'), on: layout == i, icon: _GridIcon(storyLayouts[i]), onTap: () => chooseLayout(i)),
                          if (layout == i)
                            Positioned(
                              top: Tokens.closeButton + Tokens.space[0],
                              right: 0,
                              child: Container(
                                key: const Key('cam-grid-tip'),
                                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                                decoration: BoxDecoration(color: const Color(0xCC1C1C1E), borderRadius: BorderRadius.circular(Tokens.radius[1])),
                                child: Text(l.camGridRemove, maxLines: 1, style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    final photo = mode == CamMode.photo;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photo) ...[
          topIcon(
            key: const Key('cam-grid'),
            on: layout != null,
            icon: const _GridIcon([Rect.fromLTWH(0, 0, .5, .5), Rect.fromLTWH(.5, 0, .5, .5), Rect.fromLTWH(0, .5, .5, .5), Rect.fromLTWH(.5, .5, .5, .5)]),
            onTap: () => setState(() => pickingGrid = true),
          ),
          gap,
        ],
        if (mode != CamMode.video || !recording) ...[
          topIcon(
            key: const Key('cam-dual'),
            on: dual,
            icon: const _DualIcon(),
            onTap: photo ? toggleDual : () => setMode(CamMode.photo).then((_) => toggleDual()),
          ),
          gap,
        ],
        if (mode != CamMode.live) ...[
          topIcon(
            key: const Key('cam-flash'),
            icon: Icon(switch (flash) {
              FlashMode.off => CupertinoIcons.bolt_slash,
              FlashMode.auto => CupertinoIcons.bolt_badge_a,
              _ => CupertinoIcons.bolt_fill,
            }),
            onTap: cycleFlash,
            onLongPress: () => setState(() => flashPanel = !flashPanel),
          ),
          gap,
        ],
        topIcon(
          key: const Key('cam-close'),
          icon: const Icon(CupertinoIcons.xmark),
          onTap: () {
            if (recording) stopVideo();
            Navigator.of(context).maybePop();
          },
        ),
      ],
    );
  }

  Widget modeSwitch(L l) {
    final names = {CamMode.live: l.camLive, CamMode.video: l.camVideo, CamMode.photo: l.camPhoto};
    return LiquidGlass(
      radius: CamSize.bar / 2,
      child: Padding(
        padding: EdgeInsets.all(Tokens.space[0]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in CamMode.values)
              if (!widget.capture || m != CamMode.live)
                GestureDetector(
                  key: Key('cam-mode-${m.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setMode(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: CamSize.segment,
                    height: CamSize.bar - Tokens.space[0] * 2,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: mode == m ? const Color(0x2EFFFFFF) : null, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(names[m]!, style: Tokens.preview.style.copyWith(color: mode == m ? Palette.tileYellow : const Color(0xFFFFFFFF))),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String clockText(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// The grid icon: a rounded square with the layout's lines; null = "no grid".
class _GridIcon extends StatelessWidget {
  const _GridIcon(this.rects);
  final List<Rect>? rects;

  @override
  Widget build(BuildContext context) {
    final c = IconTheme.of(context).color ?? const Color(0xFFFFFFFF);
    return CustomPaint(size: const Size(20, 20), painter: _GridIconPainter(rects, c));
  }
}

class _GridIconPainter extends CustomPainter {
  _GridIconPainter(this.rects, this.color);
  final List<Rect>? rects;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final box = Offset.zero & s;
    canvas.drawRRect(RRect.fromRectAndRadius(box.deflate(1), const Radius.circular(4)), p);
    final rs = rects ?? storyLayouts[2];
    for (final r in rs) {
      if (r.right < 1) canvas.drawLine(Offset(r.right * s.width, r.top * s.height + 1), Offset(r.right * s.width, r.bottom * s.height - 1), p);
      if (r.bottom < 1) canvas.drawLine(Offset(r.left * s.width + 1, r.bottom * s.height), Offset(r.right * s.width - 1, r.bottom * s.height), p);
    }
    if (rects == null) canvas.drawLine(const Offset(0, 0), Offset(s.width, s.height), p);
  }

  @override
  bool shouldRepaint(_GridIconPainter o) => o.rects != rects || o.color != color;
}

/// Both cameras: a phone outline with a small round lens at the top.
class _DualIcon extends StatelessWidget {
  const _DualIcon();

  @override
  Widget build(BuildContext context) {
    final c = IconTheme.of(context).color ?? const Color(0xFFFFFFFF);
    return CustomPaint(size: const Size(20, 22), painter: _DualIconPainter(c));
  }
}

class _DualIconPainter extends CustomPainter {
  _DualIconPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(2, 4, s.width - 6, s.height - 5), const Radius.circular(4)), p);
    canvas.drawCircle(Offset(s.width - 5, 5), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DualIconPainter o) => o.color != color;
}

class _GridLines extends CustomPainter {
  _GridLines(this.rects);
  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = const Color(0x80FFFFFF)
      ..strokeWidth = 1;
    for (final r in rects) {
      if (r.right < 1) canvas.drawLine(Offset(r.right * s.width, r.top * s.height), Offset(r.right * s.width, r.bottom * s.height), p);
      if (r.bottom < 1) canvas.drawLine(Offset(r.left * s.width, r.bottom * s.height), Offset(r.right * s.width, r.bottom * s.height), p);
    }
  }

  @override
  bool shouldRepaint(_GridLines o) => o.rects != rects;
}

/// Stand-in picture for tests and screenshots (warm light on a floor).
class _FakeScene extends StatelessWidget {
  const _FakeScene({this.front = false});
  final bool front;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: front ? const [Palette.tileIndigo, Palette.tileTeal] : const [Palette.tileRed, Palette.tileOrange, Palette.tileGrey],
        ),
      ),
    );
  }
}

/// A painted photo for tests and screenshots.
Future<Uint8List> fakePhoto(int n, {bool front = false}) async {
  const w = 360.0, h = 640.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final colors = front
      ? const [Palette.tileIndigo, Palette.tileTeal]
      : [
          [Palette.tileRed, Palette.tileOrange],
          [Palette.tileBlue, Palette.tileCyan],
          [Palette.tilePurple, Palette.tilePink],
          [Palette.tileYellow, Palette.tileOrange],
        ][n % 4];
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(w, h), colors));
  final img = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<ui.Image> _decode(Uint8List b) async {
  final codec = await ui.instantiateImageCodec(b);
  return (await codec.getNextFrame()).image;
}

/// Draws [img] filling [dst] (cut to fit, like BoxFit.cover).
void _cover(Canvas c, ui.Image img, Rect dst) {
  final iw = img.width.toDouble(), ih = img.height.toDouble();
  final scale = (dst.width / iw) > (dst.height / ih) ? dst.width / iw : dst.height / ih;
  final sw = dst.width / scale, sh = dst.height / scale;
  final src = Rect.fromLTWH((iw - sw) / 2, (ih - sh) / 2, sw, sh);
  c.drawImageRect(img, src, dst, Paint()..filterQuality = FilterQuality.high);
}

/// One story picture (720 × 1280) from collage boxes and/or a front-camera
/// circle. [frontAt] is the circle centre and [frontPart] its width, both as
/// parts of the picture.
Future<Uint8List> composeStory({
  required List<Uint8List> cells,
  required List<Rect> layout,
  Uint8List? front,
  Offset frontAt = const Offset(.25, .72),
  double frontPart = .4,
}) async {
  const w = 720.0, h = 1280.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF000000));
  for (var i = 0; i < cells.length && i < layout.length; i++) {
    final r = layout[i];
    final img = await _decode(cells[i]);
    _cover(c, img, Rect.fromLTWH(r.left * w, r.top * h, r.width * w, r.height * h));
  }
  if (front != null) {
    final d = frontPart * w;
    final cx = (frontAt.dx * w).clamp(d / 2, w - d / 2), cy = (frontAt.dy * h).clamp(d / 2, h - d / 2);
    final circle = Rect.fromCircle(center: Offset(cx, cy), radius: d / 2);
    final img = await _decode(front);
    c.save();
    c.clipPath(Path()..addOval(circle));
    _cover(c, img, circle);
    c.restore();
  }
  final out = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final data = await out.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
