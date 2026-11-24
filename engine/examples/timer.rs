// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Disappearing messages against a real server. Usage: timer <hs> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-timer-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("ta{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("tb{run}"), "Secret-pass-123", token.as_deref())
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
    a.send_text(&room, "남는 글").await?;
    a.set_timer(&room, 3).await?;
    for _ in 0..3 {
        a.sync_once().await?;
        b.sync_once().await?;
    }
    println!(
        "timer seen: owner {}s, friend {}s",
        a.timer(&room).await,
        b.timer(&room).await
    );
    if b.timer(&room).await != 3 {
        bail!("friend did not get the timer")
    }
    // The friend's own messages follow the chat timer too.
    let gone = b.send_text(&room, "사라질 글").await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    let tl = a.timeline(&room, 20).await?;
    let m = tl
        .iter()
        .find(|m| m.event_id == gone)
        .ok_or_else(|| anyhow::anyhow!("message missing"))?;
    println!(
        "before: {:?} expires in {}ms",
        m.body,
        m.expires_at.unwrap_or(0) as i64 - m.ts as i64
    );
    tokio::time::sleep(std::time::Duration::from_secs(4)).await;
    let shown: Vec<_> = a
        .timeline(&room, 20)
        .await?
        .into_iter()
        .filter(|m| m.kind == "text")
        .filter_map(|m| m.body)
        .collect();
    println!("after 4s (owner sees): {shown:?}");
    if shown != vec!["남는 글".to_string()] {
        bail!("expired message still shown")
    }
    b.sync_once().await?;
    let n = b.run_expiry().await?;
    println!("friend's phone deleted {n} expired message(s) of its own for everyone");
    if n != 1 {
        bail!("expiry delete count wrong")
    }
    // Photos follow the chat timer too.
    a.set_timer(&room, 60).await?;
    let pic = vec![0x89u8, b'P', b'N', b'G', 1, 2, 3, 4];
    let p1 = a
        .send_file(&room, "a.png", "image/png", pic.clone())
        .await?;
    // View once: friend opens it one time, then it is gone.
    let once = a
        .send_view_once(&room, "b.png", "image/png", pic.clone())
        .await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let tl = b.timeline(&room, 30).await?;
    let f = tl.iter().find(|m| m.event_id == p1).unwrap();
    let o = tl.iter().find(|m| m.event_id == once).unwrap();
    println!(
        "photo timer: {}s; view once: {} opened {}",
        (f.expires_at.unwrap_or(0) - f.ts) / 1000,
        o.view_once,
        o.opened
    );
    if f.expires_at.is_none() || !o.view_once || o.opened {
        bail!("media flags wrong")
    }
    let bytes = b.open_view_once(&room, &once).await?;
    if bytes != pic {
        bail!("view once bytes wrong")
    }
    for _ in 0..3 {
        b.sync_once().await?;
        a.sync_once().await?;
    }
    if b.open_view_once(&room, &once).await.is_ok() {
        bail!("opened twice")
    }
    let seen = a
        .timeline(&room, 30)
        .await?
        .into_iter()
        .find(|m| m.event_id == once)
        .map(|m| m.opened);
    println!("sender sees opened: {seen:?}");
    if seen != Some(true) {
        bail!("sender did not see opened")
    }
    let n = a.run_expiry().await?;
    for _ in 0..3 {
        b.sync_once().await?;
        a.sync_once().await?;
    }
    let after = b.timeline(&room, 30).await?;
    println!(
        "sender deleted {n}; friend now sees photo: {}, opened line: {}",
        after.iter().any(|m| m.event_id == once),
        after.iter().any(|m| m.kind == "opened")
    );
    if after.iter().any(|m| m.event_id == once) || !after.iter().any(|m| m.kind == "opened") {
        bail!("view once not removed")
    }
    println!("TIMER CHECK PASSED");
    Ok(())
}
