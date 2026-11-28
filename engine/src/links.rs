// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Invite links for groups and channels (manual 6-1, 6-7).
//!
//! - Public link: an address everyone can see (`/c/<address>`). The room is
//!   listed for the link page (name, about, member count) and anyone with
//!   the link can come in.
//! - Private link: a long random code (`/join#k=<code>`). The code sits
//!   after `#`, so it never reaches a web server; the room is not listed.
//!   Making a new code stops the old link.
//! - "승인 후 참여": people ask first (knock) and an admin lets them in.
//! - Web page (public channels only, owner turns it on): posts the admins
//!   choose to show are copied OUT of encryption as plain room state, and
//!   our web page service (a member that only reads) shows them.
//!
//! Each link is a room alias on our server: `#<address>` or `#j_<code>`.

use anyhow::{Context, Result, bail};
use matrix_sdk::ruma::{OwnedRoomOrAliasId, RoomAliasId, RoomId, UserId, events::room::member::MembershipState};

use crate::{Engine, to_err};

/// Which link a room has, kept in the room for its admins.
pub const LINK_STATE: &str = "app.burumy.link";
/// Web page switch for a public channel.
pub const WEB_STATE: &str = "app.burumy.web";
/// One post shown on the web page (state key = the post's event id).
pub const WEB_POST: &str = "app.burumy.web_post";
/// The web page service's account (reads only, never posts).
pub const WEB_READER: &str = "burumy_web";
/// Extra private links (tip 253), state key = the link's code. Our
/// server keeps their end time and people limit and counts each join.
pub const INVITE_STATE: &str = "app.burumy.invite";
/// Name and people limit bounds for an extra link.
pub const INVITE_NAME_MAX: usize = 32;
pub const INVITE_MAX_PEOPLE: u64 = 99_999;
/// Room type mark for channels (so a link page can say "채널").
pub const CHANNEL_TYPE: &str = "app.burumy.channel";
/// 가입 심사 도우미: its account, and its decision log (room state).
pub const GATE_USER: &str = "burumy_gate";
pub const GATE_LOG: &str = "app.burumy.gate_log";
/// Knock reason carrying join answers: this + {"a": [...]}.
pub const KNOCK_PREFIX: &str = "burumy-join:";

pub fn knock_reason(answers: &[String]) -> String {
    let a: Vec<String> = answers.iter().take(5).map(|x| x.chars().take(300).collect()).collect();
    format!("{KNOCK_PREFIX}{}", serde_json::json!({ "a": a }))
}

pub fn knock_answers(reason: &str) -> Vec<String> {
    let Some(rest) = reason.strip_prefix(KNOCK_PREFIX) else {
        return if reason.trim().is_empty() { vec![] } else { vec![reason.chars().take(300).collect()] };
    };
    let v: serde_json::Value = serde_json::from_str(rest).unwrap_or_default();
    v["a"].as_array().map(|a| a.iter().take(5).map(|x| x.as_str().unwrap_or("").chars().take(300).collect()).collect()).unwrap_or_default()
}

/// Posts kept on the web page; older ones are taken off.
pub const WEB_KEEP: usize = 50;
pub const WEB_TEXT_MAX: usize = 4096;

/// Words a public address may not be (or start with): ours, and ones that
/// look official. The trust service has the full list for names.
const RESERVED: &[&str] = &[
    "admin", "burumy", "buru", "official", "support", "help", "security", "system", "notice",
    "staff", "team", "app", "web", "www", "api", "c", "ch", "join", "add", "rights",
];

#[derive(Debug, Clone, PartialEq, Default)]
pub struct RoomLink {
    /// "public", "private" or "none".
    pub kind: String,
    /// The address (public) or code (private); "" for none.
    pub code: String,
    /// People ask first and an admin lets them in.
    pub approval: bool,
    /// Public channel web page is on.
    pub web: bool,
}

/// One extra private link (tip 253).
#[derive(Debug, Clone, PartialEq, Default)]
pub struct InviteLink {
    pub code: String,
    /// Only the admins see it ("친구용", "인스타 프로필").
    pub name: String,
    /// Ends at (ms since 1970); 0 = no end.
    pub until: u64,
    /// People limit; 0 = no limit.
    pub max: u64,
    /// People who came in through it (counted by our server).
    pub uses: u64,
    /// Who came in, newest last (the server keeps the last 100).
    pub joined: Vec<String>,
    pub by: String,
    pub made: u64,
    /// Cancelled: the link no longer opens, kept in the list.
    pub revoked: bool,
}

