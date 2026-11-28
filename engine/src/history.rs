// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 새 멤버에게 지난 메시지 보내기 (WhatsApp 2026): when I add someone to a
//! group, my phone can send them the last messages from before they came,
//! so they see the notice and the plan without asking again.
//!
//! Our rooms keep history closed to newcomers (server rule: history
//! visibility "invited"/"joined"), so the server can't hand old messages
//! out. Instead my phone packs the last messages it can read (sender,
//! time, words; for photos, videos, voice and files the encrypted file
//! reference = its place on the server + its key, not the file itself)
//! into one end-to-end encrypted device message for the
//! new member's phones only. The server sees an encrypted blob between two
//! accounts; it learns nothing of the words. The receiving phone keeps the
//! pack on the phone and shows it above the chat as "들어오기 전 대화",
//! and takes it only from someone who is really in that room.
//!
//! Never sent: disappearing messages (timer) and 한 번만 보기 media, so a
//! newcomer can't keep what the others only saw once or for a while.

use anyhow::{Context, Result, ensure};
use matrix_sdk::ruma::{RoomId, UserId};
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::{Engine, to_err};

pub const HISTORY_MSG: &str = "app.burumy.history";

/// Most messages in one pack (and each one's longest words).
pub const MAX_ITEMS: usize = 50;
pub const MAX_WORDS: usize = 1000;

/// A device message must stay small (servers cap them near 64 KB).
const MAX_BYTES: usize = 48 * 1024;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct EarlierMessage {
    pub sender: String,
    /// Server time in ms.
    pub ts: u64,
    /// "text", or the kind of a file ("image", "video", …) shown as a word.
    pub kind: String,
    /// Text, or the words under a photo / video / file.
    pub body: String,
    /// Encrypted file reference (JSON: place + key) of a photo, video,
    /// voice or file; "" for text.
    #[serde(default)]
    pub file: String,
    /// Small picture of a photo or video (same form), "" if none.
    #[serde(default)]
    pub thumb: String,
    #[serde(default)]
    pub mime: String,
    /// File name (files) or "" (photos, videos).
    #[serde(default)]
    pub name: String,
}

const MEDIA: [&str; 4] = ["image", "video", "audio", "file"];

/// Keeps a pack item only in a safe shape: file references must be real
/// encrypted references (mxc place + AES key), short fields stay short.
pub fn clean(mut m: EarlierMessage) -> Option<EarlierMessage> {
    let file_ok = |f: &str| -> String {
        serde_json::from_str::<serde_json::Value>(f)
            .ok()
            .and_then(|v| crate::article::clean_file(&v))
            .map(|v| v.to_string())
            .unwrap_or_default()
    };
    if MEDIA.contains(&m.kind.as_str()) {
        m.file = file_ok(&m.file);
        if m.file.is_empty() {
            return None;
        }
        m.thumb = if m.thumb.is_empty() { String::new() } else { file_ok(&m.thumb) };
    } else {
        m.kind = "text".into();
        m.file.clear();
        m.thumb.clear();
    }
    let ok_mime = m.mime.len() <= 100 && m.mime.chars().all(|c| c.is_ascii_alphanumeric() || "/+.-".contains(c));
    if !ok_mime {
        m.mime.clear();
    }
    m.name = m.name.chars().filter(|c| !c.is_control()).take(200).collect();
    Some(m)
}

/// Newest [count] messages that fit, oldest first.
pub fn pack(list: &[EarlierMessage], count: usize) -> Vec<EarlierMessage> {
    let mut out = Vec::new();
    let mut size = 0;
    for m in list.iter().rev().take(count.min(MAX_ITEMS)) {
        let mut m = m.clone();
        if m.body.chars().count() > MAX_WORDS {
            m.body = m.body.chars().take(MAX_WORDS).collect();
        }
        let n = serde_json::to_vec(&m).map(|v| v.len()).unwrap_or(MAX_BYTES);
        if size + n > MAX_BYTES {
            break;
        }
        size += n;
        out.push(m);
    }
    out.reverse();
    out
}

fn store_key(room: &str) -> Vec<u8> {
    format!("burumy.history.v1:{room}").into_bytes()
}

