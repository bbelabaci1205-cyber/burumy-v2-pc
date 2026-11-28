// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 설정 > 개인정보 > 아이디 키: strangers need my ID *and* this key to start
// a 1:1 chat. Friends and people I already talk with are not asked.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/id_key.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'settings_kit.dart';

class IdKeyPage extends StatefulWidget {
  const IdKeyPage({super.key});
  @override
  State<IdKeyPage> createState() => _IdKeyPageState();
}

class _IdKeyPageState extends State<IdKeyPage> {
  late final field = TextEditingController(text: AppScope.read(context).pref(IdKey.pref, ''));
  bool bad = false;

  Future<void> save() async {
    final k = IdKey.normal(field.text);
    if (!IdKey.valid(k)) return setState(() => bad = true);
    await AppScope.read(context).setPref(IdKey.pref, k);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final now = s.pref(IdKey.pref, '');
    return SettingsScaffold(
      title: l.idKey,
      children: [
        group(context, header: l.idKeyMine, footer: bad ? l.idKeyBad : l.idKeyInfo, error: bad, [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
            child: CupertinoTextField(
              key: const Key('id-key-field'),
              controller: field,
              placeholder: l.idKeyHint,
              autocorrect: false,
              maxLength: IdKey.maxLength,
              decoration: null,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
              onChanged: (_) {
                if (bad) setState(() => bad = false);
              },
              onSubmitted: (_) => save(),
            ),
          ),
          NavRow(key: const Key('id-key-save'), title: l.save, onTap: save),
        ]),
        if (now.isNotEmpty)
          group(context, footer: l.idKeyOffInfo, [
            NavRow(
              key: const Key('id-key-off'),
              title: l.idKeyOff,
              danger: true,
              onTap: () async {
                field.clear();
                await s.setPref(IdKey.pref, '');
              },
            ),
          ]),
      ],
    );
  }
}
