// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Batch "영상 보기·내려받기" (2026-11-27): time links (84, 198), player
// speed helpers (272, 383), download list + cancel (109), auto-download
// rules (116), keep times (101).
import 'dart:async';
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/downloads.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/video_sample.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/downloads_ui.dart';
import 'package:burumy/ui/formatting.dart';
import 'package:burumy/ui/media_bubbles.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(AppState, FakeBackend)> start(WidgetTester t, {Future<void> Function(AppState s, FakeBackend b)? before}) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  Downloads.instance.reset();
  final b = demoSample(true, File('test/assets/sample_photo.png').readAsBytesSync());
  addVideoSample(b, true, List.filled(3000, 7));
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await before?.call(s, b);
  await s.refresh();
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  return (s, b);
}

Msg video(String id, {int? size}) => Msg(id: id, sender: '@a:test', body: 'v.mp4', time: DateTime(2026), mine: false, kind: 'video', size: size);

void main() {
  test('time links: m:ss and h:mm:ss, not clock-like digits inside words', () {
    final f = findTimecodes('명장면 1:05, 끝은 1:02:30 · 12:345 · 3:7');
    expect([for (final x in f) x.$3], [const Duration(minutes: 1, seconds: 5), const Duration(hours: 1, minutes: 2, seconds: 30)]);
  });

  test('speed: 0.2× – 2.5× in 0.1 steps, written short', () {
    expect(clampSpeed(0.05), 0.2);
    expect(clampSpeed(3), 2.5);
    expect(clampSpeed(1.26), 1.3);
    expect(speedText(1.0), '1×');
    expect(speedText(1.5), '1.5×');
    expect(clockText(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  testWidgets('caption and reply "0:12" open the video from there; size shows', (t) async {
    await start(t);
    await t.tap(find.text('송하린').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('video-size')), findsOneWidget);
    final links = find.byWidgetPredicate((w) => w is FormattedText && w.onTime != null);
    expect(links, findsNWidgets(2), reason: 'caption under the video + the reply to it');
    t.widget<FormattedText>(links.first).onTime!(const Duration(seconds: 12));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(t.widget<VideoPlayerPage>(find.byType(VideoPlayerPage)).startAt, const Duration(seconds: 12));
    await t.tap(find.byKey(const Key('video-close')));
    await t.pump(const Duration(seconds: 1));
  });

  testWidgets('auto-download: by network, kind, chat type and size limit', (t) async {
    final (s, _) = await start(t);
    const room = '!video';
    s.network = 'wifi';
    expect(s.autoGet(room, video('x', size: 40 << 20)), isTrue, reason: 'Wi-Fi: videos up to 50 MB');
    expect(s.autoGet(room, video('x', size: 60 << 20)), isFalse);
    expect(s.autoGet(room, video('x')), isFalse, reason: 'unknown size waits for a tap');
    s.network = 'cellular';
    expect(s.autoGet(room, video('x', size: 40 << 20)), isFalse, reason: 'mobile data: 10 MB');
    await s.setAutoMaxMb('cell', 'video', 50);
    expect(s.autoGet(room, video('x', size: 40 << 20)), isTrue);
    await s.setAutoChats('cell', 'video', {'group'});
    expect(s.autoGet(room, video('x', size: 1)), isFalse, reason: '1:1 switched off');
    expect(s.autoRulesChanged, isTrue);
    await s.resetAutoRules();
    expect(s.autoRulesChanged, isFalse);
    await s.setOn('auto_dl_cell', false);
    expect(s.autoGet(room, video('x', size: 1)), isFalse);
  });

  testWidgets('download list: running with X, cancel, then done rows; settings pages', (t) async {
    final (s, b) = await start(t, before: (s, b) async => s.network = 'cellular');
    b.holdDownloads = Completer<void>();
    final m = video('vd1', size: 3000);
    final f = Downloads.instance.get(s, '!video', m);
    expect(Downloads.instance.isRunning('vd1'), isTrue);
    await t.tap(find.text('설정').last);
    await t.pumpAndSettle();
    final row = find.byKey(const Key('data-row'));
    await t.scrollUntilVisible(row, 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(row);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('storage-row')), findsOneWidget);
    await Scrollable.ensureVisible(t.element(find.byKey(const Key('dl-list'))), alignment: 0.5);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('dl-list')));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('dl-cancel-vd1')), findsOneWidget);
    await t.tap(find.byKey(const Key('dl-cancel-vd1')));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    b.holdDownloads!.complete();
    expect(await f, isEmpty, reason: 'stopped: nothing comes back');
    await t.pumpAndSettle();
    expect(find.text('취소했어요 · 2.9 KB'), findsOneWidget);
    await Downloads.instance.get(s, '!video', m);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dl-cancel-vd1')), findsNothing);
    expect(b.kept, contains('vd1'), reason: 'kept in the encrypted store');
    await t.tap(find.byKey(const Key('dl-clear')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('dl-empty')), findsOneWidget);
    // Auto-download pages.
    Navigator.of(t.element(find.byType(DownloadListPage))).pop();
    await t.pumpAndSettle();
    // The Data page grew (갤러리 자동 저장, 2026-11-27): scroll to the row.
    await t.scrollUntilVisible(find.byKey(const Key('auto-dl-cell')), 150, scrollable: find.byType(Scrollable).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('auto-dl-cell')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('auto-dl-cell-video')));
    await t.pumpAndSettle();
    expect(find.text('10MB까지'), findsOneWidget);
    await t.tap(find.byKey(const Key('auto-dl-chat-channel')));
    await t.pumpAndSettle();
    expect(s.autoChats('cell', 'video'), {'dm', 'group', 'channel'});
  });

  testWidgets('keep times: copies older than the chat type\'s time go', (t) async {
    final (s, b) = await start(t);
    await Downloads.instance.get(s, '!video', video('vd1', size: 3000));
    expect(b.kept, contains('vd1'));
    expect(s.keepDays('dm'), 0, reason: '1:1 kept by default (Telegram)');
    expect(await Downloads.instance.applyKeep(s, now: DateTime.now().add(const Duration(days: 400))), 0);
    await s.setKeepDays('dm', 7);
    expect(b.keepFor, const Duration(days: 30), reason: 'store cleans after the longest time');
    expect(await Downloads.instance.applyKeep(s, now: DateTime.now().add(const Duration(days: 3))), 0);
    expect(await Downloads.instance.applyKeep(s, now: DateTime.now().add(const Duration(days: 8))), 1);
    expect(b.kept, isNot(contains('vd1')));
    expect(keepName(lookupL(const Locale('ko')), 30), '한 달');
  });
}
