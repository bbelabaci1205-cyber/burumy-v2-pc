// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 홍보 이미지 (manual 6-7): a poster with the group's or channel's name,
// description and a big QR of its invite link, tall (1080x1920, stories)
// or square (1080x1080, feeds). Made on the phone; saved or shared from here.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

import '../brand/brand.dart';
import '../brand/mark.dart';
import '../core/app_state.dart';
import '../core/phone.dart';
import '../core/qr.dart';
import '../core/room_links.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'settings_kit.dart';
import 'settings_more.dart' show QrPainter;

class PosterArt extends StatelessWidget {
  const PosterArt({
    super.key,
    required this.square,
    required this.ground,
    required this.name,
    required this.kind,
    required this.about,
    required this.link,
    required this.brand,
    required this.scan,
    this.roomId,
  });
  final bool square;

  /// Shows the room's own photo (그룹·채널 사진) when it has one.
  final String? roomId;

  /// Index into [Palette.posterGrounds].
  final int ground;
  final String name, kind, about, link, brand, scan;

  static const width = 1080.0;
  Size get size => Size(width, square ? 1080 : 1920);

  @override
  Widget build(BuildContext context) {
    final (_, colors, light) = Palette.posterGrounds[ground];
    final ink = light ? const Color(0xFFFFFFFF) : const Color(0xFF16241B);
    final soft = ink.withValues(alpha: 0.78);
    final code = QrCode.encode(link);
    TextStyle t(double size, FontWeight w, Color c, {double h = 1.25}) =>
        TextStyle(fontFamily: Tokens.font, fontSize: size, fontWeight: w, color: c, height: h, decoration: TextDecoration.none);
    final mark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BurumyMark(color: ink, size: 64),
        const SizedBox(width: 16),
        Text(brand, style: t(52, FontWeight.w600, ink)),
      ],
    );
    Widget qr(double side) => Container(
      key: const Key('poster-qr'),
      padding: EdgeInsets.all(side * 0.09),
      decoration: ShapeDecoration(
        color: const Color(0xFFFFFFFF),
        shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(side * 0.11)),
        shadows: const [BoxShadow(color: Color(0x26000000), blurRadius: 40, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: side,
            child: code == null ? null : CustomPaint(painter: QrPainter(code, const Color(0xFF16241B))),
          ),
          SizedBox(height: side * 0.06),
          SizedBox(
            width: side,
            child: Text(
              RoomLinks.shown(link).split('#').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: t(side * 0.058, FontWeight.w500, const Color(0xFF16241B)),
            ),
          ),
        ],
      ),
    );
    final title = Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: square ? TextAlign.start : TextAlign.center,
      style: t(square ? 72 : 88, FontWeight.w700, ink, h: 1.15),
    );
    final kindLine = Text(kind, style: t(square ? 36 : 42, FontWeight.w500, soft));
    final aboutText = about.isEmpty
        ? null
        : Text(
            about,
            maxLines: square ? 3 : 3,
            overflow: TextOverflow.ellipsis,
            textAlign: square ? TextAlign.start : TextAlign.center,
            style: t(square ? 34 : 40, FontWeight.w400, soft, h: 1.4),
          );
    final face = Avatar(name: name, size: square ? 180 : 260, squircle: true, roomId: roomId);
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
      ),
      padding: const EdgeInsets.fromLTRB(96, 88, 96, 80),
      child: square
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mark,
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          face,
                          const SizedBox(height: 32),
                          title,
                          const SizedBox(height: 10),
                          kindLine,
                          if (aboutText != null) ...[const SizedBox(height: 20), aboutText],
                        ],
                      ),
                    ),
                    const SizedBox(width: 48),
                    qr(360),
                  ],
                ),
                const Spacer(),
                Text(scan, style: t(34, FontWeight.w500, soft)),
              ],
            )
          : Column(
              children: [
                mark,
                const Spacer(flex: 2),
                face,
                const SizedBox(height: 44),
                title,
                const SizedBox(height: 14),
                kindLine,
                if (aboutText != null) ...[const SizedBox(height: 28), aboutText],
                const Spacer(flex: 2),
                qr(520),
                const Spacer(),
                Text(scan, textAlign: TextAlign.center, style: t(40, FontWeight.w500, soft)),
              ],
            ),
    );
  }
}

