// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 답장·멘션 (Telegram tips 399 / 249 / 320) against a real server:
//! a partial-quote reply, a quote copied in from another chat, and the
//! cheap "messages on this phone" read the chat list uses for its marks.
//! Usage: reply_quote <hs> <token>
use anyhow::{Result, bail};
use burumy_engine::Engine;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-quote-{run}"));
    let a = Engine::open(&hs, &dir.join("a"), "s").await?;
    a.register(&format!("qa{run}"), "Secret-pass-123", token.as_deref()).await?;
    let b = Engine::open(&hs, &dir.join("b"), "s").await?;
    b.register(&format!("qb{run}"), "Secret-pass-123", token.as_deref()).await?;
    let ab = a.create_dm(&b.user_id().unwrap()).await?;
    for _ in 0..40 {
        b.sync_once().await?;
        if b.invited_rooms().contains(&ab) {
            break;
        }
    }
    b.join(&ab).await?;
    a.sync_once().await?;

    // b writes; a answers only "토요일 아침 7시" of it.
    let t = b.send_text(&ab, "토요일 아침 7시에 한강에서 만나요").await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    a.reply_quote(&ab, &t, "좋아요!", "토요일 아침 7시", "ignored").await?;
    // A quote copied in from another chat: no link, the writer's name kept.
    a.reply_quote(&ab, "", "우산 챙겨요", "다음 주 비 온대요", "민지").await?;
    // An over-long quote is cut to 1024 characters.
    a.reply_quote(&ab, &t, "길어요", &"가".repeat(2000), "").await?;
    // b reacts to a's first answer.
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let tl = b.timeline(&ab, 20).await?;
    let part = tl.iter().find(|m| m.body.as_deref() == Some("좋아요!")).ok_or_else(|| anyhow::anyhow!("reply missing"))?;
    println!("partial: reply_to={:?} quote={:?} name={:?} encrypted={}", part.reply_to, part.quote, part.quote_name, part.was_encrypted);
    if part.reply_to.as_deref() != Some(t.as_str()) || part.quote.as_deref() != Some("토요일 아침 7시") || part.quote_name.is_some() || !part.was_encrypted {
        bail!("partial quote wrong")
    }
    let other = tl.iter().find(|m| m.body.as_deref() == Some("우산 챙겨요")).ok_or_else(|| anyhow::anyhow!("other-chat reply missing"))?;
    println!("other chat: reply_to={:?} quote={:?} name={:?}", other.reply_to, other.quote, other.quote_name);
    if other.reply_to.is_some() || other.quote.as_deref() != Some("다음 주 비 온대요") || other.quote_name.as_deref() != Some("민지") {
        bail!("other-chat quote wrong")
    }
    let long = tl.iter().find(|m| m.body.as_deref() == Some("길어요")).ok_or_else(|| anyhow::anyhow!("long missing"))?;
    if long.quote.as_ref().map(|q| q.chars().count()) != Some(1024) {
        bail!("quote not cut")
    }
    b.react(&ab, &part.event_id, "❤️").await?;
    for _ in 0..3 {
        a.sync_once().await?;
    }
    // The chat list's cheap read sees the reaction without asking the server.
    let cached = a.cached_messages(&ab).await?;
    let mine = cached.iter().find(|m| m.event_id == part.event_id).ok_or_else(|| anyhow::anyhow!("not cached"))?;
    println!("cached: {} messages, reactions on my reply: {:?}", cached.len(), mine.reactions.iter().map(|r| (r.key.clone(), r.count)).collect::<Vec<_>>());
    if mine.reactions.iter().map(|r| r.count).sum::<u32>() != 1 {
        bail!("reaction not seen in cached messages")
    }
    println!("REPLY QUOTE CHECK PASSED");
    Ok(())
}
