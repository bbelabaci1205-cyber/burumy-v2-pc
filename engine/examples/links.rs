// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Invite links: public address (peek + join), private code (join, new
//! code stops the old one), approval (ask, admin lets in), and the channel
//! web page (reader account sees only the posts put there).
//! Usage: links <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::{Engine, links::WEB_READER};

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-links-{run}"));
    let mk = |n: &str| {
        let d = dir.join(n);
        let hs = hs.clone();
        let token = token.clone();
        let id = format!("l{n}{run}");
        async move {
            let e = Engine::open(&hs, &d, "s").await?;
            e.register(&id, "Secret-pass-123", token.as_deref()).await?;
            e.sync_once().await?;
            Ok::<_, anyhow::Error>(e)
        }
    };
    let a = mk("a").await?;
    let b = mk("b").await?;
    let c = mk("c").await?;
    let d = mk("d").await?;

    let ch = a.create_group("서울 러닝 채널", &[], true).await?;
    a.set_room_about(&ch, "주말마다 한강을 달려요").await?;
    a.sync_once().await?;
    let addr = format!("seoul_run{run}");
    if !a.address_free(&ch, &addr).await? {
        bail!("address should be free")
    }
    let link = a.set_public_link(&ch, &addr).await?;
    println!("public link: {link:?}");
    if link.kind != "public" || link.code != addr {
        bail!("public link wrong")
    }
    let bg = b.create_group("다른 방", &[], false).await?;
    if b.address_free(&bg, &addr).await? {
        bail!("address should be taken now")
    }

    let peek = b.peek_address(&addr).await?;
    println!("peek: {peek:?}");
    if peek.name != "서울 러닝 채널" || peek.about != "주말마다 한강을 달려요" || !peek.channel || peek.members != 1 || peek.approval {
        bail!("peek wrong")
    }
    let (rid, asked) = b.join_link("public", &addr).await?;
    if rid != ch.as_str() || asked {
        bail!("public join wrong")
    }
    println!("b joined by public link");

    // Private: code joins; a new code stops the old one; the address is gone.
    a.sync_once().await?;
    let p = a.new_private_link(&ch).await?;
    println!("private link: kind {} code len {}", p.kind, p.code.len());
    if b.peek_address(&addr).await.is_ok() {
        bail!("old address still open")
    }
    let (rid, _) = c.join_link("private", &p.code).await?;
    if rid != ch.as_str() {
        bail!("private join wrong")
    }
    a.sync_once().await?;
    let p2 = a.new_private_link(&ch).await?;
    if p2.code == p.code || d.join_link("private", &p.code).await.is_ok() {
        bail!("old private code still works")
    }
    println!("c joined by private link; old code refused");

    // Approval: d asks, a lets d in.
    a.sync_once().await?;
    a.set_link_approval(&ch, true).await?;
    a.sync_once().await?;
    if !a.room_link(&ch).await.approval {
        bail!("approval not on")
    }
    let (rid, asked) = d.join_link("private", &p2.code).await?;
    if rid != ch.as_str() || !asked {
        bail!("approval join should only ask")
    }
    let mut reqs = vec![];
    for _ in 0..10 {
        a.sync_once().await?;
        reqs = a.join_requests(&ch).await?;
        if !reqs.is_empty() {
            break;
        }
    }
    println!("requests: {reqs:?}");
    let did = d.user_id().unwrap().to_string();
    if !reqs.iter().any(|(u, _, _)| *u == did) {
        bail!("request not seen")
    }
    a.answer_join_request(&ch, &did, true).await?;
    for _ in 0..10 {
        d.sync_once().await?;
        if d.invited_rooms().iter().any(|r| *r == ch) {
            break;
        }
    }
    d.join(&ch).await?;
    println!("d let in after asking");

    // Web page: public again, reader in, posts shown, off removes them.
    a.set_link_approval(&ch, false).await?;
    a.sync_once().await?;
    a.set_public_link(&ch, &addr).await?;
    a.sync_once().await?;
    let w = Engine::open(&hs, &dir.join("w"), "s").await?;
    if let Err(e) = w.register(WEB_READER, "Secret-pass-123", token.as_deref()).await {
        // Already made by an earlier run: log in instead.
        println!("reader register: {e}; logging in");
        w.login(WEB_READER, "Secret-pass-123", "web").await?;
    }
    a.set_web_page(&ch, true).await?;
    a.sync_once().await?;
    if !a.room_link(&ch).await.web {
        bail!("web not on")
    }
    // Every new post is copied to the web page; a deleted one comes off.
    let post = a.send_text(&ch, "이번 주 토요일 7시, 여의도에서 만나요").await?;
    let gone = a.send_text(&ch, "잘못 올린 글").await?;
    a.sync_once().await?;
    a.delete_message(&ch, &gone).await?;
    let _ = post;
    for _ in 0..10 {
        w.sync_once().await?;
        if w.invited_rooms().iter().any(|r| *r == ch) {
            break;
        }
    }
    w.join(&ch).await?;
    w.sync_once().await?;
    let seen = w.web_posts(&ch).await;
    println!("reader sees {} web post(s): {:?}", seen.len(), seen.first().map(|x| &x.1["text"]));
    if seen.len() != 1 || seen[0].1["text"] != "이번 주 토요일 7시, 여의도에서 만나요" {
        bail!("reader posts wrong")
    }
    c.sync_once().await?;
    let peek = c.peek_address(&addr).await?;
    if peek.members != 4 {
        bail!("members should not count the reader: {}", peek.members)
    }
    a.set_web_page(&ch, false).await?;
    a.sync_once().await?;
    if !a.web_posts(&ch).await.is_empty() || a.room_link(&ch).await.web {
        bail!("web off should clear posts: {:?} {:?}", a.web_posts(&ch).await, a.room_link(&ch).await)
    }
    println!("web page off: posts cleared, reader out");
    println!("LINKS PASS");
    Ok(())
}
