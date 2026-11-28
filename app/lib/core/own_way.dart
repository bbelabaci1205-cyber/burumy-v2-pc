// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 우리식 기능 묶음 (Features.ownWay): what the app state does for it after
// each refresh, and the hidden notes it listens for.
import 'ai_local.dart';
import 'app_state.dart';
import 'backend.dart';
import 'best_friend.dart';
import 'feed_comments.dart';
import 'memories.dart';
import 'screen_guard.dart';
import 'shot_alert.dart';

class OwnWay {
  const OwnWay._();

  static Map<String, Future<void> Function(Signal s)> handlers(AppState s) => {
    ShotAlert.kind: (g) => ShotAlert.onSignal(s, g),
    FeedComments.sendKind: (g) => FeedComments.onComment(s, g),
    FeedComments.listKind: (g) => FeedComments.onList(s, g),
  };

  /// After the chat list was read: the ❤ and today's memories (both on
  /// this phone only), and the screenshot hook for this account.
  static Future<void> afterRefresh(AppState s) async {
    ScreenGuard.onShot = (what) => ShotAlert.taken(s, s.openRoom ?? '', what);
    // AI 친구 shows only where the phone has its own AI.
    if (LocalAi.known == null) await LocalAi.status();
    try {
      await BestFriend.check(s);
    } catch (_) {}
    await Memories.check(s);
  }
}
