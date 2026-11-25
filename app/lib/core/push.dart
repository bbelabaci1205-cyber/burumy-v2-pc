// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Phone notifications. Google (Android) or Apple (iPhone) only deliver a
// wake-up with nothing in it; the app then fetches and opens new messages
// here on the phone and shows them. Muted and hidden chats never notify.
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui' show IsolateNameServer, Locale, PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../ui/common.dart' show previewTextL;
import 'backend.dart';
import 'rules.dart';
import 'sounds.dart' show messageSounds;

/// Build settings (never written in code).
const _gateway = String.fromEnvironment('BURUMY_PUSH_GATEWAY');
const _fbApiKey = String.fromEnvironment('FIREBASE_API_KEY');
const _fbAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
const _fbSender = String.fromEnvironment('FIREBASE_SENDER_ID');
const _fbProject = String.fromEnvironment('FIREBASE_PROJECT_ID');

/// App ids our push gateway knows.
const androidPushApp = 'app.burumy.android';
const iosPushApp = 'app.burumy.ios';

/// Name the open app registers so a wake-up in the background can hand
/// the work to it instead of opening the encrypted store a second time.
const _portName = 'burumy.push.wake';

/// Title and text of a notification (both made on the phone).
(String, String) noticeText(L l, Notice n) {
  if (n.chat.isEmpty) return (l.appName, l.noticeNew);
  final what = n.kind == 'text' ? (n.body ?? l.noticeNew) : previewTextL(l, kind: n.kind, body: n.body);
  return (n.chat, n.sender.isEmpty ? what : '${n.sender}: $what');
}

class Push {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static ReceivePort? _port;

  /// Push works only in phone builds that were given the settings.
  static bool get configured => !kIsWeb && (Platform.isAndroid || Platform.isIOS) && _gateway.isNotEmpty && _fbApiKey.isNotEmpty;

  static Future<bool> _init() async {
    if (_ready) return true;
    if (!configured) return false;
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(apiKey: _fbApiKey, appId: _fbAppId, messagingSenderId: _fbSender, projectId: _fbProject),
      );
    }
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
      ),
    );
    _ready = true;
    return true;
  }

  /// After login in the open app: ask permission, register this phone with
  /// our server, and take over wake-ups while the app is alive.
  static Future<void> start(Backend b, {required Future<void> Function() onWake, required Future<void> Function(RemoteMessage) background}) async {
    if (!await _init()) return;
    final m = FirebaseMessaging.instance;
    final ok = await m.requestPermission();
    if (ok.authorizationStatus == AuthorizationStatus.denied) return;
    final String? key;
    final String app;
    if (Platform.isIOS) {
      key = await m.getAPNSToken();
      app = iosPushApp;
    } else {
      key = await m.getToken();
      app = androidPushApp;
    }
    if (key == null) return;
    await b.setPush(_gateway, key, app);
    m.onTokenRefresh.listen((t) {
      if (!Platform.isIOS) b.setPush(_gateway, t, app);
    });
    FirebaseMessaging.onBackgroundMessage(background);
    _port?.close();
    IsolateNameServer.removePortNameMapping(_portName);
    final port = ReceivePort();
    _port = port;
    IsolateNameServer.registerPortWithName(port.sendPort, _portName);
    port.listen((_) => onWake());
  }

  /// Shows new messages as notifications (the open app calls this after a
  /// sync while it is in the background).
  static Future<void> showNew(Backend b, L l) async {
    if (!await _init()) return;
    final list = await b.notifications(max: 5);
    final prefs = await b.settings();
    final chats = {for (final c in await b.chats()) c.roomId: c};
    final now = DateTime.now();
    for (final n in list) {
      final c = chats[n.roomId];
      if (!noticeAllowed(n, prefs, c, now)) continue;
      final kind = c == null ? 'direct' : (c.isDirect ? 'direct' : (c.isChannel ? 'channel' : 'group'));
      var (title, body) = noticeText(l, n);
      if (prefs['preview_$kind'] == '0') body = l.noticeNew;
      final sound = prefs['sound_$kind'] ?? 'nuri';
      final quiet = sound == 'none' || !messageSounds.contains(sound);
      await _local.show(
        id: n.roomId.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          // Android keeps one channel per sound (a channel's sound can't change).
          android: AndroidNotificationDetails(
            quiet ? 'messages_quiet' : 'messages_$sound',
            l.noticeChannel,
            importance: Importance.high,
            priority: Priority.high,
            playSound: !quiet,
            sound: quiet ? null : RawResourceAndroidNotificationSound('burumy_$sound'),
            // Settings > Notifications > Names on lock screen: off = the
            // locked screen only says a message came.
            visibility: prefs['lock_name'] == '0' ? NotificationVisibility.private : NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(presentSound: !quiet),
        ),
        payload: n.roomId,
      );
    }
  }

  static bool _localReady = false;

  /// Message reminders ("알림 받기"): the phone itself shows them at the
  /// time; nothing goes to the server. Phone builds only.
  static Future<void> remind(int id, DateTime at, String title, String body, String channel) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!_localReady) {
      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()),
      );
      await _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
      _localReady = true;
    }
    await _local.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails('reminders', channel, importance: Importance.high, priority: Priority.high),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelRemind(int id) async {
    if (kIsWeb || !_localReady) return;
    await _local.cancel(id: id);
  }
}

/// Runs when a wake-up arrives and the app is not open on screen
/// (main.dart's background entry calls it with a way to open the engine).
Future<void> handlePushInBackground(Future<Backend?> Function() open) async {
  // The app is still alive in the background: let it do the work, so the
  // encrypted store is never opened twice at once.
  final alive = IsolateNameServer.lookupPortByName(_portName);
  if (alive != null) {
    alive.send('wake');
    return;
  }
  final b = await open();
  if (b == null || !b.loggedIn) return;
  try {
    await b.sync(wait: Duration.zero);
  } catch (_) {}
  final lang = PlatformDispatcher.instance.locale.languageCode == 'ko' ? 'ko' : 'en';
  await Push.showNew(b, lookupL(Locale(lang)));
}
