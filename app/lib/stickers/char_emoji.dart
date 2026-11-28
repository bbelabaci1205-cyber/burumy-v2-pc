// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Character emoji between words (Telegram's custom emoji, our own art) and
// character reactions.
//
// In a message a character emoji travels as a short code, ":buru_e2_love:",
// inside the encrypted text, and our app draws the picture. Lists,
// notifications and copied text show the matching plain emoji (😍).
// In the composer each one is a single private-use letter, so the cursor,
// delete and selection treat it as one character; it turns back into the
// short code when the message goes out.
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import '../design/tokens.dart';
import '../core/custom_emoji.dart';
import 'catalog.dart';
import 'cx_emoji_view.dart';

/// ":buru_e2_love:" (also matches unknown ids; those stay as typed), and
/// made emoji ":cx_0123456789ab:" (tip 354, core/custom_emoji.dart).
final charEmojiCode = RegExp(r':([a-z]+_e\d_[a-z]+|cx_[0-9a-f]{12}):');

/// Our characters, or a made emoji whose picture this phone has.
bool _known(String id) => _indexOf.containsKey(id) || CustomEmojis.known.containsKey(id);

/// Plain emoji for each meaning, for previews and other apps.
const meaningEmoji = <String, String>{
  'smile': '😊',
  'love': '😍',
  'lol': '😂',
  'sad': '😢',
  'angry': '😠',
  'wow': '😮',
  'night': '😴',
  'good': '👍',
  'hello': '👋',
  'fire': '🔥',
  'thanks': '🙏',
  'congrats': '🎉',
  'wink': '😉',
  'brr': '🥶',
};

/// The plain emoji standing in for a character emoji or reaction id.
String charFallback(String id) => id.startsWith('cx_') ? (CustomEmojis.known[id]?.base ?? '🙂') : meaningEmoji[id.split('_').skip(2).join('_')] ?? '🙂';

final List<String> _allEmoji = [for (final g in charEmojiGroups.values) ...g];
final Map<String, int> _indexOf = {for (var i = 0; i < _allEmoji.length; i++) _allEmoji[i]: i};

/// First private-use letter (Unicode U+E000 block, one UTF-16 unit each).
const _pua = 0xE000;

/// Made emoji get composer letters from here on, handed out as used.
const _cxPua = 0xF000;
final _cxUnit = <String, int>{};
final _cxId = <int, String>{};

String? _idOfUnit(int unit) {
  final i = unit - _pua;
  if (i >= 0 && i < _allEmoji.length) return _allEmoji[i];
  return unit >= _cxPua ? _cxId[unit] : null;
}

/// Composer letter for a character emoji id.
String charEmojiLetter(String id) {
  final i = _indexOf[id];
  if (i != null) return String.fromCharCode(_pua + i);
  final u = _cxUnit.putIfAbsent(id, () => _cxPua + _cxUnit.length);
  _cxId[u] = id;
  return String.fromCharCode(u);
}

bool _hasLetters(String s) => s.codeUnits.any((u) => _idOfUnit(u) != null);

/// Short codes -> composer letters.
String charEmojiIn(String text) => text.replaceAllMapped(charEmojiCode, (m) => _known(m.group(1)!) ? charEmojiLetter(m.group(1)!) : m.group(0)!);

/// Composer letters -> short codes (what is sent).
String charEmojiOut(String text) {
  if (!_hasLetters(text)) return text;
  final b = StringBuffer();
  for (final u in text.codeUnits) {
    final id = _idOfUnit(u);
    b.write(id == null ? String.fromCharCode(u) : ':$id:');
  }
  return b.toString();
}

/// Short codes and composer letters -> plain emoji (lists, notifications, copy).
String charEmojiPlain(String text) {
  final t = text.replaceAllMapped(charEmojiCode, (m) => _known(m.group(1)!) || m.group(1)!.startsWith('cx_') ? charFallback(m.group(1)!) : m.group(0)!);
  if (!_hasLetters(t)) return t;
  final b = StringBuffer();
  for (final u in t.codeUnits) {
    final id = _idOfUnit(u);
    b.write(id == null ? String.fromCharCode(u) : charFallback(id));
  }
  return b.toString();
}

/// The known character emoji ids in [text], or null when [text] holds
/// anything else (big emoji: only 1–3 of them, spaces allowed).
List<String>? onlyCharEmoji(String text) {
  final s = text.trim();
  if (s.isEmpty) return null;
  final ids = <String>[];
  var rest = s.replaceAllMapped(charEmojiCode, (m) {
    if (!_known(m.group(1)!) && !m.group(1)!.startsWith('cx_')) return m.group(0)!;
    ids.add(m.group(1)!);
    return '';
  });
  rest = rest.trim();
  return ids.isEmpty || rest.isNotEmpty ? null : ids;
}

