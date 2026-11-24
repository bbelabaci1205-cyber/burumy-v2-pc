// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Web check: the same burumy_engine runs inside a browser tab
//! (IndexedDB store, browser network). Two people and a second device for
//! one of them, all in one page.

use std::path::Path;

use burumy_engine::{matrix_sdk::ruma::OwnedRoomId, Engine};
use gloo_timers::future::TimeoutFuture;
use wasm_bindgen::prelude::*;

fn log(s: &str) {
    web_sys::console::log_1(&s.into());
}

fn js(e: impl std::fmt::Display) -> JsValue {
    JsValue::from_str(&e.to_string())
}

async fn wait_for<F, Fut>(what: &str, engines: &[&Engine], mut check: F) -> Result<(), JsValue>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = bool>,
{
    for _ in 0..60 {
        for e in engines {
            e.sync_once().await.map_err(js)?;
        }
        if check().await {
            log(&format!("ok: {what}"));
            return Ok(());
        }
        TimeoutFuture::new(250).await;
    }
    Err(js(format!("timed out: {what}")))
}

#[wasm_bindgen]
pub async fn run_proof(hs: String, token: String) -> Result<String, JsValue> {
    let run = js_sys_now();
    let (a, b) = (format!("walice{run}"), format!("wbob{run}"));
    let pw = "Secret-pass-123";
    let text = "웹에서 보낸 암호화 메시지";

    let alice = Engine::open(&hs, Path::new(&format!("a1-{run}")), "store-a1").await.map_err(js)?;
    alice.register(&a, pw, Some(&token)).await.map_err(js)?;
    let bob = Engine::open(&hs, Path::new(&format!("b1-{run}")), "store-b1").await.map_err(js)?;
    bob.register(&b, pw, Some(&token)).await.map_err(js)?;
    log("ok: sign-up in the browser");

    let key = alice.enable_recovery().await.map_err(js)?;
    log(&format!("ok: recovery key ({} words)", key.split_whitespace().count()));

    let room: OwnedRoomId = alice.create_dm(&bob.user_id().unwrap()).await.map_err(js)?;
    wait_for("bob sees the invite", &[&bob], || {
        let r = room.clone();
        let b = bob.clone();
        async move { b.invited_rooms().contains(&r) }
    })
    .await?;
    bob.join(&room).await.map_err(js)?;
    alice.sync_once().await.map_err(js)?;
    alice.send_text(&room, text).await.map_err(js)?;
    wait_for("bob opens alice's encrypted message", &[&bob, &alice], || {
        let r = room.clone();
        let b = bob.clone();
        async move {
            b.messages(&r, 20).await.map(|m| m.iter().any(|x| x.was_encrypted && x.body.as_deref() == Some(text))).unwrap_or(false)
        }
    })
    .await?;

    alice.client().encryption().backups().wait_for_steady_state().await.map_err(js)?;
    let alice2 = Engine::open(&hs, Path::new(&format!("a2-{run}")), "store-a2").await.map_err(js)?;
    alice2.login(&a, pw, "web 2").await.map_err(js)?;
    alice2.sync_once().await.map_err(js)?;
    let before = alice2.messages(&room, 20).await.map_err(js)?.iter().filter(|m| m.body.is_some()).count();
    alice2.recover(&key).await.map_err(js)?;
    alice2.download_keys_for(&room).await.map_err(js)?;
    let after = alice2.messages(&room, 20).await.map_err(js)?.iter().filter(|m| m.body.is_some()).count();
    log(&format!("new web device: before key {before}, after key {after}"));
    if before != 0 || after < 1 {
        return Err(js("recovery on the web did not work"));
    }
    Ok(format!("WEB OK: signup, recovery key, E2E 1:1, new device {before}->{after}"))
}

fn js_sys_now() -> u64 {
    // Milliseconds since 1970 from the browser clock.
    #[wasm_bindgen]
    extern "C" {
        #[wasm_bindgen(js_namespace = Date)]
        fn now() -> f64;
    }
    now() as u64
}
