// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// What the screens need from the engine. Screens only talk to this, so they
// can be tested without a server and the engine can change underneath.
import 'dart:convert';
import 'dart:typed_data';

import 'imported.dart';
import 'room_links.dart' show InviteLink;
import 'trust.dart';
import 'join_gate.dart';
import 'search.dart';
export 'join_gate.dart';
export 'imported.dart' show ImportMark, ImportedChat, ImportPerson;
export 'search.dart' show Found, PublicPost;

class ChatPreview {
  const ChatPreview({
    required this.roomId,
    required this.name,
    required this.isDirect,
    required this.encrypted,
    required this.unread,
    this.last,
    this.streak = 0,
    this.streakAtRisk = false,
    this.pinned = false,
    this.archived = false,
    this.muted = false,
    this.isChannel = false,
    this.peer = '',
  });
  final String roomId;
  final String name;
  final bool isDirect;

  /// Only owners and admins post; for a 1:1, the other person's ID.
  final bool isChannel;
  final String peer;

  /// A 1:1 with a bot (bot IDs end in "bot").
  bool get isBot => isDirect && peer.split(':').first.toLowerCase().endsWith('bot');
  final bool encrypted;
  final int unread;
  final Msg? last;

  /// 1:1 streak days (0 = none) and whether it ends tonight.
  final int streak;
  final bool streakAtRisk;

  /// Kept on top / moved to the archive (both only on this phone) /
  /// no alerts.
  final bool pinned;
  final bool archived;
  final bool muted;

  /// The same chat with another unread count (marked unread by hand).
  ChatPreview withUnread(int n) => ChatPreview(
    roomId: roomId,
    name: name,
    isDirect: isDirect,
    encrypted: encrypted,
    unread: n,
    last: last,
    streak: streak,
    streakAtRisk: streakAtRisk,
    pinned: pinned,
    archived: archived,
    muted: muted,
    isChannel: isChannel,
    peer: peer,
  );
}

/// A view-once photo, video or voice clip nobody opened is gone after a
/// day (same as the engine's VIEW_ONCE_TTL).
const viewOnceLife = Duration(hours: 24);

class Msg {
  const Msg({
    required this.id,
    required this.sender,
    required this.body,
    required this.time,
    required this.mine,
    required this.kind,
    this.replyTo,
    this.quote,
    this.quoteName,
    this.threadRoot,
    this.topic,
    this.edited = false,
    this.editedAt,
    this.firstBody,
    this.reactions = const [],
    this.expiresAt,
    this.viewOnce = false,
    this.opened = false,
    this.forwarded = false,
    this.preview,
    this.voice,
    this.live,
    this.poll,
    this.bubble = false,
    this.call,
    this.caption,
    this.checklist,
    this.meetup,
    this.contact,
    this.card,
    this.size,
    this.imported,
    this.captionAbove = false,
    this.mediaFrom,
    this.mediaChanged = false,
    this.postAs,
  });
  final String id;

  /// 설명 위로 (Telegram tip 452): the words show above the photo or video.
  final bool captionAbove;

  /// The photo, video or file was swapped by an edit (tips 482, 81, 224):
  /// its file is in this event; the old one stays in [id] (수정 기록).
  final String? mediaFrom;
  final bool mediaChanged;

  /// Where to download this message's file from now.
  String get fileId => mediaFrom ?? id;

  /// 보내는 이름 (tips 472 + 310): who it was sent as, if not the sender
  /// themself (the app checks the claim before showing it).
  final PostAs? postAs;

  /// 다른 앱 대화 가져오기: brought in from KakaoTalk, WhatsApp or Telegram
  /// (core/imported.dart), shown with a "가져옴" mark; null = sent here.
  final ImportMark? imported;
  final String sender;

  /// File size in bytes (photo, video, file, voice) when the sender wrote it.
  final int? size;

  /// null = not opened yet (key missing).
  final String? body;
  final DateTime time;
  final bool mine;

  /// text, image, video, audio, file, locked
  final String kind;

  /// Id of the message this one answers.
  final String? replyTo;

  /// 부분 인용 (Telegram tip 399): only this part of the answered message
  /// is shown above the reply. With [quoteName] and no [replyTo] the words
  /// were copied from another chat ("다른 대화에서 답장").
  final String? quote;
  final String? quoteName;

  /// First message of the thread this one is in ("스레드로 답장").
  final String? threadRoot;

  /// 주제 (group topics, tip 527): the topic id carried inside the
  /// encrypted content; null = 일반. The server never sees it.
  final String? topic;
  final bool edited;

  /// When it was last changed, and the words as first sent ("수정 기록").
  final DateTime? editedAt;
  final String? firstBody;
  final List<Reaction> reactions;

  /// Disappears at this time (chat timer), or null.
  final DateTime? expiresAt;

  /// Photo/video that opens only once, and whether it was opened.
  final bool viewOnce;
  final bool opened;

  /// Passed on from another chat (where from is never kept).
  final bool forwarded;

  /// Card for the first link (title, picture), made by the sender's phone.
  final LinkCard? preview;

  /// Voice message length and loudness bars (0..1024).
  final VoiceInfo? voice;

  /// 움직이는 사진: this photo also carries a short clip (kind "image").
  final LiveInfo? live;

  /// Poll with its current numbers (kind "poll").
  final PollInfo? poll;

  /// A home-screen bubble (always opens once).
  final bool bubble;

  /// Voice/video call line (kind "call").
  final CallInfo? call;

  /// Words under a photo, video or file (body is then the file name).
  final String? caption;

  /// Checklist with its ticks (kind "checklist").
  final ChecklistInfo? checklist;

  /// Plan with who is coming (kind "meetup").
  final MeetupInfo? meetup;

  /// Shared contact's user id (kind "contact"; body = their name).
  final String? contact;

  /// FAQ, guide menu, link buttons, formatted post, giveaway, form or
  /// safety check-in (kind "card").
  final CardInfo? card;

  /// 부분 인용 / 다른 대화에서 답장 (tip 399): this message as the thing a
  /// reply answers, showing only [part] of it. [otherChat]: it lives in
  /// another chat, so the reply cannot point at it (id "") and carries the
  /// writer's [name] instead.
  Msg asQuote(String part, {bool otherChat = false, String name = ''}) => Msg(
    id: otherChat ? '' : id,
    sender: sender,
    body: body,
    time: time,
    mine: mine,
    kind: kind,
    caption: caption,
    quote: part,
    quoteName: otherChat ? name : null,
  );

  /// Same message with a few things changed (everything else kept).
  Msg copyWith({
    String? body,
    String? topic,
    bool? edited,
    List<Reaction>? reactions,
    bool? opened,
    PollInfo? poll,
    CallInfo? call,
    ChecklistInfo? checklist,
    MeetupInfo? meetup,
    CardInfo? card,
  }) => Msg(
    id: id,
    sender: sender,
    body: body ?? this.body,
    time: time,
    mine: mine,
    kind: kind,
    replyTo: replyTo,
    quote: quote,
    quoteName: quoteName,
    threadRoot: threadRoot,
    topic: topic ?? this.topic,
    edited: edited ?? this.edited,
    editedAt: editedAt,
    firstBody: firstBody,
    reactions: reactions ?? this.reactions,
    expiresAt: expiresAt,
    viewOnce: viewOnce,
    opened: opened ?? this.opened,
    forwarded: forwarded,
    preview: preview,
    voice: voice,
    live: live,
    poll: poll ?? this.poll,
    bubble: bubble,
    call: call ?? this.call,
    caption: caption,
    checklist: checklist ?? this.checklist,
    meetup: meetup ?? this.meetup,
    contact: contact,
    card: card ?? this.card,
    size: size,
    imported: imported,
    postAs: postAs,
    captionAbove: captionAbove,
    mediaFrom: mediaFrom,
    mediaChanged: mediaChanged,
  );

