// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! 다른 앱 대화 가져오기 (Telegram tips 244 + 254): a chat exported from
//! KakaoTalk, WhatsApp or Telegram, read on the importer's phone
//! (app/lib/core/chat_import.dart) and brought into a Burumy chat.
//!
//! How it travels: the importer's phone packs the messages into a few
//! parts (gzip JSON), encrypts each part on the phone and uploads it
//! (photos and files likewise, one encrypted upload each). Then one
//! end-to-end encrypted card of kind "import" goes into the chat with the
//! parts' places and keys. The server holds only ciphertext and sees one
//! message, not the thousands inside, nor who wrote them or when.
//!
//! Every phone that opens the chat downloads the parts once, checks each
//! message here (kinds, sizes, real encrypted file references, times not
//! after the card was sent) and keeps the checked list in the encrypted
//! local store. The chat shows them in their original time order with a
//! "가져옴" mark.
//!
//! Names: a message counts as written by a Burumy account only for the
//! importer themself, or in a 1:1 chat the other person. Everyone else
//! keeps the name they had in the other app (so nobody can put words in
//! a third member's mouth with an import).

use std::io::Read;

use anyhow::{Context, Result, bail, ensure};
use matrix_sdk::ruma::{RoomId, UserId};
use serde_json::{Value, json};

use crate::{Engine, to_err};

pub const APPS: [&str; 3] = ["kakao", "whatsapp", "telegram"];

/// Most messages in one import (the app keeps the same limit).
pub const MAX_ITEMS: usize = 300_000;
/// Parts in one import card (each part's reference is ~330 bytes).
pub const MAX_PARTS: usize = 40;
/// Most messages in one part.
pub const MAX_PART_ITEMS: usize = 10_000;
/// A part after unzipping (stops zip bombs).
const MAX_PART_BYTES: u64 = 64 * 1024 * 1024;
/// Longest words in one message, a name, a file name.
pub const MAX_BODY: usize = 10_000;
const MAX_NAME: usize = 64;
const MAX_PEOPLE: usize = 5_000;
/// 2000-01-01: older times are broken dates.
const OLDEST_MS: u64 = 946_684_800_000;
const DAY_MS: u64 = 86_400_000;

const KINDS: [&str; 8] = ["text", "image", "video", "audio", "file", "system", "deleted", "missing"];
const MEDIA: [&str; 4] = ["image", "video", "audio", "file"];
const MISSING: [&str; 5] = ["image", "video", "audio", "file", "sticker"];

fn short(v: &Value, max: usize) -> String {
    v.as_str()
        .unwrap_or_default()
        .chars()
        .filter(|c| !c.is_control() || *c == '\n')
        .take(max)
        .collect()
}

fn file_ref(v: &Value) -> Option<Value> {
    crate::article::clean_file(v)
}

/// The import card's data, checked (card.rs calls this for kind "import").
pub fn sanitize(d: &Value) -> Result<Value> {
    let app = d["app"].as_str().unwrap_or_default();
    ensure!(APPS.contains(&app), "unknown app");
    let mut parts = Vec::new();
    let mut total = 0u64;
    for p in d["parts"].as_array().map(|a| a.as_slice()).unwrap_or(&[]).iter().take(MAX_PARTS + 1) {
        let file = file_ref(&p["file"]).context("bad part")?;
        let n = p["n"].as_u64().unwrap_or(0);
        ensure!(n > 0 && n <= MAX_PART_ITEMS as u64, "bad part size");
        total += n;
        parts.push(json!({ "file": file, "n": n }));
    }
    ensure!(!parts.is_empty() && parts.len() <= MAX_PARTS, "bad parts");
    ensure!(total <= MAX_ITEMS as u64, "too many messages");
    // Which writers are Burumy accounts: person index -> user id (2 at most:
    // me and, in a 1:1, the other person). Checked again when read.
    let mut who = serde_json::Map::new();
    if let Some(m) = d["who"].as_object() {
        for (k, v) in m.iter().take(2) {
            let ok_idx = k.parse::<usize>().is_ok_and(|i| i < MAX_PEOPLE);
            let id = v.as_str().unwrap_or_default();
            if ok_idx && UserId::parse(id).is_ok() {
                who.insert(k.clone(), json!(id));
            }
        }
    }
    let from = d["from"].as_u64().unwrap_or(0);
    let to = d["to"].as_u64().unwrap_or(0).max(from);
    Ok(json!({
        "app": app,
        "title": short(&d["title"], 100).trim(),
        "count": total,
        "from": from,
        "to": to,
        "media": d["media"].as_u64().unwrap_or(0).min(total),
        "parts": parts,
        "who": who,
    }))
}