impl InviteLink {
    fn from_json(code: &str, c: &serde_json::Value) -> Option<Self> {
        let o = c.as_object()?;
        if o.is_empty() {
            return None;
        }
        Some(Self {
            code: code.to_owned(),
            name: c["name"].as_str().unwrap_or("").to_owned(),
            until: c["until"].as_u64().unwrap_or(0),
            max: c["max"].as_u64().unwrap_or(0),
            uses: c["uses"].as_u64().unwrap_or(0),
            joined: c["joined"]
                .as_array()
                .map(|a| a.iter().filter_map(|x| x.as_str().map(str::to_owned)).collect())
                .unwrap_or_default(),
            by: c["by"].as_str().unwrap_or("").to_owned(),
            made: c["made"].as_u64().unwrap_or(0),
            revoked: c["revoked"].as_bool() == Some(true),
        })
    }

    fn to_json(&self) -> serde_json::Value {
        serde_json::json!({
            "name": self.name, "until": self.until, "max": self.max, "uses": self.uses,
            "joined": self.joined, "by": self.by, "made": self.made, "revoked": self.revoked,
        })
    }
}

/// Cleans what an admin typed: name cut to [INVITE_NAME_MAX], limit capped.
pub fn clean_invite(name: &str, max: u64) -> (String, u64) {
    (name.trim().chars().take(INVITE_NAME_MAX).collect(), max.min(INVITE_MAX_PEOPLE))
}

/// What a link shows before coming in.
#[derive(Debug, Clone, PartialEq, Default)]
pub struct LinkPeek {
    pub room_id: String,
    pub name: String,
    pub about: String,
    pub members: u64,
    pub channel: bool,
    pub approval: bool,
    /// Already a member.
    pub joined: bool,
    /// The room's public photo (empty = none). Only public rooms have one.
    pub photo: Vec<u8>,
}

/// A group or channel in the server's public list (전체 검색).
#[derive(Debug, Clone, PartialEq)]
pub struct PublicRoom {
    pub room_id: String,
    /// Its public address (without '@'), or empty.
    pub address: String,
    pub name: String,
    pub about: String,
    pub members: u64,
    pub channel: bool,
    pub approval: bool,
    /// Already a member.
    pub joined: bool,
}

/// Public address rules: 5-32 of a-z, 0-9, _ ; starts with a letter; not
/// one of our words; not the private-code shape.
pub fn check_address(a: &str) -> Result<String> {
    let a = a.trim().trim_start_matches('@').to_ascii_lowercase();
    let n = a.chars().count();
    if !(5..=32).contains(&n) {
        bail!("length");
    }
    if !a.chars().next().is_some_and(|c| c.is_ascii_lowercase()) {
        bail!("start");
    }
    if !a
        .chars()
        .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_')
    {
        bail!("chars");
    }
    if a.starts_with("j_") || a.contains("__") || a.ends_with('_') {
        bail!("shape");
    }
    if RESERVED.iter().any(|w| a == *w || a.starts_with(&format!("{w}_"))) || a.starts_with("burumy") {
        bail!("reserved");
    }
    Ok(a)
}

/// Letters for private codes: lower case (aliases are), no look-alikes.
const CODE_SET: &[u8] = b"abcdefghijkmnpqrstuvwxyz23456789";

/// Private codes: 26 of 32 letters/digits (130 bits).
pub fn check_code(c: &str) -> Result<String> {
    let c = c.trim();
    if c.len() != 26 || !c.bytes().all(|x| CODE_SET.contains(&x)) {
        bail!("bad code");
    }
    Ok(c.to_owned())
}

fn new_code() -> String {
    use rand::Rng;
    let mut r = rand::thread_rng();
    (0..26).map(|_| CODE_SET[r.gen_range(0..CODE_SET.len())] as char).collect()
}

/// The alias local part for a link: the address, or `j_` + code.
pub fn alias_local(kind: &str, code: &str) -> String {
    if kind == "private" { format!("j_{code}") } else { code.to_owned() }
}

fn state_content(raw: matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState) -> serde_json::Value {
    let json = match raw {
        matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get().to_owned(),
        matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => r.json().get().to_owned(),
    };
    serde_json::from_str::<serde_json::Value>(&json)
        .ok()
        .and_then(|v| v.get("content").cloned())
        .unwrap_or(serde_json::Value::Null)
}

impl Engine {
    fn server_name(&self) -> Result<String> {
        Ok(self.client.user_id().context("not signed in")?.server_name().to_string())
    }

    fn alias(&self, local: &str) -> Result<matrix_sdk::ruma::OwnedRoomAliasId> {
        Ok(RoomAliasId::parse(format!("#{local}:{}", self.server_name()?))?)
    }

    async fn state_of(&self, room_id: &RoomId, kind: &str, key: &str) -> serde_json::Value {
        let Some(room) = self.client.get_room(room_id) else {
            return serde_json::Value::Null;
        };
        match room.get_state_event(kind.into(), key).await {
            Ok(Some(raw)) => state_content(raw),
            _ => serde_json::Value::Null,
        }
    }

