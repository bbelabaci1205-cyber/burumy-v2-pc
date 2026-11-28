// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Long posts and formatted messages ("긴 글"): headings, quotes, code,
//! formulas, lists, tables, photos and dividers.
//!
//! One shared document format is used for people's articles, short
//! formatted messages and, later, on-device AI answers and bots. It travels
//! as a card (kind "article"). A short document sits inside the encrypted
//! card itself; a long one is uploaded as an encrypted file (like a photo)
//! and the card carries only its key, a short preview and the numbers.
//! The server only ever stores scrambled bytes.
//!
//! Every phone checks the document again when it opens it (never trust the
//! sender's app): only the block types below survive, every text is cut to
//! its limit, and photo references must be well-formed encrypted files.

use anyhow::{Context, Result, ensure};
use serde_json::{Value, json};

/// Whole document (text, tables, formulas) at most this many characters.
pub const MAX_CHARS: usize = 100_000;
/// Document file at most this big (JSON, before encryption).
pub const MAX_FILE: usize = 1024 * 1024;
/// A document this small (JSON) goes inside the card itself.
pub const INLINE_MAX: usize = 16 * 1024;
pub const MAX_BLOCKS: usize = 2000;
pub const MAX_IMAGES: usize = 50;
pub const MAX_TABLE_COLS: usize = 12;
pub const MAX_TABLE_ROWS: usize = 200;
/// Blocks kept in a long post's preview.
pub const PREVIEW_BLOCKS: usize = 6;
const PREVIEW_CHARS: usize = 700;

/// Block types, in the order the editor offers them.
pub const KINDS: [&str; 12] = [
    "h1", "h2", "p", "quote", "pull", "code", "math", "ul", "ol", "table", "img", "hr",
];

fn cut(v: &Value, max: usize) -> Option<String> {
    let s = v.as_str()?;
    // Keep new lines and tabs, drop other control characters.
    let t: String = s
        .chars()
        .filter(|c| !c.is_control() || *c == '\n' || *c == '\t')
        .take(max)
        .collect();
    let t = t.trim_end().to_owned();
    (!t.trim().is_empty()).then_some(t)
}

fn arr(v: &Value) -> &[Value] {
    v.as_array().map(|a| a.as_slice()).unwrap_or(&[])
}

/// A well-formed encrypted file reference (Matrix "EncryptedFile").
pub fn clean_file(f: &Value) -> Option<Value> {
    let url = f["url"].as_str()?;
    let ok_url = url.starts_with("mxc://")
        && url.len() <= 300
        && !url.chars().any(|c| c.is_whitespace() || c.is_control());
    let key = &f["key"];
    let k = key["k"].as_str()?;
    let iv = f["iv"].as_str()?;
    let sha = f["hashes"]["sha256"].as_str()?;
    let small = |s: &str| {
        s.len() <= 100
            && s.chars()
                .all(|c| c.is_ascii_alphanumeric() || "+/=-_".contains(c))
    };
    (ok_url && small(k) && small(iv) && small(sha) && key["alg"].as_str() == Some("A256CTR")).then(
        || {
            json!({
                "url": url,
                "key": { "kty": "oct", "key_ops": ["encrypt", "decrypt"], "alg": "A256CTR", "k": k, "ext": true },
                "iv": iv,
                "hashes": { "sha256": sha },
                "v": "v2",
            })
        },
    )
}

