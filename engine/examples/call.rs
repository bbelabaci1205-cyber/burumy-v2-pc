// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Call signalling + call passes against a real server and our call-pass
//! service. Usage: call <hs> <token> [pass_url] [livekit_secret]
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use base64::Engine as _;
use burumy_engine::Engine;
use hmac::{Hmac, Mac};

fn claims(token: &str, secret: &str) -> Result<serde_json::Value> {
    let parts: Vec<&str> = token.split('.').collect();
    if parts.len() != 3 {
        bail!("not a JWT")
    }
    let mut mac = Hmac::<sha2::Sha256>::new_from_slice(secret.as_bytes())?;
    mac.update(format!("{}.{}", parts[0], parts[1]).as_bytes());
    let b = base64::engine::general_purpose::URL_SAFE_NO_PAD;
    mac.verify_slice(&b.decode(parts[2])?)
        .map_err(|_| anyhow::anyhow!("bad signature"))?;
    Ok(serde_json::from_slice(&b.decode(parts[1])?)?)
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let pass_url = std::env::args()
        .nth(3)
        .unwrap_or("http://127.0.0.1:8090/call/pass".into());
    let secret = std::env::args().nth(4).unwrap_or_default();
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-call-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("ca{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("cb{run}"), "Secret-pass-123", token.as_deref())
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

    // 1. Video call, answered, then ended.
    let id = a.start_call(&room, true).await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let ring = b.ringing_calls().await?;
    println!(
        "b rings: {} call(s), video {:?}",
        ring.len(),
        ring.first().map(|r| r.video)
    );
    if ring.len() != 1 || ring[0].call_id != id || !ring[0].video {
        bail!("not ringing")
    }
    if !a.ringing_calls().await?.is_empty() {
        bail!("caller rings for own call")
    }
    b.answer_call(&room, &id).await?;
    let pa = a.call_pass(&room, &id, &pass_url).await?;
    let pb = b.call_pass(&room, &id, &pass_url).await?;
    println!(
        "passes: a→{} b→{}; same media key: {}",
        pa.url,
        pb.url,
        pa.media_key == pb.media_key
    );
    if pa.media_key != pb.media_key || pa.media_key.len() < 40 {
        bail!("media key mismatch")
    }
    if !secret.is_empty() {
        let (ca, cb) = (claims(&pa.token, &secret)?, claims(&pb.token, &secret)?);
        println!("pass a: sub {} room {}", ca["sub"], ca["video"]["room"]);
        if ca["video"]["room"] != id.as_str() || cb["video"]["room"] != id.as_str() {
            bail!("wrong call room in pass")
        }
        if ca["sub"] == cb["sub"] || ca["sub"] != a.user_id().unwrap().as_str() {
            bail!("wrong identity in pass")
        }
    }
    // A wrong OpenID token gets nothing.
    let bad = reqwest::Client::new()
        .post(&pass_url)
        .header("content-type", "application/json")
        .body(serde_json::json!({ "openid_token": "nope", "call": id, "video": true }).to_string())
        .send()
        .await?;
    println!("fake token → {}", bad.status());
    if bad.status().is_success() {
        bail!("fake token got a pass")
    }
    for _ in 0..2 {
        a.sync_once().await?;
        b.sync_once().await?;
    }
    if !b.ringing_calls().await?.is_empty() {
        bail!("still ringing after answer")
    }
    a.hangup_call(&room, &id, "end").await?;

    // 2. Voice call, declined.
    let id2 = a.start_call(&room, false).await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    b.hangup_call(&room, &id2, "decline").await?;
    for _ in 0..3 {
        a.sync_once().await?;
        b.sync_once().await?;
    }
    let tl = a.timeline(&room, 30).await?;
    let lines: Vec<(String, bool)> = tl
        .iter()
        .filter_map(|m| m.call.as_ref().map(|c| (c.state.clone(), c.video)))
        .collect();
    println!("call lines in chat: {lines:?}");
    if lines.len() != 2
        || !lines.contains(&("ended".into(), true))
        || !lines.contains(&("declined".into(), false))
    {
        bail!("call lines wrong")
    }
    if tl.iter().any(|m| m.call.is_some() && !m.was_encrypted) {
        bail!("call event not encrypted")
    }
    println!("CALL CHECK PASSED");
    Ok(())
}
