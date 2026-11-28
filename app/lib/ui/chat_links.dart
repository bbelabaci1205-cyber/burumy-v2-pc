// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 대화 링크 (Telegram tip 438, without the click count: counting would need
// a server watching every tap). Settings > 대화 링크: links that open a 1:1
// chat with me with my words already in the other person's composer
// ("케이크 주문하고 싶어요"). Made and kept on this phone; the link carries
// everything after '#', so no web server sees it.
//
// - ChatLinksPage: the list (+ 대화 링크 만들기).
// - ChatLinkEditPage: preview over my chat background, the words, a name
//   only I see, my 아이디 키 (if I have one) in the link or not, copy /
//   share, delete (5초 되돌리기).
// - openChatLink: what happens on the other phone.
import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart' hide LinkCard;
import '../core/id_key.dart';
import '../core/room_links.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'chat_page.dart' show openChat;
import 'common.dart';
import 'glass.dart';
import 'invite_links.dart' show LinkCard;
import 'ios.dart';
import 'ios_route.dart';
import 'login_safety_ui.dart' show showUndoCountdown;
import 'new_chat_page.dart' show openCreated;
import 'room_rules_pages.dart' show explainDmBlocked;
import 'settings_kit.dart';
import 'wallpaper.dart';
import 'wide.dart' show openSheet;

/// The on-device setting with my links.
const chatLinksPref = 'chat_links';

List<MyChatLink> myChatLinks(AppState s) => MyChatLink.listFrom(s.pref(chatLinksPref, '[]'));

Future<void> saveChatLinks(AppState s, List<MyChatLink> l) => s.setPref(chatLinksPref, MyChatLink.listTo(l));

/// The link as the other person gets it.
String chatLinkUrl(AppState s, MyChatLink k) => k.link(s.backend.userId ?? '', key: s.pref(IdKey.pref, '')).url;

class ChatLinksPage extends StatefulWidget {
  const ChatLinksPage({super.key});
  @override
  State<ChatLinksPage> createState() => _ChatLinksPageState();
}

class _ChatLinksPageState extends State<ChatLinksPage> {
  /// Hidden while its 5초 되돌리기 runs.
  final going = <String>{};

