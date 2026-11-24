// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Group/channel + reply/edit/delete check. Usage: ops <homeserver> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-ops-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("oa{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("ob{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let bid = b.user_id().unwrap();

    // Group: both may write.
    let g = a.create_group("시험 그룹", &[bid.clone()], false).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&g) {
            break;
        }
    }
    b.join(&g).await?;
    a.sync_once().await?;
    b.sync_once().await?;
    println!(
        "group: owner can_post={} member can_post={} is_channel={}",
        a.can_post(&g).await?,
        b.can_post(&g).await?,
        b.is_channel(&g).await
    );
    if !b.can_post(&g).await? || b.is_channel(&g).await {
        bail!("group rights wrong")
    }

    // Reply, edit, delete.
    let first = a.send_text(&g, "원래 글").await?;
    for _ in 0..5 {
        b.sync_once().await?;
    }
    let rep = b.reply(&g, &first, "답장이에요").await?;
    a.edit(&g, &first, "고친 글").await?;
    let gone = a.send_text(&g, "지울 글").await?;
    a.delete_message(&g, &gone).await?;
    b.set_typing(&g, true).await?;
    for _ in 0..8 {
        b.sync_once().await?;
    }
    for _ in 0..5 {
        a.sync_once().await?;
        if !a.typing_users(&g).is_empty() {
            break;
        }
    }
    println!("typing seen by owner: {:?}", a.typing_users(&g));
    if a.typing_users(&g) != vec![bid.to_string()] {
        bail!("typing not seen")
    }
    let tl = b.timeline(&g, 30).await?;
    for m in &tl {
        println!(
            "  {:?} edited={} reply_to={:?}",
            m.body,
            m.edited,
            m.reply_to.as_ref().map(|r| r == &first)
        );
    }
    let f = tl
        .iter()
        .find(|m| m.event_id == first)
        .ok_or_else(|| anyhow::anyhow!("first missing"))?;
    if f.body.as_deref() != Some("고친 글") || !f.edited {
        bail!("edit not applied")
    }
    let r = tl
        .iter()
        .find(|m| m.event_id == rep)
        .ok_or_else(|| anyhow::anyhow!("reply missing"))?;
    if r.reply_to.as_deref() != Some(first.as_str()) || r.body.as_deref() != Some("답장이에요")
    {
        bail!("reply wrong")
    }
    if tl.iter().any(|m| m.event_id == gone) {
        bail!("deleted message still shown")
    }
    if tl.iter().any(|m| m.replaces.is_some()) {
        bail!("edit event shown as message")
    }

    // Reactions: both pick a heart, owner also a thumbs up, then takes it back.
    a.react(&g, &first, "❤️").await?;
    b.react(&g, &first, "❤️").await?;
    let thumbs = a.react(&g, &first, "👍").await?;
    a.delete_message(&g, &thumbs).await?;
    a.pin(&g, &first, true).await?;
    for _ in 0..6 {
        b.sync_once().await?;
    }
    let tl3 = b.timeline(&g, 40).await?;
    let f3 = tl3.iter().find(|m| m.event_id == first).unwrap();
    println!(
        "reactions seen by member: {:?}; pinned: {:?}",
        f3.reactions
            .iter()
            .map(|r| (&r.key, r.count, r.mine.is_some()))
            .collect::<Vec<_>>(),
        b.pinned(&g)
    );
    if f3.reactions.len() != 1 || f3.reactions[0].count != 2 || f3.reactions[0].mine.is_none() {
        bail!("reactions wrong")
    }
    if b.pinned(&g) != vec![first.clone()] {
        bail!("pin wrong")
    }

    // Built-in sticker: only its id travels, encrypted.
    let st = a.send_sticker(&g, "buru_01_hello").await?;
    for _ in 0..5 {
        b.sync_once().await?;
    }
    let tl2 = b.timeline(&g, 40).await?;
    let sm = tl2
        .iter()
        .find(|m| m.event_id == st)
        .ok_or_else(|| anyhow::anyhow!("sticker missing"))?;
    println!(
        "sticker: kind={} body={:?} encrypted={}",
        sm.kind, sm.body, sm.was_encrypted
    );
    if sm.kind != "sticker" || sm.body.as_deref() != Some("buru_01_hello") || !sm.was_encrypted {
        bail!("sticker wrong")
    }

    // Channel: only the owner writes.
    let c = a.create_group("시험 채널", &[bid.clone()], true).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&c) {
            break;
        }
    }
    b.join(&c).await?;
    a.sync_once().await?;
    b.sync_once().await?;
    let (ao, bo) = (a.can_post(&c).await?, b.can_post(&c).await?);
    println!(
        "channel: owner can_post={ao} subscriber can_post={bo} is_channel={}",
        b.is_channel(&c).await
    );
    if !ao || bo || !b.is_channel(&c).await {
        bail!("channel rights wrong")
    }
    a.send_text(&c, "채널 첫 글").await?;
    if b.send_text(&c, "구독자 글").await.is_ok() {
        bail!("subscriber could post")
    }
    println!("subscriber post refused (good)");
    for _ in 0..5 {
        b.sync_once().await?;
    }
    let ct = b.timeline(&c, 10).await?;
    if !ct.iter().any(|m| m.body.as_deref() == Some("채널 첫 글")) {
        bail!("subscriber cannot read channel")
    }
    // Profile + members + leave.
    a.set_my_name("에릭").await?;
    for _ in 0..4 {
        b.sync_once().await?;
        a.sync_once().await?;
    }
    println!("my name: {}", a.my_name().await?);
    let mem = b.members(&g).await?;
    println!(
        "members: {:?}",
        mem.iter().map(|m| (&m.name, &m.role)).collect::<Vec<_>>()
    );
    if a.my_name().await? != "에릭"
        || mem.len() != 2
        || mem[0].role != "owner"
        || mem[1].role != "member"
    {
        bail!("profile/members wrong")
    }
    b.leave(&c).await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    let left = a.members(&c).await?.len();
    println!("channel members after subscriber left: {left}");
    if left != 1 {
        bail!("leave failed")
    }
    println!("OPS CHECK PASSED");
    Ok(())
}
