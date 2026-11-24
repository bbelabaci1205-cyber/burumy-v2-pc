// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// In-memory backend: screen tests and the look-only demo (no server).
import 'dart:async';

import 'package:burumy/core/backend.dart';

class FakeBackend implements Backend {
  String? _me;
  final rooms = <String, List<Msg>>{};
  final groups = <String>{};
  final channels = <String>{};
  final typing = <String, List<String>>{};
  int _n = 0;
  String _id() => 'e${_n++}';
  DateTime now = DateTime(2026, 11, 23, 20);
  final names = <String, String>{};
  final pinnedChats = <String>[];
  final archivedChats = <String>{};
  final mutedChats = <String>{};
  final unreadCounts = <String, int>{};

  @override
  String? get userId => _me;
  @override
  bool get loggedIn => _me != null;

  @override
  Future<void> register({required String id, required String password, String? invite}) async => _me = '@$id:test';
  @override
  Future<void> login({required String id, required String password}) async => _me = '@$id:test';
  @override
  Future<void> logout() async => _me = null;
  @override
  Future<void> sync({Duration wait = const Duration(seconds: 25)}) => Completer<void>().future; // never: no live server in tests

  @override
  Future<List<ChatPreview>> chats() async {
    final list = [
      for (final e in rooms.entries)
        if (!quiet(e.key))
          ChatPreview(
            roomId: e.key,
            name: names[e.key]!,
            isDirect: !groups.contains(e.key),
            encrypted: true,
            unread: unreadCounts[e.key] ?? 0,
            last: e.value.where((m) => !gone.contains(m.id)).lastOrNull,
            streak: streaksOn ? (streaks[e.key]?.$1 ?? 0) : 0,
            streakAtRisk: streaksOn && (streaks[e.key]?.$2 ?? false),
            pinned: pinnedChats.contains(e.key),
            archived: archivedChats.contains(e.key),
            muted: mutedChats.contains(e.key),
            isChannel: channels.contains(e.key),
            peer: peers[e.key] ?? '',
          ),
    ];
    // Same order as the engine: pinned (oldest pin first), then the rest.
    final pins = [for (final id in pinnedChats) ...list.where((c) => c.roomId == id)];
    return [...pins, ...list.where((c) => !c.pinned)];
  }

  @override
  Future<List<Msg>> timeline(String roomId, {int limit = 50}) async => [
    for (final m in rooms[roomId] ?? const <Msg>[])
      if (!gone.contains(m.id)) m,
  ];

  /// Emoji checks: flow id -> [user, state, steps polled].
  final checks = <String, List<Object>>{};
  final verifiedUsers = <String>{};
  @override
  Future<String> requestVerification(String userId) async {
    final id = 'flow${checks.length}';
    checks[id] = [userId, 'waiting', 0];
    return id;
  }

  @override
  Future<void> acceptVerification(String userId, String flowId) async => checks[flowId] = [userId, 'starting', 0];
  @override
  Future<String> verifyState(String userId, String flowId) async {
    final c = checks[flowId];
    if (c == null) return 'gone';
    // The other phone answers after a moment.
    c[2] = (c[2] as int) + 1;
    if ((c[1] == 'waiting' || c[1] == 'starting') && (c[2] as int) >= 2) c[1] = 'emoji';
    if (c[1] == 'confirmed') {
      c[1] = 'done';
      verifiedUsers.add(userId);
    }
    return c[1] as String;
  }

  static const demoEmoji = ['🐶 Dog', '🔑 Key', '🌙 Moon', '🎸 Guitar', '🚀 Rocket', '🍎 Apple', '⚓ Anchor'];
  @override
  Future<List<String>?> sasEmoji(String userId, String flowId) async => checks[flowId]?[1] == 'emoji' ? demoEmoji : null;
  @override
  Future<void> confirmSas(String userId, String flowId) async => checks[flowId]?[1] = 'confirmed';
  @override
  Future<void> cancelVerification(String userId, String flowId) async => checks[flowId]?[1] = 'cancelled';
  @override
  Future<bool> isUserVerified(String userId) async => verifiedUsers.contains(userId);
  @override
  Future<List<PeerDevice>> peerDevices(String userId) async => [
    PeerDevice(id: 'PHONE1', name: 'iPhone', key: 'mX3kQ9vT2bLwP7rYc4NfH8sJ1aZ6eD5uGqK0oW', verified: verifiedUsers.contains(userId)),
  ];

  /// Messages marked for the delete password: "room id" -> ids.
  final marked = <String, Set<String>>{};
  final gone = <String>{};
  @override
  Future<void> reportMessage(String roomId, String id, String reason, String shown) async => reports.add((id, reason, shown));

  /// Sent reports (tests): message id, reason, reported words.
  final reports = <(String, String, String)>[];

  @override
  Future<void> markForDelete(String roomId, String id, bool on) async {
    final s = marked.putIfAbsent(roomId, () => {});
    on ? s.add(id) : s.remove(id);
  }

  @override
  Future<List<String>> markedMessages(String roomId) async => [...?marked[roomId]];

  final quietSent = <String>[];
  @override
  Future<void> sendTextQuietly(String roomId, String text) async {
    quietSent.add(text);
    await sendText(roomId, text);
  }

  @override
  Future<void> sendText(String roomId, String text) async => rooms[roomId]!.add(
    Msg(
      id: _id(),
      sender: _me!,
      body: text,
      time: now,
      mine: true,
      kind: 'text',
      preview: previewsOn ? pages.entries.where((e) => text.contains(e.key)).firstOrNull?.value : null,
      expiresAt: (timers[roomId] ?? 0) > 0 ? now.add(Duration(seconds: timers[roomId]!)) : null,
    ),
  );

  /// Web pages the fake "phone" can read for link cards.
  final pages = <String, LinkCard>{};

