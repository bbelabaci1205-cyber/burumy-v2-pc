// 4-app board: 그룹 전용 스토리 (WhatsApp group status). Any member shares
// their own story with just one group; it sits under the person in the
// story row with "○○에만", and never reaches friends outside that group.
import 'dart:io';

import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/demo/demo_backend.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/stories.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pick 그룹에만 → one group → posted as my member story', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final png = File('test/assets/sample_photo.png').readAsBytesSync();
    final b = demoSample(true, png);
    final s = AppState(b, locale: const Locale('ko'));
    await b.login(id: 'me', password: 'x');
    s.settings = await b.settings();
    final g = await b.createGroup('등산 모임', ['@mina:test']);
    await s.refresh();
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    await t.tap(find.text('대화').last);
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byKey(const Key('stories-bar'))), rootNavigator: true)
        .push(CupertinoPageRoute<void>(builder: (_) => StoryComposer(picked: ('p.mp4', png))));
    await t.pump(const Duration(seconds: 1));
    await t.pump(const Duration(milliseconds: 700));
    await t.tap(find.byKey(const Key('story-audience')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    await t.tap(find.byKey(const Key('aud-group')));
    await t.pumpAndSettle();
    expect(find.byKey(Key('aud-group-$g')), findsOneWidget);
    await t.tap(find.byKey(Key('aud-group-$g')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('aud-done')));
    await t.pump(const Duration(milliseconds: 600));
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('등산 모임에만'), findsOneWidget, reason: 'the audience chip says where it goes');
    await t.tap(find.byKey(const Key('story-share')));
    await t.pump(const Duration(milliseconds: 300));
    final x = b.storyList.last;
    expect(x.member, isTrue);
    expect(x.group, isTrue);
    expect(x.roomId, g);
    expect(b.lastStoryOnly, isEmpty, reason: 'not sent to friends one by one');
    await t.pump(const Duration(seconds: 3));
  });

  test('member stories group under the person, a channel refuses them', () async {
    final b = FakeBackend();
    await b.login(id: 'me', password: 'x');
    final s = AppState(b, locale: const Locale('ko'));
    final g = await b.createGroup('등산', ['@mina:test']);
    final ch = await b.createGroup('소식', const [], channel: true);
    await expectLater(b.postStories(mime: 'image/png', bytes: const [1], room: '$memberStoryPrefix$ch'), throwsStateError);
    final now = DateTime.now();
    Story st(String id, String who, {bool member = false, bool group = false}) => Story(
      id: id,
      roomId: g,
      eventId: id,
      sender: who,
      mine: false,
      time: now,
      kind: 'image',
      until: now.add(const Duration(hours: 1)),
      group: group || member,
      member: member,
    );
    final groups = storyGroups(s, [st('a', '@mina:test', member: true), st('b', '@mina:test'), st('c', '@admin:test', group: true)]);
    expect(groups.map((l) => l.map((x) => x.id).toList()), containsAll([
      ['a', 'b'],
      ['c'],
    ]));
  });
}
