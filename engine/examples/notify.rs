// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Notifications made on the phone after a wake-up: each message once,
//! muted chats never, text hidden when the person asks.
//! Usage: notify <hs> <token>
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
    let dir = std::env::temp_dir().join(format!("burumy-notify-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("na{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("nb{run}"), "Secret-pass-123", token.as_deref())
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

    a.send_text(&room, "저녁 7시 어때요?").await?;
    a.send_text(&room, "답장 주세요").await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let n = b.notifications(10).await?;
    println!(
        "first wake: {:?}",
        n.iter()
            .map(|x| (x.chat.clone(), x.body.clone()))
            .collect::<Vec<_>>()
    );
    if n.len() != 2 || n[0].body.as_deref() != Some("저녁 7시 어때요?") {
        bail!("notifications wrong")
    }
    if !b.notifications(10).await?.is_empty() {
        bail!("same message notified twice")
    }

    // Hide text: only "new message".
    let mut p = b.prefs().await;
    p.hide_notice_text = true;
    b.set_prefs(&p).await?;
    a.send_text(&room, "비밀 이야기").await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let n = b.notifications(10).await?;
    println!(
        "hidden: {:?}",
        n.iter()
            .map(|x| (x.chat.clone(), x.body.clone()))
            .collect::<Vec<_>>()
    );
    if n.len() != 1 || n[0].body.is_some() || !n[0].chat.is_empty() {
        bail!("text not hidden")
    }

    // Muted chat: nothing.
    b.set_chat_muted(&room, true).await?;
    a.send_text(&room, "조용히").await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    if !b.notifications(10).await?.is_empty() {
        bail!("muted chat notified")
    }
    println!("NOTIFY CHECK PASSED");
    Ok(())
}
