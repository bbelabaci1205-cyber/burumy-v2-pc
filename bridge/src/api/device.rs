// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! What the Flutter app can ask one logged-in device to do.

use std::path::PathBuf;

use anyhow::Result;
use burumy_engine::{
    Engine,
    matrix_sdk::ruma::{RoomId, UserId},
};
use flutter_rust_bridge::frb;

/// One message as the chat screen shows it.
pub struct ChatMessage {
    pub event_id: String,
    pub sender: String,
    /// None = could not be opened (key missing).
    pub body: Option<String>,
    pub was_encrypted: bool,
    /// Milliseconds since 1970 (server time).
    pub ts: u64,
    pub mine: bool,
    /// "text", "image", "video", "audio", "file", "sticker" or "locked".
    pub kind: String,
    /// The message this one answers, if any.
    pub reply_to: Option<String>,
    /// First message of its thread ("스레드로 답장").
    pub thread_root: Option<String>,
    /// 주제 (tip 527): topic id from inside the encrypted content; None = 일반.
    pub topic: Option<String>,
    pub edited: bool,
    /// When it was last changed (ms), and the words as first sent.
    pub edited_at: Option<u64>,
    pub first_body: Option<String>,
    pub reactions: Vec<ReactionRow>,
    /// Disappears at this time (ms), if the chat has a timer.
    pub expires_at: Option<u64>,
    /// Photo/video that opens only once, and whether it was opened.
    pub view_once: bool,
    pub opened: bool,
    pub forwarded: bool,
    pub preview: Option<LinkPreviewRow>,
    pub voice: Option<VoiceRow>,
    /// 움직이는 사진: play style and clip length.
    pub live: Option<LiveRow>,
    pub poll: Option<PollRow>,
    pub bubble: bool,
    pub call: Option<CallRow>,
    /// Words under a photo, video or file.
    pub caption: Option<String>,
    /// File size in bytes (photo, video, file, voice), when the sender wrote it.
    pub size: Option<u64>,
    pub checklist: Option<ChecklistRow>,
    pub meetup: Option<MeetupRow>,
    /// Shared contact's user id (kind "contact").
    pub contact: Option<String>,
    /// FAQ, guide, links, formatted post, giveaway, form, check-in.
    pub card: Option<CardRow>,
    /// 부분 인용 (tip 399): the picked words; with `quote_name` and no
    /// `reply_to` they were copied from another chat.
    pub quote: Option<String>,
    pub quote_name: Option<String>,
    /// 설명 위로 (tip 452).
    pub caption_above: bool,
    /// The file was swapped by an edit: download it from this event.
    pub media_from: Option<String>,
    pub media_changed: bool,
    /// 보내는 이름 (tips 472 + 310): who it was sent as (JSON), if not me.
    pub post_as: Option<String>,
}

/// 임시 글 이어쓰기: a draft from another of my devices (empty = cleared).
pub struct SyncedDraftRow {
    pub room_id: String,
    pub text: String,
    pub at: u64,
}

/// 움직이는 사진: "live" (once), "loop" or "bounce", and the clip length.
pub struct LiveRow {
    pub style: String,
    pub duration_ms: u64,
}

pub struct CardRow {
    pub kind: String,
    /// Checked data as JSON.
    pub data: String,
    /// Maker's numbers as "key=n" pairs.
    pub counts: Vec<String>,
    pub winners: Vec<String>,
    pub closed: bool,
    /// My own answer as JSON ("" = none).
    pub mine: String,
    /// I won (told only to me when names stay private).
    pub won: bool,
}

/// One answer on the maker's phone: who, and the answer as JSON.
pub struct CardAnswerRow {
    pub user: String,
    pub answer: String,
}

/// One call in the Calls tab.
pub struct CallLogRow {
    pub room_id: String,
    pub call_id: String,
    pub from: String,
    pub mine: bool,
    pub video: bool,
    pub state: String,
    pub started_at: u64,
    pub answered_at: Option<u64>,
    pub ended_at: Option<u64>,
}

/// One device logged in to my account.
pub struct DeviceInfo {
    pub device_id: String,
    pub name: String,
    pub last_seen: u64,
    pub this_device: bool,
    pub verified: bool,
}

/// One of another person's devices (암호화 > 기기 키 보기).
pub struct PeerKey {
    pub device_id: String,
    pub name: String,
    pub key: String,
    pub verified: bool,
}

/// A message from before I joined, sent by a member (지난 메시지 보내기).
pub struct EarlierRow {
    pub sender: String,
    pub ts: u64,
    /// "text", "image", "video", "audio" or "file".
    pub kind: String,
    /// Text, or the words under a photo / video / file.
    pub body: String,
    /// File name (files only).
    pub name: String,
    pub mime: String,
    /// There is a small picture to show first ([earlier_file] thumb).
    pub has_thumb: bool,
}

pub struct InviteRow {
    pub room_id: String,
    pub name: String,
    pub inviter: String,
    pub direct: bool,
}

/// A group's or channel's invite link.
pub struct RoomLinkRow {
    /// "public", "private" or "none".
    pub kind: String,
    /// Address (public) or code (private).
    pub code: String,
    pub approval: bool,
    pub web: bool,
}

/// One 전체 검색 hit: which chat, and the message.
pub struct FoundRow {
    pub room_id: String,
    pub message: ChatMessage,
}

/// A public group or channel from the server's public list.
pub struct PublicRoomRow {
    pub room_id: String,
    pub address: String,
    pub name: String,
    pub about: String,
    pub members: u64,
    pub channel: bool,
    pub approval: bool,
    pub joined: bool,
}

/// One extra invite link (tip 253).
pub struct InviteLinkRow {
    pub code: String,
    pub name: String,
    /// Ends at, ms since 1970 (0 = no end).
    pub until: u64,
    /// People limit (0 = none).
    pub max: u64,
    pub uses: u64,
    pub joined: Vec<String>,
    pub by: String,
    pub made: u64,
    pub revoked: bool,
}

fn invite_row(l: burumy_engine::links::InviteLink) -> InviteLinkRow {
    InviteLinkRow {
        code: l.code,
        name: l.name,
        until: l.until,
        max: l.max,
        uses: l.uses,
        joined: l.joined,
        by: l.by,
        made: l.made,
        revoked: l.revoked,
    }
}

/// What a public link shows before coming in.
pub struct LinkPeekRow {
    pub room_id: String,
    pub name: String,
    pub about: String,
    pub members: u64,
    pub channel: bool,
    pub approval: bool,
    pub joined: bool,
    /// The room's public photo (empty = none).
    pub photo: Vec<u8>,
}

/// A link sticker's card for a story (tip 467), read by MY phone only.
pub struct StoryLinkRow {
    pub title: String,
    pub site: String,
    pub description: String,
    /// The page picture as downloaded (empty = none); the app shrinks it.
    pub image: Vec<u8>,
}

/// One chat inside a community.
pub struct CommunityChatRow {
    pub room_id: String,
    pub name: String,
    /// "group" or "channel".
    pub kind: String,
    /// "in", "view" or "ask".
    pub state: String,
    pub hidden: bool,
    pub by: String,
    pub members: u64,
}

/// A community (several groups and channels together).
pub struct CommunityRow {
    pub id: String,
    pub name: String,
    pub about: String,
    pub role: String,
    pub add_all: bool,
    pub members: u64,
    pub chats: Vec<CommunityChatRow>,
}

/// Someone asking to come in.
pub struct JoinRequestRow {
    pub user_id: String,
    pub name: String,
    /// Answers to the room's join questions sent with the request.
    pub answers: Vec<String>,
}

/// 가입 심사 도우미 in a room: in or not, and its encryption devices
/// (must be 0, so it can't get room keys).
pub struct GateHelperRow {
    pub joined: bool,
    pub devices: u32,
}

/// A phone notification made on this phone.
pub struct NoticeRow {
    pub room_id: String,
    pub chat: String,
    pub sender: String,
    pub kind: String,
    pub body: Option<String>,
    pub ts: u64,
}

/// A call line in the chat.
pub struct CallRow {
    pub call_id: String,
    pub video: bool,
    /// "ringing", "ongoing", "ended", "missed", "declined", "busy"
    pub state: String,
    pub started_at: u64,
    pub answered_at: Option<u64>,
    pub ended_at: Option<u64>,
}

pub struct RingingRow {
    pub room_id: String,
    pub call_id: String,
    pub from: String,
    pub video: bool,
    pub started_at: u64,
}

/// What the app sends to the call-pass service, plus the media key.
pub struct CallAskRow {
    pub openid_token: String,
    pub media_key: String,
    pub video: bool,
}

/// A bubble waiting for me: who and when, never what.
pub struct BubbleRow {
    pub room_id: String,
    pub event_id: String,
    pub from: String,
    pub ts: u64,
}

/// A story within its 24 hours (mine once, and each friend's).
pub struct StoryRow {
    pub story_id: String,
    pub room_id: String,
    pub event_id: String,
    pub sender: String,
    pub mine: bool,
    pub ts: u64,
    pub kind: String,
    pub caption: Option<String>,
    pub extra: Option<String>,
    /// A friend-feed post (kept until deleted) rather than a story.
    pub feed: bool,
    /// Kept on the profile (tips 392 / 468 / 534): the app's pin JSON.
    pub pin: Option<String>,
    /// When it leaves the story row (ms); 0 for a feed post.
    pub until: u64,
    /// Changed after posting (tip 393).
    pub edited: bool,
    /// A group's or channel's story (tip 428).
    pub group: bool,
    /// A member's story for one group only (4-app board).
    pub member: bool,
}

/// What post_stories sent: how many chats, and the new story ids.
pub struct StoryPostedRow {
    pub sent: u32,
    pub ids: Vec<String>,
}

/// 이모지 상태 of one person.
pub struct EmojiStatusRow {
    pub emoji: String,
    pub until_ms: u64,
}

/// Someone's photo, about-me and birthday (card from our 1:1 chat, or public).
pub struct ProfileCardRow {
    pub photo: Option<Vec<u8>>,
    pub bio: String,
    pub birthday: String,
    pub private: bool,
}

/// A like on a feed post (only in our 1:1 chat).
pub struct FeedLikeRow {
    pub post_id: String,
    pub sender: String,
    pub mine: bool,
}