impl Engine {
    /// Sends the last [count] messages of this room to [user]'s phones.
    /// Returns how many went.
    pub async fn send_history(&self, room_id: &RoomId, user: &UserId, count: usize) -> Result<usize> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let msgs = self.timeline(room_id, 200).await?;
        let mut list: Vec<EarlierMessage> = Vec::new();
        for m in msgs {
            // Not: unreadable, thread replies, cards/plans/polls (they live
            // in their own events), disappearing or view-once ones.
            let shown = m.kind == "text" || MEDIA.contains(&m.kind.as_str());
            if m.body.is_none() || !shown || m.thread_root.is_some() || m.expires_at.is_some() || m.view_once {
                continue;
            }
            if m.kind == "text" {
                list.push(EarlierMessage {
                    sender: m.sender,
                    ts: m.ts,
                    kind: m.kind,
                    body: m.body.unwrap_or_default(),
                    file: String::new(),
                    thumb: String::new(),
                    mime: String::new(),
                    name: String::new(),
                });
                continue;
            }
            // A photo / video / voice / file: its encrypted reference from
            // the event this phone already decrypted.
            let Ok(eid) = <&matrix_sdk::ruma::EventId>::try_from(m.event_id.as_str()) else { continue };
            let Ok(ev) = room.event(eid, None).await else { continue };
            let Ok(v) = ev.raw().deserialize_as::<serde_json::Value>() else { continue };
            let c = &v["content"];
            let item = clean(EarlierMessage {
                sender: m.sender,
                ts: m.ts,
                kind: m.kind.clone(),
                body: m.caption.unwrap_or_default(),
                file: c["file"].to_string(),
                thumb: c["info"]["thumbnail_file"].to_string(),
                mime: c["info"]["mimetype"].as_str().unwrap_or_default().into(),
                name: if m.kind == "file" { m.body.unwrap_or_default() } else { String::new() },
            });
            list.extend(item);
        }
        let items = pack(&list, count);
        ensure!(!items.is_empty(), "nothing to send");
        let n = items.len();
        self.send_private(user.as_str(), HISTORY_MSG, &json!({ "room": room_id.as_str(), "items": items }))
            .await?;
        Ok(n)
    }

    /// A pack from someone: kept only when they are a member of that room
    /// and I am invited to it or in it.
    pub(crate) async fn take_history(&self, sender: &str, content: &serde_json::Value) -> Result<()> {
        let room_id = RoomId::parse(content["room"].as_str().context("no room")?).map_err(to_err)?;
        let room = self.client.get_room(&room_id).context("unknown room")?;
        let uid = UserId::parse(sender).map_err(to_err)?;
        let member = room.get_member_no_sync(&uid).await.map_err(to_err)?.context("not a member")?;
        ensure!(
            *member.membership() == matrix_sdk::ruma::events::room::member::MembershipState::Join,
            "sender not in the room"
        );
        let items: Vec<EarlierMessage> = serde_json::from_value(content["items"].clone())?;
        let items: Vec<EarlierMessage> = items.into_iter().filter_map(clean).collect();
        let items = pack(&items, MAX_ITEMS);
        self.client
            .state_store()
            .set_custom_value_no_read(&store_key(room_id.as_str()), serde_json::to_vec(&items)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// The photo / video / file of item [index] (or its small picture),
    /// downloaded and decrypted on this phone.
    pub async fn earlier_file(&self, room_id: &RoomId, index: usize, thumb: bool) -> Result<Vec<u8>> {
        let list = self.earlier_messages(room_id).await;
        let m = list.get(index).context("no such message")?;
        let f = if thumb && !m.thumb.is_empty() { &m.thumb } else { &m.file };
        ensure!(!f.is_empty(), "no file");
        self.download_encrypted(f).await
    }

    /// Messages from before I came, if someone sent them (oldest first).
    pub async fn earlier_messages(&self, room_id: &RoomId) -> Vec<EarlierMessage> {
        self.client
            .state_store()
            .get_custom_value(&store_key(room_id.as_str()))
            .await
            .ok()
            .flatten()
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn m(i: u64, body: &str) -> EarlierMessage {
        EarlierMessage {
            sender: "@a:t".into(),
            ts: i,
            kind: "text".into(),
            body: body.into(),
            file: String::new(),
            thumb: String::new(),
            mime: String::new(),
            name: String::new(),
        }
    }

    #[test]
    fn keeps_newest_in_order_and_small() {
        let list: Vec<_> = (0..120).map(|i| m(i, "안녕")).collect();
        let p = pack(&list, 50);
        assert_eq!(p.len(), 50);
        assert_eq!(p.first().unwrap().ts, 70);
        assert_eq!(p.last().unwrap().ts, 119);
        let long: Vec<_> = (0..50).map(|i| m(i, &"가".repeat(5000))).collect();
        let p = pack(&long, 50);
        assert!(p.iter().all(|x| x.body.chars().count() == MAX_WORDS));
        assert!(serde_json::to_vec(&p).unwrap().len() <= MAX_BYTES + 1024);
        assert_eq!(p.last().unwrap().ts, 49);
    }

    #[test]
    fn media_needs_a_real_encrypted_reference() {
        let good = serde_json::json!({
            "url": "mxc://s/abc", "key": {"k": "a2V5", "alg": "A256CTR", "kty": "oct", "key_ops": ["encrypt", "decrypt"], "ext": true},
            "iv": "aXY", "hashes": {"sha256": "c2hh"}, "v": "v2"
        })
        .to_string();
        let mut x = m(1, "사진 설명");
        x.kind = "image".into();
        x.file = good.clone();
        x.thumb = "{\"url\":\"https://evil\"}".into();
        x.mime = "image/jpeg\n<script>".into();
        let c = clean(x.clone()).unwrap();
        assert!(c.file.contains("mxc://s/abc"));
        assert!(c.thumb.is_empty(), "bad thumbnail dropped");
        assert!(c.mime.is_empty(), "odd mime dropped");
        x.file = "{\"url\":\"https://evil\"}".into();
        assert!(clean(x).is_none(), "media without a real reference is dropped");
        // A text never carries a file.
        let mut t = m(2, "hi");
        t.file = good;
        assert!(clean(t).unwrap().file.is_empty());
        // Older packs (no file fields) still read.
        let old: EarlierMessage = serde_json::from_str(r#"{"sender":"@a:t","ts":1,"kind":"text","body":"x"}"#).unwrap();
        assert_eq!(old.body, "x");
    }
}
