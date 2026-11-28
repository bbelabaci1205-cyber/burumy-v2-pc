// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// AI 편집기 (TelegramTips 561) and 내 말투 (569), on this phone's own AI.
//
// Layout from Telegram iOS's AI Editor, sizes iOS 27:
// - floating sheet 10 pt from the edges, 30 pt corners (as IosActionSheet),
//   grabber 36x5, header 56 with the 44 round X left, 17 semibold title,
//   44 round "?" right;
// - three tabs 56 tall in a white 26-corner card, the chosen one on a soft
//   grey pill (iOS 27 tab bar), 22 icon over 11 label;
// - style chips 60 wide: 28 emoji over 11 label, chosen = grey 16-corner tile;
// - text card white, 26 corners, 16 inside, 13 grey label, 17 text,
//   changed words with an accent underline, copy button bottom right;
// - "적용" 52 accent capsule + 52 accent send circle with the Burumy mark,
//   16 from the sides, 8 apart.
import 'dart:async';

import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../brand/mark.dart';
import '../core/ai_local.dart';
import '../core/ai_styles.dart';
import '../core/app_state.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';
import 'ai_age_ui.dart';

/// What the editor gives back: the new text, and whether to send it now.
typedef AiEditorResult = ({String text, bool send});

const _prefStyles = 'ai_styles';
const _prefTab = 'ai_tab';

/// My own styles (newest first).
List<AiStyle> myStyles(AppState s) => AiStyles.mine(s.pref(_prefStyles, ''));

Future<void> saveMyStyles(AppState s, List<AiStyle> list) => s.setPref(_prefStyles, AiStyles.save(list));

/// The name a built-in style shows.
String styleName(L l, AiStyle s) => !s.builtIn
    ? s.name
    : switch (s.id) {
        'formal' => l.aiStyleFormal,
        'short' => l.aiStyleShort,
        'friendly' => l.aiStyleFriendly,
        'work' => l.aiStyleWork,
        'historic' => l.aiStyleHistoric,
        _ => l.aiStyleZen,
      };

/// Language names in the app's language.
String languageName(BuildContext context, String code) {
  final l = L.of(context);
  return switch (code) {
    'ko' => l.aiLangKo,
    'en' => l.aiLangEn,
    'ja' => l.aiLangJa,
    'zh' => l.aiLangZh,
    'es' => l.aiLangEs,
    'vi' => l.aiLangVi,
    'ru' => l.aiLangRu,
    _ => code,
  };
}

/// Whether the composer should offer the AI button for [text] in a field
/// [width] wide: the AI Editor is on, the phone has AI, and the message is
/// longer than three lines (Telegram 561).
bool showAiButton(AppState s, String text, double width) {
  if (!s.on('ai_editor', fallback: true) || LocalAi.known != AiStatus.ready) return false;
  if (text.trim().isEmpty) return false;
  final tp = TextPainter(
    text: TextSpan(text: text, style: Tokens.body.style),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width < 80 ? 80 : width);
  final lines = tp.computeLineMetrics().length;
  tp.dispose();
  return lines > 3;
}

/// Opens the AI Editor for [text]. Null when closed without a choice.
Future<AiEditorResult?> openAiEditor(BuildContext context, String text) => showCupertinoModalPopup<AiEditorResult>(
  context: context,
  useRootNavigator: !Wide.on,
  builder: (_) => AiEditorSheet(text: text),
);

enum AiTab { translate, style, fix }

class AiEditorSheet extends StatefulWidget {
  const AiEditorSheet({super.key, required this.text});
  final String text;

  @override
  State<AiEditorSheet> createState() => _AiEditorSheetState();
}

class _AiEditorSheetState extends State<AiEditorSheet> {
  late AiTab tab;
  AiStyle? style;
  bool emojify = false;
  late String target;
  late final String source = detectLanguage(widget.text);

  /// Answers already made, by what was asked.
  final done = <String, String>{};
  String? error;
  String? running;
  bool started = false;

