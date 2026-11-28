// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Runs before every test file: sounds go nowhere.
import 'dart:async';

import 'package:burumy/core/ai_age.dart';
import 'package:burumy/core/sounds.dart';
import 'package:burumy/core/storage_usage.dart';
import 'package:burumy/core/translate.dart';

final played = <String>[];

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Sounds.player = (asset, {loop = false}) async => played.add(asset);
  // Real file reads never finish inside widget tests' fake time.
  StorageUsage.read = () async => null;
  // Flutter tests run as "Android": keep the Android-only age question and
  // Google credit out of every test unless a test turns them on.
  AiAge.debugAndroid = false;
  TrCredit.debugAndroid = false;
  await testMain();
}
