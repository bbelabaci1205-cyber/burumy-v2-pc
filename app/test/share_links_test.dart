// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 공유·링크 묶음 (Telegram tips 253 · 438 · 503 · 350 · 182, 2026-11-27).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/accounts.dart';
import 'package:burumy/core/backend.dart' show Member;
import 'package:burumy/core/features.dart';
import 'package:burumy/core/room_links.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/ui/invite_links.dart';
import 'package:burumy/ui/invite_links_more.dart';
import 'package:burumy/ui/chat_links.dart';
import 'package:burumy/core/qr_read.dart';
import 'package:burumy/ui/qr_watch.dart';
import 'package:burumy/ui/story_camera.dart';
import 'package:burumy/core/share_in.dart';
import 'package:burumy/ui/share_in.dart';

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.shareLinks = true);
  tearDown(() => Features.shareLinks = false);

  Widget wrap(AppState s, Widget child) => AppScope(
    state: s,
    child: CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );

  void phone(WidgetTester t) {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
  }

  group('253 extra invite links', () {
    final t0 = DateTime(2026, 11, 27, 12);
    InviteLink k({DateTime? until, int max = 0, int uses = 0, bool revoked = false, DateTime? made}) =>
        InviteLink(code: 'a' * 26, until: until, max: max, uses: uses, made: made ?? t0, revoked: revoked);

    test('state and ring: green while plenty is left, orange near the end, red when over', () {
      expect(k().state(t0), 'live');
      expect(k().left(t0), 1);
      expect(k(until: t0.add(const Duration(days: 7))).state(t0.add(const Duration(days: 1))), 'live');
      expect(k(until: t0.add(const Duration(days: 7))).left(t0.add(const Duration(days: 1))), closeTo(6 / 7, .001));
      // Less than a day left, or a quarter of the seats.
      expect(k(until: t0.add(const Duration(days: 7))).state(t0.add(const Duration(days: 6, hours: 1))), 'soon');
      expect(k(max: 10, uses: 8).state(t0), 'soon');
      expect(k(max: 10, uses: 8).left(t0), closeTo(.2, .001));
      expect(k(max: 10, uses: 10).state(t0), 'full');
      expect(k(until: t0).state(t0), 'ended');
      expect(k(revoked: true).state(t0), 'revoked');
      expect(k(max: 10, uses: 10).usable(t0), isFalse);
      // The smaller of time left and seats left.
      expect(k(until: t0.add(const Duration(hours: 10)), max: 4, uses: 1).left(t0.add(const Duration(hours: 5))), closeTo(.5, .001));
    });

    test('server refusals become plain reasons', () {
      expect(linkRefusal(StateError('[403 / M_FORBIDDEN] burumy: link expired')), 'ended');
      expect(linkRefusal(StateError('burumy: link full')), 'full');
      expect(linkRefusal(StateError('M_NOT_FOUND')), isNull);
    });

    testWidgets('make one with 1 day and 10 people; it lists with its ring and words', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final s = AppState(b, locale: const Locale('ko'));
      final room = await b.createGroup('동네 친구들', const []);
      await b.newPrivateLink(room);
      await t.pumpWidget(wrap(s, InviteLinkPage(roomId: room, name: '동네 친구들', isChannel: false)));
      await t.pumpAndSettle();
      expect(find.text('추가 링크'), findsOneWidget);
      await t.tap(find.byKey(const Key('inv-new')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('inv-name')), '인스타 프로필');
      await t.tap(find.text('1일'));
      await t.pumpAndSettle();
      await t.tap(find.text('10명'));
      await t.pumpAndSettle();
      expect(find.text('10명이 들어오면 링크가 닫혀요'), findsOneWidget);
      await t.tap(find.byKey(const Key('inv-save')));
      await t.pumpAndSettle();
      final made = (await b.inviteLinks(room)).single;
      expect(made.name, '인스타 프로필');
      expect(made.max, 10);
      expect(made.until!.difference(made.made).inHours, closeTo(24, 1));
      expect(find.text('인스타 프로필'), findsOneWidget);
      expect(find.textContaining('0명 참여 · 10명 남음'), findsOneWidget);
      expect(find.byType(LinkRing), findsOneWidget);
    });

    testWidgets('people come in until it is full; then the join card says so', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final room = await b.createGroup('동네 친구들', const []);
      final l = await b.makeInviteLink(room, max: 1);
      b.rooms.remove(room); // join from "outside"
      await b.joinLink('private', l.code);
      expect((await b.inviteLinks(room)).single.uses, 1);
      b.rooms.remove(room);
      Object? err;
      try {
        await b.joinLink('private', l.code);
      } catch (e) {
        err = e;
      }
      expect(linkRefusal(err!), 'full');
      final s = AppState(b, locale: const Locale('ko'));
      await t.pumpWidget(
        wrap(
          s,
          JoinLinkPage(
            target: LinkTarget(kind: 'private', code: l.code, name: '동네 친구들'),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('join-go')));
      await t.pumpAndSettle();
      expect(find.text('이 초대 링크는 인원이 다 찼어요'), findsOneWidget);
    });

    testWidgets('취소 waits 5 seconds and can be taken back', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final s = AppState(b, locale: const Locale('ko'));
      final room = await b.createGroup('동네 친구들', const []);
      final l = await b.makeInviteLink(room, name: '친구용');
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(
              key: const Key('go'),
              onPressed: () => Navigator.of(c).push(
                CupertinoPageRoute<void>(
                  builder: (_) => InviteLinkDetailPage(roomId: room, roomName: '동네 친구들', isChannel: false, link: l),
                ),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      expect(find.text('아직 아무도 안 들어왔어요'), findsOneWidget);
      await t.tap(find.byKey(const Key('inv-cancel')));
      await t.pump();
      expect(find.byKey(const Key('undo-countdown')), findsOneWidget);
      await t.tap(find.byKey(const Key('undo-countdown-undo')));
      await t.pump(const Duration(seconds: 6));
      expect((await b.inviteLinks(room)).single.revoked, isFalse);
      // Again, and let the time run out.
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('inv-cancel')));
      await t.pump();
      await t.pump(const Duration(seconds: 6));
      expect((await b.inviteLinks(room)).single.revoked, isTrue);
    });
  });

  group('438 chat links', () {
    test('the link keeps who, words and key after #, and reads back', () {
      const k = ChatLink(userId: '@eric:burumy.app', text: '케이크 주문하고 싶어요 & 내일 가능해요?', key: 'blue7');
      expect(k.url, startsWith('https://${RoomLinks.host}/dm#u='));
      final back = ChatLink.parse('여기로 연락 주세요 ${k.url}')!;
      expect(back.userId, '@eric:burumy.app');
      expect(back.text, '케이크 주문하고 싶어요 & 내일 가능해요?');
      expect(back.key, 'blue7');
      expect(ChatLink.parse('https://${RoomLinks.host}/dm#u=eric'), isNull);
      expect(ChatLink.parse('https://evil.example/dm#u=@a:b'), isNull);
      final long = ChatLink.parse(ChatLink(userId: '@a:b', text: '가' * 900).url)!;
      expect(long.text.length, ChatLink.maxText);
      expect(MyChatLink.listFrom(MyChatLink.listTo(const [MyChatLink(id: '1', name: '가게', text: '안녕하세요', withKey: true)])).single.withKey, isTrue);
    });

    testWidgets('make a link in Settings; the card shows it to copy', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final s = AppState(b, locale: const Locale('ko'));
      await t.pumpWidget(wrap(s, const ChatLinksPage()));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('chat-link-new')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('chat-link-text')), '생일 케이크 주문하고 싶어요');
      await t.enterText(find.byKey(const Key('chat-link-name')), '가게 문의');
      await t.pump();
      expect(find.descendant(of: find.byKey(const Key('chat-link-preview')), matching: find.text('생일 케이크 주문하고 싶어요')), findsOneWidget);
      await t.tap(find.byKey(const Key('chat-link-save')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('chat-link-card')), findsOneWidget);
      final saved = myChatLinks(s).single;
      expect(saved.name, '가게 문의');
      expect(ChatLink.parse(chatLinkUrl(s, saved))!.text, '생일 케이크 주문하고 싶어요');
    });

    testWidgets('opening one: asks once, starts the chat, the words wait in the composer', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      b.directory['@sweetbake:test'] = '달콤 베이커리';
      final s = AppState(b, locale: const Locale('ko'));
      await s.refresh();
      const link = ChatLink(userId: '@sweetbake:test', text: '케이크 주문하고 싶어요');
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(key: const Key('go'), onPressed: () => openChatLink(c, link), child: const Text('go')),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      expect(find.text('달콤 베이커리'), findsOneWidget);
      expect(find.byKey(const Key('chat-link-words')), findsOneWidget);
      await t.tap(find.byKey(const Key('chat-link-start')));
      await t.pumpAndSettle();
      final dm = s.chats.firstWhere((c) => c.isDirect && c.peer == '@sweetbake:test');
      expect(s.pref('draft:${dm.roomId}', ''), '케이크 주문하고 싶어요');
      expect(find.text('케이크 주문하고 싶어요'), findsWidgets);
    });
  });

  group('503 QR codes in the camera', () {
    final now = DateTime(2026, 11, 27, 12);
    test('what a code holds: ours open in the app, other sites ask first', () {
      expect(QrTarget.of(RoomLinks.private('a' * 26, name: '동네'), now).kind, 'room');
      expect(QrTarget.of(RoomLinks.public('bakery'), now).inApp, isTrue);
      expect(QrTarget.of(const MessageLink('!r:x', r'$e').url, now).kind, 'message');
      expect(QrTarget.of(const ChatLink(userId: '@a:b', text: '안녕').url, now).kind, 'chat');
      expect(QrTarget.of('burumy://u/%40eric%3Aburumy.app', now).userId, '@eric:burumy.app');
      final soon = now.millisecondsSinceEpoch ~/ 1000;
      expect(QrTarget.of('burumy://u/@a:b?until=${soon + 60}', now).kind, 'person');
      expect(QrTarget.of('burumy://u/@a:b?until=$soon', now).kind, 'expired');
      expect(QrTarget.of('burumy://pc-login?k=1', now).kind, 'pc');
      final web = QrTarget.of('https://shop.example.com/menu', now);
      expect(web.kind, 'web');
      expect(web.inApp, isFalse);
      expect(web.host, 'shop.example.com');
      expect(QrTarget.of('WIFI:S:home;;', now).kind, 'text');
    });

    test('the yellow box follows the code through turning, mirroring and the cover fit', () {
      const hit = QrHit('x', [(100, 300), (100, 100), (300, 100)], 400, 400);
      final b = qrBox(hit, turns: 0, boxW: 400, boxH: 400)!;
      expect(b.$1, closeTo((100 - 36) / 400, .001));
      expect(b.$3, closeTo((300 + 36) / 400, .001));
      // A code on the left of a sideways sensor frame sits at the top once turned.
      const side = QrHit('x', [(20, 150), (20, 50), (120, 50)], 400, 200);
      final t = qrBox(side, turns: 1, boxW: 200, boxH: 400)!;
      expect(t.$4, lessThan(.35));
      expect(t.$1 + t.$3, closeTo(1, .001));
      final m = qrBox(side, turns: 1, mirror: true, boxW: 200, boxH: 400)!;
      expect(m.$1 + m.$3, closeTo(1 - (t.$1 + t.$3) + 1, .001));
      expect(qrBox(const QrHit('x', [], 1, 1), turns: 0, boxW: 1, boxH: 1), isNull);
    });

    Future<void> camera(WidgetTester t, String code) async {
      phone(t);
      StoryCameraPage.fake = true;
      QrWatcher.fake = code;
      addTearDown(() => QrWatcher.fake = null);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final s = AppState(b, locale: const Locale('ko'));
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(
              key: const Key('go'),
              onPressed: () => Navigator.of(c).push(CupertinoPageRoute<void>(builder: (_) => const StoryCameraPage())),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
    }

    testWidgets('an invite code: corners, a faint capsule, then solid; a tap opens the join card', (t) async {
      await camera(t, RoomLinks.private('b' * 26, name: '동네 친구들'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('qr-marks')), findsOneWidget);
      expect(find.byKey(const Key('qr-capsule-room')), findsOneWidget);
      expect(find.text('동네 친구들'), findsOneWidget);
      expect(find.text('그룹 보기 ›'), findsOneWidget);
      double opacity() =>
          t.widget<AnimatedOpacity>(find.ancestor(of: find.byKey(const Key('qr-capsule-room')), matching: find.byType(AnimatedOpacity))).opacity;
      expect(opacity(), lessThan(1));
      await t.pump(const Duration(milliseconds: 600));
      expect(opacity(), 1);
      await t.tap(find.byKey(const Key('qr-capsule-room')));
      await t.pumpAndSettle();
      expect(find.byType(StoryCameraPage), findsNothing);
      expect(find.byKey(const Key('join-go')), findsOneWidget);
    });

    testWidgets('another site: its name first, nothing opens by itself', (t) async {
      await camera(t, 'https://shop.example.com/menu');
      await t.pump(const Duration(seconds: 2));
      expect(find.text('shop.example.com'), findsOneWidget);
      await t.tap(find.byKey(const Key('qr-capsule-web')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('qr-web-sheet')), findsOneWidget);
      expect(find.text('shop.example.com 사이트로 이동할까요?'), findsOneWidget);
      await t.tap(find.text('취소'));
      await t.pumpAndSettle();
      expect(find.byType(StoryCameraPage), findsOneWidget);
    });

    testWidgets('no capsule in video mode', (t) async {
      await camera(t, 'https://shop.example.com/menu');
      await t.tap(find.byKey(const Key('cam-mode-video')));
      await t.pumpAndSettle();
      await t.pump(const Duration(seconds: 2));
      expect(find.byKey(const Key('qr-capsule-web')), findsNothing);
    });
  });

  group('350 + 182 sharing in from other apps', () {
    test('what each shared thing is, for the room rules', () {
      expect(const SharedItem(name: 'IMG_1.HEIC', mime: 'image/heic', path: '/x').kind, 'photo');
      expect(const SharedItem(name: 'a.mov', mime: 'video/quicktime', path: '/x').kind, 'video');
      expect(const SharedItem(name: 'text', mime: 'text/plain', text: 'see https://a.b').kind, 'link');
      expect(const SharedItem(name: 'text', mime: 'text/plain', text: '안녕').kind, 'text');
      expect(SharedItem.fromMap({'path': '', 'text': '  '}), isNull);
      expect(SharedItem.fromMap({'path': '/c/1_0_a.pdf', 'name': 'a.pdf', 'mime': 'application/pdf'})!.isText, isFalse);
    });

    testWidgets('pick chats, add a message, send: the bar runs to 완료 and each chat gets it', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final family = await b.createGroup('가족', const []);
      final strict = await b.createGroup('사진 금지방', const []);
      final news = await b.createGroup('공지 채널', const [], channel: true);
      b.roomConfigs[strict] = {
        'member_perms': {'photo': false},
      };
      b.roomMembers[strict] = [Member(userId: b.userId!, name: 'me', role: 'member')];
      b.owner = false;
      final s = AppState(b, locale: const Locale('ko'));
      await s.refresh();
      final photo = File('test/assets/sample_photo.png').readAsBytesSync();
      final items = [
        SharedItem(name: 'IMG_2041.png', mime: 'image/png', bytes: photo),
        const SharedItem(name: 'text', mime: 'text/plain', text: 'https://shop.example.com/cake'),
      ];
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(key: const Key('go'), onPressed: () => openShareIn(c, items), child: const Text('go')),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      expect(find.text('부루미로 보내기'), findsOneWidget);
      expect(find.byKey(const Key('share-in-strip')), findsOneWidget);
      expect(find.byKey(Key('share-in-why-$strict')), findsOneWidget);
      expect(find.text('이 대화는 이 종류를 막아 두었어요'), findsOneWidget);
      expect(find.text('이 대화에는 글을 쓸 수 없어요'), findsOneWidget);
      // Greyed chats can't be picked.
      await t.tap(find.byKey(Key('share-in-to-$news')));
      await t.pump();
      expect(find.byKey(const Key('share-in-send')), findsNothing);
      await t.tap(find.byKey(Key('share-in-to-$family')));
      await t.pump();
      expect(find.byKey(Key('share-in-check-$family')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('share-in-count')), matching: find.text('1')), findsOneWidget);
      await t.enterText(find.byKey(const Key('share-in-comment')), '생일 케이크 여기서 주문하자');
      await t.tap(find.byKey(const Key('share-in-send')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('share-in-mark')), findsOneWidget);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('보내는 중'), findsOneWidget);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('완료'), findsWidgets);
      expect(find.text('1곳에 보냈어요'), findsOneWidget);
      final got = b.rooms[family]!;
      expect(got.where((m) => m.kind == 'image').single.caption, '생일 케이크 여기서 주문하자');
      expect(got.where((m) => m.body == 'https://shop.example.com/cake'), hasLength(1));
      expect(b.rooms[strict], isEmpty);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.byType(ShareSendPage), findsNothing);
    });

    testWidgets('closing without sending sends nothing', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      final g = await b.createGroup('가족', const []);
      final s = AppState(b, locale: const Locale('ko'));
      await s.refresh();
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(
              key: const Key('go'),
              onPressed: () => openShareIn(c, const [SharedItem(name: 'text', mime: 'text/plain', text: '안녕')]),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key('share-in-to-$g')));
      await t.pump();
      await t.tap(find.byKey(const Key('share-in-cancel')));
      await t.pumpAndSettle();
      expect(find.byType(ShareInPage), findsNothing);
      expect(b.rooms[g], isEmpty);
    });

    testWidgets('182: the photo at the top switches the account that sends', (t) async {
      phone(t);
      final b = FakeBackend();
      await b.login(id: 'me', password: 'x');
      await b.createGroup('가족', const []);
      final work = FakeBackend();
      await work.login(id: 'work', password: 'x');
      final team = await work.createGroup('회사 팀', const []);
      final s = AppState(b, locale: const Locale('ko'));
      await s.refresh();
      s.accounts =
          Accounts(
              store: MemoryBookStore(),
              openSlot: (_) async => work,
              eraseSlot: (_) async {},
              makeState: (x) => AppState(x, locale: const Locale('ko')),
            )
            ..list = [AccountEntry(0, b.userId!), AccountEntry(1, work.userId!)]
            ..side[1] = work;
      await t.pumpWidget(
        wrap(
          s,
          Builder(
            builder: (c) => CupertinoButton(
              key: const Key('go'),
              onPressed: () => openShareIn(c, const [SharedItem(name: 'text', mime: 'text/plain', text: '회의 자료예요')]),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('go')));
      await t.pumpAndSettle();
      expect(find.text('가족'), findsOneWidget);
      await t.tap(find.byKey(const Key('share-in-account')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('share-in-account-1')));
      await t.pumpAndSettle();
      expect(find.text('가족'), findsNothing);
      await t.tap(find.byKey(Key('share-in-to-$team')));
      await t.pump();
      await t.tap(find.byKey(const Key('share-in-send')));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(work.rooms[team]!.single.body, '회의 자료예요');
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
    });
  });
}
