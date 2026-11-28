// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Hide and delete lists for the three-password lock.
//!
//! - Hide list: once a session is opened with the hide password, these
//!   people/chats disappear from every list (and stay hidden in later
//!   normal sessions) until released inside a hide-password session.
//! - Delete list: a session opened with the delete password erases them
//!   from this device only. 1:1 chats are left at once; groups and
//!   channels are left quietly much later, one at a time, so nobody sees
//!   a burst of "left" notices.
//!
//! The lists live in the encrypted local store (never on the server).
//! Quiet chats are muted on the server so no notification arrives.

use std::collections::BTreeMap;

use anyhow::{Context, Result};
use matrix_sdk::{
    notification_settings::RoomNotificationMode,
    ruma::{OwnedRoomId, RoomId},
};
use serde::{Deserialize, Serialize};

use crate::{Engine, lock::Role, to_err};

const KEY: &[u8] = b"burumy.quiet.v1";
const DAY_MS: u64 = 24 * 60 * 60 * 1000;

#[derive(Clone, Default, Serialize, Deserialize, Debug)]
pub struct QuietState {
    /// User ids (@..) or chat ids (!..) chosen for hiding.
    pub hide: Vec<String>,
    /// User ids or chat ids chosen for deleting.
    pub delete: Vec<String>,
    /// Hiding is switched on (by a hide-password session).
    pub hide_active: bool,
    /// Chats already erased from this device (never shown again).
    pub erased: Vec<String>,
    /// Groups/channels still to leave: chat id -> time (ms).
    pub leave_at: BTreeMap<String, u64>,
    /// People and chats known when hiding was switched on. While hiding is
    /// on, anyone else (strangers, new invitations) is kept quietly too
    /// and shows only in a hide-password session.
    #[serde(default)]
    pub known: Vec<String>,
    /// Friends (user ids) who deleted a 1:1 chat for both, not yet told.
    #[serde(default)]
    pub erase_notices: Vec<String>,
    /// Single messages chosen for deleting: "chat id event id".
    #[serde(default)]
    pub marked: Vec<String>,
    /// Messages already erased from this device: event ids (never shown).
    #[serde(default)]
    pub gone: Vec<String>,
    /// Single messages chosen for hiding: "chat id event id". Like hidden
    /// chats: out of sight once a hide-password session switched hiding on,
    /// back only when released inside a hide-password session (no extra
    /// password, no toggle, no timer).
    #[serde(default)]
    pub veiled: Vec<String>,
}

fn mark_key(room_id: &RoomId, event_id: &str) -> String {
    format!("{room_id} {event_id}")
}

/// Whether the friend's phone is asked to erase a 1:1 chat too.
#[derive(Clone, Copy, PartialEq, Eq)]
enum Tell {
    No,
    /// Erase there too, without telling the friend (delete password).
    Quietly,
    /// Erase there too and tell the friend.
    Yes,
}

/// Inside a 1:1 chat: "delete this chat on your phone too".
pub const ERASE_TYPE: &str = "im.securemessenger.erase";

fn now_ms() -> u64 {
    #[cfg(not(target_arch = "wasm32"))]
    {
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map(|d| d.as_millis() as u64)
            .unwrap_or(0)
    }
    #[cfg(target_arch = "wasm32")]
    {
        js_sys_now()
    }
}

#[cfg(target_arch = "wasm32")]
fn js_sys_now() -> u64 {
    matrix_sdk::ruma::MilliSecondsSinceUnixEpoch::now()
        .get()
        .into()
}

/// Spread in ms around a centre: centre ± spread.
fn jitter(centre: u64, spread: u64) -> u64 {
    use rand::Rng;
    centre - spread + rand::thread_rng().gen_range(0..=spread * 2)
}

impl Engine {
    pub async fn quiet_state(&self) -> Result<QuietState> {
        let raw = self
            .client
            .state_store()
            .get_custom_value(KEY)
            .await
            .map_err(to_err)?;
        Ok(raw
            .and_then(|r| serde_json::from_slice(&r).ok())
            .unwrap_or_default())
    }