pub struct MeetupRow {
    pub title: String,
    pub starts_at: u64,
    /// 0 = no end time.
    pub ends_at: u64,
    pub place: Option<String>,
    pub cancelled: bool,
    pub yes: Vec<String>,
    pub no: Vec<String>,
    pub maybe: Vec<String>,
    /// Extra people each "yes" brings, in the same order as `yes`.
    pub guests: Vec<u32>,
}

pub struct ChecklistRow {
    pub title: String,
    pub items: Vec<ChecklistItemRow>,
    pub others_mark: bool,
    pub others_add: bool,
}

pub struct ChecklistItemRow {
    pub id: String,
    pub text: String,
    /// Who ticked it (None = not done).
    pub done_by: Option<String>,
    pub added_by: Option<String>,
}

pub struct PollRow {
    pub question: String,
    pub answers: Vec<PollAnswerRow>,
    pub anonymous: bool,
    pub multiple: bool,
    pub closed: bool,
    pub voters: u32,
    pub mine: Vec<String>,
    /// Quiz: right answer id and explanation; deadline in ms (0 = none).
    pub correct: Option<String>,
    pub explain: String,
    pub close_at: i64,
    /// Words under the question and whether a photo is attached.
    pub description: String,
    pub has_photo: bool,
    pub add_options: bool,
    pub change_vote: bool,
    pub shuffle: bool,
    pub hide_results: bool,
}

pub struct PollAnswerRow {
    pub id: String,
    pub text: String,
    pub votes: u32,
    /// Open polls: who chose it (user ids).
    pub who: Vec<String>,
    pub has_photo: bool,
    /// Built-in sticker id ("" = none) and place "geo:lat,lon" ("" = none).
    pub sticker: String,
    pub geo: String,
    /// A member added it (user id; "" = the maker's own).
    pub added_by: String,
}

/// A photo for a new poll: slot "q" = under the question, "<n>" = answer n.
pub struct PollPhotoIn {
    pub slot: String,
    pub mime: String,
    pub data: Vec<u8>,
}

/// Voice message length and loudness bars (0..1024).
pub struct VoiceRow {
    pub duration_ms: u64,
    pub waveform: Vec<u16>,
}

/// Link card inside a text message (made by the sender's phone).
pub struct LinkPreviewRow {
    pub url: String,
    pub title: String,
    pub description: Option<String>,
    pub site: Option<String>,
    pub has_image: bool,
    /// Tip 400: card above the words / small side picture.
    pub above: bool,
    pub small: bool,
}

/// One emoji under a message.
pub struct ReactionRow {
    pub key: String,
    pub count: u32,
    /// My own reaction (delete it to take the emoji back).
    pub mine: Option<String>,
}

/// One row of the chat list.
pub struct ChatRow {
    pub room_id: String,
    pub name: String,
    pub is_direct: bool,
    pub encrypted: bool,
    pub unread: u64,
    pub last: Option<ChatMessage>,
    pub streak: u32,
    pub streak_at_risk: bool,
    pub pinned: bool,
    pub archived: bool,
    pub muted: bool,
    pub is_channel: bool,
    pub peer: String,
}

/// A person (contact or search result).
pub struct PersonRow {
    pub user_id: String,
    pub name: String,
    pub room_id: Option<String>,
}

/// A hidden signal from another phone (see engine signal.rs).
pub struct SignalRow {
    pub room_id: String,
    pub event_id: String,
    pub sender: String,
    pub kind: String,
    /// JSON text.
    pub data: String,
    pub ts: u64,
}

/// Someone in a chat.
pub struct MemberRow {
    pub user_id: String,
    pub name: String,
    /// "owner", "admin" or "member".
    pub role: String,
    /// When they joined (or last renamed) here, ms; 0 = unknown.
    pub since: u64,
}

fn person(p: burumy_engine::Person) -> PersonRow {
    PersonRow {
        user_id: p.user_id,
        name: p.name,
        room_id: p.room_id,
    }
}

fn msg(m: burumy_engine::Message) -> ChatMessage {
    ChatMessage {
        event_id: m.event_id,
        sender: m.sender,
        body: m.body,
        was_encrypted: m.was_encrypted,
        ts: m.ts,
        mine: m.mine,
        kind: m.kind,
        reply_to: m.reply_to,
        quote: m.quote,
        quote_name: m.quote_name,
        caption_above: m.caption_above,
        media_from: m.media_from,
        media_changed: m.media_changed,
        post_as: m.post_as,
        thread_root: m.thread_root,
        topic: m.topic,
        edited: m.edited,
        edited_at: m.edited_at,
        first_body: m.first_body,
        reactions: m
            .reactions
            .into_iter()
            .map(|r| ReactionRow {
                key: r.key,
                count: r.count,
                mine: r.mine,
            })
            .collect(),
        expires_at: m.expires_at,
        view_once: m.view_once,
        opened: m.opened,
        forwarded: m.forwarded,
        preview: m.preview.map(|p| LinkPreviewRow {
            url: p.url,
            title: p.title,
            description: p.description,
            site: p.site,
            has_image: p.has_image,
            above: p.above,
            small: p.small,
        }),
        voice: m.voice.map(|v| VoiceRow {
            duration_ms: v.duration_ms,
            waveform: v.waveform,
        }),
        live: m.live.map(|l| LiveRow {
            style: l.style,
            duration_ms: l.duration_ms,
        }),
        poll: m.poll.map(|p| {
            let who = p.who;
            PollRow {
                question: p.question,
                answers: p
                    .answers
                    .into_iter()
                    .map(|a| PollAnswerRow {
                        who: who.get(&a.id).cloned().unwrap_or_default(),
                        id: a.id,
                        text: a.text,
                        votes: a.votes,
                        has_photo: a.media,
                        sticker: a.sticker,
                        geo: a.geo,
                        added_by: a.added_by.unwrap_or_default(),
                    })
                    .collect(),
                description: p.description.clone(),
                has_photo: p.media,
                add_options: p.add_options,
                change_vote: p.change_vote,
                shuffle: p.shuffle,
                hide_results: p.hide_results,
                anonymous: p.anonymous,
                multiple: p.multiple,
                correct: p.correct.clone(),
                explain: p.explain.clone(),
                close_at: p.close_at as i64,
                closed: p.closed,
                voters: p.voters,
                mine: p.mine,
            }
        }),
        bubble: m.bubble,
        caption: m.caption,
        size: m.size,
        meetup: m.meetup.map(|p| {
            let who = |a: &str| {
                let mut v: Vec<String> = p
                    .answers
                    .iter()
                    .filter(|(_, x)| burumy_engine::meetup::base_answer(x) == a)
                    .map(|(u, _)| u.clone())
                    .collect();
                v.sort();
                v
            };
            let yes = who("yes");
            let guests = yes
                .iter()
                .map(|u| burumy_engine::meetup::guests(p.answers.get(u).map(String::as_str).unwrap_or("")))
                .collect();
            MeetupRow {
                guests,
                ends_at: p.ends_at.unwrap_or(0),
                yes,
                no: who("no"),
                maybe: who("maybe"),
                title: p.title,
                starts_at: p.starts_at,
                place: p.place,
                cancelled: p.cancelled,
            }
        }),
        contact: m.contact,
        card: m.card.map(|c| {
            let mut counts: Vec<String> = c.counts.iter().map(|(k, n)| format!("{k}={n}")).collect();
            counts.sort();
            CardRow { kind: c.kind, data: c.data, counts, winners: c.winners, closed: c.closed, mine: c.mine, won: c.won }
        }),
        checklist: m.checklist.map(|c| ChecklistRow {
            title: c.title,
            items: c
                .items
                .into_iter()
                .map(|i| ChecklistItemRow {
                    id: i.id,
                    text: i.text,
                    done_by: i.done_by,
                    added_by: i.added_by,
                })
                .collect(),
            others_mark: c.others_mark,
            others_add: c.others_add,
        }),
        call: m.call.map(|c| CallRow {
            call_id: c.call_id,
            video: c.video,
            state: c.state,
            started_at: c.started_at,
            answered_at: c.answered_at,
            ended_at: c.ended_at,
        }),
    }
}

#[frb(opaque)]
pub struct BurumyDevice {
    engine: Engine,
}

impl BurumyDevice {
    pub async fn open(
        homeserver: String,
        data_dir: String,
        store_passphrase: String,
    ) -> Result<BurumyDevice> {
        let engine = Engine::open(&homeserver, &PathBuf::from(data_dir), &store_passphrase).await?;
        Ok(BurumyDevice { engine })
    }

    pub async fn register(
        &self,
        username: String,
        password: String,
        invite_code: Option<String>,
    ) -> Result<String> {
        self.engine
            .register(&username, &password, invite_code.as_deref())
            .await?;
        Ok(self
            .engine
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default())
    }

    pub async fn login(
        &self,
        username: String,
        password: String,
        device_name: String,
    ) -> Result<String> {
        self.engine
            .login(&username, &password, &device_name)
            .await?;
        Ok(self
            .engine
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default())
    }

    /// QR로 PC 연결: sign in with a one-time token (returns my user id).
    pub async fn login_token(&self, token: String, device_name: String) -> Result<String> {
        self.engine.login_token(&token, &device_name).await?;
        Ok(self
            .engine
            .user_id()
            .map(|u| u.to_string())
            .unwrap_or_default())
    }

    pub async fn sync_once(&self) -> Result<()> {
        self.engine.sync_once().await
    }

    pub async fn enable_recovery(&self) -> Result<String> {
        self.engine.enable_recovery().await
    }

    pub async fn recover(&self, recovery_key: String, room_id: String) -> Result<()> {
        self.engine.recover(&recovery_key).await?;
        self.engine
            .download_keys_for(&RoomId::parse(room_id)?)
            .await
    }

    pub async fn create_dm(&self, user_id: String) -> Result<String> {
        Ok(self
            .engine
            .create_dm(&UserId::parse(user_id)?)
            .await?
            .to_string())
    }

    /// 1:1 chat with an 아이디 키 proof ("" = a plain 1:1 chat).
    pub async fn create_dm_keyed(&self, user_id: String, proof: String) -> Result<String> {
        Ok(self
            .engine
            .create_dm_keyed(&UserId::parse(user_id)?, &proof)
            .await?
            .to_string())
    }

