// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Channel and group tools that post a "card": giveaway, form, FAQ, guide
// menu, link buttons, formatted post and safety check-in, plus post
// templates. Layout follows Burumy v1 (Eric 2026-11-24); sizes follow the
// rulebook D chapter (rows 52, side 16, corners 26, 17/15/13 type).
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/link_check.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'links.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'wide.dart';

/// Tools that open a card editor from the attach sheet.
const cardKinds = ['lottery', 'form', 'faq', 'guide', 'links', 'rich', 'checkin'];

// ---------------------------------------------------------------------------
// Shared pieces

TextStyle _fieldStyle(BuildContext c) => Tokens.body.style.copyWith(color: paletteOf(c).label);

Widget _field(
  BuildContext context,
  TextEditingController c, {
  required String key,
  required String hint,
  int max = 200,
  int lines = 1,
  TextStyle? style,
  ValueChanged<String>? onChanged,
  TextInputType? keyboard,
}) => CupertinoTextField.borderless(
  key: Key(key),
  controller: c,
  placeholder: hint,
  style: style ?? _fieldStyle(context),
  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
  maxLength: max,
  minLines: lines,
  maxLines: lines == 1 ? 1 : lines + 6,
  keyboardType: keyboard,
  onChanged: onChanged,
);

/// "+ 질문 추가" style row in accent colour.
Widget _addRow(BuildContext context, String key, String label, VoidCallback onTap) {
  final p = paletteOf(context);
  return GestureDetector(
    key: Key(key),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
      child: Row(
        children: [
          Icon(CupertinoIcons.add, size: Tokens.listIcon, color: p.accent),
          SizedBox(width: Tokens.space[2]),
          Text(label, style: Tokens.body.style.copyWith(color: p.accent)),
        ],
      ),
    ),
  );
}

Widget _removeRow(BuildContext context, String key, String label, VoidCallback onTap) => GestureDetector(
  key: Key(key),
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  child: Center(
    child: Text(label, style: Tokens.body.style.copyWith(color: Palette.tileRed)),
  ),
);

/// Label on the left, control on the right (a 52 pt settings row).
Widget _row(BuildContext context, String title, Widget trailing, {String? sub}) {
  final p = paletteOf(context);
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Tokens.body.style.copyWith(color: p.label)),
              if (sub != null) ...[const SizedBox(height: Tokens.nameToSub), Text(sub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel))],
            ],
          ),
        ),
        SizedBox(width: Tokens.space[2]),
        trailing,
      ],
    ),
  );
}

