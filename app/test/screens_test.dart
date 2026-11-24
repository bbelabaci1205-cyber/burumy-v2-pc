// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Screenshots of the main screens at iPhone size, Korean + English, green +
// blue, light + dark. Run with --update-goldens to refresh the pictures.
import 'dart:async';

import 'dart:io';

import 'package:burumy/brand/brand.dart';
import 'package:burumy/core/app_state.dart';
import 'package:burumy/core/backend.dart';
import 'package:burumy/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:burumy/ui/chat_list_page.dart';

import 'package:burumy/core/call_media.dart';
import 'package:burumy/core/call_session.dart';

import 'package:burumy/demo/sample.dart';

import 'fake_backend.dart';
import 'fake_call_media.dart';

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

FakeBackend sample(bool ko) => demoSample(ko, File('test/assets/sample_photo.png').readAsBytesSync());

void main() {
  setUpAll(() async {
    await loadFont('Pretendard', ['assets/fonts/Pretendard-Regular.otf', 'assets/fonts/Pretendard-Medium.otf', 'assets/fonts/Pretendard-SemiBold.otf']);
    final home = Platform.environment['HOME'];
    await loadFont('packages/cupertino_icons/CupertinoIcons', ['$home/.pub-cache/hosted/pub.dev/cupertino_icons-1.0.9/assets/CupertinoIcons.ttf']);
    await loadFont('Noto Color Emoji', ['/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf']);
    await loadFont('CupertinoSystemText', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('CupertinoSystemDisplay', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('.SF Pro Text', ['assets/fonts/Pretendard-Regular.otf']);
    await loadFont('.SF Pro Display', ['assets/fonts/Pretendard-Medium.otf']);
  });

  for (final (lang, f, dark) in [
    ('ko', BrandFamily.green, false),
    ('ko', BrandFamily.green, true),
    ('ko', BrandFamily.blue, false),
    ('ko', BrandFamily.blue, true),
    ('en', BrandFamily.green, false),
    ('en', BrandFamily.blue, true),
  ]) {
    {
      {
        final tag = '${lang}_${f.name}_${dark ? 'dark' : 'light'}';
        testWidgets('screens $tag', (t) async {
          t.view.physicalSize = const Size(393 * 2, 852 * 2);
          t.view.devicePixelRatio = 2;
          t.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
          addTearDown(t.view.reset);
          addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
          final ko = lang == 'ko';
          final state = AppState(sample(ko), family: f, locale: Locale(lang));
          await t.pumpWidget(BurumyApp(state: state));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_1_signup.png'));

          await state.backend.login(id: 'me', password: 'x');
          await state.refresh();
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_2_chats.png'));
          await t.tap(find.byKey(const Key('archive-row')));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_13_archive.png'));
          Navigator.of(t.element(find.byType(ArchivePage)), rootNavigator: true).pop();
          await t.pumpAndSettle();

          await t.tap(find.text(ko ? '김민지' : 'Mina Kim').last);
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
          await t.pumpAndSettle();
          for (final e in find.byType(Image).evaluate()) {
            final img = (e.widget as Image).image;
            await t.runAsync(() => precacheImage(img, e));
          }
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_3_chat.png'));
          await t.tap(find.byKey(const Key('sticker-button')));
          await t.pumpAndSettle();
          for (final e in find.byType(Image).evaluate()) {
            final img = (e.widget as Image).image;
            await t.runAsync(() => precacheImage(img, e));
          }
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_11_stickers.png'));
          await t.tap(find.byKey(const Key('sticker-button')));
          await t.pumpAndSettle();

          await t.tap(find.byKey(const Key('chat-title')));
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('info-search')));
          await t.pumpAndSettle();
          await t.enterText(find.byKey(const Key('msg-search')), ko ? '사진' : 'photo');
          await t.testTextInput.receiveAction(TextInputAction.search);
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_14_search.png'));
          await t.tap(find.byKey(const Key('search-cancel')));
          await t.pumpAndSettle();

          Navigator.of(t.element(find.byType(CupertinoTextField).first)).pop();
          await t.pumpAndSettle();
          await t.tap(find.text(ko ? '설정' : 'Settings').last);
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_4_settings.png'));
          for (final (row, name) in const [
            ('privacy-row', 'privacy'),
            ('look-row', 'appearance'),
            ('notify-row', 'notifications'),
            ('chats-row', 'chat_settings'),
          ]) {
            unawaited(Scrollable.ensureVisible(t.element(find.byKey(Key(row))), alignment: 0.5));
            await t.pumpAndSettle();
            await t.tap(find.byKey(Key(row)));
            await t.pumpAndSettle();
            await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_4_$name.png'));
            await t.tap(find.byKey(const Key('back')).last);
            await t.pumpAndSettle();
          }
          await t.tap(find.text(ko ? '연락처' : 'Contacts').last);
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_5_contacts.png'));

          await t.tap(find.text(ko ? '대화' : 'Chats').last);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('new-chat')));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_6_new.png'));
          await t.tap(find.text(ko ? '취소' : 'Cancel'));
          await t.pumpAndSettle();

          await t.tap(find.text(ko ? '디자인 팀' : 'Design Team'));
          await t.pumpAndSettle();
          await t.ensureVisible(find.text(ko ? '좋아요, 3쪽 표 확인했어요' : 'Great, checked the table on page 3').last);
          await t.pumpAndSettle();
          await t.longPress(find.text(ko ? '좋아요, 3쪽 표 확인했어요' : 'Great, checked the table on page 3').last);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('menu-reply')));
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
          await t.pumpAndSettle();
          for (final e in find.byType(Image).evaluate()) {
            final img = (e.widget as Image).image;
            await t.runAsync(() => precacheImage(img, e));
          }
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_7_group.png'));
          await t.dragUntilVisible(find.byKey(const Key('poll')), find.byType(ListView).last, const Offset(0, -150));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_15_poll.png'));
          await t.tap(find.byKey(const Key('chat-title')));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_12_info.png'));
          Navigator.of(t.element(find.byKey(const Key('info-mute')))).pop();
          await t.pumpAndSettle();
          Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
          await t.pumpAndSettle();

          await t.tap(find.text(ko ? '부루미 소식' : 'Burumy News'));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_8_channel.png'));
          Navigator.of(t.element(find.byKey(const Key('read-only')))).pop();
          await t.pumpAndSettle();

          // App lock settings (after the normal password) and the lock screen.
          final fb = state.backend as FakeBackend;
          fb.normalPw = 'normal123';
          fb.hidePw = 'hide12345';
          fb.hideList = ['!r0', '!r2'];
          await t.tap(find.text(ko ? '설정' : 'Settings').last);
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('privacy-row')));
          await t.pumpAndSettle();
          await t.pumpAndSettle();
          await t.tap(find.byKey(const Key('app-lock')));
          await t.pumpAndSettle();
          await t.enterText(find.byKey(const Key('lock-gate')), 'normal123');
          await t.tap(find.byKey(const Key('lock-gate-ok')));
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_9_applock.png'));
          await state.checkLock();
          await t.pumpAndSettle();
          await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${tag}_10_lock.png'));
          state.stopLive();
        });
      }
    }
  }

  for (final lang in ['ko', 'en']) {
    testWidgets('call screens $lang', (t) async {
      t.view.physicalSize = const Size(393 * 2, 852 * 2);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      CallMedia.make = FakeCallMedia.new;
      CallSession.active = null;
      CallSession.waiting.value = null;
      final ko = lang == 'ko';
      final fake = sample(ko);
      await fake.login(id: 'me', password: 'x');
      final state = AppState(fake, locale: Locale(lang));
      await state.refresh();
      await t.pumpWidget(BurumyApp(state: state));
      await t.pumpAndSettle();
      fake.receiveCall('!r0', '@mina:test', video: true);
      await state.refresh();
      await t.pump();
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${lang}_16_call_in.png'));
      await t.tap(find.byKey(const Key('call-decline')));
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();

      await t.tap(find.text(ko ? '김민지' : 'Mina Kim').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('chat-title')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('info-voice-call')));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      FakeCallMedia.last!.otherJoins();
      for (var i = 0; i < 75; i++) {
        await t.pump(const Duration(seconds: 1));
      }
      await t.tap(find.byKey(const Key('call-mute')));
      await t.pump(const Duration(milliseconds: 100));
      await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${lang}_17_call_live.png'));
      fake.receiveCall('!r2', '@seo:test');
      await state.refresh();
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(milliseconds: 100));
      await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${lang}_21_call_waiting.png'));
      await t.tap(find.byKey(const Key('waiting-decline')));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byKey(const Key('call-end')));
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      // Back from the info page (the call starts there), then the chat.
      await t.tap(find.byKey(const Key('back')).last);
      await t.pumpAndSettle();
      Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
      await t.pumpAndSettle();
      await t.tap(find.text(ko ? '설정' : 'Settings').last);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const Key('notify-row')), 150, scrollable: find.byType(Scrollable).last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('notify-row')));
      await t.pumpAndSettle();
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const Key('call-waiting-tile')), 150, scrollable: find.byType(Scrollable).last);
      await t.ensureVisible(find.byKey(const Key('call-waiting-tile')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('call-waiting-tile')));
      await t.pumpAndSettle();
      await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/${lang}_22_call_waiting_setting.png'));
      await t.tap(find.byKey(const Key('call-waiting-missed')));
      await t.pumpAndSettle();
      expect(fake.waitMode, 'missed');
      state.stopLive();
    });
  }

  testWidgets('1:1 info + lock warning ko', (t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final fake = sample(true);
    await fake.login(id: 'me', password: 'x');
    final state = AppState(fake, locale: const Locale('ko'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await t.tap(find.text('김민지').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-title')));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_18_info_dm.png'));
    Navigator.of(t.element(find.byKey(const Key('info-mute')))).pop();
    await t.pumpAndSettle();
    Navigator.of(t.element(find.byKey(const Key('composer')))).pop();
    await t.pumpAndSettle();
    fake.normalPw = 'normal123';
    fake.wipeN = 5;
    await state.checkLock();
    await t.pumpAndSettle();
    for (var i = 0; i < 2; i++) {
      await t.enterText(find.byKey(const Key('lock-password')), 'guess$i-xx');
      await t.tap(find.byKey(const Key('lock-open')));
      await t.pumpAndSettle();
    }
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_19_lock_warning.png'));
    state.stopLive();
  });

  testWidgets('group invitations in chat list ko', (t) async {
    t.view.physicalSize = const Size(393 * 2, 852 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final fake = sample(true);
    await fake.login(id: 'me', password: 'x');
    fake.invites.addAll(const [
      Invite(roomId: '!g1', name: '주말 등산 모임', inviter: '@jun:test', direct: false),
      Invite(roomId: '!c1', name: '부루미 소식', inviter: '@burumy:test', direct: false),
    ]);
    final state = AppState(fake, locale: const Locale('ko'));
    await state.refresh();
    await t.pumpWidget(BurumyApp(state: state));
    await t.pumpAndSettle();
    await expectLater(find.byType(CupertinoApp), matchesGoldenFile('shots/ko_20_invites.png'));
    state.stopLive();
  });
}
