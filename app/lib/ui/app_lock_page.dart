// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Settings > App Lock: normal password, hide/delete passwords and the
// people & chats they act on.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'accounts_ui.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'ios_route.dart';

/// Shared look for one or two password fields.
Widget passwordField(BuildContext context, TextEditingController c, String hint, {Key? key, bool autofocus = false}) {
  final p = paletteOf(context);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
    child: CupertinoTextField(
      key: key,
      controller: c,
      obscureText: true,
      autofocus: autofocus,
      placeholder: hint,
      decoration: null,
      style: Tokens.body.style.copyWith(color: p.label),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
    ),
  );
}

class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key});
  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  bool? isSet;

  /// The normal password, once typed on this visit (kept only in memory).
  String? normal;
  List<bool> extras = const [false, false, false];
  List<List<String>> lists = const [[], []];
  bool hideSession = false;
  bool hideOn = false;
  int wipeN = 10;
  final gate = TextEditingController();
  String? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isSet == null) refresh();
  }

  Future<void> refresh() async {
    final b = AppScope.of(context).backend;
    final s = await b.lockIsSet();
    final l = await b.quietLists();
    final on = await b.hideActive();
    final w = await b.wipeAfter();
    final e = normal == null ? extras : await b.extrasSet(normal!);
    if (mounted) {
      setState(() {
        isSet = s;
        lists = l;
        extras = e;
        hideSession = b.sessionRole == 'hide';
        hideOn = on;
        wipeN = w;
      });
    }
  }

  Future<void> enter() async {
    final b = AppScope.of(context).backend;
    try {
      final e = await b.extrasSet(gate.text);
      setState(() {
        normal = gate.text;
        extras = e;
        error = null;
      });
      gate.clear();
    } catch (_) {
      setState(() => error = L.of(context).lockWrong);
    }
  }

  Future<void> push(Widget page) async {
    await Navigator.of(context).push(IosPageRoute(builder: (_) => page));
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final b = AppScope.of(context).backend;
    final accounts = AppScope.of(context).accounts;
    final List<Widget> body;
    if (isSet == null) {
      body = const [];
    } else if (isSet == false) {
      body = [
        IosSection(
          children: [
            IosTile(
              key: const Key('lock-set-first'),
              leading: iconTile(Palette.tileIndigo, CupertinoIcons.lock),
              title: Text(l.setPassword),
              trailing: const IosChevron(),
              onTap: () => push(
                PasswordPage(
                  title: l.setPassword,
                  onSave: (pw) async {
                    await b.setNormalPassword(pw);
                    normal = pw;
                  },
                ),
              ),
            ),
          ],
        ),
      ];
    } else if (normal == null) {
      body = [
        IosSection(
          footer: sectionFooter(context, error ?? l.enterToManage, error: error != null),
          children: [passwordField(context, gate, l.currentPassword, key: const Key('lock-gate'), autofocus: true)],
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: CupertinoButton.filled(key: const Key('lock-gate-ok'), onPressed: enter, child: Text(l.open)),
        ),
      ];
    } else {
      final n = normal!;
      Widget extraRow(String role, int i, Color c, IconData icon, String title, String info) => IosTile(
        key: Key('lock-$role'),
        leading: iconTile(c, icon),
        title: Text(title),
        additionalInfo: Text(extras.length > i && extras[i] ? l.appLockOn : l.notSet),
        trailing: const IosChevron(),
        onTap: () => push(
          PasswordPage(
            title: title,
            info: info,
            onSave: (pw) => b.setExtraPassword(n, role, pw),
            onRemove: extras.length > i && extras[i] ? () => b.setExtraPassword(n, role, null) : null,
          ),
        ),
      );
      Widget listRow(int i, Color c, IconData icon, String title) => IosTile(
        key: Key('lock-list-$i'),
        leading: iconTile(c, icon),
        title: Text(title),
        additionalInfo: Text(lists[i].isEmpty ? l.notSet : l.chooseCount(lists[i].length)),
        trailing: const IosChevron(),
        onTap: () => push(QuietPickPage(title: title, chosen: lists[i], onSave: (v) => b.setQuietLists(i == 0 ? v : lists[0], i == 1 ? v : lists[1]))),
      );
      body = [
        IosSection(
          children: [
            IosTile(
              leading: iconTile(Palette.tileIndigo, CupertinoIcons.lock),
              title: Text(l.changePassword),
              trailing: const IosChevron(),
              onTap: () => push(
                PasswordPage(
                  title: l.changePassword,
                  onSave: (pw) async {
                    await b.setNormalPassword(pw, old: n);
                    normal = pw;
                  },
                ),
              ),
            ),
          ],
        ),
        IosSection(
          footer: sectionFooter(context, l.hidePasswordInfo),
          children: [
            extraRow('hide', 0, Palette.tileBlue, CupertinoIcons.eye_slash, l.hidePassword, l.hidePasswordInfo),
            listRow(0, Palette.tileTeal, CupertinoIcons.person_crop_circle_badge_xmark, l.hideList),
          ],
        ),
        IosSection(
          footer: sectionFooter(context, l.deletePasswordInfo),
          children: [
            extraRow('delete', 1, Palette.tileRed, CupertinoIcons.trash, l.deletePassword, l.deletePasswordInfo),
            listRow(1, Palette.tileOrange, CupertinoIcons.person_crop_circle_badge_minus, l.deleteList),
          ],
        ),
        // Fourth password: only with two or more accounts on this phone
        // (or when it is already set).
        if ((accounts?.several ?? false) || (extras.length > 2 && extras[2]))
          IosSection(
            footer: sectionFooter(context, l.accountPasswordInfo),
            children: [
              extraRow('account', 2, Palette.tileIndigo, CupertinoIcons.person_2, l.accountPassword, l.accountPasswordInfo),
              IosTile(
                key: const Key('lock-account-list'),
                leading: iconTile(Palette.tileGrey, CupertinoIcons.person_crop_circle_badge_minus),
                title: Text(l.accountEraseList),
                additionalInfo: Text(accounts == null || accounts.toErase.isEmpty ? l.notSet : l.chooseCount(accounts.toErase.length)),
                trailing: const IosChevron(),
                onTap: accounts == null ? null : () => push(const AccountErasePage()),
              ),
            ],
          ),
        IosSection(
          footer: sectionFooter(context, l.wipeAfterInfo),
          children: [
            IosTile(
              leading: iconTile(Palette.tilePink, CupertinoIcons.exclamationmark_shield),
              title: Text(l.wipeAfter),
              trailing: IosSegmented<int>(
                key: const Key('wipe-after'),
                // Short choices so '틀리면 모두 지우기' shows in full (검수 2026-11-28).
                itemWidth: 64,
                groupValue: wipeN,
                children: {5: Text(l.wipeTimes(5)), 10: Text(l.wipeTimes(10))},
                onValueChanged: (v) async {
                  if (v == null) return;
                  setState(() => wipeN = v);
                  await b.setWipeAfter(n, v);
                },
              ),
            ),
          ],
        ),
      ];
    }
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.appLock), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            ...body,
            if (hideSession && hideOn)
              IosSection(
                children: [
                  IosTile(
                    key: const Key('release-hidden'),
                    leading: iconTile(Palette.tileBlue, CupertinoIcons.eye),
                    title: Text(l.releaseHidden),
                    onTap: () async {
                      final st = AppScope.of(context);
                      await b.releaseHidden();
                      // Hiding was on for every account on this phone.
                      for (final o in st.accounts?.side.values ?? const <Backend>[]) {
                        try {
                          await o.releaseHidden();
                        } catch (_) {}
                      }
                      await st.refresh();
                      await refresh();
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

/// New password twice (rule: 8+ characters, letters and digits).
class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key, required this.title, required this.onSave, this.info, this.onRemove});
  final String title;
  final String? info;
  final Future<void> Function(String) onSave;
  final Future<void> Function()? onRemove;
  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  final a = TextEditingController();
  final b = TextEditingController();
  String? error;

  Future<void> save() async {
    final l = L.of(context);
    if (!passwordRuleOk(a.text)) return setState(() => error = l.passwordRule);
    if (a.text != b.text) return setState(() => error = l.passwordMismatch);
    try {
      await widget.onSave(a.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => error = l.passwordUsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(widget.title),
        backgroundColor: p.background,
        border: null,
        trailing: CupertinoButton(key: const Key('password-save'), padding: EdgeInsets.zero, onPressed: save, child: Text(l.save)),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              footer: sectionFooter(context, error ?? widget.info ?? l.passwordRule, error: error != null),
              children: [
                passwordField(context, a, l.newPassword, key: const Key('password-new'), autofocus: true),
                passwordField(context, b, l.confirmPassword, key: const Key('password-again')),
              ],
            ),
            if (widget.onRemove != null)
              IosSection(
                children: [
                  IosTile(
                    title: Text(l.removePassword, style: const TextStyle(color: Palette.tileRed)),
                    onTap: () async {
                      await widget.onRemove!();
                      if (context.mounted) Navigator.pop(context);
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

/// Same rule as the engine (lock.rs password_ok), checked early for a
/// friendly message.
bool passwordRuleOk(String s) => s.length >= 8 && RegExp(r'\p{L}', unicode: true).hasMatch(s) && RegExp(r'\d').hasMatch(s);

/// Tick people (1:1 partners) and group/channel chats.
class QuietPickPage extends StatefulWidget {
  const QuietPickPage({super.key, required this.title, required this.chosen, required this.onSave});
  final String title;
  final List<String> chosen;
  final Future<void> Function(List<String>) onSave;
  @override
  State<QuietPickPage> createState() => _QuietPickPageState();
}

class _QuietPickPageState extends State<QuietPickPage> {
  late final picked = {...widget.chosen};
  List<Person> people = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppScope.of(context).backend.contacts().then((c) {
      if (mounted) setState(() => people = c);
    });
  }

  Widget row(BuildContext context, String id, String name, String sub) {
    final p = paletteOf(context);
    final on = picked.contains(id);
    return IosTile(
      leading: Avatar(name: name, size: 30),
      title: Text(name),
      subtitle: Text(sub, style: Tokens.caption.style),
      trailing: Icon(on ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle, color: on ? p.accent : p.secondaryLabel),
      onTap: () => setState(() => on ? picked.remove(id) : picked.add(id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final groups = AppScope.of(context).chats.where((c) => !c.isDirect).toList();
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(widget.title),
        backgroundColor: p.background,
        border: null,
        trailing: CupertinoButton(
          key: const Key('quiet-save'),
          padding: EdgeInsets.zero,
          onPressed: () async {
            await widget.onSave(picked.toList());
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(l.save),
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            if (people.isNotEmpty)
              IosSection(
                header: sectionHeader(context, l.contactsSection),
                children: [for (final x in people) row(context, x.userId, x.name, displayId(x.userId))],
              ),
            if (groups.isNotEmpty)
              IosSection(
                header: sectionHeader(context, '${l.group} · ${l.channel}'),
                children: [for (final g in groups) row(context, g.roomId, g.name, l.group)],
              ),
          ],
        ),
      ),
    );
  }
}
