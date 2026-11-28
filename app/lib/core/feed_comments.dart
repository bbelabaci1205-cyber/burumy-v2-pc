// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 친구 피드 댓글 — 아는 친구 댓글만 보이기 (WeChat Moments, our way; 4대
// 메신저 보드 '우리식으로', Eric 2026-11-28).
//
// WeChat's server decides who sees which comment, so it knows everyone's
// friend list. Here no server is asked:
// 1. My comment goes to the poster alone, inside our 1:1 chat's
//    encryption (a hidden note, Backend.sendSignal).
// 2. The poster's phone hands the post's comments to the friends the post
//    went to, again inside each 1:1 chat's encryption.
// 3. Each friend's phone shows only the comments of people that friend
//    knows (their own contacts), plus their own and the poster's. The
//    poster sees all of them.
// The server only ever carries scrambled notes between two friends.
import 'dart:convert';

import 'app_state.dart';
import 'backend.dart';

class FeedComment {
  const FeedComment({required this.id, required this.who, required this.text, required this.at});
  final String id;
  final String who;
  final String text;
  final DateTime at;

  Map<String, Object> toJson() => {'i': id, 'w': who, 't': text, 'a': at.millisecondsSinceEpoch};

  static FeedComment? fromJson(Object? v) {
    if (v is! Map) return null;
    final id = v['i'], who = v['w'], t = v['t'], a = v['a'];
    if (id is! String || who is! String || t is! String || a is! int) return null;
    if (id.isEmpty || id.length > 40 || t.trim().isEmpty) return null;
    return FeedComment(
      id: id,
      who: who,
      text: t.length > FeedComments.maxText ? t.substring(0, FeedComments.maxText) : t,
      at: DateTime.fromMillisecondsSinceEpoch(a),
    );
  }
}

class FeedComments {
  const FeedComments._();

  /// Commenter → poster ("feed_c"); poster → the post's friends ("feed_cl").
  static const sendKind = 'feed_c';
  static const listKind = 'feed_cl';

  static const maxText = 500;
  static const maxPerPost = 100;

  static String _key(String post) => 'feed_c:$post';

  /// Who my own post went to (set when I post it).
  static String audienceKey(String post) => 'feed_aud:$post';

  /// Saved under [audienceKey] for a post that went to everyone.
  static const everyone = '*';

  static List<FeedComment> all(AppState s, String post) {
    final raw = s.pref(_key(post), '');
    if (raw.isEmpty) return const [];
    try {
      return [for (final v in jsonDecode(raw) as List) ?FeedComment.fromJson(v)]..sort((a, b) => a.at.compareTo(b.at));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _store(AppState s, String post, List<FeedComment> list) {
    final keep = list.length > maxPerPost ? list.sublist(list.length - maxPerPost) : list;
    return s.setPref(_key(post), keep.isEmpty ? '' : jsonEncode([for (final c in keep) c.toJson()]));
  }

  /// What I may see under [post]: everything on my own post; on a
  /// friend's, only people I know, me and the poster.
  static List<FeedComment> visible(AppState s, Story post) {
    final list = all(s, post.id);
    if (post.mine) return list;
    final me = s.backend.userId ?? '';
    return [
      for (final c in list)
        if (c.who == me || c.who == post.sender || s.friendIds.contains(c.who)) c,
    ];
  }

  /// Writes a comment under [post].
  static Future<void> add(AppState s, Story post, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final me = s.backend.userId ?? '';
    final now = DateTime.now();
    final c = FeedComment(id: 'c${now.microsecondsSinceEpoch}', who: me, text: t.length > maxText ? t.substring(0, maxText) : t, at: now);
    await _store(s, post.id, [...all(s, post.id), c]);
    if (post.mine) {
      await _handOut(s, post.id);
    } else {
      await s.backend.sendSignal(post.roomId, sendKind, {'p': post.id, ...c.toJson()});
    }
  }

  /// Takes a comment away: mine anywhere, anyone's on my own post.
  static Future<void> remove(AppState s, Story post, FeedComment c) async {
    final me = s.backend.userId ?? '';
    if (!post.mine && c.who != me) return;
    await _store(s, post.id, [
      for (final x in all(s, post.id))
        if (x.id != c.id) x,
    ]);
    if (post.mine) {
      await _handOut(s, post.id);
    } else {
      await s.backend.sendSignal(post.roomId, sendKind, {'p': post.id, 'i': c.id, 'del': true});
    }
  }

  static Story? _mine(AppState s, String post) => s.feed.where((x) => x.id == post && x.mine).firstOrNull;

  /// A friend commented on (or took back a comment from) my post.
  static Future<void> onComment(AppState s, Signal g) async {
    final post = g.data['p'];
    if (post is! String || _mine(s, post) == null) return;
    final now = all(s, post);
    if (g.data['del'] == true) {
      final id = g.data['i'];
      await _store(s, post, [
        for (final x in now)
          if (!(x.id == id && x.who == g.sender)) x,
      ]);
    } else {
      final c = FeedComment.fromJson({...g.data, 'w': g.sender});
      if (c == null || now.any((x) => x.id == c.id)) return;
      // Their clock may be off: never later than when it arrived.
      final fixed = c.at.isAfter(g.time) ? FeedComment(id: c.id, who: c.who, text: c.text, at: g.time) : c;
      await _store(s, post, [...now, fixed]);
    }
    await _handOut(s, post);
  }

  /// The poster sent the comments of a post I got from them.
  static Future<void> onList(AppState s, Signal g) async {
    final post = g.data['p'];
    if (post is! String) return;
    final from = s.feed.where((x) => x.id == post && !x.mine).firstOrNull;
    if (from == null || from.sender != g.sender) return;
    final raw = g.data['c'];
    if (raw is! List) return;
    await _store(s, post, [for (final v in raw.take(maxPerPost)) ?FeedComment.fromJson(v)]);
  }

  /// My post's comments go to the friends it went to (each inside our
  /// 1:1 chat). Friends the post never reached get nothing.
  static Future<void> _handOut(AppState s, String post) async {
    final list = [for (final c in all(s, post)) c.toJson()];
    final saved = s.pref(audienceKey(post), '');
    // Who the post went to is unknown here (posted from another phone or
    // before this list was kept): hand out nothing rather than send the
    // comments to every 1:1 chat, people the post never reached included
    // (보안검수 2026-11-28).
    if (saved.isEmpty) return;
    final rooms = saved == everyone
        ? [
            for (final c in s.chats)
              if (c.isDirect && !c.isBot && c.roomId != s.savedRoomId && !s.isRequest(c.roomId)) c.roomId,
          ]
        : saved.split(',').where((r) => r.isNotEmpty).toList();
    for (final r in rooms) {
      try {
        await s.backend.sendSignal(r, listKind, {'p': post, 'c': list});
      } catch (_) {}
    }
  }
}
