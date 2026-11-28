// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// One chat: bubbles + composer (iOS "+" on the left, brand send circle).
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core/login_safety.dart';
import '../core/features.dart';
import 'emoji_status.dart' show StatusMark;
import '../core/channel_dm.dart';
import '../core/next_channel.dart';
import 'quote_block.dart';
import 'jump_buttons.dart';
import '../core/chat_marks.dart';
import '../core/my_pins.dart';
import '../core/video_resume.dart';
import '../core/codes.dart';
import '../core/ai_styles.dart';
import '../core/app_state.dart';
import '../core/looks.dart';
import '../core/downloads.dart';
import '../core/draft_sync.dart';
import '../core/my_sounds.dart';
import '../core/backend.dart';
import '../core/group_tools.dart';
import '../core/room_rules.dart';
import '../core/room_texts.dart';
import 'name_colors.dart';
import 'welcome.dart';
import 'dust_out.dart';
import 'room_rules_pages.dart' show MentionList, explainStrike, permLabel, pickPin, pickPinFor, pickPinTime;
import 'pinned_list.dart';
import 'next_channel_hint.dart';
import 'channel_inbox.dart';
import 'quick_forward.dart';
import 'invite_links.dart' show openJoinLink;
import 'send_as.dart';
import 'share_sheet.dart';
import 'file_viewer.dart';
import 'light_video.dart';
import 'downloads_ui.dart' show sizeOf;
import 'media_editor.dart' show editChatPhoto;
import 'media_bubbles.dart';
import 'media_sizes.dart';
import 'live_photo.dart';
import '../core/live_photo.dart' show LiveStyle, Mp4Meta;
import 'gallery_save.dart';
import 'login_safety_ui.dart';

import 'story_video.dart' show storyMime;
import 'video_note.dart';
import 'earlier_messages.dart';
import 'chat_import_ui.dart';
import '../core/imported.dart' show mergeImported;
import 'unread_summary.dart';
import 'voice_text.dart';
import 'post_summary.dart';
import 'reader_page.dart';
import 'music_player.dart';
import '../core/audio_dock.dart' show AudioDock;
import '../core/search.dart' show isMusic;
import '../core/ai_local.dart';
import '../core/reader.dart';
import '../core/link_check.dart';
import '../core/voice.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'moving_emoji.dart';
import 'common.dart';
import 'trust_ui.dart';
import '../core/automod.dart' show hasLinkText;
import '../core/guard.dart';
import '../core/trust.dart';
import 'stories.dart' show showStoryToast, postToStory;
import 'links.dart';
import 'wallpaper.dart';
import 'look_studio.dart';
import 'look_pages.dart' show pickTimer, timerText;
import 'ios.dart';
import 'first_hello.dart';
import 'formatting.dart';
import 'gif_tab.dart' show GifTab, GifLayerOver;
import 'schedule_send.dart';
import 'send_fly.dart';
import 'compose_options.dart';
import 'glass.dart';
import 'message_menu.dart';
import 'message_sheets.dart';
import '../core/reminders.dart';
import '../core/read_times.dart';
import '../core/room_links.dart' show LinkTarget, MessageLink;
import '../core/saved_tags.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../core/screen_guard.dart';
import '../core/shot_alert.dart';
import '../core/memories.dart';
import 'memories_ui.dart' show MemoriesBar;
import 'chat_row_actions.dart' show showInfoBanner;
import '../brand/mark.dart';
import '../core/effects.dart';
import 'ai_editor.dart';
import 'custom_emoji_ui.dart';
import 'effects.dart';
import '../core/custom_emoji.dart';
import '../stickers/cx_emoji_view.dart';
import 'article.dart';
import 'attach_sheet.dart';
import 'bubbles.dart';
import 'cards.dart';
import 'checklist.dart';
import 'chat_safety.dart';
import '../core/report_reasons.dart';
import 'location.dart';
import 'meetup.dart';
import 'call_page.dart';
import 'poll.dart';
import 'photo_suggest.dart';
import 'profile_page.dart';
import 'room_tools.dart';
import 'saved_page.dart';
import 'sticker_panel.dart';
import 'sized_by_media.dart';
import 'text_sticker.dart';
import 'sticker_maker.dart';
import 'verify_page.dart';
import '../stickers/catalog.dart';
import '../stickers/char_emoji.dart';
import '../core/translate.dart';
import 'translate_ui.dart';
import 'ios_route.dart';
import 'swipe_reply.dart';
import 'wide.dart';
import 'community.dart' show CommunityCardBubble;
import 'back_trail.dart';
import 'album.dart';
import 'photo_stickers.dart' show pickSwapMedia;
import 'pinch_zoom.dart';
import '../core/gifs.dart';
import '../core/media_tags.dart';
import 'photo_viewer.dart';
import '../core/phone.dart' show Phone;
import '../core/photo_size.dart';
import 'ai_age_ui.dart';
import '../core/topics.dart';
import 'topics.dart';
import '../core/suggest_post.dart';
import 'suggest_post.dart';
import 'emoji_suggest.dart';
import 'sticker_sets_ui.dart' show StickerSetBubble;

/// Opens a chat over the whole screen (tab bar hidden, like Telegram).
/// Message links (tip 302): a link tapped inside the chat that is already
/// open asks that chat to scroll to the message.
final chatJump = ValueNotifier<(String, String)?>(null);

Future<void> openChat(BuildContext context, String roomId, String title, {String? jump, String? dmInbox, bool up = false}) async {
  final s = AppScope.read(context);
  if (s.on('marked_unread:$roomId')) unawaited(s.setOn('marked_unread:$roomId', false));
  if (Wide.on) {
    // Two panes: the chat shows on the right, in place of the last one.
    s.openRoom = roomId;
    ChatTrail.shown(roomId);
    await Wide.show(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: roomId, title: title, jump: jump, dmInbox: dmInbox),
      ),
      roomId: roomId,
    );
    if (Wide.selected.value == null && s.openRoom == roomId) s.openRoom = null;
    return;
  }
  final before = s.openRoom;
  s.openRoom = roomId;
  final route = IosPageRoute<void>(
    enterUp: up,
    builder: (_) => ChatPage(roomId: roomId, title: title, jump: jump, dmInbox: dmInbox),
  );
  final trail = (roomId, route);
  ChatTrail.stack.add(trail);
  try {
    await paneNav(context).push(route);
  } finally {
    ChatTrail.stack.remove(trail);
    s.openRoom = before;
  }
}

/// 다른 대화에서 답장 (Telegram tip 399): the quote waiting for the chat it
/// was sent to, with what was typed so far. Lives only in memory.
class CrossReply {
  const CrossReply(this.roomId, this.quote, this.typed);
  final String roomId;
  final Msg quote;
  final String typed;
  static CrossReply? pending;

