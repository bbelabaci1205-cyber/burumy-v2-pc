// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 초대 링크 여러 개 (tip 253) against our Conduit fork: an extra link with
//! a people limit lets exactly that many in, the server counts them and
//! names them, an ended link is refused, a cancelled link stops at once
//! and comes back with 되돌리기, and the main link is counted too.
//! Usage: invite_links <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;

fn now_ms() -> u64 {
    std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis() as u64
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-invl-{run}"));
    let mk = |n: &str| {
        let d = dir.join(n);
        let hs = hs.clone();
        let token = token.clone();
        let id = format!("v{n}{run}");
        async move {
            let e = Engine::open(&hs, &d, "s").await?;
            e.register(&id, "Secret-pass-123", token.as_deref()).await?;
            e.sync_once().await?;
            Ok::<_, anyhow::Error>(e)
        }
    };
    let owner = mk("o").await?;
    let p1 = mk("a").await?;
    let p2 = mk("b").await?;
    let p3 = mk("c").await?;
    let p4 = mk("d").await?;

    let g = owner.create_group("동네 친구들", &[], false).await?;
    owner.sync_once().await?;
    let main = owner.new_private_link(&g).await?;
    owner.sync_once().await?;

    // 1. Two seats.
    let two = owner.make_invite_link(&g, "인스타 프로필", 0, 2, now_ms()).await?;
    println!("made link with 2 seats: name {:?}", two.name);
    p1.join_link("private", &two.code).await?;
    p2.join_link("private", &two.code).await?;
    match p3.join_link("private", &two.code).await {
        Ok(_) => bail!("third person got in through a 2-seat link"),
        Err(e) if e.to_string().contains("link full") => println!("3rd person refused: link full"),
        Err(e) => bail!("wrong refusal: {e}"),
    }
    owner.sync_once().await?;
    let list = owner.invite_links(&g).await;
    let l = list.iter().find(|x| x.code == two.code).expect("link listed");
    println!("server count: uses {} joined {:?}", l.uses, l.joined.len());
    if l.uses != 2 || l.joined.len() != 2 || !l.joined.iter().any(|u| u.starts_with(&format!("@va{run}"))) {
        bail!("count wrong: {l:?}")
    }
    // Joining again (already a member) is not counted twice.
    p1.join_link("private", &two.code).await?;

    // 2. Ended link.
    let short = owner.make_invite_link(&g, "", now_ms() + 1500, 0, now_ms()).await?;
    tokio::time::sleep(std::time::Duration::from_millis(2000)).await;
    match p3.join_link("private", &short.code).await {
        Ok(_) => bail!("ended link still let someone in"),
        Err(e) if e.to_string().contains("link expired") => println!("ended link refused: link expired"),
        Err(e) => bail!("wrong refusal: {e}"),
    }

    // 3. Cancel stops it; 되돌리기 brings it back.
    let open = owner.make_invite_link(&g, "친구용", 0, 0, now_ms()).await?;
    owner.revoke_invite_link(&g, &open.code).await?;
    if p3.join_link("private", &open.code).await.is_ok() {
        bail!("cancelled link still works")
    }
    println!("cancelled link refused");
    owner.restore_invite_link(&g, &open.code).await?;
    p3.join_link("private", &open.code).await?;
    println!("restored link works");

    // 4. Editing keeps the count; the main link is counted too.
    owner.sync_once().await?;
    let edited = owner.edit_invite_link(&g, &two.code, "인스타", 0, 3).await?;
    if edited.uses != 2 || edited.max != 3 {
        bail!("edit lost the count: {edited:?}")
    }
    p4.join_link("private", &main.code).await?;
    owner.sync_once().await?;
    let (n, who) = owner.main_link_uses(&g).await;
    println!("main link: {n} joined");
    if n != 1 || who.len() != 1 {
        bail!("main link not counted")
    }
    owner.delete_invite_link(&g, &short.code).await?;
    owner.sync_once().await?;
    if owner.invite_links(&g).await.iter().any(|x| x.code == short.code) {
        bail!("deleted link still listed")
    }
    println!("INVITE LINKS PASS");
    Ok(())
}
