// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// My profile (name, photo) and the info screen of a chat (members, leave).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'call_page.dart';
import 'chat_page.dart' show timerLabel;
import 'common.dart';
import 'ios.dart';
import 'glass.dart';
import 'photo_editor.dart';
import 'room_tools.dart';
import 'wallpaper.dart';
import 'settings_kit.dart';
import 'settings_more.dart' show MyQrPage;
import 'stories.dart';
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
    final ph = await b.myPhoto().catchError((_) => null);
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
        CupertinoListTile(
          key: const Key('my-profile'),
          padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
          leadingSize: 60,
          leading: PhotoAvatar(name: name ?? '', bytes: photo, size: 60),
          title: Text(name ?? '', style: Tokens.cardTitle.style),
          subtitle: Text(displayId(s.backend.userId ?? ''), style: Tokens.caption.style),
          trailing: const CupertinoListTileChevron(),
          onTap: () async {
            await Navigator.of(context).push(IosPageRoute(builder: (_) => const ProfilePage()));
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
      if (me != null) {
        b.bioOf(me).then((t) {
          bioWas = t;
          if (mounted) bio.text = t;
        }, onError: (_) {});
      }
      b.myPhoto().then((p) {
        if (mounted) setState(() => photo = p);
      }, onError: (_) {});
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
    final b = AppScope.read(context).backend;
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (x == null || !mounted) return;
    final picked = await x.readAsBytes();
    if (!mounted) return;
    final bytes = await editProfilePhoto(context, picked);
    if (bytes == null || !mounted) return;
    await b.setMyPhoto('image/png', bytes);
    if (mounted) setState(() => photo = bytes);
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
          if (photo != null)
            CupertinoActionSheetAction(
              key: const Key('photo-remove'),
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(c);
                await AppScope.read(context).backend.setMyPhoto('image/png', const []);
                if (mounted) setState(() => photo = null);
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
    if (full != nameWas) await b.setMyName(full);
    await s.setPref('last_name', l);
    final t = bio.text.trim();
    if (t != bioWas) {
      try {
        await b.setMyBio(t);
      } catch (_) {}
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
            footer: sectionFooter(context, '${l.nameHint} ${l.photoServerNote}'),
            children: [field(const Key('profile-name'), first, l.firstName, max: 64), field(const Key('profile-last'), last, l.lastName, max: 64)],
          ),
          IosSection(
            header: sectionHeader(context, l.bio),
            footer: sectionFooter(context, l.bioInfo),
            children: [field(const Key('profile-bio'), bio, l.bio, max: 70, maxLines: 3)],
          ),
          IosSection(
            footer: sectionFooter(context, l.idInfo),
            children: [
              CupertinoListTile(
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
              CupertinoListTile(
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
  List<Msg> shared = const [];
  List<String> blockedIds = const [];
  int tab = 0;
  bool copied = false;
  String bio = '';
  String about = '';
  String role = 'member';
  bool hideMembers = false;
  Map<String, dynamic> cfg = const {};
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
          b.bioOf(other).then((t) {
            if (mounted) setState(() => bio = t);
          }, onError: (_) {});
        }
      });
      b.timeline(widget.roomId, limit: 300).then((m) {
        if (mounted) setState(() => shared = m.reversed.toList());
      }, onError: (_) {});
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
    if (mounted) {
      setState(() {
        cfg = c;
        about = r[0];
        role = r[1];
        hideMembers = hide;
        members = m;
      });
    }
  }

  bool get isAdmin => role == 'owner' || role == 'admin';

  /// Channels: only admins see subscribers. Groups: everyone, unless hidden.
  bool get showMembers => isAdmin || (!widget.isChannel && !hideMembers);

  Future<void> memberActions(Member m) async {
    final l = L.of(context);
    final b = AppScope.of(context).backend;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        title: Text(m.name),
        actions: [
          if (role == 'owner')
            CupertinoActionSheetAction(
              key: const Key('member-admin'),
              onPressed: () => Navigator.pop(c, 'admin'),
              child: Text(m.role == 'admin' ? l.removeAdmin : l.makeAdmin),
            ),
          CupertinoActionSheetAction(
            key: const Key('member-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(widget.isChannel ? l.removeSubscriber : l.removeMember),
          ),
          CupertinoActionSheetAction(
            key: const Key('member-ban'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'ban'),
            child: Text(l.banMember),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == 'admin') await b.setAdmin(widget.roomId, m.userId, m.role != 'admin');
    if (pick == 'remove') await b.removeMember(widget.roomId, m.userId);
    if (pick == 'ban') {
      await b.setBanned(widget.roomId, m.userId, true);
      if (mounted) await AppScope.read(context).logMod(widget.roomId, 'banned', m.name);
    }
    if (pick != null) await loadRoom();
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

  Future<void> toggleMute() async {
    final s = AppScope.of(context);
    await s.backend.setChatMuted(widget.roomId, !muted);
    await s.refresh();
  }

  /// "더 보기": disappearing messages, clear my side, block.
  Future<void> openMore(String? other) async {
    final l = L.of(context);
    final s = AppScope.of(context);
    final canTimer = !widget.isChannel || await s.backend.canPost(widget.roomId);
    if (!mounted) return;
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (canTimer) CupertinoActionSheetAction(key: const Key('more-timer'), onPressed: () => Navigator.pop(c, 'timer'), child: Text(l.timer)),
          CupertinoActionSheetAction(key: const Key('more-clear'), onPressed: () => Navigator.pop(c, 'clear'), child: Text(l.clearChat)),
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
      case 'timer':
        final now = await s.backend.timer(widget.roomId);
        if (!mounted) return;
        const options = [0, 86400, 604800, 2592000];
        final secs = await showCupertinoModalPopup<int>(
          useRootNavigator: !Wide.on,
          context: context,
          builder: (c) => IosActionSheet(
            title: Text(l.timer),
            message: Text(l.timerInfo),
            actions: [
              for (final o in options)
                CupertinoActionSheetAction(
                  key: Key('timer-$o'),
                  isDefaultAction: o == now,
                  onPressed: () => Navigator.pop(c, o),
                  child: Text(o == 0 ? l.timerOff : timerLabel(c, o)),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
          ),
        );
        if (secs != null && secs != now) await s.backend.setTimer(widget.roomId, secs);
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
    final theirStories = direct && other != null ? st.stories.where((x) => !x.mine && x.sender == other).toList() : const <Story>[];
    final rules = (cfg['rules'] as String? ?? '').trim();
    final hereId = st.pref('chat_theme:${widget.roomId}', '');
    final themeHere = hereId.isEmpty ? l.useDefault : ChatTheme.of(hereId).label(l);
    String roleName(String r) => switch (r) {
      'owner' => l.owner,
      'admin' => l.admin,
      _ => '',
    };
    return CupertinoPageScaffold(
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
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + Tokens.space[3]),
          children: [
            Center(
              child: GestureDetector(
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
                    userId: direct ? other : null,
                    owner: widget.isChannel ? AppScope.of(context).chats.where((c) => c.roomId == widget.roomId).firstOrNull?.peer : null,
                  ),
                ),
              ),
            ),
            SizedBox(height: Tokens.space[2]),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Text(
                title,
                key: const Key('info-name'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Tokens.screenTitle.style.copyWith(color: p.label, fontWeight: FontWeight.w500),
              ),
            ),
            SizedBox(height: Tokens.nameToSub),
            Center(
              child: Text(
                widget.isChannel
                    ? l.subscribersCount(members.length)
                    : (widget.isGroup ? l.membersCount(members.length) : displayId(members.where((m) => m.userId != me).firstOrNull?.userId ?? '')),
                style: Tokens.body.style.copyWith(color: p.secondaryLabel),
              ),
            ),
            if (about.isNotEmpty)
              Padding(
                key: const Key('info-about'),
                padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
                child: Text(
                  about,
                  textAlign: TextAlign.center,
                  style: Tokens.preview.style.copyWith(color: p.label),
                ),
              ),
            SizedBox(height: Tokens.space[5]),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
              child: Row(
                children: [
                  if (!widget.isGroup && !widget.isChannel) ...[
                    Expanded(
                      child: InfoAction(
                        key: const Key('info-voice-call'),
                        icon: CupertinoIcons.phone_fill,
                        label: l.callVoice,
                        onTap: () => startCall(context, widget.roomId, widget.title, video: false),
                      ),
                    ),
                    SizedBox(width: Tokens.space[1]),
                    Expanded(
                      child: InfoAction(
                        key: const Key('info-video-call'),
                        icon: CupertinoIcons.video_camera_solid,
                        label: l.callVideo,
                        onTap: () => startCall(context, widget.roomId, widget.title, video: true),
                      ),
                    ),
                    SizedBox(width: Tokens.space[1]),
                  ],
                  Expanded(
                    child: InfoAction(
                      key: const Key('info-mute'),
                      icon: muted ? CupertinoIcons.bell_fill : CupertinoIcons.bell_slash_fill,
                      label: muted ? l.chatUnmute : l.chatMute,
                      onTap: toggleMute,
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  Expanded(
                    child: InfoAction(
                      key: const Key('info-search'),
                      icon: CupertinoIcons.search,
                      label: l.searchInChat,
                      onTap: () => Navigator.pop(context, 'search'),
                    ),
                  ),
                  SizedBox(width: Tokens.space[1]),
                  Expanded(
                    child: InfoAction(key: const Key('info-more'), icon: CupertinoIcons.ellipsis, label: l.more, onTap: () => openMore(other)),
                  ),
                ],
              ),
            ),
            if ((widget.isGroup || widget.isChannel) && members.isNotEmpty && showMembers)
              IosSection(
                header: sectionHeader(context, widget.isChannel ? l.subscribers : l.members),
                footer: hideMembers && !widget.isChannel ? sectionFooter(context, l.hideMembersOnInfo) : null,
                children: [
                  if (isAdmin || (!widget.isChannel && !hideMembers))
                    CupertinoListTile(
                      key: const Key('info-add-member'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                      leading: Icon(CupertinoIcons.person_badge_plus, color: p.accent, size: Tokens.tabIcon),
                      title: Text(l.addMembers, style: TextStyle(color: p.accent)),
                      onTap: addMembers,
                    ),
                  for (final m in members)
                    // Telegram sizes: 40 photo, 60-tall row, role as a soft pill.
                    CupertinoListTile(
                      key: Key('member-${m.userId}'),
                      leadingSize: Tokens.memberAvatar,
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[1]),
                      leading: Avatar(name: m.name, size: Tokens.memberAvatar, userId: m.userId),
                      title: Text(m.userId == me ? '${m.name} (${l.you})' : m.name),
                      subtitle: Text(displayId(m.userId), style: Tokens.preview.style.copyWith(color: p.secondaryLabel)),
                      additionalInfo: roleName(m.role).isEmpty
                          ? null
                          : Container(
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[1] + 2, vertical: 3),
                              decoration: BoxDecoration(color: p.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Tokens.capsule)),
                              child: Text(roleName(m.role), style: Tokens.caption.style.copyWith(color: p.accent)),
                            ),
                      onTap: isAdmin && m.userId != me && m.role != 'owner' && (role == 'owner' || m.role != 'admin') ? () => memberActions(m) : null,
                    ),
                ],
              )
            else if (widget.isChannel && !isAdmin)
              IosSection(
                hasLeading: false,
                footer: sectionFooter(context, l.subscribersHiddenInfo),
                children: [CupertinoListTile(title: Text(l.subscribersCount(members.length)))],
              ),
            if (!widget.isGroup && !widget.isChannel && other != null)
              IosSection(
                hasLeading: false,
                children: [
                  CupertinoListTile(
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
                    CupertinoListTile(
                      key: const Key('info-bio'),
                      title: Text(l.bio, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(bio, maxLines: 4, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  if (memo.isNotEmpty)
                    CupertinoListTile(
                      key: const Key('info-memo'),
                      title: Text(l.memo, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                      subtitle: Text(memo, maxLines: 4, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  CupertinoListTile(
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
            if (!direct && (isAdmin || rules.isNotEmpty))
              IosSection(
                children: [
                  if (isAdmin)
                    CupertinoListTile(
                      key: const Key('info-tools'),
                      leading: iconTile(Palette.tileBlue, CupertinoIcons.shield_lefthalf_fill),
                      title: Text(l.manageTools),
                      trailing: const CupertinoListTileChevron(),
                      onTap: openTools,
                    ),
                  if (rules.isNotEmpty)
                    CupertinoListTile(
                      key: const Key('info-rules'),
                      leading: iconTile(Palette.tileOrange, CupertinoIcons.doc_text_fill),
                      title: Text(l.roomRules),
                      trailing: const CupertinoListTileChevron(),
                      onTap: () => Navigator.of(context).push(IosPageRoute(fullscreenDialog: true, builder: (_) => RulesSheet(rules: rules))),
                    ),
                ],
              ),
            IosSection(
              children: [
                // v1's top-right menu had "보안 코드 확인"; it lives here now.
                if (direct && other != null)
                  CupertinoListTile(
                    key: const Key('info-encryption'),
                    leading: iconTile(p.tileGreen, CupertinoIcons.lock_fill),
                    title: Text(l.encryption),
                    additionalInfo: Text(peerVerified ? l.encVerified : l.encNotVerified),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () async {
                      await Navigator.of(context).push(
                        IosPageRoute(
                          builder: (_) => EncryptionPage(userId: other, name: title),
                        ),
                      );
                      await loadVerified();
                    },
                  ),
                CupertinoListTile(
                  key: const Key('info-theme'),
                  leading: iconTile(Palette.tileCyan, CupertinoIcons.paintbrush_fill),
                  title: Text(l.chatThemeHere),
                  additionalInfo: Text(themeHere),
                  trailing: const CupertinoListTileChevron(),
                  onTap: () => Navigator.of(context).push(
                    IosPageRoute(
                      builder: (_) => ChoicePage(
                        title: l.chatThemeHere,
                        footer: l.chatThemeHereInfo,
                        options: [('', l.useDefault), for (final t in ChatTheme.all) (t.id, t.label(l))],
                        value: () => st.pref('chat_theme:${widget.roomId}', ''),
                        onPick: (v) => st.setPref('chat_theme:${widget.roomId}', v),
                      ),
                    ),
                  ),
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
                children: {0: Text(l.tabMedia), 1: Text(l.tabFiles), 2: Text(l.tabLinks), if (direct) 3: Text(l.tabGroups)},
                onValueChanged: (v) => setState(() => tab = v ?? 0),
              ),
            ),
            if (tab == 3) CommonGroups(chats: common) else SharedList(roomId: widget.roomId, msgs: shared, tab: tab),
            if (!widget.isGroup && !widget.isChannel)
              IosSection(
                footer: sectionFooter(context, l.deleteForBothInfo),
                children: [
                  if (deleting == null)
                    CupertinoListTile(
                      key: const Key('delete-both'),
                      leading: iconTile(Palette.tileRed, CupertinoIcons.trash),
                      title: Text(l.deleteForBoth, style: const TextStyle(color: Palette.tileRed)),
                      onTap: leaving == null ? startDeleteForBoth : null,
                    )
                  else
                    CupertinoListTile(
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
                    CupertinoListTile(
                      key: const Key('delete-room'),
                      leading: iconTile(Palette.tileRed, CupertinoIcons.trash),
                      title: Text(widget.isChannel ? l.deleteChannel : l.deleteGroup, style: const TextStyle(color: Palette.tileRed)),
                      onTap: leaving == null ? askDeleteRoom : null,
                    )
                  else
                    CupertinoListTile(
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
                  CupertinoListTile(
                    key: const Key('leave'),
                    leading: iconTile(Palette.tileRed, CupertinoIcons.square_arrow_right),
                    title: Text(widget.isChannel ? l.leaveChannel : l.leaveChat, style: const TextStyle(color: Palette.tileRed)),
                    onTap: deleting == null && removing == null ? startLeave : null,
                  )
                else
                  CupertinoListTile(
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
    return IosSection(
      children: [
        for (final m in list)
          CupertinoListTile(
            key: Key('shared-${m.id}'),
            leading: iconTile(tab == 1 ? Palette.tileBlue : Palette.tileOrange, tab == 1 ? CupertinoIcons.doc_fill : CupertinoIcons.link),
            title: Text(tab == 1 ? (m.body ?? '') : _link.firstMatch(m.body ?? '')!.group(0)!, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(m.time), style: Tokens.caption.style),
            onTap: tab == 2 ? () => launchUrl(Uri.parse(_link.firstMatch(m.body ?? '')!.group(0)!)) : null,
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
    if (widget.msg.kind == 'image') bytes ??= AppScope.of(context).backend.downloadFile(widget.roomId, widget.msg.id);
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
              footer: sectionFooter(context, l.contactPhotoInfo(widget.name)),
              children: [
                CupertinoListTile(
                  key: const Key('contact-photo'),
                  leading: Icon(CupertinoIcons.camera, color: p.accent, size: Tokens.listIcon),
                  title: Text(l.contactPhotoSet(widget.name), style: TextStyle(color: p.accent)),
                  onTap: pickPhoto,
                ),
                if (hasPhoto)
                  CupertinoListTile(
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
  bool ready = false;
  bool busy = false;

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
      if (mounted) {
        setState(() {
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

  Future<void> save() async {
    if (busy || name.text.trim().isEmpty) return;
    setState(() => busy = true);
    final b = AppScope.of(context).backend;
    try {
      if (name.text.trim() != widget.name) await b.setRoomName(widget.roomId, name.text.trim());
      if (about.text.trim() != await b.roomAbout(widget.roomId)) await b.setRoomAbout(widget.roomId, about.text.trim());
      final key = widget.isChannel ? 'sign' : 'hide_members';
      final want = widget.isChannel ? sign : hide;
      if (want != await b.roomSwitch(widget.roomId, key)) await b.setRoomSwitch(widget.roomId, key, want);
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
            Center(child: Avatar(name: name.text.trim().isEmpty ? widget.name : name.text.trim(), size: 90, squircle: true)),
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
                  onChanged: (_) => setState(() {}),
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
              footer: sectionFooter(context, widget.isChannel ? l.signPostsInfo : l.hideMembersInfo),
              children: [
                CupertinoListTile(
                  title: Text(widget.isChannel ? l.signPosts : l.hideMembers),
                  trailing: IosSwitch(
                    key: const Key('room-switch'),
                    value: widget.isChannel ? sign : hide,
                    activeTrackColor: p.accent,
                    onChanged: (v) => setState(() => widget.isChannel ? sign = v : hide = v),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (people != null) return;
    people = const [];
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
      await AppScope.of(context).backend.inviteUsers(widget.roomId, chosen.toList());
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
                  IosSection(
                    children: [
                      for (final c in list)
                        CupertinoListTile(
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
                    child: ClipOval(child: _StoryThumb(story: stories[i])),
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

class _StoryThumb extends StatefulWidget {
  const _StoryThumb({required this.story});
  final Story story;

  @override
  State<_StoryThumb> createState() => _StoryThumbState();
}

class _StoryThumbState extends State<_StoryThumb> {
  Future<List<int>>? bytes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.story.kind == 'image') bytes ??= AppScope.of(context).backend.downloadFile(widget.story.roomId, widget.story.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final p = paletteOf(context);
    final fallback = ColoredBox(
      color: p.incoming,
      child: Icon(widget.story.kind == 'video' ? CupertinoIcons.play_fill : CupertinoIcons.photo, color: p.secondaryLabel, size: Tokens.listIcon),
    );
    final b = bytes;
    if (b == null) return fallback;
    return FutureBuilder<List<int>>(
      future: b,
      builder: (_, s) => s.hasData && s.data!.isNotEmpty ? Image.memory(Uint8List.fromList(s.data!), fit: BoxFit.cover, gaplessPlayback: true) : fallback,
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
          CupertinoListTile(
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