    #[frb(sync)]
    pub fn invited_rooms(&self) -> Vec<String> {
        self.engine
            .invited_rooms()
            .into_iter()
            .map(|r| r.to_string())
            .collect()
    }

    pub async fn join(&self, room_id: String) -> Result<()> {
        self.engine.join(&RoomId::parse(room_id)?).await
    }

    pub async fn send_text(&self, room_id: String, text: String) -> Result<String> {
        self.engine.send_text(&RoomId::parse(room_id)?, &text).await
    }

    /// Sends without a notification sound on the other phones.
    pub async fn send_text_quietly(&self, room_id: String, text: String) -> Result<String> {
        self.engine.send_text_with(&RoomId::parse(room_id)?, &text, true).await
    }

    pub async fn messages(&self, room_id: String, limit: u32) -> Result<Vec<ChatMessage>> {
        Ok(self
            .engine
            .messages(&RoomId::parse(room_id)?, limit)
            .await?
            .into_iter()
            .map(msg)
            .collect())
    }

    /// Oldest first, from this device's own copy.
    /// Passes a message on to another chat.
    pub async fn forward(
        &self,
        from_room: String,
        event_id: String,
        to_room: String,
    ) -> Result<String> {
        self.engine
            .forward(
                &RoomId::parse(from_room)?,
                &event_id,
                &RoomId::parse(to_room)?,
            )
            .await
    }

    /// 전체 검색 on this phone: kind "text", "media", "link", "file",
    /// "music" or "voice"; newest first, at most `limit`.
    pub async fn search_all(&self, term: String, kind: String, limit: u32) -> Result<Vec<FoundRow>> {
        Ok(self
            .engine
            .search_all(&term, &kind, 2000, limit as usize)
            .await?
            .into_iter()
            .map(|(room_id, m)| FoundRow { room_id, message: msg(m) })
            .collect())
    }

    /// Public groups / channels with these words (server's public list).
    pub async fn search_public(&self, term: String, channels_only: bool) -> Result<Vec<PublicRoomRow>> {
        Ok(self
            .engine
            .search_public(&term, channels_only, 30)
            .await?
            .into_iter()
            .map(|p| PublicRoomRow {
                room_id: p.room_id,
                address: p.address,
                name: p.name,
                about: p.about,
                members: p.members,
                channel: p.channel,
                approval: p.approval,
                joined: p.joined,
            })
            .collect())
    }

    /// Messages in one chat containing the words, newest first (on this phone only).
    pub async fn search_messages(&self, room_id: String, term: String) -> Result<Vec<ChatMessage>> {
        Ok(self
            .engine
            .search(&RoomId::parse(room_id)?, &term, 2000)
            .await?
            .into_iter()
            .map(msg)
            .collect())
    }

    pub async fn timeline(&self, room_id: String, limit: u32) -> Result<Vec<ChatMessage>> {
        Ok(self
            .engine
            .timeline(&RoomId::parse(room_id)?, limit as usize)
            .await?
            .into_iter()
            .map(msg)
            .collect())
    }

    pub async fn chat_list(&self) -> Result<Vec<ChatRow>> {
        Ok(self
            .engine
            .chat_list()
            .await?
            .into_iter()
            .map(|c| ChatRow {
                is_channel: c.is_channel,
                peer: c.peer,
                room_id: c.room_id,
                name: c.name,
                is_direct: c.is_direct,
                encrypted: c.encrypted,
                unread: c.unread,
                last: c.last.map(msg),
                streak: c.streak,
                streak_at_risk: c.streak_at_risk,
                pinned: c.pinned,
                archived: c.archived,
                muted: c.muted,
            })
            .collect())
    }

    /// Waits up to `timeout_ms` for anything new.
    pub async fn sync_wait(&self, timeout_ms: u64) -> Result<()> {
        self.engine.sync_wait(timeout_ms).await
    }

    #[frb(sync)]
    pub fn session_json(&self) -> Result<String> {
        self.engine.session_json()
    }

    pub async fn restore(&self, session_json: String) -> Result<()> {
        self.engine.restore(&session_json).await
    }

    #[frb(sync)]
    pub fn is_logged_in(&self) -> bool {
        self.engine.is_logged_in()
    }

    #[frb(sync)]
    pub fn user_id(&self) -> Option<String> {
        self.engine.user_id().map(|u| u.to_string())
    }

    pub async fn send_file(
        &self,
        room_id: String,
        name: String,
        mime: String,
        data: Vec<u8>,
    ) -> Result<String> {
        self.engine
            .send_file(&RoomId::parse(room_id)?, &name, &mime, data)
            .await
    }

    /// A photo, video or file with words under it.
    pub async fn send_file_captioned(
        &self,
        room_id: String,
        name: String,
        mime: String,
        data: Vec<u8>,
        caption: String,
    ) -> Result<String> {
        self.engine
            .send_file_with(&RoomId::parse(room_id)?, &name, &mime, data, &caption)
            .await
    }

    /// With words above the photo or video (설명 위로, tip 452).
    pub async fn send_file_opts(
        &self,
        room_id: String,
        name: String,
        mime: String,
        data: Vec<u8>,
        caption: String,
        caption_above: bool,
    ) -> Result<String> {
        self.engine
            .send_file_opts(&RoomId::parse(room_id)?, &name, &mime, data, &caption, caption_above)
            .await
    }

    /// Edit my photo/video/file message: words, above/under, and with a
    /// new file swap it (not in public chats). Tips 452 B, 482, 81, 224.
    #[allow(clippy::too_many_arguments)]
    pub async fn edit_media(
        &self,
        room_id: String,
        event_id: String,
        caption: String,
        caption_above: bool,
        file_name: Option<String>,
        file_mime: Option<String>,
        file_data: Option<Vec<u8>>,
    ) -> Result<()> {
        let file = match (file_name, file_mime, file_data) {
            (Some(n), Some(m), Some(d)) => Some((n, m, d)),
            _ => None,
        };
        self.engine
            .edit_media(&RoomId::parse(room_id)?, &event_id, &caption, caption_above, file)
            .await
    }

    /// 움직이는 사진: still photo + short clip, both encrypted here.
    #[allow(clippy::too_many_arguments)]
    pub async fn send_live_photo(
        &self,
        room_id: String,
        name: String,
        mime: String,
        data: Vec<u8>,
        video_mime: String,
        video: Vec<u8>,
        duration_ms: u64,
        style: String,
        caption: String,
    ) -> Result<String> {
        self.engine
            .send_live_photo(
                &RoomId::parse(room_id)?,
                &name,
                &mime,
                data,
                &video_mime,
                video,
                duration_ms,
                &style,
                &caption,
            )
            .await
    }

    /// The decrypted clip of a 움직이는 사진 (its bytes; always MP4/MOV).
    pub async fn live_video(&self, room_id: String, event_id: String) -> Result<Vec<u8>> {
        Ok(self
            .engine
            .live_video(&RoomId::parse(room_id)?, &event_id)
            .await?
            .1)
    }

    /// Returns the file bytes (decrypted on this device).
    pub async fn download_file(&self, room_id: String, event_id: String) -> Result<Vec<u8>> {
        Ok(self
            .engine
            .download_file(&RoomId::parse(room_id)?, &event_id)
            .await?
            .1)
    }

    /// Same, keeping a copy in the encrypted store when [cache] is true.
    pub async fn download_file_cached(&self, room_id: String, event_id: String, cache: bool) -> Result<Vec<u8>> {
        Ok(self
            .engine
            .download_file_with(&RoomId::parse(room_id)?, &event_id, cache)
            .await?
            .1)
    }

    /// Stops a running cached download (true = one was running).
    pub fn cancel_download(&self, event_id: String) -> bool {
        self.engine.cancel_download(&event_id)
    }

    /// Drops the kept copy of one file.
    pub async fn forget_file(&self, room_id: String, event_id: String) -> Result<()> {
        self.engine.forget_file(&RoomId::parse(room_id)?, &event_id).await
    }

    /// Biggest kept file and how long kept copies stay (None = no limit).
    pub async fn set_media_keep(&self, max_file: Option<u64>, keep_secs: Option<u64>) -> Result<()> {
        self.engine.set_media_keep(max_file, keep_secs).await
    }

    pub async fn set_push(
        &self,
        gateway_url: String,
        pushkey: String,
        app_id: String,
    ) -> Result<()> {
        self.engine.set_push(&gateway_url, &pushkey, &app_id).await
    }

    pub async fn contacts(&self) -> Result<Vec<PersonRow>> {
        Ok(self
            .engine
            .contacts()
            .await?
            .into_iter()
            .map(person)
            .collect())
    }

    pub async fn search_people(&self, term: String) -> Result<Vec<PersonRow>> {
        Ok(self
            .engine
            .search_people(&term)
            .await?
            .into_iter()
            .map(person)
            .collect())
    }

    pub async fn mark_read(&self, room_id: String) -> Result<()> {
        self.engine.mark_read(&RoomId::parse(room_id)?).await
    }

    /// Others have read everything sent up to this time (ms).
    pub async fn read_until(&self, room_id: String) -> Result<u64> {
        self.engine.read_until(&RoomId::parse(room_id)?).await
    }

    /// Turn down an invitation because only contacts may add me (tip 385).
    pub async fn decline_blocked(&self, room_id: String) -> Result<()> {
        self.engine.decline_blocked(&RoomId::parse(room_id)?).await
    }

    /// People who turned down this room's invitation for that reason.
    pub async fn invites_blocked(&self, room_id: String) -> Result<Vec<String>> {
        Ok(self.engine.invites_blocked(&RoomId::parse(room_id)?).await)
    }

    /// [read up to, when they read it] in ms (1:1 read time, tip 421).
    pub async fn read_receipt(&self, room_id: String) -> Result<Vec<u64>> {
        let (until, at) = self.engine.read_receipt(&RoomId::parse(room_id)?).await?;
        Ok(vec![until, at])
    }

    pub async fn has_recovery(&self) -> bool {
        self.engine.has_recovery().await
    }

    /// New device: opens old chats with the 대화 복구 키.
    pub async fn recover_all(&self, recovery_key: String) -> Result<()> {
        self.engine.recover(&recovery_key).await?;
        for r in self.engine.client().joined_rooms() {
            let _ = self.engine.download_keys_for(r.room_id()).await;
        }
        Ok(())
    }