  AppState get s => AppScope.read(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (started) return;
    started = true;
    tab = AiTab.values.firstWhere((t) => t.name == s.pref(_prefTab, 'style'), orElse: () => AiTab.style);
    final app = Localizations.localeOf(context).languageCode;
    target = source == app || source.isEmpty ? (app == 'en' ? 'ko' : 'en') : (aiLanguages.containsKey(app) ? app : 'en');
    if (tab != AiTab.style) unawaited(go());
  }

  String? get askKey => switch (tab) {
    AiTab.fix => 'fix',
    AiTab.translate => 'tr:$target',
    AiTab.style => style == null ? null : 'st:${style!.id}:$emojify',
  };

  String? get rules => switch (tab) {
    AiTab.fix => AiStyles.fixRules(),
    AiTab.translate => AiStyles.translateRules(aiLanguages[target]!),
    AiTab.style => style == null ? null : AiStyles.styleRules(style!, emojify: emojify),
  };

  String? get result => askKey == null ? null : done[askKey];

  Future<void> go() async {
    final key = askKey, r = rules;
    if (key == null || r == null || done.containsKey(key)) {
      setState(() => error = null);
      return;
    }
    final l = L.of(context);
    if (widget.text.runes.length > AiStyles.maxText) {
      setState(() => error = l.aiTooLong(AiStyles.maxText));
      return;
    }
    setState(() {
      error = null;
      running = key;
    });
    try {
      final out = await LocalAi.run(rules: r, text: widget.text);
      if (AiStyles.badOutput(widget.text, out)) throw const AiError('failed');
      done[key] = out;
    } on AiError catch (e) {
      if (running == key) {
        error = switch (e.code) {
          'refused' => l.aiRefused,
          'unsupported' => l.aiNotOnPhone,
          _ => LocalAi.known == AiStatus.preparing ? l.aiPreparing : l.aiFailed,
        };
      }
    } catch (_) {
      if (running == key) error = l.aiFailed;
    }
    if (!mounted) return;
    setState(() {
      if (running == key) running = null;
    });
  }

  void pickTab(AiTab t) {
    setState(() => tab = t);
    unawaited(s.setPref(_prefTab, t.name));
    unawaited(go());
  }

  void pickStyle(AiStyle st) {
    setState(() => style = st);
    unawaited(go());
  }

  Future<void> newStyle() async {
    final made = await openSheet<AiStyle>(context, (_) => const NewStylePage());
    if (made != null && mounted) pickStyle(made);
  }

