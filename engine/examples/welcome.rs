// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 환영 인사 + 규칙 against a real server (Eric 2026-11-27). Usage:
//! welcome <hs> <token>
//! - the owner's pack (words + an encrypted photo key) reaches a member as
//!   a hidden encrypted signal; the photo decrypts to the same bytes;
//! - the room's settings on the server hold only the fingerprint (no words),
//!   and plain welcome/rules can no longer be written;
//! - someone who joins later can't read the first pack, but gets the one the
//!   owner's phone sends after they join.
#![recursion_limit = "256"]
use anyhow::{Result, bail, ensure};
use burumy_engine::Engine;
use matrix_sdk::ruma::RoomId;

async fn wait_signal(e: &Engine, room: &RoomId) -> Result<Option<burumy_engine::signal::Signal>> {
    for _ in 0..20 {
        e.sync_once().await?;
        if let Some(s) = e
            .take_signals()
            .into_iter()
            .find(|s| s.room_id == room.as_str() && s.kind == "room_texts")
        {
            return Ok(Some(s));
        }
    }
    Ok(None)
}

async fn join_when_invited(e: &Engine, room: &RoomId) -> Result<()> {
    for _ in 0..40 {
        e.sync_once().await?;
        if e.invited_rooms().iter().any(|r| r.as_str() == room.as_str()) {
            return e.join(room).await;
        }
    }
    bail!("no invite")
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-welcome-{run}"));
    let mut people = vec![];
    for n in ["a", "b", "c"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("w{n}{run}"), "Secret-pass-123", token.as_deref())
            .await?;
        people.push(e);
    }
    let (a, b, c) = (&people[0], &people[1], &people[2]);
    let room = a.create_group("러닝 모임", &[b.user_id().unwrap()], false).await?;
    join_when_invited(b, &room).await?;
    for e in [a, b] {
        e.sync_once().await?;
    }

    // Owner: photo encrypted on the phone, pack as a hidden signal, room
    // keeps only the fingerprint.
    let photo: Vec<u8> = (0..300_000u32).map(|i| (i % 251) as u8).collect();
    let file = a.upload_secret(photo.clone()).await?;
    ensure!(!file.contains("러닝"), "file ref has no words");
    let pack = serde_json::json!({
        "n": "a1b2", "welcome": "**어서 와요!** 토요일 7시 한강 출발", "rules": "1. 서로 존중해요",
        "at": 1, "media": {"file": file, "mime": "image/jpeg", "name": "hi.jpg"},
    });
    let h = "ab".repeat(32); // the app's SHA-256; the engine only checks shape
    a.set_room_config(&room, "texts", &serde_json::json!({"h": h, "w": true, "r": true}).to_string())
        .await?;
    a.send_signal(&room, "room_texts", &pack.to_string()).await?;
    let plain = a.set_room_config(&room, "welcome", "\"평문 인사\"").await;
    ensure!(plain.is_err(), "plain welcome must be refused");
    println!("plain welcome refused: {}", plain.unwrap_err());

    // Member b gets the pack and the photo.
    let got = wait_signal(b, &room).await?.ok_or_else(|| anyhow::anyhow!("b: no pack"))?;
    let v: serde_json::Value = serde_json::from_str(&got.data)?;
    ensure!(v["welcome"] == pack["welcome"] && v["rules"] == pack["rules"], "b: words");
    let bytes = b.download_secret(v["media"]["file"].as_str().unwrap()).await?;
    ensure!(bytes == photo, "b: photo bytes");
    println!("b: pack ok, photo {} bytes decrypted", bytes.len());

    // What the server holds for the room settings: fingerprint only.
    let cfg = b.room_config(&room).await;
    ensure!(!cfg.contains("어서") && !cfg.contains("존중") && cfg.contains(&h), "cfg: {cfg}");
    println!("room settings on the server: {cfg}");

    // c joins later: can't read the first pack ...
    a.invite_users(&room, &[c.user_id().unwrap().to_string()]).await?;
    join_when_invited(c, &room).await?;
    let early = wait_signal(c, &room).await?;
    ensure!(early.is_none(), "c must not read the pack sent before joining");
    println!("c: first pack not readable (joined later)");
    // ... the owner's phone sees the new member and sends it again.
    a.sync_once().await?;
    let mem = a.members(&room).await?;
    let newcomer = mem.iter().find(|m| m.user_id == c.user_id().unwrap().as_str()).unwrap();
    println!("owner sees newcomer since={}", newcomer.since);
    ensure!(newcomer.since > 0, "join time known");
    a.send_signal(&room, "room_texts", &pack.to_string()).await?;
    let got = wait_signal(c, &room).await?.ok_or_else(|| anyhow::anyhow!("c: no pack"))?;
    let v: serde_json::Value = serde_json::from_str(&got.data)?;
    let bytes = c.download_secret(v["media"]["file"].as_str().unwrap()).await?;
    ensure!(v["welcome"] == pack["welcome"] && bytes == photo, "c: pack + photo");
    println!("c: pack ok after joining, photo {} bytes", bytes.len());
    println!("WELCOME PASS");
    Ok(())
}