    /// New group (channel = true: only I can post). Returns the room id.
    pub async fn create_group(
        &self,
        name: String,
        invite: Vec<String>,
        channel: bool,
    ) -> Result<String> {
        let ids = invite
            .into_iter()
            .map(UserId::parse)
            .collect::<Result<Vec<_>, _>>()?;
        Ok(self
            .engine
            .create_group(&name, &ids, channel)
            .await?
            .to_string())
    }

    pub async fn can_post(&self, room_id: String) -> Result<bool> {
        self.engine.can_post(&RoomId::parse(room_id)?).await
    }

    pub async fn is_channel(&self, room_id: String) -> Result<bool> {
        Ok(self.engine.is_channel(&RoomId::parse(room_id)?).await)
    }

    /// Text (or a reply when `to_event` is set) with the sender's link
    /// card set-up (tips 400 + 401): `url` = the picked link ("" = first),
    /// card `above` the words, `small` picture, or `off` = no card.
    #[allow(clippy::too_many_arguments)]
    pub async fn send_text_link(&self, room_id: String, to_event: String, text: String, silent: bool, url: String, above: bool, small: bool, off: bool) -> Result<String> {
        let room = RoomId::parse(room_id)?;
        let link = burumy_engine::LinkChoice { url: (!url.is_empty()).then_some(url), above, small, off };
        if to_event.is_empty() {
            self.engine.send_text_link(&room, &text, silent, &link).await
        } else {
            self.engine.reply_link(&room, &to_event, &text, &link).await
        }
    }

    pub async fn reply(&self, room_id: String, to_event: String, text: String) -> Result<String> {
        self.engine
            .reply(&RoomId::parse(room_id)?, &to_event, &text)
            .await
    }

    /// 보내는 이름 (tips 472 + 310): my next messages in this chat are sent
    /// as `as_json` ("" = as myself).
    #[frb(sync)]
    pub fn set_send_as(&self, room_id: String, as_json: String) -> Result<()> {
        self.engine.set_send_as(&RoomId::parse(room_id)?, &as_json)
    }

    /// 부분 인용 답장 / 다른 대화에서 답장 (tip 399); `to_event` "" = from
    /// another chat (then `quote_name` is shown as the writer).
    pub async fn reply_quote(&self, room_id: String, to_event: String, text: String, quote: String, quote_name: String) -> Result<String> {
        self.engine
            .reply_quote(&RoomId::parse(room_id)?, &to_event, &text, &quote, &quote_name)
            .await
    }

    /// Messages already on this phone (no server round trip), for the chat
    /// list's unseen mention / reaction marks.
    pub async fn cached_messages(&self, room_id: String) -> Result<Vec<ChatMessage>> {
        Ok(self.engine.cached_messages(&RoomId::parse(room_id)?).await?.into_iter().map(msg).collect())
    }

    pub async fn edit(&self, room_id: String, event_id: String, text: String) -> Result<()> {
        self.engine
            .edit(&RoomId::parse(room_id)?, &event_id, &text)
            .await
    }

    pub async fn delete_message(&self, room_id: String, event_id: String) -> Result<()> {
        self.engine
            .delete_message(&RoomId::parse(room_id)?, &event_id)
            .await
    }

    pub async fn set_typing(&self, room_id: String, typing: bool) -> Result<()> {
        self.engine
            .set_typing(&RoomId::parse(room_id)?, typing)
            .await
    }

    #[frb(sync)]
    pub fn typing_users(&self, room_id: String) -> Result<Vec<String>> {
        Ok(self.engine.typing_users(&RoomId::parse(room_id)?))
    }

    /// Call history, newest first.
    pub async fn call_log(&self, max: u32) -> Result<Vec<CallLogRow>> {
        Ok(self
            .engine
            .call_log(max as usize)
            .await?
            .into_iter()
            .map(|c| CallLogRow {
                room_id: c.room_id,
                call_id: c.call_id,
                from: c.from,
                mine: c.mine,
                video: c.video,
                state: c.state,
                started_at: c.started_at,
                answered_at: c.answered_at,
                ended_at: c.ended_at,
            })
            .collect())
    }

    /// Invitations to show, with name, sender and 1:1-or-not.
    pub async fn invitations(&self) -> Vec<InviteRow> {
        self.engine
            .invitations()
            .await
            .into_iter()
            .map(|i| InviteRow { room_id: i.room_id, name: i.name, inviter: i.inviter, direct: i.direct })
            .collect()
    }

    /// 새 멤버에게 지난 메시지 보내기: the last [count] (≤50) messages, end-to-end
    /// encrypted to that person's phones only. Returns how many went.
    pub async fn send_history(&self, room_id: String, user_id: String, count: u32) -> Result<u32> {
        Ok(self
            .engine
            .send_history(&RoomId::parse(room_id)?, &UserId::parse(user_id)?, count as usize)
            .await? as u32)
    }

    /// Messages from before I came, if a member sent them (oldest first).
    pub async fn earlier_messages(&self, room_id: String) -> Result<Vec<EarlierRow>> {
        Ok(self
            .engine
            .earlier_messages(&RoomId::parse(room_id)?)
            .await
            .into_iter()
            .map(|m| EarlierRow {
                has_thumb: !m.thumb.is_empty(),
                sender: m.sender,
                ts: m.ts,
                kind: m.kind,
                body: m.body,
                name: m.name,
                mime: m.mime,
            })
            .collect())
    }

    /// 다른 앱 대화 가져오기: the checked messages of an import card (JSON,
    /// oldest first), downloaded and decrypted once, then kept on this phone.
    pub async fn imported_messages(&self, room_id: String, card_id: String) -> Result<String> {
        self.engine.imported_messages(&RoomId::parse(room_id)?, &card_id).await
    }

    /// The photo / video / file of earlier message [index] (or its small
    /// picture), decrypted on this phone.
    pub async fn earlier_file(&self, room_id: String, index: u32, thumb: bool) -> Result<Vec<u8>> {
        self.engine.earlier_file(&RoomId::parse(room_id)?, index as usize, thumb).await
    }

    pub async fn decline(&self, room_id: String) -> Result<()> {
        self.engine.decline(&RoomId::parse(room_id)?).await
    }

    /// Visible invitations (quiet people's ones stay hidden).
    pub async fn visible_invites(&self) -> Vec<String> {
        self.engine
            .visible_invites()
            .await
            .into_iter()
            .map(|r| r.to_string())
            .collect()
    }

    /// Right after the lock opens: "normal", "hide" or "delete".
    pub async fn start_session(&self, role: String) -> Result<()> {
        self.engine
            .start_session(super::lock::role_from(&role))
            .await
    }

    #[frb(sync)]
    pub fn session_role(&self) -> String {
        super::lock::role_name(self.engine.session_role())
    }

    /// [hide list, delete list] (user ids and chat ids).
    pub async fn quiet_lists(&self) -> Result<Vec<Vec<String>>> {
        let q = self.engine.quiet_state().await?;
        Ok(vec![q.hide, q.delete])
    }

    pub async fn set_quiet_lists(&self, hide: Vec<String>, delete: Vec<String>) -> Result<()> {
        self.engine.set_quiet_lists(hide, delete).await
    }

    /// Emoji check with another person: ask (returns the check's id).
    pub async fn request_user_verification(&self, user_id: String) -> Result<String> {
        self.engine.request_user_verification(&UserId::parse(user_id)?).await
    }

    pub async fn accept_verification(&self, user_id: String, flow_id: String) -> Result<()> {
        self.engine.accept_verification(&UserId::parse(user_id)?, &flow_id).await
    }

    /// "incoming", "waiting", "starting", "emoji", "confirmed", "done", "cancelled" or "gone".
    pub async fn verify_state(&self, user_id: String, flow_id: String) -> Result<String> {
        self.engine.verify_state(&UserId::parse(user_id)?, &flow_id).await
    }

    pub async fn sas_emoji(&self, user_id: String, flow_id: String) -> Result<Option<Vec<String>>> {
        self.engine.sas_emoji(&UserId::parse(user_id)?, &flow_id).await
    }

    pub async fn confirm_sas(&self, user_id: String, flow_id: String) -> Result<bool> {
        self.engine.confirm_sas(&UserId::parse(user_id)?, &flow_id).await
    }

    pub async fn cancel_verification(&self, user_id: String, flow_id: String) -> Result<()> {
        self.engine.cancel_verification(&UserId::parse(user_id)?, &flow_id).await
    }

    pub async fn is_user_verified(&self, user_id: String) -> Result<bool> {
        self.engine.is_user_verified(&UserId::parse(user_id)?).await
    }

    pub async fn peer_keys(&self, user_id: String) -> Result<Vec<PeerKey>> {
        Ok(self
            .engine
            .peer_devices(&UserId::parse(user_id)?)
            .await?
            .into_iter()
            .map(|d| PeerKey { device_id: d.device_id, name: d.name, key: d.key, verified: d.verified })
            .collect())
    }

    /// Marks one message for the delete password (or takes the mark off).
    pub async fn mark_for_delete(&self, room_id: String, event_id: String, on: bool) -> Result<()> {
        self.engine.mark_for_delete(&RoomId::parse(room_id)?, &event_id, on).await
    }

    /// Marks one message for the hide password (or takes the mark off).
    pub async fn mark_for_hide(&self, room_id: String, event_id: String, on: bool) -> Result<()> {
        self.engine.mark_for_hide(&RoomId::parse(room_id)?, &event_id, on).await
    }

    /// Event ids in this chat marked for the hide password.
    pub async fn hide_marked_messages(&self, room_id: String) -> Result<Vec<String>> {
        self.engine.hide_marked_messages(&RoomId::parse(room_id)?).await
    }

    /// "스레드로 답장": a text inside the thread that starts at `root`.
    pub async fn reply_in_thread(&self, room_id: String, root: String, text: String) -> Result<String> {
        self.engine.reply_in_thread(&RoomId::parse(room_id)?, &root, &text).await
    }

    /// "메시지 신고": reason plus the reported words go to our operators.
    pub async fn report_message(&self, room_id: String, event_id: String, reason: String, shown: String) -> Result<()> {
        self.engine.report_message(&RoomId::parse(room_id)?, &event_id, &reason, &shown).await
    }

    /// Event ids in this chat marked for the delete password.
    pub async fn marked_messages(&self, room_id: String) -> Result<Vec<String>> {
        self.engine.marked_messages(&RoomId::parse(room_id)?).await
    }

