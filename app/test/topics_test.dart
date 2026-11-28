// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 주제 (group topics, tip 527): the encrypted topic pack, sending into a
// topic, the side rail / top bar / list views, closed topics, and
// iPhone-size (393x852) screenshots.
import 'dart:convert';
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/topics.dart';
import 'package:burumy/demo/topics_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/topics.dart';
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
    await loadFont('Pretendard', [
      'assets/fonts/Pretendard-Regular.otf',
      'assets/fonts/Pretendard-Medium.otf',
      'assets/fonts/Pretendard-SemiBold.otf',
      'assets/fonts/Pretendard-Bold.otf',
    ]);
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
  });

  Future<(FakeBackend, AppState)> app(WidgetTester t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final d = DateTime.now();
    addTopicsSample(b, true, at: DateTime(d.year, d.month, d.day, 14));
    final s = AppState(b, locale: const Locale('ko'));
    return (b, s);
  }

  Future<void> shot(WidgetTester t, String name) async {
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/$name.png'));
  }

  Future<void> open(WidgetTester t, AppState s) async {
    await s.afterLogin();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('과학 동아리'));
    await t.pumpAndSettle();
  }

  group('pack', () {
    test('round trip keeps 일반 first and drops bad topics', () {
      final t = Topics.fromJson({
        'on': true,
        'v': 'list',
        't': [
          {'i': 'a1', 'n': '공지', 'e': '📢'},
          {'i': 'bad id!', 'n': 'x'},
          {'i': 'g', 'n': ''},
          {'i': 'a1', 'n': 'dup'},
          {'i': 'b2', 'n': '잡담', 'c': 99, 'x': true},
        ],
      })!;
      expect(t.list.map((x) => x.id), ['g', 'a1', 'b2']);
      expect(t.view, Topics.listView);
      expect(t.byId('b2')!.closed, isTrue);
      expect(t.byId('b2')!.color, Topics.colorCount - 1);
      expect(Topics.fromJson(t.toJson())!.list.length, 3);
    });

    test('a message with no or unknown topic is 일반', () {
      const t = Topics(
        on: true,
        list: [
          Topic(id: 'g'),
          Topic(id: 'a1', name: 'x'),
        ],
      );
      Msg m(String? topic) => Msg(id: '1', sender: '@a:test', body: 'hi', time: DateTime(2026), mine: false, kind: 'text', topic: topic);
      expect(t.topicOf(m(null)), 'g');
      expect(t.topicOf(m('zz')), 'g');
      expect(t.topicOf(m('a1')), 'a1');
    });

    testWidgets('a pack that does not match the room fingerprint is ignored', (tester) async {
      final (b, s) = await app(tester);
      await s.afterLogin();
      final cfg = await b.roomConfig('!science');
      expect(Topics.of(s, '!science', cfg).on, isTrue);
      // A member sends a fake list: the room's fingerprint (admins only) does not match.
      await Topics.onSignal(
        s,
        Signal(
          roomId: '!science',
          id: 'x',
          sender: '@leo:test',
          kind: Topics.kind,
          data: {
            'on': true,
            't': [
              {'i': 'evil', 'n': '가짜'},
            ],
          },
          time: DateTime.now(),
        ),
      );
      expect(Topics.of(s, '!science', cfg).byId('evil'), isNull);
    });

    testWidgets('saving keeps only the fingerprint in the room settings', (tester) async {
      final (b, s) = await app(tester);
      await s.afterLogin();
      final cfg = await b.roomConfig('!science');
      final t = Topics.of(s, '!science', cfg);
      await Topics.save(
        s,
        '!science',
        t.copyWith(
          list: [
            ...t.list,
            const Topic(id: 'tnew', name: '새 주제'),
          ],
        ),
      );
      final after = await b.roomConfig('!science');
      expect(after['topics'], isA<Map>());
      expect((after['topics'] as Map).keys, ['h']);
      expect(jsonEncode(after).contains('새 주제'), isFalse);
      // The list went to the room as an encrypted signal.
      expect(b.sentSignals.where((x) => x.$2 == Topics.kind).length, 1);
      expect(Topics.of(s, '!science', after).byId('tnew')!.name, '새 주제');
    });
  });

  testWidgets('rail: pick a topic, only its messages, words go into it', (t) async {
    final (b, s) = await app(t);
    await open(t, s);
    expect(find.byKey(const Key('topic-rail')), findsOneWidget);
    // 모두 shows the topic lines.
    expect(find.byKey(const Key('topic-line-tastro')), findsOneWidget);
    expect(find.text('일반에 메시지'), findsOneWidget);
    await t.tap(find.byKey(const Key('topic-rail-tastro')));
    await t.pumpAndSettle();
    expect(find.textContaining('개기월식'), findsOneWidget);
    expect(find.textContaining('국밥집'), findsNothing);
    expect(find.text('천문에 메시지'), findsOneWidget);
    await t.enterText(find.byKey(const Key('composer')), '토성 사진 올릴게요');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('send')));
    await t.pumpAndSettle();
    final sent = (await b.timeline('!science')).lastWhere((m) => m.body == '토성 사진 올릴게요');
    expect(sent.topic, 'tastro');
    // The send topic is cleared when the chat closes.
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await b.sendText('!science', '밖에서 보낸 글');
    expect((await b.timeline('!science')).last.topic, isNull);
  });

  testWidgets('closed topic: members can only read', (t) async {
    final (b, s) = await app(t);
    b.roomMembers['!science'] = [const Member(userId: '@me:test', name: 'me', role: 'member'), const Member(userId: '@mina:test', name: '미나', role: 'owner')];
    await open(t, s);
    await t.tap(find.byKey(const Key('topic-rail-tchem')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('topic-closed')), findsOneWidget);
    expect(find.byKey(const Key('composer')), findsNothing);
    // Members can't add topics.
    expect(find.byKey(const Key('topic-rail-add')), findsNothing);
  });

  testWidgets('shots: rail, bar, list, settings, new topic', (t) async {
    final (b, s) = await app(t);
    await open(t, s);
    await shot(t, 'ko_t1_topics_rail_all');
    await t.tap(find.byKey(const Key('topic-rail-tastro')));
    await t.pumpAndSettle();
    await shot(t, 'ko_t2_topics_rail_astro');
    await t.tap(find.byKey(const Key('topic-switch-bar')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('topic-bar')), findsOneWidget);
    await shot(t, 'ko_t3_topics_bar');
    await t.tap(find.byKey(const Key('topic-switch-rail')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('topic-rail')), findsOneWidget);
    // New topic from the rail (owner).
    await t.tap(find.byKey(const Key('topic-rail-add')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('topic-name')), '사진');
    await t.tap(find.byKey(const Key('topic-color-4')));
    await t.pumpAndSettle();
    await shot(t, 'ko_t4_topic_new');
    await t.tap(find.byKey(const Key('topic-done')));
    await t.pumpAndSettle();
    expect(find.text('사진에 메시지'), findsOneWidget);
    // List view (settings page).
    final cfg = await b.roomConfig('!science');
    await Topics.save(s, '!science', Topics.of(s, '!science', cfg).copyWith(view: Topics.listView));
    await t.tap(find.byKey(const Key('back')).last);
    await t.pumpAndSettle();
    await t.tap(find.text('과학 동아리'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('topic-list')), findsOneWidget);
    expect(find.byKey(const Key('composer')), findsNothing);
    await shot(t, 'ko_t5_topics_list');
    await t.tap(find.byKey(const Key('topic-row-tfood')));
    await t.pumpAndSettle();
    expect(find.text('맛집에 메시지'), findsOneWidget);
    expect(find.textContaining('개기월식'), findsNothing);
    await shot(t, 'ko_t6_topic_page');
  });

  testWidgets('shots: settings page', (t) async {
    final (b, s) = await app(t);
    await s.afterLogin();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(CupertinoPageRoute(builder: (_) => const TopicsPage(roomId: '!science')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('topics-view-tabs')), findsOneWidget);
    await shot(t, 'ko_t7_topics_settings');
    expect(b.groups.contains('!science'), isTrue);
  });
}
