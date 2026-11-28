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
  String get recoveryKeyBody =>
      'You need this to open old chats on a new phone. Write it down somewhere safe.';

  @override
  String get chatsEmpty => 'No chats yet';

  @override
  String get messageLocked => 'This message can\'t be opened yet';

  @override
  String get sendFailedNoEncryption =>
      'Can\'t send to a chat that isn\'t encrypted';

  @override
  String get themeGreen => 'Green';

  @override
  String get themeBlue => 'Blue';

  @override
  String get language => 'Language';

  @override
  String get signUpSub =>
      'All you need is an ID and a password. No phone number.';

  @override
  String get haveAccount => 'I already have an account';

  @override
  String get noAccount => 'Create a new account';

  @override
  String get logInTitle => 'Welcome back';

  @override
  String get fieldRequired => 'Enter your ID and password';

  @override
  String get passwordRule =>
      'Use 8 or more characters with letters and numbers';

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
  String get encryptedNotice =>
      'This chat is end-to-end encrypted. Not even Burumy can read it.';

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
  String copyCodeButton(String code) {
    return 'Copy code · $code';
  }

  @override
  String get codeCopied => 'Code copied. Cleared in 1 minute.';

  @override
  String codeCopyFailed(String code) {
    return 'Couldn\'t copy. Code: $code';
  }

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
  String get enterRecoveryKeyBody =>
      'Enter the Chat Recovery Key from your old phone to open your old chats.';

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
  String get channelInfo =>
      'In a channel only you can post. Subscribers can read.';

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
  String get enterToManage =>
      'Enter your normal password to change lock settings';

  @override
  String get streaks => 'Streaks';

  @override
  String get streakInfo =>
      'When you both message each other every day for 3+ days in a 1:1 chat, a flame shows next to the name. In groups, half the members (2 to 5 people) need to write each day. Worked out on your phone only.';

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
  String get timerInfo =>
      'New messages in this chat are deleted for everyone after the time you choose.';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString members';
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
  String get archiveFooter =>
      'Archived chats are kept on this phone only. The server doesn\'t know which chats you archived.';

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
  String get codeBlockCopied => 'Code copied';

  @override
  String get codeBlockCopy => 'Copy code';

  @override
  String get dateMarkAdd => 'Add Date';

  @override
  String get dateMarkTime => 'Time';

  @override
  String get fmtDate => 'Date';

  @override
  String get dateCopy => 'Copy Date';

  @override
  String get dateCopied => 'Date copied';

  @override
  String get dateToCalendar => 'Add to Calendar';

  @override
  String get dateRemind => 'Set a Reminder';

  @override
  String dateInMyZone(String zone) {
    return 'Shown in your time zone ($zone)';
  }

  @override
  String get dateCalendarFailed => 'Couldn\'t open Calendar';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String sendAtTime(String date, String time) {
    return 'Send $date at $time';
  }

  @override
  String get scheduleTitle => 'Schedule Message';

  @override
  String get reschedule => 'Reschedule';

  @override
  String get scheduledTitle => 'Scheduled Messages';

  @override
  String get scheduledEmpty => 'No scheduled messages';

  @override
  String scheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String scheduledDeleted(int left) {
    return 'Deleting in ${left}s';
  }

  @override
  String get linkOptionsTitle => 'Link Preview Settings';

  @override
  String get linkOptionsPick => 'Tap a link to preview it instead';

  @override
  String get replyOptionsTitle => 'Reply Settings';

  @override
  String get linkMoveUp => 'Move Up';

  @override
  String get linkMoveDown => 'Move Down';

  @override
  String get linkPhotoSmall => 'Shrink Photo';

  @override
  String get linkPhotoBig => 'Enlarge Photo';

  @override
  String get applyChanges => 'Apply Changes';

  @override
  String get linkNoPreview => 'Do Not Preview';

  @override
  String get tabReply => 'Reply';

  @override
  String get tabLink => 'Link';

  @override
  String get linkBarLoading => 'Making a preview…';

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
  String get pollAnonInfo =>
      'Other members can\'t see who chose what. Votes go, encrypted, only to the maker\'s phone; the chat gets just the numbers.';

  @override
  String get pollOpenInfo => 'Everyone in the chat can see who chose what.';

  @override
  String get pollChannelInfo =>
      'Channel polls are always anonymous, so subscribers stay hidden.';

  @override
  String get pollCreate => 'Create';

  @override
  String pollVoters(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n votes',
      one: '1 vote',
    );
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
  String get stickerRecent => 'Recently used';

  @override
  String get stickerPhrases => 'Quick replies';

  @override
  String get stickerNone => 'No stickers match';

  @override
  String get segStickers => 'Stickers';

  @override
  String get segEmoji => 'Emoji';

  @override
  String get emoji_smileys => 'Smileys & people';

  @override
  String get emoji_people => 'Hands & people';

  @override
  String get emoji_animals => 'Animals & nature';

  @override
  String get emoji_food => 'Food & drink';

  @override
  String get emoji_activity => 'Activity';

  @override
  String get emoji_travel => 'Travel & places';

  @override
  String get emoji_objects => 'Objects';

  @override
  String get emoji_symbols => 'Symbols';

  @override
  String get stickerTileMake => 'Create\nsticker';

  @override
  String get stickerMine => 'My stickers';

  @override
  String get emojiNone => 'No emoji match';

  @override
  String get emojiPickTitle => 'Choose emoji';

  @override
  String get emojiSearchHint => 'Try heart, laugh, party';

  @override
  String get emojiSetStatus => 'Status';

  @override
  String get reactAllEmoji => 'All emoji';

  @override
  String get suggestEmoji => 'Suggest emoji for words';

  @override
  String get suggestStickers => 'Suggest stickers for emoji';

  @override
  String get suggestInfo =>
      'Type \':laugh\' for emoji, or a single emoji for matching stickers. Everything is found on this phone.';

  @override
  String get setsTitle => 'My sticker sets';

  @override
  String get setsHeader =>
      'Put your own stickers into a set and share it. The pictures travel encrypted only, so even the server can\'t see them.';

  @override
  String get setsMakeInfo => 'A set holds up to 50 stickers.';

  @override
  String get setsNew => 'New set';

  @override
  String get setsAdded => 'Added sets';

  @override
  String get setsBrowse => 'Browse sticker sets';

  @override
  String get setsBurumyPacks => 'Burumy stickers';

  @override
  String get setsBurumyInfo =>
      'Sets you turn off don\'t show in the sticker panel.';

  @override
  String get setsSeen => 'Seen in your chats';

  @override
  String get setsSeenInfo =>
      'Sets friends sent in chats, most seen first. This list stays on this phone.';

  @override
  String get setsSeenNone => 'Sets your friends send in chats gather here.';

  @override
  String setSeenCount(int n, int times) {
    return '$n stickers · seen $times times';
  }

  @override
  String get setEdit => 'Edit set';

  @override
  String get setName => 'Set name';

  @override
  String get setNameHint => 'e.g. Our puppy';

  @override
  String get setNameNeeded => 'Give the set a name';

  @override
  String setStickers(int n, int max) {
    return 'Stickers $n/$max';
  }

  @override
  String get setEmpty => 'Add at least one sticker';

  @override
  String get setOrderInfo =>
      'Tap a sticker to move it or give it an emoji. Its emoji suggests it when you type that emoji.';

  @override
  String get setItemEmoji => 'Choose emoji';

  @override
  String setItemEmojiNow(String emoji) {
    return 'Change emoji ($emoji)';
  }

  @override
  String get setItemFirst => 'Move to front';

  @override
  String get setItemLeft => 'Move left';

  @override
  String get setItemRight => 'Move right';

  @override
  String get setItemRemove => 'Remove from set';

  @override
  String get setPickTitle => 'Choose stickers';

  @override
  String setPicked(int n) {
    return '$n chosen';
  }

  @override
  String get setShare => 'Share set';

  @override
  String get setShareInfo =>
      'Send it to a chat or share a link. Anyone who gets it can add it.';

  @override
  String get setShareSheetInfo =>
      'The set is encrypted on this phone before upload. The key is only inside the chat or link, so the server sees neither pictures nor name.';

  @override
  String get setShareToChat => 'Send to a chat';

  @override
  String get setCopyLink => 'Copy link';

  @override
  String get setSent => 'Set sent';

  @override
  String get setLinkCopied => 'Link copied';

  @override
  String get setDelete => 'Delete set';

  @override
  String get setDeleteInfo =>
      'Deletes the set from this phone. Links you already shared keep working.';

  @override
  String get setOpenFailed =>
      'Can\'t open this set. The link may be cut or the set gone.';

  @override
  String get setPrivateInfo =>
      'This set only travelled encrypted. The server doesn\'t know who uses which set.';

  @override
  String setAddCount(int n) {
    return 'Add $n stickers';
  }

  @override
  String setRemove(int n) {
    return 'Remove set ($n)';
  }

  @override
  String setAdded(String name) {
    return 'Added \'$name\'';
  }

  @override
  String get setRemoved => 'Set removed';

  @override
  String get setAddShort => 'Add';

  @override
  String get setAddedShort => 'Added';

  @override
  String get setCardKind => 'Sticker set';

  @override
  String get setCardView => 'View';

  @override
  String get setCardHave => 'Added · View';

  @override
  String get statusTitle => 'Emoji status';

  @override
  String get statusInfo =>
      'Shows an emoji beside your name. Only friends you have a 1:1 chat with get it, encrypted.';

  @override
  String get statusOther => 'Choose another emoji';

  @override
  String get statusClear => 'Clear status';

  @override
  String get statusCleared => 'Status cleared';

  @override
  String get statusHowLong => 'Show it for how long?';

  @override
  String get statusFor1h => '1 hour';

  @override
  String get statusFor2h => '2 hours';

  @override
  String get statusFor8h => '8 hours';

  @override
  String get statusFor2d => '2 days';

  @override
  String get statusForEver => 'Until I clear it';

  @override
  String statusSet(String emoji) {
    return 'Status set to $emoji';
  }

  @override
  String get statusRow => 'Emoji status';

  @override
  String get stickerMakeTitle => 'Create sticker';

  @override
  String get stickerMakeCut => 'Cut out';

  @override
  String get stickerMakeOutline => 'White edge';

  @override
  String get stickerMakeText => 'Add words';

  @override
  String get stickerMakeRound => 'Rounded';

  @override
  String get stickerMakeCircle => 'Circle';

  @override
  String get stickerMakeWorking => 'Cutting out…';

  @override
  String get stickerMakeInfo =>
      'The photo is handled only on this phone. Tap to pick another.';

  @override
  String get stickerMakeNoCut =>
      'This device can\'t cut out by itself, so the photo sits in a shape.';

  @override
  String get stickerTileBubble => 'Send a\nbubble';

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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n bubbles',
      one: '1 bubble',
    );
    return '$_temp0';
  }

  @override
  String get bubbleTapToPop => 'Tap to pop';

  @override
  String get bubbleSent => 'Bubble sent';

  @override
  String get bubblePopped => 'Popped';

  @override
  String get bubbleOnce =>
      'You can see this once. It\'s gone when you close it.';

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
  String get deleteForBothInfo =>
      'This chat is deleted on your phone and your friend\'s phone.';

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
  String get privacyInfo =>
      'Manage app lock, hide and delete passwords and your chat recovery key.';

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
  String get defaultTimerInfo =>
      'New chats you start will delete messages for everyone after this time.';

  @override
  String get privacyWho => 'Privacy';

  @override
  String get whoInfo =>
      'Calls from others become missed calls; their messages and invitations stay hidden.';

  @override
  String get whoCalls => 'Calls';

  @override
  String get whoMessages => 'Messages';

  @override
  String get whoInvites => 'Group and channel invites';

  @override
  String get readTypingInfo =>
      'When off, others do not see when you read or type.';

  @override
  String get sendRead => 'Send read receipts';

  @override
  String get sendTyping => 'Send typing indicator';

  @override
  String get devices => 'Devices';

  @override
  String get encryptionKeys => 'Encryption keys';

  @override
  String get blockedInfo =>
      'Blocked people cannot reach you with messages or invites. They are not told.';

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
  String get passwordAgainInfo =>
      'For safety, enter your account password again.';

  @override
  String get keysInfo =>
      'Compare these keys in person to make sure no one is in the middle. Tap to copy.';

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
  String get veilDotsInfo =>
      'Messages in this chat are covered with sparkling dots and show only while you hold them. Tap once to open the menu.';

  @override
  String get readHere => 'Read receipts in this chat';

  @override
  String get veilBlur => 'Sensitive chat';

  @override
  String get veilBlurInfo =>
      'A sensitive chat sits under frosted glass and is clear only while your finger rests on it, so people nearby can\'t read it.';

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
  String get bioInfo =>
      'Choose who sees it in Settings > Privacy and Security. Up to 70 characters.';

  @override
  String get markRead => 'Read';

  @override
  String get hideFromList => 'Hide from list';

  @override
  String get hiddenChats => 'Hidden chats';

  @override
  String get hiddenChatsInfo =>
      'Chats you hid from the list. Messages and notifications still arrive. Tap one to show it again.';

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
  String get listTopInfo =>
      'Off gives the chat list more room. Search and folders are in the menu at the top left.';

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
  String get scheduledInfo =>
      'Scheduled messages wait on this phone, encrypted. They go at the set time if the app is open, or the next time you open it.';

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
  String get contactNameInfo =>
      'Only you see this name, on this phone. They won\'t know.';

  @override
  String get memo => 'Note';

  @override
  String get memoHint => 'Something to remember about them';

  @override
  String get memoInfo => 'Notes stay on this phone too.';

  @override
  String get clearChat => 'Clear messages';

  @override
  String get clearChatInfo =>
      'Cleared only on your screen. Theirs stays as it is.';

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
  String get attachFileInfo =>
      'Photos can go as original files too. Up to 20 at a time.';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get onceOnInfo => 'Viewable once; gone after 24h if not opened';

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
  String get checklistOthersInfo =>
      'Checklists are encrypted like messages. Ticks or tasks from people you didn\'t allow are ignored on every phone.';

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
  String get meetupInfo =>
      'Events and answers are encrypted like messages. The server never knows who\'s coming.';

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
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString subscribers';
  }

  @override
  String get subscribers => 'Subscribers';

  @override
  String get hideMembersOnInfo => 'Only admins see the member list.';

  @override
  String get subscribersHiddenInfo =>
      'Only admins can see subscribers. Other subscribers never know who follows.';

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
  String get hideMembersInfo =>
      'When on, only admins can see who is in the group.';

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
  String get locationDenied =>
      'Location access is off. Allow Burumy to use your location in Settings.';

  @override
  String get locationOff => 'Location services are turned off on this phone.';

  @override
  String get locationUnavailable =>
      'Your location can\'t be found right now. Try again in a moment.';

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
  String get securityCheckInfo =>
      'Do these two things and your chats stay safe even if you lose or change your phone.';

  @override
  String get checkRecovery => 'Make a chat recovery key';

  @override
  String get checkRecoveryInfo =>
      'Use it to open your old chats on a new phone. If you lose it, nobody can bring them back.';

  @override
  String get checkDevice => 'Confirm this device';

  @override
  String get checkDeviceInfo =>
      'Confirming this device is yours lets friends chat with you safely.';

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
  String get accountManageInfo =>
      'Your ID, password, signed-in devices and encryption keys in one place.';

  @override
  String get faq => 'FAQ';

  @override
  String get feedbackTitle => 'Report a bug or idea';

  @override
  String get feedbackHeader =>
      'Tell us what broke or what you\'d like. The team reads every one, and fixes are posted in the Burumy News channel.';

  @override
  String get feedbackBug => 'Bug';

  @override
  String get feedbackIdea => 'Idea';

  @override
  String get feedbackWhat => 'Details';

  @override
  String get feedbackSubject => 'One-line summary';

  @override
  String get feedbackBodyBug => 'What did you do, and what happened?';

  @override
  String get feedbackBodyIdea => 'What would you like to have?';

  @override
  String get feedbackBugHint =>
      'e.g. I tapped + to send a photo and the screen went white.';

  @override
  String get feedbackIdeaHint => 'e.g. I\'d like to schedule channel posts.';

  @override
  String get feedbackNeedWords =>
      'Please fill in both the summary and the details.';

  @override
  String get feedbackGoesTo => 'Goes to';

  @override
  String get feedbackTeam => 'Burumy team';

  @override
  String get feedbackSentTitle => 'Sent';

  @override
  String get feedbackSentBody =>
      'Thank you. We\'ll post in Burumy News when it\'s fixed.';

  @override
  String get feedbackFailed => 'Couldn\'t send. Please try again in a moment.';

  @override
  String get feedbackMine => 'What I sent';

  @override
  String get feedbackMineInfo => 'This list is kept on this phone only.';

  @override
  String feedbackPrivacy(String device) {
    return 'Sent with it: the kind, your words, device type ($device) and app version. Never chats, contacts or photos. It goes as an encrypted 1:1 message.';
  }

  @override
  String feedbackAttachLog(int count) {
    return 'Attach error log · $count';
  }

  @override
  String feedbackDate(int month, int day) {
    return '$month/$day';
  }

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
  String get openSourceLicenses => 'Open source and credits';

  @override
  String get aboutInfo =>
      'Burumy is a messenger where nobody can read your chats. Not the operator, not the server.';

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
  String get powerModeInfo =>
      'When the battery is below this level, moving effects pause. The web can\'t read the battery, so only \'Always\' works there.';

  @override
  String get faqQ1 => 'Are my chats really safe?';

  @override
  String get faqA1 =>
      'All 1:1 and group chats are end-to-end encrypted. The server and the operator can\'t read them.';

  @override
  String get faqQ2 => 'Can I sign up without a phone number?';

  @override
  String get faqA2 =>
      'Yes. You only need an ID and a password. We don\'t use phone numbers or contacts.';

  @override
  String get faqQ3 => 'Will I lose my chats if I change phones?';

  @override
  String get faqA3 =>
      'Make a chat recovery key and you can open your old chats on a new phone. Only you have the key, so if you lose it nobody can bring them back.';

  @override
  String get faqQ4 => 'Who can find me?';

  @override
  String get faqA4 =>
      'Only people who know your ID. Nobody can find you by name or phone number.';

  @override
  String get faqQ5 => 'How do I turn on disappearing messages?';

  @override
  String get faqA5 =>
      'Tap the timer button at the top of a chat and pick a time. Messages sent after that disappear when the time is up.';

  @override
  String get faqQ6 => 'What is a bubble?';

  @override
  String get faqA6 =>
      'A photo that disappears once it\'s opened. The home-screen widget shows only the bubble, never the content.';

  @override
  String get faqQ7 => 'Can I lock the app?';

  @override
  String get faqA7 =>
      'Set a password in Settings > Privacy and Security and the app asks for it every time it opens.';

  @override
  String get faqQ8 => 'Can I edit or delete a sent message?';

  @override
  String get faqA8 =>
      'Touch and hold a message to edit or delete it. Deleted messages disappear for the other person too.';

  @override
  String get tourE2e => 'End-to-end encryption';

  @override
  String get tourE2eBody => 'Every chat opens only on your phone and theirs.';

  @override
  String get tourTimer => 'Disappearing messages';

  @override
  String get tourTimerBody =>
      'Messages delete themselves after the time you pick.';

  @override
  String get tourOnce => 'View once';

  @override
  String get tourOnceBody =>
      'Send photos and videos that can be opened only once.';

  @override
  String get tourBubble => 'Bubbles';

  @override
  String get tourBubbleBody =>
      'Float a photo bubble to a friend. It pops when opened.';

  @override
  String get tourStreak => 'Streaks';

  @override
  String get tourStreakBody =>
      'Chat with a friend every day and the 🔥 count goes up.';

  @override
  String get tourGroups => 'Groups and channels';

  @override
  String get tourGroupsBody =>
      'Groups for friends, channels for news to many people.';

  @override
  String get tourTools => 'Polls · checklists · meetups';

  @override
  String get tourToolsBody =>
      'Decide, share tasks and plan meetups right in the chat.';

  @override
  String get tourLocation => 'Send location';

  @override
  String get tourLocationBody =>
      'Send where you are. The map opens only when tapped.';

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
  String get undoSendInfo =>
      'Messages wait 5 seconds before they really go, so you can take them back.';

  @override
  String sendingIn(int n) {
    return 'Sending in $n s';
  }

  @override
  String get veilAll => 'Hide messages in chats';

  @override
  String get veilAllInfo =>
      'Messages in every chat are covered and show only while you hold them. People nearby can\'t read them. This device only.';

  @override
  String get panic => 'Panic gesture';

  @override
  String get panicInfo =>
      'Double-tap with two fingers to lock at once. No sound or vibration. App lock must be on.';

  @override
  String get appearanceInfo =>
      'Change how Burumy looks: colour theme, night mode, text size and chat background.';

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
  String get avatarShape => 'Profile shape';

  @override
  String get avatarShapePeople => 'People';

  @override
  String get avatarShapeGroups => 'Groups';

  @override
  String get avatarShapeChannels => 'Channels';

  @override
  String get shapeCircle => 'Circle';

  @override
  String get shapeRounded => 'Rounded square';

  @override
  String get avatarShapeInfo =>
      'Only how they look changes. Photos stay as they are.';

  @override
  String get tabEditFolder => 'Edit folder';

  @override
  String get tabShowUnread => 'View unread chats';

  @override
  String get tabReorder => 'Reorder tabs';

  @override
  String get glassEffect => 'Glass';

  @override
  String get glassClear => 'Clear';

  @override
  String get glassNormal => 'Default';

  @override
  String get glassSolid => 'Solid';

  @override
  String get glassInfo =>
      'Solid shows clean panels instead of see-through glass. Power saving switches to this too.';

  @override
  String get autoNight => 'Auto night mode';

  @override
  String get autoNightOff => 'Off';

  @override
  String get autoNightSystem => 'Follow phone';

  @override
  String get roomThemeMine => 'Mine';

  @override
  String autoNightRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String get autoNightInfo =>
      '“Follow phone” turns dark with your phone. “Schedule” turns night mode on only between the times you pick.';

  @override
  String get autoNightSchedule => 'Schedule';

  @override
  String get autoNightTimes => 'Times';

  @override
  String get autoNightFrom => 'Turn on';

  @override
  String get autoNightTo => 'Turn off';

  @override
  String get autoNightScheduleInfo =>
      'Times are kept on this phone only. Sunset times need your location, so they are not offered.';

  @override
  String timerYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String timerMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String timerWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String timerDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String timerHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String timerMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get timerOther => 'Other time';

  @override
  String timerUnitHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'hours',
      one: 'hour',
    );
    return '$_temp0';
  }

  @override
  String timerUnitDays(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String timerUnitWeeks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String timerUnitMonths(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String timerUnitYears(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String get defaultTimerHeader =>
      'Messages are erased from both phones after the time you pick, from 1 hour up to 1 year.';

  @override
  String get defaultTimerNew => 'New chats';

  @override
  String get timerApply => 'Apply to existing chats';

  @override
  String get timerApplyInfo =>
      'The same time goes on every chat you pick at once. Each chat shows that the timer changed.';

  @override
  String get timerApplyGo => 'Apply';

  @override
  String timerApplyGoN(int n) {
    return 'Apply $n';
  }

  @override
  String get timerApplyTime => 'Time to apply';

  @override
  String get timerApplyPick => 'Pick chats';

  @override
  String get timerSelectAll => 'Select all';

  @override
  String get timerDeselectAll => 'Deselect all';

  @override
  String timerApplied(int n, String time) {
    return 'Auto-delete $time is on in $n chats';
  }

  @override
  String timerAppliedOff(int n) {
    return 'Auto-delete is off in $n chats';
  }

  @override
  String get qrTheme => 'Theme';

  @override
  String get qrShort => '5-minute QR';

  @override
  String get qrShortFooter =>
      'When on, the code stops working after 5 minutes and your ID is not written on the card, so a photo of it is useless later.';

  @override
  String get qrShortInfo => 'This code works for 5 minutes only.';

  @override
  String get qrShortOver => 'Expired';

  @override
  String get qrShortAgain => 'Make a new code';

  @override
  String get roomThemeBoth => 'Also for the other person';

  @override
  String get roomThemeBothInfo =>
      'When on, the background changes on their phone too. Which one is end-to-end encrypted, so the server can\'t tell. Your own photo stays on your phone.';

  @override
  String get roomThemeByOther =>
      'The other person picked this background. Pick again to change it.';

  @override
  String get roomThemeSent => 'Changed for them too';

  @override
  String get roomThemeSample1 => 'What time today?';

  @override
  String get roomThemeSample2 => '7 works 🙂';

  @override
  String get textSizeDefault => 'Default';

  @override
  String get textSizePreview =>
      'Did we say left or right at yesterday\'s meeting?';

  @override
  String get textSizePreviewReply => 'Right. I\'m sure.';

  @override
  String get notificationsInfo =>
      'Choose how new messages reach you, including alerts while you use the app and focus hours.';

  @override
  String get inAppNotices => 'While using the app';

  @override
  String get inAppStyle => 'Alert style';

  @override
  String get inAppSilent => 'None';

  @override
  String get inAppBanner => 'Banner';

  @override
  String get inAppStyleInfo =>
      'A banner shows at the top for a moment. With None, nothing shows while you use the app.';

  @override
  String get inAppSound => 'Sounds in the app';

  @override
  String get inAppPreview => 'Previews in the app';

  @override
  String get focusSchedule => 'Focus hours';

  @override
  String get focusInfo =>
      'No alerts during these hours. Messages still arrive; it all happens on this phone.';

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
  String get whoExceptionsInfo =>
      'People here come before the setting above. This phone applies it.';

  @override
  String get bigEmoji => 'Big emoji';

  @override
  String get fxAdd => 'Add an effect';

  @override
  String get fxMore => 'More effects';

  @override
  String get fxSearch => 'Search effects';

  @override
  String get fxNothing => 'No matching effects';

  @override
  String get fxReplay => 'Play the effect again';

  @override
  String fxSendWith(String name) {
    return 'Send with $name';
  }

  @override
  String fxQuietWith(String name) {
    return 'Send quietly with $name';
  }

  @override
  String get diceBull => 'Bullseye!';

  @override
  String get diceMissed => 'Missed';

  @override
  String diceScore(int n) {
    return '$n points';
  }

  @override
  String get diceGoal => 'Goal!';

  @override
  String get diceAlmost => 'So close';

  @override
  String get diceStrike => 'Strike!';

  @override
  String dicePins(int n) {
    return '$n pins';
  }

  @override
  String get diceJackpot => 'Jackpot!';

  @override
  String diceTry(String emoji) {
    return 'Send $emoji on its own to try it too';
  }

  @override
  String get diceTrySend => 'Send';

  @override
  String get cxStill => 'Still';

  @override
  String get cxBounce => 'Bounce';

  @override
  String get cxSpin => 'Spin';

  @override
  String get cxWiggle => 'Wiggle';

  @override
  String get cxBeat => 'Beat';

  @override
  String get cxFloat => 'Float';

  @override
  String get cxJelly => 'Jelly';

  @override
  String get cxSparkle => 'Sparkle';

  @override
  String get cxMakeTitle => 'Make an emoji';

  @override
  String get cxWordsHint => 'Type a few letters and they become an emoji';

  @override
  String get cxPhotoHint => 'Pick a photo to turn it into an emoji';

  @override
  String get cxSample => 'Best day';

  @override
  String get cxFromPhoto => 'From a photo';

  @override
  String get cxFromWords => 'From words';

  @override
  String get cxWordsPlaceholder => '1–4 letters (e.g. OK, LOL)';

  @override
  String get cxMotionTitle => 'Motion';

  @override
  String get cxBaseTitle => 'Stand-in emoji';

  @override
  String get cxBaseInfo =>
      'Shown where pictures can\'t be drawn, like the chat list and notifications.';

  @override
  String cxGroupSection(String name) {
    return '$name emoji';
  }

  @override
  String get cxMineSection => 'My emoji';

  @override
  String get cxIsMine => 'It\'s in My emoji';

  @override
  String get cxSaveInfo => 'Save it to My emoji to use it in any chat';

  @override
  String get cxSave => 'Save to My emoji';

  @override
  String get cxRemove => 'Remove from My emoji';

  @override
  String get cxGroupTitle => 'Group emoji';

  @override
  String get cxGroupAdminInfo =>
      'The emoji you pick show first in everyone\'s emoji panel in this group. Pictures are encrypted; the server can\'t see them.';

  @override
  String get cxGroupInfo =>
      'Emoji the admins picked for this group. Tap one to save it to My emoji.';

  @override
  String get cxGroupEmptyAdmin =>
      'Make an emoji first, then pick from the ones you made.';

  @override
  String get cxGroupEmpty => 'No group emoji yet';

  @override
  String cxGroupCount(int n, int max) {
    return '$n of $max picked';
  }

  @override
  String get cxSaveAll => 'Save all to My emoji';

  @override
  String get cxAllSaved => 'All saved';

  @override
  String get gifSave => 'Save GIF';

  @override
  String get gifSaved => 'Saved to My GIFs';

  @override
  String get gifMine => 'My GIFs';

  @override
  String get gifEmpty =>
      'No saved GIFs yet.\nHold a GIF in a chat and tap \'Save GIF\'.';

  @override
  String get gifWithCaption => 'Send with Caption';

  @override
  String get gifEdit => 'Edit and Send';

  @override
  String get gifRemove => 'Remove from My GIFs';

  @override
  String gifRemoveIn(int n) {
    return 'Removing from My GIFs in ${n}s';
  }

  @override
  String get gifCaptionHint => 'Add a caption…';

  @override
  String get gifTrim => 'Trim';

  @override
  String get bigEmojiInfo =>
      'One to three emoji alone are shown big, without a bubble.';

  @override
  String get burumyStickers => 'Burumy stickers';

  @override
  String stickerCount(int n) {
    return '$n stickers';
  }

  @override
  String get stickerPacksInfo =>
      'Characters switched off leave the sticker panel. Stickers you receive still show.';

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
  String get dataInfo =>
      'See the space Burumy uses and choose when photos download.';

  @override
  String get storageUsage => 'Storage used';

  @override
  String get storageApp => 'Chats and settings';

  @override
  String get storageCache => 'Temporary files';

  @override
  String get clearCache => 'Clear temporary files';

  @override
  String get storageInfo =>
      'Chats are kept. Temporary files download again when needed.';

  @override
  String get storageWeb => 'On the web, the browser manages storage.';

  @override
  String get autoDownload => 'Auto-download media';

  @override
  String get autoDlCell => 'On cellular';

  @override
  String get autoDlWifi => 'On Wi-Fi';

  @override
  String get autoDownloadInfo =>
      'Anything not downloaded ahead downloads when you tap it. In power saving, everything waits for a tap.';

  @override
  String get autoplayGif => 'Autoplay GIFs';

  @override
  String get autoplayGifInfo => 'When off, GIFs stay on their first frame.';

  @override
  String get powerJobs => 'Battery-heavy features';

  @override
  String get powerJobsInfo =>
      'Power saving pauses these. They come back when the battery is fine.';

  @override
  String sizeBytes(int n) {
    return '$n B';
  }

  @override
  String get chatsInfo =>
      'How you send and reply, quick replies, away replies, and AI features that run only on this phone.';

  @override
  String get aiFeatures => 'AI features';

  @override
  String get scamWarning => 'Scam link warnings';

  @override
  String get scamWarningInfo =>
      'Flags odd links (look-alike, number-only or shortened addresses). Checked on this phone only; nothing is sent anywhere.';

  @override
  String get scamLink => 'Careful: suspicious link';

  @override
  String get quickReplies => 'Quick replies';

  @override
  String get quickRepliesInfo =>
      'Pick them from the phrase button in the composer. Up to 20.';

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
  String get nameHint =>
      'Add your name and a photo so friends can recognise you.';

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
  String get manageToolsInfo =>
      'Only admins see this. Messages are never sent to the server for this; your phone does the work.';

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
  String get roomRulesInfo => 'Every member can see them.';

  @override
  String get rulesAgree => 'Ask to agree to the rules';

  @override
  String get rulesAgreeInfo => 'New members must agree before they can write.';

  @override
  String get agreeRules => 'I\'ll follow the rules';

  @override
  String get welcomeMessage => 'Welcome message';

  @override
  String get welcomeHint =>
      'e.g. Welcome! Have a look at the pinned post first 😊';

  @override
  String get welcomeInfo =>
      'Shown once, only to each new member when they join.';

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
  String get reactionsMaxInfo =>
      'How many different reactions one message can have.';

  @override
  String get reactionsPick => 'Allowed reactions';

  @override
  String get reactionsPreview => 'Preview';

  @override
  String get reactionsPreviewPost => 'New update tonight at 8 🎉';

  @override
  String get reactionsNoneInfo =>
      'Nobody can react. The server refuses new reactions too.';

  @override
  String get reactionHiddenMine =>
      'Your reaction is hidden by the chat\'s rules. Tap to take it back.';

  @override
  String get hideCounts => 'Hide reaction and vote counts';

  @override
  String get hideCountsInfo =>
      'Members don\'t see the numbers. Admins still do.';

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
  String get bannedWordsInfo =>
      'Messages with these words are removed. The list stays on this phone.';

  @override
  String get modRules => 'Rules';

  @override
  String get modNewLinks => 'Block links from new members';

  @override
  String get modNewLinksInfo =>
      'Links from people first seen less than 24 hours ago';

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
  String get statsInfo =>
      'Worked out on this phone from the chat on this phone. Nothing is sent, and there are no per-person numbers.';

  @override
  String get modLog => 'Admin log';

  @override
  String get modLogEmpty => 'Nothing yet';

  @override
  String get modLogInfo =>
      'Only admin actions done on this phone. The last 200 are kept.';

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
  String get movingInfo =>
      'Enter how many were in your old group to see how many have moved over.';

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
  String get levelInfo =>
      'Levels come from members, people who wrote in the last 4 weeks, and the room\'s age. For now this phone works it out.';

  @override
  String get chatThemeHere => 'Background for this chat';

  @override
  String get chatThemeHereInfo =>
      'Only on your phone. Nobody else\'s background changes.';

  @override
  String get useDefault => 'Use my default';

  @override
  String get discussion => 'Discussion';

  @override
  String get discussionInfo =>
      'Link a group: every post gets a comments button, and comments live in that group.';

  @override
  String get discussionNone => 'None';

  @override
  String get comments => 'Comments';

  @override
  String get deleteChannel => 'Delete channel';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteRoomInfo =>
      'Everyone is removed and you leave too. This can\'t be undone.';

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
  String get hideCountsInfoGroup =>
      'Members don\'t see the numbers. Admins still do.';

  @override
  String get pollQuizKind => 'Quiz';

  @override
  String get quizMode => 'Quiz mode';

  @override
  String get quizModeInfo =>
      'Pick one right answer. People see it with the explanation right after answering, and can\'t change their answer.';

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
  String get lotteryPrizeInfo =>
      'Members tap Join. When it ends, my phone picks winners at random.';

  @override
  String get lotteryWinners => 'Winners';

  @override
  String get lotteryEnds => 'Ends';

  @override
  String get lotteryEndsManual => 'When I close it';

  @override
  String get lotteryAnnounce => 'Announce winners';

  @override
  String get lotteryAnnounceInfo =>
      'When off, only the winners are told. Only I see the list.';

  @override
  String get lotteryInfo =>
      'Members can\'t see who joined. Admins can\'t win. The draw runs on my phone, so open the app after it ends.';

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
  String get cardAnswersInfo =>
      'Answers are only on this phone. The server and other members can\'t see them.';

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
  String get formInfo =>
      'Answers are encrypted and come only to me. Other members and the server can\'t see them.';

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
  String get formFillInfo =>
      'Answers go only to the maker. Other members can\'t see them.';

  @override
  String get faqQ => 'Question';

  @override
  String get faqA => 'Answer';

  @override
  String get faqInfo =>
      'Members tap a question to open the answer. Nothing is sent, so nobody knows who read what.';

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
  String get guideInfo =>
      'Tapping a button opens the next screen right there. Nothing is sent, so nobody knows who read what.';

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
  String get linksInfo =>
      'Buttons are encrypted with the post. Nobody can tell who tapped. Links are checked for scams on this phone.';

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
  String get linksColorInfo =>
      'The first circle follows the colour chosen under \'Style all buttons\'.';

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
  String get linksStyleInfo =>
      'Applies to every button. Each button can also have its own colour.';

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
  String get checkinInfo =>
      'Members tap \'I\'m OK\' or \'I need help\'. Answers come only to me.';

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
  String get templatesInfo =>
      'Templates stay on this phone. Tap one to put it in the message box.';

  @override
  String get cardRemove => 'Remove';

  @override
  String get attachPickAudio => 'Choose audio files';

  @override
  String get attachAudioInfo =>
      'Send music or recordings. People can play them right in the chat.';

  @override
  String get remindMe => 'Remind me';

  @override
  String get remindNote =>
      'This phone will remind you. Nothing is sent to the server.';

  @override
  String get remindNoteWeb =>
      'You\'re reminded while this window is open. Nothing is sent to the server.';

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
  String get emergencyDelete => 'Delete this message in emergency';

  @override
  String get emergencyDeleteOff => 'Don\'t delete in emergency';

  @override
  String get emergencyHideRoom => 'Hide this chat in emergency';

  @override
  String get emergencyHideRoomOff => 'Don\'t hide in emergency';

  @override
  String get emergencyHideMsg => 'Hide this message in emergency';

  @override
  String get emergencyHideMsgOff => 'Don\'t hide in emergency';

  @override
  String get emergencyMsgHidden =>
      'Opened with the hide password, this message disappears';

  @override
  String get emergencyMarked =>
      'Opening with the delete password erases this message';

  @override
  String get emergencyUnmarked => 'Removed from emergency delete';

  @override
  String get emergencyHidden =>
      'Opening with the hide password hides this chat';

  @override
  String get emergencyUnhidden => 'Removed from emergency hide';

  @override
  String get emergencyWebInfo =>
      'App lock and emergency delete and hide can only be set in the phone app. A web browser can\'t keep secrets safe.';

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
  String get encStartInfo =>
      'Do it together or on a call. If both phones show the same 7 pictures, it\'s really them.';

  @override
  String get encShowKeys => 'Show device keys (advanced)';

  @override
  String get encKeysInfo =>
      'Each device\'s key fingerprint. If it matches what their screen shows, it\'s the same device.';

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
  String get verifyCompare =>
      'Do both phones show the same pictures in the same order?';

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
  String get reportNote =>
      'Our team will read this message: its words are sent with the report. No other messages are sent.';

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
  String get suggestPost => 'Suggest a Post';

  @override
  String get suggestHint => 'Suggest a post for this channel';

  @override
  String get suggestBarButton => 'Suggest a Post';

  @override
  String get suggestTextHint => 'Write the post you\'d like to see';

  @override
  String get suggestPhoto => 'Add Photo';

  @override
  String get suggestPhotoRemove => 'Remove Photo';

  @override
  String get suggestTime => 'Time';

  @override
  String get suggestAnyTime => 'Anytime';

  @override
  String get suggestTimeInfo =>
      'Pick a time if you\'d like one. Admins can change it.';

  @override
  String get suggestSend => 'Send Suggestion';

  @override
  String get suggestFree =>
      'It\'s free. Your post and photo are end-to-end encrypted; only this channel\'s admins see them.';

  @override
  String get suggestCardTitle => 'Suggested Post';

  @override
  String suggestWantsAt(Object when) {
    return 'Preferred time: $when';
  }

  @override
  String get suggestWaiting => 'Waiting for the admins';

  @override
  String get suggestAccept => 'Publish';

  @override
  String get suggestDecline => 'Decline';

  @override
  String get suggestAcceptTitle => 'Publish to Channel';

  @override
  String get suggestNow => 'Now';

  @override
  String suggestTheirTime(Object when) {
    return 'Their time ($when)';
  }

  @override
  String get suggestOtherTime => 'Choose Another Time';

  @override
  String get suggestCredit => 'Credit the suggester';

  @override
  String suggestCreditLine(Object name) {
    return '✍️ Suggested by $name';
  }

  @override
  String get suggestNote => 'Reason (optional)';

  @override
  String get suggestDeclineSend => 'Decline';

  @override
  String get suggestDealAccepted => 'Agreement Reached!';

  @override
  String get suggestDealNow => 'Published to the channel.';

  @override
  String suggestDealAt(Object when) {
    return 'Will be published automatically $when.';
  }

  @override
  String get suggestDealFree => 'A free suggestion, no money changed hands.';

  @override
  String get suggestDealCredit => 'The post credits the suggester.';

  @override
  String get suggestDealDeclined => 'Suggestion declined';

  @override
  String suggestDealNote(Object note) {
    return 'Reason: $note';
  }

  @override
  String get suggestSent => 'Suggestion sent';

  @override
  String get suggestPublished => 'Published';

  @override
  String suggestScheduled(Object when) {
    return 'Scheduled for $when';
  }

  @override
  String get suggestDeclinedNotice => 'Suggestion declined';

  @override
  String get suggestPhoneOn =>
      'Scheduled posts go out from this phone; the app needs to open once around that time.';

  @override
  String get suggestNoRight => 'You can\'t post in this channel';

  @override
  String get topics => 'Topics';

  @override
  String get topicsInfo =>
      'Split a big group into topic rooms. Which topic each message is in is end-to-end encrypted too, so the server never knows.';

  @override
  String get topicsOn => 'Enable Topics';

  @override
  String get topicsView => 'Display As';

  @override
  String get topicsViewTabs => 'Tabs';

  @override
  String get topicsViewList => 'List';

  @override
  String get topicsViewInfo => 'Choose how topics appear for all members.';

  @override
  String get topicsList => 'Topics';

  @override
  String get topicsListInfo =>
      'Topic names and icons are encrypted too and go straight from admins\' phones to members\' phones. Only admins can create and close topics.';

  @override
  String get topicGeneral => 'General';

  @override
  String get topicAll => 'All';

  @override
  String get topicNew => 'New Topic';

  @override
  String get topicEdit => 'Edit Topic';

  @override
  String get topicName => 'Topic name';

  @override
  String get topicNameHint => 'e.g. News, Chat, Food';

  @override
  String get topicIcon => 'Icon';

  @override
  String get topicColor => 'Colour';

  @override
  String get topicCreate => 'Create';

  @override
  String get topicDone => 'Done';

  @override
  String get topicClose => 'Close Topic';

  @override
  String get topicReopen => 'Reopen Topic';

  @override
  String get topicClosedBar =>
      'This topic is closed. Only admins can write here.';

  @override
  String get topicHideGeneral => 'Hide General from tabs';

  @override
  String topicMessageIn(Object name) {
    return 'Message in $name';
  }

  @override
  String topicCount(Object n) {
    return '$n topics';
  }

  @override
  String get topicOffInfo =>
      'Turning this off shows every message in one chat. Topics are kept, so turning it on again restores them.';

  @override
  String topicCreated(Object name) {
    return 'Created topic “$name”';
  }

  @override
  String get topicClosedNotice => 'Topic closed';

  @override
  String get topicReopenedNotice => 'Topic reopened';

  @override
  String get topicSwitchBar => 'Move tabs';

  @override
  String get topicNoMessages => 'No messages yet';

  @override
  String get topicNoIcon => 'Letter';

  @override
  String get topicSaved => 'Topic saved';

  @override
  String get topicNameNeeded => 'Type a topic name';

  @override
  String get packDynamic => 'Dynamic pack order';

  @override
  String get packDynamicInfo => 'Packs you used lately come first.';

  @override
  String get packOrderInfo =>
      'Drag the handle to change the order. Packs you turn off leave the sticker panel; stickers you get still show.';

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
  String get chatGuarded => 'Public room · guard checks';

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
  String get camLiveLater =>
      'Live broadcasts open once our own server is ready';

  @override
  String get camGridRemove => 'Tap to remove grid';

  @override
  String get camUnavailable =>
      'Can\'t open the camera\nThe button below uses your phone\'s camera';

  @override
  String get camDualHint =>
      'Takes the back camera, then the front, right after';

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
  String get storyPollInfo =>
      'Each answer comes to you in a 1:1 chat. Nobody else, not even Burumy, sees who picked what.';

  @override
  String storyOption(int n) {
    return 'Option $n';
  }

  @override
  String get storyPlanWhen => 'When';

  @override
  String get storyPlanPlace => 'Where (optional)';

  @override
  String get storyPlanInfo =>
      'When a friend taps \"I\'m in\", you hear it in your 1:1 chat.';

  @override
  String get storyQuestionInfo =>
      'Answers come to you in 1:1 chats, for you only.';

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
  String get storyWhoInfo =>
      'Only the friends you pick get it, sealed in each chat\'s encryption.';

  @override
  String get storyHowLong => 'How long?';

  @override
  String get storyHowLongInfo =>
      'After that it disappears from friends\' phones and the server.';

  @override
  String storyHoursN(int n) {
    return '$n hours';
  }

  @override
  String get storyArchive => 'My story archive';

  @override
  String get storyArchiveEmpty =>
      'Nothing yet. Stories you share are kept here, on this phone only.';

  @override
  String get storyArchiveWeb => 'The web keeps no archive. Use the phone app.';

  @override
  String get storyArchiveInfo =>
      'On this phone only. Tap to share again, hold to delete.';

  @override
  String get storyNew => 'New story';

  @override
  String get feedTitle => 'Feed';

  @override
  String get feedEmpty => 'No posts yet';

  @override
  String get feedInfo =>
      'Only your 1:1 friends see it. No ads, encrypted end to end.';

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
  String get emergencyRoomMarked =>
      'Opening with the delete password erases this chat';

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
  String get muteSoundOff => 'Mute sound';

  @override
  String get muteSoundOn => 'Turn sound on';

  @override
  String muteFor(String time) {
    return 'Mute for $time';
  }

  @override
  String muteHours(int n) {
    return '$n h';
  }

  @override
  String muteDays(int n) {
    return '$n d';
  }

  @override
  String get muteCustom => 'Choose a time';

  @override
  String get muteUntilTitle => 'Mute until';

  @override
  String muteEndsAt(String time) {
    return 'Back on: $time';
  }

  @override
  String get mutedToast => 'Notifications off';

  @override
  String get unmutedToast => 'Notifications on';

  @override
  String mutedForToast(String time) {
    return 'Notifications off for $time';
  }

  @override
  String mutedUntilToast(String time) {
    return 'Notifications off until $time';
  }

  @override
  String get soundOffToast => 'Notifications will come silently';

  @override
  String get soundOnToast => 'Notification sound is back';

  @override
  String pinnedMany(int n) {
    return 'Pinned $n chats';
  }

  @override
  String unpinnedMany(int n) {
    return 'Unpinned $n chats';
  }

  @override
  String mutedMany(int n) {
    return 'Muted $n chats';
  }

  @override
  String unmutedMany(int n) {
    return 'Unmuted $n chats';
  }

  @override
  String get swipeUnread => 'Unread';

  @override
  String get swipeSettings => 'Chat list swipe';

  @override
  String get swipeToRight => 'Swipe right';

  @override
  String get swipeToLeft => 'Swipe left';

  @override
  String get swipeDefault => 'Default';

  @override
  String get swipeSettingsInfo =>
      'Pick the outer button that shows when you swipe a chat. A full swipe runs it right away.';

  @override
  String get swipeSampleName => 'Burumy';

  @override
  String get swipeSampleText => 'Swipe to tidy up in one move';

  @override
  String get folderDefaultInfo =>
      'The folder in front opens first when the app starts. \'All chats\' can move too.';

  @override
  String get iconBadgeHeader => 'Badge counter';

  @override
  String get iconBadgeChannels => 'Include channels';

  @override
  String get iconBadgeMuted => 'Include muted chats';

  @override
  String get iconBadgeMessages => 'Count unread messages';

  @override
  String get iconBadgeInfo =>
      'The red number on the Chats tab and the app icon. Turn off \'Count unread messages\' to count chats instead. Counted on the phone only; the server never knows.';

  @override
  String get chatsHeaderInfo =>
      'Choose how messages look, replies, stickers and emoji, and the on-device AI features you use in chats.';

  @override
  String get faqHeaderInfo =>
      'Common questions about Burumy. You can read them offline too.';

  @override
  String get devicesHeaderInfo =>
      'See every device signed in to your account. Sign out any device you don\'t recognise right here.';

  @override
  String get languageHeaderInfo =>
      'Pick the app\'s language. Messages in other languages can be translated right in the chat.';

  @override
  String get stickersHeaderInfo =>
      'Set your quick reaction, big emoji and how sticker packs are ordered.';

  @override
  String get birthday => 'Birthday';

  @override
  String get birthdayAdd => 'Add';

  @override
  String get birthdayInfo =>
      'Friends see only the month and day. Choose who sees it in Settings > Privacy and Security.';

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
  String get whoCardInfo =>
      '\'My contacts\' never goes to the server; friends get it only inside your encrypted 1:1 chats.';

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
  String get editHistoryInfo =>
      'People see only the last version of a message you edited. Burumy never shows earlier versions.';

  @override
  String get birthdayAlert => 'Birthday alerts';

  @override
  String get birthdayAlertInfo =>
      'On a friend\'s birthday (if they share it), you get an alert at 9 am. It\'s made on this phone only.';

  @override
  String birthdayAlertTitle(String name) {
    return 'It\'s $name\'s birthday today';
  }

  @override
  String get birthdayAlertBody => 'Send them a message.';

  @override
  String get showErrors => 'Show error details';

  @override
  String get showErrorsInfo =>
      'When on, error details are kept on this phone so you can copy them when asking for help. No message content is included.';

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
  String get autoDeleteInfo =>
      'If you don\'t come back at least once in this time, your account is deleted with all groups, messages and contacts.';

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
  String get veilAllSub => 'Messages in a chat show only while you hold them';

  @override
  String get veilList => 'Hide chat list previews';

  @override
  String get veilListSub =>
      'Last messages in the list show only while you hold them';

  @override
  String get panicSub => 'Double-tap with two fingers to lock at once';

  @override
  String get birthdayAlertSub =>
      'This phone reminds you at 9 am on a friend\'s birthday';

  @override
  String get showErrorsSub => 'Keeps error details on this phone for support';

  @override
  String get autoDeleteSub =>
      'Your account is deleted if you don\'t sign in for this long';

  @override
  String get autoDlPhotosSub => 'Photos load on their own';

  @override
  String get autoDlReset => 'Reset auto-download';

  @override
  String get mediaAndLinks => 'Media and links';

  @override
  String get autoplayGifSub => 'Off: GIFs stay on the first frame';

  @override
  String get linkPreviewSub =>
      'Your phone adds the title and picture when sending';

  @override
  String get callsHeader => 'Calls';

  @override
  String get lowDataCalls => 'Use less data for calls';

  @override
  String get lowDataCallsSub =>
      'Lower video quality so calls hold up on slow networks';

  @override
  String get devicesArtInfo => 'Keep chatting on a PC or another phone.';

  @override
  String get addDevice => 'Add a device';

  @override
  String get addDeviceTitle => 'Use on another device';

  @override
  String get addDeviceStep1 =>
      'Install Burumy on the new device. There\'s a Windows app for PCs.';

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
  String get foldersArtInfo =>
      'Make folders for different groups of chats and switch between them from the top of the list or the side menu.';

  @override
  String get createFolder => 'Create a Folder';

  @override
  String get allChatsFolder => 'All Chats';

  @override
  String get editList => 'Edit';

  @override
  String get foldersEditInfo =>
      'Tap Edit to change the order of folders or delete them.';

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
  String get folderTagsInfo =>
      'Show folder names as coloured tags under each chat in the list.';

  @override
  String folderChatsCount(int n) {
    return '$n chats';
  }

  @override
  String get folderDeleted => 'Folder deleted';

  @override
  String get folderInclude => 'Included Chats';

  @override
  String get folderIncludeInfo =>
      'Choose chats or types of chats that will appear in this folder.';

  @override
  String get folderExclude => 'Excluded Chats';

  @override
  String get folderExcludeInfo =>
      'Choose chats or types of chats that will never appear in this folder.';

  @override
  String get folderAddChats => 'Add Chats';

  @override
  String get folderColor => 'Folder Color';

  @override
  String get folderNoTag => 'No tag';

  @override
  String get folderColorInfo =>
      'This colour is used for the folder\'s tag in the chat list.';

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
  String get folderIconFavourites => 'Folder picks';

  @override
  String get folderIconOnly => 'Show icon only';

  @override
  String get folderIconOnlyInfo =>
      'The folder tab above the chat list shows only the emoji.';

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
  String get linkOpenInfo =>
      'Inside Burumy, links open without leaving the app and stay out of your other browser\'s history.';

  @override
  String get linkNeverHeader => 'Never Open in App';

  @override
  String get linkNeverAdd => 'Add Website';

  @override
  String get linkNeverInfo =>
      'These websites always open in your default browser.';

  @override
  String get tiltMove => 'Move When Tilted';

  @override
  String get tiltInfo =>
      'Tilt the phone and the chat background moves a little. Uses a bit more battery.';

  @override
  String get appIcon => 'App Icon';

  @override
  String get appIconInfo =>
      'Changes the Burumy icon on your home screen. The app may close for a moment while it changes.';

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
  String get aiOnPhoneInfo =>
      'All of this runs on this phone. Messages are never sent anywhere.';

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
  String get archiveMovedBody =>
      'Tap the menu button at the top left to see it.';

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

  @override
  String get trustOfficial => 'Official account';

  @override
  String get trustOfficialInfo => 'An official account checked by Burumy';

  @override
  String get trustChecking => 'Under review';

  @override
  String get trustFake => 'Fake';

  @override
  String trustNotOfficial(String name) {
    return 'Not the official account of $name';
  }

  @override
  String get trustCheckingInfo =>
      'Several people reported this account for pretending to be someone. Our team is checking it.';

  @override
  String get trustFakeInfo =>
      'Our team found this account pretends to be someone else. Don\'t send money or codes.';

  @override
  String get firstTitle => 'First message from someone new';

  @override
  String get firstJoined => 'Joined';

  @override
  String get ageWeek => 'This week';

  @override
  String get ageMonth => 'This month';

  @override
  String get ageYear => 'This year';

  @override
  String get ageOlder => 'Over a year ago';

  @override
  String get ageUnknown => 'Unknown';

  @override
  String get firstRenamed => 'Name change';

  @override
  String get firstRenamedRecent => 'Changed in the last 7 days';

  @override
  String get firstRenamedNo => 'None recently';

  @override
  String get firstCommon => 'Chats in common';

  @override
  String firstCommonCount(int count) {
    return '$count';
  }

  @override
  String get firstVerified => 'Official check';

  @override
  String get firstVerifiedYes => 'Yes';

  @override
  String get firstVerifiedNo => 'No';

  @override
  String get firstTip =>
      'If you don\'t know them, never send money, codes or passwords.';

  @override
  String get firstAccept => 'Accept';

  @override
  String get firstBlock => 'Block';

  @override
  String get firstReport => 'Report';

  @override
  String get firstMediaHidden => 'Accept to see it';

  @override
  String get reportImpersonation => 'Pretending to be someone';

  @override
  String get reportImpTitle => 'Report impersonation';

  @override
  String get reportImpInfo =>
      'Tell us about an account that pretends to be someone else. Only the profile goes to our team, never your chats.';

  @override
  String get reportImpWho => 'Who are they pretending to be?';

  @override
  String get reportImpWhoHint => 'Name or ID';

  @override
  String get reportImpNote => 'Anything else (optional)';

  @override
  String get reportImpSend => 'Report';

  @override
  String get reportImpDone => 'Reported. Our team will check it.';

  @override
  String get badgeRow => 'Official badge';

  @override
  String get badgeTitle => 'Official badge';

  @override
  String get badgeInfo =>
      'Public figures, companies and big channels get a badge next to their name so nobody can pretend to be them. We never ask for ID papers.';

  @override
  String get badgeStep =>
      'Post the code below on your official Instagram, YouTube or website for a short while, or send it from your company e-mail, then tell us where.';

  @override
  String get badgeCode => 'Code';

  @override
  String get badgeCopy => 'Copy';

  @override
  String get badgeCopied => 'Copied';

  @override
  String get badgeKind => 'Type';

  @override
  String get badgeKindPerson => 'Person';

  @override
  String get badgeKindBrand => 'Company or brand';

  @override
  String get badgeKindChannel => 'Channel';

  @override
  String get badgeName => 'Name on the badge';

  @override
  String get badgeProof => 'Where you posted it (link or e-mail)';

  @override
  String get badgeSend => 'Apply';

  @override
  String get badgeSent =>
      'Sent. Once it\'s checked, the badge shows next to your name.';

  @override
  String get badgeHave => 'You have the official badge';

  @override
  String get badgeRenameNote =>
      'Changing your name turns the badge off until it\'s checked again.';

  @override
  String get badgeFailed =>
      'You can\'t apply right now. Please try again later.';

  @override
  String get nameMarkRefused => 'Names can\'t have check marks in them';

  @override
  String get nameReservedRefused =>
      'This name has words only official accounts can use';

  @override
  String get idReservedRefused =>
      'This ID is reserved. If it\'s yours, sign up with another ID and apply for the official badge.';

  @override
  String get idLookalikeRefused =>
      'This ID looks too much like an official account. Please pick another.';

  @override
  String get accountsAdd => 'Add account';

  @override
  String get accountsLimitTitle => 'More accounts';

  @override
  String get accountsLimitInfo =>
      'One account is free. Plus includes a second one, and a third can be bought. Payments open after launch.';

  @override
  String get accountsAlready => 'This account is already on this phone';

  @override
  String get accountPassword => 'Account erase password';

  @override
  String get accountPasswordInfo =>
      'Opened with this password, the chosen accounts quietly leave this phone and only the others open. Their accounts stay on the server, so friends see nothing, and you can sign in again later with the ID and backup password.';

  @override
  String get accountEraseList => 'Accounts to erase';

  @override
  String get accountEraseListInfo =>
      'You can\'t choose every account; one must stay.';

  @override
  String get editFirstWords => 'Originally sent';

  @override
  String get reportIllegal => 'Illegal sexual images (incl. AI-made)';

  @override
  String get reportHiddenNow =>
      'Enough reports: this message is now hidden for everyone';

  @override
  String get reportHiddenLine =>
      'Hidden after reports or an automatic check. Our team is checking it.';

  @override
  String get guardNotice =>
      'This is a public room anyone can join, so our public room guard filters illegal pictures and spam here. 1:1 chats and private rooms stay end-to-end encrypted.';

  @override
  String newMediaWait(int days) {
    return 'In this group you can send photos, videos and links $days days after joining';
  }

  @override
  String get newMediaHidden =>
      'Photos, videos and links from new members are hidden';

  @override
  String get newMediaTitle => 'New member media limit';

  @override
  String get newMediaInfo =>
      'People who just joined can only write text. Stops bot accounts from joining and posting harmful pictures.';

  @override
  String get newMediaFooter =>
      'Owners and admins aren\'t limited. Photos, videos and links sent during the limit stay hidden from other members. Public groups start with 7 days.';

  @override
  String newMediaDays(int days) {
    return '$days days';
  }

  @override
  String get toolsSafety => 'Safety';

  @override
  String get toolsSafetyInfo =>
      'Protects against blackmail attacks that hide harmful pictures in old messages and then report the app.';

  @override
  String get lateEditTitle => 'Late edits';

  @override
  String get lateEditInfo =>
      'Messages changed more than an hour after sending show up here. Messages in groups and channels can only be edited for 24 hours, and photos or videos can never be swapped by an edit.';

  @override
  String get lateEditEmpty => 'No late edits';

  @override
  String lateEditLine(String first, String now, String sent, String edited) {
    return 'Before: $first\nNow: $now\nSent $sent · edited $edited';
  }

  @override
  String lateEditBanner(int count) {
    return '$count old messages were edited';
  }

  @override
  String get extortionRow => 'I\'m being blackmailed';

  @override
  String get extortionTitle => 'Report blackmail';

  @override
  String get extortionInfo =>
      'Got a message like \"pay or we\'ll get your group reported\"? Don\'t pay. Tell us: we\'ll block that account and watch this group for illegal posts first. If you feel unsafe, contact the police too.';

  @override
  String get extortionWho => 'Who sent it';

  @override
  String get extortionWhoHint => 'ID (e.g. @abc)';

  @override
  String get extortionNote => 'What they said';

  @override
  String get extortionNoteHint => 'Paste the message as you got it';

  @override
  String get extortionSend => 'Send to our team';

  @override
  String get extortionDone => 'Sent to our team. Please don\'t pay.';

  @override
  String get wipeUser => 'Delete all their messages and ban';

  @override
  String logLateEdit(String name) {
    return '$name edited an old message';
  }

  @override
  String logWiped(String name, int count) {
    return 'Deleted $count messages from $name and banned them';
  }

  @override
  String logExtortion(String name) {
    return 'Reported blackmail ($name)';
  }

  @override
  String get linkTitle => 'Invite link';

  @override
  String get linkKind => 'Link type';

  @override
  String get linkPrivate => 'Private link';

  @override
  String get linkPublic => 'Public address';

  @override
  String get linkPrivateInfo =>
      'Only people who get the link can join. The code in the link is never kept on the server.';

  @override
  String get linkPublicInfo =>
      'Anyone can join by the address. Pasted links show a card with the name and description.';

  @override
  String get linkAddress => 'Address';

  @override
  String get linkChecking => 'Checking…';

  @override
  String get linkFree => 'This address is free';

  @override
  String get linkTaken => 'This address is taken';

  @override
  String get linkBadAddress =>
      'Start with a small letter, 5–32 characters. Numbers and _ are fine.';

  @override
  String get linkReserved => 'Has a word you can\'t use';

  @override
  String get linkShare => 'Share';

  @override
  String get linkShareText => 'Join us';

  @override
  String get linkApproval => 'Approve new members';

  @override
  String get linkApprovalInfo =>
      'When on, people who come by the link send a request, and an admin lets them in.';

  @override
  String get linkReset => 'Make a new link';

  @override
  String get linkResetInfo =>
      'The current link will stop working. Send the new link again.';

  @override
  String get linkFailed => 'Couldn\'t change the link. Try again in a moment.';

  @override
  String get joinRequests => 'Join requests';

  @override
  String get joinRequestsNone => 'No join requests yet';

  @override
  String get joinRequestsInfo =>
      'Accepted people join right away. Declined people aren\'t told.';

  @override
  String get joinAccept => 'Accept';

  @override
  String get joinDecline => 'Decline';

  @override
  String get posterMake => 'Make a promo image';

  @override
  String get posterTitle => 'Promo image';

  @override
  String get posterTall => 'Tall';

  @override
  String get posterSquare => 'Square';

  @override
  String get posterColor => 'Colour';

  @override
  String get posterSave => 'Save to Photos';

  @override
  String get posterSaved => 'Saved to Photos';

  @override
  String get posterScan => 'Scan with your camera to join';

  @override
  String get posterInfo =>
      'If you make a new link, the QR on older images stops opening.';

  @override
  String get webPage => 'Public web page';

  @override
  String get webPageInfo =>
      'When on, new posts also show on a web page. Web page posts are not encrypted and can show up in search. Turning it off takes them all down.';

  @override
  String get webPageNeedsPublic =>
      'Switch to a public address to turn this on.';

  @override
  String get webPageAddress => 'Web page address';

  @override
  String get webPageOn => 'Turn on the web page?';

  @override
  String get webPageOnBody =>
      'From now on, posts and photos leave encryption and anyone can see them. Older posts are not put up.';

  @override
  String get webPageTurnOn => 'Turn on';

  @override
  String get joinByLink => 'Join by link';

  @override
  String get joinByLinkHint => 'Paste an invite link';

  @override
  String get joinByLinkBad => 'That\'s not an invite link';

  @override
  String get joinPublicChannel => 'Public channel';

  @override
  String get joinPublicGroup => 'Public group';

  @override
  String get joinPrivateChannel => 'Private channel';

  @override
  String get joinPrivateGroup => 'Private group';

  @override
  String get joinSubscribe => 'Subscribe';

  @override
  String get joinGroup => 'Join';

  @override
  String get joinAsk => 'Send a join request';

  @override
  String get joinAsked => 'Request sent. You\'ll join when an admin accepts.';

  @override
  String get joinPrivateNote => 'Members and description show after you join.';

  @override
  String get joinNotFound => 'This link doesn\'t exist or was replaced';

  @override
  String get joinUnnamed => 'Invitation';

  @override
  String get remoteWipe => 'Remote emergency wipe';

  @override
  String get remoteWipeInfo =>
      'If your phone is lost or taken, a trusted friend you chose can send your delete code and the chats on this phone are quietly erased.';

  @override
  String get wipeFriends => 'Trusted friends';

  @override
  String get wipeFriendsPick => 'Pick friends (up to 3)';

  @override
  String get wipeFriendsInfo =>
      'Only friends you have a 1:1 chat with. Tell them your delete code yourself.';

  @override
  String get wipeCode => 'Delete code';

  @override
  String get wipeCodeChange => 'Change delete code';

  @override
  String get wipeCodeInfo =>
      '6 or more characters. Only a scrambled check of it stays on this phone; the server never knows it.';

  @override
  String get wipeCodeRule => 'Use at least 6 characters';

  @override
  String get wipeCodeSaved => 'Delete code saved';

  @override
  String get wipeTwo => 'Needs two friends';

  @override
  String get wipeTwoInfo =>
      'When on, two trusted friends must send the code within 24 hours.';

  @override
  String get wipeLastMsg => 'Last message';

  @override
  String get wipeLastMsgInfo =>
      'Sent to your trusted friends right before the erase. Leave empty to send nothing.';

  @override
  String get wipeLastMsgHint =>
      'e.g. I lost my phone. I\'ll reach out from a new one.';

  @override
  String get savedShort => 'Saved';

  @override
  String get decoyTip =>
      'Tip: keep a second, rarely used account (a decoy). If someone forces you to open the app, you can show that one.';

  @override
  String daysN(int n) {
    return '$n days';
  }

  @override
  String get idleWipe => 'Erase after no use';

  @override
  String get idleWipeInfo =>
      'If you don\'t open the app for this long, every chat is erased before anything shows the next time it opens. A plain reminder comes a day before.';

  @override
  String get idleReminderTitle => 'Burumy';

  @override
  String get idleReminderBody => 'It\'s been a while. Take a look?';

  @override
  String get wipeRequest => 'Ask for an emergency wipe';

  @override
  String wipeRequestInfo(String name) {
    return 'Enter the delete code $name gave you and the chats on their phone are erased. Works only if they chose you as a trusted friend.';
  }

  @override
  String get wipeRequestNote =>
      'The request is end-to-end encrypted. You aren\'t told whether the code was right.';

  @override
  String get wipeRequestSend => 'Send wipe request';

  @override
  String get wipeRequestSent => 'Request sent';

  @override
  String get wipeTrustOn => 'Make a trusted wipe friend';

  @override
  String get wipeTrustOff => 'Remove as trusted wipe friend';

  @override
  String get wipeTrustAdded => 'Added. Set your delete code in Settings too.';

  @override
  String get wipeTrustRemoved => 'Removed';

  @override
  String get wipeFriendsFull => 'Up to 3 trusted friends';

  @override
  String get emergencyHeader => 'Lock and emergency';

  @override
  String get autoLock => 'Auto-lock';

  @override
  String get autoLockInfo =>
      'After you leave the app for this long, it asks for the password again. Only when the app lock is on.';

  @override
  String get autoLockNow => 'Right away';

  @override
  String get autoLock1m => 'After 1 minute';

  @override
  String get autoLock5m => 'After 5 minutes';

  @override
  String get autoLock1h => 'After 1 hour';

  @override
  String get protect => 'Restrict saving content';

  @override
  String get protectInfo =>
      'When on, nobody can forward, save or copy here, and screenshots are blocked. iPhone covers the screen while recording.';

  @override
  String get protectOn => 'Restrict saving content';

  @override
  String get protectOff => 'Allow saving content';

  @override
  String get protectOnDone =>
      'Forwarding, saving, copying and screenshots are now blocked here';

  @override
  String get protectOffDone => 'Saving content is allowed again';

  @override
  String get idReservedOwner =>
      'This ID is held for its real owner. If it\'s yours, enter the code from \'Get a reserved ID\'.';

  @override
  String get roomReservedOwner =>
      'This name belongs to a company, organisation or famous person, so it needs their official badge to be a channel name';

  @override
  String get idReservedSale =>
      'IDs of 4 letters or fewer and popular words are given out separately. Enter your code if you have one.';

  @override
  String get claimHaveCode => 'I have a code';

  @override
  String get claimCodeHint => 'Code (starts with BRM-)';

  @override
  String get claimCodeHelp =>
      'The code we emailed you for this ID. It works once, within 30 days.';

  @override
  String get claimCodeWrong =>
      'That code is wrong or already used. Check the ID and code in your email.';

  @override
  String ruleSecs(int n) {
    return '$n s';
  }

  @override
  String ruleMins(int n) {
    return '$n min';
  }

  @override
  String ruleHours(int n) {
    return '$n h';
  }

  @override
  String get permText => 'Send messages';

  @override
  String get permMedia => 'Photos, videos, files';

  @override
  String get permSticker => 'Stickers and GIFs';

  @override
  String get permPoll => 'Polls';

  @override
  String get permLink => 'Links';

  @override
  String get permInvite => 'Add members';

  @override
  String get permPin => 'Pin messages';

  @override
  String get permInfo => 'Change group info';

  @override
  String get rightInfo => 'Change group info';

  @override
  String get rightDelete => 'Delete others\' messages';

  @override
  String get rightBan => 'Remove and ban members';

  @override
  String get rightInvite => 'Invite links';

  @override
  String get rightPin => 'Pin messages';

  @override
  String get rightMute => 'Stop members writing';

  @override
  String get rightAddAdmin => 'Add admins';

  @override
  String get memberPerms => 'Member permissions';

  @override
  String get memberPermsHeader => 'What members can do';

  @override
  String get memberPermsInfo =>
      'Switched off, plain members can\'t use it. The owner and admins always can.';

  @override
  String get adminRights => 'Admin rights';

  @override
  String get adminRightsInfo =>
      'Pick what this admin can do. Only the owner can hand over the group or delete it.';

  @override
  String get slowMode => 'Slow mode';

  @override
  String get slowModeInfo =>
      'Members wait this long between messages. The owner and admins aren\'t limited.';

  @override
  String get memberTag => 'Member tag';

  @override
  String get memberTagInfo =>
      'A short word next to the name (up to 16 characters). Leave empty to remove it.';

  @override
  String get memberTagHint => 'e.g. Designer';

  @override
  String get muteMember => 'Stop writing for…';

  @override
  String get unmuteMember => 'Let them write again';

  @override
  String get muteFor1h => '1 hour';

  @override
  String get muteFor1d => '1 day';

  @override
  String get muteFor7d => '7 days';

  @override
  String get muteForever => 'Until I lift it';

  @override
  String get mutedRole => 'Muted';

  @override
  String get mutedForever => 'An admin stopped your messages in this chat';

  @override
  String mutedUntil(String time) {
    return 'An admin stopped your messages until $time';
  }

  @override
  String get handover => 'Hand over ownership';

  @override
  String handoverTitle(String name) {
    return 'Hand ownership to $name';
  }

  @override
  String get handoverInfo =>
      'You\'re both owners for the days you pick. Then you tap \'Finish handover\' and become an admin. They can say no.';

  @override
  String handoverPending(String name, String time) {
    return 'Handing ownership to $name. You can finish from $time.';
  }

  @override
  String handoverIncoming(String time) {
    return 'You\'ve been made owner. Until $time you share it with the previous owner.';
  }

  @override
  String get handoverFinish => 'Finish handover';

  @override
  String get handoverDecline => 'Don\'t take ownership';

  @override
  String logMuted(String name) {
    return 'Stopped $name writing';
  }

  @override
  String logUnmuted(String name) {
    return 'Let $name write again';
  }

  @override
  String logHandover(String name) {
    return 'Started handing ownership to $name';
  }

  @override
  String get toolsMembers => 'Members';

  @override
  String get permBlocked => 'Only admins can send this here';

  @override
  String slowWait(int n) {
    return 'Slow mode: you can send again in $n s';
  }

  @override
  String get mentionAll => '@all';

  @override
  String get mentionAllInfo => 'Notify every member of this chat';

  @override
  String get mentionAllAdmins =>
      'In chats with 33 or more members only admins can use @all';

  @override
  String get videoLabel => 'Video';

  @override
  String videoResumed(String time) {
    return 'Resumed at $time';
  }

  @override
  String get videoFromStart => 'From start';

  @override
  String get videoSpeedTitle => 'Playback speed';

  @override
  String get videoNoteHoldHint =>
      'Tap to record, tap again to send. Or hold, and let go to send';

  @override
  String get videoNoteSlideHint => 'Slide ↑ to lock · ← to discard';

  @override
  String get videoNoteLocked => 'Locked · tap ■ to send';

  @override
  String get autoSaveTitle => 'Save to Photos';

  @override
  String get autoSaveInfo =>
      'Photos and videos you receive go to the phone\'s Photos app. Saved copies live outside Burumy, so this starts off. View-once media and chats with sharing off are never saved.';

  @override
  String get autoplayVideo => 'Autoplay videos';

  @override
  String get autoplayVideoSub =>
      'Downloaded videos play silently in the chat. Tap the speaker for sound';

  @override
  String get videoQualityTitle => 'Quality';

  @override
  String get videoQualityAuto => 'Auto';

  @override
  String get videoQualityOriginal => 'Original';

  @override
  String get videoQualityLightShort => 'Light';

  @override
  String videoQualityLight(int height) {
    return 'Light ${height}p';
  }

  @override
  String get videoSendQuality => 'Video quality';

  @override
  String get videoQualityAbout => 'approx.';

  @override
  String get videoQualitySmall => 'Smaller';

  @override
  String get videoQualityHigh => 'Sharper';

  @override
  String get videoLightCopy => 'Also send a light copy';

  @override
  String get videoLightCopySub => 'People saving data can watch it at 480p';

  @override
  String get videoQualityWebNote =>
      'The web sends the original. The phone app sends it at this size.';

  @override
  String get dlWaiting => 'Waiting';

  @override
  String get dlPaused => 'Paused';

  @override
  String get dlFirst => 'Download first';

  @override
  String get dlPause => 'Pause';

  @override
  String get dlResume => 'Resume (from the start)';

  @override
  String get dlStop => 'Stop downloading';

  @override
  String get docOpenOther => 'Open in another app';

  @override
  String get docOpenOtherWarn =>
      'The other app can read this file. It leaves Burumy\'s encryption.';

  @override
  String get docOpenOtherGo => 'Open';

  @override
  String get docNoInApp => 'Burumy can\'t show this file itself';

  @override
  String get docNoInAppHint =>
      'PDFs, text files and photos open right here. Open this one in another app.';

  @override
  String get docProtectedNoShare =>
      'Sharing is off in this chat, so it can\'t go to another app';

  @override
  String get docSearch => 'Find in document';

  @override
  String get docSearchNone => 'None';

  @override
  String docPage(int page, int pages) {
    return 'Page $page of $pages';
  }

  @override
  String docTabsMore(String name, int count) {
    return '$name and $count more';
  }

  @override
  String get docTabsTitle => 'Open files';

  @override
  String get docTabsCloseAll => 'Close all';

  @override
  String get docFailed => 'Couldn\'t open the file';

  @override
  String get docTextCut => 'Long file: only the start is shown';

  @override
  String get videoSpeedNormal => 'Normal';

  @override
  String videoSkipSeconds(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get dlChatDm => '1:1 chats';

  @override
  String get dlOff => 'Off';

  @override
  String dlUpToMb(int mb) {
    return 'up to $mb MB';
  }

  @override
  String dlChatsCount(int count) {
    return '$count chat types';
  }

  @override
  String get dlAutoSwitch => 'Download automatically';

  @override
  String get dlKinds => 'What to download';

  @override
  String get dlWhere => 'Download ahead in these chats';

  @override
  String get dlMaxSize => 'Maximum size';

  @override
  String get dlMaxInfo =>
      'Bigger files download when you tap them. So do files of unknown size.';

  @override
  String get dlList => 'Downloads';

  @override
  String get dlListEmpty => 'Nothing downloaded yet';

  @override
  String get dlRunning => 'Downloading';

  @override
  String get dlRecent => 'Recently downloaded';

  @override
  String get dlCancelled => 'Cancelled';

  @override
  String get dlFailed => 'Couldn’t download';

  @override
  String get dlClear => 'Clear list';

  @override
  String get dlListInfo =>
      'Only the list is cleared. Downloaded files are removed after the keep time below.';

  @override
  String get dlTapToGet => 'Tap to download';

  @override
  String get keepTitle => 'Remove downloaded files automatically';

  @override
  String get keepInfo =>
      'Photos, videos and files you downloaded are removed from this device when you haven’t opened them for this long. Chats stay; tap again to download. Downloaded files are encrypted on the device too.';

  @override
  String get keepDay => '1 day';

  @override
  String get keepWeek => '1 week';

  @override
  String get keepMonth => '1 month';

  @override
  String get keepNever => 'Never';

  @override
  String get viewOnceVideo => 'View-once video';

  @override
  String get draftLabel => 'Draft:';

  @override
  String get pinHowLong => 'Pin for how long?';

  @override
  String invitesBlockedRow(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n people blocked invitations',
      one: '1 person blocked invitations',
    );
    return '$_temp0';
  }

  @override
  String invitesBlockedTitle(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n people only accept invitations from contacts',
      one: '1 person only accepts invitations from contacts',
    );
    return '$_temp0';
  }

  @override
  String get invitesBlockedInfo =>
      'They only let their contacts add them to groups and channels. You can send them the invite link in a private chat instead, and they decide whether to join.';

  @override
  String sendInviteLinkN(int n) {
    return 'Send Invite Link $n';
  }

  @override
  String inviteLinkSent(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Invite link sent to $n people',
      one: 'Invite link sent to 1 person',
    );
    return '$_temp0';
  }

  @override
  String get inviteLinkNone =>
      'You can\'t make an invite link here. Ask an admin.';

  @override
  String readAtToday(String time) {
    return 'Read today at $time';
  }

  @override
  String readAtYesterday(String time) {
    return 'Read yesterday at $time';
  }

  @override
  String readAtDate(String date) {
    return 'Read $date';
  }

  @override
  String get shareTitle => 'Share';

  @override
  String get shareAddWord => 'Add a comment';

  @override
  String shareSendN(int n) {
    return 'Send $n';
  }

  @override
  String shareDone(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Forwarded to $n chats',
      one: 'Forwarded to 1 chat',
    );
    return '$_temp0';
  }

  @override
  String get textCopied => 'Text copied';

  @override
  String get copyMsgLink => 'Copy Link';

  @override
  String get msgLinkCopied =>
      'Link copied. Only members of this chat can open it.';

  @override
  String get msgLinkNotMember =>
      'Only members of this chat can open this link.';

  @override
  String get msgLinkGone =>
      'Couldn\'t find the message. It was deleted or is too old.';

  @override
  String pinnedMessageN(int n) {
    return 'Pinned message #$n';
  }

  @override
  String pinnedListTitle(int count) {
    return '$count Pinned Messages';
  }

  @override
  String get pinnedListOpen => 'Show all pinned messages';

  @override
  String get unpinAll => 'Unpin All';

  @override
  String unpinAllAsk(int count) {
    return 'Unpin all $count messages?';
  }

  @override
  String get pinNotifyAll => 'Notify all members';

  @override
  String get pinNotifyInfo =>
      'When on, every member\'s phone gets a notification. When off, it\'s pinned quietly.';

  @override
  String pinLine(String name) {
    return '$name pinned a message';
  }

  @override
  String get pinLineMine => 'You pinned a message';

  @override
  String get pinFor1d => 'A day';

  @override
  String get pinFor1w => 'A week';

  @override
  String get pinFor1m => 'A month';

  @override
  String get pinForever => 'Until I unpin';

  @override
  String get repeatNone => 'Once';

  @override
  String get repeatDay => 'Daily';

  @override
  String get repeatWeek => 'Weekly';

  @override
  String get repeatMonth => 'Monthly';

  @override
  String get tabPolls => 'Polls';

  @override
  String get tabSaved => 'Saved';

  @override
  String get pollClosedShort => 'Closed';

  @override
  String get videoNote => 'Round video';

  @override
  String get videoNoteHint => 'Tap to record up to 1 minute, tap again to send';

  @override
  String get cameraUnavailable => 'Can\'t turn on the camera';

  @override
  String get saveToGallery => 'Save to Photos';

  @override
  String get savedToGallery => 'Saved to Photos';

  @override
  String get noMemberDm => 'Block member-to-member chats';

  @override
  String get noMemberDmInfo =>
      'When on, regular members of this group can\'t start new 1:1 chats with each other. They can still message admins. Stops strangers from contacting people privately through the group.';

  @override
  String get memberDmBlocked =>
      'A group you\'re both in doesn\'t allow 1:1 chats between members, so this chat can\'t be started.';

  @override
  String get cardFlow => 'Choice flow';

  @override
  String get newFlow => 'New choice flow';

  @override
  String get flowTitleHint => 'e.g. What should we watch tonight?';

  @override
  String get flowTextHint => 'Description (optional)';

  @override
  String get flowStartHint => 'Start button name (blank = \'Start\')';

  @override
  String get flowStart => 'Start';

  @override
  String get flowQuestionHint => 'Write the question';

  @override
  String get flowChoiceHint => 'Choice';

  @override
  String get flowAddChoice => 'Add a choice';

  @override
  String get flowAddQuestion => 'Add a question';

  @override
  String get flowRemoveQuestion => 'Remove this question';

  @override
  String flowResultN(int n) {
    return 'Result $n';
  }

  @override
  String get flowResultTitleHint => 'Result name (e.g. Action movie)';

  @override
  String get flowResultTextHint => 'Result text (optional)';

  @override
  String get flowLinkLabelHint => 'Link button name (optional)';

  @override
  String get flowAddResult => 'Add a result';

  @override
  String get flowRemoveResult => 'Remove this result';

  @override
  String get flowPickNext => 'Where does this choice go?';

  @override
  String flowToQuestion(int n) {
    return 'Question $n';
  }

  @override
  String flowToResult(int n) {
    return 'Result $n';
  }

  @override
  String get flowStats => 'Get result numbers';

  @override
  String get flowStatsInfo =>
      'When someone reaches a result, only its number comes to your phone. Who got which result is never kept, even on your phone; you see counts only.';

  @override
  String get flowInfo =>
      'Each tap turns the card into the next question. Only the person tapping sees it, and their picks never leave their phone. Up to 10 questions, 6 choices each, 8 results.';

  @override
  String get flowNoPath =>
      'No choice leads to a result. Check where the choices go.';

  @override
  String get flowBack => 'Back';

  @override
  String get flowAgain => 'Try again';

  @override
  String get flowShare => 'Share result';

  @override
  String get flowResultLabel => 'Your result';

  @override
  String get flowShared => 'Result sent';

  @override
  String get flowStatsTitle => 'Result numbers';

  @override
  String flowTried(int n) {
    return '$n people got a result';
  }

  @override
  String get flowStatsNone => 'Nobody has reached a result yet';

  @override
  String get flowStatsPrivacy =>
      'Only counts per result are shown. Nobody knows who got which result.';

  @override
  String get flowRevert => 'Revert to start';

  @override
  String flowShareText(String title, String result) {
    return '$title\nMy result: $result';
  }

  @override
  String get welcomeEmptyTitle => 'Create a welcome message';

  @override
  String get welcomeEmptyBody =>
      'Greets new members automatically when they join.\nYou can add one photo or video too.';

  @override
  String get welcomeEditorHint =>
      'New members will see this message when they join.\nTouch and hold to edit or delete it.';

  @override
  String get welcomeOnlyYou => 'Only visible to you';

  @override
  String get joinedGroupLine => 'You joined the group';

  @override
  String get joinedChannelLine => 'You joined the channel';

  @override
  String get welcomeMediaTooBig => 'Photos and videos can be up to 50 MB';

  @override
  String get textsEncrypted =>
      'End-to-end encrypted. The server can\'t read it.';

  @override
  String get welcomeRemoveMedia => 'Remove photo or video';

  @override
  String get welcomeAddHint => 'Welcome message';

  @override
  String get removeContact => 'Remove from contacts';

  @override
  String get removeContactInfo =>
      'They leave your contacts list only; the chat stays. Opening a chat with them again brings them back.';

  @override
  String get tidyChats => 'Tidy up chats';

  @override
  String get tidyChatsInfo =>
      'Groups and channels with no new message for over 6 months. Leave the ones you pick in one go; you have 5 seconds to undo.';

  @override
  String tidyLast(String date) {
    return 'Last message $date';
  }

  @override
  String get tidyNone => 'Nothing to tidy up';

  @override
  String tidyLeave(int n) {
    return 'Leave $n chats';
  }

  @override
  String get noIdSearch => 'Don\'t let people find me by ID';

  @override
  String get noIdSearchInfo =>
      'When on, strangers searching your ID or name won\'t find you. People who share a chat with you, or have your QR code or invite link, still can.';

  @override
  String get liveLabel => 'LIVE';

  @override
  String get liveLabelOff => 'LIVE OFF';

  @override
  String get liveStyleLive => 'Live';

  @override
  String get liveStyleLoop => 'Loop';

  @override
  String get liveStyleBounce => 'Bounce';

  @override
  String get liveStyleOff => 'Live Off';

  @override
  String get liveOnToast => 'Live Photo turned on';

  @override
  String get liveLoopToast => 'Loop turned on';

  @override
  String get liveBounceToast => 'Bounce turned on';

  @override
  String get liveOffToast => 'Live Photo turned off. Sending the photo only';

  @override
  String get livePhoto => 'Live Photo';

  @override
  String get liveReplay => 'Play again';

  @override
  String get aiEditor => 'AI Editor';

  @override
  String get aiTabTranslate => 'Translate';

  @override
  String get aiTabStyle => 'Style';

  @override
  String get aiTabFix => 'Fix';

  @override
  String get aiOriginal => 'Original';

  @override
  String get aiResult => 'Result';

  @override
  String get aiEmojify => 'Emojify';

  @override
  String get aiApply => 'Apply';

  @override
  String aiFromLang(String lang) {
    return 'Original: $lang';
  }

  @override
  String get aiToLang => 'Translate to';

  @override
  String get aiFailed =>
      'The AI couldn\'t answer right now. Try again in a moment.';

  @override
  String get aiRefused => 'The AI can\'t change this text.';

  @override
  String aiTooLong(int count) {
    return 'This is too long. The AI can change up to $count characters.';
  }

  @override
  String get aiPreparing =>
      'Your phone is still getting its AI ready. Try again soon.';

  @override
  String get aiNoChange => 'Nothing to fix.';

  @override
  String get aiHelp =>
      'The AI Editor only uses the AI inside this phone. What you write is never sent anywhere, not even to our server.';

  @override
  String get aiStyleNew => 'New Style';

  @override
  String get aiStyleNameHint => 'Style name (for example, \"Pirate\")';

  @override
  String get aiStyleRulesHint =>
      'How should it write? (for example, \"Write like a pirate. Say \'arr\' a lot.\")';

  @override
  String get aiStyleIconPick => 'Pick one emoji as the icon';

  @override
  String get aiStyleEmpty => 'Fill in the icon, name and instructions.';

  @override
  String aiStyleLong(int name, int rules) {
    return 'Names can have $name characters and instructions $rules.';
  }

  @override
  String get aiStyleBlocked =>
      'These instructions aren\'t allowed. Please word it differently.';

  @override
  String get aiStyleSaveInfo =>
      'Your styles are kept locked in your account settings. The server can\'t read them.';

  @override
  String get aiStyleAdd => 'Add Style';

  @override
  String aiStyleAdded(String name) {
    return 'Style added: $name';
  }

  @override
  String get aiStyleAddedHint =>
      'Tap AI → Style when you write a long message.';

  @override
  String get aiStyleExample => 'Example';

  @override
  String get aiStyleBefore => 'Before';

  @override
  String get aiStyleAfter => 'After';

  @override
  String get aiStyleAnother => 'Another example';

  @override
  String get aiStyleAddInfo =>
      'Add this style to the AI Editor to rewrite your messages like this. Your phone\'s AI just made this example.';

  @override
  String get aiStyleNoAi =>
      'This phone can\'t run the AI Editor, so there\'s no example. You can still keep the style.';

  @override
  String get aiStyleHave => 'You already have this style';

  @override
  String get aiMyStyles => 'My Styles';

  @override
  String get aiMyStylesEmpty =>
      'No styles yet. Tap + on the Style tab of the AI Editor to make one.';

  @override
  String get aiStyleCopyLink => 'Copy Link';

  @override
  String get aiStyleSendInfo =>
      'The style is inside the link itself. It\'s never stored on a server and nobody counts who uses it.';

  @override
  String get aiStyleCard => 'Burumy style';

  @override
  String get aiStyleCardOpen => 'View Style';

  @override
  String get aiEditorSwitch => 'AI Editor';

  @override
  String get aiEditorSwitchSub =>
      'Spelling, style and translate buttons appear for long messages';

  @override
  String get aiNotOnPhone =>
      'This phone has no built-in AI, so the AI Editor is hidden.';

  @override
  String get aiStyleFormal => 'Formal';

  @override
  String get aiStyleShort => 'Short';

  @override
  String get aiStyleFriendly => 'Friendly';

  @override
  String get aiStyleWork => 'Work';

  @override
  String get aiStyleHistoric => 'Historic';

  @override
  String get aiStyleZen => 'Zen';

  @override
  String get aiTryAgain => 'Try again';

  @override
  String get aiLangKo => 'Korean';

  @override
  String get aiLangEn => 'English';

  @override
  String get aiLangJa => 'Japanese';

  @override
  String get aiLangZh => 'Chinese';

  @override
  String get aiLangEs => 'Spanish';

  @override
  String get aiLangVi => 'Vietnamese';

  @override
  String get aiLangRu => 'Russian';

  @override
  String get aiExample1 =>
      'Want to grab dinner this weekend if you are free? How about 7?';

  @override
  String get aiExample2 =>
      'It\'s raining so I\'m just staying home today. What are you up to?';

  @override
  String get aiExample3 => 'I\'m moving next month. Could you help me pack?';

  @override
  String get gateTitle => 'Join helper';

  @override
  String get gateHeader =>
      'When someone asks to join, the helper checks within seconds and lets them in or says no. It can\'t read the chat.';

  @override
  String get gateOn => 'Turn on helper';

  @override
  String get gateOnInfo =>
      'The \'join helper\' account comes into this room. It can only let people in or turn them down; it can\'t post or change settings.';

  @override
  String get gateSafety => 'Safety';

  @override
  String get gateSafetyInfo =>
      'The helper has no encryption keys, so it can\'t receive any message. Our server refuses keys for it. It only sees the name of the person asking and their answers.';

  @override
  String get gateCantRead => 'Can\'t read the chat';

  @override
  String get gateHasKeys => 'It has keys. Turn the helper off';

  @override
  String gateKeyCount(int count) {
    return '$count keys';
  }

  @override
  String get gateQuestions => 'Join questions';

  @override
  String get gateQuestionsInfo =>
      'Asked when someone requests to join. Quiz picks are checked right away and can be changed. Questions and answers aren\'t encrypted, so the server can see them. Don\'t ask for private details. Up to 5.';

  @override
  String gateQuizKind(int count) {
    return 'Quiz · $count choices';
  }

  @override
  String get gateWrittenKind => 'Written answer';

  @override
  String get gateAddQuestion => 'Add question';

  @override
  String get gateEditQuestion => 'Edit question';

  @override
  String get gateQuestionHint => 'Question (e.g. What brings you here?)';

  @override
  String get gateQuizShort => 'Quiz';

  @override
  String get gateChoices => 'Choices';

  @override
  String get gateChoicesInfo =>
      'Tap a circle to mark the right answer. People asking to join never see it.';

  @override
  String gateChoiceHint(int n) {
    return 'Choice $n';
  }

  @override
  String get gateAddChoice => 'Add choice';

  @override
  String get gateWrittenInfo =>
      'The person writes an answer. Admins see it in the request list.';

  @override
  String get gateRemoveQuestion => 'Delete question';

  @override
  String get gateRules => 'Rules';

  @override
  String get gateRulesInfo =>
      'Wrong quiz answers or blocked words: turned down. Accounts confirmed as fake are turned down; ones being checked go to the admins. People turned down may ask again.';

  @override
  String get gateNeedAnswers => 'Turn down empty answers';

  @override
  String get gateWords => 'Blocked words';

  @override
  String get gateWordsInfo =>
      'Names or answers with these words are turned down. One per line, up to 30.';

  @override
  String get gateWordsHint => 'e.g. crypto\nfree money';

  @override
  String get gateAi => 'Check written answers with AI';

  @override
  String get gateAiInfo =>
      'Only written answers go to the AI. It can let people in or pass them to admins, never turn anyone down alone.';

  @override
  String get gateLog => 'Decisions';

  @override
  String get gateLogNone => 'No requests checked yet';

  @override
  String get gateLogInfo =>
      'The last 50. Remove anyone let in by mistake from the member list; anyone turned down by mistake can ask again.';

  @override
  String get gateWhyOk => 'Passed every question';

  @override
  String get gateWhyAi => 'AI checked the answers';

  @override
  String get gateWhyQuiz => 'Wrong quiz answer';

  @override
  String get gateWhyEmpty => 'Left an answer empty';

  @override
  String get gateWhyWords => 'Blocked word';

  @override
  String get gateWhyFake => 'Confirmed fake account';

  @override
  String get gateWhyChecking => 'Account being checked';

  @override
  String get gateWhyHeld => 'Needs an admin';

  @override
  String get gateIn => 'Let in';

  @override
  String get gateOut => 'Turned down';

  @override
  String get gateHeld => 'For admins';

  @override
  String get gateSending => 'Sending your request';

  @override
  String get gateYoureIn => 'You\'re in';

  @override
  String gateYoureInBody(String name) {
    return 'You passed the questions of $name';
  }

  @override
  String get gateNotIn => 'Not this time';

  @override
  String get gateNotInBody => 'Check your answers and ask again later';

  @override
  String get gateFailed => 'Couldn\'t send. Try again';

  @override
  String get gateWaiting => 'Request sent';

  @override
  String get gateWaitingBody =>
      'It shows up in your chats once an admin lets you in';

  @override
  String gateQuizIntro(int count) {
    return 'Answer $count questions to ask to join';
  }

  @override
  String gateStep(int now, int total) {
    return 'Question $now of $total';
  }

  @override
  String get gateTryAgain => 'Not quite. Try again';

  @override
  String get gateAnswerHint => 'Your answer';

  @override
  String get gateAnswersSeenBy =>
      'This room\'s admins and join helper see your answers. They aren\'t encrypted, so leave out private details';

  @override
  String get gateGoToGroup => 'Go to group';

  @override
  String get gateGoToChannel => 'Go to channel';

  @override
  String get gateSend => 'Ask to join';

  @override
  String get gateAnswerAndAsk => 'Answer and ask to join';

  @override
  String get gateHeldNote =>
      'Only requests the helper left for admins stay here';

  @override
  String get community => 'Community';

  @override
  String get communityAdd => 'Add to a community';

  @override
  String get communityIntroBody =>
      'Link several groups and channels together. Members see the other chats in one place and join them right away.';

  @override
  String get communityCreate => 'Create a community';

  @override
  String get communityMine => 'Add to my community';

  @override
  String get communityNew => 'New community';

  @override
  String get communityName => 'Community name';

  @override
  String get communityAbout => 'About (optional)';

  @override
  String get communityCreateBtn => 'Create';

  @override
  String get communityPrivacy =>
      'Our server never learns which chats are linked or what the community is called. Only members\' phones can open it.';

  @override
  String get communityAsOne => 'Show as one chat';

  @override
  String get communityAsOneFooter =>
      'Groups all community chats into one item in the chat list.';

  @override
  String get communityIn => 'Chats you\'re in';

  @override
  String get communityView => 'Chats you can view';

  @override
  String get communityAsk => 'Chats you can ask to join';

  @override
  String get communityHiddenTag => 'Admins only';

  @override
  String get communityAddChat => 'Add a chat to the community';

  @override
  String get communityWhoAdds => 'Who can add chats';

  @override
  String get communityAddAll => 'All members';

  @override
  String get communityAddAllInfo =>
      'Members can add their own groups and channels.';

  @override
  String get communityAddAdmins => 'Only admins';

  @override
  String get communityAddAdminsInfo =>
      'Only admins can add chats. The server itself enforces it.';

  @override
  String get communityAdmins => 'Administrators';

  @override
  String get communityChats => 'Manage chats';

  @override
  String get communityChatsFooter =>
      'Hidden chats are seen only by admins. They are sealed with a separate admin key, so members\' phones can\'t open them.';

  @override
  String get communityHide => 'Hide';

  @override
  String get communityShow => 'Show';

  @override
  String get communityRemoveChat => 'Remove from community';

  @override
  String get communityLeave => 'Leave community';

  @override
  String get communityLeaveInfo =>
      'Your chats stay; only the community stops showing.';

  @override
  String get communityDelete => 'Delete community';

  @override
  String get communityDeleteInfo =>
      'Only the link goes; the groups and channels stay.';

  @override
  String communityRemovingIn(int seconds) {
    return 'Deleting in $seconds s';
  }

  @override
  String communityCardGroup(String name) {
    return 'This group was added to the $name community';
  }

  @override
  String communityCardChannel(String name) {
    return 'This channel was added to the $name community';
  }

  @override
  String get communityOpen => 'View';

  @override
  String get communityJoin => 'Join';

  @override
  String get communityAskBtn => 'Ask';

  @override
  String get communityAskedBtn => 'Asked';

  @override
  String get communityAsked =>
      'Request sent. You\'re in once an admin accepts.';

  @override
  String communityMembers(int count) {
    return '$count members';
  }

  @override
  String communityChatsCount(int count) {
    return '$count chats';
  }

  @override
  String get communityPickTitle => 'Add a chat';

  @override
  String get communityPickEmpty =>
      'No groups or channels to add. You can add chats where you\'re the owner or an admin.';

  @override
  String get communityPickHidden => 'Add hidden (admins only)';

  @override
  String get communityPickFooter =>
      'A chat without a link gets a private link with approval: community members ask, and an admin lets them in.';

  @override
  String get communityAddedToast => 'Added to the community';

  @override
  String get communityNotYet =>
      'You\'ll be in the community shortly, once an admin\'s phone sends you the key.';

  @override
  String get communityEmpty => 'No chats yet';

  @override
  String get communityOnlyAdmins => 'Only admins can do this';

  @override
  String get communityInfo => 'Community info';

  @override
  String get communityAdminsFooter =>
      'Admins can add, hide and remove chats. New admins receive the hidden-chats key.';

  @override
  String get communityMakeAdmin => 'Make admin';

  @override
  String get communityUnmakeAdmin => 'Remove admin';

  @override
  String get communityRoleOwner => 'Owner';

  @override
  String get communityRoleAdmin => 'Admin';

  @override
  String communityLast(String who, String chat) {
    return '$who › $chat';
  }

  @override
  String get searchFilter => 'Find by type';

  @override
  String get kindPhoto => 'Photos';

  @override
  String get kindVideo => 'Videos';

  @override
  String get kindFile => 'Files';

  @override
  String get kindLink => 'Links';

  @override
  String get kindVoice => 'Voice messages';

  @override
  String get keywordReplies => 'Keyword replies';

  @override
  String get keywordRepliesInfo =>
      'When a member\'s message has this word, the answer is posted as a reply in your name. The server can\'t read messages, so this phone answers. Each word is answered at most once a minute.';

  @override
  String get keywordWordHint => 'Word (e.g. fee)';

  @override
  String get keywordAnswerHint => 'Answer (e.g. The fee is 10,000 won a month)';

  @override
  String get pollDescription => 'Description (optional)';

  @override
  String get pollAddPhoto => 'Add photo';

  @override
  String get pollRemovePhoto => 'Remove photo';

  @override
  String get pollAttachTitle => 'Attach to answer';

  @override
  String get pollAttachPhoto => 'Photo';

  @override
  String get pollAttachSticker => 'Sticker';

  @override
  String get pollAttachPlace => 'My current place';

  @override
  String get pollAttachRemove => 'Remove attachment';

  @override
  String get pollAttachInfo =>
      'Each answer can carry one photo, sticker or place. Photos are encrypted on this phone first; places are stored as numbers only, never sent to a map company.';

  @override
  String get pollPickSticker => 'Pick a sticker';

  @override
  String get pollAllowAdd => 'Allow adding answers';

  @override
  String get pollAllowChange => 'Allow changing votes';

  @override
  String get pollShuffle => 'Shuffle answers';

  @override
  String get pollHideResults => 'Hide results until the end';

  @override
  String get pollMoreInfo =>
      'Adding answers: members can add more (12 in total; their name is shown). Shuffle: everyone sees a different order, so the first line doesn\'t get extra votes.';

  @override
  String get pollHideAnonInfo =>
      'In an anonymous poll, hidden results never leave the maker\'s phone before the end. When it ends, that phone posts the numbers.';

  @override
  String get pollHideOpenInfo =>
      'Open-poll votes sit encrypted in the chat on members\' phones; the app keeps the numbers covered until the end.';

  @override
  String get pollNoChangeInfo =>
      'Once chosen, a vote can\'t be changed or taken back.';

  @override
  String get pollAddTitle => 'Add an answer';

  @override
  String get pollAddDone => 'Add';

  @override
  String get pollAddInfo =>
      'Your name is shown on the answer you add. The same answer can\'t be added twice.';

  @override
  String pollAddedBy(String name) {
    return 'added by $name';
  }

  @override
  String get pollHiddenUntilEnd => 'Results show when the poll ends';

  @override
  String get pollViewVotes => 'View votes';

  @override
  String get pollResults => 'Poll results';

  @override
  String pollVotesN(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n votes',
      one: '1 vote',
    );
    return '$_temp0';
  }

  @override
  String get pollNobodyYet => 'Nobody picked this yet';

  @override
  String get pollFinalShort => 'final';

  @override
  String get pollFull => 'A poll can have up to 12 answers';

  @override
  String get pollRepeat => 'That answer is already there';

  @override
  String get pollAnonResultsInfo =>
      'Anonymous poll: nobody can see who chose what, only the numbers.';

  @override
  String get pollChangeVote => 'Change vote';

  @override
  String get articleWrite => 'Write a long post';

  @override
  String get articleExpand => 'Expand';

  @override
  String get articleTitleHint => 'Title';

  @override
  String get articleBodyHint => 'Write something…';

  @override
  String get articleReadAll => 'Read all';

  @override
  String articleMinutes(int n) {
    return '$n min read';
  }

  @override
  String articleChars(int n) {
    return '$n characters';
  }

  @override
  String get articleEncrypted =>
      'End-to-end encrypted. The server can\'t read this post.';

  @override
  String get articleOpenFailed =>
      'Couldn\'t open the post. Please try again later.';

  @override
  String get articleTooLong =>
      'This post is too long. Up to 100,000 characters.';

  @override
  String get articleEmpty => 'There\'s nothing to send.';

  @override
  String get articleSending => 'Sending…';

  @override
  String get articleDiscardAsk => 'What should we do with this post?';

  @override
  String get articleDiscard => 'Discard';

  @override
  String get articleKeepDraft => 'Save draft';

  @override
  String get articleDraftNote => 'Photos aren\'t kept in drafts.';

  @override
  String get articleStyle => 'Style';

  @override
  String get articleInsert => 'Insert';

  @override
  String get blockH1 => 'Heading';

  @override
  String get blockH2 => 'Subheading';

  @override
  String get blockP => 'Text';

  @override
  String get blockQuote => 'Quote';

  @override
  String get blockPull => 'Pull quote';

  @override
  String get blockCode => 'Code';

  @override
  String get blockMath => 'Formula';

  @override
  String get blockUl => 'Bulleted list';

  @override
  String get blockOl => 'Numbered list';

  @override
  String get blockTable => 'Table';

  @override
  String get blockImg => 'Photo';

  @override
  String get blockHr => 'Divider';

  @override
  String get blockRemove => 'Remove block';

  @override
  String get blockUp => 'Move up';

  @override
  String get blockDown => 'Move down';

  @override
  String get articleCaptionHint => 'Caption (optional)';

  @override
  String get articleMathHint => 'Formula (e.g. a^2 + b^2 = c^2)';

  @override
  String get articleCodeHint => 'Code';

  @override
  String get articleLangHint => 'Language (optional)';

  @override
  String get articleItemHint => 'Item';

  @override
  String get tableAddRow => 'Add row';

  @override
  String get tableAddCol => 'Add column';

  @override
  String get tableDelRow => 'Remove last row';

  @override
  String get tableDelCol => 'Remove last column';

  @override
  String get tableHeader => 'First row is a header';

  @override
  String get articleAi => 'AI helper';

  @override
  String get articleAiInfo =>
      'Everything happens on this phone. Your post is never sent anywhere.';

  @override
  String get aiTidy => 'Tidy up';

  @override
  String get aiTidySub =>
      'Turns # headings, - lists, | tables | and \$\$formulas\$\$ into formatting';

  @override
  String get aiPolish => 'Polish with AI';

  @override
  String get aiPolishSub =>
      'Rewrites the selection (or this block) to read better';

  @override
  String get aiShorter => 'Make shorter';

  @override
  String get aiShorterSub => 'Keeps only the key points';

  @override
  String get aiUnavailable =>
      'AI writing isn\'t available on this phone yet. Tidy up still works.';

  @override
  String get aiDone => 'Done. Undo brings the old text back.';

  @override
  String get articleUndo => 'Undo';

  @override
  String get articleRedo => 'Redo';

  @override
  String get roomNight => 'Night mode';

  @override
  String get roomNightInfo =>
      'Members can\'t post during these hours. The owner and admins still can. Hours follow this phone\'s time zone.';

  @override
  String nightRange(int from, int to) {
    return '$from:00–$to:00';
  }

  @override
  String nightBlocked(int hour) {
    return 'Night mode. You can send from $hour:00';
  }

  @override
  String get sendToChannels => 'Post to several channels';

  @override
  String get noOtherChannels => 'No other channels you can post in';

  @override
  String sendToCount(int n) {
    return 'Post to $n channels';
  }

  @override
  String sentToCount(int n) {
    return 'Posted to $n channels';
  }

  @override
  String get raidLock => 'Raid lock';

  @override
  String get raidLockInfo =>
      'Turn on when strangers rush in through a link. While it\'s on, everyone joining by link waits for an admin to let them in. Turning it off puts the link back the way it was.';

  @override
  String get mentionsOnly => 'Only when mentioned';

  @override
  String get mentionsOnlyInfo =>
      'When on, groups only notify you when someone mentions you by name or with @all. Other messages arrive quietly and show as a count in the chat list.';

  @override
  String get messageRequests => 'Message requests';

  @override
  String get messageRequestsEmpty => 'No message requests';

  @override
  String get messageRequestsInfo =>
      '1:1 chats from people who aren\'t in your contacts. They can\'t see that you\'ve read them until you accept.';

  @override
  String get messageRequestBar =>
      'This message is from someone who isn\'t in your contacts. Accept to reply. If you delete it, they won\'t be told.';

  @override
  String get messageRequestAccept => 'Accept';

  @override
  String get messageRequestDelete => 'Delete';

  @override
  String get messageRequestBlock => 'Delete and block';

  @override
  String get messageRequestDeleteInfo =>
      'This chat will be deleted and you\'ll leave it. They won\'t be told.';

  @override
  String get messageRequestsSwitchInfo =>
      'When on, 1:1 chats started by people who aren\'t in your contacts wait in Message requests at the top of your chat list. Until you accept, they stay quiet and no read receipts are sent.';

  @override
  String get nameColor => 'Name color';

  @override
  String get nameColorSample => 'What time is the meetup today?';

  @override
  String get nameColorInfo =>
      'The color of your name above your messages in groups. It\'s the same in every group you\'re in. \'A\' picks a color from your name automatically.';

  @override
  String get roomName => 'My name in this group';

  @override
  String get roomNameHint => 'Name';

  @override
  String get roomNameInfo =>
      'Only people in this group see you by this name. Everywhere else you keep your usual name. Leave it empty to go back to your usual name.';

  @override
  String get liveLocation => 'Live location';

  @override
  String get liveLocationInfo =>
      'For the time you pick, your location moves in the chat every minute. It goes end-to-end encrypted only to people in this chat, and you can stop at any time. It doesn\'t move while the app is closed.';

  @override
  String get live15m => 'Share for 15 minutes';

  @override
  String get live1h => 'Share for 1 hour';

  @override
  String get live8h => 'Share for 8 hours';

  @override
  String get liveLocationEnded => 'Live location (ended)';

  @override
  String liveLeftMinutes(int n) {
    return '$n min left';
  }

  @override
  String liveLeftHours(int n) {
    return '$n h left';
  }

  @override
  String get liveStop => 'Stop sharing';

  @override
  String get editorAuto => 'Auto';

  @override
  String get editorDraw => 'Draw';

  @override
  String get editorText => 'Text';

  @override
  String get editorClearAll => 'Clear all';

  @override
  String get editorAddText => 'Add text';

  @override
  String get penPen => 'Pen';

  @override
  String get penArrow => 'Arrow';

  @override
  String get penMarker => 'Highlighter';

  @override
  String get penNeon => 'Neon';

  @override
  String get penEraser => 'Eraser';

  @override
  String get penBlur => 'Blur';

  @override
  String get editAndSend => 'Edit & send';

  @override
  String photoOf(int n, int total) {
    return '$n of $total';
  }

  @override
  String get videoMutedToast => 'Sound off. It will be sent as a GIF';

  @override
  String get videoSoundToast => 'Sound on';

  @override
  String get sendTogether => 'Send together';

  @override
  String get sendSeparately => 'Send separately';

  @override
  String get sendSpoiler => 'Hide with spoiler';

  @override
  String get sendAsFileOriginal => 'Send as file (original quality)';

  @override
  String get albumRecents => 'Recents';

  @override
  String get albumFavorites => 'Favorites';

  @override
  String get albumVideos => 'Videos';

  @override
  String get albumScreenshots => 'Screenshots';

  @override
  String get albumSelfies => 'Selfies';

  @override
  String get albumLive => 'Live Photos';

  @override
  String get newLoginTitle => 'Someone just signed in to your account';

  @override
  String newLoginBody(String device, String when) {
    return '$device · $when. Is it you?';
  }

  @override
  String get newLoginJustNow => 'just now';

  @override
  String get newLoginYes => 'Yes, it\'s me';

  @override
  String get newLoginNo => 'No, it\'s not me';

  @override
  String get newLoginOut => 'Log out this device';

  @override
  String newLoginOutDone(String device) {
    return '$device was logged out';
  }

  @override
  String get newLoginChangePw =>
      'Change your password too, so they can\'t sign in again.';

  @override
  String get later => 'Later';

  @override
  String get ok => 'OK';

  @override
  String get deviceUnnamed => 'Unnamed device';

  @override
  String get deleteForMeOnly => 'Delete for me only';

  @override
  String get deleteForBothShort => 'Delete for both of us';

  @override
  String deleteForMeAnd(String name) {
    return 'Delete for me and $name';
  }

  @override
  String get dateWipeTitle => 'Delete by date';

  @override
  String get dateWipeHint =>
      'Tap a day, or two days to pick everything between. Bold days have messages.';

  @override
  String get dateWipePick => 'Pick a day';

  @override
  String dateWipeButton(String range, int count) {
    return 'Delete $count from $range';
  }

  @override
  String dateWipeAsk(int count) {
    return 'Delete $count messages?';
  }

  @override
  String dateWipeIn(int left) {
    return 'Deleting in ${left}s';
  }

  @override
  String get dateWipeMenu => 'Delete by date';

  @override
  String get voiceBlockedLine =>
      'Voice message (from someone you don\'t take them from)';

  @override
  String get voiceClosedTitle => 'Can\'t send voice messages';

  @override
  String voiceClosedBody(String name) {
    return '$name doesn\'t take voice and video messages. You can still send text and photos.';
  }

  @override
  String get whoVoice => 'Voice and video messages';

  @override
  String get whoVoiceInfo =>
      'Only the people you pick can send you voice messages and round videos in 1:1 chats. Their mic button looks dimmed.';

  @override
  String get strangerArchive => 'Archive chats from strangers';

  @override
  String get strangerArchiveSub =>
      'First messages from people who aren\'t your friends go to Archive, muted.';

  @override
  String get strangerTucked => 'A new chat from a stranger went to Archive';

  @override
  String get callsEdit => 'Edit';

  @override
  String get callsSelect => 'Select';

  @override
  String get callsClearAll => 'Clear call history';

  @override
  String callsDeleteN(int count) {
    return 'Delete ($count)';
  }

  @override
  String callsDeleteAsk(int count) {
    return 'Delete $count calls?';
  }

  @override
  String callsDeleteIn(int left) {
    return 'Deleting calls in ${left}s';
  }

  @override
  String get callsDeleteBothNote =>
      'Deleting for both removes them from their phone too.';

  @override
  String get deviceSheetCalls => 'Take calls on this device';

  @override
  String get deviceSheetCallsSub =>
      'When off, calls don\'t ring on this device.';

  @override
  String get deviceSheetOut => 'Log out this device';

  @override
  String get deviceSheetLastSeen => 'Last used';

  @override
  String get deviceSheetKind => 'Kind';

  @override
  String get deviceKindPhone => 'Phone';

  @override
  String get deviceKindPc => 'Computer';

  @override
  String get deviceKindWeb => 'Web';

  @override
  String get deviceIdleTitle => 'Log out idle devices';

  @override
  String get deviceIdleInfo =>
      'Devices not used for this long are logged out by our server. Protects against a lost phone or a login left on someone else\'s PC.';

  @override
  String get deviceIdleOff => 'Never';

  @override
  String get idleDays7 => '1 week';

  @override
  String get idleDays30 => '1 month';

  @override
  String get idleDays90 => '3 months';

  @override
  String get idleDays180 => '6 months';

  @override
  String get idleDays365 => '1 year';

  @override
  String get linkPc => 'Link a PC with QR';

  @override
  String get linkPcInfo =>
      'Scan the QR on Burumy for PC with this phone to sign in there without a password.';

  @override
  String get linkPcScanTitle => 'Scan the QR on your PC';

  @override
  String get linkPcStep1 => 'Open Burumy on your PC.';

  @override
  String get linkPcStep2 => 'Choose \'Sign in with QR\' on the sign-in screen.';

  @override
  String get linkPcStep3 => 'Point this screen at the QR on your PC.';

  @override
  String get linkPcConfirmTitle => 'Sign in on this PC?';

  @override
  String linkPcConfirmBody(String device) {
    return '$device. Only continue if you opened this screen yourself right now. Never scan a QR someone sent you.';
  }

  @override
  String get linkPcConfirm => 'Sign in';

  @override
  String get linkPcDone =>
      'Signed in on the PC. Finish the emoji check there to see past chats.';

  @override
  String get linkPcBad => 'That\'s not a Burumy PC sign-in QR';

  @override
  String get linkPcExpired => 'The QR has expired. Show a new one on the PC.';

  @override
  String get linkPcNoCamera => 'This device can\'t scan. Use the phone app.';

  @override
  String get qrLoginTitle => 'Sign in with QR';

  @override
  String get qrLoginStep1 => 'Open Burumy on your phone.';

  @override
  String get qrLoginStep2 => 'Go to Settings > Devices > Link a PC with QR.';

  @override
  String get qrLoginStep3 => 'Point your phone at this QR.';

  @override
  String get qrLoginWaiting => 'Waiting for your phone…';

  @override
  String get qrLoginNew => 'New QR';

  @override
  String get qrLoginPassword => 'Sign in with ID and password';

  @override
  String get qrLoginOff => 'QR sign-in isn\'t set up on this server yet.';

  @override
  String get phoneCall => 'Call';

  @override
  String get phoneText => 'Send Text';

  @override
  String get phoneCopy => 'Copy Number';

  @override
  String get phoneSave => 'Save to Phone Contacts';

  @override
  String get phoneCopied => 'Number copied';

  @override
  String get videoNoteOnceHint =>
      'View once: it disappears after they watch it';

  @override
  String get onceRoundSent => 'View once';

  @override
  String get onceRoundExpired => 'Expired video message';

  @override
  String get onceRoundClose => 'Close and delete';

  @override
  String get storyScrubHint => 'Slide left or right to move';

  @override
  String get camFlashWarm => 'Warmth';

  @override
  String get camFlashBright => 'Brightness';

  @override
  String get camFlashFront =>
      'With the front camera, the screen lights up in this colour';

  @override
  String birthdayBannerOne(String name) {
    return 'It\'s $name\'s birthday today!';
  }

  @override
  String birthdayBannerMany(int n) {
    return '$n friends have a birthday today!';
  }

  @override
  String get birthdayBannerSub => 'Tap to send your wishes';

  @override
  String birthdayTodayLine(String date) {
    return 'Birthday today 🎂 · $date';
  }

  @override
  String get firstHelloTitle => 'No messages here yet';

  @override
  String get firstHelloSub => 'Tap the greeting below to say hi';

  @override
  String firstHelloTap(String name) {
    return 'Tap to say hi to $name';
  }

  @override
  String get liveTextButton => 'Text';

  @override
  String get liveTextTitle => 'Text in photo';

  @override
  String get liveTextHint => 'Tap lines to pick them, or copy all';

  @override
  String liveTextPicked(int n) {
    return '$n lines picked';
  }

  @override
  String get liveTextNoneSel => 'Deselect';

  @override
  String get liveTextCopied => 'Text copied';

  @override
  String get liveTextPaste => 'Hold the message box to paste';

  @override
  String get liveTextNone => 'No text found in this photo';

  @override
  String get liveTextAll => 'Select All';

  @override
  String get callNoteAsk => 'No answer. Leave a message?';

  @override
  String get callNoteVoice => 'Voice';

  @override
  String get callNoteVideo => 'Video';

  @override
  String callNoteTo(String name) {
    return 'Message for $name';
  }

  @override
  String get callNoteVoiceHint => 'Tap to record. Tap again to send.';

  @override
  String get idKey => 'ID key';

  @override
  String get idKeyMine => 'My key';

  @override
  String get idKeyHint => 'e.g. blue7';

  @override
  String get idKeyInfo =>
      'With a key, people chatting with you for the first time need your ID and this key. Without the right key nothing arrives, and the sender isn\'t told. Friends and people you already talk with aren\'t asked. The key stays on this phone and never goes to the server. 4–20 letters or digits.';

  @override
  String get idKeyBad => 'Use 4–20 letters or digits.';

  @override
  String get idKeyOff => 'Turn off key';

  @override
  String get idKeyOffInfo => 'When off, first chats that were waiting come in.';

  @override
  String get idKeyEnterHint => 'ID key (if you got one)';

  @override
  String get idKeyEnterInfo =>
      'If they gave you an ID key, add it. It\'s only needed for the first chat.';

  @override
  String get voiceToText => 'Show as text';

  @override
  String get voiceToTextFailed =>
      'This phone can\'t turn it into text. Download the speech language in the phone\'s settings.';

  @override
  String get voiceToTextEmpty => 'No words heard.';

  @override
  String get voiceToTextOnPhone => 'Done on this phone only';

  @override
  String get voiceTranslate => 'Translate';

  @override
  String get voiceTranslating => 'Translating…';

  @override
  String get voiceShowOriginal => 'Hide translation';

  @override
  String unreadSummaryAsk(int count) {
    return 'Summarize $count unread messages';
  }

  @override
  String get unreadSummaryTitle => 'Unread summary';

  @override
  String get unreadSummaryFailed =>
      'Can\'t summarize now. Only text messages are summarized.';

  @override
  String get unreadSummaryOnPhone =>
      'Summarized by this phone\'s AI only. Your chat never leaves the phone.';

  @override
  String get postSummaryButton => 'Summarize';

  @override
  String get postSummaryBusy => 'Summarizing…';

  @override
  String get postSummaryOriginal => 'Show original';

  @override
  String get postSummaryTitle => 'AI summary';

  @override
  String get postSummaryFailed =>
      'Can\'t summarize right now. Try again in a moment.';

  @override
  String get postSummaryOnPhone =>
      'Summarized by this phone\'s AI only. The post never leaves the phone.';

  @override
  String get postSummarySwitch => 'Summarize long posts';

  @override
  String get postSummarySwitchSub =>
      'A \'Summarize\' button above long posts in groups and channels';

  @override
  String get readerButton => 'Reading mode';

  @override
  String get readerMenu => 'Open in reading mode';

  @override
  String get readerLoading => 'Getting the page…';

  @override
  String get readerFailed =>
      'This page can\'t open in reading mode. Try the browser.';

  @override
  String get readerOpenBrowser => 'Open in browser';

  @override
  String get readerTextSize => 'Text size';

  @override
  String readerMinutes(int minutes) {
    return '$minutes min read';
  }

  @override
  String get readerSummaryAsk => 'Summarize with AI';

  @override
  String get readerFootnote =>
      'This phone fetched the page from the site itself and tidied it for reading. Burumy\'s servers never learn what you read.';

  @override
  String get readerLinkCopied => 'Link copied';

  @override
  String get readerSwitch => 'Show \'Reading mode\' on links';

  @override
  String get readerSwitchInfo =>
      'Read article links as clean text without ads or menus. This phone fetches the page itself; nothing goes through Burumy\'s servers.';

  @override
  String get audioPlay => 'Play';

  @override
  String get audioPause => 'Pause';

  @override
  String get audioPrevious => 'Previous';

  @override
  String get audioNext => 'Next';

  @override
  String get audioRepeat => 'Repeat';

  @override
  String get audioRepeatOff => 'Repeat off';

  @override
  String get audioRepeatAll => 'Repeating the whole list';

  @override
  String get audioRepeatOne => 'Repeating this track';

  @override
  String audioPlaylist(int count) {
    return 'Play list · $count';
  }

  @override
  String get audioSpeedTitle => 'Playback speed';

  @override
  String get audioSpeedPlain => 'Normal';

  @override
  String get audioSpeedNormal => 'Playing at normal speed';

  @override
  String audioSpeedSet(String speed) {
    return 'Playing at $speed×';
  }

  @override
  String get protectIntroInfoDm =>
      'In this chat, neither of you can do the following.';

  @override
  String get protectIntroInfoRoom =>
      'Nobody in this chat can do the following.';

  @override
  String get protectIntroShot => 'No screenshots or recordings';

  @override
  String get protectIntroShotSub =>
      'Captures and recordings show a black screen';

  @override
  String get protectIntroForward => 'No forwarding';

  @override
  String get protectIntroForwardSub =>
      'Messages can\'t be sent on to other chats';

  @override
  String get protectIntroSave => 'No saving or copying';

  @override
  String get protectIntroSaveSub =>
      'Photos and videos can\'t be saved, text can\'t be copied';

  @override
  String get protectIntroOnlyMe => 'Only you can turn this off again.';

  @override
  String get protectNoticeMine => 'You disabled sharing in this chat';

  @override
  String protectNoticeOther(String name) {
    return '$name disabled sharing in this chat';
  }

  @override
  String get protectNoticeRoom => 'Sharing is disabled in this chat';

  @override
  String get protectMenuFooter =>
      'Sharing is disabled here: no copying, forwarding or saving';

  @override
  String get protectOnlyOwner =>
      'Only the person who turned it on can turn it off';

  @override
  String get protectByOther => 'Sharing disabled (by them)';

  @override
  String get reportStepTitle => 'What\'s wrong?';

  @override
  String get reportSubTitle => 'Tell us a bit more';

  @override
  String get reportNoteTitle => 'Anything else? (optional)';

  @override
  String get reportNoteHint => 'e.g. they post the same thing in many chats';

  @override
  String get reportSend => 'Report';

  @override
  String get reportUrgentLine => 'The operator looks at this report first';

  @override
  String get reportDislikeInfo =>
      'This doesn\'t go to the operator. On this phone you can:';

  @override
  String get reportDislikeHide => 'Hide this message on my phone';

  @override
  String get reportDislikeBlock => 'Block the sender';

  @override
  String get reportDislikeHidden => 'Hidden on this phone';

  @override
  String get reportCopyrightInfo =>
      'Copyright is claimed by the rights holder. Use the web form with the original and your contact.';

  @override
  String get reportCopyrightOpen => 'Open the rights holder form';

  @override
  String get reportHiddenMsg => 'Message hidden on this phone';

  @override
  String get rDislike => 'I don\'t like it';

  @override
  String get rChild => 'Child abuse';

  @override
  String get rChildSexual => 'Child sexual abuse material';

  @override
  String get rChildAbuse => 'Physical abuse of a child';

  @override
  String get rChildDanger => 'Grooming or approaching a child';

  @override
  String get rSexualCrime => 'Non-consensual or illegal sexual images';

  @override
  String get rHiddenCamera => 'Secretly taken photos or videos';

  @override
  String get rDeepfake => 'Fake (deepfake) photos or videos';

  @override
  String get rSharedNoConsent => 'Shared without consent';

  @override
  String get rExtortion => 'Threats using photos';

  @override
  String get rViolence => 'Violence or threats';

  @override
  String get rThreat => 'Threats to hurt someone';

  @override
  String get rGraphic => 'Graphic violence';

  @override
  String get rSelfHarm => 'Encouraging self-harm or suicide';

  @override
  String get rHate => 'Hate speech';

  @override
  String get rGoods => 'Illegal goods or services';

  @override
  String get rDrugs => 'Drugs';

  @override
  String get rWeapons => 'Weapons';

  @override
  String get rFakeDocs => 'Fake documents or IDs';

  @override
  String get rGoodsOther => 'Other illegal trade';

  @override
  String get rAdult => 'Sexual content';

  @override
  String get rPorn => 'Pornography';

  @override
  String get rUnwanted => 'Unwanted sexual messages';

  @override
  String get rPrivacy => 'Personal data';

  @override
  String get rIdDocs => 'ID cards or ID numbers';

  @override
  String get rContact => 'Phone numbers or addresses';

  @override
  String get rPhotos => 'My photos posted without permission';

  @override
  String get rTerror => 'Terrorism';

  @override
  String get rTerrorPromo => 'Promoting terrorism';

  @override
  String get rTerrorRecruit => 'Planning or recruiting';

  @override
  String get rScam => 'Scam or spam';

  @override
  String get rPhishing => 'Phishing links';

  @override
  String get rMoney => 'Money or investment scam';

  @override
  String get rSpam => 'Spam ads';

  @override
  String get rCopyright => 'Copyright';

  @override
  String get rTakedown => 'Not illegal, but must be taken down';

  @override
  String get firstPhotoChanged => 'Photo changed';

  @override
  String get firstNameChanged => 'Name changed';

  @override
  String firstDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get firstToday => 'Today';

  @override
  String get firstNotChanged => 'Not in 30 days';

  @override
  String get firstGroupsTitle => 'Groups in common';

  @override
  String get firstGroupsNone => 'None';

  @override
  String get firstAboutTitle => 'New contact';

  @override
  String get ageQuarter => '1–3 months ago';

  @override
  String get ageHalf => '3–12 months ago';

  @override
  String get firstNotFriend => 'Not in your friends';

  @override
  String get onceVoice => 'One-time voice message';

  @override
  String get onceVoiceTap => 'Tap to listen once';

  @override
  String get onceVoiceSent => 'Can be played once';

  @override
  String get onceVoiceExpired => 'Expired voice message';

  @override
  String get onceVoiceOn => 'One-time: it disappears after one listen';

  @override
  String get onceVoiceOff => 'One-time off';

  @override
  String get onceVoiceHint => 'Tap to make it play only once';

  @override
  String get onceVoiceClose => 'Close and delete';

  @override
  String get onceVoiceInfo =>
      'It disappears after this. It can\'t be saved or forwarded.';

  @override
  String get permMediaAll => 'Send media';

  @override
  String get permPhoto => 'Photos';

  @override
  String get permVideo => 'Videos';

  @override
  String get permFile => 'Files';

  @override
  String get permMusic => 'Music';

  @override
  String get permVoice => 'Voice messages';

  @override
  String get permVideoNote => 'Video messages';

  @override
  String get permExceptions => 'Exceptions';

  @override
  String get permExceptionAdd => 'Add exception';

  @override
  String get permExceptionInfo =>
      'Set different permissions for one member. Owners and admins can always do everything.';

  @override
  String get permExceptionRemove => 'Remove exception';

  @override
  String permExceptionCount(int n) {
    return '$n different';
  }

  @override
  String get permPickMember => 'Pick a member';

  @override
  String get permTextLocked => 'Text isn\'t allowed in this chat';

  @override
  String permKindBlocked(String what) {
    return '$what can\'t be sent in this chat';
  }

  @override
  String get reportBlockedSender => 'Sender blocked';

  @override
  String get shareHistory => 'Share last 50 messages';

  @override
  String get shareHistoryInfo =>
      'Your phone sends new members the chat from before they joined, encrypted to their phones only. The server can\'t read it. Text only, no photos or files.';

  @override
  String get sendHistory => 'Send earlier messages';

  @override
  String sendHistoryDone(int count, String name) {
    return 'Sent $count earlier messages to $name';
  }

  @override
  String earlierBar(int count) {
    return 'See $count messages from before you joined';
  }

  @override
  String get earlierTitle => 'Before you joined';

  @override
  String get earlierInfo =>
      'Earlier messages a member sent to your phones only. They stay on this phone.';

  @override
  String earlierMedia(String name, String time) {
    return '$name · photo or file ($time)';
  }

  @override
  String get fmtQuote => 'Quote';

  @override
  String get fmtFoldQuote => 'Collapsed Quote';

  @override
  String replyFromOtherChat(String name) {
    return '$name · another chat';
  }

  @override
  String quotingWho(String name) {
    return 'Quote · $name';
  }

  @override
  String get quotePickPart => 'Quote a Specific Part';

  @override
  String get replyInOtherChat => 'Reply in Another Chat';

  @override
  String get replyNone => 'Don\'t Reply';

  @override
  String get replyInWhichChat => 'Reply in…';

  @override
  String get quotePickTitle => 'Choose Quote';

  @override
  String get quotePickHint => 'Drag the handles to choose what to quote';

  @override
  String quotePickCount(int n) {
    return '$n characters chosen';
  }

  @override
  String pinAlsoFor(String name) {
    return 'Also pin for $name';
  }

  @override
  String get pinAlsoForOn => 'You both see it.';

  @override
  String get pinOnlyMeInfo =>
      'Only you see it, on this phone. Nothing is sent.';

  @override
  String get pinnedOnlyMe => 'Pinned for you only';

  @override
  String get pinOnlyMeTag => 'only me';

  @override
  String get attachScan => 'Scan';

  @override
  String scanFileName(String time) {
    return 'Scan $time';
  }

  @override
  String get scanNotHere => 'Document scan works in the phone app';

  @override
  String get pack_hip => 'Hip Friends';

  @override
  String get pack_dandy => 'Dandy Friends';

  @override
  String charEmojiTitle(String name) {
    return '$name emoji';
  }

  @override
  String get charReactionsTitle => 'Character reactions';

  @override
  String get translate => 'Translate';

  @override
  String trToLang(String lang) {
    return 'Translate to $lang';
  }

  @override
  String get trShowOriginal => 'Show original';

  @override
  String get trOtherLang => 'Translate to another language';

  @override
  String trDontTranslate(String lang) {
    return 'Do not translate $lang';
  }

  @override
  String get trHideBar => 'Hide in this chat';

  @override
  String get trHiddenNote =>
      'Translation bar hidden. Hold a message and open Translate to turn it on again.';

  @override
  String get trShowButton => 'Show translate button';

  @override
  String get trShowButtonSub => 'Hold a message to translate it';

  @override
  String get trChat => 'Translate entire chats';

  @override
  String get trChatSub => 'A bar on top of chats in another language';

  @override
  String get trSkip => 'Do not translate';

  @override
  String get trFooter =>
      'Translation happens on this phone only. Words never go to a translation server. Each language downloads once (Wi-Fi, about 30 MB).';

  @override
  String get trWebDemo =>
      'The web preview shows fixed example translations only.';

  @override
  String get trAppLang => 'App language';

  @override
  String trDownloadAsk(String lang) {
    return 'Download $lang for translation?';
  }

  @override
  String get trDownloadInfo =>
      'After one download it works without internet. Downloads on Wi-Fi (about 30 MB).';

  @override
  String get trDownload => 'Download';

  @override
  String get trDownloading => 'Downloading…';

  @override
  String get trDownloadFailed =>
      'Couldn\'t download. Connect to Wi-Fi and try again.';

  @override
  String get trUnsupported => 'This phone can\'t translate';

  @override
  String get trFailed => 'Couldn\'t translate';

  @override
  String trSameLang(String lang) {
    return 'Already in $lang';
  }

  @override
  String get trWholeChatOn => 'Translate entire chat';

  @override
  String get trTranslating => 'Translating…';

  @override
  String get trLang_ko => 'Korean';

  @override
  String get trLang_en => 'English';

  @override
  String get trLang_ja => 'Japanese';

  @override
  String get trLang_zh => 'Chinese';

  @override
  String get trLang_es => 'Spanish';

  @override
  String get trLang_fr => 'French';

  @override
  String get trLang_de => 'German';

  @override
  String get trLang_ru => 'Russian';

  @override
  String get trLang_pt => 'Portuguese';

  @override
  String get trLang_it => 'Italian';

  @override
  String get trLang_vi => 'Vietnamese';

  @override
  String get trLang_th => 'Thai';

  @override
  String get trLang_id => 'Indonesian';

  @override
  String get trLang_tr => 'Turkish';

  @override
  String get trLang_ar => 'Arabic';

  @override
  String get trLang_hi => 'Hindi';

  @override
  String get trLang_uk => 'Ukrainian';

  @override
  String get trLang_pl => 'Polish';

  @override
  String get trLang_nl => 'Dutch';

  @override
  String newLoginMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String get deviceIdlePage => 'Auto log out';

  @override
  String get deviceIdleHeader => 'Log out if not used for';

  @override
  String get whoInfoVoice =>
      'Calls from others become missed calls; their messages and invitations stay hidden. People you don\'t allow voice and video messages from see their mic locked and can only type.';

  @override
  String get qrLoginHeading => 'Log in by scanning with your phone';

  @override
  String get searchTabChats => 'Chats';

  @override
  String get searchTabChannels => 'Channels';

  @override
  String get searchTabPosts => 'Posts';

  @override
  String get searchTabMedia => 'Media';

  @override
  String get searchTabLinks => 'Links';

  @override
  String get searchTabFiles => 'Files';

  @override
  String get searchTabMusic => 'Music';

  @override
  String get searchTabVoice => 'Voice';

  @override
  String get searchSectionChats => 'Chats';

  @override
  String get searchSectionGlobal => 'Global search';

  @override
  String get searchSectionMessages => 'Messages';

  @override
  String get searchScopeAll => 'All chats';

  @override
  String get searchScopeDirect => 'Private chats';

  @override
  String get searchScopeGroup => 'Groups';

  @override
  String get searchScopeChannel => 'Channels';

  @override
  String get searchScopeTitle => 'Search messages in';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchClear => 'Clear';

  @override
  String get searchMyChannels => 'Channels you joined';

  @override
  String get searchPublicChannels => 'Public channels';

  @override
  String get searchFollowedPosts => 'From your channels';

  @override
  String get searchPublicPosts => 'Public posts';

  @override
  String get searchPublicPostsNote =>
      'Only posts of public channels with their web page on. Your words are not kept on the server.';

  @override
  String get searchPostsHint => 'Type words to find in channel posts';

  @override
  String get searchChannelsHint => 'Type a channel name or address';

  @override
  String get searchOnPhoneNote =>
      'Messages, photos and files are searched on this phone only. The server never knows what you look for.';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchMore => 'Show more';

  @override
  String get searchLess => 'Show less';

  @override
  String get tagThisChat => 'This chat';

  @override
  String get tagMyMessages => 'My messages';

  @override
  String get tagPublicPosts => 'Public posts';

  @override
  String get tagShowChat => 'Show as chat';

  @override
  String get tagShowList => 'Show as list';

  @override
  String get tagShowGrid => 'Show as grid';

  @override
  String get tagJoinToSee => 'Join to see this chat\'s posts';

  @override
  String get tagOpenChat => 'Preview';

  @override
  String get tagStoriesTitle => 'Hashtag stories';

  @override
  String get tagStoriesEmpty => 'No stories with this hashtag';

  @override
  String get tagStoriesNote => 'Only stories of friends that you can see';

  @override
  String searchMembers(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString members';
  }

  @override
  String searchSubscribers(int n) {
    final intl.NumberFormat nNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String nString = nNumberFormat.format(n);

    return '$nString subscribers';
  }

  @override
  String tagCount(int n) {
    return '$n messages';
  }

  @override
  String tagStories(int n) {
    return '$n stories';
  }

  @override
  String tagInChat(String address) {
    return 'In $address';
  }

  @override
  String tagStoriesSub(String tag) {
    return 'View stories · $tag';
  }

  @override
  String dayRangeSameMonth(String from, int day) {
    return '$from–$day';
  }

  @override
  String get stkWeather => 'Weather';

  @override
  String get stkPlace => 'Location';

  @override
  String get stkLink => 'Link';

  @override
  String get stkWeatherTitle => 'Weather sticker';

  @override
  String get stkWeatherHere => 'Where I am';

  @override
  String get stkWeatherHereSub =>
      'Your place is blurred to about 10 km before asking';

  @override
  String get stkWeatherCity => 'Pick a city';

  @override
  String get stkWeatherCitySub => 'Uses no location at all';

  @override
  String get stkWeatherFinding => 'Getting the weather…';

  @override
  String get stkWeatherShowCity => 'Show the city name';

  @override
  String get stkWeatherInfo =>
      'Your story carries only the temperature and the sky. Your location stays with nobody, not friends, not Burumy. Friends see their own unit (°C or °F) and can tap to switch.';

  @override
  String get stkWeatherNoLocation => 'Can\'t use your location, so pick a city';

  @override
  String get stkWeatherOff => 'Weather isn\'t available in this version';

  @override
  String get stkWeatherNetwork =>
      'Couldn\'t get the weather. Try again in a moment';

  @override
  String get stkLook => 'Style';

  @override
  String get stkLookWhite => 'White';

  @override
  String get stkLookDark => 'Dark';

  @override
  String get stkLookClear => 'Clear';

  @override
  String get stkLookColor => 'My colour';

  @override
  String get stkSearchCity => 'Search cities';

  @override
  String get stkNearby => 'Nearby';

  @override
  String get stkCities => 'Cities';

  @override
  String get stkPlaceTitle => 'Location sticker';

  @override
  String get stkPlaceName => 'Place name (e.g. the riverside café)';

  @override
  String get stkPlaceMap => 'Let friends open it on a map';

  @override
  String get stkPlaceExact => 'Exact spot';

  @override
  String get stkPlaceRough => 'Rough (about 1 km)';

  @override
  String get stkPlaceFinding => 'Finding your location…';

  @override
  String get stkPlaceNoLocation =>
      'Can\'t use your location, so only the name is added';

  @override
  String get stkPlaceInfo =>
      'The name and the spot travel encrypted inside the story, to your friends only. With the map off, only the name shows.';

  @override
  String get stkLinkTitle => 'Link sticker';

  @override
  String get stkLinkUrl => 'Address (https://…)';

  @override
  String get stkLinkName => 'Name to show (optional)';

  @override
  String get stkLinkSmall => 'Small';

  @override
  String get stkLinkCard => 'Card';

  @override
  String get stkLinkInfo =>
      'Your phone makes the preview and puts it, encrypted, inside the story. Friends don\'t visit the site when they watch your story.';

  @override
  String get stkLinkBad => 'Enter a web address';

  @override
  String get stkLinkReading => 'Making the preview…';

  @override
  String get stkLinkPreviewOff => 'Link previews are off, so it shows small';

  @override
  String get stkLinkOpen => 'Open';

  @override
  String get stkLinkGoesTo => 'This link goes to';

  @override
  String get stkLinkLookalike =>
      'The name and the real address differ. Check the address';

  @override
  String get stkMapOpen => 'Open in Maps';

  @override
  String get stkPlaceOnlyName => 'Only a name, no map spot';

  @override
  String get roomPhotoNote =>
      'The photo is sent encrypted inside the chat. Only chats with a public link also show it on the link preview.';

  @override
  String roomPhotoLine(String who, String kind, String done) {
    String _temp0 = intl.Intl.selectLogic(done, {
      'removed': 'removed',
      'other': 'changed',
    });
    String _temp1 = intl.Intl.selectLogic(kind, {
      'channel': 'channel',
      'other': 'group',
    });
    return '$who $_temp0 the $_temp1 photo';
  }

  @override
  String roomPhotoLineMine(String kind, String done) {
    String _temp0 = intl.Intl.selectLogic(done, {
      'removed': 'removed',
      'other': 'changed',
    });
    String _temp1 = intl.Intl.selectLogic(kind, {
      'channel': 'channel',
      'other': 'group',
    });
    return 'You $_temp0 the $_temp1 photo';
  }

  @override
  String get roomPhotoPreview => 'Changed the photo';

  @override
  String get meetupEndToggle => 'End time';

  @override
  String get meetupStarts => 'Starts';

  @override
  String get meetupEnds => 'Ends';

  @override
  String get meetupBring => 'Bringing';

  @override
  String meetupWithGuests(String name, int n) {
    return '$name +$n';
  }

  @override
  String get meetupAddCalendar => 'Add to Calendar';

  @override
  String get meetupCalendarFile =>
      'Calendar file saved. Open it to add the event';

  @override
  String get meetupRemind => 'Remind me 1 hour before';

  @override
  String get meetupRemindInfo =>
      'Plans you answer Going or Maybe remind you 1 hour before, from this phone only. The server never knows.';

  @override
  String get myPlans => 'My Plans';

  @override
  String get myPlansEmpty =>
      'No plans yet. Make one with + > Plan in a chat, or tap Going on a plan you get.';

  @override
  String get myPlansPast => 'Past';

  @override
  String get myPlansSoon => 'Upcoming';

  @override
  String meetupReminderTitle(String title) {
    return 'In 1 hour: $title';
  }

  @override
  String get myPlansMade => 'I made this';

  @override
  String get myPlansGoing => 'Going';

  @override
  String get earlierVoice => 'Voice message';

  @override
  String get earlierFileFailed =>
      'Couldn\'t open the file. The sender may have deleted it.';

  @override
  String get callIgnore => 'Ignore';

  @override
  String get callUnknown => 'Not in your contacts';

  @override
  String callCommonGroups(int n) {
    return '$n groups in common';
  }

  @override
  String get callNoCommon => 'No groups in common';

  @override
  String get callLock => 'Lock screen';

  @override
  String get callLocked => 'Locked · hold to unlock';

  @override
  String get filterMentions => 'Mentions';

  @override
  String get mentionNone => 'No one has mentioned you';

  @override
  String get newGroupFromMembers => 'New group with these members';

  @override
  String get reportPerson => 'Report';

  @override
  String reportPersonNote(int n) {
    return 'Sends their last $n messages to our team with it';
  }

  @override
  String get reportPersonEmpty => 'They haven\'t sent you anything to report';

  @override
  String get storageByChat => 'Storage by chat';

  @override
  String get storageByChatInfo =>
      'Photos, videos and files downloaded to this phone. Clearing keeps the messages; tap to download again.';

  @override
  String get storageGoneChat => 'Left chat';

  @override
  String storageFiles(int n) {
    return '$n files';
  }

  @override
  String get storageChatTotal => 'Space used';

  @override
  String get storageChatInfo => 'Messages stay. Tap one to download it again.';

  @override
  String get storageClearChat => 'Clear all files in this chat';

  @override
  String storageClearPicked(int n) {
    return 'Clear $n picked files';
  }

  @override
  String get storageChatFiles => 'Biggest first';

  @override
  String get storageChatEmpty => 'No files kept on this phone';

  @override
  String get storageNoName => 'Untitled file';

  @override
  String storageGoing(int count, int n) {
    return 'Clearing $count files in ${n}s';
  }

  @override
  String get videoEditTitle => 'Edit video';

  @override
  String get videoRotate => 'Rotate';

  @override
  String get videoFlip => 'Flip';

  @override
  String get videoSound => 'Sound';

  @override
  String get videoEditFailed =>
      'Couldn\'t make the edited video, so it wasn\'t sent';

  @override
  String get videoEditing => 'Making the video';

  @override
  String get photoHdOn => 'Sending in HD';

  @override
  String get photoHdOff => 'Sending in standard quality to save data';

  @override
  String get sendHd => 'Send in HD';

  @override
  String get photoHdSetting => 'Send photos in HD';

  @override
  String get photoHdSettingSub =>
      'Off: standard quality, saves data and storage';

  @override
  String get albumPreview => 'Preview';

  @override
  String get albumPreviewHint => 'Hold and drag to change the order';

  @override
  String get pickEdit => 'Edit';

  @override
  String get pickTrim => 'Trim & rotate';

  @override
  String get pickSpoilerOn => 'Hide with spoiler';

  @override
  String get pickSpoilerOff => 'Remove spoiler';

  @override
  String get pickRemove => 'Remove';

  @override
  String spoilerCount(int count) {
    return '$count hidden';
  }

  @override
  String get aiAgeTitle => 'AI features are for ages 18 and up';

  @override
  String get aiAgeInfo =>
      'On Android, the phone\'s AI (by Google) may only be used by people 18 or older under Google\'s terms. We ask once; change it in Settings › Chats › AI features.';

  @override
  String get aiAgeAdult => 'I\'m 18 or older';

  @override
  String get aiAgeMinor => 'I\'m under 18';

  @override
  String get aiAgeOnly => 'Only for ages 18 and up';

  @override
  String get aiAgeRow => 'AI age check';

  @override
  String get aiAgeRowSub =>
      'AI Editor, summaries, background removal (Android)';

  @override
  String get aiAgeValueAdult => '18 or older';

  @override
  String get aiAgeValueMinor => 'Under 18';

  @override
  String get aiAgeValueUnknown => 'Not yet';

  @override
  String get trPoweredByGoogle => 'Powered by Google Translate';

  @override
  String get stkWeatherCredit =>
      'Weather: based on data from MET Norway (CC BY 4.0)';

  @override
  String get creditsHeader => 'Credits';

  @override
  String get creditsFooter => 'Tap for details and the original licence text.';

  @override
  String get creditWeather => 'Weather data';

  @override
  String get creditWeatherSub => 'MET Norway · CC BY 4.0';

  @override
  String get creditWeatherInfo =>
      'The story weather sticker is based on data from the Norwegian Meteorological Institute (MET Norway). Our server asks with the place blurred to about 10 km, and the app turns the forecast into a temperature and sky picture.';

  @override
  String get creditGoogle => 'Translation and AI (Android)';

  @override
  String get creditGoogleSub => 'Google ML Kit';

  @override
  String get creditGoogleInfo =>
      'On Android, translation, document scanning, background removal and the AI Editor are done on the phone by Google ML Kit. Nothing is sent to the company. Translations carry a Google credit. iPhone uses Apple\'s built-in features.';

  @override
  String get creditFont => 'Font';

  @override
  String get creditFontSub => 'Pretendard · SIL OFL 1.1';

  @override
  String get creditFontInfo =>
      'The app\'s font is Pretendard, free for everyone under the SIL Open Font License, so its licence text comes with the app.';

  @override
  String get creditPdq => 'Picture fingerprints';

  @override
  String get creditPdqSub => 'PDQ (Meta) · safety server';

  @override
  String get creditPdqInfo =>
      'To find known illegal pictures, our safety server uses PDQ, a picture fingerprint published by Meta. Pictures in private chats are not checked.';

  @override
  String partsHeader(int count) {
    return '$count app parts';
  }

  @override
  String get importTitle => 'Import chats from other apps';

  @override
  String get importHeader =>
      'Bring a chat exported from KakaoTalk, WhatsApp or Telegram into a Burumy chat, with its original dates.';

  @override
  String get importAppKakao => 'KakaoTalk';

  @override
  String get importAppWhatsapp => 'WhatsApp';

  @override
  String get importAppTelegram => 'Telegram';

  @override
  String get importDeviceIphone => 'iPhone';

  @override
  String get importDeviceAndroid => 'Android';

  @override
  String get importDevicePc => 'Computer';

  @override
  String importHowTo(String app) {
    return 'How to export from $app';
  }

  @override
  String get importStepsKakaoPhone =>
      'Open the chat and tap ☰ at the top right\nTap ⚙ Settings at the bottom of the menu, then \'Export Messages\'\nTo bring photos too, save all messages to storage; for words only, send text messages only\nPick the saved file (.zip or .txt) with \'Choose exported file\' below';

  @override
  String get importStepsKakaoPc =>
      'In KakaoTalk for PC, open the chat and click ☰ at the top right\nChoose \'Export chats\' and save the .txt file\nMove the file to your phone, or pick it right away in Burumy for PC';

  @override
  String get importStepsWhatsappIphone =>
      'Open the chat and tap the contact or group name at the top\nScroll down and tap \'Export Chat\'\nChoose \'Attach Media\' to bring photos too\nSave to Files, then pick it with \'Choose exported file\' below';

  @override
  String get importStepsWhatsappAndroid =>
      'Open the chat and tap ⋮ at the top right\nTap More → Export chat\nChoose \'Include media\' to bring photos too\nSave it as a file, then pick it with \'Choose exported file\' below';

  @override
  String get importStepsTelegram =>
      'In Telegram Desktop, open the chat and click ⋮ at the top right\nChoose \'Export chat history\'\nTurn on photos and files to bring them too, and pick the JSON (or HTML) format\nWhen it\'s done, zip the whole export folder and pick it with \'Choose exported file\' below';

  @override
  String get importTelegramPhoneNote =>
      'The Telegram phone app can\'t export chats, so use Telegram on a computer.';

  @override
  String get importKakaoMediaNote =>
      'If you export words only, photos show as \'Photo\' placeholders.';

  @override
  String get importWhatsappMediaNote =>
      'If you export without media, photos show as \'Photo\' placeholders.';

  @override
  String get importPrivacy =>
      'The file is read only on this phone. It\'s encrypted here before it\'s sent, so the server can\'t see the words or who wrote them.';

  @override
  String get importPick => 'Choose exported file';

  @override
  String get importSample => 'Try with a sample file';

  @override
  String get importReading => 'Reading the chat';

  @override
  String get importPickFailed =>
      'Couldn\'t open the file picker. Please try again.';

  @override
  String get importErrBig =>
      'The file is too big. Export without media or in smaller parts.';

  @override
  String get importErrEmpty => 'There are no messages in this file.';

  @override
  String get importErrBroken => 'The file is damaged. Please export it again.';

  @override
  String get importErrUnknown =>
      'This isn\'t a chat exported from KakaoTalk, WhatsApp or Telegram.';

  @override
  String get importPickChat => 'Choose a chat to import';

  @override
  String get importNoTitle => 'Untitled chat';

  @override
  String importCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get importCheckTitle => 'Check the chat';

  @override
  String get importWhoIsMe => 'Which one is you?';

  @override
  String get importWhoIsMeInfo =>
      'Messages from the name you pick show as your bubbles (right side). Others keep their names from the other app.';

  @override
  String importPeerInfo(String name, String peer) {
    return 'Messages from $name show as $peer\'s bubbles in this chat.';
  }

  @override
  String get importWhere => 'Where should it go?';

  @override
  String get importPickRoom => 'Choose a chat';

  @override
  String get importPickRoomInfo =>
      'Everyone in the chat you pick can see the imported messages.';

  @override
  String get importKindDirect => 'Direct chat';

  @override
  String get importKindGroup => 'Group';

  @override
  String get importKindChannel => 'Channel';

  @override
  String get importMedia => 'Photos, videos and files';

  @override
  String importMediaSize(int count, String size) {
    return '$count · $size';
  }

  @override
  String get importNoMedia => 'This file has no photos in it';

  @override
  String importMissingInfo(int count) {
    return '$count photos or files weren\'t in the export, so only their place shows. To bring them, export again with media.';
  }

  @override
  String get importStart => 'Import';

  @override
  String importConfirmTitle(String room, int count) {
    return 'Add $count messages to $room?';
  }

  @override
  String get importConfirmInfo =>
      'They go in by their original date and time, each with an \'Imported\' mark.';

  @override
  String importStepMedia(int done, int total) {
    return 'Encrypting and uploading photos and files ($done/$total)';
  }

  @override
  String get importStepPack => 'Encrypting and packing the messages';

  @override
  String get importStepSend => 'Almost done';

  @override
  String get importKeepOpen => 'Keep this screen open until it\'s done.';

  @override
  String importDone(int count) {
    return 'Imported $count messages!';
  }

  @override
  String get importFailed =>
      'Couldn\'t import. Check your connection and try again.';

  @override
  String get importRetry => 'Try again';

  @override
  String get importStop => 'Stop';

  @override
  String get importSeeChat => 'See the chat';

  @override
  String importLineMine(String app, int count) {
    return 'You imported a chat from $app · $count messages';
  }

  @override
  String importLine(String name, String app, int count) {
    return '$name imported a chat from $app · $count messages';
  }

  @override
  String get importInfoTitle => 'Imported chat';

  @override
  String get importInfoCount => 'Messages';

  @override
  String get importInfoDates => 'Dates';

  @override
  String get importInfoBy => 'Imported by';

  @override
  String get importInfoByMe => 'Me';

  @override
  String get importInfoNote =>
      'Imported messages are copied from another app\'s export file. Burumy couldn\'t check who wrote them, so they carry an \'Imported\' mark.';

  @override
  String get importDelete => 'Delete imported chat';

  @override
  String get importedMark => 'Imported';

  @override
  String get importSticker => 'Sticker';

  @override
  String importNotIncluded(String kind) {
    return '$kind · not in the export';
  }

  @override
  String importSysCreate(String name) {
    return '$name created the chat';
  }

  @override
  String importSysJoin(String name) {
    return '$name joined';
  }

  @override
  String importSysLeft(String name) {
    return '$name removed a member';
  }

  @override
  String importSysPin(String name) {
    return '$name pinned a message';
  }

  @override
  String importSysCall(String name) {
    return 'Call from $name';
  }

  @override
  String importSysTitle(String name, String title) {
    return '$name renamed the chat: $title';
  }

  @override
  String importSysPhoto(String name) {
    return '$name changed the photo';
  }

  @override
  String importSysOther(String name) {
    return 'Notice from $name';
  }

  @override
  String get importRow => 'Import from other apps';

  @override
  String get importRowSub => 'KakaoTalk, WhatsApp, Telegram';

  @override
  String get importMenu => 'Import chat';

  @override
  String get importDeleted => 'Deleted message';

  @override
  String get importAlready =>
      'You\'ve already imported this chat here. Importing it again shows every message twice.';

  @override
  String invJoined(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString joined';
  }

  @override
  String invPeopleLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString left';
  }

  @override
  String invDaysLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}d left';
  }

  @override
  String invHoursLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}h left';
  }

  @override
  String invMinutesLeft(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '${countString}m left';
  }

  @override
  String get invEnded => 'Expired';

  @override
  String get invFull => 'Limit reached';

  @override
  String get invRevoked => 'Cancelled';

  @override
  String get invMoreHeader => 'Additional links';

  @override
  String get invMoreInfo =>
      'Make separate links, like one for your Instagram profile and one for friends. When a link\'s time is up or it is full, our server closes it, even while your phone is off.';

  @override
  String get invNew => 'Create a new link';

  @override
  String get invRevokedHeader => 'Cancelled links';

  @override
  String get invDeleteAllRevoked => 'Delete all cancelled links';

  @override
  String invDeleteAllIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Deleting cancelled links in ${secondsString}s';
  }

  @override
  String get invNewTitle => 'New link';

  @override
  String get invEditTitle => 'Edit link';

  @override
  String get invMake => 'Create';

  @override
  String get invNameHint => 'Link name (e.g. Instagram profile)';

  @override
  String get invNameInfo =>
      'Only admins see the name. People who get the link don\'t.';

  @override
  String get invTime => 'Time limit';

  @override
  String get inv1h => '1 hour';

  @override
  String get inv1d => '1 day';

  @override
  String get inv1w => '1 week';

  @override
  String get invNoLimit => 'No limit';

  @override
  String get invPick => 'Custom';

  @override
  String get invTimeNone => 'Stays open with no end date';

  @override
  String invTimeEnds(String time) {
    return 'Ends $time';
  }

  @override
  String get invPeople => 'Number of people';

  @override
  String invPeopleCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString';
  }

  @override
  String get invPeopleHint => 'Type how many people can join';

  @override
  String invPeopleN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'The link closes after $countString people join';
  }

  @override
  String get invPeopleNone => 'Any number of people can join';

  @override
  String get invPeopleApproval =>
      'Approval is on, so admins let people in one by one. Only the time limit applies.';

  @override
  String get invRevokedInfo => 'This link was cancelled and no longer opens.';

  @override
  String get invFullInfo =>
      'Everyone it was for has joined, so it no longer opens. You can raise the limit in Edit link.';

  @override
  String get invEndedInfo =>
      'Its time is up, so it no longer opens. You can extend it in Edit link.';

  @override
  String invJoinedHeader(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString joined with this link';
  }

  @override
  String get invJoinedMore => 'Shows the latest 100 people.';

  @override
  String get invNobody => 'Nobody has joined yet';

  @override
  String get invLeftRoom => 'Has left since';

  @override
  String get invRevoke => 'Cancel link';

  @override
  String invRevokeIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Cancelling link in ${secondsString}s';
  }

  @override
  String get invDelete => 'Delete link';

  @override
  String invDeleteIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Deleting link in ${secondsString}s';
  }

  @override
  String get joinLinkEnded => 'This invite link has expired';

  @override
  String get joinLinkFull => 'This invite link is full';

  @override
  String get chatLinks => 'Links to chat';

  @override
  String get chatLinksAbout =>
      'Whoever taps the link gets a chat with you, with your words already typed in. Great for shop questions or sign-ups.';

  @override
  String get chatLinksFooter =>
      'Links include your ID. The list stays on this phone, and nobody counts taps, not even our server.';

  @override
  String get chatLinkNew => 'Create a link to chat';

  @override
  String get chatLinkEdit => 'Link to chat';

  @override
  String get chatLinkNoText => 'No message';

  @override
  String get chatLinkPreview => 'What they will see';

  @override
  String get chatLinkText => 'Message';

  @override
  String get chatLinkTextHint => 'e.g. I\'d like to order a cake';

  @override
  String get chatLinkTextInfo =>
      'It goes into their message box. They can change it and send it themselves.';

  @override
  String get chatLinkNameHint => 'Link name (e.g. Shop questions)';

  @override
  String get chatLinkNameInfo => 'Only you see the name.';

  @override
  String get chatLinkKey => 'Include my ID key';

  @override
  String get chatLinkKeyInfo =>
      'When on, strangers can start a chat without asking for your ID key. If the link spreads, the key spreads with it.';

  @override
  String get chatLinkIdInfo => 'People who get the link can see your ID.';

  @override
  String get chatLinkDelete => 'Delete link';

  @override
  String chatLinkDeleteIn(int seconds) {
    final intl.NumberFormat secondsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String secondsString = secondsNumberFormat.format(seconds);

    return 'Deleting link in ${secondsString}s';
  }

  @override
  String get chatLinkWaiting => 'Ready in your message box';

  @override
  String get chatLinkStart => 'Send a message';

  @override
  String get qrSeeChannel => 'View channel';

  @override
  String get qrSeeGroup => 'View group';

  @override
  String get qrChat => 'Message';

  @override
  String get qrMessage => 'Message link';

  @override
  String get qrSee => 'View';

  @override
  String get qrPc => 'Sign in on a computer';

  @override
  String get qrConnect => 'Connect';

  @override
  String get qrExpired => 'This QR code has expired';

  @override
  String get qrOpenLink => 'Open link';

  @override
  String get qrCopyText => 'Copy text';

  @override
  String qrWebTitle(String host) {
    return 'Open $host?';
  }

  @override
  String get qrScan => 'Scan QR code';

  @override
  String get qrScanHint => 'Point the camera at a QR code';

  @override
  String get qrNoCamera => 'Camera isn\'t available';

  @override
  String get shareInTitle => 'Send with Burumy';

  @override
  String get shareInComment => 'Add a message';

  @override
  String get shareInFrom => 'Send from';

  @override
  String get shareInNoPost => 'You can\'t post in this chat';

  @override
  String get shareInKind => 'This chat doesn\'t allow this kind';

  @override
  String get shareInLater => 'Sending is paused here right now';

  @override
  String get shareInSlow => 'You can send again in a moment';

  @override
  String get shareInNone => 'No chats to send to';

  @override
  String shareInSending(int percent) {
    final intl.NumberFormat percentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String percentString = percentNumberFormat.format(percent);

    return 'Sending $percentString%';
  }

  @override
  String shareInSent(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Sent to $countString chats';
  }

  @override
  String shareInFailed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Couldn\'t send to $countString chats';
  }

  @override
  String get shareInDemo => 'Try sharing from another app';

  @override
  String shareInSendN(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Send to $countString';
  }

  @override
  String get editorSticker => 'Stickers';

  @override
  String get editorAddSticker => 'Add sticker or emoji';

  @override
  String get editorStickerHint =>
      'Tap for options, pinch to resize or turn, drag to the bin to remove';

  @override
  String get stkPhotoCut => 'Cut out a photo';

  @override
  String get stkFlip => 'Flip';

  @override
  String get stkCopy => 'Duplicate';

  @override
  String get stkCutout => 'Cut out';

  @override
  String get cutoutFail => 'This device can\'t remove the background';

  @override
  String get colorTitle => 'Colour';

  @override
  String get colorGrid => 'Grid';

  @override
  String get colorSpectrum => 'Spectrum';

  @override
  String get colorSliders => 'Sliders';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGreen => 'Green';

  @override
  String get colorBlue => 'Blue';

  @override
  String get mediaChanged => 'photo changed';

  @override
  String get editFirstPhoto => 'Photo before the change';

  @override
  String get captionAboveMenu => 'Move caption up';

  @override
  String get captionUp => 'Move caption up';

  @override
  String get captionDown => 'Move caption down';

  @override
  String get editSwapPhoto => 'Replace with another photo or video';

  @override
  String get editThisPhoto => 'Edit this photo';

  @override
  String get editAddPhoto => 'Add a photo or video';

  @override
  String get editingMedia => 'Edit photo';

  @override
  String get editMediaHint => 'Tap here to replace or edit the photo';

  @override
  String get editNewPhotoPicked => 'Will be replaced with the new one';

  @override
  String get noSwapPublic =>
      'In public groups and channels a sent photo can\'t be replaced. You can still edit the caption.';

  @override
  String get editMediaFailed =>
      'Couldn\'t edit it. Please try again in a moment.';

  @override
  String get photoMineForThem => 'Photo you set';

  @override
  String get photoTheirs => 'Their photo';

  @override
  String get myProfile => 'My profile';

  @override
  String get myProfileSeenBy => 'Seen by';

  @override
  String get seenEveryone => 'Everyone';

  @override
  String get seenContacts => 'My contacts';

  @override
  String get myProfileEveryoneInfo =>
      'Anyone who knows your ID sees this. Only what you set to \'Everyone\' is stored on the server.';

  @override
  String get myProfileContactsInfo =>
      'People you chat with 1:1 see this. It goes only through your encrypted 1:1 chats, never to the server.';

  @override
  String myProfileHidden(String what) {
    return 'Hidden: $what';
  }

  @override
  String get myProfileWho => 'Change who sees what';

  @override
  String get myProfileEdit => 'Edit';

  @override
  String get myProfileNoPhoto => 'No photo shown';

  @override
  String get publicPhoto => 'Public photo';

  @override
  String get publicPhotoSet => 'Set public photo';

  @override
  String get publicPhotoChange => 'Change public photo';

  @override
  String get publicPhotoRemove => 'Remove public photo';

  @override
  String get publicPhotoInfo =>
      'People who can\'t see your profile photo see this one instead. The public photo is stored on the server.';

  @override
  String get publicPhotoDone => 'Public photo set';

  @override
  String get publicPhotoRemoved => 'Public photo removed';

  @override
  String get oldPhotos => 'Earlier photos';

  @override
  String get oldPhotosInfo =>
      'Earlier photos stay only on this phone, encrypted. Others see just your main photo.';

  @override
  String get photoMain => 'Main photo';

  @override
  String get photoMakeMain => 'Set as main photo';

  @override
  String get photoMainDone => 'This is your main photo now';

  @override
  String get photoDeleted => 'Photo removed';

  @override
  String photoUsedUntil(String date) {
    return 'Used until $date';
  }

  @override
  String photoSuggest(String name) {
    return 'Suggest a photo for $name';
  }

  @override
  String get photoSuggestInfo =>
      'The photo goes encrypted in your 1:1 chat. It changes only if they tap \'Use as my photo\'.';

  @override
  String get photoSuggestSent => 'Photo suggested';

  @override
  String get photoSuggestNoChat => 'You need a 1:1 chat to suggest a photo';

  @override
  String get photoSuggestMine => 'You suggested a profile photo';

  @override
  String photoSuggestTheirs(String name) {
    return '$name suggested a profile photo';
  }

  @override
  String get photoSuggestView => 'View photo';

  @override
  String get photoSuggestUse => 'Use as my photo';

  @override
  String get photoSuggestPreview => '🖼️ Photo suggestion';

  @override
  String get emojiPhoto => 'Emoji or sticker';

  @override
  String get emojiPhotoTitle => 'Emoji photo';

  @override
  String get emojiPhotoEmoji => 'Emoji';

  @override
  String get emojiPhotoSticker => 'Burumy';

  @override
  String get emojiPhotoSize => 'Size';

  @override
  String get emojiPhotoColor => 'Background';

  @override
  String get emojiPhotoCustom => 'Custom';

  @override
  String get emojiPhotoInfo =>
      'No photo? Make your own from an emoji or a Burumy character.';

  @override
  String get skEdit => 'Edit';

  @override
  String get skKeep => 'Keep on profile';

  @override
  String get skUnkeep => 'Remove from profile';

  @override
  String get skAlbumPut => 'Add to album';

  @override
  String get skTop => 'Pin to top';

  @override
  String get skUntop => 'Unpin';

  @override
  String get skCover => 'Choose cover';

  @override
  String get skDelete => 'Delete story';

  @override
  String get skFailed => 'Couldn\'t change it now. Please try again later';

  @override
  String get skKeptDone => 'Kept on your profile';

  @override
  String get skUnkeptDone => 'Removed from your profile';

  @override
  String skDeleteIn(int n) {
    return 'Deleting in ${n}s';
  }

  @override
  String get skTopFull => 'You can pin up to 3 to the top';

  @override
  String get skAlbums => 'Album';

  @override
  String get skAlbumNone => 'No album';

  @override
  String get skAlbumNew => 'New album';

  @override
  String get skAlbumName => 'Album name';

  @override
  String get skAlbumInfo =>
      'Albums group stories on your profile by topic. Only friends who got the story see it.';

  @override
  String get skCoverTitle => 'Cover';

  @override
  String get skCoverNone => 'Couldn\'t get frames from this video';

  @override
  String get skCoverInfo =>
      'This frame shows on your profile and in the archive';

  @override
  String skKeptCount(int n) {
    return '$n profile stories';
  }

  @override
  String get skAll => 'All';

  @override
  String get skPostOpen => 'View post';

  @override
  String get skMusicTooBig => 'Music files can be up to 10 MB';

  @override
  String get skReact => 'Reaction';

  @override
  String get skMusic => 'Music';

  @override
  String get skRound => 'Round video';

  @override
  String get skReactPick => 'Reaction sticker';

  @override
  String get skReactInfo => 'When a friend taps it, only you get the reaction';

  @override
  String get skEdited => 'edited';

  @override
  String get skReactSent => 'Reaction sent';

  @override
  String get skSaved => 'Changed';

  @override
  String get skCoverPill => 'Cover';

  @override
  String skSplit(int n) {
    return 'Long video: posting it as $n stories';
  }

  @override
  String get skSplitInfo => 'Tap a part to leave it out';

  @override
  String get skGroupStory => 'Group story';

  @override
  String get skGroupStoryNew => 'Post a group story';

  @override
  String get skChannelStoryNew => 'Post a channel story';

  @override
  String get skGroupStoryInfo =>
      'Only admins can post. All members see it above their chat list. It stays inside the group\'s encryption.';

  @override
  String get skGroupOpen => 'Go to group';

  @override
  String get skGroupShared => 'Group story posted';

  @override
  String get skToStory => 'My story';

  @override
  String get skKeptMine => 'Profile stories';

  @override
  String get skKeptEmpty =>
      'No stories kept on your profile. Open your story and tap ⋯ > Keep on profile.';

  @override
  String get skKeptInfo =>
      'Friends can see these on your profile after 24 hours. Only friends who got the story see it.';

  @override
  String get skMore => 'More';

  @override
  String get skMuteTap => 'Tap to turn sound on or off';

  @override
  String get skRoundShort => 'Round';

  @override
  String quickForwardIn(int n) {
    return 'Forwarding in ${n}s';
  }

  @override
  String quickForwardTo(String name) {
    return 'To: $name';
  }

  @override
  String get quickForwardHint => 'Hold the arrow and slide to forward';

  @override
  String nextChannelPull(int n) {
    return '$n unread · pull up for next channel';
  }

  @override
  String get nextChannelLetGo => 'Let go for the next channel';

  @override
  String get sendAsTitle => 'Send as';

  @override
  String get sendAsInfo => 'Choose the name your messages show in this chat';

  @override
  String get sendAsMe => 'Shown with your own name and photo';

  @override
  String get sendAsChannelHidden => 'Only the channel\'s name shows, not yours';

  @override
  String get sendAsMyChannel => 'Shown as your public channel';

  @override
  String sendAsChanged(String name) {
    return 'Sending as $name';
  }

  @override
  String get showAuthors => 'Show authors\' profiles';

  @override
  String get showAuthorsInfo =>
      'Each post shows the admin\'s photo and name, like a group. Admins can still post as the channel by tapping the photo next to the message field.';

  @override
  String get subscriberDm => 'Messages from subscribers';

  @override
  String get subscriberDmInfo =>
      'Subscribers can message the admins privately with the 💬 button. Chats stay end-to-end encrypted.';

  @override
  String get dmInboxTag => 'Messages';

  @override
  String dmInboxSub(String channel) {
    return '$channel · subscriber messages';
  }

  @override
  String get dmEmptyTitle => 'Message the admins';

  @override
  String dmEmptyBody(String channel) {
    return 'Only $channel\'s admins see this. End-to-end encrypted.';
  }

  @override
  String get dmButtonHint => 'Message the channel\'s admins';

  @override
  String get dmToAdmins => 'Message to the admins';

  @override
  String get dmOpenFailed => 'You can\'t send a message right now';

  @override
  String get allBackgrounds => 'All backgrounds';

  @override
  String get allBackgroundsInfo =>
      'Tap one to make it your default. Tap Night to see how it looks in night mode.';

  @override
  String get channelNameColor => 'Channel name colour';

  @override
  String get channelNameColorInfo =>
      'Quotes of this channel\'s posts show in this colour.';

  @override
  String get dayLook => 'Day';

  @override
  String get nightLook => 'Night';

  @override
  String get gradInfo =>
      'The colours turn a little each time you send. Colours and icons stay on this phone.';

  @override
  String get gradSky => 'Sky';

  @override
  String get gradPeach => 'Peach';

  @override
  String get gradMint => 'Mint';

  @override
  String get gradLilac => 'Lilac';

  @override
  String get gradSunset => 'Sunset';

  @override
  String get gradNight => 'Night sky';

  @override
  String get gradPickColor => 'Tap a circle, then pick a colour';

  @override
  String get gradTapToTurn => 'Tap to see it move';

  @override
  String lookFromLevel(int n) {
    return 'From level $n';
  }

  @override
  String get lookSampleLink => 'Link preview';

  @override
  String get lookSampleLinkText => 'burumy.app · News';

  @override
  String get lookSampleQuote => 'What time today?';

  @override
  String get lookSampleText => 'How about 7?';

  @override
  String get myThemes => 'My themes';

  @override
  String get myThemesInfo =>
      'Tap to use. Touch and hold to edit, copy the link or delete. Send the link in a chat and friends can use the same theme.';

  @override
  String get nightBrightness => 'Night brightness';

  @override
  String get nightBrightnessInfo =>
      'In night mode, photo and colour backgrounds get this much darker.';

  @override
  String get none => 'None';

  @override
  String get patternStrength => 'Icon strength';

  @override
  String get patternTitle => 'Icons';

  @override
  String get personLook => 'Name & profile look';

  @override
  String get personLookInfo =>
      'In groups everyone sees it with your name colour; 1:1 chats get it in an encrypted note.';

  @override
  String get pickBackground => 'Pick a background';

  @override
  String get profileColor => 'Profile colour';

  @override
  String get profileIcons => 'Profile icons';

  @override
  String get replyIcons => 'Reply icons';

  @override
  String get replyIconsInfo =>
      'When someone replies to you, these icons show faintly in the quote.';

  @override
  String get roomCoverColor => 'Cover colour';

  @override
  String get roomLogoIcons => 'Cover icons';

  @override
  String get roomLook => 'Appearance';

  @override
  String get roomLookFailed =>
      'Couldn\'t change it. Check that you are an admin.';

  @override
  String get roomLookInfo =>
      'Everyone in the room sees it. More opens as the community level grows.';

  @override
  String get roomLookSaved => 'Appearance updated';

  @override
  String get roomStatusEmoji => 'Status emoji';

  @override
  String get roomWallAll => 'Background for everyone';

  @override
  String get roomWallAllInfo =>
      'Members see this unless they picked their own background for this chat.';

  @override
  String get themeAccentInfo =>
      'The accent colours bubbles, buttons and switches. Very dark colours are lightened a little so words stay readable.';

  @override
  String get themeApplied => 'Theme applied';

  @override
  String get themeApply => 'Use this theme';

  @override
  String get themeCardOpen => 'View theme';

  @override
  String get themeCopyLink => 'Copy link';

  @override
  String get themeDefaultName => 'My theme';

  @override
  String themeDeletedIn(int n) {
    return 'Deleting theme in ${n}s';
  }

  @override
  String get themeEdit => 'Edit theme';

  @override
  String get themeLinkCopied => 'Theme link copied. Paste it in a chat.';

  @override
  String get themeLinkInfo =>
      'The theme is inside the link itself. Nothing is downloaded.';

  @override
  String get themeMake => 'Make a theme';

  @override
  String get themeMakeInfo =>
      'Saving puts it on. In night mode the same background shows a little darker.';

  @override
  String get themeNameHint => 'Theme name';

  @override
  String get themeNew => 'New';

  @override
  String get themePartAccent => 'Accent';

  @override
  String get themePartWall => 'Background';

  @override
  String get themeSaved => 'Theme saved';

  @override
  String get wallApplyBoth => 'Set for both of us';

  @override
  String get wallApplyHere => 'Only for me';

  @override
  String get wallBlur => 'Blur';

  @override
  String get wallFromPhotos => 'Choose from photos';

  @override
  String get wallMakeColors => 'Mix my own colours';

  @override
  String get wallMine => 'My backgrounds';

  @override
  String get wallMixed => 'My colours';

  @override
  String get wallMoreChoices => 'Photo or colour';

  @override
  String get wallMotion => 'Motion';

  @override
  String get wallNoteKeep => 'Keep it';

  @override
  String wallNoteMine(String name) {
    return 'You set a new background for you and $name';
  }

  @override
  String wallNoteTheirs(String name) {
    return '$name set a new background for you both';
  }

  @override
  String get wallNoteUndo => 'Go back to mine';

  @override
  String get wallPhotoMineOnly => 'Photo backgrounds stay on your phone only';

  @override
  String get wallPreview => 'Background preview';

  @override
  String get wallPreviewReply => 'Swipe to see other backgrounds';

  @override
  String get wallReady => 'Burumy backgrounds';

  @override
  String get wallSet => 'Set background';

  @override
  String get wallSolid => 'Colour';

  @override
  String get wallSolidColor => 'Solid colour';

  @override
  String get anonAdminLabel => 'anonymous admin';

  @override
  String get anonAdmin => 'Remain anonymous';

  @override
  String get anonAdminInfo =>
      'When on, this admin\'s messages show the group\'s name and photo, and they don\'t appear in the member list. Earlier messages stay as they were. Hidden in the app only; the server still records which account sent them.';

  @override
  String get anonSelfInfo =>
      'When on, your messages show the group\'s name and photo and you\'re hidden from the member list. Earlier messages stay as they were. Hidden in the app only; the server still records which account sent them.';

  @override
  String get anonShort => 'anonymous';

  @override
  String get myTag => 'My tag';

  @override
  String get myTagAdd => 'Add my tag';

  @override
  String get myTagInfo =>
      'Shown next to your name in this group (up to 16 characters). Leave empty to remove it.';

  @override
  String get ownTags => 'Edit own tags';

  @override
  String get ownTagsInfo =>
      'When on, members can put a tag next to their own name from the group info. A tag an admin gave comes first. Admin tags are green, member tags grey.';

  @override
  String get antiSpam => 'Aggressive anti-spam';

  @override
  String get antiSpamIntro =>
      'Admins\' phones remove spam like ads, gambling and loans by themselves. The server can\'t read messages, so the phones of admins who may delete do the checking.';

  @override
  String get antiSpamInfo =>
      'Best for big groups of 200+. Admins\' messages and people marked \'Not spam\' are never removed. Removed messages scatter into dust on everyone\'s screen.';

  @override
  String get antiSpamChecks => 'What it catches';

  @override
  String get antiSpamCheckWords =>
      'Spam words like gambling, loans, signal groups';

  @override
  String get antiSpamCheckLinks =>
      'Links and contacts from new members (handles, invite links, phone numbers)';

  @override
  String get antiSpamCheckRepeat => 'The same message posted again and again';

  @override
  String get antiSpamCheckMentions => 'Mentioning many people at once (6+ @)';

  @override
  String get antiSpamCheckStrikes =>
      'Caught 3 times in a day: can\'t write for a day';

  @override
  String get antiSpamRemoved => 'Removed by anti-spam';

  @override
  String get antiSpamRemovedInfo =>
      'Messages this phone removed. If one wasn\'t spam, tap \'Not spam\': that person won\'t be checked again, and a spam mute is lifted.';

  @override
  String get antiSpamNone => 'Nothing removed yet';

  @override
  String get spamOk => 'Not spam';

  @override
  String get spamOkMark => 'Marked not spam';

  @override
  String spamOkDone(String name) {
    return '$name\'s messages won\'t be checked any more';
  }

  @override
  String logSpam(String name) {
    return 'Anti-spam removed a message from $name';
  }

  @override
  String logSpamOk(String name) {
    return 'Marked $name as not spam';
  }

  @override
  String groupReadCount(int n) {
    return '$n read';
  }

  @override
  String groupReadTitle(int n) {
    return '$n read';
  }

  @override
  String groupReadNotYet(int n) {
    return '$n haven\'t read it yet.';
  }

  @override
  String get groupReadInfo =>
      'Shown in groups of up to 100. Read times are kept for 7 days.';

  @override
  String groupReadToday(String time) {
    return 'today $time';
  }

  @override
  String groupReadYesterday(String time) {
    return 'yesterday $time';
  }

  @override
  String get draftFromOther => 'Picked up the draft from your other device';

  @override
  String toneGoing(String name, int n) {
    return 'Removing \'$name\' · ${n}s';
  }

  @override
  String soundChatDefault(String name) {
    return 'Default ($name)';
  }

  @override
  String get toneMine => 'My sounds';

  @override
  String get toneMineEmpty =>
      'Press and hold a voice message of 5 seconds or less in a chat and tap \'Save as alert sound\' to add it here.';

  @override
  String get toneMineInfo =>
      'Sounds are kept encrypted on this device. They play while you use the app; lock-screen alerts use the default sound for now.';

  @override
  String toneSeconds(int n) {
    return '${n}s';
  }

  @override
  String get toneNone => 'No saved sounds yet';

  @override
  String get toneOurs => 'Burumy sounds';

  @override
  String get saveAsTone => 'Save as alert sound';

  @override
  String get toneTooLong =>
      'Only sounds up to 5 seconds and 300 KB can be alert sounds';

  @override
  String toneFull(int n) {
    return 'You can keep up to $n alert sounds';
  }

  @override
  String toneDefaultName(String who, int n) {
    return '$who\'s sound $n';
  }

  @override
  String get toneSaved =>
      'Added to alert sounds. Pick it from a chat\'s alerts menu';

  @override
  String get toneForChat => 'Change alert sound';

  @override
  String get storageTitle => 'Storage';

  @override
  String get storageOther => 'Other temporary files';

  @override
  String get storageNoLimit => 'No limit';

  @override
  String storageClearing(String size, int n) {
    return 'Clearing $size · ${n}s';
  }

  @override
  String storageFreed(String size) {
    return 'Cleared $size';
  }

  @override
  String get storageFreedInfo =>
      'Your chats are untouched. Tap anything to download it again.';

  @override
  String get storageNothing => 'Nothing to clear';

  @override
  String get storageOnDevice => 'Used on this device';

  @override
  String storageOfTotal(String size) {
    return 'of $size';
  }

  @override
  String get storageKeepsChats =>
      'Don\'t worry: clearing keeps your chats and messages. Photos, videos and files download again when you tap them.';

  @override
  String storagePercent(int n) {
    return '$n%';
  }

  @override
  String storageClearButton(String size) {
    return 'Clear selected · $size';
  }

  @override
  String get storagePickKind => 'Pick what to clear';

  @override
  String get keepExceptions => 'Chat exceptions';

  @override
  String get keepExceptionInfo =>
      'Copies from this chat follow its own time. \'Never\' keeps them.';

  @override
  String get storageMaxTitle => 'Maximum storage';

  @override
  String get storageMaxInfo =>
      'Above this size, the copies opened longest ago go first. The phone and PC apps each keep their own limit.';

  @override
  String get storageAllChats => 'See all chats';

  @override
  String get storageBig => 'Largest files';

  @override
  String get storageTabMedia => 'Media';

  @override
  String get dataUsageTitle => 'Data usage';

  @override
  String get storageThisChat => 'This chat';

  @override
  String get usageMessages => 'Messages';

  @override
  String get usageCalls => 'Calls';

  @override
  String usageResetting(int n) {
    return 'Resetting statistics · ${n}s';
  }

  @override
  String get usageAll => 'All';

  @override
  String get usageCell => 'Mobile';

  @override
  String get usageWifi => 'Wi-Fi';

  @override
  String get usageUsed => 'Data used';

  @override
  String get usageInfo =>
      'Counted on this device only. Media are exact sizes, messages are their text size, calls are estimated from minutes talked.';

  @override
  String usageAbout(String size) {
    return '≈ $size';
  }

  @override
  String get usageSent => 'Sent';

  @override
  String get usageRecv => 'Received';

  @override
  String usageSentN(int n) {
    return 'Sent · $n';
  }

  @override
  String usageRecvN(int n) {
    return 'Received · $n';
  }

  @override
  String usageSince(String date) {
    return 'Counted since $date';
  }

  @override
  String get usageReset => 'Reset statistics';

  @override
  String get draftSync => 'Continue drafts on my devices';

  @override
  String get draftSyncSub =>
      'Pick up unsent text on your other devices. Sent encrypted, only between your own devices.';

  @override
  String get archiveSettings => 'Archive settings';

  @override
  String get archiveHow => 'How the archive works';

  @override
  String get archiveIntroTitle => 'This is your archive';

  @override
  String get archiveIntro1Title => 'A tidy chat list';

  @override
  String get archiveIntro1 =>
      'Move chats you rarely open here. They stay as they are.';

  @override
  String get archiveIntro2Title => 'Muted chats stay here';

  @override
  String get archiveIntro2 =>
      'Muted chats stay even when new messages come. Chats with alerts on come back to the list when someone writes — change it in Archive settings.';

  @override
  String get archiveIntro3Title => 'Swipe in and out';

  @override
  String get archiveIntro3 =>
      'Swipe a chat left to archive it; swipe again here to take it out.';

  @override
  String get archiveSettingsInfo =>
      'Choose when archived chats come back to your list. Kept on this phone only.';

  @override
  String get archiveUnmutedHeader => 'Chats with alerts on';

  @override
  String get archiveKeepUnmuted => 'Keep archived on new messages';

  @override
  String get archiveUnmutedInfo =>
      'When off, a chat with alerts on comes back to your list when someone writes. Muted chats always stay.';

  @override
  String get archiveFolderHeader => 'Chats in folders';

  @override
  String get archiveKeepFolder => 'Keep archived on new messages';

  @override
  String get archiveFolderInfo =>
      'Chats you added to a folder can stay archived — you still see them in that folder\'s tab.';

  @override
  String get archiveStrangerHeader => 'Unknown people';

  @override
  String get folderShare => 'Share folder';

  @override
  String get folderShareRowInfo =>
      'Send this folder\'s groups and channels to friends with one link.';

  @override
  String folderShareTitle(String name) {
    return 'Share \'$name\'';
  }

  @override
  String get folderShareInfo =>
      'Whoever opens the link adds the folder and joins the chats they pick in one tap.';

  @override
  String get folderShareChats => 'Chats in the link';

  @override
  String get folderShareChatsInfo =>
      '1:1 chats and chats without an invite link stay out. Each chat\'s own rules (approval, join questions) still apply.';

  @override
  String get folderShareNone => 'No groups or channels to share in this folder';

  @override
  String get folderShareNoLink => 'No invite link';

  @override
  String folderJoinTitle(String name) {
    return 'Add folder \'$name\'';
  }

  @override
  String get folderJoinInfo =>
      'You join the chats you pick, and a tab for this folder appears above your chat list.';

  @override
  String folderJoinChats(int n) {
    return '$n chats';
  }

  @override
  String get folderJoinIn => 'Already joined';

  @override
  String folderJoinGo(int n) {
    return 'Add folder and join $n';
  }

  @override
  String folderJoined(String name, int n) {
    return 'Added \'$name\' · $n chats';
  }

  @override
  String get folderJoinNone => 'No chats joined, so no folder was added';

  @override
  String folderJoinAsked(int n) {
    return '$n waiting for approval.';
  }

  @override
  String folderJoinFailed(int n) {
    return '$n couldn\'t be joined.';
  }

  @override
  String get accountPreviewEmpty => 'No chats yet';

  @override
  String get accountPreviewSwitch => 'Switch to this account';

  @override
  String onceGoesHours(int n) {
    return 'Gone in ${n}h if not opened';
  }

  @override
  String onceGoesMinutes(int n) {
    return 'Gone in ${n}m if not opened';
  }

  @override
  String onceOpenWithinHours(int n) {
    return 'Tap to open · ${n}h left';
  }

  @override
  String onceOpenWithinMinutes(int n) {
    return 'Tap to open · ${n}m left';
  }

  @override
  String zipCount(int n) {
    return '$n files';
  }

  @override
  String zipUnpacked(String size) {
    return '$size unpacked';
  }

  @override
  String zipFirstOnly(int n) {
    return 'first $n shown';
  }

  @override
  String get zipInfo =>
      'Shown without unpacking. Only the file you tap opens, in this phone\'s memory; nothing is saved or sent.';

  @override
  String get zipPassword =>
      'This archive has a password, so we can\'t look inside';

  @override
  String get zipEmpty => 'This archive is empty';

  @override
  String get zipTooBig => 'Over 50 MB unpacked, too big to open here';

  @override
  String get zipCantOpen => 'This file can\'t be opened';

  @override
  String get storyGroupOnly => 'One group only';

  @override
  String get storyGroupOnlySub => 'Only that group\'s members see it';

  @override
  String get storyGroupOnlyInfo =>
      'Every member of that group can see it, friends or not. Nobody else gets it.';

  @override
  String storyGroupOnlyLabel(String name) {
    return 'Only $name';
  }

  @override
  String storyGroupOnlyShared(String name) {
    return 'Shared with $name only';
  }

  @override
  String get textStickerTitle => 'Text sticker';

  @override
  String get textStickerSave => 'Send';

  @override
  String get textStickerHint => 'What you type below shows here as a sticker';

  @override
  String get textStickerPlain => 'Words';

  @override
  String get textStickerBubble => 'Bubble';

  @override
  String get textStickerBadge => 'Badge';

  @override
  String get textStickerTag => 'Tag';

  @override
  String get textStickerPlaceholder => 'Type a few words';

  @override
  String get textStickerTile => 'Text';

  @override
  String get pdfMarkAdd => 'Highlight';

  @override
  String get pdfMarkDone => 'Highlighted';

  @override
  String pdfMarks(int count) {
    return 'Highlights ($count)';
  }

  @override
  String get pdfMarksTitle => 'Highlights';

  @override
  String get pdfMarksInfo =>
      'Highlights stay on this phone. Nobody sees them unless you send them to the chat.';

  @override
  String pdfMarkPage(int page) {
    return 'Page $page';
  }

  @override
  String get pdfMarksSend => 'Send to the chat';

  @override
  String get pdfMarksSent => 'Sent to the chat';

  @override
  String pdfMarksQuote(String name) {
    return 'Highlights from $name';
  }

  @override
  String pdfMarkGoing(int seconds) {
    return 'Removing highlight ($seconds)';
  }

  @override
  String get pdfMarksHow => 'Hold on words to pick them, then tap Highlight.';

  @override
  String get appIconMarks => 'Burumy mark';

  @override
  String get appIconCharacters => 'Characters';

  @override
  String get appIconLogos => 'Other logos';

  @override
  String appIconLogo(String letter) {
    return 'Logo $letter';
  }

  @override
  String get linkSummaryButton => '3-line summary';

  @override
  String get linkSummaryBusy => 'Summarizing…';

  @override
  String get linkSummaryTitle => 'Summary · only you see it';

  @override
  String get linkSummaryFailed => 'Couldn\'t get the article. Try the reader.';

  @override
  String get linkSummaryHide => 'Hide summary';

  @override
  String shotLine(String name, String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'photo': 'a view-once photo',
      'video': 'a view-once video',
      'voice': 'a listen-once voice message',
      'round': 'a view-once round video',
      'file': 'a protected file',
      'bubble': 'a bubble',
      'other': 'the chat',
    });
    return '$name took a screenshot of $_temp0';
  }

  @override
  String shotLineMine(String what) {
    String _temp0 = intl.Intl.selectLogic(what, {
      'photo': 'a view-once photo',
      'video': 'a view-once video',
      'voice': 'a listen-once voice message',
      'round': 'a view-once round video',
      'file': 'a protected file',
      'bubble': 'a bubble',
      'other': 'the chat',
    });
    return 'You took a screenshot of $_temp0 · the chat was told';
  }

  @override
  String shotPreview(String name) {
    return '📸 $name took a screenshot';
  }

  @override
  String get shotPreviewMine => '📸 You took a screenshot';

  @override
  String get shotInfoTitle => 'Screenshot notice';

  @override
  String get shotInfoBody =>
      'Burumy blocks screenshots of view-once photos and videos, protected files and chats with sharing off. On Android a screenshot comes out black. An iPhone can\'t stop it, so the chat is told instead. The notice is end-to-end encrypted; the server never knows.';

  @override
  String get bestFriendSwitch => 'Best friend mark';

  @override
  String get bestFriendInfo =>
      'The friend you and they wrote to each other most in the last 2 weeks gets a ❤ by their name. Your phone counts it and only you see it; neither the server nor the friend knows.';

  @override
  String get bestFriendTip => 'Your best friend';

  @override
  String get bestFriendTipBody =>
      'You two wrote to each other most in the last 2 weeks. Only you see this ❤.';

  @override
  String memoriesTitle(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years ago today',
      one: '1 year ago today',
    );
    return '$_temp0';
  }

  @override
  String memoriesPreview(int years, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures',
      one: '1 picture',
    );
    String _temp1 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    return '📷 $_temp0 saved $_temp1 ago today';
  }

  @override
  String get memoriesOpen => 'View';

  @override
  String get memoriesSwitch => 'On this day';

  @override
  String get memoriesInfo =>
      'Your phone picks photos and videos you saved to Saved Messages on this day in earlier years and tells you on the Saved Messages row. Nothing new is uploaded or kept on a server.';

  @override
  String get memoriesSend => 'Send to a chat';

  @override
  String get memoriesGoTo => 'Show in Saved Messages';

  @override
  String get memoriesOnPhone => 'Picked by your phone · not kept on a server';

  @override
  String get feedComment => 'Comment';

  @override
  String get feedCommentHint => 'Add a comment…';

  @override
  String get feedCommentsKnown => 'Only friends\' comments are shown';

  @override
  String get feedCommentsMine => 'Your post: you see every comment';

  @override
  String feedCommentsMore(int n) {
    return 'View all $n comments';
  }

  @override
  String get feedCommentDelete => 'Delete comment';

  @override
  String get feedCommentsTitle => 'Comments';

  @override
  String get feedCommentsInfo =>
      'A comment goes encrypted to the poster only; the poster\'s phone passes the comments on to the friends who got the post. Each friend\'s phone shows only comments from people they know. The server never learns who is friends with whom.';

  @override
  String memoriesCount(int count) {
    return '$count';
  }

  @override
  String get accountSuspended =>
      'Your account is paused for now. There were several tries to break the rules with a changed app or a script. You can use it again when the pause ends; until then you can only leave chats. If this is a mistake, send an appeal.';

  @override
  String get accountWarned =>
      'This app looks changed. If the same tries go on, the account will be paused. Please use the official Burumy app.';

  @override
  String get pullCameraSwitch => 'Pull down for camera';

  @override
  String get pullCameraInfo =>
      'Pull the chat list down far from the top to open the camera. A short pull still shows the archive.';

  @override
  String get pullCameraMore => 'Pull more for camera';

  @override
  String get pullCameraLetGo => 'Let go to open the camera';

  @override
  String get aiFriendName => 'AI friend';

  @override
  String get aiFriendPreview => 'Talk with the AI on your phone';

  @override
  String get aiFriendLock => 'Only on this phone · nothing goes to a server';

  @override
  String get aiFriendHint => 'Message your AI friend';

  @override
  String get aiFriendHello =>
      'Hi! I\'m your Burumy AI friend. Ask me anything or let\'s work out what to say. Our chat never leaves this phone.';

  @override
  String get aiFriendIdea1 => 'Suggest something for dinner';

  @override
  String get aiFriendIdea2 => 'Write a birthday message for a friend';

  @override
  String get aiFriendIdea3 => 'What should I do this weekend?';

  @override
  String get aiFriendIdea4 => 'Say this in Korean: thanks for today';

  @override
  String get aiFriendThinking => 'Thinking…';

  @override
  String get aiFriendFailed =>
      'Couldn\'t answer just now. Try again in a moment.';

  @override
  String get aiFriendNoAi =>
      'This phone has no built-in AI, so the AI friend can\'t work here. It needs Apple Intelligence (iPhone) or Gemini Nano (Android).';

  @override
  String get aiFriendClear => 'Clear chat';

  @override
  String get aiFriendCleared => 'Chat with your AI friend cleared';

  @override
  String get aiFriendHide => 'Remove from chat list';

  @override
  String get aiFriendHidden =>
      'AI friend removed · turn it back on in Settings > Chats';

  @override
  String get aiFriendSwitch => 'Show AI friend in chats';

  @override
  String get aiFriendSwitchSub => 'Uses only the AI on this phone';

  @override
  String get aiFriendWrong => 'AI answers can be wrong';

  @override
  String get aiFriendCopy => 'Copy';

  @override
  String get aiFriendCopied => 'Copied';

  @override
  String get aiFriendShare => 'Send to a chat';

  @override
  String aiFriendAsk(String words) {
    return 'Ask your AI friend: $words';
  }

  @override
  String get shopTitle => 'Sticker shop';

  @override
  String get shopFree => 'Free stickers';

  @override
  String get shopFreeInfo =>
      'Stickers drawn by Burumy. Add one and it shows in your sticker panel right away.';

  @override
  String get shopPaid => 'Paid stickers';

  @override
  String get shopSoon => 'Coming soon';

  @override
  String get shopPaidInfo =>
      'Artist stickers and special packs can be bought here once payments open. No brand-ad stickers: Burumy has no ads.';

  @override
  String get shopFreeTag => 'Free';

  @override
  String shopMovingN(int n) {
    return '$n moving';
  }

  @override
  String get shopBy => 'Burumy';

  @override
  String get shopAdd => 'Add';

  @override
  String get shopAdded => 'Added';

  @override
  String get shopRemove => 'Remove';

  @override
  String get shopPrivacy =>
      'The server isn\'t told which stickers you add. Nothing is ranked on a server.';

  @override
  String get shopNew => 'New';

  @override
  String get shopOpen => 'Sticker shop';

  @override
  String get searchFeatures => 'Features & settings';

  @override
  String get searchChannelPosts => 'Posts in my channels';

  @override
  String get searchStickers => 'Stickers';

  @override
  String get searchAllPosts => 'All posts';

  @override
  String shopPackInfo(int count, int moving) {
    return '$count stickers · $moving moving';
  }

  @override
  String get shopSeenTitle => 'Sets seen in chats';

  @override
  String get aiFriendMore => 'More';

  @override
  String get searchFeatAiFriend => 'AI friend';

  @override
  String get searchFeatMemories => 'On this day';

  @override
  String get searchFeatBestFriend => 'Best friend mark';

  @override
  String get searchFeatLock => 'App lock & passwords';

  @override
  String get searchFeatPullCamera => 'Pull down for camera';

  @override
  String get dmInboxAll => 'All';

  @override
  String get dmInboxAllInfo =>
      'All messages to this channel in one place. Tap one to open that person’s chat.';

  @override
  String get accountSuspendedEdit =>
      'Your account is paused because someone tried to edit another person\'s message. The Burumy app can\'t do that, so it looks like a changed app or a script. If this is a mistake, send an appeal.';

  @override
  String get appealButton => 'Appeal';

  @override
  String get appealHint => 'Tell us what happened';

  @override
  String get appealInfo =>
      'Only the Burumy team reads this. Your chats stay hidden from them too. You can send one at a time.';

  @override
  String get appealSent =>
      'Appeal sent. The team will read it and decide whether to lift the pause.';

  @override
  String get appealWaiting =>
      'Your appeal is waiting. When the team lifts the pause, you can use your account right away.';

  @override
  String appealDenied(String date) {
    return 'The team decided to keep the pause. You can appeal again from $date.';
  }

  @override
  String suspendUntil(String date) {
    return 'Paused until $date';
  }

  @override
  String get suspendUntilLifted => 'Paused until the team lifts it';

  @override
  String get suspendReasonEdit => 'A try to edit someone else\'s message';

  @override
  String get suspendReasonApp =>
      'Several tries to break the rules with a changed app or a script';

  @override
  String get notSuspended => 'Your account isn\'t paused.';
}
