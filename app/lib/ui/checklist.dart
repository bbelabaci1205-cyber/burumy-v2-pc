// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Checklists: the maker's screen and the checklist bubble.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'ios.dart';
import 'glass.dart';

class CreateChecklistPage extends StatefulWidget {
  const CreateChecklistPage({super.key, required this.roomId, required this.isGroup});
  final String roomId;

  /// Groups and channels: others may tick / add (1:1: the other person).
  final bool isGroup;

  @override
  State<CreateChecklistPage> createState() => _CreateChecklistPageState();
}

class _CreateChecklistPageState extends State<CreateChecklistPage> {
  static const maxItems = 30;
  final title = TextEditingController();
  final items = [TextEditingController()];
  final focus = [FocusNode()];
  bool othersMark = true;
  bool othersAdd = false;
  bool busy = false;

  bool get ready => title.text.trim().isNotEmpty && items.any((i) => i.text.trim().isNotEmpty);

  @override
  void dispose() {
    title.dispose();
    for (final i in items) {
      i.dispose();
    }
    for (final f in focus) {
      f.dispose();
    }
    super.dispose();
  }

  void addItem() {
    if (items.length >= maxItems) return;
    setState(() {
      items.add(TextEditingController());
      focus.add(FocusNode());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.last.requestFocus());
  }

  Future<void> create() async {
    if (!ready || busy) return;
    setState(() => busy = true);
    try {
      await AppScope.of(context).backend
          .createChecklist(widget.roomId, title.text.trim(), [for (final i in items) i.text], othersMark: othersMark, othersAdd: othersAdd);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final field = Tokens.body.style.copyWith(color: p.label);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.newChecklist),
        trailing: Opacity(
          opacity: ready && !busy ? 1 : 0.4,
          child: GlassPill(key: const Key('checklist-create'), text: l.send, onTap: ready && !busy ? create : null),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            IosSection(
              hasLeading: false,
              header: sectionHeader(context, l.checklistTitle),
              children: [
                CupertinoTextField.borderless(
                  key: const Key('checklist-title'),
                  controller: title,
                  placeholder: l.checklistTitleHint,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                  maxLength: 200,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            IosSection(
              header: sectionHeader(context, l.checklistItems),
              footer: sectionFooter(context, l.checklistItemsInfo(maxItems)),
              children: [
                for (var i = 0; i < items.length; i++)
                  CupertinoTextField.borderless(
                    key: Key('checklist-item-$i'),
                    controller: items[i],
                    focusNode: focus[i],
                    placeholder: l.checklistItemHint,
                    style: field,
                    padding: EdgeInsets.all(Tokens.space[2]),
                    maxLength: 200,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => i == items.length - 1 ? addItem() : focus[i + 1].requestFocus(),
                    onChanged: (_) => setState(() {}),
                    prefix: Padding(
                      padding: EdgeInsets.only(left: Tokens.space[2]),
                      child: Icon(CupertinoIcons.circle, size: Tokens.listIcon, color: p.secondaryLabel),
                    ),
                    suffix: items.length > 1
                        ? CupertinoButton(
                            padding: EdgeInsets.only(right: Tokens.space[1]),
                            minimumSize: const Size(32, 32),
                            onPressed: () => setState(() {
                              items.removeAt(i).dispose();
                              focus.removeAt(i).dispose();
                            }),
                            child: Icon(CupertinoIcons.minus_circle_fill, color: Palette.tileRed, size: Tokens.listIcon),
                          )
                        : null,
                  ),
                if (items.length < maxItems)
                  IosTile(
                    key: const Key('checklist-add'),
                    leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent),
                    title: Text(l.checklistAddItem, style: Tokens.body.style.copyWith(color: p.accent)),
                    onTap: addItem,
                  ),
              ],
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.checklistOthersInfo),
              children: [
                IosTile(
                  title: Text(l.checklistOthersMark),
                  trailing: IosSwitch(
                    key: const Key('checklist-others-mark'),
                    value: othersMark,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => othersMark = v),
                  ),
                ),
                IosTile(
                  title: Text(l.checklistOthersAdd),
                  trailing: IosSwitch(
                    key: const Key('checklist-others-add'),
                    value: othersAdd,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => othersAdd = v),
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

/// The checklist inside a chat: tick circles, who ticked (groups), "N/M done",
/// and "+ add" when the maker allowed it.
class ChecklistBubble extends StatefulWidget {
  const ChecklistBubble({
    super.key,
    required this.roomId,
    required this.msg,
    required this.fg,
    required this.meta,
    required this.onChanged,
    this.showWho = false,
  });
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;
  final Future<void> Function() onChanged;
  final bool showWho;

  @override
  State<ChecklistBubble> createState() => _ChecklistBubbleState();
}

class _ChecklistBubbleState extends State<ChecklistBubble> {
  bool adding = false;
  final add = TextEditingController();

  @override
  void dispose() {
    add.dispose();
    super.dispose();
  }

  Future<void> tick(ChecklistItem it) async {
    await AppScope.of(context).backend.markChecklist(widget.roomId, widget.msg.id, it.id, it.doneBy == null);
    await widget.onChanged();
  }

  Future<void> submit() async {
    final t = add.text.trim();
    if (t.isEmpty) return setState(() => adding = false);
    add.clear();
    setState(() => adding = false);
    await AppScope.of(context).backend.addChecklistItem(widget.roomId, widget.msg.id, t);
    await widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final c = widget.msg.checklist!;
    final fg = widget.fg;
    final canMark = widget.msg.mine || c.othersMark;
    final canAdd = (widget.msg.mine || c.othersAdd) && c.items.length < 30;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 230),
      child: Column(
        key: Key('checklist-${widget.msg.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            c.title,
            style: Tokens.body.style.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
          Text(l.checklistDone(c.done, c.items.length), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7))),
          SizedBox(height: Tokens.space[1]),
          for (final it in c.items)
            GestureDetector(
              key: Key('check-${it.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: canMark ? () => tick(it) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: Icon(
                        it.doneBy != null ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                        key: ValueKey(it.doneBy != null),
                        size: 22,
                        color: fg.withValues(alpha: it.doneBy != null ? 1 : (canMark ? 0.7 : 0.4)),
                      ),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.text,
                            style: Tokens.body.style.copyWith(
                              color: fg.withValues(alpha: it.doneBy != null ? 0.6 : 1),
                              decoration: it.doneBy != null ? TextDecoration.lineThrough : null,
                              decorationColor: fg.withValues(alpha: 0.6),
                            ),
                          ),
                          if (widget.showWho && it.doneBy != null)
                            Text(displayId(it.doneBy!), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (adding)
            CupertinoTextField(
              key: const Key('checklist-new-item'),
              controller: add,
              autofocus: true,
              placeholder: l.checklistItemHint,
              maxLength: 200,
              style: Tokens.body.style.copyWith(color: fg),
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(Tokens.radius[1])),
              onSubmitted: (_) => submit(),
              suffix: CupertinoButton(
                key: const Key('checklist-new-ok'),
                padding: EdgeInsets.only(right: Tokens.space[1]),
                minimumSize: const Size(32, 32),
                onPressed: submit,
                child: Icon(CupertinoIcons.arrow_up_circle_fill, color: fg, size: 26),
              ),
            )
          else if (canAdd)
            GestureDetector(
              key: const Key('checklist-add-item'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => adding = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(CupertinoIcons.add, size: 22, color: fg.withValues(alpha: 0.8)),
                    SizedBox(width: Tokens.space[1]),
                    Text(l.checklistAddItem, style: Tokens.body.style.copyWith(color: fg.withValues(alpha: 0.8))),
                  ],
                ),
              ),
            ),
          Align(alignment: Alignment.centerRight, child: widget.meta),
        ],
      ),
    );
  }
}
