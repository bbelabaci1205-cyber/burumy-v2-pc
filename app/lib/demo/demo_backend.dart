// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// In-memory backend: screen tests and the look-only demo (no server).
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/imported.dart' show demoAssembleImport;
import 'package:burumy/core/search.dart';
import 'package:burumy/core/room_links.dart' show InviteLink;
import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:crypto/crypto.dart' show sha256;
import 'package:burumy/core/doc.dart';
import 'package:burumy/core/id_key.dart';
import 'package:burumy/core/trust.dart';

/// The app lock is one for the whole phone, shared by every account.
class FakeLock {
  String? normalPw, hidePw, deletePw, accountPw;
  int fails = 0;
  int wipeN = 10;
}

class FakeBackend implements Backend {
  FakeBackend({FakeLock? lock}) : lk = lock ?? FakeLock();
  final FakeLock lk;
  String? _me;
  final rooms = <String, List<Msg>>{};
  final groups = <String>{};
  // demo rooms that are not one person (a family chat, a shop): kept out of the contacts list.
  final notContacts = <String>{};
  final channels = <String>{};
  final typing = <String, List<String>>{};
  int _n = 0;
  String _id() => 'e${_n++}';
  DateTime now = DateTime(2026, 11, 23, 20);
  @override
  DateTime get clock => now;
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
  Future<void> eraseEverything() async {
    wiped++;
    for (final id in rooms.keys.toList()) {
      rooms.remove(id);
      names.remove(id);
    }
  }

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
            last: e.value.where((m) => !unseen(m.id)).lastOrNull,
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
  Future<List<Msg>> cachedMessages(String roomId) => timeline(roomId);
  @override
  Future<List<Msg>> timeline(String roomId, {int limit = 50}) async {
    _sealTopics(roomId);
    return [
      for (final m in rooms[roomId] ?? const <Msg>[])
        if (!unseen(m.id)) topicOf[m.id] != null && m.topic != topicOf[m.id] ? m.copyWith(topic: topicOf[m.id]) : m,
    ];
  }

  /// 주제 (tip 527): the topic my new messages go to, per room, and the
  /// topic each message got (fixed the first time the chat is read, like
  /// the engine writing it into the encrypted content when sending).
  final sendTopics = <String, String>{};
  final topicOf = <String, String?>{};

  @override
  void setSendTopic(String roomId, String? topic) {
    _sealTopics(roomId);
    topic == null || topic == 'g' ? sendTopics.remove(roomId) : sendTopics[roomId] = topic;
  }

  void _sealTopics(String roomId) {
    for (final m in rooms[roomId] ?? const <Msg>[]) {
      topicOf.putIfAbsent(m.id, () => m.topic ?? (m.mine ? sendTopics[roomId] : null));
    }
  }

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

  /// Messages marked for the hide password: "room id" -> ids.
  final veiled = <String, Set<String>>{};
  @override
  Future<void> markForHide(String roomId, String id, bool on) async {
    final s = veiled.putIfAbsent(roomId, () => {});
    on ? s.add(id) : s.remove(id);
  }

  @override
  Future<List<String>> hideMarkedMessages(String roomId) async => [...?veiled[roomId]];

