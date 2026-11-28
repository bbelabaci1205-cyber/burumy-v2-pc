// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 채널에 글 제안 (Telegram tip 531), without money.
//
// A subscriber writes a post idea in the channel's admin chat (채널 문의함,
// tip 526: its own end-to-end encrypted room, built by the channel thread)
// as a "suggest" card: words and/or one photo (encrypted on the phone, only
// its key travels in the card) and a time they would like. An admin taps
// 올리기 (now, at their time, or another time; optionally with the
// suggester's name) or 거절 (with an optional reason) — a "suggest_deal"
// card answers it in the same chat ("합의됐어요!").
//
// The admin's own phone posts it into the channel: the server only ever
// sees an ordinary encrypted channel post from that admin, never that it
// was suggested or by whom. A post for later waits on the admin's phone
// (like the phone's scheduled messages) and goes out when the app runs.
// Telegram's Stars price / 24-hour hold is left out (money comes later with
// our own coin).
import 'dart:async';
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';

class SuggestPost {
  /// The channel this admin chat belongs to (#15's channel DM marker), or null.
  static String? channelOf(Map<String, dynamic> cfg) {
    final c = cfg['channel_dm'];
    return c is String && c.startsWith('!') ? c : null;
  }

  /// The subscriber who opened this admin chat.
  static String? subscriberOf(Map<String, dynamic> cfg) {
    final s = cfg['subscriber'];
    return s is String && s.isNotEmpty ? s : null;
  }

  /// The admin's answer to suggestion [cardId] among [msgs] (first wins).
  static Msg? dealFor(List<Msg> msgs, String cardId) =>
      msgs.where((m) => m.kind == 'card' && m.card?.kind == 'suggest_deal' && m.card!.data['to'] == cardId).firstOrNull;

  static DateTime? wantedAt(CardInfo c) {
    final at = c.data['at'];
    return at is int && at > 0 ? DateTime.fromMillisecondsSinceEpoch(at) : null;
  }

  /// The subscriber sends a suggestion. [photo]: (mime, bytes) or null.
  static Future<void> send(Backend b, String dmRoom, String channel, String text, {(String, List<int>)? photo, DateTime? at}) async {
    String? file;
    if (photo != null) file = await b.uploadEncrypted(photo.$2);
    await b.createCard(dmRoom, 'suggest', {
      'text': text.trim(),
      'photo': ?file,
      if (photo != null) 'mime': photo.$1,
      'at': at?.millisecondsSinceEpoch ?? 0,
      'channel': channel,
    });
  }

  /// An admin publishes it: now (at == null) or later on this phone.
  /// [credit]: the suggester's name, put under the post.
  static Future<void> accept(AppState s, String dmRoom, Msg card, {DateTime? at, String? credit, String creditLine = ''}) async {
    final b = s.backend;
    final c = card.card!;
    final channel = c.text('channel');
    final job = {
      'dm': dmRoom,
      'card': card.id,
      'channel': channel,
      'text': c.text('text'),
      if (c.text('photo').isNotEmpty) 'photo': c.text('photo'),
      if (c.text('mime').isNotEmpty) 'mime': c.text('mime'),
      if (credit != null) 'credit': creditLine,
    };
    final later = at != null && at.isAfter(b.clock.add(const Duration(minutes: 1)));
    if (later) {
      await s.setPref(
        dueKey,
        jsonEncode([
          ...due(s),
          {...job, 'at': at.millisecondsSinceEpoch},
        ]),
      );
    } else {
      await publish(b, job);
    }
    await b.createCard(dmRoom, 'suggest_deal', {'to': card.id, 'act': 'accept', 'at': later ? at.millisecondsSinceEpoch : 0, 'credit': credit != null});
  }

  static Future<void> decline(Backend b, String dmRoom, Msg card, {String note = ''}) =>
      b.createCard(dmRoom, 'suggest_deal', {'to': card.id, 'act': 'decline', 'note': note.trim()});

  static const dueKey = 'suggest_due';

  /// Accepted posts waiting on this phone for their time.
  static List<Map<String, dynamic>> due(AppState s) {
    try {
      return [for (final j in jsonDecode(s.pref(dueKey, '[]')) as List) (j as Map).cast<String, dynamic>()];
    } catch (_) {
      return [];
    }
  }

  /// Posts it into the channel from this phone.
  static Future<void> publish(Backend b, Map<String, dynamic> job) async {
    final channel = job['channel'] as String;
    final credit = (job['credit'] as String?) ?? '';
    final words = [job['text'] as String? ?? '', if (credit.isNotEmpty) credit].where((x) => x.trim().isNotEmpty).join('\n\n');
    final photo = job['photo'] as String?;
    if (photo != null) {
      final bytes = await b.downloadEncrypted(photo);
      final mime = job['mime'] as String? ?? 'image/jpeg';
      await b.sendFile(channel, name: 'photo.${mime.split('/').last}', mime: mime, bytes: bytes, caption: words);
    } else {
      await b.sendText(channel, words);
    }
  }

  /// On each refresh: post what is due (kept for a retry if it fails).
  static Future<void> run(AppState s) async {
    final all = due(s);
    if (all.isEmpty) return;
    final now = s.backend.clock.millisecondsSinceEpoch;
    final left = <Map<String, dynamic>>[];
    for (final j in all) {
      if ((j['at'] as num? ?? 0) > now) {
        left.add(j);
        continue;
      }
      try {
        await publish(s.backend, j);
      } catch (_) {
        left.add(j);
      }
    }
    if (left.length != all.length) await s.setPref(dueKey, left.isEmpty ? '' : jsonEncode(left));
  }
}
