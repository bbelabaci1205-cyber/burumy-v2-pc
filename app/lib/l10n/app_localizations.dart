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
  L(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ko')];

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
  /// **'1:1 대화에서 둘 다 3일 넘게 매일 메시지를 보내면 이름 옆에 불꽃이 생겨요. 계산은 휴대폰 안에서만 해요.'**
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
  /// **'받는 사람이 한 번만 볼 수 있어요'**
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
  /// **'오픈소스 라이선스'**
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
  /// **'모든 대화방 가리기'**
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
  /// **'끄면 사진을 누를 때 받아요. 절전 모드에서는 늘 누를 때 받아요.'**
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
  /// **'규칙은 들어오기 전에도 보여요. 비밀 내용은 쓰지 마세요.'**
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
  /// **'새 멤버가 처음 들어왔을 때 한 번 보여요.'**
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
  /// **'비상 시 삭제'**
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
  /// **'누르고 있는 동안만 메시지가 보여요'**
  String get veilAllSub;

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
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ko'].contains(locale.languageCode);

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