  @override
  Future<String> createDirectChat(String userId) async {
    final existing = names.entries.where((e) => e.value == userId && !groups.contains(e.key));
    if (existing.isNotEmpty) return existing.first.key;
    final id = '!r${rooms.length}';
    rooms[id] = [];
    names[id] = userId;
    peers[id] = userId;
    return id;
  }

  /// 1:1 room → the other person's ID.
  final peers = <String, String>{};

  @override
  Future<String> makeRecoveryKey() async => 'abcd efgh ijkl';

  final files = <String, List<int>>{};
  DateTime? readAt;
  bool recovery = false;

  @override
  Future<bool> hasRecovery() async => recovery;
  @override
  Future<void> recover(String key) async => recovery = true;

  @override
  Future<List<Person>> contacts() async => [
    for (final e in names.entries)
      if (!groups.contains(e.key) && !quiet(e.key)) Person(userId: e.value.startsWith('@') ? e.value : '@${e.value}:test', name: e.value, roomId: e.key),
  ];
  @override
  Future<List<Person>> searchPeople(String term) async => [Person(userId: '@$term:test', name: term)];
  @override
  Future<void> markRead(String roomId) async => unreadCounts.remove(roomId);
  @override
  Future<DateTime?> readUntil(String roomId) async => prefs['send_read'] == '0' || prefs['send_read:$roomId'] == '0' ? null : readAt;