  Future<void> open(MyChatLink? k) async {
    final gone = await Navigator.of(context).push<String>(IosPageRoute(builder: (_) => ChatLinkEditPage(link: k)));
    if (gone == null || !mounted) return;
    // Delete asked on the edit page: hide now, delete after 5 seconds.
    final s = AppScope.read(context);
    final l = L.of(context);
    setState(() => going.add(gone));
    showUndoCountdown(context, (n) => l.chatLinkDeleteIn(n), () async {
      await saveChatLinks(s, [...myChatLinks(s).where((x) => x.id != gone)]);
      if (mounted) setState(() => going.remove(gone));
    }, onUndo: () => mounted ? setState(() => going.remove(gone)) : null);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final links = myChatLinks(s).where((k) => !going.contains(k.id)).toList();
    return SettingsScaffold(
      title: l.chatLinks,
      children: [
        HeaderCard(color: Palette.tileIndigo, icon: CupertinoIcons.link, title: l.chatLinks, body: l.chatLinksAbout),
        group(context, footer: l.chatLinksFooter, [
          IosTile(
            key: const Key('chat-link-new'),
            leading: Icon(CupertinoIcons.add, color: p.accent),
            title: Text(l.chatLinkNew, style: TextStyle(color: p.accent)),
            onTap: () => open(null),
          ),
          for (final k in links)
            IosTile(
              key: Key('chat-link-${k.id}'),
              leading: iconTile(Palette.tileIndigo, CupertinoIcons.chat_bubble_text_fill),
              title: Text(k.name.isNotEmpty ? k.name : (k.text.isNotEmpty ? k.text : l.chatLinkNoText), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                k.name.isNotEmpty && k.text.isNotEmpty ? k.text : RoomLinks.shown(chatLinkUrl(s, k)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const IosChevron(),
              onTap: () => open(k),
            ),
        ]),
      ],
    );
  }
}

/// Make or change one link. Pops with the link's id when it should be
/// deleted (the list runs the 5초 되돌리기).
class ChatLinkEditPage extends StatefulWidget {
  const ChatLinkEditPage({super.key, this.link});
  final MyChatLink? link;

  @override
  State<ChatLinkEditPage> createState() => _ChatLinkEditPageState();
}

class _ChatLinkEditPageState extends State<ChatLinkEditPage> {
  late final text = TextEditingController(text: widget.link?.text ?? '');
  late final name = TextEditingController(text: widget.link?.name ?? '');
  late bool withKey = widget.link?.withKey ?? false;
  late MyChatLink? saved = widget.link;

  @override
  void dispose() {
    text.dispose();
    name.dispose();
    super.dispose();
  }

  bool get changed => saved == null || saved!.text != text.text.trim() || saved!.name != name.text.trim() || saved!.withKey != withKey;

  Future<void> save() async {
    final s = AppScope.read(context);
    final now = myChatLinks(s);
    final k = MyChatLink(
      id: saved?.id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      name: name.text.trim(),
      text: text.text.trim(),
      withKey: withKey,
    );
    final i = now.indexWhere((x) => x.id == k.id);
    await saveChatLinks(s, i < 0 ? [...now, k] : ([...now]..[i] = k));
    if (mounted) setState(() => saved = k);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final s = AppScope.of(context);
    final p = paletteOf(context);
    final hasKey = s.pref(IdKey.pref, '').isNotEmpty;
    final ready = saved != null && !changed;
    return SettingsScaffold(
      title: widget.link == null ? l.chatLinkNew : l.chatLinkEdit,
      trailing: [if (changed) GlassPill(key: const Key('chat-link-save'), text: widget.link == null && saved == null ? l.invMake : l.done, onTap: save)],
      children: [
        // What the other person sees: my chat background, my words waiting
        // in their composer.
        Padding(
          padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radius[3]),
            child: SizedBox(
              height: Tokens.chatLinkPreview,
              child: ChatWallpaper(
                child: Column(
                  children: [
                    SizedBox(height: Tokens.space[3]),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: Tokens.space[2] + 2, vertical: Tokens.space[0]),
                      decoration: BoxDecoration(color: p.card.withValues(alpha: .85), borderRadius: BorderRadius.circular(Tokens.capsule)),
                      child: Text(l.chatLinkPreview, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    ),
                    const Spacer(),
                    Padding(
                      padding: EdgeInsets.all(Tokens.space[2]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              key: const Key('chat-link-preview'),
                              constraints: const BoxConstraints(minHeight: 40),
                              padding: EdgeInsets.symmetric(horizontal: Tokens.space[3], vertical: Tokens.space[2]),
                              decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                text.text.trim().isEmpty ? l.messageHint : text.text.trim(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.body.style.copyWith(color: text.text.trim().isEmpty ? p.secondaryLabel : p.label),
                              ),
                            ),
                          ),
                          SizedBox(width: Tokens.space[2]),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                            child: Icon(CupertinoIcons.arrow_up, color: p.onAccent, size: Tokens.listIcon),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        group(context, header: l.chatLinkText, footer: l.chatLinkTextInfo, [
          CupertinoTextField.borderless(
            key: const Key('chat-link-text'),
            controller: text,
            placeholder: l.chatLinkTextHint,
            minLines: 2,
            maxLines: 6,
            maxLength: ChatLink.maxText,
            autofocus: widget.link == null,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + 2),
            onChanged: (_) => setState(() {}),
          ),
        ]),
        group(context, footer: l.chatLinkNameInfo, [
          CupertinoTextField.borderless(
            key: const Key('chat-link-name'),
            controller: name,
            placeholder: l.chatLinkNameHint,
            maxLength: 32,
            style: Tokens.body.style.copyWith(color: p.label),
            padding: EdgeInsets.all(Tokens.space[2] + 2),
            onChanged: (_) => setState(() {}),
          ),
        ]),
        if (hasKey)
          group(context, footer: l.chatLinkKeyInfo, [
            IosTile(
              leading: iconTile(Palette.tileOrange, CupertinoIcons.lock_fill),
              title: Text(l.chatLinkKey),
              trailing: IosSwitch(key: const Key('chat-link-key'), value: withKey, activeTrackColor: p.accent, onChanged: (v) => setState(() => withKey = v)),
            ),
          ]),
        if (ready) group(context, footer: l.chatLinkIdInfo, [LinkCard(key: const Key('chat-link-card'), link: chatLinkUrl(s, saved!))]),
        if (widget.link != null)
          group(context, [
            IosTile(
              key: const Key('chat-link-delete'),
              title: Text(l.chatLinkDelete, style: const TextStyle(color: Palette.tileRed)),
              onTap: () => Navigator.of(context).pop(widget.link!.id),
            ),
          ]),
      ],
    );
  }
}

/// On the phone that opened a 대화 링크: the chat with that person, with
/// the words in the composer (never sent by themselves). A first chat asks
/// once ("메시지 보내기"); my own link opens 저장한 메시지.
Future<void> openChatLink(BuildContext context, ChatLink link) async {
  final s = AppScope.read(context);
  void putDraft(String roomId) {
    // A draft the person was already writing there is kept.
    if (link.text.isNotEmpty && s.pref('draft:$roomId', '').isEmpty) unawaited(s.setPref('draft:$roomId', link.text));
  }

  if (link.userId == s.backend.userId) {
    final id = await s.openSaved();
    putDraft(id);
    if (context.mounted) await openChat(context, id, L.of(context).savedMessages);
    return;
  }
  final known = s.chats.where((c) => c.isDirect && c.peer == link.userId).firstOrNull;
  if (known != null) {
    putDraft(known.roomId);
    await openChat(context, known.roomId, known.name);
    return;
  }
  await openSheet<void>(context, (_) => ChatLinkStartPage(link: link, onStart: putDraft));
}

/// "이 사람과 대화를 시작할까요?": name, ID, the words waiting, one button.
class ChatLinkStartPage extends StatefulWidget {
  const ChatLinkStartPage({super.key, required this.link, required this.onStart});
  final ChatLink link;
  final void Function(String roomId) onStart;

  @override
  State<ChatLinkStartPage> createState() => _ChatLinkStartPageState();
}

class _ChatLinkStartPageState extends State<ChatLinkStartPage> {
  String? name;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final b = AppScope.read(context).backend;
      final found = await b.searchPeople(widget.link.userId).catchError((_) => <Person>[]);
      if (mounted) setState(() => name = found.where((x) => x.userId == widget.link.userId).firstOrNull?.name ?? '');
    });
  }

  Future<void> start() async {
    final s = AppScope.read(context);
    final title = (name ?? '').isNotEmpty ? name! : displayId(widget.link.userId);
    setState(() => busy = true);
    try {
      final room = await s.makeChat(() => s.backend.createDirectChat(widget.link.userId, idKey: widget.link.key));
      widget.onStart(room);
      await s.refresh();
      if (mounted) openCreated(context, room, title);
    } catch (e) {
      if (mounted) setState(() => busy = false);
      if (mounted) await explainDmBlocked(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final shown = (name ?? '').isNotEmpty ? name! : displayId(widget.link.userId);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: GlassTopBar.nav(leading: const GlassBack(close: true), backgroundColor: p.background, border: null),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: Tokens.space[4]),
                children: [
                  SizedBox(height: Tokens.space[4]),
                  Center(
                    child: Avatar(name: shown, userId: widget.link.userId, size: Tokens.infoAvatar),
                  ),
                  SizedBox(height: Tokens.space[3]),
                  Text(
                    shown,
                    key: const Key('chat-link-who'),
                    textAlign: TextAlign.center,
                    style: Tokens.cardTitle.style.copyWith(color: p.label),
                  ),
                  SizedBox(height: Tokens.nameToSub),
                  Text(
                    displayId(widget.link.userId),
                    textAlign: TextAlign.center,
                    style: Tokens.preview.style.copyWith(color: p.secondaryLabel),
                  ),
                  if (widget.link.text.isNotEmpty) ...[
                    SizedBox(height: Tokens.space[4]),
                    Text(l.chatLinkWaiting, style: Tokens.caption.style.copyWith(color: p.secondaryLabel)),
                    SizedBox(height: Tokens.space[1]),
                    Container(
                      key: const Key('chat-link-words'),
                      padding: EdgeInsets.all(Tokens.space[3]),
                      decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(Tokens.radius[2])),
                      child: Text(widget.link.text, style: Tokens.body.style.copyWith(color: p.label)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[1], Tokens.space[3], Tokens.space[2]),
              child: CupertinoButton.filled(
                key: const Key('chat-link-start'),
                borderRadius: BorderRadius.circular(Tokens.capsule),
                onPressed: busy || name == null ? null : start,
                child: SizedBox(
                  width: double.infinity,
                  child: busy
                      ? CupertinoActivityIndicator(color: p.onAccent)
                      : Text(
                          l.chatLinkStart,
                          textAlign: TextAlign.center,
                          style: Tokens.body.style.copyWith(color: p.onAccent, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The 대화 링크 row for Settings (only while the feature is on).
Widget chatLinksRow(BuildContext context) => NavRow(
  key: const Key('chat-links-row'),
  color: Palette.tileIndigo,
  icon: CupertinoIcons.link,
  title: L.of(context).chatLinks,
  page: (_) => const ChatLinksPage(),
);
