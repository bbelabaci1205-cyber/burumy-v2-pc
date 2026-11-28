// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Hidden signals: small end-to-end encrypted notes between phones inside a
//! chat that never show as messages (remote emergency wipe requests, join
//! request answers and the like). The app decides what each kind means; the
//! engine only carries them and keeps the ones that arrived since the last
//! look. Plain-text (unencrypted) copies are ignored.
use anyhow::{Context, Result};
use matrix_sdk::ruma::RoomId;

use crate::{to_err, Engine};

pub const SIGNAL_TYPE: &str = "im.securemessenger.signal";

/// Biggest data a signal may carry (bytes of JSON). 16 KiB: room texts
/// (welcome 500 + rules 2,000 Korean characters) fit, and the encrypted
/// event stays far below Matrix's 64 KiB.
pub const MAX_DATA: usize = 16 * 1024;

/// Biggest file [Engine::upload_secret] takes (welcome photo or video).
pub const MAX_SECRET_FILE: usize = 50 * 1024 * 1024;

/// Most signals kept waiting for the app.
const MAX_WAITING: usize = 200;

#[derive(Clone, Debug, PartialEq)]
pub struct Signal {
    pub room_id: String,
    pub event_id: String,
    pub sender: String,
    pub kind: String,
    /// JSON text.
    pub data: String,
    /// Sent at (ms since 1970, the sender's clock as the server saw it).
    pub ts: u64,
}

/// Kinds are short lower-case words: a-z, 0-9 and _ (1-32).
pub fn kind_ok(kind: &str) -> bool {
    !kind.is_empty() && kind.len() <= 32 && kind.bytes().all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_')
}

/// Reads one raw timeline event; Some when it is a signal from someone else.
pub fn parse(room_id: &str, raw: &str, me: &str) -> Option<Signal> {
    let v: serde_json::Value = serde_json::from_str(raw).ok()?;
    if v["type"].as_str() != Some(SIGNAL_TYPE) {
        return None;
    }
    let sender = v["sender"].as_str()?;
    if sender == me {
        return None;
    }
    let kind = v["content"]["kind"].as_str()?;
    if !kind_ok(kind) {
        return None;
    }
    let data = v["content"].get("data").cloned().unwrap_or(serde_json::Value::Null);
    let data = data.to_string();
    if data.len() > MAX_DATA {
        return None;
    }
    Some(Signal {
        room_id: room_id.to_owned(),
        event_id: v["event_id"].as_str().unwrap_or_default().to_owned(),
        sender: sender.to_owned(),
        kind: kind.to_owned(),
        data,
        ts: v["origin_server_ts"].as_u64().unwrap_or(0),
    })
}

impl Engine {
    /// Sends a hidden signal into an encrypted chat.
    pub async fn send_signal(&self, room_id: &RoomId, kind: &str, data: &str) -> Result<()> {
        anyhow::ensure!(kind_ok(kind), "bad kind");
        let data: serde_json::Value = serde_json::from_str(data).context("bad data")?;
        anyhow::ensure!(data.to_string().len() <= MAX_DATA, "too big");
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(room.encryption_state().is_encrypted(), "not encrypted");
        room.send_raw(SIGNAL_TYPE, serde_json::json!({ "kind": kind, "data": data }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Encrypts bytes on this phone and uploads them; returns the file's
    /// key and address (JSON) to pass inside an encrypted signal. The server
    /// keeps only ciphertext and never sees the key.
    pub async fn upload_secret(&self, bytes: Vec<u8>) -> Result<String> {
        anyhow::ensure!(!bytes.is_empty() && bytes.len() <= MAX_SECRET_FILE, "bad size");
        let mut cursor = std::io::Cursor::new(bytes);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        Ok(serde_json::to_string(&file)?)
    }

    /// Downloads and decrypts a file from [Engine::upload_secret].
    pub async fn download_secret(&self, file: &str) -> Result<Vec<u8>> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let file: EncryptedFile = serde_json::from_str(file).context("bad file")?;
        self.client
            .media()
            .get_media_content(
                &MediaRequestParameters {
                    source: MediaSource::Encrypted(Box::new(file)),
                    format: MediaFormat::File,
                },
                true,
            )
            .await
            .map_err(to_err)
    }

    /// Signals that arrived since the last call (oldest first).
    pub fn take_signals(&self) -> Vec<Signal> {
        std::mem::take(&mut *self.signals.lock().unwrap())
    }

    pub(crate) fn on_signals(&self, rooms: &matrix_sdk::sync::RoomUpdates) {
        let Some(me) = self.client.user_id().map(|u| u.to_string()) else {
            return;
        };
        let mut got = vec![];
        for (room_id, upd) in &rooms.joined {
            for ev in &upd.timeline.events {
                if matches!(ev.kind, crate::TimelineEventKind::PlainText { .. }) {
                    continue;
                }
                if let Some(s) = parse(room_id.as_str(), ev.raw().json().get(), &me) {
                    got.push(s);
                }
            }
        }
        if got.is_empty() {
            return;
        }
        let mut w = self.signals.lock().unwrap();
        for s in got {
            if !w.iter().any(|x| x.event_id == s.event_id && !s.event_id.is_empty()) {
                w.push(s);
            }
        }
        let n = w.len();
        if n > MAX_WAITING {
            w.drain(..n - MAX_WAITING);
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn room_texts_fit() {
        // Welcome 500 + rules 2,000 Korean characters (3 bytes each) + a
        // photo key fit in one signal.
        let pack = serde_json::json!({"welcome": "가".repeat(500), "rules": "나".repeat(2000), "media": {"file": "x".repeat(700)}});
        assert!(pack.to_string().len() <= MAX_DATA);
    }

    #[test]
    fn kinds() {
        assert!(kind_ok("wipe"));
        assert!(kind_ok("join_answer2"));
        assert!(!kind_ok(""));
        assert!(!kind_ok("Wipe"));
        assert!(!kind_ok("a-b"));
        assert!(!kind_ok(&"a".repeat(33)));
    }

    #[test]
    fn parses_only_others_signals() {
        let raw = r#"{"type":"im.securemessenger.signal","sender":"@a:x","event_id":"$1","origin_server_ts":5,"content":{"kind":"wipe","data":{"code":"x"}}}"#;
        let s = parse("!r:x", raw, "@me:x").unwrap();
        assert_eq!(s.kind, "wipe");
        assert_eq!(s.sender, "@a:x");
        assert_eq!(s.data, r#"{"code":"x"}"#);
        assert_eq!(s.ts, 5);
        assert!(parse("!r:x", raw, "@a:x").is_none());
        let bad = r#"{"type":"im.securemessenger.signal","sender":"@a:x","content":{"kind":"BAD","data":1}}"#;
        assert!(parse("!r:x", bad, "@me:x").is_none());
        let other = r#"{"type":"m.room.message","sender":"@a:x","content":{"kind":"wipe"}}"#;
        assert!(parse("!r:x", other, "@me:x").is_none());
    }
}
