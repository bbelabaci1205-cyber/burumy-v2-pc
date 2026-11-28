// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// My profile (name, photo) and the info screen of a chat (members, leave).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'chat_import_ui.dart';

import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/looks.dart';
import '../core/features.dart';
import '../core/group_tools.dart';
import '../ui/emoji_status.dart' show StatusMark;
import '../core/error_log.dart';
import '../core/backend.dart';
import '../core/report_reasons.dart';
import '../core/room_links.dart';
import '../core/trust.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'community.dart' show CommunityIntroPage, CommunityPage;
import 'call_page.dart';
import 'birthday.dart';
import 'chat_page.dart' show openChat;
import '../core/saved_tags.dart';
import 'invites_blocked.dart';
import 'chat_mute_sheet.dart';
import 'common.dart';
import 'invite_links.dart';
import 'poster.dart';
import 'trust_ui.dart';
import 'chat_safety.dart' show mayTurnProtectOff, reportLabel, showProtectIntro, showReportSheet;
import 'links.dart';
import 'my_look.dart';
import 'message_sheets.dart' show showEmergencyWebNotice;
import 'ios.dart';
import 'glass.dart';
import 'photo_editor.dart';
import 'profile_header.dart';
import 'my_profile_page.dart';
import 'emoji_photo.dart';
import 'photo_suggest.dart';
import '../core/my_photos.dart';
import 'room_tools.dart';
import 'look_pages.dart' show RoomThemePage, pickTimer;
import 'look_studio.dart';
import 'settings_kit.dart';
import 'settings_more.dart' show MyQrPage;
import 'safety_pages.dart';
import '../core/safety.dart';
import 'login_safety_ui.dart' show DeleteByDatePage;
import '../core/room_rules.dart';
import '../core/room_texts.dart';
import 'formatting.dart' show plainText;
import 'new_chat_page.dart' show MembersPage;
import 'room_rules_pages.dart';
import 'stories.dart';
import 'story_camera.dart' show StoryCameraPage;
import 'story_keep.dart';
import 'verify_page.dart';
import 'ios_route.dart';
import 'wide.dart';

/// Round photo, or the initial-letter avatar when there is no photo.
class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar({super.key, required this.name, this.bytes, this.size = 54});
  final String name;
  final List<int>? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final b = bytes;
    if (b == null || b.isEmpty) return Avatar(name: name, size: size);
    return ClipOval(
      child: Image.memory(Uint8List.fromList(b), width: size, height: size, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }
}

/// Card at the top of Settings.
class MyProfileCard extends StatefulWidget {
  const MyProfileCard({super.key});
  @override
  State<MyProfileCard> createState() => _MyProfileCardState();
}

