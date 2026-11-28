// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 임시 글 이어쓰기 (Telegram tip 241): what I typed but didn't send in a
// chat is kept on this device (draft:<room>) and, with the switch on
// (Settings > 대화, on by default), goes end-to-end encrypted to my other
// logged-in devices only. The newest text wins by its time, so a late
// message from an old device never overwrites newer words. Sending the
// message clears it everywhere.
import 'dart:async';

import 'app_state.dart';

/// Settings > 대화: share drafts with my other devices.
const draftSyncKey = 'draft_sync';

String draftKey(String roomId) => 'draft:$roomId';
String _atKey(String roomId) => 'draft_at:$roomId';

/// Set when the draft came from another device and the chat hasn't been
/// opened since ("다른 기기에서 쓰던 글" note in the chat).
String draftFromKey(String roomId) => 'draft_from:$roomId';

extension DraftSync on AppState {
  /// When the draft for [roomId] was last changed (any of my devices).
  DateTime draftAt(String roomId) => DateTime.fromMillisecondsSinceEpoch(int.tryParse(pref(_atKey(roomId), '0')) ?? 0);

  /// Keeps [text] as the draft (empty = none) and shares it with my other
  /// devices. Does nothing when it didn't change. The time stays even for
  /// an empty draft, so an older one arriving late can't bring it back.
  Future<void> saveDraft(String roomId, String text) async {
    if (text == pref(draftKey(roomId), '')) return;
    final at = DateTime.now();
    await setPref(draftKey(roomId), text);
    await setPref(_atKey(roomId), '${at.millisecondsSinceEpoch}');
    if (pref(draftFromKey(roomId), '').isNotEmpty) await setPref(draftFromKey(roomId), '');
    if (!on(draftSyncKey, fallback: true)) return;
    try {
      await backend.sendMyDraft(roomId, text, at);
    } catch (_) {}
  }

  /// Takes the drafts my other devices sent (called on every refresh).
  /// True when one changed here.
  Future<bool> takeOtherDrafts() async {
    if (!on(draftSyncKey, fallback: true)) return false;
    var changed = false;
    try {
      for (final d in await backend.takeSyncedDrafts()) {
        if (!d.at.isAfter(draftAt(d.roomId))) continue;
        if (d.text == pref(draftKey(d.roomId), '')) continue;
        await setPref(draftKey(d.roomId), d.text);
        await setPref(_atKey(d.roomId), '${d.at.millisecondsSinceEpoch}');
        await setPref(draftFromKey(d.roomId), d.text.isEmpty ? '' : '1');
        changed = true;
      }
    } catch (_) {}
    return changed;
  }
}
