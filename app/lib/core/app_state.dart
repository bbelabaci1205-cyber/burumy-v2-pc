// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// App-wide state: who is logged in, the chat list, the look (brand family,
// language). Keeps a live update loop while logged in.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../brand/brand.dart';
import 'automod.dart';
import 'backend.dart';
import 'error_log.dart';
import 'features.dart';
import '../l10n/app_localizations.dart';
import 'rules.dart';

class AppState extends ChangeNotifier {
  AppState(this.backend, {this.family = BrandFamily.green, this.locale});

  final Backend backend;
  BrandFamily family;

  /// null = follow the phone's language.
  Locale? locale;

  List<ChatPreview> chats = const [];

  /// My 1:1 contacts' user ids (folders: 연락처 / 비연락처).
  Set<String> friendIds = const {};

  /// Bubbles waiting for me (who and when only).
  List<BubbleRef> bubbles = const [];

  /// Stories within their 24 hours (mine and friends').
  List<Story> stories = const [];

  /// Friend-feed posts, newest first (shown only while [Features.feed] is on).
  List<Story> feed = const [];
  List<FeedLike> feedLikes = const [];

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
    if (role == null) return false;
    await backend.startSession(role);
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
      } catch (_) {}
    }
    return id;
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

  /// Saved messages first in the list, under its own name.
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
    return [named, ...list.where((x) => x.roomId != id)];
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
    await afterLogin();
  }

  Future<void> login(String id, String password) async {
    await backend.login(id: id, password: password);
    await afterLogin();
  }

  Future<void> afterLogin() async {
    await _loadSettings();
    notifyListeners();
    await refresh();
    startLive();
    final p = startPush;
    if (p != null) unawaited(p(this).catchError((_) {}));
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
    bubbles = const [];
    ringing = const [];
    invites = const [];
    settings = const {};
    savedRoomId = null;
    publishBubbles?.call(const [], const []);
    notifyListeners();
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

  Future<void> schedule(String roomId, String text, DateTime at, {bool quiet = false}) => setScheduled([
    ...scheduled,
    {'id': '${DateTime.now().microsecondsSinceEpoch}', 'room': roomId, 'text': text, 'at': at.millisecondsSinceEpoch, 'quiet': quiet},
  ]);

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
        if (m['quiet'] == true) {
          await backend.sendTextQuietly(room, text);
        } else {
          await backend.sendText(room, text);
        }
        left.removeWhere((x) => x['id'] == m['id']);
      } catch (_) {}
    }
    await setScheduled(left);
  }

  Future<Set<String>> _contactIds() async {
    try {
      return {for (final p in await backend.contacts()) p.userId};
    } catch (_) {
      return const {};
    }
  }

  /// Settings > Chats > Away reply: one reply per 1:1 chat at most every
  /// 6 hours, only for messages that came after it was switched on.
  /// Admin tools > Auto-moderation: this phone removes rule-breaking
  /// messages in the rooms where it was switched on.
  Future<void> runAutoMod() async {
    for (final c in chats) {
      if (!on('automod_on:${c.roomId}')) continue;
      try {
        await autoModRoom(c.roomId);
      } catch (_) {}
    }
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

  /// Adds a line to this phone's admin log for a room.
  Future<void> logMod(String roomId, String kind, String name, [String detail = '']) =>
      setPref('mod_log:$roomId', withLogEntry(settings, roomId, ModEntry(DateTime.now(), kind, name, detail)));

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
  Future<void> saveMyProfile({List<int>? photo, bool removePhoto = false, String? bio, String? birthday}) async {
    await _loadMyProfile();
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
    await backend.shareProfile(
      mime: 'image/png',
      photo: myOwnPhoto ?? const [],
      bio: pref('me_bio', ''),
      birthday: pref('me_birthday', ''),
      whoPhoto: pref('who_photo', 'everyone'),
      whoBio: pref('who_bio', 'everyone'),
      whoBirthday: pref('who_birthday', 'contacts'),
      only: only,
    );
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

  Future<void> refresh() async {
    try {
      await sendDue();
    } catch (_) {}
    try {
      final all = await backend.invitations();
      final friends = await _contactIds();
      friendIds = friends;
      final keep = <Invite>[];
      for (final i in all) {
        final ok = allowedFrom(settings, i.direct ? 'who_messages' : 'who_invites', i.inviter, friends);
        try {
          if (!ok) {
            // Privacy: people I don't allow can't add me or start a chat.
            await backend.decline(i.roomId);
          } else if (i.direct) {
            // Someone started a 1:1 chat: open it on its own.
            await backend.join(i.roomId);
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
    chats = [for (final c in _savedFirst(await backend.chats())) c.unread == 0 && on('marked_unread:${c.roomId}') ? c.withUnread(1) : c];
    try {
      await sendAwayReplies();
    } catch (_) {}
    try {
      await _cardToNewFriends();
    } catch (e, st) {
      ErrorLog.add(e, st);
    }
    await runAutoMod();
    try {
      bubbles = await backend.pendingBubbles();
    } catch (_) {
      bubbles = const [];
    }
    try {
      final all = await backend.stories();
      stories = [
        for (final x in all)
          if (!x.feed) x,
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
          ringing.add(r);
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
  }

  @override
  void dispose() {
    _batteryTimer?.cancel();
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
