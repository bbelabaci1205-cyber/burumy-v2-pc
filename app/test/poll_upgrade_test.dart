// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Poll upgrades (Telegram tip 562, our own build): description + photo,
// per-answer photo / sticker / place, members add answers, vote lock,
// shuffle, results hidden until the end, and the per-answer voter list.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/poll.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1x1 transparent PNG.
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
];

Future<(FakeBackend, AppState, String)> _open(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final fake = FakeBackend();
  final state = AppState(fake, locale: const Locale('ko'));
  await fake.login(id: 'me', password: 'x');
  final team = await fake.createGroup('우리 팀', ['@mina:test']);
  await state.refresh();
  return (fake, state, team);
}

Future<void> _scrollTo(WidgetTester t, String key) async {
  await t.scrollUntilVisible(
    find.byKey(Key(key)),
    120,
    scrollable: find.descendant(of: find.byType(CreatePollPage), matching: find.byType(Scrollable)).first,
  );
  await t.pumpAndSettle();
}

void main() {
  test('shuffle: same order for the same person, differs between people, all answers kept', () {
    final p = PollInfo(question: 'q', options: [for (var i = 0; i < 8; i++) PollOption('a$i', '$i', 0)], shuffle: true);
    final a1 = p.orderFor('\$p', '@a').map((o) => o.id).toList();
    final a2 = p.orderFor('\$p', '@a').map((o) => o.id).toList();
    final b = p.orderFor('\$p', '@b').map((o) => o.id).toList();
    expect(a1, a2);
    expect(a1.toSet(), {for (var i = 0; i < 8; i++) 'a$i'});
    expect(a1, isNot(b));
    const plain = PollInfo(question: 'q', options: [PollOption('a0', 'x', 0), PollOption('a1', 'y', 0)]);
    expect(plain.orderFor('\$p', '@a').map((o) => o.id), ['a0', 'a1']);
  });

  test('hidden results open only at the end', () {
    final now = DateTime(2026, 11, 27, 12);
    final p = PollInfo(question: 'q', options: const [], hideResults: true, mine: const ['a0'], closeAt: now.add(const Duration(hours: 1)));
    expect(p.resultsOpen(now), isFalse);
    expect(p.resultsOpen(now.add(const Duration(hours: 1))), isTrue);
    expect(p.copyWith(closed: true).resultsOpen(now), isTrue);
    expect(const PollInfo(question: 'q', options: [], mine: ['a0']).resultsOpen(now), isTrue);
  });

  testWidgets('make a poll with description, photo, sticker, place and all new switches', (t) async {
    final (fake, state, team) = await _open(t);
    debugPollPhoto = () async => const PollPhoto('image/png', _png);
    addTearDown(() => debugPollPhoto = null);
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-tab-poll')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('poll-question')), '토요일 어디서?');
    await t.enterText(find.byKey(const Key('poll-description')), '오후 2시예요');
    await t.tap(find.byKey(const Key('poll-photo')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('poll-photo-thumb')), findsOneWidget);
    await t.enterText(find.byKey(const Key('poll-option-0')), '한강');
    await t.enterText(find.byKey(const Key('poll-option-1')), '성수');
    // Answer 0: a sticker.
    await t.tap(find.byKey(const Key('poll-attach-0')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-sticker')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('sticker-pick')), findsOneWidget);
    await t.tap(find.byKey(const Key('pick-buru_04_good')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('poll-att-0')), findsOneWidget);
    // Answer 1: a photo.
    await t.tap(find.byKey(const Key('poll-attach-1')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('attach-photo')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('poll-att-1')), findsOneWidget);
    for (final k in ['poll-allow-add', 'poll-allow-change', 'poll-shuffle', 'poll-hide']) {
      await _scrollTo(t, k);
      await t.tap(find.byKey(Key(k)));
      await t.pumpAndSettle();
    }
    expect(find.textContaining('만든 사람 휴대폰 밖으로'), findsOneWidget, reason: 'anonymous + hidden explains the real hiding');
    expect(find.textContaining('바꾸거나 취소할 수 없어요'), findsOneWidget);
    await t.tap(find.byKey(const Key('poll-create')));
    await t.pumpAndSettle();

    final m = fake.rooms[team]!.last;
    final p = m.poll!;
    expect(p.description, '오후 2시예요');
    expect(p.hasPhoto, isTrue);
    expect(p.options[0].sticker, 'buru_04_good');
    expect(p.options[1].hasPhoto, isTrue);
    expect([p.addOptions, p.changeVote, p.shuffle, p.hideResults], [true, false, true, true]);
    expect(fake.pollPhotos['${m.id}|'], isNotEmpty);
    expect(fake.pollPhotos['${m.id}|a1'], isNotEmpty);
    expect(find.byKey(const Key('poll-desc')), findsOneWidget);
    expect(find.byKey(const Key('opt-sticker-a0')), findsOneWidget);
    expect(find.textContaining('바꾸기 불가'), findsOneWidget);

    // Vote: hidden until the end, no take-back.
    await t.tap(find.byKey(const Key('poll-a0')));
    await t.pumpAndSettle();
    expect(find.text('결과는 마감 후 공개돼요'), findsOneWidget);
    expect(find.byKey(const Key('poll-mine')), findsNothing, reason: 'no result bars yet');
    expect(find.textContaining('%'), findsNothing);
    await t.longPress(find.text('토요일 어디서?'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('menu-retract')), findsNothing);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(() => fake.vote(team, m.id, const ['a1']), throwsStateError);

    // The maker closes it: numbers appear.
    await fake.closePoll(team, m.id);
    await state.refresh();
    await t.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byKey(const Key('poll-mine')), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('members add an answer; open poll shows who chose what', (t) async {
    final (fake, state, team) = await _open(t);
    await fake.createPoll(team, '점심?', ['국수', '밥'], anonymous: false, multiple: false, extras: const PollExtras(addOptions: true));
    final id = fake.rooms[team]!.last.id;
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('우리 팀'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-add-answer')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('poll-add-text')), '국수');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-add-done')));
    await t.pumpAndSettle();
    expect(find.text('이미 있는 선택지예요'), findsOneWidget);
    await t.enterText(find.byKey(const Key('poll-add-text')), '김밥');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('poll-add-done')));
    await t.pumpAndSettle();
    final added = fake.rooms[team]!.firstWhere((m) => m.id == id).poll!.options.last;
    expect(added.text, '김밥');
    expect(find.text('김밥'), findsOneWidget);
    expect(find.byKey(Key('added-by-${added.id}')), findsOneWidget);

    fake.seedVotes(team, id, {
      '@mina:test': [added.id],
      '@leo:test': ['a0'],
    });
    await state.refresh();
    await t.pumpAndSettle(const Duration(seconds: 4));
    await t.tap(find.byKey(Key('poll-${added.id}')));
    await t.pumpAndSettle();
    expect(find.text('67%'), findsOneWidget);
    await t.tap(find.byKey(const Key('poll-view-votes')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('poll-results')), findsOneWidget);
    expect(find.byKey(Key('voter-${added.id}-@mina:test')), findsOneWidget);
    expect(find.byKey(const Key('voter-a0-@leo:test')), findsOneWidget);
    expect(find.text('아직 아무도 고르지 않았어요'), findsOneWidget, reason: '밥 has no votes');
  });

  testWidgets('channel polls: no adding answers, anonymous, no voter list', (t) async {
    final (fake, state, _) = await _open(t);
    final ch = await fake.createGroup('소식', [], channel: true);
    await fake.createPoll(ch, '다음 글?', ['a', 'b'], anonymous: false, multiple: false, extras: const PollExtras(addOptions: true));
    final p = fake.rooms[ch]!.last.poll!;
    expect(p.anonymous, isTrue);
    expect(p.addOptions, isFalse);
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
  });
}
