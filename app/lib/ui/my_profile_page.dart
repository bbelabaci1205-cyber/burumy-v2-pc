// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 프로필 묶음 (Telegram tips 445 · 58 · 374):
// - 내 프로필: my profile as other people see it, switchable between
//   "모든 사람" and "내 연락처" (what my 공개 범위 settings let each see).
// - 예전 사진: my earlier photos (kept only on this phone) to go back to.
// - 공개 사진: the photo people see when my real one is hidden from them.
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/app_state.dart';
import '../core/my_photos.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'emoji_photo.dart';
import 'glass.dart';
import 'ios.dart';
import 'ios_route.dart';
import 'message_sheets.dart' show AccentButton;
import 'photo_editor.dart';
import 'profile_header.dart';
import 'profile_page.dart';
import 'settings_pages.dart' show PrivacyPage;
import 'stories.dart';
import 'wide.dart';

/// Gallery → our round editor (1024 px). Null when nothing was picked.
Future<Uint8List?> pickProfilePhoto(BuildContext context) async {
  final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024);
  if (x == null || !context.mounted) return null;
  final picked = await x.readAsBytes();
  if (!context.mounted) return null;
  return editProfilePhoto(context, picked);
}

/// Settings > my card: my profile the way others see it (tip 445).
class MyProfileViewPage extends StatefulWidget {
  const MyProfileViewPage({super.key});
  @override
  State<MyProfileViewPage> createState() => _MyProfileViewPageState();
}

class _MyProfileViewPageState extends State<MyProfileViewPage> {
  String name = '';