  /// The waiting quote for [roomId] (taken once).
  static CrossReply? take(String roomId) {
    final p = pending;
    if (p == null || p.roomId != roomId) return null;
    pending = null;
    return p;
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.roomId, required this.title, this.jump, this.topic, this.dmInbox});
  final String roomId;
  final String title;

  /// 주제 (tip 527, 목록 view): this page shows only this topic.
  final String? topic;

  /// 문의함 (tip 526): opened from a channel's 메시지 row (that channel's
  /// id); the other subscribers show as tabs.
  final String? dmInbox;

  /// Message to scroll to once the chat opens (message links).
  final String? jump;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Msg> msgs = const [];

  /// The first load finished (no hello card flashing before it).
  bool loadedOnce = false;
  DateTime? readUntil;

  /// 289: my just-sent messages still flying in.
  final flyIds = <String>{};
  final input = Features.tipsLink ? ComposeController() : EmojiTextController();
  AppState? state;
  bool get veiled => state != null && veilOf(state!, widget.roomId).isNotEmpty;

  /// Composer modes: answering one message, or fixing my own.
  Msg? replying;
  Msg? editing;

  /// Fixing a photo message (tips 452 B, 482, 81, 224): a new file picked
  /// for it (null = keep), and the words above or under.
  List<int>? editBytes;
  String? editName;
  bool editAbove = false;

  /// Public group or channel: a sent photo can't be swapped there.
  bool publicRoom = false;
  bool canPost = true;
  bool isGroup = false;
  bool isChannel = false;

  /// Channel posts show who wrote them (admin switch "서명 남기기").
  bool signed = false;
  List<String> typers = const [];
  bool stickersOpen = false;
  int timerSecs = 0;
  Timer? tick;
  List<String> pins = const [];

  /// Pinned for me only (on this phone, tip 276).
  List<String> myPins = const [];

  /// Which pin the top bar shows (index into [pins]; null = the newest).
  int? pinAt;

  /// Search inside this chat (done on the phone).
  bool searching = false;
  final searchInput = TextEditingController();
  List<Msg> hits = const [];
  int hitAt = 0;
  bool searched = false;
  String? focusId;
  int limit = 50;

  /// 다른 앱 대화 가져오기: messages of import cards (card id → bubbles),
  /// the chat's own loaded messages, and how many older imported ones show
  /// (more as I scroll up).
  final imports = <String, List<Msg>>{};
  final importBy = <String, String>{};
  final importLoading = <String>{};
  List<Msg> ownMsgs = const [];
  int importShown = 300;

  List<Msg> withImports() {
    if (imports.isEmpty) return ownMsgs;
    final all = [for (final l in imports.values) ...l]..sort((a, b) => a.time.compareTo(b.time));
    return mergeImported(ownMsgs, all, complete: true, olderLimit: importShown);
  }

  int get importHidden {
    final n = imports.values.fold<int>(0, (a, l) => a + l.length);
    return n - (msgs.length - ownMsgs.length);
  }

  /// Import cards this chat has (remembered, so they stay when 50 newer
  /// messages push the card out of the loaded part).
  Set<String> get knownImports => state!.pref('imports:${widget.roomId}', '').split(',').where((x) => x.isNotEmpty).toSet();

  void fetchImports(List<Msg> m) {
    final b = state!.backend;
    final cards = {
      for (final x in m)
        if (x.kind == 'card' && x.card?.kind == 'import') x.id,
    };
    final known = knownImports;
    // A card that should be in the loaded part but isn't was deleted.
    final oldest = m.isEmpty ? null : m.first.time;
    final gone = {
      for (final id in known)
        if (!cards.contains(id) &&
            (m.length < limit || (imports[id]?.isNotEmpty == true && oldest != null && importCardTime[id] != null && !importCardTime[id]!.isBefore(oldest))))
          id,
    };
    for (final x in m) {
      if (cards.contains(x.id)) importCardTime[x.id] = x.time;
    }
    final want = {...cards, ...known.difference(gone)};
    final next = want.join(',');
    if (next != known.join(',') && (cards.difference(known).isNotEmpty || gone.isNotEmpty)) unawaited(state!.setPref('imports:${widget.roomId}', next));
    if (gone.isNotEmpty && mounted) {
      setState(() {
        for (final id in gone) {
          imports.remove(id);
        }
        msgs = withImports();
      });
    }
    for (final id in want) {
      if (imports.containsKey(id) || !importLoading.add(id)) continue;
      unawaited(
        b.importedMessages(widget.roomId, id).then((c) {
          importLoading.remove(id);
          if (!mounted) return;
          setState(() {
            imports[id] = c.toMsgs(id, b.userId);
            importBy[id] = c.by;
            msgs = withImports();
          });
        }, onError: (_) => importLoading.remove(id)),
      );
    }
  }

  final importCardTime = <String, DateTime>{};
  final listKey = GlobalKey();
  final scroll = ScrollController();
  final msgKeys = <String, GlobalKey>{};
  String? notice;
  Timer? noticeTimer;

  static const quickReactions = ['❤️', '👍', '😂', '😮', '😢', '🙏'];

  /// Group/channel settings from the admin tools, and my role there.
  Map<String, dynamic> cfg = const {};
  String role = 'member';

  /// Members by id (roles, join time) for the new-member limit and alerts.
  Map<String, Member> memberOf = const {};

  // ---- 채널에 글 제안 (tip 531; core/suggest_post.dart) ----
  /// This chat is a channel's admin chat (tip 526) and I'm its subscriber.
  String? get suggestChannel => SuggestPost.channelOf(cfg);
  bool get suggestFromMe => suggestChannel != null && SuggestPost.subscriberOf(cfg) == state!.backend.userId;

  Future<void> openSuggest() async {
    final ch = suggestChannel;
    if (ch == null) return;
    final sent = await Navigator.of(context).push<bool>(
      IosPageRoute(
        builder: (_) => SuggestPostPage(dmRoom: widget.roomId, channel: ch),
      ),
    );
    if (sent == true && mounted) {
      await load();
      if (mounted) showNotice(L.of(context).suggestSent);
    }
  }

  Widget? suggestRow(BuildContext context, Msg m) {
    if (m.kind != 'card') return null;
    if (m.card?.kind == 'suggest_deal') return SuggestDealLine(msg: m);
    if (m.card?.kind != 'suggest') return null;
    return SuggestCard(
      roomId: widget.roomId,
      msg: m,
      deal: SuggestPost.dealFor(msgs, m.id),
      admin: isAdmin && !m.mine,
      name: memberOf[m.sender]?.name ?? displayId(m.sender),
      onChanged: load,
    );
  }

  // ---- 주제 (group topics, tip 527; core/topics.dart, ui/topics.dart) ----
  Topics topics = const Topics();

  /// Topic shown now: Topics.all (모두), 'g' (일반) or a topic id.
  late String topicNow = widget.topic ?? Topics.all;

  /// The room's read mark when this chat opened (unread per topic before
  /// any topic was looked at on this phone).
  DateTime? topicBase;
  bool get topicsOn => isGroup && !isChannel && topics.on && !isSaved;
  bool get topicListMode => topicsOn && topics.view == Topics.listView && widget.topic == null;
  bool get topicRail => topicsOn && topics.view == Topics.tabs && widget.topic == null && !state!.on('topic_bar:${widget.roomId}');
  bool get topicTabs => topicsOn && topics.view == Topics.tabs && widget.topic == null && state!.on('topic_bar:${widget.roomId}');
  bool get canManageTopics => topicsOn && Topics.canManage(cfg, role, state!.backend.userId ?? '');

  /// The topic my words go to here (모두 → 일반).
  String get sendTopic => !topicsOn || topicNow == Topics.all ? Topics.general : topicNow;
  Topic get sendTopicItem => topics.byId(sendTopic) ?? const Topic(id: Topics.general);

  /// A closed topic: only admins write in it.
  bool get topicLocked => topicsOn && sendTopicItem.closed && !isAdmin;

  void syncSendTopic() {
    if (state == null) return;
    state!.backend.setSendTopic(widget.roomId, topicsOn ? sendTopic : null);
  }

  bool inTopic(Msg m) => !topicsOn || topicNow == Topics.all || topics.topicOf(m) == topicNow;

  Map<String, int> get topicUnread => topicsOn ? topics.unread(msgs, Topics.seen(state!, widget.roomId), topicBase) : const {};

  /// Looked at: this topic's messages count as read on this phone.
  void seeTopic() {
    if (!topicsOn || topicNow == Topics.all || msgs.isEmpty) return;
    final last = msgs.lastWhere(inTopic, orElse: () => msgs.last);
    unawaited(Topics.markSeen(state!, widget.roomId, [topicNow], last.time));
  }

  void pickTopic(String id) {
    if (id == topicNow) return;
    setState(() {
      topicNow = id;
      replying = null;
    });
    syncSendTopic();
    seeTopic();
  }

  Future<void> openTopicPage(Topic t) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ChatPage(roomId: widget.roomId, title: widget.title, topic: t.id),
      ),
    );
    syncSendTopic();
    if (mounted) await load();
  }

  /// Admins: a new topic (from the rail, bar or list).
  Future<void> addTopic() async {
    final got = await editTopic(context, null);
    if (got == null || !mounted) return;
    final base = topics.list.isEmpty ? const [Topic(id: Topics.general)] : topics.list;
    await Topics.save(state!, widget.roomId, topics.copyWith(list: [...base, got]));
    await load();
    if (!mounted) return;
    showNotice(L.of(context).topicCreated(got.name));
    if (topics.view == Topics.tabs) pickTopic(got.id);
  }

  /// Admins: hold a topic to change it or close it.
  Future<void> holdTopic(Topic t) async {
    if (!canManageTopics) return;
    final got = await editTopic(context, t);
    if (got == null || !mounted) return;
    final l = L.of(context);
    await Topics.save(state!, widget.roomId, topics.copyWith(list: [for (final x in topics.list) x.id == got.id ? got : x]));
    await load();
    if (mounted) showNotice(got.closed != t.closed ? (got.closed ? l.topicClosedNotice : l.topicReopenedNotice) : l.topicSaved);
  }

  Widget topicNav(BuildContext context, {required bool rail}) {
    final args = (
      topics: topics,
      current: topicNow,
      unread: topicUnread,
      onPick: pickTopic,
      onSwitch: () async {
        await state!.setOn('topic_bar:${widget.roomId}', rail);
        if (mounted) setState(() {});
      },
    );
    return rail
        ? TopicRail(
            topics: args.topics,
            current: args.current,
            unread: args.unread,
            onPick: args.onPick,
            onSwitch: args.onSwitch,
            onAdd: canManageTopics ? addTopic : null,
            onHold: canManageTopics ? holdTopic : null,
          )
        : TopicBar(
            topics: args.topics,
            current: args.current,
            unread: args.unread,
            onPick: args.onPick,
            onSwitch: args.onSwitch,
            onAdd: canManageTopics ? addTopic : null,
            onHold: canManageTopics ? holdTopic : null,
          );
  }

  /// In 모두: a topic line above the first message of each run of a topic.
  Widget withTopicLine(List<Msg> rows, int i, Widget child) {
    if (!topicsOn || topicNow != Topics.all || i >= rows.length) return child;
    final at = rows.length - 1 - i;
    final m = rows[at];
    if (m.kind == 'welcome' || m.imported != null) return child;
    final t = topics.topicOf(m);
    final prev = at > 0 ? rows[at - 1] : null;
    if (prev != null && prev.kind != 'welcome' && topics.topicOf(prev) == t) return child;
    final topic = topics.byId(t);
    if (topic == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TopicLine(topic: topic, onTap: () => topics.view == Topics.listView ? openTopicPage(topic) : pickTopic(t)),
        child,
      ],
    );
  }

  /// A public room the operator's guard checks (so not "nobody can read it").
  bool get guarded {
    final g = state?.trust.guard ?? '';
    return g.isNotEmpty && memberOf.containsKey(g);
  }

  Set<String> get adminIds => {
    for (final m in memberOf.values)
      if (m.role == 'owner' || m.role == 'admin') m.userId,
  };

  /// 협박 공격 막기: edits only within 24 h in groups/channels.
  /// A photo, video or file of mine that 수정 can change (not view-once,
  /// 움직이는 사진, round video or voice).
  bool mediaEditable(Msg m) =>
      (m.kind == 'image' || m.kind == 'video' || m.kind == 'file') && !m.viewOnce && m.live == null && !m.bubble && !isVideoNote(m.body);

  /// Editing words only (a text, nothing picked for it).
  bool get editingWordsOnly => editing != null && editing!.kind == 'text' && editBytes == null;

  /// 사진 수정 options from the edit bar: another photo, edit this one,
  /// words above/under, or a photo for a text.
  Future<void> editMediaOptions() async {
    final m = editing;
    if (m == null) return;
    final l = L.of(context);
    final media = m.kind != 'text' || editBytes != null;
    final isPhoto = editBytes != null ? mimeOf(editName ?? '').startsWith('image/') : m.kind == 'image';
    CupertinoActionSheetAction row(BuildContext c, String id, String label) =>
        CupertinoActionSheetAction(key: Key('edit-media-$id'), onPressed: () => Navigator.pop(c, id), child: Text(label));
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        key: const Key('edit-media-sheet'),
        message: publicRoom ? Text(l.noSwapPublic) : null,
        actions: [
          if (!publicRoom && media) row(c, 'swap', l.editSwapPhoto),
          if (!publicRoom && isPhoto) row(c, 'draw', l.editThisPhoto),
          if (!publicRoom && !media) row(c, 'add', l.editAddPhoto),
          if (media) row(c, 'above', editAbove ? l.captionDown : l.captionUp),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    switch (pick) {
      case 'swap' || 'add':
        final got = await pickSwapMedia();
        if (got == null || !mounted) return;
        setState(() {
          editName = got.$1;
          editBytes = got.$2;
        });
      case 'draw':
        final now = editBytes != null ? Uint8List.fromList(editBytes!) : Uint8List.fromList(await state!.backend.downloadFile(widget.roomId, m.fileId));
        if (!mounted) return;
        final out = await editChatPhoto(context, now);
        if (out == null || !mounted) return;
        setState(() {
          editBytes = out;
          editName = 'edited-${DateTime.now().millisecondsSinceEpoch}.png';
        });
      case 'above':
        setState(() => editAbove = !editAbove);
    }
  }

  bool canEditNow(Msg m) => editWindowOpen(group: isGroup || isChannel, sent: m.time, now: state!.backend.clock);

  /// New members' photos/videos/links stay hidden while the room's limit is on.
  int get mediaDays => isGroup || isChannel ? newMediaDays(cfg) : 0;
  bool hiddenForNew(Msg m) => !isAdmin && hideForNewMember(m, memberOf[m.sender], mediaDays, now: state!.backend.clock);
  bool get isAdmin => role == 'owner' || role == 'admin';

  /// Pinning: admins by their rights, members by 멤버 권한.
  bool get canPin => !(isGroup || isChannel) || (isAdmin ? RoomRules.can(cfg, role, state!.backend.userId ?? '', 'pin') : RoomRules.memberMay(cfg, 'pin'));

  /// Word typed after "@" (members to pick), null when not mentioning.
  String? mentionQ;
  String myName = '';

  /// 380: members whose text is switched off see a locked composer.
  bool get textLocked => Features.chatSafety && isGroup && !mayDo('text');

  /// v1 group rules: what members may send, slow mode, mutes.
  bool mayDo(String perm) => !(isGroup) || RoomRules.may(cfg, role, perm, userId: Features.chatSafety ? state!.backend.userId : null);

  /// "관리자가 {시간}까지 메시지를 막았어요".
  String mutedText(L l) {
    final until = RoomRules.muteUntil(cfg, state!.backend.userId ?? '');
    if (until == null || until.year >= 9999) return l.mutedForever;
    return l.mutedUntil(DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(until));
  }

  /// Says why it can't be sent and returns true when a rule stops it.
  bool ruleBlocks(String perm) {
    final l = L.of(context);
    if (!mayDo(perm)) {
      // 380: say which kind is blocked.
      showNotice(Features.chatSafety && RoomRules.mediaKinds.contains(perm) ? l.permKindBlocked(permLabel(l, perm)) : l.permBlocked);
      return true;
    }
    if (isGroup) {
      final night = RoomRules.nightUntil(cfg, role, state!.backend.clock);
      if (night != null) {
        showNotice(l.nightBlocked(night));
        return true;
      }
      final last = msgs.where((m) => m.mine).lastOrNull?.time;
      final wait = RoomRules.slowWait(cfg, role, last, state!.backend.clock);
      if (wait != null) {
        showNotice(l.slowWait(wait.inSeconds + 1));
        return true;
      }
    }
    return false;
  }

  /// My messages that mention me or answer me (멘션·답장 필터).
  List<Msg> get myMentions {
    final me = state!.backend.userId ?? '';
    final mine = {
      for (final m in msgs)
        if (m.mine) m.id,
    };
    return [
      for (final m in msgs.reversed)
        if (!m.mine && (RoomRules.mentionsMe(m.body ?? "", me, myName) || (m.replyTo != null && mine.contains(m.replyTo)))) m,
    ];
  }

  /// 검색 필터 (v1): only photos, videos, files, links or voice messages,
  /// newest first. Loads older history (up to 2000) to look through.
  static const searchKinds = ['photo', 'video', 'file', 'link', 'voice'];

  bool isKind(Msg m, String kind) => switch (kind) {
    'photo' => m.kind == 'image' && !m.viewOnce,
    'video' => m.kind == 'video' && !m.viewOnce,
    'file' => m.kind == 'file',
    'link' => hasLink(m),
    'voice' => m.kind == 'audio',
    _ => false,
  };

  Future<void> pickSearchKind() async {
    final l = L.of(context);
    final names = {'photo': l.kindPhoto, 'video': l.kindVideo, 'file': l.kindFile, 'link': l.kindLink, 'voice': l.kindVoice};
    final kind = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.searchFilter),
        actions: [
          for (final k in searchKinds) CupertinoActionSheetAction(key: Key('search-kind-$k'), onPressed: () => Navigator.pop(c, k), child: Text(names[k]!)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (kind == null || !mounted) return;
    while (limit < 2000 && msgs.length >= limit) {
      limit *= 2;
      await load();
    }
    final found = [
      for (final m in msgs.reversed)
        if (isKind(m, kind)) m,
    ];
    if (!mounted) return;
    setState(() {
      hits = found;
      hitAt = 0;
      searched = true;
    });
    if (found.isNotEmpty) unawaited(jumpTo(found.first.id));
  }

  void showMentions() {
    final found = myMentions;
    setState(() {
      hits = found;
      hitAt = 0;
      searched = true;
    });
    if (found.isNotEmpty) unawaited(jumpTo(found.first.id));
  }

  /// Puts the picked name in place of "@what-was-typed".
  void pickMention(String name) {
    final t = input.text;
    final at = input.selection.baseOffset < 0 ? t.length : input.selection.baseOffset;
    final start = t.substring(0, at).lastIndexOf('@');
    if (start < 0) return;
    final word = name.startsWith('@') ? name : '@$name';
    final out = '${t.substring(0, start)}$word ${t.substring(at)}';
    input.text = out;
    input.selection = TextSelection.collapsed(offset: start + word.length + 1);
    setState(() => mentionQ = null);
  }

  bool get hideCounts => hideCountsFor(cfg, role);

  /// Reactions the room allows (admins' choice), for the menu.
  List<String> get menuReactions => (allowedReactions(cfg) ?? quickReactions).take(6).toList();

  /// Shown reactions: only allowed ones, at most the room's maximum.
  List<Reaction> shownReactions(Msg m) {
    final ok = allowedReactions(cfg);
    final list = ok == null ? m.reactions : m.reactions.where((r) => ok.contains(r.key)).toList();
    return list.take(reactionsMax(cfg)).toList();
  }

  /// New members must agree to the rules before writing (when asked).
  bool get mustAgree => cfg['rules_agree'] == true && roomTexts.hasRules && !isAdmin && !state!.on('agreed:${widget.roomId}');

  /// A delete waits 5 seconds so it can be undone.
  /// Messages waiting out the 5 s undo before they are deleted.
  List<String>? pendingDelete;
  int undoLeft = 0;
  Timer? undoTimer;

  /// Settings > Privacy > Undo send: the text waits here for 5 seconds.
  (String, Msg?)? pendingSend;
  LinkChoice? pendingLink;

  /// 메시지 효과 (tip 451): picked on the send menu for the next text, and
  /// the one riding with the text that waits out 보내기 취소.
  String? nextFx, pendingFx;

  /// Big-emoji taps from the friend's phone while this chat is open (355).
  StreamSubscription<(String, FxKind)>? fxLive;

  /// Tip 400: how the link card of the message being typed is set up.
  LinkChoice linkChoice = const LinkChoice();

  /// Settings > Link previews (checked once when the chat opens).
  bool previewsOn = true;

  /// Cards read for the links being typed (url → card).
  final linkCards = <String, Future<StoryLinkInfo?>>{};
  Future<StoryLinkInfo?> linkCard(String url) => linkCards.putIfAbsent(url, () => state!.backend.storyLinkCard(url).catchError((_) => null));

  /// The links in the field when the link line shows (tip 400), else none.
  List<String> get typedLinks =>
      Features.tipsLink && editing == null && previewsOn && !linkChoice.off ? linksIn(input.text).where(settledLinks.contains).toList() : const [];

  /// Links that stayed in the field for a moment (see [onTyped]).
  List<String> settledLinks = const [];
  Timer? linkSettle;
  int sendLeft = 0;
  Timer? sendTimer;
  Timer? typingIdle;
  DateTime typingSent = DateTime(2000);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s != state) {
      state?.removeListener(load);
      state = s..addListener(load);
      if (Features.funFx) {
        // 직접 만든 이모지 (354): this account's pictures; a tap saves one.
        CustomEmojis.load(s);
        CxEmojiView.onTap ??= showCxSave;
      }
      fxLive ??= Features.funFx
          ? MsgFx.live.stream.listen((e) {
              if (mounted && e.$1 == widget.roomId) playFx(context, e.$2);
            })
          : null;
      // 안 읽은 대화 AI 요약: how many were waiting when I opened the chat.
      unreadAtOpen = s.chats.where((c) => c.roomId == widget.roomId).firstOrNull?.unread ?? 0;
      // 쓰다 만 글: what I left typed here comes back.
      final draft = s.pref('draft:${widget.roomId}', '');
      if (draft.isNotEmpty && input.text.isEmpty) input.text = draft;
      takeOtherDraft(open: true);
      settledLinks = linksIn(input.text);
      if (Features.tipsLink) {
        unawaited(
          s.backend
              .linkPreviewsEnabled()
              .then((v) {
                if (mounted && v != previewsOn) setState(() => previewsOn = v);
              })
              .catchError((_) {}),
        );
      }
      // 다른 대화에서 답장 (tip 399): the quote (and words typed) come along.
      final cross = CrossReply.take(widget.roomId);
      if (cross != null) {
        replying = cross.quote;
        if (cross.typed.isNotEmpty) input.text = cross.typed;
      }
      unawaited(
        load().then((_) {
          if (widget.jump != null && mounted) unawaited(jumpTo(widget.jump!));
        }),
      );
      chatJump.addListener(onChatJump);
      scroll.addListener(onScroll);
      // Messages with a timer disappear on time even without news.
      tick ??= Timer.periodic(const Duration(seconds: 30), (_) => load());
    }
  }

  @override
  void dispose() {
    chatJump.removeListener(onChatJump);
    // Keep what was typed but not sent (shown in the chat list, v1), and
    // pass it to my other devices (tip 241).
    final st = state;
    draftTimer?.cancel();
    if (st != null) {
      final now = draftNow;
      // After this frame: the tree is locked while a page is taken down.
      if (now != st.pref('draft:${widget.roomId}', '')) scheduleMicrotask(() => unawaited(st.saveDraft(widget.roomId, now).catchError((_) {})));
    }
    state?.removeListener(load);
    // 주제: words sent from elsewhere (share, forward) go to 일반.
    if (widget.topic == null) state?.backend.setSendTopic(widget.roomId, null);
    unawaited(fxLive?.cancel());
    undoTimer?.cancel();
    typingIdle?.cancel();
    tick?.cancel();
    noticeTimer?.cancel();
    recTick?.cancel();
    recLevelSub?.cancel();
    final r = recorder;
    if (r != null) unawaited(r.cancel());
    searchInput.dispose();
    scroll.dispose();
    for (final d in pendingDelete ?? const <String>[]) {
      unawaited(state!.backend.deleteMessage(widget.roomId, d).catchError((_) {}));
    }
    sendTimer?.cancel();
    quickTimer?.cancel();
    final pq = pendingQuick;
    if (pq != null) unawaited(state!.backend.forward(widget.roomId, pq.$1.id, pq.$2.roomId).catchError((_) {}));
    linkSettle?.cancel();
    final ps = pendingSend;
    if (ps != null) unawaited(_deliver(state!.backend, ps.$1, ps.$2, pendingLink).catchError((_) {}));
    super.dispose();
  }

  /// 안 본 멘션·반응 (tips 249/320): ids still to be seen, oldest first.
  List<String> unseenMentions = const [], unseenReactions = const [];

  /// Seen on screen this frame (written together after it).
  final seenNow = <String>{};
  bool seenFlush = false;

  /// A jump is walking through the chat: what flies past isn't "seen".
  bool walking = false;

  /// Scrolled up from the newest: the ↓ button shows.
  bool awayFromEnd = false;

  /// Works out what is still unseen here (first time: unread mentions only).
  void markUnseen(List<Msg> all) {
    if (!Features.tipsReply || isSaved) return;
    final row = state!.chats.where((c) => c.roomId == widget.roomId).firstOrNull;
    if (row == null) return;
    final key = ChatMarks.key(widget.roomId);
    var st = MarkState.decode(state!.pref(key, ''));
    if (st == null) {
      st = ChatMarks.start(all, unreadAtOpen, state!.backend.clock);
      final raw = st.encode();
      scheduleMicrotask(() => unawaited(state!.setPref(key, raw).catchError((_) {})));
    }
    final me = state!.backend.userId ?? '';
    unseenMentions = ChatMarks.mentionsCount(row) ? [for (final m in ChatMarks.mentions(all, st, me, myName)) m.id] : const [];
    unseenReactions = ChatMarks.reactionsCount(row) ? [for (final m in ChatMarks.reactions(all, st)) m.id] : const [];
  }

  /// A message with an unseen mention / reaction was built. The list also
  /// builds bubbles just past the screen edge, so it only counts as seen
  /// once at least half of it (or half the screen) is really on screen.
  void noteSeen(String id) {
    if (walking || !(unseenMentions.contains(id) || unseenReactions.contains(id))) return;
    seenNow.add(id);
    checkSeen();
  }

  /// After this frame: which waiting bubbles are on screen now.
  void checkSeen() {
    if (seenFlush || seenNow.isEmpty) return;
    seenFlush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      seenFlush = false;
      if (!mounted || walking) return;
      final ids = {
        for (final id in seenNow)
          if (onScreen(id)) id,
      };
      seenNow.removeWhere((id) => ids.contains(id) || !(unseenMentions.contains(id) || unseenReactions.contains(id)));
      if (ids.isNotEmpty) markSeen(ids);
    });
  }

  bool onScreen(String id) {
    final box = msgKeys[id]?.currentContext?.findRenderObject();
    final list = listKey.currentContext?.findRenderObject();
    if (box is! RenderBox || list is! RenderBox || !box.attached || !box.hasSize || !list.hasSize) return false;
    final r = box.localToGlobal(Offset.zero) & box.size;
    final v = list.localToGlobal(Offset.zero) & list.size;
    final shown = r.intersect(v).height;
    return shown > 0 && shown >= (r.height < v.height ? r.height : v.height) * 0.5;
  }

  void markSeen(Set<String> ids) {
    final men = unseenMentions.where(ids.contains).toList();
    final rx = unseenReactions.where(ids.contains).toList();
    if (men.isEmpty && rx.isEmpty) return;
    setState(() {
      unseenMentions = unseenMentions.where((x) => !ids.contains(x)).toList();
      unseenReactions = unseenReactions.where((x) => !ids.contains(x)).toList();
    });
    unawaited(ChatMarks.seen(state!, widget.roomId, msgs, mentionIds: men, reactionIds: rx).catchError((_) {}));
  }

  /// ♥ / @ buttons: to the oldest unseen one.
  Future<void> jumpUnseen(List<String> ids) async {
    if (ids.isEmpty) return;
    final id = ids.first;
    await jumpTo(id);
    if (mounted) markSeen({id});
  }

  void onScroll() {
    // Older imported messages as I reach the top.
    if (scroll.hasClients && imports.isNotEmpty && scroll.position.pixels > scroll.position.maxScrollExtent - 800 && importHidden > 0) {
      setState(() {
        importShown += 300;
        msgs = withImports();
      });
    }
    // Telegram: the ↓ button shows once the newest message is 40 pt away.
    final away = scroll.hasClients && scroll.offset > Tokens.jumpShow;
    if (away != awayFromEnd && mounted) setState(() => awayFromEnd = away);
    checkSeen();
  }

  /// ♥ / @ / ↓ over the lower right of the messages (tips 320 / 249).
  Widget? jumpButtons() => !Features.tipsReply || selected != null || searching
      ? null
      : JumpButtons(
          reactions: unseenReactions.length,
          mentions: unseenMentions.length,
          down: awayFromEnd,
          onReaction: () => jumpUnseen(unseenReactions),
          onMention: () => jumpUnseen(unseenMentions),
          onDown: () => scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
          onClearReactions: () => markSeen(unseenReactions.toSet()),
          onClearMentions: () => markSeen(unseenMentions.toSet()),
        );

  /// Messages marked for the delete password; this chat is on the hide list.
  Set<String> marked = {};

  /// Messages marked for the hide password.
  Set<String> veiledMsgs = {};
  bool roomHidden = false;

  Future<void> load() async {
    final b = state!.backend;
    takeOtherDraft();
    final m = await b.timeline(widget.roomId, limit: limit);
    final r = await b.readUntil(widget.roomId);
    final post = await b.canPost(widget.roomId);
    final channel = await b.isChannel(widget.roomId);
    final sign = channel && await b.roomSwitch(widget.roomId, 'sign').catchError((_) => false);
    final secs = await b.timer(widget.roomId);
    final row = state!.chats.where((c) => c.roomId == widget.roomId);
    final room = row.isNotEmpty && !row.first.isDirect;
    // 1:1: note each new read receipt (read time, tip 421).
    if (row.isNotEmpty && row.first.isDirect) {
      final (u, at) = await b.readReceipt(widget.roomId).catchError((_) => (null, null));
      if (u != null && at != null) {
        final next = ReadTimes.add(state!.pref('readlog:${widget.roomId}', ''), u, at, b.clock);
        if (next != null) unawaited(state!.setPref('readlog:${widget.roomId}', next));
      }
    }
    // 1:1 chats too: 공유 비활성화 lives in the room settings.
    final c = await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    final r0 = room ? await b.myRole(widget.roomId).catchError((_) => 'member') : 'member';
    final mem = room ? await b.members(widget.roomId).catchError((_) => const <Member>[]) : const <Member>[];
    // 그룹·채널 사진: an admin's phone sends it again for people who came
    // in later (once per opening).
    if (room && !photoShared && (r0 == 'owner' || r0 == 'admin')) {
      photoShared = true;
      unawaited(b.reshareRoomPhoto(widget.roomId).catchError((_) => false));
    }
    final mn = room && myName.isEmpty ? await b.myName().catchError((_) => '') : myName;
    // 이름 색 (v1): picks of the people in this group.
    if (room) NameColors.picked.addAll(await b.nameColors(widget.roomId).catchError((_) => const <String, String>{}));
    // 556: tags members put on themselves. 384: note each new read receipt
    // in groups of up to 100 (who read my message, and when).
    final tg = room && !channel ? await b.memberTags(widget.roomId).catchError((_) => const <String, String>{}) : const <String, String>{};
    final gr = room && !channel && mem.length <= GroupReads.maxMembers
        ? await b.groupReceipts(widget.roomId).catchError((_) => const <String, (DateTime, DateTime)>{})
        : const <String, (DateTime, DateTime)>{};
    if (gr.isNotEmpty) {
      final next = GroupReads.add(state!.pref('readlog_g:${widget.roomId}', ''), gr, b.clock);
      if (next != null) unawaited(state!.setPref('readlog_g:${widget.roomId}', next));
    }
    final mk = kIsWeb ? const <String>[] : await b.markedMessages(widget.roomId).catchError((_) => const <String>[]);
    final vk = kIsWeb ? const <String>[] : await b.hideMarkedMessages(widget.roomId).catchError((_) => const <String>[]);
    final ql = kIsWeb ? const <List<String>>[[], []] : await b.quietLists().catchError((_) => const <List<String>>[[], []]);
    if (mounted) {
      final before = loadedOnce ? {for (final x in msgs) x.id} : null;
      // 365: messages gone since the last look (deleted by someone, or by
      // the spam filter) turn to dust instead of just vanishing.
      if (loadedOnce && m.isNotEmpty && !state!.calm) {
        final now = {for (final x in m) x.id};
        final oldest = m.first.time;
        final gone = [
          for (final x in ownMsgs)
            if (!now.contains(x.id) &&
                !x.time.isBefore(oldest) &&
                x.threadRoot == null &&
                x.imported == null &&
                !dusted.contains(x.id) &&
                !(pendingDelete?.contains(x.id) ?? false))
              x,
        ];
        // Many at once (a chat cleared, a page dropped): no show.
        if (gone.isNotEmpty && gone.length <= 8) {
          for (final x in gone) {
            ghosts[x.id] = x;
          }
          dust(gone);
        }
      }
      setState(() {
        loadedOnce = true;
        final cut = clearedAt(state!, widget.roomId);
        // 날짜로 지우기 (tip 308): days wiped here stay hidden on this phone.
        final wiped = LoginSafety.hiddenRanges(state!, widget.roomId);
        final all = [
          for (final x in m)
            if ((cut == null || x.time.isAfter(cut)) && !LoginSafety.inRanges(wiped, x)) x,
        ];
        // Thread replies live on the thread page, not in the chat.
        threads = {};
        for (final x in all) {
          if (x.threadRoot != null) threads.putIfAbsent(x.threadRoot!, () => []).add(x);
        }
        msgs = all.where((x) => x.threadRoot == null).toList();
        // 289: my message that just showed up at the bottom flies in from
        // the field (older pages loaded above never do).
        if (Features.tipsLink && before != null && !state!.calm) {
          final lastKnown = msgs.lastIndexWhere((x) => before.contains(x.id));
          for (final x in msgs.skip(lastKnown + 1)) {
            if (x.mine) flyIds.add(x.id);
          }
        }
        readUntil = r;
        // My mute time is up: the server lifts it when I next write.
        final over = r0 == 'muted' && RoomRules.muteOver(c, b.userId ?? '', b.clock);
        canPost = post || over;
        isChannel = channel;
        signed = sign;
        if (isGroup || isChannel) {
          unawaited(
            b.roomLink(widget.roomId).then((r) {
              if (mounted && publicRoom != (r.kind == 'public')) setState(() => publicRoom = r.kind == 'public');
            }, onError: (_) {}),
          );
        }
        isGroup = row.isNotEmpty && !row.first.isDirect;
        // 익명 관리자: others never see them typing.
        final anonNow = r0 == 'owner' || r0 == 'admin' ? const <String>{} : AnonAdmins.current(c);
        typers = b.typingUsers(widget.roomId).where((u) => !anonNow.contains(u)).toList();
        ownTags = tg;
        groupRcpt = gr;
        pins = RoomRules.livePins(b.pinned(widget.roomId), c, b.clock);
        // 나만 고정 (tip 276): mine join the shared ones (1:1 only).
        myPins = Features.tipsReply && !room ? MyPins.live(MyPins.read(state!, widget.roomId), b.clock) : const [];
        pins = MyPins.merge(pins, myPins, all);
        timerSecs = secs;
        cfg = c;
        roomLooks[widget.roomId] = RoomLook.from(c);
        role = over ? 'member' : r0;
        // 주제: the encrypted topic list this phone accepted.
        topics = room && !channel ? Topics.of(state!, widget.roomId, c) : const Topics();
        topicBase ??= r;
        if (topicNow != Topics.all && topics.on && topics.byId(topicNow) == null) topicNow = widget.topic ?? Topics.all;
        memberOf = {for (final x in mem) x.userId: x};
        myName = mn;
        marked = mk.toSet();
        veiledMsgs = vk.toSet();
        roomHidden = ql.first.contains(widget.roomId);
        markUnseen(msgs);
        if (Features.channelTips && !sendAsLoaded) unawaited(Future.microtask(loadSendAs));
        ownMsgs = msgs;
        msgs = withImports();
      });
      fetchImports(m);
      syncSendTopic();
      seeTopic();
    }
    // 메시지 요청: no read mark until I accept.
    if (m.isNotEmpty && !m.last.mine && !state!.isRequest(widget.roomId)) unawaited(b.markRead(widget.roomId).catchError((_) {}));
    unawaited(checkTranslate());
    if (Features.funFx) {
      unawaited(playNewFx());
      if (isGroup && !gxChecked) {
        gxChecked = true;
        unawaited(CustomEmojis.resendForNewcomers(state!, widget.roomId).catchError((_) {}));
      }
    }
  }

  /// 대화 전체 번역: the chat's main language when it isn't one I read.
  String? trLang;
  String trSeenKey = '';

  Future<void> checkTranslate() async {
    final s = state;
    if (s == null || !mounted) return;
    final texts = [
      for (final x in msgs.reversed)
        if (!x.mine && x.kind == 'text' && (x.body ?? '').trim().isNotEmpty) plainText(x.body!),
    ].take(20).toList();
    final key = texts.isEmpty ? '' : '${texts.length}|${texts.first}';
    if (key == trSeenKey) return;
    trSeenKey = key;
    final lang = await Translate.chatLanguage(texts);
    if (!mounted) return;
    var shown = lang;
    if (lang != null) {
      final mine = myLanguage(context);
      final st = await Translate.status(lang, translateTarget(s, widget.roomId, mine)).catchError((_) => TrStatus.unsupported);
      if (st == TrStatus.unsupported) shown = null;
    }
    if (mounted && shown != trLang) setState(() => trLang = shown);
  }

  /// The bar shows: setting on, not hidden here, language not skipped.
  bool get showTranslateBar {
    final s = state, lang = trLang;
    if (s == null || lang == null || !s.on(TrPrefs.chat, fallback: true) || s.on(TrPrefs.hidden(widget.roomId))) return false;
    if (chatTranslateTo(s, widget.roomId).isNotEmpty) return true;
    return !skipLanguages(s, myLanguage(context)).contains(lang);
  }

  static String mimeOf(String name) => ChatPageMime.of(name);

  /// A grey line in place of a message that must not be shown.
  Widget hiddenLine(BuildContext context, Key key, IconData icon, String text, bool mine) {
    final p = paletteOf(context);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        key: key,
        margin: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
        decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: Tokens.listIconSmall, color: p.secondaryLabel),
            SizedBox(width: Tokens.space[1]),
            Flexible(
              child: Text(text, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
            ),
          ],
        ),
      ),
    );
  }

  /// A chat photo (or an album's photos) full screen; 편집해서 보내기 there
  /// sends a new photo here.
  Future<void> openPhoto(List<Msg> photos, int i) async {
    if (photos.isEmpty) return;
    final m = photos[i.clamp(0, photos.length - 1)];
    final edited = await Navigator.of(context, rootNavigator: true).push<Uint8List>(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (_) => PhotoViewPage(
          roomId: widget.roomId,
          photos: photos,
          start: i.clamp(0, photos.length - 1),
          canShare: !protected,
          canPost: canPost,
          who: m.mine ? L.of(context).you : whoName(context, m.sender),
        ),
      ),
    );
    if (edited == null || !mounted || mediaBlocked() || ruleBlocks(Features.chatSafety ? 'photo' : 'media')) return;
    await state!.backend.sendFile(widget.roomId, name: 'edited-${DateTime.now().millisecondsSinceEpoch}.png', mime: 'image/png', bytes: edited);
    await load();
    unawaited(state!.refresh());
  }

  /// Opens a view-once photo full screen; after closing it is gone.
  Future<void> openOnce(Msg m) async {
    final b = state!.backend;
    final bytes = await b.openViewOnce(widget.roomId, m.id);
    if (!mounted) return;
    if (m.kind == 'audio') {
      // 418: plays over the blurred chat, then it is gone.
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: false,
          pageBuilder: (_, _, _) => OnceVoicePage(bytes: Uint8List.fromList(bytes), length: onceVoiceLength(m.body)),
          transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
        ),
      );
      await load();
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (_) => m.kind == 'video' && isVideoNote(m.body)
            ? OnceRoundPlayerPage(bytes: Uint8List.fromList(bytes), mime: storyMime(m.body ?? 'v.mp4'))
            : m.kind == 'video'
            ? VideoPlayerPage(once: true, mime: ChatPageMime.of(m.body ?? 'v.mp4'), load: () async => bytes)
            : ViewOncePage(bytes: Uint8List.fromList(bytes)),
      ),
    );
    await load();
  }

  /// "크게 쓰기": the words typed so far open in the long-post editor.
  Future<void> expandComposer() async {
    FocusScope.of(context).unfocus();
    final sent = await Navigator.of(context, rootNavigator: !Wide.on).push<bool>(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (_) => ArticleEditor(roomId: widget.roomId, initialText: input.outText),
      ),
    );
    if (sent == true && mounted) {
      input.clear();
      await load();
      unawaited(state!.refresh());
    }
  }

  /// The page for an attach-menu tool (shown inside the card, Telegram style).
  Widget? toolPageFor(String tool) => switch (tool) {
    'bubble' => SendBubblePage(roomId: widget.roomId, name: widget.title),
    'poll' => CreatePollPage(roomId: widget.roomId, isChannel: isChannel),
    'checklist' => CreateChecklistPage(roomId: widget.roomId, isGroup: isGroup || isChannel),
    'meetup' => CreateMeetupPage(roomId: widget.roomId),
    'contact' => PickContactPage(roomId: widget.roomId),
    'location' => SendLocationPage(roomId: widget.roomId),
    'videonote' => VideoNotePage(roomId: widget.roomId),
    _ when cardKinds.contains(tool) => cardEditor(widget.roomId, tool),
    _ => null,
  };

  /// The strip over the composer (emoji_suggest.dart); hidden after ✕-less
  /// dismissal by simply typing on.
  Widget suggestStrip() => ValueListenableBuilder<TextEditingValue>(
    valueListenable: input,
    builder: (context, v, _) {
      final sg = editing != null ? null : suggestFor(state!, v.text, v.selection.isValid ? v.selection.baseOffset : v.text.length);
      if (sg == null) return const SizedBox.shrink();
      return SuggestStrip(
        suggest: sg,
        onEmoji: (e) {
          if (sg is! EmojiSuggest) return;
          final t = input.text;
          final String next;
          final int at;
          if (sg.replace) {
            next = t.replaceRange(sg.start, sg.end, e);
            at = sg.start + e.length;
          } else {
            final gap = t.endsWith(' ') ? '' : ' ';
            next = '$t$gap$e';
            at = next.length;
          }
          input.value = TextEditingValue(
            text: next,
            selection: TextSelection.collapsed(offset: at),
          );
        },
        onSticker: (it) async {
          if (ruleBlocks('sticker')) return;
          input.clear();
          if (it.png != null) {
            await sendMine(it.png!);
          } else {
            await state!.backend.sendSticker(widget.roomId, it.id);
            await load();
            unawaited(state!.refresh());
          }
        },
      );
    },
  );

  /// One of 내 스티커 (or a fresh one): a PNG named so it shows as a sticker.
  Future<void> sendMine(Uint8List png) async {
    await state!.backend.sendFile(widget.roomId, name: '$customStickerPrefix${DateTime.now().millisecondsSinceEpoch}.png', mime: 'image/png', bytes: png);
    await load();
    unawaited(state!.refresh());
  }

  Future<void> attach() async {
    FocusScope.of(context).unfocus();
    final r = await showAttachSheet(
      context,
      caption: input.outText,
      isGroup: isGroup,
      isChannel: isChannel,
      toolPage: toolPageFor,
      members: memberOf.length,
      sentFiles: [
        for (final m in msgs.reversed)
          if (m.mine && m.kind == 'file' && !m.viewOnce) m,
      ],
    );
    if (r == null || !mounted) return;
    if (r.files.isNotEmpty && (mediaBlocked() || ruleBlocks('media'))) return;
    if (Features.chatSafety && r.files.isNotEmpty) {
      for (final f in r.files) {
        if (ruleBlocks(RoomRules.kindOfFile(f.name, asFile: f.asFile))) return;
      }
    }
    if (r.made) {
      await load();
      unawaited(state!.refresh());
      return;
    }
    final tool = r.tool;
    if (tool == null) {
      if (r.files.isEmpty) return;
      if (!r.once && r.caption.trim().isNotEmpty) input.clear();
      final b = state!.backend;
      // 묶어서 보내기 / 가리기 / GIF: marks in the encrypted file name.
      final media = [
        for (final f in r.files)
          if (!f.asFile && (f.isImage || f.isVideo)) f,
      ];
      final album = !r.once && r.together && media.length > 1 ? DateTime.now().microsecondsSinceEpoch.toRadixString(36) : null;
      MediaTags tagsOf(PickedFile f, {bool gif = false}) => MediaTags(
        album: album,
        index: album == null ? 0 : media.indexOf(f),
        count: media.length,
        spoiler: f.spoiler && !r.once,
        gif: gif || (f.isVideo && f.muted),
      );
      final l = L.of(context);
      final quality = r.hd ? PhotoQuality.hd : PhotoQuality.standard;
      if (r.files.any((f) => f.isMedia && f.isVideo && !f.video.isNone)) showStoryToast(context, l.videoEditing);

      for (var i = 0; i < r.files.length; i++) {
        final picked = r.files[i];
        var name = picked.name;
        var bytes = picked.bytes;
        var gif = false;
        if (picked.isMedia && picked.isVideo && !picked.video.isNone) {
          // 자르기·회전 (tip 56): a new video made here; the parts cut off
          // never leave the phone. If that fails, nothing is sent.
          final out = await Phone.editVideo(bytes, name, {...picked.video.toChannel(), 'mute': picked.muted && !r.once});
          if (!mounted) return;
          if (out == null) {
            showStoryToast(context, l.videoEditFailed);
            continue;
          }
          bytes = out;
          name = '${name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name}.mp4';
          gif = picked.muted && !r.once;
        } else if (picked.isVideo && picked.muted && !picked.asFile && !r.once) {
          // 소리 끄기: the sound track is taken out on the phone where it can.
          final silent = await Phone.stripAudio(bytes, name);
          if (silent != null) bytes = silent;
          gif = true;
        }
        if (Features.photoSend && picked.isMedia && picked.isImage) {
          // 표준 / HD (tip 529): made smaller here, before encryption.
          final sized = await PhotoSize.fit(name, bytes, quality);
          name = sized.name;
          bytes = sized.bytes;
        }
        // 영상 화질 (tip 114) + 가벼운 복사본 (479 · 480): made on this phone
        // before encryption; the web can't, so it sends the original only.
        final vp = r.video;
        String? pair;
        if (vp != null && picked.isVideo && !picked.asFile && !gif && !r.once && canShrinkVideo) {
          final original = bytes;
          if (vp.height != null) bytes = await shrinkVideo(bytes, name, vp.height!) ?? bytes;
          if (vp.light && (vp.height == null || vp.height! > lightHeight)) {
            final small = await shrinkVideo(original, name, lightHeight);
            if (small != null && small.length < bytes.length && mounted) {
              pair = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
              final lightName = MediaTags(
                lightOf: pair,
                lightHeight: lightHeight,
              ).apply('${name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name}.mp4');
              // Sent first, so the chat's last message is the video itself.
              await b.sendFile(widget.roomId, name: lightName, mime: 'video/mp4', bytes: small);
            }
          }
          if (vp.height != null) name = '${name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name}.mp4';
        }
        if (!mounted) return;
        final f = picked;
        final t0 = tagsOf(f, gif: gif);
        final tags = pair == null ? t0 : MediaTags(album: t0.album, index: t0.index, count: t0.count, spoiler: t0.spoiler, gif: t0.gif, pair: pair);
        final marked = r.once || f.asFile || !(f.isImage || f.isVideo) || MediaTags.of(f.name).any ? name : tags.apply(name);
        final clip = f.clip;
        if (r.once) {
          // View-once photos stay still (the clip is not sent).
          await b.sendViewOnce(widget.roomId, name: name, mime: mimeOf(name), bytes: bytes);
        } else if (clip != null && f.style != LiveStyle.off && !f.asFile) {
          // 움직이는 사진: still + clip, both encrypted on this phone.
          await b.sendLivePhoto(
            widget.roomId,
            name: marked,
            mime: mimeOf(name),
            bytes: bytes,
            videoMime: 'video/mp4',
            video: clip,
            duration: Mp4Meta.duration(clip) ?? const Duration(seconds: 3),
            style: f.style.name,
            caption: i == r.files.length - 1 ? r.caption : '',
          );
        } else {
          // The words go under the last one, so they sit right above the composer.
          await b.sendFile(
            widget.roomId,
            name: marked,
            mime: f.asFile ? 'application/octet-stream' : mimeOf(name),
            bytes: bytes,
            caption: i == r.files.length - 1 ? r.caption : '',
            captionAbove: r.captionAbove && !f.asFile,
          );
        }
      }
      await load();
      unawaited(state!.refresh());
      return;
    }
    if (tool.startsWith('resend:')) {
      // "최근에 보낸 파일": the same file again, as a new message.
      if (ruleBlocks(Features.chatSafety ? 'file' : 'media')) return;
      final id = tool.substring(7);
      final m = msgs.where((x) => x.id == id).firstOrNull;
      if (m == null) return;
      final b = state!.backend;
      final bytes = await b.downloadFile(widget.roomId, m.fileId);
      await b.sendFile(widget.roomId, name: m.body ?? 'file', mime: 'application/octet-stream', bytes: Uint8List.fromList(bytes));
      await load();
      return;
    }
    if (tool == 'scan') {
      if (ruleBlocks('media')) return;
      final pdf = await Phone.scanDocument();
      if (pdf == null || !mounted) return;
      final n = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final name = '${L.of(context).scanFileName('${n.year}-${two(n.month)}-${two(n.day)} ${two(n.hour)}.${two(n.minute)}')}.pdf';
      await state!.backend.sendFile(widget.roomId, name: name, mime: 'application/pdf', bytes: pdf);
      await load();
      unawaited(state!.refresh());
      return;
    }
    if (tool == 'poll' && ruleBlocks('poll')) return;
    if (tool != 'templates' && tool != 'poll' && ruleBlocks(!Features.chatSafety ? 'media' : (tool == 'videonote' ? 'videonote' : 'text'))) return;
    final Widget? page = toolPageFor(tool);
    if (tool == 'templates') {
      final t = await openSheet<String>(context, (_) => const TemplatesPage());
      if (t != null && mounted) {
        input.text = t;
        input.selection = TextSelection.collapsed(offset: t.length);
        setState(() {});
      }
      return;
    }
    if (page == null) return;
    final made = await openSheet<bool>(context, (_) => page);
    if (made == true) {
      await load();
      unawaited(state!.refresh());
    }
  }

  /// New member while the room's limit is on: no photos, videos, links.
  bool mediaBlocked() {
    if (!(isGroup || isChannel)) return false;
    final until = myMediaFrom(memberOf[state!.backend.userId], mediaDays, now: state!.backend.clock);
    if (until == null) return false;
    showNotice(L.of(context).newMediaWait(mediaDays));
    return true;
  }

  Future<void> send() async {
    final text = input.outText.trim();
    if (text.isEmpty && (editing == null || editingWordsOnly)) return;
    if (hasLinkText(text) && mediaBlocked()) return;
    if (editing == null) {
      if (ruleBlocks('text')) return;
      if (hasLinkText(text) && ruleBlocks('link')) return;
      if (isGroup && RoomRules.hasEveryone(text) && !RoomRules.mayMentionAll(role, memberOf.length)) {
        showNotice(L.of(context).mentionAllAdmins);
        return;
      }
    }
    // 움직이는 색 배경 (tip 281): colours turn a little with each message.
    if (editing == null) wallSpin.value++;
    final b = state!.backend;
    final (rep, ed) = (replying, editing);
    final (eBytes, eName, eAbove) = (editBytes, editName, editAbove);
    editBytes = editName = null;
    final fx = ed == null ? nextFx : null;
    nextFx = null;
    // 주사위 (tip 218): 🎲 🎯 🏀 ⚽ 🎳 🎰 alone rolls; the result comes from
    // the message's id, so nobody picks it.
    final game = Features.funFx && ed == null && rep == null ? Dice.gameOf(text) : null;
    if (game != null) {
      input.clear();
      setState(() {});
      await b.createCard(widget.roomId, 'dice', {'e': game});
      await load();
      unawaited(state!.refresh());
      return;
    }
    final link = Features.tipsLink && previewsOn && linksIn(text).isNotEmpty ? linkChoice : null;
    linkChoice = const LinkChoice();
    settledLinks = const [];
    input.clear();
    draftTimer?.cancel();
    if (state!.pref('draft:${widget.roomId}', '').isNotEmpty) unawaited(state!.saveDraft(widget.roomId, ''));
    setState(() => replying = editing = null);
    typingIdle?.cancel();
    unawaited(b.setTyping(widget.roomId, false).catchError((_) {}));
    if (ed != null) {
      if (ed.kind == 'text' && eBytes == null) {
        if (text != ed.body) await b.edit(widget.roomId, ed.id, text);
      } else if (eBytes != null || text != (ed.caption ?? '') || eAbove != ed.captionAbove) {
        // 사진 수정: words, above/under, and maybe a new file (tips 452 B, 482).
        try {
          await b.editMedia(widget.roomId, ed.id, caption: text, captionAbove: eAbove, name: eName, mime: eName == null ? null : mimeOf(eName), bytes: eBytes);
        } catch (_) {
          if (mounted) showNotice(L.of(context).editMediaFailed);
        }
      }
    } else if (state!.on('undo_send')) {
      if (pendingSend != null) await flushSend();
      setState(() {
        pendingSend = (text, rep);
        pendingLink = link;
        pendingFx = fx;
        sendLeft = 5;
      });
      sendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        if (sendLeft <= 1) {
          unawaited(flushSend());
        } else {
          setState(() => sendLeft--);
        }
      });
      return;
    } else {
      await _deliver(b, text, rep, link);
    }
    await load();
    await afterSent(text, fx);
    unawaited(state!.refresh());
  }

  /// After a text went out: made emoji pictures this chat hasn't had yet
  /// (354), then the effect (451).
  Future<void> afterSent(String text, String? fx) async {
    if (!Features.funFx) return;
    final s = state;
    if (s != null) unawaited(CustomEmojis.shareIn(s, widget.roomId, text).catchError((_) {}));
    if (fx != null) await withFx(text, fx);
  }

  /// Admin phone: the group emoji go again to people who joined (430).
  bool gxChecked = false;

  /// Puts an emoji (plain, ":char:" or ":cx_…:") in at the cursor.
  void insertEmoji(String raw) {
    final e = charEmojiIn(raw);
    final sel = input.selection;
    final at = sel.isValid ? sel.start : input.text.length;
    final end = sel.isValid ? sel.end : input.text.length;
    input.text = input.text.replaceRange(at, end, e);
    input.selection = TextSelection.collapsed(offset: at + e.length);
    setState(() {});
  }

  /// Tells the other phones about the effect on my message just sent, and
  /// plays it here from the bottom, where the message is.
  Future<void> withFx(String text, String fx) async {
    final s = state;
    if (s == null) return;
    await MsgFx.sent(s, widget.roomId, text, fx, msgs).catchError((_) => null);
    if (!mounted) return;
    setState(() {});
    final k = MsgFx.byId(fx);
    if (k != null) playFx(context, k);
  }

  /// Effects on messages that came in and have not played yet: the newest
  /// plays once when the chat is open (451).
  Future<void> playNewFx() async {
    final s = state;
    if (s == null || !Features.funFx) return;
    final ids = await MsgFx.match(s, widget.roomId, msgs);
    if (ids.isEmpty || !mounted) return;
    for (final id in ids) {
      await MsgFx.markPlayed(s, id);
    }
    if (!mounted) return;
    setState(() {});
    final k = MsgFx.byId(MsgFx.of(s, ids.last));
    if (k != null) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? playFx(context, k) : null);
  }

  /// [link]: the link card set-up (tip 400; null = the usual card).
  Future<void> _deliver(Backend b, String text, Msg? rep, [LinkChoice? link]) async {
    // 주제 (tip 527): in 모두 an answer goes to the topic of what it answers.
    final into = topicsOn && topicNow == Topics.all && rep != null && rep.id.isNotEmpty ? topics.topicOf(rep) : null;
    if (into != null) b.setSendTopic(widget.roomId, into);
    try {
      await _deliver0(b, text, rep, link);
    } catch (e) {
      // Paused account: say why and keep the words in the box.
      if (!mounted || !await explainStrike(context, e)) rethrow;
      if (mounted && input.text.isEmpty) input.text = text;
    } finally {
      if (into != null) syncSendTopic();
    }
  }

  Future<void> _deliver0(Backend b, String text, Msg? rep, [LinkChoice? link]) => rep?.quote != null
      // 부분 인용 / 다른 대화에서 답장 (tip 399).
      ? b.replyQuote(widget.roomId, rep!.id, text, quote: rep.quote!, quoteName: rep.quoteName ?? '')
      : link != null
      ? b.sendTextLink(widget.roomId, text, link, replyTo: rep?.id, quiet: rep == null && channelSilent)
      : rep != null
      ? b.reply(widget.roomId, rep.id, text)
      : (channelSilent ? b.sendTextQuietly(widget.roomId, text) : b.sendText(widget.roomId, text));

  /// Channel owner's bell (v1): posts go out without sound for subscribers.
  bool get channelSilent => isChannel && state!.on('channel_silent:${widget.roomId}');

  Future<void> toggleChannelBell() async {
    final l = L.of(context);
    final now = !channelSilent;
    await state!.setOn('channel_silent:${widget.roomId}', now);
    if (mounted) showNotice(now ? l.channelSilentOn : l.channelLoudOn);
  }

  /// The 5 seconds are up (or another message follows): really send.
  Future<void> flushSend() async {
    sendTimer?.cancel();
    final ps = pendingSend;
    if (ps == null) return;
    final link = pendingLink;
    final fx = pendingFx;
    setState(() {
      pendingSend = pendingLink = null;
      pendingFx = null;
    });
    await _deliver(state!.backend, ps.$1, ps.$2, link);
    await load();
    await afterSent(ps.$1, fx);
    unawaited(state!.refresh());
  }

  /// Take the waiting message back into the field.
  void cancelSend() {
    sendTimer?.cancel();
    final ps = pendingSend;
    if (ps == null) return;
    setState(() {
      pendingSend = null;
      pendingFx = null;
      replying = ps.$2;
    });
    input.text = ps.$1;
  }

  Widget sendUndoBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Container(
      key: const Key('send-undo-bar'),
      margin: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.sendingIn(sendLeft), style: Tokens.caption.style.copyWith(color: p.accent)),
                Text(
                  pendingSend?.$1 ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: p.label),
                ),
              ],
            ),
          ),
          CupertinoButton(
            key: const Key('send-undo'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: cancelSend,
            child: Text(l.cancel, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
  }

  /// 메시지 요청: accept, or delete (and block) without telling them.
  Widget requestBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      key: const Key('request-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Column(
        children: [
          Text(
            l.messageRequestBar,
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
          ),
          SizedBox(height: Tokens.space[2]),
          Row(
            children: [
              Expanded(
                child: GlassPill(key: const Key('request-delete'), text: l.messageRequestDelete, onTap: declineRequest),
              ),
              // The first-chat card on top already has 수락.
              if (!strangerMode) ...[
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: AccentButton(
                    key: const Key('request-accept'),
                    text: l.messageRequestAccept,
                    onTap: () async {
                      await state!.acceptRequest(widget.roomId);
                      await state!.setPref('stranger_ok:${widget.roomId}', '1');
                      unawaited(state!.backend.markRead(widget.roomId).catchError((_) {}));
                      if (mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> declineRequest() async {
    final l = L.of(context);
    final pick = await showCupertinoModalPopup<String>(
      context: context,
      useRootNavigator: !Wide.on,
      builder: (c) => CupertinoActionSheet(
        message: Text(l.messageRequestDeleteInfo),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('request-delete-only'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'delete'),
            child: Text(l.messageRequestDelete),
          ),
          CupertinoActionSheetAction(
            key: const Key('request-block'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'block'),
            child: Text(l.messageRequestBlock),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    final nav = Navigator.of(context);
    await state!.declineRequest(widget.roomId, block: pick == 'block');
    if (nav.canPop()) nav.pop();
  }

  /// 여러 채널에 한 번에 (v1): the same post here and in other channels I
  /// can post in, picked in one list.
  Future<void> sendToChannels(String text) async {
    final l = L.of(context);
    final b = state!.backend;
    final mine = <ChatPreview>[];
    for (final c in state!.chats) {
      if (!c.isChannel || c.roomId == widget.roomId) continue;
      if (await b.canPost(c.roomId).catchError((_) => false)) mine.add(c);
    }
    if (!mounted) return;
    final picked = <String>{};
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => GlassSheet(
          title: l.sendToChannels,
          children: [
            if (mine.isEmpty)
              Padding(
                padding: EdgeInsets.all(Tokens.space[3]),
                child: Text(
                  l.noOtherChannels,
                  key: const Key('send-many-none'),
                  style: Tokens.preview.style.copyWith(color: paletteOf(c).secondaryLabel),
                ),
              ),
            for (final ch in mine)
              IosTile(
                key: Key('send-many-${ch.roomId}'),
                leading: Avatar(name: ch.name, size: 30, squircle: true, roomId: ch.roomId),
                title: Text(ch.name),
                trailing: Icon(
                  picked.contains(ch.roomId) ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
                  color: picked.contains(ch.roomId) ? paletteOf(c).accent : paletteOf(c).secondaryLabel,
                ),
                onTap: () => set(() => picked.contains(ch.roomId) ? picked.remove(ch.roomId) : picked.add(ch.roomId)),
              ),
            Padding(
              padding: EdgeInsets.all(Tokens.space[3]),
              child: AccentButton(key: const Key('send-many-go'), text: l.sendToCount(picked.length + 1), onTap: () => Navigator.pop(c, true)),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    input.clear();
    await b.sendText(widget.roomId, text);
    for (final id in picked) {
      try {
        await b.sendText(id, text);
      } catch (_) {}
    }
    await load();
    unawaited(state!.refresh());
    if (mounted) showNotice(l.sentToCount(picked.length + 1));
  }

  /// Hold the send button: send quietly, or set a time.
  Future<void> sendOptions() async {
    final l = L.of(context);
    final text = input.outText.trim();
    if (text.isEmpty) return;
    // 메시지 효과 (tip 451): the effect row sits on top, like Telegram.
    final fxPick = ValueNotifier<String?>(null);
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => ValueListenableBuilder<String?>(
        valueListenable: fxPick,
        builder: (c, fx, _) => IosActionSheet(
          title: Features.funFx && editing == null ? FxPicker(picked: fxPick) : null,
          actions: [
            if (fx != null)
              CupertinoActionSheetAction(
                key: const Key('send-fx'),
                isDefaultAction: true,
                onPressed: () => Navigator.pop(c, 'fx'),
                child: Text(l.fxSendWith(MsgFx.byId(fx)!.name(ko))),
              ),
            CupertinoActionSheetAction(
              key: const Key('send-quiet'),
              onPressed: () => Navigator.pop(c, 'quiet'),
              child: Text(fx == null ? l.sendQuietly : l.fxQuietWith(MsgFx.byId(fx)!.name(ko))),
            ),
            CupertinoActionSheetAction(key: const Key('send-later'), onPressed: () => Navigator.pop(c, 'later'), child: Text(l.sendLater)),
            if (isChannel) CupertinoActionSheetAction(key: const Key('send-many'), onPressed: () => Navigator.pop(c, 'many'), child: Text(l.sendToChannels)),
          ],
          cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
        ),
      ),
    );
    final fx = fxPick.value;
    fxPick.dispose();
    if (!mounted || pick == null) return;
    if (pick == 'many') return sendToChannels(text);
    if (pick == 'fx') {
      nextFx = fx;
      return send();
    }
    if (pick == 'quiet') {
      input.clear();
      await state!.backend.sendTextQuietly(widget.roomId, text);
      await load();
      await afterSent(text, fx);
      unawaited(state!.refresh());
      return;
    }
    if (Features.tipsLink) {
      // Tip 217: the wheel with a live "오늘 오후 5:41에 보내기" button.
      final got = await pickSendTime(context);
      if (got == null || !mounted) return;
      input.clear();
      await state!.schedule(widget.roomId, text, got.$1, repeat: got.$2);
      if (mounted) showNotice(l.scheduledDone);
      setState(() {});
      return;
    }
    var at = DateTime.now().add(const Duration(hours: 1));
    var repeat = '';
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => Container(
        height: 380,
        color: paletteOf(c).card,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
                  CupertinoButton(key: const Key('schedule-ok'), onPressed: () => Navigator.pop(c, true), child: Text(l.scheduleSend)),
                ],
              ),
              // v1 반복 보내기: once, every day, week or month.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                child: StatefulBuilder(
                  builder: (c, set) => CupertinoSlidingSegmentedControl<String>(
                    key: const Key('schedule-repeat'),
                    groupValue: repeat,
                    children: {'': Text(l.repeatNone), 'day': Text(l.repeatDay), 'week': Text(l.repeatWeek), 'month': Text(l.repeatMonth)},
                    onValueChanged: (v) => set(() => repeat = v ?? ''),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  key: const Key('schedule-picker'),
                  initialDateTime: at,
                  minimumDate: DateTime.now(),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  use24hFormat: false,
                  onDateTimeChanged: (v) => at = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    input.clear();
    await state!.schedule(widget.roomId, text, at, repeat: repeat);
    if (mounted) showNotice(l.scheduledDone);
    setState(() {});
  }

  (String, DateTime, Offset)? lastUp;

  void doubleTapCheck(Msg m, PointerUpEvent e) {
    if (!state!.on('double_tap_react', fallback: true)) return;
    final now = DateTime.now();
    final prev = lastUp;
    lastUp = (m.id, now, e.position);
    if (prev != null && prev.$1 == m.id && now.difference(prev.$2) < const Duration(milliseconds: 300) && (prev.$3 - e.position).distance < 30) {
      lastUp = null;
      toggleReaction(m, state!.pref('quick_reaction', '❤️'));
    }
  }

  /// The draft as it stands (nothing while editing a sent message).
  String get draftNow => input.text.trim().isEmpty || editing != null ? '' : input.outText;

  /// 임시 글 이어쓰기 (tip 241): two quiet seconds after typing, the draft
  /// is kept and goes to my other devices, so it survives a dead battery.
  Timer? draftTimer;

  /// A draft from my other device: into the empty composer, with a note.
  void takeOtherDraft({bool open = false}) {
    final s = state;
    if (s == null || s.pref(draftFromKey(widget.roomId), '').isEmpty) return;
    final draft = s.pref(draftKey(widget.roomId), '');
    if (input.text.trim().isNotEmpty && !open) return;
    if (draft.isNotEmpty && input.text != draft) input.text = draft;
    scheduleMicrotask(() => unawaited(s.setPref(draftFromKey(widget.roomId), '').catchError((_) {})));
    if (draft.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? showNotice(L.of(context).draftFromOther) : null);
  }

  /// Tells the others I'm typing (at most every 4 seconds), and stops
  /// after 5 quiet seconds.
  void onTyped(String _) {
    draftTimer?.cancel();
    draftTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) unawaited(state!.saveDraft(widget.roomId, draftNow).catchError((_) {}));
    });
    // Tip 400: the link line follows the typed links once they settle (so a
    // half-typed address is never read).
    if (Features.tipsLink) {
      linkSettle?.cancel();
      final now = linksIn(input.text);
      if (now.isEmpty || !now.every(settledLinks.contains)) {
        if (settledLinks.any((u) => !now.contains(u))) setState(() => settledLinks = settledLinks.where(now.contains).toList());
        linkSettle = Timer(const Duration(milliseconds: 700), () {
          if (mounted) setState(() => settledLinks = linksIn(input.text));
        });
      }
    }
    final q = isGroup ? RoomRules.mentionQuery(input.text, input.selection.baseOffset) : null;
    if (q != mentionQ) setState(() => mentionQ = q);
    final b = state!.backend;
    if (!state!.on('send_typing', fallback: true)) return;
    final now = DateTime.now();
    if (now.difference(typingSent) > const Duration(seconds: 4)) {
      typingSent = now;
      unawaited(b.setTyping(widget.roomId, true).catchError((_) {}));
    }
    typingIdle?.cancel();
    typingIdle = Timer(const Duration(seconds: 5), () {
      typingSent = DateTime(2000);
      unawaited(b.setTyping(widget.roomId, false).catchError((_) {}));
    });
  }

  Future<void> commitDelete() async {
    undoTimer?.cancel();
    final ids = pendingDelete;
    if (ids == null) return;
    for (final id in ids) {
      await state!.backend.deleteMessage(widget.roomId, id).catchError((_) {});
    }
    if (mounted) setState(() => pendingDelete = null);
    await load();
    unawaited(state!.refresh());
  }

  void startDelete(List<String> ids) {
    if (pendingDelete != null) unawaited(commitDelete());
    setState(() {
      if (!state!.calm) dust(msgs.where((m) => ids.contains(m.id)));
      pendingDelete = ids;
      undoLeft = 5;
    });
    undoTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (undoLeft <= 1) {
        t.cancel();
        unawaited(commitDelete());
      } else {
        setState(() => undoLeft--);
      }
    });
  }

  void undoDelete() {
    undoTimer?.cancel();
    setState(() {
      dusting.removeAll(pendingDelete ?? const <String>[]);
      dusted.removeAll(pendingDelete ?? const <String>[]);
      pendingDelete = null;
    });
  }

  Future<void> chooseTimer() async {
    // Off, 1 day … 1 year, or any time on the wheel (Telegram 251).
    final pick = await pickTimer(context, now: timerSecs);
    if (pick == null || pick == timerSecs) return;
    await state!.setChatTimer(widget.roomId, pick);
    await load();
  }

  /// Unread messages when the chat opened (for the AI summary bar).
  int unreadAtOpen = 0;

  VoiceRecorder? recorder;
  DateTime? recStart;
  bool recCancel = false;

  /// Finger's slide to the left while holding (the bar follows it, v1).
  double recDx = 0;

  /// Recent loudness, newest last (the locked bar's live wave).
  final recLevels = <double>[];

  /// 418 한 번만 듣기: the locked bar's "1" button (not in channels).
  bool recOnce = false;

  /// Slid up: recording goes on after letting go (trash / pause / send).
  bool recLocked = false;
  bool recPaused = false;
  Duration recPausedFor = Duration.zero;
  DateTime? recPausedAt;
  Timer? recTick;
  double recLevel = 0;
  StreamSubscription<double>? recLevelSub;

  Future<void> startRecording() async {
    if (Features.chatSafety && ruleBlocks('voice')) return;
    final r = VoiceKit.recorder();
    final ok = await r.start().catchError((_) => false);
    if (!mounted) return;
    if (!ok) {
      showNotice(L.of(context).voiceNoMic);
      return;
    }
    HapticFeedback.lightImpact();
    recorder = r;
    recLevels.clear();
    recLevelSub = r.level.listen((v) {
      if (!recPaused) {
        recLevels.add(v);
        if (recLevels.length > 60) recLevels.removeAt(0);
      }
      setState(() => recLevel = v);
    });
    recTick = Timer.periodic(const Duration(milliseconds: 200), (_) => setState(() {}));
    setState(() {
      recStart = DateTime.now();
      recCancel = false;
      recDx = 0;
      recLocked = false;
      recPaused = false;
      recPausedFor = Duration.zero;
      recPausedAt = null;
      stickersOpen = false;
    });
  }

  Future<void> finishRecording() async {
    final r = recorder;
    if (r == null) return;
    recTick?.cancel();
    unawaited(recLevelSub?.cancel());
    final cancel = recCancel;
    final once = recOnce;
    setState(() {
      recOnce = false;
      recorder = null;
      recStart = null;
      recCancel = false;
      recLevel = 0;
      recDx = 0;
      recLocked = false;
      recPaused = false;
    });
    if (cancel) {
      await r.cancel();
      return;
    }
    final got = await r.stop();
    // Too short to be a message (a tap that turned into a hold).
    if (got == null || got.duration < const Duration(milliseconds: 700)) {
      if (mounted) showNotice(L.of(context).voiceHoldHint);
      return;
    }
    if (once) {
      await state!.backend.sendViewOnce(widget.roomId, name: onceVoiceName(got.duration, got.mime), mime: got.mime, bytes: got.bytes);
    } else {
      await state!.backend.sendVoice(widget.roomId, got.mime, got.bytes, got.duration, got.waveform);
    }
    await load();
    unawaited(state!.refresh());
  }

  Duration get recTook {
    final now = DateTime.now();
    final paused = recPausedFor + (recPausedAt == null ? Duration.zero : now.difference(recPausedAt!));
    return now.difference(recStart ?? now) - paused;
  }

  Future<void> toggleRecPause() async {
    final r = recorder;
    if (r == null) return;
    if (recPaused) {
      await r.resume();
      setState(() {
        recPausedFor += DateTime.now().difference(recPausedAt ?? DateTime.now());
        recPausedAt = null;
        recPaused = false;
      });
    } else {
      await r.pause();
      setState(() {
        recPausedAt = DateTime.now();
        recPaused = true;
      });
    }
  }

  Future<void> cancelRecording() async {
    setState(() => recCancel = true);
    await finishRecording();
  }

  /// Locked recording (v1 layout): round glass trash, a glass capsule with
  /// the red dot, time, live level and pause, and the round send button.
  /// All 40 tall like the composer.
  Widget lockedRecordingBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      key: const Key('recording-locked'),
      padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], Tokens.space[1]),
      child: Row(
        children: [
          GlassCircle(
            key: const Key('rec-trash'),
            size: Tokens.closeButton,
            onTap: cancelRecording,
            child: Icon(CupertinoIcons.trash, color: Palette.tileRed, size: Tokens.listIcon),
          ),
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: LiquidGlass(
              radius: Tokens.capsule,
              child: SizedBox(
                height: 40,
                child: Row(
                  children: [
                    SizedBox(width: Tokens.space[2]),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: recPaused ? p.secondaryLabel : Palette.tileRed, shape: BoxShape.circle),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Text(
                      voiceTime(recTook),
                      style: Tokens.body.style.copyWith(color: p.label, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    SizedBox(width: Tokens.space[2]),
                    Expanded(
                      child: _LevelDots(levels: recLevels, color: p.secondaryLabel),
                    ),
                    CupertinoButton(
                      key: const Key('rec-pause'),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
                      minimumSize: const Size(40, 40),
                      onPressed: toggleRecPause,
                      child: Icon(
                        recPaused ? CupertinoIcons.mic_fill : CupertinoIcons.pause_fill,
                        semanticLabel: recPaused ? l.voiceResume : l.voicePause,
                        color: recPaused ? Palette.tileRed : p.label,
                        size: Tokens.listIcon,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (Features.chatSafety && !isChannel) ...[
            SizedBox(width: Tokens.space[1]),
            GestureDetector(
              key: const Key('rec-once'),
              onTap: () {
                setState(() => recOnce = !recOnce);
                showNotice(recOnce ? l.onceVoiceOn : l.onceVoiceOff);
              },
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: recOnce ? p.accent : p.incoming, shape: BoxShape.circle),
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: recOnce ? p.onAccent : p.label, width: 1.5),
                  ),
                  child: Text('1', style: Tokens.caption.style.copyWith(color: recOnce ? p.onAccent : p.label, height: 1)),
                ),
              ),
            ),
          ],
          SizedBox(width: Tokens.space[1]),
          GestureDetector(
            key: const Key('rec-send'),
            onTap: finishRecording,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
              child: Icon(CupertinoIcons.arrow_up, color: p.onAccent, size: Tokens.listIcon),
            ),
          ),
        ],
      ),
    );
  }

  Widget recordingBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final took = recTook;
    return Container(
      key: const Key('recording'),
      height: 38,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Container(
            width: 8 + recLevel * 6,
            height: 8 + recLevel * 6,
            decoration: const BoxDecoration(color: Palette.tileRed, shape: BoxShape.circle),
          ),
          SizedBox(width: Tokens.space[1]),
          Text(
            voiceTime(took),
            style: Tokens.body.style.copyWith(color: p.label, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          // Follows the finger to the left (v1), fading as it goes.
          Transform.translate(
            offset: Offset(recDx.clamp(-120.0, 0.0), 0),
            child: Opacity(
              opacity: (1 + recDx / 160).clamp(0.3, 1.0),
              child: Text(
                recCancel ? l.voiceReleaseCancel : l.voiceSlideCancel,
                style: Tokens.preview.style.copyWith(color: recCancel ? Palette.tileRed : p.secondaryLabel),
              ),
            ),
          ),
          SizedBox(width: Tokens.space[2]),
          Icon(CupertinoIcons.lock, key: const Key('rec-lock-hint'), size: Tokens.listIconSmall, color: p.secondaryLabel, semanticLabel: l.voiceLockHint),
        ],
      ),
    );
  }

  /// AI 편집기: rewrite what is in the composer on this phone; apply puts
  /// the result back, send sends it right away.
  Future<void> openAi() async {
    FocusScope.of(context).unfocus();
    if (!await aiAgeOk(context) || !mounted) return;
    final got = await openAiEditor(context, input.outText);
    if (got == null || !mounted) return;
    input.text = got.text;
    input.selection = TextSelection.collapsed(offset: input.text.length);
    if (got.send) await send();
  }

  /// 인증 코드 복사: copied, and gone from the clipboard after a minute.
  Future<void> copyFoundCode(String code) async {
    var ok = true;
    try {
      await copyCode(code).timeout(const Duration(seconds: 2));
    } catch (_) {
      ok = false; // some browsers refuse the clipboard: show the code instead
    }
    HapticFeedback.lightImpact();
    if (mounted) showNotice(ok ? L.of(context).codeCopied : L.of(context).codeCopyFailed(code));
  }

  void onChatJump() {
    final j = chatJump.value;
    if (j == null || j.$1 != widget.roomId || !mounted) return;
    chatJump.value = null;
    unawaited(jumpTo(j.$2));
  }

  /// "링크 복사": a link to this message that only members can open.
  Future<void> copyMsgLink(Msg m) async {
    await Clipboard.setData(ClipboardData(text: MessageLink(widget.roomId, m.id).url));
    if (mounted) showNotice(L.of(context).msgLinkCopied);
  }

  /// Tap on a friend's dice: "🎲 하나만 보내면 나도 해 볼 수 있어요 · 보내기".
  Future<void> tryDice(String game) async {
    final l = L.of(context);
    if (!canPost || ruleBlocks('text')) return;
    final go = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.diceTry(game)),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('dice-try'),
            isDefaultAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text('$game ${l.diceTrySend}'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (go != true || !mounted) return;
    await state!.backend.createCard(widget.roomId, 'dice', {'e': game});
    await load();
    unawaited(state!.refresh());
  }

  void showNotice(String text) {
    noticeTimer?.cancel();
    setState(() => notice = text);
    noticeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => notice = null);
    });
  }

  /// Channel post share arrow: several chats at once, or the link.
  Future<void> sharePost(Msg m) async {
    final n = await showShareSheet(context, roomId: widget.roomId, msg: m);
    if (!mounted || n == 0) return;
    if (n == -2) {
      await postToStory(context, roomId: widget.roomId, msg: m);
      unawaited(state!.refresh());
      return;
    }
    showNotice(n < 0 ? L.of(context).msgLinkCopied : L.of(context).shareDone(n));
    unawaited(state!.refresh());
  }

  /// 빠른 전달 (tip 521): waits 5 seconds with 되돌리기, then goes.
  (Msg, ChatPreview)? pendingQuick;
  int quickLeft = 5;
  Timer? quickTimer;

  Future<void> quickForward(Msg m, ChatPreview to) async {
    if (pendingQuick != null) await flushQuick();
    setState(() {
      pendingQuick = (m, to);
      quickLeft = 5;
    });
    quickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (quickLeft <= 1) {
        unawaited(flushQuick());
      } else {
        setState(() => quickLeft--);
      }
    });
  }

  Future<void> flushQuick() async {
    quickTimer?.cancel();
    final q = pendingQuick;
    if (q == null) return;
    if (mounted) setState(() => pendingQuick = null);
    final l = mounted ? L.of(context) : null;
    try {
      await state!.backend.forward(widget.roomId, q.$1.id, q.$2.roomId);
      if (q.$2.roomId == state!.savedRoomId) {
        final after = await state!.backend.timeline(q.$2.roomId, limit: 20);
        final last = after.where((x) => x.mine).lastOrNull;
        if (last != null) await setSavedFrom(state!, [last.id], widget.roomId);
      }
      unawaited(state!.refresh());
      if (mounted && l != null) showNotice(l.forwardDone);
    } catch (_) {
      if (mounted && l != null) showNotice(l.forwardFailed);
    }
  }

  Widget quickUndoBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final to = pendingQuick!.$2;
    return Container(
      key: const Key('quick-undo-bar'),
      margin: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Avatar(name: to.name, size: 28, roomId: to.roomId, squircle: !to.isDirect, userId: to.isDirect ? to.peer : null),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.quickForwardIn(quickLeft), style: Tokens.caption.style.copyWith(color: p.accent)),
                Text(
                  l.quickForwardTo(to.roomId == state!.savedRoomId ? l.savedMessages : to.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Tokens.body.style.copyWith(color: p.label),
                ),
              ],
            ),
          ),
          CupertinoButton(
            key: const Key('quick-undo'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: () {
              quickTimer?.cancel();
              setState(() => pendingQuick = null);
            },
            child: Text(l.undo, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
  }

  // 보내는 이름 (tips 472 + 310).
  /// 472: a channel that signs posts and shows authors' profiles.
  bool get authorsOn => Features.channelTips && isChannel && signed && cfg['authors'] == true;

  /// 310: my public channels (I may write as them here).
  List<SendAsChoice> myChannels = const [];
  bool sendAsLoaded = false;
  PostAs? sendAsNow;

  /// Checked claims ("room|user" -> real admin?) and channel cards.
  static final asOk = <String, bool>{};
  static final asPeek = <String, LinkPeek>{};
  final asAsking = <String>{};

  Future<void> loadSendAs() async {
    if (!Features.channelTips || sendAsLoaded) return;
    sendAsLoaded = true;
    final s = state!;
    final group = isGroup && !isChannel && canPost;
    final mine = group ? await SendAs.myChannels(s, except: widget.roomId) : const <SendAsChoice>[];
    var now = SendAs.saved(s, widget.roomId);
    // A choice that no longer fits (channel gone, authors off) falls back to me.
    if (now != null && (now.channel ? !authorsOn : !mine.any((c) => c.as?.room == now!.room))) now = null;
    s.backend.setSendAs(widget.roomId, now);
    if (mounted) {
      setState(() {
        myChannels = mine;
        sendAsNow = now;
      });
    }
  }

  Future<void> chooseSendAs() async {
    final l = L.of(context);
    final s = state!;
    final me = SendAsChoice(null, myName.isEmpty ? displayId(s.backend.userId ?? '') : myName);
    final choices = authorsOn ? [me, SendAsChoice(const PostAs.channel(), widget.title, roomId: widget.roomId)] : [me, ...myChannels];
    final pick = await pickSendAs(context, choices: choices, current: sendAsNow?.toJson() ?? '');
    if (pick == null || !mounted) return;
    await SendAs.choose(s, widget.roomId, pick.as);
    if (!mounted) return;
    setState(() => sendAsNow = pick.as);
    showNotice(l.sendAsChanged(pick.name));
  }

  Widget sendAsButton(BuildContext context) {
    final now = sendAsNow;
    final face = now == null
        ? Avatar(name: myName.isEmpty ? displayId(state!.backend.userId ?? '') : myName, size: 24, userId: state!.backend.userId)
        : now.channel
        ? Avatar(name: widget.title, size: 24, roomId: widget.roomId, squircle: true, channel: true)
        : Avatar(
            name: myChannels.where((c) => c.as?.room == now.room).firstOrNull?.name ?? now.address,
            size: 24,
            roomId: now.room,
            squircle: true,
            channel: true,
          );
    return GestureDetector(
      key: const Key('send-as'),
      onTap: chooseSendAs,
      child: Padding(
        padding: EdgeInsets.only(left: Tokens.space[1]),
        child: face,
      ),
    );
  }

  /// Name above a message: the channel's in 310 (once checked), none for
  /// an admin posting as the channel (472), the sender's in groups.
  String? nameFor(Msg m) {
    final as = Features.channelTips ? m.postAs : null;
    if (isChannel) return signed && !(as?.channel ?? false) ? displayId(m.sender) : null;
    if (!isGroup || m.mine) return null;
    if (as != null && !as.channel && claimOk(as, m.sender)) {
      return asPeek[as.room]?.name ?? state!.chats.where((c) => c.roomId == as.room).firstOrNull?.name ?? as.address;
    }
    // Groups show a name like Telegram (Eric 2026-11-28): the name I saved
    // for them, else the name they set in this group, else their ID.
    final saved = aliasOf(state!, m.sender);
    if (saved.isNotEmpty) return saved;
    final theirs = (memberOf[m.sender]?.name ?? '').trim();
    return theirs.isNotEmpty && theirs != m.sender ? theirs : displayId(m.sender);
  }

  /// Photo beside a message: the author's in a channel that shows authors,
  /// the channel's for a checked 310 message.
  Widget? faceFor(Msg m) {
    if (!Features.channelTips) return null;
    final as = m.postAs;
    if (isChannel) {
      if (!authorsOn || (as?.channel ?? false) || m.mine) return null;
      return Avatar(key: Key('author-${m.id}'), name: displayId(m.sender), size: Tokens.authorFace, userId: m.sender);
    }
    if (!isGroup || m.mine || as == null || as.channel || !claimOk(as, m.sender)) return null;
    return GestureDetector(
      key: Key('as-channel-${m.id}'),
      onTap: () => openAsChannel(as),
      child: Avatar(name: nameFor(m) ?? as.address, size: Tokens.authorFace, roomId: as.room, squircle: true, channel: true, photo: asPeek[as.room]?.photo),
    );
  }

  /// Is the 310 claim checked and true? Starts the check once.
  bool claimOk(PostAs as, String sender) {
    final k = '${as.room}|$sender';
    final v = asOk[k];
    if (v != null) return v;
    if (asAsking.add(k)) unawaited(_checkClaim(as, sender, k));
    return false;
  }

  Future<void> _checkClaim(PostAs as, String sender, String k) async {
    final b = state!.backend;
    var ok = await b.checkSendAs(as.room, sender, widget.roomId).catchError((_) => false);
    if (ok && as.address.isNotEmpty && !asPeek.containsKey(as.room)) {
      try {
        final p = await b.peekAddress(as.address);
        // The address must lead to that very channel.
        if (p.roomId == as.room && p.channel) {
          asPeek[as.room] = p;
        } else {
          ok = false;
        }
      } catch (_) {}
    }
    asOk[k] = ok;
    if (mounted) setState(() {});
  }

  Future<void> openAsChannel(PostAs as) async {
    final mine = state!.chats.where((c) => c.roomId == as.room).firstOrNull;
    if (mine != null) return openChat(context, mine.roomId, mine.name);
    if (as.address.isNotEmpty) await openJoinLink(context, LinkTarget(kind: 'public', code: as.address, channel: true));
  }

  // 문의함 (tip 526).
  /// This room's channel when it is a subscriber's message room.
  String? get dmChannel => Features.channelTips ? ChannelDm.channelOf(cfg) : null;

  /// I'm the subscriber here (not one of the admins).
  bool get dmMine => dmChannel != null && ChannelDm.subscriberOf(cfg) == state!.backend.userId;

  Widget inboxWrap(Widget body) {
    final ch = widget.dmInbox;
    if (!Features.channelTips || ch == null) return body;
    final s = state!;
    final side = inboxSide(s);
    final tabs = InboxTabs(
      channel: ch,
      current: widget.roomId,
      side: side,
      onToggle: () async {
        await s.setOn(inboxSidePref, !side);
        if (mounted) setState(() {});
      },
      onPick: (room, name) {
        if (room == widget.roomId) return;
        openInboxRoom(context, room, name, ch);
      },
      onAll: () => Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, _, _) => ChannelInboxAllPage(
            channel: ch,
            title: s.chats.where((c) => c.roomId == ch).map((c) => nameOf(s, c)).firstOrNull ?? '',
            openRoom: (c, room, name) => openInboxRoom(c, room, name, ch),
          ),
        ),
      ),
    );
    return side
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              tabs,
              Expanded(child: body),
            ],
          )
        : Column(
            children: [
              tabs,
              Expanded(child: body),
            ],
          );
  }

  /// Subscriber: 💬 under the channel opens my room with its admins.
  Future<void> openChannelDm() async {
    final l = L.of(context);
    try {
      final room = await ChannelDm.open(state!, widget.roomId, widget.title);
      await state!.refresh();
      if (mounted) await openChat(context, room, widget.title);
    } catch (_) {
      if (mounted) showNotice(l.dmOpenFailed);
    }
  }

  /// 다음 안 읽은 채널 (tip 292): how far past the newest post the list is
  /// pulled, and the channel it would open.
  double pullUp = 0;
  ChatPreview? pullNext;
  bool pullGone = false;

  Widget nextPull(Widget list) {
    if (!Features.channelTips || !isChannel) return list;
    final s = state!;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis != Axis.vertical || pullGone) return false;
        // Reversed list: the newest end is the minimum; past it = pulling up.
        final past = n.metrics.minScrollExtent - n.metrics.pixels;
        if (n is ScrollUpdateNotification || n is OverscrollNotification) {
          final dragging = n is ScrollUpdateNotification ? n.dragDetails != null : (n as OverscrollNotification).dragDetails != null;
          final over = n is OverscrollNotification ? pullUp + (-n.overscroll).clamp(0.0, 1e9) : past;
          if (dragging) {
            final next = pullNext ?? nextUnreadChannel(s.chats, widget.roomId);
            final v = over > 0 && next != null ? over : 0.0;
            // Telegram: one selection tick the moment the ring is full.
            if (v >= Tokens.nextPull && pullUp < Tokens.nextPull) HapticFeedback.selectionClick();
            if (v != pullUp || next != pullNext)
              setState(() {
                pullUp = v;
                pullNext = next;
              });
          } else if (pullUp >= Tokens.nextPull && pullNext != null) {
            goNextChannel();
          } else if (pullUp != 0 && past <= 0) {
            setState(() => pullUp = 0);
          }
        } else if (n is ScrollEndNotification) {
          if (pullUp >= Tokens.nextPull && pullNext != null) {
            goNextChannel();
          } else if (pullUp != 0) {
            setState(() => pullUp = 0);
          }
        }
        return false;
      },
      child: Stack(
        children: [
          list,
          // Telegram: nothing for the first 12 pt, then the ring fills.
          if (pullUp > Tokens.nextDead && pullNext != null)
            Positioned(
              left: 0,
              right: 0,
              // Telegram: it rises with the pull from below the last post
              // (never over it), fully in view once the ring is full.
              bottom: Tokens.space[1] + math.min(0.0, pullUp - Tokens.nextPull),
              child: IgnorePointer(
                child: NextChannelHint(next: pullNext!, progress: ((pullUp - Tokens.nextDead) / Tokens.nextFill).clamp(0.0, 1.0)),
              ),
            ),
        ],
      ),
    );
  }

  void goNextChannel() {
    final next = pullNext;
    if (next == null || pullGone) return;
    pullGone = true;
    final nav = paneNav(context);
    final ctx = nav.context;
    if (Wide.on) {
      unawaited(openChat(ctx, next.roomId, next.name));
      return;
    }
    // Telegram: this channel leaves upward while the next one comes up
    // from below (not back to the list and in again).
    final me = ModalRoute.of(context);
    if (me is IosPageRoute) me.exitUp = true;
    nav.pop();
    unawaited(openChat(ctx, next.roomId, next.name, up: true));
  }

  Future<void> forwardMsg(Msg m) => forwardMany([m]);

  /// Forwards messages (oldest first) to one chat picked from the list.
  Future<void> forwardMany(List<Msg> list) async {
    final l = L.of(context);
    final to = await openSheet<String>(context, (_) => const ForwardPickPage());
    if (to == null || !mounted) return;
    try {
      for (final m in list) {
        await state!.backend.forward(widget.roomId, m.id, to);
      }
      // Forwarded into 저장한 메시지: remember where from (this device only).
      if (to == state!.savedRoomId && to != widget.roomId) {
        final after = await state!.backend.timeline(to, limit: 50);
        await setSavedFrom(state!, [for (final m in after.where((m) => m.mine).toList().reversed.take(list.length)) m.id], widget.roomId);
      }
      if (to == widget.roomId) await load();
      unawaited(state!.refresh());
      if (mounted) showNotice(l.forwardDone);
    } catch (_) {
      if (mounted) showNotice(l.forwardFailed);
    }
  }

  void openSearch() => setState(() {
    searching = true;
    stickersOpen = false;
  });

  void closeSearch() {
    searchInput.clear();
    setState(() {
      searching = false;
      searched = false;
      hits = const [];
      focusId = null;
    });
  }

  Future<void> runSearch(String term) async {
    // 저장한 메시지: an emoji tag searches by tag (Telegram).
    if (isSaved && savedTagChoices.contains(term.trim())) {
      setState(() => tagFilter = term.trim());
      return;
    }
    var found = await state!.backend.searchMessages(widget.roomId, term);
    // 가져온 대화: imported messages are on this phone, searched here.
    final q = term.trim().toLowerCase();
    if (q.isNotEmpty && imports.isNotEmpty) {
      final more = [
        for (final l in imports.values)
          for (final m in l)
            if (m.kind == 'text' && (m.body ?? '').toLowerCase().contains(q)) m,
      ];
      found = [...found, ...more]..sort((a, b) => b.time.compareTo(a.time));
    }
    if (!mounted) return;
    setState(() {
      hits = found;
      hitAt = 0;
      searched = term.trim().isNotEmpty;
    });
    if (found.isNotEmpty) await jumpTo(found.first.id);
  }

  Future<void> stepHit(int d) async {
    final i = hitAt + d;
    if (i < 0 || i >= hits.length) return;
    setState(() => hitAt = i);
    await jumpTo(hits[i].id);
  }

  /// Brings an older message into view: loads more history if needed,
  /// then scrolls until its bubble is built.
  Future<void> jumpTo(String id) async {
    walking = true;
    try {
      await walkTo(id);
    } finally {
      walking = false;
      // Rebuild where it landed: what is on screen now counts as seen.
      if (mounted) setState(() {});
    }
  }

  Future<void> walkTo(String id) async {
    setState(() => focusId = id);
    // An older imported message: show them all down to it.
    if (id.startsWith('imp:') && !msgs.any((m) => m.id == id)) {
      setState(() {
        importShown = 1 << 30;
        msgs = withImports();
      });
    }
    while (!msgs.any((m) => m.id == id) && limit < 2000) {
      limit *= 2;
      await load();
    }
    if (!msgs.any((m) => m.id == id)) {
      if (mounted) showNotice(L.of(context).msgLinkGone);
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    // Not built yet: start from the newest end and walk back in time.
    if (msgKeys[id]?.currentContext == null && scroll.hasClients) {
      scroll.jumpTo(0);
      await WidgetsBinding.instance.endOfFrame;
    }
    for (var i = 0; i < 60 && mounted; i++) {
      final ctx = msgKeys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 250));
        return;
      }
      if (!scroll.hasClients) return;
      final pos = scroll.position;
      final next = (pos.pixels + pos.viewportDimension * 0.8).clamp(0.0, pos.maxScrollExtent);
      if (next == pos.pixels) return;
      scroll.jumpTo(next);
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Top bar while searching (v1 layout, iOS 27 glass): search capsule +
  /// round X. Capsule 44 tall, X 44, 8 between, 16 side margins.
  GlassTopBar searchTop(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GlassTopBar(
      tint: p.chatBackground.withValues(alpha: 0.7),
      full: Row(
        children: [
          Expanded(
            child: LiquidGlass(
              radius: Tokens.capsule,
              child: SizedBox(
                height: Tokens.closeButton,
                child: CupertinoSearchTextField(
                  key: const Key('msg-search'),
                  controller: searchInput,
                  autofocus: true,
                  placeholder: isSaved ? l.savedSearchHint : l.searchThisChat,
                  backgroundColor: const Color(0x00000000),
                  borderRadius: BorderRadius.circular(Tokens.capsule),
                  style: Tokens.body.style.copyWith(color: p.label),
                  onSubmitted: runSearch,
                  onChanged: (v) {
                    if (v.trim().isEmpty) setState(() => hits = const []);
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: Tokens.space[1]),
          GlassCircle(key: const Key('search-cancel'), onTap: closeSearch, child: GlassCircle.icon(context, CupertinoIcons.xmark)),
        ],
      ),
    );
  }

  /// Bottom of the search (v1): left capsule = date jump + count, right =
  /// older / newer and "목록으로 보기". Capsules and circles 44 tall.
  Widget searchBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final has = hits.isNotEmpty;
    Widget capsule(String key, Widget child, VoidCallback onTap) => GestureDetector(
      key: Key(key),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LiquidGlass(
        radius: Tokens.capsule,
        child: Container(
          height: Tokens.closeButton,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
    Widget arrow(String key, IconData icon, bool on, VoidCallback go) => Opacity(
      opacity: on ? 1 : 0.35,
      child: GlassCircle(key: Key(key), onTap: on ? go : null, child: GlassCircle.icon(context, icon)),
    );
    final label = has ? l.searchCount(hitAt + 1, hits.length) : (searched ? l.searchNoHits : l.searchByDate);
    return Padding(
      key: const Key('search-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: capsule(
              'search-date',
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.calendar, size: Tokens.listIcon, color: p.label),
                  SizedBox(width: Tokens.space[1]),
                  Flexible(
                    child: Text(
                      label,
                      key: const Key('search-count'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: p.label),
                    ),
                  ),
                ],
              ),
              jumpToDate,
            ),
          ),
          if (!has) ...[
            SizedBox(width: Tokens.space[1]),
            GlassCircle(key: const Key('search-kind'), onTap: pickSearchKind, child: GlassCircle.icon(context, CupertinoIcons.line_horizontal_3_decrease)),
          ],
          if (isGroup && !has) ...[
            SizedBox(width: Tokens.space[1]),
            GlassCircle(
              key: const Key('search-mentions'),
              onTap: showMentions,
              child: Text('@', style: Tokens.body.style.copyWith(color: p.label, fontSize: 20)),
            ),
          ],
          if (has) ...[
            SizedBox(width: Tokens.space[1]),
            arrow('search-older', CupertinoIcons.chevron_up, hitAt < hits.length - 1, () => stepHit(1)),
            SizedBox(width: Tokens.space[1]),
            arrow('search-newer', CupertinoIcons.chevron_down, hitAt > 0, () => stepHit(-1)),
            SizedBox(width: Tokens.space[1]),
            capsule('search-list', Text(l.searchAsList, style: Tokens.body.style.copyWith(color: p.label)), openHitList),
          ],
        ],
      ),
    );
  }

  /// "날짜로 이동": the first message from the chosen day on.
  Future<void> jumpToDate() async {
    final l = L.of(context);
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    final got = await showCupertinoModalPopup<DateTime>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        title: l.searchByDate,
        children: [
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              key: const Key('date-wheel'),
              mode: CupertinoDatePickerMode.date,
              initialDateTime: day,
              maximumDate: day,
              onDateTimeChanged: (d) => day = d,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(Tokens.space[3]),
            child: AccentButton(key: const Key('date-done'), text: l.done, onTap: () => Navigator.pop(c, day)),
          ),
        ],
      ),
    );
    if (got == null || !mounted) return;
    final from = DateTime(got.year, got.month, got.day);
    // Load older history until that day is covered (or nothing more).
    while (limit < 2000 && msgs.isNotEmpty && msgs.first.time.isAfter(from)) {
      final before = msgs.length;
      limit *= 2;
      await load();
      if (msgs.length == before) break;
    }
    final hit = msgs.where((m) => !m.time.isBefore(from)).firstOrNull;
    if (hit == null) {
      if (mounted) showNotice(l.searchNoneOnDate);
      return;
    }
    await jumpTo(hit.id);
  }

  Future<void> openHitList() async {
    final id = await Navigator.of(context).push<String>(
      IosPageRoute(
        builder: (_) => SearchHitsPage(hits: hits, title: widget.title),
      ),
    );
    if (id == null || !mounted) return;
    final i = hits.indexWhere((m) => m.id == id);
    if (i >= 0) setState(() => hitAt = i);
    await jumpTo(id);
  }

  /// An imported message (다른 앱 대화 가져오기) with a day line above the
  /// first one of each day. Its menu only copies or quotes it: it has no
  /// message on the server to react to or pin.
  Widget importedRow(BuildContext context, Msg m, bool newDay) {
    final l = L.of(context);
    final mk = m.imported!;
    // Names: mine none; a Burumy account (the 1:1 partner) as in any chat;
    // everyone else by the name they had in the other app.
    final linked = !m.sender.startsWith('imp:');
    final name = m.mine ? null : (linked ? (isGroup ? displayId(m.sender) : null) : (mk.name.isEmpty ? null : mk.name));
    final Widget row;
    if (m.kind == 'system') {
      row = Padding(
        padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
        child: Center(
          child: Text(
            importNotice(l, m.body ?? ''),
            key: Key('imported-notice-${m.id}'),
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: paletteOf(context).secondaryLabel),
          ),
        ),
      );
    } else if (m.kind == 'text' || m.kind == 'deleted') {
      final shown = m.kind == 'deleted' ? m.copyWith(body: l.importDeleted) : m;
      final q = m.replyTo == null ? null : msgs.where((x) => x.id == m.replyTo).firstOrNull;
      row = BubbleGestures(
        key: Key('imported-${m.id}'),
        mine: m.mine,
        onLongPress: m.kind == 'text' ? () => importedMenu(m) : null,
        onReply: canPost && m.kind == 'text' ? () => quoteImported(m) : null,
        child: Bubble(
          msg: shown,
          roomId: widget.roomId,
          chatTitle: widget.title,
          senderName: name,
          quote: q,
          quoteName: q == null ? null : (q.mine ? null : q.imported?.name),
        ),
      );
    } else {
      row = GestureDetector(
        onLongPress: () => importedMenu(m),
        child: ImportedMedia(key: Key('imported-${m.id}'), msg: m, senderName: name),
      );
    }
    final p = paletteOf(context);
    return AnimatedContainer(
      key: msgKeys.putIfAbsent(m.id, GlobalKey.new),
      duration: const Duration(milliseconds: 200),
      color: m.id == focusId ? p.accent.withValues(alpha: 0.14) : p.accent.withValues(alpha: 0),
      child: newDay
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ImportDayLine(day: m.time),
                row,
              ],
            )
          : row,
    );
  }

  void quoteImported(Msg m) {
    final words = plainText(m.body ?? '').characters.take(1024).toString();
    final name = m.mine ? myName : (m.imported?.name.isNotEmpty == true ? m.imported!.name : whoName(context, m.sender));
    setState(() {
      replying = m.asQuote(words, otherChat: true, name: name);
      editing = null;
    });
  }

  Future<void> importedMenu(Msg m) async {
    final l = L.of(context);
    final text = m.kind == 'text' && (m.body ?? '').isNotEmpty;
    final choice = await showMessageMenu(
      context,
      mine: m.mine,
      reactions: const [],
      characters: false,
      selectable: text && !protected,
      quotable: false,
      bubble: m.kind == 'text' ? Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.title) : ImportedMedia(msg: m),
      items: [
        if (canPost && text) MenuItem('reply', l.reply, CupertinoIcons.arrowshape_turn_up_left),
        if (text && !protected) MenuItem('copy', l.copy, CupertinoIcons.doc_on_doc),
      ],
    );
    if (choice == 'reply') quoteImported(m);
    if (choice == 'copy') await Clipboard.setData(ClipboardData(text: plainText(m.body ?? '')));
  }

  /// 읽기 모드 (tip 475): the first web link in a text message, if it
  /// looks like a page (not a video or app link).
  String? readerUrl(Msg m) {
    if (!Features.tipsAiRead || m.kind != 'text' || m.body == null || !state!.on('reader_button', fallback: true)) return null;
    final url = m.preview?.url ?? RegExp(r'https?://[^\s<>()]+').firstMatch(m.body!)?.group(0);
    return url != null && Reader.offered(url) ? url : null;
  }

  Future<void> menu(Msg m) async {
    final l = L.of(context);
    final text = m.kind == 'text' && m.body != null;
    final forwardable = !protected && !m.viewOnce && m.body != null && const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind);
    final pinned = pins.contains(m.id);
    final saved = isSaved;
    // Notices in the middle (joins, calls) have no menu items of their own.
    final real = m.kind != 'notice';
    final isMarked = marked.contains(m.id);
    final isVeiled = veiledMsgs.contains(m.id);
    final readers = readersOf(m);
    final choice = await showMessageMenu(
      context,
      mine: m.mine,
      reactions: menuReactions,
      characters: allowedReactions(cfg) == null,
      selectable: text && !protected,
      // 인용 (tip 399): picked words become a partial-quote reply.
      quotable: Features.tipsReply && canPost && text && !protected,
      header: readLine(m) ?? (readers.isEmpty ? null : l.groupReadCount(readers.length)),
      headerId: readers.isEmpty ? null : 'readers',
      headerTrailing: readers.isEmpty
          ? null
          : ReaderFaces(ids: [for (final r in readers.take(3)) r.$1], names: {for (final r in readers.take(3)) r.$1: memberOf[r.$1]?.name ?? displayId(r.$1)}),
      footer: protected && Features.chatSafety ? l.protectMenuFooter : null,
      bubble: Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.title),
      items: [
        if (canPost) MenuItem('reply', l.reply, CupertinoIcons.arrowshape_turn_up_left),
        if (text && !protected) MenuItem('copy', l.copy, CupertinoIcons.doc_on_doc),
        if (text && m.kind == 'text' && state!.on(TrPrefs.button)) MenuItem('translate', l.translate, CupertinoIcons.globe),
        if (readerUrl(m) != null) MenuItem('reader', l.readerMenu, CupertinoIcons.book),
        if (m.mine && (text || mediaEditable(m)) && canPost && canEditNow(m)) MenuItem('edit', l.edit, CupertinoIcons.pencil),
        if (canPost && canPin) MenuItem('pin', pinned ? l.unpin : l.pin, pinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin),
        if (forwardable) MenuItem('forward', l.forward, CupertinoIcons.arrowshape_turn_up_right),
        if (real && (isGroup || isChannel)) MenuItem('link', l.copyMsgLink, CupertinoIcons.link),
        if (forwardable && !saved) MenuItem('save', l.saveToSaved, CupertinoIcons.bookmark),
        if (forwardable && !kIsWeb && (m.kind == 'image' || m.kind == 'video')) MenuItem('gallery', l.saveToGallery, CupertinoIcons.photo_on_rectangle),
        if (Features.funFx && forwardable && Gifs.isGifMsg(m)) MenuItem('gif-save', l.gifSave, CupertinoIcons.square_stack),
        // 알림음으로 저장 (tip 329): short voice / audio messages.
        if (m.kind == 'audio' && !protected && !m.viewOnce && m.body != null) MenuItem('tone', l.saveAsTone, CupertinoIcons.bell),
        if (saved) MenuItem('tag', l.tagMsg, CupertinoIcons.tag),
        if (real) MenuItem('remind', l.remindMe, CupertinoIcons.alarm),
        if (real) MenuItem('emergency', isMarked ? l.emergencyDeleteOff : l.emergencyDelete, CupertinoIcons.exclamationmark_shield),
        if (real) MenuItem('emergency-hide', isVeiled ? l.emergencyHideMsgOff : l.emergencyHideMsg, CupertinoIcons.eye_slash),
        if (m.poll != null && !m.poll!.closedAt(DateTime.now()) && !m.poll!.isQuiz && m.poll!.changeVote && m.poll!.mine.isNotEmpty)
          MenuItem('retract', l.pollRetract, CupertinoIcons.arrow_uturn_left),
        if (m.poll != null && m.mine && !m.poll!.closed) MenuItem('close-poll', l.pollClose, CupertinoIcons.stop_circle),
        if (m.card?.kind == 'flow' && FlowProgress.of(m.id).isNotEmpty) MenuItem('flow-revert', l.flowRevert, CupertinoIcons.arrow_counterclockwise),
        if (m.mine) MenuItem('delete', l.delete, CupertinoIcons.trash, danger: true),
        // 478: 신고 right in the menu for other people's messages (Telegram).
        if (Features.chatSafety && real && !m.mine && !isSaved) MenuItem('report', l.msgReport, CupertinoIcons.exclamationmark_bubble, danger: true),
        if (real) MenuItem('select', l.selectMsg, CupertinoIcons.checkmark_circle, group: true),
      ],
    );
    await doAction(m, choice);
  }

  /// Runs one message action (long-press menu or the select "더보기" sheet).
  Future<void> doAction(Msg m, String? choice) async {
    final l = L.of(context);
    final pinned = pins.contains(m.id);
    final isMarked = marked.contains(m.id);
    if (choice == 'pin' && pinned) choice = 'unpin';
    switch (choice) {
      case 'readers':
        await showReaders(m);
      case 'info':
        await showMessageInfo(m);
      case 'thread':
        await openThread(m);
      case 'report':
        await reportMsg(m);
      case 'reply':
        setState(() {
          replying = m;
          editing = null;
        });
      case 'edit':
        setState(() {
          replying = null;
          editing = m;
          editBytes = editName = null;
          editAbove = m.captionAbove;
        });
        input.text = m.kind == 'text' ? m.body ?? '' : m.caption ?? '';
      case 'copy':
        await Clipboard.setData(ClipboardData(text: plainText(m.body ?? '')));
      case 'reader':
        await openReader(context, readerUrl(m)!);
      case 'translate':
        await showTranslateSheet(context, text: plainText(m.body ?? ''), roomId: widget.roomId);
      case 'copied-part':
        showNotice(l.textCopied);
      case final String q when q.startsWith('quote-part:'):
        final part = pickedQuote(m, q.substring(11));
        if (part.isEmpty) return;
        setState(() {
          replying = m.asQuote(part);
          editing = null;
        });
      case 'forward':
        await forwardMsg(m);
      case 'link':
        await copyMsgLink(m);
      case 'save':
        await saveWithTag([m]);
      case 'gif-save':
        // 내 GIF (tip 558): encrypted on this phone, kept for me.
        var ok = false;
        try {
          ok = await Gifs.saveMsg(state!, widget.roomId, m);
        } catch (_) {}
        if (mounted) showNotice(ok ? l.gifSaved : l.saveFailed);
      case 'tone':
        await saveTone(m);
      case 'gallery':
        // 갤러리에 저장 (v1): never for 공유 비활성화 or view-once.
        final ok = await saveToGallery(state!.backend, widget.roomId, m);
        if (mounted) showNotice(ok ? l.savedToGallery : l.saveFailed);
      case 'tag':
        await tagSaved([m.id]);
      case 'retract':
        await state!.backend.vote(widget.roomId, m.id, const []);
        await load();
      case 'close-poll':
        await state!.backend.closePoll(widget.roomId, m.id);
        await load();
      case 'delete':
        startDelete([m.id]);
      case 'remind':
        await remind(m);
      case 'emergency':
        if (kIsWeb) {
          if (mounted) await showEmergencyWebNotice(context);
          return;
        }
        await state!.backend.markForDelete(widget.roomId, m.id, !isMarked);
        if (!mounted) return;
        setState(() => isMarked ? marked.remove(m.id) : marked.add(m.id));
        showNotice(isMarked ? l.emergencyUnmarked : l.emergencyMarked);
      case 'emergency-hide':
        if (kIsWeb) {
          if (mounted) await showEmergencyWebNotice(context);
          return;
        }
        final on = !veiledMsgs.contains(m.id);
        await state!.backend.markForHide(widget.roomId, m.id, on);
        if (!mounted) return;
        setState(() => on ? veiledMsgs.add(m.id) : veiledMsgs.remove(m.id));
        showNotice(on ? l.emergencyMsgHidden : l.emergencyUnhidden);
      case 'flow-revert':
        FlowProgress.reset(m.id);
      case 'select':
        startSelect(m);
      case 'pin' || 'unpin':
        // v1 고정 기간: a day, a week, a month or until unpinned.
        int? secs;
        var notify = false;
        final room = isGroup || isChannel;
        // 나만 고정 (tip 276): a 1:1 pin can stay on my phone only.
        final oneToOne = Features.tipsReply && !room && !isSaved;
        if (choice == 'unpin' && myPins.contains(m.id)) {
          await MyPins.unpin(state!, widget.roomId, m.id);
          pinAt = null;
          await load();
          return;
        }
        if (choice == 'pin') {
          if (room) {
            final r = await pickPin(context);
            if (r == null) return;
            (secs, notify) = r;
          } else if (oneToOne) {
            final r = await pickPinFor(context, titleOf(state!, widget.roomId, widget.title));
            if (r == null) return;
            final (s, both) = r;
            if (!both) {
              await MyPins.pin(state!, widget.roomId, m.id, until: s > 0 ? state!.backend.clock.add(Duration(seconds: s)) : null);
              pinAt = null;
              await load();
              if (mounted) showNotice(L.of(context).pinnedOnlyMe);
              return;
            }
            secs = s;
          } else {
            secs = await pickPinTime(context);
            if (secs == null) return;
          }
        }
        await state!.backend.pin(widget.roomId, m.id, choice == 'pin');
        // Groups/channels: "OO님이 메시지를 고정했어요" line; with
        // "모두에게 알림" every phone rings, else it arrives quietly.
        if (choice == 'pin' && room && mounted) {
          final text = previewText(context, kind: m.kind, body: m.body, caption: m.caption);
          await state!.backend.createCard(widget.roomId, 'pin', {'id': m.id, 'text': text, 'notify': notify}).catchError((_) {});
        }
        pinAt = null;
        final timed = secs != null && secs > 0;
        final had = (cfg['pin_until'] as Map?)?.containsKey(m.id) ?? false;
        if (timed || had) {
          final until = RoomRules.withPinUntil(cfg, m.id, timed ? state!.backend.clock.add(Duration(seconds: secs)) : null);
          await state!.backend.setRoomConfig(widget.roomId, 'pin_until', until.isEmpty ? null : until).catchError((_) {});
        }
        await load();
      case final String r when r.startsWith('react:'):
        await toggleReaction(m, r.substring(6));
    }
  }

  /// Select mode "더보기" (v1): the less common actions for one message.
  Future<void> moreSheet(Msg m) async {
    final l = L.of(context);
    final text = m.kind == 'text' && m.body != null;
    final real = m.kind != 'notice';
    final pinned = pins.contains(m.id);
    final isMarked = marked.contains(m.id);
    CupertinoActionSheetAction row(BuildContext c, String id, String label, {bool danger = false}) =>
        CupertinoActionSheetAction(key: Key('more-$id'), isDestructiveAction: danger, onPressed: () => Navigator.pop(c, id), child: Text(label));
    final choice = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (canPost) row(c, 'reply', l.reply),
          if (text && !protected) row(c, 'copy', l.copy),
          if (m.mine && (text || mediaEditable(m)) && canPost && canEditNow(m)) row(c, 'edit', l.edit),
          if (canPost && real && !isSaved) row(c, 'thread', l.threadReply),
          if (canPost && canPin) row(c, 'pin', pinned ? l.unpin : l.pin),
          if (real) row(c, 'emergency', isMarked ? l.emergencyDeleteOff : l.emergencyDelete),
          if (real) row(c, 'emergency-hide', veiledMsgs.contains(m.id) ? l.emergencyHideMsgOff : l.emergencyHideMsg),
          if (real) row(c, 'info', l.msgInfo),
          if (real && !m.mine) row(c, 'report', l.msgReport, danger: true),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (choice != null && mounted) await doAction(m, choice);
  }

  /// "읽음 · 오늘 오후 10:38" for my 1:1 message (null when unknown).
  String? readLine(Msg m) {
    if (!m.mine || isGroup || isChannel || readUntil == null || m.time.isAfter(readUntil!)) return null;
    final now = state!.backend.clock;
    final at = ReadTimes.of(state!.pref('readlog:${widget.roomId}', ''), m.time, now);
    if (at == null) return null;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = DateFormat.jm(lang).format(at);
    if (day == today) return l.readAtToday(time);
    if (day == today.subtract(const Duration(days: 1))) return l.readAtYesterday(time);
    return l.readAtDate(DateFormat.MMMd(lang).add_jm().format(at));
  }

  /// 누가 읽었는지 (tip 384): who read my group message and when, newest
  /// first (groups of up to 100; anonymous admins only show to admins).
  List<(String, DateTime)> readersOf(Msg m) {
    if (!m.mine || !isGroup || isChannel || memberOf.length > GroupReads.maxMembers || groupRcpt.isEmpty) return const [];
    final list = GroupReads.readers(state!.pref('readlog_g:${widget.roomId}', ''), groupRcpt, m.time, state!.backend.clock);
    final hide = isAdmin ? const <String>{} : AnonAdmins.current(cfg);
    return [
      for (final r in list)
        if (!hide.contains(r.$1) && memberOf.containsKey(r.$1)) r,
    ];
  }

  String readTimeText(DateTime at) {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final now = state!.backend.clock;
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = DateFormat.jm(lang).format(at);
    if (day == today) return l.groupReadToday(time);
    if (day == today.subtract(const Duration(days: 1))) return l.groupReadYesterday(time);
    return DateFormat.MMMd(lang).add_jm().format(at);
  }

  Future<void> showReaders(Msg m) async {
    final l = L.of(context);
    final readers = readersOf(m);
    if (readers.isEmpty) return;
    final unread = memberOf.length - 1 - readers.length;
    await showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) {
        final p = paletteOf(c);
        return GlassSheet(
          key: const Key('readers-sheet'),
          title: l.groupReadTitle(readers.length),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.55),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final (id, at) in readers)
                    Padding(
                      key: Key('reader-$id'),
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[1]),
                      child: Row(
                        children: [
                          Avatar(name: memberOf[id]?.name ?? displayId(id), size: 36, userId: id),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  memberOf[id]?.name ?? displayId(id),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tokens.body.style.copyWith(color: p.label),
                                ),
                                Row(
                                  children: [
                                    Icon(CupertinoIcons.checkmark_alt_circle_fill, size: 13, color: p.accent),
                                    const SizedBox(width: 3),
                                    Text(readTimeText(at), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                  ],
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
            Padding(
              key: const Key('readers-footer'),
              padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[1], Tokens.space[3] + Tokens.space[0], Tokens.space[3]),
              child: Text(
                unread > 0 ? '${l.groupReadNotYet(unread)} ${l.groupReadInfo}' : l.groupReadInfo,
                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
              ),
            ),
          ],
        );
      },
    );
  }

  /// "메시지 정보": when it was sent, read, edited, and when it disappears.
  Future<void> showMessageInfo(Msg m) async {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).toLanguageTag();
    final fmt = DateFormat.yMMMd(lang).add_jm();
    String? status;
    if (m.mine) {
      final read = !isGroup && !isChannel ? await state!.backend.readUntil(widget.roomId) : null;
      status = read != null && !read.isBefore(m.time) ? (readLine(m) ?? l.infoRead) : l.infoSentOnly;
    }
    if (!mounted) return;
    await showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        key: const Key('info-sheet'),
        title: l.msgInfo,
        children: [
          SheetRow(label: l.infoSent, trailing: fmt.format(m.time), onTap: () {}),
          if (status != null) SheetRow(key: const Key('info-status'), label: l.infoStatus, trailing: status, onTap: () {}),
          if (m.edited) SheetRow(key: const Key('info-edited'), label: l.edited, trailing: m.editedAt == null ? '✓' : fmt.format(m.editedAt!), onTap: () {}),
          if (m.edited && m.firstBody != null)
            Padding(
              key: const Key('info-first'),
              padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[1], Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.editFirstWords, style: Tokens.caption.style.copyWith(color: paletteOf(c).secondaryLabel)),
                  SizedBox(height: Tokens.space[0]),
                  Text(plainText(m.firstBody!), style: Tokens.preview.style.copyWith(color: paletteOf(c).label)),
                ],
              ),
            ),
          // 수정 기록: the photo before it was swapped stays in the message.
          if (m.mediaChanged)
            Padding(
              key: const Key('info-first-photo'),
              padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], Tokens.space[1], Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.editFirstPhoto, style: Tokens.caption.style.copyWith(color: paletteOf(c).secondaryLabel)),
                  SizedBox(height: Tokens.space[0]),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Tokens.radius[1]),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: EncryptedImage(roomId: widget.roomId, eventId: m.id),
                    ),
                  ),
                ],
              ),
            ),
          if (m.forwarded) SheetRow(label: l.forwarded, trailing: '✓', onTap: () {}),
          if (m.expiresAt != null) SheetRow(label: l.infoExpires, trailing: fmt.format(m.expiresAt!), onTap: () {}),
          SizedBox(height: Tokens.space[1]),
        ],
      ),
    );
  }

  /// 478 자세한 신고: reason → narrower reason → note. Stable codes go to
  /// the operator; "그냥 싫어요" stays on this phone.
  Future<void> reportMsgDetailed(Msg m) async {
    final l = L.of(context);
    final pick = await showReportSheet(context);
    if (pick == null || !mounted) return;
    final s = state!;
    if (pick.code == ReportReasons.impersonation) {
      final name = m.sender == chatRow?.peer ? chatRow!.name : displayId(m.sender);
      final done = await openSheet<bool>(context, (_) => ImpersonationReportPage(userId: m.sender, name: name));
      if (done == true && mounted) showNotice(l.reportImpDone);
      return;
    }
    if (pick.code == ReportReasons.dislike) {
      if (pick.dislike == 'block') {
        await s.backend.block(m.sender, true).catchError((_) {});
        await s.refresh();
        if (mounted) showNotice(l.reportBlockedSender);
      } else {
        await hideDisliked(s, widget.roomId, m.id);
        if (mounted) {
          setState(() {});
          showNotice(l.reportDislikeHidden);
        }
      }
      return;
    }
    final shown = m.kind == 'text' ? plainText(m.body ?? '') : previewTextL(l, kind: m.kind, body: m.body);
    final r = ReportReasons.find(pick.code);
    final label = [if (r != null && r.code.contains('.')) reportLabel(l, r.group), reportLabel(l, pick.code)].join(' > ');
    try {
      await s.backend.reportMessage(widget.roomId, m.id, ReportReasons.reportText(code: pick.code, label: label, note: pick.note), shown);
      var hidden = false;
      if (ReportReasons.illegalPicture(pick.code) && (isGroup || isChannel)) {
        hidden = await s.backend.reportContent(widget.roomId, m.id, m.sender, 'illegal', shown).catchError((_) => false);
        unawaited(s.refreshTrust());
      }
      if (mounted) showNotice(hidden ? l.reportHiddenNow : l.reportDone);
    } catch (_) {
      if (mounted) showNotice(l.reportFailed);
    }
  }

  /// "메시지 신고": pick a reason; the sheet says the operator reads it.
  Future<void> reportMsg(Msg m) async {
    if (Features.chatSafety) return reportMsgDetailed(m);
    final l = L.of(context);
    final p = paletteOf(context);
    final reasons = [
      l.reportIllegal,
      l.reportSpam,
      l.reportScam,
      l.reportViolence,
      l.reportSexual,
      l.reportChild,
      l.reportDrugs,
      l.reportPrivacy,
      l.reportOther,
    ];
    final why = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => GlassSheet(
        key: const Key('report-sheet'),
        title: l.msgReport,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[3] + Tokens.space[0], 0, Tokens.space[3] + Tokens.space[0], Tokens.space[1]),
            child: Text(l.reportNote, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
          ),
          SheetRow(key: const Key('report-impersonation'), label: l.reportImpersonation, onTap: () => Navigator.pop(c, '\u0000imp')),
          for (var i = 0; i < reasons.length; i++) SheetRow(key: Key('report-$i'), label: reasons[i], onTap: () => Navigator.pop(c, reasons[i])),
          SizedBox(height: Tokens.space[1]),
        ],
      ),
    );
    if (why == null || !mounted) return;
    if (why == '\u0000imp') {
      // 사칭: goes to the trust service with the account (not the message).
      final name = m.sender == chatRow?.peer ? chatRow!.name : displayId(m.sender);
      final done = await openSheet<bool>(context, (_) => ImpersonationReportPage(userId: m.sender, name: name));
      if (done == true && mounted) showNotice(l.reportImpDone);
      return;
    }
    final shown = m.kind == 'text' ? plainText(m.body ?? '') : previewTextL(l, kind: m.kind, body: m.body);
    try {
      await state!.backend.reportMessage(widget.roomId, m.id, why, shown);
      // Illegal pictures also go to the trust service: three reports from
      // different (older) accounts hide the message in every app at once,
      // before the operator looks (nights, weekends).
      var hidden = false;
      if ((why == l.reportIllegal || why == l.reportChild) && (isGroup || isChannel)) {
        hidden = await state!.backend.reportContent(widget.roomId, m.id, m.sender, 'illegal', shown).catchError((_) => false);
        unawaited(state!.refreshTrust());
      }
      if (mounted) showNotice(hidden ? l.reportHiddenNow : l.reportDone);
    } catch (_) {
      if (mounted) showNotice(l.reportFailed);
    }
  }

  /// Replies per thread start (message id).
  Map<String, List<Msg>> threads = {};

  Future<void> openThread(Msg root) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ThreadPage(roomId: widget.roomId, root: root, chatTitle: widget.title),
      ),
    );
    if (mounted) await load();
  }

  /// Select mode ("선택"): ids of the chosen messages; null = off.
  Set<String>? selected;

  void startSelect(Msg m) => setState(() {
    selected = {m.id};
    replying = null;
    editing = null;
    stickersOpen = false;
  });

  void endSelect() => setState(() => selected = null);

  void toggleSelect(Msg m) => setState(() {
    final s = selected!;
    s.contains(m.id) ? s.remove(m.id) : s.add(m.id);
  });

  /// The chosen messages, oldest first.
  List<Msg> get chosen => [
    for (final m in msgs)
      if (selected?.contains(m.id) ?? false) m,
  ];

  static bool canForward(Msg m) => !m.viewOnce && m.body != null && const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind);

  Future<void> selectAction(String what) async {
    final l = L.of(context);
    final list = chosen;
    if (list.isEmpty) return;
    switch (what) {
      case 'delete':
        endSelect();
        startDelete([for (final m in list) m.id]);
      case 'tag':
        endSelect();
        if (isSaved) {
          await tagSaved([for (final m in list) m.id]);
        } else {
          await saveWithTag(list.where(canForward).toList());
        }
      case 'share':
        // v1 "공유" = send to my other chats here (not other apps).
        endSelect();
        await forwardMany(list.where(canForward).toList());
      case 'copy':
        await Clipboard.setData(
          ClipboardData(
            text: [
              for (final m in list)
                if (m.kind == 'text' && m.body != null) plainText(m.body!),
            ].join('\n'),
          ),
        );
        endSelect();
        showNotice(l.copied);
      case 'forward':
        endSelect();
        await forwardMany(list.where(canForward).toList());
      case 'more':
        final m = list.single;
        endSelect();
        await moreSheet(m);
    }
  }

  /// Top bar while selecting (v1 layout): "메시지 비우기" · "N개 선택됨" · "취소".
  GlassTopBar selectBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return GlassTopBar.nav(
      leading: GlassPill(key: const Key('select-clear'), text: l.clearChat, onTap: clearAsk),
      middle: LiquidGlass(
        radius: Tokens.capsule,
        child: Container(
          height: Tokens.closeButton,
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
          child: Center(
            widthFactor: 1,
            child: Text(
              l.selectedN(selected!.length),
              key: const Key('select-count'),
              style: Tokens.body.style.copyWith(color: p.label),
            ),
          ),
        ),
      ),
      trailing: GlassPill(key: const Key('select-cancel'), text: l.cancel, onTap: endSelect),
      backgroundColor: p.chatBackground.withValues(alpha: 0.7),
    );
  }

  /// "메시지 비우기": clears this chat on my screen only.
  Future<void> clearAsk() async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.clearChatInfo),
        actions: [
          CupertinoActionSheetAction(key: const Key('clear-ok'), isDestructiveAction: true, onPressed: () => Navigator.pop(c, true), child: Text(l.clearChat)),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok != true || !mounted) return;
    await state!.setPref('cleared:${widget.roomId}', '${DateTime.now().millisecondsSinceEpoch}');
    endSelect();
    await load();
    if (mounted) showNotice(l.clearChatDone);
  }

  /// Bottom bar while selecting: five round glass buttons.
  Widget selectTools(BuildContext context) {
    final p = paletteOf(context);
    final list = chosen;
    final allMine = list.isNotEmpty && list.every((m) => m.mine);
    final fwd = !protected && list.isNotEmpty && list.every(canForward);
    Widget b(String id, IconData icon, bool on, {Color? color}) => Opacity(
      opacity: on ? 1 : 0.35,
      child: GlassCircle(
        key: Key('select-$id'),
        onTap: on ? () => selectAction(id) : null,
        child: Icon(icon, size: Tokens.listIcon, color: color ?? p.label),
      ),
    );
    return Padding(
      key: const Key('select-tools'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          b('delete', CupertinoIcons.trash, allMine, color: Palette.tileRed),
          b('tag', CupertinoIcons.tag, isSaved || fwd),
          b('share', CupertinoIcons.square_arrow_up, fwd),
          b('forward', CupertinoIcons.arrowshape_turn_up_right, fwd),
          b('more', CupertinoIcons.ellipsis, list.length == 1),
        ],
      ),
    );
  }

  Future<void> openInfo() async {
    if (isSaved) {
      await Navigator.of(context).push(IosPageRoute(builder: (_) => SavedInfoPage(roomId: widget.roomId)));
      return;
    }
    final r = await Navigator.of(context).push<String>(
      IosPageRoute(
        builder: (_) => ChatInfoPage(roomId: widget.roomId, title: widget.title, isGroup: isGroup, isChannel: isChannel),
      ),
    );
    if (r == 'search' && mounted) openSearch();
    if (mounted) {
      setState(() {});
      unawaited(load());
    }
  }

  /// The chat's photo in the top bar (44, like the round buttons).
  Widget headerPhoto(BuildContext context) {
    final s = AppScope.of(context);
    final c = s.chats.where((x) => x.roomId == widget.roomId).firstOrNull;
    final direct = c?.isDirect ?? !(isGroup || isChannel);
    return Avatar(
      name: titleOf(s, widget.roomId, widget.title),
      size: Tokens.closeButton,
      squircle: !direct,
      channel: c?.isChannel ?? isChannel,
      userId: direct ? c?.peer : null,
      roomId: widget.roomId,
      owner: c != null && c.isChannel ? c.peer : null,
    );
  }

  /// 사칭 막기: the 1:1 (or channel) this page shows, for badges and the
  /// first-chat card.
  ChatPreview? get chatRow => state?.chats.where((x) => x.roomId == widget.roomId).firstOrNull;

  /// Someone new wrote first and I haven't answered or accepted yet.
  bool get strangerMode {
    final c = chatRow, s = state;
    if (c == null || s == null || isSaved) return false;
    return needsFirstContactCard(
      isDirect: c.isDirect && !c.isChannel,
      peer: c.peer,
      friends: s.friendIds,
      accepted: s.acceptedStranger(widget.roomId),
      iWrote: msgs.any((m) => m.mine),
      bot: c.isBot,
    );
  }

  Future<void> acceptStranger() async {
    await state!.setPref('stranger_ok:${widget.roomId}', '1');
    // The same yes takes it out of 메시지 요청.
    await state!.acceptRequest(widget.roomId);
    if (mounted) setState(() {});
  }

  Future<void> blockStranger() async {
    final c = chatRow;
    if (c == null) return;
    try {
      await state!.backend.block(c.peer, true);
      await state!.backend.leave(widget.roomId);
      await state!.refresh();
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) showNotice(L.of(context).somethingWrong);
    }
  }

  Future<void> reportImpersonator() async {
    final c = chatRow;
    if (c == null) return;
    final done = await openSheet<bool>(context, (_) => ImpersonationReportPage(userId: c.peer, name: c.name));
    if (done == true && mounted) showNotice(L.of(context).reportImpDone);
  }

  /// 공유 비활성화: no copy, forward, save or capture in this chat.
  bool get protected => cfg['protect'] == true;

  /// 557: the pill above the composer says who turned sharing off.
  Widget protectNotice(BuildContext context) {
    final l = L.of(context);
    final me = state!.backend.userId ?? '';
    final by = cfg['protect_by'];
    final direct = chatRow?.isDirect == true && !isGroup && !isChannel;
    final mine = direct ? by == me : isAdmin;
    final text = !direct
        ? l.protectNoticeRoom
        : (by == me ? l.protectNoticeMine : (by is String && by.isNotEmpty ? l.protectNoticeOther(chatRow?.name ?? '') : l.protectNoticeRoom));
    return ProtectNotice(
      text: text,
      onTap: () async {
        if (!direct || !mine) {
          showNotice(direct ? l.protectOnlyOwner : l.protectMenuFooter);
          return;
        }
        final off = await showCupertinoModalPopup<bool>(
          useRootNavigator: !Wide.on,
          context: context,
          builder: (c) => IosActionSheet(
            actions: [
              CupertinoActionSheetAction(
                key: const Key('protect-off'),
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(c, true),
                child: Text(l.protectOff),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          ),
        );
        if (off != true || !mounted) return;
        await state!.backend.setRoomConfig(widget.roomId, 'protect', null);
        await state!.backend.setRoomConfig(widget.roomId, 'protect_by', null);
        await load();
        if (mounted) showNotice(l.protectOffDone);
      },
    );
  }

  /// Welcome + rules (encrypted pack, or an old room's plain settings).
  RoomTexts get roomTexts => RoomTexts.of(state!, widget.roomId, cfg);

  bool get isSaved => widget.roomId == state?.savedRoomId || widget.title == L.of(context).savedMessages;

  /// Saved messages: '' = all, 'note' = my notes, else the source chat.
  String savedSource = '';

  /// Saved messages: the chat slides left while the side list is open.
  Animation<double>? sideAnim;

  Future<void> openSavedSideList() async {
    final pick = await openSavedSide(context, msgs: msgs, current: savedSource, onAnim: (a) => setState(() => sideAnim = a));
    if (mounted) setState(() => sideAnim = null);
    if (pick == savedExit) {
      if (mounted) await Navigator.of(context).maybePop();
      return;
    }
    if (pick != null && mounted) {
      setState(() {
        savedSource = pick;
        tagFilter = '';
      });
    }
  }

  /// Saves copies in "저장한 메시지", then offers the 12 emoji tags (v1).
  Future<void> saveWithTag(List<Msg> list) async {
    final l = L.of(context);
    if (list.isEmpty) return;
    final List<String> copies;
    try {
      final b = state!.backend;
      final saved = await b.savedRoom(create: true);
      if (saved == null) throw StateError('no saved chat');
      for (final m in list) {
        await b.forward(widget.roomId, m.id, saved);
      }
      final after = await b.timeline(saved, limit: 50);
      copies = [for (final m in after.where((m) => m.mine).toList().reversed.take(list.length)) m.id];
      await setSavedFrom(state!, copies, widget.roomId);
    } catch (_) {
      if (mounted) showNotice(l.forwardFailed);
      return;
    }
    if (!mounted) return;
    final tag = await pickSavedTag(context, saved: true);
    if (tag != null) await setSavedTag(state!, copies, tag);
  }

  /// Inside "저장한 메시지": choose or remove the tag of messages.
  Future<void> tagSaved(List<String> ids) async {
    final tag = await pickSavedTag(context, saved: false, current: ids.length == 1 ? savedTags(state!)[ids.single] : null);
    if (tag == null || !mounted) return;
    await setSavedTag(state!, ids, tag.isEmpty ? null : tag);
    if (mounted) setState(() {});
  }

  /// Saved messages: the tag chosen in the filter row ('' = all).
  String tagFilter = '';

  static final _linkRe = RegExp(r'https?://\S+');
  bool hasLink(Msg m) => m.kind == 'text' && _linkRe.hasMatch(m.body ?? '');

  /// Saved messages: the tag on a bubble (Telegram shows it like a reaction).
  List<Reaction>? savedTagReaction(Msg m, Map<String, String> tagOf) {
    final t = tagOf[m.id];
    return t == null ? null : [Reaction(t, 1, 'tag')];
  }

  Widget tagRow(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final tags = savedTags(state!);
    final from = savedFrom(state!);
    // Counts follow the chat chosen in the side list (v1: 링크 1, ✅ 1, ❤ 1).
    final here = [
      for (final m in msgs)
        if (inSavedSource(m, savedSource, from)) m,
    ];
    final links = here.where(hasLink).length;
    final count = <String, int>{};
    for (final m in here) {
      final t = tags[m.id];
      if (t != null) count[t] = (count[t] ?? 0) + 1;
    }
    final used = [
      for (final t in savedTagChoices)
        if ((count[t] ?? 0) > 0) t,
    ];
    if (used.isEmpty && links == 0) return const SizedBox.shrink();
    Widget chip(String t, String label) {
      final on = tagFilter == t;
      return GestureDetector(
        key: Key('tag-filter-${t.isEmpty ? 'all' : t}'),
        onTap: () => setState(() => tagFilter = t),
        child: Container(
          height: 32,
          margin: EdgeInsets.only(right: Tokens.space[1]),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2]),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: on ? p.accent : p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Text(label, style: Tokens.preview.style.copyWith(color: on ? p.onAccent : p.label)),
        ),
      );
    }

    return SizedBox(
      key: const Key('tag-row'),
      height: 32 + Tokens.space[2],
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[0]),
        children: [chip('', l.tagAll), if (links > 0) chip('link', '${l.savedLinkTag} $links'), for (final t in used) chip(t, '$t ${count[t]}')],
      ),
    );
  }

  Future<void> remind(Msg m) async {
    final l = L.of(context);
    final at = await pickReminderTime(context);
    if (at == null || !mounted) return;
    await addReminder(state!, Reminder(roomId: widget.roomId, msgId: m.id, chat: widget.title, at: at));
    if (!mounted) return;
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm();
    showNotice(l.remindSet(fmt.format(at)));
  }

  /// Adds my emoji, or takes it back when I already chose it.
  Future<void> toggleReaction(Msg m, String key) async {
    final b = state!.backend;
    final mine = m.reactions.where((r) => r.key == key && r.mine != null).firstOrNull?.mine;
    if (mine == null) {
      // The room's reaction rules (admin tools).
      final ok = allowedReactions(cfg);
      if (ok != null && !ok.contains(key)) return;
      final shown = shownReactions(m);
      if (shown.length >= reactionsMax(cfg) && !shown.any((r) => r.key == key)) return;
      // Tip 341: up to 3 reactions of mine per message (free for everyone);
      // a 4th takes the place of my oldest one.
      if (Features.emojiStickers) {
        final mineNow = [
          for (final r in m.reactions)
            if (r.mine != null) r.mine!,
        ];
        if (mineNow.length >= myReactionsMax) await state!.backend.deleteMessage(widget.roomId, mineNow.first);
      }
    }
    if (mine != null) {
      await b.deleteMessage(widget.roomId, mine);
    } else {
      await b.react(widget.roomId, m.id, key);
    }
    await load();
  }

  bool photoShared = false;

  /// Room photo lines already seen (each fetches the photo once).
  final photoLines = <String>{};

  /// 알림음으로 저장 (tip 329): 5 seconds and 300 KB at most; kept in the
  /// encrypted store, then picked in a chat's alerts menu or Settings.
  Future<void> saveTone(Msg m) async {
    final l = L.of(context);
    final s = state!;
    final length = m.voice?.duration;
    String refusal(ToneRefusal r) => r == ToneRefusal.full ? l.toneFull(MySounds.most) : l.toneTooLong;
    if (length == null) return showNotice(l.toneTooLong);
    if (MySounds.check(s, m.size ?? 0, length) case final r?) return showNotice(refusal(r));
    try {
      final bytes = await Downloads.instance.get(s, widget.roomId, m);
      if (!mounted || bytes.isEmpty) return;
      if (MySounds.check(s, bytes.length, length) case final r?) return showNotice(refusal(r));
      final webm = bytes.length > 4 && bytes[0] == 0x1A && bytes[1] == 0x45 && bytes[2] == 0xDF && bytes[3] == 0xA3;
      final wav = bytes.length > 4 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46;
      final ogg = bytes.length > 4 && bytes[0] == 0x4F && bytes[1] == 0x67 && bytes[2] == 0x67 && bytes[3] == 0x53;
      final who = m.mine ? (myName.isEmpty ? l.you : myName) : (!isGroup && !isChannel ? widget.title : displayId(m.sender).replaceFirst('@', ''));
      await MySounds.add(
        s,
        l.toneDefaultName(who, MySounds.list(s).length + 1),
        bytes,
        length,
        webm ? 'audio/webm' : (ogg ? 'audio/ogg' : (wav ? 'audio/wav' : 'audio/mp4')),
      );
      if (mounted) showNotice(l.toneSaved);
    } catch (_) {
      if (mounted) showNotice(l.saveFailed);
    }
  }

  // ---- 그룹 묶음 #16 (94 익명 관리자, 556 멤버 태그) ----------------------

  /// Tags people put on themselves here (556).
  Map<String, String> ownTags = const {};

  /// 384: each member's newest read receipt (groups of up to 100).
  Map<String, (DateTime, DateTime)> groupRcpt = const {};

  /// 가루처럼 사라지기 (365): messages turning to dust right now, and the
  /// ones that vanished from the chat (someone deleted them, or the spam
  /// filter did) kept on screen for the effect.
  final dusting = <String>{};
  final ghosts = <String, Msg>{};

  /// Each message turns to dust once (not again when the delete lands).
  final dusted = <String>{};

  void dust(Iterable<Msg> gone) {
    for (final m in gone) {
      if (dusted.add(m.id)) dusting.add(m.id);
    }
  }

  void dustDone(String id) {
    if (!mounted) return;
    setState(() {
      dusting.remove(id);
      ghosts.remove(id);
    });
  }

  /// [shown] with the vanished messages put back in time order.
  List<Msg> withGhosts(List<Msg> shown) {
    if (ghosts.isEmpty) return shown;
    final ids = {for (final m in shown) m.id};
    final extra = ghosts.values.where((g) => !ids.contains(g.id)).toList();
    if (extra.isEmpty) return shown;
    final out = [...shown];
    for (final g in extra) {
      final at = out.indexWhere((m) => m.time.isAfter(g.time));
      at < 0 ? out.add(g) : out.insert(at, g);
    }
    return out;
  }

  /// One list row, turned to dust when its message is going.
  Widget dustRow(List<Msg> rows, int i, Widget Function() build) {
    if (i >= rows.length || dusting.isEmpty) return build();
    final m = rows[rows.length - 1 - i];
    if (!dusting.contains(m.id)) return build();
    return DustOut(
      key: ValueKey('dust-${m.id}'),
      onDone: () => dustDone(m.id),
      child: IgnorePointer(child: build()),
    );
  }

  /// 캡처 알림: "민지님이 한 번 보기 사진을 캡처했어요" in the middle;
  /// tap = what the notice is about.
  /// The "end-to-end encrypted" line at the top of a chat: a soft pill like the
  /// other centre lines, so it stays readable over a chat background.
  Widget noticePill(String text, Key key) {
    final p = paletteOf(context);
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[1]),
        decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Text(
          text,
          key: key,
          textAlign: TextAlign.center,
          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
        ),
      ),
    );
  }

  Widget shotLine(BuildContext context, Msg m) {
    final l = L.of(context);
    final p = paletteOf(context);
    final what = m.body ?? 'chat';
    final who = !isGroup && !isChannel
        ? titleOf(AppScope.of(context), widget.roomId, widget.title)
        : (memberOf[m.sender]?.name ?? whoName(context, m.sender).replaceFirst(RegExp('^@'), ''));
    return Padding(
      key: Key('shot-line-${m.id}'),
      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
      child: Center(
        child: GestureDetector(
          onTap: () => showInfoBanner(context, l.shotInfoTitle, l.shotInfoBody),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
            decoration: BoxDecoration(color: p.secondaryLabel.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.camera_viewfinder, size: 14, color: p.secondaryLabel),
                SizedBox(width: Tokens.space[0]),
                Flexible(
                  child: Text(
                    '${m.mine ? l.shotLineMine(what) : l.shotLine(who, what)} · ${DateFormat.jm(Localizations.localeOf(context).languageCode).format(m.time)}',
                    textAlign: TextAlign.center,
                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Sent by an admin while anonymous: shows the group, not the person.
  bool anonMsg(Msg m) => isGroup && !isChannel && AnonAdmins.sentAnon(cfg, m);

  /// The name line on a message (null = none, e.g. my own).
  String? senderNameOf(Msg m) {
    if (isGroup && !isChannel && anonMsg(m)) return m.mine ? null : titleOf(state!, widget.roomId, widget.title);
    return nameFor(m);
  }

  ShownTag? senderTagOf(Msg m) => isGroup && !isChannel && !m.mine && !anonMsg(m) ? MemberTags.of(cfg, ownTags, m.sender) : null;

  String whoName(BuildContext context, String sender) => sender == state?.backend.userId ? L.of(context).you : displayId(sender);

  Widget undoBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Container(
      key: const Key('undo-bar'),
      margin: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
      decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2] + 2)),
      child: Row(
        children: [
          Text('$undoLeft', style: Tokens.body.style.copyWith(color: p.accent)),
          SizedBox(width: Tokens.space[2]),
          Expanded(
            child: Text(l.deleted, style: Tokens.body.style.copyWith(color: p.label)),
          ),
          CupertinoButton(
            key: const Key('undo'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: undoDelete,
            child: Text(l.undo, style: Tokens.body.style.copyWith(color: p.accent)),
          ),
        ],
      ),
    );
  }

  /// Latest pinned message, under the title (like Telegram).
  /// Owner/admin: old messages someone changed long after sending (the
  /// "hide a picture in an old message" attack) that I haven't looked at.
  List<Msg> get unseenLate {
    if (!isAdmin || !(isGroup || isChannel)) return const [];
    final seen = state!.pref('late_seen:${widget.roomId}', '').split(',').toSet();
    return [
      for (final m in lateEdits(msgs, adminIds))
        if (!seen.contains(m.id)) m,
    ];
  }

  Future<void> openLateEdits() async {
    final s = state!;
    final list = unseenLate;
    final seen = s.pref('late_seen:${widget.roomId}', '').split(',').where((x) => x.isNotEmpty).toList();
    for (final m in list) {
      await s.logMod(widget.roomId, 'late_edit', memberOf[m.sender]?.name ?? displayId(m.sender));
    }
    // Keep the newest 500 ids so the setting stays small.
    await s.setPref('late_seen:${widget.roomId}', [...seen, for (final m in list) m.id].reversed.take(500).toList().reversed.join(','));
    if (!mounted) return;
    await Navigator.of(context).push(IosPageRoute(builder: (_) => LateEditsPage(roomId: widget.roomId)));
    await load();
  }

  Widget lateEditBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: GestureDetector(
        key: const Key('late-edit-bar'),
        onTap: openLateEdits,
        child: LiquidGlass(
          radius: 24,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
            child: Row(
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle_fill, size: Tokens.listIconSmall, color: Palette.tileOrange),
                SizedBox(width: Tokens.space[2]),
                Expanded(
                  child: Text(l.lateEditBanner(unseenLate.length), style: Tokens.caption.style.copyWith(color: p.label)),
                ),
                Icon(CupertinoIcons.chevron_right, size: Tokens.listIconSmall, color: p.secondaryLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget pinnedBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final at = (pinAt ?? pins.length - 1).clamp(0, pins.length - 1);
    final m = msgs.where((x) => x.id == pins[at]).firstOrNull;
    final many = pins.length > 1;
    // iOS 27: a floating glass capsule under the bar, not a full-width strip.
    // Telegram: each tap jumps to the shown pin and steps to the one before;
    // the left bar is split into one piece per pin (4 visible at most).
    return Padding(
      key: const Key('pinned-bar'),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: LiquidGlass(
        radius: 24,
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                key: const Key('pinned-bar-tap'),
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final id = pins[at];
                  setState(() => pinAt = at == 0 ? pins.length - 1 : at - 1);
                  await jumpTo(id);
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], 0, Tokens.space[1]),
                  child: Row(
                    children: [
                      PinSegments(count: pins.length, at: at, color: p.accent),
                      SizedBox(width: Tokens.space[2]),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${many ? l.pinnedMessageN(at + 1) : l.pinnedMessage}${myPins.contains(pins[at]) ? ' · ${l.pinOnlyMeTag}' : ''}',
                              key: const Key('pinned-bar-title'),
                              style: Tokens.caption.style.copyWith(color: p.accent),
                            ),
                            Text(
                              m == null ? '' : previewText(context, kind: m.kind, body: m.body, caption: m.caption),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.caption.style.copyWith(color: p.label),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CupertinoButton(
              key: const Key('pinned-list'),
              padding: EdgeInsets.zero,
              minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
              onPressed: openPinnedList,
              child: Icon(many ? CupertinoIcons.list_bullet : CupertinoIcons.pin, size: Tokens.listIconSmall, color: p.secondaryLabel),
            ),
            SizedBox(width: Tokens.space[1]),
          ],
        ),
      ),
    );
  }

  /// "고정 메시지 N개": every pin on one page; tapping one jumps to it.
  Future<void> openPinnedList() async {
    final id = await Navigator.of(context, rootNavigator: !Wide.on).push<String>(
      IosPageRoute(
        builder: (_) =>
            PinnedListPage(roomId: widget.roomId, title: widget.title, pins: pins, msgs: {for (final m in msgs) m.id: m}, canUnpin: canPost && canPin),
      ),
    );
    await load();
    if (id != null && mounted) await jumpTo(id);
  }

  /// The picked words, kept only where they really are in the message (the
  /// lifted bubble also holds the name and time).
  String pickedQuote(Msg m, String words) {
    final body = plainText(m.body ?? '');
    final w = words.trim();
    if (body.contains(w)) return w;
    return w.split('\n').where((x) => x.trim().isNotEmpty && body.contains(x.trim())).map((x) => x.trim()).join('\n');
  }

  /// Tap on the reply line (Telegram tip 399): pick part of the message,
  /// answer it in another chat, or stop answering.
  Future<void> replyOptions() async {
    final m = replying;
    if (m == null) return;
    final l = L.of(context);
    final text = m.body != null && (m.kind == 'text' || m.caption != null);
    // 공유 비활성화: its words may not leave this chat.
    final canLeave = !protected && m.id.isNotEmpty && text && !m.viewOnce;
    final choice = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (text && m.id.isNotEmpty)
            CupertinoActionSheetAction(key: const Key('reply-pick-part'), onPressed: () => Navigator.pop(c, 'part'), child: Text(l.quotePickPart)),
          if (canLeave)
            CupertinoActionSheetAction(key: const Key('reply-other-chat'), onPressed: () => Navigator.pop(c, 'other'), child: Text(l.replyInOtherChat)),
          CupertinoActionSheetAction(
            key: const Key('reply-cancel'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'none'),
            child: Text(l.replyNone),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case 'none':
        stopReplying();
      case 'part':
        await pickQuotePart();
      case 'other':
        await replyElsewhere();
    }
  }

  /// 답장 안 함.
  void stopReplying() => setState(() => replying = null);

  /// 특정 부분 인용: pick the words of the message being answered.
  Future<void> pickQuotePart() async {
    final m = replying;
    if (m == null) return;
    final words = plainText(m.caption ?? m.body ?? '');
    final got = await openSheet<String>(context, (_) => QuotePickPage(words: words, name: whoName(context, m.sender), start: m.quote));
    if (got == null || !mounted) return;
    setState(() => replying = got.isEmpty ? replying : replyingSource(m).asQuote(got));
  }

  /// 다른 대화에서 답장: pick a chat; the quote and the words typed go there.
  Future<void> replyElsewhere() async {
    final m = replying;
    if (m == null) return;
    final l = L.of(context);
    final to = await openSheet<String>(context, (_) => ForwardPickPage(title: l.replyInWhichChat, skip: widget.roomId));
    if (to == null || !mounted) return;
    final words = m.quote ?? plainText(m.caption ?? m.body ?? '');
    final name = whoName(context, m.sender).replaceFirst(RegExp('^@'), '');
    CrossReply.pending = CrossReply(to, m.asQuote(words.characters.take(1024).toString(), otherChat: true, name: name), input.text);
    input.clear();
    setState(() => replying = null);
    final row = state!.chats.where((c) => c.roomId == to).firstOrNull;
    if (mounted) await openChat(context, to, row?.name ?? '');
  }

  /// The real message behind a reply line (a partial quote keeps its id).
  Msg replyingSource(Msg m) => msgs.where((x) => x.id == m.id).firstOrNull ?? m;

  /// Tips 400 + 401: the blurred screen with 답장 | 링크 tabs.
  Future<void> composeOptions(String tab) async {
    final m = replying;
    final text = m != null && m.body != null && (m.kind == 'text' || m.caption != null);
    final r = await openComposeOptions(
      context,
      text: input.text,
      link: linkChoice,
      card: linkCard,
      tab: tab,
      replying: m,
      replyName: m == null ? '' : (m.quoteName ?? whoName(context, m.sender)),
      canQuotePart: m != null && text && m.id.isNotEmpty,
      canReplyElsewhere: m != null && !protected && m.id.isNotEmpty && text && !m.viewOnce,
    );
    if (r == null || !mounted) return;
    setState(() => linkChoice = r.link);
    switch (r.reply) {
      case 'none':
        stopReplying();
      case 'part':
        await pickQuotePart();
      case 'other':
        await replyElsewhere();
    }
  }

  /// Tip 400: the link line above the field: the card being made for the
  /// first (or picked) link. Tap = settings; ✕ = no card for this message.
  Widget linkBar(BuildContext context, List<String> links) {
    final l = L.of(context);
    final p = paletteOf(context);
    final url = links.contains(linkChoice.url) ? linkChoice.url! : links.first;
    return Container(
      key: const Key('link-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], 0),
      child: Row(
        children: [
          Icon(CupertinoIcons.link, color: p.accent, size: Tokens.listIcon),
          SizedBox(width: Tokens.space[2]),
          Container(width: 2, height: 34, color: p.accent),
          SizedBox(width: Tokens.space[1]),
          Expanded(
            child: GestureDetector(
              key: const Key('link-options'),
              behavior: HitTestBehavior.opaque,
              onTap: () => composeOptions('link'),
              onLongPress: () => composeOptions('link'),
              child: FutureBuilder<StoryLinkInfo?>(
                key: ValueKey(url),
                future: linkCard(url),
                builder: (context, snap) {
                  final c = snap.data;
                  final host = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? url;
                  return Row(
                    children: [
                      if (c != null && c.image.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(right: Tokens.space[1]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Tokens.radius[0] - 2),
                            child: Image.memory(Uint8List.fromList(c.image), width: 34, height: 34, fit: BoxFit.cover),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c?.site.isNotEmpty == true ? c!.site : host,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.caption.style.copyWith(color: p.accent),
                            ),
                            Text(
                              c?.title ?? (snap.connectionState == ConnectionState.done ? url : l.linkBarLoading),
                              key: const Key('link-bar-title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.caption.style.copyWith(color: p.label),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          CupertinoButton(
            key: const Key('link-bar-close'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: () => setState(() => linkChoice = linkChoice.copyWith(off: true)),
            child: Icon(CupertinoIcons.xmark, color: p.secondaryLabel, size: Tokens.listIconSmall),
          ),
        ],
      ),
    );
  }

  /// Shown above the composer while answering or fixing a message.
  Widget modeBar(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final m = (editing ?? replying)!;
    // 부분 인용 / 다른 대화 (tip 399): the picked words and whose they are.
    final part = editing == null ? m.quote : null;
    final other = part != null && m.id.isEmpty;
    final who = editing != null
        ? (editing!.kind != 'text' || editBytes != null ? l.editingMedia : l.editing)
        : other
        ? l.replyFromOtherChat(m.quoteName ?? '')
        : part != null
        ? l.quotingWho(whoName(context, m.sender))
        : whoName(context, m.sender);
    final options = Features.tipsReply && editing == null;
    return Container(
      key: const Key('mode-bar'),
      padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], 0),
      child: Row(
        children: [
          Icon(
            editing != null
                ? CupertinoIcons.pencil
                : part != null
                ? CupertinoIcons.text_quote
                : CupertinoIcons.reply,
            color: p.accent,
            size: Tokens.listIcon,
          ),
          SizedBox(width: Tokens.space[2]),
          Container(width: 2, height: 34, color: p.accent),
          SizedBox(width: Tokens.space[1]),
          // 사진 수정: the photo it will have (tap the bar for options).
          if (editing != null && (editBytes != null || editing!.kind == 'image'))
            GestureDetector(
              key: const Key('edit-media-thumb'),
              onTap: editMediaOptions,
              child: Padding(
                padding: EdgeInsets.only(right: Tokens.space[1]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Tokens.radius[0] / 2),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: editBytes != null
                        ? (mimeOf(editName ?? '').startsWith('image/')
                              ? Image.memory(Uint8List.fromList(editBytes!), fit: BoxFit.cover)
                              : ColoredBox(
                                  color: p.background,
                                  child: Icon(CupertinoIcons.videocam_fill, size: 18, color: p.accent),
                                ))
                        : EncryptedImage(roomId: widget.roomId, eventId: editing!.id, msg: editing),
                  ),
                ),
              ),
            ),
          Expanded(
            // Telegram: tap (or hold) the reply line for 인용 / 다른 대화 / 답장 안 함.
            child: GestureDetector(
              key: const Key('mode-options'),
              behavior: HitTestBehavior.opaque,
              onTap: editing != null
                  ? editMediaOptions
                  : options
                  ? (Features.tipsLink ? () => composeOptions('reply') : replyOptions)
                  : null,
              onLongPress: options ? (Features.tipsLink ? () => composeOptions('reply') : replyOptions) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    who,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.caption.style.copyWith(color: p.accent),
                  ),
                  Text(
                    part ??
                        (editing != null && (editing!.kind != 'text' || editBytes != null)
                            ? (editBytes != null ? l.editNewPhotoPicked : l.editMediaHint)
                            : previewText(context, kind: m.kind, body: m.body)),
                    key: const Key('mode-text'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Tokens.caption.style.copyWith(color: p.label),
                  ),
                ],
              ),
            ),
          ),
          CupertinoButton(
            key: const Key('mode-close'),
            padding: EdgeInsets.zero,
            minimumSize: const Size(Tokens.closeButton, Tokens.closeButton),
            onPressed: () {
              if (editing != null) input.clear();
              setState(() {
                replying = editing = null;
                editBytes = editName = null;
              });
            },
            child: Icon(CupertinoIcons.xmark, color: p.secondaryLabel, size: Tokens.listIconSmall),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final tagOf = isSaved ? savedTags(state!) : const <String, String>{};
    final from = isSaved ? savedFrom(state!) : const <String, String>{};
    LightIndex.note(msgs);
    final shown = withGhosts(msgs)
        .where(
          (m) =>
              (!(pendingDelete?.contains(m.id) ?? false) || dusting.contains(m.id)) &&
              // A video's light copy (479 · 480) is not its own message.
              !LightIndex.isLight(m) &&
              inTopic(m) &&
              (tagFilter.isEmpty || (tagFilter == 'link' ? hasLink(m) : tagOf[m.id] == tagFilter)) &&
              (!isSaved || inSavedSource(m, savedSource, from)),
        )
        .toList();
    // 묶어서 보내기: an album shows as one bubble (selecting keeps them apart).
    final (folded, albums) = selected == null ? foldAlbums(shown) : (shown, const <String, List<Msg>>{});
    // 환영 인사: right after I joined, a bubble only I see (new members).
    final joined = memberOf.isEmpty ? null : RoomTexts.joinedAt(state!, widget.roomId, memberOf[state!.backend.userId]?.since);
    final rowsNoShots =
        !isSaved &&
            (isGroup || isChannel) &&
            memberOf.isNotEmpty &&
            selected == null &&
            !searching &&
            roomTexts.welcomeFor(state!, widget.roomId, admin: isAdmin, joined: joined)
        ? withWelcome(folded, joined)
        : folded;
    // 캡처 알림 (우리식): who took a screenshot here, by time between messages.
    final rows = Features.ownWay && !isSaved && selected == null && !searching
        ? ShotAlert.mix(rowsNoShots, ShotAlert.asMsgs(state!, widget.roomId))
        : rowsNoShots;
    final sourceChat = isSaved && savedSource.isNotEmpty && savedSource != 'note' ? savedSource : null;
    final stranger = strangerMode;
    final helloShown = loadedOnce && msgs.isEmpty && pendingDelete == null && !isGroup && !isChannel && !isSaved && !stranger && !searching && selected == null;
    final anim = sideAnim ?? kAlwaysDismissedAnimation;
    final page = CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: selected != null
          ? selectBar(context)
          : searching
          ? searchTop(context)
          : GlassTopBar.nav(
              // Hold: the chats I came through (Telegram tip 321).
              leading: Builder(
                builder: (bc) => GlassBack(
                  onLongPress: () => openBackTrail(bc, widget.roomId, wide: Wide.on, open: (id, name) => openChat(bc, id, name)),
                ),
              ),
              // v1 layout, Telegram sizes: a glass capsule with the lock,
              // name and '끝까지 잠김' (or who is typing); photo on the right.
              middle: GestureDetector(
                key: const Key('chat-title'),
                onTap: openInfo,
                child: LiquidGlass(
                  radius: Tokens.capsule,
                  child: Container(
                    height: Tokens.closeButton,
                    constraints: const BoxConstraints(minWidth: Tokens.titlePillMin),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                    child: DefaultTextStyle.merge(
                      style: Tokens.navTitle.style,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sourceChat != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Avatar(name: savedSourceName(state!, sourceChat), size: 22, roomId: sourceChat),
                                SizedBox(width: Tokens.space[1]),
                                Flexible(child: Text(savedSourceName(state!, sourceChat), key: const Key('saved-source-title'))),
                              ],
                            )
                          else if (isSaved)
                            Text(savedSource == 'note' ? l.savedNotes : l.savedMessages)
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // A guarded public room isn't "locked end to end" for the guard.
                                if (!guarded) ...[Icon(CupertinoIcons.lock, key: const Key('title-lock'), size: 12, color: p.label), const SizedBox(width: 3)],
                                Flexible(
                                  child: Text(
                                    widget.topic != null && topics.byId(widget.topic) != null
                                        ? topicName(l, topics.byId(widget.topic)!)
                                        : titleOf(AppScope.of(context), widget.roomId, widget.title),
                                  ),
                                ),
                                if (chatRow != null && (chatRow!.isDirect || chatRow!.isChannel))
                                  TrustMark(key: const Key('title-trust'), user: chatRow!.peer, name: chatRow!.name, size: 13),
                                if (Features.emojiStickers && chatRow != null && chatRow!.isDirect)
                                  StatusMark(key: const Key('title-status'), user: chatRow!.peer, size: 14),
                              ],
                            ),
                          if (isSaved && savedSource.isEmpty && savedSources(msgs, from).isNotEmpty)
                            Text(
                              l.savedChatsCount(savedSources(msgs, from).length),
                              key: const Key('saved-count'),
                              style: Tokens.navSubtitle.style.copyWith(color: p.secondaryLabel),
                            ),
                          if (typers.isNotEmpty)
                            Text(
                              isGroup ? '${typers.map(displayId).join(', ')} · ${l.typing}' : l.typing,
                              key: const Key('typing'),
                              style: Tokens.navSubtitle.style.copyWith(color: p.accent),
                            )
                          else if (!isSaved)
                            Text(
                              guarded ? l.chatGuarded : l.chatLocked,
                              key: Key(guarded ? 'title-guarded' : 'title-locked'),
                              style: Tokens.navSubtitle.style.copyWith(color: guarded ? p.secondaryLabel : p.accent),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              backgroundColor: p.chatBackground.withValues(alpha: 0.7),
              border: null,
              // Telegram: the capsule may stretch up to 13pt from the buttons.
              middleInset: isSaved ? 96 : Tokens.closeButton + Tokens.titlePillGap,
              // Telegram chat header: buttons centred 27pt under the status bar.
              lift: Tokens.chatBarLift,
              trailing: isSaved
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassCircle(key: const Key('saved-search'), onTap: openSearch, child: GlassCircle.icon(context, CupertinoIcons.search)),
                        SizedBox(width: Tokens.space[1]),
                        GlassCircle(key: const Key('saved-side-open'), onTap: openSavedSideList, child: GlassCircle.icon(context, CupertinoIcons.sidebar_left)),
                      ],
                    )
                  : GestureDetector(key: const Key('title-photo'), onTap: openInfo, child: headerPhoto(context)),
            ),
      child: ChatWallpaper(
        roomId: widget.roomId,
        roomWall: RoomLook.from(cfg).wall,
        child: SafeArea(
          child: Column(
            children: [
              if (stranger)
                FirstContactCard(
                  key: Key('first-contact-${widget.roomId}'),
                  roomId: widget.roomId,
                  peer: chatRow!.peer,
                  name: chatRow!.name,
                  onAccept: acceptStranger,
                  onBlock: blockStranger,
                  onReport: reportImpersonator,
                ),
              if (pins.isNotEmpty) pinnedBar(context),
              // 1년 전 오늘 (우리식): saved pictures from this day, picked on this phone.
              if (isSaved && Features.ownWay && Memories.shown(AppScope.of(context))) MemoriesBar(roomId: widget.roomId, onJump: (id) => jumpTo(id)),
              // 양쪽 같은 배경 (tips 387 + 410).
              if (chatRow?.isDirect == true && wallNote(AppScope.of(context), widget.roomId) != null)
                WallNoteCard(roomId: widget.roomId, peerName: chatRow!.name),
              if (unseenLate.isNotEmpty) lateEditBar(context),
              if (showTranslateBar) TranslateBar(roomId: widget.roomId, lang: trLang!),
              if (Features.tipsAudio) const AudioMiniBar(),
              UnreadSummaryBar(roomId: widget.roomId, unread: unreadAtOpen, msgs: msgs, blocked: protected),
              EarlierBar(roomId: widget.roomId, title: widget.title),
              if (isSaved) tagRow(context),
              if (topicTabs) topicNav(context, rail: false),
              JumpsArea(
                jumps: jumpButtons(),
                child: topicListMode
                    ? TopicListBody(
                        topics: topics,
                        msgs: msgs,
                        unread: topicUnread,
                        nameOf: (u) => memberOf[u]?.name ?? displayId(u),
                        onOpen: openTopicPage,
                        onAdd: canManageTopics ? addTopic : null,
                        onHold: canManageTopics ? holdTopic : null,
                      )
                    : topicRail
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          topicNav(context, rail: true),
                          Expanded(
                            child: ListView.builder(
                              key: listKey,
                              controller: scroll,
                              reverse: true,
                              // 292: a short channel can still be pulled for the next one.
                              // Telegram: the messages always bounce, even when they do not fill the screen.
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[1]),
                              itemCount: rows.length + 1,
                              itemBuilder: (c, i) => withTopicLine(
                                rows,
                                i,
                                dustRow(rows, i, () {
                                  if (i == rows.length && rows.isEmpty && loadedOnce && dmMine) {
                                    return SizedBox(
                                      height: MediaQuery.sizeOf(context).height * .55,
                                      child: ChannelDmEmpty(channelName: widget.title),
                                    );
                                  }
                                  if (i == rows.length && rows.isEmpty && helloShown) {
                                    // A new 1:1 chat: the hello card in the middle (TelegramTips 80).
                                    return SizedBox(
                                      height: MediaQuery.sizeOf(context).height * .62,
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: FirstHelloCard(
                                              roomId: widget.roomId,
                                              name: titleOf(AppScope.of(context), widget.roomId, widget.title),
                                              onSend: (id) async {
                                                await state!.backend.sendSticker(widget.roomId, id);
                                                await load();
                                              },
                                            ),
                                          ),
                                          noticePill(l.encryptedNotice, const Key('e2e-notice')),
                                        ],
                                      ),
                                    );
                                  }
                                  if (i == rows.length) {
                                    return Padding(
                                      padding: EdgeInsets.all(Tokens.space[3]),
                                      child: noticePill(guarded ? l.guardNotice : l.encryptedNotice, Key(guarded ? 'guard-notice' : 'e2e-notice')),
                                    );
                                  }
                                  final m = rows[rows.length - 1 - i];
                                  // 캡처 알림: a centre line, not a message.
                                  if (m.kind == 'shot') return shotLine(context, m);
                                  noteSeen(m.id);
                                  // 다른 앱 대화 가져오기: the import line and its messages.
                                  if (m.kind == 'card' && m.card?.kind == 'import') {
                                    return ImportCardLine(
                                      key: Key('import-card-${m.id}'),
                                      msg: m,
                                      who: whoName(context, m.sender).replaceFirst(RegExp('^@'), ''),
                                      onDelete: m.mine ? () => startDelete([m.id]) : null,
                                    );
                                  }
                                  if (m.imported != null) {
                                    final at = rows.length - 1 - i;
                                    final prev = at > 0 ? rows[at - 1] : null;
                                    final newDay =
                                        prev == null || !(prev.time.year == m.time.year && prev.time.month == m.time.month && prev.time.day == m.time.day);
                                    return importedRow(context, m, newDay);
                                  }
                                  if (m.kind == 'welcome') {
                                    return WelcomeBubble(
                                      roomId: widget.roomId,
                                      roomName: titleOf(AppScope.of(context), widget.roomId, widget.title),
                                      texts: roomTexts,
                                      channel: isChannel,
                                      onHold: () => deleteWelcome(context, widget.roomId),
                                    );
                                  }
                                  if (m.kind == 'room_photo') {
                                    final kind = isChannel ? 'channel' : 'group';
                                    // A new photo line: fetch the photo again (once per line).
                                    if (photoLines.add(m.id)) AppScope.read(context).roomPhoto(widget.roomId, fresh: true);
                                    final who = memberOf[m.sender]?.name ?? displayId(m.sender);
                                    return Padding(
                                      key: Key('room-photo-line-${m.id}'),
                                      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                      child: Center(
                                        child: Text(
                                          m.mine ? l.roomPhotoLineMine(kind, m.body ?? 'set') : l.roomPhotoLine(who, kind, m.body ?? 'set'),
                                          textAlign: TextAlign.center,
                                          style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                        ),
                                      ),
                                    );
                                  }
                                  if (m.kind == 'opened') {
                                    return Padding(
                                      key: const Key('opened-line'),
                                      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                      child: Center(
                                        child: Text(l.viewOnceOpenedLine, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                      ),
                                    );
                                  }
                                  if (m.kind == 'call' && m.call != null) {
                                    return CallLine(
                                      key: Key('call-line-${m.id}'),
                                      msg: m,
                                      onCallBack: isGroup || isChannel ? null : (video) => startCall(context, widget.roomId, widget.title, video: video),
                                    );
                                  }
                                  if (m.kind == 'verify') {
                                    // A request to check each other's keys: a centred card
                                    // (only the other person's request has a button).
                                    return Padding(
                                      key: Key('verify-line-${m.id}'),
                                      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                                          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(CupertinoIcons.lock_shield, size: Tokens.listIconSmall, color: p.accent),
                                              SizedBox(width: Tokens.space[1]),
                                              Text(l.verifyRequestLine, style: Tokens.caption.style.copyWith(color: p.label)),
                                              SizedBox(width: Tokens.space[1]),
                                              if (!m.mine)
                                                GestureDetector(
                                                  key: Key('verify-open-${m.id}'),
                                                  onTap: () =>
                                                      openSheet<void>(context, (_) => VerifyPage(userId: m.sender, name: displayId(m.sender), flowId: m.id)),
                                                  child: Container(
                                                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                                                    decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                                    child: Text(l.verifyOpen, style: Tokens.caption.style.copyWith(color: p.onAccent)),
                                                  ),
                                                )
                                              else
                                                SizedBox(width: Tokens.space[1]),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  // 커뮤니티: "이 그룹을 ○○ 커뮤니티에 추가했어요 · 보기" (centred, no bubble).
                                  if (m.kind == 'card' && m.card?.kind == 'community') return CommunityCardBubble(card: m.card!);
                                  // 사진 제안 (tip 373): photo in a circle + "사진 보기".
                                  if (m.kind == 'card' && m.card?.kind == 'photo') {
                                    final st = AppScope.of(context);
                                    final who = aliasOf(st, m.sender);
                                    return PhotoSuggestBubble(
                                      m: m,
                                      name: who.isNotEmpty ? who : (isGroup ? displayId(m.sender) : titleOf(st, widget.roomId, widget.title)),
                                    );
                                  }
                                  if (suggestRow(context, m) case final w?) return w;
                                  // "OO님이 메시지를 고정했어요": tap jumps to the pinned message.
                                  if (m.kind == 'card' && m.card?.kind == 'pin') {
                                    return PinLine(
                                      key: Key('pin-line-${m.id}'),
                                      who: m.mine ? null : whoName(context, m.sender).replaceFirst(RegExp('^@'), ''),
                                      text: m.card!.text('text'),
                                      onTap: () => jumpTo(m.card!.text('id')),
                                    );
                                  }
                                  if (m.kind == 'timer') {
                                    final secs = int.tryParse(m.body ?? '') ?? 0;
                                    return Padding(
                                      key: const Key('timer-line'),
                                      padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                      child: Center(
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                                          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                          child: Text(
                                            secs == 0 ? l.timerOffLine : l.timerLine(timerLabel(context, secs)),
                                            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  // Someone new: photos, videos and link cards wait until I accept.
                                  if (stranger && !m.mine && (m.kind == 'image' || m.kind == 'video' || m.preview != null)) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        key: Key('stranger-hidden-${m.id}'),
                                        margin: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
                                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                                        decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              m.preview != null ? CupertinoIcons.link : CupertinoIcons.eye_slash,
                                              size: Tokens.listIconSmall,
                                              color: p.secondaryLabel,
                                            ),
                                            SizedBox(width: Tokens.space[1]),
                                            Text(l.firstMediaHidden, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  // Reported as illegal by several people (or the operator):
                                  // hidden in every app until the operator decides.
                                  if (state!.trust.hidden.contains(m.id)) {
                                    return GestureDetector(
                                      onLongPress: isAdmin || m.mine ? () => menu(m) : null,
                                      child: hiddenLine(
                                        context,
                                        Key('report-hidden-${m.id}'),
                                        CupertinoIcons.exclamationmark_shield,
                                        l.reportHiddenLine,
                                        m.mine,
                                      ),
                                    );
                                  }
                                  // 478 "그냥 싫어요" → hidden on this phone only.
                                  if (Features.chatSafety && dislikedIn(state!, widget.roomId).contains(m.id)) {
                                    return hiddenLine(context, Key('disliked-${m.id}'), CupertinoIcons.eye_slash, l.reportHiddenMsg, false);
                                  }
                                  // New member's photo/video/link while the room's limit is on.
                                  if (hiddenForNew(m)) {
                                    return hiddenLine(context, Key('new-hidden-${m.id}'), CupertinoIcons.eye_slash, l.newMediaHidden, false);
                                  }
                                  final q = m.replyTo == null ? null : msgs.where((x) => x.id == m.replyTo).firstOrNull;
                                  final focused = m.id == focusId;
                                  return AnimatedContainer(
                                    key: msgKeys.putIfAbsent(m.id, GlobalKey.new),
                                    duration: const Duration(milliseconds: 200),
                                    color: focused ? p.accent.withValues(alpha: 0.14) : p.accent.withValues(alpha: 0),
                                    // Settings > Chats: double tap = my quick reaction (a
                                    // plain pointer listener, so taps inside the bubble are
                                    // not slowed down), swipe left = reply.
                                    child: selected != null
                                        ? GestureDetector(
                                            key: Key('select-row-${m.id}'),
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => toggleSelect(m),
                                            child: Row(
                                              children: [
                                                SelectCircle(on: selected!.contains(m.id)),
                                                Expanded(
                                                  child: IgnorePointer(
                                                    child: Bubble(
                                                      msg: m,
                                                      roomId: widget.roomId,
                                                      read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                                      senderName: senderNameOf(m),
                                                      senderTag: senderTagOf(m),
                                                      senderAnon: anonMsg(m),
                                                      senderFace: faceFor(m),
                                                      quote: q,
                                                      quoteName: q == null
                                                          ? null
                                                          : (anonMsg(q) ? titleOf(state!, widget.roomId, widget.title) : whoName(context, q.sender)),
                                                      chatTitle: widget.title,
                                                      reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                                      hideCounts: hideCounts || isSaved,
                                                      toDelete: marked.contains(m.id),
                                                      toHide: veiledMsgs.contains(m.id),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : SendFly(
                                            key: ValueKey('fly-${m.id}'),
                                            fly: flyIds.contains(m.id),
                                            big: m.kind == 'sticker' || (m.kind == 'text' && isBigEmoji(m.body ?? '')),
                                            onDone: () => flyIds.remove(m.id),
                                            child: Listener(
                                              onPointerUp: (e) => doubleTapCheck(m, e),
                                              child: BubbleGestures(
                                                // Veiled chats: holding shows the text, so a short
                                                // tap opens the menu instead.
                                                mine: m.mine,
                                                onTap: veiled ? () => menu(m) : null,
                                                onLongPress: veiled ? null : () => menu(m),
                                                onReply: state!.on('swipe_reply', fallback: true) ? () => setState(() => replying = m) : null,
                                                child: Bubble(
                                                  msg: m,
                                                  roomId: widget.roomId,
                                                  read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                                  senderName: senderNameOf(m),
                                                  senderTag: senderTagOf(m),
                                                  senderAnon: anonMsg(m),
                                                  senderFace: faceFor(m),
                                                  quote: q,
                                                  quoteName: q == null
                                                      ? null
                                                      : (anonMsg(q) ? titleOf(state!, widget.roomId, widget.title) : whoName(context, q.sender)),
                                                  onQuoteTap: !Features.tipsReply || m.replyTo == null ? null : () => jumpTo(m.replyTo!),
                                                  toDelete: marked.contains(m.id),
                                                  toHide: veiledMsgs.contains(m.id),
                                                  onReaction: isSaved ? (_) => tagSaved([m.id]) : (key) => toggleReaction(m, key),
                                                  onOpenOnce: () => openOnce(m),
                                                  onCopyCode: copyFoundCode,
                                                  protectedChat: protected,
                                                  summarize: (isGroup || isChannel) && !protected,
                                                  album: albums[m.id],
                                                  onOpenPhoto: (photos, i) => openPhoto(photos, i),
                                                  onPollChanged: load,
                                                  chatTitle: widget.title,
                                                  reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                                  hideCounts: hideCounts || isSaved,
                                                  threadCount: threads[m.id]?.length ?? 0,
                                                  onThread: () => openThread(m),
                                                  onShare:
                                                      isChannel &&
                                                          !protected &&
                                                          !m.viewOnce &&
                                                          m.body != null &&
                                                          const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind)
                                                      ? () => sharePost(m)
                                                      : null,
                                                  onQuickForward: Features.channelTips ? (to) => quickForward(m, to) : null,
                                                  onComments: isChannel && discussionName(state!, cfg) != null
                                                      ? () => openChat(context, cfg['discussion'] as String, discussionName(state!, cfg)!)
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                  );
                                }),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        key: listKey,
                        controller: scroll,
                        reverse: true,
                        // 292: a short channel can still be pulled for the next one.
                        // Telegram: the messages always bounce, even when they do not fill the screen.
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[1]),
                        itemCount: rows.length + 1,
                        itemBuilder: (c, i) => withTopicLine(
                          rows,
                          i,
                          dustRow(rows, i, () {
                            if (i == rows.length && rows.isEmpty && loadedOnce && dmMine) {
                              return SizedBox(
                                height: MediaQuery.sizeOf(context).height * .55,
                                child: ChannelDmEmpty(channelName: widget.title),
                              );
                            }
                            if (i == rows.length && rows.isEmpty && helloShown) {
                              // A new 1:1 chat: the hello card in the middle (TelegramTips 80).
                              return SizedBox(
                                height: MediaQuery.sizeOf(context).height * .62,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: FirstHelloCard(
                                        roomId: widget.roomId,
                                        name: titleOf(AppScope.of(context), widget.roomId, widget.title),
                                        onSend: (id) async {
                                          await state!.backend.sendSticker(widget.roomId, id);
                                          await load();
                                        },
                                      ),
                                    ),
                                    noticePill(l.encryptedNotice, const Key('e2e-notice')),
                                  ],
                                ),
                              );
                            }
                            if (i == rows.length) {
                              return Padding(
                                padding: EdgeInsets.all(Tokens.space[3]),
                                child: noticePill(guarded ? l.guardNotice : l.encryptedNotice, Key(guarded ? 'guard-notice' : 'e2e-notice')),
                              );
                            }
                            final m = rows[rows.length - 1 - i];
                            // 캡처 알림: a centre line, not a message.
                            if (m.kind == 'shot') return shotLine(context, m);
                            noteSeen(m.id);
                            // 다른 앱 대화 가져오기: the import line and its messages.
                            if (m.kind == 'card' && m.card?.kind == 'import') {
                              return ImportCardLine(
                                key: Key('import-card-${m.id}'),
                                msg: m,
                                who: whoName(context, m.sender).replaceFirst(RegExp('^@'), ''),
                                onDelete: m.mine ? () => startDelete([m.id]) : null,
                              );
                            }
                            if (m.imported != null) {
                              final at = rows.length - 1 - i;
                              final prev = at > 0 ? rows[at - 1] : null;
                              final newDay = prev == null || !(prev.time.year == m.time.year && prev.time.month == m.time.month && prev.time.day == m.time.day);
                              return importedRow(context, m, newDay);
                            }
                            if (m.kind == 'welcome') {
                              return WelcomeBubble(
                                roomId: widget.roomId,
                                roomName: titleOf(AppScope.of(context), widget.roomId, widget.title),
                                texts: roomTexts,
                                channel: isChannel,
                                onHold: () => deleteWelcome(context, widget.roomId),
                              );
                            }
                            if (m.kind == 'room_photo') {
                              final kind = isChannel ? 'channel' : 'group';
                              // A new photo line: fetch the photo again (once per line).
                              if (photoLines.add(m.id)) AppScope.read(context).roomPhoto(widget.roomId, fresh: true);
                              final who = memberOf[m.sender]?.name ?? displayId(m.sender);
                              return Padding(
                                key: Key('room-photo-line-${m.id}'),
                                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                child: Center(
                                  child: Text(
                                    m.mine ? l.roomPhotoLineMine(kind, m.body ?? 'set') : l.roomPhotoLine(who, kind, m.body ?? 'set'),
                                    textAlign: TextAlign.center,
                                    style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                  ),
                                ),
                              );
                            }
                            if (m.kind == 'opened') {
                              return Padding(
                                key: const Key('opened-line'),
                                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                child: Center(
                                  child: Text(l.viewOnceOpenedLine, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                ),
                              );
                            }
                            if (m.kind == 'call' && m.call != null) {
                              return CallLine(
                                key: Key('call-line-${m.id}'),
                                msg: m,
                                onCallBack: isGroup || isChannel ? null : (video) => startCall(context, widget.roomId, widget.title, video: video),
                              );
                            }
                            if (m.kind == 'verify') {
                              // A request to check each other's keys: a centred card
                              // (only the other person's request has a button).
                              return Padding(
                                key: Key('verify-line-${m.id}'),
                                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[1], Tokens.space[1]),
                                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.lock_shield, size: Tokens.listIconSmall, color: p.accent),
                                        SizedBox(width: Tokens.space[1]),
                                        Text(l.verifyRequestLine, style: Tokens.caption.style.copyWith(color: p.label)),
                                        SizedBox(width: Tokens.space[1]),
                                        if (!m.mine)
                                          GestureDetector(
                                            key: Key('verify-open-${m.id}'),
                                            onTap: () => openSheet<void>(context, (_) => VerifyPage(userId: m.sender, name: displayId(m.sender), flowId: m.id)),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0]),
                                              decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                              child: Text(l.verifyOpen, style: Tokens.caption.style.copyWith(color: p.onAccent)),
                                            ),
                                          )
                                        else
                                          SizedBox(width: Tokens.space[1]),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            // 커뮤니티: "이 그룹을 ○○ 커뮤니티에 추가했어요 · 보기" (centred, no bubble).
                            if (m.kind == 'card' && m.card?.kind == 'community') return CommunityCardBubble(card: m.card!);
                            // 사진 제안 (tip 373): photo in a circle + "사진 보기".
                            if (m.kind == 'card' && m.card?.kind == 'photo') {
                              final st = AppScope.of(context);
                              final who = aliasOf(st, m.sender);
                              return PhotoSuggestBubble(
                                m: m,
                                name: who.isNotEmpty ? who : (isGroup ? displayId(m.sender) : titleOf(st, widget.roomId, widget.title)),
                              );
                            }
                            if (suggestRow(context, m) case final w?) return w;
                            // "OO님이 메시지를 고정했어요": tap jumps to the pinned message.
                            if (m.kind == 'card' && m.card?.kind == 'pin') {
                              return PinLine(
                                key: Key('pin-line-${m.id}'),
                                who: m.mine ? null : whoName(context, m.sender).replaceFirst(RegExp('^@'), ''),
                                text: m.card!.text('text'),
                                onTap: () => jumpTo(m.card!.text('id')),
                              );
                            }
                            if (m.kind == 'timer') {
                              final secs = int.tryParse(m.body ?? '') ?? 0;
                              return Padding(
                                key: const Key('timer-line'),
                                padding: EdgeInsets.symmetric(vertical: Tokens.space[1]),
                                child: Center(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: 3),
                                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                                    child: Text(
                                      secs == 0 ? l.timerOffLine : l.timerLine(timerLabel(context, secs)),
                                      style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                                    ),
                                  ),
                                ),
                              );
                            }
                            // Someone new: photos, videos and link cards wait until I accept.
                            if (stranger && !m.mine && (m.kind == 'image' || m.kind == 'video' || m.preview != null)) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  key: Key('stranger-hidden-${m.id}'),
                                  margin: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: 2),
                                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                                  decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        m.preview != null ? CupertinoIcons.link : CupertinoIcons.eye_slash,
                                        size: Tokens.listIconSmall,
                                        color: p.secondaryLabel,
                                      ),
                                      SizedBox(width: Tokens.space[1]),
                                      Text(l.firstMediaHidden, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            // Reported as illegal by several people (or the operator):
                            // hidden in every app until the operator decides.
                            if (state!.trust.hidden.contains(m.id)) {
                              return GestureDetector(
                                onLongPress: isAdmin || m.mine ? () => menu(m) : null,
                                child: hiddenLine(context, Key('report-hidden-${m.id}'), CupertinoIcons.exclamationmark_shield, l.reportHiddenLine, m.mine),
                              );
                            }
                            // 478 "그냥 싫어요" → hidden on this phone only.
                            if (Features.chatSafety && dislikedIn(state!, widget.roomId).contains(m.id)) {
                              return hiddenLine(context, Key('disliked-${m.id}'), CupertinoIcons.eye_slash, l.reportHiddenMsg, false);
                            }
                            // New member's photo/video/link while the room's limit is on.
                            if (hiddenForNew(m)) {
                              return hiddenLine(context, Key('new-hidden-${m.id}'), CupertinoIcons.eye_slash, l.newMediaHidden, false);
                            }
                            final q = m.replyTo == null ? null : msgs.where((x) => x.id == m.replyTo).firstOrNull;
                            final focused = m.id == focusId;
                            return AnimatedContainer(
                              key: msgKeys.putIfAbsent(m.id, GlobalKey.new),
                              duration: const Duration(milliseconds: 200),
                              color: focused ? p.accent.withValues(alpha: 0.14) : p.accent.withValues(alpha: 0),
                              // Settings > Chats: double tap = my quick reaction (a
                              // plain pointer listener, so taps inside the bubble are
                              // not slowed down), swipe left = reply.
                              child: selected != null
                                  ? GestureDetector(
                                      key: Key('select-row-${m.id}'),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => toggleSelect(m),
                                      child: Row(
                                        children: [
                                          SelectCircle(on: selected!.contains(m.id)),
                                          Expanded(
                                            child: IgnorePointer(
                                              child: Bubble(
                                                msg: m,
                                                roomId: widget.roomId,
                                                read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                                senderName: senderNameOf(m),
                                                senderTag: senderTagOf(m),
                                                senderAnon: anonMsg(m),
                                                senderFace: faceFor(m),
                                                quote: q,
                                                quoteName: q == null
                                                    ? null
                                                    : (anonMsg(q) ? titleOf(state!, widget.roomId, widget.title) : whoName(context, q.sender)),
                                                chatTitle: widget.title,
                                                reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                                hideCounts: hideCounts || isSaved,
                                                toDelete: marked.contains(m.id),
                                                toHide: veiledMsgs.contains(m.id),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SendFly(
                                      key: ValueKey('fly-${m.id}'),
                                      fly: flyIds.contains(m.id),
                                      big: m.kind == 'sticker' || (m.kind == 'text' && isBigEmoji(m.body ?? '')),
                                      onDone: () => flyIds.remove(m.id),
                                      child: Listener(
                                        onPointerUp: (e) => doubleTapCheck(m, e),
                                        child: BubbleGestures(
                                          // Veiled chats: holding shows the text, so a short
                                          // tap opens the menu instead.
                                          mine: m.mine,
                                          onTap: veiled ? () => menu(m) : null,
                                          onLongPress: veiled ? null : () => menu(m),
                                          onReply: state!.on('swipe_reply', fallback: true) ? () => setState(() => replying = m) : null,
                                          child: Bubble(
                                            msg: m,
                                            roomId: widget.roomId,
                                            read: m.mine && readUntil != null && !m.time.isAfter(readUntil!),
                                            senderName: senderNameOf(m),
                                            senderTag: senderTagOf(m),
                                            senderAnon: anonMsg(m),
                                            senderFace: faceFor(m),
                                            quote: q,
                                            quoteName: q == null
                                                ? null
                                                : (anonMsg(q) ? titleOf(state!, widget.roomId, widget.title) : whoName(context, q.sender)),
                                            onQuoteTap: !Features.tipsReply || m.replyTo == null ? null : () => jumpTo(m.replyTo!),
                                            toDelete: marked.contains(m.id),
                                            toHide: veiledMsgs.contains(m.id),
                                            onReaction: isSaved ? (_) => tagSaved([m.id]) : (key) => toggleReaction(m, key),
                                            onOpenOnce: () => openOnce(m),
                                            onCopyCode: copyFoundCode,
                                            protectedChat: protected,
                                            summarize: (isGroup || isChannel) && !protected,
                                            album: albums[m.id],
                                            onOpenPhoto: (photos, i) => openPhoto(photos, i),
                                            onPollChanged: load,
                                            chatTitle: widget.title,
                                            reactions: isSaved ? savedTagReaction(m, tagOf) : shownReactions(m),
                                            hideCounts: hideCounts || isSaved,
                                            threadCount: threads[m.id]?.length ?? 0,
                                            onThread: () => openThread(m),
                                            onShare:
                                                isChannel &&
                                                    !protected &&
                                                    !m.viewOnce &&
                                                    m.body != null &&
                                                    const ['text', 'image', 'video', 'audio', 'file', 'sticker'].contains(m.kind)
                                                ? () => sharePost(m)
                                                : null,
                                            onQuickForward: Features.channelTips ? (to) => quickForward(m, to) : null,
                                            onComments: isChannel && discussionName(state!, cfg) != null
                                                ? () => openChat(context, cfg['discussion'] as String, discussionName(state!, cfg)!)
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ),
                            );
                          }),
                        ),
                      ).wrapWith(nextPull),
              ),
              if (pendingDelete != null) undoBar(context),
              if (pendingSend != null) sendUndoBar(context),
              // 열어 둔 파일 (tip 473): tucked-away documents, above the box.
              const DocTabsBar(),
              if (pendingQuick != null) quickUndoBar(context),
              if (state!.scheduled.any((m) => m['room'] == widget.roomId))
                GestureDetector(
                  key: const Key('scheduled-chip'),
                  onTap: () async {
                    await Navigator.of(context).push(
                      IosPageRoute(
                        builder: (_) => Features.tipsLink ? ScheduledChatPage(roomId: widget.roomId) : ScheduledPage(roomId: widget.roomId),
                      ),
                    );
                    await load();
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: Tokens.space[1]),
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: Tokens.space[0] + 2),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.clock, size: 15, color: p.accent),
                        const SizedBox(width: 4),
                        Text(
                          L.of(context).scheduledCount(state!.scheduled.where((m) => m['room'] == widget.roomId).length),
                          style: Tokens.caption.style.copyWith(color: p.accent),
                        ),
                      ],
                    ),
                  ),
                ),
              if (notice != null)
                Padding(
                  key: const Key('notice'),
                  padding: EdgeInsets.only(bottom: Tokens.space[1]),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                    decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
                    child: Text(notice!, style: Tokens.preview.style.copyWith(color: p.label)),
                  ),
                ),
              if (selected != null)
                selectTools(context)
              else if (searching)
                searchBar(context)
              else if (topicListMode)
                const SizedBox.shrink()
              else if (sourceChat != null)
                Padding(
                  key: const Key('saved-source-bar'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                  child: Row(
                    children: [
                      const SizedBox(width: Tokens.closeButton),
                      Expanded(
                        child: Center(
                          child: GlassPill(
                            key: const Key('saved-open-chat'),
                            text: l.savedOpenChat,
                            onTap: () => openChat(context, sourceChat, savedSourceName(state!, sourceChat)),
                          ),
                        ),
                      ),
                      GlassCircle(key: const Key('saved-source-search'), onTap: openSearch, child: GlassCircle.icon(context, CupertinoIcons.search)),
                    ],
                  ),
                )
              else if (state!.isRequest(widget.roomId))
                requestBar(context)
              else if (canPost && mustAgree)
                Padding(
                  key: const Key('rules-gate'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
                  child: Column(
                    children: [
                      Text(
                        l.rulesReadFirst,
                        textAlign: TextAlign.center,
                        style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                      ),
                      SizedBox(height: Tokens.space[1]),
                      GlassPill(
                        key: const Key('rules-open'),
                        text: l.readRules,
                        onTap: () =>
                            openSheet<void>(context, (_) => RulesSheet(rules: roomTexts.rules, onAgree: () => state!.setOn('agreed:${widget.roomId}', true))),
                      ),
                    ],
                  ),
                )
              else if (canPost && topicLocked)
                Container(
                  key: const Key('topic-closed'),
                  width: double.infinity,
                  padding: EdgeInsets.all(Tokens.space[3]),
                  child: Text(
                    l.topicClosedBar,
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                )
              else if (!canPost)
                Container(
                  key: const Key('read-only'),
                  width: double.infinity,
                  padding: EdgeInsets.all(Tokens.space[3]),
                  child: Row(
                    children: [
                      // 526: write to the channel's admins (their switch is on).
                      if (Features.channelTips && isChannel && role != 'muted' && ChannelDm.isOn(cfg))
                        GlassCircle(
                          key: const Key('channel-dm'),
                          onTap: openChannelDm,
                          child: Icon(CupertinoIcons.chat_bubble_2, size: 22, color: p.accent),
                        )
                      else if (Features.channelTips && isChannel)
                        const SizedBox(width: Tokens.closeButton),
                      Expanded(
                        child: Text(
                          role == 'muted' ? mutedText(l) : l.channelReadOnly,
                          textAlign: TextAlign.center,
                          style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                        ),
                      ),
                      if (Features.channelTips && isChannel) const SizedBox(width: Tokens.closeButton),
                    ],
                  ),
                )
              else ...[
                if (protected && Features.chatSafety) protectNotice(context),
                // 글 제안 (tip 531): the subscriber's button in a channel's admin chat.
                if (suggestFromMe && editing == null) SuggestBar(onTap: openSuggest),
                if (mentionQ != null && isGroup)
                  Padding(
                    padding: EdgeInsets.only(bottom: Tokens.space[1]),
                    child: MentionList(
                      members: RoomRules.mentionMatches(
                        AnonAdmins.visible(memberOf.values.toList(), cfg, viewerIsAdmin: isAdmin, me: state!.backend.userId ?? ''),
                        mentionQ!,
                        state!.backend.userId ?? '',
                      ),
                      everyone: RoomRules.mayMentionAll(role, memberOf.length) && l.mentionAll.substring(1).startsWith(mentionQ!) ? l.mentionAll : null,
                      onPick: pickMention,
                    ),
                  ),
                // Tips 294 / 221 / 366: emoji for ':웃음' or a word, stickers for one emoji.
                if (Features.emojiStickers && recStart == null) suggestStrip(),
                // Tip 400: with a link typed, its line shows (reply via the tabs).
                if (typedLinks.isNotEmpty) linkBar(context, typedLinks) else if (replying != null || editing != null) modeBar(context),
                if (recLocked && recStart != null)
                  lockedRecordingBar(context)
                else
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], Tokens.space[1]),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // iOS 27 Messages: "+" in its own glass circle.
                        GlassCircle(
                          key: const Key('attach'),
                          size: Tokens.closeButton,
                          onTap: attach,
                          child: Icon(CupertinoIcons.plus, color: p.label, size: 22),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        Expanded(
                          child: recStart != null
                              ? recordingBar(context)
                              : CupertinoTextField(
                                  key: const Key('composer'),
                                  controller: input,
                                  placeholder: textLocked
                                      ? l.permTextLocked
                                      : (isChannel
                                            ? (channelSilent ? l.channelPostSilent : l.channelPostLoud)
                                            : topicsOn
                                            ? l.topicMessageIn(topicName(l, sendTopicItem))
                                            : l.messageHint),
                                  // 380: text not allowed here → a lock, and the field stays shut.
                                  readOnly: textLocked,
                                  // Channels: who posts (my picture) on the left, v1.
                                  prefix: textLocked
                                      ? Padding(
                                          key: const Key('text-locked'),
                                          padding: EdgeInsets.only(left: Tokens.space[2]),
                                          child: Icon(CupertinoIcons.lock_fill, size: 16, color: p.secondaryLabel),
                                        )
                                      : Features.channelTips && (authorsOn || myChannels.isNotEmpty)
                                      ? sendAsButton(context)
                                      : isChannel
                                      ? Padding(
                                          padding: EdgeInsets.only(left: Tokens.space[1]),
                                          child: Avatar(name: displayId(state!.backend.userId ?? ''), size: 24),
                                        )
                                      : null,
                                  minLines: 1,
                                  maxLines: 6,
                                  onChanged: onTyped,
                                  textInputAction: state!.on('enter_send') ? TextInputAction.send : TextInputAction.newline,
                                  onSubmitted: state!.on('enter_send') ? (_) => send() : null,
                                  onTap: () => setState(() => stickersOpen = false),
                                  contextMenuBuilder: (context, st) => formatMenu(context, st, input),
                                  suffix: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // AI 편집기 (561): shows once the message is over 3 lines.
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: input,
                                        builder: (context, v, _) {
                                          final w = MediaQuery.sizeOf(context).width - 2 * Tokens.space[1] - 2 * Tokens.closeButton - 2 * Tokens.space[1];
                                          final text = w - 2 * Tokens.space[2] - 36.0 * (isChannel ? 4 : 3);
                                          if (editing != null || !showAiButton(state!, v.text, text)) return const SizedBox.shrink();
                                          return CupertinoButton(
                                            key: const Key('ai-button'),
                                            padding: EdgeInsets.only(right: Tokens.space[1]),
                                            minimumSize: const Size(32, 32),
                                            onPressed: openAi,
                                            child: Icon(CupertinoIcons.wand_stars, color: p.accent, size: Tokens.listIcon + 2),
                                          );
                                        },
                                      ),
                                      // Long text: open it in the long-post editor ("크게 쓰기").
                                      ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: input,
                                        builder: (context, v, _) => v.text.contains('\n') || v.text.length > 80
                                            ? CupertinoButton(
                                                key: const Key('composer-expand'),
                                                padding: EdgeInsets.only(right: Tokens.space[1]),
                                                minimumSize: const Size(32, 32),
                                                onPressed: expandComposer,
                                                child: Icon(CupertinoIcons.arrow_up_left_arrow_down_right, color: p.secondaryLabel, size: Tokens.listIcon),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                      if (isChannel)
                                        CupertinoButton(
                                          key: const Key('channel-bell'),
                                          padding: EdgeInsets.only(right: Tokens.space[1]),
                                          minimumSize: const Size(32, 32),
                                          onPressed: toggleChannelBell,
                                          child: Icon(
                                            channelSilent ? CupertinoIcons.bell_slash : CupertinoIcons.bell,
                                            color: p.secondaryLabel,
                                            size: Tokens.listIcon + 2,
                                          ),
                                        ),
                                      // v1: the timer sits in the field, next to stickers.
                                      CupertinoButton(
                                        key: const Key('timer-button'),
                                        padding: EdgeInsets.only(right: Tokens.space[1]),
                                        minimumSize: const Size(32, 32),
                                        onPressed: chooseTimer,
                                        child: Icon(
                                          timerSecs > 0 ? CupertinoIcons.timer_fill : CupertinoIcons.timer,
                                          color: timerSecs > 0 ? p.accent : p.secondaryLabel,
                                          size: Tokens.listIcon + 2,
                                        ),
                                      ),
                                      CupertinoButton(
                                        key: const Key('sticker-button'),
                                        padding: EdgeInsets.only(right: Tokens.space[1]),
                                        minimumSize: const Size(32, 32),
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();
                                          setState(() => stickersOpen = !stickersOpen);
                                        },
                                        child: Icon(
                                          stickersOpen ? CupertinoIcons.keyboard : CupertinoIcons.smiley,
                                          color: p.secondaryLabel,
                                          size: Tokens.listIcon + 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Telegram iOS: 44 tall like the round buttons.
                                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[2], vertical: (Tokens.closeButton - Tokens.body.lineHeight) / 2),
                                  style: Tokens.body.style.copyWith(color: p.label),
                                  decoration: BoxDecoration(
                                    color: p.card.withValues(alpha: p.dark ? 0.55 : 0.75),
                                    borderRadius: BorderRadius.circular(Tokens.closeButton / 2),
                                  ),
                                ).glassEdge(radius: Tokens.closeButton / 2),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: input,
                          builder: (context, v, _) {
                            final mic = v.text.trim().isEmpty && editing == null && VoiceKit.canRecord;
                            if (!mic) {
                              // Phone web: a tap here must not close the keyboard
                              // (Flutter treats it as a tap outside the field).
                              return TextFieldTapRegion(
                                child: GestureDetector(
                                  key: const Key('send'),
                                  onTap: send,
                                  onLongPress: editing == null && replying == null ? sendOptions : null,
                                  child: Container(
                                    width: Tokens.closeButton,
                                    height: Tokens.closeButton,
                                    decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: BurumyMark(color: p.onAccent, size: 28),
                                  ),
                                ),
                              );
                            }
                            // 음성 메시지 받을 사람 (tip 356): they closed voice
                            // to me, so the mic is dimmed and says why.
                            final row = state!.chats.where((c) => c.roomId == widget.roomId).firstOrNull;
                            if (!LoginSafety.canSendVoice(state!, row)) {
                              return GestureDetector(
                                key: const Key('mic-closed'),
                                onTap: () => showVoiceClosed(context, widget.title),
                                child: Opacity(
                                  opacity: 0.4,
                                  child: Container(
                                    width: Tokens.closeButton,
                                    height: Tokens.closeButton,
                                    decoration: BoxDecoration(color: p.incoming, shape: BoxShape.circle),
                                    child: Icon(CupertinoIcons.mic_slash_fill, color: p.secondaryLabel, size: Tokens.listIcon + 2),
                                  ),
                                ),
                              );
                            }
                            // Hold to record, let go to send, slide left to cancel.
                            return GestureDetector(
                              key: const Key('mic'),
                              onTap: () => showNotice(l.voiceHoldHint),
                              onLongPressStart: (_) => startRecording(),
                              onLongPressMoveUpdate: (d) {
                                if (recLocked || recStart == null) return;
                                final o = d.offsetFromOrigin;
                                // Slide up: lock (keeps recording after letting go).
                                if (o.dy < -60 && o.dx > -40) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    recLocked = true;
                                    recCancel = false;
                                    recDx = 0;
                                  });
                                  // 418: say once what the "1" button does.
                                  if (Features.chatSafety && !isChannel && !state!.on('once_voice_hint')) {
                                    unawaited(state!.setOn('once_voice_hint', true));
                                    showNotice(l.onceVoiceHint);
                                  }
                                  return;
                                }
                                setState(() {
                                  recDx = o.dx < 0 ? o.dx : 0;
                                  recCancel = o.dx < -80;
                                });
                              },
                              onLongPressEnd: (_) {
                                if (!recLocked) finishRecording();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: recStart != null ? 48 : Tokens.closeButton,
                                height: recStart != null ? 48 : Tokens.closeButton,
                                decoration: BoxDecoration(color: recStart != null ? p.accent : p.incoming, shape: BoxShape.circle),
                                child: Icon(CupertinoIcons.mic_fill, color: recStart != null ? p.onAccent : p.secondaryLabel, size: Tokens.listIcon + 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                if (stickersOpen)
                  StickerPanel(
                    // Bubbles go to one friend only (as in the attach sheet).
                    onBubble: isGroup || isChannel
                        ? null
                        : () async {
                            final made = await openSheet<bool>(context, (_) => SendBubblePage(roomId: widget.roomId, name: widget.title));
                            if (made == true && mounted) {
                              setState(() => stickersOpen = false);
                              await load();
                              unawaited(state!.refresh());
                            }
                          },
                    // 스티커 만들기: made on this phone, saved to 내 스티커, sent as a PNG.
                    onMake: () async {
                      final png = await openSheet<Uint8List>(context, (_) => const StickerMakerPage());
                      if (png != null && mounted) await sendMine(png);
                    },
                    // 글자 스티커 (4-app board): a few words in a shape, same path.
                    onMakeText: () async {
                      final png = await openSheet<Uint8List>(context, (_) => const TextStickerPage());
                      if (png != null && mounted) await sendMine(png);
                    },
                    onMine: sendMine,
                    // Hold an emoji > 보내기 (tip 378): goes at once.
                    onSendEmoji: (e) async {
                      if (ruleBlocks('text')) return;
                      await state!.backend.sendText(widget.roomId, e);
                      await load();
                      unawaited(state!.refresh());
                    },
                    // 내 GIF (tip 558): tap sends, hold for 설명 · 편집 · 예약.
                    gifTab: Features.funFx && !mediaBlocked()
                        ? (c) => GifTab(
                            roomId: widget.roomId,
                            onSent: () async {
                              await load();
                              unawaited(state!.refresh());
                            },
                          )
                        : null,
                    // 내 이모지 · 그룹 이모지 (tips 354 · 430) on top of the emoji side.
                    emojiTop: Features.funFx
                        ? (c) => cxPanelSlivers(c, roomId: widget.roomId, roomName: widget.title, group: isGroup, onEmoji: insertEmoji)
                        : null,
                    // 이모지 side: the emoji goes in at the cursor.
                    onEmoji: (raw) {
                      final e = charEmojiIn(raw);
                      final sel = input.selection;
                      final at = sel.isValid ? sel.start : input.text.length;
                      final end = sel.isValid ? sel.end : input.text.length;
                      input.text = input.text.replaceRange(at, end, e);
                      input.selection = TextSelection.collapsed(offset: at + e.length);
                      setState(() {});
                    },
                    phrases: quickReplies(state!),
                    onPhrase: (text) {
                      input.text = input.text.isEmpty ? text : "${input.text} $text";
                      input.selection = TextSelection.collapsed(offset: input.text.length);
                      setState(() => stickersOpen = false);
                    },
                    onPick: (id) async {
                      if (ruleBlocks('sticker')) return;
                      await state!.backend.sendSticker(widget.roomId, id);
                      await load();
                      unawaited(state!.refresh());
                    },
                  ),
              ],
            ],
          ).wrapWith(inboxWrap),
        ),
      ),
    );
    // Always wrapped, so the chat keeps its state when the side list opens.
    return AnimatedBuilder(
      animation: anim,
      child: CaptureGuard(on: protected, child: page),
      builder: (c, child) {
        final v = anim.value;
        final w = MediaQuery.sizeOf(c).width - Tokens.sideStrip;
        return Transform.translate(
          offset: Offset(-w * v, 0),
          child: ClipRRect(borderRadius: BorderRadius.circular(Tokens.radius[3] * v), child: child),
        );
      },
    );
  }
}

/// Up to three small overlapping photos (who read, tip 384).
class ReaderFaces extends StatelessWidget {
  const ReaderFaces({super.key, required this.ids, required this.names});
  final List<String> ids;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    const size = 22.0, step = 14.0;
    return SizedBox(
      key: const Key('reader-faces'),
      width: size + step * (ids.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = ids.length - 1; i >= 0; i--)
            Positioned(
              left: step * i,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.card, width: 1.5),
                ),
                child: Avatar(name: names[ids[i]] ?? ids[i], size: size - 3, userId: ids[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// The name line on others' messages in groups: name, then the member tag
/// (or "관리자" for an anonymous admin, with the group's photo in front).
class SenderLine extends StatelessWidget {
  const SenderLine({super.key, required this.name, required this.color, this.stripe, this.tag, this.roomId});
  final String name;
  final Color color;
  final Color? stripe;
  final ShownTag? tag;
  final String? roomId;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final t = tag;
    return Row(
      key: roomId != null ? const Key('sender-anon') : null,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (roomId != null) ...[Avatar(name: name, size: 16, squircle: true, roomId: roomId), const SizedBox(width: 4)],
        Flexible(
          child: NameText(name: name, color: color, stripe: stripe),
        ),
        if (t != null) ...[
          const SizedBox(width: 6),
          Text(
            t.text,
            key: const Key('sender-tag'),
            maxLines: 1,
            style: Tokens.bubbleMeta.style.copyWith(color: t.byAdmin ? p.accent : p.secondaryLabel),
          ),
        ],
      ],
    );
  }
}

class Bubble extends StatelessWidget {
  const Bubble({
    super.key,
    required this.msg,
    required this.roomId,
    this.read = false,
    this.senderName,
    this.senderFace,
    this.quote,
    this.quoteName,
    this.onReaction,
    this.onOpenOnce,
    this.onPollChanged,
    this.chatTitle = '',
    this.reactions,
    this.hideCounts = false,
    this.onComments,
    this.threadCount = 0,
    this.onThread,
    this.toDelete = false,
    this.toHide = false,
    this.onShare,
    this.protectedChat = false,
    this.onQuickForward,
    this.album,
    this.onOpenPhoto,
    this.onCopyCode,
    this.onQuoteTap,
    this.senderTag,
    this.senderAnon = false,
    this.summarize = false,
  });

  /// 긴 글 AI 요약 (tip 554): groups and channels without 공유 비활성화.
  final bool summarize;

  /// Tap on the answered message above a reply: jump to it.
  final VoidCallback? onQuoteTap;

  /// 멤버 태그 (556) beside [senderName]: an admin's or admin-given tag in
  /// the accent colour, a member's own in grey.
  final ShownTag? senderTag;

  /// 익명 관리자 (94): [senderName] is the group's name; its photo shows
  /// beside it and the label says "관리자".
  final bool senderAnon;

  Widget senderLine(BuildContext context) => SenderLine(
    name: senderName!,
    color: senderAnon ? paletteOf(context).accent : NameColors.colorFor(msg.sender, senderName!),
    stripe: senderAnon ? null : NameColors.stripeFor(msg.sender),
    tag: senderAnon ? ShownTag(L.of(context).anonAdminLabel, byAdmin: true) : senderTag,
    roomId: senderAnon ? roomId : null,
  );

  /// 인증 코드 복사 (Telegram 477): a received code message gets a button.
  final void Function(String code)? onCopyCode;

  /// Channel posts (tip 102): the round share arrow beside the bubble.
  final VoidCallback? onShare;

  /// 공유 비활성화 chat: opened files can't go to other apps (tip 473).
  final bool protectedChat;

  /// 빠른 전달 (tip 521): hold the arrow and slide onto a chat.
  final void Function(ChatPreview to)? onQuickForward;

  /// Photos and videos sent together with this one (묶어서 보내기), in order;
  /// null = on its own.
  final List<Msg>? album;

  /// Tap on a photo (or an album square): opens it full screen.
  final void Function(List<Msg> photos, int index)? onOpenPhoto;

  /// An album square or a GIF video: videos open in the player, photos in
  /// the photo screen (swiping through the album's photos).
  void openMedia(BuildContext context, List<Msg> items, int i) {
    final m = items[i];
    if (m.kind == 'video') {
      openChatVideo(context, roomId, m);
      return;
    }
    final photos = items.where((x) => x.kind == 'image').toList();
    onOpenPhoto?.call(photos, photos.indexOf(m));
  }

  /// Chosen for the delete / hide password: a small mark by the time, seen
  /// only by me (Eric 2026-11-26 "숨김/삭제는 어떻게 구분하지?").
  final bool toDelete;
  final bool toHide;

  /// Reactions to show (the room may limit them); null = all.
  final List<Reaction>? reactions;

  /// Members of rooms that hide numbers see no counts.
  final bool hideCounts;

  /// Channel post → its discussion group.
  final VoidCallback? onComments;

  /// Replies in this message's thread ("답글 N개" pill opens it).
  final int threadCount;
  final VoidCallback? onThread;
  final void Function(String key)? onReaction;
  final VoidCallback? onOpenOnce;
  final Future<void> Function()? onPollChanged;
  final String chatTitle;
  final Msg msg;
  final String roomId;
  final bool read;

  /// Shown on others' messages in groups.
  final String? senderName;

  /// 472 / 310: a small photo at the outer side of the bubble (the author
  /// in a channel that shows authors, or the channel someone wrote as).
  final Widget? senderFace;

  /// The bubble with the sender's photo on its left, bottom-aligned.
  Widget withFace(Widget bubble) {
    final f = senderFace;
    if (f == null) return bubble;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(left: Tokens.space[0], right: Tokens.space[0], bottom: Tokens.space[0]),
          child: f,
        ),
        Flexible(child: bubble),
      ],
    );
  }

  /// The message this one answers (null if not loaded or none).
  final Msg? quote;
  final String? quoteName;

  /// A long post's words with the 요약 button (tip 554), else as they are.
  Widget maybeSummary(Widget words, Color fg) =>
      Features.tipsAiRead && summarize && PostSummary.fits(msg, room: true) ? SummaryArea(msg: msg, fg: fg, child: words) : words;

  /// The bubble with the share arrow at its outer side, bottom-aligned.
  Widget withShare(Widget bubble) {
    if (onShare == null) return bubble;
    final arrow = Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
      child: onQuickForward == null
          ? ShareArrow(key: Key('share-${msg.id}'), onTap: onShare!)
          : QuickForwardArrow(roomId: roomId, msgId: msg.id, onTap: onShare!, onPick: onQuickForward!),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: msg.mine ? [arrow, Flexible(child: bubble)] : [Flexible(child: bubble), arrow],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final mine = msg.mine;
    final fg = mine && msg.kind != 'sticker' ? p.onAccent : p.label;
    final time = DateFormat.jm(Localizations.localeOf(context).languageCode).format(msg.time);
    final l = L.of(context);
    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A live location moves by edits; that isn't "edited".
        if (msg.edited && !(msg.kind == 'location' && (msg.body ?? '').contains(';live=')))
          Text(
            // 사진 바뀜: the photo itself was swapped (tips 482, 81, 224).
            '${msg.mediaChanged ? l.mediaChanged : l.edited} ',
            key: const Key('edited'),
            style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.6)),
          ),
        if (msg.expiresAt != null) ...[
          Icon(CupertinoIcons.timer, key: const Key('expires'), size: 11, color: fg.withValues(alpha: 0.6)),
          const SizedBox(width: 2),
        ],
        if (toDelete) ...[
          Icon(CupertinoIcons.exclamationmark_shield, key: const Key('mark-delete'), size: 11, color: fg.withValues(alpha: 0.6)),
          const SizedBox(width: 2),
        ],
        if (toHide) ...[Icon(CupertinoIcons.eye_slash, key: const Key('mark-hide'), size: 11, color: fg.withValues(alpha: 0.6)), const SizedBox(width: 2)],
        // 다른 앱 대화 가져오기: "가져옴 7:30", never read ticks.
        if (msg.imported != null)
          Text(
            '${l.importedMark} ',
            key: const Key('imported-mark'),
            style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.6)),
          ),
        // 메시지 효과 (tip 451): tap to see it again.
        if (Features.funFx && msg.kind == 'text')
          if (MsgFx.byId(MsgFx.of(AppScope.of(context), msg.id)) case final fxKind?) FxMark(kind: fxKind, fg: fg),
        Text(time, style: Tokens.bubbleMeta.style.copyWith(color: fg.withValues(alpha: 0.6))),
        if (mine && msg.imported == null) ...[
          const SizedBox(width: 2),
          Icon(
            read ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.checkmark_alt,
            key: Key(read ? 'tick-read' : 'tick-sent'),
            size: 13,
            color: fg.withValues(alpha: 0.75),
          ),
        ],
      ],
    );
    final Widget content;
    final big = msg.kind == 'text' && msg.preview == null && AppScope.of(context).on('big_emoji', fallback: true) && isBigEmoji(msg.body ?? '');
    final made = isCustomSticker(msg);
    // 주사위 (tip 218): drawn like a sticker, no bubble.
    final dice = Features.funFx && msg.kind == 'card' && msg.card?.kind == 'dice' ? msg.card!.text('e') : null;
    if (dice != null && Dice.kinds.containsKey(dice)) {
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.all(Tokens.space[0]),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (senderName != null) Text(senderName!, style: Tokens.caption.style.copyWith(color: NameColors.colorFor(msg.sender, senderName!))),
              DiceView(
                key: Key('dice-msg-${msg.id}'),
                game: dice,
                value: Dice.valueOf(dice, msg.id),
                roll: DateTime.now().difference(msg.time).inSeconds.abs() < 8,
                onTap: mine ? null : () => context.findAncestorStateOfType<_ChatPageState>()?.tryDice(dice),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: meta,
              ),
            ],
          ),
        ),
      );
    }
    if (msg.kind == 'sticker' || big || made) {
      final asset = big || made ? null : stickerAsset(msg.body ?? '');
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Tokens.space[0], horizontal: Tokens.space[0]),
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (senderName != null) senderLine(context),
              SizedBox(
                key: Key(big ? 'big-emoji' : 'sticker-msg'),
                width: big ? null : 150,
                height: big ? null : 150,
                child: big
                    ? (Features.funFx
                          // 큰 이모지 효과 (tips 219 · 297 · 355): it moves, and a
                          // tap fills the screen; a 1:1 friend sees it too.
                          ? BigEmojiFx(
                              text: msg.body!.trim(),
                              fresh: DateTime.now().difference(msg.time).inSeconds.abs() < 60,
                              onTapped: AppScope.of(context).chats.where((c) => c.roomId == roomId).firstOrNull?.isDirect == true
                                  ? () => unawaited(MsgFx.tapped(AppScope.read(context), roomId, msg.body!.trim()))
                                  : null,
                              child: BigEmoji(msg.body!.trim()),
                            )
                          : BigEmoji(msg.body!.trim()))
                    : made
                    ? CustomStickerView(roomId: roomId, msg: msg)
                    : asset == null
                    ? Icon(CupertinoIcons.smiley, color: p.secondaryLabel, size: 48)
                    // 자동 재생 off or power saving: a moving sticker stays still.
                    : TickerMode(
                        enabled: AppScope.of(context).gifsMove,
                        child: Image.asset(asset, fit: BoxFit.contain),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: p.incoming.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(Tokens.capsule)),
                child: meta,
              ),
            ],
          ),
        ),
      );
    }
    final voiceRoom = AppScope.of(context).chats.where((c) => c.roomId == roomId).firstOrNull;
    if (LoginSafety.hideVoice(AppScope.of(context), voiceRoom, msg)) {
      // 음성 메시지 받을 사람 (tip 356): a changed app sent one anyway.
      content = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Tokens.space[1],
        children: [
          VoiceBlockedLine(fg: fg),
          meta,
        ],
      );
    } else if (msg.bubble) {
      content = BubbleMsg(msg: msg, roomId: roomId, name: chatTitle, fg: fg, meta: meta);
    } else if (msg.card?.kind == 'stickers') {
      // 스티커 묶음 (tips 538 + 441): name, a peek, 보기 / 추가됨.
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          StickerSetBubble(msg: msg, fg: fg),
          const SizedBox(height: 2),
          meta,
        ],
      );
    } else if (msg.card != null) {
      content = CardBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {});
    } else if (msg.meetup != null) {
      content = MeetupBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, showWho: senderName != null);
    } else if (msg.contact != null) {
      content = ContactBubble(msg: msg, fg: fg, meta: meta);
    } else if (msg.kind == 'location') {
      content = LocationBubble(msg: msg, fg: fg, meta: meta, roomId: roomId);
    } else if (msg.checklist != null) {
      content = ChecklistBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, showWho: senderName != null);
    } else if (msg.poll != null) {
      content = PollBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, onChanged: onPollChanged ?? () async {}, hideCounts: hideCounts);
    } else if (msg.voice != null) {
      content = VoiceBubble(roomId: roomId, msg: msg, fg: fg, meta: meta);
    } else if (Features.tipsAudio && !msg.viewOnce && msg.body != null && isMusic(msg)) {
      // 음악 (tips 108 + 199): plays in the chat's play list with the mini bar.
      content = MusicBubble(roomId: roomId, msg: msg, fg: fg, meta: meta, chatTitle: chatTitle);
    } else if (album != null && album!.length > 1 && !msg.viewOnce) {
      // 묶어서 보내기: one bubble with the mosaic, words under it.
      final capMsg = album!.where((m) => m.caption != null).firstOrNull;
      final cap = capMsg?.caption;
      // 설명 위로 (tip 452) for the album's words.
      final above = capMsg?.captionAbove ?? false;
      content = SizedByMedia(
        media: above ? 1 : 0,
        children: [
          if (above)
            Padding(
              key: const Key('caption-above'),
              padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], Tokens.space[0]),
              child: FormattedText(
                cap!,
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: mine ? p.onAccent : p.accent,
                quoteColor: mine ? p.onAccent : p.accent,
                tagRoom: roomId,
              ),
            ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radius[2]),
                child: AlbumGrid(roomId: roomId, items: album!, onOpen: (i) => openMedia(context, album!, i)),
              ),
              if (above) Positioned(right: Tokens.space[1], bottom: Tokens.space[1], child: onPhotoMeta(meta)),
            ],
          ),
          if (!above)
            Padding(
              key: cap == null ? null : const Key('caption'),
              padding: cap == null ? EdgeInsets.only(top: Tokens.space[0]) : EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], 2),
              child: cap == null
                  ? Align(alignment: AlignmentDirectional.centerEnd, child: meta)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: FormattedText(
                            cap,
                            style: Tokens.body.style.copyWith(color: fg),
                            linkColor: mine ? p.onAccent : p.accent,
                            quoteColor: mine ? p.onAccent : p.accent,
                            tagRoom: roomId,
                          ),
                        ),
                        SizedBox(width: Tokens.space[1]),
                        meta,
                      ],
                    ),
            ),
        ],
      );
    } else if (msg.kind == 'video' && !msg.viewOnce && MediaTags.of(msg.body).gif) {
      // Sent with 소리 끄기: a silent loop, like a GIF.
      content = GifVideoBubble(roomId: roomId, msg: msg, meta: meta, onOpen: () => openMedia(context, [msg], 0));
    } else if (msg.kind == 'video' && !msg.viewOnce && isVideoNote(msg.body)) {
      final b = AppScope.of(context).backend;
      final round = RoundVideoBubble(mime: ChatPageMime.of(msg.body ?? 'v.mp4'), meta: meta, load: () => b.downloadFile(roomId, msg.fileId));
      // 글로 보기 (tip 361): the words of a round video, heard on this phone.
      content = Features.tipsAiRead ? VoiceTextArea(roomId: roomId, msg: msg, fg: p.label, mime: ChatPageMime.of(msg.body ?? 'v.mp4'), child: round) : round;
    } else if (msg.kind == 'video' && !msg.viewOnce) {
      final cap = msg.caption;
      final video = ChatVideo(roomId: roomId, msg: msg, meta: cap == null || msg.captionAbove ? meta : const SizedBox.shrink());
      // 가리기 (tip 369): covered until the first tap; else two fingers zoom.
      final Widget bubble = MediaTags.of(msg.body).spoiler
          ? ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radius[2]),
              child: SpoilerCover(key: Key('spoiler-${msg.id}'), child: video),
            )
          : PinchZoom(radius: Tokens.radius[2], child: video);
      // Words under the video; "1:05" in them plays from there (tip 198).
      content = cap == null
          ? bubble
          : msg.captionAbove
          // 설명 위로 (tip 452): words on top, the video under them.
          ? Column(
              key: const Key('caption-above'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], Tokens.space[0]),
                  child: FormattedText(
                    cap,
                    style: Tokens.body.style.copyWith(color: fg),
                    linkColor: mine ? p.onAccent : p.accent,
                    quoteColor: mine ? p.onAccent : p.accent,
                    tagRoom: roomId,
                    onTime: (at) => openChatVideo(context, roomId, msg, at: at),
                  ),
                ),
                bubble,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                bubble,
                Padding(
                  key: const Key('caption'),
                  padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FormattedText(
                          cap,
                          style: Tokens.body.style.copyWith(color: fg),
                          linkColor: mine ? p.onAccent : p.accent,
                          quoteColor: mine ? p.onAccent : p.accent,
                          tagRoom: roomId,
                          onTime: (at) => openChatVideo(context, roomId, msg, at: at),
                        ),
                      ),
                      SizedBox(width: Tokens.space[1]),
                      meta,
                    ],
                  ),
                ),
              ],
            );
    } else if (msg.viewOnce && msg.kind == 'audio') {
      content = OnceVoiceBubble(body: msg.body, mine: mine, opened: msg.opened, fg: fg, meta: meta, onOpen: onOpenOnce ?? () {});
    } else if (msg.viewOnce && msg.kind == 'video' && isVideoNote(msg.body)) {
      content = OnceRoundBubble(opened: msg.opened, canOpen: !mine && !msg.opened, onOpen: onOpenOnce, meta: meta);
    } else if (msg.viewOnce) {
      final canOpen = !mine && !msg.opened;
      content = GestureDetector(
        key: const Key('view-once'),
        onTap: canOpen ? onOpenOnce : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: fg, width: 1.5),
              ),
              child: Text('1', style: Tokens.caption.style.copyWith(color: fg)),
            ),
            SizedBox(width: Tokens.space[1]),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(msg.kind == 'video' ? l.viewOnceVideo : l.viewOncePhoto, style: Tokens.body.style.copyWith(color: fg)),
                  Text(
                    msg.opened ? l.viewOnceOpened : (onceLeft(l, msg, mine) ?? (canOpen ? l.viewOnceTap : '')),
                    key: msg.opened ? const Key('view-once-opened') : null,
                    style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            SizedBox(width: Tokens.space[1]),
            meta,
          ],
        ),
      );
    } else if (msg.kind == 'image') {
      final cap = msg.caption;
      final above = cap != null && msg.captionAbove;
      content = SizedByMedia(
        media: above ? 1 : 0,
        children: [
          // 설명 위로 (tip 452): the words first, then the photo.
          if (above)
            Padding(
              key: const Key('caption-above'),
              padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], Tokens.space[0]),
              child: FormattedText(
                cap,
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: mine ? p.onAccent : p.accent,
                quoteColor: mine ? p.onAccent : p.accent,
                tagRoom: roomId,
              ),
            ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.radius[2]),
                child: GestureDetector(
                  key: Key('photo-${msg.id}'),
                  onTap: onOpenPhoto == null ? null : () => onOpenPhoto!([msg], 0),
                  child: msg.live == null
                      ? (MediaTags.of(msg.body).spoiler
                            ? SpoilerCover(
                                key: Key('spoiler-${msg.id}'),
                                child: EncryptedImage(roomId: roomId, eventId: msg.id, msg: msg),
                              )
                            // Two fingers: the photo lifts and grows (tip 273).
                            : PinchZoom(
                                key: Key('pinch-${msg.id}'),
                                radius: Tokens.radius[2],
                                // A GIF's words and drawing (tip 558) over it.
                                child: GifLayerOver(
                                  msg: msg,
                                  child: EncryptedImage(roomId: roomId, eventId: msg.id, msg: msg),
                                ),
                              ))
                      // 움직이는 사진: the clip plays over the still (LIVE capsule).
                      : PinchZoom(
                          radius: Tokens.radius[2],
                          child: LiveLayer(
                            key: Key('live-${msg.id}'),
                            style: LiveStyle.parse(msg.live!.style),
                            loadClip: () => AppScope.read(context).backend.liveVideo(roomId, msg.id),
                            child: EncryptedImage(roomId: roomId, eventId: msg.id, msg: msg),
                          ),
                        ),
                ),
              ),
              // With the words on top, the time sits on the photo (like iOS).
              if (above) Positioned(right: Tokens.space[1], bottom: Tokens.space[1], child: onPhotoMeta(meta)),
            ],
          ),
          if (cap == null)
            Padding(
              padding: EdgeInsets.only(top: Tokens.space[0]),
              child: Align(alignment: AlignmentDirectional.centerEnd, child: meta),
            )
          else if (!above)
            Padding(
              key: const Key('caption'),
              padding: EdgeInsets.fromLTRB(Tokens.space[1], Tokens.space[0], Tokens.space[1], 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: FormattedText(
                      cap,
                      style: Tokens.body.style.copyWith(color: fg),
                      linkColor: mine ? p.onAccent : p.accent,
                      quoteColor: mine ? p.onAccent : p.accent,
                      tagRoom: roomId,
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  meta,
                ],
              ),
            ),
        ],
      );
    } else if (msg.kind == 'file' && !msg.viewOnce) {
      // 문서 바로 보기 (tip 473): tile + name + size; tap opens it in Burumy.
      final cap = msg.caption;
      final file = FileBubble(roomId: roomId, msg: msg, fg: fg, meta: cap == null ? meta : const SizedBox.shrink(), protected: protectedChat);
      content = cap == null
          ? file
          : Column(
              key: const Key('caption'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                file,
                SizedBox(height: Tokens.space[1]),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: Tokens.space[1],
                  children: [
                    FormattedText(
                      cap,
                      style: Tokens.body.style.copyWith(color: fg),
                      linkColor: mine ? p.onAccent : p.accent,
                      quoteColor: mine ? p.onAccent : p.accent,
                      tagRoom: roomId,
                    ),
                    meta,
                  ],
                ),
              ],
            );
    } else if (msg.caption != null && msg.kind != 'text') {
      content = Column(
        key: const Key('caption'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(msg.kind == 'video' ? CupertinoIcons.videocam_fill : CupertinoIcons.doc, size: Tokens.listIcon, color: fg),
              SizedBox(width: Tokens.space[1]),
              Flexible(
                child: Text(
                  previewText(context, kind: msg.kind, body: msg.body),
                  style: Tokens.body.style.copyWith(color: fg),
                ),
              ),
            ],
          ),
          SizedBox(height: Tokens.space[0]),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Tokens.space[1],
            children: [
              FormattedText(
                msg.caption!,
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: mine ? p.onAccent : p.accent,
                quoteColor: mine ? p.onAccent : p.accent,
                tagRoom: roomId,
              ),
              meta,
            ],
          ),
        ],
      );
    } else {
      final text = previewText(context, kind: msg.kind, body: msg.body);
      // A shared 말투 shows as a card; the long link itself is hidden.
      final styleLink = msg.kind == 'text' ? AiStyles.parse(msg.body ?? '') : null;
      // A shared theme (tip 226) shows as a card too.
      final themeLink = msg.kind == 'text' && styleLink == null ? MyTheme.parseLink(msg.body ?? '') : null;
      final words = Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: Tokens.space[1],
        children: [
          if (msg.kind == 'file') Icon(CupertinoIcons.doc, size: Tokens.listIcon, color: fg),
          if (msg.kind == 'text' && !mine && chatTranslateTo(AppScope.of(context), roomId).isNotEmpty)
            // 대화 전체 번역: the words in my language (marks dropped).
            TranslatedWords(
              text: plainText(msg.body ?? ''),
              to: chatTranslateTo(AppScope.of(context), roomId),
              builder: (shown) => FormattedText(
                shown,
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: p.accent,
                quoteColor: p.accent,
              ),
            )
          else if (msg.kind == 'text')
            maybeSummary(
              FormattedText(
                // The marks themselves (previewText takes them out).
                styleLink != null ? AiStyles.withoutLink(msg.body ?? '') : (themeLink != null ? MyTheme.withoutLink(msg.body ?? '') : msg.body ?? ''),
                style: Tokens.body.style.copyWith(color: fg),
                linkColor: mine ? p.onAccent : p.accent,
                quoteColor: mine ? p.onAccent : p.accent,
                tagRoom: roomId,
                onPlan: AppScope.of(context).on('plan_pick') ? (at) => planReminder(context, roomId, chatTitle, msg, at) : null,
                // A reply to a video: "2:15" plays that video from there (tip 84).
                onTime: quote != null && quote!.kind == 'video' && !quote!.viewOnce ? (at) => openChatVideo(context, roomId, quote!, at: at) : null,
                codeInset: mine,
                onDateRemind: (at) => planReminder(context, roomId, chatTitle, msg, at),
              ),
              fg,
            )
          else
            Text(text, style: Tokens.body.style.copyWith(color: msg.kind == 'locked' ? fg.withValues(alpha: 0.6) : fg)),
          if (msg.kind == 'file' && sizeOf(msg) != null)
            Text(
              sizeOf(msg)!,
              key: const Key('file-size'),
              style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
            ),
          if (msg.preview == null && styleLink == null && themeLink == null) meta,
        ],
      );
      final card = msg.preview;
      final scam = !mine && msg.kind == 'text' && AppScope.of(context).on('scam_warning', fallback: true) && hasSuspiciousLink(text);
      final warned = !scam
          ? words
          : Column(
              key: const Key('scam-warning'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Palette.tileRed, size: 15),
                    SizedBox(width: Tokens.space[0]),
                    Flexible(
                      child: Text(L.of(context).scamLink, style: Tokens.caption.style.copyWith(color: Palette.tileRed)),
                    ),
                  ],
                ),
                SizedBox(height: Tokens.space[0]),
                words,
              ],
            );
      content = themeLink != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (MyTheme.withoutLink(msg.body ?? '').isNotEmpty) Align(alignment: Alignment.centerLeft, child: warned),
                ThemeLinkCard(theme: themeLink, mine: mine),
                meta,
              ],
            )
          : styleLink != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(alignment: Alignment.centerLeft, child: warned),
                StyleLinkCard(style: styleLink, mine: mine),
                meta,
              ],
            )
          : card == null
          ? warned
          : Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tip 400: the sender may have put the card above the words.
                if (Features.tipsLink && card.above) LinkCardView(card: card, roomId: roomId, eventId: msg.id, mine: mine, summary: !protectedChat),
                Align(alignment: Alignment.centerLeft, child: warned),
                if (!(Features.tipsLink && card.above)) LinkCardView(card: card, roomId: roomId, eventId: msg.id, mine: mine, summary: !protectedChat),
                meta,
              ],
            );
    }
    final q = quote;
    // 부분 인용 / 다른 대화에서 온 인용 (tip 399): the picked words instead.
    final part = Features.tipsReply ? msg.quote : null;
    final fwd = msg.forwarded
        ? Padding(
            key: const Key('forwarded'),
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.arrowshape_turn_up_right_fill, size: 12, color: mine ? p.onAccent : p.accent),
                const SizedBox(width: 3),
                Text(l.forwarded, style: Tokens.caption.style.copyWith(color: mine ? p.onAccent : p.accent)),
              ],
            ),
          )
        : null;
    final Widget body = (senderName == null && q == null && part == null && fwd == null)
        ? content
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (senderName != null) senderLine(context),
              ?fwd,
              if (part != null)
                ReplyQuoteHeader(
                  name: msg.replyTo == null ? (msg.quoteName ?? '') : (quoteName ?? ''),
                  text: part,
                  otherChat: msg.replyTo == null,
                  ink: fg,
                  color: mine ? p.onAccent : p.accent,
                  onTap: msg.replyTo == null ? null : onQuoteTap,
                )
              else if (q != null)
                GestureDetector(
                  onTap: onQuoteTap,
                  // 계정 색 (tip 402): the quote takes the quoted person's
                  // colour and icons; in a channel, the channel's (412).
                  child: KeyedSubtree(
                    key: const Key('quote'),
                    child: Builder(
                      builder: (context) {
                        final st = AppScope.of(context);
                        final rl = roomLooks[roomId];
                        final look = lookOfUser(st, q.sender);
                        final own = rl != null && rl.name.isNotEmpty ? NameColors.colorOf(rl.name) : NameColors.colorOf(look.name.firstOrNull ?? '');
                        final icons = rl != null && rl.name.isNotEmpty ? rl.logo : look.reply;
                        return LookQuote(
                          color: mine ? p.onAccent : (own ?? p.accent),
                          icons: icons,
                          name: quoteName ?? '',
                          text: previewText(context, kind: q.kind, body: q.body),
                          ink: fg,
                        );
                      },
                    ),
                  ),
                ),
              content,
            ],
          );
    final bubble = Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      // 가리기: a finger anywhere on the bubble shows it, not only the dots.
      child: withShare(
        VeilHold(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
            margin: EdgeInsets.symmetric(vertical: 2, horizontal: Tokens.space[0]),
            padding: msg.kind == 'image'
                ? EdgeInsets.all(Tokens.space[0] - 1)
                : EdgeInsets.fromLTRB(Tokens.space[2], Tokens.space[1] - 2, Tokens.space[2], Tokens.space[1] - 2),
            decoration: BoxDecoration(
              color: mine ? p.accent : p.incoming,
              borderRadius: BorderRadius.circular(double.tryParse(AppScope.of(context).pref('bubble_radius', '')) ?? Tokens.radius[2] + 2),
            ),
            child: Veil(mode: veilOf(AppScope.of(context), roomId), ink: fg, child: body),
          ),
        ),
      ).wrapWith(withFace),
    );
    final shown = reactions ?? msg.reactions;
    // My own reaction that the room's rules now hide (Telegram 450 shows
    // nothing): a faint chip, tap takes it back.
    final hidden = reactions == null || !Features.tipsD1
        ? const <Reaction>[]
        : [
            for (final r in msg.reactions)
              if (r.mine != null && !shown.any((x) => x.key == r.key)) r,
          ];
    Widget pill(Key key, IconData icon, String text, VoidCallback tap) => Padding(
      padding: EdgeInsets.fromLTRB(Tokens.space[1], 2, Tokens.space[1], Tokens.space[0]),
      child: GestureDetector(
        key: key,
        onTap: tap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: p.incoming, borderRadius: BorderRadius.circular(Tokens.capsule)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.accent),
              const SizedBox(width: 6),
              Text(text, style: Tokens.caption.style.copyWith(color: p.accent)),
            ],
          ),
        ),
      ),
    );
    final code = Features.tipsD1 && !mine && onCopyCode != null && msg.kind == 'text' ? findCode(msg.body ?? '') : null;
    final extra = [
      if (code != null) pill(Key('copy-code-${msg.id}'), CupertinoIcons.doc_on_doc, l.copyCodeButton(code), () => onCopyCode!(code)),
      if (onComments != null) pill(Key('comments-${msg.id}'), CupertinoIcons.chat_bubble_2, l.comments, onComments!),
      if (onThread != null && threadCount > 0) pill(Key('thread-${msg.id}'), CupertinoIcons.text_bubble, l.threadReplies(threadCount), onThread!),
    ];
    final comments = extra.isEmpty
        ? null
        : (extra.length == 1 ? extra.single : Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: extra));
    if (shown.isEmpty && hidden.isEmpty && comments == null) return bubble;
    if (shown.isEmpty && hidden.isEmpty) {
      return Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [bubble, comments!]);
    }
    return Column(
      crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (comments != null) comments,
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[1], 0, Tokens.space[1], Tokens.space[0]),
          child: Wrap(
            spacing: Tokens.space[0],
            children: [
              for (final r in shown)
                GestureDetector(
                  key: Key('reaction-${r.key}'),
                  onTap: () => onReaction?.call(r.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.mine != null ? p.accent.withValues(alpha: 0.18) : p.incoming,
                      borderRadius: BorderRadius.circular(Tokens.capsule),
                    ),
                    child: charReactionAsset(r.key) == null
                        ? Text(hideCounts ? r.key : '${r.key} ${r.count}', style: Tokens.caption.style.copyWith(color: r.mine != null ? p.accent : p.label))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReactionGlyph(r.key, size: 16),
                              if (!hideCounts) Text(' ${r.count}', style: Tokens.caption.style.copyWith(color: r.mine != null ? p.accent : p.label)),
                            ],
                          ),
                  ),
                ),
              for (final r in hidden)
                Semantics(
                  label: l.reactionHiddenMine,
                  child: GestureDetector(
                    key: Key('reaction-hidden-${r.key}'),
                    onTap: () => onReaction?.call(r.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: p.separator),
                        borderRadius: BorderRadius.circular(Tokens.capsule),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          charReactionAsset(r.key) == null
                              ? Opacity(opacity: 0.45, child: Text(r.key, style: Tokens.caption.style))
                              : ReactionGlyph(r.key, size: 16, opacity: 0.45),
                          const SizedBox(width: 3),
                          Icon(CupertinoIcons.eye_slash, size: 12, color: p.secondaryLabel),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Downloads and decrypts a photo on this device, then shows it.
/// Opens a chat video full screen, from [at] when a time link was tapped.
/// The download goes through the download list (kept, encrypted).
Future<void> openChatVideo(BuildContext context, String roomId, Msg m, {Duration? at}) {
  final s = AppScope.read(context);
  // 이어보기 (tip 509): where I stopped last time, on this phone only.
  final key = VideoResume.keyFor(roomId, m.id);
  final resume = Features.tipsD1 && !m.viewOnce ? VideoResume.at(s, key) : null;
  final light = LightIndex.of(m);
  return Navigator.of(context, rootNavigator: true).push(
    IosPageRoute(
      fullscreenDialog: true,
      builder: (_) => VideoPlayerPage(
        mime: ChatPageMime.of(MediaTags.plain(m.body ?? 'v.mp4')),
        startAt: at ?? resume,
        resumed: at == null && resume != null,
        onClose: Features.tipsD1 && !m.viewOnce ? (pos, total) => unawaited(VideoResume.save(s, key, pos, total)) : null,
        load: () => Downloads.instance.get(s, roomId, m),
        // 가벼운 복사본 (tips 479 · 480): the ⚙ menu, when the sender made one.
        light: light == null || m.viewOnce
            ? null
            : LightCopy(msg: light, height: MediaTags.of(light.body).lightHeight, load: () => Downloads.instance.get(s, roomId, light)),
        originalSize: m.size,
      ),
    ),
  );
}

/// A chat video: downloads ahead when Settings > Data says so (tip 116),
/// shows its size and a ring with X while downloading (tip 109).
class ChatVideo extends StatefulWidget {
  const ChatVideo({super.key, required this.roomId, required this.msg, required this.meta});
  final String roomId;
  final Msg msg;
  final Widget meta;

  @override
  State<ChatVideo> createState() => _ChatVideoState();
}

class _ChatVideoState extends State<ChatVideo> {
  bool asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (!asked && Downloads.instance.find(widget.msg.fileId) == null && s.autoGet(widget.roomId, widget.msg)) {
      asked = true;
      unawaited(Downloads.instance.get(s, widget.roomId, widget.msg).then((_) {}, onError: (_) {}));
    }
  }

  final inlineKey = GlobalKey<InlineVideoState>();

  /// 자동 재생 (tip 204): downloaded already, switch on, not saving power,
  /// not covered, not huge (it plays from memory).
  bool inline(AppState s) {
    final m = widget.msg;
    return s.on('autoplay_video', fallback: true) &&
        s.gifsMove &&
        !MediaTags.of(m.body).spoiler &&
        (m.size ?? 0) <= 50 * 1024 * 1024 &&
        Downloads.instance.find(m.fileId)?.state == DownloadState.done;
  }

  Future<void> open() async {
    inlineKey.currentState?.pause();
    await openChatVideo(context, widget.roomId, widget.msg);
    inlineKey.currentState?.resume();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Downloads.instance,
    builder: (context, _) => VideoBubble(
      name: MediaTags.plain(widget.msg.body ?? ''),
      meta: widget.meta,
      size: sizeOf(widget.msg),
      downloading: Downloads.instance.isRunning(widget.msg.fileId),
      onCancel: () => Downloads.instance.cancel(AppScope.read(context), widget.msg.fileId),
      inline: inline(AppScope.of(context))
          ? InlineVideo(
              key: inlineKey,
              mime: ChatPageMime.of(MediaTags.plain(widget.msg.body ?? 'v.mp4')),
              // From the encrypted store (already downloaded): no new row.
              load: () => AppScope.read(context).backend.downloadFileCached(widget.roomId, widget.msg.fileId),
            )
          : null,
      onOpen: open,
      watched: Features.tipsD1 ? VideoResume.watched(AppScope.of(context), VideoResume.keyFor(widget.roomId, widget.msg.id)) : null,
    ),
  );
}

class EncryptedImage extends StatefulWidget {
  const EncryptedImage({super.key, required this.roomId, required this.eventId, this.msg});
  final String roomId;
  final String eventId;

  /// A chat photo: Settings > Data rules per chat type, and the download
  /// list / keep time (null = old plain rule).
  final Msg? msg;
  @override
  State<EncryptedImage> createState() => _EncryptedImageState();
}

class _EncryptedImageState extends State<EncryptedImage> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Settings > Data > Auto-download (and power saving): otherwise wait
    // for a tap.
    final s = AppScope.of(context);
    final m = widget.msg;
    if (bytes == null && (m == null ? s.autoDownload : s.autoGet(widget.roomId, m))) bytes = fetch();
  }

  @override
  void didUpdateWidget(EncryptedImage old) {
    super.didUpdateWidget(old);
    // The photo was swapped by an edit (tips 482, 81, 224): fetch the new one.
    if (old.msg?.fileId != widget.msg?.fileId && bytes != null) bytes = fetch();
  }

  Future<List<int>> fetch() {
    final s = AppScope.read(context);
    final m = widget.msg;
    return m == null ? s.backend.downloadFile(widget.roomId, widget.eventId) : Downloads.instance.get(s, widget.roomId, m);
  }

  void load() {
    final f = fetch();
    setState(() => bytes = f);
  }

  void noteSize() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final r = context.findRenderObject();
    if (r is RenderBox && r.hasSize) MediaSizes.note(widget.eventId, r.size);
  });

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final s = AppScope.of(context);
    // Loading: the size it had before, so the row keeps its height.
    final had = MediaSizes.of(widget.eventId);
    Widget box(Widget child) => Container(
      width: had?.width ?? 220,
      height: had?.height ?? 160,
      color: p.secondaryLabel.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: child,
    );
    if (bytes == null) {
      return GestureDetector(
        key: const Key('tap-to-download'),
        onTap: load,
        child: box(
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Color(0x66000000), shape: BoxShape.circle),
            child: const Icon(CupertinoIcons.arrow_down, color: Color(0xFFFFFFFF), size: 22),
          ),
        ),
      );
    }
    return FutureBuilder<List<int>>(
      future: bytes,
      builder: (c, snap) {
        final data = snap.data;
        if (data == null || data.isEmpty) return box(const CupertinoActivityIndicator());
        final raw = Uint8List.fromList(data);
        final gif = raw.length > 4 && raw[0] == 0x47 && raw[1] == 0x49 && raw[2] == 0x46;
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260, maxHeight: 340),
          child: gif && !s.gifsMove
              ? StillImage(raw, size: had, onShown: noteSize)
              : Image.memory(
                  raw,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  // Until the picture is decoded it has no size: hold the box.
                  frameBuilder: (_, child, frame, sync) {
                    if (frame == null && !sync) return box(const SizedBox());
                    noteSize();
                    return child;
                  },
                  errorBuilder: (_, _, _) => box(const SizedBox()),
                ),
        );
      },
    );
  }
}

