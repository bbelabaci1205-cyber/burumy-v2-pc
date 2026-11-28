// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 프로필 화면 머리 (Telegram tip 195): the round photo grows into a photo
// across the top of the screen (pull down, or tap when there is no story),
// with the name on the photo, bars for each photo and taps left / right to
// go through them. Scrolling up turns it back into the circle.
import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../design/tokens.dart';

/// One photo in the header, with an optional small label ("내가 정한 사진").
class HeaderPhoto {
  const HeaderPhoto(this.bytes, {this.label = ''});
  final Uint8List bytes;
  final String label;
}

class ProfileTop extends StatefulWidget {
  const ProfileTop({
    super.key,
    required this.photos,
    required this.avatar,
    required this.avatarSize,
    required this.name,
    required this.sub,
    required this.actions,
    this.onAvatarTap,
    this.below = const [],
    this.startOpen = false,
  });

  /// Photos to go through (first = the one in the circle). Empty: the
  /// header stays the circle.
  final List<HeaderPhoto> photos;

  /// The circle as it is drawn when small (story ring and all).
  final Widget avatar;
  final double avatarSize;

  /// The name row; [onPhoto] = drawn white on the big photo.
  final Widget Function(bool onPhoto) name;
  final Widget Function(bool onPhoto) sub;

  /// The round buttons; [onPhoto] = glass buttons on the big photo.
  final Widget Function(bool onPhoto)? actions;

  /// Tap on the small circle (stories). Null: the tap opens the big photo.
  final VoidCallback? onAvatarTap;

  /// Under the name when small (warnings, about), under the photo when big.
  final List<Widget> below;
  final bool startOpen;

  @override
  State<ProfileTop> createState() => ProfileTopState();
}

class ProfileTopState extends State<ProfileTop> with SingleTickerProviderStateMixin {
  late final AnimationController grow = AnimationController(vsync: this, duration: Tokens.profileGrow, value: widget.startOpen ? 1 : 0);
  late final PageController pages = PageController();
  ScrollPosition? _pos;
  int at = 0;

