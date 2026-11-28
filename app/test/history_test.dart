// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 새 멤버에게 지난 메시지 보내기: when adding people (switch) or later from
// the member menu; the new member sees "들어오기 전 대화" from their phone.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/phone.dart';
import 'package:burumy/ui/glass.dart' show GlassBack;
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test.dart' show reveal, revealInfo;
import 'fake_backend.dart';

void main() {
  Future<(FakeBackend, AppState, String)> openInfo(WidgetTester t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('동창 모임', ['@mina:test']);
    await fake.sendText(team, '장소는 강남역 3번 출구');
    await fake.createDirectChat('@eunji:test');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('동창 모임'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    return (fake, state, team);
  }

  testWidgets('add with 최근 메시지 같이 보내기, and later from the member menu (ko)', (t) async {
    final (fake, _, team) = await openInfo(t);
    await reveal(t, find.byKey(const Key('info-add-member')));
    await t.tap(find.byKey(const Key('info-add-member')));
    await t.pumpAndSettle();
    expect(find.text('최근 메시지 50개 같이 보내기'), findsOneWidget);
    await t.tap(find.byKey(const Key('add-share-history')));
    await t.tap(find.byKey(const Key('add-@eunji:test')));
    await t.pump();
    await t.tap(find.byKey(const Key('add-members-ok')));
    await t.pumpAndSettle();
    expect(fake.historySent['$team|@eunji:test'], 1);

    await revealInfo(t, find.byKey(const Key('member-@mina:test')), 150);
    await t.tap(find.byKey(const Key('member-@mina:test')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('member-history')));
    await t.pumpAndSettle();
    expect(fake.historySent['$team|@mina:test'], 1);
    expect(find.text('mina님에게 지난 메시지 1개를 보냈어요'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('the new member sees 들어오기 전 대화 (ko)', (t) async {
    t.view.physicalSize = const Size(1179, 2556);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('동창 모임', ['@mina:test']);
    final t0 = DateTime(2026, 11, 20, 9);
    fake.earlier[team] = [
      Msg(id: 'e1', sender: '@mina:test', body: '장소는 강남역 3번 출구', time: t0, mine: false, kind: 'text'),
      Msg(id: 'e2', sender: '@jun:test', body: '', caption: '작년에 간 곳', time: t0, mine: false, kind: 'image'),
      Msg(id: 'e3', sender: '@jun:test', body: '회비 정리.pdf', time: t0, mine: false, kind: 'file'),
    ];
    fake.earlierFiles['$team|1'] = _png;
    fake.earlierFiles['$team|2'] = '%PDF'.codeUnits;
    final shared = <String>[];
    Phone.debugShare = (text, bytes) async {
      shared.add(String.fromCharCodes(bytes!));
      return 'shared';
    };
    addTearDown(() => Phone.debugShare = null);
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('동창 모임'));
    await t.pumpAndSettle();
    expect(find.text('들어오기 전 대화 3개 보기'), findsOneWidget);
    await t.tap(find.byKey(const Key('earlier-bar')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('earlier-page')), findsOneWidget);
    expect(find.text('장소는 강남역 3번 출구'), findsOneWidget);
    // The photo shows (small picture first) with its words; tap = full screen.
    expect(find.text('작년에 간 곳'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    await t.tap(find.byKey(const Key('earlier-media-1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('earlier-photo')), findsOneWidget);
    await t.tap(find.byType(GlassBack).first);
    await t.pumpAndSettle();
    // The file opens in the share sheet (save / open in another app).
    expect(find.text('회비 정리.pdf'), findsOneWidget);
    await t.tap(find.byKey(const Key('earlier-media-2')));
    await t.pumpAndSettle();
    expect(shared, ['%PDF']);
  });

  test('never sends timer or view-once messages (demo mirrors the engine)', () async {
    final fake = FakeBackend();
    await fake.login(id: 'me', password: 'x');
    final team = await fake.createGroup('t', ['@mina:test']);
    final t0 = DateTime(2026, 11, 20, 9);
    fake.rooms[team] = [
      Msg(id: 'a', sender: '@mina:test', body: '보여도 돼', time: t0, mine: false, kind: 'text'),
      Msg(id: 'b', sender: '@mina:test', body: '곧 사라져', time: t0, mine: false, kind: 'text', expiresAt: t0.add(const Duration(days: 1))),
      Msg(id: 'c', sender: '@mina:test', body: 'p.jpg', time: t0, mine: false, kind: 'image', viewOnce: true),
    ];
    expect(await fake.sendHistory(team, '@eunji:test'), 1);
  });
}

/// A 1×1 PNG.
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];
