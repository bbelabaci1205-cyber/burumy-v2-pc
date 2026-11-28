// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 링크 미리보기 조절 + 답장·링크 탭 (Telegram tips 400 + 401). Tapping the
// link line (or the reply line) above the message field opens this screen:
// the chat blurs, my message shows as it will be sent, and a menu beside it
// changes it. With both a reply and a link, capsule tabs at the bottom
// switch between 답장 and 링크.
//   링크 tab: 위로/아래로 옮기기 (card above or below the words), 사진
//             작게/크게, 적용, 미리보기 안 함 (red). With several links, a
//             tap on a link in the bubble makes the card for that one.
//   답장 tab: 특정 부분 인용, 다른 대화에서 답장, 적용, 답장 안 함 (red).
// The card is still made on MY phone and travels encrypted (the readers
// never contact the website). Telegram's 전달 tab is not here: Burumy
// forwards straight away and never keeps the source (a deliberate choice).
//
// Sizes: iOS 27 context menu (250 wide, 44 rows, radius[3] glass, 8 pt
// group gap), blur 14 + 18 % dim like the message menu, tab capsule 36
// tall with 13/18 semi labels.
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show LinkCardBody;
import 'common.dart';
import 'formatting.dart';
import 'glass.dart';
import 'wide.dart';

/// Every web link in [text], in order, once (same rule as the engine).
List<String> linksIn(String text) {
  final out = <String>[];
  for (var w in text.split(RegExp(r'\s+'))) {
    final i = w.lastIndexOf('](');
    if (i >= 0) w = w.substring(i + 2);
    w = w.replaceAll(RegExp(r'''[.,!?)\]}>"']+$'''), '').replaceAll(RegExp(r'''^[(<\["']+'''), '');
    if ((w.startsWith('https://') || w.startsWith('http://')) && w.length > 10 && w.substring(8).contains('.') && !out.contains(w)) out.add(w);
  }
  return out;
}

class ComposeOptionsResult {
  const ComposeOptionsResult(this.link, {this.reply});
  final LinkChoice link;

  /// 'part' (특정 부분 인용), 'other' (다른 대화에서 답장), 'none' (답장 안 함).
  final String? reply;
}

/// Opens the screen on [tab] ('link' or 'reply'). Null = closed as it was.
Future<ComposeOptionsResult?> openComposeOptions(
  BuildContext context, {
  required String text,
  required LinkChoice link,
  required Future<StoryLinkInfo?> Function(String url) card,
  String tab = 'link',
  Msg? replying,
  String replyName = '',
  bool canQuotePart = false,
  bool canReplyElsewhere = false,
}) => paneNav(context).push<ComposeOptionsResult>(
  PageRouteBuilder(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (c, a, _) => ComposeOptionsPage(
      anim: a,
      text: text,
      link: link,
      card: card,
      tab: tab,
      replying: replying,
      replyName: replyName,
      canQuotePart: canQuotePart,
      canReplyElsewhere: canReplyElsewhere,
    ),
  ),
);

class ComposeOptionsPage extends StatefulWidget {
  const ComposeOptionsPage({
    super.key,
    required this.anim,
    required this.text,
    required this.link,
    required this.card,
    this.tab = 'link',
    this.replying,
    this.replyName = '',
    this.canQuotePart = false,
    this.canReplyElsewhere = false,
  });
  final Animation<double> anim;
  final String text;
  final LinkChoice link;
  final Future<StoryLinkInfo?> Function(String url) card;
  final String tab;
  final Msg? replying;
  final String replyName;
  final bool canQuotePart, canReplyElsewhere;

  static const width = 250.0, row = 44.0, tabsHeight = 36.0;

  @override
  State<ComposeOptionsPage> createState() => _ComposeOptionsPageState();
}

class _ComposeOptionsPageState extends State<ComposeOptionsPage> {
  late String tab = widget.tab;
  late LinkChoice link = widget.link.copyWith(off: false);
  late final links = linksIn(widget.text);
  final cards = <String, Future<StoryLinkInfo?>>{};

  String? get url => links.isEmpty ? null : (links.contains(link.url) ? link.url! : links.first);
  Future<StoryLinkInfo?>? get info => url == null ? null : cards.putIfAbsent(url!, () => widget.card(url!));

