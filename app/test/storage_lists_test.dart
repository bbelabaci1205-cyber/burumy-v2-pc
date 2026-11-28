// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Telegram tip batches #22 (저장 공간·데이터: 206 · 367 · 371 · 243 · 379) and
// #23 (목록·알림 설정: 187 · 211 · 178 · 329 · 241), 2026-11-27.
import 'dart:convert';
import 'dart:io';

import 'package:burumy/core/accounts.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/archive_rules.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/core/data_usage.dart';
import 'package:burumy/core/downloads.dart';
import 'package:burumy/core/draft_sync.dart';
import 'package:burumy/core/folder_link.dart';
import 'package:burumy/core/my_sounds.dart';
import 'package:burumy/core/sounds.dart';
import 'package:burumy/core/storage_usage.dart';
import 'package:burumy/demo/more_sample.dart';
import 'package:burumy/demo/sample.dart';
import 'package:burumy/demo/storage_sample.dart';
import 'package:burumy/main.dart';
import 'package:burumy/ui/accounts_ui.dart';
import 'package:burumy/ui/chat_folders.dart';
import 'package:burumy/ui/chat_list_page.dart' show ArchivePage;
import 'package:burumy/ui/data_usage_page.dart';
import 'package:burumy/ui/folder_share.dart';
import 'package:burumy/ui/storage_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Msg text(String id, String body, {bool mine = false, String who = '@mina:test'}) =>
    Msg(id: id, sender: mine ? '@me:test' : who, body: body, time: DateTime(2026, 11, 27, 9), mine: mine, kind: 'text');

Future<(AppState, FakeBackend)> logged() async {
  final b = FakeBackend();
  final s = AppState(b, locale: const Locale('ko'));
  await b.login(id: 'me', password: 'x');
  await s.refresh();
  return (s, b);
}

Future<(AppState, FakeBackend)> demo(WidgetTester t) async {
  t.view.physicalSize = const Size(393 * 3, 852 * 3);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  final photo = File('test/assets/sample_photo.png').readAsBytesSync();
  final b = demoSample(true, photo);
  addMoreChats(b, true, photo);
  addStorageSample(b, true, tone: List.filled(2000, 7), savedTone: List.filled(500, 3));
  final s = AppState(b, locale: const Locale('ko'));
  await s.login('me', 'x');
  return (s, b);
}

Future<void> show(WidgetTester t, AppState s, Widget page) async {
  await t.pumpWidget(BurumyApp(state: s));
  await t.pumpAndSettle();
  final nav = Navigator.of(t.element(find.byType(CupertinoPageScaffold).first), rootNavigator: true);
  // ignore: unawaited_futures
  nav.push(CupertinoPageRoute<void>(builder: (_) => page));
  await t.pumpAndSettle();
}

