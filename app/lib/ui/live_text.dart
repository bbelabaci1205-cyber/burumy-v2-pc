// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사진 속 글자 복사 (TelegramTips 317, iOS Live Text): a button under a
// photo finds its text on this phone (Apple Vision; the photo never leaves
// it). The words light up and the rest of the picture dims; tap lines to
// pick them, then copy and paste them anywhere.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/phone.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_row_actions.dart' show showInfoBanner;
import 'common.dart';
import 'glass.dart';
import 'photo_viewer.dart' show PhotoButton;

/// The photo viewer's "글자" button (hidden where the phone can't read text).
final PhotoButton liveTextButton = (
  key: const Key('photo-text'),
  icon: CupertinoIcons.doc_text_viewfinder,
  label: (L l) => Phone.canReadText ? l.liveTextButton : '',
  onTap: (BuildContext c, Uint8List bytes) => openLiveText(c, bytes),
);

Future<void> openLiveText(BuildContext context, Uint8List bytes) async {
  final lines = await Phone.readText(bytes) ?? const <TextLine>[];
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, a, _) => FadeTransition(
        opacity: a,
        child: LiveTextPage(bytes: bytes, lines: lines),
      ),
    ),
  );
}

class LiveTextPage extends StatefulWidget {
  const LiveTextPage({super.key, required this.bytes, required this.lines});
  final Uint8List bytes;
  final List<TextLine> lines;
  @override
  State<LiveTextPage> createState() => _LiveTextPageState();
}

class _LiveTextPageState extends State<LiveTextPage> {
  Size? image;
  final picked = <int>{};

  @override
  void initState() {
    super.initState();
    ui.decodeImageFromList(widget.bytes, (img) {
      if (mounted) setState(() => image = Size(img.width.toDouble(), img.height.toDouble()));
    });
  }

  /// Where the photo sits inside [box] (fit: contain).
  Rect photoRect(Size box) {
    final im = image ?? box;
    final s = (box.width / im.width).clamp(0.0, box.height / im.height);
    final w = im.width * s, h = im.height * s;
    return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
  }

  Rect lineRect(Rect photo, TextLine t) => Rect.fromLTWH(
    photo.left + t.box.left * photo.width,
    photo.top + t.box.top * photo.height,
    t.box.width * photo.width,
    t.box.height * photo.height,
  ).inflate(3);

  Future<void> copy() async {
    final l = L.of(context);
    final use = picked.isEmpty ? List.generate(widget.lines.length, (i) => i) : (picked.toList()..sort());
    final text = [for (final i in use) widget.lines[i].text].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    showInfoBanner(context, l.liveTextCopied, l.liveTextPaste);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final mq = MediaQuery.of(context);
    const white = Color(0xFFFFFFFF);
    final none = widget.lines.isEmpty;
    return CupertinoPageScaffold(
      key: const Key('live-text'),
      backgroundColor: const Color(0xFF000000),
      child: Column(
        children: [
          SizedBox(
            height: mq.viewPadding.top + Tokens.topBar,
            child: Padding(
              padding: EdgeInsets.only(top: mq.viewPadding.top),
              child: Row(
                children: [
                  CupertinoButton(
                    key: const Key('live-text-close'),
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark, color: white, size: Tokens.closeIcon),
                  ),
                  Expanded(
                    child: Text(
                      l.liveTextTitle,
                      textAlign: TextAlign.center,
                      style: Tokens.navTitle.style.copyWith(color: white),
                    ),
                  ),
                  const SizedBox(width: Tokens.closeButton + 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final photo = photoRect(box.biggest);
                final rects = [for (final t in widget.lines) lineRect(photo, t)];
                return Stack(
                  children: [
                    Positioned.fromRect(
                      rect: photo,
                      child: Image.memory(widget.bytes, fit: BoxFit.fill, gaplessPlayback: true),
                    ),
                    // Everything but the words gets darker.
                    if (!none)
                      Positioned.fill(
                        child: IgnorePointer(child: CustomPaint(painter: _Dim(rects))),
                      ),
                    for (final (i, r) in rects.indexed)
                      Positioned.fromRect(
                        rect: r,
                        child: GestureDetector(
                          key: Key('live-line-$i'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => picked.contains(i) ? picked.remove(i) : picked.add(i)),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: picked.contains(i) ? p.accent.withValues(alpha: 0.35) : const Color(0x00000000),
                              borderRadius: BorderRadius.circular(Tokens.radius[0]),
                            ),
                          ),
                        ),
                      ),
                    if (none)
                      Center(
                        child: LiquidGlass(
                          radius: Tokens.capsule,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                            child: Text(
                              l.liveTextNone,
                              key: const Key('live-text-none'),
                              style: Tokens.body.style.copyWith(color: white),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[2] + mq.viewPadding.bottom),
            child: none
                ? const SizedBox(height: 44)
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          picked.isEmpty ? l.liveTextHint : l.liveTextPicked(picked.length),
                          style: Tokens.caption.style.copyWith(color: white.withValues(alpha: 0.75)),
                        ),
                      ),
                      _Capsule(
                        key: const Key('live-text-all'),
                        label: picked.length == widget.lines.length ? l.liveTextNoneSel : l.liveTextAll,
                        onTap: () =>
                            setState(() => picked.length == widget.lines.length ? picked.clear() : picked.addAll(List.generate(widget.lines.length, (i) => i))),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      _Capsule(key: const Key('live-text-copy'), label: l.copy, onTap: copy, strong: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({super.key, required this.label, required this.onTap, this.strong = false});
  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final text = Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
      child: Text(label, style: Tokens.body.style.copyWith(color: const Color(0xFFFFFFFF))),
    );
    return GestureDetector(
      onTap: onTap,
      child: strong
          ? DecoratedBox(
              decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: text,
            )
          : LiquidGlass(radius: Tokens.capsule, child: text),
    );
  }
}

class _Dim extends CustomPainter {
  _Dim(this.holes);
  final List<Rect> holes;

  @override
  void paint(Canvas canvas, Size size) {
    // One shape with holes (even-odd), so every line stays bright.
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    for (final r in holes) {
      path.addRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)));
    }
    canvas.drawPath(path, Paint()..color = const Color(0x8C000000));
  }

  @override
  bool shouldRepaint(_Dim old) => old.holes != holes;
}
