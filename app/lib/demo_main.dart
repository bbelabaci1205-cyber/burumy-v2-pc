// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Look-only demo: the real app screens with example chats and no server.
// Build with -t lib/demo_main.dart (web preview, demo APK). Nothing leaves
// the device. Opens on the example chats; after logging out, any ID and
// password sign in again.
import 'dart:convert';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'core/ai_local.dart';
import 'core/licenses.dart';
import 'core/app_state.dart';
import 'core/call_media.dart';
import 'demo/demo_call_media.dart';
import 'demo/demo_ai.dart';
import 'core/desktop_update.dart';
import 'core/features.dart';
import 'demo/gate_sample.dart';
import 'demo/community_sample.dart';
import 'demo/guard_sample.dart';
import 'demo/live_sample.dart';
import 'demo/fun_sample.dart';
import 'demo/profile_sample.dart';
import 'demo/fx_sample.dart';
import 'demo/photo_sample.dart';
import 'demo/rival_sample.dart';
import 'demo/own_way_sample.dart';
import 'demo/translate_sample.dart';
import 'core/translate.dart';
import 'demo/more_sample.dart';
import 'demo/sample.dart';
import 'demo/sticker_sample.dart';
import 'demo/storage_sample.dart';
import 'demo/link_sample.dart';
import 'demo/topics_sample.dart';
import 'demo/suggest_sample.dart';
import 'demo/channel_tips_sample.dart';
import 'demo/audio_reader_sample.dart';
import 'demo/trust_sample.dart';
import 'demo/safety_sample.dart';
import 'demo/tips_d1_sample.dart';
import 'core/accounts.dart';
import 'demo/demo_backend.dart';
import 'demo/search_sample.dart';
import 'demo/share_sample.dart';
import 'demo/video_sample.dart';
import 'demo/view_sample.dart';
import 'demo/list_sample.dart';
import 'demo/reply_sample.dart';
import 'demo/group16_sample.dart';
import 'demo/login_safety_sample.dart';
import 'demo/import_sample.dart';
import 'demo/story_keep_sample.dart';
import 'demo/look_sample.dart';
import 'ui/look_studio.dart' show RoomLookLevels;
import 'demo/emoji_sticker_sample.dart';
import 'main.dart' show AccountsHost;
import 'ui/app_icon.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final ko = PlatformDispatcher.instance.locale.languageCode != 'en';
  final photo = (await rootBundle.load('assets/demo/photo.png')).buffer.asUint8List();
  final b = demoSample(ko, photo);
  addTrustSample(b, ko, photo);
  addMoreChats(b, ko, photo);
  addGuardSample(b, ko, photo);
  // Join helper: off in real builds, shown in the look-only demo.
  Features.joinGate = true;
  Features.chatSafety = true;
  Features.tipsD1 = true;
  Features.search = true;
  Features.tipsReply = true;
  Features.shareLinks = true;
  Features.tipsLink = true;
  Features.photoSend = true;
  Features.channelTips = true;
  addGateSample(b, ko);
  // 로그인·기기 안전: off in real builds, shown in the look-only demo.
  Features.loginSafety = true;
  // 앱 아이콘 picker: Android only in real builds; shown in the demo to look at.
  AppIconPicker.preview = true;
  addLoginSafetySample(b);
  addTipsD1Sample(b, ko, video: (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List());
  final still = (await rootBundle.load('assets/demo/live_still.jpg')).buffer.asUint8List();
  addLiveSample(b, ko, still, (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List());
  addListSample(b, photo, still);
  // 그룹 사진: the team group shows a photo its admins set.
  b.roomPhotos['!r1'] = still;
  b.roomPhotos['!seoul_runners'] = photo;
  addCommunitySample(b, ko);
  addVideoSample(b, ko, (await rootBundle.load('assets/demo/clip.mp4')).buffer.asUint8List());
  // Pretend gallery + a chat with an album, a covered photo and a GIF.
  await addPhotoSample(
    b,
    ko,
    (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List(),
    longClip: (await rootBundle.load('assets/demo/clip.mp4')).buffer.asUint8List(),
  );
  // Fun batch: text in a photo, phone number, birthday, video story, round video, hello card.
  await addFunSample(b, ko, (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List());
  // 프로필 묶음 #12: off in real builds, shown in the look-only demo.
  Features.profile = true;
  await addProfileSample(b, photo, still);
  // 4-messenger batch: voice to text, …
  addRivalSample(b, ko, photo: photo);
  // 우리식 기능 묶음 (캡처 알림, 제일 친한 친구 ❤, 1년 전 오늘, 피드 댓글):
  // off in real builds, shown in the look-only demo. The friend feed is
  // shown here too so its comments can be looked at.
  Features.ownWay = true;
  // The web preview has no phone AI: fixed example answers stand in. Set
  // before the first refresh (우리식 asks the AI status after it, and the
  // answer is kept).
  LocalAi.engine = DemoAi();
  await LocalAi.status();
  Features.feed = true;
  addOwnWaySample(b, ko, photo: photo, still: still);
  // 다른 앱 대화 가져오기: off in real builds, shown in the look-only demo.
  Features.chatImport = true;
  // 번역 + character emoji / reactions (2026-11-27).
  addTranslateSample(b, ko);
  Translate.engine = DemoTranslate();
  // 답장·멘션: folded quote, partial quote, @ / ♥ marks, pin for me only.
  addReplySample(b, ko);
  // Story stickers (tip 467): weather, place, link.
  addStickerSample(b, ko, photo);
  // 스토리 남기기·꾸미기 (tips 393 · 392 · 468 · 534 · 525 · 395 · 408 · 414 · 428).
  await addStoryKeepSample(
    b,
    ko,
    photo,
    still: still,
    clip: (await rootBundle.load('assets/demo/clip.mp4')).buffer.asUint8List(),
    round: (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List(),
  );
  // 대화 안전 묶음 (557, 418, 380).
  addSafetySample(b, ko: ko);
  // 전체 검색 + 해시태그 (tips 500 · 189 · 248 · 533 · 444 · 454 · 484 · 459).
  addSearchSample(b, ko, photo);
  // 공유·링크 (tips 253 · 438 · 503 · 350 · 182).
  addShareSample(b, ko, photo: photo);
  // 링크·서식·보내기 (tips 400 · 401 · 411 · 559 · 217 · 289).
  addLinkSample(b, ko, photo);
  // 보기·파일 + 영상 가볍게 (tips 473 · 334 · 103 · 204 · 352 · 479 · 480 · 114 · 322 · 466).
  addViewSample(
    b,
    ko,
    pdf: (await rootBundle.load('assets/demo/book.pdf')).buffer.asUint8List(),
    clip: (await rootBundle.load('assets/demo/clip.mp4')).buffer.asUint8List(),
    light: (await rootBundle.load('assets/demo/clip_light.mp4')).buffer.asUint8List(),
  );
  // 그룹 묶음 #16 (tips 94 · 556 · 365 · 384): anonymous admin, member
  // tags, aggressive anti-spam with dust, who read my message.
  addGroup16Sample(b, ko);
  // 주제 (tip 527): a club group with encrypted topics.
  addTopicsSample(b, ko);
  // 채널에 글 제안 (tip 531, no money).
  await addSuggestSample(b, ko, photo: still);
  // 이모지 찾기·반응 + 스티커 묶음 (tip batches #19 + #20).
  Features.emojiStickers = true;
  await addEmojiStickerSample(b, ko);
  // 채널 묶음 #15 (tips 521 · 292 · 472 · 310 · 526).
  addChannelTipsSample(b, ko);
  // 번역·읽기 모드·오디오 (tips 554 · 475 · 199 · 108).
  Features.tipsAiRead = true;
  Features.tipsAudio = true;
  addAudioReaderSample(b, ko, round: (await rootBundle.load('assets/demo/live.mp4')).buffer.asUint8List());
  // 테마·배경·꾸미기 (tips 229 · 305 · 181 · 281 · 284 · 387 · 410 · 173 · 226 ·
  // 402 · 409 · 412 · 429). Every 꾸미기 part is open in the preview (real
  // builds open them by community level).
  addLookSample(b, ko);
  RoomLookLevels.on = false;
  // 효과 · 이모지 팩 · GIF (tips 451 · 219 · 297 · 355 · 218 · 354 · 430 · 558).
  Features.funFx = true;
  addFxSample(b, ko);
  await addCxSample(b, ko);
  await addGifSample(b, ko);
  // 저장 공간·데이터 + 목록·알림 설정 (tip batches #22 · #23, 2026-11-27).
  addStorageSample(
    b,
    ko,
    tone: (await rootBundle.load('assets/sounds/burumy_call_ring.wav')).buffer.asUint8List(),
    savedTone: (await rootBundle.load('assets/sounds/burumy_bell.wav')).buffer.asUint8List(),
  );
  // Several accounts work in the preview too: a work account with chats
  // (hold it in Settings to peek, tip 178); a third one starts empty.
  final work = demoWorkAccount(ko);
  await work.login(id: 'burumy_work', password: 'demo');
  final book = MemoryBookStore()
    ..json = jsonEncode({
      'accounts': [
        {'slot': 0, 'user': '@me:test'},
        {'slot': 1, 'user': '@burumy_work:test'},
      ],
      'active': 0,
    });
  final accounts = Accounts(
    store: book,
    openSlot: (slot) async => slot == 0 ? b : (slot == 1 ? work : FakeBackend(lock: b.lk)),
    eraseSlot: (_) async {},
    makeState: AppState.new,
    onShown: (s) async {
      if (s.backend.loggedIn) await s.afterLogin();
    },
  );
  final state = await accounts.load();
  await state.login('me', 'demo');
  // The sample import goes in as me (after logging in).
  await addImportSample(b, ko, photo);
  // 사진 제안 card (tip 373) as the newest message in Mina's chat.
  await addProfileSuggestCard(b);
  wireGroup16Spam(b, state, ko);
  // No call server in the preview: calls ring, nobody answers, and the
  // 메시지 남기기 buttons show (엄마 doesn't pick up after 6 seconds).
  CallMedia.make = DemoCallMedia.new;
  registerExtraLicenses();
  runApp(AccountsHost(accounts: accounts));
  unawaited(checkDesktopUpdate());
}
