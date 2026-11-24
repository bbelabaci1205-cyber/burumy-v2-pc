// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Forwarding and in-chat search against a real server.
//! Usage: forward <hs> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-forward-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("fa{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("fb{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let c = Engine::open(&hs, &dir.join("c"), "s").await?;
    c.register(&format!("fc{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    // a <-> b and a <-> c.
    let ab = a.create_dm(&b.user_id().unwrap()).await?;
    let ac = a.create_dm(&c.user_id().unwrap()).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&ab) {
            break;
        }
    }
    b.join(&ab).await?;
    for _ in 0..40 {
        c.sync_once().await?;
        if c.invited_rooms().contains(&ac) {
            break;
        }
    }
    c.join(&ac).await?;
    a.sync_once().await?;

    // b writes and edits a text, sends a photo and a view-once photo.
    let t = b.send_text(&ab, "회의는 3시예요").await?;
    b.edit(&ab, &t, "회의는 4시로 바뀌었어요").await?;
    let pic = vec![0x89u8, b'P', b'N', b'G', 9, 8, 7, 6];
    let p = b
        .send_file(&ab, "plan.png", "image/png", pic.clone())
        .await?;
    let once = b
        .send_view_once(&ab, "o.png", "image/png", pic.clone())
        .await?;
    for i in 0..30 {
        b.send_text(&ab, &format!("잡담 {i}")).await?;
    }
    for _ in 0..3 {
        a.sync_once().await?;
    }

    // a passes the text (latest wording) and the photo on to c.
    a.forward(&ab, &t, &ac).await?;
    a.forward(&ab, &p, &ac).await?;
    if a.forward(&ab, &once, &ac).await.is_ok() {
        bail!("view once was forwarded")
    }
    for _ in 0..3 {
        c.sync_once().await?;
    }
    let tl = c.timeline(&ac, 20).await?;
    let text = tl
        .iter()
        .find(|m| m.kind == "text")
        .ok_or_else(|| anyhow::anyhow!("text missing"))?;
    let photo = tl
        .iter()
        .find(|m| m.kind == "image")
        .ok_or_else(|| anyhow::anyhow!("photo missing"))?;
    println!(
        "c got: {:?} forwarded={} / photo forwarded={} encrypted={}",
        text.body, text.forwarded, photo.forwarded, photo.was_encrypted
    );
    if text.body.as_deref() != Some("회의는 4시로 바뀌었어요")
        || !text.forwarded
        || !photo.forwarded
    {
        bail!("forward content wrong")
    }
    let (_, bytes, enc) = c.download_file(&ac, &photo.event_id).await?;
    println!(
        "c opened forwarded photo: {} bytes, encrypted file {enc}",
        bytes.len()
    );
    if bytes != pic || !enc {
        bail!("forwarded photo bytes wrong")
    }

    // In-chat search on the phone, reaching back past the 30 small talks.
    let hits = a.search(&ab, "4시", 500).await?;
    println!(
        "search '4시': {:?}",
        hits.iter().map(|m| m.body.clone()).collect::<Vec<_>>()
    );
    if hits.len() != 1 {
        bail!("search wrong")
    }
    let many = a.search(&ab, "잡담 2", 500).await?;
    println!(
        "search '잡담 2': {} hits, newest first: {:?}",
        many.len(),
        many.first().and_then(|m| m.body.clone())
    );
    if many.len() != 11 || many[0].body.as_deref() != Some("잡담 29") {
        bail!("search order wrong")
    }
    println!("FORWARD CHECK PASSED");
    Ok(())
}
