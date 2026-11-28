// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Polls inside encrypted chats.
//!
//! Open polls: each vote is an encrypted room event, so members can see who
//! chose what (like Telegram's public polls).
//!
//! Anonymous polls (channels always): a vote is NOT posted in the room. It
//! goes only to the poll maker's phone(s) as an encrypted device message.
//! That phone keeps one salted fingerprint per voter (so a vote can be
//! changed but never counted twice), never the name, and posts just the
//! numbers back into the chat. Other members can't see who voted or what;
//! the server sees neither.

use std::collections::HashMap;

use serde::{Deserialize, Serialize};

pub const START: &str = "im.securemessenger.poll.start";
pub const VOTE: &str = "im.securemessenger.poll.vote";
pub const TALLY: &str = "im.securemessenger.poll.tally";
pub const END: &str = "im.securemessenger.poll.end";
/// A member adds an answer (only when the maker allowed it).
pub const OPTION: &str = "im.securemessenger.poll.option";
/// The maker writes up to 10 answers; members can add up to 12 in total.
pub const MAX_ANSWERS: usize = 10;
pub const MAX_WITH_ADDED: usize = 12;
pub const MAX_ANSWER_TEXT: usize = 100;
pub const MAX_DESCRIPTION: usize = 1024;

#[derive(Debug, Clone, PartialEq)]
pub struct PollAnswer {
    pub id: String,
    pub text: String,
    pub votes: u32,
    /// An encrypted photo is attached (fetched separately).
    pub media: bool,
    /// A built-in sticker id ("" = none).
    pub sticker: String,
    /// A place as "geo:lat,lon" ("" = none).
    pub geo: String,
    /// A member added this answer (their user id).
    pub added_by: Option<String>,
}