class _MyProfileCardState extends State<MyProfileCard> {
  String? name;
  List<int>? photo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (name == null) load();
  }

  Future<void> load() async {
    final b = AppScope.of(context).backend;
    final n = await b.myName();
    final ph = AppScope.of(context).myOwnPhoto ?? await b.myPhoto().catchError((_) => null);
    if (mounted) {
      setState(() {
        name = n;
        photo = ph;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return IosSection(
      children: [
        IosTile(
          key: const Key('my-profile'),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
          leadingSize: 60,
          leading: PhotoAvatar(name: name ?? '', bytes: photo, size: 60),
          title: Text(name ?? '', style: Tokens.cardTitle.style),
          subtitle: Text(displayId(s.backend.userId ?? ''), style: Tokens.caption.style),
          trailing: const IosChevron(),
          onTap: () async {
            // 내 프로필 (tip 445): first how others see me, 편집 from there.
            await Navigator.of(context).push(IosPageRoute(builder: (_) => Features.profile ? const MyProfileViewPage() : const ProfilePage()));
            await load();
          },
        ),
      ],
    );
  }
}

/// Edit my profile (Burumy v1 layout, iOS sheet look): photo with a menu,
/// first and last name, bio (70), my ID to copy, log out.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final first = TextEditingController();
  final last = TextEditingController();
  final bio = TextEditingController();
  String nameWas = '';
  String bioWas = '';
  List<int>? photo;
  bool loaded = false;
  bool copied = false;

  /// Why the new name can't be used (사칭 막기), or null.
  String? nameError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      loaded = true;
      final s = AppScope.of(context);
      final b = s.backend;
      b.myName().then((n) {
        nameWas = n;
        // The last name is kept on this phone so the two boxes come back
        // as they were typed; the server only knows the full name.
        final l = s.pref('last_name', '');
        if (l.isNotEmpty && n.endsWith(' $l')) {
          first.text = n.substring(0, n.length - l.length - 1);
          last.text = l;
        } else if (l.isNotEmpty && n.startsWith(l) && n.length > l.length) {
          first.text = n.substring(l.length);
          last.text = l;
        } else {
          first.text = n;
        }
        if (mounted) setState(() {});
      });
      final me = b.userId;
      final keptBio = s.pref('me_bio', '');
      if (keptBio.isNotEmpty) {
        bioWas = keptBio;
        bio.text = keptBio;
      } else if (me != null) {
        b.bioOf(me).then((t) {
          bioWas = t;
          if (mounted) bio.text = t;
        }, onError: (_) {});
      }
      photo = s.myOwnPhoto;
      if (photo == null) {
        b.myPhoto().then((p) {
          if (mounted) setState(() => photo = p);
        }, onError: (_) {});
      }
    }
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    bio.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final s = AppScope.read(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x == null || !mounted) return;
    final picked = await x.readAsBytes();
    if (!mounted) return;
    final bytes = await editProfilePhoto(context, picked);
    if (bytes == null || !mounted) return;
    if (mounted) setState(() => photo = bytes);
    await s.saveMyProfile(photo: bytes);
  }

  void photoMenu() {
    final l = L.of(context);
    showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          CupertinoActionSheetAction(
            key: const Key('photo-new'),
            onPressed: () {
              Navigator.pop(c);
              pickPhoto();
            },
            child: Text(l.newPhoto),
          ),
          // 이모지 사진 (tips 376 + 351) and 예전 사진 (tip 58).
          if (Features.profile)
            CupertinoActionSheetAction(
              key: const Key('photo-emoji'),
              onPressed: () async {
                Navigator.pop(c);
                final s = AppScope.read(context);
                final bytes = await makeEmojiPhoto(context);
                if (bytes == null || !mounted) return;
                setState(() => photo = bytes);
                await s.saveMyProfile(photo: bytes);
              },
              child: Text(l.emojiPhoto),
            ),
          if (Features.profile && (photo != null || MyPhotos.ids(AppScope.read(context)).isNotEmpty))
            CupertinoActionSheetAction(
              key: const Key('photo-old'),
              onPressed: () async {
                Navigator.pop(c);
                await Navigator.of(context).push(IosPageRoute(builder: (_) => const MyPhotosPage()));
                if (mounted) setState(() => photo = AppScope.read(context).myOwnPhoto);
              },
              child: Text(l.oldPhotos),
            ),
          if (photo != null)
            CupertinoActionSheetAction(
              key: const Key('photo-remove'),
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(c);
                final s = AppScope.read(context);
                if (mounted) setState(() => photo = null);
                await s.saveMyProfile(removePhoto: true);
              },
              child: Text(l.removePhoto),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
  }

  Future<void> save() async {
    final s = AppScope.read(context);
    final b = s.backend;
    final f = first.text.trim(), l = last.text.trim();
    if (f.isEmpty) return;
    // Korean puts the family name first with no space (김민지).
    final ko = Localizations.localeOf(context).languageCode == 'ko';
    final full = l.isEmpty ? f : (ko ? '$l$f' : '$f $l');
    if (full != nameWas) {
      // 사칭 막기: no check marks, no '공식' words (my own badge name is fine).
      final why = checkName(full, who: b.userId, badges: s.trust.badges, displayName: true);
      if (why.isNotEmpty) {
        if (mounted) setState(() => nameError = nameRefusal(L.of(context), why));
        return;
      }
      await b.setMyName(full);
      unawaited(b.trustSeen(full).catchError((_) {}));
    }
    await s.setPref('last_name', l);
    final t = bio.text.trim();
    if (t != bioWas) {
      try {
        await s.saveMyProfile(bio: t);
      } catch (e, st) {
        ErrorLog.add(e, st);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Widget field(Key key, TextEditingController c, String hint, {int? max, int maxLines = 1}) {
    final p = paletteOf(context);
    return CupertinoTextField.borderless(
      key: key,
      controller: c,
      placeholder: hint,
      maxLength: max,
      minLines: 1,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      style: Tokens.body.style.copyWith(color: p.label),
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2] + 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = displayId(s.backend.userId ?? '');
    final ok = first.text.trim().isNotEmpty;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: l.editProfile,
        tint: p.background,
        leading: const [GlassBack(close: true)],
        trailing: [GlassDone(key: const Key('profile-save'), onTap: ok ? save : null)],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + GlassTopBar.height, bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5]),
        children: [
          SizedBox(height: Tokens.space[2]),
          Center(
            child: GestureDetector(
              onTap: photoMenu,
              child: PhotoAvatar(name: first.text, bytes: photo, size: 94),
            ),
          ),
          Center(
            child: CupertinoButton(
              key: const Key('change-photo'),
              onPressed: photoMenu,
              child: Text(l.changePhoto, style: Tokens.body.style.copyWith(color: p.accent)),
            ),
          ),
          IosSection(
            footer: nameError != null ? sectionFooter(context, nameError!, error: true) : sectionFooter(context, '${l.nameHint} ${l.photoServerNote}'),
            children: [field(const Key('profile-name'), first, l.firstName, max: 64), field(const Key('profile-last'), last, l.lastName, max: 64)],
          ),
          // 공개 사진 (tip 374): when the real photo is hidden from some people.
          if (Features.profile && s.pref('who_photo', 'everyone') != 'everyone')
            IosSection(footer: sectionFooter(context, l.publicPhotoInfo), children: const [PublicPhotoTile()]),
          // 이름·프로필 꾸미기 (tips 402 + 409).
          IosSection(
            children: [
              NavRow(
                key: const Key('profile-look'),
                color: Palette.tilePink,
                icon: CupertinoIcons.sparkles,
                title: l.personLook,
                page: (_) => const PersonLookPage(),
              ),
            ],
          ),
          IosSection(
            header: sectionHeader(context, l.bio),
            footer: sectionFooter(context, l.bioInfo),
            children: [field(const Key('profile-bio'), bio, l.bio, max: 70, maxLines: 3)],
          ),
          IosSection(
            footer: sectionFooter(context, l.birthdayInfo),
            children: [
              IosTile(
                key: const Key('profile-birthday'),
                leading: iconTile(Palette.tilePink, CupertinoIcons.gift_fill),
                title: Text(l.birthday),
                additionalInfo: Text(birthdayText(l, s.pref('me_birthday', '')) ?? l.birthdayAdd),
                trailing: const IosChevron(),
                onTap: () => pickBirthday(context),
              ),
            ],
          ),
          // 프로필 스토리 (tips 392 / 534): stories kept past their hours.
          IosSection(
            children: [
              IosTile(
                key: const Key('profile-kept-stories'),
                leading: iconTile(Palette.tileOrange, CupertinoIcons.square_grid_2x2_fill),
                title: Text(l.skKeptMine),
                additionalInfo: Text('${s.keptStories.where((x) => x.mine && !x.group).length}'),
                trailing: const IosChevron(),
                onTap: () => openMyKept(context),
              ),
            ],
          ),
          IosSection(
            footer: sectionFooter(context, l.idInfo),
            children: [
              IosTile(
                key: const Key('profile-id'),
                leading: iconTile(Palette.tileGrey, CupertinoIcons.at),
                title: Text(l.myId),
                additionalInfo: Text(copied ? l.copied : id),
                trailing: Icon(CupertinoIcons.doc_on_doc, size: Tokens.listIconSmall, color: p.secondaryLabel),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: id));
                  if (mounted) setState(() => copied = true);
                },
              ),
            ],
          ),
          IosSection(
            children: [
              IosTile(
                key: const Key('profile-logout'),
                title: Center(
                  child: Text(l.logOut, style: Tokens.body.style.copyWith(color: Palette.tileRed)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  s.logout();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tap the chat title: who is in it, and leaving (5 s to undo).
class ChatInfoPage extends StatefulWidget {
  const ChatInfoPage({super.key, required this.roomId, required this.title, required this.isGroup, required this.isChannel});
  final String roomId;
  final String title;
  final bool isGroup;
  final bool isChannel;
  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  List<Member> members = const [];

  String get myRoomName {
    final me = AppScope.read(context).backend.userId;
    return members.where((m) => m.userId == me).firstOrNull?.name ?? '';
  }

  List<Msg> shared = const [];

  /// 저장 tab (tip 426): my saved-message copies that came from this chat.
  List<Msg> savedHere = const [];

  /// Turned my invitation down (contacts only) and not sent the link yet.
  List<String> inviteBlocked = const [];
  String? savedId;
  List<String> blockedIds = const [];
  int tab = 0;
  bool copied = false;
  String bio = '';
  String birthday = '';

  /// Balloons are flying on this visit.
  bool partyShown = false;
  String about = '';
  String role = 'member';
  bool hideMembers = false;
  Map<String, dynamic> cfg = const {};
  RoomLink link = const RoomLink();
  int requests = 0;
  bool linkCopied = false;
  int? leaving;
  int? removing;
  int? deleting;
  Timer? timer;
  bool peerVerified = false;
  List<ChatPreview> common = const [];

  /// Groups we are both in (Telegram's 그룹 tab).
  Future<void> loadCommon(String other) async {
    final st = AppScope.read(context);
    final out = <ChatPreview>[];
    for (final c in st.chats.where((c) => !c.isDirect && !c.isChannel)) {
      try {
        final m = await st.backend.members(c.roomId);
        if (m.any((x) => x.userId == other)) out.add(c);
      } catch (_) {}
    }
    if (mounted) setState(() => common = out);
  }

  Future<void> loadVerified() async {
    final b = AppScope.read(context).backend;
    final other = members.where((x) => x.userId != b.userId).firstOrNull?.userId;
    if (other == null) return;
    final v = await b.isUserVerified(other).catchError((_) => false);
    if (mounted) setState(() => peerVerified = v);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (members.isEmpty) {
      final b = AppScope.of(context).backend;
      b.members(widget.roomId).then((m) {
        if (mounted) setState(() => members = m);
        final other = m.where((x) => x.userId != b.userId).firstOrNull?.userId;
        if (!widget.isGroup && !widget.isChannel && other != null) {
          unawaited(loadVerified());
          unawaited(loadCommon(other));
          final st = AppScope.of(context);
          final c = st.cardOf(other, fresh: true);
          if (c != null) bio = c.bio;
          b.profileOf(other).then((c) {
            if (mounted) {
              setState(() {
                bio = c.bio;
                birthday = c.birthday;
              });
            }
          }, onError: (_) {});
        }
      });
      b.timeline(widget.roomId, limit: 300).then((m) {
        if (mounted) setState(() => shared = m.reversed.toList());
      }, onError: (_) {});
      final from = savedFrom(AppScope.read(context));
      if (from.containsValue(widget.roomId)) {
        b.savedRoom().then((saved) async {
          if (saved == null || saved == widget.roomId) return;
          final m = await b.timeline(saved, limit: 500);
          if (mounted) {
            setState(() {
              savedId = saved;
              savedHere = [
                for (final x in m.reversed)
                  if (from[x.id] == widget.roomId) x,
              ];
            });
          }
        }, onError: (_) {});
      }
      b.blocked().then((x) {
        if (mounted) setState(() => blockedIds = x);
      }, onError: (_) {});
      if (widget.isGroup || widget.isChannel) unawaited(loadRoom());
    }
  }

  /// Description, my role and the member-list switch.
  Future<void> loadRoom() async {
    final b = AppScope.of(context).backend;
    final r = await Future.wait([b.roomAbout(widget.roomId), b.myRole(widget.roomId)]);
    final hide = await b.roomSwitch(widget.roomId, 'hide_members');
    final m = await b.members(widget.roomId);
    final c = await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    final tg = widget.isGroup && !widget.isChannel ? await b.memberTags(widget.roomId).catchError((_) => const <String, String>{}) : const <String, String>{};
    final lk = await b.roomLink(widget.roomId).catchError((_) => const RoomLink());
    final admin = r[1] == 'owner' || r[1] == 'admin';
    final asks = admin && lk.approval ? (await b.joinRequests(widget.roomId).catchError((_) => const <JoinRequest>[])).length : 0;
    final blockedNow = mounted ? await blockedWaiting(AppScope.read(context), widget.roomId) : const <String>[];
    if (mounted) {
      setState(() {
        cfg = c;
        ownTags = tg;
        link = lk;
        requests = asks;
        inviteBlocked = blockedNow;
        about = r[0];
        role = r[1];
        hideMembers = hide;
        members = m;
      });
    }
  }

  bool get isAdmin => role == 'owner' || role == 'admin';

  /// 556: tags members put on themselves.
  Map<String, String> ownTags = const {};

  /// 94: anonymous admins aren't in the list members see.
  List<Member> get shownMembers => AnonAdmins.visible(members, cfg, viewerIsAdmin: isAdmin, me: AppScope.read(context).backend.userId ?? '');

  Future<void> editMyTag(Member me) async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => TagEditPage(roomId: widget.roomId, member: me, initial: ownTags[me.userId] ?? '', own: true),
      ),
    );
    await loadRoom();
  }

  /// Channels: only admins see subscribers. Groups: everyone, unless hidden.
  bool get showMembers => isAdmin || (!widget.isChannel && !hideMembers);

  /// What I may do here, by the owner's choice of admin rights.
  bool may(String right) => RoomRules.can(cfg, role, AppScope.read(context).backend.userId ?? '', right);

  Future<void> memberActions(Member m) async {
    final l = L.of(context);
    final s = AppScope.of(context);
    final b = s.backend;
    final owner = role == 'owner';
    final pending = RoomRules.handover(cfg);
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(m.name),
        actions: [
          // Admins can add admins (equal level) but only the owner removes.
          if (m.role == 'member' && may('add_admin') || m.role == 'admin' && owner)
            CupertinoActionSheetAction(
              key: const Key('member-admin'),
              onPressed: () => Navigator.pop(c, 'admin'),
              child: Text(m.role == 'admin' ? l.removeAdmin : l.makeAdmin),
            ),
          if (owner && m.role == 'admin')
            CupertinoActionSheetAction(key: const Key('member-rights'), onPressed: () => Navigator.pop(c, 'rights'), child: Text(l.adminRights)),
          if (may('info') && !widget.isChannel)
            CupertinoActionSheetAction(key: const Key('member-tag'), onPressed: () => Navigator.pop(c, 'tag'), child: Text(l.memberTag)),
          if (may('mute') && m.role == 'member' && !widget.isChannel)
            CupertinoActionSheetAction(key: const Key('member-mute'), onPressed: () => Navigator.pop(c, 'mute'), child: Text(l.muteMember)),
          if (may('mute') && m.role == 'muted')
            CupertinoActionSheetAction(key: const Key('member-unmute'), onPressed: () => Navigator.pop(c, 'unmute'), child: Text(l.unmuteMember)),
          if (!widget.isChannel)
            CupertinoActionSheetAction(key: const Key('member-history'), onPressed: () => Navigator.pop(c, 'history'), child: Text(l.sendHistory)),
          if (owner && pending == null && m.role != 'muted')
            CupertinoActionSheetAction(key: const Key('member-handover'), onPressed: () => Navigator.pop(c, 'handover'), child: Text(l.handover)),
          if (may('ban'))
            CupertinoActionSheetAction(
              key: const Key('member-remove'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'remove'),
              child: Text(widget.isChannel ? l.removeSubscriber : l.removeMember),
            ),
          if (may('ban'))
            CupertinoActionSheetAction(
              key: const Key('member-ban'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'ban'),
              child: Text(l.banMember),
            ),
          if (may('delete') && (m.role == 'member' || m.role == 'muted'))
            CupertinoActionSheetAction(
              key: const Key('member-wipe'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'wipe'),
              child: Text(l.wipeUser),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    try {
      switch (pick) {
        case 'admin':
          await b.setAdmin(widget.roomId, m.userId, m.role != 'admin');
          if (m.role == 'admin') {
            final fresh = await b.roomConfig(widget.roomId);
            if ((fresh['admin_rights'] as Map?)?.containsKey(m.userId) ?? false) {
              await b.setRoomConfig(widget.roomId, 'admin_rights', RoomRules.withRights(fresh, m.userId, null));
            }
          }
        case 'rights':
          await Navigator.of(context).push(IosPageRoute(builder: (_) => adminRightsPage(s, widget.roomId, m, cfg, l)));
        case 'tag':
          await Navigator.of(context).push(
            IosPageRoute(
              builder: (_) => TagEditPage(roomId: widget.roomId, member: m, initial: RoomRules.tagOf(cfg, m.userId)),
            ),
          );
        case 'mute':
          final secs = await pickMuteTime(context);
          if (secs == null) return;
          await muteMember(s, widget.roomId, m, secs);
        case 'unmute':
          await unmuteMember(s, widget.roomId, m.userId, m.name);
        case 'history':
          final n = await b.sendHistory(widget.roomId, m.userId);
          if (mounted) showStoryToast(context, l.sendHistoryDone(n, m.name));
        case 'handover':
          final days = await pickHandoverDays(context, m.name);
          if (days == null) return;
          await b.setMemberLevel(widget.roomId, m.userId, 100);
          await b.setRoomConfig(widget.roomId, 'handover', {'to': m.userId, 'until': b.clock.add(Duration(days: days)).millisecondsSinceEpoch});
          await s.logMod(widget.roomId, 'handover', m.name);
        case 'remove':
          await b.removeMember(widget.roomId, m.userId);
        case 'ban':
          await b.setBanned(widget.roomId, m.userId, true);
          if (mounted) await AppScope.read(context).logMod(widget.roomId, 'banned', m.name);
        case 'wipe':
          // 협박 공격 막기: everything this person wrote goes, then they're out
          // for good (an attack account posts many things, often long ago).
          final n = await wipeUser(b, widget.roomId, m.userId);
          if (mounted) await AppScope.read(context).logMod(widget.roomId, 'wiped', m.name, '$n');
      }
    } catch (_) {
      if (mounted) showStoryToast(context, l.saveFailed);
    }
    await loadRoom();
  }

  /// 방장 넘기기 in progress: the old owner finishes after the days pass;
  /// the new one can say no.
  Future<void> finishHandover(bool accept) async {
    final s = AppScope.read(context);
    final b = s.backend;
    final h = RoomRules.handover(cfg);
    if (h == null) return;
    try {
      if (accept) {
        await b.setMemberLevel(widget.roomId, b.userId!, 50);
      } else {
        await b.setMemberLevel(widget.roomId, b.userId!, 0);
      }
      await b.setRoomConfig(widget.roomId, 'handover', null);
    } catch (_) {
      if (mounted) showStoryToast(context, L.of(context).saveFailed);
    }
    await loadRoom();
  }

  /// "초대를 막은 사람 N명" → send them the invite link (tip 385).
  Future<void> sendLinksToBlocked() async {
    final l = L.of(context);
    final n = await showInvitesBlocked(context, roomId: widget.roomId, name: widget.title, channel: widget.isChannel, people: inviteBlocked);
    if (!mounted || n == 0) return;
    showStoryToast(context, n < 0 ? l.inviteLinkNone : l.inviteLinkSent(n));
    await loadRoom();
  }

  Future<void> addMembers() async {
    final added = await Navigator.of(context).push<bool>(
      IosPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddMembersPage(roomId: widget.roomId, already: [for (final m in members) m.userId]),
      ),
    );
    if (added == true) await loadRoom();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startLeave() {
    final s = AppScope.of(context);
    final nav = paneNav(context);
    setState(() => leaving = 5);
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (leaving! > 1) return setState(() => leaving = leaving! - 1);
      t.cancel();
      await s.backend.leave(widget.roomId);
      await s.refresh();
      nav.popUntil((r) => r.isFirst);
    });
  }

  /// Owner: delete the group or channel, with 5 s to take it back.
  void startDeleteRoom() {
    final s = AppScope.of(context);
    final nav = paneNav(context);
    setState(() => removing = 5);
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (removing! > 1) return setState(() => removing = removing! - 1);
      t.cancel();
      await deleteRoom(s.backend, widget.roomId);
      await s.refresh();
      nav.popUntil((r) => r.isFirst);
    });
  }

  Future<void> askDeleteRoom() async {
    final l = L.of(context);
    final ok = await showCupertinoModalPopup<bool>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(l.deleteRoomConfirm),
        message: Text(l.deleteRoomInfo),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('delete-room-ok'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, true),
            child: Text(widget.isChannel ? l.deleteChannel : l.deleteGroup),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (ok == true && mounted) startDeleteRoom();
  }

  Future<void> openTools() async {
    await Navigator.of(context).push(
      IosPageRoute(
        builder: (_) => ManageToolsPage(roomId: widget.roomId, isChannel: widget.isChannel, role: role),
      ),
    );
    await loadRoom();
  }

  void startDeleteForBoth() {
    final s = AppScope.of(context);
    final nav = paneNav(context);
    setState(() => deleting = 5);
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (deleting! > 1) return setState(() => deleting = deleting! - 1);
      t.cancel();
      await s.backend.deleteForBoth(widget.roomId);
      await s.refresh();
      nav.popUntil((r) => r.isFirst);
    });
  }

  bool get muted => AppScope.of(context).chats.where((c) => c.roomId == widget.roomId).firstOrNull?.muted ?? false;

  /// Telegram: the 알림 button opens the times menu (sound only, 1 h ... forever).
  Future<void> toggleMute() => openMuteSheet(context, widget.roomId, muted: muted);

  /// "더 보기": disappearing messages, clear my side, block.
  /// Profile report (WhatsApp / Viber "신고"): the same reasons as a
  /// message report. Messages are locked end to end, so the person's last
  /// [reportPersonMax] messages here travel with it, as the row says; no
  /// message from them = nothing the operator could read, so we say so.
  Future<void> reportPerson(String other, String name) async {
    final l = L.of(context);
    final s = AppScope.of(context);
    final pick = await showReportSheet(context);
    if (pick == null || !mounted) return;
    if (pick.code == ReportReasons.impersonation) {
      final done = await openSheet<bool>(context, (_) => ImpersonationReportPage(userId: other, name: name));
      if (done == true && mounted) await s.refreshTrust();
      return;
    }
    if (pick.code == ReportReasons.dislike) {
      // Nothing to hide on a profile: "그냥 싫어요" means block here.
      await s.backend.block(other, true).catchError((_) {});
      final x = await s.backend.blocked().catchError((_) => blockedIds);
      if (!mounted) return;
      setState(() => blockedIds = x);
      showStoryToast(context, l.reportBlockedSender);
      return;
    }
    final msgs = await s.backend.cachedMessages(widget.roomId).catchError((_) => const <Msg>[]);
    final theirs = [
      for (final m in msgs)
        if (m.sender == other && !m.mine && m.kind != 'locked') m,
    ];
    if (!mounted) return;
    if (theirs.isEmpty) return showStoryToast(context, l.reportPersonEmpty);
    final last = theirs.sublist(theirs.length > reportPersonMax ? theirs.length - reportPersonMax : 0);
    final t = DateFormat('MM.dd HH:mm');
    final shown = [for (final m in last) '[${t.format(m.time)}] ${m.kind == 'text' ? plainText(m.body ?? '') : previewTextL(l, kind: m.kind, body: m.body)}']
        .join('\n');
    final r = ReportReasons.find(pick.code);
    final label = [if (r != null && r.code.contains('.')) reportLabel(l, r.group), reportLabel(l, pick.code)].join(' > ');
    try {
      await s.backend.reportMessage(widget.roomId, last.last.id, ReportReasons.reportText(code: pick.code, label: label, note: pick.note), shown);
      if (mounted) showStoryToast(context, l.reportDone);
    } catch (_) {
      if (mounted) showStoryToast(context, l.reportFailed);
    }
  }

  /// Photos the big header goes through (tip 195): the one I chose for
  /// them first (나에게만 보이는 사진), then theirs; a group's / channel's.
  List<HeaderPhoto> headerPhotos(AppState st, String? other, bool direct) {
    final l = L.of(context);
    if (direct && other != null) {
      final mine = myPhotoFor(st, other);
      final theirs = st.cardPhoto(other);
      return [
        if (mine != null) HeaderPhoto(mine, label: l.photoMineForThem),
        if (theirs != null) HeaderPhoto(theirs, label: mine != null ? l.photoTheirs : ''),
      ];
    }
    final ph = direct ? null : st.roomPhoto(widget.roomId);
    return [if (ph != null) HeaderPhoto(ph)];
  }

  Future<void> openMore(String? other) async {
    final l = L.of(context);
    final s = AppScope.of(context);
    final canTimer = !widget.isChannel || await s.backend.canPost(widget.roomId);
    final canImport = await s.backend.canPost(widget.roomId).catchError((_) => false);
    // This chat on the hide / delete password lists (Eric 2026-11-26: room
    // items live on the chat, message items on the message).
    final ql = await s.backend.quietLists().catchError((_) => const <List<String>>[[], []]);
    final hidden = ql.first.contains(widget.roomId), toDelete = ql.last.contains(widget.roomId);
    final rc = await s.backend.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
    final protect = rc['protect'] == true;
    final direct = other != null && !widget.isGroup && !widget.isChannel;
    // 557: in a 1:1 only the one who turned it on may turn it off.
    final lockedByOther = Features.chatSafety && !mayTurnProtectOff(rc, direct: direct, me: s.backend.userId ?? '');
    final trusted = direct && Safety.friends(s.settings).contains(other);
    if (!mounted) return;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (canTimer) CupertinoActionSheetAction(key: const Key('more-timer'), onPressed: () => Navigator.pop(c, 'timer'), child: Text(l.timer)),
          CupertinoActionSheetAction(
            key: const Key('more-protect'),
            onPressed: () => Navigator.pop(c, 'protect'),
            child: Text(lockedByOther ? l.protectByOther : (protect ? l.protectOff : l.protectOn)),
          ),
          CupertinoActionSheetAction(key: const Key('more-clear'), onPressed: () => Navigator.pop(c, 'clear'), child: Text(l.clearChat)),
          // 다른 앱 대화 가져오기 (tips 244 + 254): into this chat.
          if (Features.chatImport && canImport)
            CupertinoActionSheetAction(key: const Key('more-import'), onPressed: () => Navigator.pop(c, 'import'), child: Text(l.importMenu)),
          // 날짜로 지우기 (tip 308).
          if (Features.loginSafety)
            CupertinoActionSheetAction(key: const Key('more-date-wipe'), onPressed: () => Navigator.pop(c, 'date-wipe'), child: Text(l.dateWipeMenu)),
          CupertinoActionSheetAction(
            key: const Key('more-hide-room'),
            onPressed: () => Navigator.pop(c, 'hide-room'),
            child: Text(hidden ? l.emergencyHideRoomOff : l.emergencyHideRoom),
          ),
          CupertinoActionSheetAction(
            key: const Key('more-delete-room'),
            onPressed: () => Navigator.pop(c, 'delete-room'),
            child: Text(toDelete ? l.emergencyDeleteOff : l.emergencyDeleteRoom),
          ),
          // 4-app board: start a new group with the people here (WeChat/LINE).
          if (widget.isGroup && !widget.isChannel && members.length > 1)
            CupertinoActionSheetAction(key: const Key('more-new-group'), onPressed: () => Navigator.pop(c, 'new-group'), child: Text(l.newGroupFromMembers)),
          if (direct)
            CupertinoActionSheetAction(
              key: const Key('more-wipe-trust'),
              onPressed: () => Navigator.pop(c, 'wipe-trust'),
              child: Text(trusted ? l.wipeTrustOff : l.wipeTrustOn),
            ),
          if (direct)
            CupertinoActionSheetAction(key: const Key('more-wipe-request'), onPressed: () => Navigator.pop(c, 'wipe-request'), child: Text(l.wipeRequest)),
          if (other != null && !widget.isGroup && !widget.isChannel)
            CupertinoActionSheetAction(
              key: const Key('more-block'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'block'),
              child: Text(blockedIds.contains(other) ? l.unblock : l.blockUser),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (!mounted || pick == null) return;
    switch (pick) {
      case 'new-group':
        final me = s.backend.userId;
        final people = [
          for (final m in members)
            if (m.userId != me) Person(userId: m.userId, name: m.name),
        ];
        await Navigator.of(context).push(
          IosPageRoute(
            builder: (_) => MembersPage(contacts: people, picked: {for (final x in people) x.userId}),
          ),
        );
      case 'protect':
        if (lockedByOther) {
          showStoryToast(context, l.protectOnlyOwner);
          return;
        }
        if (Features.chatSafety && !protect && !await showProtectIntro(context, direct: direct)) return;
        if (!mounted) return;
        try {
          await s.backend.setRoomConfig(widget.roomId, 'protect', protect ? null : true);
          if (Features.chatSafety) await s.backend.setRoomConfig(widget.roomId, 'protect_by', protect ? null : s.backend.userId);
          if (mounted) showStoryToast(context, protect ? l.protectOffDone : l.protectOnDone);
        } catch (_) {
          if (mounted) showStoryToast(context, l.saveFailed);
        }
      case 'wipe-trust':
        if (kIsWeb) return showEmergencyWebNotice(context);
        final list = Safety.friends(s.settings);
        if (!trusted && list.length >= Safety.maxFriends) {
          if (mounted) showStoryToast(context, l.wipeFriendsFull);
          return;
        }
        await s.setPref(Safety.friendsKey, (trusted ? list.where((x) => x != other) : [...list, other!]).join(','));
        if (mounted) showStoryToast(context, trusted ? l.wipeTrustRemoved : l.wipeTrustAdded);
      case 'wipe-request':
        await Navigator.of(context).push(
          IosPageRoute(
            builder: (_) => WipeRequestPage(roomId: widget.roomId, name: titleOf(s, widget.roomId, widget.title)),
          ),
        );
      case 'hide-room' || 'delete-room':
        if (kIsWeb) return showEmergencyWebNotice(context);
        final id = widget.roomId;
        final hide = [...ql.first.where((x) => x != id), if (pick == 'hide-room' && !hidden) id];
        final del = [...ql.last.where((x) => x != id), if (pick == 'delete-room' && !toDelete) id];
        await s.backend.setQuietLists(pick == 'hide-room' ? hide : ql.first, pick == 'delete-room' ? del : ql.last);
        if (!mounted) return;
        final on = pick == 'hide-room' ? !hidden : !toDelete;
        showStoryToast(context, pick == 'hide-room' ? (on ? l.emergencyHidden : l.emergencyUnhidden) : (on ? l.emergencyRoomMarked : l.emergencyUnmarked));
      case 'date-wipe':
        await Navigator.of(context).push(
          IosPageRoute(
            builder: (_) => DeleteByDatePage(
              roomId: widget.roomId,
              title: titleOf(s, widget.roomId, widget.title),
              direct: direct,
              peerName: direct ? titleOf(s, widget.roomId, widget.title) : null,
            ),
          ),
        );
      case 'timer':
        final now = await s.backend.timer(widget.roomId);
        if (!mounted) return;
        final secs = await pickTimer(context, now: now);
        if (secs != null && secs != now) await s.setChatTimer(widget.roomId, secs);
      case 'import':
        await openChatImport(context, roomId: widget.roomId, title: titleOf(s, widget.roomId, widget.title));
      case 'clear':
        final ok = await showCupertinoModalPopup<bool>(
          useRootNavigator: !Wide.on,
          context: context,
          builder: (c) => IosActionSheet(
            message: Text(l.clearChatInfo),
            actions: [
              CupertinoActionSheetAction(
                key: const Key('clear-ok'),
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(c, true),
                child: Text(l.clearChat),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          ),
        );
        if (ok == true) {
          await s.setPref('cleared:${widget.roomId}', '${DateTime.now().millisecondsSinceEpoch}');
          if (mounted) setState(() => shared = const []);
        }
      case 'block':
        await s.backend.block(other!, !blockedIds.contains(other));
        final x = await s.backend.blocked();
        if (mounted) setState(() => blockedIds = x);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final st = AppScope.of(context);
    final me = st.backend.userId;
    final other = members.where((m) => m.userId != me).firstOrNull?.userId;
    final title = titleOf(st, widget.roomId, widget.title);
    final memo = other == null ? '' : st.pref('memo:$other', '').trim();
    final direct = !widget.isGroup && !widget.isChannel;
    // Badge / label: the other person (1:1) or the owner (channel), with the
    // name they gave themselves (not my own alias for them).
    final row = st.chats.where((c) => c.roomId == widget.roomId).firstOrNull;
    final trustUser = direct ? other : (widget.isChannel ? row?.peer : null);
    final trustName = row?.name ?? widget.title;
    final theirStories = direct && other != null ? st.stories.where((x) => !x.mine && !x.group && x.sender == other).toList() : const <Story>[];
    // Kept on their profile past the hours (tips 392 / 534 / 468).
    final theirKept = direct && other != null ? st.keptStories.where((x) => !x.mine && !x.group && x.sender == other).toList() : const <Story>[];
    final rules = RoomTexts.of(st, widget.roomId, cfg).rules;
    final hereId = st.pref('chat_theme:${widget.roomId}', '');
    final themeHere = hereId.isEmpty ? l.useDefault : wallName(l, hereId);
    // 꾸미기 (tips 409 / 412 / 429): their profile cover or the room's.
    final roomLook = direct ? const RoomLook() : RoomLook.from(cfg);
    final personLook = direct && other != null ? lookOfUser(st, other) : const PersonLook();
    final coverColors = direct ? lookColors(personLook.cover) : lookColors(roomLook.cover);
    final coverIcons = direct ? personLook.coverIcons : roomLook.logo;
    final covered = coverColors.isNotEmpty || coverIcons.isNotEmpty;
    final onCover = covered ? const Color(0xFFFFFFFF) : null;
    String roleName(String r) => switch (r) {
      'owner' => l.owner,
      'admin' => l.admin,
      'muted' => l.mutedRole,
      _ => '',
    };
    // 멤버 태그 shows in place of the role word; admins' tags in colour,
    // a member's own tag (556) in grey. Admins see "익명" on anonymous ones.
    Widget? pill(Member m) {
      final tag = widget.isChannel ? null : MemberTags.of(cfg, ownTags, m.userId);
      final base = tag?.text ?? roleName(m.role);
      final anon = isAdmin && AnonAdmins.isOn(cfg, m.userId);
      final text = anon ? (base.isEmpty ? l.anonShort : '$base · ${l.anonShort}') : base;
      if (text.isEmpty) return null;
      final c = m.role == 'muted' ? Palette.tileRed : (m.role == 'member' || (tag != null && !tag.byAdmin) ? p.secondaryLabel : p.accent);
      return Container(
        key: Key('pill-${m.userId}'),
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] + 2, vertical: 3),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
        child: Text(text, style: Tokens.caption.style.copyWith(color: c)),
      );
    }

    // Their birthday today: balloons + confetti once a day (TelegramTips 446).
    final bdayToday = direct && other != null && isBirthdayOn(birthday, DateTime.now());
    if (bdayToday && !partyShown && st.pref('birthday_party:$other', '') != todayKey(DateTime.now())) {
      partyShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => st.setPref('birthday_party:$other', todayKey(DateTime.now())));
    }
    // Round photo (story ring when they have stories).
    final avatarW = GestureDetector(
      key: const Key('info-photo'),
      onTap: theirStories.isEmpty ? null : () => openStories(context, [theirStories], 0).then((_) => setState(() {})),
      child: StoryRing(
        key: const Key('info-story-ring'),
        size: theirStories.isEmpty ? Tokens.infoAvatar : Tokens.infoAvatar + 10,
        show: theirStories.isNotEmpty,
        fresh: theirStories.any((x) => !seenStories(st).contains(x.id)),
        child: Avatar(
          name: title,
          size: Tokens.infoAvatar,
          squircle: widget.isGroup,
          channel: widget.isChannel,
          roomId: widget.isGroup ? widget.roomId : null,
          userId: direct ? other : null,
          owner: widget.isChannel ? AppScope.of(context).chats.where((c) => c.roomId == widget.roomId).firstOrNull?.peer : null,
        ),
      ),
    );
    // [onPhoto]: white, left-aligned, on the big photo (tip 195).
    Widget nameRow(bool onPhoto) => Padding(
      padding: EdgeInsets.symmetric(horizontal: onPhoto ? 0 : Tokens.space[3]),
      child: Row(
        mainAxisAlignment: onPhoto ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              title,
              key: Key(onPhoto ? 'info-name-photo' : 'info-name'),
              textAlign: onPhoto ? TextAlign.start : TextAlign.center,
              maxLines: onPhoto ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Tokens.screenTitle.style.copyWith(color: onPhoto ? const Color(0xFFFFFFFF) : (onCover ?? p.label), fontWeight: FontWeight.w500),
            ),
          ),
          if (trustUser != null) TrustMark(key: Key(onPhoto ? 'info-trust-photo' : 'info-trust'), user: trustUser, name: trustName, size: 22),
          if (Features.emojiStickers && trustUser != null) StatusMark(key: Key(onPhoto ? 'info-status-photo' : 'info-status'), user: trustUser, size: 22),
          if (roomLook.emoji.isNotEmpty) ...[
            SizedBox(width: Tokens.space[0]),
            RoomStatusEmoji(key: Key(onPhoto ? 'info-status-emoji-photo' : 'info-status-emoji'), emoji: roomLook.emoji, size: 24),
          ],
        ],
      ),
    );
    // 사칭 막기: say plainly when this isn't who the name suggests.
    final warn = <Widget>[
      if (trustUser != null && trustWarning(l, st.trustOf(trustUser, trustName)).isNotEmpty)
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], 0),
          child: Text(
            trustWarning(l, st.trustOf(trustUser, trustName)),
            key: const Key('info-trust-warning'),
            textAlign: TextAlign.center,
            style: Tokens.preview.style.copyWith(color: st.trustOf(trustUser, trustName).checking ? Palette.tileOrange : Palette.tileRed),
          ),
        )
      else if (trustUser != null && st.trustOf(trustUser, trustName).official)
        Padding(
          padding: EdgeInsets.only(top: Tokens.space[0]),
          child: Text(
            l.trustOfficialInfo,
            key: const Key('info-trust-official'),
            textAlign: TextAlign.center,
            style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
          ),
        ),
    ];
    Widget subW(bool onPhoto) => Text(
      widget.isChannel
          ? l.subscribersCount(members.length)
          : (widget.isGroup ? l.membersCount(members.length) : displayId(members.where((m) => m.userId != me).firstOrNull?.userId ?? '')),
      style: Tokens.body.style.copyWith(color: onPhoto ? const Color(0xD9FFFFFF) : (onCover?.withValues(alpha: 0.8) ?? p.secondaryLabel)),
    );
    final aboutW = about.isEmpty
        ? null
        : Padding(
            key: const Key('info-about'),
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
            child: Text(
              about,
              textAlign: TextAlign.center,
              style: Tokens.preview.style.copyWith(color: onCover ?? p.label),
            ),
          );
    // Round buttons; on the big photo they turn into glass (tip 195).
    Widget actionsRow(bool onPhoto) {
      Widget act(String k, IconData icon, String label, VoidCallback onTap) => Expanded(
        child: onPhoto
            ? PhotoAction(key: Key('$k-photo'), icon: icon, label: label, onTap: onTap)
            : InfoAction(key: Key(k), icon: icon, label: label, onTap: onTap),
      );
      final gap = SizedBox(width: Tokens.space[1]);
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: onPhoto ? 0 : Tokens.space[3]),
        child: Row(
          children: [
            if (!widget.isGroup && !widget.isChannel) ...[
              act('info-voice-call', CupertinoIcons.phone_fill, l.callVoice, () => startCall(context, widget.roomId, widget.title, video: false)),
              gap,
              act('info-video-call', CupertinoIcons.video_camera_solid, l.callVideo, () => startCall(context, widget.roomId, widget.title, video: true)),
              gap,
            ],
            act('info-mute', muted ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill, muted ? l.chatUnmute : l.chatMute, toggleMute),
            gap,
            act('info-search', CupertinoIcons.search, l.searchInChat, () => Navigator.pop(context, 'search')),
            gap,
            act('info-more', CupertinoIcons.ellipsis, l.more, () => openMore(other)),
          ],
        ),
      );
    }

    final scaffold = CupertinoPageScaffold(
      backgroundColor: p.background,
      // No title at the top (Telegram, v1): the name shows once scrolled.
      navigationBar: GlassTopBar(
        title: title,
        titleOnScroll: true,
        leading: const [GlassBack()],
        trailing: [
          ?(direct && other != null
              ? GlassPill(
                  key: const Key('info-edit'),
                  text: l.edit,
                  onTap: () => Navigator.of(context).push(
                    IosPageRoute(
                      builder: (_) => ContactEditPage(userId: other, name: widget.title),
                    ),
                  ),
                )
              : (!direct && isAdmin
                    ? GlassPill(
                        key: const Key('info-edit'),
                        text: l.edit,
                        onTap: () async {
                          await Navigator.of(context).push(
                            IosPageRoute(
                              builder: (_) => RoomEditPage(roomId: widget.roomId, name: title, isChannel: widget.isChannel),
                            ),
                          );
                          if (!context.mounted) return;
                          await AppScope.of(context).refresh();
                          await loadRoom();
                        },
                      )
                    : null)),
        ],
        tint: p.background,
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          // The photo starts beside the round buttons, as in Telegram.
          padding: EdgeInsets.only(top: Features.profile ? 0 : MediaQuery.paddingOf(context).top + Tokens.space[3]),
          children: [
            if (Features.profile)
              CoverHeader(
                key: const Key('info-cover'),
                colors: coverColors,
                icons: coverIcons,
                child: ProfileTop(
                  key: const Key('info-top'),
                  photos: headerPhotos(st, other, direct),
                  avatar: avatarW,
                  avatarSize: theirStories.isEmpty ? Tokens.infoAvatar : Tokens.infoAvatar + 10,
                  onAvatarTap: theirStories.isEmpty ? null : () => openStories(context, [theirStories], 0).then((_) => setState(() {})),
                  name: nameRow,
                  sub: subW,
                  below: [...warn, ?aboutW],
                  actions: actionsRow,
                ),
              )
            else ...[
              CoverHeader(
                key: const Key('info-cover'),
                colors: coverColors,
                icons: coverIcons,
                extendTop: MediaQuery.paddingOf(context).top + Tokens.space[3],
                child: Column(
                  children: [
                    Center(child: avatarW),
                    SizedBox(height: Tokens.space[2]),
                    nameRow(false),
                    ...warn,
                    SizedBox(height: Tokens.nameToSub),
                    Center(child: subW(false)),
                    ?aboutW,
                  ],
                ),
              ),
              SizedBox(height: Tokens.space[5]),
              actionsRow(false),
            ],
            if (!direct && (link.public || (isAdmin && link.private)))
              IosSection(
                hasLeading: false,
                children: [
                  IosTile(
                    key: const Key('info-link'),
                    title: Text(l.linkTitle, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    subtitle: Text(
                      RoomLinks.shown(roomLinkText(link, name: title, channel: widget.isChannel)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Tokens.body.style.copyWith(color: p.accent),
                    ),
                    trailing: linkCopied
                        ? Text(l.copied, style: Tokens.caption.style.copyWith(color: p.secondaryLabel))
                        : GestureDetector(
                            key: const Key('info-link-qr'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              IosPageRoute(
                                builder: (_) => PosterPage(
                                  roomId: widget.roomId,
                                  name: title,
                                  link: roomLinkText(link, name: title, channel: widget.isChannel),
                                  isChannel: widget.isChannel,
                                ),
                              ),
                            ),
                            child: SizedBox(
                              width: Tokens.closeButton,
                              height: Tokens.closeButton,
                              child: Icon(CupertinoIcons.qrcode, color: p.accent, size: Tokens.listIcon),
                            ),
                          ),
                    onTap: () async {
                      await Clipboard.setData(
                        ClipboardData(
                          text: roomLinkText(link, name: title, channel: widget.isChannel),
                        ),
                      );
                      if (!mounted) return;
                      setState(() => linkCopied = true);
                      Timer(const Duration(seconds: 2), () => mounted ? setState(() => linkCopied = false) : null);
                    },
                  ),
                ],
              ),
            if (RoomRules.handover(cfg) case (final to, final until) when (widget.isGroup || widget.isChannel) && (to == me || role == 'owner'))
              IosSection(
                key: const Key('handover-card'),
                hasLeading: false,
                footer: sectionFooter(
                  context,
                  to == me
                      ? l.handoverIncoming(DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(until))
                      : l.handoverPending(
                          members.where((x) => x.userId == to).firstOrNull?.name ?? displayId(to),
                          DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag()).add_jm().format(until),
                        ),
                ),
                children: [
                  if (to == me)
                    IosTile(
                      key: const Key('handover-decline'),
                      title: Text(l.handoverDecline, style: const TextStyle(color: Palette.tileRed)),
                      onTap: () => finishHandover(false),
                    )
                  else
                    IosTile(
                      key: const Key('handover-finish'),
                      title: Text(l.handoverFinish, style: TextStyle(color: AppScope.of(context).backend.clock.isBefore(until) ? p.secondaryLabel : p.accent)),
                      onTap: AppScope.of(context).backend.clock.isBefore(until) ? null : () => finishHandover(true),
                    ),
                ],
              ),
            if ((widget.isGroup || widget.isChannel) && members.isNotEmpty && showMembers)
              IosSection(
                header: sectionHeader(context, widget.isChannel ? l.subscribers : l.members),
                footer: hideMembers && !widget.isChannel ? sectionFooter(context, l.hideMembersOnInfo) : null,
                children: [
                  if (isAdmin ? may('invite') : (!widget.isChannel && !hideMembers && RoomRules.memberMay(cfg, 'invite')))
                    IosTile(
                      key: const Key('info-add-member'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      leading: Icon(CupertinoIcons.person_badge_plus, color: p.accent, size: Tokens.tabIcon),
                      title: Text(l.addMembers, style: TextStyle(color: p.accent)),
                      onTap: addMembers,
                    ),
                  if (inviteBlocked.isNotEmpty && (isAdmin ? may('invite') : RoomRules.memberMay(cfg, 'invite')))
                    IosTile(
                      key: const Key('info-invites-blocked'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      leading: Icon(CupertinoIcons.link, color: p.accent, size: Tokens.tabIcon),
                      title: Text(l.invitesBlockedRow(inviteBlocked.length), style: TextStyle(color: p.accent)),
                      trailing: const IosChevron(),
                      onTap: sendLinksToBlocked,
                    ),
                  // 556: "내 태그" when the group lets members tag themselves.
                  if (!widget.isChannel && widget.isGroup && MemberTags.ownAllowed(cfg) && MemberTags.canEditOwn(cfg, role, me ?? ''))
                    IosTile(
                      key: const Key('info-my-tag'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      leading: Icon(CupertinoIcons.tag, color: p.accent, size: Tokens.tabIcon),
                      title: Text((ownTags[me] ?? '').isEmpty ? l.myTagAdd : l.myTag, style: TextStyle(color: p.accent)),
                      additionalInfo: (ownTags[me] ?? '').isEmpty ? null : Text(ownTags[me]!),
                      trailing: const IosChevron(),
                      onTap: () {
                        final mine = members.where((x) => x.userId == me).firstOrNull;
                        if (mine != null) unawaited(editMyTag(mine));
                      },
                    ),
                  for (final m in shownMembers)
                    // Telegram sizes: 40 photo, 60-tall row, role as a soft pill.
                    IosTile(
                      key: Key('member-${m.userId}'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                      leading: Avatar(name: m.name, size: Tokens.memberAvatar, userId: m.userId),
                      title: Text(m.userId == me ? '${m.name} (${l.you})' : m.name),
                      subtitle: Text(displayId(m.userId), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                      additionalInfo: pill(m),
                      onTap: isAdmin && m.userId != me && m.role != 'owner' && (role == 'owner' || m.role != 'admin') ? () => memberActions(m) : null,
                    ),
                ],
              )
            else if (widget.isChannel && !isAdmin)
              IosSection(
                hasLeading: false,
                footer: sectionFooter(context, l.subscribersHiddenInfo),
                children: [IosTile(title: Text(l.subscribersCount(members.length)))],
              ),
            if (!widget.isGroup && !widget.isChannel && other != null)
              IosSection(
                hasLeading: false,
                children: [
                  IosTile(
                    key: const Key('info-id'),
                    title: Text(l.idLabel, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    subtitle: Text(displayId(other), style: Tokens.body.style.copyWith(color: p.accent)),
                    trailing: copied
                        ? Text(l.copied, style: Tokens.caption.style.copyWith(color: p.secondaryLabel))
                        : GestureDetector(
                            key: const Key('info-qr'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              IosPageRoute(
                                builder: (_) => MyQrPage(userId: other, title: l.qrCode),
                              ),
                            ),
                            child: SizedBox(
                              width: Tokens.closeButton,
                              height: Tokens.closeButton,
                              child: Icon(CupertinoIcons.qrcode, color: p.accent, size: Tokens.listIcon),
                            ),
                          ),
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: displayId(other)));
                      if (!mounted) return;
                      setState(() => copied = true);
                      Timer(const Duration(seconds: 2), () => mounted ? setState(() => copied = false) : null);
                    },
                  ),
                  if (bio.isNotEmpty)
                    IosTile(
                      key: const Key('info-bio'),
                      title: Text(l.bio, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(bio, maxLines: 4, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  if (birthdayText(l, birthday) case final b?)
                    IosTile(
                      key: const Key('info-birthday'),
                      title: Text(l.birthday, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(isBirthdayOn(birthday, DateTime.now()) ? l.birthdayTodayLine(b) : b, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  if (memo.isNotEmpty)
                    IosTile(
                      key: const Key('info-memo'),
                      title: Text(l.memo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(memo, maxLines: 4, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  // 4-app board: report the person right here, with their
                  // last few messages (the line under it says so).
                  if (Features.chatSafety)
                    IosTile(
                      key: const Key('info-report'),
                      title: Text(l.reportPerson, style: const TextStyle(color: Palette.tileRed)),
                      subtitle: Text(l.reportPersonNote(reportPersonMax), style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      onTap: () => reportPerson(other, trustName),
                    ),
                  IosTile(
                    key: const Key('info-report-imp'),
                    title: Text(l.reportImpTitle, style: const TextStyle(color: Palette.tileRed)),
                    onTap: () async {
                      final done = await openSheet<bool>(context, (_) => ImpersonationReportPage(userId: other, name: trustName));
                      if (done == true && context.mounted) await AppScope.of(context).refreshTrust();
                    },
                  ),
                  IosTile(
                    key: const Key('info-block'),
                    title: Text(blockedIds.contains(other) ? l.unblock : l.blockUser, style: const TextStyle(color: Palette.tileRed)),
                    onTap: () async {
                      final b = AppScope.of(context).backend;
                      await b.block(other, !blockedIds.contains(other));
                      final x = await b.blocked();
                      if (mounted) setState(() => blockedIds = x);
                    },
                  ),
                ],
              ),
            if (theirStories.isNotEmpty)
              StoryShelf(
                stories: theirStories,
                title: l.storiesCount(theirStories.length),
                onOpen: (i) => openStories(context, [theirStories], 0, at: i).then((_) => setState(() {})),
              ),
            if (theirKept.isNotEmpty)
              KeptStories(
                stories: theirKept,
                onOpen: (list, i) => openStories(context, [list], 0, at: i).then((_) => setState(() {})),
              ),
            if (!direct && (isAdmin || rules.isNotEmpty || AppScope.of(context).communityOf(widget.roomId) != null))
              IosSection(
                children: [
                  // 커뮤니티 (Telegram: "Add Group to a Community" in group settings).
                  if (AppScope.of(context).communityOf(widget.roomId) case final com?)
                    IosTile(
                      key: const Key('info-community'),
                      leading: iconTile(p.tileGreen, CupertinoIcons.person_3_fill),
                      title: Text(l.community),
                      additionalInfo: Text(com.name),
                      trailing: const IosChevron(),
                      onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => CommunityPage(id: com.id))),
                    )
                  else if (isAdmin)
                    IosTile(
                      key: const Key('info-community-add'),
                      leading: iconTile(p.tileGreen, CupertinoIcons.person_3_fill),
                      title: Text(l.communityAdd),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await Navigator.of(context).push(IosPageRoute(builder: (_) => CommunityIntroPage(roomId: widget.roomId)));
                        await loadRoom();
                      },
                    ),
                  if (isAdmin)
                    IosTile(
                      key: const Key('info-invite-link'),
                      leading: iconTile(Palette.tileIndigo, CupertinoIcons.link),
                      title: Text(l.linkTitle),
                      additionalInfo: Text(link.public ? l.linkPublic : l.linkPrivate),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await Navigator.of(context).push(
                          IosPageRoute(
                            builder: (_) => InviteLinkPage(roomId: widget.roomId, name: title, isChannel: widget.isChannel),
                          ),
                        );
                        await loadRoom();
                      },
                    ),
                  // Tip 428: the group's own story, posted by an admin.
                  if (isAdmin)
                    IosTile(
                      key: const Key('info-group-story'),
                      leading: iconTile(Palette.tilePink, CupertinoIcons.plus_circle_fill),
                      title: Text(widget.isChannel ? l.skChannelStoryNew : l.skGroupStoryNew),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await openSheet<void>(context, (_) => StoryCameraPage(room: widget.roomId, roomName: title));
                        if (context.mounted) await AppScope.of(context).refresh();
                      },
                    ),
                  if (isAdmin && requests > 0)
                    IosTile(
                      key: const Key('info-requests'),
                      leading: iconTile(Palette.tileBlue, CupertinoIcons.person_2_fill),
                      title: Text(l.joinRequests),
                      additionalInfo: Text('$requests'),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await Navigator.of(context).push(IosPageRoute(builder: (_) => JoinRequestsPage(roomId: widget.roomId)));
                        await loadRoom();
                      },
                    ),
                  // 방마다 다른 이름 (v1): my name in this group only.
                  if (!widget.isChannel)
                    IosTile(
                      key: const Key('info-my-name'),
                      leading: iconTile(Palette.tileTeal, CupertinoIcons.person_crop_circle_fill),
                      title: Text(l.roomName),
                      additionalInfo: Text(myRoomName),
                      trailing: const IosChevron(),
                      onTap: () async {
                        await Navigator.of(context).push(
                          IosPageRoute(
                            builder: (_) => RoomNamePage(roomId: widget.roomId, current: myRoomName),
                          ),
                        );
                        await loadRoom();
                      },
                    ),
                  if (isAdmin)
                    IosTile(
                      key: const Key('info-tools'),
                      leading: iconTile(Palette.tileBlue, CupertinoIcons.shield_lefthalf_fill),
                      title: Text(l.manageTools),
                      trailing: const IosChevron(),
                      onTap: openTools,
                    ),
                  if (rules.isNotEmpty)
                    IosTile(
                      key: const Key('info-rules'),
                      leading: iconTile(Palette.tileOrange, CupertinoIcons.doc_text_fill),
                      title: Text(l.roomRules),
                      trailing: const IosChevron(),
                      onTap: () => Navigator.of(context).push(IosPageRoute(fullscreenDialog: true, builder: (_) => RulesSheet(rules: rules))),
                    ),
                ],
              ),
            IosSection(
              children: [
                // v1's top-right menu had "보안 코드 확인"; it lives here now.
                if (direct && other != null)
                  IosTile(
                    key: const Key('info-encryption'),
                    leading: iconTile(p.tileGreen, CupertinoIcons.lock_fill),
                    title: Text(l.encryption),
                    additionalInfo: Text(peerVerified ? l.encVerified : l.encNotVerified),
                    trailing: const IosChevron(),
                    onTap: () async {
                      await Navigator.of(context).push(
                        IosPageRoute(
                          builder: (_) => EncryptionPage(userId: other, name: title),
                        ),
                      );
                      await loadVerified();
                    },
                  ),
                IosTile(
                  key: const Key('info-theme'),
                  leading: iconTile(Palette.tileCyan, CupertinoIcons.paintbrush_fill),
                  title: Text(l.chatThemeHere),
                  additionalInfo: Text(themeHere),
                  trailing: const IosChevron(),
                  onTap: () => Navigator.of(context).push(
                    IosPageRoute(
                      builder: (_) => RoomThemePage(roomId: widget.roomId, direct: direct),
                    ),
                  ),
                ),
                // 채널·그룹 꾸미기 (tips 412 + 429): admins only.
                if (!direct && isAdmin)
                  IosTile(
                    key: const Key('info-room-look'),
                    leading: iconTile(Palette.tilePink, CupertinoIcons.sparkles),
                    title: Text(l.roomLook),
                    trailing: const IosChevron(),
                    onTap: () async {
                      await Navigator.of(context).push(
                        IosPageRoute(
                          builder: (_) => RoomLookPage(roomId: widget.roomId, title: title, channel: widget.isChannel, start: RoomLook.from(cfg)),
                        ),
                      );
                      await loadRoom();
                    },
                  ),
              ],
            ),
            IosSection(
              footer: sectionFooter(context, l.veilDotsInfo),
              children: [PrefSwitch('veil_dots:${widget.roomId}', title: l.veilDots)],
            ),
            IosSection(
              footer: sectionFooter(context, l.veilBlurInfo),
              children: [
                if (!widget.isChannel)
                  PrefSwitch('send_read:${widget.roomId}', title: l.readHere, icon: CupertinoIcons.checkmark_alt, color: p.tileGreen, fallback: true),
                PrefSwitch('veil_blur:${widget.roomId}', title: l.veilBlur, icon: CupertinoIcons.eye_slash_fill, color: Palette.tileGrey),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[2], Tokens.space[4], Tokens.space[2]),
              child: IosSegmented<int>(
                key: const Key('info-tabs'),
                groupValue: tab,
                children: {
                  0: Text(l.tabMedia),
                  1: Text(l.tabFiles),
                  2: Text(l.tabLinks),
                  if (direct) 3: Text(l.tabGroups),
                  if (widget.isGroup || widget.isChannel) 4: Text(l.tabPolls),
                  if (savedHere.isNotEmpty) 5: Text(l.tabSaved),
                },
                onValueChanged: (v) => setState(() => tab = v ?? 0),
              ),
            ),
            if (tab == 3)
              CommonGroups(chats: common)
            else if (tab == 5)
              SavedHereList(savedId: savedId!, msgs: savedHere)
            else
              SharedList(roomId: widget.roomId, msgs: shared, tab: tab),
            if (!widget.isGroup && !widget.isChannel)
              IosSection(
                footer: sectionFooter(context, l.deleteForBothInfo),
                children: [
                  if (deleting == null)
                    IosTile(
                      key: const Key('delete-both'),
                      leading: iconTile(Palette.tileRed, CupertinoIcons.trash),
                      title: Text(l.deleteForBoth, style: const TextStyle(color: Palette.tileRed)),
                      onTap: leaving == null ? startDeleteForBoth : null,
                    )
                  else
                    IosTile(
                      key: const Key('deleting'),
                      title: Text(l.deletingIn(deleting!), style: Tokens.body.style.copyWith(color: p.label)),
                      trailing: CupertinoButton(
                        key: const Key('delete-undo'),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          timer?.cancel();
                          setState(() => deleting = null);
                        },
                        child: Text(l.undo),
                      ),
                    ),
                ],
              ),
            if (!direct && role == 'owner')
              IosSection(
                footer: sectionFooter(context, l.deleteRoomInfo),
                children: [
                  if (removing == null)
                    IosTile(
                      key: const Key('delete-room'),
                      leading: iconTile(Palette.tileRed, CupertinoIcons.trash),
                      title: Text(widget.isChannel ? l.deleteChannel : l.deleteGroup, style: const TextStyle(color: Palette.tileRed)),
                      onTap: leaving == null ? askDeleteRoom : null,
                    )
                  else
                    IosTile(
                      key: const Key('removing'),
                      title: Text(l.deletingIn(removing!), style: Tokens.body.style.copyWith(color: p.label)),
                      trailing: CupertinoButton(
                        key: const Key('delete-room-undo'),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          timer?.cancel();
                          setState(() => removing = null);
                        },
                        child: Text(l.undo),
                      ),
                    ),
                ],
              ),
            IosSection(
              children: [
                if (leaving == null)
                  IosTile(
                    key: const Key('leave'),
                    leading: iconTile(Palette.tileRed, CupertinoIcons.square_arrow_right),
                    title: Text(widget.isChannel ? l.leaveChannel : l.leaveChat, style: const TextStyle(color: Palette.tileRed)),
                    onTap: deleting == null && removing == null ? startLeave : null,
                  )
                else
                  IosTile(
                    key: const Key('leaving'),
                    title: Text(l.leavingIn(leaving!), style: Tokens.body.style.copyWith(color: p.label)),
                    trailing: CupertinoButton(
                      key: const Key('leave-undo'),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        timer?.cancel();
                        setState(() => leaving = null);
                      },
                      child: Text(l.undo),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return partyShown
        ? Stack(
            children: [
              scaffold,
              const Positioned.fill(child: BirthdayParty()),
            ],
          )
        : scaffold;
  }
}

/// Round-cornered button under the chat name (iOS contact card style).
class InfoAction extends StatelessWidget {
  const InfoAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Tokens.infoTile,
        decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: p.accent, size: Tokens.listIcon + 2),
            const SizedBox(height: 3),
            Text(label, style: Tokens.caption.style.copyWith(color: p.accent)),
          ],
        ),
      ),
    );
  }
}

/// 저장 tab: what I saved from this chat; a tap opens it in 저장한 메시지.
class SavedHereList extends StatelessWidget {
  const SavedHereList({super.key, required this.savedId, required this.msgs});
  final String savedId;
  final List<Msg> msgs;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tags = savedTags(s);
    final fmt = DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    return IosSection(
      key: const Key('saved-here'),
      children: [
        for (final m in msgs)
          IosTile(
            key: Key('saved-here-${m.id}'),
            leading: iconTile(Palette.tileBlue, CupertinoIcons.bookmark_fill),
            title: Text(
              '${tags[m.id] == null ? '' : '${tags[m.id]} '}${previewText(context, kind: m.kind, body: m.body, caption: m.caption)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(fmt.format(m.time), style: Tokens.caption.style),
            onTap: () => openChat(context, savedId, L.of(context).savedMessages, jump: m.id),
          ),
      ],
    );
  }
}

/// Photos, files or links sent in a chat (chat info tabs).
class SharedList extends StatelessWidget {
  const SharedList({super.key, required this.roomId, required this.msgs, required this.tab});
  final String roomId;
  final List<Msg> msgs;
  final int tab;

  static final _link = RegExp(r'https?://[^\s]+');

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final list = switch (tab) {
      0 => msgs.where((m) => (m.kind == 'image' || m.kind == 'video') && !m.viewOnce).toList(),
      1 => msgs.where((m) => m.kind == 'file' || m.kind == 'audio').toList(),
      4 => msgs.where((m) => m.poll != null).toList(),
      _ => msgs.where((m) => m.kind == 'text' && _link.hasMatch(m.body ?? '')).toList(),
    };
    if (list.isEmpty) {
      return Padding(
        key: const Key('shared-empty'),
        padding: EdgeInsets.symmetric(vertical: Tokens.space[5]),
        child: Center(
          child: Text(l.nothingShared, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        ),
      );
    }
    if (tab == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final m in list) SharedThumb(roomId: roomId, msg: m)],
        ),
      );
    }
    if (tab == 4) {
      return IosSection(
        children: [
          for (final m in list)
            IosTile(
              key: Key('shared-${m.id}'),
              leading: iconTile(p.tileGreen, CupertinoIcons.chart_bar_fill),
              title: Text(m.poll!.question, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(m.time)} · ${m.poll!.closed ? l.pollClosedShort : l.pollVoters(m.poll!.voters)}',
                style: Tokens.caption.style,
              ),
            ),
        ],
      );
    }
    return IosSection(
      children: [
        for (final m in list)
          IosTile(
            key: Key('shared-${m.id}'),
            leading: iconTile(tab == 1 ? Palette.tileBlue : Palette.tileOrange, tab == 1 ? CupertinoIcons.doc_fill : CupertinoIcons.link),
            title: Text(tab == 1 ? (m.body ?? '') : _link.firstMatch(m.body ?? '')!.group(0)!, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(m.time), style: Tokens.caption.style),
            onTap: tab == 2 ? () => openWebLink(context, _link.firstMatch(m.body ?? '')!.group(0)!) : null,
          ),
      ],
    );
  }
}

