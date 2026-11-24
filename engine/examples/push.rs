// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Push check: bob turns on notifications, alice sends an encrypted message,
//! and we look at exactly what the server hands to the push gateway.
//! Usage: push <homeserver> <token>
use std::time::Duration;

use anyhow::{Result, bail};
use burumy_engine::Engine;
use tokio::{
    io::{AsyncReadExt, AsyncWriteExt},
    net::TcpListener,
    sync::mpsc,
};

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-push-{run}"));

    // A stand-in push gateway (the real one is Sygnal -> Apple / Google).
    let listener = TcpListener::bind("127.0.0.1:0").await?;
    let gw = format!("http://{}/_matrix/push/v1/notify", listener.local_addr()?);
    let (tx, mut rx) = mpsc::channel::<String>(8);
    tokio::spawn(async move {
        while let Ok((mut s, _)) = listener.accept().await {
            let tx = tx.clone();
            tokio::spawn(async move {
                let mut buf = vec![0u8; 65536];
                let mut got = Vec::new();
                loop {
                    let n = s.read(&mut buf).await.unwrap_or(0);
                    if n == 0 {
                        break;
                    }
                    got.extend_from_slice(&buf[..n]);
                    let t = String::from_utf8_lossy(&got);
                    if let Some(i) = t.find("\r\n\r\n") {
                        let len = t
                            .lines()
                            .find_map(|l| {
                                l.to_ascii_lowercase()
                                    .strip_prefix("content-length:")
                                    .map(|v| v.trim().parse::<usize>().unwrap_or(0))
                            })
                            .unwrap_or(0);
                        if got.len() >= i + 4 + len {
                            let _ = tx.send(t[i + 4..].to_string()).await;
                            break;
                        }
                    }
                }
                let _ = s.write_all(b"HTTP/1.1 200 OK\r\ncontent-type: application/json\r\ncontent-length: 14\r\n\r\n{\"rejected\":[]}").await;
            });
        }
    });

    let alice = Engine::open(&hs, &dir.join("a"), "s").await?;
    alice
        .register(&format!("pa{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let bob = Engine::open(&hs, &dir.join("b"), "s").await?;
    bob.register(&format!("pb{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    bob.set_push(&gw, "test-push-key", "app.burumy.ios").await?;
    let room = alice.create_dm(&bob.user_id().unwrap()).await?;
    for _ in 0..40 {
        bob.sync_once().await?;
        if bob.invited_rooms().contains(&room) {
            break;
        }
    }
    bob.join(&room).await?;
    alice.sync_once().await?;
    let secret = "비밀 내용 12345";
    alice.send_text(&room, secret).await?;

    let mut seen = Vec::new();
    while let Ok(Some(body)) = tokio::time::timeout(Duration::from_secs(5), rx.recv()).await {
        seen.push(body);
    }
    if seen.is_empty() {
        bail!("no notification reached the gateway");
    }
    for (i, b) in seen.iter().enumerate() {
        println!("notification {}: {b}", i + 1);
    }
    let all = seen.join("\n");
    for bad in [
        secret,
        "sender_display_name",
        "room_name",
        "\"content\"",
        alice.user_id().unwrap().as_str(),
    ] {
        if all.contains(bad) {
            bail!("notification carries {bad}");
        }
    }
    println!(
        "PUSH CHECK PASSED: {} notification(s), only ids, no text / sender / chat name",
        seen.len()
    );
    Ok(())
}