pub fn body(d: &Value) -> String {
    format!("📥 {} · {}", d["title"].as_str().unwrap_or_default(), d["count"].as_u64().unwrap_or(0))
}

/// Unzips one part, never more than [MAX_PART_BYTES].
pub fn gunzip(bytes: &[u8]) -> Result<Vec<u8>> {
    let mut out = Vec::new();
    flate2::read::GzDecoder::new(bytes)
        .take(MAX_PART_BYTES + 1)
        .read_to_end(&mut out)
        .context("part is not gzip")?;
    ensure!(out.len() as u64 <= MAX_PART_BYTES, "part too big");
    Ok(out)
}

/// One message from a part, checked; None = dropped.
/// `people` = how many writers there are, `sent` = the card's time (ms),
/// `index` = its place in the whole import (replies may only point back).
pub fn clean_item(v: &Value, people: usize, sent: u64, index: usize) -> Option<Value> {
    let t = v["t"].as_u64()?;
    if t < OLDEST_MS || t > sent + DAY_MS {
        return None;
    }
    let mut k = v["k"].as_str().unwrap_or("text");
    if !KINDS.contains(&k) {
        return None;
    }
    let p = v["p"].as_u64().map(|p| p as usize).filter(|p| *p < people);
    if k != "system" && p.is_none() {
        return None;
    }
    let mut out = json!({ "t": t, "k": k, "b": short(&v["b"], MAX_BODY) });
    if let Some(p) = p {
        out["p"] = json!(p);
    }
    if MEDIA.contains(&k) {
        match file_ref(&v["f"]) {
            Some(f) => {
                out["f"] = f;
                if let Some(th) = file_ref(&v["th"]) {
                    out["th"] = th;
                }
                let mime = v["m"].as_str().unwrap_or_default();
                if mime.len() <= 100 && mime.chars().all(|c| c.is_ascii_alphanumeric() || "/+.-".contains(c)) {
                    out["m"] = json!(mime);
                }
                out["n"] = json!(short(&v["n"], 200).replace('\n', " "));
                out["s"] = json!(v["s"].as_u64().unwrap_or(0));
            }
            None => {
                // A photo whose file is not there: say so, never show a broken one.
                out["mk"] = json!(k);
                k = "missing";
                out["k"] = json!(k);
            }
        }
    }
    if k == "missing" {
        let mk = out["mk"].as_str().map(str::to_owned).unwrap_or_else(|| v["mk"].as_str().unwrap_or("file").to_owned());
        out["mk"] = json!(if MISSING.contains(&mk.as_str()) { mk.as_str() } else { "file" });
    }
    if let Some(r) = v["r"].as_u64().map(|r| r as usize).filter(|r| *r < index) {
        out["r"] = json!(r);
    }
    if v["fw"].as_bool() == Some(true) {
        out["fw"] = json!(true);
    }
    if v["e"].as_bool() == Some(true) {
        out["e"] = json!(true);
    }
    Some(out)
}