  @override
  Future<void> sendFile(String roomId, {required String name, required String mime, required List<int> bytes, String caption = ''}) async {
    final id = 'f${files.length}';
    files[id] = bytes;
    final kind = mime.startsWith('image/') ? 'image' : (mime.startsWith('video/') ? 'video' : 'file');
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: name,
        time: DateTime(2026, 11, 23, 20, 5),
        mine: true,
        kind: kind,
        caption: caption.trim().isEmpty ? null : caption.trim(),
      ),
    );
  }

  @override
  Future<List<int>> downloadFile(String roomId, String eventId) async => files[eventId] ?? const [];

  @override
  Future<String> createGroup(String name, List<String> members, {bool channel = false}) async {
    final id = '!g${rooms.length}';
    rooms[id] = [];
    names[id] = name;
    groups.add(id);
    if (channel) channels.add(id);
    return id;
  }

  /// Set to false to see a channel as a subscriber.
  bool owner = true;
  @override
  Future<bool> canPost(String roomId) async => !channels.contains(roomId) || owner;
  @override
  Future<bool> isChannel(String roomId) async => channels.contains(roomId);
  @override
  Future<void> replyInThread(String roomId, String rootId, String text) async =>
      rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: text, time: now, mine: true, kind: 'text', threadRoot: rootId));
  @override
  Future<void> reply(String roomId, String toId, String text) async =>
      rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: text, time: now, mine: true, kind: 'text', replyTo: toId));
  @override
  Future<void> edit(String roomId, String id, String text) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    l[i] = m.copyWith(body: text, edited: true);
  }

  @override
  Future<void> deleteMessage(String roomId, String id) async {
    final r = reactionOf.remove(id);
    if (r == null) return rooms[roomId]!.removeWhere((m) => m.id == id);
    final l = rooms[r.$1]!;
    final i = l.indexWhere((m) => m.id == r.$2);
    final m = l[i];
    final rs = [
      for (final x in m.reactions)
        if (x.key != r.$3) x else if (x.count > 1) Reaction(x.key, x.count - 1, null),
    ];
    l[i] = m.copyWith(reactions: rs);
  }

  @override
  Future<void> setTyping(String roomId, bool typing) async {}
  @override
  List<String> typingUsers(String roomId) => typing[roomId] ?? const [];

  // App lock: plain fields (the real hashing is tested in Rust).
  String? normalPw, hidePw, deletePw;
  int fails = 0;
  String role = 'normal';
  List<String> hideList = [], deleteList = [];
  bool hideOn = false;
  final erased = <String>{};

  @override
  Future<bool> lockIsSet() async => normalPw != null;
  @override
  Future<String?> unlock(String password) async {
    final r = password == normalPw
        ? 'normal'
        : password == hidePw
        ? 'hide'
        : password == deletePw
        ? 'delete'
        : null;
    fails = r == null ? fails + 1 : 0;
    if (r == null && fails >= wipeN) {
      fails = 0;
      wiped++;
      for (final id in rooms.keys.toList()) {
        rooms.remove(id);
        names.remove(id);
      }
    }
    return r;
  }

  int wipeN = 10;
  int wiped = 0;
  @override
  Future<int> wipeAfter() async => wipeN;
  @override
  Future<void> setWipeAfter(String normal, int n) async {
    if (normal != normalPw) throw StateError('wrong');
    wipeN = n;
  }

  final deletedForBoth = <String>[];
  final eraseNotices = <String>[];
  @override
  Future<void> deleteForBoth(String roomId) async {
    if (groups.contains(roomId)) throw StateError('1:1 only');
    deletedForBoth.add(roomId);
    rooms.remove(roomId);
    names.remove(roomId);
  }

  @override
  Future<List<String>> takeEraseNotices() async {
    final out = List.of(eraseNotices);
    eraseNotices.clear();
    return out;
  }

  @override
  Future<void> setNormalPassword(String password, {String? old}) async {
    if (normalPw != null && old != normalPw) throw StateError('wrong');
    normalPw = password;
  }

  @override
  Future<void> setExtraPassword(String normal, String role, String? password) async {
    if (normal != normalPw) throw StateError('wrong');
    if (password != null && [normalPw, hidePw, deletePw].contains(password)) throw StateError('used');
    role == 'hide' ? hidePw = password : deletePw = password;
  }

  @override
  Future<List<bool>> extrasSet(String normal) async {
    if (normal != normalPw) throw StateError('wrong');
    return [hidePw != null, deletePw != null];
  }

  @override
  Future<int> lockFails() async => fails;
  @override
  Future<void> startSession(String r) async {
    role = r;
    if (r == 'hide') hideOn = true;
    if (r == 'delete') {
      for (final e in marked.entries) {
        gone.addAll(e.value);
        rooms[e.key]?.removeWhere((m) => e.value.contains(m.id) && m.mine);
      }
      marked.clear();
      for (final id in deleteList) {
        for (final e in names.entries) {
          if (e.key == id || e.value == id) erased.add(e.key);
        }
      }
    }
  }

  @override
  String get sessionRole => role;
  @override
  Future<List<List<String>>> quietLists() async => [hideList, deleteList];
  @override
  Future<void> setQuietLists(List<String> hide, List<String> delete) async {
    hideList = hide;
    deleteList = delete;
  }

  @override
  Future<bool> hideActive() async => hideOn;
  @override
  Future<void> releaseHidden() async => hideOn = false;
  @override
  Future<String?> runDueLeaves() async => null;

  /// Room id -> (days, at risk), as the engine would work it out.
  final streaks = <String, (int, bool)>{};
  bool streaksOn = true;
  @override
  Future<bool> streaksEnabled() async => streaksOn;
  @override
  Future<void> setStreaksEnabled(bool on) async => streaksOn = on;
  @override
  Future<void> sendBubble(String roomId, String kind, String mime, List<int> bytes) async {
    if (groups.contains(roomId)) throw StateError('1:1 only');
    final id = _id();
    if (kind != 'emoji') files[id] = bytes;
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: kind == 'emoji' ? '' : kind,
        time: now,
        mine: true,
        kind: kind == 'emoji' ? 'text' : (kind == 'voice' ? 'audio' : 'image'),
        viewOnce: true,
        bubble: true,
      ),
    );
  }

  /// A friend's bubble arriving (for tests): kind text = emoji.
  String receiveBubble(String roomId, String from, String kind, List<int> bytes) {
    final id = _id();
    files[id] = bytes;
    rooms[roomId]!.add(Msg(id: id, sender: from, body: '', time: now, mine: false, kind: kind, viewOnce: true, bubble: true));
    return id;
  }

  // Notifications.
  final pushes = <(String, String, String)>[];
  bool hideNotice = false;
  final notified = <String>{};
  @override
  Future<void> setPush(String gatewayUrl, String pushKey, String appId) async => pushes.add((gatewayUrl, pushKey, appId));
  @override
  Future<List<Notice>> notifications({int max = 5}) async => [
    for (final e in rooms.entries)
      if (!mutedChats.contains(e.key))
        for (final m in e.value)
          if (!m.mine && notified.add(m.id))
            Notice(
              roomId: e.key,
              chat: hideNotice ? '' : names[e.key]!,
              sender: groups.contains(e.key) && !hideNotice ? m.sender : '',
              kind: m.kind,
              body: hideNotice || m.kind != 'text' || m.viewOnce ? null : m.body,
              time: m.time,
            ),
  ];
  @override
  Future<bool> noticeTextHidden() async => hideNotice;
  String waitMode = 'wait';
  @override
  Future<String> callWaiting() async => waitMode;
  @override
  Future<void> setCallWaiting(String mode) async => waitMode = mode;
  @override
  Future<void> setNoticeTextHidden(bool on) async => hideNotice = on;

  // Calls: kept as call lines in the chat, like the engine.
  ({String room, int index})? _findCall(String callId) {
    for (final e in rooms.entries) {
      final i = e.value.indexWhere((m) => m.call?.id == callId);
      if (i >= 0) return (room: e.key, index: i);
    }
    return null;
  }

  void _setCall(String callId, CallInfo Function(CallInfo c) f) {
    final at = _findCall(callId);
    if (at == null) throw StateError('no call');
    final m = rooms[at.room]![at.index];
    rooms[at.room]![at.index] = m.copyWith(call: f(m.call!));
  }

  @override
  Future<String> startCall(String roomId, {required bool video}) async {
    if (channels.contains(roomId)) throw StateError('no calls in channels');
    final id = 'call${_n++}';
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: '',
        time: now,
        mine: true,
        kind: 'call',
        call: CallInfo(id: id, video: video, state: 'ringing', started: now),
      ),
    );
    return id;
  }

  /// A friend calling me (for tests).
  String receiveCall(String roomId, String from, {bool video = false}) {
    final id = 'call${_n++}';
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: from,
        body: '',
        time: now,
        mine: false,
        kind: 'call',
        call: CallInfo(id: id, video: video, state: 'ringing', started: now),
      ),
    );
    return id;
  }

  final hangups = <String, String>{};

  @override
  Future<void> answerCall(String roomId, String callId) async =>
      _setCall(callId, (c) => CallInfo(id: c.id, video: c.video, state: 'ongoing', started: c.started, answered: now));

  @override
  Future<void> hangupCall(String roomId, String callId, String reason) async {
    hangups[callId] = reason;
    _setCall(callId, (c) {
      if (c.ended != null) return c;
      final state = c.answered != null ? 'ended' : (reason == 'decline' ? 'declined' : (reason == 'busy' ? 'busy' : 'missed'));
      return CallInfo(id: c.id, video: c.video, state: state, started: c.started, answered: c.answered, ended: now);
    });
  }

  @override
  Future<String> callState(String roomId, String callId) async {
    final at = _findCall(callId);
    return at == null ? 'ringing' : rooms[at.room]![at.index].call!.state;
  }

  @override
  Future<List<RingingCall>> ringingCalls() async => [
    for (final e in rooms.entries)
      for (final m in e.value.reversed)
        if (m.call != null && !m.mine && m.call!.state == 'ringing')
          RingingCall(roomId: e.key, callId: m.call!.id, from: m.sender, video: m.call!.video, time: m.time),
  ];

  @override
  Future<CallTicket> callTicket(String roomId, String callId) async {
    final at = _findCall(callId)!;
    return CallTicket(url: 'wss://calls.test', token: 'pass', mediaKey: 'key-$callId', video: rooms[at.room]![at.index].call!.video);
  }

  /// Stories (mine and friends'), oldest first.
  final storyList = <Story>[];
  List<String> lastStoryOnly = const [];
  int lastStoryHours = 24;

  @override
  Future<int> postStory({
    required String mime,
    required List<int> bytes,
    String caption = '',
    List<String> only = const [],
    int hours = 24,
    String extra = '',
  }) async {
    final friends = rooms.keys.where((r) => !groups.contains(r) && r != saved && (only.isEmpty || only.contains(r))).length;
    if (friends == 0) throw StateError('no friends yet');
    final id = 'story${storyList.length}';
    files[id] = bytes;
    storyList.add(
      Story(
        id: id,
        roomId: '',
        eventId: id,
        sender: _me ?? '@me:test',
        mine: true,
        time: DateTime.now(),
        kind: mime.isEmpty ? 'text' : (mime.startsWith('video/') ? 'video' : 'image'),
        caption: caption.trim().isEmpty ? null : caption.trim(),
        extra: extra.isEmpty ? null : extra,
        feed: hours == 0,
      ),
    );
    lastStoryOnly = only;
    lastStoryHours = hours;
    return friends;
  }

  @override
  Future<List<Story>> stories() async => List.of(storyList);

  /// (post id, sender) -> liked.
  final likes = <(String, String), bool>{};

  @override
  Future<void> feedLike(String roomId, String postId, {bool on = true}) async => likes[(postId, _me ?? '@me:test')] = on;

  @override
  Future<List<FeedLike>> feedLikes() async => [
    for (final e in likes.entries)
      if (e.value) FeedLike(postId: e.key.$1, sender: e.key.$2, mine: e.key.$2 == (_me ?? '@me:test')),
  ];

  @override
  Future<void> deleteStory(String id) async => storyList.removeWhere((x) => x.id == id && x.mine);

  @override
  Future<List<BubbleRef>> pendingBubbles() async => [
    for (final e in rooms.entries)
      if (!groups.contains(e.key))
        for (final m in e.value.reversed)
          if (m.bubble && !m.mine && !m.opened) BubbleRef(roomId: e.key, id: m.id, from: m.sender, time: m.time),
  ];

  @override
  Future<void> createPoll(
    String roomId,
    String question,
    List<String> options, {
    required bool anonymous,
    required bool multiple,
    int? quiz,
    String explain = '',
    DateTime? closeAt,
  }) async {
    final opts = [for (final o in options.map((o) => o.trim()).where((o) => o.isNotEmpty)) o];
    if (question.trim().isEmpty || opts.length < 2) throw ArgumentError('poll');
    if (quiz != null && (quiz < 0 || quiz >= opts.length)) throw ArgumentError('quiz');
    if (explain.length > 200) throw ArgumentError('explain');
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: question,
        time: now,
        mine: true,
        kind: 'poll',
        poll: PollInfo(
          question: question,
          options: [for (var i = 0; i < opts.length; i++) PollOption('a$i', opts[i], 0)],
          anonymous: anonymous || channels.contains(roomId),
          multiple: multiple && quiz == null,
          correct: quiz == null ? null : 'a$quiz',
          explain: quiz == null ? '' : explain.trim(),
          closeAt: closeAt,
        ),
      ),
    );
  }

  /// Other people's votes on a poll: user -> choices.
  final otherVotes = <String, Map<String, List<String>>>{};

  void _repoll(String roomId, String pollId, List<String>? mine, {bool? closed}) {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == pollId);
    final m = l[i];
    final p = m.poll!;
    final my = mine ?? p.mine;
    final all = {...?otherVotes[pollId], if (my.isNotEmpty) _me!: my};
    l[i] = Msg(
      id: m.id,
      sender: m.sender,
      body: m.body,
      time: m.time,
      mine: m.mine,
      kind: 'poll',
      poll: PollInfo(
        question: p.question,
        options: [
          for (final o in p.options)
            PollOption(
              o.id,
              o.text,
              all.values.where((c) => c.contains(o.id)).length,
              p.anonymous
                  ? const []
                  : [
                      for (final e in all.entries)
                        if (e.value.contains(o.id)) e.key,
                    ],
            ),
        ],
        anonymous: p.anonymous,
        multiple: p.multiple,
        closed: closed ?? p.closed,
        voters: all.values.where((c) => c.isNotEmpty).length,
        mine: my,
        correct: p.correct,
        explain: p.explain,
        closeAt: p.closeAt,
      ),
    );
  }

  void seedVotes(String roomId, String pollId, Map<String, List<String>> votes) {
    otherVotes[pollId] = votes;
    _repoll(roomId, pollId, null);
  }

  @override
  Future<void> vote(String roomId, String pollId, List<String> choices) async {
    final p = rooms[roomId]!.firstWhere((m) => m.id == pollId).poll!;
    if (p.closedAt(now)) throw StateError('closed');
    // A quiz answer is final.
    if (p.isQuiz && p.mine.isNotEmpty) throw StateError('answered');
    _repoll(roomId, pollId, choices);
  }

  @override
  Future<void> closePoll(String roomId, String pollId) async => _repoll(roomId, pollId, null, closed: true);

  /// Card answers kept by the maker: card id -> person -> answer.
  final cardBooks = <String, Map<String, Object?>>{};

  @override
  Future<void> createCard(String roomId, String kind, Map<String, Object?> data) async {
    final d = demoCheckCard(kind, data, now);
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: cardBody(kind, d),
        time: now,
        mine: true,
        kind: 'card',
        card: CardInfo(kind: kind, data: d),
      ),
    );
  }

  void _recard(String roomId, String id, CardInfo Function(CardInfo c) change) {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    l[i] = l[i].copyWith(card: change(l[i].card!));
  }

  Map<String, int> _counts(String kind, Map<String, Object?> book) {
    final c = <String, int>{};
    for (final v in book.values) {
      final k = kind == 'form' ? 'sent' : (v is String ? v : '');
      if (k.isNotEmpty) c[k] = (c[k] ?? 0) + 1;
    }
    return c;
  }

  @override
  Future<void> answerCard(String roomId, String cardId, Object? answer) async {
    final c = rooms[roomId]!.firstWhere((m) => m.id == cardId).card!;
    if (!CardInfo.answered(c.kind) || c.closedAt(now)) throw StateError('closed');
    final ok = switch (c.kind) {
      _ when answer == null => true,
      'lottery' => answer == 'in',
      'checkin' => answer == 'ok' || answer == 'help',
      _ => answer is List && answer.length == c.listOf('questions').length,
    };
    if (!ok) throw ArgumentError('answer');
    final book = cardBooks.putIfAbsent(cardId, () => {});
    answer == null ? book.remove(_me) : book[_me!] = answer;
    _recard(roomId, cardId, (p) => CardInfo(kind: p.kind, data: p.data, counts: _counts(p.kind, book), winners: p.winners, closed: p.closed, mine: answer));
  }

  @override
  Future<List<CardAnswer>> cardAnswers(String roomId, String cardId) async {
    if (!rooms[roomId]!.firstWhere((m) => m.id == cardId).mine) throw StateError('not maker');
    return [for (final e in (cardBooks[cardId] ?? const {}).entries) CardAnswer(e.key, e.value)];
  }

  @override
  Future<List<String>> closeCard(String roomId, String cardId) async {
    final m = rooms[roomId]!.firstWhere((m) => m.id == cardId);
    if (!m.mine) throw StateError('not maker');
    final c = m.card!;
    var winners = <String>[];
    if (c.kind == 'lottery') {
      final n = (c.data['winners'] as int?) ?? 1;
      // Admins and the maker never win.
      winners = ([
        for (final e in (cardBooks[cardId] ?? const {}).entries)
          if (e.value == 'in' && e.key != _me) e.key,
      ]..shuffle()).take(n).toList();
    }
    final counts = {...c.counts, if (c.kind == 'lottery') 'won': winners.length};
    _recard(roomId, cardId, (p) => CardInfo(kind: p.kind, data: p.data, counts: counts, winners: winners, closed: true, mine: p.mine));
    return winners;
  }

  void seedCardAnswers(String roomId, String cardId, Map<String, Object?> answers) {
    final book = cardBooks.putIfAbsent(cardId, () => {})..addAll(answers);
    _recard(roomId, cardId, (p) => CardInfo(kind: p.kind, data: p.data, counts: _counts(p.kind, book), winners: p.winners, closed: p.closed, mine: p.mine));
  }

  @override
  Future<void> createChecklist(String roomId, String title, List<String> items, {required bool othersMark, required bool othersAdd}) async {
    final list = [for (final t in items.map((t) => t.trim()).where((t) => t.isNotEmpty).take(30)) t];
    if (title.trim().isEmpty || list.isEmpty) throw ArgumentError('checklist');
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: title.trim(),
        time: now,
        mine: true,
        kind: 'checklist',
        checklist: ChecklistInfo(
          title: title.trim(),
          items: [for (var i = 0; i < list.length; i++) ChecklistItem('i$i', list[i])],
          othersMark: othersMark,
          othersAdd: othersAdd,
        ),
      ),
    );
  }

  @override
  Future<void> createMeetup(String roomId, String title, DateTime startsAt, String place) async {
    if (title.trim().isEmpty) throw ArgumentError('meetup');
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: title.trim(),
        time: now,
        mine: true,
        kind: 'meetup',
        meetup: MeetupInfo(title: title.trim(), startsAt: startsAt, place: place.trim().isEmpty ? null : place.trim()),
      ),
    );
  }

  void _replan(String roomId, String id, MeetupInfo Function(MeetupInfo m) change) {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    l[i] = m.copyWith(meetup: change(m.meetup!));
  }

  @override
  Future<void> answerMeetup(String roomId, String meetupId, String answer) async {
    final me = _me!;
    _replan(roomId, meetupId, (p) {
      if (p.cancelled) return p;
      List<String> put(List<String> l, String a) => [...l.where((u) => u != me), if (answer == a) me];
      return MeetupInfo(title: p.title, startsAt: p.startsAt, place: p.place, yes: put(p.yes, 'yes'), no: put(p.no, 'no'), maybe: put(p.maybe, 'maybe'));
    });
  }

  @override
  Future<void> cancelMeetup(String roomId, String meetupId) async {
    if (!rooms[roomId]!.firstWhere((m) => m.id == meetupId).mine) return;
    _replan(roomId, meetupId, (p) => MeetupInfo(title: p.title, startsAt: p.startsAt, place: p.place, cancelled: true, yes: p.yes, no: p.no, maybe: p.maybe));
  }

  @override
  Future<void> sendLocation(String roomId, double lat, double lon, double? accuracy) async {
    final u = accuracy == null ? '' : ';u=${accuracy.round()}';
    rooms[roomId]!.add(
      Msg(id: _id(), sender: _me!, body: 'geo:${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}$u', time: now, mine: true, kind: 'location'),
    );
  }

  @override
  Future<void> sendContact(String roomId, String userId, String name) async {
    rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: name, time: now, mine: true, kind: 'contact', contact: userId));
  }

  void _relist(String roomId, String id, ChecklistInfo Function(ChecklistInfo c) change) {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    l[i] = m.copyWith(checklist: change(m.checklist!));
  }

  bool _mayChange(String roomId, String id, bool Function(ChecklistInfo c) allowed) {
    final m = rooms[roomId]!.firstWhere((m) => m.id == id);
    return m.mine || allowed(m.checklist!);
  }

  @override
  Future<void> markChecklist(String roomId, String checklistId, String itemId, bool done) async {
    if (!_mayChange(roomId, checklistId, (c) => c.othersMark)) return;
    _relist(
      roomId,
      checklistId,
      (c) => ChecklistInfo(
        title: c.title,
        items: [for (final it in c.items) it.id == itemId ? ChecklistItem(it.id, it.text, doneBy: done ? _me : null, addedBy: it.addedBy) : it],
        othersMark: c.othersMark,
        othersAdd: c.othersAdd,
      ),
    );
  }

  @override
  Future<void> addChecklistItem(String roomId, String checklistId, String text) async {
    if (text.trim().isEmpty || !_mayChange(roomId, checklistId, (c) => c.othersAdd)) return;
    _relist(
      roomId,
      checklistId,
      (c) => ChecklistInfo(
        title: c.title,
        items: [
          ...c.items,
          if (c.items.length < 30) ChecklistItem(_id(), text.trim(), addedBy: _me),
        ],
        othersMark: c.othersMark,
        othersAdd: c.othersAdd,
      ),
    );
  }

  @override
  Future<void> sendVoice(String roomId, String mime, List<int> bytes, Duration duration, List<int> waveform) async {
    final id = _id();
    files[id] = bytes;
    rooms[roomId]!.add(Msg(id: id, sender: _me!, body: 'voice', time: now, mine: true, kind: 'audio', voice: VoiceInfo(duration, waveform)));
  }

  bool previewsOn = true;
  final previewImages = <String, List<int>>{};
  @override
  Future<bool> linkPreviewsEnabled() async => previewsOn;
  @override
  Future<void> setLinkPreviewsEnabled(bool on) async => previewsOn = on;
  @override
  Future<List<int>> previewImage(String roomId, String eventId) async => previewImages[eventId] ?? const [];
  @override
  Future<void> forward(String fromRoom, String id, String toRoom) async {
    final m = rooms[fromRoom]!.firstWhere((m) => m.id == id);
    if (m.viewOnce) throw StateError('view once');
    rooms[toRoom]!.add(Msg(id: _id(), sender: _me!, body: m.body, time: now, mine: true, kind: m.kind, forwarded: true, preview: m.preview));
  }

  @override
  Future<List<Msg>> searchMessages(String roomId, String term) async {
    final t = term.trim().toLowerCase();
    if (t.isEmpty) return const [];
    return [
      for (final m in (rooms[roomId] ?? const <Msg>[]).reversed)
        if ((m.kind == 'text' || m.kind == 'file') && (m.body ?? '').toLowerCase().contains(t)) m,
    ];
  }

  @override
  Future<void> setChatPinned(String roomId, bool on) async {
    pinnedChats.remove(roomId);
    if (on) pinnedChats.add(roomId);
  }

  @override
  Future<void> setChatArchived(String roomId, bool on) async => on ? archivedChats.add(roomId) : archivedChats.remove(roomId);
  @override
  Future<void> setChatMuted(String roomId, bool on) async => on ? mutedChats.add(roomId) : mutedChats.remove(roomId);
  final pins = <String, List<String>>{};
  @override
  Future<void> react(String roomId, String id, String key) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    final rs = [...m.reactions];
    final j = rs.indexWhere((r) => r.key == key);
    final rid = 'r${_id()}';
    if (j < 0) {
      rs.add(Reaction(key, 1, rid));
    } else {
      rs[j] = Reaction(key, rs[j].count + 1, rid);
    }
    reactionOf[rid] = (roomId, id, key);
    l[i] = m.copyWith(reactions: rs);
  }

  final reactionOf = <String, (String, String, String)>{};
  @override
  Future<void> pin(String roomId, String id, bool pinned) async {
    final l = pins.putIfAbsent(roomId, () => []);
    pinned ? l.add(id) : l.remove(id);
  }

  @override
  List<String> pinned(String roomId) => pins[roomId] ?? const [];
  final timers = <String, int>{};
  @override
  Future<void> setTimer(String roomId, int seconds) async {
    timers[roomId] = seconds;
    rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: '$seconds', time: now, mine: true, kind: 'timer'));
  }

  @override
  Future<int> timer(String roomId) async => timers[roomId] ?? 0;
  @override
  Future<int> runExpiry() async => 0;
  String? myDisplayName;
  List<int>? photo;
  @override
  Future<String> myName() async => myDisplayName ?? _me!.substring(1).split(':').first;
  @override
  Future<void> setMyName(String name) async => myDisplayName = name;
  final bios = <String, String>{};
  @override
  Future<void> setMyBio(String text) async => text.isEmpty ? bios.remove(userId) : bios[userId ?? ''] = text;
  @override
  Future<String> bioOf(String userId) async => bios[userId] ?? '';
  @override
  Future<List<int>?> myPhoto() async => photo;
  @override
  Future<void> setMyPhoto(String mime, List<int> bytes) async => photo = bytes.isEmpty ? null : bytes;
  @override
  Future<List<Member>> members(String roomId) async => roomMembers[roomId] ?? await _defaultMembers(roomId);

  Future<List<Member>> _defaultMembers(String roomId) async => [
    Member(userId: _me!, name: await myName(), role: groups.contains(roomId) && (owner || !channels.contains(roomId)) ? 'owner' : 'member'),
    Member(userId: names[roomId]!.startsWith('@') ? names[roomId]! : '@mina:test', name: groups.contains(roomId) ? 'mina' : names[roomId]!, role: 'member'),
  ];

  /// Members after someone was added, removed or promoted.
  final roomMembers = <String, List<Member>>{};
  final abouts = <String, String>{};
  final switches = <String, bool>{};

  Future<List<Member>> _editMembers(String roomId, List<Member> Function(List<Member> l) f) async => roomMembers[roomId] = f(List.of(await members(roomId)));

  @override
  Future<void> setRoomName(String roomId, String name) async {
    if (name.trim().isEmpty) throw ArgumentError('name');
    names[roomId] = name.trim();
  }

  @override
  Future<String> roomAbout(String roomId) async => abouts[roomId] ?? '';
  @override
  Future<void> setRoomAbout(String roomId, String text) async => abouts[roomId] = text.trim();
  @override
  Future<void> inviteUsers(String roomId, List<String> userIds) async => _editMembers(roomId, (l) {
    for (final u in userIds) {
      if (!l.any((m) => m.userId == u)) l.add(Member(userId: u, name: u.substring(1).split(':').first, role: 'member'));
    }
    return l;
  });
  @override
  Future<void> removeMember(String roomId, String userId) async {
    if (userId == _me) throw ArgumentError('self');
    await _editMembers(roomId, (l) => l..removeWhere((m) => m.userId == userId && m.role != 'owner'));
  }

  @override
  Future<void> setAdmin(String roomId, String userId, bool admin) async => _editMembers(
    roomId,
    (l) => [for (final m in l) m.userId == userId && m.role != 'owner' ? Member(userId: m.userId, name: m.name, role: admin ? 'admin' : 'member') : m],
  );
  @override
  Future<bool> roomSwitch(String roomId, String key) async => switches['$roomId/$key'] ?? false;
  @override
  Future<void> setRoomSwitch(String roomId, String key, bool on) async => switches['$roomId/$key'] = on;
  final roomConfigs = <String, Map<String, dynamic>>{};
  final bannedUsers = <String, Set<String>>{};
  @override
  Future<Map<String, dynamic>> roomConfig(String roomId) async => Map.of(roomConfigs[roomId] ?? const {});
  @override
  Future<void> setRoomConfig(String roomId, String key, Object? value) async {
    if (await myRole(roomId) == 'member') throw StateError('admins only');
    final c = roomConfigs.putIfAbsent(roomId, () => {});
    value == null ? c.remove(key) : c[key] = value;
  }

  @override
  Future<void> setBanned(String roomId, String userId, bool banned) async {
    final set = bannedUsers.putIfAbsent(roomId, () => {});
    if (banned) {
      set.add(userId);
      await removeMember(roomId, userId);
    } else {
      set.remove(userId);
    }
  }

  @override
  Future<List<String>> banned(String roomId) async => (bannedUsers[roomId] ?? const {}).toList();
  @override
  Future<String> myRole(String roomId) async => (await members(roomId))
      .firstWhere(
        (m) => m.userId == _me,
        orElse: () => const Member(userId: '', name: '', role: 'member'),
      )
      .role;
  @override
  Future<void> leave(String roomId) async {
    rooms.remove(roomId);
    names.remove(roomId);
  }

  /// Invitations waiting (tests add to it).
  final invites = <Invite>[];
  @override
  Future<List<Invite>> invitations() async => List.of(invites);
  @override
  Future<List<CallLogItem>> callLog({int max = 200}) async {
    final out = [
      for (final e in rooms.entries)
        for (final m in e.value)
          if (m.call != null) CallLogItem(roomId: e.key, from: m.sender, mine: m.mine, call: m.call!),
    ]..sort((a, b) => b.call.started.compareTo(a.call.started));
    return out.take(max).toList();
  }

  /// On-device settings (tests read them).
  final prefs = <String, String>{};
  @override
  Future<Map<String, String>> settings() async => Map.of(prefs);
  @override
  Future<void> setSetting(String key, String value) async => value.isEmpty ? prefs.remove(key) : prefs[key] = value;
  final blockedIds = <String>[];
  @override
  Future<List<String>> blocked() async => List.of(blockedIds);
  @override
  Future<void> block(String userId, bool on) async {
    blockedIds.remove(userId);
    if (on) blockedIds.add(userId);
  }

  /// Devices other than this one (tests add to it).
  final otherDevices = <DeviceRow>[];
  @override
  Future<List<DeviceRow>> devices() async => [DeviceRow(id: 'THIS', name: 'Burumy', lastSeen: now, thisDevice: true, verified: true), ...otherDevices];
  String password = 'demo';
  @override
  Future<void> logOutDevices(List<String> ids, String password) async {
    if (password != this.password) throw StateError('wrong password');
    otherDevices.removeWhere((d) => ids.contains(d.id));
  }

  @override
  Future<void> changePassword(String old, String newPassword) async {
    if (old != password) throw StateError('wrong password');
    password = newPassword;
  }

  @override
  Future<List<String>> myKeys() async => ['27avJm56TmEhO+eHxYA4EHytkPYIjX/1TChlQ2kK/1c', 'iFV0Gauocf6r2/G6DM4mOb7+yAROkfsGl21YcNNwiqw'];
  @override
  Future<bool> thisDeviceVerified() async => true;
  String? saved;
  @override
  Future<String?> savedRoom({bool create = false}) async {
    if (saved == null && create) {
      saved = 'saved';
      rooms[saved!] = [];
      names[saved!] = '';
    }
    return saved;
  }

  @override
  Future<void> join(String roomId) async {
    final i = invites.firstWhere((i) => i.roomId == roomId);
    invites.remove(i);
    rooms[roomId] = [];
    names[roomId] = i.direct ? i.inviter : i.name;
    if (!i.direct) groups.add(roomId);
  }

  @override
  Future<void> decline(String roomId) async => invites.removeWhere((i) => i.roomId == roomId);
  @override
  Future<void> sendViewOnce(String roomId, {required String name, required String mime, required List<int> bytes}) async {
    final id = 'f${files.length}';
    files[id] = bytes;
    rooms[roomId]!.add(Msg(id: id, sender: _me!, body: name, time: now, mine: true, kind: 'image', viewOnce: true));
  }

  @override
  Future<List<int>> openViewOnce(String roomId, String id) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    if (m.opened || m.mine) throw StateError('no');
    l[i] = Msg(id: m.id, sender: m.sender, body: m.body, time: m.time, mine: m.mine, kind: m.kind, viewOnce: true, opened: true, bubble: m.bubble);
    return files[id] ?? const [];
  }

  @override
  Future<void> sendSticker(String roomId, String stickerId) async =>
      rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: stickerId, time: now, mine: true, kind: 'sticker'));

  bool quiet(String roomId) => erased.contains(roomId) || (hideOn && role != 'hide' && (hideList.contains(roomId) || hideList.contains(names[roomId])));
}