  /// Out of sight now: erased, or chosen for hiding while hiding is on.
  bool unseen(String id) => gone.contains(id) || (hideOn && role != 'hide' && veiled.values.any((s) => s.contains(id)));

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
      postAs: sendAs[roomId],
    ),
  );

  @override
  Future<void> sendTextLink(String roomId, String text, LinkChoice link, {String? replyTo, bool quiet = false}) async {
    if (replyTo != null) {
      await reply(roomId, replyTo, text);
    } else if (quiet) {
      await sendTextQuietly(roomId, text);
    } else {
      await sendText(roomId, text);
    }
    final list = rooms[roomId]!;
    final last = list.removeLast();
    LinkCard? card;
    if (previewsOn && !link.off) {
      final first = RegExp(r'https?://[^\s<>()\[\]]+[^\s<>()\[\].,!?]').firstMatch(text)?.group(0);
      final url = link.url != null && text.contains(link.url!) ? link.url! : first;
      final hit = (url == null ? null : pages[url] ?? _cardFromStory(url)) ?? pages.entries.where((e) => text.contains(e.key)).firstOrNull?.value;
      if (hit != null) {
        card = LinkCard(
          url: hit.url,
          title: hit.title,
          description: hit.description,
          site: hit.site,
          hasImage: hit.hasImage,
          above: link.above,
          small: link.small && hit.hasImage,
        );
      }
    }
    list.add(last.withPreview(card));
    final img = storyLinks[card?.url]?.image;
    if (card != null && card.hasImage && img != null && img.isNotEmpty) previewImages[last.id] = img;
  }

  LinkCard? _cardFromStory(String url) {
    final s = storyLinks[url];
    return s == null
        ? null
        : LinkCard(url: url, title: s.title, description: s.description.isEmpty ? null : s.description, site: s.site, hasImage: s.image.isNotEmpty);
  }

  /// Web pages the fake "phone" can read for link cards.
  final pages = <String, LinkCard>{};

  @override
  Future<String> createDirectChat(String userId, {String idKey = ''}) async {
    if (idKey.trim().isNotEmpty) dmProofs[userId] = IdKey.proof(idKey, from: _me ?? '', to: userId);
    final existing = names.entries.where((e) => e.value == userId && !groups.contains(e.key));
    if (existing.isNotEmpty) return existing.first.key;
    // Server rule (4묶음): a shared group with "그룹 안 1:1 막기" on refuses
    // member-to-member chats.
    for (final g in groups.where(rooms.containsKey)) {
      if (roomConfigs[g]?['no_member_dm'] != true) continue;
      final ms = roomMembers[g] ?? await _defaultMembers(g);
      bool low(String? r) => r == 'member' || r == 'muted';
      final mine = ms.where((m) => m.userId == _me).firstOrNull?.role;
      final theirs = ms.where((m) => m.userId == userId).firstOrNull?.role;
      if (low(mine) && low(theirs)) throw StateError('burumy: this group does not allow 1:1 chats between members');
    }
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
      if (e.value.trim().isNotEmpty && !groups.contains(e.key) && !notContacts.contains(e.key) && !quiet(e.key) && !strangerRooms.contains(e.key))
        Person(
          userId: (peers[e.key] ?? '').startsWith('@') ? peers[e.key]! : (e.value.startsWith('@') ? e.value : '@${e.value}:test'),
          name: e.value,
          roomId: e.key,
        ),
  ];

  /// 1:1 chats someone new started (not in my contacts yet).
  final strangerRooms = <String>{};
  @override
  Future<List<Person>> searchPeople(String term) async => term.startsWith('@') && term.contains(':')
      ? [Person(userId: term, name: directory[term] ?? term.substring(1).split(':').first)]
      : [Person(userId: '@$term:test', name: term)];

  /// Names of people found by their full ID (demo).
  final directory = <String, String>{};
  @override
  Future<void> markRead(String roomId) async {
    unreadCounts.remove(roomId);
    // Look-only demo: something happens the moment a chat is read (once).
    onRead.remove(roomId)?.call();
  }

  /// One-shot actions run when a chat is read (demo only).
  final onRead = <String, void Function()>{};
  @override
  Future<DateTime?> readUntil(String roomId) async => prefs['send_read'] == '0' || prefs['send_read:$roomId'] == '0' ? null : readAt;

  /// When the other person read (demo: [readWhen], else just after [readAt]).
  DateTime? readWhen;
  @override
  Future<(DateTime?, DateTime?)> readReceipt(String roomId) async {
    final u = await readUntil(roomId);
    return (u, u == null ? null : (readWhen ?? u.add(const Duration(minutes: 1))));
  }

  @override
  Future<void> sendFile(
    String roomId, {
    required String name,
    required String mime,
    required List<int> bytes,
    String caption = '',
    bool captionAbove = false,
  }) async {
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
        size: bytes.length,
        captionAbove: captionAbove && caption.trim().isNotEmpty,
      ),
    );
  }

  @override
  Future<void> editMedia(String roomId, String id, {required String caption, bool captionAbove = false, String? name, String? mime, List<int>? bytes}) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == id);
    final m = l[i];
    if (!m.mine) throw StateError('only your own messages');
    final c = caption.trim();
    if (bytes == null) {
      if (m.kind == 'text') throw StateError('nothing to change');
      l[i] = m.afterMediaEdit(kind: m.kind, body: m.body, caption: c.isEmpty ? null : c, captionAbove: captionAbove && c.isNotEmpty);
      return;
    }
    // Same rule as the engine: no swaps in public groups and channels.
    if (links[roomId]?.public ?? false) throw StateError('photos can\'t be changed in public groups and channels');
    final fid = 'f${files.length}';
    files[fid] = bytes;
    final kind = mime!.startsWith('image/') ? 'image' : (mime.startsWith('video/') ? 'video' : 'file');
    l[i] = m.afterMediaEdit(
      kind: kind,
      body: name,
      caption: c.isEmpty ? null : c,
      captionAbove: captionAbove && c.isNotEmpty,
      mediaFrom: fid,
      size: bytes.length,
    );
  }

  @override
  Future<List<int>> downloadFile(String roomId, String eventId) async => files[eventId] ?? const [];

  /// Kept copies (tests read these).
  final kept = <String>{};
  Duration? keepFor;
  int? keepMax;

  @override
  Future<List<int>> downloadFileCached(String roomId, String eventId, {bool cache = true}) async {
    await holdDownloads?.future;
    if (cache) kept.add(eventId);
    return downloadFile(roomId, eventId);
  }

  /// Tests: hold downloads until this completes.
  Completer<void>? holdDownloads;

  @override
  Future<bool> cancelDownload(String eventId) async => false;

  @override
  Future<void> forgetFile(String roomId, String eventId) async => kept.remove(eventId);

  @override
  Future<void> setMediaKeep({int? maxFile, Duration? keep}) async {
    keepMax = maxFile;
    keepFor = keep;
  }

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
  Future<bool> canPost(String roomId) async =>
      (!channels.contains(roomId) ||
          // A channel whose member list says I only read it (demo 526).
          (owner && !(roomMembers[roomId]?.any((m) => m.userId == _me && m.role == 'member') ?? false)) ||
          (roomMembers[roomId]?.any((m) => m.userId == _me && (m.role == 'owner' || m.role == 'admin')) ?? false)) &&
      !(roomMembers[roomId]?.any((m) => m.userId == _me && m.role == 'muted') ?? false);
  @override
  Future<bool> isChannel(String roomId) async => channels.contains(roomId);
  @override
  Future<void> replyInThread(String roomId, String rootId, String text) async =>
      rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: text, time: now, mine: true, kind: 'text', threadRoot: rootId));
  @override
  Future<void> reply(String roomId, String toId, String text) async =>
      rooms[roomId]!.add(Msg(id: _id(), sender: _me!, body: text, time: now, mine: true, kind: 'text', replyTo: toId, postAs: sendAs[roomId]));
  @override
  Future<void> replyQuote(String roomId, String toId, String text, {required String quote, String quoteName = ''}) async {
    // Same limits as the engine (engine/src/lib.rs read_quote).
    final q = quote.trim().characters.take(1024).toString();
    final n = quoteName.trim().characters.take(64).toString();
    rooms[roomId]!.add(
      Msg(
        id: _id(),
        sender: _me!,
        body: text,
        time: now,
        mine: true,
        kind: 'text',
        replyTo: toId.isEmpty ? null : toId,
        quote: q.isEmpty ? null : q,
        quoteName: toId.isEmpty && q.isNotEmpty && n.isNotEmpty ? n : null,
      ),
    );
  }

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
  String? get normalPw => lk.normalPw;
  set normalPw(String? v) => lk.normalPw = v;
  String? get hidePw => lk.hidePw;
  set hidePw(String? v) => lk.hidePw = v;
  String? get deletePw => lk.deletePw;
  set deletePw(String? v) => lk.deletePw = v;
  String? get accountPw => lk.accountPw;
  set accountPw(String? v) => lk.accountPw = v;
  int get fails => lk.fails;
  set fails(int v) => lk.fails = v;
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
        : password == accountPw
        ? 'account'
        : null;
    fails = r == null ? fails + 1 : 0;
    if (r == null && fails >= wipeN) {
      fails = 0;
      await eraseEverything();
    }
    return r;
  }

  int get wipeN => lk.wipeN;
  set wipeN(int v) => lk.wipeN = v;
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

  /// Hidden notes I sent (tests read them) and notes waiting for me.
  final sentSignals = <(String, String, Map<String, dynamic>)>[];
  final incomingSignals = <Signal>[];
  bool get erasedAll => wiped > 0;

  /// 보내는 이름 picked per chat (tips 472 + 310).
  final sendAs = <String, PostAs>{};
  @override
  void setSendAs(String roomId, PostAs? as) => as == null ? sendAs.remove(roomId) : sendAs[roomId] = as;

  /// Channels whose admins the fake server knows: channel -> admin ids.
  final channelAdmins = <String, Set<String>>{};
  @override
  Future<bool> checkSendAs(String channel, String userId, String inRoom) async =>
      (channelAdmins[channel]?.contains(userId) ?? false) || (userId == _me && channels.contains(channel) && owner);

  /// 정지 (rule 13): the fake server's pause for me (null = not paused).
  Suspension? paused;
  final appeals = <String>[];
  @override
  Future<Suspension?> suspension() async => paused ?? const Suspension();
  @override
  Future<void> appeal(String text) async {
    final p = paused;
    if (p == null || !p.suspended) throw StateError('not suspended');
    if (p.appeal == 'waiting') throw StateError('an appeal is already waiting');
    appeals.add(text.trim());
    paused = Suspension(suspended: true, until: p.until, reason: p.reason, appeal: 'waiting');
  }

  @override
  Future<void> sendSignal(String roomId, String kind, Map<String, dynamic> data) async => sentSignals.add((roomId, kind, data));

  /// Files "encrypted" by [uploadSecret] (the demo keeps them in memory).
  final secrets = <String, List<int>>{};

  @override
  Future<String> uploadSecret(List<int> bytes) async {
    final f = jsonEncode({'url': 'demo://secret/${secrets.length + 1}', 'key': 'demo'});
    secrets[f] = List.of(bytes);
    return f;
  }

  @override
  Future<List<int>> downloadSecret(String file) async => secrets[file] ?? (throw StateError('no file'));

  @override
  List<Signal> takeSignals() {
    final out = List.of(incomingSignals);
    incomingSignals.clear();
    return out;
  }

  /// Drafts "my other device" sent (tests and the preview fill this), and
  /// what this device sent to them.
  final draftsIn = <SyncedDraft>[];
  final draftsOut = <SyncedDraft>[];

  /// Pretend I'm also logged in on a PC (drafts go there).
  bool otherDevice = true;

  @override
  Future<bool> sendMyDraft(String roomId, String text, DateTime at) async {
    if (!otherDevice) return false;
    draftsOut.add(SyncedDraft(roomId, text, at));
    return true;
  }

  @override
  Future<List<SyncedDraft>> takeSyncedDrafts() async {
    final out = List.of(draftsIn);
    draftsIn.clear();
    return out;
  }

  final savedBlobs = <String, List<int>>{};

  @override
  Future<void> saveBlob(String name, List<int> data) async {
    if (data.length > 300 * 1024) throw StateError('too big');
    savedBlobs[name] = List.of(data);
  }

  @override
  Future<List<int>?> blob(String name) async => savedBlobs[name];

  @override
  Future<void> dropBlob(String name) async => savedBlobs.remove(name);

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
    if (password != null && [normalPw, hidePw, deletePw, accountPw].contains(password)) throw StateError('used');
    switch (role) {
      case 'hide':
        hidePw = password;
      case 'account':
        accountPw = password;
      default:
        deletePw = password;
    }
  }

  @override
  Future<List<bool>> extrasSet(String normal) async {
    if (normal != normalPw) throw StateError('wrong');
    return [hidePw != null, deletePw != null, accountPw != null];
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

  /// Look-only demo: calls to these chats go unanswered after a few
  /// seconds, so 음성 남기기 / 영상 남기기 can be tried without the 45-second
  /// ring. Empty unless a demo sample adds a chat.
  final unansweredCalls = <String>{};
  Duration unansweredAfter = const Duration(seconds: 6);
  final _ringingSince = <String, DateTime>{};

  @override
  Future<String> startCall(String roomId, {required bool video}) async {
    if (channels.contains(roomId)) throw StateError('no calls in channels');
    final id = 'call${_n++}';
    if (unansweredCalls.contains(roomId)) _ringingSince[id] = DateTime.now();
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
    final since = _ringingSince[callId];
    if (since != null && DateTime.now().difference(since) >= unansweredAfter) {
      _ringingSince.remove(callId);
      await hangupCall(roomId, callId, 'missed');
    }
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
        until: hours == 0 ? null : DateTime.now().add(Duration(hours: const {6, 12, 48}.contains(hours) ? hours : 24)),
      ),
    );
    lastStoryOnly = only;
    lastStoryHours = hours;
    return friends;
  }

  /// Group / channel admin stories posted here (tip 428): room -> count.
  final roomStoryCount = <String, int>{};

  @override
  Future<StoryPosted> postStories({
    required String mime,
    required List<int> bytes,
    String caption = '',
    List<String> only = const [],
    int hours = 24,
    List<String> extras = const [],
    String room = '',
  }) async {
    final member = room.startsWith(memberStoryPrefix);
    if (member) room = room.substring(memberStoryPrefix.length);
    if (room.isNotEmpty) {
      if (!groups.contains(room)) throw StateError('not a group');
      if (member && channels.contains(room)) throw StateError('channels have no member stories');
      if (!member && await myRole(room) == 'member') throw StateError('only admins');
    }
    final friends = room.isNotEmpty ? 1 : rooms.keys.where((r) => !groups.contains(r) && r != saved && (only.isEmpty || only.contains(r))).length;
    if (friends == 0) throw StateError('no friends yet');
    final ids = <String>[];
    final file = 'storyfile${storyList.length}';
    files[file] = bytes;
    final now = DateTime.now();
    for (final extra in extras.isEmpty ? const [''] : extras) {
      final id = 'story${storyList.length}';
      storyList.add(
        Story(
          id: id,
          roomId: room,
          eventId: file,
          sender: _me ?? '@me:test',
          mine: true,
          time: now,
          kind: mime.isEmpty ? 'text' : (mime.startsWith('video/') ? 'video' : 'image'),
          caption: caption.trim().isEmpty ? null : caption.trim(),
          extra: extra.isEmpty ? null : extra,
          feed: hours == 0,
          until: hours == 0 ? null : now.add(Duration(hours: const {6, 12, 48}.contains(hours) ? hours : 24)),
          group: room.isNotEmpty,
          member: member,
        ),
      );
      ids.add(id);
    }
    if (room.isNotEmpty && !member) roomStoryCount[room] = (roomStoryCount[room] ?? 0) + 1;
    lastStoryOnly = only;
    lastStoryHours = hours;
    return StoryPosted(friends, ids);
  }

  /// Who each of my stories went to (tests check a narrowed audience).
  final storyAudience = <String, List<String>>{};

  @override
  Future<int> editStory(
    String id, {
    String mime = '',
    List<int> bytes = const [],
    String caption = '',
    String extra = '',
    List<String> only = const [],
    String? pin,
  }) async {
    final i = storyList.indexWhere((x) => x.id == id && x.mine);
    if (i < 0) throw StateError('no such story');
    final x = storyList[i];
    if (pin == null && !(x.until?.isAfter(DateTime.now()) ?? false)) throw StateError('story ended');
    var eventId = x.eventId;
    var kind = x.kind;
    if (bytes.isNotEmpty) {
      eventId = 'storyfile-edit-$id-${DateTime.now().microsecondsSinceEpoch}';
      files[eventId] = bytes;
      kind = mime.startsWith('video/') ? 'video' : 'image';
    }
    storyList[i] = Story(
      id: x.id,
      roomId: x.roomId,
      eventId: eventId,
      sender: x.sender,
      mine: true,
      time: x.time,
      kind: kind,
      caption: caption.trim().isEmpty ? null : caption.trim(),
      extra: extra.isEmpty ? null : extra,
      until: x.until,
      pin: pin,
      edited: true,
      group: x.group,
      member: x.member,
    );
    final friends = x.group ? 1 : rooms.keys.where((r) => !groups.contains(r) && r != saved && (only.isEmpty || only.contains(r))).length;
    storyAudience[id] = only;
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
    PollExtras extras = const PollExtras(),
  }) async {
    // Blank rows are dropped together with their attachments.
    final kept = [
      for (var i = 0; i < options.length; i++)
        if (options[i].trim().isNotEmpty) i,
    ];
    final opts = [for (final i in kept) options[i].trim()];
    if (question.trim().isEmpty || opts.length < 2 || opts.length > 10) throw ArgumentError('poll');
    if (quiz != null && (quiz < 0 || quiz >= opts.length)) throw ArgumentError('quiz');
    if (explain.length > 200) throw ArgumentError('explain');
    if (extras.description.length > 1024) throw ArgumentError('description');
    final id = _id();
    PollAttachment? att(int i) => i < extras.attachments.length ? extras.attachments[i] : null;
    if (extras.photo != null) pollPhotos['$id|'] = extras.photo!.bytes;
    for (var n = 0; n < kept.length; n++) {
      final a = att(kept[n]);
      if (a?.photo != null) pollPhotos['$id|a$n'] = a!.photo!.bytes;
    }
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: question,
        time: now,
        mine: true,
        kind: 'poll',
        poll: PollInfo(
          question: question,
          options: [
            for (var n = 0; n < opts.length; n++)
              PollOption('a$n', opts[n], 0, const [], att(kept[n])?.photo != null, att(kept[n])?.sticker ?? '', att(kept[n])?.geo ?? ''),
          ],
          anonymous: anonymous || channels.contains(roomId),
          multiple: multiple && quiz == null,
          correct: quiz == null ? null : 'a$quiz',
          explain: quiz == null ? '' : explain.trim(),
          closeAt: closeAt,
          description: extras.description.trim(),
          hasPhoto: extras.photo != null,
          addOptions: extras.addOptions && !channels.contains(roomId),
          changeVote: extras.changeVote && quiz == null,
          shuffle: extras.shuffle,
          hideResults: extras.hideResults,
        ),
      ),
    );
  }

  /// Poll photos by `poll|answer id` (empty answer id = under the question).
  final pollPhotos = <String, List<int>>{};

  @override
  Future<List<int>> pollPhoto(String roomId, String pollId, String slot) async => pollPhotos['$pollId|$slot'] ?? const [];

  @override
  Future<void> addPollOption(String roomId, String pollId, String text) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == pollId);
    final m = l[i];
    final p = m.poll!;
    final t = text.trim();
    if (!p.addOptions || p.closedAt(now)) throw StateError('closed');
    if (t.isEmpty || t.length > 100) throw ArgumentError('text');
    if (p.options.length >= 12) throw StateError('full');
    if (p.options.any((o) => o.text.toLowerCase() == t.toLowerCase())) throw StateError('repeat');
    l[i] = m.copyWith(poll: p.copyWith(options: [...p.options, PollOption(_id(), t, 0, const [], false, '', '', _me!)]));
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
    l[i] = m.copyWith(
      poll: p.copyWith(
        options: [
          for (final o in p.options)
            o.withVotes(
              all.values.where((c) => c.contains(o.id)).length,
              p.anonymous
                  ? const []
                  : [
                      for (final e in all.entries)
                        if (e.value.contains(o.id)) e.key,
                    ],
            ),
        ],
        closed: closed ?? p.closed,
        voters: all.values.where((c) => c.isNotEmpty).length,
        mine: my,
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
    // A quiz answer (or a poll with changes off) is final.
    if ((p.isQuiz || !p.changeVote) && p.mine.isNotEmpty) throw StateError('answered');
    _repoll(roomId, pollId, choices);
  }

  @override
  Future<void> closePoll(String roomId, String pollId) async => _repoll(roomId, pollId, null, closed: true);

  /// Card answers kept by the maker: card id -> person -> answer.
  final cardBooks = <String, Map<String, Object?>>{};

  /// Opened import cards (the engine keeps them in its encrypted store).
  final importCache = <String, ImportedChat>{};

  @override
  Future<ImportedChat> importedMessages(String roomId, String cardId) async {
    final hit = importCache[cardId];
    if (hit != null) return hit;
    final m = rooms[roomId]!.firstWhere((m) => m.id == cardId);
    final c = m.card;
    if (c == null || c.kind != 'import') throw StateError('not an import');
    final parts = <Map<String, Object?>>[];
    for (final p in c.listOf('parts')) {
      final bytes = await downloadEncrypted(jsonEncode(p['file']));
      parts.add((jsonDecode(utf8.decode(GZipDecoder().decodeBytes(bytes))) as Map).cast<String, Object?>());
    }
    // Only the importer (and the other person of a 1:1) stand behind words.
    final direct = groups.contains(roomId) ? null : peers[roomId];
    final who = <int, String>{
      for (final e in (c.data['who'] is Map ? (c.data['who'] as Map).entries : const <MapEntry>[]))
        if (e.value == m.sender || e.value == direct) int.parse('${e.key}'): '${e.value}',
    };
    final out = demoAssembleImport(parts, m.time.millisecondsSinceEpoch, who);
    return importCache[cardId] = ImportedChat.fromJson({...out, 'app': c.data['app'], 'title': c.data['title'], 'by': m.sender});
  }

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
      'flow' =>
        c.data['stats'] == true &&
            answer is String &&
            RegExp(r'^r(0|[1-9]\d*)$').hasMatch(answer) &&
            int.parse(answer.substring(1)) < c.listOf('results').length,
      _ => answer is List && answer.length == c.listOf('questions').length,
    };
    if (!ok) throw ArgumentError('answer');
    final book = cardBooks.putIfAbsent(cardId, () => {});
    // Choice flows keep a one-way code, never the person's ID (like the engine).
    final who = c.kind == 'flow' ? 'flow:${Object.hash(cardId, _me).toRadixString(16)}' : _me!;
    answer == null ? book.remove(who) : book[who] = answer;
    _recard(roomId, cardId, (p) => CardInfo(kind: p.kind, data: p.data, counts: _counts(p.kind, book), winners: p.winners, closed: p.closed, mine: answer));
  }

  /// Encrypted uploads: reference url -> bytes (the demo keeps them in memory).
  final blobs = <String, List<int>>{};

  @override
  Future<String> uploadEncrypted(List<int> bytes) async {
    final url = 'mxc://burumy.demo/${blobs.length + 1}';
    blobs[url] = bytes;
    return jsonEncode({
      'url': url,
      'key': {
        'kty': 'oct',
        'key_ops': ['encrypt', 'decrypt'],
        'alg': 'A256CTR',
        'k': 'demo',
        'ext': true,
      },
      'iv': 'demo',
      'hashes': {'sha256': 'demo'},
      'v': 'v2',
    });
  }

  @override
  Future<List<int>> downloadEncrypted(String fileJson) async {
    final f = Doc.cleanFile(jsonDecode(fileJson));
    final b = blobs[f?['url']];
    if (b == null) throw StateError('no file');
    return b;
  }

  @override
  Future<String> sendArticle(String roomId, Map<String, Object?> doc) async {
    final clean = Doc.clean(doc);
    if ((clean['blocks'] as List).isEmpty && (clean['title'] as String).isEmpty) throw ArgumentError('empty');
    final raw = jsonEncode(clean);
    final Map<String, Object?> data;
    if (utf8.encode(raw).length <= DocLimits.inline) {
      data = {'doc': clean};
    } else {
      final file = jsonDecode(await uploadEncrypted(utf8.encode(raw))) as Map<String, Object?>;
      final d = Doc.fromJson(clean);
      data = {'file': file, 'preview': articlePreview(clean), 'size': raw.length, 'chars': d.chars, 'images': d.blocks.where((b) => b.t == 'img').length};
    }
    final id = _id();
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: articleBody(data),
        time: now,
        mine: true,
        kind: 'card',
        card: CardInfo(kind: 'article', data: data),
      ),
    );
    return id;
  }

  @override
  Future<Map<String, Object?>> openArticle(String roomId, String eventId) async {
    final c = rooms[roomId]!.firstWhere((m) => m.id == eventId).card!;
    if (c.data['doc'] != null) return Doc.clean(c.data['doc']);
    final bytes = await downloadEncrypted(jsonEncode(c.data['file']));
    return Doc.clean(jsonDecode(utf8.decode(bytes)));
  }

  @override
  Future<List<CardAnswer>> cardAnswers(String roomId, String cardId) async {
    final m = rooms[roomId]!.firstWhere((m) => m.id == cardId);
    if (!m.mine) throw StateError('not maker');
    if (m.card?.kind == 'flow') throw StateError('numbers only');
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
  Future<String> createMeetup(String roomId, String title, DateTime startsAt, String place, {DateTime? endsAt}) async {
    if (title.trim().isEmpty) throw ArgumentError('meetup');
    final id = _id();
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: title.trim(),
        time: now,
        mine: true,
        kind: 'meetup',
        meetup: MeetupInfo(
          title: title.trim(),
          startsAt: startsAt,
          endsAt: endsAt != null && endsAt.isAfter(startsAt) ? endsAt : null,
          place: place.trim().isEmpty ? null : place.trim(),
        ),
      ),
    );
    return id;
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
      final plus = RegExp(r'^yes\+([1-9])$').firstMatch(answer);
      final base = plus != null ? 'yes' : answer;
      List<String> put(List<String> l, String a) => [...l.where((u) => u != me), if (base == a) me];
      final guests = {...p.guests}..remove(me);
      if (plus != null) guests[me] = int.parse(plus.group(1)!);
      return p.copyWith(yes: put(p.yes, 'yes'), no: put(p.no, 'no'), maybe: put(p.maybe, 'maybe'), guests: guests);
    });
  }

  @override
  Future<void> cancelMeetup(String roomId, String meetupId) async {
    if (!rooms[roomId]!.firstWhere((m) => m.id == meetupId).mine) return;
    _replan(roomId, meetupId, (p) => p.copyWith(cancelled: true));
  }

  @override
  Future<void> sendLocation(String roomId, double lat, double lon, double? accuracy) async {
    final u = accuracy == null ? '' : ';u=${accuracy.round()}';
    rooms[roomId]!.add(
      Msg(id: _id(), sender: _me!, body: 'geo:${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}$u', time: now, mine: true, kind: 'location'),
    );
  }

  String _geo(double lat, double lon, double? accuracy) =>
      'geo:${lat.toStringAsFixed(6)},${lon.toStringAsFixed(6)}${accuracy == null ? '' : ';u=${accuracy.round()}'}';

  @override
  Future<String> sendLiveLocation(String roomId, double lat, double lon, double? accuracy, DateTime until) async {
    final id = _id();
    rooms[roomId]!.add(
      Msg(id: id, sender: _me!, body: '${_geo(lat, lon, accuracy)};live=${until.millisecondsSinceEpoch}', time: now, mine: true, kind: 'location'),
    );
    return id;
  }

  @override
  Future<void> updateLiveLocation(String roomId, String messageId, double lat, double lon, double? accuracy, DateTime until) async {
    final l = rooms[roomId]!;
    final i = l.indexWhere((m) => m.id == messageId);
    if (i < 0) return;
    final m = l[i];
    l[i] = Msg(
      id: m.id,
      sender: m.sender,
      body: '${_geo(lat, lon, accuracy)};live=${until.millisecondsSinceEpoch}',
      time: m.time,
      mine: true,
      kind: 'location',
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

  /// Story link cards the demo "reads" (url → card); others get the site name.
  final storyLinks = <String, StoryLinkInfo>{};
  @override
  Future<StoryLinkInfo?> storyLinkCard(String url) async {
    if (!previewsOn) return null;
    final known = storyLinks[url];
    if (known != null) return known;
    final host = Uri.tryParse(url)?.host.replaceFirst(RegExp(r'^www\.'), '') ?? '';
    return host.isEmpty ? null : StoryLinkInfo(title: host, site: host);
  }

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
  Future<List<Found>> searchEverywhere(String term, {String kind = 'text', int limit = 300}) async {
    final out = <Found>[
      for (final e in rooms.entries)
        if (!quiet(e.key))
          for (final m in e.value)
            if (!unseen(m.id) && (m.expiresAt == null || m.expiresAt!.isAfter(clock)) && searchHit(m, kind, term)) Found(e.key, m),
    ]..sort((a, b) => b.msg.time.compareTo(a.msg.time));
    return out.take(limit).toList();
  }

  /// Public posts of web-page channels in the look-only demo.
  final publicPosts = <PublicPost>[];

  @override
  Future<List<LinkPeek>> searchPublicRooms(String term, {bool channelsOnly = false}) async {
    final t = term.trim().replaceFirst('@', '').toLowerCase();
    if (t.length < 2) return const [];
    final all = <LinkPeek>[
      for (final e in outside.entries)
        LinkPeek(
          roomId: e.value.roomId,
          address: e.key,
          name: e.value.name,
          about: e.value.about,
          members: e.value.members,
          channel: e.value.channel,
          approval: e.value.approval,
          joined: rooms.containsKey(e.value.roomId),
        ),
      for (final e in links.entries)
        if (e.value.public && rooms.containsKey(e.key))
          LinkPeek(
            roomId: e.key,
            address: e.value.code,
            name: names[e.key] ?? '',
            about: abouts[e.key] ?? '',
            members: (await members(e.key)).length,
            channel: channels.contains(e.key),
            joined: true,
          ),
    ];
    return [
      for (final p in all)
        if ((!channelsOnly || p.channel) && (p.name.toLowerCase().contains(t) || p.address.contains(t) || p.about.toLowerCase().contains(t))) p,
    ]..sort((a, b) => b.members.compareTo(a.members));
  }

  @override
  Future<List<PublicPost>> searchPublicPosts(String term) async {
    final words = term.trim().toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (term.trim().length < 2) return const [];
    return [
      for (final p in publicPosts)
        if (words.every(p.text.toLowerCase().contains)) p,
    ]..sort((a, b) => b.time.compareTo(a.time));
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
  Future<int> setEmojiStatus(String emoji, DateTime? until) async {
    if (emoji.isEmpty) {
      statuses.remove(_me);
    } else {
      statuses[_me ?? ''] = EmojiStatus(emoji, until);
    }
    return names.keys.where((r) => !groups.contains(r)).length;
  }

  /// 이모지 상태 per person (demo: friends' statuses are set by the samples).
  final statuses = <String, EmojiStatus>{};

  @override
  Future<EmojiStatus?> emojiStatusOf(String userId) async {
    final st = statuses[userId];
    return st != null && st.liveAt(DateTime.now()) ? st : null;
  }

  @override
  Future<void> setMyBio(String text) async => text.isEmpty ? bios.remove(userId) : bios[userId ?? ''] = text;
  @override
  Future<String> bioOf(String userId) async => bios[userId] ?? '';
  @override
  Future<List<int>?> myPhoto() async => photo;
  @override
  Future<void> setMyPhoto(String mime, List<int> bytes) async => photo = bytes.isEmpty ? null : bytes;

  /// What I last shared, and each person's card (look-only demo).
  final cards = <String, ProfileCard>{};
  Map<String, String> shared = {};
  @override
  Future<int> shareProfile({
    required String mime,
    required List<int> photo,
    required String bio,
    required String birthday,
    required String whoPhoto,
    required String whoBio,
    required String whoBirthday,
    List<String> only = const [],
  }) async {
    shared = {'photo': whoPhoto, 'bio': whoBio, 'birthday': whoBirthday, 'birthdayValue': birthday};
    if (only.isEmpty) {
      this.photo = whoPhoto == 'everyone' && photo.isNotEmpty ? photo : null;
      await setMyBio(whoBio == 'everyone' ? bio : '');
    }
    return 1;
  }

  @override
  Future<ProfileCard> profileOf(String userId) async => cards[userId] ?? ProfileCard(bio: bios[userId] ?? '');
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
      if (contactsOnly.contains(u)) {
        final b = blockedInvites.putIfAbsent(roomId, () => []);
        if (!b.contains(u)) b.add(u);
        continue;
      }
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
  Future<void> setMemberLevel(String roomId, String userId, int level) async {
    const roles = {-1: 'muted', 0: 'member', 50: 'admin', 100: 'owner'};
    if (!roles.containsKey(level)) throw ArgumentError('level');
    await _editMembers(
      roomId,
      (l) => [for (final m in l) m.userId == userId ? Member(userId: m.userId, name: m.name, role: roles[level]!, since: m.since) : m],
    );
  }

  @override
  Future<bool> roomSwitch(String roomId, String key) async => switches['$roomId/$key'] ?? false;
  @override
  Future<void> setRoomSwitch(String roomId, String key, bool on) async => switches['$roomId/$key'] = on;
  // Invite links: address or code per room, approval, web page; links of
  // rooms this phone is not in (for trying a link in the demo).
  final links = <String, RoomLink>{};
  final requests = <String, List<JoinRequest>>{};
  final outside = <String, LinkPeek>{};
  final webPages = <String, List<String>>{};
  var _codes = 0;

  Future<void> _admin(String roomId) async {
    if (await myRole(roomId) == 'member') throw StateError('admins only');
  }

  @override
  Future<RoomLink> roomLink(String roomId) async => links[roomId] ?? const RoomLink();

  @override
  Future<bool> addressFree(String roomId, String address) async {
    final a = address.trim().toLowerCase();
    if (!RegExp(r'^[a-z][a-z0-9_]{4,31}$').hasMatch(a) || a.endsWith('_') || a.contains('__') || a.startsWith('j_')) {
      throw ArgumentError('address');
    }
    if (const ['admin', 'burumy', 'official', 'support', 'help'].any((w) => a == w || a.startsWith('${w}_'))) throw ArgumentError('reserved');
    final owner = links.entries.where((e) => e.value.public && e.value.code == a).map((e) => e.key).firstOrNull;
    return (owner == null || owner == roomId) && !outside.containsKey(a);
  }

  @override
  Future<RoomLink> setPublicLink(String roomId, String address) async {
    await _admin(roomId);
    if (!await addressFree(roomId, address)) throw StateError('taken');
    final old = await roomLink(roomId);
    return links[roomId] = RoomLink(kind: 'public', code: address.trim().toLowerCase(), approval: old.approval, web: old.web);
  }

  @override
  Future<RoomLink> newPrivateLink(String roomId) async {
    await _admin(roomId);
    final old = await roomLink(roomId);
    webPages.remove(roomId);
    _codes++;
    final code = 'k${roomId.hashCode.abs()}x$_codes'.padRight(26, 'q').substring(0, 26).toLowerCase();
    return links[roomId] = RoomLink(kind: 'private', code: code, approval: old.approval);
  }

  @override
  Future<void> setLinkApproval(String roomId, bool on) async {
    await _admin(roomId);
    final old = await roomLink(roomId);
    links[roomId] = RoomLink(kind: old.kind, code: old.code, approval: on, web: old.web);
  }

  @override
  Future<LinkPeek> peekAddress(String address) async {
    final a = address.trim().toLowerCase();
    if (outside[a] case final p?) {
      // A public room's photo comes with the peek (as on the real server).
      final ph = roomPhotos[p.roomId];
      if (ph == null) return p;
      return LinkPeek(
        roomId: p.roomId,
        name: p.name,
        about: p.about,
        members: p.members,
        channel: p.channel,
        approval: p.approval,
        joined: p.joined,
        photo: ph,
      );
    }
    final mine = links.entries.where((e) => e.value.public && e.value.code == a).firstOrNull;
    if (mine == null) throw StateError('not found');
    final id = mine.key;
    return LinkPeek(
      roomId: id,
      name: names[id] ?? id,
      about: abouts[id] ?? '',
      members: (await members(id)).length,
      channel: channels.contains(id),
      approval: mine.value.approval,
      joined: rooms.containsKey(id),
      photo: roomPhotos[id],
    );
  }

  /// Extra invite links per room (tip 253); the demo plays the server:
  /// ended / full / cancelled links are refused, joins are counted.
  final inviteLinkMap = <String, List<InviteLink>>{};
  final mainUses = <String, (int, List<String>)>{};

  @override
  Future<List<InviteLink>> inviteLinks(String roomId) async => [...?inviteLinkMap[roomId]]..sort((a, b) => b.made.compareTo(a.made));

  @override
  Future<InviteLink> makeInviteLink(String roomId, {String name = '', DateTime? until, int max = 0}) async {
    await _admin(roomId);
    if (until != null && !until.isAfter(DateTime.now())) throw ArgumentError('ends in the past');
    _codes++;
    final code = 'x${roomId.hashCode.abs()}n$_codes'.padRight(26, 'w').substring(0, 26).toLowerCase();
    final l = InviteLink(
      code: code,
      name: name.trim().characters.take(32).toString(),
      until: until,
      max: max.clamp(0, 99999),
      by: _me ?? '',
      made: DateTime.now(),
    );
    (inviteLinkMap[roomId] ??= []).add(l);
    return l;
  }

  InviteLink _inviteOf(String roomId, String code) => inviteLinkMap[roomId]!.firstWhere((l) => l.code == code);

  void _putInvite(String roomId, InviteLink l) {
    final list = inviteLinkMap[roomId]!;
    list[list.indexWhere((x) => x.code == l.code)] = l;
  }

  @override
  Future<InviteLink> editInviteLink(String roomId, String code, {String name = '', DateTime? until, int max = 0}) async {
    await _admin(roomId);
    final l = _inviteOf(
      roomId,
      code,
    ).copyWith(name: name.trim().characters.take(32).toString(), until: until, clearUntil: until == null, max: max.clamp(0, 99999));
    _putInvite(roomId, l);
    return l;
  }

  @override
  Future<void> revokeInviteLink(String roomId, String code) async => _putInvite(roomId, _inviteOf(roomId, code).copyWith(revoked: true));

  @override
  Future<void> restoreInviteLink(String roomId, String code) async => _putInvite(roomId, _inviteOf(roomId, code).copyWith(revoked: false));

  @override
  Future<void> deleteInviteLink(String roomId, String code) async => inviteLinkMap[roomId]?.removeWhere((l) => l.code == code);

  @override
  Future<(int, List<String>)> mainLinkUses(String roomId) async => mainUses[roomId] ?? (0, const <String>[]);

  @override
  Future<(String, bool)> joinLink(String kind, String code) async {
    final c = code.trim().toLowerCase();
    final known = links.entries.where((e) => e.value.kind == kind && e.value.code == c).firstOrNull;
    if (known != null) return (known.key, false);
    for (final e in inviteLinkMap.entries) {
      final l = e.value.where((x) => x.code == c).firstOrNull;
      if (l == null || kind != 'private') continue;
      switch (l.state(DateTime.now())) {
        case 'ended':
          throw StateError('M_FORBIDDEN burumy: link expired');
        case 'full':
          throw StateError('M_FORBIDDEN burumy: link full');
        case 'revoked':
          throw StateError('M_NOT_FOUND');
      }
      if (rooms.containsKey(e.key)) return (e.key, false);
      _putInvite(e.key, l.copyWith(uses: l.uses + 1, joined: [...l.joined, _me ?? '']));
      rooms.putIfAbsent(e.key, () => []);
      return (e.key, false);
    }
    final p = kind == 'public' ? outside[c] : null;
    if (p != null) {
      if (p.approval) return (p.roomId, true);
      rooms.putIfAbsent(p.roomId, () => []);
      names[p.roomId] = p.name;
      abouts[p.roomId] = p.about;
      groups.add(p.roomId);
      if (p.channel) channels.add(p.roomId);
      outside[c] = LinkPeek(roomId: p.roomId, name: p.name, about: p.about, members: p.members + 1, channel: p.channel, joined: true);
      // Demo: the room greets me (the owner's phone sends its encrypted
      // welcome pack once I'm in).
      final w = welcomeOnJoin.remove(p.roomId);
      if (w != null) {
        roomMembers[p.roomId] = [Member(userId: _me!, name: await myName(), role: 'member', since: now), Member(userId: w.$2, name: p.name, role: 'owner')];
        roomConfigs[p.roomId] = {
          'texts': {'h': w.$3, 'w': true, 'r': (w.$1['rules'] as String? ?? '').isNotEmpty},
        };
        incomingSignals.add(Signal(roomId: p.roomId, id: '\$welcome-${p.roomId}', sender: w.$2, kind: 'room_texts', data: w.$1, time: now));
      }
      return (p.roomId, false);
    }
    throw StateError('link not found');
  }

  @override
  Future<List<JoinRequest>> joinRequests(String roomId) async => List.of(requests[roomId] ?? const []);

  @override
  Future<void> answerJoinRequest(String roomId, String userId, bool accept) async {
    await _admin(roomId);
    final r = requests[roomId]?.where((x) => x.userId == userId).firstOrNull;
    requests[roomId]?.removeWhere((x) => x.userId == userId);
    if (accept && r != null) await _editMembers(roomId, (l) => l..add(Member(userId: r.userId, name: r.name, role: 'member')));
  }

  // 가입 심사 도우미: the helper's rules run here (same as server/gate).
  final gateHelpers = <String, bool>{};
  final gateLogs = <String, List<GateEntry>>{};
  final knocks = <String, String>{};

  String? _linkRoom(String kind, String code) {
    final c = code.trim().toLowerCase();
    if (kind == 'public' && outside[c] != null) return outside[c]!.roomId;
    return links.entries.where((e) => e.value.kind == kind && e.value.code == c).firstOrNull?.key;
  }

  @override
  Future<List<GateQuestion>?> gateQuestions(String kind, String code) async {
    final id = _linkRoom(kind, code);
    final cfg = id == null ? null : roomConfigs[id];
    if (cfg == null || !GateSettings.from(cfg).on) return null;
    final qs = GateQuestion.listFrom(cfg);
    return qs.isEmpty ? null : [for (final q in qs) GateQuestion(q: q.q, choices: q.choices)];
  }

  @override
  Future<List<bool?>> gateCheck(String kind, String code, List<String> answers) async {
    final id = _linkRoom(kind, code);
    return gateRightWrong(GateQuestion.listFrom(roomConfigs[id] ?? const {}), answers);
  }

  @override
  Future<(String, bool)> joinLinkWith(String kind, String code, List<String> answers) async {
    final c = code.trim().toLowerCase();
    final p = kind == 'public' ? outside[c] : null;
    if (p == null || !p.approval) return joinLink(kind, code);
    final cfg = roomConfigs[p.roomId] ?? const {};
    final g = GateSettings.from(cfg);
    final v = g.on ? gateScreen(GateQuestion.listFrom(cfg), g, answers, name: 'me') : 'held';
    knocks[p.roomId] = switch (v) {
      'ok' => 'in',
      'quiz' || 'empty' || 'words' || 'fake' => 'no',
      _ => 'waiting',
    };
    if (v == 'ok') {
      rooms.putIfAbsent(p.roomId, () => []);
      names[p.roomId] = p.name;
      abouts[p.roomId] = p.about;
      groups.add(p.roomId);
      if (p.channel) channels.add(p.roomId);
      outside[c] = LinkPeek(roomId: p.roomId, name: p.name, about: p.about, members: p.members + 1, channel: p.channel, approval: true, joined: true);
    }
    return (p.roomId, true);
  }

  @override
  Future<String> knockState(String roomId) async => knocks[roomId] ?? 'unknown';

  @override
  Future<void> setGateHelper(String roomId, bool on) async {
    await _admin(roomId);
    gateHelpers[roomId] = on;
    if (!on) return;
    // The helper answers the requests already waiting.
    final cfg = roomConfigs[roomId] ?? const {};
    final g = GateSettings.from(cfg);
    final qs = GateQuestion.listFrom(cfg);
    for (final r in List.of(requests[roomId] ?? const <JoinRequest>[])) {
      final v = gateScreen(qs, g, r.answers, name: r.name);
      final entry = GateEntry(userId: r.userId, name: r.name, verdict: v, at: now);
      gateLogs.putIfAbsent(roomId, () => []).insert(0, entry);
      if (entry.kind == 'held') continue;
      requests[roomId]?.removeWhere((x) => x.userId == r.userId);
      if (entry.kind == 'in') await _editMembers(roomId, (l) => l..add(Member(userId: r.userId, name: r.name, role: 'member')));
    }
  }

  @override
  Future<GateHelper> gateHelper(String roomId) async => GateHelper(joined: gateHelpers[roomId] ?? false);

  @override
  Future<List<GateEntry>> gateLog(String roomId) async => List.of(gateLogs[roomId] ?? const []);

  @override
  Future<void> setWebPage(String roomId, bool on) async {
    await _admin(roomId);
    final old = await roomLink(roomId);
    if (on && !old.public) throw StateError('public link first');
    links[roomId] = RoomLink(kind: old.kind, code: old.code, approval: old.approval, web: on);
    if (!on) webPages.remove(roomId);
  }

  // ---- 커뮤니티 (demo copy of community.rs: same rules, no server) ----

  /// id -> [name, about, addAll, chats (room id -> hidden), role].
  final communityBook = <String, FakeCommunity>{};

  /// Chats of other people that are in a community I am in (not joined).
  final outsideChats = <String, CommunityChat>{};

  @override
  Future<List<Community>> communities() async => [
    for (final e in communityBook.entries)
      Community(
        id: e.key,
        name: e.value.name,
        about: e.value.about,
        role: e.value.role,
        addAll: e.value.addAll,
        members: e.value.members,
        chats: [
          for (final c in e.value.chats.entries)
            if (rooms.containsKey(c.key))
              CommunityChat(
                roomId: c.key,
                name: names[c.key] ?? c.key,
                channel: channels.contains(c.key),
                state: 'in',
                hidden: c.value,
                by: e.value.by[c.key] ?? _me ?? '',
                members: (roomMembers[c.key]?.length ?? 2),
              )
            else if (outsideChats[c.key] case final o?)
              CommunityChat(roomId: o.roomId, name: o.name, channel: o.channel, state: o.state, hidden: c.value, by: o.by, members: o.members),
        ],
      ),
  ];

  FakeCommunity _community(String id) => communityBook[id] ?? (throw StateError('unknown community'));
  void _communityAdmin(String id) {
    if (_community(id).role == 'member') throw StateError('admins only');
  }

  @override
  Future<String> createCommunity(String name, {String about = ''}) async {
    final n = name.trim();
    if (n.isEmpty || n.length > 64) throw ArgumentError('name');
    final id = '!community${communityBook.length}';
    communityBook[id] = FakeCommunity(name: n, about: about.trim(), role: 'owner');
    roomMembers[id] = [Member(userId: _me!, name: await myName(), role: 'owner')];
    return id;
  }

  @override
  Future<void> setCommunityInfo(String id, String name, String about) async {
    _communityAdmin(id);
    final n = name.trim();
    if (n.isEmpty || n.length > 64) throw ArgumentError('name');
    _community(id)
      ..name = n
      ..about = about.trim();
  }

  @override
  Future<void> addToCommunity(String id, String roomId, {bool hidden = false}) async {
    final c = _community(id);
    if (c.role == 'member' && !c.addAll) throw StateError('admins only');
    if (hidden && c.role == 'member') throw StateError('admins only');
    if (!groups.contains(roomId)) throw StateError('not a group');
    final role = await myRole(roomId);
    if (role != 'owner' && role != 'admin') throw StateError('only your own groups and channels');
    if (!c.chats.containsKey(roomId) && c.chats.length >= 100) throw StateError('full');
    // Same as the engine: a chat with no link gets a private one with approval.
    if ((await roomLink(roomId)).kind == 'none') {
      await newPrivateLink(roomId);
      await setLinkApproval(roomId, true);
    }
    c.chats[roomId] = hidden;
    c.by[roomId] = _me!;
    if (!hidden) await createCard(roomId, 'community', {'community': id, 'name': c.name, 'kind': channels.contains(roomId) ? 'channel' : 'group'});
  }

  @override
  Future<void> removeFromCommunity(String id, String roomId) async {
    final c = _community(id);
    if (c.role == 'member' && c.by[roomId] != _me) throw StateError('admins only');
    c.chats.remove(roomId);
  }

  @override
  Future<void> setCommunityChatHidden(String id, String roomId, bool hidden) async {
    _communityAdmin(id);
    final c = _community(id);
    if (!c.chats.containsKey(roomId)) throw StateError('not in this community');
    c.chats[roomId] = hidden;
  }

  @override
  Future<void> setCommunityAddAll(String id, bool all) async {
    _communityAdmin(id);
    _community(id).addAll = all;
  }

  @override
  Future<void> setCommunityAdmin(String id, String userId, bool on) async {
    _communityAdmin(id);
    await setAdmin(id, userId, on);
  }

  @override
  Future<(String, bool)> joinCommunityChat(String id, String roomId) async {
    final o = outsideChats[roomId];
    if (o == null || !_community(id).chats.containsKey(roomId)) throw StateError('not in this community');
    if (o.state == 'ask') {
      outsideChats[roomId] = CommunityChat(roomId: o.roomId, name: o.name, channel: o.channel, state: 'ask', by: o.by, members: o.members, hidden: o.hidden);
      asked.add(roomId);
      return (roomId, true);
    }
    rooms.putIfAbsent(roomId, () => []);
    names[roomId] = o.name;
    groups.add(roomId);
    if (o.channel) channels.add(roomId);
    outsideChats.remove(roomId);
    return (roomId, false);
  }

  /// Chats I asked to join through a community (demo: never answered).
  final asked = <String>{};

  @override
  Future<void> leaveCommunity(String id) async => communityBook.remove(id);

  @override
  Future<void> deleteCommunity(String id) async {
    if (_community(id).role != 'owner') throw StateError('owner only');
    communityBook.remove(id);
  }

  final roomConfigs = <String, Map<String, dynamic>>{};

  /// Demo rooms that send me their welcome when I join: (pack, owner, fingerprint).
  final welcomeOnJoin = <String, (Map<String, dynamic>, String, String)>{};
  final bannedUsers = <String, Set<String>>{};
  @override
  Future<Map<String, dynamic>> roomConfig(String roomId) async => Map.of(roomConfigs[roomId] ?? const {});
  @override
  Future<void> setRoomConfig(String roomId, String key, Object? value) async {
    // 1:1 chats: both people may change them (like the real server, where
    // both sides of a 1:1 get full rights).
    if (groups.contains(roomId) && await myRole(roomId) == 'member') throw StateError('admins only');
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

  /// 지난 메시지 보내기: what went to whom ("room|user" → how many), and
  /// packs other members sent me, by chat.
  final historySent = <String, int>{};
  final earlier = <String, List<Msg>>{};

  @override
  Future<int> sendHistory(String roomId, String userId, {int count = 50}) async {
    // Same as the engine: texts and files; never timer or view-once ones.
    const shown = {'text', 'image', 'video', 'audio', 'file'};
    final n = (rooms[roomId] ?? const []).where((m) => shown.contains(m.kind) && m.expiresAt == null && !m.viewOnce).length.clamp(0, count.clamp(0, 50));
    if (n == 0) throw StateError('nothing to send');
    historySent['$roomId|$userId'] = n;
    return n;
  }

  @override
  Future<List<Msg>> earlierMessages(String roomId) async => earlier[roomId] ?? const [];

  /// 'room|index' -> the file of an earlier photo / video / file.
  final earlierFiles = <String, List<int>>{};

  @override
  Future<List<int>> earlierFile(String roomId, int index, {bool thumb = false}) async => earlierFiles['$roomId|$index'] ?? (throw StateError('no file'));
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
  // ---- 사칭 막기 ----

  /// 아이디 키 proofs my 1:1 invitations carried, by person.
  final dmProofs = <String, String>{};
  TrustList trust = TrustList.empty;
  final trustAbouts = <String, TrustAbout>{};
  final reservedNames = <String>['iu', 'bts', 'sonheungmin', 'samsung', 'kakao'];
  final badgeApplications = <Map<String, String>>[];
  final impersonationReports = <List<String>>[];
  String? lastBadgeCode;
  String seenName = '';

  @override
  Future<TrustList> trustList() async => trust;
  @override
  Future<TrustAbout> trustAbout(String userId) async => trustAbouts[userId] ?? const TrustAbout();
  String seenPhoto = '';
  @override
  Future<void> trustSeen(String name, {String photo = ''}) async {
    seenName = name;
    seenPhoto = photo;
  }

  @override
  Future<String> nameCheck(String text, {bool displayName = false, bool room = false}) async {
    if (claimOpened != null && skeleton(claimOpened!) == skeleton(text)) return '';
    final v = checkName(text, who: _me, reserved: reservedNames, badges: trust.badges, displayName: displayName || room);
    if (v == 'reserved' && !displayName && !room && !ourWords.any((w) => skeleton(text).contains(skeleton(w)))) return 'reserved_owner';
    if (v == '' && !displayName && !room && text.trim().length <= 4) return 'reserved_sale';
    if (room && reservedNames.any((r) => nameCore(r) == nameCore(text))) return 'reserved_owner';
    return v;
  }

  /// The ID a claim code opened (demo: any code starting BRM- works).
  String? claimOpened;
  @override
  Future<void> claimOpen(String id, String code) async {
    if (!code.trim().toUpperCase().startsWith('BRM-')) throw StateError('wrong code');
    claimOpened = id;
  }

  @override
  Future<String> badgeCode() async => lastBadgeCode = 'burumy-7K2Q9M';
  @override
  Future<void> applyBadge({required String kind, required String name, required String proof}) async {
    if (lastBadgeCode == null) throw StateError('no code');
    badgeApplications.add({'kind': kind, 'name': name, 'proof': proof});
  }

  /// Demo: reported messages ([room, id, sender, reason, note]).
  final contentReports = <List<String>>[];

  @override
  Future<bool> reportContent(String roomId, String id, String sender, String reason, String note) async {
    contentReports.add([roomId, id, sender, reason, note]);
    // Demo: three "illegal" reports hide it (the real rule counts only
    // different, older accounts).
    if (reason == 'illegal' && contentReports.where((r) => r[1] == id && r[3] == 'illegal').length >= 3) {
      trust = TrustList(version: trust.version + 1, badges: trust.badges, flags: trust.flags, hidden: {...trust.hidden, id}, guard: trust.guard);
      return true;
    }
    return false;
  }

  @override
  Future<String> reportImpersonation(String userId, {String victim = '', String note = ''}) async {
    impersonationReports.add([userId, victim, note]);
    // Demo: three reports put '확인 중' on (the real rule counts only
    // different, older accounts).
    if (impersonationReports.where((r) => r[0] == userId).length >= 3 && trust.badgeOf(userId) == null) {
      trust = TrustList(
        version: trust.version + 1,
        badges: trust.badges,
        flags: {...trust.flags, userId: 'checking'},
        hidden: trust.hidden,
        guard: trust.guard,
      );
    }
    return trust.flags[userId] ?? '';
  }

  @override
  Future<void> setIdSearchHidden(bool on) async => idSearchHidden = on;

  /// Account privacy settings (tests read them).
  final privacy = <String, dynamic>{};
  @override
  Future<Map<String, dynamic>> accountPrivacy() async => {...privacy, 'no_id_search': ?(idSearchHidden ? true : null)};
  @override
  Future<void> setAccountPrivacy(String key, Object? value) async => value == null ? privacy.remove(key) : privacy[key] = value;

  /// QR로 PC 연결: vouched QR ids, shared by every FakeBackend in the app
  /// (so a test "phone" and "PC" can meet).
  static final pcVouched = <String>{};
  bool pcReady = true;
  @override
  bool get pcLinkReady => pcReady;
  @override
  Future<void> approvePcLogin(String rid) async {
    if (!loggedIn) throw StateError('not logged in');
    pcVouched.add(rid);
  }

  @override
  Future<bool> takePcLogin(String secret) async {
    final rid = sha256.convert(utf8.encode(secret)).toString();
    if (!pcVouched.remove(rid)) return false;
    await login(id: 'me', password: password);
    return true;
  }

  /// 그룹·채널 사진 per room (the real app sends it encrypted in the room).
  final roomPhotos = <String, Uint8List>{};
  @override
  Future<void> setRoomPhoto(String roomId, String mime, Uint8List? bytes) async {
    if (bytes == null || bytes.isEmpty) {
      if (roomPhotos.remove(roomId) == null) return;
    } else {
      roomPhotos[roomId] = bytes;
    }
    rooms[roomId]?.add(Msg(id: _id(), sender: _me!, body: bytes == null || bytes.isEmpty ? 'removed' : 'set', time: now, mine: true, kind: 'room_photo'));
  }

  @override
  Future<Uint8List?> roomPhoto(String roomId) async => roomPhotos[roomId];

  /// 멤버 태그 (556): tags people put on themselves, per room.
  final ownTags = <String, Map<String, String>>{};
  @override
  Future<void> setMyRoomTag(String roomId, String tag) async {
    final t = tag.trim();
    if (t.characters.length > 16) throw StateError('tag too long');
    final m = ownTags.putIfAbsent(roomId, () => {});
    t.isEmpty ? m.remove(_me) : m[_me!] = t;
  }

  @override
  Future<Map<String, String>> memberTags(String roomId) async => Map.of(ownTags[roomId] ?? const {});

  /// 누가 읽었는지 (384): (read up to, when) per member, per room.
  final groupReads = <String, Map<String, (DateTime, DateTime)>>{};
  @override
  Future<Map<String, (DateTime, DateTime)>> groupReceipts(String roomId) async {
    if (prefs['send_read'] == '0' || prefs['send_read:$roomId'] == '0') return const {};
    if ((roomMembers[roomId]?.length ?? 2) > 100) return const {};
    return Map.of(groupReads[roomId] ?? const {});
  }

  @override
  Future<bool> reshareRoomPhoto(String roomId) async => false;

  /// My name / name colour per room (the real app keeps them on my member event).
  final myColors = <String, String>{};
  @override
  Future<void> setMyRoomLook(String roomId, {String? name, String? color}) async {
    if (name != null) {
      final n = name.trim().isEmpty ? await myName() : name.trim();
      final ms = roomMembers[roomId] ?? await _defaultMembers(roomId);
      roomMembers[roomId] = [for (final m in ms) m.userId == _me ? Member(userId: m.userId, name: n, role: m.role, since: m.since) : m];
    }
    if (color != null) color.isEmpty ? myColors.remove(roomId) : myColors[roomId] = color;
  }

  @override
  Future<Map<String, String>> nameColors(String roomId) async => {...?demoColors[roomId], if (myColors[roomId] != null) _me!: myColors[roomId]!};

  /// Sample people's picks (the demo).
  final demoColors = <String, Map<String, String>>{};
  bool idSearchHidden = false;

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

  /// Demo people who only take invitations from contacts (tip 385): their
  /// "phones" turn the invitation down at once.
  final contactsOnly = <String>{};
  final blockedInvites = <String, List<String>>{};
  @override
  Future<void> declineBlocked(String roomId) => decline(roomId);
  @override
  Future<List<String>> invitesBlocked(String roomId) async {
    final now = await members(roomId);
    return [
      for (final u in blockedInvites[roomId] ?? const <String>[])
        if (!now.any((m) => m.userId == u)) u,
    ];
  }

  /// 움직이는 사진: still + clip kept here, like the real app's two files.
  final liveClips = <String, List<int>>{};

  @override
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
  }) async {
    final id = 'f${files.length}';
    files[id] = bytes;
    liveClips[id] = video;
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: name,
        time: now,
        mine: true,
        kind: 'image',
        caption: caption.trim().isEmpty ? null : caption.trim(),
        live: LiveInfo(style, duration),
      ),
    );
  }

  @override
  Future<List<int>> liveVideo(String roomId, String eventId) async => liveClips[eventId] ?? const [];

  @override
  Future<void> sendViewOnce(String roomId, {required String name, required String mime, required List<int> bytes}) async {
    final id = 'f${files.length}';
    files[id] = bytes;
    rooms[roomId]!.add(
      Msg(
        id: id,
        sender: _me!,
        body: name,
        time: now,
        mine: true,
        kind: mime.startsWith('video/') ? 'video' : (mime.startsWith('audio/') ? 'audio' : 'image'),
        viewOnce: true,
        // Unopened, it goes after a day (engine VIEW_ONCE_TTL).
        expiresAt: now.add(viewOnceLife),
      ),
    );
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

/// A community as the demo keeps it.
class FakeCommunity {
  FakeCommunity({required this.name, this.about = '', this.role = 'member', this.addAll = false, this.members = 1});
  String name;
  String about;
  String role;
  bool addAll;
  int members;

  /// Chat id -> hidden.
  final chats = <String, bool>{};
  final by = <String, String>{};
}

/// Short line for the chat list and notifications.
String cardBody(String kind, Map<String, Object?> d) => switch (kind) {
  'community' => '🏘️ ${d['name']}',
  'faq' => '❓ ${d['title'] is String && (d['title'] as String).isNotEmpty ? d['title'] : 'FAQ'}',
  'guide' => '🧭 ${d['title']}',
  'links' => '🔗 ${d['text']}',
  'rich' => '📝 ${d['title']}',
  'article' => articleBody(d),
  'lottery' => '🎁 ${d['prize']}',
  'form' => '📋 ${d['title']}',
  'flow' => '🧩 ${d['title']}',
  'pin' => '📌 ${d['text']}',
  'import' => '📥 ${d['title']} · ${d['count']}',
  'photo' => '🖼️',
  'suggest' => '✍️ ${d['text']}',
  'suggest_deal' => d['act'] == 'accept' ? '🤝' : '🙅',
  'stickers' => '🎨 ${d['name']}',
  'dice' => '${d['e']}',
  _ => '🛟 ${d['text']}',
};

/// Pin line preview: trimmed, at most 100 characters.
String pinText(Object? v) {
  final s = v is String ? v.trim() : '';
  return s.length > 100 ? s.substring(0, 100) : s;
}

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
    // 채널에 글 제안 (tip 531), as engine card.rs.
    'suggest' => need({
      'text': t(d['text'], 4000) ?? '',
      'photo': d['photo'] is String && (d['photo'] as String).isNotEmpty ? d['photo'] : null,
      'mime': d['photo'] is String && d['mime'] is String && (d['mime'] as String).startsWith('image/') ? d['mime'] : null,
      'at': d['at'] is int && (d['at'] as int) > now.millisecondsSinceEpoch ? d['at'] : 0,
      'channel': t(d['channel'], 255) ?? '',
    }, t(d['text'], 4000) != null || (d['photo'] is String && (d['photo'] as String).isNotEmpty)),
    'suggest_deal' => need({
      'to': d['to'],
      'act': d['act'],
      'at': d['at'] is int ? d['at'] : 0,
      'credit': d['credit'] == true,
      'note': t(d['note'], 200) ?? '',
    }, d['to'] is String && (d['act'] == 'accept' || d['act'] == 'decline')),
    'pin' => need({'id': d['id'], 'text': pinText(d['text']), 'notify': d['notify'] == true}, d['id'] is String),
    'import' => demoCheckImport(d),
    // 사진 제안 (tip 373): only the encrypted file's place + key.
    'photo' => need({'file': Doc.cleanFile(d['file']), 'mime': d['mime'] == 'image/png' ? 'image/png' : 'image/jpeg'}, Doc.cleanFile(d['file']) != null),
    // 스티커 묶음: same rules as engine/src/card.rs "stickers".
    'stickers' => need({
      'file': Doc.cleanFile(d['file']),
      'name': t(d['name'], 32) ?? '',
      'n': d['n'],
      'kind': d['kind'] == 'emoji' ? 'emoji' : 'sticker',
    }, Doc.cleanFile(d['file']) != null && t(d['name'], 32) != null && d['n'] is int && (d['n'] as int) >= 1 && (d['n'] as int) <= 50),
    'dice' => {
      'e': const ['🎲', '🎯', '🏀', '⚽', '🎳', '🎰'].contains(d['e']) ? d['e'] : '🎲',
    },
    'community' => need({
      'community': d['community'],
      'name': t(d['name'], 64) ?? '',
      'kind': d['kind'] == 'channel' ? 'channel' : 'group',
    }, d['community'] is String && (d['community'] as String).startsWith('!')),
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
    'flow' => () {
      final rs = list(d['results'], 8);
      final ss = list(d['steps'], 10);
      String? to(Object? v) {
        if (v is! String || !RegExp(r'^[sr](0|[1-9]\d*)$').hasMatch(v)) return null;
        final n = int.parse(v.substring(1));
        return n < (v[0] == 's' ? ss.length : rs.length) ? v : null;
      }

      final results = [
        for (final x in rs)
          {
            'title': t(x['title'], 100),
            'text': t(x['text'], 1000) ?? '',
            'link': x['link'] is Map && t((x['link'] as Map)['label'], 24) != null && url((x['link'] as Map)['url'])
                ? {'label': t((x['link'] as Map)['label'], 24), 'url': (x['link'] as Map)['url']}
                : null,
          },
      ];
      final steps = [
        for (final x in ss)
          {
            'q': t(x['q'], 200),
            'choices': [
              for (final c in list(x['choices'], 6))
                if (t(c['label'], 40) case final lb?)
                  if (to(c['to']) case final tt?) {'label': lb, 'to': tt},
            ],
          },
      ];
      final ok =
          t(d['title'], 100) != null &&
          steps.isNotEmpty &&
          results.isNotEmpty &&
          results.every((r) => r['title'] != null) &&
          steps.every((s) => s['q'] != null && (s['choices'] as List).isNotEmpty) &&
          flowReachesResult([
            for (final s in steps) [for (final c in s['choices'] as List) (c as Map)['to'] as String],
          ]);
      return need({
        'title': t(d['title'], 100),
        'text': t(d['text'], 1000) ?? '',
        'start': t(d['start'], 24) ?? '',
        'steps': steps,
        'results': results,
        'stats': d['stats'] is bool ? d['stats'] : true,
      }, ok);
    }(),
    _ => throw ArgumentError(kind),
  };
}

