// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Checklists inside encrypted chats.
//!
//! The list itself, every tick and every added item are encrypted room
//! events, so only members can read them. Only the maker may tick or add
//! unless the maker allowed others to; anything else is ignored by every
//! phone (the server never decides).

use std::collections::HashMap;

pub const START: &str = "app.burumy.checklist";
pub const MARK: &str = "app.burumy.checklist.mark";
pub const ADD: &str = "app.burumy.checklist.add";
pub const MAX_ITEMS: usize = 30;
pub const MAX_TEXT: usize = 200;

#[derive(Debug, Clone, PartialEq)]
pub struct ChecklistItem {
    pub id: String,
    pub text: String,
    /// Who ticked it (None = not done).
    pub done_by: Option<String>,
    /// Who added it later (None = in the first list).
    pub added_by: Option<String>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Checklist {
    pub title: String,
    pub items: Vec<ChecklistItem>,
    pub others_mark: bool,
    pub others_add: bool,
}

/// Cleans the words: trimmed, not empty, not too long.
pub fn clean(text: &str) -> Option<String> {
    let t = text.trim();
    (!t.is_empty()).then(|| t.chars().take(MAX_TEXT).collect())
}

pub fn start_content(
    title: &str,
    items: &[String],
    others_mark: bool,
    others_add: bool,
) -> serde_json::Value {
    let list: Vec<_> = items
        .iter()
        .enumerate()
        .map(|(i, t)| serde_json::json!({ "id": format!("i{i}"), "text": t }))
        .collect();
    serde_json::json!({
        "body": format!("☑️ {title}"),
        "title": title,
        "items": list,
        "others_mark": others_mark,
        "others_add": others_add,
    })
}

/// Builds every checklist in these (decrypted) events, in order, applying
/// only the ticks and additions their senders were allowed to make.
pub fn collect(events: &[serde_json::Value]) -> HashMap<String, Checklist> {
    let mut lists: HashMap<String, (String, Checklist)> = HashMap::new();
    for v in events {
        let ty = v["type"].as_str().unwrap_or_default();
        let c = &v["content"];
        let sender = v["sender"].as_str().unwrap_or_default();
        if ty == START {
            let (Some(id), Some(title)) =
                (v["event_id"].as_str(), c["title"].as_str().and_then(clean))
            else {
                continue;
            };
            let items: Vec<ChecklistItem> = c["items"]
                .as_array()
                .map(|a| {
                    a.iter()
                        .take(MAX_ITEMS)
                        .filter_map(|x| {
                            Some(ChecklistItem {
                                id: x["id"].as_str()?.into(),
                                text: clean(x["text"].as_str()?)?,
                                done_by: None,
                                added_by: None,
                            })
                        })
                        .collect()
                })
                .unwrap_or_default();
            if items.is_empty() {
                continue;
            }
            let list = Checklist {
                title,
                items,
                others_mark: c["others_mark"].as_bool().unwrap_or(false),
                others_add: c["others_add"].as_bool().unwrap_or(false),
            };
            lists.insert(id.into(), (sender.into(), list));
            continue;
        }
        if ty != MARK && ty != ADD {
            continue;
        }
        let Some(cid) = c["checklist"].as_str() else {
            continue;
        };
        let Some((maker, list)) = lists.get_mut(cid) else {
            continue;
        };
        let is_maker = sender == maker.as_str();
        if ty == MARK && (is_maker || list.others_mark) {
            let Some(item) = c["item"].as_str() else {
                continue;
            };
            if let Some(it) = list.items.iter_mut().find(|x| x.id == item) {
                it.done_by = c["done"]
                    .as_bool()
                    .unwrap_or(false)
                    .then(|| sender.to_owned());
            }
        } else if ty == ADD && (is_maker || list.others_add) && list.items.len() < MAX_ITEMS {
            let (Some(id), Some(text)) =
                (v["event_id"].as_str(), c["text"].as_str().and_then(clean))
            else {
                continue;
            };
            list.items.push(ChecklistItem {
                id: id.into(),
                text,
                done_by: None,
                added_by: Some(sender.into()),
            });
        }
    }
    lists.into_iter().map(|(k, (_, l))| (k, l)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn ev(id: &str, ty: &str, sender: &str, content: serde_json::Value) -> serde_json::Value {
        json!({ "event_id": id, "type": ty, "sender": sender, "content": content })
    }

    #[test]
    fn only_allowed_people_tick_and_add() {
        let start = start_content("장보기", &["우유".into(), "빵".into()], false, true);
        let evs = vec![
            ev("$c", START, "@me:x", start),
            ev(
                "$1",
                MARK,
                "@bob:x",
                json!({ "checklist": "$c", "item": "i0", "done": true }),
            ),
            ev(
                "$2",
                MARK,
                "@me:x",
                json!({ "checklist": "$c", "item": "i1", "done": true }),
            ),
            ev(
                "$3",
                ADD,
                "@bob:x",
                json!({ "checklist": "$c", "text": "  계란 " }),
            ),
            ev(
                "$4",
                MARK,
                "@me:x",
                json!({ "checklist": "$c", "item": "$3", "done": true }),
            ),
            ev(
                "$5",
                MARK,
                "@me:x",
                json!({ "checklist": "$c", "item": "$3", "done": false }),
            ),
            ev(
                "$6",
                MARK,
                "@me:x",
                json!({ "checklist": "$nope", "item": "i0", "done": true }),
            ),
        ];
        let l = &collect(&evs)["$c"];
        assert_eq!(l.items[0].done_by, None, "others may not tick");
        assert_eq!(l.items[1].done_by.as_deref(), Some("@me:x"));
        assert_eq!(l.items[2].text, "계란");
        assert_eq!(l.items[2].added_by.as_deref(), Some("@bob:x"));
        assert_eq!(l.items[2].done_by, None, "last tick wins");
    }

    #[test]
    fn caps_items_and_text() {
        let many: Vec<String> = (0..40).map(|i| format!("{i}")).collect();
        let long = "가".repeat(500);
        let mut evs = vec![ev(
            "$c",
            START,
            "@me:x",
            start_content("t", &many, true, true),
        )];
        evs.push(ev(
            "$a",
            ADD,
            "@me:x",
            json!({ "checklist": "$c", "text": long }),
        ));
        let l = &collect(&evs)["$c"];
        assert_eq!(l.items.len(), MAX_ITEMS);
        let evs = vec![
            ev(
                "$c",
                START,
                "@me:x",
                start_content("t", &["x".into()], true, true),
            ),
            ev(
                "$a",
                ADD,
                "@b:x",
                json!({ "checklist": "$c", "text": "가".repeat(500) }),
            ),
        ];
        assert_eq!(collect(&evs)["$c"].items[1].text.chars().count(), MAX_TEXT);
        let empty = vec![ev(
            "$c",
            START,
            "@me:x",
            json!({ "title": " ", "items": [{ "id": "i0", "text": "a" }] }),
        )];
        assert!(collect(&empty).is_empty());
    }
}
