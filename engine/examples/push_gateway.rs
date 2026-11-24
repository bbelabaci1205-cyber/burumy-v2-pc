// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Push through our gateway: Matrix server -> server/push-gateway ->
//! stand-ins for Google (FCM) and Apple (APNs) on 127.0.0.1:18099.
//! Checks that Google/Apple get a wake-up with no ids, no text, no sender.
//! Usage: push_gateway <hs> <token> <gateway notify url>
#![recursion_limit = "256"]
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
    let gw = std::env::args()
        .nth(3)
        .unwrap_or("http://127.0.0.1:8091/_matrix/push/v1/notify".into());
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-pushgw-{run}"));

    // Stand-in Google + Apple: record (request line, headers, body).
    let listener = TcpListener::bind("127.0.0.1:18099").await?;
    let (tx, mut rx) = mpsc::channel::<(String, String, String)>(32);
    tokio::spawn(async move {
        while let Ok((mut s, _)) = listener.accept().await {
            let tx = tx.clone();
            tokio::spawn(async move {
                let mut buf = vec![0u8; 65536];
                let mut got = Vec::new();
                let (head, body) = loop {
                    let n = s.read(&mut buf).await.unwrap_or(0);
                    if n == 0 {
                        return;
                    }
                    got.extend_from_slice(&buf[..n]);
                    let t = String::from_utf8_lossy(&got).to_string();
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
                            break (t[..i].to_string(), t[i + 4..].to_string());
                        }
                    }
                };
                let line = head.lines().next().unwrap_or_default().to_string();
                let (code, out) = if line.starts_with("POST /token") {
                    (
                        "200 OK",
                        r#"{"access_token":"google-access-1","expires_in":3600}"#.to_string(),
                    )
                } else if line.contains("/messages:send") && body.contains("gone-token") {
                    (
                        "404 Not Found",
                        r#"{"error":{"status":"NOT_FOUND"}}"#.to_string(),
                    )
                } else {
                    ("200 OK", "{}".to_string())
                };
                let _ = tx.send((line, head, body)).await;
                let _ = s.write_all(format!("HTTP/1.1 {code}\r\ncontent-type: application/json\r\ncontent-length: {}\r\nconnection: close\r\n\r\n{out}", out.len()).as_bytes()).await;
            });
        }
    });

    let alice = Engine::open(&hs, &dir.join("a"), "s").await?;
    alice
        .register(&format!("ga{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let bob = Engine::open(&hs, &dir.join("b"), "s").await?;
    bob.register(&format!("gb{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let apple_device = "a1b2c3d4e5f60718293a4b5c6d7e8f90a1b2c3d4e5f60718293a4b5c6d7e8f90";
    bob.set_push(&gw, "fcm-token-bob", "app.burumy.android")
        .await?;
    bob.set_push(&gw, apple_device, "app.burumy.ios").await?;
    bob.set_push(&gw, "gone-token", "app.burumy.android")
        .await?;
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
    let eid = alice.send_text(&room, secret).await?;

    let mut seen = vec![];
    while let Ok(Some(x)) = tokio::time::timeout(Duration::from_secs(6), rx.recv()).await {
        seen.push(x);
    }
    let fcm: Vec<_> = seen
        .iter()
        .filter(|x| x.0.contains("/v1/projects/test-project/messages:send"))
        .collect();
    let apns: Vec<_> = seen
        .iter()
        .filter(|x| x.0.contains(&format!("/3/device/{apple_device}")))
        .collect();
    let tok = seen
        .iter()
        .filter(|x| x.0.starts_with("POST /token"))
        .count();
    println!(
        "google token requests {tok}, FCM sends {}, APNs sends {}",
        fcm.len(),
        apns.len()
    );
    if fcm.is_empty() || apns.is_empty() || tok == 0 {
        bail!("a wake-up did not arrive")
    }
    for (line, head, body) in fcm.iter().chain(apns.iter()) {
        println!("  {line}\n    body: {body}");
        let all = format!("{line}\n{head}\n{body}");
        for bad in [
            secret,
            eid.as_str(),
            room.as_str(),
            alice.user_id().unwrap().as_str(),
            "event_id",
            "room_id",
        ] {
            if all.contains(bad) {
                bail!("Google/Apple would see {bad}")
            }
        }
    }
    let (_, fhead, _) = fcm[0];
    if !fhead
        .to_ascii_lowercase()
        .contains("authorization: bearer google-access-1")
    {
        bail!("FCM call not signed in")
    }
    let (_, ahead, _) = apns[0];
    let al = ahead.to_ascii_lowercase();
    if !al.contains("apns-topic: app.burumy.ios") || !al.contains("authorization: bearer ey") {
        bail!("APNs headers wrong")
    }
    println!("PUSH GATEWAY CHECK PASSED");
    Ok(())
}
