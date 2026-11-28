// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Burumy v2 engine (feasibility prototype).
//!
//! A thin wrapper around matrix-rust-sdk (Apache-2.0) that the Flutter app
//! calls through its own bindings. Written from scratch for v2: it does not
//! copy or follow any FluffyChat / matrix-dart-sdk code.
#![recursion_limit = "256"]

pub mod account;
pub mod call;
pub mod article;
pub mod card;
pub mod checklist;
pub mod community;
pub mod history;
pub mod import;
pub mod location;
pub mod links;
pub mod lock;
pub mod meetup;
pub mod mine;
pub mod org;
pub mod poll;
#[cfg(not(target_arch = "wasm32"))]
pub mod preview;
pub mod search;
mod quiet;
pub mod signal;
pub mod streak;
pub mod topic;
pub mod verify;

use std::{path::Path, time::Duration};

use anyhow::{Context, Result, anyhow, bail};
pub use matrix_sdk;
use matrix_sdk::{
    Client,
    config::SyncSettings,
    encryption::{BackupDownloadStrategy, EncryptionSettings},
    room::MessagesOptions,
    ruma::{
        OwnedRoomId, OwnedUserId, RoomId, UserId,
        api::client::{
            account::register::v3::Request as RegisterRequest,
            uiaa::{AuthData, Dummy, Password, UserIdentifier},
        },
        events::{
            AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
            room::message::{MessageType, RoomMessageEventContent},
        },
    },
};
use matrix_sdk_base_crypto_shim::TimelineEventKind;

/// An invitation waiting on this phone.
/// Profile field that holds the about-me text.
const BIO_FIELD: &str = "app.burumy.bio";
/// Public profile field with my birthday ("MM-DD" or "YYYY-MM-DD"), only
/// when I let everyone see it.
const BIRTHDAY_FIELD: &str = "app.burumy.birthday";
/// My profile card for friends (photo, about me, birthday), sent inside
/// each 1:1 chat's own encryption: the server can't read it.
pub const PROFILE_TYPE: &str = "im.securemessenger.profile";

/// 이모지 상태 (Telegram tip 359): an emoji beside my name, sent end-to-end
/// encrypted into each 1:1 chat (the server never sees it; group members
/// who aren't friends don't get it). `{ "e": "🏖️", "until": ms or 0 }`.
pub const STATUS_TYPE: &str = "app.burumy.status";

/// Someone's photo, about-me and birthday as I may see them.
#[derive(Debug, Clone, Default)]
pub struct ProfileCard {
    pub photo: Option<Vec<u8>>,
    pub bio: String,
    pub birthday: String,
    /// true: it came from our encrypted 1:1 chat (not the public profile).
    pub private: bool,
}

fn birthday_ok(b: &str) -> bool {
    let p: Vec<&str> = b.split('-').collect();
    let num = |x: &str, n: usize| x.len() == n && x.chars().all(|c| c.is_ascii_digit());
    b.is_empty()
        || (p.len() == 2 && num(p[0], 2) && num(p[1], 2))
        || (p.len() == 3 && num(p[0], 4) && num(p[1], 2) && num(p[2], 2))
}

#[derive(Clone, Debug)]
pub struct Invitation {
    pub room_id: String,
    pub name: String,
    pub inviter: String,
    pub direct: bool,
}

/// One line of the call history (Calls tab).
#[derive(Debug, Clone)]
pub struct CallLogEntry {
    pub room_id: String,
    pub call_id: String,
    pub from: String,
    pub mine: bool,
    pub video: bool,
    /// "ringing", "ongoing", "ended", "missed", "declined", "busy"
    pub state: String,
    pub started_at: u64,
    pub answered_at: Option<u64>,
    pub ended_at: Option<u64>,
}

/// A call that is ringing for me.
#[derive(Debug, Clone)]
pub struct RingingCall {
    pub room_id: String,
    pub call_id: String,
    pub from: String,
    pub video: bool,
    pub started_at: u64,
}

/// Ticket into a call: where to connect, the pass, and the media key
/// (base64, from the encrypted invite) for end-to-end encrypted media.
#[derive(Debug, Clone)]
pub struct CallPass {
    pub url: String,
    pub token: String,
    pub media_key: String,
    pub video: bool,
}

/// What the app shows for one message.
#[derive(Debug, Clone, Default)]
pub struct Message {
    pub event_id: String,
    pub sender: String,
    /// Plain text, or None when the message could not be opened.
    pub body: Option<String>,
    /// True when the message travelled end-to-end encrypted.
    pub was_encrypted: bool,
    /// Server time in milliseconds since 1970.
    pub ts: u64,
    /// Sent by this account.
    pub mine: bool,
    /// "text", "image", "video", "audio", "file", or "locked" (not opened yet).
    pub kind: String,
    /// The message this one answers, if any.
    pub reply_to: Option<String>,
    /// First message of the thread this one belongs to ("스레드로 답장").
    pub thread_root: Option<String>,
    /// 주제 (group topics, tip 527): the topic id written inside the
    /// encrypted content; None = 일반 (General). The server never sees it.
    pub topic: Option<String>,
    /// Changed after sending.
    pub edited: bool,
    /// When the last accepted change was made (ms), if edited.
    pub edited_at: Option<u64>,
    /// The words as first sent, if edited ("수정 기록").
    pub first_body: Option<String>,
    /// Internal: this event only changes another message (not shown itself).
    #[doc(hidden)]
    pub replaces: Option<String>,
    /// Emoji reactions under this message.
    pub reactions: Vec<Reaction>,
    /// Disappears at this time (ms), if the chat had a timer.
    pub expires_at: Option<u64>,
    /// Photo/video that can be opened only once, and whether it was.
    pub view_once: bool,
    pub opened: bool,
    /// Passed on from another chat (where from is never recorded).
    pub forwarded: bool,
    /// Sent without a notification sound ("send quietly").
    pub silent: bool,
    /// Card for the first link in a text (made by the sender's phone).
    pub preview: Option<LinkPreview>,
    /// Voice message: length and loudness bars (0..1024).
    pub voice: Option<Voice>,
    /// 움직이는 사진: a photo that also carries a short clip.
    pub live: Option<Live>,
    /// Poll with its current numbers (kind "poll").
    pub poll: Option<poll::Poll>,
    /// A home-screen bubble (always view-once).
    pub bubble: bool,
    /// Voice/video call line (kind "call").
    pub call: Option<call::Call>,
    /// Words under a photo, video or file (the body is then the file name).
    pub caption: Option<String>,
    /// File size in bytes from the message (photo, video, file, voice).
    pub size: Option<u64>,
    /// Checklist with its ticks (kind "checklist").
    pub checklist: Option<checklist::Checklist>,
    /// Plan with who is coming (kind "meetup").
    pub meetup: Option<meetup::Meetup>,
    /// Shared contact's user id (kind "contact"; body = their name).
    pub contact: Option<String>,
    /// FAQ, guide, link buttons, formatted post, giveaway, form or
    /// safety check-in (kind "card").
    pub card: Option<card::Card>,
    /// 부분 인용 (Telegram tip 399): the part of the answered message the
    /// sender picked, carried inside the encrypted message. With
    /// `quote_name` and no `reply_to` it came from another chat ("다른
    /// 대화에서 답장"): only the copied words and the writer's name travel.
    pub quote: Option<String>,
    pub quote_name: Option<String>,
    /// 설명 위로 (tip 452): the words show above the photo or video.
    pub caption_above: bool,
    /// The photo, video or file was swapped by an edit (tips 482, 81,
    /// 224): download it from this event (the edit), not the message.
    /// The old one stays in the message itself (수정 기록).
    pub media_from: Option<String>,
    pub media_changed: bool,
    /// 보내는 이름 (channel batch #15, Telegram tips 472 + 310): who this
    /// message was sent as, carried inside the encrypted message as JSON.
    /// `{"ch":true}` = as this channel (an admin hiding their name in a
    /// channel that shows authors); `{"room":"!id","addr":"name"}` = as
    /// one of the sender's public channels. The app checks the claim.
    pub post_as: Option<String>,
}

/// A bubble waiting on my home screen: who and when, never what.
#[derive(Debug, Clone, PartialEq)]
pub struct BubbleRef {
    pub room_id: String,
    pub event_id: String,
    pub from: String,
    pub ts: u64,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Voice {
    pub duration_ms: u64,
    pub waveform: Vec<u16>,
}

/// 움직이는 사진 (iPhone Live Photo / Android Motion Photo): the still is the
/// normal photo; a short clip (about 3 s) rides along, encrypted the same
/// way. `style` = "live" (plays once), "loop" or "bounce" (forward, then
/// backward).
#[derive(Debug, Clone, PartialEq)]
pub struct Live {
    pub style: String,
    pub duration_ms: u64,
}

/// The clip may be at most this long and this big (a Live Photo is ~3 s).
pub const LIVE_MAX_MS: u64 = 10_000;
pub const LIVE_MAX_BYTES: usize = 20 * 1024 * 1024;

/// Checks the play style; anything unknown plays once.
pub fn live_style(s: &str) -> &'static str {
    match s {
        "loop" => "loop",
        "bounce" => "bounce",
        _ => "live",
    }
}

/// Title and picture of a web link, carried inside the encrypted message.
#[derive(Debug, Clone, PartialEq)]
pub struct LinkPreview {
    pub url: String,
    pub title: String,
    pub description: Option<String>,
    pub site: Option<String>,
    pub has_image: bool,
    /// Tip 400: the card sits above the words (sender's choice).
    pub above: bool,
    /// Tip 400: small picture at the side instead of a big one on top.
    pub small: bool,
}

/// How the sender set up the link card before sending (Telegram tip 400):
/// which link, card above or below the words, small or big picture, or no
/// card at all. Everything stays inside the encrypted message.
#[derive(Debug, Clone, Default, PartialEq)]
pub struct LinkChoice {
    /// One of the links in the text; None = the first one.
    pub url: Option<String>,
    pub above: bool,
    pub small: bool,
    /// "미리보기 안 함".
    pub off: bool,
}

/// Field inside an encrypted text message holding its link card.
pub const PREVIEW_FIELD: &str = "im.securemessenger.preview";

/// One emoji under a message, with how many people chose it.
#[derive(Debug, Clone, PartialEq)]
pub struct Reaction {
    pub key: String,
    pub count: u32,
    /// My own reaction event (to take it back), if I chose this one.
    pub mine: Option<String>,
}

/// Someone in a chat.
#[derive(Debug, Clone)]
pub struct Member {
    pub user_id: String,
    pub name: String,
    /// "owner", "admin" or "member".
    pub role: String,
    /// When their membership last changed (joined, or renamed) in ms; 0 =
    /// unknown. Used for "새 멤버" limits (a rename restarts the clock,
    /// which only ever makes the limit stricter).
    pub since: u64,
}

/// A person found by ID or name.
#[derive(Debug, Clone)]
pub struct Person {
    pub user_id: String,
    pub name: String,
    /// The 1:1 chat with them, if there is one.
    pub room_id: Option<String>,
}

/// One phone notification, made on the phone after a wake-up.
#[derive(Debug, Clone)]
pub struct Notice {
    pub room_id: String,
    /// Chat name (empty when hidden by the setting).
    pub chat: String,
    /// Sender's name in a group (empty in 1:1 chats or when hidden).
    pub sender: String,
    pub kind: String,
    /// Text (None for photos etc., closed bubbles, view-once, or hidden).
    pub body: Option<String>,
    pub ts: u64,
}

/// One row of the chat list.
#[derive(Debug, Clone)]
pub struct ChatSummary {
    pub room_id: String,
    pub name: String,
    pub is_direct: bool,
    pub encrypted: bool,
    pub unread: u64,
    pub last: Option<Message>,
    /// 1:1 streak (days, 0 = none or switched off) and whether it ends
    /// tonight unless both write.
    pub streak: u32,
    pub streak_at_risk: bool,
    pub pinned: bool,
    pub archived: bool,
    /// No notifications for this chat.
    pub muted: bool,
    /// Only owners and admins post here.
    pub is_channel: bool,
    /// For a 1:1, the other person's ID; for a channel, its owner ("" otherwise).
    pub peer: String,
}

/// Body of a live location message: "📍live:<end ms>".
const LIVE_MARK: &str = "📍live:";

/// Our built-in sticker message: only the sticker's id travels (inside
/// the encrypted message); the picture is already in every app.
pub const STICKER_TYPE: &str = "im.securemessenger.sticker";

/// Field inside a forwarded message (no source is ever recorded).
pub const FORWARDED_FIELD: &str = "im.securemessenger.forwarded";
/// Marks a message sent quietly: the other phones make no sound for it.
pub const SILENT_FIELD: &str = "app.burumy.silent";

/// 부분 인용 / 다른 대화에서 답장 (Telegram tip 399): {"text": picked words,
/// "name": writer (only when it came from another chat)}. Inside the
/// encrypted content, so the server never sees it.
pub const QUOTE_FIELD: &str = "app.burumy.quote";
/// Field inside an encrypted message: who it was sent as (see `post_as`).
pub const AS_FIELD: &str = "app.burumy.as";

/// Keeps only the parts of a "sent as" claim the app understands, so a
/// message can't smuggle anything else through it.
pub fn clean_post_as(v: &serde_json::Value) -> Option<String> {
    if v.get("ch").and_then(serde_json::Value::as_bool) == Some(true) {
        return Some(r#"{"ch":true}"#.into());
    }
    let room = v.get("room")?.as_str()?;
    let addr = v.get("addr").and_then(serde_json::Value::as_str).unwrap_or("");
    if !room.starts_with('!') || room.len() > 255 || addr.len() > 64 {
        return None;
    }
    Some(serde_json::json!({ "room": room, "addr": addr }).to_string())
}
/// Telegram's limit for a quote; names are cut too.
pub const QUOTE_MAX: usize = 1024;
pub const QUOTE_NAME_MAX: usize = 64;

/// The quote's words and writer, cut to the limits; empty words = none.
pub fn read_quote(v: &serde_json::Value) -> (Option<String>, Option<String>) {
    let cut = |s: &str, n: usize| s.chars().take(n).collect::<String>();
    let text = v.get("text").and_then(|x| x.as_str()).map(|t| cut(t.trim(), QUOTE_MAX)).filter(|t| !t.is_empty());
    let name = text.as_ref().and(v.get("name").and_then(|x| x.as_str())).map(|n| cut(n.trim(), QUOTE_NAME_MAX)).filter(|n| !n.is_empty());
    (text, name)
}

/// The quote field to send ([read_quote] reads it back the same way).
pub fn quote_value(text: &str, name: Option<&str>) -> Option<serde_json::Value> {
    let (text, name) = read_quote(&serde_json::json!({ "text": text, "name": name.unwrap_or("") }));
    let mut v = serde_json::json!({ "text": text? });
    if let Some(n) = name {
        v["name"] = n.into();
    }
    Some(v)
}
/// Room-name mark of a 1:1 chat started with an 아이디 키 proof.
pub const ID_KEY_PREFIX: &str = "bk1:";

/// Leave reason when an invitation is turned down by the "contacts only"
/// invitation setting (no other words travel with it).
pub const INVITES_BLOCKED: &str = "app.burumy.invites_blocked";
/// Field inside a photo message: its moving clip (encrypted file, mimetype,
/// size, duration) and how it plays. See [`Live`].
pub const LIVE_FIELD: &str = "im.securemessenger.live";
/// Field inside a photo/video message: can be opened only once.
pub const VIEW_ONCE_FIELD: &str = "im.securemessenger.view_once";
/// Field inside a view-once message meant for the friend's home-screen bubble.
pub const BUBBLE_FIELD: &str = "im.securemessenger.bubble";
/// A story: a photo or video for friends, gone after 24 hours. The value
/// is the story's own id (the same in every 1:1 chat it went to).
pub const STORY_FIELD: &str = "im.securemessenger.story";
pub const STORY_SECONDS: u64 = 24 * 3600;

/// The story id of an event, if it is a story.
fn story_of(e: &matrix_sdk::deserialized_responses::TimelineEvent) -> Option<String> {
    let v = serde_json::from_str::<serde_json::Value>(e.raw().json().get()).ok()?;
    v.get("content")?
        .get(STORY_FIELD)?
        .as_str()
        .map(str::to_owned)
}

/// Live parts of a story (poll, question, plan), as JSON the app reads;
/// sealed inside the same encrypted message as the picture.
pub const STORY_EXTRA_FIELD: &str = "im.securemessenger.story_extra";

/// How long a story may be shown: 6, 12, 24 (default) or 48 hours.
pub fn story_seconds(hours: u32) -> u64 {
    match hours {
        6 | 12 | 48 => u64::from(hours) * 3600,
        _ => STORY_SECONDS,
    }
}

/// A friend-feed post (hours = 0): like a story, but kept until deleted.
/// Same path: inside each 1:1 chat's own encryption, friends only, no ads.
pub const FEED_FIELD: &str = "im.securemessenger.feed";
/// A like on a friend's feed post, sent only into our 1:1 chat: only the
/// poster can count them. Content: {"post": "<story id>"}.
pub const FEED_LIKE_TYPE: &str = "im.securemessenger.feed_like";

fn is_feed(e: &matrix_sdk::deserialized_responses::TimelineEvent) -> bool {
    serde_json::from_str::<serde_json::Value>(e.raw().json().get())
        .ok()
        .and_then(|v| v.get("content")?.get(FEED_FIELD)?.as_bool())
        .unwrap_or(false)
}

/// A like seen in a 1:1 chat (mine or the friend's).
#[derive(Debug, Clone)]
pub struct FeedLike {
    pub post_id: String,
    pub sender: String,
    pub mine: bool,
}

fn story_extra_of(e: &matrix_sdk::deserialized_responses::TimelineEvent) -> Option<String> {
    let v = serde_json::from_str::<serde_json::Value>(e.raw().json().get()).ok()?;
    v.get("content")?
        .get(STORY_EXTRA_FIELD)?
        .as_str()
        .map(str::to_owned)
}

/// Set on a story sent again after a change (tip 393): when it was first
/// posted (ms), so it keeps its place and time.
pub const STORY_TIME_FIELD: &str = "im.securemessenger.story_time";
/// Kept on my profile past its hours (tips 392 / 468 / 534): a small JSON
/// object the app reads (album name, top pin). Sealed like the story.
pub const STORY_PIN_FIELD: &str = "im.securemessenger.story_pin";
/// For a kept story: when it leaves the story row (ms).
pub const STORY_UNTIL_FIELD: &str = "im.securemessenger.story_until";
/// A group's or channel's story (tip 428), posted by an admin into the room
/// itself (inside the room's encryption).
pub const ROOM_STORY_FIELD: &str = "im.securemessenger.room_story";
/// A member's story for one group only (4-app board): any member of a group
/// (not a channel) may post one; only that group's members get it.
pub const MEMBER_STORY_FIELD: &str = "im.securemessenger.member_story";
/// post_stories(room = "members:!id"): a member story into that group.
pub const MEMBER_STORY_PREFIX: &str = "members:";

fn content_of(e: &matrix_sdk::deserialized_responses::TimelineEvent) -> Option<serde_json::Value> {
    let v = serde_json::from_str::<serde_json::Value>(e.raw().json().get()).ok()?;
    v.get("content").cloned()
}

/// A pin JSON from the app: a small object, or nothing.
fn clean_pin(pin: &str) -> Result<Option<serde_json::Value>> {
    if pin.is_empty() {
        return Ok(None);
    }
    anyhow::ensure!(pin.len() <= 512, "pin too big");
    let v: serde_json::Value = serde_json::from_str(pin)?;
    anyhow::ensure!(v.is_object(), "bad pin");
    Ok(Some(v))
}

/// What post_stories sent: how many chats, and the new story ids.
#[derive(Debug, Clone)]
pub struct StoryPosted {
    pub sent: usize,
    pub ids: Vec<String>,
}

/// One story I can see (mine or a friend's), still within its time.
#[derive(Debug, Clone)]
pub struct StoryRef {
    pub story_id: String,
    pub room_id: String,
    pub event_id: String,
    pub sender: String,
    pub mine: bool,
    pub ts: u64,
    /// "image" or "video".
    pub kind: String,
    pub caption: Option<String>,
    /// Poll / question / plan parts (JSON), if any.
    pub extra: Option<String>,
    /// A friend-feed post (no time limit) rather than a story.
    pub feed: bool,
    /// Kept on the profile: the app's pin JSON (album, top), if any.
    pub pin: Option<String>,
    /// When it leaves the story row (ms); 0 for a feed post.
    pub until: u64,
    /// Changed after posting (tip 393).
    pub edited: bool,
    /// A group's or channel's story (tip 428): room_id is that room.
    pub group: bool,
    /// 그룹 전용 스토리 (4-app board, WhatsApp group status): a member's
    /// own story shown only to that group (room_id); sender is the person.
    pub member: bool,
}
/// Event sent (encrypted) when a view-once photo was opened.
pub const OPENED_TYPE: &str = "im.securemessenger.opened";

/// Chat timer change (seconds; 0 = off), shown as a line in the chat.
pub const TIMER_TYPE: &str = "im.securemessenger.timer";
pub const CONTACT_TYPE: &str = "app.burumy.contact";
/// Group/channel switches (state event, readable by members).
pub const ROOM_SWITCHES: &str = "app.burumy.room_switches";
/// Group/channel tool settings (state event, readable by members; only
/// things that may be public to members: rules, welcome, reactions...).
pub const ROOM_CONFIG: &str = "app.burumy.room_config";
/// Group/channel photo, inside the room's encryption (v1 had a plain
/// m.room.avatar; v2 keeps private rooms' photos away from the server).
pub const ROOM_PHOTO_TYPE: &str = "app.burumy.room_photo";

/// Groups and channels: a message may be edited this long after sending
/// (the server refuses later edits too). 1:1 chats have no limit.
pub const EDIT_WINDOW_MS: u64 = 24 * 60 * 60 * 1000;

/// An edit is shown only when it changes words into words.
pub fn edit_accepted(original_kind: &str, edit_kind: &str) -> bool {
    original_kind == "text" && edit_kind == "text"
}

/// 설명 위로 (tip 452), inside the encrypted message.
pub const CAPTION_ABOVE_FIELD: &str = "app.burumy.caption_above";

/// What an edit may change (tips 452 B, 482, 81, 224).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EditKind {
    /// Not shown at all.
    Refused,
    /// Words into words.
    Text,
    /// Only the words with a photo, video or file (the same file).
    Caption,
    /// A new photo, video or file: swapped in, or added to a text.
    Media,
}

fn is_media_kind(k: &str) -> bool {
    matches!(k, "image" | "video" | "file")
}

/// Which edits count. Swapping or adding a photo is never allowed in
/// public groups and channels (`swaps_ok` false): that is how illegal
/// pictures get hidden in old messages there. A caption edit must keep
/// the very same file (`same_file`).
pub fn edit_rule(original_kind: &str, edit_kind: &str, same_file: bool, swaps_ok: bool) -> EditKind {
    match (original_kind, edit_kind) {
        ("text", "text") => EditKind::Text,
        (o, e) if is_media_kind(o) && is_media_kind(e) && same_file && o == e => EditKind::Caption,
        (o, e) if (o == "text" || is_media_kind(o)) && is_media_kind(e) && swaps_ok => EditKind::Media,
        _ => EditKind::Refused,
    }
}

/// The same photo, video or file with new words (the file itself, its
/// key and its name stay).
fn with_caption(t: MessageType, caption: &str) -> Result<MessageType> {
    fn set(body: &mut String, filename: &mut Option<String>, caption: &str) {
        let name = filename.clone().unwrap_or_else(|| body.clone());
        if caption.is_empty() {
            (*body, *filename) = (name, None);
        } else {
            (*body, *filename) = (caption.to_owned(), Some(name));
        }
    }
    Ok(match t {
        MessageType::Image(mut c) => {
            set(&mut c.body, &mut c.filename, caption);
            MessageType::Image(c)
        }
        MessageType::Video(mut c) => {
            set(&mut c.body, &mut c.filename, caption);
            MessageType::Video(c)
        }
        MessageType::File(mut c) => {
            set(&mut c.body, &mut c.filename, caption);
            MessageType::File(c)
        }
        _ => bail!("no photo, video or file in this message"),
    })
}

/// Where the file of a message (or of an edit's new content) is on the server.
fn media_url_of(ev: &matrix_sdk::deserialized_responses::TimelineEvent) -> Option<String> {
    let v: serde_json::Value = ev.raw().deserialize_as().ok()?;
    let c = v.get("content")?;
    let c = c.get("m.new_content").unwrap_or(c);
    c.get("url")
        .or_else(|| c.get("file")?.get("url"))
        .and_then(|u| u.as_str())
        .map(str::to_owned)
}

/// Whether a message sent at `sent_ms` may still be edited.
pub fn edit_window_open(is_group: bool, sent_ms: u64, now_ms: u64) -> bool {
    !is_group || now_ms.saturating_sub(sent_ms) <= EDIT_WINDOW_MS
}

/// Default for "새 멤버 사진·영상·링크 제한" when the owner never set it:
/// on (7 days) in public rooms, off in private ones.
pub const NEW_MEDIA_DAYS_PUBLIC: u64 = 7;

/// Checks one room tool setting: known key, right type, sane size.
/// A list of at most `n` non-empty strings of at most `len` characters.
fn short_list(v: &serde_json::Value, n: usize, len: usize) -> bool {
    matches!(v, serde_json::Value::Array(a) if a.len() <= n && a.iter().all(|x| x.as_str().is_some_and(|s| !s.is_empty() && s.chars().count() <= len)))
}

fn join_question_ok(v: &serde_json::Value) -> bool {
    use serde_json::Value as V;
    match v {
        V::String(s) => !s.trim().is_empty() && s.chars().count() <= 200,
        V::Object(o) => {
            let q_ok = o.get("q").and_then(V::as_str).is_some_and(|s| !s.trim().is_empty() && s.chars().count() <= 200);
            let choices = o.get("choices").and_then(V::as_array);
            let n = choices.map_or(0, Vec::len);
            let c_ok = choices.is_some_and(|c| c.iter().all(|x| x.as_str().is_some_and(|s| !s.trim().is_empty() && s.chars().count() <= 80)));
            let r_ok = o.get("right").and_then(V::as_u64).is_some_and(|r| (r as usize) < n);
            o.len() == 3 && q_ok && (2..=6).contains(&n) && c_ok && r_ok
        }
        _ => false,
    }
}

/// Old room settings that held people's words in plain text (read for old
/// rooms, never written again: welcome and rules now travel encrypted).
pub const PLAIN_TEXT_KEYS: [&str; 2] = ["welcome", "rules"];

pub fn check_room_config(key: &str, v: &serde_json::Value) -> Result<()> {
    use serde_json::Value as V;
    let ok = match key {
        "rules" => v.as_str().is_some_and(|s| s.chars().count() <= 2000),
        "welcome" => v.as_str().is_some_and(|s| s.chars().count() <= 500),
        "rules_agree" | "hide_counts" | "owner_photo" => v.is_boolean(),
        "reactions" => matches!(v.as_str(), Some("all" | "some" | "none")),
        "reactions_set" => {
            matches!(v, V::Array(a) if a.len() <= 24 && a.iter().all(|x| x.as_str().is_some_and(|s| !s.is_empty() && s.len() <= 32)))
        }
        "reactions_max" => v.as_u64().is_some_and(|n| (1..=11).contains(&n)),
        "discussion" => v
            .as_str()
            .is_some_and(|s| s.is_empty() || RoomId::parse(s).is_ok()),
        "old_members" => v.as_u64().is_some_and(|n| n <= 10_000_000),
        // v1 parity (2026-11-27): room switches and lists the app enforces
        // on every phone (the server only checks who may change them).
        "protect" | "raid" | "views" | "subscriber_dm" | "auto_translate" | "no_member_dm"
        | "repeat_mute" => v.is_boolean(),
        // 채널 묶음 #15: 472 작성자 프로필 보이기; 526 a subscriber's message
        // room for a channel (which channel, and who the subscriber is).
        "authors" => v.is_boolean(),
        "channel_dm" => v.as_str().is_some_and(|s| RoomId::parse(s).is_ok()),
        "subscriber" => v.as_str().is_some_and(|s| UserId::parse(s).is_ok()),
        "slow" => v.as_u64().is_some_and(|n| n <= 86_400),
        "post_ttl" => v.as_u64().is_some_and(|n| n <= 31_536_000),
        "type_lock" => short_list(v, 16, 32),
        // Join questions: a string (written answer) or a quiz question
        // {q, choices (2-6), right}. 가입 심사 도우미 (helper) settings.
        "join_questions" => matches!(v, V::Array(a) if a.len() <= 5 && a.iter().all(join_question_ok)),
        "gate" => matches!(v, V::Object(o) if o.len() <= 6 && o.iter().all(|(k, x)| match k.as_str() {
            "on" | "need_answers" | "ai" => x.is_boolean(),
            "words" => short_list(x, 30, 32),
            "about" => x.as_str().is_some_and(|s| s.chars().count() <= 300),
            _ => false,
        })),
        // 야간 모드: {from, to} hours (0-23) + tz (minutes from UTC).
        "night" => matches!(v, V::Object(o) if o.len() <= 3 && o.iter().all(|(k, x)| match k.as_str() {
            "from" | "to" => x.as_u64().is_some_and(|h| h < 24),
            "tz" => x.as_i64().is_some_and(|m| (-1440..=1440).contains(&m)),
            _ => false,
        })),
        "keyword_replies" => matches!(v, V::Array(a) if a.len() <= 30 && a.iter().all(|x| matches!(x, V::Object(o) if o.len() <= 3 && o.values().all(|y| y.as_str().is_some_and(|s| s.chars().count() <= 500))))),
        "member_perms" => matches!(v, V::Object(o) if o.len() <= 16 && o.values().all(|x| x.is_boolean())),
        "admin_rights" => matches!(v, V::Object(o) if o.len() <= 50 && o.iter().all(|(k, x)| UserId::parse(k.as_str()).is_ok() && short_list(x, 16, 32))),
        "tags" => matches!(v, V::Object(o) if o.len() <= 500 && o.iter().all(|(k, x)| UserId::parse(k.as_str()).is_ok() && x.as_str().is_some_and(|s| s.chars().count() <= 16))),
        "mutes" => matches!(v, V::Object(o) if o.len() <= 500 && o.iter().all(|(k, x)| UserId::parse(k.as_str()).is_ok() && x.is_u64())),
        "pin_until" => matches!(v, V::Object(o) if o.len() <= 50 && o.values().all(|x| x.is_u64())),
        "handover" => matches!(v, V::Object(o) if o.len() <= 3 && o.get("to").and_then(|t| t.as_str()).is_some_and(|t| UserId::parse(t).is_ok()) && o.get("until").is_some_and(|t| t.is_u64())),
        // New members can't send photos, videos, files or links for this
        // many days after joining (0 = off).
        "new_media_days" => v.as_u64().is_some_and(|n| n <= 30),
        // Telegram tips batch #16 (groups, 2026-11-27):
        // 내 태그 스스로 달기 (556) and 강력 스팸 차단 (365) switches.
        "own_tags" | "antispam" => v.is_boolean(),
        // 익명 관리자 (94): per admin, the times they were anonymous as
        // [from, to] ms pairs (to 0 = still anonymous). Messages sent in
        // those times show the group's name and photo on every phone.
        "anon" => matches!(v, V::Object(o) if o.len() <= 50 && o.iter().all(|(k, x)| UserId::parse(k.as_str()).is_ok()
            && matches!(x, V::Array(a) if a.len() <= 20 && a.iter().all(|p| matches!(p, V::Array(q) if q.len() == 2 && q.iter().all(|t| t.is_u64())))))),
        // 강력 스팸 차단: people an admin said "스팸 아님" for.
        "spam_ok" => matches!(v, V::Array(a) if a.len() <= 500 && a.iter().all(|x| x.as_str().is_some_and(|u| UserId::parse(u).is_ok()))),
        // Welcome + rules travel end-to-end encrypted (hidden signal); the
        // room keeps only their fingerprint (h, SHA-256 hex of the pack with
        // a random salt) so phones accept the pack only from admins, plus
        // whether each is on.
        "texts" => matches!(v, V::Object(o) if o.len() <= 3
            && o.get("h").and_then(|h| h.as_str()).is_some_and(|h| h.len() == 64 && h.bytes().all(|b| b.is_ascii_hexdigit()))
            && o.iter().all(|(k, x)| k == "h" || ((k == "w" || k == "r") && x.is_boolean()))),
        // 주제 (tip 527): the topic list travels encrypted like "texts";
        // the room keeps only its fingerprint, not even whether topics are on.
        "topics" => matches!(v, V::Object(o) if o.len() == 1
            && o.get("h").and_then(|h| h.as_str()).is_some_and(|h| h.len() == 64 && h.bytes().all(|b| b.is_ascii_hexdigit()))),
        _ => false,
    };
    anyhow::ensure!(ok, "bad room setting");
    Ok(())
}
/// Field inside a message: disappears this many seconds after sending.
pub const TTL_FIELD: &str = "im.securemessenger.ttl";

