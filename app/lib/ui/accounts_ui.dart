// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Several accounts, Telegram-style: the list under my profile in Settings,
// and a quick switch by holding the Settings tab (Eric 2026-11-27).
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../core/accounts.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

/// The name another account goes by (its own profile name, else its ID).
class AccountName extends StatelessWidget {
  const AccountName(this.accounts, this.entry, {super.key, this.style});
  final Accounts accounts;
  final AccountEntry entry;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final b = entry.slot == accounts.active ? accounts.state.backend : accounts.side[entry.slot];
    final id = displayId(entry.userId);
    return FutureBuilder<String>(
      future: b?.myName().catchError((_) => id) ?? Future.value(id),
      builder: (_, snap) => Text((snap.data ?? '').isEmpty ? id : snap.data!, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
    );
  }
}

/// "계정 추가": within the limit, an empty sign-in page comes up; past it,
/// a short note on Plus and buying (payments open after launch).
Future<void> addAccount(BuildContext context) async {
  final a = AppScope.of(context).accounts;
  if (a == null) return;
  if (a.canAdd) {
    await a.startAdd();
    return;
  }
  final l = L.of(context);
  await showCupertinoModalPopup<void>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.accountsLimitTitle),
      message: Text(l.accountsLimitInfo),
      cancelButton: CupertinoActionSheetAction(key: const Key('accounts-limit-ok'), onPressed: () => Navigator.pop(c), child: Text(l.okButton)),
    ),
  );
}

/// Settings: other accounts (tap to switch, unread count on the right)
/// and "계정 추가".
class AccountsSection extends StatelessWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final a = AppScope.of(context).accounts;
    if (a == null) return const SizedBox.shrink();
    final l = L.of(context);
    final p = paletteOf(context);
    return ListenableBuilder(
      listenable: a,
      builder: (context, _) => IosSection(
        children: [
          for (final e in a.others)
            // Tip 178: hold to peek at that account's chats.
            GestureDetector(
              key: Key('account-hold-${e.slot}'),
              onLongPress: () => showAccountPreview(context, a, e),
              child: IosTile(
                key: Key('account-${e.slot}'),
                leading: Avatar(name: displayId(e.userId).replaceFirst('@', ''), userId: e.userId, size: 30, round: true),
                title: AccountName(a, e),
                additionalInfo: FutureBuilder<int>(
                  future: a.unreadOf(e.slot),
                  builder: (_, snap) => (snap.data ?? 0) == 0
                      ? const SizedBox.shrink()
                      : Container(
                          key: Key('account-unread-${e.slot}'),
                          constraints: const BoxConstraints(minWidth: 22),
                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] - 2),
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                          child: Text('${snap.data}', style: Tokens.caption.style.copyWith(color: p.onAccent)),
                        ),
                ),
                onTap: () => a.switchTo(e.slot),
              ),
            ),
          IosTile(
            key: const Key('account-add'),
            leading: SizedBox(
              width: 30,
              height: 30,
              child: Icon(CupertinoIcons.plus, color: p.accent, size: Tokens.tileGlyph + 2),
            ),
            title: Text(l.accountsAdd, style: TextStyle(color: p.accent)),
            onTap: () => addAccount(context),
          ),
        ],
      ),
    );
  }
}

/// Holding the Settings tab: every account (mine ticked) and "계정 추가".
Future<void> showAccountsMenu(BuildContext context) async {
  final a = AppScope.of(context).accounts;
  if (a == null) return;
  final l = L.of(context);
  final pick = await showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      actions: [
        for (final e in a.list)
          CupertinoActionSheetAction(
            key: Key('switch-${e.slot}'),
            isDefaultAction: e.slot == a.active,
            onPressed: () => Navigator.pop(c, e.slot),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: AccountName(a, e)),
                if (e.slot == a.active) ...[SizedBox(width: Tokens.space[1]), const Icon(CupertinoIcons.checkmark_alt, size: 18)],
              ],
            ),
          ),
        CupertinoActionSheetAction(key: const Key('switch-add'), onPressed: () => Navigator.pop(c, -1), child: Text(l.accountsAdd)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  if (pick == -1) return addAccount(context);
  await a.switchTo(pick);
}

/// App lock: which accounts the account password erases (never all).
class AccountErasePage extends StatefulWidget {
  const AccountErasePage({super.key});
  @override
  State<AccountErasePage> createState() => _AccountErasePageState();
}