/// One character emoji drawn at text size (a little larger, like Apple's).
class CharEmoji extends StatelessWidget {
  const CharEmoji(this.id, {super.key, required this.size});
  final String id;
  final double size;
  @override
  Widget build(BuildContext context) => id.startsWith('cx_')
      ? CxEmojiView(id, size: size)
      : Image.asset(
          charEmojiAsset(id)!,
          key: Key('char-emoji-$id'),
          width: size,
          height: size,
          cacheWidth: (size * 3).round(),
          semanticLabel: charFallback(id),
        );
}

/// [s] with its short codes drawn as pictures.
List<InlineSpan> charEmojiSpans(String s, TextStyle st, {GestureRecognizer? recognizer}) {
  if (!s.contains(':')) return [TextSpan(text: s, style: st, recognizer: recognizer)];
  final out = <InlineSpan>[];
  var at = 0;
  final size = (st.fontSize ?? 17) * 1.25;
  for (final m in charEmojiCode.allMatches(s)) {
    // A made emoji whose picture has not come yet shows its stand-in for now.
    if (!_known(m.group(1)!) && !m.group(1)!.startsWith('cx_')) continue;
    if (m.start > at) out.add(TextSpan(text: s.substring(at, m.start), style: st, recognizer: recognizer));
    out.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: CharEmoji(m.group(1)!, size: size),
      ),
    );
    at = m.end;
  }
  if (at < s.length) out.add(TextSpan(text: s.substring(at), style: st, recognizer: recognizer));
  return out;
}

/// The composer's controller: a pasted or typed ":buru_e2_love:" becomes
/// one character emoji, drawn as its picture.
class EmojiTextController extends TextEditingController {
  EmojiTextController({super.text});

  @override
  set value(TextEditingValue v) {
    if (!v.text.contains(':') || !charEmojiCode.hasMatch(v.text)) {
      super.value = v;
      return;
    }
    var base = v.selection.baseOffset, extent = v.selection.extentOffset;
    final b = StringBuffer();
    var at = 0, cut = 0;
    int move(int o, int start, int end) => o < 0 || o <= start - cut ? o : (o >= end - cut ? o - (end - start - 1) : start - cut + 1);
    for (final m in charEmojiCode.allMatches(v.text)) {
      final id = m.group(1)!;
      if (!_known(id)) continue;
      b.write(v.text.substring(at, m.start));
      b.write(charEmojiLetter(id));
      base = move(base, m.start, m.end);
      extent = move(extent, m.start, m.end);
      cut += m.end - m.start - 1;
      at = m.end;
    }
    if (at == 0) {
      super.value = v;
      return;
    }
    b.write(v.text.substring(at));
    final text = b.toString();
    super.value = TextEditingValue(
      text: text,
      selection: v.selection.isValid ? TextSelection(baseOffset: base.clamp(0, text.length), extentOffset: extent.clamp(0, text.length)) : v.selection,
    );
  }

  /// What goes out: the composer letters back as short codes.
  String get outText => charEmojiOut(text);

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    if (!_hasLetters(text)) return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    final size = (style?.fontSize ?? Tokens.body.style.fontSize ?? 17) * 1.25;
    final kids = <InlineSpan>[];
    final run = StringBuffer();
    for (final u in text.codeUnits) {
      final id = _idOfUnit(u);
      if (id == null) {
        run.writeCharCode(u);
        continue;
      }
      if (run.isNotEmpty) {
        kids.add(TextSpan(text: run.toString()));
        run.clear();
      }
      kids.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: CharEmoji(id, size: size),
        ),
      );
    }
    if (run.isNotEmpty) kids.add(TextSpan(text: run.toString()));
    return TextSpan(style: style, children: kids);
  }
}

/// A reaction: a character picture ('buru_r2_love') or a plain emoji.
class ReactionGlyph extends StatelessWidget {
  const ReactionGlyph(this.reaction, {super.key, this.size = 17, this.style, this.opacity = 1});
  final String reaction;
  final double size;
  final TextStyle? style;
  final double opacity;
  @override
  Widget build(BuildContext context) {
    final asset = charReactionAsset(reaction);
    final Widget w = asset == null
        ? Text(
            reaction,
            style: (style ?? const TextStyle()).copyWith(fontSize: size, height: 1, fontFamilyFallback: Tokens.emojiFallback),
          )
        : Image.asset(asset, width: size * 1.2, height: size * 1.2, cacheWidth: (size * 3.6).round(), semanticLabel: charFallback(reaction));
    return opacity < 1 ? Opacity(opacity: opacity, child: w) : w;
  }
}

/// A reaction as plain text (notifications, lists): pictures -> emoji.
String reactionText(String reaction) => charReactionAsset(reaction) == null ? reaction : charFallback(reaction);
