// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo for 로그인·기기 안전: an iPad I know, and a Windows PC
// that just signed in (the 새 로그인 경고 card shows on top of the list).
import 'package:burumy/core/backend.dart';

import '../core/login_safety.dart';
import 'demo_backend.dart';

void addLoginSafetySample(FakeBackend b) {
  final now = b.now;
  b.otherDevices.addAll([
    DeviceRow(id: 'IPAD1', name: 'Burumy iPad', lastSeen: now.subtract(const Duration(days: 2)), thisDevice: false, verified: true),
    DeviceRow(id: 'WINPC7', name: 'Burumy Windows PC', lastSeen: now.subtract(const Duration(minutes: 2)), thisDevice: false, verified: false),
  ]);
  // The phone already knew itself and the iPad; the PC is new.
  b.prefs[LoginSafety.knownKey] = 'THIS,IPAD1';
  // 정다은 (photo sample chat) takes text only: my mic there is locked.
  b.prefs['voice_ok:!photos'] = '0';
}
