// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Backend on top of our Rust engine (through our own bindings).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show PlatformInt64Util;
import 'package:http/http.dart' as http;

import '../src/rust/api/device.dart';
import '../src/rust/api/lock.dart';
import 'backend.dart';

/// Call-pass service address comes from the build (never written in code).
const _callPass = String.fromEnvironment('BURUMY_CALL_PASS');

/// Where the login is kept between app starts. Phones use the system
/// keychain; tests use memory.
abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String? json);
}

/// Where the app lock file is kept (keychain on phones).
abstract class LockStore {
  Future<String?> read();
  Future<void> write(String? json);
}

class RustBackend implements Backend {
  RustBackend._(this._d, this._store, this._lock);
  final BurumyDevice _d;
  final SessionStore _store;
  final LockStore _lock;

  static Future<RustBackend> open({
    required String server,
    required String dataDir,
    required String storePassphrase,
    required SessionStore store,
    required LockStore lock,
    bool forgetBrokenSession = true,
  }) async {
    final d = await BurumyDevice.open(homeserver: server, dataDir: dataDir, storePassphrase: storePassphrase);
    final b = RustBackend._(d, store, lock);
    d.setTzOffset(minutes: DateTime.now().timeZoneOffset.inMinutes);
    final saved = await store.read();
    if (saved != null) {
      try {
        await d.restore(sessionJson: saved);
      } catch (e) {
        debugPrint('session restore failed: $e');
        if (forgetBrokenSession) await store.write(null);
      }
    }
    return b;
  }

  @override
  String? get userId => _d.userId();
  @override
  bool get loggedIn => _d.isLoggedIn();

  Future<void> _save() => _store.write(_d.sessionJson());

  @override
  Future<void> register({required String id, required String password, String? invite}) async {
    await _d.register(username: id, password: password, inviteCode: invite);
    await _save();
  }

  @override
  Future<void> login({required String id, required String password}) async {
    await _d.login(username: id, password: password, deviceName: 'Burumy');
    await _save();
  }

  @override
  Future<void> logout() async {
    await _d.logout();
    await _store.write(null);
  }

  @override
  Future<void> sync({Duration wait = const Duration(seconds: 25)}) => _d.syncWait(timeoutMs: BigInt.from(wait.inMilliseconds));

  static Msg _msg(ChatMessage m) => Msg(
    id: m.eventId,
    sender: m.sender,
    body: m.body,
    time: _at(m.ts.toInt()),
    mine: m.mine,
    kind: m.kind,
    replyTo: m.replyTo,
    threadRoot: m.threadRoot,
    edited: m.edited,
    reactions: [for (final r in m.reactions) Reaction(r.key, r.count, r.mine)],
    expiresAt: m.expiresAt == null ? null : _at(m.expiresAt!.toInt()),
    viewOnce: m.viewOnce,
    opened: m.opened,
    forwarded: m.forwarded,
    preview: m.preview == null
        ? null
        : LinkCard(url: m.preview!.url, title: m.preview!.title, description: m.preview!.description, site: m.preview!.site, hasImage: m.preview!.hasImage),
    voice: m.voice == null ? null : VoiceInfo(Duration(milliseconds: m.voice!.durationMs.toInt()), m.voice!.waveform),
    poll: m.poll == null
        ? null
        : PollInfo(
            question: m.poll!.question,
            options: [for (final a in m.poll!.answers) PollOption(a.id, a.text, a.votes, a.who)],
            anonymous: m.poll!.anonymous,
            multiple: m.poll!.multiple,
            closed: m.poll!.closed,
            voters: m.poll!.voters,
            mine: m.poll!.mine,
            correct: m.poll!.correct,
            explain: m.poll!.explain,
            closeAt: m.poll!.closeAt.toInt() == 0 ? null : DateTime.fromMillisecondsSinceEpoch(m.poll!.closeAt.toInt()),
          ),
    bubble: m.bubble,
    caption: m.caption,
    meetup: m.meetup == null
        ? null
        : MeetupInfo(
            title: m.meetup!.title,
            startsAt: _at(m.meetup!.startsAt.toInt()),
            place: m.meetup!.place,
            cancelled: m.meetup!.cancelled,
            yes: m.meetup!.yes,
            no: m.meetup!.no,
            maybe: m.meetup!.maybe,
          ),
    contact: m.contact,
    card: m.card == null ? null : _card(m.card!),
    checklist: m.checklist == null
        ? null
        : ChecklistInfo(
            title: m.checklist!.title,
            items: [for (final i in m.checklist!.items) ChecklistItem(i.id, i.text, doneBy: i.doneBy, addedBy: i.addedBy)],
            othersMark: m.checklist!.othersMark,
            othersAdd: m.checklist!.othersAdd,
          ),
    call: m.call == null
        ? null
        : CallInfo(
            id: m.call!.callId,
            video: m.call!.video,
            state: m.call!.state,
            started: _at(m.call!.startedAt.toInt()),
            answered: m.call!.answeredAt == null ? null : _at(m.call!.answeredAt!.toInt()),
            ended: m.call!.endedAt == null ? null : _at(m.call!.endedAt!.toInt()),
          ),
  );

