// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 커뮤니티: several groups and channels linked together, so members see
//! and join the other chats from one place (Eric 2026-11-27, after
//! Telegram's Communities). Our own design, keeping the server blind:
//!
//! - A community is a hidden room of its own (never shown as a chat). Its
//!   members are the community's members.
//! - Which chats belong to it, and its name, live in that room's state but
//!   sealed with a community key (XChaCha20-Poly1305). The server stores
//!   only ciphertext under random slot names, so it never learns which
//!   groups and channels are linked, or what the community is called.
//! - Chats the admins hide are sealed with a second key only admins hold.
//! - Keys travel only as end-to-end encrypted device messages: to my other
//!   phones when I make one, and from admin phones to each new member.
//! - "Who may add chats" is the room's power level for the slot event,
//!   so the server itself refuses members when only admins may add.
//! - Admin phones share one duty: members of linked chats who are not in
//!   the community yet get an invite plus the key (their phone then joins
//!   on its own). Nobody has to accept anything by hand.
use std::collections::{BTreeMap, BTreeSet, HashMap};

use anyhow::{Context, Result, bail, ensure};
use base64::Engine as _;
use chacha20poly1305::{
    Key as ChachaKey, KeyInit, XChaCha20Poly1305, XNonce,
    aead::{Aead, Payload},
};
use matrix_sdk::ruma::{OwnedRoomId, RoomId, UserId};
use rand::RngCore;
use serde_json::{Value, json};

use crate::{Engine, to_err};

/// Creation mark of a community room (the server sees only "this is a
/// community", never what is in it).
pub const MARK: &str = "app.burumy.community";
/// One linked chat (state key = random slot name).
pub const CHAT: &str = "app.burumy.community_chat";
/// Name and about (state key "").
pub const INFO: &str = "app.burumy.community_info";
/// Device message carrying the keys.
pub const KEY_MSG: &str = "app.burumy.community_key";
const STORE: &[u8] = b"burumy.community.v1";
/// Most chats in one community (Telegram allows 100 groups too).
pub const MAX_CHATS: usize = 100;
/// New members invited per community per round (admin duty).
const INVITES_PER_ROUND: usize = 20;
/// How often an admin phone looks for new members (ms).
const DUTY_EVERY_MS: u64 = 10 * 60 * 1000;

#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize)]
#[serde(default)]
pub struct Keys {
    /// Community key (base64, 32 bytes).
    pub k: String,
    /// Admin key ("" when I am not an admin).
    pub a: String,
    /// Who gave them to me ("" = I made the community).
    pub from: String,
}

#[derive(Clone, Debug, Default, serde::Serialize, serde::Deserialize)]
#[serde(default)]
struct Book {
    keys: BTreeMap<String, Keys>,
    /// "community|user" admins I already gave the admin key.
    sent_admin: BTreeSet<String>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct CommunityChat {
    pub room_id: String,
    pub name: String,
    /// "group" or "channel".
    pub kind: String,
    /// "in" (I am a member), "view" (open: one tap joins) or "ask"
    /// (approval needed).
    pub state: String,
    /// Only admins see it.
    pub hidden: bool,
    /// Who added it.
    pub by: String,
    /// Members when it was added (0 = unknown).
    pub members: u64,
    pub(crate) link_kind: String,
    pub(crate) code: String,
}

#[derive(Clone, Debug, PartialEq)]
pub struct Community {
    pub id: String,
    pub name: String,
    pub about: String,
    /// "owner", "admin" or "member".
    pub role: String,
    /// Every member may add their own groups and channels (else admins only).
    pub add_all: bool,
    pub chats: Vec<CommunityChat>,
    /// People in the community.
    pub members: u64,
}

// ---- sealing (pure, tested below) ----

fn b64() -> base64::engine::GeneralPurpose {
    base64::engine::general_purpose::STANDARD
}

pub fn new_key() -> String {
    let mut k = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut k);
    b64().encode(k)
}

fn key_bytes(key: &str) -> Option<[u8; 32]> {
    b64().decode(key).ok()?.try_into().ok()
}

