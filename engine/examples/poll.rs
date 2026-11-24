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
    println!("POLL CHECK PASSED");
    Ok(())
}
