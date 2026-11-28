// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 번역 screens (v1 parity, Telegram layout, iOS 27 sizes):
// - the 번역 sheet from the message menu (original, translation, language
//   switch, copy, 대화 전체 번역 켜기),
// - the "한국어로 번역하기" capsule on top of a chat in another language
//   (tap = whole chat translated in place, ⋯ = other language / don't
//   translate this language / hide in this chat),
// - the language list (one pick, or several for 번역하지 않을 언어),
// - a message's words shown translated while the chat is translated.
// Everything runs through core/translate.dart (on the phone only).
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/translate.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show GlassSheet;
import 'settings_kit.dart';
import 'wide.dart';

/// The language I read (the app's language).
String myLanguage(BuildContext context) => Localizations.localeOf(context).languageCode;

/// A language's name in the app's language ('en' in Korean = 영어).
String langName(BuildContext context, String code) {
  final l = L.of(context);
  return switch (code) {
    'ko' => l.trLang_ko,
    'en' => l.trLang_en,
    'ja' => l.trLang_ja,
    'zh' => l.trLang_zh,
    'es' => l.trLang_es,
    'fr' => l.trLang_fr,
    'de' => l.trLang_de,
    'ru' => l.trLang_ru,
    'pt' => l.trLang_pt,
    'it' => l.trLang_it,
    'vi' => l.trLang_vi,
    'th' => l.trLang_th,
    'id' => l.trLang_id,
    'tr' => l.trLang_tr,
    'ar' => l.trLang_ar,
    'hi' => l.trLang_hi,
    'uk' => l.trLang_uk,
    'pl' => l.trLang_pl,
    'nl' => l.trLang_nl,
    _ => code,
  };
}

/// Languages never offered for translation (always includes mine).
Set<String> skipLanguages(AppState s, String mine) => {
  mine,
  for (final x in s.pref(TrPrefs.skip, '').split(','))
    if (x.isNotEmpty) x,
};

/// What this chat is translated into ('' = not translating).
String chatTranslateTo(AppState s, String roomId) => s.pref(TrPrefs.on(roomId), '');

/// Target for a chat: its own pick, else my language.
String translateTarget(AppState s, String roomId, String mine) {
  final t = s.pref(TrPrefs.to(roomId), '');
  return t.isEmpty ? mine : t;
}

/// Makes sure the phone has the language; asks first (Wi-Fi, ~30 MB).
/// True when translating can go ahead.
Future<bool> ensureLanguage(BuildContext context, String from, String to) async {
  final st = await Translate.status(from, to);
  if (st == TrStatus.ready) return true;
  if (!context.mounted) return false;
  final l = L.of(context);
  if (st == TrStatus.unsupported) {
    trNotice(context, l.trUnsupported);
    return false;
  }
  final need = from == 'en' ? to : from;
  final ok = await showCupertinoModalPopup<bool>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.trDownloadAsk(langName(context, need))),
      message: Text(l.trDownloadInfo),
      actions: [CupertinoActionSheetAction(key: const Key('tr-download'), onPressed: () => Navigator.pop(c, true), child: Text(l.trDownload))],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (ok != true) return false;
  trNotice(context, l.trDownloading);
  final got = await PhoneTranslate.download(from, to);
  if (!got) trNotice(context, l.trDownloadFailed);
  return got;
}

