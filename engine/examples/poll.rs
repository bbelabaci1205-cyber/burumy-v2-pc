// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Open and anonymous polls against a real server. Usage: poll <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::{Engine, Message};

async fn find(e: &Engine, room: &matrix_sdk::ruma::RoomId, id: &str) -> Result<Message> {
    e.timeline(room, 50)
        .await?
        .into_iter()
        .find(|m| m.event_id == id)
        .ok_or_else(|| anyhow::anyhow!("poll missing"))
}

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args()
        .nth(1)
        .unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-poll-{run}"));
    let mut people = vec![];
    for n in ["a", "b", "c"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("v{n}{run}"), "Secret-pass-123", token.as_deref())
            .await?;
        people.push(e);
    }
    let (a, b, c) = (&people[0], &people[1], &people[2]);
    let room = a
        .create_group(
            "투표방",
            &[b.user_id().unwrap(), c.user_id().unwrap()],
            false,
        )
        .await?;
    for e in [b, c] {
        for _ in 0..40 {
            e.sync_once().await?;
            if e.invited_rooms().contains(&room) {
                break;
            }
        }
        e.join(&room).await?;
    }
    for e in [a, b, c] {
        e.sync_once().await?;
    }

    // Open poll: everyone sees who chose what.
    let p1 = a
        .create_poll(
            &room,
            "점심 뭐 먹을까요?",
            &["국수".into(), "비빔밥".into(), "".into()],
            false,
            false,
            None,
            "",
            0,
            "",
            vec![],
        )
        .await?;
    for e in [b, c] {
        e.sync_once().await?;
    }
    b.vote(&room, &p1, &["a0".into()]).await?;
    c.vote(&room, &p1, &["a1".into()]).await?;
    b.vote(&room, &p1, &["a1".into()]).await?; // changed mind
    for _ in 0..2 {
        for e in [a, b, c] {
            e.sync_once().await?;
        }
    }
    let m = find(a, &room, &p1).await?;
    let p = m.poll.clone().unwrap();
    println!(
        "open poll: {:?} votes {:?} voters {} who(a1) {:?}",
        m.body,
        p.answers
            .iter()
            .map(|x| (x.text.clone(), x.votes))
            .collect::<Vec<_>>(),
        p.voters,
        p.who.get("a1").map(|w| w.len())
    );
    if p.answers.len() != 2 || p.answers[1].votes != 2 || p.voters != 2 {
        bail!("open poll counts wrong")
    }

    // Anonymous poll: votes go only to a's phone, numbers come back.
    let p2 = a
        .create_poll(
            &room,
            "회식 날짜",
            &["금요일".into(), "토요일".into()],
            true,
            false,
            None,
            "",
            0,
            "",
            vec![],
        )
        .await?;
    for e in [b, c] {
        e.sync_once().await?;
    }
    b.vote(&room, &p2, &["a1".into()]).await?;
    c.vote(&room, &p2, &["a1".into()]).await?;
    c.vote(&room, &p2, &["a0".into()]).await?; // changed: must not count twice
    for _ in 0..3 {
        a.sync_once().await?;
        b.sync_once().await?;
        c.sync_once().await?;
    }
    let pb = find(b, &room, &p2).await?.poll.unwrap();
    println!(
        "anonymous poll seen by b: {:?} voters {} mine {:?} who {:?}",
        pb.answers.iter().map(|x| x.votes).collect::<Vec<_>>(),
        pb.voters,
        pb.mine,
        pb.who
    );
    if pb.answers.iter().map(|x| x.votes).collect::<Vec<_>>() != vec![1, 1]
        || pb.voters != 2
        || pb.mine != vec!["a1".to_string()]
        || !pb.who.is_empty()
    {
        bail!("anonymous numbers wrong")
    }
    // Nothing in the room says who voted.
    let leaked = b
        .timeline(&room, 100)
        .await?
        .iter()
        .any(|m| m.body.as_deref().is_some_and(|x| x.contains("a0")));
    if leaked {
        bail!("vote leaked into room")
    }

    // Close: no more votes.
    a.close_poll(&room, &p2).await?;
    for e in [b, c] {
        e.sync_once().await?;
    }
    if b.close_poll(&room, &p2).await.is_ok() {
        bail!("non-maker closed")
    }
    if b.vote(&room, &p2, &["a0".into()]).await.is_ok() {
        bail!("voted after close")
    }
    let closed = find(c, &room, &p2).await?.poll.unwrap().closed;
    println!("closed seen by c: {closed}");
    if !closed {
        bail!("close not seen")
    }
    upgrades(a, b, c, &room).await?;
    println!("POLL CHECK PASSED");
    Ok(())
}

