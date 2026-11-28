// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 주제 (group topics, Telegram tip 527).
//!
//! A topic is only a short id written INSIDE the encrypted message content
//! (`app.burumy.topic`). It is never put in `m.relates_to` (which Matrix
//! leaves readable to the server), so the server cannot tell which message
//! belongs to which topic, or that the group has topics at all. The topic
//! list itself (names, icons, closed) travels as an encrypted pack from an
//! admin's phone; the room keeps only its fingerprint (room setting
//! "topics", see `check_room_config`).
//!
//! The app says which topic the chat screen is in (`set`); every message
//! sent into that room from then on carries it, until it is cleared.

use std::collections::HashMap;
use std::sync::{LazyLock, Mutex};

/// Field inside the encrypted message content.
pub const FIELD: &str = "app.burumy.topic";

/// Longest topic id accepted from other phones.
pub const MAX_ID: usize = 24;

static SENDING: LazyLock<Mutex<HashMap<String, String>>> = LazyLock::new(Default::default);

/// Only short ids of letters, digits, '-' and '_' (anything else = 일반).
pub fn valid(id: &str) -> bool {
    !id.is_empty() && id.len() <= MAX_ID && id.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'-' || b == b'_')
}

/// The topic new messages in `room` go to; None or "g" = 일반 (no field).
pub fn set(room: &str, topic: Option<&str>) {
    let Ok(mut m) = SENDING.lock() else { return };
    match topic.filter(|t| valid(t) && *t != "g") {
        Some(t) => {
            m.insert(room.to_owned(), t.to_owned());
        }
        None => {
            m.remove(room);
        }
    }
}

pub fn current(room: &str) -> Option<String> {
    SENDING.lock().ok()?.get(room).cloned()
}

/// Puts the current topic into an outgoing content object.
pub fn stamp(room: &str, content: &mut serde_json::Value) {
    if let (Some(t), Some(o)) = (current(room), content.as_object_mut()) {
        o.insert(FIELD.to_owned(), t.into());
    }
}

/// The topic of a received event (full event JSON, already decrypted).
pub fn read(event_json: &str) -> Option<String> {
    let v: serde_json::Value = serde_json::from_str(event_json).ok()?;
    let t = v.get("content")?.get(FIELD)?.as_str()?;
    valid(t).then(|| t.to_owned()).filter(|t| t != "g")
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn stamps_and_reads() {
        set("!a:x", Some("t1"));
        let mut c = json!({"msgtype": "m.text", "body": "hi"});
        stamp("!a:x", &mut c);
        assert_eq!(c[FIELD], "t1");
        let ev = json!({"type": "m.room.message", "content": c}).to_string();
        assert_eq!(read(&ev).as_deref(), Some("t1"));
        // Another room is untouched; clearing stops the stamp.
        let mut d = json!({"body": "x"});
        stamp("!b:x", &mut d);
        assert!(d.get(FIELD).is_none());
        set("!a:x", None);
        let mut e = json!({"body": "x"});
        stamp("!a:x", &mut e);
        assert!(e.get(FIELD).is_none());
    }

    #[test]
    fn rejects_bad_ids() {
        for bad in ["", "g", "a b", "<script>", &"x".repeat(MAX_ID + 1)] {
            let ev = json!({"content": {FIELD: bad}}).to_string();
            assert_eq!(read(&ev), None, "{bad}");
        }
        assert_eq!(read(&json!({"content": {FIELD: 5}}).to_string()), None);
        set("!c:x", Some("g"));
        assert_eq!(current("!c:x"), None);
    }
}
