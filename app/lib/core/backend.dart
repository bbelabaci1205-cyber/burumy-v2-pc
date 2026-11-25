// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// What the screens need from the engine. Screens only talk to this, so they
// can be tested without a server and the engine can change underneath.

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

class Msg {
  const Msg({
    required this.id,
    required this.sender,
    required this.body,
    required this.time,
    required this.mine,
    required this.kind,
    this.replyTo,
    this.threadRoot,
    this.edited = false,
    this.reactions = const [],
    this.expiresAt,
    this.viewOnce = false,
    this.opened = false,
    this.forwarded = false,
    this.preview,
    this.voice,
    this.poll,
    this.bubble = false,
    this.call,
    this.caption,
    this.checklist,
    this.meetup,
    this.contact,
    this.card,
  });
  final String id;
  final String sender;

  /// null = not opened yet (key missing).
  final String? body;
  final DateTime time;
  final bool mine;

  /// text, image, video, audio, file, locked
  final String kind;

  /// Id of the message this one answers.
  final String? replyTo;

  /// First message of the thread this one is in ("스레드로 답장").
  final String? threadRoot;
  final bool edited;
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

  /// Same message with a few things changed (everything else kept).
  Msg copyWith({
    String? body,
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
    threadRoot: threadRoot,
    edited: edited ?? this.edited,
    reactions: reactions ?? this.reactions,
    expiresAt: expiresAt,
    viewOnce: viewOnce,
    opened: opened ?? this.opened,
    forwarded: forwarded,
    preview: preview,
    voice: voice,
    poll: poll ?? this.poll,
    bubble: bubble,
    call: call ?? this.call,
    caption: caption,
    checklist: checklist ?? this.checklist,
    meetup: meetup ?? this.meetup,
    contact: contact,
    card: card ?? this.card,
  );
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
  });
  final String id;
  final String roomId;
  final String eventId;
  final String sender;
  final bool mine;
  final DateTime time;

  /// "image" or "video" ("text" only for a feed post).
  final String kind;

  /// A friend-feed post (kept until deleted), not a 24-hour story.
  final bool feed;
  final String? caption;

  /// Poll / question / plan parts (JSON), drawn live by the viewer.
  final String? extra;
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
    this.place,
    this.cancelled = false,
    this.yes = const [],
    this.no = const [],
    this.maybe = const [],
  });
  final String title;
  final DateTime startsAt;
  final String? place;
  final bool cancelled;
  final List<String> yes;
  final List<String> no;
  final List<String> maybe;

  /// My answer: "yes", "no", "maybe" or "".
  String answerOf(String? me) => yes.contains(me) ? 'yes' : (no.contains(me) ? 'no' : (maybe.contains(me) ? 'maybe' : ''));
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

  /// faq, guide, links, rich, lottery, form, checkin
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
  static bool answered(String kind) => const ['lottery', 'form', 'checkin'].contains(kind);

  List<Map<String, Object?>> listOf(String key) => [
    for (final x in (data[key] is List ? data[key] as List : const []))
      if (x is Map) x.cast<String, Object?>(),
  ];
  String text(String key) => data[key] is String ? data[key] as String : '';
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
  });
  final String question;
  final List<PollOption> options;

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
  const PollOption(this.id, this.text, this.votes, [this.who = const []]);
  final String id;
  final String text;
  final int votes;

  /// Open polls only: who chose it.
  final List<String> who;
}

class VoiceInfo {
  const VoiceInfo(this.duration, this.waveform);
  final Duration duration;
  final List<int> waveform;
}

class LinkCard {
  const LinkCard({required this.url, required this.title, this.description, this.site, this.hasImage = false});
  final String url;
  final String title;
  final String? description;
  final String? site;
  final bool hasImage;
}

class Reaction {
  const Reaction(this.key, this.count, this.mine);
  final String key;
  final int count;

  /// My own reaction's id (to take it back), or null.
  final String? mine;
}

class Member {
  const Member({required this.userId, required this.name, required this.role});
  final String userId;
  final String name;

  /// owner, admin, member
  final String role;
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

abstract class Backend {
  String? get userId;
  bool get loggedIn;

  Future<void> register({required String id, required String password, String? invite});
  Future<void> login({required String id, required String password});
  Future<void> logout();

  /// Waits for anything new (live updates).
  Future<void> sync({Duration wait});
  Future<List<ChatPreview>> chats();
  Future<List<Msg>> timeline(String roomId, {int limit});
  Future<void> sendText(String roomId, String text);

