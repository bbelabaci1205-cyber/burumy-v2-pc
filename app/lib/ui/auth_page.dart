// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Sign-up (ID + password + invite code, no phone number) and log-in.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/features.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios_route.dart';
import 'link_pc.dart' show QrLoginPage;
import 'trust_ui.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool signUp = true;
  bool busy = false;
  String? error;
  final id = TextEditingController(), pw = TextEditingController(), invite = TextEditingController(), claim = TextEditingController();

  /// The ID is held for its owner or for sale: offer the code field.
  bool reservedId = false, showClaim = false;

  static bool goodPassword(String p) => p.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

  Future<void> submit() async {
    final l = L.of(context);
    final state = AppScope.of(context);
    if (id.text.trim().isEmpty || pw.text.isEmpty) return setState(() => error = l.fieldRequired);
    if (signUp && !goodPassword(pw.text)) return setState(() => error = l.passwordRule);
    // Adding an account: one that is already on this phone can't come twice.
    final here = state.accounts?.list.any((e) => e.userId.split(':').first.toLowerCase() == '@${id.text.trim().toLowerCase()}') ?? false;
    if (here) return setState(() => error = l.accountsAlready);
    if (signUp) {
      // 예약 아이디: the real owner (or buyer) got a code from us.
      if (showClaim && claim.text.trim().isNotEmpty) {
        try {
          await state.backend.claimOpen(id.text.trim(), claim.text.trim());
        } catch (_) {
          if (mounted) setState(() => error = l.claimCodeWrong);
          return;
        }
      }
      // 사칭 막기: reserved names and look-alikes of official accounts.
      String why = '';
      try {
        why = await state.backend.nameCheck(id.text.trim());
      } catch (_) {}
      if (!mounted) return;
      if (why.isNotEmpty) {
        return setState(() {
          error = nameRefusal(l, why, id: true);
          reservedId = why == 'reserved_owner' || why == 'reserved_sale';
        });
      }
    }
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
    } on AccountAlreadyHere {
      return;
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
    final adding = AppScope.of(context).accounts?.adding ?? false;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], adding ? Tokens.space[1] : Tokens.space[5] * 2, Tokens.space[3], Tokens.space[4]),
          children: [
            // "계정 추가" came here: a way back to the account I was using.
            if (adding)
              Align(
                alignment: Alignment.centerLeft,
                child: CupertinoButton(
                  key: const Key('auth-cancel-add'),
                  padding: EdgeInsets.zero,
                  onPressed: busy ? null : () => AppScope.of(context).accounts?.cancelAdd(),
                  child: Text(l.cancel, style: Tokens.body.style.copyWith(color: p.accent)),
                ),
              ),
            if (adding) SizedBox(height: Tokens.space[5]),
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
                child: Text(
                  error!,
                  key: const Key('auth-error'),
                  style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                ),
              ),
            // A reserved ID: its owner types the code we sent them.
            if (signUp && (reservedId || showClaim)) ...[
              if (!showClaim)
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    key: const Key('auth-claim-open'),
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                    minimumSize: Size.zero,
                    onPressed: () => setState(() => showClaim = true),
                    child: Text(l.claimHaveCode, style: Tokens.preview.style.copyWith(color: p.accent)),
                  ),
                )
              else ...[
                SizedBox(height: Tokens.space[2]),
                field(p, claim, l.claimCodeHint, key: const Key('auth-claim')),
                Text(l.claimCodeHelp, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
              ],
            ],
            SizedBox(height: Tokens.space[4]),
            CupertinoButton.filled(
              key: const Key('auth-submit'),
              onPressed: busy ? null : submit,
              borderRadius: BorderRadius.circular(Tokens.capsule),
              child: busy
                  ? const CupertinoActivityIndicator(color: Color(0xFFFFFFFF))
                  : Text(signUp ? l.signUpButton : l.logInButton, style: Tokens.body.style.copyWith(color: p.onAccent)),
            ),
            // QR로 PC 연결 (tip 78): sign in here by scanning with the phone.
            if (!signUp && Features.loginSafety)
              CupertinoButton(
                key: const Key('auth-qr'),
                onPressed: busy ? null : () => Navigator.of(context).push(IosPageRoute(builder: (_) => const QrLoginPage())),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.qrcode, size: Tokens.listIconSmall, color: p.accent),
                    SizedBox(width: Tokens.space[1]),
                    Text(l.qrLoginTitle, style: Tokens.preview.style.copyWith(color: p.accent)),
                  ],
                ),
              ),
            CupertinoButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      signUp = !signUp;
                      error = null;
                      reservedId = showClaim = false;
                    }),
              child: Text(signUp ? l.haveAccount : l.noAccount, style: Tokens.preview.style.copyWith(color: p.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