  @override
  Future<List<ChatPreview>> chats() async => [
    for (final c in await _d.chatList())
      ChatPreview(
        roomId: c.roomId,
        name: c.name,
        isDirect: c.isDirect,
        encrypted: c.encrypted,
        unread: c.unread.toInt(),
        last: c.last == null ? null : _msg(c.last!),
        streak: c.streak,
        streakAtRisk: c.streakAtRisk,
        pinned: c.pinned,
        archived: c.archived,
        muted: c.muted,
        isChannel: c.isChannel,
        peer: c.peer,
      ),
  ];

  @override
  Future<List<Msg>> timeline(String roomId, {int limit = 50}) async => [for (final m in await _d.timeline(roomId: roomId, limit: limit)) _msg(m)];

  @override
  Future<void> sendText(String roomId, String text) => _d.sendText(roomId: roomId, text: text);

  @override
  Future<void> sendTextQuietly(String roomId, String text) => _d.sendTextQuietly(roomId: roomId, text: text);

  @override
  Future<String> createDirectChat(String userId) => _d.createDm(userId: userId);

  @override
  Future<String> makeRecoveryKey() => _d.enableRecovery();

  @override
  Future<bool> hasRecovery() => _d.hasRecovery();

  @override
  Future<void> recover(String key) => _d.recoverAll(recoveryKey: key);

  static Person _p(PersonRow r) => Person(userId: r.userId, name: r.name, roomId: r.roomId);

  @override
  Future<List<Person>> contacts() async => [for (final r in await _d.contacts()) _p(r)];

  @override
  Future<List<Person>> searchPeople(String term) async => [for (final r in await _d.searchPeople(term: term)) _p(r)];

  @override
  Future<void> markRead(String roomId) => _d.markRead(roomId: roomId);

  @override
  Future<DateTime?> readUntil(String roomId) async {
    final ms = (await _d.readUntil(roomId: roomId)).toInt();
    return ms == 0 ? null : _at(ms);
  }

  @override
  Future<void> sendFile(String roomId, {required String name, required String mime, required List<int> bytes, String caption = ''}) => caption.trim().isEmpty
      ? _d.sendFile(roomId: roomId, name: name, mime: mime, data: Uint8List.fromList(bytes))
      : _d.sendFileCaptioned(roomId: roomId, name: name, mime: mime, data: Uint8List.fromList(bytes), caption: caption.trim());

  @override
  Future<List<int>> downloadFile(String roomId, String eventId) => _d.downloadFile(roomId: roomId, eventId: eventId);

  @override
  Future<String> createGroup(String name, List<String> members, {bool channel = false}) => _d.createGroup(name: name, invite: members, channel: channel);
  @override
  Future<bool> canPost(String roomId) => _d.canPost(roomId: roomId);
  @override
  Future<bool> isChannel(String roomId) => _d.isChannel(roomId: roomId);
  @override
  Future<void> reply(String roomId, String toId, String text) async {
    await _d.reply(roomId: roomId, toEvent: toId, text: text);
  }

