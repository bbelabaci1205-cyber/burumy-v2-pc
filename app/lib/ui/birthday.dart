// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Birthdays (TelegramTips 446, our way, no paid gifts): a banner on top of
// the chat list "민아님이 오늘 생일이에요!" with the friends' small photos,
// and balloons + confetti when I open a friend's info on their birthday.
// Birthdays are only "MM-DD" (friends never see a year), so we show a cake,
// never an age. Everything is worked out on this phone.
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'ios.dart';
import 'wide.dart';

/// True when "MM-DD" (or "YYYY-MM-DD") is [day].
bool isBirthdayOn(String birthday, DateTime day) {
  final p = birthday.split('-');
  if (p.length < 2) return false;
  final m = int.tryParse(p[p.length - 2]), d = int.tryParse(p.last);
  if (m == null || d == null) return false;
  // 29 February: celebrated on 28 February in other years.
  final leap = DateTime(day.year, 2, 29).month == 2;
  if (m == 2 && d == 29 && !leap) return day.month == 2 && day.day == 28;
  return day.month == m && day.day == d;
}

String todayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// 1:1 friends whose birthday is today (cards I was allowed to see).
List<ChatPreview> birthdaysToday(AppState s, {DateTime? now}) {
  final day = now ?? DateTime.now();
  return [
    for (final c in s.chats)
      if (c.isDirect && !c.isBot && c.peer.isNotEmpty && isBirthdayOn(s.cardOf(c.peer)?.birthday ?? '', day)) c,
  ];
}

/// The banner over the chat list; × hides it until tomorrow.
class BirthdayBanner extends StatelessWidget {
  const BirthdayBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final now = DateTime.now();
    if (s.pref('birthday_banner_closed', '') == todayKey(now)) return const SizedBox.shrink();
    final list = birthdaysToday(s, now: now);
    if (list.isEmpty) return const SizedBox.shrink();
    final l = L.of(context);
    final p = paletteOf(context);
    final title = list.length == 1 ? l.birthdayBannerOne(list.first.name) : l.birthdayBannerMany(list.length);
    return Padding(
      key: const Key('birthday-banner'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[1]),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => list.length == 1 ? openChat(context, list.first.roomId, list.first.name) : pickBirthdayFriend(context, list),
        child: Container(
          padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[2], 0, Tokens.space[2]),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
          child: Row(
            children: [
              SizedBox(
                width: 28.0 + 18 * (math.min(list.length, 3) - 1),
                height: 28,
                child: Stack(
                  children: [
                    for (final (i, c) in list.take(3).indexed)
                      Positioned(
                        left: 18.0 * i,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: p.card, width: 2),
                          ),
                          child: Avatar(name: c.name, userId: c.peer, size: 24),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title 🎂',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                    ),
                    Text(
                      l.birthdayBannerSub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                key: const Key('birthday-banner-close'),
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => s.setPref('birthday_banner_closed', todayKey(now)),
                child: Icon(CupertinoIcons.xmark, size: Tokens.listIcon - 4, color: p.secondaryLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Several birthdays today: pick whose chat to open.
Future<void> pickBirthdayFriend(BuildContext context, List<ChatPreview> list) async {
  final l = L.of(context);
  final got = await showCupertinoModalPopup<ChatPreview>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => IosActionSheet(
      title: Text(l.birthdayBannerMany(list.length)),
      actions: [
        for (final x in list)
          CupertinoActionSheetAction(key: Key('birthday-pick-${x.roomId}'), onPressed: () => Navigator.pop(c, x), child: Text('🎂 ${x.name}')),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (got != null && context.mounted) await openChat(context, got.roomId, got.name);
}

/// Balloons float up and confetti falls for a few seconds (no touches).
class BirthdayParty extends StatefulWidget {
  const BirthdayParty({super.key});
  static const length = Duration(milliseconds: 3600);
  @override
  State<BirthdayParty> createState() => _BirthdayPartyState();
}

class _BirthdayPartyState extends State<BirthdayParty> with SingleTickerProviderStateMixin {
  late final AnimationController t = AnimationController(vsync: this, duration: BirthdayParty.length)..forward();

  @override
  void dispose() {
    t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (_, _) =>
            t.isCompleted ? const SizedBox.shrink() : CustomPaint(key: const Key('birthday-party'), painter: _Party(t.value), size: Size.infinite),
      ),
    );
  }
}

class _Party extends CustomPainter {
  _Party(this.v);
  final double v;
  static const colors = [Palette.tileRed, Palette.tileOrange, Palette.tileYellow, Palette.tileBlue, Palette.tilePurple, Palette.tilePink, Palette.tileTeal];

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final fade = v > .8 ? (1 - v) / .2 : 1.0;
    // Confetti: small turning pieces falling from the top.
    for (var i = 0; i < 70; i++) {
      final x0 = r.nextDouble() * size.width;
      final speed = .6 + r.nextDouble() * .8;
      final y = -20 + (size.height + 40) * ((v * speed + r.nextDouble() * .25) % 1.1);
      final x = x0 + math.sin(v * 8 + i) * 14;
      final paint = Paint()..color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(v * 10 * (i.isEven ? 1 : -1) + i);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -2, 8, 4), const Radius.circular(1)), paint);
      canvas.restore();
    }
    // Balloons: rise from the bottom, swaying, with a string.
    for (var i = 0; i < 9; i++) {
      final w = 34.0 + r.nextDouble() * 16;
      final x = size.width * (.08 + .84 * r.nextDouble()) + math.sin(v * 5 + i) * 10;
      final delay = r.nextDouble() * .25;
      final up = ((v - delay) / .8).clamp(0.0, 1.0);
      final y = size.height + w - up * (size.height + w * 3);
      final c = colors[(i * 3) % colors.length].withValues(alpha: .92 * fade);
      final body = Rect.fromCenter(center: Offset(x, y), width: w, height: w * 1.2);
      final string = Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final path = Path()
        ..moveTo(x, body.bottom)
        ..quadraticBezierTo(x + 6, body.bottom + 20, x - 2, body.bottom + 44);
      canvas.drawPath(path, string..color = c.withValues(alpha: .5 * fade));
      canvas.drawOval(body, Paint()..color = c);
      // The soft shine on the top left.
      canvas.drawOval(
        Rect.fromLTWH(body.left + w * .2, body.top + w * .18, w * .22, w * .3),
        Paint()..color = const Color(0x55FFFFFF).withValues(alpha: .33 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_Party old) => old.v != v;
}