/// Full-screen editor: round close, title, "보내기" pill (v1 layout).
class _EditorScaffold extends StatelessWidget {
  const _EditorScaffold({required this.title, required this.ready, required this.onSend, required this.children, this.error});
  final String title;
  final bool ready;
  final VoidCallback onSend;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(title),
        trailing: Opacity(
          opacity: ready ? 1 : 0.4,
          child: GlassPill(key: const Key('card-send'), text: l.send, onTap: ready ? onSend : null),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(bottom: Tokens.space[5]),
          children: [
            if (error != null)
              Padding(
                padding: EdgeInsets.fromLTRB(32, Tokens.space[2], 32, 0),
                child: Text(
                  error!,
                  key: const Key('card-error'),
                  style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}

mixin _Sending<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  String get roomId;
  String get kind;
  Map<String, Object?> get data;

  Future<void> sendCard() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.read(context).backend.createCard(roomId, kind, data);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

/// The page for one card kind.
Widget cardEditor(String roomId, String kind) => switch (kind) {
  'lottery' => LotteryEditor(roomId: roomId),
  'form' => FormEditor(roomId: roomId),
  'faq' => FaqEditor(roomId: roomId, guide: false),
  'guide' => FaqEditor(roomId: roomId, guide: true),
  'links' => LinksEditor(roomId: roomId),
  'rich' => RichEditor(roomId: roomId),
  _ => CheckinEditor(roomId: roomId),
};

// ---------------------------------------------------------------------------
// Giveaway

class LotteryEditor extends StatefulWidget {
  const LotteryEditor({super.key, required this.roomId});
  final String roomId;

  @override
  State<LotteryEditor> createState() => _LotteryEditorState();
}

class _LotteryEditorState extends State<LotteryEditor> with _Sending {
  final prize = TextEditingController();
  int winners = 1;

  /// Hours until it ends (0 = I close it myself).
  int hours = 24;
  bool announce = false;

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => 'lottery';
  @override
  Map<String, Object?> get data => {
    'prize': prize.text.trim(),
    'winners': winners,
    'ends_at': hours == 0 ? 0 : DateTime.now().add(Duration(hours: hours)).millisecondsSinceEpoch,
    'announce': announce,
  };

  @override
  void dispose() {
    prize.dispose();
    super.dispose();
  }

  String endsLabel(L l) => switch (hours) {
    0 => l.lotteryEndsManual,
    1 => l.pollIn1h,
    24 => l.pollIn1d,
    72 => l.pollIn3d,
    _ => l.pollIn1w,
  };

  Future<void> pickEnd() async {
    final l = L.of(context);
    final got = await showCupertinoModalPopup<int>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.lotteryEnds),
        actions: [
          for (final (i, h) in const [0, 1, 24, 72, 168].indexed)
            CupertinoActionSheetAction(
              key: Key('lottery-end-$i'),
              onPressed: () => Navigator.pop(c, h),
              child: Text(switch (h) {
                0 => l.lotteryEndsManual,
                1 => l.pollIn1h,
                24 => l.pollIn1d,
                72 => l.pollIn3d,
                _ => l.pollIn1w,
              }),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (got != null) setState(() => hours = got);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ready = prize.text.trim().isNotEmpty && !busy;
    Widget step(IconData icon, String key, VoidCallback? onTap) => GestureDetector(
      key: Key(key),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 32,
        child: Icon(icon, size: Tokens.listIconSmall, color: onTap == null ? p.secondaryLabel.withValues(alpha: 0.4) : p.label),
      ),
    );
    return _EditorScaffold(
      title: l.newLottery,
      ready: ready,
      onSend: sendCard,
      error: error,
      children: [
        IosSection(
          hasLeading: false,
          header: sectionHeader(context, l.lotteryPrize),
          footer: sectionFooter(context, l.lotteryPrizeInfo),
          children: [_field(context, prize, key: 'lottery-prize', hint: l.lotteryPrizeHint, onChanged: (_) => setState(() {}))],
        ),
        IosSection(
          hasLeading: false,
          footer: sectionFooter(context, l.lotteryInfo),
          children: [
            _row(
              context,
              l.lotteryWinners,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$winners',
                    key: const Key('lottery-winners'),
                    style: Tokens.body.style.copyWith(color: p.secondaryLabel),
                  ),
                  SizedBox(width: Tokens.space[2]),
                  // iOS stepper: one grey capsule, two halves.
                  Container(
                    decoration: BoxDecoration(
                      color: p.dark ? const Color(0x3D767680) : const Color(0x1F767680),
                      borderRadius: BorderRadius.circular(Tokens.capsule),
                    ),
                    child: Row(
                      children: [
                        step(CupertinoIcons.minus, 'lottery-minus', winners > 1 ? () => setState(() => winners--) : null),
                        Container(width: 1, height: 18, color: p.separator),
                        step(CupertinoIcons.plus, 'lottery-plus', winners < 100 ? () => setState(() => winners++) : null),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              key: const Key('lottery-end'),
              behavior: HitTestBehavior.opaque,
              onTap: pickEnd,
              child: _row(
                context,
                l.lotteryEnds,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(endsLabel(l), style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                    SizedBox(width: Tokens.space[1]),
                    Icon(CupertinoIcons.chevron_forward, size: 16, color: p.dark ? const Color(0xFF5A5A5F) : const Color(0xFFBCBCC1)),
                  ],
                ),
              ),
            ),
            _row(
              context,
              l.lotteryAnnounce,
              IosSwitch(key: const Key('lottery-announce'), value: announce, onChanged: (v) => setState(() => announce = v)),
              sub: l.lotteryAnnounceInfo,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form

class FormEditor extends StatefulWidget {
  const FormEditor({super.key, required this.roomId});
  final String roomId;

  @override
  State<FormEditor> createState() => _FormEditorState();
}

class _FormQ {
  final q = TextEditingController();
  final options = TextEditingController();
  bool choice = false;
  void dispose() {
    q.dispose();
    options.dispose();
  }
}

class _FormEditorState extends State<FormEditor> with _Sending {
  final title = TextEditingController();
  final qs = [_FormQ()];

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => 'form';
  @override
  Map<String, Object?> get data => {
    'title': title.text.trim(),
    'questions': [
      for (final q in qs)
        if (q.q.text.trim().isNotEmpty)
          {
            'q': q.q.text.trim(),
            'options': q.choice
                ? [
                    for (final o in q.options.text.split('\n'))
                      if (o.trim().isNotEmpty) o.trim(),
                  ]
                : <String>[],
          },
    ],
  };

  @override
  void dispose() {
    title.dispose();
    for (final q in qs) {
      q.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final ready = title.text.trim().isNotEmpty && qs.any((q) => q.q.text.trim().isNotEmpty) && !busy;
    return _EditorScaffold(
      title: l.newForm,
      ready: ready,
      onSend: sendCard,
      error: error,
      children: [
        IosSection(
          hasLeading: false,
          header: sectionHeader(context, l.cardTitleLabel),
          children: [_field(context, title, key: 'form-title', hint: l.formTitleHint, onChanged: (_) => setState(() {}))],
        ),
        for (final (i, q) in qs.indexed)
          IosSection(
            hasLeading: false,
            header: sectionHeader(context, l.formQuestionN(i + 1)),
            children: [
              _field(context, q.q, key: 'form-q-$i', hint: l.formQuestionHint, onChanged: (_) => setState(() {})),
              _row(
                context,
                l.formAnswerType,
                SizedBox(
                  width: 168,
                  child: IosSegmented<bool>(
                    key: Key('form-type-$i'),
                    groupValue: q.choice,
                    onValueChanged: (v) => setState(() => q.choice = v ?? false),
                    children: {false: Text(l.formShort), true: Text(l.formChoice)},
                  ),
                ),
              ),
              if (q.choice) _field(context, q.options, key: 'form-options-$i', hint: l.formOptionsHint, max: 1100, lines: 3),
              if (qs.length > 1)
                _removeRow(context, 'form-remove-$i', l.cardRemove, () {
                  setState(() => qs.removeAt(i));
                  q.dispose();
                }),
            ],
          ),
        IosSection(
          hasLeading: false,
          footer: sectionFooter(context, l.formInfo),
          children: [if (qs.length < 20) _addRow(context, 'form-add', l.formAddQuestion, () => setState(() => qs.add(_FormQ())))],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// FAQ and guide menu (same shape: title + pairs)

class FaqEditor extends StatefulWidget {
  const FaqEditor({super.key, required this.roomId, required this.guide});
  final String roomId;
  final bool guide;

  @override
  State<FaqEditor> createState() => _FaqEditorState();
}

class _FaqEditorState extends State<FaqEditor> with _Sending {
  late final title = TextEditingController(text: widget.guide ? '' : null);
  final sub = TextEditingController();
  final items = <(TextEditingController, TextEditingController)>[(TextEditingController(), TextEditingController())];
  bool seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!seeded && !widget.guide) title.text = L.of(context).cardFaq;
    seeded = true;
  }

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => widget.guide ? 'guide' : 'faq';
  @override
  Map<String, Object?> get data => {
    'title': title.text.trim(),
    if (widget.guide) 'sub': sub.text.trim(),
    'items': [
      for (final (a, b) in items)
        if (a.text.trim().isNotEmpty && b.text.trim().isNotEmpty)
          widget.guide ? {'label': a.text.trim(), 'text': b.text.trim()} : {'q': a.text.trim(), 'a': b.text.trim()},
    ],
  };

  @override
  void dispose() {
    title.dispose();
    sub.dispose();
    for (final (a, b) in items) {
      a.dispose();
      b.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final g = widget.guide;
    final ok = items.any((x) => x.$1.text.trim().isNotEmpty && x.$2.text.trim().isNotEmpty);
    final max = g ? 20 : 30;
    return _EditorScaffold(
      title: g ? l.newGuide : l.newFaq,
      ready: ok && (!g || title.text.trim().isNotEmpty) && !busy,
      onSend: sendCard,
      error: error,
      children: [
        IosSection(
          hasLeading: false,
          header: sectionHeader(context, l.cardTitleLabel),
          children: [
            _field(context, title, key: 'faq-title', hint: g ? l.guideTitleHint : l.cardFaq, max: 100, onChanged: (_) => setState(() {})),
            if (g) _field(context, sub, key: 'guide-sub', hint: l.guideSubHint),
          ],
        ),
        for (final (i, (a, b)) in items.indexed)
          IosSection(
            hasLeading: false,
            header: g && i > 0 ? null : sectionHeader(context, g ? l.guideButtons : l.formQuestionN(i + 1)),
            children: [
              _field(context, a, key: 'faq-q-$i', hint: g ? l.guideLabel : l.faqQ, max: g ? 60 : 200, onChanged: (_) => setState(() {})),
              _field(context, b, key: 'faq-a-$i', hint: g ? l.guideText : l.faqA, max: 1000, lines: 2, onChanged: (_) => setState(() {})),
              if (items.length > 1)
                _removeRow(context, 'faq-remove-$i', l.cardRemove, () {
                  setState(() => items.removeAt(i));
                  a.dispose();
                  b.dispose();
                }),
            ],
          ),
        IosSection(
          hasLeading: false,
          footer: sectionFooter(context, g ? l.guideInfo : l.faqInfo),
          children: [
            if (items.length < max)
              _addRow(
                context,
                'faq-add',
                g ? l.guideAddButton : l.formAddQuestion,
                () => setState(() => items.add((TextEditingController(), TextEditingController()))),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Safety check-in

class CheckinEditor extends StatefulWidget {
  const CheckinEditor({super.key, required this.roomId});
  final String roomId;

  @override
  State<CheckinEditor> createState() => _CheckinEditorState();
}

class _CheckinEditorState extends State<CheckinEditor> with _Sending {
  final text = TextEditingController();

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => 'checkin';
  @override
  Map<String, Object?> get data => {'text': text.text.trim()};

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return _EditorScaffold(
      title: l.newCheckin,
      ready: text.text.trim().isNotEmpty && !busy,
      onSend: sendCard,
      error: error,
      children: [
        IosSection(
          hasLeading: false,
          footer: sectionFooter(context, l.checkinInfo),
          children: [_field(context, text, key: 'checkin-text', hint: l.checkinHint, max: 500, lines: 3, onChanged: (_) => setState(() {}))],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Link buttons

/// iOS colours for link buttons (never dark green; "green" = theme accent).
const linkColors = ['green', 'blue', 'teal', 'purple', 'pink', 'red', 'orange', 'yellow', 'grey', 'black', 'white'];

Color linkColor(String name, Palette p) => switch (name) {
  'blue' => Palette.tileBlue,
  'teal' => Palette.tileTeal,
  'purple' => Palette.tilePurple,
  'pink' => Palette.tilePink,
  'red' => Palette.tileRed,
  'orange' => Palette.tileOrange,
  'yellow' => Palette.tileYellow,
  'grey' => Palette.tileGrey,
  'black' => const Color(0xFF1C1C1E),
  'white' => const Color(0xFFFFFFFF),
  _ => p.accent,
};

/// "example.com" -> "https://example.com"; null when it is not a web link.
String? webLink(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(s)) s = 'https://$s';
  final u = Uri.tryParse(s);
  if (u == null || u.host.isEmpty || !u.host.contains('.') || s.contains(RegExp(r'\s')) || s.length > 500) return null;
  return s;
}

/// Shows the real address (and a warning for a suspicious one) before
/// opening: a button's name can say anything.
Future<void> openCardLink(BuildContext context, String url) async {
  final l = L.of(context);
  final p = paletteOf(context);
  final bad = suspicious(url) != null;
  final ok = await showCupertinoModalPopup<bool>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(bad ? l.scamLink : l.openLinkAsk, style: bad ? TextStyle(color: Palette.tileRed) : null),
      message: Text(
        url,
        key: const Key('card-link-real'),
        style: TextStyle(color: p.secondaryLabel),
      ),
      actions: [
        CupertinoActionSheetAction(
          key: const Key('card-link-open'),
          isDestructiveAction: bad,
          onPressed: () => Navigator.pop(c, true),
          child: Text(l.openLink),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (ok == true && context.mounted) await openWebLink(context, url);
}

/// The buttons, in rows, styled as the maker chose.
class LinkButtonGrid extends StatelessWidget {
  const LinkButtonGrid({super.key, required this.buttons, required this.style, this.onTap, this.selected, this.keyPrefix = 'link-btn'});
  final List<Map<String, Object?>> buttons;
  final Map<String, Object?> style;
  final void Function(int index)? onTap;
  final int? selected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final h = switch (style['size']) {
      's' => 34.0,
      'l' => 56.0,
      _ => 42.0,
    };
    final radius = switch (style['shape']) {
      'pill' => Tokens.capsule,
      'square' => Tokens.radius[0],
      _ => Tokens.radius[1],
    };
    final glass = style['glass'] != false;
    final rows = <int, List<int>>{};
    for (var i = 0; i < buttons.length; i++) {
      final r = buttons[i]['row'] is int ? buttons[i]['row'] as int : 0;
      rows.putIfAbsent(r, () => []).add(i);
    }
    final keys = rows.keys.toList()..sort();
    Widget button(int i) {
      final b = buttons[i];
      final own = b['color'] as String? ?? '';
      final name = own.isEmpty ? (style['color'] as String? ?? 'green') : own;
      final bg = linkColor(name, p);
      final ink = switch (style['ink']) {
        'white' => const Color(0xFFFFFFFF),
        'black' => const Color(0xFF000000),
        _ => (name == 'yellow' || name == 'white') ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      };
      final on = selected == i;
      return Expanded(
        child: GestureDetector(
          key: Key('$keyPrefix-$i'),
          onTap: onTap == null ? null : () => onTap!(i),
          // iOS lift for the one being edited: a little bigger, soft shadow.
          child: AnimatedScale(
            scale: on ? 1.04 : 1,
            duration: const Duration(milliseconds: 180),
            child: Container(
              height: h,
              margin: const EdgeInsets.all(2),
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Flat colour glass: slightly see-through with a light top edge, no glow.
                color: glass ? bg.withValues(alpha: 0.86) : bg,
                gradient: glass
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color.lerp(bg, const Color(0xFFFFFFFF), 0.14)!.withValues(alpha: 0.9), bg.withValues(alpha: 0.86)],
                      )
                    : null,
                border: name == 'white' ? Border.all(color: p.separator) : null,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: on ? const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      b['label'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.preview.style.copyWith(color: ink, fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(width: Tokens.space[0]),
                  Icon(CupertinoIcons.arrow_up_right, size: 11, color: ink.withValues(alpha: 0.85)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in keys) Row(children: [for (final i in rows[r]!) button(i)]),
      ],
    );
  }
}

class LinksEditor extends StatefulWidget {
  const LinksEditor({super.key, required this.roomId});
  final String roomId;

  @override
  State<LinksEditor> createState() => _LinksEditorState();
}

class _LinksEditorState extends State<LinksEditor> with _Sending {
  final text = TextEditingController();
  final label = TextEditingController();
  final url = TextEditingController();

  /// Each button: label, raw url, own colour ("" = follow), row.
  final buttons = <Map<String, Object?>>[];
  int? editing;
  String color = 'green', size = 'm', shape = 'round', ink = 'auto';
  bool glass = true;

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => 'links';
  @override
  Map<String, Object?> get data => {
    'text': text.text.trim(),
    'buttons': [
      for (final b in buttons)
        if (webLink(b['url'] as String) case final u? when (b['label'] as String).trim().isNotEmpty) {...b, 'label': (b['label'] as String).trim(), 'url': u},
    ],
    'style': style,
  };
  Map<String, Object?> get style => {'color': color, 'glass': glass, 'size': size, 'shape': shape, 'ink': ink};

  int get rowCount => buttons.isEmpty ? 0 : buttons.map((b) => b['row'] as int).reduce((a, b) => a > b ? a : b) + 1;
  int inRow(int r) => buttons.where((b) => b['row'] == r).length;

  @override
  void dispose() {
    text.dispose();
    label.dispose();
    url.dispose();
    super.dispose();
  }

  void select(int i) {
    setState(() {
      editing = i;
      label.text = buttons[i]['label'] as String;
      url.text = buttons[i]['url'] as String;
    });
  }

  void add(int row) {
    if (buttons.length >= 18 || inRow(row) >= 3 || row > 5) return;
    final l = L.of(context);
    buttons.add({'label': l.linksLabel, 'url': '', 'color': '', 'row': row});
    // Keep rows in order so indexes match what is shown.
    buttons.sort((a, b) => (a['row'] as int).compareTo(b['row'] as int));
    select(buttons.lastIndexWhere((b) => b['row'] == row));
  }

  void remove() {
    final i = editing;
    if (i == null) return;
    final row = buttons[i]['row'] as int;
    setState(() {
      buttons.removeAt(i);
      // Close the gap when a row empties.
      if (inRow(row) == 0) {
        for (final b in buttons) {
          if ((b['row'] as int) > row) b['row'] = (b['row'] as int) - 1;
        }
      }
      editing = null;
    });
  }

  Widget dots(String value, ValueChanged<String> pick, {bool follow = false, required String keyPrefix}) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Wrap(
        spacing: 14,
        runSpacing: Tokens.space[2],
        children: [
          for (final c in [if (follow) '', ...linkColors])
            GestureDetector(
              key: Key('$keyPrefix-${c.isEmpty ? 'follow' : c}'),
              onTap: () => setState(() => pick(c)),
              child: Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: value == c ? p.label : const Color(0x00000000), width: 2),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: linkColor(c.isEmpty ? color : c, p),
                    border: c == 'white' ? Border.all(color: p.separator) : null,
                  ),
                  child: c.isEmpty ? const Icon(CupertinoIcons.link, size: 16, color: Color(0xFFFFFFFF)) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget segmented<T extends Object>(String key, T value, Map<T, String> options, ValueChanged<T> pick) => Padding(
    padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
    child: IosSegmented<T>(
      key: Key(key),
      groupValue: value,
      onValueChanged: (v) => v == null ? null : setState(() => pick(v)),
      children: {for (final e in options.entries) e.key: Text(e.value)},
    ),
  );

  Widget caption(String t) => Padding(
    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], Tokens.space[1]),
    child: Text(t, style: Tokens.preview.style.copyWith(color: paletteOf(context).label)),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final e = editing;
    final ok = data['buttons'] is List && (data['buttons'] as List).isNotEmpty;
    final urlBad = e != null && url.text.trim().isNotEmpty && webLink(url.text) == null;
    final rows = rowCount;
    return _EditorScaffold(
      title: l.cardLinks,
      ready: ok && !busy,
      onSend: sendCard,
      error: error,
      children: [
        IosSection(
          hasLeading: false,
          header: sectionHeader(context, l.linksPreview),
          footer: sectionFooter(context, buttons.isEmpty ? '${l.linksIntro}\n\n${l.linksInfo}' : l.linksLeft(18 - buttons.length)),
          children: [
            _field(context, text, key: 'links-text', hint: l.linksTextHint, max: 2000, lines: 2),
            Padding(
              padding: EdgeInsets.all(Tokens.space[2]),
              child: Column(
                children: [
                  for (var r = 0; r < rows; r++)
                    Row(
                      children: [
                        Expanded(
                          child: LinkButtonGrid(
                            keyPrefix: 'links-btn',
                            buttons: [
                              for (final b in buttons)
                                if (b['row'] == r) b,
                            ],
                            style: style,
                            selected: e != null && buttons[e]['row'] == r ? buttons.where((b) => b['row'] == r).toList().indexOf(buttons[e]) : null,
                            onTap: (j) => select(buttons.indexOf(buttons.where((b) => b['row'] == r).elementAt(j))),
                          ),
                        ),
                        if (inRow(r) < 3 && buttons.length < 18)
                          GestureDetector(
                            key: Key('links-add-$r'),
                            onTap: () => add(r),
                            child: Container(
                              width: 42,
                              height: 42,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(Tokens.radius[1])),
                              child: Icon(CupertinoIcons.add, size: Tokens.listIconSmall, color: p.accent),
                            ),
                          ),
                      ],
                    ),
                  if (rows < 6 && buttons.length < 18)
                    GestureDetector(
                      key: Key(rows == 0 ? 'links-add' : 'links-add-row'),
                      onTap: () => add(rows),
                      child: Container(
                        height: 42,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(Tokens.radius[1])),
                        child: Center(
                          child: Text('+ ${rows == 0 ? l.linksAddButton : l.linksAddRow}', style: Tokens.preview.style.copyWith(color: p.accent)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (e != null)
          IosSection(
            hasLeading: false,
            header: sectionHeader(
              context,
              l.linksEditing('${(buttons[e]['row'] as int) + 1}', '${buttons.where((b) => b['row'] == buttons[e]['row']).toList().indexOf(buttons[e]) + 1}'),
            ),
            footer: urlBad ? sectionFooter(context, l.linksBadUrl, error: true) : null,
            children: [
              _field(context, label, key: 'links-label', hint: l.linksLabel, max: 24, onChanged: (v) => setState(() => buttons[e]['label'] = v)),
              _field(
                context,
                url,
                key: 'links-url',
                hint: 'example.com',
                max: 500,
                keyboard: TextInputType.url,
                onChanged: (v) => setState(() => buttons[e]['url'] = v),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  caption(l.linksColor),
                  dots(buttons[e]['color'] as String, (c) => buttons[e]['color'] = c, follow: true, keyPrefix: 'links-own'),
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
                    child: Text(l.linksColorInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ),
                ],
              ),
              _removeRow(context, 'links-remove', l.linksRemove, remove),
            ],
          ),
        IosSection(
          hasLeading: false,
          header: sectionHeader(context, l.linksStyle),
          footer: sectionFooter(context, '${l.linksStyleInfo}\n\n${l.linksInfo}'),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                caption(l.linksStyleColor),
                dots(color, (c) => color = c, keyPrefix: 'links-all'),
              ],
            ),
            _row(context, l.linksGlass, IosSwitch(key: const Key('links-glass'), value: glass, onChanged: (v) => setState(() => glass = v))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                caption(l.linksSize),
                segmented('links-size', size, {'s': l.sizeSmall, 'm': l.sizeMedium, 'l': l.sizeLarge}, (v) => size = v),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                caption(l.linksShape),
                segmented('links-shape', shape, {'round': l.shapeRound, 'pill': l.shapePill, 'square': l.shapeSquare}, (v) => shape = v),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                caption(l.linksInk),
                segmented('links-ink', ink, {'auto': l.inkAuto, 'white': l.inkWhite, 'black': l.inkBlack}, (v) => ink = v),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Formatted post

class RichEditor extends StatefulWidget {
  const RichEditor({super.key, required this.roomId});
  final String roomId;

  @override
  State<RichEditor> createState() => _RichEditorState();
}

class _Block {
  _Block(this.t);
  String t;
  final text = TextEditingController();
  final url = TextEditingController();
  final focus = FocusNode();
  void dispose() {
    text.dispose();
    url.dispose();
    focus.dispose();
  }
}

class _RichEditorState extends State<RichEditor> with _Sending {
  final title = TextEditingController();
  final blocks = [_Block('p')];

  @override
  String get roomId => widget.roomId;
  @override
  String get kind => 'rich';
  @override
  Map<String, Object?> get data => {
    'title': title.text.trim(),
    'blocks': [
      for (final b in blocks)
        if (b.text.text.trim().isNotEmpty)
          if (b.t != 'link')
            {'t': b.t, 'text': b.text.text.trim()}
          else if (webLink(b.url.text) case final u?)
            {'t': 'link', 'text': b.text.text.trim(), 'url': u},
    ],
  };

  @override
  void dispose() {
    title.dispose();
    for (final b in blocks) {
      b.dispose();
    }
    super.dispose();
  }

  void add(String t) {
    if (blocks.length >= 50) return;
    final b = _Block(t);
    setState(() => blocks.add(b));
    WidgetsBinding.instance.addPostFrameCallback((_) => b.focus.requestFocus());
  }

  TextStyle styleOf(String t, Palette p) => switch (t) {
    'h' => Tokens.cardTitle.style.copyWith(color: p.label),
    'quote' => Tokens.body.style.copyWith(color: p.secondaryLabel),
    'link' => Tokens.body.style.copyWith(color: p.accent),
    _ => Tokens.body.style.copyWith(color: p.label),
  };

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ok = (data['blocks'] as List).isNotEmpty && !busy;
    Widget tool(String t, IconData icon) => GestureDetector(
      key: Key('rich-add-$t'),
      onTap: () => add(t),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, size: Tokens.listIcon, color: p.label),
      ),
    );
    return CupertinoPageScaffold(
      backgroundColor: p.card,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.cardRich),
        trailing: Opacity(
          opacity: ok ? 1 : 0.4,
          child: GlassPill(key: const Key('card-send'), text: l.send, onTap: ok ? sendCard : null),
        ),
        backgroundColor: p.card,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                children: [
                  if (error != null)
                    Text(
                      error!,
                      key: const Key('card-error'),
                      style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                    ),
                  CupertinoTextField.borderless(
                    key: const Key('rich-title'),
                    controller: title,
                    placeholder: l.richTitleHint,
                    maxLength: 200,
                    style: Tokens.screenTitle.style.copyWith(color: p.label),
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                    onChanged: (_) => setState(() {}),
                  ),
                  for (final (i, b) in blocks.indexed)
                    Container(
                      key: Key('rich-block-$i'),
                      margin: EdgeInsets.only(top: Tokens.space[1]),
                      padding: b.t == 'quote' ? EdgeInsets.only(left: Tokens.space[2]) : EdgeInsets.zero,
                      decoration: b.t == 'quote'
                          ? BoxDecoration(
                              border: Border(left: BorderSide(color: p.accent, width: 3)),
                            )
                          : null,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (b.t == 'li')
                            Padding(
                              padding: EdgeInsets.only(top: Tokens.space[1], right: Tokens.space[1]),
                              child: Text('•', style: Tokens.body.style.copyWith(color: p.label)),
                            ),
                          Expanded(
                            child: Column(
                              children: [
                                CupertinoTextField.borderless(
                                  key: Key('rich-text-$i'),
                                  controller: b.text,
                                  focusNode: b.focus,
                                  placeholder: switch (b.t) {
                                    'h' => l.richHeading,
                                    'li' => l.richList,
                                    'quote' => l.richQuote,
                                    'link' => l.richLink,
                                    _ => l.richBodyHint,
                                  },
                                  maxLength: 2000,
                                  minLines: 1,
                                  maxLines: null,
                                  style: styleOf(b.t, p),
                                  padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                  onChanged: (_) => setState(() {}),
                                ),
                                if (b.t == 'link')
                                  CupertinoTextField.borderless(
                                    key: Key('rich-url-$i'),
                                    controller: b.url,
                                    placeholder: l.richLinkUrl,
                                    keyboardType: TextInputType.url,
                                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                    padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                    onChanged: (_) => setState(() {}),
                                  ),
                              ],
                            ),
                          ),
                          if (blocks.length > 1)
                            GestureDetector(
                              key: Key('rich-remove-$i'),
                              onTap: () {
                                setState(() => blocks.removeAt(i));
                                b.dispose();
                              },
                              child: Padding(
                                padding: EdgeInsets.all(Tokens.space[1]),
                                child: Icon(CupertinoIcons.xmark_circle_fill, size: Tokens.listIconSmall, color: p.secondaryLabel.withValues(alpha: 0.5)),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // v1: a glass tool bar at the bottom.
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
              child: LiquidGlass(
                radius: 22,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      tool('p', CupertinoIcons.add),
                      tool('h', CupertinoIcons.textformat_size),
                      tool('li', CupertinoIcons.list_bullet),
                      tool('quote', CupertinoIcons.text_quote),
                      tool('link', CupertinoIcons.link),
                    ],
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

// ---------------------------------------------------------------------------
// Templates (kept on this phone only)

List<String> templatesOf(AppState s) {
  try {
    final v = jsonDecode(s.pref('post_templates', '[]'));
    return v is List
        ? [
            for (final x in v)
              if (x is String && x.trim().isNotEmpty) x,
          ]
        : const [];
  } catch (_) {
    return const [];
  }
}

/// Saved texts; tapping one returns it for the message box.
class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> save(List<String> list) => AppScope.read(context).setPref('post_templates', jsonEncode(list));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final list = templatesOf(s);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), middle: Text(l.cardTemplates), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              hasLeading: false,
              header: sectionHeader(context, l.templatesNew),
              children: [
                _field(context, field, key: 'template-field', hint: l.templatesHint, max: 2000, lines: 2, onChanged: (_) => setState(() {})),
                if (field.text.trim().isNotEmpty)
                  _addRow(context, 'template-save', l.save, () async {
                    if (list.length >= 50) return;
                    await save([field.text.trim(), ...list]);
                    field.clear();
                    if (mounted) setState(() {});
                  }),
              ],
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.templatesInfo),
              children: [
                if (list.isEmpty)
                  Center(
                    child: Text(l.templatesEmpty, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  ),
                for (final (i, t) in list.indexed)
                  GestureDetector(
                    key: Key('template-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, t),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              t,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.body.style.copyWith(color: p.label),
                            ),
                          ),
                          GestureDetector(
                            key: Key('template-remove-$i'),
                            onTap: () async {
                              await save([...list]..removeAt(i));
                              if (mounted) setState(() {});
                            },
                            child: Padding(
                              padding: EdgeInsets.only(left: Tokens.space[2]),
                              child: Icon(CupertinoIcons.minus_circle_fill, size: Tokens.listIcon, color: Palette.tileRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The card in the chat

class CardBubble extends StatefulWidget {
  const CardBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta, required this.onChanged});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final Future<void> Function() onChanged;

  @override
  State<CardBubble> createState() => _CardBubbleState();
}

class _CardBubbleState extends State<CardBubble> {
  final open = <int>{};
  bool busy = false;

  CardInfo get c => widget.msg.card!;
  Color get fg => widget.fg;

  Future<void> run(Future<void> Function() f) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await f();
      await widget.onChanged();
    } catch (_) {
      // The card may have closed meanwhile; the next refresh shows it.
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> confirm(String title, String info, String action) async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (x) => IosActionSheet(
        title: Text(title),
        message: Text(info),
        actions: [CupertinoActionSheetAction(key: const Key('card-confirm'), onPressed: () => Navigator.pop(x, true), child: Text(action))],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(x), child: Text(l.cancel)),
      ),
    );
    return ok == true;
  }

  Widget pill(String key, String label, {bool on = false, VoidCallback? onTap}) {
    final p = paletteOf(context);
    return GestureDetector(
      key: Key(key),
      onTap: busy ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? fg : fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Tokens.caption.style.copyWith(color: on ? (widget.msg.mine ? p.accent : p.card) : fg.withValues(alpha: onTap == null ? 0.5 : 1)),
        ),
      ),
    );
  }

  Text title(String t) => Text(
    t,
    style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w600),
  );
  Text small(String t, {Key? key}) => Text(
    t,
    key: key,
    style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75)),
  );
  Text plain(String t) => Text(t, style: Tokens.body.style.copyWith(color: fg));

  Widget kindLabel(IconData icon, String t) => Padding(
    padding: EdgeInsets.only(bottom: Tokens.space[0]),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: fg.withValues(alpha: 0.75)),
        SizedBox(width: Tokens.space[0]),
        small(t),
      ],
    ),
  );

  Widget answersButton() => pill(
    'card-answers',
    L.of(context).cardAnswers,
    onTap: () => paneNav(context).push(
      IosPageRoute(
        builder: (_) => CardAnswersPage(roomId: widget.roomId, msg: widget.msg),
      ),
    ),
  );

  List<Widget> body(L l) {
    final s = AppScope.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final closed = c.closedAt(now);
    final mine = widget.msg.mine;
    switch (c.kind) {
      case 'faq':
      case 'guide':
        final guide = c.kind == 'guide';
        final items = c.listOf('items');
        return [
          kindLabel(guide ? CupertinoIcons.square_list : CupertinoIcons.question_circle, guide ? l.cardGuide : l.cardFaq),
          // No second line when the title only repeats the kind.
          if (c.text('title').isNotEmpty && c.text('title') != (guide ? l.cardGuide : l.cardFaq)) title(c.text('title')),
          if (c.text('sub').isNotEmpty) small(c.text('sub')),
          SizedBox(height: Tokens.space[1]),
          for (final (i, it) in items.indexed)
            if (guide)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: pill('guide-item-$i', it['label'] as String? ?? '', onTap: () => showGuide(it['label'] as String? ?? '', it['text'] as String? ?? '')),
              )
            else
              GestureDetector(
                key: Key('faq-item-$i'),
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => open.contains(i) ? open.remove(i) : open.add(i)),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              it['q'] as String? ?? '',
                              style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                            ),
                          ),
                          AnimatedRotation(
                            turns: open.contains(i) ? 0.25 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: Icon(CupertinoIcons.chevron_forward, size: 14, color: fg.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                      if (open.contains(i))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            it['a'] as String? ?? '',
                            key: Key('faq-answer-$i'),
                            style: Tokens.preview.style.copyWith(color: fg.withValues(alpha: 0.85)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
        ];
      case 'links':
        return [
          if (c.text('text').isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: Tokens.space[1]),
              child: plain(c.text('text')),
            ),
          LinkButtonGrid(
            buttons: c.listOf('buttons'),
            style: c.data['style'] is Map ? (c.data['style'] as Map).cast<String, Object?>() : const {},
            onTap: (i) => openCardLink(context, c.listOf('buttons')[i]['url'] as String? ?? ''),
          ),
        ];
      case 'rich':
        return [
          if (c.text('title').isNotEmpty) Text(c.text('title'), style: Tokens.cardTitle.style.copyWith(color: fg)),
          for (final b in c.listOf('blocks'))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: switch (b['t']) {
                'h' => Text(
                  b['text'] as String? ?? '',
                  style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w600),
                ),
                'li' => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    plain('•  '),
                    Expanded(child: plain(b['text'] as String? ?? '')),
                  ],
                ),
                'quote' => Container(
                  padding: EdgeInsets.only(left: Tokens.space[1]),
                  decoration: BoxDecoration(
                    border: Border(left: BorderSide(color: fg.withValues(alpha: 0.6), width: 3)),
                  ),
                  child: Text(b['text'] as String? ?? '', style: Tokens.body.style.copyWith(color: fg.withValues(alpha: 0.8))),
                ),
                'link' => GestureDetector(
                  onTap: () => openCardLink(context, b['url'] as String? ?? ''),
                  child: Text(
                    b['text'] as String? ?? '',
                    style: Tokens.body.style.copyWith(color: fg, decoration: TextDecoration.underline, decorationColor: fg),
                  ),
                ),
                _ => plain(b['text'] as String? ?? ''),
              },
            ),
        ];
      case 'lottery':
        final joined = c.mine == 'in';
        final n = c.counts['in'] ?? 0;
        final ends = c.endsAt;
        final meWon = c.won || c.winners.contains(s.backend.userId);
        return [
          kindLabel(CupertinoIcons.gift, l.cardLottery),
          title(c.text('prize')),
          small(l.lotteryWinnersN(c.data['winners'] is int ? c.data['winners'] as int : 1)),
          if (c.text('note').isNotEmpty) small(c.text('note')),
          if (ends != null && !closed) small(l.lotteryEndsAt(DateFormat.MMMd(lang).add_jm().format(ends))),
          SizedBox(height: Tokens.space[1]),
          if (closed) ...[
            small(c.closed ? l.cardEnded : l.cardEnded, key: const Key('card-closed')),
            if (meWon)
              Text(
                l.lotteryWon,
                key: const Key('lottery-won'),
                style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w600),
              ),
            if (c.closed && (c.counts['won'] ?? c.winners.length) == 0) small(l.lotteryNoWinner),
            if (c.winners.isNotEmpty) small(c.winners.map(displayId).join(', '), key: const Key('lottery-winners-list')),
          ] else
            Row(
              children: [
                Expanded(
                  child: pill(
                    'lottery-join',
                    joined ? l.lotteryLeave : l.lotteryJoin,
                    on: joined,
                    onTap: mine ? null : () => run(() => s.backend.answerCard(widget.roomId, widget.msg.id, joined ? null : 'in')),
                  ),
                ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: small(l.lotteryJoined(n), key: const Key('lottery-count')),
          ),
          if (mine && !c.closed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: pill(
                'lottery-draw',
                l.lotteryDraw,
                onTap: () async {
                  if (!await confirm(l.lotteryDrawAsk, l.lotteryDrawInfo, l.lotteryDraw)) return;
                  await run(() => s.backend.closeCard(widget.roomId, widget.msg.id));
                },
              ),
            ),
        ];
      case 'form':
        final sent = c.mine != null;
        final qs = c.listOf('questions');
        return [
          kindLabel(CupertinoIcons.doc_text, l.cardForm),
          title(c.text('title')),
          small(l.formQuestionsN(qs.length)),
          SizedBox(height: Tokens.space[1]),
          if (closed)
            small(l.cardEnded, key: const Key('card-closed'))
          else if (!mine)
            pill(
              'form-fill',
              sent ? l.formSent : l.formFill,
              on: sent,
              onTap: () async {
                final done = await openSheet<bool>(context, (_) => FormFillPage(roomId: widget.roomId, msg: widget.msg));
                if (done == true) await widget.onChanged();
              },
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: small(l.formSentN(c.counts['sent'] ?? 0), key: const Key('form-count')),
          ),
          if (mine) ...makerTools(l),
        ];
      default:
        final a = c.mine;
        return [
          kindLabel(CupertinoIcons.heart_circle, l.cardCheckin),
          plain(c.text('text')),
          SizedBox(height: Tokens.space[1]),
          if (closed) small(l.cardEnded, key: const Key('card-closed')),
          Row(
            children: [
              Expanded(
                child: pill(
                  'checkin-ok',
                  '${l.checkinOk} ${c.counts['ok'] ?? 0}',
                  on: a == 'ok',
                  onTap: closed ? null : () => run(() => s.backend.answerCard(widget.roomId, widget.msg.id, a == 'ok' ? null : 'ok')),
                ),
              ),
              Expanded(
                child: pill(
                  'checkin-help',
                  '${l.checkinHelp} ${c.counts['help'] ?? 0}',
                  on: a == 'help',
                  onTap: closed ? null : () => run(() => s.backend.answerCard(widget.roomId, widget.msg.id, a == 'help' ? null : 'help')),
                ),
              ),
            ],
          ),
          if (mine) ...makerTools(l),
        ];
    }
  }

  List<Widget> makerTools(L l) {
    final s = AppScope.of(context);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(child: answersButton()),
            if (!c.closed)
              Expanded(
                child: pill(
                  'card-close',
                  l.cardClose,
                  onTap: () async {
                    if (!await confirm(l.cardCloseAsk, l.cardCloseInfo, l.cardClose)) return;
                    await run(() => s.backend.closeCard(widget.roomId, widget.msg.id).then((_) {}));
                  },
                ),
              ),
          ],
        ),
      ),
    ];
  }

  Future<void> showGuide(String label, String text) => paneNav(context).push(
    IosPageRoute(
      builder: (ctx) {
        final p = paletteOf(ctx);
        return CupertinoPageScaffold(
          backgroundColor: p.background,
          navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(label), backgroundColor: p.background, border: null),
          child: SafeArea(
            child: ListView(
              children: [
                IosSection(
                  hasLeading: false,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(Tokens.space[3]),
                      child: Text(
                        text,
                        key: const Key('guide-text'),
                        style: Tokens.body.style.copyWith(color: p.label),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 250),
      child: Column(
        key: Key('card-${widget.msg.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...body(l),
          Align(alignment: Alignment.centerRight, child: widget.meta),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filling a form

class FormFillPage extends StatefulWidget {
  const FormFillPage({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  State<FormFillPage> createState() => _FormFillPageState();
}

class _FormFillPageState extends State<FormFillPage> {
  late final qs = widget.msg.card!.listOf('questions');
  late final fields = [for (final _ in qs) TextEditingController()];
  late final picks = List<String?>.filled(qs.length, null);
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // Earlier answers from this phone, to change them.
    final m = widget.msg.card!.mine;
    if (m is List) {
      for (var i = 0; i < qs.length && i < m.length; i++) {
        if (qs[i]['type'] == 'choice') {
          picks[i] = m[i] is String ? m[i] as String : null;
        } else {
          fields[i].text = m[i] is String ? m[i] as String : '';
        }
      }
    }
  }

  @override
  void dispose() {
    for (final f in fields) {
      f.dispose();
    }
    super.dispose();
  }

  List<String> get answers => [for (var i = 0; i < qs.length; i++) qs[i]['type'] == 'choice' ? (picks[i] ?? '') : fields[i].text.trim()];

  Future<void> send() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await AppScope.read(context).backend.answerCard(widget.roomId, widget.msg.id, answers);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => error = L.of(context).saveFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ready = answers.any((a) => a.isNotEmpty) && !busy;
    return _EditorScaffold(
      title: widget.msg.card!.text('title'),
      ready: ready,
      onSend: send,
      error: error,
      children: [
        for (final (i, q) in qs.indexed)
          IosSection(
            hasLeading: false,
            header: sectionHeader(context, q['q'] as String? ?? ''),
            children: [
              if (q['type'] == 'choice')
                for (final (j, o) in (q['options'] is List ? q['options'] as List : const []).indexed)
                  GestureDetector(
                    key: Key('fill-$i-$j'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => picks[i] = picks[i] == o ? null : o as String),
                    child: _row(
                      context,
                      '$o',
                      picks[i] == o ? Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIcon, color: p.accent) : const SizedBox(width: 22),
                    ),
                  )
              else
                _field(context, fields[i], key: 'fill-$i', hint: l.formAnswerHint, max: 1000, lines: 1, onChanged: (_) => setState(() {})),
            ],
          ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Text(l.formFillInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Answers (maker only, read from this phone)

class CardAnswersPage extends StatefulWidget {
  const CardAnswersPage({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;

  @override
  State<CardAnswersPage> createState() => _CardAnswersPageState();
}

class _CardAnswersPageState extends State<CardAnswersPage> {
  List<CardAnswer>? list;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (list != null) return;
    list = const [];
    AppScope.read(context).backend.cardAnswers(widget.roomId, widget.msg.id).then((x) {
      if (mounted) setState(() => list = x);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final c = widget.msg.card!;
    final qs = c.listOf('questions');
    String name(String u) => aliasOf(s, u).isEmpty ? displayId(u) : aliasOf(s, u);
    final rows = [...?list];
    // Check-in: people who need help first.
    if (c.kind == 'checkin') rows.sort((a, b) => (a.answer == 'help' ? 0 : 1).compareTo(b.answer == 'help' ? 0 : 1));
    return SettingsScaffoldLite(
      title: l.cardAnswers,
      children: [
        if (rows.isEmpty)
          Padding(
            padding: EdgeInsets.all(Tokens.space[5]),
            child: Center(
              child: Text(
                l.cardNoAnswers,
                key: const Key('answers-empty'),
                style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
              ),
            ),
          ),
        if (c.kind != 'form' && rows.isNotEmpty)
          IosSection(
            children: [
              for (final a in rows)
                IosTile(
                  key: Key('answer-${a.user}'),
                  leading: Avatar(name: name(a.user), size: 32),
                  title: Text(name(a.user)),
                  additionalInfo: Text(switch (a.answer) {
                    'ok' => l.checkinOk,
                    'help' => l.checkinHelp,
                    _ => l.lotteryJoin,
                  }, style: TextStyle(color: a.answer == 'help' ? Palette.tileRed : p.secondaryLabel)),
                ),
            ],
          ),
        if (c.kind == 'form')
          for (final a in rows)
            IosSection(
              hasLeading: false,
              header: sectionHeader(context, name(a.user)),
              children: [
                for (final (i, q) in qs.indexed)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['q'] as String? ?? '', style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                        const SizedBox(height: Tokens.nameToSub),
                        Text(
                          a.answer is List && i < (a.answer as List).length ? '${(a.answer as List)[i]}' : '',
                          key: Key('answer-${a.user}-$i'),
                          style: Tokens.body.style.copyWith(color: p.label),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        Padding(
          padding: EdgeInsets.fromLTRB(32, Tokens.space[2], 32, 0),
          child: Text(l.cardAnswersInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
        ),
      ],
    );
  }
}

/// A plain sub-page with a back button (same look as settings pages).
class SettingsScaffoldLite extends StatelessWidget {
  const SettingsScaffoldLite({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(title), backgroundColor: p.background, border: null),
      child: SafeArea(child: ListView(children: children)),
    );
  }
}
