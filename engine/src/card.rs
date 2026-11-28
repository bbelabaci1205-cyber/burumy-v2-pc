// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Channel and group "cards": FAQ, guide menu, link buttons, formatted
//! posts, long posts (see article.rs), giveaways, application forms, safety check-ins and choice flows.
//!
//! A choice flow ("flow") carries its whole question tree inside the one
//! encrypted event, so tapping through it runs only on the reader's phone:
//! no bot, no server and not even the maker sees the taps. With stats on,
//! only the result reached goes to the maker's phone, which keeps it under
//! a one-way code (never the person's ID) and posts numbers only.
//!
//! A card is one encrypted room event with checked, size-limited data.
//! Answers (joining a giveaway, a form, "I'm safe") never go into the room:
//! like anonymous poll votes they go only to the maker's phone(s) as
//! encrypted device messages, because in channels members must not see
//! each other. The maker's phone keeps who answered (it needs that to pick
//! winners or read forms) and posts only numbers, and winners at the end.

use std::collections::HashMap;

use anyhow::{Context, Result, bail, ensure};
use serde_json::{Value, json};

pub const START: &str = "app.burumy.card";
pub const REPLY: &str = "app.burumy.card.reply";
pub const TALLY: &str = "app.burumy.card.tally";
/// "You won" sent only to each winner's phones when names stay private.
pub const WON: &str = "app.burumy.card.won";
pub const MAX_DATA: usize = 24 * 1024;
pub const MAX_WINNERS: u64 = 100;
/// Longest suggested post (tip 531), like a channel post's caption room.
pub const SUGGEST_TEXT: usize = 4000;

/// Kinds people answer (the others are read-only).
pub fn answered(kind: &str) -> bool {
    matches!(kind, "lottery" | "form" | "checkin" | "flow")
}

/// Choice flows: at most 10 questions of up to 6 choices, 8 results.
pub const FLOW_STEPS: usize = 10;
pub const FLOW_CHOICES: usize = 6;
pub const FLOW_RESULTS: usize = 8;

/// Key for one person in the maker's answer book. Choice flows keep a
/// one-way code instead of the ID so the maker's phone never holds who got
/// which result (it still counts one answer per person).
pub fn book_key(kind: &str, cid: &str, sender: &str) -> String {
    if kind != "flow" {
        return sender.to_owned();
    }
    use sha2::{Digest, Sha256};
    let h = Sha256::digest(format!("burumy.flow\n{cid}\n{sender}").as_bytes());
    h.iter().take(16).map(|b| format!("{b:02x}")).collect()
}

/// "s3" -> step 3, "r1" -> result 1, checked against the sizes.
fn flow_target(v: &Value, steps: usize, results: usize) -> Option<String> {
    let t = v.as_str()?;
    let (kind, n) = t.split_at_checked(1)?;
    let n: usize = n.parse().ok()?;
    let ok = match kind {
        "s" => n < steps,
        "r" => n < results,
        _ => false,
    };
    (ok && n.to_string().len() == t.len() - 1).then(|| t.to_owned())
}

#[derive(Debug, Clone, PartialEq)]
pub struct Card {
    pub kind: String,
    /// The checked data as JSON.
    pub data: String,
    /// Numbers the maker posted ("in", "ok", "help", "sent").
    pub counts: HashMap<String, u32>,
    pub winners: Vec<String>,
    pub closed: bool,
    /// My own answer from this phone (JSON), "" if none.
    pub mine: String,
    /// I won this giveaway (told only to me when names stay private).
    pub won: bool,
}

fn text(v: &Value, max: usize) -> Option<String> {
    let t = v.as_str()?.trim();
    (!t.is_empty()).then(|| t.chars().take(max).collect())
}

fn opt_text(v: &Value, max: usize) -> String {
    text(v, max).unwrap_or_default()
}

fn list<'a>(v: &'a Value, max: usize) -> impl Iterator<Item = &'a Value> {
    v.as_array()
        .map(|a| a.as_slice())
        .unwrap_or(&[])
        .iter()
        .take(max)
}

/// Only web links people can safely open.
fn link(v: &Value) -> Option<String> {
    let u = v.as_str()?.trim();
    let ok = (u.starts_with("https://") || u.starts_with("http://"))
        && u.len() <= 500
        && !u.chars().any(|c| c.is_whitespace() || c.is_control());
    ok.then(|| u.to_owned())
}

