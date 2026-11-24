// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Channel and group "cards": FAQ, guide menu, link buttons, formatted
//! posts, giveaways, application forms and safety check-ins.
//!
//! A card is one encrypted room event with checked, size-limited data.
//! Answers (joining a giveaway, a form, "I'm safe") never go into the room:
//! like anonymous poll votes they go only to the maker's phone(s) as
//! encrypted device messages, because in channels members must not see
//! each other. The maker's phone keeps who answered (it needs that to pick
//! winners or read forms) and posts only numbers, and winners at the end.

use std::collections::HashMap;

use anyhow::{Result, bail, ensure};
use serde_json::{Value, json};

pub const START: &str = "app.burumy.card";
pub const REPLY: &str = "app.burumy.card.reply";
pub const TALLY: &str = "app.burumy.card.tally";
/// "You won" sent only to each winner's phones when names stay private.
pub const WON: &str = "app.burumy.card.won";
pub const MAX_DATA: usize = 24 * 1024;
pub const MAX_WINNERS: u64 = 100;

/// Kinds people answer (the others are read-only).
pub fn answered(kind: &str) -> bool {
    matches!(kind, "lottery" | "form" | "checkin")
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
        "lottery" => format!("🎁 {}", d["prize"].as_str().unwrap_or_default()),
        "form" => format!("📋 {}", d["title"].as_str().unwrap_or_default()),
        "checkin" => format!("🛟 {}", d["text"].as_str().unwrap_or_default()),
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
}
