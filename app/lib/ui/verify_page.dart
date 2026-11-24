// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 1:1 info > 암호화 (v1 merged the top-right menu's "보안 코드 확인" into
// this page): hero card, the member and whether their phone is checked,
// "확인 시작" (7-emoji check) and the advanced device-key list.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'message_sheets.dart';
import 'settings_kit.dart';
import 'wide.dart';

class EncryptionPage extends StatefulWidget {
  const EncryptionPage({super.key, required this.userId, required this.name});
  final String userId;
  final String name;
  @override
  State<EncryptionPage> createState() => _EncryptionPageState();
}

class _EncryptionPageState extends State<EncryptionPage> {
  bool? verified;
  bool showKeys = false;
  List<PeerDevice>? devices;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final b = AppScope.read(context).backend;
    final v = await b.isUserVerified(widget.userId).catchError((_) => false);
    final d = showKeys ? await b.peerDevices(widget.userId).catchError((_) => const <PeerDevice>[]) : devices;
    if (mounted) {
      setState(() {
        verified = v;
        devices = d;
      });
    }
  }

  Future<void> start() async {
    await openSheet<void>(context, (_) => VerifyPage(userId: widget.userId, name: widget.name));
    await load();
  }

  /// "AbCd EfGh …": easier to read aloud.
  static String groups(String key) => [for (var i = 0; i < key.length; i += 4) key.substring(i, i + 4 > key.length ? key.length : i + 4)].join(' ');

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: l.encryption,
      children: [
        HeaderCard(color: p.tileGreen, icon: CupertinoIcons.lock_fill, title: l.encHeroTitle, body: l.encHeroBody),
        group(context, header: l.encMembers, [
          CupertinoListTile(
            key: const Key('enc-member'),
            leading: Avatar(name: widget.name, size: 30),
            title: Text(widget.name),
            additionalInfo: verified == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (verified!) Icon(CupertinoIcons.checkmark_seal_fill, size: Tokens.listIconSmall, color: p.accent),
                      SizedBox(width: Tokens.space[0]),
                      Text(verified! ? l.encVerified : l.encNotVerified, style: TextStyle(color: verified! ? p.accent : p.secondaryLabel)),
                    ],
                  ),
          ),
        ]),
        if (verified == false)
          Padding(
            // iOS grouped spacing: a section's gap above the button.
            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[4], Tokens.space[3], 0),
            child: Column(
              children: [
                AccentButton(key: const Key('enc-start'), text: l.encStart, onTap: start),
                SizedBox(height: Tokens.cardToFooter),
                sectionFooter(context, l.encStartInfo),
              ],
            ),
          ),
        group(context, footer: showKeys ? l.encKeysInfo : null, [
          CupertinoListTile(
            title: Text(l.encShowKeys),
            trailing: IosSwitch(
              key: const Key('enc-keys'),
              value: showKeys,
              onChanged: (v) {
                setState(() => showKeys = v);
                if (v) unawaited(load());
              },
            ),
          ),
          if (showKeys && devices != null && devices!.isEmpty)
            CupertinoListTile(
              title: Text(l.encNoDevices, style: TextStyle(color: p.secondaryLabel)),
            ),
          if (showKeys)
            for (final d in devices ?? const <PeerDevice>[])
              CupertinoListTile(
                key: Key('enc-device-${d.id}'),
                title: Text(d.name.isEmpty ? d.id : '${d.name} · ${d.id}'),
                subtitle: Text(
                  groups(d.key),
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel, fontFamily: 'Courier', fontFamilyFallback: const ['monospace']),
                ),
                trailing: d.verified ? Icon(CupertinoIcons.checkmark_seal_fill, size: Tokens.listIconSmall, color: p.accent) : null,
              ),
        ]),
      ],
    );
  }
}

/// The 7-emoji check itself. [flowId] is given when the other person asked
/// (from the request card in the chat); otherwise this page asks.
class VerifyPage extends StatefulWidget {
  const VerifyPage({super.key, required this.userId, required this.name, this.flowId});
  final String userId;
  final String name;
  final String? flowId;
  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  String? flow;
  String state = 'starting';
  List<String>? emoji;
  Timer? tick;
  bool failed = false;

  Backend get b => AppScope.read(context).backend;

  @override
  void initState() {
    super.initState();
    flow = widget.flowId;
    WidgetsBinding.instance.addPostFrameCallback((_) => begin());
  }

  Future<void> begin() async {
    if (flow == null) {
      try {
        flow = await b.requestVerification(widget.userId);
      } catch (_) {
        if (mounted) setState(() => failed = true);
        return;
      }
    }
    await poll();
    tick = Timer.periodic(const Duration(seconds: 1), (_) => poll());
  }