/// iOS colours for link buttons (never dark green).
const COLORS: [&str; 11] = [
    "green", "blue", "teal", "purple", "pink", "red", "orange", "yellow", "grey", "black", "white",
];
/// 주사위 games (tip 218), as sent alone in a message.
const DICE: [&str; 6] = ["🎲", "🎯", "🏀", "⚽", "🎳", "🎰"];
const MAX_ROWS: u64 = 6;
const PER_ROW: usize = 3;

fn pick<'a>(v: &Value, from: &[&'a str], def: &'a str) -> &'a str {
    v.as_str()
        .and_then(|x| from.iter().find(|c| **c == x).copied())
        .unwrap_or(def)
}

/// Checks and trims card data; refuses unknown kinds and empty cards.
pub fn sanitize(kind: &str, d: &Value, now: u64) -> Result<Value> {
    let out = match kind {
        "faq" => {
            let items: Vec<Value> = list(&d["items"], 30)
                .filter_map(|x| {
                    Some(json!({ "q": text(&x["q"], 200)?, "a": text(&x["a"], 1000)? }))
                })
                .collect();
            ensure!(!items.is_empty(), "add at least one question");
            json!({ "title": opt_text(&d["title"], 100), "items": items })
        }
        "guide" => {
            let items: Vec<Value> = list(&d["items"], 20)
                .filter_map(|x| {
                    Some(
                        json!({ "label": text(&x["label"], 60)?, "text": text(&x["text"], 1000)? }),
                    )
                })
                .collect();
            ensure!(!items.is_empty(), "add at least one menu item");
            json!({ "title": text(&d["title"], 100).unwrap_or_default(), "sub": opt_text(&d["sub"], 200), "items": items })
        }
        "links" => {
            // Up to 6 rows of up to 3 buttons (18 in all), like the v1 editor.
            let mut per_row = [0usize; MAX_ROWS as usize];
            let buttons: Vec<Value> = list(&d["buttons"], PER_ROW * MAX_ROWS as usize)
                .filter_map(|x| {
                    let row = x["row"].as_u64().unwrap_or(0).min(MAX_ROWS - 1);
                    let label = text(&x["label"], 24)?;
                    let url = link(&x["url"])?;
                    let slot = &mut per_row[row as usize];
                    if *slot >= PER_ROW {
                        return None;
                    }
                    *slot += 1;
                    // "" = follow the colour chosen for all buttons.
                    let color = pick(&x["color"], &COLORS, "");
                    Some(json!({ "label": label, "url": url, "color": color, "row": row }))
                })
                .collect();
            ensure!(!buttons.is_empty(), "add at least one button");
            let st = &d["style"];
            let style = json!({
                "color": pick(&st["color"], &COLORS, "green"),
                "glass": st["glass"].as_bool().unwrap_or(true),
                "size": pick(&st["size"], &["s", "m", "l"], "m"),
                "shape": pick(&st["shape"], &["round", "pill", "square"], "round"),
                "ink": pick(&st["ink"], &["auto", "white", "black"], "auto"),
            });
            json!({ "text": opt_text(&d["text"], 2000), "buttons": buttons, "style": style })
        }
        "rich" => {
            let blocks: Vec<Value> = list(&d["blocks"], 50)
                .filter_map(|x| {
                    let t = x["t"]
                        .as_str()
                        .filter(|t| ["h", "p", "li", "quote", "link"].contains(t))?;
                    let body = text(&x["text"], 2000)?;
                    if t == "link" {
                        return Some(json!({ "t": t, "text": body, "url": link(&x["url"])? }));
                    }
                    Some(json!({ "t": t, "text": body }))
                })
                .collect();
            let title = opt_text(&d["title"], 200);
            ensure!(!blocks.is_empty() || !title.is_empty(), "write something");
            json!({ "title": title, "blocks": blocks })
        }
        "article" => crate::article::clean_card(d)?,
        "lottery" => {
            let prize =
                text(&d["prize"], 200).ok_or_else(|| anyhow::anyhow!("what is the prize?"))?;
            let winners = d["winners"].as_u64().unwrap_or(1);
            ensure!((1..=MAX_WINNERS).contains(&winners), "1-100 winners");
            let ends = d["ends_at"].as_u64().unwrap_or(0);
            ensure!(
                ends == 0 || (ends > now + 60_000 && ends <= now + 90 * 24 * 3600 * 1000),
                "end within 90 days"
            );
            // announce false: winners are told privately, the list stays on my phone.
            let announce = d["announce"].as_bool().unwrap_or(false);
            json!({ "prize": prize, "winners": winners, "ends_at": ends, "note": opt_text(&d["note"], 500), "announce": announce })
        }
        "form" => {
            let questions: Vec<Value> = list(&d["questions"], 20)
                .filter_map(|x| {
                    let q = text(&x["q"], 200)?;
                    let options: Vec<String> = list(&x["options"], 10).filter_map(|o| text(o, 100)).collect();
                    let t = if options.len() >= 2 { "choice" } else { "text" };
                    Some(json!({ "q": q, "type": t, "options": if t == "choice" { options } else { vec![] } }))
                })
                .collect();
            ensure!(!questions.is_empty(), "add at least one question");
            json!({ "title": text(&d["title"], 200).ok_or_else(|| anyhow::anyhow!("a form needs a title"))?, "questions": questions })
        }
        "checkin" => {
            json!({ "text": text(&d["text"], 500).ok_or_else(|| anyhow::anyhow!("write what happened"))? })
        }
        "flow" => {
            let title = text(&d["title"], 100).ok_or_else(|| anyhow::anyhow!("a flow needs a title"))?;
            let steps_in: Vec<&Value> = list(&d["steps"], FLOW_STEPS).collect();
            let results_in: Vec<&Value> = list(&d["results"], FLOW_RESULTS).collect();
            ensure!(!steps_in.is_empty(), "add at least one question");
            ensure!(!results_in.is_empty(), "add at least one result");
            // Indexes must stay put (choices point at them): a blank
            // question or result refuses the card instead of shifting.
            let mut results = vec![];
            for x in &results_in {
                let t = text(&x["title"], 100).ok_or_else(|| anyhow::anyhow!("each result needs a name"))?;
                let l = &x["link"];
                let link = match (text(&l["label"], 24), link(&l["url"])) {
                    (Some(label), Some(url)) => json!({ "label": label, "url": url }),
                    _ => Value::Null,
                };
                results.push(json!({ "title": t, "text": opt_text(&x["text"], 1000), "link": link }));
            }
            let mut steps = vec![];
            for x in &steps_in {
                let q = text(&x["q"], 200).ok_or_else(|| anyhow::anyhow!("each question needs words"))?;
                let choices: Vec<Value> = list(&x["choices"], FLOW_CHOICES)
                    .filter_map(|c| {
                        let label = text(&c["label"], 40)?;
                        let to = flow_target(&c["to"], steps_in.len(), results.len())?;
                        Some(json!({ "label": label, "to": to }))
                    })
                    .collect();
                ensure!(!choices.is_empty(), "each question needs a choice");
                steps.push(json!({ "q": q, "choices": choices }));
            }
            // Some result must be reachable from the first question.
            let mut seen = vec![false; steps.len()];
            let mut todo = vec![0usize];
            let mut ends = false;
            while let Some(i) = todo.pop() {
                if std::mem::replace(&mut seen[i], true) {
                    continue;
                }
                for c in steps[i]["choices"].as_array().into_iter().flatten() {
                    let to = c["to"].as_str().unwrap_or_default();
                    match to.split_at(1) {
                        ("r", _) => ends = true,
                        (_, n) => todo.extend(n.parse::<usize>().ok()),
                    }
                }
            }
            ensure!(ends, "no answer path reaches a result");
            json!({
                "title": title,
                "text": opt_text(&d["text"], 1000),
                "start": opt_text(&d["start"], 24),
                "steps": steps,
                "results": results,
                "stats": d["stats"].as_bool().unwrap_or(true),
            })
        }
        // "이 그룹을 ○○ 커뮤니티에 추가했어요" line (community.rs). Only the
        // community's id and name: keys never travel in a chat.
        "community" => {
            let id = d["community"].as_str().unwrap_or_default();
            ensure!(matrix_sdk::ruma::RoomId::parse(id).is_ok(), "bad community");
            let kind = pick(&d["kind"], &["group", "channel"], "group");
            json!({ "community": id, "name": text(&d["name"], 64).unwrap_or_default(), "kind": kind })
        }
        // "OO님이 메시지를 고정했어요" line. Only the pinned message's id and
        // a short preview; notify = phones ring (else sent silently).
        "pin" => {
            let id = d["id"].as_str().unwrap_or_default();
            ensure!(matrix_sdk::ruma::EventId::parse(id).is_ok(), "bad message id");
            json!({ "id": id, "text": opt_text(&d["text"], 100), "notify": d["notify"].as_bool().unwrap_or(false) })
        }
        // 스티커 묶음 (tips 538 + 441): the set's encrypted file (place +
        // key, inside this end-to-end encrypted card), its name and size.
        // The pictures themselves never travel in the card.
        "stickers" => {
            let file = crate::article::clean_file(&d["file"]).context("bad set file")?;
            let name = text(&d["name"], 32).ok_or_else(|| anyhow::anyhow!("a set needs a name"))?;
            let n = d["n"].as_u64().unwrap_or(0);
            ensure!((1..=50).contains(&n), "1-50 stickers");
            let kind = pick(&d["kind"], &["sticker", "emoji"], "sticker");
            json!({ "file": file, "name": name, "n": n, "kind": kind })
        }
        // 다른 앱 대화 가져오기 (import.rs): parts' places + keys, counts.
        "import" => crate::import::sanitize(d)?,
        // 사진 제안 (Telegram tip 373): a profile photo suggested to the
        // other person in a 1:1. Only the encrypted file's place + key; the
        // photo itself is uploaded encrypted beforehand.
        "photo" => {
            let Some(file) = crate::article::clean_file(&d["file"]) else {
                bail!("bad photo")
            };
            json!({ "file": file, "mime": pick(&d["mime"], &["image/jpeg", "image/png"], "image/jpeg") })
        }
        // 채널에 글 제안 (tip 531): a subscriber's post idea in the channel's
        // admin chat (end-to-end encrypted like everything there). Words,
        // and/or one photo (its key from upload_encrypted), and when the
        // subscriber would like it posted (ms; 0 = any time). No money.
        "suggest" => {
            let words = opt_text(&d["text"], SUGGEST_TEXT);
            let photo = d["photo"].as_str().filter(|f| !f.is_empty() && f.len() <= 4096);
            ensure!(!words.is_empty() || photo.is_some(), "a suggestion needs words or a photo");
            let mime = d["mime"].as_str().filter(|m| m.starts_with("image/") && m.len() <= 64);
            json!({
                "text": words,
                "photo": photo,
                "mime": photo.and(mime),
                "at": d["at"].as_u64().filter(|t| *t > now).unwrap_or(0),
                "channel": opt_text(&d["channel"], 255),
            })
        }
        // An admin's answer to a suggestion: posted (now or at `at`) or not.
        "suggest_deal" => {
            let to = d["to"].as_str().unwrap_or_default();
            ensure!(matrix_sdk::ruma::EventId::parse(to).is_ok() || (to.len() <= 64 && !to.is_empty()), "bad message id");
            let act = d["act"].as_str().unwrap_or_default();
            ensure!(matches!(act, "accept" | "decline"), "bad answer");
            json!({
                "to": to,
                "act": act,
                "at": d["at"].as_u64().unwrap_or(0),
                "credit": d["credit"].as_bool().unwrap_or(false),
                "note": opt_text(&d["note"], 200),
            })
        }
        // 주사위 (tip 218): only which game. The result is worked out on
        // every phone from this message's server-given id, so the sender
        // cannot choose it and nothing else needs to travel.
        "dice" => json!({ "e": pick(&d["e"], &DICE, "🎲") }),
        _ => bail!("unknown card"),
    };
    ensure!(out.to_string().len() <= MAX_DATA, "card is too big");
    Ok(out)
}

