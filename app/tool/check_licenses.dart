// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Dart licence check (CLEANROOM.md rule 5): every package the app uses
// (pubspec.lock, after `flutter pub get`) must have a licence file that is
// Apache-2.0 / MIT / BSD / ISC / Zlib / MPL-2.0 style. GPL, AGPL and LGPL
// fail. Run from app/: `dart run tool/check_licenses.dart` (exit 1 = fix).
import 'dart:convert';
import 'dart:io';

/// Words that mark a licence family, checked in this order.
const _banned = <String, String>{
  'GNU AFFERO GENERAL PUBLIC LICENSE': 'AGPL',
  'GNU LESSER GENERAL PUBLIC LICENSE': 'LGPL',
  'GNU LIBRARY GENERAL PUBLIC LICENSE': 'LGPL',
  'GNU GENERAL PUBLIC LICENSE': 'GPL',
};
const _allowed = <String, String>{
  'Apache License': 'Apache-2.0',
  'Mozilla Public License': 'MPL-2.0',
  'Permission is hereby granted, free of charge': 'MIT',
  'Redistribution and use in source and binary forms': 'BSD',
  'Permission to use, copy, modify, and/or distribute': 'ISC',
  'Permission to use, copy, modify, and distribute': 'ISC',
  'This software is provided \'as-is\'': 'Zlib',
  'SIL OPEN FONT LICENSE': 'OFL-1.1',
};

void main() {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) {
    stderr.writeln('Run `flutter pub get` first.');
    exit(2);
  }
  final lock = File('pubspec.lock').readAsStringSync();
  final used = RegExp(r'^  ([a-z0-9_]+):', multiLine: true).allMatches(lock).map((m) => m[1]!).toSet();
  final pkgs = (jsonDecode(config.readAsStringSync())['packages'] as List).cast<Map<String, dynamic>>();
  final bad = <String>[], unknown = <String>[];
  var ok = 0;
  for (final p in pkgs) {
    final name = p['name'] as String;
    if (!used.contains(name)) continue;
    var root = Uri.parse(p['rootUri'] as String);
    if (!root.isAbsolute) root = config.uri.resolveUri(root);
    final dir = Directory.fromUri(root);
    final files = dir.existsSync()
        ? dir.listSync().whereType<File>().where((f) => RegExp(r'^(LICEN[CS]E|COPYING)', caseSensitive: false).hasMatch(f.uri.pathSegments.last)).toList()
        : <File>[];
    if (files.isEmpty) {
      // Flutter's own packages (flutter, flutter_test, ...) live in the SDK.
      if (dir.path.contains('/flutter/packages/') || dir.path.contains('/flutter/bin/cache/')) {
        ok++;
        continue;
      }
      unknown.add('$name (no licence file)');
      continue;
    }
    final text = files.map((f) => f.readAsStringSync()).join('\n');
    final upper = text.toUpperCase();
    final hit = _banned.entries.where((e) => upper.contains(e.key)).map((e) => e.value).toList();
    // Dual licences ("MIT or GPL") are fine when an allowed one is offered.
    final good = _allowed.entries.where((e) => upper.contains(e.key.toUpperCase())).map((e) => e.value).toSet();
    if (hit.isNotEmpty && good.isEmpty) {
      bad.add('$name: ${hit.first}');
    } else if (good.isEmpty) {
      unknown.add('$name (licence not recognised: ${files.first.path})');
    } else {
      ok++;
    }
  }
  stdout.writeln('Dart packages: $ok ok, ${bad.length} not allowed, ${unknown.length} to check by hand');
  for (final b in bad) {
    stdout.writeln('  NOT ALLOWED  $b');
  }
  for (final u in unknown) {
    stdout.writeln('  CHECK        $u');
  }
  exit(bad.isEmpty && unknown.isEmpty ? 0 : 1);
}