/// A view-once photo, video or voice clip nobody opened is gone after this
/// many seconds (WhatsApp keeps them 14 days, Snapchat 30; a day is enough
/// for "see it now" and leaves less lying around).
pub const VIEW_ONCE_TTL: u64 = 24 * 60 * 60;

/// The time a message lives: the chat's timer, unless the message already
/// carries a shorter one (a view-once photo in a chat with a 1-week timer
/// still goes after a day). 0 = no timer.
pub fn pick_ttl(message: Option<u64>, chat: u64) -> Option<u64> {
    match (message.filter(|x| *x > 0), chat) {
        (None, 0) => None,
        (None, c) => Some(c),
        (Some(m), 0) => Some(m),
        (Some(m), c) => Some(m.min(c)),
    }
}

#[cfg(test)]
mod view_once_ttl_tests {
    use super::*;
    #[test]
    fn shorter_of_message_and_chat() {
        assert_eq!(pick_ttl(None, 0), None);
        assert_eq!(pick_ttl(None, 60), Some(60));
        assert_eq!(pick_ttl(Some(VIEW_ONCE_TTL), 0), Some(VIEW_ONCE_TTL));
        assert_eq!(pick_ttl(Some(VIEW_ONCE_TTL), 7 * 86400), Some(VIEW_ONCE_TTL));
        assert_eq!(pick_ttl(Some(VIEW_ONCE_TTL), 30), Some(30));
        assert_eq!(pick_ttl(Some(0), 30), Some(30));
    }
}

/// One emoji (with its joiners and skin tones), no letters or digits.
fn status_emoji_ok(e: &str) -> bool {
    e.is_empty()
        || (e.chars().count() <= 10
            && e.len() <= 40
            && !e.chars().any(|c| c.is_alphanumeric() || c.is_whitespace() || c.is_control()))
}

/// A status event's content -> (emoji, until), "" once it is over.
fn read_status(c: &serde_json::Value, now: u64) -> (String, u64) {
    let e = c["e"].as_str().unwrap_or_default();
    let until = c["until"].as_u64().unwrap_or(0);
    if !status_emoji_ok(e) || e.is_empty() || (until != 0 && until <= now) {
        return (String::new(), 0);
    }
    (e.to_owned(), until)
}

fn now_ms() -> u64 {
    matrix_sdk::ruma::MilliSecondsSinceUnixEpoch::now()
        .get()
        .into()
}

/// Settings that stay on this device.
#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
#[serde(default)]
pub struct Prefs {
    /// Show 1:1 streaks (on by default, can be switched off).
    pub streaks: bool,
    /// Chats pinned to the top of the list (in order).
    pub pinned_chats: Vec<String>,
    /// Chats moved to the archive.
    pub archived: Vec<String>,
    /// Link previews switched off (they are on by default).
    pub no_link_previews: bool,
    /// Notifications show only "new message", no name or text.
    pub hide_notice_text: bool,
    /// A call coming in while I talk: "wait" (call waiting, the caller
    /// hears it ring), "missed" (no banner, it rings out to a missed call)
    /// or "busy" (the caller is told I am on a call).
    pub call_waiting: String,
    /// Other on-device switches and choices, by name (screens read them
    /// with a default, so a missing key means "as shipped").
    #[serde(default)]
    pub settings: std::collections::BTreeMap<String, String>,
}

impl Default for Prefs {
    fn default() -> Self {
        Prefs {
            streaks: true,
            pinned_chats: vec![],
            archived: vec![],
            no_link_previews: false,
            hide_notice_text: false,
            call_waiting: "wait".into(),
            settings: Default::default(),
        }
    }
}

/// One logged-in device.
/// Downloads running now, by event id (so the X button can stop one).
static RUNNING_DOWNLOADS: std::sync::LazyLock<
    std::sync::Mutex<std::collections::HashMap<String, futures_util::future::AbortHandle>>,
> = std::sync::LazyLock::new(Default::default);

#[derive(Clone)]
pub struct Engine {
    client: Client,
    /// Who is typing right now, per chat (from sync, never stored).
    typing: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<OwnedRoomId, Vec<String>>>>,
    /// Which password opened the app this time.
    role: std::sync::Arc<std::sync::Mutex<lock::Role>>,
    /// The phone's time zone (minutes from UTC), for streak days.
    tz: std::sync::Arc<std::sync::atomic::AtomicI32>,
    /// Timer lines I sent that may not be back from the server yet.
    sent_timers:
        std::sync::Arc<std::sync::Mutex<std::collections::HashMap<OwnedRoomId, (String, u64)>>>,
    /// My own choices in anonymous polls (kept only on this phone).
    my_votes: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, Vec<String>>>>,
    /// My own card answers (giveaway, form, check-in), kept on this phone.
    my_cards:
        std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, serde_json::Value>>>,
    /// View-once messages I opened whose "opened" mark may not be back yet.
    opened_here: std::sync::Arc<std::sync::Mutex<std::collections::HashSet<String>>>,
    /// Hidden signals waiting for the app (see signal.rs).
    signals: std::sync::Arc<std::sync::Mutex<Vec<signal::Signal>>>,
    /// When this phone last did its community rounds (per community).
    community_rounds: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, u64>>>,
    /// Which rooms are communities (never changes for a room).
    community_kind: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<String, bool>>>,
    /// 보내는 이름 picked per chat (this phone only, set by the app).
    send_as: std::sync::Arc<std::sync::Mutex<std::collections::HashMap<OwnedRoomId, serde_json::Value>>>,
}

/// SDK errors are not thread-safe on the web, so they are turned into
/// plain text errors at the engine edge (same on every platform).
fn to_err(e: impl std::fmt::Display) -> anyhow::Error {
    anyhow!("{e}")
}

mod matrix_sdk_base_crypto_shim {
    pub use matrix_sdk::deserialized_responses::TimelineEventKind;
}

impl Engine {
    /// Opens (or creates) the encrypted local store for one device.
    /// On the web `data_dir` is only a name: the store lives in the
    /// browser's IndexedDB, encrypted with the same passphrase.
    pub async fn open(homeserver: &str, data_dir: &Path, store_passphrase: &str) -> Result<Self> {
        let builder = Client::builder().homeserver_url(homeserver);
        #[cfg(not(target_arch = "wasm32"))]
        let builder = builder.sqlite_store(data_dir, Some(store_passphrase));
        #[cfg(target_arch = "wasm32")]
        let builder = builder.indexeddb_store(&data_dir.to_string_lossy(), Some(store_passphrase));
        let client = builder
            .with_encryption_settings(EncryptionSettings {
                auto_enable_cross_signing: true,
                auto_enable_backups: true,
                backup_download_strategy: BackupDownloadStrategy::AfterDecryptionFailure,
            })
            .build()
            .await
            .map_err(to_err)?;
        // Keep a local copy of every chat on this device (offline reading,
        // fast chat list). It stays inside the encrypted store.
        client.event_cache().subscribe().map_err(to_err)?;
        let typing: std::sync::Arc<
            std::sync::Mutex<std::collections::HashMap<OwnedRoomId, Vec<String>>>,
        > = Default::default();
        let t = typing.clone();
        client.add_event_handler(
            move |ev: matrix_sdk::ruma::events::typing::SyncTypingEvent, room: matrix_sdk::Room| {
                let t = t.clone();
                async move {
                    let ids = ev.content.user_ids.iter().map(|u| u.to_string()).collect();
                    if let Ok(mut m) = t.lock() {
                        m.insert(room.room_id().to_owned(), ids);
                    }
                }
            },
        );
        Ok(Self {
            client,
            typing,
            role: std::sync::Arc::new(std::sync::Mutex::new(lock::Role::Normal)),
            tz: Default::default(),
            sent_timers: Default::default(),
            my_votes: Default::default(),
            my_cards: Default::default(),
            opened_here: Default::default(),
            signals: Default::default(),
            community_rounds: Default::default(),
            community_kind: Default::default(),
            send_as: Default::default(),
        })
    }

    pub fn user_id(&self) -> Option<OwnedUserId> {
        self.client.user_id().map(ToOwned::to_owned)
    }

    pub fn device_id(&self) -> Option<String> {
        self.client.device_id().map(|d| d.to_string())
    }

    /// Creates an account (ID sign-up, no phone or e-mail) and logs in.
    pub async fn register(
        &self,
        username: &str,
        password: &str,
        token: Option<&str>,
    ) -> Result<()> {
        let mut req = RegisterRequest::new();
        req.username = Some(username.to_owned());
        req.password = Some(password.to_owned());
        req.initial_device_display_name = Some("Burumy v2".to_owned());
        // First try: the server tells us which steps it wants.
        match self.client.matrix_auth().register(req.clone()).await {
            Ok(_) => {}
            Err(e) => {
                let uiaa = e
                    .as_uiaa_response()
                    .ok_or_else(|| anyhow!("register: {e}"))?;
                let session = uiaa.session.clone();
                let wants_token = uiaa.flows.iter().any(|f| {
                    f.stages
                        .iter()
                        .any(|s| s.as_str() == "m.login.registration_token")
                });
                req.auth = Some(if wants_token {
                    let mut t = matrix_sdk::ruma::api::client::uiaa::RegistrationToken::new(
                        token.context("server wants an invite code")?.to_owned(),
                    );
                    t.session = session;
                    AuthData::RegistrationToken(t)
                } else {
                    let mut d = Dummy::new();
                    d.session = session;
                    AuthData::Dummy(d)
                });
                self.client
                    .matrix_auth()
                    .register(req)
                    .await
                    .map_err(to_err)?;
            }
        }
        self.after_login(password).await
    }

    /// Logs in as a new device of an existing account.
    pub async fn login(&self, username: &str, password: &str, device_name: &str) -> Result<()> {
        self.client
            .matrix_auth()
            .login_username(username, password)
            .initial_device_display_name(device_name)
            .send()
            .await
            .map_err(to_err)?;
        self.after_login(password).await
    }

    /// QR로 PC 연결: signs in with the one-time token my phone vouched for
    /// (Matrix `m.login.token`). Past chats open after the emoji check or
    /// the 대화 복구 키, like any other new device.
    pub async fn login_token(&self, token: &str, device_name: &str) -> Result<()> {
        self.client
            .matrix_auth()
            .login_token(token)
            .initial_device_display_name(device_name)
            .send()
            .await
            .map_err(to_err)?;
        self.after_login("").await
    }

    async fn after_login(&self, password: &str) -> Result<()> {
        self.sync_once().await.map_err(to_err)?;
        self.client
            .encryption()
            .wait_for_e2ee_initialization_tasks()
            .await;
        // Some servers ask for the password again before the signing keys
        // can be uploaded; do it here if the automatic step was refused.
        // Only a brand-new account makes signing keys. A new device of an
        // existing account must never replace them (it gets them later
        // from the 대화 복구 키 or from an emoji check with an old device).
        {
            let user = self.client.user_id().context("no user")?.to_owned();
            if let Err(e) = self
                .client
                .encryption()
                .bootstrap_cross_signing_if_needed(None)
                .await
            {
                let uiaa = e
                    .as_uiaa_response()
                    .ok_or_else(|| anyhow!("cross-signing: {e}"))?;
                let mut p = Password::new(
                    UserIdentifier::Matrix(
                        matrix_sdk::ruma::api::client::uiaa::MatrixUserIdentifier::new(
                            user.to_string(),
                        ),
                    ),
                    password.to_owned(),
                );
                p.session = uiaa.session.clone();
                self.client
                    .encryption()
                    .bootstrap_cross_signing_if_needed(Some(AuthData::Password(p)))
                    .await
                    .map_err(to_err)?;
            }
        }
        Ok(())
    }

    /// The login to keep in the phone's keychain (never in plain files).
    pub fn session_json(&self) -> Result<String> {
        let s = self
            .client
            .matrix_auth()
            .session()
            .context("not logged in")?;
        Ok(serde_json::to_string(&s)?)
    }

    /// Logs this device back in after the app restarts.
    pub async fn restore(&self, session_json: &str) -> Result<()> {
        let s: matrix_sdk::authentication::matrix::MatrixSession =
            serde_json::from_str(session_json)?;
        self.client.restore_session(s).await.map_err(to_err)?;
        Ok(())
    }

    pub fn is_logged_in(&self) -> bool {
        self.client.matrix_auth().logged_in()
    }

    /// Waits up to `timeout_ms` for anything new (live updates).
    pub async fn sync_wait(&self, timeout_ms: u64) -> Result<()> {
        let r = self
            .client
            .sync_once(SyncSettings::default().timeout(Duration::from_millis(timeout_ms)))
            .await
            .map_err(to_err)?;
        Box::pin(self.on_device_messages(&r.to_device)).await;
        Box::pin(self.on_erase_requests(&r.rooms)).await;
        self.on_signals(&r.rooms);
        Box::pin(self.community_duty(&self.community_rounds.clone())).await;
        Ok(())
    }

    pub async fn sync_once(&self) -> Result<()> {
        let r = self
            .client
            .sync_once(SyncSettings::default().timeout(Duration::from_millis(300)))
            .await
            .map_err(to_err)?;
        Box::pin(self.on_device_messages(&r.to_device)).await;
        Box::pin(self.on_erase_requests(&r.rooms)).await;
        self.on_signals(&r.rooms);
        Box::pin(self.community_duty(&self.community_rounds.clone())).await;
        Ok(())
    }

    /// Encrypted device-to-device messages: anonymous poll votes for polls
    /// I made.
    async fn on_device_messages(
        &self,
        list: &[matrix_sdk::deserialized_responses::ProcessedToDeviceEvent],
    ) {
        use matrix_sdk::deserialized_responses::ProcessedToDeviceEvent;
        for e in list {
            // Only votes that came end-to-end encrypted count.
            let ProcessedToDeviceEvent::Decrypted { raw, .. } = e else {
                continue;
            };
            let Ok(v) = serde_json::from_str::<serde_json::Value>(raw.json().get()) else {
                continue;
            };
            if v["type"].as_str() == Some(community::KEY_MSG) {
                if let Some(sender) = v["sender"].as_str() {
                    if let Err(err) = Box::pin(self.take_community_key(sender, &v["content"])).await {
                        eprintln!("community key skipped: {err}");
                    }
                }
                continue;
            }
            if v["type"].as_str() == Some(mine::DRAFT_MSG) {
                if let Some(sender) = v["sender"].as_str() {
                    if let Err(err) = Box::pin(self.take_draft_message(sender, &v["content"])).await {
                        eprintln!("draft skipped: {err}");
                    }
                }
                continue;
            }
            if v["type"].as_str() == Some(history::HISTORY_MSG) {
                if let Some(sender) = v["sender"].as_str() {
                    if let Err(err) = Box::pin(self.take_history(sender, &v["content"])).await {
                        eprintln!("history pack skipped: {err}");
                    }
                }
                continue;
            }
            if v["type"].as_str() == Some(card::WON) {
                if let (Some(sender), Some(room), Some(cid)) = (
                    v["sender"].as_str(),
                    v["content"]["room"].as_str(),
                    v["content"]["card"].as_str(),
                ) {
                    if let Err(err) = Box::pin(self.take_card_win(room, cid, sender)).await {
                        eprintln!("win message skipped: {err}");
                    }
                }
                continue;
            }
            if v["type"].as_str() == Some(card::REPLY) {
                let (Some(sender), Some(room), Some(cid)) = (
                    v["sender"].as_str(),
                    v["content"]["room"].as_str(),
                    v["content"]["card"].as_str(),
                ) else {
                    continue;
                };
                let answer = v["content"]["answer"].clone();
                if let Err(err) = Box::pin(self.take_card_answer(room, cid, sender, answer)).await {
                    eprintln!("card answer skipped: {err}");
                }
                continue;
            }
            if v["type"].as_str() != Some(poll::VOTE) {
                continue;
            }
            let (Some(sender), Some(room), Some(pid)) = (
                v["sender"].as_str(),
                v["content"]["room"].as_str(),
                v["content"]["poll"].as_str(),
            ) else {
                continue;
            };
            let choices: Vec<String> = v["content"]["choices"]
                .as_array()
                .map(|a| {
                    a.iter()
                        .filter_map(|x| x.as_str().map(str::to_owned))
                        .collect()
                })
                .unwrap_or_default();
            if let Err(err) = Box::pin(self.count_anonymous_vote(room, pid, sender, choices)).await
            {
                eprintln!("poll vote skipped: {err}");
            }
        }
    }

