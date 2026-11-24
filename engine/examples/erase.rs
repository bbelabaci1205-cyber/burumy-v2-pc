// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Delete a 1:1 chat for both, and the wrong-password wipe.
//! Usage: erase <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-erase-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("ea{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("eb{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let dm = a.create_dm(&b.user_id().unwrap()).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&dm) {
            break;
        }
    }
    b.join(&dm).await?;
    a.sync_once().await?;
    a.send_text(&dm, "지울 이야기").await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }

    // 1. b deletes the chat for both.
    b.delete_for_both(&dm).await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    let a_has = a
        .chat_list()
        .await?
        .iter()
        .any(|c| c.room_id == dm.as_str());
    let b_has = b
        .chat_list()
        .await?
        .iter()
        .any(|c| c.room_id == dm.as_str());
    let notices = a.take_erase_notices().await?;
    println!("after delete for both: a has chat {a_has}, b has chat {b_has}, a told {notices:?}");
    if a_has || b_has || notices.len() != 1 {
        bail!("delete for both failed")
    }
    if !a.take_erase_notices().await?.is_empty() {
        bail!("told twice")
    }

    // 2. Too many wrong passwords on a's phone: everything goes.
    let dm2 = a.create_dm(&b.user_id().unwrap()).await?;
    let group = a
        .create_group("팀", &[b.user_id().unwrap().to_owned()], false)
        .await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&dm2) && b.invited_rooms().contains(&group) {
            break;
        }
    }
    b.join(&dm2).await?;
    b.join(&group).await?;
    a.sync_once().await?;
    a.send_text(&dm2, "안녕").await?;
    a.send_text(&group, "모두 안녕").await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    a.erase_everything().await?;
    for _ in 0..3 {
        b.sync_once().await?;
        a.sync_once().await?;
    }
    let a_left = a.chat_list().await?.len();
    let b_dm = b
        .chat_list()
        .await?
        .iter()
        .any(|c| c.room_id == dm2.as_str());
    let b_group = b
        .chat_list()
        .await?
        .iter()
        .any(|c| c.room_id == group.as_str());
    println!(
        "after wipe: a sees {a_left} chats; b still has 1:1 {b_dm}, group {b_group} (a leaves the group quietly later)"
    );
    if a_left != 0 || b_dm || !b_group {
        bail!("wipe wrong")
    }
    // 3. Delete password on b's phone: 1:1 with a goes on both sides, quietly.
    let dm3 = b.create_dm(&a.user_id().unwrap()).await?;
    for _ in 0..40 {
        a.sync_once().await?;
        if a.invited_rooms().contains(&dm3) {
            break;
        }
    }
    a.join(&dm3).await?;
    b.sync_once().await?;
    b.send_text(&dm3, "숨길 이야기").await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    b.set_quiet_lists(vec![], vec![a.user_id().unwrap().to_string()])
        .await?;
    b.start_session(burumy_engine::lock::Role::Delete).await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    let a_has3 = a
        .chat_list()
        .await?
        .iter()
        .any(|c| c.room_id == dm3.as_str());
    let told = a.take_erase_notices().await?;
    println!("delete password: a still has chat {a_has3}, a told {told:?}");
    if a_has3 || !told.is_empty() {
        bail!("quiet delete wrong")
    }
    println!("ERASE CHECK PASSED");
    Ok(())
}