/// Short text for notifications and old apps.
pub fn body(kind: &str, d: &Value) -> String {
    match kind {
        "faq" => format!(
            "❓ {}",
            d["title"]
                .as_str()
                .filter(|t| !t.is_empty())
                .unwrap_or("FAQ")
        ),
        "guide" => format!("🧭 {}", d["title"].as_str().unwrap_or_default()),
        "links" => format!("🔗 {}", d["text"].as_str().unwrap_or_default()),
        "rich" => format!("📝 {}", d["title"].as_str().unwrap_or_default()),
        "community" => format!("🏘️ {}", d["name"].as_str().unwrap_or_default()),
        "article" => crate::article::body(d),
        "lottery" => format!("🎁 {}", d["prize"].as_str().unwrap_or_default()),
        "form" => format!("📋 {}", d["title"].as_str().unwrap_or_default()),
        "checkin" => format!("🛟 {}", d["text"].as_str().unwrap_or_default()),
        "flow" => format!("🧩 {}", d["title"].as_str().unwrap_or_default()),
        "pin" => format!("📌 {}", d["text"].as_str().unwrap_or_default()),
        "import" => crate::import::body(d),
        "photo" => "🖼️".to_owned(),
        "suggest" => format!("✍️ {}", d["text"].as_str().unwrap_or_default().chars().take(80).collect::<String>()),
        "suggest_deal" => (if d["act"] == "accept" { "🤝" } else { "🙅" }).to_owned(),
        "stickers" => format!("🎨 {}", d["name"].as_str().unwrap_or_default()),
        "dice" => d["e"].as_str().unwrap_or("🎲").to_string(),
        _ => String::new(),
    }
}