/// Checks a whole document. `budget` counts characters across blocks.
pub fn clean_doc(d: &Value) -> Result<Value> {
    let mut left = MAX_CHARS;
    let mut images = 0usize;
    let mut take = |v: &Value, max: usize| -> Option<String> {
        if left == 0 {
            return None;
        }
        let t = cut(v, max.min(left))?;
        left = left.saturating_sub(t.chars().count());
        Some(t)
    };
    let mut blocks = vec![];
    for b in arr(&d["blocks"]).iter().take(MAX_BLOCKS) {
        let Some(t) = b["t"].as_str().filter(|t| KINDS.contains(t)) else {
            continue;
        };
        let out = match t {
            "h1" | "h2" => take(&b["text"], 300).map(|s| json!({ "t": t, "text": s })),
            "p" | "quote" | "pull" => {
                take(&b["text"], 20_000).map(|s| json!({ "t": t, "text": s }))
            }
            "code" => take(&b["text"], 20_000).map(|s| {
                let lang: String = b["lang"]
                    .as_str()
                    .unwrap_or_default()
                    .chars()
                    .filter(|c| c.is_ascii_alphanumeric() || "+#-_.".contains(*c))
                    .take(20)
                    .collect();
                json!({ "t": t, "text": s, "lang": lang })
            }),
            "math" => take(&b["tex"], 2000).map(|s| json!({ "t": t, "tex": s })),
            "ul" | "ol" => {
                let items: Vec<String> = arr(&b["items"])
                    .iter()
                    .take(500)
                    .filter_map(|x| take(x, 4000))
                    .collect();
                (!items.is_empty()).then(|| {
                    let start = b["start"].as_u64().unwrap_or(1).clamp(0, 100_000);
                    if t == "ol" {
                        json!({ "t": t, "items": items, "start": start })
                    } else {
                        json!({ "t": t, "items": items })
                    }
                })
            }
            "table" => {
                let rows: Vec<Vec<String>> = arr(&b["rows"])
                    .iter()
                    .take(MAX_TABLE_ROWS)
                    .map(|r| {
                        arr(r)
                            .iter()
                            .take(MAX_TABLE_COLS)
                            .map(|c| take(c, 500).unwrap_or_default())
                            .collect::<Vec<_>>()
                    })
                    .filter(|r| !r.is_empty())
                    .collect();
                let cols = rows.iter().map(|r| r.len()).max().unwrap_or(0);
                (cols > 0 && rows.iter().any(|r| r.iter().any(|c| !c.is_empty()))).then(|| {
                    // Every row as wide as the widest one.
                    let rows: Vec<Vec<String>> = rows
                        .into_iter()
                        .map(|mut r| {
                            r.resize(cols, String::new());
                            r
                        })
                        .collect();
                    json!({ "t": t, "rows": rows, "head": b["head"].as_bool().unwrap_or(true) })
                })
            }
            "img" => {
                if images >= MAX_IMAGES {
                    None
                } else {
                    clean_file(&b["file"]).map(|file| {
                        images += 1;
                        let mime = match b["mime"].as_str() {
                            Some(m @ ("image/jpeg" | "image/png" | "image/webp" | "image/gif")) => m,
                            _ => "image/jpeg",
                        };
                        let dim = |k: &str| b[k].as_u64().unwrap_or(0).min(20_000);
                        let mut o = json!({ "t": t, "file": file, "mime": mime, "w": dim("w"), "h": dim("h") });
                        if let Some(c) = take(&b["caption"], 500) {
                            o["caption"] = c.into();
                        }
                        o
                    })
                }
            }
            _ => Some(json!({ "t": "hr" })),
        };
        if let Some(o) = out {
            blocks.push(o);
        }
    }
    let title = take(&d["title"], 200).unwrap_or_default();
    ensure!(!blocks.is_empty() || !title.is_empty(), "write something");
    Ok(json!({ "title": title, "blocks": blocks }))
}

/// Characters a person reads (for "about N minutes").
pub fn chars(doc: &Value) -> usize {
    let mut n = doc["title"]
        .as_str()
        .map(|s| s.chars().count())
        .unwrap_or(0);
    for b in arr(&doc["blocks"]) {
        for k in ["text", "tex", "caption"] {
            n += b[k].as_str().map(|s| s.chars().count()).unwrap_or(0);
        }
        for x in arr(&b["items"]) {
            n += x.as_str().map(|s| s.chars().count()).unwrap_or(0);
        }
        for r in arr(&b["rows"]) {
            for c in arr(r) {
                n += c.as_str().map(|s| s.chars().count()).unwrap_or(0);
            }
        }
    }
    n
}

