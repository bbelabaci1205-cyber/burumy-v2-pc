// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
// Emoji tags on saved messages ("저장한 메시지"): kept in this device's own
// settings only, used to filter the saved messages chat.
import 'dart:convert';

import 'app_state.dart';

/// The twelve tags offered after saving (Burumy v1 order).
const savedTagChoices = ['🔥', '⭐', '✍️', '💡', '📅', '⚡', '📰', '✅', '❤️', '👍', '📌', '😂'];

/// Message id -> tag.
Map<String, String> savedTags(AppState s) {
  try {
    final v = jsonDecode(s.pref('saved_tags', '{}'));
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.key is String && e.value is String && savedTagChoices.contains(e.value)) e.key as String: e.value as String,
    };
  } catch (_) {
    return {};
  }
}

/// Sets (or with null removes) the tag of saved messages.
Future<void> setSavedTag(AppState s, Iterable<String> ids, String? tag) {
  final m = savedTags(s);
  for (final id in ids) {
    if (tag == null) {
      m.remove(id);
    } else {
      m[id] = tag;
    }
  }
  return s.setPref('saved_tags', m.isEmpty ? '' : jsonEncode(m));
}

/// Saved copy id -> the chat it was saved from. Kept on this device only
/// (the server never learns where a saved message came from).
Map<String, String> savedFrom(AppState s) {
  try {
    final v = jsonDecode(s.pref('saved_from', '{}'));
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.key is String && e.value is String) e.key as String: e.value as String,
    };
  } catch (_) {
    return {};
  }
}

/// Remembers where saved copies came from.
Future<void> setSavedFrom(AppState s, Iterable<String> ids, String roomId) {
  final m = savedFrom(s);
  for (final id in ids) {
    m[id] = roomId;
  }
  return s.setPref('saved_from', jsonEncode(m));
}
