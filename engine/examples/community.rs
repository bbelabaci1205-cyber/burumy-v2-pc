// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 커뮤니티 on a real server: make one, add a group (members are brought in
//! by the admin phone and get the key), the line in the group, an approval
//! chat (ask + accept), a hidden chat (members can't see it, a new admin
//! can), "admins only" enforced by the server, and that the server's copy
//! holds no room ids or names. Then delete: members' phones leave.
//! Usage: community <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::{Engine, community::Community};

async fn find(e: &Engine, id: &str) -> Option<Community> {
    e.communities().await.into_iter().find(|c| c.id == id)
}

async fn settle(list: &[&Engine]) -> Result<()> {
    for _ in 0..3 {
        for e in list {
            e.sync_once().await?;
        }
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-community-{run}"));
    let mk = |n: &str| {
        let d = dir.join(n);
        let hs = hs.clone();
        let token = token.clone();
        let id = format!("cm{n}{run}");
        async move {
            let e = Engine::open(&hs, &d, "s").await?;
            e.register(&id, "Secret-pass-123", token.as_deref()).await?;
            e.sync_once().await?;
            Ok::<_, anyhow::Error>(e)
        }
    };
    let a = mk("a").await?; // owner
    let b = mk("b").await?; // member of the football group
    let c = mk("c").await?; // a stranger
    let bid = b.user_id().unwrap();

    // a's football group with b in it.
    let g = a.create_group("일요 축구회", &[bid.clone()], false).await?;
    settle(&[&a, &b]).await?;
    b.join(&g).await?;
    settle(&[&a, &b]).await?;

    // 1. a makes the community and adds the group.
    let cid = a.create_community("우리 동네 운동", "동네 운동 모임을 한곳에").await?;
    a.sync_once().await?;
    a.add_to_community(&cid, &g, false).await?;
    a.sync_once().await?;
    let mine = find(&a, cid.as_str()).await.expect("owner sees it");
    println!("owner: {} role={} chats={}", mine.name, mine.role, mine.chats.len());
    if mine.role != "owner" || mine.chats.len() != 1 || mine.chats[0].state != "in" {
        bail!("owner view wrong")
    }
    // Not a chat in the chat list.
    if a.chat_list().await?.iter().any(|x| x.room_id == cid.as_str()) {
        bail!("community shows as a chat")
    }

    // 2. b is brought in by a's phone (invite + key) and joins on its own.
    let mut got = None;
    for _ in 0..12 {
        a.sync_once().await?;
        b.sync_once().await?;
        if let Some(x) = find(&b, cid.as_str()).await {
            got = Some(x);
            break;
        }
    }
    if got.is_none() {
        println!("debug: b invited={:?} key={:?} is_comm={}", b.invited_rooms(), b.community_keys(&cid).await.map(|k| k.from), b.is_community(&cid).await);
        println!("debug: a members of community: {:?}", a.members(&cid).await.ok().map(|m| m.len()));
    }
    let seen = got.expect("b never got the community");
    println!("b sees: {} role={} chats={:?}", seen.name, seen.role, seen.chats.iter().map(|x| (&x.name, &x.state)).collect::<Vec<_>>());
    if seen.role != "member" || seen.chats.len() != 1 || seen.chats[0].state != "in" {
        bail!("member view wrong")
    }
    // The line in the group.
    let tl = b.timeline(&g, 30).await?;
    if !tl.iter().any(|m| m.card.as_ref().is_some_and(|k| k.kind == "community" && k.data.contains("우리 동네 운동"))) {
        bail!("no community line in the group")
    }
    println!("line in the group ok");

    // 3. A second group without a link: added with a private approval link;
    //    b asks through the community and a lets b in.
    let g2 = a.create_group("새벽 러닝", &[], false).await?;
    a.sync_once().await?;
    a.add_to_community(&cid, &g2, false).await?;
    settle(&[&a, &b]).await?;
    let x = find(&b, cid.as_str()).await.unwrap();
    let run_chat = x.chats.iter().find(|x| x.room_id == g2.as_str()).expect("b sees 새벽 러닝");
    if run_chat.state != "ask" {
        bail!("approval chat should be 'ask', got {}", run_chat.state)
    }
    let (rid, asked) = b.join_community_chat(&cid, g2.as_str()).await?;
    if rid != g2.as_str() || !asked {
        bail!("should only ask")
    }
    let mut ok = false;
    for _ in 0..10 {
        a.sync_once().await?;
        if a.join_requests(&g2).await?.iter().any(|(u, _)| *u == bid.as_str()) {
            ok = true;
            break;
        }
    }
    if !ok {
        bail!("request not seen")
    }
    a.answer_join_request(&g2, bid.as_str(), true).await?;
    for _ in 0..10 {
        b.sync_once().await?;
        if b.invited_rooms().iter().any(|r| *r == g2) {
            break;
        }
    }
    b.join(&g2).await?;
    settle(&[&a, &b]).await?;
    if find(&b, cid.as_str()).await.unwrap().chats.iter().find(|x| x.room_id == g2.as_str()).unwrap().state != "in" {
        bail!("b should be in 새벽 러닝 now")
    }
    println!("ask + accept ok");

    // 4. Hidden chat: b (member) can't see it.
    let staff = a.create_group("운영진", &[], false).await?;
    a.sync_once().await?;
    a.add_to_community(&cid, &staff, true).await?;
    settle(&[&a, &b]).await?;
    if !find(&a, cid.as_str()).await.unwrap().chats.iter().any(|x| x.room_id == staff.as_str() && x.hidden) {
        bail!("owner should see the hidden chat")
    }
    if find(&b, cid.as_str()).await.unwrap().chats.iter().any(|x| x.room_id == staff.as_str()) {
        bail!("member sees a hidden chat")
    }
    println!("hidden ok");

    // 5. Only admins add: the server refuses b; then everyone may.
    let bg = b.create_group("b의 배드민턴", &[], false).await?;
    b.sync_once().await?;
    match b.add_to_community(&cid, &bg, false).await {
        Ok(_) => bail!("server let a member add while admins only"),
        Err(e) => println!("member add refused: {e}"),
    }
    a.set_community_add_all(&cid, true).await?;
    settle(&[&a, &b]).await?;
    b.add_to_community(&cid, &bg, false).await?;
    settle(&[&a, &b]).await?;
    if !find(&a, cid.as_str()).await.unwrap().chats.iter().any(|x| x.room_id == bg.as_str() && x.by == bid.as_str()) {
        bail!("member's own chat not added")
    }
    println!("add rights ok");

    // 6. b becomes an admin: gets the admin key and sees the hidden chat.
    a.set_community_admin(&cid, bid.as_str(), true).await?;
    settle(&[&a, &b]).await?;
    let bx = find(&b, cid.as_str()).await.unwrap();
    if bx.role != "admin" || !bx.chats.iter().any(|x| x.room_id == staff.as_str()) {
        bail!("new admin can't see the hidden chat (role {})", bx.role)
    }
    println!("admin key ok");

    // 7. What the server holds: no room ids, no names, no community name.
    let s: serde_json::Value = serde_json::from_str(&a.session_json()?)?;
    let tok = s["tokens"]["access_token"].as_str().or(s["access_token"].as_str()).unwrap_or_default().to_owned();
    let url = format!("{hs}/_matrix/client/v3/rooms/{}/state", cid);
    let out = std::process::Command::new("curl").args(["-s", "-H", &format!("Authorization: Bearer {tok}"), &url]).output()?;
    let body = String::from_utf8_lossy(&out.stdout).to_string();
    if !body.contains("app.burumy.community_chat") {
        bail!("state not read: {}", &body[..body.len().min(300)])
    }
    for secret in [g.as_str(), g2.as_str(), staff.as_str(), "일요 축구회", "운영진", "우리 동네 운동"] {
        if body.contains(secret) {
            bail!("server copy shows {secret}")
        }
    }
    println!("server copy: {} bytes, no room ids or names", body.len());

    // 8. A stranger can't read it or pull anyone in.
    if find(&c, cid.as_str()).await.is_some() {
        bail!("stranger sees the community")
    }

    // 9. Delete: b's phone leaves too.
    a.delete_community(&cid).await?;
    let mut gone = false;
    for _ in 0..10 {
        b.sync_once().await?;
        if find(&b, cid.as_str()).await.is_none() {
            gone = true;
            break;
        }
    }
    if !gone {
        bail!("member still sees a deleted community")
    }
    // The groups themselves stay.
    if !b.chat_list().await?.iter().any(|x| x.room_id == g.as_str()) {
        bail!("group went with the community")
    }
    println!("COMMUNITY PASS");
    Ok(())
}
