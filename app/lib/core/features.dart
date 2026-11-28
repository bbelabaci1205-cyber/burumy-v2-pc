// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Switches for features whose place is kept but which are off for now.
// Turning one on must not need screens or data to be rebuilt.

class Features {
  const Features._();

  /// Business accounts: a company owns its members' accounts and has an
  /// admin console. Engine side: engine/src/org.rs (BUSINESS_ENABLED).
  /// Eric 2026-11-23: space only, free at launch, paid tier later.
  static const business = false;

  /// Cloud AI: off. On-device AI is the rule (nothing leaves the phone).
  /// If ever switched on, it works only in chats where the user turned it
  /// on themselves, and the chat shows that it is on. Eric 2026-11-23.
  static const cloudAi = false;

  /// Friend feed (photos / words for 1:1 friends only, no ads, end-to-end
  /// encrypted, likes seen only by the poster). Built and hidden: Eric
  /// 2026-11-24 "만들고 빼고 시기를 보자". A build can turn it on with
  /// --dart-define=BURUMY_FEED=true; tests set it directly.
  static bool feed = const bool.fromEnvironment('BURUMY_FEED');

  /// 가입 심사 도우미 (join helper + join questions with quiz). Built,
  /// off in real builds until Eric picks the time (2026-11-27 "지금
  /// 만들기 (꺼진 상태로)"). --dart-define=BURUMY_JOIN_GATE=true turns it
  /// on; the look-only web demo shows it.
  static bool joinGate = const bool.fromEnvironment('BURUMY_JOIN_GATE');

  /// 대화 안전 묶음 (Telegram tips 557, 478, 514, 418, 380; Eric 2026-11-27
  /// "다해죠"): owner-only 공유 비활성화 with intro sheet / notice / iPhone
  /// screenshot shield, 2-step reports, the richer first-message card,
  /// 한 번만 듣기 voice, media permissions per kind + exceptions. Built and
  /// off in real builds until its release drop; the web demo shows it.
  /// --dart-define=BURUMY_CHAT_SAFETY=true turns it on.
  static bool chatSafety = const bool.fromEnvironment('BURUMY_CHAT_SAFETY');

  /// 로그인·기기 안전 (tips 398, 78+311, 247, 308, 343, 356): new-login
  /// card, device sheet + idle logout + QR PC link, stranger 보관, voice
  /// rule, calls / days wiped for both. Built 2026-11-27, off in real
  /// builds until its release slot; --dart-define=BURUMY_LOGIN_SAFETY=true
  /// turns it on; the look-only web demo shows it.
  static bool loginSafety = const bool.fromEnvironment('BURUMY_LOGIN_SAFETY');

  /// 빠른 다듬기 묶음 D1 (Telegram tips 450 · 502 · 477 · 546 · 509, Eric
  /// 2026-11-27 "고를 것 없이 다 해 줘"): built, off in real builds until
  /// its release drop (staged release plan). The look-only web demo shows
  /// it. --dart-define=BURUMY_TIPS_D1=true turns it on.
  static bool tipsD1 = const bool.fromEnvironment('BURUMY_TIPS_D1');

  /// 전체 검색 묶음 (Telegram tips 500 · 189 · 248 · 533 · 444 · 454 ·
  /// 484 · 459, Eric 2026-11-27 "다해죠"): one search screen with tabs
  /// 대화 · 채널 · 글 · 미디어 · 링크 · 파일 · 음악 · 음성, tappable
  /// #해시태그 in messages and story captions. Built, off in real builds
  /// until its release drop; the web demo shows it.
  /// --dart-define=BURUMY_SEARCH=true turns it on.
  static bool search = const bool.fromEnvironment('BURUMY_SEARCH');

  /// 답장·멘션 묶음 (Telegram tips 455 접히는 인용문 · 399 부분 인용과 다른
  /// 대화에서 답장 · 249/320 안 본 멘션·반응 배지와 바로 가기 · 276 나만
  /// 고정; Eric 2026-11-27 "다 해 줘", "시간이 걸려도 최고로"): built, off in
  /// real builds until its release drop. The look-only web demo shows it.
  /// --dart-define=BURUMY_TIPS_REPLY=true turns it on.
  static bool tipsReply = const bool.fromEnvironment('BURUMY_TIPS_REPLY');

  /// 공유·링크 묶음 (Telegram tips 350 · 182 · 503 · 438 · 253; Eric
  /// 2026-11-27 "다해죠", "시간이 걸려도 최고로"): share from other apps
  /// into Burumy (several chats, a word, progress), QR reading in the
  /// camera, 대화 링크 with a ready message, extra invite links with time /
  /// people limits our server keeps. Built, off in real builds until its
  /// release drop; the web demo shows it.
  /// --dart-define=BURUMY_SHARE_LINKS=true turns it on.
  static bool shareLinks = const bool.fromEnvironment('BURUMY_SHARE_LINKS');

  /// 링크·서식·보내기 묶음 #4 (Telegram tips 400+401 링크 미리보기 조절 +
  /// 답장·링크 탭, 411 코드 블록, 559 날짜 표시, 217 예약 보내기 다듬기,
  /// 289 말풍선 날아드는 움직임; Eric 2026-11-27 "다 해 줘", "시간이 걸려도
  /// 최고로"): built, off in real builds until its release drop. The
  /// look-only web demo shows it. --dart-define=BURUMY_TIPS_LINK=true.
  static bool tipsLink = const bool.fromEnvironment('BURUMY_TIPS_LINK');