/// All parts (already unzipped JSON) into one checked list, oldest first.
/// Replies keep pointing at the same message after sorting.
pub fn assemble(parts: &[Value], sent: u64, who: &[(usize, String)]) -> Result<Value> {
    let people: Vec<String> = parts
        .first()
        .and_then(|p| p["people"].as_array())
        .map(|a| a.iter().take(MAX_PEOPLE).map(|x| short(x, MAX_NAME).replace('\n', " ")).collect())
        .unwrap_or_default();
    let mut raw: Vec<Option<Value>> = Vec::new();
    for part in parts {
        for v in part["items"].as_array().map(|a| a.as_slice()).unwrap_or(&[]).iter().take(MAX_PART_ITEMS) {
            if raw.len() >= MAX_ITEMS {
                break;
            }
            let i = raw.len();
            raw.push(clean_item(v, people.len(), sent, i));
        }
    }
    // Old index -> new index after dropping bad ones and sorting by time.
    let mut keep: Vec<(usize, Value)> = raw.into_iter().enumerate().filter_map(|(i, v)| v.map(|v| (i, v))).collect();
    keep.sort_by_key(|(i, v)| (v["t"].as_u64().unwrap_or(0), *i));
    let mut moved = std::collections::HashMap::new();
    for (new, (old, _)) in keep.iter().enumerate() {
        moved.insert(*old, new);
    }
    let items: Vec<Value> = keep
        .into_iter()
        .map(|(_, mut v)| {
            if let Some(r) = v["r"].as_u64() {
                match moved.get(&(r as usize)) {
                    Some(n) => v["r"] = json!(n),
                    None => {
                        v.as_object_mut().map(|o| o.remove("r"));
                    }
                }
            }
            v
        })
        .collect();
    ensure!(!items.is_empty(), "nothing in the import");
    let people: Vec<Value> = people
        .iter()
        .enumerate()
        .map(|(i, name)| {
            let id = who.iter().find(|(w, _)| *w == i).map(|(_, id)| id.as_str()).unwrap_or("");
            json!({ "name": name, "id": id })
        })
        .collect();
    Ok(json!({ "people": people, "items": items }))
}

fn store_key(room: &str, card: &str) -> Vec<u8> {
    format!("burumy.import.v1:{room}:{card}").into_bytes()
}

