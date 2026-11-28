// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 보내는 이름 (channel batch #15).
// 472 슈퍼 채널: in a channel that shows authors, an admin picks "내 이름으로"
// (default, my photo and name on the post) or "채널 이름으로" (no name).
// 310 내 채널 이름으로 쓰기: in a group or a channel's comments I can write
// as one of my PUBLIC channels instead of my own name. Other phones show
// the channel's name and photo only after checking I really run it (my
// copy of the channel, else our server's rule 11); otherwise they show
// the real sender.
// The choice is kept on this phone per chat (pref send_as:<room>) and the
// claim travels inside the encrypted message.
import 'package:flutter/cupertino.dart';

import '../core/app_state.dart';
import '../core/backend.dart';
import '../design/tokens.dart';
import '../l10n/app_localizations.dart';
import 'common.dart';
import 'glass.dart';
import 'ios.dart';
import 'wide.dart';

/// One row of the picker: null [as] = myself.
class SendAsChoice {
  const SendAsChoice(this.as, this.name, {this.roomId});
  final PostAs? as;
  final String name;

  /// The channel (for its photo).
  final String? roomId;

  String get key => as?.toJson() ?? '';
}

class SendAs {
  const SendAs._();

  static String prefKey(String roomId) => 'send_as:$roomId';

  static PostAs? saved(AppState s, String roomId) => PostAs.fromJson(s.pref(prefKey(roomId), ''));

  /// Tells the engine (each time the chat opens) and remembers it.
  static Future<void> choose(AppState s, String roomId, PostAs? as) async {
    s.backend.setSendAs(roomId, as);
    await s.setPref(prefKey(roomId), as?.toJson() ?? '');
  }

  /// 310: my public channels (I'm owner or admin, it has a public address).
  static Future<List<SendAsChoice>> myChannels(AppState s, {String? except}) async {
    final out = <SendAsChoice>[];
    for (final c in s.chats) {
      if (!c.isChannel || c.roomId == except) continue;
      final role = await s.backend.myRole(c.roomId).catchError((_) => 'member');
      if (role != 'owner' && role != 'admin') continue;
      final link = await s.backend.roomLink(c.roomId).catchError((_) => const RoomLink());
      if (link.kind != 'public' || link.code.isEmpty) continue;
      out.add(SendAsChoice(PostAs.of(c.roomId, link.code), c.name, roomId: c.roomId));
    }
    return out;
  }
}

/// The picker sheet; returns the picked row, or null when closed.
Future<SendAsChoice?> pickSendAs(BuildContext context, {required List<SendAsChoice> choices, required String current}) => showCupertinoModalPopup<SendAsChoice>(
  useRootNavigator: !Wide.on,
  context: context,
  builder: (_) => SendAsSheet(choices: choices, current: current),
);

class SendAsSheet extends StatelessWidget {
  const SendAsSheet({super.key, required this.choices, required this.current});
  final List<SendAsChoice> choices;
  final String current;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final p = paletteOf(context);
    final s = AppScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom > 0 ? bottom : 10),
      child: LiquidGlass(
        key: const Key('send-as-sheet'),
        radius: IosActionSheet.radius,
        child: ColoredBox(
          color: p.card.withValues(alpha: p.dark ? 0.5 : 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], Tokens.space[3], Tokens.space[3], Tokens.space[0]),
                child: Text(
                  l.sendAsTitle,
                  textAlign: TextAlign.center,
                  style: Tokens.body.style.copyWith(color: p.label, fontWeight: Tokens.semi),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(Tokens.space[3], 0, Tokens.space[3], Tokens.space[2]),
                child: Text(
                  l.sendAsInfo,
                  textAlign: TextAlign.center,
                  style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                ),
              ),
              for (final c in choices)
                GestureDetector(
                  key: Key('send-as-${c.as == null ? 'me' : (c.as!.channel ? 'channel' : c.as!.room)}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context, c),
                  child: SizedBox(
                    height: Tokens.settingsRow + 4,
                    child: Row(
                      children: [
                        SizedBox(width: Tokens.space[3]),
                        c.roomId != null
                            ? Avatar(name: c.name, size: 36, roomId: c.roomId, squircle: true, channel: true)
                            : Avatar(name: c.name, size: 36, userId: s.backend.userId),
                        SizedBox(width: Tokens.space[2]),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Tokens.body.style.copyWith(color: p.label),
                              ),
                              Text(
                                c.as == null ? l.sendAsMe : (c.as!.channel ? l.sendAsChannelHidden : l.sendAsMyChannel),
                                style: Tokens.caption.style.copyWith(color: p.secondaryLabel),
                              ),
                            ],
                          ),
                        ),
                        if (c.key == current) Icon(CupertinoIcons.checkmark_alt, key: const Key('send-as-check'), color: p.accent, size: Tokens.listIcon),
                        SizedBox(width: Tokens.space[3]),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: Tokens.space[2]),
            ],
          ),
        ),
      ),
    );
  }
}
