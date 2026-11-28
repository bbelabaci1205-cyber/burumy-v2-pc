// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 스티커 묶음 screens (Telegram tips 538 + 441 + 79; Eric's card "B. 묶음+
// 공유만"): 내 스티커 묶음 list, make / edit a set (name, add stickers,
// order, an emoji per sticker), share it (to a chat as an encrypted card,
// or as a link whose key stays after '#'), the card in the chat, the
// preview with 추가, and 둘러보기 (Burumy packs + sets seen in my chats).
// Layout follows Settings > 스티커와 이모지 (v1 placement); sizes are the
// rulebook's (rows 52 / 64, 5-column sticker grid like the panel).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../core/app_state.dart';
import '../core/backend.dart' show CardInfo, Msg;
import '../core/features.dart';
import '../core/sticker_sets.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import '../stickers/catalog.dart';
import 'chat_page.dart' show ForwardPickPage;
import 'common.dart';
import 'emoji_pick.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'settings_kit.dart';
import 'settings_pages.dart' show packName;
import 'sticker_maker.dart' show StickerMakerPage, myStickers;
import 'sticker_shop.dart';
import 'stories.dart' show showStoryToast;
import 'wide.dart';

/// One sticker of a set, drawn at [size].
class SetItemView extends StatelessWidget {
  const SetItemView(this.item, {super.key, this.size = 64});
  final SetItem item;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = item.id.isEmpty ? null : stickerAsset(item.id);
    final px = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return SizedBox(
      width: size,
      height: size,
      child: item.png != null
          ? Image.memory(item.png!, cacheWidth: px, gaplessPlayback: true)
          : a != null
          ? Image.asset(a, cacheWidth: px)
          : const SizedBox.shrink(),
    );
  }
}

/// The set's picture: its first sticker.
Widget setCover(StickerSet s, {double size = 40}) => s.items.isEmpty ? SizedBox(width: size, height: size) : SetItemView(s.items.first, size: size);

// ---------------------------------------------------------------------------
// Settings > 스티커와 이모지 > 내 스티커 묶음