/// A short glass note near the top for 2 seconds (no page of its own).
void trNotice(BuildContext context, String text) {
  if (!context.mounted) return;
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  final p = paletteOf(context);
  late final OverlayEntry e;
  e = OverlayEntry(
    builder: (c) => Positioned(
      left: Tokens.space[3],
      right: Tokens.space[3],
      top: MediaQuery.paddingOf(c).top + 56,
      child: IgnorePointer(
        child: Center(
          child: LiquidGlass(
            key: const Key('tr-notice'),
            radius: Tokens.capsule,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Tokens.caption.style.copyWith(color: p.label),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(e);
  Future<void>.delayed(const Duration(seconds: 2), () {
    if (e.mounted) e.remove();
  });
}

// ---------------------------------------------------------------- sheet

/// The 번역 sheet for one message's words.
Future<void> showTranslateSheet(BuildContext context, {required String text, String? roomId}) => showCupertinoModalPopup<void>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (_) => TranslateSheet(text: text, roomId: roomId),
);

class TranslateSheet extends StatefulWidget {
  const TranslateSheet({super.key, required this.text, this.roomId});
  final String text;
  final String? roomId;
  @override
  State<TranslateSheet> createState() => _TranslateSheetState();
}

class _TranslateSheetState extends State<TranslateSheet> {
  String? from, to, out, error;
  bool busy = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (to != null) return;
    final s = AppScope.of(context);
    final mine = myLanguage(context);
    to = widget.roomId == null ? mine : translateTarget(s, widget.roomId!, mine);
    run();
  }

  Future<void> run() async {
    final l = L.of(context);
    setState(() {
      busy = true;
      error = out = null;
    });
    from ??= await Translate.detect(widget.text) ?? 'en';
    if (!mounted) return;
    if (from == to) {
      setState(() {
        busy = false;
        error = l.trSameLang(langName(context, to!));
      });
      return;
    }
    final ok = await ensureLanguage(context, from!, to!);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        busy = false;
        error = l.trUnsupported;
      });
      return;
    }
    try {
      final got = await Translate.run(widget.text, from: from, to: to!);
      if (mounted) setState(() => out = got);
    } on TrError catch (e) {
      if (mounted) setState(() => error = e.code == 'unsupported' ? l.trUnsupported : l.trFailed);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> pickTarget() async {
    final got = await Navigator.of(context).push<String>(
      IosPageRoute(
        builder: (_) => TrLanguagePage(title: L.of(context).trOtherLang, selected: {to!}),
      ),
    );
    if (got == null || got == to || !mounted) return;
    to = got;
    await run();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final ui = myLanguage(context);
    final s = AppScope.of(context);
    final small = Tokens.caption.style;
    final words = Tokens.body.style.copyWith(color: p.label);
    final room = widget.roomId;
    return GlassSheet(
      title: l.translate,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Original: grey language name, then the words.
                Text(
                  from == null ? '' : langName(context, from!),
                  key: const Key('tr-from'),
                  style: small.copyWith(color: p.secondaryLabel),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(
                  widget.text,
                  key: const Key('tr-original'),
                  style: words.copyWith(color: p.secondaryLabel),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                  child: Container(height: 0.5, color: p.separator),
                ),
                // Translation: accent language name with ⌄ (pick another).
                GestureDetector(
                  key: const Key('tr-to'),
                  behavior: HitTestBehavior.opaque,
                  onTap: pickTarget,
                  child: Row(
                    children: [
                      Text(
                        langName(context, to ?? ui),
                        style: small.copyWith(color: p.accent, fontWeight: Tokens.semi),
                      ),
                      SizedBox(width: Tokens.space[0]),
                      Icon(CupertinoIcons.chevron_down, size: 12, color: p.accent),
                    ],
                  ),
                ),
                SizedBox(height: Tokens.space[0]),
                if (busy && out == null)
                  Row(
                    children: [
                      const CupertinoActivityIndicator(radius: 8),
                      SizedBox(width: Tokens.space[1]),
                      Text(l.trTranslating, style: words.copyWith(color: p.secondaryLabel)),
                    ],
                  )
                else if (error != null)
                  Text(
                    error!,
                    key: const Key('tr-error'),
                    style: words.copyWith(color: p.secondaryLabel),
                  )
                else ...[
                  Text(out ?? '', key: const Key('tr-result'), style: words),
                  if (out != null && TrCredit.google) ...[SizedBox(height: Tokens.space[1]), const GoogleTranslateCredit()],
                ],
                if (kIsWeb) ...[SizedBox(height: Tokens.space[2]), Text(l.trWebDemo, style: small.copyWith(color: p.secondaryLabel))],
                SizedBox(height: Tokens.space[3]),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[3]),
          child: Row(
            children: [
              Expanded(
                child: CapsuleButton(
                  key: const Key('tr-copy'),
                  label: l.copy,
                  filled: false,
                  onTap: out == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: out!));
                          trNotice(context, l.copied);
                          Navigator.pop(context);
                        },
                ),
              ),
              if (room != null && chatTranslateTo(s, room).isEmpty) ...[
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: CapsuleButton(
                    key: const Key('tr-whole-chat'),
                    label: l.trWholeChatOn,
                    onTap: () async {
                      await s.setPref(TrPrefs.hidden(room), '');
                      await s.setPref(TrPrefs.on(room), to ?? ui);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A 50 pt capsule button (iOS 27 sheet buttons; no ripple).
class CapsuleButton extends StatelessWidget {
  const CapsuleButton({super.key, required this.label, required this.onTap, this.filled = true});
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? p.accent.withValues(alpha: on ? 1 : 0.4) : p.label.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Tokens.capsule),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Tokens.body.style.copyWith(color: filled ? p.onAccent : (on ? p.accent : p.secondaryLabel), fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- languages

/// Language list with checkmarks. One pick returns its code; with [multi]
/// every tap toggles and the result is saved by [onToggle].
class TrLanguagePage extends StatelessWidget {
  const TrLanguagePage({super.key, required this.title, required this.selected, this.multi = false, this.onToggle, this.locked = const {}});
  final String title;
  final Set<String> selected;
  final bool multi;
  final void Function(String code, bool on)? onToggle;

  /// Always checked (my own language in 번역하지 않을 언어).
  final Set<String> locked;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // rebuild when settings change
    final ui = myLanguage(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: title,
      children: [
        group(context, [
          for (final code in trLanguages)
            IosTile(
              key: Key('tr-lang-$code'),
              title: Text(langName(context, code)),
              subtitle: ui == 'ko' ? Text(trEnglishNames[code]!) : null,
              trailing: selected.contains(code) || locked.contains(code) ? Icon(CupertinoIcons.check_mark, color: p.accent, size: 20) : null,
              onTap: locked.contains(code)
                  ? null
                  : () {
                      if (!multi) return Navigator.pop(context, code);
                      onToggle?.call(code, !selected.contains(code));
                    },
            ),
        ]),
      ],
    );
  }
}

/// Settings > 언어 > 번역하지 않을 언어 (several; mine always on).
class TrSkipPage extends StatelessWidget {
  const TrSkipPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final mine = myLanguage(context);
    final now = skipLanguages(s, mine);
    return TrLanguagePage(
      title: L.of(context).trSkip,
      selected: now,
      multi: true,
      locked: {mine},
      onToggle: (code, on) {
        final next = {...now}..remove(mine);
        on ? next.add(code) : next.remove(code);
        s.setPref(TrPrefs.skip, next.join(','));
      },
    );
  }
}

/// "영어, 일본어" for the settings row.
String skipSummary(AppState s, BuildContext context) {
  final ui = myLanguage(context);
  return [for (final c in skipLanguages(s, ui)) langName(context, c)].join(', ');
}

// ---------------------------------------------------------------- chat bar

/// The capsule on top of a chat whose messages are mostly in [lang]:
/// "한국어로 번역하기", or "원문 보기" while the chat is translated.
class TranslateBar extends StatelessWidget {
  const TranslateBar({super.key, required this.roomId, required this.lang});
  final String roomId;

  /// The chat's language.
  final String lang;

  Future<void> toggle(BuildContext context) async {
    final s = AppScope.of(context);
    final mine = myLanguage(context);
    if (chatTranslateTo(s, roomId).isNotEmpty) return s.setPref(TrPrefs.on(roomId), '');
    final to = translateTarget(s, roomId, mine);
    if (!await ensureLanguage(context, lang, to)) return;
    await s.setPref(TrPrefs.on(roomId), to);
  }

  Future<void> more(BuildContext context) async {
    final s = AppScope.of(context);
    final l = L.of(context);
    final name = langName(context, lang);
    final ui = myLanguage(context);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          CupertinoActionSheetAction(key: const Key('tr-bar-other'), onPressed: () => Navigator.pop(c, 'other'), child: Text(l.trOtherLang)),
          CupertinoActionSheetAction(key: const Key('tr-bar-skip'), onPressed: () => Navigator.pop(c, 'skip'), child: Text(l.trDontTranslate(name))),
          CupertinoActionSheetAction(key: const Key('tr-bar-hide'), onPressed: () => Navigator.pop(c, 'hide'), child: Text(l.trHideBar)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!context.mounted) return;
    switch (pick) {
      case 'other':
        final to = await Navigator.of(context).push<String>(
          IosPageRoute(
            builder: (_) => TrLanguagePage(title: l.trOtherLang, selected: {translateTarget(s, roomId, ui)}),
          ),
        );
        if (to == null || !context.mounted) return;
        if (!await ensureLanguage(context, lang, to)) return;
        await s.setPref(TrPrefs.to(roomId), to);
        await s.setPref(TrPrefs.on(roomId), to);
      case 'skip':
        final next = skipLanguages(s, ui)
          ..remove(ui)
          ..add(lang);
        await s.setPref(TrPrefs.skip, next.join(','));
        await s.setPref(TrPrefs.on(roomId), '');
      case 'hide':
        await s.setPref(TrPrefs.hidden(roomId), '1');
        await s.setPref(TrPrefs.on(roomId), '');
        trNotice(context, l.trHiddenNote);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = L.of(context);
    final p = paletteOf(context);
    final ui = myLanguage(context);
    final on = chatTranslateTo(s, roomId).isNotEmpty;
    final bar = Padding(
      key: const Key('translate-bar'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: LiquidGlass(
        radius: 24,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const Key('translate-bar-tap'),
                behavior: HitTestBehavior.opaque,
                onTap: () => toggle(context),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: Tokens.closeButton),
                      Icon(CupertinoIcons.globe, size: Tokens.listIconSmall, color: p.accent),
                      SizedBox(width: Tokens.space[1]),
                      Flexible(
                        child: Text(
                          on ? l.trShowOriginal : l.trToLang(langName(context, translateTarget(s, roomId, ui))),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CupertinoButton(
              key: const Key('translate-bar-more'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
              onPressed: () => more(context),
              child: Icon(CupertinoIcons.ellipsis, size: Tokens.listIconSmall, color: p.secondaryLabel),
            ),
            SizedBox(width: Tokens.space[1]),
          ],
        ),
      ),
    );
    // While the chat shows Google's translations (Android), the credit sits
    // right under the bar, above the translated messages.
    if (!on || !TrCredit.google) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        const Padding(padding: EdgeInsets.only(bottom: 4), child: GoogleTranslateCredit(center: true)),
      ],
    );
  }
}

/// "Powered by Google Translate" in small grey text (Google's text
/// attribution style; the words and the "Google Translate" name unchanged).
class GoogleTranslateCredit extends StatelessWidget {
  const GoogleTranslateCredit({super.key, this.center = false});
  final bool center;
  @override
  Widget build(BuildContext context) => Text(
    L.of(context).trPoweredByGoogle,
    key: const Key('tr-google-credit'),
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: Tokens.caption.style.copyWith(color: paletteOf(context).secondaryLabel),
  );
}

// ---------------------------------------------------------------- bubble

/// A message's words, translated while its chat is translated (shows the
/// original until the translation is ready).
class TranslatedWords extends StatefulWidget {
  const TranslatedWords({super.key, required this.text, required this.to, required this.builder});
  final String text;
  final String to;
  final Widget Function(String shown) builder;
  @override
  State<TranslatedWords> createState() => _TranslatedWordsState();
}

class _TranslatedWordsState extends State<TranslatedWords> {
  String? shown;

  @override
  void initState() {
    super.initState();
    start();
  }

  @override
  void didUpdateWidget(TranslatedWords old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.to != widget.to) start();
  }

  void start() {
    shown = Translate.cached(widget.text, widget.to);
    if (shown != null) return;
    final ask = (widget.text, widget.to);
    Translate.run(widget.text, to: widget.to).then((v) {
      if (mounted && ask == (widget.text, widget.to)) setState(() => shown = v);
    }, onError: (_) {});
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: Key(shown == null ? 'tr-waiting' : 'tr-shown'), child: widget.builder(shown ?? widget.text));
}