/// Seals `plain` for one place (community + slot): moving a sealed value
/// to another slot or community makes it unreadable.
pub fn seal(key: &str, place: &str, plain: &[u8]) -> Result<String> {
    let k = key_bytes(key).context("bad key")?;
    let cipher = XChaCha20Poly1305::new(ChachaKey::cast_from_core(&k));
    let mut nonce = [0u8; 24];
    rand::thread_rng().fill_bytes(&mut nonce);
    let ct = cipher
        .encrypt(XNonce::cast_from_core(&nonce), Payload { msg: plain, aad: place.as_bytes() })
        .map_err(|_| anyhow::anyhow!("seal failed"))?;
    let mut out = nonce.to_vec();
    out.extend(ct);
    Ok(b64().encode(out))
}

pub fn open(key: &str, place: &str, sealed: &str) -> Option<Vec<u8>> {
    let k = key_bytes(key)?;
    let raw = b64().decode(sealed).ok()?;
    if raw.len() < 24 + 16 || raw.len() > 64 * 1024 {
        return None;
    }
    let (nonce, ct) = raw.split_at(24);
    let nonce: [u8; 24] = nonce.try_into().ok()?;
    let cipher = XChaCha20Poly1305::new(ChachaKey::cast_from_core(&k));
    cipher
        .decrypt(XNonce::cast_from_core(&nonce), Payload { msg: ct, aad: place.as_bytes() })
        .ok()
}

fn place(community: &str, slot: &str) -> String {
    format!("{community}|{slot}")
}

fn clip(v: &Value, max: usize) -> String {
    v.as_str().unwrap_or_default().trim().chars().take(max).collect()
}

/// A linked chat as written in a slot (checked; None when broken).
pub fn check_entry(v: &Value) -> Option<Value> {
    let room = v["room"].as_str()?;
    RoomId::parse(room).ok()?;
    let by = v["by"].as_str()?;
    UserId::parse(by).ok()?;
    let kind = match v["kind"].as_str()? {
        "group" => "group",
        "channel" => "channel",
        _ => return None,
    };
    let name = clip(&v["name"], 128);
    if name.is_empty() {
        return None;
    }
    let lk = match v["link"]["kind"].as_str().unwrap_or("none") {
        "public" => "public",
        "private" => "private",
        _ => "none",
    };
    let code = clip(&v["link"]["code"], 64);
    if lk != "none" && (code.is_empty() || !code.bytes().all(|b| b.is_ascii_alphanumeric() || b == b'_' || b == b'-')) {
        return None;
    }
    Some(json!({
        "room": room, "by": by, "kind": kind, "name": name,
        "link": { "kind": lk, "code": code, "approval": v["link"]["approval"].as_bool().unwrap_or(false) },
        "members": v["members"].as_u64().unwrap_or(0).min(100_000_000),
    }))
}

/// Who may keep a slot: admins always; a member only for an entry they
/// wrote themselves, and only while everyone may add.
pub fn entry_allowed(sender: &str, sender_level: i64, add_all: bool, by: &str) -> bool {
    sender_level >= 50 || (add_all && sender == by)
}

/// Slot names are random, so they say nothing about the chat.
fn new_slot() -> String {
    let mut b = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut b);
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn raw_json(raw: &matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState) -> Value {
    let s = match raw {
        matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get(),
        matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => r.json().get(),
    };
    serde_json::from_str(s).unwrap_or(Value::Null)
}

fn level_of(pl: &matrix_sdk::ruma::events::room::power_levels::RoomPowerLevels, user: &UserId) -> i64 {
    use matrix_sdk::ruma::events::room::power_levels::UserPowerLevel;
    match pl.for_user(user) {
        UserPowerLevel::Infinite => 100,
        UserPowerLevel::Int(i) => i.into(),
        _ => 0,
    }
}

fn state_of_opt(raw: Option<matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState>) -> Value {
    raw.map(|r| raw_json(&r)["content"].clone()).unwrap_or(Value::Null)
}

/// One slot read from the room: (slot, sender, sealed, hidden).
struct Slot {
    slot: String,
    sender: String,
    sealed: String,
    hidden: bool,
}

