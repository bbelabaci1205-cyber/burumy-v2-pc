// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class LKo extends L {
  LKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => '부루미';

  @override
  String get tabChats => '대화';

  @override
  String get tabContacts => '연락처';

  @override
  String get tabSettings => '설정';

  @override
  String get signUpTitle => '아이디로 시작해요';

  @override
  String get signUpId => '아이디';

  @override
  String get signUpPassword => '비밀번호';

  @override
  String get signUpInvite => '초대 코드';

  @override
  String get signUpButton => '가입하기';

  @override
  String get logInButton => '로그인';

  @override
  String get recoveryKeyTitle => '대화 복구 키';

  @override
  String get recoveryKeyBody => '새 휴대폰에서 예전 대화를 열 때 필요해요. 안전한 곳에 적어 두세요.';

  @override
  String get chatsEmpty => '아직 대화가 없어요';

  @override
  String get messageLocked => '이 메시지는 아직 열 수 없어요';

  @override
  String get sendFailedNoEncryption => '암호화되지 않은 대화에는 보낼 수 없어요';

  @override
  String get themeGreen => '그린';

  @override
  String get themeBlue => '블루';

  @override
  String get language => '언어';

  @override
  String get signUpSub => '아이디와 비밀번호만 있으면 돼요. 전화번호는 필요 없어요.';

  @override
  String get haveAccount => '이미 계정이 있어요';

  @override
  String get noAccount => '새로 가입할게요';

  @override
  String get logInTitle => '다시 오셨네요';

  @override
  String get fieldRequired => '아이디와 비밀번호를 넣어 주세요';

  @override
  String get passwordRule => '비밀번호는 8자 이상, 글자와 숫자를 섞어 주세요';

  @override
  String get somethingWrong => '잠시 후 다시 해 볼까요?';

  @override
  String get newChat => '새 대화';

  @override
  String get newChatHint => '상대 아이디';

  @override
  String get start => '시작';

  @override
  String get cancel => '취소';

  @override
  String get messageHint => '메시지';

  @override
  String get encryptedNotice => '이 대화는 종단간 암호화돼요. 부루미도 내용을 볼 수 없어요.';

  @override
  String get photo => '사진';

  @override
  String get video => '동영상';

  @override
  String get voice => '음성 메시지';

  @override
  String get file => '파일';

  @override
  String get you => '나';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String get settingsLook => '화면';

  @override
  String get settingsColor => '색';

  @override
  String get settingsLanguage => '언어';

  @override
  String get languageAuto => '휴대폰 설정 따르기';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsSecurity => '보안';

  @override
  String get makeRecoveryKey => '대화 복구 키 만들기';

  @override
  String get copied => '복사했어요';

  @override
  String get logOut => '로그아웃';

  @override
  String get myId => '내 아이디';

  @override
  String get contactsEmpty => '아직 연락처가 없어요';

  @override
  String get done => '완료';

  @override
  String get searchById => '아이디로 찾기';

  @override
  String get contactsSection => '내 연락처';

  @override
  String get searchResults => '찾은 사람';

  @override
  String get noOneFound => '찾는 사람이 없어요';

  @override
  String get attachPhoto => '사진 또는 동영상';

  @override
  String get attachFile => '파일';

  @override
  String get sending => '보내는 중';

  @override
  String get read => '읽음';

  @override
  String get enterRecoveryKey => '대화 복구 키 넣기';

  @override
  String get enterRecoveryKeyBody => '예전 휴대폰에서 만든 대화 복구 키를 넣으면 예전 대화를 열 수 있어요.';

  @override
  String get recoveryKeyHint => '단어 12개';

  @override
  String get recoveryDone => '예전 대화를 열었어요';

  @override
  String get recoveryWrong => '키가 맞지 않아요. 다시 확인해 주세요.';

  @override
  String get recoveryOn => '켜져 있어요';

  @override
  String get open => '열기';

  @override
  String get newGroup => '새 그룹';

  @override
  String get newChannel => '새 채널';

  @override
  String get addMembers => '멤버 추가';

  @override
  String get next => '다음';

  @override
  String get groupName => '그룹 이름';

  @override
  String get channelName => '채널 이름';

  @override
  String get create => '만들기';

  @override
  String get channelInfo => '채널에서는 나만 글을 쓸 수 있어요. 구독자는 읽기만 해요.';

  @override
  String get groupInfo => '그룹 대화도 종단간 암호화돼요.';

  @override
  String get channelReadOnly => '채널 주인만 글을 쓸 수 있어요';

  @override
  String get reply => '답장';

  @override
  String get edit => '수정';

  @override
  String get copy => '복사';

  @override
  String get delete => '삭제';

  @override
  String get editing => '메시지 수정';

  @override
  String get edited => '수정됨';

  @override
  String get typing => '입력 중…';

  @override
  String get deleted => '메시지를 지웠어요';

  @override
  String get undo => '되돌리기';

  @override
  String get channel => '채널';

  @override
  String get group => '그룹';

  @override
  String get orById => '또는 아이디로 1:1 대화 시작';

  @override
  String get lockTitle => '비밀번호를 넣어 주세요';

  @override
  String get lockWrong => '비밀번호가 맞지 않아요';

  @override
  String get appLock => '앱 잠금';

  @override
  String get appLockOff => '꺼져 있어요';

  @override
  String get appLockOn => '켜져 있어요';

  @override
  String get setPassword => '비밀번호 정하기';

  @override
  String get newPassword => '새 비밀번호';

  @override
  String get confirmPassword => '한 번 더';

  @override
  String get passwordMismatch => '두 비밀번호가 달라요';

  @override
  String get changePassword => '비밀번호 바꾸기';

  @override
  String get currentPassword => '지금 비밀번호';

  @override
  String get hidePassword => '숨김 비밀번호';

  @override
  String get deletePassword => '삭제 비밀번호';

  @override
  String get hidePasswordInfo =>
      '이 비밀번호로 열면 고른 사람과 대화가 모든 목록에서 사라져요. 다음에 보통 비밀번호로 열어도 계속 숨겨져요.';

  @override
  String get deletePasswordInfo =>
      '이 비밀번호로 열면 고른 사람과 대화가 지워져요. 1:1 대화는 상대 쪽에서도 조용히 지워지고, 그룹·채널은 며칠에 걸쳐 조용히 나가요. 상대에게는 알림이 가지 않아요. 되돌릴 수 없어요.';

  @override
  String get hideList => '숨길 사람·대화';

  @override
  String get deleteList => '지울 사람·대화';

  @override
  String get notSet => '없음';

  @override
  String get removePassword => '비밀번호 없애기';

  @override
  String get save => '저장';

  @override
  String get releaseHidden => '숨긴 사람 다시 보이기';

  @override
  String get releaseHiddenDone => '다시 보여요';

  @override
  String get passwordUsed => '다른 비밀번호와 같아요';

  @override
  String chooseCount(int count) {
    return '$count개 골랐어요';
  }

  @override
  String get enterToManage => '보통 비밀번호를 넣으면 잠금 설정을 바꿀 수 있어요';

  @override
  String get streaks => '스트릭';

  @override
  String get streakInfo =>
      '1:1 대화에서 둘 다 3일 넘게 매일 메시지를 보내면 이름 옆에 불꽃이 생겨요. 계산은 휴대폰 안에서만 해요.';

  @override
  String get sticker => '스티커';

  @override
  String get stickers => '스티커';

  @override
  String get pin => '고정';

  @override
  String get unpin => '고정 해제';

  @override
  String get pinnedMessage => '고정된 메시지';

  @override
  String get timer => '사라지는 메시지';

  @override
  String get timerOff => '끄기';

  @override
  String get timer1d => '1일';

  @override
  String get timer1w => '1주';

  @override
  String get timer1m => '1달';

  @override
  String timerLine(String duration) {
    return '사라지는 메시지: $duration';
  }

  @override
  String get timerOffLine => '사라지는 메시지를 껐어요';

  @override
  String get timerInfo => '정한 시간이 지나면 이 대화의 새 메시지가 양쪽 모두에서 지워져요.';

  @override
  String get attachOnce => '한 번만 보기 사진';

  @override
  String get viewOncePhoto => '한 번만 보기 사진';

  @override
  String get viewOnceTap => '눌러서 열기';

  @override
  String get viewOnceOpened => '열어 봤어요';

  @override
  String get viewOnceOpenedLine => '한 번만 보기 사진을 열어 봤어요';

  @override
  String get viewOnceInfo => '닫으면 다시 볼 수 없어요';

  @override
  String get profile => '프로필';

  @override
  String get name => '이름';

  @override
  String get changePhoto => '사진 바꾸기';

  @override
  String get photoServerNote =>
      '사진을 \'모두\'로 두면 서버에 저장돼요. \'내 연락처\'로 두면 서버에는 올라가지 않고 친구와의 암호화된 1:1 대화로만 전달돼요.';

  @override
  String get chatInfo => '정보';

  @override
  String get members => '멤버';

  @override
  String membersCount(int count) {
    return '멤버 $count명';
  }

  @override
  String get owner => '방장';

  @override
  String get admin => '관리자';

  @override
  String get leaveChat => '대화방 나가기';

  @override
  String get leaveChannel => '채널 나가기';

  @override
  String leavingIn(int seconds) {
    return '$seconds초 뒤에 나가요';
  }

  @override
  String get chatPin => '맨 위에 고정';

  @override
  String get chatUnpin => '고정 풀기';

  @override
  String get chatMute => '알림 끄기';

  @override
  String get chatUnmute => '알림 켜기';

  @override
  String get chatArchive => '보관하기';

  @override
  String get chatUnarchive => '보관 풀기';

  @override
  String get archive => '보관함';

  @override
  String get archiveEmpty => '보관한 대화가 없어요';

  @override
  String get archiveFooter => '보관한 대화는 이 휴대폰에만 표시돼요. 서버는 어떤 대화를 보관했는지 몰라요.';

  @override
  String get searchChats => '검색';

  @override
  String get searchNone => '찾는 대화가 없어요';

  @override
  String get forward => '전달';

  @override
  String get forwarded => '전달된 메시지';

  @override
  String get forwardTo => '전달할 대화';

  @override
  String get forwardDone => '전달했어요';

  @override
  String get forwardFailed => '이 대화에는 보낼 수 없어요';

  @override
  String get searchInChat => '검색';

  @override
  String searchCount(int n, int total) {
    return '$n/$total';
  }

  @override
  String get searchNoHits => '찾는 글이 없어요';

  @override
  String get linkPreviews => '링크 미리보기';

  @override
  String get linkPreviewInfo =>
      '링크를 보낼 때 내 휴대폰이 그 페이지의 제목과 사진을 가져와 메시지에 암호화해 넣어요. 받는 사람은 그 사이트에 접속하지 않아요.';

  @override
  String get voiceHoldHint => '길게 눌러 음성 메시지를 녹음해요';

  @override
  String get voiceNoMic => '마이크를 쓸 수 있게 허용해 주세요';

  @override
  String get voiceSlideCancel => '‹ 밀어서 취소';

  @override
  String get voiceReleaseCancel => '놓으면 취소돼요';

  @override
  String get poll => '투표';

  @override
  String get attachPoll => '투표';

  @override
  String get newPoll => '새 투표';

  @override
  String get pollQuestion => '질문';

  @override
  String get pollOptions => '선택지';

  @override
  String get pollOption => '선택지';

  @override
  String get pollAddOption => '선택지 추가';

  @override
  String get pollAnonymous => '익명 투표';

  @override
  String get pollMultiple => '여러 개 고르기';

  @override
  String get pollMultipleShort => '여러 개';

  @override
  String get pollAnonInfo =>
      '누가 무엇을 골랐는지 다른 멤버에게 보이지 않아요. 표는 만든 사람 휴대폰으로만 암호화돼 가고, 대화에는 숫자만 올라가요.';

  @override
  String get pollOpenInfo => '누가 무엇을 골랐는지 멤버 모두에게 보여요.';

  @override
  String get pollChannelInfo => '채널 투표는 항상 익명이에요. 구독자가 누구인지 드러나지 않아요.';

  @override
  String get pollCreate => '만들기';

  @override
  String pollVoters(int n) {
    return '$n명 투표';
  }

  @override
  String get pollNoVotes => '아직 투표가 없어요';

  @override
  String get pollOpenKind => '공개 투표';

  @override
  String get pollAnonKind => '익명 투표';

  @override
  String get pollClosedKind => '마감된 투표';

  @override
  String get pollVote => '투표하기';

  @override
  String get pollClose => '투표 마감';

  @override
  String get pollRetract => '투표 취소';

  @override
  String get attachBubble => '비눗방울';

  @override
  String get bubbleSendTitle => '비눗방울 보내기';

  @override
  String bubbleSendInfo(String name) {
    return '$name님 홈 화면에 방울이 떠요. 안에 무엇이 들었는지는 보이지 않고, 터뜨리면 한 번만 열려요.';
  }

  @override
  String get bubbleRecord => '음성 녹음';

  @override
  String bubblesWaiting(int n) {
    return '비눗방울 $n개';
  }

  @override
  String get bubbleTapToPop => '눌러서 터뜨리기';

  @override
  String get bubbleSent => '비눗방울을 보냈어요';

  @override
  String get bubblePopped => '터뜨렸어요';

  @override
  String get bubbleOnce => '한 번만 볼 수 있어요. 닫으면 사라져요.';

  @override
  String get bubbleGone => '이미 터진 방울이에요';

  @override
  String get callVoice => '음성 통화';

  @override
  String get callVideo => '영상 통화';

  @override
  String get callCalling => '거는 중…';

  @override
  String get callConnecting => '연결 중…';

  @override
  String get callEnded => '통화 종료';

  @override
  String get callNoAnswer => '받지 않았어요';

  @override
  String get callDeclined => '상대가 거절했어요';

  @override
  String get callBusy => '상대가 통화 중이에요';

  @override
  String get callFailed => '연결하지 못했어요';

  @override
  String get callAccept => '받기';

  @override
  String get callDecline => '거절';

  @override
  String get callEnd => '종료';

  @override
  String get callMute => '음소거';

  @override
  String get callSpeaker => '스피커';

  @override
  String get callCamera => '카메라';

  @override
  String get callFlip => '전환';

  @override
  String get callE2ee => '끝에서 끝까지 암호화돼요';

  @override
  String get callLineOut => '건 통화';

  @override
  String get callLineIn => '받은 통화';

  @override
  String get callLineMissed => '부재중 통화';

  @override
  String get callLineDeclined => '거절한 통화';

  @override
  String get callLineCancelled => '취소한 통화';

  @override
  String get callLineNow => '통화 중';

  @override
  String get callNotSetUp => '이 버전에서는 아직 통화를 쓸 수 없어요';

  @override
  String get callBack => '다시 걸기';

  @override
  String get callPreview => '통화';

  @override
  String get noticeNew => '새 메시지';

  @override
  String get noticeTextHidden => '알림에 내용 숨기기';

  @override
  String get noticeTextHiddenInfo =>
      '켜면 알림에 대화 이름과 내용 없이 \'새 메시지\'만 보여요. 알림 내용은 이 휴대폰에서만 풀어요.';

  @override
  String get noticeChannel => '메시지';

  @override
  String get wipeAfter => '틀리면 모두 지우기';

  @override
  String get wipeAfterInfo =>
      '비밀번호를 연속으로 이만큼 틀리면 이 휴대폰의 모든 대화가 지워져요. 1:1 대화는 상대 휴대폰에서도 지워지고, 그룹·채널은 며칠에 걸쳐 조용히 나가요.';

  @override
  String wipeTimes(int n) {
    return '$n번';
  }

  @override
  String wipeWarning(int n) {
    return '$n번 더 틀리면 모든 대화가 지워져요';
  }

  @override
  String get deleteForBoth => '양쪽에서 대화 삭제';

  @override
  String get deleteForBothInfo => '내 휴대폰과 상대 휴대폰 모두에서 이 대화가 지워져요.';

  @override
  String deletingIn(int seconds) {
    return '$seconds초 뒤 삭제돼요';
  }

  @override
  String erasedByFriend(String name) {
    return '상대가 양쪽에서 대화를 지웠어요 · $name';
  }

  @override
  String get editorReset => '초기화';

  @override
  String get editorCrop => '자르기';

  @override
  String get editorFilters => '필터';

  @override
  String get editorAdjust => '조절';

  @override
  String get filterNone => '원본';

  @override
  String get filterVivid => '선명하게';

  @override
  String get filterWarm => '따뜻하게';

  @override
  String get filterCool => '차갑게';

  @override
  String get filterDramatic => '드라마틱';

  @override
  String get filterMono => '흑백';

  @override
  String get filterSilver => '실버';

  @override
  String get filterNoir => '누아르';

  @override
  String get filterFade => '바랜';

  @override
  String get filterFilm => '필름';

  @override
  String get adjExposure => '노출';

  @override
  String get adjBrilliance => '휘도';

  @override
  String get adjHighlights => '하이라이트';

  @override
  String get adjShadows => '그림자';

  @override
  String get adjContrast => '대비';

  @override
  String get adjBrightness => '밝기';

  @override
  String get adjBlackPoint => '블랙 포인트';

  @override
  String get adjSaturation => '채도';

  @override
  String get adjVibrance => '생동감';

  @override
  String get adjWarmth => '색온도';

  @override
  String get adjTint => '색조';

  @override
  String get adjFade => '바래기';

  @override
  String get adjVignette => '비네트';

  @override
  String inviteFrom(String name) {
    return '초대한 사람 · $name';
  }

  @override
  String get inviteAccept => '참여';

  @override
  String get inviteDecline => '거절';

  @override
  String get callWaiting => '대기 중인 전화';

  @override
  String get callWaitingVideo => '대기 중인 영상 통화';

  @override
  String get callWaitingTitle => '통화 중 걸려온 전화';

  @override
  String get callWaitingWait => '대기 통화';

  @override
  String get callWaitingMissed => '부재중으로 남기기';

  @override
  String get callWaitingBusy => '통화 중이라고 알리기';

  @override
  String get callWaitingInfo =>
      '대기 통화: 거는 사람은 계속 울리는 소리를 듣고, 나는 받을 수 있어요. 부재중으로 남기기: 통화 중에는 아무것도 뜨지 않고 부재중 전화로 남아요. 통화 중이라고 알리기: 거는 사람에게 통화 중이라고 보여요.';

  @override
  String get tabCalls => '통화';

  @override
  String get callsAll => '모두';

  @override
  String get callsMissed => '부재중';

  @override
  String get callsEmpty => '아직 통화 기록이 없어요';

  @override
  String get callsEmptyMissed => '부재중 통화가 없어요';

  @override
  String get callsNew => '새 통화';

  @override
  String get settingsAppearance => '모양';

  @override
  String get settingsNotifications => '알림';

  @override
  String get settingsChatsPage => '대화';

  @override
  String get settingsPrivacy => '개인정보 및 보안';

  @override
  String get privacyInfo => '앱 잠금, 숨김·삭제 비밀번호, 대화 복구 키 같은 보안 기능을 관리해요.';

  @override
  String get contactsAddById => '아이디로 친구 추가';

  @override
  String get contactsInvite => '친구 초대';

  @override
  String inviteText(String id) {
    return '부루미에서 같이 대화해요. 제 아이디: $id';
  }

  @override
  String get inviteCopied => '초대 글을 복사했어요. 친구에게 붙여 넣어 보내세요.';

  @override
  String get chatsMenuArchive => '보관함';

  @override
  String get sortByName => '이름순';

  @override
  String get sortByRecent => '최근 대화순';

  @override
  String get colorTheme => '색 테마';

  @override
  String get nightMode => '야간 모드';

  @override
  String get nightSystem => '휴대폰 설정 따르기';

  @override
  String get nightLight => '끄기';

  @override
  String get nightDark => '켜기';

  @override
  String get textSize => '텍스트 크기';

  @override
  String get bubbleCorners => '메시지 모서리';

  @override
  String get bubbleSample => '안녕하세요! 👋';

  @override
  String get stickersEmoji => '스티커 및 이모지';

  @override
  String get doubleTapInfo => '메시지를 두 번 누르면 고른 반응이 붙어요.';

  @override
  String get quickReaction => '빠른 반응';

  @override
  String get doubleTapReact => '두 번 눌러 반응';

  @override
  String get powerSaving => '절전';

  @override
  String get powerSavingInfo => '배터리를 아끼도록 움직임 효과를 줄여요.';

  @override
  String get uiEffects => '화면 효과';

  @override
  String get uiEffectsInfo => '끄면 화면이 바뀔 때 움직임 없이 바로 바뀌어요.';

  @override
  String get messageNotices => '메시지 알림';

  @override
  String get notifyDirect => '개인 대화';

  @override
  String get notifyGroup => '그룹 대화';

  @override
  String get notifyChannel => '채널';

  @override
  String get resetNotices => '모든 알림 설정 재설정';

  @override
  String get enterSends => '엔터로 보내기';

  @override
  String get swipeReply => '왼쪽으로 밀어서 답장';

  @override
  String get dataStorage => '데이터 및 저장 공간';

  @override
  String get whoEveryone => '모두';

  @override
  String get whoContacts => '내 연락처';

  @override
  String get whoNobody => '아무도 안 됨';

  @override
  String get blockedUsers => '차단한 사용자';

  @override
  String get defaultTimer => '메시지 자동 삭제';

  @override
  String get defaultTimerInfo => '켜면 새로 만드는 대화의 메시지가 정한 시간 뒤 양쪽에서 지워져요.';

  @override
  String get privacyWho => '개인 정보';

  @override
  String get whoInfo => '내 연락처가 아닌 사람의 전화는 부재중으로 남고, 메시지·초대는 보이지 않아요.';

  @override
  String get whoCalls => '전화';

  @override
  String get whoMessages => '메시지';

  @override
  String get whoInvites => '그룹·채널 초대';

  @override
  String get readTypingInfo => '끄면 상대에게도 내 읽음 표시와 입력 중 표시가 가지 않아요.';

  @override
  String get sendRead => '읽음 표시 보내기';

  @override
  String get sendTyping => '입력 중 표시 보내기';

  @override
  String get devices => '기기';

  @override
  String get encryptionKeys => '암호화 키';

  @override
  String get blockedInfo => '차단한 사람의 메시지와 초대는 나에게 오지 않아요. 상대에게는 알리지 않아요.';

  @override
  String get blockSomeone => '사용자 차단하기';

  @override
  String get unblock => '차단 풀기';

  @override
  String get blockFailed => '차단하지 못했어요. 아이디를 확인해 주세요.';

  @override
  String get userIdHint => '아이디';

  @override
  String get deviceVerified => '확인된 기기';

  @override
  String get deviceNotVerified => '아직 확인 안 된 기기';

  @override
  String get thisDevice => '이 기기';

  @override
  String get logOutOthers => '다른 모든 기기 로그아웃';

  @override
  String get otherDevices => '다른 기기';

  @override
  String get passwordAgainInfo => '안전을 위해 계정 비밀번호를 한 번 더 넣어 주세요.';

  @override
  String get keysInfo =>
      '상대와 직접 만나 이 키를 비교하면 중간에서 엿보는 사람이 없는지 확인할 수 있어요. 눌러서 복사해요.';

  @override
  String get myIdentityKey => '내 신원 키';

  @override
  String get thisDeviceKey => '이 기기 키';

  @override
  String get savedMessages => '저장한 메시지';

  @override
  String get chatBackup => '대화 백업';

  @override
  String get editShort => '편집';

  @override
  String get idLabel => '아이디';

  @override
  String get blockUser => '사용자 차단';

  @override
  String get veilDots => '대화방 가리기';

  @override
  String get veilDotsInfo =>
      '이 대화방의 메시지가 반짝이는 점으로 가려지고, 손가락으로 누르고 있는 동안만 보여요. 메뉴는 짧게 톡 누르면 열려요.';

  @override
  String get readHere => '이 대화에서 읽음 표시';

  @override
  String get veilBlur => '민감한 대화';

  @override
  String get veilBlurInfo =>
      '민감한 대화는 흐린 유리 아래 있고, 손가락을 대고 있는 동안만 선명하게 보여요. 옆사람이 훔쳐볼 수 없어요.';

  @override
  String get tabMedia => '미디어';

  @override
  String get tabFiles => '파일';

  @override
  String get tabLinks => '링크';

  @override
  String get nothingShared => '아직 없어요';

  @override
  String get bio => '자기소개';

  @override
  String get bioInfo => '누가 볼지는 설정 > 개인정보 및 보안에서 정해요. 70자까지 쓸 수 있어요.';

  @override
  String get markRead => '읽음';

  @override
  String get hideFromList => '목록에서 숨기기';

  @override
  String get hiddenChats => '숨긴 대화방';

  @override
  String get hiddenChatsInfo =>
      '목록에서 숨긴 대화방이에요. 메시지와 알림은 그대로 와요. 누르면 다시 목록에 보여요.';

  @override
  String get showInList => '목록에 다시 보이기';

  @override
  String get filterAll => '모두';

  @override
  String get filterUnread => '안 읽음';

  @override
  String get filterPeople => '연락처';

  @override
  String get filterGroups => '그룹';

  @override
  String get filterChannels => '채널';

  @override
  String get filterBots => '봇';

  @override
  String get myFolders => '내 폴더';

  @override
  String get newFolder => '새 폴더';

  @override
  String get folderName => '폴더 이름';

  @override
  String get folderKinds => '포함할 대화';

  @override
  String get folderInfo =>
      '고른 종류의 대화가 모두 들어가요. 아래에서 대화를 하나씩 넣거나 뺄 수도 있어요. 폴더는 이 기기에만 저장돼요.';

  @override
  String get folderChats => '대화 고르기';

  @override
  String get deleteFolder => '폴더 삭제';

  @override
  String get listTop => '위쪽에 검색과 폴더 보이기';

  @override
  String get listTopInfo => '끄면 대화 목록이 더 넓어져요. 검색과 폴더는 왼쪽 위 메뉴에 있어요.';

  @override
  String get saveToSaved => '저장한 메시지에 넣기';

  @override
  String get savedDone => '저장한 메시지에 넣었어요';

  @override
  String get sendQuietly => '조용히 보내기';

  @override
  String get sendLater => '예약 보내기';

  @override
  String get scheduleSend => '이때 보내기';

  @override
  String get scheduledDone => '예약했어요';

  @override
  String scheduledCount(int count) {
    return '예약된 메시지 $count개';
  }

  @override
  String get scheduledInfo =>
      '예약한 메시지는 이 휴대폰에 있다가, 정한 시간에 앱이 열려 있으면 바로, 아니면 다음에 앱을 열 때 보내져요.';

  @override
  String get sendNow => '지금 보내기';

  @override
  String get fmtBold => '굵게';

  @override
  String get fmtItalic => '기울임';

  @override
  String get fmtUnderline => '밑줄';

  @override
  String get fmtStrike => '취소선';

  @override
  String get fmtCode => '고정폭';

  @override
  String get fmtSpoiler => '스포일러';

  @override
  String get fmtLink => '링크';

  @override
  String get more => '더 보기';

  @override
  String get contactEdit => '연락처 편집';

  @override
  String get contactNameInfo => '이 이름은 내 휴대폰에서만 보여요. 상대방은 몰라요.';

  @override
  String get memo => '메모';

  @override
  String get memoHint => '이 사람에 대해 기억할 것';

  @override
  String get memoInfo => '메모도 내 휴대폰에만 남아요.';

  @override
  String get clearChat => '메시지 비우기';

  @override
  String get clearChatInfo => '내 화면에서만 지워져요. 상대방 화면은 그대로예요.';

  @override
  String get clearChatDone => '메시지를 비웠어요';

  @override
  String get send => '보내기';

  @override
  String get attachGallery => '갤러리';

  @override
  String get attachCamera => '카메라';

  @override
  String get attachLibrary => '사진 고르기';

  @override
  String get attachPickFile => '파일 고르기';

  @override
  String get attachFileInfo => '사진도 원본 그대로 파일로 보낼 수 있어요. 한 번에 20개까지요.';

  @override
  String selectedCount(int count) {
    return '$count개 선택';
  }

  @override
  String get onceOnInfo => '받는 사람이 한 번만 볼 수 있어요';

  @override
  String get onceNoCaption => '한 번만 보기에는 설명을 붙이지 않아요';

  @override
  String get captionHint => '설명 넣기';

  @override
  String get checklist => '체크리스트';

  @override
  String get newChecklist => '새 체크리스트';

  @override
  String get checklistTitle => '제목';

  @override
  String get checklistTitleHint => '무엇을 할까요?';

  @override
  String get checklistItems => '할 일';

  @override
  String checklistItemsInfo(int count) {
    return '$count개까지 넣을 수 있어요.';
  }

  @override
  String get checklistItemHint => '할 일';

  @override
  String get checklistAddItem => '할 일 추가';

  @override
  String get checklistOthersMark => '다른 사람도 체크할 수 있어요';

  @override
  String get checklistOthersAdd => '다른 사람도 할 일을 추가할 수 있어요';

  @override
  String get checklistOthersInfo =>
      '체크리스트도 메시지처럼 암호화돼요. 허락하지 않은 사람이 체크하거나 추가하면 모든 휴대폰이 무시해요.';

  @override
  String checklistDone(int done, int total) {
    return '$done/$total 완료';
  }

  @override
  String get meetup => '일정';

  @override
  String get newMeetup => '새 일정';

  @override
  String get meetupTitleHint => '무엇을 하나요?';

  @override
  String get meetupPlaceHint => '장소 (선택)';

  @override
  String get meetupWhen => '언제';

  @override
  String get meetupInfo => '일정과 참석 답도 메시지처럼 암호화돼요. 서버는 누가 오는지 몰라요.';

  @override
  String get meetupYes => '갈게요';

  @override
  String get meetupMaybe => '아마도';

  @override
  String get meetupNo => '못 가요';

  @override
  String get meetupCancel => '일정 취소';

  @override
  String get meetupCancelled => '취소된 일정이에요';

  @override
  String get meetupPast => '지난 일정이에요';

  @override
  String get contactCard => '연락처';

  @override
  String get pickContact => '연락처 보내기';

  @override
  String get noContacts => '아직 연락처가 없어요';

  @override
  String get contactMessage => '메시지 보내기';

  @override
  String get removeAdmin => '관리자 해제';

  @override
  String get makeAdmin => '관리자로 지정';

  @override
  String get removeSubscriber => '구독자 내보내기';

  @override
  String get removeMember => '그룹에서 내보내기';

  @override
  String subscribersCount(int count) {
    return '구독자 $count명';
  }

  @override
  String get subscribers => '구독자';

  @override
  String get hideMembersOnInfo => '멤버 목록이 관리자에게만 보여요.';

  @override
  String get subscribersHiddenInfo =>
      '구독자 목록은 관리자만 볼 수 있어요. 누가 구독하는지 다른 구독자는 몰라요.';

  @override
  String get editGroup => '그룹 편집';

  @override
  String get editChannel => '채널 편집';

  @override
  String get aboutHint => '설명 (선택)';

  @override
  String get signPosts => '서명 남기기';

  @override
  String get signPostsInfo => '켜면 글 위에 올린 관리자 이름이 보여요.';

  @override
  String get hideMembers => '멤버 목록 숨기기';

  @override
  String get hideMembersInfo => '켜면 관리자만 멤버 목록을 볼 수 있어요.';

  @override
  String get add => '추가';

  @override
  String get openLinkAsk => '이 링크를 열까요?';

  @override
  String get openLink => '열기';

  @override
  String get location => '위치';

  @override
  String get locationSend => '현재 위치 보내기';

  @override
  String get locationFinding => '위치를 찾고 있어요';

  @override
  String locationAccuracy(int meters) {
    return '정확도 약 ${meters}m';
  }

  @override
  String get locationDenied => '위치 권한이 꺼져 있어요. 설정에서 부루미의 위치 접근을 허용해 주세요.';

  @override
  String get locationOff => '휴대폰의 위치 서비스가 꺼져 있어요.';

  @override
  String get locationUnavailable => '지금은 위치를 알 수 없어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get locationRetry => '다시 찾기';

  @override
  String get openPhoneSettings => '설정 열기';

  @override
  String get locationOpenMap => '지도에서 보기';

  @override
  String get locationPrivacy =>
      '보낼 때 그 순간의 위치를 한 번만 읽어요. 위치는 암호화되어 대화 상대만 보고, 지도 회사에는 보내지 않아요.';

  @override
  String get attachAllPhotos => '모든 사진';

  @override
  String get photosDenied => '사진 접근이 꺼져 있어요';

  @override
  String settingsProfileSub(String id) {
    return '$id · 프로필, 사진, 이름';
  }

  @override
  String securityCheck(int done, int total) {
    return '보안 점검 $done/$total';
  }

  @override
  String get securityAllDone => '모두 마쳤어요. 계정이 잘 지켜지고 있어요.';

  @override
  String securityLeft(int n) {
    return '$n개 남았어요. 눌러서 마저 해 주세요.';
  }

  @override
  String get securityCheckTitle => '보안 점검';

  @override
  String get securityCheckInfo => '두 가지만 해 두면 폰을 잃어버리거나 바꿔도 대화를 지킬 수 있어요.';

  @override
  String get checkRecovery => '대화 복구 키 만들기';

  @override
  String get checkRecoveryInfo =>
      '새 폰에서 이전 대화를 다시 열 때 써요. 키를 잃어버리면 아무도 되살릴 수 없어요.';

  @override
  String get checkDevice => '이 기기 확인';

  @override
  String get checkDeviceInfo => '이 기기가 내 것이라고 확인해 두면 친구들도 안심하고 대화할 수 있어요.';

  @override
  String get checkDone => '완료';

  @override
  String get checkTodo => '해야 해요';

  @override
  String get stateOn => '켜짐';

  @override
  String get stateOff => '꺼짐';

  @override
  String get accountManage => '계정 관리';

  @override
  String get accountManageInfo => '아이디, 비밀번호, 로그인한 기기와 암호화 키를 한곳에서 관리해요.';

  @override
  String get faq => '자주 묻는 질문';

  @override
  String get featureTour => '부루미 기능 소개';

  @override
  String get featureTourInfo => '부루미에서 할 수 있는 일을 한눈에 볼 수 있어요.';

  @override
  String get aboutApp => '소개';

  @override
  String appVersion(String version) {
    return '버전 $version';
  }

  @override
  String get openSourceLicenses => '오픈소스 라이선스';

  @override
  String get aboutInfo => '부루미는 대화 내용을 아무도 볼 수 없는 메신저예요. 운영자도 서버도 내용을 볼 수 없어요.';

  @override
  String get powerMode => '절전 모드';

  @override
  String powerBelowValue(int pct) {
    return '$pct% 미만일 때';
  }

  @override
  String get powerAlways => '항상';

  @override
  String get powerNever => '끄기';

  @override
  String get powerModeInfo =>
      '배터리가 정한 값보다 적으면 움직이는 효과를 잠시 멈춰요. 웹에서는 배터리를 알 수 없어서 \'항상\'만 적용돼요.';

  @override
  String get faqQ1 => '대화가 정말 안전한가요?';

  @override
  String get faqA1 => '1:1 대화와 그룹 대화는 모두 끝에서 끝까지 암호화돼요. 서버와 운영자는 내용을 볼 수 없어요.';

  @override
  String get faqQ2 => '전화번호 없이 가입할 수 있나요?';

  @override
  String get faqA2 => '네. 아이디와 비밀번호만 있으면 돼요. 전화번호와 연락처는 쓰지 않아요.';

  @override
  String get faqQ3 => '폰을 바꾸면 대화가 사라지나요?';

  @override
  String get faqA3 =>
      '대화 복구 키를 만들어 두면 새 폰에서 이전 대화를 다시 열 수 있어요. 키는 나만 갖고 있어서, 잃어버리면 아무도 되살릴 수 없어요.';

  @override
  String get faqQ4 => '누가 나를 찾을 수 있나요?';

  @override
  String get faqA4 => '내 아이디를 아는 사람만 찾을 수 있어요. 이름이나 전화번호로는 찾을 수 없어요.';

  @override
  String get faqQ5 => '사라지는 메시지는 어떻게 켜나요?';

  @override
  String get faqA5 =>
      '대화 위쪽의 타이머 버튼을 눌러 시간을 고르면, 그 뒤에 보낸 메시지가 정한 시간이 지나면 사라져요.';

  @override
  String get faqQ6 => '비눗방울은 뭔가요?';

  @override
  String get faqA6 => '한 번 열어 보면 사라지는 사진이에요. 홈 화면 위젯에는 내용 없이 방울만 보여요.';

  @override
  String get faqQ7 => '앱에 잠금을 걸 수 있나요?';

  @override
  String get faqA7 => '설정 > 개인정보 및 보안에서 비밀번호를 정하면 앱을 열 때마다 물어봐요.';

  @override
  String get faqQ8 => '보낸 메시지를 고치거나 지울 수 있나요?';

  @override
  String get faqA8 => '메시지를 길게 누르면 고치거나 지울 수 있어요. 지운 메시지는 상대 화면에서도 사라져요.';

  @override
  String get tourE2e => '끝에서 끝까지 암호화';

  @override
  String get tourE2eBody => '모든 대화는 내 폰과 상대 폰에서만 열려요.';

  @override
  String get tourTimer => '사라지는 메시지';

  @override
  String get tourTimerBody => '정한 시간이 지나면 메시지가 저절로 지워져요.';

  @override
  String get tourOnce => '한 번만 보기';

  @override
  String get tourOnceBody => '사진과 영상을 한 번만 열어 볼 수 있게 보내요.';

  @override
  String get tourBubble => '비눗방울';

  @override
  String get tourBubbleBody => '친구에게 사진 방울을 띄워요. 열면 톡 터져요.';

  @override
  String get tourStreak => '연속 대화';

  @override
  String get tourStreakBody => '친구와 매일 대화하면 🔥 숫자가 올라가요.';

  @override
  String get tourGroups => '그룹과 채널';

  @override
  String get tourGroupsBody => '친구끼리는 그룹, 많은 사람에게는 채널로 소식을 전해요.';

  @override
  String get tourTools => '투표 · 체크리스트 · 모임';

  @override
  String get tourToolsBody => '대화 안에서 바로 정하고, 할 일을 나누고, 약속을 잡아요.';

  @override
  String get tourLocation => '위치 보내기';

  @override
  String get tourLocationBody => '지금 있는 곳을 보내요. 지도는 눌렀을 때만 열려요.';

  @override
  String get myQr => '내 QR 코드';

  @override
  String get myQrInfo => '친구에게 보여 주면 내 아이디를 바로 알려 줄 수 있어요.';

  @override
  String get verifyThisDevice => '이 기기 확인';

  @override
  String get verifiedDone => '확인 완료';

  @override
  String get verifyNeeded => '확인 필요';

  @override
  String get undoSend => '보내기 취소 (5초)';

  @override
  String get undoSendInfo => '보낸 뒤 5초 동안은 실제로 전송되지 않아서 취소할 수 있어요.';

  @override
  String sendingIn(int n) {
    return '$n초 뒤에 보내요';
  }

  @override
  String get veilAll => '모든 대화방 가리기';

  @override
  String get veilAllInfo =>
      '모든 대화방의 메시지가 가려져서 누르고 있는 동안만 보여요. 옆 사람이 볼 수 없어요. 이 기기에만 적용돼요.';

  @override
  String get panic => '패닉 동작';

  @override
  String get panicInfo =>
      '두 손가락으로 두 번 톡톡 치면 바로 잠겨요. 소리와 진동은 없어요. 앱 잠금이 켜져 있어야 해요.';

  @override
  String get appearanceInfo =>
      '색 테마, 야간 모드, 글자 크기, 대화 배경처럼 부루미가 보이는 모습을 내 취향대로 바꿀 수 있어요.';

  @override
  String get themePlain => '기본';

  @override
  String get themeSecure => '보안';

  @override
  String get themeNature => '자연';

  @override
  String get themeDaily => '일상';

  @override
  String get themeHiphop => '힙합 밝게';

  @override
  String get themePhoto => '내 사진';

  @override
  String get myPhotoBackground => '내 사진으로 배경 바꾸기';

  @override
  String get myColor => '내 색상';

  @override
  String get glassEffect => '유리 효과';

  @override
  String get glassClear => '맑게';

  @override
  String get glassNormal => '기본';

  @override
  String get glassSolid => '불투명';

  @override
  String get glassInfo => '불투명을 고르면 비치는 유리 대신 깔끔한 판으로 보여요. 절전 모드에서도 이렇게 바뀌어요.';

  @override
  String get autoNight => '자동 야간 모드';

  @override
  String get autoNightOff => '끔';

  @override
  String get autoNightSystem => '휴대폰 설정 따르기';

  @override
  String get textSizeDefault => '기본';

  @override
  String get textSizePreview => '어제 회의에서 왼쪽 길로 가자고 했나, 오른쪽 길로 가자고 했나?';

  @override
  String get textSizePreviewReply => '오른쪽이요. 확실해요.';

  @override
  String get notificationsInfo =>
      '새 메시지 알림을 어떻게 받을지 정해요. 앱을 쓰는 중의 알림, 집중 일정도 여기서 바꿔요.';

  @override
  String get inAppNotices => '앱 사용 중 알림';

  @override
  String get inAppStyle => '알림 스타일';

  @override
  String get inAppSilent => '무음';

  @override
  String get inAppBanner => '배너';

  @override
  String get inAppStyleInfo =>
      '배너는 화면 위에 잠깐 나타났다가 사라져요. 무음이면 앱을 쓰는 동안 아무것도 뜨지 않아요.';

  @override
  String get inAppSound => '앱 사용 중 소리';

  @override
  String get inAppPreview => '앱 사용 중 미리보기';

  @override
  String get focusSchedule => '집중 일정';

  @override
  String get focusInfo => '정한 시간에는 알림이 오지 않아요. 메시지는 그대로 받고, 모두 이 휴대폰 안에서 처리해요.';

  @override
  String get focusFrom => '시작';

  @override
  String get focusTo => '종료';

  @override
  String get focusDays => '요일';

  @override
  String get focusEveryDay => '매일';

  @override
  String get showNotices => '알림 표시';

  @override
  String get messagePreview => '메시지 미리보기';

  @override
  String get messagePreviewInfo => '끄면 알림에 \'새 메시지\'만 보여요.';

  @override
  String get sound => '소리';

  @override
  String get soundNone => '없음';

  @override
  String get sound_nuri => '부루미';

  @override
  String get sound_pop => '톡';

  @override
  String get sound_drop => '물방울';

  @override
  String get sound_bell => '종';

  @override
  String get sound_chord => '화음';

  @override
  String get sound_breeze => '바람';

  @override
  String get sound_knock => '똑똑';

  @override
  String get sound_twinkle => '반짝';

  @override
  String get soundInfo => '부루미가 직접 만든 소리예요. 누르면 미리 들어 볼 수 있어요.';

  @override
  String get noticeExceptions => '예외';

  @override
  String get addException => '예외 추가';

  @override
  String get exceptionsInfo => '여기 넣은 대화는 위 설정보다 먼저 적용돼요.';

  @override
  String get noticeOnHere => '알림 켬';

  @override
  String get noticeOffHere => '알림 끔';

  @override
  String get removeException => '예외에서 빼기';

  @override
  String get pickChat => '대화 고르기';

  @override
  String get alwaysAllow => '항상 허용';

  @override
  String get alwaysDeny => '항상 거부';

  @override
  String get addUsers => '사용자 추가';

  @override
  String peopleCount(int n) {
    return '$n명';
  }

  @override
  String get whoExceptionsInfo => '사람을 예외로 넣으면 위 설정보다 먼저 적용돼요. 모두 이 휴대폰에서 지켜요.';

  @override
  String get bigEmoji => '큰 이모지';

  @override
  String get bigEmojiInfo => '이모지 1~3개만 보내면 말풍선 없이 크게 보여요.';

  @override
  String get burumyStickers => '부루미 스티커';

  @override
  String stickerCount(int n) {
    return '스티커 $n개';
  }

  @override
  String get stickerPacksInfo => '끈 캐릭터는 스티커 칸에서 빠져요. 받은 스티커는 그대로 보여요.';

  @override
  String get clearRecentStickers => '최근 스티커 지우기';

  @override
  String get pack_buru => '부루';

  @override
  String get pack_dugi => '두기';

  @override
  String get pack_rumi => '루미';

  @override
  String get pack_mongi => '몽지';

  @override
  String get pack_duru => '두루';

  @override
  String get pack_burumi => '부루와 미';

  @override
  String get dataInfo => '부루미가 쓰는 저장 공간과 사진·영상을 언제 받을지 정해요.';

  @override
  String get storageUsage => '저장 공간 사용량';

  @override
  String get storageApp => '대화와 설정';

  @override
  String get storageCache => '임시 파일';

  @override
  String get clearCache => '임시 파일 지우기';

  @override
  String get storageInfo => '대화는 지워지지 않아요. 임시 파일은 다시 열 때 새로 받아요.';

  @override
  String get storageWeb => '웹에서는 브라우저가 저장 공간을 관리해요.';

  @override
  String get autoDownload => '미디어 자동 다운로드';

  @override
  String get autoDlCell => '셀룰러 데이터 사용 시';

  @override
  String get autoDlWifi => 'Wi-Fi 사용 시';

  @override
  String get autoDownloadInfo => '끄면 사진을 누를 때 받아요. 절전 모드에서는 늘 누를 때 받아요.';

  @override
  String get autoplayGif => 'GIF 자동 재생';

  @override
  String get autoplayGifInfo => '끄면 GIF가 첫 장면에 멈춰 있어요.';

  @override
  String get powerJobs => '배터리를 많이 쓰는 기능';

  @override
  String get powerJobsInfo => '절전 모드가 켜지면 이 기능들이 잠시 꺼져요. 배터리가 충분하면 다시 켜져요.';

  @override
  String sizeBytes(int n) {
    return '$n B';
  }

  @override
  String get chatsInfo =>
      '메시지 보내는 방법, 답장, 빠른 답장 문구, 자리 비움 답장, 휴대폰 안에서만 도는 AI 기능을 정해요.';

  @override
  String get aiFeatures => 'AI 기능';

  @override
  String get scamWarning => '사기·피싱 링크 경고';

  @override
  String get scamWarningInfo =>
      '이상한 링크(가짜 주소, 숫자 주소, 줄인 주소)에 경고를 붙여요. 이 휴대폰 안에서만 확인하고, 메시지 내용은 어디로도 보내지 않아요.';

  @override
  String get scamLink => '주의: 의심스러운 링크예요';

  @override
  String get quickReplies => '빠른 답장 문구';

  @override
  String get quickRepliesInfo => '입력창의 문구 버튼을 누르면 고를 수 있어요. 최대 20개.';

  @override
  String get addQuickReply => '문구 추가';

  @override
  String get quickReplyHint => '예: 지금 회의 중이라 이따 연락할게요';

  @override
  String get awayReply => '자리 비움 답장';

  @override
  String get awayReplyInfo =>
      '켜 두면 1:1 대화에 새 메시지가 오면 이 문구로 한 번 답해요. 같은 사람에게는 6시간에 한 번만 보내요. 앱이 받을 때 이 휴대폰이 보내요.';

  @override
  String get awayReplyText => '답장 문구';

  @override
  String get awayReplyDefault => '지금은 자리에 없어요. 확인하면 답할게요.';

  @override
  String get awayTag => '자동 답장';

  @override
  String get editProfile => '프로필 편집';

  @override
  String get firstName => '이름';

  @override
  String get lastName => '성 (선택)';

  @override
  String get nameHint => '이름을 쓰고 사진을 넣으면 친구가 나를 알아보기 쉬워요.';

  @override
  String get newPhoto => '새 사진 설정';

  @override
  String get removePhoto => '사진 지우기';

  @override
  String get idInfo => '친구가 이 아이디로 나를 찾을 수 있어요. 누르면 복사돼요.';

  @override
  String get themeHiphopWhite => '힙합 흰색';

  @override
  String get themeHiphopDark => '힙합 어둡게';

  @override
  String get manageTools => '운영 도구';

  @override
  String get manageToolsInfo =>
      '관리자만 보는 화면이에요. 대화 내용은 서버로 보내지 않고 이 휴대폰에서 처리해요.';

  @override
  String get toolsJoin => '가입';

  @override
  String get toolsPosts => '글 관리';

  @override
  String get toolsStats => '기록과 통계';

  @override
  String get roomRules => '모임 규칙';

  @override
  String get roomRulesHint => '예: 1. 서로 존중해요\n2. 광고 금지\n3. 사진은 출처를 밝혀요';

  @override
  String get roomRulesInfo => '규칙은 들어오기 전에도 보여요. 비밀 내용은 쓰지 마세요.';

  @override
  String get rulesAgree => '규칙 동의 받기';

  @override
  String get rulesAgreeInfo => '새로 들어온 사람은 규칙에 동의해야 글을 쓸 수 있어요.';

  @override
  String get agreeRules => '규칙을 지킬게요';

  @override
  String get welcomeMessage => '환영 인사';

  @override
  String get welcomeHint => '예: 반가워요! 공지부터 한번 봐 주세요 😊';

  @override
  String get welcomeInfo => '새 멤버가 처음 들어왔을 때 한 번 보여요.';

  @override
  String get reactionsSetting => '반응';

  @override
  String get reactionsAll => '모든 반응';

  @override
  String get reactionsSome => '일부 반응';

  @override
  String get reactionsNone => '반응 없음';

  @override
  String get reactionsInfo => '구독자가 어떤 이모지로 반응할 수 있는지 정해요.';

  @override
  String get reactionsMax => '글마다 최대 반응 수';

  @override
  String get reactionsMaxInfo => '한 메시지에 붙을 수 있는 반응 종류의 수예요.';

  @override
  String get reactionsPick => '쓸 수 있는 반응';

  @override
  String get hideCounts => '반응·투표 숫자 숨기기';

  @override
  String get hideCountsInfo => '구독자에게는 숫자가 안 보여요. 관리자는 계속 볼 수 있어요.';

  @override
  String get autoMod => '자동 관리';

  @override
  String get autoModInfo =>
      '관리자 휴대폰이 규칙에 맞지 않는 글을 지워요. 서버는 대화 내용을 볼 수 없어서, 관리자 앱이 꺼져 있으면 조금 늦게 처리돼요.';

  @override
  String get bannedWords => '금지어';

  @override
  String get addBannedWord => '금지어 추가';

  @override
  String get bannedWordsInfo => '금지어가 들어간 메시지를 지워요. 금지어 목록은 이 휴대폰에만 있어요.';

  @override
  String get modRules => '규칙';

  @override
  String get modNewLinks => '새 멤버 링크 막기';

  @override
  String get modNewLinksInfo => '처음 본 지 24시간이 안 된 사람의 링크';

  @override
  String get modFlood => '도배 지우기';

  @override
  String get modFloodInfo => '10초 안에 메시지 5개 넘게';

  @override
  String get roomStats => '모임 통계';

  @override
  String get statsMembers => '멤버';

  @override
  String get statsPerDay => '하루 평균 메시지';

  @override
  String get statsActive => '30일 동안 글 쓴 사람';

  @override
  String get statsMessages30 => '최근 30일 메시지';

  @override
  String get statsHours => '활발한 시간대';

  @override
  String statsBusiest(String hour) {
    return '가장 활발한 시간: $hour시';
  }

  @override
  String get statsInfo =>
      '통계는 이 휴대폰에 있는 대화로 이 휴대폰이 계산해요. 서버로 보내지 않고, 사람별 숫자는 만들지 않아요.';

  @override
  String get modLog => '관리 기록';

  @override
  String get modLogEmpty => '아직 기록이 없어요';

  @override
  String get modLogInfo => '이 휴대폰에서 한 관리 일만 보여요. 최근 200개까지 남아요.';

  @override
  String logRemoved(String name, String why) {
    return '$name님의 메시지를 지움 ($why)';
  }

  @override
  String logBanned(String name) {
    return '$name님을 추방함';
  }

  @override
  String logUnbanned(String name) {
    return '$name님의 추방을 풂';
  }

  @override
  String logSetting(String what) {
    return '설정을 바꿈: $what';
  }

  @override
  String get whyWord => '금지어';

  @override
  String get whyLink => '새 멤버 링크';

  @override
  String get whyFlood => '도배';

  @override
  String get movingBoard => '이사 현황판';

  @override
  String get movingInfo => '옛 방에 몇 명이 있었는지 적으면 몇 명이 이사 왔는지 보여 드려요.';

  @override
  String get oldMembers => '옛 방 인원';

  @override
  String movedCount(String now, String old) {
    return '$now명 / $old명 이사 왔어요';
  }

  @override
  String get bannedUsers => '추방된 사용자';

  @override
  String get bannedEmpty => '추방된 사람이 없어요';

  @override
  String get unban => '추방 풀기';

  @override
  String get banMember => '추방';

  @override
  String get roomLevel => '레벨';

  @override
  String levelN(int n) {
    return '레벨 $n';
  }

  @override
  String levelNext(String members, String active, int days) {
    return '다음 레벨까지: 인원 $members명 · 활동 $active명 · $days일';
  }

  @override
  String get levelMax => '가장 높은 레벨이에요';

  @override
  String get levelInfo =>
      '레벨은 인원, 최근 4주 동안 글 쓴 사람, 방이 생긴 날로 정해요. 한 번 오른 레벨은 쉽게 내려가지 않아요. 지금은 이 휴대폰이 계산해서 보여 줘요.';

  @override
  String get chatThemeHere => '이 대화방 배경';

  @override
  String get chatThemeHereInfo => '내 휴대폰에서만 바뀌어요. 다른 사람의 배경은 바꾸지 않아요.';

  @override
  String get useDefault => '기본 설정 따르기';

  @override
  String get discussion => '토론';

  @override
  String get discussionInfo => '그룹을 연결하면 게시물마다 댓글 버튼이 생기고, 댓글은 그 그룹에 남아요.';

  @override
  String get discussionNone => '연결 안 함';

  @override
  String get comments => '댓글';

  @override
  String get deleteChannel => '채널 삭제';

  @override
  String get deleteGroup => '그룹 삭제';

  @override
  String get deleteRoomInfo => '모든 멤버를 내보내고 나도 나가요. 되돌릴 수 없어요.';

  @override
  String get deleteRoomConfirm => '정말 삭제할까요?';

  @override
  String get saveFailed => '저장하지 못했어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get rulesReadFirst => '규칙을 읽고 동의하면 글을 쓸 수 있어요';

  @override
  String get readRules => '규칙 보기';

  @override
  String get welcomeTitle => '환영해요';

  @override
  String get pollVoted => '투표했어요';

  @override
  String get hideCountsInfoGroup => '멤버에게는 숫자가 안 보여요. 관리자는 계속 볼 수 있어요.';

  @override
  String get pollQuizKind => '퀴즈';

  @override
  String get quizMode => '퀴즈 모드';

  @override
  String get quizModeInfo => '정답을 하나 정해요. 답한 사람은 바로 정답과 해설을 보고, 답은 바꿀 수 없어요.';

  @override
  String get quizPickAnswer => '동그라미를 눌러 정답을 골라 주세요';

  @override
  String get quizExplain => '해설 (선택)';

  @override
  String get quizRight => '정답이에요!';

  @override
  String get quizWrong => '아쉬워요, 정답이 아니에요';

  @override
  String get pollDeadline => '마감 시간';

  @override
  String get pollDeadlineNone => '없음';

  @override
  String get pollIn1h => '1시간 뒤';

  @override
  String get pollIn1d => '1일 뒤';

  @override
  String get pollIn3d => '3일 뒤';

  @override
  String get pollIn1w => '1주 뒤';

  @override
  String pollLeftMin(int min) {
    return '$min분 남음';
  }

  @override
  String pollLeftHours(int hours) {
    return '$hours시간 남음';
  }

  @override
  String pollLeftDays(int days) {
    return '$days일 남음';
  }

  @override
  String get pollDeadlineInfo => '마감 시간이 지나면 더 투표할 수 없어요.';

  @override
  String get cardLottery => '추첨';

  @override
  String get cardForm => '신청서';

  @override
  String get cardFaq => '자주 묻는 질문';

  @override
  String get cardGuide => '안내 메뉴';

  @override
  String get cardLinks => '링크 버튼';

  @override
  String get cardTemplates => '글 틀';

  @override
  String get cardAudio => '오디오';

  @override
  String get cardRich => '서식 글쓰기';

  @override
  String get cardCheckin => '안전 체크인';

  @override
  String get newLottery => '새 추첨';

  @override
  String get newForm => '새 신청서';

  @override
  String get newFaq => '자주 묻는 질문 만들기';

  @override
  String get newGuide => '안내 메뉴 만들기';

  @override
  String get newCheckin => '새 안전 체크인';

  @override
  String get cardTitleLabel => '제목';

  @override
  String get lotteryPrize => '상품';

  @override
  String get lotteryPrizeHint => '예: 커피 쿠폰 2장';

  @override
  String get lotteryPrizeInfo => '회원이 참여하기를 누르면 돼요. 마감되면 내 폰이 무작위로 당첨자를 뽑아요.';

  @override
  String get lotteryWinners => '당첨자 수';

  @override
  String get lotteryEnds => '마감';

  @override
  String get lotteryEndsManual => '직접 마감';

  @override
  String get lotteryAnnounce => '당첨자 이름 발표';

  @override
  String get lotteryAnnounceInfo => '끄면 당첨자 본인에게만 알려요. 명단은 나만 봐요.';

  @override
  String get lotteryInfo =>
      '구독자끼리는 누가 참여했는지 볼 수 없어요. 운영진은 당첨될 수 없어요. 추첨은 내 폰에서 하니 마감 뒤에 앱을 열어 주세요.';

  @override
  String get lotteryJoin => '참여하기';

  @override
  String get lotteryLeave => '참여 취소';

  @override
  String lotteryJoined(int n) {
    return '$n명 참여';
  }

  @override
  String get lotteryDraw => '추첨하기';

  @override
  String get lotteryWon => '당첨됐어요!';

  @override
  String lotteryWinnersN(int n) {
    return '당첨자 $n명';
  }

  @override
  String get lotteryNoWinner => '참여한 사람이 없어 당첨자가 없어요';

  @override
  String lotteryEndsAt(String when) {
    return '$when 마감';
  }

  @override
  String get lotteryDrawAsk => '지금 추첨할까요?';

  @override
  String get lotteryDrawInfo => '추첨하면 더는 참여할 수 없어요.';

  @override
  String get cardEnded => '마감됐어요';

  @override
  String get cardClose => '마감하기';

  @override
  String get cardCloseAsk => '지금 마감할까요?';

  @override
  String get cardCloseInfo => '마감하면 더는 답을 받지 않아요.';

  @override
  String get cardAnswers => '답 보기';

  @override
  String get cardNoAnswers => '아직 답이 없어요';

  @override
  String get cardAnswersInfo => '답은 이 휴대폰에만 있어요. 서버와 다른 멤버는 볼 수 없어요.';

  @override
  String get formTitleHint => '예: 12월 송년 산행 신청';

  @override
  String formQuestionN(int n) {
    return '질문 $n';
  }

  @override
  String get formQuestionHint => '질문을 써 주세요';

  @override
  String get formAnswerType => '답 종류';

  @override
  String get formShort => '짧은 답';

  @override
  String get formChoice => '고르기';

  @override
  String get formOptionsHint => '보기를 줄마다 하나씩 써 주세요';

  @override
  String get formAddQuestion => '질문 추가';

  @override
  String get formInfo => '답은 암호화돼서 나에게만 와요. 다른 멤버와 서버는 볼 수 없어요.';

  @override
  String get formFill => '작성하기';

  @override
  String get formSent => '보냈어요';

  @override
  String formSentN(int n) {
    return '$n명 보냄';
  }

  @override
  String formQuestionsN(int n) {
    return '질문 $n개';
  }

  @override
  String get formAnswerHint => '답을 써 주세요';

  @override
  String get formFillInfo => '답은 만든 사람에게만 가요. 다른 멤버는 볼 수 없어요.';

  @override
  String get faqQ => '질문';

  @override
  String get faqA => '답';

  @override
  String get faqInfo =>
      '멤버가 질문을 누르면 답이 펼쳐져요. 눌러도 아무것도 보내지 않아서 누가 무엇을 봤는지 아무도 몰라요.';

  @override
  String get guideTitleHint => '무엇을 도와드릴까요?';

  @override
  String get guideSubHint => '아래 버튼을 눌러 보세요 (선택)';

  @override
  String get guideButtons => '버튼';

  @override
  String get guideAddButton => '버튼 추가';

  @override
  String get guideLabel => '버튼 이름';

  @override
  String get guideText => '누르면 보여 줄 글';

  @override
  String get guideInfo =>
      '멤버가 버튼을 누르면 그 자리에서 다음 화면이 열려요. 눌러도 아무것도 보내지 않아서 누가 무엇을 봤는지 아무도 몰라요.';

  @override
  String get linksPreview => '미리보기';

  @override
  String get linksTextHint => '버튼 위에 쓸 글 (선택)';

  @override
  String get linksAddButton => '버튼 추가';

  @override
  String get linksAddRow => '줄 추가';

  @override
  String get linksIntro => '글 아래에 웹사이트로 가는 버튼을 붙여요.';

  @override
  String get linksInfo =>
      '버튼은 글과 함께 암호화돼요. 누가 눌렀는지는 아무도 알 수 없어요. 주소는 이 휴대폰 안에서 사기 링크인지 확인해요.';

  @override
  String linksLeft(int n) {
    return '버튼을 누르면 고칠 수 있어요. 버튼을 $n개 더 넣을 수 있어요.';
  }

  @override
  String linksEditing(String row, String col) {
    return '$row줄 $col번째 버튼 고치는 중';
  }

  @override
  String get linksLabel => '버튼 이름';

  @override
  String get linksColor => '이 버튼 색';

  @override
  String get linksColorInfo => '첫 번째 동그라미는 \'모든 버튼 꾸미기\'에서 고른 색을 따라가요.';

  @override
  String get linksRemove => '버튼 지우기';

  @override
  String get linksStyle => '모든 버튼 꾸미기';

  @override
  String get linksStyleColor => '색상';

  @override
  String get linksGlass => '유리 효과';

  @override
  String get linksSize => '크기';

  @override
  String get sizeSmall => '작게';

  @override
  String get sizeMedium => '보통';

  @override
  String get sizeLarge => '크게';

  @override
  String get linksShape => '모양';

  @override
  String get shapeRound => '둥글게';

  @override
  String get shapePill => '알약';

  @override
  String get shapeSquare => '네모';

  @override
  String get linksInk => '글씨 색';

  @override
  String get inkAuto => '자동';

  @override
  String get inkWhite => '흰색';

  @override
  String get inkBlack => '검은색';

  @override
  String get linksStyleInfo => '모든 버튼에 적용돼요. 버튼마다 색을 따로 정할 수도 있어요.';

  @override
  String get linksBadUrl => 'https:// 로 시작하는 웹 주소를 써 주세요';

  @override
  String get richTitleHint => '제목';

  @override
  String get richBodyHint => '무엇이든 써 보세요...';

  @override
  String get richHeading => '소제목';

  @override
  String get richList => '목록';

  @override
  String get richQuote => '인용';

  @override
  String get richLink => '링크';

  @override
  String get richLinkUrl => '링크 주소';

  @override
  String get checkinHint => '예: 지진이 났어요. 모두 괜찮아요?';

  @override
  String get checkinInfo => '멤버가 \'괜찮아요\' 또는 \'도움 필요해요\'를 눌러요. 답은 나에게만 와요.';

  @override
  String get checkinOk => '괜찮아요';

  @override
  String get checkinHelp => '도움 필요해요';

  @override
  String get templatesNew => '새 글 틀';

  @override
  String get templatesHint => '자주 쓰는 글을 써 두세요';

  @override
  String get templatesEmpty => '저장한 글 틀이 없어요';

  @override
  String get templatesInfo => '글 틀은 이 휴대폰에만 저장돼요. 누르면 입력창에 들어가요.';

  @override
  String get cardRemove => '지우기';

  @override
  String get attachPickAudio => '오디오 파일 고르기';

  @override
  String get attachAudioInfo => '음악·녹음 파일을 보내요. 받은 사람은 대화 안에서 바로 들을 수 있어요.';

  @override
  String get remindMe => '알림 받기';

  @override
  String get remindNote => '이 휴대폰에 알림이 와요. 서버로는 아무것도 보내지 않아요.';

  @override
  String get remindNoteWeb => '이 창이 열려 있을 때 알려 줘요. 서버로는 아무것도 보내지 않아요.';

  @override
  String get remindIn20 => '20분 뒤';

  @override
  String get remindIn1h => '1시간 뒤';

  @override
  String get remindIn3h => '3시간 뒤';

  @override
  String get remindTomorrow => '내일 오전 9시';

  @override
  String get remindPick => '날짜와 시간 고르기';

  @override
  String remindSet(String time) {
    return '알림 시간: $time';
  }

  @override
  String get remindDue => '알림 받기로 정한 메시지예요';

  @override
  String get remindChannel => '메시지 알림 받기';

  @override
  String get remindOn => '알림 정함';

  @override
  String get emergencyDelete => '비상 시 삭제';

  @override
  String get emergencyDeleteOff => '비상 시 삭제 취소';

  @override
  String get emergencyHideRoom => '이 대화방 비상 시 숨김';

  @override
  String get emergencyHideRoomOff => '비상 시 숨김 취소';

  @override
  String get emergencyMarked => '삭제 비밀번호로 열면 이 메시지가 지워져요';

  @override
  String get emergencyUnmarked => '비상 시 삭제에서 뺐어요';

  @override
  String get emergencyHidden => '숨김 비밀번호로 열면 이 대화방이 사라져요';

  @override
  String get emergencyUnhidden => '비상 시 숨김에서 뺐어요';

  @override
  String get emergencyWebInfo =>
      '앱 잠금과 비상 시 삭제·숨김은 휴대폰 앱에서만 설정할 수 있어요. 웹은 브라우저라 비밀을 안전하게 지킬 수 없어서예요.';

  @override
  String get emergencyBadge => '비상 시 삭제';

  @override
  String get selectMsg => '선택';

  @override
  String get okButton => '확인';

  @override
  String selectedN(int count) {
    return '$count개 선택됨';
  }

  @override
  String get selectCopy => '복사';

  @override
  String get selectSave => '저장';

  @override
  String get searchThisChat => '이 대화방에서 검색';

  @override
  String searchMsgCount(int count) {
    return '메시지 $count개';
  }

  @override
  String get searchAsList => '목록으로 보기';

  @override
  String get searchByDate => '날짜로 이동';

  @override
  String get searchFound => '검색 결과';

  @override
  String get searchNoneOnDate => '그날 이후 메시지가 없어요';

  @override
  String get savedToast => '저장한 메시지에 저장했어요';

  @override
  String get savedTagHint => '빠른 검색을 위해 메시지에 이모지를 태그해 보세요';

  @override
  String get tagMsg => '태그';

  @override
  String get tagRemove => '태그 빼기';

  @override
  String get tagAll => '전체';

  @override
  String get shareMsg => '공유';

  @override
  String get shareFailed => '공유하지 못했어요';

  @override
  String get voiceLockHint => '위로 밀면 잠금';

  @override
  String get voicePause => '일시 정지';

  @override
  String get voiceResume => '이어서 녹음';

  @override
  String get channelPostLoud => '알리기';

  @override
  String get channelPostSilent => '조용히 알리기';

  @override
  String get channelLoudOn => '구독자가 소리와 함께 알림을 받아요';

  @override
  String get channelSilentOn => '구독자가 소리 없이 알림을 받아요';

  @override
  String get encryption => '암호화';

  @override
  String get encVerified => '확인됨';

  @override
  String get encNotVerified => '확인 안 됨';

  @override
  String get encHeroTitle => '이 대화는 종단간 암호화되어 있어요';

  @override
  String get encHeroBody =>
      '메시지와 통화는 두 사람의 휴대폰에서만 열려요. 부루미 서버도 내용을 볼 수 없어요. 아래에서 상대 휴대폰이 진짜인지 확인할 수 있어요.';

  @override
  String get encMembers => '멤버';

  @override
  String get encStart => '확인 시작';

  @override
  String get encStartInfo =>
      '두 사람이 함께 있을 때 또는 통화하면서 해 보세요. 두 휴대폰에 같은 그림 7개가 나오면 진짜예요.';

  @override
  String get encShowKeys => '기기 키 보기 (고급)';

  @override
  String get encKeysInfo => '각 기기의 고유 열쇠 지문이에요. 상대 화면의 지문과 같으면 같은 기기예요.';

  @override
  String get encNoDevices => '아직 기기 정보를 받지 못했어요';

  @override
  String get verifyTitle => '보안 코드 확인';

  @override
  String get verifyWaiting => '상대 휴대폰에서 수락하기를 기다리고 있어요';

  @override
  String verifyIncoming(String name) {
    return '$name님이 서로의 보안 코드를 확인하자고 요청했어요';
  }

  @override
  String get verifyAccept => '수락';

  @override
  String get verifyDecline => '거절';

  @override
  String get verifyCompare => '두 휴대폰에 같은 그림이 같은 순서로 보이나요?';

  @override
  String get verifyMatch => '같아요';

  @override
  String get verifyNoMatch => '달라요';

  @override
  String get verifyWaitOther => '상대가 확인하기를 기다리고 있어요';

  @override
  String get verifyDone => '확인했어요. 이제 이 사람의 휴대폰을 믿을 수 있어요.';

  @override
  String get verifyCancelled => '확인이 취소됐어요';

  @override
  String get verifyFailed => '확인을 시작하지 못했어요';

  @override
  String get verifyRequestLine => '보안 코드 확인 요청';

  @override
  String get verifyOpen => '확인하기';

  @override
  String get close => '닫기';

  @override
  String get contactFirst => '이름';

  @override
  String get contactLast => '성';

  @override
  String get memoAdd => '메모 추가';

  @override
  String contactPhotoSet(String name) {
    return '$name님의 사진 설정';
  }

  @override
  String contactPhotoInfo(String name) {
    return '$name님이 정한 사진 대신 나에게만 보이는 사진이에요.';
  }

  @override
  String get contactPhotoRemove => '내가 정한 사진 지우기';

  @override
  String get msgInfo => '메시지 정보';

  @override
  String get msgReport => '메시지 신고';

  @override
  String get reportNote =>
      '운영자가 이 글을 봐요. 신고하면 이 메시지 내용이 함께 보내져요. 다른 메시지는 보내지 않아요.';

  @override
  String get reportSpam => '스팸';

  @override
  String get reportScam => '사기';

  @override
  String get reportViolence => '폭력이나 위협';

  @override
  String get reportSexual => '음란물';

  @override
  String get reportChild => '아동 학대';

  @override
  String get reportDrugs => '불법 약물';

  @override
  String get reportPrivacy => '개인정보 노출';

  @override
  String get reportOther => '기타';

  @override
  String get reportDone => '신고했어요. 운영자가 확인할게요.';

  @override
  String get reportFailed => '신고하지 못했어요. 다시 해 주세요.';

  @override
  String get infoSent => '보낸 시간';

  @override
  String get infoStatus => '상태';

  @override
  String get infoRead => '읽음';

  @override
  String get infoSentOnly => '보냄';

  @override
  String get infoExpires => '사라지는 시간';

  @override
  String get threadReply => '스레드로 답장';

  @override
  String get threadTitle => '스레드';

  @override
  String threadReplies(int count) {
    return '답글 $count개';
  }

  @override
  String get threadPlaceholder => '스레드에 답장';

  @override
  String get threadEmpty => '아직 답글이 없어요';

  @override
  String get packDynamic => '묶음 정렬 유연하게';

  @override
  String get packDynamicInfo => '최근에 쓴 스티커 묶음이 앞에 나와요.';

  @override
  String get packOrderInfo =>
      '오른쪽 줄 세 개를 끌어서 순서를 바꿔요. 끈 묶음은 스티커 칸에서 빠지고, 받은 스티커는 그대로 보여요.';

  @override
  String get attachFromGallery => '갤러리에서 선택';

  @override
  String get attachFromFiles => '파일에서 선택';

  @override
  String get recentSentFiles => '최근에 보낸 파일';

  @override
  String get photoTooBig => '사진이 너무 커요. 더 작은 사진을 골라 주세요.';

  @override
  String savedChatsCount(int n) {
    return '$n개 대화';
  }

  @override
  String get savedAll => '모든 메시지';

  @override
  String get savedNotes => '내 노트';

  @override
  String get savedOpenChat => '대화 열기';

  @override
  String get savedSearchHint => '메시지 또는 태그 검색';

  @override
  String get savedSide => '대화별로 보기';

  @override
  String get savedSearchList => '검색';

  @override
  String get savedNoMore => '더 이상 결과가 없어요';

  @override
  String get mediaZoomIn => '확대';

  @override
  String get mediaZoomOut => '축소';

  @override
  String get mediaCalendar => '달력 보기';

  @override
  String get mediaPhotos => '사진 보기';

  @override
  String get mediaVideos => '동영상 보기';

  @override
  String get savedLinkTag => '링크';

  @override
  String get markAllRead => '모두 읽음';

  @override
  String get archiveShort => '보관';

  @override
  String get chatLocked => '끝까지 잠김';

  @override
  String get storyMine => '내 스토리';

  @override
  String get storyReplyPrefix => '스토리에 답장:';

  @override
  String get storyReplied => '답장을 보냈어요';

  @override
  String get storyReplyHint => '답장 보내기…';

  @override
  String get storyPrivateNote => '친구에게만 24시간 보여요 · 본 사람 기록 없음';

  @override
  String get storyNow => '방금';

  @override
  String storyMinutes(int n) {
    return '$n분';
  }

  @override
  String storyHours(int n) {
    return '$n시간';
  }

  @override
  String get storyHint => '사진을 찍거나 고르세요';

  @override
  String get storyCaptionHint => '글 넣기';

  @override
  String get storyShare => '친구에게 공유';

  @override
  String storyShared(int n) {
    return '친구 $n명에게 공유했어요';
  }

  @override
  String get storyNoFriends => '보낼 친구가 아직 없어요';

  @override
  String get storyCamera => '스토리 카메라';

  @override
  String get camLive => '라이브';

  @override
  String get camVideo => '영상';

  @override
  String get camPhoto => '사진';

  @override
  String get camLiveStart => '실시간 방송 시작';

  @override
  String get camLiveLater => '실시간 방송은 우리 서버가 준비되면 열려요';

  @override
  String get camGridRemove => '탭하여 그리드 제거';

  @override
  String get camUnavailable => '카메라를 켤 수 없어요\n아래 버튼을 누르면 휴대폰 카메라로 찍어요';

  @override
  String get camDualHint => '뒤 카메라, 앞 카메라 순서로 바로 이어 찍어요';

  @override
  String camGridLeft(int n) {
    return '$n장 더 찍어요';
  }

  @override
  String storiesCount(int n) {
    return '스토리 $n개';
  }

  @override
  String get tabGroups => '그룹';

  @override
  String get noCommonGroups => '같이 있는 그룹이 없어요';

  @override
  String get qrCode => 'QR 코드';

  @override
  String get wideEmpty => '대화를 골라요';

  @override
  String get storyAnswerSent => '보냈어요. 1:1 대화로 갔어요';

  @override
  String get storyAnswerHint => '답 쓰기';

  @override
  String get storyGoing => '갈래요';

  @override
  String get storyGoingSent => '갈게요라고 보냈어요';

  @override
  String get storyPoll => '투표';

  @override
  String get storyQuestion => '질문';

  @override
  String get storyPlan => '일정';

  @override
  String get storyPlanTitle => '무엇을 해요? (예: 토요일 사진전)';

  @override
  String get storyAskHint => '물어볼 말';

  @override
  String get storyPollInfo => '답은 각자 1:1 대화로 와요. 다른 친구도, 부루미도 누가 무엇을 골랐는지 몰라요.';

  @override
  String storyOption(int n) {
    return '선택 $n';
  }

  @override
  String get storyPlanWhen => '언제 (예: 토요일 오후 3시)';

  @override
  String get storyPlanPlace => '어디서 (선택)';

  @override
  String get storyPlanInfo => '친구가 \"갈래요\"를 누르면 1:1 대화로 알려 줘요.';

  @override
  String get storyQuestionInfo => '답은 1:1 대화로 와요. 나만 봐요.';

  @override
  String get storyAllFriends => '모든 친구';

  @override
  String get storyCloseFriends => '친한 친구';

  @override
  String get storyPicked => '이번만 고르기';

  @override
  String storyPickedCount(int n) {
    return '$n명';
  }

  @override
  String storyAllFriendsSub(int n) {
    return '1:1 대화 친구 $n명';
  }

  @override
  String storyCloseFriendsSub(int n) {
    return '$n명 · 이 휴대폰에만 저장돼요';
  }

  @override
  String get storyPickedSub => '이 스토리만 볼 사람을 골라요';

  @override
  String get storyWho => '누가 볼까요?';

  @override
  String get storyWhoInfo => '고른 친구에게만 그 대화의 암호로 잠겨서 가요. 서버는 누가 받았는지 알 수 없어요.';

  @override
  String get storyHowLong => '얼마나 보여 줄까요?';

  @override
  String get storyHowLongInfo => '시간이 지나면 친구 휴대폰과 서버에서 사라져요.';

  @override
  String storyHoursN(int n) {
    return '$n시간';
  }

  @override
  String get storyArchive => '내 스토리 보관함';

  @override
  String get storyArchiveEmpty => '아직 없어요. 스토리를 올리면 이 휴대폰에만 보관돼요.';

  @override
  String get storyArchiveWeb => '웹에서는 보관하지 않아요. 휴대폰 앱에서 볼 수 있어요.';

  @override
  String get storyArchiveInfo => '이 휴대폰에만 있어요. 누르면 다시 올리고, 길게 누르면 지워요.';

  @override
  String get storyNew => '새 스토리';

  @override
  String get feedTitle => '친구 피드';

  @override
  String get feedEmpty => '아직 게시물이 없어요';

  @override
  String get feedInfo => '1:1 친구에게만 보여요. 광고 없이, 끝까지 잠겨서 가요.';

  @override
  String get feedNew => '새 게시물';

  @override
  String get feedHint => '무슨 일이 있었나요?';

  @override
  String get feedPost => '올리기';

  @override
  String get feedAddPhoto => '사진';

  @override
  String get feedRemovePhoto => '사진 빼기';

  @override
  String feedLikesN(int n) {
    return '좋아요 $n명';
  }

  @override
  String get feedOnlyMe => '나만 보여요';

  @override
  String get feedReplyHint => '답장은 이 친구에게만 가요';

  @override
  String get feedReplyPrefix => '💬 게시물에 답장:';

  @override
  String feedPosted(int n) {
    return '친구 $n명에게 올렸어요';
  }

  @override
  String get feedDeleted => '게시물을 지웠어요';

  @override
  String get feedLike => '좋아요';

  @override
  String get feedReply => '답장';

  @override
  String get markUnread => '읽지 않음으로 표시';

  @override
  String get addToFolder => '폴더에 추가';

  @override
  String removeFromFolder(String name) {
    return '$name 폴더에서 빼기';
  }

  @override
  String get blockShort => '차단';

  @override
  String get emergencyDeleteRoom => '이 대화방 비상 시 삭제';

  @override
  String get emergencyRoomMarked => '삭제 비밀번호로 열면 이 대화방이 지워져요';

  @override
  String get folderAddedTo => '폴더에 넣었어요';

  @override
  String get noFoldersYet => '아직 폴더가 없어요';

  @override
  String get swipePin => '고정';

  @override
  String get swipeUnpin => '고정 해제';

  @override
  String get swipeMute => '알림 끔';

  @override
  String get swipeUnmute => '알림 켬';

  @override
  String get swipeArchive => '보관';

  @override
  String get swipeUnarchive => '보관 해제';

  @override
  String get chatsHeaderInfo =>
      '메시지 표시 방법, 답장, 스티커와 이모지, 이 휴대폰 안에서만 처리되는 AI 기능처럼 대화방에서 쓰는 기능을 정해요.';

  @override
  String get faqHeaderInfo =>
      '부루미를 쓰면서 자주 궁금해하는 내용을 모았어요. 인터넷에 연결되지 않아도 볼 수 있어요.';

  @override
  String get devicesHeaderInfo =>
      '내 계정에 로그인된 기기를 모두 볼 수 있어요. 모르는 기기가 있으면 여기서 바로 로그아웃시킬 수 있어요.';

  @override
  String get languageHeaderInfo =>
      '앱에 보이는 말을 골라요. 다른 언어로 온 메시지는 대화방에서 바로 번역할 수 있어요.';

  @override
  String get stickersHeaderInfo =>
      '빠른 반응, 큰 이모지, 스티커 팩 순서처럼 스티커와 이모지를 쓰는 방법을 정해요.';

  @override
  String get birthday => '생일';

  @override
  String get birthdayAdd => '추가';

  @override
  String get birthdayInfo => '친구에게는 월과 일만 보여요. 누가 볼지는 설정 > 개인정보 및 보안에서 정해요.';

  @override
  String get birthdayRemove => '생일 지우기';

  @override
  String birthdayMonthDay(int m, int d) {
    return '$m월 $d일';
  }

  @override
  String get whoPhoto => '프로필 사진';

  @override
  String get whoBio => '자기소개';

  @override
  String get whoBirthday => '생일';

  @override
  String get whoLastSeen => '마지막 접속 및 온라인';

  @override
  String get whoForwards => '전달된 메시지';

  @override
  String get whoAlwaysNobody => '아무도';

  @override
  String get whoCardInfo => '\'내 연락처\'는 서버에 올라가지 않고, 1:1 대화의 암호화로만 친구에게 전달돼요.';

  @override
  String get lastSeenInfo =>
      '부루미는 접속 중인지, 마지막으로 언제 접속했는지 누구에게도 보여 주지 않아요. 처음부터 그렇게 만들어서 바꿀 필요가 없어요.';

  @override
  String get forwardsInfo =>
      '누가 내 메시지를 전달해도 내 이름과 원래 대화방은 함께 가지 않아요. \'전달됨\' 표시만 붙어요. 처음부터 그렇게 만들었어요.';

  @override
  String get editHistory => '내 수정 기록 숨기기';

  @override
  String get editHistoryAlways => '항상';

  @override
  String get editHistoryInfo =>
      '내가 고친 메시지는 다른 사람에게 마지막 내용만 보여요. 부루미는 처음부터 고치기 전 내용을 보여 주지 않아요.';

  @override
  String get birthdayAlert => '생일 알림';

  @override
  String get birthdayAlertInfo =>
      '생일을 공개한 친구의 생일 당일 오전 9시에 알려 드려요. 이 휴대폰 안에서만 알려요.';

  @override
  String birthdayAlertTitle(String name) {
    return '오늘은 $name 님의 생일이에요';
  }

  @override
  String get birthdayAlertBody => '축하 메시지를 보내 보세요.';

  @override
  String get showErrors => '오류 내용 보기';

  @override
  String get showErrorsInfo =>
      '켜면 문제가 생겼을 때의 오류 내용을 이 휴대폰에 모아 보여 줘요. 문의할 때 복사해서 보내면 도움이 돼요. 메시지 내용은 담기지 않아요.';

  @override
  String get errorLog => '오류 기록';

  @override
  String get errorLogEmpty => '아직 오류가 없어요';

  @override
  String get errorLogCopy => '모두 복사';

  @override
  String get autoDeleteHeader => '자동 회원 탈퇴';

  @override
  String get autoDeleteRow => '다음 기간 동안 미접속 시';

  @override
  String get autoDeleteInfo =>
      '이 기간 안에 한 번이라도 접속하지 않으면 모든 그룹, 메시지, 연락처와 함께 계정이 삭제돼요.';

  @override
  String get months1 => '1개월';

  @override
  String get months3 => '3개월';

  @override
  String get months6 => '6개월';

  @override
  String get months12 => '12개월';

  @override
  String get months18 => '18개월';

  @override
  String get hideDeleteRow => '숨김·삭제 비밀번호';

  @override
  String get privMessages => '메시지';

  @override
  String get privWhoSees => '누가 내 정보를 볼 수 있나요';

  @override
  String get privWhoReach => '누가 나에게 연락할 수 있나요';

  @override
  String get privScreen => '화면 보호';

  @override
  String get privAccount => '계정';

  @override
  String get undoSendSub => '보낸 뒤 5초 안에는 취소할 수 있어요';

  @override
  String get sendReadSub => '끄면 상대에게 내 읽음 표시가 가지 않아요';

  @override
  String get sendTypingSub => '끄면 상대에게 입력 중 표시가 가지 않아요';

  @override
  String get veilAllSub => '누르고 있는 동안만 메시지가 보여요';

  @override
  String get panicSub => '두 손가락으로 두 번 톡톡 치면 바로 잠겨요';

  @override
  String get birthdayAlertSub => '친구 생일 아침 9시에 이 휴대폰이 알려 줘요';

  @override
  String get showErrorsSub => '문의할 때 보낼 오류 내용을 이 휴대폰에 모아요';

  @override
  String get autoDeleteSub => '이 기간 동안 한 번도 접속하지 않으면 계정이 지워져요';

  @override
  String get autoDlPhotosSub => '사진을 미리 받아 둬요';

  @override
  String get autoDlReset => '자동 다운로드 설정 되돌리기';

  @override
  String get mediaAndLinks => '미디어와 링크';

  @override
  String get autoplayGifSub => '끄면 GIF가 첫 장면에 멈춰 있어요';

  @override
  String get linkPreviewSub => '보낼 때 내 휴대폰이 제목과 사진을 넣어요';

  @override
  String get callsHeader => '통화';

  @override
  String get lowDataCalls => '전화에 데이터 적게 쓰기';

  @override
  String get lowDataCallsSub => '영상 화질을 낮춰 느린 인터넷에서도 잘 이어져요';

  @override
  String get devicesArtInfo => 'PC나 다른 휴대폰에서도 대화를 이어 볼 수 있어요.';

  @override
  String get addDevice => '기기 추가';

  @override
  String get addDeviceTitle => '다른 기기에서 쓰기';

  @override
  String get addDeviceStep1 => '새 기기에 부루미를 설치해요. PC는 Windows 앱이 있어요.';

  @override
  String get addDeviceStep2 => '내 아이디와 비밀번호로 로그인해요.';

  @override
  String get addDeviceStep3 =>
      '이 휴대폰에 뜨는 확인 요청에서 두 기기의 이모지가 같은지 보면 끝이에요. 그러면 지난 대화도 열려요.';

  @override
  String get devicesPlatforms => '부루미는 iPhone, Android, Windows에서 쓸 수 있어요.';

  @override
  String get onlineNow => '지금 사용 중';

  @override
  String get chatFolders => '대화방 폴더';

  @override
  String get foldersArtInfo =>
      '폴더를 만들어 대화방을 나눠 보세요. 목록 위나 왼쪽 메뉴에서 바로 바꿀 수 있어요.';

  @override
  String get createFolder => '폴더 만들기';

  @override
  String get allChatsFolder => '모든 대화방';

  @override
  String get editList => '편집';

  @override
  String get foldersEditInfo => '편집을 누르면 폴더 순서를 바꾸거나 지울 수 있어요.';

  @override
  String get recommendedFolders => '추천 폴더';

  @override
  String get folderUnreadName => '안 읽음';

  @override
  String get folderUnreadInfo => '안 읽은 메시지가 있는 대화방';

  @override
  String get folderPersonalName => '개인';

  @override
  String get folderPersonalInfo => '1:1 대화방만';

  @override
  String get folderTags => '폴더 태그 표시';

  @override
  String get folderTagsInfo => '대화 목록에서 각 대화방 아래에 폴더 이름을 색깔 태그로 보여 줘요.';

  @override
  String folderChatsCount(int n) {
    return '대화방 $n개';
  }

  @override
  String get folderDeleted => '폴더를 지웠어요';

  @override
  String get folderInclude => '포함할 대화방';

  @override
  String get folderIncludeInfo => '이 폴더에 보일 대화방이나 대화방 유형을 고르세요.';

  @override
  String get folderExclude => '제외할 대화방';

  @override
  String get folderExcludeInfo => '이 폴더에 절대 보이지 않을 대화방이나 유형을 고르세요.';

  @override
  String get folderAddChats => '대화방 추가';

  @override
  String get folderColor => '폴더 색상';

  @override
  String get folderNoTag => '태그 없음';

  @override
  String get folderColorInfo => '대화 목록에서 이 폴더 태그의 색이에요.';

  @override
  String get folderNeedChats => '대화방을 하나 이상 넣어 주세요.';

  @override
  String get folderNeedName => '폴더 이름을 적어 주세요.';

  @override
  String get chatTypes => '대화방 유형';

  @override
  String get chatsHeader => '대화방';

  @override
  String get kindContacts => '연락처';

  @override
  String get kindNonContacts => '연락처 아닌 사람';

  @override
  String get kindMuted => '알림 꺼짐';

  @override
  String get kindRead => '읽음';

  @override
  String get kindArchived => '보관됨';

  @override
  String get folderIcon => '폴더 아이콘';

  @override
  String get folderIconNone => '없음';

  @override
  String get newFolderTitle => '새 폴더';

  @override
  String exceptionsCount(int n) {
    return '$n개 예외';
  }

  @override
  String get inAppHeader => '앱 사용 중 알림';

  @override
  String get inAppVibrate => '앱 사용 중 진동';

  @override
  String get lockName => '잠금 화면에 이름 보이기';

  @override
  String get lockNameInfo =>
      '끄면 휴대폰이 잠겨 있을 때 알림에 보낸 사람 이름과 내용이 가려져요. 아이폰은 iOS 설정 > 알림 > 미리보기 표시도 함께 확인해 주세요.';

  @override
  String get linkOpenTitle => '링크 열기';

  @override
  String get linkOpenHeader => '링크를 여는 곳';

  @override
  String get linkOpenInApp => '부루미 안에서 (개인정보 보호 창)';

  @override
  String get linkOpenBrowser => '기본 브라우저';

  @override
  String get linkOpenInAppShort => '부루미';

  @override
  String get linkOpenBrowserShort => '브라우저';

  @override
  String get linkOpenInfo => '부루미 안에서 열면 앱을 떠나지 않고, 다른 브라우저의 기록에도 남지 않아요.';

  @override
  String get linkNeverHeader => '앱 안에서 열지 않기';

  @override
  String get linkNeverAdd => '웹사이트 추가';

  @override
  String get linkNeverInfo => '이 웹사이트들은 언제나 기본 브라우저에서 열려요.';

  @override
  String get tiltMove => '기울이면 움직이기';

  @override
  String get tiltInfo => '휴대폰을 기울이면 대화 배경이 살짝 움직여요. 배터리를 조금 더 써요.';

  @override
  String get appIcon => '앱 아이콘';

  @override
  String get appIconInfo => '홈 화면의 부루미 아이콘 모양을 바꿔요. 바꿀 때 앱이 잠깐 닫힐 수 있어요.';

  @override
  String get appIconGreen => '기본';

  @override
  String get appIconDark => '다크';

  @override
  String get appIconLight => '화이트';

  @override
  String get appIconMint => '세이지';

  @override
  String get psGlass => '유리 효과';

  @override
  String get psGlassSub => '끄면 위·아래 바가 비치지 않는 판으로 보여요.';

  @override
  String get psPreload => '미디어 미리 받기';

  @override
  String get psPreloadSub => '사진·영상을 열기 전에 미리 받아 둬요.';

  @override
  String get psTiltSub => '휴대폰을 기울이면 대화 배경이 움직여요.';

  @override
  String get chatsMessages => '메시지';

  @override
  String get chatsList => '대화 목록';

  @override
  String get chatsMediaReactions => '미디어와 반응';

  @override
  String get formattingRow => '형식이 지정된 메시지';

  @override
  String get formattingSub => '굵게 같은 서식을 메시지에 보여 줘요';

  @override
  String get listMedia => '사진·동영상 미리보기 보이기';

  @override
  String get listMediaSub => '대화 목록에 마지막 사진을 작게 보여 줘요';

  @override
  String get scamWarningSub => '이상한 링크에 경고를 붙여요';

  @override
  String get planPick => '일정 뽑기';

  @override
  String get planPickSub => '메시지 속 날짜·시간을 누르면 알림을 맞춰요';

  @override
  String get aiOnPhoneInfo => '모두 이 휴대폰 안에서만 처리돼요. 메시지 내용은 어디로도 보내지 않아요.';

  @override
  String planFound(String when) {
    return '일정: $when';
  }

  @override
  String get planHourBefore => '1시간 전에 알림';

  @override
  String get planAtTime => '그 시각에 알림';
}
