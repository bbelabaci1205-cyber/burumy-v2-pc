// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 사칭 막기: look-alike rules (same cases as server/trust/src/names.rs),
// badges and labels on screen, the first-chat card, reports, the badge
// application, and refused IDs / names.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/trust.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/trust_sample.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<AppState> demo(WidgetTester t) async {
  final b = demoSample(true, File('assets/demo/photo.png').readAsBytesSync());
  addTrustSample(b, true, b.files['img']!);
  final s = AppState(b, locale: const Locale('ko'));
  await s.login('me', 'demo');
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  return s;
}

void main() {
  test('skeleton: same answers as the server', () {
    // server/trust/src/names.rs tests::SHARED
    const shared = {'Haneul_0fficial': 'haneulofflclal', 'rnina': 'mlna', '하늘 별': 'ㅎㅏㄴㅡㄹㅂㅕㄹ', 'ІU': 'lu', 'ｂｔｓ': 'bts', 'vvow': 'wow'};
    shared.forEach((a, want) => expect(skeleton(a), want, reason: a));
    expect(skeleton('하​늘별'), skeleton('하늘별'));
    // The Rust file really has the same list.
    final rust = File('../server/trust/src/names.rs').readAsStringSync();
    shared.forEach((a, want) => expect(rust.contains('("$a", "$want")'), isTrue, reason: a));
  });

  test('ID and name checks', () {
    const badges = [Badge(user: '@haneulbyeol:x', name: '하늘별')];
    const reserved = ['아이유', 'bts'];
    String id(String s, {String? who}) => checkName(s, who: who, reserved: reserved, badges: badges);
    expect(id('admin2'), 'reserved');
    expect(id('하늘별공식'), 'reserved');
    expect(id('haneu1byeol99'), 'lookalike');
    expect(id('하늘별'), 'lookalike');
    expect(id('하늘별', who: '@haneulbyeol:x'), '');
    expect(id('B.T.S'), 'reserved');
    expect(id('진짜아이유'), 'reserved');
    expect(id('김민지'), '');
    expect(checkName('민지 ✔', displayName: true), 'mark');
    expect(checkName('하늘별', badges: badges, displayName: true), '', reason: 'same display name is allowed, just marked');
    expect(checkName('부루미 운영자', displayName: true), 'reserved');
  });

  test('list: badge needs the checked name; look-alikes and labels', () {
    final l = TrustList.fromJson({
      'v': 3,
      'badges': [
        {'user': '@star:x', 'name': '하늘별'},
        {'user': 42},
      ],
      'flags': [
        {'user': '@bad:x', 'state': 'fake'},
        {'user': '@odd:x', 'state': 'boss'},
      ],
    });
    expect(l.badges.length, 1);
    expect(l.flags, {'@bad:x': 'fake'});
    expect(l.of('@star:x', '하늘 별').official, isTrue);
    expect(l.of('@star:x', '다른 이름').official, isFalse, reason: 'renamed: badge off');
    expect(l.of('@copy:x', '하늘별').looksLike?.user, '@star:x');
    expect(l.of('@haneulbyeol_0fficial:x', '팬').looksLike, isNull);
    expect(l.of('@bad:x', 'x').fake, isTrue);
    expect(needsFirstContactCard(isDirect: true, peer: '@a:x', friends: const {}, accepted: false, iWrote: false), isTrue);
    expect(needsFirstContactCard(isDirect: true, peer: '@a:x', friends: const {'@a:x'}, accepted: false, iWrote: false), isFalse);
    expect(needsFirstContactCard(isDirect: true, peer: '@a:x', friends: const {}, accepted: false, iWrote: true), isFalse);
  });

  testWidgets('chat list: badge on the channel, 가짜 label; impersonator chat shows the card', (t) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    final s = await demo(t);
    expect(find.byKey(const Key('trust-badge')), findsWidgets); // 부루미 소식 channel
    expect(find.byKey(const Key('trust-fake')), findsOneWidget); // 이벤트 당첨 안내

    await t.tap(find.text('하늘별').first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('first-contact-card')), findsOneWidget);
    expect(find.text('하늘별 공식 계정이 아니에요'), findsOneWidget);
    expect(find.text('7일 안'), findsOneWidget);
    expect(find.text('최근 7일 안에 바꿨어요'), findsOneWidget);
    expect(find.byKey(const Key('stranger-hidden-imp2')), findsOneWidget, reason: 'photo waits');
    expect(find.byKey(const Key('title-trust')), findsOneWidget);

    // Report: goes with the badge holder's ID filled in.
    await t.tap(find.byKey(const Key('first-report')));
    await t.pumpAndSettle();
    expect(find.text('하늘별'), findsWidgets);
    await t.tap(find.byKey(const Key('imp-send')));
    await t.pumpAndSettle();
    final fake = s.backend as FakeBackend;
    expect(fake.impersonationReports.single, ['@haneul_0fficial:test', '@haneulbyeol:test', '']);
    expect(find.text('신고했어요. 운영자가 확인할게요'), findsOneWidget);

    // Accept: the card goes, the photo shows.
    await t.tap(find.byKey(const Key('first-accept')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('first-contact-card')), findsNothing);
    expect(find.byKey(const Key('stranger-hidden-imp2')), findsNothing);
    expect(s.acceptedStranger('!imp'), isTrue);
  });

  testWidgets('three reports put 확인 중 on; 가짜 accounts cannot start chats', (t) async {
    final fake = FakeBackend();
    final s = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    for (var i = 0; i < 3; i++) {
      await fake.reportImpersonation('@copy:test', victim: '@star:test');
    }
    fake.trust = TrustList(version: 2, badges: fake.trust.badges, flags: {...fake.trust.flags, '@scam:test': 'fake'});
    fake.invites.add(const Invite(roomId: '!scam', name: '', inviter: '@scam:test', direct: true));
    await s.refresh();
    expect(s.trust.flags['@copy:test'], 'checking');
    expect(fake.rooms.containsKey('!scam'), isFalse, reason: 'declined on my phone');
  });

  testWidgets('badge application: code, kind, where it was posted', (t) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    final s = await demo(t);
    await t.tap(find.text('설정'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byKey(const Key('badge-row')), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.byKey(const Key('badge-row')));
    await t.pumpAndSettle();
    expect(find.text('burumy-7K2Q9M'), findsOneWidget);
    await t.tap(find.byKey(const Key('badge-kind-channel')));
    await t.enterText(find.byKey(const Key('badge-name')), '하늘별');
    await t.enterText(find.byKey(const Key('badge-proof')), 'https://instagram.com/haneulbyeol');
    await t.pump();
    await t.tap(find.byKey(const Key('badge-send')));
    await t.pumpAndSettle();
    final fake = s.backend as FakeBackend;
    expect(fake.badgeApplications.single, {'kind': 'channel', 'name': '하늘별', 'proof': 'https://instagram.com/haneulbyeol'});
    expect(find.byKey(const Key('badge-sent')), findsOneWidget);
  });

  testWidgets('sign-up refuses reserved and look-alike IDs', (t) async {
    final fake = FakeBackend();
    fake.trust = const TrustList(
      badges: [Badge(user: '@haneulbyeol:test', name: '하늘별')],
    );
    final s = AppState(fake, locale: const Locale('ko'));
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    Future<void> tryId(String id) async {
      await t.enterText(find.byKey(const Key('auth-id')), id);
      await t.enterText(find.byKey(const Key('auth-pw')), 'abcd1234');
      await t.tap(find.byKey(const Key('auth-submit')));
      await t.pumpAndSettle();
    }

    await tryId('burumy_admin');
    expect(find.textContaining('이 ID는 예약돼 있어요'), findsOneWidget);
    await tryId('haneu1byeol99');
    expect(find.textContaining('공식 계정과 너무 비슷한 ID예요'), findsOneWidget);
    expect(fake.loggedIn, isFalse);
    // Held for its owner: the code field appears; the owner's code opens it.
    await tryId('samsung');
    expect(find.textContaining('진짜 주인을 위해 맡아 둔 ID예요'), findsOneWidget);
    await tryId('abc');
    expect(find.textContaining('4글자 이하 ID'), findsOneWidget);
    expect(fake.loggedIn, isFalse);
    await tryId('samsung');
    await t.tap(find.byKey(const Key('auth-claim-open')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('auth-claim')), 'WRONG');
    await t.tap(find.byKey(const Key('auth-submit')));
    await t.pumpAndSettle();
    expect(find.textContaining('코드가 맞지 않거나'), findsOneWidget);
    expect(fake.loggedIn, isFalse);
    await t.enterText(find.byKey(const Key('auth-claim')), 'BRM-AB12-CD34-EF56');
    await t.tap(find.byKey(const Key('auth-submit')));
    await t.pumpAndSettle();
    expect(fake.loggedIn, isTrue);
  });

  test('channel titles: owner names refused, ordinary words fine', () async {
    final fake = FakeBackend();
    expect(await fake.nameCheck('Samsung', room: true), 'reserved_owner');
    expect(await fake.nameCheck('BTS TV', room: true), 'reserved_owner');
    expect(await fake.nameCheck('뉴스', room: true), '');
    expect(await fake.nameCheck('우리 반', room: true), '');
    expect(await fake.nameCheck('부루미 공지', room: true), 'reserved');
  });
}
