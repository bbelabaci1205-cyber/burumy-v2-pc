// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 가입 심사 도우미 end to end, on a real server with server/gate running:
//! the owner writes questions and switches the helper on; one person
//! answers right and is let in within seconds; one answers wrong and is
//! turned down; one writes a blocked word; the log shows all three; the
//! helper has no encryption devices.
//! Usage: gate <hs> <registration token>
#![recursion_limit = "256"]
use std::time::Duration;

use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-gate-{run}"));
    let mk = |n: &str| {
        let d = dir.join(n);
        let hs = hs.clone();
        let token = token.clone();
        let id = format!("g{n}{run}");
        async move {
            let e = Engine::open(&hs, &d, "s").await?;
            e.register(&id, "Secret-pass-123", token.as_deref()).await?;
            e.sync_once().await?;
            Ok::<_, anyhow::Error>(e)
        }
    };
    let owner = mk("owner").await?;
    let good = mk("good").await?;
    let bad = mk("bad").await?;
    let spam = mk("spam").await?;

    let room = owner.create_group("음악 만드는 사람들", &[], false).await?;
    owner.sync_once().await?;
    let addr = format!("music{run}");
    owner.set_public_link(&room, &addr).await?;
    owner.set_link_approval(&room, true).await?;
    owner
        .set_room_config(
            &room,
            "join_questions",
            r#"[{"q":"BPM은 무엇을 나타낼까요?","choices":["곡의 빠르기","곡의 길이"],"right":0},"어떤 음악을 만들어요?"]"#,
        )
        .await?;
    // Each write reads the config first: let the first one arrive.
    owner.sync_once().await?;
    owner.set_room_config(&room, "gate", r#"{"on":true,"need_answers":true,"words":["코인"]}"#).await?;
    owner.sync_once().await?;
    owner.set_gate_helper(&room, true).await?;
    // The helper comes in by itself.
    let mut joined = false;
    for _ in 0..30 {
        owner.sync_once().await?;
        if owner.gate_helper_state(&room).await?.0 {
            joined = true;
            break;
        }
        tokio::time::sleep(Duration::from_millis(500)).await;
    }
    if !joined {
        bail!("helper did not come in")
    }
    let (_, devices) = owner.gate_helper_state(&room).await?;
    println!("helper in, encryption devices: {devices}");
    if devices != 0 {
        bail!("helper must have no encryption devices")
    }
    owner.send_text(&room, "그룹 안 비밀 이야기").await?;

    async fn ask(e: &Engine, addr: &str, answers: &[&str]) -> Result<String> {
        let a: Vec<String> = answers.iter().map(|s| s.to_string()).collect();
        let (rid, asked) = e.join_link_with("public", addr, &a).await?;
        if !asked {
            bail!("approval is on: should only ask")
        }
        let rid = matrix_sdk::ruma::RoomId::parse(rid)?;
        let started = std::time::Instant::now();
        for _ in 0..40 {
            e.sync_once().await?;
            let s = e.knock_state(&rid).await?;
            if s != "waiting" {
                println!("  answered in {:.1}s: {s}", started.elapsed().as_secs_f32());
                return Ok(s);
            }
            tokio::time::sleep(Duration::from_millis(300)).await;
        }
        Ok("waiting".into())
    }
    println!("right answers:");
    if ask(&good, &addr, &["0", "집에서 로파이 비트를 만들어요"]).await? != "in" {
        bail!("right answers should be let in")
    }
    println!("wrong quiz answer:");
    if ask(&bad, &addr, &["1", "아무거나"]).await? != "no" {
        bail!("wrong answer should be turned down")
    }
    println!("blocked word:");
    if ask(&spam, &addr, &["0", "코인 무료로 드려요"]).await? != "no" {
        bail!("blocked word should be turned down")
    }
    owner.sync_once().await?;
    let log = owner.gate_log(&room).await;
    println!("log: {log}");
    let v: serde_json::Value = serde_json::from_str(&log)?;
    let verdicts: Vec<&str> = v["e"].as_array().map(|a| a.iter().filter_map(|x| x["v"].as_str()).collect()).unwrap_or_default();
    if verdicts != ["ok", "quiz", "words"] {
        bail!("log wrong: {verdicts:?}")
    }
    // Admin view of requests still works (nobody left waiting).
    if !owner.join_requests(&room).await?.is_empty() {
        bail!("no request should be left")
    }
    if std::env::var("GATE_KEEP").is_ok() {
        println!("KEEP room={room} addr={addr}");
        return Ok(());
    }
    // Off: the helper is taken out.
    owner.set_room_config(&room, "gate", r#"{"on":false}"#).await?;
    owner.set_gate_helper(&room, false).await?;
    for _ in 0..10 {
        owner.sync_once().await?;
        if !owner.gate_helper_state(&room).await?.0 {
            println!("GATE PASS (room {room})");
            return Ok(());
        }
        tokio::time::sleep(Duration::from_millis(300)).await;
    }
    bail!("helper still in after off")
}
