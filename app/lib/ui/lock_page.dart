// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// App lock: one password field. Normal, hide and delete passwords all
// look and feel the same here (same screen, same wait).
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class LockPage extends StatefulWidget {
  const LockPage({super.key});
  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final pw = TextEditingController();
  bool busy = false;
  bool wrong = false;

  /// Wrong tries left before everything is erased (shown when 3 or fewer).
  int? left;

  Future<void> open() async {
    if (busy || pw.text.isEmpty) return;
    setState(() {
      busy = true;
      wrong = false;
    });
    final st = AppScope.of(context);
    final ok = await st.unlock(pw.text);
    if (!mounted) return;
    if (!ok) {
      final n = await st.backend.wipeAfter() - await st.backend.lockFails();
      if (!mounted) return;
      pw.clear();
      setState(() {
        busy = false;
        wrong = true;
        left = n <= 3 ? n : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                child: Icon(CupertinoIcons.lock_fill, color: p.onAccent, size: 30),
              ),
              SizedBox(height: Tokens.space[4]),
              Text(l.lockTitle, style: Tokens.cardTitle.style.copyWith(color: p.label)),
              SizedBox(height: Tokens.space[4]),
              CupertinoTextField(
                key: const Key('lock-password'),
                controller: pw,
                obscureText: true,
                autofocus: true,
                enabled: !busy,
                textAlign: TextAlign.center,
                padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                style: Tokens.body.style.copyWith(color: p.label),
                decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                onSubmitted: (_) => open(),
              ),
              SizedBox(height: Tokens.space[2]),
              SizedBox(
                height: Tokens.space[4],
                child: wrong
                    ? Text(
                        left == null ? l.lockWrong : l.wipeWarning(left!),
                        key: const Key('lock-wrong'),
                        textAlign: TextAlign.center,
                        style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                      )
                    : null,
              ),
              SizedBox(height: Tokens.space[2]),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  key: const Key('lock-open'),
                  onPressed: busy ? null : open,
                  child: busy ? const CupertinoActivityIndicator() : Text(l.open),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
