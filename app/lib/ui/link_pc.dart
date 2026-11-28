// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// QR로 PC 연결 (Telegram tips 78 + 311), behind Features.loginSafety.
//
// PC (signed out): 로그인 > "QR로 로그인" shows a QR that holds only the
// sha256 of a random secret the PC keeps. Phone: 설정 > 기기 > "QR로 PC
// 연결" scans it, asks "이 PC에 로그인할까요?" and vouches for it through our
// small server/qr-login service. The PC then signs in with a 2-minute
// one-time token: no password typed on the PC. Past chats open there after
// the usual emoji check, like any new device.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show compute, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:zxing2/qrcode.dart';

import '../core/app_state.dart';
import '../core/login_safety.dart';
import '../core/qr.dart';
import '../core/qr_read.dart' show GreyLuminance;
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'qr_page.dart' show QrPainter;
import 'settings_art.dart';
import 'wide.dart';

/// What a PC sign-in QR holds: `burumy://pc-login?r=<64 hex>`.
class PcLinkCode {
  const PcLinkCode._();
  static const scheme = 'burumy://pc-login';

  static String of(String rid) => '$scheme?r=$rid';

  /// The QR id inside a scanned text, or null when it isn't ours.
  static String? read(String text) {
    final u = Uri.tryParse(text.trim());
    if (u == null || '${u.scheme}://${u.host}' != scheme) return null;
    final r = u.queryParameters['r'] ?? '';
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(r) ? r : null;
  }

  /// A fresh secret (64 hex) and its QR id.
  /// Screenshot tests only: a fixed secret so the picture is the same.
  @visibleForTesting
  static String? debugSecret;

  static (String, String) fresh() {
    final rnd = math.Random.secure();
    final s = debugSecret ?? [for (var i = 0; i < 32; i++) rnd.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
    return (s, sha256.convert(utf8.encode(s)).toString());
  }
}

/// Can this device scan with a camera (phone apps only)?
bool get canScanHere => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

/// 설정 > 기기 > "QR로 PC 연결".
Future<void> openLinkPc(BuildContext context) => Navigator.of(context).push(IosPageRoute(builder: (_) => const LinkPcPage()));

/// Asks "이 PC에 로그인할까요?" and vouches for it. Tests and the scanner
/// both come here with the scanned text. True when the PC may sign in.
Future<bool> confirmPcLink(BuildContext context, String text) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final rid = PcLinkCode.read(text);
  if (rid == null) {
    showPcNotice(context, l.linkPcBad);
    return false;
  }
  HapticFeedback.mediumImpact();
  final go = await showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      title: Text(l.linkPcConfirmTitle),
      message: Text(l.linkPcConfirmBody(l.deviceKindPc)),
      actions: [
        CupertinoActionSheetAction(key: const Key('link-pc-yes'), isDefaultAction: true, onPressed: () => Navigator.pop(c, true), child: Text(l.linkPcConfirm)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
    ),
  );
  if (go != true || !context.mounted) return false;
  try {
    await s.backend.approvePcLogin(rid);
  } catch (_) {
    if (context.mounted) showPcNotice(context, l.linkPcExpired);
    return false;
  }
  // The PC that shows up next was approved here: no 새 로그인 경고 for it.
  unawaited(() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      try {
        final all = await s.backend.devices();
        final fresh = await LoginSafety.newDevices(s, all);
        if (fresh.isNotEmpty) {
          for (final d in fresh) {
            await s.answerNewLogin(d.id, mine: true);
          }
          return;
        }
      } catch (_) {}
    }
  }());
  return true;
}

void showPcNotice(BuildContext context, String text) {
  showCupertinoModalPopup<void>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      title: Text(text),
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(L.of(c).ok)),
    ),
  );
}

/// Phone page: laptop picture, three steps, the camera finder (phones).
class LinkPcPage extends StatefulWidget {
  const LinkPcPage({super.key});
  @override
  State<LinkPcPage> createState() => _LinkPcPageState();
}

class _LinkPcPageState extends State<LinkPcPage> {
  bool scanning = false;