    async fn count_anonymous_vote(
        &self,
        room: &str,
        pid: &str,
        sender: &str,
        mut choices: Vec<String>,
    ) -> Result<()> {
        let room = self
            .client
            .get_room(&RoomId::parse(room).map_err(to_err)?)
            .context("unknown room")?;
        let me = self.client.user_id().context("not logged in")?.to_string();
        let start = self.poll_start(&room, pid).await?;
        anyhow::ensure!(start["sender"].as_str() == Some(me.as_str()), "not my poll");
        anyhow::ensure!(
            start["content"]["anonymous"].as_bool() == Some(true),
            "not anonymous"
        );
        // The voter must be in the chat.
        let uid = <&UserId>::try_from(sender).map_err(to_err)?;
        anyhow::ensure!(
            room.get_member_no_sync(uid)
                .await
                .map_err(to_err)?
                .is_some_and(|m| *m.membership()
                    == matrix_sdk::ruma::events::room::member::MembershipState::Join),
            "voter not in chat"
        );
        // The maker's answers plus the ones members added in time.
        let raws: Vec<serde_json::Value> = match room.event_cache().await {
            Ok((cache, _drop)) => cache
                .events()
                .await
                .unwrap_or_default()
                .iter()
                .filter_map(trusted_json)
                .collect(),
            Err(_) => vec![],
        };
        let mut ids = poll::answer_ids(&raws, pid);
        if ids.is_empty() {
            ids = start["content"]["answers"]
                .as_array()
                .map(|a| {
                    a.iter()
                        .filter_map(|x| x["id"].as_str().map(str::to_owned))
                        .collect()
                })
                .unwrap_or_default();
        }
        choices.retain(|c| ids.contains(c));
        choices.dedup();
        if start["content"]["multiple"].as_bool() != Some(true) {
            choices.truncate(1);
        }
        if self.poll_closed(&room, pid).await
            || poll::past(start["content"]["close_at"].as_u64().unwrap_or(0), now_ms())
        {
            bail!("closed")
        }
        let quiz = start["content"]["quiz"].is_string();
        let locked = quiz || start["content"]["change_vote"].as_bool() == Some(false);
        let hidden = start["content"]["hide_results"].as_bool() == Some(true);
        let key = format!("burumy.pollbook.{pid}");
        let mut book: poll::MakerBook = self
            .client
            .state_store()
            .get_custom_value(key.as_bytes())
            .await
            .map_err(to_err)?
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default();
        if book.salt.is_empty() {
            use rand::Rng;
            book.salt = (0..32)
                .map(|_| format!("{:02x}", rand::thread_rng().r#gen::<u8>()))
                .collect();
        }
        let f = book.fingerprint(sender);
        // A quiz answer (or a poll with changes off) is final.
        if locked && book.votes.get(&f).is_some_and(|c| !c.is_empty()) {
            return Ok(());
        }
        book.votes.insert(f, choices);
        self.client
            .state_store()
            .set_custom_value_no_read(key.as_bytes(), serde_json::to_vec(&book)?)
            .await
            .map_err(to_err)?;
        // Results hidden until the end: no numbers leave this phone yet.
        if hidden {
            return Ok(());
        }
        self.post_tally(&room, pid, &book).await
    }

    async fn post_tally(
        &self,
        room: &matrix_sdk::Room,
        pid: &str,
        book: &poll::MakerBook,
    ) -> Result<()> {
        let (counts, voters) = book.counts();
        room.send_raw(
            poll::TALLY,
            serde_json::json!({ "poll": pid, "counts": counts, "voters": voters }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Anonymous polls with hidden results: once a poll of mine has ended,
    /// my phone posts the final numbers (once).
    async fn post_final_tallies(&self, room: &matrix_sdk::Room, msgs: &[Message]) {
        let now = now_ms();
        for m in msgs.iter().filter(|m| m.mine) {
            let Some(p) = &m.poll else { continue };
            if !(p.anonymous && p.hide_results && (p.closed || poll::past(p.close_at, now))) {
                continue;
            }
            let done = format!("burumy.pollfinal.{}", m.event_id);
            let store = self.client.state_store();
            if store.get_custom_value(done.as_bytes()).await.ok().flatten().is_some() {
                continue;
            }
            let book: poll::MakerBook = store
                .get_custom_value(format!("burumy.pollbook.{}", m.event_id).as_bytes())
                .await
                .ok()
                .flatten()
                .and_then(|b| serde_json::from_slice(&b).ok())
                .unwrap_or_default();
            if self.post_tally(room, &m.event_id, &book).await.is_ok() {
                let _ = store.set_custom_value_no_read(done.as_bytes(), vec![1]).await;
            }
        }
    }

    /// The raw start event of a poll (decrypted).
    async fn poll_start(&self, room: &matrix_sdk::Room, pid: &str) -> Result<serde_json::Value> {
        let eid = <&matrix_sdk::ruma::EventId>::try_from(pid).map_err(to_err)?;
        let ev = room.event(eid, None).await.map_err(to_err)?;
        let v = trusted_json(&ev).context("poll was not end-to-end encrypted")?;
        anyhow::ensure!(v["type"].as_str() == Some(poll::START), "not a poll");
        Ok(v)
    }

    async fn poll_closed(&self, room: &matrix_sdk::Room, pid: &str) -> bool {
        let Ok((cache, _drop)) = room.event_cache().await else {
            return false;
        };
        let events = cache.events().await.unwrap_or_default();
        let maker = self
            .poll_start(room, pid)
            .await
            .ok()
            .and_then(|v| v["sender"].as_str().map(str::to_owned));
        events.iter().filter_map(|e| trusted_json(e)).any(|v| {
            v["type"].as_str() == Some(poll::END)
                && v["content"]["poll"].as_str() == Some(pid)
                && v["sender"].as_str() == maker.as_deref()
        })
    }

    /// Posts a card (FAQ, guide, links, formatted post, giveaway, form,
    /// check-in). The data is checked and trimmed first.
    pub async fn create_card(&self, room_id: &RoomId, kind: &str, data: &str) -> Result<String> {
        let data: serde_json::Value = serde_json::from_str(data)?;
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(
            room.latest_encryption_state()
                .await
                .map_err(to_err)?
                .is_encrypted(),
            "refusing to send into a room without encryption"
        );
        let data = card::sanitize(kind, &data, now_ms())?;
        let mut content =
            serde_json::json!({ "kind": kind, "data": data, "body": card::body(kind, &data) });
        // "알림 없이 고정": the pin line arrives without a sound.
        if kind == "pin" && data["notify"] != serde_json::json!(true) {
            content[SILENT_FIELD] = serde_json::json!(true);
        }
        let r = room
            .send_raw(card::START, { let mut c = content; topic::stamp(room_id.as_str(), &mut c); c })
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    async fn card_start(&self, room: &matrix_sdk::Room, cid: &str) -> Result<serde_json::Value> {
        let eid = <&matrix_sdk::ruma::EventId>::try_from(cid).map_err(to_err)?;
        let ev = room.event(eid, None).await.map_err(to_err)?;
        let v = trusted_json(&ev).context("card was not end-to-end encrypted")?;
        anyhow::ensure!(v["type"].as_str() == Some(card::START), "not a card");
        Ok(v)
    }

    async fn card_book(
        &self,
        cid: &str,
    ) -> Result<std::collections::HashMap<String, serde_json::Value>> {
        let key = format!("burumy.cardbook.{cid}");
        Ok(self
            .client
            .state_store()
            .get_custom_value(key.as_bytes())
            .await
            .map_err(to_err)?
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default())
    }

    async fn save_card_book(
        &self,
        cid: &str,
        book: &std::collections::HashMap<String, serde_json::Value>,
    ) -> Result<()> {
        let key = format!("burumy.cardbook.{cid}");
        self.client
            .state_store()
            .set_custom_value_no_read(key.as_bytes(), serde_json::to_vec(book)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// On the maker's phone: one person's answer (only from a member, only
    /// while open, only a valid answer); then post the new numbers.
    async fn take_card_answer(
        &self,
        room: &str,
        cid: &str,
        sender: &str,
        answer: serde_json::Value,
    ) -> Result<()> {
        let room = self
            .client
            .get_room(&RoomId::parse(room).map_err(to_err)?)
            .context("unknown room")?;
        let me = self.client.user_id().context("not logged in")?.to_string();
        let start = self.card_start(&room, cid).await?;
        anyhow::ensure!(start["sender"].as_str() == Some(me.as_str()), "not my card");
        let kind = start["content"]["kind"]
            .as_str()
            .unwrap_or_default()
            .to_owned();
        anyhow::ensure!(card::answered(&kind), "this card takes no answers");
        let data = card::sanitize(&kind, &start["content"]["data"], 0)?;
        anyhow::ensure!(!card::past(&data, now_ms()), "closed");
        let uid = <&UserId>::try_from(sender).map_err(to_err)?;
        anyhow::ensure!(
            room.get_member_no_sync(uid)
                .await
                .map_err(to_err)?
                .is_some_and(|m| *m.membership()
                    == matrix_sdk::ruma::events::room::member::MembershipState::Join),
            "not in chat"
        );
        let clean = card::clean_reply(&kind, &data, &answer).context("bad answer")?;
        let mut book = self.card_book(cid).await?;
        // Choice flows: a one-way code, never the person's ID.
        let who = card::book_key(&kind, cid, sender);
        anyhow::ensure!(
            book.len() < 100_000 || book.contains_key(&who),
            "too many answers"
        );
        if clean.is_null() {
            book.remove(&who);
        } else {
            book.insert(who, clean);
        }
        self.save_card_book(cid, &book).await?;
        room.send_raw(
            card::TALLY,
            serde_json::json!({ "card": cid, "counts": card::counts(&kind, &book) }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Answers a card: only to the maker's phone(s), end-to-end encrypted.
    pub async fn answer_card(&self, room_id: &RoomId, cid: &str, answer: &str) -> Result<()> {
        let answer: serde_json::Value = serde_json::from_str(answer)?;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.card_start(&room, cid).await?;
        let kind = start["content"]["kind"].as_str().unwrap_or_default();
        anyhow::ensure!(card::answered(kind), "this card takes no answers");
        let data = card::sanitize(kind, &start["content"]["data"], 0)?;
        anyhow::ensure!(!card::past(&data, now_ms()), "closed");
        let clean = card::clean_reply(kind, &data, &answer).context("bad answer")?;
        let maker = start["sender"].as_str().context("no maker")?.to_owned();
        let me = self.client.user_id().context("not logged in")?.to_string();
        if maker == me {
            Box::pin(self.take_card_answer(room_id.as_str(), cid, &me, clean.clone())).await?;
        } else {
            let content =
                serde_json::json!({ "room": room_id.as_str(), "card": cid, "answer": clean });
            self.send_private(&maker, card::REPLY, &content).await?;
        }
        self.remember_card(cid.to_owned(), clean).await
    }

    /// Encrypted device message to all of one person's phones.
    async fn send_private(&self, user: &str, ty: &str, content: &serde_json::Value) -> Result<()> {
        let uid = <&UserId>::try_from(user).map_err(to_err)?;
        let devices = self
            .client
            .encryption()
            .get_user_devices(uid)
            .await
            .map_err(to_err)?;
        let list: Vec<_> = devices.devices().collect();
        anyhow::ensure!(!list.is_empty(), "no devices");
        let raw = matrix_sdk::ruma::serde::Raw::new(content)?.cast_unchecked();
        let failed = self
            .client
            .encryption()
            .encrypt_and_send_raw_to_device(
                list.iter().collect(),
                ty,
                raw,
                matrix_sdk_base::crypto::CollectStrategy::AllDevices,
            )
            .await
            .map_err(to_err)?;
        anyhow::ensure!(failed.len() < list.len(), "could not be delivered");
        Ok(())
    }

    /// Keeps something about a card on this phone only (my answer, "won",
    /// or the maker's private winner list).
    async fn remember_card(&self, key: String, v: serde_json::Value) -> Result<()> {
        let mut mine = self.my_card_answers().await;
        mine.insert(key, v);
        self.client
            .state_store()
            .set_custom_value_no_read(b"burumy.mycards.v1", serde_json::to_vec(&mine)?)
            .await
            .map_err(to_err)?;
        if let Ok(mut g) = self.my_cards.lock() {
            *g = mine;
        }
        Ok(())
    }

    /// A "you won" message: only from the giveaway's maker counts.
    async fn take_card_win(&self, room: &str, cid: &str, sender: &str) -> Result<()> {
        let room = self
            .client
            .get_room(&RoomId::parse(room).map_err(to_err)?)
            .context("unknown room")?;
        let start = self.card_start(&room, cid).await?;
        anyhow::ensure!(
            start["sender"].as_str() == Some(sender),
            "not from the maker"
        );
        anyhow::ensure!(
            start["content"]["kind"].as_str() == Some("lottery"),
            "not a giveaway"
        );
        self.remember_card(format!("won:{cid}"), serde_json::json!(true))
            .await
    }

    async fn my_card_answers(&self) -> std::collections::HashMap<String, serde_json::Value> {
        let m: std::collections::HashMap<String, serde_json::Value> = self
            .client
            .state_store()
            .get_custom_value(b"burumy.mycards.v1")
            .await
            .ok()
            .flatten()
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default();
        if let Ok(mut g) = self.my_cards.lock() {
            *g = m.clone();
        }
        m
    }

    /// Maker only: who answered and what (person, answer as JSON).
    pub async fn card_answers(&self, room_id: &RoomId, cid: &str) -> Result<Vec<(String, String)>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.card_start(&room, cid).await?;
        let me = self.client.user_id().context("not logged in")?.to_string();
        anyhow::ensure!(start["sender"].as_str() == Some(me.as_str()), "not my card");
        // Choice flows show numbers only; there are no names to list.
        anyhow::ensure!(
            start["content"]["kind"].as_str() != Some("flow"),
            "numbers only"
        );
        let mut out: Vec<(String, String)> = self
            .card_book(cid)
            .await?
            .into_iter()
            .map(|(k, v)| (k, v.to_string()))
            .collect();
        out.sort();
        Ok(out)
    }

    /// Maker only: closes a card; a giveaway draws its winners now.
    pub async fn close_card(&self, room_id: &RoomId, cid: &str) -> Result<Vec<String>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.card_start(&room, cid).await?;
        let me = self.client.user_id().context("not logged in")?.to_string();
        anyhow::ensure!(start["sender"].as_str() == Some(me.as_str()), "not my card");
        let kind = start["content"]["kind"].as_str().unwrap_or_default();
        let data = card::sanitize(kind, &start["content"]["data"], 0)?;
        let book = self.card_book(cid).await?;
        if kind != "lottery" {
            room.send_raw(
                card::TALLY,
                serde_json::json!({ "card": cid, "counts": card::counts(kind, &book), "closed": true, "winners": [] }),
            )
            .await
            .map_err(to_err)?;
            return Ok(vec![]);
        }
        // Admins (and I) can never win my own giveaway.
        let pl = room.power_levels().await.map_err(to_err)?;
        let entrants: std::collections::HashMap<String, serde_json::Value> = book
            .iter()
            .filter(|(u, _)| {
                u.as_str() != me
                    && <&UserId>::try_from(u.as_str()).is_ok_and(|uid| {
                        matches!(
                            pl.for_user(uid),
                            matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) if i64::from(i) < 50
                        )
                    })
            })
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect();
        let n = data["winners"].as_u64().unwrap_or(1) as usize;
        let winners = card::draw(&entrants, n, &mut rand::thread_rng());
        let announce = data["announce"].as_bool().unwrap_or(false);
        let mut counts = card::counts(kind, &book);
        counts.insert("won".into(), winners.len() as u32);
        let public: &[String] = if announce { &winners } else { &[] };
        self.remember_card(format!("winners:{cid}"), serde_json::json!(winners))
            .await?;
        room.send_raw(
            card::TALLY,
            serde_json::json!({ "card": cid, "counts": counts, "closed": true, "winners": public }),
        )
        .await
        .map_err(to_err)?;
        if !announce {
            for w in &winners {
                let content = serde_json::json!({ "room": room_id.as_str(), "card": cid });
                if let Err(err) = self.send_private(w, card::WON, &content).await {
                    eprintln!("winner not told: {err}");
                }
            }
        }
        Ok(winners)
    }

    async fn load_my_votes(&self) {
        let cards_empty = self.my_cards.lock().map(|m| m.is_empty()).unwrap_or(false);
        if cards_empty {
            self.my_card_answers().await;
        }
        let empty = self.my_votes.lock().map(|m| m.is_empty()).unwrap_or(false);
        if !empty {
            return;
        }
        if let Ok(Some(b)) = self
            .client
            .state_store()
            .get_custom_value(b"burumy.myvotes.v1")
            .await
        {
            if let (Ok(m), Ok(mut g)) = (
                serde_json::from_slice::<std::collections::HashMap<String, Vec<String>>>(&b),
                self.my_votes.lock(),
            ) {
                *g = m;
            }
        }
    }

    /// Starts a checklist (1-30 items). [others_mark]/[others_add]: other
    /// members may tick / add items too.
    pub async fn create_checklist(
        &self,
        room_id: &RoomId,
        title: &str,
        items: &[String],
        others_mark: bool,
        others_add: bool,
    ) -> Result<String> {
        let room = self.encrypted_room(room_id).await?;
        let title = checklist::clean(title).context("a checklist needs a title")?;
        let items: Vec<String> = items.iter().filter_map(|t| checklist::clean(t)).collect();
        anyhow::ensure!(
            (1..=checklist::MAX_ITEMS).contains(&items.len()),
            "a checklist needs 1-30 items"
        );
        let r = room
            .send_raw(
                checklist::START,
                { let mut c = checklist::start_content(&title, &items, others_mark, others_add); topic::stamp(room_id.as_str(), &mut c); c },
            )
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// Ticks or unticks one item (ignored by everyone if I may not).
    pub async fn mark_checklist(
        &self,
        room_id: &RoomId,
        checklist_id: &str,
        item: &str,
        done: bool,
    ) -> Result<()> {
        let room = self.encrypted_room(room_id).await?;
        room.send_raw(
            checklist::MARK,
            serde_json::json!({ "checklist": checklist_id, "item": item, "done": done }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Adds one item to a checklist (when the maker allowed it).
    pub async fn add_checklist_item(
        &self,
        room_id: &RoomId,
        checklist_id: &str,
        text: &str,
    ) -> Result<()> {
        let room = self.encrypted_room(room_id).await?;
        let text = checklist::clean(text).context("empty item")?;
        room.send_raw(
            checklist::ADD,
            serde_json::json!({ "checklist": checklist_id, "text": text }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Starts a plan: what, when (ms since 1970), until when (0 = open),
    /// and where (optional).
    pub async fn create_meetup(
        &self,
        room_id: &RoomId,
        title: &str,
        starts_at: u64,
        ends_at: u64,
        place: &str,
    ) -> Result<String> {
        let room = self.encrypted_room(room_id).await?;
        let title = meetup::clean(title).context("a plan needs a title")?;
        let place = meetup::clean(place);
        let r = room
            .send_raw(
                meetup::START,
                {
                    let mut c = meetup::start_content(
                        &title,
                        starts_at,
                        (ends_at > 0).then_some(ends_at),
                        place.as_deref(),
                    );
                    topic::stamp(room_id.as_str(), &mut c);
                    c
                },
            )
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// "yes" (or "yes+N" with N guests), "no" or "maybe" ("" takes my
    /// answer back).
    pub async fn answer_meetup(
        &self,
        room_id: &RoomId,
        meetup_id: &str,
        answer: &str,
    ) -> Result<()> {
        anyhow::ensure!(meetup::valid_answer(answer), "unknown answer");
        let room = self.encrypted_room(room_id).await?;
        room.send_raw(
            meetup::ANSWER,
            serde_json::json!({ "meetup": meetup_id, "answer": answer }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Cancels my plan (others' cancels are ignored by every phone).
    pub async fn cancel_meetup(&self, room_id: &RoomId, meetup_id: &str) -> Result<()> {
        let room = self.encrypted_room(room_id).await?;
        room.send_raw(meetup::CANCEL, serde_json::json!({ "meetup": meetup_id }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Shares someone's contact card (their ID and the name I know them by).
    pub async fn send_contact(
        &self,
        room_id: &RoomId,
        user_id: &str,
        name: &str,
    ) -> Result<String> {
        let uid = UserId::parse(user_id).context("bad user id")?;
        let room = self.encrypted_room(room_id).await?;
        let name: String = name.trim().chars().take(64).collect();
        let r = room
            .send_raw(
                CONTACT_TYPE,
                serde_json::json!({ "body": format!("👤 {name}"), "user_id": uid.as_str(), "name": name }),
            )
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// Sends where I am (one point, encrypted). Nothing else about the
    /// place (no address, no map picture) leaves the phone.
    pub async fn send_location(
        &self,
        room_id: &RoomId,
        lat: f64,
        lon: f64,
        accuracy: Option<f64>,
    ) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::LocationMessageEventContent;
        let geo = location::geo_uri(lat, lon, accuracy).context("not a place on Earth")?;
        let room = self.encrypted_room(room_id).await?;
        let content = RoomMessageEventContent::new(MessageType::Location(
            LocationMessageEventContent::new("📍".into(), geo),
        ));
        let r = room.send(content).await.map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// 실시간 위치 (v1): a location message that my phone moves (by editing
    /// it) until `until_ms`. The end time rides in the encrypted body
    /// ("📍live:<ms>"), so only the people in the chat know it is live.
    pub async fn send_live_location(
        &self,
        room_id: &RoomId,
        lat: f64,
        lon: f64,
        accuracy: Option<f64>,
        until_ms: u64,
    ) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::LocationMessageEventContent;
        let geo = location::geo_uri(lat, lon, accuracy).context("not a place on Earth")?;
        anyhow::ensure!(until_ms <= now_ms() + 8 * 3_600_000 + 60_000, "8 hours at most");
        let room = self.encrypted_room(room_id).await?;
        let content = RoomMessageEventContent::new(MessageType::Location(
            LocationMessageEventContent::new(format!("{LIVE_MARK}{until_ms}"), geo),
        ));
        let r = room.send(content).await.map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// Moves my live location (or ends it with `until_ms` = now).
    pub async fn update_live_location(
        &self,
        room_id: &RoomId,
        event_id: &str,
        lat: f64,
        lon: f64,
        accuracy: Option<f64>,
        until_ms: u64,
    ) -> Result<()> {
        use matrix_sdk::ruma::events::room::message::{
            LocationMessageEventContent, ReplacementMetadata,
        };
        let geo = location::geo_uri(lat, lon, accuracy).context("not a place on Earth")?;
        let room = self.encrypted_room(room_id).await?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        let original = room.event(&eid, None).await.map_err(to_err)?;
        let parsed = original.raw().deserialize().map_err(to_err)?;
        anyhow::ensure!(
            Some(parsed.sender()) == self.client.user_id(),
            "only your own messages"
        );
        let content = RoomMessageEventContent::new(MessageType::Location(
            LocationMessageEventContent::new(format!("{LIVE_MARK}{until_ms}"), geo),
        ))
        .make_replacement(ReplacementMetadata::new(eid, None));
        room.send(content).await.map_err(to_err)?;
        Ok(())
    }

    /// The room, only if it is end-to-end encrypted.
    async fn encrypted_room(&self, room_id: &RoomId) -> Result<matrix_sdk::Room> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        Ok(room)
    }

    /// Starts a poll. Channels always get anonymous polls.
    pub async fn create_poll(
        &self,
        room_id: &RoomId,
        question: &str,
        answers: &[String],
        anonymous: bool,
        multiple: bool,
        quiz: Option<u32>,
        explain: &str,
        close_at: u64,
        extra: &str,
        photos: Vec<(String, String, Vec<u8>)>,
    ) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        // Extras follow the answers as the app sent them (blank rows dropped
        // together with their extras).
        let mut extra: serde_json::Value = if extra.trim().is_empty() {
            serde_json::json!({})
        } else {
            serde_json::from_str(extra)?
        };
        let sent: Vec<usize> = (0..answers.len())
            .filter(|i| !answers[*i].trim().is_empty())
            .collect();
        if let Some(list) = extra["answers"].as_array() {
            let kept: Vec<serde_json::Value> = sent
                .iter()
                .map(|i| list.get(*i).cloned().unwrap_or_default())
                .collect();
            extra["answers"] = kept.into();
        }
        let answers: Vec<String> = sent.iter().map(|i| answers[*i].trim().to_owned()).collect();
        anyhow::ensure!(
            answers.iter().all(|a| a.chars().count() <= poll::MAX_ANSWER_TEXT),
            "answer too long"
        );
        anyhow::ensure!(
            extra["description"].as_str().unwrap_or_default().chars().count() <= poll::MAX_DESCRIPTION,
            "description too long"
        );
        anyhow::ensure!(photos.len() <= 1 + poll::MAX_ANSWERS, "too many photos");
        anyhow::ensure!(
            !question.trim().is_empty() && (2..=poll::MAX_ANSWERS).contains(&answers.len()),
            "a poll needs a question and 2-10 answers"
        );
        let quiz = quiz.map(|i| i as usize);
        anyhow::ensure!(
            quiz.is_none_or(|i| i < answers.len()),
            "quiz answer out of range"
        );
        anyhow::ensure!(
            explain.chars().count() <= poll::MAX_EXPLAIN,
            "explanation too long"
        );
        if close_at > 0 {
            let now = now_ms();
            anyhow::ensure!(
                close_at > now + 60_000 && close_at <= now + poll::MAX_DEADLINE_MS,
                "deadline must be 1 minute to 30 days away"
            );
        }
        let channel = self.is_channel(room_id).await;
        let anonymous = anonymous || channel;
        // Subscribers can't post into a channel, so they can't add answers.
        if channel {
            extra["add_options"] = false.into();
        }
        let mut content = poll::start_content_ext(
            question.trim(),
            &answers,
            anonymous,
            multiple,
            quiz,
            explain,
            close_at,
        );
        poll::apply_extras(&mut content, &extra, quiz.is_some());
        // Photos: "q" = under the question, "<n>" = the n-th answer as sent.
        // Each is encrypted on this phone before upload.
        for (slot, mime, data) in photos {
            anyhow::ensure!(mime.starts_with("image/"), "photos only");
            anyhow::ensure!(data.len() <= 20 * 1024 * 1024, "photo too big");
            let target = if slot == "q" {
                None
            } else {
                let n: usize = slot.parse().context("bad photo slot")?;
                let at = sent.iter().position(|i| *i == n).context("photo for a blank answer")?;
                Some(at)
            };
            let mut cursor = std::io::Cursor::new(data);
            let file = self
                .client
                .upload_encrypted_file(&mut cursor)
                .await
                .map_err(to_err)?;
            let media = serde_json::json!({ "file": file, "mimetype": mime });
            match target {
                None => content["media"] = media,
                Some(at) => {
                    let a = &mut content["answers"][at];
                    a["media"] = media;
                    // One attachment per answer: a photo wins.
                    if let Some(o) = a.as_object_mut() {
                        o.remove("sticker");
                        o.remove("geo");
                    }
                }
            }
        }
        let r = room
            .send_raw(poll::START, { let mut c = content; topic::stamp(room_id.as_str(), &mut c); c })
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// A member adds an answer to a poll that allows it.
    pub async fn add_poll_option(&self, room_id: &RoomId, poll_id: &str, text: &str) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.poll_start(&room, poll_id).await?;
        anyhow::ensure!(start["content"]["add_options"].as_bool() == Some(true), "adding answers is off");
        anyhow::ensure!(!self.poll_closed(&room, poll_id).await, "poll closed");
        anyhow::ensure!(
            !poll::past(start["content"]["close_at"].as_u64().unwrap_or(0), now_ms()),
            "poll closed"
        );
        let text = text.trim();
        anyhow::ensure!(
            !text.is_empty() && text.chars().count() <= poll::MAX_ANSWER_TEXT,
            "answer must be 1-100 characters"
        );
        let raws: Vec<serde_json::Value> = match room.event_cache().await {
            Ok((cache, _drop)) => cache.events().await.unwrap_or_default().iter().filter_map(trusted_json).collect(),
            Err(_) => vec![],
        };
        let now = poll::collect(&raws, "", &std::collections::HashMap::new());
        if let Some(p) = now.get(poll_id) {
            anyhow::ensure!(p.answers.len() < poll::MAX_WITH_ADDED, "this poll is full");
            anyhow::ensure!(
                !p.answers.iter().any(|a| a.text.to_lowercase() == text.to_lowercase()),
                "that answer is already there"
            );
        }
        let r = room
            .send_raw(poll::OPTION, serde_json::json!({ "poll": poll_id, "text": text }))
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// The decrypted photo of a poll: `slot` "" = under the question, else
    /// an answer id.
    pub async fn poll_photo(&self, room_id: &RoomId, poll_id: &str, slot: &str) -> Result<Vec<u8>> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.poll_start(&room, poll_id).await?;
        let c = &start["content"];
        let media = if slot.is_empty() {
            c["media"].clone()
        } else {
            c["answers"]
                .as_array()
                .and_then(|a| a.iter().find(|x| x["id"].as_str() == Some(slot)))
                .map(|x| x["media"].clone())
                .unwrap_or_default()
        };
        let file: EncryptedFile = serde_json::from_value(media["file"].clone()).context("no photo")?;
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

    /// Votes (or changes my vote; an empty list takes it back).
    pub async fn vote(&self, room_id: &RoomId, poll_id: &str, choices: &[String]) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.poll_start(&room, poll_id).await?;
        anyhow::ensure!(!self.poll_closed(&room, poll_id).await, "poll closed");
        anyhow::ensure!(
            !poll::past(start["content"]["close_at"].as_u64().unwrap_or(0), now_ms()),
            "poll closed"
        );
        let maker = start["sender"].as_str().context("no maker")?.to_owned();
        if start["content"]["anonymous"].as_bool() != Some(true) {
            room.send_raw(
                poll::VOTE,
                serde_json::json!({ "poll": poll_id, "choices": choices }),
            )
            .await
            .map_err(to_err)?;
            return Ok(());
        }
        // Anonymous: only to the maker's phone(s), end-to-end encrypted.
        let me = self.client.user_id().context("not logged in")?.to_string();
        if maker == me {
            Box::pin(self.count_anonymous_vote(room_id.as_str(), poll_id, &me, choices.to_vec()))
                .await?;
        } else {
            let uid = <&UserId>::try_from(maker.as_str()).map_err(to_err)?;
            let devices = self
                .client
                .encryption()
                .get_user_devices(uid)
                .await
                .map_err(to_err)?;
            let list: Vec<_> = devices.devices().collect();
            anyhow::ensure!(!list.is_empty(), "the poll maker has no devices");
            let content = serde_json::json!({ "room": room_id.as_str(), "poll": poll_id, "choices": choices });
            let raw = matrix_sdk::ruma::serde::Raw::new(&content)?.cast_unchecked();
            let failed = self
                .client
                .encryption()
                .encrypt_and_send_raw_to_device(
                    list.iter().collect(),
                    poll::VOTE,
                    raw,
                    matrix_sdk_base::crypto::CollectStrategy::AllDevices,
                )
                .await
                .map_err(to_err)?;
            anyhow::ensure!(failed.len() < list.len(), "vote could not be delivered");
        }
        self.load_my_votes().await;
        let snapshot = {
            let mut g = self.my_votes.lock().map_err(|_| anyhow::anyhow!("lock"))?;
            g.insert(poll_id.to_owned(), choices.to_vec());
            g.clone()
        };
        self.client
            .state_store()
            .set_custom_value_no_read(b"burumy.myvotes.v1", serde_json::to_vec(&snapshot)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Rings the other side(s): a small encrypted event with a random call
    /// id and a fresh media key. Returns the call id.
    pub async fn start_call(&self, room_id: &RoomId, video: bool) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to call in a room without encryption");
        }
        anyhow::ensure!(!self.is_channel(room_id).await, "no calls in channels");
        use base64::Engine as _;
        let id = call::new_call_id();
        let key = base64::engine::general_purpose::STANDARD.encode(call::new_media_key());
        room.send_raw(
            call::INVITE,
            serde_json::json!({ "call": id, "video": video, "key": key }),
        )
        .await
        .map_err(to_err)?;
        Ok(id)
    }

    pub async fn answer_call(&self, room_id: &RoomId, call_id: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.send_raw(call::ANSWER, serde_json::json!({ "call": call_id }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// reason: "end", "decline" or "busy".
    pub async fn hangup_call(&self, room_id: &RoomId, call_id: &str, reason: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let reason = if ["end", "decline", "busy"].contains(&reason) {
            reason
        } else {
            "end"
        };
        room.send_raw(
            call::HANGUP,
            serde_json::json!({ "call": call_id, "reason": reason }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// The invite event of a call (decrypted), from the local copy.
    async fn call_invite(
        &self,
        room: &matrix_sdk::Room,
        call_id: &str,
    ) -> Result<serde_json::Value> {
        let find = |events: &[matrix_sdk::deserialized_responses::TimelineEvent]| {
            events.iter().filter_map(|e| trusted_json(e)).find(|v| {
                v["type"].as_str() == Some(call::INVITE)
                    && v["content"]["call"].as_str() == Some(call_id)
            })
        };
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        if let Some(v) = find(&cache.events().await.map_err(to_err)?) {
            return Ok(v);
        }
        // Not synced yet (e.g. my own call a moment ago): ask the server.
        let mut opts = MessagesOptions::backward();
        opts.limit = 50u32.into();
        let page = room.messages(opts).await.map_err(to_err)?;
        find(&page.chunk).context("call not found")
    }

    /// Where one call stands now ("ringing", "ongoing", "ended", ...).
    pub async fn call_state(&self, room_id: &RoomId, call_id: &str) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let raws: Vec<serde_json::Value> = cache
            .events()
            .await
            .map_err(to_err)?
            .iter()
            .filter_map(|e| trusted_json(e))
            .collect();
        Ok(call::collect(&raws, now_ms())
            .get(call_id)
            .map(|c| c.1.state.clone())
            .unwrap_or_else(|| "ringing".into()))
    }

    /// Calls ringing for me right now (newest first).
    pub async fn ringing_calls(&self) -> Result<Vec<RingingCall>> {
        let me = self.client.user_id().context("not logged in")?.to_string();
        let now = now_ms();
        let mut out = vec![];
        for room in self.client.joined_rooms() {
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            let events = cache.events().await.unwrap_or_default();
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            if !raws
                .iter()
                .any(|v| v["type"].as_str() == Some(call::INVITE))
            {
                continue;
            }
            for (_, (eid, c)) in call::collect(&raws, now) {
                if c.state != "ringing" {
                    continue;
                }
                let from = raws
                    .iter()
                    .find(|v| v["event_id"].as_str() == Some(eid.as_str()))
                    .and_then(|v| v["sender"].as_str())
                    .unwrap_or_default()
                    .to_owned();
                if from == me {
                    continue;
                }
                out.push(RingingCall {
                    room_id: room.room_id().to_string(),
                    call_id: c.call_id,
                    from,
                    video: c.video,
                    started_at: c.started_at,
                });
            }
        }
        out.sort_by(|a, b| b.started_at.cmp(&a.started_at));
        // Settings > Privacy > Calls: "contacts" lets only my contacts ring
        // me, "nobody" lets no one; the others ring out as missed calls.
        match self
            .prefs()
            .await
            .settings
            .get("who_calls")
            .map(String::as_str)
        {
            Some("nobody") => out.clear(),
            Some("contacts") if !out.is_empty() => {
                let friends: Vec<String> = self
                    .contacts()
                    .await
                    .unwrap_or_default()
                    .into_iter()
                    .map(|p| p.user_id)
                    .collect();
                out.retain(|c| friends.contains(&c.from));
            }
            _ => {}
        }
        Ok(out)
    }

    /// Every call this phone knows about, newest first (Calls tab). Built
    /// only from the encrypted chat events kept on this phone.
    pub async fn call_log(&self, max: usize) -> Result<Vec<CallLogEntry>> {
        let me = self.client.user_id().context("not logged in")?.to_string();
        let now = now_ms();
        let mut out = vec![];
        for room in self.client.joined_rooms() {
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            let events = cache.events().await.unwrap_or_default();
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            for (_, (eid, c)) in call::collect(&raws, now) {
                let from = raws
                    .iter()
                    .find(|v| v["event_id"].as_str() == Some(eid.as_str()))
                    .and_then(|v| v["sender"].as_str())
                    .unwrap_or_default()
                    .to_owned();
                out.push(CallLogEntry {
                    room_id: room.room_id().to_string(),
                    call_id: c.call_id,
                    mine: from == me,
                    from,
                    video: c.video,
                    state: c.state,
                    started_at: c.started_at,
                    answered_at: c.answered_at,
                    ended_at: c.ended_at,
                });
            }
        }
        out.sort_by(|a, b| b.started_at.cmp(&a.started_at));
        out.truncate(max);
        Ok(out)
    }

    /// A short-lived Matrix OpenID token: proves who I am to our own small
    /// services (call pass, trust list) without giving them my login token.
    pub async fn openid_token(&self) -> Result<String> {
        use matrix_sdk::ruma::api::client::account::request_openid_token::v3::Request;
        let me = self.client.user_id().context("not logged in")?.to_owned();
        let t = self.client.send(Request::new(me)).await.map_err(to_err)?;
        Ok(t.access_token)
    }

    /// What the app needs to ask for a call pass itself (used on the web):
    /// a fresh OpenID token, the media key (base64) and whether it is video.
    pub async fn call_ask(
        &self,
        room_id: &RoomId,
        call_id: &str,
    ) -> Result<(String, String, bool)> {
        use matrix_sdk::ruma::api::client::account::request_openid_token::v3::Request;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let invite = self.call_invite(&room, call_id).await?;
        let key = invite["content"]["key"]
            .as_str()
            .context("no media key")?
            .to_owned();
        let video = invite["content"]["video"].as_bool().unwrap_or(false);
        let me = self.client.user_id().context("not logged in")?.to_owned();
        let t = self.client.send(Request::new(me)).await.map_err(to_err)?;
        Ok((t.access_token, key, video))
    }

    /// Asks our call-pass service for a ticket into the call. Proves who I
    /// am with a short-lived Matrix OpenID token (never my login token).
    /// The media key comes from the encrypted invite, not from the service.
    #[cfg(not(target_arch = "wasm32"))]
    pub async fn call_pass(
        &self,
        room_id: &RoomId,
        call_id: &str,
        pass_url: &str,
    ) -> Result<CallPass> {
        let (openid, key, video) = self.call_ask(room_id, call_id).await?;
        let body = serde_json::json!({ "openid_token": openid, "call": call_id, "video": video });
        let r = reqwest::Client::builder()
            .timeout(std::time::Duration::from_secs(10))
            .build()?
            .post(pass_url)
            .header("content-type", "application/json")
            .body(serde_json::to_vec(&body)?)
            .send()
            .await?;
        anyhow::ensure!(r.status().is_success(), "call pass refused: {}", r.status());
        let v: serde_json::Value = serde_json::from_slice(&r.bytes().await?)?;
        Ok(CallPass {
            url: v["url"].as_str().context("no url")?.into(),
            token: v["token"].as_str().context("no token")?.into(),
            media_key: key,
            video,
        })
    }

    /// The maker closes the poll; numbers stay, no more votes.
    pub async fn close_poll(&self, room_id: &RoomId, poll_id: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let start = self.poll_start(&room, poll_id).await?;
        anyhow::ensure!(
            start["sender"].as_str() == self.client.user_id().map(|u| u.as_str()),
            "only the maker can close"
        );
        if start["content"]["anonymous"].as_bool() == Some(true)
            && start["content"]["hide_results"].as_bool() == Some(true)
        {
            let book: poll::MakerBook = self
                .client
                .state_store()
                .get_custom_value(format!("burumy.pollbook.{poll_id}").as_bytes())
                .await
                .map_err(to_err)?
                .and_then(|b| serde_json::from_slice(&b).ok())
                .unwrap_or_default();
            self.post_tally(&room, poll_id, &book).await?;
            let _ = self
                .client
                .state_store()
                .set_custom_value_no_read(format!("burumy.pollfinal.{poll_id}").as_bytes(), vec![1])
                .await;
        }
        room.send_raw(poll::END, serde_json::json!({ "poll": poll_id }))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Turns on the 대화 복구 키: key backup + secret storage. Returns the key.
    pub async fn enable_recovery(&self) -> Result<String> {
        let key = self
            .client
            .encryption()
            .recovery()
            .enable()
            .wait_for_backups_to_upload()
            .await
            .map_err(to_err)?;
        Ok(key)
    }

    /// Opens old messages on a new device with the 대화 복구 키.
    pub async fn recover(&self, recovery_key: &str) -> Result<()> {
        self.client
            .encryption()
            .recovery()
            .recover(recovery_key)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    pub async fn download_keys_for(&self, room_id: &RoomId) -> Result<()> {
        self.client
            .encryption()
            .backups()
            .download_room_keys_for_room(room_id)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// New end-to-end encrypted 1:1 chat.
    pub async fn create_dm(&self, other: &UserId) -> Result<OwnedRoomId> {
        let room = self.client.create_dm(other).await.map_err(to_err)?;
        Ok(room.room_id().to_owned())
    }

    /// New 1:1 chat that carries an 아이디 키 proof (made by the app from the
    /// key the other person gave me). The proof rides in the room name, the
    /// one place an invitation shows before joining; only the invited
    /// person's phone checks it, and chat lists never show it as a name.
    pub async fn create_dm_keyed(&self, other: &UserId, proof: &str) -> Result<OwnedRoomId> {
        if proof.is_empty() {
            return self.create_dm(other).await;
        }
        if !proof.starts_with(ID_KEY_PREFIX) || proof.len() > 64 {
            bail!("bad id key proof");
        }
        use matrix_sdk::ruma::{
            api::client::room::{Visibility, create_room::v3::{Request as CreateRoom, RoomPreset}},
            events::{InitialStateEvent, room::encryption::RoomEncryptionEventContent},
            serde::Raw,
        };
        let mut req = CreateRoom::new();
        req.name = Some(proof.to_owned());
        req.invite = vec![other.to_owned()];
        req.is_direct = true;
        req.preset = Some(RoomPreset::TrustedPrivateChat);
        req.visibility = Visibility::Private;
        req.initial_state = vec![
            Raw::new(&InitialStateEvent::new(
                Default::default(),
                RoomEncryptionEventContent::with_recommended_defaults(),
            ))?
            .cast(),
        ];
        let room = self.client.create_room(req).await.map_err(to_err)?;
        Ok(room.room_id().to_owned())
    }

    pub async fn join(&self, room_id: &RoomId) -> Result<()> {
        self.client.join_room_by_id(room_id).await.map_err(to_err)?;
        Ok(())
    }

    pub fn invited_rooms(&self) -> Vec<OwnedRoomId> {
        self.client
            .invited_rooms()
            .iter()
            .map(|r| r.room_id().to_owned())
            .collect()
    }

    /// Invitations to show (quiet people's invitations are left waiting).
    pub async fn visible_invites(&self) -> Vec<OwnedRoomId> {
        let q = self.quiet_state().await.unwrap_or_default();
        let prefs = self.prefs().await;
        let only_friends = |k: &str| prefs.settings.get(k).is_some_and(|v| v == "contacts");
        let (dm_friends, group_friends) =
            (only_friends("who_messages"), only_friends("who_invites"));
        let friends: Vec<String> = if dm_friends || group_friends {
            self.contacts()
                .await
                .unwrap_or_default()
                .into_iter()
                .map(|p| p.user_id)
                .collect()
        } else {
            vec![]
        };
        let mut out = Vec::new();
        for r in self.client.invited_rooms() {
            let inviter = r
                .invite_details()
                .await
                .ok()
                .map(|d| d.inviter_id.to_string());
            if inviter
                .as_ref()
                .is_some_and(|u| self.is_quiet_user(u, &q) || self.is_stranger(u, &q))
                || self.is_quiet(r.room_id(), &q).await
            {
                continue;
            }
            // "Only my contacts may message / add me": others wait unseen.
            let direct = r.is_direct().await.unwrap_or(false);
            if (if direct { dm_friends } else { group_friends })
                && !inviter.as_ref().is_some_and(|u| friends.contains(u))
            {
                continue;
            }
            out.push(r.room_id().to_owned());
        }
        out
    }

    /// Invitations to show, with who sent them. 1:1 invitations are
    /// joined by the app on its own; group and channel ones wait for a tap.
    pub async fn invitations(&self) -> Vec<Invitation> {
        let mut out = Vec::new();
        for id in self.visible_invites().await {
            // Community invites are taken by the app itself (community.rs).
            if self.is_community(&id).await {
                continue;
            }
            let Some(r) = self.client.get_room(&id) else {
                continue;
            };
            let inviter = r
                .invite_details()
                .await
                .ok()
                .map(|d| d.inviter_id.to_string())
                .unwrap_or_default();
            let direct = r.is_direct().await.unwrap_or(false);
            // Only a name the room really has; the app shows the sender otherwise.
            // A 1:1 invitation passes on its 아이디 키 proof here (the app checks it).
            let name = if direct {
                r.name().filter(|n| n.starts_with(ID_KEY_PREFIX)).unwrap_or_default()
            } else {
                r.name().unwrap_or_default()
            };
            out.push(Invitation {
                room_id: id.to_string(),
                name,
                inviter,
                direct,
            });
        }
        out
    }

    /// Says no to an invitation.
    pub async fn decline(&self, room_id: &RoomId) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.leave().await.map_err(to_err)?;
        Ok(())
    }

    /// Declines a group/channel invitation because "그룹·채널 초대" only lets
    /// my contacts add me. The leave carries a fixed marker (nothing else),
    /// so the room's admins can offer me the invite link instead (tip 385).
    pub async fn decline_blocked(&self, room_id: &RoomId) -> Result<()> {
        use matrix_sdk::ruma::api::client::membership::leave_room;
        let mut req = leave_room::v3::Request::new(room_id.to_owned());
        req.reason = Some(INVITES_BLOCKED.to_owned());
        self.client.send(req).await.map_err(to_err)?;
        Ok(())
    }

    /// People who turned down an invitation to this room because they only
    /// take invitations from contacts (and haven't joined since).
    pub async fn invites_blocked(&self, room_id: &RoomId) -> Vec<String> {
        let Some(room) = self.client.get_room(room_id) else {
            return vec![];
        };
        let me = self.client.user_id().map(|u| u.to_string()).unwrap_or_default();
        let Ok(list) = room
            .get_state_events(matrix_sdk::ruma::events::StateEventType::RoomMember)
            .await
        else {
            return vec![];
        };
        list.iter()
            .filter_map(|r| {
                let s = match r {
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get(),
                    matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => r.json().get(),
                };
                let v: serde_json::Value = serde_json::from_str(s).ok()?;
                let who = v["state_key"].as_str()?;
                (v["content"]["membership"].as_str() == Some("leave")
                    && v["content"]["reason"].as_str() == Some(INVITES_BLOCKED)
                    && v["sender"].as_str() == Some(who)
                    && who != me)
                    .then(|| who.to_owned())
            })
            .collect()
    }

    pub async fn is_encrypted(&self, room_id: &RoomId) -> Result<bool> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        Ok(room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted())
    }

    /// 보내는 이름 (tips 472 + 310): from now on my messages in this chat
    /// say who they are sent as. `as_json` empty = as myself again.
    pub fn set_send_as(&self, room_id: &RoomId, as_json: &str) -> Result<()> {
        let v = if as_json.trim().is_empty() {
            None
        } else {
            let v: serde_json::Value = serde_json::from_str(as_json)?;
            let clean = clean_post_as(&v).context("bad sender")?;
            Some(serde_json::from_str::<serde_json::Value>(&clean)?)
        };
        let mut m = self.send_as.lock().map_err(|_| anyhow!("lock"))?;
        match v {
            Some(v) => m.insert(room_id.to_owned(), v),
            None => m.remove(room_id),
        };
        Ok(())
    }

    pub async fn send_text(&self, room_id: &RoomId, text: &str) -> Result<String> {
        self.send_text_with(room_id, text, false).await
    }

    /// Like [send_text]; `silent` = the other phones make no sound.
    pub async fn send_text_with(
        &self,
        room_id: &RoomId,
        text: &str,
        silent: bool,
    ) -> Result<String> {
        Box::pin(self.send_text_link(room_id, text, silent, &LinkChoice::default())).await
    }

    /// Like [send_text_with], with the sender's link card set-up (tip 400).
    pub async fn send_text_link(
        &self,
        room_id: &RoomId,
        text: &str,
        silent: bool,
        link: &LinkChoice,
    ) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let mut v = serde_json::to_value(RoomMessageEventContent::text_plain(text))?;
        if silent {
            v[SILENT_FIELD] = serde_json::Value::Bool(true);
        }
        Box::pin(self.add_preview(&mut v, text, link)).await;
        let id = Box::pin(self.send_timed_value(&room, v)).await?;
        Box::pin(self.copy_to_web(room_id, &id, text, None)).await;
        Ok(id)
    }

    /// Public channel with its web page on: my new post is also shown on
    /// the web page (the owner turned it on knowing posts leave encryption).
    /// Posts with a chat timer are never copied. Failures only skip it.
    async fn copy_to_web(&self, room_id: &RoomId, id: &str, text: &str, photo: Option<(String, Vec<u8>)>) {
        if !self.room_link(room_id).await.web || Box::pin(self.timer(room_id)).await > 0 {
            return;
        }
        let _ = Box::pin(self.web_post(room_id, id, text, now_ms(), photo)).await;
    }

    /// Puts the link card (if any) into an outgoing text message.
    #[allow(unused_variables)]
    async fn add_preview(&self, v: &mut serde_json::Value, text: &str, link: &LinkChoice) {
        #[cfg(not(target_arch = "wasm32"))]
        if !link.off && !self.prefs().await.no_link_previews {
            if let Some(mut card) = Box::pin(self.make_preview(text, link.url.as_deref())).await {
                if link.above {
                    card["above"] = true.into();
                }
                if link.small && card.get("image").is_some() {
                    card["small"] = true.into();
                }
                v[PREVIEW_FIELD] = card;
            }
        }
    }

    /// Builds the link card on this phone: reads the page, and encrypts its
    /// picture before uploading it. Any failure just sends the text alone.
    /// `pick` = the link the sender chose (must be in the text).
    #[cfg(not(target_arch = "wasm32"))]
    async fn make_preview(&self, text: &str, pick: Option<&str>) -> Option<serde_json::Value> {
        let url = match pick {
            Some(u) if preview::all_links(text).iter().any(|l| l == u) => u.to_owned(),
            _ => preview::first_link(text)?,
        };
        let page = preview::fetch_page(&url).await.ok()?;
        let mut card = serde_json::json!({ "url": page.url, "title": page.title });
        if let Some(d) = page.description {
            card["description"] = d.into();
        }
        card["site"] = page.site.unwrap_or_else(|| preview::host(&url)).into();
        if let Some(img) = page.image_url.filter(|u| preview::check_web(u).is_ok()) {
            if let Ok((mime, data)) = preview::fetch_image(&img).await {
                let mut cursor = std::io::Cursor::new(data);
                if let Ok(file) = self.client.upload_encrypted_file(&mut cursor).await {
                    card["image"] = serde_json::json!({ "file": file, "mimetype": mime });
                }
            }
        }
        Some(card)
    }

    /// The decrypted picture of a message's link card.
    pub async fn preview_image(&self, room_id: &RoomId, event_id: &str) -> Result<Vec<u8>> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
        let ev = room.event(eid, None).await.map_err(to_err)?;
        let v: serde_json::Value = ev.raw().deserialize_as().map_err(to_err)?;
        let file = v
            .get("content")
            .and_then(|c| c.get(PREVIEW_FIELD)?.get("image")?.get("file"))
            .context("no picture")?;
        let file: EncryptedFile = serde_json::from_value(file.clone())?;
        let source = MediaSource::Encrypted(Box::new(file));
        self.client
            .media()
            .get_media_content(
                &MediaRequestParameters {
                    source,
                    format: MediaFormat::File,
                },
                false,
            )
            .await
            .map_err(to_err)
    }

    /// Encrypts bytes on this phone and uploads them; returns the file
    /// reference (place + key) as JSON to put inside an encrypted message.
    /// Used for long posts and their photos.
    pub async fn upload_encrypted(&self, data: Vec<u8>) -> Result<String> {
        anyhow::ensure!(
            !data.is_empty() && data.len() <= 50 * 1024 * 1024,
            "file size"
        );
        let mut cursor = std::io::Cursor::new(data);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        Ok(serde_json::to_string(&file)?)
    }

    /// Downloads and decrypts one file reference that came inside an
    /// encrypted message (a long post or one of its photos).
    pub async fn download_encrypted(&self, file: &str) -> Result<Vec<u8>> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let v: serde_json::Value = serde_json::from_str(file)?;
        let v = article::clean_file(&v).context("bad file reference")?;
        let file: EncryptedFile = serde_json::from_value(v)?;
        self.client
            .media()
            .get_media_content(
                &MediaRequestParameters {
                    source: MediaSource::Encrypted(Box::new(file)),
                    format: MediaFormat::File,
                },
                false,
            )
            .await
            .map_err(to_err)
    }

    /// Opens a long post: its document (from the card, or downloaded and
    /// decrypted), checked again on this phone. Returns JSON.
    pub async fn open_article(&self, room_id: &RoomId, event_id: &str) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let v = self.card_start(&room, event_id).await?;
        anyhow::ensure!(
            v["content"]["kind"].as_str() == Some("article"),
            "not a long post"
        );
        let data = card::sanitize("article", &v["content"]["data"], 0)?;
        if let Some(doc) = data.get("doc") {
            return Ok(doc.to_string());
        }
        let bytes = self.download_encrypted(&data["file"].to_string()).await?;
        Ok(article::open_file(&bytes)?.to_string())
    }

    /// Posts a long post or formatted message. [doc] is the document JSON
    /// whose photos are already uploaded with [upload_encrypted]. A short
    /// one goes inside the encrypted card; a long one is uploaded as an
    /// encrypted file and the card carries its key and a preview.
    pub async fn send_article(&self, room_id: &RoomId, doc: &str) -> Result<String> {
        let doc: serde_json::Value = serde_json::from_str(doc)?;
        let doc = article::clean_doc(&doc)?;
        let raw = doc.to_string();
        let data = if raw.len() <= article::INLINE_MAX {
            serde_json::json!({ "doc": doc })
        } else {
            anyhow::ensure!(raw.len() <= article::MAX_FILE, "document too big");
            let images = doc["blocks"]
                .as_array()
                .map(|b| b.iter().filter(|x| x["t"] == "img").count())
                .unwrap_or(0);
            let file = self.upload_encrypted(raw.clone().into_bytes()).await?;
            serde_json::json!({
                "file": serde_json::from_str::<serde_json::Value>(&file)?,
                "preview": article::preview(&doc),
                "size": raw.len(),
                "chars": article::chars(&doc),
                "images": images,
            })
        };
        self.create_card(room_id, "article", &data.to_string())
            .await
    }

    /// Sends a message, adding the chat's timer (if any) inside the
    /// encrypted content.
    async fn send_timed(
        &self,
        room: &matrix_sdk::Room,
        content: RoomMessageEventContent,
    ) -> Result<String> {
        Box::pin(self.send_timed_with(room, content, false)).await
    }

    async fn send_timed_with(
        &self,
        room: &matrix_sdk::Room,
        content: RoomMessageEventContent,
        view_once: bool,
    ) -> Result<String> {
        let mut v = serde_json::to_value(&content)?;
        if view_once {
            v[VIEW_ONCE_FIELD] = serde_json::Value::Bool(true);
            // 4-app board: unopened, it goes by itself after a day.
            v[TTL_FIELD] = VIEW_ONCE_TTL.into();
        }
        Box::pin(self.send_timed_value(room, v)).await
    }

    async fn send_timed_value(
        &self,
        room: &matrix_sdk::Room,
        mut v: serde_json::Value,
    ) -> Result<String> {
        let ttl = Box::pin(self.timer(room.room_id())).await;
        let set = v.get(TTL_FIELD).and_then(|x| x.as_u64());
        if let Some(t) = pick_ttl(set, ttl) {
            v[TTL_FIELD] = serde_json::Value::from(t);
        }
        topic::stamp(room.room_id().as_str(), &mut v);
        let who = self.send_as.lock().ok().and_then(|m| m.get(room.room_id()).cloned());
        if let Some(a) = who {
            v[AS_FIELD] = a;
        }
        let r = room.send_raw("m.room.message", v).await.map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// Passes a message on to another chat. Photos and files are not
    /// uploaded again: the new message carries the same file key, inside
    /// the new chat's encryption. Only a "forwarded" mark goes along, never
    /// where it came from or who wrote it. View-once photos can't be
    /// forwarded.
    pub async fn forward(&self, from: &RoomId, event_id: &str, to: &RoomId) -> Result<String> {
        let src = self.client.get_room(from).context("unknown room")?;
        let dst = self.client.get_room(to).context("unknown room")?;
        if !dst
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let (cache, _drop) = src.event_cache().await.map_err(to_err)?;
        let mut found = None;
        for _ in 0..20 {
            found = self
                .fold(&cache.events().await.map_err(to_err)?)
                .into_iter()
                .find(|m| m.event_id == event_id);
            if found.is_some()
                || cache
                    .pagination()
                    .run_backwards_once(100)
                    .await
                    .map_err(to_err)?
                    .reached_start
            {
                break;
            }
        }
        let m = match found {
            Some(m) => m,
            None => self
                .fold(&cache.events().await.map_err(to_err)?)
                .into_iter()
                .find(|m| m.event_id == event_id)
                .context("not found")?,
        };
        anyhow::ensure!(!m.view_once, "view-once photos can't be forwarded");
        let mut content = if m.kind == "text" {
            // The latest wording, if it was edited, and its link card.
            let mut v = serde_json::to_value(RoomMessageEventContent::text_plain(
                m.body.clone().unwrap_or_default(),
            ))?;
            let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
            if let Ok(ev) = src.event(eid, None).await {
                let raw: serde_json::Value = ev.raw().deserialize_as().unwrap_or_default();
                if let Some(card) = raw.get("content").and_then(|c| c.get(PREVIEW_FIELD)) {
                    v[PREVIEW_FIELD] = card.clone();
                }
            }
            v
        } else {
            anyhow::ensure!(
                ["image", "video", "audio", "file", "sticker"].contains(&m.kind.as_str()),
                "this message can't be forwarded"
            );
            let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
            let ev = src.event(eid, None).await.map_err(to_err)?;
            let v: serde_json::Value = ev.raw().deserialize_as().map_err(to_err)?;
            v.get("content").cloned().context("no content")?
        };
        if let Some(c) = content.as_object_mut() {
            for k in ["m.relates_to", "m.new_content", TTL_FIELD, VIEW_ONCE_FIELD, AS_FIELD] {
                c.remove(k);
            }
            c.insert(FORWARDED_FIELD.into(), serde_json::Value::Bool(true));
        }
        Box::pin(self.send_timed_value(&dst, content)).await
    }

    /// Finds messages in one chat that contain the words (looked up on this
    /// phone only; the server never sees what you search for). Looks back
    /// through up to `max_events` past events, newest match first.
    pub async fn search(
        &self,
        room_id: &RoomId,
        term: &str,
        max_events: usize,
    ) -> Result<Vec<Message>> {
        let term = term.trim().to_lowercase();
        if term.is_empty() {
            return Ok(vec![]);
        }
        let q = self.quiet_state().await.unwrap_or_default();
        if self.is_quiet(room_id, &q).await {
            return Ok(vec![]);
        }
        // Same rules as 전체 검색: captions too, hidden messages never.
        let mut hits = self
            .search_room(room_id, "text", &term, max_events, &self.unseen(&q))
            .await?;
        hits.reverse();
        Ok(hits)
    }

    /// The chat's current timer in seconds (0 = off): the latest timer line.
    pub async fn timer(&self, room_id: &RoomId) -> u64 {
        let Some(room) = self.client.get_room(room_id) else {
            return 0;
        };
        let Ok((cache, _drop)) = room.event_cache().await else {
            return 0;
        };
        let events = cache.events().await.unwrap_or_default();
        let timers: Vec<Message> = events
            .iter()
            .filter_map(|e| self.to_message(e))
            .filter(|m| m.kind == "timer")
            .collect();
        let sent = self
            .sent_timers
            .lock()
            .ok()
            .and_then(|m| m.get(room_id).cloned());
        if let Some((id, secs)) = sent {
            if !timers.iter().any(|m| m.event_id == id) {
                return secs;
            }
        }
        timers
            .last()
            .and_then(|m| m.body.as_ref()?.parse().ok())
            .unwrap_or(0)
    }

    /// Pins a chat to the top of the list (kept on this device only).
    pub async fn set_chat_pinned(&self, room_id: &RoomId, on: bool) -> Result<()> {
        let mut p = self.prefs().await;
        p.pinned_chats.retain(|r| r != room_id.as_str());
        if on {
            p.pinned_chats.push(room_id.to_string());
        }
        self.set_prefs(&p).await
    }

    /// Moves a chat to the archive (kept on this device only).
    pub async fn set_chat_archived(&self, room_id: &RoomId, on: bool) -> Result<()> {
        let mut p = self.prefs().await;
        p.archived.retain(|r| r != room_id.as_str());
        if on {
            p.archived.push(room_id.to_string());
        }
        self.set_prefs(&p).await
    }

    /// Turns notifications for a chat off (on = muted) or back on.
    pub async fn set_chat_muted(&self, room_id: &RoomId, on: bool) -> Result<()> {
        let ns = self.client.notification_settings().await;
        if on {
            ns.set_room_notification_mode(
                room_id,
                matrix_sdk::notification_settings::RoomNotificationMode::Mute,
            )
            .await
            .map_err(to_err)?;
        } else {
            ns.delete_user_defined_room_rules(room_id)
                .await
                .map_err(to_err)?;
        }
        Ok(())
    }

    /// My shown name (falls back to the ID's first part).
    pub async fn my_name(&self) -> Result<String> {
        let n = self
            .client
            .account()
            .get_display_name()
            .await
            .map_err(to_err)?;
        Ok(n.unwrap_or_else(|| {
            self.client
                .user_id()
                .map(|u| u.localpart().to_owned())
                .unwrap_or_default()
        }))
    }

    pub async fn set_my_name(&self, name: &str) -> Result<()> {
        self.client
            .account()
            .set_display_name(Some(name))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// About me (자기소개). Kept as a profile field on our server, so
    /// everyone who knows my ID can read it (like a name or photo).
    pub async fn set_my_bio(&self, text: &str) -> Result<()> {
        use matrix_sdk::ruma::profile::{ProfileFieldName, ProfileFieldValue};
        let account = self.client.account();
        if text.trim().is_empty() {
            account
                .delete_profile_field(ProfileFieldName::from(BIO_FIELD))
                .await
                .map_err(to_err)?;
        } else {
            let v = ProfileFieldValue::new(
                BIO_FIELD,
                serde_json::Value::String(text.trim().to_owned()),
            )
            .map_err(to_err)?;
            account.set_profile_field(v).await.map_err(to_err)?;
        }
        Ok(())
    }

    /// Someone's about-me text ("" when none or the server can't tell).
    pub async fn bio_of(&self, user_id: &str) -> Result<String> {
        let Ok(user) = OwnedUserId::try_from(user_id) else {
            return Ok(String::new());
        };
        let v = self
            .client
            .account()
            .fetch_profile_field_of(user, BIO_FIELD.into())
            .await;
        Ok(match v {
            Ok(Some(v)) => v.value().as_str().unwrap_or_default().to_owned(),
            _ => String::new(),
        })
    }

    /// My profile photo. Note: profile photos are stored on our server
    /// (like every messenger's), not end-to-end encrypted.
    pub async fn my_photo(&self) -> Result<Option<Vec<u8>>> {
        self.client
            .account()
            .get_avatar(matrix_sdk::media::MediaFormat::File)
            .await
            .map_err(to_err)
    }

    pub async fn set_my_photo(&self, mime: &str, data: Vec<u8>) -> Result<()> {
        // No bytes: take the photo off.
        if data.is_empty() {
            self.client
                .account()
                .set_avatar_url(None)
                .await
                .map_err(to_err)?;
            return Ok(());
        }
        let m: mime::Mime = mime.parse().map_err(to_err)?;
        self.client
            .account()
            .upload_avatar(&m, data)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Shares my photo, about-me and birthday. [who_*]: "everyone" (also on
    /// the public profile), "contacts" (only inside each 1:1 chat's
    /// encryption) or "nobody". [only]: just these chats (new friends);
    /// empty = everything again, public profile included. Returns how many
    /// friends got the card.
    #[allow(clippy::too_many_arguments)]
    pub async fn share_profile(
        &self,
        mime: &str,
        photo: Vec<u8>,
        bio: &str,
        birthday: &str,
        who_photo: &str,
        who_bio: &str,
        who_birthday: &str,
        only: &[String],
    ) -> Result<usize> {
        use matrix_sdk::ruma::profile::{ProfileFieldName, ProfileFieldValue};
        anyhow::ensure!(birthday_ok(birthday), "bad birthday");
        anyhow::ensure!(bio.chars().count() <= 200, "about me too long");
        anyhow::ensure!(photo.is_empty() || mime.starts_with("image/"), "photo only");
        let open = |w: &str| w == "everyone";
        let friends = |w: &str| w == "everyone" || w == "contacts";
        if only.is_empty() {
            if open(who_photo) && !photo.is_empty() {
                self.set_my_photo(mime, photo.clone()).await?;
            } else {
                self.set_my_photo("", vec![]).await?;
            }
            self.set_my_bio(if open(who_bio) { bio } else { "" })
                .await?;
            let account = self.client.account();
            if open(who_birthday) && !birthday.is_empty() {
                let v = ProfileFieldValue::new(
                    BIRTHDAY_FIELD,
                    serde_json::Value::String(birthday.to_owned()),
                )
                .map_err(to_err)?;
                account.set_profile_field(v).await.map_err(to_err)?;
            } else {
                // Nothing there yet is fine.
                let _ = account
                    .delete_profile_field(ProfileFieldName::from(BIRTHDAY_FIELD))
                    .await;
            }
        }
        let quiet = self.quiet_state().await.unwrap_or_default();
        let mut rooms = vec![];
        for room in self.client.joined_rooms() {
            if (only.is_empty() || only.iter().any(|r| r.as_str() == room.room_id().as_str()))
                && room.is_direct().await.unwrap_or(false)
                && !self.is_quiet(room.room_id(), &quiet).await
                && room
                    .latest_encryption_state()
                    .await
                    .map(|e| e.is_encrypted())
                    .unwrap_or(false)
            {
                rooms.push(room);
            }
        }
        if rooms.is_empty() {
            return Ok(0);
        }
        let mut card = serde_json::json!({
            "bio": if friends(who_bio) { bio.trim() } else { "" },
            "birthday": if friends(who_birthday) { birthday } else { "" },
        });
        if friends(who_photo) && !photo.is_empty() {
            let mut cursor = std::io::Cursor::new(photo);
            let file = self
                .client
                .upload_encrypted_file(&mut cursor)
                .await
                .map_err(to_err)?;
            card["photo"] = serde_json::json!({ "file": file, "mimetype": mime });
        }
        let mut sent = 0;
        for room in rooms {
            if room.send_raw(PROFILE_TYPE, card.clone()).await.is_ok() {
                sent += 1;
            }
        }
        Ok(sent)
    }

    /// 이모지 상태: sends my emoji (or "" = none) and when it ends (0 =
    /// until I change it) to every friend's 1:1 chat. Returns how many.
    pub async fn set_emoji_status(&self, emoji: &str, until: u64) -> Result<usize> {
        let emoji = emoji.trim();
        anyhow::ensure!(status_emoji_ok(emoji), "one emoji");
        anyhow::ensure!(until == 0 || until > now_ms(), "already over");
        let quiet = self.quiet_state().await.unwrap_or_default();
        let content = serde_json::json!({ "e": emoji, "until": until });
        let mut sent = 0;
        for room in self.client.joined_rooms() {
            if room.is_direct().await.unwrap_or(false)
                && !self.is_quiet(room.room_id(), &quiet).await
                && room
                    .latest_encryption_state()
                    .await
                    .map(|e| e.is_encrypted())
                    .unwrap_or(false)
                && room.send_raw(STATUS_TYPE, content.clone()).await.is_ok()
            {
                sent += 1;
            }
        }
        Ok(sent)
    }

    /// Someone's emoji status from our 1:1 chat ("" when none or over).
    pub async fn emoji_status_of(&self, user_id: &str) -> Result<(String, u64)> {
        let uid = OwnedUserId::try_from(user_id).map_err(to_err)?;
        let mut best: Option<(u64, serde_json::Value)> = None;
        for room in self.client.joined_rooms() {
            if !room.is_direct().await.unwrap_or(false)
                || !room
                    .direct_targets()
                    .iter()
                    .any(|t| t.as_user_id() == Some(uid.as_ref()))
            {
                continue;
            }
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                // Only what came through the chat's encryption counts.
                let Some(v) = trusted_json(&e) else { continue };
                if v.get("type").and_then(|t| t.as_str()) != Some(STATUS_TYPE)
                    || v.get("sender").and_then(|s| s.as_str()) != Some(user_id)
                {
                    continue;
                }
                let ts = v.get("origin_server_ts").and_then(|t| t.as_u64()).unwrap_or(0);
                if best.as_ref().is_none_or(|(t, _)| ts >= *t) {
                    best = Some((ts, v["content"].clone()));
                }
            }
        }
        Ok(best.map(|(_, c)| read_status(&c, now_ms())).unwrap_or_default())
    }

    /// Someone's photo, about-me and birthday: the newest card they sent
    /// me in our 1:1 chat, else what they made public.
    pub async fn profile_of(&self, user_id: &str) -> Result<ProfileCard> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let uid = OwnedUserId::try_from(user_id).map_err(to_err)?;
        let mut best: Option<(u64, serde_json::Value)> = None;
        for room in self.client.joined_rooms() {
            if !room.is_direct().await.unwrap_or(false)
                || !room
                    .direct_targets()
                    .iter()
                    .any(|t| t.as_user_id() == Some(uid.as_ref()))
            {
                continue;
            }
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                let Ok(v) = serde_json::from_str::<serde_json::Value>(e.raw().json().get()) else {
                    continue;
                };
                if v.get("type").and_then(|t| t.as_str()) != Some(PROFILE_TYPE)
                    || v.get("sender").and_then(|s| s.as_str()) != Some(user_id)
                {
                    continue;
                }
                let ts = v
                    .get("origin_server_ts")
                    .and_then(|t| t.as_u64())
                    .unwrap_or(0);
                if best.as_ref().is_none_or(|(t, _)| ts >= *t) {
                    best = Some((ts, v["content"].clone()));
                }
            }
        }
        if let Some((_, c)) = best {
            let photo = match c.pointer("/photo/file") {
                Some(f) => match serde_json::from_value::<EncryptedFile>(f.clone()) {
                    Ok(file) => self
                        .client
                        .media()
                        .get_media_content(
                            &MediaRequestParameters {
                                source: MediaSource::Encrypted(Box::new(file)),
                                format: MediaFormat::File,
                            },
                            true,
                        )
                        .await
                        .ok(),
                    Err(_) => None,
                },
                None => None,
            };
            let text = |k: &str| {
                c.get(k)
                    .and_then(|x| x.as_str())
                    .unwrap_or_default()
                    .to_owned()
            };
            let birthday = text("birthday");
            return Ok(ProfileCard {
                photo,
                bio: text("bio"),
                birthday: if birthday_ok(&birthday) {
                    birthday
                } else {
                    String::new()
                },
                private: true,
            });
        }
        // Public profile (everyone may see it).
        let account = self.client.account();
        let photo = match account.fetch_user_profile_of(&uid).await {
            Ok(p) => match p
                .get_static::<matrix_sdk::ruma::profile::AvatarUrl>()
                .ok()
                .flatten()
            {
                Some(url) => self
                    .client
                    .media()
                    .get_media_content(
                        &MediaRequestParameters {
                            source: MediaSource::Plain(url),
                            format: MediaFormat::File,
                        },
                        true,
                    )
                    .await
                    .ok(),
                None => None,
            },
            Err(_) => None,
        };
        let birthday = match account
            .fetch_profile_field_of(uid.clone(), BIRTHDAY_FIELD.into())
            .await
        {
            Ok(Some(v)) => v.value().as_str().unwrap_or_default().to_owned(),
            _ => String::new(),
        };
        Ok(ProfileCard {
            photo,
            bio: self.bio_of(user_id).await.unwrap_or_default(),
            birthday: if birthday_ok(&birthday) {
                birthday
            } else {
                String::new()
            },
            private: false,
        })
    }

    /// People in a chat with their role ("owner", "admin" or "member").
    pub async fn members(&self, room_id: &RoomId) -> Result<Vec<Member>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let list = room
            .members(matrix_sdk::RoomMemberships::JOIN)
            .await
            .map_err(to_err)?;
        let mut out: Vec<Member> = list
            .iter()
            .map(|m| {
                let pl = m.power_level();
                let role = match pl {
                    matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Infinite => {
                        "owner"
                    }
                    matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i)
                        if i64::from(i) >= 100 =>
                    {
                        "owner"
                    }
                    matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i)
                        if i64::from(i) >= 50 =>
                    {
                        "admin"
                    }
                    matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i)
                        if i64::from(i) < 0 =>
                    {
                        "muted"
                    }
                    _ => "member",
                };
                Member {
                    user_id: m.user_id().to_string(),
                    name: m
                        .display_name()
                        .map(str::to_owned)
                        .unwrap_or_else(|| m.user_id().localpart().to_owned()),
                    role: role.into(),
                    since: m.event().timestamp().map(u64::from).unwrap_or(0),
                }
            })
            .collect();
        let rank = |r: &str| match r {
            "owner" => 0,
            "admin" => 1,
            _ => 2,
        };
        out.sort_by(|a, b| {
            rank(&a.role)
                .cmp(&rank(&b.role))
                .then(a.name.to_lowercase().cmp(&b.name.to_lowercase()))
        });
        Ok(out)
    }

    /// Leaves a chat and removes it from this device's list.
    pub async fn leave(&self, room_id: &RoomId) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.leave().await.map_err(to_err)?;
        let _ = room.forget().await;
        Ok(())
    }

    /// Sets the chat timer for everyone in the chat (0 = off).
    pub async fn set_timer(&self, room_id: &RoomId, seconds: u64) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let mut data = serde_json::Map::new();
        data.insert("seconds".into(), serde_json::Value::from(seconds));
        let r = room
            .send(RoomMessageEventContent::new(MessageType::new(
                TIMER_TYPE,
                "[timer]".into(),
                data,
            )?))
            .await
            .map_err(to_err)?;
        if let Ok(mut m) = self.sent_timers.lock() {
            m.insert(
                room_id.to_owned(),
                (r.response.event_id.to_string(), seconds),
            );
        }
        Ok(())
    }

    /// Deletes my own messages whose time is up, for everyone. Call now
    /// and then while the app is open. Returns how many were deleted.
    pub async fn run_expiry(&self) -> Result<usize> {
        let now = now_ms();
        let mut n = 0;
        for room in self.client.joined_rooms() {
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            let events = cache.events().await.unwrap_or_default();
            // My view-once photos that were opened: delete them for everyone.
            for m in self.fold(&events) {
                if m.mine && m.view_once && m.opened {
                    let eid = matrix_sdk::ruma::EventId::parse(&m.event_id)?;
                    if room.redact(&eid, None, None).await.is_ok() {
                        n += 1;
                    }
                }
            }
            for e in events {
                let Some(m) = self.to_message(&e) else {
                    continue;
                };
                if m.mine && m.expires_at.is_some_and(|t| t <= now) {
                    let eid = matrix_sdk::ruma::EventId::parse(&m.event_id)?;
                    if room.redact(&eid, None, None).await.is_ok() {
                        n += 1;
                    }
                }
            }
        }
        Ok(n)
    }

    /// Sends a photo or file. In an encrypted chat the file is encrypted on
    /// this device first; the server only stores scrambled bytes.
    pub async fn send_file(
        &self,
        room_id: &RoomId,
        name: &str,
        mime: &str,
        data: Vec<u8>,
    ) -> Result<String> {
        Box::pin(self.send_file_with(room_id, name, mime, data, "")).await
    }

    /// Same, with words under it (shown under the photo, video or file).
    pub async fn send_file_with(
        &self,
        room_id: &RoomId,
        name: &str,
        mime: &str,
        data: Vec<u8>,
        caption: &str,
    ) -> Result<String> {
        anyhow::ensure!(caption.chars().count() <= 4096, "caption too long");
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let photo = (mime.starts_with("image/") && self.room_link(room_id).await.web).then(|| (mime.to_owned(), data.clone()));
        let id = Box::pin(self.send_media(&room, name, mime, data, false, false, caption.trim())).await?;
        if let Some(p) = photo {
            Box::pin(self.copy_to_web(room_id, &id, caption.trim(), Some(p))).await;
        }
        Ok(id)
    }

    /// Same, and with [caption_above] the words show above the photo or
    /// video (설명 위로, tip 452; the mark is inside the encryption).
    pub async fn send_file_opts(
        &self,
        room_id: &RoomId,
        name: &str,
        mime: &str,
        data: Vec<u8>,
        caption: &str,
        caption_above: bool,
    ) -> Result<String> {
        if !caption_above || caption.trim().is_empty() {
            return Box::pin(self.send_file_with(room_id, name, mime, data, caption)).await;
        }
        anyhow::ensure!(caption.chars().count() <= 4096, "caption too long");
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let photo = (mime.starts_with("image/") && self.room_link(room_id).await.web).then(|| (mime.to_owned(), data.clone()));
        let msgtype = Box::pin(self.media_msgtype(name, mime, data, caption.trim())).await?;
        let mut v = serde_json::to_value(RoomMessageEventContent::new(msgtype))?;
        v[CAPTION_ABOVE_FIELD] = true.into();
        let id = Box::pin(self.send_timed_value(&room, v)).await?;
        if let Some(p) = photo {
            Box::pin(self.copy_to_web(room_id, &id, caption.trim(), Some(p))).await;
        }
        Ok(id)
    }

    /// Edits my photo, video or file message (tips 452 B, 482, 81, 224):
    /// new words with it, words above or under, and with [file] (name,
    /// mime, bytes) a new photo, video or file in its place. A text message
    /// can get a photo this way too (the text becomes its words). Swapping
    /// or adding a file is refused in public groups and channels; the
    /// other phones refuse it there as well ([edit_rule]). View-once,
    /// 움직이는 사진 and voice messages can't be edited.
    pub async fn edit_media(
        &self,
        room_id: &RoomId,
        event_id: &str,
        caption: &str,
        caption_above: bool,
        file: Option<(String, String, Vec<u8>)>,
    ) -> Result<()> {
        use matrix_sdk::ruma::events::room::message::ReplacementMetadata;
        anyhow::ensure!(caption.chars().count() <= 4096, "caption too long");
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        let original = room.event(&eid, None).await.map_err(to_err)?;
        let parsed = original.raw().deserialize().map_err(to_err)?;
        anyhow::ensure!(Some(parsed.sender()) == self.client.user_id(), "only your own messages");
        let sent: u64 = parsed.origin_server_ts().get().into();
        let group = self.is_channel(room_id).await || room.joined_members_count() > 2;
        anyhow::ensure!(edit_window_open(group, sent, now_ms()), "edit window closed");
        let raw: serde_json::Value = original.raw().deserialize_as().map_err(to_err)?;
        let c = &raw["content"];
        anyhow::ensure!(
            c.get(VIEW_ONCE_FIELD).is_none() && c.get(LIVE_FIELD).is_none() && c.get(BUBBLE_FIELD).is_none(),
            "this message can't be edited"
        );
        let swaps = self.swaps_ok(&room).await;
        // What the message shows now (a swapped file lives in its edit).
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let mut now = self.fold_rules(&cache.events().await.map_err(to_err)?, swaps, group).into_iter().find(|m| m.event_id == event_id);
        if now.is_none() {
            // Not loaded on this phone yet: ask the server for the recent page.
            now = Box::pin(self.messages(room_id, 100)).await?.into_iter().find(|m| m.event_id == event_id);
        }
        let now = now.context("message not found")?;
        anyhow::ensure!(matches!(now.kind.as_str(), "text" | "image" | "video" | "file"), "this message can't be edited");
        let caption = caption.trim();
        let msgtype = match file {
            Some((name, mime, data)) => {
                anyhow::ensure!(swaps, "photos can't be changed in public groups and channels");
                anyhow::ensure!(!mime.starts_with("audio/"), "voice messages can't be swapped in");
                Box::pin(self.media_msgtype(&name, &mime, data, caption)).await?
            }
            None => {
                anyhow::ensure!(now.kind != "text", "nothing to change");
                let from = now.media_from.clone().unwrap_or_else(|| event_id.to_owned());
                let fid = matrix_sdk::ruma::EventId::parse(&from)?;
                let fev = room.event(&fid, None).await.map_err(to_err)?;
                let AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m))) =
                    fev.raw().deserialize().map_err(to_err)?
                else {
                    bail!("not a message")
                };
                let mt = match m.content.relates_to {
                    Some(matrix_sdk::ruma::events::room::message::Relation::Replacement(r)) => r.new_content.msgtype,
                    _ => m.content.msgtype,
                };
                with_caption(mt, caption)?
            }
        };
        let content = RoomMessageEventContent::new(msgtype).make_replacement(ReplacementMetadata::new(eid, None));
        let mut v = serde_json::to_value(content)?;
        if caption_above && !caption.is_empty() {
            v["m.new_content"][CAPTION_ABOVE_FIELD] = true.into();
            v[CAPTION_ABOVE_FIELD] = true.into();
        }
        room.send_raw("m.room.message", v).await.map_err(to_err)?;
        Ok(())
    }

    /// A voice message: the recording is encrypted on this device first,
    /// with its length and a small loudness picture (waveform) inside the
    /// encrypted message.
    pub async fn send_voice(
        &self,
        room_id: &RoomId,
        mime: &str,
        data: Vec<u8>,
        duration_ms: u64,
        waveform: &[u16],
    ) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::{AudioInfo, AudioMessageEventContent};
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        anyhow::ensure!(mime.starts_with("audio/"), "voice must be audio");
        let size = matrix_sdk::ruma::UInt::new(data.len() as u64);
        let mut cursor = std::io::Cursor::new(data);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        let mut info = AudioInfo::new();
        (info.mimetype, info.size, info.duration) = (
            Some(mime.to_owned()),
            size,
            Some(std::time::Duration::from_millis(duration_ms)),
        );
        let msgtype = MessageType::Audio(
            AudioMessageEventContent::encrypted("voice".into(), file).info(Some(Box::new(info))),
        );
        let mut v = serde_json::to_value(RoomMessageEventContent::new(msgtype))?;
        let bars: Vec<u16> = waveform.iter().take(120).map(|n| (*n).min(1024)).collect();
        v["org.matrix.msc1767.audio"] =
            serde_json::json!({ "duration": duration_ms, "waveform": bars });
        v["org.matrix.msc3245.voice"] = serde_json::json!({});
        Box::pin(self.send_timed_value(&room, v)).await
    }

    /// A photo, video or voice clip (한 번만 듣기, tip 418) that the other
    /// side can open only once.
    pub async fn send_view_once(
        &self,
        room_id: &RoomId,
        name: &str,
        mime: &str,
        data: Vec<u8>,
    ) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        anyhow::ensure!(
            mime.starts_with("image/") || mime.starts_with("video/") || mime.starts_with("audio/"),
            "view once is for photos, videos and voice"
        );
        Box::pin(self.send_media(&room, name, mime, data, true, false, "")).await
    }

    /// 움직이는 사진: the still photo plus its short clip, both encrypted on
    /// this device and uploaded as scrambled bytes; the clip's key, size,
    /// length and play style sit inside the encrypted message. Apps that
    /// don't know the field simply show the still photo.
    #[allow(clippy::too_many_arguments)]
    pub async fn send_live_photo(
        &self,
        room_id: &RoomId,
        name: &str,
        mime: &str,
        data: Vec<u8>,
        video_mime: &str,
        video: Vec<u8>,
        duration_ms: u64,
        style: &str,
        caption: &str,
    ) -> Result<String> {
        use matrix_sdk::ruma::events::room::ImageInfo;
        use matrix_sdk::ruma::events::room::message::ImageMessageEventContent;
        anyhow::ensure!(caption.chars().count() <= 4096, "caption too long");
        anyhow::ensure!(mime.starts_with("image/"), "the still must be a photo");
        anyhow::ensure!(video_mime.starts_with("video/"), "the clip must be a video");
        anyhow::ensure!(!video.is_empty() && video.len() <= LIVE_MAX_BYTES, "clip too big");
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let clip_size = video.len();
        let mut cursor = std::io::Cursor::new(video);
        let clip = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        let photo = self.room_link(room_id).await.web.then(|| (mime.to_owned(), data.clone()));
        let size = matrix_sdk::ruma::UInt::new(data.len() as u64);
        let mut cursor = std::io::Cursor::new(data);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        let caption = caption.trim();
        let mut info = ImageInfo::new();
        (info.mimetype, info.size) = (Some(mime.to_owned()), size);
        let mut image = ImageMessageEventContent::encrypted(
            if caption.is_empty() { name.to_owned() } else { caption.to_owned() },
            file,
        )
        .info(Some(Box::new(info)));
        image.filename = (!caption.is_empty()).then(|| name.to_owned());
        let mut v = serde_json::to_value(RoomMessageEventContent::new(MessageType::Image(image)))?;
        v[LIVE_FIELD] = serde_json::json!({
            "file": clip,
            "mimetype": video_mime,
            "size": clip_size,
            "duration": duration_ms.min(LIVE_MAX_MS),
            "style": live_style(style),
        });
        let id = Box::pin(self.send_timed_value(&room, v)).await?;
        // A public channel's web page gets the still photo only.
        if let Some(p) = photo {
            Box::pin(self.copy_to_web(room_id, &id, caption, Some(p))).await;
        }
        Ok(id)
    }

    /// The decrypted moving clip of a 움직이는 사진 (mimetype, bytes).
    pub async fn live_video(&self, room_id: &RoomId, event_id: &str) -> Result<(String, Vec<u8>)> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
        let ev = room.event(eid, None).await.map_err(to_err)?;
        let v: serde_json::Value = ev.raw().deserialize_as().map_err(to_err)?;
        let live = v
            .get("content")
            .and_then(|c| c.get(LIVE_FIELD))
            .context("no clip")?;
        anyhow::ensure!(
            v.get("content").and_then(|c| c.get(VIEW_ONCE_FIELD)).is_none(),
            "view-once photos stay still"
        );
        let mime = live
            .get("mimetype")
            .and_then(|m| m.as_str())
            .filter(|m| m.starts_with("video/"))
            .unwrap_or("video/mp4")
            .to_owned();
        let file: EncryptedFile = serde_json::from_value(live.get("file").context("no clip")?.clone())?;
        let data = self
            .client
            .media()
            .get_media_content(
                &MediaRequestParameters {
                    source: MediaSource::Encrypted(Box::new(file)),
                    format: MediaFormat::File,
                },
                false,
            )
            .await
            .map_err(to_err)?;
        anyhow::ensure!(data.len() <= LIVE_MAX_BYTES, "clip too big");
        Ok((mime, data))
    }

    /// Encrypts the file on this device, uploads the scrambled bytes, then
    /// sends the message (with the chat timer, and the view-once mark).
    /// Encrypts and uploads a file and makes its message part (photo,
    /// video, audio or file) with the words in [caption].
    async fn media_msgtype(&self, name: &str, mime: &str, data: Vec<u8>, caption: &str) -> Result<MessageType> {
        use matrix_sdk::ruma::events::room::ImageInfo;
        use matrix_sdk::ruma::events::room::message::{
            AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
            ImageMessageEventContent, VideoInfo, VideoMessageEventContent,
        };
        let size = matrix_sdk::ruma::UInt::new(data.len() as u64);
        let mut cursor = std::io::Cursor::new(data);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        // With words: the body carries them and `filename` the name (Matrix
        // media captions); without, the body is the name as before.
        let (n, m) = (
            if caption.is_empty() {
                name.to_owned()
            } else {
                caption.to_owned()
            },
            Some(mime.to_owned()),
        );
        let file_name = (!caption.is_empty()).then(|| name.to_owned());
        let mut msgtype = if mime.starts_with("image/") {
            let mut info = ImageInfo::new();
            (info.mimetype, info.size) = (m, size);
            MessageType::Image(
                ImageMessageEventContent::encrypted(n, file).info(Some(Box::new(info))),
            )
        } else if mime.starts_with("video/") {
            let mut info = VideoInfo::new();
            (info.mimetype, info.size) = (m, size);
            MessageType::Video(
                VideoMessageEventContent::encrypted(n, file).info(Some(Box::new(info))),
            )
        } else if mime.starts_with("audio/") {
            let mut info = AudioInfo::new();
            (info.mimetype, info.size) = (m, size);
            MessageType::Audio(
                AudioMessageEventContent::encrypted(n, file).info(Some(Box::new(info))),
            )
        } else {
            let mut info = FileInfo::new();
            (info.mimetype, info.size) = (m, size);
            MessageType::File(
                FileMessageEventContent::encrypted(n, file).info(Some(Box::new(info))),
            )
        };
        match &mut msgtype {
            MessageType::Image(c) => c.filename = file_name,
            MessageType::Video(c) => c.filename = file_name,
            MessageType::Audio(c) => c.filename = file_name,
            MessageType::File(c) => c.filename = file_name,
            _ => {}
        }
        Ok(msgtype)
    }

    async fn send_media(
        &self,
        room: &matrix_sdk::Room,
        name: &str,
        mime: &str,
        data: Vec<u8>,
        view_once: bool,
        bubble: bool,
        caption: &str,
    ) -> Result<String> {
        let msgtype = Box::pin(self.media_msgtype(name, mime, data, caption)).await?;
        if !bubble {
            return self
                .send_timed_with(room, RoomMessageEventContent::new(msgtype), view_once)
                .await;
        }
        let mut v = serde_json::to_value(RoomMessageEventContent::new(msgtype))?;
        v[VIEW_ONCE_FIELD] = true.into();
        v[BUBBLE_FIELD] = true.into();
        Box::pin(self.send_timed_value(room, v)).await
    }

    /// A Burumy bubble for a friend's home screen: a photo, voice clip or
    /// emoji that opens once. The bubble itself never shows what is inside
    /// (only who sent it); 1:1 chats only.
    pub async fn send_bubble(
        &self,
        room_id: &RoomId,
        kind: &str,
        mime: &str,
        data: Vec<u8>,
    ) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        anyhow::ensure!(
            room.is_direct().await.unwrap_or(false),
            "bubbles are for 1:1 chats"
        );
        match kind {
            "emoji" => {
                let text = String::from_utf8(data)?;
                anyhow::ensure!(
                    !text.trim().is_empty() && text.chars().count() <= 8,
                    "one emoji"
                );
                let mut v = serde_json::to_value(RoomMessageEventContent::text_plain(text.trim()))?;
                v[VIEW_ONCE_FIELD] = true.into();
                v[BUBBLE_FIELD] = true.into();
                Box::pin(self.send_timed_value(&room, v)).await
            }
            "photo" | "voice" => {
                let ok = if kind == "photo" {
                    mime.starts_with("image/") || mime.starts_with("video/")
                } else {
                    mime.starts_with("audio/")
                };
                anyhow::ensure!(ok, "wrong file for this bubble");
                Box::pin(self.send_media(&room, kind, mime, data, true, true, "")).await
            }
            _ => bail!("unknown bubble"),
        }
    }

    /// Posts a story to every 1:1 friend (each copy inside that chat's own
    /// encryption; the photo is uploaded once, scrambled). No view records:
    /// nobody learns who watched. Returns how many friends it went to.
    /// A story to my 1:1 friends: all of them, or only the chats in [only].
    /// [hours] 6 / 12 / 24 / 48. [extra] = live parts (JSON, small).
    pub async fn post_story(
        &self,
        mime: &str,
        data: Vec<u8>,
        caption: &str,
        only: &[String],
        hours: u32,
        extra: &str,
    ) -> Result<usize> {
        Ok(self
            .post_stories(mime, data, caption, only, hours, &[extra.to_owned()], "")
            .await?
            .sent)
    }

    /// The 1:1 chats a story of mine may go to: all friends, or the chats
    /// in [only]; never quiet (hidden) chats or chats without encryption.
    async fn story_rooms(&self, only: &[String]) -> Vec<matrix_sdk::Room> {
        let quiet = self.quiet_state().await.unwrap_or_default();
        let mut rooms = vec![];
        for room in self.client.joined_rooms() {
            if (only.is_empty() || only.iter().any(|r| r.as_str() == room.room_id().as_str()))
                && room.is_direct().await.unwrap_or(false)
                && !self.is_quiet(room.room_id(), &quiet).await
                && room
                    .latest_encryption_state()
                    .await
                    .map(|e| e.is_encrypted())
                    .unwrap_or(false)
            {
                rooms.push(room);
            }
        }
        rooms
    }

    /// Am I an admin (level 50+) of this room?
    async fn am_admin(&self, room: &matrix_sdk::Room) -> bool {
        let Some(me) = self.client.user_id() else {
            return false;
        };
        match room.power_levels().await {
            Ok(pl) => match pl.for_user(me) {
                matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) => i64::from(i) >= 50,
                _ => true,
            },
            Err(_) => false,
        }
    }

    /// The story's picture or video as message content (uploaded once,
    /// encrypted on this phone).
    async fn story_content(&self, mime: &str, data: Vec<u8>, caption: &str) -> Result<serde_json::Value> {
        use matrix_sdk::ruma::events::room::ImageInfo;
        use matrix_sdk::ruma::events::room::message::{
            ImageMessageEventContent, VideoInfo, VideoMessageEventContent,
        };
        anyhow::ensure!(mime.starts_with("image/") || mime.starts_with("video/"), "stories are photos or videos");
        let size = matrix_sdk::ruma::UInt::new(data.len() as u64);
        let mut cursor = std::io::Cursor::new(data);
        let file = self
            .client
            .upload_encrypted_file(&mut cursor)
            .await
            .map_err(to_err)?;
        let caption = caption.trim();
        let body = if caption.is_empty() {
            "story".to_owned()
        } else {
            caption.to_owned()
        };
        let msgtype = if mime.starts_with("image/") {
            let mut info = ImageInfo::new();
            (info.mimetype, info.size) = (Some(mime.to_owned()), size);
            MessageType::Image(
                ImageMessageEventContent::encrypted(body, file).info(Some(Box::new(info))),
            )
        } else {
            let mut info = VideoInfo::new();
            (info.mimetype, info.size) = (Some(mime.to_owned()), size);
            MessageType::Video(
                VideoMessageEventContent::encrypted(body, file).info(Some(Box::new(info))),
            )
        };
        let mut v = serde_json::to_value(RoomMessageEventContent::new(msgtype))?;
        if !caption.is_empty() {
            v["filename"] = "story".into();
        }
        Ok(v)
    }

    /// One upload, several stories (tip 525: a long video in parts, each
    /// part's start / end in its [extras] entry). [room] empty: to my 1:1
    /// friends (all, or [only]); else a group's or channel's story (tip
    /// 428), which only its admins may post. hours 0 = a feed post.
    #[allow(clippy::too_many_arguments)]
    pub async fn post_stories(
        &self,
        mime: &str,
        data: Vec<u8>,
        caption: &str,
        only: &[String],
        hours: u32,
        extras: &[String],
        room: &str,
    ) -> Result<StoryPosted> {
        // hours = 0: a feed post, which may also be words only (mime "").
        let feed = hours == 0;
        anyhow::ensure!(
            mime.starts_with("image/") || mime.starts_with("video/") || (feed && mime.is_empty()),
            "stories are photos or videos"
        );
        anyhow::ensure!(
            !mime.is_empty() || !caption.trim().is_empty(),
            "nothing to post"
        );
        anyhow::ensure!(caption.chars().count() <= 2048, "caption too long");
        anyhow::ensure!(extras.len() <= 10, "too many parts");
        // Live parts (polls, weather, place, link cards with a small picture).
        for extra in extras {
            anyhow::ensure!(extra.len() <= 24576, "story parts too big");
            if !extra.is_empty() {
                serde_json::from_str::<serde_json::Value>(extra)?;
            }
        }
        let empty = [String::new()];
        let extras = if extras.is_empty() { &empty[..] } else { extras };
        let (room, member) = match room.strip_prefix(MEMBER_STORY_PREFIX) {
            Some(r) => (r, true),
            None => (room, false),
        };
        let rooms = if room.is_empty() {
            let rooms = self.story_rooms(only).await;
            anyhow::ensure!(!rooms.is_empty(), "no friends yet");
            rooms
        } else {
            anyhow::ensure!(!feed, "rooms have no feed");
            let id = RoomId::parse(room).context("bad room")?;
            let r = self.client.get_room(&id).context("unknown room")?;
            anyhow::ensure!(!r.is_direct().await.unwrap_or(false), "not a group");
            if member {
                anyhow::ensure!(!self.is_channel(r.room_id()).await, "channels have no member stories");
                anyhow::ensure!(
                    r.latest_encryption_state().await.map(|e| e.is_encrypted()).unwrap_or(false),
                    "refusing to post into a room without encryption"
                );
            } else {
                anyhow::ensure!(self.am_admin(&r).await, "only admins post the room's story");
            }
            vec![r]
        };
        let mut v = if mime.is_empty() {
            serde_json::to_value(RoomMessageEventContent::text_plain(caption.trim()))?
        } else {
            self.story_content(mime, data, caption).await?
        };
        if feed {
            v[FEED_FIELD] = true.into();
        } else {
            v[TTL_FIELD] = story_seconds(hours).into();
        }
        if !room.is_empty() {
            v[ROOM_STORY_FIELD] = true.into();
        }
        if member {
            v[MEMBER_STORY_FIELD] = true.into();
        }
        let mut ids = vec![];
        let mut sent = 0;
        for extra in extras {
            let id = call::new_call_id();
            let mut v = v.clone();
            v[STORY_FIELD] = id.clone().into();
            if !extra.is_empty() {
                v[STORY_EXTRA_FIELD] = extra.clone().into();
            }
            let mut n = 0;
            for room in &rooms {
                if room.send_raw("m.room.message", v.clone()).await.is_ok() {
                    n += 1;
                }
            }
            if n > 0 {
                ids.push(id);
                sent = sent.max(n);
            }
        }
        anyhow::ensure!(sent > 0, "story not sent");
        Ok(StoryPosted { sent, ids })
    }

    /// My copies of one story: (room, event id, origin time, content).
    async fn my_story_copies(&self, story_id: &str) -> Vec<(matrix_sdk::Room, String, u64, serde_json::Value)> {
        let me = self
            .client
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default();
        let mut out = vec![];
        for room in self.client.joined_rooms() {
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                if story_of(&e).as_deref() != Some(story_id) {
                    continue;
                }
                let Ok(v) = serde_json::from_str::<serde_json::Value>(e.raw().json().get()) else {
                    continue;
                };
                if v.get("sender").and_then(|x| x.as_str()) != Some(me.as_str()) {
                    continue;
                }
                let (Some(eid), Some(ts), Some(c)) = (
                    v.get("event_id").and_then(|x| x.as_str()),
                    v.get("origin_server_ts").and_then(|x| x.as_u64()),
                    v.get("content"),
                ) else {
                    continue;
                };
                // A redacted copy has no picture any more.
                if c.get("msgtype").is_none() {
                    continue;
                }
                out.push((room.clone(), eid.to_owned(), ts, c.clone()));
            }
        }
        out
    }

    /// Changes a story I posted (tip 393), or keeps it on my profile past
    /// its hours (tips 392 / 468 / 534). Each chat gets a new copy with the
    /// same story id and first time; the older copies are taken back. New
    /// [data] (with [mime]) replaces the picture; empty keeps it. [only]
    /// as in post_story (a group's story stays in its room). [pin] = the
    /// app's pin JSON ("" = not kept: the story leaves at its first end).
    /// Chats left out of [only] lose the story. Returns how many chats.
    #[allow(clippy::too_many_arguments)]
    pub async fn edit_story(
        &self,
        story_id: &str,
        mime: &str,
        data: Vec<u8>,
        caption: &str,
        extra: &str,
        only: &[String],
        pin: &str,
    ) -> Result<usize> {
        anyhow::ensure!(caption.chars().count() <= 2048, "caption too long");
        anyhow::ensure!(extra.len() <= 24576, "story parts too big");
        if !extra.is_empty() {
            serde_json::from_str::<serde_json::Value>(extra)?;
        }
        let pin = clean_pin(pin)?;
        let copies = self.my_story_copies(story_id).await;
        let (_, _, base_ts, base) = copies
            .iter()
            .max_by_key(|c| c.2)
            .cloned()
            .context("no such story")?;
        anyhow::ensure!(base.get(FEED_FIELD).is_none(), "feed posts are not stories");
        let first = base
            .get(STORY_TIME_FIELD)
            .and_then(|x| x.as_u64())
            .unwrap_or_else(|| copies.iter().map(|c| c.2).min().unwrap_or(base_ts));
        let ends = match base.get(STORY_UNTIL_FIELD).and_then(|x| x.as_u64()) {
            Some(t) if base.get(STORY_PIN_FIELD).is_some() => t,
            _ => base_ts.saturating_add(
                base.get(TTL_FIELD)
                    .and_then(|x| x.as_u64())
                    .unwrap_or(STORY_SECONDS)
                    .saturating_mul(1000),
            ),
        };
        let now = now_ms();
        let group = base.get(ROOM_STORY_FIELD).is_some();
        let mut v = if data.is_empty() {
            let mut v = base.clone();
            let caption = caption.trim();
            v["body"] = if caption.is_empty() { "story" } else { caption }.into();
            if caption.is_empty() {
                if let Some(o) = v.as_object_mut() {
                    o.remove("filename");
                }
            } else {
                v["filename"] = "story".into();
            }
            v
        } else {
            let mut v = self.story_content(mime, data, caption).await?;
            for k in [ROOM_STORY_FIELD, MEMBER_STORY_FIELD] {
                if let Some(x) = base.get(k) {
                    v[k] = x.clone();
                }
            }
            v
        };
        if let Some(o) = v.as_object_mut() {
            for k in ["m.relates_to", "m.new_content", STORY_EXTRA_FIELD, TTL_FIELD, STORY_PIN_FIELD, STORY_UNTIL_FIELD] {
                o.remove(k);
            }
        }
        v[STORY_FIELD] = story_id.into();
        v[STORY_TIME_FIELD] = first.into();
        if !extra.is_empty() {
            v[STORY_EXTRA_FIELD] = extra.into();
        }
        match pin {
            Some(p) => {
                v[STORY_PIN_FIELD] = p;
                v[STORY_UNTIL_FIELD] = ends.into();
            }
            None => {
                anyhow::ensure!(now < ends, "story ended");
                v[TTL_FIELD] = ends.saturating_sub(now).div_ceil(1000).max(1).into();
            }
        }
        // Where it goes now.
        let targets: Vec<matrix_sdk::Room> = if group {
            let mut seen: Vec<matrix_sdk::Room> = vec![];
            for (r, ..) in &copies {
                if !seen.iter().any(|x| x.room_id() == r.room_id()) && self.am_admin(r).await {
                    seen.push(r.clone());
                }
            }
            seen
        } else {
            self.story_rooms(only).await
        };
        anyhow::ensure!(!targets.is_empty(), "no friends yet");
        let mut sent = 0;
        for room in &targets {
            if room.send_raw("m.room.message", v.clone()).await.is_ok() {
                sent += 1;
                // Take back the older copies in this chat.
                for (r, eid, ..) in &copies {
                    if r.room_id() == room.room_id()
                        && let Ok(eid) = matrix_sdk::ruma::OwnedEventId::try_from(eid.as_str())
                    {
                        let _ = room.redact(&eid, None, None).await;
                    }
                }
            }
        }
        anyhow::ensure!(sent > 0, "story not sent");
        // Chats no longer chosen lose it.
        for (r, eid, ..) in &copies {
            if !targets.iter().any(|t| t.room_id() == r.room_id())
                && let Ok(eid) = matrix_sdk::ruma::OwnedEventId::try_from(eid.as_str())
            {
                let _ = r.redact(&eid, None, None).await;
            }
        }
        Ok(sent)
    }

    /// Stories I can see, oldest first: mine once (not once per friend),
    /// each friend's, and my groups' (admins' only). Within their hours, or
    /// kept on a profile ([StoryRef::pin]). A changed story shows its
    /// newest copy, at its first time.
    pub async fn stories(&self) -> Result<Vec<StoryRef>> {
        let quiet = self.quiet_state().await.unwrap_or_default();
        let me = self
            .client
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default();
        let now = now_ms();
        // (story id, sender, event time, room, event, group)
        let mut latest: Vec<(String, String, u64, String, matrix_sdk::deserialized_responses::TimelineEvent, bool)> = vec![];
        for room in self.client.joined_rooms() {
            if self.is_quiet(room.room_id(), &quiet).await {
                continue;
            }
            let direct = room.is_direct().await.unwrap_or(false);
            // Groups and channels: only their admins' stories count.
            let pl = if direct { None } else { room.power_levels().await.ok() };
            if !direct && pl.is_none() {
                continue;
            }
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                let Some(id) = story_of(&e) else { continue };
                let Ok(v) = serde_json::from_str::<serde_json::Value>(e.raw().json().get()) else {
                    continue;
                };
                let (Some(sender), Some(ts)) = (
                    v.get("sender").and_then(|x| x.as_str()),
                    v.get("origin_server_ts").and_then(|x| x.as_u64()),
                ) else {
                    continue;
                };
                let group = v.pointer(&format!("/content/{ROOM_STORY_FIELD}")).is_some();
                if direct == group {
                    continue;
                }
                // A member's group-only story: any member may post one in a
                // group, never in a channel (there only admins speak).
                let member = group && v.pointer(&format!("/content/{MEMBER_STORY_FIELD}")).is_some();
                if member && self.is_channel(room.room_id()).await {
                    continue;
                }
                if let Some(pl) = pl.as_ref().filter(|_| !member) {
                    let admin = <&UserId>::try_from(sender).is_ok_and(|u| match pl.for_user(u) {
                        matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) => i64::from(i) >= 50,
                        _ => true,
                    });
                    if !admin {
                        continue;
                    }
                }
                let room_id = room.room_id().to_string();
                // Group stories are told apart by room too; 1:1 ones by person.
                match latest
                    .iter_mut()
                    .find(|x| x.0 == id && x.1 == sender && x.5 == group && (!group || x.3 == room_id))
                {
                    Some(x) if x.2 >= ts => {}
                    Some(x) => *x = (id, sender.to_owned(), ts, room_id, e, group),
                    None => latest.push((id, sender.to_owned(), ts, room_id, e, group)),
                }
            }
        }
        let mut out: Vec<StoryRef> = vec![];
        for (id, _, _, room_id, e, group) in latest {
            let extra = story_extra_of(&e);
            let feed = is_feed(&e);
            let c = content_of(&e).unwrap_or_default();
            let Some(m) = self.to_message(&e) else {
                continue;
            };
            let pin = c
                .get(STORY_PIN_FIELD)
                .filter(|p| p.is_object())
                .map(|p| p.to_string());
            let until = if feed {
                0
            } else if pin.is_some() {
                c.get(STORY_UNTIL_FIELD).and_then(|x| x.as_u64()).unwrap_or(m.ts)
            } else {
                m.expires_at.unwrap_or(0)
            };
            // A story must carry its timer (or be kept); a feed post has none.
            if (!feed && pin.is_none() && (m.expires_at.is_none() || until <= now))
                || !(matches!(m.kind.as_str(), "image" | "video") || (feed && m.kind == "text"))
            {
                continue;
            }
            let first = c.get(STORY_TIME_FIELD).and_then(|x| x.as_u64());
            out.push(StoryRef {
                story_id: id,
                room_id,
                event_id: m.event_id.clone(),
                mine: m.sender == me,
                sender: m.sender.clone(),
                ts: first.unwrap_or(m.ts),
                kind: m.kind.clone(),
                caption: if m.kind == "text" {
                    m.body.clone()
                } else {
                    m.caption.clone()
                },
                extra,
                feed,
                pin,
                until,
                edited: first.is_some(),
                group,
                member: group && c.get(MEMBER_STORY_FIELD).is_some(),
            });
        }
        out.sort_by_key(|x| x.ts);
        Ok(out)
    }

    /// Likes a friend's feed post: a small encrypted note into our 1:1
    /// chat only (nobody else learns of it, not even other friends).
    pub async fn feed_like(&self, room_id: &RoomId, post_id: &str, on: bool) -> Result<()> {
        anyhow::ensure!(post_id.len() <= 64, "bad post");
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(room.is_direct().await.unwrap_or(false), "not a 1:1 chat");
        room.send_raw(
            FEED_LIKE_TYPE,
            serde_json::json!({ "post": post_id, "on": on }),
        )
        .await
        .map_err(to_err)?;
        Ok(())
    }

    /// Likes in my 1:1 chats, the last word of each person per post (a
    /// like can be taken back).
    pub async fn feed_likes(&self) -> Result<Vec<FeedLike>> {
        let quiet = self.quiet_state().await.unwrap_or_default();
        let me = self
            .client
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default();
        let mut last: std::collections::BTreeMap<(String, String), (u64, bool)> =
            Default::default();
        for room in self.client.joined_rooms() {
            if !room.is_direct().await.unwrap_or(false)
                || self.is_quiet(room.room_id(), &quiet).await
            {
                continue;
            }
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                let Ok(v) = serde_json::from_str::<serde_json::Value>(e.raw().json().get()) else {
                    continue;
                };
                if v.get("type").and_then(|t| t.as_str()) != Some(FEED_LIKE_TYPE) {
                    continue;
                }
                let (Some(post), Some(sender)) = (
                    v.pointer("/content/post").and_then(|x| x.as_str()),
                    v.get("sender").and_then(|x| x.as_str()),
                ) else {
                    continue;
                };
                let on = v
                    .pointer("/content/on")
                    .and_then(|x| x.as_bool())
                    .unwrap_or(true);
                let ts = v
                    .get("origin_server_ts")
                    .and_then(|x| x.as_u64())
                    .unwrap_or(0);
                let k = (post.to_owned(), sender.to_owned());
                if last.get(&k).is_none_or(|(t, _)| *t <= ts) {
                    last.insert(k, (ts, on));
                }
            }
        }
        Ok(last
            .into_iter()
            .filter(|(_, (_, on))| *on)
            .map(|((post_id, sender), _)| FeedLike {
                mine: sender == me,
                post_id,
                sender,
            })
            .collect())
    }

    /// Deletes my story or feed post from every chat it went to (1:1
    /// chats, or the group whose story it was).
    pub async fn delete_story(&self, story_id: &str) -> Result<usize> {
        let me = self
            .client
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default();
        let mut n = 0;
        for room in self.client.joined_rooms() {
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            for e in cache.events().await.unwrap_or_default() {
                if story_of(&e).as_deref() != Some(story_id) {
                    continue;
                }
                let Some(m) = self.to_message(&e) else {
                    continue;
                };
                if m.sender != me {
                    continue;
                }
                let Ok(eid) = matrix_sdk::ruma::OwnedEventId::try_from(m.event_id.as_str()) else {
                    continue;
                };
                if room.redact(&eid, None, None).await.is_ok() {
                    n += 1;
                }
            }
        }
        Ok(n)
    }

    /// Bubbles waiting for me (not popped yet), newest first. Only who sent
    /// it and when: never what is inside, so a home-screen widget can show
    /// them without revealing anything.
    pub async fn pending_bubbles(&self) -> Result<Vec<BubbleRef>> {
        let quiet = self.quiet_state().await.unwrap_or_default();
        let mut out = vec![];
        for room in self.client.joined_rooms() {
            if !room.is_direct().await.unwrap_or(false)
                || self.is_quiet(room.room_id(), &quiet).await
            {
                continue;
            }
            let Ok((cache, _drop)) = room.event_cache().await else {
                continue;
            };
            let events = cache.events().await.unwrap_or_default();
            for m in self.fold(&events) {
                if m.bubble && m.view_once && !m.mine && !m.opened {
                    out.push(BubbleRef {
                        room_id: room.room_id().to_string(),
                        event_id: m.event_id,
                        from: m.sender,
                        ts: m.ts,
                    });
                }
            }
        }
        out.sort_by_key(|b| std::cmp::Reverse(b.ts));
        Ok(out)
    }

    /// Opens a view-once photo: returns its bytes once, then tells the
    /// sender it was opened (the sender's phone then deletes it).
    pub async fn open_view_once(&self, room_id: &RoomId, event_id: &str) -> Result<Vec<u8>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let events = cache.events().await.map_err(to_err)?;
        let m = self
            .fold(&events)
            .into_iter()
            .find(|m| m.event_id == event_id)
            .context("not found")?;
        anyhow::ensure!(m.view_once && !m.mine, "not a view-once message for me");
        anyhow::ensure!(!m.opened, "already opened");
        // Claim it first, so two quick taps can't open it twice.
        anyhow::ensure!(
            self.opened_here
                .lock()
                .map(|mut g| g.insert(event_id.to_owned()))
                .unwrap_or(false),
            "already opened"
        );
        let got: Result<Vec<u8>> = async {
            Ok(if m.kind == "text" {
                let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
                let v: serde_json::Value = room
                    .event(eid, None)
                    .await
                    .map_err(to_err)?
                    .raw()
                    .deserialize_as()
                    .map_err(to_err)?;
                v["content"]["body"]
                    .as_str()
                    .unwrap_or_default()
                    .as_bytes()
                    .to_vec()
            } else {
                self.download_file(room_id, event_id).await?.1
            })
        }
        .await;
        // Could not fetch it: give the claim back so it can be tried again.
        let bytes = match got {
            Ok(b) => b,
            Err(e) => {
                if let Ok(mut g) = self.opened_here.lock() {
                    g.remove(event_id);
                }
                return Err(e);
            }
        };
        let mut done = serde_json::Map::new();
        done.insert(
            "event_id".into(),
            serde_json::Value::String(event_id.to_owned()),
        );
        room.send_raw(OPENED_TYPE, serde_json::Value::Object(done))
            .await
            .map_err(to_err)?;
        Ok(bytes)
    }

    /// Downloads (and decrypts) the file of one message.
    pub async fn download_file(
        &self,
        room_id: &RoomId,
        event_id: &str,
    ) -> Result<(String, Vec<u8>, bool)> {
        self.download_file_with(room_id, event_id, false).await
    }

    /// The file's request (where it is on the server + its key).
    async fn media_request(
        &self,
        room_id: &RoomId,
        event_id: &str,
    ) -> Result<(String, matrix_sdk::media::MediaRequestParameters, bool)> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::MediaSource,
        };
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = <&matrix_sdk::ruma::EventId>::try_from(event_id).map_err(to_err)?;
        let ev = room.event(eid, None).await.map_err(to_err)?;
        let parsed = ev.raw().deserialize().map_err(to_err)?;
        let AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        )) = parsed
        else {
            bail!("not a message")
        };
        // An edit that swapped the file: its new content holds the file.
        let msgtype = match &m.content.relates_to {
            Some(matrix_sdk::ruma::events::room::message::Relation::Replacement(r)) => &r.new_content.msgtype,
            _ => &m.content.msgtype,
        };
        let (name, source) = match msgtype {
            MessageType::File(f) => (f.body.clone(), f.source.clone()),
            MessageType::Image(f) => (f.body.clone(), f.source.clone()),
            MessageType::Video(f) => (f.body.clone(), f.source.clone()),
            MessageType::Audio(f) => (f.body.clone(), f.source.clone()),
            _ => bail!("no file in this message"),
        };
        let encrypted_file = matches!(source, MediaSource::Encrypted(_));
        Ok((
            name,
            MediaRequestParameters {
                source,
                format: MediaFormat::File,
            },
            encrypted_file,
        ))
    }

    /// [cache] = keep a copy in this device's encrypted store (auto-download,
    /// or a video opened again) so it opens without downloading again.
    pub async fn download_file_with(
        &self,
        room_id: &RoomId,
        event_id: &str,
        cache: bool,
    ) -> Result<(String, Vec<u8>, bool)> {
        let (name, request, encrypted_file) = self.media_request(room_id, event_id).await?;
        // [cancel_download] stops it for real (the transfer is dropped).
        let media = self.client.media();
        let (job, stop) = futures_util::future::abortable(media.get_media_content(&request, cache));
        RUNNING_DOWNLOADS
            .lock()
            .map_err(|_| anyhow!("lock"))?
            .insert(event_id.to_owned(), stop);
        let got = job.await;
        if let Ok(mut m) = RUNNING_DOWNLOADS.lock() {
            m.remove(event_id);
        }
        let data = got.map_err(|_| anyhow!("cancelled"))?.map_err(to_err)?;
        Ok((name, data, encrypted_file))
    }

    /// Stops a running [download_file_with] (download list "X").
    pub fn cancel_download(&self, event_id: &str) -> bool {
        RUNNING_DOWNLOADS
            .lock()
            .ok()
            .and_then(|mut m| m.remove(event_id))
            .map(|h| h.abort())
            .is_some()
    }

    /// Removes the kept copy of one file (Settings > Data: keep for N days).
    pub async fn forget_file(&self, room_id: &RoomId, event_id: &str) -> Result<()> {
        let (_, request, _) = self.media_request(room_id, event_id).await?;
        self.client
            .media()
            .remove_media_content(&request)
            .await
            .map_err(to_err)
    }

    /// Kept copies: biggest single file and how long an unopened copy stays
    /// (None = no limit). The store drops older copies on its own.
    pub async fn set_media_keep(&self, max_file: Option<u64>, keep_secs: Option<u64>) -> Result<()> {
        use matrix_sdk::media::MediaRetentionPolicy;
        let policy = MediaRetentionPolicy::new()
            .with_max_cache_size(Some(4 * 1024 * 1024 * 1024))
            .with_max_file_size(max_file)
            .with_last_access_expiry(keep_secs.map(std::time::Duration::from_secs));
        let media = self.client.media();
        media.set_media_retention_policy(policy).await.map_err(to_err)?;
        media.clean().await.map_err(to_err)
    }

    /// Turns on phone notifications through our push gateway. The server is
    /// told to send only the message id ("event_id_only"): no text, no
    /// sender name, no chat name ever leaves the server in a notification.
    pub async fn set_push(&self, gateway_url: &str, pushkey: &str, app_id: &str) -> Result<()> {
        use matrix_sdk::ruma::{
            api::client::push::{PusherIds, PusherInit, PusherKind},
            push::{HttpPusherData, PushFormat},
        };
        let mut data = HttpPusherData::new(gateway_url.to_owned());
        data.format = Some(PushFormat::EventIdOnly);
        let pusher = PusherInit {
            ids: PusherIds::new(pushkey.to_owned(), app_id.to_owned()),
            kind: PusherKind::Http(data),
            app_display_name: "Burumy".to_owned(),
            device_display_name: "phone".to_owned(),
            profile_tag: None,
            lang: "ko".to_owned(),
        };
        self.client
            .pusher()
            .set(pusher.into(), false)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    fn to_message(
        &self,
        ev: &matrix_sdk::deserialized_responses::TimelineEvent,
    ) -> Option<Message> {
        let mut m = self.to_message_inner(ev)?;
        m.topic = topic::read(ev.raw().json().get());
        Some(m)
    }

    fn to_message_inner(
        &self,
        ev: &matrix_sdk::deserialized_responses::TimelineEvent,
    ) -> Option<Message> {
        // In our (always encrypted) chats a message that did not come end-to-end
        // encrypted was injected around the encryption (a bad server or a
        // modified app): never show it or let it change anything.
        trusted_json(ev)?;
        let was_encrypted = !matches!(ev.kind, TimelineEventKind::PlainText { .. });
        let parsed = ev.raw().deserialize().ok()?;
        let me = self.client.user_id();
        let ts: u64 = parsed.origin_server_ts().get().into();
        let (event_id, sender) = (parsed.event_id().to_string(), parsed.sender().to_string());
        let mine = me.map(|u| u.as_str() == sender).unwrap_or(false);
        match parsed {
            AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
                SyncMessageLikeEvent::Original(m),
            )) => {
                use matrix_sdk::ruma::events::room::message::Relation;
                let kind_body = |t: &MessageType| match t {
                    MessageType::Text(t) => ("text", t.body.clone()),
                    MessageType::Image(f) => ("image", f.filename().to_owned()),
                    MessageType::Video(f) => ("video", f.filename().to_owned()),
                    MessageType::Audio(f) => ("audio", f.filename().to_owned()),
                    MessageType::File(f) => ("file", f.filename().to_owned()),
                    // Only a valid point; anything else shows as plain text.
                    MessageType::Location(l) => match location::parse(&l.geo_uri) {
                        // Live: the end time goes after the point (";live=").
                        Some(g) => match l.body.strip_prefix(LIVE_MARK).and_then(|x| x.parse::<u64>().ok()) {
                            Some(until) => ("location", format!("{g};live={until}")),
                            None => ("location", g),
                        },
                        None => ("text", l.body.clone()),
                    },
                    // A request to check each other's keys (in-chat card).
                    MessageType::VerificationRequest(r) => ("verify", r.body.clone()),
                    other if other.msgtype() == STICKER_TYPE => (
                        "sticker",
                        other
                            .data()
                            .get("sticker")
                            .and_then(|v| v.as_str())
                            .unwrap_or_default()
                            .to_owned(),
                    ),
                    other => ("text", other.body().to_owned()),
                };
                let caption_of = |t: &MessageType| match t {
                    MessageType::Image(f) => f.caption().map(str::to_owned),
                    MessageType::Video(f) => f.caption().map(str::to_owned),
                    MessageType::File(f) => f.caption().map(str::to_owned),
                    _ => None,
                };
                let (mut kind, mut body) = kind_body(&m.content.msgtype);
                let mut caption = caption_of(&m.content.msgtype);
                // The sender's phone writes the size; shown on the bubble and
                // used by the auto-download size limit.
                let file_size: Option<u64> = match &m.content.msgtype {
                    MessageType::Image(f) => f.info.as_ref().and_then(|i| i.size),
                    MessageType::Video(f) => f.info.as_ref().and_then(|i| i.size),
                    MessageType::File(f) => f.info.as_ref().and_then(|i| i.size),
                    MessageType::Audio(f) => f.info.as_ref().and_then(|i| i.size),
                    _ => None,
                }
                .map(u64::from);
                if m.content.msgtype.msgtype() == TIMER_TYPE {
                    kind = "timer";
                    body = m
                        .content
                        .msgtype
                        .data()
                        .get("seconds")
                        .and_then(|v| v.as_u64())
                        .unwrap_or(0)
                        .to_string();
                }
                // Timer: seconds after sending (inside the encrypted content).
                let raw = serde_json::from_str::<serde_json::Value>(ev.raw().json().get()).ok();
                let view_once = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(VIEW_ONCE_FIELD)?.as_bool())
                    .unwrap_or(false);
                let bubble = view_once
                    && raw
                        .as_ref()
                        .and_then(|v| v.get("content")?.get(BUBBLE_FIELD)?.as_bool())
                        .unwrap_or(false);
                // What's inside a closed bubble stays hidden until it is popped.
                if bubble && kind == "text" {
                    body = String::new();
                }
                let forwarded = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(FORWARDED_FIELD)?.as_bool())
                    .unwrap_or(false);
                let silent = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(SILENT_FIELD)?.as_bool())
                    .unwrap_or(false);
                let voice = raw.as_ref().and_then(|v| {
                    let c = v.get("content")?;
                    c.get("org.matrix.msc3245.voice")?;
                    let a = c.get("org.matrix.msc1767.audio");
                    let duration_ms = a
                        .and_then(|a| a.get("duration")?.as_u64())
                        .or_else(|| c.get("info")?.get("duration")?.as_u64())
                        .unwrap_or(0);
                    let waveform = a
                        .and_then(|a| a.get("waveform")?.as_array().cloned())
                        .unwrap_or_default()
                        .iter()
                        .filter_map(|x| x.as_u64().map(|n| n.min(1024) as u16))
                        .take(120)
                        .collect();
                    Some(Voice {
                        duration_ms,
                        waveform,
                    })
                });
                // Only photos carry a clip; view-once photos stay still.
                let live = raw.as_ref().and_then(|v| {
                    let l = v.get("content")?.get(LIVE_FIELD)?;
                    l.get("file")?;
                    Some(Live {
                        style: live_style(l.get("style").and_then(|x| x.as_str()).unwrap_or("")).to_owned(),
                        duration_ms: l.get("duration").and_then(|x| x.as_u64()).unwrap_or(0).min(LIVE_MAX_MS),
                    })
                }).filter(|_| matches!(m.content.msgtype, MessageType::Image(_)) && !view_once);
                let preview = raw.as_ref().and_then(|v| {
                    let p = v.get("content")?.get(PREVIEW_FIELD)?;
                    let s = |k: &str| p.get(k).and_then(|x| x.as_str()).map(str::to_owned);
                    Some(LinkPreview {
                        url: s("url")?,
                        title: s("title")?,
                        description: s("description"),
                        site: s("site"),
                        has_image: p.get("image").is_some(),
                        above: p.get("above").and_then(|x| x.as_bool()).unwrap_or(false),
                        small: p.get("small").and_then(|x| x.as_bool()).unwrap_or(false),
                    })
                });
                let (quote, quote_name) = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(QUOTE_FIELD).cloned())
                    .map(|q| read_quote(&q))
                    .unwrap_or((None, None));
                let post_as = raw.as_ref().and_then(|v| clean_post_as(v.get("content")?.get(AS_FIELD)?));
                let expires_at = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(TTL_FIELD)?.as_u64())
                    .filter(|s| *s > 0)
                    .map(|s| ts.saturating_add(s.saturating_mul(1000)));
                let (mut reply_to, mut replaces, mut thread_root) = (None, None, None);
                let mut caption_above = raw
                    .as_ref()
                    .and_then(|v| v.get("content")?.get(CAPTION_ABOVE_FIELD)?.as_bool())
                    .unwrap_or(false);
                match &m.content.relates_to {
                    Some(Relation::Reply(r)) => reply_to = Some(r.in_reply_to.event_id.to_string()),
                    Some(Relation::Thread(t)) => thread_root = Some(t.event_id.to_string()),
                    Some(Relation::Replacement(r)) => {
                        replaces = Some(r.event_id.to_string());
                        (kind, body) = kind_body(&r.new_content.msgtype);
                        caption = caption_of(&r.new_content.msgtype);
                        caption_above = raw
                            .as_ref()
                            .and_then(|v| v.get("content")?.get("m.new_content")?.get(CAPTION_ABOVE_FIELD)?.as_bool())
                            .unwrap_or(false);
                    }
                    _ => {}
                }
                Some(Message {
                    event_id,
                    sender,
                    body: Some(body),
                    was_encrypted,
                    topic: None,
                    ts,
                    mine,
                    kind: kind.into(),
                    reply_to,
                    thread_root,
                    edited: false,
                    edited_at: None,
                    first_body: None,
                    replaces,
                    reactions: vec![],
                    expires_at,
                    view_once,
                    opened: false,
                    forwarded,
                    silent,
                    preview,
                    voice,
                    live,
                    poll: None,
                    call: None,
                    bubble,
                    caption: if view_once { None } else { caption },
                    size: file_size,
                    checklist: None,
                    meetup: None,
                    contact: None,
                    card: None,
                    quote,
                    quote_name,
                    caption_above,
                    media_from: None,
                    media_changed: false,
                    post_as,
                })
            }
            AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(_)) => {
                Some(Message {
                    event_id,
                    sender,
                    body: None,
                    was_encrypted: true,
                    topic: None,
                    ts,
                    mine,
                    kind: "locked".into(),
                    reply_to: None,
                    thread_root: None,
                    edited: false,
                    edited_at: None,
                    first_body: None,
                    replaces: None,
                    reactions: vec![],
                    expires_at: None,
                    view_once: false,
                    opened: false,
                    forwarded: false,
                    silent: false,
                    preview: None,
                    voice: None,
                    live: None,
                    poll: None,
                    call: None,
                    bubble: false,
                    caption: None,
                    size: None,
                    checklist: None,
                    meetup: None,
                    contact: None,
                    card: None,
                    quote: None,
                    quote_name: None,
                    caption_above: false,
                    media_from: None,
                    media_changed: false,
                    post_as: None,
                })
            }
            _ => {
                // A poll (our own event type, inside the encrypted chat).
                let v = serde_json::from_str::<serde_json::Value>(ev.raw().json().get()).ok()?;
                if v["type"].as_str() == Some(call::INVITE) {
                    let c = &v["content"];
                    c["call"].as_str()?;
                    let video = c["video"].as_bool().unwrap_or(false);
                    return Some(Message {
                        event_id,
                        sender,
                        body: Some(String::new()),
                        was_encrypted,
                        topic: None,
                        ts,
                        mine,
                        kind: "call".into(),
                        reply_to: None,
                        thread_root: None,
                        edited: false,
                        edited_at: None,
                        first_body: None,
                        replaces: None,
                        reactions: vec![],
                        expires_at: None,
                        view_once: false,
                        opened: false,
                        forwarded: false,
                        silent: false,
                        preview: None,
                        voice: None,
                        live: None,
                        poll: None,
                        call: Some(call::Call {
                            call_id: c["call"].as_str()?.into(),
                            video,
                            state: "ringing".into(),
                            started_at: ts,
                            answered_at: None,
                            ended_at: None,
                        }),
                        bubble: false,
                        caption: None,
                        size: None,
                        checklist: None,
                        meetup: None,
                        contact: None,
                        card: None,
                        quote: None,
                        quote_name: None,
                        caption_above: false,
                        media_from: None,
                        media_changed: false,
                        post_as: None,
                    });
                }
                if v["type"].as_str() == Some(ROOM_PHOTO_TYPE) {
                    // "그룹 사진을 바꿨어요" line; a copy sent again for new
                    // members stays hidden.
                    let c = &v["content"];
                    if c.get("again").and_then(|x| x.as_bool()) == Some(true) {
                        return None;
                    }
                    let name = if c.get("photo").is_some() { "set".to_owned() } else { "removed".to_owned() };
                    return Some(Message {
                        event_id,
                        sender,
                        body: Some(name),
                        was_encrypted,
                        topic: None,
                        ts,
                        mine,
                        kind: "room_photo".into(),
                        reply_to: None,
                        thread_root: None,
                        edited: false,
                        edited_at: None,
                        first_body: None,
                        replaces: None,
                        reactions: vec![],
                        expires_at: None,
                        view_once: false,
                        opened: false,
                        forwarded: false,
                        silent: false,
                        preview: None,
                        voice: None,
                        live: None,
                        poll: None,
                        call: None,
                        bubble: false,
                        caption: None,
                        size: None,
                        checklist: None,
                        meetup: None,
                        contact: None,
                        card: None,
                        quote: None,
                        quote_name: None,
                        caption_above: false,
                        media_from: None,
                        media_changed: false,
                        post_as: None,
                    });
                }
                if v["type"].as_str() == Some(CONTACT_TYPE) {
                    let c = &v["content"];
                    let uid = c["user_id"]
                        .as_str()
                        .filter(|u| UserId::parse(*u).is_ok())?;
                    let name = c["name"]
                        .as_str()
                        .map(|n| n.trim().chars().take(64).collect::<String>())
                        .filter(|n| !n.is_empty())
                        .unwrap_or_else(|| uid.to_owned());
                    return Some(Message {
                        event_id,
                        sender,
                        body: Some(name),
                        was_encrypted,
                        topic: None,
                        ts,
                        mine,
                        kind: "contact".into(),
                        reply_to: None,
                        thread_root: None,
                        edited: false,
                        edited_at: None,
                        first_body: None,
                        replaces: None,
                        reactions: vec![],
                        expires_at: None,
                        view_once: false,
                        opened: false,
                        forwarded: false,
                        silent: false,
                        preview: None,
                        voice: None,
                        live: None,
                        poll: None,
                        call: None,
                        bubble: false,
                        caption: None,
                        size: None,
                        checklist: None,
                        meetup: None,
                        contact: Some(uid.to_owned()),
                        card: None,
                        quote: None,
                        quote_name: None,
                        caption_above: false,
                        media_from: None,
                        media_changed: false,
                        post_as: None,
                    });
                }
                let is_list = v["type"].as_str() == Some(checklist::START);
                let is_plan = v["type"].as_str() == Some(meetup::START);
                let is_card = v["type"].as_str() == Some(card::START);
                if v["type"].as_str() != Some(poll::START) && !is_list && !is_plan && !is_card {
                    return None;
                }
                let q = if is_card {
                    card::body(v["content"]["kind"].as_str()?, &v["content"]["data"])
                } else if is_list || is_plan {
                    v["content"]["title"].as_str()?.to_owned()
                } else {
                    v["content"]["question"].as_str()?.to_owned()
                };
                Some(Message {
                    event_id,
                    sender,
                    body: Some(q),
                    was_encrypted,
                    topic: None,
                    ts,
                    mine,
                    kind: if is_card {
                        "card"
                    } else if is_list {
                        "checklist"
                    } else if is_plan {
                        "meetup"
                    } else {
                        "poll"
                    }
                    .into(),
                    reply_to: None,
                    thread_root: None,
                    edited: false,
                    edited_at: None,
                    first_body: None,
                    replaces: None,
                    reactions: vec![],
                    expires_at: None,
                    view_once: false,
                    opened: false,
                    forwarded: false,
                    silent: is_card && v["content"][SILENT_FIELD].as_bool().unwrap_or(false),
                    preview: None,
                    voice: None,
                    live: None,
                    poll: None,
                    call: None,
                    bubble: false,
                    caption: None,
                    size: None,
                    checklist: None,
                    meetup: None,
                    contact: None,
                    card: None,
                    quote: None,
                    quote_name: None,
                    caption_above: false,
                    media_from: None,
                    media_changed: false,
                    post_as: None,
                })
            }
        }
    }

    /// Applies edits (only the sender's own edits count) and drops the edit
    /// events themselves. Deleted messages are already gone (not shown).
    fn fold(&self, events: &[matrix_sdk::deserialized_responses::TimelineEvent]) -> Vec<Message> {
        self.fold_rules(events, false, false)
    }

    /// Group or channel (more than two people): edits count for 24 hours.
    async fn is_group_chat(&self, room: &matrix_sdk::Room) -> bool {
        self.is_channel(room.room_id()).await || room.joined_members_count() > 2
    }

    /// Whether this chat lets a sent photo be swapped: not in public groups
    /// and channels (a public address, even with join approval on).
    async fn swaps_ok(&self, room: &matrix_sdk::Room) -> bool {
        room.join_rule() != Some(matrix_sdk::ruma::events::room::join_rules::JoinRule::Public)
            && self.room_link(room.room_id()).await.kind != "public"
    }

    /// [fold] with the chat's swap rule ([swaps_ok]).
    fn fold_rules(
        &self,
        events: &[matrix_sdk::deserialized_responses::TimelineEvent],
        swaps_ok: bool,
        group: bool,
    ) -> Vec<Message> {
        let mut url_of: std::collections::HashMap<String, String> = events
            .iter()
            .filter_map(|e| Some((e.event_id()?.to_string(), media_url_of(e)?)))
            .collect();
        // Deletions that the local copy has not applied yet.
        let gone: std::collections::HashSet<String> = events
            .iter()
            .filter_map(|e| match e.raw().deserialize().ok()? {
                AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomRedaction(r)) => r
                    .as_original()
                    .and_then(|o| o.content.redacts.clone().or_else(|| o.redacts.clone()))
                    .map(|id| id.to_string()),
                _ => None,
            })
            .collect();
        let now = now_ms();
        let all: Vec<Message> = events
            .iter()
            // Stories live in the story row, never in the chat itself.
            .filter(|e| story_of(e).is_none())
            .filter_map(|e| self.to_message(e))
            .filter(|m| !gone.contains(&m.event_id) && m.expires_at.is_none_or(|t| t > now))
            .collect();
        let mut out: Vec<Message> = all
            .iter()
            .filter(|m| m.replaces.is_none())
            .cloned()
            .collect();
        for e in all.iter().filter(|m| m.replaces.is_some()) {
            if let Some(t) = out
                .iter_mut()
                .find(|t| Some(&t.event_id) == e.replaces.as_ref() && t.sender == e.sender)
            {
                // Groups and channels: an edit sent more than 24 hours after
                // the message never counts. The server refuses those, but a
                // modified app can hide the edit link inside the encryption
                // where the server can't see it (보안검수 2026-11-28), so
                // every phone checks too, by the server's own times.
                if group && !edit_window_open(true, t.ts, e.ts) {
                    continue;
                }
                // Words can change; a caption only with the same file; a
                // photo, video or file only outside public chats (see
                // [edit_rule]), even from a modified app.
                let same = url_of.get(&t.event_id).is_some() && url_of.get(&t.event_id) == url_of.get(&e.event_id);
                match edit_rule(&t.kind, &e.kind, same, swaps_ok) {
                    EditKind::Refused => continue,
                    EditKind::Text => {
                        if t.first_body.is_none() {
                            t.first_body = t.body.clone();
                        }
                        t.body = e.body.clone();
                    }
                    EditKind::Caption => {
                        if t.first_body.is_none() {
                            t.first_body = Some(t.caption.clone().unwrap_or_default());
                        }
                        t.caption = e.caption.clone();
                        t.caption_above = e.caption_above;
                    }
                    EditKind::Media => {
                        if t.first_body.is_none() {
                            t.first_body = Some(if t.kind == "text" { t.body.clone().unwrap_or_default() } else { t.caption.clone().unwrap_or_default() });
                        }
                        if let Some(u) = url_of.get(&e.event_id).cloned() {
                            url_of.insert(t.event_id.clone(), u);
                        }
                        t.kind = e.kind.clone();
                        t.body = e.body.clone();
                        t.caption = e.caption.clone();
                        t.caption_above = e.caption_above;
                        t.size = e.size;
                        t.media_from = Some(e.event_id.clone());
                        t.media_changed = true;
                        (t.preview, t.voice, t.live) = (None, None, None);
                    }
                }
                t.edited = true;
                t.edited_at = Some(t.edited_at.unwrap_or(0).max(e.ts));
            }
        }
        let me = self.client.user_id().map(|u| u.to_string());
        // View-once photos that were opened (only the receiver's mark counts).
        for e in events {
            let Some(v) = trusted_json(e) else {
                continue;
            };
            if v.get("type").and_then(|t| t.as_str()) != Some(OPENED_TYPE) {
                continue;
            }
            let (Some(target), Some(by)) =
                (v["content"]["event_id"].as_str(), v["sender"].as_str())
            else {
                continue;
            };
            if let Some(t) = out
                .iter_mut()
                .find(|t| t.event_id == target && t.view_once && t.sender != by)
            {
                t.opened = true;
            } else if !out.iter().any(|t| t.event_id == target) {
                // The photo itself is gone: keep a small line saying it was opened.
                let ts = v["origin_server_ts"].as_u64().unwrap_or(0);
                let id = v["event_id"].as_str().unwrap_or_default().to_owned();
                let pos = out.iter().position(|t| t.ts > ts).unwrap_or(out.len());
                out.insert(
                    pos,
                    Message {
                        event_id: id,
                        sender: by.to_owned(),
                        body: None,
                        was_encrypted: true,
                        topic: None,
                        ts,
                        mine: me.as_deref() == Some(by),
                        kind: "opened".into(),
                        reply_to: None,
                        thread_root: None,
                        edited: false,
                        edited_at: None,
                        first_body: None,
                        replaces: None,
                        reactions: vec![],
                        expires_at: None,
                        view_once: false,
                        opened: true,
                        forwarded: false,
                        silent: false,
                        preview: None,
                        voice: None,
                        live: None,
                        poll: None,
                        call: None,
                        bubble: false,
                        caption: None,
                        size: None,
                        checklist: None,
                        meetup: None,
                        contact: None,
                        card: None,
                        quote: None,
                        quote_name: None,
                        caption_above: false,
                        media_from: None,
                        media_changed: false,
                        post_as: None,
                    },
                );
            }
        }
        // Polls: numbers from votes, the maker's counts and the close mark.
        if out.iter().any(|m| m.kind == "poll") {
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            let mine_anon = self
                .my_votes
                .lock()
                .ok()
                .map(|m| m.clone())
                .unwrap_or_default();
            let polls = poll::collect(&raws, me.as_deref().unwrap_or_default(), &mine_anon);
            for m in out.iter_mut().filter(|m| m.kind == "poll") {
                m.poll = polls.get(&m.event_id).cloned();
            }
            out.retain(|m| m.kind != "poll" || m.poll.is_some());
        }
        // Checklists: ticks and added items from the people allowed to.
        if out.iter().any(|m| m.kind == "checklist") {
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            let lists = checklist::collect(&raws);
            for m in out.iter_mut().filter(|m| m.kind == "checklist") {
                m.checklist = lists.get(&m.event_id).cloned();
            }
            out.retain(|m| m.kind != "checklist" || m.checklist.is_some());
        }
        // Plans: who is coming (latest answer of each person).
        if out.iter().any(|m| m.kind == "meetup") {
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            let plans = meetup::collect(&raws);
            for m in out.iter_mut().filter(|m| m.kind == "meetup") {
                m.meetup = plans.get(&m.event_id).cloned();
            }
            out.retain(|m| m.kind != "meetup" || m.meetup.is_some());
        }
        // Cards: the maker's numbers and winners, my own answer.
        if out.iter().any(|m| m.kind == "card") {
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            let mine = self.my_cards.lock().map(|m| m.clone()).unwrap_or_default();
            let cards = card::collect(&raws, &mine);
            for m in out.iter_mut().filter(|m| m.kind == "card") {
                m.card = cards.get(&m.event_id).cloned();
            }
            out.retain(|m| m.kind != "card" || m.card.is_some());
        }
        // Calls: ringing / ongoing / ended / missed / declined.
        if out.iter().any(|m| m.kind == "call") {
            let raws: Vec<serde_json::Value> =
                events.iter().filter_map(|e| trusted_json(e)).collect();
            let calls = call::collect(&raws, now);
            for m in out.iter_mut().filter(|m| m.kind == "call") {
                if let Some(c) = m
                    .call
                    .as_ref()
                    .and_then(|c| calls.get(&c.call_id))
                    .filter(|(eid, _)| *eid == m.event_id)
                {
                    m.call = Some(c.1.clone());
                }
            }
        }
        if let Ok(g) = self.opened_here.lock() {
            for m in out
                .iter_mut()
                .filter(|m| m.view_once && !m.mine && g.contains(&m.event_id))
            {
                m.opened = true;
            }
        }
        // Reactions (each person counts once per emoji).
        let mut seen = std::collections::HashSet::new();
        for e in events {
            let Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Reaction(r))) =
                e.raw().deserialize()
            else {
                continue;
            };
            let Some(o) = r.as_original() else { continue };
            if gone.contains(o.event_id.as_str()) {
                continue;
            }
            let (target, key, sender) = (
                o.content.relates_to.event_id.to_string(),
                o.content.relates_to.key.clone(),
                o.sender.to_string(),
            );
            if !seen.insert((target.clone(), key.clone(), sender.clone())) {
                continue;
            }
            let Some(t) = out.iter_mut().find(|t| t.event_id == target) else {
                continue;
            };
            let mine = (Some(&sender) == me.as_ref()).then(|| o.event_id.to_string());
            match t.reactions.iter_mut().find(|x| x.key == key) {
                Some(x) => {
                    x.count += 1;
                    if mine.is_some() {
                        x.mine = mine;
                    }
                }
                None => t.reactions.push(Reaction {
                    key,
                    count: 1,
                    mine,
                }),
            }
        }
        out
    }

    /// Newest messages first, straight from the server.
    pub async fn messages(&self, room_id: &RoomId, limit: u32) -> Result<Vec<Message>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let mut opts = MessagesOptions::backward();
        opts.limit = limit.into();
        let page = room.messages(opts).await.map_err(to_err)?;
        let mut v = self.fold_rules(&page.chunk.iter().rev().cloned().collect::<Vec<_>>(), self.swaps_ok(&room).await, self.is_group_chat(&room).await);
        v.reverse();
        Ok(v)
    }

    /// Oldest first, from this device's own copy (works offline). Asks the
    /// server for older messages only when fewer than `limit` are kept here.
    pub async fn timeline(&self, room_id: &RoomId, limit: usize) -> Result<Vec<Message>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if self
            .is_quiet(room_id, &self.quiet_state().await.unwrap_or_default())
            .await
        {
            return Ok(vec![]);
        }
        self.load_my_votes().await;
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let swaps = self.swaps_ok(&room).await;
        let group = self.is_group_chat(&room).await;
        let mut out: Vec<Message> = self.fold_rules(&cache.events().await.map_err(to_err)?, swaps, group);
        for _ in 0..5 {
            if out.len() >= limit {
                break;
            }
            let outcome = cache
                .pagination()
                .run_backwards_once(50)
                .await
                .map_err(to_err)?;
            out = self.fold_rules(&cache.events().await.map_err(to_err)?, swaps, group);
            if outcome.reached_start {
                break;
            }
        }
        if out.iter().any(|m| m.mine && m.poll.as_ref().is_some_and(|p| p.hide_results)) {
            self.post_final_tallies(&room, &out).await;
        }
        let q = self.quiet_state().await.unwrap_or_default();
        let unseen = self.unseen(&q);
        if !unseen.is_empty() {
            out.retain(|m| !unseen.contains(&m.event_id));
        }
        let skip = out.len().saturating_sub(limit);
        Ok(out.split_off(skip))
    }

    /// The messages this phone already holds for a chat, without asking
    /// the server for more (안 본 멘션·반응 배지, tips 249/320: the chat list
    /// looks at every chat often, so this must stay cheap).
    pub async fn cached_messages(&self, room_id: &RoomId) -> Result<Vec<Message>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let q = self.quiet_state().await.unwrap_or_default();
        if self.is_quiet(room_id, &q).await {
            return Ok(vec![]);
        }
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let mut out = self.fold_rules(&cache.events().await.map_err(to_err)?, self.swaps_ok(&room).await, self.is_group_chat(&room).await);
        let unseen = self.unseen(&q);
        if !unseen.is_empty() {
            out.retain(|m| !unseen.contains(&m.event_id));
        }
        Ok(out)
    }

    /// The chat list, newest activity first.
    pub async fn chat_list(&self) -> Result<Vec<ChatSummary>> {
        let mut out = Vec::new();
        let q = self.quiet_state().await.unwrap_or_default();
        let prefs = self.prefs().await;
        let streaks_on = prefs.streaks;
        let ns = self.client.notification_settings().await;
        let now: u64 = matrix_sdk::ruma::MilliSecondsSinceUnixEpoch::now()
            .get()
            .into();
        for room in self.client.joined_rooms() {
            if self.is_quiet(room.room_id(), &q).await {
                continue;
            }
            // Communities are not chats: they show through their chats.
            if self.is_community(room.room_id()).await {
                continue;
            }
            let mut name = room
                .display_name()
                .await
                .map(|n| n.to_string())
                .unwrap_or_default();
            let is_direct = room.is_direct().await.unwrap_or(false);
            if name.starts_with(ID_KEY_PREFIX) {
                // A 1:1 started with an 아이디 키: show the other person.
                name = self.dm_peer_name(&room).await;
            }
            let encrypted = room
                .latest_encryption_state()
                .await
                .map(|e| e.is_encrypted())
                .unwrap_or(false);
            let mut msgs = match room.event_cache().await {
                Ok((cache, _drop)) => self.fold_rules(&cache.events().await.unwrap_or_default(), self.swaps_ok(&room).await, self.is_group_chat(&room).await),
                Err(_) => vec![],
            };
            let unseen = self.unseen(&q);
            if !unseen.is_empty() {
                msgs.retain(|m| !unseen.contains(&m.event_id));
            }
            let is_channel = !is_direct && self.is_channel(room.room_id()).await;
            let tz = self.tz.load(std::sync::atomic::Ordering::Relaxed);
            let st = if is_direct && streaks_on {
                streak::streak(&msgs.iter().map(|m| (m.ts, m.mine)).collect::<Vec<_>>(), now, tz)
            } else if !is_direct && !is_channel && streaks_on {
                // 그룹 스트릭: enough members wrote each day.
                let members = room.joined_members_count() as usize;
                streak::group_streak(&msgs.iter().map(|m| (m.ts, m.sender.as_str())).collect::<Vec<_>>(), members, now, tz)
            } else {
                streak::Streak::default()
            };
            let last = msgs.last().cloned();
            let peer = if is_direct {
                room.direct_targets()
                    .iter()
                    .find_map(|t| t.as_user_id().map(|u| u.to_string()))
                    .unwrap_or_default()
            } else if is_channel {
                // Channels: the owner, for the small photo on the avatar.
                room.creators()
                    .and_then(|c| c.first().map(|u| u.to_string()))
                    .unwrap_or_default()
            } else {
                String::new()
            };
            out.push(ChatSummary {
                is_channel,
                peer,
                room_id: room.room_id().to_string(),
                name,
                is_direct,
                encrypted,
                unread: room.num_unread_messages(),
                last,
                streak: if st.days >= streak::SHOW_FROM {
                    st.days
                } else {
                    0
                },
                streak_at_risk: st.at_risk && st.days >= streak::SHOW_FROM,
                pinned: prefs.pinned_chats.contains(&room.room_id().to_string()),
                archived: prefs.archived.contains(&room.room_id().to_string()),
                muted: matches!(
                    ns.get_user_defined_room_notification_mode(room.room_id())
                        .await,
                    Some(matrix_sdk::notification_settings::RoomNotificationMode::Mute)
                ),
            });
        }
        out.sort_by_key(|c| std::cmp::Reverse(c.last.as_ref().map(|m| m.ts).unwrap_or(0)));
        // Pinned chats first, in the order they were pinned.
        out.sort_by_key(|c| {
            prefs
                .pinned_chats
                .iter()
                .position(|p| *p == c.room_id)
                .unwrap_or(usize::MAX)
        });
        Ok(out)
    }

    /// New messages to show as phone notifications, oldest first, at most
    /// `max`. Muted and hidden chats never notify. Each message is given
    /// out once (a mark per chat is kept on the phone).
    pub async fn notifications(&self, max: usize) -> Result<Vec<Notice>> {
        const KEY: &[u8] = b"burumy.notified.v1";
        let store = self.client.state_store();
        let mut marks: std::collections::HashMap<String, u64> = store
            .get_custom_value(KEY)
            .await
            .map_err(to_err)?
            .and_then(|b| serde_json::from_slice(&b).ok())
            .unwrap_or_default();
        let prefs = self.prefs().await;
        let hide = prefs.hide_notice_text;
        // Settings > Notifications: 1:1 chats, groups and channels can each
        // be switched off ("0"); on by default.
        let kind_on = |k: &str| prefs.settings.get(k).map(String::as_str) != Some("0");
        let mut out = vec![];
        for chat in self.chat_list().await? {
            if chat.muted || chat.unread == 0 {
                continue;
            }
            let Some(room) = self
                .client
                .get_room(&RoomId::parse(&chat.room_id).map_err(to_err)?)
            else {
                continue;
            };
            let allowed = if chat.is_direct {
                kind_on("notify_direct")
            } else if self.is_channel(room.room_id()).await {
                kind_on("notify_channel")
            } else {
                kind_on("notify_group")
            };
            if !allowed {
                continue;
            }
            let msgs = match room.event_cache().await {
                Ok((cache, _drop)) => self.fold(&cache.events().await.unwrap_or_default()),
                Err(_) => continue,
            };
            let since = marks.get(&chat.room_id).copied().unwrap_or(0);
            let fresh: Vec<&Message> = msgs.iter().filter(|m| !m.mine && m.ts > since).collect();
            let fresh = &fresh[fresh.len().saturating_sub(chat.unread as usize)..];
            for m in fresh {
                if m.silent {
                    continue;
                }
                let sender = if chat.is_direct || hide {
                    String::new()
                } else {
                    let uid = <&UserId>::try_from(m.sender.as_str()).ok();
                    let member = match uid {
                        Some(u) => room.get_member_no_sync(u).await.ok().flatten(),
                        None => None,
                    };
                    member
                        .and_then(|x| x.display_name().map(str::to_owned))
                        .unwrap_or_else(|| {
                            m.sender
                                .trim_start_matches('@')
                                .split(':')
                                .next()
                                .unwrap_or_default()
                                .to_owned()
                        })
                };
                let secret = m.view_once || m.bubble || m.kind == "locked";
                // "고정하고 모두에게 알림": reaches everyone, with the preview.
                let pin_line = m.card.as_ref().is_some_and(|c| c.kind == "pin");
                out.push(Notice {
                    room_id: chat.room_id.clone(),
                    chat: if hide {
                        String::new()
                    } else {
                        chat.name.clone()
                    },
                    sender,
                    kind: if m.bubble {
                        "bubble".into()
                    } else if pin_line {
                        "pin".into()
                    } else {
                        m.kind.clone()
                    },
                    body: if hide || secret || (m.kind != "text" && !pin_line) {
                        None
                    } else {
                        m.body.clone()
                    },
                    ts: m.ts,
                });
            }
            if let Some(last) = msgs.iter().filter(|m| !m.mine).map(|m| m.ts).max() {
                marks.insert(chat.room_id.clone(), last.max(since));
            }
        }
        store
            .set_custom_value_no_read(KEY, serde_json::to_vec(&marks)?)
            .await
            .map_err(to_err)?;
        out.sort_by_key(|n| n.ts);
        let skip = out.len().saturating_sub(max);
        Ok(out.split_off(skip))
    }

    /// People I have a 1:1 chat with (the contact list), by name.
    pub async fn contacts(&self) -> Result<Vec<Person>> {
        let mut out = Vec::new();
        let q = self.quiet_state().await.unwrap_or_default();
        for room in self.client.joined_rooms() {
            if !room.is_direct().await.unwrap_or(false) {
                continue;
            }
            if self.is_quiet(room.room_id(), &q).await {
                continue;
            }
            for t in room.direct_targets() {
                let Some(uid) = t.as_user_id() else { continue };
                let name = match room.get_member_no_sync(uid).await {
                    Ok(Some(m)) => m
                        .display_name()
                        .map(str::to_owned)
                        .unwrap_or_else(|| uid.localpart().to_owned()),
                    _ => uid.localpart().to_owned(),
                };
                out.push(Person {
                    user_id: uid.to_string(),
                    name,
                    room_id: Some(room.room_id().to_string()),
                });
            }
        }
        out.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
        out.dedup_by(|a, b| a.user_id == b.user_id);
        Ok(out)
    }

    /// Finds people on our server by ID (or name).
    pub async fn search_people(&self, term: &str) -> Result<Vec<Person>> {
        let r = self.client.search_users(term, 20).await.map_err(to_err)?;
        let me = self.client.user_id().map(|u| u.to_string());
        let q = self.quiet_state().await.unwrap_or_default();
        Ok(r.results
            .into_iter()
            .filter(|u| {
                Some(u.user_id.to_string()) != me && !self.is_quiet_user(u.user_id.as_str(), &q)
            })
            .map(|u| Person {
                name: u
                    .display_name
                    .unwrap_or_else(|| u.user_id.localpart().to_owned()),
                user_id: u.user_id.to_string(),
                room_id: None,
            })
            .collect())
    }

    /// Tells the other side I have read everything up to the newest message.
    pub async fn mark_read(&self, room_id: &RoomId) -> Result<()> {
        use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType as Send;
        use matrix_sdk::ruma::events::receipt::ReceiptThread;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let (cache, _drop) = room.event_cache().await.map_err(to_err)?;
        let last = cache
            .events()
            .await
            .map_err(to_err)?
            .iter()
            .rev()
            .find_map(|e| e.event_id().map(|x| x.to_owned()));
        if let Some(id) = last {
            // Read receipts switched off: only my own devices learn it.
            let kind = if self.reads_shared(room_id).await {
                Send::Read
            } else {
                Send::ReadPrivate
            };
            room.send_single_receipt(kind, ReceiptThread::Unthreaded, id)
                .await
                .map_err(to_err)?;
        }
        Ok(())
    }

    /// Up to when (ms) the other people in a chat have read. My messages sent
    /// at or before this time are shown as read.
    pub async fn read_until(&self, room_id: &RoomId) -> Result<u64> {
        Ok(self.read_receipt(room_id).await?.0)
    }

    /// (read up to, when they read it) in ms; (0, 0) when nothing is shared.
    /// "When" is the receipt's own time, so it shows only between people who
    /// both share read ticks (1:1 "오늘 10:38에 읽음", tip 421).
    pub async fn read_receipt(&self, room_id: &RoomId) -> Result<(u64, u64)> {
        use matrix_sdk::ruma::events::receipt::{ReceiptThread, ReceiptType};
        let room = self.client.get_room(room_id).context("unknown room")?;
        let me = self.client.user_id().context("no user")?.to_owned();
        let mut best = 0u64;
        let mut when = 0u64;
        // Fair rule: when I hide my read ticks I do not see theirs either.
        if !self.reads_shared(room_id).await {
            return Ok((0, 0));
        }
        for m in room
            .members(matrix_sdk::RoomMemberships::JOIN)
            .await
            .map_err(to_err)?
        {
            if m.user_id() == me {
                continue;
            }
            if let Some((eid, rcpt)) = room
                .load_user_receipt(ReceiptType::Read, &ReceiptThread::Unthreaded, m.user_id())
                .await
                .map_err(to_err)?
            {
                let at = match room.event(&eid, None).await {
                    Ok(ev) => ev
                        .raw()
                        .deserialize()
                        .ok()
                        .map(|e| u64::from(e.origin_server_ts().get())),
                    Err(_) => None,
                }
                .or(rcpt.ts.map(|t| u64::from(t.get())))
                .unwrap_or(0);
                if at > best {
                    best = at;
                    when = rcpt.ts.map(|t| u64::from(t.get())).unwrap_or(0);
                }
            }
        }
        Ok((best, when))
    }

    /// True when the 대화 복구 키 is already set up for this account.
    pub async fn has_recovery(&self) -> bool {
        matches!(
            self.client.encryption().recovery().state(),
            matrix_sdk::encryption::recovery::RecoveryState::Enabled
        )
    }

    /// New group or channel, always end-to-end encrypted. In a channel only
    /// the owner (creator) can post; subscribers read.
    pub async fn create_group(
        &self,
        name: &str,
        invite: &[OwnedUserId],
        channel: bool,
    ) -> Result<OwnedRoomId> {
        use matrix_sdk::ruma::{
            api::client::room::create_room::v3::{CreationContent, Request as CreateRoom},
            events::{InitialStateEvent, room::encryption::RoomEncryptionEventContent},
            serde::Raw,
        };
        let mut req = CreateRoom::new();
        req.name = Some(name.to_owned());
        req.invite = invite.to_vec();
        req.initial_state = vec![
            Raw::new(&InitialStateEvent::new(
                Default::default(),
                RoomEncryptionEventContent::with_recommended_defaults(),
            ))?
            .cast(),
        ];
        if channel {
            // Our server reads this mark (channel rules, history for subscribers).
            let mut cc: serde_json::Map<String, serde_json::Value> = serde_json::Map::new();
            cc.insert(
                "im.securemessenger.channel".into(),
                serde_json::Value::Bool(true),
            );
            // Room type, so a public link page can say "채널" before joining.
            cc.insert("type".into(), links::CHANNEL_TYPE.into());
            req.creation_content = Some(Raw::<CreationContent>::from_json_string(
                serde_json::Value::Object(cc).to_string(),
            )?);
            req.power_level_content_override = Some(Raw::from_json_string(
                r#"{"events_default":100,"invite":100}"#.to_owned(),
            )?);
        }
        let room = self.client.create_room(req).await.map_err(to_err)?;
        Ok(room.room_id().to_owned())
    }

    /// Renames a group or channel (admins only; the server checks).
    /// The other person's name (or ID) in a 1:1 chat.
    async fn dm_peer_name(&self, room: &matrix_sdk::Room) -> String {
        let me = self.client.user_id().map(|u| u.to_owned());
        let peer = room
            .direct_targets()
            .into_iter()
            .filter_map(|t| t.into_user_id())
            .find(|u| Some(u) != me.as_ref());
        let Some(peer) = peer else {
            return String::new();
        };
        match room.get_member_no_sync(&peer).await {
            Ok(Some(m)) => m.display_name().map(str::to_owned).unwrap_or_else(|| peer.localpart().to_owned()),
            _ => peer.localpart().to_owned(),
        }
    }

    pub async fn set_room_name(&self, room_id: &RoomId, name: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let name: String = name.trim().chars().take(128).collect();
        anyhow::ensure!(!name.is_empty(), "empty name");
        room.set_name(name).await.map_err(to_err)?;
        Ok(())
    }

    /// The description under a group or channel name ("" = none).
    pub async fn room_about(&self, room_id: &RoomId) -> String {
        self.client
            .get_room(room_id)
            .and_then(|r| r.topic())
            .unwrap_or_default()
    }

    pub async fn set_room_about(&self, room_id: &RoomId, text: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let text: String = text.trim().chars().take(255).collect();
        room.set_room_topic(&text).await.map_err(to_err)?;
        Ok(())
    }

    /// Adds people to a group or channel (admins; in groups anyone may).
    pub async fn invite_users(&self, room_id: &RoomId, users: &[String]) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        anyhow::ensure!(users.len() <= 50, "too many at once");
        for u in users {
            let uid = UserId::parse(u.as_str()).context("bad user id")?;
            room.invite_user_by_id(&uid).await.map_err(to_err)?;
        }
        Ok(())
    }

    /// Takes someone out (admins only, never the owner).
    pub async fn remove_member(&self, room_id: &RoomId, user_id: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let uid = UserId::parse(user_id).context("bad user id")?;
        anyhow::ensure!(
            Some(uid.as_str()) != self.client.user_id().map(|u| u.as_str()),
            "use leave for yourself"
        );
        room.kick_user(&uid, None).await.map_err(to_err)?;
        Ok(())
    }

    /// Makes someone an admin (50) or a member again (0). Owners only.
    pub async fn set_admin(&self, room_id: &RoomId, user_id: &str, admin: bool) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let uid = UserId::parse(user_id).context("bad user id")?;
        let me = self.client.user_id().context("no user")?;
        anyhow::ensure!(uid.as_str() != me.as_str(), "not yourself");
        let level = matrix_sdk::ruma::Int::from(if admin { 50u8 } else { 0u8 });
        room.update_power_levels(vec![(&uid, level)])
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Sets someone's level in a group or channel: -1 (can't write: timed
    /// message ban, the server refuses their messages), 0 member, 50 admin,
    /// 100 owner (owner handover). On myself only a step down (finishing a
    /// handover). The server checks that I may do it.
    pub async fn set_member_level(&self, room_id: &RoomId, user_id: &str, level: i64) -> Result<()> {
        anyhow::ensure!(matches!(level, -1 | 0 | 50 | 100), "bad level");
        let room = self.client.get_room(room_id).context("unknown room")?;
        let uid = UserId::parse(user_id).context("bad user id")?;
        let me = self.client.user_id().context("no user")?;
        if uid.as_str() == me.as_str() {
            let pl = room.power_levels().await.map_err(to_err)?;
            let now: i64 = match pl.for_user(me) {
                matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) => i.into(),
                _ => 100,
            };
            anyhow::ensure!(level < now && level >= 0, "only a step down");
        }
        room.update_power_levels(vec![(&uid, matrix_sdk::ruma::Int::from(level as i32))])
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Room switches kept in one state event: "sign" (channel posts show
    /// who wrote them) and "hide_members" (only admins see the list).
    pub async fn room_switch(&self, room_id: &RoomId, key: &str) -> bool {
        let Some(room) = self.client.get_room(room_id) else {
            return false;
        };
        let Ok(Some(raw)) = room.get_state_event(ROOM_SWITCHES.into(), "").await else {
            return false;
        };
        let json = match raw {
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => {
                r.json().get().to_owned()
            }
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => {
                r.json().get().to_owned()
            }
        };
        serde_json::from_str::<serde_json::Value>(&json)
            .ok()
            .and_then(|v| v["content"][key].as_bool())
            .unwrap_or(false)
    }

    pub async fn set_room_switch(&self, room_id: &RoomId, key: &str, on: bool) -> Result<()> {
        anyhow::ensure!(matches!(key, "sign" | "hide_members"), "unknown switch");
        let room = self.client.get_room(room_id).context("unknown room")?;
        let mut content = serde_json::json!({
            "sign": self.room_switch(room_id, "sign").await,
            "hide_members": self.room_switch(room_id, "hide_members").await,
        });
        content[key] = on.into();
        room.send_state_event_raw(ROOM_SWITCHES, "", content)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Room tool settings as a JSON object ("{}" when none). Unknown or
    /// bad values from the server are dropped.
    pub async fn room_config(&self, room_id: &RoomId) -> String {
        let Some(room) = self.client.get_room(room_id) else {
            return "{}".into();
        };
        let Ok(Some(raw)) = room.get_state_event(ROOM_CONFIG.into(), "").await else {
            if room.join_rule()
                == Some(matrix_sdk::ruma::events::room::join_rules::JoinRule::Public)
            {
                return serde_json::json!({ "new_media_days": NEW_MEDIA_DAYS_PUBLIC }).to_string();
            }
            return "{}".into();
        };
        let json = match raw {
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => {
                r.json().get().to_owned()
            }
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => {
                r.json().get().to_owned()
            }
        };
        let content = serde_json::from_str::<serde_json::Value>(&json)
            .ok()
            .and_then(|v| v.get("content").and_then(|c| c.as_object().cloned()))
            .unwrap_or_default();
        let mut clean: serde_json::Map<String, serde_json::Value> = content
            .into_iter()
            .filter(|(k, v)| check_room_config(k, v).is_ok())
            .collect();
        if !clean.contains_key("new_media_days")
            && room.join_rule()
                == Some(matrix_sdk::ruma::events::room::join_rules::JoinRule::Public)
        {
            clean.insert("new_media_days".into(), NEW_MEDIA_DAYS_PUBLIC.into());
        }
        serde_json::Value::Object(clean).to_string()
    }

    /// Changes one room tool setting (admins; the server checks the power
    /// level for state events). `value` is JSON; null removes the key.
    pub async fn set_room_config(&self, room_id: &RoomId, key: &str, value: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let v: serde_json::Value = serde_json::from_str(value).context("bad value")?;
        let mut content: serde_json::Map<String, serde_json::Value> =
            serde_json::from_str(&self.room_config(room_id).await).unwrap_or_default();
        if v.is_null() {
            content.remove(key);
        } else {
            // Words people write go end-to-end encrypted (see "texts"); the
            // old plain copies may only be removed.
            anyhow::ensure!(!PLAIN_TEXT_KEYS.contains(&key), "encrypted only");
            check_room_config(key, &v)?;
            content.insert(key.to_owned(), v);
        }
        let body = serde_json::Value::Object(content);
        anyhow::ensure!(body.to_string().len() <= 16 * 1024, "too big");
        room.send_state_event_raw(ROOM_CONFIG, "", body)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// 이름 색 (v1): one of 8 colours, kept on each member event as
    /// "app.burumy.color" so everyone in the room sees it.
    pub const NAME_COLORS: [&'static str; 8] = [
        "red", "orange", "yellow", "green", "teal", "blue", "purple", "pink",
    ];

    async fn my_member_content(
        &self,
        room: &matrix_sdk::Room,
    ) -> Result<serde_json::Map<String, serde_json::Value>> {
        let me = self.client.user_id().context("not logged in")?.to_owned();
        let raw = room
            .get_state_event(matrix_sdk::ruma::events::StateEventType::RoomMember, me.as_str())
            .await
            .map_err(to_err)?
            .context("not a member")?;
        let json = match raw {
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => {
                r.json().get().to_owned()
            }
            matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => {
                r.json().get().to_owned()
            }
        };
        let content = serde_json::from_str::<serde_json::Value>(&json)
            .ok()
            .and_then(|v| v.get("content").and_then(|c| c.as_object().cloned()))
            .unwrap_or_default();
        anyhow::ensure!(
            content.get("membership").and_then(|m| m.as_str()) == Some("join"),
            "not joined"
        );
        Ok(content)
    }

    /// 방마다 다른 프로필 (v1): my name in this room only. Empty = back to my
    /// usual name. `color`: one of [NAME_COLORS], "" = none, None = keep.
    pub async fn set_my_room_look(
        &self,
        room_id: &RoomId,
        name: Option<String>,
        color: Option<String>,
    ) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let mut content = self.my_member_content(&room).await?;
        if let Some(n) = name {
            let n = n.trim().to_owned();
            anyhow::ensure!(n.chars().count() <= 64, "name too long");
            let n = if n.is_empty() {
                self.client
                    .account()
                    .get_display_name()
                    .await
                    .map_err(to_err)?
                    .unwrap_or_default()
            } else {
                n
            };
            if n.is_empty() {
                content.remove("displayname");
            } else {
                content.insert("displayname".into(), n.into());
            }
        }
        if let Some(c) = color {
            if c.is_empty() {
                content.remove("app.burumy.color");
            } else {
                anyhow::ensure!(Self::NAME_COLORS.contains(&c.as_str()), "unknown colour");
                content.insert("app.burumy.color".into(), c.into());
            }
        }
        let me = self.client.user_id().context("not logged in")?.to_owned();
        room.send_state_event_raw("m.room.member", me.as_str(), serde_json::Value::Object(content))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// 멤버 태그 (tip 556): the short word I put next to my own name in this
    /// room, kept on my member event as "app.burumy.tag" (rooms where the
    /// admins allow it; a tag an admin gave me wins). "" removes it.
    pub async fn set_my_room_tag(&self, room_id: &RoomId, tag: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let mut content = self.my_member_content(&room).await?;
        let t = tag.trim();
        anyhow::ensure!(t.chars().count() <= 16, "tag too long");
        if t.is_empty() {
            content.remove("app.burumy.tag");
        } else {
            content.insert("app.burumy.tag".into(), t.into());
        }
        let me = self.client.user_id().context("not logged in")?.to_owned();
        room.send_state_event_raw("m.room.member", me.as_str(), serde_json::Value::Object(content))
            .await
            .map_err(to_err)?;
        Ok(())
    }

    /// Tags people put on themselves in this room: (user, tag).
    pub async fn member_tags(&self, room_id: &RoomId) -> Vec<(String, String)> {
        let Some(room) = self.client.get_room(room_id) else {
            return vec![];
        };
        let Ok(list) = room.get_state_events(matrix_sdk::ruma::events::StateEventType::RoomMember).await else {
            return vec![];
        };
        let mut out = vec![];
        for raw in list {
            let json = match raw {
                matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => {
                    r.json().get().to_owned()
                }
                matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => {
                    r.json().get().to_owned()
                }
            };
            let Ok(v) = serde_json::from_str::<serde_json::Value>(&json) else {
                continue;
            };
            if v.pointer("/content/membership").and_then(|x| x.as_str()) != Some("join") {
                continue;
            }
            let (Some(who), Some(t)) = (
                v.get("state_key").and_then(|x| x.as_str()),
                v.pointer("/content/app.burumy.tag").and_then(|x| x.as_str()),
            ) else {
                continue;
            };
            let t = t.trim();
            if !t.is_empty() && t.chars().count() <= 16 {
                out.push((who.to_owned(), t.to_owned()));
            }
        }
        out
    }

    /// 누가 읽었는지 (tip 384): in a group of at most [GROUP_READS_MAX]
    /// people, each other member's newest read receipt as (user, read up
    /// to ms, when ms). Empty when the group is bigger, or when I hide my
    /// own read ticks (the same fair rule as 1:1). People who hide theirs
    /// send no public receipt, so they never show up.
    pub const GROUP_READS_MAX: usize = 100;

    pub async fn group_receipts(&self, room_id: &RoomId) -> Result<Vec<(String, u64, u64)>> {
        use matrix_sdk::ruma::events::receipt::{ReceiptThread, ReceiptType};
        let room = self.client.get_room(room_id).context("unknown room")?;
        let me = self.client.user_id().context("no user")?.to_owned();
        if !self.reads_shared(room_id).await {
            return Ok(vec![]);
        }
        let members = room
            .members(matrix_sdk::RoomMemberships::JOIN)
            .await
            .map_err(to_err)?;
        if members.len() > Self::GROUP_READS_MAX {
            return Ok(vec![]);
        }
        let mut out = vec![];
        for m in members {
            if m.user_id() == me {
                continue;
            }
            let Some((eid, rcpt)) = room
                .load_user_receipt(ReceiptType::Read, &ReceiptThread::Unthreaded, m.user_id())
                .await
                .map_err(to_err)?
            else {
                continue;
            };
            let upto = match room.event(&eid, None).await {
                Ok(ev) => ev
                    .raw()
                    .deserialize()
                    .ok()
                    .map(|e| u64::from(e.origin_server_ts().get())),
                Err(_) => None,
            }
            .or(rcpt.ts.map(|t| u64::from(t.get())))
            .unwrap_or(0);
            let at = rcpt.ts.map(|t| u64::from(t.get())).unwrap_or(upto);
            if upto > 0 {
                out.push((m.user_id().to_string(), upto, at));
            }
        }
        Ok(out)
    }

    /// Name colours people picked in this room: (user, colour).
    pub async fn name_colors(&self, room_id: &RoomId) -> Vec<(String, String)> {
        let Some(room) = self.client.get_room(room_id) else {
            return vec![];
        };
        let Ok(list) = room.get_state_events(matrix_sdk::ruma::events::StateEventType::RoomMember).await else {
            return vec![];
        };
        let mut out = vec![];
        for raw in list {
            let json = match raw {
                matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => {
                    r.json().get().to_owned()
                }
                matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Stripped(r) => {
                    r.json().get().to_owned()
                }
            };
            let Ok(v) = serde_json::from_str::<serde_json::Value>(&json) else {
                continue;
            };
            let (Some(who), Some(c)) = (
                v.get("state_key").and_then(|x| x.as_str()),
                v.pointer("/content/app.burumy.color").and_then(|x| x.as_str()),
            ) else {
                continue;
            };
            if Self::NAME_COLORS.contains(&c) {
                out.push((who.to_owned(), c.to_owned()));
            }
        }
        out
    }

    /// Bans someone (they can't come back until unbanned) or lifts it.
    pub async fn set_banned(&self, room_id: &RoomId, user_id: &str, banned: bool) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let uid = UserId::parse(user_id).context("bad user id")?;
        anyhow::ensure!(
            Some(uid.as_str()) != self.client.user_id().map(|u| u.as_str()),
            "not yourself"
        );
        if banned {
            room.ban_user(&uid, None).await.map_err(to_err)?;
        } else {
            room.unban_user(&uid, None).await.map_err(to_err)?;
        }
        Ok(())
    }

    /// People banned from a room.
    pub async fn banned(&self, room_id: &RoomId) -> Result<Vec<String>> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let list = room
            .members(matrix_sdk::RoomMemberships::BAN)
            .await
            .map_err(to_err)?;
        Ok(list.iter().map(|m| m.user_id().to_string()).collect())
    }

    /// My role here: "owner", "admin" or "member".
    pub async fn my_role(&self, room_id: &RoomId) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let me = self.client.user_id().context("no user")?;
        let pl = room.power_levels().await.map_err(to_err)?;
        let level: i64 = match pl.for_user(me) {
            matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Infinite => 100,
            matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) => i.into(),
            _ => 0,
        };
        Ok(match level {
            100.. => "owner",
            50.. => "admin",
            _ => "member",
        }
        .into())
    }

    /// Sets (or with no bytes, takes off) a group/channel photo. Admins only.
    /// The photo is encrypted on this phone and its key travels inside the
    /// room's encryption, so the server can't see it. A public room (anyone
    /// may join) also gets the plain photo, for its link card and web page.
    pub async fn set_room_photo(&self, room_id: &RoomId, mime: &str, data: Vec<u8>) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if self.my_role(room_id).await? == "member" {
            anyhow::bail!("not an admin");
        }
        let content = if data.is_empty() {
            serde_json::json!({})
        } else {
            let mut cursor = std::io::Cursor::new(data.clone());
            let file = self.client.upload_encrypted_file(&mut cursor).await.map_err(to_err)?;
            serde_json::json!({ "photo": { "file": file, "mimetype": mime } })
        };
        room.send_raw(ROOM_PHOTO_TYPE, content).await.map_err(to_err)?;
        let public = self.room_link(room_id).await.kind == "public";
        self.plain_room_photo(room_id, public, Some((mime, data))).await
    }

    /// Keeps the plain (server-readable) copy of the room photo in step
    /// with the link: only a public room has one, for its link card. A
    /// private room's copy is taken off. [photo] None = use the current one.
    pub(crate) async fn plain_room_photo(&self, room_id: &RoomId, public: bool, photo: Option<(&str, Vec<u8>)>) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let photo = match photo {
            Some((m, d)) => Some((m.to_owned(), d)),
            None => match self.room_photo_event(&room).await {
                Some((_, c)) if c.get("photo").is_some() => {
                    let m = c.pointer("/photo/mimetype").and_then(|m| m.as_str()).unwrap_or("image/jpeg").to_owned();
                    self.room_photo(room_id).await.ok().flatten().map(|d| (m, d))
                }
                _ => None,
            },
        };
        match photo {
            Some((m, d)) if public && !d.is_empty() => {
                let m: mime::Mime = m.parse().map_err(to_err)?;
                room.upload_avatar(&m, d, None).await.map_err(to_err)?;
            }
            _ if room.avatar_url().is_some() => {
                room.remove_avatar().await.map_err(to_err)?;
            }
            _ => {}
        }
        Ok(())
    }

    /// The newest room photo event an admin sent: (time, content).
    async fn room_photo_event(&self, room: &matrix_sdk::Room) -> Option<(u64, serde_json::Value)> {
        let pl = room.power_levels().await.ok()?;
        let (cache, _drop) = room.event_cache().await.ok()?;
        let mut best: Option<(u64, serde_json::Value)> = None;
        for e in cache.events().await.unwrap_or_default() {
            // Only end-to-end encrypted ones (a server can't slip one in).
            let Some(v) = trusted_json(&e) else {
                continue;
            };
            if v.get("type").and_then(|t| t.as_str()) != Some(ROOM_PHOTO_TYPE) {
                continue;
            }
            let Some(sender) = v.get("sender").and_then(|x| x.as_str()).and_then(|x| OwnedUserId::try_from(x).ok()) else {
                continue;
            };
            let admin = match pl.for_user(&sender) {
                matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Infinite => true,
                matrix_sdk::ruma::events::room::power_levels::UserPowerLevel::Int(i) => i64::from(i) >= 50,
                _ => false,
            };
            if !admin {
                continue;
            }
            let ts = v.get("origin_server_ts").and_then(|t| t.as_u64()).unwrap_or(0);
            if best.as_ref().is_none_or(|(t, _)| ts >= *t) {
                best = Some((ts, v["content"].clone()));
            }
        }
        best
    }

    /// A group/channel photo: the newest encrypted one an admin sent, else
    /// a public room's plain photo. None = no photo.
    pub async fn room_photo(&self, room_id: &RoomId) -> Result<Option<Vec<u8>>> {
        use matrix_sdk::{
            media::{MediaFormat, MediaRequestParameters},
            ruma::events::room::{EncryptedFile, MediaSource},
        };
        let room = self.client.get_room(room_id).context("unknown room")?;
        if let Some((_, c)) = self.room_photo_event(&room).await {
            let Some(f) = c.pointer("/photo/file") else {
                return Ok(None);
            };
            let file = serde_json::from_value::<EncryptedFile>(f.clone()).map_err(to_err)?;
            let bytes = self
                .client
                .media()
                .get_media_content(&MediaRequestParameters { source: MediaSource::Encrypted(Box::new(file)), format: MediaFormat::File }, true)
                .await
                .map_err(to_err)?;
            return Ok(Some(bytes));
        }
        if self.room_link(room_id).await.kind != "public" {
            return Ok(None);
        }
        room.avatar(MediaFormat::File).await.map_err(to_err)
    }

    /// An admin's phone sends the photo again after people joined since it
    /// was set (new members can't open older encrypted messages). True when
    /// it was sent again.
    pub async fn reshare_room_photo(&self, room_id: &RoomId) -> Result<bool> {
        use matrix_sdk::ruma::events::StateEventType;
        let room = self.client.get_room(room_id).context("unknown room")?;
        if self.my_role(room_id).await? == "member" {
            return Ok(false);
        }
        let Some((ts, content)) = self.room_photo_event(&room).await else {
            return Ok(false);
        };
        if content.get("photo").is_none() {
            return Ok(false);
        }
        let mut newest_join = 0u64;
        for raw in room.get_state_events(StateEventType::RoomMember).await.unwrap_or_default() {
            let json = match raw {
                matrix_sdk::deserialized_responses::RawAnySyncOrStrippedState::Sync(r) => r.json().get().to_owned(),
                _ => continue,
            };
            let Ok(v) = serde_json::from_str::<serde_json::Value>(&json) else {
                continue;
            };
            if v.pointer("/content/membership").and_then(|m| m.as_str()) == Some("join") {
                newest_join = newest_join.max(v.get("origin_server_ts").and_then(|t| t.as_u64()).unwrap_or(0));
            }
        }
        if newest_join <= ts {
            return Ok(false);
        }
        let mut content = content;
        content["again"] = serde_json::Value::Bool(true);
        room.send_raw(ROOM_PHOTO_TYPE, content).await.map_err(to_err)?;
        Ok(true)
    }

    /// Whether I may write in this chat (false for channel subscribers).
    pub async fn can_post(&self, room_id: &RoomId) -> Result<bool> {
        use matrix_sdk::ruma::events::MessageLikeEventType;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let me = self.client.user_id().context("no user")?;
        let pl = room.power_levels().await.map_err(to_err)?;
        Ok(pl.user_can_send_message(me, MessageLikeEventType::RoomMessage))
    }

    /// True when this room was made as a channel.
    pub async fn is_channel(&self, room_id: &RoomId) -> bool {
        let Some(room) = self.client.get_room(room_id) else {
            return false;
        };
        match room.get_state_event_static::<matrix_sdk::ruma::events::room::create::RoomCreateEventContent>().await {
            Ok(Some(matrix_sdk::deserialized_responses::RawSyncOrStrippedState::Sync(raw))) => raw.json().get().contains("im.securemessenger.channel"),
            Ok(Some(matrix_sdk::deserialized_responses::RawSyncOrStrippedState::Stripped(raw))) => raw.json().get().contains("im.securemessenger.channel"),
            _ => false,
        }
    }

    /// A reply with a link card set up by the sender (tips 400 + 401). Like
    /// other replies it carries the chat timer.
    pub async fn reply_link(&self, room_id: &RoomId, to_event: &str, text: &str, link: &LinkChoice) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::{AddMentions, ForwardThread, ReplyMetadata};
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room.latest_encryption_state().await.map_err(to_err)?.is_encrypted() {
            bail!("refusing to send into a room without encryption");
        }
        let eid = matrix_sdk::ruma::EventId::parse(to_event)?;
        let target = room.event(&eid, None).await.map_err(to_err)?;
        let sender = target.raw().deserialize().map_err(to_err)?.sender().to_owned();
        let content = RoomMessageEventContent::text_plain(text).make_reply_to(ReplyMetadata::new(&eid, &sender, None), ForwardThread::No, AddMentions::No);
        let mut v = serde_json::to_value(content)?;
        Box::pin(self.add_preview(&mut v, text, link)).await;
        Box::pin(self.send_timed_value(&room, v)).await
    }

    pub async fn reply(&self, room_id: &RoomId, to_event: &str, text: &str) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::{AddMentions, ForwardThread, ReplyMetadata};
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(to_event)?;
        let target = room.event(&eid, None).await.map_err(to_err)?;
        let sender = target
            .raw()
            .deserialize()
            .map_err(to_err)?
            .sender()
            .to_owned();
        let content = RoomMessageEventContent::text_plain(text).make_reply_to(
            ReplyMetadata::new(&eid, &sender, None),
            ForwardThread::No,
            AddMentions::No,
        );
        // Through the usual path so the chat timer and 보내는 이름 apply.
        let v = serde_json::to_value(content)?;
        Box::pin(self.send_timed_value(&room, v)).await
    }

    /// 부분 인용 답장 (Telegram tip 399): a reply that shows only the
    /// picked part of `to_event`. With `to_event` empty it is "다른 대화에서
    /// 답장": no link to the other chat's message (it lives in another
    /// room); the copied words and the writer's name travel encrypted here.
    pub async fn reply_quote(&self, room_id: &RoomId, to_event: &str, text: &str, quote: &str, quote_name: &str) -> Result<String> {
        use matrix_sdk::ruma::events::room::message::{AddMentions, ForwardThread, ReplyMetadata};
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room.latest_encryption_state().await.map_err(to_err)?.is_encrypted() {
            bail!("refusing to send into a room without encryption");
        }
        let mut content = RoomMessageEventContent::text_plain(text);
        let name = if to_event.is_empty() { Some(quote_name) } else { None };
        if !to_event.is_empty() {
            let eid = matrix_sdk::ruma::EventId::parse(to_event)?;
            let target = room.event(&eid, None).await.map_err(to_err)?;
            let sender = target.raw().deserialize().map_err(to_err)?.sender().to_owned();
            content = content.make_reply_to(ReplyMetadata::new(&eid, &sender, None), ForwardThread::No, AddMentions::No);
        }
        let mut v = serde_json::to_value(content)?;
        if let Some(q) = quote_value(quote, name) {
            v[QUOTE_FIELD] = q;
        }
        let id = Box::pin(self.send_timed_value(&room, v)).await?;
        Ok(id)
    }

    /// "스레드로 답장": a message inside the thread that starts at `root`.
    pub async fn reply_in_thread(
        &self,
        room_id: &RoomId,
        root: &str,
        text: &str,
    ) -> Result<String> {
        use matrix_sdk::ruma::events::relation::Thread;
        use matrix_sdk::ruma::events::room::message::Relation;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let root = matrix_sdk::ruma::OwnedEventId::try_from(root).map_err(to_err)?;
        let mut content = RoomMessageEventContent::text_plain(text);
        content.relates_to = Some(Relation::Thread(Thread::plain(root.clone(), root)));
        let r = room.send(content).await.map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    pub async fn edit(&self, room_id: &RoomId, event_id: &str, text: &str) -> Result<()> {
        use matrix_sdk::ruma::events::room::message::ReplacementMetadata;
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        let original = room.event(&eid, None).await.map_err(to_err)?;
        let parsed = original.raw().deserialize().map_err(to_err)?;
        anyhow::ensure!(
            Some(parsed.sender()) == self.client.user_id(),
            "only your own messages"
        );
        let sent: u64 = parsed.origin_server_ts().get().into();
        let group = self.is_channel(room_id).await || room.joined_members_count() > 2;
        anyhow::ensure!(
            edit_window_open(group, sent, now_ms()),
            "edit window closed"
        );
        let content = RoomMessageEventContent::text_plain(text)
            .make_replacement(ReplacementMetadata::new(eid, None));
        room.send(content).await.map_err(to_err)?;
        Ok(())
    }

    /// Sends one of the built-in stickers (e.g. "buru_01_hello").
    pub async fn send_sticker(&self, room_id: &RoomId, sticker_id: &str) -> Result<String> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        if !room
            .latest_encryption_state()
            .await
            .map_err(to_err)?
            .is_encrypted()
        {
            bail!("refusing to send into a room without encryption");
        }
        let mut data = serde_json::Map::new();
        data.insert(
            "sticker".into(),
            serde_json::Value::String(sticker_id.to_owned()),
        );
        let content =
            RoomMessageEventContent::new(MessageType::new(STICKER_TYPE, "[sticker]".into(), data)?);
        Box::pin(self.send_timed(&room, content)).await
    }

    /// Adds an emoji under a message.
    pub async fn react(&self, room_id: &RoomId, event_id: &str, key: &str) -> Result<String> {
        use matrix_sdk::ruma::events::{reaction::ReactionEventContent, relation::Annotation};
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        let r = room
            .send(ReactionEventContent::new(Annotation::new(
                eid,
                key.to_owned(),
            )))
            .await
            .map_err(to_err)?;
        Ok(r.response.event_id.to_string())
    }

    /// Pins a message at the top of the chat (pinned = true) or unpins it.
    pub async fn pin(&self, room_id: &RoomId, event_id: &str, pinned: bool) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        if pinned {
            room.pin_event(&eid).await.map_err(to_err)?;
        } else {
            room.unpin_event(&eid).await.map_err(to_err)?;
        }
        Ok(())
    }

    /// Pinned messages, newest pin last.
    pub fn pinned(&self, room_id: &RoomId) -> Vec<String> {
        self.client
            .get_room(room_id)
            .and_then(|r| r.pinned_event_ids())
            .unwrap_or_default()
            .into_iter()
            .map(|e| e.to_string())
            .collect()
    }

    /// Deletes a message for everyone in the chat.
    pub async fn delete_message(&self, room_id: &RoomId, event_id: &str) -> Result<()> {
        let room = self.client.get_room(room_id).context("unknown room")?;
        let eid = matrix_sdk::ruma::EventId::parse(event_id)?;
        room.redact(&eid, None, None).await.map_err(to_err)?;
        if self.web_posts(room_id).await.iter().any(|(id, _)| id == event_id) {
            let _ = self.web_unpost(room_id, event_id).await;
        }
        Ok(())
    }

    pub async fn set_typing(&self, room_id: &RoomId, typing: bool) -> Result<()> {
        if typing && !self.setting_on("send_typing", true).await {
            return Ok(());
        }
        let room = self.client.get_room(room_id).context("unknown room")?;
        room.typing_notice(typing).await.map_err(to_err)?;
        Ok(())
    }

    /// Other people typing in this chat right now.
    pub fn typing_users(&self, room_id: &RoomId) -> Vec<String> {
        let me = self.client.user_id().map(|u| u.to_string());
        self.typing
            .lock()
            .ok()
            .and_then(|m| m.get(room_id).cloned())
            .unwrap_or_default()
            .into_iter()
            .filter(|u| Some(u) != me.as_ref())
            .collect()
    }

    pub fn set_tz_offset(&self, minutes: i32) {
        self.tz.store(minutes, std::sync::atomic::Ordering::Relaxed);
    }

    /// This device's own settings (kept in the encrypted local store).
    pub async fn prefs(&self) -> Prefs {
        let raw = self
            .client
            .state_store()
            .get_custom_value(b"burumy.prefs.v1")
            .await
            .ok()
            .flatten();
        raw.and_then(|r| serde_json::from_slice(&r).ok())
            .unwrap_or_default()
    }

    /// A yes/no setting from [Prefs::settings] ("1" / "0").
    /// Read ticks are shared in this chat: the app-wide switch and the
    /// per-chat switch ("send_read:<room>") must both be on.
    async fn reads_shared(&self, room_id: &RoomId) -> bool {
        self.setting_on("send_read", true).await
            && self.setting_on(&format!("send_read:{room_id}"), true).await
    }

    pub async fn setting_on(&self, key: &str, default: bool) -> bool {
        match self.prefs().await.settings.get(key).map(String::as_str) {
            Some("1") => true,
            Some("0") => false,
            _ => default,
        }
    }

    pub async fn set_prefs(&self, p: &Prefs) -> Result<()> {
        self.client
            .state_store()
            .set_custom_value_no_read(b"burumy.prefs.v1", serde_json::to_vec(p)?)
            .await
            .map_err(to_err)?;
        Ok(())
    }

    pub fn client(&self) -> &Client {
        &self.client
    }

    /// Starts an emoji check with another person (their phone gets a request).
    pub async fn request_user_verification(&self, other: &UserId) -> Result<String> {
        let id = self
            .client
            .encryption()
            .request_user_identity(other)
            .await
            .map_err(to_err)?
            .context("no identity for that user yet")?;
        let req = id.request_verification().await.map_err(to_err)?;
        Ok(req.flow_id().to_owned())
    }

    /// Accepts an emoji check request.
    pub async fn accept_verification(&self, other: &UserId, flow_id: &str) -> Result<()> {
        let req = self
            .client
            .encryption()
            .get_verification_request(other, flow_id)
            .await
            .context("no such request")?;
        req.accept().await.map_err(to_err)?;
        Ok(())
    }

    pub async fn start_sas(&self, other: &UserId, flow_id: &str) -> Result<()> {
        let req = self
            .client
            .encryption()
            .get_verification_request(other, flow_id)
            .await
            .context("no such request")?;
        req.start_sas()
            .await
            .map_err(to_err)?
            .context("other side cannot do emoji")?;
        Ok(())
    }

    /// The 7 emoji (with their English names) once both sides are ready.
    pub async fn sas_emoji(&self, other: &UserId, flow_id: &str) -> Result<Option<Vec<String>>> {
        let Some(v) = self
            .client
            .encryption()
            .get_verification(other, flow_id)
            .await
        else {
            return Ok(None);
        };
        let Some(sas) = v.sas() else { return Ok(None) };
        if !sas.we_started() && !sas.can_be_presented() {
            let _ = sas.accept().await;
        }
        Ok(sas.emoji().map(|e| {
            e.iter()
                .map(|x| format!("{} {}", x.symbol, x.description))
                .collect()
        }))
    }

    pub async fn confirm_sas(&self, other: &UserId, flow_id: &str) -> Result<bool> {
        let v = self
            .client
            .encryption()
            .get_verification(other, flow_id)
            .await
            .context("no verification")?;
        let sas = v.sas().context("not an emoji check")?;
        sas.confirm().await.map_err(to_err)?;
        Ok(sas.is_done())
    }

    pub async fn is_user_verified(&self, other: &UserId) -> Result<bool> {
        Ok(self
            .client
            .encryption()
            .get_user_identity(other)
            .await
            .map_err(to_err)?
            .map(|i| i.is_verified())
            .unwrap_or(false))
    }

    pub async fn logout(&self) -> Result<()> {
        self.client.matrix_auth().logout().await.map_err(to_err)?;
        Ok(())
    }
}

