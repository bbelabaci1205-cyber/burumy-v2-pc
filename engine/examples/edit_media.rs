// SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
//! Editing a sent photo (tips 452 B, 482, 81, 224) on a real server:
//! words above, new words, a new photo in a 1:1 chat (the old one kept for
//! 메시지 정보), a photo added to a text, and in a public group only the
//! words may change: our app refuses a swap, and a modified app's swap is
//! ignored by the other phones.
//! Usage: edit_media <hs> <token>
#![recursion_limit = "256"]
use anyhow::{Result, bail};
use burumy_engine::Engine;
use serde_json::json;

#[tokio::main]
async fn main() -> Result<()> {
    let hs = std::env::args().nth(1).unwrap_or("http://127.0.0.1:6167".into());
    let token = std::env::args().nth(2);
    let run = std::process::id();
    let dir = std::env::temp_dir().join(format!("burumy-editmedia-{run}"));
    let mut people = vec![];
    for n in ["a", "b"] {
        let e = Engine::open(&hs, &dir.join(n), "s").await?;
        e.register(&format!("em{n}{run}"), "Secret-pass-123", token.as_deref()).await?;
        people.push(e);
    }
    let (a, b) = (&people[0], &people[1]);
    let join = |room: matrix_sdk::ruma::OwnedRoomId| async move {
        for _ in 0..40 {
            b.sync_once().await?;
            if b.invited_rooms().contains(&room) {
                break;
            }
        }
        b.join(&room).await?;
        a.sync_once().await?;
        anyhow::Ok(room)
    };
    let old_png = vec![137, 80, 78, 71, 1, 2, 3];
    let new_jpg = vec![255, 216, 255, 9, 9, 9];

    // 1:1 chat.
    let dm = join(a.create_dm(&b.user_id().unwrap()).await?).await?;
    let photo = a.send_file_opts(&dm, "sea.png", "image/png", old_png.clone(), "오늘 바다", true).await?;
    let text = a.send_text(&dm, "사진은 이따 보낼게").await?;
    b.sync_once().await?;
    let m = b.messages(&dm, 20).await?;
    let p = m.iter().find(|x| x.event_id == photo).expect("photo");
    println!("sent above: caption={:?} above={}", p.caption, p.caption_above);
    if !p.caption_above || p.caption.as_deref() != Some("오늘 바다") {
        bail!("caption above not sent")
    }

    // Words only: same file, words moved under.
    a.edit_media(&dm, &photo, "오늘 바다 최고", false, None).await?;
    // New photo.
    a.edit_media(&dm, &photo, "새 사진", false, Some(("beach.jpg".into(), "image/jpeg".into(), new_jpg.clone()))).await?;
    // A text gets a photo.
    a.edit_media(&dm, &text, "사진은 이따 보낼게", true, Some(("c.png".into(), "image/png".into(), old_png.clone()))).await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let m = b.messages(&dm, 30).await?;
    let p = m.iter().find(|x| x.event_id == photo).expect("photo");
    let t = m.iter().find(|x| x.event_id == text).expect("text");
    println!(
        "b sees photo: caption={:?} above={} changed={} from={} first={:?}",
        p.caption, p.caption_above, p.media_changed, p.media_from.is_some(), p.first_body
    );
    println!("b sees text: kind={} caption={:?} above={} changed={}", t.kind, t.caption, t.caption_above, t.media_changed);
    if p.caption.as_deref() != Some("새 사진") || !p.media_changed || p.caption_above {
        bail!("swap not shown right")
    }
    let (_, now, _) = b.download_file(&dm, p.media_from.as_deref().unwrap()).await?;
    let (_, first, _) = b.download_file(&dm, &photo).await?;
    if now != new_jpg || first != old_png {
        bail!("files wrong: new {} bytes, old {} bytes", now.len(), first.len())
    }
    if t.kind != "image" || t.caption.as_deref() != Some("사진은 이따 보낼게") || !t.caption_above {
        bail!("text did not get its photo")
    }
    if m.iter().any(|x| x.replaces.is_some()) {
        bail!("edit events leaked into the chat")
    }

    // Public group: words yes, swaps no.
    let g = join(a.create_group("공개 시험", &[b.user_id().unwrap().to_owned()], false).await?).await?;
    a.set_public_link(&g, &format!("emtest{run}")).await?;
    let gp = a.send_file_with(&g, "p.png", "image/png", old_png.clone(), "모임 사진").await?;
    a.sync_once().await?;
    a.edit_media(&g, &gp, "모임 사진 고침", false, None).await?;
    let ours = a.edit_media(&g, &gp, "x", false, Some(("q.jpg".into(), "image/jpeg".into(), new_jpg.clone()))).await;
    println!("our app swap in public group: {}", if ours.is_err() { "refused" } else { "ALLOWED" });
    if ours.is_ok() {
        bail!("app swapped a photo in a public group")
    }
    // A modified app sends the swap anyway (any file link): ignored.
    let room_a = a.client().get_room(&g).unwrap();
    room_a
        .send_raw(
            "m.room.message",
            json!({
                "msgtype": "m.image", "body": "* bad", "url": "mxc://x/y",
                "m.new_content": {"msgtype": "m.image", "body": "bad", "url": "mxc://x/y"},
                "m.relates_to": {"rel_type": "m.replace", "event_id": gp},
            }),
        )
        .await?;
    for _ in 0..3 {
        b.sync_once().await?;
    }
    let m = b.messages(&g, 30).await?;
    let p = m.iter().find(|x| x.event_id == gp).expect("group photo");
    println!("b sees group photo: caption={:?} changed={} from={}", p.caption, p.media_changed, p.media_from.is_some());
    if p.caption.as_deref() != Some("모임 사진 고침") || p.media_changed || p.media_from.is_some() {
        bail!("public group photo was swapped")
    }
    println!("EDIT MEDIA PASS");
    Ok(())
}
