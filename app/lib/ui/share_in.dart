// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 다른 앱에서 부루미로 보내기 (Telegram tips 350 + 182). Something was
// shared to us from another app's share sheet: pick one or more chats
// (a green check on each photo), add a message if you like, switch to
// another account from the photo at the top right, and send. Then the
// Burumy mark floats over a "보내는 중 N%" bar until it says 완료.
// Only the chats this account can see are listed (hidden chats never
// show), and a chat whose rules stop these kinds is greyed with why.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../brand/mark.dart';
import '../core/accounts.dart';
import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/room_rules.dart';
import '../core/share_in.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

Future<void> openShareIn(BuildContext context, List<SharedItem> items) => openSheet<void>(context, (_) => ShareInPage(items: items));

class ShareInPage extends StatefulWidget {
  const ShareInPage({super.key, required this.items});
  final List<SharedItem> items;

  @override
  State<ShareInPage> createState() => _ShareInPageState();
}

class _ShareInPageState extends State<ShareInPage> {
  /// Another account on this phone (null: the one on screen).
  int? slot;
  List<ChatPreview>? chats;

  /// Why a chat can't take these: 'post', 'kind' or 'later'.
  final blocked = <String, String>{};
  final picked = <String>[];
  final comment = TextEditingController();
  String query = '';
  bool sent = false;

