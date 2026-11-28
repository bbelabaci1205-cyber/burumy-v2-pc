// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Size, type, spacing and colour rules from the v2 rulebook ch. 3-4
// (owner's choice "A": Telegram-size type, iOS-first look). Screens use these
// names only, never raw numbers.
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/widgets.dart';

import '../brand/brand.dart';

class TypeStyle {
  const TypeStyle(this.size, this.lineHeight, this.weight);
  final double size;
  final double lineHeight;
  final FontWeight weight;

  TextStyle get style => TextStyle(
    fontFamily: Tokens.fontFor(size),
    fontFamilyFallback: Tokens.emojiFallback,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: Tokens.weight(weight),
  );
}

class Tokens {
  const Tokens._();

  /// Phone apps use the phone's own font, like Telegram (Eric 2026-11-26
  /// "웹앱은 기존 것, 앱은 다르게"): iPhone / Mac = SF Pro + Apple SD Gothic
  /// Neo, Android = Roboto + the phone's Korean font. Free: they are already
  /// on the device. Web and Windows keep Pretendard (Apple's fonts may not be
  /// shipped). Switched on by the real app's main(); tests and the web demo
  /// stay on Pretendard.
  static bool deviceFont = false;
  static String get font {
    if (!deviceFont || kIsWeb) return 'Pretendard';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS || TargetPlatform.macOS => 'CupertinoSystemText',
      TargetPlatform.android => 'Roboto',
      _ => 'Pretendard',
    };
  }

  /// iPhone switches to its "Display" cut from 20pt up, like iOS itself.
  static String fontFor(double size) => font == 'CupertinoSystemText' && size >= 20 ? 'CupertinoSystemDisplay' : font;

  /// Weights per device, like Telegram (Eric 2026-11-26 "다른 조건도 텔레그램
  /// 따라"): Telegram Android draws every bold-ish text (names, titles,
  /// buttons) in Roboto Medium, so 600/700 become 500 there. iPhone, Mac,
  /// Windows and web keep the weight as written.
  static FontWeight weight(FontWeight w) => deviceFont && !kIsWeb && defaultTargetPlatform == TargetPlatform.android && w.value > 500 ? FontWeight.w500 : w;

  /// Semibold for names, titles and buttons (Medium on Android).
  static FontWeight get semi => weight(FontWeight.w600);

  /// The phone's own colour emoji (iOS, Android).
  static const emojiFallback = ['Apple Color Emoji', 'Noto Color Emoji'];

  // Type scale. Weight 700 (bold) only for the settings header card title
  // (iOS 27; Eric 2026-11-25: "700은 보통 땐 안 쓸 거야").
  static const largeTitle = TypeStyle(34, 41, FontWeight.w600);
  static const screenTitle = TypeStyle(28, 34, FontWeight.w600);
  static const cardTitle = TypeStyle(22, 28, FontWeight.w500);

  /// Title in the card at the top of a settings page (iOS 27 Settings: 22 bold).
  static const headerTitle = TypeStyle(22, 28, FontWeight.w700);
  static const body = TypeStyle(17, 22, FontWeight.w400);
  static const preview = TypeStyle(15, 20, FontWeight.w400);
  static const caption = TypeStyle(13, 18, FontWeight.w400);
  static const bubbleMeta = TypeStyle(11, 13, FontWeight.w400);

  /// Chat header capsule: name and the line under it (Telegram iOS sizes,
  /// measured from Eric's screenshots 2026-11-25).
  static const navTitle = TypeStyle(15, 18, FontWeight.w600);
  static const navSubtitle = TypeStyle(12, 15, FontWeight.w400);
  static const tabLabel = TypeStyle(10, 12, FontWeight.w500);

  /// Chat list row: name and date (Telegram iOS: Medium 16, Regular 14;
  /// measured on Eric's screenshots 2026-11-26, names were 17 before).
  static const listName = TypeStyle(16, 21, FontWeight.w500);
  static const listDate = TypeStyle(14, 18, FontWeight.w400);
  static const all = [largeTitle, screenTitle, cardTitle, headerTitle, body, preview, caption, bubbleMeta, navTitle, navSubtitle, tabLabel, listName, listDate];

  // Spacing and corners.
  static const space = [4.0, 8.0, 12.0, 16.0, 24.0, 32.0];
  static const radius = [6.0, 10.0, 16.0, 26.0];
  static const capsule = 999.0;

  // Gaps between texts.
  static const nameToSub = 2.0, groupTitleToCard = 6.0, cardToFooter = 8.0;

  // Bars and sheets.
  static const tabBar = 62.0, tabIcon = 26.0;
  static const sheetHeader = 56.0, closeButton = 44.0, closeIcon = 22.0;

  /// Chat header capsule: at least this wide, and it may grow until this
  /// gap from the round buttons on each side (Telegram).
  static const titlePillMin = 178.0, titlePillGap = 13.0;

  /// Saved messages side list: how much of the chat stays visible on the
  /// left (Telegram).
  static const sideStrip = 76.0;

  /// 주제 (group topics, tip 527), Telegram measured from its iOS frames:
  /// side rail 72pt wide with 28pt topic icons and 10pt names; the top bar
  /// is as tall as the folder tabs; a topic line in 모두 is a 24pt capsule.
  static const topicRail = 72.0, topicIcon = 28.0, topicIconSmall = 18.0, topicLine = 24.0, topicBadge = 16.0;

  /// Chat header sits 3pt up in its 60pt bar (Telegram: centre 27pt under
  /// the status bar); other pages follow iOS 27 (22pt).
  static const chatBarLift = 3.0;

  /// Chat list = Telegram measured on Eric's iPhone (2026-11-26): buttons
  /// centre 27pt under the status bar (same lift as the chat header), 21pt
  /// from the search capsule to the first avatar (search bottom pad 13 +
  /// 8 inside the row).
  static const listBarLift = 3.0;
  static const listSearchBelow = 13.0;

  /// Side menu: icons, words and counts sit 20pt in from the card edge so the
  /// rows don't look empty in the middle (Eric 2026-11-26).
  static const menuInset = 20.0;

  /// Folder tabs under the list search (Telegram measured on Eric's iPhone
  /// 2026-11-26): 40pt glass capsule, 4pt inner gap, 10pt under the search,
  /// 3pt + the row's own 8pt down to the first avatar; 22pt count pill.
  static const folderTabs = 40.0;
  static const folderTabInset = 4.0;
  static const folderTabsAbove = 10.0;
  static const folderTabsBelow = 3.0;
  static const folderCount = 22.0;

  /// 가리기 dust (Telegram spoiler look): one dot per this many pt², drift
  /// speed in pt/s, and peak opacity of the ink colour.
  static const veilDustArea = 7.0;
  static const veilDustSpeed = 5.0;
  static const veilDustAlpha = 0.85;
  static const veilDustCorner = 8.0;

  /// Search capsule: 44 pt tall, 16 pt side margins, icon + word centred
  /// (Telegram on Eric's iPhone, measured 2026-11-26).
  static const searchField = 44.0;

  /// Chat row: room kept right of the preview for the unread count (fits "999+").
  static const badgeSlot = 40.0;

  /// A waiting 비눗방울 in a chat row (Eric 2026-11-26, plan B): a little
  /// larger than the 15 pt flame, since the drop is round and see-through.
  static const rowBubble = 18.0;

  /// 📌 / 🔥 in a chat row (Eric 2026-11-26: emoji, not line icons).
  static const rowEmoji = 14.0;

  /// 움직이는 사진 LIVE capsule (iOS Photos / Telegram 563 measured at
  /// 393 pt): 22 tall, 6 from the photo's corner, 14 mark, 11 pt
  /// semibold letters with a little spacing; style menu = iOS 27 context
  /// menu (row 44, 22 icons, 26 corners), 220 wide.
  static const liveBadge = 22.0;
  static const liveInset = 6.0;
  static const liveMark = 14.0;
  static const liveText = TypeStyle(11, 13, FontWeight.w600);
  static const liveMenuWidth = 220.0;
  static const liveMenuRow = 44.0;

  /// Fade between the still and the moving clip, and the backward step
  /// of 바운스 (about 30 frames a second).
  static const liveFade = Duration(milliseconds: 220);
  static const liveBackStep = Duration(milliseconds: 33);

  /// 야간 모드 quick switch: the old screen fades over the new colours
  /// (iOS-style cross-fade, Telegram tip 180 without its circle).
  static const themeFade = Duration(milliseconds: 350);

  /// 움직이는 색 배경 (tips 281 + 284): one eighth of a turn per message I send.
  static const swirlTurn = Duration(milliseconds: 700);

  /// 테마·배경·꾸미기 (#21 + #24, Telegram iOS measured from the tip videos,
  /// iOS 27 sizes): colour dots 36 (ring 2.5, 3 gap) in rows of 8 at 16 side
  /// margin; background tiles 3 across (9:16, corner 12); preview 190 tall;
  /// cover on a profile 260 tall with 20 pt icons every 56 pt.
  static const lookDot = 36.0, lookDotRing = 2.5, lookDotGap = 3.0;
  static const wallTileCorner = 12.0, wallTileAspect = 9 / 16;
  static const lookPreview = 190.0;
  static const coverHeight = 260.0, coverIconStep = 56.0;

  /// 보낼 때 말풍선이 날아드는 움직임 (tip 289, like iPhone Messages): the new
  /// bubble rises from the message field ([sendFlyRise] points below its
  /// place), grows from 92 % (stickers / big emoji from 50 %) and settles.
  static const sendFly = Duration(milliseconds: 420);
  static const sendFlyRise = 64.0;
  static const sendFlyFrom = 0.92, sendFlyFromBig = 0.5;

  /// 메시지 효과 · 큰 이모지 효과 (tips 451 · 297 · 355): one play lasts
  /// [fxLength]; pieces are [fxPieceMin]–[fxPieceMax] pt emoji that sway
  /// [fxSway] pt. Picker cells 44 pt (iOS tap size) with 28 pt icons; the
  /// replay mark beside the time is 12 pt.
  static const fxLength = Duration(milliseconds: 2800);
  static const fxPieceMin = 22.0, fxPieceMax = 40.0, fxSway = 22.0;
  static const fxCell = 44.0, fxIcon = 28.0, fxMark = 12.0;

  /// Big emoji motion (tip 219) and dice roll (tip 218, 120 pt like a
  /// small sticker).
  static const fxEmojiMove = Duration(milliseconds: 900);
  static const diceRoll = Duration(milliseconds: 1500);
  static const diceSize = 120.0;

  /// Made emoji (tip 354): one loop of its motion; pictures are made at
  /// [cxPixels] px (sharp at 3x for a 48 pt emoji); big preview 112 pt
  /// (Telegram's lone custom emoji size).
  static const cxLoop = Duration(milliseconds: 1600);
  static const cxPixels = 160;
  static const cxBig = 112.0;

  /// 내 GIF (tip 558): the preview on a held GIF / a scheduled GIF, and how
  /// wide a GIF's words-and-drawing layer is made (a see-through PNG).
  static const double gifPreview = 160;
  static const double gifLayerWidth = 720;

  /// 자동 삭제 mark on a chat photo (Telegram tip 364 "1w"): a small
  /// accent capsule on the lower right, 2 pt ring in the list colour.
  static const timerMark = 18.0;
  static const timerMarkText = TypeStyle(10, 12, FontWeight.w600);

  /// QR theme cards (Telegram tip 316): 64 × 82, 14 corners, emoji 26.
  static const qrThemeW = 64.0, qrThemeH = 82.0, qrThemeCorner = 14.0, qrThemeEmoji = 26.0;

  /// 5분 QR countdown (tip 368) under the code.
  static const qrCountdown = TypeStyle(22, 28, FontWeight.w600);

  /// Wheel picker height (iOS standard 216).
  static const wheelHeight = 216.0;

  /// 코드 블록 (tip 411): code text 14/19 monospace, language label row 22,
  /// copy button 28 (hit area 44), box inset 8x10, corner radius[1].
  static const codeText = TypeStyle(14, 19, FontWeight.w400);
  static const codeHeader = 22.0, codeCopy = 16.0;
  static const codeFonts = ['Menlo', 'SF Mono', 'Roboto Mono', 'Consolas', 'monospace'];

  /// Corner of the rounded-square avatar (KakaoTalk's soft squircle,
  /// Eric 2026-11-26); people / groups / channels each pick it in 모양.
  static const roomKakaoCorner = 0.4;

  /// Title → description gap in an iOS two-line cell.
  static const subtitleGap = 2.0;

  /// Small story / bubble faces beside the list title (Telegram measured
  /// 2026-11-26): 30.7 pt across, 2 pt gradient ring, 1.33 pt white gap.
  /// Big story rings use the same top-to-bottom gradient as the small faces
  /// (Eric 2026-11-26, "원복할 수도 있어": false = the earlier sweep ring).
  static const storyRingLinear = true;

  static const miniFace = 92 / 3, miniRing = 2.0, miniGap = 4 / 3;
  static const topBar = 44.0, listIcon = 22.0, listIconSmall = 18.0, settingsRow = 52.0;

  /// White glyph in a 28pt settings tile, and the back chevron in the round
  /// back button (iOS 27, measured 2026-11-25: both bigger than before).
  /// How much lighter the top of a letter avatar is. iOS 27 tiles: ~3%
  /// (measured 2026-11-26); 18% before looked pastel (Eric).
  static const avatarTopLight = 0.04;

  static const tileGlyph = 20.0, backChevron = 27.0;
  static const loadingMark = 168.0;

  // Chat info header (Telegram 1:1 info, measured 2026-11-24): 100 photo,
  // 28 name, 57-tall action tiles.
  static const infoAvatar = 100.0, infoTile = 57.0, memberAvatar = 40.0, memberRow = 60.0;

  // 프로필 큰 사진 (tip 195, Telegram iOS measured from the tip video): the
  // photo fills the width as a square; pull 70 pt to open, scroll 24 pt to
  // close; story-style bars 2.5 tall with 4 gaps; iOS sheet timing.
  static const profilePhotoTall = 1.0, profilePullToOpen = 70.0, profileScrollToClose = 24.0;
  static const profileBarHeight = 2.5, profileBarGap = 4.0;
  static const profileGrow = Duration(milliseconds: 380);

  /// 예전 사진 strip under the photo viewer (tip 58) and the 이모지 사진
  /// maker's preview circle (tips 376 + 351).
  static const oldPhotoThumb = 52.0, emojiPhotoPreview = 168.0, emojiPhotoDot = 34.0;
  static const emojiPhotoOut = 1024.0, emojiPhotoShine = 0.22;

  /// 사진 제안 card in the chat (tip 373): same width as the community line.
  static const suggestCard = 220.0, suggestPhoto = 84.0;

  /// 이모지 사진 grounds: the iPhone system colours (tile palette + green,
  /// mint, brown), no dark green (rulebook ch. 4).
  static const emojiPhotoGrounds = [
    Palette.tileRed,
    Palette.tileOrange,
    Palette.tileYellow,
    Color(0xFF34C759),
    Color(0xFF00C8B3),
    Palette.tileTeal,
    Palette.tileBlue,
    Palette.tileIndigo,
    Palette.tilePurple,
    Palette.tilePink,
    Color(0xFFAC7F5E),
    Palette.tileGrey,
  ];

  /// Invite link icon with its "time / seats left" ring (tip 253).
  static const linkRing = 40.0, linkRingGap = 3.0, linkRingStroke = 2.0, joinedFace = 26.0;

  /// 대화 링크 editor: the preview over my chat background (tip 438).
  static const chatLinkPreview = 190.0;
  // QR codes the camera reads (tip 503): corner marks and the capsule's picture.
  static const qrMarkStroke = 3.0, qrMarkCorner = 6.0, qrCapsuleIcon = 36.0;
  // 다른 앱에서 보내기 (tips 350 + 182).
  static const shareInAccount = 32.0, shareInCheck = 22.0, shareInThumb = 64.0, shareInMark = 120.0, shareInBar = 6.0;

  // 스토리 남기기·꾸미기 (Telegram tips 392 / 534 / 468 / 395 / 408, measured
  // on Telegram iOS 2026-11-27 at 393 pt): profile story grid 3 across, 9:16,
  // 2 pt hairlines like iOS Photos; album capsules 32 tall; cover frame
  // strip 56 tall with the chosen frame lifted (iOS, no border glow);
  // reaction sticker 88 circle with a 48 pt emoji; round video 136 with a
  // 3 pt white rim; music capsule 36 tall.
  static const storyGridGap = 2.0, storyAlbumChip = 32.0, coverStrip = 56.0, coverLift = 1.12;
  static const storyReact = 88.0, storyReactEmoji = 48.0, storyRound = 136.0, storyRoundRim = 3.0, storyMusic = 36.0;
  // 채널 묶음 #15. 빠른 전달 (tip 521, Telegram frames 2025-05-21): five
  // 40 pt faces in a glass capsule, 6 apart, the one under the finger grows
  // 1.25x with its name in a small capsule above.
  static const quickFace = 40.0, quickGap = 6.0, quickPad = 6.0, quickGrow = 1.25, quickAbove = 8.0;
  // 다음 안 읽은 채널 (tip 292). Telegram iOS: nothing for the first 12 pt
  // past the newest post, then the ring fills over 94 pt more (106 in all,
  // was 64: Eric 2026-11-28 "좀 더 위로"); one tick when it is full.
  static const nextDead = 12.0, nextFill = 94.0, nextPull = nextDead + nextFill, nextFace = 36.0;

  // ── Gestures (Telegram iOS 2026-11 values, read 2026-11-28; numbers only,
  // see docs/GESTURES.md). One place so every screen moves the same way.
  // Swipe back (iOS 26 rule): where the page would be 0.35 s after letting
  // go decides; it closes past 187.5 pt or half the width, whichever is less.
  static const backProject = 0.35, backFinish = 187.5;
  // Release spring for the page: damping 0.85, settles in about 0.3 s.
  static const backDamping = 0.85, backResponse = 0.3;
  // Swipe to reply: others' bubbles 45 pt, mine 60 pt; past that the bubble
  // is held back (rubber band) and stops at 180; one firm tap at the point.
  static const replyIn = 45.0, replyOut = 60.0, replyMax = 180.0, replyIcon = 33.0;
  static const replyBack = Duration(milliseconds: 300);
  // Chat row buttons: open if flicked faster than 50 pt/s toward them, else
  // past half; the long pull runs the edge action past the buttons + 20 pt or
  // 52.5 % of the width (delete: width − 29). One light tick when it arms.
  static const rowFlick = 50.0, rowFullExtra = 20.0, rowFullShare = 0.525, rowDeleteGap = 29.0;
  static const rowResponse = 0.5;
  // Hold for the menu: 0.12 s still, then the item sinks for 0.2 s and the
  // menu opens (0.32 s in all; Flutter's own hold is 0.5 s).
  static const holdWait = Duration(milliseconds: 120), holdTime = Duration(milliseconds: 320);
  // Sheets: a downward flick faster than 300 pt/s, or a drag past 10 % of the
  // sheet, closes it; else it springs back.
  static const sheetFlick = 300.0, sheetShare = 0.1;
  // ↓ button: shows once the newest message is 40 pt off screen; 40 pt glass
  // circles, 12 apart, 20 pt above the message bar.
  static const jumpShow = 40.0, jumpSize = 40.0, jumpGap = 12.0, jumpAbove = 20.0;
  // Chat list: pull 60 pt past the top to bring 보관함 out.
  static const archivePull = 60.0;
  // 슈퍼 채널 (tip 472) and 보내는 이름 (tip 310): face beside a post.
  static const authorFace = 30.0;
  // 문의함 (tip 526): subscribers down the left side.
  static const inboxSide = 68.0;

  // Chat list row (Telegram iOS, measured 2026-11-24 on Eric's iPhone):
  // 76 pitch, 60 photo, 16 left, text 12 after the photo.
  static const chatRow = 76.0, chatAvatar = 60.0;
}