class MySetsPage extends StatelessWidget {
  const MySetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final sets = StickerSets.all(s).where((x) => x.kind == 'sticker').toList();
    final mine = sets.where((x) => x.mine).toList();
    final added = sets.where((x) => !x.mine).toList();
    Widget row(StickerSet x) => IosTile(
      key: Key('set-row-${x.id}'),
      leadingSize: 40,
      leading: setCover(x),
      title: Text(x.name),
      subtitle: Text(l.stickerCount(x.items.length)),
      trailing: const IosChevron(),
      onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => x.mine ? SetEditPage(set: x) : SetPreviewPage.local(x))),
    );
    return SettingsScaffold(
      title: l.setsTitle,
      children: [
        HeaderCard(color: Palette.tilePurple, icon: CupertinoIcons.square_stack_3d_up_fill, title: l.setsTitle, body: l.setsHeader),
        group(context, footer: l.setsMakeInfo, [
          IosTile(
            key: const Key('set-new'),
            leading: Icon(CupertinoIcons.add_circled_solid, color: p.accent, size: 28),
            title: Text(l.setsNew, style: TextStyle(color: p.accent)),
            onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const SetEditPage())),
          ),
          for (final x in mine) row(x),
        ]),
        if (added.isNotEmpty) group(context, header: l.setsAdded, [for (final x in added) row(x)]),
        group(context, [
          NavRow(
            key: const Key('sets-browse'),
            color: Palette.tileOrange,
            icon: CupertinoIcons.flame_fill,
            title: Features.ownWay ? l.shopOpen : l.setsBrowse,
            page: (_) => const BrowseSetsPage(),
          ),
        ]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Make / edit a set

class SetEditPage extends StatefulWidget {
  const SetEditPage({super.key, this.set});
  final StickerSet? set;
  @override
  State<SetEditPage> createState() => _SetEditPageState();
}

class _SetEditPageState extends State<SetEditPage> {
  late final name = TextEditingController(text: widget.set?.name ?? '');
  late List<SetItem> items = [...?widget.set?.items];
  late final String id = widget.set?.id ?? 's${DateTime.now().millisecondsSinceEpoch}';
  bool tried = false;
  bool busy = false;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  bool get ok => cleanName(name.text).isNotEmpty && items.isNotEmpty;

  /// Saves on this phone. A set shared before gets a new file on its next
  /// share (old links keep showing the old version).
  Future<StickerSet?> save() async {
    setState(() => tried = true);
    if (!ok) return null;
    final s = AppScope.read(context);
    final changed =
        widget.set == null || jsonEncode(widget.set!.payload()) != jsonEncode(StickerSet(id: id, name: cleanName(name.text), items: items).payload());
    final set = StickerSet(id: id, name: cleanName(name.text), items: items, mine: true, file: changed ? '' : widget.set!.file);
    await StickerSets.put(s, set);
    return set;
  }

  Future<void> add() async {
    final picked = await openSheet<List<SetItem>>(context, (_) => PickStickersPage(have: items));
    if (picked == null || !mounted) return;
    setState(() => items = [...items, ...picked].take(StickerSets.maxItems).toList());
  }

  Future<void> itemMenu(int i) async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      context: context,
      builder: (c) => IosActionSheet(
        title: SizedBox(height: 96, child: Center(child: SetItemView(items[i], size: 88))),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('set-item-emoji'),
            onPressed: () => Navigator.pop(c, 'emoji'),
            child: Text(items[i].emoji.isEmpty ? l.setItemEmoji : l.setItemEmojiNow(items[i].emoji)),
          ),
          if (i > 0) CupertinoActionSheetAction(key: const Key('set-item-first'), onPressed: () => Navigator.pop(c, 'first'), child: Text(l.setItemFirst)),
          if (i > 0) CupertinoActionSheetAction(key: const Key('set-item-left'), onPressed: () => Navigator.pop(c, 'left'), child: Text(l.setItemLeft)),
          if (i < items.length - 1)
            CupertinoActionSheetAction(key: const Key('set-item-right'), onPressed: () => Navigator.pop(c, 'right'), child: Text(l.setItemRight)),
          CupertinoActionSheetAction(
            key: const Key('set-item-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(l.setItemRemove),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    if (pick == 'emoji') {
      final e = await pickEmoji(context, title: l.setItemEmoji);
      if (e != null && mounted) setState(() => items[i] = items[i].copy(emoji: e));
      return;
    }
    setState(() {
      final x = items.removeAt(i);
      switch (pick) {
        case 'first':
          items.insert(0, x);
        case 'left':
          items.insert(i - 1, x);
        case 'right':
          items.insert(i + 1, x);
      }
    });
  }

  Future<void> share() async {
    final set = await save();
    if (set == null || !mounted) return;
    setState(() => busy = true);
    try {
      await shareStickerSet(context, set);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final yes = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.setDeleteInfo),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('set-delete-yes'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(l.setDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (yes != true || !mounted) return;
    await StickerSets.remove(s, id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return SettingsScaffold(
      title: widget.set == null ? l.setsNew : l.setEdit,
      trailing: [
        GlassDone(
          key: const Key('set-save'),
          onTap: busy
              ? null
              : () async {
                  final set = await save();
                  if (set != null && context.mounted) Navigator.pop(context);
                },
        ),
      ],
      children: [
        group(context, header: l.setName, footer: tried && cleanName(name.text).isEmpty ? l.setNameNeeded : null, error: true, [
          CupertinoTextField.borderless(
            key: const Key('set-name'),
            controller: name,
            placeholder: l.setNameHint,
            maxLength: StickerSets.maxName,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[2] + 3),
            onChanged: (_) => setState(() {}),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin + 20, Tokens.space[4], IosSection.sideMargin + 20, Tokens.groupTitleToCard + 2),
          child: sectionHeader(context, l.setStickers(items.length, StickerSets.maxItems)),
        ),
        Container(
          key: const Key('set-grid'),
          margin: EdgeInsets.symmetric(horizontal: IosSection.sideMargin),
          padding: EdgeInsets.all(Tokens.space[1]),
          decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(IosSection.radius)),
          child: GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (items.length < StickerSets.maxItems)
                GestureDetector(
                  key: const Key('set-add'),
                  onTap: add,
                  child: Container(
                    margin: EdgeInsets.all(Tokens.space[0]),
                    decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[2])),
                    child: Icon(CupertinoIcons.add, color: p.accent, size: 28),
                  ),
                ),
              for (var i = 0; i < items.length; i++)
                GestureDetector(
                  key: Key('set-item-$i'),
                  onTap: () => itemMenu(i),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Padding(padding: EdgeInsets.all(Tokens.space[0]), child: SetItemView(items[i])),
                      ),
                      if (items[i].emoji.isNotEmpty) Positioned(right: 0, bottom: 0, child: Text(items[i].emoji, style: emojiStyle(15))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin + 20, Tokens.cardToFooter, IosSection.sideMargin + 20, 0),
          child: sectionFooter(context, tried && items.isEmpty ? l.setEmpty : l.setOrderInfo, error: tried && items.isEmpty),
        ),
        group(context, footer: l.setShareInfo, [
          IosTile(
            key: const Key('set-share'),
            leading: iconTile(Palette.tileBlue, CupertinoIcons.square_arrow_up),
            title: Text(l.setShare),
            trailing: const IosChevron(),
            onTap: busy ? null : share,
          ),
        ]),
        if (widget.set != null)
          group(context, [
            IosTile(
              key: const Key('set-delete'),
              title: Text(l.setDelete, style: const TextStyle(color: Palette.tileRed)),
              onTap: delete,
            ),
          ]),
      ],
    );
  }
}

/// Pick stickers to put in a set: 내 스티커 (made on this phone), a new one,
/// and every Burumy sticker. Returns the picked ones.
class PickStickersPage extends StatefulWidget {
  const PickStickersPage({super.key, this.have = const []});
  final List<SetItem> have;
  @override
  State<PickStickersPage> createState() => _PickStickersPageState();
}

class _PickStickersPageState extends State<PickStickersPage> {
  final picked = <String>[];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = myStickers(s);
    final room = StickerSets.maxItems - widget.have.length;
    Widget cell(String key, Widget child) {
      final at = picked.indexOf(key);
      return GestureDetector(
        key: Key('pick-$key'),
        onTap: () => setState(() {
          if (at >= 0) {
            picked.remove(key);
          } else if (picked.length < room) {
            picked.add(key);
          }
        }),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(padding: EdgeInsets.all(Tokens.space[0] + 2), child: child),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: at >= 0 ? p.accent : const Color(0x33000000),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFFFFF), width: 1.5),
                ),
                child: at >= 0 ? Text('${at + 1}', style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF), fontSize: 12)) : null,
              ),
            ),
          ],
        ),
      );
    }

    SliverGrid grid(List<Widget> cells) =>
        SliverGrid(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5), delegate: SliverChildListDelegate(cells));
    Widget head(String t) =>
        Padding(padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[1]), child: sectionHeader(context, t));
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        middle: Text(picked.isEmpty ? l.setPickTitle : l.setPicked(picked.length)),
        leading: GlassCircle(
          key: const Key('pick-close'),
          size: Tokens.closeButton,
          onTap: () => Navigator.pop(context),
          child: GlassCircle.icon(context, CupertinoIcons.xmark, size: Tokens.closeIcon),
        ),
        trailing: GlassDone(
          key: const Key('pick-done'),
          onTap: picked.isEmpty
              ? null
              : () {
                  final mineNow = myStickers(AppScope.read(context));
                  Navigator.pop(context, [
                    for (final k in picked)
                      if (k.startsWith('mine:')) SetItem(png: mineNow[int.parse(k.substring(5))]) else SetItem(id: k, emoji: _emojiOf(k)),
                  ]);
                },
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: head(l.stickerMine)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
              sliver: grid([
                GestureDetector(
                  key: const Key('pick-make'),
                  onTap: () async {
                    final png = await openSheet<Uint8List>(context, (_) => const StickerMakerPage());
                    if (png == null || !context.mounted) return;
                    // StickerMakerPage keeps it first in 내 스티커; pick it.
                    setState(() {
                      // Indices moved by one: the new sticker is first.
                      for (var i = 0; i < picked.length; i++) {
                        if (picked[i].startsWith('mine:')) picked[i] = 'mine:${int.parse(picked[i].substring(5)) + 1}';
                      }
                      if (picked.length < room) picked.add('mine:0');
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(Tokens.space[0] + 2),
                    decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[2])),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.add, color: p.accent, size: 24),
                        Text(
                          l.stickerTileMake,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Tokens.caption.style.copyWith(color: p.accent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                for (var i = 0; i < mine.length; i++) cell('mine:$i', Image.memory(mine[i])),
              ]),
            ),
            for (final k in stickerPacks) ...[
              SliverToBoxAdapter(child: head(packName(l, k.id))),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                sliver: grid([
                  for (final id in k.items)
                    if (!StickerPack.moving(id)) cell(id, Image.asset(k.asset(id), cacheWidth: (64 * MediaQuery.devicePixelRatioOf(context)).round())),
                ]),
              ),
            ],
            SliverToBoxAdapter(child: SizedBox(height: Tokens.space[5])),
          ],
        ),
      ),
    );
  }
}