class SharedThumb extends StatefulWidget {
  const SharedThumb({super.key, required this.roomId, required this.msg});
  final String roomId;
  final Msg msg;
  @override
  State<SharedThumb> createState() => _SharedThumbState();
}

class _SharedThumbState extends State<SharedThumb> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.msg.kind == 'image') bytes ??= AppScope.of(context).backend.downloadFile(widget.roomId, widget.msg.fileId);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: ColoredBox(
        color: p.card,
        child: bytes == null
            ? Icon(CupertinoIcons.play_fill, color: p.secondaryLabel)
            : FutureBuilder<List<int>>(
                future: bytes,
                builder: (_, b) => b.hasData ? Image.memory(Uint8List.fromList(b.data!), fit: BoxFit.cover) : const SizedBox.expand(),
              ),
      ),
    );
  }
}

/// My own name and note for a person (only on this phone, never sent).
class ContactEditPage extends StatefulWidget {
  const ContactEditPage({super.key, required this.userId, required this.name});
  final String userId;
  final String name;
  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  late final TextEditingController first;
  late final TextEditingController last;
  late final TextEditingController memo;
  bool ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    final s = AppScope.of(context);
    final id = widget.userId;
    // Older names were saved whole: they go into 이름.
    final f = s.pref('alias_first:$id', '');
    final g = s.pref('alias_last:$id', '');
    first = TextEditingController(text: f.isEmpty && g.isEmpty ? aliasOf(s, id) : f);
    last = TextEditingController(text: g);
    memo = TextEditingController(text: s.pref('memo:$id', ''));
    ready = true;
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    memo.dispose();
    super.dispose();
  }

  String get shown {
    final a = joinName(first.text, last.text, Localizations.localeOf(context).languageCode);
    return a.isEmpty ? widget.name : a;
  }

  Future<void> save() async {
    final s = AppScope.of(context);
    final id = widget.userId;
    await s.setPref('alias_first:$id', first.text.trim());
    await s.setPref('alias_last:$id', last.text.trim());
    await s.setPref('alias:$id', joinName(first.text, last.text, Localizations.localeOf(context).languageCode));
    await s.setPref('memo:$id', memo.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> pickPhoto() async {
    final s = AppScope.of(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256, imageQuality: 80);
    if (x == null) return;
    final ok = await setMyPhotoFor(s, widget.userId, await x.readAsBytes());
    if (!mounted) return;
    setState(() {});
    if (!ok) {
      await showCupertinoDialog<void>(
        useRootNavigator: !Wide.on,
        context: context,
        builder: (c) => CupertinoAlertDialog(
          content: Text(L.of(c).photoTooBig),
          actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(c), child: Text(L.of(c).okButton))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final hasPhoto = myPhotoFor(s, widget.userId) != null;
    Widget field(Key key, TextEditingController c, String hint, {int max = 64, int lines = 1}) => CupertinoTextField.borderless(
      key: key,
      controller: c,
      placeholder: hint,
      placeholderStyle: Tokens.body.style.copyWith(color: p.secondaryLabel),
      style: Tokens.body.style.copyWith(color: p.label),
      maxLength: max,
      minLines: 1,
      maxLines: lines,
      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3] + Tokens.space[0], vertical: Tokens.space[2] + 2),
      onChanged: (_) => setState(() {}),
    );
    // v1 layout: X, title, round accent check; photo; 이름 / 성; 메모 추가;
    // "X님의 사진 설정" (a photo only I see).
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.contactEdit),
        trailing: AccentCircle(key: const Key('contact-save'), icon: CupertinoIcons.checkmark_alt, onTap: save),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SizedBox(height: Tokens.space[3]),
            Center(
              child: Avatar(key: const Key('contact-avatar'), name: shown, userId: widget.userId, size: Tokens.infoAvatar),
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.contactNameInfo),
              children: [field(const Key('contact-first'), first, l.contactFirst), field(const Key('contact-last'), last, l.contactLast)],
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.memoInfo),
              children: [field(const Key('contact-memo'), memo, l.memoAdd, max: 500, lines: 6)],
            ),
            IosSection(
              footer: sectionFooter(context, Features.profile ? '${l.contactPhotoInfo(widget.name)} ${l.photoSuggestInfo}' : l.contactPhotoInfo(widget.name)),
              children: [
                IosTile(
                  key: const Key('contact-photo'),
                  leading: Icon(CupertinoIcons.camera, color: p.accent, size: Tokens.listIcon),
                  title: Text(l.contactPhotoSet(widget.name), style: TextStyle(color: p.accent)),
                  onTap: pickPhoto,
                ),
                // 사진 제안 (tip 373): they choose whether to use it.
                if (Features.profile)
                  IosTile(
                    key: const Key('contact-photo-suggest'),
                    leading: Icon(CupertinoIcons.person_crop_circle_badge_plus, color: p.accent, size: Tokens.listIcon),
                    title: Text(l.photoSuggest(widget.name), style: TextStyle(color: p.accent)),
                    onTap: () => suggestPhoto(context, widget.userId),
                  ),
                if (hasPhoto)
                  IosTile(
                    key: const Key('contact-photo-remove'),
                    leading: Icon(CupertinoIcons.trash, color: Palette.tileRed, size: Tokens.listIcon),
                    title: Text(l.contactPhotoRemove, style: const TextStyle(color: Palette.tileRed)),
                    onTap: () async {
                      await setMyPhotoFor(s, widget.userId, null);
                      if (mounted) setState(() {});
                    },
                  ),
              ],
            ),
            SizedBox(height: Tokens.space[5]),
          ],
        ),
      ),
    );
  }
}