class _AccountErasePageState extends State<AccountErasePage> {
  @override
  Widget build(BuildContext context) {
    final a = AppScope.of(context).accounts!;
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.accountEraseList), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              footer: sectionFooter(context, l.accountEraseListInfo),
              children: [
                for (final e in a.list)
                  IosTile(
                    key: Key('erase-${e.slot}'),
                    leading: Avatar(name: displayId(e.userId).replaceFirst('@', ''), userId: e.userId, size: 30, round: true),
                    title: AccountName(a, e),
                    trailing: a.toErase.contains(e.slot) ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
                    onTap: () async {
                      final next = {...a.toErase};
                      next.contains(e.slot) ? next.remove(e.slot) : next.add(e.slot);
                      // One account must stay.
                      if (next.length >= a.list.length) return;
                      await a.setToErase(next);
                      setState(() {});
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 다른 계정 미리보기 (Telegram tip 178): holding another account's row
/// lifts a card with that account's chat list over a blurred screen, with
/// "이 계정으로 바꾸기" under it; a tap outside closes it. Chats that are
/// hidden, archived or still requests on that account never show, and a
/// hide / delete session (three passwords) is already applied to its list.
Future<void> showAccountPreview(BuildContext context, Accounts a, AccountEntry e) async {
  final b = a.side[e.slot];
  if (b == null || !b.loggedIn) return;
  final pick = await paneNav(context).push<bool>(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (c, anim, _) => _AccountPreview(anim: anim, accounts: a, entry: e, backend: b),
    ),
  );
  if (pick == true) await a.switchTo(e.slot);
}

class _AccountPreview extends StatefulWidget {
  const _AccountPreview({required this.anim, required this.accounts, required this.entry, required this.backend});
  final Animation<double> anim;
  final Accounts accounts;
  final AccountEntry entry;
  final Backend backend;

  /// Rows shown on the card (Telegram shows about a screenful).
  static const most = 8;

  @override
  State<_AccountPreview> createState() => _AccountPreviewState();
}

class _AccountPreviewState extends State<_AccountPreview> {
  List<ChatPreview>? chats;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final all = await widget.backend.chats();
      final prefs = await widget.backend.settings();
      final list = [
        for (final c in all)
          if (!c.archived && prefs['list_hidden:${c.roomId}'] != '1' && (prefs['dm_request:${c.roomId}'] ?? '').isEmpty) c,
      ]..sort((x, y) => x.pinned != y.pinned ? (x.pinned ? -1 : 1) : (y.last?.time ?? DateTime(2000)).compareTo(x.last?.time ?? DateTime(2000)));
      if (mounted) setState(() => chats = list.take(_AccountPreview.most).toList());
    } catch (_) {
      if (mounted) setState(() => chats = const []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final anim = widget.anim;
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    final size = MediaQuery.sizeOf(context);
    final width = (size.width - Tokens.space[3] * 2).clamp(0.0, 380.0);
    final list = chats;
    Widget row(ChatPreview c) {
      final last = c.last;
      final text = last == null ? '' : previewText(context, kind: last.kind, body: last.body, caption: last.caption, live: last.live != null);
      return SizedBox(
        key: Key('preview-chat-${c.roomId}'),
        height: 64,
        child: Row(
          children: [
            SizedBox(width: Tokens.space[2] + Tokens.space[0]),
            Avatar(name: c.name, size: 46, squircle: !c.isDirect, channel: c.isChannel),
            SizedBox(width: Tokens.space[2] + Tokens.space[0]),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.listName.style.copyWith(color: p.label),
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Text(
                    text.replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                ],
              ),
            ),
            if (c.unread > 0) ...[
              SizedBox(width: Tokens.space[1]),
              Container(
                constraints: const BoxConstraints(minWidth: 20),
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[0] + 2, vertical: 1),
                decoration: BoxDecoration(
                  color: c.muted ? p.secondaryLabel.withValues(alpha: 0.45) : p.accent,
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                ),
                child: Text(
                  '${c.unread}',
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.onAccent),
                ),
              ),
            ],
            SizedBox(width: Tokens.space[2] + Tokens.space[0]),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('account-preview-dismiss'),
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * anim.value, sigmaY: 14 * anim.value),
                child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.18 * anim.value)),
              ),
            ),
          ),
          Center(
            child: Opacity(
              opacity: anim.value.clamp(0, 1),
              child: Transform.scale(scale: 0.92 + 0.08 * curved.value, child: child),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('account-preview'),
            width: width,
            constraints: BoxConstraints(maxHeight: size.height * 0.62),
            decoration: BoxDecoration(color: p.list, borderRadius: BorderRadius.circular(Tokens.radius[3])),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The account it belongs to.
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2] + Tokens.space[0], Tokens.space[3], Tokens.space[2]),
                  child: Row(
                    children: [
                      Avatar(name: displayId(widget.entry.userId).replaceFirst('@', ''), userId: widget.entry.userId, size: 30, round: true),
                      SizedBox(width: Tokens.space[2]),
                      Expanded(
                        child: AccountName(
                          widget.accounts,
                          widget.entry,
                          style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 0.5, color: p.separator),
                if (list == null)
                  Padding(padding: EdgeInsets.all(Tokens.space[4]), child: const CupertinoActivityIndicator())
                else if (list.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(Tokens.space[4]),
                    child: Text(l.accountPreviewEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  )
                else
                  Flexible(
                    child: ListView(padding: EdgeInsets.zero, shrinkWrap: true, children: [for (final c in list) row(c)]),
                  ),
              ],
            ),
          ),
          SizedBox(height: Tokens.space[2]),
          // iOS context menu action under the lifted card.
          GestureDetector(
            key: const Key('account-preview-switch'),
            onTap: () => Navigator.pop(context, true),
            child: Container(
              width: 250,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2] + 4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.accountPreviewSwitch, style: Tokens.body.style.copyWith(color: p.label)),
                  ),
                  Icon(CupertinoIcons.arrow_right_arrow_left, size: Tokens.listIcon, color: p.label),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