  bool get open => grow.value > 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pos = Scrollable.maybeOf(context)?.position;
    if (pos != _pos) {
      _pos?.removeListener(_scrolled);
      _pos = pos?..addListener(_scrolled);
    }
  }

  @override
  void didUpdateWidget(ProfileTop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.photos.isEmpty && grow.value > 0) grow.value = 0;
    if (at >= widget.photos.length) at = 0;
  }

  @override
  void dispose() {
    _pos?.removeListener(_scrolled);
    grow.dispose();
    pages.dispose();
    super.dispose();
  }

  /// Pull down past the top: grow. Scroll on up: back to the circle.
  void _scrolled() {
    final y = _pos?.pixels ?? 0;
    if (!open && y < -Tokens.profilePullToOpen && widget.photos.isNotEmpty && !grow.isAnimating) {
      setOpen(true);
    } else if (open && y > Tokens.profileScrollToClose && !grow.isAnimating) {
      setOpen(false);
    }
  }

  void setOpen(bool v) {
    if (widget.photos.isEmpty) return;
    unawaited(HapticFeedback.selectionClick());
    unawaited(v ? grow.animateTo(1, curve: Curves.easeOutCubic) : grow.animateTo(0, curve: Curves.easeOutCubic));
  }

  void go(int d) {
    final n = widget.photos.length;
    if (n < 2) return;
    final next = (at + d).clamp(0, n - 1);
    if (next == at) {
      unawaited(HapticFeedback.lightImpact());
      return;
    }
    setState(() => at = next);
    pages.jumpToPage(next);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: grow,
      builder: (context, _) {
        final t = grow.value;
        final small = widget.avatarSize;
        final side = lerpDouble(small, w, t)!;
        final tall = lerpDouble(small, w * Tokens.profilePhotoTall, t)!;
        final round = lerpDouble(small / 2, 0, t)!;
        final photoOn = t > 0.02 && widget.photos.isNotEmpty;
        final late = ((t - 0.5) * 2).clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: lerpDouble(top + Tokens.space[3], 0, t)),
            Center(
              child: SizedBox(
                width: side,
                height: tall,
                child: photoOn
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(round),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PageView(
                              key: const Key('profile-photos'),
                              controller: pages,
                              physics: t < 1 ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                              onPageChanged: (i) => setState(() => at = i),
                              children: [
                                for (final ph in widget.photos) Image.memory(ph.bytes, fit: BoxFit.cover, gaplessPlayback: true, width: side, height: tall),
                              ],
                            ),
                            // Shade at the top (bars, status bar) and bottom (name).
                            IgnorePointer(
                              child: Opacity(
                                opacity: t,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0x59000000), Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
                                      stops: [0, 0.22, 0.55, 1],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Left / right halves go through the photos.
                            if (t == 1)
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      key: const Key('profile-photo-prev'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => widget.photos.length < 2 ? setOpen(false) : go(-1),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      key: const Key('profile-photo-next'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => widget.photos.length < 2 ? setOpen(false) : go(1),
                                    ),
                                  ),
                                ],
                              ),
                            if (widget.photos.length > 1)
                              Positioned(
                                left: Tokens.space[1],
                                right: Tokens.space[1],
                                top: top + Tokens.topBar + Tokens.space[1],
                                child: Opacity(
                                  opacity: late,
                                  child: PhotoBars(count: widget.photos.length, at: at),
                                ),
                              ),
                            if (widget.photos[at.clamp(0, widget.photos.length - 1)].label.isNotEmpty)
                              Positioned(
                                left: Tokens.space[3],
                                top: top + Tokens.topBar + Tokens.space[3],
                                child: Opacity(
                                  opacity: late,
                                  child: PhotoLabel(text: widget.photos[at].label),
                                ),
                              ),
                            Positioned(
                              left: Tokens.space[3],
                              right: Tokens.space[3],
                              bottom: (widget.actions == null ? 0 : Tokens.infoTile + Tokens.space[2]) + Tokens.space[3],
                              child: IgnorePointer(
                                child: Opacity(
                                  opacity: late,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      widget.name(true),
                                      SizedBox(height: Tokens.nameToSub),
                                      widget.sub(true),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (widget.actions != null)
                              Positioned(
                                left: Tokens.space[3],
                                right: Tokens.space[3],
                                bottom: Tokens.space[3],
                                child: Opacity(
                                  opacity: late,
                                  child: IgnorePointer(ignoring: t < 1, child: widget.actions!(true)),
                                ),
                              ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        key: const Key('profile-avatar'),
                        onTap: widget.onAvatarTap ?? (widget.photos.isEmpty ? null : () => setOpen(true)),
                        child: widget.avatar,
                      ),
              ),
            ),
            // The small layout's name and buttons fold away as the photo grows.
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: 1 - t,
                child: Opacity(
                  opacity: (1 - t * 2).clamp(0.0, 1.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: Tokens.space[2]),
                      widget.name(false),
                      SizedBox(height: Tokens.nameToSub),
                      Center(child: widget.sub(false)),
                    ],
                  ),
                ),
              ),
            ),
            if (t > 0) SizedBox(height: Tokens.space[2] * t),
            ...widget.below,
            if (widget.actions != null)
              ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1 - t,
                  child: Opacity(
                    opacity: (1 - t * 2).clamp(0.0, 1.0),
                    child: Padding(
                      padding: EdgeInsets.only(top: Tokens.space[5]),
                      child: widget.actions!(false),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Story-style bars, one per photo; the shown one is bright.
class PhotoBars extends StatelessWidget {
  const PhotoBars({super.key, required this.count, required this.at});
  final int count;
  final int at;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('profile-photo-bars'),
      children: [
        for (var i = 0; i < count; i++)
          Expanded(
            child: Container(
              height: Tokens.profileBarHeight,
              margin: EdgeInsets.symmetric(horizontal: Tokens.profileBarGap / 2),
              decoration: BoxDecoration(
                color: i == at ? const Color(0xFFFFFFFF) : const Color(0x59FFFFFF),
                borderRadius: BorderRadius.circular(Tokens.capsule),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small dark glass capsule on a photo ("내가 정한 사진", "공개 사진").
class PhotoLabel extends StatelessWidget {
  const PhotoLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
      decoration: BoxDecoration(color: const Color(0x66000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
      child: Text(text, style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF))),
    );
  }
}

/// Round button on the big photo: white icon and word on dark glass.
class PhotoAction extends StatelessWidget {
  const PhotoAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        child: Container(
          height: Tokens.infoTile,
          color: const Color(0x33FFFFFF),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFFFFFFF), size: Tokens.listIcon + 2),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Round button on a black photo screen: white icon on a light veil.
class DarkCircle extends StatelessWidget {
  const DarkCircle({super.key, required this.icon, this.onTap, this.size = 44});
  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap ?? () => Navigator.of(context).maybePop(),
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Color(0x2EFFFFFF), shape: BoxShape.circle),
      child: Icon(icon, color: const Color(0xFFFFFFFF), size: 22),
    ),
  );
}