  /// Same message after a photo/caption edit (tips 452 B, 482): new kind,
  /// file name, words and their place; [mediaFrom] when the file changed.
  Msg afterMediaEdit({required String kind, required String? body, required String? caption, required bool captionAbove, String? mediaFrom, int? size}) => Msg(
    id: id,
    sender: sender,
    body: body,
    time: time,
    mine: mine,
    kind: kind,
    replyTo: replyTo,
    quote: quote,
    quoteName: quoteName,
    threadRoot: threadRoot,
    edited: true,
    editedAt: editedAt,
    firstBody: firstBody ?? (this.kind == 'text' ? this.body : (this.caption ?? '')),
    reactions: reactions,
    expiresAt: expiresAt,
    viewOnce: viewOnce,
    opened: opened,
    forwarded: forwarded,
    preview: mediaFrom != null ? null : preview,
    voice: voice,
    live: live,
    poll: poll,
    bubble: bubble,
    call: call,
    caption: caption,
    checklist: checklist,
    meetup: meetup,
    contact: contact,
    card: card,
    size: size ?? this.size,
    imported: imported,
    captionAbove: captionAbove,
    mediaFrom: mediaFrom ?? this.mediaFrom,
    mediaChanged: mediaChanged || mediaFrom != null,
    postAs: postAs,
  );

  /// Same message with another link card (or none).
  Msg withPreview(LinkCard? card) => copyWith()._preview(card);

  Msg _preview(LinkCard? p) => Msg(
    id: id,
    sender: sender,
    body: body,
    time: time,
    mine: mine,
    kind: kind,
    replyTo: replyTo,
    quote: quote,
    quoteName: quoteName,
    threadRoot: threadRoot,
    topic: topic,
    edited: edited,
    editedAt: editedAt,
    firstBody: firstBody,
    reactions: reactions,
    expiresAt: expiresAt,
    viewOnce: viewOnce,
    opened: opened,
    forwarded: forwarded,
    preview: p,
    voice: voice,
    live: live,
    poll: poll,
    bubble: bubble,
    call: call,
    caption: caption,
    checklist: checklist,
    meetup: meetup,
    contact: contact,
    card: card,
    size: size,
    imported: imported,
    captionAbove: captionAbove,
    mediaFrom: mediaFrom,
    mediaChanged: mediaChanged,
    postAs: postAs,
  );
}

/// 보내는 이름 (channel batch #15): [channel] = an admin posting as the
/// channel itself in a channel that shows authors (472); [room] + [address]
/// = sent as one of the sender's public channels (310).
class PostAs {
  const PostAs.channel() : channel = true, room = '', address = '';
  const PostAs.of(this.room, this.address) : channel = false;
  final bool channel;
  final String room, address;

  static PostAs? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final v = jsonDecode(json);
      if (v is! Map) return null;
      if (v['ch'] == true) return const PostAs.channel();
      final r = v['room'], a = v['addr'];
      if (r is String && r.startsWith('!')) return PostAs.of(r, a is String ? a : '');
    } catch (_) {}
    return null;
  }

  String toJson() => channel ? '{"ch":true}' : jsonEncode({'room': room, 'addr': address});
}

/// 움직이는 사진: how its clip plays ("live" once, "loop", "bounce") and
/// how long the clip is.
class LiveInfo {
  const LiveInfo(this.style, this.duration);
  final String style;
  final Duration duration;
}

/// One line of the call history (Calls tab).
class CallLogItem {
  const CallLogItem({required this.roomId, required this.from, required this.mine, required this.call});
  final String roomId;
  final String from;
  final bool mine;
  final CallInfo call;
}

/// An invitation to a chat. 1:1 ones are opened on their own.
class Invite {
  const Invite({required this.roomId, required this.name, required this.inviter, required this.direct});
  final String roomId;
  final String name;
  final String inviter;
  final bool direct;
}

/// A group's or channel's invite link (manual 6-1, 6-7).
/// A draft typed on another of my devices.
class SyncedDraft {
  const SyncedDraft(this.roomId, this.text, this.at);
  final String roomId;

  /// Empty = sent or cleared there.
  final String text;
  final DateTime at;
}

class RoomLink {
  const RoomLink({this.kind = 'none', this.code = '', this.approval = false, this.web = false});

  /// "public" (address everyone sees), "private" (secret code) or "none".
  final String kind;

  /// The address (public) or code (private).
  final String code;

  /// People ask first and an admin lets them in.
  final bool approval;

  /// Public channel web page is on.
  final bool web;

  bool get public => kind == 'public';
  bool get private => kind == 'private';
}

/// What a public link shows before coming in.
class LinkPeek {
  const LinkPeek({
    required this.roomId,
    required this.name,
    this.about = '',
    this.members = 0,
    this.channel = false,
    this.approval = false,
    this.joined = false,
    this.photo,
    this.address = '',
  });
  final String roomId;

  /// Its public address (전체 검색 results), or empty.
  final String address;
  final String name;
  final String about;
  final int members;
  final bool channel;
  final bool approval;
  final bool joined;

  /// The room's public photo (public links only; private rooms keep theirs
  /// encrypted, so their link shows the first letter).
  final Uint8List? photo;
}

/// Someone asking to come in (approval on).
class JoinRequest {
  const JoinRequest({required this.userId, required this.name, this.answers = const []});
  final String userId;
  final String name;

  /// Answers to the room's join questions sent with the request.
  final List<String> answers;
}

/// A phone notification made on this phone.
class Notice {
  const Notice({required this.roomId, required this.chat, required this.sender, required this.kind, this.body, required this.time});
  final String roomId;

  /// Empty when the person hides notification text.
  final String chat;
  final String sender;
  final String kind;
  final String? body;
  final DateTime time;
}

/// One call in a chat.
class CallInfo {
  const CallInfo({required this.id, required this.video, required this.state, required this.started, this.answered, this.ended});
  final String id;
  final bool video;

  /// ringing, ongoing, ended, missed, declined, busy
  final String state;
  final DateTime started;
  final DateTime? answered;
  final DateTime? ended;

  /// How long we talked (answered calls that ended).
  Duration? get talked => answered != null && ended != null ? ended!.difference(answered!) : null;
}

/// A call ringing for me.
class RingingCall {
  const RingingCall({required this.roomId, required this.callId, required this.from, required this.video, required this.time});
  final String roomId;
  final String callId;
  final String from;
  final bool video;
  final DateTime time;
}

/// Ticket into a call: server address, pass, and the media key that only
/// travelled inside the encrypted chat.
class CallTicket {
  const CallTicket({required this.url, required this.token, required this.mediaKey, required this.video});
  final String url;
  final String token;
  final String mediaKey;
  final bool video;
}

/// A bubble waiting for me: who and when, never what.
class BubbleRef {
  const BubbleRef({required this.roomId, required this.id, required this.from, required this.time});
  final String roomId;
  final String id;
  final String from;
  final DateTime time;
}

/// A story within its 24 hours: mine (once) or a friend's.
/// postStories(room: '$memberStoryPrefix<room id>'): a member's story for
/// one group only (engine MEMBER_STORY_PREFIX).
const memberStoryPrefix = 'members:';

class Story {
  const Story({
    required this.id,
    required this.roomId,
    required this.eventId,
    required this.sender,
    required this.mine,
    required this.time,
    required this.kind,
    this.caption,
    this.extra,
    this.feed = false,
    this.pin,
    this.until,
    this.edited = false,
    this.group = false,
    this.member = false,
  });
  final String id;
  final String roomId;
  final String eventId;
  final String sender;
  final bool mine;
  final DateTime time;

  /// Kept on the profile past its hours (tips 392 / 468 / 534): the pin
  /// JSON ({"album": "제주도", "top": true}); null = not kept.
  final String? pin;

  /// When it leaves the story row (null: a feed post).
  final DateTime? until;

  /// Changed after posting (tip 393).
  final bool edited;

  /// A group's or channel's story (tip 428): [roomId] is that room.
  final bool group;

  /// 그룹 전용 스토리 (4-app board): [sender]'s own story that only the
  /// members of group [roomId] get ([group] is true too).
  final bool member;