/// The first few blocks of a long post, without photos (they need the file).
pub fn preview(doc: &Value) -> Value {
    let mut left = PREVIEW_CHARS;
    let mut out = vec![];
    for b in arr(&doc["blocks"]) {
        if out.len() >= PREVIEW_BLOCKS || left == 0 {
            break;
        }
        let t = b["t"].as_str().unwrap_or_default();
        match t {
            "img" | "hr" => continue,
            "table" => {
                // Two rows are enough to show there is a table.
                let rows: Vec<Value> = arr(&b["rows"]).iter().take(2).cloned().collect();
                out.push(json!({ "t": t, "rows": rows, "head": b["head"] }));
                left = left.saturating_sub(100);
            }
            "ul" | "ol" => {
                let items: Vec<Value> = arr(&b["items"]).iter().take(3).cloned().collect();
                let mut o = b.clone();
                o["items"] = items.into();
                out.push(o);
                left = left.saturating_sub(150);
            }
            _ => {
                let mut o = b.clone();
                for k in ["text", "tex"] {
                    if let Some(s) = b[k].as_str() {
                        let n = s.chars().count();
                        o[k] = s.chars().take(left).collect::<String>().into();
                        left = left.saturating_sub(n);
                    }
                }
                out.push(o);
            }
        }
    }
    json!({ "title": doc["title"], "blocks": out })
}

/// Checks the card data of an article: the document inside, or a long
/// post's file key + preview.
pub fn clean_card(d: &Value) -> Result<Value> {
    if d.get("doc").is_some() {
        let doc = clean_doc(&d["doc"])?;
        ensure!(
            doc.to_string().len() <= INLINE_MAX + 4096,
            "too long for one message"
        );
        return Ok(json!({ "doc": doc }));
    }
    let file = clean_file(&d["file"]).context("no document")?;
    let preview = clean_doc(&d["preview"]).unwrap_or_else(|_| json!({ "title": "", "blocks": [] }));
    let num = |k: &str, max: u64| d[k].as_u64().unwrap_or(0).min(max);
    Ok(json!({
        "file": file,
        "preview": preview,
        "size": num("size", MAX_FILE as u64),
        "chars": num("chars", MAX_CHARS as u64),
        "images": num("images", MAX_IMAGES as u64),
    }))
}

/// Short text for notifications, the chat list and old apps.
pub fn body(d: &Value) -> String {
    let doc = if d.get("doc").is_some() {
        &d["doc"]
    } else {
        &d["preview"]
    };
    let title = doc["title"].as_str().unwrap_or_default();
    if !title.is_empty() {
        return format!("📰 {title}");
    }
    let first = arr(&doc["blocks"])
        .iter()
        .find_map(|b| {
            b["text"]
                .as_str()
                .or_else(|| arr(&b["items"]).first().and_then(|x| x.as_str()))
        })
        .unwrap_or_default();
    let line: String = first
        .lines()
        .next()
        .unwrap_or_default()
        .chars()
        .take(80)
        .collect();
    format!("📰 {line}")
}

