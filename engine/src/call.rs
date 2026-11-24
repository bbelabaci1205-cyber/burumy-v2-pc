// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Voice/video calls. Ringing, answering and hanging up are small events
//! inside the encrypted chat. The call itself runs through our LiveKit
//! server, but the sound and picture are encrypted end to end with a key
//! that only travels inside the encrypted chat (in the invite), and the
//! call room name is a random id that also only travels there.

use std::collections::HashMap;

pub const INVITE: &str = "im.securemessenger.call.invite";
pub const ANSWER: &str = "im.securemessenger.call.answer";
pub const HANGUP: &str = "im.securemessenger.call.hangup";

/// How long an unanswered call rings.
pub const RING_MS: u64 = 45_000;

#[derive(Debug, Clone, PartialEq)]
pub struct Call {
    pub call_id: String,
    pub video: bool,
    /// "ringing", "ongoing", "ended", "missed", "declined", "busy"
    pub state: String,
    pub started_at: u64,
    pub answered_at: Option<u64>,
    pub ended_at: Option<u64>,
}

/// Works out every call's state from the chat's raw events (oldest first).
pub fn collect(events: &[serde_json::Value], now: u64) -> HashMap<String, (String, Call)> {
    let mut calls: HashMap<String, (String, Call)> = HashMap::new();
    for v in events {
        let ty = v["type"].as_str().unwrap_or_default();
        let c = &v["content"];
        let Some(id) = c["call"].as_str() else {
            continue;
        };
        let ts = v["origin_server_ts"].as_u64().unwrap_or(0);
        let sender = v["sender"].as_str().unwrap_or_default();
        match ty {
            INVITE => {
                if !calls.contains_key(id) {
                    let call = Call {
                        call_id: id.into(),
                        video: c["video"].as_bool().unwrap_or(false),
                        state: "ringing".into(),
                        started_at: ts,
                        answered_at: None,
                        ended_at: None,
                    };
                    calls.insert(
                        id.into(),
                        (v["event_id"].as_str().unwrap_or_default().into(), call),
                    );
                    calls.get_mut(id).unwrap().1.state = "ringing".into();
                    // Keep the caller in the state string's companion map.
                    let _ = sender;
                }
            }
            ANSWER => {
                if let Some((_, call)) = calls.get_mut(id) {
                    if call.answered_at.is_none() && call.ended_at.is_none() {
                        call.answered_at = Some(ts);
                    }
                }
            }
            HANGUP => {
                if let Some((_, call)) = calls.get_mut(id) {
                    if call.ended_at.is_none() {
                        call.ended_at = Some(ts);
                        if call.answered_at.is_none() {
                            match c["reason"].as_str() {
                                Some("decline") => call.state = "declined".into(),
                                Some("busy") => call.state = "busy".into(),
                                _ => {}
                            }
                        }
                    }
                }
            }
            _ => {}
        }
    }
    for (_, call) in calls.values_mut() {
        if call.state == "declined" || call.state == "busy" {
            continue;
        }
        call.state = match (call.answered_at, call.ended_at) {
            (Some(_), Some(_)) => "ended",
            (Some(_), None) => "ongoing",
            (None, Some(_)) => "missed",
            (None, None) if now.saturating_sub(call.started_at) < RING_MS => "ringing",
            (None, None) => "missed",
        }
        .into();
    }
    calls
}

pub fn new_call_id() -> String {
    use rand::Rng;
    (0..16)
        .map(|_| format!("{:02x}", rand::thread_rng().r#gen::<u8>()))
        .collect()
}

pub fn new_media_key() -> Vec<u8> {
    use rand::Rng;
    (0..32).map(|_| rand::thread_rng().r#gen::<u8>()).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ev(ty: &str, ts: u64, content: serde_json::Value) -> serde_json::Value {
        serde_json::json!({ "type": ty, "event_id": format!("${ts}"), "sender": "@a", "origin_server_ts": ts, "content": content })
    }

    #[test]
    fn states() {
        let evs = vec![
            ev(
                INVITE,
                1000,
                serde_json::json!({ "call": "c1", "video": true }),
            ),
            ev(ANSWER, 3000, serde_json::json!({ "call": "c1" })),
            ev(
                HANGUP,
                63000,
                serde_json::json!({ "call": "c1", "reason": "end" }),
            ),
            ev(INVITE, 70000, serde_json::json!({ "call": "c2" })),
            ev(
                HANGUP,
                72000,
                serde_json::json!({ "call": "c2", "reason": "decline" }),
            ),
            ev(INVITE, 80000, serde_json::json!({ "call": "c3" })),
            ev(INVITE, 200000, serde_json::json!({ "call": "c4" })),
            ev(INVITE, 300000, serde_json::json!({ "call": "c5" })),
            ev(ANSWER, 301000, serde_json::json!({ "call": "c5" })),
            ev(INVITE, 302000, serde_json::json!({ "call": "c6" })),
            ev(
                HANGUP,
                303000,
                serde_json::json!({ "call": "c6", "reason": "busy" }),
            ),
        ];
        let c = collect(&evs, 210000);
        assert_eq!(c["c1"].1.state, "ended");
        assert!(c["c1"].1.video);
        assert_eq!(c["c2"].1.state, "declined");
        assert_eq!(c["c3"].1.state, "missed");
        assert_eq!(c["c4"].1.state, "ringing");
        assert_eq!(c["c5"].1.state, "ongoing");
        assert_eq!(c["c6"].1.state, "busy");
    }
}
