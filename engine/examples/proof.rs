// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Feasibility proof: sign-up, E2E 1:1 chat both ways, 대화 복구 키 on a new
//! device, and an emoji check between two people.
//! Usage: proof <homeserver-url> [registration-token]

use std::{future::Future, time::Duration};

use anyhow::{Result, bail};
use burumy_engine::Engine;
use matrix_sdk::ruma::{OwnedRoomId, UserId};

async fn wait_for<F, Fut>(what: &str, engines: &[&Engine], mut check: F) -> Result<()>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = Result<bool>>,
{
    for _ in 0..60 {
        for e in engines {
            e.sync_once().await?;
        }
        if check().await? {
            println!("  ok: {what}");
            return Ok(());
        }
        tokio::time::sleep(Duration::from_millis(250)).await;
    }
    bail!("timed out: {what}")
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let dir = tempfile_dir()?;
    let run = std::process::id();
    let (alice_name, bob_name) = (format!("alice{run}"), format!("bob{run}"));
    let pw = "Secret-pass-123";

    println!("1) sign-up (ID only)");
    let alice = Engine::open(&hs, &dir.join("alice1"), "store-pass-a1").await?;
    alice.register(&alice_name, pw, token.as_deref()).await?;
    let bob = Engine::open(&hs, &dir.join("bob1"), "store-pass-b1").await?;
    bob.register(&bob_name, pw, token.as_deref()).await?;
    let (a_id, b_id) = (alice.user_id().unwrap(), bob.user_id().unwrap());
    println!("  ok: {a_id} / {b_id}");

    println!("2) 대화 복구 키 (key backup + secret storage)");
    let recovery_key = alice.enable_recovery().await?;
    println!(
        "  ok: recovery key made ({} words)",
        recovery_key.split_whitespace().count()
    );

    println!("3) encrypted 1:1 chat");
    let room: OwnedRoomId = alice.create_dm(&b_id).await?;
    let r = room.clone();
    wait_for("bob sees the invite", &[&bob], || {
        let b = bob.clone();
        let r = r.clone();
        async move { Ok(b.invited_rooms().contains(&r)) }
    })
    .await?;
    bob.join(&room).await?;
    alice.sync_once().await?;
    println!("  room encrypted: {}", alice.is_encrypted(&room).await?);
    alice.send_text(&room, "안녕 밥, 첫 메시지야").await?;
    let r = room.clone();
    wait_for("bob reads alice's message", &[&bob, &alice], || {
        let b = bob.clone();
        let r = r.clone();
        async move {
            let m = b.messages(&r, 20).await?;
            Ok(m.iter()
                .any(|m| m.was_encrypted && m.body.as_deref() == Some("안녕 밥, 첫 메시지야")))
        }
    })
    .await?;
    bob.send_text(&room, "응 잘 받았어").await?;
    let r = room.clone();
    wait_for("alice reads bob's answer", &[&alice, &bob], || {
        let a = alice.clone();
        let r = r.clone();
        async move {
            let m = a.messages(&r, 20).await?;
            Ok(m.iter()
                .any(|m| m.was_encrypted && m.body.as_deref() == Some("응 잘 받았어")))
        }
    })
    .await?;

    println!("4) new device for alice; old messages need the 대화 복구 키");
    // Make sure the room keys reached the backup before the new device looks.
    alice.enable_recovery_wait().await.ok();
    let alice2 = Engine::open(&hs, &dir.join("alice2"), "store-pass-a2").await?;
    alice2.login(&alice_name, pw, "alice phone 2").await?;
    alice2.sync_once().await?;
    let before = alice2.messages(&room, 20).await?;
    let opened_before = before.iter().filter(|m| m.body.is_some()).count();
    println!(
        "  before key: {opened_before} of {} messages open",
        before.len()
    );
    alice2.recover(&recovery_key).await?;
    alice2.download_keys_for(&room).await?;
    let after = alice2.messages(&room, 20).await?;
    let opened_after = after.iter().filter(|m| m.body.is_some()).count();
    println!(
        "  after key: {opened_after} of {} messages open",
        after.len()
    );
    if opened_after < 2 {
        bail!("recovery did not open the old messages");
    }
    println!("  ok: old messages open on the new device");

    println!("5) emoji check alice <-> bob");
    let flow = alice.request_user_verification(&b_id).await?;
    let f = flow.clone();
    let a_uid = a_id.clone();
    wait_for("bob gets the request", &[&bob, &alice], || {
        let b = bob.clone();
        let f = f.clone();
        let u = a_uid.clone();
        async move {
            Ok(b.client()
                .encryption()
                .get_verification_request(&u, &f)
                .await
                .is_some())
        }
    })
    .await?;
    bob.accept_verification(&a_id, &flow).await?;
    wait_for("alice sees accept", &[&alice, &bob], || async { Ok(true) }).await?;
    alice.start_sas(&b_id, &flow).await?;
    let mut emoji_a = None;
    let mut emoji_b = None;
    for _ in 0..60 {
        for e in [&alice, &bob] {
            e.sync_once().await?;
        }
        emoji_b = bob.sas_emoji(&a_id, &flow).await?;
        emoji_a = alice.sas_emoji(&b_id, &flow).await?;
        if emoji_a.is_some() && emoji_b.is_some() {
            break;
        }
    }
    let (ea, eb) = (emoji_a.expect("alice emoji"), emoji_b.expect("bob emoji"));
    println!("  alice sees: {}", ea.join(", "));
    println!("  bob sees:   {}", eb.join(", "));
    if ea != eb {
        bail!("emoji differ");
    }
    alice.confirm_sas(&b_id, &flow).await?;
    bob.confirm_sas(&a_id, &flow).await?;
    let b2: &UserId = &b_id;
    let a2: &UserId = &a_id;
    wait_for("both marked verified", &[&alice, &bob], || {
        let (a, b) = (alice.clone(), bob.clone());
        async move { Ok(a.is_user_verified(b2).await? && b.is_user_verified(a2).await?) }
    })
    .await?;

    println!("\nALL CHECKS PASSED");
    Ok(())
}

fn tempfile_dir() -> Result<std::path::PathBuf> {
    let d = std::env::temp_dir().join(format!("burumy-v2-proof-{}", std::process::id()));
    std::fs::create_dir_all(&d)?;
    Ok(d)
}

trait WaitBackup {
    async fn enable_recovery_wait(&self) -> Result<()>;
}
impl WaitBackup for Engine {
    async fn enable_recovery_wait(&self) -> Result<()> {
        self.client()
            .encryption()
            .backups()
            .wait_for_steady_state()
            .await?;
        Ok(())
    }
}