    /// The room's link as its admins set it.
    pub async fn room_link(&self, room_id: &RoomId) -> RoomLink {
        let s = self.state_of(room_id, LINK_STATE, "").await;
        let kind = s["kind"].as_str().filter(|k| matches!(*k, "public" | "private")).unwrap_or("none");
        let code = if kind == "none" { "" } else { s["code"].as_str().unwrap_or("") };
        let rule = self.state_of(room_id, "m.room.join_rules", "").await;
        let web = self.state_of(room_id, WEB_STATE, "").await;
        RoomLink {
            kind: kind.into(),
            code: code.into(),
            approval: rule["join_rule"].as_str() == Some("knock"),
            web: kind == "public" && web["on"].as_bool() == Some(true),
        }
    }

    async fn set_join_rule(&self, room_id: &RoomId, rule: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw("m.room.join_rules", "", serde_json::json!({ "join_rule": rule }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    async fn set_listed(&self, room_id: &RoomId, listed: bool) -> Result<()> {
        use matrix_sdk::ruma::api::client::{directory::set_room_visibility::v3::Request, room::Visibility};
        let v = if listed { Visibility::Public } else { Visibility::Private };
        self.client.send(Request::new(room_id.to_owned(), v)).await.map_err(to_err)?;
        Ok(())
    }

    /// Takes the old link's alias away (ignores one that is already gone).
    async fn drop_alias(&self, old: &RoomLink) {
        if old.kind == "none" || old.code.is_empty() {
            return;
        }
        if let Ok(a) = self.alias(&alias_local(&old.kind, &old.code)) {
            let _ = self.client.remove_room_alias(&a).await;
        }
    }

    async fn write_link(&self, room_id: &RoomId, kind: &str, code: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw(LINK_STATE, "", serde_json::json!({ "kind": kind, "code": code }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    // ---- 초대 링크 여러 개 (tip 253) ----

    /// The room's extra links, newest first (admins).
    pub async fn invite_links(&self, room_id: &RoomId) -> Vec<InviteLink> {
        let Some(room) = self.client.get_room(room_id) else {
            return vec![];
        };
        let Ok(list) = room.get_state_events(INVITE_STATE.into()).await else {
            return vec![];
        };
        let mut out: Vec<InviteLink> = list
            .into_iter()
            .filter_map(|raw| {
                let json = match raw {
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get().to_owned(),
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => r.json().get().to_owned(),
                };
                let v: serde_json::Value = serde_json::from_str(&json).ok()?;
                let key = v["state_key"].as_str()?;
                check_code(key).ok()?;
                InviteLink::from_json(key, v.get("content")?)
            })
            .collect();
        out.sort_by_key(|l| std::cmp::Reverse(l.made));
        out
    }

    /// One link as the server has it now (the local copy may be a sync
    /// behind right after it was made or counted).
    async fn invite_now(&self, room_id: &RoomId, code: &str) -> Option<InviteLink> {
        use matrix_sdk::ruma::api::client::state::get_state_event_for_key::v3::Request;
        let req = Request::new(room_id.to_owned(), INVITE_STATE.into(), code.to_owned());
        let from_server = match self.client.send(req).await {
            Ok(r) => serde_json::from_str::<serde_json::Value>(r.event_or_content.get()).ok(),
            Err(_) => None,
        };
        let c = match from_server {
            Some(v) => v,
            None => self.state_of(room_id, INVITE_STATE, code).await,
        };
        InviteLink::from_json(code, &c)
    }

    async fn write_invite(&self, room_id: &RoomId, link: &InviteLink) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw(INVITE_STATE, &link.code, link.to_json()).await.map_err(to_err)?;
        Ok(())
    }

    /// A new extra link (admins): its own code, an optional name, end time
    /// (0 = none) and people limit (0 = none).
    pub async fn make_invite_link(&self, room_id: &RoomId, name: &str, until: u64, max: u64, now: u64) -> Result<InviteLink> {
        let (name, max) = clean_invite(name, max);
        anyhow::ensure!(until == 0 || until > now, "ends in the past");
        let code = new_code();
        self.client
            .create_room_alias(&self.alias(&alias_local("private", &code))?, room_id)
            .await
            .map_err(to_err)?;
        let link = InviteLink {
            code,
            name,
            until,
            max,
            by: self.client.user_id().map(|u| u.to_string()).unwrap_or_default(),
            made: now,
            ..Default::default()
        };
        self.write_invite(room_id, &link).await?;
        Ok(link)
    }

    /// Changes a link's name, end time or limit (count kept).
    pub async fn edit_invite_link(&self, room_id: &RoomId, code: &str, name: &str, until: u64, max: u64) -> Result<InviteLink> {
        let code = check_code(code)?;
        let mut link = self.invite_now(room_id, &code).await.context("no such link")?;
        anyhow::ensure!(!link.revoked, "cancelled");
        let (name, max) = clean_invite(name, max);
        link.name = name;
        link.until = until;
        link.max = max;
        self.write_invite(room_id, &link).await?;
        Ok(link)
    }

    /// Cancels a link: it stops opening at once (its alias goes) and stays
    /// in the list as 취소된 링크.
    pub async fn revoke_invite_link(&self, room_id: &RoomId, code: &str) -> Result<()> {
        let code = check_code(code)?;
        let mut link = self.invite_now(room_id, &code).await.context("no such link")?;
        if let Ok(a) = self.alias(&alias_local("private", &code)) {
            let _ = self.client.remove_room_alias(&a).await;
        }
        link.revoked = true;
        self.write_invite(room_id, &link).await
    }

    /// Brings a cancelled link back (the 되돌리기 right after 취소).
    pub async fn restore_invite_link(&self, room_id: &RoomId, code: &str) -> Result<()> {
        let code = check_code(code)?;
        let mut link = self.invite_now(room_id, &code).await.context("no such link")?;
        self.client
            .create_room_alias(&self.alias(&alias_local("private", &code))?, room_id)
            .await
            .map_err(to_err)?;
        link.revoked = false;
        self.write_invite(room_id, &link).await
    }

    /// Takes a cancelled link out of the list for good.
    pub async fn delete_invite_link(&self, room_id: &RoomId, code: &str) -> Result<()> {
        let code = check_code(code)?;
        if let Ok(a) = self.alias(&alias_local("private", &code)) {
            let _ = self.client.remove_room_alias(&a).await;
        }
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw(INVITE_STATE, &code, serde_json::json!({})).await.map_err(to_err)?;
        Ok(())
    }

    /// The main private link's count (our server keeps it in the link
    /// state): (people, who came in, newest last).
    pub async fn main_link_uses(&self, room_id: &RoomId) -> (u64, Vec<String>) {
        let s = self.state_of(room_id, LINK_STATE, "").await;
        let joined = s["joined"]
            .as_array()
            .map(|a| a.iter().filter_map(|x| x.as_str().map(str::to_owned)).collect())
            .unwrap_or_default();
        (s["uses"].as_u64().unwrap_or(0), joined)
    }

    /// Is this public address free? (Mine counts as free.)
    pub async fn address_free(&self, room_id: &RoomId, address: &str) -> Result<bool> {
        let a = check_address(address)?;
        let alias = self.alias(&a)?;
        if self.client.is_room_alias_available(&alias).await.map_err(to_err)? {
            return Ok(true);
        }
        let r = self.client.resolve_room_alias(&alias).await.map_err(to_err)?;
        Ok(r.room_id == room_id)
    }

    /// Makes the room public at this address (admins).
    pub async fn set_public_link(&self, room_id: &RoomId, address: &str) -> Result<RoomLink> {
        let a = check_address(address)?;
        let old = self.room_link(room_id).await;
        if !(old.kind == "public" && old.code == a) {
            anyhow::ensure!(self.address_free(room_id, &a).await?, "taken");
            self.client.create_room_alias(&self.alias(&a)?, room_id).await.map_err(to_err)?;
            self.drop_alias(&old).await;
        }
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw(
            "m.room.canonical_alias",
            "",
            serde_json::json!({ "alias": self.alias(&a)?.to_string() }),
        )
        .await
        .map_err(to_err)?;
        self.set_listed(room_id, true).await?;
        self.set_join_rule(room_id, if old.approval { "knock" } else { "public" }).await?;
        self.write_link(room_id, "public", &a).await?;
        // The link card may now show the room photo.
        let _ = self.plain_room_photo(room_id, true, None).await;
        // The local copy updates on the next sync; say what was set.
        Ok(RoomLink { kind: "public".into(), code: a, approval: old.approval, web: old.web })
    }

    /// Makes a new private link; the old one stops working (admins).
    pub async fn new_private_link(&self, room_id: &RoomId) -> Result<RoomLink> {
        let old = self.room_link(room_id).await;
        let code = new_code();
        self.client
            .create_room_alias(&self.alias(&alias_local("private", &code))?, room_id)
            .await
            .map_err(to_err)?;
        self.drop_alias(&old).await;
        if old.kind == "public" {
            let room = self.client.get_room(room_id).context("unknown room")?;
            room.send_state_event_raw("m.room.canonical_alias", "", serde_json::json!({}))
                .await
                .map_err(to_err)?;
            if old.web {
                self.set_web_page(room_id, false).await?;
            }
        }
        self.set_listed(room_id, false).await?;
        self.set_join_rule(room_id, if old.approval { "knock" } else { "public" }).await?;
        self.write_link(room_id, "private", &code).await?;
        let _ = self.plain_room_photo(room_id, false, None).await;
        Ok(RoomLink { kind: "private".into(), code, approval: old.approval, web: false })
    }

    /// No link at all: only people added by an admin come in.
    pub async fn remove_link(&self, room_id: &RoomId) -> Result<()> {
        let old = self.room_link(room_id).await;
        if old.web {
            self.set_web_page(room_id, false).await?;
        }
        self.drop_alias(&old).await;
        self.set_listed(room_id, false).await?;
        self.set_join_rule(room_id, "invite").await?;
        self.write_link(room_id, "none", "").await?;
        let _ = self.plain_room_photo(room_id, false, None).await;
        Ok(())
    }

    /// "승인 후 참여" on/off.
    pub async fn set_link_approval(&self, room_id: &RoomId, on: bool) -> Result<()> {
        let link = self.room_link(room_id).await;
        let rule = match (on, link.kind.as_str()) {
            (true, _) => "knock",
            (false, "none") => "invite",
            (false, _) => "public",
        };
        self.set_join_rule(room_id, rule).await
    }

    /// What a public address shows (name, about, members). Private codes
    /// show nothing from the server: the link itself carries the name.
    pub async fn peek_address(&self, address: &str) -> Result<LinkPeek> {
        use matrix_sdk::ruma::{api::client::directory::get_public_rooms_filtered::v3::Request, directory::Filter};
        let a = check_address(address).or_else(|_| {
            // Old or reserved-looking addresses still open if they exist.
            let a = address.trim().to_ascii_lowercase();
            anyhow::ensure!(!a.is_empty() && a.len() <= 64, "bad address");
            Ok::<_, anyhow::Error>(a)
        })?;
        let alias = self.alias(&a)?;
        let room_id = self.client.resolve_room_alias(&alias).await.map_err(to_err)?.room_id;
        let mut req = Request::new();
        let mut f = Filter::new();
        f.generic_search_term = Some(alias.to_string());
        req.filter = f;
        req.limit = Some(20u32.into());
        let res = self.client.public_rooms_filtered(req).await.map_err(to_err)?;
        let chunk = res.chunk.into_iter().find(|c| c.room_id == room_id).context("not public")?;
        let joined = self
            .client
            .get_room(&room_id)
            .is_some_and(|r| r.state() == matrix_sdk::RoomState::Joined);
        let web = self.state_of(&room_id, WEB_STATE, "").await["on"].as_bool() == Some(true);
        let members = u64::from(chunk.num_joined_members);
        let photo = match &chunk.avatar_url {
            Some(u) => {
                use matrix_sdk::{
                    media::{MediaFormat, MediaRequestParameters},
                    ruma::events::room::MediaSource,
                };
                let req = MediaRequestParameters { source: MediaSource::Plain(u.clone()), format: MediaFormat::File };
                self.client.media().get_media_content(&req, true).await.ok().filter(|b| b.len() <= 8 * 1024 * 1024).unwrap_or_default()
            }
            None => vec![],
        };
        Ok(LinkPeek {
            room_id: room_id.to_string(),
            name: chunk.name.unwrap_or_default(),
            about: chunk.topic.unwrap_or_default(),
            // The web page reader is not a person.
            members: if web && members > 0 { members - 1 } else { members },
            channel: chunk.room_type.as_ref().is_some_and(|t| t.to_string() == CHANNEL_TYPE),
            approval: matches!(chunk.join_rule, matrix_sdk::ruma::room::JoinRuleKind::Knock),
            joined,
            photo,
        })
    }

    /// 전체 검색: public groups and channels whose name, description or
    /// address has the words (the server's public room list; only rooms
    /// their admins made public are in it). Nothing about my own chats is
    /// sent. `channels_only` keeps channels.
    pub async fn search_public(&self, term: &str, channels_only: bool, limit: u32) -> Result<Vec<PublicRoom>> {
        use matrix_sdk::ruma::{api::client::directory::get_public_rooms_filtered::v3::Request, directory::Filter};
        let term = term.trim().trim_start_matches('@');
        if term.chars().count() < 2 {
            return Ok(vec![]);
        }
        let mut req = Request::new();
        let mut f = Filter::new();
        f.generic_search_term = Some(term.to_owned());
        req.filter = f;
        req.limit = Some(limit.clamp(1, 50).into());
        let res = self.client.public_rooms_filtered(req).await.map_err(to_err)?;
        let local = |a: &matrix_sdk::ruma::OwnedRoomAliasId| a.alias().to_owned();
        let mut out = Vec::new();
        for c in res.chunk {
            let channel = c.room_type.as_ref().is_some_and(|t| t.to_string() == CHANNEL_TYPE);
            if channels_only && !channel {
                continue;
            }
            // Only rooms with one of our public addresses (never private codes).
            let address = c.canonical_alias.as_ref().map(local).unwrap_or_default();
            if address.is_empty() || address.starts_with("j_") {
                continue;
            }
            let joined = self
                .client
                .get_room(&c.room_id)
                .is_some_and(|r| r.state() == matrix_sdk::RoomState::Joined);
            out.push(PublicRoom {
                room_id: c.room_id.to_string(),
                address,
                name: c.name.unwrap_or_default(),
                about: c.topic.unwrap_or_default(),
                members: u64::from(c.num_joined_members),
                channel,
                approval: matches!(c.join_rule, matrix_sdk::ruma::room::JoinRuleKind::Knock),
                joined,
            });
        }
        // Bigger first, like Telegram's global results.
        out.sort_by(|a, b| b.members.cmp(&a.members));
        Ok(out)
    }

    /// Comes in through a link ("public" + address or "private" + code).
    /// Returns the room id, and whether it only asked (approval on).
    pub async fn join_link(&self, kind: &str, code: &str) -> Result<(String, bool)> {
        self.join_link_with(kind, code, &[]).await
    }

    /// The same, sending answers to the room's join questions with the
    /// request (the knock reason, which the room's admins and its join
    /// helper read). Answers are not encrypted: the app says so.
    pub async fn join_link_with(&self, kind: &str, code: &str, answers: &[String]) -> Result<(String, bool)> {
        let local = match kind {
            "public" => alias_local("public", &code.trim().to_ascii_lowercase()),
            "private" => alias_local("private", &check_code(&code.to_ascii_lowercase())?),
            _ => bail!("bad link"),
        };
        let alias = self.alias(&local)?;
        let target: OwnedRoomOrAliasId = alias.clone().into();
        match self.client.join_room_by_id_or_alias(&target, &[]).await {
            Ok(room) => Ok((room.room_id().to_string(), false)),
            Err(e) => {
                // Approval on: ask instead.
                let msg = e.to_string();
                if !msg.contains("M_FORBIDDEN") && !msg.to_lowercase().contains("forbidden") {
                    return Err(to_err(e));
                }
                // Our server turned the link itself down (ended, full,
                // cancelled): asking would not help, say why.
                if msg.contains("burumy: link") {
                    return Err(to_err(e));
                }
                let reason = (!answers.is_empty()).then(|| knock_reason(answers));
                let room = self.client.knock(target, reason, vec![]).await.map_err(to_err)?;
                Ok((room.room_id().to_string(), true))
            }
        }
    }

    /// People asking to come in (admins see these): user, name, and the
    /// answers they sent ([] when none).
    pub async fn join_requests(&self, room_id: &RoomId) -> Result<Vec<(String, String, Vec<String>)>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let list = room.members(matrix_sdk::RoomMemberships::KNOCK).await.map_err(to_err)?;
        Ok(list
            .iter()
            .map(|m| {
                (
                    m.user_id().to_string(),
                    m.display_name().map(str::to_owned).unwrap_or_else(|| m.user_id().localpart().to_owned()),
                    knock_answers(m.event().reason().unwrap_or("")),
                )
            })
            .collect())
    }

    fn gate_user(&self) -> Result<matrix_sdk::ruma::OwnedUserId> {
        Ok(UserId::parse(format!("@{GATE_USER}:{}", self.server_name()?))?)
    }

    /// 가입 심사 도우미 on/off (admins). The settings themselves (questions,
    /// rules) are in the room config (keys `gate`, `join_questions`); write
    /// `gate.on` first, then call this. On: the helper gets exactly the
    /// level needed to let people in and turn them down (and to write its
    /// log), and is invited. Off: it is taken out.
    pub async fn set_gate_helper(&self, room_id: &RoomId, on: bool) -> Result<()> {
        use matrix_sdk::ruma::{events::room::power_levels::RoomPowerLevelsEventContent, int};
        let room = self.client.get_room(room_id).context("unknown room")?;
        let helper = self.gate_user()?;
        let mut pl = room.power_levels().await.map_err(to_err)?;
        if on {
            let level = pl.invite.max(pl.kick).max(int!(1));
            pl.users.insert(helper.clone(), level);
            pl.events.insert(GATE_LOG.into(), level);
            room.send_state_event(RoomPowerLevelsEventContent::try_from(pl).map_err(to_err)?)
                .await
                .map_err(to_err)?;
            let joined = room
                .get_member_no_sync(&helper)
                .await
                .ok()
                .flatten()
                .is_some_and(|m| matches!(m.membership(), MembershipState::Join | MembershipState::Invite));
            if !joined {
                room.invite_user_by_id(&helper).await.map_err(to_err)?;
            }
        } else {
            if room.get_member_no_sync(&helper).await.ok().flatten().is_some_and(|m| {
                matches!(m.membership(), MembershipState::Join | MembershipState::Invite)
            }) {
                let _ = room.kick_user(&helper, Some("gate:off")).await;
            }
            if pl.users.remove(&helper).is_some() {
                room.send_state_event(RoomPowerLevelsEventContent::try_from(pl).map_err(to_err)?)
                    .await
                    .map_err(to_err)?;
            }
        }
        Ok(())
    }

    /// Whether the helper is in the room, and how many encryption devices
    /// it has (must be 0: then it can't get any room key).
    pub async fn gate_helper_state(&self, room_id: &RoomId) -> Result<(bool, usize)> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let helper = self.gate_user()?;
        let joined = room
            .get_member_no_sync(&helper)
            .await
            .ok()
            .flatten()
            .is_some_and(|m| matches!(m.membership(), MembershipState::Join));
        let devices = self.client.encryption().get_user_devices(&helper).await.map_err(to_err)?.devices().count();
        Ok((joined, devices))
    }

    /// The helper's recent decisions (room state written by the helper),
    /// as JSON: {"e": [{"u","n","v","t"}, ...]}, newest last.
    pub async fn gate_log(&self, room_id: &RoomId) -> String {
        let v = self.state_of(room_id, GATE_LOG, "").await;
        let helper = self.gate_user().map(|u| u.to_string()).unwrap_or_default();
        // Only entries the helper itself wrote count.
        let room = self.client.get_room(room_id);
        let by_helper = match room {
            Some(r) => match r.get_state_event(GATE_LOG.into(), "").await {
                Ok(Some(matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(raw))) => {
                    raw.get_field::<String>("sender").ok().flatten().is_some_and(|s| s == helper)
                }
                _ => false,
            },
            None => false,
        };
        if by_helper { v.to_string() } else { "{}".into() }
    }

    /// After asking to come in: "in" (let in, now joined), "no" (turned
    /// down), "waiting", or "unknown".
    pub async fn knock_state(&self, room_id: &RoomId) -> Result<String> {
        let Some(room) = self.client.get_room(room_id) else { return Ok("unknown".into()) };
        Ok(match room.state() {
            matrix_sdk::RoomState::Joined => "in".into(),
            matrix_sdk::RoomState::Invited => {
                room.join().await.map_err(to_err)?;
                "in".into()
            }
            matrix_sdk::RoomState::Knocked => "waiting".into(),
            _ => "no".into(),
        })
    }

    /// Lets someone in, or says no.
    pub async fn answer_join_request(&self, room_id: &RoomId, user_id: &str, accept: bool) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let uid = UserId::parse(user_id).context("bad user id")?;
        if accept {
            room.invite_user_by_id(&uid).await.map_err(to_err)?;
        } else {
            room.kick_user(&uid, None).await.map_err(to_err)?;
        }
        Ok(())
    }

    fn web_reader(&self) -> Result<matrix_sdk::ruma::OwnedUserId> {
        Ok(UserId::parse(format!("@{WEB_READER}:{}", self.server_name()?))?)
    }

    /// Web page on/off for a public channel (owner). On: the reader account
    /// is let in. Off: it is taken out and every shown post is removed.
    pub async fn set_web_page(&self, room_id: &RoomId, on: bool) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if on {
            let link = self.room_link(room_id).await;
            anyhow::ensure!(link.kind == "public", "public link first");
        }
        room.send_state_event_raw(WEB_STATE, "", serde_json::json!({ "on": on }))
            .await
            .map_err(to_err)?;
        let reader = self.web_reader()?;
        if on {
            if let Err(e) = room.invite_user_by_id(&reader).await {
                // Already in is fine.
                if !e.to_string().to_lowercase().contains("already") {
                    return Err(to_err(e));
                }
            }
        } else {
            for id in self.web_post_ids_on_server(room_id).await? {
                room.send_state_event_raw(WEB_POST, &id, serde_json::json!({})).await.map_err(to_err)?;
            }
            let _ = room.kick_user(&reader, None).await;
        }
        Ok(())
    }

    /// Shown posts as the server has them right now (the local copy may
    /// not have the latest yet), for taking them all off.
    async fn web_post_ids_on_server(&self, room_id: &RoomId) -> Result<Vec<String>> {
        use matrix_sdk::ruma::api::client::state::get_state_events::v3::Request;
        let res = self.client.send(Request::new(room_id.to_owned())).await.map_err(to_err)?;
        Ok(res
            .room_state
            .iter()
            .filter_map(|raw| {
                let v: serde_json::Value = serde_json::from_str(raw.json().get()).ok()?;
                (v["type"] == WEB_POST && v["content"].get("ts").is_some()).then(|| v["state_key"].as_str().map(str::to_owned))?
            })
            .collect())
    }

    /// Posts now on the web page: (event id, content), newest first.
    pub async fn web_posts(&self, room_id: &RoomId) -> Vec<(String, serde_json::Value)> {
        let Some(room) = self.client.get_room(room_id) else {
            return vec![];
        };
        let Ok(list) = room.get_state_events(WEB_POST.into()).await else {
            return vec![];
        };
        let mut out: Vec<(String, serde_json::Value)> = list
            .into_iter()
            .filter_map(|raw| {
                let json = match raw {
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get().to_owned(),
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => r.json().get().to_owned(),
                };
                let v: serde_json::Value = serde_json::from_str(&json).ok()?;
                let key = v["state_key"].as_str()?.to_owned();
                let c = v.get("content")?.clone();
                c.get("ts")?.as_u64()?;
                Some((key, c))
            })
            .collect();
        out.sort_by_key(|(_, c)| std::cmp::Reverse(c["ts"].as_u64().unwrap_or(0)));
        out
    }

    /// Shows one channel post on the web page, OUT of encryption: the
    /// words, and the photo uploaded again without encryption. Keeps the
    /// newest [WEB_KEEP].
    pub async fn web_post(
        &self,
        room_id: &RoomId,
        event_id: &str,
        text: &str,
        ts: u64,
        photo: Option<(String, Vec<u8>)>,
    ) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(self.room_link(room_id).await.web, "web page is off");
        anyhow::ensure!(event_id.starts_with('$') && event_id.len() < 256, "bad id");
        let text: String = text.trim().chars().take(WEB_TEXT_MAX).collect();
        let mut c = serde_json::json!({ "text": text, "ts": ts });
        if let Some((mime, bytes)) = photo {
            anyhow::ensure!(mime.starts_with("image/") && bytes.len() <= 10 * 1024 * 1024, "photo");
            let m: mime::Mime = mime.parse().context("bad mime")?;
            let up = self.client.media().upload(&m, bytes, None).await.map_err(to_err)?;
            c["photo"] = serde_json::Value::String(up.content_uri.to_string());
        }
        anyhow::ensure!(!text.is_empty() || c.get("photo").is_some(), "empty");
        room.send_state_event_raw(WEB_POST, event_id, c).await.map_err(to_err)?;
        let all = self.web_posts(room_id).await;
        for (id, _) in all.iter().skip(WEB_KEEP) {
            room.send_state_event_raw(WEB_POST, id, serde_json::json!({})).await.map_err(to_err)?;
        }
        Ok(())
    }

