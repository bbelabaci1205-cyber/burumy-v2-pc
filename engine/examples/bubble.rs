// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Home-screen bubbles against a real server. Usage: bubble <hs> <token>
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
    let dir = std::env::temp_dir().join(format!("burumy-bubble-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("ba{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("bb{run}"), "Secret-pass-123", token.as_deref())
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

    let e = a
        .send_bubble(&room, "emoji", "text/plain", "🥳".as_bytes().to_vec())
        .await?;
    let pic = vec![0x89u8, b'P', b'N', b'G', 5, 5, 5];
    let p = a
        .send_bubble(&room, "photo", "image/png", pic.clone())
        .await?;
    if a.send_bubble(&room, "voice", "image/png", pic.clone())
        .await
        .is_ok()
    {
        bail!("wrong file accepted")
    }
    for _ in 0..3 {
        b.sync_once().await?;
    }

    let waiting = b.pending_bubbles().await?;
    println!(
        "b's home screen: {} bubble(s) from {:?}",
        waiting.len(),
        waiting.iter().map(|w| w.from.clone()).collect::<Vec<_>>()
    );
    if waiting.len() != 2 {
        bail!("bubbles missing")
    }
    // The chat itself does not show what's inside the closed emoji bubble.
    let tl = b.timeline(&room, 20).await?;
    let em = tl.iter().find(|m| m.event_id == e).unwrap();
    println!(
        "closed emoji bubble body in chat: {:?} (bubble {}, view once {})",
        em.body, em.bubble, em.view_once
    );
    if em.body.as_deref() != Some("") || !em.bubble {
        bail!("emoji visible before popping")
    }

    let got = b.open_view_once(&room, &e).await?;
    println!("popped emoji: {}", String::from_utf8_lossy(&got));
    if got != "🥳".as_bytes() {
        bail!("emoji wrong")
    }
    if b.open_view_once(&room, &e).await.is_ok() {
        bail!("popped twice")
    }
    let photo = b.open_view_once(&room, &p).await?;
    if photo != pic {
        bail!("photo wrong")
    }
    for _ in 0..3 {
        b.sync_once().await?;
        a.sync_once().await?;
    }
    let left = b.pending_bubbles().await?.len();
    let seen = a
        .timeline(&room, 20)
        .await?
        .iter()
        .filter(|m| m.bubble && m.opened)
        .count();
    println!("after popping: {left} left on b's home screen; a sees {seen} popped");
    if left != 0 || seen != 2 {
        bail!("pop state wrong")
    }
    println!("BUBBLE CHECK PASSED");
    Ok(())
}
