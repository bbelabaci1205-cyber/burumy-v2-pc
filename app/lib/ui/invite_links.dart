// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Invite links for groups and channels (manual 6-1, 6-6, 6-7):
// - InviteLinkPage: private link or public address, copy / share, approval,
//   promo image, and the public channel web page (owner turns it on).
// - JoinRequestsPage: people who asked to come in (approval on).
// - JoinLinkPage: what a link shows before coming in, then join or ask.
// iOS layout (Settings list), Telegram's channel-type page as reference.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/features.dart';
import '../core/phone.dart';
import '../core/room_links.dart';
import '../core/trust.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'invite_links_more.dart';
import 'join_gate_pages.dart';
import 'poster.dart';
import 'settings_kit.dart';
import 'wide.dart';

/// The full link text for a room's link ("" for none).
String roomLinkText(RoomLink link, {String name = '', bool channel = false}) => switch (link.kind) {
  'public' => RoomLinks.public(link.code),
  'private' => RoomLinks.private(link.code, name: name, channel: channel),
  _ => '',
};

/// The grey link box with 복사 / 공유 under it (Telegram iOS look).
class LinkCard extends StatefulWidget {
  const LinkCard({super.key, required this.link, this.showText = true});
  final String link;

  /// Public addresses show the address in the field above instead.
  final bool showText;

  @override
  State<LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends State<LinkCard> {
  bool copied = false;
  Timer? back;

  @override
  void dispose() {
    back?.cancel();
    super.dispose();
  }

  Future<void> copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link));
    if (!mounted) return;
    setState(() => copied = true);
    back?.cancel();
    back = Timer(const Duration(seconds: 2), () => mounted ? setState(() => copied = false) : null);
  }

  Future<void> share() async {
    final l = L.of(context);
    final r = await Phone.share(text: '${l.linkShareText}\n${widget.link}');
    if (r == 'copied' && mounted) setState(() => copied = true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget button(Key key, String text, VoidCallback onTap) => Expanded(
      child: CupertinoButton(
        key: key,
        color: p.accent,
        padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
        borderRadius: BorderRadius.circular(Tokens.capsule),
        onPressed: onTap,
        child: Text(
          text,
          style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.all(Tokens.space[3]),
      child: Column(
        children: [
          if (widget.showText) ...[
            Container(
              key: const Key('link-text'),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.radius[1])),
              child: Text(
                RoomLinks.shown(widget.link),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Tokens.body.style.copyWith(color: p.label),
              ),
            ),
            SizedBox(height: Tokens.space[2]),
          ],
          Row(
            children: [
              button(const Key('link-copy'), copied ? l.copied : l.copy, copy),
              SizedBox(width: Tokens.space[2]),
              button(const Key('link-share'), l.linkShare, share),
            ],
          ),
        ],
      ),
    );
  }
}

class InviteLinkPage extends StatefulWidget {
  const InviteLinkPage({super.key, required this.roomId, required this.name, required this.isChannel});
  final String roomId;
  final String name;
  final bool isChannel;

  @override
  State<InviteLinkPage> createState() => _InviteLinkPageState();
}

class _InviteLinkPageState extends State<InviteLinkPage> {
  RoomLink link = const RoomLink();
  bool loaded = false;

  /// Chosen on the page ("public" / "private"); saved with 완료.
  String mode = 'private';
  final address = TextEditingController();

  /// '', 'checking', 'free', 'taken', 'bad', 'reserved'.
  String check = '';
  Timer? wait;
  int requests = 0;
  bool gateOn = false;

  /// 초대 링크 여러 개: how many came in through the main private link.
  (int, List<String>) mainUses = (0, const []);
  bool busy = false;
  String? failed;