/// Group / channel edit (admins): name, description and the switches.
class RoomEditPage extends StatefulWidget {
  const RoomEditPage({super.key, required this.roomId, required this.name, required this.isChannel});
  final String roomId;
  final String name;
  final bool isChannel;
  @override
  State<RoomEditPage> createState() => _RoomEditPageState();
}

class _RoomEditPageState extends State<RoomEditPage> {
  late final name = TextEditingController(text: widget.name);
  final about = TextEditingController();
  bool sign = false;
  bool hide = false;
  bool protect = false;
  bool ready = false;
  bool busy = false;

  /// 채널 묶음 #15: 472 작성자 프로필 보이기, 526 구독자 메시지 받기.
  bool authors = false;
  bool subscriberDm = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ready) return;
    ready = true;
    final b = AppScope.of(context).backend;
    () async {
      final a = await b.roomAbout(widget.roomId);
      final s = await b.roomSwitch(widget.roomId, 'sign');
      final h = await b.roomSwitch(widget.roomId, 'hide_members');
      final c = await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
      if (mounted) {
        setState(() {
          protect = c['protect'] == true;
          authors = c['authors'] == true;
          subscriberDm = c['subscriber_dm'] == true;
          about.text = a;
          sign = s;
          hide = h;
        });
      }
    }();
  }

  @override
  void dispose() {
    name.dispose();
    about.dispose();
    super.dispose();
  }

  /// Refusal for a reserved channel title.
  String? nameError;

  /// 그룹·채널 사진 (v1): pick, crop, and it is set at once (like my own
  /// photo). It travels encrypted; a public room's link card shows it too.
  Future<void> pickRoomPhoto() async {
    final s = AppScope.read(context);
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x == null || !mounted) return;
    final picked = await x.readAsBytes();
    if (!mounted) return;
    final bytes = await editProfilePhoto(context, picked);
    if (bytes == null || !mounted) return;
    await s.setRoomPhoto(widget.roomId, bytes);
  }

  void photoMenu() {
    final l = L.of(context);
    final has = AppScope.read(context).roomPhoto(widget.roomId) != null;
    showCupertinoModalPopup<void>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        message: Text(l.roomPhotoNote),
        actions: [
          CupertinoActionSheetAction(
            key: const Key('room-photo-new'),
            onPressed: () {
              Navigator.pop(c);
              pickRoomPhoto();
            },
            child: Text(l.newPhoto),
          ),
          // 이모지 사진 (tips 376 + 351) for groups and channels too.
          if (Features.profile)
            CupertinoActionSheetAction(
              key: const Key('room-photo-emoji'),
              onPressed: () async {
                Navigator.pop(c);
                final s = AppScope.read(context);
                final bytes = await makeEmojiPhoto(context);
                if (bytes != null && mounted) await s.setRoomPhoto(widget.roomId, bytes, mime: 'image/png');
              },
              child: Text(l.emojiPhoto),
            ),
          if (has)
            CupertinoActionSheetAction(
              key: const Key('room-photo-remove'),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(c);
                AppScope.read(context).setRoomPhoto(widget.roomId, null);
              },
              child: Text(l.removePhoto),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
  }

  Future<void> save() async {
    if (busy || name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      nameError = null;
    });
    final b = AppScope.of(context).backend;
    final l = L.of(context);
    try {
      if (name.text.trim() != widget.name && widget.isChannel) {
        var why = '';
        try {
          why = await b.nameCheck(name.text.trim(), room: true);
        } catch (_) {}
        if (why.isNotEmpty) {
          if (mounted) setState(() => nameError = nameRefusal(l, why));
          return;
        }
      }
      if (name.text.trim() != widget.name) await b.setRoomName(widget.roomId, name.text.trim());
      if (about.text.trim() != await b.roomAbout(widget.roomId)) await b.setRoomAbout(widget.roomId, about.text.trim());
      final key = widget.isChannel ? 'sign' : 'hide_members';
      final want = widget.isChannel ? sign : hide;
      if (want != await b.roomSwitch(widget.roomId, key)) await b.setRoomSwitch(widget.roomId, key, want);
      final c = await b.roomConfig(widget.roomId).catchError((_) => <String, dynamic>{});
      if (Features.channelTips && widget.isChannel) {
        final a = sign && authors;
        if (a != (c['authors'] == true)) await b.setRoomConfig(widget.roomId, 'authors', a ? true : null);
        if (subscriberDm != (c['subscriber_dm'] == true)) await b.setRoomConfig(widget.roomId, 'subscriber_dm', subscriberDm ? true : null);
      }
      if (protect != (c['protect'] == true)) {
        await b.setRoomConfig(widget.roomId, 'protect', protect ? true : null);
        if (Features.chatSafety) await b.setRoomConfig(widget.roomId, 'protect_by', protect ? b.userId : null);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final field = Tokens.body.style.copyWith(color: p.label);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(),
        middle: Text(widget.isChannel ? l.editChannel : l.editGroup),
        trailing: GlassPill(key: const Key('room-save'), text: l.done, onTap: save),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: ListView(
          children: [
            SizedBox(height: Tokens.space[4]),
            Center(
              child: GestureDetector(
                key: const Key('room-photo'),
                onTap: photoMenu,
                child: Avatar(
                  name: name.text.trim().isEmpty ? widget.name : name.text.trim(),
                  size: 90,
                  squircle: true,
                  channel: widget.isChannel,
                  roomId: widget.roomId,
                ),
              ),
            ),
            Center(
              child: CupertinoButton(
                key: const Key('room-photo-change'),
                onPressed: photoMenu,
                child: Text(l.changePhoto, style: Tokens.body.style.copyWith(color: p.accent)),
              ),
            ),
            IosSection(
              hasLeading: false,
              children: [
                CupertinoTextField.borderless(
                  key: const Key('room-name'),
                  controller: name,
                  placeholder: l.name,
                  maxLength: 128,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                  onChanged: (_) => setState(() => nameError = null),
                ),
                if (nameError != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(Tokens.space[2], 0, Tokens.space[2], Tokens.space[1]),
                    child: Text(
                      nameError!,
                      key: const Key('room-name-error'),
                      style: Tokens.caption.style.copyWith(color: Palette.tileRed),
                    ),
                  ),
                CupertinoTextField.borderless(
                  key: const Key('room-about'),
                  controller: about,
                  placeholder: l.aboutHint,
                  maxLength: 255,
                  minLines: 1,
                  maxLines: 4,
                  style: field,
                  padding: EdgeInsets.all(Tokens.space[2]),
                ),
              ],
            ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(
                context,
                widget.isChannel ? (Features.channelTips && sign ? '${l.signPostsInfo}\n\n${l.showAuthorsInfo}' : l.signPostsInfo) : l.hideMembersInfo,
              ),
              children: [
                IosTile(
                  title: Text(widget.isChannel ? l.signPosts : l.hideMembers),
                  trailing: IosSwitch(
                    key: const Key('room-switch'),
                    value: widget.isChannel ? sign : hide,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => widget.isChannel ? sign = v : hide = v),
                  ),
                ),
                if (Features.channelTips && widget.isChannel && sign)
                  IosTile(
                    title: Text(l.showAuthors),
                    trailing: IosSwitch(
                      key: const Key('room-authors'),
                      value: authors,
                      activeTrackColor: p.accent,
                      onChanged: (v) => setState(() => authors = v),
                    ),
                  ),
              ],
            ),
            if (Features.channelTips && widget.isChannel)
              IosSection(
                hasLeading: false,
                footer: sectionFooter(context, l.subscriberDmInfo),
                children: [
                  IosTile(
                    title: Text(l.subscriberDm),
                    trailing: IosSwitch(
                      key: const Key('room-subscriber-dm'),
                      value: subscriberDm,
                      activeTrackColor: p.accent,
                      onChanged: (v) => setState(() => subscriberDm = v),
                    ),
                  ),
                ],
              ),
            IosSection(
              hasLeading: false,
              footer: sectionFooter(context, l.protectInfo),
              children: [
                IosTile(
                  title: Text(l.protect),
                  trailing: IosSwitch(
                    key: const Key('room-protect'),
                    value: protect,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => protect = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick contacts to add to a group or channel.
class AddMembersPage extends StatefulWidget {
  const AddMembersPage({super.key, required this.roomId, required this.already});
  final String roomId;
  final List<String> already;
  @override
  State<AddMembersPage> createState() => _AddMembersPageState();
}

class _AddMembersPageState extends State<AddMembersPage> {
  List<Person>? people;
  final chosen = <String>{};
  bool busy = false;

  /// 최근 메시지 같이 보내기 (groups; channels already show their posts).
  bool shareHistory = false;
  bool channel = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (people != null) return;
    people = const [];
    AppScope.of(context).backend.isChannel(widget.roomId).then((c) {
      if (mounted) setState(() => channel = c);
    }, onError: (_) {});
    AppScope.of(context).backend.contacts().then((x) {
      if (mounted)
        setState(
          () => people = [
            for (final p in x)
              if (!widget.already.contains(p.userId)) p,
          ],
        );
    }, onError: (_) {});
  }

  Future<void> add() async {
    if (chosen.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      final b = AppScope.of(context).backend;
      await b.inviteUsers(widget.roomId, chosen.toList());
      if (shareHistory && !channel) {
        for (final u in chosen) {
          await b.sendHistory(widget.roomId, u).catchError((_) => 0);
        }
      }
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final list = people ?? const [];
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(
        leading: const GlassBack(close: true),
        middle: Text(l.addMembers),
        trailing: Opacity(
          opacity: chosen.isEmpty ? 0.4 : 1,
          child: GlassPill(key: const Key('add-members-ok'), text: l.add, onTap: chosen.isEmpty ? null : add),
        ),
        backgroundColor: p.background,
        border: null,
      ),
      child: SafeArea(
        child: list.isEmpty
            ? Center(
                child: Text(l.noContacts, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
              )
            : ListView(
                children: [
                  if (!channel)
                    IosSection(
                      footer: sectionFooter(context, l.shareHistoryInfo),
                      children: [
                        IosTile(
                          title: Text(l.shareHistory),
                          trailing: IosSwitch(
                            key: const Key('add-share-history'),
                            value: shareHistory,
                            activeTrackColor: p.accent,
                            onChanged: (v) => setState(() => shareHistory = v),
                          ),
                        ),
                      ],
                    ),
                  IosSection(
                    children: [
                      for (final c in list)
                        IosTile(
                          key: Key('add-${c.userId}'),
                          leading: Avatar(name: aliasOf(s, c.userId).isEmpty ? c.name : aliasOf(s, c.userId), size: 32),
                          title: Text(aliasOf(s, c.userId).isEmpty ? c.name : aliasOf(s, c.userId)),
                          subtitle: Text(displayId(c.userId), style: Tokens.caption.style),
                          trailing: Icon(
                            chosen.contains(c.userId) ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                            color: chosen.contains(c.userId) ? p.accent : p.secondaryLabel,
                          ),
                          onTap: () => setState(() => chosen.contains(c.userId) ? chosen.remove(c.userId) : chosen.add(c.userId)),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

/// Instagram's round "highlights", here the person's stories of today:
/// a small picture in a circle with how long ago, tap to watch.
class StoryShelf extends StatelessWidget {
  const StoryShelf({super.key, required this.stories, required this.title, required this.onOpen});
  final List<Story> stories;
  final String title;
  final void Function(int i) onOpen;

  static const size = 64.0;

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final l = L.of(context);
    return Column(
      key: const Key('info-stories'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: EdgeInsets.fromLTRB(Tokens.space[5], Tokens.space[4], Tokens.space[3], Tokens.space[1]), child: sectionHeader(context, title)),
        SizedBox(
          height: size + Tokens.space[4] + Tokens.space[1],
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            itemCount: stories.length,
            separatorBuilder: (_, _) => SizedBox(width: Tokens.space[2]),
            itemBuilder: (context, i) => GestureDetector(
              key: Key('info-story-$i'),
              onTap: () => onOpen(i),
              child: Column(
                children: [
                  Container(
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.separator),
                    ),
                    child: ClipOval(child: StoryThumb(story: stories[i])),
                  ),
                  SizedBox(height: Tokens.space[0]),
                  Text(agoLabel(l, stories[i].time), style: Tokens.caption.style.copyWith(color: p.label)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Telegram's 그룹 tab: groups we are both in.
class CommonGroups extends StatelessWidget {
  const CommonGroups({super.key, required this.chats});
  final List<ChatPreview> chats;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    if (chats.isEmpty) {
      return Padding(
        key: const Key('common-empty'),
        padding: EdgeInsets.symmetric(vertical: Tokens.space[5]),
        child: Center(
          child: Text(l.noCommonGroups, style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
        ),
      );
    }
    return IosSection(
      children: [
        for (final c in chats)
          IosTile(
            key: Key('common-${c.roomId}'),
            leadingSize: Tokens.memberAvatar,
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
            leading: Avatar(name: c.name, size: Tokens.memberAvatar, squircle: true, roomId: c.roomId),
            title: Text(c.name),
          ),
      ],
    );
  }
}

/// "3월 14일" from "MM-DD" (or "YYYY-MM-DD"); null when none.
String? birthdayText(L l, String b) {
  final p = b.split('-');
  if (p.length < 2) return null;
  final m = int.tryParse(p[p.length - 2]), d = int.tryParse(p.last);
  if (m == null || d == null) return null;
  return l.birthdayMonthDay(m, d);
}

/// Month and day wheels (iOS), saved as "MM-DD": friends never see a year.
Future<void> pickBirthday(BuildContext context) async {
  final s = AppScope.read(context);
  final l = L.of(context);
  final p = paletteOf(context);
  final was = s.pref('me_birthday', '').split('-');
  var m = was.length >= 2 ? int.tryParse(was[was.length - 2]) ?? 1 : 1;
  var d = was.length >= 2 ? int.tryParse(was.last) ?? 1 : 1;
  String two(int x) => x.toString().padLeft(2, '0');
  final had = s.pref('me_birthday', '').isNotEmpty;
  final picked = await showCupertinoModalPopup<String>(
    context: context,
    useRootNavigator: !Wide.on,
    builder: (c) => Container(
      color: p.card,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(c).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (had)
                CupertinoButton(
                  key: const Key('birthday-remove'),
                  onPressed: () => Navigator.pop(c, ''),
                  child: Text(l.birthdayRemove, style: Tokens.body.style.copyWith(color: Palette.tileRed)),
                ),
              const Spacer(),
              CupertinoButton(
                key: const Key('birthday-done'),
                onPressed: () => Navigator.pop(c, '${two(m)}-${two(d)}'),
                child: Text(l.done, style: Tokens.body.style.copyWith(color: p.accent)),
              ),
            ],
          ),
          SizedBox(
            height: 216,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    key: const Key('birthday-month'),
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(initialItem: m - 1),
                    onSelectedItemChanged: (i) => m = i + 1,
                    children: [for (var i = 1; i <= 12; i++) Center(child: Text(l.birthdayMonthDay(i, 1).split(' ').first.replaceAll('/1', '')))],
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    key: const Key('birthday-day'),
                    itemExtent: 32,
                    scrollController: FixedExtentScrollController(initialItem: d - 1),
                    onSelectedItemChanged: (i) => d = i + 1,
                    children: [for (var i = 1; i <= 31; i++) Center(child: Text('$i'))],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  // 2월 30일 같은 날은 그 달의 마지막 날로.
  var value = picked;
  if (picked.isNotEmpty) {
    final last = DateTime(2024, m + 1, 0).day;
    value = '${two(m)}-${two(d > last ? last : d)}';
  }
  try {
    await s.saveMyProfile(birthday: value);
  } catch (e, st) {
    ErrorLog.add(e, st);
  }
}

/// How many of their latest messages a profile report carries.
const reportPersonMax = 5;
