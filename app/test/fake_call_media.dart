// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Call sound/picture stand-in for screen tests.
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/call_media.dart';
import 'package:flutter/widgets.dart';

class FakeCallMedia extends CallMedia {
  static FakeCallMedia? last;
  FakeCallMedia() {
    last = this;
  }

  CallTicket? ticket;
  bool mic = true, camera = false, speaker = false, left = false, _here = false, _was = false;
  int flips = 0;

  /// The other person joins / leaves.
  void otherJoins() {
    _here = _was = true;
    notifyListeners();
  }

  void otherLeaves() {
    _here = false;
    notifyListeners();
  }

  @override
  Future<void> join(CallTicket t) async {
    ticket = t;
    camera = t.video;
  }

  @override
  bool get connected => ticket != null && !left;
  @override
  bool get otherHere => _here;
  @override
  bool get otherVideo => _here && ticket?.video == true;
  @override
  bool get otherLeft => _was && !_here;
  @override
  Future<void> setMic(bool on) async => mic = on;
  @override
  Future<void> setCamera(bool on) async => camera = on;
  @override
  Future<void> setSpeaker(bool on) async => speaker = on;
  @override
  Future<void> flipCamera() async => flips++;
  @override
  Widget otherView() => const ColoredBox(key: Key('fake-other-video'), color: Color(0xFF3A6EA5));
  @override
  Widget myView() => const ColoredBox(key: Key('fake-my-video'), color: Color(0xFF8E8E93));
  @override
  Future<void> leave() async => left = true;
}