/// The event as JSON, only when it may be trusted: it came end-to-end
/// encrypted, or it is room state / a deletion (which Matrix never encrypts).
/// Plain message events inside our encrypted chats are dropped, so nobody
/// can fake a message, a vote, a tick or a call line around the encryption.
pub(crate) fn trusted_json(
    e: &matrix_sdk::deserialized_responses::TimelineEvent,
) -> Option<serde_json::Value> {
    let v: serde_json::Value = serde_json::from_str(e.raw().json().get()).ok()?;
    if !matches!(e.kind, TimelineEventKind::PlainText { .. }) {
        return Some(v);
    }
    let structural = v.get("state_key").is_some() || v["type"].as_str() == Some("m.room.redaction");
    structural.then_some(v)
}

#[cfg(test)]
mod quote_tests {
    use super::*;

    #[test]
    fn quote_cut_and_name() {
        let long = "가".repeat(QUOTE_MAX + 50);
        let v = quote_value(&long, Some("  에릭  ")).unwrap();
        let (t, n) = read_quote(&v);
        assert_eq!(t.unwrap().chars().count(), QUOTE_MAX);
        assert_eq!(n.as_deref(), Some("에릭"));
        // Same-chat reply: no name kept.
        let (_, n) = read_quote(&quote_value("hi", None).unwrap());
        assert!(n.is_none());
        // Empty words = no quote at all (a name alone is dropped).
        assert!(quote_value("   ", Some("x")).is_none());
        assert_eq!(read_quote(&serde_json::json!({"name": "x"})), (None, None));
        assert_eq!(read_quote(&serde_json::json!({"text": 5})), (None, None));
    }
}

