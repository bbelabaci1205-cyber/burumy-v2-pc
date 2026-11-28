// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Edit guard (협박 공격 막기 1·2): in a group, an edit can only change
//! words into words, only the writer may edit (the server refuses others,
//! even though the message itself is encrypted), and the first wording is
//! kept for "수정 기록". Also checks the member "since" time is known.
//! Usage: edit_guard <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-editguard-{run}"));
    let mut people = vec![];
    for n in ["a", "b", "c"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("eg{n}{run}"), "Secret-pass-123", token.as_deref())
            .await?;
        people.push(e);
    }
    let (a, b, c) = (&people[0], &people[1], &people[2]);
    let group = a
        .create_group(
            "편집 시험",
            &[
                b.user_id().unwrap().to_owned(),
                c.user_id().unwrap().to_owned(),
            ],
            false,
        )
        .await?;
    for e in [b, c] {
        for _ in 0..40 {
            e.sync_once().await?;
            if e.invited_rooms().contains(&group) {
                break;
            }
        }
        e.join(&group).await?;
    }
    a.sync_once().await?;
    let text_id = a.send_text(&group, "원래 글").await?;
    let photo_id = a
        .send_file(
            &group,
            "cat.png",
            "image/png",
            vec![137, 80, 78, 71, 1, 2, 3],
        )
        .await?;
    for e in [b, c] {
        e.sync_once().await?;
    }

    // 1. A normal edit by the writer: shown, first wording kept.
    a.edit(&group, &text_id, "고친 글").await?;

    // 2. Someone else's edit (a modified app): the server refuses it, though
    //    the content is encrypted (the edit link is visible to the server).
    let room_b = b.client().get_room(&group).unwrap();
    let foreign = room_b
        .send_raw(
            "m.room.message",
            json!({
                "msgtype": "m.text", "body": "* 남의 글",
                "m.new_content": {"msgtype": "m.text", "body": "남의 글"},
                "m.relates_to": {"rel_type": "m.replace", "event_id": text_id},
            }),
        )
        .await;
    println!(
        "someone else's edit: {}",
        if foreign.is_err() {
            "refused by server"
        } else {
            "ACCEPTED"
        }
    );
    if foreign.is_ok() {
        bail!("server took an edit of someone else's message")
    }
    // And our own app refuses before sending.
    if b.edit(&group, &text_id, "남의 글").await.is_ok() {
        bail!("app let b edit a's message")
    }

    // 3. In a public group, the writer's modified app tries to swap a
    //    picture in by editing the text, and to swap the photo for words:
    //    both ignored. (In 1:1 chats and private groups a text may get a
    //    photo, tip 482: see edit_media.)
    a.set_public_link(&group, &format!("egtest{run}")).await?;
    for e in [a, c] {
        e.sync_once().await?;
    }
    let room_a = a.client().get_room(&group).unwrap();
    room_a
        .send_raw(
            "m.room.message",
            json!({
                "msgtype": "m.image", "body": "bad.png", "url": "mxc://x/y",
                "m.new_content": {"msgtype": "m.image", "body": "bad.png", "url": "mxc://x/y"},
                "m.relates_to": {"rel_type": "m.replace", "event_id": text_id},
            }),
        )
        .await?;
    room_a
        .send_raw(
            "m.room.message",
            json!({
                "msgtype": "m.text", "body": "* 사진 대신 글",
                "m.new_content": {"msgtype": "m.text", "body": "사진 대신 글"},
                "m.relates_to": {"rel_type": "m.replace", "event_id": photo_id},
            }),
        )
        .await?;
    for _ in 0..3 {
        c.sync_once().await?;
    }
    let msgs = c.messages(&group, 50).await?;
    let t = msgs.iter().find(|m| m.event_id == text_id).expect("text");
    let p = msgs.iter().find(|m| m.event_id == photo_id).expect("photo");
    println!(
        "c sees text: kind={} body={:?} edited={} first={:?} at={:?}",
        t.kind, t.body, t.edited, t.first_body, t.edited_at
    );
    println!(
        "c sees photo: kind={} body={:?} edited={}",
        p.kind, p.body, p.edited
    );
    if t.kind != "text"
        || t.body.as_deref() != Some("고친 글")
        || t.first_body.as_deref() != Some("원래 글")
        || t.edited_at.is_none()
    {
        bail!("text edit not shown right")
    }
    if p.kind != "image" || p.edited || p.body.as_deref() != Some("cat.png") {
        bail!("photo was changed by an edit")
    }
    if msgs.iter().any(|m| m.replaces.is_some()) {
        bail!("edit events leaked into the chat")
    }

    // 4. Members carry the time they joined (for the new-member limit).
    let members = c.members(&group).await?;
    println!(
        "members since: {:?}",
        members
            .iter()
            .map(|m| (m.role.as_str(), m.since > 0))
            .collect::<Vec<_>>()
    );
    if members.iter().any(|m| m.since == 0) {
        bail!("member join time missing")
    }
    println!("EDIT GUARD PASS");
    Ok(())
}
