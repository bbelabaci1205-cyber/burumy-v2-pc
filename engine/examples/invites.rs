// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Invitations: a 1:1 invitation is marked as 1:1 (the app opens it on its
//! own), a group invitation shows its name and who sent it, decline works.
//! Usage: invites <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-invites-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("ia{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("ib{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let a_id = a.user_id().unwrap().to_string();

    let dm = a.create_dm(&b.user_id().unwrap()).await?;
    let group = a
        .create_group("주말 모임", &[b.user_id().unwrap().to_owned()], false)
        .await?;
    let mut inv = vec![];
    for _ in 0..40 {
        b.sync_once().await?;
        inv = b.invitations().await;
        if inv.len() == 2 {
            break;
        }
    }
    for i in &inv {
        println!(
            "invite: name {:?}, from {}, 1:1 {}",
            i.name, i.inviter, i.direct
        );
    }
    let d = inv
        .iter()
        .find(|i| i.room_id == dm.as_str())
        .ok_or(anyhow::anyhow!("no dm invite"))?;
    let g = inv
        .iter()
        .find(|i| i.room_id == group.as_str())
        .ok_or(anyhow::anyhow!("no group invite"))?;
    if !d.direct || g.direct || g.name != "주말 모임" || d.inviter != a_id || g.inviter != a_id
    {
        bail!("invite details wrong")
    }

    b.join(&dm).await?;
    b.decline(&group).await?;
    b.sync_once().await?;
    let left = b.invitations().await;
    let list = b.chat_list().await?;
    let has_dm = list.iter().any(|c| c.room_id == dm.as_str());
    let has_group = list.iter().any(|c| c.room_id == group.as_str());
    println!(
        "after: invitations left {}, b has 1:1 {has_dm}, group {has_group}",
        left.len()
    );
    if !left.is_empty() || !has_dm || has_group {
        bail!("join/decline wrong")
    }
    a.sync_once().await?;
    a.send_text(&dm, "안녕").await?;
    let mut got = false;
    for _ in 0..5 {
        b.sync_once().await?;
        if b.chat_list().await?.iter().any(|c| {
            c.room_id == dm.as_str()
                && c.last
                    .as_ref()
                    .is_some_and(|m| m.body.as_deref() == Some("안녕"))
        }) {
            got = true;
            break;
        }
    }
    println!("b reads a's first message: {got}");
    if !got {
        bail!("no message")
    }
    println!("INVITES CHECK PASSED");
    Ok(())
}
