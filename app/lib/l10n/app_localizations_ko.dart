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
  String copyCodeButton(String code) {
    return '코드 복사 · $code';
  }

  @override
  String get codeCopied => '코드를 복사했어요. 1분 뒤 지워져요.';

  @override
  String codeCopyFailed(String code) {
    return '복사하지 못했어요. 코드: $code';
  }

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
      '1:1 대화에서 둘 다 3일 넘게 매일 메시지를 보내면 이름 옆에 불꽃이 생겨요. 그룹은 매일 멤버 절반(2~5명) 이상이 말하면 생겨요. 계산은 휴대폰 안에서만 해요.';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '멤버 $countString명';
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
  String get codeBlockCopied => '코드를 복사했어요';

  @override
  String get codeBlockCopy => '코드 복사';

  @override
  String get dateMarkAdd => '날짜 넣기';

  @override
  String get dateMarkTime => '시간';

  @override
  String get fmtDate => '날짜';

  @override
  String get dateCopy => '날짜 복사';

  @override
  String get dateCopied => '날짜를 복사했어요';

  @override
  String get dateToCalendar => '캘린더에 추가';

  @override
  String get dateRemind => '알림 설정';

  @override
  String dateInMyZone(String zone) {
    return '내 시간대($zone) 기준이에요';
  }

  @override
  String get dateCalendarFailed => '캘린더를 열지 못했어요';

  @override
  String get tomorrow => '내일';

  @override
  String sendAtTime(String date, String time) {
    return '$date $time에 보내기';
  }

  @override
  String get scheduleTitle => '메시지 예약';

  @override
  String get reschedule => '시간 바꾸기';

  @override
  String get scheduledTitle => '예약된 메시지';

  @override
  String get scheduledEmpty => '예약된 메시지가 없어요';

  @override
  String scheduledFor(String date) {
    return '$date에 보낼 메시지';
  }

  @override
  String scheduledDeleted(int left) {
    return '$left초 뒤 예약을 지워요';
  }

  @override
  String get linkOptionsTitle => '링크 미리보기 설정';

  @override
  String get linkOptionsPick => '링크를 누르면 그 링크로 미리보기를 만들어요';

  @override
  String get replyOptionsTitle => '답장 설정';

  @override
  String get linkMoveUp => '위로 옮기기';

  @override
  String get linkMoveDown => '아래로 옮기기';

  @override
  String get linkPhotoSmall => '사진 작게';

  @override
  String get linkPhotoBig => '사진 크게';

  @override
  String get applyChanges => '적용';

  @override
  String get linkNoPreview => '미리보기 안 함';

  @override
  String get tabReply => '답장';

  @override
  String get tabLink => '링크';

  @override
  String get linkBarLoading => '미리보기를 만드는 중이에요';

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
  String get stickerRecent => '최근 사용';

  @override
  String get stickerPhrases => '빠른 답장 문구';

  @override
  String get stickerNone => '맞는 스티커가 없어요';

  @override
  String get segStickers => '스티커';

  @override
  String get segEmoji => '이모지';

  @override
  String get emoji_smileys => '스마일리 및 사람';

  @override
  String get emoji_people => '손과 사람';

  @override
  String get emoji_animals => '동물 및 자연';

  @override
  String get emoji_food => '음식 및 음료';

  @override
  String get emoji_activity => '활동';

  @override
  String get emoji_travel => '여행 및 장소';

  @override
  String get emoji_objects => '사물';

  @override
  String get emoji_symbols => '기호';

  @override
  String get stickerTileMake => '스티커\n만들기';

  @override
  String get stickerMine => '내 스티커';

  @override
  String get emojiNone => '맞는 이모지가 없어요';

  @override
  String get emojiPickTitle => '이모지 고르기';

  @override
  String get emojiSearchHint => '하트, 웃음, 축하처럼 찾아요';

  @override
  String get emojiSetStatus => '상태로';

  @override
  String get reactAllEmoji => '모든 이모지';

  @override
  String get suggestEmoji => '단어로 이모지 추천';

  @override
  String get suggestStickers => '이모지로 스티커 추천';

  @override
  String get suggestInfo =>
      '입력창에 \':웃음\'처럼 쓰면 이모지가, 이모지 하나만 쓰면 어울리는 스티커가 위에 나와요. 모두 이 폰 안에서만 찾아요.';

  @override
  String get setsTitle => '내 스티커 묶음';

  @override
  String get setsHeader =>
      '내가 만든 스티커로 묶음을 만들어 친구와 나눠요. 그림은 암호화된 채로만 오가서 서버도 볼 수 없어요.';

  @override
  String get setsMakeInfo => '묶음 하나에 스티커를 50개까지 넣을 수 있어요.';

  @override
  String get setsNew => '새 묶음 만들기';

  @override
  String get setsAdded => '추가한 묶음';

  @override
  String get setsBrowse => '스티커 묶음 둘러보기';

  @override
  String get setsBurumyPacks => '부루미 스티커';

  @override
  String get setsBurumyInfo => '끈 묶음은 스티커 창에 나오지 않아요.';

  @override
  String get setsSeen => '대화에서 본 묶음';

  @override
  String get setsSeenInfo =>
      '친구들이 대화에 보낸 묶음이에요. 많이 본 순서로 보여요. 이 목록은 이 폰에만 있어요.';

  @override
  String get setsSeenNone => '친구가 대화에 묶음을 보내면 여기에 모여요.';

  @override
  String setSeenCount(int n, int times) {
    return '스티커 $n개 · $times번 봤어요';
  }

  @override
  String get setEdit => '묶음 고치기';

  @override
  String get setName => '묶음 이름';

  @override
  String get setNameHint => '예: 우리 강아지';

  @override
  String get setNameNeeded => '묶음 이름을 써 주세요';

  @override
  String setStickers(int n, int max) {
    return '스티커 $n/$max';
  }

  @override
  String get setEmpty => '스티커를 하나 이상 넣어 주세요';

  @override
  String get setOrderInfo =>
      '스티커를 누르면 순서를 바꾸거나 이모지를 정할 수 있어요. 이모지를 정하면 입력창에 그 이모지를 쓸 때 추천돼요.';

  @override
  String get setItemEmoji => '이모지 정하기';

  @override
  String setItemEmojiNow(String emoji) {
    return '이모지 바꾸기 ($emoji)';
  }

  @override
  String get setItemFirst => '맨 앞으로';

  @override
  String get setItemLeft => '앞으로';

  @override
  String get setItemRight => '뒤로';

  @override
  String get setItemRemove => '묶음에서 빼기';

  @override
  String get setPickTitle => '스티커 고르기';

  @override
  String setPicked(int n) {
    return '$n개 골랐어요';
  }

  @override
  String get setShare => '묶음 나누기';

  @override
  String get setShareInfo => '대화에 보내거나 링크로 나눠요. 받은 사람은 그대로 추가해 쓸 수 있어요.';

  @override
  String get setShareSheetInfo =>
      '묶음은 이 폰에서 암호화돼 올라가요. 열쇠는 대화나 링크 안에만 있어서 서버는 그림도 이름도 볼 수 없어요.';

  @override
  String get setShareToChat => '대화에 보내기';

  @override
  String get setCopyLink => '링크 복사';

  @override
  String get setSent => '묶음을 보냈어요';

  @override
  String get setLinkCopied => '링크를 복사했어요';

  @override
  String get setDelete => '묶음 지우기';

  @override
  String get setDeleteInfo => '이 폰에서 묶음을 지워요. 이미 나눈 링크로는 계속 열 수 있어요.';

  @override
  String get setOpenFailed => '묶음을 열 수 없어요. 링크가 잘렸거나 지워진 묶음일 수 있어요.';

  @override
  String get setPrivateInfo => '이 묶음은 암호화된 채로만 오갔어요. 서버는 누가 어떤 묶음을 쓰는지 몰라요.';

  @override
  String setAddCount(int n) {
    return '스티커 $n개 추가하기';
  }

  @override
  String setRemove(int n) {
    return '묶음 빼기 ($n개)';
  }

  @override
  String setAdded(String name) {
    return '\'$name\' 묶음을 추가했어요';
  }

  @override
  String get setRemoved => '묶음을 뺐어요';

  @override
  String get setAddShort => '추가';

  @override
  String get setAddedShort => '추가됨';

  @override
  String get setCardKind => '스티커 묶음';

  @override
  String get setCardView => '보기';

  @override
  String get setCardHave => '추가됨 · 보기';

  @override
  String get statusTitle => '이모지 상태';

  @override
  String get statusInfo =>
      '이름 옆에 지금 상태를 이모지로 보여줘요. 1:1 대화를 하는 친구에게만 암호화돼 전해져요.';

  @override
  String get statusOther => '다른 이모지 고르기';

  @override
  String get statusClear => '상태 지우기';

  @override
  String get statusCleared => '상태를 지웠어요';

  @override
  String get statusHowLong => '얼마 동안 보여줄까요?';

  @override
  String get statusFor1h => '1시간';

  @override
  String get statusFor2h => '2시간';

  @override
  String get statusFor8h => '8시간';

  @override
  String get statusFor2d => '2일';

  @override
  String get statusForEver => '직접 지울 때까지';

  @override
  String statusSet(String emoji) {
    return '$emoji 상태를 달았어요';
  }

  @override
  String get statusRow => '이모지 상태';

  @override
  String get stickerMakeTitle => '스티커 만들기';

  @override
  String get stickerMakeCut => '오려내기';

  @override
  String get stickerMakeOutline => '흰 테두리';

  @override
  String get stickerMakeText => '글자 넣기';

  @override
  String get stickerMakeRound => '둥근 네모';

  @override
  String get stickerMakeCircle => '동그라미';

  @override
  String get stickerMakeWorking => '오려내는 중…';

  @override
  String get stickerMakeInfo => '사진은 이 휴대폰 안에서만 처리돼요. 눌러서 다른 사진을 골라요.';

  @override
  String get stickerMakeNoCut => '이 기기에서는 자동으로 오려낼 수 없어서 사진을 모양 안에 넣었어요.';

  @override
  String get stickerTileBubble => '비눗방울\n보내기';

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
  String get onceOnInfo => '한 번만 볼 수 있고, 24시간 안에 안 열면 사라져요';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '구독자 $countString명';
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
  String get feedbackTitle => '버그·제안 보내기';

  @override
  String get feedbackHeader =>
      '고장 난 곳이나 바라는 기능을 알려 주세요. 운영팀이 직접 읽고, 고친 소식은 부루미 소식 채널에 올려요.';

  @override
  String get feedbackBug => '버그';

  @override
  String get feedbackIdea => '제안';

  @override
  String get feedbackWhat => '내용';

  @override
  String get feedbackSubject => '한 줄 요약';

  @override
  String get feedbackBodyBug => '무엇을 했더니 어떻게 됐나요?';

  @override
  String get feedbackBodyIdea => '어떤 기능이 있으면 좋을까요?';

  @override
  String get feedbackBugHint => '예: 사진을 보내려고 + 를 눌렀더니 화면이 하얘졌어요.';

  @override
  String get feedbackIdeaHint => '예: 채널 글을 예약해서 올리고 싶어요.';

  @override
  String get feedbackNeedWords => '요약과 내용을 모두 적어 주세요.';

  @override
  String get feedbackGoesTo => '받는 곳';

  @override
  String get feedbackTeam => '부루미 운영팀';

  @override
  String get feedbackSentTitle => '보냈어요';

  @override
  String get feedbackSentBody => '알려 줘서 고마워요. 고치면 부루미 소식 채널에 알려 드려요.';

  @override
  String get feedbackFailed => '보내지 못했어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get feedbackMine => '내가 보낸 의견';

  @override
  String get feedbackMineInfo => '이 목록은 이 폰에만 있어요.';

  @override
  String feedbackPrivacy(String device) {
    return '함께 가는 것: 버그·제안, 적은 글, 기기 종류($device), 앱 버전. 대화 내용·연락처·사진은 절대 붙지 않아요. 암호화된 1:1 메시지로 가요.';
  }

  @override
  String feedbackAttachLog(int count) {
    return '오류 기록 붙이기 · $count개';
  }

  @override
  String feedbackDate(int month, int day) {
    return '$month월 $day일';
  }

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
  String get openSourceLicenses => '오픈소스·출처';

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
  String get veilAll => '대화창 가리기';

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
  String get avatarShape => '프로필 모양';

  @override
  String get avatarShapePeople => '개인';

  @override
  String get avatarShapeGroups => '그룹';

  @override
  String get avatarShapeChannels => '채널';

  @override
  String get shapeCircle => '동그라미';

  @override
  String get shapeRounded => '둥근 사각';

  @override
  String get avatarShapeInfo => '보는 모양만 바뀌어요. 사진은 그대로예요.';

  @override
  String get tabEditFolder => '폴더 편집';

  @override
  String get tabShowUnread => '읽지 않은 대화 보기';

  @override
  String get tabReorder => '탭 재정렬';

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
  String get roomThemeMine => '내 설정';

  @override
  String autoNightRange(String from, String to) {
    return '$from~$to';
  }

  @override
  String get autoNightInfo =>
      '‘휴대폰 설정 따르기’는 휴대폰이 어두운 화면일 때 같이 어두워져요. ‘시간 정하기’는 정한 시간 동안만 야간 모드가 켜져요.';

  @override
  String get autoNightSchedule => '시간 정하기';

  @override
  String get autoNightTimes => '시간';

  @override
  String get autoNightFrom => '켜는 시간';

  @override
  String get autoNightTo => '끄는 시간';

  @override
  String get autoNightScheduleInfo =>
      '시간은 이 휴대폰에만 저장돼요. 해 지는 시간에 맞추려면 위치가 필요해서 넣지 않았어요.';

  @override
  String timerYears(int n) {
    return '$n년';
  }

  @override
  String timerMonths(int n) {
    return '$n달';
  }

  @override
  String timerWeeks(int n) {
    return '$n주';
  }

  @override
  String timerDays(int n) {
    return '$n일';
  }

  @override
  String timerHours(int n) {
    return '$n시간';
  }

  @override
  String timerMinutes(int n) {
    return '$n분';
  }

  @override
  String get timerOther => '다른 시간';

  @override
  String timerUnitHours(int n) {
    return '시간';
  }

  @override
  String timerUnitDays(int n) {
    return '일';
  }

  @override
  String timerUnitWeeks(int n) {
    return '주';
  }

  @override
  String timerUnitMonths(int n) {
    return '달';
  }

  @override
  String timerUnitYears(int n) {
    return '년';
  }

  @override
  String get defaultTimerHeader =>
      '정한 시간이 지나면 메시지가 양쪽 휴대폰에서 지워져요. 1시간부터 1년까지 고를 수 있어요.';

  @override
  String get defaultTimerNew => '새 대화';

  @override
  String get timerApply => '기존 대화에 적용';

  @override
  String get timerApplyInfo =>
      '고른 대화 모두에 같은 시간이 바로 적용돼요. 대화방 안에도 ‘자동 삭제를 바꿨어요’가 보여요.';

  @override
  String get timerApplyGo => '적용';

  @override
  String timerApplyGoN(int n) {
    return '$n개 적용';
  }

  @override
  String get timerApplyTime => '적용할 시간';

  @override
  String get timerApplyPick => '대화 고르기';

  @override
  String get timerSelectAll => '모두 고르기';

  @override
  String get timerDeselectAll => '모두 풀기';

  @override
  String timerApplied(int n, String time) {
    return '대화 $n개에 자동 삭제 $time 켰어요';
  }

  @override
  String timerAppliedOff(int n) {
    return '대화 $n개에서 자동 삭제를 껐어요';
  }

  @override
  String get qrTheme => '테마';

  @override
  String get qrShort => '5분짜리 QR';

  @override
  String get qrShortFooter =>
      '켜면 QR이 5분 뒤 쓸 수 없게 바뀌고, 아이디도 카드에 적지 않아요. 사진으로 찍혀 퍼져도 나중엔 못 써요.';

  @override
  String get qrShortInfo => '이 QR은 5분 동안만 쓸 수 있어요.';

  @override
  String get qrShortOver => '시간이 지났어요';

  @override
  String get qrShortAgain => '새 QR 만들기';

  @override
  String get roomThemeBoth => '상대방 화면에도 적용';

  @override
  String get roomThemeBothInfo =>
      '켜면 고른 배경이 상대방 휴대폰에도 바로 바뀌어요. 어떤 배경인지는 암호화돼서 서버도 몰라요. 내 사진 배경은 내 휴대폰에만 있어요.';

  @override
  String get roomThemeByOther => '지금 배경은 상대방이 골랐어요. 다시 고르면 내 선택으로 바뀌어요.';

  @override
  String get roomThemeSent => '상대방 화면에도 바꿨어요';

  @override
  String get roomThemeSample1 => '오늘 몇 시에 만나요?';

  @override
  String get roomThemeSample2 => '7시 좋아요 🙂';

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
  String get fxAdd => '효과 넣기';

  @override
  String get fxMore => '효과 더 보기';

  @override
  String get fxSearch => '효과 찾기';

  @override
  String get fxNothing => '맞는 효과가 없어요';

  @override
  String get fxReplay => '효과 다시 보기';

  @override
  String fxSendWith(String name) {
    return '$name 효과로 보내기';
  }

  @override
  String fxQuietWith(String name) {
    return '$name 효과로 조용히 보내기';
  }

  @override
  String get diceBull => '한가운데!';

  @override
  String get diceMissed => '빗나갔어요';

  @override
  String diceScore(int n) {
    return '$n점';
  }

  @override
  String get diceGoal => '골인!';

  @override
  String get diceAlmost => '아깝다';

  @override
  String get diceStrike => '스트라이크!';

  @override
  String dicePins(int n) {
    return '핀 $n개';
  }

  @override
  String get diceJackpot => '잭팟!';

  @override
  String diceTry(String emoji) {
    return '$emoji 하나만 보내면 나도 해 볼 수 있어요';
  }

  @override
  String get diceTrySend => '보내기';

  @override
  String get cxStill => '가만히';

  @override
  String get cxBounce => '통통';

  @override
  String get cxSpin => '빙글';

  @override
  String get cxWiggle => '흔들';

  @override
  String get cxBeat => '두근';

  @override
  String get cxFloat => '둥실';

  @override
  String get cxJelly => '말랑';

  @override
  String get cxSparkle => '반짝';

  @override
  String get cxMakeTitle => '이모지 만들기';

  @override
  String get cxWordsHint => '글자를 쓰면 바로 이모지가 돼요';

  @override
  String get cxPhotoHint => '사진을 고르면 이모지로 만들어요';

  @override
  String get cxSample => '오늘 최고';

  @override
  String get cxFromPhoto => '사진으로';

  @override
  String get cxFromWords => '글자로';

  @override
  String get cxWordsPlaceholder => '1~4글자 (예: 굿, ㅋㅋ, 최고)';

  @override
  String get cxMotionTitle => '움직임';

  @override
  String get cxBaseTitle => '대신 보일 이모지';

  @override
  String get cxBaseInfo => '대화 목록이나 알림처럼 그림을 못 그리는 곳에서는 이 이모지가 보여요.';

  @override
  String cxGroupSection(String name) {
    return '$name 이모지';
  }

  @override
  String get cxMineSection => '내 이모지';

  @override
  String get cxIsMine => '내 이모지에 있어요';

  @override
  String get cxSaveInfo => '내 이모지에 저장하면 어느 대화에서나 쓸 수 있어요';

  @override
  String get cxSave => '내 이모지에 저장';

  @override
  String get cxRemove => '내 이모지에서 빼기';

  @override
  String get cxGroupTitle => '그룹 이모지';

  @override
  String get cxGroupAdminInfo =>
      '고른 이모지는 이 그룹 모든 사람의 이모지 칸 맨 위에 보여요. 그림은 암호화돼서 서버는 볼 수 없어요.';

  @override
  String get cxGroupInfo => '관리자가 고른 이 그룹의 이모지예요. 눌러서 내 이모지에 저장할 수 있어요.';

  @override
  String get cxGroupEmptyAdmin => '먼저 이모지를 만들어 주세요. 만든 이모지 중에서 골라요.';

  @override
  String get cxGroupEmpty => '아직 그룹 이모지가 없어요';

  @override
  String cxGroupCount(int n, int max) {
    return '$n/$max개 골랐어요';
  }

  @override
  String get cxSaveAll => '모두 내 이모지에 저장';

  @override
  String get cxAllSaved => '모두 저장했어요';

  @override
  String get gifSave => 'GIF 저장';

  @override
  String get gifSaved => '내 GIF에 저장했어요';

  @override
  String get gifMine => '내 GIF';

  @override
  String get gifEmpty => '저장한 GIF가 없어요.\n대화에서 GIF를 꾹 누르고 \'GIF 저장\'을 눌러 보세요.';

  @override
  String get gifWithCaption => '설명 붙여 보내기';

  @override
  String get gifEdit => '편집해서 보내기';

  @override
  String get gifRemove => '내 GIF에서 빼기';

  @override
  String gifRemoveIn(int n) {
    return '$n초 뒤 내 GIF에서 빠져요';
  }

  @override
  String get gifCaptionHint => '설명 추가…';

  @override
  String get gifTrim => '자르기';

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
  String get autoDownloadInfo =>
      '미리 받지 않는 사진·동영상·파일은 누를 때 받아요. 절전 모드에서는 늘 누를 때 받아요.';

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
  String get roomRulesInfo => '멤버라면 누구나 볼 수 있어요.';

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
  String get welcomeInfo => '새 멤버가 들어왔을 때 그 사람에게만 한 번 보여요.';

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
  String get reactionsPreview => '미리보기';

  @override
  String get reactionsPreviewPost => '오늘 저녁 8시에 새 소식을 올려요 🎉';

  @override
  String get reactionsNoneInfo => '아무도 반응을 달 수 없어요. 서버도 새 반응을 받지 않아요.';

  @override
  String get reactionHiddenMine => '방 규칙으로 숨겨진 내 반응이에요. 누르면 거둬요.';

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
  String get emergencyDelete => '이 메시지 비상 시 삭제';

  @override
  String get emergencyDeleteOff => '비상 시 삭제 취소';

  @override
  String get emergencyHideRoom => '이 대화방 비상 시 숨김';

  @override
  String get emergencyHideRoomOff => '비상 시 숨김 취소';

  @override
  String get emergencyHideMsg => '이 메시지 비상 시 숨김';

  @override
  String get emergencyHideMsgOff => '비상 시 숨김 취소';

  @override
  String get emergencyMsgHidden => '숨김 비밀번호로 열면 이 메시지가 사라져요';

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
  String get suggestPost => '글 제안';

  @override
  String get suggestHint => '이 채널에 올릴 글을 제안해 보세요';

  @override
  String get suggestBarButton => '글 제안하기';

  @override
  String get suggestTextHint => '올리고 싶은 글을 써 주세요';

  @override
  String get suggestPhoto => '사진 넣기';

  @override
  String get suggestPhotoRemove => '사진 빼기';

  @override
  String get suggestTime => '올릴 때';

  @override
  String get suggestAnyTime => '아무 때나';

  @override
  String get suggestTimeInfo => '원하는 시간이 있으면 골라 주세요. 관리자가 바꿀 수도 있어요.';

  @override
  String get suggestSend => '제안 보내기';

  @override
  String get suggestFree => '돈은 들지 않아요. 제안한 글과 사진은 끝까지 암호화돼서 이 채널 관리자만 봐요.';

  @override
  String get suggestCardTitle => '글 제안';

  @override
  String suggestWantsAt(Object when) {
    return '원하는 시간: $when';
  }

  @override
  String get suggestWaiting => '관리자 답을 기다리고 있어요';

  @override
  String get suggestAccept => '올리기';

  @override
  String get suggestDecline => '거절';

  @override
  String get suggestAcceptTitle => '채널에 올리기';

  @override
  String get suggestNow => '지금 바로';

  @override
  String suggestTheirTime(Object when) {
    return '원하는 시간 ($when)';
  }

  @override
  String get suggestOtherTime => '다른 시간 정하기';

  @override
  String get suggestCredit => '제안한 사람 이름 함께 올리기';

  @override
  String suggestCreditLine(Object name) {
    return '✍️ $name님이 제안했어요';
  }

  @override
  String get suggestNote => '거절 이유 (안 써도 돼요)';

  @override
  String get suggestDeclineSend => '거절하기';

  @override
  String get suggestDealAccepted => '합의됐어요!';

  @override
  String get suggestDealNow => '채널에 바로 올렸어요.';

  @override
  String suggestDealAt(Object when) {
    return '$when에 자동으로 올라가요.';
  }

  @override
  String get suggestDealFree => '무료 제안이라 오간 돈은 없어요.';

  @override
  String get suggestDealCredit => '제안한 사람 이름이 함께 올라가요.';

  @override
  String get suggestDealDeclined => '제안이 거절됐어요';

  @override
  String suggestDealNote(Object note) {
    return '이유: $note';
  }

  @override
  String get suggestSent => '제안을 보냈어요';

  @override
  String get suggestPublished => '채널에 올렸어요';

  @override
  String suggestScheduled(Object when) {
    return '$when에 올라가도록 예약했어요';
  }

  @override
  String get suggestDeclinedNotice => '제안을 거절했어요';

  @override
  String get suggestPhoneOn => '예약한 글은 이 폰에서 올라가요. 그때 앱이 한 번 열려 있어야 해요.';

  @override
  String get suggestNoRight => '이 채널에 글을 올릴 권한이 없어요';

  @override
  String get topics => '주제';

  @override
  String get topicsInfo =>
      '큰 그룹 대화를 주제별 방으로 나눠요. 어떤 글이 어느 주제인지도 끝까지 암호화돼서 서버는 몰라요.';

  @override
  String get topicsOn => '주제 켜기';

  @override
  String get topicsView => '보이는 모양';

  @override
  String get topicsViewTabs => '탭';

  @override
  String get topicsViewList => '목록';

  @override
  String get topicsViewInfo => '모든 멤버에게 같은 모양으로 보여요.';

  @override
  String get topicsList => '주제 목록';

  @override
  String get topicsListInfo =>
      '주제 이름과 아이콘도 암호화돼서 관리자 폰에서 멤버 폰으로 바로 전해져요. 관리자만 주제를 만들고 닫을 수 있어요.';

  @override
  String get topicGeneral => '일반';

  @override
  String get topicAll => '모두';

  @override
  String get topicNew => '새 주제';

  @override
  String get topicEdit => '주제 수정';

  @override
  String get topicName => '주제 이름';

  @override
  String get topicNameHint => '예: 공지, 잡담, 맛집';

  @override
  String get topicIcon => '아이콘';

  @override
  String get topicColor => '색';

  @override
  String get topicCreate => '만들기';

  @override
  String get topicDone => '완료';

  @override
  String get topicClose => '주제 닫기';

  @override
  String get topicReopen => '주제 다시 열기';

  @override
  String get topicClosedBar => '닫힌 주제예요. 관리자만 쓸 수 있어요.';

  @override
  String get topicHideGeneral => '탭에서 일반 숨기기';

  @override
  String topicMessageIn(Object name) {
    return '$name에 메시지';
  }

  @override
  String topicCount(Object n) {
    return '주제 $n개';
  }

  @override
  String get topicOffInfo => '끄면 모든 글이 한 대화로 보여요. 주제는 남아 있어서 다시 켜면 그대로예요.';

  @override
  String topicCreated(Object name) {
    return '‘$name’ 주제를 만들었어요';
  }

  @override
  String get topicClosedNotice => '주제를 닫았어요';

  @override
  String get topicReopenedNotice => '주제를 다시 열었어요';

  @override
  String get topicSwitchBar => '탭 위치 바꾸기';

  @override
  String get topicNoMessages => '아직 글이 없어요';

  @override
  String get topicNoIcon => '글자';

  @override
  String get topicSaved => '주제를 저장했어요';

  @override
  String get topicNameNeeded => '주제 이름을 써 주세요';

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
  String get chatGuarded => '공개방 · 지킴이 검사';

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
  String get muteSoundOff => '소리 끄기';

  @override
  String get muteSoundOn => '소리 켜기';

  @override
  String muteFor(String time) {
    return '$time 동안 끄기';
  }

  @override
  String muteHours(int n) {
    return '$n시간';
  }

  @override
  String muteDays(int n) {
    return '$n일';
  }

  @override
  String get muteCustom => '직접 정하기';

  @override
  String get muteUntilTitle => '언제까지 끌까요?';

  @override
  String muteEndsAt(String time) {
    return '다시 켜지는 때: $time';
  }

  @override
  String get mutedToast => '알림이 꺼졌어요';

  @override
  String get unmutedToast => '알림이 켜졌어요';

  @override
  String mutedForToast(String time) {
    return '$time 동안 알림이 꺼져요';
  }

  @override
  String mutedUntilToast(String time) {
    return '알림이 꺼져요. 다시 켜지는 때: $time';
  }

  @override
  String get soundOffToast => '알림이 소리 없이 와요';

  @override
  String get soundOnToast => '알림 소리가 다시 나요';

  @override
  String pinnedMany(int n) {
    return '대화 $n개를 고정했어요';
  }

  @override
  String unpinnedMany(int n) {
    return '대화 $n개의 고정을 풀었어요';
  }

  @override
  String mutedMany(int n) {
    return '대화 $n개의 알림을 껐어요';
  }

  @override
  String unmutedMany(int n) {
    return '대화 $n개의 알림을 켰어요';
  }

  @override
  String get swipeUnread => '안 읽음';

  @override
  String get swipeSettings => '대화 목록 밀기';

  @override
  String get swipeToRight => '오른쪽으로 밀기';

  @override
  String get swipeToLeft => '왼쪽으로 밀기';

  @override
  String get swipeDefault => '기본';

  @override
  String get swipeSettingsInfo =>
      '대화를 옆으로 밀면 나오는 버튼 중 맨 끝 버튼을 골라요. 끝까지 쭉 밀면 그 버튼이 바로 실행돼요.';

  @override
  String get swipeSampleName => '부루미';

  @override
  String get swipeSampleText => '옆으로 밀어서 바로 정리해 보세요';

  @override
  String get folderDefaultInfo =>
      '맨 앞에 둔 폴더가 앱을 열 때 먼저 보여요. \'모든 대화\'도 옮길 수 있어요.';

  @override
  String get iconBadgeHeader => '배지 숫자';

  @override
  String get iconBadgeChannels => '채널 포함';

  @override
  String get iconBadgeMuted => '알림 끈 대화 포함';

  @override
  String get iconBadgeMessages => '안 읽은 메시지 수로 세기';

  @override
  String get iconBadgeInfo =>
      '대화 탭과 앱 아이콘의 빨간 숫자예요. \'안 읽은 메시지 수로 세기\'를 끄면 안 읽은 대화 수로 세요. 숫자는 휴대폰에서만 세고 서버는 몰라요.';

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
  String get veilAllSub => '대화방 안 메시지를 누르고 있는 동안만 보여요';

  @override
  String get veilList => '대화 목록 가리기';

  @override
  String get veilListSub => '목록의 마지막 메시지를 누르고 있는 동안만 보여요';

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
  String get folderIconFavourites => '폴더용 추천';

  @override
  String get folderIconOnly => '아이콘만 보기';

  @override
  String get folderIconOnlyInfo => '대화 목록 위 폴더 탭에 이름 없이 이모지만 보여요.';

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

  @override
  String get checkSectionTodo => '할 일';

  @override
  String get archiveToMenu => '왼쪽 메뉴로';

  @override
  String get archiveMovedTitle => '보관함을 왼쪽 메뉴로 옮겼어요';

  @override
  String get archiveMovedBody => '왼쪽 위 메뉴 버튼을 누르면 보여요.';

  @override
  String get archivePinnedTitle => '보관함을 대화 목록에 고정했어요';

  @override
  String get archivePinnedBody => '다시 옮기려면 왼쪽으로 끝까지 밀어요.';

  @override
  String get archivePinBack => '목록에 고정';

  @override
  String get menuStories => '스토리';

  @override
  String get storiesMovedTitle => '스토리를 왼쪽 메뉴로 옮겼어요';

  @override
  String get bubblesMovedTitle => '비눗방울을 왼쪽 메뉴로 옮겼어요';

  @override
  String get storiesPinnedTitle => '스토리를 대화 목록에 고정했어요';

  @override
  String get bubblesPinnedTitle => '비눗방울을 대화 목록에 고정했어요';

  @override
  String get trustOfficial => '공식 계정';

  @override
  String get trustOfficialInfo => '부루미가 확인한 공식 계정이에요';

  @override
  String get trustChecking => '확인 중';

  @override
  String get trustFake => '가짜';

  @override
  String trustNotOfficial(String name) {
    return '$name 공식 계정이 아니에요';
  }

  @override
  String get trustCheckingInfo => '사칭 신고가 여러 번 들어와서 운영자가 확인하고 있어요';

  @override
  String get trustFakeInfo => '운영자가 확인한 사칭 계정이에요. 돈이나 인증번호를 보내지 마세요';

  @override
  String get firstTitle => '처음 메시지를 보낸 사람이에요';

  @override
  String get firstJoined => '가입';

  @override
  String get ageWeek => '7일 안';

  @override
  String get ageMonth => '한 달 안';

  @override
  String get ageYear => '1년 안';

  @override
  String get ageOlder => '1년 넘음';

  @override
  String get ageUnknown => '알 수 없음';

  @override
  String get firstRenamed => '이름 변경';

  @override
  String get firstRenamedRecent => '최근 7일 안에 바꿨어요';

  @override
  String get firstRenamedNo => '최근엔 없어요';

  @override
  String get firstCommon => '함께 있는 대화방';

  @override
  String firstCommonCount(int count) {
    return '$count개';
  }

  @override
  String get firstVerified => '공식 인증';

  @override
  String get firstVerifiedYes => '됨';

  @override
  String get firstVerifiedNo => '안 됨';

  @override
  String get firstTip => '아는 사람이 아니면 돈, 인증번호, 비밀번호를 보내지 마세요.';

  @override
  String get firstAccept => '수락';

  @override
  String get firstBlock => '차단';

  @override
  String get firstReport => '신고';

  @override
  String get firstMediaHidden => '수락하면 보여요';

  @override
  String get reportImpersonation => '사칭이에요';

  @override
  String get reportImpTitle => '사칭 신고';

  @override
  String get reportImpInfo =>
      '다른 사람인 척하는 계정을 알려 주세요. 프로필만 운영자에게 가고, 대화 내용은 가지 않아요.';

  @override
  String get reportImpWho => '누구인 척하나요?';

  @override
  String get reportImpWhoHint => '이름 또는 ID';

  @override
  String get reportImpNote => '더 알려 줄 내용 (선택)';

  @override
  String get reportImpSend => '신고하기';

  @override
  String get reportImpDone => '신고했어요. 운영자가 확인할게요';

  @override
  String get badgeRow => '공식 배지';

  @override
  String get badgeTitle => '공식 배지';

  @override
  String get badgeInfo =>
      '유명인, 회사, 큰 채널이 사칭을 막을 수 있게 이름 옆에 배지를 붙여요. 신분증은 받지 않아요.';

  @override
  String get badgeStep =>
      '아래 확인 문구를 공식 인스타그램·유튜브·홈페이지에 잠깐 올리거나 회사 메일 주소로 보내고, 올린 곳 주소를 적어 주세요.';

  @override
  String get badgeCode => '확인 문구';

  @override
  String get badgeCopy => '복사';

  @override
  String get badgeCopied => '복사했어요';

  @override
  String get badgeKind => '종류';

  @override
  String get badgeKindPerson => '사람';

  @override
  String get badgeKindBrand => '회사·브랜드';

  @override
  String get badgeKindChannel => '채널';

  @override
  String get badgeName => '배지에 쓸 이름';

  @override
  String get badgeProof => '문구를 올린 곳 (주소 또는 메일)';

  @override
  String get badgeSend => '신청하기';

  @override
  String get badgeSent => '신청했어요. 확인되면 이름 옆에 배지가 붙어요.';

  @override
  String get badgeHave => '공식 배지가 있어요';

  @override
  String get badgeRenameNote => '이름을 바꾸면 배지가 꺼지고 다시 확인해요.';

  @override
  String get badgeFailed => '지금은 신청할 수 없어요. 잠시 뒤에 다시 해 주세요.';

  @override
  String get nameMarkRefused => '이름에 체크 표시는 넣을 수 없어요';

  @override
  String get nameReservedRefused => '공식 계정만 쓸 수 있는 말이 들어 있어요';

  @override
  String get idReservedRefused =>
      '이 ID는 예약돼 있어요. 진짜 주인이면 가입한 뒤 공식 배지를 신청해 주세요.';

  @override
  String get idLookalikeRefused => '공식 계정과 너무 비슷한 ID예요. 다른 ID를 써 주세요.';

  @override
  String get accountsAdd => '계정 추가';

  @override
  String get accountsLimitTitle => '계정을 더 쓰려면';

  @override
  String get accountsLimitInfo =>
      '계정 1개는 무료예요. 2번째 계정은 Plus에 들어 있고, 3번째 계정은 따로 살 수 있어요. 결제는 출시 후에 열려요.';

  @override
  String get accountsAlready => '이미 이 휴대폰에 있는 계정이에요';

  @override
  String get accountPassword => '계정 삭제 비밀번호';

  @override
  String get accountPasswordInfo =>
      '이 비밀번호로 열면 고른 계정이 이 휴대폰에서 조용히 사라지고, 남은 계정만 열려요. 서버의 계정은 그대로라 친구에게는 아무것도 보이지 않아요. 나중에 아이디와 백업 비밀번호로 다시 로그인할 수 있어요.';

  @override
  String get accountEraseList => '지울 계정';

  @override
  String get accountEraseListInfo => '모든 계정을 고를 수는 없어요. 하나는 남아야 해요.';

  @override
  String get editFirstWords => '처음 보낸 글';

  @override
  String get reportIllegal => '불법 촬영물·성착취물 (합성 포함)';

  @override
  String get reportHiddenNow => '신고가 모여 이 글은 모든 사람에게 가려졌어요';

  @override
  String get reportHiddenLine => '신고나 자동 검사로 가려진 글이에요. 운영자가 확인하고 있어요.';

  @override
  String get guardNotice =>
      '공개방이에요. 누구나 들어올 수 있어서, 운영자의 공개방 지킴이가 불법 사진과 스팸을 걸러요. 1:1 대화와 비공개 방은 그대로 종단간 암호화돼요.';

  @override
  String newMediaWait(int days) {
    return '이 방은 들어온 지 $days일이 지나야 사진·영상·링크를 보낼 수 있어요';
  }

  @override
  String get newMediaHidden => '새 멤버가 보낸 사진·영상·링크는 가려져요';

  @override
  String get newMediaTitle => '새 멤버 사진·영상·링크 제한';

  @override
  String get newMediaInfo =>
      '방에 들어온 지 얼마 안 된 사람은 글만 쓸 수 있어요. 자동 계정이 들어와 나쁜 사진을 올리는 걸 막아요.';

  @override
  String get newMediaFooter =>
      '방장·관리자는 제한이 없어요. 제한 기간에 올라온 사진·영상·링크는 다른 멤버에게 가려져요. 공개방은 처음부터 7일로 켜져 있어요.';

  @override
  String newMediaDays(int days) {
    return '$days일';
  }

  @override
  String get toolsSafety => '안전';

  @override
  String get toolsSafetyInfo => '예전 글을 몰래 고쳐 나쁜 사진을 숨기고 앱을 신고하는 협박 공격을 막아요.';

  @override
  String get lateEditTitle => '늦게 수정된 글';

  @override
  String get lateEditInfo =>
      '보낸 지 1시간이 지난 글을 누가 고치면 여기에 모여요. 그룹·채널의 글은 24시간이 지나면 고칠 수 없고, 사진·영상은 수정으로 바꿀 수 없어요.';

  @override
  String get lateEditEmpty => '늦게 수정된 글이 없어요';

  @override
  String lateEditLine(String first, String now, String sent, String edited) {
    return '처음: $first\n지금: $now\n보냄 $sent · 수정 $edited';
  }

  @override
  String lateEditBanner(int count) {
    return '오래된 글 $count개가 수정됐어요';
  }

  @override
  String get extortionRow => '협박받았어요';

  @override
  String get extortionTitle => '협박 신고';

  @override
  String get extortionInfo =>
      '\"돈을 안 보내면 방을 신고하겠다\" 같은 연락을 받았나요? 돈을 보내지 마세요. 운영자에게 알리면 그 계정을 막고, 이 방에 올라오는 불법 글을 먼저 살펴볼게요. 위험하면 경찰(112)에도 신고해 주세요.';

  @override
  String get extortionWho => '협박한 사람';

  @override
  String get extortionWhoHint => '아이디 (예: @abc)';

  @override
  String get extortionNote => '받은 말';

  @override
  String get extortionNoteHint => '받은 말을 그대로 붙여 넣어 주세요';

  @override
  String get extortionSend => '운영자에게 보내기';

  @override
  String get extortionDone => '운영자에게 보냈어요. 돈은 보내지 마세요.';

  @override
  String get wipeUser => '글 모두 지우고 내보내기';

  @override
  String logLateEdit(String name) {
    return '$name님이 오래된 글을 수정함';
  }

  @override
  String logWiped(String name, int count) {
    return '$name님의 글 $count개를 지우고 내보냄';
  }

  @override
  String logExtortion(String name) {
    return '협박 신고함 ($name)';
  }

  @override
  String get linkTitle => '초대 링크';

  @override
  String get linkKind => '링크 종류';

  @override
  String get linkPrivate => '비공개 링크';

  @override
  String get linkPublic => '공개 주소';

  @override
  String get linkPrivateInfo => '링크를 받은 사람만 들어올 수 있어요. 링크 속 코드는 서버에 남지 않아요.';

  @override
  String get linkPublicInfo => '누구나 주소로 들어올 수 있어요. 링크를 붙이면 카드에 이름과 소개가 보여요.';

  @override
  String get linkAddress => '주소';

  @override
  String get linkChecking => '확인하는 중…';

  @override
  String get linkFree => '쓸 수 있는 주소예요';

  @override
  String get linkTaken => '이미 쓰고 있는 주소예요';

  @override
  String get linkBadAddress => '영문 소문자로 시작해 5~32자로 써 주세요. 숫자와 _도 쓸 수 있어요.';

  @override
  String get linkReserved => '쓸 수 없는 단어가 들어 있어요';

  @override
  String get linkShare => '공유';

  @override
  String get linkShareText => '같이 들어와요';

  @override
  String get linkApproval => '승인 후 참여';

  @override
  String get linkApprovalInfo => '켜면 링크로 온 사람이 가입 요청을 보내고, 관리자가 받아 줘야 들어와요.';

  @override
  String get linkReset => '새 링크 만들기';

  @override
  String get linkResetInfo => '지금 링크는 더 이상 쓸 수 없어요. 새 링크를 다시 보내 주세요.';

  @override
  String get linkFailed => '링크를 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get joinRequests => '가입 요청';

  @override
  String get joinRequestsNone => '아직 가입 요청이 없어요';

  @override
  String get joinRequestsInfo => '받으면 바로 들어와요. 거절해도 상대에게 따로 알리지 않아요.';

  @override
  String get joinAccept => '받기';

  @override
  String get joinDecline => '거절';

  @override
  String get posterMake => '홍보 이미지 만들기';

  @override
  String get posterTitle => '홍보 이미지';

  @override
  String get posterTall => '세로';

  @override
  String get posterSquare => '정사각';

  @override
  String get posterColor => '색';

  @override
  String get posterSave => '사진에 저장';

  @override
  String get posterSaved => '사진에 저장했어요';

  @override
  String get posterScan => '카메라로 찍으면 바로 들어와요';

  @override
  String get posterInfo => '링크를 새로 만들면 예전 이미지의 QR은 더 이상 열리지 않아요.';

  @override
  String get webPage => '공개 웹페이지';

  @override
  String get webPageInfo =>
      '켜면 이제부터 올리는 글이 웹페이지에 보여요. 웹페이지 글은 암호화되지 않고, 검색에 나올 수 있어요. 끄면 웹페이지 글을 모두 내려요.';

  @override
  String get webPageNeedsPublic => '공개 주소로 바꾸면 켤 수 있어요.';

  @override
  String get webPageAddress => '웹페이지 주소';

  @override
  String get webPageOn => '웹페이지를 켤까요?';

  @override
  String get webPageOnBody =>
      '이제부터 올리는 글과 사진은 암호화 밖으로 나가서 누구나 볼 수 있어요. 예전 글은 올라가지 않아요.';

  @override
  String get webPageTurnOn => '켜기';

  @override
  String get joinByLink => '링크로 들어가기';

  @override
  String get joinByLinkHint => '초대 링크 붙여 넣기';

  @override
  String get joinByLinkBad => '초대 링크가 아니에요';

  @override
  String get joinPublicChannel => '공개 채널';

  @override
  String get joinPublicGroup => '공개 그룹';

  @override
  String get joinPrivateChannel => '비공개 채널';

  @override
  String get joinPrivateGroup => '비공개 그룹';

  @override
  String get joinSubscribe => '구독하기';

  @override
  String get joinGroup => '참여하기';

  @override
  String get joinAsk => '가입 요청 보내기';

  @override
  String get joinAsked => '가입 요청을 보냈어요. 관리자가 받아 주면 들어가요.';

  @override
  String get joinPrivateNote => '들어가기 전에는 멤버 수와 소개를 볼 수 없어요.';

  @override
  String get joinNotFound => '링크가 없거나 새 링크로 바뀌었어요';

  @override
  String get joinUnnamed => '초대받은 모임';

  @override
  String get remoteWipe => '원격 비상 삭제';

  @override
  String get remoteWipeInfo =>
      '휴대폰을 잃어버리거나 빼앗겼을 때, 내가 고른 믿는 친구가 삭제 코드를 보내면 이 휴대폰의 대화가 조용히 지워져요.';

  @override
  String get wipeFriends => '믿는 친구';

  @override
  String get wipeFriendsPick => '친구 고르기 (최대 3명)';

  @override
  String get wipeFriendsInfo =>
      '1:1 대화가 있는 친구만 고를 수 있어요. 친구에게 삭제 코드를 직접 알려 주세요.';

  @override
  String get wipeCode => '삭제 코드';

  @override
  String get wipeCodeChange => '삭제 코드 바꾸기';

  @override
  String get wipeCodeInfo => '6자 이상. 코드는 이 휴대폰에 암호처럼 바꿔서만 남고, 서버는 몰라요.';

  @override
  String get wipeCodeRule => '삭제 코드는 6자 이상으로 정해 주세요';

  @override
  String get wipeCodeSaved => '삭제 코드를 정했어요';

  @override
  String get wipeTwo => '두 명이 요청해야 삭제';

  @override
  String get wipeTwoInfo => '켜면 믿는 친구 두 명이 24시간 안에 코드를 보내야 지워져요.';

  @override
  String get wipeLastMsg => '마지막 메시지';

  @override
  String get wipeLastMsgInfo => '지우기 직전에 믿는 친구에게 이 글을 보내요. 비워 두면 아무것도 안 보내요.';

  @override
  String get wipeLastMsgHint => '예: 휴대폰을 잃어버렸어요. 새 번호로 연락할게요.';

  @override
  String get savedShort => '저장했어요';

  @override
  String get decoyTip =>
      '도움말: 평소에 거의 안 쓰는 두 번째 계정(미끼 계정)을 만들어 두면, 누가 억지로 앱을 열게 할 때 그 계정을 보여 줄 수 있어요.';

  @override
  String daysN(int n) {
    return '$n일';
  }

  @override
  String get idleWipe => '미접속 자동 삭제';

  @override
  String get idleWipeInfo =>
      '이 기간 동안 앱을 한 번도 열지 않으면 다음에 열 때 모든 대화가 먼저 지워져요. 하루 전에 평범한 알림이 와요.';

  @override
  String get idleReminderTitle => '부루미';

  @override
  String get idleReminderBody => '오랜만이에요. 한번 열어 볼까요?';

  @override
  String get wipeRequest => '비상 삭제 요청';

  @override
  String wipeRequestInfo(String name) {
    return '$name님이 알려 준 삭제 코드를 넣으면 그 휴대폰의 대화가 지워져요. 나를 믿는 친구로 정해 둔 경우에만 돼요.';
  }

  @override
  String get wipeRequestNote => '요청은 끝에서 끝까지 암호화돼 가요. 맞았는지 틀렸는지는 알려 주지 않아요.';

  @override
  String get wipeRequestSend => '지우기 요청 보내기';

  @override
  String get wipeRequestSent => '요청을 보냈어요';

  @override
  String get wipeTrustOn => '비상 삭제 요청할 사람으로 지정';

  @override
  String get wipeTrustOff => '비상 삭제 요청할 사람에서 빼기';

  @override
  String get wipeTrustAdded => '믿는 친구로 정했어요. 설정에서 삭제 코드도 정해 주세요.';

  @override
  String get wipeTrustRemoved => '믿는 친구에서 뺐어요';

  @override
  String get wipeFriendsFull => '믿는 친구는 3명까지예요';

  @override
  String get emergencyHeader => '잠금과 비상 삭제';

  @override
  String get autoLock => '자동 잠금';

  @override
  String get autoLockInfo =>
      '앱을 떠난 뒤 이 시간이 지나면 다시 비밀번호를 물어요. 앱 잠금이 켜져 있을 때만 적용돼요.';

  @override
  String get autoLockNow => '바로';

  @override
  String get autoLock1m => '1분 뒤';

  @override
  String get autoLock5m => '5분 뒤';

  @override
  String get autoLock1h => '1시간 뒤';

  @override
  String get protect => '공유 비활성화';

  @override
  String get protectInfo =>
      '켜면 이 대화방에서는 전달, 저장, 복사가 안 되고 화면 캡처도 막아요. 아이폰은 녹화할 때 화면을 가려요.';

  @override
  String get protectOn => '공유 비활성화 켜기';

  @override
  String get protectOff => '공유 비활성화 끄기';

  @override
  String get protectOnDone => '이 대화방에서 전달·저장·복사·캡처를 막았어요';

  @override
  String get protectOffDone => '공유 비활성화를 껐어요';

  @override
  String get idReservedOwner =>
      '진짜 주인을 위해 맡아 둔 ID예요. 주인이면 \'예약 아이디 받기\'로 받은 코드를 넣어 주세요.';

  @override
  String get roomReservedOwner =>
      '회사·기관·유명인 같은 주인이 있는 이름이라 공식 배지가 있어야 채널 이름으로 쓸 수 있어요';

  @override
  String get idReservedSale =>
      '4글자 이하 ID와 인기 단어 ID는 따로 받을 수 있어요. 코드가 있으면 넣어 주세요.';

  @override
  String get claimHaveCode => '받은 코드가 있어요';

  @override
  String get claimCodeHint => '코드 (BRM-로 시작)';

  @override
  String get claimCodeHelp => '이 ID를 받을 때 메일로 온 코드예요. 30일 안에 한 번만 쓸 수 있어요.';

  @override
  String get claimCodeWrong => '코드가 맞지 않거나 이미 썼어요. 받은 메일의 ID와 코드를 다시 확인해 주세요.';

  @override
  String ruleSecs(int n) {
    return '$n초';
  }

  @override
  String ruleMins(int n) {
    return '$n분';
  }

  @override
  String ruleHours(int n) {
    return '$n시간';
  }

  @override
  String get permText => '글 보내기';

  @override
  String get permMedia => '사진·영상·파일';

  @override
  String get permSticker => '스티커·GIF';

  @override
  String get permPoll => '투표';

  @override
  String get permLink => '링크';

  @override
  String get permInvite => '멤버 초대';

  @override
  String get permPin => '메시지 고정';

  @override
  String get permInfo => '그룹 정보 바꾸기';

  @override
  String get rightInfo => '그룹 정보 바꾸기';

  @override
  String get rightDelete => '다른 사람 글 지우기';

  @override
  String get rightBan => '멤버 내보내기·차단';

  @override
  String get rightInvite => '초대 링크 만들기';

  @override
  String get rightPin => '메시지 고정';

  @override
  String get rightMute => '메시지 금지';

  @override
  String get rightAddAdmin => '관리자 추가';

  @override
  String get memberPerms => '멤버 권한';

  @override
  String get memberPermsHeader => '멤버가 할 수 있는 일';

  @override
  String get memberPermsInfo => '끄면 일반 멤버는 그 기능을 쓸 수 없어요. 방장과 관리자는 늘 쓸 수 있어요.';

  @override
  String get adminRights => '관리자 권한';

  @override
  String get adminRightsInfo =>
      '이 관리자가 할 수 있는 일을 하나씩 고를 수 있어요. 방장 넘기기와 그룹 삭제는 방장만 할 수 있어요.';

  @override
  String get slowMode => '슬로 모드';

  @override
  String get slowModeInfo =>
      '켜면 멤버는 메시지를 보낸 뒤 정한 시간이 지나야 다시 보낼 수 있어요. 방장과 관리자는 제한이 없어요.';

  @override
  String get memberTag => '멤버 태그';

  @override
  String get memberTagInfo => '이름 옆에 보이는 짧은 글이에요 (최대 16자). 비우면 태그가 사라져요.';

  @override
  String get memberTagHint => '예: 디자이너';

  @override
  String get muteMember => '다음 동안 메시지 금지';

  @override
  String get unmuteMember => '메시지 금지 풀기';

  @override
  String get muteFor1h => '1시간';

  @override
  String get muteFor1d => '1일';

  @override
  String get muteFor7d => '7일';

  @override
  String get muteForever => '풀 때까지';

  @override
  String get mutedRole => '메시지 금지';

  @override
  String get mutedForever => '관리자가 이 방에서 메시지를 막았어요';

  @override
  String mutedUntil(String time) {
    return '관리자가 $time까지 메시지를 막았어요';
  }

  @override
  String get handover => '방장 넘기기';

  @override
  String handoverTitle(String name) {
    return '$name님에게 방장 넘기기';
  }

  @override
  String get handoverInfo =>
      '고른 기간 동안 둘 다 방장이에요. 기간이 끝나면 내가 \'넘기기 완료\'를 눌러야 끝나고, 나는 관리자가 돼요. 받는 사람은 거절할 수 있어요.';

  @override
  String handoverPending(String name, String time) {
    return '$name님에게 방장을 넘기는 중이에요. $time부터 마칠 수 있어요.';
  }

  @override
  String handoverIncoming(String time) {
    return '방장을 넘겨받았어요. $time까지는 기존 방장과 함께 방장이에요.';
  }

  @override
  String get handoverFinish => '넘기기 완료';

  @override
  String get handoverDecline => '방장 받지 않기';

  @override
  String logMuted(String name) {
    return '$name님 메시지 금지';
  }

  @override
  String logUnmuted(String name) {
    return '$name님 메시지 금지 풀기';
  }

  @override
  String logHandover(String name) {
    return '$name님에게 방장 넘기기 시작';
  }

  @override
  String get toolsMembers => '멤버';

  @override
  String get permBlocked => '이 방에서는 관리자만 보낼 수 있어요';

  @override
  String slowWait(int n) {
    return '슬로 모드: $n초 뒤에 보낼 수 있어요';
  }

  @override
  String get mentionAll => '@모두';

  @override
  String get mentionAllInfo => '이 방의 모든 멤버에게 알려요';

  @override
  String get mentionAllAdmins => '멤버가 33명 이상인 방은 관리자만 @모두를 쓸 수 있어요';

  @override
  String get videoLabel => '동영상';

  @override
  String videoResumed(String time) {
    return '이어서 봐요 · $time';
  }

  @override
  String get videoFromStart => '처음부터';

  @override
  String get videoSpeedTitle => '재생 속도';

  @override
  String get videoNoteHoldHint => '누르면 찍고 다시 누르면 보내요. 꾹 누르고 있으면 손을 뗄 때 보내요';

  @override
  String get videoNoteSlideHint => '↑ 밀면 잠가요 · ← 밀면 지워요';

  @override
  String get videoNoteLocked => '잠겼어요 · ■ 누르면 보내요';

  @override
  String get autoSaveTitle => '갤러리에 자동 저장';

  @override
  String get autoSaveInfo =>
      '받은 사진·영상을 폰 사진 앱에 저절로 저장해요. 사진 앱에 저장된 건 부루미 밖에 남아서 처음엔 꺼져 있어요. 한 번만 보기와 공유가 꺼진 대화는 저장하지 않아요.';

  @override
  String get autoplayVideo => '영상 자동 재생';

  @override
  String get autoplayVideoSub => '받아 둔 영상이 대화에서 소리 없이 움직여요. 스피커를 누르면 소리가 나요';

  @override
  String get videoQualityTitle => '화질';

  @override
  String get videoQualityAuto => '자동';

  @override
  String get videoQualityOriginal => '원본';

  @override
  String get videoQualityLightShort => '가벼운 화질';

  @override
  String videoQualityLight(int height) {
    return '가벼운 화질 ${height}p';
  }

  @override
  String get videoSendQuality => '영상 화질';

  @override
  String get videoQualityAbout => '대략';

  @override
  String get videoQualitySmall => '작은 용량';

  @override
  String get videoQualityHigh => '높은 화질';

  @override
  String get videoLightCopy => '가벼운 복사본도 함께 보내기';

  @override
  String get videoLightCopySub => '데이터를 아끼는 사람은 480p로 볼 수 있어요';

  @override
  String get videoQualityWebNote => '웹에서는 원본으로 보내요. 폰 앱에서는 이 화질로 줄여서 보내요.';

  @override
  String get dlWaiting => '순서 기다리는 중';

  @override
  String get dlPaused => '멈춤';

  @override
  String get dlFirst => '먼저 받기';

  @override
  String get dlPause => '멈추기';

  @override
  String get dlResume => '이어 받기 (처음부터)';

  @override
  String get dlStop => '그만 받기';

  @override
  String get docOpenOther => '다른 앱으로 열기';

  @override
  String get docOpenOtherWarn =>
      '다른 앱으로 열면 그 앱이 파일 내용을 볼 수 있어요. 부루미의 암호화 보호 밖으로 나가요.';

  @override
  String get docOpenOtherGo => '열기';

  @override
  String get docNoInApp => '부루미 안에서 바로 볼 수 없는 파일이에요';

  @override
  String get docNoInAppHint =>
      'PDF, 글자 파일, 사진은 부루미 안에서 바로 열려요. 이 파일은 다른 앱으로 열어 주세요.';

  @override
  String get docProtectedNoShare => '이 대화는 공유가 꺼져 있어서 다른 앱으로 열 수 없어요';

  @override
  String get docSearch => '문서에서 찾기';

  @override
  String get docSearchNone => '없어요';

  @override
  String docPage(int page, int pages) {
    return '$page/$pages쪽';
  }

  @override
  String docTabsMore(String name, int count) {
    return '$name 외 $count개';
  }

  @override
  String get docTabsTitle => '열어 둔 파일';

  @override
  String get docTabsCloseAll => '모두 닫기';

  @override
  String get docFailed => '파일을 열지 못했어요';

  @override
  String get docTextCut => '글이 길어서 앞부분만 보여요';

  @override
  String get videoSpeedNormal => '보통';

  @override
  String videoSkipSeconds(int seconds) {
    return '$seconds초';
  }

  @override
  String get dlChatDm => '1:1 대화';

  @override
  String get dlOff => '꺼짐';

  @override
  String dlUpToMb(int mb) {
    return '${mb}MB까지';
  }

  @override
  String dlChatsCount(int count) {
    return '대화 종류 $count개';
  }

  @override
  String get dlAutoSwitch => '자동으로 받기';

  @override
  String get dlKinds => '받을 것';

  @override
  String get dlWhere => '이런 대화에서 미리 받아요';

  @override
  String get dlMaxSize => '최대 크기';

  @override
  String get dlMaxInfo => '이보다 큰 파일은 누를 때 받아요. 크기를 모르는 파일도 누를 때 받아요.';

  @override
  String get dlList => '다운로드 목록';

  @override
  String get dlListEmpty => '받은 파일이 아직 없어요';

  @override
  String get dlRunning => '받는 중';

  @override
  String get dlRecent => '최근에 받은 것';

  @override
  String get dlCancelled => '취소했어요';

  @override
  String get dlFailed => '받지 못했어요';

  @override
  String get dlClear => '목록 지우기';

  @override
  String get dlListInfo => '목록만 지워져요. 받아 둔 파일은 아래 보관 기간이 지나면 지워져요.';

  @override
  String get dlTapToGet => '눌러서 받기';

  @override
  String get keepTitle => '받아 둔 파일 자동으로 지우기';

  @override
  String get keepInfo =>
      '마지막으로 연 지 이 기간이 지나면 기기에 받아 둔 사진·동영상·파일을 지워요. 대화는 그대로이고, 다시 누르면 새로 받아요. 받아 둔 파일도 기기 안에서 암호화돼 있어요.';

  @override
  String get keepDay => '하루';

  @override
  String get keepWeek => '일주일';

  @override
  String get keepMonth => '한 달';

  @override
  String get keepNever => '안 지워요';

  @override
  String get viewOnceVideo => '한 번만 보기 동영상';

  @override
  String get draftLabel => '임시 저장:';

  @override
  String get pinHowLong => '얼마 동안 고정할까요?';

  @override
  String invitesBlockedRow(int n) {
    return '초대를 막은 사람 $n명';
  }

  @override
  String invitesBlockedTitle(int n) {
    return '$n명이 초대를 막았어요';
  }

  @override
  String get invitesBlockedInfo =>
      '이 사람들은 연락처에 있는 사람만 그룹·채널에 초대할 수 있게 해 두었어요. 대신 초대 링크를 1:1 대화로 보낼 수 있어요. 들어올지는 본인이 정해요.';

  @override
  String sendInviteLinkN(int n) {
    return '초대 링크 보내기 $n';
  }

  @override
  String inviteLinkSent(int n) {
    return '$n명에게 초대 링크를 보냈어요';
  }

  @override
  String get inviteLinkNone => '초대 링크를 만들 권한이 없어요. 관리자에게 부탁해 보세요.';

  @override
  String readAtToday(String time) {
    return '읽음 · 오늘 $time';
  }

  @override
  String readAtYesterday(String time) {
    return '읽음 · 어제 $time';
  }

  @override
  String readAtDate(String date) {
    return '읽음 · $date';
  }

  @override
  String get shareTitle => '공유';

  @override
  String get shareAddWord => '한마디 덧붙이기';

  @override
  String shareSendN(int n) {
    return '보내기 $n';
  }

  @override
  String shareDone(int n) {
    return '$n곳에 전달했어요';
  }

  @override
  String get textCopied => '글자를 복사했어요';

  @override
  String get copyMsgLink => '링크 복사';

  @override
  String get msgLinkCopied => '링크를 복사했어요. 이 대화방 멤버만 열 수 있어요.';

  @override
  String get msgLinkNotMember => '이 링크는 대화방 멤버만 열 수 있어요.';

  @override
  String get msgLinkGone => '메시지를 찾지 못했어요. 지워졌거나 오래된 메시지예요.';

  @override
  String pinnedMessageN(int n) {
    return '고정 메시지 #$n';
  }

  @override
  String pinnedListTitle(int count) {
    return '고정 메시지 $count개';
  }

  @override
  String get pinnedListOpen => '고정 메시지 모두 보기';

  @override
  String get unpinAll => '모두 고정 해제';

  @override
  String unpinAllAsk(int count) {
    return '고정 메시지 $count개를 모두 해제할까요?';
  }

  @override
  String get pinNotifyAll => '모두에게 알림';

  @override
  String get pinNotifyInfo => '켜면 멤버 모두의 휴대폰에 알림이 가요. 끄면 조용히 고정돼요.';

  @override
  String pinLine(String name) {
    return '$name님이 메시지를 고정했어요';
  }

  @override
  String get pinLineMine => '메시지를 고정했어요';

  @override
  String get pinFor1d => '하루';

  @override
  String get pinFor1w => '일주일';

  @override
  String get pinFor1m => '한 달';

  @override
  String get pinForever => '직접 풀 때까지';

  @override
  String get repeatNone => '한 번';

  @override
  String get repeatDay => '매일';

  @override
  String get repeatWeek => '매주';

  @override
  String get repeatMonth => '매월';

  @override
  String get tabPolls => '투표';

  @override
  String get tabSaved => '저장';

  @override
  String get pollClosedShort => '마감';

  @override
  String get videoNote => '동그라미 영상';

  @override
  String get videoNoteHint => '누르면 최대 1분 동안 찍고, 다시 누르면 보내요';

  @override
  String get cameraUnavailable => '카메라를 켤 수 없어요';

  @override
  String get saveToGallery => '갤러리에 저장';

  @override
  String get savedToGallery => '갤러리에 저장했어요';

  @override
  String get noMemberDm => '멤버끼리 1:1 대화 막기';

  @override
  String get noMemberDmInfo =>
      '켜면 이 그룹의 일반 멤버끼리는 1:1 대화를 새로 시작할 수 없어요. 관리자와는 대화할 수 있어요. 낯선 사람이 그룹에서 개인 연락하는 걸 막아 줘요.';

  @override
  String get memberDmBlocked => '같이 있는 그룹에서 멤버끼리 1:1 대화를 막아 두어서 대화를 시작할 수 없어요.';

  @override
  String get cardFlow => '선택형 카드';

  @override
  String get newFlow => '선택형 카드 만들기';

  @override
  String get flowTitleHint => '예: 오늘 뭐 볼까?';

  @override
  String get flowTextHint => '설명 (없어도 돼요)';

  @override
  String get flowStartHint => '시작 버튼 이름 (비우면 \'시작하기\')';

  @override
  String get flowStart => '시작하기';

  @override
  String get flowQuestionHint => '질문을 적어 주세요';

  @override
  String get flowChoiceHint => '선택지';

  @override
  String get flowAddChoice => '선택지 추가';

  @override
  String get flowAddQuestion => '질문 추가';

  @override
  String get flowRemoveQuestion => '이 질문 지우기';

  @override
  String flowResultN(int n) {
    return '결과 $n';
  }

  @override
  String get flowResultTitleHint => '결과 이름 (예: 액션 영화)';

  @override
  String get flowResultTextHint => '결과 설명 (없어도 돼요)';

  @override
  String get flowLinkLabelHint => '링크 버튼 이름 (없어도 돼요)';

  @override
  String get flowAddResult => '결과 추가';

  @override
  String get flowRemoveResult => '이 결과 지우기';

  @override
  String get flowPickNext => '이 선택지를 누르면 어디로 갈까요?';

  @override
  String flowToQuestion(int n) {
    return '질문 $n';
  }

  @override
  String flowToResult(int n) {
    return '결과 $n';
  }

  @override
  String get flowStats => '결과 통계 받기';

  @override
  String get flowStatsInfo =>
      '누군가 결과까지 가면 결과 번호만 내 폰으로 와요. 누가 어떤 결과를 받았는지는 내 폰에도 남지 않고, 결과마다 몇 명인지 숫자만 보여요.';

  @override
  String get flowInfo =>
      '버튼을 누를 때마다 카드가 다음 질문으로 바뀌어요. 바뀐 화면은 누른 사람에게만 보이고, 고른 답은 그 사람 폰 밖으로 나가지 않아요. 질문은 10개, 선택지는 질문마다 6개, 결과는 8개까지예요.';

  @override
  String get flowNoPath => '어떤 선택으로도 결과에 닿지 않아요. 선택지가 어디로 가는지 확인해 주세요.';

  @override
  String get flowBack => '뒤로';

  @override
  String get flowAgain => '다시 하기';

  @override
  String get flowShare => '결과 보내기';

  @override
  String get flowResultLabel => '내 결과';

  @override
  String get flowShared => '결과를 보냈어요';

  @override
  String get flowStatsTitle => '결과 통계';

  @override
  String flowTried(int n) {
    return '$n명이 결과를 받았어요';
  }

  @override
  String get flowStatsNone => '아직 결과를 받은 사람이 없어요';

  @override
  String get flowStatsPrivacy => '결과마다 몇 명인지만 보여요. 누가 어떤 결과를 받았는지는 아무도 몰라요.';

  @override
  String get flowRevert => '처음으로 되돌리기';

  @override
  String flowShareText(String title, String result) {
    return '$title\n내 결과: $result';
  }

  @override
  String get welcomeEmptyTitle => '환영 인사 만들기';

  @override
  String get welcomeEmptyBody =>
      '새 멤버가 들어오면 자동으로 반겨 줘요.\n사진이나 영상도 하나 넣을 수 있어요.';

  @override
  String get welcomeEditorHint =>
      '새 멤버가 들어오면 이 메시지를 봐요.\n길게 누르면 고치거나 지울 수 있어요.';

  @override
  String get welcomeOnlyYou => '나만 보여요';

  @override
  String get joinedGroupLine => '그룹에 들어왔어요';

  @override
  String get joinedChannelLine => '채널을 구독했어요';

  @override
  String get welcomeMediaTooBig => '사진이나 영상은 50MB까지 넣을 수 있어요';

  @override
  String get textsEncrypted => '끝까지 암호화돼요. 서버는 내용을 볼 수 없어요.';

  @override
  String get welcomeRemoveMedia => '사진·영상 빼기';

  @override
  String get welcomeAddHint => '환영 메시지';

  @override
  String get removeContact => '연락처에서 삭제';

  @override
  String get removeContactInfo =>
      '연락처 목록에서만 빠지고 대화는 그대로 남아요. 다시 대화를 열면 연락처에 돌아와요.';

  @override
  String get tidyChats => '대화 정리하기';

  @override
  String get tidyChatsInfo =>
      '6개월 넘게 새 글이 없는 그룹과 채널이에요. 고른 방을 한 번에 나가요. 나가기 전 5초 동안 되돌릴 수 있어요.';

  @override
  String tidyLast(String date) {
    return '마지막 글 $date';
  }

  @override
  String get tidyNone => '정리할 대화가 없어요';

  @override
  String tidyLeave(int n) {
    return '$n개 대화 나가기';
  }

  @override
  String get noIdSearch => '아이디로 나를 찾지 못하게';

  @override
  String get noIdSearchInfo =>
      '켜면 모르는 사람이 내 아이디나 이름을 검색해도 나오지 않아요. 같은 대화방에 있는 사람이나 내 QR·초대 링크를 받은 사람은 계속 찾을 수 있어요.';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get liveLabelOff => 'LIVE 끔';

  @override
  String get liveStyleLive => '라이브';

  @override
  String get liveStyleLoop => '반복';

  @override
  String get liveStyleBounce => '바운스';

  @override
  String get liveStyleOff => '라이브 끄기';

  @override
  String get liveOnToast => '라이브 포토를 켰어요';

  @override
  String get liveLoopToast => '반복 재생으로 바꿨어요';

  @override
  String get liveBounceToast => '바운스로 바꿨어요';

  @override
  String get liveOffToast => '라이브 포토를 껐어요. 사진만 보내요';

  @override
  String get livePhoto => '라이브 포토';

  @override
  String get liveReplay => '다시 재생';

  @override
  String get aiEditor => 'AI 편집기';

  @override
  String get aiTabTranslate => '번역';

  @override
  String get aiTabStyle => '말투';

  @override
  String get aiTabFix => '고치기';

  @override
  String get aiOriginal => '원래 글';

  @override
  String get aiResult => '결과';

  @override
  String get aiEmojify => '이모지 넣기';

  @override
  String get aiApply => '적용';

  @override
  String aiFromLang(String lang) {
    return '원래 언어: $lang';
  }

  @override
  String get aiToLang => '바꿀 언어';

  @override
  String get aiFailed => '지금은 AI가 답하지 못했어요. 잠시 뒤 다시 해 보세요.';

  @override
  String get aiRefused => '이 글은 AI가 바꿀 수 없어요.';

  @override
  String aiTooLong(int count) {
    return '글이 너무 길어요. $count자까지 바꿀 수 있어요.';
  }

  @override
  String get aiPreparing => '휴대폰이 AI를 준비하고 있어요. 조금 뒤에 다시 해 보세요.';

  @override
  String get aiNoChange => '고칠 곳이 없어요.';

  @override
  String get aiHelp => 'AI 편집기는 이 휴대폰 안의 AI만 써요. 쓴 글은 서버를 포함해 어디로도 보내지 않아요.';

  @override
  String get aiStyleNew => '새 말투';

  @override
  String get aiStyleNameHint => '말투 이름 (예: 해적)';

  @override
  String get aiStyleRulesHint =>
      '어떻게 바꿀지 적어 주세요 (예: 해적처럼 써 줘. \'으하하\'를 자주 넣어서)';

  @override
  String get aiStyleIconPick => '아이콘으로 쓸 이모지를 하나 골라요';

  @override
  String get aiStyleEmpty => '아이콘, 이름, 설명을 모두 채워 주세요.';

  @override
  String aiStyleLong(int name, int rules) {
    return '이름은 $name자, 설명은 $rules자까지 쓸 수 있어요.';
  }

  @override
  String get aiStyleBlocked => '이런 지시는 쓸 수 없어요. 다른 말로 적어 주세요.';

  @override
  String get aiStyleSaveInfo => '내 말투는 내 계정 설정에 잠긴 채로 저장돼요. 서버는 내용을 몰라요.';

  @override
  String get aiStyleAdd => '말투 추가';

  @override
  String aiStyleAdded(String name) {
    return '말투를 추가했어요: $name';
  }

  @override
  String get aiStyleAddedHint => '긴 글을 쓸 때 AI 버튼 → 말투에서 골라요.';

  @override
  String get aiStyleExample => '예시';

  @override
  String get aiStyleBefore => '바꾸기 전';

  @override
  String get aiStyleAfter => '바꾼 후';

  @override
  String get aiStyleAnother => '다른 예시';

  @override
  String get aiStyleAddInfo =>
      '이 말투를 AI 편집기에 넣으면 내 메시지를 이렇게 바꿀 수 있어요. 예시는 내 휴대폰 AI가 방금 만들었어요.';

  @override
  String get aiStyleNoAi =>
      '이 휴대폰에서는 AI 편집기를 쓸 수 없어서 예시를 보여 드릴 수 없어요. 말투는 저장해 둘 수 있어요.';

  @override
  String get aiStyleHave => '이미 있는 말투예요';

  @override
  String get aiMyStyles => '내 말투';

  @override
  String get aiMyStylesEmpty => '아직 만든 말투가 없어요. AI 편집기의 말투 탭에서 +를 눌러 만들어요.';

  @override
  String get aiStyleCopyLink => '링크 복사';

  @override
  String get aiStyleSendInfo =>
      '링크 안에 말투가 들어 있어요. 서버에는 저장되지 않고, 몇 명이 쓰는지도 세지 않아요.';

  @override
  String get aiStyleCard => '부루미 말투';

  @override
  String get aiStyleCardOpen => '말투 보기';

  @override
  String get aiEditorSwitch => 'AI 편집기';

  @override
  String get aiEditorSwitchSub => '긴 글을 쓰면 맞춤법·말투·번역 버튼이 생겨요';

  @override
  String get aiNotOnPhone => '이 휴대폰은 기기 안 AI를 지원하지 않아서 AI 편집기가 보이지 않아요.';

  @override
  String get aiStyleFormal => '정중하게';

  @override
  String get aiStyleShort => '짧게';

  @override
  String get aiStyleFriendly => '다정하게';

  @override
  String get aiStyleWork => '업무용';

  @override
  String get aiStyleHistoric => '사극체';

  @override
  String get aiStyleZen => '차분하게';

  @override
  String get aiTryAgain => '다시 하기';

  @override
  String get aiLangKo => '한국어';

  @override
  String get aiLangEn => '영어';

  @override
  String get aiLangJa => '일본어';

  @override
  String get aiLangZh => '중국어';

  @override
  String get aiLangEs => '스페인어';

  @override
  String get aiLangVi => '베트남어';

  @override
  String get aiLangRu => '러시아어';

  @override
  String get aiExample1 => '이번 주말에 시간 되면 같이 저녁 먹을래? 7시쯤 어때?';

  @override
  String get aiExample2 => '오늘 비가 와서 그냥 집에서 쉬려고. 너는 뭐 해?';

  @override
  String get aiExample3 => '다음 달에 이사 가는데 짐 싸는 것 좀 도와줄 수 있어?';

  @override
  String get gateTitle => '가입 심사 도우미';

  @override
  String get gateHeader =>
      '가입 신청이 오면 도우미가 몇 초 안에 확인하고 들여보내거나 거절해요. 대화 내용은 볼 수 없어요.';

  @override
  String get gateOn => '도우미 켜기';

  @override
  String get gateOnInfo =>
      '켜면 \'가입 심사 도우미\' 계정이 이 방에 들어와요. 이 계정은 사람을 들이고 거절하는 일만 할 수 있고, 글을 쓰거나 설정을 바꿀 수 없어요.';

  @override
  String get gateSafety => '안전';

  @override
  String get gateSafetyInfo =>
      '도우미는 암호 열쇠가 없어서 대화 내용을 받을 수 없어요. 서버가 도우미의 열쇠 등록을 막아요. 도우미가 보는 건 신청한 사람의 이름과 질문에 쓴 답뿐이에요.';

  @override
  String get gateCantRead => '대화를 못 읽어요';

  @override
  String get gateHasKeys => '암호 열쇠가 있어요. 도우미를 꺼 주세요';

  @override
  String gateKeyCount(int count) {
    return '암호 열쇠 $count개';
  }

  @override
  String get gateQuestions => '가입 질문';

  @override
  String get gateQuestionsInfo =>
      '신청할 때 답해요. 객관식은 맞았는지 바로 알려 주고 다시 고를 수 있어요. 질문과 답은 암호화되지 않아서 서버도 볼 수 있어요. 개인 정보는 묻지 마세요. 최대 5개.';

  @override
  String gateQuizKind(int count) {
    return '객관식 · 보기 $count개';
  }

  @override
  String get gateWrittenKind => '글로 답하기';

  @override
  String get gateAddQuestion => '질문 추가';

  @override
  String get gateEditQuestion => '질문 고치기';

  @override
  String get gateQuestionHint => '질문 (예: 우리 모임에서 하고 싶은 건?)';

  @override
  String get gateQuizShort => '객관식';

  @override
  String get gateChoices => '보기';

  @override
  String get gateChoicesInfo => '동그라미를 눌러 정답을 골라요. 정답은 신청하는 사람에게 보이지 않아요.';

  @override
  String gateChoiceHint(int n) {
    return '보기 $n';
  }

  @override
  String get gateAddChoice => '보기 추가';

  @override
  String get gateWrittenInfo => '신청하는 사람이 글로 답해요. 관리자가 신청 목록에서 답을 볼 수 있어요.';

  @override
  String get gateRemoveQuestion => '질문 지우기';

  @override
  String get gateRules => '심사 규칙';

  @override
  String get gateRulesInfo =>
      '객관식을 틀리거나 금지어가 있으면 거절해요. 사칭으로 확인된 계정도 거절하고, 확인 중인 계정은 관리자에게 넘겨요. 거절된 사람은 다시 신청할 수 있어요.';

  @override
  String get gateNeedAnswers => '글 답을 비우면 거절';

  @override
  String get gateWords => '금지어';

  @override
  String get gateWordsInfo => '이름이나 답에 이 말이 있으면 거절해요. 한 줄에 하나씩, 최대 30개.';

  @override
  String get gateWordsHint => '예: 코인\n무료 지급';

  @override
  String get gateAi => 'AI로 글 답 확인';

  @override
  String get gateAiInfo =>
      '글 답만 AI에게 보내요. AI는 들여보내거나 관리자에게 넘길 수만 있고, 혼자 거절하지 못해요.';

  @override
  String get gateLog => '심사 기록';

  @override
  String get gateLogNone => '아직 도우미가 확인한 신청이 없어요';

  @override
  String get gateLogInfo =>
      '최근 50개까지 보여요. 잘못 들어온 사람은 멤버 목록에서 내보내고, 잘못 거절된 사람은 다시 신청하면 돼요.';

  @override
  String get gateWhyOk => '질문을 모두 통과했어요';

  @override
  String get gateWhyAi => 'AI가 답을 확인했어요';

  @override
  String get gateWhyQuiz => '객관식 답이 틀렸어요';

  @override
  String get gateWhyEmpty => '글 답을 비웠어요';

  @override
  String get gateWhyWords => '금지어가 있어요';

  @override
  String get gateWhyFake => '사칭으로 확인된 계정이에요';

  @override
  String get gateWhyChecking => '사칭 확인 중인 계정이에요';

  @override
  String get gateWhyHeld => '관리자가 확인해야 해요';

  @override
  String get gateIn => '들어옴';

  @override
  String get gateOut => '거절';

  @override
  String get gateHeld => '관리자 확인';

  @override
  String get gateSending => '신청하고 있어요';

  @override
  String get gateYoureIn => '들어왔어요';

  @override
  String gateYoureInBody(String name) {
    return '$name 질문을 모두 통과했어요';
  }

  @override
  String get gateNotIn => '이번에는 들어갈 수 없어요';

  @override
  String get gateNotInBody => '답을 다시 확인하고 나중에 다시 신청해 주세요';

  @override
  String get gateFailed => '신청하지 못했어요. 다시 해 주세요';

  @override
  String get gateWaiting => '신청했어요';

  @override
  String get gateWaitingBody => '관리자가 확인하면 대화 목록에 나타나요';

  @override
  String gateQuizIntro(int count) {
    return '질문 $count개에 답하면 신청돼요';
  }

  @override
  String gateStep(int now, int total) {
    return '질문 $now/$total';
  }

  @override
  String get gateTryAgain => '아니에요. 다시 골라 보세요';

  @override
  String get gateAnswerHint => '답을 써 주세요';

  @override
  String get gateAnswersSeenBy =>
      '답은 이 방의 관리자와 가입 심사 도우미가 봐요. 암호화되지 않으니 개인 정보는 쓰지 마세요';

  @override
  String get gateGoToGroup => '그룹으로 가기';

  @override
  String get gateGoToChannel => '채널로 가기';

  @override
  String get gateSend => '신청하기';

  @override
  String get gateAnswerAndAsk => '질문에 답하고 신청하기';

  @override
  String get gateHeldNote => '도우미가 정하지 못한 신청만 여기 남아요';

  @override
  String get community => '커뮤니티';

  @override
  String get communityAdd => '커뮤니티에 추가';

  @override
  String get communityIntroBody =>
      '그룹과 채널 여러 개를 하나로 묶어요. 멤버는 한곳에서 다른 대화를 보고 바로 들어갈 수 있어요.';

  @override
  String get communityCreate => '커뮤니티 만들기';

  @override
  String get communityMine => '내 커뮤니티에 추가';

  @override
  String get communityNew => '새 커뮤니티';

  @override
  String get communityName => '커뮤니티 이름';

  @override
  String get communityAbout => '소개 (선택)';

  @override
  String get communityCreateBtn => '만들기';

  @override
  String get communityPrivacy =>
      '어떤 대화가 묶였는지, 커뮤니티 이름이 무엇인지 서버는 몰라요. 멤버 휴대폰에서만 열려요.';

  @override
  String get communityAsOne => '한 대화로 보기';

  @override
  String get communityAsOneFooter => '커뮤니티의 대화를 대화 목록에서 한 줄로 묶어요.';

  @override
  String get communityIn => '내가 들어간 대화';

  @override
  String get communityView => '볼 수 있는 대화';

  @override
  String get communityAsk => '가입 요청할 수 있는 대화';

  @override
  String get communityHiddenTag => '관리자만 보여요';

  @override
  String get communityAddChat => '커뮤니티에 대화 추가';

  @override
  String get communityWhoAdds => '대화를 추가할 수 있는 사람';

  @override
  String get communityAddAll => '모든 멤버';

  @override
  String get communityAddAllInfo => '멤버가 자기 그룹과 채널을 추가할 수 있어요.';

  @override
  String get communityAddAdmins => '관리자만';

  @override
  String get communityAddAdminsInfo => '관리자만 대화를 추가할 수 있어요. 서버가 직접 막아요.';

  @override
  String get communityAdmins => '관리자';

  @override
  String get communityChats => '대화 관리';

  @override
  String get communityChatsFooter =>
      '숨긴 대화는 관리자만 볼 수 있어요. 관리자 열쇠로 따로 잠가서 멤버 휴대폰도 못 열어요.';

  @override
  String get communityHide => '숨기기';

  @override
  String get communityShow => '보이기';

  @override
  String get communityRemoveChat => '커뮤니티에서 빼기';

  @override
  String get communityLeave => '커뮤니티 나가기';

  @override
  String get communityLeaveInfo => '내 대화는 그대로 남고 커뮤니티만 안 보여요.';

  @override
  String get communityDelete => '커뮤니티 없애기';

  @override
  String get communityDeleteInfo => '묶음만 없어지고 그룹과 채널은 그대로 남아요.';

  @override
  String communityRemovingIn(int seconds) {
    return '$seconds초 뒤에 없어져요';
  }

  @override
  String communityCardGroup(String name) {
    return '이 그룹을 $name 커뮤니티에 추가했어요';
  }

  @override
  String communityCardChannel(String name) {
    return '이 채널을 $name 커뮤니티에 추가했어요';
  }

  @override
  String get communityOpen => '보기';

  @override
  String get communityJoin => '들어가기';

  @override
  String get communityAskBtn => '요청';

  @override
  String get communityAskedBtn => '요청함';

  @override
  String get communityAsked => '가입을 요청했어요. 관리자가 받아 주면 들어가져요.';

  @override
  String communityMembers(int count) {
    return '멤버 $count명';
  }

  @override
  String communityChatsCount(int count) {
    return '대화 $count개';
  }

  @override
  String get communityPickTitle => '추가할 대화';

  @override
  String get communityPickEmpty =>
      '추가할 수 있는 그룹이나 채널이 없어요. 내가 방장이나 관리자인 대화만 추가할 수 있어요.';

  @override
  String get communityPickHidden => '관리자만 보이게 추가';

  @override
  String get communityPickFooter =>
      '링크가 없는 대화에는 \'승인 후 참여\' 비공개 링크가 새로 생겨요. 커뮤니티 멤버는 요청하고, 관리자가 받아 줘요.';

  @override
  String get communityAddedToast => '커뮤니티에 추가했어요';

  @override
  String get communityNotYet => '곧 커뮤니티에 들어가져요. 관리자 휴대폰이 열쇠를 보내 주면 바로 보여요.';

  @override
  String get communityEmpty => '아직 대화가 없어요';

  @override
  String get communityOnlyAdmins => '관리자만 할 수 있어요';

  @override
  String get communityInfo => '커뮤니티 정보';

  @override
  String get communityAdminsFooter =>
      '관리자는 대화를 추가·숨기기·빼기 할 수 있어요. 관리자가 되면 숨긴 대화 열쇠를 받아요.';

  @override
  String get communityMakeAdmin => '관리자로 지정';

  @override
  String get communityUnmakeAdmin => '관리자 해제';

  @override
  String get communityRoleOwner => '방장';

  @override
  String get communityRoleAdmin => '관리자';

  @override
  String communityLast(String who, String chat) {
    return '$who › $chat';
  }

  @override
  String get searchFilter => '종류로 찾기';

  @override
  String get kindPhoto => '사진';

  @override
  String get kindVideo => '동영상';

  @override
  String get kindFile => '파일';

  @override
  String get kindLink => '링크';

  @override
  String get kindVoice => '음성 메시지';

  @override
  String get keywordReplies => '키워드 자동 답장';

  @override
  String get keywordRepliesInfo =>
      '멤버 글에 이 단어가 있으면 정한 답을 내 이름으로 달아 줘요. 서버는 글을 못 읽어서 이 휴대폰이 답해요. 같은 단어는 1분에 한 번만 답해요.';

  @override
  String get keywordWordHint => '단어 (예: 회비)';

  @override
  String get keywordAnswerHint => '답 (예: 회비는 매달 1만 원이에요)';

  @override
  String get pollDescription => '설명 (선택)';

  @override
  String get pollAddPhoto => '사진 넣기';

  @override
  String get pollRemovePhoto => '사진 빼기';

  @override
  String get pollAttachTitle => '선택지에 붙이기';

  @override
  String get pollAttachPhoto => '사진';

  @override
  String get pollAttachSticker => '스티커';

  @override
  String get pollAttachPlace => '지금 있는 곳';

  @override
  String get pollAttachRemove => '붙인 것 빼기';

  @override
  String get pollAttachInfo =>
      '선택지마다 사진, 스티커, 장소 중 하나를 붙일 수 있어요. 사진은 이 휴대폰에서 암호화돼 올라가고, 장소는 지도 회사에 묻지 않고 숫자로만 담겨요.';

  @override
  String get pollPickSticker => '스티커 고르기';

  @override
  String get pollAllowAdd => '선택지 추가 허용';

  @override
  String get pollAllowChange => '투표 바꾸기 허용';

  @override
  String get pollShuffle => '선택지 순서 섞기';

  @override
  String get pollHideResults => '마감까지 결과 숨기기';

  @override
  String get pollMoreInfo =>
      '선택지 추가: 멤버가 선택지를 더 넣을 수 있어요 (모두 12개까지, 넣은 사람 이름이 보여요). 순서 섞기: 사람마다 선택지 순서가 달라서 첫 줄에 몰리지 않아요.';

  @override
  String get pollHideAnonInfo =>
      '익명 투표에서 결과를 숨기면, 마감 전까지 숫자가 만든 사람 휴대폰 밖으로 나가지 않아요. 마감되면 그 휴대폰이 결과를 올려요.';

  @override
  String get pollHideOpenInfo =>
      '공개 투표의 표는 대화 안에 암호화돼 있어서 멤버 휴대폰에 함께 저장돼요. 마감 전까지는 앱이 숫자를 가려요.';

  @override
  String get pollNoChangeInfo => '한 번 고르면 바꾸거나 취소할 수 없어요.';

  @override
  String get pollAddTitle => '선택지 추가';

  @override
  String get pollAddDone => '추가';

  @override
  String get pollAddInfo => '내가 넣은 선택지에는 내 이름이 함께 보여요. 같은 선택지는 두 번 넣을 수 없어요.';

  @override
  String pollAddedBy(String name) {
    return '추가: $name';
  }

  @override
  String get pollHiddenUntilEnd => '결과는 마감 후 공개돼요';

  @override
  String get pollViewVotes => '투표 결과 보기';

  @override
  String get pollResults => '투표 결과';

  @override
  String pollVotesN(int n) {
    return '$n표';
  }

  @override
  String get pollNobodyYet => '아직 아무도 고르지 않았어요';

  @override
  String get pollFinalShort => '바꾸기 불가';

  @override
  String get pollFull => '선택지는 12개까지예요';

  @override
  String get pollRepeat => '이미 있는 선택지예요';

  @override
  String get pollAnonResultsInfo => '익명 투표라 누가 골랐는지는 아무에게도 보이지 않아요. 숫자만 보여요.';

  @override
  String get pollChangeVote => '투표 바꾸기';

  @override
  String get articleWrite => '긴 글 쓰기';

  @override
  String get articleExpand => '크게 쓰기';

  @override
  String get articleTitleHint => '제목';

  @override
  String get articleBodyHint => '내용을 써 보세요';

  @override
  String get articleReadAll => '전체 읽기';

  @override
  String articleMinutes(int n) {
    return '약 $n분';
  }

  @override
  String articleChars(int n) {
    return '$n자';
  }

  @override
  String get articleEncrypted => '끝까지 암호화된 글이에요. 서버는 내용을 볼 수 없어요.';

  @override
  String get articleOpenFailed => '글을 열지 못했어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get articleTooLong => '글이 너무 길어요. 10만 자까지 쓸 수 있어요.';

  @override
  String get articleEmpty => '보낼 내용이 없어요.';

  @override
  String get articleSending => '보내는 중이에요…';

  @override
  String get articleDiscardAsk => '쓰던 글을 어떻게 할까요?';

  @override
  String get articleDiscard => '버리기';

  @override
  String get articleKeepDraft => '임시 저장';

  @override
  String get articleDraftNote => '임시 저장에는 사진이 빠져요.';

  @override
  String get articleStyle => '스타일';

  @override
  String get articleInsert => '넣기';

  @override
  String get blockH1 => '큰 제목';

  @override
  String get blockH2 => '작은 제목';

  @override
  String get blockP => '본문';

  @override
  String get blockQuote => '인용';

  @override
  String get blockPull => '큰 인용';

  @override
  String get blockCode => '코드';

  @override
  String get blockMath => '수식';

  @override
  String get blockUl => '목록';

  @override
  String get blockOl => '번호 목록';

  @override
  String get blockTable => '표';

  @override
  String get blockImg => '사진';

  @override
  String get blockHr => '구분선';

  @override
  String get blockRemove => '이 칸 지우기';

  @override
  String get blockUp => '위로 옮기기';

  @override
  String get blockDown => '아래로 옮기기';

  @override
  String get articleCaptionHint => '사진 설명 (선택)';

  @override
  String get articleMathHint => '수식 (예: a^2 + b^2 = c^2)';

  @override
  String get articleCodeHint => '코드';

  @override
  String get articleLangHint => '언어 (선택)';

  @override
  String get articleItemHint => '항목';

  @override
  String get tableAddRow => '행 추가';

  @override
  String get tableAddCol => '열 추가';

  @override
  String get tableDelRow => '마지막 행 지우기';

  @override
  String get tableDelCol => '마지막 열 지우기';

  @override
  String get tableHeader => '첫 행을 머리글로';

  @override
  String get articleAi => 'AI 도우미';

  @override
  String get articleAiInfo => '모두 이 휴대폰 안에서만 처리돼요. 글 내용은 어디로도 보내지 않아요.';

  @override
  String get aiTidy => '자동 정리';

  @override
  String get aiTidySub => '# 제목, - 목록, | 표 |, \$\$수식\$\$ 같은 표시를 서식으로 바꿔요';

  @override
  String get aiPolish => 'AI로 다듬기';

  @override
  String get aiPolishSub => '고른 부분(없으면 지금 칸)을 자연스럽게 다듬어요';

  @override
  String get aiShorter => '짧게 줄이기';

  @override
  String get aiShorterSub => '핵심만 남겨요';

  @override
  String get aiUnavailable => '이 휴대폰에서는 아직 AI 글쓰기를 쓸 수 없어요. 자동 정리는 쓸 수 있어요.';

  @override
  String get aiDone => '바꿨어요. 되돌리기로 돌아갈 수 있어요.';

  @override
  String get articleUndo => '되돌리기';

  @override
  String get articleRedo => '다시 하기';

  @override
  String get roomNight => '야간 모드';

  @override
  String get roomNightInfo =>
      '정한 시간에는 멤버가 글을 쓸 수 없어요. 방장과 관리자는 계속 쓸 수 있어요. 시간은 지금 이 휴대폰 시간대를 따라요.';

  @override
  String nightRange(int from, int to) {
    return '$from시~$to시';
  }

  @override
  String nightBlocked(int hour) {
    return '야간 모드예요. $hour시부터 보낼 수 있어요';
  }

  @override
  String get sendToChannels => '여러 채널에 함께 올리기';

  @override
  String get noOtherChannels => '글을 올릴 수 있는 다른 채널이 없어요';

  @override
  String sendToCount(int n) {
    return '채널 $n곳에 올리기';
  }

  @override
  String sentToCount(int n) {
    return '채널 $n곳에 올렸어요';
  }

  @override
  String get raidLock => '습격 잠금';

  @override
  String get raidLockInfo =>
      '모르는 사람이 링크로 한꺼번에 몰려올 때 켜세요. 켜 두는 동안 링크로 들어오려는 사람은 모두 관리자 승인을 기다려요. 끄면 링크가 원래대로 돌아가요.';

  @override
  String get mentionsOnly => '나를 부를 때만 알림';

  @override
  String get mentionsOnlyInfo =>
      '켜면 그룹에서는 누군가 @내 이름이나 @모두로 불렀을 때만 알림이 와요. 다른 글은 조용히 쌓이고, 대화 목록의 숫자로 볼 수 있어요.';

  @override
  String get messageRequests => '메시지 요청';

  @override
  String get messageRequestsEmpty => '메시지 요청이 없어요';

  @override
  String get messageRequestsInfo =>
      '연락처에 없는 사람이 보낸 1:1 대화예요. 수락하기 전에는 내가 읽었는지 상대가 알 수 없어요.';

  @override
  String get messageRequestBar =>
      '연락처에 없는 사람이 보낸 메시지예요. 수락하면 답장할 수 있고, 삭제해도 상대에게 알리지 않아요.';

  @override
  String get messageRequestAccept => '수락';

  @override
  String get messageRequestDelete => '삭제';

  @override
  String get messageRequestBlock => '삭제하고 차단';

  @override
  String get messageRequestDeleteInfo => '이 대화를 지우고 나가요. 상대에게는 알리지 않아요.';

  @override
  String get messageRequestsSwitchInfo =>
      '켜면 연락처에 없는 사람이 시작한 1:1 대화는 대화 목록 위 ‘메시지 요청’에 따로 모여요. 수락하기 전에는 알림이 조용하고 읽음 표시도 가지 않아요.';

  @override
  String get nameColor => '이름 색';

  @override
  String get nameColorSample => '오늘 모임 몇 시예요?';

  @override
  String get nameColorInfo =>
      '그룹에서 내 메시지 위에 보이는 이름 색이에요. 내가 들어가 있는 모든 그룹에 똑같이 보여요. ‘A’는 이름에 따라 자동으로 정해지는 색이에요.';

  @override
  String get roomName => '이 그룹에서 내 이름';

  @override
  String get roomNameHint => '이름';

  @override
  String get roomNameInfo =>
      '이 그룹 사람들에게만 이 이름으로 보여요. 다른 대화에서는 원래 이름 그대로예요. 비워 두면 원래 이름으로 돌아가요.';

  @override
  String get liveLocation => '실시간 위치';

  @override
  String get liveLocationInfo =>
      '고른 시간 동안 내 위치가 1분마다 대화 안에서 움직여요. 위치는 이 대화 사람들에게만 암호화되어 가고, 언제든 멈출 수 있어요. 앱이 꺼져 있는 동안에는 움직이지 않아요.';

  @override
  String get live15m => '15분 동안 공유';

  @override
  String get live1h => '1시간 동안 공유';

  @override
  String get live8h => '8시간 동안 공유';

  @override
  String get liveLocationEnded => '실시간 위치 (끝남)';

  @override
  String liveLeftMinutes(int n) {
    return '$n분 남음';
  }

  @override
  String liveLeftHours(int n) {
    return '$n시간 남음';
  }

  @override
  String get liveStop => '공유 멈추기';

  @override
  String get editorAuto => '자동';

  @override
  String get editorDraw => '그리기';

  @override
  String get editorText => '글씨';

  @override
  String get editorClearAll => '모두 지우기';

  @override
  String get editorAddText => '글씨 넣기';

  @override
  String get penPen => '펜';

  @override
  String get penArrow => '화살표';

  @override
  String get penMarker => '형광펜';

  @override
  String get penNeon => '네온';

  @override
  String get penEraser => '지우개';

  @override
  String get penBlur => '흐림';

  @override
  String get editAndSend => '편집해서 보내기';

  @override
  String photoOf(int n, int total) {
    return '$n/$total';
  }

  @override
  String get videoMutedToast => '소리를 껐어요. GIF로 보내요';

  @override
  String get videoSoundToast => '소리를 켰어요';

  @override
  String get sendTogether => '묶어서 보내기';

  @override
  String get sendSeparately => '따로 보내기';

  @override
  String get sendSpoiler => '가리고 보내기';

  @override
  String get sendAsFileOriginal => '파일로 보내기 (원본 화질)';

  @override
  String get albumRecents => '최근 항목';

  @override
  String get albumFavorites => '즐겨찾기';

  @override
  String get albumVideos => '동영상';

  @override
  String get albumScreenshots => '스크린샷';

  @override
  String get albumSelfies => '셀피';

  @override
  String get albumLive => 'Live Photos';

  @override
  String get newLoginTitle => '누군가 새 기기로 내 계정에 로그인했어요';

  @override
  String newLoginBody(String device, String when) {
    return '$device · $when. 본인이 맞나요?';
  }

  @override
  String get newLoginJustNow => '방금';

  @override
  String get newLoginYes => '네, 저예요';

  @override
  String get newLoginNo => '아니요, 제가 아니에요';

  @override
  String get newLoginOut => '이 기기 로그아웃';

  @override
  String newLoginOutDone(String device) {
    return '$device을(를) 로그아웃시켰어요';
  }

  @override
  String get newLoginChangePw => '다시 들어오지 못하게 비밀번호도 바꾸는 게 좋아요.';

  @override
  String get later => '나중에';

  @override
  String get ok => '확인';

  @override
  String get deviceUnnamed => '이름 없는 기기';

  @override
  String get deleteForMeOnly => '나에게서만 지우기';

  @override
  String get deleteForBothShort => '나와 상대 모두에게서 지우기';

  @override
  String deleteForMeAnd(String name) {
    return '나와 $name 모두에게서 지우기';
  }

  @override
  String get dateWipeTitle => '날짜로 지우기';

  @override
  String get dateWipeHint =>
      '하루를 누르거나, 두 날짜를 눌러 그 사이를 모두 골라요. 진하게 보이는 날에 메시지가 있어요.';

  @override
  String get dateWipePick => '날짜를 골라 주세요';

  @override
  String dateWipeButton(String range, int count) {
    return '$range 메시지 $count개 지우기';
  }

  @override
  String dateWipeAsk(int count) {
    return '메시지 $count개를 지울까요?';
  }

  @override
  String dateWipeIn(int left) {
    return '$left초 뒤 지워요';
  }

  @override
  String get dateWipeMenu => '날짜로 지우기';

  @override
  String get voiceBlockedLine => '음성 메시지 (받지 않게 해 둔 사람)';

  @override
  String get voiceClosedTitle => '음성 메시지를 보낼 수 없어요';

  @override
  String voiceClosedBody(String name) {
    return '$name 님이 음성·영상 메시지를 받지 않게 해 두었어요. 글이나 사진은 보낼 수 있어요.';
  }

  @override
  String get whoVoice => '음성·영상 메시지';

  @override
  String get whoVoiceInfo =>
      '고른 사람만 나에게 음성 메시지와 동그라미 영상을 보낼 수 있어요. 1:1 대화에 적용돼요. 상대 앱에는 마이크 버튼이 흐리게 보여요.';

  @override
  String get strangerArchive => '모르는 사람 새 대화 보관하기';

  @override
  String get strangerArchiveSub => '친구가 아닌 사람의 첫 메시지는 알림 없이 보관함으로 가요.';

  @override
  String get strangerTucked => '모르는 사람의 새 대화를 보관함에 넣었어요';

  @override
  String get callsEdit => '편집';

  @override
  String get callsSelect => '선택';

  @override
  String get callsClearAll => '통화 기록 모두 지우기';

  @override
  String callsDeleteN(int count) {
    return '지우기 ($count)';
  }

  @override
  String callsDeleteAsk(int count) {
    return '통화 기록 $count개를 지울까요?';
  }

  @override
  String callsDeleteIn(int left) {
    return '$left초 뒤 통화 기록을 지워요';
  }

  @override
  String get callsDeleteBothNote => '양쪽에서 지우면 상대 휴대폰의 기록도 사라져요.';

  @override
  String get deviceSheetCalls => '이 기기로 통화 받기';

  @override
  String get deviceSheetCallsSub => '끄면 이 기기는 전화가 와도 울리지 않아요.';

  @override
  String get deviceSheetOut => '이 기기 로그아웃';

  @override
  String get deviceSheetLastSeen => '마지막 사용';

  @override
  String get deviceSheetKind => '종류';

  @override
  String get deviceKindPhone => '휴대폰';

  @override
  String get deviceKindPc => 'PC';

  @override
  String get deviceKindWeb => '웹';

  @override
  String get deviceIdleTitle => '오래 안 쓴 기기 자동 로그아웃';

  @override
  String get deviceIdleInfo =>
      '이 기간 동안 한 번도 쓰지 않은 기기는 서버가 알아서 로그아웃시켜요. 잃어버린 휴대폰이나 남의 PC에 남은 로그인을 막아요.';

  @override
  String get deviceIdleOff => '안 함';

  @override
  String get idleDays7 => '1주';

  @override
  String get idleDays30 => '1개월';

  @override
  String get idleDays90 => '3개월';

  @override
  String get idleDays180 => '6개월';

  @override
  String get idleDays365 => '1년';

  @override
  String get linkPc => 'QR로 PC 연결';

  @override
  String get linkPcInfo => 'PC 부루미 화면의 QR을 이 휴대폰으로 찍으면 비밀번호 없이 바로 로그인돼요.';

  @override
  String get linkPcScanTitle => 'PC 화면의 QR 찍기';

  @override
  String get linkPcStep1 => 'PC에서 부루미를 열어요.';

  @override
  String get linkPcStep2 => '로그인 화면의 \'QR로 로그인\'을 눌러요.';

  @override
  String get linkPcStep3 => '이 화면으로 PC의 QR을 찍어요.';

  @override
  String get linkPcConfirmTitle => '이 PC에 로그인할까요?';

  @override
  String linkPcConfirmBody(String device) {
    return '$device. 내가 지금 직접 띄운 화면이 맞을 때만 눌러요. 누가 보내 준 QR이면 절대 찍지 마세요.';
  }

  @override
  String get linkPcConfirm => '로그인';

  @override
  String get linkPcDone => 'PC에 로그인했어요. PC에서 이모지 확인을 마치면 예전 대화도 보여요.';

  @override
  String get linkPcBad => '부루미 PC 로그인 QR이 아니에요';

  @override
  String get linkPcExpired => 'QR 시간이 지났어요. PC에서 새 QR을 띄워 주세요.';

  @override
  String get linkPcNoCamera => '이 기기에서는 카메라로 찍을 수 없어요. 휴대폰 앱에서 해 주세요.';

  @override
  String get qrLoginTitle => 'QR로 로그인';

  @override
  String get qrLoginStep1 => '휴대폰에서 부루미를 열어요.';

  @override
  String get qrLoginStep2 => '설정 > 기기 > QR로 PC 연결을 눌러요.';

  @override
  String get qrLoginStep3 => '휴대폰으로 이 QR을 찍어요.';

  @override
  String get qrLoginWaiting => '휴대폰에서 확인하기를 기다리는 중…';

  @override
  String get qrLoginNew => '새 QR 만들기';

  @override
  String get qrLoginPassword => '아이디와 비밀번호로 로그인';

  @override
  String get qrLoginOff => '이 앱은 아직 QR 로그인 서버에 연결되지 않았어요.';

  @override
  String get phoneCall => '전화 걸기';

  @override
  String get phoneText => '문자 보내기';

  @override
  String get phoneCopy => '번호 복사';

  @override
  String get phoneSave => '휴대폰 연락처에 저장';

  @override
  String get phoneCopied => '번호를 복사했어요';

  @override
  String get videoNoteOnceHint => '한 번만 보기: 받는 사람이 한 번 본 뒤 사라져요';

  @override
  String get onceRoundSent => '한 번만 보기';

  @override
  String get onceRoundExpired => '만료된 영상 메시지';

  @override
  String get onceRoundClose => '닫고 삭제';

  @override
  String get storyScrubHint => '좌우로 밀어 이동';

  @override
  String get camFlashWarm => '따뜻함';

  @override
  String get camFlashBright => '밝기';

  @override
  String get camFlashFront => '앞카메라로 찍을 때 화면이 이 색으로 밝아져요';

  @override
  String birthdayBannerOne(String name) {
    return '$name님이 오늘 생일이에요!';
  }

  @override
  String birthdayBannerMany(int n) {
    return '친구 $n명이 오늘 생일이에요!';
  }

  @override
  String get birthdayBannerSub => '눌러서 축하 메시지를 보내 보세요';

  @override
  String birthdayTodayLine(String date) {
    return '오늘 생일 🎂 · $date';
  }

  @override
  String get firstHelloTitle => '아직 메시지가 없어요';

  @override
  String get firstHelloSub => '아래 인사를 눌러 첫 마디를 건네 보세요';

  @override
  String firstHelloTap(String name) {
    return '눌러서 $name님에게 인사 보내기';
  }

  @override
  String get liveTextButton => '글자';

  @override
  String get liveTextTitle => '사진 속 글자';

  @override
  String get liveTextHint => '줄을 눌러 고르세요. 안 고르면 전부 복사해요';

  @override
  String liveTextPicked(int n) {
    return '$n줄 골랐어요';
  }

  @override
  String get liveTextNoneSel => '선택 해제';

  @override
  String get liveTextCopied => '글자를 복사했어요';

  @override
  String get liveTextPaste => '입력칸을 길게 눌러 붙여넣으세요';

  @override
  String get liveTextNone => '이 사진에서 글자를 찾지 못했어요';

  @override
  String get liveTextAll => '전체 선택';

  @override
  String get callNoteAsk => '받지 않았어요. 메시지를 남길까요?';

  @override
  String get callNoteVoice => '음성 남기기';

  @override
  String get callNoteVideo => '영상 남기기';

  @override
  String callNoteTo(String name) {
    return '$name님에게 남길 말';
  }

  @override
  String get callNoteVoiceHint => '누르면 녹음해요. 한 번 더 누르면 보내요.';

  @override
  String get idKey => '아이디 키';

  @override
  String get idKeyMine => '내 키';

  @override
  String get idKeyHint => '예: blue7';

  @override
  String get idKeyInfo =>
      '키를 정하면, 처음 대화하는 사람은 아이디와 이 키를 둘 다 알아야 메시지를 보낼 수 있어요. 키가 틀리면 메시지가 오지 않고, 보낸 사람에게도 알리지 않아요. 친구와 이미 대화한 사람은 그대로예요. 키는 이 폰에만 있고 서버로 가지 않아요. 글자·숫자 4~20자예요.';

  @override
  String get idKeyBad => '글자나 숫자로 4~20자를 써 주세요.';

  @override
  String get idKeyOff => '키 끄기';

  @override
  String get idKeyOffInfo => '끄면 기다리던 처음 대화도 다시 들어와요.';

  @override
  String get idKeyEnterHint => '아이디 키 (받았다면)';

  @override
  String get idKeyEnterInfo => '상대가 아이디 키를 알려 줬다면 같이 써요. 처음 대화할 때만 필요해요.';

  @override
  String get voiceToText => '글로 보기';

  @override
  String get voiceToTextFailed =>
      '이 폰에서는 글로 바꿀 수 없어요. 폰 설정에서 음성 인식 언어를 내려받으면 돼요.';

  @override
  String get voiceToTextEmpty => '들리는 말이 없어요.';

  @override
  String get voiceToTextOnPhone => '이 폰 안에서만 바꿨어요';

  @override
  String get voiceTranslate => '번역';

  @override
  String get voiceTranslating => '번역하는 중…';

  @override
  String get voiceShowOriginal => '번역 숨기기';

  @override
  String unreadSummaryAsk(int count) {
    return '안 읽은 메시지 $count개 요약 보기';
  }

  @override
  String get unreadSummaryTitle => '안 읽은 메시지 요약';

  @override
  String get unreadSummaryFailed => '지금은 요약할 수 없어요. 글로 된 메시지만 요약해요.';

  @override
  String get unreadSummaryOnPhone => '이 폰 AI로만 요약했어요. 대화는 폰 밖으로 나가지 않아요.';

  @override
  String get postSummaryButton => '요약';

  @override
  String get postSummaryBusy => '요약하는 중…';

  @override
  String get postSummaryOriginal => '원문 보기';

  @override
  String get postSummaryTitle => 'AI 요약';

  @override
  String get postSummaryFailed => '지금은 요약할 수 없어요. 잠시 뒤 다시 해 보세요.';

  @override
  String get postSummaryOnPhone => '이 폰 AI로만 요약했어요. 글은 폰 밖으로 나가지 않아요.';

  @override
  String get postSummarySwitch => '긴 글 요약';

  @override
  String get postSummarySwitchSub => '그룹·채널의 긴 글 위에 \'요약\' 버튼이 보여요';

  @override
  String get readerButton => '읽기 모드';

  @override
  String get readerMenu => '읽기 모드로 열기';

  @override
  String get readerLoading => '페이지를 가져오는 중…';

  @override
  String get readerFailed => '이 페이지는 읽기 모드로 열 수 없어요. 브라우저로 열어 보세요.';

  @override
  String get readerOpenBrowser => '브라우저로 열기';

  @override
  String get readerTextSize => '글자 크기';

  @override
  String readerMinutes(int minutes) {
    return '$minutes분 읽기';
  }

  @override
  String get readerSummaryAsk => 'AI로 3줄 요약 보기';

  @override
  String get readerFootnote =>
      '이 폰이 사이트에서 직접 가져와 읽기 좋게 정리했어요. 부루미 서버는 어떤 글을 읽었는지 몰라요.';

  @override
  String get readerLinkCopied => '링크를 복사했어요';

  @override
  String get readerSwitch => '링크에 \'읽기 모드\' 버튼 보이기';

  @override
  String get readerSwitchInfo =>
      '기사 링크를 광고·메뉴 없이 깔끔한 글로 읽어요. 이 폰이 사이트에서 직접 가져오고, 부루미 서버는 거치지 않아요.';

  @override
  String get audioPlay => '재생';

  @override
  String get audioPause => '일시 정지';

  @override
  String get audioPrevious => '이전 곡';

  @override
  String get audioNext => '다음 곡';

  @override
  String get audioRepeat => '반복';

  @override
  String get audioRepeatOff => '반복하지 않아요';

  @override
  String get audioRepeatAll => '목록 전체를 반복해요';

  @override
  String get audioRepeatOne => '이 곡만 반복해요';

  @override
  String audioPlaylist(int count) {
    return '재생 목록 $count곡';
  }

  @override
  String get audioSpeedTitle => '재생 속도';

  @override
  String get audioSpeedPlain => '보통';

  @override
  String get audioSpeedNormal => '보통 속도로 재생해요';

  @override
  String audioSpeedSet(String speed) {
    return '$speed배 속도로 재생해요';
  }

  @override
  String get protectIntroInfoDm => '이 대화에서는 나와 상대 모두 아래 일을 할 수 없어요.';

  @override
  String get protectIntroInfoRoom => '이 방의 모든 멤버가 아래 일을 할 수 없어요.';

  @override
  String get protectIntroShot => '화면 캡처·녹화 막기';

  @override
  String get protectIntroShotSub => '캡처하거나 녹화하면 대화가 까맣게 나와요';

  @override
  String get protectIntroForward => '전달 막기';

  @override
  String get protectIntroForwardSub => '메시지를 다른 대화로 보낼 수 없어요';

  @override
  String get protectIntroSave => '저장·복사 막기';

  @override
  String get protectIntroSaveSub => '사진·영상 저장과 글 복사가 안 돼요';

  @override
  String get protectIntroOnlyMe => '끌 수 있는 사람은 켠 나뿐이에요.';

  @override
  String get protectNoticeMine => '내가 이 대화의 공유를 막았어요';

  @override
  String protectNoticeOther(String name) {
    return '$name님이 이 대화의 공유를 막았어요';
  }

  @override
  String get protectNoticeRoom => '이 방은 공유가 막혀 있어요';

  @override
  String get protectMenuFooter => '공유가 막힌 대화라 복사·전달·저장할 수 없어요';

  @override
  String get protectOnlyOwner => '상대가 켠 공유 비활성화는 상대만 끌 수 있어요';

  @override
  String get protectByOther => '공유 비활성화 (상대가 켬)';

  @override
  String get reportStepTitle => '무엇이 문제인가요?';

  @override
  String get reportSubTitle => '조금 더 알려 주세요';

  @override
  String get reportNoteTitle => '더 알려 줄 내용 (선택)';

  @override
  String get reportNoteHint => '예: 이 사람이 여러 방에 같은 글을 올려요';

  @override
  String get reportSend => '신고하기';

  @override
  String get reportUrgentLine => '이 신고는 운영자가 가장 먼저 봐요';

  @override
  String get reportDislikeInfo => '이 신고는 운영자에게 가지 않아요. 이 폰에서 이렇게 할 수 있어요.';

  @override
  String get reportDislikeHide => '이 메시지 내 폰에서 숨기기';

  @override
  String get reportDislikeBlock => '보낸 사람 차단하기';

  @override
  String get reportDislikeHidden => '이 메시지를 내 폰에서 숨겼어요';

  @override
  String get reportCopyrightInfo =>
      '저작권 침해는 권리자(만든 사람이나 회사)가 직접 신고해요. 웹 신고서에서 원본과 연락처를 적어 주세요.';

  @override
  String get reportCopyrightOpen => '권리자 신고서 열기';

  @override
  String get reportHiddenMsg => '내 폰에서 숨긴 메시지예요';

  @override
  String get rDislike => '그냥 싫어요';

  @override
  String get rChild => '아동 학대·아동 성착취';

  @override
  String get rChildSexual => '아동 성착취물';

  @override
  String get rChildAbuse => '아동 폭행·학대';

  @override
  String get rChildDanger => '아동을 노리는 접근 (그루밍)';

  @override
  String get rSexualCrime => '불법 촬영물·성착취물 (합성 포함)';

  @override
  String get rHiddenCamera => '몰래 찍은 사진·영상';

  @override
  String get rDeepfake => '합성한 사진·영상 (딥페이크)';

  @override
  String get rSharedNoConsent => '동의 없이 퍼뜨린 사진';

  @override
  String get rExtortion => '사진으로 하는 협박';

  @override
  String get rViolence => '폭력이나 위협';

  @override
  String get rThreat => '나나 다른 사람을 해치겠다는 위협';

  @override
  String get rGraphic => '잔인한 장면';

  @override
  String get rSelfHarm => '자해·자살 부추김';

  @override
  String get rHate => '혐오 표현';

  @override
  String get rGoods => '불법 상품·서비스';

  @override
  String get rDrugs => '마약·불법 약물';

  @override
  String get rWeapons => '무기';

  @override
  String get rFakeDocs => '위조 문서·신분증';

  @override
  String get rGoodsOther => '기타 불법 거래';

  @override
  String get rAdult => '음란물';

  @override
  String get rPorn => '성인 음란물';

  @override
  String get rUnwanted => '원치 않는 성적인 메시지';

  @override
  String get rPrivacy => '개인정보 노출';

  @override
  String get rIdDocs => '신분증·주민등록번호';

  @override
  String get rContact => '전화번호·주소';

  @override
  String get rPhotos => '내 사진을 허락 없이 올림';

  @override
  String get rTerror => '테러·극단주의';

  @override
  String get rTerrorPromo => '테러를 칭찬하거나 알리기';

  @override
  String get rTerrorRecruit => '테러 계획·사람 모으기';

  @override
  String get rScam => '사기·스팸';

  @override
  String get rPhishing => '가짜 링크로 비밀번호 빼 가기 (피싱)';

  @override
  String get rMoney => '돈 사기·투자 사기';

  @override
  String get rSpam => '스팸 광고';

  @override
  String get rCopyright => '저작권 침해';

  @override
  String get rTakedown => '불법은 아니지만 내려야 해요';

  @override
  String get firstPhotoChanged => '프로필 사진 바뀜';

  @override
  String get firstNameChanged => '이름 바뀜';

  @override
  String firstDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get firstToday => '오늘';

  @override
  String get firstNotChanged => '최근 30일 없음';

  @override
  String get firstGroupsTitle => '같이 있는 그룹';

  @override
  String get firstGroupsNone => '없음';

  @override
  String get firstAboutTitle => '처음 대화하는 사람이에요';

  @override
  String get ageQuarter => '1~3개월 전';

  @override
  String get ageHalf => '3개월~1년 전';

  @override
  String get firstNotFriend => '친구가 아닌 사람이에요';

  @override
  String get onceVoice => '한 번만 듣기 음성';

  @override
  String get onceVoiceTap => '눌러서 한 번 들어요';

  @override
  String get onceVoiceSent => '한 번만 들을 수 있어요';

  @override
  String get onceVoiceExpired => '들은 음성 메시지';

  @override
  String get onceVoiceOn => '한 번만 듣기 켜짐: 상대가 한 번 들으면 사라져요';

  @override
  String get onceVoiceOff => '한 번만 듣기 꺼짐';

  @override
  String get onceVoiceHint => '눌러서 한 번만 재생되게 해요';

  @override
  String get onceVoiceClose => '닫고 삭제';

  @override
  String get onceVoiceInfo => '한 번 들으면 사라져요. 저장하거나 전달할 수 없어요.';

  @override
  String get permMediaAll => '미디어 보내기';

  @override
  String get permPhoto => '사진';

  @override
  String get permVideo => '동영상';

  @override
  String get permFile => '파일';

  @override
  String get permMusic => '음악';

  @override
  String get permVoice => '음성 메시지';

  @override
  String get permVideoNote => '동그라미 영상';

  @override
  String get permExceptions => '예외';

  @override
  String get permExceptionAdd => '예외 추가';

  @override
  String get permExceptionInfo => '특정 멤버만 다르게 정할 수 있어요. 방장과 관리자는 늘 모두 쓸 수 있어요.';

  @override
  String get permExceptionRemove => '예외 지우기';

  @override
  String permExceptionCount(int n) {
    return '$n개 다름';
  }

  @override
  String get permPickMember => '멤버 고르기';

  @override
  String get permTextLocked => '이 방에서는 글을 보낼 수 없어요';

  @override
  String permKindBlocked(String what) {
    return '이 방에서는 $what 보내기가 막혀 있어요';
  }

  @override
  String get reportBlockedSender => '보낸 사람을 차단했어요';

  @override
  String get shareHistory => '최근 메시지 50개 같이 보내기';

  @override
  String get shareHistoryInfo =>
      '새 멤버가 들어오기 전 대화도 읽을 수 있게 내 폰이 보내 줘요. 그 사람 폰으로만 암호화해서 가고, 서버는 내용을 몰라요. 글만 보내고 사진·파일은 보내지 않아요.';

  @override
  String get sendHistory => '지난 메시지 보내기';

  @override
  String sendHistoryDone(int count, String name) {
    return '$name님에게 지난 메시지 $count개를 보냈어요';
  }

  @override
  String earlierBar(int count) {
    return '들어오기 전 대화 $count개 보기';
  }

  @override
  String get earlierTitle => '들어오기 전 대화';

  @override
  String get earlierInfo => '멤버가 내 폰으로만 보내 준 지난 메시지예요. 이 폰에만 있어요.';

  @override
  String earlierMedia(String name, String time) {
    return '$name · 사진이나 파일 ($time)';
  }

  @override
  String get fmtQuote => '인용';

  @override
  String get fmtFoldQuote => '접는 인용';

  @override
  String replyFromOtherChat(String name) {
    return '$name · 다른 대화';
  }

  @override
  String quotingWho(String name) {
    return '인용 · $name';
  }

  @override
  String get quotePickPart => '특정 부분 인용';

  @override
  String get replyInOtherChat => '다른 대화에서 답장';

  @override
  String get replyNone => '답장 안 함';

  @override
  String get replyInWhichChat => '답장할 대화';

  @override
  String get quotePickTitle => '인용할 부분';

  @override
  String get quotePickHint => '손잡이를 끌어 인용할 부분을 골라요';

  @override
  String quotePickCount(int n) {
    return '고른 글자 $n자';
  }

  @override
  String pinAlsoFor(String name) {
    return '$name님에게도 고정';
  }

  @override
  String get pinAlsoForOn => '두 사람 모두에게 보여요.';

  @override
  String get pinOnlyMeInfo => '이 휴대폰에서 나만 봐요. 상대방에게는 아무것도 가지 않아요.';

  @override
  String get pinnedOnlyMe => '나만 보이게 고정했어요';

  @override
  String get pinOnlyMeTag => '나만';

  @override
  String get attachScan => '문서 스캔';

  @override
  String scanFileName(String time) {
    return '스캔 $time';
  }

  @override
  String get scanNotHere => '문서 스캔은 폰 앱에서 쓸 수 있어요';

  @override
  String get pack_hip => '힙 프렌즈';

  @override
  String get pack_dandy => '댄디 프렌즈';

  @override
  String charEmojiTitle(String name) {
    return '$name 이모지';
  }

  @override
  String get charReactionsTitle => '캐릭터 반응';

  @override
  String get translate => '번역';

  @override
  String trToLang(String lang) {
    return '$lang로 번역하기';
  }

  @override
  String get trShowOriginal => '원문 보기';

  @override
  String get trOtherLang => '다른 언어로 번역';

  @override
  String trDontTranslate(String lang) {
    return '$lang 번역하지 않기';
  }

  @override
  String get trHideBar => '이 대화에서 가리기';

  @override
  String get trHiddenNote => '번역 줄을 가렸어요. 메시지를 꾹 눌러 번역을 열면 다시 켤 수 있어요.';

  @override
  String get trShowButton => '번역 버튼 보기';

  @override
  String get trShowButtonSub => '메시지를 꾹 누르면 번역이 나와요';

  @override
  String get trChat => '대화 전체 번역';

  @override
  String get trChatSub => '다른 언어 대화 위에 번역 줄이 나와요';

  @override
  String get trSkip => '번역하지 않을 언어';

  @override
  String get trFooter =>
      '번역은 이 휴대폰 안에서만 해요. 글이 번역 서버로 가지 않아요. 언어마다 처음 한 번만 받아요 (와이파이, 약 30MB).';

  @override
  String get trWebDemo => '웹 미리보기는 정해진 예시 번역만 보여 줘요.';

  @override
  String get trAppLang => '앱 언어';

  @override
  String trDownloadAsk(String lang) {
    return '$lang 번역을 받을까요?';
  }

  @override
  String get trDownloadInfo => '한 번만 받으면 인터넷 없이도 번역돼요. 와이파이에서 받아요 (약 30MB).';

  @override
  String get trDownload => '받기';

  @override
  String get trDownloading => '받는 중…';

  @override
  String get trDownloadFailed => '받지 못했어요. 와이파이에 연결한 뒤 다시 해 주세요.';

  @override
  String get trUnsupported => '이 휴대폰에서는 번역할 수 없어요';

  @override
  String get trFailed => '번역하지 못했어요';

  @override
  String trSameLang(String lang) {
    return '이미 $lang예요';
  }

  @override
  String get trWholeChatOn => '대화 전체 번역 켜기';

  @override
  String get trTranslating => '번역하는 중…';

  @override
  String get trLang_ko => '한국어';

  @override
  String get trLang_en => '영어';

  @override
  String get trLang_ja => '일본어';

  @override
  String get trLang_zh => '중국어';

  @override
  String get trLang_es => '스페인어';

  @override
  String get trLang_fr => '프랑스어';

  @override
  String get trLang_de => '독일어';

  @override
  String get trLang_ru => '러시아어';

  @override
  String get trLang_pt => '포르투갈어';

  @override
  String get trLang_it => '이탈리아어';

  @override
  String get trLang_vi => '베트남어';

  @override
  String get trLang_th => '태국어';

  @override
  String get trLang_id => '인도네시아어';

  @override
  String get trLang_tr => '튀르키예어';

  @override
  String get trLang_ar => '아랍어';

  @override
  String get trLang_hi => '힌디어';

  @override
  String get trLang_uk => '우크라이나어';

  @override
  String get trLang_pl => '폴란드어';

  @override
  String get trLang_nl => '네덜란드어';

  @override
  String newLoginMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String get deviceIdlePage => '자동 로그아웃';

  @override
  String get deviceIdleHeader => '이 기간 동안 안 쓰면 로그아웃';

  @override
  String get whoInfoVoice =>
      '내 연락처가 아닌 사람의 전화는 부재중으로 남고, 메시지·초대는 보이지 않아요. 음성·영상 메시지를 막은 사람은 마이크 버튼이 잠겨서 글로만 보낼 수 있어요.';

  @override
  String get qrLoginHeading => '휴대폰으로 QR을 찍어 로그인';

  @override
  String get searchTabChats => '대화';

  @override
  String get searchTabChannels => '채널';

  @override
  String get searchTabPosts => '글';

  @override
  String get searchTabMedia => '미디어';

  @override
  String get searchTabLinks => '링크';

  @override
  String get searchTabFiles => '파일';

  @override
  String get searchTabMusic => '음악';

  @override
  String get searchTabVoice => '음성';

  @override
  String get searchSectionChats => '대화';

  @override
  String get searchSectionGlobal => '전체 검색';

  @override
  String get searchSectionMessages => '메시지';

  @override
  String get searchScopeAll => '모든 대화';

  @override
  String get searchScopeDirect => '1:1 대화';

  @override
  String get searchScopeGroup => '그룹';

  @override
  String get searchScopeChannel => '채널';

  @override
  String get searchScopeTitle => '어느 대화에서 찾을까요?';

  @override
  String get searchRecent => '최근 검색';

  @override
  String get searchClear => '지우기';

  @override
  String get searchMyChannels => '참여한 채널';

  @override
  String get searchPublicChannels => '공개 채널';

  @override
  String get searchFollowedPosts => '구독한 채널의 글';

  @override
  String get searchPublicPosts => '공개 채널 글';

  @override
  String get searchPublicPostsNote =>
      '웹 페이지를 켠 공개 채널의 글만 보여요. 찾는 단어는 서버에 남지 않아요.';

  @override
  String get searchPostsHint => '채널 글에서 찾을 단어를 써 주세요';

  @override
  String get searchChannelsHint => '채널 이름이나 주소를 써 주세요';

  @override
  String get searchOnPhoneNote => '메시지·사진·파일은 이 휴대폰 안에서만 찾아요. 서버는 무엇을 찾는지 몰라요.';

  @override
  String get searchNoResults => '찾는 결과가 없어요';

  @override
  String get searchMore => '더 보기';

  @override
  String get searchLess => '접기';

  @override
  String get tagThisChat => '이 대화';

  @override
  String get tagMyMessages => '내 메시지';

  @override
  String get tagPublicPosts => '공개 글';

  @override
  String get tagShowChat => '대화로 보기';

  @override
  String get tagShowList => '목록으로 보기';

  @override
  String get tagShowGrid => '사진으로 보기';

  @override
  String get tagJoinToSee => '참여하면 이 대화의 글을 볼 수 있어요';

  @override
  String get tagOpenChat => '미리 보기';

  @override
  String get tagStoriesTitle => '해시태그 스토리';

  @override
  String get tagStoriesEmpty => '이 해시태그가 붙은 스토리가 없어요';

  @override
  String get tagStoriesNote => '내가 볼 수 있는 친구 스토리에서만 찾아요';

  @override
  String searchMembers(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '멤버 $nString명';
  }

  @override
  String searchSubscribers(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '구독자 $nString명';
  }

  @override
  String tagCount(int n) {
    return '메시지 $n개';
  }

  @override
  String tagStories(int n) {
    return '스토리 $n개';
  }

  @override
  String tagInChat(String address) {
    return '대화: $address';
  }

  @override
  String tagStoriesSub(String tag) {
    return '스토리 보기 · $tag';
  }

  @override
  String dayRangeSameMonth(String from, int day) {
    return '$from–$day일';
  }

  @override
  String get stkWeather => '날씨';

  @override
  String get stkPlace => '위치';

  @override
  String get stkLink => '링크';

  @override
  String get stkWeatherTitle => '날씨 스티커';

  @override
  String get stkWeatherHere => '지금 있는 곳';

  @override
  String get stkWeatherHereSub => '위치를 약 10km 단위로 뭉개서 날씨만 물어봐요';

  @override
  String get stkWeatherCity => '도시 고르기';

  @override
  String get stkWeatherCitySub => '위치를 전혀 쓰지 않아요';

  @override
  String get stkWeatherFinding => '날씨를 가져오는 중이에요';

  @override
  String get stkWeatherShowCity => '도시 이름 보이기';

  @override
  String get stkWeatherInfo =>
      '스토리에는 온도와 날씨만 들어가요. 내 위치는 친구에게도, 부루미에도 남지 않아요. 친구는 자기 나라 단위(°C·°F)로 보고, 눌러서 바꿀 수 있어요.';

  @override
  String get stkWeatherNoLocation => '위치를 쓸 수 없어서 도시를 골라 주세요';

  @override
  String get stkWeatherOff => '이 버전에서는 날씨를 가져올 수 없어요';

  @override
  String get stkWeatherNetwork => '날씨를 가져오지 못했어요. 잠시 뒤 다시 해 주세요';

  @override
  String get stkLook => '모양';

  @override
  String get stkLookWhite => '흰색';

  @override
  String get stkLookDark => '어둡게';

  @override
  String get stkLookClear => '투명';

  @override
  String get stkLookColor => '내 색';

  @override
  String get stkSearchCity => '도시 검색';

  @override
  String get stkNearby => '가까운 도시';

  @override
  String get stkCities => '도시';

  @override
  String get stkPlaceTitle => '위치 스티커';

  @override
  String get stkPlaceName => '장소 이름 (예: 성수동 카페거리)';

  @override
  String get stkPlaceMap => '친구가 지도에서 열 수 있게';

  @override
  String get stkPlaceExact => '정확한 위치';

  @override
  String get stkPlaceRough => '대략 (약 1km)';

  @override
  String get stkPlaceFinding => '위치를 찾는 중이에요';

  @override
  String get stkPlaceNoLocation => '위치를 쓸 수 없어서 이름만 붙여요';

  @override
  String get stkPlaceInfo =>
      '이름과 위치는 스토리 안에 암호화되어 친구에게만 가요. 지도를 켜지 않으면 이름만 보여요.';

  @override
  String get stkLinkTitle => '링크 스티커';

  @override
  String get stkLinkUrl => '주소 (https://…)';

  @override
  String get stkLinkName => '보일 이름 (선택)';

  @override
  String get stkLinkSmall => '작게';

  @override
  String get stkLinkCard => '카드';

  @override
  String get stkLinkInfo =>
      '미리보기는 내 폰이 만들어 스토리 안에 암호화해 넣어요. 친구들은 스토리를 볼 때 이 사이트에 접속하지 않아요.';

  @override
  String get stkLinkBad => '웹 주소를 넣어 주세요';

  @override
  String get stkLinkReading => '미리보기를 만드는 중이에요';

  @override
  String get stkLinkPreviewOff => '링크 미리보기가 꺼져 있어서 작게만 보여요';

  @override
  String get stkLinkOpen => '열기';

  @override
  String get stkLinkGoesTo => '이 링크가 가는 곳';

  @override
  String get stkLinkLookalike => '보이는 이름과 실제 주소가 달라요. 주소를 꼭 확인하세요';

  @override
  String get stkMapOpen => '지도에서 보기';

  @override
  String get stkPlaceOnlyName => '지도 위치 없이 이름만 붙였어요';

  @override
  String get roomPhotoNote =>
      '사진은 방 안에서 암호화돼서 보내져요. 공개 링크가 있는 방만 링크 미리보기에도 이 사진이 보여요.';

  @override
  String roomPhotoLine(String who, String kind, String done) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'channel': '채널',
      'other': '그룹',
    });
    String _temp1 = intl.Intl.selectLogic(done, {
      'removed': '지웠어요',
      'other': '바꿨어요',
    });
    return '$who님이 $_temp0 사진을 $_temp1';
  }

  @override
  String roomPhotoLineMine(String kind, String done) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'channel': '채널',
      'other': '그룹',
    });
    String _temp1 = intl.Intl.selectLogic(done, {
      'removed': '지웠어요',
      'other': '바꿨어요',
    });
    return '$_temp0 사진을 $_temp1';
  }

  @override
  String get roomPhotoPreview => '사진을 바꿨어요';

  @override
  String get meetupEndToggle => '끝나는 시간';

  @override
  String get meetupStarts => '시작';

  @override
  String get meetupEnds => '종료';

  @override
  String get meetupBring => '같이 오는 사람';

  @override
  String meetupWithGuests(String name, int n) {
    return '$name +$n';
  }

  @override
  String get meetupAddCalendar => '캘린더에 추가';

  @override
  String get meetupCalendarFile => '캘린더 파일을 받았어요. 열면 캘린더에 들어가요';

  @override
  String get meetupRemind => '1시간 전에 알림';

  @override
  String get meetupRemindInfo =>
      '\'갈게요\'나 \'아마도\'로 답한 일정은 시작 1시간 전에 이 폰이 알려 줘요. 서버는 몰라요.';

  @override
  String get myPlans => '내 일정';

  @override
  String get myPlansEmpty =>
      '아직 일정이 없어요. 대화에서 + > 일정으로 만들거나, 받은 일정에 \'갈게요\'를 누르면 여기에 모여요.';

  @override
  String get myPlansPast => '지난 일정';

  @override
  String get myPlansSoon => '다가오는 일정';

  @override
  String meetupReminderTitle(String title) {
    return '1시간 뒤: $title';
  }

  @override
  String get myPlansMade => '내가 만든 일정';

  @override
  String get myPlansGoing => '갈게요';

  @override
  String get earlierVoice => '음성 메시지';

  @override
  String get earlierFileFailed => '파일을 열 수 없어요. 보낸 사람이 지웠을 수 있어요.';

  @override
  String get callIgnore => '무시';

  @override
  String get callUnknown => '연락처에 없는 사람이에요';

  @override
  String callCommonGroups(int n) {
    return '같은 그룹 $n개';
  }

  @override
  String get callNoCommon => '같은 그룹 없음';

  @override
  String get callLock => '화면 잠금';

  @override
  String get callLocked => '화면 잠김 · 길게 눌러 풀기';

  @override
  String get filterMentions => '멘션';

  @override
  String get mentionNone => '나를 부른 대화가 없어요';

  @override
  String get newGroupFromMembers => '이 멤버로 새 그룹 만들기';

  @override
  String get reportPerson => '신고하기';

  @override
  String reportPersonNote(int n) {
    return '이 사람이 보낸 최근 메시지 $n개까지 운영팀에 함께 보내요';
  }

  @override
  String get reportPersonEmpty => '이 사람이 보낸 메시지가 없어 신고할 내용이 없어요';

  @override
  String get storageByChat => '대화별 저장 공간';

  @override
  String get storageByChatInfo =>
      '내려받은 사진·영상·파일이 이 폰에 차지하는 크기예요. 지워도 메시지는 그대로고, 누르면 다시 받아요.';

  @override
  String get storageGoneChat => '나간 대화';

  @override
  String storageFiles(int n) {
    return '파일 $n개';
  }

  @override
  String get storageChatTotal => '이 대화가 차지하는 크기';

  @override
  String get storageChatInfo => '지워도 메시지는 남아요. 대화에서 다시 누르면 내려받아요.';

  @override
  String get storageClearChat => '이 대화 파일 모두 지우기';

  @override
  String storageClearPicked(int n) {
    return '고른 파일 $n개 지우기';
  }

  @override
  String get storageChatFiles => '큰 파일부터';

  @override
  String get storageChatEmpty => '이 폰에 받아 둔 파일이 없어요';

  @override
  String get storageNoName => '이름 없는 파일';

  @override
  String storageGoing(int count, int n) {
    return '파일 $count개 $n초 뒤 지워요';
  }

  @override
  String get videoEditTitle => '동영상 편집';

  @override
  String get videoRotate => '회전';

  @override
  String get videoFlip => '뒤집기';

  @override
  String get videoSound => '소리';

  @override
  String get videoEditFailed => '영상을 편집하지 못해서 보내지 않았어요';

  @override
  String get videoEditing => '영상을 만드는 중이에요';

  @override
  String get photoHdOn => 'HD 화질로 보내요';

  @override
  String get photoHdOff => '표준 화질로 보내요. 데이터를 아껴요';

  @override
  String get sendHd => 'HD 화질로 보내기';

  @override
  String get photoHdSetting => '사진을 HD로 보내기';

  @override
  String get photoHdSettingSub => '끄면 표준 화질로 보내서 데이터와 저장 공간을 아껴요';

  @override
  String get albumPreview => '미리보기';

  @override
  String get albumPreviewHint => '꾹 눌러 끌면 순서가 바뀌어요';

  @override
  String get pickEdit => '편집';

  @override
  String get pickTrim => '자르기·회전';

  @override
  String get pickSpoilerOn => '가리기';

  @override
  String get pickSpoilerOff => '가리기 풀기';

  @override
  String get pickRemove => '빼기';

  @override
  String spoilerCount(int count) {
    return '$count개 가림';
  }

  @override
  String get aiAgeTitle => 'AI 기능은 만 18세 이상만 쓸 수 있어요';

  @override
  String get aiAgeInfo =>
      '안드로이드의 휴대폰 속 AI(Google)는 약관에 따라 만 18세 이상만 쓸 수 있어요. 한 번만 물어보고, 설정 › 대화 › AI 기능에서 바꿀 수 있어요.';

  @override
  String get aiAgeAdult => '만 18세 이상이에요';

  @override
  String get aiAgeMinor => '18세 미만이에요';

  @override
  String get aiAgeOnly => '18세 이상만 쓸 수 있어요';

  @override
  String get aiAgeRow => 'AI 나이 확인';

  @override
  String get aiAgeRowSub => 'AI 편집기·요약·배경 지우기 (안드로이드)';

  @override
  String get aiAgeValueAdult => '만 18세 이상';

  @override
  String get aiAgeValueMinor => '18세 미만';

  @override
  String get aiAgeValueUnknown => '확인 전';

  @override
  String get trPoweredByGoogle => 'Powered by Google Translate';

  @override
  String get stkWeatherCredit => '날씨 정보: MET Norway 자료 기반 (CC BY 4.0)';

  @override
  String get creditsHeader => '출처';

  @override
  String get creditsFooter => '눌러서 자세한 내용과 원문 라이선스를 볼 수 있어요.';

  @override
  String get creditWeather => '날씨 정보';

  @override
  String get creditWeatherSub => 'MET Norway · CC BY 4.0';

  @override
  String get creditWeatherInfo =>
      '스토리 날씨 스티커의 날씨는 노르웨이 기상청(MET Norway) 자료를 바탕으로 해요. 우리 서버가 위치를 약 10 km 단위로 흐리게 해서 묻고, 앱이 기온과 날씨 그림으로 바꿔 보여 줘요.';

  @override
  String get creditGoogle => '번역·AI (안드로이드)';

  @override
  String get creditGoogleSub => 'Google ML Kit';

  @override
  String get creditGoogleInfo =>
      '안드로이드에서는 번역, 문서 스캔, 배경 지우기, AI 편집기를 Google ML Kit이 휴대폰 안에서 처리해요. 내용은 회사로 보내지 않아요. 번역 결과 아래에는 Google 표시가 붙어요. 아이폰은 애플 기본 기능을 써요.';

  @override
  String get creditFont => '글꼴';

  @override
  String get creditFontSub => 'Pretendard · SIL OFL 1.1';

  @override
  String get creditFontInfo =>
      '앱 글꼴은 Pretendard예요. 누구나 무료로 쓸 수 있는 SIL 오픈 폰트 라이선스라서 원문을 함께 실어요.';

  @override
  String get creditPdq => '사진 지문';

  @override
  String get creditPdqSub => 'PDQ (Meta) · 안전 서버';

  @override
  String get creditPdqInfo =>
      '알려진 불법 사진을 찾을 때 Meta가 공개한 PDQ 사진 지문 방식을 우리 안전 서버에서 써요. 비공개 대화의 사진은 검사하지 않아요.';

  @override
  String partsHeader(int count) {
    return '앱 부품 $count개';
  }

  @override
  String get importTitle => '다른 앱 대화 가져오기';

  @override
  String get importHeader =>
      '카카오톡 · 왓츠앱 · 텔레그램에서 내보낸 대화를 원래 날짜 그대로 부루미 대화방에 넣어요.';

  @override
  String get importAppKakao => '카카오톡';

  @override
  String get importAppWhatsapp => '왓츠앱';

  @override
  String get importAppTelegram => '텔레그램';

  @override
  String get importDeviceIphone => '아이폰';

  @override
  String get importDeviceAndroid => '안드로이드';

  @override
  String get importDevicePc => 'PC';

  @override
  String importHowTo(String app) {
    return '$app에서 내보내는 방법';
  }

  @override
  String get importStepsKakaoPhone =>
      '가져올 대화방을 열고 오른쪽 위 ☰ 메뉴를 눌러요\n메뉴 아래쪽 ⚙ 설정에서 \'대화 내용 내보내기\'를 눌러요\n사진까지 가져오려면 \'모든 메시지 내부 저장소에 저장\', 글만 가져오려면 \'텍스트 메시지만 보내기\'를 골라요\n저장된 파일(.zip 또는 .txt)을 아래 \'내보낸 파일 고르기\'로 골라요';

  @override
  String get importStepsKakaoPc =>
      'PC 카카오톡에서 대화방을 열고 오른쪽 위 ☰ 메뉴를 눌러요\n\'대화 내보내기\'를 눌러 .txt 파일로 저장해요\n그 파일을 휴대폰으로 옮기거나 PC용 부루미에서 바로 골라요';

  @override
  String get importStepsWhatsappIphone =>
      '가져올 대화방을 열고 맨 위 상대 이름(또는 그룹 이름)을 눌러요\n아래로 내려 \'대화 내보내기\'를 눌러요\n사진까지 가져오려면 \'미디어 첨부\'를 골라요\n\'파일에 저장\'으로 저장한 뒤, 아래 \'내보낸 파일 고르기\'로 골라요';

  @override
  String get importStepsWhatsappAndroid =>
      '가져올 대화방을 열고 오른쪽 위 ⋮ 를 눌러요\n\'더보기\' → \'대화 내보내기\'를 눌러요\n사진까지 가져오려면 \'미디어 포함\'을 골라요\n파일로 저장한 뒤, 아래 \'내보낸 파일 고르기\'로 골라요';

  @override
  String get importStepsTelegram =>
      '컴퓨터용 텔레그램(Telegram Desktop)에서 대화방을 열고 오른쪽 위 ⋮ 를 눌러요\n\'대화 기록 내보내기\'를 눌러요\n사진까지 가져오려면 사진 · 파일을 켜고, 형식은 \'JSON\'(또는 HTML)을 골라요\n다 되면 내보낸 폴더를 통째로 압축(.zip)해서, 아래 \'내보낸 파일 고르기\'로 골라요';

  @override
  String get importTelegramPhoneNote =>
      '휴대폰 텔레그램 앱에는 대화 내보내기가 없어서 컴퓨터용 텔레그램을 써야 해요.';

  @override
  String get importKakaoMediaNote => '글만 내보낸 파일이면 사진 자리에 \'사진\'이라고만 표시돼요.';

  @override
  String get importWhatsappMediaNote =>
      '\'미디어 없이\'로 내보내면 사진 자리에 \'사진\'이라고만 표시돼요.';

  @override
  String get importPrivacy =>
      '파일은 이 휴대폰 안에서만 읽어요. 보낼 때는 이 휴대폰에서 암호화해서 보내니, 서버는 내용도 누가 썼는지도 볼 수 없어요.';

  @override
  String get importPick => '내보낸 파일 고르기';

  @override
  String get importSample => '예시 파일로 해 보기';

  @override
  String get importReading => '대화를 읽고 있어요';

  @override
  String get importPickFailed => '파일을 고를 수 없어요. 다시 해 주세요.';

  @override
  String get importErrBig => '파일이 너무 커요. 사진 없이 내보내거나 기간을 나눠서 해 주세요.';

  @override
  String get importErrEmpty => '파일에 메시지가 없어요.';

  @override
  String get importErrBroken => '파일이 깨져서 열 수 없어요. 다시 내보내 주세요.';

  @override
  String get importErrUnknown => '카카오톡 · 왓츠앱 · 텔레그램에서 내보낸 대화 파일이 아니에요.';

  @override
  String get importPickChat => '가져올 대화 고르기';

  @override
  String get importNoTitle => '이름 없는 대화';

  @override
  String importCount(int count) {
    return '메시지 $count개';
  }

  @override
  String get importCheckTitle => '가져올 대화 확인';

  @override
  String get importWhoIsMe => '이 중에 나는 누구인가요?';

  @override
  String get importWhoIsMeInfo =>
      '고른 이름의 메시지는 내 말풍선(오른쪽)으로 보여요. 다른 사람은 원래 앱의 이름으로 보여요.';

  @override
  String importPeerInfo(String name, String peer) {
    return '$name 님의 메시지는 이 대화의 $peer 님 말풍선으로 보여요.';
  }

  @override
  String get importWhere => '어디에 넣을까요?';

  @override
  String get importPickRoom => '넣을 대화방 고르기';

  @override
  String get importPickRoomInfo => '가져온 메시지는 이 대화방의 모든 사람이 볼 수 있어요.';

  @override
  String get importKindDirect => '1:1 대화';

  @override
  String get importKindGroup => '그룹';

  @override
  String get importKindChannel => '채널';

  @override
  String get importMedia => '사진 · 동영상 · 파일';

  @override
  String importMediaSize(int count, String size) {
    return '$count개 · $size';
  }

  @override
  String get importNoMedia => '이 파일에는 사진이 들어 있지 않아요';

  @override
  String importMissingInfo(int count) {
    return '사진 · 파일 $count개는 내보낸 파일에 없어서 자리만 표시돼요. 사진까지 가져오려면 원래 앱에서 사진을 포함해 다시 내보내 주세요.';
  }

  @override
  String get importStart => '가져오기';

  @override
  String importConfirmTitle(String room, int count) {
    return '$room 대화방에 메시지 $count개를 넣을까요?';
  }

  @override
  String get importConfirmInfo => '원래 날짜와 시간 순서대로 들어가고, 말풍선마다 \'가져옴\' 표시가 붙어요.';

  @override
  String importStepMedia(int done, int total) {
    return '사진과 파일을 암호화해서 올리고 있어요 ($done/$total)';
  }

  @override
  String get importStepPack => '메시지를 암호화해서 묶고 있어요';

  @override
  String get importStepSend => '거의 다 됐어요';

  @override
  String get importKeepOpen => '다 될 때까지 이 화면을 열어 두세요.';

  @override
  String importDone(int count) {
    return '메시지 $count개를 가져왔어요!';
  }

  @override
  String get importFailed => '가져오지 못했어요. 인터넷 연결을 확인하고 다시 해 주세요.';

  @override
  String get importRetry => '다시 하기';

  @override
  String get importStop => '그만두기';

  @override
  String get importSeeChat => '대화 보기';

  @override
  String importLineMine(String app, int count) {
    return '$app에서 대화를 가져왔어요 · 메시지 $count개';
  }

  @override
  String importLine(String name, String app, int count) {
    return '$name 님이 $app에서 대화를 가져왔어요 · 메시지 $count개';
  }

  @override
  String get importInfoTitle => '가져온 대화';

  @override
  String get importInfoCount => '메시지';

  @override
  String get importInfoDates => '기간';

  @override
  String get importInfoBy => '가져온 사람';

  @override
  String get importInfoByMe => '나';

  @override
  String get importInfoNote =>
      '가져온 메시지는 다른 앱에서 내보낸 파일 그대로예요. 부루미가 보낸 사람을 확인한 메시지가 아니라서 \'가져옴\' 표시가 붙어요.';

  @override
  String get importDelete => '가져온 대화 지우기';

  @override
  String get importedMark => '가져옴';

  @override
  String get importSticker => '스티커';

  @override
  String importNotIncluded(String kind) {
    return '$kind · 내보낸 파일에 없음';
  }

  @override
  String importSysCreate(String name) {
    return '$name 님이 대화방을 만들었어요';
  }

  @override
  String importSysJoin(String name) {
    return '$name 님이 들어왔어요';
  }

  @override
  String importSysLeft(String name) {
    return '$name 님이 내보냈어요';
  }

  @override
  String importSysPin(String name) {
    return '$name 님이 메시지를 고정했어요';
  }

  @override
  String importSysCall(String name) {
    return '$name 님의 통화';
  }

  @override
  String importSysTitle(String name, String title) {
    return '$name 님이 이름을 바꿨어요: $title';
  }

  @override
  String importSysPhoto(String name) {
    return '$name 님이 사진을 바꿨어요';
  }

  @override
  String importSysOther(String name) {
    return '$name 님의 알림';
  }

  @override
  String get importRow => '다른 앱 대화 가져오기';

  @override
  String get importRowSub => '카카오톡 · 왓츠앱 · 텔레그램';

  @override
  String get importMenu => '대화 가져오기';

  @override
  String get importDeleted => '삭제된 메시지';

  @override
  String get importAlready => '이 대화방에 같은 대화를 이미 가져왔어요. 또 가져오면 메시지가 두 번씩 보여요.';

  @override
  String invJoined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString명 참여';
  }

  @override
  String invPeopleLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString명 남음';
  }

  @override
  String invDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString일 남음';
  }

  @override
  String invHoursLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString시간 남음';
  }

  @override
  String invMinutesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString분 남음';
  }

  @override
  String get invEnded => '기간 끝남';

  @override
  String get invFull => '인원 마감';

  @override
  String get invRevoked => '취소됨';

  @override
  String get invMoreHeader => '추가 링크';

  @override
  String get invMoreInfo =>
      '인스타 프로필용, 친구용처럼 링크를 여러 개 만들 수 있어요. 기간이 끝나거나 인원이 차면 서버가 바로 막아서, 내 폰이 꺼져 있어도 지켜져요.';

  @override
  String get invNew => '새 링크 만들기';

  @override
  String get invRevokedHeader => '취소된 링크';

  @override
  String get invDeleteAllRevoked => '취소된 링크 모두 지우기';

  @override
  String invDeleteAllIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString초 뒤에 취소된 링크를 지워요';
  }

  @override
  String get invNewTitle => '새 링크';

  @override
  String get invEditTitle => '링크 수정';

  @override
  String get invMake => '만들기';

  @override
  String get invNameHint => '링크 이름 (예: 인스타 프로필)';

  @override
  String get invNameInfo => '이름은 관리자만 봐요. 받는 사람에게는 보이지 않아요.';

  @override
  String get invTime => '기간';

  @override
  String get inv1h => '1시간';

  @override
  String get inv1d => '1일';

  @override
  String get inv1w => '1주';

  @override
  String get invNoLimit => '제한 없음';

  @override
  String get invPick => '직접';

  @override
  String get invTimeNone => '끝나는 날 없이 계속 열려 있어요';

  @override
  String invTimeEnds(String time) {
    return '$time에 끝나요';
  }

  @override
  String get invPeople => '인원';

  @override
  String invPeopleCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString명';
  }

  @override
  String get invPeopleHint => '몇 명까지 들어올 수 있는지 숫자로 적어 주세요';

  @override
  String invPeopleN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString명이 들어오면 링크가 닫혀요';
  }

  @override
  String get invPeopleNone => '몇 명이든 들어올 수 있어요';

  @override
  String get invPeopleApproval =>
      '승인 후 참여가 켜져 있어서 관리자가 한 명씩 들여보내요. 그래서 인원 제한 대신 기간만 쓰여요.';

  @override
  String get invRevokedInfo => '취소한 링크라서 더 이상 열리지 않아요.';

  @override
  String get invFullInfo => '정한 인원이 다 들어와서 더 이상 열리지 않아요. 링크 수정에서 인원을 늘릴 수 있어요.';

  @override
  String get invEndedInfo => '기간이 끝나서 더 이상 열리지 않아요. 링크 수정에서 기간을 늘릴 수 있어요.';

  @override
  String invJoinedHeader(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '이 링크로 들어온 사람 $countString명';
  }

  @override
  String get invJoinedMore => '최근 100명까지 보여요.';

  @override
  String get invNobody => '아직 아무도 안 들어왔어요';

  @override
  String get invLeftRoom => '지금은 나간 사람';

  @override
  String get invRevoke => '링크 취소';

  @override
  String invRevokeIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString초 뒤에 링크를 취소해요';
  }

  @override
  String get invDelete => '링크 지우기';

  @override
  String invDeleteIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString초 뒤에 링크를 지워요';
  }

  @override
  String get joinLinkEnded => '이 초대 링크는 기간이 끝났어요';

  @override
  String get joinLinkFull => '이 초대 링크는 인원이 다 찼어요';

  @override
  String get chatLinks => '대화 링크';

  @override
  String get chatLinksAbout =>
      '링크를 누른 사람에게 나와의 대화가 열리고, 미리 써 둔 글이 입력창에 들어가 있어요. 가게 문의나 행사 신청 받을 때 좋아요.';

  @override
  String get chatLinksFooter =>
      '링크에는 내 아이디가 들어 있어요. 링크 목록은 이 폰에만 있고, 누가 눌렀는지는 서버도 몰라서 세지 않아요.';

  @override
  String get chatLinkNew => '대화 링크 만들기';

  @override
  String get chatLinkEdit => '대화 링크';

  @override
  String get chatLinkNoText => '미리 쓴 글 없음';

  @override
  String get chatLinkPreview => '받는 사람에게 이렇게 보여요';

  @override
  String get chatLinkText => '미리 쓸 글';

  @override
  String get chatLinkTextHint => '예: 케이크 주문하고 싶어요';

  @override
  String get chatLinkTextInfo => '링크를 누른 사람의 입력창에 들어가요. 그 사람이 고치거나 지우고 직접 보내요.';

  @override
  String get chatLinkNameHint => '링크 이름 (예: 가게 문의)';

  @override
  String get chatLinkNameInfo => '이름은 나만 봐요.';

  @override
  String get chatLinkKey => '아이디 키 넣기';

  @override
  String get chatLinkKeyInfo =>
      '켜면 처음 보는 사람도 아이디 키 없이 대화를 시작할 수 있어요. 링크가 퍼지면 키도 같이 퍼져요.';

  @override
  String get chatLinkIdInfo => '링크를 받은 사람은 내 아이디를 볼 수 있어요.';

  @override
  String get chatLinkDelete => '링크 지우기';

  @override
  String chatLinkDeleteIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return '$secondsString초 뒤에 링크를 지워요';
  }

  @override
  String get chatLinkWaiting => '입력창에 들어갈 글';

  @override
  String get chatLinkStart => '메시지 보내기';

  @override
  String get qrSeeChannel => '채널 보기';

  @override
  String get qrSeeGroup => '그룹 보기';

  @override
  String get qrChat => '대화하기';

  @override
  String get qrMessage => '메시지 링크';

  @override
  String get qrSee => '보기';

  @override
  String get qrPc => 'PC에서 로그인';

  @override
  String get qrConnect => '연결하기';

  @override
  String get qrExpired => '시간이 지난 QR 코드예요';

  @override
  String get qrOpenLink => '링크 열기';

  @override
  String get qrCopyText => '글 복사하기';

  @override
  String qrWebTitle(String host) {
    return '$host 사이트로 이동할까요?';
  }

  @override
  String get qrScan => 'QR 코드 읽기';

  @override
  String get qrScanHint => 'QR 코드를 네모 안에 비춰 주세요';

  @override
  String get qrNoCamera => '카메라를 쓸 수 없어요';

  @override
  String get shareInTitle => '부루미로 보내기';

  @override
  String get shareInComment => '메시지 추가';

  @override
  String get shareInFrom => '보낼 계정';

  @override
  String get shareInNoPost => '이 대화에는 글을 쓸 수 없어요';

  @override
  String get shareInKind => '이 대화는 이 종류를 막아 두었어요';

  @override
  String get shareInLater => '지금은 보낼 수 없는 시간이에요';

  @override
  String get shareInSlow => '조금 뒤에 보낼 수 있어요';

  @override
  String get shareInNone => '보낼 수 있는 대화가 없어요';

  @override
  String shareInSending(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return '보내는 중 $percentString%';
  }

  @override
  String shareInSent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곳에 보냈어요';
  }

  @override
  String shareInFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곳에는 못 보냈어요';
  }

  @override
  String get shareInDemo => '다른 앱에서 보내기 체험';

  @override
  String shareInSendN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곳에 보내기';
  }

  @override
  String get editorSticker => '스티커';

  @override
  String get editorAddSticker => '스티커·이모지 넣기';

  @override
  String get editorStickerHint => '누르면 메뉴, 두 손가락으로 크기·각도, 휴지통으로 끌면 지워져요';

  @override
  String get stkPhotoCut => '사진 오려 붙이기';

  @override
  String get stkFlip => '뒤집기';

  @override
  String get stkCopy => '복제';

  @override
  String get stkCutout => '오려내기';

  @override
  String get cutoutFail => '이 기기에서는 배경을 지울 수 없어요';

  @override
  String get colorTitle => '색';

  @override
  String get colorGrid => '격자';

  @override
  String get colorSpectrum => '스펙트럼';

  @override
  String get colorSliders => '슬라이더';

  @override
  String get colorRed => '빨강';

  @override
  String get colorGreen => '초록';

  @override
  String get colorBlue => '파랑';

  @override
  String get mediaChanged => '사진 바뀜';

  @override
  String get editFirstPhoto => '바뀌기 전 사진';

  @override
  String get captionAboveMenu => '설명 위로 올리기';

  @override
  String get captionUp => '설명 위로 올리기';

  @override
  String get captionDown => '설명 아래로 내리기';

  @override
  String get editSwapPhoto => '다른 사진·동영상으로 바꾸기';

  @override
  String get editThisPhoto => '이 사진 편집';

  @override
  String get editAddPhoto => '사진·동영상 넣기';

  @override
  String get editingMedia => '사진 수정';

  @override
  String get editMediaHint => '여기를 누르면 사진 바꾸기·편집';

  @override
  String get editNewPhotoPicked => '새 사진으로 바뀌어요';

  @override
  String get noSwapPublic => '공개 그룹·채널에서는 보낸 사진을 바꿀 수 없어요. 설명만 고칠 수 있어요.';

  @override
  String get editMediaFailed => '수정하지 못했어요. 잠시 뒤 다시 해 주세요.';

  @override
  String get photoMineForThem => '내가 정한 사진';

  @override
  String get photoTheirs => '올린 사진';

  @override
  String get myProfile => '내 프로필';

  @override
  String get myProfileSeenBy => '보는 사람';

  @override
  String get seenEveryone => '모든 사람';

  @override
  String get seenContacts => '내 연락처';

  @override
  String get myProfileEveryoneInfo =>
      '내 아이디를 아는 누구나 이렇게 봐요. \'모두\'로 둔 것만 서버에 저장돼요.';

  @override
  String get myProfileContactsInfo =>
      '나와 1:1 대화를 하는 사람은 이렇게 봐요. 서버를 거치지 않고 암호화된 1:1 대화로만 전달돼요.';

  @override
  String myProfileHidden(String what) {
    return '안 보이는 것: $what';
  }

  @override
  String get myProfileWho => '누가 무엇을 볼지 바꾸기';

  @override
  String get myProfileEdit => '편집';

  @override
  String get myProfileNoPhoto => '사진이 안 보여요';

  @override
  String get publicPhoto => '공개 사진';

  @override
  String get publicPhotoSet => '공개 사진 설정';

  @override
  String get publicPhotoChange => '공개 사진 바꾸기';

  @override
  String get publicPhotoRemove => '공개 사진 지우기';

  @override
  String get publicPhotoInfo =>
      '프로필 사진을 볼 수 없는 사람에게는 이 사진이 대신 보여요. 공개 사진은 서버에 저장돼요.';

  @override
  String get publicPhotoDone => '공개 사진을 정했어요';

  @override
  String get publicPhotoRemoved => '공개 사진을 지웠어요';

  @override
  String get oldPhotos => '예전 사진';

  @override
  String get oldPhotosInfo =>
      '예전 사진은 이 휴대폰에만 암호화되어 있어요. 다른 사람에게는 대표 사진 한 장만 보여요.';

  @override
  String get photoMain => '대표 사진';

  @override
  String get photoMakeMain => '대표 사진으로';

  @override
  String get photoMainDone => '이제 대표 사진이에요';

  @override
  String get photoDeleted => '사진을 지웠어요';

  @override
  String photoUsedUntil(String date) {
    return '$date까지 쓴 사진';
  }

  @override
  String photoSuggest(String name) {
    return '$name님에게 사진 제안';
  }

  @override
  String get photoSuggestInfo =>
      '고른 사진은 암호화되어 1:1 대화로 가요. 받은 사람이 \'내 사진으로\'를 눌러야 바뀌어요.';

  @override
  String get photoSuggestSent => '사진을 제안했어요';

  @override
  String get photoSuggestNoChat => '1:1 대화가 있어야 사진을 제안할 수 있어요';

  @override
  String get photoSuggestMine => '프로필 사진을 제안했어요';

  @override
  String photoSuggestTheirs(String name) {
    return '$name님이 프로필 사진을 제안했어요';
  }

  @override
  String get photoSuggestView => '사진 보기';

  @override
  String get photoSuggestUse => '내 사진으로';

  @override
  String get photoSuggestPreview => '🖼️ 사진 제안';

  @override
  String get emojiPhoto => '이모지나 스티커로';

  @override
  String get emojiPhotoTitle => '이모지 사진';

  @override
  String get emojiPhotoEmoji => '이모지';

  @override
  String get emojiPhotoSticker => '부루미';

  @override
  String get emojiPhotoSize => '크기';

  @override
  String get emojiPhotoColor => '배경';

  @override
  String get emojiPhotoCustom => '직접 고르기';

  @override
  String get emojiPhotoInfo => '사진이 없어도 이모지나 부루미 캐릭터로 나만의 프로필 사진을 만들 수 있어요.';

  @override
  String get skEdit => '고치기';

  @override
  String get skKeep => '프로필에 남기기';

  @override
  String get skUnkeep => '프로필에서 빼기';

  @override
  String get skAlbumPut => '앨범에 넣기';

  @override
  String get skTop => '맨 위에 고정';

  @override
  String get skUntop => '고정 풀기';

  @override
  String get skCover => '표지 고르기';

  @override
  String get skDelete => '스토리 지우기';

  @override
  String get skFailed => '지금은 바꿀 수 없어요. 잠시 뒤에 다시 해 주세요';

  @override
  String get skKeptDone => '프로필에 남겼어요';

  @override
  String get skUnkeptDone => '프로필에서 뺐어요';

  @override
  String skDeleteIn(int n) {
    return '$n초 뒤에 지워져요';
  }

  @override
  String get skTopFull => '맨 위에는 3개까지 고정할 수 있어요';

  @override
  String get skAlbums => '앨범';

  @override
  String get skAlbumNone => '앨범 없음';

  @override
  String get skAlbumNew => '새 앨범';

  @override
  String get skAlbumName => '앨범 이름';

  @override
  String get skAlbumInfo =>
      '앨범은 프로필에서 스토리를 주제별로 모아 보여 줘요. 그 스토리를 받은 친구에게만 보여요.';

  @override
  String get skCoverTitle => '표지';

  @override
  String get skCoverNone => '이 영상에서는 장면을 꺼낼 수 없어요';

  @override
  String get skCoverInfo => '프로필과 보관함에 이 장면이 보여요';

  @override
  String skKeptCount(int n) {
    return '프로필 스토리 $n개';
  }

  @override
  String get skAll => '전체';

  @override
  String get skPostOpen => '글 보기';

  @override
  String get skMusicTooBig => '음악 파일은 10MB까지 넣을 수 있어요';

  @override
  String get skReact => '반응';

  @override
  String get skMusic => '음악';

  @override
  String get skRound => '동그라미 영상';

  @override
  String get skReactPick => '반응 스티커';

  @override
  String get skReactInfo => '친구가 누르면 나에게만 반응이 와요';

  @override
  String get skEdited => '수정됨';

  @override
  String get skReactSent => '반응을 보냈어요';

  @override
  String get skSaved => '고쳤어요';

  @override
  String get skCoverPill => '표지';

  @override
  String skSplit(int n) {
    return '긴 영상이라 스토리 $n개로 나눠 올려요';
  }

  @override
  String get skSplitInfo => '누르면 그 부분을 빼요';

  @override
  String get skGroupStory => '그룹 스토리';

  @override
  String get skGroupStoryNew => '그룹 스토리 올리기';

  @override
  String get skChannelStoryNew => '채널 스토리 올리기';

  @override
  String get skGroupStoryInfo =>
      '운영자만 올릴 수 있어요. 멤버 모두가 대화 목록 위에서 봐요. 그룹 암호화 안에서만 가요.';

  @override
  String get skGroupOpen => '그룹으로 가기';

  @override
  String get skGroupShared => '그룹 스토리를 올렸어요';

  @override
  String get skToStory => '내 스토리';

  @override
  String get skKeptMine => '프로필 스토리';

  @override
  String get skKeptEmpty => '프로필에 남긴 스토리가 없어요. 내 스토리를 열고 ⋯ 버튼에서 프로필에 남기기를 눌러요.';

  @override
  String get skKeptInfo =>
      '24시간이 지나도 친구들이 내 프로필에서 볼 수 있어요. 그 스토리를 받은 친구에게만 보여요.';

  @override
  String get skMore => '더 보기';

  @override
  String get skMuteTap => '눌러서 소리 켜고 끄기';

  @override
  String get skRoundShort => '동그라미';

  @override
  String quickForwardIn(int n) {
    return '$n초 뒤에 전달해요';
  }

  @override
  String quickForwardTo(String name) {
    return '받는 곳: $name';
  }

  @override
  String get quickForwardHint => '화살표를 꾹 누른 채 밀면 바로 전달돼요';

  @override
  String nextChannelPull(int n) {
    return '안 읽은 글 $n개 · 위로 밀어 다음 채널';
  }

  @override
  String get nextChannelLetGo => '놓으면 다음 채널로 가요';

  @override
  String get sendAsTitle => '보내는 이름';

  @override
  String get sendAsInfo => '이 대화에서 내 글이 어떤 이름으로 보일지 골라요';

  @override
  String get sendAsMe => '내 이름과 사진으로 보여요';

  @override
  String get sendAsChannelHidden => '채널 이름만 보이고 내 이름은 안 보여요';

  @override
  String get sendAsMyChannel => '내 공개 채널 이름으로 보여요';

  @override
  String sendAsChanged(String name) {
    return '$name 이름으로 보내요';
  }

  @override
  String get showAuthors => '작성자 프로필 보이기';

  @override
  String get showAuthorsInfo =>
      '켜면 글마다 쓴 관리자의 사진과 이름이 보여서 그룹처럼 보여요. 관리자는 입력칸 왼쪽 사진을 눌러 채널 이름으로 올릴 수도 있어요.';

  @override
  String get subscriberDm => '구독자 메시지 받기';

  @override
  String get subscriberDmInfo =>
      '켜면 구독자가 💬 버튼으로 관리자에게 따로 메시지를 보낼 수 있어요. 대화는 끝까지 암호화돼요.';

  @override
  String get dmInboxTag => '메시지';

  @override
  String dmInboxSub(String channel) {
    return '$channel · 구독자 메시지';
  }

  @override
  String get dmEmptyTitle => '관리자에게 메시지 보내기';

  @override
  String dmEmptyBody(String channel) {
    return '$channel 관리자에게만 보여요. 끝까지 암호화돼요.';
  }

  @override
  String get dmButtonHint => '채널 관리자에게 메시지 보내기';

  @override
  String get dmToAdmins => '관리자에게 보내는 메시지';

  @override
  String get dmOpenFailed => '지금은 메시지를 보낼 수 없어요';

  @override
  String get allBackgrounds => '배경 모두 보기';

  @override
  String get allBackgroundsInfo =>
      '누르면 내 기본 배경이 바로 바뀌어요. 밤을 누르면 야간 모드일 때 모습을 미리 볼 수 있어요.';

  @override
  String get channelNameColor => '채널 이름 색';

  @override
  String get channelNameColorInfo => '채널 글에 답장할 때 인용 칸이 이 색으로 보여요.';

  @override
  String get dayLook => '낮';

  @override
  String get nightLook => '밤';

  @override
  String get gradInfo => '내가 메시지를 보낼 때마다 색이 조금씩 돌아요. 색과 무늬는 이 휴대폰에만 저장돼요.';

  @override
  String get gradSky => '하늘';

  @override
  String get gradPeach => '복숭아';

  @override
  String get gradMint => '민트';

  @override
  String get gradLilac => '라일락';

  @override
  String get gradSunset => '노을';

  @override
  String get gradNight => '밤하늘';

  @override
  String get gradPickColor => '동그라미를 누르고 색을 골라요';

  @override
  String get gradTapToTurn => '눌러서 움직임 보기';

  @override
  String lookFromLevel(int n) {
    return '레벨 $n부터';
  }

  @override
  String get lookSampleLink => '링크 미리보기';

  @override
  String get lookSampleLinkText => 'burumy.app · 새 소식';

  @override
  String get lookSampleQuote => '오늘 몇 시에 만나요?';

  @override
  String get lookSampleText => '7시 어때요?';

  @override
  String get myThemes => '내 테마';

  @override
  String get myThemesInfo =>
      '누르면 바로 바뀌어요. 꾹 누르면 고치기·링크 복사·삭제를 할 수 있어요. 링크를 대화에 보내면 친구도 같은 테마를 쓸 수 있어요.';

  @override
  String get nightBrightness => '밤 밝기';

  @override
  String get nightBrightnessInfo => '야간 모드일 때 사진·색 배경을 이만큼 어둡게 해요.';

  @override
  String get none => '없음';

  @override
  String get patternStrength => '무늬 강도';

  @override
  String get patternTitle => '무늬';

  @override
  String get personLook => '이름·프로필 꾸미기';

  @override
  String get personLookInfo =>
      '그룹에서는 이름 색과 함께 모두에게 보이고, 1:1 대화 상대에게는 암호화된 쪽지로 전해져요.';

  @override
  String get pickBackground => '배경 고르기';

  @override
  String get profileColor => '프로필 색';

  @override
  String get profileIcons => '프로필 무늬';

  @override
  String get replyIcons => '답장 무늬';

  @override
  String get replyIconsInfo => '다른 사람이 내 메시지에 답장하면 인용 칸에 이 무늬가 흐리게 보여요.';

  @override
  String get roomCoverColor => '표지 색';

  @override
  String get roomLogoIcons => '표지 무늬';

  @override
  String get roomLook => '모양';

  @override
  String get roomLookFailed => '바꾸지 못했어요. 관리자인지 확인해 주세요.';

  @override
  String get roomLookInfo => '모든 멤버에게 보여요. 커뮤니티 레벨이 오를수록 꾸밀 수 있는 것이 늘어나요.';

  @override
  String get roomLookSaved => '모양을 바꿨어요';

  @override
  String get roomStatusEmoji => '상태 이모지';

  @override
  String get roomWallAll => '모두에게 보이는 배경';

  @override
  String get roomWallAllInfo => '멤버가 이 대화방 배경을 따로 고르지 않았다면 이 배경이 보여요.';

  @override
  String get themeAccentInfo =>
      '강조색은 말풍선·버튼·스위치에 쓰여요. 너무 어두운 색은 읽기 쉽게 조금 밝게 바꿔요.';

  @override
  String get themeApplied => '테마를 적용했어요';

  @override
  String get themeApply => '이 테마 적용하기';

  @override
  String get themeCardOpen => '테마 보기';

  @override
  String get themeCopyLink => '링크 복사';

  @override
  String get themeDefaultName => '내 테마';

  @override
  String themeDeletedIn(int n) {
    return '$n초 뒤에 테마를 지워요';
  }

  @override
  String get themeEdit => '테마 고치기';

  @override
  String get themeLinkCopied => '테마 링크를 복사했어요. 대화에 붙여 보내 보세요.';

  @override
  String get themeLinkInfo => '테마는 링크 안에 들어 있어요. 서버에서 받아 오는 것은 없어요.';

  @override
  String get themeMake => '테마 만들기';

  @override
  String get themeMakeInfo => '저장하면 바로 적용돼요. 야간 모드에서는 같은 배경이 조금 어둡게 보여요.';

  @override
  String get themeNameHint => '테마 이름';

  @override
  String get themeNew => '새 테마';

  @override
  String get themePartAccent => '강조색';

  @override
  String get themePartWall => '배경';

  @override
  String get themeSaved => '테마를 저장했어요';

  @override
  String get wallApplyBoth => '나와 상대 모두 적용';

  @override
  String get wallApplyHere => '이 대화에만 적용';

  @override
  String get wallBlur => '흐림';

  @override
  String get wallFromPhotos => '사진에서 고르기';

  @override
  String get wallMakeColors => '색 섞어 만들기';

  @override
  String get wallMine => '내가 만든 배경';

  @override
  String get wallMixed => '내가 섞은 색';

  @override
  String get wallMoreChoices => '사진·색으로 고르기';

  @override
  String get wallMotion => '움직임';

  @override
  String get wallNoteKeep => '그대로 두기';

  @override
  String wallNoteMine(String name) {
    return '나와 $name님 화면에 새 배경을 설정했어요';
  }

  @override
  String wallNoteTheirs(String name) {
    return '$name님이 두 사람 화면에 새 배경을 설정했어요';
  }

  @override
  String get wallNoteUndo => '내 배경으로 되돌리기';

  @override
  String get wallPhotoMineOnly => '사진 배경은 내 휴대폰에만 보여요';

  @override
  String get wallPreview => '배경 미리보기';

  @override
  String get wallPreviewReply => '옆으로 넘기면 다른 배경을 볼 수 있어요';

  @override
  String get wallReady => '부루미 배경';

  @override
  String get wallSet => '배경으로 설정';

  @override
  String get wallSolid => '단색';

  @override
  String get wallSolidColor => '단색';

  @override
  String get anonAdminLabel => '익명 관리자';

  @override
  String get anonAdmin => '익명으로 남기';

  @override
  String get anonAdminInfo =>
      '켜면 이 관리자가 쓴 글은 그룹 이름과 사진으로 보이고, 멤버 목록에서도 보이지 않아요. 켜기 전에 쓴 글은 그대로예요. 앱 화면에서만 숨겨지고, 서버 기록에는 보낸 계정이 남아요.';

  @override
  String get anonSelfInfo =>
      '켜면 내가 쓴 글이 그룹 이름과 사진으로 보이고, 멤버 목록에서 나를 숨겨요. 켜기 전에 쓴 글은 그대로예요. 앱 화면에서만 숨겨지고, 서버 기록에는 보낸 계정이 남아요.';

  @override
  String get anonShort => '익명';

  @override
  String get myTag => '내 태그';

  @override
  String get myTagAdd => '내 태그 달기';

  @override
  String get myTagInfo => '이 그룹에서 내 이름 옆에 보여요 (최대 16자). 비우면 태그가 사라져요.';

  @override
  String get ownTags => '스스로 태그 달기';

  @override
  String get ownTagsInfo =>
      '켜면 멤버가 그룹 정보에서 자기 이름 옆 태그를 직접 달 수 있어요. 관리자가 달아 준 태그가 있으면 그게 먼저 보여요. 관리자 태그는 초록색, 멤버 태그는 회색이에요.';

  @override
  String get antiSpam => '강력 스팸 차단';

  @override
  String get antiSpamIntro =>
      '광고·도박·대출 같은 스팸을 관리자 폰이 알아서 지워요. 대화 내용은 서버가 읽을 수 없어서, 글을 지울 수 있는 관리자 폰에서 확인해요.';

  @override
  String get antiSpamInfo =>
      '200명이 넘는 큰 그룹에 특히 좋아요. 관리자 글과 \'스팸 아님\'으로 둔 사람 글은 지우지 않아요. 지워진 글은 모두의 화면에서 가루처럼 흩어져 사라져요.';

  @override
  String get antiSpamChecks => '이런 글을 걸러요';

  @override
  String get antiSpamCheckWords => '도박·대출·리딩방 같은 스팸 단어';

  @override
  String get antiSpamCheckLinks => '새로 온 멤버의 링크와 연락처 (텔레그램 아이디, 오픈채팅, 전화번호)';

  @override
  String get antiSpamCheckRepeat => '같은 글을 여러 번 올리기';

  @override
  String get antiSpamCheckMentions => '한 번에 여러 사람 부르기 (@ 6개 이상)';

  @override
  String get antiSpamCheckStrikes => '하루에 3번 걸리면 하루 동안 글쓰기 금지';

  @override
  String get antiSpamRemoved => '스팸 차단이 지운 글';

  @override
  String get antiSpamRemovedInfo =>
      '이 폰이 지운 글이에요. 잘못 지웠으면 \'스팸 아님\'을 눌러요. 그 사람 글은 다시 거르지 않고, 스팸 때문에 걸린 글쓰기 금지도 풀려요.';

  @override
  String get antiSpamNone => '아직 지운 글이 없어요';

  @override
  String get spamOk => '스팸 아님';

  @override
  String get spamOkMark => '스팸 아님 처리됨';

  @override
  String spamOkDone(String name) {
    return '$name님 글은 이제 거르지 않아요';
  }

  @override
  String logSpam(String name) {
    return '스팸 차단이 $name님 글을 지웠어요';
  }

  @override
  String logSpamOk(String name) {
    return '$name님을 스팸 아님으로 두었어요';
  }

  @override
  String groupReadCount(int n) {
    return '$n명 읽음';
  }

  @override
  String groupReadTitle(int n) {
    return '$n명 읽음';
  }

  @override
  String groupReadNotYet(int n) {
    return '$n명은 아직 안 읽었어요.';
  }

  @override
  String get groupReadInfo => '100명 이하 그룹에서만 보여요. 읽은 시간은 7일 동안 남아요.';

  @override
  String groupReadToday(String time) {
    return '오늘 $time';
  }

  @override
  String groupReadYesterday(String time) {
    return '어제 $time';
  }

  @override
  String get draftFromOther => '다른 기기에서 쓰던 글을 이어서 쓸 수 있어요';

  @override
  String toneGoing(String name, int n) {
    return '\'$name\' 소리를 지워요 · $n초';
  }

  @override
  String soundChatDefault(String name) {
    return '기본 ($name)';
  }

  @override
  String get toneMine => '내 소리';

  @override
  String get toneMineEmpty =>
      '대화에서 5초 이하의 음성 메시지를 길게 누르고 \'알림음으로 저장\'을 누르면 여기에 생겨요.';

  @override
  String get toneMineInfo =>
      '소리는 이 기기 안에 암호화해서 보관해요. 앱을 쓰는 동안 이 소리가 나고, 잠긴 화면 알림은 지금은 기본 소리로 울려요.';

  @override
  String toneSeconds(int n) {
    return '$n초';
  }

  @override
  String get toneNone => '아직 저장한 소리가 없어요';

  @override
  String get toneOurs => '부루미 소리';

  @override
  String get saveAsTone => '알림음으로 저장';

  @override
  String get toneTooLong => '5초·300KB 이하의 소리만 알림음으로 저장할 수 있어요';

  @override
  String toneFull(int n) {
    return '알림음은 $n개까지 저장할 수 있어요';
  }

  @override
  String toneDefaultName(String who, int n) {
    return '$who의 소리 $n';
  }

  @override
  String get toneSaved => '알림음에 추가했어요. 대화의 알림 메뉴에서 고를 수 있어요';

  @override
  String get toneForChat => '알림음 바꾸기';

  @override
  String get storageTitle => '저장 공간';

  @override
  String get storageOther => '기타 임시 파일';

  @override
  String get storageNoLimit => '제한 없음';

  @override
  String storageClearing(String size, int n) {
    return '$size 비우는 중 · $n초';
  }

  @override
  String storageFreed(String size) {
    return '$size 비웠어요';
  }

  @override
  String get storageFreedInfo => '대화는 그대로예요. 필요하면 누르는 순간 다시 받아요.';

  @override
  String get storageNothing => '비울 게 없어요';

  @override
  String get storageOnDevice => '이 기기에서 쓰는 공간';

  @override
  String storageOfTotal(String size) {
    return '전체 $size 중';
  }

  @override
  String get storageKeepsChats =>
      '걱정 마세요. 비워도 대화와 메시지는 그대로 남고, 사진·동영상·파일은 누르면 서버에서 다시 받아요.';

  @override
  String storagePercent(int n) {
    return '$n%';
  }

  @override
  String storageClearButton(String size) {
    return '선택한 것 비우기 · $size';
  }

  @override
  String get storagePickKind => '비울 종류를 골라 주세요';

  @override
  String get keepExceptions => '예외로 둔 대화';

  @override
  String get keepExceptionInfo =>
      '이 대화만 따로 정한 기간이 지나면 받아 둔 파일을 지워요. \'안 지워요\'로 두면 이 대화 파일은 자동으로 지우지 않아요.';

  @override
  String get storageMaxTitle => '최대 저장 용량';

  @override
  String get storageMaxInfo =>
      '받아 둔 파일이 이 크기를 넘으면 가장 오래 안 연 것부터 지워요. 휴대폰과 PC 앱은 각자 이 기기 안에서 지켜요.';

  @override
  String get storageAllChats => '모든 대화 보기';

  @override
  String get storageBig => '큰 파일';

  @override
  String get storageTabMedia => '사진·동영상';

  @override
  String get dataUsageTitle => '데이터 사용량';

  @override
  String get storageThisChat => '이 대화';

  @override
  String get usageMessages => '메시지';

  @override
  String get usageCalls => '통화';

  @override
  String usageResetting(int n) {
    return '통계를 지워요 · $n초';
  }

  @override
  String get usageAll => '전체';

  @override
  String get usageCell => '모바일 데이터';

  @override
  String get usageWifi => 'Wi-Fi';

  @override
  String get usageUsed => '사용한 데이터';

  @override
  String get usageInfo =>
      '이 기기에서만 세요. 사진·동영상·파일·음성은 실제 크기, 메시지는 글자 크기, 통화는 통화 시간으로 어림한 값이에요.';

  @override
  String usageAbout(String size) {
    return '약 $size';
  }

  @override
  String get usageSent => '보냄';

  @override
  String get usageRecv => '받음';

  @override
  String usageSentN(int n) {
    return '보냄 · $n개';
  }

  @override
  String usageRecvN(int n) {
    return '받음 · $n개';
  }

  @override
  String usageSince(String date) {
    return '$date부터 센 값이에요';
  }

  @override
  String get usageReset => '통계 초기화';

  @override
  String get draftSync => '임시 글 내 기기끼리 이어쓰기';

  @override
  String get draftSyncSub =>
      '쓰다 만 글을 내 다른 기기(PC 등)에서 이어 써요. 암호화해서 내 기기끼리만 주고받아요.';

  @override
  String get archiveSettings => '보관함 설정';

  @override
  String get archiveHow => '보관함은 이렇게 써요';

  @override
  String get archiveIntroTitle => '이게 보관함이에요';

  @override
  String get archiveIntro1Title => '목록을 깔끔하게';

  @override
  String get archiveIntro1 => '자주 안 보는 대화를 옮겨 두면 대화 목록이 가벼워져요. 대화는 그대로 남아요.';

  @override
  String get archiveIntro2Title => '알림 끈 대화는 계속 여기에';

  @override
  String get archiveIntro2 =>
      '알림을 끈 대화는 새 메시지가 와도 보관함에 있어요. 알림 켠 대화는 새 메시지가 오면 목록으로 돌아와요. 보관함 설정에서 바꿀 수 있어요.';

  @override
  String get archiveIntro3Title => '밀어서 넣고 빼기';

  @override
  String get archiveIntro3 => '대화를 왼쪽으로 밀어 보관하고, 보관함 안에서 다시 밀면 꺼내요.';

  @override
  String get archiveSettingsInfo => '보관한 대화가 언제 목록으로 돌아올지 정해요. 이 휴대폰에만 저장돼요.';

  @override
  String get archiveUnmutedHeader => '알림 켠 대화';

  @override
  String get archiveKeepUnmuted => '새 메시지가 와도 계속 보관';

  @override
  String get archiveUnmutedInfo =>
      '끄면 알림 켠 대화는 누가 새 메시지를 보낼 때 목록으로 돌아와요. 알림 끈 대화는 언제나 보관함에 남아요.';

  @override
  String get archiveFolderHeader => '폴더에 넣은 대화';

  @override
  String get archiveKeepFolder => '새 메시지가 와도 계속 보관';

  @override
  String get archiveFolderInfo =>
      '폴더에 직접 넣은 대화는 폴더 탭에서 볼 수 있으니 보관함에 계속 둘 수 있어요.';

  @override
  String get archiveStrangerHeader => '모르는 사람';

  @override
  String get folderShare => '폴더 공유하기';

  @override
  String get folderShareRowInfo => '링크 하나로 이 폴더의 그룹·채널을 친구에게 한 번에 보내요.';

  @override
  String folderShareTitle(String name) {
    return '\'$name\' 폴더 공유';
  }

  @override
  String get folderShareInfo => '링크를 연 사람은 폴더를 추가하고, 고른 대화에 한 번에 들어와요.';

  @override
  String get folderShareChats => '링크에 넣을 대화';

  @override
  String get folderShareChatsInfo =>
      '1:1 대화와 초대 링크가 없는 대화는 빠져요. 들어올 때는 대화마다 정한 규칙(승인, 가입 질문)을 그대로 지켜요.';

  @override
  String get folderShareNone => '이 폴더에는 공유할 그룹이나 채널이 없어요';

  @override
  String get folderShareNoLink => '초대 링크 없음';

  @override
  String folderJoinTitle(String name) {
    return '\'$name\' 폴더 추가';
  }

  @override
  String get folderJoinInfo => '고른 대화에 들어가고, 대화 목록 위에 이 폴더 탭이 생겨요.';

  @override
  String folderJoinChats(int n) {
    return '대화 $n개';
  }

  @override
  String get folderJoinIn => '이미 들어가 있어요';

  @override
  String folderJoinGo(int n) {
    return '폴더 추가하고 $n개 들어가기';
  }

  @override
  String folderJoined(String name, int n) {
    return '\'$name\' 폴더를 추가했어요 · 대화 $n개';
  }

  @override
  String get folderJoinNone => '들어간 대화가 없어 폴더를 만들지 않았어요';

  @override
  String folderJoinAsked(int n) {
    return '$n개는 승인을 기다려요.';
  }

  @override
  String folderJoinFailed(int n) {
    return '$n개는 들어가지 못했어요.';
  }

  @override
  String get accountPreviewEmpty => '아직 대화가 없어요';

  @override
  String get accountPreviewSwitch => '이 계정으로 바꾸기';

  @override
  String onceGoesHours(int n) {
    return '안 열면 $n시간 뒤 사라져요';
  }

  @override
  String onceGoesMinutes(int n) {
    return '안 열면 $n분 뒤 사라져요';
  }

  @override
  String onceOpenWithinHours(int n) {
    return '눌러서 열기 · $n시간 남음';
  }

  @override
  String onceOpenWithinMinutes(int n) {
    return '눌러서 열기 · $n분 남음';
  }

  @override
  String zipCount(int n) {
    return '파일 $n개';
  }

  @override
  String zipUnpacked(String size) {
    return '풀면 $size';
  }

  @override
  String zipFirstOnly(int n) {
    return '앞의 $n개만 보여요';
  }

  @override
  String get zipInfo =>
      '압축을 풀지 않고 보여 줘요. 누른 파일만 이 폰 메모리에서 열고, 저장하거나 서버로 보내지 않아요.';

  @override
  String get zipPassword => '암호가 걸린 압축 파일이라 안을 볼 수 없어요';

  @override
  String get zipEmpty => '빈 압축 파일이에요';

  @override
  String get zipTooBig => '풀면 50MB가 넘어서 여기서는 못 열어요';

  @override
  String get zipCantOpen => '이 파일은 열 수 없어요';

  @override
  String get storyGroupOnly => '그룹에만';

  @override
  String get storyGroupOnlySub => '고른 그룹의 멤버만 봐요';

  @override
  String get storyGroupOnlyInfo =>
      '그 그룹 멤버라면 친구가 아니어도 볼 수 있어요. 다른 그룹과 친구에게는 가지 않아요.';

  @override
  String storyGroupOnlyLabel(String name) {
    return '$name에만';
  }

  @override
  String storyGroupOnlyShared(String name) {
    return '$name 멤버에게만 올렸어요';
  }

  @override
  String get textStickerTitle => '글자 스티커';

  @override
  String get textStickerSave => '보내기';

  @override
  String get textStickerHint => '아래에 쓴 글자가 여기에 스티커로 보여요';

  @override
  String get textStickerPlain => '글자만';

  @override
  String get textStickerBubble => '말풍선';

  @override
  String get textStickerBadge => '동그라미';

  @override
  String get textStickerTag => '이름표';

  @override
  String get textStickerPlaceholder => '짧은 말을 써 보세요';

  @override
  String get textStickerTile => '글자';

  @override
  String get pdfMarkAdd => '형광펜';

  @override
  String get pdfMarkDone => '형광펜으로 표시했어요';

  @override
  String pdfMarks(int count) {
    return '형광펜 표시 $count개';
  }

  @override
  String get pdfMarksTitle => '형광펜 표시';

  @override
  String get pdfMarksInfo => '표시는 이 휴대폰에만 남아요. 대화에 보내기 전에는 아무도 못 봐요.';

  @override
  String pdfMarkPage(int page) {
    return '$page쪽';
  }

  @override
  String get pdfMarksSend => '대화에 보내기';

  @override
  String get pdfMarksSent => '대화에 보냈어요';

  @override
  String pdfMarksQuote(String name) {
    return '$name에서 표시한 부분';
  }

  @override
  String pdfMarkGoing(int seconds) {
    return '표시를 지워요 ($seconds)';
  }

  @override
  String get pdfMarksHow => '글자를 꾹 눌러 고른 다음 \'형광펜\'을 누르면 표시돼요.';

  @override
  String get appIconMarks => '부루미 마크';

  @override
  String get appIconCharacters => '캐릭터';

  @override
  String get appIconLogos => '다른 로고';

  @override
  String appIconLogo(String letter) {
    return '로고 $letter';
  }

  @override
  String get linkSummaryButton => '3줄 요약';

  @override
  String get linkSummaryBusy => '요약하는 중…';

  @override
  String get linkSummaryTitle => '3줄 요약 · 나만 보여요';

  @override
  String get linkSummaryFailed => '글을 가져오지 못했어요. 읽기 모드로 열어 보세요.';

  @override
  String get linkSummaryHide => '요약 접기';

  @override
  String shotLine(String name, String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'photo': '한 번 보기 사진을',
      'video': '한 번 보기 영상을',
      'voice': '한 번 듣기 음성을',
      'round': '한 번 보기 동그란 영상을',
      'file': '보호된 파일을',
      'bubble': '비눗방울을',
      'other': '대화 화면을',
    });
    return '$name님이 $_temp0 캡처했어요';
  }

  @override
  String shotLineMine(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'photo': '한 번 보기 사진을',
      'video': '한 번 보기 영상을',
      'voice': '한 번 듣기 음성을',
      'round': '한 번 보기 동그란 영상을',
      'file': '보호된 파일을',
      'bubble': '비눗방울을',
      'other': '대화 화면을',
    });
    return '내가 $_temp0 캡처했어요 · 대화방에 알렸어요';
  }

  @override
  String shotPreview(String name) {
    return '📸 $name님이 캡처했어요';
  }

  @override
  String get shotPreviewMine => '📸 캡처했다고 알렸어요';

  @override
  String get shotInfoTitle => '캡처 알림';

  @override
  String get shotInfoBody =>
      '부루미는 한 번 보기 사진·영상, 보호된 파일, 공유를 막은 대화를 캡처하지 못하게 막아요. 안드로이드는 캡처하면 검은 화면만 남아요. 아이폰은 앱이 캡처를 막을 수 없어서, 대신 캡처한 사실을 대화방에 알려요. 알림은 끝까지 암호화되어 서버는 몰라요.';

  @override
  String get bestFriendSwitch => '제일 친한 친구 표시';

  @override
  String get bestFriendInfo =>
      '최근 2주 동안 서로 가장 많이 대화한 친구 이름 옆에 ❤가 붙어요. 내 폰이 직접 세고 나만 봐요. 서버도, 그 친구도 몰라요.';

  @override
  String get bestFriendTip => '제일 친한 친구예요';

  @override
  String get bestFriendTipBody => '최근 2주 동안 서로 가장 많이 대화했어요. 이 ❤는 나만 보여요.';

  @override
  String memoriesTitle(int years) {
    return '$years년 전 오늘';
  }

  @override
  String memoriesPreview(int years, int count) {
    return '📷 $years년 전 오늘 저장한 사진 $count개가 있어요';
  }

  @override
  String get memoriesOpen => '보기';

  @override
  String get memoriesSwitch => '1년 전 오늘 보기';

  @override
  String get memoriesInfo =>
      '저장한 메시지에 올려 둔 사진·영상 중 몇 년 전 오늘 저장한 것을 폰이 골라 저장한 메시지 줄에 알려 줘요. 새로 올리거나 서버에 보관하는 건 없어요.';

  @override
  String get memoriesSend => '대화로 보내기';

  @override
  String get memoriesGoTo => '저장한 메시지에서 보기';

  @override
  String get memoriesOnPhone => '내 폰이 고른 추억이에요 · 서버에는 없어요';

  @override
  String get feedComment => '댓글';

  @override
  String get feedCommentHint => '댓글 달기…';

  @override
  String get feedCommentsKnown => '아는 친구 댓글만 보여요';

  @override
  String get feedCommentsMine => '내 글이라 댓글이 모두 보여요';

  @override
  String feedCommentsMore(int n) {
    return '댓글 $n개 모두 보기';
  }

  @override
  String get feedCommentDelete => '댓글 삭제';

  @override
  String get feedCommentsTitle => '댓글';

  @override
  String get feedCommentsInfo =>
      '댓글은 글쓴이에게만 암호화되어 가고, 글쓴이 폰이 친구들에게 다시 나눠 줘요. 친구 폰은 그 친구가 아는 사람의 댓글만 보여 줘요. 서버는 누가 누구와 친구인지 몰라요. 다른 댓글은 지워지지 않고 내 폰에서만 가려져요.';

  @override
  String memoriesCount(int count) {
    return '$count개';
  }

  @override
  String get accountSuspended =>
      '계정이 잠시 정지됐어요. 고친 앱이나 프로그램으로 규칙을 어기려는 시도가 여러 번 있었어요. 정지 기간이 끝나면 다시 쓸 수 있고, 그동안은 대화방 나가기만 돼요. 잘못된 정지라면 이의 신청을 보내 주세요.';

  @override
  String get accountWarned =>
      '이 앱이 바뀐 것 같아요. 같은 시도를 계속하면 계정이 정지돼요. 공식 부루미 앱을 써 주세요.';

  @override
  String get pullCameraSwitch => '아래로 당겨 카메라 열기';

  @override
  String get pullCameraInfo =>
      '대화 목록 맨 위에서 아래로 길게 당기면 카메라가 바로 열려요. 짧게 당기면 지금처럼 보관함이 나와요.';

  @override
  String get pullCameraMore => '더 당기면 카메라';

  @override
  String get pullCameraLetGo => '놓으면 카메라가 열려요';

  @override
  String get aiFriendName => 'AI 친구';

  @override
  String get aiFriendPreview => '폰 안의 AI와 이야기해요';

  @override
  String get aiFriendLock => '이 폰 안에서만 대화해요 · 서버로 가지 않아요';

  @override
  String get aiFriendHint => 'AI 친구에게 메시지';

  @override
  String get aiFriendHello =>
      '안녕하세요! 저는 부루미 AI 친구예요. 궁금한 걸 묻거나, 보낼 말을 같이 고민해 봐요. 우리 대화는 이 폰 밖으로 나가지 않아요.';

  @override
  String get aiFriendIdea1 => '오늘 저녁 메뉴 추천해 줘';

  @override
  String get aiFriendIdea2 => '친구 생일 축하 문구 써 줘';

  @override
  String get aiFriendIdea3 => '주말에 뭐 하면 좋을까?';

  @override
  String get aiFriendIdea4 => '이 말 영어로 바꿔 줘: 오늘 고마웠어';

  @override
  String get aiFriendThinking => '생각하는 중…';

  @override
  String get aiFriendFailed => '지금은 답하지 못했어요. 잠시 후 다시 보내 주세요.';

  @override
  String get aiFriendNoAi =>
      '이 폰에는 AI가 없어서 AI 친구를 쓸 수 없어요. 아이폰은 Apple Intelligence, 안드로이드는 Gemini Nano가 있는 폰에서 돼요.';

  @override
  String get aiFriendClear => '대화 지우기';

  @override
  String get aiFriendCleared => 'AI 친구와의 대화를 지웠어요';

  @override
  String get aiFriendHide => '대화 목록에서 빼기';

  @override
  String get aiFriendHidden => 'AI 친구를 목록에서 뺐어요 · 설정 > 대화에서 다시 켤 수 있어요';

  @override
  String get aiFriendSwitch => '대화 목록에 AI 친구 보이기';

  @override
  String get aiFriendSwitchSub => '폰 안의 AI만 써요';

  @override
  String get aiFriendWrong => 'AI의 답은 틀릴 수 있어요';

  @override
  String get aiFriendCopy => '복사';

  @override
  String get aiFriendCopied => '복사했어요';

  @override
  String get aiFriendShare => '대화로 보내기';

  @override
  String aiFriendAsk(String words) {
    return 'AI 친구에게 묻기: $words';
  }

  @override
  String get shopTitle => '스티커 가게';

  @override
  String get shopFree => '무료 스티커';

  @override
  String get shopFreeInfo => '부루미가 직접 그린 스티커예요. 추가하면 스티커 창에 바로 생겨요.';

  @override
  String get shopPaid => '유료 스티커';

  @override
  String get shopSoon => '곧 열려요';

  @override
  String get shopPaidInfo =>
      '작가 스티커와 특별 팩은 결제가 열리면 여기서 살 수 있어요. 브랜드 광고 스티커는 팔지 않아요. 부루미는 광고를 넣지 않아요.';

  @override
  String get shopFreeTag => '무료';

  @override
  String shopMovingN(int n) {
    return '움직이는 스티커 $n개';
  }

  @override
  String get shopBy => '부루미';

  @override
  String get shopAdd => '추가하기';

  @override
  String get shopAdded => '추가됨';

  @override
  String get shopRemove => '빼기';

  @override
  String get shopPrivacy => '어떤 스티커를 받는지 서버에 알리지 않아요. 인기 순위도 폰에서 정해요.';

  @override
  String get shopNew => '새로 나왔어요';

  @override
  String get shopOpen => '스티커 가게';

  @override
  String get searchFeatures => '기능 · 설정';

  @override
  String get searchChannelPosts => '구독 채널 글';

  @override
  String get searchStickers => '스티커';

  @override
  String get searchAllPosts => '글 모두 보기';

  @override
  String shopPackInfo(int count, int moving) {
    return '$count개 · $moving개는 움직여요';
  }

  @override
  String get shopSeenTitle => '대화에서 본 묶음';

  @override
  String get aiFriendMore => '더 보기';

  @override
  String get searchFeatAiFriend => 'AI 친구';

  @override
  String get searchFeatMemories => '1년 전 오늘';

  @override
  String get searchFeatBestFriend => '제일 친한 친구 표시';

  @override
  String get searchFeatLock => '앱 잠금 · 비밀번호';

  @override
  String get searchFeatPullCamera => '아래로 당겨 카메라 열기';

  @override
  String get dmInboxAll => '전체';

  @override
  String get dmInboxAllInfo => '이 채널로 온 메시지를 모두 모아 봐요. 누르면 그 사람과의 대화로 가요.';

  @override
  String get accountSuspendedEdit =>
      '다른 사람의 메시지를 고치려는 시도가 있어서 계정이 정지됐어요. 부루미 앱에서는 할 수 없는 일이라, 고친 앱이나 프로그램을 쓴 것으로 보여요. 잘못된 정지라면 이의 신청을 보내 주세요.';

  @override
  String get appealButton => '이의 신청';

  @override
  String get appealHint => '무슨 일이 있었는지 적어 주세요';

  @override
  String get appealInfo =>
      '운영팀만 읽어요. 대화 내용은 운영팀에게도 보이지 않아요. 한 번에 하나만 보낼 수 있어요.';

  @override
  String get appealSent => '이의 신청을 보냈어요. 운영팀이 읽고 정지를 풀지 정해요.';

  @override
  String get appealWaiting => '이의 신청을 기다리는 중이에요. 운영팀이 정지를 풀면 바로 다시 쓸 수 있어요.';

  @override
  String appealDenied(String date) {
    return '운영팀이 정지를 그대로 두기로 했어요. $date부터 다시 신청할 수 있어요.';
  }

  @override
  String suspendUntil(String date) {
    return '$date까지 정지';
  }

  @override
  String get suspendUntilLifted => '운영팀이 풀 때까지 정지';

  @override
  String get suspendReasonEdit => '다른 사람의 메시지를 고치려는 시도';

  @override
  String get suspendReasonApp => '고친 앱이나 프로그램으로 규칙을 어기려는 시도 여러 번';

  @override
  String get notSuspended => '지금은 정지되어 있지 않아요.';
}