  void finish(bool send) {
    final r = result;
    if (r == null) return;
    Navigator.pop<AiEditorResult>(context, (text: r, send: send));
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet(), scrollbars: false),
      child: sheet(context),
    );
  }

  Widget sheet(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final mine = myStyles(AppScope.of(context));
    final styles = [...mine, ...AiStyles.builtIns];
    final busy = running != null && running == askKey;
    final r = result;
    final fixNothing = tab == AiTab.fix && r != null && r.trim() == widget.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(IosActionSheet.radius),
        child: ColoredBox(
          key: const Key('ai-editor'),
          color: p.background,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(Tokens.capsule)),
                    ),
                  ),
                ),
                SizedBox(
                  height: Tokens.sheetHeader,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('ai-close'),
                          onTap: () => Navigator.pop(context),
                          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
                        ),
                      ),
                      Text(
                        l.aiEditor,
                        style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                      ),
                      Positioned(
                        right: Tokens.space[2],
                        child: GlassCircle(
                          key: const Key('ai-help'),
                          onTap: () => showStoryToast(context, l.aiHelp),
                          child: GlassCircle.icon(context, CupertinoIcons.question_circle, size: Tokens.closeIcon),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  child: _Tabs(
                    value: tab,
                    onPick: pickTab,
                    items: [
                      (AiTab.translate, CupertinoIcons.globe, l.aiTabTranslate),
                      (AiTab.style, CupertinoIcons.wand_stars, l.aiTabStyle),
                      (AiTab.fix, CupertinoIcons.textformat_abc_dottedunderline, l.aiTabFix),
                    ],
                  ),
                ),
                SizedBox(height: Tokens.space[2]),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  child: Container(
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (tab == AiTab.style) ...[
                          SizedBox(height: Tokens.space[2]),
                          SizedBox(
                            height: 64,
                            child: ListView(
                              // PC app / web: a mouse can drag the row too.
                              key: const Key('ai-styles'),
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                              children: [
                                for (final st in styles)
                                  _StyleChip(
                                    key: Key('ai-style-${st.id}'),
                                    emoji: st.emoji,
                                    label: styleName(l, st),
                                    on: style?.id == st.id,
                                    onTap: () => pickStyle(st),
                                  ),
                                _StyleChip(key: const Key('ai-style-new'), icon: CupertinoIcons.plus, label: l.create, onTap: newStyle),
                              ],
                            ),
                          ),
                          Container(
                            height: 1 / MediaQuery.devicePixelRatioOf(context),
                            margin: EdgeInsets.only(left: Tokens.space[3], top: Tokens.space[1]),
                            color: p.separator,
                          ),
                        ],
                        if (tab == AiTab.translate) ...[
                          SizedBox(height: Tokens.space[2]),
                          SizedBox(
                            height: 34,
                            child: ListView(
                              // PC app / web: a mouse can drag the row too.
                              key: const Key('ai-langs'),
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                              children: [
                                for (final code in aiLanguages.keys)
                                  if (code != source)
                                    Padding(
                                      padding: EdgeInsets.only(right: Tokens.space[1]),
                                      child: _Capsule(
                                        key: Key('ai-lang-$code'),
                                        text: languageName(context, code),
                                        on: code == target,
                                        onTap: () {
                                          setState(() => target = code);
                                          unawaited(go());
                                        },
                                      ),
                                    ),
                              ],
                            ),
                          ),
                          SizedBox(height: Tokens.space[2]),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                            child: Text.rich(
                              key: const Key('ai-from'),
                              TextSpan(
                                children: [
                                  TextSpan(text: l.aiFromLang('').trimRight()),
                                  const TextSpan(text: ' '),
                                  TextSpan(
                                    text: source.isEmpty ? '—' : languageName(context, source),
                                    style: TextStyle(color: p.accent),
                                  ),
                                ],
                              ),
                              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[0], Tokens.space[3], 0),
                            child: Text(
                              widget.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.preview.style.copyWith(color: p.label),
                            ),
                          ),
                          Container(
                            height: 1 / MediaQuery.devicePixelRatioOf(context),
                            margin: EdgeInsets.only(left: Tokens.space[3], top: Tokens.space[2]),
                            color: p.separator,
                          ),
                        ],
                        Padding(
                          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[2], 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r == null && tab == AiTab.style ? l.aiOriginal : l.aiResult,
                                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                ),
                              ),
                              if (tab == AiTab.style)
                                GestureDetector(
                                  key: const Key('ai-emojify'),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() => emojify = !emojify);
                                    unawaited(go());
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[0]),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          emojify ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                                          size: 18,
                                          color: emojify ? p.accent : p.chevron,
                                        ),
                                        SizedBox(width: Tokens.space[0]),
                                        Text(l.aiEmojify, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 88, maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], 0),
                            child: busy
                                ? const _Thinking(key: Key('ai-thinking'))
                                : error != null
                                ? Text(
                                    error!,
                                    key: const Key('ai-error'),
                                    style: Tokens.body.style.copyWith(color: Palette.tileRed),
                                  )
                                : r == null
                                ? Text(
                                    widget.text,
                                    key: const Key('ai-original'),
                                    style: Tokens.body.style.copyWith(color: p.label),
                                  )
                                : fixNothing
                                ? Text(
                                    l.aiNoChange,
                                    key: const Key('ai-nochange'),
                                    style: Tokens.body.style.copyWith(color: p.secondaryLabel),
                                  )
                                : _Changed(key: const Key('ai-result'), before: widget.text, after: r, underline: tab == AiTab.fix),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            key: const Key('ai-copy'),
                            padding: EdgeInsets.all(Tokens.space[2]),
                            minimumSize: const Size(40, 40),
                            onPressed: r == null || busy
                                ? null
                                : () async {
                                    await Clipboard.setData(ClipboardData(text: r));
                                    if (context.mounted) showStoryToast(context, l.copied);
                                  },
                            child: Icon(CupertinoIcons.doc_on_doc, size: 20, color: r == null || busy ? p.chevron : p.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[3]),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Filled(
                          key: const Key('ai-apply'),
                          enabled: r != null && !busy && !fixNothing,
                          onTap: () => finish(false),
                          child: Text(
                            l.aiApply,
                            style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                          ),
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      _Filled(
                        key: const Key('ai-send'),
                        enabled: r != null && !busy && !fixNothing,
                        width: Tokens.settingsRow,
                        onTap: () => finish(true),
                        child: BurumyMark(color: p.onAccent, size: 28),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Accent capsule (or circle with [width]) that dims while it can't be used.
class _Filled extends StatelessWidget {
  const _Filled({super.key, required this.enabled, required this.onTap, required this.child, this.width});
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: Tokens.settingsRow,
        width: width,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: enabled ? p.accent : p.accent.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: child,
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.value, required this.onPick, required this.items});
  final AiTab value;
  final ValueChanged<AiTab> onPick;
  final List<(AiTab, IconData, String)> items;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
      child: Row(
        children: [
          for (final (t, icon, label) in items)
            Expanded(
              child: GestureDetector(
                key: Key('ai-tab-${t.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onPick(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: t == value ? p.label.withValues(alpha: p.dark ? 0.14 : 0.06) : const Color(0x00000000),
                    borderRadius: BorderRadius.circular(Tokens.radius[3]),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: Tokens.listIcon, color: p.label),
                      const SizedBox(height: 2),
                      Text(label, style: Tokens.tabLabel.style.copyWith(color: p.label, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StyleChip extends StatelessWidget {
  const _StyleChip({super.key, this.emoji, this.icon, required this.label, this.on = false, required this.onTap});
  final String? emoji;
  final IconData? icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: on ? p.label.withValues(alpha: p.dark ? 0.14 : 0.06) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(Tokens.radius[2]),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: Center(
                child: emoji != null
                    ? Text(emoji!, style: const TextStyle(fontSize: 26, height: 1.1, fontFamilyFallback: Tokens.emojiFallback))
                    : Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.12)),
                        child: Icon(icon, size: 18, color: p.accent),
                      ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.tabLabel.style.copyWith(color: icon != null ? p.accent : p.label, fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _Capsule extends StatelessWidget {
  const _Capsule({super.key, required this.text, required this.on, required this.onTap});
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? p.accent : p.label.withValues(alpha: p.dark ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(Tokens.capsule),
        ),
        child: Text(text, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
      ),
    );
  }
}

/// The result, with the words that changed underlined (고치기) or plain.
class _Changed extends StatelessWidget {
  const _Changed({super.key, required this.before, required this.after, required this.underline});
  final String before, after;
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final base = Tokens.body.style.copyWith(color: p.label);
    if (!underline) return Text(after, style: base);
    return Text.rich(
      TextSpan(
        children: [
          for (final part in wordDiff(before, after))
            TextSpan(
              text: part.text,
              style: part.changed
                  ? TextStyle(
                      decoration: TextDecoration.underline,
                      decorationColor: p.accent,
                      decorationThickness: 2,
                      decorationStyle: TextDecorationStyle.wavy,
                    )
                  : null,
            ),
        ],
      ),
      style: base,
    );
  }
}

/// Grey lines that softly pulse while the phone's AI thinks.
class _Thinking extends StatefulWidget {
  const _Thinking({super.key});
  @override
  State<_Thinking> createState() => _ThinkingState();
}

class _ThinkingState extends State<_Thinking> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final w in const [1.0, 0.86, 0.6])
            FractionallySizedBox(
              widthFactor: w,
              child: Container(
                height: 10,
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                decoration: BoxDecoration(
                  color: p.label.withValues(alpha: 0.06 + 0.08 * c.value),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- 새 말투

/// Emoji offered as a style's icon.
const styleIcons = [
  '👽',
  '🏴‍☠️',
  '🎭',
  '🤖',
  '👑',
  '🧙',
  '🦄',
  '🐱',
  '🐶',
  '🐻',
  '🦊',
  '🐸',
  '🌸',
  '🍀',
  '🔥',
  '⭐',
  '🌙',
  '☀️',
  '🌊',
  '🎵',
  '🎤',
  '📚',
  '✏️',
  '💌',
  '😎',
  '🤓',
  '🥰',
  '😇',
  '🤠',
  '🥷',
  '🧑‍🍳',
  '👵',
  '👶',
  '🧸',
  '🍜',
  '☕',
];

/// "새 말투": icon, name, instructions. Returns the saved style.
class NewStylePage extends StatefulWidget {
  const NewStylePage({super.key});
  @override
  State<NewStylePage> createState() => _NewStylePageState();
}

class _NewStylePageState extends State<NewStylePage> {
  final name = TextEditingController();
  final rules = TextEditingController();
  String emoji = '';
  String? problem;

  @override
  void dispose() {
    name.dispose();
    rules.dispose();
    super.dispose();
  }

  Future<void> pickIcon() async {
    final l = L.of(context);
    final got = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) {
        final p = paletteOf(c);
        final bottom = MediaQuery.paddingOf(c).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(IosActionSheet.radius),
            child: Container(
              key: const Key('style-icons'),
              color: p.card,
              padding: EdgeInsets.all(Tokens.space[3]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l.aiStyleIconPick, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  SizedBox(height: Tokens.space[2]),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final e in styleIcons)
                        GestureDetector(
                          key: Key('style-icon-$e'),
                          onTap: () => Navigator.pop(c, e),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: Center(
                              child: Text(e, style: const TextStyle(fontSize: 30, fontFamilyFallback: Tokens.emojiFallback)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (got != null) setState(() => emoji = got);
  }

  Future<void> create() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final st = AiStyle(id: AiStyles.newId(name.text.trim(), rules.text.trim()), emoji: emoji, name: name.text.trim(), rules: rules.text.trim());
    final why = AiStyles.check(st);
    if (why != null) {
      setState(
        () => problem = switch (why) {
          'empty' => l.aiStyleEmpty,
          'long' => l.aiStyleLong(AiStyles.maxName, AiStyles.maxRules),
          _ => l.aiStyleBlocked,
        },
      );
      return;
    }
    await saveMyStyles(s, AiStyles.add(myStyles(s), st));
    if (mounted) Navigator.pop(context, st);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key key, TextEditingController c, String hint, {int lines = 1, int? max}) => Container(
      margin: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
      child: CupertinoTextField(
        key: key,
        controller: c,
        placeholder: hint,
        minLines: lines,
        maxLines: lines == 1 ? 1 : 8,
        maxLength: max,
        onChanged: (_) => setState(() => problem = null),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: (Tokens.settingsRow - Tokens.body.lineHeight) / 2),
        style: Tokens.body.style.copyWith(color: p.label),
        placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
        decoration: const BoxDecoration(),
      ),
    );
    return WidePage(
      child: CupertinoPageScaffold(
        key: const Key('new-style'),
        backgroundColor: p.background,
        navigationBar: GlassTopBar(title: l.aiStyleNew, leading: const [GlassBack(close: true)], tint: p.background),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height + Tokens.space[3]),
                children: [
                  Center(
                    child: GestureDetector(
                      key: const Key('style-icon'),
                      onTap: pickIcon,
                      child: Container(
                        width: Tokens.infoAvatar,
                        height: Tokens.infoAvatar,
                        decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: emoji.isEmpty
                            ? Icon(CupertinoIcons.smiley, size: 40, color: p.chevron)
                            : Text(emoji, style: const TextStyle(fontSize: 52, fontFamilyFallback: Tokens.emojiFallback)),
                      ),
                    ),
                  ),
                  SizedBox(height: Tokens.space[4]),
                  field(const Key('style-name'), name, l.aiStyleNameHint, max: AiStyles.maxName),
                  SizedBox(height: Tokens.space[3]),
                  field(const Key('style-rules'), rules, l.aiStyleRulesHint, lines: 4, max: AiStyles.maxRules),
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.cardToFooter, Tokens.space[4], 0),
                    child: Text(
                      problem ?? l.aiStyleSaveInfo,
                      key: const Key('style-note'),
                      style: Tokens.caption.style.copyWith(color: problem != null ? Palette.tileRed : p.secondaryLabel),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], MediaQuery.paddingOf(context).bottom + Tokens.space[2]),
              child: _Filled(
                key: const Key('style-create'),
                enabled: true,
                onTap: create,
                child: Text(
                  l.create,
                  style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ 말투 추가

/// Opens the "add this style" page for a shared style.
Future<void> openStyleLink(BuildContext context, AiStyle st) async {
  if (!await aiAgeOk(context) || !context.mounted) return;
  await openSheet<void>(context, (_) => AddStylePage(style: st));
}

/// A shared style: icon, name, an example made on this phone, 말투 추가.
class AddStylePage extends StatefulWidget {
  const AddStylePage({super.key, required this.style});
  final AiStyle style;

  @override
  State<AddStylePage> createState() => _AddStylePageState();
}

class _AddStylePageState extends State<AddStylePage> {
  int at = 0;
  String? after;
  bool noAi = false;
  bool started = false;

  List<String> get examples {
    final l = L.of(context);
    return [l.aiExample1, l.aiExample2, l.aiExample3];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!started) {
      started = true;
      unawaited(make());
    }
  }

  Future<void> make() async {
    setState(() => after = null);
    if (!await LocalAi.available()) {
      if (mounted) setState(() => noAi = true);
      return;
    }
    final before = examples[at];
    try {
      final out = await LocalAi.run(rules: AiStyles.styleRules(widget.style), text: before);
      if (mounted && examples[at] == before) setState(() => after = AiStyles.badOutput(before, out) ? '—' : out);
    } catch (_) {
      if (mounted) setState(() => after = '—');
    }
  }

  Future<void> add() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final st = widget.style;
    await saveMyStyles(s, AiStyles.add(myStyles(s), st));
    if (!mounted) return;
    Navigator.pop(context);
    showStoryToast(context, '${l.aiStyleAdded(st.name)}\n${l.aiStyleAddedHint}');
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final st = widget.style;
    final have = myStyles(AppScope.of(context)).any((x) => x.id == st.id);
    return WidePage(
      child: CupertinoPageScaffold(
        key: const Key('add-style'),
        backgroundColor: p.background,
        navigationBar: GlassTopBar(leading: const [GlassBack(close: true)], tint: p.background),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
                children: [
                  Center(
                    child: Text(st.emoji, style: const TextStyle(fontSize: 64, fontFamilyFallback: Tokens.emojiFallback)),
                  ),
                  SizedBox(height: Tokens.space[1]),
                  Text(
                    st.name,
                    key: const Key('add-style-name'),
                    textAlign: TextAlign.center,
                    style: Tokens.headerTitle.style.copyWith(color: p.label),
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(
                    l.aiStyleCard,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                  SizedBox(height: Tokens.space[4]),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                    child: Row(
                      children: [
                        Expanded(child: sectionHeader(context, l.aiStyleExample)),
                        if (!noAi)
                          GestureDetector(
                            key: const Key('add-style-another'),
                            onTap: () {
                              setState(() => at = (at + 1) % examples.length);
                              unawaited(make());
                            },
                            child: Row(
                              children: [
                                Icon(CupertinoIcons.arrow_clockwise, size: 13, color: p.accent),
                                const SizedBox(width: 3),
                                Text(l.aiStyleAnother, style: Tokens.caption.style.copyWith(color: p.accent)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: Tokens.groupTitleToCard),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    padding: EdgeInsets.all(Tokens.space[3]),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[3])),
                    child: noAi
                        ? Text(
                            l.aiStyleNoAi,
                            key: const Key('add-style-noai'),
                            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.aiStyleBefore, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                              SizedBox(height: Tokens.space[0]),
                              Text(examples[at], style: Tokens.body.style.copyWith(color: p.label)),
                              Container(
                                height: 1 / MediaQuery.devicePixelRatioOf(context),
                                margin: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                                color: p.separator,
                              ),
                              Text(l.aiStyleAfter, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                              SizedBox(height: Tokens.space[0]),
                              after == null
                                  ? const _Thinking()
                                  : Text(
                                      after!,
                                      key: const Key('add-style-after'),
                                      style: Tokens.body.style.copyWith(color: p.label),
                                    ),
                            ],
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.cardToFooter, Tokens.space[4], 0),
                    child: sectionFooter(context, '${l.aiStyleAddInfo} ${l.aiStyleSendInfo}'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[2], Tokens.space[3], MediaQuery.paddingOf(context).bottom + Tokens.space[2]),
              child: _Filled(
                key: const Key('add-style-add'),
                enabled: !have,
                onTap: add,
                child: Text(
                  have ? l.aiStyleHave : l.aiStyleAdd,
                  style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: Tokens.semi),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- 말투 카드 (in chat)

/// The card under a message that carries a style link. The link (and so
/// the style) is inside the encrypted message; nothing is fetched.
class StyleLinkCard extends StatelessWidget {
  const StyleLinkCard({super.key, required this.style, required this.mine});
  final AiStyle style;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final fg = mine ? p.onAccent : p.label;
    final bar = mine ? p.onAccent : p.accent;
    return GestureDetector(
      key: const Key('style-card'),
      behavior: HitTestBehavior.opaque,
      onTap: () => openStyleLink(context, style),
      child: Container(
        margin: EdgeInsets.only(top: Tokens.space[1]),
        padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
        decoration: BoxDecoration(
          color: bar.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Tokens.radius[1]),
          border: Border(left: BorderSide(color: bar, width: 3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l.aiStyleCard,
                    style: Tokens.caption.style.copyWith(color: bar, fontWeight: Tokens.semi),
                  ),
                  Text(
                    style.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    style.rules,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75)),
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(
                    l.aiStyleCardOpen,
                    style: Tokens.caption.style.copyWith(color: bar, fontWeight: Tokens.semi),
                  ),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[1]),
            Text(style.emoji, style: const TextStyle(fontSize: 34, fontFamilyFallback: Tokens.emojiFallback)),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------- Settings > 내 말투

class MyStylesPage extends StatelessWidget {
  const MyStylesPage({super.key});

  Future<void> rowMenu(BuildContext context, AiStyle st) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final what = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) => IosActionSheet(
        title: Text('${st.emoji} ${st.name}'),
        message: Text(l.aiStyleSendInfo),
        actions: [
          CupertinoActionSheetAction(key: const Key('style-copy-link'), onPressed: () => Navigator.pop(c, 'copy'), child: Text(l.aiStyleCopyLink)),
          CupertinoActionSheetAction(
            key: const Key('style-delete'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(l.delete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!context.mounted) return;
    if (what == 'copy') {
      await Clipboard.setData(ClipboardData(text: AiStyles.link(st)));
      if (context.mounted) showStoryToast(context, l.copied);
    } else if (what == 'delete') {
      await saveMyStyles(s, myStyles(s).where((x) => x.id != st.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = myStyles(AppScope.of(context));
    return SettingsScaffold(
      key: const Key('my-styles'),
      title: l.aiMyStyles,
      children: [
        group(context, footer: list.isEmpty ? l.aiMyStylesEmpty : l.aiStyleSendInfo, [
          IosTile(
            key: const Key('my-styles-new'),
            leading: Icon(CupertinoIcons.add, color: p.accent),
            title: Text(l.aiStyleNew, style: TextStyle(color: p.accent)),
            onTap: () => paneNav(context).push(IosPageRoute<AiStyle>(builder: (_) => const NewStylePage())),
          ),
          for (final st in list)
            IosTile(
              key: Key('my-style-${st.id}'),
              leading: SizedBox(
                width: 28,
                child: Center(
                  child: Text(st.emoji, style: const TextStyle(fontSize: 22, fontFamilyFallback: Tokens.emojiFallback)),
                ),
              ),
              title: Text(st.name),
              subtitle: Text(st.rules, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const IosChevron(),
              onTap: () => rowMenu(context, st),
            ),
        ]),
      ],
    );
  }
}