  /// Still in the story row (not only kept on a profile).
  bool get inRow => !feed && (until == null || until!.isAfter(DateTime.now()));

  bool get kept => pin != null;

  Map<String, dynamic> get _pin {
    try {
      final j = jsonDecode(pin ?? '');
      return j is Map<String, dynamic> ? j : const {};
    } catch (_) {
      return const {};
    }
  }

  /// The album it is kept in on the profile ('' = none).
  String get album {
    final a = _pin['album'];
    return a is String ? (a.length > 40 ? a.substring(0, 40) : a) : '';
  }

  /// Pinned to the top of the profile (up to 3).
  bool get top => _pin['top'] == true;

  Story copyWith({String? caption, String? extra, String? pin, bool clearPin = false, String? eventId, bool? edited}) => Story(
    id: id,
    roomId: roomId,
    eventId: eventId ?? this.eventId,
    sender: sender,
    mine: mine,
    time: time,
    kind: kind,
    caption: caption ?? this.caption,
    extra: extra ?? this.extra,
    feed: feed,
    pin: clearPin ? null : (pin ?? this.pin),
    until: until,
    edited: edited ?? this.edited,
    group: group,
  );

  /// "image" or "video" ("text" only for a feed post).
  final String kind;

  /// A friend-feed post (kept until deleted), not a 24-hour story.
  final bool feed;
  final String? caption;

  /// Poll / question / plan parts (JSON), drawn live by the viewer.
  final String? extra;
}

/// What postStories sent: how many chats, and the new story ids.
class StoryPosted {
  const StoryPosted(this.sent, this.ids);
  final int sent;
  final List<String> ids;
}

/// A like on a feed post.
class FeedLike {
  const FeedLike({required this.postId, required this.sender, required this.mine});
  final String postId;
  final String sender;
  final bool mine;
}

/// A plan ("일정"): what, when, where, and who is coming.
class MeetupInfo {
  const MeetupInfo({
    required this.title,
    required this.startsAt,
    this.endsAt,
    this.place,
    this.cancelled = false,
    this.yes = const [],
    this.no = const [],
    this.maybe = const [],
    this.guests = const {},
  });
  final String title;
  final DateTime startsAt;

  /// When it ends (null = open-ended).
  final DateTime? endsAt;
  final String? place;
  final bool cancelled;
  final List<String> yes;
  final List<String> no;
  final List<String> maybe;

  /// Extra people a "yes" brings along (person -> 1..9; missing = alone).
  final Map<String, int> guests;

  /// Most people one person can bring along.
  static const maxGuests = 9;

  /// People coming, counting the ones they bring.
  int get coming => yes.length + guests.values.fold(0, (a, b) => a + b);

  /// My answer: "yes", "no", "maybe" or "".
  String answerOf(String? me) => yes.contains(me) ? 'yes' : (no.contains(me) ? 'no' : (maybe.contains(me) ? 'maybe' : ''));

  /// How many I bring along (0 when I'm not coming or come alone).
  int guestsOf(String? me) => yes.contains(me) ? (guests[me] ?? 0) : 0;

  /// The answer as sent: "yes+2" for me and two more.
  static String answerWith(String answer, int guests) => answer == 'yes' && guests > 0 ? 'yes+${guests.clamp(1, maxGuests)}' : answer;

  MeetupInfo copyWith({bool? cancelled, List<String>? yes, List<String>? no, List<String>? maybe, Map<String, int>? guests}) => MeetupInfo(
    title: title,
    startsAt: startsAt,
    endsAt: endsAt,
    place: place,
    cancelled: cancelled ?? this.cancelled,
    yes: yes ?? this.yes,
    no: no ?? this.no,
    maybe: maybe ?? this.maybe,
    guests: guests ?? this.guests,
  );
}

/// A checklist: items people tick (only those the maker allowed).
class ChecklistInfo {
  const ChecklistInfo({required this.title, required this.items, this.othersMark = false, this.othersAdd = false});
  final String title;
  final List<ChecklistItem> items;
  final bool othersMark;
  final bool othersAdd;

  int get done => items.where((i) => i.doneBy != null).length;
}

class ChecklistItem {
  const ChecklistItem(this.id, this.text, {this.doneBy, this.addedBy});
  final String id;
  final String text;

  /// Who ticked it (null = not done).
  final String? doneBy;
  final String? addedBy;
}

/// A channel/group card. [data] is the checked content (see each kind);
/// answers go only to the maker's phone, which posts the numbers.
class CardInfo {
  const CardInfo({required this.kind, required this.data, this.counts = const {}, this.winners = const [], this.closed = false, this.mine, this.won = false});

  /// faq, guide, links, rich, lottery, form, checkin, flow
  final String kind;
  final Map<String, Object?> data;

  /// Numbers from the maker: "in" (giveaway), "ok"/"help" (check-in), "sent" (form).
  final Map<String, int> counts;
  final List<String> winners;
  final bool closed;

  /// My own answer (null = none): "in", "ok"/"help", or a list of form answers.
  final Object? mine;

  /// I won this giveaway (when names stay private only I am told).
  final bool won;

  /// Giveaway deadline (null = none).
  DateTime? get endsAt {
    final e = data['ends_at'];
    return e is int && e > 0 ? DateTime.fromMillisecondsSinceEpoch(e) : null;
  }

  bool closedAt(DateTime now) => closed || (endsAt != null && !now.isBefore(endsAt!));

  /// Kinds people answer.
  static bool answered(String kind) => const ['lottery', 'form', 'checkin', 'flow'].contains(kind);

  List<Map<String, Object?>> listOf(String key) => [
    for (final x in (data[key] is List ? data[key] as List : const []))
      if (x is Map) x.cast<String, Object?>(),
  ];
  String text(String key) => data[key] is String ? data[key] as String : '';
}

/// True when some choice path from the first question ends on a result.
bool flowReachesResult(List<List<String>> targets) {
  if (targets.isEmpty) return false;
  final seen = <int>{};
  final todo = [0];
  while (todo.isNotEmpty) {
    final i = todo.removeLast();
    if (!seen.add(i) || i >= targets.length) continue;
    for (final to in targets[i]) {
      if (to.startsWith('r')) return true;
      final n = int.tryParse(to.substring(1));
      if (n != null) todo.add(n);
    }
  }
  return false;
}

/// One answer the maker can read (form, check-in, giveaway).
class CardAnswer {
  const CardAnswer(this.user, this.answer);
  final String user;
  final Object? answer;
}

class PollInfo {
  const PollInfo({
    required this.question,
    required this.options,
    this.anonymous = true,
    this.multiple = false,
    this.closed = false,
    this.voters = 0,
    this.mine = const [],
    this.correct,
    this.explain = '',
    this.closeAt,
    this.description = '',
    this.hasPhoto = false,
    this.addOptions = false,
    this.changeVote = true,
    this.shuffle = false,
    this.hideResults = false,
  });
  final String question;
  final List<PollOption> options;

  /// Words under the question, and whether a photo is attached to them.
  final String description;
  final bool hasPhoto;

  /// Members may add answers.
  final bool addOptions;

  /// People may change or take back their vote (a quiz never).
  final bool changeVote;

  /// Each person sees the answers in their own random order.
  final bool shuffle;

  /// Numbers stay hidden until the poll ends.
  final bool hideResults;

  /// Whether numbers may be shown now (after voting or the end; hidden
  /// polls only after the end).
  bool resultsOpen(DateTime now) => closedAt(now) || (mine.isNotEmpty && !hideResults);

  /// The answers in the order this person sees them: shuffled polls use a
  /// fixed order per poll and person, so it doesn't jump on every refresh.
  List<PollOption> orderFor(String pollId, String me) {
    if (!shuffle) return options;
    int h(String s) {
      var x = 0x811c9dc5;
      for (final c in s.codeUnits) {
        x = ((x ^ c) * 0x01000193) & 0xffffffff;
      }
      return x;
    }

    final list = [...options];
    list.sort((a, b) => h('$pollId|$me|${a.id}').compareTo(h('$pollId|$me|${b.id}')));
    return list;
  }

