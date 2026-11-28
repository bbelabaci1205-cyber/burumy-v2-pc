// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 전체 검색 (search in every chat, Telegram tips 500 + 189 + 248).
//!
//! Messages are end-to-end encrypted, so the server can't search them and
//! must not learn what anyone looks for. Everything here runs on the phone
//! over messages it already opened. Hidden chats (the hide / delete
//! passwords) and hidden messages are never looked at, view-once photos
//! and home-screen bubbles never show up.

use anyhow::Result;
use matrix_sdk::ruma::RoomId;

use crate::{Engine, Message, to_err};

/// What to look for (`kind` of [Engine::search_all]).
pub const KINDS: [&str; 6] = ["text", "media", "link", "file", "music", "voice"];

const MUSIC_EXT: [&str; 7] = [".mp3", ".m4a", ".aac", ".wav", ".ogg", ".flac", ".opus"];

fn has(s: Option<&str>, term: &str) -> bool {
    s.is_some_and(|s| s.to_lowercase().contains(term))
}

fn has_link(s: &str) -> bool {
    s.contains("http://") || s.contains("https://")
}

fn is_music(m: &Message) -> bool {
    let name = m.body.as_deref().unwrap_or("").to_lowercase();
    match m.kind.as_str() {
        // A recorded voice message carries its loudness bars.
        "audio" => m.voice.is_none(),
        "file" => MUSIC_EXT.iter().any(|e| name.ends_with(e)),
        _ => false,
    }
}

/// Does this message belong in the results for `kind` + `term` (`term`
/// already lower case; empty = every message of that kind)?
pub fn search_hit(m: &Message, kind: &str, term: &str) -> bool {
    if m.body.is_none() || m.view_once || m.bubble || m.replaces.is_some() {
        return false;
    }
    let words = || {
        term.is_empty()
            || has(m.body.as_deref(), term)
            || has(m.caption.as_deref(), term)
            || m.preview.as_ref().is_some_and(|p| {
                p.title.to_lowercase().contains(term) || has(p.description.as_deref(), term)
            })
    };
    match kind {
        "text" => {
            !term.is_empty()
                && matches!(m.kind.as_str(), "text" | "file" | "image" | "video" | "audio")
                && (has(m.body.as_deref(), term) || has(m.caption.as_deref(), term))
        }
        "media" => matches!(m.kind.as_str(), "image" | "video") && words(),
        "link" => m.kind == "text" && has_link(m.body.as_deref().unwrap_or("")) && words(),
        "file" => m.kind == "file" && !is_music(m) && words(),
        "music" => is_music(m) && words(),
        "voice" => m.kind == "audio" && m.voice.is_some() && (term.is_empty() || has(m.caption.as_deref(), term)),
        _ => false,
    }
}

impl Engine {
    /// Messages of one chat matching `kind` + `term`, oldest first. Looks
    /// back through up to `max_events` past events. Hidden chats give none.
    pub(crate) async fn search_room(
        &self,
        room_id: &RoomId,
        kind: &str,
        term: &str,
        max_events: usize,
        unseen: &[String],
    ) -> Result<Vec<Message>> {
        let room = self.client.get_room(room_id).ok_or_else(|| anyhow::anyhow!("unknown room"))?;
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        loop {
            if cache.events().await.map_err(to_err)?.len() >= max_events {
                break;
            }
            let outcome = cache.pagination().run_backwards_once(100).await.map_err(to_err)?;
            if outcome.reached_start {
                break;
            }
        }
        let now: u64 = matrix_sdk::ruma::MilliSecondsSinceUnixEpoch::now().get().into();
        Ok(self
            .fold(&cache.events().await.map_err(to_err)?)
            .into_iter()
            .filter(|m| {
                !unseen.contains(&m.event_id)
                    && m.expires_at.is_none_or(|t| t > now)
                    && search_hit(m, kind, term)
            })
            .collect())
    }

    /// 전체 검색: messages in every chat on this phone, newest first, at
    /// most `limit`. `kind` is one of [KINDS]; `term` may be empty for the
    /// kinds other than "text" (then every photo, link, file... is listed).
    /// Nothing is sent to the server: the words stay on this phone.
    pub async fn search_all(
        &self,
        term: &str,
        kind: &str,
        max_events: usize,
        limit: usize,
    ) -> Result<Vec<(String, Message)>> {
        let term = term.trim().to_lowercase();
        anyhow::ensure!(KINDS.contains(&kind), "unknown kind");
        if kind == "text" && term.is_empty() {
            return Ok(vec![]);
        }
        let q = self.quiet_state().await.unwrap_or_default();
        let unseen = self.unseen(&q);
        let mut out = Vec::new();
        for room in self.client.joined_rooms() {
            let rid = room.room_id().to_owned();
            if self.is_quiet(&rid, &q).await || self.is_community(&rid).await {
                continue;
            }
            // One chat that can't be read must not spoil the whole search.
            if let Ok(found) = self.search_room(&rid, kind, &term, max_events, &unseen).await {
                out.extend(found.into_iter().map(|m| (rid.to_string(), m)));
            }
        }
        out.sort_by(|a, b| b.1.ts.cmp(&a.1.ts));
        out.truncate(limit);
        Ok(out)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn m(kind: &str, body: &str) -> Message {
        Message { kind: kind.into(), body: Some(body.into()), ..Message::default() }
    }

    #[test]
    fn kinds() {
        assert!(search_hit(&m("text", "Go to #Future now"), "text", "#future"));
        assert!(!search_hit(&m("text", "hello"), "text", ""));
        assert!(search_hit(&m("text", "see https://a.b/c"), "link", ""));
        assert!(!search_hit(&m("text", "no link"), "link", ""));
        assert!(search_hit(&m("file", "song.MP3"), "music", ""));
        assert!(!search_hit(&m("file", "song.mp3"), "file", ""));
        assert!(search_hit(&m("file", "plan.pdf"), "file", "plan"));
        let mut v = m("audio", "voice.ogg");
        assert!(search_hit(&v, "music", ""));
        v.voice = Some(crate::Voice { duration_ms: 1000, waveform: vec![] });
        assert!(search_hit(&v, "voice", "") && !search_hit(&v, "music", ""));
        let mut once = m("image", "a.jpg");
        assert!(search_hit(&once, "media", ""));
        once.view_once = true;
        assert!(!search_hit(&once, "media", ""));
        let mut cap = m("image", "a.jpg");
        cap.caption = Some("Trip to Busan".into());
        assert!(search_hit(&cap, "text", "busan") && search_hit(&cap, "media", "busan"));
        let mut locked = m("text", "x");
        locked.body = None;
        assert!(!search_hit(&locked, "media", ""));
    }
}
