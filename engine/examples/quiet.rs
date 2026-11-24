// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Hide / delete password behaviour against a real server.
//! Usage: quiet <homeserver> <token>
use anyhow::{Result, bail};
use burumy_engine::{Engine, lock::Role};

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-quiet-{run}"));
    let me = Engine::open(&hs, &dir.join("me"), "s").await?;
    me.register(&format!("qm{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let mut friends = Vec::new();
    for n in ["h", "d", "k"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("q{n}{run}"), "Secret-pass-123", token.as_deref())
            .await?;
        friends.push(e);
    }
    let (hid, del, keep) = (&friends[0], &friends[1], &friends[2]);
    let mut dms = Vec::new();
    for f in &friends {
        let r = me.create_dm(&f.user_id().unwrap()).await?;
        for _ in 0..40 {
            f.sync_once().await?;
            if f.invited_rooms().contains(&r) {
                break;
            }
        }
        f.join(&r).await?;
        dms.push(r);
    }
    let group = me
        .create_group("지울 그룹", &[keep.user_id().unwrap()], false)
        .await?;
    for _ in 0..40 {
        keep.sync_once().await?;
        if keep.invited_rooms().contains(&group) {
            break;
        }
    }
    keep.join(&group).await?;
    for _ in 0..3 {
        me.sync_once().await?;
    }
    for (i, r) in dms.iter().enumerate() {
        me.send_text(r, &format!("안녕 {i}")).await?;
    }
    me.send_text(&group, "그룹 글").await?;
    for _ in 0..3 {
        me.sync_once().await?;
    }

    let names = |l: &Vec<burumy_engine::ChatSummary>| {
        l.iter().map(|c| c.room_id.clone()).collect::<Vec<_>>()
    };
    let all = names(&me.chat_list().await?);
    println!("before: {} chats", all.len());
    if all.len() != 4 {
        bail!("expected 4 chats")
    }

    me.set_quiet_lists(
        vec![hid.user_id().unwrap().to_string()],
        vec![del.user_id().unwrap().to_string(), group.to_string()],
    )
    .await?;

    // Hide session: hidden person still visible here, hiding switches on.
    me.start_session(Role::Hide).await?;
    let in_hide = names(&me.chat_list().await?);
    println!("hide session: {} chats", in_hide.len());
    if in_hide.len() != 4 {
        bail!("hide session should still show all")
    }
    // Later normal session: hidden person gone, also from contacts.
    me.start_session(Role::Normal).await?;
    let normal = names(&me.chat_list().await?);
    let contacts = me.contacts().await?;
    println!(
        "normal after hide: {} chats, {} contacts",
        normal.len(),
        contacts.len()
    );
    if normal.contains(&dms[0].to_string())
        || contacts
            .iter()
            .any(|p| Some(p.user_id.as_str()) == hid.user_id().as_ref().map(|u| u.as_str()))
    {
        bail!("hidden person visible")
    }
    if !me.timeline(&dms[0], 10).await?.is_empty() {
        bail!("hidden chat readable")
    }

    // A stranger writes while hiding is on: kept quietly, seen only in a hide session.
    let stranger = Engine::open(&hs, &dir.join("s"), "s").await?;
    stranger
        .register(&format!("qs{run}"), "Secret-pass-123", token.as_deref())
        .await?;
    let sroom = stranger.create_dm(&me.user_id().unwrap()).await?;
    for _ in 0..40 {
        me.sync_once().await?;
        if me.invited_rooms().contains(&sroom) {
            break;
        }
    }
    let shown_normal = me.visible_invites().await.contains(&sroom);
    me.start_session(Role::Hide).await?;
    let shown_hide = me.visible_invites().await.contains(&sroom);
    me.start_session(Role::Normal).await?;
    println!("stranger's invitation: normal session {shown_normal}, hide session {shown_hide}");
    if shown_normal || !shown_hide {
        bail!("stranger not kept quietly")
    }

    // Delete session: erased from this phone; 1:1 left now, group later.
    me.start_session(Role::Delete).await?;
    for _ in 0..3 {
        me.sync_once().await?;
    }
    let after = names(&me.chat_list().await?);
    let q = me.quiet_state().await?;
    println!(
        "delete session: {} chats; erased {}; group leaves in {:.1} days",
        after.len(),
        q.erased.len(),
        q.leave_at
            .values()
            .next()
            .map(|t| (*t as f64
                - std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_millis() as f64)
                / 86_400_000.0)
            .unwrap_or(-1.0)
    );
    if after.contains(&dms[1].to_string()) || after.contains(&group.to_string()) {
        bail!("deleted chats visible")
    }
    if !after.contains(&dms[2].to_string()) {
        bail!("kept chat missing")
    }
    if !q.leave_at.contains_key(group.as_str()) {
        bail!("group leave not planned")
    }
    // The deleted friend sees that I left the 1:1; the group sees nothing yet.
    for _ in 0..5 {
        keep.sync_once().await?;
    }
    let members_before = keep
        .client()
        .get_room(&group)
        .unwrap()
        .joined_members_count();
    println!("group members seen by friend now: {members_before}");
    if members_before != 2 {
        bail!("group leave happened too early")
    }
    me.leave_now_for_test().await?;
    let left = me.run_due_leaves().await?;
    let again = me.run_due_leaves().await?;
    println!("due leave: {left:?}, second run: {again:?}");
    if left.as_deref() != Some(group.as_str()) || again.is_some() {
        bail!("leave schedule wrong")
    }

    // Releasing hidden people works only inside a hide session.
    if me.release_hidden().await.is_ok() {
        bail!("release allowed outside hide session")
    }
    me.start_session(Role::Hide).await?;
    me.release_hidden().await?;
    me.start_session(Role::Normal).await?;
    if !names(&me.chat_list().await?).contains(&dms[0].to_string()) {
        bail!("release failed")
    }
    println!("QUIET CHECK PASSED");
    Ok(())
}
