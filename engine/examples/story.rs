// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Stories against a real server (tips 393, 392/468/534, 525, 428):
//! a long video in parts from one upload, changing a posted story, keeping
//! it on the profile, narrowing who sees it, and a group's admin story.
//! Usage: story <homeserver> <token>
use anyhow::{Result, bail, ensure};
use burumy_engine::{Engine, matrix_sdk::ruma::RoomId};

async fn friend_of(a: &Engine, b: &Engine) -> Result<String> {
    let room = a.create_dm(&b.user_id().unwrap()).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&room) {
            break;
        }
    }
    b.join(&room).await?;
    a.sync_once().await?;
    Ok(room.to_string())
}

async fn settle(all: &[&Engine]) -> Result<()> {
    for _ in 0..3 {
        for e in all {
            e.sync_once().await?;
        }
    }
    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-story-{run}"));
    let mut people = vec![];
    for n in ["a", "b", "c"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("s{n}{run}"), "Secret-pass-123", token.as_deref())
            .await?;
        people.push(e);
    }
    let (a, b, c) = (&people[0], &people[1], &people[2]);
    let ab = friend_of(a, b).await?;
    let ac = friend_of(a, c).await?;
    let all = [a, b, c];
    settle(&all).await?;

    // 525: one upload, three parts.
    let video = vec![0u8, 0, 0, 0x18, b'f', b't', b'y', b'p', 1, 2, 3];
    let parts: Vec<String> = (0..3)
        .map(|i| format!(r#"{{"clip":{{"from":{},"to":{}}}}}"#, i * 60, i * 60 + 60))
        .collect();
    let posted = a
        .post_stories("video/mp4", video, "긴 영상", &[], 24, &parts, "")
        .await?;
    println!("parts: sent to {} friends, ids {:?}", posted.sent, posted.ids);
    ensure!(posted.sent == 2 && posted.ids.len() == 3, "parts not posted");
    settle(&all).await?;
    let seen = b.stories().await?;
    ensure!(seen.len() == 3, "friend sees {} parts", seen.len());
    let ev: std::collections::BTreeSet<_> = seen.iter().map(|s| s.event_id.clone()).collect();
    ensure!(ev.len() == 3, "parts share an event");

    // 393: change a photo story's words and stickers; it keeps its time.
    let pic = vec![0x89u8, b'P', b'N', b'G', 1, 2, 3, 4];
    let id = a
        .post_stories("image/png", pic, "오타 있는 글", &[], 24, &[], "")
        .await?
        .ids[0]
        .clone();
    settle(&all).await?;
    let before = b.stories().await?.into_iter().find(|s| s.story_id == id).unwrap();
    a.edit_story(&id, "", vec![], "고친 글", r#"{"items":[]}"#, &[], "").await?;
    settle(&all).await?;
    let after = b.stories().await?.into_iter().filter(|s| s.story_id == id).collect::<Vec<_>>();
    println!("edit: {:?} -> {:?} (edited {})", before.caption, after.first().and_then(|s| s.caption.clone()), after.first().is_some_and(|s| s.edited));
    ensure!(after.len() == 1, "edit shows {} copies", after.len());
    ensure!(after[0].caption.as_deref() == Some("고친 글") && after[0].edited, "edit not seen");
    ensure!(after[0].ts == before.ts, "edit moved the time");
    ensure!(after[0].extra.as_deref() == Some(r#"{"items":[]}"#), "stickers not changed");
    let mine = a.stories().await?.into_iter().filter(|s| s.story_id == id).count();
    ensure!(mine == 1, "I see my story {mine} times");

    // Narrow: only b now; c loses it.
    a.edit_story(&id, "", vec![], "고친 글", "", std::slice::from_ref(&ab), "").await?;
    settle(&all).await?;
    let b_has = b.stories().await?.iter().any(|s| s.story_id == id);
    let c_has = c.stories().await?.iter().any(|s| s.story_id == id);
    println!("audience narrowed: b {b_has}, c {c_has}");
    ensure!(b_has && !c_has, "audience change wrong");
    // Widen again: c gets the same picture back.
    a.edit_story(&id, "", vec![], "고친 글", "", &[ab.clone(), ac.clone()], "").await?;
    settle(&all).await?;
    let back = c.stories().await?.into_iter().find(|s| s.story_id == id);
    ensure!(back.is_some(), "c did not get it back");
    let file = c.download_file(&RoomId::parse(&ac)?, &back.unwrap().event_id).await?.1;
    ensure!(file.starts_with(&[0x89, b'P']), "picture lost on re-send");

    // 392 / 534: keep it on the profile, in an album.
    a.edit_story(&id, "", vec![], "고친 글", "", &[], r#"{"album":"제주도"}"#).await?;
    settle(&all).await?;
    let kept = b.stories().await?.into_iter().find(|s| s.story_id == id).unwrap();
    println!("kept: pin {:?}, until {} (time {})", kept.pin, kept.until, kept.ts);
    ensure!(kept.pin.as_deref() == Some(r#"{"album":"제주도"}"#), "pin not seen");
    ensure!(kept.until > kept.ts, "pin lost its end time");

    // New picture (393: replace the photo too).
    a.edit_story(&id, "image/png", vec![0x89, b'P', b'N', b'G', 9, 9], "새 사진", "", &[], r#"{"album":"제주도"}"#).await?;
    settle(&all).await?;
    let x = b.stories().await?.into_iter().find(|s| s.story_id == id).unwrap();
    let f = b.download_file(&RoomId::parse(&ab)?, &x.event_id).await?.1;
    ensure!(f.ends_with(&[9, 9]), "new picture not seen");

    // 428: a group's story, admins only.
    let g = a
        .create_group("동호회", &[b.user_id().unwrap(), c.user_id().unwrap()], false)
        .await?;
    for e in [b, c] {
        for _ in 0..40 {
            e.sync_once().await?;
            if e.invited_rooms().contains(&g) {
                break;
            }
        }
        e.join(&g).await?;
    }
    settle(&all).await?;
    let gs = a
        .post_stories("image/png", vec![0x89, b'P', b'N', b'G', 5], "모임 사진", &[], 24, &[], g.as_str())
        .await?;
    ensure!(gs.sent == 1, "group story not sent");
    if b
        .post_stories("image/png", vec![0x89, b'P', b'N', b'G', 6], "", &[], 24, &[], g.as_str())
        .await
        .is_ok()
    {
        bail!("a member posted the group's story")
    }
    settle(&all).await?;
    let in_group: Vec<_> = c.stories().await?.into_iter().filter(|s| s.group).collect();
    println!("group stories c sees: {}", in_group.len());
    ensure!(in_group.len() == 1 && in_group[0].room_id == g.as_str(), "group story not seen");
    // Not in the chat itself.
    let msgs = c.messages(&g, 20).await?;
    ensure!(!msgs.iter().any(|m| m.body.as_deref() == Some("모임 사진")), "group story leaked into the chat");

    // Delete everywhere.
    a.delete_story(&id).await?;
    a.delete_story(&gs.ids[0]).await?;
    settle(&all).await?;
    let left = b.stories().await?.into_iter().filter(|s| s.story_id == id || s.group).count();
    ensure!(left == 0, "{left} left after delete");
    println!("story check PASS");
    Ok(())
}
