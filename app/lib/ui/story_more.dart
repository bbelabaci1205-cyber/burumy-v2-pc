// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// What our stories do beyond Instagram (Eric, 2026-11-24: 1, 3, 4, 5, 6):
// - who sees it: all friends, close friends, or friends picked this time;
// - how long: 6 / 12 / 24 (default) / 48 hours;
// - live parts: a poll, a question, a plan (일정). Answers go to the poster
//   as a 1:1 message, inside that chat's encryption; nobody else, and not
//   us, sees who answered what;
// - my story archive, on this phone only (never on the server).
import 'dart:convert';
import 'dart:io' show Directory, File;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'story_video.dart';
import 'wide.dart';

// ---------------------------------------------------------------- live parts

/// A poll, a question or a plan placed on a story. [at] is its centre as a
/// part of the picture (0..1), [scale] its size.
class StoryLive {
  StoryLive({required this.kind, this.q = '', this.options = const [], this.when = '', this.place = '', this.at = const Offset(.5, .5), this.scale = 1});
  final String kind; // poll, question, plan
  String q; // the question, or the plan's title
  List<String> options;
  String when, place;
  Offset at;
  double scale;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    'q': q,
    if (options.isNotEmpty) 'options': options,
    if (when.isNotEmpty) 'when': when,
    if (place.isNotEmpty) 'place': place,
    'x': double.parse(at.dx.toStringAsFixed(3)),
    'y': double.parse(at.dy.toStringAsFixed(3)),
    's': double.parse(scale.toStringAsFixed(2)),
  };

  static StoryLive? fromJson(Object? j) {
    if (j is! Map) return null;
    final kind = j['kind'];
    if (kind is! String || !const {'poll', 'question', 'plan'}.contains(kind)) return null;
    String str(Object? v, int max) => v is String ? (v.length > max ? v.substring(0, max) : v) : '';
    double dbl(Object? v, double d, double lo, double hi) => v is num ? v.toDouble().clamp(lo, hi) : d;
    final opts = j['options'] is List ? [for (final o in (j['options'] as List).take(4)) str(o, 40)].where((o) => o.isNotEmpty).toList() : <String>[];
    if (kind == 'poll' && opts.length < 2) return null;
    return StoryLive(
      kind: kind,
      q: str(j['q'], 120),
      options: opts,
      when: str(j['when'], 60),
      place: str(j['place'], 80),
      at: Offset(dbl(j['x'], .5, 0, 1), dbl(j['y'], .5, 0, 1)),
      scale: dbl(j['s'], 1, .4, 3),
    );
  }
}

String encodeLive(List<StoryLive> items) => items.isEmpty
    ? ''
    : jsonEncode({
        'items': [for (final x in items) x.toJson()],
      });

List<StoryLive> decodeLive(String? extra) {
  if (extra == null || extra.isEmpty) return const [];
  try {
    final j = jsonDecode(extra);
    final items = j is Map ? j['items'] : null;
    if (items is! List) return const [];
    return [for (final x in items.take(6)) ?StoryLive.fromJson(x)];
  } catch (_) {
    return const [];
  }
}

/// The card drawn on a story. In the viewer the buttons answer (to the
/// poster's 1:1 chat); in the editor they do nothing.
class StoryLiveCard extends StatefulWidget {
  const StoryLiveCard({super.key, required this.item, this.onAnswer, this.chosen});
  final StoryLive item;

  /// Sends an answer (text). Null in the editor and on my own story.
  final Future<void> Function(String text)? onAnswer;

  /// The option I already picked (poll), kept on this phone.
  final String? chosen;

  @override
  State<StoryLiveCard> createState() => _StoryLiveCardState();
}