void main() {
  setUp(() => Downloads.instance.reset());

  // ------------------------------------------------------------ 241
  test('drafts: kept, shared with my devices, newest wins, sync off', () async {
    final (s, b) = await logged();
    await s.saveDraft('!a', '토요일에 갈래?');
    expect(s.pref(draftKey('!a'), ''), '토요일에 갈래?');
    expect(b.draftsOut.single.text, '토요일에 갈래?');
    // Same words again: nothing new goes out.
    await s.saveDraft('!a', '토요일에 갈래?');
    expect(b.draftsOut, hasLength(1));
    // From my PC: newer wins and is marked as from another device.
    b.draftsIn.add(SyncedDraft('!a', 'PC에서 고친 글', DateTime.now().add(const Duration(minutes: 1))));
    await s.refresh();
    expect(s.pref(draftKey('!a'), ''), 'PC에서 고친 글');
    expect(s.pref(draftFromKey('!a'), ''), '1');
    // An older one arriving late loses.
    b.draftsIn.add(SyncedDraft('!a', '옛날 글', DateTime(2020)));
    await s.refresh();
    expect(s.pref(draftKey('!a'), ''), 'PC에서 고친 글');
    // Sent there (empty): cleared here too.
    b.draftsIn.add(SyncedDraft('!a', '', DateTime.now().add(const Duration(minutes: 2))));
    await s.refresh();
    expect(s.pref(draftKey('!a'), ''), '');
    // Switch off: nothing goes out, nothing comes in.
    await s.setOn(draftSyncKey, false);
    await s.saveDraft('!a', '혼자 쓸 글');
    expect(b.draftsOut, hasLength(1));
    b.draftsIn.add(SyncedDraft('!a', '다른 글', DateTime.now().add(const Duration(hours: 1))));
    await s.refresh();
    expect(s.pref(draftKey('!a'), ''), '혼자 쓸 글');
  });

  // ------------------------------------------------------------ 329
  test('my sounds: limits, encrypted store, per-chat sound, removal', () async {
    final (s, b) = await logged();
    expect(MySounds.check(s, 1000, const Duration(seconds: 7)), ToneRefusal.tooLong);
    expect(MySounds.check(s, 400 * 1024, const Duration(seconds: 3)), ToneRefusal.tooBig);
    expect(MySounds.check(s, 1000, const Duration(seconds: 3)), isNull);
    final m = await MySounds.add(s, '엄마 목소리', [1, 2, 3], const Duration(seconds: 3), 'audio/mp4');
    expect(b.savedBlobs['tone_${m.id}'], [1, 2, 3], reason: 'kept in the encrypted store, not a file');
    expect(MySounds.list(s).single.name, '엄마 목소리');
    await s.setPref(MySounds.chatKey('!fam'), m.key);
    expect(MySounds.forChat(s, '!fam', 'sound_group'), m.key);
    expect(MySounds.forChat(s, '!other', 'sound_group'), 'nuri');
    List<int>? played;
    Sounds.bytesPlayer = (bytes, mime) async => played = bytes;
    await Sounds.play(s, m.key);
    expect(played, [1, 2, 3]);
    await MySounds.rename(s, m.id, '엄마');
    expect(MySounds.list(s).single.name, '엄마');
    await MySounds.remove(s, m.id);
    expect(MySounds.list(s), isEmpty);
    expect(b.savedBlobs.containsKey('tone_${m.id}'), isFalse);
    expect(s.pref(MySounds.chatKey('!fam'), ''), '', reason: 'the chat goes back to its kind\'s sound');
  });

  // ------------------------------------------------------------ 206 · 367 · 371
  test('storage: kinds, exception keep time, size limit drops the oldest', () async {
    final (s, b) = await logged();
    final g = await b.createGroup('가족', ['@mom:test']);
    final now = DateTime.now();
    Msg f(String id, String kind, int size, Duration ago) =>
        Msg(id: id, sender: '@mom:test', body: id, time: now.subtract(ago), mine: false, kind: kind, size: size);
    b.rooms[g]!.addAll([f('v', 'video', 600 << 20, Duration.zero), f('p', 'image', 2 << 20, Duration.zero), f('a', 'audio', 1 << 20, Duration.zero)]);
    await s.refresh();
    for (final m in b.rooms[g]!) {
      await Downloads.instance.get(s, g, m);
    }
    final by = Downloads.instance.keptByKind(s);
    expect(by['video']!.$1, 600 << 20);
    expect(by['voice']!.$2, 1, reason: 'voice messages count on their own');
    // Max 1 GB is fine; then pretend the video is old and set 0.5 GB... use
    // the 1 GB step with a bigger total instead.
    final kept = jsonDecode(s.pref('media_kept', '{}')) as Map<String, dynamic>;
    (kept['v'] as List)[2] = DateTime(2020).millisecondsSinceEpoch;
    (kept['v'] as List)[3] = 1100 << 20;
    await s.setPref('media_kept', jsonEncode(kept));
    await s.setCacheMaxMb(1024);
    expect(b.kept.contains('v'), isFalse, reason: 'over 1 GB: the oldest went');
    expect(b.kept, containsAll(['p', 'a']));
    // Exception: this chat keeps its copies though groups clear after a day.
    await s.setKeepDays('group', 1);
    await s.setKeepDaysOf(g, 0);
    expect(s.keepExceptions, [g]);
    final k2 = jsonDecode(s.pref('media_kept', '{}')) as Map<String, dynamic>;
    (k2['p'] as List)[2] = DateTime(2020).millisecondsSinceEpoch;
    await s.setPref('media_kept', jsonEncode(k2));
    await Downloads.instance.applyKeep(s);
    expect(b.kept, contains('p'), reason: 'the exception keeps it');
    await s.setKeepDaysOf(g, null);
    expect(b.kept.contains('p'), isFalse, reason: 'back to the group rule: gone');
    // Clear one kind.
    final freed = await Downloads.instance.forgetKinds(s, {'voice'});
    expect(freed, 1 << 20);
    expect(b.kept, isEmpty);
  });

  testWidgets('storage page: ring, untick a kind, clear with undo, freed', (t) async {
    var cleared = false;
    StorageUsage.read = () async => cleared ? const StorageUsage(5 << 20, 0) : const StorageUsage(5 << 20, 3 << 20);
    StorageUsage.clearCache = () async => cleared = true;
    final (s, b) = await demo(t);
    await show(t, s, const StorageUsagePage());
    expect(find.byKey(const Key('storage-ring')), findsOneWidget);
    final before = (t.widget<Text>(find.byKey(const Key('storage-total')))).data;
    // Untick videos: the button and the middle count only the rest.
    await t.tap(find.byKey(const Key('store-kind-video')));
    await t.pumpAndSettle();
    final after = (t.widget<Text>(find.byKey(const Key('storage-total')))).data;
    expect(after, isNot(before));
    final videos = Downloads.instance.keptFiles(s).where((f) => f.kind == 'video').length;
    await t.ensureVisible(find.byKey(const Key('storage-clear')));
    await t.tap(find.byKey(const Key('storage-clear')));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('undo-countdown')), findsOneWidget);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(cleared, isTrue, reason: 'other temporary files went too');
    expect(Downloads.instance.keptFiles(s).length, videos, reason: 'only the videos stay');
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(b.kept, isEmpty);
  });

  testWidgets('storage page: size limit slider and an exception row', (t) async {
    final (s, _) = await demo(t);
    await show(t, s, const StorageUsagePage());
    await t.scrollUntilVisible(find.byKey(const Key('cache-max-slider')), 200, scrollable: find.byType(Scrollable).first);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('cache-max-value')), findsOneWidget);
    expect(t.widget<Text>(find.byKey(const Key('cache-max-value'))).data, '제한 없음');
    expect(s.keepExceptions, ['!r3']);
  });

  // ------------------------------------------------------------ 379
  test('data usage: counted per network and kind, saved, reset', () async {
    final (s, _) = await logged();
    s.network = 'cellular';
    startDataUsage(s);
    DataUsage.note('photo', sent: true, bytes: 1000);
    DataUsage.note('photo', sent: false, bytes: 3000);
    s.network = 'wifi';
    DataUsage.note('video', sent: false, bytes: 5000);
    DataUsage.noteCall(const Duration(minutes: 2), video: false);
    var all = DataUsage.read(s);
    expect(all['cell']!['photo']!.sent, 1000);
    expect(all['cell']!['photo']!.recvN, 1);
    expect(all['wifi']!['video']!.recv, 5000);
    expect(all['wifi']!['calls']!.total, greaterThan(1 << 20));
    await DataUsage.flush(s);
    expect(s.pref('data_use', ''), isNotEmpty);
    all = DataUsage.read(s);
    expect(all['wifi']!['video']!.recv, 5000, reason: 'nothing counted twice');
    expect(DataUsage.since(s), isNotNull);
    await DataUsage.reset(s);
    expect(DataUsage.read(s), isEmpty);
  });

  testWidgets('data usage page: total, open a row, Wi-Fi only', (t) async {
    final (s, _) = await demo(t);
    await show(t, s, const DataUsagePage());
    expect(find.byKey(const Key('usage-ring')), findsOneWidget);
    final all = t.widget<Text>(find.byKey(const Key('usage-total'))).data;
    await t.tap(find.byKey(const Key('usage-photo')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('usage-photo-sent')), findsOneWidget);
    expect(find.text('받음 · 592개'), findsOneWidget);
    await t.tap(find.text('Wi-Fi').first);
    await t.pumpAndSettle();
    expect(t.widget<Text>(find.byKey(const Key('usage-total'))).data, isNot(all));
    expect(find.text('받음 · 402개'), findsOneWidget);
  });

  // ------------------------------------------------------------ 187
  test('archive: unmuted chats come back on news, muted / kept stay', () async {
    final (s, b) = await logged();
    final a = await b.createDirectChat('@ann:test');
    final m = await b.createDirectChat('@max:test');
    final f = await b.createGroup('동호회', ['@k:test']);
    for (final r in [a, m, f]) {
      b.rooms[r]!.add(text('$r-0', 'hi'));
      await b.setChatArchived(r, true);
    }
    await b.setChatMuted(m, true);
    await saveFolders(s, [
      ChatFolder(id: 'x', name: '취미', include: {f}),
    ]);
    await s.refresh(); // first look: nothing moves
    expect(b.archivedChats, containsAll([a, m, f]));
    // My own message doesn't bring it back.
    b.rooms[a]!.add(text('$a-me', 'me', mine: true));
    await s.refresh();
    expect(b.archivedChats, contains(a));
    await s.setOn(archiveKeepFolderKey, true);
    for (final r in [a, m, f]) {
      b.rooms[r]!.add(text('$r-1', 'news'));
    }
    await s.refresh();
    expect(b.archivedChats.contains(a), isFalse, reason: 'alerts on: back to the list');
    expect(b.archivedChats, contains(m), reason: 'muted stays');
    expect(b.archivedChats, contains(f), reason: 'in a folder by hand, switch on');
    // Keep everything.
    await b.setChatArchived(a, true);
    await s.refresh();
    await s.setOn(archiveKeepUnmutedKey, true);
    b.rooms[a]!.add(text('$a-2', 'again'));
    await s.refresh();
    expect(b.archivedChats, contains(a));
  });

  testWidgets('archive: first visit explains, ⋯ opens the settings', (t) async {
    final (s, _) = await demo(t);
    await show(t, s, const ArchivePage());
    expect(find.byKey(const Key('archive-intro')), findsOneWidget);
    await t.tap(find.byKey(const Key('archive-intro-ok')));
    await t.pumpAndSettle();
    expect(s.on('archive_intro_seen'), isTrue);
    await t.tap(find.byKey(const Key('archive-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('archive-menu-settings')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('pref-archive_keep_unmuted')));
    await t.pumpAndSettle();
    expect(s.on(archiveKeepUnmutedKey), isTrue);
  });

  // ------------------------------------------------------------ 211
  test('folder link: round trip, private names, junk refused', () {
    const l = FolderLink(
      name: '거래처 & 팀',
      emoji: '💼',
      items: [
        FolderLinkItem(kind: 'public', code: 'mangwon_bakery'),
        FolderLinkItem(kind: 'private', code: 'h3k8mtq2va7xw9pc4rzn6sd5je', name: '디자인 팀', channel: true),
      ],
    );
    final url = l.url;
    expect(url, contains('/folder#'));
    expect(url, isNot(contains('디자인')), reason: 'names are encoded');
    expect(url, isNot(contains('%')), reason: 'short and readable in a message');
    final back = FolderLink.parse('봐 봐 $url 끝')!;
    expect(back.name, '거래처 & 팀');
    expect(back.emoji, '💼');
    expect(back.items.map((i) => i.kind), ['public', 'private']);
    expect(back.items[1].name, '디자인 팀');
    expect(back.items[1].channel, isTrue);
    expect(FolderLink.parse('https://burumy.app/folder#n=x&c=p.ab'), isNull, reason: 'bad address');
    expect(FolderLink.parse('https://burumy.app/c/mangwon'), isNull);
  });

  testWidgets('folder link: pick, join in one go, folder added', (t) async {
    final (s, b) = await demo(t);
    final msg = b.rooms['!r0']!.firstWhere((m) => m.id == 'st-folder');
    final link = FolderLink.parse(msg.body!)!;
    await show(t, s, FolderJoinPage(link: link));
    expect(find.byKey(const Key('folder-join-name')), findsOneWidget);
    // Leave the market channel out.
    await t.tap(find.byKey(const Key('folder-join-mangwon_market')));
    await t.pumpAndSettle();
    expect(find.text('폴더 추가하고 2개 들어가기'), findsOneWidget);
    await t.tap(find.byKey(const Key('folder-join-go')));
    await t.pumpAndSettle();
    final f = foldersOf(s).firstWhere((x) => x.name == '망원동 생활');
    expect(f.include, containsAll(['!st-bakery', '!seoul_runners']));
    expect(f.include.contains('!st-market'), isFalse);
    expect(b.rooms.containsKey('!st-bakery'), isTrue);
    await t.pump(const Duration(seconds: 5));
  });

  testWidgets('folder share: link holds the chats with links', (t) async {
    final (s, _) = await demo(t);
    final f = foldersOf(s).firstWhere((x) => x.id == 'st-hobby');
    await show(t, s, FolderSharePage(folder: f));
    expect(find.byKey(const Key('folder-share-link')), findsOneWidget);
    final shared = FolderLink.parse(t.widget<Text>(find.descendant(of: find.byKey(const Key('link-text')), matching: find.byType(Text))).data!);
    expect(shared!.items.map((i) => i.code), containsAll(['mangwon_friends', 'film_diary']));
    expect(shared.name, '동네·취미');
  });

  // ------------------------------------------------------------ 178
  testWidgets('account preview: hold, see that account\'s chats, switch', (t) async {
    t.view.physicalSize = const Size(393 * 3, 852 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final main = FakeBackend();
    final work = demoWorkAccount(true);
    await work.login(id: 'work', password: 'x');
    final book = MemoryBookStore()
      ..json = jsonEncode({
        'accounts': [
          {'slot': 0, 'user': '@me:test'},
          {'slot': 1, 'user': '@work:test'},
        ],
        'active': 0,
      });
    final a = Accounts(store: book, openSlot: (slot) async => slot == 0 ? main : work, eraseSlot: (_) async {}, makeState: AppState.new);
    final s = await a.load();
    await s.login('me', 'x');
    await t.pumpWidget(BurumyApp(state: s));
    await t.pumpAndSettle();
    final ctx = t.element(find.byType(CupertinoPageScaffold).first);
    final e = a.others.single;
    // ignore: unawaited_futures
    showAccountPreview(ctx, a, e);
    await t.pumpAndSettle();
    expect(find.byKey(const Key('account-preview')), findsOneWidget);
    expect(find.byKey(const Key('preview-chat-!w1')), findsOneWidget);
    expect(find.byKey(const Key('preview-chat-!w6')), findsNothing, reason: 'hidden chats never show');
    await t.tap(find.byKey(const Key('account-preview-switch')));
    await t.pumpAndSettle();
    expect(a.active, 1);
  });
}