/// Short line for the chat list and notifications.
String cardBody(String kind, Map<String, Object?> d) => switch (kind) {
  'faq' => '❓ ${d['title'] is String && (d['title'] as String).isNotEmpty ? d['title'] : 'FAQ'}',
  'guide' => '🧭 ${d['title']}',
  'links' => '🔗 ${d['text']}',
  'rich' => '📝 ${d['title']}',
  'lottery' => '🎁 ${d['prize']}',
  'form' => '📋 ${d['title']}',
  _ => '🛟 ${d['text']}',
};

/// The demo's copy of the phone-side checks (the real ones live in the engine).
Map<String, Object?> demoCheckCard(String kind, Map<String, Object?> d, DateTime now) {
  String? t(Object? v, int max) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty || s.length > max ? null : s;
  }

  bool url(Object? v) => v is String && RegExp(r'^https?://\S+$').hasMatch(v) && v.length <= 500;
  List<Map> list(Object? v, int max) => [
    for (final x in (v is List ? v : const []))
      if (x is Map) x,
  ].take(max).toList();
  Map<String, Object?> need(Map<String, Object?> m, bool ok) => ok ? m : throw ArgumentError(kind);
  return switch (kind) {
    'faq' => () {
      final items = [
        for (final x in list(d['items'], 30))
          if (t(x['q'], 200) case final q?)
            if (t(x['a'], 1000) case final a?) {'q': q, 'a': a},
      ];
      return need({'title': t(d['title'], 100) ?? '', 'items': items}, items.isNotEmpty);
    }(),
    'guide' => () {
      final items = [
        for (final x in list(d['items'], 20))
          if (t(x['label'], 60) case final l?)
            if (t(x['text'], 1000) case final a?) {'label': l, 'text': a},
      ];
      return need({'title': t(d['title'], 100) ?? '', 'sub': t(d['sub'], 200) ?? '', 'items': items}, items.isNotEmpty);
    }(),
    'links' => () {
      const colors = ['green', 'blue', 'teal', 'purple', 'pink', 'red', 'orange', 'yellow', 'grey', 'black', 'white'];
      final perRow = List.filled(6, 0);
      final b = <Map<String, Object?>>[];
      for (final x in list(d['buttons'], 18)) {
        final row = (x['row'] is int ? x['row'] as int : 0).clamp(0, 5);
        final l = t(x['label'], 24);
        if (l == null || !url(x['url']) || perRow[row] >= 3) continue;
        perRow[row]++;
        b.add({'label': l, 'url': x['url'], 'color': colors.contains(x['color']) ? x['color'] : '', 'row': row});
      }
      final st = d['style'] is Map ? d['style'] as Map : const {};
      String pick(Object? v, List<String> from, String def) => from.contains(v) ? v as String : def;
      final style = {
        'color': pick(st['color'], colors, 'green'),
        'glass': st['glass'] is bool ? st['glass'] : true,
        'size': pick(st['size'], const ['s', 'm', 'l'], 'm'),
        'shape': pick(st['shape'], const ['round', 'pill', 'square'], 'round'),
        'ink': pick(st['ink'], const ['auto', 'white', 'black'], 'auto'),
      };
      return need({'text': t(d['text'], 2000) ?? '', 'buttons': b, 'style': style}, b.isNotEmpty);
    }(),
    'rich' => () {
      final b = [
        for (final x in list(d['blocks'], 50))
          if (t(x['text'], 2000) case final s?)
            if (x['t'] == 'link' ? url(x['url']) : const ['h', 'p', 'li', 'quote'].contains(x['t']))
              {'t': x['t'], 'text': s, if (x['t'] == 'link') 'url': x['url']},
      ];
      return need({'title': t(d['title'], 200) ?? '', 'blocks': b}, b.isNotEmpty);
    }(),
    'lottery' => () {
      final w = d['winners'] is int ? d['winners'] as int : 1;
      final e = d['ends_at'] is int ? d['ends_at'] as int : 0;
      final n = now.millisecondsSinceEpoch;
      final okEnd = e == 0 || (e > n + 60000 && e <= n + 90 * 86400000);
      return need({
        'prize': t(d['prize'], 200),
        'winners': w,
        'ends_at': e,
        'note': t(d['note'], 500) ?? '',
        'announce': d['announce'] == true,
      }, t(d['prize'], 200) != null && w >= 1 && w <= 100 && okEnd);
    }(),
    'form' => () {
      final q = [
        for (final x in list(d['questions'], 20))
          if (t(x['q'], 200) case final s?)
            () {
              final o = [for (final v in (x['options'] is List ? x['options'] as List : const [])) ?t(v, 100)].take(10).toList();
              return {'q': s, 'type': o.length >= 2 ? 'choice' : 'text', 'options': o.length >= 2 ? o : <String>[]};
            }(),
      ];
      return need({'title': t(d['title'], 200), 'questions': q}, t(d['title'], 200) != null && q.isNotEmpty);
    }(),
    'checkin' => need({'text': t(d['text'], 500)}, t(d['text'], 500) != null),
    _ => throw ArgumentError(kind),
  };
}