  Future<void> poll() async {
    final f = flow;
    if (f == null || !mounted) return;
    final s = await b.verifyState(widget.userId, f).catchError((_) => 'gone');
    final e = s == 'emoji' && emoji == null ? await b.sasEmoji(widget.userId, f).catchError((_) => null) : emoji;
    if (!mounted) return;
    if (const ['done', 'cancelled', 'gone'].contains(s)) tick?.cancel();
    setState(() {
      state = s;
      emoji = e;
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    final f = flow;
    // Leaving midway stops the check on both phones.
    if (f != null && !const ['done', 'cancelled', 'gone'].contains(state)) {
      unawaited(b.cancelVerification(widget.userId, f).catchError((_) {}));
    }
    super.dispose();
  }

  Future<void> act(Future<void> Function() f) async {
    try {
      await f();
    } catch (_) {}
    await poll();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final f = flow;
    Widget body;
    if (failed) {
      body = _Message(icon: CupertinoIcons.exclamationmark_circle, color: Palette.tileRed, text: l.verifyFailed);
    } else {
      body = switch (state) {
        'incoming' => _Message(icon: CupertinoIcons.lock_shield, color: p.accent, text: l.verifyIncoming(widget.name)),
        'emoji' when emoji != null => Column(
          key: const Key('verify-emoji'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.verifyCompare,
              textAlign: TextAlign.center,
              style: Tokens.cardTitle.style.copyWith(color: p.label),
            ),
            SizedBox(height: Tokens.space[4]),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Tokens.space[2],
              runSpacing: Tokens.space[3],
              children: [
                for (final e in emoji!)
                  SizedBox(
                    width: 72,
                    child: Column(
                      children: [
                        Text(e.split(' ').first, style: TextStyle(fontSize: 40, height: 1.1, fontFamilyFallback: Tokens.emojiFallback)),
                        SizedBox(height: Tokens.space[0]),
                        Text(
                          e.split(' ').skip(1).join(' '),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        'confirmed' => _Message(icon: CupertinoIcons.hourglass, color: p.secondaryLabel, text: l.verifyWaitOther),
        'done' => _Message(key: const Key('verify-done'), icon: CupertinoIcons.checkmark_seal_fill, color: p.accent, text: l.verifyDone),
        'cancelled' || 'gone' => _Message(icon: CupertinoIcons.xmark_circle, color: Palette.tileRed, text: l.verifyCancelled),
        _ => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 14),
            SizedBox(height: Tokens.space[3]),
            Text(
              l.verifyWaiting,
              textAlign: TextAlign.center,
              style: Tokens.body.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
      };
    }
    final ended = failed || const ['done', 'cancelled', 'gone'].contains(state);
    final buttons = <Widget>[
      if (!failed && state == 'incoming' && f != null) ...[
        AccentButton(key: const Key('verify-accept'), text: l.verifyAccept, onTap: () => act(() => b.acceptVerification(widget.userId, f))),
        SizedBox(height: Tokens.space[1]),
        _TextButton(
          key: const Key('verify-decline'),
          text: l.verifyDecline,
          color: Palette.tileRed,
          onTap: () => act(() => b.cancelVerification(widget.userId, f)),
        ),
      ],
      if (!failed && state == 'emoji' && emoji != null && f != null) ...[
        AccentButton(key: const Key('verify-match'), text: l.verifyMatch, onTap: () => act(() => b.confirmSas(widget.userId, f))),
        SizedBox(height: Tokens.space[1]),
        _TextButton(
          key: const Key('verify-nomatch'),
          text: l.verifyNoMatch,
          color: Palette.tileRed,
          onTap: () => act(() => b.cancelVerification(widget.userId, f)),
        ),
      ],
      if (ended) AccentButton(key: const Key('verify-close'), text: state == 'done' ? l.done : l.close, onTap: () => Navigator.pop(context)),
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: Tokens.sheetHeader,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    l.verifyTitle,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                  ),
                  if (!ended)
                    Positioned(
                      left: Tokens.space[2],
                      child: CupertinoButton(
                        key: const Key('verify-x'),
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: Icon(CupertinoIcons.xmark, color: p.label, size: Tokens.closeIcon),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                  child: body,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[3]),
              child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 56, color: color),
      SizedBox(height: Tokens.space[3]),
      Text(
        text,
        textAlign: TextAlign.center,
        style: Tokens.body.style.copyWith(color: paletteOf(context).label),
      ),
    ],
  );
}

class _TextButton extends StatelessWidget {
  const _TextButton({super.key, required this.text, required this.color, required this.onTap});
  final String text;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      height: Tokens.settingsRow,
      child: Center(
        child: Text(text, style: Tokens.body.style.copyWith(color: color)),
      ),
    ),
  );
}
