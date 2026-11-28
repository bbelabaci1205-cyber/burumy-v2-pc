// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 빠른 다듬기 D1 (Telegram tips 450 · 502 · 477 · 546, 2026-11-27).
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/codes.dart';
import 'package:burumy/core/features.dart';
import 'package:burumy/core/video_resume.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:burumy/ui/feedback_page.dart';
import 'package:burumy/ui/room_tools.dart';
import 'package:burumy/l10n/app_localizations.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/ui/chat_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

void main() {
  setUp(() => Features.tipsD1 = true);

  test('477: finds codes, skips money, times, phones and long texts', () {
    expect(findCode('[부루미] 인증번호는 482913 입니다.'), '482913');
    expect(findCode('Your verification code is 123 456'), '123456');
    expect(findCode('로그인 코드: G-482913 (5분 안에 입력)'), 'G-482913');
    expect(findCode('Your one-time code: AB12CD'), 'AB12CD');
    expect(findCode('인증번호 4829.'), '4829');
    expect(findCode('내일 2026년에 만나요 코드 리뷰 해요'), isNull);
    expect(findCode('인증 비용 12,000원 이에요'), isNull);
    expect(findCode('확인 코드 회의 10:30 에 봐요'), isNull);
    expect(findCode('인증 문의 010-1234-5678'), isNull);
    expect(findCode('482913'), isNull, reason: 'no code word');
    expect(findCode('코드 ${'아주 긴 글 ' * 80} 123456'), isNull);
  });

  test('502: icon-only folders keep the name but show only the emoji', () {
    final f = ChatFolder(id: '1', name: '회사', emoji: '💼', iconOnly: true);
    expect(f.label, '💼');
    final back = ChatFolder.fromJson(f.toJson());
    expect(back.iconOnly, isTrue);
    expect(back.name, '회사');
    expect(ChatFolder(id: '2', name: '가족', emoji: '🏠').label, '🏠 가족');
    expect(ChatFolder(id: '3', name: '친구', iconOnly: true).label, '친구', reason: 'no emoji = name');
    expect(ChatFolder.fromJson({'id': 'x', 'name': 'a', 'kinds': [], 'include': [], 'exclude': []}).iconOnly, isFalse);
  });

  test('546: the message carries only kind, words, device and app', () {
    final t = feedbackText(bug: true, title: '사진이 안 보여요', body: ' 앨범을 열면 하얘요 ', device: 'iOS', errors: ['TypeError: x']);
    expect(t, startsWith('[BUG] 사진이 안 보여요'));
    expect(t, contains('앨범을 열면 하얘요'));
    expect(t, contains('iOS'));
    expect(t, contains('• TypeError: x'));
    expect(feedbackText(bug: false, title: 'a', body: 'b', device: 'web'), isNot(contains('Error log')));
    expect(supportIdFor('@me:burumy.app'), '@burumy_support:burumy.app');
  });

  Widget wrap(AppState s, Widget child) => AppScope(
    state: s,
    child: CupertinoApp(
      locale: const Locale('ko'),
      localizationsDelegates: const [L.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: L.supportedLocales,
      home: child,
    ),
  );

  testWidgets('450: slider sets the max, preview follows, none blocks', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final s = AppState(b, locale: const Locale('ko'));
    final room = await b.createGroup('소식', const [], channel: true);
    await t.pumpWidget(wrap(s, ReactionsPage(roomId: room)));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('react-max-slider')), findsOneWidget);
    expect(find.byKey(const Key('react-preview')), findsOneWidget);
    // Drag the slider all the way left: 1 kind.
    t.widget<CupertinoSlider>(find.byKey(const Key('react-max-slider'))).onChanged!(1);
    await t.pump(const Duration(milliseconds: 500));
    await t.pumpAndSettle();
    expect((await b.roomConfig(room))['reactions_max'], 1);
    expect(find.text('1'), findsWidgets);
    expect(find.byKey(Key('react-preview-${reactionPool[0]}')), findsOneWidget);
    expect(find.byKey(Key('react-preview-${reactionPool[1]}')), findsNothing);
    await t.tap(find.byKey(const Key('pick-none')));
    await t.pumpAndSettle();
    expect((await b.roomConfig(room))['reactions'], 'none');
    expect(find.byKey(const Key('react-preview')), findsNothing);
    expect(find.textContaining('서버도 새 반응을 받지 않아요'), findsOneWidget);
  });

  testWidgets('546: send goes to the support account as one message', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final s = AppState(b, locale: const Locale('ko'));
    await t.pumpWidget(wrap(s, const FeedbackPage()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('feedback-send')));
    await t.pumpAndSettle();
    expect(find.text('요약과 내용을 모두 적어 주세요.'), findsOneWidget);
    await t.enterText(find.byKey(const Key('feedback-subject')), '폴더가 안 보여요');
    await t.enterText(find.byKey(const Key('feedback-body')), '폴더를 만들었는데 탭에 없어요');
    await t.tap(find.byKey(const Key('feedback-send')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('feedback-ok')));
    await t.pumpAndSettle();
    final room = await b.createDirectChat(supportIdFor(b.userId));
    final sent = await b.timeline(room);
    expect(sent.last.body, startsWith('[BUG] 폴더가 안 보여요'));
    expect(find.text('🐞  폴더가 안 보여요'), findsOneWidget);
  });

  test('509: long videos remember the place; ends, short ones and the cap forget', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final s = AppState(b, locale: const Locale('ko'));
    const k = '!r|\$v';
    const total = Duration(minutes: 10);
    await VideoResume.save(s, k, const Duration(minutes: 4), total);
    expect(VideoResume.at(s, k), const Duration(minutes: 4));
    expect(VideoResume.watched(s, k), closeTo(0.4, 0.001));
    await VideoResume.save(s, k, total - const Duration(seconds: 3), total);
    expect(VideoResume.at(s, k), isNull, reason: 'watched to the end');
    await VideoResume.save(s, 'short', const Duration(seconds: 20), const Duration(seconds: 50));
    expect(VideoResume.at(s, 'short'), isNull);
    for (var i = 0; i <= VideoResume.cap; i++) {
      await VideoResume.save(s, 'v$i', const Duration(minutes: 1), total);
    }
    expect(VideoResume.at(s, 'v0'), isNull, reason: 'oldest dropped');
    expect(VideoResume.at(s, 'v${VideoResume.cap}'), const Duration(minutes: 1));
  });

  testWidgets('477: tapping 코드 복사 copies and says so', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final room = await b.createDirectChat('@sky:test');
    b.rooms[room]!.add(Msg(id: 'c1', sender: '@sky:test', body: '인증번호는 482913 이에요', time: DateTime(2026, 11, 27, 9), mine: false, kind: 'text'));
    final s = AppState(b, locale: const Locale('ko'));
    String? copied;
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.setData') copied = (c.arguments as Map)['text'] as String?;
      return null;
    });
    await t.pumpWidget(wrap(s, ChatPage(roomId: room, title: 'sky')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('copy-code-c1')));
    await t.pump(const Duration(milliseconds: 100));
    expect(copied, '482913');
    expect(find.textContaining('코드를 복사했어요'), findsOneWidget);
    await t.pump(const Duration(minutes: 2));
  });
}
