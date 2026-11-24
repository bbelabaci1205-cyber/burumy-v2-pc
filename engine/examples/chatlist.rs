// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Chat list + local timeline check. Usage: chatlist <homeserver> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-list-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("la{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("lb{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let room = a.create_dm(&b.user_id().unwrap()).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&room) {
            break;
        }
    }
    b.join(&room).await?;
    a.sync_once().await?;
    for t in ["하나", "둘", "셋"] {
        a.send_text(&room, t).await?;
    }
    for _ in 0..10 {
        b.sync_once().await?;
    }
    let list = b.chat_list().await?;
    let row = list
        .iter()
        .find(|c| c.room_id == room.as_str())
        .ok_or_else(|| anyhow::anyhow!("room missing"))?;
    println!(
        "list: name={:?} direct={} encrypted={} unread={} last={:?}",
        row.name,
        row.is_direct,
        row.encrypted,
        row.unread,
        row.last.as_ref().and_then(|m| m.body.clone())
    );
    let tl = b.timeline(&room, 20).await?;
    let texts: Vec<_> = tl.iter().filter_map(|m| m.body.clone()).collect();
    println!("timeline (oldest first): {texts:?}");
    if row.last.as_ref().and_then(|m| m.body.as_deref()) != Some("셋") {
        bail!("last message wrong")
    }
    if texts
        .iter()
        .rev()
        .take(3)
        .rev()
        .cloned()
        .collect::<Vec<_>>()
        != ["하나", "둘", "셋"]
    {
        bail!("timeline order wrong")
    }
    if !row.encrypted || tl.iter().any(|m| m.mine) {
        bail!("flags wrong")
    }
    b.mark_read(&room).await?;
    for _ in 0..10 {
        a.sync_once().await?;
        if a.read_until(&room).await? > 0 {
            break;
        }
    }
    let read = a.read_until(&room).await?;
    let last_ts = tl.last().map(|m| m.ts).unwrap_or(u64::MAX);
    println!("read receipt: bob read until {read}, last sent {last_ts}");
    if read < last_ts {
        bail!("read receipt missing")
    }
    let contacts = a.contacts().await?;
    println!(
        "alice's contacts: {:?}",
        contacts
            .iter()
            .map(|p| (&p.name, &p.room_id))
            .collect::<Vec<_>>()
    );
    if !contacts
        .iter()
        .any(|p| Some(p.user_id.as_str()) == b.user_id().as_ref().map(|u| u.as_str()))
    {
        bail!("contact missing")
    }
    let found = a.search_people(&format!("lb{run}")).await?;
    println!(
        "search: {:?}",
        found.iter().map(|p| &p.user_id).collect::<Vec<_>>()
    );
    if found.is_empty() {
        bail!("search found nobody")
    }
    // Pin, archive, mute.
    let other = b.create_dm(&a.user_id().unwrap()).await.ok();
    let _ = other;
    b.set_chat_pinned(&room, true).await?;
    b.set_chat_archived(&room, true).await?;
    b.set_chat_muted(&room, true).await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let r = b
        .chat_list()
        .await?
        .into_iter()
        .find(|c| c.room_id == room.as_str())
        .unwrap();
    println!(
        "pinned={} archived={} muted={}",
        r.pinned, r.archived, r.muted
    );
    if !(r.pinned && r.archived && r.muted) {
        bail!("list flags wrong")
    }
    b.set_chat_muted(&room, false).await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    if b.chat_list()
        .await?
        .into_iter()
        .find(|c| c.room_id == room.as_str())
        .unwrap()
        .muted
    {
        bail!("unmute failed")
    }
    println!("CHATLIST CHECK PASSED");
    Ok(())
}