impl Engine {
    /// The messages of an import card, checked, oldest first (JSON:
    /// {app, title, by, people: [{name, id}], items: [...]}). Downloaded
    /// and decrypted once, then read from this phone's encrypted store.
    pub async fn imported_messages(&self, room_id: &RoomId, card_id: &str) -> Result<String> {
        let key = store_key(room_id.as_str(), card_id);
        let store = self.client.state_store();
        if let Ok(Some(b)) = store.get_custom_value(&key).await {
            if let Ok(b) = gunzip(&b) {
                return Ok(String::from_utf8(b)?);
            }
        }
        let room = self.client.get_room(room_id).context("unknown room")?;
        let v = self.card_start(&room, card_id).await?;
        ensure!(v["content"]["kind"].as_str() == Some("import"), "not an import");
        let d = sanitize(&v["content"]["data"])?;
        let by = v["sender"].as_str().context("no sender")?.to_owned();
        let sent = v["origin_server_ts"].as_u64().unwrap_or(0);
        // Only the importer, or the other person of a 1:1, may stand behind
        // imported words with their account.
        let mut allowed = vec![by.clone()];
        if room.is_direct().await.unwrap_or(false) {
            for t in room.direct_targets() {
                allowed.push(t.to_string());
            }
        }
        let who: Vec<(usize, String)> = d["who"]
            .as_object()
            .map(|m| {
                m.iter()
                    .filter_map(|(k, v)| Some((k.parse().ok()?, v.as_str()?.to_owned())))
                    .filter(|(_, id)| allowed.contains(id))
                    .collect()
            })
            .unwrap_or_default();
        let mut parts = Vec::new();
        for p in d["parts"].as_array().map(|a| a.as_slice()).unwrap_or(&[]) {
            let bytes = self.download_encrypted(&p["file"].to_string()).await?;
            let raw = gunzip(&bytes)?;
            let part: Value = serde_json::from_slice(&raw).context("bad part")?;
            if !part.is_object() {
                bail!("bad part");
            }
            parts.push(part);
        }
        let mut out = assemble(&parts, sent, &who)?;
        out["app"] = d["app"].clone();
        out["title"] = d["title"].clone();
        out["by"] = json!(by);
        let text = out.to_string();
        let mut gz = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
        std::io::Write::write_all(&mut gz, text.as_bytes())?;
        let _ = store.set_custom_value_no_read(&key, gz.finish()?).await.map_err(to_err);
        Ok(text)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn file() -> Value {
        json!({
            "url": "mxc://s/abc", "key": {"k": "a2V5", "alg": "A256CTR", "kty": "oct", "key_ops": ["encrypt", "decrypt"], "ext": true},
            "iv": "aXY", "hashes": {"sha256": "c2hh"}, "v": "v2"
        })
    }

    const SENT: u64 = 1_800_000_000_000;

    #[test]
    fn card_data_is_checked() {
        let d = json!({ "app": "kakao", "title": " 가족방 ", "parts": [{ "file": file(), "n": 3 }], "who": { "0": "@me:s", "1": "not an id", "2": "@x:s", "3": "@y:s" }, "from": 5, "to": 9, "media": 99 });
        let c = sanitize(&d).unwrap();
        assert_eq!(c["title"], "가족방");
        assert_eq!(c["count"], 3);
        assert_eq!(c["media"], 3, "never more media than messages");
        assert_eq!(c["who"].as_object().unwrap().len(), 1, "bad id dropped, 2 entries looked at");
        assert!(sanitize(&json!({ "app": "line", "parts": [{ "file": file(), "n": 1 }] })).is_err());
        assert!(sanitize(&json!({ "app": "kakao", "parts": [] })).is_err());
        assert!(sanitize(&json!({ "app": "kakao", "parts": [{ "file": { "url": "https://evil" }, "n": 1 }] })).is_err());
        let many: Vec<Value> = (0..41).map(|_| json!({ "file": file(), "n": 1 })).collect();
        assert!(sanitize(&json!({ "app": "kakao", "parts": many })).is_err());
        let s = serde_json::to_string(&sanitize(&json!({ "app": "kakao", "title": "가".repeat(500), "parts": (0..40).map(|_| json!({ "file": file(), "n": 7500 })).collect::<Vec<_>>() })).unwrap()).unwrap();
        assert!(s.len() <= crate::card::MAX_DATA, "a full card still fits ({})", s.len());
    }

    #[test]
    fn items_are_checked_sorted_and_replies_follow() {
        let part = json!({
            "people": ["민지", "나"],
            "items": [
                { "t": 1_700_000_100_000u64, "p": 0, "k": "text", "b": "두 번째" },
                { "t": 1_700_000_000_000u64, "p": 1, "k": "text", "b": "첫 번째" },
                { "t": 1_700_000_200_000u64, "p": 0, "k": "text", "b": "답장", "r": 1 },
                { "t": 1_700_000_300_000u64, "p": 0, "k": "image", "f": { "url": "https://evil" } },
                { "t": 1_700_000_400_000u64, "p": 9, "k": "text", "b": "모르는 사람" },
                { "t": 100, "p": 0, "k": "text", "b": "1970" },
                { "t": SENT + 2 * DAY_MS, "p": 0, "k": "text", "b": "미래" },
                { "t": 1_700_000_500_000u64, "p": 0, "k": "script", "b": "x" },
                { "t": 1_700_000_600_000u64, "k": "system", "b": "들어옴" },
                { "t": 1_700_000_700_000u64, "p": 1, "k": "file", "f": file(), "m": "application/pdf\n<x>", "n": "a.pdf", "s": 5, "r": 99 },
                { "t": 1_700_000_800_000u64, "p": 0, "k": "text", "b": "가".repeat(20_000) },
            ]
        });
        let out = assemble(&[part], SENT, &[(1, "@me:s".into())]).unwrap();
        let items = out["items"].as_array().unwrap();
        let bodies: Vec<&str> = items.iter().map(|x| x["b"].as_str().unwrap()).collect();
        assert_eq!(bodies[..3], ["첫 번째", "두 번째", "답장"]);
        assert_eq!(items[2]["r"], 0, "reply still points at 첫 번째 after sorting");
        assert_eq!(items[3]["k"], "missing", "photo with a bad reference shows as missing");
        assert_eq!(items[3]["mk"], "image");
        assert_eq!(items[4]["k"], "system");
        assert!(items[5]["m"].is_null(), "odd mime dropped");
        assert!(items[5]["r"].is_null(), "reply forward in time dropped");
        assert_eq!(items[6]["b"].as_str().unwrap().chars().count(), MAX_BODY);
        assert_eq!(items.len(), 7, "unknown writer, 1970, future and unknown kind dropped");
        assert_eq!(out["people"][1]["id"], "@me:s");
        assert_eq!(out["people"][0]["id"], "");
    }

    #[test]
    fn zip_bombs_stop() {
        let mut gz = flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::best());
        let zeros = vec![0u8; 1024 * 1024];
        for _ in 0..70 {
            std::io::Write::write_all(&mut gz, &zeros).unwrap();
        }
        let b = gz.finish().unwrap();
        assert!(b.len() < 1024 * 1024);
        assert!(gunzip(&b).is_err());
        assert!(gunzip(b"not gzip").is_err());
    }
}
