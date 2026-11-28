// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 이름 색 and 방마다 다른 이름 (v1): how my name looks to others in groups.
// Both live on my member event in each room (the server sees them, like any
// name); nothing else about me changes.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'name_colors.dart';
import 'settings_kit.dart';

/// Settings > 모양 > 이름 색: 8 colours (or automatic), used in every group.
class NameColorPage extends StatefulWidget {
  const NameColorPage({super.key});
  @override
  State<NameColorPage> createState() => _NameColorPageState();
}

class _NameColorPageState extends State<NameColorPage> {
  String myName = '';

  @override
  void initState() {
    super.initState();
    unawaited(
      AppScope.read(context).backend.myName().then((n) {
        if (mounted) setState(() => myName = n);
      }, onError: (_) {}),
    );
  }

  Future<void> pick(AppState s, String key) async {
    await s.setPref('name_color', key);
    final me = s.backend.userId ?? '';
    if (key.isEmpty) {
      NameColors.picked.remove(me);
    } else {
      NameColors.picked[me] = key;
    }
    if (mounted) setState(() {});
    // Every group I'm in (channels show no names), and later ones too.
    await s.applyNameColor();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final now = s.pref('name_color', '');
    final me = s.backend.userId ?? '';
    final name = myName.isNotEmpty ? myName : (me.startsWith('@') ? me.substring(1).split(':').first : me);
    final shown = NameColors.colorOf(now) ?? Avatar.colorFor(name);
    Widget dot(String key) {
      final c = NameColors.colorOf(key);
      final on = now == key;
      return GestureDetector(
        key: Key('name-color-${key.isEmpty ? 'auto' : key}'),
        onTap: () => pick(s, key),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c ?? p.secondaryLabel.withValues(alpha: 0.18)),
          child: on
              ? const Icon(CupertinoIcons.checkmark_alt, color: Color(0xFFFFFFFF), size: 22)
              : (c == null ? Text('A', style: Tokens.body.style.copyWith(color: p.secondaryLabel)) : null),
        ),
      );
    }

    return SettingsScaffold(
      title: l.nameColor,
      children: [
        // Preview: my name over a group message, as others see it.
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              key: const Key('name-color-preview'),
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + 2, vertical: Tokens.space[1] + 2),
              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Tokens.caption.style.copyWith(color: shown)),
                  Text(l.nameColorSample, style: Tokens.body.style.copyWith(color: p.label)),
                ],
              ),
            ),
          ),
        ),
        group(context, footer: l.nameColorInfo, [
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: Wrap(spacing: Tokens.space[2] + 2, runSpacing: Tokens.space[2] + 2, children: [dot(''), for (final k in NameColors.keys) dot(k)]),
          ),
        ]),
      ],
    );
  }
}

/// Group info > 이 그룹에서 내 이름: a name only this group sees.
class RoomNamePage extends StatefulWidget {
  const RoomNamePage({super.key, required this.roomId, required this.current});
  final String roomId;
  final String current;
  @override
  State<RoomNamePage> createState() => _RoomNamePageState();
}

class _RoomNamePageState extends State<RoomNamePage> {
  late final TextEditingController text = TextEditingController(text: widget.current);

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final s = AppScope.read(context);
    final nav = Navigator.of(context);
    try {
      await s.backend.setMyRoomLook(widget.roomId, name: text.text.trim());
    } catch (_) {}
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.roomName),
        trailing: AccentCircle(key: const Key('room-name-save'), icon: CupertinoIcons.checkmark_alt, onTap: save),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SizedBox(height: Tokens.space[3]),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.roomNameInfo),
              children: [
                CupertinoTextField.borderless(
                  key: const Key('room-name-field'),
                  controller: text,
                  autofocus: true,
                  placeholder: l.roomNameHint,
                  placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                  style: Tokens.body.style.copyWith(color: p.label),
                  maxLength: 64,
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[2] + 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
