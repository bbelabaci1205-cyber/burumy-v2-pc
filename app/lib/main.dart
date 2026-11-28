// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Burumy v2 app entry. iOS-standard look first (rulebook ch. 2), Korean and
// English built in (ch. 6), green and blue brand families side by side (ch. 4).
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory;
import 'dart:math' show Random, max;

import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:clock/clock.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'core/ai_age.dart';
import 'core/ai_local.dart';
import 'core/licenses.dart';
import 'core/desktop_update.dart';
import 'core/reminders.dart';
import 'core/accounts.dart';
import 'brand/brand.dart';
import 'core/app_state.dart';
import 'ui/gallery_save.dart' show autoSaveToGallery;
import 'core/downloads.dart';
import 'core/looks.dart' show brightEnough, hexColor;
import 'core/backend.dart';
import 'core/error_log.dart';
import 'core/call_media.dart' show LiveKitMedia;
import 'core/night.dart';
import 'core/phone.dart';
import 'core/push.dart';
import 'core/rust_backend.dart';
import 'core/safety.dart';
import 'design/tokens.dart';
import 'l10n/app_localizations.dart';
import 'src/rust/frb_generated.dart';
import 'ui/scroll_edge.dart';
import 'ui/glass.dart';
import 'ui/panic.dart';
import 'ui/theme_fade.dart';
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

/// One account's login (slot 0 keeps the old key names).
class KeychainStore implements SessionStore {
  KeychainStore([this.slot = 0]);
  final int slot;
  static const _s = FlutterSecureStorage();
  String get _k => slot == 0 ? 'burumy.session' : 'burumy.session.$slot';
  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String? json) => json == null ? _s.delete(key: _k) : _s.write(key: _k, value: json);
}

/// The list of accounts on this phone.
class KeychainBook implements AccountBookStore {
  static const _s = FlutterSecureStorage();
  static const _k = 'burumy.accounts';
  @override
  Future<String?> read() => _s.read(key: _k);
  @override
  Future<void> write(String json) => _s.write(key: _k, value: json);
}

String _storeKey(int slot) => slot == 0 ? 'burumy.store' : 'burumy.store.$slot';
Future<String> _dataDir(int slot) async => '${(await getApplicationSupportDirectory()).path}/${slot == 0 ? 'burumy' : 'burumy-$slot'}';

/// Opens one account's engine from its saved login (also used by a
/// background wake-up, which must never forget the login on a passing
/// error).
Future<RustBackend> openBackend({bool background = false, int slot = 0}) async {
  // The local store passphrase is made once and kept in the keychain.
  const keychain = FlutterSecureStorage();
  var pass = await keychain.read(key: _storeKey(slot));
  if (pass == null) {
    // 32 random bytes from the phone's secure random source (보안검수
    // 2026-11-28: the old time + hash code was guessable).
    final rnd = Random.secure();
    pass = base64UrlEncode(List<int>.generate(32, (_) => rnd.nextInt(256)));
    await keychain.write(key: _storeKey(slot), value: pass);
  }
  return RustBackend.open(
    server: _server,
    dataDir: await _dataDir(slot),
    storePassphrase: pass,
    store: KeychainStore(slot),
    lock: KeychainLock(),
    forgetBrokenSession: !background,
  );
}

/// Forgets one account on this phone: its login, its store key (so what
/// is left on disk can't be read) and, where possible, its files.
Future<void> eraseSlot(int slot) async {
  const keychain = FlutterSecureStorage();
  await keychain.delete(key: slot == 0 ? 'burumy.session' : 'burumy.session.$slot');
  await keychain.delete(key: _storeKey(slot));
  try {
    final d = Directory(await _dataDir(slot));
    if (await d.exists()) await d.delete(recursive: true);
  } catch (_) {}
}

/// Every account on the phone (background wake-ups).
Future<List<int>> _slots() async {
  final raw = await KeychainBook().read();
  if (raw == null) return [0];
  try {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final s = [for (final e in (j['accounts'] as List? ?? const [])) e['slot'] as int];
    return s.isEmpty ? [0] : s;
  } catch (_) {
    return [0];
  }
}

