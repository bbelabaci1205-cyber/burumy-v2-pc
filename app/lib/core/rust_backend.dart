// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Backend on top of our Rust engine (through our own bindings).
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart' show PlatformInt64Util;
import 'package:http/http.dart' as http;

import '../src/rust/api/device.dart';
import '../src/rust/api/lock.dart';
import '../brand/brand.dart';
import 'backend.dart';
import 'data_usage.dart';
import 'id_key.dart';
import 'live_photo.dart';
import 'room_links.dart' show InviteLink;
import 'strip_meta.dart';
import 'trust.dart';

/// Call-pass service address comes from the build (never written in code).
const _callPass = String.fromEnvironment('BURUMY_CALL_PASS');

/// Our trust service (badges, labels, name checks), e.g. https://burumy.app.
/// Empty = not set up in this build (no badges, checks always pass).
const _trust = String.fromEnvironment('BURUMY_TRUST');

/// QR로 PC 연결 service (server/qr-login), e.g. https://burumy.example.
const _qrLogin = String.fromEnvironment('BURUMY_QR_LOGIN');

/// The name other devices see for this one (새 로그인 경고, 설정 > 기기):
/// app + kind of device, nothing personal.
String deviceLabel() {
  if (kIsWeb) return 'Burumy Web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'Burumy iPhone',
    TargetPlatform.android => 'Burumy Android',
    TargetPlatform.windows => 'Burumy Windows PC',
    TargetPlatform.macOS => 'Burumy Mac',
    TargetPlatform.linux => 'Burumy Linux PC',
    _ => 'Burumy',
  };
}

