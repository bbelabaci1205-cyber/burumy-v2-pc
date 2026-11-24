// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PC app (Windows) updates itself: a little after start it reads a small
// file (update.json: build number, installer name, SHA-256), and when a
// newer build is there it downloads the installer, checks its fingerprint,
// runs it quietly and closes; the installer opens the app again.
// The address comes from the build (UPDATE_FEED_URL); empty = no updates
// (phones, the web, builds made by hand).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

const updateFeed = String.fromEnvironment('UPDATE_FEED_URL');
const buildNumber = int.fromEnvironment('BUILD_NUMBER');

/// What the feed says, if it is newer than this build and well formed.
({int build, Uri file, String sha256})? newerBuild(String feedBody, Uri feed, int current) {
  try {
    final j = jsonDecode(feedBody) as Map<String, dynamic>;
    final build = j['build'] as int;
    final file = j['file'] as String;
    final sum = (j['sha256'] as String).toLowerCase();
    if (build <= current || file.contains('..') || !RegExp(r'^[0-9a-f]{64}$').hasMatch(sum)) return null;
    final uri = feed.resolve(file);
    // Only from the same place as the feed.
    if (uri.host != feed.host || uri.scheme != 'https') return null;
    return (build: build, file: uri, sha256: sum);
  } catch (_) {
    return null;
  }
}

Future<void> checkDesktopUpdate({Duration wait = const Duration(seconds: 20)}) async {
  if (kIsWeb || !Platform.isWindows || updateFeed.isEmpty || buildNumber == 0) return;
  await Future<void>.delayed(wait);
  try {
    final feed = Uri.parse(updateFeed);
    final r = await http.get(feed).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return;
    final next = newerBuild(r.body, feed, buildNumber);
    if (next == null) return;
    final f = await http.get(next.file).timeout(const Duration(minutes: 10));
    if (f.statusCode != 200 || sha256.convert(f.bodyBytes).toString() != next.sha256) return;
    final exe = File('${Directory.systemTemp.path}${Platform.pathSeparator}burumy-v2-update-${next.build}.exe');
    await exe.writeAsBytes(f.bodyBytes, flush: true);
    await Process.start(exe.path, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'], mode: ProcessStartMode.detached);
    exit(0);
  } catch (_) {
    // No network or a bad file: try again next start.
  }
}