/// Parses a downloaded document file and checks it.
pub fn open_file(bytes: &[u8]) -> Result<Value> {
    ensure!(bytes.len() <= MAX_FILE, "document too big");
    let v: Value = serde_json::from_slice(bytes).context("not a document")?;
    clean_doc(&v)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn file() -> Value {
        json!({ "url": "mxc://burumy.test/abc", "key": { "kty": "oct", "alg": "A256CTR", "k": "a-b_c", "key_ops": ["encrypt","decrypt"], "ext": true }, "iv": "AAAA", "hashes": { "sha256": "xyz+/=" }, "v": "v2" })
    }

    #[test]
    fn unknown_blocks_and_scripts_are_dropped() {
        let d = json!({ "title": "T", "blocks": [
            { "t": "script", "text": "<script>" },
            { "t": "p", "text": "hello\u{0007} world" },
            { "t": "h1", "text": "   " },
            { "t": "img", "file": { "url": "https://evil/x" } },
            { "t": "img", "file": file(), "mime": "text/html", "w": 99999 },
        ]});
        let c = clean_doc(&d).unwrap();
        let b = c["blocks"].as_array().unwrap();
        assert_eq!(b.len(), 2);
        assert_eq!(b[0]["text"], "hello world");
        assert_eq!(b[1]["mime"], "image/jpeg");
        assert_eq!(b[1]["w"], 20_000);
        assert_eq!(b[1]["file"]["url"], "mxc://burumy.test/abc");
    }

    #[test]
    fn tables_are_squared_and_capped() {
        let rows: Vec<Value> = (0..300)
            .map(|i| {
                json!([
                    format!("r{i}"),
                    "b",
                    "c",
                    "d",
                    "e",
                    "f",
                    "g",
                    "h",
                    "i",
                    "j",
                    "k",
                    "l",
                    "m",
                    "n"
                ])
            })
            .collect();
        let mut rows2 = rows.clone();
        rows2[1] = json!(["only one"]);
        let c = clean_doc(&json!({ "blocks": [{ "t": "table", "rows": rows2 }] })).unwrap();
        let t = &c["blocks"][0];
        assert_eq!(t["rows"].as_array().unwrap().len(), MAX_TABLE_ROWS);
        assert_eq!(t["rows"][0].as_array().unwrap().len(), MAX_TABLE_COLS);
        assert_eq!(t["rows"][1].as_array().unwrap().len(), MAX_TABLE_COLS);
        assert_eq!(t["head"], true);
    }

    #[test]
    fn total_length_is_capped() {
        let big = "가".repeat(20_000);
        let blocks: Vec<Value> = (0..10).map(|_| json!({ "t": "p", "text": big })).collect();
        let c = clean_doc(&json!({ "blocks": blocks })).unwrap();
        assert!(chars(&c) <= MAX_CHARS);
        assert_eq!(c["blocks"].as_array().unwrap().len(), 5);
    }

    #[test]
    fn empty_is_refused() {
        assert!(clean_doc(&json!({ "blocks": [{ "t": "p", "text": " " }] })).is_err());
    }

    #[test]
    fn card_forms() {
        let inline = clean_card(
            &json!({ "doc": { "title": "Hi", "blocks": [{ "t": "math", "tex": "a^2+b^2=c^2" }] } }),
        )
        .unwrap();
        assert_eq!(inline["doc"]["blocks"][0]["tex"], "a^2+b^2=c^2");
        assert_eq!(body(&inline), "📰 Hi");
        let long = clean_card(&json!({ "file": file(), "preview": { "blocks": [{ "t": "p", "text": "첫 줄\n둘" }] }, "chars": 9_999_999 })).unwrap();
        assert_eq!(long["chars"], MAX_CHARS as u64);
        assert_eq!(body(&long), "📰 첫 줄");
        assert!(clean_card(&json!({ "file": { "url": "mxc://x/y" } })).is_err());
        let too_big = "가".repeat(30_000);
        assert!(
            clean_card(&json!({ "doc": { "blocks": [{ "t": "p", "text": too_big }] } })).is_err()
        );
    }

    #[test]
    fn preview_is_short_and_has_no_photos() {
        let d = clean_doc(&json!({ "title": "T", "blocks": [
            { "t": "img", "file": file() },
            { "t": "p", "text": "x".repeat(5000) },
            { "t": "p", "text": "more" },
        ]}))
        .unwrap();
        let p = preview(&d);
        let b = p["blocks"].as_array().unwrap();
        assert_eq!(b.len(), 1);
        assert_eq!(b[0]["text"].as_str().unwrap().len(), PREVIEW_CHARS);
    }
}
