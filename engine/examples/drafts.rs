// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 임시 글 이어쓰기 (tip 241) + 내 알림음 (tip 329) on a real server:
//! a draft typed on my phone reaches my PC (end-to-end encrypted device
//! message to my own account), an older draft arriving late loses, a
//! friend can't plant a draft, and a saved sound stays in the encrypted
//! store. Usage: drafts <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-drafts-{run}"));
    let pw = "Secret-pass-123";
    let phone = Engine::open(&hs, &dir.join("phone"), "s").await?;
    phone.register(&format!("da{run}"), pw, token.as_deref()).await?;
    let pc = Engine::open(&hs, &dir.join("pc"), "s").await?;
    pc.login(&format!("da{run}"), pw, "pc").await?;
    let friend = Engine::open(&hs, &dir.join("friend"), "s").await?;
    friend.register(&format!("df{run}"), pw, token.as_deref()).await?;
    let room = phone.create_dm(&friend.user_id().unwrap()).await?;
    for e in [&phone, &pc, &friend] {
        e.sync_once().await?;
    }

    println!("1) only device: nothing is sent");
    let lone = Engine::open(&hs, &dir.join("lone"), "s").await?;
    lone.register(&format!("dl{run}"), pw, token.as_deref()).await?;
    if lone.send_my_draft(room.as_str(), "x", 1).await? {
        bail!("sent with no other device");
    }

    println!("2) phone -> pc");
    let mut sent = false;
    for _ in 0..20 {
        if phone.send_my_draft(room.as_str(), "토요일에 북한산 갈래?", 2000).await? {
            sent = true;
            break;
        }
        phone.sync_once().await?;
    }
    if !sent {
        bail!("phone never saw the pc device");
    }
    // An older one arriving later must not win.
    phone.send_my_draft(room.as_str(), "옛날 글", 1000).await?;
    let mut got = vec![];
    for _ in 0..20 {
        pc.sync_once().await?;
        got.extend(pc.take_synced_drafts().await?);
        if !got.is_empty() {
            break;
        }
    }
    println!("  pc got {got:?}");
    if got.len() != 1 || got[0].text != "토요일에 북한산 갈래?" || got[0].at != 2000 {
        bail!("pc did not get the newest draft");
    }
    // The phone doesn't take back its own.
    phone.sync_once().await?;
    if !phone.take_synced_drafts().await?.is_empty() {
        bail!("phone took its own draft");
    }

    println!("3) a friend can't plant a draft");
    friend.sync_once().await?;
    friend.join(&room).await?;
    for _ in 0..5 {
        friend.sync_once().await?;
        if friend.send_device_message_for_test(phone.user_id().unwrap().as_str(), "app.burumy.ping", &serde_json::json!({})).await.is_ok() {
            break;
        }
    }
    let content = serde_json::json!({"room": room.as_str(), "text": "가짜", "at": 9999, "from": "X"});
    friend.send_device_message_for_test(phone.user_id().unwrap().as_str(), burumy_engine::mine::DRAFT_MSG, &content).await?;
    for _ in 0..5 {
        pc.sync_once().await?;
        phone.sync_once().await?;
    }
    if !pc.take_synced_drafts().await?.is_empty() || !phone.take_synced_drafts().await?.is_empty() {
        bail!("took a draft from someone else");
    }

    println!("4) saved sound in the encrypted store");
    phone.save_blob("tone_t1", &[1, 2, 3]).await?;
    if phone.blob("tone_t1").await?.as_deref() != Some(&[1u8, 2, 3][..]) {
        bail!("blob not read back");
    }
    if phone.save_blob("tone_big", &vec![0u8; 400 * 1024]).await.is_ok() {
        bail!("big blob taken");
    }
    phone.drop_blob("tone_t1").await?;
    if phone.blob("tone_t1").await?.is_some() {
        bail!("blob not dropped");
    }
    println!("ALL OK");
    let _ = std::fs::remove_dir_all(&dir);
    Ok(())
}
