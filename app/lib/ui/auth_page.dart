// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sign-up (ID + password + invite code, no phone number) and log-in.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool signUp = true;
  bool busy = false;
  String? error;
  final id = TextEditingController(), pw = TextEditingController(), invite = TextEditingController();

  static bool goodPassword(String p) => p.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

  Future<void> submit() async {
    final l = L.of(context);
    final state = AppScope.of(context);
    if (id.text.trim().isEmpty || pw.text.isEmpty) return setState(() => error = l.fieldRequired);
    if (signUp && !goodPassword(pw.text)) return setState(() => error = l.passwordRule);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (signUp) {
        await state.register(id.text.trim(), pw.text, invite.text.trim().isEmpty ? null : invite.text.trim());
      } else {
        await state.login(id.text.trim(), pw.text);
      }
    } catch (_) {
      if (mounted) setState(() => error = l.somethingWrong);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(Palette p, TextEditingController c, String hint, {bool secret = false, Key? key}) => Padding(
    padding: EdgeInsets.only(bottom: Tokens.space[1]),
    child: CupertinoTextField(
      key: key,
      controller: c,
      placeholder: hint,
      obscureText: secret,
      autocorrect: false,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 2),
      style: Tokens.body.style.copyWith(color: p.label),
      placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[1])),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[5] * 2, Tokens.space[3], Tokens.space[4]),
          children: [
            Text(signUp ? l.signUpTitle : l.logInTitle, style: Tokens.largeTitle.style.copyWith(color: p.label)),
            SizedBox(height: Tokens.space[1]),
            if (signUp) Text(l.signUpSub, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            SizedBox(height: Tokens.space[4]),
            field(p, id, l.signUpId, key: const Key('auth-id')),
            field(p, pw, l.signUpPassword, secret: true, key: const Key('auth-pw')),
            if (signUp) field(p, invite, l.signUpInvite, key: const Key('auth-invite')),
            if (error != null)
              Padding(
                padding: EdgeInsets.only(top: Tokens.space[1]),
                child: Text(error!, style: Tokens.caption.style.copyWith(color: Palette.tileRed)),
              ),
            SizedBox(height: Tokens.space[4]),
            CupertinoButton.filled(
              key: const Key('auth-submit'),
              onPressed: busy ? null : submit,
              borderRadius: BorderRadius.circular(Tokens.capsule),
              child: busy
                  ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                  : Text(signUp ? l.signUpButton : l.logInButton, style: Tokens.body.style.copyWith(color: p.onAccent)),
            ),
            CupertinoButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      signUp = !signUp;
                      error = null;
                    }),
              child: Text(signUp ? l.haveAccount : l.noAccount, style: Tokens.preview.style.copyWith(color: p.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