  PollInfo copyWith({List<PollOption>? options, bool? closed, int? voters, List<String>? mine}) => PollInfo(
    question: question,
    options: options ?? this.options,
    anonymous: anonymous,
    multiple: multiple,
    closed: closed ?? this.closed,
    voters: voters ?? this.voters,
    mine: mine ?? this.mine,
    correct: correct,
    explain: explain,
    closeAt: closeAt,
    description: description,
    hasPhoto: hasPhoto,
    addOptions: addOptions,
    changeVote: changeVote,
    shuffle: shuffle,
    hideResults: hideResults,
  );

  /// Quiz: the right answer's id, and why (shown after answering).
  final String? correct;
  final String explain;

  /// Voting stops at this time (null = no deadline).
  final DateTime? closeAt;
  bool get isQuiz => correct != null;

  /// Closed by the maker or past its deadline.
  bool closedAt(DateTime now) => closed || (closeAt != null && !now.isBefore(closeAt!));
  final bool anonymous;
  final bool multiple;
  final bool closed;
  final int voters;

  /// Ids of the options I chose.
  final List<String> mine;
}

class PollOption {
  const PollOption(this.id, this.text, this.votes, [this.who = const [], this.hasPhoto = false, this.sticker = '', this.geo = '', this.addedBy = '']);
  final String id;
  final String text;
  final int votes;

  /// Open polls only: who chose it.
  final List<String> who;

  /// One attachment at most: a photo, a built-in sticker id, or a place
  /// ("geo:lat,lon"); empty = none.
  final bool hasPhoto;
  final String sticker;
  final String geo;

  /// A member added this answer (their id; empty = the maker's own).
  final String addedBy;

  PollOption withVotes(int n, List<String> by) => PollOption(id, text, n, by, hasPhoto, sticker, geo, addedBy);
}

/// What a new poll carries besides the question and answers.
class PollExtras {
  const PollExtras({
    this.description = '',
    this.photo,
    this.addOptions = false,
    this.changeVote = true,
    this.shuffle = false,
    this.hideResults = false,
    this.attachments = const [],
  });
  final String description;

  /// Photo under the question (hidden details are stripped before sending).
  final PollPhoto? photo;
  final bool addOptions;
  final bool changeVote;
  final bool shuffle;
  final bool hideResults;

  /// Same order as the answers given to [Backend.createPoll] (null = none).
  final List<PollAttachment?> attachments;
}

class PollPhoto {
  const PollPhoto(this.mime, this.bytes);
  final String mime;
  final List<int> bytes;
}

/// One answer's attachment: exactly one of photo, sticker, geo.
class PollAttachment {
  const PollAttachment.photo(PollPhoto this.photo) : sticker = null, geo = null;
  const PollAttachment.sticker(String this.sticker) : photo = null, geo = null;
  const PollAttachment.geo(String this.geo) : photo = null, sticker = null;
  final PollPhoto? photo;
  final String? sticker;
  final String? geo;
}

class VoiceInfo {
  const VoiceInfo(this.duration, this.waveform);
  final Duration duration;
  final List<int> waveform;
}

/// A story link sticker's card (tip 467), read by my phone only.
class StoryLinkInfo {
  const StoryLinkInfo({required this.title, required this.site, this.description = '', this.image = const []});
  final String title, site, description;

  /// The page picture as downloaded (empty = none).
  final List<int> image;
}

class LinkCard {
  const LinkCard({required this.url, required this.title, this.description, this.site, this.hasImage = false, this.above = false, this.small = false});
  final String url;
  final String title;
  final String? description;
  final String? site;
  final bool hasImage;

  /// Tip 400: the sender put the card above the words / chose a small
  /// picture at the side.
  final bool above;
  final bool small;
}

/// Tip 400: how the sender set up the link card before sending.
class LinkChoice {
  const LinkChoice({this.url, this.above = false, this.small = false, this.off = false});

  /// The picked link (null = the first one in the text).
  final String? url;
  final bool above, small;

  /// 미리보기 안 함.
  final bool off;
  bool get plain => url == null && !above && !small && !off;
  LinkChoice copyWith({String? url, bool? above, bool? small, bool? off}) =>
      LinkChoice(url: url ?? this.url, above: above ?? this.above, small: small ?? this.small, off: off ?? this.off);
}

class Reaction {
  const Reaction(this.key, this.count, this.mine);
  final String key;
  final int count;

  /// My own reaction's id (to take it back), or null.
  final String? mine;
}

class Member {
  const Member({required this.userId, required this.name, required this.role, this.since});
  final String userId;
  final String name;

  /// owner, admin, member
  final String role;

  /// When they joined here (a rename restarts it); null = unknown.
  final DateTime? since;
}

class Person {
  const Person({required this.userId, required this.name, this.roomId});
  final String userId;
  final String name;
  final String? roomId;
}

class DeviceRow {
  const DeviceRow({required this.id, required this.name, required this.lastSeen, required this.thisDevice, required this.verified});
  final String id;
  final String name;
  final DateTime? lastSeen;
  final bool thisDevice;
  final bool verified;
}

/// One group or channel inside a community.
class CommunityChat {
  const CommunityChat({required this.roomId, required this.name, this.channel = false, this.state = 'in', this.hidden = false, this.by = '', this.members = 0});
  final String roomId;
  final String name;
  final bool channel;

  /// "in" (I am a member), "view" (open: one tap joins) or "ask" (an admin
  /// lets me in).
  final String state;

  /// Hidden by the admins: only admins see it here.
  final bool hidden;

  /// Who added it.
  final String by;

  /// Members when it was added (0 = unknown).
  final int members;
}

/// 커뮤니티: several groups and channels together. The server never sees
/// which chats are in it or what it is called (sealed with a community key).
class Community {
  const Community({required this.id, required this.name, this.about = '', this.role = 'member', this.addAll = false, this.members = 0, this.chats = const []});
  final String id;
  final String name;
  final String about;

  /// "owner", "admin" or "member".
  final String role;
  bool get admin => role != 'member';

  /// Every member may add their own groups and channels (else admins only).
  final bool addAll;
  final int members;
  final List<CommunityChat> chats;

  /// What I may see: members never see hidden chats.
  List<CommunityChat> get visible => [
    for (final c in chats)
      if (!c.hidden || admin) c,
  ];
}

abstract class Backend {
  /// The time now (the look-only demo keeps its own fixed clock).
  DateTime get clock;

  String? get userId;
  bool get loggedIn;

  Future<void> register({required String id, required String password, String? invite});
  Future<void> login({required String id, required String password});
  Future<void> logout();

  /// Erases every chat of this account from this phone (wrong-try limit,
  /// or the account password for another account).
  Future<void> eraseEverything();

  /// Waits for anything new (live updates).
  Future<void> sync({Duration wait});
  Future<List<ChatPreview>> chats();
  Future<List<Msg>> timeline(String roomId, {int limit});

  /// Messages already on this phone, without asking the server (the chat
  /// list's unseen @ and ♥ marks, tips 249/320).
  Future<List<Msg>> cachedMessages(String roomId);
  Future<void> sendText(String roomId, String text);

  /// Sends without a notification sound on the other phones.
  Future<void> sendTextQuietly(String roomId, String text);

  /// [idKey]: the 아이디 키 the other person gave me ('' = none); only a
  /// proof made from it travels (see core/id_key.dart).
  Future<String> createDirectChat(String userId, {String idKey = ''});
  Future<String> makeRecoveryKey();
  Future<bool> hasRecovery();
  Future<void> recover(String key);

  Future<List<Person>> contacts();
  Future<List<Person>> searchPeople(String term);
  Future<void> markRead(String roomId);

  /// My messages sent at or before this time have been read.
  Future<DateTime?> readUntil(String roomId);

  /// (read up to, when they read it); nulls when read ticks aren't shared
  /// both ways (1:1 read time, tip 421).
  Future<(DateTime?, DateTime?)> readReceipt(String roomId);

