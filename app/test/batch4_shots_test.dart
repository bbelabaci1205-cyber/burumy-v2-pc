// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tips batch 4: iPhone-size (393x852) screenshots of the pins
// bar + list, pin sheet, message link menu, picking words, channel share
// sheet, 1:1 read time, 저장 tab and the invite-blocked sheet.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  final home = Platform.environment['HOME'];
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf', 'assets/fonts/Pretendard-Bold.otf']);
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    return (b, s);
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/$name.png'));
  }

  Future<void> open(WidgetTester t, AppState s, String chat) async {
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text(chat));
    await t.pumpAndSettle();
  }

  Future<String> team(FakeBackend b) async {
    final g = await b.createGroup('여행 모임', ['@mina:test', '@leo:test']);
    await b.sendText(g, '토요일 10시 역 앞에서 만나요');
    await b.sendText(g, '준비물: 물, 모자, 선크림');
    await b.sendText(g, '저는 조금 늦을 수도 있어요');
    return g;
  }

  testWidgets('shots: pins (sheet, bar, list)', (t) async {
    final (b, s) = await app(t);
    await team(b);
    await open(t, s, '여행 모임');
    await t.longPress(find.text('토요일 10시 역 앞에서 만나요').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    await shot(t, 'ko_60_pin_sheet_notify');
    await t.tap(find.byKey(const Key('pin-for-0')));
    await t.pumpAndSettle();
    await t.longPress(find.text('준비물: 물, 모자, 선크림').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('menu-pin')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pin-for-0')));
    await t.pumpAndSettle();
    await shot(t, 'ko_61_pin_bar_lines');
    await t.tap(find.byKey(const Key('pinned-list')));
    await t.pumpAndSettle();
    await shot(t, 'ko_62_pinned_list');
    s.stopLive();
  });

  testWidgets('shots: copy link menu + picking words', (t) async {
    final (b, s) = await app(t);
    await team(b);
    await open(t, s, '여행 모임');
    await t.longPress(find.text('준비물: 물, 모자, 선크림').last);
    await t.pumpAndSettle();
    await shot(t, 'ko_63_menu_copy_link');
    await t.longPress(find.descendant(of: find.byKey(const Key('menu-select-text')), matching: find.text('준비물: 물, 모자, 선크림')));
    await t.pumpAndSettle();
    await shot(t, 'ko_64_pick_words');
    s.stopLive();
  });

  testWidgets('shots: channel share arrow + sheet', (t) async {
    final (b, s) = await app(t);
    final ch = await b.createGroup('부루미 소식', const [], channel: true);
    await b.sendText(ch, '새 기능: 고정 메시지를 위 띠에서 하나씩 넘겨 볼 수 있어요');
    for (final n in ['mina', 'leo', 'sora', 'jun', 'ara']) {
      await b.createDirectChat('@$n:test');
    }
    await b.createGroup('여행 모임', ['@mina:test']);
    await open(t, s, '부루미 소식');
    await shot(t, 'ko_65_channel_share_arrow');
    await t.tap(find.byKey(Key('share-${b.rooms[ch]!.last.id}')));
    await t.pumpAndSettle();
    await t.tap(find.text('@mina:test').first);
    await t.tap(find.text('여행 모임').first);
    await t.pumpAndSettle();
    await shot(t, 'ko_66_share_sheet');
    s.stopLive();
  });

  testWidgets('shots: 1:1 read time in the menu', (t) async {
    final (b, s) = await app(t);
    final room = await b.createDirectChat('@mina:test');
    await b.sendText(room, '도착하면 연락해 줘');
    b.readAt = b.now.add(const Duration(minutes: 1));
    b.readWhen = b.now.add(const Duration(minutes: 8));
    b.now = b.now.add(const Duration(hours: 1));
    await open(t, s, '@mina:test');
    await t.longPress(find.text('도착하면 연락해 줘').last);
    await t.pumpAndSettle();
    await shot(t, 'ko_67_read_time');
    s.stopLive();
  });

  testWidgets('shots: invite-blocked sheet', (t) async {
    final (b, s) = await app(t);
    final g = await team(b);
    b.contactsOnly.addAll(['@sora:test', '@jun:test']);
    await b.inviteUsers(g, ['@sora:test', '@jun:test']);
    await open(t, s, '여행 모임');
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    final list = find.byType(Scrollable).last;
    await t.scrollUntilVisible(find.byKey(const Key('info-invites-blocked')), 200, scrollable: list);
    await Scrollable.ensureVisible(t.element(find.byKey(const Key('info-invites-blocked'))), alignment: 0.5);
    await t.pumpAndSettle();
    await shot(t, 'ko_68_invites_blocked_row');
    await t.tap(find.byKey(const Key('info-invites-blocked')));
    await t.pumpAndSettle();
    await shot(t, 'ko_69_invites_blocked_sheet');
    s.stopLive();
  });
}