#[cfg(test)]
mod trust_tests {
    use super::trusted_json;
    use matrix_sdk::deserialized_responses::TimelineEvent;
    use matrix_sdk::ruma::serde::Raw;

    fn plain(v: serde_json::Value) -> TimelineEvent {
        TimelineEvent::from_plaintext(Raw::from_json(serde_json::value::to_raw_value(&v).unwrap()))
    }

    #[test]
    fn plaintext_messages_are_not_trusted() {
        let base =
            serde_json::json!({ "event_id": "$x", "sender": "@evil:x", "origin_server_ts": 1 });
        let mut msg = base.clone();
        msg["type"] = "m.room.message".into();
        msg["content"] = serde_json::json!({ "msgtype": "m.text", "body": "fake" });
        assert!(
            trusted_json(&plain(msg)).is_none(),
            "an unencrypted message is ignored"
        );
        let mut tick = base.clone();
        tick["type"] = "app.burumy.checklist.mark".into();
        tick["content"] = serde_json::json!({ "checklist": "$c", "item": "i0", "done": true });
        assert!(
            trusted_json(&plain(tick)).is_none(),
            "an unencrypted tick is ignored"
        );
        let mut state = base.clone();
        state["type"] = "m.room.name".into();
        state["state_key"] = "".into();
        state["content"] = serde_json::json!({ "name": "n" });
        assert!(
            trusted_json(&plain(state)).is_some(),
            "room state stays readable"
        );
        let mut red = base;
        red["type"] = "m.room.redaction".into();
        red["redacts"] = "$y".into();
        red["content"] = serde_json::json!({});
        assert!(
            trusted_json(&plain(red)).is_some(),
            "deletions stay readable"
        );
    }
}