/// 1x1 PNG.
const PNG: &[u8] = &[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00,
    0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00,
    0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01,
    0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

async fn sync_all(list: &[&Engine], rounds: usize) -> Result<()> {
    for _ in 0..rounds {
        for e in list {
            e.sync_once().await?;
        }
    }
    Ok(())
}

/// Telegram tip 562 extras on a real server: description + photos, a
/// sticker, members adding answers, vote lock, hidden numbers until the end.
async fn upgrades(a: &Engine, b: &Engine, c: &Engine, room: &matrix_sdk::ruma::RoomId) -> Result<()> {
    let extra = serde_json::json!({
        "description": "오후 2시, 두 시간 정도",
        "add_options": true,
        "change_vote": false,
        "shuffle": true,
        "answers": [{ "sticker": "buru_04_good" }, {}, { "geo": "geo:37.5,127.0" }],
    });
    let p3 = a
        .create_poll(
            room,
            "토요일 어디서?",
            &["한강".into(), "성수".into(), "".into()],
            false,
            false,
            None,
            "",
            0,
            &extra.to_string(),
            vec![
                ("q".into(), "image/png".into(), PNG.to_vec()),
                ("1".into(), "image/png".into(), PNG.to_vec()),
            ],
        )
        .await?;
    sync_all(&[b, c], 1).await?;
    let added = b.add_poll_option(room, &p3, "을지로").await?;
    sync_all(&[a, b, c], 1).await?;
    if c.add_poll_option(room, &p3, " 한강 ").await.is_ok() {
        bail!("same answer added twice")
    }
    c.vote(room, &p3, &[added.clone()]).await?;
    c.vote(room, &p3, &["a0".into()]).await?; // changes are off: ignored
    sync_all(&[a, b, c], 2).await?;
    let p = find(b, room, &p3).await?.poll.unwrap();
    println!(
        "upgrade poll: desc {:?} media {} answers {:?} change_vote {} shuffle {}",
        p.description,
        p.media,
        p.answers
            .iter()
            .map(|x| (x.text.clone(), x.votes, x.sticker.clone(), x.media, x.added_by.clone()))
            .collect::<Vec<_>>(),
        p.change_vote,
        p.shuffle
    );
    if p.description != "오후 2시, 두 시간 정도"
        || !p.media
        || p.answers.len() != 3
        || p.answers[0].sticker != "buru_04_good"
        || !p.answers[1].media
        || p.answers[2].text != "을지로"
        || p.answers[2].added_by != b.user_id().map(|u| u.to_string())
        || p.answers[2].votes != 1
        || p.answers[0].votes != 0
        || p.change_vote
        || !p.shuffle
    {
        bail!("upgrade poll wrong")
    }
    let q = c.poll_photo(room, &p3, "").await?;
    let o = c.poll_photo(room, &p3, "a1").await?;
    if q != PNG || o != PNG {
        bail!("poll photos did not come back")
    }
    println!("photos decrypted on another phone: {} + {} bytes", q.len(), o.len());

    // Anonymous + hidden: no numbers in the chat until the maker closes.
    let extra = serde_json::json!({ "hide_results": true });
    let p4 = a
        .create_poll(room, "비밀 결과", &["예".into(), "아니요".into()], true, false, None, "", 0, &extra.to_string(), vec![])
        .await?;
    sync_all(&[b, c], 1).await?;
    b.vote(room, &p4, &["a0".into()]).await?;
    c.vote(room, &p4, &["a1".into()]).await?;
    sync_all(&[a, b, c], 3).await?;
    let before = find(c, room, &p4).await?.poll.unwrap();
    println!("hidden before end (c): {:?} voters {}", before.answers.iter().map(|x| x.votes).collect::<Vec<_>>(), before.voters);
    if before.voters != 0 || before.answers.iter().any(|x| x.votes > 0) {
        bail!("hidden numbers leaked before the end")
    }
    a.close_poll(room, &p4).await?;
    sync_all(&[a, b, c], 2).await?;
    let after = find(c, room, &p4).await?.poll.unwrap();
    println!("hidden after close (c): {:?} voters {} closed {}", after.answers.iter().map(|x| x.votes).collect::<Vec<_>>(), after.voters, after.closed);
    if after.voters != 2 || after.answers.iter().map(|x| x.votes).collect::<Vec<_>>() != vec![1, 1] || !after.closed {
        bail!("final numbers missing")
    }

    // Deadline instead of closing: the maker's phone posts the numbers once
    // the time is up (next time it opens the chat).
    let soon = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_millis() as u64 + 62_000;
    let p5 = a
        .create_poll(room, "마감 시간 결과", &["x".into(), "y".into()], true, false, None, "", soon, &extra.to_string(), vec![])
        .await?;
    sync_all(&[b], 1).await?;
    b.vote(room, &p5, &["a1".into()]).await?;
    sync_all(&[a, b], 2).await?;
    if find(b, room, &p5).await?.poll.unwrap().voters != 0 {
        bail!("deadline poll leaked early")
    }
    tokio::time::sleep(std::time::Duration::from_secs(64)).await;
    a.sync_once().await?;
    a.timeline(room, 50).await?; // maker's phone opens the chat
    sync_all(&[b], 2).await?;
    let d = find(b, room, &p5).await?.poll.unwrap();
    println!("deadline poll after time (b): {:?} voters {}", d.answers.iter().map(|x| x.votes).collect::<Vec<_>>(), d.voters);
    if d.voters != 1 || d.answers[1].votes != 1 {
        bail!("deadline numbers missing")
    }
    if b.vote(room, &p5, &["a0".into()]).await.is_ok() {
        bail!("voted after deadline")
    }
    println!("POLL UPGRADES PASSED");
    Ok(())
}
