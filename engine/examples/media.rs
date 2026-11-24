// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Photo / file check: alice sends files into an encrypted 1:1 chat, bob
//! downloads and opens them, and the copy on the server is scrambled.
//! Usage: media <homeserver> <token>
use std::time::{Duration, Instant};

use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-media-{run}"));
    let alice = Engine::open(&hs, &dir.join("a"), "s").await?;
    alice
        .register(&format!("ma{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let bob = Engine::open(&hs, &dir.join("b"), "s").await?;
    bob.register(&format!("mb{run}"), "Secret-pass-123", token.as_deref())
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

    for (name, mime, size) in [
        ("photo.jpg", "image/jpeg", 3_000_000usize),
        ("video.mp4", "video/mp4", 50_000_000),
    ] {
        // Random bytes stand in for a real photo/video.
        let data: Vec<u8> = (0..size)
            .map(|i| {
                ((i as u64)
                    .wrapping_mul(6364136223846793005)
                    .wrapping_add(run as u64)
                    >> 33) as u8
            })
            .collect();
        let t = Instant::now();
        let ev = alice.send_file(&room, name, mime, data.clone()).await?;
        let up = t.elapsed();
        let mut got = None;
        for _ in 0..40 {
            bob.sync_once().await?;
            if let Ok(x) = bob.download_file(&room, &ev).await {
                got = Some(x);
                break;
            }
            tokio::time::sleep(Duration::from_millis(250)).await;
        }
        let (n, bytes, encrypted) =
            got.ok_or_else(|| anyhow::anyhow!("bob could not get {name}"))?;
        if bytes != data {
            bail!("{name}: bob's copy differs");
        }
        // What the server keeps: download the raw blob without the key.
        let ev_full = bob
            .client()
            .get_room(&room)
            .unwrap()
            .event(ev.as_str().try_into()?, None)
            .await?;
        let raw = ev_full.raw().json().get().to_owned();
        let url = raw
            .split("\"url\":\"")
            .nth(1)
            .and_then(|s| s.split('"').next())
            .unwrap_or_default()
            .to_owned();
        eprintln!("bob got {name}, checking server copy {url}");
        let mxc: &burumy_engine::matrix_sdk::ruma::MxcUri = url.as_str().into();
        let req = burumy_engine::matrix_sdk::ruma::api::client::authenticated_media::get_content::v1::Request::from_uri(mxc)?;
        let blob = bob.client().send(req).await?.file;
        let same = blob.len() == data.len() && blob == data;
        println!(
            "{n}: {} MB, upload {:.1}s, bob opened it: yes, encrypted file: {encrypted}, server copy readable: {same}",
            size / 1_000_000,
            up.as_secs_f32()
        );
        if !encrypted || same {
            bail!("{name} is not encrypted on the server");
        }
    }
    println!("MEDIA CHECK PASSED");
    Ok(())
}
