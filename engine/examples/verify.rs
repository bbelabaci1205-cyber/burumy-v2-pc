// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
#![recursion_limit = "512"]
//! Feasibility proof: sign-up, E2E 1:1 chat both ways, 대화 복구 키 on a new
//! device, and an emoji check between two people.
//! Usage: proof <homeserver-url> [registration-token]

use std::{future::Future, time::Duration};

use anyhow::{Result, bail};
use burumy_engine::Engine;
use matrix_sdk::ruma::OwnedRoomId;

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
    let pw = "Secret-pass-123";
    let alice = Engine::open(&hs, &dir.join("va"), "store-pass-a").await?;
    alice
        .register(&format!("valice{run}"), pw, token.as_deref())
        .await?;
    let bob = Engine::open(&hs, &dir.join("vb"), "store-pass-b").await?;
    bob.register(&format!("vbob{run}"), pw, token.as_deref())
        .await?;
    let (a_id, b_id) = (alice.user_id().unwrap(), bob.user_id().unwrap());
    let room: OwnedRoomId = alice.create_dm(&b_id).await?;
    let r = room.clone();
    wait_for("bob sees the invite", &[&bob], || {
        let b = bob.clone();
        let r = r.clone();
        async move { Ok(b.invited_rooms().contains(&r)) }
    })
    .await?;
    bob.join(&room).await?;
    alice.send_text(&room, "hi").await?;
    wait_for("both synced", &[&alice, &bob], || async { Ok(true) }).await?;

    println!("1) alice asks (the 암호화 page's 확인 시작)");
    let flow = alice.request_user_verification(&b_id).await?;
    println!("  flow {flow}");
    let st = |e: Engine, u: matrix_sdk::ruma::OwnedUserId, f: String, want: &'static str| async move {
        let s = e.verify_state(&u, &f).await?;
        if s != want && std::env::var("VDEBUG").is_ok() {
            println!("    ({want}? now {s})");
        }
        Ok(s == want)
    };
    println!("2) bob's chat shows the request card (kind verify, id = flow)");
    let (r, f) = (room.clone(), flow.clone());
    wait_for("request card in bob's timeline", &[&bob, &alice], || {
        let b = bob.clone();
        let (r, f) = (r.clone(), f.clone());
        async move {
            Ok(b.timeline(&r, 50)
                .await?
                .iter()
                .any(|m| m.kind == "verify" && m.event_id == f && !m.mine))
        }
    })
    .await?;
    wait_for("bob: incoming", &[&bob], || {
        st(bob.clone(), a_id.clone(), flow.clone(), "incoming")
    })
    .await?;
    wait_for("alice: waiting", &[&alice], || {
        st(alice.clone(), b_id.clone(), flow.clone(), "waiting")
    })
    .await?;
    println!("3) bob accepts; alice's page starts the emoji step by itself");
    bob.accept_verification(&a_id, &flow).await?;
    // Both pages poll at the same time (bob's page accepts the emoji step).
    wait_for("alice: emoji", &[&alice, &bob], || {
        let (a, b, a2, b2, f) = (
            alice.clone(),
            bob.clone(),
            a_id.clone(),
            b_id.clone(),
            flow.clone(),
        );
        async move {
            let _ = b.verify_state(&a2, &f).await?;
            Ok(a.verify_state(&b2, &f).await? == "emoji")
        }
    })
    .await?;
    wait_for("bob: emoji", &[&bob, &alice], || {
        st(bob.clone(), a_id.clone(), flow.clone(), "emoji")
    })
    .await?;
    let ea = alice.sas_emoji(&b_id, &flow).await?.unwrap();
    let eb = bob.sas_emoji(&a_id, &flow).await?.unwrap();
    println!("  alice {ea:?}\n  bob   {eb:?}");
    if ea != eb || ea.len() != 7 {
        bail!("emoji differ");
    }
    println!("4) both say they match");
    alice.confirm_sas(&b_id, &flow).await?;
    wait_for("alice: confirmed", &[&alice], || {
        st(alice.clone(), b_id.clone(), flow.clone(), "confirmed")
    })
    .await?;
    bob.confirm_sas(&a_id, &flow).await?;
    wait_for("alice: done", &[&alice, &bob], || {
        st(alice.clone(), b_id.clone(), flow.clone(), "done")
    })
    .await?;
    wait_for("bob: done", &[&bob, &alice], || {
        st(bob.clone(), a_id.clone(), flow.clone(), "done")
    })
    .await?;
    wait_for("both trusted", &[&alice, &bob], || {
        let (a, b, a2, b2) = (alice.clone(), bob.clone(), a_id.clone(), b_id.clone());
        async move { Ok(a.is_user_verified(&b2).await? && b.is_user_verified(&a2).await?) }
    })
    .await?;
    let keys = alice.peer_devices(&b_id).await?;
    println!(
        "  bob's devices seen by alice: {}",
        keys.iter()
            .map(|d| format!(
                "{} verified={} key={}…",
                d.device_id,
                d.verified,
                &d.key[..8]
            ))
            .collect::<Vec<_>>()
            .join(", ")
    );
    if keys.is_empty() || !keys.iter().all(|d| d.verified) {
        bail!("device keys not verified");
    }

    println!("5) a second check, cancelled with 달라요");
    let flow2 = alice.request_user_verification(&b_id).await?;
    wait_for("bob: incoming 2", &[&bob, &alice], || {
        st(bob.clone(), a_id.clone(), flow2.clone(), "incoming")
    })
    .await?;
    // Alice's page keeps polling too (it starts the emoji step).
    bob.accept_verification(&a_id, &flow2).await?;
    let _ = alice.verify_state(&b_id, &flow2).await;
    wait_for("bob: emoji 2", &[&bob, &alice], || {
        let (a, b, a2, b2, f) = (
            alice.clone(),
            bob.clone(),
            a_id.clone(),
            b_id.clone(),
            flow2.clone(),
        );
        async move {
            let _ = a.verify_state(&b2, &f).await?;
            Ok(b.verify_state(&a2, &f).await? == "emoji")
        }
    })
    .await?;
    bob.cancel_verification(&a_id, &flow2).await?;
    wait_for("alice: cancelled", &[&alice, &bob], || {
        st(alice.clone(), b_id.clone(), flow2.clone(), "cancelled")
    })
    .await?;
    println!("6) bob reports the request message to the operators");
    bob.report_message(&room, &flow, "스팸", "신고 시험")
        .await?;
    println!("  ok: reported");
    println!("7) a reply inside a thread");
    let root = alice.send_text(&room, "스레드 시작").await?;
    let reply = alice.reply_in_thread(&room, &root, "스레드 답").await?;
    let (r2, root2, reply2) = (room.clone(), root.clone(), reply.clone());
    wait_for("bob sees the reply in the thread", &[&bob, &alice], || {
        let b = bob.clone();
        let (r, ro, re) = (r2.clone(), root2.clone(), reply2.clone());
        async move {
            Ok(b.timeline(&r, 50)
                .await?
                .iter()
                .any(|m| m.event_id == re && m.thread_root.as_deref() == Some(ro.as_str())))
        }
    })
    .await?;
    println!("8) a story: bob sees it in the story row, not in the chat");
    // 1x1 PNG.
    let png = vec![
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0, 0, 0, 0x0d, 0x49, 0x48, 0x44, 0x52, 0,
        0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 0x1f, 0x15, 0xc4, 0x89, 0, 0, 0, 0x0a, 0x49, 0x44,
        0x41, 0x54, 0x78, 0x9c, 0x63, 0, 1, 0, 0, 5, 0, 1, 0x0d, 0x0a, 0x2d, 0xb4, 0, 0, 0, 0,
        0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
    ];
    let n = alice
        .post_story(
            "image/png",
            png.clone(),
            "첫 스토리",
            &[],
            24,
            r#"{"items":[{"kind":"poll","q":"어때요?","options":["좋아요","별로"]}]}"#,
        )
        .await?;
    anyhow::ensure!(n >= 1, "story went to nobody");
    wait_for("bob sees alice's story", &[&bob, &alice], || {
        let b = bob.clone();
        async move {
            Ok(b.stories()
                .await?
                .iter()
                .any(|x| !x.mine && x.caption.as_deref() == Some("첫 스토리")))
        }
    })
    .await?;
    let st = bob.stories().await?.into_iter().find(|x| !x.mine).unwrap();
    let (_, bytes, enc) = bob.download_file(&room, &st.event_id).await?;
    anyhow::ensure!(
        bytes == png && enc,
        "story photo should come back the same, and be encrypted on the server"
    );
    anyhow::ensure!(
        !bob.timeline(&room, 50)
            .await?
            .iter()
            .any(|m| m.event_id == st.event_id),
        "a story must not show inside the chat"
    );
    anyhow::ensure!(
        alice.stories().await?.iter().filter(|x| x.mine).count() == 1,
        "my story once"
    );
    anyhow::ensure!(
        st.extra.as_deref().is_some_and(|x| x.contains("poll")),
        "the poll goes with the story"
    );
    // Only chosen friends: a chat that is not mine gets nothing.
    anyhow::ensure!(
        alice
            .post_story(
                "image/png",
                png.clone(),
                "",
                &["!nobody:x".to_owned()],
                6,
                ""
            )
            .await
            .is_err(),
        "a story for no chosen friend must not go out"
    );
    let n = alice
        .post_story(
            "image/png",
            png.clone(),
            "골라서",
            &[room.to_string()],
            6,
            "",
        )
        .await?;
    anyhow::ensure!(n == 1, "only the chosen chat");
    println!("  ok: story (encrypted, 24 h, not in the chat, poll, chosen friends, 6 h)");

    println!("9) friend feed: words-only post, a like only the poster counts, delete");
    alice
        .post_story("", vec![], "피드 첫 글", &[], 0, "")
        .await?;
    wait_for("bob sees the feed post", &[&bob, &alice], || {
        let b = bob.clone();
        async move {
            Ok(b.stories()
                .await?
                .iter()
                .any(|x| x.feed && x.kind == "text" && x.caption.as_deref() == Some("피드 첫 글")))
        }
    })
    .await?;
    let post = bob
        .stories()
        .await?
        .into_iter()
        .find(|x| x.feed && !x.mine)
        .unwrap();
    anyhow::ensure!(
        !bob.timeline(&room, 50)
            .await?
            .iter()
            .any(|m| m.event_id == post.event_id || m.body.as_deref() == Some("피드 첫 글")),
        "a feed post must not show inside the chat"
    );
    bob.feed_like(&room, &post.story_id, true).await?;
    wait_for("alice counts bob's like", &[&bob, &alice], || {
        let a = alice.clone();
        let id = post.story_id.clone();
        async move {
            Ok(a.feed_likes()
                .await?
                .iter()
                .any(|k| k.post_id == id && !k.mine))
        }
    })
    .await?;
    anyhow::ensure!(
        !bob.timeline(&room, 50).await?.iter().any(|m| m
            .body
            .as_deref()
            .is_some_and(|b| b.contains(&post.story_id))),
        "a like must not show inside the chat"
    );
    bob.feed_like(&room, &post.story_id, false).await?;
    wait_for("the like is taken back", &[&bob, &alice], || {
        let a = alice.clone();
        let id = post.story_id.clone();
        async move { Ok(!a.feed_likes().await?.iter().any(|k| k.post_id == id)) }
    })
    .await?;
    let n = alice.delete_story(&post.story_id).await?;
    anyhow::ensure!(n >= 1, "my post should be deleted");
    wait_for("the post is gone for bob", &[&bob, &alice], || {
        let b = bob.clone();
        let id = post.story_id.clone();
        async move { Ok(!b.stories().await?.iter().any(|x| x.story_id == id)) }
    })
    .await?;
    println!("  ok: feed (encrypted, not in the chat, private like + take back, delete)");
    println!("ALL OK");
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