  AppState get s => AppScope.read(context);
  Accounts? get accounts => s.accounts;
  Backend get b => slot == null ? s.backend : accounts!.side[slot]!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => load());
  }

  @override
  void dispose() {
    comment.dispose();
    // Closed without sending: the phone's temporary copies go too.
    if (!sent) {
      for (final i in widget.items) {
        unawaited(i.drop());
      }
    }
    super.dispose();
  }

  Future<void> load() async {
    final from = b;
    final list = slot == null ? s.chats : await from.chats().catchError((_) => const <ChatPreview>[]);
    if (!mounted) return;
    setState(() {
      chats = list;
      blocked.clear();
      picked.clear();
    });
    final kinds = {for (final i in widget.items) i.kind};
    await Future.wait([
      for (final c in list)
        if (!c.isDirect)
          shareBlock(from, c.roomId, kinds).then((why) {
            if (why != null && mounted && from == b) setState(() => blocked[c.roomId] = why);
          }),
    ]);
  }

  Future<void> pickAccount() async {
    final a = accounts;
    if (a == null) return;
    final l = L.of(context);
    final rows = [(null as int?, s.backend.userId ?? ''), for (final e in a.others) (e.slot, e.userId)];
    final got = await showCupertinoModalPopup<(int?,)>(
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.shareInFrom),
        actions: [
          for (final (sl, id) in rows)
            CupertinoActionSheetAction(
              key: Key('share-in-account-${sl ?? 'me'}'),
              isDefaultAction: sl == slot,
              onPressed: () => Navigator.pop(c, (sl,)),
              child: Text(displayId(id)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (got == null || got.$1 == slot) return;
    if (got.$1 != null && a.side[got.$1] == null) return;
    setState(() {
      slot = got.$1;
      chats = null;
    });
    await load();
  }

  Future<void> send() async {
    if (picked.isEmpty) return;
    sent = true;
    final to = [
      for (final c in chats!)
        if (picked.contains(c.roomId)) c,
    ];
    await Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (_) => ShareSendPage(backend: b, items: widget.items, to: to, comment: comment.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final q = query.trim().toLowerCase();
    final all = chats;
    final shown = [
      for (final c in all ?? const <ChatPreview>[])
        if (q.isEmpty || c.name.toLowerCase().contains(q)) c,
    ];
    final a = accounts;
    final me = slot == null ? s.backend.userId : a?.list.where((e) => e.slot == slot).firstOrNull?.userId;
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar.nav(
        middle: Text(l.shareInTitle),
        leading: CupertinoButton(key: const Key('share-in-cancel'), padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        // 182: the account photo switches who sends.
        trailing: a != null && a.several
            ? GestureDetector(
                key: const Key('share-in-account'),
                onTap: pickAccount,
                child: Avatar(name: displayId(me ?? '').replaceFirst('@', ''), userId: me, size: Tokens.shareInAccount),
              )
            : null,
        backgroundColor: p.list,
      ),
      child: SafeArea(
        child: Column(
          children: [
            SharedStrip(items: widget.items),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
              child: CupertinoSearchTextField(
                key: const Key('share-in-search'),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                placeholder: l.searchChats,
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: all == null
                  ? const Center(child: CupertinoActivityIndicator())
                  : shown.isEmpty
                  ? Center(
                      child: Text(l.shareInNone, style: Tokens.body.style.copyWith(color: p.secondaryLabel)),
                    )
                  : ListView.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) => Padding(
                        padding: EdgeInsets.only(left: Tokens.memberAvatar + Tokens.space[3] * 2),
                        child: Container(height: 1, color: p.separator),
                      ),
                      itemBuilder: (_, i) => row(shown[i]),
                    ),
            ),
            if (picked.isNotEmpty) bottom(),
          ],
        ),
      ),
    );
  }

  Widget row(ChatPreview chat) {
    final l = L.of(context);
    final p = paletteOf(context);
    final why = blocked[chat.roomId];
    final on = picked.contains(chat.roomId);
    final name = chat.name;
    return GestureDetector(
      key: Key('share-in-to-${chat.roomId}'),
      behavior: HitTestBehavior.opaque,
      onTap: why != null
          ? null
          : () {
              HapticFeedback.selectionClick();
              setState(() => on ? picked.remove(chat.roomId) : picked.add(chat.roomId));
            },
      child: Opacity(
        opacity: why != null ? .45 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
          child: Row(
            children: [
              SizedBox(
                width: Tokens.memberAvatar,
                height: Tokens.memberAvatar,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedScale(
                      scale: on ? .86 : 1,
                      duration: const Duration(milliseconds: 160),
                      child: Avatar(
                        name: name,
                        size: Tokens.memberAvatar,
                        squircle: !chat.isDirect,
                        userId: chat.isDirect ? chat.peer : null,
                        roomId: chat.roomId,
                        owner: chat.isChannel ? chat.peer : null,
                      ),
                    ),
                    if (on)
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Container(
                          key: Key('share-in-check-${chat.roomId}'),
                          width: Tokens.shareInCheck,
                          height: Tokens.shareInCheck,
                          decoration: BoxDecoration(
                            color: p.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.list, width: 2),
                          ),
                          child: Icon(CupertinoIcons.checkmark_alt, size: Tokens.shareInCheck - 8, color: p.onAccent),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: Tokens.space[2]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: on ? p.accent : p.label),
                    ),
                    if (why != null)
                      Text(
                        switch (why) {
                          'post' => l.shareInNoPost,
                          'later' => l.shareInLater,
                          _ => l.shareInKind,
                        },
                        key: Key('share-in-why-${chat.roomId}'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Message field + the green send circle with how many chats.
  Widget bottom() {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1], Tokens.space[2], Tokens.space[2]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: CupertinoTextField(
              key: const Key('share-in-comment'),
              controller: comment,
              placeholder: l.shareInComment,
              maxLines: 4,
              minLines: 1,
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: 10),
              decoration: BoxDecoration(color: p.searchFill, borderRadius: BorderRadius.circular(Tokens.capsule)),
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          Semantics(
            button: true,
            label: l.shareInSendN(picked.length),
            child: GestureDetector(
              key: const Key('share-in-send'),
              onTap: send,
              child: SizedBox(
                width: Tokens.closeButton,
                height: Tokens.closeButton,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: BurumyMark(color: p.onAccent, size: 28),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        key: const Key('share-in-count'),
                        constraints: const BoxConstraints(minWidth: Tokens.shareInCheck),
                        height: Tokens.shareInCheck,
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[0]),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.list,
                          borderRadius: BorderRadius.circular(Tokens.capsule),
                          border: Border.all(color: p.accent, width: 1.5),
                        ),
                        child: Text(
                          '${picked.length}',
                          style: Tokens.caption.style.copyWith(color: p.accent, fontWeight: Tokens.semi),
                        ),
                      ),
                    ),
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

/// Why [roomId] can't take [kinds] now: 'post' (I can't write there),
/// 'kind' (its rules stop one of them) or 'later' (quiet hours); null = ok.
Future<String?> shareBlock(Backend b, String roomId, Set<String> kinds) async {
  try {
    if (!await b.canPost(roomId)) return 'post';
    final cfg = await b.roomConfig(roomId).catchError((_) => <String, dynamic>{});
    final role = await b.myRole(roomId).catchError((_) => 'member');
    for (final k in kinds) {
      if (!RoomRules.may(cfg, role, k, userId: b.userId)) return 'kind';
    }
    if (RoomRules.nightUntil(cfg, role, b.clock) != null) return 'later';
  } catch (_) {}
  return null;
}

/// What is being sent, in a row along the top.
class SharedStrip extends StatelessWidget {
  const SharedStrip({super.key, required this.items});
  final List<SharedItem> items;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final t = Tokens.shareInThumb;
    return SizedBox(
      height: t + Tokens.space[2] * 2,
      child: ListView(
        key: const Key('share-in-strip'),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(Tokens.space[2]),
        children: [
          for (final i in items)
            Padding(
              padding: EdgeInsets.only(right: Tokens.space[1]),
              child: ClipRSuperellipse(
                borderRadius: BorderRadius.circular(Tokens.radius[1]),
                child: SizedBox(
                  width: i.isText ? t * 3 : t,
                  height: t,
                  child: i.isPhoto
                      ? FutureBuilder<Uint8List>(
                          future: i.read(),
                          builder: (_, sn) => sn.data == null
                              ? ColoredBox(color: p.card)
                              : Image.memory(sn.data!, fit: BoxFit.cover, gaplessPlayback: true, cacheWidth: (t * 3).round()),
                        )
                      : ColoredBox(
                          color: p.searchFill,
                          child: i.isText
                              ? Padding(
                                  padding: EdgeInsets.all(Tokens.space[1]),
                                  child: Text(
                                    i.text,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Tokens.caption.style.copyWith(color: p.label),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(i.isVideo ? CupertinoIcons.play_rectangle_fill : CupertinoIcons.doc_fill, color: p.accent, size: Tokens.listIcon),
                                    SizedBox(height: Tokens.space[0]),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[0]),
                                      child: Text(
                                        i.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Sending: the Burumy mark floats over the bar, then 완료.
class ShareSendPage extends StatefulWidget {
  const ShareSendPage({super.key, required this.backend, required this.items, required this.to, this.comment = ''});
  final Backend backend;
  final List<SharedItem> items;
  final List<ChatPreview> to;
  final String comment;

  @override
  State<ShareSendPage> createState() => _ShareSendPageState();
}

class _ShareSendPageState extends State<ShareSendPage> with SingleTickerProviderStateMixin {
  late final float = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  /// What is really sent (0..1), and what the bar shows: it creeps toward
  /// the end of the file being sent, so a big video doesn't sit still.
  double done = 0, cap = 0, shown = 0;
  int ok = 0, failed = 0;
  bool finished = false;
  Timer? creep;

  @override
  void initState() {
    super.initState();
    creep = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      // Eases toward what is sent, never jumps: a quick send still shows
      // the bar filling (about a second and a half from 0 to 100 %).
      final goal = cap.clamp(0.0, 1.0);
      if (goal - shown < .002) return;
      final step = (goal - shown) * .18;
      setState(() => shown = (shown + (step < .04 ? .04 : step)).clamp(0.0, goal));
    });
    unawaited(run());
  }

  @override
  void dispose() {
    creep?.cancel();
    float.dispose();
    super.dispose();
  }

  Future<void> run() async {
    final b = widget.backend;
    final items = widget.items;
    final size = await ShareInbox.sizeOf(items);
    final per = size + widget.comment.length + 1;
    final total = (per * widget.to.length).toDouble();
    var sentBytes = 0;
    // One photo or file with a message: the message goes under it.
    final files = items.where((i) => !i.isText).toList();
    final caption = files.length == 1 && widget.comment.isNotEmpty;
    for (final c in widget.to) {
      var good = true;
      // Rules may have changed since the list opened; slow mode is checked here.
      final kinds = {for (final i in items) i.kind, if (widget.comment.isNotEmpty) 'text'};
      if (await shareBlock(b, c.roomId, kinds) != null || await slowWait(b, c)) good = false;
      if (good && widget.comment.isNotEmpty && !caption) {
        try {
          await b.sendText(c.roomId, widget.comment);
        } catch (_) {
          good = false;
        }
      }
      sentBytes += widget.comment.length + 1;
      for (final i in items) {
        final n = i.isText ? i.text.length : (i.bytes?.length ?? 0);
        cap = (sentBytes + n * .9) / total;
        if (good) {
          try {
            if (i.isText) {
              await b.sendText(c.roomId, i.text);
            } else {
              final bytes = await i.read();
              cap = (sentBytes + bytes.length * .9) / total;
              await b.sendFile(c.roomId, name: i.name, mime: i.mime, bytes: bytes, caption: caption ? widget.comment : '');
              sentBytes += bytes.length - n;
            }
          } catch (_) {
            good = false;
          }
        }
        sentBytes += n;
        done = sentBytes / total;
        cap = done;
      }
      good ? ok++ : failed++;
    }
    for (final i in items) {
      await i.drop();
    }
    cap = 1;
    while (mounted && shown < .995) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => finished = true);
    float.stop();
    if (failed == 0) {
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  /// Slow mode in a group: true while my last message is too recent.
  Future<bool> slowWait(Backend b, ChatPreview c) async {
    if (c.isDirect) return false;
    try {
      final cfg = await b.roomConfig(c.roomId);
      if (RoomRules.slowSeconds(cfg) == 0) return false;
      final role = await b.myRole(c.roomId);
      final last = (await b.timeline(c.roomId, limit: 30)).where((m) => m.mine).lastOrNull?.time;
      return RoomRules.slowWait(cfg, role, last, b.clock) != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final pct = (shown * 100).floor().clamp(0, 100);
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[5] + Tokens.space[3]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: float,
                  builder: (_, child) {
                    final v = Curves.easeInOut.transform(float.value);
                    return Transform.translate(
                      offset: Offset(0, finished ? 0 : -Tokens.space[1] + v * Tokens.space[2]),
                      child: Transform.rotate(angle: finished ? 0 : (v - .5) * .08, child: child),
                    );
                  },
                  child: AnimatedScale(
                    scale: finished ? 1.08 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      'assets/brand/symbol_green.png',
                      key: const Key('share-in-mark'),
                      width: Tokens.shareInMark,
                      color: p.accent,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                ),
                SizedBox(height: Tokens.space[5]),
                ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  child: SizedBox(
                    height: Tokens.shareInBar,
                    child: Stack(
                      children: [
                        Positioned.fill(child: ColoredBox(color: p.searchFill)),
                        Positioned.fill(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              key: const Key('share-in-bar'),
                              widthFactor: finished ? 1 : shown,
                              heightFactor: 1,
                              child: ColoredBox(color: failed > 0 && finished ? Palette.tileOrange : p.accent),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Tokens.space[3]),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    !finished
                        ? l.shareInSending(pct)
                        : failed == 0
                        ? l.done
                        : l.shareInFailed(failed),
                    key: ValueKey('share-in-state-$finished'),
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: finished ? Tokens.semi : null),
                  ),
                ),
                if (finished) ...[
                  SizedBox(height: Tokens.space[0]),
                  Text(
                    l.shareInSent(ok),
                    key: const Key('share-in-sent'),
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                  // All sent: it closes by itself. Some failed: read it, then close.
                  if (failed > 0) ...[
                    SizedBox(height: Tokens.space[4]),
                    CupertinoButton(key: const Key('share-in-close'), onPressed: () => Navigator.of(context).maybePop(), child: Text(l.close)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