/// First frame only (a GIF that should not move).
class StillImage extends StatefulWidget {
  const StillImage(this.bytes, {super.key, this.size, this.onShown});
  final Uint8List bytes;

  /// The size it had before (kept while the frame decodes).
  final Size? size;
  final VoidCallback? onShown;
  @override
  State<StillImage> createState() => _StillImageState();
}

class _StillImageState extends State<StillImage> {
  ui.Image? frame;

  @override
  void initState() {
    super.initState();
    unawaited(() async {
      try {
        final codec = await ui.instantiateImageCodec(widget.bytes);
        final f = await codec.getNextFrame();
        codec.dispose();
        if (mounted) {
          setState(() => frame = f.image);
        } else {
          f.image.dispose();
        }
      } catch (_) {}
    }());
  }

  @override
  void dispose() {
    frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (frame != null) widget.onShown?.call();
    return frame == null
        ? SizedBox(width: widget.size?.width ?? 220, height: widget.size?.height ?? 160)
        : RawImage(key: const Key('still-gif'), image: frame, fit: BoxFit.cover, width: frame!.width.toDouble(), height: frame!.height.toDouble());
  }
}

/// "1일", "1주", "1달" (or hours / minutes for other values).
String timerLabel(BuildContext context, int secs) => timerText(L.of(context), secs);