  /// Whose eyes: anyone with my ID, or someone I talk to 1:1.
  bool contact = true;
  bool copied = false;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    final n = await AppScope.read(context).backend.myName();
    if (mounted) setState(() => name = n);
  }

  bool sees(AppState s, String key, String fallback) {
    final w = s.pref(key, fallback);
    return w == 'everyone' || (w == 'contacts' && contact);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final id = displayId(s.backend.userId ?? '');
    final (photo, isPublic) = MyPhotos.seenBy(s, contact: contact);
    final bio = sees(s, 'who_bio', 'everyone') ? s.pref('me_bio', '') : '';
    final bday = sees(s, 'who_birthday', 'contacts') ? s.pref('me_birthday', '') : '';
    final mine = s.stories.where((x) => x.mine).toList();
    final hidden = [
      if ((photo == null || isPublic) && s.myOwnPhoto != null) l.whoPhoto,
      if (bio.isEmpty && s.pref('me_bio', '').isNotEmpty) l.bio,
      if (bday.isEmpty && s.pref('me_birthday', '').isNotEmpty) l.birthday,
    ];
    final olds = MyPhotos.ids(s);
    final real = s.myOwnPhoto;
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar(
        title: name,
        titleOnScroll: true,
        tint: p.background,
        leading: const [GlassBack()],
        trailing: [
          GlassPill(
            key: const Key('my-profile-edit'),
            text: l.myProfileEdit,
            onTap: () async {
              await Navigator.of(context).push(IosPageRoute(builder: (_) => const ProfilePage()));
              await load();
            },
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5]),
        children: [
          ProfileTop(
            key: ValueKey('my-top-$contact-${photo?.length}'),
            photos: [if (photo != null) HeaderPhoto(photo, label: isPublic ? l.publicPhoto : '')],
            avatar: StoryRing(
              size: mine.isEmpty ? Tokens.infoAvatar : Tokens.infoAvatar + 10,
              show: mine.isNotEmpty,
              fresh: false,
              child: Stack(
                children: [
                  PhotoAvatar(key: const Key('my-profile-photo'), name: name, bytes: photo, size: Tokens.infoAvatar),
                  if (isPublic)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(child: PhotoLabel(text: l.publicPhoto)),
                    ),
                ],
              ),
            ),
            avatarSize: mine.isEmpty ? Tokens.infoAvatar : Tokens.infoAvatar + 10,
            onAvatarTap: mine.isEmpty ? null : () => openStories(context, [mine], 0).then((_) => setState(() {})),
            name: (onPhoto) => Text(
              name,
              key: Key(onPhoto ? 'my-profile-name-photo' : 'my-profile-name'),
              textAlign: onPhoto ? TextAlign.start : TextAlign.center,
              maxLines: onPhoto ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style: Tokens.screenTitle.style.copyWith(color: onPhoto ? const Color(0xFFFFFFFF) : p.label, fontWeight: FontWeight.w500),
            ),
            sub: (onPhoto) => Text(id, style: Tokens.body.style.copyWith(color: onPhoto ? const Color(0xD9FFFFFF) : p.secondaryLabel)),
            actions: null,
          ),
          SizedBox(height: Tokens.space[4]),
          // 보는 사람: 모든 사람 / 내 연락처.
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
            child: IosSegmented<bool>(
              key: const Key('my-profile-who'),
              groupValue: contact,
              children: {false: Text(l.seenEveryone), true: Text(l.seenContacts)},
              onValueChanged: (v) => setState(() => contact = v ?? contact),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Tokens.space[4], Tokens.space[1], Tokens.space[4], 0),
            child: Text(
              contact ? l.myProfileContactsInfo : l.myProfileEveryoneInfo,
              key: const Key('my-profile-who-info'),
              style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
            ),
          ),
          IosSection(
            hasLeading: false,
            footer: hidden.isEmpty ? null : sectionFooter(context, l.myProfileHidden(hidden.join(', '))),
            children: [
              if (bio.isNotEmpty)
                IosTile(
                  key: const Key('my-profile-bio'),
                  title: Text(l.bio, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  subtitle: Text(bio, style: Tokens.body.style.copyWith(color: p.label)),
                ),
              if (bday.isNotEmpty)
                IosTile(
                  key: const Key('my-profile-birthday'),
                  title: Text(l.birthday, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                  subtitle: Text(birthdayText(l, bday) ?? '', style: Tokens.body.style.copyWith(color: p.label)),
                ),
              IosTile(
                key: const Key('my-profile-id'),
                title: Text(l.myId, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                subtitle: Text(copied ? l.copied : id, style: Tokens.body.style.copyWith(color: p.accent)),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: id));
                  if (mounted) setState(() => copied = true);
                },
              ),
            ],
          ),
          if (mine.isNotEmpty)
            StoryShelf(
              stories: mine,
              title: l.storiesCount(mine.length),
              onOpen: (i) => openStories(context, [mine], 0, at: i).then((_) => setState(() {})),
            ),
          IosSection(
            children: [
              IosTile(
                key: const Key('my-profile-photos'),
                leading: iconTile(Palette.tileIndigo, CupertinoIcons.photo_on_rectangle),
                title: Text(l.oldPhotos),
                additionalInfo: Text('${olds.length + (real == null ? 0 : 1)}'),
                trailing: const IosChevron(),
                onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const MyPhotosPage())).then((_) => setState(() {})),
              ),
              if (s.pref('who_photo', 'everyone') != 'everyone') const PublicPhotoTile(),
              IosTile(
                key: const Key('my-profile-privacy'),
                leading: iconTile(Palette.tileBlue, CupertinoIcons.lock_fill),
                title: Text(l.myProfileWho),
                trailing: const IosChevron(),
                onTap: () => Navigator.of(context).push(IosPageRoute(builder: (_) => const PrivacyPage())).then((_) => setState(() {})),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 공개 사진 row (tip 374): set / change / remove, with what it is for.
class PublicPhotoTile extends StatelessWidget {
  const PublicPhotoTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final pub = MyPhotos.publicPhoto(s);
    return IosTile(
      key: const Key('public-photo'),
      leading: pub == null ? iconTile(Palette.tileTeal, CupertinoIcons.person_crop_circle) : PhotoAvatar(name: '', bytes: pub, size: 28),
      title: Text(pub == null ? l.publicPhotoSet : l.publicPhoto),
      trailing: const IosChevron(),
      onTap: () => publicPhotoMenu(context),
    );
  }
}

/// Picks, changes or removes the 공개 사진.
Future<void> publicPhotoMenu(BuildContext context) async {
  final l = L.of(context);
  final s = AppScope.read(context);
  final has = MyPhotos.publicPhoto(s) != null;
  final pick = await showCupertinoModalPopup<String>(
    useRootNavigator: !Wide.on,
    context: context,
    builder: (c) => IosActionSheet(
      message: Text(l.publicPhotoInfo),
      actions: [
        CupertinoActionSheetAction(
          key: const Key('public-photo-pick'),
          onPressed: () => Navigator.pop(c, 'pick'),
          child: Text(has ? l.publicPhotoChange : l.publicPhotoSet),
        ),
        CupertinoActionSheetAction(key: const Key('public-photo-emoji'), onPressed: () => Navigator.pop(c, 'emoji'), child: Text(l.emojiPhoto)),
        if (has)
          CupertinoActionSheetAction(
            key: const Key('public-photo-remove'),
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(c, 'remove'),
            child: Text(l.publicPhotoRemove),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
    ),
  );
  if (pick == null || !context.mounted) return;
  if (pick == 'remove') {
    await MyPhotos.setPublic(s, null);
    if (context.mounted) showStoryToast(context, l.publicPhotoRemoved);
    return;
  }
  final bytes = pick == 'emoji' ? await makeEmojiPhoto(context) : await pickProfilePhoto(context);
  if (bytes == null || !context.mounted) return;
  await MyPhotos.setPublic(s, bytes);
  if (context.mounted) showStoryToast(context, l.publicPhotoDone);
}

/// 예전 사진 (tip 58): my photo and the earlier ones, to look through, go
/// back to (대표 사진으로) or take off.
class MyPhotosPage extends StatefulWidget {
  const MyPhotosPage({super.key});
  @override
  State<MyPhotosPage> createState() => _MyPhotosPageState();
}

class _MyPhotosPageState extends State<MyPhotosPage> {
  final pages = PageController();
  int at = 0;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  /// (id, bytes): id '' = my 대표 사진.
  List<(String, Uint8List)> all(AppState s) => [
    if (s.myOwnPhoto case final m?) ('', m),
    for (final id in MyPhotos.ids(s))
      if (MyPhotos.bytes(s, id) case final b?) (id, b),
  ];

  void jump(int i) {
    setState(() => at = i);
    pages.jumpToPage(i);
  }

  Future<void> menu(List<(String, Uint8List)> list) async {
    final l = L.of(context);
    final s = AppScope.read(context);
    final cur = list.isEmpty ? null : list[at.clamp(0, list.length - 1)];
    final pick = await showCupertinoModalPopup<String>(
      useRootNavigator: !Wide.on,
      context: context,
      builder: (c) => IosActionSheet(
        actions: [
          if (cur != null && cur.$1.isNotEmpty)
            CupertinoActionSheetAction(key: const Key('photos-main'), onPressed: () => Navigator.pop(c, 'main'), child: Text(l.photoMakeMain)),
          CupertinoActionSheetAction(key: const Key('photos-new'), onPressed: () => Navigator.pop(c, 'new'), child: Text(l.newPhoto)),
          CupertinoActionSheetAction(key: const Key('photos-emoji'), onPressed: () => Navigator.pop(c, 'emoji'), child: Text(l.emojiPhoto)),
          if (cur != null)
            CupertinoActionSheetAction(
              key: const Key('photos-delete'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(c, 'delete'),
              child: Text(l.removePhoto),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(onPressed: () => Navigator.pop(c), child: Text(l.cancel)),
      ),
    );
    if (pick == null || !mounted) return;
    switch (pick) {
      case 'main':
        await MyPhotos.makeMain(s, cur!.$1);
        if (!mounted) return;
        jump(0);
        showStoryToast(context, l.photoMainDone);
      case 'new' || 'emoji':
        final b = pick == 'emoji' ? await makeEmojiPhoto(context) : await pickProfilePhoto(context);
        if (b == null || !mounted) return;
        await s.saveMyProfile(photo: b);
        if (!mounted) return;
        jump(0);
        showStoryToast(context, l.photoMainDone);
      case 'delete':
        if (cur!.$1.isEmpty) {
          await MyPhotos.dropMain(s);
        } else {
          await MyPhotos.forget(s, cur.$1);
        }
        if (!mounted) return;
        final n = all(s).length;
        if (at >= n && n > 0) jump(n - 1);
        setState(() {});
        showStoryToast(context, l.photoDeleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final list = all(s);
    final i = list.isEmpty ? 0 : at.clamp(0, list.length - 1);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final since = list.isEmpty || list[i].$1.isEmpty ? null : MyPhotos.since(list[i].$1);
    const white = Color(0xFFFFFFFF);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: list.isEmpty
                ? Center(
                    child: Text(l.myProfileNoPhoto, style: Tokens.body.style.copyWith(color: const Color(0x99FFFFFF))),
                  )
                : PageView(
                    key: const Key('photos-pages'),
                    controller: pages,
                    onPageChanged: (x) => setState(() => at = x),
                    children: [
                      for (final (_, b) in list)
                        InteractiveViewer(
                          maxScale: 4,
                          child: Center(child: Image.memory(b, fit: BoxFit.contain, gaplessPlayback: true)),
                        ),
                    ],
                  ),
          ),
          Positioned(
            left: Tokens.space[3],
            right: Tokens.space[3],
            top: MediaQuery.paddingOf(context).top + Tokens.space[1],
            child: Row(
              children: [
                const DarkCircle(key: Key('back'), icon: CupertinoIcons.xmark),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        list.isEmpty ? l.oldPhotos : '${i + 1}/${list.length}',
                        key: const Key('photos-count'),
                        style: Tokens.body.style.copyWith(color: white, fontWeight: Tokens.semi),
                      ),
                      if (list.isNotEmpty)
                        Text(
                          since == null ? l.photoMain : l.photoUsedUntil(DateFormat.yMMMd(locale).format(since)),
                          key: const Key('photos-when'),
                          style: Tokens.caption.style.copyWith(color: const Color(0xB3FFFFFF)),
                        ),
                    ],
                  ),
                ),
                DarkCircle(key: const Key('photos-menu'), icon: CupertinoIcons.ellipsis, onTap: () => menu(list)),
              ],
            ),
          ),
          if (list.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[5] + Tokens.space[3],
              height: Tokens.oldPhotoThumb,
              child: Center(
                child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space[3]),
                  children: [
                    for (var k = 0; k < list.length; k++)
                      GestureDetector(
                        key: Key('photos-thumb-$k'),
                        onTap: () => jump(k),
                        child: AnimatedContainer(
                          duration: Tokens.liveFade,
                          width: Tokens.oldPhotoThumb,
                          margin: EdgeInsets.symmetric(horizontal: Tokens.space[0] / 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Tokens.radius[0]),
                            border: Border.all(color: k == i ? white : const Color(0x00FFFFFF), width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(Tokens.radius[0] - 1),
                            child: Opacity(
                              opacity: k == i ? 1 : 0.6,
                              child: Image.memory(list[k].$2, fit: BoxFit.cover, gaplessPlayback: true),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Positioned(
            left: Tokens.space[4],
            right: Tokens.space[4],
            bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[2],
            child: Text(
              l.oldPhotosInfo,
              textAlign: TextAlign.center,
              style: Tokens.caption.style.copyWith(color: const Color(0x99FFFFFF)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen photo with one big button under it (사진 제안 → 내 사진으로).
class PhotoUsePage extends StatelessWidget {
  const PhotoUsePage({super.key, required this.bytes, required this.title, required this.button, required this.onUse});
  final Uint8List bytes;
  final String title;
  final String button;
  final Future<void> Function() onUse;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
          ),
          Positioned(
            left: Tokens.space[3],
            right: Tokens.space[3],
            top: MediaQuery.paddingOf(context).top + Tokens.space[1],
            child: Row(
              children: [
                const DarkCircle(key: Key('back'), icon: CupertinoIcons.xmark),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Tokens.body.style.copyWith(color: white, fontWeight: Tokens.semi),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
          ),
          Positioned(
            left: Tokens.space[4],
            right: Tokens.space[4],
            bottom: MediaQuery.paddingOf(context).bottom + Tokens.space[4],
            child: AccentButton(key: const Key('photo-use'), text: button, onTap: onUse),
          ),
        ],
      ),
    );
  }
}