impl Engine {
    async fn community_book(&self) -> Book {
        match self.client.state_store().get_custom_value(STORE).await {
            Ok(Some(b)) => serde_json::from_slice(&b).unwrap_or_default(),
            _ => Book::default(),
        }
    }

    async fn save_community_book(&self, b: &Book) -> Result<()> {
        self.client
            .state_store()
            .set_custom_value_no_read(STORE, serde_json::to_vec(b)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// True when this room is a community (made with our mark).
    pub async fn is_community(&self, room_id: &RoomId) -> bool {
        // A room's creation never changes: remember the answer.
        if let Some(v) = self.community_kind.lock().unwrap().get(room_id.as_str()) {
            return *v;
        }
        let Some(v) = self.read_is_community(room_id).await else {
            return false; // not known yet: ask again next time
        };
        self.community_kind.lock().unwrap().insert(room_id.to_string(), v);
        v
    }

    async fn read_is_community(&self, room_id: &RoomId) -> Option<bool> {
        let room = self.client.get_room(room_id)?;
        let raw = room
            .get_state_event_static::<matrix_sdk::ruma::events::room::create::RoomCreateEventContent>()
            .await;
        let s = match raw {
            Ok(Some(matrix_sdk::deserialized_responses::RawSyncOrStrippedState::Sync(r))) => r.json().get().to_owned(),
            Ok(Some(matrix_sdk::deserialized_responses::RawSyncOrStrippedState::Stripped(r))) => r.json().get().to_owned(),
            _ => return None,
        };
        Some(serde_json::from_str::<Value>(&s).is_ok_and(|v| v["content"][MARK].as_bool() == Some(true)))
    }

    /// Makes a community; I am its owner. Returns its id.
    pub async fn create_community(&self, name: &str, about: &str) -> Result<OwnedRoomId> {
        use matrix_sdk::ruma::{
            api::client::room::create_room::v3::{CreationContent, Request as CreateRoom, RoomPreset},
            events::{InitialStateEvent, room::encryption::RoomEncryptionEventContent},
            serde::Raw,
        };
        let name: String = name.trim().chars().take(64).collect();
        ensure!(!name.is_empty(), "empty name");
        let mut req = CreateRoom::new();
        req.preset = Some(RoomPreset::PrivateChat);
        req.initial_state = vec![
            Raw::new(&InitialStateEvent::new(Default::default(), RoomEncryptionEventContent::with_recommended_defaults()))?.cast(),
        ];
        req.creation_content = Some(Raw::<CreationContent>::from_json_string(
            json!({ MARK: true, "type": MARK }).to_string(),
        )?);
        // Nobody chats in a community room; only admins change it, and by
        // default only admins add chats.
        req.power_level_content_override = Some(Raw::from_json_string(
            json!({ "events_default": 50, "state_default": 50, "invite": 50, "events": { CHAT: 50 } }).to_string(),
        )?);
        let room = self.client.create_room(req).await.map_err(to_err)?;
        let id = room.room_id().to_owned();
        let keys = Keys { k: new_key(), a: new_key(), from: String::new() };
        let mut book = self.community_book().await;
        book.keys.insert(id.to_string(), keys.clone());
        self.save_community_book(&book).await?;
        self.write_info(&id, &keys.k, &name, about).await?;
        // My other phones get the keys too (best effort).
        if let Some(me) = self.client.user_id().map(|u| u.to_string()) {
            let _ = self
                .send_private(&me, KEY_MSG, &json!({ "community": id.as_str(), "k": keys.k, "a": keys.a }))
                .await;
        }
        Ok(id)
    }

    async fn write_info(&self, id: &RoomId, k: &str, name: &str, about: &str) -> Result<()> {
        let room = self.client.get_room(id).context("unknown community")?;
        let name: String = name.trim().chars().take(64).collect();
        ensure!(!name.is_empty(), "empty name");
        let about: String = about.trim().chars().take(255).collect();
        let plain = json!({ "name": name, "about": about }).to_string();
        let c = seal(k, &place(id.as_str(), ""), plain.as_bytes())?;
        room.send_state_event_raw(INFO, "", json!({ "c": c })).await.map_err(to_err)?;
        Ok(())
    }

    /// Changes the name and about (admins).
    pub async fn set_community_info(&self, id: &RoomId, name: &str, about: &str) -> Result<()> {
        let keys = self.community_keys(id).await.context("no key")?;
        self.write_info(id, &keys.k, name, about).await
    }

    pub async fn community_keys(&self, id: &RoomId) -> Option<Keys> {
        self.community_book().await.keys.get(id.as_str()).cloned().filter(|k| !k.k.is_empty())
    }

    async fn slots(&self, room: &matrix_sdk::Room) -> Vec<Slot> {
        let Ok(list) = room.get_state_events(CHAT.into()).await else {
            return vec![];
        };
        list.iter()
            .filter_map(|r| {
                let v = raw_json(r);
                Some(Slot {
                    slot: v["state_key"].as_str()?.to_owned(),
                    sender: v["sender"].as_str()?.to_owned(),
                    sealed: v["content"]["c"].as_str()?.to_owned(),
                    hidden: v["content"]["h"].as_bool().unwrap_or(false),
                })
            })
            .collect()
    }

    /// Every community I am in, with the chats I may see.
    pub async fn communities(&self) -> Vec<Community> {
        let book = self.community_book().await;
        let me = self.client.user_id().map(|u| u.to_owned());
        let joined: BTreeSet<String> = self.client.joined_rooms().iter().map(|r| r.room_id().to_string()).collect();
        let mut out = vec![];
        for room in self.client.joined_rooms() {
            if !self.is_community(room.room_id()).await {
                continue;
            }
            let id = room.room_id().to_string();
            let Some(keys) = book.keys.get(&id).filter(|k| !k.k.is_empty()) else {
                continue;
            };
            let Some(c) = self.read_community(&room, keys, me.as_deref(), &joined).await else {
                continue;
            };
            out.push(c);
        }
        out.sort_by(|a, b| a.name.cmp(&b.name));
        out
    }

    async fn read_community(
        &self,
        room: &matrix_sdk::Room,
        keys: &Keys,
        me: Option<&UserId>,
        joined: &BTreeSet<String>,
    ) -> Option<Community> {
        let id = room.room_id().to_string();
        let info = state_of_opt(room.get_state_event(INFO.into(), "").await.ok().flatten());
        let plain = open(&keys.k, &place(&id, ""), info["c"].as_str()?)?;
        let info: Value = serde_json::from_slice(&plain).ok()?;
        let name = clip(&info["name"], 64);
        if name.is_empty() {
            return None; // deleted
        }
        let pl = room.power_levels().await.ok()?;
        let my_level = me.map(|m| level_of(&pl, m)).unwrap_or(0);
        let add_all = pl
            .events
            .get(&CHAT.into())
            .map(|l| i64::from(*l) <= 0)
            .unwrap_or(false);
        let mut seen = BTreeSet::new();
        let mut chats = vec![];
        for s in self.slots(room).await {
            let key = if s.hidden { &keys.a } else { &keys.k };
            if key.is_empty() {
                continue;
            }
            let Some(plain) = open(key, &place(&id, &s.slot), &s.sealed) else {
                continue;
            };
            let Some(e) = serde_json::from_slice::<Value>(&plain).ok().and_then(|v| check_entry(&v)) else {
                continue;
            };
            let sender_level = UserId::parse(s.sender.as_str()).map(|u| level_of(&pl, &u)).unwrap_or(0);
            let by = e["by"].as_str().unwrap_or_default().to_owned();
            if !entry_allowed(&s.sender, sender_level, add_all, &by) {
                continue;
            }
            let rid = e["room"].as_str().unwrap_or_default().to_owned();
            if !seen.insert(rid.clone()) {
                continue;
            }
            let approval = e["link"]["approval"].as_bool().unwrap_or(false);
            let link_kind = e["link"]["kind"].as_str().unwrap_or("none").to_owned();
            let state = if joined.contains(&rid) {
                "in"
            } else if !approval && link_kind != "none" {
                "view"
            } else {
                "ask"
            };
            chats.push(CommunityChat {
                room_id: rid,
                name: e["name"].as_str().unwrap_or_default().to_owned(),
                kind: e["kind"].as_str().unwrap_or("group").to_owned(),
                state: state.into(),
                hidden: s.hidden,
                by,
                members: e["members"].as_u64().unwrap_or(0),
                link_kind,
                code: e["link"]["code"].as_str().unwrap_or_default().to_owned(),
            });
        }
        chats.truncate(MAX_CHATS);
        Some(Community {
            id,
            name,
            about: clip(&info["about"], 255),
            role: match my_level {
                100.. => "owner",
                50.. => "admin",
                _ => "member",
            }
            .into(),
            add_all,
            chats,
            members: room.joined_members_count(),
        })
    }

    async fn find_slot(&self, room: &matrix_sdk::Room, keys: &Keys, chat: &str) -> Option<(String, Value, bool)> {
        let id = room.room_id().to_string();
        for s in self.slots(room).await {
            let key = if s.hidden { &keys.a } else { &keys.k };
            let Some(plain) = open(key, &place(&id, &s.slot), &s.sealed) else {
                continue;
            };
            if let Some(e) = serde_json::from_slice::<Value>(&plain).ok().and_then(|v| check_entry(&v)) {
                if e["room"].as_str() == Some(chat) {
                    return Some((s.slot, e, s.hidden));
                }
            }
        }
        None
    }

    /// Adds one of my groups or channels (I must be its owner or admin).
    /// A chat without a link gets a private link with approval, so
    /// community members can ask to come in. A line in the chat says it.
    pub async fn add_to_community(&self, id: &RoomId, chat: &RoomId, hidden: bool) -> Result<()> {
        let keys = self.community_keys(id).await.context("no key")?;
        let room = self.client.get_room(id).context("unknown community")?;
        ensure!(!self.is_community(chat).await, "not a chat");
        let role = self.my_role(chat).await?;
        ensure!(role == "owner" || role == "admin", "only your own groups and channels");
        let c = self.client.get_room(chat).context("unknown chat")?;
        ensure!(!c.is_direct().await.unwrap_or(false), "not a 1:1");
        let me = self.client.user_id().context("no user")?.to_string();
        if hidden {
            ensure!(!keys.a.is_empty(), "admins only");
        }
        let existing = self.find_slot(&room, &keys, chat.as_str()).await;
        if existing.is_none() {
            ensure!(self.slots(&room).await.len() < MAX_CHATS, "this community is full");
        }
        let mut link = self.room_link(chat).await;
        if link.kind == "none" {
            link = self.new_private_link(chat).await?;
            self.set_link_approval(chat, true).await?;
            link.approval = true;
        }
        let name = c.display_name().await.map(|n| n.to_string()).unwrap_or_default();
        let kind = if self.is_channel(chat).await { "channel" } else { "group" };
        let entry = json!({
            "room": chat.as_str(), "by": me, "kind": kind, "name": name,
            "link": { "kind": link.kind, "code": link.code, "approval": link.approval },
            "members": c.joined_members_count(),
        });
        let entry = check_entry(&entry).context("bad chat")?;
        let slot = existing.map(|(s, _, _)| s).unwrap_or_else(new_slot);
        self.write_slot(&room, &keys, &slot, &entry, hidden).await?;
        // Its members get the community on my next sync.
        self.community_rounds_now();
        if !hidden {
            let cname = self.communities().await.into_iter().find(|x| x.id == id.as_str()).map(|x| x.name).unwrap_or_default();
            let _ = self
                .create_card(chat, "community", &json!({ "community": id.as_str(), "name": cname, "kind": kind }).to_string())
                .await;
        }
        Ok(())
    }

    async fn write_slot(&self, room: &matrix_sdk::Room, keys: &Keys, slot: &str, entry: &Value, hidden: bool) -> Result<()> {
        let key = if hidden { &keys.a } else { &keys.k };
        let c = seal(key, &place(room.room_id().as_str(), slot), entry.to_string().as_bytes())?;
        let mut content = json!({ "c": c });
        if hidden {
            content["h"] = true.into();
        }
        room.send_state_event_raw(CHAT, slot, content).await.map_err(to_err)?;
        Ok(())
    }

    /// Takes a chat out (admins, or whoever added it).
    pub async fn remove_from_community(&self, id: &RoomId, chat: &str) -> Result<()> {
        let keys = self.community_keys(id).await.context("no key")?;
        let room = self.client.get_room(id).context("unknown community")?;
        let (slot, _, _) = self.find_slot(&room, &keys, chat).await.context("not in this community")?;
        room.send_state_event_raw(CHAT, &slot, json!({})).await.map_err(to_err)?;
        Ok(())
    }

    /// Hides a chat from members (only admins see it) or shows it again.
    pub async fn set_community_chat_hidden(&self, id: &RoomId, chat: &str, hidden: bool) -> Result<()> {
        let keys = self.community_keys(id).await.context("no key")?;
        ensure!(!keys.a.is_empty(), "admins only");
        let room = self.client.get_room(id).context("unknown community")?;
        let (slot, entry, _) = self.find_slot(&room, &keys, chat).await.context("not in this community")?;
        self.write_slot(&room, &keys, &slot, &entry, hidden).await
    }

    /// Everyone may add their own chats, or only admins (the server
    /// enforces it through the room's power levels).
    pub async fn set_community_add_all(&self, id: &RoomId, all: bool) -> Result<()> {
        let room = self.client.get_room(id).context("unknown community")?;
        let raw = room.get_state_event("m.room.power_levels".into(), "").await.map_err(to_err)?;
        let mut pl = state_of_opt(raw);
        ensure!(pl.is_object(), "no power levels");
        if !pl["events"].is_object() {
            pl["events"] = json!({});
        }
        pl["events"][CHAT] = if all { 0 } else { 50 }.into();
        room.send_state_event_raw("m.room.power_levels", "", pl).await.map_err(to_err)?;
        Ok(())
    }

    /// Makes someone a community admin (they get the admin key) or not.
    pub async fn set_community_admin(&self, id: &RoomId, user: &str, on: bool) -> Result<()> {
        let keys = self.community_keys(id).await.context("no key")?;
        self.set_member_level(id, user, if on { 50 } else { 0 }).await?;
        if on && !keys.a.is_empty() {
            self.send_private(user, KEY_MSG, &json!({ "community": id.as_str(), "k": keys.k, "a": keys.a })).await?;
            let mut book = self.community_book().await;
            book.sent_admin.insert(format!("{id}|{user}"));
            self.save_community_book(&book).await?;
        }
        Ok(())
    }

    /// Comes into one of the community's chats. Returns the chat id and
    /// whether it only asked (approval needed).
    pub async fn join_community_chat(&self, id: &RoomId, chat: &str) -> Result<(String, bool)> {
        let c = self
            .communities()
            .await
            .into_iter()
            .find(|c| c.id == id.as_str())
            .context("unknown community")?;
        let e = c.chats.into_iter().find(|x| x.room_id == chat).context("not in this community")?;
        match e.link_kind.as_str() {
            "public" | "private" => self.join_link(&e.link_kind, &e.code).await,
            _ => {
                let rid = RoomId::parse(chat)?;
                let room = self.client.knock(rid.to_owned().into(), None, vec![]).await.map_err(to_err)?;
                Ok((room.room_id().to_string(), true))
            }
        }
    }

    /// Leaves a community (my chats stay; it just stops showing).
    pub async fn leave_community(&self, id: &RoomId) -> Result<()> {
        if let Some(room) = self.client.get_room(id) {
            room.leave().await.map_err(to_err)?;
        }
        let mut book = self.community_book().await;
        book.keys.remove(id.as_str());
        self.save_community_book(&book).await
    }

    /// Owner: empties the community (every slot and the name) and leaves.
    /// Members' phones then see it gone and leave too.
    pub async fn delete_community(&self, id: &RoomId) -> Result<()> {
        ensure!(self.my_role(id).await? == "owner", "owner only");
        let room = self.client.get_room(id).context("unknown community")?;
        for s in self.slots(&room).await {
            room.send_state_event_raw(CHAT, &s.slot, json!({})).await.map_err(to_err)?;
        }
        room.send_state_event_raw(INFO, "", json!({})).await.map_err(to_err)?;
        self.leave_community(id).await
    }

    /// Runs the admin rounds on the next sync instead of waiting (tests,
    /// and right after adding a chat).
    pub fn community_rounds_now(&self) {
        self.community_rounds.lock().unwrap().clear();
    }

    /// Keys from another phone. Kept only when the sender may give them:
    /// my own other phone, the person who invited me, or a community admin.
    pub(crate) async fn take_community_key(&self, sender: &str, content: &Value) -> Result<()> {
        let id = RoomId::parse(content["community"].as_str().context("no community")?)?;
        let k = content["k"].as_str().context("no key")?;
        ensure!(key_bytes(k).is_some(), "bad key");
        let a = content["a"].as_str().filter(|a| key_bytes(a).is_some()).unwrap_or_default();
        let me = self.client.user_id().context("no user")?.to_string();
        let mut book = self.community_book().await;
        if sender != me {
            if let Some(old) = book.keys.get(id.as_str()) {
                // Never let a stranger swap a key I already trust.
                if !old.k.is_empty() && old.k != k {
                    bail!("key already known");
                }
            }
        }
        let mut keys = book.keys.get(id.as_str()).cloned().unwrap_or_default();
        keys.k = k.to_owned();
        if !a.is_empty() {
            keys.a = a.to_owned();
        }
        if keys.from.is_empty() && sender != me {
            keys.from = sender.to_owned();
        }
        book.keys.insert(id.to_string(), keys);
        self.save_community_book(&book).await
    }

    /// Runs on every sync (throttled): joins communities I was brought
    /// into, leaves deleted ones, and on admin phones invites members of
    /// linked chats who are not in the community yet.
    pub(crate) async fn community_duty(&self, last: &std::sync::Mutex<HashMap<String, u64>>) {
        let now = crate::now_ms();
        let Some(me) = self.client.user_id().map(|u| u.to_owned()) else {
            return;
        };
        let book = self.community_book().await;
        // 1. Invites to communities: join when the inviter also gave me the
        //    key and we already share a chat (strangers can't pull me in).
        let visible: BTreeSet<String> = self.visible_invites().await.iter().map(|r| r.to_string()).collect();
        for r in self.client.invited_rooms() {
            let id = r.room_id().to_string();
            if !visible.contains(&id) || !self.is_community(r.room_id()).await {
                continue;
            }
            let Some(keys) = book.keys.get(&id) else { continue };
            let inviter = r.invite_details().await.ok().map(|d| d.inviter_id.to_string()).unwrap_or_default();
            if inviter.is_empty() || keys.from != inviter {
                continue;
            }
            let Ok(inviter_id) = UserId::parse(inviter.as_str()) else { continue };
            let mut shares = false;
            for j in self.client.joined_rooms() {
                if matches!(j.get_member_no_sync(&inviter_id).await, Ok(Some(m)) if *m.membership() == matrix_sdk::ruma::events::room::member::MembershipState::Join) {
                    shares = true;
                    break;
                }
            }
            if shares {
                let _ = self.client.join_room_by_id(r.room_id()).await;
            }
        }
        let joined: BTreeSet<String> = self.client.joined_rooms().iter().map(|r| r.room_id().to_string()).collect();
        for room in self.client.joined_rooms() {
            if !self.is_community(room.room_id()).await {
                continue;
            }
            let id = room.room_id().to_string();
            // Emptied by its owner: gone for me too.
            let info = state_of_opt(room.get_state_event(INFO.into(), "").await.ok().flatten());
            if info.as_object().is_some_and(|o| o.is_empty()) {
                let _ = self.leave_community(room.room_id()).await;
                continue;
            }
            {
                let mut l = last.lock().unwrap();
                if l.get(&id).is_some_and(|t| now.saturating_sub(*t) < DUTY_EVERY_MS) {
                    continue;
                }
                l.insert(id.clone(), now);
            }
            let Some(keys) = book.keys.get(&id).filter(|k| !k.k.is_empty()).cloned() else {
                continue;
            };
            let Some(c) = self.read_community(&room, &keys, Some(&me), &joined).await else {
                continue;
            };
            if c.role == "member" || keys.a.is_empty() {
                continue;
            }
            let _ = self.admin_duty(&room, &c, &keys, &me).await;
        }
    }

    async fn admin_duty(&self, room: &matrix_sdk::Room, c: &Community, keys: &Keys, me: &UserId) -> Result<()> {
        use matrix_sdk::RoomMemberships;
        let known: BTreeSet<String> = room
            .members(RoomMemberships::all())
            .await
            .map_err(to_err)?
            .iter()
            .map(|m| m.user_id().to_string())
            .collect();
        // Other admins get the admin key once.
        let pl = room.power_levels().await.map_err(to_err)?;
        let mut book = self.community_book().await;
        let mut changed = false;
        for m in room.members(RoomMemberships::JOIN).await.map_err(to_err)? {
            let u = m.user_id();
            if u == me || level_of(&pl, u) < 50 {
                continue;
            }
            let mark = format!("{}|{u}", c.id);
            if book.sent_admin.contains(&mark) {
                continue;
            }
            if self.send_private(u.as_str(), KEY_MSG, &json!({ "community": c.id, "k": keys.k, "a": keys.a })).await.is_ok() {
                book.sent_admin.insert(mark);
                changed = true;
            }
        }
        if changed {
            self.save_community_book(&book).await?;
        }
        // Members of linked chats who are not in yet (people who left or
        // were removed keep a membership and are never asked again).
        let mut sent = 0;
        for chat in c.chats.iter().filter(|x| x.state == "in") {
            let Some(cr) = self.client.get_room(&RoomId::parse(chat.room_id.as_str())?) else {
                continue;
            };
            for m in cr.members(RoomMemberships::JOIN).await.map_err(to_err)? {
                let u = m.user_id().to_string();
                if sent >= INVITES_PER_ROUND {
                    return Ok(());
                }
                if known.contains(&u) || u == me.as_str() {
                    continue;
                }
                // Key first, so their phone can check the invite comes from it.
                if self.send_private(&u, KEY_MSG, &json!({ "community": c.id, "k": keys.k })).await.is_err() {
                    continue;
                }
                let _ = room.invite_user_by_id(m.user_id()).await;
                sent += 1;
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seal_and_open() {
        let k = new_key();
        let s = seal(&k, "!c:x|a1", b"hello").unwrap();
        assert_eq!(open(&k, "!c:x|a1", &s).unwrap(), b"hello");
        // Wrong place (moved to another slot) or key: unreadable.
        assert!(open(&k, "!c:x|a2", &s).is_none());
        assert!(open(&new_key(), "!c:x|a1", &s).is_none());
        // Same text twice looks different (fresh nonce).
        assert_ne!(s, seal(&k, "!c:x|a1", b"hello").unwrap());
        assert!(open(&k, "!c:x|a1", "garbage").is_none());
        assert!(!s.contains("hello"));
    }

    #[test]
    fn entries() {
        let ok = json!({"room":"!g:x","by":"@a:x","kind":"group","name":"축구 모임","link":{"kind":"private","code":"abc123","approval":true},"members":12});
        let e = check_entry(&ok).unwrap();
        assert_eq!(e["name"], "축구 모임");
        assert!(check_entry(&json!({"room":"nope","by":"@a:x","kind":"group","name":"x"})).is_none());
        assert!(check_entry(&json!({"room":"!g:x","by":"@a:x","kind":"dm","name":"x"})).is_none());
        assert!(check_entry(&json!({"room":"!g:x","by":"@a:x","kind":"group","name":" "})).is_none());
        let bad_code = json!({"room":"!g:x","by":"@a:x","kind":"group","name":"x","link":{"kind":"public","code":"a b"}});
        assert!(check_entry(&bad_code).is_none());
        let none = check_entry(&json!({"room":"!g:x","by":"@a:x","kind":"channel","name":"x"})).unwrap();
        assert_eq!(none["link"]["kind"], "none");
    }

    #[test]
    fn who_may_keep_a_slot() {
        assert!(entry_allowed("@admin:x", 50, false, "@someone:x"));
        assert!(!entry_allowed("@m:x", 0, false, "@m:x"));
        assert!(entry_allowed("@m:x", 0, true, "@m:x"));
        // A member can't overwrite someone else's chat.
        assert!(!entry_allowed("@m:x", 0, true, "@other:x"));
    }
}
