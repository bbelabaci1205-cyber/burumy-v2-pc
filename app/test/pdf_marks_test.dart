// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// PDF 형광펜 (4-app board): marks are kept on this phone per file, one box
// per line; the list jumps to a page, removes with 5 s to undo, and sends
// the marked words to the chat.
import 'dart:async';
import 'dart:typed_data';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/open_docs.dart';
import 'package:burumy/core/pdf_marks.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/ios_route.dart';
import 'package:burumy/ui/pdf_marks_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

PdfMark mark(int page, String text, int at, {double top = 700}) =>
    PdfMark(page: page, rects: [(50, top, 300, top - 14)], text: text, at: DateTime.fromMicrosecondsSinceEpoch(at));

void main() {
  test('letters become one box per line', () {
    final chars = [
      for (var i = 0; i < 5; i++) (100.0 + i * 10, 700.0, 108.0 + i * 10, 688.0),
      (0.0, 0.0, 0.0, 0.0), // empty boxes (spaces) are skipped
      for (var i = 0; i < 3; i++) (60.0 + i * 10, 684.0, 68.0 + i * 10, 672.0),
    ];
    final lines = PdfMarks.lines(chars);
    expect(lines, hasLength(2));
    expect(lines[0], (100.0, 700.0, 148.0, 688.0));
    expect(lines[1], (60.0, 684.0, 88.0, 672.0));
  });

  testWidgets('kept per file, in page order; removed by id', (t) async {
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await PdfMarks.add(s, 'e1', [mark(3, '셋째', 3), mark(1, '아래', 2, top: 300), mark(1, '위', 1)]);
    await PdfMarks.add(s, 'e2', [mark(1, '다른 파일', 4)]);
    expect([for (final m in PdfMarks.of(s, 'e1')) m.text], ['위', '아래', '셋째']);
    expect(PdfMarks.of(s, 'e2'), hasLength(1));
    await PdfMarks.remove(s, 'e1', {'2'});
    expect([for (final m in PdfMarks.of(s, 'e1')) m.text], ['위', '셋째']);
  });

  testWidgets('list: tap goes to the page, remove waits 5 s, send quotes them', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    final room = await b.createGroup('스터디', ['@mina:test']);
    await s.refresh();
    final doc = OpenDoc(
      roomId: room,
      msg: Msg(id: 'pdf1', sender: '@mina:test', body: '회비 정리.pdf', time: DateTime(2026, 11, 27), mine: false, kind: 'file'),
      bytes: Uint8List(0),
      chat: '스터디',
    );
    await PdfMarks.add(s, 'pdf1', [mark(2, '회비는 매달 1만 원', 1), mark(4, '남은 돈은 연말 모임에', 2)]);
    int? went;
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(nav.push<int>(IosPageRoute(builder: (_) => PdfMarksPage(doc: doc))).then((v) => went = v));
    await t.pumpAndSettle();
    expect(find.text('회비는 매달 1만 원'), findsOneWidget);
    expect(find.text('2쪽'), findsOneWidget);
    // Remove one: gone from the list now, from the phone after 5 s.
    await t.tap(find.byKey(const Key('pdf-mark-del-1')));
    await t.pump();
    expect(find.text('회비는 매달 1만 원'), findsNothing);
    expect(PdfMarks.of(s, 'pdf1'), hasLength(2));
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(PdfMarks.of(s, 'pdf1'), hasLength(1));
    // Tap: back to the PDF on that page.
    await t.tap(find.text('남은 돈은 연말 모임에'));
    await t.pumpAndSettle();
    expect(went, 4);
    // Send: one message with the page and the words.
    unawaited(nav.push<int>(IosPageRoute(builder: (_) => PdfMarksPage(doc: doc))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pdf-marks-send')));
    await t.pumpAndSettle();
    final sent = b.rooms[room]!.last;
    final l = await L.delegate.load(const Locale('ko'));
    expect(sent.body, pdfMarksMessage(l, '회비 정리.pdf', PdfMarks.of(s, 'pdf1')));
    expect(sent.body, contains('4쪽 · “남은 돈은 연말 모임에”'));
    await t.pump(const Duration(seconds: 3));
  });
}