/// Full-screen view of a view-once photo. Closing it ends the viewing.
class ViewOncePage extends StatelessWidget {
  const ViewOncePage({super.key, required this.bytes});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return CupertinoPageScaffold(
      key: const Key('view-once-page'),
      backgroundColor: const Color(0xFF000000),
      navigationBar: GlassTopBar.nav(
        backgroundColor: const Color(0x00000000),
        border: null,
        leading: CupertinoButton(
          key: const Key('view-once-close'),
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.xmark, color: Color(0xFFFFFFFF)),
        ),
        middle: Text(l.viewOnceInfo, style: Tokens.caption.style.copyWith(color: const Color(0xFFFFFFFF))),
      ),
      child: CaptureBlock(
        child: Center(
          child: Image.memory(bytes, fit: BoxFit.contain, errorBuilder: (_, _, _) => const SizedBox()),
        ),
      ),
    );
  }
}

/// File name -> media type (shared by the chat and profile screens).
class ChatPageMime {
  const ChatPageMime._();
  static String of(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}

/// Pick the chat to pass a message on to.
class ForwardPickPage extends StatefulWidget {
  const ForwardPickPage({super.key, this.title, this.skip});

  /// Other uses (다른 대화에서 답장): another title, and the chat I'm in left out.
  final String? title;
  final String? skip;

