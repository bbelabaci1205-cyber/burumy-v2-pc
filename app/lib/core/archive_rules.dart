// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// 보관함 설정 (Telegram tip 187). Like Telegram, a chat in the archive whose
// alerts are on comes back to the chat list when someone writes there;
// muted chats stay. Two switches keep them in:
// - 알림 켠 대화도 계속 보관 (archive_keep_unmuted)
// - 폴더에 넣은 대화도 계속 보관 (archive_keep_folder): chats I added to
//   a folder by hand
// and 모르는 사람의 새 대화 보관 (LoginSafety.strangerArchiveKey, tip 343)
// puts strangers' new chats there, muted. All of it stays on this phone.
import 'dart:convert';

import 'app_state.dart';

const archiveKeepUnmutedKey = 'archive_keep_unmuted';
const archiveKeepFolderKey = 'archive_keep_folder';

/// Last message id per archived chat when last looked (archive_seen).
const _seenKey = 'archive_seen';

extension ArchiveRules on AppState {
  Map<String, String> _archiveSeen() {
    try {
      final j = jsonDecode(pref(_seenKey, '{}'));
      return j is Map ? {for (final e in j.entries) '${e.key}': '${e.value}'} : {};
    } catch (_) {
      return {};
    }
  }

  /// Chats added to a folder by hand.
  Set<String> _inFolders() {
    try {
      final j = jsonDecode(pref('folders', '[]'));
      return {
        for (final f in j as List)
          if (f is Map && f['include'] is List) ...(f['include'] as List).map((x) => '$x'),
      };
    } catch (_) {
      return {};
    }
  }

  /// Brings archived chats with alerts on back when a new message came
  /// from someone else since they were archived. True when one moved.
  Future<bool> liftArchived() async {
    final seen = _archiveSeen();
    final before = jsonEncode(seen);
    final keepAll = on(archiveKeepUnmutedKey);
    final keepFolder = on(archiveKeepFolderKey);
    final folders = keepFolder ? _inFolders() : const <String>{};
    final archived = {
      for (final c in chats)
        if (c.archived) c.roomId,
    };
    seen.removeWhere((k, _) => !archived.contains(k));
    var moved = false;
    for (final c in chats) {
      if (!c.archived) continue;
      final last = c.last?.id ?? '';
      final was = seen[c.roomId];
      seen[c.roomId] = last;
      // First look (or nothing new): remember where it stood.
      if (was == null || was == last) continue;
      final m = c.last;
      if (m == null || m.mine || c.muted || keepAll || folders.contains(c.roomId)) continue;
      await backend.setChatArchived(c.roomId, false);
      seen.remove(c.roomId);
      moved = true;
    }
    if (jsonEncode(seen) != before) await setPref(_seenKey, seen.isEmpty ? '' : jsonEncode(seen));
    return moved;
  }
}
