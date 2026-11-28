// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 폴더 링크 (Telegram tip 211): one link that adds a folder and lets the
// person join its groups and channels in one go.
//
//   https://<host>/folder#n=<name b64url>&e=<emoji b64url>&c=<items>
//   items joined by '~':  p.<address>            public group / channel
//                         k.<code>.<g|c>.<name>  private link (name base64url)
//
// Everything sits after '#', so the folder name and the private codes never
// reach a web server or its logs (same as private invite links). The link
// only carries invite links that already exist; 1:1 chats and chats without
// a link stay out. Joining still follows each chat's own rules (approval,
// join questions, link limits).
import 'dart:convert';

import 'room_links.dart';

class FolderLinkItem {
  const FolderLinkItem({required this.kind, required this.code, this.name = '', this.channel = false});

  /// "public" or "private" (as LinkTarget).
  final String kind;
  final String code;
  final String name;
  final bool channel;

  LinkTarget get target => LinkTarget(kind: kind, code: code, name: name, channel: channel);

  String get _part => kind == 'public' ? 'p.$code' : 'k.$code.${channel ? 'c' : 'g'}.${_b64(Uri.decodeComponent(shortName(name)))}';
}

/// Names and the emoji go as base64url (about half as long as %-escaped
/// Korean, and no % signs in the message).
String _b64(String text) => base64Url.encode(utf8.encode(text)).replaceAll('=', '');

String _unb64(String text) {
  try {
    return utf8.decode(base64Url.decode(base64Url.normalize(text)));
  } catch (_) {
    return '';
  }
}

class FolderLink {
  const FolderLink({required this.name, this.emoji = '', required this.items});
  final String name;
  final String emoji;
  final List<FolderLinkItem> items;

  /// Telegram lets a shared folder hold up to 100 chats; a QR code and a
  /// message stay readable with fewer.
  static const most = 50;

  String get url {
    final n = _b64(Uri.decodeComponent(shortName(name)));
    final e = emoji.isEmpty ? '' : '&e=${_b64(emoji)}';
    return 'https://${RoomLinks.host}/folder#n=$n$e&c=${items.take(most).map((i) => i._part).join('~')}';
  }

  /// Our folder link inside any text, or null.
  static FolderLink? parse(String text) {
    final h = RegExp.escape(RoomLinks.host);
    final m = RegExp('(?:https?://)?$h/folder#(\\S+)').firstMatch(text.trim());
    if (m == null) return null;
    final Map<String, String> q;
    try {
      q = Uri.splitQueryString(m.group(1)!);
    } catch (_) {
      return null;
    }
    final items = <FolderLinkItem>[];
    for (final part in (q['c'] ?? '').split('~')) {
      final x = part.split('.');
      if (x.length == 2 && x[0] == 'p' && RegExp(r'^[A-Za-z][A-Za-z0-9_]{4,31}$').hasMatch(x[1])) {
        items.add(FolderLinkItem(kind: 'public', code: x[1].toLowerCase()));
      } else if (x.length == 4 && x[0] == 'k' && RegExp(r'^[a-z2-9]{26}$').hasMatch(x[1])) {
        var name = '';
        try {
          name = utf8.decode(base64Url.decode(base64Url.normalize(x[3])));
        } catch (_) {}
        items.add(FolderLinkItem(kind: 'private', code: x[1], name: name, channel: x[2] == 'c'));
      }
      if (items.length >= most) break;
    }
    final name = _unb64(q['n'] ?? '').trim();
    if (items.isEmpty || name.isEmpty) return null;
    return FolderLink(name: name, emoji: _unb64(q['e'] ?? ''), items: items);
  }
}