  @override
  State<ForwardPickPage> createState() => _ForwardPickPageState();
}

class _ForwardPickPageState extends State<ForwardPickPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final q = query.trim().toLowerCase();
    final chats = [
      for (final c in AppScope.of(context).chats)
        if ((q.isEmpty || c.name.toLowerCase().contains(q)) && c.roomId != widget.skip) c,
    ];
    return CupertinoPageScaffold(
      backgroundColor: p.list,
      navigationBar: GlassTopBar.nav(
        middle: Text(widget.title ?? l.forwardTo),
        leading: CupertinoButton(padding: EdgeInsets.zero, onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        backgroundColor: p.list,
        border: null,
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[1]),
              child: CupertinoSearchTextField(
                borderRadius: const BorderRadius.all(Radius.circular(18)),
                key: const Key('forward-search'),
                placeholder: l.searchChats,
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: chats.length,
                separatorBuilder: (_, _) => Padding(
                  padding: EdgeInsets.only(left: 40 + Tokens.space[3] * 2),
                  child: Container(height: 1, color: p.separator),
                ),
                itemBuilder: (c, i) {
                  final chat = chats[i];
                  return GestureDetector(
                    key: Key('forward-to-${chat.roomId}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, chat.roomId),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                      child: Row(
                        children: [
                          Avatar(
                            name: chat.name,
                            size: 40,
                            squircle: !chat.isDirect,
                            userId: chat.isDirect ? chat.peer : null,
                            roomId: chat.roomId,
                            owner: chat.isChannel ? chat.peer : null,
                          ),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Text(
                              chat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Tokens.body.style.copyWith(color: p.label),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Link card under a text (Telegram-style bar on the left). The picture was
/// encrypted by the sender's phone; this phone never visits the site until
/// the card is tapped.
class LinkCardView extends StatefulWidget {
  const LinkCardView({super.key, required this.card, required this.roomId, required this.eventId, required this.mine, this.summary = false});
  final LinkCard card;
  final String roomId;
  final String eventId;
  final bool mine;

  /// 링크 3줄 요약 (4-app board, Viber 2025): offered (not in chats with
  /// 공유 비활성화). The phone fetches the page itself and its own AI
  /// writes the lines; only I see them.
  final bool summary;

  @override
  State<LinkCardView> createState() => _LinkCardViewState();
}

class _LinkCardViewState extends State<LinkCardView> {
  Future<List<int>>? image;

  /// 링크 3줄 요약: kept on this phone under the message.
  String? summary;
  bool summaryOpen = false, summaryBusy = false, summaryFailed = false;

  String get summaryKey => PostSummary.key('link:${widget.eventId}');

  @override
  void initState() {
    super.initState();
    if (widget.summary && LocalAi.known == null) unawaited(LocalAi.status().then((_) => mounted ? setState(() {}) : null));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.card.hasImage) image ??= AppScope.of(context).backend.previewImage(widget.roomId, widget.eventId);
    final kept = AppScope.of(context).settings[summaryKey];
    if (summary == null && kept != null && kept.trim().isNotEmpty) summary = kept;
  }

  Future<void> summarize() async {
    if (summaryOpen) return setState(() => summaryOpen = false);
    if (!await aiAgeOk(context) || !mounted) return;
    if (summary != null) return setState(() => summaryOpen = true);
    final s = AppScope.read(context);
    setState(() {
      summaryBusy = true;
      summaryFailed = false;
    });
    final lang = (s.locale ?? WidgetsBinding.instance.platformDispatcher.locale).languageCode == 'en' ? 'English' : 'Korean';
    try {
      final a = await Reader.open(widget.card.url);
      if (a == null || a.text.trim().length < 200) throw const AiError('failed');
      final out = await LocalAi.run(rules: LinkSummary.rules(lang), text: PostSummary.input('${a.title}\n${a.text}'));
      summary = out.trim();
      unawaited(s.setPref(summaryKey, summary!));
      summaryOpen = true;
    } catch (_) {
      summaryFailed = true;
    }
    if (mounted) setState(() => summaryBusy = false);
  }

  /// One outlined button under the card (읽기 모드, 3줄 요약).
  Widget cardButton(Key key, IconData icon, String text, Color line, VoidCallback? onTap) => GestureDetector(
    key: key,
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(top: Tokens.space[0], bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radius[0]),
        border: Border.all(color: line.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: line),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tokens.caption.style.copyWith(color: line, fontWeight: Tokens.semi),
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final c = widget.card;
    final card = GestureDetector(
      key: const Key('link-card'),
      onTap: () => openWebLink(context, c.url),
      child: LinkCardBody(
        site: c.site,
        title: c.title,
        description: c.description,
        image: image,
        small: Features.tipsLink && c.small,
        line: widget.mine ? p.onAccent : p.accent,
        fg: widget.mine ? p.onAccent : p.label,
        above: Features.tipsLink && c.above,
      ),
    );
    // 읽기 모드 (tip 475): the article in a clean page, read on this phone.
    final st = AppScope.of(context);
    if (!Features.tipsAiRead || !Reader.offered(c.url)) return card;
    final reader = st.on('reader_button', fallback: true);
    // 링크 3줄 요약 (4-app board): phones with their own AI only.
    final sum = widget.summary && LocalAi.onPhone && st.on(PostSummary.pref, fallback: true);
    if (!reader && !sum) return card;
    final l = L.of(context);
    final line = widget.mine ? p.onAccent : p.accent;
    final fg = widget.mine ? p.onAccent : p.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        card,
        Row(
          children: [
            if (reader)
              Expanded(child: cardButton(Key('reader-open-${widget.eventId}'), CupertinoIcons.book, l.readerButton, line, () => openReader(context, c.url))),
            if (reader && sum) SizedBox(width: Tokens.space[1]),
            if (sum)
              Expanded(
                child: cardButton(
                  Key('link-summary-${widget.eventId}'),
                  summaryOpen ? CupertinoIcons.chevron_up : CupertinoIcons.sparkles,
                  summaryBusy ? l.linkSummaryBusy : (summaryOpen ? l.linkSummaryHide : l.linkSummaryButton),
                  line,
                  summaryBusy ? null : summarize,
                ),
              ),
          ],
        ),
        if (sum && summaryFailed)
          Padding(
            padding: EdgeInsets.only(top: Tokens.space[0]),
            child: Text(
              l.linkSummaryFailed,
              key: const Key('link-summary-failed'),
              style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7)),
            ),
          ),
        if (sum && summaryOpen && summary != null)
          Container(
            key: const Key('link-summary-box'),
            margin: EdgeInsets.only(top: Tokens.space[1]),
            padding: EdgeInsets.all(Tokens.space[1]),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Tokens.radius[1]),
              border: Border(left: BorderSide(color: line.withValues(alpha: 0.7), width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.linkSummaryTitle,
                  style: Tokens.caption.style.copyWith(color: fg, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(
                  summary!,
                  key: const Key('link-summary-text'),
                  style: Tokens.body.style.copyWith(color: fg),
                ),
                SizedBox(height: Tokens.space[0]),
                Text(l.postSummaryOnPhone, style: Tokens.caption.style.copyWith(color: fg.withValues(alpha: 0.7))),
              ],
            ),
          ),
      ],
    );
  }
}

/// The look of a link card (in a bubble, and while setting it up before
/// sending, tip 400): accent bar, site, title, summary, and the picture —
/// big under the words, or [small] at the side.
class LinkCardBody extends StatelessWidget {
  const LinkCardBody({
    super.key,
    this.site,
    required this.title,
    this.description,
    this.image,
    this.small = false,
    required this.line,
    required this.fg,
    this.above = false,
  });
  final String? site;
  final String title;
  final String? description;
  final Future<List<int>>? image;
  final bool small, above;
  final Color line, fg;

  static const thumb = 56.0, big = 150.0;

  @override
  Widget build(BuildContext context) {
    Widget picture(double? w, double h) => FutureBuilder<List<int>>(
      future: image,
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: small ? EdgeInsets.only(left: Tokens.space[1]) : EdgeInsets.only(top: Tokens.space[0]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[0]),
            child: Image.memory(Uint8List.fromList(bytes), key: const Key('link-card-image'), fit: BoxFit.cover, width: w, height: h),
          ),
        );
      },
    );
    final words = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (site != null)
          Text(
            site!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tokens.caption.style.copyWith(color: line, fontWeight: Tokens.semi),
          ),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Tokens.preview.style.copyWith(color: fg, fontWeight: FontWeight.w500),
        ),
        if (description != null)
          Text(
            description!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Tokens.preview.style.copyWith(color: fg),
          ),
      ],
    );
    return Container(
      key: Key(small ? 'link-card-small' : 'link-card-big'),
      margin: EdgeInsets.only(top: above ? 0 : Tokens.space[0], bottom: above ? Tokens.space[0] : 2),
      padding: EdgeInsets.fromLTRB(Tokens.space[1], 3, Tokens.space[1], Tokens.space[0]),
      decoration: BoxDecoration(
        color: line.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Tokens.radius[0]),
        border: Border(left: BorderSide(color: line, width: 3)),
      ),
      child: image == null
          ? words
          : small
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: words),
                picture(thumb, thumb),
              ],
            )
          : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [words, picture(double.infinity, big)]),
    );
  }
}

