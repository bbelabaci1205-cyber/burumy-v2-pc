// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Location: "send my current location" and the location bubble. We never
// fetch a map picture (that would tell a map company where the person is);
// the bubble draws its own calm map-like card and opens the phone's own
// Maps app only when the reader taps.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';

/// A point read from a "geo:" address (the engine already checked it).
class GeoPoint {
  const GeoPoint(this.lat, this.lon, this.accuracy);
  final double lat, lon;
  final double? accuracy;

  static GeoPoint? parse(String? uri) {
    final m = RegExp(r'^geo:(-?[\d.]+),(-?[\d.]+)(?:;u=([\d.]+))?').firstMatch(uri ?? '');
    if (m == null) return null;
    final lat = double.tryParse(m[1]!), lon = double.tryParse(m[2]!);
    if (lat == null || lon == null || lat.abs() > 90 || lon.abs() > 180) return null;
    return GeoPoint(lat, lon, m[3] == null ? null : double.tryParse(m[3]!));
  }

  String get shown => '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';

  /// 실시간 위치: when the sharing ends (null = a one-time location).
  static DateTime? liveUntil(String? uri) {
    final m = RegExp(r';live=(\d+)').firstMatch(uri ?? '');
    return m == null ? null : DateTime.fromMillisecondsSinceEpoch(int.parse(m[1]!));
  }

  /// The phone's own Maps app (iPhone: Apple Maps; Android: the chosen map
  /// app; web: OpenStreetMap, which needs no account).
  Uri get mapsUri {
    if (kIsWeb) return Uri.parse('https://www.openstreetmap.org/?mlat=$lat&mlon=$lon#map=17/$lat/$lon');
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return Uri.parse('https://maps.apple.com/?ll=$lat,$lon&q=%F0%9F%93%8D');
    }
    return Uri.parse('geo:$lat,$lon?q=$lat,$lon');
  }
}

/// Full-screen "send my location": finds the point once, shows how exact it
/// is, and sends only when the person taps.
class SendLocationPage extends StatefulWidget {
  const SendLocationPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<SendLocationPage> createState() => _SendLocationPageState();
}

class _SendLocationPageState extends State<SendLocationPage> {
  GeoFix? fix;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    find();
  }

  Future<void> find() async {
    setState(() {
      fix = null;
      error = null;
    });
    try {
      final f = await Phone.location();
      if (mounted) setState(() => fix = f);
    } on PhoneError catch (e) {
      if (mounted) setState(() => error = e.code);
    } catch (_) {
      if (mounted) setState(() => error = 'unavailable');
    }
  }

  /// 실시간 위치 for 15 minutes, 1 hour or 8 hours.
  Future<void> sendLive(Duration length) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).startLiveLocation(widget.roomId, length);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = 'unavailable');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> send() async {
    final f = fix;
    if (f == null || busy) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend.sendLocation(widget.roomId, f.lat, f.lon, f.accuracy);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final f = fix;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), middle: Text(l.location), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(IosSection.sideMargin, 16, IosSection.sideMargin, 0),
              child: ClipRSuperellipse(
                borderRadius: BorderRadius.circular(IosSection.radius),
                child: SizedBox(
                  height: 220,
                  child: MapArt(
                    key: const Key('location-art'),
                    pin: f != null,
                    accuracy: f?.accuracy,
                    child: f == null && error == null ? const CupertinoActivityIndicator(radius: 14) : null,
                  ),
                ),
              ),
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.locationPrivacy),
              children: [
                if (f != null)
                  IosTile(
                    key: const Key('location-send'),
                    title: Text(l.locationSend, style: Tokens.body.style.copyWith(color: p.accent)),
                    subtitle: Text(
                      f.accuracy == null ? GeoPoint(f.lat, f.lon, null).shown : l.locationAccuracy(f.accuracy!.round()),
                      style: Tokens.caption.style,
                    ),
                    trailing: busy ? const CupertinoActivityIndicator() : Icon(CupertinoIcons.location_fill, color: p.accent, size: Tokens.listIcon),
                    onTap: send,
                  )
                else if (error == null)
                  IosTile(
                    title: Text(l.locationFinding, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                  )
                else ...[
                  Padding(
                    key: const Key('location-error'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Text(switch (error) {
                      'denied' => l.locationDenied,
                      'off' => l.locationOff,
                      _ => l.locationUnavailable,
                    }, style: Tokens.body.style.copyWith(color: p.label)),
                  ),
                  if (error == 'denied' || error == 'off')
                    IosTile(
                      key: const Key('location-settings'),
                      title: Text(l.openPhoneSettings, style: Tokens.body.style.copyWith(color: p.accent)),
                      onTap: Phone.openSettings,
                    ),
                  IosTile(
                    key: const Key('location-retry'),
                    title: Text(l.locationRetry, style: Tokens.body.style.copyWith(color: p.accent)),
                    onTap: find,
                  ),
                ],
              ],
            ),
            if (f != null)
              IosSection(
                hasLeading: false,
                header: sectionHeader(context, l.liveLocation),
                footer: sectionFooter(context, l.liveLocationInfo),
                children: [
                  for (final (key, d, label) in [
                    ('live-15m', const Duration(minutes: 15), l.live15m),
                    ('live-1h', const Duration(hours: 1), l.live1h),
                    ('live-8h', const Duration(hours: 8), l.live8h),
                  ])
                    IosTile(
                      key: Key(key),
                      title: Text(label, style: Tokens.body.style.copyWith(color: p.accent)),
                      trailing: Icon(CupertinoIcons.location_circle_fill, color: p.accent, size: Tokens.listIcon),
                      onTap: () => sendLive(d),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A calm drawn "map": soft blocks and roads, and a pin with its accuracy
/// ring. It is decoration only; no real map is fetched.
class MapArt extends StatelessWidget {
  const MapArt({super.key, required this.pin, this.accuracy, this.child, this.seed = 0});
  final bool pin;
  final double? accuracy;
  final Widget? child;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return CustomPaint(
      painter: _MapPainter(p.dark, seed),
      child: Center(
        child:
            child ??
            (pin
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.16)),
                      ),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.accent,
                          border: Border.all(color: const Color(0xFFFFFFFF), width: 4),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                      ),
                    ],
                  )
                : null),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.dark, this.seed);
  final bool dark;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = dark ? const Color(0xFF26282B) : const Color(0xFFF1EFE9);
    canvas.drawRect(Offset.zero & size, land);
    final rnd = math.Random(seed);
    final park = Paint()..color = dark ? const Color(0xFF223326) : const Color(0xFFD9EBCF);
    final water = Paint()..color = dark ? const Color(0xFF1D2A3A) : const Color(0xFFCFE3F3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.62, size.height * 0.08, size.width * 0.3, size.height * 0.34), const Radius.circular(18)),
      park,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * 0.78)
        ..quadraticBezierTo(size.width * 0.3, size.height * 0.68, size.width * 0.55, size.height)
        ..lineTo(0, size.height)
        ..close(),
      water,
    );
    final road = Paint()
      ..color = dark ? const Color(0xFF3A3D42) : const Color(0xFFFFFFFF)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      road.strokeWidth = i.isEven ? 9 : 5;
      final y = size.height * (0.15 + i * 0.19) + rnd.nextDouble() * 8;
      canvas.drawLine(Offset(-10, y), Offset(size.width + 10, y + (rnd.nextDouble() - 0.5) * 30), road);
    }
    for (var i = 0; i < 4; i++) {
      road.strokeWidth = i == 1 ? 9 : 5;
      final x = size.width * (0.12 + i * 0.26) + rnd.nextDouble() * 10;
      canvas.drawLine(Offset(x, -10), Offset(x + (rnd.nextDouble() - 0.5) * 40, size.height + 10), road);
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.dark != dark || old.seed != seed;
}