class PosterPage extends StatefulWidget {
  const PosterPage({super.key, required this.roomId, required this.name, required this.link, required this.isChannel});
  final String roomId;
  final String name;
  final String link;
  final bool isChannel;

  @override
  State<PosterPage> createState() => _PosterPageState();
}

class _PosterPageState extends State<PosterPage> {
  bool square = false;
  int ground = 0;
  String about = '';
  bool saved = false;
  final art = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final a = await AppScope.read(context).backend.roomAbout(widget.roomId);
      if (mounted) setState(() => about = a);
    });
  }

  /// The poster as a 1080-wide PNG.
  Future<Uint8List?> png() async {
    final box = art.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (box == null) return null;
    final image = await box.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  String get fileName => 'burumy-${square ? 'square' : 'tall'}-${DateTime.now().millisecondsSinceEpoch}.png';

  Future<void> save() async {
    final bytes = await png();
    if (bytes == null) return;
    final ok = await Phone.saveImage(bytes, name: fileName);
    if (mounted && ok) setState(() => saved = true);
  }

  Future<void> share() async {
    final bytes = await png();
    if (bytes == null) return;
    await Phone.share(text: widget.link, bytes: bytes, name: fileName);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final kind = widget.link.contains('/c/')
        ? (widget.isChannel ? l.joinPublicChannel : l.joinPublicGroup)
        : (widget.isChannel ? l.joinPrivateChannel : l.joinPrivateGroup);
    final poster = PosterArt(
      square: square,
      ground: ground,
      name: widget.name,
      kind: kind,
      about: about,
      link: widget.link,
      brand: ko ? Brand.nameKo : Brand.nameEn,
      scan: l.posterScan,
      roomId: widget.roomId,
    );
    return SettingsScaffold(
      title: l.posterTitle,
      children: [
        SizedBox(height: Tokens.space[3]),
        Center(
          child: Container(
            key: const Key('poster-preview'),
            height: square ? 320 : 420,
            width: square ? 320 : 420 * 1080 / 1920,
            decoration: ShapeDecoration(
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(Tokens.radius[2])),
              shadows: const [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 8))],
            ),
            clipBehavior: Clip.antiAlias,
            child: FittedBox(
              child: RepaintBoundary(key: art, child: poster),
            ),
          ),
        ),
        SizedBox(height: Tokens.space[4]),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: IosSegmented<bool>(
            key: const Key('poster-shape'),
            groupValue: square,
            onValueChanged: (v) => setState(() {
              square = v ?? false;
              saved = false;
            }),
            children: {false: Text(l.posterTall), true: Text(l.posterSquare)},
          ),
        ),
        SizedBox(height: Tokens.space[3]),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < Palette.posterGrounds.length; i++)
              GestureDetector(
                key: Key('poster-ground-${Palette.posterGrounds[i].$1}'),
                onTap: () => setState(() {
                  ground = i;
                  saved = false;
                }),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: i == ground ? p.accent : const Color(0x00000000), width: 2),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: Palette.posterGrounds[i].$2),
                      border: Border.all(color: p.separator),
                    ),
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
          child: Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  key: const Key('poster-save'),
                  color: p.accent,
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: save,
                  child: Text(
                    saved ? l.posterSaved : l.posterSave,
                    style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: CupertinoButton(
                  key: const Key('poster-share'),
                  color: p.accent,
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  onPressed: share,
                  child: Text(
                    l.linkShare,
                    style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[3], Tokens.space[5], Tokens.space[4]),
          child: Text(
            l.posterInfo,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
      ],
    );
  }
}
