// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// "저장한 메시지" extras (Burumy v1 layout, Telegram iOS details, iOS 27
// look): the list of where saved messages came from (모든 메시지, 내 노트,
// each chat), the saved info page (미디어 / 파일 / 링크 with the ⋯ menu) and
// a small month calendar of saved photos and videos.
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../core/saved_tags.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'profile_page.dart' show SharedList, SharedThumb;
import 'wide.dart';

/// Which saved messages are shown: '' = all, 'note' = the ones I wrote
/// here myself, otherwise the id of the chat they were saved from.
bool inSavedSource(Msg m, String source, Map<String, String> from) {
  if (source.isEmpty) return true;
  if (source == 'note') return !m.forwarded;
  return from[m.id] == source;
}

/// Chats that saved messages came from, newest first.
List<String> savedSources(List<Msg> msgs, Map<String, String> from) {
  final last = <String, DateTime>{};
  for (final m in msgs) {
    final r = m.forwarded ? from[m.id] : null;
    if (r == null) continue;
    final t = last[r];
    if (t == null || m.time.isAfter(t)) last[r] = m.time;
  }
  return last.keys.toList()..sort((a, b) => last[b]!.compareTo(last[a]!));
}

/// The side list slides in from the left (Telegram); returns the choice,
/// or null when closed.
/// Telegram: the chat slides left and stays as a strip (tap it to close);
/// the list fills the rest. [onAnim] lets the chat follow the same motion.
Future<String?> openSavedSide(BuildContext context, {required List<Msg> msgs, required String current, void Function(Animation<double>)? onAnim}) {
  final r = PageRouteBuilder<String>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (c, a, _) => Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: Tokens.sideStrip,
          child: GestureDetector(key: const Key('saved-side-close'), behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(c)),
        ),
        Positioned(
          left: Tokens.sideStrip,
          top: 0,
          right: 0,
          bottom: 0,
          child: SavedChatsPage(msgs: msgs, current: current),
        ),
      ],
    ),
    transitionsBuilder: (c, a, _, child) {
      final w = MediaQuery.sizeOf(c).width - Tokens.sideStrip;
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (_, ch) => Transform.translate(offset: Offset(w * (1 - curved.value), 0), child: ch),
      );
    },
  );
  final f = Navigator.of(context).push(r);
  if (r.animation case final a?) onAnim?.call(CurvedAnimation(parent: a, curve: Curves.easeOutCubic));
  return f;
}

/// Back on the side list leaves 저장한 메시지 altogether (Telegram):
/// to Settings or the chat list, wherever it was opened from.
const savedExit = '\u0000exit';

/// Name of a chat a message was saved from.
String savedSourceName(AppState s, String roomId) {
  final c = s.chats.where((x) => x.roomId == roomId).firstOrNull;
  if (c == null) return '?';
  return nameOf(s, c);
}

/// Small round mark in front of a row name (20 pt, Telegram).
class _Mark extends StatelessWidget {
  const _Mark({required this.color, required this.icon});
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, size: 11, color: const Color(0xFFFFFFFF)),
  );
}

/// 모든 메시지 / 내 노트 / each chat (v1 order, Telegram rows).
class SavedChatsPage extends StatefulWidget {
  const SavedChatsPage({super.key, required this.msgs, required this.current});
  final List<Msg> msgs;
  final String current;

  @override
  State<SavedChatsPage> createState() => _SavedChatsPageState();
}