/// The location bubble: drawn map card with the pin, the place's numbers and
/// "open in Maps".
class LocationBubble extends StatelessWidget {
  const LocationBubble({super.key, required this.msg, required this.fg, required this.meta, this.roomId = ''});
  final Msg msg;
  final String roomId;
  final Color fg;
  final Widget meta;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final g = GeoPoint.parse(msg.body);
    if (g == null) return Text(l.location, style: Tokens.body.style.copyWith(color: fg));
    final s = AppScope.of(context);
    final until = GeoPoint.liveUntil(msg.body);
    final live = until != null && until.isAfter(s.backend.clock);
    final left = until?.difference(s.backend.clock);
    return SizedBox(
      width: 240,
      child: Column(
        key: Key('location-${msg.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            key: const Key('location-open'),
            onTap: () => launchUrl(g.mapsUri, mode: LaunchMode.externalApplication),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              child: SizedBox(
                height: 130,
                child: MapArt(pin: true, accuracy: g.accuracy, seed: msg.id.hashCode),
              ),
            ),
          ),
          SizedBox(height: Tokens.space[1]),
          Row(
            children: [
              Icon(CupertinoIcons.location_solid, size: 16, color: fg),
              SizedBox(width: Tokens.space[0]),
              Expanded(
                child: Text(
                  until == null ? l.location : (live ? l.liveLocation : l.liveLocationEnded),
                  key: Key(until == null ? 'location-title' : (live ? 'live-on' : 'live-ended')),
                  style: Tokens.body.style.copyWith(color: fg, fontWeight: Tokens.semi),
                ),
              ),
            ],
          ),
          Text(
            live
                ? (left!.inMinutes < 60 ? l.liveLeftMinutes(left.inMinutes + 1) : l.liveLeftHours((left.inMinutes / 60).ceil()))
                : (g.accuracy == null ? g.shown : '${g.shown} · ${l.locationAccuracy(g.accuracy!.round())}'),
            style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75)),
          ),
          if (live && msg.mine && s.liveShares[roomId]?.$1 == msg.id) ...[
            SizedBox(height: Tokens.space[1]),
            GestureDetector(
              key: const Key('live-stop'),
              onTap: () => s.stopLiveLocation(roomId),
              child: Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(l.liveStop, style: Tokens.caption.style.copyWith(color: fg)),
              ),
            ),
          ],
          SizedBox(height: Tokens.space[1]),
          GestureDetector(
            onTap: () => launchUrl(g.mapsUri, mode: LaunchMode.externalApplication),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(l.locationOpenMap, style: Tokens.caption.style.copyWith(color: fg)),
            ),
          ),
          Align(alignment: Alignment.centerRight, child: meta),
        ],
      ),
    );
  }
}