    /// Hiding is on (shown only inside a hide session).
    pub async fn hide_active(&self) -> Result<bool> {
        Ok(self.engine.quiet_state().await?.hide_active)
    }

    pub async fn release_hidden(&self) -> Result<()> {
        self.engine.release_hidden().await
    }

    pub async fn run_due_leaves(&self) -> Result<Option<String>> {
        self.engine.run_due_leaves().await
    }

    /// The phone's time zone in minutes from UTC (for streak days).
    #[frb(sync)]
    pub fn set_tz_offset(&self, minutes: i32) {
        self.engine.set_tz_offset(minutes)
    }

    pub async fn streaks_enabled(&self) -> bool {
        self.engine.prefs().await.streaks
    }

    pub async fn set_streaks_enabled(&self, on: bool) -> Result<()> {
        let mut p = self.engine.prefs().await;
        p.streaks = on;
        self.engine.set_prefs(&p).await
    }

    /// New messages to notify about (each once; muted/hidden chats never).
    pub async fn notifications(&self, max: u32) -> Result<Vec<NoticeRow>> {
        Ok(self.engine.notifications(max as usize).await?.into_iter().map(|n| NoticeRow { room_id: n.room_id, chat: n.chat, sender: n.sender, kind: n.kind, body: n.body, ts: n.ts }).collect())
    }

    pub async fn notice_text_hidden(&self) -> bool {
        self.engine.prefs().await.hide_notice_text
    }

    pub async fn set_notice_text_hidden(&self, on: bool) -> Result<()> {
        let mut p = self.engine.prefs().await;
        p.hide_notice_text = on;
        self.engine.set_prefs(&p).await
    }

    /// People I blocked.
    pub async fn blocked(&self) -> Vec<String> {
        self.engine.blocked().await
    }

    pub async fn block(&self, user_id: String, on: bool) -> Result<()> {
        self.engine.block(&UserId::parse(user_id)?, on).await
    }

    pub async fn devices(&self) -> Result<Vec<DeviceInfo>> {
        Ok(self
            .engine
            .devices()
            .await?
            .into_iter()
            .map(|d| DeviceInfo { device_id: d.device_id, name: d.name, last_seen: d.last_seen, this_device: d.this_device, verified: d.verified })
            .collect())
    }

    pub async fn log_out_devices(&self, ids: Vec<String>, password: String) -> Result<()> {
        self.engine.log_out_devices(&ids, &password).await
    }

    pub async fn change_password(&self, old: String, new: String) -> Result<()> {
        self.engine.change_password(&old, &new).await
    }

    /// [identity key, device key].
    pub async fn my_keys(&self) -> Vec<String> {
        let (a, b) = self.engine.my_keys().await;
        vec![a, b]
    }

    pub async fn this_device_verified(&self) -> bool {
        self.engine.this_device_verified().await
    }

    /// "아이디 검색 막기" on my account (our server hides me from search).
    pub async fn set_id_search_hidden(&self, on: bool) -> Result<()> {
        self.engine.set_id_search_hidden(on).await
    }

    /// My privacy settings kept in my account, as JSON (see the engine).
    pub async fn privacy_json(&self) -> String {
        self.engine.privacy().await.to_string()
    }

    /// Changes one account privacy setting; `value_json` "null" removes it.
    pub async fn set_privacy_value(&self, key: String, value_json: String) -> Result<()> {
        self.engine.set_privacy_json(&key, &value_json).await
    }

    /// My "saved messages" chat id (made when `create` and missing).
    pub async fn saved_room(&self, create: bool) -> Result<Option<String>> {
        Ok(self.engine.saved_room(create).await?.map(|r| r.to_string()))
    }

    /// Every on-device setting stored by name.
    pub async fn settings(&self) -> std::collections::HashMap<String, String> {
        self.engine.prefs().await.settings.into_iter().collect()
    }

    /// Stores one on-device setting (empty value removes it).
    pub async fn set_setting(&self, key: String, value: String) -> Result<()> {
        let mut p = self.engine.prefs().await;
        if value.is_empty() {
            p.settings.remove(&key);
        } else {
            p.settings.insert(key, value);
        }
        self.engine.set_prefs(&p).await
    }

    /// "wait", "missed" or "busy".
    pub async fn call_waiting(&self) -> String {
        self.engine.prefs().await.call_waiting
    }

    pub async fn set_call_waiting(&self, mode: String) -> Result<()> {
        let mut p = self.engine.prefs().await;
        p.call_waiting = if ["wait", "missed", "busy"].contains(&mode.as_str()) { mode } else { "wait".into() };
        self.engine.set_prefs(&p).await
    }

    pub async fn link_previews_enabled(&self) -> bool {
        !self.engine.prefs().await.no_link_previews
    }

    pub async fn set_link_previews_enabled(&self, on: bool) -> Result<()> {
        let mut p = self.engine.prefs().await;
        p.no_link_previews = !on;
        self.engine.set_prefs(&p).await
    }

    /// kind: "emoji" (data = the emoji as text), "photo" or "voice".
    pub async fn send_bubble(
        &self,
        room_id: String,
        kind: String,
        mime: String,
        data: Vec<u8>,
    ) -> Result<String> {
        self.engine
            .send_bubble(&RoomId::parse(room_id)?, &kind, &mime, data)
            .await
    }

    pub async fn pending_bubbles(&self) -> Result<Vec<BubbleRow>> {
        Ok(self
            .engine
            .pending_bubbles()
            .await?
            .into_iter()
            .map(|b| BubbleRow {
                room_id: b.room_id,
                event_id: b.event_id,
                from: b.from,
                ts: b.ts,
            })
            .collect())
    }

    /// A photo or video to my 1:1 friends (all, or the chats in `only`) for
    /// 6 / 12 / 24 / 48 hours; returns how many got it.
    pub async fn post_story(
        &self,
        mime: String,
        data: Vec<u8>,
        caption: String,
        only: Vec<String>,
        hours: u32,
        extra: String,
    ) -> Result<u32> {
        Ok(self
            .engine
            .post_story(&mime, data, &caption, &only, hours, &extra)
            .await? as u32)
    }

    /// One upload, several stories (tip 525: parts of a long video, each
    /// with its own `extras` entry). `room` empty: to my 1:1 friends; else
    /// a group's or channel's story (admins only, tip 428).
    #[allow(clippy::too_many_arguments)]
    pub async fn post_stories(
        &self,
        mime: String,
        data: Vec<u8>,
        caption: String,
        only: Vec<String>,
        hours: u32,
        extras: Vec<String>,
        room: String,
    ) -> Result<StoryPostedRow> {
        let x = self
            .engine
            .post_stories(&mime, data, &caption, &only, hours, &extras, &room)
            .await?;
        Ok(StoryPostedRow {
            sent: x.sent as u32,
            ids: x.ids,
        })
    }

    /// Changes a story I posted (tip 393) or keeps it on my profile (pin
    /// JSON; "" = not kept). Empty `data` keeps the picture.
    #[allow(clippy::too_many_arguments)]
    pub async fn edit_story(
        &self,
        story_id: String,
        mime: String,
        data: Vec<u8>,
        caption: String,
        extra: String,
        only: Vec<String>,
        pin: String,
    ) -> Result<u32> {
        Ok(self
            .engine
            .edit_story(&story_id, &mime, data, &caption, &extra, &only, &pin)
            .await? as u32)
    }

    pub async fn stories(&self) -> Result<Vec<StoryRow>> {
        Ok(self
            .engine
            .stories()
            .await?
            .into_iter()
            .map(|x| StoryRow {
                story_id: x.story_id,
                room_id: x.room_id,
                event_id: x.event_id,
                sender: x.sender,
                mine: x.mine,
                ts: x.ts,
                kind: x.kind,
                caption: x.caption,
                extra: x.extra,
                feed: x.feed,
                pin: x.pin,
                until: x.until,
                edited: x.edited,
                group: x.group,
                member: x.member,
            })
            .collect())
    }

    pub async fn feed_like(&self, room_id: String, post_id: String, on: bool) -> Result<()> {
        self.engine
            .feed_like(&RoomId::parse(room_id)?, &post_id, on)
            .await
    }

    pub async fn feed_likes(&self) -> Result<Vec<FeedLikeRow>> {
        Ok(self
            .engine
            .feed_likes()
            .await?
            .into_iter()
            .map(|x| FeedLikeRow {
                post_id: x.post_id,
                sender: x.sender,
                mine: x.mine,
            })
            .collect())
    }

    /// Deletes my story or feed post everywhere it went.
    pub async fn delete_story(&self, story_id: String) -> Result<u32> {
        Ok(self.engine.delete_story(&story_id).await? as u32)
    }

    pub async fn start_call(&self, room_id: String, video: bool) -> Result<String> {
        self.engine
            .start_call(&RoomId::parse(room_id)?, video)
            .await
    }

    pub async fn answer_call(&self, room_id: String, call_id: String) -> Result<()> {
        self.engine
            .answer_call(&RoomId::parse(room_id)?, &call_id)
            .await
    }

    pub async fn hangup_call(
        &self,
        room_id: String,
        call_id: String,
        reason: String,
    ) -> Result<()> {
        self.engine
            .hangup_call(&RoomId::parse(room_id)?, &call_id, &reason)
            .await
    }

    pub async fn call_state(&self, room_id: String, call_id: String) -> Result<String> {
        self.engine
            .call_state(&RoomId::parse(room_id)?, &call_id)
            .await
    }

    /// Someone's level: -1 (can't write), 0, 50 (admin), 100 (owner).
    pub async fn set_member_level(&self, room_id: String, user_id: String, level: i64) -> Result<()> {
        self.engine
            .set_member_level(&RoomId::parse(room_id)?, &user_id, level)
            .await
    }

    /// 주제 (tip 527): messages I send into this chat from now on carry this
    /// topic inside their encryption; None or "g" = 일반.
    #[frb(sync)]
    pub fn set_send_topic(&self, room_id: String, topic: Option<String>) {
        burumy_engine::topic::set(&room_id, topic.as_deref());
    }

    /// Sends a hidden end-to-end encrypted signal into a chat.
    pub async fn send_signal(&self, room_id: String, kind: String, data: String) -> Result<()> {
        self.engine
            .send_signal(&RoomId::parse(room_id)?, &kind, &data)
            .await
    }

