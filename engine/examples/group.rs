// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Group / channel check: one owner, N members, encrypted room. Measures how
//! long the first and the next encrypted post take, and whether every
//! member can open them. Usage: group <homeserver> <token> <members> [channel]
use std::time::{Duration, Instant};

use anyhow::{Result, bail};
use burumy_engine::{
    Engine,
    matrix_sdk::ruma::{
        OwnedRoomId,
        api::client::room::create_room::v3::Request as CreateRoom,
        events::{InitialStateEvent, room::encryption::RoomEncryptionEventContent},
        serde::Raw,
    },
};
use futures_util::future::join_all;

#[tokio::main]
async fn main() -> Result<()> {
    let a: Vec<String> = std::env::args().collect();
    let hs = a.get(1).cloned().unwrap_or("http://127.0.0.1:6167".into());
    let token = a.get(2).cloned();
    let n: usize = a.get(3).and_then(|s| s.parse().ok()).unwrap_or(20);
    let channel = a.get(4).map(|s| s == "channel").unwrap_or(false);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-group-{run}"));
    let pw = "Secret-pass-123";

    let t = Instant::now();
    let owner = Engine::open(&hs, &dir.join("owner"), "s").await?;
    owner
        .register(&format!("own{run}"), pw, token.as_deref())
        .await?;
    let members = join_all((0..n).map(|i| {
        let (hs, dir, token) = (hs.clone(), dir.clone(), token.clone());
        async move {
            let e = Engine::open(&hs, &dir.join(format!("m{i}")), "s").await?;
            e.register(&format!("m{i}x{run}"), pw, token.as_deref())
                .await?;
            anyhow::Ok(e)
        }
    }))
    .await
    .into_iter()
    .collect::<Result<Vec<_>>>()?;
    println!("{n} members signed up in {:.1}s", t.elapsed().as_secs_f32());

    let mut req = CreateRoom::new();
    req.name = Some(
        if channel {
            "test channel"
        } else {
            "test group"
        }
        .into(),
    );
    req.invite = members.iter().map(|m| m.user_id().unwrap()).collect();
    let state = vec![
        Raw::new(&InitialStateEvent::new(
            Default::default(),
            RoomEncryptionEventContent::with_recommended_defaults(),
        ))?
        .cast(),
    ];
    if channel {
        // Channel: only the owner may post.
        // Room version 12: the creator is always the top admin and must not
        // be listed in "users".
        req.power_level_content_override = Some(Raw::from_json_string(
            r#"{"events_default":100}"#.to_owned(),
        )?);
    }
    req.initial_state = state;
    let room: OwnedRoomId = owner.client().create_room(req).await?.room_id().to_owned();

    let t = Instant::now();
    join_all(members.iter().map(|m| {
        let r = room.clone();
        async move {
            for _ in 0..40 {
                m.sync_once().await?;
                if m.invited_rooms().contains(&r) {
                    return m.join(&r).await;
                }
            }
            bail!("no invite")
        }
    }))
    .await
    .into_iter()
    .collect::<Result<Vec<_>>>()?;
    println!("all joined in {:.1}s", t.elapsed().as_secs_f32());
    owner.sync_once().await?;

    for (k, text) in ["첫 글 (키 나눠 주기 포함)", "두 번째 글"]
        .iter()
        .enumerate()
    {
        let t = Instant::now();
        owner.send_text(&room, text).await?;
        let sent = t.elapsed();
        let opened = join_all(members.iter().map(|m| {
            let r = room.clone();
            async move {
                for _ in 0..60 {
                    m.sync_once().await.ok();
                    if let Ok(msgs) = m.messages(&r, 10).await {
                        if msgs
                            .iter()
                            .any(|x| x.was_encrypted && x.body.as_deref() == Some(*text))
                        {
                            return true;
                        }
                    }
                    tokio::time::sleep(Duration::from_millis(200)).await;
                }
                false
            }
        }))
        .await;
        let ok = opened.iter().filter(|x| **x).count();
        println!(
            "post {}: send {:.2}s, {ok}/{n} members opened it, all done {:.1}s",
            k + 1,
            sent.as_secs_f32(),
            t.elapsed().as_secs_f32()
        );
        if ok != n {
            bail!("not everyone could open post {}", k + 1);
        }
    }
    if channel {
        match members[0].send_text(&room, "구독자 글").await {
            Ok(_) => bail!("a subscriber could post in a channel"),
            Err(e) => println!("subscriber post refused: {e}"),
        }
    }
    println!(
        "GROUP CHECK PASSED ({})",
        if channel { "channel" } else { "group" }
    );
    Ok(())
}
