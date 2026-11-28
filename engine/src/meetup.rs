// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Plans ("일정") inside encrypted chats: a title, a time, a place, and who
//! is coming. Every answer is an encrypted room event; each person's latest
//! answer counts, and only the maker can cancel the plan.

use std::collections::HashMap;

pub const START: &str = "app.burumy.meetup";
pub const ANSWER: &str = "app.burumy.meetup.answer";
pub const CANCEL: &str = "app.burumy.meetup.cancel";
pub const MAX_TEXT: usize = 200;
/// Latest start time we accept (end of year 9999); anything later is junk
/// that would break date display on phones.
pub const MAX_TIME: u64 = 253_402_300_799_999;

#[derive(Debug, Clone, PartialEq)]
pub struct Meetup {
    pub title: String,
    /// Start time, milliseconds since 1970.
    pub starts_at: u64,
    pub place: Option<String>,
    /// End time (ms since 1970), after the start; None = open-ended.
    pub ends_at: Option<u64>,
    pub cancelled: bool,
    /// Person -> "yes" / "no" / "maybe".
    pub answers: HashMap<String, String>,
}

pub fn clean(text: &str) -> Option<String> {
    let t = text.trim();
    (!t.is_empty()).then(|| t.chars().take(MAX_TEXT).collect())
}

pub fn start_content(
    title: &str,
    starts_at: u64,
    ends_at: Option<u64>,
    place: Option<&str>,
) -> serde_json::Value {
    let mut c = serde_json::json!({
        "body": format!("📅 {title}"),
        "title": title,
        "starts_at": starts_at,
        "place": place,
    });
    if let Some(end) = ends_at.filter(|e| *e > starts_at && *e <= MAX_TIME) {
        c["ends_at"] = end.into();
    }
    c
}

/// Most people one person can bring along ("yes+3" = me and 3 more).
pub const MAX_GUESTS: u32 = 9;

/// The extra people in a "yes+N" answer (0 for a plain answer).
pub fn guests(answer: &str) -> u32 {
    answer
        .strip_prefix("yes+")
        .and_then(|n| n.parse::<u32>().ok())
        .filter(|n| (1..=MAX_GUESTS).contains(n))
        .unwrap_or(0)
}

pub fn valid_answer(a: &str) -> bool {
    matches!(a, "yes" | "no" | "maybe" | "") || guests(a) > 0
}

/// "yes+2" counts as "yes" (with 2 guests).
pub fn base_answer(a: &str) -> &str {
    if guests(a) > 0 { "yes" } else { a }
}

/// Builds every plan in these (decrypted) events, in order.
pub fn collect(events: &[serde_json::Value]) -> HashMap<String, Meetup> {
    let mut plans: HashMap<String, (String, Meetup)> = HashMap::new();
    for v in events {
        let ty = v["type"].as_str().unwrap_or_default();
        let c = &v["content"];
        let sender = v["sender"].as_str().unwrap_or_default();
        match ty {
            START => {
                let (Some(id), Some(title), Some(at)) = (
                    v["event_id"].as_str(),
                    c["title"].as_str().and_then(clean),
                    c["starts_at"].as_u64().filter(|t| *t <= MAX_TIME),
                ) else {
                    continue;
                };
                let place = c["place"].as_str().and_then(clean);
                let ends_at = c["ends_at"].as_u64().filter(|e| *e > at && *e <= MAX_TIME);
                plans.insert(
                    id.into(),
                    (
                        sender.into(),
                        Meetup {
                            title,
                            starts_at: at,
                            place,
                            ends_at,
                            cancelled: false,
                            answers: HashMap::new(),
                        },
                    ),
                );
            }
            ANSWER | CANCEL => {
                let Some((maker, m)) = c["meetup"].as_str().and_then(|id| plans.get_mut(id)) else {
                    continue;
                };
                if ty == CANCEL {
                    if sender == maker.as_str() {
                        m.cancelled = true;
                    }
                    continue;
                }
                if m.cancelled {
                    continue;
                }
                let a = c["answer"].as_str().unwrap_or_default();
                if !valid_answer(a) {
                    continue;
                }
                if a.is_empty() {
                    m.answers.remove(sender);
                } else {
                    m.answers.insert(sender.into(), a.into());
                }
            }
            _ => {}
        }
    }
    plans.into_iter().map(|(k, (_, m))| (k, m)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn ev(id: &str, ty: &str, sender: &str, content: serde_json::Value) -> serde_json::Value {
        json!({ "event_id": id, "type": ty, "sender": sender, "content": content })
    }

    #[test]
    fn latest_answer_counts_and_only_maker_cancels() {
        let evs = vec![
            ev(
                "$m",
                START,
                "@me:x",
                start_content("저녁", 1_800_000_000_000, None, Some("강남")),
            ),
            ev(
                "$1",
                ANSWER,
                "@bob:x",
                json!({ "meetup": "$m", "answer": "maybe" }),
            ),
            ev(
                "$2",
                ANSWER,
                "@bob:x",
                json!({ "meetup": "$m", "answer": "yes" }),
            ),
            ev(
                "$3",
                ANSWER,
                "@amy:x",
                json!({ "meetup": "$m", "answer": "hack" }),
            ),
            ev(
                "$4",
                ANSWER,
                "@amy:x",
                json!({ "meetup": "$m", "answer": "no" }),
            ),
            ev(
                "$5",
                ANSWER,
                "@amy:x",
                json!({ "meetup": "$m", "answer": "" }),
            ),
            ev("$6", CANCEL, "@bob:x", json!({ "meetup": "$m" })),
        ];
        let m = &collect(&evs)["$m"];
        assert_eq!(m.answers.get("@bob:x").map(String::as_str), Some("yes"));
        assert!(!m.answers.contains_key("@amy:x"));
        assert!(!m.cancelled, "only the maker cancels");
        let mut evs = evs;
        evs.push(ev("$7", CANCEL, "@me:x", json!({ "meetup": "$m" })));
        evs.push(ev(
            "$8",
            ANSWER,
            "@amy:x",
            json!({ "meetup": "$m", "answer": "yes" }),
        ));
        let m = &collect(&evs)["$m"];
        assert!(m.cancelled);
        assert!(!m.answers.contains_key("@amy:x"), "no answers after cancel");
        assert_eq!(m.place.as_deref(), Some("강남"));
    }

    #[test]
    fn absurd_times_are_dropped() {
        let evs = vec![ev(
            "$m",
            START,
            "@me:x",
            start_content("x", u64::MAX, None, None),
        )];
        assert!(collect(&evs).is_empty());
    }

    #[test]
    fn guests_and_end_time() {
        assert!(valid_answer("yes+3"));
        assert!(!valid_answer("yes+0"));
        assert!(!valid_answer("yes+10"));
        assert!(!valid_answer("no+1"));
        assert_eq!(guests("yes+2"), 2);
        assert_eq!(base_answer("yes+2"), "yes");
        let evs = vec![
            ev(
                "$m",
                START,
                "@me:x",
                start_content("저녁", 1_800_000_000_000, Some(1_800_007_200_000), None),
            ),
            ev(
                "$1",
                ANSWER,
                "@bob:x",
                json!({ "meetup": "$m", "answer": "yes+2" }),
            ),
        ];
        let m = &collect(&evs)["$m"];
        assert_eq!(m.ends_at, Some(1_800_007_200_000));
        assert_eq!(m.answers.get("@bob:x").map(String::as_str), Some("yes+2"));
        // An end before the start is dropped.
        let c = start_content("x", 1_800_000_000_000, Some(1_000), None);
        assert!(c.get("ends_at").is_none());
    }
}