  /// AI·번역 묶음 #25 (Telegram tips 554 긴 글 AI 요약, 475 읽기 모드,
  /// 361 동그란 영상 글로 보기; 339 · 315 · 377 were already in): built,
  /// off in real builds until its release drop. The look-only web demo
  /// shows it. --dart-define=BURUMY_TIPS_AI_READ=true turns it on.
  static bool tipsAiRead = const bool.fromEnvironment('BURUMY_TIPS_AI_READ');

  /// 오디오 묶음 #26 (Telegram tips 108 음악 재생 목록 + 미니 플레이어, 199
  /// 속도 고르기 · 이어 듣기): built, off in real builds until its release
  /// drop. The web demo shows it. --dart-define=BURUMY_TIPS_AUDIO=true.
  static bool tipsAudio = const bool.fromEnvironment('BURUMY_TIPS_AUDIO');

  /// 효과 묶음 #30 + 이모지 팩·GIF #31 (Telegram tips 451 메시지 효과 B ·
  /// 219 · 297 · 355 큰 이모지 효과 · 218 주사위 · 354 직접 만든 움직이는
  /// 이모지 · 430 그룹 이모지 묶음 · 558 내 GIF; Eric 2026-11-27 "1~5번 지금
  /// 시작"): built, off in real builds until its release drop. The look-only
  /// web demo shows it. --dart-define=BURUMY_FUN_FX=true turns it on.
  static bool funFx = const bool.fromEnvironment('BURUMY_FUN_FX');

  /// 다른 앱 대화 가져오기 (Telegram tips 244 + 254 + Telegram exports;
  /// Eric 2026-11-27 "같이 해 줘", "시간이 걸려도 최고로"): KakaoTalk,
  /// WhatsApp and Telegram exports read on the phone, sent as one
  /// end-to-end encrypted import card. Built, off in real builds until its
  /// release drop (launch day per the release calendar); the web demo shows
  /// it. --dart-define=BURUMY_CHAT_IMPORT=true turns it on.
  static bool chatImport = const bool.fromEnvironment('BURUMY_CHAT_IMPORT');

  /// 사진 보내기 묶음 (Telegram tips 75 + 323 앨범 미리보기·순서 바꾸기,
  /// 529 표준/HD, 273 대화 안 핀치 확대, 369 한 장씩 가리기, 56 동영상
  /// 자르기·회전; Eric 2026-11-27 "다 해 줘"): built, off in real builds
  /// until its release drop (then photos go at 표준 size unless HD is on).
  /// The look-only web demo shows it. --dart-define=BURUMY_PHOTO_SEND=true.
  static bool photoSend = const bool.fromEnvironment('BURUMY_PHOTO_SEND');

  /// 프로필 묶음 #12 (Telegram tips 195 큰 사진 머리·사진 넘기기, 445 남에게
  /// 보이는 내 프로필, 58 예전 사진, 374 공개 사진, 373 사진 제안, 376+351
  /// 이모지 프로필 사진; Eric 2026-11-27 "다같이 시작"): built, off in real
  /// builds until its release drop. The look-only web demo shows it.
  /// --dart-define=BURUMY_PROFILE=true turns it on.
  static bool profile = const bool.fromEnvironment('BURUMY_PROFILE');

  /// 이모지 찾기·반응 + 스티커 묶음 (Telegram tip batches #19 + #20: 294,
  /// 366, 378, 221, 341, 358, 538, 441, 79, 496, 359; Eric 2026-11-27
  /// approved every tip card, 538 = "B. 묶음+공유만"): emoji search and
  /// shortcuts, sticker suggestions, the big reaction panel (3 per person),
  /// sticker sets with encrypted sharing, 둘러보기, emoji status. Built,
  /// off in real builds until its release drop; the web demo shows it.
  /// --dart-define=BURUMY_EMOJI_STICKERS=true.
  static bool emojiStickers = const bool.fromEnvironment('BURUMY_EMOJI_STICKERS');

  /// 채널 묶음 #15 (Telegram tips 521 빠른 전달, 292 다음 안 읽은 채널,
  /// 472 슈퍼 채널, 310 내 채널 이름으로 쓰기, 526 채널 관리자에게 메시지;
  /// Eric 2026-11-27 approved all tip cards): built, off in real builds
  /// until its release drop. The look-only web demo shows it.
  /// --dart-define=BURUMY_CHANNEL_TIPS=true turns it on.
  static bool channelTips = const bool.fromEnvironment('BURUMY_CHANNEL_TIPS');

  /// 우리식 기능 묶음 (4대 메신저 보드 '우리식으로' 8개; Eric 2026-11-28
  /// "5번 빼고 해 줘"): 캡처 알림 (only where capture can't be blocked),
  /// 제일 친한 친구 ❤ (counted on this phone), 1년 전 오늘 (saved photos,
  /// picked on this phone), 당겨서 카메라, AI 친구 (on-phone AI only),
  /// 스티커 가게, 친구 피드 '아는 친구 댓글만', 통합 검색 (기능 · 설정 ·
  /// 채널 글 in one place). Built, off in real builds until its release
  /// drop; the web demo shows it. --dart-define=BURUMY_OWN_WAY=true.
  static bool ownWay = const bool.fromEnvironment('BURUMY_OWN_WAY');
}

/// Where an AI job may run. Everything is [onDevice] while
/// [Features.cloudAi] is off. Plan (Eric picked option B, 2026-11-23):
/// phase 1 after launch, phase 2 when Plus opens.
enum AiPlace { onDevice, cloud }

/// Cloud only when: the app switch is on, the user turned it on for this
/// chat, and the chat's owner has not blocked cloud AI for the chat.
AiPlace aiPlaceFor({required bool chatAllowsCloud, bool ownerBlocksCloud = false}) =>
    Features.cloudAi && chatAllowsCloud && !ownerBlocksCloud ? AiPlace.cloud : AiPlace.onDevice;
