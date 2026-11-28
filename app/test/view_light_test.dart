// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Batches #10 보기·파일 and #11 영상 가볍게 (2026-11-27): document viewer
// and tabs (473), download line / pause / first (322), light copies and
// their marks (479 · 480 · 114), gallery auto-save rules (352).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/downloads.dart';
import 'package:burumy/core/media_tags.dart';
import 'package:burumy/core/open_docs.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/view_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/file_viewer.dart';
import 'package:burumy/ui/light_video.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  Downloads.instance.reset();
  OpenDocs.instance.clear();
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  // A tiny "PDF" is enough: the tests open the text and Word files.
  addViewSample(b, true, pdf: utf8.encode('%PDF-1.4'), clip: List.filled(3000, 7), light: List.filled(1000, 7));
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  return (s, b);
}

Msg file(String id, String name, {int? size}) => Msg(id: id, sender: '@a:test', body: name, time: DateTime(2026), mine: false, kind: 'file', size: size);

void main() {
  test('file kinds: what Burumy draws itself and what goes to another app', () {
    expect(fileKindOf('회비 정리.PDF'), FileKind.pdf);
    expect(fileKindOf('list.txt'), FileKind.text);
    expect(fileKindOf('a.csv'), FileKind.text);
    expect(fileKindOf('보고서.hwp'), FileKind.word);
    expect(fileKindOf('fees.xlsx'), FileKind.sheet);
    expect(fileKindOf('noext'), FileKind.other);
    expect(opensInApp(FileKind.pdf) && opensInApp(FileKind.text) && opensInApp(FileKind.image), isTrue);
    expect(opensInApp(FileKind.word), isFalse);
    expect(mimeOfName('x.docx'), contains('wordprocessingml'));
  });

  test('open files: newest first, at most 5, the same file moves to the front', () {
    final d = OpenDocs.instance..clear();
    for (var i = 0; i < 7; i++) {
      d.add(OpenDoc(roomId: '!r', msg: file('f$i', 'f$i.pdf'), bytes: Uint8List(1), chat: ''));
    }
    expect(d.docs.length, OpenDocs.max);
    expect(d.docs.first.id, 'f6');
    d.add(OpenDoc(roomId: '!r', msg: file('f3', 'f3.pdf'), bytes: Uint8List(1), chat: ''));
    expect(d.docs.first.id, 'f3');
    expect(d.docs.length, OpenDocs.max);
    d.clear();
    expect(d.docs, isEmpty);
  });

  test('light copy marks: pair on the original, lightOf + height on the copy', () {
    final o = const MediaTags(pair: 'k1', spoiler: true).apply('a.mp4');
    final l = const MediaTags(lightOf: 'k1', lightHeight: 480).apply('a.mp4');
    expect(MediaTags.of(o).pair, 'k1');
    expect(MediaTags.of(o).spoiler, isTrue);
    expect(MediaTags.plain(o), 'a.mp4');
    expect(MediaTags.of(l).lightOf, 'k1');
    expect(MediaTags.of(l).lightHeight, 480);
    final orig = Msg(id: 'o', sender: '@a:test', body: o, time: DateTime(2026), mine: false, kind: 'video');
    final copy = Msg(id: 'l', sender: '@a:test', body: l, time: DateTime(2026), mine: false, kind: 'video');
    expect(LightIndex.isLight(copy), isTrue);
    expect(LightIndex.isLight(orig), isFalse);
    LightIndex.note([orig, copy]);
    expect(LightIndex.of(orig)?.id, 'l');
  });

  test('light copy defaults (card A) and size estimates', () {
    expect(wantsLight(channel: true, members: 3, length: const Duration(seconds: 45)), isTrue);
    expect(wantsLight(channel: false, members: 120, length: const Duration(seconds: 45)), isTrue);
    expect(wantsLight(channel: false, members: 20, length: const Duration(minutes: 5)), isFalse, reason: 'small group');
    expect(wantsLight(channel: true, members: 3, length: const Duration(seconds: 10)), isFalse, reason: 'short clip');
    expect(estimateBytes(const Duration(seconds: 80), 480), lessThan(estimateBytes(const Duration(seconds: 80), 720)));
    final clip = File('assets/demo/clip.mp4').readAsBytesSync();
    expect(mp4VideoSize(clip), const Size(480, 270));
  });

  test('gallery auto-save: off by default, per chat type, size limit, never view-once', () async {
    final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    await s.refresh();
    final room = s.chats.firstWhere((c) => c.isDirect).roomId;
    final photo = Msg(id: 'p', sender: '@a:test', body: 'p.jpg', time: DateTime(2026), mine: false, kind: 'image');
    expect(s.autoSaves(room, photo), isFalse);
    await s.setAutoSave('dm', 'photo', true);
    expect(s.autoSaves(room, photo), isTrue);
    final big = Msg(id: 'v', sender: '@a:test', body: 'v.mp4', time: DateTime(2026), mine: false, kind: 'video', size: 30 << 20);
    await s.setAutoSave('dm', 'video', true);
    expect(s.autoSaves(room, big), isFalse, reason: '25 MB by default');
    await s.setAutoSaveMaxMb(50);
    expect(s.autoSaves(room, big), isTrue);
    final once = Msg(id: 'o', sender: '@a:test', body: 'p.jpg', time: DateTime(2026), mine: false, kind: 'image', viewOnce: true);
    expect(s.autoSaves(room, once), isFalse);
  });

  testWidgets('downloads wait in line, pause, resume and go first', (t) async {
    final (s, b) = await start(t);
    Downloads.maxRunning = 1;
    b.holdDownloads = Completer<void>();
    final d = Downloads.instance;
    final f1 = d.get(s, '!book-club', file('bk-txt', 'a.txt'));
    final f2 = d.get(s, '!book-club', file('bk-docx', 'b.docx'));
    await t.pump();
    expect(d.find('bk-txt')!.state, DownloadState.running);
    expect(d.find('bk-docx')!.state, DownloadState.waiting);
    expect(d.activeCount, 2);
    await d.first(s, 'bk-docx');
    expect(d.find('bk-docx')!.state, DownloadState.running, reason: '먼저 받기 takes the only slot');
    expect(d.find('bk-txt')!.state, DownloadState.waiting);
    await d.pause(s, 'bk-docx');
    expect(d.find('bk-docx')!.state, DownloadState.paused);
    expect(d.find('bk-txt')!.state, DownloadState.running, reason: 'the next one starts');
    d.resume(s, 'bk-docx');
    expect(d.find('bk-docx')!.state, DownloadState.waiting);
    b.holdDownloads!.complete();
    expect(await f1, isNotEmpty);
    expect(await f2, isNotEmpty);
    expect(d.activeCount, 0);
    await t.pumpAndSettle();
  });

  testWidgets('a text file opens in Burumy, tucks away into the bar, reopens', (t) async {
    await start(t);
    await t.tap(find.text('책 읽는 저녁').first);
    await t.pumpAndSettle();
    expect(find.byType(FileBubble), findsNWidgets(4));
    expect(find.text('TXT'), findsOneWidget);
    await t.tap(find.byKey(const Key('file-bubble-bk-txt')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-text')), findsOneWidget);
    expect(find.textContaining('작별하지 않는다'), findsOneWidget);
    await t.tap(find.byKey(const Key('doc-tuck')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-tabs-bar')), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('doc-tabs-label'))).data, '읽을 책 목록.txt');
    await t.tap(find.byKey(const Key('doc-tabs-bar')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-text')), findsOneWidget);
    await t.tap(find.byKey(const Key('doc-tuck')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('doc-tabs-close')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-tabs-bar')), findsNothing);
  });

  testWidgets('a Word file shows the other-app card with a warning; no tab', (t) async {
    await start(t);
    await t.tap(find.text('책 읽는 저녁').first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('file-bubble-bk-docx')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('doc-not-in-app')), findsOneWidget);
    await t.tap(find.byKey(const Key('doc-open-other')));
    await t.pumpAndSettle();
    expect(find.textContaining('암호화 보호 밖'), findsOneWidget);
    await t.tap(find.text('취소'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('doc-tuck')));
    await t.pumpAndSettle();
    expect(OpenDocs.instance.docs, isEmpty);
    expect(find.byKey(const Key('doc-tabs-bar')), findsNothing);
  });

  testWidgets('the light copy is not its own message', (t) async {
    await start(t);
    await t.tap(find.text('책 읽는 저녁').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('video-bubble')), findsOneWidget, reason: 'the original only');
  });
}
