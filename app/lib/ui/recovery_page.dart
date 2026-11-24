// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// New device: type the 대화 복구 키 on a full screen (no pop-up text boxes).
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';

class RecoveryPage extends StatefulWidget {
  const RecoveryPage({super.key});
  @override
  State<RecoveryPage> createState() => _RecoveryPageState();
}

class _RecoveryPageState extends State<RecoveryPage> {
  final key = TextEditingController();
  bool busy = false;
  String? message;
  bool ok = false;

  Future<void> submit() async {
    final l = L.of(context);
    final s = AppScope.of(context);
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await s.backend.recover(key.text.trim());
      await s.refresh();
      ok = true;
      message = l.recoveryDone;
    } catch (_) {
      ok = false;
      message = l.recoveryWrong;
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(l.enterRecoveryKey),
        border: null,
        backgroundColor: p.background,
        trailing: CupertinoButton(
          key: const Key('recovery-submit'),
          padding: EdgeInsets.zero,
          onPressed: busy ? null : (ok ? () => Navigator.pop(context) : submit),
          child: busy ? const CupertinoActivityIndicator() : Text(ok ? l.done : l.open),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Tokens.space[3]),
          children: [
            Text(l.enterRecoveryKeyBody, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            SizedBox(height: Tokens.space[3]),
            CupertinoTextField(
              key: const Key('recovery-key'),
              controller: key,
              placeholder: l.recoveryKeyHint,
              autofocus: true,
              autocorrect: false,
              minLines: 3,
              maxLines: 5,
              padding: EdgeInsets.all(Tokens.space[3]),
              style: Tokens.body.style.copyWith(color: p.label),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[1])),
            ),
            if (message != null)
              Padding(
                padding: EdgeInsets.only(top: Tokens.space[2]),
                child: Text(message!, style: Tokens.caption.style.copyWith(color: ok ? p.accent : Palette.tileRed)),
              ),
          ],
        ),
      ),
    );
  }
}