  Future<void> scan() async {
    final l = L.of(context);
    if (!canScanHere) {
      showPcNotice(context, l.linkPcNoCamera);
      return;
    }
    setState(() => scanning = true);
    final text = await Navigator.of(context).push<String>(IosPageRoute(fullscreenDialog: true, builder: (_) => const QrScanPage()));
    if (!mounted) return;
    setState(() => scanning = false);
    if (text == null) return;
    final ok = await confirmPcLink(context, text);
    if (ok && mounted) {
      showPcNotice(context, l.linkPcDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget step(int n, String text) => Padding(
      padding: EdgeInsets.only(bottom: Tokens.space[3]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            child: Text(
              '$n',
              style: Tokens.preview.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
            ),
          ),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Text(text, style: Tokens.body.style.copyWith(color: p.label)),
          ),
        ],
      ),
    );
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.linkPc, back: true, tint: p.background),
      child: ListView(
        key: const Key('link-pc-page'),
        padding: EdgeInsets.fromLTRB(
          Tokens.space[3],
          MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[3],
          Tokens.space[3],
          Tokens.space[5],
        ),
        children: [
          const Center(child: LaptopArt()),
          SizedBox(height: Tokens.space[3]),
          Text(
            l.linkPcInfo,
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
          SizedBox(height: Tokens.space[4]),
          step(1, l.linkPcStep1),
          step(2, l.linkPcStep2),
          step(3, l.linkPcStep3),
          SizedBox(height: Tokens.space[2]),
          GestureDetector(
            key: const Key('link-pc-scan'),
            onTap: scanning ? null : scan,
            child: Container(
              height: Tokens.settingsRow,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.qrcode_viewfinder, color: p.onAccent, size: Tokens.listIcon),
                  SizedBox(width: Tokens.space[1]),
                  Text(
                    l.linkPcScanTitle,
                    style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- scanner

/// Full-screen camera with a square finder; pops with the first QR text
/// it reads. The picture never leaves the phone (read here, frame by
/// frame, by a small QR reader written in Dart).
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  CameraController? cam;
  bool busy = false, done = false;
  DateTime last = DateTime(2000);

  @override
  void initState() {
    super.initState();
    unawaited(start());
  }

  Future<void> start() async {
    try {
      final cams = await availableCameras();
      final back = cams.where((c) => c.lensDirection == CameraLensDirection.back).firstOrNull ?? cams.first;
      final c = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => cam = c);
      await c.startImageStream(onFrame);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void onFrame(CameraImage img) {
    final now = DateTime.now();
    if (busy || done || now.difference(last) < const Duration(milliseconds: 350)) return;
    busy = true;
    last = now;
    final frame = lumaOf(img);
    unawaited(
      compute(readQr, frame).then((text) {
        busy = false;
        if (text == null || done || !mounted) return;
        done = true;
        HapticFeedback.lightImpact();
        unawaited(cam?.stopImageStream().catchError((_) {}));
        Navigator.of(context).pop(text);
      }),
    );
  }

  @override
  void dispose() {
    unawaited(cam?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = cam;
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (c != null && c.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(width: c.value.previewSize?.height ?? 1, height: c.value.previewSize?.width ?? 1, child: CameraPreview(c)),
            ),
          // Finder: a clear square with soft corners, the rest dimmed.
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFFFFF), width: 3),
                borderRadius: BorderRadius.circular(Tokens.radius[3]),
              ),
            ),
          ),
          Positioned(
            left: Tokens.space[3],
            right: Tokens.space[3],
            top: MediaQuery.paddingOf(context).top + Tokens.space[2],
            child: Row(
              children: [
                GlassCircle(key: const Key('scan-close'), onTap: () => Navigator.of(context).pop(), child: GlassCircle.icon(context, CupertinoIcons.xmark)),
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Text(
                    l.linkPcScanTitle,
                    style: Tokens.body.style.copyWith(color: const Color(0xFFFFFFFF), fontWeight: Tokens.semi),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One camera frame as grey levels (width, height, bytes).
(int, int, Uint8List) lumaOf(CameraImage img) {
  final w = img.width, h = img.height;
  final out = Uint8List(w * h);
  final pl = img.planes.first;
  if (img.format.group == ImageFormatGroup.bgra8888) {
    final b = pl.bytes, row = pl.bytesPerRow;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * row + x * 4;
        out[y * w + x] = (b[i] * 29 + b[i + 1] * 150 + b[i + 2] * 77) >> 8;
      }
    }
  } else {
    final b = pl.bytes, row = pl.bytesPerRow;
    for (var y = 0; y < h; y++) {
      out.setRange(y * w, y * w + w, b, y * row);
    }
  }
  return (w, h, out);
}

/// Reads a QR code from grey levels; null when there is none.
String? readQr((int, int, Uint8List) f) {
  final (w, h, luma) = f;
  try {
    final src = GreyLuminance(luma, w, h);
    return QRCodeReader().decode(BinaryBitmap(HybridBinarizer(src))).text;
  } catch (_) {
    return null;
  }
}

// ------------------------------------------------------------------ PC

/// Sign-in screen on a PC (and the web): a QR the phone scans. A new code
/// every 2 minutes; the page asks every 2 seconds whether my phone
/// vouched for it.
class QrLoginPage extends StatefulWidget {
  const QrLoginPage({super.key});
  @override
  State<QrLoginPage> createState() => _QrLoginPageState();
}

class _QrLoginPageState extends State<QrLoginPage> {
  late (String, String) code = PcLinkCode.fresh();
  Timer? poll;
  DateTime made = DateTime.now();
  bool signingIn = false;

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(seconds: 2), (_) => ask());
  }

  @override
  void dispose() {
    poll?.cancel();
    super.dispose();
  }

  void renew() => setState(() {
    code = PcLinkCode.fresh();
    made = DateTime.now();
  });

  Future<void> ask() async {
    if (signingIn || !mounted) return;
    if (DateTime.now().difference(made) > const Duration(minutes: 2)) return renew();
    final s = AppScope.read(context);
    signingIn = true;
    try {
      if (await s.loginWithPcCode(code.$1)) {
        poll?.cancel();
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
    } catch (_) {
    } finally {
      signingIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final qr = QrCode.encode(PcLinkCode.of(code.$2));
    Widget step(int n, String text) => Padding(
      padding: EdgeInsets.only(bottom: Tokens.space[2]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
            child: Text(
              '$n',
              style: Tokens.caption.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
            ),
          ),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Text(text, style: Tokens.preview.style.copyWith(color: p.label)),
          ),
        ],
      ),
    );
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.qrLoginTitle, back: true, tint: p.background),
      // Like Telegram Desktop: QR, a heading, three steps, then the way
      // back to ID + password; high on a phone-sized window, centred on a PC.
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ListView(
            key: const Key('qr-login-page'),
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(
              Tokens.space[3],
              MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[4],
              Tokens.space[3],
              Tokens.space[4],
            ),
            children: [
              if (!s.backend.pcLinkReady)
                Text(
                  l.qrLoginOff,
                  key: const Key('qr-login-off'),
                  textAlign: TextAlign.center,
                  style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                )
              else ...[
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    padding: EdgeInsets.all(Tokens.space[3]),
                    decoration: ShapeDecoration(
                      color: const Color(0xFFFFFFFF),
                      shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[3])),
                    ),
                    child: qr == null ? null : CustomPaint(key: const Key('qr-login-code'), painter: QrPainter(qr, const Color(0xFF000000))),
                  ),
                ),
                SizedBox(height: Tokens.space[4]),
                Text(
                  l.qrLoginHeading,
                  textAlign: TextAlign.center,
                  style: Tokens.cardTitle.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                ),
                SizedBox(height: Tokens.space[3]),
                step(1, l.qrLoginStep1),
                step(2, l.qrLoginStep2),
                step(3, l.qrLoginStep3),
                SizedBox(height: Tokens.space[2]),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CupertinoActivityIndicator(radius: 8),
                    SizedBox(width: Tokens.space[1]),
                    Text(l.qrLoginWaiting, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
                CupertinoButton(
                  key: const Key('qr-login-new'),
                  onPressed: renew,
                  child: Text(l.qrLoginNew, style: Tokens.preview.style.copyWith(color: p.accent)),
                ),
              ],
              CupertinoButton(
                key: const Key('qr-login-password'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l.qrLoginPassword, style: Tokens.preview.style.copyWith(color: p.accent)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
