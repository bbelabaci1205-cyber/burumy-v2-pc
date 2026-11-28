import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L of(BuildContext context) {
    return Localizations.of<L>(context, L)!;
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get appName;

  /// No description provided for @tabChats.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get tabChats;

  /// No description provided for @tabContacts.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get tabContacts;

  /// No description provided for @tabSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get tabSettings;

  /// No description provided for @signUpTitle.
  ///
  /// In ko, this message translates to:
  /// **'아이디로 시작해요'**
  String get signUpTitle;

  /// No description provided for @signUpId.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get signUpId;

  /// No description provided for @signUpPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get signUpPassword;

  /// No description provided for @signUpInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get signUpInvite;

  /// No description provided for @signUpButton.
  ///
  /// In ko, this message translates to:
  /// **'가입하기'**
  String get signUpButton;

  /// No description provided for @logInButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get logInButton;

  /// No description provided for @recoveryKeyTitle.
  ///
  /// In ko, this message translates to:
  /// **'대화 복구 키'**
  String get recoveryKeyTitle;

  /// No description provided for @recoveryKeyBody.
  ///
  /// In ko, this message translates to:
  /// **'새 휴대폰에서 예전 대화를 열 때 필요해요. 안전한 곳에 적어 두세요.'**
  String get recoveryKeyBody;

  /// No description provided for @chatsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없어요'**
  String get chatsEmpty;

  /// No description provided for @messageLocked.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지는 아직 열 수 없어요'**
  String get messageLocked;

  /// No description provided for @sendFailedNoEncryption.
  ///
  /// In ko, this message translates to:
  /// **'암호화되지 않은 대화에는 보낼 수 없어요'**
  String get sendFailedNoEncryption;

  /// No description provided for @themeGreen.
  ///
  /// In ko, this message translates to:
  /// **'그린'**
  String get themeGreen;

  /// No description provided for @themeBlue.
  ///
  /// In ko, this message translates to:
  /// **'블루'**
  String get themeBlue;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get language;

  /// No description provided for @signUpSub.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호만 있으면 돼요. 전화번호는 필요 없어요.'**
  String get signUpSub;

  /// No description provided for @haveAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있어요'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In ko, this message translates to:
  /// **'새로 가입할게요'**
  String get noAccount;

  /// No description provided for @logInTitle.
  ///
  /// In ko, this message translates to:
  /// **'다시 오셨네요'**
  String get logInTitle;

  /// No description provided for @fieldRequired.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호를 넣어 주세요'**
  String get fieldRequired;

  /// No description provided for @passwordRule.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 8자 이상, 글자와 숫자를 섞어 주세요'**
  String get passwordRule;

  /// No description provided for @somethingWrong.
  ///
  /// In ko, this message translates to:
  /// **'잠시 후 다시 해 볼까요?'**
  String get somethingWrong;

  /// No description provided for @newChat.
  ///
  /// In ko, this message translates to:
  /// **'새 대화'**
  String get newChat;

  /// No description provided for @newChatHint.
  ///
  /// In ko, this message translates to:
  /// **'상대 아이디'**
  String get newChatHint;

  /// No description provided for @start.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get start;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @messageHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get messageHint;

  /// No description provided for @encryptedNotice.
  ///
  /// In ko, this message translates to:
  /// **'이 대화는 종단간 암호화돼요. 부루미도 내용을 볼 수 없어요.'**
  String get encryptedNotice;

  /// No description provided for @photo.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get video;

  /// No description provided for @voice.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get voice;

  /// No description provided for @file.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get file;

  /// No description provided for @you.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get you;

  /// No description provided for @today.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get yesterday;

  /// No description provided for @settingsLook.
  ///
  /// In ko, this message translates to:
  /// **'화면'**
  String get settingsLook;

  /// No description provided for @settingsColor.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get settingsColor;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @languageAuto.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정 따르기'**
  String get languageAuto;

  /// No description provided for @languageKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageEn.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @settingsSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get settingsSecurity;

  /// No description provided for @makeRecoveryKey.
  ///
  /// In ko, this message translates to:
  /// **'대화 복구 키 만들기'**
  String get makeRecoveryKey;

  /// No description provided for @copied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get copied;

  /// No description provided for @copyCodeButton.
  ///
  /// In ko, this message translates to:
  /// **'코드 복사 · {code}'**
  String copyCodeButton(String code);

  /// No description provided for @codeCopied.
  ///
  /// In ko, this message translates to:
  /// **'코드를 복사했어요. 1분 뒤 지워져요.'**
  String get codeCopied;

  /// No description provided for @codeCopyFailed.
  ///
  /// In ko, this message translates to:
  /// **'복사하지 못했어요. 코드: {code}'**
  String codeCopyFailed(String code);

  /// No description provided for @logOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logOut;

  /// No description provided for @myId.
  ///
  /// In ko, this message translates to:
  /// **'내 아이디'**
  String get myId;

  /// No description provided for @contactsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 연락처가 없어요'**
  String get contactsEmpty;

  /// No description provided for @done.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get done;

  /// No description provided for @searchById.
  ///
  /// In ko, this message translates to:
  /// **'아이디로 찾기'**
  String get searchById;

  /// No description provided for @contactsSection.
  ///
  /// In ko, this message translates to:
  /// **'내 연락처'**
  String get contactsSection;

  /// No description provided for @searchResults.
  ///
  /// In ko, this message translates to:
  /// **'찾은 사람'**
  String get searchResults;

  /// No description provided for @noOneFound.
  ///
  /// In ko, this message translates to:
  /// **'찾는 사람이 없어요'**
  String get noOneFound;

  /// No description provided for @attachPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 또는 동영상'**
  String get attachPhoto;

  /// No description provided for @attachFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get attachFile;

  /// No description provided for @sending.
  ///
  /// In ko, this message translates to:
  /// **'보내는 중'**
  String get sending;

  /// No description provided for @read.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get read;

  /// No description provided for @enterRecoveryKey.
  ///
  /// In ko, this message translates to:
  /// **'대화 복구 키 넣기'**
  String get enterRecoveryKey;

  /// No description provided for @enterRecoveryKeyBody.
  ///
  /// In ko, this message translates to:
  /// **'예전 휴대폰에서 만든 대화 복구 키를 넣으면 예전 대화를 열 수 있어요.'**
  String get enterRecoveryKeyBody;

  /// No description provided for @recoveryKeyHint.
  ///
  /// In ko, this message translates to:
  /// **'단어 12개'**
  String get recoveryKeyHint;

  /// No description provided for @recoveryDone.
  ///
  /// In ko, this message translates to:
  /// **'예전 대화를 열었어요'**
  String get recoveryDone;

  /// No description provided for @recoveryWrong.
  ///
  /// In ko, this message translates to:
  /// **'키가 맞지 않아요. 다시 확인해 주세요.'**
  String get recoveryWrong;

  /// No description provided for @recoveryOn.
  ///
  /// In ko, this message translates to:
  /// **'켜져 있어요'**
  String get recoveryOn;

  /// No description provided for @open.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get open;

  /// No description provided for @newGroup.
  ///
  /// In ko, this message translates to:
  /// **'새 그룹'**
  String get newGroup;

  /// No description provided for @newChannel.
  ///
  /// In ko, this message translates to:
  /// **'새 채널'**
  String get newChannel;

  /// No description provided for @addMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 추가'**
  String get addMembers;

  /// No description provided for @next.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get next;

  /// No description provided for @groupName.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이름'**
  String get groupName;

  /// No description provided for @channelName.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름'**
  String get channelName;

  /// No description provided for @create.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get create;

  /// No description provided for @channelInfo.
  ///
  /// In ko, this message translates to:
  /// **'채널에서는 나만 글을 쓸 수 있어요. 구독자는 읽기만 해요.'**
  String get channelInfo;

  /// No description provided for @groupInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹 대화도 종단간 암호화돼요.'**
  String get groupInfo;

  /// No description provided for @channelReadOnly.
  ///
  /// In ko, this message translates to:
  /// **'채널 주인만 글을 쓸 수 있어요'**
  String get channelReadOnly;

  /// No description provided for @reply.
  ///
  /// In ko, this message translates to:
  /// **'답장'**
  String get reply;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get copy;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @editing.
  ///
  /// In ko, this message translates to:
  /// **'메시지 수정'**
  String get editing;

  /// No description provided for @edited.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get edited;

  /// No description provided for @typing.
  ///
  /// In ko, this message translates to:
  /// **'입력 중…'**
  String get typing;

  /// No description provided for @deleted.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 지웠어요'**
  String get deleted;

  /// No description provided for @undo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get undo;

  /// No description provided for @channel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get channel;

  /// No description provided for @group.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get group;

  /// No description provided for @orById.
  ///
  /// In ko, this message translates to:
  /// **'또는 아이디로 1:1 대화 시작'**
  String get orById;

  /// No description provided for @lockTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 넣어 주세요'**
  String get lockTitle;

  /// No description provided for @lockWrong.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 맞지 않아요'**
  String get lockWrong;

  /// No description provided for @appLock.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금'**
  String get appLock;

  /// No description provided for @appLockOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼져 있어요'**
  String get appLockOff;

  /// No description provided for @appLockOn.
  ///
  /// In ko, this message translates to:
  /// **'켜져 있어요'**
  String get appLockOn;

  /// No description provided for @setPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 정하기'**
  String get setPassword;

  /// No description provided for @newPassword.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'두 비밀번호가 달라요'**
  String get passwordMismatch;

  /// No description provided for @changePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 바꾸기'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In ko, this message translates to:
  /// **'지금 비밀번호'**
  String get currentPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ko, this message translates to:
  /// **'숨김 비밀번호'**
  String get hidePassword;

  /// No description provided for @deletePassword.
  ///
  /// In ko, this message translates to:
  /// **'삭제 비밀번호'**
  String get deletePassword;

  /// No description provided for @hidePasswordInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 비밀번호로 열면 고른 사람과 대화가 모든 목록에서 사라져요. 다음에 보통 비밀번호로 열어도 계속 숨겨져요.'**
  String get hidePasswordInfo;

  /// No description provided for @deletePasswordInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 비밀번호로 열면 고른 사람과 대화가 지워져요. 1:1 대화는 상대 쪽에서도 조용히 지워지고, 그룹·채널은 며칠에 걸쳐 조용히 나가요. 상대에게는 알림이 가지 않아요. 되돌릴 수 없어요.'**
  String get deletePasswordInfo;

  /// No description provided for @hideList.
  ///
  /// In ko, this message translates to:
  /// **'숨길 사람·대화'**
  String get hideList;

  /// No description provided for @deleteList.
  ///
  /// In ko, this message translates to:
  /// **'지울 사람·대화'**
  String get deleteList;

  /// No description provided for @notSet.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get notSet;

  /// No description provided for @removePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 없애기'**
  String get removePassword;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @releaseHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 사람 다시 보이기'**
  String get releaseHidden;

  /// No description provided for @releaseHiddenDone.
  ///
  /// In ko, this message translates to:
  /// **'다시 보여요'**
  String get releaseHiddenDone;

  /// No description provided for @passwordUsed.
  ///
  /// In ko, this message translates to:
  /// **'다른 비밀번호와 같아요'**
  String get passwordUsed;

  /// No description provided for @chooseCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 골랐어요'**
  String chooseCount(int count);

  /// No description provided for @enterToManage.
  ///
  /// In ko, this message translates to:
  /// **'보통 비밀번호를 넣으면 잠금 설정을 바꿀 수 있어요'**
  String get enterToManage;

  /// No description provided for @streaks.
  ///
  /// In ko, this message translates to:
  /// **'스트릭'**
  String get streaks;

  /// No description provided for @streakInfo.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화에서 둘 다 3일 넘게 매일 메시지를 보내면 이름 옆에 불꽃이 생겨요. 그룹은 매일 멤버 절반(2~5명) 이상이 말하면 생겨요. 계산은 휴대폰 안에서만 해요.'**
  String get streakInfo;

  /// No description provided for @sticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get sticker;

  /// No description provided for @stickers.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get stickers;

  /// No description provided for @pin.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In ko, this message translates to:
  /// **'고정 해제'**
  String get unpin;

  /// No description provided for @pinnedMessage.
  ///
  /// In ko, this message translates to:
  /// **'고정된 메시지'**
  String get pinnedMessage;

  /// No description provided for @timer.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 메시지'**
  String get timer;

  /// No description provided for @timerOff.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get timerOff;

  /// No description provided for @timer1d.
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get timer1d;

  /// No description provided for @timer1w.
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get timer1w;

  /// No description provided for @timer1m.
  ///
  /// In ko, this message translates to:
  /// **'1달'**
  String get timer1m;

  /// No description provided for @timerLine.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 메시지: {duration}'**
  String timerLine(String duration);

  /// No description provided for @timerOffLine.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 메시지를 껐어요'**
  String get timerOffLine;

  /// No description provided for @timerInfo.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간이 지나면 이 대화의 새 메시지가 양쪽 모두에서 지워져요.'**
  String get timerInfo;

  /// No description provided for @attachOnce.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기 사진'**
  String get attachOnce;

  /// No description provided for @viewOncePhoto.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기 사진'**
  String get viewOncePhoto;

  /// No description provided for @viewOnceTap.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 열기'**
  String get viewOnceTap;

  /// No description provided for @viewOnceOpened.
  ///
  /// In ko, this message translates to:
  /// **'열어 봤어요'**
  String get viewOnceOpened;

  /// No description provided for @viewOnceOpenedLine.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기 사진을 열어 봤어요'**
  String get viewOnceOpenedLine;

  /// No description provided for @viewOnceInfo.
  ///
  /// In ko, this message translates to:
  /// **'닫으면 다시 볼 수 없어요'**
  String get viewOnceInfo;

  /// No description provided for @profile.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profile;

  /// No description provided for @name.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get name;

  /// No description provided for @changePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 바꾸기'**
  String get changePhoto;

  /// No description provided for @photoServerNote.
  ///
  /// In ko, this message translates to:
  /// **'사진을 \'모두\'로 두면 서버에 저장돼요. \'내 연락처\'로 두면 서버에는 올라가지 않고 친구와의 암호화된 1:1 대화로만 전달돼요.'**
  String get photoServerNote;

  /// No description provided for @chatInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get chatInfo;

  /// No description provided for @members.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get members;

  /// No description provided for @membersCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String membersCount(int count);

  /// No description provided for @owner.
  ///
  /// In ko, this message translates to:
  /// **'방장'**
  String get owner;

  /// No description provided for @admin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get admin;

  /// No description provided for @leaveChat.
  ///
  /// In ko, this message translates to:
  /// **'대화방 나가기'**
  String get leaveChat;

  /// No description provided for @leaveChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 나가기'**
  String get leaveChannel;

  /// No description provided for @leavingIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 나가요'**
  String leavingIn(int seconds);

  /// No description provided for @chatPin.
  ///
  /// In ko, this message translates to:
  /// **'맨 위에 고정'**
  String get chatPin;

  /// No description provided for @chatUnpin.
  ///
  /// In ko, this message translates to:
  /// **'고정 풀기'**
  String get chatUnpin;

  /// No description provided for @chatMute.
  ///
  /// In ko, this message translates to:
  /// **'알림 끄기'**
  String get chatMute;

  /// No description provided for @chatUnmute.
  ///
  /// In ko, this message translates to:
  /// **'알림 켜기'**
  String get chatUnmute;

  /// No description provided for @chatArchive.
  ///
  /// In ko, this message translates to:
  /// **'보관하기'**
  String get chatArchive;

  /// No description provided for @chatUnarchive.
  ///
  /// In ko, this message translates to:
  /// **'보관 풀기'**
  String get chatUnarchive;

  /// No description provided for @archive.
  ///
  /// In ko, this message translates to:
  /// **'보관함'**
  String get archive;

  /// No description provided for @archiveEmpty.
  ///
  /// In ko, this message translates to:
  /// **'보관한 대화가 없어요'**
  String get archiveEmpty;

  /// No description provided for @archiveFooter.
  ///
  /// In ko, this message translates to:
  /// **'보관한 대화는 이 휴대폰에만 표시돼요. 서버는 어떤 대화를 보관했는지 몰라요.'**
  String get archiveFooter;

  /// No description provided for @searchChats.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchChats;

  /// No description provided for @searchNone.
  ///
  /// In ko, this message translates to:
  /// **'찾는 대화가 없어요'**
  String get searchNone;

  /// No description provided for @forward.
  ///
  /// In ko, this message translates to:
  /// **'전달'**
  String get forward;

  /// No description provided for @forwarded.
  ///
  /// In ko, this message translates to:
  /// **'전달된 메시지'**
  String get forwarded;

  /// No description provided for @forwardTo.
  ///
  /// In ko, this message translates to:
  /// **'전달할 대화'**
  String get forwardTo;

  /// No description provided for @forwardDone.
  ///
  /// In ko, this message translates to:
  /// **'전달했어요'**
  String get forwardDone;

  /// No description provided for @forwardFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에는 보낼 수 없어요'**
  String get forwardFailed;

  /// No description provided for @searchInChat.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get searchInChat;

  /// No description provided for @searchCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}/{total}'**
  String searchCount(int n, int total);

  /// No description provided for @searchNoHits.
  ///
  /// In ko, this message translates to:
  /// **'찾는 글이 없어요'**
  String get searchNoHits;

  /// No description provided for @codeBlockCopied.
  ///
  /// In ko, this message translates to:
  /// **'코드를 복사했어요'**
  String get codeBlockCopied;

  /// No description provided for @codeBlockCopy.
  ///
  /// In ko, this message translates to:
  /// **'코드 복사'**
  String get codeBlockCopy;

  /// No description provided for @dateMarkAdd.
  ///
  /// In ko, this message translates to:
  /// **'날짜 넣기'**
  String get dateMarkAdd;

  /// No description provided for @dateMarkTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get dateMarkTime;

  /// No description provided for @fmtDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get fmtDate;

  /// No description provided for @dateCopy.
  ///
  /// In ko, this message translates to:
  /// **'날짜 복사'**
  String get dateCopy;

  /// No description provided for @dateCopied.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 복사했어요'**
  String get dateCopied;

  /// No description provided for @dateToCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더에 추가'**
  String get dateToCalendar;

  /// No description provided for @dateRemind.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get dateRemind;

  /// No description provided for @dateInMyZone.
  ///
  /// In ko, this message translates to:
  /// **'내 시간대({zone}) 기준이에요'**
  String dateInMyZone(String zone);

  /// No description provided for @dateCalendarFailed.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 열지 못했어요'**
  String get dateCalendarFailed;

  /// No description provided for @tomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get tomorrow;

  /// No description provided for @sendAtTime.
  ///
  /// In ko, this message translates to:
  /// **'{date} {time}에 보내기'**
  String sendAtTime(String date, String time);

  /// No description provided for @scheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'메시지 예약'**
  String get scheduleTitle;

  /// No description provided for @reschedule.
  ///
  /// In ko, this message translates to:
  /// **'시간 바꾸기'**
  String get reschedule;

  /// No description provided for @scheduledTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약된 메시지'**
  String get scheduledTitle;

  /// No description provided for @scheduledEmpty.
  ///
  /// In ko, this message translates to:
  /// **'예약된 메시지가 없어요'**
  String get scheduledEmpty;

  /// No description provided for @scheduledFor.
  ///
  /// In ko, this message translates to:
  /// **'{date}에 보낼 메시지'**
  String scheduledFor(String date);

  /// No description provided for @scheduledDeleted.
  ///
  /// In ko, this message translates to:
  /// **'{left}초 뒤 예약을 지워요'**
  String scheduledDeleted(int left);

  /// No description provided for @linkOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'링크 미리보기 설정'**
  String get linkOptionsTitle;

  /// No description provided for @linkOptionsPick.
  ///
  /// In ko, this message translates to:
  /// **'링크를 누르면 그 링크로 미리보기를 만들어요'**
  String get linkOptionsPick;

  /// No description provided for @replyOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'답장 설정'**
  String get replyOptionsTitle;

  /// No description provided for @linkMoveUp.
  ///
  /// In ko, this message translates to:
  /// **'위로 옮기기'**
  String get linkMoveUp;

  /// No description provided for @linkMoveDown.
  ///
  /// In ko, this message translates to:
  /// **'아래로 옮기기'**
  String get linkMoveDown;

  /// No description provided for @linkPhotoSmall.
  ///
  /// In ko, this message translates to:
  /// **'사진 작게'**
  String get linkPhotoSmall;

  /// No description provided for @linkPhotoBig.
  ///
  /// In ko, this message translates to:
  /// **'사진 크게'**
  String get linkPhotoBig;

  /// No description provided for @applyChanges.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get applyChanges;

  /// No description provided for @linkNoPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기 안 함'**
  String get linkNoPreview;

  /// No description provided for @tabReply.
  ///
  /// In ko, this message translates to:
  /// **'답장'**
  String get tabReply;

  /// No description provided for @tabLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get tabLink;

  /// No description provided for @linkBarLoading.
  ///
  /// In ko, this message translates to:
  /// **'미리보기를 만드는 중이에요'**
  String get linkBarLoading;

  /// No description provided for @linkPreviews.
  ///
  /// In ko, this message translates to:
  /// **'링크 미리보기'**
  String get linkPreviews;

  /// No description provided for @linkPreviewInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 보낼 때 내 휴대폰이 그 페이지의 제목과 사진을 가져와 메시지에 암호화해 넣어요. 받는 사람은 그 사이트에 접속하지 않아요.'**
  String get linkPreviewInfo;

  /// No description provided for @voiceHoldHint.
  ///
  /// In ko, this message translates to:
  /// **'길게 눌러 음성 메시지를 녹음해요'**
  String get voiceHoldHint;

  /// No description provided for @voiceNoMic.
  ///
  /// In ko, this message translates to:
  /// **'마이크를 쓸 수 있게 허용해 주세요'**
  String get voiceNoMic;

  /// No description provided for @voiceSlideCancel.
  ///
  /// In ko, this message translates to:
  /// **'‹ 밀어서 취소'**
  String get voiceSlideCancel;

  /// No description provided for @voiceReleaseCancel.
  ///
  /// In ko, this message translates to:
  /// **'놓으면 취소돼요'**
  String get voiceReleaseCancel;

  /// No description provided for @poll.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get poll;

  /// No description provided for @attachPoll.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get attachPoll;

  /// No description provided for @newPoll.
  ///
  /// In ko, this message translates to:
  /// **'새 투표'**
  String get newPoll;

  /// No description provided for @pollQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get pollQuestion;

  /// No description provided for @pollOptions.
  ///
  /// In ko, this message translates to:
  /// **'선택지'**
  String get pollOptions;

  /// No description provided for @pollOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지'**
  String get pollOption;

  /// No description provided for @pollAddOption.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get pollAddOption;

  /// No description provided for @pollAnonymous.
  ///
  /// In ko, this message translates to:
  /// **'익명 투표'**
  String get pollAnonymous;

  /// No description provided for @pollMultiple.
  ///
  /// In ko, this message translates to:
  /// **'여러 개 고르기'**
  String get pollMultiple;

  /// No description provided for @pollMultipleShort.
  ///
  /// In ko, this message translates to:
  /// **'여러 개'**
  String get pollMultipleShort;

  /// No description provided for @pollAnonInfo.
  ///
  /// In ko, this message translates to:
  /// **'누가 무엇을 골랐는지 다른 멤버에게 보이지 않아요. 표는 만든 사람 휴대폰으로만 암호화돼 가고, 대화에는 숫자만 올라가요.'**
  String get pollAnonInfo;

  /// No description provided for @pollOpenInfo.
  ///
  /// In ko, this message translates to:
  /// **'누가 무엇을 골랐는지 멤버 모두에게 보여요.'**
  String get pollOpenInfo;

  /// No description provided for @pollChannelInfo.
  ///
  /// In ko, this message translates to:
  /// **'채널 투표는 항상 익명이에요. 구독자가 누구인지 드러나지 않아요.'**
  String get pollChannelInfo;

  /// No description provided for @pollCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get pollCreate;

  /// No description provided for @pollVoters.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 투표'**
  String pollVoters(int n);

  /// No description provided for @pollNoVotes.
  ///
  /// In ko, this message translates to:
  /// **'아직 투표가 없어요'**
  String get pollNoVotes;

  /// No description provided for @pollOpenKind.
  ///
  /// In ko, this message translates to:
  /// **'공개 투표'**
  String get pollOpenKind;

  /// No description provided for @pollAnonKind.
  ///
  /// In ko, this message translates to:
  /// **'익명 투표'**
  String get pollAnonKind;

  /// No description provided for @pollClosedKind.
  ///
  /// In ko, this message translates to:
  /// **'마감된 투표'**
  String get pollClosedKind;

  /// No description provided for @pollVote.
  ///
  /// In ko, this message translates to:
  /// **'투표하기'**
  String get pollVote;

  /// No description provided for @pollClose.
  ///
  /// In ko, this message translates to:
  /// **'투표 마감'**
  String get pollClose;

  /// No description provided for @pollRetract.
  ///
  /// In ko, this message translates to:
  /// **'투표 취소'**
  String get pollRetract;

  /// No description provided for @stickerRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 사용'**
  String get stickerRecent;

  /// No description provided for @stickerPhrases.
  ///
  /// In ko, this message translates to:
  /// **'빠른 답장 문구'**
  String get stickerPhrases;

  /// No description provided for @stickerNone.
  ///
  /// In ko, this message translates to:
  /// **'맞는 스티커가 없어요'**
  String get stickerNone;

  /// No description provided for @segStickers.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get segStickers;

  /// No description provided for @segEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지'**
  String get segEmoji;

  /// No description provided for @emoji_smileys.
  ///
  /// In ko, this message translates to:
  /// **'스마일리 및 사람'**
  String get emoji_smileys;

  /// No description provided for @emoji_people.
  ///
  /// In ko, this message translates to:
  /// **'손과 사람'**
  String get emoji_people;

  /// No description provided for @emoji_animals.
  ///
  /// In ko, this message translates to:
  /// **'동물 및 자연'**
  String get emoji_animals;

  /// No description provided for @emoji_food.
  ///
  /// In ko, this message translates to:
  /// **'음식 및 음료'**
  String get emoji_food;

  /// No description provided for @emoji_activity.
  ///
  /// In ko, this message translates to:
  /// **'활동'**
  String get emoji_activity;

  /// No description provided for @emoji_travel.
  ///
  /// In ko, this message translates to:
  /// **'여행 및 장소'**
  String get emoji_travel;

  /// No description provided for @emoji_objects.
  ///
  /// In ko, this message translates to:
  /// **'사물'**
  String get emoji_objects;

  /// No description provided for @emoji_symbols.
  ///
  /// In ko, this message translates to:
  /// **'기호'**
  String get emoji_symbols;

  /// No description provided for @stickerTileMake.
  ///
  /// In ko, this message translates to:
  /// **'스티커\n만들기'**
  String get stickerTileMake;

  /// No description provided for @stickerMine.
  ///
  /// In ko, this message translates to:
  /// **'내 스티커'**
  String get stickerMine;

  /// No description provided for @emojiNone.
  ///
  /// In ko, this message translates to:
  /// **'맞는 이모지가 없어요'**
  String get emojiNone;

  /// No description provided for @emojiPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'이모지 고르기'**
  String get emojiPickTitle;

  /// No description provided for @emojiSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'하트, 웃음, 축하처럼 찾아요'**
  String get emojiSearchHint;

  /// No description provided for @emojiSetStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태로'**
  String get emojiSetStatus;

  /// No description provided for @reactAllEmoji.
  ///
  /// In ko, this message translates to:
  /// **'모든 이모지'**
  String get reactAllEmoji;

  /// No description provided for @suggestEmoji.
  ///
  /// In ko, this message translates to:
  /// **'단어로 이모지 추천'**
  String get suggestEmoji;

  /// No description provided for @suggestStickers.
  ///
  /// In ko, this message translates to:
  /// **'이모지로 스티커 추천'**
  String get suggestStickers;

  /// No description provided for @suggestInfo.
  ///
  /// In ko, this message translates to:
  /// **'입력창에 \':웃음\'처럼 쓰면 이모지가, 이모지 하나만 쓰면 어울리는 스티커가 위에 나와요. 모두 이 폰 안에서만 찾아요.'**
  String get suggestInfo;

  /// No description provided for @setsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 스티커 묶음'**
  String get setsTitle;

  /// No description provided for @setsHeader.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 스티커로 묶음을 만들어 친구와 나눠요. 그림은 암호화된 채로만 오가서 서버도 볼 수 없어요.'**
  String get setsHeader;

  /// No description provided for @setsMakeInfo.
  ///
  /// In ko, this message translates to:
  /// **'묶음 하나에 스티커를 50개까지 넣을 수 있어요.'**
  String get setsMakeInfo;

  /// No description provided for @setsNew.
  ///
  /// In ko, this message translates to:
  /// **'새 묶음 만들기'**
  String get setsNew;

  /// No description provided for @setsAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가한 묶음'**
  String get setsAdded;

  /// No description provided for @setsBrowse.
  ///
  /// In ko, this message translates to:
  /// **'스티커 묶음 둘러보기'**
  String get setsBrowse;

  /// No description provided for @setsBurumyPacks.
  ///
  /// In ko, this message translates to:
  /// **'부루미 스티커'**
  String get setsBurumyPacks;

  /// No description provided for @setsBurumyInfo.
  ///
  /// In ko, this message translates to:
  /// **'끈 묶음은 스티커 창에 나오지 않아요.'**
  String get setsBurumyInfo;

  /// No description provided for @setsSeen.
  ///
  /// In ko, this message translates to:
  /// **'대화에서 본 묶음'**
  String get setsSeen;

  /// No description provided for @setsSeenInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구들이 대화에 보낸 묶음이에요. 많이 본 순서로 보여요. 이 목록은 이 폰에만 있어요.'**
  String get setsSeenInfo;

  /// No description provided for @setsSeenNone.
  ///
  /// In ko, this message translates to:
  /// **'친구가 대화에 묶음을 보내면 여기에 모여요.'**
  String get setsSeenNone;

  /// No description provided for @setSeenCount.
  ///
  /// In ko, this message translates to:
  /// **'스티커 {n}개 · {times}번 봤어요'**
  String setSeenCount(int n, int times);

  /// No description provided for @setEdit.
  ///
  /// In ko, this message translates to:
  /// **'묶음 고치기'**
  String get setEdit;

  /// No description provided for @setName.
  ///
  /// In ko, this message translates to:
  /// **'묶음 이름'**
  String get setName;

  /// No description provided for @setNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 우리 강아지'**
  String get setNameHint;

  /// No description provided for @setNameNeeded.
  ///
  /// In ko, this message translates to:
  /// **'묶음 이름을 써 주세요'**
  String get setNameNeeded;

  /// No description provided for @setStickers.
  ///
  /// In ko, this message translates to:
  /// **'스티커 {n}/{max}'**
  String setStickers(int n, int max);

  /// No description provided for @setEmpty.
  ///
  /// In ko, this message translates to:
  /// **'스티커를 하나 이상 넣어 주세요'**
  String get setEmpty;

  /// No description provided for @setOrderInfo.
  ///
  /// In ko, this message translates to:
  /// **'스티커를 누르면 순서를 바꾸거나 이모지를 정할 수 있어요. 이모지를 정하면 입력창에 그 이모지를 쓸 때 추천돼요.'**
  String get setOrderInfo;

  /// No description provided for @setItemEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지 정하기'**
  String get setItemEmoji;

  /// No description provided for @setItemEmojiNow.
  ///
  /// In ko, this message translates to:
  /// **'이모지 바꾸기 ({emoji})'**
  String setItemEmojiNow(String emoji);

  /// No description provided for @setItemFirst.
  ///
  /// In ko, this message translates to:
  /// **'맨 앞으로'**
  String get setItemFirst;

  /// No description provided for @setItemLeft.
  ///
  /// In ko, this message translates to:
  /// **'앞으로'**
  String get setItemLeft;

  /// No description provided for @setItemRight.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get setItemRight;

  /// No description provided for @setItemRemove.
  ///
  /// In ko, this message translates to:
  /// **'묶음에서 빼기'**
  String get setItemRemove;

  /// No description provided for @setPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'스티커 고르기'**
  String get setPickTitle;

  /// No description provided for @setPicked.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 골랐어요'**
  String setPicked(int n);

  /// No description provided for @setShare.
  ///
  /// In ko, this message translates to:
  /// **'묶음 나누기'**
  String get setShare;

  /// No description provided for @setShareInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화에 보내거나 링크로 나눠요. 받은 사람은 그대로 추가해 쓸 수 있어요.'**
  String get setShareInfo;

  /// No description provided for @setShareSheetInfo.
  ///
  /// In ko, this message translates to:
  /// **'묶음은 이 폰에서 암호화돼 올라가요. 열쇠는 대화나 링크 안에만 있어서 서버는 그림도 이름도 볼 수 없어요.'**
  String get setShareSheetInfo;

  /// No description provided for @setShareToChat.
  ///
  /// In ko, this message translates to:
  /// **'대화에 보내기'**
  String get setShareToChat;

  /// No description provided for @setCopyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get setCopyLink;

  /// No description provided for @setSent.
  ///
  /// In ko, this message translates to:
  /// **'묶음을 보냈어요'**
  String get setSent;

  /// No description provided for @setLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했어요'**
  String get setLinkCopied;

  /// No description provided for @setDelete.
  ///
  /// In ko, this message translates to:
  /// **'묶음 지우기'**
  String get setDelete;

  /// No description provided for @setDeleteInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 폰에서 묶음을 지워요. 이미 나눈 링크로는 계속 열 수 있어요.'**
  String get setDeleteInfo;

  /// No description provided for @setOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'묶음을 열 수 없어요. 링크가 잘렸거나 지워진 묶음일 수 있어요.'**
  String get setOpenFailed;

  /// No description provided for @setPrivateInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 묶음은 암호화된 채로만 오갔어요. 서버는 누가 어떤 묶음을 쓰는지 몰라요.'**
  String get setPrivateInfo;

  /// No description provided for @setAddCount.
  ///
  /// In ko, this message translates to:
  /// **'스티커 {n}개 추가하기'**
  String setAddCount(int n);

  /// No description provided for @setRemove.
  ///
  /// In ko, this message translates to:
  /// **'묶음 빼기 ({n}개)'**
  String setRemove(int n);

  /// No description provided for @setAdded.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 묶음을 추가했어요'**
  String setAdded(String name);

  /// No description provided for @setRemoved.
  ///
  /// In ko, this message translates to:
  /// **'묶음을 뺐어요'**
  String get setRemoved;

  /// No description provided for @setAddShort.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get setAddShort;

  /// No description provided for @setAddedShort.
  ///
  /// In ko, this message translates to:
  /// **'추가됨'**
  String get setAddedShort;

  /// No description provided for @setCardKind.
  ///
  /// In ko, this message translates to:
  /// **'스티커 묶음'**
  String get setCardKind;

  /// No description provided for @setCardView.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get setCardView;

  /// No description provided for @setCardHave.
  ///
  /// In ko, this message translates to:
  /// **'추가됨 · 보기'**
  String get setCardHave;

  /// No description provided for @statusTitle.
  ///
  /// In ko, this message translates to:
  /// **'이모지 상태'**
  String get statusTitle;

  /// No description provided for @statusInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름 옆에 지금 상태를 이모지로 보여줘요. 1:1 대화를 하는 친구에게만 암호화돼 전해져요.'**
  String get statusInfo;

  /// No description provided for @statusOther.
  ///
  /// In ko, this message translates to:
  /// **'다른 이모지 고르기'**
  String get statusOther;

  /// No description provided for @statusClear.
  ///
  /// In ko, this message translates to:
  /// **'상태 지우기'**
  String get statusClear;

  /// No description provided for @statusCleared.
  ///
  /// In ko, this message translates to:
  /// **'상태를 지웠어요'**
  String get statusCleared;

  /// No description provided for @statusHowLong.
  ///
  /// In ko, this message translates to:
  /// **'얼마 동안 보여줄까요?'**
  String get statusHowLong;

  /// No description provided for @statusFor1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get statusFor1h;

  /// No description provided for @statusFor2h.
  ///
  /// In ko, this message translates to:
  /// **'2시간'**
  String get statusFor2h;

  /// No description provided for @statusFor8h.
  ///
  /// In ko, this message translates to:
  /// **'8시간'**
  String get statusFor8h;

  /// No description provided for @statusFor2d.
  ///
  /// In ko, this message translates to:
  /// **'2일'**
  String get statusFor2d;

  /// No description provided for @statusForEver.
  ///
  /// In ko, this message translates to:
  /// **'직접 지울 때까지'**
  String get statusForEver;

  /// No description provided for @statusSet.
  ///
  /// In ko, this message translates to:
  /// **'{emoji} 상태를 달았어요'**
  String statusSet(String emoji);

  /// No description provided for @statusRow.
  ///
  /// In ko, this message translates to:
  /// **'이모지 상태'**
  String get statusRow;

  /// No description provided for @stickerMakeTitle.
  ///
  /// In ko, this message translates to:
  /// **'스티커 만들기'**
  String get stickerMakeTitle;

  /// No description provided for @stickerMakeCut.
  ///
  /// In ko, this message translates to:
  /// **'오려내기'**
  String get stickerMakeCut;

  /// No description provided for @stickerMakeOutline.
  ///
  /// In ko, this message translates to:
  /// **'흰 테두리'**
  String get stickerMakeOutline;

  /// No description provided for @stickerMakeText.
  ///
  /// In ko, this message translates to:
  /// **'글자 넣기'**
  String get stickerMakeText;

  /// No description provided for @stickerMakeRound.
  ///
  /// In ko, this message translates to:
  /// **'둥근 네모'**
  String get stickerMakeRound;

  /// No description provided for @stickerMakeCircle.
  ///
  /// In ko, this message translates to:
  /// **'동그라미'**
  String get stickerMakeCircle;

  /// No description provided for @stickerMakeWorking.
  ///
  /// In ko, this message translates to:
  /// **'오려내는 중…'**
  String get stickerMakeWorking;

  /// No description provided for @stickerMakeInfo.
  ///
  /// In ko, this message translates to:
  /// **'사진은 이 휴대폰 안에서만 처리돼요. 눌러서 다른 사진을 골라요.'**
  String get stickerMakeInfo;

  /// No description provided for @stickerMakeNoCut.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 자동으로 오려낼 수 없어서 사진을 모양 안에 넣었어요.'**
  String get stickerMakeNoCut;

  /// No description provided for @stickerTileBubble.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울\n보내기'**
  String get stickerTileBubble;

  /// No description provided for @attachBubble.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울'**
  String get attachBubble;

  /// No description provided for @bubbleSendTitle.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울 보내기'**
  String get bubbleSendTitle;

  /// No description provided for @bubbleSendInfo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 홈 화면에 방울이 떠요. 안에 무엇이 들었는지는 보이지 않고, 터뜨리면 한 번만 열려요.'**
  String bubbleSendInfo(String name);

  /// No description provided for @bubbleRecord.
  ///
  /// In ko, this message translates to:
  /// **'음성 녹음'**
  String get bubbleRecord;

  /// No description provided for @bubblesWaiting.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울 {n}개'**
  String bubblesWaiting(int n);

  /// No description provided for @bubbleTapToPop.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 터뜨리기'**
  String get bubbleTapToPop;

  /// No description provided for @bubbleSent.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울을 보냈어요'**
  String get bubbleSent;

  /// No description provided for @bubblePopped.
  ///
  /// In ko, this message translates to:
  /// **'터뜨렸어요'**
  String get bubblePopped;

  /// No description provided for @bubbleOnce.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 볼 수 있어요. 닫으면 사라져요.'**
  String get bubbleOnce;

  /// No description provided for @bubbleGone.
  ///
  /// In ko, this message translates to:
  /// **'이미 터진 방울이에요'**
  String get bubbleGone;

  /// No description provided for @callVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성 통화'**
  String get callVoice;

  /// No description provided for @callVideo.
  ///
  /// In ko, this message translates to:
  /// **'영상 통화'**
  String get callVideo;

  /// No description provided for @callCalling.
  ///
  /// In ko, this message translates to:
  /// **'거는 중…'**
  String get callCalling;

  /// No description provided for @callConnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 중…'**
  String get callConnecting;

  /// No description provided for @callEnded.
  ///
  /// In ko, this message translates to:
  /// **'통화 종료'**
  String get callEnded;

  /// No description provided for @callNoAnswer.
  ///
  /// In ko, this message translates to:
  /// **'받지 않았어요'**
  String get callNoAnswer;

  /// No description provided for @callDeclined.
  ///
  /// In ko, this message translates to:
  /// **'상대가 거절했어요'**
  String get callDeclined;

  /// No description provided for @callBusy.
  ///
  /// In ko, this message translates to:
  /// **'상대가 통화 중이에요'**
  String get callBusy;

  /// No description provided for @callFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결하지 못했어요'**
  String get callFailed;

  /// No description provided for @callAccept.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get callAccept;

  /// No description provided for @callDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get callDecline;

  /// No description provided for @callEnd.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get callEnd;

  /// No description provided for @callMute.
  ///
  /// In ko, this message translates to:
  /// **'음소거'**
  String get callMute;

  /// No description provided for @callSpeaker.
  ///
  /// In ko, this message translates to:
  /// **'스피커'**
  String get callSpeaker;

  /// No description provided for @callCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get callCamera;

  /// No description provided for @callFlip.
  ///
  /// In ko, this message translates to:
  /// **'전환'**
  String get callFlip;

  /// No description provided for @callE2ee.
  ///
  /// In ko, this message translates to:
  /// **'끝에서 끝까지 암호화돼요'**
  String get callE2ee;

  /// No description provided for @callLineOut.
  ///
  /// In ko, this message translates to:
  /// **'건 통화'**
  String get callLineOut;

  /// No description provided for @callLineIn.
  ///
  /// In ko, this message translates to:
  /// **'받은 통화'**
  String get callLineIn;

  /// No description provided for @callLineMissed.
  ///
  /// In ko, this message translates to:
  /// **'부재중 통화'**
  String get callLineMissed;

  /// No description provided for @callLineDeclined.
  ///
  /// In ko, this message translates to:
  /// **'거절한 통화'**
  String get callLineDeclined;

  /// No description provided for @callLineCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소한 통화'**
  String get callLineCancelled;

  /// No description provided for @callLineNow.
  ///
  /// In ko, this message translates to:
  /// **'통화 중'**
  String get callLineNow;

  /// No description provided for @callNotSetUp.
  ///
  /// In ko, this message translates to:
  /// **'이 버전에서는 아직 통화를 쓸 수 없어요'**
  String get callNotSetUp;

  /// No description provided for @callBack.
  ///
  /// In ko, this message translates to:
  /// **'다시 걸기'**
  String get callBack;

  /// No description provided for @callPreview.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get callPreview;

  /// No description provided for @noticeNew.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지'**
  String get noticeNew;

  /// No description provided for @noticeTextHidden.
  ///
  /// In ko, this message translates to:
  /// **'알림에 내용 숨기기'**
  String get noticeTextHidden;

  /// No description provided for @noticeTextHiddenInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 알림에 대화 이름과 내용 없이 \'새 메시지\'만 보여요. 알림 내용은 이 휴대폰에서만 풀어요.'**
  String get noticeTextHiddenInfo;

  /// No description provided for @noticeChannel.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get noticeChannel;

  /// No description provided for @wipeAfter.
  ///
  /// In ko, this message translates to:
  /// **'틀리면 모두 지우기'**
  String get wipeAfter;

  /// No description provided for @wipeAfterInfo.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 연속으로 이만큼 틀리면 이 휴대폰의 모든 대화가 지워져요. 1:1 대화는 상대 휴대폰에서도 지워지고, 그룹·채널은 며칠에 걸쳐 조용히 나가요.'**
  String get wipeAfterInfo;

  /// No description provided for @wipeTimes.
  ///
  /// In ko, this message translates to:
  /// **'{n}번'**
  String wipeTimes(int n);

  /// No description provided for @wipeWarning.
  ///
  /// In ko, this message translates to:
  /// **'{n}번 더 틀리면 모든 대화가 지워져요'**
  String wipeWarning(int n);

  /// No description provided for @deleteForBoth.
  ///
  /// In ko, this message translates to:
  /// **'양쪽에서 대화 삭제'**
  String get deleteForBoth;

  /// No description provided for @deleteForBothInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 휴대폰과 상대 휴대폰 모두에서 이 대화가 지워져요.'**
  String get deleteForBothInfo;

  /// No description provided for @deletingIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤 삭제돼요'**
  String deletingIn(int seconds);

  /// No description provided for @erasedByFriend.
  ///
  /// In ko, this message translates to:
  /// **'상대가 양쪽에서 대화를 지웠어요 · {name}'**
  String erasedByFriend(String name);

  /// No description provided for @editorReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get editorReset;

  /// No description provided for @editorCrop.
  ///
  /// In ko, this message translates to:
  /// **'자르기'**
  String get editorCrop;

  /// No description provided for @editorFilters.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get editorFilters;

  /// No description provided for @editorAdjust.
  ///
  /// In ko, this message translates to:
  /// **'조절'**
  String get editorAdjust;

  /// No description provided for @filterNone.
  ///
  /// In ko, this message translates to:
  /// **'원본'**
  String get filterNone;

  /// No description provided for @filterVivid.
  ///
  /// In ko, this message translates to:
  /// **'선명하게'**
  String get filterVivid;

  /// No description provided for @filterWarm.
  ///
  /// In ko, this message translates to:
  /// **'따뜻하게'**
  String get filterWarm;

  /// No description provided for @filterCool.
  ///
  /// In ko, this message translates to:
  /// **'차갑게'**
  String get filterCool;

  /// No description provided for @filterDramatic.
  ///
  /// In ko, this message translates to:
  /// **'드라마틱'**
  String get filterDramatic;

  /// No description provided for @filterMono.
  ///
  /// In ko, this message translates to:
  /// **'흑백'**
  String get filterMono;

  /// No description provided for @filterSilver.
  ///
  /// In ko, this message translates to:
  /// **'실버'**
  String get filterSilver;

  /// No description provided for @filterNoir.
  ///
  /// In ko, this message translates to:
  /// **'누아르'**
  String get filterNoir;

  /// No description provided for @filterFade.
  ///
  /// In ko, this message translates to:
  /// **'바랜'**
  String get filterFade;

  /// No description provided for @filterFilm.
  ///
  /// In ko, this message translates to:
  /// **'필름'**
  String get filterFilm;

  /// No description provided for @adjExposure.
  ///
  /// In ko, this message translates to:
  /// **'노출'**
  String get adjExposure;

  /// No description provided for @adjBrilliance.
  ///
  /// In ko, this message translates to:
  /// **'휘도'**
  String get adjBrilliance;

  /// No description provided for @adjHighlights.
  ///
  /// In ko, this message translates to:
  /// **'하이라이트'**
  String get adjHighlights;

  /// No description provided for @adjShadows.
  ///
  /// In ko, this message translates to:
  /// **'그림자'**
  String get adjShadows;

  /// No description provided for @adjContrast.
  ///
  /// In ko, this message translates to:
  /// **'대비'**
  String get adjContrast;

  /// No description provided for @adjBrightness.
  ///
  /// In ko, this message translates to:
  /// **'밝기'**
  String get adjBrightness;

  /// No description provided for @adjBlackPoint.
  ///
  /// In ko, this message translates to:
  /// **'블랙 포인트'**
  String get adjBlackPoint;

  /// No description provided for @adjSaturation.
  ///
  /// In ko, this message translates to:
  /// **'채도'**
  String get adjSaturation;

  /// No description provided for @adjVibrance.
  ///
  /// In ko, this message translates to:
  /// **'생동감'**
  String get adjVibrance;

  /// No description provided for @adjWarmth.
  ///
  /// In ko, this message translates to:
  /// **'색온도'**
  String get adjWarmth;

  /// No description provided for @adjTint.
  ///
  /// In ko, this message translates to:
  /// **'색조'**
  String get adjTint;

  /// No description provided for @adjFade.
  ///
  /// In ko, this message translates to:
  /// **'바래기'**
  String get adjFade;

  /// No description provided for @adjVignette.
  ///
  /// In ko, this message translates to:
  /// **'비네트'**
  String get adjVignette;

  /// No description provided for @inviteFrom.
  ///
  /// In ko, this message translates to:
  /// **'초대한 사람 · {name}'**
  String inviteFrom(String name);

  /// No description provided for @inviteAccept.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get inviteAccept;

  /// No description provided for @inviteDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get inviteDecline;

  /// No description provided for @callWaiting.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 전화'**
  String get callWaiting;

  /// No description provided for @callWaitingVideo.
  ///
  /// In ko, this message translates to:
  /// **'대기 중인 영상 통화'**
  String get callWaitingVideo;

  /// No description provided for @callWaitingTitle.
  ///
  /// In ko, this message translates to:
  /// **'통화 중 걸려온 전화'**
  String get callWaitingTitle;

  /// No description provided for @callWaitingWait.
  ///
  /// In ko, this message translates to:
  /// **'대기 통화'**
  String get callWaitingWait;

  /// No description provided for @callWaitingMissed.
  ///
  /// In ko, this message translates to:
  /// **'부재중으로 남기기'**
  String get callWaitingMissed;

  /// No description provided for @callWaitingBusy.
  ///
  /// In ko, this message translates to:
  /// **'통화 중이라고 알리기'**
  String get callWaitingBusy;

  /// No description provided for @callWaitingInfo.
  ///
  /// In ko, this message translates to:
  /// **'대기 통화: 거는 사람은 계속 울리는 소리를 듣고, 나는 받을 수 있어요. 부재중으로 남기기: 통화 중에는 아무것도 뜨지 않고 부재중 전화로 남아요. 통화 중이라고 알리기: 거는 사람에게 통화 중이라고 보여요.'**
  String get callWaitingInfo;

  /// No description provided for @tabCalls.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get tabCalls;

  /// No description provided for @callsAll.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get callsAll;

  /// No description provided for @callsMissed.
  ///
  /// In ko, this message translates to:
  /// **'부재중'**
  String get callsMissed;

  /// No description provided for @callsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 통화 기록이 없어요'**
  String get callsEmpty;

  /// No description provided for @callsEmptyMissed.
  ///
  /// In ko, this message translates to:
  /// **'부재중 통화가 없어요'**
  String get callsEmptyMissed;

  /// No description provided for @callsNew.
  ///
  /// In ko, this message translates to:
  /// **'새 통화'**
  String get callsNew;

  /// No description provided for @settingsAppearance.
  ///
  /// In ko, this message translates to:
  /// **'모양'**
  String get settingsAppearance;

  /// No description provided for @settingsNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get settingsNotifications;

  /// No description provided for @settingsChatsPage.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get settingsChatsPage;

  /// No description provided for @settingsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 및 보안'**
  String get settingsPrivacy;

  /// No description provided for @privacyInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금, 숨김·삭제 비밀번호, 대화 복구 키 같은 보안 기능을 관리해요.'**
  String get privacyInfo;

  /// No description provided for @contactsAddById.
  ///
  /// In ko, this message translates to:
  /// **'아이디로 친구 추가'**
  String get contactsAddById;

  /// No description provided for @contactsInvite.
  ///
  /// In ko, this message translates to:
  /// **'친구 초대'**
  String get contactsInvite;

  /// No description provided for @inviteText.
  ///
  /// In ko, this message translates to:
  /// **'부루미에서 같이 대화해요. 제 아이디: {id}'**
  String inviteText(String id);

  /// No description provided for @inviteCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 글을 복사했어요. 친구에게 붙여 넣어 보내세요.'**
  String get inviteCopied;

  /// No description provided for @chatsMenuArchive.
  ///
  /// In ko, this message translates to:
  /// **'보관함'**
  String get chatsMenuArchive;

  /// No description provided for @sortByName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get sortByName;

  /// No description provided for @sortByRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 대화순'**
  String get sortByRecent;

  /// No description provided for @colorTheme.
  ///
  /// In ko, this message translates to:
  /// **'색 테마'**
  String get colorTheme;

  /// No description provided for @nightMode.
  ///
  /// In ko, this message translates to:
  /// **'야간 모드'**
  String get nightMode;

  /// No description provided for @nightSystem.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정 따르기'**
  String get nightSystem;

  /// No description provided for @nightLight.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get nightLight;

  /// No description provided for @nightDark.
  ///
  /// In ko, this message translates to:
  /// **'켜기'**
  String get nightDark;

  /// No description provided for @textSize.
  ///
  /// In ko, this message translates to:
  /// **'텍스트 크기'**
  String get textSize;

  /// No description provided for @bubbleCorners.
  ///
  /// In ko, this message translates to:
  /// **'메시지 모서리'**
  String get bubbleCorners;

  /// No description provided for @bubbleSample.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요! 👋'**
  String get bubbleSample;

  /// No description provided for @stickersEmoji.
  ///
  /// In ko, this message translates to:
  /// **'스티커 및 이모지'**
  String get stickersEmoji;

  /// No description provided for @doubleTapInfo.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 두 번 누르면 고른 반응이 붙어요.'**
  String get doubleTapInfo;

  /// No description provided for @quickReaction.
  ///
  /// In ko, this message translates to:
  /// **'빠른 반응'**
  String get quickReaction;

  /// No description provided for @doubleTapReact.
  ///
  /// In ko, this message translates to:
  /// **'두 번 눌러 반응'**
  String get doubleTapReact;

  /// No description provided for @powerSaving.
  ///
  /// In ko, this message translates to:
  /// **'절전'**
  String get powerSaving;

  /// No description provided for @powerSavingInfo.
  ///
  /// In ko, this message translates to:
  /// **'배터리를 아끼도록 움직임 효과를 줄여요.'**
  String get powerSavingInfo;

  /// No description provided for @uiEffects.
  ///
  /// In ko, this message translates to:
  /// **'화면 효과'**
  String get uiEffects;

  /// No description provided for @uiEffectsInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 화면이 바뀔 때 움직임 없이 바로 바뀌어요.'**
  String get uiEffectsInfo;

  /// No description provided for @messageNotices.
  ///
  /// In ko, this message translates to:
  /// **'메시지 알림'**
  String get messageNotices;

  /// No description provided for @notifyDirect.
  ///
  /// In ko, this message translates to:
  /// **'개인 대화'**
  String get notifyDirect;

  /// No description provided for @notifyGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 대화'**
  String get notifyGroup;

  /// No description provided for @notifyChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get notifyChannel;

  /// No description provided for @resetNotices.
  ///
  /// In ko, this message translates to:
  /// **'모든 알림 설정 재설정'**
  String get resetNotices;

  /// No description provided for @enterSends.
  ///
  /// In ko, this message translates to:
  /// **'엔터로 보내기'**
  String get enterSends;

  /// No description provided for @swipeReply.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽으로 밀어서 답장'**
  String get swipeReply;

  /// No description provided for @dataStorage.
  ///
  /// In ko, this message translates to:
  /// **'데이터 및 저장 공간'**
  String get dataStorage;

  /// No description provided for @whoEveryone.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get whoEveryone;

  /// No description provided for @whoContacts.
  ///
  /// In ko, this message translates to:
  /// **'내 연락처'**
  String get whoContacts;

  /// No description provided for @whoNobody.
  ///
  /// In ko, this message translates to:
  /// **'아무도 안 됨'**
  String get whoNobody;

  /// No description provided for @blockedUsers.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사용자'**
  String get blockedUsers;

  /// No description provided for @defaultTimer.
  ///
  /// In ko, this message translates to:
  /// **'메시지 자동 삭제'**
  String get defaultTimer;

  /// No description provided for @defaultTimerInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 새로 만드는 대화의 메시지가 정한 시간 뒤 양쪽에서 지워져요.'**
  String get defaultTimerInfo;

  /// No description provided for @privacyWho.
  ///
  /// In ko, this message translates to:
  /// **'개인 정보'**
  String get privacyWho;

  /// No description provided for @whoInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 연락처가 아닌 사람의 전화는 부재중으로 남고, 메시지·초대는 보이지 않아요.'**
  String get whoInfo;

  /// No description provided for @whoCalls.
  ///
  /// In ko, this message translates to:
  /// **'전화'**
  String get whoCalls;

  /// No description provided for @whoMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get whoMessages;

  /// No description provided for @whoInvites.
  ///
  /// In ko, this message translates to:
  /// **'그룹·채널 초대'**
  String get whoInvites;

  /// No description provided for @readTypingInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 상대에게도 내 읽음 표시와 입력 중 표시가 가지 않아요.'**
  String get readTypingInfo;

  /// No description provided for @sendRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음 표시 보내기'**
  String get sendRead;

  /// No description provided for @sendTyping.
  ///
  /// In ko, this message translates to:
  /// **'입력 중 표시 보내기'**
  String get sendTyping;

  /// No description provided for @devices.
  ///
  /// In ko, this message translates to:
  /// **'기기'**
  String get devices;

  /// No description provided for @encryptionKeys.
  ///
  /// In ko, this message translates to:
  /// **'암호화 키'**
  String get encryptionKeys;

  /// No description provided for @blockedInfo.
  ///
  /// In ko, this message translates to:
  /// **'차단한 사람의 메시지와 초대는 나에게 오지 않아요. 상대에게는 알리지 않아요.'**
  String get blockedInfo;

  /// No description provided for @blockSomeone.
  ///
  /// In ko, this message translates to:
  /// **'사용자 차단하기'**
  String get blockSomeone;

  /// No description provided for @unblock.
  ///
  /// In ko, this message translates to:
  /// **'차단 풀기'**
  String get unblock;

  /// No description provided for @blockFailed.
  ///
  /// In ko, this message translates to:
  /// **'차단하지 못했어요. 아이디를 확인해 주세요.'**
  String get blockFailed;

  /// No description provided for @userIdHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get userIdHint;

  /// No description provided for @deviceVerified.
  ///
  /// In ko, this message translates to:
  /// **'확인된 기기'**
  String get deviceVerified;

  /// No description provided for @deviceNotVerified.
  ///
  /// In ko, this message translates to:
  /// **'아직 확인 안 된 기기'**
  String get deviceNotVerified;

  /// No description provided for @thisDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기'**
  String get thisDevice;

  /// No description provided for @logOutOthers.
  ///
  /// In ko, this message translates to:
  /// **'다른 모든 기기 로그아웃'**
  String get logOutOthers;

  /// No description provided for @otherDevices.
  ///
  /// In ko, this message translates to:
  /// **'다른 기기'**
  String get otherDevices;

  /// No description provided for @passwordAgainInfo.
  ///
  /// In ko, this message translates to:
  /// **'안전을 위해 계정 비밀번호를 한 번 더 넣어 주세요.'**
  String get passwordAgainInfo;

  /// No description provided for @keysInfo.
  ///
  /// In ko, this message translates to:
  /// **'상대와 직접 만나 이 키를 비교하면 중간에서 엿보는 사람이 없는지 확인할 수 있어요. 눌러서 복사해요.'**
  String get keysInfo;

  /// No description provided for @myIdentityKey.
  ///
  /// In ko, this message translates to:
  /// **'내 신원 키'**
  String get myIdentityKey;

  /// No description provided for @thisDeviceKey.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 키'**
  String get thisDeviceKey;

  /// No description provided for @savedMessages.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지'**
  String get savedMessages;

  /// No description provided for @chatBackup.
  ///
  /// In ko, this message translates to:
  /// **'대화 백업'**
  String get chatBackup;

  /// No description provided for @editShort.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get editShort;

  /// No description provided for @idLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get idLabel;

  /// No description provided for @blockUser.
  ///
  /// In ko, this message translates to:
  /// **'사용자 차단'**
  String get blockUser;

  /// No description provided for @veilDots.
  ///
  /// In ko, this message translates to:
  /// **'대화방 가리기'**
  String get veilDots;

  /// No description provided for @veilDotsInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방의 메시지가 반짝이는 점으로 가려지고, 손가락으로 누르고 있는 동안만 보여요. 메뉴는 짧게 톡 누르면 열려요.'**
  String get veilDotsInfo;

  /// No description provided for @readHere.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에서 읽음 표시'**
  String get readHere;

  /// No description provided for @veilBlur.
  ///
  /// In ko, this message translates to:
  /// **'민감한 대화'**
  String get veilBlur;

  /// No description provided for @veilBlurInfo.
  ///
  /// In ko, this message translates to:
  /// **'민감한 대화는 흐린 유리 아래 있고, 손가락을 대고 있는 동안만 선명하게 보여요. 옆사람이 훔쳐볼 수 없어요.'**
  String get veilBlurInfo;

  /// No description provided for @tabMedia.
  ///
  /// In ko, this message translates to:
  /// **'미디어'**
  String get tabMedia;

  /// No description provided for @tabFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get tabFiles;

  /// No description provided for @tabLinks.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get tabLinks;

  /// No description provided for @nothingShared.
  ///
  /// In ko, this message translates to:
  /// **'아직 없어요'**
  String get nothingShared;

  /// No description provided for @bio.
  ///
  /// In ko, this message translates to:
  /// **'자기소개'**
  String get bio;

  /// No description provided for @bioInfo.
  ///
  /// In ko, this message translates to:
  /// **'누가 볼지는 설정 > 개인정보 및 보안에서 정해요. 70자까지 쓸 수 있어요.'**
  String get bioInfo;

  /// No description provided for @markRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get markRead;

  /// No description provided for @hideFromList.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 숨기기'**
  String get hideFromList;

  /// No description provided for @hiddenChats.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 대화방'**
  String get hiddenChats;

  /// No description provided for @hiddenChatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'목록에서 숨긴 대화방이에요. 메시지와 알림은 그대로 와요. 누르면 다시 목록에 보여요.'**
  String get hiddenChatsInfo;

  /// No description provided for @showInList.
  ///
  /// In ko, this message translates to:
  /// **'목록에 다시 보이기'**
  String get showInList;

  /// No description provided for @filterAll.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get filterAll;

  /// No description provided for @filterUnread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음'**
  String get filterUnread;

  /// No description provided for @filterPeople.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get filterPeople;

  /// No description provided for @filterGroups.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get filterGroups;

  /// No description provided for @filterChannels.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get filterChannels;

  /// No description provided for @filterBots.
  ///
  /// In ko, this message translates to:
  /// **'봇'**
  String get filterBots;

  /// No description provided for @myFolders.
  ///
  /// In ko, this message translates to:
  /// **'내 폴더'**
  String get myFolders;

  /// No description provided for @newFolder.
  ///
  /// In ko, this message translates to:
  /// **'새 폴더'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In ko, this message translates to:
  /// **'폴더 이름'**
  String get folderName;

  /// No description provided for @folderKinds.
  ///
  /// In ko, this message translates to:
  /// **'포함할 대화'**
  String get folderKinds;

  /// No description provided for @folderInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 종류의 대화가 모두 들어가요. 아래에서 대화를 하나씩 넣거나 뺄 수도 있어요. 폴더는 이 기기에만 저장돼요.'**
  String get folderInfo;

  /// No description provided for @folderChats.
  ///
  /// In ko, this message translates to:
  /// **'대화 고르기'**
  String get folderChats;

  /// No description provided for @deleteFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 삭제'**
  String get deleteFolder;

  /// No description provided for @listTop.
  ///
  /// In ko, this message translates to:
  /// **'위쪽에 검색과 폴더 보이기'**
  String get listTop;

  /// No description provided for @listTopInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 대화 목록이 더 넓어져요. 검색과 폴더는 왼쪽 위 메뉴에 있어요.'**
  String get listTopInfo;

  /// No description provided for @saveToSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지에 넣기'**
  String get saveToSaved;

  /// No description provided for @savedDone.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지에 넣었어요'**
  String get savedDone;

  /// No description provided for @sendQuietly.
  ///
  /// In ko, this message translates to:
  /// **'조용히 보내기'**
  String get sendQuietly;

  /// No description provided for @sendLater.
  ///
  /// In ko, this message translates to:
  /// **'예약 보내기'**
  String get sendLater;

  /// No description provided for @scheduleSend.
  ///
  /// In ko, this message translates to:
  /// **'이때 보내기'**
  String get scheduleSend;

  /// No description provided for @scheduledDone.
  ///
  /// In ko, this message translates to:
  /// **'예약했어요'**
  String get scheduledDone;

  /// No description provided for @scheduledCount.
  ///
  /// In ko, this message translates to:
  /// **'예약된 메시지 {count}개'**
  String scheduledCount(int count);

  /// No description provided for @scheduledInfo.
  ///
  /// In ko, this message translates to:
  /// **'예약한 메시지는 이 휴대폰에 있다가, 정한 시간에 앱이 열려 있으면 바로, 아니면 다음에 앱을 열 때 보내져요.'**
  String get scheduledInfo;

  /// No description provided for @sendNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 보내기'**
  String get sendNow;

  /// No description provided for @fmtBold.
  ///
  /// In ko, this message translates to:
  /// **'굵게'**
  String get fmtBold;

  /// No description provided for @fmtItalic.
  ///
  /// In ko, this message translates to:
  /// **'기울임'**
  String get fmtItalic;

  /// No description provided for @fmtUnderline.
  ///
  /// In ko, this message translates to:
  /// **'밑줄'**
  String get fmtUnderline;

  /// No description provided for @fmtStrike.
  ///
  /// In ko, this message translates to:
  /// **'취소선'**
  String get fmtStrike;

  /// No description provided for @fmtCode.
  ///
  /// In ko, this message translates to:
  /// **'고정폭'**
  String get fmtCode;

  /// No description provided for @fmtSpoiler.
  ///
  /// In ko, this message translates to:
  /// **'스포일러'**
  String get fmtSpoiler;

  /// No description provided for @fmtLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get fmtLink;

  /// No description provided for @more.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get more;

  /// No description provided for @contactEdit.
  ///
  /// In ko, this message translates to:
  /// **'연락처 편집'**
  String get contactEdit;

  /// No description provided for @contactNameInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 이름은 내 휴대폰에서만 보여요. 상대방은 몰라요.'**
  String get contactNameInfo;

  /// No description provided for @memo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memo;

  /// No description provided for @memoHint.
  ///
  /// In ko, this message translates to:
  /// **'이 사람에 대해 기억할 것'**
  String get memoHint;

  /// No description provided for @memoInfo.
  ///
  /// In ko, this message translates to:
  /// **'메모도 내 휴대폰에만 남아요.'**
  String get memoInfo;

  /// No description provided for @clearChat.
  ///
  /// In ko, this message translates to:
  /// **'메시지 비우기'**
  String get clearChat;

  /// No description provided for @clearChatInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 화면에서만 지워져요. 상대방 화면은 그대로예요.'**
  String get clearChatInfo;

  /// No description provided for @clearChatDone.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 비웠어요'**
  String get clearChatDone;

  /// No description provided for @send.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get send;

  /// No description provided for @attachGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get attachGallery;

  /// No description provided for @attachCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get attachCamera;

  /// No description provided for @attachLibrary.
  ///
  /// In ko, this message translates to:
  /// **'사진 고르기'**
  String get attachLibrary;

  /// No description provided for @attachPickFile.
  ///
  /// In ko, this message translates to:
  /// **'파일 고르기'**
  String get attachPickFile;

  /// No description provided for @attachFileInfo.
  ///
  /// In ko, this message translates to:
  /// **'사진도 원본 그대로 파일로 보낼 수 있어요. 한 번에 20개까지요.'**
  String get attachFileInfo;

  /// No description provided for @selectedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String selectedCount(int count);

  /// No description provided for @onceOnInfo.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 볼 수 있고, 24시간 안에 안 열면 사라져요'**
  String get onceOnInfo;

  /// No description provided for @onceNoCaption.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기에는 설명을 붙이지 않아요'**
  String get onceNoCaption;

  /// No description provided for @captionHint.
  ///
  /// In ko, this message translates to:
  /// **'설명 넣기'**
  String get captionHint;

  /// No description provided for @checklist.
  ///
  /// In ko, this message translates to:
  /// **'체크리스트'**
  String get checklist;

  /// No description provided for @newChecklist.
  ///
  /// In ko, this message translates to:
  /// **'새 체크리스트'**
  String get newChecklist;

  /// No description provided for @checklistTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get checklistTitle;

  /// No description provided for @checklistTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 할까요?'**
  String get checklistTitleHint;

  /// No description provided for @checklistItems.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get checklistItems;

  /// No description provided for @checklistItemsInfo.
  ///
  /// In ko, this message translates to:
  /// **'{count}개까지 넣을 수 있어요.'**
  String checklistItemsInfo(int count);

  /// No description provided for @checklistItemHint.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get checklistItemHint;

  /// No description provided for @checklistAddItem.
  ///
  /// In ko, this message translates to:
  /// **'할 일 추가'**
  String get checklistAddItem;

  /// No description provided for @checklistOthersMark.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람도 체크할 수 있어요'**
  String get checklistOthersMark;

  /// No description provided for @checklistOthersAdd.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람도 할 일을 추가할 수 있어요'**
  String get checklistOthersAdd;

  /// No description provided for @checklistOthersInfo.
  ///
  /// In ko, this message translates to:
  /// **'체크리스트도 메시지처럼 암호화돼요. 허락하지 않은 사람이 체크하거나 추가하면 모든 휴대폰이 무시해요.'**
  String get checklistOthersInfo;

  /// No description provided for @checklistDone.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total} 완료'**
  String checklistDone(int done, int total);

  /// No description provided for @meetup.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get meetup;

  /// No description provided for @newMeetup.
  ///
  /// In ko, this message translates to:
  /// **'새 일정'**
  String get newMeetup;

  /// No description provided for @meetupTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 하나요?'**
  String get meetupTitleHint;

  /// No description provided for @meetupPlaceHint.
  ///
  /// In ko, this message translates to:
  /// **'장소 (선택)'**
  String get meetupPlaceHint;

  /// No description provided for @meetupWhen.
  ///
  /// In ko, this message translates to:
  /// **'언제'**
  String get meetupWhen;

  /// No description provided for @meetupInfo.
  ///
  /// In ko, this message translates to:
  /// **'일정과 참석 답도 메시지처럼 암호화돼요. 서버는 누가 오는지 몰라요.'**
  String get meetupInfo;

  /// No description provided for @meetupYes.
  ///
  /// In ko, this message translates to:
  /// **'갈게요'**
  String get meetupYes;

  /// No description provided for @meetupMaybe.
  ///
  /// In ko, this message translates to:
  /// **'아마도'**
  String get meetupMaybe;

  /// No description provided for @meetupNo.
  ///
  /// In ko, this message translates to:
  /// **'못 가요'**
  String get meetupNo;

  /// No description provided for @meetupCancel.
  ///
  /// In ko, this message translates to:
  /// **'일정 취소'**
  String get meetupCancel;

  /// No description provided for @meetupCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소된 일정이에요'**
  String get meetupCancelled;

  /// No description provided for @meetupPast.
  ///
  /// In ko, this message translates to:
  /// **'지난 일정이에요'**
  String get meetupPast;

  /// No description provided for @contactCard.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get contactCard;

  /// No description provided for @pickContact.
  ///
  /// In ko, this message translates to:
  /// **'연락처 보내기'**
  String get pickContact;

  /// No description provided for @noContacts.
  ///
  /// In ko, this message translates to:
  /// **'아직 연락처가 없어요'**
  String get noContacts;

  /// No description provided for @contactMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 보내기'**
  String get contactMessage;

  /// No description provided for @removeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자 해제'**
  String get removeAdmin;

  /// No description provided for @makeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자로 지정'**
  String get makeAdmin;

  /// No description provided for @removeSubscriber.
  ///
  /// In ko, this message translates to:
  /// **'구독자 내보내기'**
  String get removeSubscriber;

  /// No description provided for @removeMember.
  ///
  /// In ko, this message translates to:
  /// **'그룹에서 내보내기'**
  String get removeMember;

  /// No description provided for @subscribersCount.
  ///
  /// In ko, this message translates to:
  /// **'구독자 {count}명'**
  String subscribersCount(int count);

  /// No description provided for @subscribers.
  ///
  /// In ko, this message translates to:
  /// **'구독자'**
  String get subscribers;

  /// No description provided for @hideMembersOnInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버 목록이 관리자에게만 보여요.'**
  String get hideMembersOnInfo;

  /// No description provided for @subscribersHiddenInfo.
  ///
  /// In ko, this message translates to:
  /// **'구독자 목록은 관리자만 볼 수 있어요. 누가 구독하는지 다른 구독자는 몰라요.'**
  String get subscribersHiddenInfo;

  /// No description provided for @editGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 편집'**
  String get editGroup;

  /// No description provided for @editChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 편집'**
  String get editChannel;

  /// No description provided for @aboutHint.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get aboutHint;

  /// No description provided for @signPosts.
  ///
  /// In ko, this message translates to:
  /// **'서명 남기기'**
  String get signPosts;

  /// No description provided for @signPostsInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 글 위에 올린 관리자 이름이 보여요.'**
  String get signPostsInfo;

  /// No description provided for @hideMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 목록 숨기기'**
  String get hideMembers;

  /// No description provided for @hideMembersInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 관리자만 멤버 목록을 볼 수 있어요.'**
  String get hideMembersInfo;

  /// No description provided for @add.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get add;

  /// No description provided for @openLinkAsk.
  ///
  /// In ko, this message translates to:
  /// **'이 링크를 열까요?'**
  String get openLinkAsk;

  /// No description provided for @openLink.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get openLink;

  /// No description provided for @location.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get location;

  /// No description provided for @locationSend.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치 보내기'**
  String get locationSend;

  /// No description provided for @locationFinding.
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾고 있어요'**
  String get locationFinding;

  /// No description provided for @locationAccuracy.
  ///
  /// In ko, this message translates to:
  /// **'정확도 약 {meters}m'**
  String locationAccuracy(int meters);

  /// No description provided for @locationDenied.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한이 꺼져 있어요. 설정에서 부루미의 위치 접근을 허용해 주세요.'**
  String get locationDenied;

  /// No description provided for @locationOff.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰의 위치 서비스가 꺼져 있어요.'**
  String get locationOff;

  /// No description provided for @locationUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'지금은 위치를 알 수 없어요. 잠시 뒤 다시 해 주세요.'**
  String get locationUnavailable;

  /// No description provided for @locationRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 찾기'**
  String get locationRetry;

  /// No description provided for @openPhoneSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openPhoneSettings;

  /// No description provided for @locationOpenMap.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 보기'**
  String get locationOpenMap;

  /// No description provided for @locationPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'보낼 때 그 순간의 위치를 한 번만 읽어요. 위치는 암호화되어 대화 상대만 보고, 지도 회사에는 보내지 않아요.'**
  String get locationPrivacy;

  /// No description provided for @attachAllPhotos.
  ///
  /// In ko, this message translates to:
  /// **'모든 사진'**
  String get attachAllPhotos;

  /// No description provided for @photosDenied.
  ///
  /// In ko, this message translates to:
  /// **'사진 접근이 꺼져 있어요'**
  String get photosDenied;

  /// No description provided for @settingsProfileSub.
  ///
  /// In ko, this message translates to:
  /// **'{id} · 프로필, 사진, 이름'**
  String settingsProfileSub(String id);

  /// No description provided for @securityCheck.
  ///
  /// In ko, this message translates to:
  /// **'보안 점검 {done}/{total}'**
  String securityCheck(int done, int total);

  /// No description provided for @securityAllDone.
  ///
  /// In ko, this message translates to:
  /// **'모두 마쳤어요. 계정이 잘 지켜지고 있어요.'**
  String get securityAllDone;

  /// No description provided for @securityLeft.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 남았어요. 눌러서 마저 해 주세요.'**
  String securityLeft(int n);

  /// No description provided for @securityCheckTitle.
  ///
  /// In ko, this message translates to:
  /// **'보안 점검'**
  String get securityCheckTitle;

  /// No description provided for @securityCheckInfo.
  ///
  /// In ko, this message translates to:
  /// **'두 가지만 해 두면 폰을 잃어버리거나 바꿔도 대화를 지킬 수 있어요.'**
  String get securityCheckInfo;

  /// No description provided for @checkRecovery.
  ///
  /// In ko, this message translates to:
  /// **'대화 복구 키 만들기'**
  String get checkRecovery;

  /// No description provided for @checkRecoveryInfo.
  ///
  /// In ko, this message translates to:
  /// **'새 폰에서 이전 대화를 다시 열 때 써요. 키를 잃어버리면 아무도 되살릴 수 없어요.'**
  String get checkRecoveryInfo;

  /// No description provided for @checkDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 확인'**
  String get checkDevice;

  /// No description provided for @checkDeviceInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 기기가 내 것이라고 확인해 두면 친구들도 안심하고 대화할 수 있어요.'**
  String get checkDeviceInfo;

  /// No description provided for @checkDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get checkDone;

  /// No description provided for @checkTodo.
  ///
  /// In ko, this message translates to:
  /// **'해야 해요'**
  String get checkTodo;

  /// No description provided for @stateOn.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get stateOn;

  /// No description provided for @stateOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get stateOff;

  /// No description provided for @accountManage.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get accountManage;

  /// No description provided for @accountManageInfo.
  ///
  /// In ko, this message translates to:
  /// **'아이디, 비밀번호, 로그인한 기기와 암호화 키를 한곳에서 관리해요.'**
  String get accountManageInfo;

  /// No description provided for @faq.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get faq;

  /// No description provided for @feedbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'버그·제안 보내기'**
  String get feedbackTitle;

  /// No description provided for @feedbackHeader.
  ///
  /// In ko, this message translates to:
  /// **'고장 난 곳이나 바라는 기능을 알려 주세요. 운영팀이 직접 읽고, 고친 소식은 부루미 소식 채널에 올려요.'**
  String get feedbackHeader;

  /// No description provided for @feedbackBug.
  ///
  /// In ko, this message translates to:
  /// **'버그'**
  String get feedbackBug;

  /// No description provided for @feedbackIdea.
  ///
  /// In ko, this message translates to:
  /// **'제안'**
  String get feedbackIdea;

  /// No description provided for @feedbackWhat.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get feedbackWhat;

  /// No description provided for @feedbackSubject.
  ///
  /// In ko, this message translates to:
  /// **'한 줄 요약'**
  String get feedbackSubject;

  /// No description provided for @feedbackBodyBug.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 했더니 어떻게 됐나요?'**
  String get feedbackBodyBug;

  /// No description provided for @feedbackBodyIdea.
  ///
  /// In ko, this message translates to:
  /// **'어떤 기능이 있으면 좋을까요?'**
  String get feedbackBodyIdea;

  /// No description provided for @feedbackBugHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 사진을 보내려고 + 를 눌렀더니 화면이 하얘졌어요.'**
  String get feedbackBugHint;

  /// No description provided for @feedbackIdeaHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 채널 글을 예약해서 올리고 싶어요.'**
  String get feedbackIdeaHint;

  /// No description provided for @feedbackNeedWords.
  ///
  /// In ko, this message translates to:
  /// **'요약과 내용을 모두 적어 주세요.'**
  String get feedbackNeedWords;

  /// No description provided for @feedbackGoesTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 곳'**
  String get feedbackGoesTo;

  /// No description provided for @feedbackTeam.
  ///
  /// In ko, this message translates to:
  /// **'부루미 운영팀'**
  String get feedbackTeam;

  /// No description provided for @feedbackSentTitle.
  ///
  /// In ko, this message translates to:
  /// **'보냈어요'**
  String get feedbackSentTitle;

  /// No description provided for @feedbackSentBody.
  ///
  /// In ko, this message translates to:
  /// **'알려 줘서 고마워요. 고치면 부루미 소식 채널에 알려 드려요.'**
  String get feedbackSentBody;

  /// No description provided for @feedbackFailed.
  ///
  /// In ko, this message translates to:
  /// **'보내지 못했어요. 잠시 뒤 다시 해 주세요.'**
  String get feedbackFailed;

  /// No description provided for @feedbackMine.
  ///
  /// In ko, this message translates to:
  /// **'내가 보낸 의견'**
  String get feedbackMine;

  /// No description provided for @feedbackMineInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 목록은 이 폰에만 있어요.'**
  String get feedbackMineInfo;

  /// No description provided for @feedbackPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'함께 가는 것: 버그·제안, 적은 글, 기기 종류({device}), 앱 버전. 대화 내용·연락처·사진은 절대 붙지 않아요. 암호화된 1:1 메시지로 가요.'**
  String feedbackPrivacy(String device);

  /// No description provided for @feedbackAttachLog.
  ///
  /// In ko, this message translates to:
  /// **'오류 기록 붙이기 · {count}개'**
  String feedbackAttachLog(int count);

  /// No description provided for @feedbackDate.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일'**
  String feedbackDate(int month, int day);

  /// No description provided for @featureTour.
  ///
  /// In ko, this message translates to:
  /// **'부루미 기능 소개'**
  String get featureTour;

  /// No description provided for @featureTourInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미에서 할 수 있는 일을 한눈에 볼 수 있어요.'**
  String get featureTourInfo;

  /// No description provided for @aboutApp.
  ///
  /// In ko, this message translates to:
  /// **'소개'**
  String get aboutApp;

  /// No description provided for @appVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전 {version}'**
  String appVersion(String version);

  /// No description provided for @openSourceLicenses.
  ///
  /// In ko, this message translates to:
  /// **'오픈소스·출처'**
  String get openSourceLicenses;

  /// No description provided for @aboutInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미는 대화 내용을 아무도 볼 수 없는 메신저예요. 운영자도 서버도 내용을 볼 수 없어요.'**
  String get aboutInfo;

  /// No description provided for @powerMode.
  ///
  /// In ko, this message translates to:
  /// **'절전 모드'**
  String get powerMode;

  /// No description provided for @powerBelowValue.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 미만일 때'**
  String powerBelowValue(int pct);

  /// No description provided for @powerAlways.
  ///
  /// In ko, this message translates to:
  /// **'항상'**
  String get powerAlways;

  /// No description provided for @powerNever.
  ///
  /// In ko, this message translates to:
  /// **'끄기'**
  String get powerNever;

  /// No description provided for @powerModeInfo.
  ///
  /// In ko, this message translates to:
  /// **'배터리가 정한 값보다 적으면 움직이는 효과를 잠시 멈춰요. 웹에서는 배터리를 알 수 없어서 \'항상\'만 적용돼요.'**
  String get powerModeInfo;

  /// No description provided for @faqQ1.
  ///
  /// In ko, this message translates to:
  /// **'대화가 정말 안전한가요?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화와 그룹 대화는 모두 끝에서 끝까지 암호화돼요. 서버와 운영자는 내용을 볼 수 없어요.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 없이 가입할 수 있나요?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In ko, this message translates to:
  /// **'네. 아이디와 비밀번호만 있으면 돼요. 전화번호와 연락처는 쓰지 않아요.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In ko, this message translates to:
  /// **'폰을 바꾸면 대화가 사라지나요?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In ko, this message translates to:
  /// **'대화 복구 키를 만들어 두면 새 폰에서 이전 대화를 다시 열 수 있어요. 키는 나만 갖고 있어서, 잃어버리면 아무도 되살릴 수 없어요.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In ko, this message translates to:
  /// **'누가 나를 찾을 수 있나요?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In ko, this message translates to:
  /// **'내 아이디를 아는 사람만 찾을 수 있어요. 이름이나 전화번호로는 찾을 수 없어요.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 메시지는 어떻게 켜나요?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In ko, this message translates to:
  /// **'대화 위쪽의 타이머 버튼을 눌러 시간을 고르면, 그 뒤에 보낸 메시지가 정한 시간이 지나면 사라져요.'**
  String get faqA5;

  /// No description provided for @faqQ6.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울은 뭔가요?'**
  String get faqQ6;

  /// No description provided for @faqA6.
  ///
  /// In ko, this message translates to:
  /// **'한 번 열어 보면 사라지는 사진이에요. 홈 화면 위젯에는 내용 없이 방울만 보여요.'**
  String get faqA6;

  /// No description provided for @faqQ7.
  ///
  /// In ko, this message translates to:
  /// **'앱에 잠금을 걸 수 있나요?'**
  String get faqQ7;

  /// No description provided for @faqA7.
  ///
  /// In ko, this message translates to:
  /// **'설정 > 개인정보 및 보안에서 비밀번호를 정하면 앱을 열 때마다 물어봐요.'**
  String get faqA7;

  /// No description provided for @faqQ8.
  ///
  /// In ko, this message translates to:
  /// **'보낸 메시지를 고치거나 지울 수 있나요?'**
  String get faqQ8;

  /// No description provided for @faqA8.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 길게 누르면 고치거나 지울 수 있어요. 지운 메시지는 상대 화면에서도 사라져요.'**
  String get faqA8;

  /// No description provided for @tourE2e.
  ///
  /// In ko, this message translates to:
  /// **'끝에서 끝까지 암호화'**
  String get tourE2e;

  /// No description provided for @tourE2eBody.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화는 내 폰과 상대 폰에서만 열려요.'**
  String get tourE2eBody;

  /// No description provided for @tourTimer.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 메시지'**
  String get tourTimer;

  /// No description provided for @tourTimerBody.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간이 지나면 메시지가 저절로 지워져요.'**
  String get tourTimerBody;

  /// No description provided for @tourOnce.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기'**
  String get tourOnce;

  /// No description provided for @tourOnceBody.
  ///
  /// In ko, this message translates to:
  /// **'사진과 영상을 한 번만 열어 볼 수 있게 보내요.'**
  String get tourOnceBody;

  /// No description provided for @tourBubble.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울'**
  String get tourBubble;

  /// No description provided for @tourBubbleBody.
  ///
  /// In ko, this message translates to:
  /// **'친구에게 사진 방울을 띄워요. 열면 톡 터져요.'**
  String get tourBubbleBody;

  /// No description provided for @tourStreak.
  ///
  /// In ko, this message translates to:
  /// **'연속 대화'**
  String get tourStreak;

  /// No description provided for @tourStreakBody.
  ///
  /// In ko, this message translates to:
  /// **'친구와 매일 대화하면 🔥 숫자가 올라가요.'**
  String get tourStreakBody;

  /// No description provided for @tourGroups.
  ///
  /// In ko, this message translates to:
  /// **'그룹과 채널'**
  String get tourGroups;

  /// No description provided for @tourGroupsBody.
  ///
  /// In ko, this message translates to:
  /// **'친구끼리는 그룹, 많은 사람에게는 채널로 소식을 전해요.'**
  String get tourGroupsBody;

  /// No description provided for @tourTools.
  ///
  /// In ko, this message translates to:
  /// **'투표 · 체크리스트 · 모임'**
  String get tourTools;

  /// No description provided for @tourToolsBody.
  ///
  /// In ko, this message translates to:
  /// **'대화 안에서 바로 정하고, 할 일을 나누고, 약속을 잡아요.'**
  String get tourToolsBody;

  /// No description provided for @tourLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치 보내기'**
  String get tourLocation;

  /// No description provided for @tourLocationBody.
  ///
  /// In ko, this message translates to:
  /// **'지금 있는 곳을 보내요. 지도는 눌렀을 때만 열려요.'**
  String get tourLocationBody;

  /// No description provided for @myQr.
  ///
  /// In ko, this message translates to:
  /// **'내 QR 코드'**
  String get myQr;

  /// No description provided for @myQrInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구에게 보여 주면 내 아이디를 바로 알려 줄 수 있어요.'**
  String get myQrInfo;

  /// No description provided for @verifyThisDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 확인'**
  String get verifyThisDevice;

  /// No description provided for @verifiedDone.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료'**
  String get verifiedDone;

  /// No description provided for @verifyNeeded.
  ///
  /// In ko, this message translates to:
  /// **'확인 필요'**
  String get verifyNeeded;

  /// No description provided for @undoSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기 취소 (5초)'**
  String get undoSend;

  /// No description provided for @undoSendInfo.
  ///
  /// In ko, this message translates to:
  /// **'보낸 뒤 5초 동안은 실제로 전송되지 않아서 취소할 수 있어요.'**
  String get undoSendInfo;

  /// No description provided for @sendingIn.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤에 보내요'**
  String sendingIn(int n);

  /// No description provided for @veilAll.
  ///
  /// In ko, this message translates to:
  /// **'대화창 가리기'**
  String get veilAll;

  /// No description provided for @veilAllInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화방의 메시지가 가려져서 누르고 있는 동안만 보여요. 옆 사람이 볼 수 없어요. 이 기기에만 적용돼요.'**
  String get veilAllInfo;

  /// No description provided for @panic.
  ///
  /// In ko, this message translates to:
  /// **'패닉 동작'**
  String get panic;

  /// No description provided for @panicInfo.
  ///
  /// In ko, this message translates to:
  /// **'두 손가락으로 두 번 톡톡 치면 바로 잠겨요. 소리와 진동은 없어요. 앱 잠금이 켜져 있어야 해요.'**
  String get panicInfo;

  /// No description provided for @appearanceInfo.
  ///
  /// In ko, this message translates to:
  /// **'색 테마, 야간 모드, 글자 크기, 대화 배경처럼 부루미가 보이는 모습을 내 취향대로 바꿀 수 있어요.'**
  String get appearanceInfo;

  /// No description provided for @themePlain.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get themePlain;

  /// No description provided for @themeSecure.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get themeSecure;

  /// No description provided for @themeNature.
  ///
  /// In ko, this message translates to:
  /// **'자연'**
  String get themeNature;

  /// No description provided for @themeDaily.
  ///
  /// In ko, this message translates to:
  /// **'일상'**
  String get themeDaily;

  /// No description provided for @themeHiphop.
  ///
  /// In ko, this message translates to:
  /// **'힙합 밝게'**
  String get themeHiphop;

  /// No description provided for @themePhoto.
  ///
  /// In ko, this message translates to:
  /// **'내 사진'**
  String get themePhoto;

  /// No description provided for @myPhotoBackground.
  ///
  /// In ko, this message translates to:
  /// **'내 사진으로 배경 바꾸기'**
  String get myPhotoBackground;

  /// No description provided for @myColor.
  ///
  /// In ko, this message translates to:
  /// **'내 색상'**
  String get myColor;

  /// No description provided for @avatarShape.
  ///
  /// In ko, this message translates to:
  /// **'프로필 모양'**
  String get avatarShape;

  /// No description provided for @avatarShapePeople.
  ///
  /// In ko, this message translates to:
  /// **'개인'**
  String get avatarShapePeople;

  /// No description provided for @avatarShapeGroups.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get avatarShapeGroups;

  /// No description provided for @avatarShapeChannels.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get avatarShapeChannels;

  /// No description provided for @shapeCircle.
  ///
  /// In ko, this message translates to:
  /// **'동그라미'**
  String get shapeCircle;

  /// No description provided for @shapeRounded.
  ///
  /// In ko, this message translates to:
  /// **'둥근 사각'**
  String get shapeRounded;

  /// No description provided for @avatarShapeInfo.
  ///
  /// In ko, this message translates to:
  /// **'보는 모양만 바뀌어요. 사진은 그대로예요.'**
  String get avatarShapeInfo;

  /// No description provided for @tabEditFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 편집'**
  String get tabEditFolder;

  /// No description provided for @tabShowUnread.
  ///
  /// In ko, this message translates to:
  /// **'읽지 않은 대화 보기'**
  String get tabShowUnread;

  /// No description provided for @tabReorder.
  ///
  /// In ko, this message translates to:
  /// **'탭 재정렬'**
  String get tabReorder;

  /// No description provided for @glassEffect.
  ///
  /// In ko, this message translates to:
  /// **'유리 효과'**
  String get glassEffect;

  /// No description provided for @glassClear.
  ///
  /// In ko, this message translates to:
  /// **'맑게'**
  String get glassClear;

  /// No description provided for @glassNormal.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get glassNormal;

  /// No description provided for @glassSolid.
  ///
  /// In ko, this message translates to:
  /// **'불투명'**
  String get glassSolid;

  /// No description provided for @glassInfo.
  ///
  /// In ko, this message translates to:
  /// **'불투명을 고르면 비치는 유리 대신 깔끔한 판으로 보여요. 절전 모드에서도 이렇게 바뀌어요.'**
  String get glassInfo;

  /// No description provided for @autoNight.
  ///
  /// In ko, this message translates to:
  /// **'자동 야간 모드'**
  String get autoNight;

  /// No description provided for @autoNightOff.
  ///
  /// In ko, this message translates to:
  /// **'끔'**
  String get autoNightOff;

  /// No description provided for @autoNightSystem.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 설정 따르기'**
  String get autoNightSystem;

  /// No description provided for @roomThemeMine.
  ///
  /// In ko, this message translates to:
  /// **'내 설정'**
  String get roomThemeMine;

  /// No description provided for @autoNightRange.
  ///
  /// In ko, this message translates to:
  /// **'{from}~{to}'**
  String autoNightRange(String from, String to);

  /// No description provided for @autoNightInfo.
  ///
  /// In ko, this message translates to:
  /// **'‘휴대폰 설정 따르기’는 휴대폰이 어두운 화면일 때 같이 어두워져요. ‘시간 정하기’는 정한 시간 동안만 야간 모드가 켜져요.'**
  String get autoNightInfo;

  /// No description provided for @autoNightSchedule.
  ///
  /// In ko, this message translates to:
  /// **'시간 정하기'**
  String get autoNightSchedule;

  /// No description provided for @autoNightTimes.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get autoNightTimes;

  /// No description provided for @autoNightFrom.
  ///
  /// In ko, this message translates to:
  /// **'켜는 시간'**
  String get autoNightFrom;

  /// No description provided for @autoNightTo.
  ///
  /// In ko, this message translates to:
  /// **'끄는 시간'**
  String get autoNightTo;

  /// No description provided for @autoNightScheduleInfo.
  ///
  /// In ko, this message translates to:
  /// **'시간은 이 휴대폰에만 저장돼요. 해 지는 시간에 맞추려면 위치가 필요해서 넣지 않았어요.'**
  String get autoNightScheduleInfo;

  /// No description provided for @timerYears.
  ///
  /// In ko, this message translates to:
  /// **'{n}년'**
  String timerYears(int n);

  /// No description provided for @timerMonths.
  ///
  /// In ko, this message translates to:
  /// **'{n}달'**
  String timerMonths(int n);

  /// No description provided for @timerWeeks.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String timerWeeks(int n);

  /// No description provided for @timerDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String timerDays(int n);

  /// No description provided for @timerHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간'**
  String timerHours(int n);

  /// No description provided for @timerMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String timerMinutes(int n);

  /// No description provided for @timerOther.
  ///
  /// In ko, this message translates to:
  /// **'다른 시간'**
  String get timerOther;

  /// No description provided for @timerUnitHours.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String timerUnitHours(int n);

  /// No description provided for @timerUnitDays.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String timerUnitDays(int n);

  /// No description provided for @timerUnitWeeks.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String timerUnitWeeks(int n);

  /// No description provided for @timerUnitMonths.
  ///
  /// In ko, this message translates to:
  /// **'달'**
  String timerUnitMonths(int n);

  /// No description provided for @timerUnitYears.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String timerUnitYears(int n);

  /// No description provided for @defaultTimerHeader.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간이 지나면 메시지가 양쪽 휴대폰에서 지워져요. 1시간부터 1년까지 고를 수 있어요.'**
  String get defaultTimerHeader;

  /// No description provided for @defaultTimerNew.
  ///
  /// In ko, this message translates to:
  /// **'새 대화'**
  String get defaultTimerNew;

  /// No description provided for @timerApply.
  ///
  /// In ko, this message translates to:
  /// **'기존 대화에 적용'**
  String get timerApply;

  /// No description provided for @timerApplyInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 대화 모두에 같은 시간이 바로 적용돼요. 대화방 안에도 ‘자동 삭제를 바꿨어요’가 보여요.'**
  String get timerApplyInfo;

  /// No description provided for @timerApplyGo.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get timerApplyGo;

  /// No description provided for @timerApplyGoN.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 적용'**
  String timerApplyGoN(int n);

  /// No description provided for @timerApplyTime.
  ///
  /// In ko, this message translates to:
  /// **'적용할 시간'**
  String get timerApplyTime;

  /// No description provided for @timerApplyPick.
  ///
  /// In ko, this message translates to:
  /// **'대화 고르기'**
  String get timerApplyPick;

  /// No description provided for @timerSelectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 고르기'**
  String get timerSelectAll;

  /// No description provided for @timerDeselectAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 풀기'**
  String get timerDeselectAll;

  /// No description provided for @timerApplied.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개에 자동 삭제 {time} 켰어요'**
  String timerApplied(int n, String time);

  /// No description provided for @timerAppliedOff.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개에서 자동 삭제를 껐어요'**
  String timerAppliedOff(int n);

  /// No description provided for @qrTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get qrTheme;

  /// No description provided for @qrShort.
  ///
  /// In ko, this message translates to:
  /// **'5분짜리 QR'**
  String get qrShort;

  /// No description provided for @qrShortFooter.
  ///
  /// In ko, this message translates to:
  /// **'켜면 QR이 5분 뒤 쓸 수 없게 바뀌고, 아이디도 카드에 적지 않아요. 사진으로 찍혀 퍼져도 나중엔 못 써요.'**
  String get qrShortFooter;

  /// No description provided for @qrShortInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 QR은 5분 동안만 쓸 수 있어요.'**
  String get qrShortInfo;

  /// No description provided for @qrShortOver.
  ///
  /// In ko, this message translates to:
  /// **'시간이 지났어요'**
  String get qrShortOver;

  /// No description provided for @qrShortAgain.
  ///
  /// In ko, this message translates to:
  /// **'새 QR 만들기'**
  String get qrShortAgain;

  /// No description provided for @roomThemeBoth.
  ///
  /// In ko, this message translates to:
  /// **'상대방 화면에도 적용'**
  String get roomThemeBoth;

  /// No description provided for @roomThemeBothInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 고른 배경이 상대방 휴대폰에도 바로 바뀌어요. 어떤 배경인지는 암호화돼서 서버도 몰라요. 내 사진 배경은 내 휴대폰에만 있어요.'**
  String get roomThemeBothInfo;

  /// No description provided for @roomThemeByOther.
  ///
  /// In ko, this message translates to:
  /// **'지금 배경은 상대방이 골랐어요. 다시 고르면 내 선택으로 바뀌어요.'**
  String get roomThemeByOther;

  /// No description provided for @roomThemeSent.
  ///
  /// In ko, this message translates to:
  /// **'상대방 화면에도 바꿨어요'**
  String get roomThemeSent;

  /// No description provided for @roomThemeSample1.
  ///
  /// In ko, this message translates to:
  /// **'오늘 몇 시에 만나요?'**
  String get roomThemeSample1;

  /// No description provided for @roomThemeSample2.
  ///
  /// In ko, this message translates to:
  /// **'7시 좋아요 🙂'**
  String get roomThemeSample2;

  /// No description provided for @textSizeDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get textSizeDefault;

  /// No description provided for @textSizePreview.
  ///
  /// In ko, this message translates to:
  /// **'어제 회의에서 왼쪽 길로 가자고 했나, 오른쪽 길로 가자고 했나?'**
  String get textSizePreview;

  /// No description provided for @textSizePreviewReply.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽이요. 확실해요.'**
  String get textSizePreviewReply;

  /// No description provided for @notificationsInfo.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지 알림을 어떻게 받을지 정해요. 앱을 쓰는 중의 알림, 집중 일정도 여기서 바꿔요.'**
  String get notificationsInfo;

  /// No description provided for @inAppNotices.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 알림'**
  String get inAppNotices;

  /// No description provided for @inAppStyle.
  ///
  /// In ko, this message translates to:
  /// **'알림 스타일'**
  String get inAppStyle;

  /// No description provided for @inAppSilent.
  ///
  /// In ko, this message translates to:
  /// **'무음'**
  String get inAppSilent;

  /// No description provided for @inAppBanner.
  ///
  /// In ko, this message translates to:
  /// **'배너'**
  String get inAppBanner;

  /// No description provided for @inAppStyleInfo.
  ///
  /// In ko, this message translates to:
  /// **'배너는 화면 위에 잠깐 나타났다가 사라져요. 무음이면 앱을 쓰는 동안 아무것도 뜨지 않아요.'**
  String get inAppStyleInfo;

  /// No description provided for @inAppSound.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 소리'**
  String get inAppSound;

  /// No description provided for @inAppPreview.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 미리보기'**
  String get inAppPreview;

  /// No description provided for @focusSchedule.
  ///
  /// In ko, this message translates to:
  /// **'집중 일정'**
  String get focusSchedule;

  /// No description provided for @focusInfo.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간에는 알림이 오지 않아요. 메시지는 그대로 받고, 모두 이 휴대폰 안에서 처리해요.'**
  String get focusInfo;

  /// No description provided for @focusFrom.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get focusFrom;

  /// No description provided for @focusTo.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get focusTo;

  /// No description provided for @focusDays.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get focusDays;

  /// No description provided for @focusEveryDay.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get focusEveryDay;

  /// No description provided for @showNotices.
  ///
  /// In ko, this message translates to:
  /// **'알림 표시'**
  String get showNotices;

  /// No description provided for @messagePreview.
  ///
  /// In ko, this message translates to:
  /// **'메시지 미리보기'**
  String get messagePreview;

  /// No description provided for @messagePreviewInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 알림에 \'새 메시지\'만 보여요.'**
  String get messagePreviewInfo;

  /// No description provided for @sound.
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get sound;

  /// No description provided for @soundNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get soundNone;

  /// No description provided for @sound_nuri.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get sound_nuri;

  /// No description provided for @sound_pop.
  ///
  /// In ko, this message translates to:
  /// **'톡'**
  String get sound_pop;

  /// No description provided for @sound_drop.
  ///
  /// In ko, this message translates to:
  /// **'물방울'**
  String get sound_drop;

  /// No description provided for @sound_bell.
  ///
  /// In ko, this message translates to:
  /// **'종'**
  String get sound_bell;

  /// No description provided for @sound_chord.
  ///
  /// In ko, this message translates to:
  /// **'화음'**
  String get sound_chord;

  /// No description provided for @sound_breeze.
  ///
  /// In ko, this message translates to:
  /// **'바람'**
  String get sound_breeze;

  /// No description provided for @sound_knock.
  ///
  /// In ko, this message translates to:
  /// **'똑똑'**
  String get sound_knock;

  /// No description provided for @sound_twinkle.
  ///
  /// In ko, this message translates to:
  /// **'반짝'**
  String get sound_twinkle;

  /// No description provided for @soundInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미가 직접 만든 소리예요. 누르면 미리 들어 볼 수 있어요.'**
  String get soundInfo;

  /// No description provided for @noticeExceptions.
  ///
  /// In ko, this message translates to:
  /// **'예외'**
  String get noticeExceptions;

  /// No description provided for @addException.
  ///
  /// In ko, this message translates to:
  /// **'예외 추가'**
  String get addException;

  /// No description provided for @exceptionsInfo.
  ///
  /// In ko, this message translates to:
  /// **'여기 넣은 대화는 위 설정보다 먼저 적용돼요.'**
  String get exceptionsInfo;

  /// No description provided for @noticeOnHere.
  ///
  /// In ko, this message translates to:
  /// **'알림 켬'**
  String get noticeOnHere;

  /// No description provided for @noticeOffHere.
  ///
  /// In ko, this message translates to:
  /// **'알림 끔'**
  String get noticeOffHere;

  /// No description provided for @removeException.
  ///
  /// In ko, this message translates to:
  /// **'예외에서 빼기'**
  String get removeException;

  /// No description provided for @pickChat.
  ///
  /// In ko, this message translates to:
  /// **'대화 고르기'**
  String get pickChat;

  /// No description provided for @alwaysAllow.
  ///
  /// In ko, this message translates to:
  /// **'항상 허용'**
  String get alwaysAllow;

  /// No description provided for @alwaysDeny.
  ///
  /// In ko, this message translates to:
  /// **'항상 거부'**
  String get alwaysDeny;

  /// No description provided for @addUsers.
  ///
  /// In ko, this message translates to:
  /// **'사용자 추가'**
  String get addUsers;

  /// No description provided for @peopleCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}명'**
  String peopleCount(int n);

  /// No description provided for @whoExceptionsInfo.
  ///
  /// In ko, this message translates to:
  /// **'사람을 예외로 넣으면 위 설정보다 먼저 적용돼요. 모두 이 휴대폰에서 지켜요.'**
  String get whoExceptionsInfo;

  /// No description provided for @bigEmoji.
  ///
  /// In ko, this message translates to:
  /// **'큰 이모지'**
  String get bigEmoji;

  /// No description provided for @fxAdd.
  ///
  /// In ko, this message translates to:
  /// **'효과 넣기'**
  String get fxAdd;

  /// No description provided for @fxMore.
  ///
  /// In ko, this message translates to:
  /// **'효과 더 보기'**
  String get fxMore;

  /// No description provided for @fxSearch.
  ///
  /// In ko, this message translates to:
  /// **'효과 찾기'**
  String get fxSearch;

  /// No description provided for @fxNothing.
  ///
  /// In ko, this message translates to:
  /// **'맞는 효과가 없어요'**
  String get fxNothing;

  /// No description provided for @fxReplay.
  ///
  /// In ko, this message translates to:
  /// **'효과 다시 보기'**
  String get fxReplay;

  /// No description provided for @fxSendWith.
  ///
  /// In ko, this message translates to:
  /// **'{name} 효과로 보내기'**
  String fxSendWith(String name);

  /// No description provided for @fxQuietWith.
  ///
  /// In ko, this message translates to:
  /// **'{name} 효과로 조용히 보내기'**
  String fxQuietWith(String name);

  /// No description provided for @diceBull.
  ///
  /// In ko, this message translates to:
  /// **'한가운데!'**
  String get diceBull;

  /// No description provided for @diceMissed.
  ///
  /// In ko, this message translates to:
  /// **'빗나갔어요'**
  String get diceMissed;

  /// No description provided for @diceScore.
  ///
  /// In ko, this message translates to:
  /// **'{n}점'**
  String diceScore(int n);

  /// No description provided for @diceGoal.
  ///
  /// In ko, this message translates to:
  /// **'골인!'**
  String get diceGoal;

  /// No description provided for @diceAlmost.
  ///
  /// In ko, this message translates to:
  /// **'아깝다'**
  String get diceAlmost;

  /// No description provided for @diceStrike.
  ///
  /// In ko, this message translates to:
  /// **'스트라이크!'**
  String get diceStrike;

  /// No description provided for @dicePins.
  ///
  /// In ko, this message translates to:
  /// **'핀 {n}개'**
  String dicePins(int n);

  /// No description provided for @diceJackpot.
  ///
  /// In ko, this message translates to:
  /// **'잭팟!'**
  String get diceJackpot;

  /// No description provided for @diceTry.
  ///
  /// In ko, this message translates to:
  /// **'{emoji} 하나만 보내면 나도 해 볼 수 있어요'**
  String diceTry(String emoji);

  /// No description provided for @diceTrySend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get diceTrySend;

  /// No description provided for @cxStill.
  ///
  /// In ko, this message translates to:
  /// **'가만히'**
  String get cxStill;

  /// No description provided for @cxBounce.
  ///
  /// In ko, this message translates to:
  /// **'통통'**
  String get cxBounce;

  /// No description provided for @cxSpin.
  ///
  /// In ko, this message translates to:
  /// **'빙글'**
  String get cxSpin;

  /// No description provided for @cxWiggle.
  ///
  /// In ko, this message translates to:
  /// **'흔들'**
  String get cxWiggle;

  /// No description provided for @cxBeat.
  ///
  /// In ko, this message translates to:
  /// **'두근'**
  String get cxBeat;

  /// No description provided for @cxFloat.
  ///
  /// In ko, this message translates to:
  /// **'둥실'**
  String get cxFloat;

  /// No description provided for @cxJelly.
  ///
  /// In ko, this message translates to:
  /// **'말랑'**
  String get cxJelly;

  /// No description provided for @cxSparkle.
  ///
  /// In ko, this message translates to:
  /// **'반짝'**
  String get cxSparkle;

  /// No description provided for @cxMakeTitle.
  ///
  /// In ko, this message translates to:
  /// **'이모지 만들기'**
  String get cxMakeTitle;

  /// No description provided for @cxWordsHint.
  ///
  /// In ko, this message translates to:
  /// **'글자를 쓰면 바로 이모지가 돼요'**
  String get cxWordsHint;

  /// No description provided for @cxPhotoHint.
  ///
  /// In ko, this message translates to:
  /// **'사진을 고르면 이모지로 만들어요'**
  String get cxPhotoHint;

  /// No description provided for @cxSample.
  ///
  /// In ko, this message translates to:
  /// **'오늘 최고'**
  String get cxSample;

  /// No description provided for @cxFromPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진으로'**
  String get cxFromPhoto;

  /// No description provided for @cxFromWords.
  ///
  /// In ko, this message translates to:
  /// **'글자로'**
  String get cxFromWords;

  /// No description provided for @cxWordsPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'1~4글자 (예: 굿, ㅋㅋ, 최고)'**
  String get cxWordsPlaceholder;

  /// No description provided for @cxMotionTitle.
  ///
  /// In ko, this message translates to:
  /// **'움직임'**
  String get cxMotionTitle;

  /// No description provided for @cxBaseTitle.
  ///
  /// In ko, this message translates to:
  /// **'대신 보일 이모지'**
  String get cxBaseTitle;

  /// No description provided for @cxBaseInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록이나 알림처럼 그림을 못 그리는 곳에서는 이 이모지가 보여요.'**
  String get cxBaseInfo;

  /// No description provided for @cxGroupSection.
  ///
  /// In ko, this message translates to:
  /// **'{name} 이모지'**
  String cxGroupSection(String name);

  /// No description provided for @cxMineSection.
  ///
  /// In ko, this message translates to:
  /// **'내 이모지'**
  String get cxMineSection;

  /// No description provided for @cxIsMine.
  ///
  /// In ko, this message translates to:
  /// **'내 이모지에 있어요'**
  String get cxIsMine;

  /// No description provided for @cxSaveInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 이모지에 저장하면 어느 대화에서나 쓸 수 있어요'**
  String get cxSaveInfo;

  /// No description provided for @cxSave.
  ///
  /// In ko, this message translates to:
  /// **'내 이모지에 저장'**
  String get cxSave;

  /// No description provided for @cxRemove.
  ///
  /// In ko, this message translates to:
  /// **'내 이모지에서 빼기'**
  String get cxRemove;

  /// No description provided for @cxGroupTitle.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이모지'**
  String get cxGroupTitle;

  /// No description provided for @cxGroupAdminInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 이모지는 이 그룹 모든 사람의 이모지 칸 맨 위에 보여요. 그림은 암호화돼서 서버는 볼 수 없어요.'**
  String get cxGroupAdminInfo;

  /// No description provided for @cxGroupInfo.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 고른 이 그룹의 이모지예요. 눌러서 내 이모지에 저장할 수 있어요.'**
  String get cxGroupInfo;

  /// No description provided for @cxGroupEmptyAdmin.
  ///
  /// In ko, this message translates to:
  /// **'먼저 이모지를 만들어 주세요. 만든 이모지 중에서 골라요.'**
  String get cxGroupEmptyAdmin;

  /// No description provided for @cxGroupEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 그룹 이모지가 없어요'**
  String get cxGroupEmpty;

  /// No description provided for @cxGroupCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}/{max}개 골랐어요'**
  String cxGroupCount(int n, int max);

  /// No description provided for @cxSaveAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 내 이모지에 저장'**
  String get cxSaveAll;

  /// No description provided for @cxAllSaved.
  ///
  /// In ko, this message translates to:
  /// **'모두 저장했어요'**
  String get cxAllSaved;

  /// No description provided for @gifSave.
  ///
  /// In ko, this message translates to:
  /// **'GIF 저장'**
  String get gifSave;

  /// No description provided for @gifSaved.
  ///
  /// In ko, this message translates to:
  /// **'내 GIF에 저장했어요'**
  String get gifSaved;

  /// No description provided for @gifMine.
  ///
  /// In ko, this message translates to:
  /// **'내 GIF'**
  String get gifMine;

  /// No description provided for @gifEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장한 GIF가 없어요.\n대화에서 GIF를 꾹 누르고 \'GIF 저장\'을 눌러 보세요.'**
  String get gifEmpty;

  /// No description provided for @gifWithCaption.
  ///
  /// In ko, this message translates to:
  /// **'설명 붙여 보내기'**
  String get gifWithCaption;

  /// No description provided for @gifEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집해서 보내기'**
  String get gifEdit;

  /// No description provided for @gifRemove.
  ///
  /// In ko, this message translates to:
  /// **'내 GIF에서 빼기'**
  String get gifRemove;

  /// No description provided for @gifRemoveIn.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤 내 GIF에서 빠져요'**
  String gifRemoveIn(int n);

  /// No description provided for @gifCaptionHint.
  ///
  /// In ko, this message translates to:
  /// **'설명 추가…'**
  String get gifCaptionHint;

  /// No description provided for @gifTrim.
  ///
  /// In ko, this message translates to:
  /// **'자르기'**
  String get gifTrim;

  /// No description provided for @bigEmojiInfo.
  ///
  /// In ko, this message translates to:
  /// **'이모지 1~3개만 보내면 말풍선 없이 크게 보여요.'**
  String get bigEmojiInfo;

  /// No description provided for @burumyStickers.
  ///
  /// In ko, this message translates to:
  /// **'부루미 스티커'**
  String get burumyStickers;

  /// No description provided for @stickerCount.
  ///
  /// In ko, this message translates to:
  /// **'스티커 {n}개'**
  String stickerCount(int n);

  /// No description provided for @stickerPacksInfo.
  ///
  /// In ko, this message translates to:
  /// **'끈 캐릭터는 스티커 칸에서 빠져요. 받은 스티커는 그대로 보여요.'**
  String get stickerPacksInfo;

  /// No description provided for @clearRecentStickers.
  ///
  /// In ko, this message translates to:
  /// **'최근 스티커 지우기'**
  String get clearRecentStickers;

  /// No description provided for @pack_buru.
  ///
  /// In ko, this message translates to:
  /// **'부루'**
  String get pack_buru;

  /// No description provided for @pack_dugi.
  ///
  /// In ko, this message translates to:
  /// **'두기'**
  String get pack_dugi;

  /// No description provided for @pack_rumi.
  ///
  /// In ko, this message translates to:
  /// **'루미'**
  String get pack_rumi;

  /// No description provided for @pack_mongi.
  ///
  /// In ko, this message translates to:
  /// **'몽지'**
  String get pack_mongi;

  /// No description provided for @pack_duru.
  ///
  /// In ko, this message translates to:
  /// **'두루'**
  String get pack_duru;

  /// No description provided for @pack_burumi.
  ///
  /// In ko, this message translates to:
  /// **'부루와 미'**
  String get pack_burumi;

  /// No description provided for @dataInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미가 쓰는 저장 공간과 사진·영상을 언제 받을지 정해요.'**
  String get dataInfo;

  /// No description provided for @storageUsage.
  ///
  /// In ko, this message translates to:
  /// **'저장 공간 사용량'**
  String get storageUsage;

  /// No description provided for @storageApp.
  ///
  /// In ko, this message translates to:
  /// **'대화와 설정'**
  String get storageApp;

  /// No description provided for @storageCache.
  ///
  /// In ko, this message translates to:
  /// **'임시 파일'**
  String get storageCache;

  /// No description provided for @clearCache.
  ///
  /// In ko, this message translates to:
  /// **'임시 파일 지우기'**
  String get clearCache;

  /// No description provided for @storageInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화는 지워지지 않아요. 임시 파일은 다시 열 때 새로 받아요.'**
  String get storageInfo;

  /// No description provided for @storageWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹에서는 브라우저가 저장 공간을 관리해요.'**
  String get storageWeb;

  /// No description provided for @autoDownload.
  ///
  /// In ko, this message translates to:
  /// **'미디어 자동 다운로드'**
  String get autoDownload;

  /// No description provided for @autoDlCell.
  ///
  /// In ko, this message translates to:
  /// **'셀룰러 데이터 사용 시'**
  String get autoDlCell;

  /// No description provided for @autoDlWifi.
  ///
  /// In ko, this message translates to:
  /// **'Wi-Fi 사용 시'**
  String get autoDlWifi;

  /// No description provided for @autoDownloadInfo.
  ///
  /// In ko, this message translates to:
  /// **'미리 받지 않는 사진·동영상·파일은 누를 때 받아요. 절전 모드에서는 늘 누를 때 받아요.'**
  String get autoDownloadInfo;

  /// No description provided for @autoplayGif.
  ///
  /// In ko, this message translates to:
  /// **'GIF 자동 재생'**
  String get autoplayGif;

  /// No description provided for @autoplayGifInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 GIF가 첫 장면에 멈춰 있어요.'**
  String get autoplayGifInfo;

  /// No description provided for @powerJobs.
  ///
  /// In ko, this message translates to:
  /// **'배터리를 많이 쓰는 기능'**
  String get powerJobs;

  /// No description provided for @powerJobsInfo.
  ///
  /// In ko, this message translates to:
  /// **'절전 모드가 켜지면 이 기능들이 잠시 꺼져요. 배터리가 충분하면 다시 켜져요.'**
  String get powerJobsInfo;

  /// No description provided for @sizeBytes.
  ///
  /// In ko, this message translates to:
  /// **'{n} B'**
  String sizeBytes(int n);

  /// No description provided for @chatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'메시지 보내는 방법, 답장, 빠른 답장 문구, 자리 비움 답장, 휴대폰 안에서만 도는 AI 기능을 정해요.'**
  String get chatsInfo;

  /// No description provided for @aiFeatures.
  ///
  /// In ko, this message translates to:
  /// **'AI 기능'**
  String get aiFeatures;

  /// No description provided for @scamWarning.
  ///
  /// In ko, this message translates to:
  /// **'사기·피싱 링크 경고'**
  String get scamWarning;

  /// No description provided for @scamWarningInfo.
  ///
  /// In ko, this message translates to:
  /// **'이상한 링크(가짜 주소, 숫자 주소, 줄인 주소)에 경고를 붙여요. 이 휴대폰 안에서만 확인하고, 메시지 내용은 어디로도 보내지 않아요.'**
  String get scamWarningInfo;

  /// No description provided for @scamLink.
  ///
  /// In ko, this message translates to:
  /// **'주의: 의심스러운 링크예요'**
  String get scamLink;

  /// No description provided for @quickReplies.
  ///
  /// In ko, this message translates to:
  /// **'빠른 답장 문구'**
  String get quickReplies;

  /// No description provided for @quickRepliesInfo.
  ///
  /// In ko, this message translates to:
  /// **'입력창의 문구 버튼을 누르면 고를 수 있어요. 최대 20개.'**
  String get quickRepliesInfo;

  /// No description provided for @addQuickReply.
  ///
  /// In ko, this message translates to:
  /// **'문구 추가'**
  String get addQuickReply;

  /// No description provided for @quickReplyHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 지금 회의 중이라 이따 연락할게요'**
  String get quickReplyHint;

  /// No description provided for @awayReply.
  ///
  /// In ko, this message translates to:
  /// **'자리 비움 답장'**
  String get awayReply;

  /// No description provided for @awayReplyInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜 두면 1:1 대화에 새 메시지가 오면 이 문구로 한 번 답해요. 같은 사람에게는 6시간에 한 번만 보내요. 앱이 받을 때 이 휴대폰이 보내요.'**
  String get awayReplyInfo;

  /// No description provided for @awayReplyText.
  ///
  /// In ko, this message translates to:
  /// **'답장 문구'**
  String get awayReplyText;

  /// No description provided for @awayReplyDefault.
  ///
  /// In ko, this message translates to:
  /// **'지금은 자리에 없어요. 확인하면 답할게요.'**
  String get awayReplyDefault;

  /// No description provided for @awayTag.
  ///
  /// In ko, this message translates to:
  /// **'자동 답장'**
  String get awayTag;

  /// No description provided for @editProfile.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get editProfile;

  /// No description provided for @firstName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ko, this message translates to:
  /// **'성 (선택)'**
  String get lastName;

  /// No description provided for @nameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름을 쓰고 사진을 넣으면 친구가 나를 알아보기 쉬워요.'**
  String get nameHint;

  /// No description provided for @newPhoto.
  ///
  /// In ko, this message translates to:
  /// **'새 사진 설정'**
  String get newPhoto;

  /// No description provided for @removePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 지우기'**
  String get removePhoto;

  /// No description provided for @idInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구가 이 아이디로 나를 찾을 수 있어요. 누르면 복사돼요.'**
  String get idInfo;

  /// No description provided for @themeHiphopWhite.
  ///
  /// In ko, this message translates to:
  /// **'힙합 흰색'**
  String get themeHiphopWhite;

  /// No description provided for @themeHiphopDark.
  ///
  /// In ko, this message translates to:
  /// **'힙합 어둡게'**
  String get themeHiphopDark;

  /// No description provided for @manageTools.
  ///
  /// In ko, this message translates to:
  /// **'운영 도구'**
  String get manageTools;

  /// No description provided for @manageToolsInfo.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 보는 화면이에요. 대화 내용은 서버로 보내지 않고 이 휴대폰에서 처리해요.'**
  String get manageToolsInfo;

  /// No description provided for @toolsJoin.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get toolsJoin;

  /// No description provided for @toolsPosts.
  ///
  /// In ko, this message translates to:
  /// **'글 관리'**
  String get toolsPosts;

  /// No description provided for @toolsStats.
  ///
  /// In ko, this message translates to:
  /// **'기록과 통계'**
  String get toolsStats;

  /// No description provided for @roomRules.
  ///
  /// In ko, this message translates to:
  /// **'모임 규칙'**
  String get roomRules;

  /// No description provided for @roomRulesHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 1. 서로 존중해요\n2. 광고 금지\n3. 사진은 출처를 밝혀요'**
  String get roomRulesHint;

  /// No description provided for @roomRulesInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버라면 누구나 볼 수 있어요.'**
  String get roomRulesInfo;

  /// No description provided for @rulesAgree.
  ///
  /// In ko, this message translates to:
  /// **'규칙 동의 받기'**
  String get rulesAgree;

  /// No description provided for @rulesAgreeInfo.
  ///
  /// In ko, this message translates to:
  /// **'새로 들어온 사람은 규칙에 동의해야 글을 쓸 수 있어요.'**
  String get rulesAgreeInfo;

  /// No description provided for @agreeRules.
  ///
  /// In ko, this message translates to:
  /// **'규칙을 지킬게요'**
  String get agreeRules;

  /// No description provided for @welcomeMessage.
  ///
  /// In ko, this message translates to:
  /// **'환영 인사'**
  String get welcomeMessage;

  /// No description provided for @welcomeHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 반가워요! 공지부터 한번 봐 주세요 😊'**
  String get welcomeHint;

  /// No description provided for @welcomeInfo.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버가 들어왔을 때 그 사람에게만 한 번 보여요.'**
  String get welcomeInfo;

  /// No description provided for @reactionsSetting.
  ///
  /// In ko, this message translates to:
  /// **'반응'**
  String get reactionsSetting;

  /// No description provided for @reactionsAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 반응'**
  String get reactionsAll;

  /// No description provided for @reactionsSome.
  ///
  /// In ko, this message translates to:
  /// **'일부 반응'**
  String get reactionsSome;

  /// No description provided for @reactionsNone.
  ///
  /// In ko, this message translates to:
  /// **'반응 없음'**
  String get reactionsNone;

  /// No description provided for @reactionsInfo.
  ///
  /// In ko, this message translates to:
  /// **'구독자가 어떤 이모지로 반응할 수 있는지 정해요.'**
  String get reactionsInfo;

  /// No description provided for @reactionsMax.
  ///
  /// In ko, this message translates to:
  /// **'글마다 최대 반응 수'**
  String get reactionsMax;

  /// No description provided for @reactionsMaxInfo.
  ///
  /// In ko, this message translates to:
  /// **'한 메시지에 붙을 수 있는 반응 종류의 수예요.'**
  String get reactionsMaxInfo;

  /// No description provided for @reactionsPick.
  ///
  /// In ko, this message translates to:
  /// **'쓸 수 있는 반응'**
  String get reactionsPick;

  /// No description provided for @reactionsPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get reactionsPreview;

  /// No description provided for @reactionsPreviewPost.
  ///
  /// In ko, this message translates to:
  /// **'오늘 저녁 8시에 새 소식을 올려요 🎉'**
  String get reactionsPreviewPost;

  /// No description provided for @reactionsNoneInfo.
  ///
  /// In ko, this message translates to:
  /// **'아무도 반응을 달 수 없어요. 서버도 새 반응을 받지 않아요.'**
  String get reactionsNoneInfo;

  /// No description provided for @reactionHiddenMine.
  ///
  /// In ko, this message translates to:
  /// **'방 규칙으로 숨겨진 내 반응이에요. 누르면 거둬요.'**
  String get reactionHiddenMine;

  /// No description provided for @hideCounts.
  ///
  /// In ko, this message translates to:
  /// **'반응·투표 숫자 숨기기'**
  String get hideCounts;

  /// No description provided for @hideCountsInfo.
  ///
  /// In ko, this message translates to:
  /// **'구독자에게는 숫자가 안 보여요. 관리자는 계속 볼 수 있어요.'**
  String get hideCountsInfo;

  /// No description provided for @autoMod.
  ///
  /// In ko, this message translates to:
  /// **'자동 관리'**
  String get autoMod;

  /// No description provided for @autoModInfo.
  ///
  /// In ko, this message translates to:
  /// **'관리자 휴대폰이 규칙에 맞지 않는 글을 지워요. 서버는 대화 내용을 볼 수 없어서, 관리자 앱이 꺼져 있으면 조금 늦게 처리돼요.'**
  String get autoModInfo;

  /// No description provided for @bannedWords.
  ///
  /// In ko, this message translates to:
  /// **'금지어'**
  String get bannedWords;

  /// No description provided for @addBannedWord.
  ///
  /// In ko, this message translates to:
  /// **'금지어 추가'**
  String get addBannedWord;

  /// No description provided for @bannedWordsInfo.
  ///
  /// In ko, this message translates to:
  /// **'금지어가 들어간 메시지를 지워요. 금지어 목록은 이 휴대폰에만 있어요.'**
  String get bannedWordsInfo;

  /// No description provided for @modRules.
  ///
  /// In ko, this message translates to:
  /// **'규칙'**
  String get modRules;

  /// No description provided for @modNewLinks.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버 링크 막기'**
  String get modNewLinks;

  /// No description provided for @modNewLinksInfo.
  ///
  /// In ko, this message translates to:
  /// **'처음 본 지 24시간이 안 된 사람의 링크'**
  String get modNewLinksInfo;

  /// No description provided for @modFlood.
  ///
  /// In ko, this message translates to:
  /// **'도배 지우기'**
  String get modFlood;

  /// No description provided for @modFloodInfo.
  ///
  /// In ko, this message translates to:
  /// **'10초 안에 메시지 5개 넘게'**
  String get modFloodInfo;

  /// No description provided for @roomStats.
  ///
  /// In ko, this message translates to:
  /// **'모임 통계'**
  String get roomStats;

  /// No description provided for @statsMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get statsMembers;

  /// No description provided for @statsPerDay.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균 메시지'**
  String get statsPerDay;

  /// No description provided for @statsActive.
  ///
  /// In ko, this message translates to:
  /// **'30일 동안 글 쓴 사람'**
  String get statsActive;

  /// No description provided for @statsMessages30.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일 메시지'**
  String get statsMessages30;

  /// No description provided for @statsHours.
  ///
  /// In ko, this message translates to:
  /// **'활발한 시간대'**
  String get statsHours;

  /// No description provided for @statsBusiest.
  ///
  /// In ko, this message translates to:
  /// **'가장 활발한 시간: {hour}시'**
  String statsBusiest(String hour);

  /// No description provided for @statsInfo.
  ///
  /// In ko, this message translates to:
  /// **'통계는 이 휴대폰에 있는 대화로 이 휴대폰이 계산해요. 서버로 보내지 않고, 사람별 숫자는 만들지 않아요.'**
  String get statsInfo;

  /// No description provided for @modLog.
  ///
  /// In ko, this message translates to:
  /// **'관리 기록'**
  String get modLog;

  /// No description provided for @modLogEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 기록이 없어요'**
  String get modLogEmpty;

  /// No description provided for @modLogInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에서 한 관리 일만 보여요. 최근 200개까지 남아요.'**
  String get modLogInfo;

  /// No description provided for @logRemoved.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 메시지를 지움 ({why})'**
  String logRemoved(String name, String why);

  /// No description provided for @logBanned.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 추방함'**
  String logBanned(String name);

  /// No description provided for @logUnbanned.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 추방을 풂'**
  String logUnbanned(String name);

  /// No description provided for @logSetting.
  ///
  /// In ko, this message translates to:
  /// **'설정을 바꿈: {what}'**
  String logSetting(String what);

  /// No description provided for @whyWord.
  ///
  /// In ko, this message translates to:
  /// **'금지어'**
  String get whyWord;

  /// No description provided for @whyLink.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버 링크'**
  String get whyLink;

  /// No description provided for @whyFlood.
  ///
  /// In ko, this message translates to:
  /// **'도배'**
  String get whyFlood;

  /// No description provided for @movingBoard.
  ///
  /// In ko, this message translates to:
  /// **'이사 현황판'**
  String get movingBoard;

  /// No description provided for @movingInfo.
  ///
  /// In ko, this message translates to:
  /// **'옛 방에 몇 명이 있었는지 적으면 몇 명이 이사 왔는지 보여 드려요.'**
  String get movingInfo;

  /// No description provided for @oldMembers.
  ///
  /// In ko, this message translates to:
  /// **'옛 방 인원'**
  String get oldMembers;

  /// No description provided for @movedCount.
  ///
  /// In ko, this message translates to:
  /// **'{now}명 / {old}명 이사 왔어요'**
  String movedCount(String now, String old);

  /// No description provided for @bannedUsers.
  ///
  /// In ko, this message translates to:
  /// **'추방된 사용자'**
  String get bannedUsers;

  /// No description provided for @bannedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'추방된 사람이 없어요'**
  String get bannedEmpty;

  /// No description provided for @unban.
  ///
  /// In ko, this message translates to:
  /// **'추방 풀기'**
  String get unban;

  /// No description provided for @banMember.
  ///
  /// In ko, this message translates to:
  /// **'추방'**
  String get banMember;

  /// No description provided for @roomLevel.
  ///
  /// In ko, this message translates to:
  /// **'레벨'**
  String get roomLevel;

  /// No description provided for @levelN.
  ///
  /// In ko, this message translates to:
  /// **'레벨 {n}'**
  String levelN(int n);

  /// No description provided for @levelNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 레벨까지: 인원 {members}명 · 활동 {active}명 · {days}일'**
  String levelNext(String members, String active, int days);

  /// No description provided for @levelMax.
  ///
  /// In ko, this message translates to:
  /// **'가장 높은 레벨이에요'**
  String get levelMax;

  /// No description provided for @levelInfo.
  ///
  /// In ko, this message translates to:
  /// **'레벨은 인원, 최근 4주 동안 글 쓴 사람, 방이 생긴 날로 정해요. 한 번 오른 레벨은 쉽게 내려가지 않아요. 지금은 이 휴대폰이 계산해서 보여 줘요.'**
  String get levelInfo;

  /// No description provided for @chatThemeHere.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방 배경'**
  String get chatThemeHere;

  /// No description provided for @chatThemeHereInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 휴대폰에서만 바뀌어요. 다른 사람의 배경은 바꾸지 않아요.'**
  String get chatThemeHereInfo;

  /// No description provided for @useDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 설정 따르기'**
  String get useDefault;

  /// No description provided for @discussion.
  ///
  /// In ko, this message translates to:
  /// **'토론'**
  String get discussion;

  /// No description provided for @discussionInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹을 연결하면 게시물마다 댓글 버튼이 생기고, 댓글은 그 그룹에 남아요.'**
  String get discussionInfo;

  /// No description provided for @discussionNone.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 함'**
  String get discussionNone;

  /// No description provided for @comments.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get comments;

  /// No description provided for @deleteChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 삭제'**
  String get deleteChannel;

  /// No description provided for @deleteGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 삭제'**
  String get deleteGroup;

  /// No description provided for @deleteRoomInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 멤버를 내보내고 나도 나가요. 되돌릴 수 없어요.'**
  String get deleteRoomInfo;

  /// No description provided for @deleteRoomConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 삭제할까요?'**
  String get deleteRoomConfirm;

  /// No description provided for @saveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장하지 못했어요. 잠시 뒤 다시 해 주세요.'**
  String get saveFailed;

  /// No description provided for @rulesReadFirst.
  ///
  /// In ko, this message translates to:
  /// **'규칙을 읽고 동의하면 글을 쓸 수 있어요'**
  String get rulesReadFirst;

  /// No description provided for @readRules.
  ///
  /// In ko, this message translates to:
  /// **'규칙 보기'**
  String get readRules;

  /// No description provided for @welcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'환영해요'**
  String get welcomeTitle;

  /// No description provided for @pollVoted.
  ///
  /// In ko, this message translates to:
  /// **'투표했어요'**
  String get pollVoted;

  /// No description provided for @hideCountsInfoGroup.
  ///
  /// In ko, this message translates to:
  /// **'멤버에게는 숫자가 안 보여요. 관리자는 계속 볼 수 있어요.'**
  String get hideCountsInfoGroup;

  /// No description provided for @pollQuizKind.
  ///
  /// In ko, this message translates to:
  /// **'퀴즈'**
  String get pollQuizKind;

  /// No description provided for @quizMode.
  ///
  /// In ko, this message translates to:
  /// **'퀴즈 모드'**
  String get quizMode;

  /// No description provided for @quizModeInfo.
  ///
  /// In ko, this message translates to:
  /// **'정답을 하나 정해요. 답한 사람은 바로 정답과 해설을 보고, 답은 바꿀 수 없어요.'**
  String get quizModeInfo;

  /// No description provided for @quizPickAnswer.
  ///
  /// In ko, this message translates to:
  /// **'동그라미를 눌러 정답을 골라 주세요'**
  String get quizPickAnswer;

  /// No description provided for @quizExplain.
  ///
  /// In ko, this message translates to:
  /// **'해설 (선택)'**
  String get quizExplain;

  /// No description provided for @quizRight.
  ///
  /// In ko, this message translates to:
  /// **'정답이에요!'**
  String get quizRight;

  /// No description provided for @quizWrong.
  ///
  /// In ko, this message translates to:
  /// **'아쉬워요, 정답이 아니에요'**
  String get quizWrong;

  /// No description provided for @pollDeadline.
  ///
  /// In ko, this message translates to:
  /// **'마감 시간'**
  String get pollDeadline;

  /// No description provided for @pollDeadlineNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get pollDeadlineNone;

  /// No description provided for @pollIn1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간 뒤'**
  String get pollIn1h;

  /// No description provided for @pollIn1d.
  ///
  /// In ko, this message translates to:
  /// **'1일 뒤'**
  String get pollIn1d;

  /// No description provided for @pollIn3d.
  ///
  /// In ko, this message translates to:
  /// **'3일 뒤'**
  String get pollIn3d;

  /// No description provided for @pollIn1w.
  ///
  /// In ko, this message translates to:
  /// **'1주 뒤'**
  String get pollIn1w;

  /// No description provided for @pollLeftMin.
  ///
  /// In ko, this message translates to:
  /// **'{min}분 남음'**
  String pollLeftMin(int min);

  /// No description provided for @pollLeftHours.
  ///
  /// In ko, this message translates to:
  /// **'{hours}시간 남음'**
  String pollLeftHours(int hours);

  /// No description provided for @pollLeftDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 남음'**
  String pollLeftDays(int days);

  /// No description provided for @pollDeadlineInfo.
  ///
  /// In ko, this message translates to:
  /// **'마감 시간이 지나면 더 투표할 수 없어요.'**
  String get pollDeadlineInfo;

  /// No description provided for @cardLottery.
  ///
  /// In ko, this message translates to:
  /// **'추첨'**
  String get cardLottery;

  /// No description provided for @cardForm.
  ///
  /// In ko, this message translates to:
  /// **'신청서'**
  String get cardForm;

  /// No description provided for @cardFaq.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문'**
  String get cardFaq;

  /// No description provided for @cardGuide.
  ///
  /// In ko, this message translates to:
  /// **'안내 메뉴'**
  String get cardGuide;

  /// No description provided for @cardLinks.
  ///
  /// In ko, this message translates to:
  /// **'링크 버튼'**
  String get cardLinks;

  /// No description provided for @cardTemplates.
  ///
  /// In ko, this message translates to:
  /// **'글 틀'**
  String get cardTemplates;

  /// No description provided for @cardAudio.
  ///
  /// In ko, this message translates to:
  /// **'오디오'**
  String get cardAudio;

  /// No description provided for @cardRich.
  ///
  /// In ko, this message translates to:
  /// **'서식 글쓰기'**
  String get cardRich;

  /// No description provided for @cardCheckin.
  ///
  /// In ko, this message translates to:
  /// **'안전 체크인'**
  String get cardCheckin;

  /// No description provided for @newLottery.
  ///
  /// In ko, this message translates to:
  /// **'새 추첨'**
  String get newLottery;

  /// No description provided for @newForm.
  ///
  /// In ko, this message translates to:
  /// **'새 신청서'**
  String get newForm;

  /// No description provided for @newFaq.
  ///
  /// In ko, this message translates to:
  /// **'자주 묻는 질문 만들기'**
  String get newFaq;

  /// No description provided for @newGuide.
  ///
  /// In ko, this message translates to:
  /// **'안내 메뉴 만들기'**
  String get newGuide;

  /// No description provided for @newCheckin.
  ///
  /// In ko, this message translates to:
  /// **'새 안전 체크인'**
  String get newCheckin;

  /// No description provided for @cardTitleLabel.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get cardTitleLabel;

  /// No description provided for @lotteryPrize.
  ///
  /// In ko, this message translates to:
  /// **'상품'**
  String get lotteryPrize;

  /// No description provided for @lotteryPrizeHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 커피 쿠폰 2장'**
  String get lotteryPrizeHint;

  /// No description provided for @lotteryPrizeInfo.
  ///
  /// In ko, this message translates to:
  /// **'회원이 참여하기를 누르면 돼요. 마감되면 내 폰이 무작위로 당첨자를 뽑아요.'**
  String get lotteryPrizeInfo;

  /// No description provided for @lotteryWinners.
  ///
  /// In ko, this message translates to:
  /// **'당첨자 수'**
  String get lotteryWinners;

  /// No description provided for @lotteryEnds.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get lotteryEnds;

  /// No description provided for @lotteryEndsManual.
  ///
  /// In ko, this message translates to:
  /// **'직접 마감'**
  String get lotteryEndsManual;

  /// No description provided for @lotteryAnnounce.
  ///
  /// In ko, this message translates to:
  /// **'당첨자 이름 발표'**
  String get lotteryAnnounce;

  /// No description provided for @lotteryAnnounceInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 당첨자 본인에게만 알려요. 명단은 나만 봐요.'**
  String get lotteryAnnounceInfo;

  /// No description provided for @lotteryInfo.
  ///
  /// In ko, this message translates to:
  /// **'구독자끼리는 누가 참여했는지 볼 수 없어요. 운영진은 당첨될 수 없어요. 추첨은 내 폰에서 하니 마감 뒤에 앱을 열어 주세요.'**
  String get lotteryInfo;

  /// No description provided for @lotteryJoin.
  ///
  /// In ko, this message translates to:
  /// **'참여하기'**
  String get lotteryJoin;

  /// No description provided for @lotteryLeave.
  ///
  /// In ko, this message translates to:
  /// **'참여 취소'**
  String get lotteryLeave;

  /// No description provided for @lotteryJoined.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 참여'**
  String lotteryJoined(int n);

  /// No description provided for @lotteryDraw.
  ///
  /// In ko, this message translates to:
  /// **'추첨하기'**
  String get lotteryDraw;

  /// No description provided for @lotteryWon.
  ///
  /// In ko, this message translates to:
  /// **'당첨됐어요!'**
  String get lotteryWon;

  /// No description provided for @lotteryWinnersN.
  ///
  /// In ko, this message translates to:
  /// **'당첨자 {n}명'**
  String lotteryWinnersN(int n);

  /// No description provided for @lotteryNoWinner.
  ///
  /// In ko, this message translates to:
  /// **'참여한 사람이 없어 당첨자가 없어요'**
  String get lotteryNoWinner;

  /// No description provided for @lotteryEndsAt.
  ///
  /// In ko, this message translates to:
  /// **'{when} 마감'**
  String lotteryEndsAt(String when);

  /// No description provided for @lotteryDrawAsk.
  ///
  /// In ko, this message translates to:
  /// **'지금 추첨할까요?'**
  String get lotteryDrawAsk;

  /// No description provided for @lotteryDrawInfo.
  ///
  /// In ko, this message translates to:
  /// **'추첨하면 더는 참여할 수 없어요.'**
  String get lotteryDrawInfo;

  /// No description provided for @cardEnded.
  ///
  /// In ko, this message translates to:
  /// **'마감됐어요'**
  String get cardEnded;

  /// No description provided for @cardClose.
  ///
  /// In ko, this message translates to:
  /// **'마감하기'**
  String get cardClose;

  /// No description provided for @cardCloseAsk.
  ///
  /// In ko, this message translates to:
  /// **'지금 마감할까요?'**
  String get cardCloseAsk;

  /// No description provided for @cardCloseInfo.
  ///
  /// In ko, this message translates to:
  /// **'마감하면 더는 답을 받지 않아요.'**
  String get cardCloseInfo;

  /// No description provided for @cardAnswers.
  ///
  /// In ko, this message translates to:
  /// **'답 보기'**
  String get cardAnswers;

  /// No description provided for @cardNoAnswers.
  ///
  /// In ko, this message translates to:
  /// **'아직 답이 없어요'**
  String get cardNoAnswers;

  /// No description provided for @cardAnswersInfo.
  ///
  /// In ko, this message translates to:
  /// **'답은 이 휴대폰에만 있어요. 서버와 다른 멤버는 볼 수 없어요.'**
  String get cardAnswersInfo;

  /// No description provided for @formTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 12월 송년 산행 신청'**
  String get formTitleHint;

  /// No description provided for @formQuestionN.
  ///
  /// In ko, this message translates to:
  /// **'질문 {n}'**
  String formQuestionN(int n);

  /// No description provided for @formQuestionHint.
  ///
  /// In ko, this message translates to:
  /// **'질문을 써 주세요'**
  String get formQuestionHint;

  /// No description provided for @formAnswerType.
  ///
  /// In ko, this message translates to:
  /// **'답 종류'**
  String get formAnswerType;

  /// No description provided for @formShort.
  ///
  /// In ko, this message translates to:
  /// **'짧은 답'**
  String get formShort;

  /// No description provided for @formChoice.
  ///
  /// In ko, this message translates to:
  /// **'고르기'**
  String get formChoice;

  /// No description provided for @formOptionsHint.
  ///
  /// In ko, this message translates to:
  /// **'보기를 줄마다 하나씩 써 주세요'**
  String get formOptionsHint;

  /// No description provided for @formAddQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 추가'**
  String get formAddQuestion;

  /// No description provided for @formInfo.
  ///
  /// In ko, this message translates to:
  /// **'답은 암호화돼서 나에게만 와요. 다른 멤버와 서버는 볼 수 없어요.'**
  String get formInfo;

  /// No description provided for @formFill.
  ///
  /// In ko, this message translates to:
  /// **'작성하기'**
  String get formFill;

  /// No description provided for @formSent.
  ///
  /// In ko, this message translates to:
  /// **'보냈어요'**
  String get formSent;

  /// No description provided for @formSentN.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 보냄'**
  String formSentN(int n);

  /// No description provided for @formQuestionsN.
  ///
  /// In ko, this message translates to:
  /// **'질문 {n}개'**
  String formQuestionsN(int n);

  /// No description provided for @formAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'답을 써 주세요'**
  String get formAnswerHint;

  /// No description provided for @formFillInfo.
  ///
  /// In ko, this message translates to:
  /// **'답은 만든 사람에게만 가요. 다른 멤버는 볼 수 없어요.'**
  String get formFillInfo;

  /// No description provided for @faqQ.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get faqQ;

  /// No description provided for @faqA.
  ///
  /// In ko, this message translates to:
  /// **'답'**
  String get faqA;

  /// No description provided for @faqInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 질문을 누르면 답이 펼쳐져요. 눌러도 아무것도 보내지 않아서 누가 무엇을 봤는지 아무도 몰라요.'**
  String get faqInfo;

  /// No description provided for @guideTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 도와드릴까요?'**
  String get guideTitleHint;

  /// No description provided for @guideSubHint.
  ///
  /// In ko, this message translates to:
  /// **'아래 버튼을 눌러 보세요 (선택)'**
  String get guideSubHint;

  /// No description provided for @guideButtons.
  ///
  /// In ko, this message translates to:
  /// **'버튼'**
  String get guideButtons;

  /// No description provided for @guideAddButton.
  ///
  /// In ko, this message translates to:
  /// **'버튼 추가'**
  String get guideAddButton;

  /// No description provided for @guideLabel.
  ///
  /// In ko, this message translates to:
  /// **'버튼 이름'**
  String get guideLabel;

  /// No description provided for @guideText.
  ///
  /// In ko, this message translates to:
  /// **'누르면 보여 줄 글'**
  String get guideText;

  /// No description provided for @guideInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 버튼을 누르면 그 자리에서 다음 화면이 열려요. 눌러도 아무것도 보내지 않아서 누가 무엇을 봤는지 아무도 몰라요.'**
  String get guideInfo;

  /// No description provided for @linksPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get linksPreview;

  /// No description provided for @linksTextHint.
  ///
  /// In ko, this message translates to:
  /// **'버튼 위에 쓸 글 (선택)'**
  String get linksTextHint;

  /// No description provided for @linksAddButton.
  ///
  /// In ko, this message translates to:
  /// **'버튼 추가'**
  String get linksAddButton;

  /// No description provided for @linksAddRow.
  ///
  /// In ko, this message translates to:
  /// **'줄 추가'**
  String get linksAddRow;

  /// No description provided for @linksIntro.
  ///
  /// In ko, this message translates to:
  /// **'글 아래에 웹사이트로 가는 버튼을 붙여요.'**
  String get linksIntro;

  /// No description provided for @linksInfo.
  ///
  /// In ko, this message translates to:
  /// **'버튼은 글과 함께 암호화돼요. 누가 눌렀는지는 아무도 알 수 없어요. 주소는 이 휴대폰 안에서 사기 링크인지 확인해요.'**
  String get linksInfo;

  /// No description provided for @linksLeft.
  ///
  /// In ko, this message translates to:
  /// **'버튼을 누르면 고칠 수 있어요. 버튼을 {n}개 더 넣을 수 있어요.'**
  String linksLeft(int n);

  /// No description provided for @linksEditing.
  ///
  /// In ko, this message translates to:
  /// **'{row}줄 {col}번째 버튼 고치는 중'**
  String linksEditing(String row, String col);

  /// No description provided for @linksLabel.
  ///
  /// In ko, this message translates to:
  /// **'버튼 이름'**
  String get linksLabel;

  /// No description provided for @linksColor.
  ///
  /// In ko, this message translates to:
  /// **'이 버튼 색'**
  String get linksColor;

  /// No description provided for @linksColorInfo.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 동그라미는 \'모든 버튼 꾸미기\'에서 고른 색을 따라가요.'**
  String get linksColorInfo;

  /// No description provided for @linksRemove.
  ///
  /// In ko, this message translates to:
  /// **'버튼 지우기'**
  String get linksRemove;

  /// No description provided for @linksStyle.
  ///
  /// In ko, this message translates to:
  /// **'모든 버튼 꾸미기'**
  String get linksStyle;

  /// No description provided for @linksStyleColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get linksStyleColor;

  /// No description provided for @linksGlass.
  ///
  /// In ko, this message translates to:
  /// **'유리 효과'**
  String get linksGlass;

  /// No description provided for @linksSize.
  ///
  /// In ko, this message translates to:
  /// **'크기'**
  String get linksSize;

  /// No description provided for @sizeSmall.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get sizeLarge;

  /// No description provided for @linksShape.
  ///
  /// In ko, this message translates to:
  /// **'모양'**
  String get linksShape;

  /// No description provided for @shapeRound.
  ///
  /// In ko, this message translates to:
  /// **'둥글게'**
  String get shapeRound;

  /// No description provided for @shapePill.
  ///
  /// In ko, this message translates to:
  /// **'알약'**
  String get shapePill;

  /// No description provided for @shapeSquare.
  ///
  /// In ko, this message translates to:
  /// **'네모'**
  String get shapeSquare;

  /// No description provided for @linksInk.
  ///
  /// In ko, this message translates to:
  /// **'글씨 색'**
  String get linksInk;

  /// No description provided for @inkAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get inkAuto;

  /// No description provided for @inkWhite.
  ///
  /// In ko, this message translates to:
  /// **'흰색'**
  String get inkWhite;

  /// No description provided for @inkBlack.
  ///
  /// In ko, this message translates to:
  /// **'검은색'**
  String get inkBlack;

  /// No description provided for @linksStyleInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 버튼에 적용돼요. 버튼마다 색을 따로 정할 수도 있어요.'**
  String get linksStyleInfo;

  /// No description provided for @linksBadUrl.
  ///
  /// In ko, this message translates to:
  /// **'https:// 로 시작하는 웹 주소를 써 주세요'**
  String get linksBadUrl;

  /// No description provided for @richTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get richTitleHint;

  /// No description provided for @richBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'무엇이든 써 보세요...'**
  String get richBodyHint;

  /// No description provided for @richHeading.
  ///
  /// In ko, this message translates to:
  /// **'소제목'**
  String get richHeading;

  /// No description provided for @richList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get richList;

  /// No description provided for @richQuote.
  ///
  /// In ko, this message translates to:
  /// **'인용'**
  String get richQuote;

  /// No description provided for @richLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get richLink;

  /// No description provided for @richLinkUrl.
  ///
  /// In ko, this message translates to:
  /// **'링크 주소'**
  String get richLinkUrl;

  /// No description provided for @checkinHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 지진이 났어요. 모두 괜찮아요?'**
  String get checkinHint;

  /// No description provided for @checkinInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 \'괜찮아요\' 또는 \'도움 필요해요\'를 눌러요. 답은 나에게만 와요.'**
  String get checkinInfo;

  /// No description provided for @checkinOk.
  ///
  /// In ko, this message translates to:
  /// **'괜찮아요'**
  String get checkinOk;

  /// No description provided for @checkinHelp.
  ///
  /// In ko, this message translates to:
  /// **'도움 필요해요'**
  String get checkinHelp;

  /// No description provided for @templatesNew.
  ///
  /// In ko, this message translates to:
  /// **'새 글 틀'**
  String get templatesNew;

  /// No description provided for @templatesHint.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 글을 써 두세요'**
  String get templatesHint;

  /// No description provided for @templatesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장한 글 틀이 없어요'**
  String get templatesEmpty;

  /// No description provided for @templatesInfo.
  ///
  /// In ko, this message translates to:
  /// **'글 틀은 이 휴대폰에만 저장돼요. 누르면 입력창에 들어가요.'**
  String get templatesInfo;

  /// No description provided for @cardRemove.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get cardRemove;

  /// No description provided for @attachPickAudio.
  ///
  /// In ko, this message translates to:
  /// **'오디오 파일 고르기'**
  String get attachPickAudio;

  /// No description provided for @attachAudioInfo.
  ///
  /// In ko, this message translates to:
  /// **'음악·녹음 파일을 보내요. 받은 사람은 대화 안에서 바로 들을 수 있어요.'**
  String get attachAudioInfo;

  /// No description provided for @remindMe.
  ///
  /// In ko, this message translates to:
  /// **'알림 받기'**
  String get remindMe;

  /// No description provided for @remindNote.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에 알림이 와요. 서버로는 아무것도 보내지 않아요.'**
  String get remindNote;

  /// No description provided for @remindNoteWeb.
  ///
  /// In ko, this message translates to:
  /// **'이 창이 열려 있을 때 알려 줘요. 서버로는 아무것도 보내지 않아요.'**
  String get remindNoteWeb;

  /// No description provided for @remindIn20.
  ///
  /// In ko, this message translates to:
  /// **'20분 뒤'**
  String get remindIn20;

  /// No description provided for @remindIn1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간 뒤'**
  String get remindIn1h;

  /// No description provided for @remindIn3h.
  ///
  /// In ko, this message translates to:
  /// **'3시간 뒤'**
  String get remindIn3h;

  /// No description provided for @remindTomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일 오전 9시'**
  String get remindTomorrow;

  /// No description provided for @remindPick.
  ///
  /// In ko, this message translates to:
  /// **'날짜와 시간 고르기'**
  String get remindPick;

  /// No description provided for @remindSet.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간: {time}'**
  String remindSet(String time);

  /// No description provided for @remindDue.
  ///
  /// In ko, this message translates to:
  /// **'알림 받기로 정한 메시지예요'**
  String get remindDue;

  /// No description provided for @remindChannel.
  ///
  /// In ko, this message translates to:
  /// **'메시지 알림 받기'**
  String get remindChannel;

  /// No description provided for @remindOn.
  ///
  /// In ko, this message translates to:
  /// **'알림 정함'**
  String get remindOn;

  /// No description provided for @emergencyDelete.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지 비상 시 삭제'**
  String get emergencyDelete;

  /// No description provided for @emergencyDeleteOff.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 삭제 취소'**
  String get emergencyDeleteOff;

  /// No description provided for @emergencyHideRoom.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방 비상 시 숨김'**
  String get emergencyHideRoom;

  /// No description provided for @emergencyHideRoomOff.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 숨김 취소'**
  String get emergencyHideRoomOff;

  /// No description provided for @emergencyHideMsg.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지 비상 시 숨김'**
  String get emergencyHideMsg;

  /// No description provided for @emergencyHideMsgOff.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 숨김 취소'**
  String get emergencyHideMsgOff;

  /// No description provided for @emergencyMsgHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김 비밀번호로 열면 이 메시지가 사라져요'**
  String get emergencyMsgHidden;

  /// No description provided for @emergencyMarked.
  ///
  /// In ko, this message translates to:
  /// **'삭제 비밀번호로 열면 이 메시지가 지워져요'**
  String get emergencyMarked;

  /// No description provided for @emergencyUnmarked.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 삭제에서 뺐어요'**
  String get emergencyUnmarked;

  /// No description provided for @emergencyHidden.
  ///
  /// In ko, this message translates to:
  /// **'숨김 비밀번호로 열면 이 대화방이 사라져요'**
  String get emergencyHidden;

  /// No description provided for @emergencyUnhidden.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 숨김에서 뺐어요'**
  String get emergencyUnhidden;

  /// No description provided for @emergencyWebInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금과 비상 시 삭제·숨김은 휴대폰 앱에서만 설정할 수 있어요. 웹은 브라우저라 비밀을 안전하게 지킬 수 없어서예요.'**
  String get emergencyWebInfo;

  /// No description provided for @emergencyBadge.
  ///
  /// In ko, this message translates to:
  /// **'비상 시 삭제'**
  String get emergencyBadge;

  /// No description provided for @selectMsg.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get selectMsg;

  /// No description provided for @okButton.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get okButton;

  /// No description provided for @selectedN.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택됨'**
  String selectedN(int count);

  /// No description provided for @selectCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get selectCopy;

  /// No description provided for @selectSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get selectSave;

  /// No description provided for @searchThisChat.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방에서 검색'**
  String get searchThisChat;

  /// No description provided for @searchMsgCount.
  ///
  /// In ko, this message translates to:
  /// **'메시지 {count}개'**
  String searchMsgCount(int count);

  /// No description provided for @searchAsList.
  ///
  /// In ko, this message translates to:
  /// **'목록으로 보기'**
  String get searchAsList;

  /// No description provided for @searchByDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜로 이동'**
  String get searchByDate;

  /// No description provided for @searchFound.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과'**
  String get searchFound;

  /// No description provided for @searchNoneOnDate.
  ///
  /// In ko, this message translates to:
  /// **'그날 이후 메시지가 없어요'**
  String get searchNoneOnDate;

  /// No description provided for @savedToast.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지에 저장했어요'**
  String get savedToast;

  /// No description provided for @savedTagHint.
  ///
  /// In ko, this message translates to:
  /// **'빠른 검색을 위해 메시지에 이모지를 태그해 보세요'**
  String get savedTagHint;

  /// No description provided for @tagMsg.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tagMsg;

  /// No description provided for @tagRemove.
  ///
  /// In ko, this message translates to:
  /// **'태그 빼기'**
  String get tagRemove;

  /// No description provided for @tagAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get tagAll;

  /// No description provided for @shareMsg.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get shareMsg;

  /// No description provided for @shareFailed.
  ///
  /// In ko, this message translates to:
  /// **'공유하지 못했어요'**
  String get shareFailed;

  /// No description provided for @voiceLockHint.
  ///
  /// In ko, this message translates to:
  /// **'위로 밀면 잠금'**
  String get voiceLockHint;

  /// No description provided for @voicePause.
  ///
  /// In ko, this message translates to:
  /// **'일시 정지'**
  String get voicePause;

  /// No description provided for @voiceResume.
  ///
  /// In ko, this message translates to:
  /// **'이어서 녹음'**
  String get voiceResume;

  /// No description provided for @channelPostLoud.
  ///
  /// In ko, this message translates to:
  /// **'알리기'**
  String get channelPostLoud;

  /// No description provided for @channelPostSilent.
  ///
  /// In ko, this message translates to:
  /// **'조용히 알리기'**
  String get channelPostSilent;

  /// No description provided for @channelLoudOn.
  ///
  /// In ko, this message translates to:
  /// **'구독자가 소리와 함께 알림을 받아요'**
  String get channelLoudOn;

  /// No description provided for @channelSilentOn.
  ///
  /// In ko, this message translates to:
  /// **'구독자가 소리 없이 알림을 받아요'**
  String get channelSilentOn;

  /// No description provided for @encryption.
  ///
  /// In ko, this message translates to:
  /// **'암호화'**
  String get encryption;

  /// No description provided for @encVerified.
  ///
  /// In ko, this message translates to:
  /// **'확인됨'**
  String get encVerified;

  /// No description provided for @encNotVerified.
  ///
  /// In ko, this message translates to:
  /// **'확인 안 됨'**
  String get encNotVerified;

  /// No description provided for @encHeroTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 대화는 종단간 암호화되어 있어요'**
  String get encHeroTitle;

  /// No description provided for @encHeroBody.
  ///
  /// In ko, this message translates to:
  /// **'메시지와 통화는 두 사람의 휴대폰에서만 열려요. 부루미 서버도 내용을 볼 수 없어요. 아래에서 상대 휴대폰이 진짜인지 확인할 수 있어요.'**
  String get encHeroBody;

  /// No description provided for @encMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get encMembers;

  /// No description provided for @encStart.
  ///
  /// In ko, this message translates to:
  /// **'확인 시작'**
  String get encStart;

  /// No description provided for @encStartInfo.
  ///
  /// In ko, this message translates to:
  /// **'두 사람이 함께 있을 때 또는 통화하면서 해 보세요. 두 휴대폰에 같은 그림 7개가 나오면 진짜예요.'**
  String get encStartInfo;

  /// No description provided for @encShowKeys.
  ///
  /// In ko, this message translates to:
  /// **'기기 키 보기 (고급)'**
  String get encShowKeys;

  /// No description provided for @encKeysInfo.
  ///
  /// In ko, this message translates to:
  /// **'각 기기의 고유 열쇠 지문이에요. 상대 화면의 지문과 같으면 같은 기기예요.'**
  String get encKeysInfo;

  /// No description provided for @encNoDevices.
  ///
  /// In ko, this message translates to:
  /// **'아직 기기 정보를 받지 못했어요'**
  String get encNoDevices;

  /// No description provided for @verifyTitle.
  ///
  /// In ko, this message translates to:
  /// **'보안 코드 확인'**
  String get verifyTitle;

  /// No description provided for @verifyWaiting.
  ///
  /// In ko, this message translates to:
  /// **'상대 휴대폰에서 수락하기를 기다리고 있어요'**
  String get verifyWaiting;

  /// No description provided for @verifyIncoming.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 서로의 보안 코드를 확인하자고 요청했어요'**
  String verifyIncoming(String name);

  /// No description provided for @verifyAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get verifyAccept;

  /// No description provided for @verifyDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get verifyDecline;

  /// No description provided for @verifyCompare.
  ///
  /// In ko, this message translates to:
  /// **'두 휴대폰에 같은 그림이 같은 순서로 보이나요?'**
  String get verifyCompare;

  /// No description provided for @verifyMatch.
  ///
  /// In ko, this message translates to:
  /// **'같아요'**
  String get verifyMatch;

  /// No description provided for @verifyNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'달라요'**
  String get verifyNoMatch;

  /// No description provided for @verifyWaitOther.
  ///
  /// In ko, this message translates to:
  /// **'상대가 확인하기를 기다리고 있어요'**
  String get verifyWaitOther;

  /// No description provided for @verifyDone.
  ///
  /// In ko, this message translates to:
  /// **'확인했어요. 이제 이 사람의 휴대폰을 믿을 수 있어요.'**
  String get verifyDone;

  /// No description provided for @verifyCancelled.
  ///
  /// In ko, this message translates to:
  /// **'확인이 취소됐어요'**
  String get verifyCancelled;

  /// No description provided for @verifyFailed.
  ///
  /// In ko, this message translates to:
  /// **'확인을 시작하지 못했어요'**
  String get verifyFailed;

  /// No description provided for @verifyRequestLine.
  ///
  /// In ko, this message translates to:
  /// **'보안 코드 확인 요청'**
  String get verifyRequestLine;

  /// No description provided for @verifyOpen.
  ///
  /// In ko, this message translates to:
  /// **'확인하기'**
  String get verifyOpen;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @contactFirst.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get contactFirst;

  /// No description provided for @contactLast.
  ///
  /// In ko, this message translates to:
  /// **'성'**
  String get contactLast;

  /// No description provided for @memoAdd.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get memoAdd;

  /// No description provided for @contactPhotoSet.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 사진 설정'**
  String contactPhotoSet(String name);

  /// No description provided for @contactPhotoInfo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 정한 사진 대신 나에게만 보이는 사진이에요.'**
  String contactPhotoInfo(String name);

  /// No description provided for @contactPhotoRemove.
  ///
  /// In ko, this message translates to:
  /// **'내가 정한 사진 지우기'**
  String get contactPhotoRemove;

  /// No description provided for @msgInfo.
  ///
  /// In ko, this message translates to:
  /// **'메시지 정보'**
  String get msgInfo;

  /// No description provided for @msgReport.
  ///
  /// In ko, this message translates to:
  /// **'메시지 신고'**
  String get msgReport;

  /// No description provided for @reportNote.
  ///
  /// In ko, this message translates to:
  /// **'운영자가 이 글을 봐요. 신고하면 이 메시지 내용이 함께 보내져요. 다른 메시지는 보내지 않아요.'**
  String get reportNote;

  /// No description provided for @reportSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸'**
  String get reportSpam;

  /// No description provided for @reportScam.
  ///
  /// In ko, this message translates to:
  /// **'사기'**
  String get reportScam;

  /// No description provided for @reportViolence.
  ///
  /// In ko, this message translates to:
  /// **'폭력이나 위협'**
  String get reportViolence;

  /// No description provided for @reportSexual.
  ///
  /// In ko, this message translates to:
  /// **'음란물'**
  String get reportSexual;

  /// No description provided for @reportChild.
  ///
  /// In ko, this message translates to:
  /// **'아동 학대'**
  String get reportChild;

  /// No description provided for @reportDrugs.
  ///
  /// In ko, this message translates to:
  /// **'불법 약물'**
  String get reportDrugs;

  /// No description provided for @reportPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 노출'**
  String get reportPrivacy;

  /// No description provided for @reportOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportOther;

  /// No description provided for @reportDone.
  ///
  /// In ko, this message translates to:
  /// **'신고했어요. 운영자가 확인할게요.'**
  String get reportDone;

  /// No description provided for @reportFailed.
  ///
  /// In ko, this message translates to:
  /// **'신고하지 못했어요. 다시 해 주세요.'**
  String get reportFailed;

  /// No description provided for @infoSent.
  ///
  /// In ko, this message translates to:
  /// **'보낸 시간'**
  String get infoSent;

  /// No description provided for @infoStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get infoStatus;

  /// No description provided for @infoRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get infoRead;

  /// No description provided for @infoSentOnly.
  ///
  /// In ko, this message translates to:
  /// **'보냄'**
  String get infoSentOnly;

  /// No description provided for @infoExpires.
  ///
  /// In ko, this message translates to:
  /// **'사라지는 시간'**
  String get infoExpires;

  /// No description provided for @threadReply.
  ///
  /// In ko, this message translates to:
  /// **'스레드로 답장'**
  String get threadReply;

  /// No description provided for @threadTitle.
  ///
  /// In ko, this message translates to:
  /// **'스레드'**
  String get threadTitle;

  /// No description provided for @threadReplies.
  ///
  /// In ko, this message translates to:
  /// **'답글 {count}개'**
  String threadReplies(int count);

  /// No description provided for @threadPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'스레드에 답장'**
  String get threadPlaceholder;

  /// No description provided for @threadEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 답글이 없어요'**
  String get threadEmpty;

  /// No description provided for @suggestPost.
  ///
  /// In ko, this message translates to:
  /// **'글 제안'**
  String get suggestPost;

  /// No description provided for @suggestHint.
  ///
  /// In ko, this message translates to:
  /// **'이 채널에 올릴 글을 제안해 보세요'**
  String get suggestHint;

  /// No description provided for @suggestBarButton.
  ///
  /// In ko, this message translates to:
  /// **'글 제안하기'**
  String get suggestBarButton;

  /// No description provided for @suggestTextHint.
  ///
  /// In ko, this message translates to:
  /// **'올리고 싶은 글을 써 주세요'**
  String get suggestTextHint;

  /// No description provided for @suggestPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 넣기'**
  String get suggestPhoto;

  /// No description provided for @suggestPhotoRemove.
  ///
  /// In ko, this message translates to:
  /// **'사진 빼기'**
  String get suggestPhotoRemove;

  /// No description provided for @suggestTime.
  ///
  /// In ko, this message translates to:
  /// **'올릴 때'**
  String get suggestTime;

  /// No description provided for @suggestAnyTime.
  ///
  /// In ko, this message translates to:
  /// **'아무 때나'**
  String get suggestAnyTime;

  /// No description provided for @suggestTimeInfo.
  ///
  /// In ko, this message translates to:
  /// **'원하는 시간이 있으면 골라 주세요. 관리자가 바꿀 수도 있어요.'**
  String get suggestTimeInfo;

  /// No description provided for @suggestSend.
  ///
  /// In ko, this message translates to:
  /// **'제안 보내기'**
  String get suggestSend;

  /// No description provided for @suggestFree.
  ///
  /// In ko, this message translates to:
  /// **'돈은 들지 않아요. 제안한 글과 사진은 끝까지 암호화돼서 이 채널 관리자만 봐요.'**
  String get suggestFree;

  /// No description provided for @suggestCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'글 제안'**
  String get suggestCardTitle;

  /// No description provided for @suggestWantsAt.
  ///
  /// In ko, this message translates to:
  /// **'원하는 시간: {when}'**
  String suggestWantsAt(Object when);

  /// No description provided for @suggestWaiting.
  ///
  /// In ko, this message translates to:
  /// **'관리자 답을 기다리고 있어요'**
  String get suggestWaiting;

  /// No description provided for @suggestAccept.
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get suggestAccept;

  /// No description provided for @suggestDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get suggestDecline;

  /// No description provided for @suggestAcceptTitle.
  ///
  /// In ko, this message translates to:
  /// **'채널에 올리기'**
  String get suggestAcceptTitle;

  /// No description provided for @suggestNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 바로'**
  String get suggestNow;

  /// No description provided for @suggestTheirTime.
  ///
  /// In ko, this message translates to:
  /// **'원하는 시간 ({when})'**
  String suggestTheirTime(Object when);

  /// No description provided for @suggestOtherTime.
  ///
  /// In ko, this message translates to:
  /// **'다른 시간 정하기'**
  String get suggestOtherTime;

  /// No description provided for @suggestCredit.
  ///
  /// In ko, this message translates to:
  /// **'제안한 사람 이름 함께 올리기'**
  String get suggestCredit;

  /// No description provided for @suggestCreditLine.
  ///
  /// In ko, this message translates to:
  /// **'✍️ {name}님이 제안했어요'**
  String suggestCreditLine(Object name);

  /// No description provided for @suggestNote.
  ///
  /// In ko, this message translates to:
  /// **'거절 이유 (안 써도 돼요)'**
  String get suggestNote;

  /// No description provided for @suggestDeclineSend.
  ///
  /// In ko, this message translates to:
  /// **'거절하기'**
  String get suggestDeclineSend;

  /// No description provided for @suggestDealAccepted.
  ///
  /// In ko, this message translates to:
  /// **'합의됐어요!'**
  String get suggestDealAccepted;

  /// No description provided for @suggestDealNow.
  ///
  /// In ko, this message translates to:
  /// **'채널에 바로 올렸어요.'**
  String get suggestDealNow;

  /// No description provided for @suggestDealAt.
  ///
  /// In ko, this message translates to:
  /// **'{when}에 자동으로 올라가요.'**
  String suggestDealAt(Object when);

  /// No description provided for @suggestDealFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 제안이라 오간 돈은 없어요.'**
  String get suggestDealFree;

  /// No description provided for @suggestDealCredit.
  ///
  /// In ko, this message translates to:
  /// **'제안한 사람 이름이 함께 올라가요.'**
  String get suggestDealCredit;

  /// No description provided for @suggestDealDeclined.
  ///
  /// In ko, this message translates to:
  /// **'제안이 거절됐어요'**
  String get suggestDealDeclined;

  /// No description provided for @suggestDealNote.
  ///
  /// In ko, this message translates to:
  /// **'이유: {note}'**
  String suggestDealNote(Object note);

  /// No description provided for @suggestSent.
  ///
  /// In ko, this message translates to:
  /// **'제안을 보냈어요'**
  String get suggestSent;

  /// No description provided for @suggestPublished.
  ///
  /// In ko, this message translates to:
  /// **'채널에 올렸어요'**
  String get suggestPublished;

  /// No description provided for @suggestScheduled.
  ///
  /// In ko, this message translates to:
  /// **'{when}에 올라가도록 예약했어요'**
  String suggestScheduled(Object when);

  /// No description provided for @suggestDeclinedNotice.
  ///
  /// In ko, this message translates to:
  /// **'제안을 거절했어요'**
  String get suggestDeclinedNotice;

  /// No description provided for @suggestPhoneOn.
  ///
  /// In ko, this message translates to:
  /// **'예약한 글은 이 폰에서 올라가요. 그때 앱이 한 번 열려 있어야 해요.'**
  String get suggestPhoneOn;

  /// No description provided for @suggestNoRight.
  ///
  /// In ko, this message translates to:
  /// **'이 채널에 글을 올릴 권한이 없어요'**
  String get suggestNoRight;

  /// No description provided for @topics.
  ///
  /// In ko, this message translates to:
  /// **'주제'**
  String get topics;

  /// No description provided for @topicsInfo.
  ///
  /// In ko, this message translates to:
  /// **'큰 그룹 대화를 주제별 방으로 나눠요. 어떤 글이 어느 주제인지도 끝까지 암호화돼서 서버는 몰라요.'**
  String get topicsInfo;

  /// No description provided for @topicsOn.
  ///
  /// In ko, this message translates to:
  /// **'주제 켜기'**
  String get topicsOn;

  /// No description provided for @topicsView.
  ///
  /// In ko, this message translates to:
  /// **'보이는 모양'**
  String get topicsView;

  /// No description provided for @topicsViewTabs.
  ///
  /// In ko, this message translates to:
  /// **'탭'**
  String get topicsViewTabs;

  /// No description provided for @topicsViewList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get topicsViewList;

  /// No description provided for @topicsViewInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 멤버에게 같은 모양으로 보여요.'**
  String get topicsViewInfo;

  /// No description provided for @topicsList.
  ///
  /// In ko, this message translates to:
  /// **'주제 목록'**
  String get topicsList;

  /// No description provided for @topicsListInfo.
  ///
  /// In ko, this message translates to:
  /// **'주제 이름과 아이콘도 암호화돼서 관리자 폰에서 멤버 폰으로 바로 전해져요. 관리자만 주제를 만들고 닫을 수 있어요.'**
  String get topicsListInfo;

  /// No description provided for @topicGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get topicGeneral;

  /// No description provided for @topicAll.
  ///
  /// In ko, this message translates to:
  /// **'모두'**
  String get topicAll;

  /// No description provided for @topicNew.
  ///
  /// In ko, this message translates to:
  /// **'새 주제'**
  String get topicNew;

  /// No description provided for @topicEdit.
  ///
  /// In ko, this message translates to:
  /// **'주제 수정'**
  String get topicEdit;

  /// No description provided for @topicName.
  ///
  /// In ko, this message translates to:
  /// **'주제 이름'**
  String get topicName;

  /// No description provided for @topicNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 공지, 잡담, 맛집'**
  String get topicNameHint;

  /// No description provided for @topicIcon.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get topicIcon;

  /// No description provided for @topicColor.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get topicColor;

  /// No description provided for @topicCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get topicCreate;

  /// No description provided for @topicDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get topicDone;

  /// No description provided for @topicClose.
  ///
  /// In ko, this message translates to:
  /// **'주제 닫기'**
  String get topicClose;

  /// No description provided for @topicReopen.
  ///
  /// In ko, this message translates to:
  /// **'주제 다시 열기'**
  String get topicReopen;

  /// No description provided for @topicClosedBar.
  ///
  /// In ko, this message translates to:
  /// **'닫힌 주제예요. 관리자만 쓸 수 있어요.'**
  String get topicClosedBar;

  /// No description provided for @topicHideGeneral.
  ///
  /// In ko, this message translates to:
  /// **'탭에서 일반 숨기기'**
  String get topicHideGeneral;

  /// No description provided for @topicMessageIn.
  ///
  /// In ko, this message translates to:
  /// **'{name}에 메시지'**
  String topicMessageIn(Object name);

  /// No description provided for @topicCount.
  ///
  /// In ko, this message translates to:
  /// **'주제 {n}개'**
  String topicCount(Object n);

  /// No description provided for @topicOffInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 모든 글이 한 대화로 보여요. 주제는 남아 있어서 다시 켜면 그대로예요.'**
  String get topicOffInfo;

  /// No description provided for @topicCreated.
  ///
  /// In ko, this message translates to:
  /// **'‘{name}’ 주제를 만들었어요'**
  String topicCreated(Object name);

  /// No description provided for @topicClosedNotice.
  ///
  /// In ko, this message translates to:
  /// **'주제를 닫았어요'**
  String get topicClosedNotice;

  /// No description provided for @topicReopenedNotice.
  ///
  /// In ko, this message translates to:
  /// **'주제를 다시 열었어요'**
  String get topicReopenedNotice;

  /// No description provided for @topicSwitchBar.
  ///
  /// In ko, this message translates to:
  /// **'탭 위치 바꾸기'**
  String get topicSwitchBar;

  /// No description provided for @topicNoMessages.
  ///
  /// In ko, this message translates to:
  /// **'아직 글이 없어요'**
  String get topicNoMessages;

  /// No description provided for @topicNoIcon.
  ///
  /// In ko, this message translates to:
  /// **'글자'**
  String get topicNoIcon;

  /// No description provided for @topicSaved.
  ///
  /// In ko, this message translates to:
  /// **'주제를 저장했어요'**
  String get topicSaved;

  /// No description provided for @topicNameNeeded.
  ///
  /// In ko, this message translates to:
  /// **'주제 이름을 써 주세요'**
  String get topicNameNeeded;

  /// No description provided for @packDynamic.
  ///
  /// In ko, this message translates to:
  /// **'묶음 정렬 유연하게'**
  String get packDynamic;

  /// No description provided for @packDynamicInfo.
  ///
  /// In ko, this message translates to:
  /// **'최근에 쓴 스티커 묶음이 앞에 나와요.'**
  String get packDynamicInfo;

  /// No description provided for @packOrderInfo.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 줄 세 개를 끌어서 순서를 바꿔요. 끈 묶음은 스티커 칸에서 빠지고, 받은 스티커는 그대로 보여요.'**
  String get packOrderInfo;

  /// No description provided for @attachFromGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 선택'**
  String get attachFromGallery;

  /// No description provided for @attachFromFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일에서 선택'**
  String get attachFromFiles;

  /// No description provided for @recentSentFiles.
  ///
  /// In ko, this message translates to:
  /// **'최근에 보낸 파일'**
  String get recentSentFiles;

  /// No description provided for @photoTooBig.
  ///
  /// In ko, this message translates to:
  /// **'사진이 너무 커요. 더 작은 사진을 골라 주세요.'**
  String get photoTooBig;

  /// No description provided for @savedChatsCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 대화'**
  String savedChatsCount(int n);

  /// No description provided for @savedAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 메시지'**
  String get savedAll;

  /// No description provided for @savedNotes.
  ///
  /// In ko, this message translates to:
  /// **'내 노트'**
  String get savedNotes;

  /// No description provided for @savedOpenChat.
  ///
  /// In ko, this message translates to:
  /// **'대화 열기'**
  String get savedOpenChat;

  /// No description provided for @savedSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메시지 또는 태그 검색'**
  String get savedSearchHint;

  /// No description provided for @savedSide.
  ///
  /// In ko, this message translates to:
  /// **'대화별로 보기'**
  String get savedSide;

  /// No description provided for @savedSearchList.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get savedSearchList;

  /// No description provided for @savedNoMore.
  ///
  /// In ko, this message translates to:
  /// **'더 이상 결과가 없어요'**
  String get savedNoMore;

  /// No description provided for @mediaZoomIn.
  ///
  /// In ko, this message translates to:
  /// **'확대'**
  String get mediaZoomIn;

  /// No description provided for @mediaZoomOut.
  ///
  /// In ko, this message translates to:
  /// **'축소'**
  String get mediaZoomOut;

  /// No description provided for @mediaCalendar.
  ///
  /// In ko, this message translates to:
  /// **'달력 보기'**
  String get mediaCalendar;

  /// No description provided for @mediaPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진 보기'**
  String get mediaPhotos;

  /// No description provided for @mediaVideos.
  ///
  /// In ko, this message translates to:
  /// **'동영상 보기'**
  String get mediaVideos;

  /// No description provided for @savedLinkTag.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get savedLinkTag;

  /// No description provided for @markAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음'**
  String get markAllRead;

  /// No description provided for @archiveShort.
  ///
  /// In ko, this message translates to:
  /// **'보관'**
  String get archiveShort;

  /// No description provided for @chatLocked.
  ///
  /// In ko, this message translates to:
  /// **'끝까지 잠김'**
  String get chatLocked;

  /// No description provided for @chatGuarded.
  ///
  /// In ko, this message translates to:
  /// **'공개방 · 지킴이 검사'**
  String get chatGuarded;

  /// No description provided for @storyMine.
  ///
  /// In ko, this message translates to:
  /// **'내 스토리'**
  String get storyMine;

  /// No description provided for @storyReplyPrefix.
  ///
  /// In ko, this message translates to:
  /// **'스토리에 답장:'**
  String get storyReplyPrefix;

  /// No description provided for @storyReplied.
  ///
  /// In ko, this message translates to:
  /// **'답장을 보냈어요'**
  String get storyReplied;

  /// No description provided for @storyReplyHint.
  ///
  /// In ko, this message translates to:
  /// **'답장 보내기…'**
  String get storyReplyHint;

  /// No description provided for @storyPrivateNote.
  ///
  /// In ko, this message translates to:
  /// **'친구에게만 24시간 보여요 · 본 사람 기록 없음'**
  String get storyPrivateNote;

  /// No description provided for @storyNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get storyNow;

  /// No description provided for @storyMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String storyMinutes(int n);

  /// No description provided for @storyHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간'**
  String storyHours(int n);

  /// No description provided for @storyHint.
  ///
  /// In ko, this message translates to:
  /// **'사진을 찍거나 고르세요'**
  String get storyHint;

  /// No description provided for @storyCaptionHint.
  ///
  /// In ko, this message translates to:
  /// **'글 넣기'**
  String get storyCaptionHint;

  /// No description provided for @storyShare.
  ///
  /// In ko, this message translates to:
  /// **'친구에게 공유'**
  String get storyShare;

  /// No description provided for @storyShared.
  ///
  /// In ko, this message translates to:
  /// **'친구 {n}명에게 공유했어요'**
  String storyShared(int n);

  /// No description provided for @storyNoFriends.
  ///
  /// In ko, this message translates to:
  /// **'보낼 친구가 아직 없어요'**
  String get storyNoFriends;

  /// No description provided for @storyCamera.
  ///
  /// In ko, this message translates to:
  /// **'스토리 카메라'**
  String get storyCamera;

  /// No description provided for @camLive.
  ///
  /// In ko, this message translates to:
  /// **'라이브'**
  String get camLive;

  /// No description provided for @camVideo.
  ///
  /// In ko, this message translates to:
  /// **'영상'**
  String get camVideo;

  /// No description provided for @camPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get camPhoto;

  /// No description provided for @camLiveStart.
  ///
  /// In ko, this message translates to:
  /// **'실시간 방송 시작'**
  String get camLiveStart;

  /// No description provided for @camLiveLater.
  ///
  /// In ko, this message translates to:
  /// **'실시간 방송은 우리 서버가 준비되면 열려요'**
  String get camLiveLater;

  /// No description provided for @camGridRemove.
  ///
  /// In ko, this message translates to:
  /// **'탭하여 그리드 제거'**
  String get camGridRemove;

  /// No description provided for @camUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 켤 수 없어요\n아래 버튼을 누르면 휴대폰 카메라로 찍어요'**
  String get camUnavailable;

  /// No description provided for @camDualHint.
  ///
  /// In ko, this message translates to:
  /// **'뒤 카메라, 앞 카메라 순서로 바로 이어 찍어요'**
  String get camDualHint;

  /// No description provided for @camGridLeft.
  ///
  /// In ko, this message translates to:
  /// **'{n}장 더 찍어요'**
  String camGridLeft(int n);

  /// No description provided for @storiesCount.
  ///
  /// In ko, this message translates to:
  /// **'스토리 {n}개'**
  String storiesCount(int n);

  /// No description provided for @tabGroups.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get tabGroups;

  /// No description provided for @noCommonGroups.
  ///
  /// In ko, this message translates to:
  /// **'같이 있는 그룹이 없어요'**
  String get noCommonGroups;

  /// No description provided for @qrCode.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드'**
  String get qrCode;

  /// No description provided for @wideEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대화를 골라요'**
  String get wideEmpty;

  /// No description provided for @storyAnswerSent.
  ///
  /// In ko, this message translates to:
  /// **'보냈어요. 1:1 대화로 갔어요'**
  String get storyAnswerSent;

  /// No description provided for @storyAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'답 쓰기'**
  String get storyAnswerHint;

  /// No description provided for @storyGoing.
  ///
  /// In ko, this message translates to:
  /// **'갈래요'**
  String get storyGoing;

  /// No description provided for @storyGoingSent.
  ///
  /// In ko, this message translates to:
  /// **'갈게요라고 보냈어요'**
  String get storyGoingSent;

  /// No description provided for @storyPoll.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get storyPoll;

  /// No description provided for @storyQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문'**
  String get storyQuestion;

  /// No description provided for @storyPlan.
  ///
  /// In ko, this message translates to:
  /// **'일정'**
  String get storyPlan;

  /// No description provided for @storyPlanTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 해요? (예: 토요일 사진전)'**
  String get storyPlanTitle;

  /// No description provided for @storyAskHint.
  ///
  /// In ko, this message translates to:
  /// **'물어볼 말'**
  String get storyAskHint;

  /// No description provided for @storyPollInfo.
  ///
  /// In ko, this message translates to:
  /// **'답은 각자 1:1 대화로 와요. 다른 친구도, 부루미도 누가 무엇을 골랐는지 몰라요.'**
  String get storyPollInfo;

  /// No description provided for @storyOption.
  ///
  /// In ko, this message translates to:
  /// **'선택 {n}'**
  String storyOption(int n);

  /// No description provided for @storyPlanWhen.
  ///
  /// In ko, this message translates to:
  /// **'언제 (예: 토요일 오후 3시)'**
  String get storyPlanWhen;

  /// No description provided for @storyPlanPlace.
  ///
  /// In ko, this message translates to:
  /// **'어디서 (선택)'**
  String get storyPlanPlace;

  /// No description provided for @storyPlanInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구가 \"갈래요\"를 누르면 1:1 대화로 알려 줘요.'**
  String get storyPlanInfo;

  /// No description provided for @storyQuestionInfo.
  ///
  /// In ko, this message translates to:
  /// **'답은 1:1 대화로 와요. 나만 봐요.'**
  String get storyQuestionInfo;

  /// No description provided for @storyAllFriends.
  ///
  /// In ko, this message translates to:
  /// **'모든 친구'**
  String get storyAllFriends;

  /// No description provided for @storyCloseFriends.
  ///
  /// In ko, this message translates to:
  /// **'친한 친구'**
  String get storyCloseFriends;

  /// No description provided for @storyPicked.
  ///
  /// In ko, this message translates to:
  /// **'이번만 고르기'**
  String get storyPicked;

  /// No description provided for @storyPickedCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}명'**
  String storyPickedCount(int n);

  /// No description provided for @storyAllFriendsSub.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화 친구 {n}명'**
  String storyAllFriendsSub(int n);

  /// No description provided for @storyCloseFriendsSub.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 · 이 휴대폰에만 저장돼요'**
  String storyCloseFriendsSub(int n);

  /// No description provided for @storyPickedSub.
  ///
  /// In ko, this message translates to:
  /// **'이 스토리만 볼 사람을 골라요'**
  String get storyPickedSub;

  /// No description provided for @storyWho.
  ///
  /// In ko, this message translates to:
  /// **'누가 볼까요?'**
  String get storyWho;

  /// No description provided for @storyWhoInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 친구에게만 그 대화의 암호로 잠겨서 가요. 서버는 누가 받았는지 알 수 없어요.'**
  String get storyWhoInfo;

  /// No description provided for @storyHowLong.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 보여 줄까요?'**
  String get storyHowLong;

  /// No description provided for @storyHowLongInfo.
  ///
  /// In ko, this message translates to:
  /// **'시간이 지나면 친구 휴대폰과 서버에서 사라져요.'**
  String get storyHowLongInfo;

  /// No description provided for @storyHoursN.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간'**
  String storyHoursN(int n);

  /// No description provided for @storyArchive.
  ///
  /// In ko, this message translates to:
  /// **'내 스토리 보관함'**
  String get storyArchive;

  /// No description provided for @storyArchiveEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 없어요. 스토리를 올리면 이 휴대폰에만 보관돼요.'**
  String get storyArchiveEmpty;

  /// No description provided for @storyArchiveWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹에서는 보관하지 않아요. 휴대폰 앱에서 볼 수 있어요.'**
  String get storyArchiveWeb;

  /// No description provided for @storyArchiveInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에만 있어요. 누르면 다시 올리고, 길게 누르면 지워요.'**
  String get storyArchiveInfo;

  /// No description provided for @storyNew.
  ///
  /// In ko, this message translates to:
  /// **'새 스토리'**
  String get storyNew;

  /// No description provided for @feedTitle.
  ///
  /// In ko, this message translates to:
  /// **'친구 피드'**
  String get feedTitle;

  /// No description provided for @feedEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 게시물이 없어요'**
  String get feedEmpty;

  /// No description provided for @feedInfo.
  ///
  /// In ko, this message translates to:
  /// **'1:1 친구에게만 보여요. 광고 없이, 끝까지 잠겨서 가요.'**
  String get feedInfo;

  /// No description provided for @feedNew.
  ///
  /// In ko, this message translates to:
  /// **'새 게시물'**
  String get feedNew;

  /// No description provided for @feedHint.
  ///
  /// In ko, this message translates to:
  /// **'무슨 일이 있었나요?'**
  String get feedHint;

  /// No description provided for @feedPost.
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get feedPost;

  /// No description provided for @feedAddPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get feedAddPhoto;

  /// No description provided for @feedRemovePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 빼기'**
  String get feedRemovePhoto;

  /// No description provided for @feedLikesN.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 {n}명'**
  String feedLikesN(int n);

  /// No description provided for @feedOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 보여요'**
  String get feedOnlyMe;

  /// No description provided for @feedReplyHint.
  ///
  /// In ko, this message translates to:
  /// **'답장은 이 친구에게만 가요'**
  String get feedReplyHint;

  /// No description provided for @feedReplyPrefix.
  ///
  /// In ko, this message translates to:
  /// **'💬 게시물에 답장:'**
  String get feedReplyPrefix;

  /// No description provided for @feedPosted.
  ///
  /// In ko, this message translates to:
  /// **'친구 {n}명에게 올렸어요'**
  String feedPosted(int n);

  /// No description provided for @feedDeleted.
  ///
  /// In ko, this message translates to:
  /// **'게시물을 지웠어요'**
  String get feedDeleted;

  /// No description provided for @feedLike.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get feedLike;

  /// No description provided for @feedReply.
  ///
  /// In ko, this message translates to:
  /// **'답장'**
  String get feedReply;

  /// No description provided for @markUnread.
  ///
  /// In ko, this message translates to:
  /// **'읽지 않음으로 표시'**
  String get markUnread;

  /// No description provided for @addToFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더에 추가'**
  String get addToFolder;

  /// No description provided for @removeFromFolder.
  ///
  /// In ko, this message translates to:
  /// **'{name} 폴더에서 빼기'**
  String removeFromFolder(String name);

  /// No description provided for @blockShort.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get blockShort;

  /// No description provided for @emergencyDeleteRoom.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방 비상 시 삭제'**
  String get emergencyDeleteRoom;

  /// No description provided for @emergencyRoomMarked.
  ///
  /// In ko, this message translates to:
  /// **'삭제 비밀번호로 열면 이 대화방이 지워져요'**
  String get emergencyRoomMarked;

  /// No description provided for @folderAddedTo.
  ///
  /// In ko, this message translates to:
  /// **'폴더에 넣었어요'**
  String get folderAddedTo;

  /// No description provided for @noFoldersYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 폴더가 없어요'**
  String get noFoldersYet;

  /// No description provided for @swipePin.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get swipePin;

  /// No description provided for @swipeUnpin.
  ///
  /// In ko, this message translates to:
  /// **'고정 해제'**
  String get swipeUnpin;

  /// No description provided for @swipeMute.
  ///
  /// In ko, this message translates to:
  /// **'알림 끔'**
  String get swipeMute;

  /// No description provided for @swipeUnmute.
  ///
  /// In ko, this message translates to:
  /// **'알림 켬'**
  String get swipeUnmute;

  /// No description provided for @swipeArchive.
  ///
  /// In ko, this message translates to:
  /// **'보관'**
  String get swipeArchive;

  /// No description provided for @swipeUnarchive.
  ///
  /// In ko, this message translates to:
  /// **'보관 해제'**
  String get swipeUnarchive;

  /// No description provided for @muteSoundOff.
  ///
  /// In ko, this message translates to:
  /// **'소리 끄기'**
  String get muteSoundOff;

  /// No description provided for @muteSoundOn.
  ///
  /// In ko, this message translates to:
  /// **'소리 켜기'**
  String get muteSoundOn;

  /// No description provided for @muteFor.
  ///
  /// In ko, this message translates to:
  /// **'{time} 동안 끄기'**
  String muteFor(String time);

  /// No description provided for @muteHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간'**
  String muteHours(int n);

  /// No description provided for @muteDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String muteDays(int n);

  /// No description provided for @muteCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 정하기'**
  String get muteCustom;

  /// No description provided for @muteUntilTitle.
  ///
  /// In ko, this message translates to:
  /// **'언제까지 끌까요?'**
  String get muteUntilTitle;

  /// No description provided for @muteEndsAt.
  ///
  /// In ko, this message translates to:
  /// **'다시 켜지는 때: {time}'**
  String muteEndsAt(String time);

  /// No description provided for @mutedToast.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼졌어요'**
  String get mutedToast;

  /// No description provided for @unmutedToast.
  ///
  /// In ko, this message translates to:
  /// **'알림이 켜졌어요'**
  String get unmutedToast;

  /// No description provided for @mutedForToast.
  ///
  /// In ko, this message translates to:
  /// **'{time} 동안 알림이 꺼져요'**
  String mutedForToast(String time);

  /// No description provided for @mutedUntilToast.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼져요. 다시 켜지는 때: {time}'**
  String mutedUntilToast(String time);

  /// No description provided for @soundOffToast.
  ///
  /// In ko, this message translates to:
  /// **'알림이 소리 없이 와요'**
  String get soundOffToast;

  /// No description provided for @soundOnToast.
  ///
  /// In ko, this message translates to:
  /// **'알림 소리가 다시 나요'**
  String get soundOnToast;

  /// No description provided for @pinnedMany.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개를 고정했어요'**
  String pinnedMany(int n);

  /// No description provided for @unpinnedMany.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개의 고정을 풀었어요'**
  String unpinnedMany(int n);

  /// No description provided for @mutedMany.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개의 알림을 껐어요'**
  String mutedMany(int n);

  /// No description provided for @unmutedMany.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개의 알림을 켰어요'**
  String unmutedMany(int n);

  /// No description provided for @swipeUnread.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음'**
  String get swipeUnread;

  /// No description provided for @swipeSettings.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록 밀기'**
  String get swipeSettings;

  /// No description provided for @swipeToRight.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽으로 밀기'**
  String get swipeToRight;

  /// No description provided for @swipeToLeft.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽으로 밀기'**
  String get swipeToLeft;

  /// No description provided for @swipeDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get swipeDefault;

  /// No description provided for @swipeSettingsInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화를 옆으로 밀면 나오는 버튼 중 맨 끝 버튼을 골라요. 끝까지 쭉 밀면 그 버튼이 바로 실행돼요.'**
  String get swipeSettingsInfo;

  /// No description provided for @swipeSampleName.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get swipeSampleName;

  /// No description provided for @swipeSampleText.
  ///
  /// In ko, this message translates to:
  /// **'옆으로 밀어서 바로 정리해 보세요'**
  String get swipeSampleText;

  /// No description provided for @folderDefaultInfo.
  ///
  /// In ko, this message translates to:
  /// **'맨 앞에 둔 폴더가 앱을 열 때 먼저 보여요. \'모든 대화\'도 옮길 수 있어요.'**
  String get folderDefaultInfo;

  /// No description provided for @iconBadgeHeader.
  ///
  /// In ko, this message translates to:
  /// **'배지 숫자'**
  String get iconBadgeHeader;

  /// No description provided for @iconBadgeChannels.
  ///
  /// In ko, this message translates to:
  /// **'채널 포함'**
  String get iconBadgeChannels;

  /// No description provided for @iconBadgeMuted.
  ///
  /// In ko, this message translates to:
  /// **'알림 끈 대화 포함'**
  String get iconBadgeMuted;

  /// No description provided for @iconBadgeMessages.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 메시지 수로 세기'**
  String get iconBadgeMessages;

  /// No description provided for @iconBadgeInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 탭과 앱 아이콘의 빨간 숫자예요. \'안 읽은 메시지 수로 세기\'를 끄면 안 읽은 대화 수로 세요. 숫자는 휴대폰에서만 세고 서버는 몰라요.'**
  String get iconBadgeInfo;

  /// No description provided for @chatsHeaderInfo.
  ///
  /// In ko, this message translates to:
  /// **'메시지 표시 방법, 답장, 스티커와 이모지, 이 휴대폰 안에서만 처리되는 AI 기능처럼 대화방에서 쓰는 기능을 정해요.'**
  String get chatsHeaderInfo;

  /// No description provided for @faqHeaderInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미를 쓰면서 자주 궁금해하는 내용을 모았어요. 인터넷에 연결되지 않아도 볼 수 있어요.'**
  String get faqHeaderInfo;

  /// No description provided for @devicesHeaderInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 계정에 로그인된 기기를 모두 볼 수 있어요. 모르는 기기가 있으면 여기서 바로 로그아웃시킬 수 있어요.'**
  String get devicesHeaderInfo;

  /// No description provided for @languageHeaderInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱에 보이는 말을 골라요. 다른 언어로 온 메시지는 대화방에서 바로 번역할 수 있어요.'**
  String get languageHeaderInfo;

  /// No description provided for @stickersHeaderInfo.
  ///
  /// In ko, this message translates to:
  /// **'빠른 반응, 큰 이모지, 스티커 팩 순서처럼 스티커와 이모지를 쓰는 방법을 정해요.'**
  String get stickersHeaderInfo;

  /// No description provided for @birthday.
  ///
  /// In ko, this message translates to:
  /// **'생일'**
  String get birthday;

  /// No description provided for @birthdayAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get birthdayAdd;

  /// No description provided for @birthdayInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구에게는 월과 일만 보여요. 누가 볼지는 설정 > 개인정보 및 보안에서 정해요.'**
  String get birthdayInfo;

  /// No description provided for @birthdayRemove.
  ///
  /// In ko, this message translates to:
  /// **'생일 지우기'**
  String get birthdayRemove;

  /// No description provided for @birthdayMonthDay.
  ///
  /// In ko, this message translates to:
  /// **'{m}월 {d}일'**
  String birthdayMonthDay(int m, int d);

  /// No description provided for @whoPhoto.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진'**
  String get whoPhoto;

  /// No description provided for @whoBio.
  ///
  /// In ko, this message translates to:
  /// **'자기소개'**
  String get whoBio;

  /// No description provided for @whoBirthday.
  ///
  /// In ko, this message translates to:
  /// **'생일'**
  String get whoBirthday;

  /// No description provided for @whoLastSeen.
  ///
  /// In ko, this message translates to:
  /// **'마지막 접속 및 온라인'**
  String get whoLastSeen;

  /// No description provided for @whoForwards.
  ///
  /// In ko, this message translates to:
  /// **'전달된 메시지'**
  String get whoForwards;

  /// No description provided for @whoAlwaysNobody.
  ///
  /// In ko, this message translates to:
  /// **'아무도'**
  String get whoAlwaysNobody;

  /// No description provided for @whoCardInfo.
  ///
  /// In ko, this message translates to:
  /// **'\'내 연락처\'는 서버에 올라가지 않고, 1:1 대화의 암호화로만 친구에게 전달돼요.'**
  String get whoCardInfo;

  /// No description provided for @lastSeenInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미는 접속 중인지, 마지막으로 언제 접속했는지 누구에게도 보여 주지 않아요. 처음부터 그렇게 만들어서 바꿀 필요가 없어요.'**
  String get lastSeenInfo;

  /// No description provided for @forwardsInfo.
  ///
  /// In ko, this message translates to:
  /// **'누가 내 메시지를 전달해도 내 이름과 원래 대화방은 함께 가지 않아요. \'전달됨\' 표시만 붙어요. 처음부터 그렇게 만들었어요.'**
  String get forwardsInfo;

  /// No description provided for @editHistory.
  ///
  /// In ko, this message translates to:
  /// **'내 수정 기록 숨기기'**
  String get editHistory;

  /// No description provided for @editHistoryAlways.
  ///
  /// In ko, this message translates to:
  /// **'항상'**
  String get editHistoryAlways;

  /// No description provided for @editHistoryInfo.
  ///
  /// In ko, this message translates to:
  /// **'내가 고친 메시지는 다른 사람에게 마지막 내용만 보여요. 부루미는 처음부터 고치기 전 내용을 보여 주지 않아요.'**
  String get editHistoryInfo;

  /// No description provided for @birthdayAlert.
  ///
  /// In ko, this message translates to:
  /// **'생일 알림'**
  String get birthdayAlert;

  /// No description provided for @birthdayAlertInfo.
  ///
  /// In ko, this message translates to:
  /// **'생일을 공개한 친구의 생일 당일 오전 9시에 알려 드려요. 이 휴대폰 안에서만 알려요.'**
  String get birthdayAlertInfo;

  /// No description provided for @birthdayAlertTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 {name} 님의 생일이에요'**
  String birthdayAlertTitle(String name);

  /// No description provided for @birthdayAlertBody.
  ///
  /// In ko, this message translates to:
  /// **'축하 메시지를 보내 보세요.'**
  String get birthdayAlertBody;

  /// No description provided for @showErrors.
  ///
  /// In ko, this message translates to:
  /// **'오류 내용 보기'**
  String get showErrors;

  /// No description provided for @showErrorsInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 문제가 생겼을 때의 오류 내용을 이 휴대폰에 모아 보여 줘요. 문의할 때 복사해서 보내면 도움이 돼요. 메시지 내용은 담기지 않아요.'**
  String get showErrorsInfo;

  /// No description provided for @errorLog.
  ///
  /// In ko, this message translates to:
  /// **'오류 기록'**
  String get errorLog;

  /// No description provided for @errorLogEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 오류가 없어요'**
  String get errorLogEmpty;

  /// No description provided for @errorLogCopy.
  ///
  /// In ko, this message translates to:
  /// **'모두 복사'**
  String get errorLogCopy;

  /// No description provided for @autoDeleteHeader.
  ///
  /// In ko, this message translates to:
  /// **'자동 회원 탈퇴'**
  String get autoDeleteHeader;

  /// No description provided for @autoDeleteRow.
  ///
  /// In ko, this message translates to:
  /// **'다음 기간 동안 미접속 시'**
  String get autoDeleteRow;

  /// No description provided for @autoDeleteInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 기간 안에 한 번이라도 접속하지 않으면 모든 그룹, 메시지, 연락처와 함께 계정이 삭제돼요.'**
  String get autoDeleteInfo;

  /// No description provided for @months1.
  ///
  /// In ko, this message translates to:
  /// **'1개월'**
  String get months1;

  /// No description provided for @months3.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get months3;

  /// No description provided for @months6.
  ///
  /// In ko, this message translates to:
  /// **'6개월'**
  String get months6;

  /// No description provided for @months12.
  ///
  /// In ko, this message translates to:
  /// **'12개월'**
  String get months12;

  /// No description provided for @months18.
  ///
  /// In ko, this message translates to:
  /// **'18개월'**
  String get months18;

  /// No description provided for @hideDeleteRow.
  ///
  /// In ko, this message translates to:
  /// **'숨김·삭제 비밀번호'**
  String get hideDeleteRow;

  /// No description provided for @privMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get privMessages;

  /// No description provided for @privWhoSees.
  ///
  /// In ko, this message translates to:
  /// **'누가 내 정보를 볼 수 있나요'**
  String get privWhoSees;

  /// No description provided for @privWhoReach.
  ///
  /// In ko, this message translates to:
  /// **'누가 나에게 연락할 수 있나요'**
  String get privWhoReach;

  /// No description provided for @privScreen.
  ///
  /// In ko, this message translates to:
  /// **'화면 보호'**
  String get privScreen;

  /// No description provided for @privAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get privAccount;

  /// No description provided for @undoSendSub.
  ///
  /// In ko, this message translates to:
  /// **'보낸 뒤 5초 안에는 취소할 수 있어요'**
  String get undoSendSub;

  /// No description provided for @sendReadSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 상대에게 내 읽음 표시가 가지 않아요'**
  String get sendReadSub;

  /// No description provided for @sendTypingSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 상대에게 입력 중 표시가 가지 않아요'**
  String get sendTypingSub;

  /// No description provided for @veilAllSub.
  ///
  /// In ko, this message translates to:
  /// **'대화방 안 메시지를 누르고 있는 동안만 보여요'**
  String get veilAllSub;

  /// No description provided for @veilList.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록 가리기'**
  String get veilList;

  /// No description provided for @veilListSub.
  ///
  /// In ko, this message translates to:
  /// **'목록의 마지막 메시지를 누르고 있는 동안만 보여요'**
  String get veilListSub;

  /// No description provided for @panicSub.
  ///
  /// In ko, this message translates to:
  /// **'두 손가락으로 두 번 톡톡 치면 바로 잠겨요'**
  String get panicSub;

  /// No description provided for @birthdayAlertSub.
  ///
  /// In ko, this message translates to:
  /// **'친구 생일 아침 9시에 이 휴대폰이 알려 줘요'**
  String get birthdayAlertSub;

  /// No description provided for @showErrorsSub.
  ///
  /// In ko, this message translates to:
  /// **'문의할 때 보낼 오류 내용을 이 휴대폰에 모아요'**
  String get showErrorsSub;

  /// No description provided for @autoDeleteSub.
  ///
  /// In ko, this message translates to:
  /// **'이 기간 동안 한 번도 접속하지 않으면 계정이 지워져요'**
  String get autoDeleteSub;

  /// No description provided for @autoDlPhotosSub.
  ///
  /// In ko, this message translates to:
  /// **'사진을 미리 받아 둬요'**
  String get autoDlPhotosSub;

  /// No description provided for @autoDlReset.
  ///
  /// In ko, this message translates to:
  /// **'자동 다운로드 설정 되돌리기'**
  String get autoDlReset;

  /// No description provided for @mediaAndLinks.
  ///
  /// In ko, this message translates to:
  /// **'미디어와 링크'**
  String get mediaAndLinks;

  /// No description provided for @autoplayGifSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 GIF가 첫 장면에 멈춰 있어요'**
  String get autoplayGifSub;

  /// No description provided for @linkPreviewSub.
  ///
  /// In ko, this message translates to:
  /// **'보낼 때 내 휴대폰이 제목과 사진을 넣어요'**
  String get linkPreviewSub;

  /// No description provided for @callsHeader.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get callsHeader;

  /// No description provided for @lowDataCalls.
  ///
  /// In ko, this message translates to:
  /// **'전화에 데이터 적게 쓰기'**
  String get lowDataCalls;

  /// No description provided for @lowDataCallsSub.
  ///
  /// In ko, this message translates to:
  /// **'영상 화질을 낮춰 느린 인터넷에서도 잘 이어져요'**
  String get lowDataCallsSub;

  /// No description provided for @devicesArtInfo.
  ///
  /// In ko, this message translates to:
  /// **'PC나 다른 휴대폰에서도 대화를 이어 볼 수 있어요.'**
  String get devicesArtInfo;

  /// No description provided for @addDevice.
  ///
  /// In ko, this message translates to:
  /// **'기기 추가'**
  String get addDevice;

  /// No description provided for @addDeviceTitle.
  ///
  /// In ko, this message translates to:
  /// **'다른 기기에서 쓰기'**
  String get addDeviceTitle;

  /// No description provided for @addDeviceStep1.
  ///
  /// In ko, this message translates to:
  /// **'새 기기에 부루미를 설치해요. PC는 Windows 앱이 있어요.'**
  String get addDeviceStep1;

  /// No description provided for @addDeviceStep2.
  ///
  /// In ko, this message translates to:
  /// **'내 아이디와 비밀번호로 로그인해요.'**
  String get addDeviceStep2;

  /// No description provided for @addDeviceStep3.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에 뜨는 확인 요청에서 두 기기의 이모지가 같은지 보면 끝이에요. 그러면 지난 대화도 열려요.'**
  String get addDeviceStep3;

  /// No description provided for @devicesPlatforms.
  ///
  /// In ko, this message translates to:
  /// **'부루미는 iPhone, Android, Windows에서 쓸 수 있어요.'**
  String get devicesPlatforms;

  /// No description provided for @onlineNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 사용 중'**
  String get onlineNow;

  /// No description provided for @chatFolders.
  ///
  /// In ko, this message translates to:
  /// **'대화방 폴더'**
  String get chatFolders;

  /// No description provided for @foldersArtInfo.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 만들어 대화방을 나눠 보세요. 목록 위나 왼쪽 메뉴에서 바로 바꿀 수 있어요.'**
  String get foldersArtInfo;

  /// No description provided for @createFolder.
  ///
  /// In ko, this message translates to:
  /// **'폴더 만들기'**
  String get createFolder;

  /// No description provided for @allChatsFolder.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화방'**
  String get allChatsFolder;

  /// No description provided for @editList.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get editList;

  /// No description provided for @foldersEditInfo.
  ///
  /// In ko, this message translates to:
  /// **'편집을 누르면 폴더 순서를 바꾸거나 지울 수 있어요.'**
  String get foldersEditInfo;

  /// No description provided for @recommendedFolders.
  ///
  /// In ko, this message translates to:
  /// **'추천 폴더'**
  String get recommendedFolders;

  /// No description provided for @folderUnreadName.
  ///
  /// In ko, this message translates to:
  /// **'안 읽음'**
  String get folderUnreadName;

  /// No description provided for @folderUnreadInfo.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 메시지가 있는 대화방'**
  String get folderUnreadInfo;

  /// No description provided for @folderPersonalName.
  ///
  /// In ko, this message translates to:
  /// **'개인'**
  String get folderPersonalName;

  /// No description provided for @folderPersonalInfo.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화방만'**
  String get folderPersonalInfo;

  /// No description provided for @folderTags.
  ///
  /// In ko, this message translates to:
  /// **'폴더 태그 표시'**
  String get folderTags;

  /// No description provided for @folderTagsInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록에서 각 대화방 아래에 폴더 이름을 색깔 태그로 보여 줘요.'**
  String get folderTagsInfo;

  /// No description provided for @folderChatsCount.
  ///
  /// In ko, this message translates to:
  /// **'대화방 {n}개'**
  String folderChatsCount(int n);

  /// No description provided for @folderDeleted.
  ///
  /// In ko, this message translates to:
  /// **'폴더를 지웠어요'**
  String get folderDeleted;

  /// No description provided for @folderInclude.
  ///
  /// In ko, this message translates to:
  /// **'포함할 대화방'**
  String get folderInclude;

  /// No description provided for @folderIncludeInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에 보일 대화방이나 대화방 유형을 고르세요.'**
  String get folderIncludeInfo;

  /// No description provided for @folderExclude.
  ///
  /// In ko, this message translates to:
  /// **'제외할 대화방'**
  String get folderExclude;

  /// No description provided for @folderExcludeInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에 절대 보이지 않을 대화방이나 유형을 고르세요.'**
  String get folderExcludeInfo;

  /// No description provided for @folderAddChats.
  ///
  /// In ko, this message translates to:
  /// **'대화방 추가'**
  String get folderAddChats;

  /// No description provided for @folderColor.
  ///
  /// In ko, this message translates to:
  /// **'폴더 색상'**
  String get folderColor;

  /// No description provided for @folderNoTag.
  ///
  /// In ko, this message translates to:
  /// **'태그 없음'**
  String get folderNoTag;

  /// No description provided for @folderColorInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록에서 이 폴더 태그의 색이에요.'**
  String get folderColorInfo;

  /// No description provided for @folderNeedChats.
  ///
  /// In ko, this message translates to:
  /// **'대화방을 하나 이상 넣어 주세요.'**
  String get folderNeedChats;

  /// No description provided for @folderNeedName.
  ///
  /// In ko, this message translates to:
  /// **'폴더 이름을 적어 주세요.'**
  String get folderNeedName;

  /// No description provided for @chatTypes.
  ///
  /// In ko, this message translates to:
  /// **'대화방 유형'**
  String get chatTypes;

  /// No description provided for @chatsHeader.
  ///
  /// In ko, this message translates to:
  /// **'대화방'**
  String get chatsHeader;

  /// No description provided for @kindContacts.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get kindContacts;

  /// No description provided for @kindNonContacts.
  ///
  /// In ko, this message translates to:
  /// **'연락처 아닌 사람'**
  String get kindNonContacts;

  /// No description provided for @kindMuted.
  ///
  /// In ko, this message translates to:
  /// **'알림 꺼짐'**
  String get kindMuted;

  /// No description provided for @kindRead.
  ///
  /// In ko, this message translates to:
  /// **'읽음'**
  String get kindRead;

  /// No description provided for @kindArchived.
  ///
  /// In ko, this message translates to:
  /// **'보관됨'**
  String get kindArchived;

  /// No description provided for @folderIcon.
  ///
  /// In ko, this message translates to:
  /// **'폴더 아이콘'**
  String get folderIcon;

  /// No description provided for @folderIconNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get folderIconNone;

  /// No description provided for @folderIconFavourites.
  ///
  /// In ko, this message translates to:
  /// **'폴더용 추천'**
  String get folderIconFavourites;

  /// No description provided for @folderIconOnly.
  ///
  /// In ko, this message translates to:
  /// **'아이콘만 보기'**
  String get folderIconOnly;

  /// No description provided for @folderIconOnlyInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록 위 폴더 탭에 이름 없이 이모지만 보여요.'**
  String get folderIconOnlyInfo;

  /// No description provided for @newFolderTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 폴더'**
  String get newFolderTitle;

  /// No description provided for @exceptionsCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 예외'**
  String exceptionsCount(int n);

  /// No description provided for @inAppHeader.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 알림'**
  String get inAppHeader;

  /// No description provided for @inAppVibrate.
  ///
  /// In ko, this message translates to:
  /// **'앱 사용 중 진동'**
  String get inAppVibrate;

  /// No description provided for @lockName.
  ///
  /// In ko, this message translates to:
  /// **'잠금 화면에 이름 보이기'**
  String get lockName;

  /// No description provided for @lockNameInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 휴대폰이 잠겨 있을 때 알림에 보낸 사람 이름과 내용이 가려져요. 아이폰은 iOS 설정 > 알림 > 미리보기 표시도 함께 확인해 주세요.'**
  String get lockNameInfo;

  /// No description provided for @linkOpenTitle.
  ///
  /// In ko, this message translates to:
  /// **'링크 열기'**
  String get linkOpenTitle;

  /// No description provided for @linkOpenHeader.
  ///
  /// In ko, this message translates to:
  /// **'링크를 여는 곳'**
  String get linkOpenHeader;

  /// No description provided for @linkOpenInApp.
  ///
  /// In ko, this message translates to:
  /// **'부루미 안에서 (개인정보 보호 창)'**
  String get linkOpenInApp;

  /// No description provided for @linkOpenBrowser.
  ///
  /// In ko, this message translates to:
  /// **'기본 브라우저'**
  String get linkOpenBrowser;

  /// No description provided for @linkOpenInAppShort.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get linkOpenInAppShort;

  /// No description provided for @linkOpenBrowserShort.
  ///
  /// In ko, this message translates to:
  /// **'브라우저'**
  String get linkOpenBrowserShort;

  /// No description provided for @linkOpenInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미 안에서 열면 앱을 떠나지 않고, 다른 브라우저의 기록에도 남지 않아요.'**
  String get linkOpenInfo;

  /// No description provided for @linkNeverHeader.
  ///
  /// In ko, this message translates to:
  /// **'앱 안에서 열지 않기'**
  String get linkNeverHeader;

  /// No description provided for @linkNeverAdd.
  ///
  /// In ko, this message translates to:
  /// **'웹사이트 추가'**
  String get linkNeverAdd;

  /// No description provided for @linkNeverInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 웹사이트들은 언제나 기본 브라우저에서 열려요.'**
  String get linkNeverInfo;

  /// No description provided for @tiltMove.
  ///
  /// In ko, this message translates to:
  /// **'기울이면 움직이기'**
  String get tiltMove;

  /// No description provided for @tiltInfo.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 기울이면 대화 배경이 살짝 움직여요. 배터리를 조금 더 써요.'**
  String get tiltInfo;

  /// No description provided for @appIcon.
  ///
  /// In ko, this message translates to:
  /// **'앱 아이콘'**
  String get appIcon;

  /// No description provided for @appIconInfo.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면의 부루미 아이콘 모양을 바꿔요. 바꿀 때 앱이 잠깐 닫힐 수 있어요.'**
  String get appIconInfo;

  /// No description provided for @appIconGreen.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get appIconGreen;

  /// No description provided for @appIconDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get appIconDark;

  /// No description provided for @appIconLight.
  ///
  /// In ko, this message translates to:
  /// **'화이트'**
  String get appIconLight;

  /// No description provided for @appIconMint.
  ///
  /// In ko, this message translates to:
  /// **'세이지'**
  String get appIconMint;

  /// No description provided for @psGlass.
  ///
  /// In ko, this message translates to:
  /// **'유리 효과'**
  String get psGlass;

  /// No description provided for @psGlassSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 위·아래 바가 비치지 않는 판으로 보여요.'**
  String get psGlassSub;

  /// No description provided for @psPreload.
  ///
  /// In ko, this message translates to:
  /// **'미디어 미리 받기'**
  String get psPreload;

  /// No description provided for @psPreloadSub.
  ///
  /// In ko, this message translates to:
  /// **'사진·영상을 열기 전에 미리 받아 둬요.'**
  String get psPreloadSub;

  /// No description provided for @psTiltSub.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 기울이면 대화 배경이 움직여요.'**
  String get psTiltSub;

  /// No description provided for @chatsMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get chatsMessages;

  /// No description provided for @chatsList.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록'**
  String get chatsList;

  /// No description provided for @chatsMediaReactions.
  ///
  /// In ko, this message translates to:
  /// **'미디어와 반응'**
  String get chatsMediaReactions;

  /// No description provided for @formattingRow.
  ///
  /// In ko, this message translates to:
  /// **'형식이 지정된 메시지'**
  String get formattingRow;

  /// No description provided for @formattingSub.
  ///
  /// In ko, this message translates to:
  /// **'굵게 같은 서식을 메시지에 보여 줘요'**
  String get formattingSub;

  /// No description provided for @listMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진·동영상 미리보기 보이기'**
  String get listMedia;

  /// No description provided for @listMediaSub.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록에 마지막 사진을 작게 보여 줘요'**
  String get listMediaSub;

  /// No description provided for @scamWarningSub.
  ///
  /// In ko, this message translates to:
  /// **'이상한 링크에 경고를 붙여요'**
  String get scamWarningSub;

  /// No description provided for @planPick.
  ///
  /// In ko, this message translates to:
  /// **'일정 뽑기'**
  String get planPick;

  /// No description provided for @planPickSub.
  ///
  /// In ko, this message translates to:
  /// **'메시지 속 날짜·시간을 누르면 알림을 맞춰요'**
  String get planPickSub;

  /// No description provided for @aiOnPhoneInfo.
  ///
  /// In ko, this message translates to:
  /// **'모두 이 휴대폰 안에서만 처리돼요. 메시지 내용은 어디로도 보내지 않아요.'**
  String get aiOnPhoneInfo;

  /// No description provided for @planFound.
  ///
  /// In ko, this message translates to:
  /// **'일정: {when}'**
  String planFound(String when);

  /// No description provided for @planHourBefore.
  ///
  /// In ko, this message translates to:
  /// **'1시간 전에 알림'**
  String get planHourBefore;

  /// No description provided for @planAtTime.
  ///
  /// In ko, this message translates to:
  /// **'그 시각에 알림'**
  String get planAtTime;

  /// No description provided for @checkSectionTodo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get checkSectionTodo;

  /// No description provided for @archiveToMenu.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 메뉴로'**
  String get archiveToMenu;

  /// No description provided for @archiveMovedTitle.
  ///
  /// In ko, this message translates to:
  /// **'보관함을 왼쪽 메뉴로 옮겼어요'**
  String get archiveMovedTitle;

  /// No description provided for @archiveMovedBody.
  ///
  /// In ko, this message translates to:
  /// **'왼쪽 위 메뉴 버튼을 누르면 보여요.'**
  String get archiveMovedBody;

  /// No description provided for @archivePinnedTitle.
  ///
  /// In ko, this message translates to:
  /// **'보관함을 대화 목록에 고정했어요'**
  String get archivePinnedTitle;

  /// No description provided for @archivePinnedBody.
  ///
  /// In ko, this message translates to:
  /// **'다시 옮기려면 왼쪽으로 끝까지 밀어요.'**
  String get archivePinnedBody;

  /// No description provided for @archivePinBack.
  ///
  /// In ko, this message translates to:
  /// **'목록에 고정'**
  String get archivePinBack;

  /// No description provided for @menuStories.
  ///
  /// In ko, this message translates to:
  /// **'스토리'**
  String get menuStories;

  /// No description provided for @storiesMovedTitle.
  ///
  /// In ko, this message translates to:
  /// **'스토리를 왼쪽 메뉴로 옮겼어요'**
  String get storiesMovedTitle;

  /// No description provided for @bubblesMovedTitle.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울을 왼쪽 메뉴로 옮겼어요'**
  String get bubblesMovedTitle;

  /// No description provided for @storiesPinnedTitle.
  ///
  /// In ko, this message translates to:
  /// **'스토리를 대화 목록에 고정했어요'**
  String get storiesPinnedTitle;

  /// No description provided for @bubblesPinnedTitle.
  ///
  /// In ko, this message translates to:
  /// **'비눗방울을 대화 목록에 고정했어요'**
  String get bubblesPinnedTitle;

  /// No description provided for @trustOfficial.
  ///
  /// In ko, this message translates to:
  /// **'공식 계정'**
  String get trustOfficial;

  /// No description provided for @trustOfficialInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미가 확인한 공식 계정이에요'**
  String get trustOfficialInfo;

  /// No description provided for @trustChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인 중'**
  String get trustChecking;

  /// No description provided for @trustFake.
  ///
  /// In ko, this message translates to:
  /// **'가짜'**
  String get trustFake;

  /// No description provided for @trustNotOfficial.
  ///
  /// In ko, this message translates to:
  /// **'{name} 공식 계정이 아니에요'**
  String trustNotOfficial(String name);

  /// No description provided for @trustCheckingInfo.
  ///
  /// In ko, this message translates to:
  /// **'사칭 신고가 여러 번 들어와서 운영자가 확인하고 있어요'**
  String get trustCheckingInfo;

  /// No description provided for @trustFakeInfo.
  ///
  /// In ko, this message translates to:
  /// **'운영자가 확인한 사칭 계정이에요. 돈이나 인증번호를 보내지 마세요'**
  String get trustFakeInfo;

  /// No description provided for @firstTitle.
  ///
  /// In ko, this message translates to:
  /// **'처음 메시지를 보낸 사람이에요'**
  String get firstTitle;

  /// No description provided for @firstJoined.
  ///
  /// In ko, this message translates to:
  /// **'가입'**
  String get firstJoined;

  /// No description provided for @ageWeek.
  ///
  /// In ko, this message translates to:
  /// **'7일 안'**
  String get ageWeek;

  /// No description provided for @ageMonth.
  ///
  /// In ko, this message translates to:
  /// **'한 달 안'**
  String get ageMonth;

  /// No description provided for @ageYear.
  ///
  /// In ko, this message translates to:
  /// **'1년 안'**
  String get ageYear;

  /// No description provided for @ageOlder.
  ///
  /// In ko, this message translates to:
  /// **'1년 넘음'**
  String get ageOlder;

  /// No description provided for @ageUnknown.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없음'**
  String get ageUnknown;

  /// No description provided for @firstRenamed.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get firstRenamed;

  /// No description provided for @firstRenamedRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일 안에 바꿨어요'**
  String get firstRenamedRecent;

  /// No description provided for @firstRenamedNo.
  ///
  /// In ko, this message translates to:
  /// **'최근엔 없어요'**
  String get firstRenamedNo;

  /// No description provided for @firstCommon.
  ///
  /// In ko, this message translates to:
  /// **'함께 있는 대화방'**
  String get firstCommon;

  /// No description provided for @firstCommonCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String firstCommonCount(int count);

  /// No description provided for @firstVerified.
  ///
  /// In ko, this message translates to:
  /// **'공식 인증'**
  String get firstVerified;

  /// No description provided for @firstVerifiedYes.
  ///
  /// In ko, this message translates to:
  /// **'됨'**
  String get firstVerifiedYes;

  /// No description provided for @firstVerifiedNo.
  ///
  /// In ko, this message translates to:
  /// **'안 됨'**
  String get firstVerifiedNo;

  /// No description provided for @firstTip.
  ///
  /// In ko, this message translates to:
  /// **'아는 사람이 아니면 돈, 인증번호, 비밀번호를 보내지 마세요.'**
  String get firstTip;

  /// No description provided for @firstAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get firstAccept;

  /// No description provided for @firstBlock.
  ///
  /// In ko, this message translates to:
  /// **'차단'**
  String get firstBlock;

  /// No description provided for @firstReport.
  ///
  /// In ko, this message translates to:
  /// **'신고'**
  String get firstReport;

  /// No description provided for @firstMediaHidden.
  ///
  /// In ko, this message translates to:
  /// **'수락하면 보여요'**
  String get firstMediaHidden;

  /// No description provided for @reportImpersonation.
  ///
  /// In ko, this message translates to:
  /// **'사칭이에요'**
  String get reportImpersonation;

  /// No description provided for @reportImpTitle.
  ///
  /// In ko, this message translates to:
  /// **'사칭 신고'**
  String get reportImpTitle;

  /// No description provided for @reportImpInfo.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람인 척하는 계정을 알려 주세요. 프로필만 운영자에게 가고, 대화 내용은 가지 않아요.'**
  String get reportImpInfo;

  /// No description provided for @reportImpWho.
  ///
  /// In ko, this message translates to:
  /// **'누구인 척하나요?'**
  String get reportImpWho;

  /// No description provided for @reportImpWhoHint.
  ///
  /// In ko, this message translates to:
  /// **'이름 또는 ID'**
  String get reportImpWhoHint;

  /// No description provided for @reportImpNote.
  ///
  /// In ko, this message translates to:
  /// **'더 알려 줄 내용 (선택)'**
  String get reportImpNote;

  /// No description provided for @reportImpSend.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportImpSend;

  /// No description provided for @reportImpDone.
  ///
  /// In ko, this message translates to:
  /// **'신고했어요. 운영자가 확인할게요'**
  String get reportImpDone;

  /// No description provided for @badgeRow.
  ///
  /// In ko, this message translates to:
  /// **'공식 배지'**
  String get badgeRow;

  /// No description provided for @badgeTitle.
  ///
  /// In ko, this message translates to:
  /// **'공식 배지'**
  String get badgeTitle;

  /// No description provided for @badgeInfo.
  ///
  /// In ko, this message translates to:
  /// **'유명인, 회사, 큰 채널이 사칭을 막을 수 있게 이름 옆에 배지를 붙여요. 신분증은 받지 않아요.'**
  String get badgeInfo;

  /// No description provided for @badgeStep.
  ///
  /// In ko, this message translates to:
  /// **'아래 확인 문구를 공식 인스타그램·유튜브·홈페이지에 잠깐 올리거나 회사 메일 주소로 보내고, 올린 곳 주소를 적어 주세요.'**
  String get badgeStep;

  /// No description provided for @badgeCode.
  ///
  /// In ko, this message translates to:
  /// **'확인 문구'**
  String get badgeCode;

  /// No description provided for @badgeCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get badgeCopy;

  /// No description provided for @badgeCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get badgeCopied;

  /// No description provided for @badgeKind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get badgeKind;

  /// No description provided for @badgeKindPerson.
  ///
  /// In ko, this message translates to:
  /// **'사람'**
  String get badgeKindPerson;

  /// No description provided for @badgeKindBrand.
  ///
  /// In ko, this message translates to:
  /// **'회사·브랜드'**
  String get badgeKindBrand;

  /// No description provided for @badgeKindChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get badgeKindChannel;

  /// No description provided for @badgeName.
  ///
  /// In ko, this message translates to:
  /// **'배지에 쓸 이름'**
  String get badgeName;

  /// No description provided for @badgeProof.
  ///
  /// In ko, this message translates to:
  /// **'문구를 올린 곳 (주소 또는 메일)'**
  String get badgeProof;

  /// No description provided for @badgeSend.
  ///
  /// In ko, this message translates to:
  /// **'신청하기'**
  String get badgeSend;

  /// No description provided for @badgeSent.
  ///
  /// In ko, this message translates to:
  /// **'신청했어요. 확인되면 이름 옆에 배지가 붙어요.'**
  String get badgeSent;

  /// No description provided for @badgeHave.
  ///
  /// In ko, this message translates to:
  /// **'공식 배지가 있어요'**
  String get badgeHave;

  /// No description provided for @badgeRenameNote.
  ///
  /// In ko, this message translates to:
  /// **'이름을 바꾸면 배지가 꺼지고 다시 확인해요.'**
  String get badgeRenameNote;

  /// No description provided for @badgeFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 신청할 수 없어요. 잠시 뒤에 다시 해 주세요.'**
  String get badgeFailed;

  /// No description provided for @nameMarkRefused.
  ///
  /// In ko, this message translates to:
  /// **'이름에 체크 표시는 넣을 수 없어요'**
  String get nameMarkRefused;

  /// No description provided for @nameReservedRefused.
  ///
  /// In ko, this message translates to:
  /// **'공식 계정만 쓸 수 있는 말이 들어 있어요'**
  String get nameReservedRefused;

  /// No description provided for @idReservedRefused.
  ///
  /// In ko, this message translates to:
  /// **'이 ID는 예약돼 있어요. 진짜 주인이면 가입한 뒤 공식 배지를 신청해 주세요.'**
  String get idReservedRefused;

  /// No description provided for @idLookalikeRefused.
  ///
  /// In ko, this message translates to:
  /// **'공식 계정과 너무 비슷한 ID예요. 다른 ID를 써 주세요.'**
  String get idLookalikeRefused;

  /// No description provided for @accountsAdd.
  ///
  /// In ko, this message translates to:
  /// **'계정 추가'**
  String get accountsAdd;

  /// No description provided for @accountsLimitTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정을 더 쓰려면'**
  String get accountsLimitTitle;

  /// No description provided for @accountsLimitInfo.
  ///
  /// In ko, this message translates to:
  /// **'계정 1개는 무료예요. 2번째 계정은 Plus에 들어 있고, 3번째 계정은 따로 살 수 있어요. 결제는 출시 후에 열려요.'**
  String get accountsLimitInfo;

  /// No description provided for @accountsAlready.
  ///
  /// In ko, this message translates to:
  /// **'이미 이 휴대폰에 있는 계정이에요'**
  String get accountsAlready;

  /// No description provided for @accountPassword.
  ///
  /// In ko, this message translates to:
  /// **'계정 삭제 비밀번호'**
  String get accountPassword;

  /// No description provided for @accountPasswordInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 비밀번호로 열면 고른 계정이 이 휴대폰에서 조용히 사라지고, 남은 계정만 열려요. 서버의 계정은 그대로라 친구에게는 아무것도 보이지 않아요. 나중에 아이디와 백업 비밀번호로 다시 로그인할 수 있어요.'**
  String get accountPasswordInfo;

  /// No description provided for @accountEraseList.
  ///
  /// In ko, this message translates to:
  /// **'지울 계정'**
  String get accountEraseList;

  /// No description provided for @accountEraseListInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 계정을 고를 수는 없어요. 하나는 남아야 해요.'**
  String get accountEraseListInfo;

  /// No description provided for @editFirstWords.
  ///
  /// In ko, this message translates to:
  /// **'처음 보낸 글'**
  String get editFirstWords;

  /// No description provided for @reportIllegal.
  ///
  /// In ko, this message translates to:
  /// **'불법 촬영물·성착취물 (합성 포함)'**
  String get reportIllegal;

  /// No description provided for @reportHiddenNow.
  ///
  /// In ko, this message translates to:
  /// **'신고가 모여 이 글은 모든 사람에게 가려졌어요'**
  String get reportHiddenNow;

  /// No description provided for @reportHiddenLine.
  ///
  /// In ko, this message translates to:
  /// **'신고나 자동 검사로 가려진 글이에요. 운영자가 확인하고 있어요.'**
  String get reportHiddenLine;

  /// No description provided for @guardNotice.
  ///
  /// In ko, this message translates to:
  /// **'공개방이에요. 누구나 들어올 수 있어서, 운영자의 공개방 지킴이가 불법 사진과 스팸을 걸러요. 1:1 대화와 비공개 방은 그대로 종단간 암호화돼요.'**
  String get guardNotice;

  /// No description provided for @newMediaWait.
  ///
  /// In ko, this message translates to:
  /// **'이 방은 들어온 지 {days}일이 지나야 사진·영상·링크를 보낼 수 있어요'**
  String newMediaWait(int days);

  /// No description provided for @newMediaHidden.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버가 보낸 사진·영상·링크는 가려져요'**
  String get newMediaHidden;

  /// No description provided for @newMediaTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버 사진·영상·링크 제한'**
  String get newMediaTitle;

  /// No description provided for @newMediaInfo.
  ///
  /// In ko, this message translates to:
  /// **'방에 들어온 지 얼마 안 된 사람은 글만 쓸 수 있어요. 자동 계정이 들어와 나쁜 사진을 올리는 걸 막아요.'**
  String get newMediaInfo;

  /// No description provided for @newMediaFooter.
  ///
  /// In ko, this message translates to:
  /// **'방장·관리자는 제한이 없어요. 제한 기간에 올라온 사진·영상·링크는 다른 멤버에게 가려져요. 공개방은 처음부터 7일로 켜져 있어요.'**
  String get newMediaFooter;

  /// No description provided for @newMediaDays.
  ///
  /// In ko, this message translates to:
  /// **'{days}일'**
  String newMediaDays(int days);

  /// No description provided for @toolsSafety.
  ///
  /// In ko, this message translates to:
  /// **'안전'**
  String get toolsSafety;

  /// No description provided for @toolsSafetyInfo.
  ///
  /// In ko, this message translates to:
  /// **'예전 글을 몰래 고쳐 나쁜 사진을 숨기고 앱을 신고하는 협박 공격을 막아요.'**
  String get toolsSafetyInfo;

  /// No description provided for @lateEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'늦게 수정된 글'**
  String get lateEditTitle;

  /// No description provided for @lateEditInfo.
  ///
  /// In ko, this message translates to:
  /// **'보낸 지 1시간이 지난 글을 누가 고치면 여기에 모여요. 그룹·채널의 글은 24시간이 지나면 고칠 수 없고, 사진·영상은 수정으로 바꿀 수 없어요.'**
  String get lateEditInfo;

  /// No description provided for @lateEditEmpty.
  ///
  /// In ko, this message translates to:
  /// **'늦게 수정된 글이 없어요'**
  String get lateEditEmpty;

  /// No description provided for @lateEditLine.
  ///
  /// In ko, this message translates to:
  /// **'처음: {first}\n지금: {now}\n보냄 {sent} · 수정 {edited}'**
  String lateEditLine(String first, String now, String sent, String edited);

  /// No description provided for @lateEditBanner.
  ///
  /// In ko, this message translates to:
  /// **'오래된 글 {count}개가 수정됐어요'**
  String lateEditBanner(int count);

  /// No description provided for @extortionRow.
  ///
  /// In ko, this message translates to:
  /// **'협박받았어요'**
  String get extortionRow;

  /// No description provided for @extortionTitle.
  ///
  /// In ko, this message translates to:
  /// **'협박 신고'**
  String get extortionTitle;

  /// No description provided for @extortionInfo.
  ///
  /// In ko, this message translates to:
  /// **'\"돈을 안 보내면 방을 신고하겠다\" 같은 연락을 받았나요? 돈을 보내지 마세요. 운영자에게 알리면 그 계정을 막고, 이 방에 올라오는 불법 글을 먼저 살펴볼게요. 위험하면 경찰(112)에도 신고해 주세요.'**
  String get extortionInfo;

  /// No description provided for @extortionWho.
  ///
  /// In ko, this message translates to:
  /// **'협박한 사람'**
  String get extortionWho;

  /// No description provided for @extortionWhoHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디 (예: @abc)'**
  String get extortionWhoHint;

  /// No description provided for @extortionNote.
  ///
  /// In ko, this message translates to:
  /// **'받은 말'**
  String get extortionNote;

  /// No description provided for @extortionNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'받은 말을 그대로 붙여 넣어 주세요'**
  String get extortionNoteHint;

  /// No description provided for @extortionSend.
  ///
  /// In ko, this message translates to:
  /// **'운영자에게 보내기'**
  String get extortionSend;

  /// No description provided for @extortionDone.
  ///
  /// In ko, this message translates to:
  /// **'운영자에게 보냈어요. 돈은 보내지 마세요.'**
  String get extortionDone;

  /// No description provided for @wipeUser.
  ///
  /// In ko, this message translates to:
  /// **'글 모두 지우고 내보내기'**
  String get wipeUser;

  /// No description provided for @logLateEdit.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 오래된 글을 수정함'**
  String logLateEdit(String name);

  /// No description provided for @logWiped.
  ///
  /// In ko, this message translates to:
  /// **'{name}님의 글 {count}개를 지우고 내보냄'**
  String logWiped(String name, int count);

  /// No description provided for @logExtortion.
  ///
  /// In ko, this message translates to:
  /// **'협박 신고함 ({name})'**
  String logExtortion(String name);

  /// No description provided for @linkTitle.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크'**
  String get linkTitle;

  /// No description provided for @linkKind.
  ///
  /// In ko, this message translates to:
  /// **'링크 종류'**
  String get linkKind;

  /// No description provided for @linkPrivate.
  ///
  /// In ko, this message translates to:
  /// **'비공개 링크'**
  String get linkPrivate;

  /// No description provided for @linkPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개 주소'**
  String get linkPublic;

  /// No description provided for @linkPrivateInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 받은 사람만 들어올 수 있어요. 링크 속 코드는 서버에 남지 않아요.'**
  String get linkPrivateInfo;

  /// No description provided for @linkPublicInfo.
  ///
  /// In ko, this message translates to:
  /// **'누구나 주소로 들어올 수 있어요. 링크를 붙이면 카드에 이름과 소개가 보여요.'**
  String get linkPublicInfo;

  /// No description provided for @linkAddress.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get linkAddress;

  /// No description provided for @linkChecking.
  ///
  /// In ko, this message translates to:
  /// **'확인하는 중…'**
  String get linkChecking;

  /// No description provided for @linkFree.
  ///
  /// In ko, this message translates to:
  /// **'쓸 수 있는 주소예요'**
  String get linkFree;

  /// No description provided for @linkTaken.
  ///
  /// In ko, this message translates to:
  /// **'이미 쓰고 있는 주소예요'**
  String get linkTaken;

  /// No description provided for @linkBadAddress.
  ///
  /// In ko, this message translates to:
  /// **'영문 소문자로 시작해 5~32자로 써 주세요. 숫자와 _도 쓸 수 있어요.'**
  String get linkBadAddress;

  /// No description provided for @linkReserved.
  ///
  /// In ko, this message translates to:
  /// **'쓸 수 없는 단어가 들어 있어요'**
  String get linkReserved;

  /// No description provided for @linkShare.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get linkShare;

  /// No description provided for @linkShareText.
  ///
  /// In ko, this message translates to:
  /// **'같이 들어와요'**
  String get linkShareText;

  /// No description provided for @linkApproval.
  ///
  /// In ko, this message translates to:
  /// **'승인 후 참여'**
  String get linkApproval;

  /// No description provided for @linkApprovalInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 링크로 온 사람이 가입 요청을 보내고, 관리자가 받아 줘야 들어와요.'**
  String get linkApprovalInfo;

  /// No description provided for @linkReset.
  ///
  /// In ko, this message translates to:
  /// **'새 링크 만들기'**
  String get linkReset;

  /// No description provided for @linkResetInfo.
  ///
  /// In ko, this message translates to:
  /// **'지금 링크는 더 이상 쓸 수 없어요. 새 링크를 다시 보내 주세요.'**
  String get linkResetInfo;

  /// No description provided for @linkFailed.
  ///
  /// In ko, this message translates to:
  /// **'링크를 바꾸지 못했어요. 잠시 뒤 다시 해 주세요.'**
  String get linkFailed;

  /// No description provided for @joinRequests.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청'**
  String get joinRequests;

  /// No description provided for @joinRequestsNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 가입 요청이 없어요'**
  String get joinRequestsNone;

  /// No description provided for @joinRequestsInfo.
  ///
  /// In ko, this message translates to:
  /// **'받으면 바로 들어와요. 거절해도 상대에게 따로 알리지 않아요.'**
  String get joinRequestsInfo;

  /// No description provided for @joinAccept.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get joinAccept;

  /// No description provided for @joinDecline.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get joinDecline;

  /// No description provided for @posterMake.
  ///
  /// In ko, this message translates to:
  /// **'홍보 이미지 만들기'**
  String get posterMake;

  /// No description provided for @posterTitle.
  ///
  /// In ko, this message translates to:
  /// **'홍보 이미지'**
  String get posterTitle;

  /// No description provided for @posterTall.
  ///
  /// In ko, this message translates to:
  /// **'세로'**
  String get posterTall;

  /// No description provided for @posterSquare.
  ///
  /// In ko, this message translates to:
  /// **'정사각'**
  String get posterSquare;

  /// No description provided for @posterColor.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get posterColor;

  /// No description provided for @posterSave.
  ///
  /// In ko, this message translates to:
  /// **'사진에 저장'**
  String get posterSave;

  /// No description provided for @posterSaved.
  ///
  /// In ko, this message translates to:
  /// **'사진에 저장했어요'**
  String get posterSaved;

  /// No description provided for @posterScan.
  ///
  /// In ko, this message translates to:
  /// **'카메라로 찍으면 바로 들어와요'**
  String get posterScan;

  /// No description provided for @posterInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 새로 만들면 예전 이미지의 QR은 더 이상 열리지 않아요.'**
  String get posterInfo;

  /// No description provided for @webPage.
  ///
  /// In ko, this message translates to:
  /// **'공개 웹페이지'**
  String get webPage;

  /// No description provided for @webPageInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 이제부터 올리는 글이 웹페이지에 보여요. 웹페이지 글은 암호화되지 않고, 검색에 나올 수 있어요. 끄면 웹페이지 글을 모두 내려요.'**
  String get webPageInfo;

  /// No description provided for @webPageNeedsPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개 주소로 바꾸면 켤 수 있어요.'**
  String get webPageNeedsPublic;

  /// No description provided for @webPageAddress.
  ///
  /// In ko, this message translates to:
  /// **'웹페이지 주소'**
  String get webPageAddress;

  /// No description provided for @webPageOn.
  ///
  /// In ko, this message translates to:
  /// **'웹페이지를 켤까요?'**
  String get webPageOn;

  /// No description provided for @webPageOnBody.
  ///
  /// In ko, this message translates to:
  /// **'이제부터 올리는 글과 사진은 암호화 밖으로 나가서 누구나 볼 수 있어요. 예전 글은 올라가지 않아요.'**
  String get webPageOnBody;

  /// No description provided for @webPageTurnOn.
  ///
  /// In ko, this message translates to:
  /// **'켜기'**
  String get webPageTurnOn;

  /// No description provided for @joinByLink.
  ///
  /// In ko, this message translates to:
  /// **'링크로 들어가기'**
  String get joinByLink;

  /// No description provided for @joinByLinkHint.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 붙여 넣기'**
  String get joinByLinkHint;

  /// No description provided for @joinByLinkBad.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크가 아니에요'**
  String get joinByLinkBad;

  /// No description provided for @joinPublicChannel.
  ///
  /// In ko, this message translates to:
  /// **'공개 채널'**
  String get joinPublicChannel;

  /// No description provided for @joinPublicGroup.
  ///
  /// In ko, this message translates to:
  /// **'공개 그룹'**
  String get joinPublicGroup;

  /// No description provided for @joinPrivateChannel.
  ///
  /// In ko, this message translates to:
  /// **'비공개 채널'**
  String get joinPrivateChannel;

  /// No description provided for @joinPrivateGroup.
  ///
  /// In ko, this message translates to:
  /// **'비공개 그룹'**
  String get joinPrivateGroup;

  /// No description provided for @joinSubscribe.
  ///
  /// In ko, this message translates to:
  /// **'구독하기'**
  String get joinSubscribe;

  /// No description provided for @joinGroup.
  ///
  /// In ko, this message translates to:
  /// **'참여하기'**
  String get joinGroup;

  /// No description provided for @joinAsk.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청 보내기'**
  String get joinAsk;

  /// No description provided for @joinAsked.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청을 보냈어요. 관리자가 받아 주면 들어가요.'**
  String get joinAsked;

  /// No description provided for @joinPrivateNote.
  ///
  /// In ko, this message translates to:
  /// **'들어가기 전에는 멤버 수와 소개를 볼 수 없어요.'**
  String get joinPrivateNote;

  /// No description provided for @joinNotFound.
  ///
  /// In ko, this message translates to:
  /// **'링크가 없거나 새 링크로 바뀌었어요'**
  String get joinNotFound;

  /// No description provided for @joinUnnamed.
  ///
  /// In ko, this message translates to:
  /// **'초대받은 모임'**
  String get joinUnnamed;

  /// No description provided for @remoteWipe.
  ///
  /// In ko, this message translates to:
  /// **'원격 비상 삭제'**
  String get remoteWipe;

  /// No description provided for @remoteWipeInfo.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰을 잃어버리거나 빼앗겼을 때, 내가 고른 믿는 친구가 삭제 코드를 보내면 이 휴대폰의 대화가 조용히 지워져요.'**
  String get remoteWipeInfo;

  /// No description provided for @wipeFriends.
  ///
  /// In ko, this message translates to:
  /// **'믿는 친구'**
  String get wipeFriends;

  /// No description provided for @wipeFriendsPick.
  ///
  /// In ko, this message translates to:
  /// **'친구 고르기 (최대 3명)'**
  String get wipeFriendsPick;

  /// No description provided for @wipeFriendsInfo.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화가 있는 친구만 고를 수 있어요. 친구에게 삭제 코드를 직접 알려 주세요.'**
  String get wipeFriendsInfo;

  /// No description provided for @wipeCode.
  ///
  /// In ko, this message translates to:
  /// **'삭제 코드'**
  String get wipeCode;

  /// No description provided for @wipeCodeChange.
  ///
  /// In ko, this message translates to:
  /// **'삭제 코드 바꾸기'**
  String get wipeCodeChange;

  /// No description provided for @wipeCodeInfo.
  ///
  /// In ko, this message translates to:
  /// **'6자 이상. 코드는 이 휴대폰에 암호처럼 바꿔서만 남고, 서버는 몰라요.'**
  String get wipeCodeInfo;

  /// No description provided for @wipeCodeRule.
  ///
  /// In ko, this message translates to:
  /// **'삭제 코드는 6자 이상으로 정해 주세요'**
  String get wipeCodeRule;

  /// No description provided for @wipeCodeSaved.
  ///
  /// In ko, this message translates to:
  /// **'삭제 코드를 정했어요'**
  String get wipeCodeSaved;

  /// No description provided for @wipeTwo.
  ///
  /// In ko, this message translates to:
  /// **'두 명이 요청해야 삭제'**
  String get wipeTwo;

  /// No description provided for @wipeTwoInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 믿는 친구 두 명이 24시간 안에 코드를 보내야 지워져요.'**
  String get wipeTwoInfo;

  /// No description provided for @wipeLastMsg.
  ///
  /// In ko, this message translates to:
  /// **'마지막 메시지'**
  String get wipeLastMsg;

  /// No description provided for @wipeLastMsgInfo.
  ///
  /// In ko, this message translates to:
  /// **'지우기 직전에 믿는 친구에게 이 글을 보내요. 비워 두면 아무것도 안 보내요.'**
  String get wipeLastMsgInfo;

  /// No description provided for @wipeLastMsgHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 휴대폰을 잃어버렸어요. 새 번호로 연락할게요.'**
  String get wipeLastMsgHint;

  /// No description provided for @savedShort.
  ///
  /// In ko, this message translates to:
  /// **'저장했어요'**
  String get savedShort;

  /// No description provided for @decoyTip.
  ///
  /// In ko, this message translates to:
  /// **'도움말: 평소에 거의 안 쓰는 두 번째 계정(미끼 계정)을 만들어 두면, 누가 억지로 앱을 열게 할 때 그 계정을 보여 줄 수 있어요.'**
  String get decoyTip;

  /// No description provided for @daysN.
  ///
  /// In ko, this message translates to:
  /// **'{n}일'**
  String daysN(int n);

  /// No description provided for @idleWipe.
  ///
  /// In ko, this message translates to:
  /// **'미접속 자동 삭제'**
  String get idleWipe;

  /// No description provided for @idleWipeInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 기간 동안 앱을 한 번도 열지 않으면 다음에 열 때 모든 대화가 먼저 지워져요. 하루 전에 평범한 알림이 와요.'**
  String get idleWipeInfo;

  /// No description provided for @idleReminderTitle.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get idleReminderTitle;

  /// No description provided for @idleReminderBody.
  ///
  /// In ko, this message translates to:
  /// **'오랜만이에요. 한번 열어 볼까요?'**
  String get idleReminderBody;

  /// No description provided for @wipeRequest.
  ///
  /// In ko, this message translates to:
  /// **'비상 삭제 요청'**
  String get wipeRequest;

  /// No description provided for @wipeRequestInfo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 알려 준 삭제 코드를 넣으면 그 휴대폰의 대화가 지워져요. 나를 믿는 친구로 정해 둔 경우에만 돼요.'**
  String wipeRequestInfo(String name);

  /// No description provided for @wipeRequestNote.
  ///
  /// In ko, this message translates to:
  /// **'요청은 끝에서 끝까지 암호화돼 가요. 맞았는지 틀렸는지는 알려 주지 않아요.'**
  String get wipeRequestNote;

  /// No description provided for @wipeRequestSend.
  ///
  /// In ko, this message translates to:
  /// **'지우기 요청 보내기'**
  String get wipeRequestSend;

  /// No description provided for @wipeRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'요청을 보냈어요'**
  String get wipeRequestSent;

  /// No description provided for @wipeTrustOn.
  ///
  /// In ko, this message translates to:
  /// **'비상 삭제 요청할 사람으로 지정'**
  String get wipeTrustOn;

  /// No description provided for @wipeTrustOff.
  ///
  /// In ko, this message translates to:
  /// **'비상 삭제 요청할 사람에서 빼기'**
  String get wipeTrustOff;

  /// No description provided for @wipeTrustAdded.
  ///
  /// In ko, this message translates to:
  /// **'믿는 친구로 정했어요. 설정에서 삭제 코드도 정해 주세요.'**
  String get wipeTrustAdded;

  /// No description provided for @wipeTrustRemoved.
  ///
  /// In ko, this message translates to:
  /// **'믿는 친구에서 뺐어요'**
  String get wipeTrustRemoved;

  /// No description provided for @wipeFriendsFull.
  ///
  /// In ko, this message translates to:
  /// **'믿는 친구는 3명까지예요'**
  String get wipeFriendsFull;

  /// No description provided for @emergencyHeader.
  ///
  /// In ko, this message translates to:
  /// **'잠금과 비상 삭제'**
  String get emergencyHeader;

  /// No description provided for @autoLock.
  ///
  /// In ko, this message translates to:
  /// **'자동 잠금'**
  String get autoLock;

  /// No description provided for @autoLockInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱을 떠난 뒤 이 시간이 지나면 다시 비밀번호를 물어요. 앱 잠금이 켜져 있을 때만 적용돼요.'**
  String get autoLockInfo;

  /// No description provided for @autoLockNow.
  ///
  /// In ko, this message translates to:
  /// **'바로'**
  String get autoLockNow;

  /// No description provided for @autoLock1m.
  ///
  /// In ko, this message translates to:
  /// **'1분 뒤'**
  String get autoLock1m;

  /// No description provided for @autoLock5m.
  ///
  /// In ko, this message translates to:
  /// **'5분 뒤'**
  String get autoLock5m;

  /// No description provided for @autoLock1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간 뒤'**
  String get autoLock1h;

  /// No description provided for @protect.
  ///
  /// In ko, this message translates to:
  /// **'공유 비활성화'**
  String get protect;

  /// No description provided for @protectInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 이 대화방에서는 전달, 저장, 복사가 안 되고 화면 캡처도 막아요. 아이폰은 녹화할 때 화면을 가려요.'**
  String get protectInfo;

  /// No description provided for @protectOn.
  ///
  /// In ko, this message translates to:
  /// **'공유 비활성화 켜기'**
  String get protectOn;

  /// No description provided for @protectOff.
  ///
  /// In ko, this message translates to:
  /// **'공유 비활성화 끄기'**
  String get protectOff;

  /// No description provided for @protectOnDone.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방에서 전달·저장·복사·캡처를 막았어요'**
  String get protectOnDone;

  /// No description provided for @protectOffDone.
  ///
  /// In ko, this message translates to:
  /// **'공유 비활성화를 껐어요'**
  String get protectOffDone;

  /// No description provided for @idReservedOwner.
  ///
  /// In ko, this message translates to:
  /// **'진짜 주인을 위해 맡아 둔 ID예요. 주인이면 \'예약 아이디 받기\'로 받은 코드를 넣어 주세요.'**
  String get idReservedOwner;

  /// No description provided for @roomReservedOwner.
  ///
  /// In ko, this message translates to:
  /// **'회사·기관·유명인 같은 주인이 있는 이름이라 공식 배지가 있어야 채널 이름으로 쓸 수 있어요'**
  String get roomReservedOwner;

  /// No description provided for @idReservedSale.
  ///
  /// In ko, this message translates to:
  /// **'4글자 이하 ID와 인기 단어 ID는 따로 받을 수 있어요. 코드가 있으면 넣어 주세요.'**
  String get idReservedSale;

  /// No description provided for @claimHaveCode.
  ///
  /// In ko, this message translates to:
  /// **'받은 코드가 있어요'**
  String get claimHaveCode;

  /// No description provided for @claimCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'코드 (BRM-로 시작)'**
  String get claimCodeHint;

  /// No description provided for @claimCodeHelp.
  ///
  /// In ko, this message translates to:
  /// **'이 ID를 받을 때 메일로 온 코드예요. 30일 안에 한 번만 쓸 수 있어요.'**
  String get claimCodeHelp;

  /// No description provided for @claimCodeWrong.
  ///
  /// In ko, this message translates to:
  /// **'코드가 맞지 않거나 이미 썼어요. 받은 메일의 ID와 코드를 다시 확인해 주세요.'**
  String get claimCodeWrong;

  /// No description provided for @ruleSecs.
  ///
  /// In ko, this message translates to:
  /// **'{n}초'**
  String ruleSecs(int n);

  /// No description provided for @ruleMins.
  ///
  /// In ko, this message translates to:
  /// **'{n}분'**
  String ruleMins(int n);

  /// No description provided for @ruleHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간'**
  String ruleHours(int n);

  /// No description provided for @permText.
  ///
  /// In ko, this message translates to:
  /// **'글 보내기'**
  String get permText;

  /// No description provided for @permMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진·영상·파일'**
  String get permMedia;

  /// No description provided for @permSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커·GIF'**
  String get permSticker;

  /// No description provided for @permPoll.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get permPoll;

  /// No description provided for @permLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get permLink;

  /// No description provided for @permInvite.
  ///
  /// In ko, this message translates to:
  /// **'멤버 초대'**
  String get permInvite;

  /// No description provided for @permPin.
  ///
  /// In ko, this message translates to:
  /// **'메시지 고정'**
  String get permPin;

  /// No description provided for @permInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹 정보 바꾸기'**
  String get permInfo;

  /// No description provided for @rightInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹 정보 바꾸기'**
  String get rightInfo;

  /// No description provided for @rightDelete.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람 글 지우기'**
  String get rightDelete;

  /// No description provided for @rightBan.
  ///
  /// In ko, this message translates to:
  /// **'멤버 내보내기·차단'**
  String get rightBan;

  /// No description provided for @rightInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 만들기'**
  String get rightInvite;

  /// No description provided for @rightPin.
  ///
  /// In ko, this message translates to:
  /// **'메시지 고정'**
  String get rightPin;

  /// No description provided for @rightMute.
  ///
  /// In ko, this message translates to:
  /// **'메시지 금지'**
  String get rightMute;

  /// No description provided for @rightAddAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자 추가'**
  String get rightAddAdmin;

  /// No description provided for @memberPerms.
  ///
  /// In ko, this message translates to:
  /// **'멤버 권한'**
  String get memberPerms;

  /// No description provided for @memberPermsHeader.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 할 수 있는 일'**
  String get memberPermsHeader;

  /// No description provided for @memberPermsInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 일반 멤버는 그 기능을 쓸 수 없어요. 방장과 관리자는 늘 쓸 수 있어요.'**
  String get memberPermsInfo;

  /// No description provided for @adminRights.
  ///
  /// In ko, this message translates to:
  /// **'관리자 권한'**
  String get adminRights;

  /// No description provided for @adminRightsInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 관리자가 할 수 있는 일을 하나씩 고를 수 있어요. 방장 넘기기와 그룹 삭제는 방장만 할 수 있어요.'**
  String get adminRightsInfo;

  /// No description provided for @slowMode.
  ///
  /// In ko, this message translates to:
  /// **'슬로 모드'**
  String get slowMode;

  /// No description provided for @slowModeInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 멤버는 메시지를 보낸 뒤 정한 시간이 지나야 다시 보낼 수 있어요. 방장과 관리자는 제한이 없어요.'**
  String get slowModeInfo;

  /// No description provided for @memberTag.
  ///
  /// In ko, this message translates to:
  /// **'멤버 태그'**
  String get memberTag;

  /// No description provided for @memberTagInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름 옆에 보이는 짧은 글이에요 (최대 16자). 비우면 태그가 사라져요.'**
  String get memberTagInfo;

  /// No description provided for @memberTagHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 디자이너'**
  String get memberTagHint;

  /// No description provided for @muteMember.
  ///
  /// In ko, this message translates to:
  /// **'다음 동안 메시지 금지'**
  String get muteMember;

  /// No description provided for @unmuteMember.
  ///
  /// In ko, this message translates to:
  /// **'메시지 금지 풀기'**
  String get unmuteMember;

  /// No description provided for @muteFor1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get muteFor1h;

  /// No description provided for @muteFor1d.
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get muteFor1d;

  /// No description provided for @muteFor7d.
  ///
  /// In ko, this message translates to:
  /// **'7일'**
  String get muteFor7d;

  /// No description provided for @muteForever.
  ///
  /// In ko, this message translates to:
  /// **'풀 때까지'**
  String get muteForever;

  /// No description provided for @mutedRole.
  ///
  /// In ko, this message translates to:
  /// **'메시지 금지'**
  String get mutedRole;

  /// No description provided for @mutedForever.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 이 방에서 메시지를 막았어요'**
  String get mutedForever;

  /// No description provided for @mutedUntil.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 {time}까지 메시지를 막았어요'**
  String mutedUntil(String time);

  /// No description provided for @handover.
  ///
  /// In ko, this message translates to:
  /// **'방장 넘기기'**
  String get handover;

  /// No description provided for @handoverTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 방장 넘기기'**
  String handoverTitle(String name);

  /// No description provided for @handoverInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 기간 동안 둘 다 방장이에요. 기간이 끝나면 내가 \'넘기기 완료\'를 눌러야 끝나고, 나는 관리자가 돼요. 받는 사람은 거절할 수 있어요.'**
  String get handoverInfo;

  /// No description provided for @handoverPending.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 방장을 넘기는 중이에요. {time}부터 마칠 수 있어요.'**
  String handoverPending(String name, String time);

  /// No description provided for @handoverIncoming.
  ///
  /// In ko, this message translates to:
  /// **'방장을 넘겨받았어요. {time}까지는 기존 방장과 함께 방장이에요.'**
  String handoverIncoming(String time);

  /// No description provided for @handoverFinish.
  ///
  /// In ko, this message translates to:
  /// **'넘기기 완료'**
  String get handoverFinish;

  /// No description provided for @handoverDecline.
  ///
  /// In ko, this message translates to:
  /// **'방장 받지 않기'**
  String get handoverDecline;

  /// No description provided for @logMuted.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 메시지 금지'**
  String logMuted(String name);

  /// No description provided for @logUnmuted.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 메시지 금지 풀기'**
  String logUnmuted(String name);

  /// No description provided for @logHandover.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 방장 넘기기 시작'**
  String logHandover(String name);

  /// No description provided for @toolsMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get toolsMembers;

  /// No description provided for @permBlocked.
  ///
  /// In ko, this message translates to:
  /// **'이 방에서는 관리자만 보낼 수 있어요'**
  String get permBlocked;

  /// No description provided for @slowWait.
  ///
  /// In ko, this message translates to:
  /// **'슬로 모드: {n}초 뒤에 보낼 수 있어요'**
  String slowWait(int n);

  /// No description provided for @mentionAll.
  ///
  /// In ko, this message translates to:
  /// **'@모두'**
  String get mentionAll;

  /// No description provided for @mentionAllInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 방의 모든 멤버에게 알려요'**
  String get mentionAllInfo;

  /// No description provided for @mentionAllAdmins.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 33명 이상인 방은 관리자만 @모두를 쓸 수 있어요'**
  String get mentionAllAdmins;

  /// No description provided for @videoLabel.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get videoLabel;

  /// No description provided for @videoResumed.
  ///
  /// In ko, this message translates to:
  /// **'이어서 봐요 · {time}'**
  String videoResumed(String time);

  /// No description provided for @videoFromStart.
  ///
  /// In ko, this message translates to:
  /// **'처음부터'**
  String get videoFromStart;

  /// No description provided for @videoSpeedTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생 속도'**
  String get videoSpeedTitle;

  /// No description provided for @videoNoteHoldHint.
  ///
  /// In ko, this message translates to:
  /// **'누르면 찍고 다시 누르면 보내요. 꾹 누르고 있으면 손을 뗄 때 보내요'**
  String get videoNoteHoldHint;

  /// No description provided for @videoNoteSlideHint.
  ///
  /// In ko, this message translates to:
  /// **'↑ 밀면 잠가요 · ← 밀면 지워요'**
  String get videoNoteSlideHint;

  /// No description provided for @videoNoteLocked.
  ///
  /// In ko, this message translates to:
  /// **'잠겼어요 · ■ 누르면 보내요'**
  String get videoNoteLocked;

  /// No description provided for @autoSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 자동 저장'**
  String get autoSaveTitle;

  /// No description provided for @autoSaveInfo.
  ///
  /// In ko, this message translates to:
  /// **'받은 사진·영상을 폰 사진 앱에 저절로 저장해요. 사진 앱에 저장된 건 부루미 밖에 남아서 처음엔 꺼져 있어요. 한 번만 보기와 공유가 꺼진 대화는 저장하지 않아요.'**
  String get autoSaveInfo;

  /// No description provided for @autoplayVideo.
  ///
  /// In ko, this message translates to:
  /// **'영상 자동 재생'**
  String get autoplayVideo;

  /// No description provided for @autoplayVideoSub.
  ///
  /// In ko, this message translates to:
  /// **'받아 둔 영상이 대화에서 소리 없이 움직여요. 스피커를 누르면 소리가 나요'**
  String get autoplayVideoSub;

  /// No description provided for @videoQualityTitle.
  ///
  /// In ko, this message translates to:
  /// **'화질'**
  String get videoQualityTitle;

  /// No description provided for @videoQualityAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get videoQualityAuto;

  /// No description provided for @videoQualityOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원본'**
  String get videoQualityOriginal;

  /// No description provided for @videoQualityLightShort.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 화질'**
  String get videoQualityLightShort;

  /// No description provided for @videoQualityLight.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 화질 {height}p'**
  String videoQualityLight(int height);

  /// No description provided for @videoSendQuality.
  ///
  /// In ko, this message translates to:
  /// **'영상 화질'**
  String get videoSendQuality;

  /// No description provided for @videoQualityAbout.
  ///
  /// In ko, this message translates to:
  /// **'대략'**
  String get videoQualityAbout;

  /// No description provided for @videoQualitySmall.
  ///
  /// In ko, this message translates to:
  /// **'작은 용량'**
  String get videoQualitySmall;

  /// No description provided for @videoQualityHigh.
  ///
  /// In ko, this message translates to:
  /// **'높은 화질'**
  String get videoQualityHigh;

  /// No description provided for @videoLightCopy.
  ///
  /// In ko, this message translates to:
  /// **'가벼운 복사본도 함께 보내기'**
  String get videoLightCopy;

  /// No description provided for @videoLightCopySub.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 아끼는 사람은 480p로 볼 수 있어요'**
  String get videoLightCopySub;

  /// No description provided for @videoQualityWebNote.
  ///
  /// In ko, this message translates to:
  /// **'웹에서는 원본으로 보내요. 폰 앱에서는 이 화질로 줄여서 보내요.'**
  String get videoQualityWebNote;

  /// No description provided for @dlWaiting.
  ///
  /// In ko, this message translates to:
  /// **'순서 기다리는 중'**
  String get dlWaiting;

  /// No description provided for @dlPaused.
  ///
  /// In ko, this message translates to:
  /// **'멈춤'**
  String get dlPaused;

  /// No description provided for @dlFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 받기'**
  String get dlFirst;

  /// No description provided for @dlPause.
  ///
  /// In ko, this message translates to:
  /// **'멈추기'**
  String get dlPause;

  /// No description provided for @dlResume.
  ///
  /// In ko, this message translates to:
  /// **'이어 받기 (처음부터)'**
  String get dlResume;

  /// No description provided for @dlStop.
  ///
  /// In ko, this message translates to:
  /// **'그만 받기'**
  String get dlStop;

  /// No description provided for @docOpenOther.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱으로 열기'**
  String get docOpenOther;

  /// No description provided for @docOpenOtherWarn.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱으로 열면 그 앱이 파일 내용을 볼 수 있어요. 부루미의 암호화 보호 밖으로 나가요.'**
  String get docOpenOtherWarn;

  /// No description provided for @docOpenOtherGo.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get docOpenOtherGo;

  /// No description provided for @docNoInApp.
  ///
  /// In ko, this message translates to:
  /// **'부루미 안에서 바로 볼 수 없는 파일이에요'**
  String get docNoInApp;

  /// No description provided for @docNoInAppHint.
  ///
  /// In ko, this message translates to:
  /// **'PDF, 글자 파일, 사진은 부루미 안에서 바로 열려요. 이 파일은 다른 앱으로 열어 주세요.'**
  String get docNoInAppHint;

  /// No description provided for @docProtectedNoShare.
  ///
  /// In ko, this message translates to:
  /// **'이 대화는 공유가 꺼져 있어서 다른 앱으로 열 수 없어요'**
  String get docProtectedNoShare;

  /// No description provided for @docSearch.
  ///
  /// In ko, this message translates to:
  /// **'문서에서 찾기'**
  String get docSearch;

  /// No description provided for @docSearchNone.
  ///
  /// In ko, this message translates to:
  /// **'없어요'**
  String get docSearchNone;

  /// No description provided for @docPage.
  ///
  /// In ko, this message translates to:
  /// **'{page}/{pages}쪽'**
  String docPage(int page, int pages);

  /// No description provided for @docTabsMore.
  ///
  /// In ko, this message translates to:
  /// **'{name} 외 {count}개'**
  String docTabsMore(String name, int count);

  /// No description provided for @docTabsTitle.
  ///
  /// In ko, this message translates to:
  /// **'열어 둔 파일'**
  String get docTabsTitle;

  /// No description provided for @docTabsCloseAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 닫기'**
  String get docTabsCloseAll;

  /// No description provided for @docFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열지 못했어요'**
  String get docFailed;

  /// No description provided for @docTextCut.
  ///
  /// In ko, this message translates to:
  /// **'글이 길어서 앞부분만 보여요'**
  String get docTextCut;

  /// No description provided for @videoSpeedNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get videoSpeedNormal;

  /// No description provided for @videoSkipSeconds.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초'**
  String videoSkipSeconds(int seconds);

  /// No description provided for @dlChatDm.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화'**
  String get dlChatDm;

  /// No description provided for @dlOff.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get dlOff;

  /// No description provided for @dlUpToMb.
  ///
  /// In ko, this message translates to:
  /// **'{mb}MB까지'**
  String dlUpToMb(int mb);

  /// No description provided for @dlChatsCount.
  ///
  /// In ko, this message translates to:
  /// **'대화 종류 {count}개'**
  String dlChatsCount(int count);

  /// No description provided for @dlAutoSwitch.
  ///
  /// In ko, this message translates to:
  /// **'자동으로 받기'**
  String get dlAutoSwitch;

  /// No description provided for @dlKinds.
  ///
  /// In ko, this message translates to:
  /// **'받을 것'**
  String get dlKinds;

  /// No description provided for @dlWhere.
  ///
  /// In ko, this message translates to:
  /// **'이런 대화에서 미리 받아요'**
  String get dlWhere;

  /// No description provided for @dlMaxSize.
  ///
  /// In ko, this message translates to:
  /// **'최대 크기'**
  String get dlMaxSize;

  /// No description provided for @dlMaxInfo.
  ///
  /// In ko, this message translates to:
  /// **'이보다 큰 파일은 누를 때 받아요. 크기를 모르는 파일도 누를 때 받아요.'**
  String get dlMaxInfo;

  /// No description provided for @dlList.
  ///
  /// In ko, this message translates to:
  /// **'다운로드 목록'**
  String get dlList;

  /// No description provided for @dlListEmpty.
  ///
  /// In ko, this message translates to:
  /// **'받은 파일이 아직 없어요'**
  String get dlListEmpty;

  /// No description provided for @dlRunning.
  ///
  /// In ko, this message translates to:
  /// **'받는 중'**
  String get dlRunning;

  /// No description provided for @dlRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근에 받은 것'**
  String get dlRecent;

  /// No description provided for @dlCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소했어요'**
  String get dlCancelled;

  /// No description provided for @dlFailed.
  ///
  /// In ko, this message translates to:
  /// **'받지 못했어요'**
  String get dlFailed;

  /// No description provided for @dlClear.
  ///
  /// In ko, this message translates to:
  /// **'목록 지우기'**
  String get dlClear;

  /// No description provided for @dlListInfo.
  ///
  /// In ko, this message translates to:
  /// **'목록만 지워져요. 받아 둔 파일은 아래 보관 기간이 지나면 지워져요.'**
  String get dlListInfo;

  /// No description provided for @dlTapToGet.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 받기'**
  String get dlTapToGet;

  /// No description provided for @keepTitle.
  ///
  /// In ko, this message translates to:
  /// **'받아 둔 파일 자동으로 지우기'**
  String get keepTitle;

  /// No description provided for @keepInfo.
  ///
  /// In ko, this message translates to:
  /// **'마지막으로 연 지 이 기간이 지나면 기기에 받아 둔 사진·동영상·파일을 지워요. 대화는 그대로이고, 다시 누르면 새로 받아요. 받아 둔 파일도 기기 안에서 암호화돼 있어요.'**
  String get keepInfo;

  /// No description provided for @keepDay.
  ///
  /// In ko, this message translates to:
  /// **'하루'**
  String get keepDay;

  /// No description provided for @keepWeek.
  ///
  /// In ko, this message translates to:
  /// **'일주일'**
  String get keepWeek;

  /// No description provided for @keepMonth.
  ///
  /// In ko, this message translates to:
  /// **'한 달'**
  String get keepMonth;

  /// No description provided for @keepNever.
  ///
  /// In ko, this message translates to:
  /// **'안 지워요'**
  String get keepNever;

  /// No description provided for @viewOnceVideo.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기 동영상'**
  String get viewOnceVideo;

  /// No description provided for @draftLabel.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장:'**
  String get draftLabel;

  /// No description provided for @pinHowLong.
  ///
  /// In ko, this message translates to:
  /// **'얼마 동안 고정할까요?'**
  String get pinHowLong;

  /// No description provided for @invitesBlockedRow.
  ///
  /// In ko, this message translates to:
  /// **'초대를 막은 사람 {n}명'**
  String invitesBlockedRow(int n);

  /// No description provided for @invitesBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{n}명이 초대를 막았어요'**
  String invitesBlockedTitle(int n);

  /// No description provided for @invitesBlockedInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 사람들은 연락처에 있는 사람만 그룹·채널에 초대할 수 있게 해 두었어요. 대신 초대 링크를 1:1 대화로 보낼 수 있어요. 들어올지는 본인이 정해요.'**
  String get invitesBlockedInfo;

  /// No description provided for @sendInviteLinkN.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 보내기 {n}'**
  String sendInviteLinkN(int n);

  /// No description provided for @inviteLinkSent.
  ///
  /// In ko, this message translates to:
  /// **'{n}명에게 초대 링크를 보냈어요'**
  String inviteLinkSent(int n);

  /// No description provided for @inviteLinkNone.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크를 만들 권한이 없어요. 관리자에게 부탁해 보세요.'**
  String get inviteLinkNone;

  /// No description provided for @readAtToday.
  ///
  /// In ko, this message translates to:
  /// **'읽음 · 오늘 {time}'**
  String readAtToday(String time);

  /// No description provided for @readAtYesterday.
  ///
  /// In ko, this message translates to:
  /// **'읽음 · 어제 {time}'**
  String readAtYesterday(String time);

  /// No description provided for @readAtDate.
  ///
  /// In ko, this message translates to:
  /// **'읽음 · {date}'**
  String readAtDate(String date);

  /// No description provided for @shareTitle.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get shareTitle;

  /// No description provided for @shareAddWord.
  ///
  /// In ko, this message translates to:
  /// **'한마디 덧붙이기'**
  String get shareAddWord;

  /// No description provided for @shareSendN.
  ///
  /// In ko, this message translates to:
  /// **'보내기 {n}'**
  String shareSendN(int n);

  /// No description provided for @shareDone.
  ///
  /// In ko, this message translates to:
  /// **'{n}곳에 전달했어요'**
  String shareDone(int n);

  /// No description provided for @textCopied.
  ///
  /// In ko, this message translates to:
  /// **'글자를 복사했어요'**
  String get textCopied;

  /// No description provided for @copyMsgLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get copyMsgLink;

  /// No description provided for @msgLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했어요. 이 대화방 멤버만 열 수 있어요.'**
  String get msgLinkCopied;

  /// No description provided for @msgLinkNotMember.
  ///
  /// In ko, this message translates to:
  /// **'이 링크는 대화방 멤버만 열 수 있어요.'**
  String get msgLinkNotMember;

  /// No description provided for @msgLinkGone.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 찾지 못했어요. 지워졌거나 오래된 메시지예요.'**
  String get msgLinkGone;

  /// No description provided for @pinnedMessageN.
  ///
  /// In ko, this message translates to:
  /// **'고정 메시지 #{n}'**
  String pinnedMessageN(int n);

  /// No description provided for @pinnedListTitle.
  ///
  /// In ko, this message translates to:
  /// **'고정 메시지 {count}개'**
  String pinnedListTitle(int count);

  /// No description provided for @pinnedListOpen.
  ///
  /// In ko, this message translates to:
  /// **'고정 메시지 모두 보기'**
  String get pinnedListOpen;

  /// No description provided for @unpinAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 고정 해제'**
  String get unpinAll;

  /// No description provided for @unpinAllAsk.
  ///
  /// In ko, this message translates to:
  /// **'고정 메시지 {count}개를 모두 해제할까요?'**
  String unpinAllAsk(int count);

  /// No description provided for @pinNotifyAll.
  ///
  /// In ko, this message translates to:
  /// **'모두에게 알림'**
  String get pinNotifyAll;

  /// No description provided for @pinNotifyInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 멤버 모두의 휴대폰에 알림이 가요. 끄면 조용히 고정돼요.'**
  String get pinNotifyInfo;

  /// No description provided for @pinLine.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 메시지를 고정했어요'**
  String pinLine(String name);

  /// No description provided for @pinLineMine.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 고정했어요'**
  String get pinLineMine;

  /// No description provided for @pinFor1d.
  ///
  /// In ko, this message translates to:
  /// **'하루'**
  String get pinFor1d;

  /// No description provided for @pinFor1w.
  ///
  /// In ko, this message translates to:
  /// **'일주일'**
  String get pinFor1w;

  /// No description provided for @pinFor1m.
  ///
  /// In ko, this message translates to:
  /// **'한 달'**
  String get pinFor1m;

  /// No description provided for @pinForever.
  ///
  /// In ko, this message translates to:
  /// **'직접 풀 때까지'**
  String get pinForever;

  /// No description provided for @repeatNone.
  ///
  /// In ko, this message translates to:
  /// **'한 번'**
  String get repeatNone;

  /// No description provided for @repeatDay.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get repeatDay;

  /// No description provided for @repeatWeek.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get repeatWeek;

  /// No description provided for @repeatMonth.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get repeatMonth;

  /// No description provided for @tabPolls.
  ///
  /// In ko, this message translates to:
  /// **'투표'**
  String get tabPolls;

  /// No description provided for @tabSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get tabSaved;

  /// No description provided for @pollClosedShort.
  ///
  /// In ko, this message translates to:
  /// **'마감'**
  String get pollClosedShort;

  /// No description provided for @videoNote.
  ///
  /// In ko, this message translates to:
  /// **'동그라미 영상'**
  String get videoNote;

  /// No description provided for @videoNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'누르면 최대 1분 동안 찍고, 다시 누르면 보내요'**
  String get videoNoteHint;

  /// No description provided for @cameraUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 켤 수 없어요'**
  String get cameraUnavailable;

  /// No description provided for @saveToGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 저장'**
  String get saveToGallery;

  /// No description provided for @savedToGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에 저장했어요'**
  String get savedToGallery;

  /// No description provided for @noMemberDm.
  ///
  /// In ko, this message translates to:
  /// **'멤버끼리 1:1 대화 막기'**
  String get noMemberDm;

  /// No description provided for @noMemberDmInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 이 그룹의 일반 멤버끼리는 1:1 대화를 새로 시작할 수 없어요. 관리자와는 대화할 수 있어요. 낯선 사람이 그룹에서 개인 연락하는 걸 막아 줘요.'**
  String get noMemberDmInfo;

  /// No description provided for @memberDmBlocked.
  ///
  /// In ko, this message translates to:
  /// **'같이 있는 그룹에서 멤버끼리 1:1 대화를 막아 두어서 대화를 시작할 수 없어요.'**
  String get memberDmBlocked;

  /// No description provided for @cardFlow.
  ///
  /// In ko, this message translates to:
  /// **'선택형 카드'**
  String get cardFlow;

  /// No description provided for @newFlow.
  ///
  /// In ko, this message translates to:
  /// **'선택형 카드 만들기'**
  String get newFlow;

  /// No description provided for @flowTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 오늘 뭐 볼까?'**
  String get flowTitleHint;

  /// No description provided for @flowTextHint.
  ///
  /// In ko, this message translates to:
  /// **'설명 (없어도 돼요)'**
  String get flowTextHint;

  /// No description provided for @flowStartHint.
  ///
  /// In ko, this message translates to:
  /// **'시작 버튼 이름 (비우면 \'시작하기\')'**
  String get flowStartHint;

  /// No description provided for @flowStart.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get flowStart;

  /// No description provided for @flowQuestionHint.
  ///
  /// In ko, this message translates to:
  /// **'질문을 적어 주세요'**
  String get flowQuestionHint;

  /// No description provided for @flowChoiceHint.
  ///
  /// In ko, this message translates to:
  /// **'선택지'**
  String get flowChoiceHint;

  /// No description provided for @flowAddChoice.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get flowAddChoice;

  /// No description provided for @flowAddQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 추가'**
  String get flowAddQuestion;

  /// No description provided for @flowRemoveQuestion.
  ///
  /// In ko, this message translates to:
  /// **'이 질문 지우기'**
  String get flowRemoveQuestion;

  /// No description provided for @flowResultN.
  ///
  /// In ko, this message translates to:
  /// **'결과 {n}'**
  String flowResultN(int n);

  /// No description provided for @flowResultTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'결과 이름 (예: 액션 영화)'**
  String get flowResultTitleHint;

  /// No description provided for @flowResultTextHint.
  ///
  /// In ko, this message translates to:
  /// **'결과 설명 (없어도 돼요)'**
  String get flowResultTextHint;

  /// No description provided for @flowLinkLabelHint.
  ///
  /// In ko, this message translates to:
  /// **'링크 버튼 이름 (없어도 돼요)'**
  String get flowLinkLabelHint;

  /// No description provided for @flowAddResult.
  ///
  /// In ko, this message translates to:
  /// **'결과 추가'**
  String get flowAddResult;

  /// No description provided for @flowRemoveResult.
  ///
  /// In ko, this message translates to:
  /// **'이 결과 지우기'**
  String get flowRemoveResult;

  /// No description provided for @flowPickNext.
  ///
  /// In ko, this message translates to:
  /// **'이 선택지를 누르면 어디로 갈까요?'**
  String get flowPickNext;

  /// No description provided for @flowToQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 {n}'**
  String flowToQuestion(int n);

  /// No description provided for @flowToResult.
  ///
  /// In ko, this message translates to:
  /// **'결과 {n}'**
  String flowToResult(int n);

  /// No description provided for @flowStats.
  ///
  /// In ko, this message translates to:
  /// **'결과 통계 받기'**
  String get flowStats;

  /// No description provided for @flowStatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'누군가 결과까지 가면 결과 번호만 내 폰으로 와요. 누가 어떤 결과를 받았는지는 내 폰에도 남지 않고, 결과마다 몇 명인지 숫자만 보여요.'**
  String get flowStatsInfo;

  /// No description provided for @flowInfo.
  ///
  /// In ko, this message translates to:
  /// **'버튼을 누를 때마다 카드가 다음 질문으로 바뀌어요. 바뀐 화면은 누른 사람에게만 보이고, 고른 답은 그 사람 폰 밖으로 나가지 않아요. 질문은 10개, 선택지는 질문마다 6개, 결과는 8개까지예요.'**
  String get flowInfo;

  /// No description provided for @flowNoPath.
  ///
  /// In ko, this message translates to:
  /// **'어떤 선택으로도 결과에 닿지 않아요. 선택지가 어디로 가는지 확인해 주세요.'**
  String get flowNoPath;

  /// No description provided for @flowBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get flowBack;

  /// No description provided for @flowAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 하기'**
  String get flowAgain;

  /// No description provided for @flowShare.
  ///
  /// In ko, this message translates to:
  /// **'결과 보내기'**
  String get flowShare;

  /// No description provided for @flowResultLabel.
  ///
  /// In ko, this message translates to:
  /// **'내 결과'**
  String get flowResultLabel;

  /// No description provided for @flowShared.
  ///
  /// In ko, this message translates to:
  /// **'결과를 보냈어요'**
  String get flowShared;

  /// No description provided for @flowStatsTitle.
  ///
  /// In ko, this message translates to:
  /// **'결과 통계'**
  String get flowStatsTitle;

  /// No description provided for @flowTried.
  ///
  /// In ko, this message translates to:
  /// **'{n}명이 결과를 받았어요'**
  String flowTried(int n);

  /// No description provided for @flowStatsNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 결과를 받은 사람이 없어요'**
  String get flowStatsNone;

  /// No description provided for @flowStatsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'결과마다 몇 명인지만 보여요. 누가 어떤 결과를 받았는지는 아무도 몰라요.'**
  String get flowStatsPrivacy;

  /// No description provided for @flowRevert.
  ///
  /// In ko, this message translates to:
  /// **'처음으로 되돌리기'**
  String get flowRevert;

  /// No description provided for @flowShareText.
  ///
  /// In ko, this message translates to:
  /// **'{title}\n내 결과: {result}'**
  String flowShareText(String title, String result);

  /// No description provided for @welcomeEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'환영 인사 만들기'**
  String get welcomeEmptyTitle;

  /// No description provided for @welcomeEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버가 들어오면 자동으로 반겨 줘요.\n사진이나 영상도 하나 넣을 수 있어요.'**
  String get welcomeEmptyBody;

  /// No description provided for @welcomeEditorHint.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버가 들어오면 이 메시지를 봐요.\n길게 누르면 고치거나 지울 수 있어요.'**
  String get welcomeEditorHint;

  /// No description provided for @welcomeOnlyYou.
  ///
  /// In ko, this message translates to:
  /// **'나만 보여요'**
  String get welcomeOnlyYou;

  /// No description provided for @joinedGroupLine.
  ///
  /// In ko, this message translates to:
  /// **'그룹에 들어왔어요'**
  String get joinedGroupLine;

  /// No description provided for @joinedChannelLine.
  ///
  /// In ko, this message translates to:
  /// **'채널을 구독했어요'**
  String get joinedChannelLine;

  /// No description provided for @welcomeMediaTooBig.
  ///
  /// In ko, this message translates to:
  /// **'사진이나 영상은 50MB까지 넣을 수 있어요'**
  String get welcomeMediaTooBig;

  /// No description provided for @textsEncrypted.
  ///
  /// In ko, this message translates to:
  /// **'끝까지 암호화돼요. 서버는 내용을 볼 수 없어요.'**
  String get textsEncrypted;

  /// No description provided for @welcomeRemoveMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진·영상 빼기'**
  String get welcomeRemoveMedia;

  /// No description provided for @welcomeAddHint.
  ///
  /// In ko, this message translates to:
  /// **'환영 메시지'**
  String get welcomeAddHint;

  /// No description provided for @removeContact.
  ///
  /// In ko, this message translates to:
  /// **'연락처에서 삭제'**
  String get removeContact;

  /// No description provided for @removeContactInfo.
  ///
  /// In ko, this message translates to:
  /// **'연락처 목록에서만 빠지고 대화는 그대로 남아요. 다시 대화를 열면 연락처에 돌아와요.'**
  String get removeContactInfo;

  /// No description provided for @tidyChats.
  ///
  /// In ko, this message translates to:
  /// **'대화 정리하기'**
  String get tidyChats;

  /// No description provided for @tidyChatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'6개월 넘게 새 글이 없는 그룹과 채널이에요. 고른 방을 한 번에 나가요. 나가기 전 5초 동안 되돌릴 수 있어요.'**
  String get tidyChatsInfo;

  /// No description provided for @tidyLast.
  ///
  /// In ko, this message translates to:
  /// **'마지막 글 {date}'**
  String tidyLast(String date);

  /// No description provided for @tidyNone.
  ///
  /// In ko, this message translates to:
  /// **'정리할 대화가 없어요'**
  String get tidyNone;

  /// No description provided for @tidyLeave.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 대화 나가기'**
  String tidyLeave(int n);

  /// No description provided for @noIdSearch.
  ///
  /// In ko, this message translates to:
  /// **'아이디로 나를 찾지 못하게'**
  String get noIdSearch;

  /// No description provided for @noIdSearchInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 모르는 사람이 내 아이디나 이름을 검색해도 나오지 않아요. 같은 대화방에 있는 사람이나 내 QR·초대 링크를 받은 사람은 계속 찾을 수 있어요.'**
  String get noIdSearchInfo;

  /// No description provided for @liveLabel.
  ///
  /// In ko, this message translates to:
  /// **'LIVE'**
  String get liveLabel;

  /// No description provided for @liveLabelOff.
  ///
  /// In ko, this message translates to:
  /// **'LIVE 끔'**
  String get liveLabelOff;

  /// No description provided for @liveStyleLive.
  ///
  /// In ko, this message translates to:
  /// **'라이브'**
  String get liveStyleLive;

  /// No description provided for @liveStyleLoop.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get liveStyleLoop;

  /// No description provided for @liveStyleBounce.
  ///
  /// In ko, this message translates to:
  /// **'바운스'**
  String get liveStyleBounce;

  /// No description provided for @liveStyleOff.
  ///
  /// In ko, this message translates to:
  /// **'라이브 끄기'**
  String get liveStyleOff;

  /// No description provided for @liveOnToast.
  ///
  /// In ko, this message translates to:
  /// **'라이브 포토를 켰어요'**
  String get liveOnToast;

  /// No description provided for @liveLoopToast.
  ///
  /// In ko, this message translates to:
  /// **'반복 재생으로 바꿨어요'**
  String get liveLoopToast;

  /// No description provided for @liveBounceToast.
  ///
  /// In ko, this message translates to:
  /// **'바운스로 바꿨어요'**
  String get liveBounceToast;

  /// No description provided for @liveOffToast.
  ///
  /// In ko, this message translates to:
  /// **'라이브 포토를 껐어요. 사진만 보내요'**
  String get liveOffToast;

  /// No description provided for @livePhoto.
  ///
  /// In ko, this message translates to:
  /// **'라이브 포토'**
  String get livePhoto;

  /// No description provided for @liveReplay.
  ///
  /// In ko, this message translates to:
  /// **'다시 재생'**
  String get liveReplay;

  /// No description provided for @aiEditor.
  ///
  /// In ko, this message translates to:
  /// **'AI 편집기'**
  String get aiEditor;

  /// No description provided for @aiTabTranslate.
  ///
  /// In ko, this message translates to:
  /// **'번역'**
  String get aiTabTranslate;

  /// No description provided for @aiTabStyle.
  ///
  /// In ko, this message translates to:
  /// **'말투'**
  String get aiTabStyle;

  /// No description provided for @aiTabFix.
  ///
  /// In ko, this message translates to:
  /// **'고치기'**
  String get aiTabFix;

  /// No description provided for @aiOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원래 글'**
  String get aiOriginal;

  /// No description provided for @aiResult.
  ///
  /// In ko, this message translates to:
  /// **'결과'**
  String get aiResult;

  /// No description provided for @aiEmojify.
  ///
  /// In ko, this message translates to:
  /// **'이모지 넣기'**
  String get aiEmojify;

  /// No description provided for @aiApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get aiApply;

  /// No description provided for @aiFromLang.
  ///
  /// In ko, this message translates to:
  /// **'원래 언어: {lang}'**
  String aiFromLang(String lang);

  /// No description provided for @aiToLang.
  ///
  /// In ko, this message translates to:
  /// **'바꿀 언어'**
  String get aiToLang;

  /// No description provided for @aiFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 AI가 답하지 못했어요. 잠시 뒤 다시 해 보세요.'**
  String get aiFailed;

  /// No description provided for @aiRefused.
  ///
  /// In ko, this message translates to:
  /// **'이 글은 AI가 바꿀 수 없어요.'**
  String get aiRefused;

  /// No description provided for @aiTooLong.
  ///
  /// In ko, this message translates to:
  /// **'글이 너무 길어요. {count}자까지 바꿀 수 있어요.'**
  String aiTooLong(int count);

  /// No description provided for @aiPreparing.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰이 AI를 준비하고 있어요. 조금 뒤에 다시 해 보세요.'**
  String get aiPreparing;

  /// No description provided for @aiNoChange.
  ///
  /// In ko, this message translates to:
  /// **'고칠 곳이 없어요.'**
  String get aiNoChange;

  /// No description provided for @aiHelp.
  ///
  /// In ko, this message translates to:
  /// **'AI 편집기는 이 휴대폰 안의 AI만 써요. 쓴 글은 서버를 포함해 어디로도 보내지 않아요.'**
  String get aiHelp;

  /// No description provided for @aiStyleNew.
  ///
  /// In ko, this message translates to:
  /// **'새 말투'**
  String get aiStyleNew;

  /// No description provided for @aiStyleNameHint.
  ///
  /// In ko, this message translates to:
  /// **'말투 이름 (예: 해적)'**
  String get aiStyleNameHint;

  /// No description provided for @aiStyleRulesHint.
  ///
  /// In ko, this message translates to:
  /// **'어떻게 바꿀지 적어 주세요 (예: 해적처럼 써 줘. \'으하하\'를 자주 넣어서)'**
  String get aiStyleRulesHint;

  /// No description provided for @aiStyleIconPick.
  ///
  /// In ko, this message translates to:
  /// **'아이콘으로 쓸 이모지를 하나 골라요'**
  String get aiStyleIconPick;

  /// No description provided for @aiStyleEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아이콘, 이름, 설명을 모두 채워 주세요.'**
  String get aiStyleEmpty;

  /// No description provided for @aiStyleLong.
  ///
  /// In ko, this message translates to:
  /// **'이름은 {name}자, 설명은 {rules}자까지 쓸 수 있어요.'**
  String aiStyleLong(int name, int rules);

  /// No description provided for @aiStyleBlocked.
  ///
  /// In ko, this message translates to:
  /// **'이런 지시는 쓸 수 없어요. 다른 말로 적어 주세요.'**
  String get aiStyleBlocked;

  /// No description provided for @aiStyleSaveInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 말투는 내 계정 설정에 잠긴 채로 저장돼요. 서버는 내용을 몰라요.'**
  String get aiStyleSaveInfo;

  /// No description provided for @aiStyleAdd.
  ///
  /// In ko, this message translates to:
  /// **'말투 추가'**
  String get aiStyleAdd;

  /// No description provided for @aiStyleAdded.
  ///
  /// In ko, this message translates to:
  /// **'말투를 추가했어요: {name}'**
  String aiStyleAdded(String name);

  /// No description provided for @aiStyleAddedHint.
  ///
  /// In ko, this message translates to:
  /// **'긴 글을 쓸 때 AI 버튼 → 말투에서 골라요.'**
  String get aiStyleAddedHint;

  /// No description provided for @aiStyleExample.
  ///
  /// In ko, this message translates to:
  /// **'예시'**
  String get aiStyleExample;

  /// No description provided for @aiStyleBefore.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기 전'**
  String get aiStyleBefore;

  /// No description provided for @aiStyleAfter.
  ///
  /// In ko, this message translates to:
  /// **'바꾼 후'**
  String get aiStyleAfter;

  /// No description provided for @aiStyleAnother.
  ///
  /// In ko, this message translates to:
  /// **'다른 예시'**
  String get aiStyleAnother;

  /// No description provided for @aiStyleAddInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 말투를 AI 편집기에 넣으면 내 메시지를 이렇게 바꿀 수 있어요. 예시는 내 휴대폰 AI가 방금 만들었어요.'**
  String get aiStyleAddInfo;

  /// No description provided for @aiStyleNoAi.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에서는 AI 편집기를 쓸 수 없어서 예시를 보여 드릴 수 없어요. 말투는 저장해 둘 수 있어요.'**
  String get aiStyleNoAi;

  /// No description provided for @aiStyleHave.
  ///
  /// In ko, this message translates to:
  /// **'이미 있는 말투예요'**
  String get aiStyleHave;

  /// No description provided for @aiMyStyles.
  ///
  /// In ko, this message translates to:
  /// **'내 말투'**
  String get aiMyStyles;

  /// No description provided for @aiMyStylesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 만든 말투가 없어요. AI 편집기의 말투 탭에서 +를 눌러 만들어요.'**
  String get aiMyStylesEmpty;

  /// No description provided for @aiStyleCopyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get aiStyleCopyLink;

  /// No description provided for @aiStyleSendInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크 안에 말투가 들어 있어요. 서버에는 저장되지 않고, 몇 명이 쓰는지도 세지 않아요.'**
  String get aiStyleSendInfo;

  /// No description provided for @aiStyleCard.
  ///
  /// In ko, this message translates to:
  /// **'부루미 말투'**
  String get aiStyleCard;

  /// No description provided for @aiStyleCardOpen.
  ///
  /// In ko, this message translates to:
  /// **'말투 보기'**
  String get aiStyleCardOpen;

  /// No description provided for @aiEditorSwitch.
  ///
  /// In ko, this message translates to:
  /// **'AI 편집기'**
  String get aiEditorSwitch;

  /// No description provided for @aiEditorSwitchSub.
  ///
  /// In ko, this message translates to:
  /// **'긴 글을 쓰면 맞춤법·말투·번역 버튼이 생겨요'**
  String get aiEditorSwitchSub;

  /// No description provided for @aiNotOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰은 기기 안 AI를 지원하지 않아서 AI 편집기가 보이지 않아요.'**
  String get aiNotOnPhone;

  /// No description provided for @aiStyleFormal.
  ///
  /// In ko, this message translates to:
  /// **'정중하게'**
  String get aiStyleFormal;

  /// No description provided for @aiStyleShort.
  ///
  /// In ko, this message translates to:
  /// **'짧게'**
  String get aiStyleShort;

  /// No description provided for @aiStyleFriendly.
  ///
  /// In ko, this message translates to:
  /// **'다정하게'**
  String get aiStyleFriendly;

  /// No description provided for @aiStyleWork.
  ///
  /// In ko, this message translates to:
  /// **'업무용'**
  String get aiStyleWork;

  /// No description provided for @aiStyleHistoric.
  ///
  /// In ko, this message translates to:
  /// **'사극체'**
  String get aiStyleHistoric;

  /// No description provided for @aiStyleZen.
  ///
  /// In ko, this message translates to:
  /// **'차분하게'**
  String get aiStyleZen;

  /// No description provided for @aiTryAgain.
  ///
  /// In ko, this message translates to:
  /// **'다시 하기'**
  String get aiTryAgain;

  /// No description provided for @aiLangKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get aiLangKo;

  /// No description provided for @aiLangEn.
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get aiLangEn;

  /// No description provided for @aiLangJa.
  ///
  /// In ko, this message translates to:
  /// **'일본어'**
  String get aiLangJa;

  /// No description provided for @aiLangZh.
  ///
  /// In ko, this message translates to:
  /// **'중국어'**
  String get aiLangZh;

  /// No description provided for @aiLangEs.
  ///
  /// In ko, this message translates to:
  /// **'스페인어'**
  String get aiLangEs;

  /// No description provided for @aiLangVi.
  ///
  /// In ko, this message translates to:
  /// **'베트남어'**
  String get aiLangVi;

  /// No description provided for @aiLangRu.
  ///
  /// In ko, this message translates to:
  /// **'러시아어'**
  String get aiLangRu;

  /// No description provided for @aiExample1.
  ///
  /// In ko, this message translates to:
  /// **'이번 주말에 시간 되면 같이 저녁 먹을래? 7시쯤 어때?'**
  String get aiExample1;

  /// No description provided for @aiExample2.
  ///
  /// In ko, this message translates to:
  /// **'오늘 비가 와서 그냥 집에서 쉬려고. 너는 뭐 해?'**
  String get aiExample2;

  /// No description provided for @aiExample3.
  ///
  /// In ko, this message translates to:
  /// **'다음 달에 이사 가는데 짐 싸는 것 좀 도와줄 수 있어?'**
  String get aiExample3;

  /// No description provided for @gateTitle.
  ///
  /// In ko, this message translates to:
  /// **'가입 심사 도우미'**
  String get gateTitle;

  /// No description provided for @gateHeader.
  ///
  /// In ko, this message translates to:
  /// **'가입 신청이 오면 도우미가 몇 초 안에 확인하고 들여보내거나 거절해요. 대화 내용은 볼 수 없어요.'**
  String get gateHeader;

  /// No description provided for @gateOn.
  ///
  /// In ko, this message translates to:
  /// **'도우미 켜기'**
  String get gateOn;

  /// No description provided for @gateOnInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 \'가입 심사 도우미\' 계정이 이 방에 들어와요. 이 계정은 사람을 들이고 거절하는 일만 할 수 있고, 글을 쓰거나 설정을 바꿀 수 없어요.'**
  String get gateOnInfo;

  /// No description provided for @gateSafety.
  ///
  /// In ko, this message translates to:
  /// **'안전'**
  String get gateSafety;

  /// No description provided for @gateSafetyInfo.
  ///
  /// In ko, this message translates to:
  /// **'도우미는 암호 열쇠가 없어서 대화 내용을 받을 수 없어요. 서버가 도우미의 열쇠 등록을 막아요. 도우미가 보는 건 신청한 사람의 이름과 질문에 쓴 답뿐이에요.'**
  String get gateSafetyInfo;

  /// No description provided for @gateCantRead.
  ///
  /// In ko, this message translates to:
  /// **'대화를 못 읽어요'**
  String get gateCantRead;

  /// No description provided for @gateHasKeys.
  ///
  /// In ko, this message translates to:
  /// **'암호 열쇠가 있어요. 도우미를 꺼 주세요'**
  String get gateHasKeys;

  /// No description provided for @gateKeyCount.
  ///
  /// In ko, this message translates to:
  /// **'암호 열쇠 {count}개'**
  String gateKeyCount(int count);

  /// No description provided for @gateQuestions.
  ///
  /// In ko, this message translates to:
  /// **'가입 질문'**
  String get gateQuestions;

  /// No description provided for @gateQuestionsInfo.
  ///
  /// In ko, this message translates to:
  /// **'신청할 때 답해요. 객관식은 맞았는지 바로 알려 주고 다시 고를 수 있어요. 질문과 답은 암호화되지 않아서 서버도 볼 수 있어요. 개인 정보는 묻지 마세요. 최대 5개.'**
  String get gateQuestionsInfo;

  /// No description provided for @gateQuizKind.
  ///
  /// In ko, this message translates to:
  /// **'객관식 · 보기 {count}개'**
  String gateQuizKind(int count);

  /// No description provided for @gateWrittenKind.
  ///
  /// In ko, this message translates to:
  /// **'글로 답하기'**
  String get gateWrittenKind;

  /// No description provided for @gateAddQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 추가'**
  String get gateAddQuestion;

  /// No description provided for @gateEditQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 고치기'**
  String get gateEditQuestion;

  /// No description provided for @gateQuestionHint.
  ///
  /// In ko, this message translates to:
  /// **'질문 (예: 우리 모임에서 하고 싶은 건?)'**
  String get gateQuestionHint;

  /// No description provided for @gateQuizShort.
  ///
  /// In ko, this message translates to:
  /// **'객관식'**
  String get gateQuizShort;

  /// No description provided for @gateChoices.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get gateChoices;

  /// No description provided for @gateChoicesInfo.
  ///
  /// In ko, this message translates to:
  /// **'동그라미를 눌러 정답을 골라요. 정답은 신청하는 사람에게 보이지 않아요.'**
  String get gateChoicesInfo;

  /// No description provided for @gateChoiceHint.
  ///
  /// In ko, this message translates to:
  /// **'보기 {n}'**
  String gateChoiceHint(int n);

  /// No description provided for @gateAddChoice.
  ///
  /// In ko, this message translates to:
  /// **'보기 추가'**
  String get gateAddChoice;

  /// No description provided for @gateWrittenInfo.
  ///
  /// In ko, this message translates to:
  /// **'신청하는 사람이 글로 답해요. 관리자가 신청 목록에서 답을 볼 수 있어요.'**
  String get gateWrittenInfo;

  /// No description provided for @gateRemoveQuestion.
  ///
  /// In ko, this message translates to:
  /// **'질문 지우기'**
  String get gateRemoveQuestion;

  /// No description provided for @gateRules.
  ///
  /// In ko, this message translates to:
  /// **'심사 규칙'**
  String get gateRules;

  /// No description provided for @gateRulesInfo.
  ///
  /// In ko, this message translates to:
  /// **'객관식을 틀리거나 금지어가 있으면 거절해요. 사칭으로 확인된 계정도 거절하고, 확인 중인 계정은 관리자에게 넘겨요. 거절된 사람은 다시 신청할 수 있어요.'**
  String get gateRulesInfo;

  /// No description provided for @gateNeedAnswers.
  ///
  /// In ko, this message translates to:
  /// **'글 답을 비우면 거절'**
  String get gateNeedAnswers;

  /// No description provided for @gateWords.
  ///
  /// In ko, this message translates to:
  /// **'금지어'**
  String get gateWords;

  /// No description provided for @gateWordsInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름이나 답에 이 말이 있으면 거절해요. 한 줄에 하나씩, 최대 30개.'**
  String get gateWordsInfo;

  /// No description provided for @gateWordsHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 코인\n무료 지급'**
  String get gateWordsHint;

  /// No description provided for @gateAi.
  ///
  /// In ko, this message translates to:
  /// **'AI로 글 답 확인'**
  String get gateAi;

  /// No description provided for @gateAiInfo.
  ///
  /// In ko, this message translates to:
  /// **'글 답만 AI에게 보내요. AI는 들여보내거나 관리자에게 넘길 수만 있고, 혼자 거절하지 못해요.'**
  String get gateAiInfo;

  /// No description provided for @gateLog.
  ///
  /// In ko, this message translates to:
  /// **'심사 기록'**
  String get gateLog;

  /// No description provided for @gateLogNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 도우미가 확인한 신청이 없어요'**
  String get gateLogNone;

  /// No description provided for @gateLogInfo.
  ///
  /// In ko, this message translates to:
  /// **'최근 50개까지 보여요. 잘못 들어온 사람은 멤버 목록에서 내보내고, 잘못 거절된 사람은 다시 신청하면 돼요.'**
  String get gateLogInfo;

  /// No description provided for @gateWhyOk.
  ///
  /// In ko, this message translates to:
  /// **'질문을 모두 통과했어요'**
  String get gateWhyOk;

  /// No description provided for @gateWhyAi.
  ///
  /// In ko, this message translates to:
  /// **'AI가 답을 확인했어요'**
  String get gateWhyAi;

  /// No description provided for @gateWhyQuiz.
  ///
  /// In ko, this message translates to:
  /// **'객관식 답이 틀렸어요'**
  String get gateWhyQuiz;

  /// No description provided for @gateWhyEmpty.
  ///
  /// In ko, this message translates to:
  /// **'글 답을 비웠어요'**
  String get gateWhyEmpty;

  /// No description provided for @gateWhyWords.
  ///
  /// In ko, this message translates to:
  /// **'금지어가 있어요'**
  String get gateWhyWords;

  /// No description provided for @gateWhyFake.
  ///
  /// In ko, this message translates to:
  /// **'사칭으로 확인된 계정이에요'**
  String get gateWhyFake;

  /// No description provided for @gateWhyChecking.
  ///
  /// In ko, this message translates to:
  /// **'사칭 확인 중인 계정이에요'**
  String get gateWhyChecking;

  /// No description provided for @gateWhyHeld.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 확인해야 해요'**
  String get gateWhyHeld;

  /// No description provided for @gateIn.
  ///
  /// In ko, this message translates to:
  /// **'들어옴'**
  String get gateIn;

  /// No description provided for @gateOut.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get gateOut;

  /// No description provided for @gateHeld.
  ///
  /// In ko, this message translates to:
  /// **'관리자 확인'**
  String get gateHeld;

  /// No description provided for @gateSending.
  ///
  /// In ko, this message translates to:
  /// **'신청하고 있어요'**
  String get gateSending;

  /// No description provided for @gateYoureIn.
  ///
  /// In ko, this message translates to:
  /// **'들어왔어요'**
  String get gateYoureIn;

  /// No description provided for @gateYoureInBody.
  ///
  /// In ko, this message translates to:
  /// **'{name} 질문을 모두 통과했어요'**
  String gateYoureInBody(String name);

  /// No description provided for @gateNotIn.
  ///
  /// In ko, this message translates to:
  /// **'이번에는 들어갈 수 없어요'**
  String get gateNotIn;

  /// No description provided for @gateNotInBody.
  ///
  /// In ko, this message translates to:
  /// **'답을 다시 확인하고 나중에 다시 신청해 주세요'**
  String get gateNotInBody;

  /// No description provided for @gateFailed.
  ///
  /// In ko, this message translates to:
  /// **'신청하지 못했어요. 다시 해 주세요'**
  String get gateFailed;

  /// No description provided for @gateWaiting.
  ///
  /// In ko, this message translates to:
  /// **'신청했어요'**
  String get gateWaiting;

  /// No description provided for @gateWaitingBody.
  ///
  /// In ko, this message translates to:
  /// **'관리자가 확인하면 대화 목록에 나타나요'**
  String get gateWaitingBody;

  /// No description provided for @gateQuizIntro.
  ///
  /// In ko, this message translates to:
  /// **'질문 {count}개에 답하면 신청돼요'**
  String gateQuizIntro(int count);

  /// No description provided for @gateStep.
  ///
  /// In ko, this message translates to:
  /// **'질문 {now}/{total}'**
  String gateStep(int now, int total);

  /// No description provided for @gateTryAgain.
  ///
  /// In ko, this message translates to:
  /// **'아니에요. 다시 골라 보세요'**
  String get gateTryAgain;

  /// No description provided for @gateAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'답을 써 주세요'**
  String get gateAnswerHint;

  /// No description provided for @gateAnswersSeenBy.
  ///
  /// In ko, this message translates to:
  /// **'답은 이 방의 관리자와 가입 심사 도우미가 봐요. 암호화되지 않으니 개인 정보는 쓰지 마세요'**
  String get gateAnswersSeenBy;

  /// No description provided for @gateGoToGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹으로 가기'**
  String get gateGoToGroup;

  /// No description provided for @gateGoToChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널로 가기'**
  String get gateGoToChannel;

  /// No description provided for @gateSend.
  ///
  /// In ko, this message translates to:
  /// **'신청하기'**
  String get gateSend;

  /// No description provided for @gateAnswerAndAsk.
  ///
  /// In ko, this message translates to:
  /// **'질문에 답하고 신청하기'**
  String get gateAnswerAndAsk;

  /// No description provided for @gateHeldNote.
  ///
  /// In ko, this message translates to:
  /// **'도우미가 정하지 못한 신청만 여기 남아요'**
  String get gateHeldNote;

  /// No description provided for @community.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티'**
  String get community;

  /// No description provided for @communityAdd.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에 추가'**
  String get communityAdd;

  /// No description provided for @communityIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'그룹과 채널 여러 개를 하나로 묶어요. 멤버는 한곳에서 다른 대화를 보고 바로 들어갈 수 있어요.'**
  String get communityIntroBody;

  /// No description provided for @communityCreate.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 만들기'**
  String get communityCreate;

  /// No description provided for @communityMine.
  ///
  /// In ko, this message translates to:
  /// **'내 커뮤니티에 추가'**
  String get communityMine;

  /// No description provided for @communityNew.
  ///
  /// In ko, this message translates to:
  /// **'새 커뮤니티'**
  String get communityNew;

  /// No description provided for @communityName.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 이름'**
  String get communityName;

  /// No description provided for @communityAbout.
  ///
  /// In ko, this message translates to:
  /// **'소개 (선택)'**
  String get communityAbout;

  /// No description provided for @communityCreateBtn.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get communityCreateBtn;

  /// No description provided for @communityPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'어떤 대화가 묶였는지, 커뮤니티 이름이 무엇인지 서버는 몰라요. 멤버 휴대폰에서만 열려요.'**
  String get communityPrivacy;

  /// No description provided for @communityAsOne.
  ///
  /// In ko, this message translates to:
  /// **'한 대화로 보기'**
  String get communityAsOne;

  /// No description provided for @communityAsOneFooter.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티의 대화를 대화 목록에서 한 줄로 묶어요.'**
  String get communityAsOneFooter;

  /// No description provided for @communityIn.
  ///
  /// In ko, this message translates to:
  /// **'내가 들어간 대화'**
  String get communityIn;

  /// No description provided for @communityView.
  ///
  /// In ko, this message translates to:
  /// **'볼 수 있는 대화'**
  String get communityView;

  /// No description provided for @communityAsk.
  ///
  /// In ko, this message translates to:
  /// **'가입 요청할 수 있는 대화'**
  String get communityAsk;

  /// No description provided for @communityHiddenTag.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 보여요'**
  String get communityHiddenTag;

  /// No description provided for @communityAddChat.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에 대화 추가'**
  String get communityAddChat;

  /// No description provided for @communityWhoAdds.
  ///
  /// In ko, this message translates to:
  /// **'대화를 추가할 수 있는 사람'**
  String get communityWhoAdds;

  /// No description provided for @communityAddAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 멤버'**
  String get communityAddAll;

  /// No description provided for @communityAddAllInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 자기 그룹과 채널을 추가할 수 있어요.'**
  String get communityAddAllInfo;

  /// No description provided for @communityAddAdmins.
  ///
  /// In ko, this message translates to:
  /// **'관리자만'**
  String get communityAddAdmins;

  /// No description provided for @communityAddAdminsInfo.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 대화를 추가할 수 있어요. 서버가 직접 막아요.'**
  String get communityAddAdminsInfo;

  /// No description provided for @communityAdmins.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get communityAdmins;

  /// No description provided for @communityChats.
  ///
  /// In ko, this message translates to:
  /// **'대화 관리'**
  String get communityChats;

  /// No description provided for @communityChatsFooter.
  ///
  /// In ko, this message translates to:
  /// **'숨긴 대화는 관리자만 볼 수 있어요. 관리자 열쇠로 따로 잠가서 멤버 휴대폰도 못 열어요.'**
  String get communityChatsFooter;

  /// No description provided for @communityHide.
  ///
  /// In ko, this message translates to:
  /// **'숨기기'**
  String get communityHide;

  /// No description provided for @communityShow.
  ///
  /// In ko, this message translates to:
  /// **'보이기'**
  String get communityShow;

  /// No description provided for @communityRemoveChat.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에서 빼기'**
  String get communityRemoveChat;

  /// No description provided for @communityLeave.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 나가기'**
  String get communityLeave;

  /// No description provided for @communityLeaveInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 대화는 그대로 남고 커뮤니티만 안 보여요.'**
  String get communityLeaveInfo;

  /// No description provided for @communityDelete.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 없애기'**
  String get communityDelete;

  /// No description provided for @communityDeleteInfo.
  ///
  /// In ko, this message translates to:
  /// **'묶음만 없어지고 그룹과 채널은 그대로 남아요.'**
  String get communityDeleteInfo;

  /// No description provided for @communityRemovingIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 없어져요'**
  String communityRemovingIn(int seconds);

  /// No description provided for @communityCardGroup.
  ///
  /// In ko, this message translates to:
  /// **'이 그룹을 {name} 커뮤니티에 추가했어요'**
  String communityCardGroup(String name);

  /// No description provided for @communityCardChannel.
  ///
  /// In ko, this message translates to:
  /// **'이 채널을 {name} 커뮤니티에 추가했어요'**
  String communityCardChannel(String name);

  /// No description provided for @communityOpen.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get communityOpen;

  /// No description provided for @communityJoin.
  ///
  /// In ko, this message translates to:
  /// **'들어가기'**
  String get communityJoin;

  /// No description provided for @communityAskBtn.
  ///
  /// In ko, this message translates to:
  /// **'요청'**
  String get communityAskBtn;

  /// No description provided for @communityAskedBtn.
  ///
  /// In ko, this message translates to:
  /// **'요청함'**
  String get communityAskedBtn;

  /// No description provided for @communityAsked.
  ///
  /// In ko, this message translates to:
  /// **'가입을 요청했어요. 관리자가 받아 주면 들어가져요.'**
  String get communityAsked;

  /// No description provided for @communityMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String communityMembers(int count);

  /// No description provided for @communityChatsCount.
  ///
  /// In ko, this message translates to:
  /// **'대화 {count}개'**
  String communityChatsCount(int count);

  /// No description provided for @communityPickTitle.
  ///
  /// In ko, this message translates to:
  /// **'추가할 대화'**
  String get communityPickTitle;

  /// No description provided for @communityPickEmpty.
  ///
  /// In ko, this message translates to:
  /// **'추가할 수 있는 그룹이나 채널이 없어요. 내가 방장이나 관리자인 대화만 추가할 수 있어요.'**
  String get communityPickEmpty;

  /// No description provided for @communityPickHidden.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 보이게 추가'**
  String get communityPickHidden;

  /// No description provided for @communityPickFooter.
  ///
  /// In ko, this message translates to:
  /// **'링크가 없는 대화에는 \'승인 후 참여\' 비공개 링크가 새로 생겨요. 커뮤니티 멤버는 요청하고, 관리자가 받아 줘요.'**
  String get communityPickFooter;

  /// No description provided for @communityAddedToast.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티에 추가했어요'**
  String get communityAddedToast;

  /// No description provided for @communityNotYet.
  ///
  /// In ko, this message translates to:
  /// **'곧 커뮤니티에 들어가져요. 관리자 휴대폰이 열쇠를 보내 주면 바로 보여요.'**
  String get communityNotYet;

  /// No description provided for @communityEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없어요'**
  String get communityEmpty;

  /// No description provided for @communityOnlyAdmins.
  ///
  /// In ko, this message translates to:
  /// **'관리자만 할 수 있어요'**
  String get communityOnlyAdmins;

  /// No description provided for @communityInfo.
  ///
  /// In ko, this message translates to:
  /// **'커뮤니티 정보'**
  String get communityInfo;

  /// No description provided for @communityAdminsFooter.
  ///
  /// In ko, this message translates to:
  /// **'관리자는 대화를 추가·숨기기·빼기 할 수 있어요. 관리자가 되면 숨긴 대화 열쇠를 받아요.'**
  String get communityAdminsFooter;

  /// No description provided for @communityMakeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자로 지정'**
  String get communityMakeAdmin;

  /// No description provided for @communityUnmakeAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자 해제'**
  String get communityUnmakeAdmin;

  /// No description provided for @communityRoleOwner.
  ///
  /// In ko, this message translates to:
  /// **'방장'**
  String get communityRoleOwner;

  /// No description provided for @communityRoleAdmin.
  ///
  /// In ko, this message translates to:
  /// **'관리자'**
  String get communityRoleAdmin;

  /// No description provided for @communityLast.
  ///
  /// In ko, this message translates to:
  /// **'{who} › {chat}'**
  String communityLast(String who, String chat);

  /// No description provided for @searchFilter.
  ///
  /// In ko, this message translates to:
  /// **'종류로 찾기'**
  String get searchFilter;

  /// No description provided for @kindPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get kindPhoto;

  /// No description provided for @kindVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get kindVideo;

  /// No description provided for @kindFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get kindFile;

  /// No description provided for @kindLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get kindLink;

  /// No description provided for @kindVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get kindVoice;

  /// No description provided for @keywordReplies.
  ///
  /// In ko, this message translates to:
  /// **'키워드 자동 답장'**
  String get keywordReplies;

  /// No description provided for @keywordRepliesInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버 글에 이 단어가 있으면 정한 답을 내 이름으로 달아 줘요. 서버는 글을 못 읽어서 이 휴대폰이 답해요. 같은 단어는 1분에 한 번만 답해요.'**
  String get keywordRepliesInfo;

  /// No description provided for @keywordWordHint.
  ///
  /// In ko, this message translates to:
  /// **'단어 (예: 회비)'**
  String get keywordWordHint;

  /// No description provided for @keywordAnswerHint.
  ///
  /// In ko, this message translates to:
  /// **'답 (예: 회비는 매달 1만 원이에요)'**
  String get keywordAnswerHint;

  /// No description provided for @pollDescription.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get pollDescription;

  /// No description provided for @pollAddPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 넣기'**
  String get pollAddPhoto;

  /// No description provided for @pollRemovePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 빼기'**
  String get pollRemovePhoto;

  /// No description provided for @pollAttachTitle.
  ///
  /// In ko, this message translates to:
  /// **'선택지에 붙이기'**
  String get pollAttachTitle;

  /// No description provided for @pollAttachPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get pollAttachPhoto;

  /// No description provided for @pollAttachSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get pollAttachSticker;

  /// No description provided for @pollAttachPlace.
  ///
  /// In ko, this message translates to:
  /// **'지금 있는 곳'**
  String get pollAttachPlace;

  /// No description provided for @pollAttachRemove.
  ///
  /// In ko, this message translates to:
  /// **'붙인 것 빼기'**
  String get pollAttachRemove;

  /// No description provided for @pollAttachInfo.
  ///
  /// In ko, this message translates to:
  /// **'선택지마다 사진, 스티커, 장소 중 하나를 붙일 수 있어요. 사진은 이 휴대폰에서 암호화돼 올라가고, 장소는 지도 회사에 묻지 않고 숫자로만 담겨요.'**
  String get pollAttachInfo;

  /// No description provided for @pollPickSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커 고르기'**
  String get pollPickSticker;

  /// No description provided for @pollAllowAdd.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가 허용'**
  String get pollAllowAdd;

  /// No description provided for @pollAllowChange.
  ///
  /// In ko, this message translates to:
  /// **'투표 바꾸기 허용'**
  String get pollAllowChange;

  /// No description provided for @pollShuffle.
  ///
  /// In ko, this message translates to:
  /// **'선택지 순서 섞기'**
  String get pollShuffle;

  /// No description provided for @pollHideResults.
  ///
  /// In ko, this message translates to:
  /// **'마감까지 결과 숨기기'**
  String get pollHideResults;

  /// No description provided for @pollMoreInfo.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가: 멤버가 선택지를 더 넣을 수 있어요 (모두 12개까지, 넣은 사람 이름이 보여요). 순서 섞기: 사람마다 선택지 순서가 달라서 첫 줄에 몰리지 않아요.'**
  String get pollMoreInfo;

  /// No description provided for @pollHideAnonInfo.
  ///
  /// In ko, this message translates to:
  /// **'익명 투표에서 결과를 숨기면, 마감 전까지 숫자가 만든 사람 휴대폰 밖으로 나가지 않아요. 마감되면 그 휴대폰이 결과를 올려요.'**
  String get pollHideAnonInfo;

  /// No description provided for @pollHideOpenInfo.
  ///
  /// In ko, this message translates to:
  /// **'공개 투표의 표는 대화 안에 암호화돼 있어서 멤버 휴대폰에 함께 저장돼요. 마감 전까지는 앱이 숫자를 가려요.'**
  String get pollHideOpenInfo;

  /// No description provided for @pollNoChangeInfo.
  ///
  /// In ko, this message translates to:
  /// **'한 번 고르면 바꾸거나 취소할 수 없어요.'**
  String get pollNoChangeInfo;

  /// No description provided for @pollAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'선택지 추가'**
  String get pollAddTitle;

  /// No description provided for @pollAddDone.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get pollAddDone;

  /// No description provided for @pollAddInfo.
  ///
  /// In ko, this message translates to:
  /// **'내가 넣은 선택지에는 내 이름이 함께 보여요. 같은 선택지는 두 번 넣을 수 없어요.'**
  String get pollAddInfo;

  /// No description provided for @pollAddedBy.
  ///
  /// In ko, this message translates to:
  /// **'추가: {name}'**
  String pollAddedBy(String name);

  /// No description provided for @pollHiddenUntilEnd.
  ///
  /// In ko, this message translates to:
  /// **'결과는 마감 후 공개돼요'**
  String get pollHiddenUntilEnd;

  /// No description provided for @pollViewVotes.
  ///
  /// In ko, this message translates to:
  /// **'투표 결과 보기'**
  String get pollViewVotes;

  /// No description provided for @pollResults.
  ///
  /// In ko, this message translates to:
  /// **'투표 결과'**
  String get pollResults;

  /// No description provided for @pollVotesN.
  ///
  /// In ko, this message translates to:
  /// **'{n}표'**
  String pollVotesN(int n);

  /// No description provided for @pollNobodyYet.
  ///
  /// In ko, this message translates to:
  /// **'아직 아무도 고르지 않았어요'**
  String get pollNobodyYet;

  /// No description provided for @pollFinalShort.
  ///
  /// In ko, this message translates to:
  /// **'바꾸기 불가'**
  String get pollFinalShort;

  /// No description provided for @pollFull.
  ///
  /// In ko, this message translates to:
  /// **'선택지는 12개까지예요'**
  String get pollFull;

  /// No description provided for @pollRepeat.
  ///
  /// In ko, this message translates to:
  /// **'이미 있는 선택지예요'**
  String get pollRepeat;

  /// No description provided for @pollAnonResultsInfo.
  ///
  /// In ko, this message translates to:
  /// **'익명 투표라 누가 골랐는지는 아무에게도 보이지 않아요. 숫자만 보여요.'**
  String get pollAnonResultsInfo;

  /// No description provided for @pollChangeVote.
  ///
  /// In ko, this message translates to:
  /// **'투표 바꾸기'**
  String get pollChangeVote;

  /// No description provided for @articleWrite.
  ///
  /// In ko, this message translates to:
  /// **'긴 글 쓰기'**
  String get articleWrite;

  /// No description provided for @articleExpand.
  ///
  /// In ko, this message translates to:
  /// **'크게 쓰기'**
  String get articleExpand;

  /// No description provided for @articleTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get articleTitleHint;

  /// No description provided for @articleBodyHint.
  ///
  /// In ko, this message translates to:
  /// **'내용을 써 보세요'**
  String get articleBodyHint;

  /// No description provided for @articleReadAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 읽기'**
  String get articleReadAll;

  /// No description provided for @articleMinutes.
  ///
  /// In ko, this message translates to:
  /// **'약 {n}분'**
  String articleMinutes(int n);

  /// No description provided for @articleChars.
  ///
  /// In ko, this message translates to:
  /// **'{n}자'**
  String articleChars(int n);

  /// No description provided for @articleEncrypted.
  ///
  /// In ko, this message translates to:
  /// **'끝까지 암호화된 글이에요. 서버는 내용을 볼 수 없어요.'**
  String get articleEncrypted;

  /// No description provided for @articleOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'글을 열지 못했어요. 잠시 뒤 다시 해 주세요.'**
  String get articleOpenFailed;

  /// No description provided for @articleTooLong.
  ///
  /// In ko, this message translates to:
  /// **'글이 너무 길어요. 10만 자까지 쓸 수 있어요.'**
  String get articleTooLong;

  /// No description provided for @articleEmpty.
  ///
  /// In ko, this message translates to:
  /// **'보낼 내용이 없어요.'**
  String get articleEmpty;

  /// No description provided for @articleSending.
  ///
  /// In ko, this message translates to:
  /// **'보내는 중이에요…'**
  String get articleSending;

  /// No description provided for @articleDiscardAsk.
  ///
  /// In ko, this message translates to:
  /// **'쓰던 글을 어떻게 할까요?'**
  String get articleDiscardAsk;

  /// No description provided for @articleDiscard.
  ///
  /// In ko, this message translates to:
  /// **'버리기'**
  String get articleDiscard;

  /// No description provided for @articleKeepDraft.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장'**
  String get articleKeepDraft;

  /// No description provided for @articleDraftNote.
  ///
  /// In ko, this message translates to:
  /// **'임시 저장에는 사진이 빠져요.'**
  String get articleDraftNote;

  /// No description provided for @articleStyle.
  ///
  /// In ko, this message translates to:
  /// **'스타일'**
  String get articleStyle;

  /// No description provided for @articleInsert.
  ///
  /// In ko, this message translates to:
  /// **'넣기'**
  String get articleInsert;

  /// No description provided for @blockH1.
  ///
  /// In ko, this message translates to:
  /// **'큰 제목'**
  String get blockH1;

  /// No description provided for @blockH2.
  ///
  /// In ko, this message translates to:
  /// **'작은 제목'**
  String get blockH2;

  /// No description provided for @blockP.
  ///
  /// In ko, this message translates to:
  /// **'본문'**
  String get blockP;

  /// No description provided for @blockQuote.
  ///
  /// In ko, this message translates to:
  /// **'인용'**
  String get blockQuote;

  /// No description provided for @blockPull.
  ///
  /// In ko, this message translates to:
  /// **'큰 인용'**
  String get blockPull;

  /// No description provided for @blockCode.
  ///
  /// In ko, this message translates to:
  /// **'코드'**
  String get blockCode;

  /// No description provided for @blockMath.
  ///
  /// In ko, this message translates to:
  /// **'수식'**
  String get blockMath;

  /// No description provided for @blockUl.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get blockUl;

  /// No description provided for @blockOl.
  ///
  /// In ko, this message translates to:
  /// **'번호 목록'**
  String get blockOl;

  /// No description provided for @blockTable.
  ///
  /// In ko, this message translates to:
  /// **'표'**
  String get blockTable;

  /// No description provided for @blockImg.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get blockImg;

  /// No description provided for @blockHr.
  ///
  /// In ko, this message translates to:
  /// **'구분선'**
  String get blockHr;

  /// No description provided for @blockRemove.
  ///
  /// In ko, this message translates to:
  /// **'이 칸 지우기'**
  String get blockRemove;

  /// No description provided for @blockUp.
  ///
  /// In ko, this message translates to:
  /// **'위로 옮기기'**
  String get blockUp;

  /// No description provided for @blockDown.
  ///
  /// In ko, this message translates to:
  /// **'아래로 옮기기'**
  String get blockDown;

  /// No description provided for @articleCaptionHint.
  ///
  /// In ko, this message translates to:
  /// **'사진 설명 (선택)'**
  String get articleCaptionHint;

  /// No description provided for @articleMathHint.
  ///
  /// In ko, this message translates to:
  /// **'수식 (예: a^2 + b^2 = c^2)'**
  String get articleMathHint;

  /// No description provided for @articleCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'코드'**
  String get articleCodeHint;

  /// No description provided for @articleLangHint.
  ///
  /// In ko, this message translates to:
  /// **'언어 (선택)'**
  String get articleLangHint;

  /// No description provided for @articleItemHint.
  ///
  /// In ko, this message translates to:
  /// **'항목'**
  String get articleItemHint;

  /// No description provided for @tableAddRow.
  ///
  /// In ko, this message translates to:
  /// **'행 추가'**
  String get tableAddRow;

  /// No description provided for @tableAddCol.
  ///
  /// In ko, this message translates to:
  /// **'열 추가'**
  String get tableAddCol;

  /// No description provided for @tableDelRow.
  ///
  /// In ko, this message translates to:
  /// **'마지막 행 지우기'**
  String get tableDelRow;

  /// No description provided for @tableDelCol.
  ///
  /// In ko, this message translates to:
  /// **'마지막 열 지우기'**
  String get tableDelCol;

  /// No description provided for @tableHeader.
  ///
  /// In ko, this message translates to:
  /// **'첫 행을 머리글로'**
  String get tableHeader;

  /// No description provided for @articleAi.
  ///
  /// In ko, this message translates to:
  /// **'AI 도우미'**
  String get articleAi;

  /// No description provided for @articleAiInfo.
  ///
  /// In ko, this message translates to:
  /// **'모두 이 휴대폰 안에서만 처리돼요. 글 내용은 어디로도 보내지 않아요.'**
  String get articleAiInfo;

  /// No description provided for @aiTidy.
  ///
  /// In ko, this message translates to:
  /// **'자동 정리'**
  String get aiTidy;

  /// No description provided for @aiTidySub.
  ///
  /// In ko, this message translates to:
  /// **'# 제목, - 목록, | 표 |, \$\$수식\$\$ 같은 표시를 서식으로 바꿔요'**
  String get aiTidySub;

  /// No description provided for @aiPolish.
  ///
  /// In ko, this message translates to:
  /// **'AI로 다듬기'**
  String get aiPolish;

  /// No description provided for @aiPolishSub.
  ///
  /// In ko, this message translates to:
  /// **'고른 부분(없으면 지금 칸)을 자연스럽게 다듬어요'**
  String get aiPolishSub;

  /// No description provided for @aiShorter.
  ///
  /// In ko, this message translates to:
  /// **'짧게 줄이기'**
  String get aiShorter;

  /// No description provided for @aiShorterSub.
  ///
  /// In ko, this message translates to:
  /// **'핵심만 남겨요'**
  String get aiShorterSub;

  /// No description provided for @aiUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에서는 아직 AI 글쓰기를 쓸 수 없어요. 자동 정리는 쓸 수 있어요.'**
  String get aiUnavailable;

  /// No description provided for @aiDone.
  ///
  /// In ko, this message translates to:
  /// **'바꿨어요. 되돌리기로 돌아갈 수 있어요.'**
  String get aiDone;

  /// No description provided for @articleUndo.
  ///
  /// In ko, this message translates to:
  /// **'되돌리기'**
  String get articleUndo;

  /// No description provided for @articleRedo.
  ///
  /// In ko, this message translates to:
  /// **'다시 하기'**
  String get articleRedo;

  /// No description provided for @roomNight.
  ///
  /// In ko, this message translates to:
  /// **'야간 모드'**
  String get roomNight;

  /// No description provided for @roomNightInfo.
  ///
  /// In ko, this message translates to:
  /// **'정한 시간에는 멤버가 글을 쓸 수 없어요. 방장과 관리자는 계속 쓸 수 있어요. 시간은 지금 이 휴대폰 시간대를 따라요.'**
  String get roomNightInfo;

  /// No description provided for @nightRange.
  ///
  /// In ko, this message translates to:
  /// **'{from}시~{to}시'**
  String nightRange(int from, int to);

  /// No description provided for @nightBlocked.
  ///
  /// In ko, this message translates to:
  /// **'야간 모드예요. {hour}시부터 보낼 수 있어요'**
  String nightBlocked(int hour);

  /// No description provided for @sendToChannels.
  ///
  /// In ko, this message translates to:
  /// **'여러 채널에 함께 올리기'**
  String get sendToChannels;

  /// No description provided for @noOtherChannels.
  ///
  /// In ko, this message translates to:
  /// **'글을 올릴 수 있는 다른 채널이 없어요'**
  String get noOtherChannels;

  /// No description provided for @sendToCount.
  ///
  /// In ko, this message translates to:
  /// **'채널 {n}곳에 올리기'**
  String sendToCount(int n);

  /// No description provided for @sentToCount.
  ///
  /// In ko, this message translates to:
  /// **'채널 {n}곳에 올렸어요'**
  String sentToCount(int n);

  /// No description provided for @raidLock.
  ///
  /// In ko, this message translates to:
  /// **'습격 잠금'**
  String get raidLock;

  /// No description provided for @raidLockInfo.
  ///
  /// In ko, this message translates to:
  /// **'모르는 사람이 링크로 한꺼번에 몰려올 때 켜세요. 켜 두는 동안 링크로 들어오려는 사람은 모두 관리자 승인을 기다려요. 끄면 링크가 원래대로 돌아가요.'**
  String get raidLockInfo;

  /// No description provided for @mentionsOnly.
  ///
  /// In ko, this message translates to:
  /// **'나를 부를 때만 알림'**
  String get mentionsOnly;

  /// No description provided for @mentionsOnlyInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 그룹에서는 누군가 @내 이름이나 @모두로 불렀을 때만 알림이 와요. 다른 글은 조용히 쌓이고, 대화 목록의 숫자로 볼 수 있어요.'**
  String get mentionsOnlyInfo;

  /// No description provided for @messageRequests.
  ///
  /// In ko, this message translates to:
  /// **'메시지 요청'**
  String get messageRequests;

  /// No description provided for @messageRequestsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'메시지 요청이 없어요'**
  String get messageRequestsEmpty;

  /// No description provided for @messageRequestsInfo.
  ///
  /// In ko, this message translates to:
  /// **'연락처에 없는 사람이 보낸 1:1 대화예요. 수락하기 전에는 내가 읽었는지 상대가 알 수 없어요.'**
  String get messageRequestsInfo;

  /// No description provided for @messageRequestBar.
  ///
  /// In ko, this message translates to:
  /// **'연락처에 없는 사람이 보낸 메시지예요. 수락하면 답장할 수 있고, 삭제해도 상대에게 알리지 않아요.'**
  String get messageRequestBar;

  /// No description provided for @messageRequestAccept.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get messageRequestAccept;

  /// No description provided for @messageRequestDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get messageRequestDelete;

  /// No description provided for @messageRequestBlock.
  ///
  /// In ko, this message translates to:
  /// **'삭제하고 차단'**
  String get messageRequestBlock;

  /// No description provided for @messageRequestDeleteInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 대화를 지우고 나가요. 상대에게는 알리지 않아요.'**
  String get messageRequestDeleteInfo;

  /// No description provided for @messageRequestsSwitchInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 연락처에 없는 사람이 시작한 1:1 대화는 대화 목록 위 ‘메시지 요청’에 따로 모여요. 수락하기 전에는 알림이 조용하고 읽음 표시도 가지 않아요.'**
  String get messageRequestsSwitchInfo;

  /// No description provided for @nameColor.
  ///
  /// In ko, this message translates to:
  /// **'이름 색'**
  String get nameColor;

  /// No description provided for @nameColorSample.
  ///
  /// In ko, this message translates to:
  /// **'오늘 모임 몇 시예요?'**
  String get nameColorSample;

  /// No description provided for @nameColorInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹에서 내 메시지 위에 보이는 이름 색이에요. 내가 들어가 있는 모든 그룹에 똑같이 보여요. ‘A’는 이름에 따라 자동으로 정해지는 색이에요.'**
  String get nameColorInfo;

  /// No description provided for @roomName.
  ///
  /// In ko, this message translates to:
  /// **'이 그룹에서 내 이름'**
  String get roomName;

  /// No description provided for @roomNameHint.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get roomNameHint;

  /// No description provided for @roomNameInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 그룹 사람들에게만 이 이름으로 보여요. 다른 대화에서는 원래 이름 그대로예요. 비워 두면 원래 이름으로 돌아가요.'**
  String get roomNameInfo;

  /// No description provided for @liveLocation.
  ///
  /// In ko, this message translates to:
  /// **'실시간 위치'**
  String get liveLocation;

  /// No description provided for @liveLocationInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 시간 동안 내 위치가 1분마다 대화 안에서 움직여요. 위치는 이 대화 사람들에게만 암호화되어 가고, 언제든 멈출 수 있어요. 앱이 꺼져 있는 동안에는 움직이지 않아요.'**
  String get liveLocationInfo;

  /// No description provided for @live15m.
  ///
  /// In ko, this message translates to:
  /// **'15분 동안 공유'**
  String get live15m;

  /// No description provided for @live1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간 동안 공유'**
  String get live1h;

  /// No description provided for @live8h.
  ///
  /// In ko, this message translates to:
  /// **'8시간 동안 공유'**
  String get live8h;

  /// No description provided for @liveLocationEnded.
  ///
  /// In ko, this message translates to:
  /// **'실시간 위치 (끝남)'**
  String get liveLocationEnded;

  /// No description provided for @liveLeftMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 남음'**
  String liveLeftMinutes(int n);

  /// No description provided for @liveLeftHours.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 남음'**
  String liveLeftHours(int n);

  /// No description provided for @liveStop.
  ///
  /// In ko, this message translates to:
  /// **'공유 멈추기'**
  String get liveStop;

  /// No description provided for @editorAuto.
  ///
  /// In ko, this message translates to:
  /// **'자동'**
  String get editorAuto;

  /// No description provided for @editorDraw.
  ///
  /// In ko, this message translates to:
  /// **'그리기'**
  String get editorDraw;

  /// No description provided for @editorText.
  ///
  /// In ko, this message translates to:
  /// **'글씨'**
  String get editorText;

  /// No description provided for @editorClearAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 지우기'**
  String get editorClearAll;

  /// No description provided for @editorAddText.
  ///
  /// In ko, this message translates to:
  /// **'글씨 넣기'**
  String get editorAddText;

  /// No description provided for @penPen.
  ///
  /// In ko, this message translates to:
  /// **'펜'**
  String get penPen;

  /// No description provided for @penArrow.
  ///
  /// In ko, this message translates to:
  /// **'화살표'**
  String get penArrow;

  /// No description provided for @penMarker.
  ///
  /// In ko, this message translates to:
  /// **'형광펜'**
  String get penMarker;

  /// No description provided for @penNeon.
  ///
  /// In ko, this message translates to:
  /// **'네온'**
  String get penNeon;

  /// No description provided for @penEraser.
  ///
  /// In ko, this message translates to:
  /// **'지우개'**
  String get penEraser;

  /// No description provided for @penBlur.
  ///
  /// In ko, this message translates to:
  /// **'흐림'**
  String get penBlur;

  /// No description provided for @editAndSend.
  ///
  /// In ko, this message translates to:
  /// **'편집해서 보내기'**
  String get editAndSend;

  /// No description provided for @photoOf.
  ///
  /// In ko, this message translates to:
  /// **'{n}/{total}'**
  String photoOf(int n, int total);

  /// No description provided for @videoMutedToast.
  ///
  /// In ko, this message translates to:
  /// **'소리를 껐어요. GIF로 보내요'**
  String get videoMutedToast;

  /// No description provided for @videoSoundToast.
  ///
  /// In ko, this message translates to:
  /// **'소리를 켰어요'**
  String get videoSoundToast;

  /// No description provided for @sendTogether.
  ///
  /// In ko, this message translates to:
  /// **'묶어서 보내기'**
  String get sendTogether;

  /// No description provided for @sendSeparately.
  ///
  /// In ko, this message translates to:
  /// **'따로 보내기'**
  String get sendSeparately;

  /// No description provided for @sendSpoiler.
  ///
  /// In ko, this message translates to:
  /// **'가리고 보내기'**
  String get sendSpoiler;

  /// No description provided for @sendAsFileOriginal.
  ///
  /// In ko, this message translates to:
  /// **'파일로 보내기 (원본 화질)'**
  String get sendAsFileOriginal;

  /// No description provided for @albumRecents.
  ///
  /// In ko, this message translates to:
  /// **'최근 항목'**
  String get albumRecents;

  /// No description provided for @albumFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get albumFavorites;

  /// No description provided for @albumVideos.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get albumVideos;

  /// No description provided for @albumScreenshots.
  ///
  /// In ko, this message translates to:
  /// **'스크린샷'**
  String get albumScreenshots;

  /// No description provided for @albumSelfies.
  ///
  /// In ko, this message translates to:
  /// **'셀피'**
  String get albumSelfies;

  /// No description provided for @albumLive.
  ///
  /// In ko, this message translates to:
  /// **'Live Photos'**
  String get albumLive;

  /// No description provided for @newLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'누군가 새 기기로 내 계정에 로그인했어요'**
  String get newLoginTitle;

  /// No description provided for @newLoginBody.
  ///
  /// In ko, this message translates to:
  /// **'{device} · {when}. 본인이 맞나요?'**
  String newLoginBody(String device, String when);

  /// No description provided for @newLoginJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get newLoginJustNow;

  /// No description provided for @newLoginYes.
  ///
  /// In ko, this message translates to:
  /// **'네, 저예요'**
  String get newLoginYes;

  /// No description provided for @newLoginNo.
  ///
  /// In ko, this message translates to:
  /// **'아니요, 제가 아니에요'**
  String get newLoginNo;

  /// No description provided for @newLoginOut.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 로그아웃'**
  String get newLoginOut;

  /// No description provided for @newLoginOutDone.
  ///
  /// In ko, this message translates to:
  /// **'{device}을(를) 로그아웃시켰어요'**
  String newLoginOutDone(String device);

  /// No description provided for @newLoginChangePw.
  ///
  /// In ko, this message translates to:
  /// **'다시 들어오지 못하게 비밀번호도 바꾸는 게 좋아요.'**
  String get newLoginChangePw;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @ok.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get ok;

  /// No description provided for @deviceUnnamed.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 기기'**
  String get deviceUnnamed;

  /// No description provided for @deleteForMeOnly.
  ///
  /// In ko, this message translates to:
  /// **'나에게서만 지우기'**
  String get deleteForMeOnly;

  /// No description provided for @deleteForBothShort.
  ///
  /// In ko, this message translates to:
  /// **'나와 상대 모두에게서 지우기'**
  String get deleteForBothShort;

  /// No description provided for @deleteForMeAnd.
  ///
  /// In ko, this message translates to:
  /// **'나와 {name} 모두에게서 지우기'**
  String deleteForMeAnd(String name);

  /// No description provided for @dateWipeTitle.
  ///
  /// In ko, this message translates to:
  /// **'날짜로 지우기'**
  String get dateWipeTitle;

  /// No description provided for @dateWipeHint.
  ///
  /// In ko, this message translates to:
  /// **'하루를 누르거나, 두 날짜를 눌러 그 사이를 모두 골라요. 진하게 보이는 날에 메시지가 있어요.'**
  String get dateWipeHint;

  /// No description provided for @dateWipePick.
  ///
  /// In ko, this message translates to:
  /// **'날짜를 골라 주세요'**
  String get dateWipePick;

  /// No description provided for @dateWipeButton.
  ///
  /// In ko, this message translates to:
  /// **'{range} 메시지 {count}개 지우기'**
  String dateWipeButton(String range, int count);

  /// No description provided for @dateWipeAsk.
  ///
  /// In ko, this message translates to:
  /// **'메시지 {count}개를 지울까요?'**
  String dateWipeAsk(int count);

  /// No description provided for @dateWipeIn.
  ///
  /// In ko, this message translates to:
  /// **'{left}초 뒤 지워요'**
  String dateWipeIn(int left);

  /// No description provided for @dateWipeMenu.
  ///
  /// In ko, this message translates to:
  /// **'날짜로 지우기'**
  String get dateWipeMenu;

  /// No description provided for @voiceBlockedLine.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지 (받지 않게 해 둔 사람)'**
  String get voiceBlockedLine;

  /// No description provided for @voiceClosedTitle.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지를 보낼 수 없어요'**
  String get voiceClosedTitle;

  /// No description provided for @voiceClosedBody.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 음성·영상 메시지를 받지 않게 해 두었어요. 글이나 사진은 보낼 수 있어요.'**
  String voiceClosedBody(String name);

  /// No description provided for @whoVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성·영상 메시지'**
  String get whoVoice;

  /// No description provided for @whoVoiceInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 사람만 나에게 음성 메시지와 동그라미 영상을 보낼 수 있어요. 1:1 대화에 적용돼요. 상대 앱에는 마이크 버튼이 흐리게 보여요.'**
  String get whoVoiceInfo;

  /// No description provided for @strangerArchive.
  ///
  /// In ko, this message translates to:
  /// **'모르는 사람 새 대화 보관하기'**
  String get strangerArchive;

  /// No description provided for @strangerArchiveSub.
  ///
  /// In ko, this message translates to:
  /// **'친구가 아닌 사람의 첫 메시지는 알림 없이 보관함으로 가요.'**
  String get strangerArchiveSub;

  /// No description provided for @strangerTucked.
  ///
  /// In ko, this message translates to:
  /// **'모르는 사람의 새 대화를 보관함에 넣었어요'**
  String get strangerTucked;

  /// No description provided for @callsEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get callsEdit;

  /// No description provided for @callsSelect.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get callsSelect;

  /// No description provided for @callsClearAll.
  ///
  /// In ko, this message translates to:
  /// **'통화 기록 모두 지우기'**
  String get callsClearAll;

  /// No description provided for @callsDeleteN.
  ///
  /// In ko, this message translates to:
  /// **'지우기 ({count})'**
  String callsDeleteN(int count);

  /// No description provided for @callsDeleteAsk.
  ///
  /// In ko, this message translates to:
  /// **'통화 기록 {count}개를 지울까요?'**
  String callsDeleteAsk(int count);

  /// No description provided for @callsDeleteIn.
  ///
  /// In ko, this message translates to:
  /// **'{left}초 뒤 통화 기록을 지워요'**
  String callsDeleteIn(int left);

  /// No description provided for @callsDeleteBothNote.
  ///
  /// In ko, this message translates to:
  /// **'양쪽에서 지우면 상대 휴대폰의 기록도 사라져요.'**
  String get callsDeleteBothNote;

  /// No description provided for @deviceSheetCalls.
  ///
  /// In ko, this message translates to:
  /// **'이 기기로 통화 받기'**
  String get deviceSheetCalls;

  /// No description provided for @deviceSheetCallsSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 이 기기는 전화가 와도 울리지 않아요.'**
  String get deviceSheetCallsSub;

  /// No description provided for @deviceSheetOut.
  ///
  /// In ko, this message translates to:
  /// **'이 기기 로그아웃'**
  String get deviceSheetOut;

  /// No description provided for @deviceSheetLastSeen.
  ///
  /// In ko, this message translates to:
  /// **'마지막 사용'**
  String get deviceSheetLastSeen;

  /// No description provided for @deviceSheetKind.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get deviceSheetKind;

  /// No description provided for @deviceKindPhone.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰'**
  String get deviceKindPhone;

  /// No description provided for @deviceKindPc.
  ///
  /// In ko, this message translates to:
  /// **'PC'**
  String get deviceKindPc;

  /// No description provided for @deviceKindWeb.
  ///
  /// In ko, this message translates to:
  /// **'웹'**
  String get deviceKindWeb;

  /// No description provided for @deviceIdleTitle.
  ///
  /// In ko, this message translates to:
  /// **'오래 안 쓴 기기 자동 로그아웃'**
  String get deviceIdleTitle;

  /// No description provided for @deviceIdleInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 기간 동안 한 번도 쓰지 않은 기기는 서버가 알아서 로그아웃시켜요. 잃어버린 휴대폰이나 남의 PC에 남은 로그인을 막아요.'**
  String get deviceIdleInfo;

  /// No description provided for @deviceIdleOff.
  ///
  /// In ko, this message translates to:
  /// **'안 함'**
  String get deviceIdleOff;

  /// No description provided for @idleDays7.
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get idleDays7;

  /// No description provided for @idleDays30.
  ///
  /// In ko, this message translates to:
  /// **'1개월'**
  String get idleDays30;

  /// No description provided for @idleDays90.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get idleDays90;

  /// No description provided for @idleDays180.
  ///
  /// In ko, this message translates to:
  /// **'6개월'**
  String get idleDays180;

  /// No description provided for @idleDays365.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get idleDays365;

  /// No description provided for @linkPc.
  ///
  /// In ko, this message translates to:
  /// **'QR로 PC 연결'**
  String get linkPc;

  /// No description provided for @linkPcInfo.
  ///
  /// In ko, this message translates to:
  /// **'PC 부루미 화면의 QR을 이 휴대폰으로 찍으면 비밀번호 없이 바로 로그인돼요.'**
  String get linkPcInfo;

  /// No description provided for @linkPcScanTitle.
  ///
  /// In ko, this message translates to:
  /// **'PC 화면의 QR 찍기'**
  String get linkPcScanTitle;

  /// No description provided for @linkPcStep1.
  ///
  /// In ko, this message translates to:
  /// **'PC에서 부루미를 열어요.'**
  String get linkPcStep1;

  /// No description provided for @linkPcStep2.
  ///
  /// In ko, this message translates to:
  /// **'로그인 화면의 \'QR로 로그인\'을 눌러요.'**
  String get linkPcStep2;

  /// No description provided for @linkPcStep3.
  ///
  /// In ko, this message translates to:
  /// **'이 화면으로 PC의 QR을 찍어요.'**
  String get linkPcStep3;

  /// No description provided for @linkPcConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 PC에 로그인할까요?'**
  String get linkPcConfirmTitle;

  /// No description provided for @linkPcConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'{device}. 내가 지금 직접 띄운 화면이 맞을 때만 눌러요. 누가 보내 준 QR이면 절대 찍지 마세요.'**
  String linkPcConfirmBody(String device);

  /// No description provided for @linkPcConfirm.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get linkPcConfirm;

  /// No description provided for @linkPcDone.
  ///
  /// In ko, this message translates to:
  /// **'PC에 로그인했어요. PC에서 이모지 확인을 마치면 예전 대화도 보여요.'**
  String get linkPcDone;

  /// No description provided for @linkPcBad.
  ///
  /// In ko, this message translates to:
  /// **'부루미 PC 로그인 QR이 아니에요'**
  String get linkPcBad;

  /// No description provided for @linkPcExpired.
  ///
  /// In ko, this message translates to:
  /// **'QR 시간이 지났어요. PC에서 새 QR을 띄워 주세요.'**
  String get linkPcExpired;

  /// No description provided for @linkPcNoCamera.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 카메라로 찍을 수 없어요. 휴대폰 앱에서 해 주세요.'**
  String get linkPcNoCamera;

  /// No description provided for @qrLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'QR로 로그인'**
  String get qrLoginTitle;

  /// No description provided for @qrLoginStep1.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰에서 부루미를 열어요.'**
  String get qrLoginStep1;

  /// No description provided for @qrLoginStep2.
  ///
  /// In ko, this message translates to:
  /// **'설정 > 기기 > QR로 PC 연결을 눌러요.'**
  String get qrLoginStep2;

  /// No description provided for @qrLoginStep3.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰으로 이 QR을 찍어요.'**
  String get qrLoginStep3;

  /// No description provided for @qrLoginWaiting.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰에서 확인하기를 기다리는 중…'**
  String get qrLoginWaiting;

  /// No description provided for @qrLoginNew.
  ///
  /// In ko, this message translates to:
  /// **'새 QR 만들기'**
  String get qrLoginNew;

  /// No description provided for @qrLoginPassword.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호로 로그인'**
  String get qrLoginPassword;

  /// No description provided for @qrLoginOff.
  ///
  /// In ko, this message translates to:
  /// **'이 앱은 아직 QR 로그인 서버에 연결되지 않았어요.'**
  String get qrLoginOff;

  /// No description provided for @phoneCall.
  ///
  /// In ko, this message translates to:
  /// **'전화 걸기'**
  String get phoneCall;

  /// No description provided for @phoneText.
  ///
  /// In ko, this message translates to:
  /// **'문자 보내기'**
  String get phoneText;

  /// No description provided for @phoneCopy.
  ///
  /// In ko, this message translates to:
  /// **'번호 복사'**
  String get phoneCopy;

  /// No description provided for @phoneSave.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 연락처에 저장'**
  String get phoneSave;

  /// No description provided for @phoneCopied.
  ///
  /// In ko, this message translates to:
  /// **'번호를 복사했어요'**
  String get phoneCopied;

  /// No description provided for @videoNoteOnceHint.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기: 받는 사람이 한 번 본 뒤 사라져요'**
  String get videoNoteOnceHint;

  /// No description provided for @onceRoundSent.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 보기'**
  String get onceRoundSent;

  /// No description provided for @onceRoundExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료된 영상 메시지'**
  String get onceRoundExpired;

  /// No description provided for @onceRoundClose.
  ///
  /// In ko, this message translates to:
  /// **'닫고 삭제'**
  String get onceRoundClose;

  /// No description provided for @storyScrubHint.
  ///
  /// In ko, this message translates to:
  /// **'좌우로 밀어 이동'**
  String get storyScrubHint;

  /// No description provided for @camFlashWarm.
  ///
  /// In ko, this message translates to:
  /// **'따뜻함'**
  String get camFlashWarm;

  /// No description provided for @camFlashBright.
  ///
  /// In ko, this message translates to:
  /// **'밝기'**
  String get camFlashBright;

  /// No description provided for @camFlashFront.
  ///
  /// In ko, this message translates to:
  /// **'앞카메라로 찍을 때 화면이 이 색으로 밝아져요'**
  String get camFlashFront;

  /// No description provided for @birthdayBannerOne.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 오늘 생일이에요!'**
  String birthdayBannerOne(String name);

  /// No description provided for @birthdayBannerMany.
  ///
  /// In ko, this message translates to:
  /// **'친구 {n}명이 오늘 생일이에요!'**
  String birthdayBannerMany(int n);

  /// No description provided for @birthdayBannerSub.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 축하 메시지를 보내 보세요'**
  String get birthdayBannerSub;

  /// No description provided for @birthdayTodayLine.
  ///
  /// In ko, this message translates to:
  /// **'오늘 생일 🎂 · {date}'**
  String birthdayTodayLine(String date);

  /// No description provided for @firstHelloTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 메시지가 없어요'**
  String get firstHelloTitle;

  /// No description provided for @firstHelloSub.
  ///
  /// In ko, this message translates to:
  /// **'아래 인사를 눌러 첫 마디를 건네 보세요'**
  String get firstHelloSub;

  /// No description provided for @firstHelloTap.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 {name}님에게 인사 보내기'**
  String firstHelloTap(String name);

  /// No description provided for @liveTextButton.
  ///
  /// In ko, this message translates to:
  /// **'글자'**
  String get liveTextButton;

  /// No description provided for @liveTextTitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 속 글자'**
  String get liveTextTitle;

  /// No description provided for @liveTextHint.
  ///
  /// In ko, this message translates to:
  /// **'줄을 눌러 고르세요. 안 고르면 전부 복사해요'**
  String get liveTextHint;

  /// No description provided for @liveTextPicked.
  ///
  /// In ko, this message translates to:
  /// **'{n}줄 골랐어요'**
  String liveTextPicked(int n);

  /// No description provided for @liveTextNoneSel.
  ///
  /// In ko, this message translates to:
  /// **'선택 해제'**
  String get liveTextNoneSel;

  /// No description provided for @liveTextCopied.
  ///
  /// In ko, this message translates to:
  /// **'글자를 복사했어요'**
  String get liveTextCopied;

  /// No description provided for @liveTextPaste.
  ///
  /// In ko, this message translates to:
  /// **'입력칸을 길게 눌러 붙여넣으세요'**
  String get liveTextPaste;

  /// No description provided for @liveTextNone.
  ///
  /// In ko, this message translates to:
  /// **'이 사진에서 글자를 찾지 못했어요'**
  String get liveTextNone;

  /// No description provided for @liveTextAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 선택'**
  String get liveTextAll;

  /// No description provided for @callNoteAsk.
  ///
  /// In ko, this message translates to:
  /// **'받지 않았어요. 메시지를 남길까요?'**
  String get callNoteAsk;

  /// No description provided for @callNoteVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성 남기기'**
  String get callNoteVoice;

  /// No description provided for @callNoteVideo.
  ///
  /// In ko, this message translates to:
  /// **'영상 남기기'**
  String get callNoteVideo;

  /// No description provided for @callNoteTo.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 남길 말'**
  String callNoteTo(String name);

  /// No description provided for @callNoteVoiceHint.
  ///
  /// In ko, this message translates to:
  /// **'누르면 녹음해요. 한 번 더 누르면 보내요.'**
  String get callNoteVoiceHint;

  /// No description provided for @idKey.
  ///
  /// In ko, this message translates to:
  /// **'아이디 키'**
  String get idKey;

  /// No description provided for @idKeyMine.
  ///
  /// In ko, this message translates to:
  /// **'내 키'**
  String get idKeyMine;

  /// No description provided for @idKeyHint.
  ///
  /// In ko, this message translates to:
  /// **'예: blue7'**
  String get idKeyHint;

  /// No description provided for @idKeyInfo.
  ///
  /// In ko, this message translates to:
  /// **'키를 정하면, 처음 대화하는 사람은 아이디와 이 키를 둘 다 알아야 메시지를 보낼 수 있어요. 키가 틀리면 메시지가 오지 않고, 보낸 사람에게도 알리지 않아요. 친구와 이미 대화한 사람은 그대로예요. 키는 이 폰에만 있고 서버로 가지 않아요. 글자·숫자 4~20자예요.'**
  String get idKeyInfo;

  /// No description provided for @idKeyBad.
  ///
  /// In ko, this message translates to:
  /// **'글자나 숫자로 4~20자를 써 주세요.'**
  String get idKeyBad;

  /// No description provided for @idKeyOff.
  ///
  /// In ko, this message translates to:
  /// **'키 끄기'**
  String get idKeyOff;

  /// No description provided for @idKeyOffInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 기다리던 처음 대화도 다시 들어와요.'**
  String get idKeyOffInfo;

  /// No description provided for @idKeyEnterHint.
  ///
  /// In ko, this message translates to:
  /// **'아이디 키 (받았다면)'**
  String get idKeyEnterHint;

  /// No description provided for @idKeyEnterInfo.
  ///
  /// In ko, this message translates to:
  /// **'상대가 아이디 키를 알려 줬다면 같이 써요. 처음 대화할 때만 필요해요.'**
  String get idKeyEnterInfo;

  /// No description provided for @voiceToText.
  ///
  /// In ko, this message translates to:
  /// **'글로 보기'**
  String get voiceToText;

  /// No description provided for @voiceToTextFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 폰에서는 글로 바꿀 수 없어요. 폰 설정에서 음성 인식 언어를 내려받으면 돼요.'**
  String get voiceToTextFailed;

  /// No description provided for @voiceToTextEmpty.
  ///
  /// In ko, this message translates to:
  /// **'들리는 말이 없어요.'**
  String get voiceToTextEmpty;

  /// No description provided for @voiceToTextOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'이 폰 안에서만 바꿨어요'**
  String get voiceToTextOnPhone;

  /// No description provided for @voiceTranslate.
  ///
  /// In ko, this message translates to:
  /// **'번역'**
  String get voiceTranslate;

  /// No description provided for @voiceTranslating.
  ///
  /// In ko, this message translates to:
  /// **'번역하는 중…'**
  String get voiceTranslating;

  /// No description provided for @voiceShowOriginal.
  ///
  /// In ko, this message translates to:
  /// **'번역 숨기기'**
  String get voiceShowOriginal;

  /// No description provided for @unreadSummaryAsk.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 메시지 {count}개 요약 보기'**
  String unreadSummaryAsk(int count);

  /// No description provided for @unreadSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 메시지 요약'**
  String get unreadSummaryTitle;

  /// No description provided for @unreadSummaryFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 요약할 수 없어요. 글로 된 메시지만 요약해요.'**
  String get unreadSummaryFailed;

  /// No description provided for @unreadSummaryOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'이 폰 AI로만 요약했어요. 대화는 폰 밖으로 나가지 않아요.'**
  String get unreadSummaryOnPhone;

  /// No description provided for @postSummaryButton.
  ///
  /// In ko, this message translates to:
  /// **'요약'**
  String get postSummaryButton;

  /// No description provided for @postSummaryBusy.
  ///
  /// In ko, this message translates to:
  /// **'요약하는 중…'**
  String get postSummaryBusy;

  /// No description provided for @postSummaryOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원문 보기'**
  String get postSummaryOriginal;

  /// No description provided for @postSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 요약'**
  String get postSummaryTitle;

  /// No description provided for @postSummaryFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 요약할 수 없어요. 잠시 뒤 다시 해 보세요.'**
  String get postSummaryFailed;

  /// No description provided for @postSummaryOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'이 폰 AI로만 요약했어요. 글은 폰 밖으로 나가지 않아요.'**
  String get postSummaryOnPhone;

  /// No description provided for @postSummarySwitch.
  ///
  /// In ko, this message translates to:
  /// **'긴 글 요약'**
  String get postSummarySwitch;

  /// No description provided for @postSummarySwitchSub.
  ///
  /// In ko, this message translates to:
  /// **'그룹·채널의 긴 글 위에 \'요약\' 버튼이 보여요'**
  String get postSummarySwitchSub;

  /// No description provided for @readerButton.
  ///
  /// In ko, this message translates to:
  /// **'읽기 모드'**
  String get readerButton;

  /// No description provided for @readerMenu.
  ///
  /// In ko, this message translates to:
  /// **'읽기 모드로 열기'**
  String get readerMenu;

  /// No description provided for @readerLoading.
  ///
  /// In ko, this message translates to:
  /// **'페이지를 가져오는 중…'**
  String get readerLoading;

  /// No description provided for @readerFailed.
  ///
  /// In ko, this message translates to:
  /// **'이 페이지는 읽기 모드로 열 수 없어요. 브라우저로 열어 보세요.'**
  String get readerFailed;

  /// No description provided for @readerOpenBrowser.
  ///
  /// In ko, this message translates to:
  /// **'브라우저로 열기'**
  String get readerOpenBrowser;

  /// No description provided for @readerTextSize.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get readerTextSize;

  /// No description provided for @readerMinutes.
  ///
  /// In ko, this message translates to:
  /// **'{minutes}분 읽기'**
  String readerMinutes(int minutes);

  /// No description provided for @readerSummaryAsk.
  ///
  /// In ko, this message translates to:
  /// **'AI로 3줄 요약 보기'**
  String get readerSummaryAsk;

  /// No description provided for @readerFootnote.
  ///
  /// In ko, this message translates to:
  /// **'이 폰이 사이트에서 직접 가져와 읽기 좋게 정리했어요. 부루미 서버는 어떤 글을 읽었는지 몰라요.'**
  String get readerFootnote;

  /// No description provided for @readerLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'링크를 복사했어요'**
  String get readerLinkCopied;

  /// No description provided for @readerSwitch.
  ///
  /// In ko, this message translates to:
  /// **'링크에 \'읽기 모드\' 버튼 보이기'**
  String get readerSwitch;

  /// No description provided for @readerSwitchInfo.
  ///
  /// In ko, this message translates to:
  /// **'기사 링크를 광고·메뉴 없이 깔끔한 글로 읽어요. 이 폰이 사이트에서 직접 가져오고, 부루미 서버는 거치지 않아요.'**
  String get readerSwitchInfo;

  /// No description provided for @audioPlay.
  ///
  /// In ko, this message translates to:
  /// **'재생'**
  String get audioPlay;

  /// No description provided for @audioPause.
  ///
  /// In ko, this message translates to:
  /// **'일시 정지'**
  String get audioPause;

  /// No description provided for @audioPrevious.
  ///
  /// In ko, this message translates to:
  /// **'이전 곡'**
  String get audioPrevious;

  /// No description provided for @audioNext.
  ///
  /// In ko, this message translates to:
  /// **'다음 곡'**
  String get audioNext;

  /// No description provided for @audioRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get audioRepeat;

  /// No description provided for @audioRepeatOff.
  ///
  /// In ko, this message translates to:
  /// **'반복하지 않아요'**
  String get audioRepeatOff;

  /// No description provided for @audioRepeatAll.
  ///
  /// In ko, this message translates to:
  /// **'목록 전체를 반복해요'**
  String get audioRepeatAll;

  /// No description provided for @audioRepeatOne.
  ///
  /// In ko, this message translates to:
  /// **'이 곡만 반복해요'**
  String get audioRepeatOne;

  /// No description provided for @audioPlaylist.
  ///
  /// In ko, this message translates to:
  /// **'재생 목록 {count}곡'**
  String audioPlaylist(int count);

  /// No description provided for @audioSpeedTitle.
  ///
  /// In ko, this message translates to:
  /// **'재생 속도'**
  String get audioSpeedTitle;

  /// No description provided for @audioSpeedPlain.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get audioSpeedPlain;

  /// No description provided for @audioSpeedNormal.
  ///
  /// In ko, this message translates to:
  /// **'보통 속도로 재생해요'**
  String get audioSpeedNormal;

  /// No description provided for @audioSpeedSet.
  ///
  /// In ko, this message translates to:
  /// **'{speed}배 속도로 재생해요'**
  String audioSpeedSet(String speed);

  /// No description provided for @protectIntroInfoDm.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에서는 나와 상대 모두 아래 일을 할 수 없어요.'**
  String get protectIntroInfoDm;

  /// No description provided for @protectIntroInfoRoom.
  ///
  /// In ko, this message translates to:
  /// **'이 방의 모든 멤버가 아래 일을 할 수 없어요.'**
  String get protectIntroInfoRoom;

  /// No description provided for @protectIntroShot.
  ///
  /// In ko, this message translates to:
  /// **'화면 캡처·녹화 막기'**
  String get protectIntroShot;

  /// No description provided for @protectIntroShotSub.
  ///
  /// In ko, this message translates to:
  /// **'캡처하거나 녹화하면 대화가 까맣게 나와요'**
  String get protectIntroShotSub;

  /// No description provided for @protectIntroForward.
  ///
  /// In ko, this message translates to:
  /// **'전달 막기'**
  String get protectIntroForward;

  /// No description provided for @protectIntroForwardSub.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 다른 대화로 보낼 수 없어요'**
  String get protectIntroForwardSub;

  /// No description provided for @protectIntroSave.
  ///
  /// In ko, this message translates to:
  /// **'저장·복사 막기'**
  String get protectIntroSave;

  /// No description provided for @protectIntroSaveSub.
  ///
  /// In ko, this message translates to:
  /// **'사진·영상 저장과 글 복사가 안 돼요'**
  String get protectIntroSaveSub;

  /// No description provided for @protectIntroOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'끌 수 있는 사람은 켠 나뿐이에요.'**
  String get protectIntroOnlyMe;

  /// No description provided for @protectNoticeMine.
  ///
  /// In ko, this message translates to:
  /// **'내가 이 대화의 공유를 막았어요'**
  String get protectNoticeMine;

  /// No description provided for @protectNoticeOther.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 이 대화의 공유를 막았어요'**
  String protectNoticeOther(String name);

  /// No description provided for @protectNoticeRoom.
  ///
  /// In ko, this message translates to:
  /// **'이 방은 공유가 막혀 있어요'**
  String get protectNoticeRoom;

  /// No description provided for @protectMenuFooter.
  ///
  /// In ko, this message translates to:
  /// **'공유가 막힌 대화라 복사·전달·저장할 수 없어요'**
  String get protectMenuFooter;

  /// No description provided for @protectOnlyOwner.
  ///
  /// In ko, this message translates to:
  /// **'상대가 켠 공유 비활성화는 상대만 끌 수 있어요'**
  String get protectOnlyOwner;

  /// No description provided for @protectByOther.
  ///
  /// In ko, this message translates to:
  /// **'공유 비활성화 (상대가 켬)'**
  String get protectByOther;

  /// No description provided for @reportStepTitle.
  ///
  /// In ko, this message translates to:
  /// **'무엇이 문제인가요?'**
  String get reportStepTitle;

  /// No description provided for @reportSubTitle.
  ///
  /// In ko, this message translates to:
  /// **'조금 더 알려 주세요'**
  String get reportSubTitle;

  /// No description provided for @reportNoteTitle.
  ///
  /// In ko, this message translates to:
  /// **'더 알려 줄 내용 (선택)'**
  String get reportNoteTitle;

  /// No description provided for @reportNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 이 사람이 여러 방에 같은 글을 올려요'**
  String get reportNoteHint;

  /// No description provided for @reportSend.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportSend;

  /// No description provided for @reportUrgentLine.
  ///
  /// In ko, this message translates to:
  /// **'이 신고는 운영자가 가장 먼저 봐요'**
  String get reportUrgentLine;

  /// No description provided for @reportDislikeInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 신고는 운영자에게 가지 않아요. 이 폰에서 이렇게 할 수 있어요.'**
  String get reportDislikeInfo;

  /// No description provided for @reportDislikeHide.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지 내 폰에서 숨기기'**
  String get reportDislikeHide;

  /// No description provided for @reportDislikeBlock.
  ///
  /// In ko, this message translates to:
  /// **'보낸 사람 차단하기'**
  String get reportDislikeBlock;

  /// No description provided for @reportDislikeHidden.
  ///
  /// In ko, this message translates to:
  /// **'이 메시지를 내 폰에서 숨겼어요'**
  String get reportDislikeHidden;

  /// No description provided for @reportCopyrightInfo.
  ///
  /// In ko, this message translates to:
  /// **'저작권 침해는 권리자(만든 사람이나 회사)가 직접 신고해요. 웹 신고서에서 원본과 연락처를 적어 주세요.'**
  String get reportCopyrightInfo;

  /// No description provided for @reportCopyrightOpen.
  ///
  /// In ko, this message translates to:
  /// **'권리자 신고서 열기'**
  String get reportCopyrightOpen;

  /// No description provided for @reportHiddenMsg.
  ///
  /// In ko, this message translates to:
  /// **'내 폰에서 숨긴 메시지예요'**
  String get reportHiddenMsg;

  /// No description provided for @rDislike.
  ///
  /// In ko, this message translates to:
  /// **'그냥 싫어요'**
  String get rDislike;

  /// No description provided for @rChild.
  ///
  /// In ko, this message translates to:
  /// **'아동 학대·아동 성착취'**
  String get rChild;

  /// No description provided for @rChildSexual.
  ///
  /// In ko, this message translates to:
  /// **'아동 성착취물'**
  String get rChildSexual;

  /// No description provided for @rChildAbuse.
  ///
  /// In ko, this message translates to:
  /// **'아동 폭행·학대'**
  String get rChildAbuse;

  /// No description provided for @rChildDanger.
  ///
  /// In ko, this message translates to:
  /// **'아동을 노리는 접근 (그루밍)'**
  String get rChildDanger;

  /// No description provided for @rSexualCrime.
  ///
  /// In ko, this message translates to:
  /// **'불법 촬영물·성착취물 (합성 포함)'**
  String get rSexualCrime;

  /// No description provided for @rHiddenCamera.
  ///
  /// In ko, this message translates to:
  /// **'몰래 찍은 사진·영상'**
  String get rHiddenCamera;

  /// No description provided for @rDeepfake.
  ///
  /// In ko, this message translates to:
  /// **'합성한 사진·영상 (딥페이크)'**
  String get rDeepfake;

  /// No description provided for @rSharedNoConsent.
  ///
  /// In ko, this message translates to:
  /// **'동의 없이 퍼뜨린 사진'**
  String get rSharedNoConsent;

  /// No description provided for @rExtortion.
  ///
  /// In ko, this message translates to:
  /// **'사진으로 하는 협박'**
  String get rExtortion;

  /// No description provided for @rViolence.
  ///
  /// In ko, this message translates to:
  /// **'폭력이나 위협'**
  String get rViolence;

  /// No description provided for @rThreat.
  ///
  /// In ko, this message translates to:
  /// **'나나 다른 사람을 해치겠다는 위협'**
  String get rThreat;

  /// No description provided for @rGraphic.
  ///
  /// In ko, this message translates to:
  /// **'잔인한 장면'**
  String get rGraphic;

  /// No description provided for @rSelfHarm.
  ///
  /// In ko, this message translates to:
  /// **'자해·자살 부추김'**
  String get rSelfHarm;

  /// No description provided for @rHate.
  ///
  /// In ko, this message translates to:
  /// **'혐오 표현'**
  String get rHate;

  /// No description provided for @rGoods.
  ///
  /// In ko, this message translates to:
  /// **'불법 상품·서비스'**
  String get rGoods;

  /// No description provided for @rDrugs.
  ///
  /// In ko, this message translates to:
  /// **'마약·불법 약물'**
  String get rDrugs;

  /// No description provided for @rWeapons.
  ///
  /// In ko, this message translates to:
  /// **'무기'**
  String get rWeapons;

  /// No description provided for @rFakeDocs.
  ///
  /// In ko, this message translates to:
  /// **'위조 문서·신분증'**
  String get rFakeDocs;

  /// No description provided for @rGoodsOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 불법 거래'**
  String get rGoodsOther;

  /// No description provided for @rAdult.
  ///
  /// In ko, this message translates to:
  /// **'음란물'**
  String get rAdult;

  /// No description provided for @rPorn.
  ///
  /// In ko, this message translates to:
  /// **'성인 음란물'**
  String get rPorn;

  /// No description provided for @rUnwanted.
  ///
  /// In ko, this message translates to:
  /// **'원치 않는 성적인 메시지'**
  String get rUnwanted;

  /// No description provided for @rPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 노출'**
  String get rPrivacy;

  /// No description provided for @rIdDocs.
  ///
  /// In ko, this message translates to:
  /// **'신분증·주민등록번호'**
  String get rIdDocs;

  /// No description provided for @rContact.
  ///
  /// In ko, this message translates to:
  /// **'전화번호·주소'**
  String get rContact;

  /// No description provided for @rPhotos.
  ///
  /// In ko, this message translates to:
  /// **'내 사진을 허락 없이 올림'**
  String get rPhotos;

  /// No description provided for @rTerror.
  ///
  /// In ko, this message translates to:
  /// **'테러·극단주의'**
  String get rTerror;

  /// No description provided for @rTerrorPromo.
  ///
  /// In ko, this message translates to:
  /// **'테러를 칭찬하거나 알리기'**
  String get rTerrorPromo;

  /// No description provided for @rTerrorRecruit.
  ///
  /// In ko, this message translates to:
  /// **'테러 계획·사람 모으기'**
  String get rTerrorRecruit;

  /// No description provided for @rScam.
  ///
  /// In ko, this message translates to:
  /// **'사기·스팸'**
  String get rScam;

  /// No description provided for @rPhishing.
  ///
  /// In ko, this message translates to:
  /// **'가짜 링크로 비밀번호 빼 가기 (피싱)'**
  String get rPhishing;

  /// No description provided for @rMoney.
  ///
  /// In ko, this message translates to:
  /// **'돈 사기·투자 사기'**
  String get rMoney;

  /// No description provided for @rSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸 광고'**
  String get rSpam;

  /// No description provided for @rCopyright.
  ///
  /// In ko, this message translates to:
  /// **'저작권 침해'**
  String get rCopyright;

  /// No description provided for @rTakedown.
  ///
  /// In ko, this message translates to:
  /// **'불법은 아니지만 내려야 해요'**
  String get rTakedown;

  /// No description provided for @firstPhotoChanged.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진 바뀜'**
  String get firstPhotoChanged;

  /// No description provided for @firstNameChanged.
  ///
  /// In ko, this message translates to:
  /// **'이름 바뀜'**
  String get firstNameChanged;

  /// No description provided for @firstDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String firstDaysAgo(int n);

  /// No description provided for @firstToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get firstToday;

  /// No description provided for @firstNotChanged.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일 없음'**
  String get firstNotChanged;

  /// No description provided for @firstGroupsTitle.
  ///
  /// In ko, this message translates to:
  /// **'같이 있는 그룹'**
  String get firstGroupsTitle;

  /// No description provided for @firstGroupsNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get firstGroupsNone;

  /// No description provided for @firstAboutTitle.
  ///
  /// In ko, this message translates to:
  /// **'처음 대화하는 사람이에요'**
  String get firstAboutTitle;

  /// No description provided for @ageQuarter.
  ///
  /// In ko, this message translates to:
  /// **'1~3개월 전'**
  String get ageQuarter;

  /// No description provided for @ageHalf.
  ///
  /// In ko, this message translates to:
  /// **'3개월~1년 전'**
  String get ageHalf;

  /// No description provided for @firstNotFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구가 아닌 사람이에요'**
  String get firstNotFriend;

  /// No description provided for @onceVoice.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 듣기 음성'**
  String get onceVoice;

  /// No description provided for @onceVoiceTap.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 한 번 들어요'**
  String get onceVoiceTap;

  /// No description provided for @onceVoiceSent.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 들을 수 있어요'**
  String get onceVoiceSent;

  /// No description provided for @onceVoiceExpired.
  ///
  /// In ko, this message translates to:
  /// **'들은 음성 메시지'**
  String get onceVoiceExpired;

  /// No description provided for @onceVoiceOn.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 듣기 켜짐: 상대가 한 번 들으면 사라져요'**
  String get onceVoiceOn;

  /// No description provided for @onceVoiceOff.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 듣기 꺼짐'**
  String get onceVoiceOff;

  /// No description provided for @onceVoiceHint.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 한 번만 재생되게 해요'**
  String get onceVoiceHint;

  /// No description provided for @onceVoiceClose.
  ///
  /// In ko, this message translates to:
  /// **'닫고 삭제'**
  String get onceVoiceClose;

  /// No description provided for @onceVoiceInfo.
  ///
  /// In ko, this message translates to:
  /// **'한 번 들으면 사라져요. 저장하거나 전달할 수 없어요.'**
  String get onceVoiceInfo;

  /// No description provided for @permMediaAll.
  ///
  /// In ko, this message translates to:
  /// **'미디어 보내기'**
  String get permMediaAll;

  /// No description provided for @permPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진'**
  String get permPhoto;

  /// No description provided for @permVideo.
  ///
  /// In ko, this message translates to:
  /// **'동영상'**
  String get permVideo;

  /// No description provided for @permFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get permFile;

  /// No description provided for @permMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get permMusic;

  /// No description provided for @permVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get permVoice;

  /// No description provided for @permVideoNote.
  ///
  /// In ko, this message translates to:
  /// **'동그라미 영상'**
  String get permVideoNote;

  /// No description provided for @permExceptions.
  ///
  /// In ko, this message translates to:
  /// **'예외'**
  String get permExceptions;

  /// No description provided for @permExceptionAdd.
  ///
  /// In ko, this message translates to:
  /// **'예외 추가'**
  String get permExceptionAdd;

  /// No description provided for @permExceptionInfo.
  ///
  /// In ko, this message translates to:
  /// **'특정 멤버만 다르게 정할 수 있어요. 방장과 관리자는 늘 모두 쓸 수 있어요.'**
  String get permExceptionInfo;

  /// No description provided for @permExceptionRemove.
  ///
  /// In ko, this message translates to:
  /// **'예외 지우기'**
  String get permExceptionRemove;

  /// No description provided for @permExceptionCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}개 다름'**
  String permExceptionCount(int n);

  /// No description provided for @permPickMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버 고르기'**
  String get permPickMember;

  /// No description provided for @permTextLocked.
  ///
  /// In ko, this message translates to:
  /// **'이 방에서는 글을 보낼 수 없어요'**
  String get permTextLocked;

  /// No description provided for @permKindBlocked.
  ///
  /// In ko, this message translates to:
  /// **'이 방에서는 {what} 보내기가 막혀 있어요'**
  String permKindBlocked(String what);

  /// No description provided for @reportBlockedSender.
  ///
  /// In ko, this message translates to:
  /// **'보낸 사람을 차단했어요'**
  String get reportBlockedSender;

  /// No description provided for @shareHistory.
  ///
  /// In ko, this message translates to:
  /// **'최근 메시지 50개 같이 보내기'**
  String get shareHistory;

  /// No description provided for @shareHistoryInfo.
  ///
  /// In ko, this message translates to:
  /// **'새 멤버가 들어오기 전 대화도 읽을 수 있게 내 폰이 보내 줘요. 그 사람 폰으로만 암호화해서 가고, 서버는 내용을 몰라요. 글만 보내고 사진·파일은 보내지 않아요.'**
  String get shareHistoryInfo;

  /// No description provided for @sendHistory.
  ///
  /// In ko, this message translates to:
  /// **'지난 메시지 보내기'**
  String get sendHistory;

  /// No description provided for @sendHistoryDone.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 지난 메시지 {count}개를 보냈어요'**
  String sendHistoryDone(int count, String name);

  /// No description provided for @earlierBar.
  ///
  /// In ko, this message translates to:
  /// **'들어오기 전 대화 {count}개 보기'**
  String earlierBar(int count);

  /// No description provided for @earlierTitle.
  ///
  /// In ko, this message translates to:
  /// **'들어오기 전 대화'**
  String get earlierTitle;

  /// No description provided for @earlierInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 내 폰으로만 보내 준 지난 메시지예요. 이 폰에만 있어요.'**
  String get earlierInfo;

  /// No description provided for @earlierMedia.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 사진이나 파일 ({time})'**
  String earlierMedia(String name, String time);

  /// No description provided for @fmtQuote.
  ///
  /// In ko, this message translates to:
  /// **'인용'**
  String get fmtQuote;

  /// No description provided for @fmtFoldQuote.
  ///
  /// In ko, this message translates to:
  /// **'접는 인용'**
  String get fmtFoldQuote;

  /// No description provided for @replyFromOtherChat.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 다른 대화'**
  String replyFromOtherChat(String name);

  /// No description provided for @quotingWho.
  ///
  /// In ko, this message translates to:
  /// **'인용 · {name}'**
  String quotingWho(String name);

  /// No description provided for @quotePickPart.
  ///
  /// In ko, this message translates to:
  /// **'특정 부분 인용'**
  String get quotePickPart;

  /// No description provided for @replyInOtherChat.
  ///
  /// In ko, this message translates to:
  /// **'다른 대화에서 답장'**
  String get replyInOtherChat;

  /// No description provided for @replyNone.
  ///
  /// In ko, this message translates to:
  /// **'답장 안 함'**
  String get replyNone;

  /// No description provided for @replyInWhichChat.
  ///
  /// In ko, this message translates to:
  /// **'답장할 대화'**
  String get replyInWhichChat;

  /// No description provided for @quotePickTitle.
  ///
  /// In ko, this message translates to:
  /// **'인용할 부분'**
  String get quotePickTitle;

  /// No description provided for @quotePickHint.
  ///
  /// In ko, this message translates to:
  /// **'손잡이를 끌어 인용할 부분을 골라요'**
  String get quotePickHint;

  /// No description provided for @quotePickCount.
  ///
  /// In ko, this message translates to:
  /// **'고른 글자 {n}자'**
  String quotePickCount(int n);

  /// No description provided for @pinAlsoFor.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게도 고정'**
  String pinAlsoFor(String name);

  /// No description provided for @pinAlsoForOn.
  ///
  /// In ko, this message translates to:
  /// **'두 사람 모두에게 보여요.'**
  String get pinAlsoForOn;

  /// No description provided for @pinOnlyMeInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에서 나만 봐요. 상대방에게는 아무것도 가지 않아요.'**
  String get pinOnlyMeInfo;

  /// No description provided for @pinnedOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 보이게 고정했어요'**
  String get pinnedOnlyMe;

  /// No description provided for @pinOnlyMeTag.
  ///
  /// In ko, this message translates to:
  /// **'나만'**
  String get pinOnlyMeTag;

  /// No description provided for @attachScan.
  ///
  /// In ko, this message translates to:
  /// **'문서 스캔'**
  String get attachScan;

  /// No description provided for @scanFileName.
  ///
  /// In ko, this message translates to:
  /// **'스캔 {time}'**
  String scanFileName(String time);

  /// No description provided for @scanNotHere.
  ///
  /// In ko, this message translates to:
  /// **'문서 스캔은 폰 앱에서 쓸 수 있어요'**
  String get scanNotHere;

  /// No description provided for @pack_hip.
  ///
  /// In ko, this message translates to:
  /// **'힙 프렌즈'**
  String get pack_hip;

  /// No description provided for @pack_dandy.
  ///
  /// In ko, this message translates to:
  /// **'댄디 프렌즈'**
  String get pack_dandy;

  /// No description provided for @charEmojiTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 이모지'**
  String charEmojiTitle(String name);

  /// No description provided for @charReactionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터 반응'**
  String get charReactionsTitle;

  /// No description provided for @translate.
  ///
  /// In ko, this message translates to:
  /// **'번역'**
  String get translate;

  /// No description provided for @trToLang.
  ///
  /// In ko, this message translates to:
  /// **'{lang}로 번역하기'**
  String trToLang(String lang);

  /// No description provided for @trShowOriginal.
  ///
  /// In ko, this message translates to:
  /// **'원문 보기'**
  String get trShowOriginal;

  /// No description provided for @trOtherLang.
  ///
  /// In ko, this message translates to:
  /// **'다른 언어로 번역'**
  String get trOtherLang;

  /// No description provided for @trDontTranslate.
  ///
  /// In ko, this message translates to:
  /// **'{lang} 번역하지 않기'**
  String trDontTranslate(String lang);

  /// No description provided for @trHideBar.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에서 가리기'**
  String get trHideBar;

  /// No description provided for @trHiddenNote.
  ///
  /// In ko, this message translates to:
  /// **'번역 줄을 가렸어요. 메시지를 꾹 눌러 번역을 열면 다시 켤 수 있어요.'**
  String get trHiddenNote;

  /// No description provided for @trShowButton.
  ///
  /// In ko, this message translates to:
  /// **'번역 버튼 보기'**
  String get trShowButton;

  /// No description provided for @trShowButtonSub.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 꾹 누르면 번역이 나와요'**
  String get trShowButtonSub;

  /// No description provided for @trChat.
  ///
  /// In ko, this message translates to:
  /// **'대화 전체 번역'**
  String get trChat;

  /// No description provided for @trChatSub.
  ///
  /// In ko, this message translates to:
  /// **'다른 언어 대화 위에 번역 줄이 나와요'**
  String get trChatSub;

  /// No description provided for @trSkip.
  ///
  /// In ko, this message translates to:
  /// **'번역하지 않을 언어'**
  String get trSkip;

  /// No description provided for @trFooter.
  ///
  /// In ko, this message translates to:
  /// **'번역은 이 휴대폰 안에서만 해요. 글이 번역 서버로 가지 않아요. 언어마다 처음 한 번만 받아요 (와이파이, 약 30MB).'**
  String get trFooter;

  /// No description provided for @trWebDemo.
  ///
  /// In ko, this message translates to:
  /// **'웹 미리보기는 정해진 예시 번역만 보여 줘요.'**
  String get trWebDemo;

  /// No description provided for @trAppLang.
  ///
  /// In ko, this message translates to:
  /// **'앱 언어'**
  String get trAppLang;

  /// No description provided for @trDownloadAsk.
  ///
  /// In ko, this message translates to:
  /// **'{lang} 번역을 받을까요?'**
  String trDownloadAsk(String lang);

  /// No description provided for @trDownloadInfo.
  ///
  /// In ko, this message translates to:
  /// **'한 번만 받으면 인터넷 없이도 번역돼요. 와이파이에서 받아요 (약 30MB).'**
  String get trDownloadInfo;

  /// No description provided for @trDownload.
  ///
  /// In ko, this message translates to:
  /// **'받기'**
  String get trDownload;

  /// No description provided for @trDownloading.
  ///
  /// In ko, this message translates to:
  /// **'받는 중…'**
  String get trDownloading;

  /// No description provided for @trDownloadFailed.
  ///
  /// In ko, this message translates to:
  /// **'받지 못했어요. 와이파이에 연결한 뒤 다시 해 주세요.'**
  String get trDownloadFailed;

  /// No description provided for @trUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 휴대폰에서는 번역할 수 없어요'**
  String get trUnsupported;

  /// No description provided for @trFailed.
  ///
  /// In ko, this message translates to:
  /// **'번역하지 못했어요'**
  String get trFailed;

  /// No description provided for @trSameLang.
  ///
  /// In ko, this message translates to:
  /// **'이미 {lang}예요'**
  String trSameLang(String lang);

  /// No description provided for @trWholeChatOn.
  ///
  /// In ko, this message translates to:
  /// **'대화 전체 번역 켜기'**
  String get trWholeChatOn;

  /// No description provided for @trTranslating.
  ///
  /// In ko, this message translates to:
  /// **'번역하는 중…'**
  String get trTranslating;

  /// No description provided for @trLang_ko.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get trLang_ko;

  /// No description provided for @trLang_en.
  ///
  /// In ko, this message translates to:
  /// **'영어'**
  String get trLang_en;

  /// No description provided for @trLang_ja.
  ///
  /// In ko, this message translates to:
  /// **'일본어'**
  String get trLang_ja;

  /// No description provided for @trLang_zh.
  ///
  /// In ko, this message translates to:
  /// **'중국어'**
  String get trLang_zh;

  /// No description provided for @trLang_es.
  ///
  /// In ko, this message translates to:
  /// **'스페인어'**
  String get trLang_es;

  /// No description provided for @trLang_fr.
  ///
  /// In ko, this message translates to:
  /// **'프랑스어'**
  String get trLang_fr;

  /// No description provided for @trLang_de.
  ///
  /// In ko, this message translates to:
  /// **'독일어'**
  String get trLang_de;

  /// No description provided for @trLang_ru.
  ///
  /// In ko, this message translates to:
  /// **'러시아어'**
  String get trLang_ru;

  /// No description provided for @trLang_pt.
  ///
  /// In ko, this message translates to:
  /// **'포르투갈어'**
  String get trLang_pt;

  /// No description provided for @trLang_it.
  ///
  /// In ko, this message translates to:
  /// **'이탈리아어'**
  String get trLang_it;

  /// No description provided for @trLang_vi.
  ///
  /// In ko, this message translates to:
  /// **'베트남어'**
  String get trLang_vi;

  /// No description provided for @trLang_th.
  ///
  /// In ko, this message translates to:
  /// **'태국어'**
  String get trLang_th;

  /// No description provided for @trLang_id.
  ///
  /// In ko, this message translates to:
  /// **'인도네시아어'**
  String get trLang_id;

  /// No description provided for @trLang_tr.
  ///
  /// In ko, this message translates to:
  /// **'튀르키예어'**
  String get trLang_tr;

  /// No description provided for @trLang_ar.
  ///
  /// In ko, this message translates to:
  /// **'아랍어'**
  String get trLang_ar;

  /// No description provided for @trLang_hi.
  ///
  /// In ko, this message translates to:
  /// **'힌디어'**
  String get trLang_hi;

  /// No description provided for @trLang_uk.
  ///
  /// In ko, this message translates to:
  /// **'우크라이나어'**
  String get trLang_uk;

  /// No description provided for @trLang_pl.
  ///
  /// In ko, this message translates to:
  /// **'폴란드어'**
  String get trLang_pl;

  /// No description provided for @trLang_nl.
  ///
  /// In ko, this message translates to:
  /// **'네덜란드어'**
  String get trLang_nl;

  /// No description provided for @newLoginMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String newLoginMinutesAgo(int n);

  /// No description provided for @deviceIdlePage.
  ///
  /// In ko, this message translates to:
  /// **'자동 로그아웃'**
  String get deviceIdlePage;

  /// No description provided for @deviceIdleHeader.
  ///
  /// In ko, this message translates to:
  /// **'이 기간 동안 안 쓰면 로그아웃'**
  String get deviceIdleHeader;

  /// No description provided for @whoInfoVoice.
  ///
  /// In ko, this message translates to:
  /// **'내 연락처가 아닌 사람의 전화는 부재중으로 남고, 메시지·초대는 보이지 않아요. 음성·영상 메시지를 막은 사람은 마이크 버튼이 잠겨서 글로만 보낼 수 있어요.'**
  String get whoInfoVoice;

  /// No description provided for @qrLoginHeading.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰으로 QR을 찍어 로그인'**
  String get qrLoginHeading;

  /// No description provided for @searchTabChats.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get searchTabChats;

  /// No description provided for @searchTabChannels.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get searchTabChannels;

  /// No description provided for @searchTabPosts.
  ///
  /// In ko, this message translates to:
  /// **'글'**
  String get searchTabPosts;

  /// No description provided for @searchTabMedia.
  ///
  /// In ko, this message translates to:
  /// **'미디어'**
  String get searchTabMedia;

  /// No description provided for @searchTabLinks.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get searchTabLinks;

  /// No description provided for @searchTabFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get searchTabFiles;

  /// No description provided for @searchTabMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get searchTabMusic;

  /// No description provided for @searchTabVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성'**
  String get searchTabVoice;

  /// No description provided for @searchSectionChats.
  ///
  /// In ko, this message translates to:
  /// **'대화'**
  String get searchSectionChats;

  /// No description provided for @searchSectionGlobal.
  ///
  /// In ko, this message translates to:
  /// **'전체 검색'**
  String get searchSectionGlobal;

  /// No description provided for @searchSectionMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get searchSectionMessages;

  /// No description provided for @searchScopeAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화'**
  String get searchScopeAll;

  /// No description provided for @searchScopeDirect.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화'**
  String get searchScopeDirect;

  /// No description provided for @searchScopeGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get searchScopeGroup;

  /// No description provided for @searchScopeChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get searchScopeChannel;

  /// No description provided for @searchScopeTitle.
  ///
  /// In ko, this message translates to:
  /// **'어느 대화에서 찾을까요?'**
  String get searchScopeTitle;

  /// No description provided for @searchRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 검색'**
  String get searchRecent;

  /// No description provided for @searchClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get searchClear;

  /// No description provided for @searchMyChannels.
  ///
  /// In ko, this message translates to:
  /// **'참여한 채널'**
  String get searchMyChannels;

  /// No description provided for @searchPublicChannels.
  ///
  /// In ko, this message translates to:
  /// **'공개 채널'**
  String get searchPublicChannels;

  /// No description provided for @searchFollowedPosts.
  ///
  /// In ko, this message translates to:
  /// **'구독한 채널의 글'**
  String get searchFollowedPosts;

  /// No description provided for @searchPublicPosts.
  ///
  /// In ko, this message translates to:
  /// **'공개 채널 글'**
  String get searchPublicPosts;

  /// No description provided for @searchPublicPostsNote.
  ///
  /// In ko, this message translates to:
  /// **'웹 페이지를 켠 공개 채널의 글만 보여요. 찾는 단어는 서버에 남지 않아요.'**
  String get searchPublicPostsNote;

  /// No description provided for @searchPostsHint.
  ///
  /// In ko, this message translates to:
  /// **'채널 글에서 찾을 단어를 써 주세요'**
  String get searchPostsHint;

  /// No description provided for @searchChannelsHint.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름이나 주소를 써 주세요'**
  String get searchChannelsHint;

  /// No description provided for @searchOnPhoneNote.
  ///
  /// In ko, this message translates to:
  /// **'메시지·사진·파일은 이 휴대폰 안에서만 찾아요. 서버는 무엇을 찾는지 몰라요.'**
  String get searchOnPhoneNote;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'찾는 결과가 없어요'**
  String get searchNoResults;

  /// No description provided for @searchMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get searchMore;

  /// No description provided for @searchLess.
  ///
  /// In ko, this message translates to:
  /// **'접기'**
  String get searchLess;

  /// No description provided for @tagThisChat.
  ///
  /// In ko, this message translates to:
  /// **'이 대화'**
  String get tagThisChat;

  /// No description provided for @tagMyMessages.
  ///
  /// In ko, this message translates to:
  /// **'내 메시지'**
  String get tagMyMessages;

  /// No description provided for @tagPublicPosts.
  ///
  /// In ko, this message translates to:
  /// **'공개 글'**
  String get tagPublicPosts;

  /// No description provided for @tagShowChat.
  ///
  /// In ko, this message translates to:
  /// **'대화로 보기'**
  String get tagShowChat;

  /// No description provided for @tagShowList.
  ///
  /// In ko, this message translates to:
  /// **'목록으로 보기'**
  String get tagShowList;

  /// No description provided for @tagShowGrid.
  ///
  /// In ko, this message translates to:
  /// **'사진으로 보기'**
  String get tagShowGrid;

  /// No description provided for @tagJoinToSee.
  ///
  /// In ko, this message translates to:
  /// **'참여하면 이 대화의 글을 볼 수 있어요'**
  String get tagJoinToSee;

  /// No description provided for @tagOpenChat.
  ///
  /// In ko, this message translates to:
  /// **'미리 보기'**
  String get tagOpenChat;

  /// No description provided for @tagStoriesTitle.
  ///
  /// In ko, this message translates to:
  /// **'해시태그 스토리'**
  String get tagStoriesTitle;

  /// No description provided for @tagStoriesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 해시태그가 붙은 스토리가 없어요'**
  String get tagStoriesEmpty;

  /// No description provided for @tagStoriesNote.
  ///
  /// In ko, this message translates to:
  /// **'내가 볼 수 있는 친구 스토리에서만 찾아요'**
  String get tagStoriesNote;

  /// No description provided for @searchMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {n}명'**
  String searchMembers(int n);

  /// No description provided for @searchSubscribers.
  ///
  /// In ko, this message translates to:
  /// **'구독자 {n}명'**
  String searchSubscribers(int n);

  /// No description provided for @tagCount.
  ///
  /// In ko, this message translates to:
  /// **'메시지 {n}개'**
  String tagCount(int n);

  /// No description provided for @tagStories.
  ///
  /// In ko, this message translates to:
  /// **'스토리 {n}개'**
  String tagStories(int n);

  /// No description provided for @tagInChat.
  ///
  /// In ko, this message translates to:
  /// **'대화: {address}'**
  String tagInChat(String address);

  /// No description provided for @tagStoriesSub.
  ///
  /// In ko, this message translates to:
  /// **'스토리 보기 · {tag}'**
  String tagStoriesSub(String tag);

  /// No description provided for @dayRangeSameMonth.
  ///
  /// In ko, this message translates to:
  /// **'{from}–{day}일'**
  String dayRangeSameMonth(String from, int day);

  /// No description provided for @stkWeather.
  ///
  /// In ko, this message translates to:
  /// **'날씨'**
  String get stkWeather;

  /// No description provided for @stkPlace.
  ///
  /// In ko, this message translates to:
  /// **'위치'**
  String get stkPlace;

  /// No description provided for @stkLink.
  ///
  /// In ko, this message translates to:
  /// **'링크'**
  String get stkLink;

  /// No description provided for @stkWeatherTitle.
  ///
  /// In ko, this message translates to:
  /// **'날씨 스티커'**
  String get stkWeatherTitle;

  /// No description provided for @stkWeatherHere.
  ///
  /// In ko, this message translates to:
  /// **'지금 있는 곳'**
  String get stkWeatherHere;

  /// No description provided for @stkWeatherHereSub.
  ///
  /// In ko, this message translates to:
  /// **'위치를 약 10km 단위로 뭉개서 날씨만 물어봐요'**
  String get stkWeatherHereSub;

  /// No description provided for @stkWeatherCity.
  ///
  /// In ko, this message translates to:
  /// **'도시 고르기'**
  String get stkWeatherCity;

  /// No description provided for @stkWeatherCitySub.
  ///
  /// In ko, this message translates to:
  /// **'위치를 전혀 쓰지 않아요'**
  String get stkWeatherCitySub;

  /// No description provided for @stkWeatherFinding.
  ///
  /// In ko, this message translates to:
  /// **'날씨를 가져오는 중이에요'**
  String get stkWeatherFinding;

  /// No description provided for @stkWeatherShowCity.
  ///
  /// In ko, this message translates to:
  /// **'도시 이름 보이기'**
  String get stkWeatherShowCity;

  /// No description provided for @stkWeatherInfo.
  ///
  /// In ko, this message translates to:
  /// **'스토리에는 온도와 날씨만 들어가요. 내 위치는 친구에게도, 부루미에도 남지 않아요. 친구는 자기 나라 단위(°C·°F)로 보고, 눌러서 바꿀 수 있어요.'**
  String get stkWeatherInfo;

  /// No description provided for @stkWeatherNoLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치를 쓸 수 없어서 도시를 골라 주세요'**
  String get stkWeatherNoLocation;

  /// No description provided for @stkWeatherOff.
  ///
  /// In ko, this message translates to:
  /// **'이 버전에서는 날씨를 가져올 수 없어요'**
  String get stkWeatherOff;

  /// No description provided for @stkWeatherNetwork.
  ///
  /// In ko, this message translates to:
  /// **'날씨를 가져오지 못했어요. 잠시 뒤 다시 해 주세요'**
  String get stkWeatherNetwork;

  /// No description provided for @stkLook.
  ///
  /// In ko, this message translates to:
  /// **'모양'**
  String get stkLook;

  /// No description provided for @stkLookWhite.
  ///
  /// In ko, this message translates to:
  /// **'흰색'**
  String get stkLookWhite;

  /// No description provided for @stkLookDark.
  ///
  /// In ko, this message translates to:
  /// **'어둡게'**
  String get stkLookDark;

  /// No description provided for @stkLookClear.
  ///
  /// In ko, this message translates to:
  /// **'투명'**
  String get stkLookClear;

  /// No description provided for @stkLookColor.
  ///
  /// In ko, this message translates to:
  /// **'내 색'**
  String get stkLookColor;

  /// No description provided for @stkSearchCity.
  ///
  /// In ko, this message translates to:
  /// **'도시 검색'**
  String get stkSearchCity;

  /// No description provided for @stkNearby.
  ///
  /// In ko, this message translates to:
  /// **'가까운 도시'**
  String get stkNearby;

  /// No description provided for @stkCities.
  ///
  /// In ko, this message translates to:
  /// **'도시'**
  String get stkCities;

  /// No description provided for @stkPlaceTitle.
  ///
  /// In ko, this message translates to:
  /// **'위치 스티커'**
  String get stkPlaceTitle;

  /// No description provided for @stkPlaceName.
  ///
  /// In ko, this message translates to:
  /// **'장소 이름 (예: 성수동 카페거리)'**
  String get stkPlaceName;

  /// No description provided for @stkPlaceMap.
  ///
  /// In ko, this message translates to:
  /// **'친구가 지도에서 열 수 있게'**
  String get stkPlaceMap;

  /// No description provided for @stkPlaceExact.
  ///
  /// In ko, this message translates to:
  /// **'정확한 위치'**
  String get stkPlaceExact;

  /// No description provided for @stkPlaceRough.
  ///
  /// In ko, this message translates to:
  /// **'대략 (약 1km)'**
  String get stkPlaceRough;

  /// No description provided for @stkPlaceFinding.
  ///
  /// In ko, this message translates to:
  /// **'위치를 찾는 중이에요'**
  String get stkPlaceFinding;

  /// No description provided for @stkPlaceNoLocation.
  ///
  /// In ko, this message translates to:
  /// **'위치를 쓸 수 없어서 이름만 붙여요'**
  String get stkPlaceNoLocation;

  /// No description provided for @stkPlaceInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름과 위치는 스토리 안에 암호화되어 친구에게만 가요. 지도를 켜지 않으면 이름만 보여요.'**
  String get stkPlaceInfo;

  /// No description provided for @stkLinkTitle.
  ///
  /// In ko, this message translates to:
  /// **'링크 스티커'**
  String get stkLinkTitle;

  /// No description provided for @stkLinkUrl.
  ///
  /// In ko, this message translates to:
  /// **'주소 (https://…)'**
  String get stkLinkUrl;

  /// No description provided for @stkLinkName.
  ///
  /// In ko, this message translates to:
  /// **'보일 이름 (선택)'**
  String get stkLinkName;

  /// No description provided for @stkLinkSmall.
  ///
  /// In ko, this message translates to:
  /// **'작게'**
  String get stkLinkSmall;

  /// No description provided for @stkLinkCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get stkLinkCard;

  /// No description provided for @stkLinkInfo.
  ///
  /// In ko, this message translates to:
  /// **'미리보기는 내 폰이 만들어 스토리 안에 암호화해 넣어요. 친구들은 스토리를 볼 때 이 사이트에 접속하지 않아요.'**
  String get stkLinkInfo;

  /// No description provided for @stkLinkBad.
  ///
  /// In ko, this message translates to:
  /// **'웹 주소를 넣어 주세요'**
  String get stkLinkBad;

  /// No description provided for @stkLinkReading.
  ///
  /// In ko, this message translates to:
  /// **'미리보기를 만드는 중이에요'**
  String get stkLinkReading;

  /// No description provided for @stkLinkPreviewOff.
  ///
  /// In ko, this message translates to:
  /// **'링크 미리보기가 꺼져 있어서 작게만 보여요'**
  String get stkLinkPreviewOff;

  /// No description provided for @stkLinkOpen.
  ///
  /// In ko, this message translates to:
  /// **'열기'**
  String get stkLinkOpen;

  /// No description provided for @stkLinkGoesTo.
  ///
  /// In ko, this message translates to:
  /// **'이 링크가 가는 곳'**
  String get stkLinkGoesTo;

  /// No description provided for @stkLinkLookalike.
  ///
  /// In ko, this message translates to:
  /// **'보이는 이름과 실제 주소가 달라요. 주소를 꼭 확인하세요'**
  String get stkLinkLookalike;

  /// No description provided for @stkMapOpen.
  ///
  /// In ko, this message translates to:
  /// **'지도에서 보기'**
  String get stkMapOpen;

  /// No description provided for @stkPlaceOnlyName.
  ///
  /// In ko, this message translates to:
  /// **'지도 위치 없이 이름만 붙였어요'**
  String get stkPlaceOnlyName;

  /// No description provided for @roomPhotoNote.
  ///
  /// In ko, this message translates to:
  /// **'사진은 방 안에서 암호화돼서 보내져요. 공개 링크가 있는 방만 링크 미리보기에도 이 사진이 보여요.'**
  String get roomPhotoNote;

  /// No description provided for @roomPhotoLine.
  ///
  /// In ko, this message translates to:
  /// **'{who}님이 {kind, select, channel{채널} other{그룹}} 사진을 {done, select, removed{지웠어요} other{바꿨어요}}'**
  String roomPhotoLine(String who, String kind, String done);

  /// No description provided for @roomPhotoLineMine.
  ///
  /// In ko, this message translates to:
  /// **'{kind, select, channel{채널} other{그룹}} 사진을 {done, select, removed{지웠어요} other{바꿨어요}}'**
  String roomPhotoLineMine(String kind, String done);

  /// No description provided for @roomPhotoPreview.
  ///
  /// In ko, this message translates to:
  /// **'사진을 바꿨어요'**
  String get roomPhotoPreview;

  /// No description provided for @meetupEndToggle.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 시간'**
  String get meetupEndToggle;

  /// No description provided for @meetupStarts.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get meetupStarts;

  /// No description provided for @meetupEnds.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get meetupEnds;

  /// No description provided for @meetupBring.
  ///
  /// In ko, this message translates to:
  /// **'같이 오는 사람'**
  String get meetupBring;

  /// No description provided for @meetupWithGuests.
  ///
  /// In ko, this message translates to:
  /// **'{name} +{n}'**
  String meetupWithGuests(String name, int n);

  /// No description provided for @meetupAddCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더에 추가'**
  String get meetupAddCalendar;

  /// No description provided for @meetupCalendarFile.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 파일을 받았어요. 열면 캘린더에 들어가요'**
  String get meetupCalendarFile;

  /// No description provided for @meetupRemind.
  ///
  /// In ko, this message translates to:
  /// **'1시간 전에 알림'**
  String get meetupRemind;

  /// No description provided for @meetupRemindInfo.
  ///
  /// In ko, this message translates to:
  /// **'\'갈게요\'나 \'아마도\'로 답한 일정은 시작 1시간 전에 이 폰이 알려 줘요. 서버는 몰라요.'**
  String get meetupRemindInfo;

  /// No description provided for @myPlans.
  ///
  /// In ko, this message translates to:
  /// **'내 일정'**
  String get myPlans;

  /// No description provided for @myPlansEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 일정이 없어요. 대화에서 + > 일정으로 만들거나, 받은 일정에 \'갈게요\'를 누르면 여기에 모여요.'**
  String get myPlansEmpty;

  /// No description provided for @myPlansPast.
  ///
  /// In ko, this message translates to:
  /// **'지난 일정'**
  String get myPlansPast;

  /// No description provided for @myPlansSoon.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 일정'**
  String get myPlansSoon;

  /// No description provided for @meetupReminderTitle.
  ///
  /// In ko, this message translates to:
  /// **'1시간 뒤: {title}'**
  String meetupReminderTitle(String title);

  /// No description provided for @myPlansMade.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 일정'**
  String get myPlansMade;

  /// No description provided for @myPlansGoing.
  ///
  /// In ko, this message translates to:
  /// **'갈게요'**
  String get myPlansGoing;

  /// No description provided for @earlierVoice.
  ///
  /// In ko, this message translates to:
  /// **'음성 메시지'**
  String get earlierVoice;

  /// No description provided for @earlierFileFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열 수 없어요. 보낸 사람이 지웠을 수 있어요.'**
  String get earlierFileFailed;

  /// No description provided for @callIgnore.
  ///
  /// In ko, this message translates to:
  /// **'무시'**
  String get callIgnore;

  /// No description provided for @callUnknown.
  ///
  /// In ko, this message translates to:
  /// **'연락처에 없는 사람이에요'**
  String get callUnknown;

  /// No description provided for @callCommonGroups.
  ///
  /// In ko, this message translates to:
  /// **'같은 그룹 {n}개'**
  String callCommonGroups(int n);

  /// No description provided for @callNoCommon.
  ///
  /// In ko, this message translates to:
  /// **'같은 그룹 없음'**
  String get callNoCommon;

  /// No description provided for @callLock.
  ///
  /// In ko, this message translates to:
  /// **'화면 잠금'**
  String get callLock;

  /// No description provided for @callLocked.
  ///
  /// In ko, this message translates to:
  /// **'화면 잠김 · 길게 눌러 풀기'**
  String get callLocked;

  /// No description provided for @filterMentions.
  ///
  /// In ko, this message translates to:
  /// **'멘션'**
  String get filterMentions;

  /// No description provided for @mentionNone.
  ///
  /// In ko, this message translates to:
  /// **'나를 부른 대화가 없어요'**
  String get mentionNone;

  /// No description provided for @newGroupFromMembers.
  ///
  /// In ko, this message translates to:
  /// **'이 멤버로 새 그룹 만들기'**
  String get newGroupFromMembers;

  /// No description provided for @reportPerson.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportPerson;

  /// No description provided for @reportPersonNote.
  ///
  /// In ko, this message translates to:
  /// **'이 사람이 보낸 최근 메시지 {n}개까지 운영팀에 함께 보내요'**
  String reportPersonNote(int n);

  /// No description provided for @reportPersonEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 사람이 보낸 메시지가 없어 신고할 내용이 없어요'**
  String get reportPersonEmpty;

  /// No description provided for @storageByChat.
  ///
  /// In ko, this message translates to:
  /// **'대화별 저장 공간'**
  String get storageByChat;

  /// No description provided for @storageByChatInfo.
  ///
  /// In ko, this message translates to:
  /// **'내려받은 사진·영상·파일이 이 폰에 차지하는 크기예요. 지워도 메시지는 그대로고, 누르면 다시 받아요.'**
  String get storageByChatInfo;

  /// No description provided for @storageGoneChat.
  ///
  /// In ko, this message translates to:
  /// **'나간 대화'**
  String get storageGoneChat;

  /// No description provided for @storageFiles.
  ///
  /// In ko, this message translates to:
  /// **'파일 {n}개'**
  String storageFiles(int n);

  /// No description provided for @storageChatTotal.
  ///
  /// In ko, this message translates to:
  /// **'이 대화가 차지하는 크기'**
  String get storageChatTotal;

  /// No description provided for @storageChatInfo.
  ///
  /// In ko, this message translates to:
  /// **'지워도 메시지는 남아요. 대화에서 다시 누르면 내려받아요.'**
  String get storageChatInfo;

  /// No description provided for @storageClearChat.
  ///
  /// In ko, this message translates to:
  /// **'이 대화 파일 모두 지우기'**
  String get storageClearChat;

  /// No description provided for @storageClearPicked.
  ///
  /// In ko, this message translates to:
  /// **'고른 파일 {n}개 지우기'**
  String storageClearPicked(int n);

  /// No description provided for @storageChatFiles.
  ///
  /// In ko, this message translates to:
  /// **'큰 파일부터'**
  String get storageChatFiles;

  /// No description provided for @storageChatEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 폰에 받아 둔 파일이 없어요'**
  String get storageChatEmpty;

  /// No description provided for @storageNoName.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 파일'**
  String get storageNoName;

  /// No description provided for @storageGoing.
  ///
  /// In ko, this message translates to:
  /// **'파일 {count}개 {n}초 뒤 지워요'**
  String storageGoing(int count, int n);

  /// No description provided for @videoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'동영상 편집'**
  String get videoEditTitle;

  /// No description provided for @videoRotate.
  ///
  /// In ko, this message translates to:
  /// **'회전'**
  String get videoRotate;

  /// No description provided for @videoFlip.
  ///
  /// In ko, this message translates to:
  /// **'뒤집기'**
  String get videoFlip;

  /// No description provided for @videoSound.
  ///
  /// In ko, this message translates to:
  /// **'소리'**
  String get videoSound;

  /// No description provided for @videoEditFailed.
  ///
  /// In ko, this message translates to:
  /// **'영상을 편집하지 못해서 보내지 않았어요'**
  String get videoEditFailed;

  /// No description provided for @videoEditing.
  ///
  /// In ko, this message translates to:
  /// **'영상을 만드는 중이에요'**
  String get videoEditing;

  /// No description provided for @photoHdOn.
  ///
  /// In ko, this message translates to:
  /// **'HD 화질로 보내요'**
  String get photoHdOn;

  /// No description provided for @photoHdOff.
  ///
  /// In ko, this message translates to:
  /// **'표준 화질로 보내요. 데이터를 아껴요'**
  String get photoHdOff;

  /// No description provided for @sendHd.
  ///
  /// In ko, this message translates to:
  /// **'HD 화질로 보내기'**
  String get sendHd;

  /// No description provided for @photoHdSetting.
  ///
  /// In ko, this message translates to:
  /// **'사진을 HD로 보내기'**
  String get photoHdSetting;

  /// No description provided for @photoHdSettingSub.
  ///
  /// In ko, this message translates to:
  /// **'끄면 표준 화질로 보내서 데이터와 저장 공간을 아껴요'**
  String get photoHdSettingSub;

  /// No description provided for @albumPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get albumPreview;

  /// No description provided for @albumPreviewHint.
  ///
  /// In ko, this message translates to:
  /// **'꾹 눌러 끌면 순서가 바뀌어요'**
  String get albumPreviewHint;

  /// No description provided for @pickEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get pickEdit;

  /// No description provided for @pickTrim.
  ///
  /// In ko, this message translates to:
  /// **'자르기·회전'**
  String get pickTrim;

  /// No description provided for @pickSpoilerOn.
  ///
  /// In ko, this message translates to:
  /// **'가리기'**
  String get pickSpoilerOn;

  /// No description provided for @pickSpoilerOff.
  ///
  /// In ko, this message translates to:
  /// **'가리기 풀기'**
  String get pickSpoilerOff;

  /// No description provided for @pickRemove.
  ///
  /// In ko, this message translates to:
  /// **'빼기'**
  String get pickRemove;

  /// No description provided for @spoilerCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 가림'**
  String spoilerCount(int count);

  /// No description provided for @aiAgeTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 기능은 만 18세 이상만 쓸 수 있어요'**
  String get aiAgeTitle;

  /// No description provided for @aiAgeInfo.
  ///
  /// In ko, this message translates to:
  /// **'안드로이드의 휴대폰 속 AI(Google)는 약관에 따라 만 18세 이상만 쓸 수 있어요. 한 번만 물어보고, 설정 › 대화 › AI 기능에서 바꿀 수 있어요.'**
  String get aiAgeInfo;

  /// No description provided for @aiAgeAdult.
  ///
  /// In ko, this message translates to:
  /// **'만 18세 이상이에요'**
  String get aiAgeAdult;

  /// No description provided for @aiAgeMinor.
  ///
  /// In ko, this message translates to:
  /// **'18세 미만이에요'**
  String get aiAgeMinor;

  /// No description provided for @aiAgeOnly.
  ///
  /// In ko, this message translates to:
  /// **'18세 이상만 쓸 수 있어요'**
  String get aiAgeOnly;

  /// No description provided for @aiAgeRow.
  ///
  /// In ko, this message translates to:
  /// **'AI 나이 확인'**
  String get aiAgeRow;

  /// No description provided for @aiAgeRowSub.
  ///
  /// In ko, this message translates to:
  /// **'AI 편집기·요약·배경 지우기 (안드로이드)'**
  String get aiAgeRowSub;

  /// No description provided for @aiAgeValueAdult.
  ///
  /// In ko, this message translates to:
  /// **'만 18세 이상'**
  String get aiAgeValueAdult;

  /// No description provided for @aiAgeValueMinor.
  ///
  /// In ko, this message translates to:
  /// **'18세 미만'**
  String get aiAgeValueMinor;

  /// No description provided for @aiAgeValueUnknown.
  ///
  /// In ko, this message translates to:
  /// **'확인 전'**
  String get aiAgeValueUnknown;

  /// No description provided for @trPoweredByGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Powered by Google Translate'**
  String get trPoweredByGoogle;

  /// No description provided for @stkWeatherCredit.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보: MET Norway 자료 기반 (CC BY 4.0)'**
  String get stkWeatherCredit;

  /// No description provided for @creditsHeader.
  ///
  /// In ko, this message translates to:
  /// **'출처'**
  String get creditsHeader;

  /// No description provided for @creditsFooter.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 자세한 내용과 원문 라이선스를 볼 수 있어요.'**
  String get creditsFooter;

  /// No description provided for @creditWeather.
  ///
  /// In ko, this message translates to:
  /// **'날씨 정보'**
  String get creditWeather;

  /// No description provided for @creditWeatherSub.
  ///
  /// In ko, this message translates to:
  /// **'MET Norway · CC BY 4.0'**
  String get creditWeatherSub;

  /// No description provided for @creditWeatherInfo.
  ///
  /// In ko, this message translates to:
  /// **'스토리 날씨 스티커의 날씨는 노르웨이 기상청(MET Norway) 자료를 바탕으로 해요. 우리 서버가 위치를 약 10 km 단위로 흐리게 해서 묻고, 앱이 기온과 날씨 그림으로 바꿔 보여 줘요.'**
  String get creditWeatherInfo;

  /// No description provided for @creditGoogle.
  ///
  /// In ko, this message translates to:
  /// **'번역·AI (안드로이드)'**
  String get creditGoogle;

  /// No description provided for @creditGoogleSub.
  ///
  /// In ko, this message translates to:
  /// **'Google ML Kit'**
  String get creditGoogleSub;

  /// No description provided for @creditGoogleInfo.
  ///
  /// In ko, this message translates to:
  /// **'안드로이드에서는 번역, 문서 스캔, 배경 지우기, AI 편집기를 Google ML Kit이 휴대폰 안에서 처리해요. 내용은 회사로 보내지 않아요. 번역 결과 아래에는 Google 표시가 붙어요. 아이폰은 애플 기본 기능을 써요.'**
  String get creditGoogleInfo;

  /// No description provided for @creditFont.
  ///
  /// In ko, this message translates to:
  /// **'글꼴'**
  String get creditFont;

  /// No description provided for @creditFontSub.
  ///
  /// In ko, this message translates to:
  /// **'Pretendard · SIL OFL 1.1'**
  String get creditFontSub;

  /// No description provided for @creditFontInfo.
  ///
  /// In ko, this message translates to:
  /// **'앱 글꼴은 Pretendard예요. 누구나 무료로 쓸 수 있는 SIL 오픈 폰트 라이선스라서 원문을 함께 실어요.'**
  String get creditFontInfo;

  /// No description provided for @creditPdq.
  ///
  /// In ko, this message translates to:
  /// **'사진 지문'**
  String get creditPdq;

  /// No description provided for @creditPdqSub.
  ///
  /// In ko, this message translates to:
  /// **'PDQ (Meta) · 안전 서버'**
  String get creditPdqSub;

  /// No description provided for @creditPdqInfo.
  ///
  /// In ko, this message translates to:
  /// **'알려진 불법 사진을 찾을 때 Meta가 공개한 PDQ 사진 지문 방식을 우리 안전 서버에서 써요. 비공개 대화의 사진은 검사하지 않아요.'**
  String get creditPdqInfo;

  /// No description provided for @partsHeader.
  ///
  /// In ko, this message translates to:
  /// **'앱 부품 {count}개'**
  String partsHeader(int count);

  /// No description provided for @importTitle.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 대화 가져오기'**
  String get importTitle;

  /// No description provided for @importHeader.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡 · 왓츠앱 · 텔레그램에서 내보낸 대화를 원래 날짜 그대로 부루미 대화방에 넣어요.'**
  String get importHeader;

  /// No description provided for @importAppKakao.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡'**
  String get importAppKakao;

  /// No description provided for @importAppWhatsapp.
  ///
  /// In ko, this message translates to:
  /// **'왓츠앱'**
  String get importAppWhatsapp;

  /// No description provided for @importAppTelegram.
  ///
  /// In ko, this message translates to:
  /// **'텔레그램'**
  String get importAppTelegram;

  /// No description provided for @importDeviceIphone.
  ///
  /// In ko, this message translates to:
  /// **'아이폰'**
  String get importDeviceIphone;

  /// No description provided for @importDeviceAndroid.
  ///
  /// In ko, this message translates to:
  /// **'안드로이드'**
  String get importDeviceAndroid;

  /// No description provided for @importDevicePc.
  ///
  /// In ko, this message translates to:
  /// **'PC'**
  String get importDevicePc;

  /// No description provided for @importHowTo.
  ///
  /// In ko, this message translates to:
  /// **'{app}에서 내보내는 방법'**
  String importHowTo(String app);

  /// No description provided for @importStepsKakaoPhone.
  ///
  /// In ko, this message translates to:
  /// **'가져올 대화방을 열고 오른쪽 위 ☰ 메뉴를 눌러요\n메뉴 아래쪽 ⚙ 설정에서 \'대화 내용 내보내기\'를 눌러요\n사진까지 가져오려면 \'모든 메시지 내부 저장소에 저장\', 글만 가져오려면 \'텍스트 메시지만 보내기\'를 골라요\n저장된 파일(.zip 또는 .txt)을 아래 \'내보낸 파일 고르기\'로 골라요'**
  String get importStepsKakaoPhone;

  /// No description provided for @importStepsKakaoPc.
  ///
  /// In ko, this message translates to:
  /// **'PC 카카오톡에서 대화방을 열고 오른쪽 위 ☰ 메뉴를 눌러요\n\'대화 내보내기\'를 눌러 .txt 파일로 저장해요\n그 파일을 휴대폰으로 옮기거나 PC용 부루미에서 바로 골라요'**
  String get importStepsKakaoPc;

  /// No description provided for @importStepsWhatsappIphone.
  ///
  /// In ko, this message translates to:
  /// **'가져올 대화방을 열고 맨 위 상대 이름(또는 그룹 이름)을 눌러요\n아래로 내려 \'대화 내보내기\'를 눌러요\n사진까지 가져오려면 \'미디어 첨부\'를 골라요\n\'파일에 저장\'으로 저장한 뒤, 아래 \'내보낸 파일 고르기\'로 골라요'**
  String get importStepsWhatsappIphone;

  /// No description provided for @importStepsWhatsappAndroid.
  ///
  /// In ko, this message translates to:
  /// **'가져올 대화방을 열고 오른쪽 위 ⋮ 를 눌러요\n\'더보기\' → \'대화 내보내기\'를 눌러요\n사진까지 가져오려면 \'미디어 포함\'을 골라요\n파일로 저장한 뒤, 아래 \'내보낸 파일 고르기\'로 골라요'**
  String get importStepsWhatsappAndroid;

  /// No description provided for @importStepsTelegram.
  ///
  /// In ko, this message translates to:
  /// **'컴퓨터용 텔레그램(Telegram Desktop)에서 대화방을 열고 오른쪽 위 ⋮ 를 눌러요\n\'대화 기록 내보내기\'를 눌러요\n사진까지 가져오려면 사진 · 파일을 켜고, 형식은 \'JSON\'(또는 HTML)을 골라요\n다 되면 내보낸 폴더를 통째로 압축(.zip)해서, 아래 \'내보낸 파일 고르기\'로 골라요'**
  String get importStepsTelegram;

  /// No description provided for @importTelegramPhoneNote.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 텔레그램 앱에는 대화 내보내기가 없어서 컴퓨터용 텔레그램을 써야 해요.'**
  String get importTelegramPhoneNote;

  /// No description provided for @importKakaoMediaNote.
  ///
  /// In ko, this message translates to:
  /// **'글만 내보낸 파일이면 사진 자리에 \'사진\'이라고만 표시돼요.'**
  String get importKakaoMediaNote;

  /// No description provided for @importWhatsappMediaNote.
  ///
  /// In ko, this message translates to:
  /// **'\'미디어 없이\'로 내보내면 사진 자리에 \'사진\'이라고만 표시돼요.'**
  String get importWhatsappMediaNote;

  /// No description provided for @importPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'파일은 이 휴대폰 안에서만 읽어요. 보낼 때는 이 휴대폰에서 암호화해서 보내니, 서버는 내용도 누가 썼는지도 볼 수 없어요.'**
  String get importPrivacy;

  /// No description provided for @importPick.
  ///
  /// In ko, this message translates to:
  /// **'내보낸 파일 고르기'**
  String get importPick;

  /// No description provided for @importSample.
  ///
  /// In ko, this message translates to:
  /// **'예시 파일로 해 보기'**
  String get importSample;

  /// No description provided for @importReading.
  ///
  /// In ko, this message translates to:
  /// **'대화를 읽고 있어요'**
  String get importReading;

  /// No description provided for @importPickFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 고를 수 없어요. 다시 해 주세요.'**
  String get importPickFailed;

  /// No description provided for @importErrBig.
  ///
  /// In ko, this message translates to:
  /// **'파일이 너무 커요. 사진 없이 내보내거나 기간을 나눠서 해 주세요.'**
  String get importErrBig;

  /// No description provided for @importErrEmpty.
  ///
  /// In ko, this message translates to:
  /// **'파일에 메시지가 없어요.'**
  String get importErrEmpty;

  /// No description provided for @importErrBroken.
  ///
  /// In ko, this message translates to:
  /// **'파일이 깨져서 열 수 없어요. 다시 내보내 주세요.'**
  String get importErrBroken;

  /// No description provided for @importErrUnknown.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡 · 왓츠앱 · 텔레그램에서 내보낸 대화 파일이 아니에요.'**
  String get importErrUnknown;

  /// No description provided for @importPickChat.
  ///
  /// In ko, this message translates to:
  /// **'가져올 대화 고르기'**
  String get importPickChat;

  /// No description provided for @importNoTitle.
  ///
  /// In ko, this message translates to:
  /// **'이름 없는 대화'**
  String get importNoTitle;

  /// No description provided for @importCount.
  ///
  /// In ko, this message translates to:
  /// **'메시지 {count}개'**
  String importCount(int count);

  /// No description provided for @importCheckTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져올 대화 확인'**
  String get importCheckTitle;

  /// No description provided for @importWhoIsMe.
  ///
  /// In ko, this message translates to:
  /// **'이 중에 나는 누구인가요?'**
  String get importWhoIsMe;

  /// No description provided for @importWhoIsMeInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 이름의 메시지는 내 말풍선(오른쪽)으로 보여요. 다른 사람은 원래 앱의 이름으로 보여요.'**
  String get importWhoIsMeInfo;

  /// No description provided for @importPeerInfo.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 메시지는 이 대화의 {peer} 님 말풍선으로 보여요.'**
  String importPeerInfo(String name, String peer);

  /// No description provided for @importWhere.
  ///
  /// In ko, this message translates to:
  /// **'어디에 넣을까요?'**
  String get importWhere;

  /// No description provided for @importPickRoom.
  ///
  /// In ko, this message translates to:
  /// **'넣을 대화방 고르기'**
  String get importPickRoom;

  /// No description provided for @importPickRoomInfo.
  ///
  /// In ko, this message translates to:
  /// **'가져온 메시지는 이 대화방의 모든 사람이 볼 수 있어요.'**
  String get importPickRoomInfo;

  /// No description provided for @importKindDirect.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화'**
  String get importKindDirect;

  /// No description provided for @importKindGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get importKindGroup;

  /// No description provided for @importKindChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널'**
  String get importKindChannel;

  /// No description provided for @importMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진 · 동영상 · 파일'**
  String get importMedia;

  /// No description provided for @importMediaSize.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 · {size}'**
  String importMediaSize(int count, String size);

  /// No description provided for @importNoMedia.
  ///
  /// In ko, this message translates to:
  /// **'이 파일에는 사진이 들어 있지 않아요'**
  String get importNoMedia;

  /// No description provided for @importMissingInfo.
  ///
  /// In ko, this message translates to:
  /// **'사진 · 파일 {count}개는 내보낸 파일에 없어서 자리만 표시돼요. 사진까지 가져오려면 원래 앱에서 사진을 포함해 다시 내보내 주세요.'**
  String importMissingInfo(int count);

  /// No description provided for @importStart.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get importStart;

  /// No description provided for @importConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'{room} 대화방에 메시지 {count}개를 넣을까요?'**
  String importConfirmTitle(String room, int count);

  /// No description provided for @importConfirmInfo.
  ///
  /// In ko, this message translates to:
  /// **'원래 날짜와 시간 순서대로 들어가고, 말풍선마다 \'가져옴\' 표시가 붙어요.'**
  String get importConfirmInfo;

  /// No description provided for @importStepMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진과 파일을 암호화해서 올리고 있어요 ({done}/{total})'**
  String importStepMedia(int done, int total);

  /// No description provided for @importStepPack.
  ///
  /// In ko, this message translates to:
  /// **'메시지를 암호화해서 묶고 있어요'**
  String get importStepPack;

  /// No description provided for @importStepSend.
  ///
  /// In ko, this message translates to:
  /// **'거의 다 됐어요'**
  String get importStepSend;

  /// No description provided for @importKeepOpen.
  ///
  /// In ko, this message translates to:
  /// **'다 될 때까지 이 화면을 열어 두세요.'**
  String get importKeepOpen;

  /// No description provided for @importDone.
  ///
  /// In ko, this message translates to:
  /// **'메시지 {count}개를 가져왔어요!'**
  String importDone(int count);

  /// No description provided for @importFailed.
  ///
  /// In ko, this message translates to:
  /// **'가져오지 못했어요. 인터넷 연결을 확인하고 다시 해 주세요.'**
  String get importFailed;

  /// No description provided for @importRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 하기'**
  String get importRetry;

  /// No description provided for @importStop.
  ///
  /// In ko, this message translates to:
  /// **'그만두기'**
  String get importStop;

  /// No description provided for @importSeeChat.
  ///
  /// In ko, this message translates to:
  /// **'대화 보기'**
  String get importSeeChat;

  /// No description provided for @importLineMine.
  ///
  /// In ko, this message translates to:
  /// **'{app}에서 대화를 가져왔어요 · 메시지 {count}개'**
  String importLineMine(String app, int count);

  /// No description provided for @importLine.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 {app}에서 대화를 가져왔어요 · 메시지 {count}개'**
  String importLine(String name, String app, int count);

  /// No description provided for @importInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져온 대화'**
  String get importInfoTitle;

  /// No description provided for @importInfoCount.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get importInfoCount;

  /// No description provided for @importInfoDates.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get importInfoDates;

  /// No description provided for @importInfoBy.
  ///
  /// In ko, this message translates to:
  /// **'가져온 사람'**
  String get importInfoBy;

  /// No description provided for @importInfoByMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get importInfoByMe;

  /// No description provided for @importInfoNote.
  ///
  /// In ko, this message translates to:
  /// **'가져온 메시지는 다른 앱에서 내보낸 파일 그대로예요. 부루미가 보낸 사람을 확인한 메시지가 아니라서 \'가져옴\' 표시가 붙어요.'**
  String get importInfoNote;

  /// No description provided for @importDelete.
  ///
  /// In ko, this message translates to:
  /// **'가져온 대화 지우기'**
  String get importDelete;

  /// No description provided for @importedMark.
  ///
  /// In ko, this message translates to:
  /// **'가져옴'**
  String get importedMark;

  /// No description provided for @importSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get importSticker;

  /// No description provided for @importNotIncluded.
  ///
  /// In ko, this message translates to:
  /// **'{kind} · 내보낸 파일에 없음'**
  String importNotIncluded(String kind);

  /// No description provided for @importSysCreate.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 대화방을 만들었어요'**
  String importSysCreate(String name);

  /// No description provided for @importSysJoin.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 들어왔어요'**
  String importSysJoin(String name);

  /// No description provided for @importSysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 내보냈어요'**
  String importSysLeft(String name);

  /// No description provided for @importSysPin.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 메시지를 고정했어요'**
  String importSysPin(String name);

  /// No description provided for @importSysCall.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 통화'**
  String importSysCall(String name);

  /// No description provided for @importSysTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 이름을 바꿨어요: {title}'**
  String importSysTitle(String name, String title);

  /// No description provided for @importSysPhoto.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님이 사진을 바꿨어요'**
  String importSysPhoto(String name);

  /// No description provided for @importSysOther.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님의 알림'**
  String importSysOther(String name);

  /// No description provided for @importRow.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱 대화 가져오기'**
  String get importRow;

  /// No description provided for @importRowSub.
  ///
  /// In ko, this message translates to:
  /// **'카카오톡 · 왓츠앱 · 텔레그램'**
  String get importRowSub;

  /// No description provided for @importMenu.
  ///
  /// In ko, this message translates to:
  /// **'대화 가져오기'**
  String get importMenu;

  /// No description provided for @importDeleted.
  ///
  /// In ko, this message translates to:
  /// **'삭제된 메시지'**
  String get importDeleted;

  /// No description provided for @importAlready.
  ///
  /// In ko, this message translates to:
  /// **'이 대화방에 같은 대화를 이미 가져왔어요. 또 가져오면 메시지가 두 번씩 보여요.'**
  String get importAlready;

  /// No description provided for @invJoined.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 참여'**
  String invJoined(int count);

  /// No description provided for @invPeopleLeft.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 남음'**
  String invPeopleLeft(int count);

  /// No description provided for @invDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'{count}일 남음'**
  String invDaysLeft(int count);

  /// No description provided for @invHoursLeft.
  ///
  /// In ko, this message translates to:
  /// **'{count}시간 남음'**
  String invHoursLeft(int count);

  /// No description provided for @invMinutesLeft.
  ///
  /// In ko, this message translates to:
  /// **'{count}분 남음'**
  String invMinutesLeft(int count);

  /// No description provided for @invEnded.
  ///
  /// In ko, this message translates to:
  /// **'기간 끝남'**
  String get invEnded;

  /// No description provided for @invFull.
  ///
  /// In ko, this message translates to:
  /// **'인원 마감'**
  String get invFull;

  /// No description provided for @invRevoked.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get invRevoked;

  /// No description provided for @invMoreHeader.
  ///
  /// In ko, this message translates to:
  /// **'추가 링크'**
  String get invMoreHeader;

  /// No description provided for @invMoreInfo.
  ///
  /// In ko, this message translates to:
  /// **'인스타 프로필용, 친구용처럼 링크를 여러 개 만들 수 있어요. 기간이 끝나거나 인원이 차면 서버가 바로 막아서, 내 폰이 꺼져 있어도 지켜져요.'**
  String get invMoreInfo;

  /// No description provided for @invNew.
  ///
  /// In ko, this message translates to:
  /// **'새 링크 만들기'**
  String get invNew;

  /// No description provided for @invRevokedHeader.
  ///
  /// In ko, this message translates to:
  /// **'취소된 링크'**
  String get invRevokedHeader;

  /// No description provided for @invDeleteAllRevoked.
  ///
  /// In ko, this message translates to:
  /// **'취소된 링크 모두 지우기'**
  String get invDeleteAllRevoked;

  /// No description provided for @invDeleteAllIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 취소된 링크를 지워요'**
  String invDeleteAllIn(int seconds);

  /// No description provided for @invNewTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 링크'**
  String get invNewTitle;

  /// No description provided for @invEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'링크 수정'**
  String get invEditTitle;

  /// No description provided for @invMake.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get invMake;

  /// No description provided for @invNameHint.
  ///
  /// In ko, this message translates to:
  /// **'링크 이름 (예: 인스타 프로필)'**
  String get invNameHint;

  /// No description provided for @invNameInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름은 관리자만 봐요. 받는 사람에게는 보이지 않아요.'**
  String get invNameInfo;

  /// No description provided for @invTime.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get invTime;

  /// No description provided for @inv1h.
  ///
  /// In ko, this message translates to:
  /// **'1시간'**
  String get inv1h;

  /// No description provided for @inv1d.
  ///
  /// In ko, this message translates to:
  /// **'1일'**
  String get inv1d;

  /// No description provided for @inv1w.
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get inv1w;

  /// No description provided for @invNoLimit.
  ///
  /// In ko, this message translates to:
  /// **'제한 없음'**
  String get invNoLimit;

  /// No description provided for @invPick.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get invPick;

  /// No description provided for @invTimeNone.
  ///
  /// In ko, this message translates to:
  /// **'끝나는 날 없이 계속 열려 있어요'**
  String get invTimeNone;

  /// No description provided for @invTimeEnds.
  ///
  /// In ko, this message translates to:
  /// **'{time}에 끝나요'**
  String invTimeEnds(String time);

  /// No description provided for @invPeople.
  ///
  /// In ko, this message translates to:
  /// **'인원'**
  String get invPeople;

  /// No description provided for @invPeopleCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String invPeopleCount(int count);

  /// No description provided for @invPeopleHint.
  ///
  /// In ko, this message translates to:
  /// **'몇 명까지 들어올 수 있는지 숫자로 적어 주세요'**
  String get invPeopleHint;

  /// No description provided for @invPeopleN.
  ///
  /// In ko, this message translates to:
  /// **'{count}명이 들어오면 링크가 닫혀요'**
  String invPeopleN(int count);

  /// No description provided for @invPeopleNone.
  ///
  /// In ko, this message translates to:
  /// **'몇 명이든 들어올 수 있어요'**
  String get invPeopleNone;

  /// No description provided for @invPeopleApproval.
  ///
  /// In ko, this message translates to:
  /// **'승인 후 참여가 켜져 있어서 관리자가 한 명씩 들여보내요. 그래서 인원 제한 대신 기간만 쓰여요.'**
  String get invPeopleApproval;

  /// No description provided for @invRevokedInfo.
  ///
  /// In ko, this message translates to:
  /// **'취소한 링크라서 더 이상 열리지 않아요.'**
  String get invRevokedInfo;

  /// No description provided for @invFullInfo.
  ///
  /// In ko, this message translates to:
  /// **'정한 인원이 다 들어와서 더 이상 열리지 않아요. 링크 수정에서 인원을 늘릴 수 있어요.'**
  String get invFullInfo;

  /// No description provided for @invEndedInfo.
  ///
  /// In ko, this message translates to:
  /// **'기간이 끝나서 더 이상 열리지 않아요. 링크 수정에서 기간을 늘릴 수 있어요.'**
  String get invEndedInfo;

  /// No description provided for @invJoinedHeader.
  ///
  /// In ko, this message translates to:
  /// **'이 링크로 들어온 사람 {count}명'**
  String invJoinedHeader(int count);

  /// No description provided for @invJoinedMore.
  ///
  /// In ko, this message translates to:
  /// **'최근 100명까지 보여요.'**
  String get invJoinedMore;

  /// No description provided for @invNobody.
  ///
  /// In ko, this message translates to:
  /// **'아직 아무도 안 들어왔어요'**
  String get invNobody;

  /// No description provided for @invLeftRoom.
  ///
  /// In ko, this message translates to:
  /// **'지금은 나간 사람'**
  String get invLeftRoom;

  /// No description provided for @invRevoke.
  ///
  /// In ko, this message translates to:
  /// **'링크 취소'**
  String get invRevoke;

  /// No description provided for @invRevokeIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 링크를 취소해요'**
  String invRevokeIn(int seconds);

  /// No description provided for @invDelete.
  ///
  /// In ko, this message translates to:
  /// **'링크 지우기'**
  String get invDelete;

  /// No description provided for @invDeleteIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 링크를 지워요'**
  String invDeleteIn(int seconds);

  /// No description provided for @joinLinkEnded.
  ///
  /// In ko, this message translates to:
  /// **'이 초대 링크는 기간이 끝났어요'**
  String get joinLinkEnded;

  /// No description provided for @joinLinkFull.
  ///
  /// In ko, this message translates to:
  /// **'이 초대 링크는 인원이 다 찼어요'**
  String get joinLinkFull;

  /// No description provided for @chatLinks.
  ///
  /// In ko, this message translates to:
  /// **'대화 링크'**
  String get chatLinks;

  /// No description provided for @chatLinksAbout.
  ///
  /// In ko, this message translates to:
  /// **'링크를 누른 사람에게 나와의 대화가 열리고, 미리 써 둔 글이 입력창에 들어가 있어요. 가게 문의나 행사 신청 받을 때 좋아요.'**
  String get chatLinksAbout;

  /// No description provided for @chatLinksFooter.
  ///
  /// In ko, this message translates to:
  /// **'링크에는 내 아이디가 들어 있어요. 링크 목록은 이 폰에만 있고, 누가 눌렀는지는 서버도 몰라서 세지 않아요.'**
  String get chatLinksFooter;

  /// No description provided for @chatLinkNew.
  ///
  /// In ko, this message translates to:
  /// **'대화 링크 만들기'**
  String get chatLinkNew;

  /// No description provided for @chatLinkEdit.
  ///
  /// In ko, this message translates to:
  /// **'대화 링크'**
  String get chatLinkEdit;

  /// No description provided for @chatLinkNoText.
  ///
  /// In ko, this message translates to:
  /// **'미리 쓴 글 없음'**
  String get chatLinkNoText;

  /// No description provided for @chatLinkPreview.
  ///
  /// In ko, this message translates to:
  /// **'받는 사람에게 이렇게 보여요'**
  String get chatLinkPreview;

  /// No description provided for @chatLinkText.
  ///
  /// In ko, this message translates to:
  /// **'미리 쓸 글'**
  String get chatLinkText;

  /// No description provided for @chatLinkTextHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 케이크 주문하고 싶어요'**
  String get chatLinkTextHint;

  /// No description provided for @chatLinkTextInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 누른 사람의 입력창에 들어가요. 그 사람이 고치거나 지우고 직접 보내요.'**
  String get chatLinkTextInfo;

  /// No description provided for @chatLinkNameHint.
  ///
  /// In ko, this message translates to:
  /// **'링크 이름 (예: 가게 문의)'**
  String get chatLinkNameHint;

  /// No description provided for @chatLinkNameInfo.
  ///
  /// In ko, this message translates to:
  /// **'이름은 나만 봐요.'**
  String get chatLinkNameInfo;

  /// No description provided for @chatLinkKey.
  ///
  /// In ko, this message translates to:
  /// **'아이디 키 넣기'**
  String get chatLinkKey;

  /// No description provided for @chatLinkKeyInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 처음 보는 사람도 아이디 키 없이 대화를 시작할 수 있어요. 링크가 퍼지면 키도 같이 퍼져요.'**
  String get chatLinkKeyInfo;

  /// No description provided for @chatLinkIdInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 받은 사람은 내 아이디를 볼 수 있어요.'**
  String get chatLinkIdInfo;

  /// No description provided for @chatLinkDelete.
  ///
  /// In ko, this message translates to:
  /// **'링크 지우기'**
  String get chatLinkDelete;

  /// No description provided for @chatLinkDeleteIn.
  ///
  /// In ko, this message translates to:
  /// **'{seconds}초 뒤에 링크를 지워요'**
  String chatLinkDeleteIn(int seconds);

  /// No description provided for @chatLinkWaiting.
  ///
  /// In ko, this message translates to:
  /// **'입력창에 들어갈 글'**
  String get chatLinkWaiting;

  /// No description provided for @chatLinkStart.
  ///
  /// In ko, this message translates to:
  /// **'메시지 보내기'**
  String get chatLinkStart;

  /// No description provided for @qrSeeChannel.
  ///
  /// In ko, this message translates to:
  /// **'채널 보기'**
  String get qrSeeChannel;

  /// No description provided for @qrSeeGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 보기'**
  String get qrSeeGroup;

  /// No description provided for @qrChat.
  ///
  /// In ko, this message translates to:
  /// **'대화하기'**
  String get qrChat;

  /// No description provided for @qrMessage.
  ///
  /// In ko, this message translates to:
  /// **'메시지 링크'**
  String get qrMessage;

  /// No description provided for @qrSee.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get qrSee;

  /// No description provided for @qrPc.
  ///
  /// In ko, this message translates to:
  /// **'PC에서 로그인'**
  String get qrPc;

  /// No description provided for @qrConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결하기'**
  String get qrConnect;

  /// No description provided for @qrExpired.
  ///
  /// In ko, this message translates to:
  /// **'시간이 지난 QR 코드예요'**
  String get qrExpired;

  /// No description provided for @qrOpenLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 열기'**
  String get qrOpenLink;

  /// No description provided for @qrCopyText.
  ///
  /// In ko, this message translates to:
  /// **'글 복사하기'**
  String get qrCopyText;

  /// No description provided for @qrWebTitle.
  ///
  /// In ko, this message translates to:
  /// **'{host} 사이트로 이동할까요?'**
  String qrWebTitle(String host);

  /// No description provided for @qrScan.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드 읽기'**
  String get qrScan;

  /// No description provided for @qrScanHint.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드를 네모 안에 비춰 주세요'**
  String get qrScanHint;

  /// No description provided for @qrNoCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 쓸 수 없어요'**
  String get qrNoCamera;

  /// No description provided for @shareInTitle.
  ///
  /// In ko, this message translates to:
  /// **'부루미로 보내기'**
  String get shareInTitle;

  /// No description provided for @shareInComment.
  ///
  /// In ko, this message translates to:
  /// **'메시지 추가'**
  String get shareInComment;

  /// No description provided for @shareInFrom.
  ///
  /// In ko, this message translates to:
  /// **'보낼 계정'**
  String get shareInFrom;

  /// No description provided for @shareInNoPost.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에는 글을 쓸 수 없어요'**
  String get shareInNoPost;

  /// No description provided for @shareInKind.
  ///
  /// In ko, this message translates to:
  /// **'이 대화는 이 종류를 막아 두었어요'**
  String get shareInKind;

  /// No description provided for @shareInLater.
  ///
  /// In ko, this message translates to:
  /// **'지금은 보낼 수 없는 시간이에요'**
  String get shareInLater;

  /// No description provided for @shareInSlow.
  ///
  /// In ko, this message translates to:
  /// **'조금 뒤에 보낼 수 있어요'**
  String get shareInSlow;

  /// No description provided for @shareInNone.
  ///
  /// In ko, this message translates to:
  /// **'보낼 수 있는 대화가 없어요'**
  String get shareInNone;

  /// No description provided for @shareInSending.
  ///
  /// In ko, this message translates to:
  /// **'보내는 중 {percent}%'**
  String shareInSending(int percent);

  /// No description provided for @shareInSent.
  ///
  /// In ko, this message translates to:
  /// **'{count}곳에 보냈어요'**
  String shareInSent(int count);

  /// No description provided for @shareInFailed.
  ///
  /// In ko, this message translates to:
  /// **'{count}곳에는 못 보냈어요'**
  String shareInFailed(int count);

  /// No description provided for @shareInDemo.
  ///
  /// In ko, this message translates to:
  /// **'다른 앱에서 보내기 체험'**
  String get shareInDemo;

  /// No description provided for @shareInSendN.
  ///
  /// In ko, this message translates to:
  /// **'{count}곳에 보내기'**
  String shareInSendN(int count);

  /// No description provided for @editorSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get editorSticker;

  /// No description provided for @editorAddSticker.
  ///
  /// In ko, this message translates to:
  /// **'스티커·이모지 넣기'**
  String get editorAddSticker;

  /// No description provided for @editorStickerHint.
  ///
  /// In ko, this message translates to:
  /// **'누르면 메뉴, 두 손가락으로 크기·각도, 휴지통으로 끌면 지워져요'**
  String get editorStickerHint;

  /// No description provided for @stkPhotoCut.
  ///
  /// In ko, this message translates to:
  /// **'사진 오려 붙이기'**
  String get stkPhotoCut;

  /// No description provided for @stkFlip.
  ///
  /// In ko, this message translates to:
  /// **'뒤집기'**
  String get stkFlip;

  /// No description provided for @stkCopy.
  ///
  /// In ko, this message translates to:
  /// **'복제'**
  String get stkCopy;

  /// No description provided for @stkCutout.
  ///
  /// In ko, this message translates to:
  /// **'오려내기'**
  String get stkCutout;

  /// No description provided for @cutoutFail.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 배경을 지울 수 없어요'**
  String get cutoutFail;

  /// No description provided for @colorTitle.
  ///
  /// In ko, this message translates to:
  /// **'색'**
  String get colorTitle;

  /// No description provided for @colorGrid.
  ///
  /// In ko, this message translates to:
  /// **'격자'**
  String get colorGrid;

  /// No description provided for @colorSpectrum.
  ///
  /// In ko, this message translates to:
  /// **'스펙트럼'**
  String get colorSpectrum;

  /// No description provided for @colorSliders.
  ///
  /// In ko, this message translates to:
  /// **'슬라이더'**
  String get colorSliders;

  /// No description provided for @colorRed.
  ///
  /// In ko, this message translates to:
  /// **'빨강'**
  String get colorRed;

  /// No description provided for @colorGreen.
  ///
  /// In ko, this message translates to:
  /// **'초록'**
  String get colorGreen;

  /// No description provided for @colorBlue.
  ///
  /// In ko, this message translates to:
  /// **'파랑'**
  String get colorBlue;

  /// No description provided for @mediaChanged.
  ///
  /// In ko, this message translates to:
  /// **'사진 바뀜'**
  String get mediaChanged;

  /// No description provided for @editFirstPhoto.
  ///
  /// In ko, this message translates to:
  /// **'바뀌기 전 사진'**
  String get editFirstPhoto;

  /// No description provided for @captionAboveMenu.
  ///
  /// In ko, this message translates to:
  /// **'설명 위로 올리기'**
  String get captionAboveMenu;

  /// No description provided for @captionUp.
  ///
  /// In ko, this message translates to:
  /// **'설명 위로 올리기'**
  String get captionUp;

  /// No description provided for @captionDown.
  ///
  /// In ko, this message translates to:
  /// **'설명 아래로 내리기'**
  String get captionDown;

  /// No description provided for @editSwapPhoto.
  ///
  /// In ko, this message translates to:
  /// **'다른 사진·동영상으로 바꾸기'**
  String get editSwapPhoto;

  /// No description provided for @editThisPhoto.
  ///
  /// In ko, this message translates to:
  /// **'이 사진 편집'**
  String get editThisPhoto;

  /// No description provided for @editAddPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진·동영상 넣기'**
  String get editAddPhoto;

  /// No description provided for @editingMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진 수정'**
  String get editingMedia;

  /// No description provided for @editMediaHint.
  ///
  /// In ko, this message translates to:
  /// **'여기를 누르면 사진 바꾸기·편집'**
  String get editMediaHint;

  /// No description provided for @editNewPhotoPicked.
  ///
  /// In ko, this message translates to:
  /// **'새 사진으로 바뀌어요'**
  String get editNewPhotoPicked;

  /// No description provided for @noSwapPublic.
  ///
  /// In ko, this message translates to:
  /// **'공개 그룹·채널에서는 보낸 사진을 바꿀 수 없어요. 설명만 고칠 수 있어요.'**
  String get noSwapPublic;

  /// No description provided for @editMediaFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정하지 못했어요. 잠시 뒤 다시 해 주세요.'**
  String get editMediaFailed;

  /// No description provided for @photoMineForThem.
  ///
  /// In ko, this message translates to:
  /// **'내가 정한 사진'**
  String get photoMineForThem;

  /// No description provided for @photoTheirs.
  ///
  /// In ko, this message translates to:
  /// **'올린 사진'**
  String get photoTheirs;

  /// No description provided for @myProfile.
  ///
  /// In ko, this message translates to:
  /// **'내 프로필'**
  String get myProfile;

  /// No description provided for @myProfileSeenBy.
  ///
  /// In ko, this message translates to:
  /// **'보는 사람'**
  String get myProfileSeenBy;

  /// No description provided for @seenEveryone.
  ///
  /// In ko, this message translates to:
  /// **'모든 사람'**
  String get seenEveryone;

  /// No description provided for @seenContacts.
  ///
  /// In ko, this message translates to:
  /// **'내 연락처'**
  String get seenContacts;

  /// No description provided for @myProfileEveryoneInfo.
  ///
  /// In ko, this message translates to:
  /// **'내 아이디를 아는 누구나 이렇게 봐요. \'모두\'로 둔 것만 서버에 저장돼요.'**
  String get myProfileEveryoneInfo;

  /// No description provided for @myProfileContactsInfo.
  ///
  /// In ko, this message translates to:
  /// **'나와 1:1 대화를 하는 사람은 이렇게 봐요. 서버를 거치지 않고 암호화된 1:1 대화로만 전달돼요.'**
  String get myProfileContactsInfo;

  /// No description provided for @myProfileHidden.
  ///
  /// In ko, this message translates to:
  /// **'안 보이는 것: {what}'**
  String myProfileHidden(String what);

  /// No description provided for @myProfileWho.
  ///
  /// In ko, this message translates to:
  /// **'누가 무엇을 볼지 바꾸기'**
  String get myProfileWho;

  /// No description provided for @myProfileEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get myProfileEdit;

  /// No description provided for @myProfileNoPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진이 안 보여요'**
  String get myProfileNoPhoto;

  /// No description provided for @publicPhoto.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진'**
  String get publicPhoto;

  /// No description provided for @publicPhotoSet.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진 설정'**
  String get publicPhotoSet;

  /// No description provided for @publicPhotoChange.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진 바꾸기'**
  String get publicPhotoChange;

  /// No description provided for @publicPhotoRemove.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진 지우기'**
  String get publicPhotoRemove;

  /// No description provided for @publicPhotoInfo.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 볼 수 없는 사람에게는 이 사진이 대신 보여요. 공개 사진은 서버에 저장돼요.'**
  String get publicPhotoInfo;

  /// No description provided for @publicPhotoDone.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진을 정했어요'**
  String get publicPhotoDone;

  /// No description provided for @publicPhotoRemoved.
  ///
  /// In ko, this message translates to:
  /// **'공개 사진을 지웠어요'**
  String get publicPhotoRemoved;

  /// No description provided for @oldPhotos.
  ///
  /// In ko, this message translates to:
  /// **'예전 사진'**
  String get oldPhotos;

  /// No description provided for @oldPhotosInfo.
  ///
  /// In ko, this message translates to:
  /// **'예전 사진은 이 휴대폰에만 암호화되어 있어요. 다른 사람에게는 대표 사진 한 장만 보여요.'**
  String get oldPhotosInfo;

  /// No description provided for @photoMain.
  ///
  /// In ko, this message translates to:
  /// **'대표 사진'**
  String get photoMain;

  /// No description provided for @photoMakeMain.
  ///
  /// In ko, this message translates to:
  /// **'대표 사진으로'**
  String get photoMakeMain;

  /// No description provided for @photoMainDone.
  ///
  /// In ko, this message translates to:
  /// **'이제 대표 사진이에요'**
  String get photoMainDone;

  /// No description provided for @photoDeleted.
  ///
  /// In ko, this message translates to:
  /// **'사진을 지웠어요'**
  String get photoDeleted;

  /// No description provided for @photoUsedUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 쓴 사진'**
  String photoUsedUntil(String date);

  /// No description provided for @photoSuggest.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 사진 제안'**
  String photoSuggest(String name);

  /// No description provided for @photoSuggestInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 사진은 암호화되어 1:1 대화로 가요. 받은 사람이 \'내 사진으로\'를 눌러야 바뀌어요.'**
  String get photoSuggestInfo;

  /// No description provided for @photoSuggestSent.
  ///
  /// In ko, this message translates to:
  /// **'사진을 제안했어요'**
  String get photoSuggestSent;

  /// No description provided for @photoSuggestNoChat.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화가 있어야 사진을 제안할 수 있어요'**
  String get photoSuggestNoChat;

  /// No description provided for @photoSuggestMine.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 제안했어요'**
  String get photoSuggestMine;

  /// No description provided for @photoSuggestTheirs.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 프로필 사진을 제안했어요'**
  String photoSuggestTheirs(String name);

  /// No description provided for @photoSuggestView.
  ///
  /// In ko, this message translates to:
  /// **'사진 보기'**
  String get photoSuggestView;

  /// No description provided for @photoSuggestUse.
  ///
  /// In ko, this message translates to:
  /// **'내 사진으로'**
  String get photoSuggestUse;

  /// No description provided for @photoSuggestPreview.
  ///
  /// In ko, this message translates to:
  /// **'🖼️ 사진 제안'**
  String get photoSuggestPreview;

  /// No description provided for @emojiPhoto.
  ///
  /// In ko, this message translates to:
  /// **'이모지나 스티커로'**
  String get emojiPhoto;

  /// No description provided for @emojiPhotoTitle.
  ///
  /// In ko, this message translates to:
  /// **'이모지 사진'**
  String get emojiPhotoTitle;

  /// No description provided for @emojiPhotoEmoji.
  ///
  /// In ko, this message translates to:
  /// **'이모지'**
  String get emojiPhotoEmoji;

  /// No description provided for @emojiPhotoSticker.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get emojiPhotoSticker;

  /// No description provided for @emojiPhotoSize.
  ///
  /// In ko, this message translates to:
  /// **'크기'**
  String get emojiPhotoSize;

  /// No description provided for @emojiPhotoColor.
  ///
  /// In ko, this message translates to:
  /// **'배경'**
  String get emojiPhotoColor;

  /// No description provided for @emojiPhotoCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 고르기'**
  String get emojiPhotoCustom;

  /// No description provided for @emojiPhotoInfo.
  ///
  /// In ko, this message translates to:
  /// **'사진이 없어도 이모지나 부루미 캐릭터로 나만의 프로필 사진을 만들 수 있어요.'**
  String get emojiPhotoInfo;

  /// No description provided for @skEdit.
  ///
  /// In ko, this message translates to:
  /// **'고치기'**
  String get skEdit;

  /// No description provided for @skKeep.
  ///
  /// In ko, this message translates to:
  /// **'프로필에 남기기'**
  String get skKeep;

  /// No description provided for @skUnkeep.
  ///
  /// In ko, this message translates to:
  /// **'프로필에서 빼기'**
  String get skUnkeep;

  /// No description provided for @skAlbumPut.
  ///
  /// In ko, this message translates to:
  /// **'앨범에 넣기'**
  String get skAlbumPut;

  /// No description provided for @skTop.
  ///
  /// In ko, this message translates to:
  /// **'맨 위에 고정'**
  String get skTop;

  /// No description provided for @skUntop.
  ///
  /// In ko, this message translates to:
  /// **'고정 풀기'**
  String get skUntop;

  /// No description provided for @skCover.
  ///
  /// In ko, this message translates to:
  /// **'표지 고르기'**
  String get skCover;

  /// No description provided for @skDelete.
  ///
  /// In ko, this message translates to:
  /// **'스토리 지우기'**
  String get skDelete;

  /// No description provided for @skFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 바꿀 수 없어요. 잠시 뒤에 다시 해 주세요'**
  String get skFailed;

  /// No description provided for @skKeptDone.
  ///
  /// In ko, this message translates to:
  /// **'프로필에 남겼어요'**
  String get skKeptDone;

  /// No description provided for @skUnkeptDone.
  ///
  /// In ko, this message translates to:
  /// **'프로필에서 뺐어요'**
  String get skUnkeptDone;

  /// No description provided for @skDeleteIn.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤에 지워져요'**
  String skDeleteIn(int n);

  /// No description provided for @skTopFull.
  ///
  /// In ko, this message translates to:
  /// **'맨 위에는 3개까지 고정할 수 있어요'**
  String get skTopFull;

  /// No description provided for @skAlbums.
  ///
  /// In ko, this message translates to:
  /// **'앨범'**
  String get skAlbums;

  /// No description provided for @skAlbumNone.
  ///
  /// In ko, this message translates to:
  /// **'앨범 없음'**
  String get skAlbumNone;

  /// No description provided for @skAlbumNew.
  ///
  /// In ko, this message translates to:
  /// **'새 앨범'**
  String get skAlbumNew;

  /// No description provided for @skAlbumName.
  ///
  /// In ko, this message translates to:
  /// **'앨범 이름'**
  String get skAlbumName;

  /// No description provided for @skAlbumInfo.
  ///
  /// In ko, this message translates to:
  /// **'앨범은 프로필에서 스토리를 주제별로 모아 보여 줘요. 그 스토리를 받은 친구에게만 보여요.'**
  String get skAlbumInfo;

  /// No description provided for @skCoverTitle.
  ///
  /// In ko, this message translates to:
  /// **'표지'**
  String get skCoverTitle;

  /// No description provided for @skCoverNone.
  ///
  /// In ko, this message translates to:
  /// **'이 영상에서는 장면을 꺼낼 수 없어요'**
  String get skCoverNone;

  /// No description provided for @skCoverInfo.
  ///
  /// In ko, this message translates to:
  /// **'프로필과 보관함에 이 장면이 보여요'**
  String get skCoverInfo;

  /// No description provided for @skKeptCount.
  ///
  /// In ko, this message translates to:
  /// **'프로필 스토리 {n}개'**
  String skKeptCount(int n);

  /// No description provided for @skAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get skAll;

  /// No description provided for @skPostOpen.
  ///
  /// In ko, this message translates to:
  /// **'글 보기'**
  String get skPostOpen;

  /// No description provided for @skMusicTooBig.
  ///
  /// In ko, this message translates to:
  /// **'음악 파일은 10MB까지 넣을 수 있어요'**
  String get skMusicTooBig;

  /// No description provided for @skReact.
  ///
  /// In ko, this message translates to:
  /// **'반응'**
  String get skReact;

  /// No description provided for @skMusic.
  ///
  /// In ko, this message translates to:
  /// **'음악'**
  String get skMusic;

  /// No description provided for @skRound.
  ///
  /// In ko, this message translates to:
  /// **'동그라미 영상'**
  String get skRound;

  /// No description provided for @skReactPick.
  ///
  /// In ko, this message translates to:
  /// **'반응 스티커'**
  String get skReactPick;

  /// No description provided for @skReactInfo.
  ///
  /// In ko, this message translates to:
  /// **'친구가 누르면 나에게만 반응이 와요'**
  String get skReactInfo;

  /// No description provided for @skEdited.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get skEdited;

  /// No description provided for @skReactSent.
  ///
  /// In ko, this message translates to:
  /// **'반응을 보냈어요'**
  String get skReactSent;

  /// No description provided for @skSaved.
  ///
  /// In ko, this message translates to:
  /// **'고쳤어요'**
  String get skSaved;

  /// No description provided for @skCoverPill.
  ///
  /// In ko, this message translates to:
  /// **'표지'**
  String get skCoverPill;

  /// No description provided for @skSplit.
  ///
  /// In ko, this message translates to:
  /// **'긴 영상이라 스토리 {n}개로 나눠 올려요'**
  String skSplit(int n);

  /// No description provided for @skSplitInfo.
  ///
  /// In ko, this message translates to:
  /// **'누르면 그 부분을 빼요'**
  String get skSplitInfo;

  /// No description provided for @skGroupStory.
  ///
  /// In ko, this message translates to:
  /// **'그룹 스토리'**
  String get skGroupStory;

  /// No description provided for @skGroupStoryNew.
  ///
  /// In ko, this message translates to:
  /// **'그룹 스토리 올리기'**
  String get skGroupStoryNew;

  /// No description provided for @skChannelStoryNew.
  ///
  /// In ko, this message translates to:
  /// **'채널 스토리 올리기'**
  String get skChannelStoryNew;

  /// No description provided for @skGroupStoryInfo.
  ///
  /// In ko, this message translates to:
  /// **'운영자만 올릴 수 있어요. 멤버 모두가 대화 목록 위에서 봐요. 그룹 암호화 안에서만 가요.'**
  String get skGroupStoryInfo;

  /// No description provided for @skGroupOpen.
  ///
  /// In ko, this message translates to:
  /// **'그룹으로 가기'**
  String get skGroupOpen;

  /// No description provided for @skGroupShared.
  ///
  /// In ko, this message translates to:
  /// **'그룹 스토리를 올렸어요'**
  String get skGroupShared;

  /// No description provided for @skToStory.
  ///
  /// In ko, this message translates to:
  /// **'내 스토리'**
  String get skToStory;

  /// No description provided for @skKeptMine.
  ///
  /// In ko, this message translates to:
  /// **'프로필 스토리'**
  String get skKeptMine;

  /// No description provided for @skKeptEmpty.
  ///
  /// In ko, this message translates to:
  /// **'프로필에 남긴 스토리가 없어요. 내 스토리를 열고 ⋯ 버튼에서 프로필에 남기기를 눌러요.'**
  String get skKeptEmpty;

  /// No description provided for @skKeptInfo.
  ///
  /// In ko, this message translates to:
  /// **'24시간이 지나도 친구들이 내 프로필에서 볼 수 있어요. 그 스토리를 받은 친구에게만 보여요.'**
  String get skKeptInfo;

  /// No description provided for @skMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get skMore;

  /// No description provided for @skMuteTap.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 소리 켜고 끄기'**
  String get skMuteTap;

  /// No description provided for @skRoundShort.
  ///
  /// In ko, this message translates to:
  /// **'동그라미'**
  String get skRoundShort;

  /// No description provided for @quickForwardIn.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤에 전달해요'**
  String quickForwardIn(int n);

  /// No description provided for @quickForwardTo.
  ///
  /// In ko, this message translates to:
  /// **'받는 곳: {name}'**
  String quickForwardTo(String name);

  /// No description provided for @quickForwardHint.
  ///
  /// In ko, this message translates to:
  /// **'화살표를 꾹 누른 채 밀면 바로 전달돼요'**
  String get quickForwardHint;

  /// No description provided for @nextChannelPull.
  ///
  /// In ko, this message translates to:
  /// **'안 읽은 글 {n}개 · 위로 밀어 다음 채널'**
  String nextChannelPull(int n);

  /// No description provided for @nextChannelLetGo.
  ///
  /// In ko, this message translates to:
  /// **'놓으면 다음 채널로 가요'**
  String get nextChannelLetGo;

  /// No description provided for @sendAsTitle.
  ///
  /// In ko, this message translates to:
  /// **'보내는 이름'**
  String get sendAsTitle;

  /// No description provided for @sendAsInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에서 내 글이 어떤 이름으로 보일지 골라요'**
  String get sendAsInfo;

  /// No description provided for @sendAsMe.
  ///
  /// In ko, this message translates to:
  /// **'내 이름과 사진으로 보여요'**
  String get sendAsMe;

  /// No description provided for @sendAsChannelHidden.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름만 보이고 내 이름은 안 보여요'**
  String get sendAsChannelHidden;

  /// No description provided for @sendAsMyChannel.
  ///
  /// In ko, this message translates to:
  /// **'내 공개 채널 이름으로 보여요'**
  String get sendAsMyChannel;

  /// No description provided for @sendAsChanged.
  ///
  /// In ko, this message translates to:
  /// **'{name} 이름으로 보내요'**
  String sendAsChanged(String name);

  /// No description provided for @showAuthors.
  ///
  /// In ko, this message translates to:
  /// **'작성자 프로필 보이기'**
  String get showAuthors;

  /// No description provided for @showAuthorsInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 글마다 쓴 관리자의 사진과 이름이 보여서 그룹처럼 보여요. 관리자는 입력칸 왼쪽 사진을 눌러 채널 이름으로 올릴 수도 있어요.'**
  String get showAuthorsInfo;

  /// No description provided for @subscriberDm.
  ///
  /// In ko, this message translates to:
  /// **'구독자 메시지 받기'**
  String get subscriberDm;

  /// No description provided for @subscriberDmInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 구독자가 💬 버튼으로 관리자에게 따로 메시지를 보낼 수 있어요. 대화는 끝까지 암호화돼요.'**
  String get subscriberDmInfo;

  /// No description provided for @dmInboxTag.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get dmInboxTag;

  /// No description provided for @dmInboxSub.
  ///
  /// In ko, this message translates to:
  /// **'{channel} · 구독자 메시지'**
  String dmInboxSub(String channel);

  /// No description provided for @dmEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'관리자에게 메시지 보내기'**
  String get dmEmptyTitle;

  /// No description provided for @dmEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'{channel} 관리자에게만 보여요. 끝까지 암호화돼요.'**
  String dmEmptyBody(String channel);

  /// No description provided for @dmButtonHint.
  ///
  /// In ko, this message translates to:
  /// **'채널 관리자에게 메시지 보내기'**
  String get dmButtonHint;

  /// No description provided for @dmToAdmins.
  ///
  /// In ko, this message translates to:
  /// **'관리자에게 보내는 메시지'**
  String get dmToAdmins;

  /// No description provided for @dmOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 메시지를 보낼 수 없어요'**
  String get dmOpenFailed;

  /// No description provided for @allBackgrounds.
  ///
  /// In ko, this message translates to:
  /// **'배경 모두 보기'**
  String get allBackgrounds;

  /// No description provided for @allBackgroundsInfo.
  ///
  /// In ko, this message translates to:
  /// **'누르면 내 기본 배경이 바로 바뀌어요. 밤을 누르면 야간 모드일 때 모습을 미리 볼 수 있어요.'**
  String get allBackgroundsInfo;

  /// No description provided for @channelNameColor.
  ///
  /// In ko, this message translates to:
  /// **'채널 이름 색'**
  String get channelNameColor;

  /// No description provided for @channelNameColorInfo.
  ///
  /// In ko, this message translates to:
  /// **'채널 글에 답장할 때 인용 칸이 이 색으로 보여요.'**
  String get channelNameColorInfo;

  /// No description provided for @dayLook.
  ///
  /// In ko, this message translates to:
  /// **'낮'**
  String get dayLook;

  /// No description provided for @nightLook.
  ///
  /// In ko, this message translates to:
  /// **'밤'**
  String get nightLook;

  /// No description provided for @gradInfo.
  ///
  /// In ko, this message translates to:
  /// **'내가 메시지를 보낼 때마다 색이 조금씩 돌아요. 색과 무늬는 이 휴대폰에만 저장돼요.'**
  String get gradInfo;

  /// No description provided for @gradSky.
  ///
  /// In ko, this message translates to:
  /// **'하늘'**
  String get gradSky;

  /// No description provided for @gradPeach.
  ///
  /// In ko, this message translates to:
  /// **'복숭아'**
  String get gradPeach;

  /// No description provided for @gradMint.
  ///
  /// In ko, this message translates to:
  /// **'민트'**
  String get gradMint;

  /// No description provided for @gradLilac.
  ///
  /// In ko, this message translates to:
  /// **'라일락'**
  String get gradLilac;

  /// No description provided for @gradSunset.
  ///
  /// In ko, this message translates to:
  /// **'노을'**
  String get gradSunset;

  /// No description provided for @gradNight.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get gradNight;

  /// No description provided for @gradPickColor.
  ///
  /// In ko, this message translates to:
  /// **'동그라미를 누르고 색을 골라요'**
  String get gradPickColor;

  /// No description provided for @gradTapToTurn.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 움직임 보기'**
  String get gradTapToTurn;

  /// No description provided for @lookFromLevel.
  ///
  /// In ko, this message translates to:
  /// **'레벨 {n}부터'**
  String lookFromLevel(int n);

  /// No description provided for @lookSampleLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 미리보기'**
  String get lookSampleLink;

  /// No description provided for @lookSampleLinkText.
  ///
  /// In ko, this message translates to:
  /// **'burumy.app · 새 소식'**
  String get lookSampleLinkText;

  /// No description provided for @lookSampleQuote.
  ///
  /// In ko, this message translates to:
  /// **'오늘 몇 시에 만나요?'**
  String get lookSampleQuote;

  /// No description provided for @lookSampleText.
  ///
  /// In ko, this message translates to:
  /// **'7시 어때요?'**
  String get lookSampleText;

  /// No description provided for @myThemes.
  ///
  /// In ko, this message translates to:
  /// **'내 테마'**
  String get myThemes;

  /// No description provided for @myThemesInfo.
  ///
  /// In ko, this message translates to:
  /// **'누르면 바로 바뀌어요. 꾹 누르면 고치기·링크 복사·삭제를 할 수 있어요. 링크를 대화에 보내면 친구도 같은 테마를 쓸 수 있어요.'**
  String get myThemesInfo;

  /// No description provided for @nightBrightness.
  ///
  /// In ko, this message translates to:
  /// **'밤 밝기'**
  String get nightBrightness;

  /// No description provided for @nightBrightnessInfo.
  ///
  /// In ko, this message translates to:
  /// **'야간 모드일 때 사진·색 배경을 이만큼 어둡게 해요.'**
  String get nightBrightnessInfo;

  /// No description provided for @none.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get none;

  /// No description provided for @patternStrength.
  ///
  /// In ko, this message translates to:
  /// **'무늬 강도'**
  String get patternStrength;

  /// No description provided for @patternTitle.
  ///
  /// In ko, this message translates to:
  /// **'무늬'**
  String get patternTitle;

  /// No description provided for @personLook.
  ///
  /// In ko, this message translates to:
  /// **'이름·프로필 꾸미기'**
  String get personLook;

  /// No description provided for @personLookInfo.
  ///
  /// In ko, this message translates to:
  /// **'그룹에서는 이름 색과 함께 모두에게 보이고, 1:1 대화 상대에게는 암호화된 쪽지로 전해져요.'**
  String get personLookInfo;

  /// No description provided for @pickBackground.
  ///
  /// In ko, this message translates to:
  /// **'배경 고르기'**
  String get pickBackground;

  /// No description provided for @profileColor.
  ///
  /// In ko, this message translates to:
  /// **'프로필 색'**
  String get profileColor;

  /// No description provided for @profileIcons.
  ///
  /// In ko, this message translates to:
  /// **'프로필 무늬'**
  String get profileIcons;

  /// No description provided for @replyIcons.
  ///
  /// In ko, this message translates to:
  /// **'답장 무늬'**
  String get replyIcons;

  /// No description provided for @replyIconsInfo.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람이 내 메시지에 답장하면 인용 칸에 이 무늬가 흐리게 보여요.'**
  String get replyIconsInfo;

  /// No description provided for @roomCoverColor.
  ///
  /// In ko, this message translates to:
  /// **'표지 색'**
  String get roomCoverColor;

  /// No description provided for @roomLogoIcons.
  ///
  /// In ko, this message translates to:
  /// **'표지 무늬'**
  String get roomLogoIcons;

  /// No description provided for @roomLook.
  ///
  /// In ko, this message translates to:
  /// **'모양'**
  String get roomLook;

  /// No description provided for @roomLookFailed.
  ///
  /// In ko, this message translates to:
  /// **'바꾸지 못했어요. 관리자인지 확인해 주세요.'**
  String get roomLookFailed;

  /// No description provided for @roomLookInfo.
  ///
  /// In ko, this message translates to:
  /// **'모든 멤버에게 보여요. 커뮤니티 레벨이 오를수록 꾸밀 수 있는 것이 늘어나요.'**
  String get roomLookInfo;

  /// No description provided for @roomLookSaved.
  ///
  /// In ko, this message translates to:
  /// **'모양을 바꿨어요'**
  String get roomLookSaved;

  /// No description provided for @roomStatusEmoji.
  ///
  /// In ko, this message translates to:
  /// **'상태 이모지'**
  String get roomStatusEmoji;

  /// No description provided for @roomWallAll.
  ///
  /// In ko, this message translates to:
  /// **'모두에게 보이는 배경'**
  String get roomWallAll;

  /// No description provided for @roomWallAllInfo.
  ///
  /// In ko, this message translates to:
  /// **'멤버가 이 대화방 배경을 따로 고르지 않았다면 이 배경이 보여요.'**
  String get roomWallAllInfo;

  /// No description provided for @themeAccentInfo.
  ///
  /// In ko, this message translates to:
  /// **'강조색은 말풍선·버튼·스위치에 쓰여요. 너무 어두운 색은 읽기 쉽게 조금 밝게 바꿔요.'**
  String get themeAccentInfo;

  /// No description provided for @themeApplied.
  ///
  /// In ko, this message translates to:
  /// **'테마를 적용했어요'**
  String get themeApplied;

  /// No description provided for @themeApply.
  ///
  /// In ko, this message translates to:
  /// **'이 테마 적용하기'**
  String get themeApply;

  /// No description provided for @themeCardOpen.
  ///
  /// In ko, this message translates to:
  /// **'테마 보기'**
  String get themeCardOpen;

  /// No description provided for @themeCopyLink.
  ///
  /// In ko, this message translates to:
  /// **'링크 복사'**
  String get themeCopyLink;

  /// No description provided for @themeDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'내 테마'**
  String get themeDefaultName;

  /// No description provided for @themeDeletedIn.
  ///
  /// In ko, this message translates to:
  /// **'{n}초 뒤에 테마를 지워요'**
  String themeDeletedIn(int n);

  /// No description provided for @themeEdit.
  ///
  /// In ko, this message translates to:
  /// **'테마 고치기'**
  String get themeEdit;

  /// No description provided for @themeLinkCopied.
  ///
  /// In ko, this message translates to:
  /// **'테마 링크를 복사했어요. 대화에 붙여 보내 보세요.'**
  String get themeLinkCopied;

  /// No description provided for @themeLinkInfo.
  ///
  /// In ko, this message translates to:
  /// **'테마는 링크 안에 들어 있어요. 서버에서 받아 오는 것은 없어요.'**
  String get themeLinkInfo;

  /// No description provided for @themeMake.
  ///
  /// In ko, this message translates to:
  /// **'테마 만들기'**
  String get themeMake;

  /// No description provided for @themeMakeInfo.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 바로 적용돼요. 야간 모드에서는 같은 배경이 조금 어둡게 보여요.'**
  String get themeMakeInfo;

  /// No description provided for @themeNameHint.
  ///
  /// In ko, this message translates to:
  /// **'테마 이름'**
  String get themeNameHint;

  /// No description provided for @themeNew.
  ///
  /// In ko, this message translates to:
  /// **'새 테마'**
  String get themeNew;

  /// No description provided for @themePartAccent.
  ///
  /// In ko, this message translates to:
  /// **'강조색'**
  String get themePartAccent;

  /// No description provided for @themePartWall.
  ///
  /// In ko, this message translates to:
  /// **'배경'**
  String get themePartWall;

  /// No description provided for @themeSaved.
  ///
  /// In ko, this message translates to:
  /// **'테마를 저장했어요'**
  String get themeSaved;

  /// No description provided for @wallApplyBoth.
  ///
  /// In ko, this message translates to:
  /// **'나와 상대 모두 적용'**
  String get wallApplyBoth;

  /// No description provided for @wallApplyHere.
  ///
  /// In ko, this message translates to:
  /// **'이 대화에만 적용'**
  String get wallApplyHere;

  /// No description provided for @wallBlur.
  ///
  /// In ko, this message translates to:
  /// **'흐림'**
  String get wallBlur;

  /// No description provided for @wallFromPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진에서 고르기'**
  String get wallFromPhotos;

  /// No description provided for @wallMakeColors.
  ///
  /// In ko, this message translates to:
  /// **'색 섞어 만들기'**
  String get wallMakeColors;

  /// No description provided for @wallMine.
  ///
  /// In ko, this message translates to:
  /// **'내가 만든 배경'**
  String get wallMine;

  /// No description provided for @wallMixed.
  ///
  /// In ko, this message translates to:
  /// **'내가 섞은 색'**
  String get wallMixed;

  /// No description provided for @wallMoreChoices.
  ///
  /// In ko, this message translates to:
  /// **'사진·색으로 고르기'**
  String get wallMoreChoices;

  /// No description provided for @wallMotion.
  ///
  /// In ko, this message translates to:
  /// **'움직임'**
  String get wallMotion;

  /// No description provided for @wallNoteKeep.
  ///
  /// In ko, this message translates to:
  /// **'그대로 두기'**
  String get wallNoteKeep;

  /// No description provided for @wallNoteMine.
  ///
  /// In ko, this message translates to:
  /// **'나와 {name}님 화면에 새 배경을 설정했어요'**
  String wallNoteMine(String name);

  /// No description provided for @wallNoteTheirs.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 두 사람 화면에 새 배경을 설정했어요'**
  String wallNoteTheirs(String name);

  /// No description provided for @wallNoteUndo.
  ///
  /// In ko, this message translates to:
  /// **'내 배경으로 되돌리기'**
  String get wallNoteUndo;

  /// No description provided for @wallPhotoMineOnly.
  ///
  /// In ko, this message translates to:
  /// **'사진 배경은 내 휴대폰에만 보여요'**
  String get wallPhotoMineOnly;

  /// No description provided for @wallPreview.
  ///
  /// In ko, this message translates to:
  /// **'배경 미리보기'**
  String get wallPreview;

  /// No description provided for @wallPreviewReply.
  ///
  /// In ko, this message translates to:
  /// **'옆으로 넘기면 다른 배경을 볼 수 있어요'**
  String get wallPreviewReply;

  /// No description provided for @wallReady.
  ///
  /// In ko, this message translates to:
  /// **'부루미 배경'**
  String get wallReady;

  /// No description provided for @wallSet.
  ///
  /// In ko, this message translates to:
  /// **'배경으로 설정'**
  String get wallSet;

  /// No description provided for @wallSolid.
  ///
  /// In ko, this message translates to:
  /// **'단색'**
  String get wallSolid;

  /// No description provided for @wallSolidColor.
  ///
  /// In ko, this message translates to:
  /// **'단색'**
  String get wallSolidColor;

  /// No description provided for @anonAdminLabel.
  ///
  /// In ko, this message translates to:
  /// **'익명 관리자'**
  String get anonAdminLabel;

  /// No description provided for @anonAdmin.
  ///
  /// In ko, this message translates to:
  /// **'익명으로 남기'**
  String get anonAdmin;

  /// No description provided for @anonAdminInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 이 관리자가 쓴 글은 그룹 이름과 사진으로 보이고, 멤버 목록에서도 보이지 않아요. 켜기 전에 쓴 글은 그대로예요. 앱 화면에서만 숨겨지고, 서버 기록에는 보낸 계정이 남아요.'**
  String get anonAdminInfo;

  /// No description provided for @anonSelfInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 내가 쓴 글이 그룹 이름과 사진으로 보이고, 멤버 목록에서 나를 숨겨요. 켜기 전에 쓴 글은 그대로예요. 앱 화면에서만 숨겨지고, 서버 기록에는 보낸 계정이 남아요.'**
  String get anonSelfInfo;

  /// No description provided for @anonShort.
  ///
  /// In ko, this message translates to:
  /// **'익명'**
  String get anonShort;

  /// No description provided for @myTag.
  ///
  /// In ko, this message translates to:
  /// **'내 태그'**
  String get myTag;

  /// No description provided for @myTagAdd.
  ///
  /// In ko, this message translates to:
  /// **'내 태그 달기'**
  String get myTagAdd;

  /// No description provided for @myTagInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 그룹에서 내 이름 옆에 보여요 (최대 16자). 비우면 태그가 사라져요.'**
  String get myTagInfo;

  /// No description provided for @ownTags.
  ///
  /// In ko, this message translates to:
  /// **'스스로 태그 달기'**
  String get ownTags;

  /// No description provided for @ownTagsInfo.
  ///
  /// In ko, this message translates to:
  /// **'켜면 멤버가 그룹 정보에서 자기 이름 옆 태그를 직접 달 수 있어요. 관리자가 달아 준 태그가 있으면 그게 먼저 보여요. 관리자 태그는 초록색, 멤버 태그는 회색이에요.'**
  String get ownTagsInfo;

  /// No description provided for @antiSpam.
  ///
  /// In ko, this message translates to:
  /// **'강력 스팸 차단'**
  String get antiSpam;

  /// No description provided for @antiSpamIntro.
  ///
  /// In ko, this message translates to:
  /// **'광고·도박·대출 같은 스팸을 관리자 폰이 알아서 지워요. 대화 내용은 서버가 읽을 수 없어서, 글을 지울 수 있는 관리자 폰에서 확인해요.'**
  String get antiSpamIntro;

  /// No description provided for @antiSpamInfo.
  ///
  /// In ko, this message translates to:
  /// **'200명이 넘는 큰 그룹에 특히 좋아요. 관리자 글과 \'스팸 아님\'으로 둔 사람 글은 지우지 않아요. 지워진 글은 모두의 화면에서 가루처럼 흩어져 사라져요.'**
  String get antiSpamInfo;

  /// No description provided for @antiSpamChecks.
  ///
  /// In ko, this message translates to:
  /// **'이런 글을 걸러요'**
  String get antiSpamChecks;

  /// No description provided for @antiSpamCheckWords.
  ///
  /// In ko, this message translates to:
  /// **'도박·대출·리딩방 같은 스팸 단어'**
  String get antiSpamCheckWords;

  /// No description provided for @antiSpamCheckLinks.
  ///
  /// In ko, this message translates to:
  /// **'새로 온 멤버의 링크와 연락처 (텔레그램 아이디, 오픈채팅, 전화번호)'**
  String get antiSpamCheckLinks;

  /// No description provided for @antiSpamCheckRepeat.
  ///
  /// In ko, this message translates to:
  /// **'같은 글을 여러 번 올리기'**
  String get antiSpamCheckRepeat;

  /// No description provided for @antiSpamCheckMentions.
  ///
  /// In ko, this message translates to:
  /// **'한 번에 여러 사람 부르기 (@ 6개 이상)'**
  String get antiSpamCheckMentions;

  /// No description provided for @antiSpamCheckStrikes.
  ///
  /// In ko, this message translates to:
  /// **'하루에 3번 걸리면 하루 동안 글쓰기 금지'**
  String get antiSpamCheckStrikes;

  /// No description provided for @antiSpamRemoved.
  ///
  /// In ko, this message translates to:
  /// **'스팸 차단이 지운 글'**
  String get antiSpamRemoved;

  /// No description provided for @antiSpamRemovedInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 폰이 지운 글이에요. 잘못 지웠으면 \'스팸 아님\'을 눌러요. 그 사람 글은 다시 거르지 않고, 스팸 때문에 걸린 글쓰기 금지도 풀려요.'**
  String get antiSpamRemovedInfo;

  /// No description provided for @antiSpamNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 지운 글이 없어요'**
  String get antiSpamNone;

  /// No description provided for @spamOk.
  ///
  /// In ko, this message translates to:
  /// **'스팸 아님'**
  String get spamOk;

  /// No description provided for @spamOkMark.
  ///
  /// In ko, this message translates to:
  /// **'스팸 아님 처리됨'**
  String get spamOkMark;

  /// No description provided for @spamOkDone.
  ///
  /// In ko, this message translates to:
  /// **'{name}님 글은 이제 거르지 않아요'**
  String spamOkDone(String name);

  /// No description provided for @logSpam.
  ///
  /// In ko, this message translates to:
  /// **'스팸 차단이 {name}님 글을 지웠어요'**
  String logSpam(String name);

  /// No description provided for @logSpamOk.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 스팸 아님으로 두었어요'**
  String logSpamOk(String name);

  /// No description provided for @groupReadCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 읽음'**
  String groupReadCount(int n);

  /// No description provided for @groupReadTitle.
  ///
  /// In ko, this message translates to:
  /// **'{n}명 읽음'**
  String groupReadTitle(int n);

  /// No description provided for @groupReadNotYet.
  ///
  /// In ko, this message translates to:
  /// **'{n}명은 아직 안 읽었어요.'**
  String groupReadNotYet(int n);

  /// No description provided for @groupReadInfo.
  ///
  /// In ko, this message translates to:
  /// **'100명 이하 그룹에서만 보여요. 읽은 시간은 7일 동안 남아요.'**
  String get groupReadInfo;

  /// No description provided for @groupReadToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {time}'**
  String groupReadToday(String time);

  /// No description provided for @groupReadYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제 {time}'**
  String groupReadYesterday(String time);

  /// No description provided for @draftFromOther.
  ///
  /// In ko, this message translates to:
  /// **'다른 기기에서 쓰던 글을 이어서 쓸 수 있어요'**
  String get draftFromOther;

  /// No description provided for @toneGoing.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 소리를 지워요 · {n}초'**
  String toneGoing(String name, int n);

  /// No description provided for @soundChatDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본 ({name})'**
  String soundChatDefault(String name);

  /// No description provided for @toneMine.
  ///
  /// In ko, this message translates to:
  /// **'내 소리'**
  String get toneMine;

  /// No description provided for @toneMineEmpty.
  ///
  /// In ko, this message translates to:
  /// **'대화에서 5초 이하의 음성 메시지를 길게 누르고 \'알림음으로 저장\'을 누르면 여기에 생겨요.'**
  String get toneMineEmpty;

  /// No description provided for @toneMineInfo.
  ///
  /// In ko, this message translates to:
  /// **'소리는 이 기기 안에 암호화해서 보관해요. 앱을 쓰는 동안 이 소리가 나고, 잠긴 화면 알림은 지금은 기본 소리로 울려요.'**
  String get toneMineInfo;

  /// No description provided for @toneSeconds.
  ///
  /// In ko, this message translates to:
  /// **'{n}초'**
  String toneSeconds(int n);

  /// No description provided for @toneNone.
  ///
  /// In ko, this message translates to:
  /// **'아직 저장한 소리가 없어요'**
  String get toneNone;

  /// No description provided for @toneOurs.
  ///
  /// In ko, this message translates to:
  /// **'부루미 소리'**
  String get toneOurs;

  /// No description provided for @saveAsTone.
  ///
  /// In ko, this message translates to:
  /// **'알림음으로 저장'**
  String get saveAsTone;

  /// No description provided for @toneTooLong.
  ///
  /// In ko, this message translates to:
  /// **'5초·300KB 이하의 소리만 알림음으로 저장할 수 있어요'**
  String get toneTooLong;

  /// No description provided for @toneFull.
  ///
  /// In ko, this message translates to:
  /// **'알림음은 {n}개까지 저장할 수 있어요'**
  String toneFull(int n);

  /// No description provided for @toneDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'{who}의 소리 {n}'**
  String toneDefaultName(String who, int n);

  /// No description provided for @toneSaved.
  ///
  /// In ko, this message translates to:
  /// **'알림음에 추가했어요. 대화의 알림 메뉴에서 고를 수 있어요'**
  String get toneSaved;

  /// No description provided for @toneForChat.
  ///
  /// In ko, this message translates to:
  /// **'알림음 바꾸기'**
  String get toneForChat;

  /// No description provided for @storageTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장 공간'**
  String get storageTitle;

  /// No description provided for @storageOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 임시 파일'**
  String get storageOther;

  /// No description provided for @storageNoLimit.
  ///
  /// In ko, this message translates to:
  /// **'제한 없음'**
  String get storageNoLimit;

  /// No description provided for @storageClearing.
  ///
  /// In ko, this message translates to:
  /// **'{size} 비우는 중 · {n}초'**
  String storageClearing(String size, int n);

  /// No description provided for @storageFreed.
  ///
  /// In ko, this message translates to:
  /// **'{size} 비웠어요'**
  String storageFreed(String size);

  /// No description provided for @storageFreedInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화는 그대로예요. 필요하면 누르는 순간 다시 받아요.'**
  String get storageFreedInfo;

  /// No description provided for @storageNothing.
  ///
  /// In ko, this message translates to:
  /// **'비울 게 없어요'**
  String get storageNothing;

  /// No description provided for @storageOnDevice.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서 쓰는 공간'**
  String get storageOnDevice;

  /// No description provided for @storageOfTotal.
  ///
  /// In ko, this message translates to:
  /// **'전체 {size} 중'**
  String storageOfTotal(String size);

  /// No description provided for @storageKeepsChats.
  ///
  /// In ko, this message translates to:
  /// **'걱정 마세요. 비워도 대화와 메시지는 그대로 남고, 사진·동영상·파일은 누르면 서버에서 다시 받아요.'**
  String get storageKeepsChats;

  /// No description provided for @storagePercent.
  ///
  /// In ko, this message translates to:
  /// **'{n}%'**
  String storagePercent(int n);

  /// No description provided for @storageClearButton.
  ///
  /// In ko, this message translates to:
  /// **'선택한 것 비우기 · {size}'**
  String storageClearButton(String size);

  /// No description provided for @storagePickKind.
  ///
  /// In ko, this message translates to:
  /// **'비울 종류를 골라 주세요'**
  String get storagePickKind;

  /// No description provided for @keepExceptions.
  ///
  /// In ko, this message translates to:
  /// **'예외로 둔 대화'**
  String get keepExceptions;

  /// No description provided for @keepExceptionInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 대화만 따로 정한 기간이 지나면 받아 둔 파일을 지워요. \'안 지워요\'로 두면 이 대화 파일은 자동으로 지우지 않아요.'**
  String get keepExceptionInfo;

  /// No description provided for @storageMaxTitle.
  ///
  /// In ko, this message translates to:
  /// **'최대 저장 용량'**
  String get storageMaxTitle;

  /// No description provided for @storageMaxInfo.
  ///
  /// In ko, this message translates to:
  /// **'받아 둔 파일이 이 크기를 넘으면 가장 오래 안 연 것부터 지워요. 휴대폰과 PC 앱은 각자 이 기기 안에서 지켜요.'**
  String get storageMaxInfo;

  /// No description provided for @storageAllChats.
  ///
  /// In ko, this message translates to:
  /// **'모든 대화 보기'**
  String get storageAllChats;

  /// No description provided for @storageBig.
  ///
  /// In ko, this message translates to:
  /// **'큰 파일'**
  String get storageBig;

  /// No description provided for @storageTabMedia.
  ///
  /// In ko, this message translates to:
  /// **'사진·동영상'**
  String get storageTabMedia;

  /// No description provided for @dataUsageTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 사용량'**
  String get dataUsageTitle;

  /// No description provided for @storageThisChat.
  ///
  /// In ko, this message translates to:
  /// **'이 대화'**
  String get storageThisChat;

  /// No description provided for @usageMessages.
  ///
  /// In ko, this message translates to:
  /// **'메시지'**
  String get usageMessages;

  /// No description provided for @usageCalls.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get usageCalls;

  /// No description provided for @usageResetting.
  ///
  /// In ko, this message translates to:
  /// **'통계를 지워요 · {n}초'**
  String usageResetting(int n);

  /// No description provided for @usageAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get usageAll;

  /// No description provided for @usageCell.
  ///
  /// In ko, this message translates to:
  /// **'모바일 데이터'**
  String get usageCell;

  /// No description provided for @usageWifi.
  ///
  /// In ko, this message translates to:
  /// **'Wi-Fi'**
  String get usageWifi;

  /// No description provided for @usageUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용한 데이터'**
  String get usageUsed;

  /// No description provided for @usageInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서만 세요. 사진·동영상·파일·음성은 실제 크기, 메시지는 글자 크기, 통화는 통화 시간으로 어림한 값이에요.'**
  String get usageInfo;

  /// No description provided for @usageAbout.
  ///
  /// In ko, this message translates to:
  /// **'약 {size}'**
  String usageAbout(String size);

  /// No description provided for @usageSent.
  ///
  /// In ko, this message translates to:
  /// **'보냄'**
  String get usageSent;

  /// No description provided for @usageRecv.
  ///
  /// In ko, this message translates to:
  /// **'받음'**
  String get usageRecv;

  /// No description provided for @usageSentN.
  ///
  /// In ko, this message translates to:
  /// **'보냄 · {n}개'**
  String usageSentN(int n);

  /// No description provided for @usageRecvN.
  ///
  /// In ko, this message translates to:
  /// **'받음 · {n}개'**
  String usageRecvN(int n);

  /// No description provided for @usageSince.
  ///
  /// In ko, this message translates to:
  /// **'{date}부터 센 값이에요'**
  String usageSince(String date);

  /// No description provided for @usageReset.
  ///
  /// In ko, this message translates to:
  /// **'통계 초기화'**
  String get usageReset;

  /// No description provided for @draftSync.
  ///
  /// In ko, this message translates to:
  /// **'임시 글 내 기기끼리 이어쓰기'**
  String get draftSync;

  /// No description provided for @draftSyncSub.
  ///
  /// In ko, this message translates to:
  /// **'쓰다 만 글을 내 다른 기기(PC 등)에서 이어 써요. 암호화해서 내 기기끼리만 주고받아요.'**
  String get draftSyncSub;

  /// No description provided for @archiveSettings.
  ///
  /// In ko, this message translates to:
  /// **'보관함 설정'**
  String get archiveSettings;

  /// No description provided for @archiveHow.
  ///
  /// In ko, this message translates to:
  /// **'보관함은 이렇게 써요'**
  String get archiveHow;

  /// No description provided for @archiveIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'이게 보관함이에요'**
  String get archiveIntroTitle;

  /// No description provided for @archiveIntro1Title.
  ///
  /// In ko, this message translates to:
  /// **'목록을 깔끔하게'**
  String get archiveIntro1Title;

  /// No description provided for @archiveIntro1.
  ///
  /// In ko, this message translates to:
  /// **'자주 안 보는 대화를 옮겨 두면 대화 목록이 가벼워져요. 대화는 그대로 남아요.'**
  String get archiveIntro1;

  /// No description provided for @archiveIntro2Title.
  ///
  /// In ko, this message translates to:
  /// **'알림 끈 대화는 계속 여기에'**
  String get archiveIntro2Title;

  /// No description provided for @archiveIntro2.
  ///
  /// In ko, this message translates to:
  /// **'알림을 끈 대화는 새 메시지가 와도 보관함에 있어요. 알림 켠 대화는 새 메시지가 오면 목록으로 돌아와요. 보관함 설정에서 바꿀 수 있어요.'**
  String get archiveIntro2;

  /// No description provided for @archiveIntro3Title.
  ///
  /// In ko, this message translates to:
  /// **'밀어서 넣고 빼기'**
  String get archiveIntro3Title;

  /// No description provided for @archiveIntro3.
  ///
  /// In ko, this message translates to:
  /// **'대화를 왼쪽으로 밀어 보관하고, 보관함 안에서 다시 밀면 꺼내요.'**
  String get archiveIntro3;

  /// No description provided for @archiveSettingsInfo.
  ///
  /// In ko, this message translates to:
  /// **'보관한 대화가 언제 목록으로 돌아올지 정해요. 이 휴대폰에만 저장돼요.'**
  String get archiveSettingsInfo;

  /// No description provided for @archiveUnmutedHeader.
  ///
  /// In ko, this message translates to:
  /// **'알림 켠 대화'**
  String get archiveUnmutedHeader;

  /// No description provided for @archiveKeepUnmuted.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지가 와도 계속 보관'**
  String get archiveKeepUnmuted;

  /// No description provided for @archiveUnmutedInfo.
  ///
  /// In ko, this message translates to:
  /// **'끄면 알림 켠 대화는 누가 새 메시지를 보낼 때 목록으로 돌아와요. 알림 끈 대화는 언제나 보관함에 남아요.'**
  String get archiveUnmutedInfo;

  /// No description provided for @archiveFolderHeader.
  ///
  /// In ko, this message translates to:
  /// **'폴더에 넣은 대화'**
  String get archiveFolderHeader;

  /// No description provided for @archiveKeepFolder.
  ///
  /// In ko, this message translates to:
  /// **'새 메시지가 와도 계속 보관'**
  String get archiveKeepFolder;

  /// No description provided for @archiveFolderInfo.
  ///
  /// In ko, this message translates to:
  /// **'폴더에 직접 넣은 대화는 폴더 탭에서 볼 수 있으니 보관함에 계속 둘 수 있어요.'**
  String get archiveFolderInfo;

  /// No description provided for @archiveStrangerHeader.
  ///
  /// In ko, this message translates to:
  /// **'모르는 사람'**
  String get archiveStrangerHeader;

  /// No description provided for @folderShare.
  ///
  /// In ko, this message translates to:
  /// **'폴더 공유하기'**
  String get folderShare;

  /// No description provided for @folderShareRowInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크 하나로 이 폴더의 그룹·채널을 친구에게 한 번에 보내요.'**
  String get folderShareRowInfo;

  /// No description provided for @folderShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 폴더 공유'**
  String folderShareTitle(String name);

  /// No description provided for @folderShareInfo.
  ///
  /// In ko, this message translates to:
  /// **'링크를 연 사람은 폴더를 추가하고, 고른 대화에 한 번에 들어와요.'**
  String get folderShareInfo;

  /// No description provided for @folderShareChats.
  ///
  /// In ko, this message translates to:
  /// **'링크에 넣을 대화'**
  String get folderShareChats;

  /// No description provided for @folderShareChatsInfo.
  ///
  /// In ko, this message translates to:
  /// **'1:1 대화와 초대 링크가 없는 대화는 빠져요. 들어올 때는 대화마다 정한 규칙(승인, 가입 질문)을 그대로 지켜요.'**
  String get folderShareChatsInfo;

  /// No description provided for @folderShareNone.
  ///
  /// In ko, this message translates to:
  /// **'이 폴더에는 공유할 그룹이나 채널이 없어요'**
  String get folderShareNone;

  /// No description provided for @folderShareNoLink.
  ///
  /// In ko, this message translates to:
  /// **'초대 링크 없음'**
  String get folderShareNoLink;

  /// No description provided for @folderJoinTitle.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 폴더 추가'**
  String folderJoinTitle(String name);

  /// No description provided for @folderJoinInfo.
  ///
  /// In ko, this message translates to:
  /// **'고른 대화에 들어가고, 대화 목록 위에 이 폴더 탭이 생겨요.'**
  String get folderJoinInfo;

  /// No description provided for @folderJoinChats.
  ///
  /// In ko, this message translates to:
  /// **'대화 {n}개'**
  String folderJoinChats(int n);

  /// No description provided for @folderJoinIn.
  ///
  /// In ko, this message translates to:
  /// **'이미 들어가 있어요'**
  String get folderJoinIn;

  /// No description provided for @folderJoinGo.
  ///
  /// In ko, this message translates to:
  /// **'폴더 추가하고 {n}개 들어가기'**
  String folderJoinGo(int n);

  /// No description provided for @folderJoined.
  ///
  /// In ko, this message translates to:
  /// **'\'{name}\' 폴더를 추가했어요 · 대화 {n}개'**
  String folderJoined(String name, int n);

  /// No description provided for @folderJoinNone.
  ///
  /// In ko, this message translates to:
  /// **'들어간 대화가 없어 폴더를 만들지 않았어요'**
  String get folderJoinNone;

  /// No description provided for @folderJoinAsked.
  ///
  /// In ko, this message translates to:
  /// **'{n}개는 승인을 기다려요.'**
  String folderJoinAsked(int n);

  /// No description provided for @folderJoinFailed.
  ///
  /// In ko, this message translates to:
  /// **'{n}개는 들어가지 못했어요.'**
  String folderJoinFailed(int n);

  /// No description provided for @accountPreviewEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 대화가 없어요'**
  String get accountPreviewEmpty;

  /// No description provided for @accountPreviewSwitch.
  ///
  /// In ko, this message translates to:
  /// **'이 계정으로 바꾸기'**
  String get accountPreviewSwitch;

  /// No description provided for @onceGoesHours.
  ///
  /// In ko, this message translates to:
  /// **'안 열면 {n}시간 뒤 사라져요'**
  String onceGoesHours(int n);

  /// No description provided for @onceGoesMinutes.
  ///
  /// In ko, this message translates to:
  /// **'안 열면 {n}분 뒤 사라져요'**
  String onceGoesMinutes(int n);

  /// No description provided for @onceOpenWithinHours.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 열기 · {n}시간 남음'**
  String onceOpenWithinHours(int n);

  /// No description provided for @onceOpenWithinMinutes.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 열기 · {n}분 남음'**
  String onceOpenWithinMinutes(int n);

  /// No description provided for @zipCount.
  ///
  /// In ko, this message translates to:
  /// **'파일 {n}개'**
  String zipCount(int n);

  /// No description provided for @zipUnpacked.
  ///
  /// In ko, this message translates to:
  /// **'풀면 {size}'**
  String zipUnpacked(String size);

  /// No description provided for @zipFirstOnly.
  ///
  /// In ko, this message translates to:
  /// **'앞의 {n}개만 보여요'**
  String zipFirstOnly(int n);

  /// No description provided for @zipInfo.
  ///
  /// In ko, this message translates to:
  /// **'압축을 풀지 않고 보여 줘요. 누른 파일만 이 폰 메모리에서 열고, 저장하거나 서버로 보내지 않아요.'**
  String get zipInfo;

  /// No description provided for @zipPassword.
  ///
  /// In ko, this message translates to:
  /// **'암호가 걸린 압축 파일이라 안을 볼 수 없어요'**
  String get zipPassword;

  /// No description provided for @zipEmpty.
  ///
  /// In ko, this message translates to:
  /// **'빈 압축 파일이에요'**
  String get zipEmpty;

  /// No description provided for @zipTooBig.
  ///
  /// In ko, this message translates to:
  /// **'풀면 50MB가 넘어서 여기서는 못 열어요'**
  String get zipTooBig;

  /// No description provided for @zipCantOpen.
  ///
  /// In ko, this message translates to:
  /// **'이 파일은 열 수 없어요'**
  String get zipCantOpen;

  /// No description provided for @storyGroupOnly.
  ///
  /// In ko, this message translates to:
  /// **'그룹에만'**
  String get storyGroupOnly;

  /// No description provided for @storyGroupOnlySub.
  ///
  /// In ko, this message translates to:
  /// **'고른 그룹의 멤버만 봐요'**
  String get storyGroupOnlySub;

  /// No description provided for @storyGroupOnlyInfo.
  ///
  /// In ko, this message translates to:
  /// **'그 그룹 멤버라면 친구가 아니어도 볼 수 있어요. 다른 그룹과 친구에게는 가지 않아요.'**
  String get storyGroupOnlyInfo;

  /// No description provided for @storyGroupOnlyLabel.
  ///
  /// In ko, this message translates to:
  /// **'{name}에만'**
  String storyGroupOnlyLabel(String name);

  /// No description provided for @storyGroupOnlyShared.
  ///
  /// In ko, this message translates to:
  /// **'{name} 멤버에게만 올렸어요'**
  String storyGroupOnlyShared(String name);

  /// No description provided for @textStickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'글자 스티커'**
  String get textStickerTitle;

  /// No description provided for @textStickerSave.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get textStickerSave;

  /// No description provided for @textStickerHint.
  ///
  /// In ko, this message translates to:
  /// **'아래에 쓴 글자가 여기에 스티커로 보여요'**
  String get textStickerHint;

  /// No description provided for @textStickerPlain.
  ///
  /// In ko, this message translates to:
  /// **'글자만'**
  String get textStickerPlain;

  /// No description provided for @textStickerBubble.
  ///
  /// In ko, this message translates to:
  /// **'말풍선'**
  String get textStickerBubble;

  /// No description provided for @textStickerBadge.
  ///
  /// In ko, this message translates to:
  /// **'동그라미'**
  String get textStickerBadge;

  /// No description provided for @textStickerTag.
  ///
  /// In ko, this message translates to:
  /// **'이름표'**
  String get textStickerTag;

  /// No description provided for @textStickerPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'짧은 말을 써 보세요'**
  String get textStickerPlaceholder;

  /// No description provided for @textStickerTile.
  ///
  /// In ko, this message translates to:
  /// **'글자'**
  String get textStickerTile;

  /// No description provided for @pdfMarkAdd.
  ///
  /// In ko, this message translates to:
  /// **'형광펜'**
  String get pdfMarkAdd;

  /// No description provided for @pdfMarkDone.
  ///
  /// In ko, this message translates to:
  /// **'형광펜으로 표시했어요'**
  String get pdfMarkDone;

  /// No description provided for @pdfMarks.
  ///
  /// In ko, this message translates to:
  /// **'형광펜 표시 {count}개'**
  String pdfMarks(int count);

  /// No description provided for @pdfMarksTitle.
  ///
  /// In ko, this message translates to:
  /// **'형광펜 표시'**
  String get pdfMarksTitle;

  /// No description provided for @pdfMarksInfo.
  ///
  /// In ko, this message translates to:
  /// **'표시는 이 휴대폰에만 남아요. 대화에 보내기 전에는 아무도 못 봐요.'**
  String get pdfMarksInfo;

  /// No description provided for @pdfMarkPage.
  ///
  /// In ko, this message translates to:
  /// **'{page}쪽'**
  String pdfMarkPage(int page);

  /// No description provided for @pdfMarksSend.
  ///
  /// In ko, this message translates to:
  /// **'대화에 보내기'**
  String get pdfMarksSend;

  /// No description provided for @pdfMarksSent.
  ///
  /// In ko, this message translates to:
  /// **'대화에 보냈어요'**
  String get pdfMarksSent;

  /// No description provided for @pdfMarksQuote.
  ///
  /// In ko, this message translates to:
  /// **'{name}에서 표시한 부분'**
  String pdfMarksQuote(String name);

  /// No description provided for @pdfMarkGoing.
  ///
  /// In ko, this message translates to:
  /// **'표시를 지워요 ({seconds})'**
  String pdfMarkGoing(int seconds);

  /// No description provided for @pdfMarksHow.
  ///
  /// In ko, this message translates to:
  /// **'글자를 꾹 눌러 고른 다음 \'형광펜\'을 누르면 표시돼요.'**
  String get pdfMarksHow;

  /// No description provided for @appIconMarks.
  ///
  /// In ko, this message translates to:
  /// **'부루미 마크'**
  String get appIconMarks;

  /// No description provided for @appIconCharacters.
  ///
  /// In ko, this message translates to:
  /// **'캐릭터'**
  String get appIconCharacters;

  /// No description provided for @appIconLogos.
  ///
  /// In ko, this message translates to:
  /// **'다른 로고'**
  String get appIconLogos;

  /// No description provided for @appIconLogo.
  ///
  /// In ko, this message translates to:
  /// **'로고 {letter}'**
  String appIconLogo(String letter);

  /// No description provided for @linkSummaryButton.
  ///
  /// In ko, this message translates to:
  /// **'3줄 요약'**
  String get linkSummaryButton;

  /// No description provided for @linkSummaryBusy.
  ///
  /// In ko, this message translates to:
  /// **'요약하는 중…'**
  String get linkSummaryBusy;

  /// No description provided for @linkSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'3줄 요약 · 나만 보여요'**
  String get linkSummaryTitle;

  /// No description provided for @linkSummaryFailed.
  ///
  /// In ko, this message translates to:
  /// **'글을 가져오지 못했어요. 읽기 모드로 열어 보세요.'**
  String get linkSummaryFailed;

  /// No description provided for @linkSummaryHide.
  ///
  /// In ko, this message translates to:
  /// **'요약 접기'**
  String get linkSummaryHide;

  /// No description provided for @shotLine.
  ///
  /// In ko, this message translates to:
  /// **'{name}님이 {what, select, photo{한 번 보기 사진을} video{한 번 보기 영상을} voice{한 번 듣기 음성을} round{한 번 보기 동그란 영상을} file{보호된 파일을} bubble{비눗방울을} other{대화 화면을}} 캡처했어요'**
  String shotLine(String name, String what);

  /// No description provided for @shotLineMine.
  ///
  /// In ko, this message translates to:
  /// **'내가 {what, select, photo{한 번 보기 사진을} video{한 번 보기 영상을} voice{한 번 듣기 음성을} round{한 번 보기 동그란 영상을} file{보호된 파일을} bubble{비눗방울을} other{대화 화면을}} 캡처했어요 · 대화방에 알렸어요'**
  String shotLineMine(String what);

  /// No description provided for @shotPreview.
  ///
  /// In ko, this message translates to:
  /// **'📸 {name}님이 캡처했어요'**
  String shotPreview(String name);

  /// No description provided for @shotPreviewMine.
  ///
  /// In ko, this message translates to:
  /// **'📸 캡처했다고 알렸어요'**
  String get shotPreviewMine;

  /// No description provided for @shotInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'캡처 알림'**
  String get shotInfoTitle;

  /// No description provided for @shotInfoBody.
  ///
  /// In ko, this message translates to:
  /// **'부루미는 한 번 보기 사진·영상, 보호된 파일, 공유를 막은 대화를 캡처하지 못하게 막아요. 안드로이드는 캡처하면 검은 화면만 남아요. 아이폰은 앱이 캡처를 막을 수 없어서, 대신 캡처한 사실을 대화방에 알려요. 알림은 끝까지 암호화되어 서버는 몰라요.'**
  String get shotInfoBody;

  /// No description provided for @bestFriendSwitch.
  ///
  /// In ko, this message translates to:
  /// **'제일 친한 친구 표시'**
  String get bestFriendSwitch;

  /// No description provided for @bestFriendInfo.
  ///
  /// In ko, this message translates to:
  /// **'최근 2주 동안 서로 가장 많이 대화한 친구 이름 옆에 ❤가 붙어요. 내 폰이 직접 세고 나만 봐요. 서버도, 그 친구도 몰라요.'**
  String get bestFriendInfo;

  /// No description provided for @bestFriendTip.
  ///
  /// In ko, this message translates to:
  /// **'제일 친한 친구예요'**
  String get bestFriendTip;

  /// No description provided for @bestFriendTipBody.
  ///
  /// In ko, this message translates to:
  /// **'최근 2주 동안 서로 가장 많이 대화했어요. 이 ❤는 나만 보여요.'**
  String get bestFriendTipBody;

  /// No description provided for @memoriesTitle.
  ///
  /// In ko, this message translates to:
  /// **'{years}년 전 오늘'**
  String memoriesTitle(int years);

  /// No description provided for @memoriesPreview.
  ///
  /// In ko, this message translates to:
  /// **'📷 {years}년 전 오늘 저장한 사진 {count}개가 있어요'**
  String memoriesPreview(int years, int count);

  /// No description provided for @memoriesOpen.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get memoriesOpen;

  /// No description provided for @memoriesSwitch.
  ///
  /// In ko, this message translates to:
  /// **'1년 전 오늘 보기'**
  String get memoriesSwitch;

  /// No description provided for @memoriesInfo.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지에 올려 둔 사진·영상 중 몇 년 전 오늘 저장한 것을 폰이 골라 저장한 메시지 줄에 알려 줘요. 새로 올리거나 서버에 보관하는 건 없어요.'**
  String get memoriesInfo;

  /// No description provided for @memoriesSend.
  ///
  /// In ko, this message translates to:
  /// **'대화로 보내기'**
  String get memoriesSend;

  /// No description provided for @memoriesGoTo.
  ///
  /// In ko, this message translates to:
  /// **'저장한 메시지에서 보기'**
  String get memoriesGoTo;

  /// No description provided for @memoriesOnPhone.
  ///
  /// In ko, this message translates to:
  /// **'내 폰이 고른 추억이에요 · 서버에는 없어요'**
  String get memoriesOnPhone;

  /// No description provided for @feedComment.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get feedComment;

  /// No description provided for @feedCommentHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글 달기…'**
  String get feedCommentHint;

  /// No description provided for @feedCommentsKnown.
  ///
  /// In ko, this message translates to:
  /// **'아는 친구 댓글만 보여요'**
  String get feedCommentsKnown;

  /// No description provided for @feedCommentsMine.
  ///
  /// In ko, this message translates to:
  /// **'내 글이라 댓글이 모두 보여요'**
  String get feedCommentsMine;

  /// No description provided for @feedCommentsMore.
  ///
  /// In ko, this message translates to:
  /// **'댓글 {n}개 모두 보기'**
  String feedCommentsMore(int n);

  /// No description provided for @feedCommentDelete.
  ///
  /// In ko, this message translates to:
  /// **'댓글 삭제'**
  String get feedCommentDelete;

  /// No description provided for @feedCommentsTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get feedCommentsTitle;

  /// No description provided for @feedCommentsInfo.
  ///
  /// In ko, this message translates to:
  /// **'댓글은 글쓴이에게만 암호화되어 가고, 글쓴이 폰이 친구들에게 다시 나눠 줘요. 친구 폰은 그 친구가 아는 사람의 댓글만 보여 줘요. 서버는 누가 누구와 친구인지 몰라요. 다른 댓글은 지워지지 않고 내 폰에서만 가려져요.'**
  String get feedCommentsInfo;

  /// No description provided for @memoriesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String memoriesCount(int count);

  /// No description provided for @accountSuspended.
  ///
  /// In ko, this message translates to:
  /// **'계정이 잠시 정지됐어요. 고친 앱이나 프로그램으로 규칙을 어기려는 시도가 여러 번 있었어요. 정지 기간이 끝나면 다시 쓸 수 있고, 그동안은 대화방 나가기만 돼요. 잘못된 정지라면 이의 신청을 보내 주세요.'**
  String get accountSuspended;

  /// No description provided for @accountWarned.
  ///
  /// In ko, this message translates to:
  /// **'이 앱이 바뀐 것 같아요. 같은 시도를 계속하면 계정이 정지돼요. 공식 부루미 앱을 써 주세요.'**
  String get accountWarned;

  /// No description provided for @pullCameraSwitch.
  ///
  /// In ko, this message translates to:
  /// **'아래로 당겨 카메라 열기'**
  String get pullCameraSwitch;

  /// No description provided for @pullCameraInfo.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록 맨 위에서 아래로 길게 당기면 카메라가 바로 열려요. 짧게 당기면 지금처럼 보관함이 나와요.'**
  String get pullCameraInfo;

  /// No description provided for @pullCameraMore.
  ///
  /// In ko, this message translates to:
  /// **'더 당기면 카메라'**
  String get pullCameraMore;

  /// No description provided for @pullCameraLetGo.
  ///
  /// In ko, this message translates to:
  /// **'놓으면 카메라가 열려요'**
  String get pullCameraLetGo;

  /// No description provided for @aiFriendName.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구'**
  String get aiFriendName;

  /// No description provided for @aiFriendPreview.
  ///
  /// In ko, this message translates to:
  /// **'폰 안의 AI와 이야기해요'**
  String get aiFriendPreview;

  /// No description provided for @aiFriendLock.
  ///
  /// In ko, this message translates to:
  /// **'이 폰 안에서만 대화해요 · 서버로 가지 않아요'**
  String get aiFriendLock;

  /// No description provided for @aiFriendHint.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구에게 메시지'**
  String get aiFriendHint;

  /// No description provided for @aiFriendHello.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요! 저는 부루미 AI 친구예요. 궁금한 걸 묻거나, 보낼 말을 같이 고민해 봐요. 우리 대화는 이 폰 밖으로 나가지 않아요.'**
  String get aiFriendHello;

  /// No description provided for @aiFriendIdea1.
  ///
  /// In ko, this message translates to:
  /// **'오늘 저녁 메뉴 추천해 줘'**
  String get aiFriendIdea1;

  /// No description provided for @aiFriendIdea2.
  ///
  /// In ko, this message translates to:
  /// **'친구 생일 축하 문구 써 줘'**
  String get aiFriendIdea2;

  /// No description provided for @aiFriendIdea3.
  ///
  /// In ko, this message translates to:
  /// **'주말에 뭐 하면 좋을까?'**
  String get aiFriendIdea3;

  /// No description provided for @aiFriendIdea4.
  ///
  /// In ko, this message translates to:
  /// **'이 말 영어로 바꿔 줘: 오늘 고마웠어'**
  String get aiFriendIdea4;

  /// No description provided for @aiFriendThinking.
  ///
  /// In ko, this message translates to:
  /// **'생각하는 중…'**
  String get aiFriendThinking;

  /// No description provided for @aiFriendFailed.
  ///
  /// In ko, this message translates to:
  /// **'지금은 답하지 못했어요. 잠시 후 다시 보내 주세요.'**
  String get aiFriendFailed;

  /// No description provided for @aiFriendNoAi.
  ///
  /// In ko, this message translates to:
  /// **'이 폰에는 AI가 없어서 AI 친구를 쓸 수 없어요. 아이폰은 Apple Intelligence, 안드로이드는 Gemini Nano가 있는 폰에서 돼요.'**
  String get aiFriendNoAi;

  /// No description provided for @aiFriendClear.
  ///
  /// In ko, this message translates to:
  /// **'대화 지우기'**
  String get aiFriendClear;

  /// No description provided for @aiFriendCleared.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구와의 대화를 지웠어요'**
  String get aiFriendCleared;

  /// No description provided for @aiFriendHide.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록에서 빼기'**
  String get aiFriendHide;

  /// No description provided for @aiFriendHidden.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구를 목록에서 뺐어요 · 설정 > 대화에서 다시 켤 수 있어요'**
  String get aiFriendHidden;

  /// No description provided for @aiFriendSwitch.
  ///
  /// In ko, this message translates to:
  /// **'대화 목록에 AI 친구 보이기'**
  String get aiFriendSwitch;

  /// No description provided for @aiFriendSwitchSub.
  ///
  /// In ko, this message translates to:
  /// **'폰 안의 AI만 써요'**
  String get aiFriendSwitchSub;

  /// No description provided for @aiFriendWrong.
  ///
  /// In ko, this message translates to:
  /// **'AI의 답은 틀릴 수 있어요'**
  String get aiFriendWrong;

  /// No description provided for @aiFriendCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get aiFriendCopy;

  /// No description provided for @aiFriendCopied.
  ///
  /// In ko, this message translates to:
  /// **'복사했어요'**
  String get aiFriendCopied;

  /// No description provided for @aiFriendShare.
  ///
  /// In ko, this message translates to:
  /// **'대화로 보내기'**
  String get aiFriendShare;

  /// No description provided for @aiFriendAsk.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구에게 묻기: {words}'**
  String aiFriendAsk(String words);

  /// No description provided for @shopTitle.
  ///
  /// In ko, this message translates to:
  /// **'스티커 가게'**
  String get shopTitle;

  /// No description provided for @shopFree.
  ///
  /// In ko, this message translates to:
  /// **'무료 스티커'**
  String get shopFree;

  /// No description provided for @shopFreeInfo.
  ///
  /// In ko, this message translates to:
  /// **'부루미가 직접 그린 스티커예요. 추가하면 스티커 창에 바로 생겨요.'**
  String get shopFreeInfo;

  /// No description provided for @shopPaid.
  ///
  /// In ko, this message translates to:
  /// **'유료 스티커'**
  String get shopPaid;

  /// No description provided for @shopSoon.
  ///
  /// In ko, this message translates to:
  /// **'곧 열려요'**
  String get shopSoon;

  /// No description provided for @shopPaidInfo.
  ///
  /// In ko, this message translates to:
  /// **'작가 스티커와 특별 팩은 결제가 열리면 여기서 살 수 있어요. 브랜드 광고 스티커는 팔지 않아요. 부루미는 광고를 넣지 않아요.'**
  String get shopPaidInfo;

  /// No description provided for @shopFreeTag.
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get shopFreeTag;

  /// No description provided for @shopMovingN.
  ///
  /// In ko, this message translates to:
  /// **'움직이는 스티커 {n}개'**
  String shopMovingN(int n);

  /// No description provided for @shopBy.
  ///
  /// In ko, this message translates to:
  /// **'부루미'**
  String get shopBy;

  /// No description provided for @shopAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가하기'**
  String get shopAdd;

  /// No description provided for @shopAdded.
  ///
  /// In ko, this message translates to:
  /// **'추가됨'**
  String get shopAdded;

  /// No description provided for @shopRemove.
  ///
  /// In ko, this message translates to:
  /// **'빼기'**
  String get shopRemove;

  /// No description provided for @shopPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'어떤 스티커를 받는지 서버에 알리지 않아요. 인기 순위도 폰에서 정해요.'**
  String get shopPrivacy;

  /// No description provided for @shopNew.
  ///
  /// In ko, this message translates to:
  /// **'새로 나왔어요'**
  String get shopNew;

  /// No description provided for @shopOpen.
  ///
  /// In ko, this message translates to:
  /// **'스티커 가게'**
  String get shopOpen;

  /// No description provided for @searchFeatures.
  ///
  /// In ko, this message translates to:
  /// **'기능 · 설정'**
  String get searchFeatures;

  /// No description provided for @searchChannelPosts.
  ///
  /// In ko, this message translates to:
  /// **'구독 채널 글'**
  String get searchChannelPosts;

  /// No description provided for @searchStickers.
  ///
  /// In ko, this message translates to:
  /// **'스티커'**
  String get searchStickers;

  /// No description provided for @searchAllPosts.
  ///
  /// In ko, this message translates to:
  /// **'글 모두 보기'**
  String get searchAllPosts;

  /// No description provided for @shopPackInfo.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 · {moving}개는 움직여요'**
  String shopPackInfo(int count, int moving);

  /// No description provided for @shopSeenTitle.
  ///
  /// In ko, this message translates to:
  /// **'대화에서 본 묶음'**
  String get shopSeenTitle;

  /// No description provided for @aiFriendMore.
  ///
  /// In ko, this message translates to:
  /// **'더 보기'**
  String get aiFriendMore;

  /// No description provided for @searchFeatAiFriend.
  ///
  /// In ko, this message translates to:
  /// **'AI 친구'**
  String get searchFeatAiFriend;

  /// No description provided for @searchFeatMemories.
  ///
  /// In ko, this message translates to:
  /// **'1년 전 오늘'**
  String get searchFeatMemories;

  /// No description provided for @searchFeatBestFriend.
  ///
  /// In ko, this message translates to:
  /// **'제일 친한 친구 표시'**
  String get searchFeatBestFriend;

  /// No description provided for @searchFeatLock.
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금 · 비밀번호'**
  String get searchFeatLock;

  /// No description provided for @searchFeatPullCamera.
  ///
  /// In ko, this message translates to:
  /// **'아래로 당겨 카메라 열기'**
  String get searchFeatPullCamera;

  /// No description provided for @dmInboxAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get dmInboxAll;

  /// No description provided for @dmInboxAllInfo.
  ///
  /// In ko, this message translates to:
  /// **'이 채널로 온 메시지를 모두 모아 봐요. 누르면 그 사람과의 대화로 가요.'**
  String get dmInboxAllInfo;

  /// No description provided for @accountSuspendedEdit.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람의 메시지를 고치려는 시도가 있어서 계정이 정지됐어요. 부루미 앱에서는 할 수 없는 일이라, 고친 앱이나 프로그램을 쓴 것으로 보여요. 잘못된 정지라면 이의 신청을 보내 주세요.'**
  String get accountSuspendedEdit;

  /// No description provided for @appealButton.
  ///
  /// In ko, this message translates to:
  /// **'이의 신청'**
  String get appealButton;

  /// No description provided for @appealHint.
  ///
  /// In ko, this message translates to:
  /// **'무슨 일이 있었는지 적어 주세요'**
  String get appealHint;

  /// No description provided for @appealInfo.
  ///
  /// In ko, this message translates to:
  /// **'운영팀만 읽어요. 대화 내용은 운영팀에게도 보이지 않아요. 한 번에 하나만 보낼 수 있어요.'**
  String get appealInfo;

  /// No description provided for @appealSent.
  ///
  /// In ko, this message translates to:
  /// **'이의 신청을 보냈어요. 운영팀이 읽고 정지를 풀지 정해요.'**
  String get appealSent;

  /// No description provided for @appealWaiting.
  ///
  /// In ko, this message translates to:
  /// **'이의 신청을 기다리는 중이에요. 운영팀이 정지를 풀면 바로 다시 쓸 수 있어요.'**
  String get appealWaiting;

  /// No description provided for @appealDenied.
  ///
  /// In ko, this message translates to:
  /// **'운영팀이 정지를 그대로 두기로 했어요. {date}부터 다시 신청할 수 있어요.'**
  String appealDenied(String date);

  /// No description provided for @suspendUntil.
  ///
  /// In ko, this message translates to:
  /// **'{date}까지 정지'**
  String suspendUntil(String date);

  /// No description provided for @suspendUntilLifted.
  ///
  /// In ko, this message translates to:
  /// **'운영팀이 풀 때까지 정지'**
  String get suspendUntilLifted;

  /// No description provided for @suspendReasonEdit.
  ///
  /// In ko, this message translates to:
  /// **'다른 사람의 메시지를 고치려는 시도'**
  String get suspendReasonEdit;

  /// No description provided for @suspendReasonApp.
  ///
  /// In ko, this message translates to:
  /// **'고친 앱이나 프로그램으로 규칙을 어기려는 시도 여러 번'**
  String get suspendReasonApp;

  /// No description provided for @notSuspended.
  ///
  /// In ko, this message translates to:
  /// **'지금은 정지되어 있지 않아요.'**
  String get notSuspended;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'ko':
      return LKo();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