  /// [caption]: words shown under the photo, video or file.
  /// [captionAbove]: the words show above the photo or video (tip 452).
  Future<void> sendFile(String roomId, {required String name, required String mime, required List<int> bytes, String caption = '', bool captionAbove = false});

  /// Edits my photo, video or file message (tips 452 B, 482, 81, 224): its
  /// words, above or under, and with [name]/[mime]/[bytes] a new file in its
  /// place (a text message gets a photo this way; the text becomes its
  /// words). Swaps are refused in public groups and channels.
  Future<void> editMedia(String roomId, String id, {required String caption, bool captionAbove = false, String? name, String? mime, List<int>? bytes});
  Future<List<int>> downloadFile(String roomId, String eventId);

  /// Same, and [cache] keeps a copy in this device's encrypted store
  /// (auto-download; Settings > Data decides how long it stays).
  Future<List<int>> downloadFileCached(String roomId, String eventId, {bool cache = true});

  /// Stops a running [downloadFileCached] (true = one was running).
  Future<bool> cancelDownload(String eventId);

  /// Drops the kept copy of one file.
  Future<void> forgetFile(String roomId, String eventId);

  /// Biggest file worth keeping and how long kept copies stay (null = no limit).
  Future<void> setMediaKeep({int? maxFile, Duration? keep});

  /// New group or channel (channel: only I post). Returns the chat id.
  Future<String> createGroup(String name, List<String> members, {bool channel = false});
  Future<bool> canPost(String roomId);
  Future<bool> isChannel(String roomId);
  Future<void> reply(String roomId, String toId, String text);

  /// Text or reply ([replyTo]) with the sender's link card set-up (tips 400
  /// + 401). [quiet] = no sound on the other phones.
  Future<void> sendTextLink(String roomId, String text, LinkChoice link, {String? replyTo, bool quiet = false});

  /// 부분 인용 답장 (tip 399): a reply showing only [quote] of [toId]. With
  /// [toId] empty: "다른 대화에서 답장" — [quote] and [quoteName] are copied
  /// in (the original lives in another chat), encrypted like any message.
  Future<void> replyQuote(String roomId, String toId, String text, {required String quote, String quoteName = ''});

  /// "스레드로 답장": a text inside the thread that starts at [rootId].
  Future<void> replyInThread(String roomId, String rootId, String text);
  Future<void> edit(String roomId, String id, String text);
  Future<void> deleteMessage(String roomId, String id);
  Future<void> setTyping(String roomId, bool typing);

  /// Other people typing in this chat now.
  List<String> typingUsers(String roomId);

  // App lock with three passwords (normal / hide / delete).
  Future<bool> lockIsSet();

  /// Returns "normal", "hide", "delete", or null when wrong.
  Future<String?> unlock(String password);

  /// First password, or a new normal one (old needed when one is set).
  Future<void> setNormalPassword(String password, {String? old});

  /// role = "hide" or "delete"; password null removes it.
  Future<void> setExtraPassword(String normal, String role, String? password);

  /// [hide set, delete set].
  Future<List<bool>> extrasSet(String normal);

  /// Wrong tries in a row.
  Future<int> lockFails();

  /// Wrong tries that erase every chat (5 or 10). Reaching it inside
  /// [unlock] erases everything before it returns.
  Future<int> wipeAfter();
  Future<void> setWipeAfter(String normal, int n);

  /// Deletes a 1:1 chat on both phones.
  Future<void> deleteForBoth(String roomId);

  /// Friends (user ids) who deleted a 1:1 chat for both; told once.
  Future<List<String>> takeEraseNotices();

  // 내 기기끼리 (Telegram tips 241 + 329).

  /// 임시 글 이어쓰기: my draft for [roomId] (empty = sent or cleared) to my
  /// other devices, end-to-end encrypted. False when this is my only one.
  Future<bool> sendMyDraft(String roomId, String text, DateTime at);

  /// Drafts my other devices sent since the last call (newest per chat).
  Future<List<SyncedDraft>> takeSyncedDrafts();

  /// Small data kept in the encrypted store on this device (내 알림음).
  Future<void> saveBlob(String name, List<int> data);
  Future<List<int>?> blob(String name);
  Future<void> dropBlob(String name);

  Future<void> startSession(String role);
  String get sessionRole;

  /// [hide list, delete list] of user ids / chat ids.
  Future<List<List<String>>> quietLists();
  Future<void> setQuietLists(List<String> hide, List<String> delete);

  /// Emoji check with another person (암호화 page). States: "incoming",
  /// "waiting", "starting", "emoji", "confirmed", "done", "cancelled", "gone".
  Future<String> requestVerification(String userId);
  Future<void> acceptVerification(String userId, String flowId);
  Future<String> verifyState(String userId, String flowId);

  /// The 7 emoji ("🐶 Dog" …) once both phones are ready.
  Future<List<String>?> sasEmoji(String userId, String flowId);
  Future<void> confirmSas(String userId, String flowId);
  Future<void> cancelVerification(String userId, String flowId);
  Future<bool> isUserVerified(String userId);

  /// [device id, name, key, "1" if checked] for each of their devices.
  Future<List<PeerDevice>> peerDevices(String userId);

  /// One message marked for the delete password ("비상 시 삭제"): mine are
  /// deleted for everyone, other people's vanish from this device.
  Future<void> markForDelete(String roomId, String id, bool on);

  /// "메시지 신고": the reason and the reported words go to our operators.
  Future<void> reportMessage(String roomId, String id, String reason, String shown);
  Future<List<String>> markedMessages(String roomId);

  /// One message marked for the hide password ("이 메시지 비상 시 숨김"):
  /// out of sight while hiding is on, like hidden chats.
  Future<void> markForHide(String roomId, String id, bool on);
  Future<List<String>> hideMarkedMessages(String roomId);
  Future<bool> hideActive();
  Future<void> releaseHidden();
  Future<String?> runDueLeaves();

  // Streaks (worked out on the phone; can be switched off).
  Future<bool> streaksEnabled();
  Future<void> setStreaksEnabled(bool on);

  /// Bubble for a friend's home screen: kind "emoji" (bytes = the emoji
  /// text), "photo" or "voice". 1:1 chats only.
  Future<void> sendBubble(String roomId, String kind, String mime, List<int> bytes);

  /// Bubbles waiting for me, newest first (no content).
  Future<List<BubbleRef>> pendingBubbles();

  /// Instagram-style story to every 1:1 friend for 24 hours (encrypted in
  /// each chat; no record of who watched). Returns how many friends.
  /// To all 1:1 friends, or only the chats in [only]; [hours] 6/12/24/48;
  /// [extra] = live parts (poll, question, plan) as JSON.
  Future<int> postStory({required String mime, required List<int> bytes, String caption = '', List<String> only = const [], int hours = 24, String extra = ''});

  /// One upload, several stories: tip 525 (a long video in parts, each
  /// part's start / end in its [extras] entry). [room] '' = to my 1:1
  /// friends; else a group's or channel's story (admins only, tip 428).
  /// [room] '${memberStoryPrefix}!id' = my own story for that group's
  /// members only (any member, groups only; 4-app board).
  Future<StoryPosted> postStories({
    required String mime,
    required List<int> bytes,
    String caption = '',
    List<String> only = const [],
    int hours = 24,
    List<String> extras = const [],
    String room = '',
  });

  /// Changes a story I posted (tip 393): words, live parts, who sees it,
  /// or the picture itself ([bytes] empty keeps it); keeps it on my
  /// profile with [pin] JSON (null = not kept, tips 392 / 468 / 534).
  /// Returns how many chats have it now.
  Future<int> editStory(
    String id, {
    String mime = '',
    List<int> bytes = const [],
    String caption = '',
    String extra = '',
    List<String> only = const [],
    String? pin,
  });

  /// Stories (and feed posts, [Story.feed]) I can see now, oldest first.
  /// postStory with hours 0 is a feed post; mime '' = words only.
  Future<List<Story>> stories();