String voiceTime(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

/// Play button, loudness bars (filled as it plays) and length.
class VoiceBubble extends StatefulWidget {
  const VoiceBubble({super.key, required this.roomId, required this.msg, required this.fg, required this.meta});
  final String roomId;
  final Msg msg;
  final Color fg;
  final Widget meta;

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  VoicePlayer? player;
  bool playing = false;
  Duration at = Duration.zero;
  final subs = <StreamSubscription<Object>>[];

  @override
  void dispose() {
    for (final s in subs) {
      s.cancel();
    }
    player?.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (playing) {
      await player?.pause();
      return;
    }
    final b = AppScope.of(context).backend;
    if (player == null) {
      final pl = VoiceKit.player();
      player = pl;
      subs.add(pl.position.listen((d) => mounted ? setState(() => at = d) : null));
      subs.add(
        pl.playing.listen((v) {
          if (playing && !v) unawaited(keepPlace());
          if (mounted) setState(() => playing = v);
        }),
      );
      final s = AppScope.read(context);
      final bytes = await b.downloadFile(widget.roomId, widget.msg.id);
      await pl.setSpeed(speedOf(s));
      await pl.play(Uint8List.fromList(bytes), widget.msg.id);
      // 이어 듣기 (tip 199): a long voice message carries on where I stopped.
      final saved = int.tryParse(s.pref(AudioDock.posKey(widget.msg.id), '')) ?? 0;
      if (Features.tipsAudio && long && saved > 5000 && saved < widget.msg.voice!.duration.inMilliseconds - 5000) await pl.seek(Duration(milliseconds: saved));
      return;
    }
    final bytes = await b.downloadFile(widget.roomId, widget.msg.fileId);
    await player!.setSpeed(speedOf(AppScope.read(context)));
    await player!.play(Uint8List.fromList(bytes), widget.msg.id);
  }

  bool get long => widget.msg.voice!.duration >= AudioDock.rememberFrom;

  /// Keeps where a long voice message stopped (cleared once it ends).
  Future<void> keepPlace() async {
    if (!Features.tipsAudio || !long || !mounted) return;
    final end = widget.msg.voice!.duration.inMilliseconds - 3000;
    await AppScope.read(context).setPref(AudioDock.posKey(widget.msg.id), at.inMilliseconds > 3000 && at.inMilliseconds < end ? '${at.inMilliseconds}' : '');
  }

  /// Hold the speed chip: every speed (0.5×–2.5×).
  Future<void> chooseSpeed() async {
    final v = await pickSpeed(context, speedOf(AppScope.read(context)));
    if (v == null || !mounted) return;
    await AppScope.read(context).setPref('voice_speed', '$v');
    await player?.setSpeed(v);
    if (mounted) setState(() {});
  }

  /// v1 voice speed: 1× → 1.5× → 2×, kept for every voice message.
  static double speedOf(AppState s) => double.tryParse(s.pref('voice_speed', '1')) ?? 1;

  Future<void> nextSpeed() async {
    final s = AppScope.read(context);
    final now = speedOf(s);
    final next = now >= 2 ? 1.0 : (now >= 1.5 ? 2.0 : 1.5);
    await s.setPref('voice_speed', '$next');
    await player?.setSpeed(next);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final v = widget.msg.voice!;
    final mine = widget.msg.mine;
    final total = v.duration.inMilliseconds == 0 ? 1 : v.duration.inMilliseconds;
    final done = (at.inMilliseconds / total).clamp(0.0, 1.0);
    final bars = v.waveform.isEmpty ? List.filled(30, 200) : v.waveform;
    // 글로 보기 button on the right, the words underneath (voice_text.dart).
    return VoiceTextArea(roomId: widget.roomId, msg: widget.msg, fg: widget.fg, child: voiceRow(p, v, mine, done, bars));
  }

  Widget voiceRow(Palette p, VoiceInfo v, bool mine, double done, List<int> bars) {
    return Row(
      key: const Key('voice'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          key: const Key('voice-play'),
          onTap: toggle,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: mine ? p.onAccent : p.accent, shape: BoxShape.circle),
            child: Icon(playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill, color: mine ? p.accent : p.onAccent, size: 20),
          ),
        ),
        SizedBox(width: Tokens.space[1]),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < bars.length; i++)
                    Container(
                      width: 2.5,
                      margin: const EdgeInsets.only(right: 1.5),
                      height: 3 + 21 * (bars[i] / 1024),
                      decoration: BoxDecoration(
                        color: i / bars.length <= done && (playing || at > Duration.zero) ? widget.fg : widget.fg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  voiceTime(playing || at > Duration.zero ? at : v.duration),
                  style: Tokens.bubbleMeta.style.copyWith(color: widget.fg.withValues(alpha: 0.7)),
                ),
                if (playing || at > Duration.zero) ...[
                  SizedBox(width: Tokens.space[1]),
                  GestureDetector(
                    key: const Key('voice-speed'),
                    onTap: nextSpeed,
                    onLongPress: Features.tipsAudio ? chooseSpeed : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: widget.fg.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(Tokens.capsule)),
                      child: Text(audioSpeedText(speedOf(AppScope.of(context))), style: Tokens.bubbleMeta.style.copyWith(color: widget.fg)),
                    ),
                  ),
                ],
                SizedBox(width: Tokens.space[2]),
                widget.meta,
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// How a chat hides its messages from people nearby: '' (not hidden),
/// 'dots' (대화방 가리기) or 'blur' (민감한 대화). Both are set per chat in
/// the chat's info page.
String veilOf(AppState s, String roomId) => s.on('veil_all') || s.on('veil_dots:$roomId', fallback: false)
    ? 'dots'
    : s.on('veil_blur:$roomId', fallback: false)
    ? 'blur'
    : '';

