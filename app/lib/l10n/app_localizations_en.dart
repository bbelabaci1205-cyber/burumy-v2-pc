// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Burumy';

  @override
  String get tabChats => 'Chats';

  @override
  String get tabContacts => 'Contacts';

  @override
  String get tabSettings => 'Settings';

  @override
  String get signUpTitle => 'Start with an ID';

  @override
  String get signUpId => 'ID';

  @override
  String get signUpPassword => 'Password';

  @override
  String get signUpInvite => 'Invite code';

  @override
  String get signUpButton => 'Sign Up';

  @override
  String get logInButton => 'Log In';

  @override
  String get recoveryKeyTitle => 'Chat Recovery Key';

  @override
  String get recoveryKeyBody => 'You need this to open old chats on a new phone. Write it down somewhere safe.';

  @override
  String get chatsEmpty => 'No chats yet';

  @override
  String get messageLocked => 'This message can\'t be opened yet';

  @override
  String get sendFailedNoEncryption => 'Can\'t send to a chat that isn\'t encrypted';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeBlue => 'Blue';

  @override
  String get language => 'Language';

  @override
  String get signUpSub => 'All you need is an ID and a password. No phone number.';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get noAccount => 'Create a new account';

  @override
  String get logInTitle => 'Welcome back';

  @override
  String get fieldRequired => 'Enter your ID and password';

  @override
  String get passwordRule => 'Use 8 or more characters with letters and numbers';

  @override
  String get somethingWrong => 'Something went wrong. Try again in a moment.';

  @override
  String get newChat => 'New Chat';

  @override
  String get newChatHint => 'Their ID';

  @override
  String get start => 'Start';

  @override
  String get cancel => 'Cancel';

  @override
  String get messageHint => 'Message';

  @override
  String get encryptedNotice => 'This chat is end-to-end encrypted. Not even Burumy can read it.';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get voice => 'Voice Message';

  @override
  String get file => 'File';

  @override
  String get you => 'You';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get settingsLook => 'Appearance';

  @override
  String get settingsColor => 'Color';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageAuto => 'Same as Phone';

  @override
  String get languageKo => '한국어';

  @override
  String get languageEn => 'English';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get makeRecoveryKey => 'Create Chat Recovery Key';

  @override
  String get copied => 'Copied';

  @override
  String get logOut => 'Log Out';

  @override
  String get myId => 'My ID';

  @override
  String get contactsEmpty => 'No contacts yet';

  @override
  String get done => 'Done';

  @override
  String get searchById => 'Search by ID';

  @override
  String get contactsSection => 'My Contacts';

  @override
  String get searchResults => 'People Found';

  @override
  String get noOneFound => 'No one found';

  @override
  String get attachPhoto => 'Photo or Video';

  @override
  String get attachFile => 'File';

  @override
  String get sending => 'Sending';

  @override
  String get read => 'Read';

  @override
  String get enterRecoveryKey => 'Enter Chat Recovery Key';

  @override
  String get enterRecoveryKeyBody => 'Enter the Chat Recovery Key from your old phone to open your old chats.';

  @override
  String get recoveryKeyHint => '12 words';

  @override
  String get recoveryDone => 'Your old chats are open';

  @override
  String get recoveryWrong => 'That key doesn\'t match. Please check it again.';

  @override
  String get recoveryOn => 'On';

  @override
  String get open => 'Open';

  @override
  String get newGroup => 'New Group';

  @override
  String get newChannel => 'New Channel';

  @override
  String get addMembers => 'Add Members';

  @override
  String get next => 'Next';

  @override
  String get groupName => 'Group Name';

  @override
  String get channelName => 'Channel Name';

  @override
  String get create => 'Create';

  @override
  String get channelInfo => 'In a channel only you can post. Subscribers can read.';

  @override
  String get groupInfo => 'Group chats are end-to-end encrypted too.';

  @override
  String get channelReadOnly => 'Only the channel owner can post';

  @override
  String get reply => 'Reply';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get delete => 'Delete';

  @override
  String get editing => 'Edit Message';

  @override
  String get edited => 'edited';

  @override
  String get typing => 'typing…';

  @override
  String get deleted => 'Message deleted';

  @override
  String get undo => 'Undo';

  @override
  String get channel => 'Channel';

  @override
  String get group => 'Group';

  @override
  String get orById => 'Or start a 1:1 chat by ID';

  @override
  String get lockTitle => 'Enter your password';

  @override
  String get lockWrong => 'Wrong password';

  @override
  String get appLock => 'App Lock';

  @override
  String get appLockOff => 'Off';

  @override
  String get appLockOn => 'On';

  @override
  String get setPassword => 'Set Password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Once more';

  @override
  String get passwordMismatch => 'The passwords don\'t match';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get hidePassword => 'Hide Password';

  @override
  String get deletePassword => 'Delete Password';

  @override
  String get hidePasswordInfo =>
      'Opening with this password hides the chosen people and chats from every list. They stay hidden after you open with your normal password.';

  @override
  String get deletePasswordInfo =>
      'Opening with this password erases the chosen people and chats. 1:1 chats are quietly erased on the friend\'s side too, and groups and channels are left quietly over a few days. Nobody is notified. This can\'t be undone.';

  @override
  String get hideList => 'People & Chats to Hide';

  @override
  String get deleteList => 'People & Chats to Erase';

  @override
  String get notSet => 'None';

  @override
  String get removePassword => 'Remove Password';

  @override
  String get save => 'Save';

  @override
  String get releaseHidden => 'Show Hidden People Again';

  @override
  String get releaseHiddenDone => 'Visible again';

  @override
  String get passwordUsed => 'Same as another password';

  @override
  String chooseCount(int count) {
    return '$count chosen';
  }

  @override
  String get enterToManage => 'Enter your normal password to change lock settings';

  @override
  String get streaks => 'Streaks';

  @override
  String get streakInfo =>
      'When you both message each other every day for 3+ days in a 1:1 chat, a flame shows next to the name. Worked out on your phone only.';

  @override
  String get sticker => 'Sticker';

  @override
  String get stickers => 'Stickers';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get pinnedMessage => 'Pinned Message';

  @override
  String get timer => 'Auto-Delete';

  @override
  String get timerOff => 'Off';

  @override
  String get timer1d => '1 day';

  @override
  String get timer1w => '1 week';

  @override
  String get timer1m => '1 month';

  @override
  String timerLine(String duration) {
    return 'Auto-delete: $duration';
  }

  @override
  String get timerOffLine => 'Auto-delete turned off';

  @override
  String get timerInfo => 'New messages in this chat are deleted for everyone after the time you choose.';

  @override
  String get attachOnce => 'View Once Photo';

  @override
  String get viewOncePhoto => 'View once photo';

  @override
  String get viewOnceTap => 'Tap to open';

  @override
  String get viewOnceOpened => 'Opened';

  @override
  String get viewOnceOpenedLine => 'View once photo was opened';

  @override
  String get viewOnceInfo => 'You can\'t see it again after closing';

  @override
  String get profile => 'Profile';

  @override
  String get name => 'Name';

  @override
  String get changePhoto => 'Change Photo';

  @override
  String get photoServerNote =>
      'With \'Everyone\' your photo is kept on the server. With \'My contacts\' it never goes to the server and reaches friends only inside your encrypted 1:1 chats.';

  @override
  String get chatInfo => 'Info';

  @override
  String get members => 'Members';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get owner => 'Owner';

  @override
  String get admin => 'Admin';

  @override
  String get leaveChat => 'Leave Chat';

  @override
  String get leaveChannel => 'Leave Channel';

  @override
  String leavingIn(int seconds) {
    return 'Leaving in ${seconds}s';
  }

  @override
  String get chatPin => 'Pin';

  @override
  String get chatUnpin => 'Unpin';

  @override
  String get chatMute => 'Mute';

  @override
  String get chatUnmute => 'Unmute';

  @override
  String get chatArchive => 'Archive';

  @override
  String get chatUnarchive => 'Unarchive';

  @override
  String get archive => 'Archived Chats';

  @override
  String get archiveEmpty => 'No archived chats';

  @override
  String get archiveFooter => 'Archived chats are kept on this phone only. The server doesn\'t know which chats you archived.';

  @override
  String get searchChats => 'Search';

  @override
  String get searchNone => 'No matching chats';

  @override
  String get forward => 'Forward';

  @override
  String get forwarded => 'Forwarded';

  @override
  String get forwardTo => 'Forward to';

  @override
  String get forwardDone => 'Forwarded';

  @override
  String get forwardFailed => 'You can\'t send to this chat';

  @override
  String get searchInChat => 'Search';

  @override
  String searchCount(int n, int total) {
    return '$n of $total';
  }

  @override
  String get searchNoHits => 'No results';

  @override
  String get linkPreviews => 'Link Previews';

  @override
  String get linkPreviewInfo =>
      'When you send a link, your phone reads the page title and picture and puts them, encrypted, into the message. People who get it don\'t contact the site.';

  @override
  String get voiceHoldHint => 'Hold to record a voice message';

  @override
  String get voiceNoMic => 'Please allow microphone access';

  @override
  String get voiceSlideCancel => '‹ Slide to cancel';

  @override
  String get voiceReleaseCancel => 'Release to cancel';

  @override
  String get poll => 'Poll';

  @override
  String get attachPoll => 'Poll';

  @override
  String get newPoll => 'New Poll';

  @override
  String get pollQuestion => 'Question';

  @override
  String get pollOptions => 'Options';

  @override
  String get pollOption => 'Option';

  @override
  String get pollAddOption => 'Add an Option';

  @override
  String get pollAnonymous => 'Anonymous Voting';

  @override
  String get pollMultiple => 'Multiple Answers';

  @override
  String get pollMultipleShort => 'multiple';

  @override
  String get pollAnonInfo => 'Other members can\'t see who chose what. Votes go, encrypted, only to the maker\'s phone; the chat gets just the numbers.';

  @override
  String get pollOpenInfo => 'Everyone in the chat can see who chose what.';

  @override
  String get pollChannelInfo => 'Channel polls are always anonymous, so subscribers stay hidden.';

  @override
  String get pollCreate => 'Create';

  @override
  String pollVoters(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n votes', one: '1 vote');
    return '$_temp0';
  }

  @override
  String get pollNoVotes => 'No votes yet';

  @override
  String get pollOpenKind => 'Public Poll';

  @override
  String get pollAnonKind => 'Anonymous Poll';

  @override
  String get pollClosedKind => 'Final Results';

  @override
  String get pollVote => 'Vote';

  @override
  String get pollClose => 'Stop Poll';

  @override
  String get pollRetract => 'Retract Vote';

  @override
  String get attachBubble => 'Bubble';

  @override
  String get bubbleSendTitle => 'Send a Bubble';

  @override
  String bubbleSendInfo(String name) {
    return 'A bubble floats on $name\'s home screen. What\'s inside stays hidden; popping it opens it once.';
  }

  @override
  String get bubbleRecord => 'Record';

  @override
  String bubblesWaiting(int n) {
    String _temp0 = intl.Intl.pluralLogic(n, locale: localeName, other: '$n bubbles', one: '1 bubble');
    return '$_temp0';
  }

  @override
  String get bubbleTapToPop => 'Tap to pop';

  @override
  String get bubbleSent => 'Bubble sent';

  @override
  String get bubblePopped => 'Popped';

  @override
  String get bubbleOnce => 'You can see this once. It\'s gone when you close it.';

  @override
  String get bubbleGone => 'This bubble has already popped';

  @override
  String get callVoice => 'Voice Call';

  @override
  String get callVideo => 'Video Call';

  @override
  String get callCalling => 'Calling…';

  @override
  String get callConnecting => 'Connecting…';

  @override
  String get callEnded => 'Call Ended';

  @override
  String get callNoAnswer => 'No answer';

  @override
  String get callDeclined => 'Declined';

  @override
  String get callBusy => 'Busy on another call';

  @override
  String get callFailed => 'Couldn\'t connect';

  @override
  String get callAccept => 'Accept';

  @override
  String get callDecline => 'Decline';

  @override
  String get callEnd => 'End';

  @override
  String get callMute => 'Mute';

  @override
  String get callSpeaker => 'Speaker';

  @override
  String get callCamera => 'Camera';

  @override
  String get callFlip => 'Flip';

  @override
  String get callE2ee => 'End-to-end encrypted';

  @override
  String get callLineOut => 'Outgoing Call';

  @override
  String get callLineIn => 'Incoming Call';

  @override
  String get callLineMissed => 'Missed Call';

  @override
  String get callLineDeclined => 'Declined Call';

  @override
  String get callLineCancelled => 'Cancelled Call';

  @override
  String get callLineNow => 'Ongoing Call';

  @override
  String get callNotSetUp => 'Calls aren\'t available in this build yet';

  @override
  String get callBack => 'Call Back';

  @override
  String get callPreview => 'Call';

  @override
  String get noticeNew => 'New message';

  @override
  String get noticeTextHidden => 'Hide Text in Notifications';

  @override
  String get noticeTextHiddenInfo =>
      'When on, notifications only say \'New message\', without chat name or text. Notification text is only opened on this phone.';

  @override
  String get noticeChannel => 'Messages';

  @override
  String get wipeAfter => 'Erase After Wrong Tries';

  @override
  String get wipeAfterInfo =>
      'After this many wrong passwords in a row, every chat on this phone is erased. 1:1 chats are erased on the friend\'s phone too, and groups and channels are left quietly over a few days.';

  @override
  String wipeTimes(int n) {
    return '$n tries';
  }

  @override
  String wipeWarning(int n) {
    return '$n more wrong tries erase every chat';
  }

  @override
  String get deleteForBoth => 'Delete for Both';

  @override
  String get deleteForBothInfo => 'This chat is deleted on your phone and your friend\'s phone.';

  @override
  String deletingIn(int seconds) {
    return 'Deleting in ${seconds}s';
  }

  @override
  String erasedByFriend(String name) {
    return 'A friend deleted your chat for both · $name';
  }

  @override
  String get editorReset => 'Reset';

  @override
  String get editorCrop => 'Crop';

  @override
  String get editorFilters => 'Filters';

  @override
  String get editorAdjust => 'Adjust';

  @override
  String get filterNone => 'Original';

  @override
  String get filterVivid => 'Vivid';

  @override
  String get filterWarm => 'Warm';

  @override
  String get filterCool => 'Cool';

  @override
  String get filterDramatic => 'Dramatic';

  @override
  String get filterMono => 'Mono';

  @override
  String get filterSilver => 'Silver';

  @override
  String get filterNoir => 'Noir';

  @override
  String get filterFade => 'Faded';

  @override
  String get filterFilm => 'Film';

  @override
  String get adjExposure => 'Exposure';

  @override
  String get adjBrilliance => 'Brilliance';

  @override
  String get adjHighlights => 'Highlights';

  @override
  String get adjShadows => 'Shadows';

  @override
  String get adjContrast => 'Contrast';

  @override
  String get adjBrightness => 'Brightness';

  @override
  String get adjBlackPoint => 'Black Point';

  @override
  String get adjSaturation => 'Saturation';

  @override
  String get adjVibrance => 'Vibrance';

  @override
  String get adjWarmth => 'Warmth';

  @override
  String get adjTint => 'Tint';

  @override
  String get adjFade => 'Fade';

  @override
  String get adjVignette => 'Vignette';

  @override
  String inviteFrom(String name) {
    return 'Invited by $name';
  }

  @override
  String get inviteAccept => 'Join';

  @override
  String get inviteDecline => 'Decline';

  @override
  String get callWaiting => 'Call waiting';

  @override
  String get callWaitingVideo => 'Video call waiting';

  @override
  String get callWaitingTitle => 'Calls during a call';

  @override
  String get callWaitingWait => 'Call waiting';

  @override
  String get callWaitingMissed => 'Missed call';

  @override
  String get callWaitingBusy => 'Say I\'m busy';

  @override
  String get callWaitingInfo =>
      'Call waiting: the caller hears it ring and you can answer it. Missed call: nothing shows during your call and it becomes a missed call. Say I\'m busy: the caller sees you are on a call.';

  @override
  String get tabCalls => 'Calls';

  @override
  String get callsAll => 'All';

  @override
  String get callsMissed => 'Missed';

  @override
  String get callsEmpty => 'No calls yet';

  @override
  String get callsEmptyMissed => 'No missed calls';

  @override
  String get callsNew => 'New call';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsChatsPage => 'Chats';

  @override
  String get settingsPrivacy => 'Privacy and Security';

  @override
  String get privacyInfo => 'Manage app lock, hide and delete passwords and your chat recovery key.';

  @override
  String get contactsAddById => 'Add a friend by ID';

  @override
  String get contactsInvite => 'Invite friends';

  @override
  String inviteText(String id) {
    return 'Chat with me on Burumy. My ID is $id.';
  }

  @override
  String get inviteCopied => 'Invite copied. Paste it to a friend.';

  @override
  String get chatsMenuArchive => 'Archive';

  @override
  String get sortByName => 'By name';

  @override
  String get sortByRecent => 'Recent chats first';

  @override
  String get colorTheme => 'Colour theme';

  @override
  String get nightMode => 'Night mode';

  @override
  String get nightSystem => 'Same as phone';

  @override
  String get nightLight => 'Off';

  @override
  String get nightDark => 'On';

  @override
  String get textSize => 'Text size';

  @override
  String get bubbleCorners => 'Message corners';

  @override
  String get bubbleSample => 'Hello! 👋';

  @override
  String get stickersEmoji => 'Stickers and emoji';

  @override
  String get doubleTapInfo => 'Double-tap a message to add this reaction.';

  @override
  String get quickReaction => 'Quick reaction';

  @override
  String get doubleTapReact => 'Double-tap to react';

  @override
  String get powerSaving => 'Power saving';

  @override
  String get powerSavingInfo => 'Save battery by turning down motion effects.';

  @override
  String get uiEffects => 'Interface effects';

  @override
  String get uiEffectsInfo => 'When off, screens change without animation.';

  @override
  String get messageNotices => 'Message notifications';

  @override
  String get notifyDirect => 'Private chats';

  @override
  String get notifyGroup => 'Groups';

  @override
  String get notifyChannel => 'Channels';

  @override
  String get resetNotices => 'Reset all notification settings';

  @override
  String get enterSends => 'Send with Enter';

  @override
  String get swipeReply => 'Swipe left to reply';

  @override
  String get dataStorage => 'Data and storage';

  @override
  String get whoEveryone => 'Everybody';

  @override
  String get whoContacts => 'My contacts';

  @override
  String get whoNobody => 'Nobody';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get defaultTimer => 'Auto-delete messages';

  @override
  String get defaultTimerInfo => 'New chats you start will delete messages for everyone after this time.';

  @override
  String get privacyWho => 'Privacy';

  @override
  String get whoInfo => 'Calls from others become missed calls; their messages and invitations stay hidden.';

  @override
  String get whoCalls => 'Calls';

  @override
  String get whoMessages => 'Messages';

  @override
  String get whoInvites => 'Group and channel invites';

  @override
  String get readTypingInfo => 'When off, others do not see when you read or type.';

  @override
  String get sendRead => 'Send read receipts';

  @override
  String get sendTyping => 'Send typing indicator';

  @override
  String get devices => 'Devices';

  @override
  String get encryptionKeys => 'Encryption keys';

  @override
  String get blockedInfo => 'Blocked people cannot reach you with messages or invites. They are not told.';

  @override
  String get blockSomeone => 'Block someone';

  @override
  String get unblock => 'Unblock';

  @override
  String get blockFailed => 'Could not block. Check the ID.';

  @override
  String get userIdHint => 'ID';

  @override
  String get deviceVerified => 'Verified';

  @override
  String get deviceNotVerified => 'Not verified yet';

  @override
  String get thisDevice => 'This device';

  @override
  String get logOutOthers => 'Log out all other devices';

  @override
  String get otherDevices => 'Other devices';

  @override
  String get passwordAgainInfo => 'For safety, enter your account password again.';

  @override
  String get keysInfo => 'Compare these keys in person to make sure no one is in the middle. Tap to copy.';

  @override
  String get myIdentityKey => 'My identity key';

  @override
  String get thisDeviceKey => 'This device key';

  @override
  String get savedMessages => 'Saved messages';

  @override
  String get chatBackup => 'Chat backup';

  @override
  String get editShort => 'Edit';

  @override
  String get idLabel => 'ID';

  @override
  String get blockUser => 'Block user';

  @override
  String get veilDots => 'Hide chat';

  @override
  String get veilDotsInfo => 'Messages in this chat are covered with sparkling dots and show only while you hold them. Tap once to open the menu.';

  @override
  String get readHere => 'Read receipts in this chat';

  @override
  String get veilBlur => 'Sensitive chat';

  @override
  String get veilBlurInfo => 'A sensitive chat sits under frosted glass and is clear only while your finger rests on it, so people nearby can\'t read it.';

  @override
  String get tabMedia => 'Media';

  @override
  String get tabFiles => 'Files';

  @override
  String get tabLinks => 'Links';

  @override
  String get nothingShared => 'Nothing yet';

  @override
  String get bio => 'Bio';

  @override
  String get bioInfo => 'Choose who sees it in Settings > Privacy and Security. Up to 70 characters.';

  @override
  String get markRead => 'Read';

  @override
  String get hideFromList => 'Hide from list';

  @override
  String get hiddenChats => 'Hidden chats';

  @override
  String get hiddenChatsInfo => 'Chats you hid from the list. Messages and notifications still arrive. Tap one to show it again.';

  @override
  String get showInList => 'Show in list';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterPeople => 'Contacts';

  @override
  String get filterGroups => 'Groups';

  @override
  String get filterChannels => 'Channels';

  @override
  String get filterBots => 'Bots';

  @override
  String get myFolders => 'My folders';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get folderKinds => 'Include chats';

  @override
  String get folderInfo =>
      'Every chat of the kinds you pick goes in. You can also add or leave out chats one by one below. Folders are saved on this device only.';

  @override
  String get folderChats => 'Pick chats';

  @override
  String get deleteFolder => 'Delete folder';

  @override
  String get listTop => 'Show search and folders on top';

  @override
  String get listTopInfo => 'Off gives the chat list more room. Search and folders are in the menu at the top left.';

  @override
  String get saveToSaved => 'Save to Saved Messages';

  @override
  String get savedDone => 'Saved to Saved Messages';

  @override
  String get sendQuietly => 'Send without sound';

  @override
  String get sendLater => 'Schedule message';

  @override
  String get scheduleSend => 'Send at this time';

  @override
  String get scheduledDone => 'Scheduled';

  @override
  String scheduledCount(int count) {
    return '$count scheduled';
  }

  @override
  String get scheduledInfo => 'Scheduled messages wait on this phone, encrypted. They go at the set time if the app is open, or the next time you open it.';

  @override
  String get sendNow => 'Send now';

  @override
  String get fmtBold => 'Bold';

  @override
  String get fmtItalic => 'Italic';

  @override
  String get fmtUnderline => 'Underline';

  @override
  String get fmtStrike => 'Strikethrough';

  @override
  String get fmtCode => 'Monospace';

  @override
  String get fmtSpoiler => 'Spoiler';

  @override
  String get fmtLink => 'Link';

  @override
  String get more => 'More';

  @override
  String get contactEdit => 'Edit contact';

  @override
  String get contactNameInfo => 'Only you see this name, on this phone. They won\'t know.';

  @override
  String get memo => 'Note';

  @override
  String get memoHint => 'Something to remember about them';

  @override
  String get memoInfo => 'Notes stay on this phone too.';

  @override
  String get clearChat => 'Clear messages';

  @override
  String get clearChatInfo => 'Cleared only on your screen. Theirs stays as it is.';

  @override
  String get clearChatDone => 'Messages cleared';

  @override
  String get send => 'Send';

  @override
  String get attachGallery => 'Gallery';

  @override
  String get attachCamera => 'Camera';

  @override
  String get attachLibrary => 'Choose photos';

  @override
  String get attachPickFile => 'Choose files';

  @override
  String get attachFileInfo => 'Photos can go as original files too. Up to 20 at a time.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get onceOnInfo => 'They can view it only once';

  @override
  String get onceNoCaption => 'View-once media has no caption';

  @override
  String get captionHint => 'Add a caption';

  @override
  String get checklist => 'Checklist';

  @override
  String get newChecklist => 'New checklist';

  @override
  String get checklistTitle => 'Title';

  @override
  String get checklistTitleHint => 'What needs doing?';

  @override
  String get checklistItems => 'Tasks';

  @override
  String checklistItemsInfo(int count) {
    return 'Up to $count tasks.';
  }

  @override
  String get checklistItemHint => 'Task';

  @override
  String get checklistAddItem => 'Add a task';

  @override
  String get checklistOthersMark => 'Others can mark tasks done';

  @override
  String get checklistOthersAdd => 'Others can add tasks';

  @override
  String get checklistOthersInfo => 'Checklists are encrypted like messages. Ticks or tasks from people you didn\'t allow are ignored on every phone.';

  @override
  String checklistDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get meetup => 'Event';

  @override
  String get newMeetup => 'New event';

  @override
  String get meetupTitleHint => 'What\'s happening?';

  @override
  String get meetupPlaceHint => 'Place (optional)';

  @override
  String get meetupWhen => 'When';

  @override
  String get meetupInfo => 'Events and answers are encrypted like messages. The server never knows who\'s coming.';

  @override
  String get meetupYes => 'Going';

  @override
  String get meetupMaybe => 'Maybe';

  @override
  String get meetupNo => 'Can\'t go';

  @override
  String get meetupCancel => 'Cancel event';

  @override
  String get meetupCancelled => 'This event was cancelled';

  @override
  String get meetupPast => 'This event has passed';

  @override
  String get contactCard => 'Contact';

  @override
  String get pickContact => 'Share a contact';

  @override
  String get noContacts => 'No contacts yet';

  @override
  String get contactMessage => 'Message';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get removeSubscriber => 'Remove subscriber';

  @override
  String get removeMember => 'Remove from group';

  @override
  String subscribersCount(int count) {
    return '$count subscribers';
  }

  @override
  String get subscribers => 'Subscribers';

  @override
  String get hideMembersOnInfo => 'Only admins see the member list.';

  @override
  String get subscribersHiddenInfo => 'Only admins can see subscribers. Other subscribers never know who follows.';

  @override
  String get editGroup => 'Edit group';

  @override
  String get editChannel => 'Edit channel';

  @override
  String get aboutHint => 'Description (optional)';

  @override
  String get signPosts => 'Sign posts';

  @override
  String get signPostsInfo => 'When on, the admin\'s name shows on each post.';

  @override
  String get hideMembers => 'Hide member list';

  @override
  String get hideMembersInfo => 'When on, only admins can see who is in the group.';

  @override
  String get add => 'Add';

  @override
  String get openLinkAsk => 'Open this link?';

  @override
  String get openLink => 'Open';

  @override
  String get location => 'Location';

  @override
  String get locationSend => 'Send my current location';

  @override
  String get locationFinding => 'Finding where you are';

  @override
  String locationAccuracy(int meters) {
    return 'Accurate to about $meters m';
  }

  @override
  String get locationDenied => 'Location access is off. Allow Burumy to use your location in Settings.';

  @override
  String get locationOff => 'Location services are turned off on this phone.';

  @override
  String get locationUnavailable => 'Your location can\'t be found right now. Try again in a moment.';

  @override
  String get locationRetry => 'Try again';

  @override
  String get openPhoneSettings => 'Open Settings';

  @override
  String get locationOpenMap => 'Open in Maps';

  @override
  String get locationPrivacy =>
      'Your location is read once, at the moment you send it. It is encrypted, only people in this chat see it, and no map company gets it.';

  @override
  String get attachAllPhotos => 'All photos';

  @override
  String get photosDenied => 'Photo access is off';

  @override
  String settingsProfileSub(String id) {
    return '$id · Profile, photo, name';
  }

  @override
  String securityCheck(int done, int total) {
    return 'Security check $done/$total';
  }

  @override
  String get securityAllDone => 'All done. Your account is well protected.';

  @override
  String securityLeft(int n) {
    return '$n left. Tap to finish.';
  }

  @override
  String get securityCheckTitle => 'Security check';

  @override
  String get securityCheckInfo => 'Do these two things and your chats stay safe even if you lose or change your phone.';

  @override
  String get checkRecovery => 'Make a chat recovery key';

  @override
  String get checkRecoveryInfo => 'Use it to open your old chats on a new phone. If you lose it, nobody can bring them back.';

  @override
  String get checkDevice => 'Confirm this device';

  @override
  String get checkDeviceInfo => 'Confirming this device is yours lets friends chat with you safely.';

  @override
  String get checkDone => 'Done';

  @override
  String get checkTodo => 'To do';

  @override
  String get stateOn => 'On';

  @override
  String get stateOff => 'Off';

  @override
  String get accountManage => 'Account';

  @override
  String get accountManageInfo => 'Your ID, password, signed-in devices and encryption keys in one place.';

  @override
  String get faq => 'FAQ';

  @override
  String get featureTour => 'What Burumy can do';

  @override
  String get featureTourInfo => 'Everything you can do in Burumy at a glance.';

  @override
  String get aboutApp => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get aboutInfo => 'Burumy is a messenger where nobody can read your chats. Not the operator, not the server.';

  @override
  String get powerMode => 'Power saving mode';

  @override
  String powerBelowValue(int pct) {
    return 'Below $pct%';
  }

  @override
  String get powerAlways => 'Always';

  @override
  String get powerNever => 'Off';

  @override
  String get powerModeInfo => 'When the battery is below this level, moving effects pause. The web can\'t read the battery, so only \'Always\' works there.';

  @override
  String get faqQ1 => 'Are my chats really safe?';

  @override
  String get faqA1 => 'All 1:1 and group chats are end-to-end encrypted. The server and the operator can\'t read them.';

  @override
  String get faqQ2 => 'Can I sign up without a phone number?';

  @override
  String get faqA2 => 'Yes. You only need an ID and a password. We don\'t use phone numbers or contacts.';

  @override
  String get faqQ3 => 'Will I lose my chats if I change phones?';

  @override
  String get faqA3 =>
      'Make a chat recovery key and you can open your old chats on a new phone. Only you have the key, so if you lose it nobody can bring them back.';

  @override
  String get faqQ4 => 'Who can find me?';

  @override
  String get faqA4 => 'Only people who know your ID. Nobody can find you by name or phone number.';

  @override
  String get faqQ5 => 'How do I turn on disappearing messages?';

  @override
  String get faqA5 => 'Tap the timer button at the top of a chat and pick a time. Messages sent after that disappear when the time is up.';

  @override
  String get faqQ6 => 'What is a bubble?';

  @override
  String get faqA6 => 'A photo that disappears once it\'s opened. The home-screen widget shows only the bubble, never the content.';

  @override
  String get faqQ7 => 'Can I lock the app?';

  @override
  String get faqA7 => 'Set a password in Settings > Privacy and Security and the app asks for it every time it opens.';

  @override
  String get faqQ8 => 'Can I edit or delete a sent message?';

  @override
  String get faqA8 => 'Touch and hold a message to edit or delete it. Deleted messages disappear for the other person too.';

  @override
  String get tourE2e => 'End-to-end encryption';

  @override
  String get tourE2eBody => 'Every chat opens only on your phone and theirs.';

  @override
  String get tourTimer => 'Disappearing messages';

  @override
  String get tourTimerBody => 'Messages delete themselves after the time you pick.';

  @override
  String get tourOnce => 'View once';

  @override
  String get tourOnceBody => 'Send photos and videos that can be opened only once.';

  @override
  String get tourBubble => 'Bubbles';

  @override
  String get tourBubbleBody => 'Float a photo bubble to a friend. It pops when opened.';

  @override
  String get tourStreak => 'Streaks';

  @override
  String get tourStreakBody => 'Chat with a friend every day and the 🔥 count goes up.';

  @override
  String get tourGroups => 'Groups and channels';

  @override
  String get tourGroupsBody => 'Groups for friends, channels for news to many people.';

  @override
  String get tourTools => 'Polls · checklists · meetups';

  @override
  String get tourToolsBody => 'Decide, share tasks and plan meetups right in the chat.';

  @override
  String get tourLocation => 'Send location';

  @override
  String get tourLocationBody => 'Send where you are. The map opens only when tapped.';

  @override
  String get myQr => 'My QR code';

  @override
  String get myQrInfo => 'Show this to a friend to share your ID in one go.';

  @override
  String get verifyThisDevice => 'Confirm this device';

  @override
  String get verifiedDone => 'Confirmed';

  @override
  String get verifyNeeded => 'Needed';

  @override
  String get undoSend => 'Undo send (5 s)';

  @override
  String get undoSendInfo => 'Messages wait 5 seconds before they really go, so you can take them back.';

  @override
  String sendingIn(int n) {
    return 'Sending in $n s';
  }

  @override
  String get veilAll => 'Hide all chats';

  @override
  String get veilAllInfo => 'Messages in every chat are covered and show only while you hold them. People nearby can\'t read them. This device only.';

  @override
  String get panic => 'Panic gesture';

  @override
  String get panicInfo => 'Double-tap with two fingers to lock at once. No sound or vibration. App lock must be on.';

  @override
  String get appearanceInfo => 'Change how Burumy looks: colour theme, night mode, text size and chat background.';

  @override
  String get themePlain => 'Plain';

  @override
  String get themeSecure => 'Secure';

  @override
  String get themeNature => 'Nature';

  @override
  String get themeDaily => 'Daily';

  @override
  String get themeHiphop => 'Hip-hop bright';

  @override
  String get themePhoto => 'My photo';

  @override
  String get myPhotoBackground => 'Use my photo as background';

  @override
  String get myColor => 'My colour';

  @override
  String get glassEffect => 'Glass';

  @override
  String get glassClear => 'Clear';

  @override
  String get glassNormal => 'Default';

  @override
  String get glassSolid => 'Solid';

  @override
  String get glassInfo => 'Solid shows clean panels instead of see-through glass. Power saving switches to this too.';

  @override
  String get autoNight => 'Auto night mode';

  @override
  String get autoNightOff => 'Off';

  @override
  String get autoNightSystem => 'Follow phone';

  @override
  String get textSizeDefault => 'Default';

  @override
  String get textSizePreview => 'Did we say left or right at yesterday\'s meeting?';

  @override
  String get textSizePreviewReply => 'Right. I\'m sure.';

  @override
  String get notificationsInfo => 'Choose how new messages reach you, including alerts while you use the app and focus hours.';

  @override
  String get inAppNotices => 'While using the app';

  @override
  String get inAppStyle => 'Alert style';

  @override
  String get inAppSilent => 'None';

  @override
  String get inAppBanner => 'Banner';

  @override
  String get inAppStyleInfo => 'A banner shows at the top for a moment. With None, nothing shows while you use the app.';

  @override
  String get inAppSound => 'Sounds in the app';

  @override
  String get inAppPreview => 'Previews in the app';

  @override
  String get focusSchedule => 'Focus hours';

  @override
  String get focusInfo => 'No alerts during these hours. Messages still arrive; it all happens on this phone.';

  @override
  String get focusFrom => 'Starts';

  @override
  String get focusTo => 'Ends';

  @override
  String get focusDays => 'Days';

  @override
  String get focusEveryDay => 'Every day';

  @override
  String get showNotices => 'Show alerts';

  @override
  String get messagePreview => 'Message preview';

  @override
  String get messagePreviewInfo => 'When off, alerts only say \'New message\'.';

  @override
  String get sound => 'Sound';

  @override
  String get soundNone => 'None';

  @override
  String get sound_nuri => 'Burumy';

  @override
  String get sound_pop => 'Pop';

  @override
  String get sound_drop => 'Drop';

  @override
  String get sound_bell => 'Bell';

  @override
  String get sound_chord => 'Chord';

  @override
  String get sound_breeze => 'Breeze';

  @override
  String get sound_knock => 'Knock';

  @override
  String get sound_twinkle => 'Twinkle';

  @override
  String get soundInfo => 'Sounds made by Burumy. Tap one to hear it.';

  @override
  String get noticeExceptions => 'Exceptions';

  @override
  String get addException => 'Add an exception';

  @override
  String get exceptionsInfo => 'Chats here follow their own setting first.';

  @override
  String get noticeOnHere => 'Alerts on';

  @override
  String get noticeOffHere => 'Alerts off';

  @override
  String get removeException => 'Remove exception';

  @override
  String get pickChat => 'Choose a chat';

  @override
  String get alwaysAllow => 'Always allow';

  @override
  String get alwaysDeny => 'Never allow';

  @override
  String get addUsers => 'Add people';

  @override
  String peopleCount(int n) {
    return '$n';
  }

  @override
  String get whoExceptionsInfo => 'People here come before the setting above. This phone applies it.';

  @override
  String get bigEmoji => 'Big emoji';

  @override
  String get bigEmojiInfo => 'One to three emoji alone are shown big, without a bubble.';

  @override
  String get burumyStickers => 'Burumy stickers';

  @override
  String stickerCount(int n) {
    return '$n stickers';
  }

  @override
  String get stickerPacksInfo => 'Characters switched off leave the sticker panel. Stickers you receive still show.';

  @override
  String get clearRecentStickers => 'Clear recent stickers';

  @override
  String get pack_buru => 'Buru';

  @override
  String get pack_dugi => 'Dugi';

  @override
  String get pack_rumi => 'Rumi';

  @override
  String get pack_mongi => 'Mongi';

  @override
  String get pack_duru => 'Duru';

  @override
  String get pack_burumi => 'Buru & Mi';

  @override
  String get dataInfo => 'See the space Burumy uses and choose when photos download.';

  @override
  String get storageUsage => 'Storage used';

  @override
  String get storageApp => 'Chats and settings';

  @override
  String get storageCache => 'Temporary files';

  @override
  String get clearCache => 'Clear temporary files';

  @override
  String get storageInfo => 'Chats are kept. Temporary files download again when needed.';

  @override
  String get storageWeb => 'On the web, the browser manages storage.';

  @override
  String get autoDownload => 'Auto-download media';

  @override
  String get autoDlCell => 'On cellular';

  @override
  String get autoDlWifi => 'On Wi-Fi';

  @override
  String get autoDownloadInfo => 'When off, photos download when you tap them. Power saving always waits for a tap.';

  @override
  String get autoplayGif => 'Autoplay GIFs';

  @override
  String get autoplayGifInfo => 'When off, GIFs stay on their first frame.';

  @override
  String get powerJobs => 'Battery-heavy features';

  @override
  String get powerJobsInfo => 'Power saving pauses these. They come back when the battery is fine.';

  @override
  String sizeBytes(int n) {
    return '$n B';
  }

  @override
  String get chatsInfo => 'How you send and reply, quick replies, away replies, and AI features that run only on this phone.';

  @override
  String get aiFeatures => 'AI features';

  @override
  String get scamWarning => 'Scam link warnings';

  @override
  String get scamWarningInfo => 'Flags odd links (look-alike, number-only or shortened addresses). Checked on this phone only; nothing is sent anywhere.';

  @override
  String get scamLink => 'Careful: suspicious link';

  @override
  String get quickReplies => 'Quick replies';

  @override
  String get quickRepliesInfo => 'Pick them from the phrase button in the composer. Up to 20.';

  @override
  String get addQuickReply => 'Add a phrase';

  @override
  String get quickReplyHint => 'e.g. In a meeting, I\'ll call you later';

  @override
  String get awayReply => 'Away reply';

  @override
  String get awayReplyInfo =>
      'When on, new 1:1 messages get this reply once. At most once every 6 hours per person. Sent by this phone when it receives the message.';

  @override
  String get awayReplyText => 'Reply text';

  @override
  String get awayReplyDefault => 'I\'m away right now. I\'ll reply when I can.';

  @override
  String get awayTag => 'Auto-reply';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name (optional)';

  @override
  String get nameHint => 'Add your name and a photo so friends can recognise you.';

  @override
  String get newPhoto => 'Set a new photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get idInfo => 'Friends can find you with this ID. Tap to copy.';

  @override
  String get themeHiphopWhite => 'Hip-hop white';

  @override
  String get themeHiphopDark => 'Hip-hop dark';

  @override
  String get manageTools => 'Admin tools';

  @override
  String get manageToolsInfo => 'Only admins see this. Messages are never sent to the server for this; your phone does the work.';

  @override
  String get toolsJoin => 'Joining';

  @override
  String get toolsPosts => 'Posts';

  @override
  String get toolsStats => 'Records and stats';

  @override
  String get roomRules => 'Rules';

  @override
  String get roomRulesHint => 'e.g. 1. Be kind\n2. No ads\n3. Credit photos';

  @override
  String get roomRulesInfo => 'Rules show even before joining. Don\'t put secrets here.';

  @override
  String get rulesAgree => 'Ask to agree to the rules';

  @override
  String get rulesAgreeInfo => 'New members must agree before they can write.';

  @override
  String get agreeRules => 'I\'ll follow the rules';

  @override
  String get welcomeMessage => 'Welcome message';

  @override
  String get welcomeHint => 'e.g. Welcome! Have a look at the pinned post first 😊';

  @override
  String get welcomeInfo => 'Shown once when someone opens the chat for the first time.';

  @override
  String get reactionsSetting => 'Reactions';

  @override
  String get reactionsAll => 'All reactions';

  @override
  String get reactionsSome => 'Some reactions';

  @override
  String get reactionsNone => 'No reactions';

  @override
  String get reactionsInfo => 'Choose which emoji people can react with.';

  @override
  String get reactionsMax => 'Max reactions per post';

  @override
  String get reactionsMaxInfo => 'How many different reactions one message can have.';

  @override
  String get reactionsPick => 'Allowed reactions';

  @override
  String get hideCounts => 'Hide reaction and vote counts';

  @override
  String get hideCountsInfo => 'Members don\'t see the numbers. Admins still do.';

  @override
  String get autoMod => 'Auto-moderation';

  @override
  String get autoModInfo =>
      'An admin\'s phone removes posts that break the rules. The server can\'t read messages, so this waits until an admin\'s app is open.';

  @override
  String get bannedWords => 'Banned words';

  @override
  String get addBannedWord => 'Add a banned word';

  @override
  String get bannedWordsInfo => 'Messages with these words are removed. The list stays on this phone.';

  @override
  String get modRules => 'Rules';

  @override
  String get modNewLinks => 'Block links from new members';

  @override
  String get modNewLinksInfo => 'Links from people first seen less than 24 hours ago';

  @override
  String get modFlood => 'Remove flooding';

  @override
  String get modFloodInfo => 'More than 5 messages in 10 seconds';

  @override
  String get roomStats => 'Stats';

  @override
  String get statsMembers => 'Members';

  @override
  String get statsPerDay => 'Messages a day';

  @override
  String get statsActive => 'Wrote in 30 days';

  @override
  String get statsMessages30 => 'Messages, last 30 days';

  @override
  String get statsHours => 'Busy hours';

  @override
  String statsBusiest(String hour) {
    return 'Busiest hour: $hour:00';
  }

  @override
  String get statsInfo => 'Worked out on this phone from the chat on this phone. Nothing is sent, and there are no per-person numbers.';

  @override
  String get modLog => 'Admin log';

  @override
  String get modLogEmpty => 'Nothing yet';

  @override
  String get modLogInfo => 'Only admin actions done on this phone. The last 200 are kept.';

  @override
  String logRemoved(String name, String why) {
    return 'Removed a message from $name ($why)';
  }

  @override
  String logBanned(String name) {
    return 'Banned $name';
  }

  @override
  String logUnbanned(String name) {
    return 'Unbanned $name';
  }

  @override
  String logSetting(String what) {
    return 'Changed a setting: $what';
  }

  @override
  String get whyWord => 'banned word';

  @override
  String get whyLink => 'new member link';

  @override
  String get whyFlood => 'flooding';

  @override
  String get movingBoard => 'Moving board';

  @override
  String get movingInfo => 'Enter how many were in your old group to see how many have moved over.';

  @override
  String get oldMembers => 'Members in the old group';

  @override
  String movedCount(String now, String old) {
    return '$now of $old have moved';
  }

  @override
  String get bannedUsers => 'Banned people';

  @override
  String get bannedEmpty => 'No one is banned';

  @override
  String get unban => 'Unban';

  @override
  String get banMember => 'Ban';

  @override
  String get roomLevel => 'Level';

  @override
  String levelN(int n) {
    return 'Level $n';
  }

  @override
  String levelNext(String members, String active, int days) {
    return 'To the next level: $members members · $active active · $days days';
  }

  @override
  String get levelMax => 'Top level reached';

  @override
  String get levelInfo => 'Levels come from members, people who wrote in the last 4 weeks, and the room\'s age. For now this phone works it out.';

  @override
  String get chatThemeHere => 'Background for this chat';

  @override
  String get chatThemeHereInfo => 'Only on your phone. Nobody else\'s background changes.';

  @override
  String get useDefault => 'Use my default';

  @override
  String get discussion => 'Discussion';

  @override
  String get discussionInfo => 'Link a group: every post gets a comments button, and comments live in that group.';

  @override
  String get discussionNone => 'None';

  @override
  String get comments => 'Comments';

  @override
  String get deleteChannel => 'Delete channel';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteRoomInfo => 'Everyone is removed and you leave too. This can\'t be undone.';

  @override
  String get deleteRoomConfirm => 'Delete for good?';

  @override
  String get saveFailed => 'Couldn\'t save. Please try again shortly.';

  @override
  String get rulesReadFirst => 'Read and agree to the rules to write';

  @override
  String get readRules => 'Read the rules';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get pollVoted => 'Voted';

  @override
  String get hideCountsInfoGroup => 'Members don\'t see the numbers. Admins still do.';

  @override
  String get pollQuizKind => 'Quiz';

  @override
  String get quizMode => 'Quiz mode';

  @override
  String get quizModeInfo => 'Pick one right answer. People see it with the explanation right after answering, and can\'t change their answer.';

  @override
  String get quizPickAnswer => 'Tap a circle to mark the right answer';

  @override
  String get quizExplain => 'Explanation (optional)';

  @override
  String get quizRight => 'Correct!';

  @override
  String get quizWrong => 'Not quite';

  @override
  String get pollDeadline => 'Closes';

  @override
  String get pollDeadlineNone => 'Never';

  @override
  String get pollIn1h => 'In 1 hour';

  @override
  String get pollIn1d => 'In 1 day';

  @override
  String get pollIn3d => 'In 3 days';

  @override
  String get pollIn1w => 'In 1 week';

  @override
  String pollLeftMin(int min) {
    return '$min min left';
  }

  @override
  String pollLeftHours(int hours) {
    return '$hours h left';
  }

  @override
  String pollLeftDays(int days) {
    return '$days days left';
  }

  @override
  String get pollDeadlineInfo => 'After this, no one can vote.';

  @override
  String get cardLottery => 'Giveaway';

  @override
  String get cardForm => 'Form';

  @override
  String get cardFaq => 'FAQ';

  @override
  String get cardGuide => 'Guide menu';

  @override
  String get cardLinks => 'Link buttons';

  @override
  String get cardTemplates => 'Templates';

  @override
  String get cardAudio => 'Audio';

  @override
  String get cardRich => 'Formatted post';

  @override
  String get cardCheckin => 'Safety check-in';

  @override
  String get newLottery => 'New giveaway';

  @override
  String get newForm => 'New form';

  @override
  String get newFaq => 'Make an FAQ';

  @override
  String get newGuide => 'Make a guide menu';

  @override
  String get newCheckin => 'New safety check-in';

  @override
  String get cardTitleLabel => 'Title';

  @override
  String get lotteryPrize => 'Prize';

  @override
  String get lotteryPrizeHint => 'e.g. 2 coffee coupons';

  @override
  String get lotteryPrizeInfo => 'Members tap Join. When it ends, my phone picks winners at random.';

  @override
  String get lotteryWinners => 'Winners';

  @override
  String get lotteryEnds => 'Ends';

  @override
  String get lotteryEndsManual => 'When I close it';

  @override
  String get lotteryAnnounce => 'Announce winners';

  @override
  String get lotteryAnnounceInfo => 'When off, only the winners are told. Only I see the list.';

  @override
  String get lotteryInfo => 'Members can\'t see who joined. Admins can\'t win. The draw runs on my phone, so open the app after it ends.';

  @override
  String get lotteryJoin => 'Join';

  @override
  String get lotteryLeave => 'Leave';

  @override
  String lotteryJoined(int n) {
    return '$n joined';
  }

  @override
  String get lotteryDraw => 'Draw now';

  @override
  String get lotteryWon => 'You won!';

  @override
  String lotteryWinnersN(int n) {
    return '$n winners';
  }

  @override
  String get lotteryNoWinner => 'Nobody joined, so there is no winner';

  @override
  String lotteryEndsAt(String when) {
    return 'Ends $when';
  }

  @override
  String get lotteryDrawAsk => 'Draw now?';

  @override
  String get lotteryDrawInfo => 'After the draw nobody can join.';

  @override
  String get cardEnded => 'Closed';

  @override
  String get cardClose => 'Close';

  @override
  String get cardCloseAsk => 'Close it now?';

  @override
  String get cardCloseInfo => 'After closing, no more answers come in.';

  @override
  String get cardAnswers => 'See answers';

  @override
  String get cardNoAnswers => 'No answers yet';

  @override
  String get cardAnswersInfo => 'Answers are only on this phone. The server and other members can\'t see them.';

  @override
  String get formTitleHint => 'e.g. December hike sign-up';

  @override
  String formQuestionN(int n) {
    return 'Question $n';
  }

  @override
  String get formQuestionHint => 'Write a question';

  @override
  String get formAnswerType => 'Answer type';

  @override
  String get formShort => 'Short answer';

  @override
  String get formChoice => 'Choice';

  @override
  String get formOptionsHint => 'One option per line';

  @override
  String get formAddQuestion => 'Add question';

  @override
  String get formInfo => 'Answers are encrypted and come only to me. Other members and the server can\'t see them.';

  @override
  String get formFill => 'Fill in';

  @override
  String get formSent => 'Sent';

  @override
  String formSentN(int n) {
    return '$n sent';
  }

  @override
  String formQuestionsN(int n) {
    return '$n questions';
  }

  @override
  String get formAnswerHint => 'Your answer';

  @override
  String get formFillInfo => 'Answers go only to the maker. Other members can\'t see them.';

  @override
  String get faqQ => 'Question';

  @override
  String get faqA => 'Answer';

  @override
  String get faqInfo => 'Members tap a question to open the answer. Nothing is sent, so nobody knows who read what.';

  @override
  String get guideTitleHint => 'How can we help?';

  @override
  String get guideSubHint => 'Tap a button below (optional)';

  @override
  String get guideButtons => 'Buttons';

  @override
  String get guideAddButton => 'Add button';

  @override
  String get guideLabel => 'Button name';

  @override
  String get guideText => 'What it shows';

  @override
  String get guideInfo => 'Tapping a button opens the next screen right there. Nothing is sent, so nobody knows who read what.';

  @override
  String get linksPreview => 'Preview';

  @override
  String get linksTextHint => 'Text above the buttons (optional)';

  @override
  String get linksAddButton => 'Add button';

  @override
  String get linksAddRow => 'Add row';

  @override
  String get linksIntro => 'Add buttons that go to websites under the post.';

  @override
  String get linksInfo => 'Buttons are encrypted with the post. Nobody can tell who tapped. Links are checked for scams on this phone.';

  @override
  String linksLeft(int n) {
    return 'Tap a button to edit it. You can add $n more.';
  }

  @override
  String linksEditing(String row, String col) {
    return 'Editing row $row, button $col';
  }

  @override
  String get linksLabel => 'Button name';

  @override
  String get linksColor => 'This button\'s colour';

  @override
  String get linksColorInfo => 'The first circle follows the colour chosen under \'Style all buttons\'.';

  @override
  String get linksRemove => 'Remove button';

  @override
  String get linksStyle => 'Style all buttons';

  @override
  String get linksStyleColor => 'Colour';

  @override
  String get linksGlass => 'Glass';

  @override
  String get linksSize => 'Size';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get linksShape => 'Shape';

  @override
  String get shapeRound => 'Rounded';

  @override
  String get shapePill => 'Pill';

  @override
  String get shapeSquare => 'Square';

  @override
  String get linksInk => 'Text colour';

  @override
  String get inkAuto => 'Auto';

  @override
  String get inkWhite => 'White';

  @override
  String get inkBlack => 'Black';

  @override
  String get linksStyleInfo => 'Applies to every button. Each button can also have its own colour.';

  @override
  String get linksBadUrl => 'Use a web address starting with https://';

  @override
  String get richTitleHint => 'Title';

  @override
  String get richBodyHint => 'Write anything...';

  @override
  String get richHeading => 'Heading';

  @override
  String get richList => 'List';

  @override
  String get richQuote => 'Quote';

  @override
  String get richLink => 'Link';

  @override
  String get richLinkUrl => 'Link address';

  @override
  String get checkinHint => 'e.g. There was an earthquake. Is everyone OK?';

  @override
  String get checkinInfo => 'Members tap \'I\'m OK\' or \'I need help\'. Answers come only to me.';

  @override
  String get checkinOk => 'I\'m OK';

  @override
  String get checkinHelp => 'I need help';

  @override
  String get templatesNew => 'New template';

  @override
  String get templatesHint => 'Write text you use often';

  @override
  String get templatesEmpty => 'No templates yet';

  @override
  String get templatesInfo => 'Templates stay on this phone. Tap one to put it in the message box.';

  @override
  String get cardRemove => 'Remove';

  @override
  String get attachPickAudio => 'Choose audio files';

  @override
  String get attachAudioInfo => 'Send music or recordings. People can play them right in the chat.';

  @override
  String get remindMe => 'Remind me';

  @override
  String get remindNote => 'This phone will remind you. Nothing is sent to the server.';

  @override
  String get remindNoteWeb => 'You\'re reminded while this window is open. Nothing is sent to the server.';

  @override
  String get remindIn20 => 'In 20 minutes';

  @override
  String get remindIn1h => 'In 1 hour';

  @override
  String get remindIn3h => 'In 3 hours';

  @override
  String get remindTomorrow => 'Tomorrow at 9 AM';

  @override
  String get remindPick => 'Pick date and time';

  @override
  String remindSet(String time) {
    return 'Reminder set: $time';
  }

  @override
  String get remindDue => 'A message you asked to be reminded of';

  @override
  String get remindChannel => 'Message reminders';

  @override
  String get remindOn => 'Reminder set';

  @override
  String get emergencyDelete => 'Delete in emergency';

  @override
  String get emergencyDeleteOff => 'Don\'t delete in emergency';

  @override
  String get emergencyHideRoom => 'Hide this chat in emergency';

  @override
  String get emergencyHideRoomOff => 'Don\'t hide in emergency';

  @override
  String get emergencyMarked => 'Opening with the delete password erases this message';

  @override
  String get emergencyUnmarked => 'Removed from emergency delete';

  @override
  String get emergencyHidden => 'Opening with the hide password hides this chat';

  @override
  String get emergencyUnhidden => 'Removed from emergency hide';

  @override
  String get emergencyWebInfo => 'App lock and emergency delete and hide can only be set in the phone app. A web browser can\'t keep secrets safe.';

  @override
  String get emergencyBadge => 'Emergency delete';

  @override
  String get selectMsg => 'Select';

  @override
  String get okButton => 'OK';

  @override
  String selectedN(int count) {
    return '$count selected';
  }

  @override
  String get selectCopy => 'Copy';

  @override
  String get selectSave => 'Save';

  @override
  String get searchThisChat => 'Search this chat';

  @override
  String searchMsgCount(int count) {
    return '$count messages';
  }

  @override
  String get searchAsList => 'Show as list';

  @override
  String get searchByDate => 'Go to date';

  @override
  String get searchFound => 'Results';

  @override
  String get searchNoneOnDate => 'No messages from that day on';

  @override
  String get savedToast => 'Saved to Saved Messages';

  @override
  String get savedTagHint => 'Tag it with an emoji to find it quickly';

  @override
  String get tagMsg => 'Tag';

  @override
  String get tagRemove => 'Remove tag';

  @override
  String get tagAll => 'All';

  @override
  String get shareMsg => 'Share';

  @override
  String get shareFailed => 'Couldn\'t share';

  @override
  String get voiceLockHint => 'Slide up to lock';

  @override
  String get voicePause => 'Pause';

  @override
  String get voiceResume => 'Resume';

  @override
  String get channelPostLoud => 'Broadcast';

  @override
  String get channelPostSilent => 'Silent broadcast';

  @override
  String get channelLoudOn => 'Subscribers get notified with sound';

  @override
  String get channelSilentOn => 'Subscribers get notified without sound';

  @override
  String get encryption => 'Encryption';

  @override
  String get encVerified => 'Verified';

  @override
  String get encNotVerified => 'Not verified';

  @override
  String get encHeroTitle => 'This chat is end-to-end encrypted';

  @override
  String get encHeroBody =>
      'Messages and calls open only on your two phones. Not even Burumy\'s server can read them. Below you can check that the other phone is really theirs.';

  @override
  String get encMembers => 'Members';

  @override
  String get encStart => 'Start check';

  @override
  String get encStartInfo => 'Do it together or on a call. If both phones show the same 7 pictures, it\'s really them.';

  @override
  String get encShowKeys => 'Show device keys (advanced)';

  @override
  String get encKeysInfo => 'Each device\'s key fingerprint. If it matches what their screen shows, it\'s the same device.';

  @override
  String get encNoDevices => 'No device info yet';

  @override
  String get verifyTitle => 'Security check';

  @override
  String get verifyWaiting => 'Waiting for the other phone to accept';

  @override
  String verifyIncoming(String name) {
    return '$name wants to check security codes with you';
  }

  @override
  String get verifyAccept => 'Accept';

  @override
  String get verifyDecline => 'Decline';

  @override
  String get verifyCompare => 'Do both phones show the same pictures in the same order?';

  @override
  String get verifyMatch => 'They match';

  @override
  String get verifyNoMatch => 'They don\'t match';

  @override
  String get verifyWaitOther => 'Waiting for them to confirm';

  @override
  String get verifyDone => 'Verified. You can now trust this person\'s phone.';

  @override
  String get verifyCancelled => 'The check was cancelled';

  @override
  String get verifyFailed => 'Couldn\'t start the check';

  @override
  String get verifyRequestLine => 'Security check request';

  @override
  String get verifyOpen => 'Check';

  @override
  String get close => 'Close';

  @override
  String get contactFirst => 'First name';

  @override
  String get contactLast => 'Last name';

  @override
  String get memoAdd => 'Add a note';

  @override
  String contactPhotoSet(String name) {
    return 'Set a photo for $name';
  }

  @override
  String contactPhotoInfo(String name) {
    return 'Only you see this photo, instead of the one $name chose.';
  }

  @override
  String get contactPhotoRemove => 'Remove my photo';

  @override
  String get msgInfo => 'Message info';

  @override
  String get msgReport => 'Report message';

  @override
  String get reportNote => 'Our team will read this message: its words are sent with the report. No other messages are sent.';

  @override
  String get reportSpam => 'Spam';

  @override
  String get reportScam => 'Scam';

  @override
  String get reportViolence => 'Violence or threats';

  @override
  String get reportSexual => 'Sexual content';

  @override
  String get reportChild => 'Child abuse';

  @override
  String get reportDrugs => 'Illegal drugs';

  @override
  String get reportPrivacy => 'Personal details';

  @override
  String get reportOther => 'Other';

  @override
  String get reportDone => 'Reported. Our team will look at it.';

  @override
  String get reportFailed => 'Couldn\'t report. Try again.';

  @override
  String get infoSent => 'Sent';

  @override
  String get infoStatus => 'Status';

  @override
  String get infoRead => 'Read';

  @override
  String get infoSentOnly => 'Sent';

  @override
  String get infoExpires => 'Disappears';

  @override
  String get threadReply => 'Reply in thread';

  @override
  String get threadTitle => 'Thread';

  @override
  String threadReplies(int count) {
    return '$count replies';
  }

  @override
  String get threadPlaceholder => 'Reply in thread';

  @override
  String get threadEmpty => 'No replies yet';

  @override
  String get packDynamic => 'Dynamic pack order';

  @override
  String get packDynamicInfo => 'Packs you used lately come first.';

  @override
  String get packOrderInfo => 'Drag the handle to change the order. Packs you turn off leave the sticker panel; stickers you get still show.';

  @override
  String get attachFromGallery => 'Choose from gallery';

  @override
  String get attachFromFiles => 'Choose from files';

  @override
  String get recentSentFiles => 'Recently sent files';

  @override
  String get photoTooBig => 'That photo is too big. Pick a smaller one.';

  @override
  String savedChatsCount(int n) {
    return '$n chats';
  }

  @override
  String get savedAll => 'All Messages';

  @override
  String get savedNotes => 'My Notes';

  @override
  String get savedOpenChat => 'Open Chat';

  @override
  String get savedSearchHint => 'Search messages or tags';

  @override
  String get savedSide => 'View by chat';

  @override
  String get savedSearchList => 'Search';

  @override
  String get savedNoMore => 'No more results';

  @override
  String get mediaZoomIn => 'Zoom In';

  @override
  String get mediaZoomOut => 'Zoom Out';

  @override
  String get mediaCalendar => 'View as Calendar';

  @override
  String get mediaPhotos => 'Show Photos';

  @override
  String get mediaVideos => 'Show Videos';

  @override
  String get savedLinkTag => 'Links';

  @override
  String get markAllRead => 'Read All';

  @override
  String get archiveShort => 'Archive';

  @override
  String get chatLocked => 'Locked end to end';

  @override
  String get storyMine => 'Your Story';

  @override
  String get storyReplyPrefix => 'Story reply:';

  @override
  String get storyReplied => 'Reply sent';

  @override
  String get storyReplyHint => 'Send message…';

  @override
  String get storyPrivateNote => 'Friends only, 24 hours · no view records';

  @override
  String get storyNow => 'now';

  @override
  String storyMinutes(int n) {
    return '${n}m';
  }

  @override
  String storyHours(int n) {
    return '${n}h';
  }

  @override
  String get storyHint => 'Take or choose a photo';

  @override
  String get storyCaptionHint => 'Add text';

  @override
  String get storyShare => 'Share with friends';

  @override
  String storyShared(int n) {
    return 'Shared with $n friends';
  }

  @override
  String get storyNoFriends => 'No friends to share with yet';

  @override
  String get storyCamera => 'Story camera';

  @override
  String get camLive => 'Live';

  @override
  String get camVideo => 'Video';

  @override
  String get camPhoto => 'Photo';

  @override
  String get camLiveStart => 'Start live broadcast';

  @override
  String get camLiveLater => 'Live broadcasts open once our own server is ready';

  @override
  String get camGridRemove => 'Tap to remove grid';

  @override
  String get camUnavailable => 'Can\'t open the camera\nThe button below uses your phone\'s camera';

  @override
  String get camDualHint => 'Takes the back camera, then the front, right after';

  @override
  String camGridLeft(int n) {
    return '$n more to take';
  }

  @override
  String storiesCount(int n) {
    return '$n stories';
  }

  @override
  String get tabGroups => 'Groups';

  @override
  String get noCommonGroups => 'No groups in common';

  @override
  String get qrCode => 'QR code';

  @override
  String get wideEmpty => 'Pick a chat';

  @override
  String get storyAnswerSent => 'Sent to your 1:1 chat';

  @override
  String get storyAnswerHint => 'Write an answer';

  @override
  String get storyGoing => 'I\'m in';

  @override
  String get storyGoingSent => 'Told them you\'re in';

  @override
  String get storyPoll => 'Poll';

  @override
  String get storyQuestion => 'Question';

  @override
  String get storyPlan => 'Plan';

  @override
  String get storyPlanTitle => 'What\'s the plan?';

  @override
  String get storyAskHint => 'Your question';

  @override
  String get storyPollInfo => 'Each answer comes to you in a 1:1 chat. Nobody else, not even Burumy, sees who picked what.';

  @override
  String storyOption(int n) {
    return 'Option $n';
  }

  @override
  String get storyPlanWhen => 'When';

  @override
  String get storyPlanPlace => 'Where (optional)';

  @override
  String get storyPlanInfo => 'When a friend taps \"I\'m in\", you hear it in your 1:1 chat.';

  @override
  String get storyQuestionInfo => 'Answers come to you in 1:1 chats, for you only.';

  @override
  String get storyAllFriends => 'All friends';

  @override
  String get storyCloseFriends => 'Close friends';

  @override
  String get storyPicked => 'Pick for this one';

  @override
  String storyPickedCount(int n) {
    return '$n people';
  }

  @override
  String storyAllFriendsSub(int n) {
    return '$n friends in 1:1 chats';
  }

  @override
  String storyCloseFriendsSub(int n) {
    return '$n people · kept on this phone only';
  }

  @override
  String get storyPickedSub => 'Choose who sees just this story';

  @override
  String get storyWho => 'Who can see it?';

  @override
  String get storyWhoInfo => 'Only the friends you pick get it, sealed in each chat\'s encryption.';

  @override
  String get storyHowLong => 'How long?';

  @override
  String get storyHowLongInfo => 'After that it disappears from friends\' phones and the server.';

  @override
  String storyHoursN(int n) {
    return '$n hours';
  }

  @override
  String get storyArchive => 'My story archive';

  @override
  String get storyArchiveEmpty => 'Nothing yet. Stories you share are kept here, on this phone only.';

  @override
  String get storyArchiveWeb => 'The web keeps no archive. Use the phone app.';

  @override
  String get storyArchiveInfo => 'On this phone only. Tap to share again, hold to delete.';

  @override
  String get storyNew => 'New story';

  @override
  String get feedTitle => 'Friends\' feed';

  @override
  String get feedEmpty => 'No posts yet';

  @override
  String get feedInfo => 'Only your 1:1 friends see it. No ads, encrypted end to end.';

  @override
  String get feedNew => 'New post';

  @override
  String get feedHint => 'What\'s new?';

  @override
  String get feedPost => 'Post';

  @override
  String get feedAddPhoto => 'Photo';

  @override
  String get feedRemovePhoto => 'Remove photo';

  @override
  String feedLikesN(int n) {
    return '$n likes';
  }

  @override
  String get feedOnlyMe => 'Only you see this';

  @override
  String get feedReplyHint => 'Your reply goes only to this friend';

  @override
  String get feedReplyPrefix => '💬 Re your post:';

  @override
  String feedPosted(int n) {
    return 'Posted to $n friends';
  }

  @override
  String get feedDeleted => 'Post deleted';

  @override
  String get feedLike => 'Like';

  @override
  String get feedReply => 'Reply';

  @override
  String get markUnread => 'Mark as unread';

  @override
  String get addToFolder => 'Add to folder';

  @override
  String removeFromFolder(String name) {
    return 'Remove from $name';
  }

  @override
  String get blockShort => 'Block';

  @override
  String get emergencyDeleteRoom => 'Delete this chat in an emergency';

  @override
  String get emergencyRoomMarked => 'Opening with the delete password erases this chat';

  @override
  String get folderAddedTo => 'Added to the folder';

  @override
  String get noFoldersYet => 'No folders yet';

  @override
  String get swipePin => 'Pin';

  @override
  String get swipeUnpin => 'Unpin';

  @override
  String get swipeMute => 'Mute';

  @override
  String get swipeUnmute => 'Unmute';

  @override
  String get swipeArchive => 'Archive';

  @override
  String get swipeUnarchive => 'Unarchive';

  @override
  String get chatsHeaderInfo => 'Choose how messages look, replies, stickers and emoji, and the on-device AI features you use in chats.';

  @override
  String get faqHeaderInfo => 'Common questions about Burumy. You can read them offline too.';

  @override
  String get devicesHeaderInfo => 'See every device signed in to your account. Sign out any device you don\'t recognise right here.';

  @override
  String get languageHeaderInfo => 'Pick the app\'s language. Messages in other languages can be translated right in the chat.';

  @override
  String get stickersHeaderInfo => 'Set your quick reaction, big emoji and how sticker packs are ordered.';

  @override
  String get birthday => 'Birthday';

  @override
  String get birthdayAdd => 'Add';

  @override
  String get birthdayInfo => 'Friends see only the month and day. Choose who sees it in Settings > Privacy and Security.';

  @override
  String get birthdayRemove => 'Remove birthday';

  @override
  String birthdayMonthDay(int m, int d) {
    return '$m/$d';
  }

  @override
  String get whoPhoto => 'Profile photo';

  @override
  String get whoBio => 'About me';

  @override
  String get whoBirthday => 'Birthday';

  @override
  String get whoLastSeen => 'Last seen & online';

  @override
  String get whoForwards => 'Forwarded messages';

  @override
  String get whoAlwaysNobody => 'Nobody';

  @override
  String get whoCardInfo => '\'My contacts\' never goes to the server; friends get it only inside your encrypted 1:1 chats.';

  @override
  String get lastSeenInfo =>
      'Burumy never shows anyone whether you\'re online or when you were last seen. It\'s built that way, so there\'s nothing to change.';

  @override
  String get forwardsInfo =>
      'When someone forwards your message, your name and the original chat never go with it, only a \'Forwarded\' mark. It\'s built that way.';

  @override
  String get editHistory => 'Hide my edit history';

  @override
  String get editHistoryAlways => 'Always';

  @override
  String get editHistoryInfo => 'People see only the last version of a message you edited. Burumy never shows earlier versions.';

  @override
  String get birthdayAlert => 'Birthday alerts';

  @override
  String get birthdayAlertInfo => 'On a friend\'s birthday (if they share it), you get an alert at 9 am. It\'s made on this phone only.';

  @override
  String birthdayAlertTitle(String name) {
    return 'It\'s $name\'s birthday today';
  }

  @override
  String get birthdayAlertBody => 'Send them a message.';

  @override
  String get showErrors => 'Show error details';

  @override
  String get showErrorsInfo => 'When on, error details are kept on this phone so you can copy them when asking for help. No message content is included.';

  @override
  String get errorLog => 'Error log';

  @override
  String get errorLogEmpty => 'No errors yet';

  @override
  String get errorLogCopy => 'Copy all';

  @override
  String get autoDeleteHeader => 'Delete my account';

  @override
  String get autoDeleteRow => 'If away for';

  @override
  String get autoDeleteInfo => 'If you don\'t come back at least once in this time, your account is deleted with all groups, messages and contacts.';

  @override
  String get months1 => '1 month';

  @override
  String get months3 => '3 months';

  @override
  String get months6 => '6 months';

  @override
  String get months12 => '12 months';

  @override
  String get months18 => '18 months';

  @override
  String get hideDeleteRow => 'Hide & delete passwords';

  @override
  String get privMessages => 'Messages';

  @override
  String get privWhoSees => 'Who can see my info';

  @override
  String get privWhoReach => 'Who can reach me';

  @override
  String get privScreen => 'Screen protection';

  @override
  String get privAccount => 'Account';

  @override
  String get undoSendSub => 'Cancel within 5 seconds of sending';

  @override
  String get sendReadSub => 'Off: others don\'t see when you\'ve read';

  @override
  String get sendTypingSub => 'Off: others don\'t see you typing';

  @override
  String get veilAllSub => 'Messages show only while you hold them';

  @override
  String get panicSub => 'Double-tap with two fingers to lock at once';

  @override
  String get birthdayAlertSub => 'This phone reminds you at 9 am on a friend\'s birthday';

  @override
  String get showErrorsSub => 'Keeps error details on this phone for support';

  @override
  String get autoDeleteSub => 'Your account is deleted if you don\'t sign in for this long';

  @override
  String get autoDlPhotosSub => 'Photos load on their own';

  @override
  String get autoDlReset => 'Reset auto-download';

  @override
  String get mediaAndLinks => 'Media and links';

  @override
  String get autoplayGifSub => 'Off: GIFs stay on the first frame';

  @override
  String get linkPreviewSub => 'Your phone adds the title and picture when sending';

  @override
  String get callsHeader => 'Calls';

  @override
  String get lowDataCalls => 'Use less data for calls';

  @override
  String get lowDataCallsSub => 'Lower video quality so calls hold up on slow networks';

  @override
  String get devicesArtInfo => 'Keep chatting on a PC or another phone.';

  @override
  String get addDevice => 'Add a device';

  @override
  String get addDeviceTitle => 'Use on another device';

  @override
  String get addDeviceStep1 => 'Install Burumy on the new device. There\'s a Windows app for PCs.';

  @override
  String get addDeviceStep2 => 'Sign in with your ID and password.';

  @override
  String get addDeviceStep3 =>
      'Confirm the request that appears on this phone by checking both devices show the same emoji. Then your past chats open there too.';

  @override
  String get devicesPlatforms => 'Burumy runs on iPhone, Android and Windows.';

  @override
  String get onlineNow => 'Active now';

  @override
  String get chatFolders => 'Chat Folders';

  @override
  String get foldersArtInfo => 'Make folders for different groups of chats and switch between them from the top of the list or the side menu.';

  @override
  String get createFolder => 'Create a Folder';

  @override
  String get allChatsFolder => 'All Chats';

  @override
  String get editList => 'Edit';

  @override
  String get foldersEditInfo => 'Tap Edit to change the order of folders or delete them.';

  @override
  String get recommendedFolders => 'Recommended Folders';

  @override
  String get folderUnreadName => 'Unread';

  @override
  String get folderUnreadInfo => 'New messages from all chats';

  @override
  String get folderPersonalName => 'Personal';

  @override
  String get folderPersonalInfo => 'Only messages from personal chats';

  @override
  String get folderTags => 'Show Folder Tags';

  @override
  String get folderTagsInfo => 'Show folder names as coloured tags under each chat in the list.';

  @override
  String folderChatsCount(int n) {
    return '$n chats';
  }

  @override
  String get folderDeleted => 'Folder deleted';

  @override
  String get folderInclude => 'Included Chats';

  @override
  String get folderIncludeInfo => 'Choose chats or types of chats that will appear in this folder.';

  @override
  String get folderExclude => 'Excluded Chats';

  @override
  String get folderExcludeInfo => 'Choose chats or types of chats that will never appear in this folder.';

  @override
  String get folderAddChats => 'Add Chats';

  @override
  String get folderColor => 'Folder Color';

  @override
  String get folderNoTag => 'No tag';

  @override
  String get folderColorInfo => 'This colour is used for the folder\'s tag in the chat list.';

  @override
  String get folderNeedChats => 'Add at least one chat.';

  @override
  String get folderNeedName => 'Enter a folder name.';

  @override
  String get chatTypes => 'Chat Types';

  @override
  String get chatsHeader => 'Chats';

  @override
  String get kindContacts => 'Contacts';

  @override
  String get kindNonContacts => 'Non-Contacts';

  @override
  String get kindMuted => 'Muted';

  @override
  String get kindRead => 'Read';

  @override
  String get kindArchived => 'Archived';

  @override
  String get folderIcon => 'Folder Icon';

  @override
  String get folderIconNone => 'None';

  @override
  String get newFolderTitle => 'New Folder';

  @override
  String exceptionsCount(int n) {
    return '$n exceptions';
  }

  @override
  String get inAppHeader => 'In-App Notifications';

  @override
  String get inAppVibrate => 'In-App Vibrate';

  @override
  String get lockName => 'Names on Lock Screen';

  @override
  String get lockNameInfo =>
      'Off: when the phone is locked, notifications hide who wrote and what. On iPhone also check iOS Settings > Notifications > Show Previews.';

  @override
  String get linkOpenTitle => 'Open Links';

  @override
  String get linkOpenHeader => 'Open Links In';

  @override
  String get linkOpenInApp => 'Inside Burumy (private view)';

  @override
  String get linkOpenBrowser => 'Default Browser';

  @override
  String get linkOpenInAppShort => 'Burumy';

  @override
  String get linkOpenBrowserShort => 'Browser';

  @override
  String get linkOpenInfo => 'Inside Burumy, links open without leaving the app and stay out of your other browser\'s history.';

  @override
  String get linkNeverHeader => 'Never Open in App';

  @override
  String get linkNeverAdd => 'Add Website';

  @override
  String get linkNeverInfo => 'These websites always open in your default browser.';

  @override
  String get tiltMove => 'Move When Tilted';

  @override
  String get tiltInfo => 'Tilt the phone and the chat background moves a little. Uses a bit more battery.';

  @override
  String get appIcon => 'App Icon';

  @override
  String get appIconInfo => 'Changes the Burumy icon on your home screen. The app may close for a moment while it changes.';

  @override
  String get appIconGreen => 'Default';

  @override
  String get appIconDark => 'Dark';

  @override
  String get appIconLight => 'White';

  @override
  String get appIconMint => 'Sage';

  @override
  String get psGlass => 'Glass Effects';

  @override
  String get psGlassSub => 'Off: bars become plain, not see-through.';

  @override
  String get psPreload => 'Preload Media';

  @override
  String get psPreloadSub => 'Download photos and videos before you open them.';

  @override
  String get psTiltSub => 'The chat background moves when you tilt the phone.';

  @override
  String get chatsMessages => 'Messages';

  @override
  String get chatsList => 'Chat List';

  @override
  String get chatsMediaReactions => 'Media and Reactions';

  @override
  String get formattingRow => 'Formatted Messages';

  @override
  String get formattingSub => 'Show bold and other formatting in messages';

  @override
  String get listMedia => 'Photo and Video Previews';

  @override
  String get listMediaSub => 'Show the last photo small in the chat list';

  @override
  String get scamWarningSub => 'Warn about suspicious links';

  @override
  String get planPick => 'Find Plans';

  @override
  String get planPickSub => 'Tap a date or time in a message to set a reminder';

  @override
  String get aiOnPhoneInfo => 'All of this runs on this phone. Messages are never sent anywhere.';

  @override
  String planFound(String when) {
    return 'Plan: $when';
  }

  @override
  String get planHourBefore => 'Remind 1 Hour Before';

  @override
  String get planAtTime => 'Remind at That Time';

  @override
  String get checkSectionTodo => 'To do';

  @override
  String get archiveToMenu => 'To menu';

  @override
  String get archiveMovedTitle => 'Archive moved to the side menu';

  @override
  String get archiveMovedBody => 'Tap the menu button at the top left to see it.';

  @override
  String get archivePinnedTitle => 'Archive pinned to the chat list';

  @override
  String get archivePinnedBody => 'Swipe it all the way left to move it again.';

  @override
  String get archivePinBack => 'Pin to list';

  @override
  String get menuStories => 'Stories';

  @override
  String get storiesMovedTitle => 'Stories moved to the side menu';

  @override
  String get bubblesMovedTitle => 'Bubbles moved to the side menu';

  @override
  String get storiesPinnedTitle => 'Stories pinned to the chat list';

  @override
  String get bubblesPinnedTitle => 'Bubbles pinned to the chat list';
}
