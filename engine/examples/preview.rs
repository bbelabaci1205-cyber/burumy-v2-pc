// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Link previews (with a small local web page) and voice messages
//! against a real server.
//! Usage: preview <hs> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

const PNG: &[u8] = &[0x89, b'P', b'N', b'G', 13, 10, 26, 10, 1, 2, 3, 4, 5];

async fn web() -> Result<(u16, std::sync::Arc<std::sync::atomic::AtomicUsize>)> {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
    let port = listener.local_addr()?.port();
    let hits = std::sync::Arc::new(std::sync::atomic::AtomicUsize::new(0));
    let h = hits.clone();
    tokio::spawn(async move {
        loop {
            let Ok((mut sock, _)) = listener.accept().await else {
                break;
            };
            h.fetch_add(1, std::sync::atomic::Ordering::SeqCst);
            let mut buf = vec![0u8; 4096];
            let n = sock.read(&mut buf).await.unwrap_or(0);
            let req = String::from_utf8_lossy(&buf[..n]).to_string();
            let (ctype, body): (&str, Vec<u8>) = if req.starts_with("GET /pic.png") {
                ("image/png", PNG.to_vec())
            } else {
                (
                    "text/html; charset=utf-8",
                    r#"<html><head><title>fallback</title>
<meta property="og:title" content="부루미 출시 소식">
<meta property="og:description" content="암호화 메신저 부루미가 곧 나와요.">
<meta property="og:image" content="/pic.png"></head><body>hi</body></html>"#
                        .as_bytes()
                        .to_vec(),
                )
            };
            let head = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: {ctype}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n",
                body.len()
            );
            let _ = sock.write_all(head.as_bytes()).await;
            let _ = sock.write_all(&body).await;
        }
    });
    Ok((port, hits))
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-preview-{run}"));
    let (port, hits) = web().await?;
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("pa{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("pb{run}"), "Secret-pass-123", token.as_deref())
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

    let id = a
        .send_text(&room, &format!("이거 봐요 http://127.0.0.1:{port}/news"))
        .await?;
    let fetched = hits.load(std::sync::atomic::Ordering::SeqCst);
    println!("sender's phone visited the page {fetched} time(s) (page + picture)");
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let m = b
        .timeline(&room, 10)
        .await?
        .into_iter()
        .find(|m| m.event_id == id)
        .ok_or_else(|| anyhow::anyhow!("missing"))?;
    let p = m
        .preview
        .clone()
        .ok_or_else(|| anyhow::anyhow!("no preview"))?;
    println!(
        "friend sees card: {:?} / {:?} / site {:?} / picture {}",
        p.title, p.description, p.site, p.has_image
    );
    if p.title != "부루미 출시 소식" || !p.has_image {
        bail!("card wrong")
    }
    let img = b.preview_image(&room, &id).await?;
    if img != PNG {
        bail!("picture wrong")
    }
    let after = hits.load(std::sync::atomic::Ordering::SeqCst);
    println!(
        "friend opened the picture ({} bytes) without visiting the site: visits still {after}",
        img.len()
    );
    if after != fetched {
        bail!("friend contacted the website")
    }

    // Switched off: plain text only, no visit.
    let mut prefs = a.prefs().await;
    prefs.no_link_previews = true;
    a.set_prefs(&prefs).await?;
    let id2 = a
        .send_text(&room, &format!("다시 http://127.0.0.1:{port}/x"))
        .await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let m2 = b
        .timeline(&room, 10)
        .await?
        .into_iter()
        .find(|m| m.event_id == id2)
        .unwrap();
    println!(
        "previews off: card {:?}, visits {}",
        m2.preview.is_some(),
        hits.load(std::sync::atomic::Ordering::SeqCst)
    );
    if m2.preview.is_some() || hits.load(std::sync::atomic::Ordering::SeqCst) != after {
        bail!("preview made while off")
    }
    // Voice message: encrypted recording + length + loudness bars.
    let rec: Vec<u8> = (0..4000u32).map(|i| (i % 251) as u8).collect();
    let bars: Vec<u16> = (0..40).map(|i| (i * 25) as u16).collect();
    let vid = a
        .send_voice(&room, "audio/mp4", rec.clone(), 3200, &bars)
        .await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let vm = b
        .timeline(&room, 10)
        .await?
        .into_iter()
        .find(|m| m.event_id == vid)
        .unwrap();
    let v = vm
        .voice
        .clone()
        .ok_or_else(|| anyhow::anyhow!("not a voice message"))?;
    let (_, got, enc) = b.download_file(&room, &vid).await?;
    println!(
        "voice: kind {} {}ms, {} bars, {} bytes, encrypted file {enc}",
        vm.kind,
        v.duration_ms,
        v.waveform.len(),
        got.len()
    );
    if v.duration_ms != 3200 || v.waveform != bars || got != rec || !enc {
        bail!("voice wrong")
    }
    println!("PREVIEW CHECK PASSED");
    Ok(())
}