  /// Sends without a notification sound on the other phones.
  Future<void> sendTextQuietly(String roomId, String text);
  Future<String> createDirectChat(String userId);
  Future<String> makeRecoveryKey();
  Future<bool> hasRecovery();
  Future<void> recover(String key);

  Future<List<Person>> contacts();
  Future<List<Person>> searchPeople(String term);
  Future<void> markRead(String roomId);

  /// My messages sent at or before this time have been read.
  Future<DateTime?> readUntil(String roomId);

  /// [caption]: words shown under the photo, video or file.
  Future<void> sendFile(String roomId, {required String name, required String mime, required List<int> bytes, String caption = ''});
  Future<List<int>> downloadFile(String roomId, String eventId);

  /// New group or channel (channel: only I post). Returns the chat id.
  Future<String> createGroup(String name, List<String> members, {bool channel = false});
  Future<bool> canPost(String roomId);
  Future<bool> isChannel(String roomId);
  Future<void> reply(String roomId, String toId, String text);

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
  });
  Future<void> vote(String roomId, String pollId, List<String> choices);
  Future<void> closePoll(String roomId, String pollId);

  // Cards (channel/group tools). Answers go to the maker's phone only.
  Future<void> createCard(String roomId, String kind, Map<String, Object?> data);

  /// [answer] null takes mine back.
  Future<void> answerCard(String roomId, String cardId, Object? answer);

  /// Maker only.
  Future<List<CardAnswer>> cardAnswers(String roomId, String cardId);

  /// Maker only; a giveaway draws and returns its winners.
  Future<List<String>> closeCard(String roomId, String cardId);

  // Checklists (encrypted like messages). Ticks and added items from people
  // the maker did not allow are ignored on every phone.
  Future<void> createChecklist(String roomId, String title, List<String> items, {required bool othersMark, required bool othersAdd});
  Future<void> markChecklist(String roomId, String checklistId, String itemId, bool done);
  Future<void> addChecklistItem(String roomId, String checklistId, String text);

  // Plans: answers "yes" / "no" / "maybe" ("" takes mine back).
  Future<void> createMeetup(String roomId, String title, DateTime startsAt, String place);
  Future<void> answerMeetup(String roomId, String meetupId, String answer);
  Future<void> cancelMeetup(String roomId, String meetupId);

  /// Shares a contact card (their ID and the name I know them by).
  Future<void> sendContact(String roomId, String userId, String name);

  /// One point where I am (encrypted; no address or map picture is sent).
  Future<void> sendLocation(String roomId, double lat, double lon, double? accuracy);

  // Group / channel tools (admins; the server checks the rights too).
  Future<void> setRoomName(String roomId, String name);
  Future<String> roomAbout(String roomId);
  Future<void> setRoomAbout(String roomId, String text);
  Future<void> inviteUsers(String roomId, List<String> userIds);
  Future<void> removeMember(String roomId, String userId);
  Future<void> setAdmin(String roomId, String userId, bool admin);

  /// "sign" (channel posts show who wrote them) or "hide_members".
  Future<bool> roomSwitch(String roomId, String key);
  Future<void> setRoomSwitch(String roomId, String key, bool on);

  /// Group/channel tool settings (rules, welcome, reactions...), a JSON
  /// object kept in the room for its members.
  Future<Map<String, dynamic>> roomConfig(String roomId);

  /// Changes one setting; null removes it. Admins only.
  Future<void> setRoomConfig(String roomId, String key, Object? value);

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

  /// Passes a message on to another chat (not view-once photos).
  Future<void> forward(String fromRoom, String id, String toRoom);

  /// Messages containing the words, newest first; searched on this phone.
  Future<List<Msg>> searchMessages(String roomId, String term);

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

  /// The photo's bytes, one time only.
  Future<List<int>> openViewOnce(String roomId, String id);

  Future<String> myName();
  Future<void> setMyName(String name);

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
  Future<String?> savedRoom({bool create = false});
  Future<void> join(String roomId);
  Future<void> decline(String roomId);
}

class PeerDevice {
  const PeerDevice({required this.id, required this.name, required this.key, required this.verified});
  final String id;
  final String name;
  final String key;
  final bool verified;
}

/// Someone's photo, about-me and birthday ("MM-DD"), as I may see them.
class ProfileCard {
  const ProfileCard({this.photo, this.bio = '', this.birthday = '', this.private = false});
  final List<int>? photo;
  final String bio;
  final String birthday;

  /// From our encrypted 1:1 chat (not the public profile).
  final bool private;
}