    /// Encrypts bytes on this phone and uploads them; returns the key and
    /// address (JSON) to put inside an encrypted signal.
    pub async fn upload_secret(&self, bytes: Vec<u8>) -> Result<String> {
        self.engine.upload_secret(bytes).await
    }

    /// Downloads and decrypts a file from [upload_secret].
    pub async fn download_secret(&self, file: String) -> Result<Vec<u8>> {
        self.engine.download_secret(&file).await
    }

    /// Hidden signals that arrived since the last call.
    #[frb(sync)]
    pub fn take_signals(&self) -> Vec<SignalRow> {
        self.engine
            .take_signals()
            .into_iter()
            .map(|s| SignalRow {
                room_id: s.room_id,
                event_id: s.event_id,
                sender: s.sender,
                kind: s.kind,
                data: s.data,
                ts: s.ts,
            })
            .collect()
    }

    /// Too many wrong app-lock tries: erase every chat on this phone.
    pub async fn erase_everything(&self) -> Result<()> {
        self.engine.erase_everything().await
    }

    /// Deletes a 1:1 chat on both phones.
    pub async fn delete_for_both(&self, room_id: String) -> Result<()> {
        self.engine.delete_for_both(&RoomId::parse(room_id)?).await
    }

    /// 임시 글 이어쓰기 (tip 241): my draft for a chat to my other devices
    /// (end-to-end encrypted). False when this is my only device.
    pub async fn send_my_draft(&self, room_id: String, text: String, at: u64) -> Result<bool> {
        self.engine.send_my_draft(&room_id, &text, at).await
    }

    /// Drafts my other devices sent since the last call.
    pub async fn take_synced_drafts(&self) -> Result<Vec<SyncedDraftRow>> {
        Ok(self
            .engine
            .take_synced_drafts()
            .await?
            .into_iter()
            .map(|d| SyncedDraftRow { room_id: d.room_id, text: d.text, at: d.at })
            .collect())
    }

    /// 내 알림음 (tip 329): small data kept in the encrypted local store.
    pub async fn save_blob(&self, name: String, data: Vec<u8>) -> Result<()> {
        self.engine.save_blob(&name, &data).await
    }

    pub async fn blob(&self, name: String) -> Result<Option<Vec<u8>>> {
        self.engine.blob(&name).await
    }

    pub async fn drop_blob(&self, name: String) -> Result<()> {
        self.engine.drop_blob(&name).await
    }

    /// Friends (user ids) who deleted a 1:1 chat for both; told once.
    pub async fn take_erase_notices(&self) -> Result<Vec<String>> {
        self.engine.take_erase_notices().await
    }

    pub async fn ringing_calls(&self) -> Result<Vec<RingingRow>> {
        Ok(self
            .engine
            .ringing_calls()
            .await?
            .into_iter()
            .map(|r| RingingRow {
                room_id: r.room_id,
                call_id: r.call_id,
                from: r.from,
                video: r.video,
                started_at: r.started_at,
            })
            .collect())
    }

    /// Short-lived OpenID token for our trust service (badges, reports).
    pub async fn openid_token(&self) -> Result<String> {
        self.engine.openid_token().await
    }

    pub async fn call_ask(&self, room_id: String, call_id: String) -> Result<CallAskRow> {
        let (openid_token, media_key, video) = self
            .engine
            .call_ask(&RoomId::parse(room_id)?, &call_id)
            .await?;
        Ok(CallAskRow {
            openid_token,
            media_key,
            video,
        })
    }

    pub async fn create_poll(
        &self,
        room_id: String,
        question: String,
        answers: Vec<String>,
        anonymous: bool,
        multiple: bool,
        quiz: Option<u32>,
        explain: String,
        close_at: i64,
        extra: String,
        photos: Vec<PollPhotoIn>,
    ) -> Result<String> {
        self.engine
            .create_poll(
                &RoomId::parse(room_id)?,
                &question,
                &answers,
                anonymous,
                multiple,
                quiz,
                &explain,
                close_at.max(0) as u64,
                &extra,
                photos.into_iter().map(|p| (p.slot, p.mime, p.data)).collect(),
            )
            .await
    }

    /// A member adds an answer (when the poll allows it).
    pub async fn add_poll_option(&self, room_id: String, poll_id: String, text: String) -> Result<String> {
        self.engine
            .add_poll_option(&RoomId::parse(room_id)?, &poll_id, &text)
            .await
    }

    /// A poll's photo, decrypted: slot "" = under the question, else answer id.
    pub async fn poll_photo(&self, room_id: String, poll_id: String, slot: String) -> Result<Vec<u8>> {
        self.engine
            .poll_photo(&RoomId::parse(room_id)?, &poll_id, &slot)
            .await
    }

    pub async fn set_room_name(&self, room_id: String, name: String) -> Result<()> {
        self.engine.set_room_name(&RoomId::parse(room_id)?, &name).await
    }

    pub async fn room_about(&self, room_id: String) -> Result<String> {
        Ok(self.engine.room_about(&RoomId::parse(room_id)?).await)
    }

    pub async fn set_room_about(&self, room_id: String, text: String) -> Result<()> {
        self.engine.set_room_about(&RoomId::parse(room_id)?, &text).await
    }

    pub async fn invite_users(&self, room_id: String, users: Vec<String>) -> Result<()> {
        self.engine.invite_users(&RoomId::parse(room_id)?, &users).await
    }

    pub async fn remove_member(&self, room_id: String, user_id: String) -> Result<()> {
        self.engine.remove_member(&RoomId::parse(room_id)?, &user_id).await
    }

    pub async fn set_admin(&self, room_id: String, user_id: String, admin: bool) -> Result<()> {
        self.engine.set_admin(&RoomId::parse(room_id)?, &user_id, admin).await
    }

    // Invite links (public address / private code), approval, web page.
    pub async fn room_link(&self, room_id: String) -> Result<RoomLinkRow> {
        let l = self.engine.room_link(&RoomId::parse(room_id)?).await;
        Ok(RoomLinkRow { kind: l.kind, code: l.code, approval: l.approval, web: l.web })
    }

    pub async fn address_free(&self, room_id: String, address: String) -> Result<bool> {
        self.engine.address_free(&RoomId::parse(room_id)?, &address).await
    }

    pub async fn set_public_link(&self, room_id: String, address: String) -> Result<RoomLinkRow> {
        let l = self.engine.set_public_link(&RoomId::parse(room_id)?, &address).await?;
        Ok(RoomLinkRow { kind: l.kind, code: l.code, approval: l.approval, web: l.web })
    }

    pub async fn new_private_link(&self, room_id: String) -> Result<RoomLinkRow> {
        let l = self.engine.new_private_link(&RoomId::parse(room_id)?).await?;
        Ok(RoomLinkRow { kind: l.kind, code: l.code, approval: l.approval, web: l.web })
    }

    pub async fn remove_link(&self, room_id: String) -> Result<()> {
        self.engine.remove_link(&RoomId::parse(room_id)?).await
    }

    pub async fn set_link_approval(&self, room_id: String, on: bool) -> Result<()> {
        self.engine.set_link_approval(&RoomId::parse(room_id)?, on).await
    }

    pub async fn peek_address(&self, address: String) -> Result<LinkPeekRow> {
        let p = self.engine.peek_address(&address).await?;
        Ok(LinkPeekRow {
            room_id: p.room_id,
            name: p.name,
            about: p.about,
            members: p.members,
            channel: p.channel,
            approval: p.approval,
            joined: p.joined,
            photo: p.photo,
        })
    }

    /// Returns [room id, "asked" or "joined"].
    pub async fn join_link(&self, kind: String, code: String) -> Result<Vec<String>> {
        let (id, asked) = self.engine.join_link(&kind, &code).await?;
        Ok(vec![id, if asked { "asked".into() } else { "joined".into() }])
    }

    // ---- 초대 링크 여러 개 (tip 253) ----

    pub async fn invite_links(&self, room_id: String) -> Result<Vec<InviteLinkRow>> {
        Ok(self.engine.invite_links(&RoomId::parse(room_id)?).await.into_iter().map(invite_row).collect())
    }

    pub async fn make_invite_link(&self, room_id: String, name: String, until: u64, max: u64, now: u64) -> Result<InviteLinkRow> {
        Ok(invite_row(self.engine.make_invite_link(&RoomId::parse(room_id)?, &name, until, max, now).await?))
    }

    pub async fn edit_invite_link(&self, room_id: String, code: String, name: String, until: u64, max: u64) -> Result<InviteLinkRow> {
        Ok(invite_row(self.engine.edit_invite_link(&RoomId::parse(room_id)?, &code, &name, until, max).await?))
    }

    pub async fn revoke_invite_link(&self, room_id: String, code: String) -> Result<()> {
        self.engine.revoke_invite_link(&RoomId::parse(room_id)?, &code).await
    }

    pub async fn restore_invite_link(&self, room_id: String, code: String) -> Result<()> {
        self.engine.restore_invite_link(&RoomId::parse(room_id)?, &code).await
    }

    pub async fn delete_invite_link(&self, room_id: String, code: String) -> Result<()> {
        self.engine.delete_invite_link(&RoomId::parse(room_id)?, &code).await
    }

    /// The main private link's count: [people, ...who came in].
    pub async fn main_link_uses(&self, room_id: String) -> Result<Vec<String>> {
        let (n, who) = self.engine.main_link_uses(&RoomId::parse(room_id)?).await;
        Ok(std::iter::once(n.to_string()).chain(who).collect())
    }

    // ---- 커뮤니티 ----

    pub async fn communities(&self) -> Result<Vec<CommunityRow>> {
        Ok(self
            .engine
            .communities()
            .await
            .into_iter()
            .map(|c| CommunityRow {
                id: c.id,
                name: c.name,
                about: c.about,
                role: c.role,
                add_all: c.add_all,
                members: c.members,
                chats: c
                    .chats
                    .into_iter()
                    .map(|x| CommunityChatRow {
                        room_id: x.room_id,
                        name: x.name,
                        kind: x.kind,
                        state: x.state,
                        hidden: x.hidden,
                        by: x.by,
                        members: x.members,
                    })
                    .collect(),
            })
            .collect())
    }

    pub async fn create_community(&self, name: String, about: String) -> Result<String> {
        Ok(self.engine.create_community(&name, &about).await?.to_string())
    }

