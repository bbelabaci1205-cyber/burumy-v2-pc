// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Long post check: alice sends a short formatted message and a long post
//! with a photo into an encrypted chat; bob reads both. The long post and
//! its photo are scrambled on the server, the server copy of the card has
//! no words, and a forged card with unsafe blocks is cleaned on bob's side.
//! Usage: article <homeserver> <token>
use std::time::Duration;

use anyhow::{Result, bail, ensure};
use burumy_engine::Engine;
use serde_json::{Value, json};

async fn server_copy(e: &Engine, url: &str) -> Result<Vec<u8>> {
    let mxc: &burumy_engine::matrix_sdk::ruma::MxcUri = url.into();
    let req = burumy_engine::matrix_sdk::ruma::api::client::authenticated_media::get_content::v1::Request::from_uri(mxc)?;
    Ok(e.client().send(req).await?.file)
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-article-{run}"));
    let alice = Engine::open(&hs, &dir.join("a"), "s").await?;
    alice.register(&format!("aa{run}"), "Secret-pass-123", token.as_deref()).await?;
    let bob = Engine::open(&hs, &dir.join("b"), "s").await?;
    bob.register(&format!("ab{run}"), "Secret-pass-123", token.as_deref()).await?;
    let room = alice.create_dm(&bob.user_id().unwrap()).await?;
    for _ in 0..40 {
        bob.sync_once().await?;
        if bob.invited_rooms().contains(&room) {
            break;
        }
    }
    bob.join(&room).await?;
    alice.sync_once().await?;

    // 1. Short formatted message (heading, table, formula) inside the card.
    let short = json!({ "title": "기말고사 정리", "blocks": [
        { "t": "h2", "text": "시험 일정" },
        { "t": "table", "rows": [["월", "화"], ["복습", "시험"]] },
        { "t": "math", "tex": "a^2+b^2=c^2" },
    ]});
    let short_id = alice.send_article(&room, &short.to_string()).await?;

    // 2. Long post with a photo: photo encrypted + uploaded first.
    let photo: Vec<u8> = (0..300_000u32).map(|i| (i.wrapping_mul(2654435761) >> 24) as u8).collect();
    let file: Value = serde_json::from_str(&alice.upload_encrypted(photo.clone()).await?)?;
    let secret = "비밀 여행 계획";
    let mut blocks = vec![json!({ "t": "img", "file": file, "mime": "image/jpeg", "w": 1200, "h": 800, "caption": "바다" })];
    for i in 0..60 {
        blocks.push(json!({ "t": "p", "text": format!("{secret} 문단 {i} {}", "내용 ".repeat(80)) }));
    }
    let long = json!({ "title": "아주 긴 글", "blocks": blocks });
    let long_id = alice.send_article(&room, &long.to_string()).await?;

    // 3. A forged card straight into the room (someone's modified app).
    let forged = alice
        .client()
        .get_room(&room)
        .unwrap()
        .send_raw(
            "app.burumy.card",
            json!({ "kind": "article", "body": "x", "data": { "doc": { "title": "가짜", "blocks": [
                { "t": "script", "text": "<script>alert(1)</script>" },
                { "t": "img", "file": { "url": "https://evil.example/track.png" } },
                { "t": "p", "text": "괜찮은 글" },
            ]}}}),
        )
        .await?
        .response
        .event_id
        .to_string();

    // Bob reads.
    let mut msgs = vec![];
    for _ in 0..40 {
        bob.sync_once().await?;
        msgs = bob.messages(&room, 50).await?;
        if [&short_id, &long_id, &forged].iter().all(|id| msgs.iter().any(|m| &&m.event_id == id)) {
            break;
        }
        tokio::time::sleep(Duration::from_millis(250)).await;
    }
    let get = |id: &str| msgs.iter().find(|m| m.event_id == id).cloned();
    let s = get(&short_id).ok_or_else(|| anyhow::anyhow!("bob has no short post"))?;
    let sc = s.card.clone().ok_or_else(|| anyhow::anyhow!("short post is not a card"))?;
    ensure!(s.was_encrypted && sc.kind == "article", "short post not encrypted article");
    let sd: Value = serde_json::from_str(&sc.data)?;
    ensure!(sd["doc"]["blocks"][1]["rows"][1][1] == "시험", "table cell");
    ensure!(sd["doc"]["blocks"][2]["tex"] == "a^2+b^2=c^2", "formula");
    println!("short post: bob reads title + table + formula inside the encrypted message: OK");

    let l = get(&long_id).ok_or_else(|| anyhow::anyhow!("bob has no long post"))?;
    let lc = l.card.clone().unwrap();
    let ld: Value = serde_json::from_str(&lc.data)?;
    ensure!(ld.get("doc").is_none() && ld["file"]["url"].is_string(), "long post should travel as a file");
    ensure!(ld["preview"]["blocks"].as_array().unwrap().len() <= 6, "preview is short");
    ensure!(!ld["preview"].to_string().contains("문단 59"), "preview must not hold the whole post");
    println!("long post: card has file key + short preview only ({} chars, {} bytes): OK", ld["chars"], ld["size"]);
    let full: Value = serde_json::from_str(&bob.open_article(&room, &long_id).await?)?;
    let fb = full["blocks"].as_array().unwrap();
    ensure!(fb.len() == 61, "bob got {} blocks", fb.len());
    ensure!(fb[60]["text"].as_str().unwrap().starts_with(&format!("{secret} 문단 59")), "last paragraph");
    println!("long post: bob opened all 61 blocks: OK");
    let img = bob.download_encrypted(&fb[0]["file"].to_string()).await?;
    ensure!(img == photo, "photo differs");
    println!("photo: bob decrypted it, same bytes: OK");

    // What the server keeps.
    let doc_blob = server_copy(&bob, ld["file"]["url"].as_str().unwrap()).await?;
    if String::from_utf8_lossy(&doc_blob).contains(secret) || doc_blob.windows(secret.len()).any(|w| w == secret.as_bytes()) {
        bail!("server can read the long post");
    }
    let img_blob = server_copy(&bob, fb[0]["file"]["url"].as_str().unwrap()).await?;
    ensure!(img_blob != photo, "server can read the photo");
    println!("server copies of the post and the photo are scrambled: OK");
    ensure!(l.was_encrypted, "card must be end-to-end encrypted");

    let f = get(&forged).ok_or_else(|| anyhow::anyhow!("bob has no forged card"))?;
    let fd: Value = serde_json::from_str(&f.card.unwrap().data)?;
    let kinds: Vec<&str> = fd["doc"]["blocks"].as_array().unwrap().iter().map(|b| b["t"].as_str().unwrap()).collect();
    ensure!(kinds == ["p"], "forged blocks left: {kinds:?}");
    println!("forged card: script block and web-tracking photo dropped on bob's phone: OK");
    println!("ARTICLE CHECK PASSED");
    Ok(())
}
