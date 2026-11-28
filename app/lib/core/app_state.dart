// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// App-wide state: who is logged in, the chat list, the look (brand family,
// language). Keeps a live update loop while logged in.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../brand/brand.dart';
import 'automod.dart';
import 'group_tools.dart';
import 'chat_mute.dart';
import 'keyword_replies.dart';
import 'login_safety.dart';
import 'accounts.dart';
import 'backend.dart';
import 'archive_rules.dart';
import 'data_usage.dart';
import 'channel_dm.dart';
import 'downloads.dart';
import 'open_docs.dart';
import 'draft_sync.dart';
import 'error_log.dart';
import 'gifs.dart';
import 'custom_emoji.dart';
import 'effects.dart';
import 'features.dart';
import 'memories.dart';
import 'own_way.dart';
import 'my_photos.dart';
import 'id_key.dart';
import '../l10n/app_localizations.dart';
import 'rules.dart';
import 'room_rules.dart';
import 'room_texts.dart';
import 'topics.dart';
import 'suggest_post.dart';
import 'phone.dart';
import 'room_theme.dart';
import 'looks.dart';
import 'safety.dart';
import 'trust.dart';

/// That account is already signed in on this phone.
class AccountAlreadyHere implements Exception {
  const AccountAlreadyHere();
}

class AppState extends ChangeNotifier {
  AppState(this.backend, {this.family = BrandFamily.green, this.locale});

  final Backend backend;

  /// Several accounts on this phone (null in tests that use one backend).
  Accounts? accounts;
  BrandFamily family;

  /// null = follow the phone's language.
  Locale? locale;

  List<ChatPreview> chats = const [];

  /// 커뮤니티 I am in (see [Community]).
  List<Community> communities = const [];

  /// The community a chat belongs to (that I can see), if any.
  Community? communityOf(String roomId) {
    for (final c in communities) {
      if (c.visible.any((x) => x.roomId == roomId)) return c;
    }
    return null;
  }

  /// "한 대화로 보기" for this community (this phone only).
  bool communityAsOne(String id) => on('community_one:$id');

  /// 사칭 막기: official badges and '확인 중' / '가짜' labels (public list).
  TrustList trust = TrustList.empty;

  /// What to show next to [user] whose name is [name] right now.
  Trust trustOf(String user, String name) => trust.of(user, name);

