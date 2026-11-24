// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo: the real app screens with example chats and no server.
// Build with -t lib/demo_main.dart (web preview, demo APK). Nothing leaves
// the device. Opens on the example chats; after logging out, any ID and
// password sign in again.
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/app_state.dart';
import 'core/desktop_update.dart';
import 'demo/sample.dart';
import 'main.dart' show BurumyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ko = PlatformDispatcher.instance.locale.languageCode != 'en';
  final photo = (await rootBundle.load('assets/demo/photo.png')).buffer.asUint8List();
  final state = AppState(demoSample(ko, photo));
  await state.login('me', 'demo');
  runApp(BurumyApp(state: state));
  unawaited(checkDesktopUpdate());
}