#[cfg(test)]
mod room_config_tests {
    use super::check_room_config;
    use serde_json::json;

    #[test]
    fn only_known_keys_with_sane_values() {
        assert!(check_room_config("rules", &json!("1. 서로 존중해요")).is_ok());
        assert!(check_room_config("join_questions", &json!(["왜 들어오고 싶어요?", {"q":"BPM?","choices":["a","b"],"right":1}])).is_ok());
        assert!(check_room_config("join_questions", &json!([{"q":"BPM?","choices":["a"],"right":0}])).is_err());
        assert!(check_room_config("join_questions", &json!([{"q":"BPM?","choices":["a","b"],"right":2}])).is_err());
        assert!(check_room_config("join_questions", &json!(["", "x"])).is_err());
        assert!(check_room_config("gate", &json!({"on":true,"need_answers":true,"words":["casino"],"ai":false,"about":"음악 만드는 사람"})).is_ok());
        assert!(check_room_config("gate", &json!({"on":"yes"})).is_err());
        assert!(check_room_config("gate", &json!({"token":"x"})).is_err());
        // Batch #16 (groups): anonymous admins, own tags, anti-spam.
        assert!(check_room_config("anon", &json!({"@a:x": [[1, 0]], "@b:x": [[1, 5], [9, 0]]})).is_ok());
        assert!(check_room_config("anon", &json!({"nope": [[1, 0]]})).is_err());
        assert!(check_room_config("anon", &json!({"@a:x": [[1]]})).is_err());
        assert!(check_room_config("anon", &json!({"@a:x": [[1, -1]]})).is_err());
        assert!(check_room_config("own_tags", &json!(true)).is_ok());
        assert!(check_room_config("antispam", &json!("on")).is_err());
        assert!(check_room_config("spam_ok", &json!(["@a:x"])).is_ok());
        assert!(check_room_config("spam_ok", &json!(["a"])).is_err());
        assert!(check_room_config("rules", &json!("x".repeat(2001))).is_err());
        assert!(check_room_config("rules", &json!(5)).is_err());
        assert!(check_room_config("reactions", &json!("some")).is_ok());
        assert!(check_room_config("reactions", &json!("evil")).is_err());
        assert!(check_room_config("reactions_set", &json!(["❤️", "👍"])).is_ok());
        assert!(check_room_config("reactions_set", &json!([""])).is_err());
        assert!(check_room_config("reactions_max", &json!(0)).is_err());
        assert!(check_room_config("reactions_max", &json!(11)).is_ok());
        assert!(check_room_config("discussion", &json!("!abc:example.org")).is_ok());
        assert!(check_room_config("discussion", &json!("not a room")).is_err());
        assert!(check_room_config("password", &json!("x")).is_err());
        let h = "ab".repeat(32);
        assert!(check_room_config("texts", &json!({"h": h, "w": true, "r": false})).is_ok());
        assert!(check_room_config("texts", &json!({"h": h})).is_ok());
        assert!(check_room_config("topics", &json!({"h": h})).is_ok());
        assert!(check_room_config("topics", &json!({"h": h, "on": true})).is_err());
        assert!(check_room_config("topics", &json!({"list": ["plain"]})).is_err());
        assert!(check_room_config("texts", &json!({"h": "zz"})).is_err());
        assert!(check_room_config("texts", &json!({"w": true})).is_err());
        assert!(check_room_config("texts", &json!({"h": h, "welcome": "plain"})).is_err());
        assert!(check_room_config("texts", &json!({"h": h, "w": "yes"})).is_err());
    }
}

