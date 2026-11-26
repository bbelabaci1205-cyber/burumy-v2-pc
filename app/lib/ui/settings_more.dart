// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// More Settings pieces: the security check card and page, account,
// FAQ, feature tour and About (iOS 27 Settings look).
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../brand/brand.dart';
import '../brand/mark.dart';
import '../core/app_state.dart';
import '../core/qr.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'settings_page.dart';
import 'settings_pages.dart';

const appVersion = '1.0.0';

/// What the security check looks at: (recovery key made, this device confirmed).
Future<(bool, bool)> securityState(AppState s) async {
  final r = await s.backend.hasRecovery().catchError((_) => false);
  final d = await s.backend.thisDeviceVerified().catchError((_) => false);
  return (r, d);
}

/// The ring + "Security check 1/2" card under my account card.
class SecurityCheckCard extends StatefulWidget {
  const SecurityCheckCard({super.key});
  @override
  State<SecurityCheckCard> createState() => _SecurityCheckCardState();
}

class _SecurityCheckCardState extends State<SecurityCheckCard> {
  (bool, bool)? state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (state == null) load();
  }

  Future<void> load() async {
    final v = await securityState(AppScope.of(context));
    if (mounted) setState(() => state = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final st = state ?? (false, false);
    final done = (st.$1 ? 1 : 0) + (st.$2 ? 1 : 0);
    final all = done == 2;
    final ring = all ? p.tileGreen : Palette.tileOrange;
    return IosSection(
      children: [
        GestureDetector(
          key: const Key('security-check'),
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await Navigator.of(context).push(IosPageRoute(builder: (_) => const SecurityCheckPage()));
            await load();
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressRing(value: state == null ? 0 : done / 2, color: ring, track: p.separator),
                      Icon(all ? CupertinoIcons.checkmark_shield : CupertinoIcons.shield, size: 20, color: ring),
                    ],
                  ),
                ),
                SizedBox(width: Tokens.space[3]),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.securityCheck(done, 2),
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(all ? l.securityAllDone : l.securityLeft(2 - done), maxLines: 2, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ],
                  ),
                ),
                const IosChevron(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A thin progress ring (no Material).
class CircularProgressRing extends StatelessWidget {
  const CircularProgressRing({super.key, required this.value, required this.color, required this.track});
  final double value;
  final Color color, track;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => CustomPaint(size: const Size.square(40), painter: _Ring(v, color, track)),
  );
}

class _Ring extends CustomPainter {
  _Ring(this.v, this.color, this.track);
  final double v;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(r, 0, 6.2832, false, base..color = track);
    if (v > 0) canvas.drawArc(r, -1.5708, 6.2832 * v, false, base..color = color);
  }

  @override
  bool shouldRepaint(_Ring o) => o.v != v || o.color != color || o.track != track;
}

class SecurityCheckPage extends StatefulWidget {
  const SecurityCheckPage({super.key});
  @override
  State<SecurityCheckPage> createState() => _SecurityCheckPageState();
}

class _SecurityCheckPageState extends State<SecurityCheckPage> {
  (bool, bool)? state;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (state == null) load();
  }

  Future<void> load() async {
    final v = await securityState(AppScope.of(context));
    if (mounted) setState(() => state = v);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final st = state ?? (false, false);
    // Like iOS Safety Check: things still to do first (with a chevron), finished ones
    // below with a green check. The description gets the full row width.
    Widget row(String key, bool done, Color c, IconData icon, String title, String info, Future<void> Function() fix) => GestureDetector(
      key: Key(key),
      behavior: HitTestBehavior.opaque,
      onTap: done
          ? null
          : () async {
              await fix();
              await load();
            },
      child: Padding(
        padding: IosTile.iconedPad.add(EdgeInsets.symmetric(vertical: Tokens.space[3])),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconTile(c, icon),
            const SizedBox(width: IosTile.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  Text(info, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            done ? Icon(CupertinoIcons.checkmark_circle_fill, key: Key('$key-done'), size: 22, color: p.tileGreen) : const IosChevron(),
          ],
        ),
      ),
    );
    final items = [
      (
        st.$1,
        row(
          'check-recovery',
          st.$1,
          Palette.tileOrange,
          CupertinoIcons.arrow_clockwise,
          l.checkRecovery,
          l.checkRecoveryInfo,
          () => SettingsPage.showKey(context),
        ),
      ),
      (
        st.$2,
        row(
          'check-device',
          st.$2,
          Palette.tileBlue,
          CupertinoIcons.device_phone_portrait,
          l.checkDevice,
          l.checkDeviceInfo,
          () => SettingsPage.enterKey(context),
        ),
      ),
    ];
    final todo = [
      for (final i in items)
        if (!i.$1) i.$2,
    ];
    final done = [
      for (final i in items)
        if (i.$1) i.$2,
    ];
    return SettingsScaffold(
      title: l.securityCheckTitle,
      children: [
        HeaderCard(
          color: todo.isEmpty ? p.tileGreen : Palette.tileOrange,
          icon: CupertinoIcons.checkmark_shield_fill,
          title: l.securityCheckTitle,
          body: todo.isEmpty ? l.securityAllDone : l.securityCheckInfo,
        ),
        if (todo.isNotEmpty) group(context, header: l.checkSectionTodo, todo),
        if (done.isNotEmpty) group(context, header: l.checkDone, done),
      ],
    );
  }
}