impl PollAnswer {
    fn plain(id: &str, text: &str) -> Self {
        PollAnswer {
            id: id.into(),
            text: text.into(),
            votes: 0,
            media: false,
            sticker: String::new(),
            geo: String::new(),
            added_by: None,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct Poll {
    pub question: String,
    pub answers: Vec<PollAnswer>,
    pub anonymous: bool,
    pub multiple: bool,
    pub closed: bool,
    /// People who voted (open polls) or the maker's latest count (anonymous).
    pub voters: u32,
    /// What I chose (from the chat for open polls, from this phone for anonymous).
    pub mine: Vec<String>,
    /// Open polls only: who chose each answer.
    pub who: HashMap<String, Vec<String>>,
    /// Quiz: the right answer's id (shown only after voting) and why.
    pub correct: Option<String>,
    pub explain: String,
    /// Voting stops at this time (ms since 1970), 0 = no deadline.
    pub close_at: u64,
    /// Words under the question, and whether a photo is attached to them.
    pub description: String,
    pub media: bool,
    /// Members may add answers.
    pub add_options: bool,
    /// People may change or take back their vote (quizzes never).
    pub change_vote: bool,
    /// Each person sees the answers in their own random order.
    pub shuffle: bool,
    /// Numbers stay hidden until the poll ends. Anonymous polls: the maker's
    /// phone posts no numbers before the end. Open polls: votes are in the
    /// chat, so only the app hides them.
    pub hide_results: bool,
}

/// Settings and extras the app sends with a new poll (JSON):
/// {"description", "add_options", "change_vote", "shuffle", "hide_results",
///  "answers": [{"sticker": id, "geo": "geo:lat,lon"}] (same order as the answers)}
pub fn apply_extras(c: &mut serde_json::Value, extra: &serde_json::Value, quiz: bool) {
    let d: String = extra["description"]
        .as_str()
        .unwrap_or_default()
        .trim()
        .chars()
        .take(MAX_DESCRIPTION)
        .collect();
    if !d.is_empty() {
        c["description"] = d.into();
    }
    for k in ["add_options", "shuffle", "hide_results"] {
        if extra[k].as_bool() == Some(true) {
            c[k] = true.into();
        }
    }
    // Changing a vote is on unless turned off; a quiz answer is always final.
    if quiz || extra["change_vote"].as_bool() == Some(false) {
        c["change_vote"] = false.into();
    }
    if let (Some(list), Some(answers)) = (extra["answers"].as_array(), c["answers"].as_array_mut()) {
        for (a, x) in answers.iter_mut().zip(list) {
            if let Some(st) = x["sticker"].as_str().filter(|s| valid_sticker(s)) {
                a["sticker"] = st.into();
            } else if let Some(g) = x["geo"].as_str().and_then(clean_geo) {
                a["geo"] = g.into();
            }
        }
    }
}

/// Built-in sticker ids are short lower-case names (no paths, no links).
pub fn valid_sticker(s: &str) -> bool {
    (1..=64).contains(&s.len())
        && s.bytes()
            .all(|b| b.is_ascii_lowercase() || b.is_ascii_digit() || b == b'_')
}

/// "geo:lat,lon" with sane numbers, rounded to about 1 m.
pub fn clean_geo(s: &str) -> Option<String> {
    let rest = s.strip_prefix("geo:")?;
    let rest = rest.split(';').next()?;
    let (a, b) = rest.split_once(',')?;
    let (lat, lon): (f64, f64) = (a.trim().parse().ok()?, b.trim().parse().ok()?);
    if !lat.is_finite() || !lon.is_finite() || lat.abs() > 90.0 || lon.abs() > 180.0 {
        return None;
    }
    Some(format!("geo:{lat:.5},{lon:.5}"))
}

fn media_ok(v: &serde_json::Value) -> bool {
    v["file"]["url"].is_string() && v["mimetype"].as_str().is_some_and(|m| m.starts_with("image/"))
}

/// The answer ids a maker's phone accepts: the maker's answers plus the ones
/// members added in time.
pub fn answer_ids(events: &[serde_json::Value], pid: &str) -> Vec<String> {
    let me = "";
    collect(events, me, &HashMap::new())
        .remove(pid)
        .map(|p| p.answers.into_iter().map(|a| a.id).collect())
        .unwrap_or_default()
}

/// Quiz explanation limit and the longest deadline.
pub const MAX_EXPLAIN: usize = 200;
pub const MAX_DEADLINE_MS: u64 = 30 * 24 * 3600 * 1000;

/// Whether the deadline has passed at `now` (ms).
pub fn past(close_at: u64, now: u64) -> bool {
    close_at > 0 && now >= close_at
}

/// A poll with an optional right answer (quiz, one choice only) and an
/// optional deadline.
pub fn start_content_ext(
    question: &str,
    answers: &[String],
    anonymous: bool,
    multiple: bool,
    quiz: Option<usize>,
    explain: &str,
    close_at: u64,
) -> serde_json::Value {
    let mut c = start_content(question, answers, anonymous, multiple && quiz.is_none());
    if let Some(i) = quiz.filter(|i| *i < answers.len()) {
        c["quiz"] = serde_json::json!(format!("a{i}"));
        let e: String = explain.trim().chars().take(MAX_EXPLAIN).collect();
        if !e.is_empty() {
            c["explain"] = serde_json::json!(e);
        }
    }
    if close_at > 0 {
        c["close_at"] = serde_json::json!(close_at);
    }
    c
}

pub fn start_content(
    question: &str,
    answers: &[String],
    anonymous: bool,
    multiple: bool,
) -> serde_json::Value {
    let list: Vec<_> = answers
        .iter()
        .enumerate()
        .map(|(i, a)| serde_json::json!({ "id": format!("a{i}"), "text": a }))
        .collect();
    serde_json::json!({
        "body": format!("📊 {question}"),
        "question": question,
        "answers": list,
        "anonymous": anonymous,
        "multiple": multiple,
    })
}

/// Per-poll state kept only on the maker's phone.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct MakerBook {
    pub salt: String,
    /// salted fingerprint of the voter -> choices
    pub votes: HashMap<String, Vec<String>>,
}

impl MakerBook {
    /// Salted SHA-256 of the voter id; the salt never leaves this phone, so
    /// the stored list can't be turned back into names.
    pub fn fingerprint(&self, user: &str) -> String {
        use sha2::{Digest, Sha256};
        let mut h = Sha256::new();
        h.update(self.salt.as_bytes());
        h.update([0u8]);
        h.update(user.as_bytes());
        h.finalize()
            .iter()
            .take(16)
            .map(|b| format!("{b:02x}"))
            .collect()
    }

    pub fn counts(&self) -> (HashMap<String, u32>, u32) {
        let mut c = HashMap::new();
        for choices in self.votes.values() {
            for a in choices {
                *c.entry(a.clone()).or_insert(0) += 1;
            }
        }
        (
            c,
            self.votes.values().filter(|v| !v.is_empty()).count() as u32,
        )
    }
}

/// Builds every poll's current state from the chat's raw events (oldest
/// first). `my_anon` holds my own anonymous choices from this phone.
pub fn collect(
    events: &[serde_json::Value],
    me: &str,
    my_anon: &HashMap<String, Vec<String>>,
) -> HashMap<String, Poll> {
    let mut polls: HashMap<String, (String, Poll)> = HashMap::new();
    for v in events {
        if v["type"].as_str() != Some(START) {
            continue;
        }
        let c = &v["content"];
        let (Some(id), Some(maker), Some(q)) = (
            v["event_id"].as_str(),
            v["sender"].as_str(),
            c["question"].as_str(),
        ) else {
            continue;
        };
        let answers: Vec<PollAnswer> = c["answers"]
            .as_array()
            .map(|a| {
                a.iter()
                    .take(MAX_ANSWERS)
                    .filter_map(|x| {
                        let mut a = PollAnswer::plain(x["id"].as_str()?, x["text"].as_str()?);
                        a.media = media_ok(&x["media"]);
                        a.sticker = x["sticker"]
                            .as_str()
                            .filter(|s| valid_sticker(s))
                            .unwrap_or_default()
                            .into();
                        a.geo = x["geo"].as_str().and_then(clean_geo).unwrap_or_default();
                        Some(a)
                    })
                    .collect()
            })
            .unwrap_or_default();
        if answers.len() < 2 {
            continue;
        }
        let anonymous = c["anonymous"].as_bool().unwrap_or(false);
        let correct = c["quiz"]
            .as_str()
            .filter(|q| answers.iter().any(|a| a.id == *q))
            .map(str::to_owned);
        let poll = Poll {
            question: q.into(),
            anonymous,
            multiple: c["multiple"].as_bool().unwrap_or(false) && correct.is_none(),
            closed: false,
            voters: 0,
            mine: if anonymous {
                my_anon.get(id).cloned().unwrap_or_default()
            } else {
                vec![]
            },
            who: HashMap::new(),
            explain: if correct.is_some() {
                c["explain"]
                    .as_str()
                    .unwrap_or_default()
                    .chars()
                    .take(MAX_EXPLAIN)
                    .collect()
            } else {
                String::new()
            },
            change_vote: correct.is_none() && c["change_vote"].as_bool() != Some(false),
            correct,
            close_at: c["close_at"].as_u64().unwrap_or(0),
            answers,
            description: c["description"]
                .as_str()
                .unwrap_or_default()
                .chars()
                .take(MAX_DESCRIPTION)
                .collect(),
            media: media_ok(&c["media"]),
            add_options: c["add_options"].as_bool() == Some(true),
            shuffle: c["shuffle"].as_bool() == Some(true),
            hide_results: c["hide_results"].as_bool() == Some(true),
        };
        polls.insert(id.into(), (maker.into(), poll));
    }
    // Open votes: the latest vote of each person counts.
    let mut open: HashMap<String, HashMap<String, Vec<String>>> = HashMap::new();
    for v in events {
        let ty = v["type"].as_str().unwrap_or_default();
        let c = &v["content"];
        let Some(pid) = c["poll"].as_str() else {
            continue;
        };
        let Some((maker, p)) = polls.get_mut(pid) else {
            continue;
        };
        let sender = v["sender"].as_str().unwrap_or_default();
        let ts = v["origin_server_ts"].as_u64().unwrap_or(0);
        match ty {
            // A member's added answer: only while open, up to 12, no repeats.
            OPTION if p.add_options && !p.closed && !past(p.close_at, ts) => {
                let Some(eid) = v["event_id"].as_str() else {
                    continue;
                };
                let text: String = c["text"].as_str().unwrap_or_default().trim().to_owned();
                if text.is_empty()
                    || text.chars().count() > MAX_ANSWER_TEXT
                    || p.answers.len() >= MAX_WITH_ADDED
                    || p.answers.iter().any(|a| a.text.to_lowercase() == text.to_lowercase())
                {
                    continue;
                }
                let mut a = PollAnswer::plain(eid, &text);
                a.added_by = Some(sender.into());
                p.answers.push(a);
            }
            // Votes after the deadline don't count (the time is the server's).
            VOTE if !p.anonymous
                && !p.closed
                && !past(p.close_at, v["origin_server_ts"].as_u64().unwrap_or(0)) =>
            {
                let mut ch: Vec<String> = c["choices"]
                    .as_array()
                    .map(|a| {
                        a.iter()
                            .filter_map(|x| x.as_str().map(str::to_owned))
                            .collect()
                    })
                    .unwrap_or_default();
                ch.retain(|a| p.answers.iter().any(|x| &x.id == a));
                if !p.multiple {
                    ch.truncate(1);
                }
                let book = open.entry(pid.into()).or_default();
                // A quiz answer (or a poll with changes off) can't be changed
                // or taken back.
                if !p.change_vote && book.get(sender).is_some_and(|c| !c.is_empty()) {
                    continue;
                }
                book.insert(sender.into(), ch);
            }
            TALLY if p.anonymous && sender == maker.as_str() => {
                for a in p.answers.iter_mut() {
                    a.votes = c["counts"][&a.id].as_u64().unwrap_or(0) as u32;
                }
                p.voters = c["voters"].as_u64().unwrap_or(0) as u32;
            }
            END if sender == maker.as_str() => p.closed = true,
            _ => {}
        }
    }
    for (pid, by) in open {
        let Some((_, p)) = polls.get_mut(&pid) else {
            continue;
        };
        for (user, ch) in &by {
            for a in p.answers.iter_mut() {
                if ch.contains(&a.id) {
                    a.votes += 1;
                    p.who.entry(a.id.clone()).or_default().push(user.clone());
                }
            }
            if user == me {
                p.mine = ch.clone();
            }
        }
        p.voters = by.values().filter(|c| !c.is_empty()).count() as u32;
    }
    polls.into_iter().map(|(k, (_, p))| (k, p)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ev(id: &str, ty: &str, sender: &str, content: serde_json::Value) -> serde_json::Value {
        serde_json::json!({ "event_id": id, "type": ty, "sender": sender, "content": content })
    }

    #[test]
    fn open_poll_counts_latest_vote() {
        let start = start_content("점심?", &["국수".into(), "밥".into()], false, false);
        let evs = vec![
            ev("$p", START, "@a", start),
            ev(
                "$1",
                VOTE,
                "@b",
                serde_json::json!({ "poll": "$p", "choices": ["a0"] }),
            ),
            ev(
                "$2",
                VOTE,
                "@me",
                serde_json::json!({ "poll": "$p", "choices": ["a0", "a1"] }),
            ),
            ev(
                "$3",
                VOTE,
                "@b",
                serde_json::json!({ "poll": "$p", "choices": ["a1"] }),
            ),
            ev(
                "$4",
                VOTE,
                "@c",
                serde_json::json!({ "poll": "$p", "choices": ["zz"] }),
            ),
        ];
        let p = &collect(&evs, "@me", &HashMap::new())["$p"];
        assert_eq!(
            p.answers.iter().map(|a| a.votes).collect::<Vec<_>>(),
            vec![1, 1]
        );
        assert_eq!(p.mine, vec!["a0".to_string()]); // single choice keeps the first
        assert_eq!(p.voters, 2);
        assert_eq!(p.who["a1"], vec!["@b".to_string()]);
    }

    #[test]
    fn anonymous_poll_shows_only_makers_numbers() {
        let start = start_content("q", &["x".into(), "y".into()], true, false);
        let evs = vec![
            ev("$p", START, "@a", start),
            ev(
                "$1",
                VOTE,
                "@b",
                serde_json::json!({ "poll": "$p", "choices": ["a0"] }),
            ), // ignored: no room votes
            ev(
                "$t",
                TALLY,
                "@evil",
                serde_json::json!({ "poll": "$p", "counts": { "a0": 99 }, "voters": 99 }),
            ),
            ev(
                "$u",
                TALLY,
                "@a",
                serde_json::json!({ "poll": "$p", "counts": { "a0": 2, "a1": 1 }, "voters": 3 }),
            ),
            ev("$e", END, "@b", serde_json::json!({ "poll": "$p" })),
        ];
        let mine = HashMap::from([("$p".to_string(), vec!["a1".to_string()])]);
        let p = &collect(&evs, "@me", &mine)["$p"];
        assert_eq!(
            p.answers.iter().map(|a| a.votes).collect::<Vec<_>>(),
            vec![2, 1]
        );
        assert_eq!(p.voters, 3);
        assert!(!p.closed, "only the maker can close");
        assert!(p.who.is_empty());
        assert_eq!(p.mine, vec!["a1".to_string()]);
    }

    #[test]
    fn quiz_first_answer_sticks_and_deadline_stops_votes() {
        let start = start_content_ext(
            "2+2?",
            &["3".into(), "4".into()],
            false,
            true,
            Some(1),
            "기본 덧셈",
            1000,
        );
        assert_eq!(start["multiple"], false, "a quiz is one choice");
        let mut late = ev(
            "$4",
            VOTE,
            "@c",
            serde_json::json!({ "poll": "$p", "choices": ["a1"] }),
        );
        late["origin_server_ts"] = serde_json::json!(1000);
        let mut ok = ev(
            "$1",
            VOTE,
            "@me",
            serde_json::json!({ "poll": "$p", "choices": ["a0"] }),
        );
        ok["origin_server_ts"] = serde_json::json!(10);
        let mut change = ev(
            "$2",
            VOTE,
            "@me",
            serde_json::json!({ "poll": "$p", "choices": ["a1"] }),
        );
        change["origin_server_ts"] = serde_json::json!(20);
        let evs = vec![ev("$p", START, "@a", start), ok, change, late];
        let p = &collect(&evs, "@me", &HashMap::new())["$p"];
        assert_eq!(p.correct.as_deref(), Some("a1"));
        assert_eq!(p.explain, "기본 덧셈");
        assert_eq!(p.mine, vec!["a0".to_string()], "first quiz answer stays");
        assert_eq!(p.voters, 1, "late vote ignored");
        assert!(past(p.close_at, 1000) && !past(p.close_at, 999) && !past(0, u64::MAX));
    }

    #[test]
    fn quiz_with_unknown_answer_is_a_plain_poll() {
        let mut start = start_content("q", &["x".into(), "y".into()], false, false);
        start["quiz"] = serde_json::json!("a9");
        let p = &collect(&[ev("$p", START, "@a", start)], "@me", &HashMap::new())["$p"];
        assert!(p.correct.is_none() && p.explain.is_empty());
    }

    #[test]
    fn maker_book_dedupes() {
        let mut b = MakerBook {
            salt: "s".into(),
            ..Default::default()
        };
        let f = b.fingerprint("@b");
        b.votes.insert(f.clone(), vec!["a0".into()]);
        b.votes.insert(f, vec!["a1".into()]);
        b.votes.insert(b.fingerprint("@c"), vec!["a1".into()]);
        let (c, n) = b.counts();
        assert_eq!((c.get("a0"), c["a1"], n), (None, 2, 2));
    }

    #[test]
    fn extras_added_answers_and_vote_lock() {
        let mut start = start_content("어디서?", &["강남".into(), "홍대".into()], false, false);
        apply_extras(
            &mut start,
            &serde_json::json!({
                "description": "  토요일 모임  ",
                "add_options": true,
                "change_vote": false,
                "shuffle": true,
                "hide_results": true,
                "answers": [{ "sticker": "buru_01_hello" }, { "geo": "geo:37.55634567,126.9229;u=20" }],
            }),
            false,
        );
        let add = |id: &str, who: &str, text: &str, ts: u64| {
            let mut e = ev(id, OPTION, who, serde_json::json!({ "poll": "$p", "text": text }));
            e["origin_server_ts"] = serde_json::json!(ts);
            e
        };
        let mut evs = vec![
            ev("$p", START, "@a", start),
            add("$o1", "@b", "성수", 1),
            add("$o2", "@c", " 강남 ", 2), // repeat: ignored
            add("$o3", "@c", "", 3),       // empty: ignored
            ev("$1", VOTE, "@me", serde_json::json!({ "poll": "$p", "choices": ["$o1"] })),
            ev("$2", VOTE, "@me", serde_json::json!({ "poll": "$p", "choices": ["a0"] })),
            ev("$3", VOTE, "@b", serde_json::json!({ "poll": "$p", "choices": [] })),
        ];
        for i in 0..20 {
            evs.push(add(&format!("$x{i}"), "@d", &format!("옵션{i}"), 10 + i));
        }
        let p = &collect(&evs, "@me", &HashMap::new())["$p"];
        assert_eq!(p.description, "토요일 모임");
        assert!(p.add_options && p.shuffle && p.hide_results && !p.change_vote);
        assert_eq!(p.answers[0].sticker, "buru_01_hello");
        assert_eq!(p.answers[1].geo, "geo:37.55635,126.92290");
        assert_eq!(p.answers[2].text, "성수");
        assert_eq!(p.answers[2].added_by.as_deref(), Some("@b"));
        assert_eq!(p.answers.len(), MAX_WITH_ADDED, "12 at most");
        assert_eq!(p.mine, vec!["$o1".to_string()], "first vote stays when changes are off");
        assert_eq!(p.voters, 1);
        assert_eq!(answer_ids(&evs, "$p").len(), MAX_WITH_ADDED);
    }

    #[test]
    fn no_added_answers_unless_allowed_or_after_close() {
        let mut start = start_content("q", &["x".into(), "y".into()], false, false);
        let evs = vec![
            ev("$p", START, "@a", start.clone()),
            ev("$o", OPTION, "@b", serde_json::json!({ "poll": "$p", "text": "z" })),
        ];
        assert_eq!(collect(&evs, "@me", &HashMap::new())["$p"].answers.len(), 2);
        apply_extras(&mut start, &serde_json::json!({ "add_options": true, "answers": [{ "sticker": "../x" }, { "geo": "geo:99,0" }] }), false);
        let evs = vec![
            ev("$p", START, "@a", start),
            ev("$e", END, "@a", serde_json::json!({ "poll": "$p" })),
            ev("$o", OPTION, "@b", serde_json::json!({ "poll": "$p", "text": "z" })),
        ];
        let p = &collect(&evs, "@me", &HashMap::new())["$p"];
        assert_eq!(p.answers.len(), 2, "closed");
        assert!(p.answers[0].sticker.is_empty() && p.answers[1].geo.is_empty(), "bad extras dropped");
        assert!(p.change_vote, "changes on by default");
    }

    #[test]
    fn quiz_never_changes() {
        let mut start = start_content_ext("q", &["x".into(), "y".into()], false, false, Some(0), "", 0);
        apply_extras(&mut start, &serde_json::json!({ "change_vote": true }), true);
        let p = &collect(&[ev("$p", START, "@a", start)], "@me", &HashMap::new())["$p"];
        assert!(!p.change_vote);
    }
}
