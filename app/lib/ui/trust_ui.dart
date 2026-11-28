// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사칭 막기 on screen: the official badge and '확인 중' / '가짜' labels next
// to names, the first-chat card for messages from someone new, the
// impersonation report page and the badge application page.
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/backend.dart' show ChatPreview;
import '../core/features.dart';
import '../core/trust.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'wide.dart';
import 'ios.dart';
import 'settings_kit.dart';

/// Small mark after a name: the badge (theme colour seal) or a label.
class TrustMark extends StatelessWidget {
  const TrustMark({super.key, required this.user, required this.name, this.size = 16});
  final String user;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (user.isEmpty) return const SizedBox.shrink();
    final t = AppScope.of(context).trustOf(user, name);
    final l = L.of(context);
    final p = paletteOf(context);
    if (t.fake) return TrustLabel(key: const Key('trust-fake'), text: l.trustFake, color: Palette.tileRed);
    if (t.checking) return TrustLabel(key: const Key('trust-checking'), text: l.trustChecking, color: Palette.tileOrange);
    if (t.official) {
      return Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Icon(CupertinoIcons.checkmark_seal_fill, key: const Key('trust-badge'), size: size, color: p.accent, semanticLabel: l.trustOfficial),
      );
    }
    return const SizedBox.shrink();
  }
}

/// '가짜' / '확인 중': coloured words in a thin capsule (Telegram's SCAM
/// label, in our words).
class TrustLabel extends StatelessWidget {
  const TrustLabel({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 5),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.capsule),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: Tokens.bubbleMeta.style.copyWith(color: color, fontWeight: Tokens.semi),
      ),
    ),
  );
}

/// The warning line for someone (empty when there is nothing to say).
String trustWarning(L l, Trust t) {
  if (t.fake) return l.trustFakeInfo;
  if (t.checking) return l.trustCheckingInfo;
  if (t.looksLike != null) return l.trustNotOfficial(t.looksLike!.name);
  return '';
}

String ageText(L l, String age) => switch (age) {
  'week' => l.ageWeek,
  'month' => l.ageMonth,
  'quarter' => l.ageQuarter,
  'year' => l.ageYear,
  'older' => l.ageOlder,
  _ => l.ageUnknown,
};

/// Card at the top of a 1:1 that someone new started: who they are (as far
/// as we can tell without asking anyone for papers) and three buttons.
class FirstContactCard extends StatefulWidget {
  const FirstContactCard({
    super.key,
    required this.roomId,
    required this.peer,
    required this.name,
    required this.onAccept,
    required this.onBlock,
    required this.onReport,
  });
  final String roomId;
  final String peer;
  final String name;
  final VoidCallback onAccept;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  @override
  State<FirstContactCard> createState() => _FirstContactCardState();
}

