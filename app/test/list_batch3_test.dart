// Telegram tips batch 3 (chat list + alerts): timed / sound-only mute,
// badge count, picture run, swipe choice, default folder, back trail.
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/chat_badge.dart';
import 'package:burumy/core/chat_mute.dart';
import 'package:burumy/core/rules.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:burumy/ui/list_thumbs.dart';
import 'package:burumy/main.dart' show BurumyApp;
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

ChatPreview chat(String id, {int unread = 0, bool channel = false, bool muted = false, bool archived = false}) =>
    ChatPreview(roomId: id, name: id, isDirect: !channel, isChannel: channel, encrypted: true, unread: unread, muted: muted, archived: archived);

Msg pic(String id, DateTime t, {String who = '@a:test', String kind = 'image'}) => Msg(id: id, sender: who, body: 'p', time: t, mine: false, kind: kind);

void main() {
  test('badge: messages or chats, channels and muted switches', () {
    final list = [chat('a', unread: 3), chat('c', unread: 5, channel: true), chat('m', unread: 2, muted: true), chat('z', unread: 9, archived: true)];
    expect(badgeCount(list, {}), 8);
    expect(badgeCount(list, {badgeChannelsPref: '0'}), 3);
    expect(badgeCount(list, {badgeMutedPref: '1'}), 10);
    expect(badgeCount(list, {badgeMessagesPref: '0'}), 2);
    expect(badgeCount(list, {'list_hidden:a': '1'}), 5);
  });

  test('timed mute ends; expired list', () {
    final now = DateTime(2026, 11, 27, 9);
    final prefs = {muteUntilKey('!a'): '${now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch}', muteUntilKey('!b'): '${now.add(const Duration(hours: 1)).millisecondsSinceEpoch}'};
    expect(expiredMutes(prefs, now), ['!a']);
    expect(muteEnd(prefs, '!b'), now.add(const Duration(hours: 1)));
  });

  test('picture run: up to 3 from one person close together', () {
    final t = DateTime(2026, 11, 27, 9);
    expect(mediaRun([pic('1', t), pic('2', t), pic('3', t), pic('4', t)]).map((m) => m.id), ['2', '3', '4']);
    expect(mediaRun([pic('1', t, who: '@b:test'), pic('2', t)]).map((m) => m.id), ['2']);
    expect(mediaRun([pic('1', t), pic('2', t.add(const Duration(minutes: 5)))]).map((m) => m.id), ['2']);
    expect(mediaRun([pic('1', t), Msg(id: 'x', sender: '@a:test', body: 'hi', time: t, mine: false, kind: 'text')]), isEmpty);
  });

  testWidgets('timed mute lifts itself; sound-only keeps alerts', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    final g = await fake.createGroup('팀', ['@mina:test']);
    await state.refresh();
    await state.muteChat(g, const Duration(hours: 1));
    expect(fake.mutedChats, contains(g));
    // Pretend the time is over.
    await state.setPref(muteUntilKey(g), '${DateTime(2000).millisecondsSinceEpoch}');
    await state.refresh();
    expect(fake.mutedChats, isNot(contains(g)));
    expect(state.settings[muteUntilKey(g)], isNull);
    await state.setChatQuiet(g, true);
    final c = state.chats.firstWhere((c) => c.roomId == g);
    final n = Notice(roomId: g, chat: '팀', sender: '@mina:test', kind: 'text', body: 'hi', time: DateTime(2026));
    expect(noticeAllowed(n, state.settings, c, DateTime(2026, 1, 1, 12)), isTrue);
    expect(state.on(quietKey(g)), isTrue);
  });

  testWidgets('swipe choice moves the action to the outer end', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await fake.createDirectChat('bob');
    await state.setPref('swipe_left', 'pin');
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.drag(find.text('bob'), const Offset(-200, 0));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('swipe-pin')), findsOneWidget);
    expect(find.byKey(const Key('swipe-archive')), findsOneWidget);
  });

  testWidgets('folder put in front opens first', (t) async {
    final fake = FakeBackend();
    final state = AppState(fake, locale: const Locale('ko'));
    await fake.login(id: 'me', password: 'x');
    await saveFolders(state, [ChatFolder(id: 'w', name: '일', kinds: {'group'})]);
    await state.setPref(allPosPref, '1');
    expect(startFilter(state), 'folder:w');
    await state.setPref(allPosPref, '0');
    expect(startFilter(state), 'all');
  });
}