    pub async fn set_community_info(&self, id: String, name: String, about: String) -> Result<()> {
        self.engine.set_community_info(&RoomId::parse(id)?, &name, &about).await
    }

    pub async fn add_to_community(&self, id: String, room_id: String, hidden: bool) -> Result<()> {
        self.engine.add_to_community(&RoomId::parse(id)?, &RoomId::parse(room_id)?, hidden).await
    }

    pub async fn remove_from_community(&self, id: String, room_id: String) -> Result<()> {
        self.engine.remove_from_community(&RoomId::parse(id)?, &room_id).await
    }

    pub async fn set_community_chat_hidden(&self, id: String, room_id: String, hidden: bool) -> Result<()> {
        self.engine.set_community_chat_hidden(&RoomId::parse(id)?, &room_id, hidden).await
    }

    pub async fn set_community_add_all(&self, id: String, all: bool) -> Result<()> {
        self.engine.set_community_add_all(&RoomId::parse(id)?, all).await
    }

    pub async fn set_community_admin(&self, id: String, user_id: String, on: bool) -> Result<()> {
        self.engine.set_community_admin(&RoomId::parse(id)?, &user_id, on).await
    }

    /// [room id, "asked" | "joined"].
    pub async fn join_community_chat(&self, id: String, room_id: String) -> Result<Vec<String>> {
        let (rid, asked) = self.engine.join_community_chat(&RoomId::parse(id)?, &room_id).await?;
        Ok(vec![rid, if asked { "asked".into() } else { "joined".into() }])
    }

    pub async fn leave_community(&self, id: String) -> Result<()> {
        self.engine.leave_community(&RoomId::parse(id)?).await
    }

    pub async fn delete_community(&self, id: String) -> Result<()> {
        self.engine.delete_community(&RoomId::parse(id)?).await
    }

    pub async fn join_requests(&self, room_id: String) -> Result<Vec<JoinRequestRow>> {
        Ok(self
            .engine
            .join_requests(&RoomId::parse(room_id)?)
            .await?
            .into_iter()
            .map(|(user_id, name, answers)| JoinRequestRow { user_id, name, answers })
            .collect())
    }

    /// Like join_link, sending answers to the join questions with a request.
    pub async fn join_link_with(&self, kind: String, code: String, answers: Vec<String>) -> Result<Vec<String>> {
        let (id, asked) = self.engine.join_link_with(&kind, &code, &answers).await?;
        Ok(vec![id, if asked { "asked".into() } else { "joined".into() }])
    }

    /// "in", "no", "waiting" or "unknown" after asking to come in.
    pub async fn knock_state(&self, room_id: String) -> Result<String> {
        self.engine.knock_state(&RoomId::parse(room_id)?).await
    }

    pub async fn set_gate_helper(&self, room_id: String, on: bool) -> Result<()> {
        self.engine.set_gate_helper(&RoomId::parse(room_id)?, on).await
    }

    pub async fn gate_helper_state(&self, room_id: String) -> Result<GateHelperRow> {
        let (joined, devices) = self.engine.gate_helper_state(&RoomId::parse(room_id)?).await?;
        Ok(GateHelperRow { joined, devices: devices as u32 })
    }

    /// The helper's decision log as JSON ({"e": [...]}).
    pub async fn gate_log(&self, room_id: String) -> Result<String> {
        Ok(self.engine.gate_log(&RoomId::parse(room_id)?).await)
    }

    pub async fn answer_join_request(&self, room_id: String, user_id: String, accept: bool) -> Result<()> {
        self.engine.answer_join_request(&RoomId::parse(room_id)?, &user_id, accept).await
    }

    pub async fn set_web_page(&self, room_id: String, on: bool) -> Result<()> {
        self.engine.set_web_page(&RoomId::parse(room_id)?, on).await
    }

    /// Event ids of posts now on the web page, newest first.
    pub async fn web_posts(&self, room_id: String) -> Result<Vec<String>> {
        Ok(self.engine.web_posts(&RoomId::parse(room_id)?).await.into_iter().map(|(id, _)| id).collect())
    }

    pub async fn web_post(
        &self,
        room_id: String,
        event_id: String,
        text: String,
        ts: u64,
        photo_mime: Option<String>,
        photo: Option<Vec<u8>>,
    ) -> Result<()> {
        let p = match (photo_mime, photo) {
            (Some(m), Some(b)) => Some((m, b)),
            _ => None,
        };
        self.engine.web_post(&RoomId::parse(room_id)?, &event_id, &text, ts, p).await
    }

    pub async fn web_unpost(&self, room_id: String, event_id: String) -> Result<()> {
        self.engine.web_unpost(&RoomId::parse(room_id)?, &event_id).await
    }

    pub async fn room_switch(&self, room_id: String, key: String) -> Result<bool> {
        Ok(self.engine.room_switch(&RoomId::parse(room_id)?, &key).await)
    }

    pub async fn set_room_switch(&self, room_id: String, key: String, on: bool) -> Result<()> {
        self.engine.set_room_switch(&RoomId::parse(room_id)?, &key, on).await
    }

    pub async fn room_config(&self, room_id: String) -> Result<String> {
        Ok(self.engine.room_config(&RoomId::parse(room_id)?).await)
    }

    pub async fn set_room_config(&self, room_id: String, key: String, value: String) -> Result<()> {
        self.engine.set_room_config(&RoomId::parse(room_id)?, &key, &value).await
    }

    /// My name / name colour in one room (None = keep).
    pub async fn set_my_room_look(&self, room_id: String, name: Option<String>, color: Option<String>) -> Result<()> {
        self.engine.set_my_room_look(&RoomId::parse(room_id)?, name, color).await
    }

    /// 멤버 태그 (556): my own tag in this room ("" removes it).
    pub async fn set_my_room_tag(&self, room_id: String, tag: String) -> Result<()> {
        self.engine.set_my_room_tag(&RoomId::parse(room_id)?, &tag).await
    }

    /// "user\ttag" per person who tagged themselves here.
    pub async fn member_tags(&self, room_id: String) -> Result<Vec<String>> {
        let list = self.engine.member_tags(&RoomId::parse(room_id)?).await;
        Ok(list.into_iter().map(|(u, t)| format!("{u}\t{t}")).collect())
    }

    /// 누가 읽었는지 (384): "user\tread up to ms\twhen ms" per member
    /// (groups of up to 100; empty otherwise).
    pub async fn group_receipts(&self, room_id: String) -> Result<Vec<String>> {
        let list = self.engine.group_receipts(&RoomId::parse(room_id)?).await?;
        Ok(list.into_iter().map(|(u, a, b)| format!("{u}\t{a}\t{b}")).collect())
    }

    /// "user\tcolour" per person who picked a name colour.
    pub async fn name_colors(&self, room_id: String) -> Result<Vec<String>> {
        let list = self.engine.name_colors(&RoomId::parse(room_id)?).await;
        Ok(list.into_iter().map(|(u, c)| format!("{u}\t{c}")).collect())
    }

    /// Group/channel photo (no bytes = take it off). Admins only.
    pub async fn set_room_photo(&self, room_id: String, mime: String, data: Vec<u8>) -> Result<()> {
        self.engine.set_room_photo(&RoomId::parse(room_id)?, &mime, data).await
    }

    /// Group/channel photo bytes, or None.
    pub async fn room_photo(&self, room_id: String) -> Result<Option<Vec<u8>>> {
        self.engine.room_photo(&RoomId::parse(room_id)?).await
    }

    /// An admin's phone sends the photo again for people who joined later.
    pub async fn reshare_room_photo(&self, room_id: String) -> Result<bool> {
        self.engine.reshare_room_photo(&RoomId::parse(room_id)?).await
    }

    pub async fn set_banned(&self, room_id: String, user_id: String, banned: bool) -> Result<()> {
        self.engine.set_banned(&RoomId::parse(room_id)?, &user_id, banned).await
    }

    pub async fn banned(&self, room_id: String) -> Result<Vec<String>> {
        self.engine.banned(&RoomId::parse(room_id)?).await
    }

    pub async fn my_role(&self, room_id: String) -> Result<String> {
        self.engine.my_role(&RoomId::parse(room_id)?).await
    }

    pub async fn create_checklist(
        &self,
        room_id: String,
        title: String,
        items: Vec<String>,
        others_mark: bool,
        others_add: bool,
    ) -> Result<String> {
        self.engine
            .create_checklist(&RoomId::parse(room_id)?, &title, &items, others_mark, others_add)
            .await
    }

    pub async fn mark_checklist(
        &self,
        room_id: String,
        checklist_id: String,
        item: String,
        done: bool,
    ) -> Result<()> {
        self.engine
            .mark_checklist(&RoomId::parse(room_id)?, &checklist_id, &item, done)
            .await
    }

    pub async fn add_checklist_item(
        &self,
        room_id: String,
        checklist_id: String,
        text: String,
    ) -> Result<()> {
        self.engine
            .add_checklist_item(&RoomId::parse(room_id)?, &checklist_id, &text)
            .await
    }

    pub async fn create_meetup(
        &self,
        room_id: String,
        title: String,
        starts_at: u64,
        ends_at: u64,
        place: String,
    ) -> Result<String> {
        self.engine
            .create_meetup(&RoomId::parse(room_id)?, &title, starts_at, ends_at, &place)
            .await
    }

    pub async fn answer_meetup(&self, room_id: String, meetup_id: String, answer: String) -> Result<()> {
        self.engine
            .answer_meetup(&RoomId::parse(room_id)?, &meetup_id, &answer)
            .await
    }

    pub async fn cancel_meetup(&self, room_id: String, meetup_id: String) -> Result<()> {
        self.engine
            .cancel_meetup(&RoomId::parse(room_id)?, &meetup_id)
            .await
    }

    /// 실시간 위치: starts sharing until `until_ms`.
    pub async fn send_live_location(&self, room_id: String, lat: f64, lon: f64, accuracy: Option<f64>, until_ms: u64) -> Result<String> {
        self.engine
            .send_live_location(&RoomId::parse(room_id)?, lat, lon, accuracy, until_ms)
            .await
    }