class _StoryLiveCardState extends State<StoryLiveCard> {
  final answer = TextEditingController();
  String? picked;
  bool sent = false;

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final it = widget.item;
    const ink = Color(0xFF000000);
    const card = Color(0xFFFFFFFF);
    final choice = picked ?? widget.chosen;
    bool isMine(String o) => choice == o || (choice?.endsWith('→ $o') ?? false);
    final title = Text(
      it.q,
      textAlign: TextAlign.center,
      style: Tokens.body.style.copyWith(color: ink, fontWeight: FontWeight.w600),
    );
    Widget body;
    switch (it.kind) {
      case 'poll':
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            title,
            SizedBox(height: Tokens.space[2]),
            for (var i = 0; i < it.options.length; i++) ...[
              if (i > 0) SizedBox(height: Tokens.space[1]),
              GestureDetector(
                key: Key('live-option-$i'),
                onTap: widget.onAnswer == null || choice != null
                    ? null
                    : () async {
                        setState(() => picked = it.options[i]);
                        await widget.onAnswer!('📊 ${it.q} → ${it.options[i]}');
                      },
                child: Container(
                  height: Tokens.closeButton,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isMine(it.options[i]) ? p.accent : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(Tokens.radius[1]),
                  ),
                  child: Text(it.options[i], style: Tokens.body.style.copyWith(color: choice == it.options[i] ? p.onAccent : ink)),
                ),
              ),
            ],
          ],
        );
      case 'question':
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            title,
            SizedBox(height: Tokens.space[2]),
            if (sent || widget.chosen != null)
              Text(
                l.storyAnswerSent,
                key: const Key('live-answer-sent'),
                style: Tokens.preview.style.copyWith(color: p.accent),
              )
            else
              CupertinoTextField(
                key: const Key('live-answer'),
                controller: answer,
                enabled: widget.onAnswer != null,
                placeholder: l.storyAnswerHint,
                maxLength: 300,
                textInputAction: TextInputAction.send,
                style: Tokens.body.style.copyWith(color: ink),
                decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(Tokens.radius[1])),
                padding: EdgeInsets.all(Tokens.space[2]),
                onSubmitted: (t) async {
                  if (t.trim().isEmpty || widget.onAnswer == null) return;
                  await widget.onAnswer!('❓ ${it.q}\n${t.trim()}');
                  if (mounted) setState(() => sent = true);
                },
              ),
          ],
        );
      default:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.calendar, color: p.accent, size: Tokens.listIcon),
                SizedBox(width: Tokens.space[1]),
                Flexible(child: title),
              ],
            ),
            if (it.when.isNotEmpty || it.place.isNotEmpty) ...[
              SizedBox(height: Tokens.space[0]),
              Text(
                [it.when, it.place].where((x) => x.isNotEmpty).join(' · '),
                textAlign: TextAlign.center,
                style: Tokens.preview.style.copyWith(color: const Color(0x99000000)),
              ),
            ],
            SizedBox(height: Tokens.space[2]),
            GestureDetector(
              key: const Key('live-going'),
              onTap: widget.onAnswer == null || choice != null
                  ? null
                  : () async {
                      setState(() => picked = 'going');
                      await widget.onAnswer!('📅 ${it.q}${it.when.isEmpty ? '' : ' (${it.when})'} — ${l.storyGoing}!');
                    },
              child: Container(
                height: Tokens.closeButton,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: Text(
                  choice != null ? l.storyGoingSent : l.storyGoing,
                  style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
    }
    return Container(
      width: 240,
      padding: EdgeInsets.all(Tokens.space[3]),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(Tokens.radius[2]),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: body,
    );
  }
}

/// Full-screen form for a poll / question / plan (no popup text boxes).
Future<StoryLive?> editLive(BuildContext context, String kind, [StoryLive? old]) => paneNav(context).push<StoryLive>(
  IosPageRoute(
    fullscreenDialog: true,
    builder: (_) => _LiveForm(kind: kind, old: old),
  ),
);

class _LiveForm extends StatefulWidget {
  const _LiveForm({required this.kind, this.old});
  final String kind;
  final StoryLive? old;

  @override
  State<_LiveForm> createState() => _LiveFormState();
}

class _LiveFormState extends State<_LiveForm> {
  late final q = TextEditingController(text: widget.old?.q ?? '');
  late final opts = [for (var i = 0; i < 4; i++) TextEditingController(text: (widget.old?.options.length ?? 0) > i ? widget.old!.options[i] : '')];
  late final when = TextEditingController(text: widget.old?.when ?? '');
  late final place = TextEditingController(text: widget.old?.place ?? '');

  @override
  void initState() {
    super.initState();
    if (widget.old == null && widget.kind == 'poll') {
      opts[0].text = '👍';
      opts[1].text = '👎';
    }
  }

  @override
  void dispose() {
    for (final c in [q, ...opts, when, place]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get ok => q.text.trim().isNotEmpty && (widget.kind != 'poll' || opts.where((c) => c.text.trim().isNotEmpty).length >= 2);

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    Widget field(Key key, TextEditingController c, String hint, {int max = 120}) => CupertinoTextField(
      key: key,
      controller: c,
      placeholder: hint,
      maxLength: max,
      onChanged: (_) => setState(() {}),
      decoration: null,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
      style: Tokens.body.style.copyWith(color: p.label),
    );
    final title = switch (widget.kind) {
      'poll' => l.storyPoll,
      'question' => l.storyQuestion,
      _ => l.storyPlan,
    };
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: title,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('live-done'), onTap: ok ? done : null)],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader),
        children: [
          IosSection(hasLeading: false, children: [field(const Key('live-q'), q, widget.kind == 'plan' ? l.storyPlanTitle : l.storyAskHint)]),
          if (widget.kind == 'poll')
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.storyPollInfo),
              children: [for (var i = 0; i < 4; i++) field(Key('live-opt-$i'), opts[i], l.storyOption(i + 1), max: 40)],
            ),
          if (widget.kind == 'plan')
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.storyPlanInfo),
              children: [field(const Key('live-when'), when, l.storyPlanWhen, max: 60), field(const Key('live-place'), place, l.storyPlanPlace, max: 80)],
            ),
          if (widget.kind == 'question') IosSection(hasLeading: false, footer: sectionFooter(context, l.storyQuestionInfo), children: const []),
        ],
      ),
    );
  }

  void done() {
    final old = widget.old;
    Navigator.of(context).pop(
      StoryLive(
        kind: widget.kind,
        q: q.text.trim(),
        options: [
          for (final c in opts)
            if (c.text.trim().isNotEmpty) c.text.trim(),
        ],
        when: when.text.trim(),
        place: place.text.trim(),
        at: old?.at ?? const Offset(.5, .45),
        scale: old?.scale ?? 1,
      ),
    );
  }
}