/// A built-in sticker's emoji (its meaning's emoji word).
String _emojiOf(String id) {
  const byMeaning = {
    'hello': '👋', 'thanks': '🙏', 'love': '❤️', 'good': '👍', 'lol': '😂', 'sorry': '🙇', 'night': '🌙', 'angry': '😠', //
    'wow': '😮', 'sad': '😢', 'congrats': '🎉', 'fighting': '💪', 'hmm': '🤔', 'ok': '👌', 'secret': '🤫', 'dizzy': '😵',
  };
  return byMeaning[id.split('_').skip(2).join('_')] ?? '';
}

// ---------------------------------------------------------------------------
// Sharing

/// Uploads the set once (encrypted here) and remembers its file.
Future<StickerSet> uploadStickerSet(AppState s, StickerSet set) async {
  if (set.file.isNotEmpty) return set;
  final file = await s.backend.uploadEncrypted(utf8.encode(jsonEncode(set.payload())));
  final done = set.copy(file: file);
  await StickerSets.put(s, done);
  return done;
}

/// 대화에 보내기 / 링크 복사.
Future<void> shareStickerSet(BuildContext context, StickerSet set) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final how = await showCupertinoModalPopup<String>(
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(set.name),
      message: Text(l.setShareSheetInfo),
      actions: [
        CupertinoActionSheetAction(key: const Key('set-share-chat'), onPressed: () => Navigator.pop(c, 'chat'), child: Text(l.setShareToChat)),
        CupertinoActionSheetAction(key: const Key('set-share-link'), onPressed: () => Navigator.pop(c, 'link'), child: Text(l.setCopyLink)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (how == null || !context.mounted) return;
  final String? room = how == 'chat' ? await openSheet<String>(context, (_) => ForwardPickPage(title: l.setShareToChat)) : null;
  if (how == 'chat' && room == null) return;
  final up = await uploadStickerSet(s, set);
  if (room != null) {
    await s.backend.createCard(room, 'stickers', {'file': jsonDecode(up.file), 'name': up.name, 'n': up.items.length, 'kind': up.kind});
    unawaited(s.refresh());
    if (context.mounted) showStoryToast(context, l.setSent);
  } else {
    await Clipboard.setData(ClipboardData(text: StickerSetLink(up.file, up.name).url));
    if (context.mounted) showStoryToast(context, l.setLinkCopied);
  }
}

/// A set link was tapped (or pasted): open its preview.
Future<void> openStickerSetLink(BuildContext context, StickerSetLink link) => paneNav(context).push(
  IosPageRoute(
    builder: (_) => SetPreviewPage(file: link.file, name: link.name),
  ),
);

// ---------------------------------------------------------------------------
// Someone's set: preview + 추가

class SetPreviewPage extends StatefulWidget {
  const SetPreviewPage({super.key, required this.file, this.name = '', this.from = ''}) : local = null;
  const SetPreviewPage.local(StickerSet this.local, {super.key}) : file = '', name = '', from = '';
  final String file;
  final String name;
  final String from;
  final StickerSet? local;

  @override
  State<SetPreviewPage> createState() => _SetPreviewPageState();
}

/// Downloaded sets this session (a card opened twice downloads once).
final _downloaded = <String, StickerSet>{};

Future<StickerSet?> loadStickerSet(AppState s, String file, {String name = '', String from = ''}) async {
  final local = StickerSets.all(s).where((x) => x.file == file).firstOrNull;
  if (local != null) return local;
  if (_downloaded[file] case final d?) return d;
  final bytes = await s.backend.downloadEncrypted(file);
  final set = StickerSet.fromPayload(bytes, file: file, from: from);
  if (set != null) _downloaded[file] = set;
  return set;
}

class _SetPreviewPageState extends State<SetPreviewPage> {
  StickerSet? set;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    set = widget.local;
    if (set == null) {
      loadStickerSet(
        AppScope.read(context),
        widget.file,
        from: widget.from,
      ).then((v) => mounted ? setState(() => v == null ? failed = true : set = v) : null, onError: (_) => mounted ? setState(() => failed = true) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final x = set;
    final have = x != null && (x.mine || StickerSets.all(s).any((y) => y.id == x.id || (x.file.isNotEmpty && y.file == x.file)));
    return SettingsScaffold(
      title: x?.name ?? widget.name,
      children: [
        if (x == null)
          Padding(
            padding: EdgeInsets.all(Tokens.space[5]),
            child: Center(
              child: failed
                  ? Text(
                      l.setOpenFailed,
                      key: const Key('set-failed'),
                      textAlign: TextAlign.center,
                      style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                    )
                  : const CupertinoActivityIndicator(),
            ),
          )
        else ...[
          Container(
            key: const Key('set-preview'),
            margin: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[4], IosSection.sideMargin, 0),
            padding: EdgeInsets.all(Tokens.space[1]),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(IosSection.radius)),
            child: GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 5,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (final i in x.items) Padding(padding: EdgeInsets.all(Tokens.space[0]), child: SetItemView(i))],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(IosSection.sideMargin + 20, Tokens.cardToFooter, IosSection.sideMargin + 20, 0),
            child: sectionFooter(context, l.setPrivateInfo),
          ),
          if (!x.mine)
            Padding(
              padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[4], IosSection.sideMargin, 0),
              child: _WideButton(
                key: Key(have ? 'set-remove' : 'set-add-to-mine'),
                label: have ? l.setRemove(x.items.length) : l.setAddCount(x.items.length),
                filled: !have,
                onTap: () async {
                  if (have) {
                    final local = StickerSets.all(s).where((y) => y.id == x.id || y.file == x.file).firstOrNull;
                    if (local != null) await StickerSets.remove(s, local.id);
                    if (context.mounted) showStoryToast(context, l.setRemoved);
                  } else {
                    // Who shared it: this card's sender (the download may be shared).
                    await StickerSets.put(s, StickerSet(id: x.id, name: x.name, items: x.items, kind: x.kind, file: x.file, from: widget.from));
                    if (context.mounted) showStoryToast(context, l.setAdded(x.name));
                  }
                },
              ),
            ),
          if (x.file.isNotEmpty)
            group(context, [
              IosTile(
                key: const Key('set-preview-share'),
                leading: iconTile(Palette.tileBlue, CupertinoIcons.square_arrow_up),
                title: Text(l.setShare),
                onTap: () => shareStickerSet(context, x),
              ),
            ]),
        ],
      ],
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({super.key, required this.label, required this.onTap, this.filled = true});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: filled ? p.accent : p.card, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          label,
          style: Tokens.body.style.copyWith(color: filled ? const Color(0xFFFFFFFF) : Palette.tileRed, fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The card in a chat

class StickerSetBubble extends StatefulWidget {
  const StickerSetBubble({super.key, required this.msg, required this.fg});
  final Msg msg;
  final Color fg;
  @override
  State<StickerSetBubble> createState() => _StickerSetBubbleState();
}

class _StickerSetBubbleState extends State<StickerSetBubble> {
  StickerSet? set;

  CardInfo get c => widget.msg.card!;
  String get file => c.data['file'] is Map ? jsonEncode(c.data['file']) : '';

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    // 둘러보기 > 대화에서 본 묶음 (others' sets only; after this frame).
    if (!widget.msg.mine) {
      WidgetsBinding.instance.addPostFrameCallback((_) => StickerSets.noteSeen(s, widget.msg.id, file, c.text('name'), (c.data['n'] as num?)?.toInt() ?? 0));
    }
    if (file.isNotEmpty) {
      loadStickerSet(s, file, from: widget.msg.sender).then((v) => mounted ? setState(() => set = v) : null, onError: (_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final fg = widget.fg;
    final n = (c.data['n'] as num?)?.toInt() ?? 0;
    final have = StickerSets.has(s, file);
    final items = set?.items.take(4).toList() ?? const <SetItem>[];
    return GestureDetector(
      key: Key('set-card-${widget.msg.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => paneNav(context).push(
        IosPageRoute(
          builder: (_) => SetPreviewPage(file: file, name: c.text('name'), from: widget.msg.sender),
        ),
      ),
      child: SizedBox(
        width: 228,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.square_stack_3d_up, size: 13, color: fg.withValues(alpha: 0.75)),
                SizedBox(width: Tokens.space[0]),
                Text(l.setCardKind, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75))),
              ],
            ),
            SizedBox(height: Tokens.space[0]),
            Text(
              c.text('name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.body.style.copyWith(color: fg, fontWeight: Tokens.semi),
            ),
            Text(l.stickerCount(n), style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.75))),
            SizedBox(height: Tokens.space[1]),
            SizedBox(
              height: 52,
              child: Row(
                children: [
                  for (final i in items)
                    Padding(
                      padding: EdgeInsets.only(right: Tokens.space[1]),
                      child: SetItemView(i, size: 48),
                    ),
                  if (items.isEmpty) const CupertinoActivityIndicator(),
                ],
              ),
            ),
            SizedBox(height: Tokens.space[1]),
            Container(
              key: Key('set-card-open-${widget.msg.id}'),
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
              child: Text(have ? l.setCardHave : l.setCardView, style: Tokens.caption.style.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 둘러보기 (tip 79): Burumy's own packs and sets seen in my chats. No
// server ranking: that would tell the server who uses which set.

class BrowseSetsPage extends StatelessWidget {
  const BrowseSetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 우리식: the sticker shop (free packs now, paid later).
    if (Features.ownWay) return const StickerShopPage();
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final seen = StickerSets.seen(s).entries.where((e) => !StickerSets.has(s, e.key)).toList();
    Widget packRow(StickerPack k) {
      final on = !s.on('pack_off:${k.id}');
      return IosTile(
        key: Key('browse-pack-${k.id}'),
        leadingSize: 48,
        leading: Image.asset(k.asset(k.items.first), width: 48, height: 48),
        title: Text(packName(l, k.id)),
        subtitle: Text(l.stickerCount(k.items.length)),
        trailing: AddPill(on: on, onTap: () => s.setOn('pack_off:${k.id}', on)),
      );
    }

    return SettingsScaffold(
      title: l.setsBrowse,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(IosSection.sideMargin, Tokens.space[3], IosSection.sideMargin, 0),
          child: SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // The newest Burumy pack first, moving stickers (Telegram: trending row).
                for (final k in stickerPacks.reversed)
                  for (final id in k.items.where(StickerPack.moving).take(1))
                    Padding(
                      padding: EdgeInsets.only(right: Tokens.space[1]),
                      child: Image.asset(k.asset(id), width: 88, height: 88),
                    ),
              ],
            ),
          ),
        ),
        group(context, header: l.setsBurumyPacks, footer: l.setsBurumyInfo, [for (final k in stickerPacks) packRow(k)]),
        group(context, header: l.setsSeen, footer: seen.isEmpty ? l.setsSeenNone : l.setsSeenInfo, [
          for (final e in seen)
            IosTile(
              key: Key('browse-seen-${e.key.hashCode}'),
              leading: Icon(CupertinoIcons.square_stack_3d_up_fill, color: p.accent),
              title: Text(e.value.$1),
              subtitle: Text(l.setSeenCount(e.value.$2, e.value.$3)),
              trailing: const IosChevron(),
              onTap: () => Navigator.of(context).push(
                IosPageRoute(
                  builder: (_) => SetPreviewPage(file: e.key, name: e.value.$1),
                ),
              ),
            ),
        ]),
      ],
    );
  }
}

class AddPill extends StatelessWidget {
  const AddPill({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 30,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: on ? p.label.withValues(alpha: 0.08) : p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(
          on ? l.setAddedShort : l.setAddShort,
          style: Tokens.caption.style.copyWith(color: on ? p.secondaryLabel : const Color(0xFFFFFFFF), fontWeight: Tokens.semi),
        ),
      ),
    );
  }
}