  Backend get b => AppScope.read(context).backend;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    wait?.cancel();
    address.dispose();
    super.dispose();
  }

  Future<void> load() async {
    var now = await b.roomLink(widget.roomId);
    // Telegram: a private link is ready the first time this page opens.
    if (now.kind == 'none') {
      try {
        now = await b.newPrivateLink(widget.roomId);
      } catch (_) {}
    }
    final asks = now.approval ? (await b.joinRequests(widget.roomId)).length : 0;
    final cfg = Features.joinGate ? await b.roomConfig(widget.roomId) : const <String, dynamic>{};
    final uses = Features.shareLinks ? await b.mainLinkUses(widget.roomId).catchError((_) => (0, const <String>[])) : (0, const <String>[]);
    if (!mounted) return;
    setState(() {
      mainUses = uses;
      gateOn = GateSettings.from(cfg).on;
      link = now;
      mode = now.public ? 'public' : 'private';
      if (now.public) address.text = now.code;
      check = now.public ? 'free' : '';
      requests = asks;
      loaded = true;
    });
  }

  /// Something chosen here is not saved yet.
  bool get pending => loaded && (mode == 'public' ? !(link.public && address.text.trim().toLowerCase() == link.code) : link.public);

  bool get canSave => pending && !busy && (mode == 'private' || check == 'free');

  void typed(String v) {
    wait?.cancel();
    final a = v.trim().toLowerCase();
    if (a.isEmpty) {
      setState(() => check = '');
      return;
    }
    if (!RegExp(r'^[a-z][a-z0-9_]{4,31}$').hasMatch(a) || a.endsWith('_') || a.contains('__') || a.startsWith('j_')) {
      setState(() => check = 'bad');
      return;
    }
    setState(() => check = 'checking');
    wait = Timer(const Duration(milliseconds: 400), () async {
      String r;
      try {
        // 예약 아이디: public addresses follow the ID rules (the server
        // checks again); a badge holder may use their own name.
        var why = '';
        try {
          why = await b.nameCheck(a);
        } catch (_) {}
        if (why.isNotEmpty) {
          final t = await b.trustList();
          final mine = t.badges.any(
            (x) => x.user == b.userId && (nameCore(x.name) == nameCore(a) || nameCore(x.user.replaceFirst('@', '').split(':').first) == nameCore(a)),
          );
          if (!mine) throw StateError('reserved');
        }
        r = await b.addressFree(widget.roomId, a) ? 'free' : 'taken';
      } catch (e) {
        r = e.toString().contains('reserved') ? 'reserved' : 'bad';
      }
      if (mounted && address.text.trim().toLowerCase() == a) setState(() => check = r);
    });
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      failed = null;
    });
    try {
      final now = mode == 'public' ? await b.setPublicLink(widget.roomId, address.text.trim()) : await b.newPrivateLink(widget.roomId);
      if (mounted) setState(() => link = now);
    } catch (_) {
      if (mounted) setState(() => failed = L.of(context).linkFailed);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> reset() async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.linkResetInfo),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('link-reset-ok'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.linkReset),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => busy = true);
    try {
      final now = await b.newPrivateLink(widget.roomId);
      if (mounted) setState(() => link = now);
    } catch (_) {
      if (mounted) setState(() => failed = l.linkFailed);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> setApproval(bool on) async {
    setState(() => link = RoomLink(kind: link.kind, code: link.code, approval: on, web: link.web));
    try {
      await b.setLinkApproval(widget.roomId, on);
    } catch (_) {
      if (mounted) setState(() => link = RoomLink(kind: link.kind, code: link.code, approval: !on, web: link.web));
    }
  }

  Future<void> setWeb(bool on) async {
    final l = L.of(context);
    if (on) {
      final ok = await showCupertinoDialog<bool>(
        context: context,
        builder: (c) => CupertinoAlertDialog(
          title: Text(l.webPageOn),
          content: Text(l.webPageOnBody),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            CupertinoDialogAction(key: const Key('web-on-ok'), onPressed: () => Navigator.pop(c, true), child: Text(l.webPageTurnOn)),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    final before = link;
    setState(() => link = RoomLink(kind: link.kind, code: link.code, approval: link.approval, web: on));
    try {
      await b.setWebPage(widget.roomId, on);
    } catch (_) {
      if (mounted) setState(() => link = before);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final text = roomLinkText(link, name: widget.name, channel: widget.isChannel);
    String? note = switch (check) {
      'checking' => l.linkChecking,
      'free' when pending => l.linkFree,
      'taken' => l.linkTaken,
      'bad' => l.linkBadAddress,
      'reserved' => l.linkReserved,
      _ => null,
    };
    final bad = check == 'taken' || check == 'bad' || check == 'reserved';
    Widget pick(String v, String label) => IosTile(
      key: Key('link-kind-$v'),
      title: Text(label),
      trailing: mode == v ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
      onTap: () => setState(() {
        mode = v;
        failed = null;
        if (v == 'public' && address.text.isNotEmpty) typed(address.text);
      }),
    );
    return SettingsScaffold(
      title: l.linkTitle,
      trailing: [if (pending) GlassPill(key: const Key('link-save'), text: l.done, onTap: canSave ? save : null)],
      children: !loaded
          ? [SizedBox(height: Tokens.space[5]), const Center(child: CupertinoActivityIndicator())]
          : [
              group(context, header: l.linkKind, footer: mode == 'public' ? l.linkPublicInfo : l.linkPrivateInfo, [
                pick('private', l.linkPrivate),
                pick('public', l.linkPublic),
              ]),
              if (mode == 'public')
                group(context, footer: failed ?? note, error: failed != null || bad, [
                  Padding(
                    padding: EdgeInsets.only(left: Tokens.space[3]),
                    child: Row(
                      children: [
                        Text('${RoomLinks.host}/c/', style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                        Expanded(
                          child: CupertinoTextField.borderless(
                            key: const Key('link-address'),
                            controller: address,
                            placeholder: l.linkAddress,
                            autocorrect: false,
                            maxLength: 32,
                            style: Tokens.body.style.copyWith(color: p.label),
                            padding: EdgeInsets.fromLTRB(0, Tokens.space[2], Tokens.space[3], Tokens.space[2]),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9_]'))],
                            onChanged: typed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!pending && text.isNotEmpty) LinkCard(key: Key('link-card-${link.code}'), link: text, showText: false),
                ]),
              if (mode == 'private' && !pending && text.isNotEmpty)
                group(context, [
                  LinkCard(key: Key('link-card-${link.code}'), link: text),
                  if (Features.shareLinks && mainUses.$1 > 0)
                    JoinedFaces(key: const Key('link-main-joined'), count: mainUses.$1, who: mainUses.$2, roomId: widget.roomId),
                ]),
              if (Features.shareLinks && !pending && link.kind != 'none')
                ExtraLinksSection(roomId: widget.roomId, name: widget.name, isChannel: widget.isChannel, approval: link.approval),
              group(context, footer: l.linkApprovalInfo, [
                IosTile(
                  leading: iconTile(Palette.tileOrange, CupertinoIcons.person_crop_circle_badge_checkmark),
                  title: Text(l.linkApproval),
                  trailing: IosSwitch(key: const Key('link-approval'), value: link.approval, activeTrackColor: p.accent, onChanged: setApproval),
                ),
                if (link.approval && Features.joinGate)
                  NavRow(
                    key: const Key('link-gate'),
                    color: p.tileGreen,
                    icon: CupertinoIcons.person_crop_circle_badge_checkmark,
                    title: l.gateTitle,
                    value: gateOn ? l.stateOn : l.stateOff,
                    onTap: () async {
                      await Navigator.of(context).push(IosPageRoute(builder: (_) => GatePage(roomId: widget.roomId)));
                      final cfg = await b.roomConfig(widget.roomId);
                      final n = (await b.joinRequests(widget.roomId)).length;
                      if (mounted) {
                        setState(() {
                          gateOn = GateSettings.from(cfg).on;
                          requests = n;
                        });
                      }
                    },
                  ),
                if (link.approval)
                  NavRow(
                    key: const Key('link-requests'),
                    color: Palette.tileBlue,
                    icon: CupertinoIcons.person_2_fill,
                    title: l.joinRequests,
                    value: '$requests',
                    onTap: () async {
                      await Navigator.of(context).push(IosPageRoute(builder: (_) => JoinRequestsPage(roomId: widget.roomId)));
                      final n = (await b.joinRequests(widget.roomId)).length;
                      if (mounted) setState(() => requests = n);
                    },
                  ),
              ]),
              if (text.isNotEmpty && !pending)
                group(context, [
                  NavRow(
                    key: const Key('link-poster'),
                    color: Palette.tilePurple,
                    icon: CupertinoIcons.qrcode,
                    title: l.posterMake,
                    onTap: () => Navigator.of(context).push(
                      IosPageRoute(
                        builder: (_) => PosterPage(roomId: widget.roomId, name: widget.name, link: text, isChannel: widget.isChannel),
                      ),
                    ),
                  ),
                ]),
              if (widget.isChannel)
                group(context, footer: link.public ? l.webPageInfo : l.webPageNeedsPublic, [
                  IosTile(
                    leading: iconTile(Palette.tileCyan, CupertinoIcons.globe),
                    title: Text(l.webPage),
                    trailing: IosSwitch(
                      key: const Key('link-web'),
                      value: link.web,
                      activeTrackColor: p.accent,
                      onChanged: link.public && !pending ? setWeb : null,
                    ),
                  ),
                  if (link.web)
                    IosTile(
                      key: const Key('link-web-address'),
                      title: Text(l.webPageAddress, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(RoomLinks.shown(RoomLinks.web(link.code)), style: Tokens.body.style.copyWith(color: p.accent)),
                      onTap: () => Clipboard.setData(ClipboardData(text: RoomLinks.web(link.code))),
                    ),
                ]),
              if (link.private && mode == 'private')
                group(context, [
                  IosTile(
                    key: const Key('link-reset'),
                    title: Text(l.linkReset, style: const TextStyle(color: Palette.tileRed)),
                    onTap: busy ? null : reset,
                  ),
                ]),
            ],
    );
  }
}

class JoinRequestsPage extends StatefulWidget {
  const JoinRequestsPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<JoinRequestsPage> createState() => _JoinRequestsPageState();
}

class _JoinRequestsPageState extends State<JoinRequestsPage> {
  List<JoinRequest>? list;
  List<GateQuestion> questions = const [];
  bool gateOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    final r = await b.joinRequests(widget.roomId);
    final cfg = await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    if (mounted) {
      setState(() {
        list = r;
        questions = GateQuestion.listFrom(cfg);
        gateOn = Features.joinGate && GateSettings.from(cfg).on;
      });
    }
  }

  /// "Question: answer" lines (quiz answers shown as the choice picked).
  String answersOf(JoinRequest r) => [
    for (var i = 0; i < r.answers.length; i++)
      if (r.answers[i].trim().isNotEmpty)
        () {
          final q = i < questions.length ? questions[i] : null;
          final a = q != null && q.quiz ? (q.choices.elementAtOrNull(int.tryParse(r.answers[i]) ?? -1) ?? r.answers[i]) : r.answers[i];
          return q == null ? a : '${q.q}: $a';
        }(),
  ].join('\n');

  Future<void> answer(JoinRequest r, bool accept) async {
    setState(() => list = [...?list?.where((x) => x.userId != r.userId)]);
    try {
      await AppScope.read(context).backend.answerJoinRequest(widget.roomId, r.userId, accept);
    } catch (_) {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final now = list;
    Widget small(Key key, String text, bool filled, VoidCallback onTap) => CupertinoButton(
      key: key,
      minimumSize: const Size(0, 32),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + 2),
      color: filled ? p.accent : p.searchFill,
      borderRadius: BorderRadius.circular(Tokens.capsule),
      onPressed: onTap,
      child: Text(
        text,
        style: Tokens.preview.style.copyWith(color: filled ? p.onAccent : p.label, fontWeight: FontWeight.w600),
      ),
    );
    return SettingsScaffold(
      title: l.joinRequests,
      children: [
        if (now == null)
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[5]),
            child: const Center(child: CupertinoActivityIndicator()),
          )
        else if (now.isEmpty)
          Padding(
            padding: EdgeInsets.all(Tokens.space[5]),
            child: Text(
              l.joinRequestsNone,
              key: const Key('requests-empty'),
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.secondaryLabel),
            ),
          )
        else
          group(context, footer: gateOn ? '${l.joinRequestsInfo} ${l.gateHeldNote}' : l.joinRequestsInfo, [
            for (final r in now)
              IosTile(
                key: Key('request-${r.userId}'),
                leadingSize: Tokens.memberAvatar,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                leading: Avatar(name: r.name, size: Tokens.memberAvatar, userId: r.userId),
                title: Text(r.name),
                subtitle: Text(
                  [displayId(r.userId), if (answersOf(r).isNotEmpty) answersOf(r)].join('\n'),
                  key: Key('request-answers-${r.userId}'),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    small(Key('request-no-${r.userId}'), l.joinDecline, false, () => answer(r, false)),
                    SizedBox(width: Tokens.space[1]),
                    small(Key('request-ok-${r.userId}'), l.joinAccept, true, () => answer(r, true)),
                  ],
                ),
              ),
          ]),
      ],
    );
  }
}

/// Opens what a link shows; returns true when the person came in.
Future<void> openJoinLink(BuildContext context, LinkTarget target) => openSheet<void>(context, (_) => JoinLinkPage(target: target));

class JoinLinkPage extends StatefulWidget {
  const JoinLinkPage({super.key, required this.target});
  final LinkTarget target;

  @override
  State<JoinLinkPage> createState() => _JoinLinkPageState();
}

class _JoinLinkPageState extends State<JoinLinkPage> {
  LinkPeek? peek;

  /// The room's join questions (its helper is on); null = none.
  List<GateQuestion>? questions;
  bool loading = true;
  bool missing = false;
  bool asked = false;
  bool busy = false;

  /// Our server turned the link down: "ended", "full" or "revoked".
  String? refused;

  bool get private => widget.target.kind == 'private';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    if (Features.joinGate) {
      final qs = await b.gateQuestions(widget.target.kind, widget.target.code).catchError((_) => null);
      if (mounted) setState(() => questions = qs);
    }
    if (private) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final p = await b.peekAddress(widget.target.code);
      if (mounted) setState(() => peek = p);
    } catch (_) {
      if (mounted) setState(() => missing = true);
    }
    if (mounted) setState(() => loading = false);
  }

  String get name {
    final n = peek?.name ?? widget.target.name;
    return n.isEmpty ? L.of(context).joinUnnamed : n;
  }

  bool get channel => peek?.channel ?? widget.target.channel;

  Future<void> go() async {
    final s = AppScope.read(context);
    final nav = Navigator.of(context);
    if (peek?.joined == true) {
      nav.pop();
      await openChat(context, peek!.roomId, name);
      return;
    }
    if (questions != null) {
      final title = name;
      final root = Navigator.of(context, rootNavigator: true);
      nav.pop();
      await root.push(
        IosPageRoute(
          builder: (_) => JoinQuizPage(kind: widget.target.kind, code: widget.target.code, name: title, channel: channel, questions: questions!),
        ),
      );
      return;
    }
    setState(() => busy = true);
    try {
      final (room, onlyAsked) = await s.backend.joinLink(widget.target.kind, widget.target.code);
      if (!mounted) return;
      if (onlyAsked) {
        setState(() {
          asked = true;
          busy = false;
        });
        return;
      }
      await s.refresh();
      if (!mounted) return;
      final title = name;
      nav.pop();
      if (context.mounted) await openChat(context, room, title);
    } catch (e) {
      if (mounted) {
        setState(() {
          refused = linkRefusal(e);
          missing = true;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final kind = switch ((private, channel)) {
      (false, true) => l.joinPublicChannel,
      (false, false) => l.joinPublicGroup,
      (true, true) => l.joinPrivateChannel,
      (true, false) => l.joinPrivateGroup,
    };
    final count = peek == null ? null : (channel ? l.subscribersCount(peek!.members) : l.membersCount(peek!.members));
    final approval = peek?.approval ?? false;
    final button = peek?.joined == true
        ? l.open
        : questions != null
        ? l.gateAnswerAndAsk
        : approval
        ? l.joinAsk
        : channel
        ? l.joinSubscribe
        : l.joinGroup;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: loading
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                      children: [
                        SizedBox(height: Tokens.space[4]),
                        Center(
                          child: Avatar(
                            key: const Key('join-avatar'),
                            name: name,
                            size: Tokens.infoAvatar,
                            squircle: true,
                            channel: channel,
                            photo: peek?.photo,
                          ),
                        ),
                        SizedBox(height: Tokens.space[3]),
                        Text(
                          name,
                          key: const Key('join-name'),
                          textAlign: TextAlign.center,
                          style: Tokens.cardTitle.style.copyWith(color: p.label),
                        ),
                        SizedBox(height: Tokens.nameToSub),
                        Text(
                          missing
                              ? switch (refused) {
                                  'ended' => l.joinLinkEnded,
                                  'full' => l.joinLinkFull,
                                  _ => l.joinNotFound,
                                }
                              : [kind, ?count].join(' · '),
                          key: const Key('join-kind'),
                          textAlign: TextAlign.center,
                          style: Tokens.preview.style.copyWith(color: missing ? Palette.tileRed : p.secondaryLabel),
                        ),
                        if ((peek?.about ?? '').isNotEmpty) ...[
                          SizedBox(height: Tokens.space[3]),
                          Text(
                            peek!.about,
                            key: const Key('join-about'),
                            textAlign: TextAlign.center,
                            style: Tokens.body.style.copyWith(color: p.label),
                          ),
                        ],
                        if (private && !missing) ...[
                          SizedBox(height: Tokens.space[3]),
                          Text(
                            l.joinPrivateNote,
                            textAlign: TextAlign.center,
                            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                          ),
                        ],
                        if (asked) ...[
                          SizedBox(height: Tokens.space[3]),
                          Text(
                            l.joinAsked,
                            key: const Key('join-asked'),
                            textAlign: TextAlign.center,
                            style: Tokens.preview.style.copyWith(color: p.accent),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!missing && !asked)
                    Padding(
                      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                      child: CupertinoButton.filled(
                        key: const Key('join-go'),
                        borderRadius: BorderRadius.circular(Tokens.capsule),
                        onPressed: busy ? null : go,
                        child: SizedBox(
                          width: double.infinity,
                          child: busy
                              ? CupertinoActivityIndicator(color: p.onAccent)
                              : Text(
                                  button,
                                  textAlign: TextAlign.center,
                                  style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// "링크로 들어가기": paste an invite link.
class JoinByLinkPage extends StatefulWidget {
  const JoinByLinkPage({super.key});

  @override
  State<JoinByLinkPage> createState() => _JoinByLinkPageState();
}

class _JoinByLinkPageState extends State<JoinByLinkPage> {
  final field = TextEditingController();
  bool bad = false;

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> next() async {
    final t = RoomLinks.parse(field.text);
    if (t == null) {
      setState(() => bad = true);
      return;
    }
    await openJoinLink(context, t);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.joinByLink,
      trailing: [GlassPill(key: const Key('join-link-next'), text: l.next, onTap: field.text.trim().isEmpty ? null : next)],
      children: [
        group(context, footer: bad ? l.joinByLinkBad : null, error: bad, [
          CupertinoTextField.borderless(
            key: const Key('join-link-field'),
            controller: field,
            placeholder: l.joinByLinkHint,
            autofocus: true,
            autocorrect: false,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + 2),
            onChanged: (_) => setState(() => bad = false),
            onSubmitted: (_) => next(),
          ),
        ]),
      ],
    );
  }
}