  @override
  Future<void> replyInThread(String roomId, String rootId, String text) async {
    await _d.replyInThread(roomId: roomId, root: rootId, text: text);
  }

  @override
  Future<void> edit(String roomId, String id, String text) => _d.edit(roomId: roomId, eventId: id, text: text);
  @override
  Future<void> deleteMessage(String roomId, String id) => _d.deleteMessage(roomId: roomId, eventId: id);
  @override
  Future<void> setTyping(String roomId, bool typing) => _d.setTyping(roomId: roomId, typing: typing);
  @override
  List<String> typingUsers(String roomId) => _d.typingUsers(roomId: roomId);

  @override
  Future<bool> lockIsSet() async => (await _lock.read()) != null;

  @override
  Future<String?> unlock(String password) async {
    final f = await _lock.read();
    if (f == null) return 'normal';
    final r = await lockUnlock(file: f, pw: password);
    await _lock.write(r.file);
    if (r.wipe) await _d.eraseEverything();
    return r.role;
  }

  @override
  Future<void> setNormalPassword(String password, {String? old}) async {
    final f = await _lock.read();
    await _lock.write(f == null || old == null ? await lockNew(normal: password) : await lockChangeNormal(file: f, old: old, new_: password));
  }

  @override
  Future<void> setExtraPassword(String normal, String role, String? password) async {
    final f = (await _lock.read())!;
    await _lock.write(await lockSetExtra(file: f, normal: normal, role: role, pw: password));
  }

  @override
  Future<List<bool>> extrasSet(String normal) async => lockExtras(file: (await _lock.read())!, normal: normal);

  @override
  Future<int> lockFails() async {
    final f = await _lock.read();
    if (f == null) return 0;
    final m = RegExp(r'"fails":(\d+)').firstMatch(f);
    return int.tryParse(m?.group(1) ?? '0') ?? 0;
  }

  @override
  Future<int> wipeAfter() async {
    final f = await _lock.read();
    return f == null ? 10 : lockWipeAfter(file: f);
  }

  @override
  Future<void> setWipeAfter(String normal, int n) async {
    final f = (await _lock.read())!;
    await _lock.write(await lockSetWipeAfter(file: f, normal: normal, n: n));
  }

  @override
  Future<void> deleteForBoth(String roomId) => _d.deleteForBoth(roomId: roomId);

  @override
  Future<List<String>> takeEraseNotices() => _d.takeEraseNotices();

  @override
  Future<void> startSession(String role) => _d.startSession(role: role);
  @override
  String get sessionRole => _d.sessionRole();
  @override
  Future<List<List<String>>> quietLists() => _d.quietLists();
  @override
  Future<void> setQuietLists(List<String> hide, List<String> delete) => _d.setQuietLists(hide_: hide, delete: delete);
  @override
  Future<String> requestVerification(String userId) => _d.requestUserVerification(userId: userId);
  @override
  Future<void> acceptVerification(String userId, String flowId) => _d.acceptVerification(userId: userId, flowId: flowId);
  @override
  Future<String> verifyState(String userId, String flowId) => _d.verifyState(userId: userId, flowId: flowId);
  @override
  Future<List<String>?> sasEmoji(String userId, String flowId) => _d.sasEmoji(userId: userId, flowId: flowId);
  @override
  Future<void> confirmSas(String userId, String flowId) async => await _d.confirmSas(userId: userId, flowId: flowId);
  @override
  Future<void> cancelVerification(String userId, String flowId) => _d.cancelVerification(userId: userId, flowId: flowId);
  @override
  Future<bool> isUserVerified(String userId) => _d.isUserVerified(userId: userId);
  @override
  Future<List<PeerDevice>> peerDevices(String userId) async => [
    for (final k in await _d.peerKeys(userId: userId)) PeerDevice(id: k.deviceId, name: k.name, key: k.key, verified: k.verified),
  ];
  @override
  Future<void> reportMessage(String roomId, String id, String reason, String shown) =>
      _d.reportMessage(roomId: roomId, eventId: id, reason: reason, shown: shown);

