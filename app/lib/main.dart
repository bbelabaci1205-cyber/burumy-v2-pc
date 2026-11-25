// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Burumy v2 app entry. iOS-standard look first (rulebook ch. 2), Korean and
// English built in (ch. 6), green and blue brand families side by side (ch. 4).
import 'dart:async';

import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'core/desktop_update.dart';
import 'core/reminders.dart';
import 'core/app_state.dart';
import 'core/error_log.dart';
import 'core/call_media.dart' show LiveKitMedia;
import 'core/phone.dart';
import 'core/push.dart';
import 'core/rust_backend.dart';
import 'design/tokens.dart';
import 'l10n/app_localizations.dart';
import 'src/rust/frb_generated.dart';
import 'ui/scroll_edge.dart';
import 'ui/glass.dart';
import 'ui/panic.dart';
import 'ui/bubbles.dart';
import 'ui/auth_page.dart';
import 'ui/home.dart';
import 'ui/wide.dart';
import 'ui/lock_page.dart';

/// Server address comes from the build (never written in code).
const _server = String.fromEnvironment('BURUMY_SERVER', defaultValue: 'http://127.0.0.1:6167');

/// Keeps the login in the iPhone Keychain / Android Keystore.
class KeychainLock implements LockStore {
  static const _s = FlutterSecureStorage();
  static const _k = 'burumy.lock';
  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String? json) => json == null ? _s.delete(key: _k) : _s.write(key: _k, value: json);
}

class KeychainStore implements SessionStore {
  static const _s = FlutterSecureStorage();
  static const _k = 'burumy.session';
  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String? json) => json == null ? _s.delete(key: _k) : _s.write(key: _k, value: json);
}

/// Opens the engine from the saved login (also used by a background
/// wake-up, which must never forget the login on a passing error).
Future<RustBackend> openBackend({bool background = false}) async {
  final dir = await getApplicationSupportDirectory();
  // The local store passphrase is made once and kept in the keychain.
  const keychain = FlutterSecureStorage();
  var pass = await keychain.read(key: 'burumy.store');
  if (pass == null) {
    pass = DateTime.now().microsecondsSinceEpoch.toRadixString(36) + Object().hashCode.toRadixString(36);
    await keychain.write(key: 'burumy.store', value: pass);
  }
  return RustBackend.open(
    server: _server,
    dataDir: '${dir.path}/burumy',
    storePassphrase: pass,
    store: KeychainStore(),
    lock: KeychainLock(),
    forgetBrokenSession: !background,
  );
}

/// Push wake-up while the app is closed (its own background isolate).
@pragma('vm:entry-point')
Future<void> burumyPushInBackground(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await handlePushInBackground(() async {
    await RustLib.init();
    return openBackend(background: true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  final backend = await openBackend();
  AppState.publishBubbles = HomeBubbles.publish;
  final state = AppState(backend)..watchBattery(Phone.battery, net: Phone.network);
  AppState.startPush = (s) => Push.start(s.backend, onWake: s.wake, background: burumyPushInBackground);
  AppState.showNotices = (b) async {
    final lang = state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    await Push.showNew(b, lookupL(Locale(lang == 'ko' ? 'ko' : 'en')));
  };
  scheduleReminder = (r) {
    final l = lookupL(Locale((state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode) == 'ko' ? 'ko' : 'en'));
    return Push.remind(r.id, r.at, r.chat.isEmpty ? l.appName : r.chat, l.remindDue, l.remindChannel);
  };
  cancelReminder = (r) => Push.cancelRemind(r.id);
  await state.checkLock();
  if (backend.loggedIn && !state.locked) await state.afterLogin();
  // Lock again when the app comes back after more than 30 seconds away
  // (short trips, like the photo picker, don't lock).
  DateTime? away;
  AppLifecycleListener(
    onHide: () {
      away = DateTime.now();
      state.inBackground = true;
    },
    onShow: () {
      state.inBackground = false;
      final a = away;
      away = null;
      if (a != null && DateTime.now().difference(a) > const Duration(seconds: 30)) state.checkLock();
    },
  );
  // "오류 내용 보기": keep error text on this phone (only while switched on).
  final shown = FlutterError.onError;
  FlutterError.onError = (d) {
    ErrorLog.add(d.exception, d.stack);
    shown?.call(d);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    ErrorLog.add(e, st);
    return false;
  };
  AppState.remindAt = (id, at, name) {
    final l = lookupL(Locale((state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode) == 'ko' ? 'ko' : 'en'));
    return Push.remind(id, at, l.birthdayAlertTitle(name), l.birthdayAlertBody, l.remindChannel);
  };
  runApp(BurumyApp(state: state));
  unawaited(checkDesktopUpdate());
}

class BurumyApp extends StatelessWidget {
  const BurumyApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: Builder(
        builder: (context) {
          final s = AppScope.of(context);
          ErrorLog.keep = s.on('show_errors');
          LiveKitMedia.lowData = s.on('low_data_calls');
          final system = MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
          // Settings > Appearance: night mode follows the phone, or is
          // always on / off.
          final b = switch (s.pref('night', 'system')) {
            'dark' => Brightness.dark,
            'light' => Brightness.light,
            _ => system,
          };
          final scale = double.tryParse(s.pref('text_size', '')) ?? 1.0;
          final calm = s.calm;
          Glass.level = s.glassOn ? s.pref('glass', 'normal') : 'solid';
          final p = Palette.of(s.family, b);
          return CupertinoApp(
            debugShowCheckedModeBanner: false,
            onGenerateTitle: (c) => L.of(c).appName,
            locale: s.locale,
            supportedLocales: L.supportedLocales,
            localizationsDelegates: const [L.delegate, GlobalCupertinoLocalizations.delegate, GlobalWidgetsLocalizations.delegate],
            theme: CupertinoThemeData(
              brightness: b,
              primaryColor: p.accent,
              scaffoldBackgroundColor: p.background,
              textTheme: CupertinoTextThemeData(
                primaryColor: p.accent,
                textStyle: Tokens.body.style.copyWith(color: p.label),
              ),
            ),
            builder: (c, child) {
              var mq = MediaQuery.of(c);
              // Web: Flutter does not report the iPhone's status bar and
              // home indicator, so the page asks the browser itself.
              final (top, bottom) = Phone.webSafeInsets();
              if (mq.viewInsets.bottom == 0 && (top > mq.padding.top || bottom > mq.padding.bottom)) {
                final pad = mq.padding.copyWith(top: top > mq.padding.top ? top : null, bottom: bottom > mq.padding.bottom ? bottom : null);
                mq = mq.copyWith(padding: pad, viewPadding: pad);
              }
              return MediaQuery(
                data: mq.copyWith(
                  platformBrightness: b,
                  textScaler: scale == 1.0 ? mq.textScaler : TextScaler.linear(scale),
                  disableAnimations: calm || mq.disableAnimations,
                ),
                child: PanicListener(
                  onPanic: s.panicLock,
                  child: ScrollEdgeListener(child: child!),
                ),
              );
            },
            home: !s.loggedIn ? const AuthPage() : (s.locked ? const LockPage() : const _Home()),
          );
        },
      ),
    );
  }
}

/// One pane on phones, two on wide windows (the PC app).
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => isWide(context) ? const WideHome() : const HomeTabs();
}
