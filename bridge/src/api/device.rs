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
    pub edited: bool,
    pub reactions: Vec<ReactionRow>,
    /// Disappears at this time (ms), if the chat has a timer.
    pub expires_at: Option<u64>,
    /// Photo/video that opens only once, and whether it was opened.
    pub view_once: bool,
    pub opened: bool,
    pub forwarded: bool,
    pub preview: Option<LinkPreviewRow>,
    pub voice: Option<VoiceRow>,
    pub poll: Option<PollRow>,
    pub bubble: bool,
    pub call: Option<CallRow>,
    /// Words under a photo, video or file.
    pub caption: Option<String>,
    pub checklist: Option<ChecklistRow>,
    pub meetup: Option<MeetupRow>,
    /// Shared contact's user id (kind "contact").
    pub contact: Option<String>,
    /// FAQ, guide, links, formatted post, giveaway, form, check-in.
    pub card: Option<CardRow>,
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

pub struct InviteRow {
    pub room_id: String,
    pub name: String,
    pub inviter: String,
    pub direct: bool,
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
    pub place: Option<String>,
    pub cancelled: bool,
    pub yes: Vec<String>,
    pub no: Vec<String>,
    pub maybe: Vec<String>,
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
}

pub struct PollAnswerRow {
    pub id: String,
    pub text: String,
    pub votes: u32,
    /// Open polls: who chose it (user ids).
    pub who: Vec<String>,
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

/// Someone in a chat.
pub struct MemberRow {
    pub user_id: String,
    pub name: String,
    /// "owner", "admin" or "member".
    pub role: String,
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
        thread_root: m.thread_root,
        edited: m.edited,
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
        }),
        voice: m.voice.map(|v| VoiceRow {
            duration_ms: v.duration_ms,
            waveform: v.waveform,
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
                    })
                    .collect(),
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
        meetup: m.meetup.map(|p| {
            let who = |a: &str| {
                let mut v: Vec<String> = p
                    .answers
                    .iter()
                    .filter(|(_, x)| x.as_str() == a)
                    .map(|(u, _)| u.clone())
                    .collect();
                v.sort();
                v
            };
            MeetupRow {
                yes: who("yes"),
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

    /// Returns the file bytes (decrypted on this device).
    pub async fn download_file(&self, room_id: String, event_id: String) -> Result<Vec<u8>> {
        Ok(self
            .engine
            .download_file(&RoomId::parse(room_id)?, &event_id)
            .await?
            .1)
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

    pub async fn reply(&self, room_id: String, to_event: String, text: String) -> Result<String> {
        self.engine
            .reply(&RoomId::parse(room_id)?, &to_event, &text)
            .await
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

    /// Too many wrong app-lock tries: erase every chat on this phone.
    pub async fn erase_everything(&self) -> Result<()> {
        self.engine.erase_everything().await
    }

    /// Deletes a 1:1 chat on both phones.
    pub async fn delete_for_both(&self, room_id: String) -> Result<()> {
        self.engine.delete_for_both(&RoomId::parse(room_id)?).await
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
            )
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
        place: String,
    ) -> Result<String> {
        self.engine
            .create_meetup(&RoomId::parse(room_id)?, &title, starts_at, &place)
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
