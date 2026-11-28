// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 내 기기끼리 (Telegram tips 241 + 329):
//!
//! - 임시 글 이어쓰기: what I was typing in a chat goes, end-to-end
//!   encrypted, to my OTHER logged-in devices only (one device message
//!   to my own account). The server sees an encrypted blob from me to me;
//!   never the words or the chat. The newest text wins (its time is in
//!   the message), so an old message that arrives late can't overwrite a
//!   newer draft. The receiving device keeps them in its encrypted store
//!   until the app takes them ([Engine::take_synced_drafts]).
//! - 내 알림음: short sounds I saved for notifications live in the
//!   encrypted local store (never as a plain file), one store value each.
//!   They are not sent anywhere.

use anyhow::{Result, ensure};
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::{Engine, to_err};

pub const DRAFT_MSG: &str = "app.burumy.draft";

/// Longest draft that is shared (a device message stays far below 64 KB).
pub const MAX_DRAFT: usize = 8000;

/// Biggest saved sound (Telegram: 300 KB).
pub const MAX_BLOB: usize = 300 * 1024;

const DRAFTS_IN: &[u8] = b"burumy.drafts.in.v1";

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SyncedDraft {
    pub room_id: String,
    /// Empty = the draft was sent or cleared there.
    pub text: String,
    /// When it was typed there (ms since 1970).
    pub at: u64,
}

/// Keeps the newest per chat.
pub fn merge(list: &mut Vec<SyncedDraft>, d: SyncedDraft) {
    if let Some(old) = list.iter_mut().find(|x| x.room_id == d.room_id) {
        if d.at > old.at {
            *old = d;
        }
    } else {
        list.push(d);
    }
}

fn blob_key(name: &str) -> Vec<u8> {
    format!("burumy.blob.v1.{name}").into_bytes()
}

impl Engine {
    /// Sends my draft for [room_id] to my other devices. Nothing is sent
    /// when this is my only device.
    pub async fn send_my_draft(&self, room_id: &str, text: &str, at: u64) -> Result<bool> {
        let me = self.client.user_id().ok_or(anyhow::anyhow!("not logged in"))?.to_owned();
        let mine = self.device_id().unwrap_or_default();
        let devices = self.client.encryption().get_user_devices(&me).await.map_err(to_err)?;
        if !devices.devices().any(|d| d.device_id().as_str() != mine) {
            return Ok(false);
        }
        let text: String = text.chars().take(MAX_DRAFT).collect();
        let content = json!({ "room": room_id, "text": text, "at": at, "from": mine });
        self.send_private(me.as_str(), DRAFT_MSG, &content).await?;
        Ok(true)
    }

    /// A draft from one of my devices (called while syncing). Only from my
    /// own account, and never the one this device sent itself.
    pub(crate) async fn take_draft_message(&self, sender: &str, content: &serde_json::Value) -> Result<()> {
        let me = self.client.user_id().map(|u| u.to_string()).unwrap_or_default();
        ensure!(!me.is_empty() && sender == me, "not mine");
        if content["from"].as_str() == self.device_id().as_deref() {
            return Ok(());
        }
        let (Some(room), Some(text), Some(at)) = (content["room"].as_str(), content["text"].as_str(), content["at"].as_u64()) else {
            anyhow::bail!("bad draft");
        };
        ensure!(room.starts_with('!') && room.len() < 256, "bad room");
        let mut list = self.drafts_in().await;
        merge(&mut list, SyncedDraft { room_id: room.to_owned(), text: text.chars().take(MAX_DRAFT).collect(), at });
        self.client
            .state_store()
            .set_custom_value_no_read(DRAFTS_IN, serde_json::to_vec(&list)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    async fn drafts_in(&self) -> Vec<SyncedDraft> {
        self.client
            .state_store()
            .get_custom_value(DRAFTS_IN)
            .await
            .ok()
            .flatten()
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default()
    }

    /// Drafts my other devices sent since the last call (then forgotten
    /// here; the app keeps what it uses).
    pub async fn take_synced_drafts(&self) -> Result<Vec<SyncedDraft>> {
        let list = self.drafts_in().await;
        if !list.is_empty() {
            self.client.state_store().remove_custom_value(DRAFTS_IN).await.map_err(to_err)?;
        }
        Ok(list)
    }

    /// Checks only (examples/drafts.rs): an encrypted device message of any
    /// type to someone, to prove a stranger's "draft" is refused.
    #[doc(hidden)]
    pub async fn send_device_message_for_test(&self, user: &str, ty: &str, content: &serde_json::Value) -> Result<()> {
        self.send_private(user, ty, content).await
    }

    /// Keeps a small piece of data in the encrypted local store.
    pub async fn save_blob(&self, name: &str, data: &[u8]) -> Result<()> {
        ensure!(!name.is_empty() && name.len() <= 64 && name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '-'), "bad name");
        ensure!(data.len() <= MAX_BLOB, "too big");
        self.client.state_store().set_custom_value_no_read(&blob_key(name), data.to_vec()).await.map_err(to_err)?;
        Ok(())
    }

    pub async fn blob(&self, name: &str) -> Result<Option<Vec<u8>>> {
        self.client.state_store().get_custom_value(&blob_key(name)).await.map_err(to_err)
    }

    pub async fn drop_blob(&self, name: &str) -> Result<()> {
        self.client.state_store().remove_custom_value(&blob_key(name)).await.map_err(to_err)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn newest_draft_wins() {
        let mut l = vec![];
        merge(&mut l, SyncedDraft { room_id: "!a".into(), text: "new".into(), at: 20 });
        merge(&mut l, SyncedDraft { room_id: "!a".into(), text: "old".into(), at: 10 });
        merge(&mut l, SyncedDraft { room_id: "!b".into(), text: "".into(), at: 5 });
        assert_eq!(l.len(), 2);
        assert_eq!(l[0].text, "new");
        merge(&mut l, SyncedDraft { room_id: "!a".into(), text: "".into(), at: 30 });
        assert_eq!(l[0].text, "");
    }
}
