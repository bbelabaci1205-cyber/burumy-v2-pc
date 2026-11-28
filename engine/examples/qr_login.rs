// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! QR로 PC 연결 + 기기 설정 end to end, on a real server with Conduit
//! (`jwt_secret` set) and server/qr-login running:
//! a phone vouches for a QR; a photo of the QR alone can't sign in; the PC
//! with the secret signs in once (same account, new device); the second
//! take gets nothing; the account privacy keys (idle days, no-call devices)
//! reach the other device.
//! Usage: qr_login <hs> <qr service> <registration token>
#![recursion_limit = "256"]

use anyhow::{Result, bail};
use burumy_engine::Engine;
use sha2::{Digest, Sha256};

async fn post(url: &str, body: serde_json::Value) -> Result<(u16, String)> {
    let r = reqwest::Client::new()
        .post(url)
        .header("content-type", "application/json")
        .body(body.to_string())
        .send()
        .await?;
    Ok((r.status().as_u16(), r.text().await?))
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let qr = std::env::args().nth(2).unwrap_or("http://127.0.0.1:8095".into());
    let token = std::env::args().nth(3);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-qr-{run}"));
    let id = format!("qr{run}");

    let phone = Engine::open(&hs, &dir.join("phone"), "s").await?;
    phone.register(&id, "Secret-pass-123", token.as_deref()).await?;
    phone.sync_once().await?;

    // The PC's QR: only sha256(secret).
    let secret = format!("{:064x}", rand_u128() ^ (run as u128));
    let r = hex(&Sha256::digest(secret.as_bytes()));

    // Before the phone vouches: nothing to take.
    let (code, _) = post(&format!("{qr}/_burumy/v1/qr/take"), serde_json::json!({"s": secret})).await?;
    if code == 200 {
        bail!("took a sign-in nobody vouched for");
    }
    // A bad OpenID token is refused.
    let (code, _) = post(&format!("{qr}/_burumy/v1/qr/claim"), serde_json::json!({"openid_token": "nope", "r": r})).await?;
    if code == 200 {
        bail!("claimed with a fake OpenID token");
    }
    let (code, body) = post(
        &format!("{qr}/_burumy/v1/qr/claim"),
        serde_json::json!({"openid_token": phone.openid_token().await?, "r": r}),
    )
    .await?;
    if code != 200 {
        bail!("claim refused {code} {body}");
    }
    println!("ok: phone vouched for the QR");

    // Someone who only photographed the QR (knows r, not the secret).
    let (code, _) = post(&format!("{qr}/_burumy/v1/qr/take"), serde_json::json!({"s": r})).await?;
    if code == 200 {
        bail!("the QR picture alone signed in");
    }
    println!("ok: the QR picture alone can't sign in");

    let (code, body) = post(&format!("{qr}/_burumy/v1/qr/take"), serde_json::json!({"s": secret})).await?;
    if code != 200 {
        bail!("take refused {code} {body}");
    }
    let jwt = serde_json::from_str::<serde_json::Value>(&body)?["token"].as_str().unwrap_or_default().to_owned();
    let pc = Engine::open(&hs, &dir.join("pc"), "s").await?;
    pc.login_token(&jwt, "Burumy Windows PC").await?;
    pc.sync_once().await?;
    let (code, _) = post(&format!("{qr}/_burumy/v1/qr/take"), serde_json::json!({"s": secret})).await?;
    if code == 200 {
        bail!("the same QR signed in twice");
    }
    println!("ok: PC signed in once with the secret; second take refused");

    phone.sync_once().await?;
    let devices = phone.devices().await?;
    let pcs: Vec<_> = devices.iter().filter(|d| d.name == "Burumy Windows PC").collect();
    if pcs.len() != 1 || devices.len() != 2 {
        bail!("phone sees {} devices", devices.len());
    }
    println!("ok: phone sees the new PC ({} devices)", devices.len());

    // Account privacy keys: set on the phone, read on the PC.
    let pc_id = pcs[0].device_id.clone();
    phone.set_privacy_value("device_idle_days", serde_json::json!(30)).await?;
    phone.set_privacy_value("no_call_devices", serde_json::json!([pc_id])).await?;
    if phone.set_privacy_value("display_name", serde_json::json!("x")).await.is_ok() {
        bail!("an unknown privacy key was accepted");
    }
    for _ in 0..10 {
        pc.sync_once().await?;
        let p = pc.privacy().await;
        if p["device_idle_days"] == 30 && p["no_call_devices"][0] == pc_id.as_str() {
            println!("ok: idle days + calls-off reached the PC");
            std::fs::remove_dir_all(&dir).ok();
            println!("ALL OK");
            return Ok(());
        }
        tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    }
    bail!("privacy keys never reached the PC: {}", pc.privacy().await)
}

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn rand_u128() -> u128 {
    std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos()
}