// ---------------------------------------------------------------- audience

/// Who sees a story. Close friends are kept on this phone.
class StoryAudience {
  const StoryAudience.all() : mode = 'all', rooms = const [];
  const StoryAudience(this.mode, this.rooms);
  final String mode; // all, close, picked
  final List<String> rooms;

  String label(L l) => switch (mode) {
    'close' => l.storyCloseFriends,
    'picked' => l.storyPickedCount(rooms.length),
    _ => l.storyAllFriends,
  };
}

List<String> closeFriends(AppState s) {
  try {
    return [for (final x in jsonDecode(s.pref('story_close', '[]')) as List) x as String];
  } catch (_) {
    return const [];
  }
}

List<ChatPreview> storyFriends(AppState s) => s.chats.where((c) => c.isDirect && !c.isBot && c.roomId != s.savedRoomId).toList();

Future<StoryAudience?> pickAudience(BuildContext context, StoryAudience now) =>
    paneNav(context).push<StoryAudience>(IosPageRoute(fullscreenDialog: true, builder: (_) => _AudiencePage(now: now)));

class _AudiencePage extends StatefulWidget {
  const _AudiencePage({required this.now});
  final StoryAudience now;

  @override
  State<_AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<_AudiencePage> {
  late String mode = widget.now.mode;
  late Set<String> picked = {...widget.now.rooms};
  late Set<String> close;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    close = {...closeFriends(AppScope.read(context))};
    if (mode != 'picked') picked = {};
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final friends = storyFriends(s);
    Widget option(String m, String title, String sub, IconData icon, Color color) => CupertinoListTile(
      key: Key('aud-$m'),
      leading: iconTile(color, icon),
      title: Text(title),
      subtitle: Text(sub, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
      trailing: mode == m ? Icon(CupertinoIcons.checkmark_alt, color: p.accent) : null,
      onTap: () => setState(() => mode = m),
    );
    final listFor = mode == 'close' ? close : picked;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.storyWho,
        leading: const [GlassBack(close: true)],
        trailing: [
          GlassDone(
            key: const Key('aud-done'),
            onTap: mode == 'picked' && picked.isEmpty
                ? null
                : () async {
                    if (mode == 'close') await s.setPref('story_close', jsonEncode(close.toList()));
                    if (!context.mounted) return;
                    Navigator.of(context).pop(StoryAudience(mode, mode == 'close' ? close.toList() : (mode == 'picked' ? picked.toList() : const [])));
                  },
          ),
        ],
        tint: p.background,
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader),
        children: [
          IosSection(
            footer: sectionFooter(context, l.storyWhoInfo),
            children: [
              option('all', l.storyAllFriends, l.storyAllFriendsSub(friends.length), CupertinoIcons.person_2_fill, Palette.tileBlue),
              option('close', l.storyCloseFriends, l.storyCloseFriendsSub(close.length), CupertinoIcons.star_fill, p.tileGreen),
              option('picked', l.storyPicked, l.storyPickedSub, CupertinoIcons.checkmark_circle_fill, Palette.tileOrange),
            ],
          ),
          if (mode != 'all')
            IosSection(
              header: sectionHeader(context, mode == 'close' ? l.storyCloseFriends : l.storyPicked),
              children: [
                for (final c in friends)
                  CupertinoListTile(
                    key: Key('aud-friend-${c.roomId}'),
                    leadingSize: Tokens.memberAvatar,
                    leading: Avatar(name: c.name, size: Tokens.memberAvatar, userId: c.peer),
                    title: Text(c.name),
                    trailing: Icon(
                      listFor.contains(c.roomId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                      color: listFor.contains(c.roomId) ? p.accent : p.separator,
                    ),
                    onTap: () => setState(() => listFor.contains(c.roomId) ? listFor.remove(c.roomId) : listFor.add(c.roomId)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// 6 / 12 / 24 / 48 hours (24 is the default).
Future<int?> pickHours(BuildContext context, int now) {
  final l = L.of(context);
  return showCupertinoModalPopup<int>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => CupertinoActionSheet(
      title: Text(l.storyHowLong),
      message: Text(l.storyHowLongInfo),
      actions: [
        for (final h in const [6, 12, 24, 48])
          CupertinoActionSheetAction(key: Key('hours-$h'), isDefaultAction: h == now, onPressed: () => Navigator.pop(c, h), child: Text(l.storyHoursN(h))),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
}

// ---------------------------------------------------------------- archive

/// My shared stories, kept only on this phone (never sent anywhere else).
/// The web keeps none (a browser is no safe place for them).
class StoryArchive {
  static bool get supported => !kIsWeb;

  /// Tests point this somewhere temporary.
  static Directory? dirOverride;

  static Future<Directory> _dir() async {
    final base = dirOverride ?? await getApplicationSupportDirectory();
    final d = Directory('${base.path}/story_archive');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static Future<void> keep(String name, List<int> bytes, String caption) async {
    if (!supported) return;
    try {
      final d = await _dir();
      final id = DateTime.now().millisecondsSinceEpoch;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpg';
      await File('${d.path}/$id.$ext').writeAsBytes(bytes, flush: true);
      if (caption.trim().isNotEmpty) await File('${d.path}/$id.txt').writeAsString(caption.trim());
    } catch (_) {}
  }

  /// Newest first: (file, time, caption).
  static Future<List<(File, DateTime, String)>> list() async {
    if (!supported) return const [];
    try {
      final d = await _dir();
      final out = <(File, DateTime, String)>[];
      await for (final f in d.list()) {
        if (f is! File || f.path.endsWith('.txt')) continue;
        final name = f.uri.pathSegments.last;
        final id = int.tryParse(name.split('.').first);
        if (id == null) continue;
        final cap = File('${d.path}/$id.txt');
        out.add((f, DateTime.fromMillisecondsSinceEpoch(id), await cap.exists() ? await cap.readAsString() : ''));
      }
      out.sort((a, b) => b.$2.compareTo(a.$2));
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> remove(File f) async {
    try {
      await f.delete();
      final id = f.uri.pathSegments.last.split('.').first;
      final cap = File('${f.parent.path}/$id.txt');
      if (await cap.exists()) await cap.delete();
    } catch (_) {}
  }
}

/// 내 스토리 보관함: a grid; tap one to share it again.
class StoryArchivePage extends StatefulWidget {
  const StoryArchivePage({super.key, required this.onReuse});

  /// Opens the composer with this picture (name, bytes).
  final void Function((String, List<int>) file) onReuse;

  @override
  State<StoryArchivePage> createState() => _StoryArchivePageState();
}

class _StoryArchivePageState extends State<StoryArchivePage> {
  List<(File, DateTime, String)>? items;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final x = await StoryArchive.list();
    if (mounted) setState(() => items = x);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = items;
    return CupertinoPageScaffold(
      key: const Key('story-archive'),
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.storyArchive, leading: const [GlassBack()], tint: p.background),
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.sheetHeader),
        child: !StoryArchive.supported || (list != null && list.isEmpty)
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(Tokens.space[5]),
                  child: Text(
                    StoryArchive.supported ? l.storyArchiveEmpty : l.storyArchiveWeb,
                    key: const Key('story-archive-empty'),
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                ),
              )
            : list == null
            ? const Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[4], 0, Tokens.space[4], Tokens.space[2]),
                    child: Text(l.storyArchiveInfo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  ),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      childAspectRatio: 9 / 16,
                      children: [
                        for (final (f, t, _) in list)
                          GestureDetector(
                            key: Key('archive-${t.millisecondsSinceEpoch}'),
                            onTap: () async {
                              final b = await f.readAsBytes();
                              widget.onReuse((f.uri.pathSegments.last, b));
                            },
                            onLongPress: () async {
                              await StoryArchive.remove(f);
                              await load();
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                isStoryVideo(f.path)
                                    ? ColoredBox(
                                        color: p.incoming,
                                        child: Icon(CupertinoIcons.play_fill, color: p.secondaryLabel),
                                      )
                                    : Image.file(f, fit: BoxFit.cover, cacheWidth: 300),
                                Positioned(
                                  left: Tokens.space[1],
                                  bottom: Tokens.space[1],
                                  child: Text(
                                    '${t.month}/${t.day}',
                                    style: Tokens.caption.style.copyWith(
                                      color: const Color(0xFFFFFFFF),
                                      shadows: const [Shadow(color: Color(0x99000000), blurRadius: 4)],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