/// Checks one answer; returns it cleaned ("" or null = take it back).
pub fn clean_reply(kind: &str, data: &Value, v: &Value) -> Option<Value> {
    if v.is_null() || v.as_str() == Some("") {
        return Some(Value::Null);
    }
    match kind {
        "lottery" => (v.as_str() == Some("in")).then(|| json!("in")),
        "checkin" => v
            .as_str()
            .filter(|s| matches!(*s, "ok" | "help"))
            .map(|s| json!(s)),
        // The result reached, only when the maker asked for numbers.
        "flow" => {
            let n = data["results"].as_array()?.len();
            (data["stats"].as_bool() == Some(true))
                .then(|| flow_target(v, 0, n))
                .flatten()
                .map(Value::String)
        }
        "form" => {
            let qs = data["questions"].as_array()?;
            let a = v.as_array()?;
            if a.len() != qs.len() {
                return None;
            }
            let mut out = vec![];
            for (q, x) in qs.iter().zip(a) {
                let s: String = x.as_str()?.trim().chars().take(1000).collect();
                if q["type"] == "choice"
                    && !s.is_empty()
                    && !q["options"]
                        .as_array()?
                        .iter()
                        .any(|o| o.as_str() == Some(&s))
                {
                    return None;
                }
                out.push(Value::String(s));
            }
            Some(Value::Array(out))
        }
        _ => None,
    }
}