  bool get hasLink => links.isNotEmpty;
  bool get hasReply => widget.replying != null;

  void done([String? reply]) => Navigator.pop(context, ComposeOptionsResult(link, reply: reply));

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final anim = widget.anim;
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
    final showLink = tab == 'link' && hasLink || !hasReply;
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('compose-options-dismiss'),
              onTap: () => done(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14 * anim.value, sigmaY: 14 * anim.value),
                child: ColoredBox(color: Color.fromRGBO(0, 0, 0, 0.18 * anim.value)),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => done(),
            child: SafeArea(
              child: Opacity(
                opacity: anim.value.clamp(0, 1),
                child: Transform.scale(scale: 0.94 + 0.06 * curved.value, alignment: Alignment.bottomRight, child: child),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        key: const Key('compose-options'),
        children: [
          SizedBox(height: Tokens.space[2]),
          Text(
            showLink ? l.linkOptionsTitle : l.replyOptionsTitle,
            style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi),
          ),
          if (showLink && links.length > 1) Text(l.linkOptionsPick, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[3]),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: showLink ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (showLink) linkBubble(p) else replyBubble(p),
                    SizedBox(height: Tokens.space[1]),
                    showLink ? linkMenu(l, p) : replyMenu(l, p),
                  ],
                ),
              ),
            ),
          ),
          if (hasLink && hasReply) tabs(l, p),
          SizedBox(height: Tokens.space[2]),
        ],
      ),
    );
  }

  /// My message as it will be sent: words with the links (the picked one
  /// highlighted; tap another to use it), and the card above or below.
  Widget linkBubble(Palette p) {
    final plain = plainText(widget.text);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final u in links) {
      final i = plain.indexOf(u, at);
      if (i < 0) continue;
      if (i > at) spans.add(TextSpan(text: plain.substring(at, i)));
      final on = u == url;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            key: Key('pick-link-$u'),
            onTap: () => setState(() => link = link.copyWith(url: u)),
            child: Container(
              decoration: BoxDecoration(color: on && links.length > 1 ? p.onAccent.withValues(alpha: 0.28) : null, borderRadius: BorderRadius.circular(4)),
              child: Text(
                u,
                style: Tokens.body.style.copyWith(color: p.onAccent, decoration: TextDecoration.underline, decorationColor: p.onAccent),
              ),
            ),
          ),
        ),
      );
      at = i + u.length;
    }
    if (at < plain.length) spans.add(TextSpan(text: plain.substring(at)));
    final words = Text.rich(
      TextSpan(
        style: Tokens.body.style.copyWith(color: p.onAccent),
        children: spans,
      ),
      key: const Key('compose-bubble-text'),
    );
    final cardView = FutureBuilder<StoryLinkInfo?>(
      key: ValueKey('card-$url'),
      future: info,
      builder: (context, snap) {
        final c = snap.data;
        if (c == null) {
          return snap.connectionState == ConnectionState.done
              ? const SizedBox.shrink()
              : Padding(
                  padding: EdgeInsets.all(Tokens.space[1]),
                  child: CupertinoActivityIndicator(color: p.onAccent),
                );
        }
        return LinkCardBody(
          key: const Key('compose-card'),
          site: c.site,
          title: c.title,
          description: c.description.isEmpty ? null : c.description,
          image: c.image.isEmpty ? null : Future.value(c.image),
          small: link.small,
          above: link.above,
          line: p.onAccent,
          fg: p.onAccent,
        );
      },
    );
    return Container(
      key: const Key('compose-bubble'),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.rowBubble)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: link.above ? [cardView, words] : [words, cardView],
      ),
    );
  }

  /// The message being answered, as a grey bubble with its writer.
  Widget replyBubble(Palette p) {
    final m = widget.replying!;
    final words = m.quote ?? plainText(m.caption ?? m.body ?? '');
    return Container(
      key: const Key('compose-reply-bubble'),
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.rowBubble)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.replyName,
            style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
          ),
          Text(
            words,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: Tokens.body.style.copyWith(color: p.label),
          ),
        ],
      ),
    );
  }

  Widget menuBox(Palette p, List<Widget> rows) => SizedBox(
    width: ComposeOptionsPage.width,
    child: LiquidGlass(
      radius: Tokens.radius[3],
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        child: Column(mainAxisSize: MainAxisSize.min, children: rows),
      ),
    ),
  );

  Widget gap(Palette p) => Container(height: Tokens.space[1], color: p.label.withValues(alpha: 0.06));

  Widget linkMenu(L l, Palette p) => FutureBuilder<StoryLinkInfo?>(
    future: info,
    builder: (context, snap) {
      final picture = (snap.data?.image ?? const []).isNotEmpty;
      return menuBox(p, [
        _OptionRow(
          id: link.above ? 'link-down' : 'link-up',
          label: link.above ? l.linkMoveDown : l.linkMoveUp,
          icon: link.above ? CupertinoIcons.arrow_down_to_line : CupertinoIcons.arrow_up_to_line,
          onTap: () => setState(() => link = link.copyWith(above: !link.above)),
        ),
        if (picture)
          _OptionRow(
            id: link.small ? 'link-big' : 'link-small',
            label: link.small ? l.linkPhotoBig : l.linkPhotoSmall,
            icon: link.small ? CupertinoIcons.arrow_up_left_arrow_down_right : CupertinoIcons.arrow_down_right_arrow_up_left,
            onTap: () => setState(() => link = link.copyWith(small: !link.small)),
          ),
        gap(p),
        _OptionRow(id: 'link-apply', label: l.applyChanges, icon: CupertinoIcons.checkmark_circle, onTap: () => done()),
        _OptionRow(
          id: 'link-off',
          label: l.linkNoPreview,
          icon: CupertinoIcons.trash,
          danger: true,
          onTap: () => Navigator.pop(context, ComposeOptionsResult(link.copyWith(off: true))),
        ),
      ]);
    },
  );

  Widget replyMenu(L l, Palette p) => menuBox(p, [
    if (widget.canQuotePart) _OptionRow(id: 'reply-pick-part', label: l.quotePickPart, icon: CupertinoIcons.text_quote, onTap: () => done('part')),
    if (widget.canReplyElsewhere)
      _OptionRow(id: 'reply-other-chat', label: l.replyInOtherChat, icon: CupertinoIcons.arrowshape_turn_up_right, onTap: () => done('other')),
    if (widget.canQuotePart || widget.canReplyElsewhere) gap(p),
    _OptionRow(id: 'reply-apply', label: l.applyChanges, icon: CupertinoIcons.checkmark_circle, onTap: () => done()),
    _OptionRow(id: 'reply-cancel', label: l.replyNone, icon: CupertinoIcons.trash, danger: true, onTap: () => done('none')),
  ]);

  /// 답장 | 링크 capsule (tip 401).
  Widget tabs(L l, Palette p) => LiquidGlass(
    radius: Tokens.capsule,
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (id, label) in [('reply', l.tabReply), ('link', l.tabLink)])
            GestureDetector(
              key: Key('compose-tab-$id'),
              onTap: () => setState(() => tab = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: ComposeOptionsPage.tabsHeight - 6,
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: tab == id ? p.label.withValues(alpha: 0.1) : null, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(
                  label,
                  style: Tokens.caption.style.copyWith(color: tab == id ? p.label : p.secondaryLabel, fontWeight: Tokens.semi),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _OptionRow extends StatefulWidget {
  const _OptionRow({required this.id, required this.label, required this.icon, required this.onTap, this.danger = false});
  final String id, label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  @override
  State<_OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<_OptionRow> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final c = widget.danger ? Palette.tileRed : p.label;
    return GestureDetector(
      key: Key('opt-${widget.id}'),
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => down = true),
      onTapCancel: () => setState(() => down = false),
      onTapUp: (_) => setState(() => down = false),
      onTap: widget.onTap,
      child: Container(
        height: ComposeOptionsPage.row,
        color: down ? p.label.withValues(alpha: 0.08) : const Color(0x00000000),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Tokens.body.style.copyWith(color: c),
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            Icon(widget.icon, size: Tokens.listIcon, color: c),
          ],
        ),
      ),
    );
  }
}