/// Neutral backgrounds + one brand accent (rulebook ch. 4).
class Palette {
  const Palette._(this.family, this.brightness);
  final BrandFamily family;
  final Brightness brightness;

  static final all = [
    for (final f in BrandFamily.values) ...[Palette._(f, Brightness.light), Palette._(f, Brightness.dark)],
  ];

  factory Palette.of(BrandFamily f, Brightness b) => all.firstWhere((p) => p.family == f && p.brightness == b);

  bool get dark => brightness == Brightness.dark;
  Color get accent => Brand.accent(family, brightness);
  Color get onAccent => const Color(0xFFFFFFFF);
  Color get background => dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
  Color get card => dark ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);

  /// Plain lists (chat list): white in light mode, black in dark (iOS).
  /// Chat room background: plain white / black like iPhone Messages.
  Color get chatBackground => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  /// Others' message bubbles on that background (iPhone Messages grey).
  Color get incoming => dark ? const Color(0xFF262629) : const Color(0xFFE9E9EB);
  Color get list => dark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  Color get label => dark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  Color get secondaryLabel => dark ? const Color(0x99EBEBF5) : const Color(0x993C3C43);

  /// Row chevron (iOS 27 Settings, lighter than systemGrey2).
  /// Search capsule fill (iOS tertiary fill).
  Color get searchFill => dark ? const Color(0xFF1C1C1E) : const Color(0xFFEEEEEF);

  Color get chevron => dark ? const Color(0xFF5A5A5E) : const Color(0xFFC5C5C7);
  Color get separator => dark ? const Color(0xFF38383A) : const Color(0xFFE6E6E8);

  /// A list row while a finger rests on it (iOS cell highlight, light grey).
  /// Unread count pill in a folder tab (Telegram grey).
  Color get folderCount => dark ? const Color(0xFF636366) : const Color(0xFFAEAEB2);
  Color get rowPressed => dark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

  /// Found words behind the text (iOS find-in-page yellow, Telegram's
  /// hashtag results): system yellow, see-through so the text stays black.
  Color get searchMark => dark ? const Color(0x80FFD60A) : const Color(0x99FFD60A);

  /// iOS system colours for icon tiles (chosen by meaning, rulebook ch. 4)
  /// and letter avatars: the iOS 26/27 system palette in sRGB. Checked
  /// 2026-11-26 against Eric's iPhone Settings screenshots after turning
  /// them from Display P3 into sRGB (reading P3 pixels as sRGB, as done on
  /// 11-25, made every colour look pastel). Green: see [tileGreen].
  static const tileRed = Color(0xFFFF383C),
      tileOrange = Color(0xFFFF8D28),
      tileYellow = Color(0xFFFFCC00),
      tileBlue = Color(0xFF0088FF),
      tileIndigo = Color(0xFF6155F5),
      tilePurple = Color(0xFFCB30E0),
      tilePink = Color(0xFFFF2D55),
      tileTeal = Color(0xFF00C3D0),
      tileGrey = Color(0xFF8E8E93),
      tileCyan = Color(0xFF00C0E8);

  /// Front-camera screen flash at 100 % warmth (iPhone True Tone amber).
  static const flashWarm = Color(0xFFFFC777);
  // Green icon tiles (Eric 2026-11-26 "나눠 쓰기"): iPhone system green on the
  // green theme; the brand green stays for the logo, send button and
  // selections. Blue theme: tiles follow the theme blue (Eric 2026-11-24).
  /// Unseen-story ring, top to bottom (Telegram measured 2026-11-26: green
  /// #34C671 → blue #3DA2F8). Blue theme: no green, cyan → theme blue.
  List<Color> get storyRing => family == BrandFamily.green ? [tileGreen, const Color(0xFF3DA2F8)] : [tileCyan, accent];

  Color get tileGreen => family == BrandFamily.green ? (dark ? const Color(0xFF30D158) : const Color(0xFF34C759)) : Brand.accent(family, brightness);

  /// Promo image grounds, top to bottom (id, colours, light words). Bright
  /// green and iOS blue only; no dark green (rulebook ch. 4).
  static const posterGrounds = [
    ('green', [Color(0xFF34C759), Color(0xFF03C46B)], true),
    ('blue', [Color(0xFF00C0E8), Color(0xFF0088FF)], true),
    ('night', [Color(0xFF2C2C2E), Color(0xFF1C1C1E)], true),
    ('white', [Color(0xFFFFFFFF), Color(0xFFF2F2F7)], false),
  ];

  /// 코드 블록 색 (tip 411): Apple's Xcode default light / dark theme, so code
  /// looks the way iPhone developers already know it.
  Color get codeKeyword => dark ? const Color(0xFFFF7AB2) : const Color(0xFF9B2393);
  Color get codeString => dark ? const Color(0xFFFF8170) : const Color(0xFFC41A16);
  Color get codeComment => dark ? const Color(0xFF7F8C98) : const Color(0xFF5D6C79);
  Color get codeNumber => dark ? const Color(0xFFD9C97C) : const Color(0xFF1C00CF);
  Color get codeType => dark ? const Color(0xFF5DD8FF) : const Color(0xFF0B4F79);
  Color get codeFunction => dark ? const Color(0xFF67B7A4) : const Color(0xFF326D74);

  /// Code box inside a bubble: on my (accent) bubble a card-coloured inset so
  /// the colours stay readable; on others' bubbles the ink at 6 %.
  Color get codeInset => dark ? const Color(0xF21C1C1E) : const Color(0xF2FFFFFF);

  /// "Black" tile (devices): lifted to dark grey on dark cards so it still reads.
  Color get tileBlack => dark ? const Color(0xFF48484A) : const Color(0xFF1C1C1E);
}