  /// Like (or take back) a friend's feed post: told only to them, in our 1:1 chat.
  Future<void> feedLike(String roomId, String postId, {bool on = true});

  /// Likes in my 1:1 chats (each person's last word per post).
  Future<List<FeedLike>> feedLikes();

  /// Deletes my story or feed post from every chat it went to.
  Future<void> deleteStory(String id);

  // Phone notifications. The push only wakes the app; the text is opened
  // here on the phone. Muted and hidden chats never notify.
  Future<void> setPush(String gatewayUrl, String pushKey, String appId);
  Future<List<Notice>> notifications({int max = 5});
  Future<bool> noticeTextHidden();

  /// A call while I talk: "wait" (call waiting), "missed" or "busy".
  Future<String> callWaiting();
  Future<void> setCallWaiting(String mode);
  Future<void> setNoticeTextHidden(bool on);

  // Calls. Ringing/answer/hang-up are small encrypted chat events; sound
  // and picture are end-to-end encrypted with a key from the invite.
  Future<String> startCall(String roomId, {required bool video});
  Future<void> answerCall(String roomId, String callId);

  /// reason: end, decline, busy
  Future<void> hangupCall(String roomId, String callId, String reason);
  Future<String> callState(String roomId, String callId);
  Future<List<RingingCall>> ringingCalls();
  Future<CallTicket> callTicket(String roomId, String callId);

  // Polls. Anonymous votes go only to the maker's phone; channels are
  // always anonymous.
  /// [quiz] = index of the right answer; [closeAt] = voting deadline.
  Future<void> createPoll(
    String roomId,
    String question,
    List<String> options, {
    required bool anonymous,
    required bool multiple,
    int? quiz,
    String explain = '',
    DateTime? closeAt,
    PollExtras extras = const PollExtras(),
  });
  Future<void> vote(String roomId, String pollId, List<String> choices);
  Future<void> closePoll(String roomId, String pollId);

  /// A member adds an answer (only when the poll allows it).
  Future<void> addPollOption(String roomId, String pollId, String text);

  /// A poll's photo, decrypted: [slot] '' = under the question, else an answer id.
  Future<List<int>> pollPhoto(String roomId, String pollId, String slot);

  // Cards (channel/group tools). Answers go to the maker's phone only.
  Future<void> createCard(String roomId, String kind, Map<String, Object?> data);

  /// [answer] null takes mine back.
  Future<void> answerCard(String roomId, String cardId, Object? answer);

  /// Maker only.
  Future<List<CardAnswer>> cardAnswers(String roomId, String cardId);

  /// Maker only; a giveaway draws and returns its winners.
  Future<List<String>> closeCard(String roomId, String cardId);

  // Long posts / formatted messages (core/doc.dart). A short document goes
  // inside the encrypted card; a long one is uploaded as an encrypted file.
  /// Encrypts bytes on this phone and uploads them (a post's photo); returns
  /// the file reference JSON that goes inside the document.
  Future<String> uploadEncrypted(List<int> bytes);

  /// Downloads and decrypts a file reference from inside a document.
  Future<List<int>> downloadEncrypted(String fileJson);

  /// Sends a document (photos already uploaded); returns the message id.
  Future<String> sendArticle(String roomId, Map<String, Object?> doc);

  /// The whole document of a post (downloaded if long), checked again.
  Future<Map<String, Object?>> openArticle(String roomId, String eventId);

  // Checklists (encrypted like messages). Ticks and added items from people
  // the maker did not allow are ignored on every phone.
  Future<void> createChecklist(String roomId, String title, List<String> items, {required bool othersMark, required bool othersAdd});
  Future<void> markChecklist(String roomId, String checklistId, String itemId, bool done);
  Future<void> addChecklistItem(String roomId, String checklistId, String text);

  // Plans: answers "yes" / "no" / "maybe" ("" takes mine back).
  /// Returns the new plan's message id.
  Future<String> createMeetup(String roomId, String title, DateTime startsAt, String place, {DateTime? endsAt});
  Future<void> answerMeetup(String roomId, String meetupId, String answer);
  Future<void> cancelMeetup(String roomId, String meetupId);

  /// Shares a contact card (their ID and the name I know them by).
  Future<void> sendContact(String roomId, String userId, String name);

  /// One point where I am (encrypted; no address or map picture is sent).
  Future<void> sendLocation(String roomId, double lat, double lon, double? accuracy);

  /// 실시간 위치 (v1): a location my phone keeps moving until [until].
  /// Returns the message ID.
  Future<String> sendLiveLocation(String roomId, double lat, double lon, double? accuracy, DateTime until);

  /// Moves my live location; [until] = now ends it.
  Future<void> updateLiveLocation(String roomId, String messageId, double lat, double lon, double? accuracy, DateTime until);

  // Group / channel tools (admins; the server checks the rights too).
  Future<void> setRoomName(String roomId, String name);
  Future<String> roomAbout(String roomId);
  Future<void> setRoomAbout(String roomId, String text);
  Future<void> inviteUsers(String roomId, List<String> userIds);
  Future<void> removeMember(String roomId, String userId);
  Future<void> setAdmin(String roomId, String userId, bool admin);

  /// Power level: -1 muted (the server refuses their messages), 0 member,
  /// 50 admin, 100 owner. For myself only a step down.
  Future<void> setMemberLevel(String roomId, String userId, int level);

  /// "sign" (channel posts show who wrote them) or "hide_members".
  Future<bool> roomSwitch(String roomId, String key);
  Future<void> setRoomSwitch(String roomId, String key, bool on);

  /// Group/channel tool settings (rules, welcome, reactions...), a JSON
  /// object kept in the room for its members.
  Future<Map<String, dynamic>> roomConfig(String roomId);

  /// Changes one setting; null removes it. Admins only.
  Future<void> setRoomConfig(String roomId, String key, Object? value);

  // Invite links: public address or private code, approval, web page.
  Future<RoomLink> roomLink(String roomId);
  Future<bool> addressFree(String roomId, String address);
  Future<RoomLink> setPublicLink(String roomId, String address);

  /// A new secret code; the old link stops working.
  Future<RoomLink> newPrivateLink(String roomId);
  Future<void> setLinkApproval(String roomId, bool on);
  Future<LinkPeek> peekAddress(String address);

  /// Comes in by a link ("public" + address, "private" + code). Returns the
  /// room, and true when it only asked (approval on).
  Future<(String, bool)> joinLink(String kind, String code);

  // 초대 링크 여러 개 (tip 253): extra private links next to the main one,
  // each with a name, an end time and a people limit our server keeps.
  Future<List<InviteLink>> inviteLinks(String roomId);
  Future<InviteLink> makeInviteLink(String roomId, {String name = '', DateTime? until, int max = 0});
  Future<InviteLink> editInviteLink(String roomId, String code, {String name = '', DateTime? until, int max = 0});

  /// Stops it at once; it stays in the list as 취소됨.
  Future<void> revokeInviteLink(String roomId, String code);

  /// 되돌리기 right after 취소.
  Future<void> restoreInviteLink(String roomId, String code);
  Future<void> deleteInviteLink(String roomId, String code);

  /// The main private link's count: (people, who came in, newest last).
  Future<(int, List<String>)> mainLinkUses(String roomId);
  Future<List<JoinRequest>> joinRequests(String roomId);
  Future<void> answerJoinRequest(String roomId, String userId, bool accept);

  // 가입 심사 도우미 (join helper, see core/join_gate.dart). The room's
  // questions and helper switches are room config keys `join_questions`
  // and `gate` (roomConfig / setRoomConfig).

  /// The questions a link's room asks before a join request (right answers
  /// left out); null when its helper is not on or there are none.
  Future<List<GateQuestion>?> gateQuestions(String kind, String code);

  /// Right / wrong per quiz question (null for written ones), checked by
  /// the helper so the person sees it at once and can try again.
  Future<List<bool?>> gateCheck(String kind, String code, List<String> answers);