/// Settings > Account: ID, password, devices, keys.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool copied = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = displayId(s.backend.userId ?? '');
    void open(Widget w) => Navigator.of(context).push(IosPageRoute(builder: (_) => w));
    return SettingsScaffold(
      title: l.accountManage,
      children: [
        HeaderCard(color: Palette.tileGrey, icon: CupertinoIcons.person_crop_circle_fill, title: l.accountManage, body: l.accountManageInfo),
        group(context, [
          IosTile(
            key: const Key('account-id'),
            leading: iconTile(Palette.tileBlue, CupertinoIcons.at),
            title: Text(l.myId),
            additionalInfo: Text(copied ? l.copied : id),
            trailing: Icon(CupertinoIcons.doc_on_doc, size: 18, color: p.accent),
            onTap: () {
              Clipboard.setData(ClipboardData(text: id));
              setState(() => copied = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => copied = false);
              });
            },
          ),
        ]),
        group(context, [
          NavRow(color: Palette.tileOrange, icon: CupertinoIcons.textformat_abc, title: l.changePassword, onTap: () => open(const ChangePasswordPage())),
          NavRow(color: p.tileBlack, icon: CupertinoIcons.device_laptop, title: l.devices, onTap: () => open(const DevicesPage())),
          NavRow(color: p.tileGreen, icon: CupertinoIcons.lock_shield, title: l.encryptionKeys, onTap: () => open(const KeysPage())),
        ]),
      ],
    );
  }
}

