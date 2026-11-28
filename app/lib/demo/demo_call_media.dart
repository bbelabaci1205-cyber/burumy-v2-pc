// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo (web preview): calls have no server, so this stand-in
// "connects" without sending anything and the other side never joins.
// The call rings, then ends as 응답 없음, which shows 음성 남기기 /
// 영상 남기기 / 다시 걸기. Real builds use LiveKitMedia.
import 'package:flutter/widgets.dart';

import '../core/backend.dart';
import '../core/call_media.dart';

class DemoCallMedia extends CallMedia {
  bool _in = false;

  @override
  Future<void> join(CallTicket t) async => _in = true;
  @override
  bool get connected => _in;
  @override
  bool get otherHere => false;
  @override
  bool get otherVideo => false;
  @override
  bool get otherLeft => false;
  @override
  Future<void> setMic(bool on) async {}
  @override
  Future<void> setCamera(bool on) async {}
  @override
  Future<void> setSpeaker(bool on) async {}
  @override
  Future<void> flipCamera() async {}
  @override
  Widget otherView() => const ColoredBox(color: Color(0xFF1C1C1E));
  @override
  Widget myView() => const ColoredBox(color: Color(0xFF3A3A3C));
  @override
  Future<void> leave() async => _in = false;
}
