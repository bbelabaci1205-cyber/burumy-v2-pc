// 4-app board: ZIP 미리보기 (look inside without unpacking).
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:burumy/core/zip_peek.dart';
import 'dart:async';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/open_docs.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/file_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Uint8List zipOf(Map<String, List<int>> files, {String? password}) {
  final a = Archive();
  for (final e in files.entries) {
    a.add(ArchiveFile.bytes(e.key, e.value));
  }
  return Uint8List.fromList(ZipEncoder(password: password).encodeBytes(a));
}

void main() {
  test('lists files sorted, skips folders and macOS extras, reads one in memory', () {
    final z = zipOf({
      '사진/바다.jpg': List.filled(3000, 7),
      '회비.txt': utf8.encode('회비 3만 원'),
      '__MACOSX/._회비.txt': [1],
      '사진/.DS_Store': [1],
    });
    final r = ZipPeek.list('모임.zip', z);
    expect(r.problem, isNull);
    expect(r.entries.map((e) => e.path), ['사진/바다.jpg', '회비.txt']);
    expect(r.entries.first.name, '바다.jpg');
    expect(r.entries.first.folder, '사진');
    expect(r.entries.first.size, 3000);
    expect(utf8.decode(ZipPeek.read('모임.zip', z, r.entries.last)!), '회비 3만 원');
  });

  test('a password zip says so; broken bytes say broken', () {
    final z = zipOf({'secret.txt': utf8.encode('x')}, password: 'pw');
    final r = ZipPeek.list('a.zip', z);
    final ok = r.problem == ZipProblem.password || (r.problem == null && ZipPeek.read('a.zip', z, r.entries.single) == null);
    expect(ok, isTrue, reason: 'either the list or the read refuses: ${r.problem}');
    expect(ZipPeek.list('b.zip', Uint8List.fromList([1, 2, 3, 4])).problem, ZipProblem.broken);
  });

  test('bomb guard: a file claiming to grow hugely is not unpacked', () {
    const e = ZipEntry(path: 'big.bin', size: 900 * 1024 * 1024, packed: 1024);
    expect(ZipPeek.read('x.zip', Uint8List(0), e), isNull);
    const e2 = ZipEntry(path: 'b.bin', size: 40 * 1024 * 1024, packed: 10 * 1024);
    expect(ZipPeek.read('x.zip', Uint8List(0), e2), isNull, reason: '4000× growth');
  });

  test('tar.gz lists the files; a plain .gz is the one file inside', () {
    final tar = TarEncoder().encodeBytes(Archive()..add(ArchiveFile.bytes('a/b.txt', utf8.encode('hi'))));
    final tgz = Uint8List.fromList(GZipEncoder().encodeBytes(tar));
    expect(ZipPeek.list('x.tar.gz', tgz).entries.single.path, 'a/b.txt');
    final gz = Uint8List.fromList(GZipEncoder().encodeBytes(utf8.encode('log line')));
    final r = ZipPeek.list('server.log.gz', gz);
    expect(r.entries.single.name, 'server.log');
    expect(utf8.decode(ZipPeek.read('server.log.gz', gz, r.entries.single)!), 'log line');
    expect(ZipPeek.canPeek('x.rar'), isFalse);
  });

  testWidgets('a zip in a chat: folders, sizes, tap a text file to read it', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final z = zipOf({'회비.txt': utf8.encode('회비 3만 원'), '사진/바다.jpg': List.filled(2048, 1)});
    final doc = OpenDoc(
      roomId: '!r',
      msg: Msg(id: 'z1', sender: '@jun:test', body: '모임 자료.zip', time: DateTime.now(), mine: false, kind: 'file', size: z.length),
      bytes: z,
      chat: '동창',
    );
    final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
    unawaited(nav.push(CupertinoPageRoute<void>(builder: (_) => FileViewerPage(doc: doc))));
    await t.pumpAndSettle();
    expect(find.text('파일 2개 · 풀면 2.0 KB'), findsOneWidget);
    expect(find.text('사진'), findsOneWidget, reason: 'folder header');
    await t.tap(find.byKey(const Key('zip-회비.txt')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-text')), findsOneWidget);
    expect(find.textContaining('회비 3만 원'), findsOneWidget);
    s.stopLive();
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  });
}