  @override
  Future<void> markForDelete(String roomId, String id, bool on) => _d.markForDelete(roomId: roomId, eventId: id, on_: on);
  @override
  Future<List<String>> markedMessages(String roomId) => _d.markedMessages(roomId: roomId);
  @override
  Future<bool> hideActive() => _d.hideActive();
  @override
  Future<void> releaseHidden() => _d.releaseHidden();
  @override
  Future<String?> runDueLeaves() => _d.runDueLeaves();
  @override
  Future<bool> streaksEnabled() => _d.streaksEnabled();
  @override
  Future<void> setStreaksEnabled(bool on) => _d.setStreaksEnabled(on_: on);
  @override
  Future<void> sendBubble(String roomId, String kind, String mime, List<int> bytes) => _d.sendBubble(roomId: roomId, kind: kind, mime: mime, data: bytes);
  @override
  Future<int> postStory({
    required String mime,
    required List<int> bytes,
    String caption = '',
    List<String> only = const [],
    int hours = 24,
    String extra = '',
  }) async => await _d.postStory(mime: mime, data: bytes, caption: caption, only: only, hours: hours, extra: extra);
  @override
  Future<List<Story>> stories() async => [
    for (final x in await _d.stories())
      Story(
        id: x.storyId,
        roomId: x.roomId,
        eventId: x.eventId,
        sender: x.sender,
        mine: x.mine,
        time: _at(x.ts.toInt()),
        kind: x.kind,
        caption: x.caption,
        extra: x.extra,
        feed: x.feed,
      ),
  ];
  @override
  Future<void> feedLike(String roomId, String postId, {bool on = true}) => _d.feedLike(roomId: roomId, postId: postId, on_: on);
  @override
  Future<List<FeedLike>> feedLikes() async => [for (final x in await _d.feedLikes()) FeedLike(postId: x.postId, sender: x.sender, mine: x.mine)];
  @override
  Future<void> deleteStory(String id) async => await _d.deleteStory(storyId: id);
  @override
  Future<List<BubbleRef>> pendingBubbles() async => [
    for (final b in await _d.pendingBubbles()) BubbleRef(roomId: b.roomId, id: b.eventId, from: b.from, time: _at(b.ts.toInt())),
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
  }) => _d.createPoll(
    roomId: roomId,
    question: question,
    answers: options,
    anonymous: anonymous,
    multiple: multiple,
    quiz: quiz,
    explain: explain,
    closeAt: PlatformInt64Util.from(closeAt?.millisecondsSinceEpoch ?? 0),
  );
  @override
  Future<void> vote(String roomId, String pollId, List<String> choices) => _d.vote(roomId: roomId, pollId: pollId, choices: choices);

  @override
  Future<void> createChecklist(String roomId, String title, List<String> items, {required bool othersMark, required bool othersAdd}) =>
      _d.createChecklist(roomId: roomId, title: title, items: items, othersMark: othersMark, othersAdd: othersAdd);

  @override
  Future<void> markChecklist(String roomId, String checklistId, String itemId, bool done) =>
      _d.markChecklist(roomId: roomId, checklistId: checklistId, item: itemId, done: done);

  @override
  Future<void> addChecklistItem(String roomId, String checklistId, String text) => _d.addChecklistItem(roomId: roomId, checklistId: checklistId, text: text);

  @override
  Future<void> createMeetup(String roomId, String title, DateTime startsAt, String place) =>
      _d.createMeetup(roomId: roomId, title: title, startsAt: BigInt.from(startsAt.millisecondsSinceEpoch), place: place);

  @override
  Future<void> answerMeetup(String roomId, String meetupId, String answer) => _d.answerMeetup(roomId: roomId, meetupId: meetupId, answer: answer);

  @override
  Future<void> cancelMeetup(String roomId, String meetupId) => _d.cancelMeetup(roomId: roomId, meetupId: meetupId);

  @override
  Future<void> setRoomName(String roomId, String name) => _d.setRoomName(roomId: roomId, name: name);
  @override
  Future<String> roomAbout(String roomId) => _d.roomAbout(roomId: roomId);
  @override
  Future<void> setRoomAbout(String roomId, String text) => _d.setRoomAbout(roomId: roomId, text: text);
  @override
  Future<void> inviteUsers(String roomId, List<String> userIds) => _d.inviteUsers(roomId: roomId, users: userIds);
  @override
  Future<void> removeMember(String roomId, String userId) => _d.removeMember(roomId: roomId, userId: userId);
  @override
  Future<void> setAdmin(String roomId, String userId, bool admin) => _d.setAdmin(roomId: roomId, userId: userId, admin: admin);
  @override
  Future<bool> roomSwitch(String roomId, String key) => _d.roomSwitch(roomId: roomId, key: key);
  @override
  Future<void> setRoomSwitch(String roomId, String key, bool on) => _d.setRoomSwitch(roomId: roomId, key: key, on_: on);
  @override
  Future<Map<String, dynamic>> roomConfig(String roomId) async {
    try {
      return (jsonDecode(await _d.roomConfig(roomId: roomId)) as Map).cast<String, dynamic>();
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> setRoomConfig(String roomId, String key, Object? value) => _d.setRoomConfig(roomId: roomId, key: key, value: jsonEncode(value));
  @override
  Future<void> setBanned(String roomId, String userId, bool banned) => _d.setBanned(roomId: roomId, userId: userId, banned: banned);
  @override
  Future<List<String>> banned(String roomId) => _d.banned(roomId: roomId);
  @override
  Future<String> myRole(String roomId) => _d.myRole(roomId: roomId);

  @override
  Future<void> sendContact(String roomId, String userId, String name) => _d.sendContact(roomId: roomId, userId: userId, name: name);
  @override
  Future<void> sendLocation(String roomId, double lat, double lon, double? accuracy) => _d.sendLocation(roomId: roomId, lat: lat, lon: lon, accuracy: accuracy);

  @override
  Future<void> setPush(String gatewayUrl, String pushKey, String appId) => _d.setPush(gatewayUrl: gatewayUrl, pushkey: pushKey, appId: appId);

  @override
  Future<List<Notice>> notifications({int max = 5}) async => [
    for (final n in await _d.notifications(max: max))
      Notice(roomId: n.roomId, chat: n.chat, sender: n.sender, kind: n.kind, body: n.body, time: _at(n.ts.toInt())),
  ];

  @override
  Future<bool> noticeTextHidden() => _d.noticeTextHidden();
  @override
  Future<String> callWaiting() => _d.callWaiting();
  @override
  Future<void> setCallWaiting(String mode) => _d.setCallWaiting(mode: mode);

  @override
  Future<void> setNoticeTextHidden(bool on) => _d.setNoticeTextHidden(on_: on);

  @override
  Future<String> startCall(String roomId, {required bool video}) => _d.startCall(roomId: roomId, video: video);

  @override
  Future<void> answerCall(String roomId, String callId) => _d.answerCall(roomId: roomId, callId: callId);

  @override
  Future<void> hangupCall(String roomId, String callId, String reason) => _d.hangupCall(roomId: roomId, callId: callId, reason: reason);

  @override
  Future<String> callState(String roomId, String callId) => _d.callState(roomId: roomId, callId: callId);

  @override
  Future<List<RingingCall>> ringingCalls() async => [
    for (final r in await _d.ringingCalls()) RingingCall(roomId: r.roomId, callId: r.callId, from: r.from, video: r.video, time: _at(r.startedAt.toInt())),
  ];

  /// Asks our call-pass service (address from the build) with a short-lived
  /// OpenID token. The media key never goes to the service.
  @override
  Future<CallTicket> callTicket(String roomId, String callId) async {
    if (_callPass.isEmpty) throw StateError('calls are not set up in this build');
    final a = await _d.callAsk(roomId: roomId, callId: callId);
    final r = await http
        .post(
          Uri.parse(_callPass),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'openid_token': a.openidToken, 'call': callId, 'video': a.video}),
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw StateError('call pass refused (${r.statusCode})');
    final v = jsonDecode(r.body) as Map<String, dynamic>;
    return CallTicket(url: v['url'] as String, token: v['token'] as String, mediaKey: a.mediaKey, video: a.video);
  }

  @override
  Future<void> closePoll(String roomId, String pollId) => _d.closePoll(roomId: roomId, pollId: pollId);

  @override
  Future<void> createCard(String roomId, String kind, Map<String, Object?> data) => _d.createCard(roomId: roomId, kind: kind, data: jsonEncode(data));

  @override
  Future<void> answerCard(String roomId, String cardId, Object? answer) =>
      _d.answerCard(roomId: roomId, cardId: cardId, answer: answer == null ? '' : jsonEncode(answer));

  @override
  Future<List<CardAnswer>> cardAnswers(String roomId, String cardId) async => [
    for (final a in await _d.cardAnswers(roomId: roomId, cardId: cardId)) CardAnswer(a.user, _json(a.answer)),
  ];

  @override
  Future<List<String>> closeCard(String roomId, String cardId) => _d.closeCard(roomId: roomId, cardId: cardId);
  @override
  Future<void> sendVoice(String roomId, String mime, List<int> bytes, Duration duration, List<int> waveform) =>
      _d.sendVoice(roomId: roomId, mime: mime, data: bytes, durationMs: BigInt.from(duration.inMilliseconds), waveform: waveform);
  @override
  Future<bool> linkPreviewsEnabled() => _d.linkPreviewsEnabled();
  @override
  Future<void> setLinkPreviewsEnabled(bool on) => _d.setLinkPreviewsEnabled(on_: on);
  @override
  Future<List<int>> previewImage(String roomId, String eventId) => _d.previewImage(roomId: roomId, eventId: eventId);
  @override
  Future<void> forward(String fromRoom, String id, String toRoom) => _d.forward(fromRoom: fromRoom, eventId: id, toRoom: toRoom);
  @override
  Future<List<Msg>> searchMessages(String roomId, String term) async => [for (final m in await _d.searchMessages(roomId: roomId, term: term)) _msg(m)];
  @override
  Future<void> setChatPinned(String roomId, bool on) => _d.setChatPinned(roomId: roomId, on_: on);
  @override
  Future<void> setChatArchived(String roomId, bool on) => _d.setChatArchived(roomId: roomId, on_: on);
  @override
  Future<void> setChatMuted(String roomId, bool on) => _d.setChatMuted(roomId: roomId, on_: on);
  @override
  Future<void> react(String roomId, String id, String key) async {
    await _d.react(roomId: roomId, eventId: id, key: key);
  }

  @override
  Future<void> pin(String roomId, String id, bool pinned) => _d.pin(roomId: roomId, eventId: id, pinned: pinned);
  @override
  List<String> pinned(String roomId) => _d.pinned(roomId: roomId);
  @override
  Future<void> setTimer(String roomId, int seconds) => _d.setTimer(roomId: roomId, seconds: BigInt.from(seconds));
  @override
  Future<int> timer(String roomId) async => (await _d.timer(roomId: roomId)).toInt();
  @override
  Future<int> runExpiry() => _d.runExpiry();
  @override
  Future<void> sendViewOnce(String roomId, {required String name, required String mime, required List<int> bytes}) async {
    await _d.sendViewOnce(roomId: roomId, name: name, mime: mime, data: Uint8List.fromList(bytes));
  }

  @override
  Future<List<int>> openViewOnce(String roomId, String id) => _d.openViewOnce(roomId: roomId, eventId: id);
  @override
  Future<String> myName() => _d.myName();
  @override
  Future<void> setMyName(String name) => _d.setMyName(name: name);
  @override
  Future<void> setMyBio(String text) => _d.setMyBio(text: text);
  @override
  Future<String> bioOf(String userId) => _d.bioOf(userId: userId);
  @override
  Future<List<int>?> myPhoto() => _d.myPhoto();
  @override
  Future<void> setMyPhoto(String mime, List<int> bytes) => _d.setMyPhoto(mime: mime, data: Uint8List.fromList(bytes));
  @override
  Future<List<Member>> members(String roomId) async => [for (final m in await _d.members(roomId: roomId)) Member(userId: m.userId, name: m.name, role: m.role)];
  @override
  Future<void> leave(String roomId) => _d.leave(roomId: roomId);
  @override
  Future<List<Invite>> invitations() async => [
    for (final i in await _d.invitations()) Invite(roomId: i.roomId, name: i.name, inviter: i.inviter, direct: i.direct),
  ];
  @override
  Future<List<CallLogItem>> callLog({int max = 200}) async {
    DateTime t(BigInt ms) => _at(ms.toInt());
    return [
      for (final c in await _d.callLog(max: max))
        CallLogItem(
          roomId: c.roomId,
          from: c.from,
          mine: c.mine,
          call: CallInfo(
            id: c.callId,
            video: c.video,
            state: c.state,
            started: t(c.startedAt),
            answered: c.answeredAt == null ? null : t(c.answeredAt!),
            ended: c.endedAt == null ? null : t(c.endedAt!),
          ),
        ),
    ];
  }

  @override
  Future<Map<String, String>> settings() => _d.settings();
  @override
  Future<void> setSetting(String key, String value) => _d.setSetting(key: key, value: value);
  @override
  Future<List<String>> blocked() => _d.blocked();
  @override
  Future<void> block(String userId, bool on) => _d.block(userId: userId, on_: on);
  @override
  Future<List<DeviceRow>> devices() async => [
    for (final d in await _d.devices())
      DeviceRow(
        id: d.deviceId,
        name: d.name,
        lastSeen: d.lastSeen == BigInt.zero ? null : _at(d.lastSeen.toInt()),
        thisDevice: d.thisDevice,
        verified: d.verified,
      ),
  ];
  @override
  Future<void> logOutDevices(List<String> ids, String password) => _d.logOutDevices(ids: ids, password: password);
  @override
  Future<void> changePassword(String old, String newPassword) => _d.changePassword(old: old, new_: newPassword);
  @override
  Future<List<String>> myKeys() => _d.myKeys();
  @override
  Future<bool> thisDeviceVerified() => _d.thisDeviceVerified();
  @override
  Future<String?> savedRoom({bool create = false}) => _d.savedRoom(create: create);
  @override
  Future<void> join(String roomId) => _d.join(roomId: roomId);
  @override
  Future<void> decline(String roomId) => _d.decline(roomId: roomId);
  @override
  Future<void> sendSticker(String roomId, String stickerId) async {
    await _d.sendSticker(roomId: roomId, stickerId: stickerId);
  }
}

/// A time from the engine. Values come partly from other people's messages,
/// so clamp them: a huge number must never crash a chat.
DateTime _at(num ms) => DateTime.fromMillisecondsSinceEpoch(ms.clamp(0, 8640000000000000).toInt());

Object? _json(String s) {
  if (s.isEmpty) return null;
  try {
    return jsonDecode(s);
  } catch (_) {
    return null;
  }
}

CardInfo _card(CardRow c) {
  final d = _json(c.data);
  return CardInfo(
    kind: c.kind,
    data: d is Map ? d.cast<String, Object?>() : const {},
    counts: {
      for (final p in c.counts)
        if (p.lastIndexOf('=') case final i when i > 0) p.substring(0, i): int.tryParse(p.substring(i + 1)) ?? 0,
    },
    winners: c.winners,
    closed: c.closed,
    mine: _json(c.mine),
    won: c.won,
  );
}
