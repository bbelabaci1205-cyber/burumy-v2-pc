// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Picture of the home-screen bubble widget (same drawing as the phone
// widgets: colour + first letter only, never the content).
import 'dart:io';

import 'package:burumy/ui/bubbles.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final l = FontLoader('Pretendard')..addFont(Future.value(ByteData.sublistView(File('assets/fonts/Pretendard-SemiBold.otf').readAsBytesSync())));
    await l.load();
  });

  testWidgets('bubble widget preview', (t) async {
    t.view.physicalSize = const Size(393 * 2, 420 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    const spots = [(0.30, 0.32, 0.44), (0.70, 0.28, 0.34), (0.55, 0.66, 0.40), (0.22, 0.74, 0.26)];
    const people = [(Color(0xFFFF2D55), '민'), (Color(0xFF007AFF), '서'), (Color(0xFFFF9500), '가'), (Color(0xFF5856D6), '레')];
    Widget widgetBox(int n) => Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(26)),
      child: LayoutBuilder(
        builder: (c, box) => Stack(
          children: [
            for (var i = 0; i < n; i++)
              Positioned(
                left: box.maxWidth * spots[i].$1 - box.maxWidth * spots[i].$3 / 2,
                top: box.maxHeight * spots[i].$2 - box.maxWidth * spots[i].$3 / 2,
                child: SoapBubble(color: people[i].$1, size: box.maxWidth * spots[i].$3, letter: people[i].$2),
              ),
          ],
        ),
      ),
    );
    await t.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Pretendard'),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3A7BD5), Color(0xFF00D2A8)]),
            ),
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [widgetBox(4), widgetBox(1)]),
          ),
        ),
      ),
    );
    await expectLater(find.byType(Directionality).first, matchesGoldenFile('shots/bubble_widget_preview.png'));
  });
}