  /// [joinLink] sending answers with the request.
  Future<(String, bool)> joinLinkWith(String kind, String code, List<String> answers);

  /// After asking: "in" (let in and joined), "no", "waiting" or "unknown".
  Future<String> knockState(String roomId);

  /// Helper in / out (admins). Write `gate.on` in the room config first.
  Future<void> setGateHelper(String roomId, bool on);
  Future<GateHelper> gateHelper(String roomId);

  /// The helper's decisions, newest first.
  Future<List<GateEntry>> gateLog(String roomId);

  // 커뮤니티 (several groups and channels together).
  Future<List<Community>> communities();

  /// A new community; I am its owner. Returns its id.
  Future<String> createCommunity(String name, {String about = ''});
  Future<void> setCommunityInfo(String id, String name, String about);

  /// Adds one of my groups or channels (I must be its owner or admin). A
  /// chat without a link gets a private link with approval.
  Future<void> addToCommunity(String id, String roomId, {bool hidden = false});
  Future<void> removeFromCommunity(String id, String roomId);
  Future<void> setCommunityChatHidden(String id, String roomId, bool hidden);

  /// Every member may add chats ([all]) or only admins.
  Future<void> setCommunityAddAll(String id, bool all);
  Future<void> setCommunityAdmin(String id, String userId, bool on);

  /// Comes into a chat of the community: (chat id, true when it only asked).
  Future<(String, bool)> joinCommunityChat(String id, String roomId);
  Future<void> leaveCommunity(String id);
  Future<void> deleteCommunity(String id);

  /// Public channel web page (owner). New posts are copied there while on.
  Future<void> setWebPage(String roomId, bool on);

  /// Ban someone (can't come back) or lift it; and who is banned.
  Future<void> setBanned(String roomId, String userId, bool banned);
  Future<List<String>> banned(String roomId);

  /// "owner", "admin" or "member".
  Future<String> myRole(String roomId);

  /// Recorded voice message (encrypted on this phone before upload).
  Future<void> sendVoice(String roomId, String mime, List<int> bytes, Duration duration, List<int> waveform);

  // Link previews: made on my phone when I send; can be switched off.
  Future<bool> linkPreviewsEnabled();
  Future<void> setLinkPreviewsEnabled(bool on);
  Future<List<int>> previewImage(String roomId, String eventId);

  /// Story link sticker: my phone reads the page (null: none, previews
  /// switched off, or the browser, which can't read other sites).
  Future<StoryLinkInfo?> storyLinkCard(String url);

  /// Passes a message on to another chat (not view-once photos).
  Future<void> forward(String fromRoom, String id, String toRoom);

  /// Messages containing the words, newest first; searched on this phone.
  Future<List<Msg>> searchMessages(String roomId, String term);

  // 전체 검색 (core/search.dart).

  /// Messages of every chat (not hidden ones), newest first, looked up on
  /// this phone only. [kind]: "text", "media", "link", "file", "music" or
  /// "voice" ([term] may be empty for all but "text").
  Future<List<Found>> searchEverywhere(String term, {String kind = 'text', int limit = 300});

  /// Public groups and channels with these words (the server's public
  /// list); [channelsOnly] keeps channels.
  Future<List<LinkPeek>> searchPublicRooms(String term, {bool channelsOnly = false});

  /// Posts on public channels' web pages with these words (공개 글).
  Future<List<PublicPost>> searchPublicPosts(String term);

  // Chat list order: pin on top, archive, mute alerts.
  Future<void> setChatPinned(String roomId, bool on);
  Future<void> setChatArchived(String roomId, bool on);
  Future<void> setChatMuted(String roomId, bool on);

  /// One of the built-in stickers (id like "buru_01_hello").
  Future<void> sendSticker(String roomId, String stickerId);

  /// Emoji under a message; take mine back with [deleteMessage].
  Future<void> react(String roomId, String id, String key);
  Future<void> pin(String roomId, String id, bool pinned);
  List<String> pinned(String roomId);

  /// Chat timer in seconds for everyone in the chat (0 = off).
  Future<void> setTimer(String roomId, int seconds);
  Future<int> timer(String roomId);

  /// Deletes my own messages whose time is up.
  Future<int> runExpiry();

  Future<void> sendViewOnce(String roomId, {required String name, required String mime, required List<int> bytes});

  /// 움직이는 사진: the still photo plus its short clip, both encrypted on
  /// this phone (place and phone details removed from both first).
  /// [style]: "live" (plays once), "loop" or "bounce".
  Future<void> sendLivePhoto(
    String roomId, {
    required String name,
    required String mime,
    required List<int> bytes,
    required String videoMime,
    required List<int> video,
    required Duration duration,
    required String style,
    String caption = '',
  });

  /// The (decrypted) clip of a 움직이는 사진.
  Future<List<int>> liveVideo(String roomId, String eventId);

  /// The photo's bytes, one time only.
  Future<List<int>> openViewOnce(String roomId, String id);

  Future<String> myName();
  Future<void> setMyName(String name);

  /// 이모지 상태 (tip 359): my emoji goes end-to-end encrypted into each
  /// friend's 1:1 chat ('' = take it off). [until] null = until I change
  /// it. Returns how many chats got it.
  Future<int> setEmojiStatus(String emoji, DateTime? until);

  /// Someone's emoji status from our 1:1 chat, or null.
  Future<EmojiStatus?> emojiStatusOf(String userId);

  /// About me (자기소개); everyone who knows my ID can read it.
  Future<void> setMyBio(String text);
  Future<String> bioOf(String userId);
  Future<List<int>?> myPhoto();
  Future<void> setMyPhoto(String mime, List<int> bytes);

  /// Shares my photo, about-me and birthday. [who*]: everyone (also on the
  /// public profile), contacts (only inside each 1:1 chat's encryption) or
  /// nobody. [only]: just these chats (new friends). How many got it.
  Future<int> shareProfile({
    required String mime,
    required List<int> photo,
    required String bio,
    required String birthday,
    required String whoPhoto,
    required String whoBio,
    required String whoBirthday,
    List<String> only = const [],
  });

  /// Someone's photo, about-me and birthday as I may see them.
  Future<ProfileCard> profileOf(String userId);
  Future<List<Member>> members(String roomId);
  Future<void> leave(String roomId);

  Future<List<Invite>> invitations();

  /// 새 멤버에게 지난 메시지 보내기: the last [count] (≤50) messages of this
  /// chat go end-to-end encrypted to [userId]'s phones only. Returns how many.
  Future<int> sendHistory(String roomId, String userId, {int count = 50});

  /// 다른 앱 대화 가져오기: the checked messages of import card [cardId]
  /// (downloaded and decrypted once, then kept on this phone).
  Future<ImportedChat> importedMessages(String roomId, String cardId);

  /// Messages from before I joined that a member sent me (oldest first).
  Future<List<Msg>> earlierMessages(String roomId);

  /// The photo / video / file of earlier message [index] (its small
  /// picture when [thumb] and there is one), decrypted on this phone.
  Future<List<int>> earlierFile(String roomId, int index, {bool thumb = false});

  /// Call history, newest first.
  Future<List<CallLogItem>> callLog({int max = 200});

  /// On-device settings by name (switches are "1"/"0").
  Future<Map<String, String>> settings();
  Future<void> setSetting(String key, String value);

  /// People I blocked, and blocking/unblocking one.
  Future<List<String>> blocked();
  Future<void> block(String userId, bool on);

  /// My logged-in devices (this one first).
  Future<List<DeviceRow>> devices();
  Future<void> logOutDevices(List<String> ids, String password);
  Future<void> changePassword(String old, String newPassword);

  /// [identity key, this device's key].
  Future<List<String>> myKeys();
  Future<bool> thisDeviceVerified();

  /// My "saved messages" chat (made when [create] and missing).
  // ---- 사칭 막기 (trust service; nothing here carries messages) ----

  /// Official badges and '확인 중' / '가짜' labels: the whole public list.
  Future<TrustList> trustList();