class _FirstContactCardState extends State<FirstContactCard> {
  TrustAbout about = const TrustAbout();
  int? common;
  List<ChatPreview> groups = const [];
  bool loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    loaded = true;
    load();
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    try {
      final a = await s.backend.trustAbout(widget.peer);
      if (mounted) setState(() => about = a);
    } catch (_) {}
    // Chats in common: counted on this phone from my own groups.
    var n = 0;
    final found = <ChatPreview>[];
    for (final c in s.chats.where((c) => !c.isDirect).take(40)) {
      try {
        if ((await s.backend.members(c.roomId)).any((m) => m.userId == widget.peer)) {
          n++;
          found.add(c);
        }
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        common = n;
        groups = found;
      });
    }
  }

  String daysText(L l, int d) => d < 0 ? l.firstNotChanged : (d == 0 ? l.firstToday : l.firstDaysAgo(d));

  /// Groups in common: the list, tap one to open it.
  Future<void> showGroups() async {
    final l = L.of(context);
    if (groups.isEmpty) return;
    final pick = await showCupertinoModalPopup<ChatPreview>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.firstGroupsTitle),
        actions: [
          for (final g in groups) CupertinoActionSheetAction(key: Key('first-group-${g.roomId}'), onPressed: () => Navigator.pop(c, g), child: Text(g.name)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick != null && mounted) await openChat(context, pick.roomId, pick.name);
  }

  /// 514 (chat safety): centred card like iOS 27 contact cards — photo,
  /// name, then the facts we can tell without asking for papers.
  Widget richCard(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final t = AppScope.of(context).trustOf(widget.peer, widget.name);
    final warn = trustWarning(l, t);
    final warnColor = t.checking && !t.fake ? Palette.tileOrange : Palette.tileRed;
    Widget line(String k, Widget v, {Key? key, VoidCallback? onTap}) => GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[0] + 1),
        child: Row(
          children: [
            Expanded(
              child: Text(k, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            ),
            v,
          ],
        ),
      ),
    );
    Text value(String v, {bool alert = false}) => Text(v, style: Tokens.preview.style.copyWith(color: alert ? warnColor : p.label));
    Widget button(Key key, String text, VoidCallback onTap, {bool danger = false, bool main = false}) => Expanded(
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: main ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(
            text,
            style: Tokens.preview.style.copyWith(color: main ? p.onAccent : (danger ? Palette.tileRed : p.label), fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
    final stack = groups.take(3).toList();
    return Container(
      key: const Key('first-contact-card'),
      margin: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], Tokens.space[1]),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[3]),
      decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.72), borderRadius: BorderRadius.circular(Tokens.radius[3])),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(name: widget.name, userId: widget.peer, size: 56),
          SizedBox(height: Tokens.space[1]),
          Text(
            widget.name,
            key: const Key('first-name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
          ),
          Text(l.firstAboutTitle, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          if (warn.isNotEmpty) ...[
            SizedBox(height: Tokens.space[1]),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(CupertinoIcons.exclamationmark_triangle_fill, size: Tokens.listIconSmall, color: warnColor),
                ),
                SizedBox(width: Tokens.space[1]),
                Flexible(
                  child: Text(
                    warn,
                    key: const Key('first-contact-warning'),
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: warnColor, fontWeight: Tokens.semi),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: Tokens.space[2]),
          line(l.firstJoined, value(ageText(l, about.age), alert: about.age == 'week'), key: const Key('first-age')),
          line(
            l.firstNameChanged,
            value(daysText(l, about.renamedDays), alert: about.renamedDays >= 0 && about.renamedDays < 7),
            key: const Key('first-renamed'),
          ),
          line(l.firstPhotoChanged, value(daysText(l, about.photoDays), alert: about.photoDays >= 0 && about.photoDays < 7), key: const Key('first-photo')),
          line(
            l.firstGroupsTitle,
            common == null
                ? value('…')
                : common == 0
                ? value(l.firstGroupsNone)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20.0 + 14 * (stack.length - 1),
                        height: 20,
                        child: Stack(
                          children: [
                            for (var i = 0; i < stack.length; i++)
                              Positioned(
                                left: 14.0 * i,
                                child: Avatar(name: stack[i].name, roomId: stack[i].roomId, squircle: true, size: 20),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      value(l.firstCommonCount(common!)),
                      Icon(CupertinoIcons.chevron_right, size: 13, color: p.secondaryLabel),
                    ],
                  ),
            key: const Key('first-common'),
            onTap: (common ?? 0) > 0 ? showGroups : null,
          ),
          line(l.firstVerified, value(t.official ? l.firstVerifiedYes : l.firstVerifiedNo), key: const Key('first-verified')),
          SizedBox(height: Tokens.space[1]),
          Text(
            l.firstTip,
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
          SizedBox(height: Tokens.space[2]),
          Row(
            children: [
              button(const Key('first-accept'), l.firstAccept, widget.onAccept, main: !t.warn),
              SizedBox(width: Tokens.space[1]),
              button(const Key('first-block'), l.firstBlock, widget.onBlock, danger: true),
              SizedBox(width: Tokens.space[1]),
              button(const Key('first-report'), l.firstReport, widget.onReport, danger: true),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Features.chatSafety) return richCard(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final t = AppScope.of(context).trustOf(widget.peer, widget.name);
    final warn = trustWarning(l, t);
    final warnColor = t.checking && !t.fake ? Palette.tileOrange : Palette.tileRed;
    Widget line(String k, String v, {bool alert = false, Key? key}) => Padding(
      padding: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          ),
          Text(
            v,
            key: key,
            style: Tokens.preview.style.copyWith(color: alert ? warnColor : p.label),
          ),
        ],
      ),
    );
    Widget button(Key key, String text, VoidCallback onTap, {bool danger = false, bool main = false}) => Expanded(
      child: GestureDetector(
        key: key,
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: main ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(
            text,
            style: Tokens.preview.style.copyWith(color: main ? p.onAccent : (danger ? Palette.tileRed : p.label), fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
    return Container(
      key: const Key('first-contact-card'),
      margin: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
      padding: EdgeInsets.all(Tokens.space[3]),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (warn.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(CupertinoIcons.exclamationmark_triangle_fill, size: Tokens.listIconSmall, color: warnColor),
                ),
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: Text(
                    warn,
                    key: const Key('first-contact-warning'),
                    style: Tokens.preview.style.copyWith(color: warnColor, fontWeight: Tokens.semi),
                  ),
                ),
              ],
            ),
            SizedBox(height: Tokens.space[1]),
          ],
          Text(
            l.firstTitle,
            style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: Tokens.space[1]),
          line(l.firstJoined, ageText(l, about.age), alert: about.age == 'week', key: const Key('first-age')),
          line(l.firstRenamed, about.renamed ? l.firstRenamedRecent : l.firstRenamedNo, alert: about.renamed, key: const Key('first-renamed')),
          line(l.firstCommon, common == null ? '…' : l.firstCommonCount(common!), key: const Key('first-common')),
          line(l.firstVerified, t.official ? l.firstVerifiedYes : l.firstVerifiedNo, key: const Key('first-verified')),
          SizedBox(height: Tokens.space[1]),
          Text(l.firstTip, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          SizedBox(height: Tokens.space[2]),
          Row(
            children: [
              button(const Key('first-accept'), l.firstAccept, widget.onAccept, main: !t.warn),
              SizedBox(width: Tokens.space[1]),
              button(const Key('first-block'), l.firstBlock, widget.onBlock, danger: true),
              SizedBox(width: Tokens.space[1]),
              button(const Key('first-report'), l.firstReport, widget.onReport, danger: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// "사칭이에요": a full page (no pop-up typing), who is being copied and a
/// note. Returns true when sent.
class ImpersonationReportPage extends StatefulWidget {
  const ImpersonationReportPage({super.key, required this.userId, required this.name});
  final String userId;
  final String name;

  @override
  State<ImpersonationReportPage> createState() => _ImpersonationReportPageState();
}

class _ImpersonationReportPageState extends State<ImpersonationReportPage> {
  final who = TextEditingController(), note = TextEditingController();
  bool busy = false, failed = false, ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    // Already looks like a badge holder: that is who they copy.
    final t = AppScope.read(context).trustOf(widget.userId, widget.name);
    if (t.looksLike != null) who.text = t.looksLike!.name;
  }

  @override
  void dispose() {
    who.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final s = AppScope.read(context);
    setState(() {
      busy = true;
      failed = false;
    });
    // A badge holder's name typed in: send their ID so the operator sees
    // the pair (and the badge holder's own report goes first).
    final typed = who.text.trim();
    final badge = s.trust.badges.where((b) => skeleton(b.name) == skeleton(typed) || b.user == typed).firstOrNull;
    try {
      await s.backend.reportImpersonation(widget.userId, victim: badge?.user ?? typed, note: note.text.trim());
      await s.refreshTrust();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key key, TextEditingController c, String hint, {int lines = 1, int max = 80}) => CupertinoTextField.borderless(
      key: key,
      controller: c,
      placeholder: hint,
      placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
      style: Tokens.body.style.copyWith(color: p.label),
      maxLength: max,
      minLines: 1,
      maxLines: lines,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[2] + 2),
    );
    return SettingsScaffold(
      title: l.reportImpTitle,
      children: [
        HeaderCard(color: Palette.tileRed, icon: CupertinoIcons.person_crop_circle_badge_exclam, title: l.reportImpTitle, body: l.reportImpInfo),
        IosSection(hasLeading: false, header: sectionHeader(context, l.reportImpWho), children: [field(const Key('imp-who'), who, l.reportImpWhoHint)]),
        IosSection(
          hasLeading: false,
          footer: failed ? sectionFooter(context, l.reportFailed, error: true) : null,
          children: [field(const Key('imp-note'), note, l.reportImpNote, lines: 5, max: 500)],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[3]),
          child: CupertinoButton.filled(
            key: const Key('imp-send'),
            onPressed: busy ? null : send,
            borderRadius: BorderRadius.circular(Tokens.capsule),
            child: busy
                ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                : Text(l.reportImpSend, style: Tokens.body.style.copyWith(color: p.onAccent)),
          ),
        ),
      ],
    );
  }
}

/// 설정 > 공식 배지: the code to post, what kind, where it was posted.
class BadgeApplyPage extends StatefulWidget {
  const BadgeApplyPage({super.key});

  @override
  State<BadgeApplyPage> createState() => _BadgeApplyPageState();
}

class _BadgeApplyPageState extends State<BadgeApplyPage> {
  String? code;
  String kind = 'person';
  bool busy = false, sent = false, failed = false, copied = false, loaded = false;
  String myName = '';
  final name = TextEditingController(), proof = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loaded) return;
    loaded = true;
    load();
  }

  Future<void> load() async {
    final s = AppScope.read(context);
    try {
      myName = await s.backend.myName();
      if (name.text.isEmpty) name.text = myName;
    } catch (_) {}
    try {
      final c = await s.backend.badgeCode();
      if (mounted) setState(() => code = c);
    } catch (_) {
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void dispose() {
    name.dispose();
    proof.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (name.text.trim().isEmpty || proof.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      failed = false;
    });
    try {
      await AppScope.read(context).backend.applyBadge(kind: kind, name: name.text.trim(), proof: proof.text.trim());
      if (mounted) {
        setState(() {
          busy = false;
          sent = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final me = s.backend.userId ?? '';
    final have = s.trustOf(me, myName).official;
    Widget field(Key key, TextEditingController c, String hint, {int max = 64}) => CupertinoTextField.borderless(
      key: key,
      controller: c,
      placeholder: hint,
      placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
      style: Tokens.body.style.copyWith(color: p.label),
      maxLength: max,
      autocorrect: false,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[2] + 2),
      onChanged: (_) => setState(() {}),
    );
    Widget kindRow(String k, String title) => IosTile(
      key: Key('badge-kind-$k'),
      title: Text(title),
      trailing: kind == k ? Icon(CupertinoIcons.checkmark_alt, color: p.accent, size: Tokens.listIcon) : null,
      onTap: () => setState(() => kind = k),
    );
    return SettingsScaffold(
      title: l.badgeTitle,
      children: [
        HeaderCard(color: p.tileGreen, icon: CupertinoIcons.checkmark_seal_fill, title: l.badgeTitle, body: l.badgeInfo),
        if (have)
          group(context, [
            IosTile(
              key: const Key('badge-have'),
              leading: Icon(CupertinoIcons.checkmark_seal_fill, color: p.accent, size: Tokens.listIcon),
              title: Text(l.badgeHave),
            ),
          ], footer: l.badgeRenameNote)
        else if (sent)
          group(context, [IosTile(key: const Key('badge-sent'), title: Text(l.badgeSent, maxLines: 3))])
        else ...[
          IosSection(
            hasLeading: false,
            header: sectionHeader(context, l.badgeCode),
            footer: sectionFooter(context, failed && code == null ? l.badgeFailed : l.badgeStep, error: failed && code == null),
            children: [
              IosTile(
                key: const Key('badge-code'),
                title: Text(
                  code ?? '…',
                  style: Tokens.body.style.copyWith(color: p.label, fontFeatures: const [FontFeature.tabularFigures()], letterSpacing: 0.5),
                ),
                trailing: code == null
                    ? null
                    : GestureDetector(
                        key: const Key('badge-copy'),
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: code!));
                          if (mounted) setState(() => copied = true);
                        },
                        child: Text(copied ? l.badgeCopied : l.badgeCopy, style: Tokens.body.style.copyWith(color: p.accent)),
                      ),
              ),
            ],
          ),
          IosSection(
            hasLeading: false,
            header: sectionHeader(context, l.badgeKind),
            children: [kindRow('person', l.badgeKindPerson), kindRow('brand', l.badgeKindBrand), kindRow('channel', l.badgeKindChannel)],
          ),
          IosSection(
            hasLeading: false,
            footer: failed && code != null ? sectionFooter(context, l.badgeFailed, error: true) : null,
            children: [field(const Key('badge-name'), name, l.badgeName), field(const Key('badge-proof'), proof, l.badgeProof, max: 300)],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[3]),
            child: CupertinoButton.filled(
              key: const Key('badge-send'),
              onPressed: busy || code == null || name.text.trim().isEmpty || proof.text.trim().isEmpty ? null : send,
              borderRadius: BorderRadius.circular(Tokens.capsule),
              child: busy
                  ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                  : Text(l.badgeSend, style: Tokens.body.style.copyWith(color: p.onAccent)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Refusal words for a name or ID check result ('' = fine).
String nameRefusal(L l, String why, {bool id = false}) => switch (why) {
  'mark' => l.nameMarkRefused,
  'reserved' => id ? l.idReservedRefused : l.nameReservedRefused,
  'reserved_owner' => id ? l.idReservedOwner : l.roomReservedOwner,
  'reserved_sale' => l.idReservedSale,
  'lookalike' => l.idLookalikeRefused,
  _ => '',
};