/// Short line for a long post (chat list, notifications, old apps).
String articleBody(Map<String, Object?> d) {
  final doc = Doc.fromJson(d['doc'] ?? d['preview']);
  if (doc.title.trim().isNotEmpty) return '📰 ${doc.title.trim()}';
  final first = doc.plain.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
  return '📰 ${first.length > 80 ? first.substring(0, 80) : first}';
}

/// The first few blocks of a long post, without photos (like the engine).
Map<String, Object?> articlePreview(Map<String, Object?> doc) {
  final d = Doc.fromJson(doc);
  var left = 700;
  final out = <DocBlock>[];
  for (final b in d.blocks) {
    if (out.length >= 6 || left <= 0) break;
    if (b.t == 'img' || b.t == 'hr') continue;
    final c = b.copy();
    if (b.t == 'table') {
      c.rows = c.rows.take(2).toList();
      left -= 100;
    } else if (b.isList) {
      c.items = c.items.take(3).toList();
      left -= 150;
    } else {
      if (c.text.length > left) c.text = c.text.substring(0, left);
      left -= b.text.length;
    }
    out.add(c);
  }
  return Doc(title: d.title, blocks: out).toJson();
}

/// Import card data, checked like engine/src/import.rs does.
Map<String, Object?> demoCheckImport(Map<String, Object?> d) {
  if (!const ['kakao', 'whatsapp', 'telegram'].contains(d['app'])) throw ArgumentError('app');
  final parts = [
    for (final p in (d['parts'] is List ? d['parts'] as List : const []))
      if (p is Map && Doc.cleanFile(p['file']) != null && p['n'] is int && (p['n'] as int) > 0 && (p['n'] as int) <= 10000)
        {'file': Doc.cleanFile(p['file']), 'n': p['n']},
  ];
  if (parts.isEmpty || parts.length > 40) throw ArgumentError('parts');
  final count = parts.fold<int>(0, (a, p) => a + (p['n'] as int));
  final who = <String, Object?>{
    for (final e in (d['who'] is Map ? (d['who'] as Map).entries : const <MapEntry>[]).take(2))
      if (int.tryParse('${e.key}') != null && '${e.value}'.startsWith('@') && '${e.value}'.contains(':')) '${e.key}': '${e.value}',
  };
  final from = d['from'] is int ? d['from'] as int : 0;
  final to = d['to'] is int ? d['to'] as int : 0;
  final title = '${d['title'] ?? ''}'.trim();
  return {
    'app': d['app'],
    'title': title.length > 100 ? title.substring(0, 100) : title,
    'count': count,
    'from': from,
    'to': to < from ? from : to,
    'media': d['media'] is int ? (d['media'] as int).clamp(0, count) : 0,
    'parts': parts,
    'who': who,
  };
}