  /// Asks for the latest list (the backend keeps it for a few minutes).
  Future<void> refreshTrust() async {
    try {
      final t = await backend.trustList();
      if (t.version != trust.version ||
          t.badges.length != trust.badges.length ||
          t.flags.length != trust.flags.length ||
          t.hidden.length != trust.hidden.length ||
          t.guard != trust.guard) {
        trust = t;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// I accepted a first message from someone who isn't my friend.
  bool acceptedStranger(String roomId) => settings['stranger_ok:$roomId'] == '1';

  /// My 1:1 contacts' user ids (folders: 연락처 / 비연락처).
  Set<String> friendIds = const {};

  /// Bubbles waiting for me (who and when only).
  List<BubbleRef> bubbles = const [];

  /// Stories within their 24 hours (mine and friends').
  List<Story> stories = const [];

  /// Friend-feed posts, newest first (shown only while [Features.feed] is on).
  List<Story> feed = const [];

  /// 1년 전 오늘 (core/memories.dart): saved pictures from this day in
  /// earlier years, picked on this phone.
  List<MemoryDay> memories = const [];

  /// Stories kept on someone's profile (mine included), any age.
  List<Story> keptStories = const [];
  List<FeedLike> feedLikes = const [];

  /// This device's id and my account privacy settings (tip 311).
  String thisDeviceId = '';
  Map<String, dynamic> accountPrivacy = const {};

  /// "이 기기로 통화 받기" is off for this device.
  bool get callsOffHere => Features.loginSafety && thisDeviceId.isNotEmpty && LoginSafety.callsOff(accountPrivacy, thisDeviceId);

  /// 새 로그인 경고: my devices that signed in since I last looked.
  List<DeviceRow> newLogins = const [];
  DateTime _devicesAt = DateTime(2000);

  /// Asks for my device list now and then (cheap; this phone only).
  Future<void> checkNewLogins({bool now = false}) async {
    if (!Features.loginSafety || !loggedIn) return;
    final t = DateTime.now();
    if (!now && t.difference(_devicesAt) < LoginSafety.every) return;
    _devicesAt = t;
    try {
      final all = await backend.devices();
      thisDeviceId = all.where((d) => d.thisDevice).firstOrNull?.id ?? thisDeviceId;
      try {
        accountPrivacy = await backend.accountPrivacy();
      } catch (_) {}
      final fresh = await LoginSafety.newDevices(this, all);
      final ids = {for (final d in fresh) d.id};
      if (ids.length != newLogins.length || !newLogins.every((d) => ids.contains(d.id))) {
        newLogins = fresh;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// The card was answered (yes: known now; no: that device was logged out).
  Future<void> answerNewLogin(String deviceId, {required bool mine}) async {
    if (mine) await LoginSafety.confirm(this, deviceId);
    newLogins = [
      for (final d in newLogins)
        if (d.id != deviceId) d,
    ];
    notifyListeners();
  }

  /// 1:1 chats from strangers that were just tucked into 보관함 (the list
  /// plays a short animation for them).
  final tuckedNow = ValueNotifier<int>(0);

  /// Friends (user ids) who deleted a 1:1 chat for both, not yet dismissed.
  List<String> erasedBy = const [];

  void dismissErased(String who) {
    erasedBy = [...erasedBy]..remove(who);
    notifyListeners();
  }

  /// Calls ringing for me right now.
  List<RingingCall> ringing = const [];

  /// The chat open on screen right now (no in-app banner for it).
  String? openRoom;

  /// Set by the app: register this phone for push after login, and show
  /// notifications for news that arrive while the app is in the background.
  static Future<void> Function(AppState s)? startPush;
  static Future<void> Function(Backend b)? showNotices;

  /// Phone builds: a local alert at [at] (birthdays). Nothing goes out.
  static Future<void> Function(int id, DateTime at, String title)? remindAt;

  /// Phone builds: the plain "open the app" reminder a day before the
  /// 미접속 자동 삭제 runs out. Nothing goes out.
  static Future<void> Function(DateTime at)? idleReminder;

  /// The app is not on screen (notifications are shown then).
  bool inBackground = false;

  /// A wake-up from push while the app is alive in the background.
  Future<void> wake() async {
    if (!loggedIn || locked) return;
    try {
      await backend.sync(wait: Duration.zero);
    } catch (_) {}
    await refresh();
  }

  /// Set by the app to put bubbles on the home-screen widget (not in tests).
  static void Function(List<BubbleRef> bubbles, List<ChatPreview> chats)? publishBubbles;
  bool _live = false;
  int _generation = 0;

  bool get loggedIn => backend.loggedIn;

  /// The app lock screen is up.
  bool locked = false;

  /// Called on start (and when the app comes back after a while).
  Future<void> checkLock() async {
    locked = loggedIn && await backend.lockIsSet();
    if (locked) stopLive();
    notifyListeners();
  }

  /// Settings > Privacy > Panic gesture: lock right away (only when the
  /// switch and the app lock are both on).
  Future<void> panicLock() async {
    if (!on('panic') || !loggedIn || locked) return;
    await checkLock();
  }

  /// Opens the lock. The password decides the session (normal / hide /
  /// delete); the screen looks the same for all three.
  Future<bool> unlock(String password) async {
    final role = await backend.unlock(password);
    final a = accounts;
    if (role == null) {
      // The wrong-try limit erased this account's chats (the count starts
      // again at 0): the other accounts' chats go too.
      if (a != null && a.side.isNotEmpty && await backend.lockFails() == 0) await a.eraseOthers();
      return false;
    }
    if (role == 'account') {
      // Fourth password: the chosen accounts leave this phone; what is left
      // opens as usual (another account may now be on screen).
      if (a != null) {
        await a.eraseChosen();
        if (!identical(a.state, this)) {
          a.state.locked = false;
          await a.state.backend.startSession('normal');
          await a.state.afterLogin();
          return true;
        }
      }
      await backend.startSession('normal');
    } else {
      await backend.startSession(role);
      if (a != null && role != 'normal') await a.startSessionOthers(role);
    }
    locked = false;
    await afterLogin();
    unawaited(backend.runDueLeaves().then((_) {}, onError: (_) {}));
    return true;
  }

  void setFamily(BrandFamily f) {
    family = f;
    notifyListeners();
    if (loggedIn) unawaited(setPref('family', f.name));
  }

  void setLocale(Locale? l) {
    locale = l;
    notifyListeners();
    if (loggedIn) unawaited(setPref('locale', l?.languageCode ?? ''));
  }

  /// On-device settings by name (see Settings). Switches are "1"/"0".
  Map<String, String> settings = const {};

  String pref(String key, String fallback) => settings[key] ?? fallback;

  bool on(String key, {bool fallback = false}) => switch (settings[key]) {
    '1' => true,
    '0' => false,
    _ => fallback,
  };

  Future<void> setPref(String key, String value) async {
    settings = {...settings, key: value}..removeWhere((_, v) => v.isEmpty);
    notifyListeners();
    await backend.setSetting(key, value);
  }

  Future<void> setOn(String key, bool v) => setPref(key, v ? '1' : '0');

  /// "연락처에서 삭제" (v1): the 1:1 chat stays, the person leaves the
  /// contacts list until I open a chat with them again.
  Set<String> get removedContacts => pref('removed_contacts', '').split(',').where((x) => x.isNotEmpty).toSet();

  Future<void> removeContact(String userId, {bool removed = true}) {
    final all = removedContacts;
    removed ? all.add(userId) : all.remove(userId);
    return setPref('removed_contacts', all.join(','));
  }

  /// Battery left in % (null = unknown). Read once a minute while open.
  int? battery;

  /// "wifi", "cellular", "none" or "unknown", checked every minute.
  String network = 'unknown';

  /// Settings > Data: download photos on their own now?
  bool get autoDownload {
    if (lowBattery || !on('ps_preload', fallback: true)) return false;
    return network == 'cellular' ? on('auto_dl_cell', fallback: true) : on('auto_dl_wifi', fallback: true);
  }

  /// GIFs move (off in power saving, or when switched off).
  bool get gifsMove => !lowBattery && on('autoplay_gif', fallback: true);

  /// Glass blur (off: plain solid bars) and the tilting background.
  bool get glassOn => !lowBattery && on('ps_glass', fallback: true);
  bool get tiltOn => !lowBattery && on('tilt');
  Timer? _batteryTimer;

  /// Settings > Power saving: below this % the moving effects stop
  /// ("0" = never, "100" = always).
  int get powerBelow => int.tryParse(pref('power_below', '15')) ?? 15;

  /// Moving effects are off: switched off, or the battery is low.
  bool get calm => lowBattery || !on('ui_effects', fallback: true);

  /// Power saving is on now (Telegram: every heavy job stops below X%).
  bool get lowBattery {
    final below = powerBelow;
    if (below >= 100) return true;
    return below > 0 && battery != null && battery! < below;
  }

  void watchBattery(Future<int?> Function() read, {Future<String> Function()? net}) {
    Future<void> tick() async {
      final b = await read();
      final n = net == null ? network : await net();
      if (b != battery || n != network) {
        battery = b;
        network = n;
        notifyListeners();
      }
    }

    _batteryTimer?.cancel();
    unawaited(tick());
    _batteryTimer = Timer.periodic(const Duration(minutes: 1), (_) => tick());
  }

  /// Makes a chat and, when it is new, gives it my default
  /// disappearing-message time (Settings > Privacy).
  Future<String> makeChat(Future<String> Function() make) async {
    final known = {for (final c in chats) c.roomId};
    final id = await make();
    final secs = int.tryParse(pref('default_timer', '0')) ?? 0;
    if (secs > 0 && !known.contains(id)) {
      try {
        await backend.setTimer(id, secs);
        timers[id] = secs;
      } catch (_) {}
    }
    return id;
  }

  /// 자동 삭제 time per chat (seconds), for the "1w" mark on chat photos
  /// (Telegram tip 364). Read at most once a minute; set at once when I
  /// change it here.
  final timers = <String, int>{};
  DateTime? _timersAt;

  Future<void> loadTimers() async {
    final now = DateTime.now();
    if (_timersAt != null && now.difference(_timersAt!) < const Duration(minutes: 1)) return;
    _timersAt = now;
    var changed = false;
    for (final c in chats) {
      if (c.isChannel) continue;
      try {
        final t = await backend.timer(c.roomId);
        if (timers[c.roomId] != t) {
          timers[c.roomId] = t;
          changed = true;
        }
      } catch (_) {}
    }
    if (changed) notifyListeners();
  }

  /// Sets a chat's timer and its list mark together.
  Future<void> setChatTimer(String roomId, int seconds) async {
    await backend.setTimer(roomId, seconds);
    timers[roomId] = seconds;
    notifyListeners();
  }

  /// My "saved messages" chat, once made (first save, or opened in Settings).
  String? savedRoomId;

  /// "저장한 메시지" in the app's language.
  String get savedLabel {
    final loc = locale ?? WidgetsBinding.instance.platformDispatcher.locale;
    try {
      return lookupL(Locale(loc.languageCode)).savedMessages;
    } catch (_) {
      return lookupL(const Locale('en')).savedMessages;
    }
  }

  /// Saved messages under its own name, in its place by time like any
  /// other chat (Eric 2026-11-26: not stuck on top; only pins stay up).
  List<ChatPreview> _savedFirst(List<ChatPreview> list) {
    final id = savedRoomId;
    final c = id == null ? null : list.where((x) => x.roomId == id).firstOrNull;
    if (c == null) return list;
    final named = ChatPreview(
      roomId: c.roomId,
      name: savedLabel,
      isDirect: false,
      encrypted: c.encrypted,
      unread: 0,
      last: c.last,
      pinned: c.pinned,
      archived: c.archived,
      muted: c.muted,
    );
    return [for (final x in list) x.roomId == id ? named : x];
  }

  Future<String> openSaved() async {
    savedRoomId ??= await backend.savedRoom(create: true);
    await refresh();
    return savedRoomId!;
  }

  Future<void> _loadSettings() async {
    try {
      settings = await backend.settings();
      savedRoomId = await backend.savedRoom();
    } catch (_) {}
    final f = settings['family'];
    if (f != null) family = BrandFamily.values.firstWhere((x) => x.name == f, orElse: () => family);
    final l = settings['locale'];
    if (l != null) locale = l.isEmpty ? null : Locale(l);
  }

  Future<void> register(String id, String password, String? invite) async {
    await backend.register(id: id, password: password, invite: invite);
    await _noteAccount();
    await afterLogin();
  }

  Future<void> login(String id, String password) async {
    await backend.login(id: id, password: password);
    await _noteAccount();
    await afterLogin();
  }

  /// QR로 PC 연결 (PC side): signs in once my phone vouched for the QR
  /// made from [secret]. False = not yet.
  Future<bool> loginWithPcCode(String secret) async {
    if (!await backend.takePcLogin(secret)) return false;
    await _noteAccount();
    await afterLogin();
    return true;
  }

  Future<void> _noteAccount() async {
    final a = accounts;
    if (a != null && !await a.noteLogin()) throw const AccountAlreadyHere();
  }

  Future<void> afterLogin() async {
    await _loadSettings();
    unawaited(_idleTouch());
    notifyListeners();
    await refresh();
    startLive();
    // The trust service learns my current name (badge check, rename date).
    unawaited(() async {
      try {
        await backend.trustSeen(await backend.myName(), photo: photoPrint(await backend.myPhoto()));
      } catch (_) {}
    }());
    final p = startPush;
    if (p != null) unawaited(p(this).catchError((_) {}));
  }

  /// The app was opened: 미접속 자동 삭제 counts again from now.
  Future<void> _idleTouch() async {
    try {
      await Safety.touch();
      final at = await Safety.idleReminderAt();
      if (at != null) await idleReminder?.call(at);
    } catch (_) {}
  }

  /// Extra handlers for hidden notes, by kind (later features add theirs).
  late final signalHandlers = <String, Future<void> Function(Signal s)>{
    // 환영 인사 + 규칙 (encrypted pack from an admin's phone).
    RoomTexts.kind: (s) => RoomTexts.onSignal(this, s),
    // 주제 (tip 527): the encrypted topic list from an admin's phone.
    Topics.kind: (s) => Topics.onSignal(this, s),
    // 대화방 테마 양쪽 적용 (1:1, encrypted).
    RoomTheme.kind: (s) => RoomTheme.onSignal(this, s),
    // 이름·프로필 꾸미기 from a 1:1 chat (encrypted).
    PersonLook.signalKind: (s) async {
      final v = s.data['v'];
      if (v is! String || v.length > 80) return;
      await setPref(PersonLook.prefOf(s.sender), v);
    },
    // 로그인·기기 안전: voice rule, calls / days wiped for both (1:1).
    if (Features.loginSafety) ...LoginSafety.handlers(this),
    // 메시지 효과 / 큰 이모지 같이 보기 (tips 451 · 355).
    if (Features.funFx) ...{
      MsgFx.kind: (s) => MsgFx.onSignal(this, s),
      MsgFx.tapKind: (s) => MsgFx.onTapSignal(this, s),
      // 직접 만든 이모지 그림 + 그룹 이모지 묶음 (tips 354 · 430).
      CustomEmojis.kind: (s) => CustomEmojis.onSignal(this, s),
      CustomEmojis.packKind: (s) => CustomEmojis.onPack(this, s),
      // GIF 위 글씨·그림 (tip 558).
      Gifs.layerKind: (s) => Gifs.onLayer(this, s),
    },
    // 우리식 기능: 캡처 알림, 친구 피드 댓글.
    if (Features.ownWay) ...OwnWay.handlers(this),
  };

  /// Hidden notes from other phones (remote wipe requests and the like).
  Future<void> handleSignals() async {
    final List<Signal> got;
    try {
      got = backend.takeSignals();
    } catch (_) {
      return;
    }
    for (final s in got) {
      try {
        if (s.kind == Safety.wipeKind) {
          await _onWipeSignal(s);
        } else {
          await signalHandlers[s.kind]?.call(s);
        }
      } catch (e, st) {
        ErrorLog.add(e, st);
      }
    }
  }

  Future<void> _onWipeSignal(Signal s) async {
    final votes = <String, int>{};
    try {
      (jsonDecode(pref(Safety.votesKey, '{}')) as Map).forEach((k, v) => votes['$k'] = (v as num).toInt());
    } catch (_) {}
    final what = Safety.judge(settings, s, votes);
    if (what == null) return;
    await setPref(Safety.votesKey, what == 'wipe' ? '' : jsonEncode(votes));
    if (what == 'wipe') await emergencyWipe();
  }

  /// 원격 비상 삭제 / 미접속 자동 삭제: the plan's last message to my trusted
  /// friends, then every chat on this phone is erased.
  Future<void> emergencyWipe() async {
    final msg = pref(Safety.lastMsgKey, '').trim();
    if (msg.isNotEmpty) {
      for (final f in Safety.friends(settings)) {
        final room = chats.where((c) => c.isDirect && c.peer == f).firstOrNull;
        if (room == null) continue;
        try {
          await backend.sendText(room.roomId, msg);
        } catch (_) {}
      }
    }
    try {
      await backend.eraseEverything();
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    // Every account on this phone goes, like too many wrong tries.
    await accounts?.eraseOthers();
    try {
      chats = await backend.chats();
    } catch (_) {
      chats = const [];
    }
    await checkLock();
  }

  /// Group and channel invitations waiting for a tap.
  List<Invite> invites = const [];

  Future<void> acceptInvite(String roomId) async {
    await backend.join(roomId);
    await refresh();
  }

  Future<void> declineInvite(String roomId) async {
    await backend.decline(roomId);
    invites = [
      for (final i in invites)
        if (i.roomId != roomId) i,
    ];
    notifyListeners();
  }

  Future<void> logout() async {
    stopLive();
    await backend.logout();
    chats = const [];
    communities = const [];
    bubbles = const [];
    ringing = const [];
    invites = const [];
    settings = const {};
    savedRoomId = null;
    publishBubbles?.call(const [], const []);
    notifyListeners();
    await accounts?.afterLogout();
  }

  /// Messages set to go later (on this phone; sent when the app is open at
  /// that time or next opens): {id, room, text, at (ms), quiet}.
  List<Map<String, dynamic>> get scheduled {
    try {
      return [for (final j in jsonDecode(pref('scheduled', '[]')) as List) (j as Map).cast<String, dynamic>()];
    } catch (_) {
      return [];
    }
  }

  Future<void> setScheduled(List<Map<String, dynamic>> v) => setPref('scheduled', v.isEmpty ? '' : jsonEncode(v));

  /// [repeat]: '' once, 'day', 'week' or 'month' (v1 반복 보내기).
  Future<void> schedule(String roomId, String text, DateTime at, {bool quiet = false, String repeat = ''}) => setScheduled([
    ...scheduled,
    {
      'id': '${DateTime.now().microsecondsSinceEpoch}',
      'room': roomId,
      'text': text,
      'at': at.millisecondsSinceEpoch,
      'quiet': quiet,
      if (repeat.isNotEmpty) 'repeat': repeat,
    },
  ]);

  /// The next time a repeating message goes, after [now].
  static DateTime nextRepeat(DateTime at, String repeat, DateTime now) {
    var t = at;
    do {
      t = switch (repeat) {
        'day' => DateTime(t.year, t.month, t.day + 1, t.hour, t.minute),
        'week' => DateTime(t.year, t.month, t.day + 7, t.hour, t.minute),
        _ => DateTime(t.year, t.month + 1, t.day, t.hour, t.minute),
      };
    } while (!t.isAfter(now));
    return t;
  }

  /// Sends what is due; failures stay queued.
  Future<void> sendDue() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final all = scheduled;
    final due = all.where((m) => (m['at'] as int) <= now).toList();
    if (due.isEmpty) return;
    final left = [...all];
    for (final m in due) {
      try {
        final room = m['room'] as String, text = m['text'] as String;
        if (m['gif'] is Map) {
          // 내 GIF 예약 보내기 (tip 558).
          await Gifs.sendScheduled(this, room, m);
        } else if (m['quiet'] == true) {
          await backend.sendTextQuietly(room, text);
        } else {
          await backend.sendText(room, text);
        }
        left.removeWhere((x) => x['id'] == m['id']);
        final r = m['repeat'] as String? ?? '';
        if (r.isNotEmpty) {
          final next = nextRepeat(DateTime.fromMillisecondsSinceEpoch(m['at'] as int), r, DateTime.now());
          left.add({...m, 'at': next.millisecondsSinceEpoch});
        }
      } catch (_) {}
    }
    await setScheduled(left);
  }

  Future<Set<String>> _contactIds() async {
    try {
      final asking = requestPeers;
      return {
        for (final p in await backend.contacts())
          if (!asking.contains(p.userId)) p.userId,
      };
    } catch (_) {
      return const {};
    }
  }

  // ------------------------------------------------ 메시지 요청 (v1)
  // A 1:1 chat started by someone who isn't my contact waits in 메시지 요청
  // until I accept it or reply. They can't see whether I read it. Kept in
  // my own settings as dm_request:<room> = their ID.

  static const _requestKey = 'dm_request:';

  // ------------------------------------------------ 실시간 위치 (v1)
  // My live shares: live_loc:<room> = "<message ID>|<end ms>". While the
  // app runs, the point moves once a minute; then it stops by itself.

  static const _liveKey = 'live_loc:';
  Timer? _liveLocTimer;

  /// Tests and the web demo swap this (no GPS there).
  Future<GeoFix> Function() whereAmI = Phone.location;

  /// Rooms where I'm sharing my live location now, with the end time.
  Map<String, (String, DateTime)> get liveShares {
    final out = <String, (String, DateTime)>{};
    for (final e in settings.entries) {
      if (!e.key.startsWith(_liveKey)) continue;
      final p = e.value.split('|');
      final end = p.length == 2 ? int.tryParse(p[1]) : null;
      if (end == null || end <= backend.clock.millisecondsSinceEpoch) continue;
      out[e.key.substring(_liveKey.length)] = (p[0], DateTime.fromMillisecondsSinceEpoch(end));
    }
    return out;
  }

  Future<void> startLiveLocation(String roomId, Duration length) async {
    final f = await whereAmI();
    final until = backend.clock.add(length);
    final id = await backend.sendLiveLocation(roomId, f.lat, f.lon, f.accuracy, until);
    await setPref('$_liveKey$roomId', '$id|${until.millisecondsSinceEpoch}');
    _keepLiveMoving();
  }

  Future<void> stopLiveLocation(String roomId) async {
    final s = liveShares[roomId];
    await setPref('$_liveKey$roomId', '');
    if (liveShares.isEmpty) {
      _liveLocTimer?.cancel();
      _liveLocTimer = null;
    }
    if (s == null) return;
    try {
      final f = await whereAmI();
      await backend.updateLiveLocation(roomId, s.$1, f.lat, f.lon, f.accuracy, backend.clock);
    } catch (_) {}
  }

  /// One step: move every live share; drop the ones that ended.
  Future<void> moveLiveLocations() async {
    final shares = liveShares;
    for (final e in settings.entries.toList()) {
      if (e.key.startsWith(_liveKey) && e.value.isNotEmpty && !shares.containsKey(e.key.substring(_liveKey.length))) await setPref(e.key, '');
    }
    if (shares.isEmpty) {
      _liveLocTimer?.cancel();
      _liveLocTimer = null;
      return;
    }
    GeoFix f;
    try {
      f = await whereAmI();
    } catch (_) {
      return;
    }
    for (final e in shares.entries) {
      try {
        await backend.updateLiveLocation(e.key, e.value.$1, f.lat, f.lon, f.accuracy, e.value.$2);
      } catch (_) {}
    }
  }

  void _keepLiveMoving() {
    if (_liveLocTimer != null || liveShares.isEmpty) return;
    _liveLocTimer = Timer.periodic(const Duration(minutes: 1), (_) => unawaited(moveLiveLocations()));
  }

  /// Is this chat still a message request?
  bool isRequest(String roomId) => (settings['$_requestKey$roomId'] ?? '').isNotEmpty;

  /// People whose chats are still requests.
  Set<String> get requestPeers => {
    for (final e in settings.entries)
      if (e.key.startsWith(_requestKey) && e.value.isNotEmpty) e.value,
  };

  /// Chats waiting in 메시지 요청.
  List<ChatPreview> get requests => [
    for (final c in chats)
      if (c.isDirect && isRequest(c.roomId)) c,
  ];

  /// Accept: the chat moves to my list and they become a contact.
  Future<void> acceptRequest(String roomId) async {
    if (!isRequest(roomId)) return;
    await setPref('$_requestKey$roomId', '');
    friendIds = await _contactIds();
    notifyListeners();
  }

  /// Delete (and block if asked): I leave the chat; they aren't told why.
  Future<void> declineRequest(String roomId, {bool block = false}) async {
    final who = settings['$_requestKey$roomId'] ?? '';
    if (block && who.isNotEmpty) {
      try {
        await backend.block(who, true);
      } catch (_) {}
    }
    try {
      await backend.leave(roomId);
    } catch (_) {}
    await setPref('$_requestKey$roomId', '');
    await refresh();
  }

  /// Settings > Chats > Away reply: one reply per 1:1 chat at most every
  /// 6 hours, only for messages that came after it was switched on.
  /// Admin tools > Auto-moderation: this phone removes rule-breaking
  /// messages in the rooms where it was switched on.
  /// 고정 기간 that ran out: unpinned by whoever may pin there.
  Future<void> unpinExpired() async {
    for (final c in chats) {
      try {
        final cfg = await backend.roomConfig(c.roomId);
        final done = RoomRules.expiredPins(cfg, backend.clock);
        if (done.isEmpty) continue;
        for (final id in done) {
          await backend.pin(c.roomId, id, false);
        }
        var left = <String, dynamic>{...cfg};
        for (final id in done) {
          left = {...left, 'pin_until': RoomRules.withPinUntil(left, id, null)};
        }
        final m = left['pin_until'] as Map;
        await backend.setRoomConfig(c.roomId, 'pin_until', m.isEmpty ? null : m);
      } catch (_) {}
    }
  }

  /// Alerts off for [d] (null = until I turn them back on).
  Future<void> muteChat(String roomId, Duration? d) async {
    await backend.setChatMuted(roomId, true);
    await setPref(muteUntilKey(roomId), d == null ? '' : '${backend.clock.add(d).millisecondsSinceEpoch}');
    await setPref(quietKey(roomId), '');
    await refresh();
  }

  /// Alerts on again (also clears a sound-only mute).
  Future<void> unmuteChat(String roomId) async {
    await backend.setChatMuted(roomId, false);
    await setPref(muteUntilKey(roomId), '');
    await setPref(quietKey(roomId), '');
    await refresh();
  }

  /// "소리 끄기": alerts still come, silently.
  Future<void> setChatQuiet(String roomId, bool on) => setPref(quietKey(roomId), on ? '1' : '');

  /// Timed mutes whose time is over: alerts come back on their own.
  Future<void> liftTimedMutes() async {
    for (final id in expiredMutes(settings, backend.clock)) {
      try {
        await backend.setChatMuted(id, false);
      } catch (_) {}
      settings = {...settings}..remove(muteUntilKey(id));
      await backend.setSetting(muteUntilKey(id), '');
    }
  }

  /// 기간 메시지 금지 that ran out: an admin's phone lets them talk again.
  Future<void> liftMutes() async {
    for (final c in chats.where((c) => !c.isDirect)) {
      try {
        final cfg = await backend.roomConfig(c.roomId);
        final done = RoomRules.expiredMutes(cfg, backend.clock);
        if (done.isEmpty) continue;
        final role = await backend.myRole(c.roomId);
        if (!RoomRules.can(cfg, role, backend.userId ?? '', 'mute')) continue;
        var left = cfg;
        for (final u in done) {
          await backend.setMemberLevel(c.roomId, u, 0);
          left = {...left, 'mutes': RoomRules.withMute(left, u, null)};
        }
        final m = left['mutes'] as Map;
        await backend.setRoomConfig(c.roomId, 'mutes', m.isEmpty ? null : m);
      } catch (_) {}
    }
  }

  Future<void> runAutoMod() async {
    for (final c in chats) {
      if (!c.isDirect && !c.isChannel) {
        try {
          await antiSpamRoom(c.roomId);
        } catch (_) {}
      }
      if (!on('automod_on:${c.roomId}')) continue;
      try {
        await autoModRoom(c.roomId);
      } catch (_) {}
    }
  }

  /// 익명 관리자 (tip 94): each group's anonymous times, so the chat list
  /// never names them (in the last-message line or "입력 중").
  Map<String, Map<String, dynamic>> anonCfgs = {};

  Future<void> loadAnon() async {
    final next = <String, Map<String, dynamic>>{};
    for (final c in chats.where((c) => !c.isDirect && !c.isChannel)) {
      try {
        final cfg = await backend.roomConfig(c.roomId);
        if (cfg['anon'] is! Map) continue;
        next[c.roomId] = {'anon': cfg['anon']};
      } catch (_) {}
    }
    anonCfgs = next;
  }

  /// 강력 스팸 차단 (tip 365): when the room has it on and I'm an admin who
  /// may delete, my phone removes spam (the server can't read messages).
  /// Three removals of one person in a day: they can't write for a day.
  /// Returns how many messages were removed.
  Future<int> antiSpamRoom(String roomId) async {
    final cfg = await backend.roomConfig(roomId);
    if (!AntiSpam.on(cfg)) return 0;
    final me = backend.userId ?? '';
    final role = await backend.myRole(roomId);
    if (!RoomRules.can(cfg, role, me, 'delete')) return 0;
    final msgs = await backend.timeline(roomId, limit: 200);
    final members = await backend.members(roomId);
    final admins = {
      for (final m in members)
        if (m.role == 'owner' || m.role == 'admin') m.userId,
    };
    final now = backend.clock;
    final bad = AntiSpam.find(msgs, admins: admins, trusted: AntiSpam.trusted(cfg), joined: {for (final m in members) m.userId: m.since}, now: now);
    var n = 0;
    var mutes = cfg;
    for (final (m, _) in bad) {
      if (!_modDone.add(m.id)) continue;
      await backend.deleteMessage(roomId, m.id);
      final name = members.where((x) => x.userId == m.sender).firstOrNull?.name ?? m.sender;
      await setPref('mod_log:$roomId', withLogEntry(settings, roomId, ModEntry(now, 'spam', name, AntiSpam.detail(m))));
      n++;
      // Strikes: removals of this person in the last day (this phone's log).
      final day = now.subtract(const Duration(days: 1));
      final strikes = modLogOf(settings, roomId).where((e) => e.kind == 'spam' && e.time.isAfter(day) && AntiSpam.splitDetail(e.detail).$1 == m.sender).length;
      if (strikes >= AntiSpam.strikes && RoomRules.muteUntil(mutes, m.sender) == null && RoomRules.can(cfg, role, me, 'mute')) {
        try {
          await backend.setMemberLevel(roomId, m.sender, -1);
          mutes = {...mutes, 'mutes': RoomRules.withMute(mutes, m.sender, now.add(const Duration(days: 1)))};
          await backend.setRoomConfig(roomId, 'mutes', mutes['mutes']);
          await setPref('spam_muted:$roomId:${m.sender}', '1');
          await logMod(roomId, 'muted', name);
        } catch (_) {}
      }
    }
    if (n > 0) notifyListeners();
    return n;
  }

  final _modDone = <String>{};

  /// Checks one room now; returns how many messages were removed.
  Future<int> autoModRoom(String roomId) async {
    final msgs = await backend.timeline(roomId, limit: 200);
    final members = await backend.members(roomId);
    final admins = {
      for (final m in members)
        if (m.role == 'owner' || m.role == 'admin') m.userId,
    };
    if (!admins.contains(backend.userId)) return 0;
    final key = 'first_seen:$roomId';
    final first = !settings.containsKey(key);
    var seen = <String, int>{};
    try {
      seen = Map<String, int>.from(jsonDecode(settings[key] ?? '{}') as Map);
    } catch (_) {}
    final now = DateTime.now();
    var changed = false;
    for (final m in members) {
      if (seen.containsKey(m.userId)) continue;
      // Everyone already here when the switch went on counts as known.
      seen[m.userId] = first ? 0 : now.millisecondsSinceEpoch;
      changed = true;
    }
    if (changed || first) await setPref(key, jsonEncode(seen));
    final bad = violations(
      msgs,
      words: bannedWordsOf(settings, roomId),
      newLinks: on('automod_links:$roomId', fallback: true),
      flood: on('automod_flood:$roomId', fallback: true),
      firstSeen: seen,
      admins: admins,
      now: now,
    );
    var n = 0;
    for (final (m, why) in bad) {
      if (!_modDone.add(m.id)) continue;
      await backend.deleteMessage(roomId, m.id);
      final name = members.where((x) => x.userId == m.sender).firstOrNull?.name ?? m.sender;
      await setPref('mod_log:$roomId', withLogEntry(settings, roomId, ModEntry(now, 'removed', name, why.name)));
      n++;
    }
    return n;
  }

  /// 키워드 자동 답장: my phone answers member messages with a set word, in
  /// rooms where I'm an admin. Only messages that came after the rules were
  /// last saved or checked.
  Future<void> sendKeywordReplies() async {
    if (backend.sessionRole != 'normal') return;
    for (final c in chats) {
      final rules = keywordRules(settings, c.roomId);
      if (rules.isEmpty || c.last == null || c.last!.mine) continue;
      final seenKey = 'keyword_seen:${c.roomId}';
      final since = DateTime.fromMillisecondsSinceEpoch(int.tryParse(pref(seenKey, '0')) ?? 0);
      if (!c.last!.time.isAfter(since)) continue;
      try {
        final role = await backend.myRole(c.roomId);
        if (role != 'owner' && role != 'admin') continue;
        final msgs = await backend.timeline(c.roomId, limit: 50);
        final todo = keywordAnswers(msgs, rules, since, const {});
        await setPref(seenKey, '${msgs.isEmpty ? since.millisecondsSinceEpoch : msgs.last.time.millisecondsSinceEpoch}');
        for (final (m, r) in todo.take(5)) {
          await backend.reply(c.roomId, m.id, r.answer);
        }
      } catch (_) {}
    }
  }

  /// Adds a line to this phone's admin log for a room.
  Future<void> logMod(String roomId, String kind, String name, [String detail = '']) =>
      setPref('mod_log:$roomId', withLogEntry(settings, roomId, ModEntry(DateTime.now(), kind, name, detail)));

  /// 이름 색 (v1): groups I joined after picking get my colour too.
  Future<void> applyNameColor() async {
    final c = pref('name_color', '');
    // 이름·프로필 꾸미기 (tips 402 + 409): 1:1 chats get my whole look as a
    // hidden end-to-end encrypted note (groups read it from my member event).
    for (final d in chats.where((x) => x.isDirect && !x.isBot)) {
      final key = 'my_look_sent:${d.roomId}';
      final sent = pref(key, '');
      if (sent == c || (c.isEmpty && sent.isEmpty)) continue;
      try {
        await backend.sendSignal(d.roomId, PersonLook.signalKind, {'v': c});
        await setPref(key, c);
      } catch (_) {}
    }
    for (final g in chats.where((x) => !x.isDirect && !x.isChannel)) {
      final key = 'name_color_set:${g.roomId}';
      if (pref(key, '') == c) continue;
      if (c.isEmpty && pref(key, '').isEmpty) continue;
      try {
        await backend.setMyRoomLook(g.roomId, color: c);
        await setPref(key, c);
      } catch (_) {}
    }
  }

  Future<void> sendAwayReplies() async {
    if (!on('away_on') || backend.sessionRole != 'normal') return;
    final since = DateTime.tryParse(pref('away_since', ''));
    final text = pref('away_text', '').trim();
    if (since == null || text.isEmpty) return;
    final now = DateTime.now();
    for (final c in chats) {
      final m = c.last;
      if (!c.isDirect || c.isBot || m == null || m.mine || m.time.isBefore(since)) continue;
      final sent = DateTime.tryParse(pref('away_sent:${c.roomId}', ''));
      if (sent != null && now.difference(sent) < const Duration(hours: 6)) continue;
      await setPref('away_sent:${c.roomId}', now.toIso8601String());
      try {
        await backend.sendText(c.roomId, text);
      } catch (_) {}
    }
  }

  // ---- My profile card (photo, about me, birthday) -------------------
  // Kept on this phone too, so a friends-only photo still shows here.

  Uint8List? _mePhoto;
  String _mePhotoRaw = '';

  /// My own photo as I last set it (also when only friends may see it).
  Uint8List? get myOwnPhoto {
    final raw = pref('me_photo', '');
    if (raw.isEmpty) return null;
    if (raw != _mePhotoRaw) {
      _mePhotoRaw = raw;
      _mePhoto = base64Decode(raw);
    }
    return _mePhoto;
  }

  /// Older installs kept the photo and about-me only on the server.
  Future<void> _loadMyProfile() async {
    if (on('me_loaded')) return;
    try {
      final ph = await backend.myPhoto();
      if (ph != null && ph.isNotEmpty && pref('me_photo', '').isEmpty) await setPref('me_photo', base64Encode(ph));
      final me = backend.userId;
      if (me != null && pref('me_bio', '').isEmpty) await setPref('me_bio', await backend.bioOf(me));
    } catch (_) {}
    await setOn('me_loaded', true);
  }

  /// Saves my profile here and shares it by my 공개 범위 choices.
  Future<void> saveMyProfile({List<int>? photo, bool removePhoto = false, String? bio, String? birthday, DateTime? now}) async {
    await _loadMyProfile();
    // 예전 사진 (tip 58): the photo being replaced stays on this phone.
    final was = myOwnPhoto;
    if (was != null && (removePhoto || (photo != null && photo.isNotEmpty))) await MyPhotos.keep(this, was, now: now);
    if (removePhoto) await setPref('me_photo', '');
    if (photo != null && photo.isNotEmpty) await setPref('me_photo', base64Encode(photo));
    if (bio != null) await setPref('me_bio', bio.trim());
    if (birthday != null) await setPref('me_birthday', birthday);
    await publishProfile();
  }

  /// Sends my card: to every 1:1 friend (and the public profile), or with
  /// [only] just to new friends.
  Future<void> publishProfile({List<String> only = const []}) async {
    await _loadMyProfile();
    // 공개 사진 (tip 374): people my 프로필 사진 setting leaves out see it.
    // 'nobody' + 공개 사진 = everyone (friends too) gets the 공개 사진;
    // 'contacts' = friends get the real one, the public profile the 공개 사진.
    final who = pref('who_photo', 'everyone');
    final pub = Features.profile && who != 'everyone' ? MyPhotos.publicPhoto(this) : null;
    final real = pub != null && who == 'nobody' ? pub : (myOwnPhoto ?? const <int>[]);
    await backend.shareProfile(
      mime: MyPhotos.mimeOf(real),
      photo: real,
      bio: pref('me_bio', ''),
      birthday: pref('me_birthday', ''),
      whoPhoto: pub != null && who == 'nobody' ? 'everyone' : who,
      whoBio: pref('who_bio', 'everyone'),
      whoBirthday: pref('who_birthday', 'contacts'),
      only: only,
    );
    if (pub != null && who == 'contacts' && only.isEmpty) await backend.setMyPhoto(MyPhotos.mimeOf(pub), pub);
    final done = {...pref('profile_sent', '').split(',').where((x) => x.isNotEmpty), ...only};
    if (only.isEmpty)
      done.addAll([
        for (final c in chats)
          if (c.isDirect) c.roomId,
      ]);
    await setPref('profile_sent', done.join(','));
  }

  /// New 1:1 friends get my card once.
  Future<void> _cardToNewFriends() async {
    if (!loggedIn) return;
    final done = pref('profile_sent', '').split(',').toSet();
    final fresh = [
      for (final c in chats)
        if (c.isDirect && !c.isBot && !done.contains(c.roomId)) c.roomId,
    ];
    if (fresh.isEmpty) return;
    if (pref('me_photo', '').isEmpty && pref('me_bio', '').isEmpty && pref('me_birthday', '').isEmpty && on('me_loaded')) {
      await setPref('profile_sent', [...done.where((x) => x.isNotEmpty), ...fresh].join(','));
      return;
    }
    await publishProfile(only: fresh);
  }

  final _roomPhotos = <String, Uint8List?>{};
  final _roomPhotoAsked = <String, DateTime>{};

  /// A group/channel photo as bytes (kept, so no flicker); asks for it now
  /// and then. Null = none (yet).
  Uint8List? roomPhoto(String roomId, {bool fresh = false}) {
    final asked = _roomPhotoAsked[roomId];
    if (fresh || asked == null || DateTime.now().difference(asked) > const Duration(minutes: 10)) {
      _roomPhotoAsked[roomId] = DateTime.now();
      unawaited(_loadRoomPhoto(roomId));
    }
    return _roomPhotos[roomId];
  }

  Future<void> _loadRoomPhoto(String roomId) async {
    try {
      final ph = await backend.roomPhoto(roomId);
      final old = _roomPhotos[roomId];
      final now = ph == null || ph.isEmpty ? null : ph;
      if (old?.length == now?.length && (old == null) == (now == null)) {
        _roomPhotos[roomId] = now;
        return;
      }
      _roomPhotos[roomId] = now;
      notifyListeners();
    } catch (_) {}
  }

  /// Admins: sets (or with null, takes off) the room photo.
  Future<void> setRoomPhoto(String roomId, Uint8List? bytes, {String mime = 'image/jpeg'}) async {
    await backend.setRoomPhoto(roomId, mime, bytes);
    _roomPhotos[roomId] = bytes == null || bytes.isEmpty ? null : bytes;
    _roomPhotoAsked[roomId] = DateTime.now();
    notifyListeners();
  }

  final _cards = <String, ProfileCard>{};
  final _cardPhotos = <String, Uint8List>{};
  final _cardAsked = <String, DateTime>{};

  /// Someone's card (photo, about me, birthday); asks for it now and then.
  ProfileCard? cardOf(String userId, {bool fresh = false}) {
    final asked = _cardAsked[userId];
    if (fresh || asked == null || DateTime.now().difference(asked) > const Duration(minutes: 10)) {
      _cardAsked[userId] = DateTime.now();
      unawaited(_loadCard(userId));
    }
    return _cards[userId];
  }

  /// Their photo as bytes for Image.memory (kept, so no flicker).
  Uint8List? cardPhoto(String userId) {
    cardOf(userId);
    return _cardPhotos[userId];
  }

  Future<void> _loadCard(String userId) async {
    if (userId == backend.userId) return;
    try {
      final c = await backend.profileOf(userId);
      final old = _cards[userId];
      _cards[userId] = c;
      final ph = c.photo;
      if (ph == null || ph.isEmpty) {
        _cardPhotos.remove(userId);
      } else {
        _cardPhotos[userId] = Uint8List.fromList(ph);
      }
      await _birthdayAlert(userId, c);
      final same = old != null && old.bio == c.bio && old.birthday == c.birthday && old.photo?.length == c.photo?.length;
      if (!same) notifyListeners();
    } catch (_) {}
  }

  /// "생일 알림": a local alert at 9 am on a friend's birthday.
  Future<void> _birthdayAlert(String userId, ProfileCard c) async {
    if (!on('birthday_alert') || c.birthday.isEmpty) return;
    final md = c.birthday.split('-');
    final m = int.tryParse(md[md.length - 2]), d = int.tryParse(md.last);
    if (m == null || d == null) return;
    final now = DateTime.now();
    var at = DateTime(now.year, m, d, 9);
    if (at.isBefore(now)) at = DateTime(now.year + 1, m, d, 9);
    final name = chats.where((x) => x.isDirect && x.peer == userId).firstOrNull?.name ?? userId;
    try {
      await remindAt?.call(userId.hashCode & 0x3fffffff, at, name);
    } catch (_) {}
  }

  /// Downloaded copies past their keep time go once per app start.
  bool _keepChecked = false;

  /// Last message id per chat (데이터 사용량: messages that arrived).
  final _lastIds = <String, String>{};

  void _noteArrived() {
    final first = _lastIds.isEmpty;
    for (final c in chats) {
      final m = c.last;
      if (m == null) continue;
      final before = _lastIds[c.roomId];
      _lastIds[c.roomId] = m.id;
      if (first || before == m.id || m.mine || m.kind != 'text') continue;
      DataUsage.note('messages', sent: false, bytes: utf8.encode(m.body ?? '').length);
    }
  }

  Future<void> refresh() async {
    startDataUsage(this);
    if (!_keepChecked) {
      _keepChecked = true;
      unawaited(Downloads.instance.applyKeep(this).then((_) {}, onError: (_) {}));
    }
    try {
      await sendDue();
    } catch (_) {}
    await refreshTrust();
    try {
      final all = await backend.invitations();
      final friends = await _contactIds();
      friendIds = friends;
      final keep = <Invite>[];
      for (final i in all) {
        // Accounts the operator marked '가짜' can't start chats with me.
        final ok =
            allowedFrom(settings, i.direct ? 'who_messages' : 'who_invites', i.inviter, friends) &&
            !(trust.flags[i.inviter] == 'fake' && !friends.contains(i.inviter));
        try {
          if (!ok) {
            // Privacy: people I don't allow can't add me or start a chat.
            // A group/channel invitation says why (no words, a fixed mark),
            // so its admins can send me the link instead (tip 385).
            final onlyContacts = !i.direct && !allowedFrom(settings, 'who_invites', i.inviter, friends);
            await (onlyContacts ? backend.declineBlocked(i.roomId) : backend.decline(i.roomId));
          } else if (i.direct) {
            // 아이디 키: a stranger's first chat without the right key waits
            // unseen (nothing tells them; switching the key off lets it in).
            if (!IdKey.lets(myKey: pref(IdKey.pref, ''), reason: i.name, from: i.inviter, me: backend.userId ?? '', friend: friends.contains(i.inviter))) {
              continue;
            }
            // Someone started a 1:1 chat: open it on its own. A stranger's
            // goes to 메시지 요청 first (설정 > 개인정보, on by default).
            if (!friends.contains(i.inviter) && on('message_requests', fallback: true)) await setPref('$_requestKey${i.roomId}', i.inviter);
            await backend.join(i.roomId);
            // 모르는 사람 자동 보관 (tip 343): into 보관함, muted.
            if (await LoginSafety.tuckStranger(this, i, friends)) tuckedNow.value++;
          } else if (Features.channelTips && await ChannelDm.takeInvite(this, i)) {
            // 526: a subscriber's message room for a channel I run.
          } else {
            keep.add(i);
          }
        } catch (_) {
          if (!i.direct) keep.add(i);
        }
      }
      invites = keep;
    } catch (_) {
      invites = const [];
    }
    try {
      savedRoomId ??= await backend.savedRoom();
    } catch (_) {}
    // "읽지 않음으로 표시" (this phone only): shows as one unread until opened.
    await liftTimedMutes();
    chats = [for (final c in _savedFirst(await backend.chats())) c.unread == 0 && on('marked_unread:${c.roomId}') ? c.withUnread(1) : c];
    _noteArrived();
    // 보관함 설정 (tip 187): unmuted archived chats come back on news.
    try {
      if (await liftArchived()) {
        chats = [for (final c in _savedFirst(await backend.chats())) c.unread == 0 && on('marked_unread:${c.roomId}') ? c.withUnread(1) : c];
      }
    } catch (_) {}
    if (Features.channelTips) await ChannelDm.scan(this);
    // 우리식 기능: ❤ and 1년 전 오늘, counted on this phone.
    if (Features.ownWay) await OwnWay.afterRefresh(this);
    try {
      communities = await backend.communities();
    } catch (_) {
      communities = const [];
    }
    unawaited(loadTimers());
    try {
      await sendAwayReplies();
    } catch (_) {}
    _keepLiveMoving();
    try {
      await applyNameColor();
    } catch (_) {}
    try {
      await _cardToNewFriends();
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    await runAutoMod();
    await loadAnon();
    try {
      await sendKeywordReplies();
    } catch (_) {}
    await liftMutes();
    await unpinExpired();
    await handleSignals();
    // 임시 글 이어쓰기 (tip 241): drafts from my other devices.
    await takeOtherDrafts();
    if (Features.loginSafety) {
      await checkNewLogins();
      try {
        await LoginSafety.tellVoiceRule(this);
      } catch (_) {}
    }
    // Admin phones: welcome + rules to people who just joined (encrypted).
    try {
      await RoomTexts.run(this);
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    // ... and the topic list (주제, tip 527).
    try {
      await Topics.run(this);
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    // 글 제안 (tip 531): accepted posts whose time has come.
    try {
      await SuggestPost.run(this);
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    try {
      bubbles = await backend.pendingBubbles();
    } catch (_) {
      bubbles = const [];
    }
    try {
      final all = await backend.stories();
      stories = [
        for (final x in all)
          if (x.inRow) x,
      ];
      // Kept on profiles past their hours (tips 392 / 468 / 534).
      keptStories = [
        for (final x in all)
          if (x.kept && !x.feed) x,
      ];
      feed = [
        for (final x in all.reversed)
          if (x.feed) x,
      ];
      if (Features.feed) feedLikes = await backend.feedLikes();
    } catch (_) {
      stories = const [];
    }
    try {
      final n = await backend.takeEraseNotices();
      if (n.isNotEmpty) erasedBy = [...erasedBy, ...n];
    } catch (_) {}
    try {
      final friends = await _contactIds();
      final all = await backend.ringingCalls();
      ringing = [];
      for (final r in all) {
        if (allowedFrom(settings, 'who_calls', r.from, friends)) {
          // 기기별 통화 끄기 (tip 311): this device stays quiet, my other
          // devices still ring.
          if (!callsOffHere) ringing.add(r);
        } else {
          // Privacy: calls from people I don't allow are turned down quietly.
          unawaited(backend.hangupCall(r.roomId, r.callId, 'busy').catchError((_) {}));
        }
      }
    } catch (_) {
      ringing = const [];
    }
    publishBubbles?.call(bubbles, chats);
    if (inBackground) {
      try {
        await showNotices?.call(backend);
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Keeps asking the server for news while the app is open.
  void startLive() {
    if (_live) return;
    _live = true;
    final gen = ++_generation;
    unawaited(() async {
      while (_live && gen == _generation) {
        try {
          await backend.sync();
          if (!_live || gen != _generation) break;
          await refresh();
          unawaited(backend.runExpiry().then((_) {}, onError: (_) {}));
        } catch (e, st) {
          ErrorLog.add(e, st);
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
    }());
  }

  void stopLive() {
    _live = false;
    _generation++;
    // Open documents and the small video window hold decrypted bytes:
    // they go on lock, account switch and logout (tip 473, 334).
    OpenDocs.instance.clear();
    for (final f in List.of(onStop)) {
      f();
    }
  }

  /// Screens outside core (the small video window) that must close with
  /// the session.
  static final onStop = <void Function()>[];

  @override
  void dispose() {
    _batteryTimer?.cancel();
    _liveLocTimer?.cancel();
    stopLive();
    super.dispose();
  }
}

/// Gives every screen the app state.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Same, without rebuilding on changes (for taps and callbacks).
  static AppState read(BuildContext c) => c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