/// A finger anywhere on this area opens the [Veil] inside it (the whole
/// chat row or bubble, not just the dotted part; Eric 2026-11-26).
class VeilHold extends StatefulWidget {
  const VeilHold({super.key, required this.child});
  final Widget child;

  static ValueNotifier<Offset?>? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_VeilHoldScope>()?.notifier;

  @override
  State<VeilHold> createState() => _VeilHoldState();
}

class _VeilHoldState extends State<VeilHold> {
  /// Where the finger is (global), null when lifted.
  final at = ValueNotifier<Offset?>(null);

  @override
  void dispose() {
    at.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (e) => at.value = e.position,
    onPointerUp: (_) => at.value = null,
    onPointerCancel: (_) => at.value = null,
    child: _VeilHoldScope(notifier: at, child: widget.child),
  );
}

class _VeilHoldScope extends InheritedNotifier<ValueNotifier<Offset?>> {
  const _VeilHoldScope({required super.notifier, required super.child});
}

/// Hides a bubble's content until a finger rests on it.
class Veil extends StatefulWidget {
  const Veil({super.key, required this.mode, required this.ink, required this.child});
  final String mode;

  /// Colour of the dots (the bubble's text colour).
  final Color ink;
  final Widget child;
  @override
  State<Veil> createState() => _VeilState();
}