/// Whether answers are closed at `now` (deadline passed).
pub fn past(data: &Value, now: u64) -> bool {
    let e = data["ends_at"].as_u64().unwrap_or(0);
    e > 0 && now >= e
}

/// Numbers to post from the maker's book (person -> answer).
pub fn counts(kind: &str, book: &HashMap<String, Value>) -> HashMap<String, u32> {
    let mut c = HashMap::new();
    for v in book.values() {
        let key = match kind {
            "form" => "sent".to_owned(),
            _ => v.as_str().unwrap_or_default().to_owned(),
        };
        if !key.is_empty() {
            *c.entry(key).or_insert(0) += 1;
        }
    }
    c
}

/// Picks winners with a fair shuffle from people who joined.
pub fn draw(book: &HashMap<String, Value>, n: usize, rng: &mut impl rand::Rng) -> Vec<String> {
    use rand::seq::SliceRandom;
    let mut people: Vec<String> = book
        .iter()
        .filter(|(_, v)| v.as_str() == Some("in"))
        .map(|(k, _)| k.clone())
        .collect();
    people.sort();
    people.shuffle(rng);
    people.truncate(n);
    people
}

/// Builds every card in these (decrypted) events. Only the maker's numbers
/// count. `mine` holds my own answers from this phone.
pub fn collect(events: &[Value], mine: &HashMap<String, Value>) -> HashMap<String, Card> {
    let mut cards: HashMap<String, (String, Card)> = HashMap::new();
    for v in events {
        let ty = v["type"].as_str().unwrap_or_default();
        let c = &v["content"];
        let sender = v["sender"].as_str().unwrap_or_default();
        match ty {
            START => {
                let (Some(id), Some(kind)) = (v["event_id"].as_str(), c["kind"].as_str()) else {
                    continue;
                };
                let ts = v["origin_server_ts"].as_u64().unwrap_or(0);
                // Check again on the reading side: never trust the sender's app.
                let Ok(data) = sanitize(kind, &c["data"], ts.saturating_sub(120_000)) else {
                    continue;
                };
                cards.insert(
                    id.into(),
                    (
                        sender.into(),
                        Card {
                            kind: kind.into(),
                            data: data.to_string(),
                            counts: HashMap::new(),
                            winners: vec![],
                            closed: false,
                            mine: mine
                                .get(id)
                                .filter(|m| !m.is_null())
                                .map(|m| m.to_string())
                                .unwrap_or_default(),
                            won: mine
                                .get(&format!("won:{id}"))
                                .and_then(Value::as_bool)
                                .unwrap_or(false),
                        },
                    ),
                );
            }
            TALLY => {
                let Some((maker, card)) = c["card"].as_str().and_then(|id| cards.get_mut(id))
                else {
                    continue;
                };
                if sender != maker.as_str() {
                    continue;
                }
                if let Some(m) = c["counts"].as_object() {
                    card.counts = m
                        .iter()
                        .filter_map(|(k, v)| {
                            Some((k.chars().take(16).collect(), v.as_u64()? as u32))
                        })
                        .take(8)
                        .collect();
                }
                if c["closed"].as_bool() == Some(true) {
                    card.closed = true;
                }
                if let Some(w) = c["winners"].as_array() {
                    card.winners = w
                        .iter()
                        .filter_map(|x| x.as_str().map(str::to_owned))
                        .take(MAX_WINNERS as usize)
                        .collect();
                }
            }
            _ => {}
        }
    }
    cards
        .into_iter()
        .map(|(k, (_, mut c))| {
            // The maker's own private list of winners.
            if c.winners.is_empty() {
                if let Some(w) = mine.get(&format!("winners:{k}")).and_then(Value::as_array) {
                    c.winners = w
                        .iter()
                        .filter_map(|x| x.as_str().map(str::to_owned))
                        .take(MAX_WINNERS as usize)
                        .collect();
                }
            }
            (k, c)
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ev(id: &str, ty: &str, sender: &str, content: Value) -> Value {
        json!({ "event_id": id, "type": ty, "sender": sender, "content": content, "origin_server_ts": 1_000_000 })
    }

    #[test]
    fn photo_suggestion_keeps_only_the_file_place_and_key() {
        let file = json!({ "url": "mxc://burumy.app/abc", "key": { "alg": "A256CTR", "k": "a-b_c", "kty": "oct" },
            "iv": "aXY=", "hashes": { "sha256": "c2hh" }, "v": "v2", "extra": "dropped" });
        let d = sanitize("photo", &json!({ "file": file, "mime": "image/gif", "name": "x" }), 0).unwrap();
        assert_eq!(d["mime"], "image/jpeg", "only jpeg / png");
        assert_eq!(d["file"]["url"], "mxc://burumy.app/abc");
        assert!(d.get("name").is_none() && d["file"].get("extra").is_none());
        assert_eq!(body("photo", &d), "🖼️");
        assert!(sanitize("photo", &json!({ "file": { "url": "https://evil" } }), 0).is_err());
        assert!(sanitize("photo", &json!({}), 0).is_err());
    }

    #[test]
    fn sanitize_trims_and_refuses_bad_data() {
        let d = sanitize(
            "links",
            &json!({ "text": "hi", "buttons": [
                { "label": "Site", "url": "https://burumy.app", "color": "blue" },
                { "label": "Evil", "url": "javascript:alert(1)" },
                { "label": "Space", "url": "https://a b.com" },
                { "label": "", "url": "https://x.com" },
                { "label": "Odd colour", "url": "https://x.com", "color": "#ff0000" }
            ]}),
            0,
        )
        .unwrap();
        let b = d["buttons"].as_array().unwrap();
        assert_eq!(b.len(), 2);
        assert_eq!(b[1]["color"], "", "unknown colour follows the shared style");
        assert_eq!(d["style"]["color"], "green");
        let many: Vec<Value> = (0..30)
            .map(|i| json!({ "label": format!("b{i}"), "url": "https://x.com", "row": i % 2 }))
            .collect();
        let d = sanitize("links", &json!({ "buttons": many }), 0).unwrap();
        assert_eq!(d["buttons"].as_array().unwrap().len(), 6, "3 per row");
        assert!(
            sanitize(
                "links",
                &json!({ "buttons": [{ "label": "x", "url": "file:///etc/passwd" }] }),
                0
            )
            .is_err()
        );
        assert!(sanitize("nope", &json!({}), 0).is_err());
        assert!(sanitize("lottery", &json!({ "prize": "커피", "winners": 0 }), 0).is_err());
        assert!(
            sanitize(
                "lottery",
                &json!({ "prize": "커피", "winners": 3, "ends_at": 10 }),
                1_000_000
            )
            .is_err(),
            "ends in the past"
        );
        let long = "가".repeat(5000);
        let f = sanitize("faq", &json!({ "items": [{ "q": long, "a": "a" }] }), 0).unwrap();
        assert_eq!(f["items"][0]["q"].as_str().unwrap().chars().count(), 200);
        let big: Vec<Value> = (0..50)
            .map(|_| json!({ "t": "p", "text": "가".repeat(2000) }))
            .collect();
        assert!(
            sanitize("rich", &json!({ "blocks": big }), 0).is_err(),
            "too big"
        );
    }

    #[test]
    fn replies_are_checked() {
        let form = sanitize("form", &json!({ "title": "신청", "questions": [{ "q": "이름" }, { "q": "티셔츠", "options": ["S", "M"] }] }), 0).unwrap();
        assert_eq!(
            clean_reply("form", &form, &json!(["민지", "M"])),
            Some(json!(["민지", "M"]))
        );
        assert_eq!(
            clean_reply("form", &form, &json!(["민지", "XL"])),
            None,
            "not an option"
        );
        assert_eq!(
            clean_reply("form", &form, &json!(["민지"])),
            None,
            "missing answer"
        );
        assert_eq!(
            clean_reply("lottery", &json!({}), &json!("in")),
            Some(json!("in"))
        );
        assert_eq!(clean_reply("lottery", &json!({}), &json!("win")), None);
        assert_eq!(
            clean_reply("checkin", &json!({}), &json!("help")),
            Some(json!("help"))
        );
        assert_eq!(clean_reply("faq", &json!({}), &json!("in")), None);
        assert_eq!(
            clean_reply("checkin", &json!({}), &json!("")),
            Some(Value::Null)
        );
    }

    #[test]
    fn only_makers_numbers_and_fair_draw() {
        let start = json!({ "kind": "lottery", "data": { "prize": "커피", "winners": 2 } });
        let evs = vec![
            ev("$c", START, "@a", start),
            ev(
                "$t",
                TALLY,
                "@evil",
                json!({ "card": "$c", "counts": { "in": 99 }, "winners": ["@evil"], "closed": true }),
            ),
            ev(
                "$u",
                TALLY,
                "@a",
                json!({ "card": "$c", "counts": { "in": 3 } }),
            ),
        ];
        let c = &collect(&evs, &HashMap::from([("$c".to_string(), json!("in"))]))["$c"];
        assert_eq!(c.counts["in"], 3);
        assert!(!c.closed && c.winners.is_empty());
        assert_eq!(c.mine, "\"in\"");

        let book: HashMap<String, Value> = [("@x", "in"), ("@y", "in"), ("@z", "in"), ("@q", "")]
            .iter()
            .map(|(k, v)| (k.to_string(), json!(v)))
            .collect();
        let w = draw(&book, 2, &mut rand::thread_rng());
        assert_eq!(w.len(), 2);
        assert!(!w.contains(&"@q".to_string()));
        assert_eq!(counts("lottery", &book)["in"], 3);
    }

    #[test]
    fn flow_checks_targets_paths_and_answers() {
        let good = json!({
            "title": "오늘 뭐 볼까?",
            "steps": [
                { "q": "기분은?", "choices": [
                    { "label": "신나게", "to": "s1" },
                    { "label": "잔잔하게", "to": "r1" },
                    { "label": "없는 곳", "to": "s9" },
                    { "label": "이상한", "to": "x1" },
                    { "label": "앞에 0", "to": "r01" },
                    { "label": "", "to": "r0" }
                ]},
                { "q": "누구랑?", "choices": [{ "label": "친구", "to": "r0" }, { "label": "처음으로", "to": "s0" }] }
            ],
            "results": [
                { "title": "액션", "text": "크게 봐요", "link": { "label": "예고편", "url": "https://x.com/t" } },
                { "title": "다큐", "link": { "label": "나쁜", "url": "javascript:alert(1)" } }
            ]
        });
        let d = sanitize("flow", &good, 0).unwrap();
        let c0 = d["steps"][0]["choices"].as_array().unwrap();
        assert_eq!(c0.len(), 2, "bad targets and blank labels are dropped");
        assert_eq!(d["results"][0]["link"]["url"], "https://x.com/t");
        assert!(d["results"][1]["link"].is_null(), "unsafe link dropped");
        assert_eq!(d["stats"], true, "numbers on by default");
        assert_eq!(body("flow", &d), "🧩 오늘 뭐 볼까?");

        // Answers: only an existing result, only with stats on.
        assert_eq!(clean_reply("flow", &d, &json!("r1")), Some(json!("r1")));
        assert_eq!(clean_reply("flow", &d, &json!("r2")), None);
        assert_eq!(clean_reply("flow", &d, &json!("s0")), None);
        assert_eq!(clean_reply("flow", &d, &json!(["r0"])), None);
        let mut off = good.clone();
        off["stats"] = json!(false);
        let d_off = sanitize("flow", &off, 0).unwrap();
        assert_eq!(clean_reply("flow", &d_off, &json!("r0")), None);

        // A loop with no way out, a blank result, no questions: refused.
        let looped = json!({ "title": "t", "steps": [
            { "q": "a", "choices": [{ "label": "b", "to": "s1" }] },
            { "q": "b", "choices": [{ "label": "a", "to": "s0" }] }
        ], "results": [{ "title": "r" }] });
        assert!(sanitize("flow", &looped, 0).is_err());
        let mut blank = good.clone();
        blank["results"][1]["title"] = json!(" ");
        assert!(sanitize("flow", &blank, 0).is_err());
        assert!(sanitize("flow", &json!({ "title": "t", "steps": [], "results": [{ "title": "r" }] }), 0).is_err());
        // Too many pieces are cut, not trusted.
        let many = json!({ "title": "t",
            "steps": (0..30).map(|_| json!({ "q": "q", "choices": (0..20).map(|_| json!({ "label": "x", "to": "r0" })).collect::<Vec<_>>() })).collect::<Vec<_>>(),
            "results": (0..30).map(|_| json!({ "title": "r" })).collect::<Vec<_>>() });
        let d = sanitize("flow", &many, 0).unwrap();
        assert_eq!(d["steps"].as_array().unwrap().len(), FLOW_STEPS);
        assert_eq!(d["steps"][0]["choices"].as_array().unwrap().len(), FLOW_CHOICES);
        assert_eq!(d["results"].as_array().unwrap().len(), FLOW_RESULTS);
    }

    #[test]
    fn flow_book_never_keeps_ids() {
        let k = book_key("flow", "$card", "@mina:test");
        assert_eq!(k.len(), 32);
        assert!(!k.contains("mina"));
        assert_eq!(k, book_key("flow", "$card", "@mina:test"), "same person counts once");
        assert_ne!(k, book_key("flow", "$other", "@mina:test"), "not linkable across cards");
        assert_eq!(book_key("form", "$card", "@mina:test"), "@mina:test");
        let mut book = HashMap::new();
        book.insert(k, json!("r1"));
        book.insert(book_key("flow", "$card", "@jun:test"), json!("r1"));
        assert_eq!(counts("flow", &book).get("r1"), Some(&2));
    }

    #[test]
    fn suggest_cards() {
        let d = sanitize("suggest", &json!({ "text": "  맛집 후기 ", "at": 5, "channel": "!c:x" }), 10).unwrap();
        assert_eq!(d["text"], "맛집 후기");
        // A time already past = any time.
        assert_eq!(d["at"], 0);
        assert!(sanitize("suggest", &json!({ "text": "" }), 0).is_err());
        let p = sanitize("suggest", &json!({ "photo": "{}", "mime": "text/html" }), 0).unwrap();
        assert!(p["mime"].is_null());
        assert!(sanitize("suggest_deal", &json!({ "to": "$e:x", "act": "accept", "at": 7 }), 0).is_ok());
        assert!(sanitize("suggest_deal", &json!({ "to": "$e:x", "act": "pay" }), 0).is_err());
        assert_eq!(body("suggest_deal", &json!({ "act": "decline" })), "🙅");
    }

    #[test]
    fn dice_keeps_only_the_game() {
        let d = sanitize("dice", &json!({ "e": "🎯", "value": 6 }), 0).unwrap();
        assert_eq!(d, json!({ "e": "🎯" }));
        let d = sanitize("dice", &json!({ "e": "<b>" }), 0).unwrap();
        assert_eq!(d, json!({ "e": "🎲" }));
        assert_eq!(body("dice", &d), "🎲");
    }
}

#[cfg(test)]
mod sticker_set_tests {
    use super::{body, sanitize};
    use serde_json::json;

    fn file() -> serde_json::Value {
        json!({
            "url": "mxc://s/abc", "key": {"k": "a2V5", "alg": "A256CTR", "kty": "oct", "key_ops": ["encrypt", "decrypt"], "ext": true},
            "iv": "aXY", "hashes": {"sha256": "c2hh"}, "v": "v2"
        })
    }

    #[test]
    fn a_set_card_carries_only_the_file_name_and_size() {
        let c = sanitize(
            "stickers",
            &json!({ "file": file(), "name": " 우리 강아지 ", "n": 5, "png": "AAAA", "kind": "x" }),
            0,
        )
        .unwrap();
        assert_eq!(c["name"], "우리 강아지");
        assert_eq!(c["n"], 5);
        assert_eq!(c["kind"], "sticker");
        assert!(c.get("png").is_none(), "no pictures inside the card");
        assert_eq!(body("stickers", &c), "🎨 우리 강아지");
    }

    #[test]
    fn bad_set_cards_are_refused() {
        assert!(
            sanitize(
                "stickers",
                &json!({ "file": { "url": "https://evil" }, "name": "a", "n": 1 }),
                0
            )
            .is_err()
        );
        assert!(
            sanitize(
                "stickers",
                &json!({ "file": file(), "name": "", "n": 1 }),
                0
            )
            .is_err()
        );
        assert!(
            sanitize(
                "stickers",
                &json!({ "file": file(), "name": "a", "n": 0 }),
                0
            )
            .is_err()
        );
        assert!(
            sanitize(
                "stickers",
                &json!({ "file": file(), "name": "a", "n": 51 }),
                0
            )
            .is_err()
        );
    }
}