    /// Moves (or, with until_ms = now, ends) my live location.
    pub async fn update_live_location(&self, room_id: String, event_id: String, lat: f64, lon: f64, accuracy: Option<f64>, until_ms: u64) -> Result<()> {
        self.engine
            .update_live_location(&RoomId::parse(room_id)?, &event_id, lat, lon, accuracy, until_ms)
            .await
    }

    pub async fn send_location(&self, room_id: String, lat: f64, lon: f64, accuracy: Option<f64>) -> Result<String> {
        self.engine
            .send_location(&RoomId::parse(room_id)?, lat, lon, accuracy)
            .await
    }

    pub async fn send_contact(&self, room_id: String, user_id: String, name: String) -> Result<String> {
        self.engine
            .send_contact(&RoomId::parse(room_id)?, &user_id, &name)
            .await
    }

    pub async fn vote(&self, room_id: String, poll_id: String, choices: Vec<String>) -> Result<()> {
        self.engine
            .vote(&RoomId::parse(room_id)?, &poll_id, &choices)
            .await
    }

    /// Posts a card; `data` is JSON.
    pub async fn create_card(&self, room_id: String, kind: String, data: String) -> Result<String> {
        self.engine.create_card(&RoomId::parse(room_id)?, &kind, &data).await
    }

    /// Answers a card (JSON; null takes it back). Goes only to the maker.
    pub async fn answer_card(&self, room_id: String, card_id: String, answer: String) -> Result<()> {
        self.engine.answer_card(&RoomId::parse(room_id)?, &card_id, &answer).await
    }

    /// Maker only: who answered and what.
    pub async fn card_answers(&self, room_id: String, card_id: String) -> Result<Vec<CardAnswerRow>> {
        Ok(self
            .engine
            .card_answers(&RoomId::parse(room_id)?, &card_id)
            .await?
            .into_iter()
            .map(|(user, answer)| CardAnswerRow { user, answer })
            .collect())
    }

    /// Maker only: close a card; a giveaway draws its winners.
    pub async fn close_card(&self, room_id: String, card_id: String) -> Result<Vec<String>> {
        self.engine.close_card(&RoomId::parse(room_id)?, &card_id).await
    }

    pub async fn close_poll(&self, room_id: String, poll_id: String) -> Result<()> {
        self.engine
            .close_poll(&RoomId::parse(room_id)?, &poll_id)
            .await
    }

    /// Sends a recorded voice message (encrypted on this device).
    pub async fn send_voice(
        &self,
        room_id: String,
        mime: String,
        data: Vec<u8>,
        duration_ms: u64,
        waveform: Vec<u16>,
    ) -> Result<String> {
        self.engine
            .send_voice(
                &RoomId::parse(room_id)?,
                &mime,
                data,
                duration_ms,
                &waveform,
            )
            .await
    }

    /// Encrypts and uploads bytes (a long post's photo); returns the file
    /// reference JSON to place in the document.
    pub async fn upload_encrypted(&self, data: Vec<u8>) -> Result<String> {
        self.engine.upload_encrypted(data).await
    }

    /// Downloads and decrypts a file reference from inside a document.
    pub async fn download_encrypted(&self, file: String) -> Result<Vec<u8>> {
        self.engine.download_encrypted(&file).await
    }

    /// Posts a long post / formatted message (document JSON).
    pub async fn send_article(&self, room_id: String, doc: String) -> Result<String> {
        self.engine.send_article(&RoomId::parse(room_id)?, &doc).await
    }

    /// The whole document of a long post (checked again on this phone).
    pub async fn open_article(&self, room_id: String, event_id: String) -> Result<String> {
        self.engine.open_article(&RoomId::parse(room_id)?, &event_id).await
    }

    /// Story link sticker: this phone reads the page's title and picture
    /// (like a chat link card). The friends who see the story never contact
    /// the website; the card travels inside the encrypted story.
    pub async fn story_link_card(&self, url: String) -> Result<StoryLinkRow> {
        #[cfg(not(target_arch = "wasm32"))]
        {
            use burumy_engine::preview;
            anyhow::ensure!(!self.engine.prefs().await.no_link_previews, "link previews are off");
            preview::check_web(&url)?;
            let page = preview::fetch_page(&url).await?;
            let image = match page.image_url.as_deref().filter(|u| preview::check_web(u).is_ok()) {
                Some(u) => preview::fetch_image(u).await.map(|(_, b)| b).unwrap_or_default(),
                None => vec![],
            };
            let site = page.site.clone().unwrap_or_else(|| preview::host(&url));
            Ok(StoryLinkRow {
                title: page.title,
                site,
                description: page.description.unwrap_or_default(),
                image,
            })
        }
        #[cfg(target_arch = "wasm32")]
        {
            let _ = url;
            anyhow::bail!("not in the browser")
        }
    }

    /// Decrypted picture of a message's link card.
    pub async fn preview_image(&self, room_id: String, event_id: String) -> Result<Vec<u8>> {
        self.engine
            .preview_image(&RoomId::parse(room_id)?, &event_id)
            .await
    }

    pub async fn set_chat_pinned(&self, room_id: String, on: bool) -> Result<()> {
        self.engine
            .set_chat_pinned(&RoomId::parse(room_id)?, on)
            .await
    }

    pub async fn set_chat_archived(&self, room_id: String, on: bool) -> Result<()> {
        self.engine
            .set_chat_archived(&RoomId::parse(room_id)?, on)
            .await
    }

    pub async fn set_chat_muted(&self, room_id: String, on: bool) -> Result<()> {
        self.engine
            .set_chat_muted(&RoomId::parse(room_id)?, on)
            .await
    }

    pub async fn send_sticker(&self, room_id: String, sticker_id: String) -> Result<String> {
        self.engine
            .send_sticker(&RoomId::parse(room_id)?, &sticker_id)
            .await
    }

    pub async fn react(&self, room_id: String, event_id: String, key: String) -> Result<String> {
        self.engine
            .react(&RoomId::parse(room_id)?, &event_id, &key)
            .await
    }

    pub async fn pin(&self, room_id: String, event_id: String, pinned: bool) -> Result<()> {
        self.engine
            .pin(&RoomId::parse(room_id)?, &event_id, pinned)
            .await
    }

    #[frb(sync)]
    pub fn pinned(&self, room_id: String) -> Result<Vec<String>> {
        Ok(self.engine.pinned(&RoomId::parse(room_id)?))
    }

    /// Chat timer for everyone in the chat, in seconds (0 = off).
    pub async fn set_timer(&self, room_id: String, seconds: u64) -> Result<()> {
        self.engine
            .set_timer(&RoomId::parse(room_id)?, seconds)
            .await
    }

    pub async fn timer(&self, room_id: String) -> Result<u64> {
        Ok(self.engine.timer(&RoomId::parse(room_id)?).await)
    }

    /// Deletes my own messages whose time is up (call now and then).
    pub async fn run_expiry(&self) -> Result<u32> {
        Ok(self.engine.run_expiry().await? as u32)
    }

    pub async fn send_view_once(
        &self,
        room_id: String,
        name: String,
        mime: String,
        data: Vec<u8>,
    ) -> Result<String> {
        self.engine
            .send_view_once(&RoomId::parse(room_id)?, &name, &mime, data)
            .await
    }

    /// Bytes of a view-once photo, one time only.
    pub async fn open_view_once(&self, room_id: String, event_id: String) -> Result<Vec<u8>> {
        self.engine
            .open_view_once(&RoomId::parse(room_id)?, &event_id)
            .await
    }

    pub async fn my_name(&self) -> Result<String> {
        self.engine.my_name().await
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn share_profile(
        &self,
        mime: String,
        photo: Vec<u8>,
        bio: String,
        birthday: String,
        who_photo: String,
        who_bio: String,
        who_birthday: String,
        only: Vec<String>,
    ) -> Result<u32> {
        Ok(self
            .engine
            .share_profile(&mime, photo, &bio, &birthday, &who_photo, &who_bio, &who_birthday, &only)
            .await? as u32)
    }

    pub async fn profile_of(&self, user_id: String) -> Result<ProfileCardRow> {
        let c = self.engine.profile_of(&user_id).await?;
        Ok(ProfileCardRow {
            photo: c.photo,
            bio: c.bio,
            birthday: c.birthday,
            private: c.private,
        })
    }

    /// 이모지 상태 (tip 359): my emoji to each friend's 1:1 chat,
    /// end-to-end encrypted. `until_ms` 0 = until I change it.
    pub async fn set_emoji_status(&self, emoji: String, until_ms: u64) -> Result<u32> {
        Ok(self.engine.set_emoji_status(&emoji, until_ms).await? as u32)
    }

    /// Someone's emoji status: (emoji or "", until ms or 0).
    pub async fn emoji_status_of(&self, user_id: String) -> Result<EmojiStatusRow> {
        let (emoji, until_ms) = self.engine.emoji_status_of(&user_id).await?;
        Ok(EmojiStatusRow { emoji, until_ms })
    }

    pub async fn set_my_bio(&self, text: String) -> Result<()> {
        self.engine.set_my_bio(&text).await
    }

    pub async fn bio_of(&self, user_id: String) -> Result<String> {
        self.engine.bio_of(&user_id).await
    }

    pub async fn set_my_name(&self, name: String) -> Result<()> {
        self.engine.set_my_name(&name).await
    }

    pub async fn my_photo(&self) -> Result<Option<Vec<u8>>> {
        self.engine.my_photo().await
    }

    pub async fn set_my_photo(&self, mime: String, data: Vec<u8>) -> Result<()> {
        self.engine.set_my_photo(&mime, data).await
    }

    pub async fn members(&self, room_id: String) -> Result<Vec<MemberRow>> {
        Ok(self
            .engine
            .members(&RoomId::parse(room_id)?)
            .await?
            .into_iter()
            .map(|m| MemberRow {
                user_id: m.user_id,
                name: m.name,
                role: m.role,
                since: m.since,
            })
            .collect())
    }

    pub async fn leave(&self, room_id: String) -> Result<()> {
        self.engine.leave(&RoomId::parse(room_id)?).await
    }

    pub async fn logout(&self) -> Result<()> {
        self.engine.logout().await
    }
}

#[frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
    if std::env::var("BURUMY_DEBUG_LOG").is_ok() {
        let _ = tracing_subscriber::fmt()
            .with_env_filter(tracing_subscriber::EnvFilter::new("matrix_sdk=debug,info"))
            .with_writer(std::io::stderr)
            .try_init();
    }
}