/// Push wake-up while the app is closed (its own background isolate).
@pragma('vm:entry-point')
Future<void> burumyPushInBackground(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  // Every account on the phone fetches and shows its new messages.
  for (final slot in await _slots()) {
    await handlePushInBackground(() => openBackend(background: true, slot: slot));
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Tokens.deviceFont = true;
  await RustLib.init();
  AppState.publishBubbles = HomeBubbles.publish;
  // 갤러리 자동 저장 (tip 352): off until I turn it on per chat type.
  Downloads.afterDownload = autoSaveToGallery;
  late final Accounts accounts;
  AppState makeState(Backend b) => AppState(b)..watchBattery(Phone.battery, net: Phone.network);
  accounts = Accounts(
    store: KeychainBook(),
    openSlot: (slot) => openBackend(slot: slot),
    eraseSlot: eraseSlot,
    makeState: makeState,
    onShown: (s) async {
      if (s.backend.loggedIn) await s.afterLogin();
    },
  );
  await accounts.load();
  AppState.startPush = (s) async {
    await Push.start(
      s.backend,
      onWake: () async {
        await accounts.state.wake();
        await accounts.wakeOthers(notify: accounts.state.inBackground);
      },
      background: burumyPushInBackground,
    );
    // The other accounts get their wake-ups on this phone too.
    for (final b in accounts.side.values) {
      if (b.loggedIn) unawaited(Push.register(b).catchError((_) {}));
    }
  };
  AppState.showNotices = (b) async {
    final lang = accounts.state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    await Push.showNew(b, lookupL(Locale(lang == 'ko' ? 'ko' : 'en')));
  };
  scheduleReminder = (r) {
    final l = lookupL(Locale((accounts.state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode) == 'ko' ? 'ko' : 'en'));
    return Push.remind(r.id, r.at, r.chat.isEmpty ? l.appName : r.chat, l.remindDue, l.remindChannel);
  };
  cancelReminder = (r) => Push.cancelRemind(r.id);
  final state = accounts.state;
  // 미접속 자동 삭제: the app wasn't opened for the chosen days. Every
  // account on this phone goes.
  if (!kIsWeb && state.backend.loggedIn && await Safety.idleExpired()) {
    try {
      await state.backend.eraseEverything();
    } catch (_) {}
    await accounts.eraseOthers();
    await Safety.touch();
  }
  await state.checkLock();
  if (state.backend.loggedIn && !state.locked) await state.afterLogin();
  // Lock again when the app comes back after the chosen time away
  // (Settings > 개인정보 및 보안 > 자동 잠금, v1 default 1 minute). Very short
  // trips, like the photo picker, never lock.
  DateTime? away;
  AppLifecycleListener(
    onHide: () {
      away = DateTime.now();
      accounts.state.inBackground = true;
    },
    onShow: () {
      accounts.state.inBackground = false;
      final a = away;
      away = null;
      final s = accounts.state;
      final after = Duration(seconds: max(5, int.tryParse(s.pref('lock_after', '60')) ?? 60));
      if (a != null && DateTime.now().difference(a) > after) s.checkLock();
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
  AppState.idleReminder = (at) {
    final l = lookupL(Locale((accounts.state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode) == 'ko' ? 'ko' : 'en'));
    return Push.remind(0x2f1d1e, at, l.idleReminderTitle, l.idleReminderBody, l.remindChannel);
  };
  AppState.remindAt = (id, at, name) {
    final l = lookupL(Locale((accounts.state.locale?.languageCode ?? PlatformDispatcher.instance.locale.languageCode) == 'ko' ? 'ko' : 'en'));
    return Push.remind(id, at, l.birthdayAlertTitle(name), l.birthdayAlertBody, l.remindChannel);
  };
  // Does this phone have its own AI? (AI 편집기 shows only then.)
  unawaited(LocalAi.status());
  // Android: Google's AI only after "만 18세 이상이에요" (core/ai_age.dart).
  LocalAi.blocked = () => !AiAge.allowed(accounts.state);
  registerExtraLicenses();
  runApp(AccountsHost(accounts: accounts));
  unawaited(checkDesktopUpdate());
}

/// Rebuilds the app with the account on screen (Telegram-style switch).
class AccountsHost extends StatelessWidget {
  const AccountsHost({super.key, required this.accounts});
  final Accounts accounts;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: accounts,
    builder: (_, _) => BurumyApp(key: ValueKey('account-${accounts.active}'), state: accounts.state),
  );
}

class BurumyApp extends StatelessWidget {
  const BurumyApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: NightTick(
        state: state,
        builder: (context) {
          final s = AppScope.of(context);
          ErrorLog.keep = s.on('show_errors');
          LiveKitMedia.lowData = s.on('low_data_calls');
          final system = MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light;
          // Settings > Appearance: night mode follows the phone, is
          // always on / off, or turns on between two times (tip 64).
          final b = Night.brightness(s, system, clock.now());
          final scale = double.tryParse(s.pref('text_size', '')) ?? 1.0;
          final calm = s.calm;
          Glass.level = s.glassOn ? s.pref('glass', 'normal') : 'solid';
          // 테마 만들기 (tip 173): the made theme's accent.
          Brand.custom = brightEnough(hexColor(s.pref('accent_custom', ''), Brand.custom));
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
              Phone.webPageColor(b == Brightness.dark);
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
                  child: ThemeFade(child: ScrollEdgeListener(child: child!)),
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

/// 야간 모드 by time: rebuilds the app when the minute changes so night
/// starts / ends on time (only while that mode is on).
class NightTick extends StatefulWidget {
  const NightTick({super.key, required this.state, required this.builder});
  final AppState state;
  final WidgetBuilder builder;
  @override
  State<NightTick> createState() => _NightTickState();
}

class _NightTickState extends State<NightTick> {
  Timer? _t;
  bool? _dark;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 30), (_) {
      final s = widget.state;
      if (Night.mode(s) != 'schedule') return;
      final d = Night.inWindow(Night.from(s), Night.to(s), clock.now());
      if (_dark != null && _dark != d) unawaited(ThemeFade.run(() async => setState(() {})));
      _dark = d;
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Builder(builder: widget.builder);
}

/// One pane on phones, two on wide windows (the PC app).
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => isWide(context) ? const WideHome() : const HomeTabs();
}