class _VeilState extends State<Veil> with TickerProviderStateMixin {
  /// Drift clock for the dust (seconds); stays 0 when motion is off.
  final clock = ValueNotifier<double>(0);
  Ticker? ticker;

  /// 0 = covered, 1 = fully open; grows as a circle from the finger.
  late final reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), reverseDuration: const Duration(milliseconds: 260));
  Offset touch = Offset.zero;
  bool calm = false;

  ValueNotifier<Offset?>? hold;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier;
    calm = (app?.calm ?? false) || (MediaQuery.maybeDisableAnimationsOf(context) ?? false) || SoapBubble.still;
    final h = context.getInheritedWidgetOfExactType<_VeilHoldScope>()?.notifier;
    if (h != hold) {
      hold?.removeListener(held);
      hold = h?..addListener(held);
    }
    sync();
  }

  /// The outer area was pressed or let go.
  void held() {
    final g = hold?.value;
    if (widget.mode.isEmpty) return;
    if (g == null) return close();
    final box = context.findRenderObject() as RenderBox?;
    open(box == null || !box.hasSize ? Offset.zero : box.globalToLocal(g));
  }

  @override
  void didUpdateWidget(Veil old) {
    super.didUpdateWidget(old);
    sync();
  }

  void sync() {
    final run = widget.mode == 'dots' && !calm;
    if (run && ticker == null) {
      ticker = createTicker((d) => clock.value = d.inMicroseconds / 1e6)..start();
    } else if (!run && ticker != null) {
      ticker!.dispose();
      ticker = null;
    }
  }

  @override
  void dispose() {
    hold?.removeListener(held);
    ticker?.dispose();
    reveal.dispose();
    clock.dispose();
    super.dispose();
  }

  void open(Offset at) {
    touch = at;
    if (calm) {
      reveal.value = 1;
    } else {
      reveal.forward(from: reveal.value);
    }
  }

  void close() => calm ? reveal.value = 0 : reveal.reverse();

  @override
  Widget build(BuildContext context) {
    if (widget.mode.isEmpty) return widget.child;
    final dust = widget.mode == 'dots';
    return Listener(
      key: const Key('veil'),
      // Inside a [VeilHold] the outer area drives it instead.
      onPointerDown: hold != null ? null : (e) => open(e.localPosition),
      onPointerUp: hold != null ? null : (_) => close(),
      onPointerCancel: hold != null ? null : (_) => close(),
      child: AnimatedBuilder(
        animation: reveal,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(reveal.value);
          // Fully covered / fully open: no clipping work at all.
          if (t >= 1) return widget.child;
          final covered = dust
              ? Stack(
                  children: [
                    Opacity(opacity: 0, child: widget.child),
                    Positioned.fill(
                      // Soft rounded block, not a hard box (Eric 2026-11-26).
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Tokens.veilDustCorner),
                        child: CustomPaint(painter: _Dust(widget.ink, clock, touch, t)),
                      ),
                    ),
                  ],
                )
              : ClipRect(
                  child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: widget.child),
                );
          if (t <= 0) return covered;
          return Stack(
            children: [
              ClipPath(clipper: _Hole(touch, t, outside: true), child: covered),
              ClipPath(clipper: _Hole(touch, t, outside: false), child: widget.child),
            ],
          );
        },
      ),
    );
  }
}

/// Radius of the reveal circle: from the finger to the farthest corner.
double _holeRadius(Size size, Offset at, double t) {
  double d(double x, double y) => (Offset(x, y) - at).distance;
  final far = [d(0, 0), d(size.width, 0), d(0, size.height), d(size.width, size.height)].reduce((a, b) => a > b ? a : b);
  return far * t;
}

class _Hole extends CustomClipper<Path> {
  _Hole(this.at, this.t, {required this.outside});
  final Offset at;
  final double t;
  final bool outside;

  @override
  Path getClip(Size size) {
    final circle = Path()..addOval(Rect.fromCircle(center: at, radius: _holeRadius(size, at, t)));
    if (!outside) return circle;
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addPath(circle, Offset.zero);
  }

  @override
  bool shouldReclip(_Hole old) => old.t != t || old.at != at;
}

/// Telegram-style spoiler dust: fine dots that drift slowly and twinkle.
/// When the cover opens, dots near the edge of the hole are pushed outward.
class _Dust extends CustomPainter {
  _Dust(this.ink, this.clock, this.at, this.t) : super(repaint: clock);
  final Color ink;
  final ValueNotifier<double> clock;
  final Offset at;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final now = clock.value;
    final paint = Paint();
    var seed = 7;
    double next() => ((seed = (seed * 1103515245 + 12345) & 0x7fffffff) % 10000) / 10000;
    final n = (size.width * size.height / Tokens.veilDustArea).clamp(24, 900).toInt();
    final hole = t > 0 ? _holeRadius(size, at, t) : 0.0;
    for (var i = 0; i < n; i++) {
      final x0 = next() * size.width, y0 = next() * size.height;
      final a = next() * 6.2832, v = Tokens.veilDustSpeed * (0.4 + next() * 0.6);
      final r = 0.45 + next() * 0.55;
      final ph = next() * 6.2832, tw = 1.2 + next() * 2.2;
      var x = (x0 + math.cos(a) * v * now) % size.width;
      var y = (y0 + math.sin(a) * v * now) % size.height;
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;
      if (hole > 0) {
        final off = Offset(x, y) - at;
        final dist = off.distance;
        // Dots just outside the edge get pushed away and fade.
        final push = (1 - ((dist - hole) / 18).clamp(0.0, 1.0)) * 10 * t;
        if (dist > 0) {
          x += off.dx / dist * push;
          y += off.dy / dist * push;
        }
      }
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(now * tw + ph));
      paint.color = ink.withValues(alpha: ink.a * Tokens.veilDustAlpha * twinkle);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_Dust old) => old.ink != ink || old.at != at || old.t != t;
}

/// Messages set to go later in one chat: send now or delete.
class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final mine = s.scheduled.where((m) => m['room'] == roomId).toList()..sort((a, b) => (a['at'] as int).compareTo(b['at'] as int));
    final fmt = DateFormat.MMMd(Localizations.localeOf(context).languageCode).add_jm();
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(title: l.sendLater, back: true, tint: p.background),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            footer: sectionFooter(context, l.scheduledInfo),
            children: [
              for (final m in mine)
                IosTile(
                  key: Key('sched-${m['id']}'),
                  title: Text(m['gif'] is Map ? 'GIF ${m['text']}'.trim() : m['text'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    [
                      fmt.format(DateTime.fromMillisecondsSinceEpoch(m['at'] as int)),
                      switch (m['repeat']) {
                        'day' => l.repeatDay,
                        'week' => l.repeatWeek,
                        'month' => l.repeatMonth,
                        _ => '',
                      },
                    ].where((x) => x.isNotEmpty).join(' · '),
                    style: Tokens.caption.style,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        key: Key('sched-now-${m['id']}'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () async {
                          final left = s.scheduled.where((x) => x['id'] != m['id']).toList();
                          await s.setScheduled([
                            ...left,
                            {...m, 'at': 0},
                          ]);
                          await s.sendDue();
                        },
                        child: Icon(CupertinoIcons.paperplane_fill, color: p.accent),
                      ),
                      CupertinoButton(
                        key: Key('sched-del-${m['id']}'),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(36, 36),
                        onPressed: () => s.setScheduled(s.scheduled.where((x) => x['id'] != m['id']).toList()),
                        child: const Icon(CupertinoIcons.trash, color: Palette.tileRed),
                      ),
                    ],
                  ),
                ),
              if (mine.isEmpty) IosTile(title: Text(l.nothingShared)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-screen field for a link address (no pop-up text boxes).
class LinkEditPage extends StatefulWidget {
  const LinkEditPage({super.key});
  @override
  State<LinkEditPage> createState() => _LinkEditPageState();
}

class _LinkEditPageState extends State<LinkEditPage> {
  final url = TextEditingController(text: 'https://');

  void done() {
    final u = url.text.trim();
    final ok = Uri.tryParse(u)?.hasAuthority == true && (u.startsWith('https://') || u.startsWith('http://'));
    if (ok) Navigator.pop(context, u);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.fmtLink,
        back: true,
        tint: p.background,
        trailing: [GlassPill(key: const Key('link-done'), text: l.done, onTap: done)],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height),
        children: [
          IosSection(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
                child: CupertinoTextField(
                  key: const Key('link-url'),
                  controller: url,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: null,
                  onSubmitted: (_) => done(),
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One to three emoji alone in a message are shown big, without a bubble
/// (Settings > Stickers and emoji > Big emoji).
bool isBigEmoji(String text) {
  // Character emoji alone (1–3) are big too.
  final chars = onlyCharEmoji(text);
  if (chars != null) return chars.length <= 3;
  final s = text.trim();
  if (s.isEmpty || s.characters.length > 3) return false;
  return RegExp(
    r'^(?:[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{FE0F}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]|\s)+$',
    unicode: true,
  ).hasMatch(s);
}

class BigEmoji extends StatelessWidget {
  const BigEmoji(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final chars = onlyCharEmoji(text);
    if (chars != null) {
      // Telegram shows lone custom emoji the size of a small sticker.
      final size = chars.length == 1 ? 112.0 : 72.0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (final id in chars) CharEmoji(id, size: size)],
      );
    }
    // A lone emoji we have a moving picture for (v1): it moves (stays still
    // when 'GIF 자동 재생' is off or in power saving, like stickers).
    final moving = movingEmojiName(text);
    if (moving != null) return TickerMode(enabled: AppScope.of(context).gifsMove, child: MovingEmoji(moving));
    return Text(text, style: TextStyle(fontSize: 48, height: 1.15, fontFamilyFallback: Tokens.emojiFallback));
  }
}

/// Round choice mark on the left of a message in select mode (24 pt,
/// iOS edit-mode circle): thin grey ring, or accent fill with a white check.
class SelectCircle extends StatelessWidget {
  const SelectCircle({super.key, required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[1]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? p.accent : const Color(0x00000000),
          border: on ? null : Border.all(color: p.secondaryLabel, width: 1.5),
        ),
        child: on ? Icon(CupertinoIcons.checkmark_alt, size: Tokens.listIconSmall - 2, color: p.onAccent) : null,
      ),
    );
  }
}

/// "목록으로 보기": the search results as a list, newest first.
class SearchHitsPage extends StatelessWidget {
  const SearchHitsPage({super.key, required this.hits, required this.title});
  final List<Msg> hits;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(back: true, title: l.searchFound),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.only(top: Tokens.space[2]),
          children: [
            IosSection(
              hasLeading: false,
              children: [
                for (final (i, m) in hits.indexed)
                  GestureDetector(
                    key: Key('hit-$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.pop(context, m.id),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1] + 2),
                      child: Row(
                        children: [
                          Avatar(name: m.mine ? l.you : displayId(m.sender), size: 40, userId: m.mine ? null : m.sender),
                          SizedBox(width: Tokens.space[2]),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        m.mine ? l.you : displayId(m.sender),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Tokens.preview.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                                      ),
                                    ),
                                    Text(shortTime(context, m.time), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                                  ],
                                ),
                                SizedBox(height: Tokens.nameToSub),
                                Text(
                                  previewText(context, kind: m.kind, body: m.body, caption: m.caption),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                                ),
                              ],
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

/// Live loudness as a row of dots (locked voice recording).
class _LevelDots extends StatelessWidget {
  const _LevelDots({required this.levels, required this.color});
  final List<double> levels;
  final Color color;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (c, box) {
      final n = (box.maxWidth / 6).floor().clamp(0, 60);
      final shown = levels.length > n ? levels.sublist(levels.length - n) : levels;
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          for (var i = 0; i < n; i++)
            Container(
              width: 3,
              height: 3 + (i >= n - shown.length ? shown[i - (n - shown.length)] * 16 : 0),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
        ],
      );
    },
  );
}

/// "스레드로 답장": the first message, its replies, and a box to answer.
class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key, required this.roomId, required this.root, required this.chatTitle});
  final String roomId;
  final Msg root;
  final String chatTitle;
  @override
  State<ThreadPage> createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  final input = TextEditingController();
  List<Msg> replies = const [];
  Timer? poll;
  bool group = false;

  @override
  void initState() {
    super.initState();
    poll = Timer.periodic(const Duration(seconds: 3), (_) => load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final row = AppScope.of(context).chats.where((c) => c.roomId == widget.roomId);
    group = row.isNotEmpty && !row.first.isDirect;
    load();
  }

  @override
  void dispose() {
    poll?.cancel();
    input.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final all = await AppScope.of(context).backend.timeline(widget.roomId, limit: 500);
    if (!mounted) return;
    setState(() => replies = all.where((x) => x.threadRoot == widget.root.id).toList());
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();
    await AppScope.of(context).backend.replyInThread(widget.roomId, widget.root.id, text);
    await load();
  }

  Widget bubble(Msg m) => Padding(
    padding: EdgeInsets.symmetric(vertical: Tokens.space[0] / 2),
    child: Bubble(msg: m, roomId: widget.roomId, chatTitle: widget.chatTitle, senderName: group && !m.mine ? displayId(m.sender) : null),
  );

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    return CupertinoPageScaffold(
      backgroundColor: p.chatBackground,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(), middle: Text(l.threadTitle), backgroundColor: p.chatBackground),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                key: const Key('thread-list'),
                // Same side gap as the chat itself.
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[1], vertical: Tokens.space[2]),
                children: [
                  bubble(widget.root),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: Tokens.space[2]),
                    child: Center(
                      child: Text(
                        replies.isEmpty ? l.threadEmpty : l.threadReplies(replies.length),
                        key: const Key('thread-count'),
                        style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                      ),
                    ),
                  ),
                  for (final m in replies) bubble(m),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: LiquidGlass(
                      radius: Tokens.closeButton / 2,
                      child: CupertinoTextField.borderless(
                        key: const Key('thread-input'),
                        controller: input,
                        placeholder: l.threadPlaceholder,
                        placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
                        style: Tokens.body.style.copyWith(color: p.label),
                        minLines: 1,
                        maxLines: 5,
                        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] - 1),
                        onSubmitted: (_) => send(),
                      ),
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  TextFieldTapRegion(
                    child: AccentCircle(key: const Key('thread-send'), icon: CupertinoIcons.arrow_up, onTap: send),
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

/// Settings > Chats > Find plans: a tapped date or time in a message offers
/// a reminder (an hour before, or at the time). Kept on this phone only.
Future<void> planReminder(BuildContext context, String roomId, String chat, Msg m, DateTime at) async {
  final l = L.of(context);
  final fmt = DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag()).add_jm();
  final early = at.subtract(const Duration(hours: 1));
  final pick = await showCupertinoModalPopup<DateTime>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      title: Text(l.planFound(fmt.format(at))),
      actions: [
        if (early.isAfter(DateTime.now()))
          CupertinoActionSheetAction(key: const Key('plan-early'), onPressed: () => Navigator.pop(c, early), child: Text(l.planHourBefore)),
        CupertinoActionSheetAction(key: const Key('plan-at'), onPressed: () => Navigator.pop(c, at), child: Text(l.planAtTime)),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  await addReminder(AppScope.read(context), Reminder(roomId: roomId, msgId: m.id, chat: chat, at: pick));
  if (context.mounted) showStoryToast(context, l.remindSet(fmt.format(pick)));
}

/// The time and ticks over a photo: a small dark pill, white marks.
Widget onPhotoMeta(Widget meta) => Container(
  key: const Key('photo-meta'),
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: BoxDecoration(color: const Color(0x73000000), borderRadius: BorderRadius.circular(Tokens.capsule)),
  child: ColorFiltered(colorFilter: const ColorFilter.mode(Color(0xFFFFFFFF), BlendMode.srcIn), child: meta),
);

/// "23시간 안에 열어야 해요" under an unopened view-once photo (4-app board:
/// unopened, it goes by itself). Mine: "안 열면 23시간 뒤 사라져요". Null when
/// it has no end time or it was opened.
String? onceLeft(L l, Msg m, bool mine, {DateTime? now}) {
  final end = m.expiresAt;
  if (end == null || m.opened) return null;
  final left = end.difference(now ?? DateTime.now());
  if (left.isNegative) return null;
  final h = left.inHours;
  if (mine) return h >= 1 ? l.onceGoesHours(h) : l.onceGoesMinutes(left.inMinutes.clamp(1, 59));
  return h >= 1 ? l.onceOpenWithinHours(h) : l.onceOpenWithinMinutes(left.inMinutes.clamp(1, 59));
}

/// 문의함: one subscriber's chat in place of the page on top (no slide).
void openInboxRoom(BuildContext context, String room, String name, String channel) => Navigator.of(context).pushReplacement(
  PageRouteBuilder<void>(
    transitionDuration: Duration.zero,
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => ChatPage(roomId: room, title: name, dmInbox: channel),
  ),
);