class _SavedChatsPageState extends State<SavedChatsPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final from = savedFrom(s);
    final msgs = widget.msgs;
    Msg? lastOf(bool Function(Msg) f) => msgs.where(f).fold<Msg?>(null, (a, m) => a == null || m.time.isAfter(a.time) ? m : a);
    String text(Msg m) => previewText(context, kind: m.kind, body: m.body, caption: m.caption);
    String who(Msg m) {
      if (!m.forwarded) return l.savedNotes;
      final r = from[m.id];
      return r == null ? '' : savedSourceName(s, r);
    }

    final allLast = lastOf((_) => true);
    final noteLast = lastOf((m) => !m.forwarded);
    final rows = <(String, Widget, String, Msg?, String)>[
      ('', _Mark(color: p.accent, icon: CupertinoIcons.bookmark_fill), l.savedAll, allLast, allLast == null ? '' : '${who(allLast)}: ${text(allLast)}'),
      ('note', const _Mark(color: Palette.tileTeal, icon: CupertinoIcons.square_pencil), l.savedNotes, noteLast, noteLast == null ? '' : text(noteLast)),
      for (final r in savedSources(msgs, from))
        if (lastOf((m) => m.forwarded && from[m.id] == r) case final last?)
          (
            r,
            Avatar(name: savedSourceName(s, r), size: 20, roomId: r, squircle: !(s.chats.where((c) => c.roomId == r).firstOrNull?.isDirect ?? true)),
            savedSourceName(s, r),
            last,
            text(last),
          ),
    ];
    final q = query.trim().toLowerCase();
    final shown = q.isEmpty ? rows : rows.where((r) => r.$3.toLowerCase().contains(q) || r.$5.toLowerCase().contains(q)).toList();
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      // Telegram: no back here (tap the chat strip to close); a wide title
      // capsule and the bookmark that opens 미디어·파일·링크.
      navigationBar: GlassTopBar(
        tint: p.list,
        full: Row(
          children: [
            Expanded(
              child: Center(
                child: LiquidGlass(
                  radius: Tokens.capsule,
                  child: Container(
                    height: Tokens.closeButton,
                    constraints: const BoxConstraints(minWidth: Tokens.titlePillMin),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        l.savedMessages,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Tokens.navTitle.style.copyWith(color: p.label),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: Tokens.space[2]),
            AccentCircle(
              key: const Key('saved-side-info'),
              icon: CupertinoIcons.bookmark_fill,
              onTap: () {
                final id = AppScope.read(context).savedRoomId;
                if (id != null) Navigator.of(context).push(IosPageRoute(builder: (_) => SavedInfoPage(roomId: id)));
              },
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: ListView(
          key: const Key('saved-side'),
          padding: EdgeInsets.only(bottom: Tokens.space[3]),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
              child: CupertinoSearchTextField(
                key: const Key('saved-side-search'),
                placeholder: l.savedSearchList,
                style: Tokens.body.style.copyWith(color: p.label),
                borderRadius: BorderRadius.circular(Tokens.capsule),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            for (var i = 0; i < shown.length; i++) ...[
              if (i > 0 && shown[i - 1].$1 != widget.current && shown[i].$1 != widget.current)
                Padding(
                  padding: EdgeInsets.only(left: Tokens.space[3]),
                  child: Container(height: 1, color: p.separator),
                ),
              _row(context, shown[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, (String, Widget, String, Msg?, String) r) {
    final p = paletteOf(context);
    final on = r.$1 == widget.current;
    return GestureDetector(
      key: Key('saved-src-${r.$1.isEmpty ? 'all' : r.$1}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context, r.$1),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: on ? p.incoming.withValues(alpha: 0.7) : null, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                r.$2,
                SizedBox(width: Tokens.space[1]),
                Expanded(
                  child: Text(
                    r.$3,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
                  ),
                ),
                if (r.$4 != null) Text(shortTime(context, r.$4!.time), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              ],
            ),
            SizedBox(height: Tokens.nameToSub),
            Text(
              r.$5,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS pull-down menu under a top-bar button: 250 wide, 44 rows, a tick on
/// the left for chosen options, the icon on the right (iOS 27).
Future<String?> showPullDown(BuildContext context, List<(String, String, IconData?, bool)> items) => paneNav(context).push<String>(
  PageRouteBuilder(
    opaque: false,
    barrierDismissible: true,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (c, a, _) {
      final p = paletteOf(c);
      final top = MediaQuery.paddingOf(c).top + GlassTopBar.height;
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(key: const Key('pulldown-dismiss'), behavior: HitTestBehavior.opaque, onTap: () => Navigator.pop(c)),
          ),
          Positioned(
            top: top,
            right: Tokens.space[3],
            child: FadeTransition(
              opacity: a,
              child: ScaleTransition(
                alignment: Alignment.topRight,
                scale: Tween(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: SizedBox(
                  width: 250,
                  child: LiquidGlass(
                    radius: Tokens.radius[3],
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final it in items)
                            GestureDetector(
                              key: Key('pulldown-${it.$1}'),
                              behavior: HitTestBehavior.opaque,
                              onTap: () => Navigator.pop(c, it.$1),
                              child: SizedBox(
                                height: 44,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: it.$4 ? Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIconSmall, color: p.label) : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        it.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.body.style.copyWith(color: p.label),
                                      ),
                                    ),
                                    if (it.$3 != null) Icon(it.$3, size: Tokens.listIcon, color: p.label),
                                    SizedBox(width: Tokens.space[3]),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  ),
);

/// Saved info page: 미디어 / 파일 / 링크, and on 미디어 the ⋯ menu
/// (확대, 축소, 달력 보기, 사진 보기, 동영상 보기) like v1.
class SavedInfoPage extends StatefulWidget {
  const SavedInfoPage({super.key, required this.roomId});
  final String roomId;

  @override
  State<SavedInfoPage> createState() => _SavedInfoPageState();
}

class _SavedInfoPageState extends State<SavedInfoPage> {
  int tab = 0;
  int cols = 3;
  bool photos = true;
  bool videos = true;
  List<Msg> msgs = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (msgs.isEmpty) {
      AppScope.of(context).backend.timeline(widget.roomId, limit: 300).then((m) {
        if (mounted) setState(() => msgs = m.reversed.toList());
      }, onError: (_) {});
    }
  }

  List<Msg> get media => [
    for (final m in msgs)
      if (!m.viewOnce && ((m.kind == 'image' && photos) || (m.kind == 'video' && videos))) m,
  ];

  Future<void> more() async {
    final l = L.of(context);
    final pick = await showPullDown(context, [
      if (cols > 2) ('zoom-in', l.mediaZoomIn, CupertinoIcons.zoom_in, false),
      if (cols < 5) ('zoom-out', l.mediaZoomOut, CupertinoIcons.zoom_out, false),
      ('calendar', l.mediaCalendar, CupertinoIcons.calendar, false),
      ('photos', l.mediaPhotos, null, photos),
      ('videos', l.mediaVideos, null, videos),
    ]);
    if (!mounted || pick == null) return;
    switch (pick) {
      case 'zoom-in':
        setState(() => cols--);
      case 'zoom-out':
        setState(() => cols++);
      case 'calendar':
        await Navigator.of(context).push(
          IosPageRoute(
            builder: (_) => MediaCalendarPage(roomId: widget.roomId, media: media),
          ),
        );
      // At least one kind stays on (iOS Photos does the same).
      case 'photos':
        if (videos || !photos) setState(() => photos = !photos);
      case 'videos':
        if (photos || !videos) setState(() => videos = !videos);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = media;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(l.savedMessages),
        trailing: tab == 0 ? GlassCircle(key: const Key('saved-info-more'), onTap: more, child: GlassCircle.icon(context, CupertinoIcons.ellipsis)) : null,
        backgroundColor: p.background,
      ),
      child: SafeArea(
        child: ListView(
          key: const Key('saved-info'),
          padding: EdgeInsets.only(bottom: Tokens.space[4]),
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                child: SizedBox(
                  width: 280,
                  child: IosSegmented<int>(
                    key: const Key('saved-info-tabs'),
                    groupValue: tab,
                    children: {0: Text(l.tabMedia), 1: Text(l.tabFiles), 2: Text(l.tabLinks)},
                    onValueChanged: (v) => setState(() => tab = v ?? 0),
                  ),
                ),
              ),
            ),
            if (tab != 0)
              SharedList(roomId: widget.roomId, msgs: msgs, tab: tab)
            else if (list.isEmpty)
              Padding(
                key: const Key('saved-media-empty'),
                padding: EdgeInsets.only(top: Tokens.space[5]),
                child: Column(
                  children: [
                    Icon(CupertinoIcons.photo, size: 44, color: p.secondaryLabel),
                    SizedBox(height: Tokens.space[3]),
                    Text(l.savedNoMore, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                  ],
                ),
              )
            else
              GridView.count(
                key: Key('saved-media-$cols'),
                crossAxisCount: cols,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [for (final m in list) SharedThumb(roomId: widget.roomId, msg: m)],
              ),
          ],
        ),
      ),
    );
  }
}

/// Saved photos and videos by month: days with something show its picture.
class MediaCalendarPage extends StatelessWidget {
  const MediaCalendarPage({super.key, required this.roomId, required this.media});
  final String roomId;
  final List<Msg> media;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final lang = Localizations.localeOf(context).languageCode;
    final byDay = <DateTime, Msg>{};
    for (final m in media) {
      byDay.putIfAbsent(DateTime(m.time.year, m.time.month, m.time.day), () => m);
    }
    final now = DateTime.now();
    final months = {for (final d in byDay.keys) DateTime(d.year, d.month), DateTime(now.year, now.month)}.toList()..sort((a, b) => b.compareTo(a));
    final weekdays = [for (var i = 0; i < 7; i++) DateFormat.E(lang).format(DateTime(2026, 11, 22 + i))];
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.mediaCalendar), backgroundColor: p.background),
      child: SafeArea(
        child: ListView(
          key: const Key('media-calendar'),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
          children: [
            Row(
              children: [
                for (final w in weekdays)
                  Expanded(
                    child: Center(
                      child: Text(w, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ),
                  ),
              ],
            ),
            for (final mo in months) ...[
              Padding(
                padding: EdgeInsets.only(top: Tokens.space[3], bottom: Tokens.space[1]),
                child: Text(
                  DateFormat.yMMMM(lang).format(mo),
                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: FontWeight.w600),
                ),
              ),
              GridView.count(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 0; i < mo.weekday % 7; i++) const SizedBox.shrink(),
                  for (var d = 1; d <= DateTime(mo.year, mo.month + 1, 0).day; d++)
                    if (byDay[DateTime(mo.year, mo.month, d)] case final m?)
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipOval(
                            child: SharedThumb(roomId: roomId, msg: m),
                          ),
                          Center(
                            child: Text(
                              '$d',
                              style: Tokens.preview.style.copyWith(
                                color: const Color(0xFFFFFFFF),
                                shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Text('$d', style: Tokens.preview.style.copyWith(color: p.label)),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