#[cfg(test)]
mod edit_rule_tests {
    use super::*;

    #[test]
    fn what_an_edit_may_change() {
        // Words stay words.
        assert_eq!(edit_rule("text", "text", false, false), EditKind::Text);
        // New words on the same photo: anywhere, also public rooms.
        assert_eq!(edit_rule("image", "image", true, false), EditKind::Caption);
        // A new photo, or a photo added to a text: only outside public rooms.
        assert_eq!(edit_rule("image", "image", false, true), EditKind::Media);
        assert_eq!(edit_rule("image", "video", false, true), EditKind::Media);
        assert_eq!(edit_rule("text", "image", false, true), EditKind::Media);
        assert_eq!(edit_rule("image", "image", false, false), EditKind::Refused);
        assert_eq!(edit_rule("text", "image", false, false), EditKind::Refused);
        // A photo never turns back into plain words; other kinds stay as sent.
        assert_eq!(edit_rule("image", "text", false, true), EditKind::Refused);
        assert_eq!(edit_rule("poll", "text", false, true), EditKind::Refused);
        assert_eq!(edit_rule("text", "poll", false, true), EditKind::Refused);
    }
}

#[cfg(test)]
mod emoji_status_tests {
    use super::{read_status, status_emoji_ok};
    use serde_json::json;