  /// Rough account age and recent rename, for the first-chat card.
  Future<TrustAbout> trustAbout(String userId);

  /// Tells the trust service my current name (first-seen + rename date).
  /// [photo]: a short fingerprint of my profile photo (514: the card says
  /// "사진 바뀜 N일 전"); never the photo itself.
  Future<void> trustSeen(String name, {String photo = ''});

  /// Can this ID (or display name, or channel title with [room]) be used?
  /// '' = yes, else "reserved" (our own words), "reserved_owner" (held for
  /// its verified owner: companies, famous people, places …),
  /// "reserved_sale" (short IDs and popular words), "lookalike" or "mark".
  Future<String> nameCheck(String text, {bool displayName = false, bool room = false});

  /// Sign-up with a reserved ID: the code the operator sent its real owner
  /// (or buyer). Opens that one ID for 15 minutes; throws on a wrong code.
  Future<void> claimOpen(String id, String code);

  /// Starts a badge application: the code to post on my official page.
  Future<String> badgeCode();

  /// Sends the application (kind person/brand/channel, where the code is).
  Future<void> applyBadge({required String kind, required String name, required String proof});

  /// Reports an account that pretends to be [victim]. Returns its label
  /// after the report ('' or "checking").
  Future<String> reportImpersonation(String userId, {String victim = '', String note = ''});

  /// 협박 공격 막기: a message reported as illegal ("illegal": several
  /// reports hide it in every app at once) or a blackmail report against
  /// [sender] ("extortion", [id] may be ''). Returns true when the message
  /// is now hidden everywhere.
  Future<bool> reportContent(String roomId, String id, String sender, String reason, String note);

  Future<String?> savedRoom({bool create = false});

  /// "아이디 검색 막기": strangers can't find me by ID or name (server rule).
  Future<void> setIdSearchHidden(bool on);

  /// My privacy settings kept in my account (all my devices and our server
  /// read them): device_idle_days, no_call_devices, no_id_search.
  Future<Map<String, dynamic>> accountPrivacy();

  /// Changes one of them (null removes it).
  Future<void> setAccountPrivacy(String key, Object? value);

  // ---- QR로 PC 연결 (tips 78 + 311) ----

  /// The QR sign-in service is set up in this build.
  bool get pcLinkReady;

  /// Phone: vouch for the PC whose QR holds [rid] (sha256 of its secret).
  Future<void> approvePcLogin(String rid);

  /// PC (signed out): signs in when my phone vouched for [secret]'s QR.
  /// False = not yet.
  Future<bool> takePcLogin(String secret);

  /// 방마다 다른 이름 / 이름 색 (v1): my name and name colour in one room.
  /// null keeps a value; an empty name goes back to my usual name; an empty
  /// colour removes it.
  Future<void> setMyRoomLook(String roomId, {String? name, String? color});

  /// 멤버 태그 (tip 556): my own tag in this room ("" removes it). Shown
  /// when the room lets members tag themselves.
  Future<void> setMyRoomTag(String roomId, String tag);

  /// Tags people put on themselves here (user id -> tag).
  Future<Map<String, String>> memberTags(String roomId);

  /// 누가 읽었는지 (tip 384): each other member's newest read receipt as
  /// (read up to, when). Empty for groups over 100 people, or when I hide
  /// my own read ticks (then I don't see anyone's either).
  Future<Map<String, (DateTime, DateTime)>> groupReceipts(String roomId);

  /// 그룹·채널 사진 (v1): admins set it; [bytes] null removes it. The photo
  /// travels end-to-end encrypted inside the room; a public room also gets a
  /// plain copy so its link card can show it.
  Future<void> setRoomPhoto(String roomId, String mime, Uint8List? bytes);

  /// The room's photo, or null when it has none.
  Future<Uint8List?> roomPhoto(String roomId);

  /// Admin's phone: re-sends the photo so people who joined later can open
  /// it. True when it sent one.
  Future<bool> reshareRoomPhoto(String roomId);

  /// Name colours people picked in this room, by user ID.
  Future<Map<String, String>> nameColors(String roomId);
  Future<void> join(String roomId);
  Future<void> decline(String roomId);

  /// Turns down a group/channel invitation because only contacts may add
  /// me; the room's admins can then send me its link instead (tip 385).
  Future<void> declineBlocked(String roomId);

  /// People who turned down this room's invitation that way.
  Future<List<String>> invitesBlocked(String roomId);

  /// 보내는 이름 (tips 472 + 310): my next messages in this chat go out as
  /// [as] (null = as myself). Kept on this phone.
  void setSendAs(String roomId, PostAs? as);

  /// 310: is [userId] really an owner or admin of the public channel
  /// [channel]? Asked only for someone who shares [inRoom] with me.
  Future<bool> checkSendAs(String channel, String userId, String inRoom);

  /// 정지 (server rule 13): is my account paused, why, and where my 이의
  /// 신청 is. Null when the server can't be asked.
  Future<Suspension?> suspension();

  /// 이의 신청: one note to the operator while paused. Throws with the
  /// server's reason when it is refused.
  Future<void> appeal(String text);

  /// Sends a hidden end-to-end encrypted note to the phones in a chat
  /// (never shown as a message). [kind]: a-z, 0-9, _ (1-32).
  Future<void> sendSignal(String roomId, String kind, Map<String, dynamic> data);

  /// 주제 (tip 527): messages I send into [roomId] from now on carry
  /// [topic] inside their encryption; null or "g" = 일반.
  void setSendTopic(String roomId, String? topic);

  /// Hidden notes from others that arrived since the last call.
  List<Signal> takeSignals();

  /// Encrypts bytes on this phone and uploads them (the server keeps only
  /// ciphertext); returns the key + address (JSON) to send inside a signal.
  Future<String> uploadSecret(List<int> bytes);

  /// Downloads and decrypts a file from [uploadSecret].
  Future<List<int>> downloadSecret(String file);
}

/// A hidden note from another phone (see [Backend.sendSignal]).
class Signal {
  const Signal({required this.roomId, required this.id, required this.sender, required this.kind, required this.data, required this.time});
  final String roomId;
  final String id;
  final String sender;
  final String kind;
  final Map<String, dynamic> data;
  final DateTime time;
}

class PeerDevice {
  const PeerDevice({required this.id, required this.name, required this.key, required this.verified});
  final String id;
  final String name;
  final String key;
  final bool verified;
}

/// Someone's photo, about-me and birthday ("MM-DD"), as I may see them.
/// An emoji beside a name, maybe until a time (tip 359).
class EmojiStatus {
  const EmojiStatus(this.emoji, [this.until]);
  final String emoji;
  final DateTime? until;

  bool liveAt(DateTime now) => emoji.isNotEmpty && (until == null || now.isBefore(until!));
}

class ProfileCard {
  const ProfileCard({this.photo, this.bio = '', this.birthday = '', this.private = false});
  final List<int>? photo;
  final String bio;
  final String birthday;

  /// From our encrypted 1:1 chat (not the public profile).
  final bool private;
}

/// My account's pause (server rule 13, 검수 2026-11-28).
class Suspension {
  const Suspension({this.suspended = false, this.until, this.reason = '', this.appeal = 'none', this.againAt});
  final bool suspended;

  /// When it ends by itself; null = until the operator lifts it.
  final DateTime? until;

  /// 'other_edit' (tried to edit someone else's message) or 'modified_app'.
  final String reason;

  /// 'none', 'waiting' (sent, not answered yet) or 'denied'.
  final String appeal;

  /// After a "no": when I may ask again.
  final DateTime? againAt;

  static const appealMax = 1000;

  factory Suspension.fromJson(Map<String, dynamic> j) {
    DateTime? at(Object? v) => v is int && v > 0 ? DateTime.fromMillisecondsSinceEpoch(v) : null;
    return Suspension(
      suspended: j['suspended'] == true,
      until: at(j['until']),
      reason: j['reason'] as String? ?? '',
      appeal: j['appeal'] as String? ?? 'none',
      againAt: at(j['appeal_again_at']),
    );
  }
}