    /// Takes one post off the web page.
    pub async fn web_unpost(&self, room_id: &RoomId, event_id: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_state_event_raw(WEB_POST, event_id, serde_json::json!({})).await.map_err(to_err)?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn addresses() {
        assert_eq!(check_address("Coffee_Club").unwrap(), "coffee_club");
        assert_eq!(check_address("@seoul_runners").unwrap(), "seoul_runners");
        for bad in ["abc", "1coffee", "cof fee", "j_abcdef", "coffee_", "co__ffee", "admin", "burumy_kr", "support_team", "한글주소임"] {
            assert!(check_address(bad).is_err(), "{bad}");
        }
        assert!(check_address(&"a".repeat(33)).is_err());
    }

    #[test]
    fn invite_link_json() {
        let c = serde_json::json!({"name":"친구용","until":5,"max":10,"uses":3,"joined":["@a:b"],"by":"@o:b","made":1,"revoked":false});
        let l = InviteLink::from_json("abc", &c).unwrap();
        assert_eq!((l.uses, l.max, l.joined.len()), (3, 10, 1));
        assert_eq!(InviteLink::from_json("abc", &l.to_json()).unwrap(), l);
        // A deleted link (empty content) is gone from the list.
        assert!(InviteLink::from_json("abc", &serde_json::json!({})).is_none());
        let (n, m) = clean_invite(&format!("  {}  ", "가".repeat(40)), 10_000_000);
        assert_eq!(n.chars().count(), INVITE_NAME_MAX);
        assert_eq!(m, INVITE_MAX_PEOPLE);
    }

    #[test]
    fn codes() {
        let c = new_code();
        assert_eq!(c.len(), 26);
        assert!(check_code(&c).is_ok());
        assert!(check_code("short").is_err());
        assert!(check_code("abc/defghijkmnpqrstuvwxyz2").is_err());
        assert!(check_code("ABCDEFGHIJKMNPQRSTUVWXYZ23").is_err());
        assert_ne!(new_code(), new_code());
        assert_eq!(alias_local("private", "abc"), "j_abc");
        assert_eq!(alias_local("public", "coffee"), "coffee");
    }
}

#[cfg(test)]
mod knock_tests {
    use super::*;

    #[test]
    fn answers_round_trip() {
        let a = vec!["1".to_owned(), "하우스 음악 만들어요".to_owned()];
        assert_eq!(knock_answers(&knock_reason(&a)), a);
        assert_eq!(knock_answers("저 들어가고 싶어요"), vec!["저 들어가고 싶어요".to_owned()]);
        assert!(knock_answers("").is_empty());
    }
}