    #[test]
    fn only_one_emoji_is_a_status() {
        for ok in ["", "🏖️", "❤️", "👨‍💻", "🧑🏽‍🎓", "🇰🇷"] {
            assert!(status_emoji_ok(ok), "{ok}");
        }
        for bad in ["hi", "🏖️ 휴가", "1", "<b>", "🏖️🏖️🏖️🏖️🏖️🏖️🏖️🏖️🏖️🏖️🏖️"] {
            assert!(!status_emoji_ok(bad), "{bad}");
        }
    }

    #[test]
    fn a_status_ends_on_time() {
        let now = 1_800_000_000_000u64;
        assert_eq!(read_status(&json!({ "e": "🏖️", "until": 0 }), now), ("🏖️".into(), 0));
        assert_eq!(read_status(&json!({ "e": "🏖️", "until": now + 1 }), now), ("🏖️".into(), now + 1));
        assert_eq!(read_status(&json!({ "e": "🏖️", "until": now }), now), (String::new(), 0));
        assert_eq!(read_status(&json!({ "e": "", "until": 0 }), now), (String::new(), 0));
        assert_eq!(read_status(&json!({ "e": "hello" }), now), (String::new(), 0));
    }
}

#[cfg(test)]
mod post_as_tests {
    use super::clean_post_as;
    use serde_json::json;

    #[test]
    fn keeps_only_known_parts() {
        assert_eq!(clean_post_as(&json!({"ch": true, "x": 1})).as_deref(), Some(r#"{"ch":true}"#));
        let v: serde_json::Value = serde_json::from_str(&clean_post_as(&json!({"room": "!a:b", "addr": "news", "evil": "x"})).unwrap()).unwrap();
        assert_eq!(v, json!({"room": "!a:b", "addr": "news"}));
        assert_eq!(clean_post_as(&json!({"room": "@me:b"})), None);
        assert_eq!(clean_post_as(&json!({"ch": false})), None);
        assert_eq!(clean_post_as(&json!("x")), None);
    }
}
