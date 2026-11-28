// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PC app (Windows) updates itself: a little after start it reads a small
// file (update.json: app, build number, installer name, SHA-256) and its
// signature (update.json.sig). Only when Eric's key signed that exact file
// (core/update_signature.dart, keys in core/update_keys.dart) and the build
// is newer does it download the installer, check its fingerprint, run it
// quietly and close; the installer opens the app again. So whoever controls
// the download place still can't push a fake installer.
// The address comes from the build (UPDATE_FEED_URL); empty = no updates
// (phones, the web, builds made by hand). No pinned key = no updates.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'update_keys.dart';
import 'update_signature.dart';

const updateFeed = String.fromEnvironment('UPDATE_FEED_URL');
const buildNumber = int.fromEnvironment('BUILD_NUMBER');

/// Which app a feed is for, so a signed file for another app can't be reused.
const updateApp = 'burumy-v2-windows';

/// Where the signature of [feed] lives: same address + ".sig".
Uri signatureUri(Uri feed) => feed.replace(path: '${feed.path}.sig');

/// [newerBuild], but only if [signature] is a valid signature of exactly
/// [feedBytes] by one of [keys].
({int build, Uri file, String sha256})? verifiedNewerBuild(
  List<int> feedBytes,
  String signature,
  Uri feed,
  int current, {
  List<String> keys = updatePublicKeys,
}) {
  if (keys.isEmpty || !verifySshSignature(message: feedBytes, armored: signature, allowedKeys: keys)) return null;
  try {
    return newerBuild(utf8.decode(feedBytes), feed, current);
  } catch (_) {
    return null;
  }
}

/// What the feed says, if it is newer than this build and well formed.
({int build, Uri file, String sha256})? newerBuild(String feedBody, Uri feed, int current) {
  try {
    final j = jsonDecode(feedBody) as Map<String, dynamic>;
    if (j['app'] != updateApp) return null;
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
  if (kIsWeb || !Platform.isWindows || updateFeed.isEmpty || buildNumber == 0 || updatePublicKeys.isEmpty) return;
  await Future<void>.delayed(wait);
  try {
    final feed = Uri.parse(updateFeed);
    final r = await http.get(feed).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) return;
    final s = await http.get(signatureUri(feed)).timeout(const Duration(seconds: 20));
    if (s.statusCode != 200) return;
    final next = verifiedNewerBuild(r.bodyBytes, s.body, feed, buildNumber);
    if (next == null) return;
    final f = await http.get(next.file).timeout(const Duration(minutes: 10));
    if (f.statusCode != 200 || sha256.convert(f.bodyBytes).toString() != next.sha256) return;
    final dir = await Directory.systemTemp.createTemp('burumy-v2-update-');
    final exe = File('${dir.path}${Platform.pathSeparator}burumy-v2-update-${next.build}.exe');
    await exe.writeAsBytes(f.bodyBytes, flush: true);
    await Process.start(exe.path, ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'], mode: ProcessStartMode.detached);
    exit(0);
  } catch (_) {
    // No network or a bad file: try again next start.
  }
}