    async fn save_quiet(&self, q: &QuietState) -> Result<()> {
        self.client
            .state_store()
            .set_custom_value_no_read(KEY, serde_json::to_vec(q)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Chooses who/what the hide and delete passwords act on.
    pub async fn set_quiet_lists(&self, hide: Vec<String>, delete: Vec<String>) -> Result<()> {
        let mut q = self.quiet_state().await?;
        q.hide = hide;
        q.delete = delete;
        self.save_quiet(&q).await
    }

    /// Marks (or unmarks) one message for the delete password.
    pub async fn mark_for_delete(&self, room_id: &RoomId, event_id: &str, on: bool) -> Result<()> {
        anyhow::ensure!(event_id.starts_with('$'), "not a message id");
        let key = mark_key(room_id, event_id);
        let mut q = self.quiet_state().await?;
        q.marked.retain(|m| *m != key);
        if on {
            q.marked.push(key);
        }
        self.save_quiet(&q).await
    }

    /// Marks (or unmarks) one message for the hide password.
    pub async fn mark_for_hide(&self, room_id: &RoomId, event_id: &str, on: bool) -> Result<()> {
        anyhow::ensure!(event_id.starts_with('$'), "not a message id");
        let key = mark_key(room_id, event_id);
        let mut q = self.quiet_state().await?;
        q.veiled.retain(|m| *m != key);
        if on {
            q.veiled.push(key);
        }
        self.save_quiet(&q).await
    }

    /// Event ids of this chat's messages marked for the hide password.
    pub async fn hide_marked_messages(&self, room_id: &RoomId) -> Result<Vec<String>> {
        let head = format!("{room_id} ");
        Ok(self
            .quiet_state()
            .await?
            .veiled
            .iter()
            .filter_map(|m| m.strip_prefix(&head).map(str::to_owned))
            .collect())
    }

    /// Event ids that must not be shown right now: erased ones, plus the
    /// messages chosen for hiding while hiding is on (outside a
    /// hide-password session).
    pub(crate) fn unseen(&self, q: &QuietState) -> Vec<String> {
        let mut out = q.gone.clone();
        if q.hide_active && self.session_role() != Role::Hide {
            out.extend(q.veiled.iter().filter_map(|k| k.split_once(' ').map(|(_, e)| e.to_owned())));
        }
        out
    }

    /// Event ids of this chat's messages marked for the delete password.
    pub async fn marked_messages(&self, room_id: &RoomId) -> Result<Vec<String>> {
        let head = format!("{room_id} ");
        Ok(self
            .quiet_state()
            .await?
            .marked
            .iter()
            .filter_map(|m| m.strip_prefix(&head).map(str::to_owned))
            .collect())
    }

    /// Delete password: marked messages go. Mine are deleted for everyone;
    /// other people's vanish from this device.
    async fn erase_marked(&self, q: &mut QuietState) {
        let me = self.client.user_id().map(|u| u.to_owned());
        for key in std::mem::take(&mut q.marked) {
            let Some((rid, eid)) = key.split_once(' ') else {
                continue;
            };
            if let (Ok(room_id), Ok(event_id)) =
                (RoomId::parse(rid), matrix_sdk::ruma::EventId::parse(eid))
            {
                if let Some(room) = self.client.get_room(&room_id) {
                    let mine = match room.event(&event_id, None).await {
                        Ok(ev) => ev
                            .raw()
                            .deserialize()
                            .ok()
                            .map(|e| Some(e.sender().to_owned()) == me)
                            .unwrap_or(false),
                        Err(_) => false,
                    };
                    if mine {
                        let _ = room.redact(&event_id, None, None).await;
                    }
                }
            }
            if !q.gone.iter().any(|g| g == eid) {
                q.gone.push(eid.to_owned());
            }
        }
    }

    pub fn session_role(&self) -> Role {
        self.role.lock().map(|r| *r).unwrap_or(Role::Normal)
    }

    /// Called right after the app lock opens, with the password's role.
    pub async fn start_session(&self, role: Role) -> Result<()> {
        if let Ok(mut r) = self.role.lock() {
            *r = role;
        }
        let mut q = self.quiet_state().await?;
        match role {
            Role::Normal => {}
            Role::Hide => {
                if !q.hide_active {
                    q.hide_active = true;
                    q.known = self.known_now().await;
                    self.save_quiet(&q).await?;
                }
                for room in self.rooms_for(&q.hide).await {
                    let _ = self.mute(&room, true).await;
                }
            }
            Role::Delete => self.erase(&mut q).await?,
            // The app erases the chosen accounts itself; this one opens as usual.
            Role::Account => {}
        }
        Ok(())
    }

    /// Shows hidden people again. Only inside a hide-password session.
    pub async fn release_hidden(&self) -> Result<()> {
        anyhow::ensure!(self.session_role() == Role::Hide, "only in a hide session");
        let mut q = self.quiet_state().await?;
        q.hide_active = false;
        q.known.clear();
        self.save_quiet(&q).await?;
        for room in self.rooms_for(&q.hide).await {
            let _ = self.mute(&room, false).await;
        }
        Ok(())
    }

    /// Joined chats and their 1:1 partners right now.
    async fn known_now(&self) -> Vec<String> {
        let mut out = Vec::new();
        for room in self.client.joined_rooms() {
            out.push(room.room_id().to_string());
            if room.is_direct().await.unwrap_or(false) {
                out.extend(
                    room.direct_targets()
                        .iter()
                        .filter_map(|t| t.as_user_id().map(|u| u.to_string())),
                );
            }
        }
        out
    }

    /// Chats that the user ids / chat ids point to (1:1 chats for people).
    async fn rooms_for(&self, ids: &[String]) -> Vec<OwnedRoomId> {
        let mut out = Vec::new();
        for room in self
            .client
            .joined_rooms()
            .into_iter()
            .chain(self.client.invited_rooms())
        {
            let rid = room.room_id().to_string();
            let partner = if room.is_direct().await.unwrap_or(false) {
                room.direct_targets()
                    .iter()
                    .filter_map(|t| t.as_user_id().map(|u| u.to_string()))
                    .collect::<Vec<_>>()
            } else {
                vec![]
            };
            if ids.iter().any(|i| *i == rid || partner.contains(i)) {
                out.push(room.room_id().to_owned());
            }
        }
        out
    }

    async fn mute(&self, room: &RoomId, on: bool) -> Result<()> {
        let ns = self.client.notification_settings().await;
        if on {
            ns.set_room_notification_mode(room, RoomNotificationMode::Mute)
                .await
                .map_err(to_err)?;
        } else {
            ns.delete_user_defined_room_rules(room)
                .await
                .map_err(to_err)?;
        }
        Ok(())
    }

    /// True when this chat (or its 1:1 partner) must not be shown now.
    pub(crate) async fn is_quiet(&self, room_id: &RoomId, q: &QuietState) -> bool {
        let rid = room_id.to_string();
        if q.erased.contains(&rid) {
            return true;
        }
        if !q.hide_active || self.session_role() == Role::Hide {
            return false;
        }
        if q.hide.contains(&rid) {
            return true;
        }
        let Some(room) = self.client.get_room(room_id) else {
            return false;
        };
        let partners: Vec<String> = room
            .direct_targets()
            .iter()
            .filter_map(|t| t.as_user_id().map(|u| u.to_string()))
            .collect();
        if partners.iter().any(|u| q.hide.contains(u)) {
            return true;
        }
        // Strangers: a chat that is new since hiding started, with nobody known.
        !q.known.is_empty()
            && !q.known.contains(&rid)
            && !partners.iter().any(|u| q.known.contains(u))
    }

    pub(crate) fn is_quiet_user(&self, user_id: &str, q: &QuietState) -> bool {
        (q.hide_active && self.session_role() != Role::Hide && q.hide.contains(&user_id.to_owned()))
            || q.delete.contains(&user_id.to_owned()) && !q.erased.is_empty()
    }

    /// An invitation from someone unknown while hiding is on: kept waiting
    /// quietly (shown in a hide-password session).
    pub(crate) fn is_stranger(&self, user_id: &str, q: &QuietState) -> bool {
        q.hide_active
            && self.session_role() != Role::Hide
            && !q.known.is_empty()
            && !q.known.contains(&user_id.to_owned())
    }

    /// Erases the delete list from this device.
    async fn erase(&self, q: &mut QuietState) -> Result<()> {
        self.erase_marked(q).await;
        let rooms = self.rooms_for(&q.delete).await;
        // 1:1 chats go on both sides, but quietly (the friend is not told).
        self.erase_rooms(q, rooms, Tell::Quietly).await
    }

    /// Erases chats from this device. 1:1 chats are left at once and, when
    /// `tell` is on, the friend's phone is asked to erase its copy too.
    /// Groups/channels are left later, quietly: first ~14 days (±2) from
    /// now, then ~2 days (±6 hours) apart, after any already planned.
    async fn erase_rooms(
        &self,
        q: &mut QuietState,
        rooms: Vec<OwnedRoomId>,
        tell: Tell,
    ) -> Result<()> {
        let backup_version = self.backup_version().await;
        let mut next = q
            .leave_at
            .values()
            .max()
            .map(|t| t + jitter(2 * DAY_MS, DAY_MS / 4))
            .unwrap_or(0)
            .max(now_ms() + jitter(14 * DAY_MS, 2 * DAY_MS));
        for room_id in rooms {
            let rid = room_id.to_string();
            if q.erased.contains(&rid) {
                continue;
            }
            let direct = match self.client.get_room(&room_id) {
                Some(r) => r.is_direct().await.unwrap_or(false),
                None => false,
            };
            if direct && tell != Tell::No {
                if let Some(r) = self.client.get_room(&room_id) {
                    // Only inside the encrypted chat.
                    if r.latest_encryption_state()
                        .await
                        .map(|e| e.is_encrypted())
                        .unwrap_or(false)
                    {
                        let _ = r.send_raw(ERASE_TYPE, serde_json::json!({ "scope": "chat", "quiet": tell == Tell::Quietly })).await;
                    }
                }
            }
            let _ = self.mute(&room_id, true).await;
            // Local copy of the messages.
            if let Ok(state) = self.client.event_cache_store().lock().await {
                let (matrix_sdk::cross_process_lock::MappedCrossProcessLockState::Clean(g)
                | matrix_sdk::cross_process_lock::MappedCrossProcessLockState::Dirty(g)) = state;
                let _ = g.clear_all_events(Some(&room_id)).await;
            }
            // Keys for this chat in the server key backup.
            if let Some(v) = &backup_version {
                use matrix_sdk::ruma::api::client::backup::delete_backup_keys_for_room::v3::Request;
                let _ = self
                    .client
                    .send(Request::new(v.clone(), room_id.clone()))
                    .await;
            }
            if direct {
                if let Some(r) = self.client.get_room(&room_id) {
                    let _ = r.leave().await;
                    let _ = r.forget().await;
                }
            } else {
                q.leave_at.insert(rid.clone(), next);
                next += jitter(2 * DAY_MS, DAY_MS / 4);
            }
            q.erased.push(rid);
        }
        self.save_quiet(q).await
    }

    /// Too many wrong app-lock tries: erases every chat on this phone (1:1
    /// chats on both sides), the same way the delete password does.
    pub async fn erase_everything(&self) -> Result<()> {
        let mut q = self.quiet_state().await?;
        let rooms: Vec<OwnedRoomId> = self
            .client
            .joined_rooms()
            .into_iter()
            .chain(self.client.invited_rooms())
            .map(|r| r.room_id().to_owned())
            .collect();
        self.erase_rooms(&mut q, rooms, Tell::Yes).await
    }

    /// Deletes a 1:1 chat for both people.
    pub async fn delete_for_both(&self, room_id: &RoomId) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(room.is_direct().await.unwrap_or(false), "1:1 chats only");
        let mut q = self.quiet_state().await?;
        self.erase_rooms(&mut q, vec![room_id.to_owned()], Tell::Yes)
            .await
    }

    /// The friend deleted our 1:1 chat for both: erase my copy too (only
    /// for requests that came end-to-end encrypted from the other person).
    pub(crate) async fn on_erase_requests(&self, rooms: &matrix_sdk::sync::RoomUpdates) {
        let Some(me) = self.client.user_id().map(|u| u.to_string()) else {
            return;
        };
        let mut asked = vec![];
        for (room_id, upd) in &rooms.joined {
            for ev in &upd.timeline.events {
                if matches!(ev.kind, crate::TimelineEventKind::PlainText { .. }) {
                    continue;
                }
                let Ok(v) = serde_json::from_str::<serde_json::Value>(ev.raw().json().get()) else {
                    continue;
                };
                if v["type"].as_str() == Some(ERASE_TYPE)
                    && v["sender"].as_str().is_some_and(|s| s != me)
                {
                    let quiet = v["content"]["quiet"].as_bool() == Some(true);
                    asked.push((
                        room_id.clone(),
                        v["sender"].as_str().unwrap_or_default().to_owned(),
                        quiet,
                    ));
                    break;
                }
            }
        }
        if asked.is_empty() {
            return;
        }
        let Ok(mut q) = self.quiet_state().await else {
            return;
        };
        let mut direct = vec![];
        for (r, who, quiet) in asked {
            match self.client.get_room(&r) {
                Some(room) if room.is_direct().await.unwrap_or(false) => {}
                _ => continue,
            }
            if !quiet {
                q.erase_notices.push(who);
            }
            direct.push(r);
        }
        let _ = self.erase_rooms(&mut q, direct, Tell::No).await;
    }

    /// User ids of friends who deleted a 1:1 chat for both (shown once).
    pub async fn take_erase_notices(&self) -> Result<Vec<String>> {
        let mut q = self.quiet_state().await?;
        let out = std::mem::take(&mut q.erase_notices);
        if !out.is_empty() {
            self.save_quiet(&q).await?;
        }
        Ok(out)
    }

    async fn backup_version(&self) -> Option<String> {
        use matrix_sdk::ruma::api::client::backup::get_latest_backup_info::v3::Request;
        self.client
            .send(Request::new())
            .await
            .ok()
            .map(|r| r.version)
    }

    /// Leaves at most one erased group whose time has come. Call on start
    /// and now and then. Returns the chat left, if any.
    pub async fn run_due_leaves(&self) -> Result<Option<String>> {
        let mut q = self.quiet_state().await?;
        let now = now_ms();
        let Some((rid, _)) = q
            .leave_at
            .iter()
            .find(|(_, t)| **t <= now)
            .map(|(a, b)| (a.clone(), *b))
        else {
            return Ok(None);
        };
        let room_id = RoomId::parse(&rid)?;
        let room = self.client.get_room(&room_id).context("unknown room")?;
        room.leave().await.map_err(to_err)?;
        let _ = room.forget().await;
        q.leave_at.remove(&rid);
        self.save_quiet(&q).await?;
        Ok(Some(rid))
    }

    /// Test builds only: bring every planned leave forward to now.
    pub async fn leave_now_for_test(&self) -> Result<()> {
        let mut q = self.quiet_state().await?;
        for t in q.leave_at.values_mut() {
            *t = 0;
        }
        self.save_quiet(&q).await
    }
}