/// Settings > FAQ: questions that open in place.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});
  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  int? open;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final qa = [
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
      (l.faqQ5, l.faqA5),
      (l.faqQ6, l.faqA6),
      (l.faqQ7, l.faqA7),
      (l.faqQ8, l.faqA8),
    ];
    return SettingsScaffold(
      title: l.faq,
      children: [
        HeaderCard(color: Palette.tileTeal, icon: CupertinoIcons.question_circle_fill, title: l.faq, body: l.faqHeaderInfo),
        group(context, [
          for (final (i, (q, a)) in qa.indexed)
            GestureDetector(
              key: Key('faq-$i'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => open = open == i ? null : i),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(q, style: Tokens.body.style.copyWith(color: p.label)),
                        ),
                        AnimatedRotation(
                          turns: open == i ? 0.25 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(CupertinoIcons.chevron_forward, size: 16, color: p.secondaryLabel),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topLeft,
                      child: open == i
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                a,
                                key: Key('faq-a-$i'),
                                style: Tokens.caption.style.copyWith(color: p.secondaryLabel, height: 1.45),
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                  ],
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

/// Settings > What Burumy can do.
class FeatureTourPage extends StatelessWidget {
  const FeatureTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final items = [
      (p.tileGreen, CupertinoIcons.lock_fill, l.tourE2e, l.tourE2eBody),
      (Palette.tileOrange, CupertinoIcons.timer, l.tourTimer, l.tourTimerBody),
      (Palette.tilePurple, CupertinoIcons.eye_slash_fill, l.tourOnce, l.tourOnceBody),
      (Palette.tileCyan, CupertinoIcons.circle_grid_hex_fill, l.tourBubble, l.tourBubbleBody),
      (Palette.tileRed, CupertinoIcons.flame_fill, l.tourStreak, l.tourStreakBody),
      (Palette.tileBlue, CupertinoIcons.person_3_fill, l.tourGroups, l.tourGroupsBody),
      (Palette.tileIndigo, CupertinoIcons.checkmark_square_fill, l.tourTools, l.tourToolsBody),
      (Palette.tileTeal, CupertinoIcons.location_fill, l.tourLocation, l.tourLocationBody),
    ];
    return SettingsScaffold(
      title: l.featureTour,
      children: [
        HeaderCard(color: Palette.tileYellow, icon: CupertinoIcons.lightbulb_fill, title: l.featureTour, body: l.featureTourInfo),
        group(context, [
          for (final (c, icon, title, body) in items)
            IosTile(
              leading: iconTile(c, icon),
              title: Text(title),
              subtitle: Text(body, maxLines: 2, style: Tokens.caption.style),
            ),
        ]),
      ],
    );
  }
}

/// Settings > About: mark, name, version, licenses.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.aboutApp,
      children: [
        SizedBox(height: Tokens.space[3]),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: ShapeDecoration(
              color: p.accent,
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(22)),
            ),
            alignment: Alignment.center,
            child: BurumyMark(color: p.onAccent, size: 52),
          ),
        ),
        SizedBox(height: Tokens.space[2]),
        Center(
          child: Text(l.appName, style: Tokens.cardTitle.style.copyWith(color: p.label)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            l.appVersion(appVersion),
            key: const Key('about-version'),
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[3], Tokens.space[5], Tokens.space[1]),
          child: Text(
            l.aboutInfo,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel, height: 1.45),
          ),
        ),
        group(context, [
          NavRow(
            key: const Key('licenses-row'),
            color: Palette.tileGrey,
            icon: CupertinoIcons.doc_text_fill,
            title: l.openSourceLicenses,
            page: (_) => const LicensesPage(),
          ),
        ]),
        Center(
          child: Text('© 2026 ${Brand.nameEn}', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

/// Every package's licence text, grouped by package.
class LicensesPage extends StatefulWidget {
  const LicensesPage({super.key});
  @override
  State<LicensesPage> createState() => _LicensesPageState();
}

class _LicensesPageState extends State<LicensesPage> {
  Map<String, List<String>>? byPackage;

  @override
  void initState() {
    super.initState();
    LicenseRegistry.licenses
        .fold<Map<String, List<String>>>({}, (m, e) {
          final text = e.paragraphs.map((p) => p.text).join('\n\n');
          for (final pkg in e.packages) {
            (m[pkg] ??= []).add(text);
          }
          return m;
        })
        .then((m) {
          if (mounted) setState(() => byPackage = m);
        });
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final m = byPackage;
    final names = (m?.keys.toList() ?? [])..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return SettingsScaffold(
      title: l.openSourceLicenses,
      children: [
        if (m == null)
          const Padding(padding: EdgeInsets.all(40), child: CupertinoActivityIndicator())
        else
          group(context, [
            for (final n in names)
              NavRow(
                title: n,
                page: (c) => SettingsScaffold(
                  title: n,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(Tokens.space[3]),
                      child: Text(
                        m[n]!.join('\n\n────────\n\n'),
                        style: Tokens.caption.style.copyWith(color: paletteOf(c).secondaryLabel, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
      ],
    );
  }
}

/// The link a QR code carries for me. The web address waits for the domain.
String userLink(String id) => 'burumy://u/$id';

/// Settings > QR button: my ID as a QR code on a white card.
class MyQrPage extends StatefulWidget {
  const MyQrPage({super.key, this.userId, this.title});

  /// Someone else's code (from their profile); mine when null.
  final String? userId;
  final String? title;
  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  bool copied = false;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final id = displayId(widget.userId ?? AppScope.of(context).backend.userId ?? '');
    final code = QrCode.encode(userLink(id));
    return SettingsScaffold(
      title: widget.title ?? l.myQr,
      children: [
        SizedBox(height: Tokens.space[3]),
        Center(
          child: Container(
            key: const Key('my-qr-code'),
            width: 260,
            padding: const EdgeInsets.all(22),
            decoration: ShapeDecoration(
              color: const Color(0xFFFFFFFF),
              shape: RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(30)),
              shadows: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6))],
            ),
            child: Column(
              children: [
                if (code != null) AspectRatio(aspectRatio: 1, child: CustomPaint(painter: QrPainter(code, const Color(0xFF16241B)))),
                const SizedBox(height: 14),
                Text(
                  id,
                  style: Tokens.body.style.copyWith(color: const Color(0xFF16241B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[3], Tokens.space[5], 0),
          child: Text(
            l.myQrInfo,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
        group(context, [
          IosTile(
            key: const Key('qr-copy'),
            leading: iconTile(Palette.tileBlue, CupertinoIcons.doc_on_doc_fill),
            title: Text(copied ? l.copied : l.copy),
            onTap: () {
              Clipboard.setData(ClipboardData(text: id));
              setState(() => copied = true);
            },
          ),
        ]),
      ],
    );
  }
}

class QrPainter extends CustomPainter {
  QrPainter(this.code, this.color);
  final QrCode code;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / code.size;
    final paint = Paint()..color = color;
    bool finder(int x, int y) => (x < 7 && y < 7) || (x >= code.size - 7 && y < 7) || (x < 7 && y >= code.size - 7);
    for (var y = 0; y < code.size; y++) {
      for (var x = 0; x < code.size; x++) {
        if (finder(x, y) || !code.dark(x, y)) continue;
        // Soft round dots (still read fine: centres stay dark).
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x * cell + cell * .06, y * cell + cell * .06, cell * .88, cell * .88), Radius.circular(cell * .3)),
          paint,
        );
      }
    }
    // The three corner eyes, rounded.
    for (final (fx, fy) in [(0, 0), (code.size - 7, 0), (0, code.size - 7)]) {
      final o = Rect.fromLTWH(fx * cell, fy * cell, cell * 7, cell * 7);
      canvas.drawDRRect(RRect.fromRectAndRadius(o, Radius.circular(cell * 2.2)), RRect.fromRectAndRadius(o.deflate(cell), Radius.circular(cell * 1.5)), paint);
      canvas.drawRRect(RRect.fromRectAndRadius(o.deflate(cell * 2), Radius.circular(cell * 1.1)), paint);
    }
  }

  @override
  bool shouldRepaint(QrPainter o) => o.code != code || o.color != color;
}