/// 가입 심사 도우미 service (server/gate), e.g. https://burumy.app — it
/// serves /_gate/v1/questions and /_gate/v1/check. Empty = no helper.
const _gate = String.fromEnvironment('BURUMY_GATE');

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
  @override
  DateTime get clock => DateTime.now();

  RustBackend._(this._d, this._store, this._lock);
  final BurumyDevice _d;
  final SessionStore _store;
  final LockStore _lock;

  /// The homeserver address (for our own server rules, e.g. send_as).
  String _server = '';

  static Future<RustBackend> open({
    required String server,
    required String dataDir,
    required String storePassphrase,
    required SessionStore store,
    required LockStore lock,
    bool forgetBrokenSession = true,
  }) async {
    final d = await BurumyDevice.open(homeserver: server, dataDir: dataDir, storePassphrase: storePassphrase);
    final b = RustBackend._(d, store, lock).._server = server;
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
    await _d.login(username: id, password: password, deviceName: deviceLabel());
    await _save();
  }

  @override
  Future<void> eraseEverything() => _d.eraseEverything();

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
    quote: m.quote,
    quoteName: m.quoteName,
    captionAbove: m.captionAbove,
    mediaFrom: m.mediaFrom,
    mediaChanged: m.mediaChanged,
    postAs: PostAs.fromJson(m.postAs),
    threadRoot: m.threadRoot,
    topic: m.topic,
    edited: m.edited,
    editedAt: m.editedAt == null ? null : _at(m.editedAt!.toInt()),
    firstBody: m.firstBody,
    reactions: [for (final r in m.reactions) Reaction(r.key, r.count, r.mine)],
    expiresAt: m.expiresAt == null ? null : _at(m.expiresAt!.toInt()),
    viewOnce: m.viewOnce,
    opened: m.opened,
    forwarded: m.forwarded,
    preview: m.preview == null
        ? null
        : LinkCard(
            url: m.preview!.url,
            title: m.preview!.title,
            description: m.preview!.description,
            site: m.preview!.site,
            hasImage: m.preview!.hasImage,
            above: m.preview!.above,
            small: m.preview!.small,
          ),
    voice: m.voice == null ? null : VoiceInfo(Duration(milliseconds: m.voice!.durationMs.toInt()), m.voice!.waveform),
    live: m.live == null ? null : LiveInfo(m.live!.style, Duration(milliseconds: m.live!.durationMs.toInt())),
    poll: m.poll == null
        ? null
        : PollInfo(
            question: m.poll!.question,
            options: [for (final a in m.poll!.answers) PollOption(a.id, a.text, a.votes, a.who, a.hasPhoto, a.sticker, a.geo, a.addedBy)],
            description: m.poll!.description,
            hasPhoto: m.poll!.hasPhoto,
            addOptions: m.poll!.addOptions,
            changeVote: m.poll!.changeVote,
            shuffle: m.poll!.shuffle,
            hideResults: m.poll!.hideResults,
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
    size: m.size?.toInt(),
    meetup: m.meetup == null
        ? null
        : MeetupInfo(
            title: m.meetup!.title,
            startsAt: _at(m.meetup!.startsAt.toInt()),
            endsAt: m.meetup!.endsAt == BigInt.zero ? null : _at(m.meetup!.endsAt.toInt()),
            place: m.meetup!.place,
            cancelled: m.meetup!.cancelled,
            yes: m.meetup!.yes,
            no: m.meetup!.no,
            maybe: m.meetup!.maybe,
            guests: {
              for (var i = 0; i < m.meetup!.yes.length && i < m.meetup!.guests.length; i++)
                if (m.meetup!.guests[i] > 0) m.meetup!.yes[i]: m.meetup!.guests[i],
            },
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
  Future<List<Msg>> cachedMessages(String roomId) async => [for (final m in await _d.cachedMessages(roomId: roomId)) _msg(m)];

  @override
  Future<void> sendText(String roomId, String text) async {
    await _d.sendText(roomId: roomId, text: text);
    DataUsage.note('messages', sent: true, bytes: utf8.encode(text).length);
  }

  @override
  Future<void> sendTextQuietly(String roomId, String text) async {
    await _d.sendTextQuietly(roomId: roomId, text: text);
    DataUsage.note('messages', sent: true, bytes: utf8.encode(text).length);
  }

  @override
  Future<String> createDirectChat(String userId, {String idKey = ''}) => idKey.trim().isEmpty
      ? _d.createDm(userId: userId)
      : _d.createDmKeyed(
          userId: userId,
          proof: IdKey.proof(idKey, from: this.userId ?? '', to: userId),
        );

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
  Future<(DateTime?, DateTime?)> readReceipt(String roomId) async {
    final r = await _d.readReceipt(roomId: roomId);
    DateTime? at(int i) => r.length > i && r[i] > BigInt.zero ? _at(r[i].toInt()) : null;
    return (at(0), at(1));
  }

  @override
  Future<void> sendFile(String roomId, {required String name, required String mime, required List<int> bytes, String caption = '', bool captionAbove = false}) {
    final data = Uint8List.fromList(_clean(bytes, mime));
    // 데이터 사용량 (tip 379): counted once it went out.
    void count() => DataUsage.note(DataUsage.kindOfMime(mime), sent: true, bytes: data.length);
    final c = caption.trim();
    return (c.isEmpty
            ? _d.sendFile(roomId: roomId, name: name, mime: mime, data: data)
            : captionAbove
            ? _d.sendFileOpts(roomId: roomId, name: name, mime: mime, data: data, caption: c, captionAbove: true)
            : _d.sendFileCaptioned(roomId: roomId, name: name, mime: mime, data: data, caption: c))
        .then((_) => count());
  }

  @override
  Future<void> editMedia(String roomId, String id, {required String caption, bool captionAbove = false, String? name, String? mime, List<int>? bytes}) =>
      _d.editMedia(
        roomId: roomId,
        eventId: id,
        caption: caption.trim(),
        captionAbove: captionAbove,
        fileName: bytes == null ? null : name,
        fileMime: bytes == null ? null : mime,
        fileData: bytes == null ? null : Uint8List.fromList(_clean(bytes, mime!)),
      );

  /// Photos lose their hidden details (place, phone, time) before sending.
  static List<int> _clean(List<int> bytes, String mime) => mime.startsWith('image/') ? StripMeta.photo(bytes, mime) : bytes;

  @override
  Future<List<int>> downloadFile(String roomId, String eventId) => _d.downloadFile(roomId: roomId, eventId: eventId);

  @override
  Future<List<int>> downloadFileCached(String roomId, String eventId, {bool cache = true}) =>
      _d.downloadFileCached(roomId: roomId, eventId: eventId, cache: cache);

  @override
  Future<bool> cancelDownload(String eventId) => _d.cancelDownload(eventId: eventId);

  @override
  Future<void> forgetFile(String roomId, String eventId) => _d.forgetFile(roomId: roomId, eventId: eventId);

  @override
  Future<void> setMediaKeep({int? maxFile, Duration? keep}) =>
      _d.setMediaKeep(maxFile: maxFile == null ? null : BigInt.from(maxFile), keepSecs: keep == null ? null : BigInt.from(keep.inSeconds));

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
  Future<void> sendTextLink(String roomId, String text, LinkChoice link, {String? replyTo, bool quiet = false}) async {
    DataUsage.note('messages', sent: true, bytes: utf8.encode(text).length);
    await _d.sendTextLink(
      roomId: roomId,
      toEvent: replyTo ?? '',
      text: text,
      silent: quiet,
      url: link.url ?? '',
      above: link.above,
      small: link.small,
      off: link.off,
    );
  }

  @override
  Future<void> replyQuote(String roomId, String toId, String text, {required String quote, String quoteName = ''}) async {
    await _d.replyQuote(roomId: roomId, toEvent: toId, text: text, quote: quote, quoteName: quoteName);
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
    // The limit was reached: erase first, then save the reset count.
    // Saving first let someone close the app in between and get another
    // round of tries with nothing erased (보안검수 2026-11-28).
    if (r.wipe) await _d.eraseEverything();
    await _lock.write(r.file);
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
  Future<bool> sendMyDraft(String roomId, String text, DateTime at) => _d.sendMyDraft(roomId: roomId, text: text, at: BigInt.from(at.millisecondsSinceEpoch));

  @override
  Future<List<SyncedDraft>> takeSyncedDrafts() async => [
    for (final d in await _d.takeSyncedDrafts()) SyncedDraft(d.roomId, d.text, DateTime.fromMillisecondsSinceEpoch(d.at.toInt())),
  ];

  @override
  Future<void> saveBlob(String name, List<int> data) => _d.saveBlob(name: name, data: Uint8List.fromList(data));

  @override
  Future<List<int>?> blob(String name) => _d.blob(name: name);

  @override
  Future<void> dropBlob(String name) => _d.dropBlob(name: name);

  @override
  void setSendAs(String roomId, PostAs? as) => _d.setSendAs(roomId: roomId, asJson: as?.toJson() ?? '');

  /// 310: first from my own copy of the channel (I'm in it), else our
  /// server answers (rule 11: only for someone who shares [inRoom] with me,
  /// only for public channels).
  @override
  Future<bool> checkSendAs(String channel, String userId, String inRoom) async {
    try {
      final m = (await members(channel)).where((x) => x.userId == userId).firstOrNull;
      if (m != null) return m.role == 'owner' || m.role == 'admin';
    } catch (_) {}
    try {
      final tok = ((jsonDecode(_d.sessionJson()) as Map)['tokens'] as Map?)?['access_token'] as String?;
      if (tok == null || _server.isEmpty) return false;
      final u = Uri.parse(_server).replace(path: '/_burumy/v1/send_as', queryParameters: {'channel': channel, 'user': userId, 'in': inRoom});
      final r = await http.get(u, headers: {'authorization': 'Bearer $tok'}).timeout(const Duration(seconds: 10));
      return r.statusCode == 200 && (jsonDecode(r.body) as Map)['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  String? get _token => ((jsonDecode(_d.sessionJson()) as Map)['tokens'] as Map?)?['access_token'] as String?;

  @override
  Future<Suspension?> suspension() async {
    try {
      final tok = _token;
      if (tok == null || _server.isEmpty) return null;
      final u = Uri.parse(_server).replace(path: '/_burumy/v1/suspension');
      final r = await http.get(u, headers: {'authorization': 'Bearer $tok'}).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      return Suspension.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> appeal(String text) async {
    final tok = _token;
    if (tok == null || _server.isEmpty) throw StateError('not signed in');
    final u = Uri.parse(_server).replace(path: '/_burumy/v1/suspension');
    final r = await http
        .post(u, headers: {'authorization': 'Bearer $tok', 'content-type': 'application/json'}, body: jsonEncode({'text': text}))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw StateError('appeal refused: ${r.body}');
  }

  @override
  Future<void> sendSignal(String roomId, String kind, Map<String, dynamic> data) => _d.sendSignal(roomId: roomId, kind: kind, data: jsonEncode(data));

  @override
  void setSendTopic(String roomId, String? topic) => _d.setSendTopic(roomId: roomId, topic: topic);

  @override
  Future<String> uploadSecret(List<int> bytes) => _d.uploadSecret(bytes: Uint8List.fromList(bytes));

  @override
  Future<List<int>> downloadSecret(String file) => _d.downloadSecret(file: file);

  @override
  List<Signal> takeSignals() => [
    for (final s in _d.takeSignals())
      Signal(
        roomId: s.roomId,
        id: s.eventId,
        sender: s.sender,
        kind: s.kind,
        data: switch (jsonDecode(s.data)) {
          final Map<String, dynamic> m => m,
          _ => const {},
        },
        time: DateTime.fromMillisecondsSinceEpoch(s.ts.toInt()),
      ),
  ];

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
  Future<void> markForHide(String roomId, String id, bool on) => _d.markForHide(roomId: roomId, eventId: id, on_: on);
  @override
  Future<List<String>> hideMarkedMessages(String roomId) => _d.hideMarkedMessages(roomId: roomId);
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
  Future<void> sendBubble(String roomId, String kind, String mime, List<int> bytes) async {
    final data = _clean(bytes, mime);
    await _d.sendBubble(roomId: roomId, kind: kind, mime: mime, data: data);
    DataUsage.note(DataUsage.kindOfMime(mime), sent: true, bytes: data.length);
  }

  @override
  Future<int> postStory({
    required String mime,
    required List<int> bytes,
    String caption = '',
    List<String> only = const [],
    int hours = 24,
    String extra = '',
  }) async => await _d.postStory(mime: mime, data: _clean(bytes, mime), caption: caption, only: only, hours: hours, extra: extra);
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
    final x = await _d.postStories(
      mime: mime,
      data: mime.isEmpty ? const [] : _clean(bytes, mime),
      caption: caption,
      only: only,
      hours: hours,
      extras: extras,
      room: room,
    );
    return StoryPosted(x.sent, x.ids);
  }

  @override
  Future<int> editStory(
    String id, {
    String mime = '',
    List<int> bytes = const [],
    String caption = '',
    String extra = '',
    List<String> only = const [],
    String? pin,
  }) async => await _d.editStory(
    storyId: id,
    mime: mime,
    data: bytes.isEmpty ? const [] : _clean(bytes, mime),
    caption: caption,
    extra: extra,
    only: only,
    pin: pin ?? '',
  );

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
        pin: x.pin,
        until: x.feed ? null : _at(x.until.toInt()),
        edited: x.edited,
        group: x.group,
        member: x.member,
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
    PollExtras extras = const PollExtras(),
  }) => _d.createPoll(
    roomId: roomId,
    question: question,
    answers: options,
    anonymous: anonymous,
    multiple: multiple,
    quiz: quiz,
    explain: explain,
    closeAt: PlatformInt64Util.from(closeAt?.millisecondsSinceEpoch ?? 0),
    extra: jsonEncode({
      'description': extras.description,
      'add_options': extras.addOptions,
      'change_vote': extras.changeVote,
      'shuffle': extras.shuffle,
      'hide_results': extras.hideResults,
      'answers': [
        for (var i = 0; i < options.length; i++)
          {
            if (i < extras.attachments.length && extras.attachments[i]?.sticker != null) 'sticker': extras.attachments[i]!.sticker,
            if (i < extras.attachments.length && extras.attachments[i]?.geo != null) 'geo': extras.attachments[i]!.geo,
          },
      ],
    }),
    // Photos lose hidden details (place, phone model) before encryption.
    photos: [
      if (extras.photo != null) PollPhotoIn(slot: 'q', mime: extras.photo!.mime, data: Uint8List.fromList(_clean(extras.photo!.bytes, extras.photo!.mime))),
      for (var i = 0; i < extras.attachments.length && i < options.length; i++)
        if (extras.attachments[i]?.photo case final ph?) PollPhotoIn(slot: '$i', mime: ph.mime, data: Uint8List.fromList(_clean(ph.bytes, ph.mime))),
    ],
  );
  @override
  Future<void> addPollOption(String roomId, String pollId, String text) => _d.addPollOption(roomId: roomId, pollId: pollId, text: text);
  @override
  Future<List<int>> pollPhoto(String roomId, String pollId, String slot) => _d.pollPhoto(roomId: roomId, pollId: pollId, slot: slot);
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
  Future<String> createMeetup(String roomId, String title, DateTime startsAt, String place, {DateTime? endsAt}) => _d.createMeetup(
    roomId: roomId,
    title: title,
    startsAt: BigInt.from(startsAt.millisecondsSinceEpoch),
    endsAt: BigInt.from(endsAt?.millisecondsSinceEpoch ?? 0),
    place: place,
  );

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
  Future<void> setMemberLevel(String roomId, String userId, int level) =>
      _d.setMemberLevel(roomId: roomId, userId: userId, level: PlatformInt64Util.from(level));
  @override
  Future<bool> roomSwitch(String roomId, String key) => _d.roomSwitch(roomId: roomId, key: key);

  RoomLink _link(RoomLinkRow r) => RoomLink(kind: r.kind, code: r.code, approval: r.approval, web: r.web);

  @override
  Future<RoomLink> roomLink(String roomId) async => _link(await _d.roomLink(roomId: roomId));

  @override
  Future<bool> addressFree(String roomId, String address) => _d.addressFree(roomId: roomId, address: address);

  @override
  Future<RoomLink> setPublicLink(String roomId, String address) async => _link(await _d.setPublicLink(roomId: roomId, address: address));

  @override
  Future<RoomLink> newPrivateLink(String roomId) async => _link(await _d.newPrivateLink(roomId: roomId));

  @override
  Future<void> setLinkApproval(String roomId, bool on) => _d.setLinkApproval(roomId: roomId, on_: on);

  @override
  Future<LinkPeek> peekAddress(String address) async {
    final p = await _d.peekAddress(address: address);
    return LinkPeek(
      roomId: p.roomId,
      name: p.name,
      about: p.about,
      members: p.members.toInt(),
      channel: p.channel,
      approval: p.approval,
      joined: p.joined,
      photo: p.photo.isEmpty ? null : p.photo,
    );
  }

  @override
  Future<(String, bool)> joinLink(String kind, String code) async {
    final r = await _d.joinLink(kind: kind, code: code);
    return (r[0], r[1] == 'asked');
  }

  InviteLink _invite(InviteLinkRow r) => InviteLink(
    code: r.code,
    name: r.name,
    until: r.until == BigInt.zero ? null : DateTime.fromMillisecondsSinceEpoch(r.until.toInt()),
    max: r.max.toInt(),
    uses: r.uses.toInt(),
    joined: r.joined,
    by: r.by,
    made: DateTime.fromMillisecondsSinceEpoch(r.made.toInt()),
    revoked: r.revoked,
  );

  @override
  Future<List<InviteLink>> inviteLinks(String roomId) async => [for (final r in await _d.inviteLinks(roomId: roomId)) _invite(r)];

  @override
  Future<InviteLink> makeInviteLink(String roomId, {String name = '', DateTime? until, int max = 0}) async => _invite(
    await _d.makeInviteLink(
      roomId: roomId,
      name: name,
      until: BigInt.from(until?.millisecondsSinceEpoch ?? 0),
      max: BigInt.from(max),
      now: BigInt.from(DateTime.now().millisecondsSinceEpoch),
    ),
  );

  @override
  Future<InviteLink> editInviteLink(String roomId, String code, {String name = '', DateTime? until, int max = 0}) async =>
      _invite(await _d.editInviteLink(roomId: roomId, code: code, name: name, until: BigInt.from(until?.millisecondsSinceEpoch ?? 0), max: BigInt.from(max)));

  @override
  Future<void> revokeInviteLink(String roomId, String code) => _d.revokeInviteLink(roomId: roomId, code: code);

  @override
  Future<void> restoreInviteLink(String roomId, String code) => _d.restoreInviteLink(roomId: roomId, code: code);

  @override
  Future<void> deleteInviteLink(String roomId, String code) => _d.deleteInviteLink(roomId: roomId, code: code);

  @override
  Future<(int, List<String>)> mainLinkUses(String roomId) async {
    final r = await _d.mainLinkUses(roomId: roomId);
    return (int.tryParse(r.firstOrNull ?? '') ?? 0, r.skip(1).toList());
  }

  @override
  Future<List<JoinRequest>> joinRequests(String roomId) async => [
    for (final r in await _d.joinRequests(roomId: roomId)) JoinRequest(userId: r.userId, name: r.name, answers: r.answers),
  ];

  /// The link's room alias (#address or #j_code on our server).
  String _gateAlias(String kind, String code) {
    final server = (userId ?? '').split(':').skip(1).join(':');
    final local = kind == 'private' ? 'j_${code.trim().toLowerCase()}' : code.trim().toLowerCase();
    return '#$local:$server';
  }

  @override
  Future<List<GateQuestion>?> gateQuestions(String kind, String code) async {
    if (_gate.isEmpty) return null;
    try {
      final r = await http
          .get(Uri.parse('$_gate/_gate/v1/questions?alias=${Uri.encodeQueryComponent(_gateAlias(kind, code))}'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(r.body) as Map<String, dynamic>;
      final qs = [for (final v in (j['questions'] as List? ?? const [])) ?GateQuestion.fromJson(v)];
      return qs.isEmpty ? null : qs;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<bool?>> gateCheck(String kind, String code, List<String> answers) async {
    final r = await http
        .post(
          Uri.parse('$_gate/_gate/v1/check?alias=${Uri.encodeQueryComponent(_gateAlias(kind, code))}'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'a': answers}),
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw StateError('join helper refused (${r.statusCode})');
    return [for (final v in ((jsonDecode(r.body) as Map<String, dynamic>)['right'] as List? ?? const [])) v is bool ? v : null];
  }

  @override
  Future<(String, bool)> joinLinkWith(String kind, String code, List<String> answers) async {
    final r = await _d.joinLinkWith(kind: kind, code: code, answers: answers);
    return (r[0], r[1] == 'asked');
  }

  @override
  Future<String> knockState(String roomId) => _d.knockState(roomId: roomId);

  @override
  Future<void> setGateHelper(String roomId, bool on) => _d.setGateHelper(roomId: roomId, on_: on);

  @override
  Future<GateHelper> gateHelper(String roomId) async {
    final r = await _d.gateHelperState(roomId: roomId);
    return GateHelper(joined: r.joined, devices: r.devices);
  }

  @override
  Future<List<GateEntry>> gateLog(String roomId) async {
    try {
      return GateEntry.listFrom(jsonDecode(await _d.gateLog(roomId: roomId)));
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> answerJoinRequest(String roomId, String userId, bool accept) => _d.answerJoinRequest(roomId: roomId, userId: userId, accept: accept);

  // ---- 커뮤니티 ----
  @override
  Future<List<Community>> communities() async => [
    for (final c in await _d.communities())
      Community(
        id: c.id,
        name: c.name,
        about: c.about,
        role: c.role,
        addAll: c.addAll,
        members: c.members.toInt(),
        chats: [
          for (final x in c.chats)
            CommunityChat(roomId: x.roomId, name: x.name, channel: x.kind == 'channel', state: x.state, hidden: x.hidden, by: x.by, members: x.members.toInt()),
        ],
      ),
  ];
  @override
  Future<String> createCommunity(String name, {String about = ''}) => _d.createCommunity(name: name, about: about);
  @override
  Future<void> setCommunityInfo(String id, String name, String about) => _d.setCommunityInfo(id: id, name: name, about: about);
  @override
  Future<void> addToCommunity(String id, String roomId, {bool hidden = false}) => _d.addToCommunity(id: id, roomId: roomId, hidden: hidden);
  @override
  Future<void> removeFromCommunity(String id, String roomId) => _d.removeFromCommunity(id: id, roomId: roomId);
  @override
  Future<void> setCommunityChatHidden(String id, String roomId, bool hidden) => _d.setCommunityChatHidden(id: id, roomId: roomId, hidden: hidden);
  @override
  Future<void> setCommunityAddAll(String id, bool all) => _d.setCommunityAddAll(id: id, all: all);
  @override
  Future<void> setCommunityAdmin(String id, String userId, bool on) => _d.setCommunityAdmin(id: id, userId: userId, on_: on);
  @override
  Future<(String, bool)> joinCommunityChat(String id, String roomId) async {
    final r = await _d.joinCommunityChat(id: id, roomId: roomId);
    return (r[0], r[1] == 'asked');
  }

  @override
  Future<void> leaveCommunity(String id) => _d.leaveCommunity(id: id);
  @override
  Future<void> deleteCommunity(String id) => _d.deleteCommunity(id: id);

  @override
  Future<void> setWebPage(String roomId, bool on) => _d.setWebPage(roomId: roomId, on_: on);
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
  Future<String> sendLiveLocation(String roomId, double lat, double lon, double? accuracy, DateTime until) =>
      _d.sendLiveLocation(roomId: roomId, lat: lat, lon: lon, accuracy: accuracy, untilMs: BigInt.from(until.millisecondsSinceEpoch));

  @override
  Future<void> updateLiveLocation(String roomId, String messageId, double lat, double lon, double? accuracy, DateTime until) =>
      _d.updateLiveLocation(roomId: roomId, eventId: messageId, lat: lat, lon: lon, accuracy: accuracy, untilMs: BigInt.from(until.millisecondsSinceEpoch));

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
  Future<ImportedChat> importedMessages(String roomId, String cardId) async =>
      ImportedChat.fromJson((jsonDecode(await _d.importedMessages(roomId: roomId, cardId: cardId)) as Map).cast<String, Object?>());
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
  Future<String> uploadEncrypted(List<int> bytes) => _d.uploadEncrypted(data: bytes);
  @override
  Future<List<int>> downloadEncrypted(String fileJson) => _d.downloadEncrypted(file: fileJson);
  @override
  Future<String> sendArticle(String roomId, Map<String, Object?> doc) => _d.sendArticle(roomId: roomId, doc: jsonEncode(doc));
  @override
  Future<Map<String, Object?>> openArticle(String roomId, String eventId) async =>
      (jsonDecode(await _d.openArticle(roomId: roomId, eventId: eventId)) as Map).cast<String, Object?>();
  @override
  Future<void> sendVoice(String roomId, String mime, List<int> bytes, Duration duration, List<int> waveform) async {
    await _d.sendVoice(roomId: roomId, mime: mime, data: bytes, durationMs: BigInt.from(duration.inMilliseconds), waveform: waveform);
    DataUsage.note('voice', sent: true, bytes: bytes.length);
  }

  @override
  Future<bool> linkPreviewsEnabled() => _d.linkPreviewsEnabled();
  @override
  Future<void> setLinkPreviewsEnabled(bool on) => _d.setLinkPreviewsEnabled(on_: on);
  @override
  Future<List<int>> previewImage(String roomId, String eventId) => _d.previewImage(roomId: roomId, eventId: eventId);
  @override
  Future<StoryLinkInfo?> storyLinkCard(String url) async {
    try {
      final r = await _d.storyLinkCard(url: url);
      return StoryLinkInfo(title: r.title, site: r.site, description: r.description, image: r.image);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> forward(String fromRoom, String id, String toRoom) => _d.forward(fromRoom: fromRoom, eventId: id, toRoom: toRoom);
  @override
  Future<List<Found>> searchEverywhere(String term, {String kind = 'text', int limit = 300}) async => [
    for (final f in await _d.searchAll(term: term, kind: kind, limit: limit)) Found(f.roomId, _msg(f.message)),
  ];

  @override
  Future<List<LinkPeek>> searchPublicRooms(String term, {bool channelsOnly = false}) async => [
    for (final p in await _d.searchPublic(term: term, channelsOnly: channelsOnly))
      LinkPeek(
        roomId: p.roomId,
        address: p.address,
        name: p.name,
        about: p.about,
        members: p.members.toInt(),
        channel: p.channel,
        approval: p.approval,
        joined: p.joined,
      ),
  ];

  /// 공개 글: the link service (server/links POST /api/posts). The words go
  /// in the body (never in the address, so no log keeps them).
  @override
  Future<List<PublicPost>> searchPublicPosts(String term) async {
    final t = term.trim();
    if (t.length < 2) return const [];
    try {
      final r = await http
          .post(Uri.https(Brand.linkHost, '/api/posts'), headers: {'content-type': 'application/json'}, body: jsonEncode({'q': t}))
          .timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return const [];
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      return [
        for (final p in (j['posts'] as List? ?? const []))
          if (p is Map)
            PublicPost(
              address: '${p['address'] ?? ''}',
              name: '${p['name'] ?? ''}',
              text: '${p['text'] ?? ''}',
              time: DateTime.fromMillisecondsSinceEpoch((p['ts'] as num?)?.toInt() ?? 0),
              members: (p['members'] as num?)?.toInt() ?? 0,
              channel: p['channel'] != false,
              photo: p['photo'] is String ? 'https://${Brand.linkHost}${p['photo']}' : null,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

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
    await _d.sendLivePhoto(
      roomId: roomId,
      name: name,
      mime: mime,
      data: Uint8List.fromList(_clean(bytes, mime)),
      videoMime: videoMime,
      video: Mp4Meta.strip(video),
      durationMs: BigInt.from(duration.inMilliseconds),
      style: style,
      caption: caption.trim(),
    );
    DataUsage.note('photo', sent: true, bytes: bytes.length + video.length);
  }

  @override
  Future<List<int>> liveVideo(String roomId, String eventId) => _d.liveVideo(roomId: roomId, eventId: eventId);

  @override
  Future<void> sendViewOnce(String roomId, {required String name, required String mime, required List<int> bytes}) async {
    final data = Uint8List.fromList(_clean(bytes, mime));
    await _d.sendViewOnce(roomId: roomId, name: name, mime: mime, data: data);
    DataUsage.note(DataUsage.kindOfMime(mime), sent: true, bytes: data.length);
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
  Future<int> setEmojiStatus(String emoji, DateTime? until) => _d.setEmojiStatus(emoji: emoji, untilMs: BigInt.from(until?.millisecondsSinceEpoch ?? 0));
  @override
  Future<EmojiStatus?> emojiStatusOf(String userId) async {
    final r = await _d.emojiStatusOf(userId: userId);
    if (r.emoji.isEmpty) return null;
    return EmojiStatus(r.emoji, r.untilMs == BigInt.zero ? null : _at(r.untilMs.toInt()));
  }

  @override
  Future<String> bioOf(String userId) => _d.bioOf(userId: userId);
  @override
  Future<List<int>?> myPhoto() => _d.myPhoto();
  @override
  Future<void> setMyPhoto(String mime, List<int> bytes) => _d.setMyPhoto(mime: mime, data: Uint8List.fromList(bytes));
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
  }) => _d.shareProfile(mime: mime, photo: photo, bio: bio, birthday: birthday, whoPhoto: whoPhoto, whoBio: whoBio, whoBirthday: whoBirthday, only: only);
  @override
  Future<ProfileCard> profileOf(String userId) async {
    final c = await _d.profileOf(userId: userId);
    return ProfileCard(photo: c.photo, bio: c.bio, birthday: c.birthday, private: c.private);
  }

  @override
  Future<List<Member>> members(String roomId) async => [
    for (final m in await _d.members(roomId: roomId))
      Member(userId: m.userId, name: m.name, role: m.role, since: m.since == BigInt.zero ? null : _at(m.since.toInt())),
  ];
  @override
  Future<void> leave(String roomId) => _d.leave(roomId: roomId);
  @override
  Future<int> sendHistory(String roomId, String userId, {int count = 50}) => _d.sendHistory(roomId: roomId, userId: userId, count: count);

  @override
  Future<List<Msg>> earlierMessages(String roomId) async => [
    for (final (i, m) in (await _d.earlierMessages(roomId: roomId)).indexed)
      Msg(
        id: 'earlier-$i',
        sender: m.sender,
        // Files show their name; photos and videos their words underneath.
        body: m.kind == 'text' ? m.body : m.name,
        caption: m.kind == 'text' || m.body.isEmpty ? null : m.body,
        time: DateTime.fromMillisecondsSinceEpoch(m.ts.toInt()),
        mine: m.sender == userId,
        kind: m.kind,
      ),
  ];

  @override
  Future<List<int>> earlierFile(String roomId, int index, {bool thumb = false}) => _d.earlierFile(roomId: roomId, index: index, thumb: thumb);

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
  TrustList _trustCache = TrustList.empty;
  DateTime _trustAt = DateTime(2000);

  Future<Map<String, dynamic>> _trustPost(String path, Map<String, Object?> body, {bool signed = true}) async {
    if (_trust.isEmpty) throw StateError('trust service is not set up in this build');
    final b = {...body, if (signed) 'openid_token': await _d.openidToken()};
    final r = await http
        .post(Uri.parse('$_trust/_burumy/v1/trust/$path'), headers: {'content-type': 'application/json'}, body: jsonEncode(b))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw StateError('trust service refused (${r.statusCode})');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  /// The list changes rarely: fetched at most every 5 minutes.
  @override
  Future<TrustList> trustList() async {
    if (_trust.isEmpty) return TrustList.empty;
    if (DateTime.now().difference(_trustAt) < const Duration(minutes: 5)) return _trustCache;
    try {
      final r = await http.get(Uri.parse('$_trust/_burumy/v1/trust')).timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        _trustCache = TrustList.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
        _trustAt = DateTime.now();
      }
    } catch (_) {}
    return _trustCache;
  }

  @override
  Future<TrustAbout> trustAbout(String userId) async {
    if (_trust.isEmpty) return const TrustAbout();
    final v = await _trustPost('about', {'user': userId});
    return TrustAbout(
      age: (v['age'] as String?) ?? 'unknown',
      renamed: v['renamed'] == true,
      renamedDays: (v['renamed_days'] as num?)?.toInt() ?? -1,
      photoDays: (v['photo_days'] as num?)?.toInt() ?? -1,
    );
  }

  @override
  Future<void> trustSeen(String name, {String photo = ''}) async {
    if (_trust.isEmpty) return;
    await _trustPost('seen', {'name': name, if (photo.isNotEmpty) 'photo': photo});
  }

  @override
  Future<String> nameCheck(String text, {bool displayName = false, bool room = false}) async {
    if (_trust.isEmpty) return checkName(text, displayName: displayName || room);
    final v = await _trustPost(
      'name_check',
      displayName
          ? {'kind': 'name', 'name': text}
          : room
          ? {'kind': 'room', 'name': text}
          : {'id': text},
      signed: false,
    );
    if (v['ok'] == true) return '';
    final why = v['why'] as String? ?? 'reserved';
    final claim = v['claim'] as String? ?? '';
    return why == 'reserved' && (claim == 'owner' || claim == 'sale') ? 'reserved_$claim' : why;
  }

  @override
  Future<void> claimOpen(String id, String code) async {
    await _trustPost('claim', {'id': id, 'code': code}, signed: false);
  }

  @override
  Future<String> badgeCode() async => (await _trustPost('apply/start', {}))['code'] as String;

  @override
  Future<void> applyBadge({required String kind, required String name, required String proof}) =>
      _trustPost('apply', {'kind': kind, 'name': name, 'proof': proof});

  @override
  Future<String> reportImpersonation(String userId, {String victim = '', String note = ''}) async =>
      ((await _trustPost('report', {'user': userId, 'victim': victim, 'note': note}))['state'] as String?) ?? '';

  @override
  Future<bool> reportContent(String roomId, String id, String sender, String reason, String note) async {
    if (_trust.isEmpty) return false;
    final r = await _trustPost('content_report', {'room': roomId, 'event': id, 'sender': sender, 'reason': reason, 'note': note});
    // A fresh list next time, so the hidden message goes at once.
    _trustAt = DateTime(2000);
    return r['state'] == 'hidden';
  }

  @override
  Future<String?> savedRoom({bool create = false}) => _d.savedRoom(create: create);
  @override
  Future<void> setIdSearchHidden(bool on) => _d.setIdSearchHidden(on_: on);

  @override
  Future<void> setMyRoomLook(String roomId, {String? name, String? color}) => _d.setMyRoomLook(roomId: roomId, name: name, color: color);

  @override
  Future<void> setRoomPhoto(String roomId, String mime, Uint8List? bytes) => _d.setRoomPhoto(roomId: roomId, mime: mime, data: bytes ?? Uint8List(0));

  @override
  Future<Uint8List?> roomPhoto(String roomId) => _d.roomPhoto(roomId: roomId);

  @override
  Future<bool> reshareRoomPhoto(String roomId) => _d.reshareRoomPhoto(roomId: roomId);

  @override
  Future<void> setMyRoomTag(String roomId, String tag) => _d.setMyRoomTag(roomId: roomId, tag: tag);
  @override
  Future<Map<String, String>> memberTags(String roomId) async => {
    for (final x in await _d.memberTags(roomId: roomId))
      if (x.contains('\t')) x.substring(0, x.indexOf('\t')): x.substring(x.indexOf('\t') + 1),
  };
  @override
  Future<Map<String, (DateTime, DateTime)>> groupReceipts(String roomId) async {
    final out = <String, (DateTime, DateTime)>{};
    for (final x in await _d.groupReceipts(roomId: roomId)) {
      final p = x.split('\t');
      final a = p.length == 3 ? int.tryParse(p[1]) : null, b = p.length == 3 ? int.tryParse(p[2]) : null;
      if (a != null && b != null && a > 0) out[p[0]] = (_at(a), _at(b));
    }
    return out;
  }

  @override
  Future<Map<String, String>> nameColors(String roomId) async => {
    for (final x in await _d.nameColors(roomId: roomId))
      if (x.contains('\t')) x.split('\t').first: x.split('\t').last,
  };
  @override
  Future<Map<String, dynamic>> accountPrivacy() async {
    try {
      final v = jsonDecode(await _d.privacyJson());
      return v is Map<String, dynamic> ? v : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<void> setAccountPrivacy(String key, Object? value) => _d.setPrivacyValue(key: key, valueJson: jsonEncode(value));

  @override
  bool get pcLinkReady => _qrLogin.isNotEmpty;

  @override
  Future<void> approvePcLogin(String rid) async {
    if (_qrLogin.isEmpty) throw StateError('QR sign-in is not set up in this build');
    final r = await http
        .post(
          Uri.parse('$_qrLogin/_burumy/v1/qr/claim'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'openid_token': await _d.openidToken(), 'r': rid}),
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) throw StateError('QR sign-in refused (${r.statusCode})');
  }

  @override
  Future<bool> takePcLogin(String secret) async {
    if (_qrLogin.isEmpty) return false;
    final r = await http
        .post(Uri.parse('$_qrLogin/_burumy/v1/qr/take'), headers: {'content-type': 'application/json'}, body: jsonEncode({'s': secret}))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return false;
    final token = (jsonDecode(r.body) as Map<String, dynamic>)['token'];
    if (token is! String) return false;
    await _d.loginToken(token: token, deviceName: deviceLabel());
    await _save();
    return true;
  }

  @override
  Future<void> join(String roomId) => _d.join(roomId: roomId);
  @override
  Future<void> decline(String roomId) => _d.decline(roomId: roomId);
  @override
  Future<void> declineBlocked(String roomId) => _d.declineBlocked(roomId: roomId);
  @override
  Future<List<String>> invitesBlocked(String roomId) => _d.invitesBlocked(roomId: roomId);
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
